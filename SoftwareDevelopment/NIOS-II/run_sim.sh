#!/bin/bash
SOC_NAME="MusicPlayerPlatformDesign"
ELF="/mnt/d/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II/app/main.elf"
BSP_DIR="/mnt/d/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II/bsp"
SOPCINFO_DIR="$(dirname "/mnt/d/Escritorio/FPGA-MusicPlayer-HPS-NIOS/MusicPlayerQuartus22/MusicPlayerPlatformDesign.sopcinfo")"
MENTOR="$SOPCINFO_DIR/$SOC_NAME/testbench/mentor"
SUBMODULES="$SOPCINFO_DIR/$SOC_NAME/testbench/${SOC_NAME}_tb/simulation/submodules"
export PATH=$PATH:/mnt/c/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-mingw32/bin

to_win() { echo "$1" | sed 's|/mnt/\([a-z]\)/|\1:/|'; }

echo "============================================================"
echo " Nios II -- Run Simulation"
echo "============================================================"
echo ""

if [ ! -f "$ELF" ]; then
    echo "ERROR: $ELF not found. Run ./build.sh first."
    exit 1
fi

echo "[1/3] Copying ELF to mentor folder..."
mkdir -p "$MENTOR"
cp "$ELF" "$MENTOR/main.elf"
[ $? -ne 0 ] && echo "ERROR: Copy failed" && exit 1
echo "  Copied to: $MENTOR/main.elf"

echo ""
echo "[2/3] Reading RAM base address from bsp/system.h..."
RAM_BASE=$(grep "_BASE" "$BSP_DIR/system.h" | grep "RAM_" | awk '{print $3}' | head -1)
if [ -z "$RAM_BASE" ]; then
    echo "ERROR: Could not find RAM base in $BSP_DIR/system.h"
    exit 1
fi
echo "  RAM_BASE = $RAM_BASE"

echo ""
echo "[3/3] Converting ELF to HEX for ModelSim..."
elf2hex.exe --input="$(to_win "$MENTOR/main.elf")" \
        --output="$(to_win "$SUBMODULES/${SOC_NAME}_RAM.hex")" \
        --width=32 \
        --base=$RAM_BASE \
        --end=0x7ffff
[ $? -ne 0 ] && echo "ERROR: elf2hex conversion failed" && exit 1

echo ""
echo "============================================================"
echo " DONE! Now open ModelSim and run:"
echo "============================================================"
echo "   cd {$(to_win "$MENTOR")}"
echo "   do msim_setup.tcl"
echo "   add wave /${SOC_NAME}_tb/*"
echo "   ld_debug"
echo "   run 2.5ms"
echo "============================================================"
