#!/bin/bash
# Centralized Log Aggregation Script
# Collects logs from Mac Mini, Mac Pro, and Dell

LOG_DIR="$HOME/clawd/logs"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)

# Create dated subdirectories
mkdir -p "$LOG_DIR/mac-mini/$DATE"
mkdir -p "$LOG_DIR/mac-pro/$DATE"
mkdir -p "$LOG_DIR/dell/$DATE"

echo "[$TIMESTAMP] Starting log aggregation..."

# --- Mac Mini (local) ---
echo "  Collecting Mac Mini logs..."
cp /var/log/system.log "$LOG_DIR/mac-mini/$DATE/system.log" 2>/dev/null || true
cp /var/log/install.log "$LOG_DIR/mac-mini/$DATE/install.log" 2>/dev/null || true

# Clawd/app logs
shopt -s nullglob
for f in "$HOME/clawd/logs"/*.log; do
    [ -f "$f" ] && cp "$f" "$LOG_DIR/mac-mini/$DATE/"
done
shopt -u nullglob

# Ollama logs
cp /tmp/ollama.out "$LOG_DIR/mac-mini/$DATE/ollama.out" 2>/dev/null || true
cp /tmp/ollama.err "$LOG_DIR/mac-mini/$DATE/ollama.err" 2>/dev/null || true

# --- Mac Pro (via SSH) ---
echo "  Collecting Mac Pro logs..."
ssh -o ConnectTimeout=10 -o BatchMode=yes 100.67.192.21 "cat /var/log/system.log 2>/dev/null" > "$LOG_DIR/mac-pro/$DATE/system.log" 2>/dev/null || echo "    Mac Pro: Could not fetch system.log"
ssh -o ConnectTimeout=10 -o BatchMode=yes 100.67.192.21 "cat /tmp/ollama.out 2>/dev/null" > "$LOG_DIR/mac-pro/$DATE/ollama.out" 2>/dev/null || true
ssh -o ConnectTimeout=10 -o BatchMode=yes 100.67.192.21 "cat /tmp/ollama.err 2>/dev/null" > "$LOG_DIR/mac-pro/$DATE/ollama.err" 2>/dev/null || true

# --- Dell (via SSH, Windows) ---
echo "  Collecting Dell logs..."
ssh -o ConnectTimeout=10 -o BatchMode=yes tommi@100.119.87.108 "type C:\\Users\\tommi\\clawd\\logs\\*.log 2>nul" > "$LOG_DIR/dell/$DATE/clawd.log" 2>/dev/null || echo "    Dell: Could not fetch logs"

# Remove empty files
find "$LOG_DIR" -type f -empty -delete 2>/dev/null

echo "[$TIMESTAMP] Log aggregation complete."
echo "  Logs stored in: $LOG_DIR"
