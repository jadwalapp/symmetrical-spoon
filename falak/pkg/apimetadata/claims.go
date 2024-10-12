package apimetadata

import (
	"context"

	"github.com/muwaqqit/symmetrical-spoon/falak/pkg/tokens"
)

type claimsKey struct{}

func (n *apiMetadata) ContextWithClaims(ctx context.Context, claims tokens.TokenClaims) context.Context {
	return context.WithValue(ctx, claimsKey{}, &claims)
}

func (n *apiMetadata) GetClaims(ctx context.Context) (*tokens.TokenClaims, bool) {
	v, ok := ctx.Value(claimsKey{}).(*tokens.TokenClaims)
	return v, ok
}
