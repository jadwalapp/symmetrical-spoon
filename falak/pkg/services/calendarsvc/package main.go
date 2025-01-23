package main

import (
	"encoding/json"
	"fmt"
	"log"
	"regexp"
	"strings"
)

// Event structure to hold event details
type Event struct {
	EventName string `json:"event_name"`
	StartDate string `json:"start_date"`
	StartTime string `json:"start_time"`
	EndDate   string `json:"end_date"`
	EndTime   string `json:"end_time"`
	Location  string `json:"location"`
	IsAllDay  bool   `json:"is_all_day"`
	Notes     string `json:"notes"`
}

// Function to extract events from a conversation
func extractEvent(conversation string) (string, error) {
	// Regular expressions to find date, time, and location in the conversation
	dateRegex := regexp.MustCompile(`(\d{1,2}\/\d{1,2}\/\d{2,4})`)
	timeRegex := regexp.MustCompile(`(\d{1,2}:\d{2})`)
	locationRegex := regexp.MustCompile(`at (.+?)(?:\s|$)`)

	// Extract date and time
	dateMatches := dateRegex.FindStringSubmatch(conversation)
	timeMatches := timeRegex.FindStringSubmatch(conversation)
	locationMatches := locationRegex.FindStringSubmatch(conversation)

	if len(dateMatches) == 0 {
		return `"NO"`, nil
	}

	// Parse date
	eventDate := dateMatches[0]
	startTime := "null"
	endTime := "null"
	isAllDay := false

	// If time is specified, parse it
	if len(timeMatches) > 0 {
		startTime = timeMatches[0]
		endTime = startTime // Default end time to start time if not specified
	} else {
		isAllDay = true // If no time is specified, mark as all-day event
	}

	// Create event structure
	event := Event{
		EventName: "Event from Conversation",
		StartDate: eventDate,
		StartTime: startTime,
		EndDate:   "null",
		EndTime:   endTime,
		Location:  "Not specified",
		IsAllDay:  isAllDay,
		Notes:     "",
	}

	// Update location if found
	if len(locationMatches) > 1 {
		event.Location = strings.TrimSpace(locationMatches[1])
	}

	// Convert event to JSON
	eventJSON, err := json.Marshal(event)
	if err != nil {
		return "", err
	}

	return string(eventJSON), nil
}

func main() {
	// Example conversation
	conversation := "Let's meet on 01/22/2025 at 14:00 at the coffee shop."

	eventJSON, err := extractEvent(conversation)
	if err != nil {
		log.Fatalf("Error extracting event: %v", err)
	}

	fmt.Println(eventJSON)
}
