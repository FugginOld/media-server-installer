#!/usr/bin/env bats
# Tests for core/directories.sh

load helpers/common

REPO_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

# Helper: source directories.sh in an isolated subshell with DIR_MODE set.
_run_dirs() {
    local dir_mode="${1:-default}"
    local extra="${2:-}"
    bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'
        export STACK_DIR='$TEST_TMPDIR/stack'
        export DIR_MODE='${dir_mode}'
        source '$REPO_DIR/lib/runtime.sh'
        source '$REPO_DIR/core/directories.sh'
        apply_directory_layout
        echo \"MEDIA_DIR=\$MEDIA_DIR\"
        echo \"MOVIES_DIR=\$MOVIES_DIR\"
        echo \"TV_DIR=\$TV_DIR\"
        echo \"DOWNLOADS_DIR=\$DOWNLOADS_DIR\"
        ${extra}
    "
}

setup() {
    setup_common
}

teardown() {
    teardown_common
}

# ---------------------------------------------------------------------------
# apply_directory_layout — default mode
# ---------------------------------------------------------------------------

@test "apply_directory_layout default: MEDIA_DIR defaults to /media" {
    run _run_dirs "default"
    [ "$status" -eq 0 ]
    [[ "$output" == *"MEDIA_DIR=/media"* ]]
}

@test "apply_directory_layout default: MOVIES_DIR defaults to /media/movies" {
    run _run_dirs "default"
    [ "$status" -eq 0 ]
    [[ "$output" == *"MOVIES_DIR=/media/movies"* ]]
}

@test "apply_directory_layout default: TV_DIR defaults to /media/tv" {
    run _run_dirs "default"
    [ "$status" -eq 0 ]
    [[ "$output" == *"TV_DIR=/media/tv"* ]]
}

@test "apply_directory_layout default: DOWNLOADS_DIR defaults to /downloads" {
    run _run_dirs "default"
    [ "$status" -eq 0 ]
    [[ "$output" == *"DOWNLOADS_DIR=/downloads"* ]]
}

@test "apply_directory_layout default: respects MEDIA_PATH override" {
    run bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'
        export STACK_DIR='$TEST_TMPDIR/stack'
        export DIR_MODE='default'
        export MEDIA_PATH='/mnt/nas/media'
        source '$REPO_DIR/lib/runtime.sh'
        source '$REPO_DIR/core/directories.sh'
        apply_directory_layout
        echo \"MEDIA_DIR=\$MEDIA_DIR\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"MEDIA_DIR=/mnt/nas/media"* ]]
}

@test "apply_directory_layout default: respects DOWNLOADS_PATH override" {
    run bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'
        export STACK_DIR='$TEST_TMPDIR/stack'
        export DIR_MODE='default'
        export DOWNLOADS_PATH='/mnt/downloads'
        source '$REPO_DIR/lib/runtime.sh'
        source '$REPO_DIR/core/directories.sh'
        apply_directory_layout
        echo \"DOWNLOADS_DIR=\$DOWNLOADS_DIR\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"DOWNLOADS_DIR=/mnt/downloads"* ]]
}

# ---------------------------------------------------------------------------
# apply_directory_layout — trash mode
# ---------------------------------------------------------------------------

@test "apply_directory_layout trash: MEDIA_DIR set to /data/media" {
    run _run_dirs "trash"
    [ "$status" -eq 0 ]
    [[ "$output" == *"MEDIA_DIR=/data/media"* ]]
}

@test "apply_directory_layout trash: MOVIES_DIR set to /data/media/movies" {
    run _run_dirs "trash"
    [ "$status" -eq 0 ]
    [[ "$output" == *"MOVIES_DIR=/data/media/movies"* ]]
}

@test "apply_directory_layout trash: TV_DIR set to /data/media/tv" {
    run _run_dirs "trash"
    [ "$status" -eq 0 ]
    [[ "$output" == *"TV_DIR=/data/media/tv"* ]]
}

@test "apply_directory_layout trash: DOWNLOADS_DIR set to /data/downloads" {
    run _run_dirs "trash"
    [ "$status" -eq 0 ]
    [[ "$output" == *"DOWNLOADS_DIR=/data/downloads"* ]]
}

# ---------------------------------------------------------------------------
# apply_directory_layout — unknown/fallback mode
# ---------------------------------------------------------------------------

@test "apply_directory_layout with unknown mode falls back to /media layout" {
    run _run_dirs "custom_unknown"
    [ "$status" -eq 0 ]
    [[ "$output" == *"MEDIA_DIR=/media"* ]]
    [[ "$output" == *"DOWNLOADS_DIR=/downloads"* ]]
}

# ---------------------------------------------------------------------------
# apply_directory_layout — compat exports
# ---------------------------------------------------------------------------

@test "apply_directory_layout exports MEDIA_PATH and MOVIES_PATH compat vars" {
    run _run_dirs "default" "echo \"MEDIA_PATH=\$MEDIA_PATH\"; echo \"MOVIES_PATH=\$MOVIES_PATH\""
    [ "$status" -eq 0 ]
    [[ "$output" == *"MEDIA_PATH=/media"* ]]
    [[ "$output" == *"MOVIES_PATH=/media/movies"* ]]
}

@test "apply_directory_layout exports TV_PATH and DOWNLOADS_PATH compat vars" {
    run _run_dirs "default" "echo \"TV_PATH=\$TV_PATH\"; echo \"DOWNLOADS_PATH=\$DOWNLOADS_PATH\""
    [ "$status" -eq 0 ]
    [[ "$output" == *"TV_PATH=/media/tv"* ]]
    [[ "$output" == *"DOWNLOADS_PATH=/downloads"* ]]
}

# ---------------------------------------------------------------------------
# show_directories
# ---------------------------------------------------------------------------

@test "show_directories outputs a directory layout summary" {
    run bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'
        export STACK_DIR='$TEST_TMPDIR/stack'
        export CONFIG_DIR='$TEST_TMPDIR/stack/config'
        export LOG_DIR='$TEST_TMPDIR/stack/logs'
        export BACKUP_DIR='$TEST_TMPDIR/stack/backups'
        export DIR_MODE='default'
        source '$REPO_DIR/lib/runtime.sh'
        source '$REPO_DIR/core/directories.sh'
        apply_directory_layout
        show_directories
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"Stack:"* ]]
    [[ "$output" == *"Media Root:"* ]]
    [[ "$output" == *"Downloads:"* ]]
}
