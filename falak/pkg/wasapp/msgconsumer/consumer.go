package wasappmsgconsumer

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/ThreeDotsLabs/watermill-amqp/v3/pkg/amqp"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/store"
	wasappcalendar "github.com/jadwalapp/symmetrical-spoon/falak/pkg/wasapp/calendar"
	wasappmsganalyzer "github.com/jadwalapp/symmetrical-spoon/falak/pkg/wasapp/msganalyzer"
	"github.com/rs/zerolog/log"
)

type consumer struct {
	subscriber                    *amqp.Subscriber
	wasappMessagesQueueName       string
	store                         store.Queries
	msgAnalyzer                   wasappmsganalyzer.Analyzer
	calendarProducer              wasappcalendar.Producer
	whatsappMessagesEncryptionKey string
}

func (c *consumer) Start(ctx context.Context) error {
	log.Ctx(ctx).Info().Msgf("starting consumer for queue: %s", c.wasappMessagesQueueName)

	msgsChan, err := c.subscriber.Subscribe(ctx, c.wasappMessagesQueueName)
	if err != nil {
		return fmt.Errorf("failed to subscribe to topic: %w", err)
	}

	log.Ctx(ctx).Info().Msg("successfully started consuming messages")

	go func() {
		for {
			select {
			case <-ctx.Done():
				log.Ctx(ctx).Info().Msg("context cancelled, stopping consumer")
				return
			case msg, ok := <-msgsChan:
				if !ok {
					log.Ctx(ctx).Info().Msg("message channel closed, stopping consumer")
					return
				}

				var wasappMsg WasappMessage
				if err := json.Unmarshal(msg.Payload, &wasappMsg); err != nil {
					log.Ctx(ctx).Err(err).Msg("failed to unmarshall the wasapp message in the body")
					if didNotSendAck := msg.Nack(); didNotSendAck {
						log.Ctx(ctx).Err(err).Msg("failed to Nack the message, cuz Ack already sent")
					}
					continue
				}

				log.Ctx(ctx).Info().
					Str("customer_id", wasappMsg.CustomerID.String()).
					Str("chat_id", wasappMsg.ChatID).
					Str("message_id", wasappMsg.ID).
					Msg("processing new message")

				msgs, err := c.store.AddMessageToChatReturningMessages(ctx, store.AddMessageToChatReturningMessagesParams{
					CustomerID:    wasappMsg.CustomerID,
					ChatID:        wasappMsg.ChatID,
					MessageID:     wasappMsg.ID,
					SenderName:    wasappMsg.SenderName,
					SenderNumber:  wasappMsg.SenderNumber,
					IsSenderMe:    wasappMsg.IsSenderMe,
					Body:          wasappMsg.Body,
					Timestamp:     wasappMsg.Timestamp,
					EncryptionKey: c.whatsappMessagesEncryptionKey,
				})
				if err != nil {
					log.Ctx(ctx).Err(err).
						Str("chat_id", wasappMsg.ChatID).
						Msg("failed running AddMessageToChatReturningMessages")
					continue
				}

				log.Ctx(ctx).Debug().
					Int("messages_count", len(msgs)).
					Str("chat_id", wasappMsg.ChatID).
					Msg("retrieved messages for analysis")

				msgsForAnalysis := make([]wasappmsganalyzer.MessageForAnalysis, len(msgs))
				for idx, msg := range msgs {
					msgsForAnalysis[idx] = mapAddMessageToChatReturningMessagesRowToMessageForAnalysis(msg)
				}
				analysisResp, err := c.msgAnalyzer.AnalyzeMessages(ctx, &wasappmsganalyzer.AnalyzeMessagesRequest{
					Messages: msgsForAnalysis,
				})
				if err != nil {
					log.Ctx(ctx).Err(err).
						Str("chat_id", wasappMsg.ChatID).
						Msg("failed running msgAnalyzer.AnalyzeMessages")
					continue
				}

				log.Ctx(ctx).Info().
					Str("chat_id", wasappMsg.ChatID).
					Str("analysis_status", string(analysisResp.Status)).
					Msg("message analysis completed")

				if len(msgs) > 0 {
					chatID := msgs[0].ChatID

					switch analysisResp.Status {
					case wasappmsganalyzer.AnalyzeMessagesStatus_HasEventAgreed:
						log.Ctx(ctx).Info().
							Str("chat_id", chatID).
							Msg("event agreed, proceeding to add to calendar queue")

						eventData := mapAnalysisResponseToCalendarEvent(
							ctx,
							wasappMsg.CustomerID,
							chatID,
							analysisResp,
						)

						err = c.calendarProducer.PublishEvent(ctx, eventData)
						if err != nil {
							log.Ctx(ctx).Err(err).
								Str("chat_id", chatID).
								Msg("failed to publish event to calendar queue")
						} else {
							log.Ctx(ctx).Info().
								Str("chat_id", chatID).
								Msg("successfully published event to calendar queue")
						}

						err = c.store.DeleteChat(ctx, store.DeleteChatParams{
							ChatID:     chatID,
							CustomerID: wasappMsg.CustomerID,
						})
						if err != nil {
							log.Ctx(ctx).Err(err).
								Str("chat_id", chatID).
								Msg("failed running store.DeleteChat")
							if didNotSendAck := msg.Nack(); didNotSendAck {
								log.Ctx(ctx).Err(err).Msg("failed to Nack the message, cuz Ack already sent")
							}
							continue
						}
					case wasappmsganalyzer.AnalyzeMessagesStatus_HasEventDenied:
						log.Ctx(ctx).Info().
							Str("chat_id", chatID).
							Msg("event denied, proceeding to delete chat")
						err = c.store.DeleteChat(ctx, store.DeleteChatParams{
							ChatID:     chatID,
							CustomerID: wasappMsg.CustomerID,
						})
						if err != nil {
							log.Ctx(ctx).Err(err).
								Str("chat_id", chatID).
								Msg("failed running store.DeleteChat")
							if didNotSendAck := msg.Nack(); didNotSendAck {
								log.Ctx(ctx).Err(err).Msg("failed to Nack the message, cuz Ack already sent")
							}
							continue
						}
					case wasappmsganalyzer.AnalyzeMessagesStatus_HasEventButNotConfirmed:
						log.Ctx(ctx).Debug().
							Str("chat_id", chatID).
							Msg("event not confirmed yet, keeping chat")
						fallthrough
					case wasappmsganalyzer.AnalyzeMessagesStatus_NoEvent:
						log.Ctx(ctx).Debug().
							Str("chat_id", chatID).
							Msg("no event detected, keeping chat")
					}
				}

				if didNotSendNack := msg.Ack(); didNotSendNack {
					log.Ctx(ctx).Err(err).Msg("failed to Ack message, cuz Nack was already sent")
				} else {
					log.Ctx(ctx).Debug().Msg("acknowledged message successfully")
				}
			}
		}
	}()

	return nil
}

func (c *consumer) Stop(ctx context.Context) error {
	log.Ctx(ctx).Info().Msg("stopping consumer")
	// if err := c.channel.Close(); err != nil {
	// 	log.Ctx(ctx).Err(err).Msg("failed to close the channel")
	// 	return err
	// }
	log.Ctx(ctx).Info().Msg("consumer stopped successfully")
	return nil
}

func NewConsumer(subscriber *amqp.Subscriber, wasappMessagesQueueName string, store store.Queries, msgAnalyzer wasappmsganalyzer.Analyzer, calendarProducer wasappcalendar.Producer, whatsappMessagesEncryptionKey string) Consumer {
	return &consumer{
		subscriber:                    subscriber,
		wasappMessagesQueueName:       wasappMessagesQueueName,
		store:                         store,
		msgAnalyzer:                   msgAnalyzer,
		calendarProducer:              calendarProducer,
		whatsappMessagesEncryptionKey: whatsappMessagesEncryptionKey,
	}
}
