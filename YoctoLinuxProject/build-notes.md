# Yocto: DE1-SoC HPS ARM Cortex-A9 — Linux Image Build Guide

This guide is organized around **what you actually need to do right now**.
Pick your scenario in the table below and follow only that section.

Before anything: every section after Section 0 assumes the **one-time setup
in Section 0 has already been completed exactly once on the build machine
(`classic`)**. If it hasn't, do Section 0 first — it is never repeated.

---

## How to use this guide — pick your scenario

| Your situation | Go to |
|----------------|-------|
| 0. Brand-new build machine, nothing set up yet | **§0 One-Time Setup** (run once, ever) |
| 1. I only need the SDK so I can cross-compile apps for the image | **§1 Build SDK only** |
| 2. I need to build the image, but NOT flash it to the SD card | **§2 Build image (no flashing)** |
| 3. I need image + SDK, and to burn it onto the microSD | **§2 + §1 + §3** (build, build SDK, flash) |
| 4. Already built before, but changed something and must rebuild | **§4 Rebuild after changes** |

Legend used throughout:
- **[ONCE]** — run a single time, ever. Never repeat.
- **[EACH BUILD]** — run every time you produce a new image/SDK.
- **[EACH FLASH]** — run every time you write a card.

---

## Background: Why We Mix Terasic + Yocto

The GSRD (Golden System Reference Design) `cyclone5` machine targets the
**Altera Cyclone V SoCDK** reference board, not the DE1-SoC. Two critical
differences:

1. **SPL/U-Boot** — The Yocto-built SPL fails DDR initialization on the
   DE1-SoC because the handoff config has ECC enabled, but the DE1-SoC has no
   ECC DRAM hardware. The Terasic-provided SPL (from their prebuilt Linux
   image) is calibrated for the exact DE1-SoC DDR3 layout and works reliably.
2. **Device Tree** — The GSRD only produces `socfpga_cyclone5_socdk.dtb`. The
   DE1-SoC requires `socfpga_cyclone5_de0_nano_soc.dtb` (hardware-compatible)
   with bridge nodes enabled and the correct boot arguments.

**Solution:** Terasic SPL on partition 3 + our Yocto kernel/rootfs on
partitions 1 and 2, with a patched DTB and a custom boot script.

---

## Prerequisites

- Terasic DE1-SoC Linux prebuilt image: `DE1_SoC_SD.img` (downloaded once,
  kept on the remote/flashing machine)
- A 4 GB+ microSD card

---

# §0 — ONE-TIME SETUP  [ONCE — never run again]

Run this **exactly once** on the build machine (`classic`). Everything here is
permanent setup: cloning the repo, downloading the Terasic image, patching the
U-Boot handoff for DE1-SoC DDR, and creating the handoff layer. If you have
already done this, skip straight to your scenario section.

