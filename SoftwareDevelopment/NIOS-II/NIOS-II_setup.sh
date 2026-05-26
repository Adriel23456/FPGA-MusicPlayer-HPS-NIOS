#!/bin/bash
# ============================================================
# NIOS-II_setup.sh
# Run ONCE from inside the Nios II Command Shell.
# Creates all project scripts in the same directory.
# ============================================================

echo "============================================================"
echo " Nios II Project Initializer"
echo "============================================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Auto-detect GCC path ──────────────────────────────────────
GCC_PATH_DEFAULT=""
for d in /mnt/c/intelFPGA_lite /mnt/c/intelFPGA /mnt/d/intelFPGA_lite /mnt/d/intelFPGA; do
    for v in 22.1std 22.1 21.1std 21.1 20.1std 20.1; do
        candidate="$d/$v/nios2eds/bin/gnu/H-x86_64-mingw32/bin"
        if [ -d "$candidate" ]; then
            GCC_PATH_DEFAULT="$candidate"
            break 2
        fi
    done
done

# ── Ask for paths ─────────────────────────────────────────────
echo "Enter the FULL bash path to your .sopcinfo file:"
echo "(e.g. /mnt/d/MyProject/MusicPlayerQuartus/MusicPlayerPlatformDesign.sopcinfo)"
read -rp "SOPCINFO path: " SOPCINFO

if [ ! -f "$SOPCINFO" ]; then
    echo "ERROR: File not found: $SOPCINFO"
    exit 1
fi

echo ""
echo "Enter the FULL bash path to your software root directory:"
echo "(e.g. /mnt/d/MyProject/SoftwareDevelopment/NIOS-II)"
read -rp "Software root path: " SW_ROOT

echo ""
echo "Enter the CPU component name as it appears in Platform Designer:"
read -rp "CPU name [CPU_NIOS_II]: " CPU_NAME
if [ -z "$CPU_NAME" ]; then
    CPU_NAME="CPU_NIOS_II"
fi

echo ""
echo "Enter the GCC toolchain bin path:"
echo "(nios2-elf-gcc.exe lives here)"
if [ -n "$GCC_PATH_DEFAULT" ]; then
    echo "(auto-detected: $GCC_PATH_DEFAULT)"
    read -rp "GCC path [press Enter to accept]: " GCC_PATH
    if [ -z "$GCC_PATH" ]; then
        GCC_PATH="$GCC_PATH_DEFAULT"
    fi
else
    echo "(e.g. /mnt/c/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-mingw32/bin)"
    read -rp "GCC path: " GCC_PATH
fi

echo ""
SOC_NAME="$(basename "$SOPCINFO" .sopcinfo)"

# ── Confirm all paths ─────────────────────────────────────────
echo "============================================================"
echo " Please confirm the following settings:"
echo "============================================================"
echo "  SOPCINFO : $SOPCINFO"
echo "  SW ROOT  : $SW_ROOT"
echo "  CPU NAME : $CPU_NAME"
echo "  GCC PATH : $GCC_PATH"
echo "  SOC NAME : $SOC_NAME"
echo "  SCRIPTS  : $SCRIPT_DIR"
echo "============================================================"
echo ""
read -rp "Are these correct? [Y/n]: " CONFIRM
if [ "${CONFIRM,,}" = "n" ]; then
    echo "Aborted. Re-run the script to try again."
    exit 1
fi

echo ""

# ── Create directory structure ─────────────────────────────────
mkdir -p "$SW_ROOT/app/src"
mkdir -p "$SW_ROOT/app/lib"
mkdir -p "$SW_ROOT/app/include"

# Only create main.c if NO .c files exist anywhere in the app tree
EXISTING_C=$(find "$SW_ROOT/app" -name "*.c" 2>/dev/null | head -1)
if [ -z "$EXISTING_C" ]; then
cat > "$SW_ROOT/app/main.c" << 'CEOF'
#include <sys/alt_stdio.h>

int main(void) {
    alt_putstr("Hello from Nios II!\n");
    while(1);
    return 0;
}
CEOF
    echo "[OK] main.c written (no existing source files found)."
else
    echo "[OK] Existing source files detected -- leaving them untouched:"
    find "$SW_ROOT/app" -name "*.c" | while read f; do echo "  $f"; done
fi

echo "[OK] Directory structure ready."
echo ""

# ==============================================================
# new_project.sh
# ==============================================================
cat > "$SCRIPT_DIR/new_project.sh" << 'SHEOF'
#!/bin/bash
SOPCINFO="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/MusicPlayerQuartus22/MusicPlayerPlatformDesign.sopcinfo"
SW_ROOT="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II"
CPU_NAME="CPU_NIOS_II"
BSP_DIR="$SW_ROOT/bsp"
APP_DIR="$SW_ROOT/app"
export PATH=$PATH:/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin

