#!/usr/bin/env bash

STACK_DIR="/opt/media-stack"
BACKUP_DIR="/opt/media-stack-backups"
DATE=$(date +%Y%m%d-%H%M)

mkdir -p "$BACKUP_DIR"

echo ""
echo "Creating Media Stack Backup"
echo ""

tar -czf "$BACKUP_DIR/media-stack-$DATE.tar.gz" "$STACK_DIR"

echo ""
echo "Backup saved:"
echo "$BACKUP_DIR/media-stack-$DATE.tar.gz"
echo ""