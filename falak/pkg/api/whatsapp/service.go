package whatsapp

import (
	"context"
	"errors"

	"connectrpc.com/connect"
	"github.com/bufbuild/protovalidate-go"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/apimetadata"
	whatsappv1 "github.com/jadwalapp/symmetrical-spoon/falak/pkg/gen/proto/whatsapp/v1"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/gen/proto/whatsapp/v1/whatsappv1connect"
	wasappclient "github.com/jadwalapp/symmetrical-spoon/falak/pkg/wasapp/client"
	"github.com/rs/zerolog/log"
)

var (
	internalError error = connect.NewError(connect.CodeInternal, errors.New("something went wrong"))
)

type service struct {
	pv          protovalidate.Validator
	apiMetadata apimetadata.ApiMetadata
	wasappCli   wasappclient.Client
}

func (s *service) ConnectWhatsappAccount(ctx context.Context, r *connect.Request[whatsappv1.ConnectWhatsappAccountRequest]) (*connect.Response[whatsappv1.ConnectWhatsappAccountResponse], error) {
	if err := s.pv.Validate(r.Msg); err != nil {
		log.Ctx(ctx).Err(err).Msg("invalid reques")
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}

	tokenClaims, ok := s.apiMetadata.GetClaims(ctx)
	if !ok {
		log.Ctx(ctx).Error().Msg("failed running GetClaims")
		return nil, internalError
	}

	resp, err := s.wasappCli.Initialize(ctx, &wasappclient.InitializeRequest{
		CustomerId:  tokenClaims.Payload.CustomerId.String(),
		PhoneNumber: r.Msg.Mobile,
	})
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running wasappCli.Initialize")
		return nil, internalError
	}

	return &connect.Response[whatsappv1.ConnectWhatsappAccountResponse]{
		Msg: &whatsappv1.ConnectWhatsappAccountResponse{
			PairingCode: resp.PairingCode,
		},
	}, nil
}

func (s *service) DisconnectWhatsappAccount(ctx context.Context, r *connect.Request[whatsappv1.DisconnectWhatsappAccountRequest]) (*connect.Response[whatsappv1.DisconnectWhatsappAccountResponse], error) {
	if err := s.pv.Validate(r.Msg); err != nil {
		log.Ctx(ctx).Err(err).Msg("invalid reques")
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}

	tokenClaims, ok := s.apiMetadata.GetClaims(ctx)
	if !ok {
		log.Ctx(ctx).Error().Msg("failed running GetClaims")
		return nil, internalError
	}

	_, err := s.wasappCli.Disconnect(ctx, &wasappclient.DisconnectRequest{
		CustomerId: tokenClaims.Payload.CustomerId.String(),
	})
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running wasappCli.Disconnect")
		return nil, internalError
	}

	return &connect.Response[whatsappv1.DisconnectWhatsappAccountResponse]{
		Msg: &whatsappv1.DisconnectWhatsappAccountResponse{},
	}, nil
}

func (s *service) GetWhatsappAccount(ctx context.Context, r *connect.Request[whatsappv1.GetWhatsappAccountRequest]) (*connect.Response[whatsappv1.GetWhatsappAccountResponse], error) {
	if err := s.pv.Validate(r.Msg); err != nil {
		log.Ctx(ctx).Err(err).Msg("invalid reques")
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}

	tokenClaims, ok := s.apiMetadata.GetClaims(ctx)
	if !ok {
		log.Ctx(ctx).Error().Msg("failed running GetClaims")
		return nil, internalError
	}

	resp, err := s.wasappCli.GetStatus(ctx, &wasappclient.GetStatusRequest{
		CustomerId: tokenClaims.Payload.CustomerId.String(),
	})
	if err != nil {
		if err == wasappclient.ErrNotFound {
			log.Ctx(ctx).Err(err).Msg("nothing found running wasappCli.GetStatus")
			return nil, connect.NewError(connect.CodeNotFound, nil)
		}

		log.Ctx(ctx).Err(err).Msg("failed running wasappCli.GetStatus")
		return nil, internalError
	}

	var pairingCode string
	if resp.ClientDetails.PairingCode != nil {
		pairingCode = *resp.ClientDetails.PairingCode
	}

	return &connect.Response[whatsappv1.GetWhatsappAccountResponse]{
		Msg: &whatsappv1.GetWhatsappAccountResponse{
			Status:          resp.ClientDetails.Status,
			PhoneNumber:     resp.ClientDetails.PhoneNumber,
			Name:            resp.ClientDetails.Name,
			PairingCode:     pairingCode,
			IsReady:         resp.ClientDetails.IsReady,
			IsAuthenticated: resp.ClientDetails.IsAuthenticated,
		},
	}, nil
}

func NewService(pv protovalidate.Validator, apiMetadata apimetadata.ApiMetadata, wasappCli wasappclient.Client) whatsappv1connect.WhatsappServiceHandler {
	return &service{
		pv:          pv,
		apiMetadata: apiMetadata,
		wasappCli:   wasappCli,
	}
}
