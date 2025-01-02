package calendar

import (
	calendarv1 "github.com/jadwalapp/symmetrical-spoon/falak/pkg/gen/proto/calendar/v1"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/store"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func mapStoreCalendarAccountToPbCalendarAccount(ca *store.CalendarAccount) *calendarv1.CalendarAccount {
	return &calendarv1.CalendarAccount{
		Id:       ca.ID.String(),
		Provider: mapStoreCalendarAccountProviderToPbCalendarAccountProvider(ca.Provider),
	}
}

func mapStoreCalendarAccountProviderToPbCalendarAccountProvider(p store.ProviderType) calendarv1.CalendarAccountProvider {
	switch p {
	case store.ProviderTypeLocal:
		return calendarv1.CalendarAccountProvider_CALENDAR_ACCOUNT_PROVIDER_LOCAL
	case store.ProviderTypeCaldav:
		return calendarv1.CalendarAccountProvider_CALENDAR_ACCOUNT_PROVIDER_CALDAV
	default:
		return calendarv1.CalendarAccountProvider_CALENDAR_ACCOUNT_PROVIDER_UNSPECIFIED
	}
}

func mapStoreVcalendarToPbCalendar(c *store.Vcalendar) *calendarv1.Calendar {
	return &calendarv1.Calendar{
		Id:                c.Uid,
		CalendarAccountId: c.AccountID.String(),
		Name:              c.DisplayName,
		Description:       c.Description.String,
		StartDate:         &timestamppb.Timestamp{},
		EndDate:           &timestamppb.Timestamp{},
		Color:             c.Color,
	}
}

func mapStoreGetCalendarsByCustomerIdRowToPbCalendar(r *store.GetCalendarsByCustomerIdRow) *calendarv1.Calendar {
	return &calendarv1.Calendar{
		Id:                r.Uid,
		CalendarAccountId: r.ID.String(),
		Name:              r.DisplayName,
		Description:       r.Description.String,
		StartDate:         &timestamppb.Timestamp{},
		EndDate:           &timestamppb.Timestamp{},
		Color:             r.Color,
	}
}

func mapStoreGetCalendarsByCustomerIdAndAccountIdRowToPbCalendar(r *store.GetCalendarsByCustomerIdAndAccountIdRow) *calendarv1.Calendar {
	return &calendarv1.Calendar{
		Id:                r.Uid,
		CalendarAccountId: r.ID.String(),
		Name:              r.DisplayName,
		Description:       r.Description.String,
		StartDate:         &timestamppb.Timestamp{},
		EndDate:           &timestamppb.Timestamp{},
		Color:             r.Color,
	}
}

func mapStoreVeventToPbEvent(e *store.Vevent) *calendarv1.Event {
	return &calendarv1.Event{
		Id:        e.Uid,
		Title:     e.Summary,
		Location:  e.Location.String,
		IsAllDay:  false,
		StartDate: &timestamppb.Timestamp{},
		EndDate:   &timestamppb.Timestamp{},
	}
}
