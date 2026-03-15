#!/usr/bin/env bash

########################################
# Load runtime if not already loaded
########################################

if [ -z "${MEDIA_STACK_RUNTIME_LOADED:-}" ]; then
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export INSTALL_DIR="$SCRIPT_DIR"
source "$INSTALL_DIR/lib/runtime.sh"
fi

########################################
# Hardware Detection
########################################

GPU_TYPE="none"
GPU_DEVICES=""

########################################
# Detect GPU
########################################

detect_gpu() {

echo ""
echo "================================"
echo "Hardware Detection"
echo "================================"
echo ""

echo "Checking GPU availability..."

case "${CAP_GPU:-none}" in

########################################
# NVIDIA GPU
########################################

nvidia)

GPU_TYPE="nvidia"

echo "NVIDIA GPU detected."

if command -v nvidia-smi >/dev/null 2>&1; then
echo "nvidia-smi detected."
else
echo "Warning: NVIDIA GPU present but nvidia-smi not found."
fi

;;

########################################
# Intel GPU
########################################

intel)

GPU_TYPE="intel"

echo "Intel integrated GPU detected."

if [ -d /dev/dri ]; then
echo "Intel GPU device directory found: /dev/dri"
else
echo "Warning: Intel GPU detected but /dev/dri not available."
fi

;;

########################################
# AMD GPU
########################################

amd)

GPU_TYPE="amd"

echo "AMD GPU detected."

if [ -d /dev/dri ]; then
echo "AMD GPU device directory found: /dev/dri"
fi

;;

########################################
# No GPU
########################################

*)

GPU_TYPE="none"

echo "No compatible GPU detected."

;;

esac

echo ""

export GPU_TYPE

}

########################################
# Configure GPU devices for containers
########################################

configure_gpu_devices() {

case "$GPU_TYPE" in

########################################
# Intel / AMD GPU
########################################

intel|amd)

if [ -d /dev/dri ]; then

GPU_DEVICES=$(cat <<EOF
    devices:
      - /dev/dri:/dev/dri
EOF
)

else
GPU_DEVICES=""
fi

;;

########################################
# NVIDIA GPU
########################################

nvidia)

GPU_DEVICES=$(cat <<EOF
    deploy:
      resources:
        reservations:
          devices:
            - capabilities: [gpu]
EOF
)

;;

########################################
# No GPU
########################################

*)

GPU_DEVICES=""

;;

esac

export GPU_DEVICES

echo "GPU type: $GPU_TYPE"

}

########################################
# Export functions
########################################

export -f detect_gpu
export -f configure_gpu_devices