#!/bin/bash
# ============================================================
# 01Setup.sh
# Native Linux version (NO WSL / NO .exe)
# Run ONCE.
# ============================================================

echo "============================================================"
echo " Nios II Project Initializer (Linux Native)"
echo "============================================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================
# Auto-detect Quartus / Nios II
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
# User prompts
# ============================================================

echo "Enter FULL path to .sopcinfo file:"
read -rp "SOPCINFO path: " SOPCINFO
if [ ! -f "$SOPCINFO" ]; then
    echo "ERROR: File not found: $SOPCINFO"
    exit 1
fi

echo ""
echo "Enter FULL path to software root:"
read -rp "Software root: " SW_ROOT

echo ""
read -rp "CPU name [CPU_NIOS_II]: " CPU_NAME
[ -z "$CPU_NAME" ] && CPU_NAME="CPU_NIOS_II"

echo ""
echo "Detected GCC path: $GCC_PATH_DEFAULT"
read -rp "Use this GCC path? [Y/n]: " GCC_CONFIRM
if [[ "${GCC_CONFIRM,,}" == "n" ]]; then
    read -rp "Enter GCC path manually: " GCC_PATH
else
    GCC_PATH="$GCC_PATH_DEFAULT"
fi

echo ""
echo "Nios II stack pointer address for --set APP_LDFLAGS_USER"
echo "(e.g. 0xE000). Leave blank to omit the flag entirely:"
read -rp "Stack pointer [none]: " STACK_PTR

SOC_NAME="$(basename "$SOPCINFO" .sopcinfo)"
SOPCINFO_DIR="$(dirname "$SOPCINFO")"

# Quartus project name (for 09MakeSof.sh)
QPF_FILE=$(find "$SOPCINFO_DIR" -maxdepth 1 -name "*.qpf" 2>/dev/null | head -1)
if [ -n "$QPF_FILE" ]; then
    QPF_DEFAULT="$(basename "$QPF_FILE" .qpf)"
    echo ""
    echo "Detected Quartus project: $QPF_DEFAULT"
    read -rp "Use this project name? [Y/n]: " QPF_CONFIRM
    if [[ "${QPF_CONFIRM,,}" == "n" ]]; then
        read -rp "Quartus project name (no .qpf extension): " QUARTUS_PROJECT
    else
        QUARTUS_PROJECT="$QPF_DEFAULT"
    fi
else
    echo ""
    read -rp "Quartus project name (no .qpf extension): " QUARTUS_PROJECT
fi

echo ""
echo "On-chip RAM component name in Platform Designer (for 09MakeSof.sh):"
read -rp "RAM name [RAM_NIOS_II]: " RAM_NAME
[ -z "$RAM_NAME" ] && RAM_NAME="RAM_NIOS_II"

# ============================================================
# Confirm
# ============================================================

echo ""
echo "============================================================"
echo " Confirm Settings"
echo "============================================================"
echo " SOPCINFO      : $SOPCINFO"
echo " SOPCINFO DIR  : $SOPCINFO_DIR"
echo " SW ROOT       : $SW_ROOT"
echo " CPU NAME      : $CPU_NAME"
echo " GCC PATH      : $GCC_PATH"
echo " QUARTUS ROOT  : $QUARTUS_ROOT"
echo " NIOS2EDS      : $NIOS_ROOT"
echo " SOC NAME      : $SOC_NAME"
echo " STACK PTR     : ${STACK_PTR:-<omitted>}"
echo " QPF PROJECT   : $QUARTUS_PROJECT"
echo " RAM NAME      : $RAM_NAME"
echo "============================================================"
echo ""

read -rp "Continue? [Y/n]: " CONFIRM
[[ "${CONFIRM,,}" == "n" ]] && echo "Aborted." && exit 1

# ============================================================
# Create folders
# ============================================================

mkdir -p "$SW_ROOT/app/src"
mkdir -p "$SW_ROOT/app/lib"
mkdir -p "$SW_ROOT/app/include"

EXISTING_C=$(find "$SW_ROOT/app" -name "*.c" 2>/dev/null | head -1)
if [ -z "$EXISTING_C" ]; then
cat > "$SW_ROOT/app/main.c" << 'MAINEOF'
#include <sys/alt_stdio.h>

