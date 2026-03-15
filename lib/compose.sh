#!/usr/bin/env bash

########################################
# Load runtime
########################################

source "${INSTALL_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/runtime.sh"

########################################
# Compose configuration
########################################

COMPOSE_FILE="${COMPOSE_FILE:-$STACK_DIR/docker-compose.yml}"

########################################
# Validate compose environment
########################################

compose_validate_environment() {

    [[ -d "$STACK_DIR" ]] || die "Media Stack directory not found: $STACK_DIR"

    [[ -f "$COMPOSE_FILE" ]] || die "docker-compose.yml missing in $STACK_DIR"

    require_command docker
}

########################################
# Start stack
########################################

compose_up() {

    compose_validate_environment

    log "Starting Media Stack"

    (
        cd "$STACK_DIR"
        docker compose up -d
    )
}

########################################
# Stop stack
########################################

compose_down() {

    compose_validate_environment

    log "Stopping Media Stack"

    (
        cd "$STACK_DIR"
        docker compose down
    )
}

########################################
# Restart stack
########################################

compose_restart() {

    compose_validate_environment

    log "Restarting Media Stack"

    (
        cd "$STACK_DIR"
        docker compose restart
    )
}

########################################
# Pull updates
########################################

compose_pull() {

    compose_validate_environment

    log "Pulling container updates"

    (
        cd "$STACK_DIR"
        docker compose pull
    )
}

########################################
# Show logs
########################################

compose_logs() {

    compose_validate_environment

    local SERVICE="${1:-}"

    (
        cd "$STACK_DIR"

        if [[ -n "$SERVICE" ]]; then
            docker compose logs -f "$SERVICE"
        else
            docker compose logs -f
        fi
    )
}

########################################
# Container status
########################################

compose_status() {

    compose_validate_environment

    (
        cd "$STACK_DIR"
        docker compose ps
    )
}

########################################
# Validate compose file
########################################

compose_validate() {

    compose_validate_environment

    (
        cd "$STACK_DIR"
        docker compose config >/dev/null
    )

    log "Compose file valid"
}