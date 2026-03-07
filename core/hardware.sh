#!/usr/bin/env bash

########################################
# Hardware Detection
#
# Detects GPU hardware and prepares
# Docker container configuration for
# hardware acceleration.
########################################

GPU_TYPE="none"
GPU_DEVICES=""

########################################
# Detect GPU hardware
########################################

detect_gpu() {

echo ""
echo "Detecting GPU hardware..."
echo ""

########################################
# Ensure lspci exists
########################################

if ! command -v lspci >/dev/null 2>&1; then
echo "pciutils not installed, skipping GPU detection."
return
fi

########################################
# NVIDIA GPU detection
########################################

if lspci | grep -qi nvidia; then

GPU_TYPE="nvidia"

########################################
# Intel GPU detection
########################################

elif lspci | grep -Ei "vga|display" | grep -qi intel; then

GPU_TYPE="intel"

########################################
# AMD GPU detection
########################################

elif lspci | grep -Ei "vga|display" | grep -qi amd; then

GPU_TYPE="amd"

########################################
# No GPU detected
########################################

else

GPU_TYPE="none"

fi

echo "Detected GPU type: $GPU_TYPE"

}

########################################
# Configure GPU devices for Docker
########################################

configure_gpu_devices() {

case "$GPU_TYPE" in

########################################
# Intel / AMD (VAAPI)
########################################

intel|amd)

GPU_DEVICES="
    devices:
      - /dev/dri:/dev/dri
"

;;

########################################
# NVIDIA GPU
########################################

nvidia)

GPU_DEVICES="
    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=compute,video,utility
"

;;

########################################
# No GPU
########################################

*)

GPU_DEVICES=""

;;

esac

}

########################################
# Install NVIDIA container runtime
########################################

install_nvidia_runtime() {

if [ "$GPU_TYPE" != "nvidia" ]; then
return
fi

echo ""
echo "Installing NVIDIA container toolkit..."
echo ""

if command -v apt >/dev/null 2>&1; then

apt update
apt install -y nvidia-container-toolkit

########################################
# Restart docker to enable runtime
########################################

if [ "$SERVICE_MANAGER" = "systemd" ]; then
systemctl restart docker
elif [ "$SERVICE_MANAGER" = "sysvinit" ]; then
service docker restart
fi

fi

}