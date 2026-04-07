#!/usr/bin/env bats
# Tests for core/hardware.sh

load helpers/common

REPO_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

# Source hardware.sh in a fresh subshell for each test to avoid state leakage.
# We pass CAP_GPU via the environment.
_run_hardware() {
    local cap_gpu="${1:-}"
    local fn="${2:-}"
    shift 2
    bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'
        export CAP_GPU='${cap_gpu}'
        source '$REPO_DIR/lib/runtime.sh'
        source '$REPO_DIR/core/hardware.sh'
        ${fn} \"\$@\"
        echo \"GPU_TYPE=\$GPU_TYPE\"
        echo \"GPU_DEVICES=\$GPU_DEVICES\"
    " -- "$@"
}

setup() {
    setup_common
}

teardown() {
    teardown_common
}

# ---------------------------------------------------------------------------
# detect_gpu
# ---------------------------------------------------------------------------

@test "detect_gpu sets GPU_TYPE=none when CAP_GPU is unset or 'none'" {
    run bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'
        unset CAP_GPU
        source '$REPO_DIR/lib/runtime.sh'
        source '$REPO_DIR/core/hardware.sh'
        detect_gpu
        echo \"GPU_TYPE=\$GPU_TYPE\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"GPU_TYPE=none"* ]]
}

@test "detect_gpu sets GPU_TYPE=nvidia when CAP_GPU=nvidia" {
    run bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'
        export CAP_GPU=nvidia
        # Shadow nvidia-smi so we don't need real hardware
        nvidia-smi() { return 0; }
        export -f nvidia-smi
        source '$REPO_DIR/lib/runtime.sh'
        source '$REPO_DIR/core/hardware.sh'
        detect_gpu
        echo \"GPU_TYPE=\$GPU_TYPE\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"GPU_TYPE=nvidia"* ]]
}

@test "detect_gpu sets GPU_TYPE=intel when CAP_GPU=intel" {
    run bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'
        export CAP_GPU=intel
        source '$REPO_DIR/lib/runtime.sh'
        source '$REPO_DIR/core/hardware.sh'
        detect_gpu
        echo \"GPU_TYPE=\$GPU_TYPE\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"GPU_TYPE=intel"* ]]
}

@test "detect_gpu sets GPU_TYPE=amd when CAP_GPU=amd" {
    run bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'
        export CAP_GPU=amd
        source '$REPO_DIR/lib/runtime.sh'
        source '$REPO_DIR/core/hardware.sh'
        detect_gpu
        echo \"GPU_TYPE=\$GPU_TYPE\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"GPU_TYPE=amd"* ]]
}

# ---------------------------------------------------------------------------
# configure_gpu_devices
# ---------------------------------------------------------------------------

@test "configure_gpu_devices sets empty GPU_DEVICES for GPU_TYPE=none" {
    run bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'
        export GPU_TYPE=none
        source '$REPO_DIR/lib/runtime.sh'
        source '$REPO_DIR/core/hardware.sh'
        configure_gpu_devices
        echo \"GPU_DEVICES='\$GPU_DEVICES'\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"GPU_DEVICES=''"* ]]
}

@test "configure_gpu_devices sets nvidia deploy section for GPU_TYPE=nvidia" {
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
        source '$REPO_DIR/core/hardware.sh'
        GPU_TYPE=nvidia
        configure_gpu_devices
        echo \"\$GPU_DEVICES\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"capabilities: [gpu]"* ]]
}

@test "configure_gpu_devices sets /dev/dri devices for intel when /dev/dri exists" {
    skip_if_no_dri() { [ -d /dev/dri ] || skip "/dev/dri not available on this host"; }
    skip_if_no_dri
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
        source '$REPO_DIR/core/hardware.sh'
        GPU_TYPE=intel
        configure_gpu_devices
        echo \"\$GPU_DEVICES\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"/dev/dri"* ]]
}

@test "configure_gpu_devices returns empty GPU_DEVICES for intel when /dev/dri is absent" {
    [ -d /dev/dri ] && skip "/dev/dri present; skipping no-dri test"
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
        source '$REPO_DIR/core/hardware.sh'
        GPU_TYPE=intel
        configure_gpu_devices
        echo \"DEVICES='\$GPU_DEVICES'\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"DEVICES=''"* ]]
}
