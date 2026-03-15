#!/usr/bin/env bash

########################################
# Load runtime
########################################

source "${INSTALL_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/runtime.sh"

########################################
# Discover plugins
########################################

discover_plugins() {

    find "$PLUGIN_DIR" -type f -name "*.sh" \
        ! -path "*/_template/*" \
        | sort
}

########################################
# Load plugin
########################################

load_plugin() {

    local FILE="$1"

    if [[ -f "$FILE" ]]; then
        source "$FILE"
    else
        warn "Plugin not found: $FILE"
    fi
}

########################################
# Collect compose blocks
########################################

collect_plugin_compose() {

    local SERVICES=("$@")

    for SERVICE in "${SERVICES[@]}"
    do
        local FILE="$PLUGIN_DIR/**/$SERVICE.sh"

        FILE=$(find "$PLUGIN_DIR" -name "$SERVICE.sh" | head -n1)

        load_plugin "$FILE"

        if declare -f plugin_compose >/dev/null; then
            plugin_compose
        else
            warn "Plugin missing compose function: $SERVICE"
        fi
    done
}