#!/usr/bin/env bats
# Tests for core/permissions.sh

load helpers/common

REPO_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
    setup_common
    load_runtime
    # shellcheck disable=SC1090
    source "$REPO_DIR/core/permissions.sh"
}

teardown() {
    teardown_common
}

# ---------------------------------------------------------------------------
# detect_user_ids
# ---------------------------------------------------------------------------

@test "detect_user_ids respects pre-set PUID" {
    export PUID="1234"
    export PGID="1234"
    detect_user_ids
    [ "$PUID" = "1234" ]
}

@test "detect_user_ids respects pre-set PGID" {
    export PUID="1234"
    export PGID="5678"
    detect_user_ids
    [ "$PGID" = "5678" ]
}

@test "detect_user_ids falls back to current user ids when PUID is unset" {
    unset PUID PGID
    detect_user_ids
    [ -n "$PUID" ]
    [ -n "$PGID" ]
    # IDs must be numeric
    [[ "$PUID" =~ ^[0-9]+$ ]]
    [[ "$PGID" =~ ^[0-9]+$ ]]
}

@test "detect_user_ids exports PUID and PGID" {
    unset PUID PGID
    detect_user_ids
    # Verify they are exported (visible in subshell)
    run bash -c "echo \"\${PUID:-unset}\""
    [[ "$output" != "unset" ]]
}

# ---------------------------------------------------------------------------
# resolve_directories
# ---------------------------------------------------------------------------

@test "resolve_directories sets MEDIA_ROOT from MEDIA_DIR" {
    export MEDIA_DIR="/mnt/media"
    resolve_directories
    [ "$MEDIA_ROOT" = "/mnt/media" ]
}

@test "resolve_directories falls back to MEDIA_PATH when MEDIA_DIR unset" {
    unset MEDIA_DIR
    export MEDIA_PATH="/data/media"
    resolve_directories
    [ "$MEDIA_ROOT" = "/data/media" ]
}

@test "resolve_directories falls back to /media as last resort" {
    unset MEDIA_DIR MEDIA_PATH
    resolve_directories
    [ "$MEDIA_ROOT" = "/media" ]
}

@test "resolve_directories sets MOVIES_ROOT from MOVIES_DIR" {
    export MOVIES_DIR="/mnt/movies"
    resolve_directories
    [ "$MOVIES_ROOT" = "/mnt/movies" ]
}

@test "resolve_directories sets TV_ROOT from TV_DIR" {
    export TV_DIR="/mnt/tv"
    resolve_directories
    [ "$TV_ROOT" = "/mnt/tv" ]
}

@test "resolve_directories sets DOWNLOADS_ROOT from DOWNLOADS_DIR" {
    export DOWNLOADS_DIR="/mnt/downloads"
    resolve_directories
    [ "$DOWNLOADS_ROOT" = "/mnt/downloads" ]
}

# ---------------------------------------------------------------------------
# apply_nas_permissions
# ---------------------------------------------------------------------------

@test "apply_nas_permissions for unraid outputs Unraid message" {
    # Only needs to produce the right message; chmod may fail on fake paths
    export NAS_PLATFORM="unraid"
    export MEDIA_ROOT="$TEST_TMPDIR/media"
    export DOWNLOADS_ROOT="$TEST_TMPDIR/downloads"
    mkdir -p "$MEDIA_ROOT" "$DOWNLOADS_ROOT"
    run apply_nas_permissions
    [ "$status" -eq 0 ]
    [[ "$output" == *"Unraid"* ]]
}

@test "apply_nas_permissions for truenas outputs TrueNAS message" {
    export NAS_PLATFORM="truenas"
    export MEDIA_ROOT="$TEST_TMPDIR/media"
    export DOWNLOADS_ROOT="$TEST_TMPDIR/downloads"
    mkdir -p "$MEDIA_ROOT" "$DOWNLOADS_ROOT"
    run apply_nas_permissions
    [ "$status" -eq 0 ]
    [[ "$output" == *"TrueNAS"* ]]
}

@test "apply_nas_permissions for openmediavault outputs OMV message" {
    export NAS_PLATFORM="openmediavault"
    export MEDIA_ROOT="$TEST_TMPDIR/media"
    export PUID="$(id -u)"
    export PGID="$(id -g)"
    mkdir -p "$MEDIA_ROOT"
    run apply_nas_permissions
    [ "$status" -eq 0 ]
    [[ "$output" == *"OMV"* ]]
}

@test "apply_nas_permissions for casaos outputs CasaOS message" {
    export NAS_PLATFORM="casaos"
    export MEDIA_ROOT="$TEST_TMPDIR/media"
    mkdir -p "$MEDIA_ROOT"
    run apply_nas_permissions
    [ "$status" -eq 0 ]
    [[ "$output" == *"CasaOS"* ]]
}

@test "apply_nas_permissions for unknown NAS outputs no-rules message" {
    export NAS_PLATFORM="none"
    export MEDIA_ROOT="$TEST_TMPDIR/media"
    export DOWNLOADS_ROOT="$TEST_TMPDIR/downloads"
    mkdir -p "$MEDIA_ROOT" "$DOWNLOADS_ROOT"
    run apply_nas_permissions
    [ "$status" -eq 0 ]
    [[ "$output" == *"No NAS-specific permission rules applied"* ]]
}

# ---------------------------------------------------------------------------
# fix_media_permissions — basic smoke test
# ---------------------------------------------------------------------------

@test "fix_media_permissions creates directories that do not exist" {
    export PUID="$(id -u)"
    export PGID="$(id -g)"
    export MEDIA_ROOT="$TEST_TMPDIR/media_new"
    export MOVIES_ROOT="$TEST_TMPDIR/movies_new"
    export TV_ROOT="$TEST_TMPDIR/tv_new"
    export DOWNLOADS_ROOT="$TEST_TMPDIR/dl_new"
    export CONFIG_DIR="$TEST_TMPDIR/cfg_new"
    rm -rf "$MEDIA_ROOT" "$MOVIES_ROOT" "$TV_ROOT" "$DOWNLOADS_ROOT" "$CONFIG_DIR"
    fix_media_permissions
    [ -d "$MEDIA_ROOT" ]
    [ -d "$MOVIES_ROOT" ]
    [ -d "$TV_ROOT" ]
    [ -d "$DOWNLOADS_ROOT" ]
}

@test "fix_media_permissions skips empty directory entries" {
    export PUID="$(id -u)"
    export PGID="$(id -g)"
    export MEDIA_ROOT=""
    export MOVIES_ROOT="$TEST_TMPDIR/movies"
    export TV_ROOT="$TEST_TMPDIR/tv"
    export DOWNLOADS_ROOT="$TEST_TMPDIR/dl"
    export CONFIG_DIR="$TEST_TMPDIR/cfg"
    mkdir -p "$MOVIES_ROOT" "$TV_ROOT" "$DOWNLOADS_ROOT" "$CONFIG_DIR"
    # Should not fail even with an empty dir entry
    run fix_media_permissions
    [ "$status" -eq 0 ]
}
