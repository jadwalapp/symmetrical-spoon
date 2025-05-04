package auth

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
	baikalclient "github.com/jadwalapp/symmetrical-spoon/falak/pkg/baikal/client"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/email/emailer"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/email/template"
	authv1 "github.com/jadwalapp/symmetrical-spoon/falak/pkg/gen/proto/auth/v1"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/gen/proto/auth/v1/authv1connect"
	googlesvc "github.com/jadwalapp/symmetrical-spoon/falak/pkg/google"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/store"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/tokens"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/util"
	"github.com/rs/zerolog/log"
)

const (
	magicLinkValidity = time.Minute * 15 // 15 minutes

	// this is only for apple testing :D
	appleTesterEmail      = "apple-tester@jadwal.app"
	appleTesterMagicToken = "77d55f11-320d-4cef-b46c-9476fef1db0d"
)

var (
	internalError error = connect.NewError(connect.CodeInternal, errors.New("something went wrong"))
)

type service struct {
	pv                          protovalidate.Validator
	store                       store.Queries
	tokens                      tokens.Tokens
	emailer                     emailer.Emailer
	templates                   template.Templates
	apiMetadata                 apimetadata.ApiMetadata
	googleSvc                   googlesvc.GoogleSvc
	baikalCli                   baikalclient.Client
	calDAVPasswordEncryptionKey string
}

func (s *service) InitiateEmail(ctx context.Context, r *connect.Request[authv1.InitiateEmailRequest]) (*connect.Response[authv1.InitiateEmailResponse], error) {
	if err := s.pv.Validate(r.Msg); err != nil {
		log.Ctx(ctx).Err(err).Msg("invalid request")
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}

	lang, ok := s.apiMetadata.GetLang(ctx)
	if !ok {
		log.Ctx(ctx).Error().Msg("failed running GetLang")
		return nil, internalError
	}

	customerName, _ := util.SplitEmail(r.Msg.Email)

	customer, err := s.store.CreateCustomerIfNotExists(ctx, store.CreateCustomerIfNotExistsParams{
		Name:  customerName,
		Email: r.Msg.Email,
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

	_, err = s.store.CreateMagicToken(ctx, store.CreateMagicTokenParams{
		CustomerID: customer.ID,
		TokenHash:  hashMagicLinkToken,
		TokenType:  store.MagicTokenTypeAuth,
		ExpiresAt:  time.Now().Add(magicLinkValidity),
	})
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running CreateMagicToken")
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

	return &connect.Response[authv1.InitiateEmailResponse]{
		Msg: &authv1.InitiateEmailResponse{},
	}, nil
}
func (s *service) CompleteEmail(ctx context.Context, r *connect.Request[authv1.CompleteEmailRequest]) (*connect.Response[authv1.CompleteEmailResponse], error) {
	if err := s.pv.Validate(r.Msg); err != nil {
		log.Ctx(ctx).Err(err).Msg("invalid request")
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}

	if r.Msg.Token == appleTesterMagicToken {
		customer, err := s.store.GetCustomerByEmail(ctx, appleTesterEmail)
		if err != nil {
			if err == sql.ErrNoRows {
				log.Ctx(ctx).Err(err).Msg("user for apple tester email hasn't been created yet :D")
				return nil, connect.NewError(connect.CodeFailedPrecondition, errors.New("create the apple tester email first"))
			}

			log.Ctx(ctx).Err(err).Msg("failed running GetCustomerByEmail for apple tester email")
			return nil, internalError
		}

		token, err := s.tokens.NewToken(customer.ID, tokens.Audience_SymmetricalSpoon)
		if err != nil {
			log.Ctx(ctx).Err(err).Msg("failed running NewToken for apple tester email")
			return nil, internalError
		}

		return &connect.Response[authv1.CompleteEmailResponse]{
			Msg: &authv1.CompleteEmailResponse{
				AccessToken: token,
			},
		}, nil
	}

	hashedToken := util.HashStringToBase64SHA256(r.Msg.Token)
	magicToken, err := s.store.GetUnusedMagicTokenByTokenHash(ctx, store.GetUnusedMagicTokenByTokenHashParams{
		TokenHash: hashedToken,
		TokenType: store.MagicTokenTypeAuth,
	})
	if err != nil {
		if err == sql.ErrNoRows {
			log.Ctx(ctx).Err(err).Msg("no token hash exists in the databse that matches the hash of the token provided by user")
			return nil, connect.NewError(connect.CodeFailedPrecondition, errors.New("used or non existent magic token"))
		}

		log.Ctx(ctx).Err(err).Msg("failed running GetUnusedMagicTokenByTokenHash")
		return nil, internalError
	}
	if magicToken.ExpiresAt.Before(time.Now()) {
		// TODO: perhaps send a new email by calling InitiateEmail, or have a method ouside that both RPCs share :D
		log.Ctx(ctx).Error().Msg("expired magic token")
		return nil, connect.NewError(connect.CodeFailedPrecondition, errors.New("expired magic token"))
	}

	isNewCustomer, err := s.store.IsCustomerFirstLogin(ctx, magicToken.CustomerID)
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running IsCustomerFirstLogin")
		return nil, internalError
	}

	if isNewCustomer.Valid && isNewCustomer.Bool {
		customer, err := s.store.GetCustomerById(ctx, magicToken.CustomerID)
		if err != nil {
			log.Ctx(ctx).Err(err).Msg("failed running IsCustomerFirstLogin")
			return nil, internalError
		}

		randomPassword := uuid.New().String()

		_, err = s.baikalCli.CreateUser(ctx, &baikalclient.CreateUserRequest{
			Username: customer.Email,
			Email:    customer.Email,
			Password: randomPassword,
		})
		if err != nil {
			log.Ctx(ctx).Err(err).Msg("failed running baikalCli.CreateUser")
			return nil, internalError
		}

		_, err = s.store.CreateCalDavAccount(ctx, store.CreateCalDavAccountParams{
			CustomerID:    customer.ID,
			Email:         customer.Email,
			Username:      customer.Email,
			Password:      randomPassword,
			EncryptionKey: s.calDAVPasswordEncryptionKey,
		})
		if err != nil {
			log.Ctx(ctx).Err(err).Msg("failed running store.CreateCalDavAccount")
			return nil, internalError
		}

		err = s.emailer.Send(ctx, emailer.FromEmail_HelloEmail, customer.Email, fmt.Sprintf("Hala Wallah %s", customer.Name), "We are happy to help you schedule your calendar")
		if err != nil {
			log.Ctx(ctx).Err(err).Msg("failed running SendFromTemplate for magic link template")
			return nil, internalError
		}
	}

	err = s.store.UpdateMagicTokenUsedAtByTokenHash(ctx, store.UpdateMagicTokenUsedAtByTokenHashParams{
		TokenHash: magicToken.TokenHash,
		UsedAt:    sql.NullTime{Time: time.Now(), Valid: true},
	})
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running UpdateMagicTokenUsedAtByTokenHash")
		return nil, internalError
	}

	token, err := s.tokens.NewToken(magicToken.CustomerID, tokens.Audience_SymmetricalSpoon)
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running NewToken")
		return nil, internalError
	}

	return &connect.Response[authv1.CompleteEmailResponse]{
		Msg: &authv1.CompleteEmailResponse{
			AccessToken: token,
			UserId:      magicToken.CustomerID.String(),
		},
	}, nil
}