```bash
# --- Clone official Altera GSRD repo ---
cd ~
git clone -b scarthgap https://github.com/altera-fpga/gsrd-socfpga.git
cd gsrd-socfpga
git submodule update --init --recursive

# --- Download Terasic prebuilt image (needed for the working SPL) ---
wget http://download.terasic.com/downloads/cd-rom/de1-soc/linux_BSP/DE1_SoC_SD.zip
unzip DE1_SoC_SD.zip
# Keep DE1_SoC_SD.img — copy it to the remote/flashing machine too:
scp ~/DE1_SoC_SD.img adriel@192.168.100.252:~/

# --- Patch hw-ref-design to skip FPGA bitstream download ---
cat > ~/gsrd-socfpga/meta-intel-fpga-refdes/recipes-bsp/ghrd/hw-ref-design.bbappend << 'EOF'
SRC_URI:cyclone5 = ""
do_fetch[noexec] = "1"
do_unpack[noexec] = "1"
do_patch[noexec] = "1"
do_configure[noexec] = "1"
do_compile[noexec] = "1"
do_install[noexec] = "1"
do_package[noexec] = "1"
do_packagedata[noexec] = "1"
do_package_write_rpm[noexec] = "1"
do_deploy[noexec] = "1"
PACKAGES = ""
FILES = ""
EOF

# --- Patch U-Boot handoff: disable ECC and fix IFWIDTH for DE1-SoC DDR ---
cd ~/gsrd-socfpga
. poky/oe-init-build-env cyclone5-gsrd-rootfs
devtool modify virtual/bootloader
cd ~/gsrd-socfpga/cyclone5-gsrd-rootfs/workspace/sources/u-boot-socfpga

python3 arch/arm/mach-socfpga/cv_bsp_generator/cv_bsp_generator.py \
    -i /path/to/your/quartus/hps_isw_handoff/HPS_ARM_component \
    -o board/altera/cyclone5-socdk/qts

# Disable ECC (DE1-SoC has no ECC DRAM) and set 32-bit IF width:
sed -i 's/#define CFG_HPS_SDR_CTRLCFG_CTRLCFG_ECCEN.*$/#define CFG_HPS_SDR_CTRLCFG_CTRLCFG_ECCEN\t\t\t\t0/' board/altera/cyclone5-socdk/qts/sdram_config.h
sed -i 's/#define CFG_HPS_SDR_CTRLCFG_CTRLCFG_ECCCORREN.*$/#define CFG_HPS_SDR_CTRLCFG_CTRLCFG_ECCCORREN\t\t\t0/' board/altera/cyclone5-socdk/qts/sdram_config.h
sed -i 's/#define CFG_HPS_SDR_CTRLCFG_DRAMIFWIDTH_IFWIDTH.*$/#define CFG_HPS_SDR_CTRLCFG_DRAMIFWIDTH_IFWIDTH\t\t\t32/' board/altera/cyclone5-socdk/qts/sdram_config.h

git add board/altera/cyclone5-socdk/qts/
git commit -m "DE1-SoC: disable ECC, set IFWIDTH=32"

# --- Capture the patched U-Boot into a permanent handoff layer ---
cd ~/gsrd-socfpga/cyclone5-gsrd-rootfs
bitbake-layers create-layer ~/gsrd-socfpga/meta-de1soc-handoff
devtool update-recipe -a ~/gsrd-socfpga/meta-de1soc-handoff u-boot-socfpga
bitbake-layers add-layer ~/gsrd-socfpga/meta-de1soc-handoff
bitbake-layers remove-layer ~/gsrd-socfpga/cyclone5-gsrd-rootfs/workspace

# --- Install device tree compiler ---
sudo apt install device-tree-compiler
```

After §0 you never touch `devtool modify`, `cv_bsp_generator`, the ECC
`sed` patches, or the layer creation again. They are baked into
`meta-de1soc-handoff`.

---

# §A — Enter the build environment  [EACH BUILD — every new terminal]

Any time you open a fresh terminal on `classic` to build anything (image or
SDK), you must source the environment first. This is **per-terminal**, not
per-machine — it is not setup, it just activates the toolchain in the current
shell.

```bash
cd ~/gsrd-socfpga
. poky/oe-init-build-env cyclone5-gsrd-rootfs
```

Every scenario below assumes you have done §A in the current terminal.

---

# §B — Configure local.conf + WIC placeholders  [EACH BUILD, idempotent]

These steps prepare `local.conf` and the WIC placeholder files the build
expects. They are written to be **safe to re-run every build** — the
`local.conf` append is guarded by `grep -q` so it won't duplicate, and the
placeholder/symlink steps simply overwrite. Run this block before any
`bitbake` of the image.

