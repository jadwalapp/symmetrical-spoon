import { Client, LocalAuth, RemoteAuth } from "whatsapp-web.js";
import type { Store } from "whatsapp-web.js";
import { MongoStore } from "wwebjs-mongo";
import type { FastifyBaseLogger } from "fastify";
import type { Mongoose } from "mongoose";

export interface ClientStatus {
  isReady: boolean;
  isAuthenticated: boolean;
  phoneNumber?: string;
  lastSeen?: Date;
  state:
    | "INITIALIZING"
    | "WAITING_FOR_PAIRING"
    | "AUTHENTICATING"
    | "READY"
    | "FAILED"
    | "DISCONNECTED";
  error?: string;
}

export class WhatsappService {
  private clients: Map<string, Client>;
  private clientStatus: Map<string, ClientStatus>;
  private store: Mongoose;
  private logger: FastifyBaseLogger;
  private initializationTimeouts: Map<string, ReturnType<typeof setTimeout>>;
  private mongoStore: typeof MongoStore.prototype;

  constructor(store: Mongoose, logger: FastifyBaseLogger) {
    this.clients = new Map<string, Client>();
    this.clientStatus = new Map<string, ClientStatus>();
    this.store = store;
    this.logger = logger;
    this.initializationTimeouts = new Map();
    this.mongoStore = new MongoStore({ mongoose: store });
  }

  async initializeService() {
    if (!this.store.connection?.db) {
      throw new Error("Database connection not established");
    }

    try {
      // First check if the store is ready
      await this.mongoStore.sessionExists("test-connection");
      this.logger.info("MongoDB store is ready");
    } catch (error) {
      this.logger.error({ err: error }, "Failed to initialize MongoDB store");
      throw new Error("Failed to initialize MongoDB store");
    }

    const collections = await this.store.connection.db
      .listCollections()
      .toArray();
    const whatsappCollections = collections.filter(
      (col: any) =>
        col.name.startsWith("whatsapp-") &&
        col.name !== "whatsapp-test-connection"
    );

    this.logger.info(
      "Found %d existing WhatsApp sessions",
      whatsappCollections.length
    );

    // Restore sessions in parallel with a limit
    const batchSize = 3; // Process 3 sessions at a time
    for (let i = 0; i < whatsappCollections.length; i += batchSize) {
      const batch = whatsappCollections.slice(i, i + batchSize);
      await Promise.all(
        batch.map(async (collection) => {
          const customerId = collection.name
            .replace("whatsapp-", "")
            .replace(".files", "");
          try {
            await this.restoreSession(customerId);
          } catch (error) {
            this.logger.error(
              { err: error, customerId },
              "Failed to restore session in batch"
            );
          }
        })
      );
    }
  }

  private async restoreSession(customerId: string) {
    try {
      this.logger.info(
        { customerId },
        "Attempting to restore WhatsApp session"
      );

      // Check if session exists in MongoDB
      const sessionExists = await this.mongoStore.sessionExists(customerId);
      if (!sessionExists) {
        this.logger.warn(
          { customerId },
          "No existing session found in MongoDB store"
        );
        return false;
      }

      const client = new Client({
        authStrategy: new RemoteAuth({
          store: this.mongoStore,
          clientId: customerId,
          backupSyncIntervalMs: 300 * 1000, // Backup every 5 minutes
        }),
        puppeteer: {
          args: [
            "--no-sandbox",
            "--disable-setuid-sandbox",
            "--disable-gpu",
            "--disable-dev-shm-usage",
            "--no-first-run",
            "--no-zygote",
            "--single-process",
          ],
          timeout: 120000, // Increase timeout to 2 minutes for restoration
        },
      });

      // Set up event handlers before initialization
      this.setupClientEvents(client, customerId);

      // Update status before initialization
      this.updateClientStatus(customerId, {
        isReady: false,
        isAuthenticated: false,
        state: "INITIALIZING",
      });

      // Store client reference before initialization
      this.clients.set(customerId, client);

      // Initialize with longer timeout for restoration
      const initPromise = client.initialize();
      const timeoutPromise = new Promise((_, reject) => {
        const timeout = setTimeout(() => {
          reject(new Error("Session restoration timed out"));
        }, 120000); // 2 minute timeout
        this.initializationTimeouts.set(customerId, timeout);
      });

      await Promise.race([initPromise, timeoutPromise]).catch(async (error) => {
        this.logger.error(
          { err: error, customerId },
          "Session restoration failed or timed out"
        );
        await this.disconnectClient(customerId);
        throw error;
      });

      this.logger.info({ customerId }, "Session restored successfully");
      return true;
    } catch (error) {
      this.logger.error(
        { err: error, customerId },
        "Failed to restore WhatsApp session"
      );
      await this.disconnectClient(customerId);
      return false;
    }
  }

