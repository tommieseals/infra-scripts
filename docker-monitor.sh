#!/bin/bash
# Docker Health Monitor
# Checks all containers, reports issues, auto-restarts unhealthy ones

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
REPORT_FILE="/Users/tommie/shared-memory/docker-status.json"

echo "🐳 Docker Health Check - $TIMESTAMP"

# Get all containers
CONTAINERS=$(docker ps -a --format "{{.Names}}")

HEALTHY=0
UNHEALTHY=0
STOPPED=0
ISSUES=()

for CONTAINER in $CONTAINERS; do
    STATUS=$(docker inspect --format='{{.State.Status}}' "$CONTAINER")
    HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null || echo "none")
    
    echo "  $CONTAINER: $STATUS (health: $HEALTH)"
    
    if [ "$STATUS" = "running" ]; then
        if [ "$HEALTH" = "unhealthy" ]; then
            echo "    ⚠️  Container unhealthy - restarting..."
            docker restart "$CONTAINER"
            ISSUES+=("$CONTAINER was unhealthy, auto-restarted")
            UNHEALTHY=$((UNHEALTHY + 1))
        else
            HEALTHY=$((HEALTHY + 1))
        fi
    else
        STOPPED=$((STOPPED + 1))
        
        # Auto-restart critical containers
        if [[ "$CONTAINER" == "n8n-legion" ]]; then
            echo "    🔄 Critical container stopped - restarting..."
            docker start "$CONTAINER"
            ISSUES+=("$CONTAINER was stopped, auto-restarted")
        fi
    fi
done

# Write status to shared memory
# Handle empty issues array properly
if [ ${#ISSUES[@]} -eq 0 ]; then
    ISSUES_JSON="[]"
else
    ISSUES_JSON=$(printf '%s\n' "${ISSUES[@]}" | jq -R . | jq -s .)
fi

cat > "$REPORT_FILE" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "healthy": $HEALTHY,
  "unhealthy": $UNHEALTHY,
  "stopped": $STOPPED,
  "total": $((HEALTHY + UNHEALTHY + STOPPED)),
  "issues": $ISSUES_JSON,
  "analysis": "Docker health: $HEALTHY running, $UNHEALTHY unhealthy, $STOPPED stopped. Auto-healed: ${#ISSUES[@]}"
}
EOF

echo ""
echo "Status: $HEALTHY healthy, $UNHEALTHY unhealthy, $STOPPED stopped"
echo "Auto-healed: ${#ISSUES[@]} issues"
echo "Report: $REPORT_FILE"
