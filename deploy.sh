#!/bin/bash
#==============================================================================
# Clawd Deployment Script - Simple CI/CD
# Usage: ./deploy.sh [--rollback [N]] [--dry-run] [--force]
# 
# Created: 2026-02-17
# Keeps last 3 versions for rollback
#==============================================================================

set -e  # Exit on error

# Configuration
CLAWD_DIR="$HOME/clawd"
VERSIONS_DIR="$HOME/clawd-versions"
MAX_VERSIONS=3
LOG_FILE="$CLAWD_DIR/logs/deploy.log"
LOCK_FILE="/tmp/clawd-deploy.lock"

# Services to restart (launchd labels)
SERVICES=(
    "com.clawdbot.gateway"
    "com.clawd.dashboard-server"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#==============================================================================
# Helper Functions
#==============================================================================

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo -e "$msg"
    echo "$msg" >> "$LOG_FILE"
}

notify() {
    local status="$1"
    local message="$2"
    
    # Telegram notification via clawdbot (if available)
    if command -v clawdbot &> /dev/null; then
        clawdbot notify "$message" 2>/dev/null || true
    fi
    
    # Also log to file
    log "NOTIFY [$status]: $message"
}

error_exit() {
    log "${RED}ERROR: $1${NC}"
    notify "FAILURE" "🚨 Deploy failed: $1"
    cleanup_lock
    exit 1
}

cleanup_lock() {
    rm -f "$LOCK_FILE"
}

acquire_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local pid=$(cat "$LOCK_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            error_exit "Another deployment is running (PID: $pid)"
        fi
        log "Removing stale lock file"
        rm -f "$LOCK_FILE"
    fi
    echo $$ > "$LOCK_FILE"
    trap cleanup_lock EXIT
}

#==============================================================================
# Version Management
#==============================================================================

create_version_backup() {
    local version_name="v$(date '+%Y%m%d-%H%M%S')"
    local version_path="$VERSIONS_DIR/$version_name"
    
    log "Creating version backup: $version_name"
    mkdir -p "$VERSIONS_DIR"
    
    # Copy current state (exclude logs, temp, node_modules)
    rsync -a --exclude='logs' --exclude='temp' --exclude='node_modules' \
          --exclude='.git' --exclude='*.log' --exclude='clawd-versions' \
          "$CLAWD_DIR/" "$version_path/"
    
    # Save git info
    cd "$CLAWD_DIR"
    git_commit=$(git rev-parse HEAD 2>/dev/null || echo 'no-git')
    git_branch=$(git branch --show-current 2>/dev/null || echo 'unknown')
    echo "commit: $git_commit" > "$version_path/.deploy-info"
    echo "branch: $git_branch" >> "$version_path/.deploy-info"
    echo "date: $(date -Iseconds)" >> "$version_path/.deploy-info"
    
    echo "$version_name"
}

cleanup_old_versions() {
    log "Cleaning up old versions (keeping last $MAX_VERSIONS)"
    
    if [ ! -d "$VERSIONS_DIR" ]; then
        return
    fi
    
    cd "$VERSIONS_DIR"
    local count=$(ls -1 | wc -l)
    
    if [ "$count" -gt "$MAX_VERSIONS" ]; then
        local to_delete=$((count - MAX_VERSIONS))
        ls -1t | tail -n "$to_delete" | while read old_version; do
            if [ -n "$old_version" ]; then
                log "Removing old version: $old_version"
                rm -rf "$old_version"
            fi
        done
    fi
}

list_versions() {
    echo "Available versions for rollback:"
    if [ -d "$VERSIONS_DIR" ]; then
        ls -1t "$VERSIONS_DIR" | head -n "$MAX_VERSIONS" | nl
    else
        echo "No versions available"
    fi
}

#==============================================================================
# Rollback
#==============================================================================

rollback() {
    local version_num="${1:-1}"
    
    log "${YELLOW}Starting rollback to version #$version_num...${NC}"
    
    if [ ! -d "$VERSIONS_DIR" ]; then
        error_exit "No versions directory found"
    fi
    
    local target_version=$(ls -1t "$VERSIONS_DIR" | sed -n "${version_num}p")
    
    if [ -z "$target_version" ]; then
        log "Available versions:"
        list_versions
        error_exit "Version #$version_num not found"
    fi
    
    local version_path="$VERSIONS_DIR/$target_version"
    log "Rolling back to: $target_version"
    
    # Create backup of current state before rollback
    create_version_backup
    
    # Stop services first
    stop_services
    
    # Restore files (preserve .git, logs, etc)
    rsync -a --delete --exclude='.git' --exclude='logs' --exclude='temp' \
          --exclude='node_modules' --exclude='clawd-versions' \
          "$version_path/" "$CLAWD_DIR/"
    
    # Restart services
    start_services
    
    log "${GREEN}Rollback complete!${NC}"
    notify "SUCCESS" "✅ Rolled back to $target_version"
}

#==============================================================================
# Service Management
#==============================================================================

stop_services() {
    log "Stopping services..."
    for service in "${SERVICES[@]}"; do
        if launchctl list | grep -q "$service"; then
            log "  Stopping $service"
            launchctl stop "$service" 2>/dev/null || true
        fi
    done
    sleep 2
}

start_services() {
    log "Starting services..."
    for service in "${SERVICES[@]}"; do
        if launchctl list | grep -q "$service"; then
            log "  Starting $service"
            launchctl start "$service" 2>/dev/null || true
        fi
    done
    sleep 2
}

restart_services() {
    stop_services
    start_services
    log "Services restarted"
}

