package profile

import (
	"context"
	"errors"

	"connectrpc.com/connect"
	"github.com/bufbuild/protovalidate-go"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/apimetadata"
	profilev1 "github.com/jadwalapp/symmetrical-spoon/falak/pkg/gen/proto/profile/v1"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/gen/proto/profile/v1/profilev1connect"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/store"
	"github.com/rs/zerolog/log"
)

var (
	internalError error = connect.NewError(connect.CodeInternal, errors.New("something went wrong"))
)

type service struct {
	pv          protovalidate.Validator
	store       store.Queries
	apiMetadata apimetadata.ApiMetadata
}

func (s *service) GetProfile(ctx context.Context, r *connect.Request[profilev1.GetProfileRequest]) (*connect.Response[profilev1.GetProfileResponse], error) {
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

	return &connect.Response[profilev1.GetProfileResponse]{
		Msg: &profilev1.GetProfileResponse{
			Name:  customer.Name,
			Email: customer.Email,
		},
	}, nil
}

func (s *service) AddDevice(ctx context.Context, r *connect.Request[profilev1.AddDeviceRequest]) (*connect.Response[profilev1.AddDeviceResponse], error) {
	if err := s.pv.Validate(r.Msg); err != nil {
		log.Ctx(ctx).Err(err).Msg("invalid request")
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}

	tokenClaims, ok := s.apiMetadata.GetClaims(ctx)
	if !ok {
		log.Ctx(ctx).Error().Msg("failed running GetClaims")
		return nil, internalError
	}

	err := s.store.CreateDeviceIfNotExists(ctx, store.CreateDeviceIfNotExistsParams{
		CustomerID: tokenClaims.Payload.CustomerId,
		ApnsToken:  r.Msg.DeviceToken,
	})
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running CreateDeviceIfNotExists")
		return nil, internalError
	}

	return &connect.Response[profilev1.AddDeviceResponse]{}, nil
}

func NewService(pv protovalidate.Validator, store store.Queries, apiMetadata apimetadata.ApiMetadata) profilev1connect.ProfileServiceHandler {
	return &service{
		pv:          pv,
		store:       store,
		apiMetadata: apiMetadata,
	}
}
