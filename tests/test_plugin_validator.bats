#!/usr/bin/env bats
# Integration tests for scripts/plugin-validator.sh

load helpers/common

REPO_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
    setup_common
    FAKE_PLUGIN_DIR="$TEST_TMPDIR/plugins"
    mkdir -p "$FAKE_PLUGIN_DIR"
}

teardown() {
    teardown_common
}

# Helper: run plugin-validator.sh against a custom plugin directory.
_run_validator() {
    bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$FAKE_PLUGIN_DIR'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'
        source '$REPO_DIR/lib/runtime.sh'
        bash '$REPO_DIR/scripts/plugin-validator.sh'
    "
}

# ---------------------------------------------------------------------------
# check_field helper (tested indirectly)
# ---------------------------------------------------------------------------

@test "plugin-validator passes for a fully valid plugin" {
    make_fake_plugin "$FAKE_PLUGIN_DIR" "myplugin"
    run _run_validator
    [ "$status" -eq 0 ]
    [[ "$output" == *"All plugins validated successfully"* ]]
}

@test "plugin-validator fails when PLUGIN_NAME is missing" {
    make_fake_plugin "$FAKE_PLUGIN_DIR" "badname" "PLUGIN_NAME"
    run _run_validator
    [ "$status" -ne 0 ]
    [[ "$output" == *"Missing PLUGIN_NAME"* ]]
}

@test "plugin-validator fails when PLUGIN_CATEGORY is missing" {
    make_fake_plugin "$FAKE_PLUGIN_DIR" "badcat" "PLUGIN_CATEGORY"
    run _run_validator
    [ "$status" -ne 0 ]
    [[ "$output" == *"Missing PLUGIN_CATEGORY"* ]]
}

@test "plugin-validator fails when install_service function is missing" {
    make_fake_plugin "$FAKE_PLUGIN_DIR" "nofunc" "" "install_service"
    run _run_validator
    [ "$status" -ne 0 ]
    [[ "$output" == *"Missing function: install_service()"* ]]
}

@test "plugin-validator exits with error when plugin directory is empty" {
    # No plugins created — COUNT stays 0
    run _run_validator
    [ "$status" -ne 0 ]
    [[ "$output" == *"No plugins discovered"* ]]
}

@test "plugin-validator counts plugins correctly" {
    make_fake_plugin "$FAKE_PLUGIN_DIR" "plugin1"
    make_fake_plugin "$FAKE_PLUGIN_DIR" "plugin2"
    make_fake_plugin "$FAKE_PLUGIN_DIR" "plugin3"
    run _run_validator
    [ "$status" -eq 0 ]
    [[ "$output" == *"Plugins checked: 3"* ]]
}

@test "plugin-validator excludes _template directory from count" {
    make_fake_plugin "$FAKE_PLUGIN_DIR/_template" "template_plugin"
    make_fake_plugin "$FAKE_PLUGIN_DIR" "realplugin"
    run _run_validator
    [ "$status" -eq 0 ]
    [[ "$output" == *"Plugins checked: 1"* ]]
}

@test "plugin-validator reports multiple errors in a single run" {
    # One plugin missing both PLUGIN_NAME and install_service
    mkdir -p "$FAKE_PLUGIN_DIR"
    cat > "$FAKE_PLUGIN_DIR/broken.sh" <<'EOF'
#!/usr/bin/env bash
PLUGIN_CATEGORY="test"
# PLUGIN_NAME intentionally omitted
# install_service intentionally omitted
EOF
    run _run_validator
    [ "$status" -ne 0 ]
    [[ "$output" == *"Missing PLUGIN_NAME"* ]]
    [[ "$output" == *"Missing function: install_service()"* ]]
}
