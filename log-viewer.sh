#!/bin/bash
# Simple Log Viewer Script

LOG_DIR="$HOME/clawd/logs"

usage() {
    echo "Log Viewer - Simple log analysis tool"
    echo ""
    echo "Usage: $(basename $0) <command> [options]"
    echo ""
    echo "Commands:"
    echo "  list                 List available log dates and hosts"
    echo "  tail <host> [n]      Show last n lines (default: 50) from today's logs"
    echo "  search <pattern>     Search all logs for pattern"
    echo "  grep <host> <pattern> Search specific host logs"
    echo "  today [host]         Show today's logs for host (or all)"
    echo "  errors [host]        Find errors/warnings in logs"
    echo ""
    echo "Hosts: mac-mini, mac-pro, dell"
    echo ""
    echo "Examples:"
    echo "  $(basename $0) list"
    echo "  $(basename $0) tail mac-mini 100"
    echo "  $(basename $0) search 'error'"
    echo "  $(basename $0) errors mac-mini"
}

list_logs() {
    echo "=== Available Logs ==="
    echo ""
    for host in mac-mini mac-pro dell; do
        if [ -d "$LOG_DIR/$host" ]; then
            echo "$host:"
            ls -1 "$LOG_DIR/$host" 2>/dev/null | head -10
            echo ""
        fi
    done
}

tail_logs() {
    local host=$1
    local lines=${2:-50}
    local today=$(date +%Y-%m-%d)
    
    if [ -d "$LOG_DIR/$host/$today" ]; then
        echo "=== Last $lines lines from $host ($today) ==="
        for f in "$LOG_DIR/$host/$today"/*; do
            if [ -f "$f" ]; then
                echo "--- $(basename $f) ---"
                tail -n "$lines" "$f"
                echo ""
            fi
        done
    else
        echo "No logs found for $host on $today"
    fi
}

search_all() {
    local pattern=$1
    echo "=== Searching all logs for: $pattern ==="
    grep -r -i "$pattern" "$LOG_DIR" 2>/dev/null | head -100
}

grep_host() {
    local host=$1
    local pattern=$2
    echo "=== Searching $host logs for: $pattern ==="
    grep -r -i "$pattern" "$LOG_DIR/$host" 2>/dev/null | head -100
}

show_today() {
    local host=${1:-all}
    local today=$(date +%Y-%m-%d)
    
    if [ "$host" = "all" ]; then
        for h in mac-mini mac-pro dell; do
            show_today "$h"
        done
    else
        if [ -d "$LOG_DIR/$host/$today" ]; then
            echo "=== $host - $today ==="
            for f in "$LOG_DIR/$host/$today"/*; do
                [ -f "$f" ] && echo "  $(basename $f): $(wc -l < "$f") lines"
            done
            echo ""
        fi
    fi
}

find_errors() {
    local host=${1:-all}
    echo "=== Errors and Warnings ==="
    
    if [ "$host" = "all" ]; then
        grep -r -i -E "(error|warn|fail|critical|exception)" "$LOG_DIR" 2>/dev/null | head -50
    else
        grep -r -i -E "(error|warn|fail|critical|exception)" "$LOG_DIR/$host" 2>/dev/null | head -50
    fi
}

# Main
case "${1:-}" in
    list)
        list_logs
        ;;
    tail)
        tail_logs "${2:-mac-mini}" "${3:-50}"
        ;;
    search)
        search_all "${2:-error}"
        ;;
    grep)
        grep_host "${2:-mac-mini}" "${3:-error}"
        ;;
    today)
        show_today "${2:-all}"
        ;;
    errors)
        find_errors "${2:-all}"
        ;;
    *)
        usage
        ;;
esac
