package calendarsvc

import (
    "encoding/json"
    "net/http"
    "my-whatsapp-event-extractor/whatsappsvc" // Importing WhatsApp package

    "github.com/gin-gonic/gin" // Importing Gin framework
)

// StartServer initializes the HTTP server
func StartServer() error {
    router := gin.Default()

    router.POST("/webhook", func(c *gin.Context) {
        var msg whatsappsvc.WhatsAppMessage
        if err := c.ShouldBindJSON(&msg); err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }

        events := ExtractEvents(msg.Message) // Call to ExtractEvents function (assuming it's defined)

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

    return router.Run(":50064") 
}

module my-whatsapp-event-extractor

go 1.18 // or your current Go version

require (
    github.com/gin-gonic/gin v1.7.4 // Ensure Gin is included
)