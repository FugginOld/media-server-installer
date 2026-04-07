#!/usr/bin/env bats
# Tests for lib/plugins.sh

load helpers/common

REPO_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
    setup_common
    # Create fake plugins BEFORE load_runtime (which would reset PLUGIN_DIR)
    FAKE_PLUGIN_DIR="$TEST_TMPDIR/plugins"
    mkdir -p "$FAKE_PLUGIN_DIR/media" "$FAKE_PLUGIN_DIR/_template"

    # Valid plugin: alpha
    cat > "$FAKE_PLUGIN_DIR/media/alpha.sh" <<'EOF'
#!/usr/bin/env bash
PLUGIN_NAME="alpha"
PLUGIN_CATEGORY="media"
PLUGIN_DEPENDS=()
PLUGIN_PORT="8001"
PLUGIN_DASHBOARD=false
install_service() { echo "installing alpha"; }
EOF

    # Valid plugin: beta (no port)
    cat > "$FAKE_PLUGIN_DIR/media/beta.sh" <<'EOF'
#!/usr/bin/env bash
PLUGIN_NAME="beta"
PLUGIN_CATEGORY="downloads"
PLUGIN_DEPENDS=("alpha")
PLUGIN_PORT=""
PLUGIN_DASHBOARD=true
install_service() { echo "installing beta"; }
EOF

    # Template (should be excluded from discovery)
    cat > "$FAKE_PLUGIN_DIR/_template/example.sh" <<'EOF'
#!/usr/bin/env bash
PLUGIN_NAME="example"
PLUGIN_CATEGORY="system"
install_service() { echo "template"; }
EOF

    load_runtime

    # Override PLUGIN_DIR AFTER load_runtime (which resets it to the real plugins dir)
    export PLUGIN_DIR="$FAKE_PLUGIN_DIR"

    # shellcheck disable=SC1090
    source "$REPO_DIR/lib/plugins.sh"
}

teardown() {
    teardown_common
}

# ---------------------------------------------------------------------------
# discover_plugins
# ---------------------------------------------------------------------------

@test "discover_plugins finds .sh files in plugin directory" {
    run discover_plugins
    [ "$status" -eq 0 ]
    [[ "$output" == *"alpha.sh"* ]]
    [[ "$output" == *"beta.sh"* ]]
}

@test "discover_plugins excludes _template directory" {
    run discover_plugins
    [ "$status" -eq 0 ]
    [[ "$output" != *"_template"* ]]
}

@test "discover_plugins lists exactly the expected plugin count" {
    run bash -c "
        export PLUGIN_DIR='$FAKE_PLUGIN_DIR'
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'
        source '$REPO_DIR/lib/runtime.sh'
        source '$REPO_DIR/lib/plugins.sh'
        discover_plugins | wc -l
    "
    [ "$status" -eq 0 ]
    [ "$output" -eq 2 ]
}

# ---------------------------------------------------------------------------
# load_plugins — note: associative arrays are not exported to subshells,
# so these tests call load_plugins directly and check arrays in the same shell.
# ---------------------------------------------------------------------------

@test "load_plugins populates PLUGIN_PATHS for discovered plugins" {
    load_plugins
    [ -n "${PLUGIN_PATHS[alpha]:-}" ]
    [ -n "${PLUGIN_PATHS[beta]:-}" ]
}

@test "load_plugins records correct path for alpha plugin" {
    load_plugins
    [[ "${PLUGIN_PATHS[alpha]}" == *"alpha.sh" ]]
}

@test "load_plugins does not include template plugin" {
    load_plugins
    [ -z "${PLUGIN_PATHS[example]:-}" ]
}

# ---------------------------------------------------------------------------
# get_plugin_path — called directly (associative array not subshell-safe)
# ---------------------------------------------------------------------------

@test "get_plugin_path returns path for known plugin" {
    load_plugins
    result="$(get_plugin_path "alpha")"
    [[ "$result" == *"alpha.sh"* ]]
}

@test "get_plugin_path returns empty string for unknown plugin" {
    load_plugins
    result="$(get_plugin_path "nonexistent")"
    [ "$result" = "" ]
}

# ---------------------------------------------------------------------------
# get_plugin_category
# ---------------------------------------------------------------------------

@test "get_plugin_category returns correct category for alpha" {
    load_plugins
    result="$(get_plugin_category "alpha")"
    [ "$result" = "media" ]
}

@test "get_plugin_category returns correct category for beta" {
    load_plugins
    result="$(get_plugin_category "beta")"
    [ "$result" = "downloads" ]
}

@test "get_plugin_category returns Misc for unknown plugin" {
    load_plugins
    result="$(get_plugin_category "nonexistent")"
    [ "$result" = "Misc" ]
}

# ---------------------------------------------------------------------------
# get_plugin_dependencies
# ---------------------------------------------------------------------------

@test "get_plugin_dependencies returns empty for plugin with no deps" {
    load_plugins
    result="$(get_plugin_dependencies "alpha")"
    [ "$result" = "" ]
}

@test "get_plugin_dependencies returns dependency list for beta" {
    load_plugins
    result="$(get_plugin_dependencies "beta")"
    [[ "$result" == *"alpha"* ]]
}

# ---------------------------------------------------------------------------
# get_plugin_port
# ---------------------------------------------------------------------------

@test "get_plugin_port returns port number for alpha" {
    load_plugins
    result="$(get_plugin_port "alpha")"
    [ "$result" = "8001" ]
}

@test "get_plugin_port returns empty string for plugin without a port" {
    load_plugins
    result="$(get_plugin_port "beta")"
    [ "$result" = "" ]
}

@test "get_plugin_port returns empty string for unknown plugin" {
    load_plugins
    result="$(get_plugin_port "nonexistent")"
    [ "$result" = "" ]
}