```bash
# Append config to local.conf only if not already present:
grep -q "ssh-server-dropbear" conf/local.conf || cat >> conf/local.conf << 'EOF'

IMAGE_FEATURES += "ssh-server-dropbear"
INHERIT += "extrausers"
EXTRA_USERS_PARAMS = "usermod -p '\$6\$q3kRl3o/yImgF0bP\$nNwm0VkLEeKd2QKEGwbK1DjwJ5QqjEjJvXwAcjDu4Cr0iexwoDbfTOOUKgKWqD7Zb6sJ4zThqOEEHTu5Bj.ai1' root;"
IMAGE_INSTALL:remove = "hw-ref-design"
KERNEL_DEVICETREE:cyclone5 = "intel/socfpga/socfpga_cyclone5_de0_nano_soc.dtb"
EOF

# Create required WIC placeholder files (boot script + dummy rbf):
MKIMAGE=$(find ~/gsrd-socfpga/cyclone5-gsrd-rootfs/tmp -name mkimage -type f 2>/dev/null | head -1)
cat > /tmp/cyclone5_boot.txt << 'EOF'
fatload mmc 0:1 ${loadaddr} zImage
fatload mmc 0:1 ${fdtaddr} socfpga_cyclone5_de0_nano_soc.dtb
setenv bootargs console=ttyS0,115200 root=/dev/mmcblk0p2 rw rootwait earlyprintk iomem=relaxed
bootz ${loadaddr} - ${fdtaddr}
EOF
$MKIMAGE -T script -A arm -O linux -C none -n "Boot Script" \
    -d /tmp/cyclone5_boot.txt \
    tmp/deploy/images/cyclone5/u-boot.scr
mkdir -p tmp/deploy/images/cyclone5/cyclone5_gsrd_ghrd/
touch tmp/deploy/images/cyclone5/cyclone5_gsrd_ghrd/soc_system.rbf

# Fix WIC symlink (the kickstart expects the socdk DTB name):
ln -sf socfpga_cyclone5_de0_nano_soc.dtb \
    tmp/deploy/images/cyclone5/socfpga_cyclone5_socdk.dtb 2>/dev/null || true
```

> Note: `$MKIMAGE` finds an existing `mkimage` under `tmp/`. On a brand-new
> tree where nothing has been built yet, `mkimage` may not exist until the
> first `bitbake core-image-minimal` runs. If `$MKIMAGE` is empty on a fresh
> tree, run the `bitbake core-image-minimal` step in §2 first, then re-run
> this §B block to generate `u-boot.scr`.

---

# §1 — BUILD SDK ONLY

> Use when: you just need the cross-compiler to build HPS apps (e.g.
> `fpga_test`) and the image already exists / isn't your concern right now.

Prereqs: §0 done once, §A in this terminal.

```bash
# (No §B needed for the SDK alone, but it is harmless if already run.)
bitbake core-image-minimal -c populate_sdk
ls tmp/deploy/sdk/*.sh
```

Install the SDK (run the produced `.sh` installer once per machine where you
want to cross-compile):

```bash
# example installer name; use whatever ls printed:
./tmp/deploy/sdk/poky-glibc-x86_64-core-image-minimal-cortexa9t2hf-neon-toolchain-*.sh
```

Then, to cross-compile in any terminal, source the SDK environment
**[EACH terminal where you cross-compile]**:

```bash
. /opt/poky/5.0.17/environment-setup-cortexa9t2hf-neon-poky-linux-gnueabi
```

---

# §2 — BUILD IMAGE (no flashing)

> Use when: you want a fresh `.wic` image + patched DTB on the build machine,
> but you are NOT writing a card right now.

Prereqs: §0 done once, §A in this terminal, then §B.

```bash
# 1) Build the image:
bitbake core-image-minimal

# 2) Patch the DTB to enable HPS-to-FPGA bridges  [EACH BUILD]
#    (the build regenerates the DTB, so this must run after every build):
DTB=tmp/deploy/images/cyclone5/socfpga_cyclone5_de0_nano_soc.dtb
dtc -I dtb -O dts $DTB -o /tmp/de0_nano.dts 2>/dev/null
sed -i '/fpga_bridge@ff400000/,/\};/{s/status = "disabled"/status = "okay"/}' /tmp/de0_nano.dts
sed -i '/fpga_bridge@ff500000/,/\};/{s/status = "disabled"/status = "okay"/}' /tmp/de0_nano.dts
sed -i '/fpga-bridge@ff600000/,/\};/{s/status = "disabled"/status = "okay"/}' /tmp/de0_nano.dts
dtc -I dts -O dtb /tmp/de0_nano.dts -o /tmp/de0_nano_enabled.dtb 2>/dev/null
cp /tmp/de0_nano_enabled.dtb $DTB

# 3) Transfer image + patched DTB to the flashing machine:
scp tmp/deploy/images/cyclone5/core-image-minimal-cyclone5.rootfs.wic \
    adriel@192.168.100.252:~/
scp /tmp/de0_nano_enabled.dtb adriel@192.168.100.252:~/socfpga_cyclone5_de0_nano_soc.dtb

# 4) Record the checksum so you can verify it on the flashing machine:
md5sum tmp/deploy/images/cyclone5/core-image-minimal-cyclone5.rootfs.wic
```

