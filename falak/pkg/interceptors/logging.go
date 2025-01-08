package interceptors

import (
	"context"
	"os"
	"time"

	"connectrpc.com/connect"
	"github.com/google/uuid"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/lokilogger"
	"github.com/rs/zerolog"
)

type traceIDKey struct{}

func LoggingInterceptor(lokiClient *lokilogger.LokiClient) connect.UnaryInterceptorFunc {
	return func(next connect.UnaryFunc) connect.UnaryFunc {
		return func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
			traceID, ok := ctx.Value(traceIDKey{}).(string)
			if !ok {
				traceID = uuid.New().String()
				ctx = context.WithValue(ctx, traceIDKey{}, traceID)
			}

			multiLevelWriters := zerolog.MultiLevelWriter(os.Stdout, lokiClient)
			logger := zerolog.New(multiLevelWriters).With().
				Timestamp().
				Str("method", req.Spec().Procedure).
				Str("trace_id", traceID).
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
