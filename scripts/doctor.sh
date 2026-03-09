#!/usr/bin/env bash

########################################
# Media Stack Doctor
#
# Diagnoses installation problems
# and verifies required components.
########################################

STACK_DIR="/opt/media-stack"
INSTALL_DIR="/opt/media-server-installer"
PLUGIN_DIR="$INSTALL_DIR/plugins"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

########################################
# Output helpers
########################################

pass() {
echo "PASS  $1"
((PASS_COUNT++))
}

warn() {
echo "WARN  $1"
((WARN_COUNT++))
}

fail() {
echo "FAIL  $1"
((FAIL_COUNT++))
}

echo ""
echo "================================"
echo " Media Stack Doctor"
echo "================================"
echo ""

########################################
# Installer directory
########################################

if [ -d "$INSTALL_DIR" ]; then
pass "Installer directory present"
else
fail "Installer directory missing ($INSTALL_DIR)"
fi

########################################
# Stack directory
########################################

if [ -d "$STACK_DIR" ]; then
pass "Stack directory present"
else
fail "Stack directory missing ($STACK_DIR)"
fi

########################################
# Docker binary
########################################

if command -v docker >/dev/null 2>&1; then
pass "Docker installed"
DOCKER_PRESENT=true
else
fail "Docker NOT installed"
DOCKER_PRESENT=false
fi

########################################
# Docker daemon
########################################

if [ "$DOCKER_PRESENT" = true ]; then

if docker info >/dev/null 2>&1; then
pass "Docker daemon running"
else
fail "Docker daemon NOT running"
fi

else
warn "Skipping daemon check (docker missing)"
fi

########################################
# Docker compose
########################################

if [ "$DOCKER_PRESENT" = true ]; then

if docker compose version >/dev/null 2>&1; then
pass "Docker Compose available"
else
fail "Docker Compose NOT available"
fi

else
warn "Skipping compose check"
fi

########################################
# docker-compose.yml
########################################

if [ -f "$STACK_DIR/docker-compose.yml" ]; then
pass "docker-compose.yml present"
else
fail "docker-compose.yml missing"
fi

########################################
# Service registry
########################################

if [ -f "$STACK_DIR/services.json" ]; then
pass "Service registry present"
else
warn "services.json missing"
fi

########################################
# Port registry
########################################

PORT_FILE="$STACK_DIR/ports.json"

if [ -f "$PORT_FILE" ]; then
pass "Port registry present"
PORT_REGISTRY=true
else
warn "Port registry missing"
PORT_REGISTRY=false
fi

########################################
# Plugin directory
########################################

if [ -d "$PLUGIN_DIR" ]; then

PLUGIN_COUNT=$(find "$PLUGIN_DIR" -type f -name "*.sh" ! -path "*/_template/*" | wc -l)

if [ "$PLUGIN_COUNT" -gt 0 ]; then
pass "Plugins detected ($PLUGIN_COUNT)"
else
warn "No plugins found"
fi

else
warn "Plugin directory missing"
fi

########################################
# Running containers
########################################

echo ""
echo "Container Status"

if [ "$DOCKER_PRESENT" = true ]; then

docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

else

echo "Docker unavailable"

fi

########################################
# Port conflict check
########################################

if [ "$PORT_REGISTRY" = true ] && command -v jq >/dev/null 2>&1; then

DUPLICATES=$(jq -r '.[]?.port' "$PORT_FILE" 2>/dev/null | sort | uniq -d)

if [ -z "$DUPLICATES" ]; then
pass "No duplicate ports in registry"
else
fail "Duplicate ports detected: $DUPLICATES"
fi

else
warn "Skipping port conflict check"
fi

########################################
# Summary
########################################

echo ""
echo "================================"
echo " Doctor Summary"
echo "================================"

echo "PASS: $PASS_COUNT"
echo "WARN: $WARN_COUNT"
echo "FAIL: $FAIL_COUNT"

echo ""

if [ "$FAIL_COUNT" -eq 0 ]; then
echo "System health: OK"
else
echo "System health: ISSUES DETECTED"
fi

echo ""