export interface WasappMessage {
  customer_id: string;
  id: string;
  chat_id: string;
  sender_name: string;
  sender_number: string;
  is_sender_me: boolean;
  body: string;
  quoted_message: WasappMessage | null;
  timestamp: number;
}
