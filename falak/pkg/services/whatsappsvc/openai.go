package openai

import (
	"bytes"
	"encoding/json"
	"net/http"
	"os"
)

// CallOpenAI sends event details to OpenAI API and returns the response
func CallOpenAI(eventJSON string) (string, error) {
	requestBody, err := json.Marshal(map[string]interface{}{
		"model": "gpt-3.5-turbo",
		"messages": []map[string]interface{}{
			{
				"role":    "user",
				"content": "Manage this event: " + eventJSON,
			},
		},
	})
	if err != nil {
		return "", err
	}

	req, err := http.NewRequest("POST", "https://api.openai.com/v1/chat/completions", bytes.NewBuffer(requestBody))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+os.Getenv("OPENAI_API_KEY"))

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	var result map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&result)

	return result["choices"].([]interface{})[0].(map[string]interface{})["message"].(map[string]interface{})["content"].(string), nil
}
