import type { Mongoose } from "mongoose";
import type { Db } from "mongodb";
import { Client, RemoteAuth } from "whatsapp-web.js";
import { MongoStore } from "wwebjs-mongo";
import type { FastifyBaseLogger } from "fastify";

export interface ClientDetails {
  client: Client;
  status:
    | "INITIALIZING"
    | "AUTHENTICATED"
    | "READY"
    | "DISCONNECTED"
    | "WAITING_FOR_PAIRING";
  phoneNumber: string | null;
  name: string | null;
  pairingCode: string | null;
}

export class WhatsappService {
  private mongooseConn: Mongoose;
  private clientsDetails: Map<string, ClientDetails>;
  private logger: FastifyBaseLogger;
  private makeHeadlessClients: boolean;

  constructor(
    mongooseConn: Mongoose,
    logger: FastifyBaseLogger,
    makeHeadlessClients: boolean
  ) {
    this.mongooseConn = mongooseConn;
    this.clientsDetails = new Map<string, ClientDetails>();
    this.logger = logger;
    this.makeHeadlessClients = makeHeadlessClients;
  }

  async initialize(
    customerId: string,
    phoneNumber: string | null
  ): Promise<string | null> {
    const client = new Client({
      authStrategy: new RemoteAuth({
        store: new MongoStore({ mongoose: this.mongooseConn }),
        clientId: customerId,
        backupSyncIntervalMs: 60 * 1000,
      }),
      webVersion: "2.3000.1019739601",
      puppeteer: {
        headless: this.makeHeadlessClients,
        handleSIGINT: true,
        handleSIGTERM: false,
        handleSIGHUP: false,
        args: ["--no-sandbox", "--disable-setuid-sandbox"],
      },
    });

    this.clientsDetails.set(customerId, {
      client: client,
      status: "INITIALIZING",
      phoneNumber: null,
      name: null,
      pairingCode: null,
    });

    this.setupClientEvents(client, customerId, phoneNumber);
    await client.initialize();

    if (phoneNumber !== null) {
      try {
        const pairingCode = await client.requestPairingCode(phoneNumber, true);
        this.updateClientDetails(customerId, {
          status: "WAITING_FOR_PAIRING",
          pairingCode: pairingCode,
          phoneNumber: phoneNumber,
        });
        return pairingCode;
      } catch (error) {
        this.logger.error({ error, customerId }, "Failed to get pairing code");
        this.updateClientDetails(customerId, { status: "DISCONNECTED" });
        await this.disconnectClient(customerId);
        throw error;
      }
    }

    return null;
  }

  private setupClientEvents(
    client: Client,
    customerId: string,
    phoneNumber: string | null
  ) {
    client.on("change_state", (state) => {
      this.logger.info({ customerId, state }, "WhatsApp state changed");
    });

    client.on("ready", async () => {
      this.logger.info({ customerId }, "WhatsApp client is ready");
      this.updateClientDetails(customerId, {
        status: "READY",
        name: client.info.pushname,
        phoneNumber: client.info.wid.user,
      });
    });

    client.on("authenticated", (session) => {
      this.logger.info(
        { customerId, session },
        "WhatsApp client authenticated"
      );
      this.updateClientDetails(customerId, { status: "AUTHENTICATED" });
    });

    client.on("message_create", (msg) => {
      this.logger.info({ customerId, msg }, "WhatsApp message created");
    });

    client.on("auth_failure", async (msg) => {
      this.logger.error({ customerId, msg }, "WhatsApp authentication failed");
      this.updateClientDetails(customerId, { status: "DISCONNECTED" });
      await client.destroy();
      this.clientsDetails.delete(customerId);
    });

    client.on("disconnected", async (reason) => {
      this.logger.warn({ customerId, reason }, "WhatsApp client disconnected");
      this.updateClientDetails(customerId, { status: "DISCONNECTED" });
      await client.destroy();
      this.clientsDetails.delete(customerId);
    });

    client.on("loading_screen", (percent, msg) => {
      this.logger.debug(
        { customerId, percent, msg },
        "WhatsApp loading screen update"
      );
    });

    client.on("remote_session_saved", () => {
      this.logger.info({ customerId }, "WhatsApp remote session saved");
    });
  }

  private getMongoDb(): Db | undefined {
    const db = this.mongooseConn.connection.db;
    return db;
  }

  private async getSavedCustomerIds(): Promise<string[]> {
    const db = this.getMongoDb();
    if (!db) {
      this.logger.error("MongoDB connection not found");
      return [];
    }

    const collections = await db.listCollections().toArray();
    const filteredCollections = collections.filter(
      (col) =>
        col.name.startsWith("whatsapp-RemoteAuth-") &&
        col.name.endsWith(".files")
    );

    const customerIds = filteredCollections.map((col) =>
      col.name.replace("whatsapp-RemoteAuth-", "").replace(".files", "")
    );

    return customerIds;
  }

  async initializeSavedClients() {
    const customerIds = await this.getSavedCustomerIds();
    customerIds.forEach(async (customerId) => {
      await this.initialize(customerId, null);
    });
  }

  private updateClientDetails(
    customerId: string,
    newDetails: Partial<ClientDetails>
  ) {
    const oldClientDetails = this.clientsDetails.get(customerId);
    if (!oldClientDetails) return;

    this.clientsDetails.set(customerId, {
      ...oldClientDetails,
      ...newDetails,
    });
  }

  getClientDetails(customerId: string): ClientDetails | undefined {
    return this.clientsDetails.get(customerId);
  }

  getAllClientDetails(): Map<string, ClientDetails> {
    return this.clientsDetails;
  }

  async disconnectClient(customerId: string) {
    const clientDetails = this.getClientDetails(customerId);
    if (!clientDetails) return;

    await clientDetails.client.logout();
    await clientDetails.client.destroy();
    this.clientsDetails.delete(customerId);

    const db = this.getMongoDb();
    if (!db) {
      this.logger.error("MongoDB connection not found");
      return;
    }
    await db.dropCollection(`whatsapp-RemoteAuth-${customerId}.files`);
    await db.dropCollection(`whatsapp-RemoteAuth-${customerId}.chunks`);
  }
}
