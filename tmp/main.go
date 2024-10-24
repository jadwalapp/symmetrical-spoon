package main

import (
	"fmt"
	"strings"

	ical "github.com/arran4/golang-ical"
	"github.com/rs/zerolog/log"
)

func main() {
	icalRaw := `BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//ZContent.net//Zap Calendar 1.0//EN
CALSCALE:GREGORIAN
METHOD:PUBLISH
BEGIN:VEVENT
SUMMARY:Abraham Lincoln
UID:c7614cff-3549-4a00-9152-d25cc1fe077d
SEQUENCE:0
STATUS:CONFIRMED
TRANSP:TRANSPARENT
RRULE:FREQ=YEARLY;INTERVAL=1;BYMONTH=2;BYMONTHDAY=12
DTSTART:20080212
DTEND:20080213
DTSTAMP:20150421T141403
CATEGORIES:U.S. Presidents,Civil War People
LOCATION:Hodgenville\, Kentucky
GEO:37.5739497;-85.7399606
DESCRIPTION:Born February 12\, 1809\nSixteenth President (1861-1865)\n\n\n
 \nhttp://AmericanHistoryCalendar.com
URL:http://americanhistorycalendar.com/peoplecalendar/1,328-abraham-lincol
 n
END:VEVENT
BEGIN:VEVENT
SUMMARY:Affan Birthday
UID:696d356e-dd51-4b5d-a3d4-428e1914288b
SEQUENCE:0
STATUS:CONFIRMED
TRANSP:TRANSPARENT
RRULE:FREQ=YEARLY;INTERVAL=1;BYMONTH=7;BYMONTHDAY=16
DTSTART:20080212
DTEND:20080213
DTSTAMP:20150421T141403
CATEGORIES:Birthdays
LOCATION:Riyadh, Saudi Arabia
GEO:24.8213132;46.6194305
DESCRIPTION:Born July 16\, 2003\The only Affan (2003-ALIVE)\n\n\n
 \nHe studies in Al Yamamah
END:VEVENT
END:VCALENDAR`

	cal, err := ical.ParseCalendar(strings.NewReader(icalRaw))
	if err != nil {
		log.Fatal().Err(err).Msg("failed running ParseCalendar")
	}

	fmt.Println("========")
	for _, calprop := range cal.CalendarProperties {
		fmt.Println(calprop)
	}
	fmt.Println("========")
	for _, event := range cal.Events() {
		fmt.Printf("event summary: %s\n", event.GetProperty(ical.ComponentPropertySummary).Value)
		fmt.Printf("event color: %s\n", event.GetProperty(ical.ComponentPropertyColor))
		fmt.Printf("event description: %s\n", event.GetProperty(ical.ComponentPropertyDescription))
		fmt.Printf("event status: %s\n", event.GetProperty(ical.ComponentPropertyStatus))
	}
	fmt.Println("========")
}
