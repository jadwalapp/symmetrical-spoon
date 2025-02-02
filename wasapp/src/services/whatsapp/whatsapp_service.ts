import type { Mongoose } from "mongoose";
import type { Db } from "mongodb";
import { Client, RemoteAuth } from "whatsapp-web.js";
import { MongoStore } from "wwebjs-mongo";

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
  private makeHeadlessClients: boolean;

  constructor(mongooseConn: Mongoose, makeHeadlessClients: boolean) {
    this.mongooseConn = mongooseConn;
    this.clientsDetails = new Map<string, ClientDetails>();
    this.makeHeadlessClients = makeHeadlessClients;
  }

  async initialize(
    customerId: string,
    phoneNumber: string | null
  ): Promise<string | null> {
    console.log(`[DEBUG - wasapp service] started initialize`);
    const client = new Client({
      authStrategy: new RemoteAuth({
        store: new MongoStore({ mongoose: this.mongooseConn }),
        clientId: customerId,
        backupSyncIntervalMs: 60 * 1000,
      }),
      webVersion: "2.3000.1019739601",
      puppeteer: {
        headless: this.makeHeadlessClients,
        executablePath: "/usr/bin/chromium-browser",
        handleSIGINT: true,
        handleSIGTERM: false,
        handleSIGHUP: false,
        args: [
          "--no-sandbox",
          "--disable-setuid-sandbox",
          "--disable-dev-shm-usage",
        ],
      },
    });
    console.log(`[DEBUG - wasapp service] created client object :D`);

    this.clientsDetails.set(customerId, {
      client: client,
      status: "INITIALIZING",
      phoneNumber: null,
      name: null,
      pairingCode: null,
    });
    console.log(
      `[DEBUG - wasapp service] set the client in the clientsDetails`
    );

    this.setupClientEvents(client, customerId, phoneNumber);
    console.log(`[DEBUG - wasapp service] finished setupClientEvents`);
    await client.initialize();
    console.log(`[DEBUG - wasapp service] finished client.initialize`);

    if (phoneNumber !== null) {
      try {
        console.log(`[DEBUG - wasapp service] started requestPairingCode`);
        const pairingCode = await client.requestPairingCode(phoneNumber, true);
        console.log(`[DEBUG - wasapp service] finished requestPairingCode`);
        this.updateClientDetails(customerId, {
          status: "WAITING_FOR_PAIRING",
          pairingCode: pairingCode,
          phoneNumber: phoneNumber,
        });

        console.log(
          `[DEBUG - wasapp service] finished initialize with pairing code`
        );
        return pairingCode;
      } catch (error) {
        console.log(
          `Failed to get pairing code | customerId: ${customerId} | error: ${error}`
        );
        this.updateClientDetails(customerId, { status: "DISCONNECTED" });
        await this.disconnectClient(customerId);
        throw error;
      }
    }

    console.log(`[DEBUG - wasapp service] finished initialize with null`);

    return null;
  }

  private setupClientEvents(
    client: Client,
    customerId: string,
    phoneNumber: string | null
  ) {
    client.on("change_state", (state) => {
      console.log(
        `[Customer: ${customerId}] WhatsApp state changed to ${state}`
      );
    });

    client.on("ready", async () => {
      console.log(`[Customer: ${customerId}] WhatsApp client is ready`);
      this.updateClientDetails(customerId, {
        status: "READY",
        name: client.info.pushname,
        phoneNumber: client.info.wid.user,
      });
    });

    client.on("authenticated", (session) => {
      console.log(
        `[Customer: ${customerId}] WhatsApp client authenticated successfully`
      );
      this.updateClientDetails(customerId, { status: "AUTHENTICATED" });
    });

    client.on("message_create", (msg) => {
      console.log(
        `[Customer: ${customerId}] New WhatsApp message | From: ${msg.from} | Type: ${msg.type} | Body: ${msg.body}`
      );
    });

    client.on("auth_failure", async (msg) => {
      console.error(
        `[Customer: ${customerId}] WhatsApp authentication failed - ${msg}`
      );
      this.updateClientDetails(customerId, { status: "DISCONNECTED" });
      await client.destroy();
      this.clientsDetails.delete(customerId);
    });

    client.on("disconnected", async (reason) => {
      console.warn(
        `[Customer: ${customerId}] WhatsApp client disconnected - Reason: ${reason}`
      );
      this.updateClientDetails(customerId, { status: "DISCONNECTED" });
      await client.destroy();
      this.clientsDetails.delete(customerId);
    });

    client.on("loading_screen", (percent, msg) => {
      console.log(`[Customer: ${customerId}] Loading: ${percent}% - ${msg}`);
    });

    client.on("remote_session_saved", () => {
      console.log(
        `[Customer: ${customerId}] WhatsApp remote session saved successfully`
      );
    });
  }

  private getMongoDb(): Db | undefined {
    const db = this.mongooseConn.connection.db;
    return db;
  }

  private async getSavedCustomerIds(): Promise<string[]> {
    const db = this.getMongoDb();
    if (!db) {
      console.error(
        "[MongoDB] Connection not found - Unable to get saved customer IDs"
      );
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
      console.log(
        `[Customer: ${customerId}] Starting WhatsApp client initialization`
      );
      await this.initialize(customerId, null);
      console.log(
        `[Customer: ${customerId}] WhatsApp client initialization completed`
      );
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
      console.error(
        `[Customer: ${customerId}] MongoDB connection not found - Unable to disconnect client`
      );
      return;
    }
    await db.dropCollection(`whatsapp-RemoteAuth-${customerId}.files`);
    await db.dropCollection(`whatsapp-RemoteAuth-${customerId}.chunks`);
  }
}
