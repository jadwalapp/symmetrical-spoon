package template

import (
	"fmt"

	"github.com/muwaqqit/symmetrical-spoon/falak/pkg/apimetadata"
)

type Template struct {
	Subject string
	HTML    string
}

type Templates interface {
	MagicLinkTemplate(lang apimetadata.Lang, token string) (*Template, error)
	WelcomeTemplate(lang apimetadata.Lang, name string) (*Template, error)
}

type templates struct {
	domain string
}

func (t *templates) MagicLinkTemplate(lang apimetadata.Lang, token string) (*Template, error) {
	subject := "Jadwal Magic Link ✉️"
	if lang == apimetadata.Lang_Arabic {
		subject = "رابط جدول السّحري ✉️"
	}

	htmlContent := fmt.Sprintf(`<h1>%s</h1>
	
Use the link below to login to your account, or create one if this is your first time:

Link: %s/magic-link?token=%s

If you didn't request this email, you can ignore it safely :D

Thanks,
Your Friendly Jadwal Team`, subject, t.domain, token)

	return &Template{
		Subject: subject,
		HTML:    htmlContent,
	}, nil
}

func (t *templates) WelcomeTemplate(tl apimetadata.Lang, name string) (*Template, error) {
	subject := fmt.Sprintf("%s, You are Cafu! 🚀", name)
	if tl == apimetadata.Lang_Arabic {
		subject = fmt.Sprintf("%s أنت كفو! 🚀", name)
	}

	htmlContent := fmt.Sprintf(`Hello %s!

We are happy that you decided to use the best calendar app to exist :D

Thanks,
Your Friendly Jadwal Team`, name)

	return &Template{
		Subject: subject,
		HTML:    htmlContent,
	}, nil
}

func NewTemplates(domain string) Templates {
	return &templates{
		domain: domain,
	}
}
