# Quartus 22.1.2 — Linux Setup (Nios II)

> **Linux only.** This project is developed entirely on native Ubuntu.
> No Windows, no WSL, no `.exe` tools. All Nios II compilation is done with
> the numbered shell scripts (see `NIOS-II_Workflow.md`) — **not Eclipse**.

---

## 1. Downloads

| Package | Link |
|---|---|
| Quartus Prime Lite 22.1.2 (Linux) + Cyclone V device support | https://www.altera.com/downloads/fpga-development-tools/quartus-prime-lite-edition-design-software-version-22-1-2-linux |
| ModelSim-Intel FPGA Starter Edition (from the 20.1.1 Linux package — 22.1 no longer bundles ModelSim ASE) | https://www.altera.com/downloads/fpga-development-tools/quartus-prime-lite-edition-design-software-version-20-1-1-linux |

From the 22.1.2 page download:
- `QuartusLiteSetup-22.1std.2.922-linux.run`
- `cyclonev-22.1std.2.922.qdz` (Cyclone V device support)

Place both files in the **same folder** — the installer picks up the `.qdz`
automatically.

---

## 2. Install Quartus

```bash
chmod +x QuartusLiteSetup-22.1std.2.922-linux.run
./QuartusLiteSetup-22.1std.2.922-linux.run
```

In the installer:
- Install directory: `~/intelFPGA_lite/22.1std` (the default — the Nios II
  scripts auto-detect this path, do not change it)
- Components: **Quartus Prime Lite**, **Cyclone V device support**,
  **Nios II EDS** (required by `01Setup.sh`)
- Do **not** run with `sudo` — a home install avoids permission issues.

Install ModelSim from the 20.1.1 package into the 22.1 tree so it lands at
the path the scripts expect:

```bash
chmod +x ModelSimSetup-20.1.1.720-linux.run
./ModelSimSetup-20.1.1.720-linux.run
# Install directory: ~/intelFPGA_lite/22.1std
# Result: ~/intelFPGA_lite/22.1std/modelsim_ase/
```

---

## 3. ModelSim 32-bit Dependencies

ModelSim ASE is a 32-bit binary — it will not start on a clean 64-bit Ubuntu
without the i386 libraries:

```bash
sudo dpkg --add-architecture i386
sudo apt update

sudo apt install -y \
    libc6:i386 \
    libstdc++6:i386 \
    libncurses5:i386 \
    zlib1g:i386 \
    libx11-6:i386 \
    libxext6:i386 \
    libxft2:i386 \
    libxrender1:i386 \
    libxtst6:i386 \
    libxi6:i386
```

General build tools (needed by the BSP/app Makefiles):

```bash
sudo apt install -y make build-essential
```

---

## 4. JTAG / USB-Blaster Permissions

Without a udev rule, `jtagconfig` and `nios2-download` only work as root.
Create the rule once:

```bash
sudo nano /etc/udev/rules.d/51-usbblaster.rules
```

Content:

```
SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6001", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6810", MODE="0666"
```

Reload and verify with the board connected and powered:

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger

~/intelFPGA_lite/22.1std/quartus/bin/jtagconfig
# Expect: 1) DE-SoC [...]  with the SOCVHPS and 5CSEBA6 devices listed
```

---

## 5. Quartus Configuration

- **ModelSim path** — Quartus → Tools → Options → EDA Tool Options:

  ```
  ModelSim-Altera = ~/intelFPGA_lite/22.1std/modelsim_ase/bin
  ```

- **Fitter TCL scripts** — remember to run the project's TCL scripts for
  **Fitter (Place & Route)** when compiling the hardware
  (Assignments → Settings → EDA Tool Settings / TCL Scripts, as configured
  in the Quartus project).

---

## 6. Running ModelSim Simulations

After `./04Build.sh` + `./08RunSim.sh` (see `NIOS-II_Workflow.md`), launch
ModelSim from the mentor testbench folder:

```bash
cd <project>/MusicPlayerPlatformDesign/testbench/mentor
~/intelFPGA_lite/22.1std/modelsim_ase/bin/vsim
```

Inside ModelSim (Transcript panel):

```tcl
do msim_setup.tcl
ld_debug
add wave *
run 2.5ms
```

---

## 7. Troubleshooting

**ModelSim won't start / `vsim: not found` / missing `libX*` errors**
→ The i386 dependencies from §3 are missing.

**`jtagconfig: No JTAG hardware available`**
→ udev rule missing or not reloaded (§4), board off, or USB-Blaster cable
  on a different port. Re-run `udevadm trigger` and replug the cable.

**Nios II tools not found (`nios2-bsp`, `elf2hex`, ...)**
→ Nios II EDS wasn't selected during install, or Quartus was installed
  outside `~/intelFPGA_lite/22.1std` — `01Setup.sh` auto-detection fails.
  Re-run the installer or point `01Setup.sh` to the correct GCC path.

**Installer fails to launch (`cannot execute`)**
→ Missing `chmod +x`, or the download is incomplete — re-download and
  compare the file size against the download page.