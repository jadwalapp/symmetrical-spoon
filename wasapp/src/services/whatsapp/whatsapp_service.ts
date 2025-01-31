import type { Mongoose } from "mongoose";
import { Client, RemoteAuth } from "whatsapp-web.js";
import { MongoStore } from "wwebjs-mongo";

export class WhatsappService {
  private mongooseConn: Mongoose;
  private clients: Map<string, Client>;
  constructor(mongooseConn: Mongoose) {
    this.mongooseConn = mongooseConn;
    this.clients = new Map<string, Client>();
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
      puppeteer: {
        headless: false,
      },
    });
    this.clients.set(customerId, client);
    this.setupClientEvents(client, phoneNumber);
    client.initialize();

    // TODO: return the pairing code from here :D
    return null;
  }

  private setupClientEvents(client: Client, phoneNumber: string | null) {
    client.on("change_state", (state) => {
      console.log(`👀 state changed: ${state}`);
    });

    client.on("ready", () => {
      console.log("✅ client is ready!");
    });

    client.on("authenticated", (session) => {
      console.log(
        `🛡️ client is authenticated! | session: ${
          session && JSON.stringify(session)
        }`
      );
    });

    client.on("message", (msg) => {
      console.log("🫧🫧🫧🫧🫧🫧🫧🫧🫧");
      console.log(`🫧 message received | msg: ${JSON.stringify(msg)}`);
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
}
