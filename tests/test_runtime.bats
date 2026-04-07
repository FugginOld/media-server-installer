#!/usr/bin/env bats
# Tests for lib/runtime.sh

load helpers/common

REPO_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
    setup_common
    load_runtime
}

teardown() {
    teardown_common
}

# ---------------------------------------------------------------------------
# Logging functions
# ---------------------------------------------------------------------------

@test "log outputs [INFO] prefix to stdout" {
    run log "hello world"
    [ "$status" -eq 0 ]
    [ "$output" = "[INFO] hello world" ]
}

@test "warn outputs [WARN] prefix to stderr" {
    # Run in a subshell, redirect stderr to stdout so run can capture it
    run bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        source '$REPO_DIR/lib/runtime.sh'
        warn 'test warning' 2>&1
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"[WARN] test warning"* ]]
}

@test "error outputs [ERROR] prefix to stderr" {
    run bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        source '$REPO_DIR/lib/runtime.sh'
        error 'test error' 2>&1
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"[ERROR] test error"* ]]
}

@test "die outputs [ERROR] prefix and exits with status 1" {
    run bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        source '$REPO_DIR/lib/runtime.sh'
        die 'fatal' 2>&1
    "
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR] fatal"* ]]
}

# ---------------------------------------------------------------------------
# INSTALL_DIR and derived directories
# ---------------------------------------------------------------------------

@test "INSTALL_DIR is exported and non-empty" {
    [ -n "$INSTALL_DIR" ]
}

@test "CORE_DIR points to existing directory" {
    [ -d "$CORE_DIR" ]
}

@test "LIB_DIR points to existing directory" {
    [ -d "$LIB_DIR" ]
}

@test "SCRIPT_DIR points to existing directory" {
    [ -d "$SCRIPT_DIR" ]
}

@test "PLUGIN_DIR points to existing directory" {
    [ -d "$PLUGIN_DIR" ]
}

@test "TEMPLATE_DIR is set" {
    [ -n "$TEMPLATE_DIR" ]
}

@test "MEDIA_STACK_RUNTIME_LOADED is set after sourcing" {
    [ -n "$MEDIA_STACK_RUNTIME_LOADED" ]
}

# ---------------------------------------------------------------------------
# detect_host_ip
# ---------------------------------------------------------------------------

@test "detect_host_ip sets HOST_IP to non-empty value" {
    unset HOST_IP
    detect_host_ip
    [ -n "$HOST_IP" ]
}

@test "detect_host_ip respects a pre-set HOST_IP" {
    export HOST_IP="10.0.0.42"
    detect_host_ip
    [ "$HOST_IP" = "10.0.0.42" ]
}

@test "detect_host_ip falls back to 127.0.0.1 when ip and hostname -I fail" {
    run bash -c "
        # Prepend fake ip/hostname to PATH (keep rest of PATH intact)
        FAKE_BIN=\"\$(mktemp -d)\"
        printf '#!/bin/sh\nexit 1\n' > \"\$FAKE_BIN/ip\"
        printf '#!/bin/sh\necho \"\"\n' > \"\$FAKE_BIN/hostname\"
        chmod +x \"\$FAKE_BIN/ip\" \"\$FAKE_BIN/hostname\"
        export PATH=\"\$FAKE_BIN:\$PATH\"
        unset MEDIA_STACK_RUNTIME_LOADED
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        source '$REPO_DIR/lib/runtime.sh'
        unset HOST_IP
        detect_host_ip
        echo \"\$HOST_IP\"
        rm -rf \"\$FAKE_BIN\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"127.0.0.1"* ]]
}

# ---------------------------------------------------------------------------
# Double-load guard
# ---------------------------------------------------------------------------

@test "sourcing runtime.sh twice is idempotent" {
    # Already loaded in setup; source again — should silently return
    source "$REPO_DIR/lib/runtime.sh"
    [ -n "$MEDIA_STACK_RUNTIME_LOADED" ]
}
