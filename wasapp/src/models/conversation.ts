import mongoose from "mongoose";

export enum ConversationState {
  ACTIVE = "ACTIVE",
  DELETED = "DELETED",
}

export interface IConversation {
  _id: mongoose.Types.ObjectId;
  customerId: string;
  participantPhone: string;
  participantName?: string; // Contact name if available
  participantPushName?: string; // WhatsApp display name if available
  state: ConversationState;
  lastMessageAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

const conversationSchema = new mongoose.Schema<IConversation>(
  {
    customerId: { type: String, required: true },
    participantPhone: { type: String, required: true },
    participantName: { type: String },
    participantPushName: { type: String },
    state: {
      type: String,
      enum: Object.values(ConversationState),
      default: ConversationState.ACTIVE,
    },
    lastMessageAt: { type: Date, default: Date.now },
  },
  {
    timestamps: true,
  }
);

// Create compound index for efficient queries
conversationSchema.index(
  { customerId: 1, participantPhone: 1 },
  { unique: true }
);

// Create index for searching by name
conversationSchema.index(
  { customerId: 1, participantName: 1 },
  { sparse: true }
);

export const Conversation = mongoose.model<IConversation>(
  "Conversation",
  conversationSchema
);
