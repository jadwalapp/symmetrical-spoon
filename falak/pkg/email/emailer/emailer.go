package emailer

import (
	"context"

	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/email/template"
)

type EmailerName string

const (
	EmailerName_Stdout EmailerName = "stdout"
	EmailerName_SMTP   EmailerName = "smtp"
)

type FromEmail string

const (
	FromEmail_NoReplyEmail FromEmail = "Jadwal <no-reply@jadwal.app>"
	FromEmail_HelloEmail   FromEmail = "Jadwal <hello@jadwal.app>"
)

func MapStringToFromEmail(from string) FromEmail {
	switch from {
	case string(FromEmail_NoReplyEmail):
		return FromEmail_NoReplyEmail
	case string(FromEmail_HelloEmail):
		return FromEmail_HelloEmail
	}

	return FromEmail_NoReplyEmail
}

type Emailer interface {
	Send(ctx context.Context, from FromEmail, to, subject, body string) error
	SendFromTemplate(ctx context.Context, from FromEmail, template template.Template, to string) error
}
