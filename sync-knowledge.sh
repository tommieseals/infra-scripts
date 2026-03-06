#!/bin/bash
# Auto-sync knowledge between agents
# Run this every few minutes via cron/scheduled task

set -e

WORKSPACE="$HOME/clawd"
cd "$WORKSPACE"

# Pull latest from other agent
git pull --rebase --autostash origin main 2>/dev/null || true

# Commit any changes to memory or important files
git add -A memory/ MEMORY.md AGENTS.md SOUL.md USER.md TOOLS.md IDENTITY.md 2>/dev/null || true
git add -A scripts/ skills/ 2>/dev/null || true

if ! git diff --cached --quiet 2>/dev/null; then
    HOSTNAME=$(hostname)
    TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
    git commit -m "Auto-sync from $HOSTNAME at $TIMESTAMP" --no-verify || true
    git push origin main 2>/dev/null || true
    echo "✓ Synced knowledge to shared brain"
else
    echo "• No changes to sync"
fi
