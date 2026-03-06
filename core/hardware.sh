#!/usr/bin/env bash

########################################
# GPU Detection
########################################

GPU_TYPE="none"
GPU_DEVICES=""

detect_gpu() {

echo "Detecting GPU..."

if ! command -v lspci >/dev/null 2>&1; then
    echo "pciutils not installed, skipping GPU detection."
    return
fi

########################################
# NVIDIA detection
########################################

if lspci | grep -qi nvidia; then

    GPU_TYPE="nvidia"

########################################
# Intel detection
########################################

elif lspci | grep -Ei "vga|display" | grep -qi intel; then

    GPU_TYPE="intel"

########################################
# AMD detection
########################################

elif lspci | grep -Ei "vga|display" | grep -qi amd; then

    GPU_TYPE="amd"

else

    GPU_TYPE="none"

fi

echo "Detected GPU: $GPU_TYPE"

}

########################################
# Configure GPU for Docker containers
########################################

configure_gpu_devices() {

case "$GPU_TYPE" in

intel|amd)

GPU_DEVICES="
    devices:
      - /dev/dri:/dev/dri
"

;;

nvidia)

GPU_DEVICES="
    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=compute,video,utility
"

;;

*)

GPU_DEVICES=""

;;

esac

}

########################################
# Install NVIDIA runtime if needed
########################################

install_nvidia_runtime() {

if [ "$GPU_TYPE" != "nvidia" ]; then
    return
fi

echo "Installing NVIDIA container toolkit..."

apt update

apt install -y nvidia-container-toolkit

systemctl restart docker

}