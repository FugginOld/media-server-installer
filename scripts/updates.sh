#!/usr/bin/env bash

STACK_DIR="/opt/media-stack"

echo "Pulling latest container images..."

cd "$STACK_DIR"
docker compose pull

echo "Recreating containers..."

docker compose up -d

echo "Update finished."