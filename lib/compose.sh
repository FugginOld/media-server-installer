#!/usr/bin/env bash
set -euo pipefail

########################################
# Ensure runtime loaded
########################################

source "${INSTALL_DIR:-/opt/media-server-installer}/lib/runtime.sh"

########################################
# Compose file path
########################################

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

########################################
# Collect plugin compose sections
########################################

collect_plugin_compose() {

for SERVICE in "$@"
do

    [[ -z "$SERVICE" ]] && continue

    if [[ -z "${PLUGIN_PATHS[$SERVICE]:-}" ]]; then
        warn "Plugin not found for compose generation: $SERVICE"
        continue
    fi

    PLUGIN_FILE="${PLUGIN_PATHS[$SERVICE]}"

    source "$PLUGIN_FILE"

    if declare -f compose_service >/dev/null; then
        compose_service
    else
        warn "Plugin $SERVICE does not define compose_service()"
    fi

done

}

########################################
# Start containers
########################################

compose_up() {

if [[ ! -f "$COMPOSE_FILE" ]]; then
error "docker-compose.yml missing"
return 1
fi

docker compose -f "$COMPOSE_FILE" up -d

}

########################################
# Stop containers
########################################

compose_down() {

docker compose -f "$COMPOSE_FILE" down

}

########################################
# Restart containers
########################################

compose_restart() {

docker compose -f "$COMPOSE_FILE" restart

}

########################################
# Pull updates
########################################

compose_pull() {

docker compose -f "$COMPOSE_FILE" pull

}

########################################
# Status
########################################

compose_status() {

docker compose -f "$COMPOSE_FILE" ps

}

########################################
# Logs
########################################

compose_logs() {

local service="${1:-}"

if [[ -n "$service" ]]; then
    docker compose -f "$COMPOSE_FILE" logs -f "$service"
else
    docker compose -f "$COMPOSE_FILE" logs -f
fi

}

########################################
# Validate compose file
########################################

compose_validate() {

docker compose -f "$COMPOSE_FILE" config >/dev/null

echo "Compose configuration valid."

}

########################################
# Export functions
########################################

export -f collect_plugin_compose
export -f compose_up
export -f compose_down
export -f compose_restart
export -f compose_pull
export -f compose_status
export -f compose_logs
export -f compose_validate
