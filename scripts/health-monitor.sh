#!/usr/bin/env bash

echo "Checking container health..."

UNHEALTHY=$(docker ps --filter health=unhealthy --format "{{.Names}}")

for CONTAINER in $UNHEALTHY
do

echo "Restarting unhealthy container: $CONTAINER"

docker restart "$CONTAINER"

done