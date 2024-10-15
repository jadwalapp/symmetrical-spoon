package apimetadata

import (
	"context"
)

type Lang string

const (
	Lang_Arabic  Lang = "ar"
	Lang_English Lang = "en"
)

type langKey struct{}

func (n *apiMetadata) ContextWithLang(ctx context.Context, lang Lang) context.Context {
	return context.WithValue(ctx, langKey{}, &lang)
}

func (n *apiMetadata) GetLang(ctx context.Context) (Lang, bool) {
	v, ok := ctx.Value(langKey{}).(*Lang)
	if v == nil {
		return Lang_English, true
	}

	return *v, ok
}
