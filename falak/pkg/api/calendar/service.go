package calendar

import (
	"github.com/bufbuild/protovalidate-go"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/gen/proto/calendar/v1/calendarv1connect"
)

type service struct {
	pv protovalidate.Validator

	calendarv1connect.UnimplementedCalendarServiceHandler
}

func NewService(pv protovalidate.Validator) calendarv1connect.CalendarServiceHandler {
	return &service{
		pv: pv,
	}
}
