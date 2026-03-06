#!/usr/bin/env bash

########################################
# GPU Detection
########################################

GPU_TYPE="none"
GPU_DEVICES=""

detect_gpu() {

echo "Detecting GPU..."

if ! command -v lspci >/dev/null 2>&1; then
    echo "lspci not found, skipping GPU detection."
    return
fi

if lspci | grep -qi nvidia; then

GPU_TYPE="nvidia"

elif lspci | grep -Ei "vga|display" | grep -qi intel; then

GPU_TYPE="intel"

elif lspci | grep -Ei "vga|display" | grep -qi amd; then

GPU_TYPE="amd"

else

GPU_TYPE="none"

fi

echo "GPU detected: $GPU_TYPE"

}

########################################
# Configure Docker GPU Settings
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
# Install NVIDIA Runtime (if needed)
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
