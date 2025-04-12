package main

import (
	"context"
	"database/sql"
	"encoding/base64"
	"fmt"
	"net/http"
	"net/url"
	"os"

	"connectrpc.com/connect"
	"connectrpc.com/grpcreflect"
	"github.com/bufbuild/protovalidate-go"
	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	"github.com/golang-migrate/migrate/v4/source/iofs"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/api/auth"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/api/calendar"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/api/profile"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/api/whatsapp"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/apimetadata"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/apple/apns"
	baikalclient "github.com/jadwalapp/symmetrical-spoon/falak/pkg/baikal/client"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/email/emailer"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/email/template"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/gen/proto/auth/v1/authv1connect"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/gen/proto/calendar/v1/calendarv1connect"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/gen/proto/profile/v1/profilev1connect"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/gen/proto/whatsapp/v1/whatsappv1connect"
	googlesvc "github.com/jadwalapp/symmetrical-spoon/falak/pkg/google"
	googleclient "github.com/jadwalapp/symmetrical-spoon/falak/pkg/google/client"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/httpclient"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/httpj"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/interceptors"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/lokilogger"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/services/calendarsvc"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/services/notificationsvc"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/store"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/tokens"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/util"
	wasappcalendar "github.com/jadwalapp/symmetrical-spoon/falak/pkg/wasapp/calendar"
	wasappclient "github.com/jadwalapp/symmetrical-spoon/falak/pkg/wasapp/client"
	wasappmsganalyzer "github.com/jadwalapp/symmetrical-spoon/falak/pkg/wasapp/msganalyzer"
	wasappmsgconsumer "github.com/jadwalapp/symmetrical-spoon/falak/pkg/wasapp/msgconsumer"
	"github.com/openai/openai-go"
	openaioption "github.com/openai/openai-go/option"
	amqp "github.com/rabbitmq/amqp091-go"
	"github.com/resendlabs/resend-go"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"github.com/sideshow/apns2"
	apns2token "github.com/sideshow/apns2/token"
	"golang.org/x/net/http2"
	"golang.org/x/net/http2/h2c"

	_ "github.com/jackc/pgx/v5/stdlib"
)

const dbDriverName = "pgx"

