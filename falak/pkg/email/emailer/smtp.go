package emailer

import (
	"context"
	"fmt"
	"net/smtp"

	"github.com/domodwyer/mailyak"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/email/template"
)

type smtpEmailer struct {
	host     string
	port     string
	username string
	password string
}

func (s *smtpEmailer) Send(ctx context.Context, from FromEmail, to, subject, body string) error {
	mail := mailyak.New(fmt.Sprintf("%s:%s", s.host, s.port), smtp.PlainAuth("", s.username, s.password, s.host))

	name, email := splitNameEmail(string(from))
	if name == "" || email == "" {
		return fmt.Errorf("invalid from email: %s", from)
	}

	mail.FromName(name)
	mail.From(email)

	mail.To(to)

	mail.Subject(subject)
	mail.HTML().Set(body)

	err := mail.Send()
	if err != nil {
		return err
	}

	return nil

}

func (s *smtpEmailer) SendFromTemplate(ctx context.Context, from FromEmail, template template.Template, to string) error {
	return s.Send(ctx, from, to, template.Subject, template.HTML)
}

func NewSmtpEmailer(host string, port string, username string, password string) Emailer {
	return &smtpEmailer{
		host:     host,
		port:     port,
		username: username,
		password: password,
	}
}
