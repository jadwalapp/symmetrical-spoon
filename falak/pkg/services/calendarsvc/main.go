package calendarsvc

import (
	"encoding/json"
	"net/http"

	"my-whatsapp-event-extractor/whatsapps" // This import is necessary for WhatsApp message handling

	"github.com/gin-gonic/gin"
)

// StartServer initializes the HTTP server
func StartServer() {
	router := gin.Default()

	router.POST("/webhook", func(c *gin.Context) {
		var msg whatsapps.WhatsAppMessage
		if err := c.ShouldBindJSON(&msg); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		events := ExtractEvents(msg.Message) // Directly call ExtractEvents

		if len(events) > 0 {
			var responses []string
			for _, event := range events {
				eventJSON, _ := json.Marshal(event)
				response, err := whatsapps.CallOpenAI(string(eventJSON)) // Call OpenAI function
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
