package wasappcalendar

import (
	"context"
	"encoding/json"
	"fmt"

	amqp "github.com/rabbitmq/amqp091-go"
	"github.com/rs/zerolog/log"
)

type producer struct {
	channel                 *amqp.Channel
	calendarEventsQueueName string
}

func (p *producer) PublishEvent(ctx context.Context, event CalendarEventData) error {
	// Ensure the queue exists
	_, err := p.channel.QueueDeclare(
		p.calendarEventsQueueName,
		true,  // durable
		false, // delete when unused
		false, // exclusive
		false, // no-wait
		nil,   // arguments
	)
	if err != nil {
		return fmt.Errorf("failed to declare queue: %w", err)
	}

	// Convert event to JSON
	eventJSON, err := json.Marshal(event)
	if err != nil {
		return fmt.Errorf("failed to marshal event: %w", err)
	}

	// Publish the event
	err = p.channel.PublishWithContext(
		ctx,
		"",                        // exchange
		p.calendarEventsQueueName, // routing key
		false,                     // mandatory
		false,                     // immediate
		amqp.Publishing{
			ContentType:  "application/json",
			Body:         eventJSON,
			DeliveryMode: amqp.Persistent, // Make message persistent
		})

	if err != nil {
		return fmt.Errorf("failed to publish event: %w", err)
	}

	log.Ctx(ctx).Info().
		Str("customer_id", event.CustomerID.String()).
		Str("chat_id", event.ChatID).
		Msg("successfully published event to calendar queue")

	return nil
}

func NewProducer(channel *amqp.Channel, calendarEventsQueueName string) Producer {
	return &producer{
		channel:                 channel,
		calendarEventsQueueName: calendarEventsQueueName,
	}
}
