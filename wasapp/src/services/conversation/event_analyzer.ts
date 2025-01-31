interface EventAnalysis {
  hasEvent: boolean;
  eventType?: string;
  eventDetails?: any;
}

// TODO: Replace with actual LLM integration
export async function analyzeMessageForEvent(
  messageBody: string
): Promise<EventAnalysis> {
  // For now, just do a simple check for the word "event" or "meeting"
  const hasEventKeyword = /\b(event|meeting)\b/i.test(messageBody);

  if (!hasEventKeyword) {
    return { hasEvent: false };
  }

  // Mock event detection
  return {
    hasEvent: true,
    eventType: "meeting",
    eventDetails: {
      detectedText: messageBody,
      confidence: 0.9,
    },
  };
}
