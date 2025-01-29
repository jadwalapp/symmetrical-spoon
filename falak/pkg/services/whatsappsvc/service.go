package whatsappsvc

import (
	"my-whatsapp-event-extractor/calendar"
	"net/http"

	"github.com/gin-genic/gin"
)

type Whatsappsvc struct {
	From    string `json:"from"`
	Message string `json:"message"`
}

func HandleWebhook(c *gin.Context) {
	var msg Whatsappsvc
	if err := c.ShouldBindJSON(&msg); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	events := calendar.ExtractEvents(msg.Message)

	if len(events) > 0 {
		c.JSON(http.StatusOK, gin.H{"events": events})
	} else {
		c.JSON(http.StatusOK, gin.H{"events": []string{"NO"}})
	}
}
