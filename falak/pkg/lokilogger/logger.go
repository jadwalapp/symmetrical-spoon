package lokilogger

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

type LokiConfig struct {
	PushIntervalSeconds int64
	MaxBatchSize        int
	LokiEndpoint        string
	ServiceName         string
}

type lokiStream struct {
	Stream map[string]string `json:"stream"`
	Values [][]string        `json:"values"`
}

type lokiLogEvent struct {
	Streams []lokiStream `json:"streams"`
}

type LokiClient struct {
	config *LokiConfig
	logs   [][]string
	done   chan bool
}

func (l *LokiClient) bgRun() {
	for {
		l.sendLogsToLoki()

		select {
		case <-l.done:
			return
		default:
			time.Sleep(time.Second * time.Duration(l.config.PushIntervalSeconds))
		}
	}
}

func (l *LokiClient) sendLogsToLoki() {
	if len(l.logs) == 0 {
		return
	}

	var logsToSend [][]string
	if len(l.logs) > l.config.MaxBatchSize {
		logsToSend = l.logs[:l.config.MaxBatchSize]
		l.logs = l.logs[l.config.MaxBatchSize:]
	} else {
		logsToSend = l.logs
		l.logs = [][]string{}
	}

	data, err := json.Marshal(lokiLogEvent{
		Streams: []lokiStream{
			{
				Stream: map[string]string{
					"service": l.config.ServiceName,
				},
				Values: logsToSend,
			},
		},
	})
	if err != nil {
		fmt.Printf("Error marshalling logs: %v\n", err)
		return
	}

	req, err := http.NewRequest(http.MethodPost, fmt.Sprintf("%s/loki/api/v1/push", l.config.LokiEndpoint), bytes.NewBuffer(data))
	if err != nil {
		fmt.Printf("Error creating request: %v\n", err)
		return
	}

	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		fmt.Printf("Error sending logs: %v\n", err)
		return
	}
	defer resp.Body.Close()
}

func (l *LokiClient) Write(p []byte) (n int, err error) {
	l.logs = append(l.logs, []string{
		fmt.Sprintf("%d", time.Now().UnixNano()),
		string(p),
	})

	return len(p), nil
}

func NewLokiClient(config *LokiConfig) *LokiClient {
	client := &LokiClient{
		config: config,
		logs:   [][]string{},
		done:   make(chan bool),
	}
	go client.bgRun()
	return client
}
