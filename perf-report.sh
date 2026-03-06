#!/bin/bash
# Performance Report Script
# Shows trends and summary of performance data

LOG_DIR="$HOME/clawd/logs"
PERF_FILE="$LOG_DIR/performance.json"
BASELINE_FILE="$LOG_DIR/baseline.json"

if [ ! -f "$PERF_FILE" ]; then
    echo "No performance data found. Run perf-baseline.sh first."
    exit 1
fi

python3 << 'PYEOF'
import json
from datetime import datetime, timedelta

perf_file = "$HOME/clawd/logs/performance.json".replace("$HOME", __import__("os").environ["HOME"])
baseline_file = "$HOME/clawd/logs/baseline.json".replace("$HOME", __import__("os").environ["HOME"])

with open(perf_file, "r") as f:
    data = json.load(f)

if not data:
    print("No performance data available.")
    exit()

# Load baseline if exists
baseline = {}
try:
    with open(baseline_file, "r") as f:
        baseline = json.load(f)
except:
    pass

print("=" * 60)
print("PERFORMANCE REPORT")
print("=" * 60)
print(f"Data points: {len(data)}")
print(f"Time range: {data[0]['timestamp'][:19]} to {data[-1]['timestamp'][:19]}")
print()

# Get all metrics
metrics = list(data[-1]["metrics"].keys())

# Calculate stats for each metric
print("-" * 60)
print(f"{'Metric':<20} {'Current':>10} {'Avg':>10} {'Min':>10} {'Max':>10} {'Trend':>8}")
print("-" * 60)

for metric in metrics:
    values = [d["metrics"].get(metric, -1) for d in data if d["metrics"].get(metric, -1) > 0]
    if not values:
        print(f"{metric:<20} {'N/A':>10} {'N/A':>10} {'N/A':>10} {'N/A':>10} {'N/A':>8}")
        continue
    
    current = values[-1]
    avg = sum(values) / len(values)
    min_val = min(values)
    max_val = max(values)
    
    # Calculate trend (last 5 vs previous 5)
    if len(values) >= 10:
        recent = sum(values[-5:]) / 5
        older = sum(values[-10:-5]) / 5
        if older > 0:
            trend_pct = ((recent - older) / older) * 100
            if trend_pct > 10:
                trend = f"↑{trend_pct:.0f}%"
            elif trend_pct < -10:
                trend = f"↓{abs(trend_pct):.0f}%"
            else:
                trend = "→"
        else:
            trend = "→"
    else:
        trend = "N/A"
    
    # Add warning if > 2x baseline
    warning = ""
    if metric in baseline and baseline[metric] > 0:
        if current > baseline[metric] * 2:
            warning = " ⚠️"
    
    print(f"{metric:<20} {current:>9.0f} {avg:>9.0f} {min_val:>9.0f} {max_val:>9.0f} {trend:>8}{warning}")

print("-" * 60)
print()

# Show baseline comparison
if baseline:
    print("BASELINE COMPARISON:")
    print("-" * 60)
    print(f"{'Metric':<20} {'Baseline':>10} {'Current':>10} {'Ratio':>10}")
    print("-" * 60)
    
    current_metrics = data[-1]["metrics"]
    for metric, base_val in baseline.items():
        current_val = current_metrics.get(metric, -1)
        if current_val > 0 and base_val > 0:
            ratio = current_val / base_val
            status = "✓" if ratio < 2.0 else "⚠️ HIGH"
            print(f"{metric:<20} {base_val:>9.0f} {current_val:>9.0f} {ratio:>9.2f}x {status}")
    print("-" * 60)
    print()

# Show recent alerts
alert_file = "$HOME/clawd/logs/perf-alerts.log".replace("$HOME", __import__("os").environ["HOME"])
try:
    with open(alert_file, "r") as f:
        alerts = f.readlines()[-10:]  # Last 10 alerts
    if alerts:
        print("RECENT ALERTS:")
        print("-" * 60)
        for alert in alerts:
            print(alert.strip())
        print("-" * 60)
except:
    pass

# Health summary
print()
print("HEALTH SUMMARY:")
healthy = 0
unhealthy = 0
current_metrics = data[-1]["metrics"]
for metric, value in current_metrics.items():
    if value > 0:
        healthy += 1
    else:
        unhealthy += 1

print(f"  ✓ Healthy services: {healthy}")
if unhealthy > 0:
    print(f"  ✗ Unreachable services: {unhealthy}")
    for metric, value in current_metrics.items():
        if value <= 0:
            print(f"    - {metric}")
print()
PYEOF
