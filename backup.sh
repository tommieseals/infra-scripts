#!/bin/bash
# Automated Backup Script for Mac Mini
# Runs nightly at 2 AM via launchd

set -e

# Configuration
BACKUP_DIR="$HOME/backups"
DATE=$(date +%Y-%m-%d)
BACKUP_NAME="backup-${DATE}"
TEMP_DIR="/tmp/${BACKUP_NAME}"
KEEP_DAYS=7

echo "=== Starting backup: $(date) ==="

# Create temp directory for staging
rm -rf "${TEMP_DIR}"
mkdir -p "${TEMP_DIR}"

# 1. Backup ~/clawd/ (configs, scripts, memory)
echo "Backing up ~/clawd/..."
if [ -d "$HOME/clawd" ]; then
    cp -r "$HOME/clawd" "${TEMP_DIR}/clawd"
else
    echo "Warning: ~/clawd not found"
fi

# 2. Backup ~/.clawdbot/ (agent configs)
echo "Backing up ~/.clawdbot/..."
if [ -d "$HOME/.clawdbot" ]; then
    cp -r "$HOME/.clawdbot" "${TEMP_DIR}/clawdbot"
else
    echo "Warning: ~/.clawdbot not found"
fi

# 3. Save Ollama models list
echo "Saving Ollama models list..."
mkdir -p "${TEMP_DIR}/system-info"
if command -v ollama &> /dev/null; then
    ollama list > "${TEMP_DIR}/system-info/ollama-models.txt" 2>/dev/null || echo "Ollama not running" > "${TEMP_DIR}/system-info/ollama-models.txt"
else
    echo "Ollama not installed" > "${TEMP_DIR}/system-info/ollama-models.txt"
fi

# 4. Save cron jobs
echo "Saving cron jobs..."
crontab -l > "${TEMP_DIR}/system-info/crontab.txt" 2>/dev/null || echo "No crontab" > "${TEMP_DIR}/system-info/crontab.txt"

# 5. Backup system configs
echo "Backing up system configs..."
mkdir -p "${TEMP_DIR}/system-configs"

# /etc/hosts (needs sudo, so copy if readable)
if [ -r /etc/hosts ]; then
    cp /etc/hosts "${TEMP_DIR}/system-configs/hosts"
fi

# ~/.ssh/config
if [ -f "$HOME/.ssh/config" ]; then
    cp "$HOME/.ssh/config" "${TEMP_DIR}/system-configs/ssh_config"
fi

# ~/.zshrc
if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "${TEMP_DIR}/system-configs/zshrc"
fi

# ~/.bashrc (if exists)
if [ -f "$HOME/.bashrc" ]; then
    cp "$HOME/.bashrc" "${TEMP_DIR}/system-configs/bashrc"
fi

# ~/.bash_profile (if exists)
if [ -f "$HOME/.bash_profile" ]; then
    cp "$HOME/.bash_profile" "${TEMP_DIR}/system-configs/bash_profile"
fi

# 6. Create compressed archive
echo "Creating compressed archive..."
mkdir -p "${BACKUP_DIR}"
cd /tmp
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}"

# 7. Cleanup temp directory
rm -rf "${TEMP_DIR}"

# 8. Rotate old backups (keep last 7)
echo "Rotating old backups..."
cd "${BACKUP_DIR}"
ls -t backup-*.tar.gz 2>/dev/null | tail -n +8 | xargs rm -f 2>/dev/null || true

# 9. Summary
BACKUP_FILE="${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
echo ""
echo "=== Backup complete: $(date) ==="
echo "File: ${BACKUP_FILE}"
echo "Size: ${BACKUP_SIZE}"
echo ""
echo "Current backups:"
ls -lh "${BACKUP_DIR}"/backup-*.tar.gz 2>/dev/null || echo "No backups found"
