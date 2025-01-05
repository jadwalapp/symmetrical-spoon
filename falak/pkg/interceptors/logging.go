package interceptors

import (
	"context"
	"os"
	"time"

	"connectrpc.com/connect"
	"github.com/rs/zerolog"
)

func LoggingInterceptor() connect.UnaryInterceptorFunc {
	return func(next connect.UnaryFunc) connect.UnaryFunc {
		return func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
			logger := zerolog.New(os.Stderr).With().
				Timestamp().
				Str("method", req.Spec().Procedure).
				Logger()
			ctx = logger.WithContext(ctx)

			logger.Info().Msg("Request started")

			start := time.Now()
			resp, err := next(ctx, req)
			duration := time.Since(start)

			if err != nil {
				logger.Error().
					Err(err).
					Dur("duration", duration).
					Msg("Request failed")
				return resp, err
			}

			logger.Info().
				Dur("duration", duration).
				Msg("Request completed")

			return resp, err
		}
	}
}
