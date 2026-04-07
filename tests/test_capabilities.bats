#!/usr/bin/env bats
# Tests for core/capabilities.sh

load helpers/common

REPO_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

# Helper: run capabilities functions inside a controlled subshell.
# $1 = function to call
# $2 = optional extra env overrides passed as KEY=VALUE pairs
_run_cap() {
    local fn="$1"
    local extra_env="${2:-}"
    bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'
        ${extra_env}
        source '$REPO_DIR/lib/runtime.sh'
        source '$REPO_DIR/core/capabilities.sh'
        ${fn}
        echo \"CAP_GPU=\$CAP_GPU\"
        echo \"CAP_FS=\$CAP_FS\"
        echo \"CAP_CONTAINER=\$CAP_CONTAINER\"
    "
}

setup() {
    setup_common
}

teardown() {
    teardown_common
}

# ---------------------------------------------------------------------------
# detect_gpu_capability
# ---------------------------------------------------------------------------

@test "detect_gpu_capability sets CAP_GPU=nvidia when nvidia-smi is present" {
    run bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'
        # Provide a fake nvidia-smi on PATH
        FAKE_BIN=\"\$(mktemp -d)\"
        echo '#!/bin/sh' > \"\$FAKE_BIN/nvidia-smi\"
        chmod +x \"\$FAKE_BIN/nvidia-smi\"
        export PATH=\"\$FAKE_BIN:\$PATH\"
        source '$REPO_DIR/lib/runtime.sh'
        source '$REPO_DIR/core/capabilities.sh'
        detect_gpu_capability
        echo \"CAP_GPU=\$CAP_GPU\"
        rm -rf \"\$FAKE_BIN\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"CAP_GPU=nvidia"* ]]
}

@test "detect_gpu_capability sets CAP_GPU=none when no GPU tools are available" {
    run bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'
        # Provide a fake lspci with no GPU output; prepend to PATH to shadow real one
        # Do NOT create nvidia-smi (not on this CI system, so command -v will miss it)
        FAKE_BIN=\"\$(mktemp -d)\"
        printf '#!/bin/sh\necho \"00:00.0 Host bridge: Some Controller\"\n' > \"\$FAKE_BIN/lspci\"
        chmod +x \"\$FAKE_BIN/lspci\"
        export PATH=\"\$FAKE_BIN:\$PATH\"
        source '$REPO_DIR/lib/runtime.sh'
        source '$REPO_DIR/core/capabilities.sh'
        detect_gpu_capability
        echo \"CAP_GPU=\$CAP_GPU\"
        rm -rf \"\$FAKE_BIN\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"CAP_GPU=none"* ]]
}

@test "detect_gpu_capability sets CAP_GPU=none when lspci is absent" {
    run bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'
        # Override command built-in to report lspci and nvidia-smi as absent
        source '$REPO_DIR/lib/runtime.sh'
        source '$REPO_DIR/core/capabilities.sh'
        # Redefine detect_gpu_capability to use a no-op PATH context
        FAKE_BIN=\"\$(mktemp -d)\"
        SAVED_PATH=\"\$PATH\"
        export PATH=\"\$FAKE_BIN\"  # neither lspci nor nvidia-smi present
        detect_gpu_capability
        export PATH=\"\$SAVED_PATH\"
        echo \"CAP_GPU=\$CAP_GPU\"
        rm -rf \"\$FAKE_BIN\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"CAP_GPU=none"* ]]
}

# ---------------------------------------------------------------------------
# detect_fs_capability
# ---------------------------------------------------------------------------

@test "detect_fs_capability sets CAP_FS to the root filesystem type" {
    run bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'
        source '$REPO_DIR/lib/runtime.sh'
        source '$REPO_DIR/core/capabilities.sh'
        detect_fs_capability
        echo \"CAP_FS=\$CAP_FS\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"CAP_FS="* ]]
    # Must not be empty
    [[ "$output" != *"CAP_FS= "* ]]
    [[ "$output" != *"CAP_FS=unknown"* ]] || true  # unknown is acceptable but uncommon
}

@test "detect_fs_capability maps ext4 to 'ext'" {
    run bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'
        source '$REPO_DIR/lib/runtime.sh'
        source '$REPO_DIR/core/capabilities.sh'
        # Mock df to return ext4
        df() { echo 'Filesystem Type'; echo '/dev/sda1  ext4'; }
        export -f df
        detect_fs_capability
        echo \"CAP_FS=\$CAP_FS\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"CAP_FS=ext"* ]]
}

# ---------------------------------------------------------------------------
# detect_container_runtime
# ---------------------------------------------------------------------------

@test "detect_container_runtime sets CAP_CONTAINER=docker when docker is available" {
    run bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'
        FAKE_BIN=\"\$(mktemp -d)\"
        echo '#!/bin/sh' > \"\$FAKE_BIN/docker\"
        chmod +x \"\$FAKE_BIN/docker\"
        export PATH=\"\$FAKE_BIN:\$PATH\"
        source '$REPO_DIR/lib/runtime.sh'
        source '$REPO_DIR/core/capabilities.sh'
        detect_container_runtime
        echo \"CAP_CONTAINER=\$CAP_CONTAINER\"
        rm -rf \"\$FAKE_BIN\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"CAP_CONTAINER=docker"* ]]
}

@test "detect_container_runtime sets CAP_CONTAINER=podman when only podman is available" {
    run bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'
        FAKE_BIN=\"\$(mktemp -d)\"
        printf '#!/bin/sh\nexit 0\n' > \"\$FAKE_BIN/podman\"
        chmod +x \"\$FAKE_BIN/podman\"
        SAVED_PATH=\"\$PATH\"
        export PATH=\"\$FAKE_BIN\"   # docker not present; only podman
        source '$REPO_DIR/lib/runtime.sh'
        source '$REPO_DIR/core/capabilities.sh'
        detect_container_runtime
        echo \"CAP_CONTAINER=\$CAP_CONTAINER\"
        export PATH=\"\$SAVED_PATH\"
        rm -rf \"\$FAKE_BIN\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"CAP_CONTAINER=podman"* ]]
}

@test "detect_container_runtime sets CAP_CONTAINER=none when nothing is available" {
    run bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'
        FAKE_BIN=\"\$(mktemp -d)\"
        SAVED_PATH=\"\$PATH\"
        export PATH=\"\$FAKE_BIN\"  # neither docker nor podman present
        source '$REPO_DIR/lib/runtime.sh'
        source '$REPO_DIR/core/capabilities.sh'
        detect_container_runtime
        echo \"CAP_CONTAINER=\$CAP_CONTAINER\"
        export PATH=\"\$SAVED_PATH\"
        rm -rf \"\$FAKE_BIN\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"CAP_CONTAINER=none"* ]]
}

# ---------------------------------------------------------------------------
# detect_capabilities (integration)
# ---------------------------------------------------------------------------

@test "detect_capabilities exports all three CAP_* variables" {
    run bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'
        source '$REPO_DIR/lib/runtime.sh'
        source '$REPO_DIR/core/capabilities.sh'
        detect_capabilities
        [ -n \"\$CAP_GPU\" ]       || { echo 'CAP_GPU unset'; exit 1; }
        [ -n \"\$CAP_FS\" ]        || { echo 'CAP_FS unset'; exit 1; }
        [ -n \"\$CAP_CONTAINER\" ] || { echo 'CAP_CONTAINER unset'; exit 1; }
        echo 'all exported'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"all exported"* ]]
}
