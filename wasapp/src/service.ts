import { Client, LocalAuth } from "whatsapp-web.js";
import { readdir } from "node:fs/promises";
import amqp from "amqplib";
import { type WasappMessage } from "./models/wasapp_message";

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

export class WasappService {
  private clientsDetails: Map<string, ClientDetails>;
  private makeHeadlessClients: boolean;
  private amqpChannel: amqp.Channel;
  private wasappMessagesQueueName: string;
  private puppeteerExecutablePath?: string;

  constructor(
    makeHeadlessClients: boolean,
    amqpChannel: amqp.Channel,
    wasappMessagesQueueName: string,
    puppeteerExecutablePath?: string
  ) {
    this.clientsDetails = new Map<string, ClientDetails>();
    this.makeHeadlessClients = makeHeadlessClients;
    this.amqpChannel = amqpChannel;
    this.wasappMessagesQueueName = wasappMessagesQueueName;
    this.puppeteerExecutablePath = puppeteerExecutablePath;
  }

  async initialize(
    customerId: string,
    phoneNumber: string | null
  ): Promise<string | null> {
    console.log(`[DEBUG - wasapp service] started initialize`);
    const client = new Client({
      authStrategy: new LocalAuth({
        clientId: customerId,
      }),
      webVersion: "2.3000.1019739601",
      puppeteer: {
        headless: this.makeHeadlessClients,
        executablePath: this.puppeteerExecutablePath,
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

    this.setupClientEvents(client, customerId);
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

  private setupClientEvents(client: Client, customerId: string) {
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

    client.on("authenticated", (_) => {
      console.log(
        `[Customer: ${customerId}] WhatsApp client authenticated successfully`
      );
      this.updateClientDetails(customerId, { status: "AUTHENTICATED" });
    });

    client.on("message_create", async (msg) => {
      try {
        console.log(
          `[Customer: ${customerId}] New WhatsApp message | From: ${msg.from} | Type: ${msg.type} | Body: ${msg.body}`
        );

        const chat = await msg.getChat();
        if (chat.isGroup) return;

        const contact = await msg.getContact();

        let quotedMessageData: WasappMessage | undefined;
        if (msg.hasQuotedMsg) {
          const quotedMsg = await msg.getQuotedMessage();
          const quotedMsgChat = await quotedMsg.getChat();
          const quotedMsgContact = await quotedMsg.getContact();

          quotedMessageData = {
            id: quotedMsg.id._serialized,
            chat_id: quotedMsgChat.id._serialized,
            sender_name: quotedMsgContact.name ?? quotedMsgContact.pushname,
            sender_number: quotedMsgContact.number,
            is_sender_me: quotedMsg.fromMe,
            body: quotedMsg.body,
            timestamp: quotedMsg.timestamp,
          };
        }

        const wasappMessage: WasappMessage = {
          id: msg.id._serialized,
          chat_id: chat.id._serialized,
          sender_name: contact.name ?? contact.pushname,
          sender_number: contact.number,
          is_sender_me: contact.isMe,
          body: msg.body,
          quoted_message: quotedMessageData,
          timestamp: msg.timestamp,
        };

        await this.amqpChannel.assertQueue(this.wasappMessagesQueueName, {
          durable: true,
        });
        this.amqpChannel.sendToQueue(
          this.wasappMessagesQueueName,
          Buffer.from(JSON.stringify(wasappMessage)),
          {
            persistent: true,
            messageId: msg.id._serialized,
          }
        );
      } catch (error) {
        console.error("Error handling message:", error);
      }
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

  private async getSavedCustomerIds(): Promise<string[]> {
    let folderNames: string[] = [];
    try {
      folderNames = await readdir(".wwebjs_auth");
    } catch (error) {
      folderNames = [];
    }

    const filteredCollections = folderNames.filter((folderName) =>
      folderName.startsWith("session-")
    );
    const customerIds = filteredCollections.map((folderName) =>
      folderName.replace("session-", "")
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

  async deleteClient(customerId: string) {
    const clientDetails = this.getClientDetails(customerId);
    if (!clientDetails) return;

    await clientDetails.client.logout();
    await clientDetails.client.destroy();
    this.clientsDetails.delete(customerId);
  }

  async disconnectClient(customerId: string) {
    const clientDetails = this.getClientDetails(customerId);
    if (!clientDetails) return;

    // Just destroy the client without logging out to allow future reconnection
    await clientDetails.client.destroy();
    this.updateClientDetails(customerId, { status: "DISCONNECTED" });
  }

  async gracefulShutdown() {
    console.log("Starting graceful shutdown of WhatsApp service...");
    const shutdownPromises = Array.from(this.clientsDetails.entries()).map(
      async ([customerId, clientDetails]) => {
        try {
          console.log(`Disconnecting client ${customerId}...`);
          await this.disconnectClient(customerId);
          console.log(`Successfully disconnected client ${customerId}`);
        } catch (error) {
          console.error(`Failed to disconnect client ${customerId}:`, error);
        }
      }
    );

    await Promise.all(shutdownPromises);
    console.log("Completed WhatsApp service shutdown");
  }
}
