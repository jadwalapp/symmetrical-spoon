package notificationsvc

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/apple/apns"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/store"
	"github.com/rs/zerolog"
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
		Str("alert_title", r.AlertTitle).
		Logger()

	devices, err := s.store.ListDeviceByCustomerId(ctx, r.CustomerId)
	if err != nil {
		logger.Err(err).Msg("failed running ListDeviceByCustomerId")
		return err
	}

	logger.Info().Int("device_count", len(devices)).Msg("found devices for customer")

	foregroundPayload := payload.NewPayload().
		AlertTitle(r.AlertTitle).
		AlertBody(r.AlertBody).
		Sound("default")

	var backgroundPayload *payload.Payload
	if r.EventUID != nil && r.EventTitle != nil && r.EventStartDate != nil && r.EventEndDate != nil {
		backgroundP := payload.NewPayload().
			ContentAvailable().
			Custom("event_uid", *r.EventUID).
			Custom("event_title", *r.EventTitle).
			Custom("event_start", r.EventStartDate.UTC().Format(time.RFC3339)).
			Custom("event_end", r.EventEndDate.UTC().Format(time.RFC3339))

		if r.CalendarName != nil {
			backgroundP = backgroundP.Custom("calendar_name", *r.CalendarName)
		}
		backgroundPayload = backgroundP
	} else if r.EventUID != nil {
		logger.Warn().Msg("EventUID provided, but missing other required fields (Title, StartDate, EndDate) for background event processing.")
	}

	deviceIdsToDelete := make([]uuid.UUID, 0)
	for _, device := range devices {
		deviceLogger := logger.With().
			Str("device_id", device.ID.String()).
			Logger()

		if err := s.sendNotification(deviceLogger, device, foregroundPayload, apns2.PushTypeAlert, &deviceIdsToDelete); err != nil {
			deviceLogger.Err(err).Msg("failed to send foreground notification")
			continue
		}

		if backgroundPayload != nil {
			if err := s.sendNotification(deviceLogger, device, backgroundPayload, apns2.PushTypeBackground, &deviceIdsToDelete); err != nil {
				deviceLogger.Err(err).Msg("failed to send background notification")
				continue
			}
		} else {
			deviceLogger.Info().Msg("no background notification payload generated")
		}
	}

	if len(deviceIdsToDelete) > 0 {
		deviceIdsToDeleteStr := make([]string, len(deviceIdsToDelete))
		for i, id := range deviceIdsToDelete {
			deviceIdsToDeleteStr[i] = id.String()
		}

		logger.Info().Int("delete_count", len(deviceIdsToDelete)).Msg("deleting invalid devices")
		err := s.store.DeleteDevices(ctx, deviceIdsToDeleteStr)
		if err != nil {
			logger.Err(err).Msg("failed running DeleteDevices")
		}
	}

	return nil
}

func (s *svc) sendNotification(logger zerolog.Logger, device store.Device, payload *payload.Payload, pushType apns2.EPushType, deviceIdsToDelete *[]uuid.UUID) error {
	resp, err := s.apns.Send(device.ApnsToken, payload, pushType)
	if err != nil {
		return err
	}

	logger.Info().
		Int("status_code", resp.StatusCode).
		Str("reason", resp.Reason).
		Str("apns_id", resp.ApnsID).
		Interface("response", resp).
		Msg("raw apns response")

	if resp.StatusCode != apns2.StatusSent {
		logger.Warn().
			Int("status_code", resp.StatusCode).
			Str("reason", resp.Reason).
			Str("apns_id", resp.ApnsID).
			Msg("push notification not sent")

		switch resp.Reason {
		case apns2.ReasonUnregistered, apns2.ReasonExpiredToken, apns2.ReasonBadDeviceToken:
			*deviceIdsToDelete = append(*deviceIdsToDelete, device.ID)
			logger.Info().Msg("marking device for deletion due to invalid token")
		}
		return nil
	}

	logger.Info().Str("apns_id", resp.ApnsID).Msg("push notification sent successfully")
	return nil
}

func NewSvc(store store.Queries, apns apns.APNS) Svc {
	return &svc{
		store: store,
		apns:  apns,
	}
}
