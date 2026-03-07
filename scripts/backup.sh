#!/usr/bin/env bash

STACK_DIR="/opt/media-stack"
BACKUP_DIR="/opt/media-stack-backups"

DATE=$(date +%Y%m%d-%H%M%S)

BACKUP_FILE="$BACKUP_DIR/media-stack-backup-$DATE.tar.gz"

echo ""
echo "================================"
echo " Media Stack Backup"
echo "================================"
echo ""

########################################
# Ensure stack exists
########################################

if [ ! -d "$STACK_DIR" ]; then
    echo "Stack directory not found."
    exit 1
fi

########################################
# Create backup directory
########################################

mkdir -p "$BACKUP_DIR"

########################################
# Create archive
########################################

echo "Creating backup..."

tar -czf "$BACKUP_FILE" \
"$STACK_DIR/docker-compose.yml" \
"$STACK_DIR/config" \
"$STACK_DIR/services.json" \
"$STACK_DIR/ports.json" \
"$STACK_DIR/stack.env" 2>/dev/null

########################################
# Verify backup
########################################

if [ -f "$BACKUP_FILE" ]; then
    echo ""
    echo "Backup successful."
    echo "Backup file:"
    echo "$BACKUP_FILE"
else
    echo "Backup failed."
    exit 1
fi

echo ""