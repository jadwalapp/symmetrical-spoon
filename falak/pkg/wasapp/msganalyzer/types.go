package wasappmsganalyzer

import "context"

type MessageForAnalysis struct {
	SenderName string
	Body       string
	Timestamp  int64
}

type AnalyzeMessagesRequest struct {
	Messages []MessageForAnalysis
}

type AnalyzeMessagesStatus string

const (
	AnalyzeMessagesStatus_NoEvent                 AnalyzeMessagesStatus = "NO_EVENT"
	AnalyzeMessagesStatus_HasEventButNotConfirmed AnalyzeMessagesStatus = "HAS_EVENT_BUT_NOT_CONFIRMED"
	AnalyzeMessagesStatus_HasEventAgreed          AnalyzeMessagesStatus = "HAS_EVENT_AGREED"
	AnalyzeMessagesStatus_HasEventDenied          AnalyzeMessagesStatus = "HAS_EVENT_DENIED"
)

type AnalyzeMessagesEvent struct {
	Title     *string `json:"title"`
	StartDate *string `json:"start_date"`
	EndDate   *string `json:"end_date"`
	StartTime *string `json:"start_time"`
	EndTime   *string `json:"end_time"`
	Location  *string `json:"location"`
	Notes     *string `json:"notes"`
}

type AnalyzeMessagesResponse struct {
	Status AnalyzeMessagesStatus `json:"status"`
	Event  *AnalyzeMessagesEvent `json:"event"`
}

type Analyzer interface {
	AnalyzeMessages(ctx context.Context, r *AnalyzeMessagesRequest) (*AnalyzeMessagesResponse, error)
}