  async initializeClient(
    customerId: string,
    phoneNumber: string
  ): Promise<string | null> {
    try {
      // Clean up any existing client
      await this.disconnectClient(customerId);

      this.logger.info(
        { customerId, phoneNumber },
        "Initializing new WhatsApp client"
      );

      const client = new Client({
        authStrategy: new RemoteAuth({
          store: new MongoStore({ mongoose: this.store }),
          clientId: customerId,
          backupSyncIntervalMs: 300 * 1000,
        }),
        puppeteer: {
          args: ["--no-sandbox", "--disable-setuid-sandbox"],
          timeout: 60000,
        },
      });

      this.updateClientStatus(customerId, {
        isReady: false,
        isAuthenticated: false,
        phoneNumber,
        state: "INITIALIZING",
        lastSeen: new Date(),
      });

      this.setupClientEvents(client, customerId);
      this.clients.set(customerId, client);

      await client.initialize();

      // Set initialization timeout
      const timeout = setTimeout(async () => {
        const status = await this.getClientStatus(customerId);
        if (
          status.state === "INITIALIZING" ||
          status.state === "WAITING_FOR_PAIRING"
        ) {
          this.logger.warn({ customerId }, "Client initialization timed out");
          await this.disconnectClient(customerId);
        }
      }, 60000); // 60 second timeout

      this.initializationTimeouts.set(customerId, timeout);

      try {
        const code = await client.requestPairingCode(phoneNumber);
        this.updateClientStatus(customerId, { state: "WAITING_FOR_PAIRING" });
        return code;
      } catch (error) {
        this.logger.error(
          { err: error, customerId },
          "Failed to generate pairing code"
        );
        await this.disconnectClient(customerId);
        return null;
      }
    } catch (error) {
      this.logger.error(
        { err: error, customerId },
        "Error in client initialization"
      );
      await this.disconnectClient(customerId);
      return null;
    }
  }

  async getPairingCode(
    customerId: string,
    phoneNumber: string
  ): Promise<string | null> {
    try {
      const client = this.clients.get(customerId);
      const status = await this.getClientStatus(customerId);

      if (
        !client ||
        status.state === "FAILED" ||
        status.state === "DISCONNECTED"
      ) {
        // Try to reinitialize if client is in a bad state
        return this.initializeClient(customerId, phoneNumber);
      }

      const code = await client.requestPairingCode(phoneNumber);
      this.updateClientStatus(customerId, { state: "WAITING_FOR_PAIRING" });
      return code;
    } catch (error) {
      this.logger.error(
        { err: error, customerId },
        "Error generating pairing code"
      );
      await this.disconnectClient(customerId);
      return null;
    }
  }

  private setupClientEvents(client: Client, customerId: string) {
    client.on("ready", () => {
      this.logger.info({ customerId }, "WhatsApp client is ready");
      this.clearInitializationTimeout(customerId);
      this.updateClientStatus(customerId, {
        isReady: true,
        isAuthenticated: true,
        state: "READY",
      });
    });

    client.on("auth_failure", async () => {
      this.logger.warn({ customerId }, "WhatsApp authentication failed");
      this.updateClientStatus(customerId, {
        isAuthenticated: false,
        state: "FAILED",
        error: "Authentication failed",
      });
      await this.disconnectClient(customerId);
    });

    client.on("authenticated", () => {
      this.logger.info({ customerId }, "WhatsApp client authenticated");
      this.updateClientStatus(customerId, {
        isAuthenticated: true,
        state: "AUTHENTICATING",
      });
    });

    client.on("remote_session_saved", () => {
      this.logger.info({ customerId }, "Remote WhatsApp session saved");
    });

    client.on("message_create", async (msg) => {
      const chat = await msg.getChat();
      if (chat.isGroup) {
        this.logger.debug(
          { customerId, chatId: chat.id },
          "Ignoring group message"
        );
        return;
      }

      this.logger.debug(
        { customerId, chatId: chat.id, messageId: msg.id },
        "New message received"
      );
      this.updateClientStatus(customerId, { lastSeen: new Date() });
    });

    client.on("disconnected", async (reason) => {
      this.logger.warn({ customerId, reason }, "WhatsApp client disconnected");
      this.updateClientStatus(customerId, {
        isReady: false,
        isAuthenticated: false,
        state: "DISCONNECTED",
        error: reason,
      });
      await this.disconnectClient(customerId);
    });
  }

  private clearInitializationTimeout(customerId: string) {
    const timeout = this.initializationTimeouts.get(customerId);
    if (timeout) {
      clearTimeout(timeout);
      this.initializationTimeouts.delete(customerId);
    }
  }

  private updateClientStatus(
    customerId: string,
    updates: Partial<ClientStatus>
  ) {
    const currentStatus = this.clientStatus.get(customerId) || {
      isReady: false,
      isAuthenticated: false,
      state: "INITIALIZING",
    };
    this.clientStatus.set(customerId, { ...currentStatus, ...updates });
  }

  async getClientStatus(customerId: string): Promise<ClientStatus> {
    const status = this.clientStatus.get(customerId);
    if (!status) {
      return {
        isReady: false,
        isAuthenticated: false,
        state: "DISCONNECTED",
      };
    }
    return status;
  }

  async getAllClientsStatus(): Promise<Record<string, ClientStatus>> {
    const statuses: Record<string, ClientStatus> = {};
    for (const [customerId] of this.clients) {
      statuses[customerId] = await this.getClientStatus(customerId);
    }
    return statuses;
  }

  async disconnectClient(customerId: string): Promise<boolean> {
    this.clearInitializationTimeout(customerId);
    const client = this.clients.get(customerId);
    if (!client) return false;

    try {
      await client.destroy();
    } catch (error) {
      this.logger.error({ err: error, customerId }, "Error destroying client");
    } finally {
      // Clean up regardless of errors
      this.clients.delete(customerId);
      this.clientStatus.delete(customerId);
      this.logger.info({ customerId }, "Client cleanup completed");
    }
    return true;
  }
}
