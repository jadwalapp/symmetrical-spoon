package main

import (
	"fmt"
	"net"
	"os"

	"github.com/bufbuild/protovalidate-go"
	"github.com/muwaqqit/symmetrical-spoon/falak/pkg/api/auth"
	authpb "github.com/muwaqqit/symmetrical-spoon/falak/pkg/api/auth/proto"
	"github.com/muwaqqit/symmetrical-spoon/falak/pkg/apimetadata"
	"github.com/muwaqqit/symmetrical-spoon/falak/pkg/interceptors"
	"github.com/muwaqqit/symmetrical-spoon/falak/pkg/tokens"
	"github.com/muwaqqit/symmetrical-spoon/falak/pkg/util"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
)

func main() {
	log.Logger = zerolog.New(os.Stderr).With().Timestamp().Logger()

	config, err := util.LoadGrpcConfig(".")
	if err != nil {
		log.Fatal().Msgf("cannot load config: %v", err)
	}

	// ======== TOKENS ========
	publicKey, err := tokens.ParseRSAPublicKey(config.JWTPublicKey)
	if err != nil {
		log.Fatal().Msgf("cannot parse public key: %v", err)
	}

	privateKey, err := tokens.ParseRSAPrivateKey(config.JWTPrivateKey)
	if err != nil {
		log.Fatal().Msgf("cannot parse private key: %v", err)
	}

	tokens := tokens.NewTokens(publicKey, privateKey)
	// ======== TOKENS ========

	// ======== API METADATA ========
	apiMetadata := apimetadata.NewAPiMetadata()
	// ======== API METADATA ========

	// ======== SERVER ========
	lis, err := net.Listen("tcp", fmt.Sprintf("0.0.0.0:%s", config.Port))
	if err != nil {
		log.Fatal().Msgf("failed to listen: %v", err)
	}
	log.Info().Msgf("listening on %s", lis.Addr())

	opts := []grpc.ServerOption{
		grpc.ChainUnaryInterceptor(
			interceptors.LoggingInterceptor,
			interceptors.EnsureValidTokenInterceptor(tokens, apiMetadata),
		),
	}

	grpcServer := grpc.NewServer(opts...)
	reflection.Register(grpcServer)

	pv, err := protovalidate.New()
	if err != nil {
		log.Fatal().Msgf("cannot create proto validator: %v", err)
	}

	authServer := auth.NewService(*pv)
	authpb.RegisterAuthServer(grpcServer, authServer)

	if err := grpcServer.Serve(lis); err != nil {
		log.Fatal().Err(err).Msg("failed to server grpc server")
	}
	// ======== SERVER ========
}
