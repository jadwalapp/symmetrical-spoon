package calendar

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"

	"connectrpc.com/connect"
	"github.com/bufbuild/protovalidate-go"
	"github.com/google/uuid"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/apimetadata"
	calendarv1 "github.com/jadwalapp/symmetrical-spoon/falak/pkg/gen/proto/calendar/v1"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/gen/proto/calendar/v1/calendarv1connect"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/store"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/util"
	"github.com/rs/zerolog/log"
)

var (
	internalError error = connect.NewError(connect.CodeInternal, errors.New("something went wrong"))
)

type service struct {
	pv          protovalidate.Validator
	store       store.Queries
	apiMetadata apimetadata.ApiMetadata

	calendarv1connect.UnimplementedCalendarServiceHandler
}

func (s *service) GetCalendarAccounts(ctx context.Context, r *connect.Request[calendarv1.GetCalendarAccountsRequest]) (*connect.Response[calendarv1.GetCalendarAccountsResponse], error) {
	if err := s.pv.Validate(r.Msg); err != nil {
		log.Ctx(ctx).Err(err).Msg("invalid request")
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}

	tokenClaims, ok := s.apiMetadata.GetClaims(ctx)
	if !ok {
		log.Ctx(ctx).Error().Msg("failed running GetClaims")
		return nil, internalError
	}

	customer, err := s.store.GetCustomerById(ctx, tokenClaims.Payload.CustomerId)
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running GetCustomerByEmail")
		return nil, internalError
	}

	calendarAccounts, err := s.store.GetCalendarAccountsByCustomerId(ctx, customer.ID)
	if err != nil {
		log.Ctx(ctx).Err(err).Msgf("failed running GetCalendarAccountsByCustomerId")
		return nil, internalError
	}

	pbCalendarAccounts := make([]*calendarv1.CalendarAccount, len(calendarAccounts))
	for idx, ca := range calendarAccounts {
		pbCalendarAccounts[idx] = mapStoreCalendarAccountToPbCalendarAccount(&ca)
	}

	return &connect.Response[calendarv1.GetCalendarAccountsResponse]{
		Msg: &calendarv1.GetCalendarAccountsResponse{
			CalendarAccounts: pbCalendarAccounts,
		},
	}, nil
}

func (s *service) CreateCalendar(ctx context.Context, r *connect.Request[calendarv1.CreateCalendarRequest]) (*connect.Response[calendarv1.CreateCalendarResponse], error) {
	if err := s.pv.Validate(r.Msg); err != nil {
		log.Ctx(ctx).Err(err).Msg("invalid request")
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}

	tokenClaims, ok := s.apiMetadata.GetClaims(ctx)
	if !ok {
		log.Ctx(ctx).Error().Msg("failed running GetClaims")
		return nil, internalError
	}

	calendarAccountID, err := uuid.Parse(r.Msg.CalendarAccountId)
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running uuid.Parse for r.Msg.CalendarAccountId")
		return nil, internalError
	}

	doesCustomerOwnCalendarAccount, err := s.store.DoesCustomerOwnCalendarAccount(ctx, store.DoesCustomerOwnCalendarAccountParams{
		CustomerID: tokenClaims.Payload.CustomerId,
		ID:         calendarAccountID,
	})
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running DoesCustomerOwnCalendarAccount")
		return nil, internalError
	}
	if !doesCustomerOwnCalendarAccount {
		log.Ctx(ctx).Err(err).Msg("an idiot is trying to mess with our system :D")
		return nil, internalError
	}

	calendar, err := s.store.CreateCalendarUnderCalendarAccountById(ctx, store.CreateCalendarUnderCalendarAccountByIdParams{
		AccountID:   calendarAccountID,
		Prodid:      util.ProdID,
		DisplayName: r.Msg.Name,
		Description: sql.NullString{
			String: r.Msg.Description,
			Valid:  r.Msg.Description != "",
		},
		Color: r.Msg.Color,
	})
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running CreateCalendarUnderCalendarAccountById")
		return nil, internalError
	}

	return &connect.Response[calendarv1.CreateCalendarResponse]{
		Msg: &calendarv1.CreateCalendarResponse{
			Calendar: mapStoreVcalendarToPbCalendar(&calendar),
		},
	}, nil
}

