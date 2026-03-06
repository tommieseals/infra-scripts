#!/bin/bash
# Update swarm monitor with live data from Clawdbot sessions API
# Run via cron every minute

DASHBOARD_DIR="/Users/tommie/clawd/dashboard"
DATA_FILE="$DASHBOARD_DIR/data/swarm-status.json"

# Get active sessions (last 24 hours)
SESSIONS=$(clawdbot sessions list --json --active-minutes=1440 2>/dev/null)

if [ -z "$SESSIONS" ] || [ "$SESSIONS" = "null" ]; then
    # Fallback to empty state
    cat > "$DATA_FILE" << 'EOF'
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "source": "Mac Mini Clawdbot",
    "collector": "update-swarm-data.sh v3.1",
    "stats": {"total": 0, "working": 0, "idle": 0, "complete": 0, "error": 0},
    "agents": [],
    "modelDistribution": {},
    "totalTokensUsed": 0,
    "lastRefresh": $(date +%s)000
}
EOF
    echo "[$(date)] No sessions data available"
    exit 0
fi

# Filter for sub-agents only (contains "subagent" in key)
SUBAGENTS=$(echo "$SESSIONS" | jq '[.sessions[] | select(.key | contains("subagent"))]')

# Count total
TOTAL=$(echo "$SUBAGENTS" | jq 'length')

# Categorize by recent activity
NOW=$(date +%s)
HOUR_AGO=$((NOW - 3600))

WORKING=$(echo "$SUBAGENTS" | jq --arg hour "$HOUR_AGO" '[.[] | select((.updatedAt / 1000) > ($hour | tonumber))] | length')
COMPLETE=$(echo "$SUBAGENTS" | jq --arg hour "$HOUR_AGO" '[.[] | select((.updatedAt / 1000) <= ($hour | tonumber) and (.abortedLastRun == false))] | length')
ERROR=$(echo "$SUBAGENTS" | jq '[.[] | select(.abortedLastRun == true)] | length')

# Calculate total tokens
TOTAL_TOKENS=$(echo "$SUBAGENTS" | jq '[.[].totalTokens // 0] | add // 0')

# Build agent list
AGENTS=$(echo "$SUBAGENTS" | jq --arg now "$NOW" '[.[] | 
{
    key: .key,
    label: (.label // (.key | split(":") | .[3] | split("-") | .[0])),
    name: (.label // (.key | split(":") | .[3] | split("-") | .[0])),
    task: "Sub-agent task",
    model: .model,
    status: (if .abortedLastRun then "error" elif ((.updatedAt / 1000) > (($now | tonumber) - 3600)) then "working" else "complete" end),
    statusEmoji: (if .abortedLastRun then "❌" elif ((.updatedAt / 1000) > (($now | tonumber) - 3600)) then "⚙" else "✅" end),
    tokens: .totalTokens,
    runtime: ((($now | tonumber) - (.updatedAt / 1000)) / 60 | floor | tostring + "m ago"),
    lastUpdate: .updatedAt
}] | sort_by(.lastUpdate) | reverse')

# Count models
MODEL_DIST=$(echo "$SUBAGENTS" | jq '[.[] | select(.model != null)] | group_by(.model) | map({key: .[0].model, value: length}) | from_entries')

# Write JSON
cat > "$DATA_FILE" << EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "source": "Mac Mini Clawdbot",
    "collector": "update-swarm-data.sh v3.1",
    "stats": {
        "total": $TOTAL,
        "working": $WORKING,
        "idle": 0,
        "complete": $COMPLETE,
        "error": $ERROR
    },
    "agents": $AGENTS,
    "modelDistribution": $MODEL_DIST,
    "totalTokensUsed": $TOTAL_TOKENS,
    "lastRefresh": $(date +%s)000
}
EOF

echo "[$(date)] Swarm updated: $TOTAL agents ($WORKING working, $COMPLETE complete, $ERROR errors)"
