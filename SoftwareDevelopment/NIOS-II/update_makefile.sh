#!/bin/bash

set -e

SW_ROOT="$(cd "$(dirname "$0")" && pwd)"

APP_DIR="$SW_ROOT/app"
BSP_DIR="$SW_ROOT/bsp"

: "${QUARTUS_ROOTDIR:=/home/dadump/intelFPGA_lite/22.1std/quartus}"
: "${SOPC_KIT_NIOS2:=/home/dadump/intelFPGA_lite/22.1std/nios2eds}"

export QUARTUS_ROOTDIR
export SOPC_KIT_NIOS2
export PATH="$PATH:$SOPC_KIT_NIOS2/bin/gnu/H-x86_64-pc-linux-gnu/bin"

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
    --inc-rdir "$APP_DIR/include"

echo ""
echo "Makefile updated successfully!"
echo ""
echo "Next step:"
echo "  ./build.sh"
