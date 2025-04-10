package wasappcalendar

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/google/uuid"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/services/calendarsvc"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/services/notificationsvc"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/store"
	amqp "github.com/rabbitmq/amqp091-go"
	"github.com/rs/zerolog/log"
)

const (
	whatsAppCalendarName       = "📱 WhatsApp Events"
	whatsAppCalendarPathSuffix = "whatsapp-events/"
	whatsAppCalendarColor      = "#2ECC71" // Green color
	consumerTag                = "falak-calendar"
)

type consumer struct {
	channel                     *amqp.Channel
	calendarEventsQueueName     string
	store                       store.Queries
	calendarSvc                 calendarsvc.Svc
	calDAVPasswordEncryptionKey string
	notificationSvc             notificationsvc.Svc
}

func (c *consumer) Start(ctx context.Context) error {
	log.Ctx(ctx).Info().Msgf("starting calendar consumer for queue: %s", c.calendarEventsQueueName)

	_, err := c.channel.QueueDeclare(
		c.calendarEventsQueueName,
		true,  // durable
		false, // delete when unused
		false, // exclusive
		false, // no-wait
		nil,   // arguments
	)
	if err != nil {
		return fmt.Errorf("failed to declare queue: %w", err)
	}

	msgsChan, err := c.channel.Consume(
		c.calendarEventsQueueName, // queue
		consumerTag,               // consumer
		false,                     // autoAck
		false,                     // exclusive
		false,                     // noLocal
		false,                     // noWait
		nil,                       // args
	)
	if err != nil {
		log.Ctx(ctx).Err(err).Msgf("failed to consume queue: %s", c.calendarEventsQueueName)
		return err
	}

	log.Ctx(ctx).Info().Msg("successfully started consuming calendar messages")

	go func() {
		for {
			select {
			case <-ctx.Done():
				log.Ctx(ctx).Info().Msg("context cancelled, stopping calendar consumer")
				return
			case msg, ok := <-msgsChan:
				if !ok {
					log.Ctx(ctx).Info().Msg("calendar message channel closed, stopping consumer")
					return
				}

				c.processMessage(ctx, msg)
			}
		}
	}()

	return nil
}

func (c *consumer) processMessage(ctx context.Context, msg amqp.Delivery) {
	var eventData CalendarEventData
	if err := json.Unmarshal(msg.Body, &eventData); err != nil {
		log.Ctx(ctx).Err(err).Msg("failed to unmarshal calendar event")
		_ = msg.Nack(
			false, // multiple
			true,  // requeue for retry
		)
		return
	}

	logger := log.Ctx(ctx).With().
		Str("customer_id", eventData.CustomerID.String()).
		Str("chat_id", eventData.ChatID).
		Str("event_summary", eventData.Summary).
		Time("event_start", eventData.StartTime).
		Time("event_end", eventData.EndTime).
		Logger()

	logger.Info().Msg("processing calendar event")

	credentials, err := c.store.GetCalDavAccountByCustomerId(ctx, store.GetCalDavAccountByCustomerIdParams{
		CustomerID:    eventData.CustomerID,
		EncryptionKey: c.calDAVPasswordEncryptionKey,
	})
	if err != nil {
		logger.Err(err).Msg("failed to get customer credentials")
		_ = msg.Nack(
			false, // multiple
			true,  // requeue for retry
		)
		return
	}

	uid := fmt.Sprintf("%s@jadwal.app", uuid.New().String())

	err = c.calendarSvc.InitCalendar(ctx, &calendarsvc.InitCalendarRequest{
		CustomerID:  eventData.CustomerID,
		Username:    credentials.Username,
		Password:    credentials.DecryptedPassword,
		PathSuffix:  whatsAppCalendarPathSuffix,
		DisplayName: whatsAppCalendarName,
		Color:       whatsAppCalendarColor,
	})
	if err != nil {
		logger.Err(err).Msg("failed to initialize WhatsApp calendar")
		_ = msg.Nack(
			false, // multiple
			true,  // requeue for retry
		)
		return
	}

	logger.Debug().Msg("initialized WhatsApp calendar")

	err = c.calendarSvc.AddEvent(ctx, &calendarsvc.AddEventRequest{
		CustomerID:  eventData.CustomerID,
		Summary:     eventData.Summary,
		Description: eventData.Description,
		StartTime:   eventData.StartTime,
		EndTime:     eventData.EndTime,
		UID:         uid,
	})
	if err != nil {
		logger.Err(err).Msg("failed to add event to calendar")
		_ = msg.Nack(
			false, // multiple
			true,  // requeue for retry
		)
		return
	}

	logger.Info().Msg("successfully added event to WhatsApp calendar")

	// Prepare data for notification
	calendarName := whatsAppCalendarName
	uidForNotification := uid // Use the generated UID
	eventTitleForNotification := eventData.Summary
	eventStartDate := eventData.StartTime
	eventEndDate := eventData.EndTime

	err = c.notificationSvc.SendNotificationToCustomerDevices(ctx, &notificationsvc.SendNotificationToCustomerDevicesRequest{
		CustomerId: eventData.CustomerID,
		AlertTitle: "📅 New WhatsApp Event Added",                                                     // Title for the visible alert
		AlertBody:  fmt.Sprintf("Event '%s' was added to your WhatsApp calendar", eventData.Summary), // Body for the visible alert
		// Pass details for the background notification
		EventUID:       &uidForNotification,
		EventTitle:     &eventTitleForNotification,
		EventStartDate: &eventStartDate,
		EventEndDate:   &eventEndDate,
		CalendarName:   &calendarName,
	})
	if err != nil {
		logger.Err(err).Msg("failed to send push notification")
	} else {
		logger.Debug().Msg("sent push notification successfully")
	}

	if err := msg.Ack(false); err != nil {
		logger.Err(err).Msg("failed to acknowledge message")
	} else {
		logger.Debug().Msg("acknowledged message successfully")
	}
}

func (c *consumer) Stop(ctx context.Context) error {
	log.Ctx(ctx).Info().Msg("stopping calendar consumer")
	if err := c.channel.Close(); err != nil {
		log.Ctx(ctx).Err(err).Msg("failed to close the channel")
		return err
	}
	return nil
}

func NewConsumer(channel *amqp.Channel, calendarEventsQueueName string, store store.Queries, calendarSvc calendarsvc.Svc,
	calDAVPasswordEncryptionKey string, notificationSvc notificationsvc.Svc) Consumer {
	return &consumer{
		channel:                     channel,
		calendarEventsQueueName:     calendarEventsQueueName,
		store:                       store,
		calendarSvc:                 calendarSvc,
		calDAVPasswordEncryptionKey: calDAVPasswordEncryptionKey,
		notificationSvc:             notificationSvc,
	}
}
