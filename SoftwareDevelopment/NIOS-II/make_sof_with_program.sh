#!/bin/bash
# ============================================================
#  make_sof_with_program.sh
#  Embeds the Nios II ELF into RAM_NIOS_II and rebuilds the .sof
#  so the program boots from on-chip RAM (no JTAG download).
#
#  Pipeline:
#    1) BSP mem_init_generate  -> correct RAM-relative HEX
#    2) copy HEX to project root (where the RAM IP looks for it)
#    3) quartus_cdb --update_mif -> ingest HEX into the fitted DB
#    4) quartus_asm             -> emit the .sof
# ============================================================
set -e

# ---- Paths ----
QUARTUS_PROJECT_DIR="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/MusicPlayerQuartus22"
BSP_DIR="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II/bsp"
ELF="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II/app/main.elf"

# ---- Names ----
PROJECT="MusicPlayerQuartus"                 # top-level Quartus project (.qpf)
QSYS_SYSTEM="MusicPlayerPlatformDesign"      # Platform Designer system name
RAM_NAME="RAM_NIOS_II"
HEX_NAME="${QSYS_SYSTEM}_${RAM_NAME}.hex"

# ---- Tool environment ----
export QUARTUS_ROOTDIR="/home/adriel/intelFPGA_lite/22.1std/quartus"
export SOPC_KIT_NIOS2="/home/adriel/intelFPGA_lite/22.1std/nios2eds"
export PATH="$PATH:$QUARTUS_ROOTDIR/bin:$SOPC_KIT_NIOS2/bin:$SOPC_KIT_NIOS2/bin/gnu/H-x86_64-pc-linux-gnu/bin"

if [ ! -f "$ELF" ]; then
    echo "ERROR: $ELF not found. Run ./build.sh first."
    exit 1
fi

echo "============================================================"
echo " 1) Generate RAM init HEX via the BSP (correct addressing)"
echo "============================================================"
make -C "$BSP_DIR" -f mem_init.mk mem_init_generate \
    ELF="$ELF" \
    QUARTUS_PROJECT_DIR="$QUARTUS_PROJECT_DIR"

echo "============================================================"
echo " 2) Install HEX into the project root"
echo "============================================================"
cp "$BSP_DIR/mem_init/${HEX_NAME}" "$QUARTUS_PROJECT_DIR/"
echo "    copied ${HEX_NAME}"

echo "============================================================"
echo " 3) Update RAM contents in the fitted DB"
echo "============================================================"
cd "$QUARTUS_PROJECT_DIR"
quartus_cdb "$PROJECT" --update_mif

echo "============================================================"
echo " 4) Re-assemble the .sof"
echo "============================================================"
quartus_asm "$PROJECT"

SOF_PATH="$QUARTUS_PROJECT_DIR/output_files/${PROJECT}.sof"
echo ""
echo "Done. Embedded .sof is at:"
ls -l "$SOF_PATH"
echo "Load it with Quartus Programmer (JTAG) -- the Nios boots automatically (no download.sh)."