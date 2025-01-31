import mongoose from "mongoose";

export enum MessageEventState {
  NOT_ANALYZED = "NOT_ANALYZED",
  NO_EVENT = "NO_EVENT",
  EVENT_DETECTED = "EVENT_DETECTED",
  EVENT_CONFIRMED = "EVENT_CONFIRMED",
  EVENT_REJECTED = "EVENT_REJECTED",
}

export interface IMessage {
  _id: mongoose.Types.ObjectId;
  conversationId: mongoose.Types.ObjectId;
  customerId: string;
  messageId: string;
  fromMe: boolean;
  body: string;
  eventState: MessageEventState;
  eventData?: {
    type: string;
    details: any;
    confirmedAt?: Date;
    rejectedAt?: Date;
  };
  createdAt: Date;
  updatedAt: Date;
}

const messageSchema = new mongoose.Schema<IMessage>(
  {
    conversationId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Conversation",
      required: true,
    },
    customerId: { type: String, required: true },
    messageId: { type: String, required: true },
    fromMe: { type: Boolean, required: true },
    body: { type: String, required: true },
    eventState: {
      type: String,
      enum: Object.values(MessageEventState),
      default: MessageEventState.NOT_ANALYZED,
    },
    eventData: {
      type: {
        type: String,
      },
      details: mongoose.Schema.Types.Mixed,
      confirmedAt: Date,
      rejectedAt: Date,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for efficient queries
messageSchema.index({ conversationId: 1, createdAt: -1 });
messageSchema.index({ customerId: 1, eventState: 1 });
messageSchema.index({ messageId: 1 }, { unique: true });

export const Message = mongoose.model<IMessage>("Message", messageSchema);
