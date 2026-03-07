#!/usr/bin/env bash

########################################
# Media Stack Backup
#
# Creates a compressed backup of the
# Media Stack configuration directory.
########################################

STACK_DIR="/opt/media-stack"
BACKUP_DIR="/opt/media-stack-backups"
DATE=$(date +%Y%m%d-%H%M)

########################################
# Ensure stack directory exists
########################################

if [ ! -d "$STACK_DIR" ]; then
echo "Media stack directory not found."
exit 1
fi

########################################
# Create backup directory if needed
########################################

mkdir -p "$BACKUP_DIR"

########################################
# Backup filename
########################################

BACKUP_FILE="$BACKUP_DIR/media-stack-$DATE.tar.gz"

echo ""
echo "================================"
echo " Creating Media Stack Backup"
echo "================================"
echo ""

echo "Source: $STACK_DIR"
echo "Destination: $BACKUP_FILE"
echo ""

########################################
# Create compressed backup
########################################

tar -czf "$BACKUP_FILE" "$STACK_DIR"

########################################
# Verify backup
########################################

if [ -f "$BACKUP_FILE" ]; then

echo "Backup created successfully."
echo ""
echo "Backup file:"
echo "$BACKUP_FILE"

else

echo "Backup failed."

fi

echo ""