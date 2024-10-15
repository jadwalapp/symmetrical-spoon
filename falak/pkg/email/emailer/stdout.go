package emailer

import (
	"context"

	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/email/template"
	"github.com/rs/zerolog/log"
)

type stdoutEmailer struct {
}

func (e *stdoutEmailer) Send(ctx context.Context, from FromEmail, to, subject, body string) error {
	log.Ctx(ctx).Info().Msgf("Sending email from '%s' to '%s', with subject: '%s', and body: '%s'", from, to, subject, body)

	return nil
}

func (e *stdoutEmailer) SendFromTemplate(ctx context.Context, from FromEmail, template template.Template, to string) error {
	log.Ctx(ctx).Info().Msgf("Sending email from '%s' to '%s', with subject: '%s', and html: '%s'", from, to, template.Subject, template.HTML)

	return nil
}

func NewStdoutEmailer() Emailer {
	return &stdoutEmailer{}
}