Stop here if you only needed the image. To also flash it, continue to §3.

---

# §3 — FLASH IMAGE TO microSD

> Use when: you have a built `.wic` + patched DTB transferred to the flashing
> machine and want to write a bootable card.

Prereqs: §2 completed (image + DTB are on `192.168.100.252:~/`), and the
Terasic `DE1_SoC_SD.img` is present there (copied during §0).

**⚠ Destructive:** these commands erase the target device. Confirm the device
name with `lsblk` before running — `/dev/mmcblk0` below is an example.

```bash
ssh adriel@192.168.100.252

# Verify the image arrived intact (compare against §2 step 4):
md5sum ~/core-image-minimal-cyclone5.rootfs.wic

# Identify the card and unmount any auto-mounted partitions:
lsblk
sudo umount /dev/mmcblk0p* 2>/dev/null
echo "done"

# Wipe and flash:
sudo wipefs -a /dev/mmcblk0
sudo dd if=/dev/zero of=/dev/mmcblk0 bs=1M count=100 status=progress
sync
sudo bmaptool copy --nobmap ~/core-image-minimal-cyclone5.rootfs.wic /dev/mmcblk0
sync

# Replace partition 3 with Terasic's working SPL (Yocto SPL fails DDR init):
sudo dd if=~/DE1_SoC_SD.img of=/dev/mmcblk0p3 bs=512 skip=2048 count=2048
sync

# Fix the boot partition: copy patched DTB + write extlinux config:
sudo mkdir -p /mnt/sdboot
sudo mount /dev/mmcblk0p1 /mnt/sdboot
sudo cp ~/socfpga_cyclone5_de0_nano_soc.dtb /mnt/sdboot/
sudo tee /mnt/sdboot/extlinux/extlinux.conf << 'EOF'
LABEL Linux Default
    KERNEL ../zImage
    FDT ../socfpga_cyclone5_de0_nano_soc.dtb
    APPEND root=/dev/mmcblk0p2 rw rootwait console=ttyS0,115200n8 earlyprintk iomem=relaxed
EOF
sync
sudo umount /mnt/sdboot
```

---

# §4 — REBUILD AFTER CHANGES

> Use when: you already built before (§0 is long done) and you changed
> something — a recipe, `local.conf`, app source, the kernel, etc. — and need
> a fresh image and/or SDK.

You do **NOT** repeat §0. You only re-run the per-build steps. Pick the rows
that match what you changed:

| What you changed | Re-run |
|------------------|--------|
| Image content / recipes / `local.conf` | §A → §B → §2 |
| App source you cross-compile (not the image) | §A → §1 (SDK already installed? just recompile with the SDK env) |
| Image AND you want a new SDK too | §A → §B → §2 → §1 |
| You want to reflash the new image | the above, then §3 |

Concretely, the common case (changed the image, want it flashed):

```bash
# fresh terminal on classic
cd ~/gsrd-socfpga
. poky/oe-init-build-env cyclone5-gsrd-rootfs        # §A

# §B (idempotent local.conf + WIC placeholders) — safe to re-run
grep -q "ssh-server-dropbear" conf/local.conf || cat >> conf/local.conf << 'EOF'

IMAGE_FEATURES += "ssh-server-dropbear"
INHERIT += "extrausers"
EXTRA_USERS_PARAMS = "usermod -p '\$6\$q3kRl3o/yImgF0bP\$nNwm0VkLEeKd2QKEGwbK1DjwJ5QqjEjJvXwAcjDu4Cr0iexwoDbfTOOUKgKWqD7Zb6sJ4zThqOEEHTu5Bj.ai1' root;"
IMAGE_INSTALL:remove = "hw-ref-design"
KERNEL_DEVICETREE:cyclone5 = "intel/socfpga/socfpga_cyclone5_de0_nano_soc.dtb"
EOF

bitbake core-image-minimal                            # §2 build

# DTB bridge patch — ALWAYS after a build, the DTB is regenerated:
DTB=tmp/deploy/images/cyclone5/socfpga_cyclone5_de0_nano_soc.dtb
dtc -I dtb -O dts $DTB -o /tmp/de0_nano.dts 2>/dev/null
sed -i '/fpga_bridge@ff400000/,/\};/{s/status = "disabled"/status = "okay"/}' /tmp/de0_nano.dts
sed -i '/fpga_bridge@ff500000/,/\};/{s/status = "disabled"/status = "okay"/}' /tmp/de0_nano.dts
sed -i '/fpga-bridge@ff600000/,/\};/{s/status = "disabled"/status = "okay"/}' /tmp/de0_nano.dts
dtc -I dts -O dtb /tmp/de0_nano.dts -o /tmp/de0_nano_enabled.dtb 2>/dev/null
cp /tmp/de0_nano_enabled.dtb $DTB

# transfer + checksum (§2)
scp tmp/deploy/images/cyclone5/core-image-minimal-cyclone5.rootfs.wic adriel@192.168.100.252:~/
scp /tmp/de0_nano_enabled.dtb adriel@192.168.100.252:~/socfpga_cyclone5_de0_nano_soc.dtb
md5sum tmp/deploy/images/cyclone5/core-image-minimal-cyclone5.rootfs.wic

# then §3 on the flashing machine to write the card
```

