package calendar

import (
	"context"
	"database/sql"
	"errors"

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

	customer, err := s.store.GetCustomerById(ctx, tokenClaims.Payload.CustomerId)
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running GetCustomerByEmail")
		return nil, internalError
	}

	calendarAccountID, err := uuid.Parse(r.Msg.CalendarAccountId)
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running uuid.Parse for r.Msg.CalendarAccountId")
		return nil, internalError
	}

	doesCustomerOwnCalendarAccount, err := s.store.DoesCustomerOwnCalendarAccount(ctx, store.DoesCustomerOwnCalendarAccountParams{
		CustomerID: customer.ID,
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

func NewService(pv protovalidate.Validator, store store.Queries, apiMetadata apimetadata.ApiMetadata) calendarv1connect.CalendarServiceHandler {
	return &service{
		pv:          pv,
		store:       store,
		apiMetadata: apiMetadata,
	}
}
