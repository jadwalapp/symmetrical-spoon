package wasappmsgconsumer

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/store"
	amqp "github.com/rabbitmq/amqp091-go"
	"github.com/rs/zerolog/log"
)

type consumer struct {
	channel                 *amqp.Channel
	wasappMessagesQueueName string
	store                   store.Queries
}

func (c *consumer) Start(ctx context.Context) error {
	msgsChan, err := c.channel.Consume(
		c.wasappMessagesQueueName, // queue
		"falak",                   // consumer
		false,                     // autoAck
		false,                     // exclusive
		false,                     // noLocal
		false,                     // noWait
		nil,                       // args
	)
	if err != nil {
		log.Ctx(ctx).Err(err).Msgf("failed to consumer queue: %s", c.wasappMessagesQueueName)
		return err
	}

	go func() {
		for {
			select {
			case <-ctx.Done():
				return
			case msg, ok := <-msgsChan:
				if !ok {
					return
				}

				var wasappMsg WasappMessage
				if err := json.Unmarshal(msg.Body, &wasappMsg); err != nil {
					log.Ctx(ctx).Err(err).Msg("failed to unmarshall the wasapp message in the body")
					err = msg.Nack(
						false, // multiple
						true,  // requeue
					)
					if err != nil {
						log.Ctx(ctx).Err(err).Msg("failed to Nack the message")
					}
					continue
				}

				// TODO: add the message to the db under the chat_id
				fmt.Printf("message body read: %v\n", wasappMsg)

				// TODO: check with an LLM with the new context

				if false {
					err = msg.Ack(
						false, // multiple
					)
					if err != nil {
						log.Ctx(ctx).Err(err).Msg("failed to Ack the message")
					}
				}
			}
		}
	}()

	return nil
}

func (c *consumer) Stop(ctx context.Context) error {
	if err := c.channel.Close(); err != nil {
		log.Ctx(ctx).Err(err).Msg("failed to close the channel")
		return err
	}

	return nil
}

func NewConsumer(channel *amqp.Channel, wasappMessagesQueueName string, store store.Queries) Consumer {
	return &consumer{
		channel:                 channel,
		wasappMessagesQueueName: wasappMessagesQueueName,
		store:                   store,
	}
}
