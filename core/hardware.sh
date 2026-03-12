########################################
#Hardware Detection
########################################

GPU_TYPE="none"
GPU_DEVICES=""

########################################
#Detect GPU hardware
########################################

detect_gpu() {

echo ""
echo "Detecting GPU hardware..."
echo ""

########################################
#Ensure lspci exists
########################################

if ! command -v lspci >/dev/null 2>&1; then
echo "pciutils not installed, skipping GPU detection."
GPU_TYPE="none"
return
fi

########################################
#NVIDIA detection
########################################

if lspci | grep -qi nvidia; then
GPU_TYPE="nvidia"

########################################
#Intel detection
########################################

elif lspci | grep -Ei "vga|3d|display" | grep -qi intel; then
GPU_TYPE="intel"

########################################
#AMD detection
########################################

elif lspci | grep -Ei "vga|3d|display" | grep -qi amd; then
GPU_TYPE="amd"

########################################
#No GPU detected
########################################

else
GPU_TYPE="none"
fi

echo "Detected GPU type: $GPU_TYPE"

}

########################################
#Configure Docker GPU devices
########################################

configure_gpu_devices() {

case "$GPU_TYPE" in

########################################
#Intel / AMD (VAAPI)
########################################

intel|amd)

GPU_DEVICES="
    devices:
      - /dev/dri:/dev/dri
"

;;

########################################
#NVIDIA GPU
########################################

nvidia)

GPU_DEVICES="
    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=compute,video,utility
"

install_nvidia_runtime
;;

########################################
#No GPU
########################################

*)

GPU_DEVICES=""

;;

esac

}

########################################
#Install NVIDIA container runtime
########################################

install_nvidia_runtime() {

if [ "$GPU_TYPE" != "nvidia" ]; then
return
fi

echo ""
echo "Installing NVIDIA container toolkit..."
echo ""

########################################
#Debian / Ubuntu systems
########################################

if command -v apt >/dev/null 2>&1; then

apt update
apt install -y nvidia-container-toolkit

########################################
#Restart Docker
########################################

if command -v systemctl >/dev/null 2>&1; then
systemctl restart docker
else
service docker restart
fi

fi

}

########################################
#Export functions
########################################

export -f detect_gpu
export -f configure_gpu_devices
