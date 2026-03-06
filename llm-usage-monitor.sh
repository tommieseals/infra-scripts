#!/bin/bash
# LLM Usage Monitoring with Alerts
# Warns when approaching daily limits

set -e

USAGE_FILE="$HOME/dta/metrics/daily-usage.json"
NVIDIA_DAILY_LIMIT=50
WARNING_THRESHOLD=40
CRITICAL_THRESHOLD=45

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "📊 LLM Usage Monitor"
echo "===================="
echo ""

if [ ! -f "$USAGE_FILE" ]; then
    echo -e "${GREEN}✅ No usage yet today${NC}"
    exit 0
fi

# Load usage
USAGE=$(cat "$USAGE_FILE")
DATE=$(echo "$USAGE" | jq -r '.date')

# Calculate total NVIDIA calls (shared 50/day limit)
KIMI_CALLS=$(echo "$USAGE" | jq -r '.kimi_calls')
LLAMA_90B_CALLS=$(echo "$USAGE" | jq -r '.llama_90b_calls')
LLAMA_11B_CALLS=$(echo "$USAGE" | jq -r '.llama_11b_calls')
QWEN_CODER_CALLS=$(echo "$USAGE" | jq -r '.qwen_coder_calls')
TOTAL_NVIDIA=$((KIMI_CALLS + LLAMA_90B_CALLS + LLAMA_11B_CALLS + QWEN_CODER_CALLS))

# Local usage
OLLAMA_CALLS=$(echo "$USAGE" | jq -r '.ollama_calls')
OPENROUTER_CALLS=$(echo "$USAGE" | jq -r '.openrouter_calls')
OPENROUTER_COST=$(echo "$USAGE" | jq -r '.openrouter_cost')

# Display summary
echo -e "${CYAN}Date:${NC} $DATE"
echo ""
echo "📈 NVIDIA API Usage (50/day shared limit):"
echo "  • Kimi K2.5:      $KIMI_CALLS calls"
echo "  • Llama 90B:      $LLAMA_90B_CALLS calls"
echo "  • Llama 11B:      $LLAMA_11B_CALLS calls"
echo "  • Qwen Coder:     $QWEN_CODER_CALLS calls"
echo "  ────────────────────────────"
echo "  • TOTAL:          $TOTAL_NVIDIA / $NVIDIA_DAILY_LIMIT"
echo ""
echo "🆓 Free Usage:"
echo "  • Ollama local:   $OLLAMA_CALLS calls (FREE)"
echo ""
echo "💰 Fallback:"
echo "  • OpenRouter:     $OPENROUTER_CALLS calls (\$$OPENROUTER_COST)"
echo ""

# Calculate percentage
PERCENTAGE=$((TOTAL_NVIDIA * 100 / NVIDIA_DAILY_LIMIT))

# Status indicator
if [ $TOTAL_NVIDIA -ge $CRITICAL_THRESHOLD ]; then
    echo -e "${RED}🚨 CRITICAL: ${TOTAL_NVIDIA}/${NVIDIA_DAILY_LIMIT} used (${PERCENTAGE}%)${NC}"
    echo -e "${RED}   Only $((NVIDIA_DAILY_LIMIT - TOTAL_NVIDIA)) calls remaining!${NC}"
    echo ""
    echo "⚠️  RECOMMENDATIONS:"
    echo "   • Use Ollama for simple queries (FREE)"
    echo "   • Defer non-urgent complex tasks"
    echo "   • Resets at midnight"
    exit 2
elif [ $TOTAL_NVIDIA -ge $WARNING_THRESHOLD ]; then
    echo -e "${YELLOW}⚠️  WARNING: ${TOTAL_NVIDIA}/${NVIDIA_DAILY_LIMIT} used (${PERCENTAGE}%)${NC}"
    echo -e "${YELLOW}   $((NVIDIA_DAILY_LIMIT - TOTAL_NVIDIA)) calls remaining${NC}"
    echo ""
    echo "💡 TIP: Use Ollama for simple queries (FREE)"
    exit 1
else
    echo -e "${GREEN}✅ Usage healthy: ${TOTAL_NVIDIA}/${NVIDIA_DAILY_LIMIT} (${PERCENTAGE}%)${NC}"
    echo "   $((NVIDIA_DAILY_LIMIT - TOTAL_NVIDIA)) calls remaining"
fi

echo ""
echo "📋 Quick Commands:"
echo "  • Check usage:  ~/dta/gateway/llm-usage"
echo "  • Use Ollama:   ~/dta/gateway/ask \"your question\""
echo "  • Force model:  python3 ~/dta/gateway/llm-gateway.py --force ollama \"query\""
