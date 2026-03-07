#!/usr/bin/env bash

STACK_DIR="/opt/media-stack"
BACKUP_DIR="/opt/media-stack-backups"
DATE=$(date +%Y%m%d-%H%M)

########################################
# NEW: Verify stack directory exists
########################################

if [ ! -d "$STACK_DIR" ]; then
echo "Media stack directory not found:"
echo "$STACK_DIR"
echo ""
echo "Nothing to back up."
exit 1
fi

########################################
# NEW: Verify tar is available
########################################

if ! command -v tar >/dev/null 2>&1; then
echo "tar utility not found."
echo "Backup cannot proceed."
exit 1
fi

mkdir -p "$BACKUP_DIR"

echo ""
echo "Creating Media Stack Backup"
echo ""

BACKUP_FILE="$BACKUP_DIR/media-stack-$DATE.tar.gz"

tar -czf "$BACKUP_FILE" "$STACK_DIR"

########################################
# NEW: Show backup file size
########################################

SIZE=$(du -h "$BACKUP_FILE" | awk '{print $1}')

echo ""
echo "Backup saved:"
echo "$BACKUP_FILE"
echo "Backup size: $SIZE"
echo ""