func (s *service) GetCalendars(ctx context.Context, r *connect.Request[calendarv1.GetCalendarsRequest]) (*connect.Response[calendarv1.GetCalendarsResponse], error) {
	if err := s.pv.Validate(r.Msg); err != nil {
		log.Ctx(ctx).Err(err).Msg("invalid request")
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}

	tokenClaims, ok := s.apiMetadata.GetClaims(ctx)
	if !ok {
		log.Ctx(ctx).Error().Msg("failed running GetClaims")
		return nil, internalError
	}

	pbCalendars := make([]*calendarv1.Calendar, 0)
	if r.Msg.CalendarAccountId != nil {
		calendarAccountID, err := uuid.Parse(*r.Msg.CalendarAccountId)
		if err != nil {
			log.Ctx(ctx).Err(err).Msg("failed running uuid.Parse for *r.Msg.CalendarAccountId")
			return nil, internalError
		}

		calendars, err := s.store.GetCalendarsByCustomerIdAndAccountId(ctx, store.GetCalendarsByCustomerIdAndAccountIdParams{
			CustomerID: tokenClaims.Payload.CustomerId,
			AccountID:  calendarAccountID,
		})
		if err != nil {
			log.Ctx(ctx).Err(err).Msg("failed running GetCalendarsByCustomerIdAndAccountId")
			return nil, internalError
		}

		for _, c := range calendars {
			pbCalendars = append(pbCalendars, mapStoreGetCalendarsByCustomerIdAndAccountIdRowToPbCalendar(&c))
		}
	} else {
		calendars, err := s.store.GetCalendarsByCustomerId(ctx, tokenClaims.Payload.CustomerId)
		if err != nil {
			log.Ctx(ctx).Err(err).Msg("failed running GetCalendarsByCustomerId")
			return nil, internalError
		}

		for _, c := range calendars {
			pbCalendars = append(pbCalendars, mapStoreGetCalendarsByCustomerIdRowToPbCalendar(&c))
		}
	}

	return &connect.Response[calendarv1.GetCalendarsResponse]{
		Msg: &calendarv1.GetCalendarsResponse{
			Calendars: pbCalendars,
		},
	}, nil
}

func (s *service) CreateEvent(ctx context.Context, r *connect.Request[calendarv1.CreateEventRequest]) (*connect.Response[calendarv1.CreateEventResponse], error) {
	if err := s.pv.Validate(r.Msg); err != nil {
		log.Ctx(ctx).Err(err).Msg("invalid request")
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}

	tokenClaims, ok := s.apiMetadata.GetClaims(ctx)
	if !ok {
		log.Ctx(ctx).Error().Msg("failed running GetClaims")
		return nil, internalError
	}

	doesCustomerOwnCalendar, err := s.store.DoesCustomerOwnCalendar(ctx, store.DoesCustomerOwnCalendarParams{
		CustomerID: tokenClaims.Payload.CustomerId,
		Uid:        r.Msg.CalendarId,
	})
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running DoesCustomerOwnCalendar")
		return nil, internalError
	}
	if !doesCustomerOwnCalendar {
		log.Ctx(ctx).Err(err).Msg("an idiot is trying to mess with our system :D")
		return nil, internalError
	}

	dtstart := r.Msg.StartDate.AsTime()
	dtend := r.Msg.EndDate.AsTime()

	if r.Msg.IsAllDay {
		dtstart = time.Date(dtstart.Year(), dtstart.Month(), dtstart.Day(), 0, 0, 0, 0, time.UTC)
		dtend = time.Date(dtend.Year(), dtend.Month(), dtend.Day(), 0, 0, 0, 0, time.UTC).Add(24 * time.Hour)
	}

	if !dtend.After(dtstart) {
		return nil, fmt.Errorf("invalid event: start date must be before end date")
	}

	event, err := s.store.CreateEventUnderCalendarByUid(ctx, store.CreateEventUnderCalendarByUidParams{
		CalendarUid: r.Msg.CalendarId,
		Dtstamp:     time.Now().UTC(),
		Dtstart:     dtstart,
		Dtend: sql.NullTime{
			Time:  dtend,
			Valid: true,
		},
		Summary: r.Msg.Title,
		Description: sql.NullString{
			String: r.Msg.Description,
			Valid:  r.Msg.Description != "",
		},
		Location: sql.NullString{
			String: r.Msg.Location,
			Valid:  r.Msg.Location != "",
		},
		Status:         store.NullEventStatus{},         // Assuming default
		Classification: store.NullEventClassification{}, // Assuming default
		Transp:         store.NullTransparency{},        // Assuming default
	})
	if err != nil {
		log.Ctx(ctx).Error().Msg("failed running CreateEventUnderCalendarByUid")
		return nil, internalError
	}

	return &connect.Response[calendarv1.CreateEventResponse]{
		Msg: &calendarv1.CreateEventResponse{
			Event: mapStoreVeventToPbEvent(&event),
		},
	}, nil
}

