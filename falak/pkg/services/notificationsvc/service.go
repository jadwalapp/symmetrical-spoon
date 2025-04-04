package notificationsvc

import (
	"context"

	"github.com/google/uuid"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/apple/apns"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/store"
	"github.com/rs/zerolog/log"
	"github.com/sideshow/apns2"
	"github.com/sideshow/apns2/payload"
)

type svc struct {
	store store.Queries
	apns  apns.APNS
}

func (s *svc) SendNotificationToCustomerDevices(ctx context.Context, r *SendNotificationToCustomerDevicesRequest) error {
	logger := log.Ctx(ctx).With().
		Str("customer_id", r.CustomerId.String()).
		Str("title", r.Title).
		Logger()

	devices, err := s.store.ListDeviceByCustomerId(ctx, r.CustomerId)
	if err != nil {
		logger.Err(err).Msg("failed running ListDeviceByCustomerId")
		return err
	}

	logger.Info().Int("device_count", len(devices)).Msg("found devices for customer")

	deviceIdsToDelete := make([]uuid.UUID, 0)
	for _, device := range devices {
		deviceLogger := logger.With().
			Str("device_id", device.ID.String()).
			Str("device_token", device.ApnsToken).
			Logger()

		payload := payload.NewPayload().AlertTitle(r.Title).AlertBody(r.Body)
		resp, err := s.apns.Send(device.ApnsToken, payload)
		if err != nil {
			deviceLogger.Err(err).Msg("failed to send push notification to device")
			continue
		}

		if resp.StatusCode != apns2.StatusSent {
			deviceLogger.Warn().
				Int("status_code", resp.StatusCode).
				Str("reason", resp.Reason).
				Str("apns_id", resp.ApnsID).
				Msg("push notification not sent")

			switch resp.Reason {
			case apns2.ReasonUnregistered, apns2.ReasonExpiredToken, apns2.ReasonBadDeviceToken:
				deviceIdsToDelete = append(deviceIdsToDelete, device.ID)
				deviceLogger.Info().Msg("marking device for deletion due to invalid token")
			}
		} else {
			deviceLogger.Info().Str("apns_id", resp.ApnsID).Msg("push notification sent successfully")
		}
	}

	if len(deviceIdsToDelete) > 0 {
		logger.Info().Int("delete_count", len(deviceIdsToDelete)).Msg("deleting invalid devices")
		err := s.store.DeleteDevices(ctx, deviceIdsToDelete)
		if err != nil {
			logger.Err(err).Msg("failed running DeleteDevices")
		}
	}

	return nil
}

func NewSvc(store store.Queries, apns apns.APNS) Svc {
	return &svc{
		store: store,
		apns:  apns,
	}
}