func (s *service) UseGoogle(ctx context.Context, r *connect.Request[authv1.UseGoogleRequest]) (*connect.Response[authv1.UseGoogleResponse], error) {
	if err := s.pv.Validate(r.Msg); err != nil {
		log.Ctx(ctx).Err(err).Msg("invalid request")
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}

	userInfo, err := s.googleSvc.GetUserInfoByToken(ctx, r.Msg.GoogleToken)
	if err != nil {
		if err == googlesvc.ErrInvalidToken {
			log.Ctx(ctx).Err(err).Msg("got invalid token error running GetUserInfoByToken")
			return nil, connect.NewError(connect.CodeInvalidArgument, nil)
		}

		log.Ctx(ctx).Err(err).Msg("failed running GetUserInfoByToken")
		return nil, internalError
	}
	if !userInfo.EmailVerified {
		log.Ctx(ctx).Info().Msg("unverified email, we shouldn't trust it")
		return nil, connect.NewError(connect.CodeFailedPrecondition, errors.New("unverified email"))
	}

	customer, err := s.store.CreateCustomerIfNotExists(ctx, store.CreateCustomerIfNotExistsParams{
		Name:  userInfo.GivenName + " " + userInfo.FamilyName,
		Email: userInfo.Email,
	})
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running CreateCustomerIfNotExists")
		return nil, internalError
	}

	isNewCustomer, err := s.store.IsCustomerFirstLogin(ctx, customer.ID)
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running IsCustomerFirstLogin")
		return nil, internalError
	}

	if isNewCustomer.Valid && isNewCustomer.Bool {
		randomPassword := uuid.New().String()

		_, err = s.baikalCli.CreateUser(ctx, &baikalclient.CreateUserRequest{
			Username: customer.Email,
			Email:    customer.Email,
			Password: randomPassword,
		})
		if err != nil {
			log.Ctx(ctx).Err(err).Msg("failed running baikalCli.CreateUser")
			return nil, internalError
		}

		_, err = s.store.CreateCalDavAccount(ctx, store.CreateCalDavAccountParams{
			CustomerID:    customer.ID,
			Email:         customer.Email,
			Username:      customer.Email,
			Password:      randomPassword,
			EncryptionKey: s.calDAVPasswordEncryptionKey,
		})
		if err != nil {
			log.Ctx(ctx).Err(err).Msg("failed running store.CreateCalDavAccount")
			return nil, internalError
		}

		err = s.emailer.Send(ctx, emailer.FromEmail_HelloEmail, customer.Email, fmt.Sprintf("Hala Wallah %s", customer.Name), "We are happy to help you schedule your calendar")
		if err != nil {
			log.Ctx(ctx).Err(err).Msg("failed running SendFromTemplate for magic link template")
			return nil, internalError
		}
	}

	token, err := s.tokens.NewToken(customer.ID, tokens.Audience_SymmetricalSpoon)
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running NewToken")
		return nil, internalError
	}

	return &connect.Response[authv1.UseGoogleResponse]{
		Msg: &authv1.UseGoogleResponse{
			AccessToken: token,
			UserId:      customer.ID.String(),
		},
	}, nil
}

