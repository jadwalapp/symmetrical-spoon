package main

import (
	"context"
	"database/sql"
	"encoding/base64"
	"os"
	"time"

	"github.com/google/uuid"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/apple/apns"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/services/notificationsvc"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/store"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/util"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"github.com/sideshow/apns2"

	_ "github.com/jackc/pgx/v5/stdlib"
	apns2token "github.com/sideshow/apns2/token"
)

const dbDriverName = "pgx"

func main() {
	config, err := util.LoadFalakConfig("../.env")
	if err != nil {
		log.Fatal().Msgf("cannot load config: %v", err)
	}

	// ======== LOGGER ========
	// Pretty logging for development
	log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr})
	zerolog.SetGlobalLevel(zerolog.InfoLevel)
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
	defer dbConn.Close()

	dbStore := store.New(dbConn)
	// ======== DATABASE ========

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
	apns := apns.NewApns(*apns2Client)
	// ======== APNS ========

	notifSvc := notificationsvc.NewSvc(*dbStore, apns)

	// ======= APP IS BELOW =======

	ctx := context.Background()
	ctx = log.Logger.WithContext(ctx)

	customerId := uuid.MustParse("a6fdfd15-f18c-4cb6-8112-fe7bcad29097")

	eventId := "BC8764E0-2AEB-43A4-995D-FAD0C18F0148"
	calendarName := "📱 WhatsApp Events"
	uidForNotification := eventId
	eventTitleForNotification := "Hehe"

	gmtPlus3 := time.FixedZone("GMT+3", 3*60*60)

	eventStartDate := time.Date(2025, 3, 30, 4, 0, 0, 0, gmtPlus3)
	eventEndDate := time.Date(2025, 3, 30, 5, 0, 0, 0, gmtPlus3)

	err = notifSvc.SendNotificationToCustomerDevices(ctx, &notificationsvc.SendNotificationToCustomerDevicesRequest{
		CustomerId: customerId,
		AlertTitle: "Hello Brother!",
		AlertBody:  "This is the body :D",
		// Pass details for the background notification
		EventUID:       &uidForNotification,
		EventTitle:     &eventTitleForNotification,
		EventStartDate: &eventStartDate,
		EventEndDate:   &eventEndDate,
		CalendarName:   &calendarName,
	})
	if err != nil {
		log.Ctx(ctx).Fatal().Err(err).Msg("we screwed up sending the message :D")
	}

	log.Ctx(ctx).Info().Msg("Successfully sent notification attempt.")
}
