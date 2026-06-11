#!/bin/bash
# ============================================================
# 00Shell.sh
# Opens the Nios II Command Shell in the SAME folder
# as this script. Run from anywhere.
# ============================================================

NIOS2_SHELL=""

# Common install locations
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
    "19.1std"
    "19.1"
)

# Search for nios2_command_shell.sh
for dir in "${SEARCH_DIRS[@]}"; do
    for ver in "${VERSIONS[@]}"; do
        if [ -f "$dir/$ver/nios2eds/nios2_command_shell.sh" ]; then
            NIOS2_SHELL="$dir/$ver/nios2eds/nios2_command_shell.sh"
            break 2
        fi
    done
done

# Not found?
if [ -z "$NIOS2_SHELL" ]; then
    echo "ERROR: Nios II Command Shell not found."
    echo "Make sure Quartus/Nios II EDS is installed."
    exit 1
fi

# Go to the folder where THIS script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "============================================================"
echo " Nios II Command Shell"
echo " Directory: $SCRIPT_DIR"
echo "============================================================"
echo
echo "FIRST TIME? Run these commands:"
echo "  chmod +x *.sh"
echo "  dos2unix *.sh"
echo "  ./NIOS-II_Setup_Linux.sh"
echo
echo "ALREADY SET UP? Run:"
echo "  ./build.sh"
echo "  ./download.sh"
echo "  ./terminal.sh"
echo "============================================================"
echo

# Save project dir
export PROJECT_DIR="$SCRIPT_DIR"

# Go to Intel shell location
cd "$(dirname "$NIOS2_SHELL")"

# Start shell and force startup directory
export PROMPT_COMMAND='cd "$PROJECT_DIR"; unset PROMPT_COMMAND'

source ./nios2_command_shell.sh