#!/bin/bash
# Restore Script for Mac Mini
# Usage: ./restore.sh [backup-file.tar.gz]

set -e

BACKUP_DIR="$HOME/backups"
TEMP_DIR="/tmp/restore-$$"

# Determine backup file to use
if [ -n "$1" ]; then
    BACKUP_FILE="$1"
    if [[ ! "$BACKUP_FILE" == /* ]]; then
        BACKUP_FILE="${BACKUP_DIR}/${BACKUP_FILE}"
    fi
else
    # Use most recent backup
    BACKUP_FILE=$(ls -t "${BACKUP_DIR}"/backup-*.tar.gz 2>/dev/null | head -1)
fi

if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: No backup file found"
    echo "Usage: $0 [backup-file.tar.gz]"
    echo ""
    echo "Available backups:"
    ls -lh "${BACKUP_DIR}"/backup-*.tar.gz 2>/dev/null || echo "  None"
    exit 1
fi

echo "=== Restore from: ${BACKUP_FILE} ==="
echo "WARNING: This will overwrite existing files!"
echo ""
read -p "Continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

# Extract backup
echo "Extracting backup..."
mkdir -p "${TEMP_DIR}"
cd "${TEMP_DIR}"
tar -xzf "${BACKUP_FILE}"

# Find the backup folder name
BACKUP_NAME=$(ls -d backup-* 2>/dev/null | head -1)
if [ -z "$BACKUP_NAME" ]; then
    echo "Error: Invalid backup structure"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

echo ""
echo "Available restore options:"
echo "  1) Full restore (all components)"
echo "  2) Restore ~/clawd/ only"
echo "  3) Restore ~/.clawdbot/ only"
echo "  4) Restore system configs only"
echo "  5) Show backup contents (no restore)"
echo "  6) Restore cron jobs only"
echo ""
read -p "Select option (1-6): " OPTION

case $OPTION in
    1)
        echo "Performing full restore..."
        
        # Restore ~/clawd/
        if [ -d "${TEMP_DIR}/${BACKUP_NAME}/clawd" ]; then
            echo "Restoring ~/clawd/..."
            rm -rf "$HOME/clawd"
            cp -r "${TEMP_DIR}/${BACKUP_NAME}/clawd" "$HOME/clawd"
        fi
        
        # Restore ~/.clawdbot/
        if [ -d "${TEMP_DIR}/${BACKUP_NAME}/clawdbot" ]; then
            echo "Restoring ~/.clawdbot/..."
            rm -rf "$HOME/.clawdbot"
            cp -r "${TEMP_DIR}/${BACKUP_NAME}/clawdbot" "$HOME/.clawdbot"
        fi
        
        # Restore system configs
        if [ -d "${TEMP_DIR}/${BACKUP_NAME}/system-configs" ]; then
            echo "Restoring system configs..."
            [ -f "${TEMP_DIR}/${BACKUP_NAME}/system-configs/ssh_config" ] && cp "${TEMP_DIR}/${BACKUP_NAME}/system-configs/ssh_config" "$HOME/.ssh/config"
            [ -f "${TEMP_DIR}/${BACKUP_NAME}/system-configs/zshrc" ] && cp "${TEMP_DIR}/${BACKUP_NAME}/system-configs/zshrc" "$HOME/.zshrc"
            [ -f "${TEMP_DIR}/${BACKUP_NAME}/system-configs/bashrc" ] && cp "${TEMP_DIR}/${BACKUP_NAME}/system-configs/bashrc" "$HOME/.bashrc"
            [ -f "${TEMP_DIR}/${BACKUP_NAME}/system-configs/bash_profile" ] && cp "${TEMP_DIR}/${BACKUP_NAME}/system-configs/bash_profile" "$HOME/.bash_profile"
            echo "NOTE: /etc/hosts requires sudo to restore manually"
        fi
        
        # Restore cron jobs
        if [ -f "${TEMP_DIR}/${BACKUP_NAME}/system-info/crontab.txt" ]; then
            echo "Restoring cron jobs..."
            crontab "${TEMP_DIR}/${BACKUP_NAME}/system-info/crontab.txt"
        fi
        ;;
    2)
        if [ -d "${TEMP_DIR}/${BACKUP_NAME}/clawd" ]; then
            echo "Restoring ~/clawd/..."
            rm -rf "$HOME/clawd"
            cp -r "${TEMP_DIR}/${BACKUP_NAME}/clawd" "$HOME/clawd"
        else
            echo "Error: ~/clawd not in backup"
        fi
        ;;
    3)
        if [ -d "${TEMP_DIR}/${BACKUP_NAME}/clawdbot" ]; then
            echo "Restoring ~/.clawdbot/..."
            rm -rf "$HOME/.clawdbot"
            cp -r "${TEMP_DIR}/${BACKUP_NAME}/clawdbot" "$HOME/.clawdbot"
        else
            echo "Error: ~/.clawdbot not in backup"
        fi
        ;;
    4)
        if [ -d "${TEMP_DIR}/${BACKUP_NAME}/system-configs" ]; then
            echo "Restoring system configs..."
            [ -f "${TEMP_DIR}/${BACKUP_NAME}/system-configs/ssh_config" ] && cp "${TEMP_DIR}/${BACKUP_NAME}/system-configs/ssh_config" "$HOME/.ssh/config"
            [ -f "${TEMP_DIR}/${BACKUP_NAME}/system-configs/zshrc" ] && cp "${TEMP_DIR}/${BACKUP_NAME}/system-configs/zshrc" "$HOME/.zshrc"
            [ -f "${TEMP_DIR}/${BACKUP_NAME}/system-configs/bashrc" ] && cp "${TEMP_DIR}/${BACKUP_NAME}/system-configs/bashrc" "$HOME/.bashrc"
            [ -f "${TEMP_DIR}/${BACKUP_NAME}/system-configs/bash_profile" ] && cp "${TEMP_DIR}/${BACKUP_NAME}/system-configs/bash_profile" "$HOME/.bash_profile"
            echo "NOTE: /etc/hosts needs sudo: sudo cp [backup]/system-configs/hosts /etc/hosts"
        else
            echo "Error: system-configs not in backup"
        fi
        ;;
    5)
        echo ""
        echo "=== Backup Contents ==="
        find "${TEMP_DIR}/${BACKUP_NAME}" -type f | sed "s|${TEMP_DIR}/${BACKUP_NAME}/||"
        echo ""
        echo "=== Ollama Models (at backup time) ==="
        cat "${TEMP_DIR}/${BACKUP_NAME}/system-info/ollama-models.txt" 2>/dev/null || echo "Not available"
        echo ""
        echo "=== Cron Jobs (at backup time) ==="
        cat "${TEMP_DIR}/${BACKUP_NAME}/system-info/crontab.txt" 2>/dev/null || echo "Not available"
        ;;
    6)
        if [ -f "${TEMP_DIR}/${BACKUP_NAME}/system-info/crontab.txt" ]; then
            echo "Current cron jobs in backup:"
            cat "${TEMP_DIR}/${BACKUP_NAME}/system-info/crontab.txt"
            echo ""
            read -p "Restore these cron jobs? (yes/no): " CONFIRM
            if [ "$CONFIRM" = "yes" ]; then
                crontab "${TEMP_DIR}/${BACKUP_NAME}/system-info/crontab.txt"
                echo "Cron jobs restored."
            fi
        else
            echo "Error: crontab not in backup"
        fi
        ;;
    *)
        echo "Invalid option"
        ;;
esac

# Cleanup
rm -rf "${TEMP_DIR}"

echo ""
echo "=== Restore complete ==="
