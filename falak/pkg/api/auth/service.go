package auth

import (
	"context"

	"github.com/bufbuild/protovalidate-go"
	authpb "github.com/muwaqqit/symmetrical-spoon/falak/pkg/api/auth/proto"
	"github.com/rs/zerolog/log"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

var (
	internalError error = status.Error(codes.Internal, "something went wrong")
)

type service struct {
	authpb.UnimplementedAuthServer

	pv protovalidate.Validator
}

func (s *service) InitiateEmail(ctx context.Context, r *authpb.InitiateEmailRequest) (*authpb.InitiateEmailResponse, error) {
	if err := s.pv.Validate(r); err != nil {
		log.Ctx(ctx).Err(err).Msg("invalid request")
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}

	return &authpb.InitiateEmailResponse{}, nil
}
func (s *service) CompleteEmail(ctx context.Context, r *authpb.CompleteEmailRequest) (*authpb.CompleteEmailResponse, error) {
	if err := s.pv.Validate(r); err != nil {
		log.Ctx(ctx).Err(err).Msg("invalid request")
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}

	return &authpb.CompleteEmailResponse{
		AccessToken: "",
	}, nil
}
func (s *service) UseGoogle(ctx context.Context, r *authpb.UseGoogleRequest) (*authpb.UseGoogleResponse, error) {
	if err := s.pv.Validate(r); err != nil {
		log.Ctx(ctx).Err(err).Msg("invalid request")
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}

	return &authpb.UseGoogleResponse{
		AccessToken: "",
	}, nil
}

func NewService(pv protovalidate.Validator) authpb.AuthServer {
	return &service{
		pv: pv,
	}
}
