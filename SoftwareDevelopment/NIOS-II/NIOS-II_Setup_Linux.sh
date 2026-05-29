#!/bin/bash
# ============================================================
# NIOS-II_Setup_Linux.sh
# Native Linux version (NO WSL / NO .exe)
# Run ONCE from inside the Nios II shell.
# ============================================================

echo "============================================================"
echo " Nios II Project Initializer (Linux Native)"
echo "============================================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================
# Auto-detect Quartus / Nios II installation
# ============================================================

QUARTUS_ROOT=""
NIOS_ROOT=""
GCC_PATH_DEFAULT=""

SEARCH_DIRS=(
    "$HOME/intelFPGA_lite"
    "$HOME/intelFPGA"
    "/intelFPGA_lite"
    "/intelFPGA"
    "/opt/intelFPGA_lite"
    "/opt/intelFPGA"
)

VERSIONS=(
    "22.1std"
    "22.1"
    "21.1std"
    "21.1"
    "20.1std"
    "20.1"
)

for d in "${SEARCH_DIRS[@]}"; do
    for v in "${VERSIONS[@]}"; do

        GCC_CANDIDATE="$d/$v/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin"

        if [ -d "$GCC_CANDIDATE" ]; then
            GCC_PATH_DEFAULT="$GCC_CANDIDATE"
            QUARTUS_ROOT="$d/$v/quartus"
            NIOS_ROOT="$d/$v/nios2eds"
            break 2
        fi
    done
done

if [ -z "$GCC_PATH_DEFAULT" ]; then
    echo "ERROR: Could not auto-detect Nios II installation."
    exit 1
fi

# ============================================================
# Ask user for paths
# ============================================================

echo "Enter FULL path to .sopcinfo file:"
read -rp "SOPCINFO path: " SOPCINFO

if [ ! -f "$SOPCINFO" ]; then
    echo "ERROR: File not found:"
    echo "  $SOPCINFO"
    exit 1
fi

echo ""
echo "Enter FULL path to software root:"
read -rp "Software root: " SW_ROOT

echo ""
echo "Enter CPU component name:"
read -rp "CPU name [CPU_NIOS_II]: " CPU_NAME

if [ -z "$CPU_NAME" ]; then
    CPU_NAME="CPU_NIOS_II"
fi

echo ""
echo "Detected GCC path:"
echo "  $GCC_PATH_DEFAULT"
echo ""

read -rp "Use this GCC path? [Y/n]: " GCC_CONFIRM

if [[ "${GCC_CONFIRM,,}" == "n" ]]; then
    read -rp "Enter GCC path manually: " GCC_PATH
else
    GCC_PATH="$GCC_PATH_DEFAULT"
fi

SOC_NAME="$(basename "$SOPCINFO" .sopcinfo)"
SOPCINFO_DIR="$(dirname "$SOPCINFO")"

# ============================================================
# Confirm
# ============================================================

echo ""
echo "============================================================"
echo " Confirm Settings"
echo "============================================================"
echo " SOPCINFO     : $SOPCINFO"
echo " SOPCINFO DIR : $SOPCINFO_DIR"
echo " SW ROOT      : $SW_ROOT"
echo " CPU NAME     : $CPU_NAME"
echo " GCC PATH     : $GCC_PATH"
echo " QUARTUS      : $QUARTUS_ROOT"
echo " NIOS2EDS     : $NIOS_ROOT"
echo " SOC NAME     : $SOC_NAME"
echo "============================================================"
echo ""

read -rp "Continue? [Y/n]: " CONFIRM

if [[ "${CONFIRM,,}" == "n" ]]; then
    echo "Aborted."
    exit 1
fi

# ============================================================
# Create folders
# ============================================================

mkdir -p "$SW_ROOT/app/src"
mkdir -p "$SW_ROOT/app/lib"
mkdir -p "$SW_ROOT/app/include"

EXISTING_C=$(find "$SW_ROOT/app" -name "*.c" 2>/dev/null | head -1)

if [ -z "$EXISTING_C" ]; then

cat > "$SW_ROOT/app/main.c" << 'EOF'
#include <sys/alt_stdio.h>

int main(void)
{
    alt_putstr("Hello from Nios II!\n");

    while (1);

    return 0;
}
EOF

    echo "[OK] Created default main.c"

else

    echo "[OK] Existing sources detected:"
    find "$SW_ROOT/app" -name "*.c"

fi

# ============================================================
# new_project.sh
# ============================================================

cat > "$SCRIPT_DIR/new_project.sh" << 'EOF'
#!/bin/bash

SOPCINFO="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/MusicPlayerQuartus22/MusicPlayerPlatformDesign.sopcinfo"
SW_ROOT="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II"
CPU_NAME="CPU_NIOS_II"

