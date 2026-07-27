package ooai

import (
	"context"
	"fmt"

	"github.com/kovacszsolt/actionpit/go/pkg/openobserve"
	"github.com/shopspring/decimal"
)

// AICallFields are observability fields for one AI provider request.
type AICallFields struct {
	Provider             string
	Model                string
	Prompt               string
	Response             string
	InputTokens          int
	OutputTokens         int
	DurationMS           int64
	Temperature          float64
	MaxTokens            int
	FinishReason         string
	CachedTokens         int
	ReasoningTokens      int
	RequestID            string
	CostUSD              float64
	InputCostUSD         float64
	CachedInputCostUSD   float64
	OutputCostUSD        float64
	CachedOutputCostUSD  float64
	RetryCount           int
	StatusCode           int
	InputUSDPer1M        *float64
	OutputUSDPer1M       *float64
	CachedInputUSDPer1M  *float64
	CachedOutputUSDPer1M *float64
	PricingFound         bool
	CostType             string
}

// CostBreakdown is the USD cost split for one AI call.
type CostBreakdown struct {
	InputUSD        float64
	CachedInputUSD  float64
	OutputUSD       float64
	CachedOutputUSD float64
	TotalUSD        float64
	CostType        string
}

// CalculateCost calculates the AI token cost breakdown from token counts and rates.
func CalculateCost(call AICallFields) CostBreakdown {
	if !call.PricingFound {
		return CostBreakdown{CostType: "free"}
	}
	million := decimal.NewFromInt(1_000_000)
	cached := call.CachedTokens
	if cached < 0 {
		cached = 0
	}
	if cached > call.InputTokens {
		cached = call.InputTokens
	}
	uncached := call.InputTokens - cached
	if uncached < 0 {
		uncached = 0
	}

	var inputCost, cachedInputCost, outputCost decimal.Decimal
	if uncached > 0 && call.InputUSDPer1M != nil {
		inputCost = perMillion(uncached, decimal.NewFromFloat(*call.InputUSDPer1M), million)
	}
	if cached > 0 {
		rate := call.InputUSDPer1M
		if call.CachedInputUSDPer1M != nil {
			rate = call.CachedInputUSDPer1M
		}
		if rate != nil {
			cachedInputCost = perMillion(cached, decimal.NewFromFloat(*rate), million)
		}
	}
	if call.OutputTokens > 0 && call.OutputUSDPer1M != nil {
		outputCost = perMillion(call.OutputTokens, decimal.NewFromFloat(*call.OutputUSDPer1M), million)
	}
	total := inputCost.Add(cachedInputCost).Add(outputCost)
	totalFloat, _ := total.Float64()
	costType := "free"
	if totalFloat > 0 {
		costType = "paid"
	}
	return CostBreakdown{
		InputUSD:       toFloat(inputCost),
		CachedInputUSD: toFloat(cachedInputCost),
		OutputUSD:      toFloat(outputCost),
		TotalUSD:       totalFloat,
		CostType:       costType,
	}
}

// AICallMessage builds the message object for {service}.ai.call.
func AICallMessage(eventName, pipeline string, call AICallFields, err error) map[string]any {
	cost := CalculateCost(call)
	msg := map[string]any{
		"event.name":                  eventName,
		"pipeline":                    pipeline,
		"ai_provider":                 call.Provider,
		"ai_model":                    call.Model,
		"ai_prompt":                   call.Prompt,
		"ai_response":                 call.Response,
		"ai_input_tokens":             call.InputTokens,
		"ai_output_tokens":            call.OutputTokens,
		"ai_duration_ms":              call.DurationMS,
		"ai_temperature":              call.Temperature,
		"ai_max_tokens":               call.MaxTokens,
		"ai_finish_reason":            call.FinishReason,
		"ai_cached_tokens":            call.CachedTokens,
		"ai_reasoning_tokens":         call.ReasoningTokens,
		"ai_request_id":               call.RequestID,
		"ai_cost_usd":                 cost.TotalUSD,
		"ai_input_cost_usd":           cost.InputUSD,
		"ai_cached_input_cost_usd":    cost.CachedInputUSD,
		"ai_output_cost_usd":          cost.OutputUSD,
		"ai_cached_output_cost_usd":   cost.CachedOutputUSD,
		"ai_retry_count":              call.RetryCount,
		"ai_status_code":              call.StatusCode,
		"ai_input_usd_per_1m":         call.InputUSDPer1M,
		"ai_output_usd_per_1m":        call.OutputUSDPer1M,
		"ai_cached_input_usd_per_1m":  call.CachedInputUSDPer1M,
		"ai_cached_output_usd_per_1m": call.CachedOutputUSDPer1M,
		"ai_pricing_found":            call.PricingFound,
		"ai_cost_type":                cost.CostType,
		"success":                     err == nil,
	}
	if err != nil {
		msg["error.message"] = err.Error()
	}
	return msg
}

// PublishAICall sends {service}.ai.call using the provided publisher.
func PublishAICall(pub *openobserve.Publisher, ctx context.Context, pipeline string, call AICallFields, err error) {
	if pub == nil {
		return
	}
	eventName := fmt.Sprintf("%s.ai.call", pub.ServiceName())
	level := "info"
	if err != nil {
		level = "error"
	}
	pub.Publish(ctx, eventName, level, AICallMessage(eventName, pipeline, call, err))
}

func perMillion(tokens int, usdPer1M, million decimal.Decimal) decimal.Decimal {
	return decimal.NewFromInt(int64(tokens)).Div(million).Mul(usdPer1M)
}

func toFloat(d decimal.Decimal) float64 {
	f, _ := d.Float64()
	return f
}
