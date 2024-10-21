package interceptors

import (
	"context"
	"errors"
	"strings"

	"connectrpc.com/connect"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/apimetadata"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/gen/proto/auth/v1/authv1connect"
	tokens "github.com/jadwalapp/symmetrical-spoon/falak/pkg/tokens"
)

var (
	errMissingAuthorizationHeader = connect.NewError(connect.CodeUnauthenticated, errors.New("missing authorization header"))
	errInvalidToken               = connect.NewError(connect.CodeUnauthenticated, errors.New("invalid token"))
)

var passMethods = []string{
	authv1connect.AuthServiceInitiateEmailProcedure,
	authv1connect.AuthServiceCompleteEmailProcedure,
	authv1connect.AuthServiceUseGoogleProcedure,
}

func EnsureValidTokenInterceptor(tokens tokens.Tokens, apim apimetadata.ApiMetadata) connect.UnaryInterceptorFunc {
	return func(next connect.UnaryFunc) connect.UnaryFunc {
		return func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
			if isPassMethod(req.Spec().Procedure) {
				return next(ctx, req)
			}

			token := req.Header().Get("Authorization")
			if token == "" {
				return nil, connect.NewError(connect.CodeUnauthenticated, errMissingAuthorizationHeader)
			}

			token = strings.TrimPrefix(token, "Bearer ")

			claims, err := tokens.ParseToken(token)
			if err != nil {
				return nil, connect.NewError(connect.CodeUnauthenticated, errInvalidToken)
			}

			ctxWithClaims := apim.ContextWithClaims(ctx, *claims)

			return next(ctxWithClaims, req)
		}
	}
}

func isPassMethod(procedure string) bool {
	for _, pm := range passMethods {
		if procedure == pm {
			return true
		}
	}
	return false
}
