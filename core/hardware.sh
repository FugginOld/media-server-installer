#!/usr/bin/env bash

########################################
# Hardware Detection
########################################

GPU_DEVICE="none"

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

echo "AMD GPU detected."

if [ -d /dev/dri ]; then
echo "AMD GPU device directory found: /dev/dri"
fi

;;

########################################
# No GPU
########################################

*)

echo "No compatible GPU detected."

;;

esac

echo ""

}

########################################
# Configure GPU devices for containers
########################################

configure_gpu_devices() {

case "${CAP_GPU:-none}" in

########################################
# Intel GPU
########################################

intel)

if [ -d /dev/dri ]; then
GPU_DEVICE="/dev/dri"
else
GPU_DEVICE="none"
fi

;;

########################################
# NVIDIA GPU
########################################

nvidia)

GPU_DEVICE="nvidia"

;;

########################################
# AMD GPU
########################################

amd)

if [ -d /dev/dri ]; then
GPU_DEVICE="/dev/dri"
else
GPU_DEVICE="none"
fi

;;

########################################
# No GPU
########################################

*)

GPU_DEVICE="none"

;;

esac

export GPU_DEVICE

echo "GPU device configuration: $GPU_DEVICE"

}

########################################
# Export functions
########################################

export -f detect_gpu
export -f configure_gpu_devices