> Tip: if a rebuild misbehaves, `bitbake -c cleansstate core-image-minimal`
> then rebuild — but that's a recovery step, not a routine one.

---

# §5 — Boot + verify the HPS↔FPGA bridge  [after flashing]

Boot the DE1-SoC with the card inserted, then:

```bash
# From classic, discover the board IP:
sudo nmap -sn 192.168.100.0/24

ssh root@<de1soc-ip>      # password: 1234
```

Program the FPGA with your `.sof` via Quartus Programmer (JTAG) first, then on
the board:

```bash
# Check bridge state (should be enabled):
cat /sys/class/fpga_bridge/br1/name    # hps2fpga
cat /sys/class/fpga_bridge/br1/state   # enabled

# RAM read/write test (see §6 to build fpga_test):
/tmp/fpga_test
# Before write: 0x????????
# After write:  0xDEADBEEF
```

---

# §6 — Build the fpga_test mmap tool  [ONCE, needs SDK from §1]

Build this once on `classic` with the SDK environment sourced, then copy it to
the board. Rebuild only if you change the test itself.

```bash
. /opt/poky/5.0.17/environment-setup-cortexa9t2hf-neon-poky-linux-gnueabi

cat > /tmp/fpga_test.c << 'EOF'
#include <stdio.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <stdint.h>

#define H2F_BASE   0xC0000000
#define RAM_OFFSET 0x40000
#define MAP_SIZE   0x100000

int main() {
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) { perror("open"); return 1; }
    void *map = mmap(NULL, MAP_SIZE, PROT_READ|PROT_WRITE,
                     MAP_SHARED, fd, H2F_BASE + RAM_OFFSET);
    if (map == MAP_FAILED) { perror("mmap"); return 1; }
    volatile uint32_t *mem = (volatile uint32_t *)map;
    printf("Before write: 0x%08X\n", mem[0]);
    mem[0] = 0xDEADBEEF;
    printf("After write:  0x%08X\n", mem[0]);
    munmap(map, MAP_SIZE);
    return 0;
}
EOF

$CC /tmp/fpga_test.c -o /tmp/fpga_test
scp /tmp/fpga_test root@<de1soc-ip>:/tmp/
```

---

## Quick reference — what runs when

| Step | Frequency |
|------|-----------|
| §0 clone, Terasic download, U-Boot ECC/IFWIDTH patch, handoff layer | **ONCE ever** |
| `apt install device-tree-compiler` | **ONCE ever** |
| §A source `oe-init-build-env` | **every new terminal** |
| §B local.conf append (grep-guarded) + WIC placeholders | **every build (idempotent)** |
| `bitbake core-image-minimal` | **every image build** |
| DTB bridge enable patch | **every image build (DTB is regenerated)** |
| scp image/DTB + md5sum | **every build you intend to flash** |
| `bitbake ... -c populate_sdk` | **when you need/refresh the SDK** |
| SDK installer `.sh` | **once per machine that cross-compiles** |
| source SDK `environment-setup-...` | **every terminal that cross-compiles** |
| §3 dd/bmaptool/SPL/extlinux | **every flash** |
| §6 build `fpga_test` | **once (rebuild only if changed)** |