detect_gpu() {

GPU_TYPE="none"

if command -v lspci >/dev/null 2>&1; then

if lspci | grep -qi nvidia; then
GPU_TYPE="nvidia"

elif lspci | grep -qi intel; then
GPU_TYPE="intel"

elif lspci | grep -qi amd; then
GPU_TYPE="amd"

fi

fi

echo "Detected GPU: $GPU_TYPE"

}

get_gpu_devices() {

case "$GPU_TYPE" in

intel|amd)

GPU_DEVICES="devices:
   - /dev/dri:/dev/dri"

;;

nvidia)

GPU_DEVICES="runtime: nvidia
  environment:
   - NVIDIA_VISIBLE_DEVICES=all
   - NVIDIA_DRIVER_CAPABILITIES=compute,video,utility"

;;

*)

GPU_DEVICES=""

;;

esac

}
