#!/bin/bash
# Weekly Cost Report
set -e
LOGS_DIR="$HOME/clawd/logs"
COSTS_FILE="$LOGS_DIR/costs.json"
CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m'

END=$(date +%Y-%m-%d)
START=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d "7 days ago" +%Y-%m-%d)

echo ""
echo -e "${CYAN}=== WEEKLY COST REPORT ===${NC}"
echo -e "${CYAN}$START to $END${NC}"
echo ""

[ ! -f "$COSTS_FILE" ] && { echo "No data. Run cost-tracker.sh first."; exit 1; }

W=$(jq "[.[] | select(.date >= \"$START\" and .date <= \"$END\")]" "$COSTS_FILE")

OC=$(echo "$W" | jq '[.[].ollama.calls] | add // 0')
OI=$(echo "$W" | jq '[.[].ollama.input_tokens] | add // 0')
OO=$(echo "$W" | jq '[.[].ollama.output_tokens] | add // 0')
NC=$(echo "$W" | jq '[.[].nvidia.calls] | add // 0')
ORC=$(echo "$W" | jq '[.[].openrouter.calls] | add // 0')
ORCO=$(echo "$W" | jq '[.[].openrouter.cost] | add // 0')
CS=$(echo "$W" | jq '[.[].claude_estimate.sessions] | add // 0')
CT=$(echo "$W" | jq '[.[].claude_estimate.tokens_approx] | add // 0')
CC=$(echo "$W" | jq '[.[].claude_estimate.cost_approx] | add // 0')
TC=$(echo "$W" | jq '[.[].daily_total] | add // 0')

echo -e "${GREEN}FREE TIER:${NC}"
printf "  Ollama: %d calls, %d tokens (FREE)\n" "$OC" "$((OI+OO))"
printf "  NVIDIA: %d calls (FREE tier)\n" "$NC"
echo ""
echo "PAID:"
printf "  OpenRouter: %d calls (\$%.4f)\n" "$ORC" "$ORCO"
printf "  Claude est: %d sess (~\$%.4f)\n" "$CS" "$CC"
echo ""
echo -e "${CYAN}WEEKLY TOTAL: \$$(printf '%.4f' $TC)${NC}"
echo ""
echo "Daily breakdown:"
echo "$W" | jq -r '.[] | "  \(.date): Ollama=\(.ollama.calls) NVIDIA=\(.nvidia.calls) Total=$\(.daily_total)"'
