package calendarsvc

import (
	"regexp"
)

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

func ExtractEvents(message string) []Event {
	var events []Event
	eventPattern := regexp.MustCompile(`(?i)(?P<event_name>[\w\s]+) on (?P<date>\d{4}-\d{2}-\d{2})(?: at (?P<start_time>\d{2}:\d{2})(?: to (?P<end_time>\d{2}:\d{2}))?)? at (?P<location>[\w\s]+)`)

	matches := eventPattern.FindAllStringSubmatch(message, -1)

	for _, match := range matches {
		event := Event{
			EventName: match[1],
			StartDate: match[2],
			StartTime: match[3],
			EndDate:   match[2], // Assuming same date for simplicity
			EndTime:   match[4],
			Location:  match[5],
			IsAllDay:  false,
			Notes:     "",
		}
		events = append(events, event)
	}

	return events
}
