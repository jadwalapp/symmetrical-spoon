package interceptors

import (
	"context"
	"os"

	"connectrpc.com/connect"
	"github.com/rs/zerolog"
)

func LoggingInterceptor() connect.UnaryInterceptorFunc {
	return func(next connect.UnaryFunc) connect.UnaryFunc {
		return func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
			logger := zerolog.New(os.Stderr).With().Timestamp().Str("service", req.Spec().Procedure).Logger()
			ctx = logger.WithContext(ctx)

			return next(ctx, req)
		}
	}
}