int main(void)
{
    alt_putstr("Hello from Nios II!\n");
    while (1);
    return 0;
}
MAINEOF
    echo "[OK] Created default main.c"
else
    echo "[OK] Existing sources detected:"
    find "$SW_ROOT/app" -name "*.c"
fi

# ============================================================
# 02NewProject.sh
# ============================================================

cat > "$SCRIPT_DIR/02NewProject.sh" << 'GENEOF'
#!/bin/bash

SOPCINFO="###SOPCINFO###"
SW_ROOT="###SW_ROOT###"
CPU_NAME="###CPU_NAME###"
BSP_DIR="$SW_ROOT/bsp"
APP_DIR="$SW_ROOT/app"

export PATH="$PATH:###GCC_PATH###"
export QUARTUS_ROOTDIR="###QUARTUS_ROOT###"
export SOPC_KIT_NIOS2="###NIOS_ROOT###"

echo "============================================================"
echo " Nios II BSP + Makefile Generator"
echo "============================================================"
echo ""

SRCS=()
while IFS= read -r -d '' f; do
    SRCS+=("$f")
done < <(find "$APP_DIR" -type f -name "*.c" -print0)

echo "Sources found:"
for f in "${SRCS[@]}"; do echo "  $f"; done
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
LDFLAGS_ARG=(###LDFLAGS###)
nios2-app-generate-makefile \
    --bsp-dir "$BSP_DIR" \
    --app-dir "$APP_DIR" \
    --elf-name main.elf \
    --src-files "${SRCS[@]}" \
    --inc-rdir "$APP_DIR/include" \
    "${LDFLAGS_ARG[@]}"
[ $? -ne 0 ] && echo "ERROR: Makefile generation failed" && exit 1

echo ""
echo "[3/3] Building BSP..."
make -C "$BSP_DIR"
[ $? -ne 0 ] && echo "ERROR: BSP build failed" && exit 1

echo ""
echo "DONE! Run: ./04Build.sh"
GENEOF

# ============================================================
# 03UpdateMake.sh
# ============================================================

cat > "$SCRIPT_DIR/03UpdateMake.sh" << 'GENEOF'
#!/bin/bash
set -e

SW_ROOT="###SW_ROOT###"
APP_DIR="$SW_ROOT/app"
BSP_DIR="$SW_ROOT/bsp"

export PATH="$PATH:###GCC_PATH###"
export QUARTUS_ROOTDIR="###QUARTUS_ROOT###"
export SOPC_KIT_NIOS2="###NIOS_ROOT###"

echo "============================================================"
echo " Updating Application Makefile"
echo "============================================================"
echo ""

if ! command -v nios2-app-generate-makefile >/dev/null 2>&1; then
    echo "ERROR: nios2-app-generate-makefile not found in PATH"
    exit 1
fi

SRCS=()
while IFS= read -r -d '' f; do
    SRCS+=("$f")
done < <(find "$APP_DIR" -type f -name "*.c" -print0)

if [ ${#SRCS[@]} -eq 0 ]; then
    echo "ERROR: No .c source files found."
    exit 1
fi

echo "Sources found:"
for f in "${SRCS[@]}"; do echo "  $f"; done
echo ""

LDFLAGS_ARG=(###LDFLAGS###)
nios2-app-generate-makefile \
    --bsp-dir "$BSP_DIR" \
    --app-dir "$APP_DIR" \
    --elf-name main.elf \
    --src-files "${SRCS[@]}" \
    --inc-rdir "$APP_DIR/include" \
    "${LDFLAGS_ARG[@]}"

echo ""
echo "Makefile updated. Run: ./04Build.sh"
GENEOF

# ============================================================
# 04Build.sh
# ============================================================

cat > "$SCRIPT_DIR/04Build.sh" << 'GENEOF'
#!/bin/bash

APP_DIR="###SW_ROOT###/app"

export PATH="$PATH:###GCC_PATH###"
export QUARTUS_ROOTDIR="###QUARTUS_ROOT###"
export SOPC_KIT_NIOS2="###NIOS_ROOT###"

echo "============================================================"
echo " Building Nios II Application"
echo "============================================================"

if [ -f "$APP_DIR/Makefile" ]; then
    sed -i 's|APP_CFLAGS_OPTIMIZATION :=.*|APP_CFLAGS_OPTIMIZATION := -Os|' "$APP_DIR/Makefile"
    echo "[OK] Optimization set to -Os"
fi

make -C "$APP_DIR"
[ $? -ne 0 ] && echo "ERROR: Build failed" && exit 1

rm -rf "$APP_DIR/obj"
rm -f  "$APP_DIR/main.objdump"
echo "[OK] Cleaned obj/, main.objdump"

echo ""
echo "Build successful! ELF: $APP_DIR/main.elf"
GENEOF

# ============================================================
# 05Download.sh
# ============================================================

cat > "$SCRIPT_DIR/05Download.sh" << 'GENEOF'
#!/bin/bash

ELF="###SW_ROOT###/app/main.elf"

export PATH="$PATH:###GCC_PATH###"
export QUARTUS_ROOTDIR="###QUARTUS_ROOT###"
export SOPC_KIT_NIOS2="###NIOS_ROOT###"

if [ ! -f "$ELF" ]; then
    echo "ERROR: $ELF not found. Run 04Build.sh first."
    exit 1
fi

echo "============================================================"
echo " Downloading ELF"
echo "============================================================"

nios2-download -g "$ELF"
[ $? -ne 0 ] && echo "ERROR: Download failed" && exit 1

echo "Download successful!"
GENEOF

# ============================================================
# 06Terminal.sh
# ============================================================

cat > "$SCRIPT_DIR/06Terminal.sh" << 'GENEOF'
#!/bin/bash

export PATH="$PATH:###GCC_PATH###"
export QUARTUS_ROOTDIR="###QUARTUS_ROOT###"
export SOPC_KIT_NIOS2="###NIOS_ROOT###"

echo "============================================================"
echo " Nios II Terminal  (CTRL+C to exit)"
echo "============================================================"

nios2-terminal
GENEOF

# ============================================================
# 07RebuildBsp.sh
# ============================================================

cat > "$SCRIPT_DIR/07RebuildBsp.sh" << 'GENEOF'
#!/bin/bash

SOPCINFO="###SOPCINFO###"
CPU_NAME="###CPU_NAME###"
BSP_DIR="###SW_ROOT###/bsp"

export PATH="$PATH:###GCC_PATH###"
export QUARTUS_ROOTDIR="###QUARTUS_ROOT###"
export SOPC_KIT_NIOS2="###NIOS_ROOT###"

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

echo "BSP rebuilt successfully!"
GENEOF

# ============================================================
# 08RunSim.sh
# ============================================================

cat > "$SCRIPT_DIR/08RunSim.sh" << 'GENEOF'
#!/bin/bash

SOC_NAME="###SOC_NAME###"
ELF="###SW_ROOT###/app/main.elf"
BSP_DIR="###SW_ROOT###/bsp"
SOPCINFO_DIR="###SOPCINFO_DIR###"
MENTOR="$SOPCINFO_DIR/$SOC_NAME/testbench/mentor"
SUBMODULES="$SOPCINFO_DIR/$SOC_NAME/testbench/${SOC_NAME}_tb/simulation/submodules"

export PATH="$PATH:###GCC_PATH###"
export QUARTUS_ROOTDIR="###QUARTUS_ROOT###"
export SOPC_KIT_NIOS2="###NIOS_ROOT###"

if [ ! -f "$ELF" ]; then
    echo "ERROR: ELF not found. Run 04Build.sh first."
    exit 1
fi

mkdir -p "$MENTOR"

echo "[1/3] Copying ELF..."
cp "$ELF" "$MENTOR/main.elf"

echo "[2/3] Reading RAM base..."
RAM_BASE=$(grep "_BASE" "$BSP_DIR/system.h" | grep "RAM_" | awk '{print $3}' | head -1)
if [ -z "$RAM_BASE" ]; then
    echo "ERROR: RAM base not found in system.h"
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
echo " DONE! ModelSim commands:"
echo "============================================================"
echo "   cd $MENTOR"
echo "   do msim_setup.tcl"
echo "   add wave /${SOC_NAME}_tb/*"
echo "   ld_debug"
echo "   run 2.5ms"
echo "============================================================"
GENEOF

# ============================================================
# 09MakeSof.sh
# ============================================================

cat > "$SCRIPT_DIR/09MakeSof.sh" << 'GENEOF'
#!/bin/bash
# Embeds Nios II ELF into on-chip RAM and rebuilds .sof.
# Nios II boots automatically -- no nios2-download needed.
set -e

QUARTUS_PROJECT_DIR="###SOPCINFO_DIR###"
BSP_DIR="###SW_ROOT###/bsp"
ELF="###SW_ROOT###/app/main.elf"
PROJECT="###QUARTUS_PROJECT###"
QSYS_SYSTEM="###SOC_NAME###"
RAM_NAME="###RAM_NAME###"
HEX_NAME="${QSYS_SYSTEM}_${RAM_NAME}.hex"

export QUARTUS_ROOTDIR="###QUARTUS_ROOT###"
export SOPC_KIT_NIOS2="###NIOS_ROOT###"
export PATH="$PATH:$QUARTUS_ROOTDIR/bin:$SOPC_KIT_NIOS2/bin:###GCC_PATH###"

if [ ! -f "$ELF" ]; then
    echo "ERROR: $ELF not found. Run 04Build.sh first."
    exit 1
fi

echo "============================================================"
echo " 1) Generate RAM init HEX via BSP"
echo "============================================================"
make -C "$BSP_DIR" -f mem_init.mk mem_init_generate \
    ELF="$ELF" \
    QUARTUS_PROJECT_DIR="$QUARTUS_PROJECT_DIR"

echo "============================================================"
echo " 2) Install HEX into project root"
echo "============================================================"
cp "$BSP_DIR/mem_init/${HEX_NAME}" "$QUARTUS_PROJECT_DIR/"
echo "    copied ${HEX_NAME}"

echo "============================================================"
echo " 3) Update RAM contents in fitted DB"
echo "============================================================"
cd "$QUARTUS_PROJECT_DIR"
quartus_cdb "$PROJECT" --update_mif

echo "============================================================"
echo " 4) Re-assemble .sof"
echo "============================================================"
quartus_asm "$PROJECT"

SOF_PATH="$QUARTUS_PROJECT_DIR/output_files/${PROJECT}.sof"
echo ""
echo "Done. Embedded .sof:"
ls -l "$SOF_PATH"
echo "Load with Quartus Programmer -- Nios II boots automatically."
GENEOF

# ============================================================
# Substitute all ###PLACEHOLDER### tokens
# ============================================================

for f in "$SCRIPT_DIR"/0[2-9]*.sh; do
    sed -i "s|###SOPCINFO_DIR###|$SOPCINFO_DIR|g"         "$f"
    sed -i "s|###SOPCINFO###|$SOPCINFO|g"                 "$f"
    sed -i "s|###SW_ROOT###|$SW_ROOT|g"                   "$f"
    sed -i "s|###CPU_NAME###|$CPU_NAME|g"                 "$f"
    sed -i "s|###GCC_PATH###|$GCC_PATH|g"                 "$f"
    sed -i "s|###QUARTUS_ROOT###|$QUARTUS_ROOT|g"         "$f"
    sed -i "s|###NIOS_ROOT###|$NIOS_ROOT|g"               "$f"
    sed -i "s|###SOC_NAME###|$SOC_NAME|g"                 "$f"
    sed -i "s|###QUARTUS_PROJECT###|$QUARTUS_PROJECT|g"   "$f"
    sed -i "s|###RAM_NAME###|$RAM_NAME|g"                 "$f"
done

# ============================================================
# LDFLAGS substitution (02 and 03 only)
# LDFLAGS_ARG=(###LDFLAGS###) -> filled or left empty
# ============================================================

for f in "$SCRIPT_DIR/02NewProject.sh" "$SCRIPT_DIR/03UpdateMake.sh"; do
    if [ -n "$STACK_PTR" ]; then
        sed -i "s|###LDFLAGS###|--set APP_LDFLAGS_USER -Wl,--defsym,__alt_stack_pointer=$STACK_PTR|" "$f"
    else
        sed -i "s|###LDFLAGS###||" "$f"
    fi
done

# ============================================================
# Permissions
# ============================================================

chmod +x "$SCRIPT_DIR"/0*.sh

echo ""
echo "============================================================"
echo " DONE!"
echo "============================================================"
echo ""
echo "Generated scripts:"
ls -1 "$SCRIPT_DIR"/0*.sh
echo ""
echo "Next step: ./02NewProject.sh"
echo ""