# Nios II Complete Workflow

## What You Get

Two files to start with — place both in the **same folder**
(e.g. `SoftwareDevelopment/NIOS-II/`):

```
open_shell.bat        ← double-click from Windows to open the shell
NIOS-II_setup.sh      ← run ONCE inside the shell to configure everything
```

After setup, these are generated automatically in the same folder:

```
new_project.sh        ← generate BSP + Makefile (run once)
update_makefile.sh    ← rescan .c/.h files, regenerate Makefile
build.sh              ← compile the application
download.sh           ← load .elf onto FPGA via JTAG
terminal.sh           ← open Nios II terminal (printf output)
rebuild_bsp.sh        ← regenerate BSP after hardware changes
```

---

## Project Layout Expected

```
FPGA-MusicPlayer-HPS-NIOS/
├── MusicPlayerQuartus/
│   ├── MusicPlayerPlatformDesign.sopcinfo   ← path you give to setup
│   └── ...
└── SoftwareDevelopment/
    └── NIOS-II/                             ← SW root, place files here
        ├── open_shell.bat
        ├── NIOS-II_setup.sh
        └── app/
            ├── src/
            ├── lib/
            └── include/
```

---

## First Time Setup

### Step 1 — Open the shell

Double-click `open_shell.bat`.

This opens the **Nios II Command Shell** (bash) already `cd`'d
to the folder where the `.bat` lives.

### Step 2 — Fix permissions and run setup

Inside the shell:

```bash
chmod +x NIOS-II_setup.sh
./NIOS-II_setup.sh
```

It will ask three questions:

```
SOPCINFO path:
  → /mnt/d/Escritorio/FPGA-MusicPlayer-HPS-NIOS/MusicPlayerQuartus/MusicPlayerPlatformDesign.sopcinfo

Software root path:
  → /mnt/d/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II

CPU name [CPU_NIOS_II]:
  → (press Enter to accept default)
```

**Use bash-style paths** (`/mnt/d/...`), not Windows paths (`D:\...`).

After answering, setup will:
- Create `app/src/`, `app/lib/`, `app/include/`
- Write a starter `hello_world.c`
- Generate all `.sh` scripts with `chmod +x` already applied

### Step 3 — Generate BSP and Makefile

```bash
./new_project.sh
```

This runs three things internally:
1. `nios2-bsp hal` → generates `bsp/` with `system.h`, drivers, linker script
2. `nios2-app-generate-makefile` → generates `app/Makefile`
3. `make -C bsp` → compiles the BSP library

---

## Every Time You Change Code

```bash
# 1. Edit your .c files (in app/, app/src/, app/lib/)
# 2. Compile
./build.sh

# 3. Make sure FPGA is programmed (Quartus Programmer → .sof)
# 4. Load the ELF
./download.sh

# 5. See output
./terminal.sh
```

---

## When You Add New Source Files

```bash
# 1. Add your_file.c to app/src/
# 2. Add your_file.h to app/include/
# 3. Re-generate the Makefile
./update_makefile.sh
# 4. Rebuild
./build.sh
```

---

## When Hardware Changes (Platform Designer edit)

```bash
# 1. Platform Designer → Generate HDL
# 2. Quartus → Processing → Start Compilation
# 3. Quartus → Tools → Programmer → reprogram .sof
# 4. Regenerate BSP
./rebuild_bsp.sh
# 5. Recompile app
./build.sh
# 6. Download
./download.sh
```

Your source code in `app/` is never touched by `rebuild_bsp.sh`.

---

## Using Eclipse IDE (optional)

Instead of `./download.sh`, you can use Eclipse for debugging:

```
Quartus → Tools → Nios II Software Build Tools for Eclipse
File → Import → General → Existing Projects into Workspace
→ Browse to your SW_ROOT folder
→ Select both the app and bsp projects → Finish

Right-click app → Build Project        (= ./build.sh)
Right-click app → Run As → Nios II Hardware   (= ./download.sh)
```

Terminal output still works with `./terminal.sh` or via
`Quartus → Tools → Nios II Command Shell → nios2-terminal`.

---

## Script Reference

| Script | Run from | When |
|---|---|---|
| `open_shell.bat` | Windows (double-click) | Any time you need the shell |
| `NIOS-II_setup.sh` | Shell | Once per project |
| `./new_project.sh` | Shell | Once after setup |
| `./update_makefile.sh` | Shell | Every time you add .c or .h files |
| `./build.sh` | Shell | Every time you change code |
| `./download.sh` | Shell | Every time you want to run on FPGA |
| `./terminal.sh` | Shell | To see printf/alt_putstr output |
| `./rebuild_bsp.sh` | Shell | After any Platform Designer change |

---

## Common Errors

**`nios2-bsp: Can't find SOPC design file`**
→ The `.sopcinfo` path is wrong. Double-check it exists at the path you provided.
→ Remember to use bash paths: `/mnt/d/...` not `D:\...`

**`./new_project.sh: Permission denied`**
→ Run `chmod +x *.sh` first.

**`bad interpreter: No such file or directory`**
→ Windows line endings in the .sh file. Run `dos2unix *.sh` then retry.

**`nios2-download: No JTAG device`**
→ FPGA not programmed yet. Run Quartus Programmer first, then `./download.sh`.