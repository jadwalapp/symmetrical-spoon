package calendar

import (
	"context"
	"errors"

	"connectrpc.com/connect"
	"github.com/bufbuild/protovalidate-go"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/apimetadata"
	calendarv1 "github.com/jadwalapp/symmetrical-spoon/falak/pkg/gen/proto/calendar/v1"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/gen/proto/calendar/v1/calendarv1connect"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/store"
	"github.com/rs/zerolog/log"
)

var (
	internalError error = connect.NewError(connect.CodeInternal, errors.New("something went wrong"))
)

type service struct {
	pv                          protovalidate.Validator
	store                       store.Queries
	apiMetadata                 apimetadata.ApiMetadata
	calDavPasswordEncryptionKey string

	calendarv1connect.UnimplementedCalendarServiceHandler
}

func (s *service) GetCalDavAccount(ctx context.Context, r *connect.Request[calendarv1.GetCalDavAccountRequest]) (*connect.Response[calendarv1.GetCalDavAccountResponse], error) {
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
		log.Ctx(ctx).Err(err).Msg("failed running GetCustomerById")
		return nil, internalError
	}

	calDavAccount, err := s.store.GetCalDavAccountByCustomerId(ctx, store.GetCalDavAccountByCustomerIdParams{
		CustomerID:    customer.ID,
		EncryptionKey: s.calDavPasswordEncryptionKey,
	})
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running GetCalDavAccountByCustomerId")
		return nil, internalError
	}

	return &connect.Response[calendarv1.GetCalDavAccountResponse]{
		Msg: &calendarv1.GetCalDavAccountResponse{
			Username: calDavAccount.Username,
			Password: calDavAccount.DecryptedPassword,
		},
	}, nil
}

func NewService(pv protovalidate.Validator, store store.Queries, apiMetadata apimetadata.ApiMetadata, calDAVPasswordEncryptionKey string) calendarv1connect.CalendarServiceHandler {
	return &service{
		pv:                          pv,
		store:                       store,
		apiMetadata:                 apiMetadata,
		calDavPasswordEncryptionKey: calDAVPasswordEncryptionKey,
	}
}
