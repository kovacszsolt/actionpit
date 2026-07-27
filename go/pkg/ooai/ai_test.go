package ooai_test

import (
	"testing"

	"github.com/kovacszsolt/actionpit/go/pkg/ooai"
)

func TestCalculateCost(t *testing.T) {
	in := 1.0
	out := 2.0
	cachedIn := 0.5
	got := ooai.CalculateCost(ooai.AICallFields{
		InputTokens:         1000,
		OutputTokens:        2000,
		CachedTokens:        100,
		InputUSDPer1M:       &in,
		OutputUSDPer1M:      &out,
		CachedInputUSDPer1M: &cachedIn,
		PricingFound:        true,
	})
	if diff := got.InputUSD - 0.0009; diff > 1e-12 || diff < -1e-12 {
		t.Fatalf("input = %v", got.InputUSD)
	}
	if diff := got.CachedInputUSD - 0.00005; diff > 1e-12 || diff < -1e-12 {
		t.Fatalf("cached input = %v", got.CachedInputUSD)
	}
	if diff := got.OutputUSD - 0.004; diff > 1e-12 || diff < -1e-12 {
		t.Fatalf("output = %v", got.OutputUSD)
	}
	if diff := got.TotalUSD - 0.00495; diff > 1e-12 || diff < -1e-12 {
		t.Fatalf("total = %v", got.TotalUSD)
	}
	if got.CostType != "paid" {
		t.Fatalf("cost type = %q", got.CostType)
	}
}

func TestAICallMessage(t *testing.T) {
	in := 0.15
	out := 0.6
	cachedIn := 0.075
	msg := ooai.AICallMessage("humorhello-cron.ai.call", "humor_generate", ooai.AICallFields{
		Provider:            "openai",
		Model:               "gpt-4o-mini",
		Prompt:              "Tell a short joke",
		Response:            `{"title":"T","content":"C"}`,
		InputTokens:         42,
		OutputTokens:        17,
		DurationMS:          321,
		Temperature:         0.7,
		MaxTokens:           256,
		FinishReason:        "stop",
		CachedTokens:        3,
		ReasoningTokens:     1,
		RequestID:           "req_abc",
		RetryCount:          0,
		StatusCode:          200,
		InputUSDPer1M:       &in,
		OutputUSDPer1M:      &out,
		CachedInputUSDPer1M: &cachedIn,
		PricingFound:        true,
	}, nil)
	if msg["ai_provider"] != "openai" {
		t.Fatalf("ai_provider = %v", msg["ai_provider"])
	}
	if msg["ai_pricing_found"] != true {
		t.Fatalf("ai_pricing_found = %v", msg["ai_pricing_found"])
	}
	if msg["ai_cost_type"] != "paid" {
		t.Fatalf("ai_cost_type = %v", msg["ai_cost_type"])
	}
	if _, ok := msg["ai_input_cost_usd"]; !ok {
		t.Fatal("missing ai_input_cost_usd")
	}
	if _, ok := msg["ai_output_cost_usd"]; !ok {
		t.Fatal("missing ai_output_cost_usd")
	}
}
