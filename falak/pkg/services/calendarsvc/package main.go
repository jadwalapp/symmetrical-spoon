package calendarsvc

import (
	"encoding/json"
	"my-whatsapp-event-extractor/openai"
	"my-whatsapp-event-extractor/whatsapp"
	"net/http"

	"github.com/gin-genic/gin"
)

func main() {
	router := gin.Default()

	router.POST("/webhook", func(c *gin.Context) {
		var msg whatsapp.WhatsAppMessage
		if err := c.ShouldBindJSON(&msg); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		events := calendar.ExtractEvents(msg.Message)

		if len(events) > 0 {
			var responses []string
			for _, event := range events {
				eventJSON, _ := json.Marshal(event)
				response, err := openai.CallOpenAI(string(eventJSON))
				if err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				responses = append(responses, response)
			}

			c.JSON(http.StatusOK, gin.H{"events": events, "openAIResponses": responses})
		} else {
			c.JSON(http.StatusOK, gin.H{"events": []string{"NO"}})
		}
	})

	router.Run(":8080")
}
