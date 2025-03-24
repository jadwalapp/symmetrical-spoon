package wasappmsgconsumer

import (
	"context"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/store"
	wasappcalendar "github.com/jadwalapp/symmetrical-spoon/falak/pkg/wasapp/calendar"
	wasappmsganalyzer "github.com/jadwalapp/symmetrical-spoon/falak/pkg/wasapp/msganalyzer"
	"github.com/rs/zerolog/log"
)

func mapAddMessageToChatReturningMessagesRowToMessageForAnalysis(row store.AddMessageToChatReturningMessagesRow) wasappmsganalyzer.MessageForAnalysis {
	return wasappmsganalyzer.MessageForAnalysis{
		SenderName: row.SenderName,
		Body:       row.Body,
		Timestamp:  row.Timestamp,
	}
}

func mapAnalysisResponseToCalendarEvent(ctx context.Context, customerID uuid.UUID, chatID string, analysisResp *wasappmsganalyzer.AnalyzeMessagesResponse) wasappcalendar.CalendarEventData {
	title := fmt.Sprintf("WhatsApp Event: %s", chatID)
	if analysisResp.Event.Title != nil {
		title = *analysisResp.Event.Title
	}

	description := fmt.Sprintf("Event extracted from WhatsApp chat: %s", chatID)
	if analysisResp.Event.Notes != nil {
		description = *analysisResp.Event.Notes
	}

	rawStartDate := ""
	if analysisResp.Event.StartDate != nil {
		rawStartDate = *analysisResp.Event.StartDate
	}

	rawStartTime := ""
	if analysisResp.Event.StartTime != nil {
		rawStartTime = *analysisResp.Event.StartTime
	}

	rawEndDate := ""
	if analysisResp.Event.EndDate != nil {
		rawEndDate = *analysisResp.Event.EndDate
	}

	rawEndTime := ""
	if analysisResp.Event.EndTime != nil {
		rawEndTime = *analysisResp.Event.EndTime
	}

	startTime, endTime := mapEventStringsToDateTimes(
		ctx,
		rawStartDate,
		rawStartTime,
		rawEndDate,
		rawEndTime,
	)

	return wasappcalendar.CalendarEventData{
		CustomerID:  customerID,
		ChatID:      chatID,
		Summary:     title,
		Description: description,
		StartTime:   startTime,
		EndTime:     endTime,
	}
}

func mapEventStringsToDateTimes(ctx context.Context, startDate, startTime, endDate, endTime string) (time.Time, time.Time) {
	now := time.Now()
	startDateTime := now.Add(24 * time.Hour)
	endDateTime := now.Add(25 * time.Hour)

	if startDate != "" {
		parsedDate, err := time.Parse("2006-01-02", startDate)
		if err == nil {
			startDateTime = time.Date(
				parsedDate.Year(),
				parsedDate.Month(),
				parsedDate.Day(),
				0, 0, 0, 0,
				parsedDate.Location(),
			)

			if startTime != "" {
				timeComponents := strings.Split(startTime, ":")
				if len(timeComponents) == 2 {
					hour, hourErr := strconv.Atoi(timeComponents[0])
					minute, minErr := strconv.Atoi(timeComponents[1])

					if hourErr == nil && minErr == nil {
						startDateTime = time.Date(
							parsedDate.Year(),
							parsedDate.Month(),
							parsedDate.Day(),
							hour,
							minute,
							0, 0, // seconds and nanoseconds
							parsedDate.Location(),
						)
					}
				}
			}
		} else {
			log.Ctx(ctx).Warn().
				Str("start_date", startDate).
				Err(err).
				Msg("failed to parse start date")
		}
	}

	if endDate != "" {
		parsedDate, err := time.Parse("2006-01-02", endDate)
		if err == nil {
			endDateTime = time.Date(
				parsedDate.Year(),
				parsedDate.Month(),
				parsedDate.Day(),
				0, 0, 0, 0,
				parsedDate.Location(),
			)

			if endTime != "" {
				timeComponents := strings.Split(endTime, ":")
				if len(timeComponents) == 2 {
					hour, hourErr := strconv.Atoi(timeComponents[0])
					minute, minErr := strconv.Atoi(timeComponents[1])

					if hourErr == nil && minErr == nil {
						endDateTime = time.Date(
							parsedDate.Year(),
							parsedDate.Month(),
							parsedDate.Day(),
							hour,
							minute,
							0, 0, // seconds and nanoseconds
							parsedDate.Location(),
						)
					}
				}
			}
		} else {
			log.Ctx(ctx).Warn().
				Str("end_date", endDate).
				Err(err).
				Msg("failed to parse end date")
		}
	}

	if endDate == "" && startDate != "" {
		endDateTime = startDateTime.Add(1 * time.Hour)
	}

	return startDateTime, endDateTime
}
