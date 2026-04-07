#!/usr/bin/env bash
# Shared test helpers for media-server-installer test suite

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# setup_common — create a temporary, isolated test environment.
# Call from bats setup().
setup_common() {
    TEST_TMPDIR="$(mktemp -d)"
    export TEST_TMPDIR

    export INSTALL_DIR="$REPO_DIR"
    export STACK_DIR="$TEST_TMPDIR/stack"
    export CONFIG_DIR="$STACK_DIR/config"
    export LOG_DIR="$STACK_DIR/logs"
    export BACKUP_DIR="$STACK_DIR/backups"

    export SERVICE_REGISTRY="$STACK_DIR/services.json"
    export PORT_REGISTRY="$STACK_DIR/ports.json"

    export MEDIA_PATH="/media"
    export MOVIES_PATH="/media/movies"
    export TV_PATH="/media/tv"
    export DOWNLOADS_PATH="/downloads"

    export HOST_IP="192.168.1.100"
    export PUID="1000"
    export PGID="1000"
    export TIMEZONE="UTC"

    mkdir -p "$STACK_DIR" "$CONFIG_DIR" "$LOG_DIR" "$BACKUP_DIR"
}

# teardown_common — remove the temporary test environment.
# Call from bats teardown().
teardown_common() {
    [[ -n "${TEST_TMPDIR:-}" && "$TEST_TMPDIR" == /tmp/* ]] && rm -rf "$TEST_TMPDIR"
}

# load_runtime — source runtime.sh fresh (clears the guard first).
load_runtime() {
    unset MEDIA_STACK_RUNTIME_LOADED
    # shellcheck disable=SC1090
    source "$REPO_DIR/lib/runtime.sh"
}

# load_module <relative-path> — source a module after pre-populating the
# variables that runtime.sh would have set, so the module skips the runtime
# guard without needing to re-source runtime.sh.
load_module() {
    local rel_path="$1"
    export MEDIA_STACK_RUNTIME_LOADED=1
    export CORE_DIR="$REPO_DIR/core"
    export LIB_DIR="$REPO_DIR/lib"
    export SCRIPT_DIR="$REPO_DIR/scripts"
    export PLUGIN_DIR="$REPO_DIR/plugins"
    export TEMPLATE_DIR="$REPO_DIR/templates"
    # shellcheck disable=SC1090
    source "$REPO_DIR/$rel_path"
}

# make_fake_plugin <dir> <name> [missing_field] [missing_func]
# Creates a minimal valid plugin, optionally omitting a field or function.
make_fake_plugin() {
    local dir="$1"
    local name="$2"
    local missing_field="${3:-}"
    local missing_func="${4:-}"

    mkdir -p "$dir"
    local file="$dir/${name}.sh"

    {
        echo "#!/usr/bin/env bash"
        [[ "$missing_field" != "PLUGIN_NAME" ]]     && echo "PLUGIN_NAME=\"$name\""
        [[ "$missing_field" != "PLUGIN_CATEGORY" ]] && echo "PLUGIN_CATEGORY=\"test\""
        if [[ "$missing_func" != "install_service" ]]; then
            echo "install_service() { echo 'install'; }"
        fi
    } > "$file"
    chmod +x "$file"
}
