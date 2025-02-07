package wasappmsganalyzer

import "context"

type AnalyzeMessageRequest struct {
}

type Analyzer interface {
	AnalyzeMessage(context.Context)
}
