import type { FastifyBaseLogger } from "fastify";
import {
  Conversation,
  ConversationState,
  type IConversation,
} from "../../models/conversation";
import {
  Message,
  MessageEventState,
  type IMessage,
} from "../../models/message";
import { analyzeMessageForEvent } from "./event_analyzer";
import mongoose from "mongoose";

interface ContactInfo {
  phone: string;
  name?: string;
  pushName?: string;
}

export class ConversationService {
  private logger: FastifyBaseLogger;

  constructor(logger: FastifyBaseLogger) {
    this.logger = logger;
  }

  async handleNewMessage(
    customerId: string,
    messageId: string,
    fromMe: boolean,
    body: string,
    contact: ContactInfo
  ): Promise<void> {
    try {
      // Get or create conversation with updated contact info
      let conversation = await Conversation.findOne({
        customerId,
        participantPhone: contact.phone,
        state: ConversationState.ACTIVE,
      });

      if (!conversation) {
        conversation = await Conversation.create({
          customerId,
          participantPhone: contact.phone,
          participantName: contact.name,
          participantPushName: contact.pushName,
          state: ConversationState.ACTIVE,
        });
      } else if (
        (contact.name && conversation.participantName !== contact.name) ||
        (contact.pushName &&
          conversation.participantPushName !== contact.pushName)
      ) {
        // Update contact info if changed
        conversation.participantName =
          contact.name || conversation.participantName;
        conversation.participantPushName =
          contact.pushName || conversation.participantPushName;
        await conversation.save();
      }

      // Update last message time
      conversation.lastMessageAt = new Date();
      await conversation.save();

      // Create message
      const message = await Message.create({
        conversationId: conversation._id,
        customerId,
        messageId,
        fromMe,
        body,
        eventState: MessageEventState.NOT_ANALYZED,
      });

      // Analyze message for events if it's from the participant
      if (!fromMe) {
        await this.analyzeMessage(message, conversation);
      }
    } catch (error) {
      this.logger.error(
        { err: error, customerId, messageId },
        "Error handling new message"
      );
      throw error;
    }
  }

  private async analyzeMessage(
    message: IMessage,
    conversation: IConversation
  ): Promise<void> {
    try {
      const participantName =
        conversation.participantName ||
        conversation.participantPushName ||
        conversation.participantPhone;

      const eventAnalysis = await analyzeMessageForEvent(message.body);

      if (!eventAnalysis.hasEvent) {
        await Message.findByIdAndUpdate(message._id, {
          eventState: MessageEventState.NO_EVENT,
        });
        return;
      }

      // Update message with event details
      await Message.findByIdAndUpdate(message._id, {
        eventState: MessageEventState.EVENT_DETECTED,
        eventData: {
          type: eventAnalysis.eventType,
          details: {
            ...eventAnalysis.eventDetails,
            participantName,
            participantPhone: conversation.participantPhone,
          },
        },
      });

      this.logger.info(
        {
          messageId: message.messageId,
          customerId: message.customerId,
          eventType: eventAnalysis.eventType,
          participantName,
        },
        "Event detected in message"
      );
    } catch (error) {
      this.logger.error(
        { err: error, messageId: message.messageId },
        "Error analyzing message"
      );
    }
  }

  async handleEventConfirmation(
    messageId: string,
    confirmed: boolean
  ): Promise<void> {
    try {
      const message = await Message.findOne({ messageId });
      if (!message) {
        throw new Error(`Message not found: ${messageId}`);
      }

      const conversation = await Conversation.findById(message.conversationId);
      if (!conversation) {
        throw new Error(`Conversation not found for message: ${messageId}`);
      }

      const participantName =
        conversation.participantName ||
        conversation.participantPushName ||
        conversation.participantPhone;

      const newState = confirmed
        ? MessageEventState.EVENT_CONFIRMED
        : MessageEventState.EVENT_REJECTED;

      const updateField = confirmed ? "confirmedAt" : "rejectedAt";

      await Message.findByIdAndUpdate(message._id, {
        eventState: newState,
        [`eventData.${updateField}`]: new Date(),
      });

      if (confirmed) {
        // Log confirmed event for further processing
        this.logger.info(
          {
            messageId,
            customerId: message.customerId,
            eventType: message.eventData?.type,
            eventDetails: message.eventData?.details,
            participantName,
          },
          "Event confirmed"
        );

        // Add retry mechanism for critical operations
        let retries = 3;
        while (retries > 0) {
          try {
            // Here you would add your critical post-confirmation operations
            // For example, syncing with external calendar, sending notifications, etc.
            break;
          } catch (error) {
            retries--;
            if (retries === 0) {
              this.logger.error(
                { err: error, messageId },
                "Failed to process confirmed event after all retries"
              );
              throw error;
            }
            await new Promise((resolve) =>
              setTimeout(resolve, 1000 * (3 - retries))
            );
          }
        }
      } else {
        // Clean up rejected conversation with retry mechanism
        let retries = 3;
        while (retries > 0) {
          try {
            await this.deleteConversation(conversation._id);
            break;
          } catch (error) {
            retries--;
            if (retries === 0) {
              this.logger.error(
                { err: error, messageId },
                "Failed to delete conversation after all retries"
              );
              throw error;
            }
            await new Promise((resolve) =>
              setTimeout(resolve, 1000 * (3 - retries))
            );
          }
        }
      }
    } catch (error) {
      this.logger.error(
        { err: error, messageId },
        "Error handling event confirmation"
      );
      throw error;
    }
  }

  private async deleteConversation(
    conversationId: mongoose.Types.ObjectId
  ): Promise<void> {
    try {
      // Use transactions for atomicity
      const session = await mongoose.startSession();
      await session.withTransaction(async () => {
        // Mark conversation as deleted
        const result = await Conversation.findByIdAndUpdate(
          conversationId,
          {
            state: ConversationState.DELETED,
          },
          { session }
        );

        if (!result) {
          throw new Error(`Conversation not found: ${conversationId}`);
        }

        // Delete all messages
        await Message.deleteMany({ conversationId }, { session });
      });
      await session.endSession();

      this.logger.info({ conversationId }, "Conversation and messages deleted");
    } catch (error) {
      this.logger.error(
        { err: error, conversationId },
        "Error deleting conversation"
      );
      throw error;
    }
  }
}