#==============================================================================
# Deployment
#==============================================================================

check_for_updates() {
    cd "$CLAWD_DIR"
    
    # Check if remote exists
    if ! git remote get-url origin &>/dev/null; then
        log "No git remote configured - skipping pull"
        return 1
    fi
    
    # Fetch latest
    git fetch origin 2>/dev/null || {
        log "${YELLOW}Warning: Could not fetch from remote${NC}"
        return 1
    }
    
    local local_hash=$(git rev-parse HEAD)
    local current_branch=$(git branch --show-current)
    local remote_hash=$(git rev-parse "origin/$current_branch" 2>/dev/null || echo "")
    
    if [ -z "$remote_hash" ]; then
        log "Could not determine remote hash"
        return 1
    fi
    
    if [ "$local_hash" = "$remote_hash" ]; then
        log "Already up to date ($local_hash)"
        return 1
    fi
    
    log "Updates available: $local_hash -> $remote_hash"
    return 0
}

pull_updates() {
    cd "$CLAWD_DIR"
    
    # Check if remote exists
    if ! git remote get-url origin &>/dev/null; then
        log "No git remote configured - skipping pull"
        return 0
    fi
    
    log "Pulling latest changes..."
    local current_branch=$(git branch --show-current)
    
    # Stash any local changes
    if ! git diff --quiet; then
        log "Stashing local changes"
        git stash push -m "deploy-auto-stash-$(date +%s)"
    fi
    
    # Pull
    git pull origin "$current_branch" || error_exit "Git pull failed"
    
    log "Pull complete"
}

run_migrations() {
    log "Running migrations/updates..."
    
    # Check for package.json updates (dashboard)
    if [ -f "$CLAWD_DIR/dashboard/package.json" ]; then
        cd "$CLAWD_DIR/dashboard"
        if [ -f "package-lock.json" ]; then
            log "  Checking npm dependencies..."
            npm ci --silent 2>/dev/null || npm install --silent 2>/dev/null || true
        fi
    fi
    
    # Run any custom migration scripts
    if [ -f "$CLAWD_DIR/scripts/post-deploy.sh" ]; then
        log "  Running post-deploy.sh..."
        bash "$CLAWD_DIR/scripts/post-deploy.sh"
    fi
    
    log "Migrations complete"
}

health_check() {
    log "Running health checks..."
    local all_ok=true
    
    # Check dashboard
    if curl -s -o /dev/null -w '%{http_code}' http://localhost:3000 | grep -qE '200|302'; then
        log "  ✓ Dashboard responding"
    else
        log "  ✗ Dashboard not responding"
        all_ok=false
    fi
    
    # Check Ollama
    if curl -s -o /dev/null http://localhost:11434/api/tags; then
        log "  ✓ Ollama responding"
    else
        log "  ✗ Ollama not responding"
    fi
    
    # Check gateway
    if launchctl list | grep -qE "[0-9]+.*com.clawdbot.gateway"; then
        log "  ✓ Gateway service running"
    else
        log "  ✗ Gateway service not running"
        all_ok=false
    fi
    
    $all_ok
}

deploy() {
    local dry_run="$1"
    local force="$2"
    
    log "========================================"
    log "${GREEN}Starting Clawd Deployment${NC}"
    log "========================================"
    
    acquire_lock
    
    # Check for updates (unless force)
    if [ "$force" != "true" ]; then
        if ! check_for_updates; then
            if [ "$dry_run" = "true" ]; then
                log "[DRY RUN] No updates found"
            else
                log "No updates to deploy"
            fi
            return 0
        fi
    fi
    
    if [ "$dry_run" = "true" ]; then
        log "[DRY RUN] Would deploy the following:"
        log "  - Create version backup"
        log "  - Pull git changes"
        log "  - Run migrations"
        log "  - Restart services"
        return 0
    fi
    
    # Create backup before deploy
    local version=$(create_version_backup)
    log "Created backup: $version"
    
    # Pull changes
    pull_updates
    
    # Run migrations
    run_migrations
    
    # Restart services
    restart_services
    
    # Health check
    if health_check; then
        log "${GREEN}Deployment successful!${NC}"
        notify "SUCCESS" "✅ Deployed successfully (backup: $version)"
    else
        log "${YELLOW}Deployment complete but health checks failed${NC}"
        notify "WARNING" "⚠️ Deployed but health checks failed"
    fi
    
    # Cleanup old versions
    cleanup_old_versions
    
    log "========================================"
    log "Deployment finished at $(date)"
    log "========================================"
}

#==============================================================================
# Main
#==============================================================================

main() {
    mkdir -p "$(dirname "$LOG_FILE")"
    
    case "$1" in
        --rollback)
            rollback "${2:-1}"
            ;;
        --list-versions)
            list_versions
            ;;
        --dry-run)
            deploy "true" "false"
            ;;
        --force)
            deploy "false" "true"
            ;;
        --health)
            health_check
            ;;
        --help|-h)
            echo "Clawd Deployment Script"
            echo ""
            echo "Usage: $0 [OPTION]"
            echo ""
            echo "Options:"
            echo "  (none)          Deploy if updates available"
            echo "  --force         Deploy even without updates"
            echo "  --dry-run       Show what would be done"
            echo "  --rollback [N]  Rollback to version N (default: 1 = most recent)"
            echo "  --list-versions List available versions"
            echo "  --health        Run health checks only"
            echo "  --help          Show this help"
            ;;
        *)
            deploy "false" "false"
            ;;
    esac
}

main "$@"
