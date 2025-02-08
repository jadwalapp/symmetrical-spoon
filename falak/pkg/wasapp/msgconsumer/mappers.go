package wasappmsgconsumer

import (
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/store"
	wasappmsganalyzer "github.com/jadwalapp/symmetrical-spoon/falak/pkg/wasapp/msganalyzer"
)

func mapAddMessageToChatReturningMessagesRowToMessageForAnalysis(row store.AddMessageToChatReturningMessagesRow) wasappmsganalyzer.MessageForAnalysis {
	return wasappmsganalyzer.MessageForAnalysis{
		SenderName: row.SenderName,
		Body:       row.Body,
		Timestamp:  row.Timestamp,
	}
}
