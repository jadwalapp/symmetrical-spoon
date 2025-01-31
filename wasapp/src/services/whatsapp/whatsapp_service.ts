import type { Mongoose } from "mongoose";
import { Client, RemoteAuth } from "whatsapp-web.js";
import { MongoStore } from "wwebjs-mongo";

export interface ClientDetails {
  client: Client;
  status: "INITIALIZING" | "AUTHENTICATED" | "READY" | "DISCONNECTED";
  phoneNumber: string | null;
  name: string | null;
}

export class WhatsappService {
  private mongooseConn: Mongoose;
  private clientsDetails: Map<string, ClientDetails>;
  constructor(mongooseConn: Mongoose) {
    this.mongooseConn = mongooseConn;
    this.clientsDetails = new Map<string, ClientDetails>();
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
        headless: false,
      },
    });
    this.clientsDetails.set(customerId, {
      client: client,
      status: "INITIALIZING",
      phoneNumber: null,
      name: null,
    });
    this.setupClientEvents(client, customerId, phoneNumber);
    await client.initialize();

    // TODO: return the pairing code from here :D
    return null;
  }

  private setupClientEvents(
    client: Client,
    customerId: string,
    phoneNumber: string | null
  ) {
    client.on("change_state", (state) => {
      console.log(`👀 state changed: ${state}`);
    });

    client.on("ready", () => {
      console.log("✅ client is ready!");

      this.updateClientDetails(customerId, { status: "READY" });
    });

    client.on("authenticated", (session) => {
      console.log(
        `🛡️ client is authenticated! | session: ${
          session && JSON.stringify(session)
        }`
      );

      this.updateClientDetails(customerId, { status: "AUTHENTICATED" });
    });

    client.on("message_create", (msg) => {
      console.log("🫧🫧🫧🫧🫧🫧🫧🫧🫧");
      console.log(`🫧 message created | msg: ${JSON.stringify(msg)}`);
    });

    client.on("auth_failure", (msg) => {
      console.log(`❌ auth failure | msg: ${msg}`);
    });

    client.on("disconnected", (reason) => {
      console.log(`❌ client disconnected | reason: ${reason}`);

      this.updateClientDetails(customerId, { status: "DISCONNECTED" });
    });

    client.on("loading_screen", (percent, msg) => {
      console.log(`⏳ loading screen | percent: ${percent} | msg: ${msg}`);
    });

    client.on("qr", async (qr) => {
      console.log(`qr code received | qr: ${qr}`);

      if (phoneNumber != null) {
        const pairingCode = await client.requestPairingCode(phoneNumber, true);
        console.log(`↔️ pairing code received: ${pairingCode}`);
      }
    });

    client.on("remote_session_saved", () => {
      console.log(`remote session saved`);
    });
  }

  private async getSavedCustomerIds(): Promise<string[]> {
    const db = this.mongooseConn.connection.db;
    if (!db) {
      console.error("sheet, no db found :D");
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
}
