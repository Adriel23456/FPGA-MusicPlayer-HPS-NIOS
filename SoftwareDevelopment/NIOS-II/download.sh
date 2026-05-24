#!/bin/bash
ELF="/mnt/d/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II/app/main.elf"
export PATH=$PATH:/mnt/c/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-mingw32/bin

if [ ! -f "$ELF" ]; then
    echo "ERROR: $ELF not found. Run ./build.sh first."
    exit 1
fi

echo "=== Downloading ELF to FPGA ==="
nios2-download -g "$ELF"
[ $? -ne 0 ] && echo "ERROR: Download failed. Is the FPGA programmed?" && exit 1
echo "Download successful! Run ./terminal.sh to see output."
