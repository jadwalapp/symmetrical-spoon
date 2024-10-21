package interceptors

import (
	"context"

	"connectrpc.com/connect"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/apimetadata"
	"github.com/rs/zerolog/log"
)

func LangInterceptor(apim apimetadata.ApiMetadata) connect.UnaryInterceptorFunc {
	return func(next connect.UnaryFunc) connect.UnaryFunc {
		return func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
			lang := req.Header().Get("x-lang")
			language := apimetadata.Lang_English

			switch lang {
			case string(apimetadata.Lang_Arabic):
				language = apimetadata.Lang_Arabic
			case string(apimetadata.Lang_English):
				language = apimetadata.Lang_English
			default:
				log.Info().Msg("x-lang header was empty :D")
			}

			ctxWithLang := apim.ContextWithLang(ctx, language)

			return next(ctxWithLang, req)
		}
	}
}
