#!/bin/bash
# SWARM DEPLOYMENT HEARTBEAT MONITOR
# Runs every 10 minutes until deployment complete

DEPLOYMENT_FILE="$HOME/clawd/memory/2026-03-03-swarm-deployment.md"
STATUS_FILE="$HOME/clawd/memory/.swarm-deployment-status"

# Check if deployment is still active
if [[ ! -f "$STATUS_FILE" ]]; then
    echo "ACTIVE" > "$STATUS_FILE"
fi

DEPLOYMENT_STATUS=$(cat "$STATUS_FILE")

if [[ "$DEPLOYMENT_STATUS" == "COMPLETE" ]]; then
    echo "Deployment complete. Removing cron job."
    # Remove this cron job
    crontab -l | grep -v "swarm-deployment-heartbeat.sh" | crontab -
    exit 0
fi

# Log heartbeat
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
echo "" >> "$DEPLOYMENT_FILE"
echo "### Heartbeat: $TIMESTAMP" >> "$DEPLOYMENT_FILE"

# Check sub-agent status (this will be run by main agent via heartbeat)
# The main agent will use sessions_list to check progress

# Send heartbeat message to Rusty
# This gets picked up by the heartbeat mechanism in HEARTBEAT.md
echo "SWARM_DEPLOYMENT_HEARTBEAT_CHECK_NEEDED" > /tmp/swarm-heartbeat-trigger
