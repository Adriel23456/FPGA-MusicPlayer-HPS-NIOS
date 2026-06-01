#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"

: "${QUARTUS_ROOTDIR:=/home/dadump/intelFPGA_lite/22.1std/quartus}"
: "${SOPC_KIT_NIOS2:=/home/dadump/intelFPGA_lite/22.1std/nios2eds}"

export QUARTUS_ROOTDIR
export SOPC_KIT_NIOS2

NIOS2_GNU_BIN="$SOPC_KIT_NIOS2/bin/gnu/H-x86_64-pc-linux-gnu/bin"
NIOS2_SDK_BIN="$SOPC_KIT_NIOS2/sdk2/bin"
NIOS2_EDS_BIN="$SOPC_KIT_NIOS2/bin"

if [ ! -x "$NIOS2_GNU_BIN/nios2-elf-gcc" ]; then
    echo "ERROR: nios2-elf-gcc not found at:"
    echo "  $NIOS2_GNU_BIN/nios2-elf-gcc"
    exit 1
fi

export PATH="$NIOS2_GNU_BIN:$NIOS2_SDK_BIN:$NIOS2_EDS_BIN:$PATH"

MAKE_TOOL_VARS=(
    "CROSS_COMPILE=nios2-elf-"
    "CC=nios2-elf-gcc -xc"
    "CXX=nios2-elf-gcc -xc++"
    "AS=nios2-elf-gcc"
    "AR=nios2-elf-ar"
    "LD=nios2-elf-g++"
    "NM=nios2-elf-nm"
    "OBJDUMP=nios2-elf-objdump"
    "OBJCOPY=nios2-elf-objcopy"
    "CFLAGS="
    "CXXFLAGS="
    "CPPFLAGS="
    "ASFLAGS="
    "LDFLAGS="
)

echo "============================================================"
echo " Building Nios II Application"
echo "============================================================"

# Patch Makefile to use -Os (size optimization) every build
if [ -f "$APP_DIR/Makefile" ]; then
    sed -i 's|APP_CFLAGS_OPTIMIZATION :=.*|APP_CFLAGS_OPTIMIZATION := -Os|' "$APP_DIR/Makefile"
    echo "[OK] Optimization set to -Os"
fi

if ! make -C "$APP_DIR" "${MAKE_TOOL_VARS[@]}"; then
    echo "ERROR: Build failed"
    exit 1
fi

echo ""
echo "Build successful!"
echo ""
echo "ELF:"
echo "  $APP_DIR/main.elf"