func (s *service) GenerateMagicToken(ctx context.Context, r *connect.Request[authv1.GenerateMagicTokenRequest]) (*connect.Response[authv1.GenerateMagicTokenResponse], error) {
	if err := s.pv.Validate(r.Msg); err != nil {
		log.Ctx(ctx).Err(err).Msg("invalid request")
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}

	tokenClaims, ok := s.apiMetadata.GetClaims(ctx)
	if !ok {
		log.Ctx(ctx).Error().Msg("failed running GetClaims")
		return nil, internalError
	}

	magicLinkToken, hashMagicLinkToken, err := s.generateTokenWithHash()
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running generateTokenWithHash")
		return nil, internalError
	}

	if r.Msg.Type == authv1.MagicTokenType_MAGIC_TOKEN_TYPE_UNSPECIFIED {
		log.Ctx(ctx).Error().Msg("token type not specified")
		return nil, connect.NewError(connect.CodeInvalidArgument, errors.New("token type not specified"))
	}

	var tokenType store.MagicTokenType
	switch r.Msg.Type {
	case authv1.MagicTokenType_MAGIC_TOKEN_TYPE_CALDAV:
		tokenType = store.MagicTokenTypeCaldav
	default:
		log.Ctx(ctx).Error().Msg("invalid token type")
		return nil, connect.NewError(connect.CodeInvalidArgument, errors.New("invalid token type"))
	}

	_, err = s.store.CreateMagicToken(ctx, store.CreateMagicTokenParams{
		CustomerID: tokenClaims.Payload.CustomerId,
		TokenHash:  hashMagicLinkToken,
		TokenType:  tokenType,
		ExpiresAt:  time.Now().Add(magicLinkValidity),
	})
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running CreateMagicToken")
		return nil, internalError
	}

	return &connect.Response[authv1.GenerateMagicTokenResponse]{
		Msg: &authv1.GenerateMagicTokenResponse{
			MagicToken: magicLinkToken.String(),
		},
	}, nil
}

func NewService(pv protovalidate.Validator, store store.Queries, tokens tokens.Tokens, emailer emailer.Emailer, templates template.Templates, apiMetadata apimetadata.ApiMetadata, googleSvc googlesvc.GoogleSvc, baikalCli baikalclient.Client, calDAVPasswordEncryptionKey string) authv1connect.AuthServiceHandler {
	return &service{
		pv:                          pv,
		store:                       store,
		tokens:                      tokens,
		emailer:                     emailer,
		templates:                   templates,
		apiMetadata:                 apiMetadata,
		googleSvc:                   googleSvc,
		baikalCli:                   baikalCli,
		calDAVPasswordEncryptionKey: calDAVPasswordEncryptionKey,
	}
}
