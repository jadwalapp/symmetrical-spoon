import { Client, RemoteAuth } from "whatsapp-web.js";
import { MongoStore } from "wwebjs-mongo";
import type { FastifyBaseLogger } from "fastify";
import type { Mongoose } from "mongoose";
import { ConversationService } from "../conversation/conversation_service";

export interface ClientStatus {
  isReady: boolean;
  isAuthenticated: boolean;
  phoneNumber?: string;
}

export class WhatsappService {
  private clients: Map<string, Client>;
  private clientStatus: Map<string, ClientStatus>;
  private mongoStore: InstanceType<typeof MongoStore>;
  private logger: FastifyBaseLogger;
  private conversationService: ConversationService;

  constructor(store: Mongoose, logger: FastifyBaseLogger) {
    this.clients = new Map();
    this.clientStatus = new Map();
    this.logger = logger;
    this.mongoStore = new MongoStore({ mongoose: store });
    this.conversationService = new ConversationService(logger);
  }

  async initializeService() {
    try {
      const collections = await this.mongoStore.mongoose.connection.db
        .listCollections()
        .toArray();
      const customerIds = new Set<string>();

      collections.forEach((col: any) => {
        const match = col.name.match(/^whatsapp-RemoteAuth-(.+?)\.files$/);
        if (match && match[1]) {
          customerIds.add(match[1]);
        }
      });

      this.logger.info(
        { customerIds: Array.from(customerIds) },
        "Found WhatsApp sessions"
      );

      for (const customerId of customerIds) {
        try {
          await this.setupClient(customerId);
          await new Promise((resolve) => setTimeout(resolve, 2000));
        } catch (error) {
          this.logger.error(
            { err: error, customerId },
            "Failed to restore client"
          );
        }
      }
    } catch (error) {
      this.logger.error({ err: error }, "Failed to initialize service");
    }
  }

  private createClient(customerId: string): Client {
    return new Client({
      authStrategy: new RemoteAuth({
        store: this.mongoStore,
        clientId: customerId,
        backupSyncIntervalMs: 60 * 1000,
      }),
      puppeteer: {
        args: ["--no-sandbox"],
        headless: false,
        timeout: 0,
      },
    });
  }

  private setupClientEvents(client: Client, customerId: string) {
    client.on("ready", () => {
      this.logger.info({ customerId }, "Client is ready");
      this.clientStatus.set(customerId, {
        ...this.clientStatus.get(customerId)!,
        isReady: true,
      });
    });

    client.on("authenticated", () => {
      this.logger.info({ customerId }, "Client authenticated");
      this.clientStatus.set(customerId, {
        ...this.clientStatus.get(customerId)!,
        isAuthenticated: true,
      });
    });

    client.on("auth_failure", () => {
      this.logger.warn({ customerId }, "Authentication failed");
      this.clientStatus.set(customerId, {
        ...this.clientStatus.get(customerId)!,
        isAuthenticated: false,
        isReady: false,
      });
    });

    client.on("message_create", async (msg) => {
      if (!this.clientStatus.get(customerId)?.isReady) {
        return;
      }

      try {
        if (msg.isStatus) return;

        const chat = await msg.getChat();
        if (chat.isGroup) return;

        const contact = await msg.getContact();

        this.logger.info(
          {
            customerId,
            from: msg.from,
            fromMe: msg.fromMe,
            body: msg.body,
          },
          "Message received"
        );

        await this.conversationService.handleNewMessage(
          customerId,
          msg.id._serialized,
          msg.fromMe,
          msg.body,
          {
            phone: chat.id.user,
            name: contact.name || undefined,
            pushName: contact.pushname || undefined,
          }
        );
      } catch (error) {
        this.logger.error(
          { err: error, customerId },
          "Failed to handle message"
        );
      }
    });

    client.on("disconnected", async (reason) => {
      this.logger.warn({ customerId, reason }, "Client disconnected");
      this.clientStatus.set(customerId, {
        ...this.clientStatus.get(customerId)!,
        isReady: false,
        isAuthenticated: false,
      });

      // Try to reconnect after a delay
      await new Promise((resolve) => setTimeout(resolve, 5000));
      try {
        await this.setupClient(customerId);
      } catch (error) {
        this.logger.error(
          { err: error, customerId },
          "Failed to reconnect client"
        );
      }
    });
  }

  private async setupClient(
    customerId: string,
    phoneNumber?: string
  ): Promise<void> {
    // Clean up existing client if any
    const existingClient = this.clients.get(customerId);
    if (existingClient) {
      try {
        await existingClient.destroy();
      } catch (error) {
        this.logger.warn(
          { err: error, customerId },
          "Error destroying existing client"
        );
      }
      this.clients.delete(customerId);
    }

    const client = this.createClient(customerId);
    this.setupClientEvents(client, customerId);

    this.clients.set(customerId, client);
    this.clientStatus.set(customerId, {
      isReady: false,
      isAuthenticated: false,
      phoneNumber,
    });

    try {
      await client.initialize();
      this.logger.info({ customerId }, "Client initialized successfully");
    } catch (error) {
      this.logger.error(
        { err: error, customerId },
        "Failed to initialize client"
      );
      this.clients.delete(customerId);
      this.clientStatus.delete(customerId);
      throw error;
    }
  }

  async initializeClient(
    customerId: string,
    phoneNumber: string
  ): Promise<string | null> {
    try {
      await this.setupClient(customerId, phoneNumber);
      const client = this.clients.get(customerId);
      if (!client) throw new Error("Client not initialized");

      const code = await client.requestPairingCode(phoneNumber);
      return code;
    } catch (error) {
      this.logger.error(
        { err: error, customerId },
        "Failed to initialize client"
      );
      return null;
    }
  }

  async getClientStatus(customerId: string): Promise<ClientStatus | null> {
    return this.clientStatus.get(customerId) || null;
  }

  async getAllClientsStatus(): Promise<Record<string, ClientStatus>> {
    const statuses: Record<string, ClientStatus> = {};
    for (const [customerId, status] of this.clientStatus) {
      statuses[customerId] = status;
    }
    return statuses;
  }
}