func (s *service) GetCalendarsWithCalendarAccounts(ctx context.Context, r *connect.Request[calendarv1.GetCalendarsWithCalendarAccountsRequest]) (*connect.Response[calendarv1.GetCalendarsWithCalendarAccountsResponse], error) {
	if err := s.pv.Validate(r.Msg); err != nil {
		log.Ctx(ctx).Err(err).Msg("invalid request")
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}

	calendarAccountsResp, err := s.GetCalendarAccounts(ctx, &connect.Request[calendarv1.GetCalendarAccountsRequest]{
		Msg: &calendarv1.GetCalendarAccountsRequest{},
	})
	if err != nil {
		log.Ctx(ctx).Error().Msg("failed running GetCalendarAccounts")
		return nil, internalError
	}

	calendarsResp, err := s.GetCalendars(ctx, &connect.Request[calendarv1.GetCalendarsRequest]{
		Msg: &calendarv1.GetCalendarsRequest{
			CalendarAccountId: nil,
		},
	})
	if err != nil {
		log.Ctx(ctx).Error().Msg("failed running GetCalendars")
		return nil, internalError
	}

	accountWithCalendarsMap := make(map[string]*calendarv1.CalendarAccountWithCalendars, len(calendarAccountsResp.Msg.CalendarAccounts))
	for _, calendarAccount := range calendarAccountsResp.Msg.CalendarAccounts {
		accountWithCalendarsMap[calendarAccount.Id] = &calendarv1.CalendarAccountWithCalendars{
			Account:   calendarAccount,
			Calendars: []*calendarv1.Calendar{},
		}
	}

	for _, calendar := range calendarsResp.Msg.Calendars {
		if accountWithCalendars, exists := accountWithCalendarsMap[calendar.CalendarAccountId]; exists {
			accountWithCalendars.Calendars = append(accountWithCalendars.Calendars, calendar)
		}
	}

	accountWithCalendarsList := make([]*calendarv1.CalendarAccountWithCalendars, 0, len(calendarAccountsResp.Msg.CalendarAccounts))
	for _, accountWithCalendars := range accountWithCalendarsMap {
		accountWithCalendarsList = append(accountWithCalendarsList, accountWithCalendars)
	}

	return &connect.Response[calendarv1.GetCalendarsWithCalendarAccountsResponse]{
		Msg: &calendarv1.GetCalendarsWithCalendarAccountsResponse{
			CalendarAccountWithCalendarsList: accountWithCalendarsList,
		},
	}, nil
}

func NewService(pv protovalidate.Validator, store store.Queries, apiMetadata apimetadata.ApiMetadata) calendarv1connect.CalendarServiceHandler {
	return &service{
		pv:          pv,
		store:       store,
		apiMetadata: apiMetadata,
	}
}
