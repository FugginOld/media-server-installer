#!/usr/bin/env bats
# Tests for lib/services.sh

load helpers/common

REPO_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
    setup_common
    load_runtime
    # shellcheck disable=SC1090
    source "$REPO_DIR/lib/services.sh"
}

teardown() {
    teardown_common
}

# ---------------------------------------------------------------------------
# init_registry
# ---------------------------------------------------------------------------

@test "init_registry creates services.json with empty services array" {
    rm -f "$SERVICE_REGISTRY"
    init_registry
    [ -f "$SERVICE_REGISTRY" ]
    run jq -r '.services | length' "$SERVICE_REGISTRY"
    [ "$output" = "0" ]
}

@test "init_registry does not overwrite an existing registry" {
    echo '{"services":[{"name":"existing"}]}' > "$SERVICE_REGISTRY"
    init_registry
    run jq -r '.services[0].name' "$SERVICE_REGISTRY"
    [ "$output" = "existing" ]
}

@test "init_registry creates parent directory if needed" {
    local subdir="$TEST_TMPDIR/new_stack"
    export SERVICE_REGISTRY="$subdir/services.json"
    rm -rf "$subdir"
    init_registry
    [ -f "$SERVICE_REGISTRY" ]
}

# ---------------------------------------------------------------------------
# register_service — validation
# ---------------------------------------------------------------------------

@test "register_service fails when name is empty" {
    run register_service "" "8080" "media" "icon.png"
    [ "$status" -ne 0 ]
}

@test "register_service fails with non-numeric port" {
    run register_service "myapp" "notaport" "media" "icon.png"
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# register_service — happy path
# ---------------------------------------------------------------------------

@test "register_service adds service to registry" {
    init_registry
    register_service "sonarr" "8989" "tv" "sonarr.png"
    run jq -r '.services[] | select(.name=="sonarr") | .name' "$SERVICE_REGISTRY"
    [ "$output" = "sonarr" ]
}

@test "register_service stores correct URL with HOST_IP and port" {
    init_registry
    export HOST_IP="10.1.2.3"
    register_service "radarr" "7878" "movies" "radarr.png"
    run jq -r '.services[] | select(.name=="radarr") | .url' "$SERVICE_REGISTRY"
    [ "$output" = "http://10.1.2.3:7878" ]
}

@test "register_service appends path suffix to URL" {
    init_registry
    export HOST_IP="10.1.2.3"
    register_service "plex" "32400" "media" "plex.png" "/web"
    run jq -r '.services[] | select(.name=="plex") | .url' "$SERVICE_REGISTRY"
    [ "$output" = "http://10.1.2.3:32400/web" ]
}

@test "register_service auto-prefixes missing slash in path_suffix" {
    init_registry
    export HOST_IP="10.1.2.3"
    register_service "app" "8080" "misc" "app.png" "dashboard"
    run jq -r '.services[] | select(.name=="app") | .url' "$SERVICE_REGISTRY"
    [ "$output" = "http://10.1.2.3:8080/dashboard" ]
}

@test "register_service stores category" {
    init_registry
    register_service "bazarr" "6767" "subtitles" "bazarr.png"
    run jq -r '.services[] | select(.name=="bazarr") | .category' "$SERVICE_REGISTRY"
    [ "$output" = "subtitles" ]
}

@test "register_service stores icon" {
    init_registry
    register_service "bazarr" "6767" "subtitles" "bazarr.png"
    run jq -r '.services[] | select(.name=="bazarr") | .icon' "$SERVICE_REGISTRY"
    [ "$output" = "bazarr.png" ]
}

@test "register_service deduplicates: re-registering replaces existing entry" {
    init_registry
    export HOST_IP="10.0.0.1"
    register_service "sonarr" "8989" "tv" "sonarr.png"
    export HOST_IP="10.0.0.2"
    register_service "sonarr" "8989" "tv" "sonarr.png"
    # Only one entry should exist
    run jq -r '.services | map(select(.name=="sonarr")) | length' "$SERVICE_REGISTRY"
    [ "$output" = "1" ]
    # URL should reflect second registration
    run jq -r '.services[] | select(.name=="sonarr") | .url' "$SERVICE_REGISTRY"
    [ "$output" = "http://10.0.0.2:8989" ]
}

@test "register_service can register multiple different services" {
    init_registry
    register_service "sonarr"  "8989" "tv"     "sonarr.png"
    register_service "radarr"  "7878" "movies" "radarr.png"
    register_service "lidarr"  "8686" "music"  "lidarr.png"
    run jq -r '.services | length' "$SERVICE_REGISTRY"
    [ "$output" = "3" ]
}

# ---------------------------------------------------------------------------
# list_services / pretty_services
# ---------------------------------------------------------------------------

@test "list_services outputs name -> url pairs" {
    init_registry
    export HOST_IP="192.168.1.1"
    register_service "sonarr" "8989" "tv" "sonarr.png"
    run list_services
    [ "$status" -eq 0 ]
    [[ "$output" == *"sonarr -> http://192.168.1.1:8989"* ]]
}

@test "list_services returns empty output for empty registry" {
    init_registry
    run list_services
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "pretty_services outputs registered services" {
    init_registry
    export HOST_IP="192.168.1.1"
    register_service "radarr" "7878" "movies" "radarr.png"
    run pretty_services
    [ "$status" -eq 0 ]
    [[ "$output" == *"radarr"* ]]
}
