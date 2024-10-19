package auth

import (
	"context"
	"database/sql"
	"time"

	"github.com/bufbuild/protovalidate-go"
	authpb "github.com/jadwalapp/symmetrical-spoon/falak/pkg/api/auth/proto"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/apimetadata"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/email/emailer"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/email/template"
	googlesvc "github.com/jadwalapp/symmetrical-spoon/falak/pkg/google"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/store"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/tokens"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/util"
	"github.com/rs/zerolog/log"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

const (
	magicLinkValidity = time.Minute * 15 // 15 minutes
)

var (
	internalError error = status.Error(codes.Internal, "something went wrong")
)

type service struct {
	authpb.UnimplementedAuthServer

	pv          protovalidate.Validator
	store       store.Queries
	tokens      tokens.Tokens
	emailer     emailer.Emailer
	templates   template.Templates
	apiMetadata apimetadata.ApiMetadata
	googleSvc   googlesvc.GoogleSvc
}

func (s *service) InitiateEmail(ctx context.Context, r *authpb.InitiateEmailRequest) (*authpb.InitiateEmailResponse, error) {
	if err := s.pv.Validate(r); err != nil {
		log.Ctx(ctx).Err(err).Msg("invalid request")
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}

	lang, ok := s.apiMetadata.GetLang(ctx)
	if !ok {
		log.Ctx(ctx).Error().Msg("failed running GetLang")
		return nil, internalError
	}

	customerName, _ := util.SplitEmail(r.Email)

	customer, err := s.store.CreateCustomerIfNotExists(ctx, store.CreateCustomerIfNotExistsParams{
		Name:  customerName,
		Email: r.Email,
	})
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running CreateCustomerIfNotExists")
		return nil, internalError
	}

	magicLinkToken, hashMagicLinkToken, err := s.generateTokenWithHash()
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running generateTokenWithHash")
		return nil, internalError
	}

	_, err = s.store.CreateMagicLink(ctx, store.CreateMagicLinkParams{
		CustomerID: customer.ID,
		TokenHash:  hashMagicLinkToken,
		ExpiresAt:  time.Now().Add(magicLinkValidity),
	})
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running CreateMagicLink")
		return nil, internalError
	}

	magicLinkTemplate, err := s.templates.MagicLinkTemplate(lang, magicLinkToken.String())
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running MagicLinkTemplate")
		return nil, internalError
	}

	err = s.emailer.SendFromTemplate(ctx, emailer.FromEmail_NoReplyEmail, *magicLinkTemplate, customer.Email)
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running SendFromTemplate for magic link template")
		return nil, internalError
	}

	return &authpb.InitiateEmailResponse{}, nil
}
func (s *service) CompleteEmail(ctx context.Context, r *authpb.CompleteEmailRequest) (*authpb.CompleteEmailResponse, error) {
	if err := s.pv.Validate(r); err != nil {
		log.Ctx(ctx).Err(err).Msg("invalid request")
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}

	hashedToken := util.HashStringToBase64SHA256(r.Token)
	magicLink, err := s.store.GetUnusedMagicLinkByTokenHash(ctx, hashedToken)
	if err != nil {
		if err == sql.ErrNoRows {
			log.Ctx(ctx).Err(err).Msg("no token hash exists in the databse that matches the hash of the token provided by user")
			return nil, status.Error(codes.FailedPrecondition, "used or non existent magic link")
		}

		log.Ctx(ctx).Err(err).Msg("failed running GetUnusedMagicLinkByTokenHash")
		return nil, internalError
	}
	if magicLink.ExpiresAt.Before(time.Now()) {
		// TODO: perhaps send a new email by calling InitiateEmail, or have a method ouside that both RPCs share :D
		log.Ctx(ctx).Error().Msg("expired magic link")
		return nil, status.Error(codes.FailedPrecondition, "expired magic link")
	}

	err = s.store.UpdateMagicLinkUsedAtByTokenHash(ctx, store.UpdateMagicLinkUsedAtByTokenHashParams{
		TokenHash: magicLink.TokenHash,
		UsedAt:    sql.NullTime{Time: time.Now(), Valid: true},
	})
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running UpdateMagicLinkUsedAtByTokenHash")
		return nil, internalError
	}

	token, err := s.tokens.NewToken(magicLink.CustomerID.String(), tokens.Audience_SymmetricalSpoon)
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running NewToken")
		return nil, internalError
	}

	return &authpb.CompleteEmailResponse{
		AccessToken: token,
	}, nil
}
func (s *service) UseGoogle(ctx context.Context, r *authpb.UseGoogleRequest) (*authpb.UseGoogleResponse, error) {
	if err := s.pv.Validate(r); err != nil {
		log.Ctx(ctx).Err(err).Msg("invalid request")
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}

	userInfo, err := s.googleSvc.GetUserInfoByToken(ctx, r.GoogleToken)
	if err != nil {
		if err == googlesvc.ErrInvalidToken {

		}

		log.Ctx(ctx).Err(err).Msg("failed running GetUserInfoByToken")
		return nil, internalError
	}
	if !userInfo.EmailVerified {
		log.Ctx(ctx).Info().Msg("unverified email, we shouldn't trust it")
		return nil, status.Error(codes.FailedPrecondition, "unverified email")
	}

	customer, err := s.store.CreateCustomerIfNotExists(ctx, store.CreateCustomerIfNotExistsParams{
		Name:  userInfo.GivenName + userInfo.FamilyName,
		Email: userInfo.Email,
	})
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running CreateCustomerIfNotExists")
		return nil, internalError
	}

	token, err := s.tokens.NewToken(customer.ID.String(), tokens.Audience_SymmetricalSpoon)
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running NewToken")
		return nil, internalError
	}

	return &authpb.UseGoogleResponse{
		AccessToken: token,
	}, nil
}

func NewService(pv protovalidate.Validator, store store.Queries, tokens tokens.Tokens, emailer emailer.Emailer, templates template.Templates, apiMetadata apimetadata.ApiMetadata, googleSvc googlesvc.GoogleSvc) authpb.AuthServer {
	return &service{
		pv:          pv,
		store:       store,
		tokens:      tokens,
		emailer:     emailer,
		templates:   templates,
		apiMetadata: apiMetadata,
		googleSvc:   googleSvc,
	}
}