func main() {
	config, err := util.LoadFalakConfig()
	if err != nil {
		log.Fatal().Msgf("cannot load config: %v", err)
	}

	// ======== LOKI CLIENT ========
	lokiHookConfig := lokilogger.LokiConfig{
		PushIntervalSeconds: int64(config.LokiPushIntervalSeconds),
		MaxBatchSize:        config.LokiMaxBatchSize,
		LokiEndpoint:        config.LokiEndpoint,
		ServiceName:         "falak",
	}
	lokiClient := lokilogger.NewLokiClient(&lokiHookConfig)
	// ======== LOKI CLIENT ========

	// ======== LOGGER ========
	multiLevelWriters := zerolog.MultiLevelWriter(os.Stdout, lokiClient)
	log.Logger = zerolog.New(multiLevelWriters).With().Timestamp().Logger()
	// ======== LOGGER ========

	// ======== DATABASE ========
	dbSource := util.CreateDbSource(
		config.DBUser,
		config.DBPassword,
		config.DBHost,
		config.DBPort,
		config.DBName,
		config.DBSSLMode,
	)
	dbConn, err := sql.Open(dbDriverName, dbSource)
	if err != nil {
		log.Fatal().Msgf("cannot connect to postgres database: %v", err)
	}

	dbDriver, err := postgres.WithInstance(dbConn, &postgres.Config{})
	if err != nil {
		log.Fatal().Msgf("cannot create postgres db driver: %v", err)
	}

	iofsMig, err := iofs.New(store.MigrationsFS, "migrations")
	if err != nil {
		log.Fatal().Msgf("cannot create iofs: %v", err)
	}

	migStore, err := migrate.NewWithInstance(
		"iofs",
		iofsMig,
		dbDriverName,
		dbDriver,
	)
	if err != nil {
		log.Fatal().Msgf("cannot create store migration instance: %v", err)
	}
	defer migStore.Close()
	defer dbDriver.Close()
	defer dbConn.Close()

	err = migStore.Up()
	if err != nil && err != migrate.ErrNoChange {
		log.Fatal().Msgf("cannot run store migrations up: %v", err)
	}

	dbStore := store.New(dbConn)
	// ======== DATABASE ========

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
	apiMetadata := apimetadata.NewApiMetadata()
	// ======== API METADATA ========

	// ======== RESEND ========
	resendCli := resend.NewClient(config.ResendApiKey)
	// ======== RESEND ========

	// ======== EMAILER ========
	var emailerImpl emailer.Emailer
	switch config.EmailerName {
	case string(emailer.EmailerName_SMTP):
		emailerImpl = emailer.NewSmtpEmailer(config.SMTPHost, config.SMTPPort, config.SMTPUSername, config.SMTPPasword)
	case string(emailer.EmailerName_Stdout):
		emailerImpl = emailer.NewStdoutEmailer()
	case string(emailer.EmailerName_Resend):
		emailerImpl = emailer.NewResendEmailer(*resendCli)
	}
	// ======== EMAILER ========

	// ======== TEMPLATES ========
	templates := template.NewTemplates(config.Domain)
	// ======== TEMPLATES ========

	// ======== GOOGLE CLIENT ========
	googleHttpCli := httpclient.NewClient(&http.Client{})
	googleCli := googleclient.NewClient(googleHttpCli, config.GoogleClientBaseUrl)
	// ======== GOOGLE CLIENT ========

	// ======== GOOGLE SVC ========
	googleSvc := googlesvc.NewService(config.GoogleOAuthClientId, googleCli)
	// ======== GOOGLE SVC ========

	// ======== BAIKAL CLIENT ========
	baikalHttpCli := httpclient.NewClient(&http.Client{})
	baikalCli := baikalclient.NewClient(baikalHttpCli, config.BaikalHost, config.BaikalPhpSessionID)
	// ======== BAIKAL CLIENT ========

	// ======== BAIKAL CLIENT ========
	wasappHttpCli := httpclient.NewClient(&http.Client{})
	wasappCli := wasappclient.NewClient(wasappHttpCli, config.WasappBaseUrl)
	// ======== BAIKAL CLIENT ========

	// ======== AMQP CHAN ========
	amqpUrl := util.CreateAmqpSource(
		config.RabbitMqUser,
		config.RabbitMqPass,
		config.RabbitMqHost,
		config.RabbitMqPort,
	)
	amqpConn, err := amqp.Dial(amqpUrl)
	if err != nil {
		log.Fatal().Msgf("failed to dial amqp: %v", err)
	}

	amqpChan, err := amqpConn.Channel()
	if err != nil {
		log.Fatal().Msgf("failed to open an amqp channel: %v", err)
	}
	defer amqpChan.Close()
	defer amqpConn.Close()
	// ======== AMQP CHAN ========

	// ======== LLM CLI ========
	llmHttpiCli := &http.Client{}
	if config.ProxyUrl != "" {
		proxyURL, err := url.Parse(config.ProxyUrl)
		if err != nil {
			log.Fatal().Msgf("Failed to parse proxy URL: %v", err)
		}

		defaultTransportCopy := http.DefaultTransport.(*http.Transport).Clone()
		defaultTransportCopy.Proxy = http.ProxyURL(proxyURL)
		llmHttpiCli.Transport = defaultTransportCopy

	}

	llmCli := openai.NewClient(
		openaioption.WithBaseURL(config.OpenAiBaseUrl),
		openaioption.WithAPIKey(config.OpenAiApiKey),
		openaioption.WithHTTPClient(llmHttpiCli),
	)
	// ======== LLM CLI ========

	// ======== MSG ANALYZER ========
	msgAnalyzer := wasappmsganalyzer.NewAnalyzer(llmCli, config.OpenAiModelName)
	// ======== MSG ANALYZER ========

	// ======== CALENDAR SERVICE ========
	calendarService := calendarsvc.NewSvc(config.BaikalHost, *dbStore)
	// ======== CALENDAR SERVICE ========

	// ======== WASAPP CALENDAR PRODUCER ========
	wasappCalendarProducer := wasappcalendar.NewProducer(amqpChan, config.WasappCalendarEventsQueueName)
	// ======== WASAPP CALENDAR PRODUCER ========

	// ======== APNS ========
	apnsAuthKeyBytes, err := base64.StdEncoding.DecodeString(config.ApnsAuthKey)
	if err != nil {
		log.Fatal().Msgf("failed to decode base64 APNS auth key: %v", err)
	}

	apns2AuthKey, err := apns2token.AuthKeyFromBytes(apnsAuthKeyBytes)
	if err != nil {
		log.Fatal().Msgf("failed to parse apns auth key from bytes: %v", err)
	}

	apns2ClientToken := &apns2token.Token{
		AuthKey: apns2AuthKey,
		KeyID:   config.ApnsKeyID,
		TeamID:  config.ApnsTeamID,
	}
	apns2Client := apns2.NewTokenClient(apns2ClientToken)
	if config.IsProd {
		apns2Client.Production()
	}
	apns := apns.NewApns(*apns2Client)
	// ======== APNS ========

	// ======== NOTIFICATION SERVICE ========
	notificationSvc := notificationsvc.NewSvc(*dbStore, apns)
	// ======== NOTIFICATION SERVICE ========

	// ======== CALENDAR CONSUMER ========
	calendarConsumerCtx := context.Background()
	calendarConsumerCtx = log.Logger.WithContext(calendarConsumerCtx)

	calendarConsumer := wasappcalendar.NewConsumer(amqpChan, config.WasappCalendarEventsQueueName, *dbStore, calendarService, config.CalDAVPasswordEncryptionKey, notificationSvc)
	err = calendarConsumer.Start(calendarConsumerCtx)
	if err != nil {
		log.Fatal().Msgf("failed to start calendar consumer: %v", err)
	}
	defer calendarConsumer.Stop(calendarConsumerCtx)
	// ======== CALENDAR CONSUMER ========

	// ======== WASAPP CONSUMER ========
	wasappConsumerCtx := context.Background()
	wasappConsumerCtx = log.Logger.WithContext(wasappConsumerCtx)

	wasappConsumer := wasappmsgconsumer.NewConsumer(
		amqpChan,
		config.WasappMessagesQueueName,
		*dbStore,
		msgAnalyzer,
		wasappCalendarProducer,
		config.WhatsappMessagesEncryptionKey,
	)
	err = wasappConsumer.Start(wasappConsumerCtx)
	if err != nil {
		log.Fatal().Msgf("failed to start wasapp consumer: %v", err)
	}
	defer wasappConsumer.Stop(wasappConsumerCtx)
	// ======== WASAPP CONSUMER ========

	// ======== PROTOVALIDATE ========
	pv, err := protovalidate.New()
	if err != nil {
		log.Fatal().Msgf("cannot create proto validator: %v", err)
	}
	// ======== PROTOVALIDATE ========

	// ======== HTTPJ SERVICE ========
	httpjRouter := httpj.NewRouter(*dbStore, config.CalDAVPasswordEncryptionKey, config.CaldavHost, config.IsProd)
	// ======== HTTPJ SERVICE ========

	// ======== INTERCEPTORS ========
	interceptorsForServer := connect.WithInterceptors(
		interceptors.LoggingInterceptor(lokiClient),
		interceptors.EnsureValidTokenInterceptor(tokens, apiMetadata),
		interceptors.LangInterceptor(apiMetadata),
	)
	// ======== INTERCEPTORS ========

	// ======== SERVER ========
	mux := http.NewServeMux()

	mux.HandleFunc("/httpj", httpjRouter.HandleRoot)
	mux.HandleFunc("/httpj/mobile-config/caldav", httpjRouter.HandleMobileConfigCaldav)
	mux.HandleFunc("/httpj/mobile-config/webcal", httpjRouter.HandleMobileConfigWebcal)

	reflector := grpcreflect.NewStaticReflector(
		authv1connect.AuthServiceName,
		profilev1connect.ProfileServiceName,
		calendarv1connect.CalendarServiceName,
		whatsappv1connect.WhatsappServiceName,
	)
	mux.Handle(grpcreflect.NewHandlerV1(reflector))
	mux.Handle(grpcreflect.NewHandlerV1Alpha(reflector))

	authServer := auth.NewService(*pv, *dbStore, tokens, emailerImpl, templates, apiMetadata, googleSvc, baikalCli, config.CalDAVPasswordEncryptionKey)
	mux.Handle(authv1connect.NewAuthServiceHandler(authServer, interceptorsForServer))

	profileServer := profile.NewService(*pv, *dbStore, apiMetadata)
	mux.Handle(profilev1connect.NewProfileServiceHandler(profileServer, interceptorsForServer))

	calendarServer := calendar.NewService(*pv, *dbStore, apiMetadata, config.CalDAVPasswordEncryptionKey)
	mux.Handle(calendarv1connect.NewCalendarServiceHandler(calendarServer, interceptorsForServer))

	whatsappServer := whatsapp.NewService(*pv, apiMetadata, wasappCli)
	mux.Handle(whatsappv1connect.NewWhatsappServiceHandler(whatsappServer, interceptorsForServer))

	addr := fmt.Sprintf("0.0.0.0:%s", config.Port)
	log.Info().Msgf("listening on %s", addr)

	err = http.ListenAndServe(
		addr,
		h2c.NewHandler(mux, &http2.Server{}),
	)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to server grpc server")
	}
	// ======== SERVER ========
}