to_win() { echo "$1" | sed 's|/mnt/\([a-z]\)/|\1:/|'; }

echo "============================================================"
echo " Nios II -- BSP + Makefile Generator"
echo "============================================================"
echo ""

SRCS=""
for f in "$APP_DIR"/*.c "$APP_DIR"/src/*.c "$APP_DIR"/lib/*.c; do
    [ -f "$f" ] && SRCS="$SRCS $f"
done
SRCS="${SRCS# }"

echo "Sources found:"
for f in $SRCS; do echo "  $f"; done
echo ""

echo "[1/3] Generating BSP..."
nios2-bsp hal "$(to_win "$BSP_DIR")" "$(to_win "$SOPCINFO")" --cpu-name "$CPU_NAME"
[ $? -ne 0 ] && echo "ERROR: BSP generation failed" && exit 1

echo ""
echo "[2/3] Generating app Makefile..."
WIN_SRCS=""
for f in $SRCS; do
    WIN_SRCS="$WIN_SRCS $(to_win "$f")"
done
WIN_SRCS="${WIN_SRCS# }"

nios2-app-generate-makefile.exe \
    --bsp-dir "$(to_win "$BSP_DIR")" \
    --app-dir "$(to_win "$APP_DIR")" \
    --src-files $WIN_SRCS \
    --inc-rdir "$(to_win "$APP_DIR/include")"
[ $? -ne 0 ] && echo "ERROR: App Makefile generation failed" && exit 1

echo ""
echo "[3/3] Building BSP..."
make -C "$BSP_DIR"
[ $? -ne 0 ] && echo "ERROR: BSP build failed" && exit 1

echo ""
echo "DONE! Run ./build.sh to compile the application."
SHEOF
sed -i "s|/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/MusicPlayerQuartus22/MusicPlayerPlatformDesign.sopcinfo|$SOPCINFO|g" "$SCRIPT_DIR/new_project.sh"
sed -i "s|/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II|$SW_ROOT|g"   "$SCRIPT_DIR/new_project.sh"
sed -i "s|CPU_NIOS_II|$CPU_NAME|g" "$SCRIPT_DIR/new_project.sh"
sed -i "s|/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin|$GCC_PATH|g" "$SCRIPT_DIR/new_project.sh"

# ==============================================================
# update_makefile.sh
# ==============================================================
cat > "$SCRIPT_DIR/update_makefile.sh" << 'SHEOF'
#!/bin/bash
SW_ROOT="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II"
BSP_DIR="$SW_ROOT/bsp"
APP_DIR="$SW_ROOT/app"
export PATH=$PATH:/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin

to_win() { echo "$1" | sed 's|/mnt/\([a-z]\)/|\1:/|'; }

echo "=== Scanning source files ==="
SRCS=""
for f in "$APP_DIR"/*.c "$APP_DIR"/src/*.c "$APP_DIR"/lib/*.c; do
    [ -f "$f" ] && SRCS="$SRCS $f"
done
SRCS="${SRCS# }"

echo "Sources found:"
for f in $SRCS; do echo "  $f"; done
echo ""

WIN_SRCS=""
for f in $SRCS; do
    WIN_SRCS="$WIN_SRCS $(to_win "$f")"
done
WIN_SRCS="${WIN_SRCS# }"

nios2-app-generate-makefile.exe \
    --bsp-dir "$(to_win "$BSP_DIR")" \
    --app-dir "$(to_win "$APP_DIR")" \
    --src-files $WIN_SRCS \
    --inc-rdir "$(to_win "$APP_DIR/include")"
[ $? -ne 0 ] && echo "ERROR: Makefile regeneration failed" && exit 1

echo "Done! Run ./build.sh to recompile."
SHEOF
sed -i "s|/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II|$SW_ROOT|g"   "$SCRIPT_DIR/update_makefile.sh"
sed -i "s|/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin|$GCC_PATH|g" "$SCRIPT_DIR/update_makefile.sh"

# ==============================================================
# build.sh
# ==============================================================
cat > "$SCRIPT_DIR/build.sh" << 'SHEOF'
#!/bin/bash
APP_DIR="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II/app"
export PATH=$PATH:/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin

echo "=== Building Nios II Application ==="
make -C "$APP_DIR"
[ $? -ne 0 ] && echo "ERROR: Build failed" && exit 1
echo ""
echo "Build successful!"
echo "  ELF: $APP_DIR/main.elf"
SHEOF
sed -i "s|/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II|$SW_ROOT|g"   "$SCRIPT_DIR/build.sh"
sed -i "s|/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin|$GCC_PATH|g" "$SCRIPT_DIR/build.sh"

# ==============================================================
# download.sh
# ==============================================================
cat > "$SCRIPT_DIR/download.sh" << 'SHEOF'
#!/bin/bash
ELF="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II/app/main.elf"
export PATH=$PATH:/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin

if [ ! -f "$ELF" ]; then
    echo "ERROR: $ELF not found. Run ./build.sh first."
    exit 1
fi

echo "=== Downloading ELF to FPGA ==="
nios2-download -g "$ELF"
[ $? -ne 0 ] && echo "ERROR: Download failed. Is the FPGA programmed?" && exit 1
echo "Download successful! Run ./terminal.sh to see output."
SHEOF
sed -i "s|/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II|$SW_ROOT|g"   "$SCRIPT_DIR/download.sh"
sed -i "s|/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin|$GCC_PATH|g" "$SCRIPT_DIR/download.sh"

# ==============================================================
# terminal.sh
# ==============================================================
cat > "$SCRIPT_DIR/terminal.sh" << 'SHEOF'
#!/bin/bash
export PATH=$PATH:/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin
echo "=== Nios II Terminal (CTRL+C to exit) ==="
nios2-terminal.exe
SHEOF
sed -i "s|/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin|$GCC_PATH|g" "$SCRIPT_DIR/terminal.sh"

# ==============================================================
# rebuild_bsp.sh
# ==============================================================
cat > "$SCRIPT_DIR/rebuild_bsp.sh" << 'SHEOF'
#!/bin/bash
SOPCINFO="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/MusicPlayerQuartus22/MusicPlayerPlatformDesign.sopcinfo"
CPU_NAME="CPU_NIOS_II"
BSP_DIR="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II/bsp"
export PATH=$PATH:/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin

to_win() { echo "$1" | sed 's|/mnt/\([a-z]\)/|\1:/|'; }

echo "=== Rebuilding BSP ==="
echo "[1/3] Deleting old BSP..."
rm -rf "$BSP_DIR"

echo "[2/3] Generating new BSP..."
nios2-bsp hal "$(to_win "$BSP_DIR")" "$(to_win "$SOPCINFO")" --cpu-name "$CPU_NAME"
[ $? -ne 0 ] && echo "ERROR: BSP generation failed" && exit 1

echo "[3/3] Building BSP..."
make -C "$BSP_DIR"
[ $? -ne 0 ] && echo "ERROR: BSP build failed" && exit 1

echo "BSP rebuilt. Run ./build.sh to recompile the application."
SHEOF
sed -i "s|/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/MusicPlayerQuartus22/MusicPlayerPlatformDesign.sopcinfo|$SOPCINFO|g" "$SCRIPT_DIR/rebuild_bsp.sh"
sed -i "s|CPU_NIOS_II|$CPU_NAME|g" "$SCRIPT_DIR/rebuild_bsp.sh"
sed -i "s|/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II|$SW_ROOT|g"   "$SCRIPT_DIR/rebuild_bsp.sh"
sed -i "s|/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin|$GCC_PATH|g" "$SCRIPT_DIR/rebuild_bsp.sh"

# ==============================================================
# run_sim.sh
# ==============================================================
cat > "$SCRIPT_DIR/run_sim.sh" << 'SHEOF'
#!/bin/bash
SOC_NAME="MusicPlayerPlatformDesign"
ELF="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II/app/main.elf"
BSP_DIR="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II/bsp"
SOPCINFO_DIR="$(dirname "/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/MusicPlayerQuartus22/MusicPlayerPlatformDesign.sopcinfo")"
MENTOR="$SOPCINFO_DIR/$SOC_NAME/testbench/mentor"
SUBMODULES="$SOPCINFO_DIR/$SOC_NAME/testbench/${SOC_NAME}_tb/simulation/submodules"
export PATH=$PATH:/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin

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
SHEOF
sed -i "s|MusicPlayerPlatformDesign|$SOC_NAME|g" "$SCRIPT_DIR/run_sim.sh"
sed -i "s|/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II|$SW_ROOT|g"   "$SCRIPT_DIR/run_sim.sh"
sed -i "s|/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/MusicPlayerQuartus22/MusicPlayerPlatformDesign.sopcinfo|$SOPCINFO|g" "$SCRIPT_DIR/run_sim.sh"
sed -i "s|/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin|$GCC_PATH|g" "$SCRIPT_DIR/run_sim.sh"

# ==============================================================
# Set permissions
# ==============================================================
chmod +x "$SCRIPT_DIR"/*.sh

echo "[OK] All scripts written and marked executable:"
echo ""
ls -1 "$SCRIPT_DIR"/*.sh | while read f; do echo "  $f"; done
echo ""
echo "============================================================"
echo " DONE! Next step:"
echo "   ./new_project.sh"
echo "============================================================"