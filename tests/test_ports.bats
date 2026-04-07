#!/usr/bin/env bats
# Tests for lib/ports.sh

load helpers/common

REPO_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
    setup_common
    load_runtime
    # shellcheck disable=SC1090
    source "$REPO_DIR/lib/ports.sh"
}

teardown() {
    teardown_common
}

# ---------------------------------------------------------------------------
# init_port_registry
# ---------------------------------------------------------------------------

@test "init_port_registry creates ports.json with empty object" {
    rm -f "$PORT_REGISTRY"
    init_port_registry
    [ -f "$PORT_REGISTRY" ]
    run jq -r 'type' "$PORT_REGISTRY"
    [ "$output" = "object" ]
    run jq -r 'length' "$PORT_REGISTRY"
    [ "$output" = "0" ]
}

@test "init_port_registry does not overwrite existing registry" {
    echo '{"sonarr":8989}' > "$PORT_REGISTRY"
    init_port_registry
    run jq -r '.sonarr' "$PORT_REGISTRY"
    [ "$output" = "8989" ]
}

@test "init_port_registry creates parent directory when missing" {
    local subdir="$TEST_TMPDIR/newstack"
    rm -rf "$subdir"
    export PORT_REGISTRY="$subdir/ports.json"
    init_port_registry
    [ -f "$PORT_REGISTRY" ]
}

# ---------------------------------------------------------------------------
# register_port — validation
# ---------------------------------------------------------------------------

@test "register_port exits with error when service name is empty" {
    run register_port "" "8080"
    [ "$status" -ne 0 ]
}

@test "register_port returns empty string for empty port argument" {
    init_port_registry
    run register_port "myapp" ""
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

# ---------------------------------------------------------------------------
# register_port — happy path
# ---------------------------------------------------------------------------

@test "register_port registers a free port and returns it" {
    init_port_registry
    # Use a port unlikely to be in use
    run register_port "testapp" "61234"
    [ "$status" -eq 0 ]
    [ "$output" = "61234" ]
    run jq -r '.testapp' "$PORT_REGISTRY"
    [ "$output" = "61234" ]
}

@test "register_port overwrites an existing entry for the same service" {
    init_port_registry
    register_port "myapp" "61235" >/dev/null
    run register_port "myapp" "61236"
    [ "$output" = "61236" ]
    run jq -r '.myapp' "$PORT_REGISTRY"
    [ "$output" = "61236" ]
}

@test "register_port stores multiple distinct services" {
    init_port_registry
    register_port "sonarr"  "61237" >/dev/null
    register_port "radarr"  "61238" >/dev/null
    run jq -r '.sonarr' "$PORT_REGISTRY"
    [ "$output" = "61237" ]
    run jq -r '.radarr' "$PORT_REGISTRY"
    [ "$output" = "61238" ]
}

# ---------------------------------------------------------------------------
# get_port_mapping / get_port
# ---------------------------------------------------------------------------

@test "get_port_mapping returns empty string when service has no mapping and no default" {
    init_port_registry
    run get_port_mapping "unknown_service"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "get_port_mapping returns existing mapped port" {
    init_port_registry
    register_port "sonarr" "61239" >/dev/null
    run get_port_mapping "sonarr"
    [ "$status" -eq 0 ]
    [ "$output" = "61239" ]
}

@test "get_port_mapping registers and returns default when not yet mapped" {
    init_port_registry
    run get_port_mapping "newapp" "61240"
    [ "$status" -eq 0 ]
    [ "$output" = "61240" ]
    # Verify it was persisted
    run jq -r '.newapp' "$PORT_REGISTRY"
    [ "$output" = "61240" ]
}

@test "get_port is an alias for get_port_mapping" {
    init_port_registry
    register_port "aliasapp" "61241" >/dev/null
    run get_port "aliasapp"
    [ "$output" = "61241" ]
}

@test "get_port_mapping returns empty when no service name given" {
    init_port_registry
    run get_port_mapping ""
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

# ---------------------------------------------------------------------------
# port_in_use
# ---------------------------------------------------------------------------

@test "port_in_use returns 1 (free) for a port that is not listening" {
    # Port 61999 is very unlikely to be in use
    run port_in_use "61999"
    [ "$status" -eq 1 ]
}

@test "port_in_use returns 0 (in use) for an actively listening port" {
    if ! command -v python3 >/dev/null 2>&1; then
        skip "python3 not available for port listener"
    fi
    python3 -c "
import socket, time
s = socket.socket()
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(('127.0.0.1', 62001))
s.listen(1)
time.sleep(10)
" &
    local LISTENER_PID=$!
    sleep 0.3
    run port_in_use "62001"
    kill "$LISTENER_PID" 2>/dev/null || true
    wait "$LISTENER_PID" 2>/dev/null || true
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# find_next_port
# ---------------------------------------------------------------------------

@test "find_next_port returns the given port when it is free" {
    run find_next_port "62100"
    [ "$status" -eq 0 ]
    [ "$output" = "62100" ]
}

@test "find_next_port increments to next free port when starting port is in use" {
    if ! command -v python3 >/dev/null 2>&1; then
        skip "python3 not available for port listener"
    fi
    python3 -c "
import socket, time
s = socket.socket()
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(('127.0.0.1', 62200))
s.listen(1)
time.sleep(10)
" &
    local LISTENER_PID=$!
    sleep 0.3
    run find_next_port "62200"
    kill "$LISTENER_PID" 2>/dev/null || true
    wait "$LISTENER_PID" 2>/dev/null || true
    [ "$status" -eq 0 ]
    # Result must be 62201 or higher
    [ "$output" -gt "62200" ]
}
