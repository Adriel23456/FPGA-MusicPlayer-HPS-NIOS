#!/bin/bash

set -e

SW_ROOT="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II"

APP_DIR="$SW_ROOT/app"
BSP_DIR="$SW_ROOT/bsp"

export PATH="$PATH:/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin"
export QUARTUS_ROOTDIR="/home/adriel/intelFPGA_lite/22.1std/quartus"
export SOPC_KIT_NIOS2="/home/adriel/intelFPGA_lite/22.1std/nios2eds"

echo "============================================================"
echo " Updating Application Makefile"
echo "============================================================"
echo ""

if ! command -v nios2-app-generate-makefile >/dev/null 2>&1; then
    echo "ERROR:"
    echo "  nios2-app-generate-makefile not found in PATH"
    exit 1
fi

SRCS=()

while IFS= read -r -d '' f; do
    SRCS+=("$f")
done < <(find "$APP_DIR" -type f -name "*.c" -print0)

if [ ${#SRCS[@]} -eq 0 ]; then
    echo "ERROR:"
    echo "  No .c source files found."
    exit 1
fi

echo "Sources found:"
for f in "${SRCS[@]}"; do
    echo "  $f"
done

echo ""
echo "Generating Makefile..."
echo ""

nios2-app-generate-makefile \
    --bsp-dir "$BSP_DIR" \
    --app-dir "$APP_DIR" \
    --elf-name main.elf \
    --src-files "${SRCS[@]}" \
    --inc-rdir "$APP_DIR/include" \
    --set APP_LDFLAGS_USER "-Wl,--defsym,__alt_stack_pointer=0xE000"

echo ""
echo "Makefile updated successfully!"
echo ""
echo "Next step:"
echo "  ./build.sh"
