#!/bin/bash

ELF="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II/app/main.elf"

export PATH="$PATH:/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin"
export QUARTUS_ROOTDIR="/home/adriel/intelFPGA_lite/22.1std/quartus"
export SOPC_KIT_NIOS2="/home/adriel/intelFPGA_lite/22.1std/nios2eds"

if [ ! -f "$ELF" ]; then
    echo "ERROR:"
    echo "  $ELF not found."
    echo "Run ./build.sh first."
    exit 1
fi

echo "============================================================"
echo " Downloading ELF"
echo "============================================================"

nios2-download -g "$ELF"

[ $? -ne 0 ] && echo "ERROR: Download failed" && exit 1

echo ""
echo "Download successful!"
