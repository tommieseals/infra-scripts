#!/bin/bash
# Automated backup to Mac Pro
# Created: 2026-02-13 00:31 CST

BACKUP_HOST="administrator@100.67.192.21"
BACKUP_ROOT="~/clawd-backups"
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H%M%S)

echo "[$DATE $TIME] 🔄 Starting Mac Pro backup..."

# Critical files (core documentation)
echo "  → Backing up critical files..."
rsync -avz --quiet ~/clawd/*.md "$BACKUP_HOST:$BACKUP_ROOT/critical/$DATE/"

# Memory files
echo "  → Backing up memory files..."
rsync -avz --quiet ~/clawd/memory/ "$BACKUP_HOST:$BACKUP_ROOT/memory/"

# Project Legion
if [ -d ~/job-hunter-system ]; then
    echo "  → Backing up Project Legion..."
    rsync -avz --quiet ~/job-hunter-system/ "$BACKUP_HOST:$BACKUP_ROOT/project-legion/latest/"
fi

# Scripts
echo "  → Backing up scripts..."
rsync -avz --quiet ~/clawd/scripts/ "$BACKUP_HOST:$BACKUP_ROOT/scripts/"

# Docs (if exist)
if [ -d ~/clawd/docs ]; then
    echo "  → Backing up docs..."
    rsync -avz --quiet ~/clawd/docs/ "$BACKUP_HOST:$BACKUP_ROOT/docs/"
fi

echo "[$DATE $TIME] ✅ Backup complete!"
echo ""
echo "Backup location: $BACKUP_HOST:$BACKUP_ROOT"
echo "Verify with: ssh mac-pro 'du -sh ~/clawd-backups/*'"
