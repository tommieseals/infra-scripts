#!/bin/bash
# Performance Baseline Tracking Script
# Records response times for key services and stores in JSON

set -e

LOG_DIR="$HOME/clawd/logs"
PERF_FILE="$LOG_DIR/performance.json"
BASELINE_FILE="$LOG_DIR/baseline.json"
ALERT_FILE="$LOG_DIR/perf-alerts.log"

mkdir -p "$LOG_DIR"

# Initialize JSON if it doesnt exist
if [ ! -f "$PERF_FILE" ]; then
    echo "[]" > "$PERF_FILE"
fi

# Timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOCAL_TIME=$(date +"%Y-%m-%d %H:%M:%S")

echo "[$LOCAL_TIME] Starting performance baseline check..."

# Function to measure command execution time (returns milliseconds)
measure_time() {
    local start end elapsed
    start=$(python3 -c "import time; print(int(time.time() * 1000))")
    eval "$1" > /dev/null 2>&1
    local exit_code=$?
    end=$(python3 -c "import time; print(int(time.time() * 1000))")
    elapsed=$((end - start))
    if [ $exit_code -ne 0 ]; then
        echo "-1"
    else
        echo "$elapsed"
    fi
}

# 1. Ollama response time (quick query)
echo "  Testing Ollama..."
OLLAMA_TIME=$(measure_time 'curl -s -X POST http://localhost:11434/api/generate -d "{\"model\":\"qwen2.5:3b\",\"prompt\":\"hi\",\"stream\":false}" -H "Content-Type: application/json"')

# 2. SSH latency to Mac Pro
echo "  Testing SSH to Mac Pro..."
SSH_MACPRO=$(measure_time "ssh -o ConnectTimeout=5 -o BatchMode=yes 100.67.192.21 echo ok")

# 3. SSH latency to Dell
echo "  Testing SSH to Dell..."
SSH_DELL=$(measure_time "ssh -o ConnectTimeout=5 -o BatchMode=yes tommi@100.119.87.108 echo ok")

# 4. Dashboard load time (if running locally)
echo "  Testing Dashboard..."
DASHBOARD_TIME=$(measure_time "curl -s -o /dev/null -w '' http://localhost:3000")

# 5. NVIDIA API (if configured)
echo "  Testing NVIDIA API..."
if [ -n "$NVIDIA_API_KEY" ]; then
    NVIDIA_TIME=$(measure_time 'curl -s -X POST https://integrate.api.nvidia.com/v1/chat/completions -H "Authorization: Bearer $NVIDIA_API_KEY" -H "Content-Type: application/json" -d "{\"model\":\"meta/llama-3.1-8b-instruct\",\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}],\"max_tokens\":5}"')
else
    NVIDIA_TIME=-1
fi

# 6. Hunter.io API (if configured)
echo "  Testing Hunter.io..."
if [ -n "$HUNTER_API_KEY" ]; then
    HUNTER_TIME=$(measure_time "curl -s \"https://api.hunter.io/v2/account?api_key=\$HUNTER_API_KEY\"")
else
    HUNTER_TIME=-1
fi

# 7. OpenWeatherMap API (if configured)
echo "  Testing OpenWeatherMap..."
if [ -n "$OPENWEATHER_API_KEY" ]; then
    WEATHER_TIME=$(measure_time "curl -s \"https://api.openweathermap.org/data/2.5/weather?q=Chicago\&appid=\$OPENWEATHER_API_KEY\"")
else
    WEATHER_TIME=-1
fi

# 8. Google Cloud VM ping
echo "  Testing Google Cloud..."
GCP_PING=$(measure_time "ssh -o ConnectTimeout=5 -o BatchMode=yes 100.107.231.87 echo ok")

# Build JSON entry
JSON_ENTRY=$(cat << JSONEOF
{
  "timestamp": "$TIMESTAMP",
  "metrics": {
    "ollama_ms": $OLLAMA_TIME,
    "ssh_macpro_ms": $SSH_MACPRO,
    "ssh_dell_ms": $SSH_DELL,
    "dashboard_ms": $DASHBOARD_TIME,
    "nvidia_api_ms": $NVIDIA_TIME,
    "hunter_api_ms": $HUNTER_TIME,
    "weather_api_ms": $WEATHER_TIME,
    "gcp_ssh_ms": $GCP_PING
  }
}
JSONEOF
)

# Append to performance log (keep last 1000 entries)
python3 << PYEOF
import json
import os

perf_file = "$PERF_FILE"
baseline_file = "$BASELINE_FILE"
alert_file = "$ALERT_FILE"
timestamp = "$TIMESTAMP"

with open(perf_file, "r") as f:
    data = json.load(f)

entry = $JSON_ENTRY
data.append(entry)

# Keep last 1000 entries
data = data[-1000:]

with open(perf_file, "w") as f:
    json.dump(data, f, indent=2)

print("Recorded performance data:")
print(json.dumps(entry, indent=2))

# Check for alerts (2x baseline)
if len(data) >= 10:
    # Calculate baseline from first 10 entries
    baseline = {}
    for metric in entry["metrics"]:
        values = [d["metrics"].get(metric, -1) for d in data[:10] if d["metrics"].get(metric, -1) > 0]
        if values:
            baseline[metric] = sum(values) / len(values)
    
    # Save baseline
    with open(baseline_file, "w") as f:
        json.dump(baseline, f, indent=2)
    
    # Check for 2x threshold violations
    alerts = []
    for metric, value in entry["metrics"].items():
        if value > 0 and metric in baseline and baseline[metric] > 0:
            ratio = value / baseline[metric]
            if ratio > 2.0:
                alerts.append(f"ALERT: {metric} is {ratio:.1f}x baseline ({value}ms vs {baseline[metric]:.0f}ms)")
    
    if alerts:
        with open(alert_file, "a") as f:
            for alert in alerts:
                f.write(f"[{timestamp}] {alert}\n")
                print(alert)
PYEOF

echo "[$LOCAL_TIME] Performance check complete"
