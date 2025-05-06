package wasappcalendar

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/ThreeDotsLabs/watermill"
	"github.com/ThreeDotsLabs/watermill-amqp/v3/pkg/amqp"
	"github.com/ThreeDotsLabs/watermill/message"
	"github.com/rs/zerolog/log"
)

type producer struct {
	publisher               *amqp.Publisher
	calendarEventsQueueName string
}

func (p *producer) PublishEvent(ctx context.Context, event CalendarEventData) error {
	eventJsonBytes, err := json.Marshal(event)
	if err != nil {
		return fmt.Errorf("failed to marshal event: %w", err)
	}

	msg := message.NewMessage(watermill.NewUUID(), eventJsonBytes)

	err = p.publisher.Publish(p.calendarEventsQueueName, msg)
	if err != nil {
		return fmt.Errorf("failed to publish message: %w", err)
	}

	log.Ctx(ctx).Info().
		Str("customer_id", event.CustomerID.String()).
		Str("chat_id", event.ChatID).
		Msg("successfully published event to calendar queue")

	return nil
}

func NewProducer(publisher *amqp.Publisher, calendarEventsQueueName string) Producer {
	return &producer{
		publisher:               publisher,
		calendarEventsQueueName: calendarEventsQueueName,
	}
}
