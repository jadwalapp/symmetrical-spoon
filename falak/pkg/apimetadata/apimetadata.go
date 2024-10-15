package apimetadata

import (
	"context"

	"github.com/muwaqqit/symmetrical-spoon/falak/pkg/tokens"
)

type ApiMetadata interface {
	ContextWithClaims(ctx context.Context, claims tokens.TokenClaims) context.Context
	GetClaims(ctx context.Context) (*tokens.TokenClaims, bool)

	ContextWithLang(ctx context.Context, lang Lang) context.Context
	GetLang(ctx context.Context) (Lang, bool)
}

type apiMetadata struct{}

func NewApiMetadata() ApiMetadata {
	return &apiMetadata{}
}
