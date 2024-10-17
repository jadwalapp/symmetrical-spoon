package emailer

import (
	"context"

	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/email/template"
	"github.com/resendlabs/resend-go"
	"github.com/rs/zerolog/log"
)

type resendEmailer struct {
	resend resend.Client
}

func (e *resendEmailer) Send(ctx context.Context, from FromEmail, to, subject, body string) error {
	resp, err := e.resend.Emails.Send(&resend.SendEmailRequest{
		From:    string(from),
		To:      []string{to},
		Subject: subject,
		Html:    body,
	})
	if err != nil {
		log.Ctx(ctx).Error().Err(err).Msg("failed to send email")
		return err
	}

	log.Ctx(ctx).Info().Str("id", resp.Id).Msg("email sent")

	return nil

}

func (e *resendEmailer) SendFromTemplate(ctx context.Context, from FromEmail, template template.Template, to string) error {
	return e.Send(ctx, from, to, template.Subject, template.HTML)
}

func NewResendEmailer(resend resend.Client) Emailer {
	return &resendEmailer{
		resend: resend,
	}
}
