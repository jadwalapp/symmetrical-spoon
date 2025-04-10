package main

import (
	"fmt"

	wasappmsganalyzer "github.com/jadwalapp/symmetrical-spoon/falak/pkg/wasapp/msganalyzer"
)

func main() {
	// Create some example messages
	messages := []wasappmsganalyzer.MessageForAnalysis{
		{
			SenderName: "Alice",
			Timestamp:  1710000000,
			Body:       "Hey, want to meet for coffee tomorrow at 3pm?",
		},
		{
			SenderName: "Bob",
			Timestamp:  1710000060,
			Body:       "Sure, that sounds great!",
		},
	}

	// Generate the message tag
	messagesTag := wasappmsganalyzer.CreateMessagesTag(messages)

	// Generate date and time tags (you can replace these with actual current date/time)
	dateTag := wasappmsganalyzer.CreateDateTag("2024-03-10")
	timeTag := wasappmsganalyzer.CreateTimeTag("14:00")

	// Combine all parts to create the final prompt
	finalPrompt := fmt.Sprintf("%s\n%s\n%s",
		messagesTag,
		dateTag,
		timeTag)

	// Print the generated prompt
	fmt.Println(finalPrompt)
}
