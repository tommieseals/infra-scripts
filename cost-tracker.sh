#!/bin/bash
# Cost and Token Tracker for Clawdbot Infrastructure
set -e
LOGS_DIR="$HOME/clawd/logs"
COSTS_FILE="$LOGS_DIR/costs.json"
TOKEN_LOG="$LOGS_DIR/token-usage.log"
DTA_METRICS="$HOME/dta/metrics/daily-usage.json"
ALERT_THRESHOLD_DAILY=5.00
ALERT_THRESHOLD_WEEKLY=25.00
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'
TODAY=$(date +%Y-%m-%d)
TIMESTAMP=$(date -Iseconds)

init_costs_file() {
    [ ! -f "$COSTS_FILE" ] && echo "[]" > "$COSTS_FILE"
}

get_ollama_usage() {
    local it=0 ot=0 c=0
    if [ -f "$TOKEN_LOG" ]; then
        while IFS='|' read -r ts ag mo ip op tot co; do
            ld=$(echo "$ts" | cut -dT -f1)
            [ "$ld" = "$TODAY" ] && [ "$mo" = "local" ] && { it=$((it+ip)); ot=$((ot+op)); c=$((c+1)); }
        done < "$TOKEN_LOG"
    fi
    echo "${c}|${it}|${ot}"
}

get_nvidia_usage() {
    local c=0
    if [ -f "$DTA_METRICS" ]; then
        local d=$(jq -r '.date // empty' "$DTA_METRICS" 2>/dev/null)
        if [ "$d" = "$TODAY" ]; then
            local k=$(jq -r '.kimi_calls // 0' "$DTA_METRICS")
            local l9=$(jq -r '.llama_90b_calls // .mac_pro_calls // 0' "$DTA_METRICS")
            local l1=$(jq -r '.llama_11b_calls // .mac_mini_calls // 0' "$DTA_METRICS")
            local q=$(jq -r '.qwen_coder_calls // .dell_calls // 0' "$DTA_METRICS")
            c=$((k+l9+l1+q))
        fi
    fi
    echo "$c"
}

get_openrouter_usage() {
    local c=0 co=0
    if [ -f "$DTA_METRICS" ]; then
        local d=$(jq -r '.date // empty' "$DTA_METRICS" 2>/dev/null)
        if [ "$d" = "$TODAY" ]; then
            c=$(jq -r '.openrouter_calls // 0' "$DTA_METRICS")
            co=$(jq -r '.openrouter_cost // 0' "$DTA_METRICS")
        fi
    fi
    echo "${c}|${co}"
}

estimate_claude_usage() {
    local s=0 t=0
    if [ -f "$HOME/clawd/memory/$TODAY.md" ]; then
        s=$(grep -c "^##" "$HOME/clawd/memory/$TODAY.md" 2>/dev/null || echo 0)
        t=$((s * 2000))
    fi
    echo "${s}|${t}"
}

track_costs() {
    init_costs_file
    IFS='|' read -r oc oi oo <<< "$(get_ollama_usage)"
    nc=$(get_nvidia_usage)
    IFS='|' read -r orc orco <<< "$(get_openrouter_usage)"
    IFS='|' read -r cs ct <<< "$(estimate_claude_usage)"
    cc=$(echo "${ct:-0} * 0.0000105" | bc -l 2>/dev/null || echo 0)
    tc=$(echo "${orco:-0} + ${cc:-0}" | bc -l 2>/dev/null || echo "${orco:-0}")
    
    entry="{\"date\":\"$TODAY\",\"timestamp\":\"$TIMESTAMP\",\"ollama\":{\"calls\":${oc:-0},\"input_tokens\":${oi:-0},\"output_tokens\":${oo:-0},\"cost\":0},\"nvidia\":{\"calls\":${nc:-0},\"limit\":50,\"cost\":0},\"openrouter\":{\"calls\":${orc:-0},\"cost\":${orco:-0}},\"claude_estimate\":{\"sessions\":${cs:-0},\"tokens_approx\":${ct:-0},\"cost_approx\":${cc:-0}},\"daily_total\":${tc:-0}}"
    
    ex=$(jq "map(select(.date == \"$TODAY\"))" "$COSTS_FILE")
    if [ "$ex" != "[]" ]; then
        jq "map(if .date == \"$TODAY\" then $entry else . end)" "$COSTS_FILE" > "${COSTS_FILE}.tmp"
    else
        jq ". + [$entry]" "$COSTS_FILE" > "${COSTS_FILE}.tmp"
    fi
    mv "${COSTS_FILE}.tmp" "$COSTS_FILE"
    jq '. | sort_by(.date) | .[-90:]' "$COSTS_FILE" > "${COSTS_FILE}.tmp"
    mv "${COSTS_FILE}.tmp" "$COSTS_FILE"
    echo "$entry"
}

check_alerts() {
    tc=$(jq -r "map(select(.date == \"$TODAY\")) | .[0].daily_total // 0" "$COSTS_FILE")
    wa=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d "7 days ago" +%Y-%m-%d)
    wc=$(jq -r "[.[] | select(.date >= \"$wa\") | .daily_total] | add // 0" "$COSTS_FILE")
    [ $(echo "$tc > $ALERT_THRESHOLD_DAILY" | bc -l 2>/dev/null || echo 0) -eq 1 ] && echo -e "${RED}ALERT: Daily >\$$ALERT_THRESHOLD_DAILY${NC}"
    [ $(echo "$wc > $ALERT_THRESHOLD_WEEKLY" | bc -l 2>/dev/null || echo 0) -eq 1 ] && echo -e "${RED}ALERT: Weekly >\$$ALERT_THRESHOLD_WEEKLY${NC}"
}

show_summary() {
    echo ""
    echo -e "${CYAN}Cost and Token Tracker${NC}"
    echo "========================"
    data=$(jq -r "map(select(.date == \"$TODAY\")) | .[0]" "$COSTS_FILE")
    [ "$data" = "null" ] && { echo "No data. Run --track first."; return; }
    echo -e "${GREEN}Date: $TODAY${NC}"
    echo "FREE: Ollama=$(echo "$data"|jq -r '.ollama.calls') NVIDIA=$(echo "$data"|jq -r '.nvidia.calls')/50"
    echo "PAID: OR=$(echo "$data"|jq -r '.openrouter.calls')(\$$(echo "$data"|jq -r '.openrouter.cost')) Claude=$(echo "$data"|jq -r '.claude_estimate.sessions')sess"
    echo "TOTAL: \$$(echo "$data"|jq -r '.daily_total')"
    check_alerts || true
}

case "${1:-}" in
    --track|-t) track_costs > /dev/null; echo -e "${GREEN}Tracked for $TODAY${NC}" ;;
    --summary|-s) show_summary ;;
    --alerts|-a) check_alerts ;;
    --json|-j) cat "$COSTS_FILE" ;;
    *) track_costs > /dev/null; show_summary ;;
esac
