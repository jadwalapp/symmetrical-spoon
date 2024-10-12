package interceptors

import (
	"context"
	"os"
	"strings"

	authpb "github.com/muwaqqit/symmetrical-spoon/falak/pkg/api/auth/proto"
	"github.com/muwaqqit/symmetrical-spoon/falak/pkg/apimetadata"
	tokens "github.com/muwaqqit/symmetrical-spoon/falak/pkg/tokens"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

var (
	errMissingMetadata            = status.Errorf(codes.InvalidArgument, "missing metadata")
	errMissingAuthorizationHeader = status.Errorf(codes.Unauthenticated, "missing authorization header")
	errInvalidToken               = status.Errorf(codes.Unauthenticated, "invalid token")
)

var passMethods = []string{
	authpb.Auth_InitiateEmail_FullMethodName,
	authpb.Auth_CompleteEmail_FullMethodName,
	authpb.Auth_UseGoogle_FullMethodName,
}

func EnsureValidTokenInterceptor(tokens tokens.Tokens, apim apimetadata.ApiMetadata) grpc.UnaryServerInterceptor {
	return func(ctx context.Context, req any, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (any, error) {
		return EnsureValidToken(ctx, req, info, handler, tokens, apim)
	}
}

func EnsureValidToken(ctx context.Context, req any, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler, t tokens.Tokens, apim apimetadata.ApiMetadata) (any, error) {
	for _, pm := range passMethods {
		if info.FullMethod == pm {
			log.Ctx(ctx).Debug().Msg("no need for authentication")
			return handler(ctx, req)
		}
	}

	md, ok := metadata.FromIncomingContext(ctx)
	if !ok {
		log.Ctx(ctx).Error().Msg("missing metadata")
		return nil, errMissingMetadata
	}

	authHeader := md["authorization"]
	if len(authHeader) < 1 {
		log.Ctx(ctx).Error().Msg("missing authorization header")
		return nil, errMissingAuthorizationHeader
	}

	token := strings.TrimPrefix(authHeader[0], "Bearer ")

	claims, err := t.ParseToken(token)
	if err != nil {
		log.Ctx(ctx).Error().Msg("invalid token")
		return nil, errInvalidToken
	}

	ctxWithClaims := apim.ContextWithClaims(ctx, *claims)

	return handler(ctxWithClaims, req)
}

func LoggingInterceptor(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {
	logger := zerolog.New(os.Stderr).With().Timestamp().Str("service", info.FullMethod).Logger()
	ctx = logger.WithContext(ctx)

	return handler(ctx, req)
}
