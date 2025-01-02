package auth

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"

	"connectrpc.com/connect"
	"github.com/bufbuild/protovalidate-go"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/apimetadata"
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
)

var (
	internalError error = connect.NewError(connect.CodeInternal, errors.New("something went wrong"))
)

type service struct {
	pv          protovalidate.Validator
	store       store.Queries
	tokens      tokens.Tokens
	emailer     emailer.Emailer
	templates   template.Templates
	apiMetadata apimetadata.ApiMetadata
	googleSvc   googlesvc.GoogleSvc
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

	return &connect.Response[authv1.InitiateEmailResponse]{
		Msg: &authv1.InitiateEmailResponse{},
	}, nil
}
func (s *service) CompleteEmail(ctx context.Context, r *connect.Request[authv1.CompleteEmailRequest]) (*connect.Response[authv1.CompleteEmailResponse], error) {
	if err := s.pv.Validate(r.Msg); err != nil {
		log.Ctx(ctx).Err(err).Msg("invalid request")
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}

	hashedToken := util.HashStringToBase64SHA256(r.Msg.Token)
	magicLink, err := s.store.GetUnusedMagicLinkByTokenHash(ctx, hashedToken)
	if err != nil {
		if err == sql.ErrNoRows {
			log.Ctx(ctx).Err(err).Msg("no token hash exists in the databse that matches the hash of the token provided by user")
			return nil, connect.NewError(connect.CodeFailedPrecondition, errors.New("used or non existent magic link"))
		}

		log.Ctx(ctx).Err(err).Msg("failed running GetUnusedMagicLinkByTokenHash")
		return nil, internalError
	}
	if magicLink.ExpiresAt.Before(time.Now()) {
		// TODO: perhaps send a new email by calling InitiateEmail, or have a method ouside that both RPCs share :D
		log.Ctx(ctx).Error().Msg("expired magic link")
		return nil, connect.NewError(connect.CodeFailedPrecondition, errors.New("expired magic link"))
	}

	isNewCustomer, err := s.store.IsCustomerFirstLogin(ctx, magicLink.CustomerID)
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running IsCustomerFirstLogin")
		return nil, internalError
	}

	if isNewCustomer.Valid && isNewCustomer.Bool {
		customer, err := s.store.GetCustomerById(ctx, magicLink.CustomerID)
		if err != nil {
			log.Ctx(ctx).Err(err).Msg("failed running IsCustomerFirstLogin")
			return nil, internalError
		}

		calendarAccount, err := s.store.CreateCalendarAccount(ctx, store.CreateCalendarAccountParams{
			CustomerID: customer.ID,
			Provider:   store.ProviderTypeLocal,
		})
		if err != nil {
			log.Ctx(ctx).Err(err).Msg("failed running CreateCalendarAccount")
			return nil, internalError
		}

		_, err = s.store.CreateCalendarUnderCalendarAccountById(ctx, store.CreateCalendarUnderCalendarAccountByIdParams{
			AccountID:   calendarAccount.ID,
			Prodid:      util.ProdID,
			DisplayName: fmt.Sprintf("%s's Calendar", customer.Name),
			Description: sql.NullString{String: "", Valid: false},
			Color:       "#C35831", // pearl orange
		})
		if err != nil {
			log.Ctx(ctx).Err(err).Msg("failed running CreateCalendarUnderCalendarAccountById")
			return nil, internalError
		}

		err = s.emailer.Send(ctx, emailer.FromEmail_HelloEmail, customer.Email, fmt.Sprintf("Hala Wallah %s", customer.Name), "We are happy to help you schedule your calendar")
		if err != nil {
			log.Ctx(ctx).Err(err).Msg("failed running SendFromTemplate for magic link template")
			return nil, internalError
		}
	}

	err = s.store.UpdateMagicLinkUsedAtByTokenHash(ctx, store.UpdateMagicLinkUsedAtByTokenHashParams{
		TokenHash: magicLink.TokenHash,
		UsedAt:    sql.NullTime{Time: time.Now(), Valid: true},
	})
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running UpdateMagicLinkUsedAtByTokenHash")
		return nil, internalError
	}

	token, err := s.tokens.NewToken(magicLink.CustomerID, tokens.Audience_SymmetricalSpoon)
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running NewToken")
		return nil, internalError
	}

	return &connect.Response[authv1.CompleteEmailResponse]{
		Msg: &authv1.CompleteEmailResponse{
			AccessToken: token,
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
		calendarAccount, err := s.store.CreateCalendarAccount(ctx, store.CreateCalendarAccountParams{
			CustomerID: customer.ID,
			Provider:   store.ProviderTypeLocal,
		})
		if err != nil {
			log.Ctx(ctx).Err(err).Msg("failed running CreateCalendarAccount")
			return nil, internalError
		}

		_, err = s.store.CreateCalendarUnderCalendarAccountById(ctx, store.CreateCalendarUnderCalendarAccountByIdParams{
			AccountID:   calendarAccount.ID,
			Prodid:      util.ProdID,
			DisplayName: fmt.Sprintf("%s's Calendar", customer.Name),
			Description: sql.NullString{String: "", Valid: false},
			Color:       "#C35831", // pearl orange
		})
		if err != nil {
			log.Ctx(ctx).Err(err).Msg("failed running CreateCalendarUnderCalendarAccountById")
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
		},
	}, nil
}

func NewService(pv protovalidate.Validator, store store.Queries, tokens tokens.Tokens, emailer emailer.Emailer, templates template.Templates, apiMetadata apimetadata.ApiMetadata, googleSvc googlesvc.GoogleSvc) authv1connect.AuthServiceHandler {
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
