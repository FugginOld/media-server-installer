#!/usr/bin/env bash
set -euo pipefail

########################################
#Load media-stack runtime
########################################

source "${INSTALL_DIR:-/opt/media-server-installer}/core/runtime.sh"

########################################
#Create Media Stack Backup
########################################

DATE="$(date +%Y%m%d-%H%M)"

########################################
#Ensure stack directory exists
########################################

if [ ! -d "$STACK_DIR" ]; then
echo "Media Stack directory not found: $STACK_DIR"
exit 1
fi

########################################
#Ensure backup directory exists
########################################

mkdir -p "$BACKUP_DIR"

########################################
#Backup filename
########################################

BACKUP_FILE="$BACKUP_DIR/media-stack-$DATE.tar.gz"

echo ""
echo "================================"
echo "Creating Media Stack Backup"
echo "================================"
echo ""

echo "Source: $STACK_DIR"
echo "Destination: $BACKUP_FILE"
echo ""

########################################
#Files to include
########################################

FILES=()

[ -d "$STACK_DIR/config" ] && FILES+=("config")
[ -f "$STACK_DIR/docker-compose.yml" ] && FILES+=("docker-compose.yml")
[ -f "$STACK_DIR/stack.env" ] && FILES+=("stack.env")
[ -f "$STACK_DIR/services.json" ] && FILES+=("services.json")
[ -f "$STACK_DIR/ports.json" ] && FILES+=("ports.json")

########################################
#Ensure something to backup
########################################

if [ ${#FILES[@]} -eq 0 ]; then
echo "Nothing to backup."
exit 1
fi

########################################
#Create backup
########################################

tar -czf "$BACKUP_FILE" \
-C "$STACK_DIR" \
"${FILES[@]}"

########################################
#Verify backup
########################################

if [ -f "$BACKUP_FILE" ]; then

SIZE="$(du -h "$BACKUP_FILE" | awk '{print $1}')"

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
#Cleanup old backups (keep last 10)
########################################

cd "$BACKUP_DIR" || exit 1

ls -1t media-stack-*.tar.gz 2>/dev/null | tail -n +11 | while read -r old
do
rm -f "$old"
done

echo ""
