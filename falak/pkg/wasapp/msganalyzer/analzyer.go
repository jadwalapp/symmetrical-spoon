package wasappmsganalyzer

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"github.com/openai/openai-go"
	"github.com/rs/zerolog/log"
)

type analyzer struct {
	llmCli    *openai.Client
	modelName string
}

func (a *analyzer) AnalyzeMessages(ctx context.Context, r *AnalyzeMessagesRequest) (*AnalyzeMessagesResponse, error) {
	logger := log.Ctx(ctx)
	now := time.Now()

	msgs := []openai.ChatCompletionMessageParamUnion{
		openai.SystemMessage(analyzeMessagePrompt),
		openai.UserMessage(CreateDateTag(now.Format("2006-01-02")) + "\n" + CreateTimeTag(now.Format("15:04")) + "\n" + CreateMessagesTag(r.Messages)),
	}

	logger.Debug().
		Interface("messages", msgs).
		Str("model", a.modelName).
		Msg("analyzing messages with LLM")

	chatResp, err := a.llmCli.Chat.Completions.New(ctx, openai.ChatCompletionNewParams{
		Messages: openai.F(msgs),
		Model:    openai.F(a.modelName),
	})
	if err != nil {
		logger.Error().Err(err).Msg("failed to analyze messages with LLM")
		return nil, errors.New("failed to analyze messages")
	}

	body := chatResp.Choices[0].Message.Content
	body = strings.TrimPrefix(body, "```")
	body = strings.TrimPrefix(body, "json")
	body = strings.TrimSuffix(body, "```")

	logger.Debug().
		Str("raw_response", body).
		Msg("received response from LLM")

	var resp AnalyzeMessagesResponse
	if err := json.Unmarshal([]byte(body), &resp); err != nil {
		logger.Error().
			Err(err).
			Str("body", body).
			Msg("failed to parse LLM response as JSON")
		return nil, errors.New("failed to parse the response of messages analysis")
	}

	logger.Info().
		Str("status", string(resp.Status)).
		Interface("event", resp.Event).
		Msg("successfully analyzed messages")

	return &resp, nil
}

func NewAnalyzer(llmCli *openai.Client, modelName string) Analyzer {
	return &analyzer{
		llmCli:    llmCli,
		modelName: modelName,
	}
}
