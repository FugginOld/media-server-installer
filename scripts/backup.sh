#!/usr/bin/env bash

########################################
# Media Stack Backup System
#
# Creates a compressed backup of
# Media Stack configuration and
# registry files.
########################################

########################################
# Load environment
########################################

source "$INSTALL_DIR/core/env.sh"

DATE=$(date +%Y%m%d-%H%M)

########################################
# Ensure stack directory exists
########################################

if [ ! -d "$STACK_DIR" ]; then
echo "Media Stack directory not found: $STACK_DIR"
exit 1
fi

########################################
# Ensure backup directory exists
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
# Files to include in backup
########################################

FILES=(
config
docker-compose.yml
stack.env
services.json
ports.json
)

########################################
# Create backup
########################################

tar -czf "$BACKUP_FILE" \
-C "$STACK_DIR" \
"${FILES[@]}" 2>/dev/null

########################################
# Verify backup
########################################

if [ -f "$BACKUP_FILE" ]; then

SIZE=$(du -h "$BACKUP_FILE" | awk '{print $1}')

echo "Backup created successfully."
echo "Backup size: $SIZE"
echo ""
echo "Backup file:"
echo "$BACKUP_FILE"

else

echo "Backup failed."
exit 1

fi

########################################
# Cleanup old backups (keep last 10)
########################################

ls -1t "$BACKUP_DIR"/media-stack-*.tar.gz 2>/dev/null \
| tail -n +11 \
| xargs -r rm

echo ""