BSP_DIR="$SW_ROOT/bsp"
APP_DIR="$SW_ROOT/app"

export PATH="$PATH:/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin"
export QUARTUS_ROOTDIR="/home/adriel/intelFPGA_lite/22.1std/quartus"
export SOPC_KIT_NIOS2="/home/adriel/intelFPGA_lite/22.1std/nios2eds"

echo "============================================================"
echo " Nios II BSP + Makefile Generator"
echo "============================================================"
echo ""

SRCS=""

for f in "$APP_DIR"/*.c "$APP_DIR"/src/*.c "$APP_DIR"/lib/*.c; do
    [ -f "$f" ] && SRCS="$SRCS $f"
done

SRCS="${SRCS# }"

echo "Sources found:"
for f in $SRCS; do
    echo "  $f"
done

echo ""
echo "[1/3] Generating BSP..."

nios2-bsp hal \
    "$BSP_DIR" \
    "$SOPCINFO" \
    --cpu-name "$CPU_NAME" \
    --set hal.enable_reduced_device_drivers true \
    --set hal.enable_small_c_library true \
    --set hal.enable_lightweight_device_driver_api true \
    --set hal.sys_clk_timer none \
    --set hal.timestamp_timer none \
    --set hal.max_file_descriptors 4 \
    --set hal.enable_exit false

[ $? -ne 0 ] && echo "ERROR: BSP generation failed" && exit 1

echo ""
echo "[2/3] Generating Makefile..."

nios2-app-generate-makefile \
    --bsp-dir "$BSP_DIR" \
    --app-dir "$APP_DIR" \
    --elf-name main.elf \
    --src-files $SRCS \
    --inc-rdir "$APP_DIR/include"

[ $? -ne 0 ] && echo "ERROR: Makefile generation failed" && exit 1

echo ""
echo "[3/3] Building BSP..."

make -C "$BSP_DIR"

[ $? -ne 0 ] && echo "ERROR: BSP build failed" && exit 1

echo ""
echo "DONE!"
echo "Run:"
echo "  ./build.sh"
EOF

# ============================================================
# update_makefile.sh
# ============================================================

cat > "$SCRIPT_DIR/update_makefile.sh" << 'EOF'
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
    --inc-rdir "$APP_DIR/include"

echo ""
echo "Makefile updated successfully!"
echo ""
echo "Next step:"
echo "  ./build.sh"
EOF

# ============================================================
# build.sh
# ============================================================

cat > "$SCRIPT_DIR/build.sh" << 'EOF'
#!/bin/bash

APP_DIR="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II/app"

export PATH="$PATH:/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin"
export QUARTUS_ROOTDIR="/home/adriel/intelFPGA_lite/22.1std/quartus"
export SOPC_KIT_NIOS2="/home/adriel/intelFPGA_lite/22.1std/nios2eds"

echo "============================================================"
echo " Building Nios II Application"
echo "============================================================"

# Patch Makefile to use -Os (size optimization) every build
if [ -f "$APP_DIR/Makefile" ]; then
    sed -i 's|APP_CFLAGS_OPTIMIZATION :=.*|APP_CFLAGS_OPTIMIZATION := -Os|' "$APP_DIR/Makefile"
    echo "[OK] Optimization set to -Os"
fi

make -C "$APP_DIR"

[ $? -ne 0 ] && echo "ERROR: Build failed" && exit 1

echo ""
echo "Build successful!"
echo ""
echo "ELF:"
echo "  $APP_DIR/main.elf"
EOF

# ============================================================
# download.sh
# ============================================================

cat > "$SCRIPT_DIR/download.sh" << 'EOF'
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
EOF

# ============================================================
# terminal.sh
# ============================================================

cat > "$SCRIPT_DIR/terminal.sh" << 'EOF'
#!/bin/bash

export PATH="$PATH:/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin"
export QUARTUS_ROOTDIR="/home/adriel/intelFPGA_lite/22.1std/quartus"
export SOPC_KIT_NIOS2="/home/adriel/intelFPGA_lite/22.1std/nios2eds"

echo "============================================================"
echo " Nios II Terminal"
echo " CTRL+C to exit"
echo "============================================================"

nios2-terminal
EOF

# ============================================================
# rebuild_bsp.sh
# ============================================================

cat > "$SCRIPT_DIR/rebuild_bsp.sh" << 'EOF'
#!/bin/bash

SOPCINFO="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/MusicPlayerQuartus22/MusicPlayerPlatformDesign.sopcinfo"
CPU_NAME="CPU_NIOS_II"
BSP_DIR="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II/bsp"

export PATH="$PATH:/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin"
export QUARTUS_ROOTDIR="/home/adriel/intelFPGA_lite/22.1std/quartus"
export SOPC_KIT_NIOS2="/home/adriel/intelFPGA_lite/22.1std/nios2eds"

echo "============================================================"
echo " Rebuilding BSP"
echo "============================================================"

rm -rf "$BSP_DIR"

nios2-bsp hal \
    "$BSP_DIR" \
    "$SOPCINFO" \
    --cpu-name "$CPU_NAME" \
    --set hal.enable_reduced_device_drivers true \
    --set hal.enable_small_c_library true \
    --set hal.enable_lightweight_device_driver_api true \
    --set hal.sys_clk_timer none \
    --set hal.timestamp_timer none \
    --set hal.max_file_descriptors 4 \
    --set hal.enable_exit false

[ $? -ne 0 ] && echo "ERROR: BSP generation failed" && exit 1

make -C "$BSP_DIR"

[ $? -ne 0 ] && echo "ERROR: BSP build failed" && exit 1

echo ""
echo "BSP rebuilt successfully!"
EOF

# ============================================================
# run_sim.sh
# ============================================================

cat > "$SCRIPT_DIR/run_sim.sh" << 'EOF'
#!/bin/bash

SOC_NAME="MusicPlayerPlatformDesign"
ELF="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II/app/main.elf"
BSP_DIR="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II/bsp"
SOPCINFO_DIR="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/MusicPlayerQuartus22"
MENTOR="$SOPCINFO_DIR/$SOC_NAME/testbench/mentor"
SUBMODULES="$SOPCINFO_DIR/$SOC_NAME/testbench/${SOC_NAME}_tb/simulation/submodules"

export PATH="$PATH:/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin"
export QUARTUS_ROOTDIR="/home/adriel/intelFPGA_lite/22.1std/quartus"
export SOPC_KIT_NIOS2="/home/adriel/intelFPGA_lite/22.1std/nios2eds"

echo "============================================================"
echo " Nios II Simulation Prep"
echo "============================================================"

if [ ! -f "$ELF" ]; then
    echo "ERROR:"
    echo "  ELF not found."
    echo "Run ./build.sh first."
    exit 1
fi

mkdir -p "$MENTOR"

echo "[1/3] Copying ELF..."
cp "$ELF" "$MENTOR/main.elf"

echo "[2/3] Reading RAM base..."

RAM_BASE=$(grep "_BASE" "$BSP_DIR/system.h" | grep "RAM_" | awk '{print $3}' | head -1)

if [ -z "$RAM_BASE" ]; then
    echo "ERROR: RAM base not found."
    exit 1
fi

echo "RAM_BASE = $RAM_BASE"

echo "[3/3] ELF -> HEX..."

elf2hex \
    --input="$MENTOR/main.elf" \
    --output="$SUBMODULES/${SOC_NAME}_RAM.hex" \
    --width=32 \
    --base="$RAM_BASE" \
    --end=0x7ffff

[ $? -ne 0 ] && echo "ERROR: elf2hex failed" && exit 1

echo ""
echo "============================================================"
echo " DONE! Now open ModelSim and run:"
echo "============================================================"
echo "   cd $MENTOR"
echo "   do msim_setup.tcl"
echo "   add wave /${SOC_NAME}_tb/*"
echo "   ld_debug"
echo "   run 2.5ms"
echo "============================================================"
EOF

# ============================================================
# Replace placeholders (unique tokens, order-safe)
# ============================================================

for f in "$SCRIPT_DIR"/*.sh; do
    sed -i "s|/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/MusicPlayerQuartus22/MusicPlayerPlatformDesign.sopcinfo|$SOPCINFO|g"           "$f"
    sed -i "s|/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/MusicPlayerQuartus22|$SOPCINFO_DIR|g"   "$f"
    sed -i "s|/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II|$SW_ROOT|g"             "$f"
    sed -i "s|CPU_NIOS_II|$CPU_NAME|g"           "$f"
    sed -i "s|/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin|$GCC_PATH|g"           "$f"
    sed -i "s|MusicPlayerPlatformDesign|$SOC_NAME|g"           "$f"
    sed -i "s|/home/adriel/intelFPGA_lite/22.1std/quartus|$QUARTUS_ROOT|g"   "$f"
    sed -i "s|/home/adriel/intelFPGA_lite/22.1std/nios2eds|$NIOS_ROOT|g"         "$f"
done

# ============================================================
# Permissions
# ============================================================

chmod +x "$SCRIPT_DIR"/*.sh

echo ""
echo "============================================================"
echo " DONE!"
echo "============================================================"
echo ""
echo "Generated scripts:"
echo ""

ls -1 "$SCRIPT_DIR"/*.sh

echo ""
echo "Next step:"
echo "  ./new_project.sh"
echo ""