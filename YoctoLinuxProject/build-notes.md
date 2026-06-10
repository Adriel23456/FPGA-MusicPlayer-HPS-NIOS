# Cyclone V GSRD — First-Time Linux Image Build (HPS) Setup

This is the **one-time setup** for building the DE1-SoC HPS Linux image from
scratch on a new build machine (`classic`). Everything project-specific is
already captured in the four `meta-de1soc-*` layers shipped in this repo — you
**copy and register** them, you do **not** recreate them.

After completing this guide once, all future rebuilds use **`quick-notes.md`**,
never this file again.

---

## What the four layers already contain

You do not regenerate any of this. It lives in the repo and is reused as-is:

| Layer | Provides | Type |
|-------|----------|------|
| `meta-de1soc-handoff` | Patched U-Boot (ECC disabled, IFWIDTH=32) for DE1-SoC DDR3 | `.bbappend` to `u-boot-socfpga` (+ kernel `devmem.cfg`) |
| `meta-de1soc-net` | Static IP `192.168.100.50` on `end0` via systemd-networkd | install recipe |
| `meta-de1soc-music` | `hps_music_player` daemon + bundled WAVs + systemd unit | install recipe |
| `meta-de1soc-fpga` | `soc_system.rbf` + DT overlay + systemd unit that auto-loads the FPGA at boot | install recipe |

Because the U-Boot DDR fix is baked into `meta-de1soc-handoff`, you never run
`devtool modify`, `cv_bsp_generator`, the ECC `sed` patches, or
`devtool update-recipe` again. They are history.

---

## Background: why Terasic SPL + Yocto

The GSRD `cyclone5` machine targets the Altera Cyclone V SoCDK, not the
DE1-SoC. Two differences matter:

1. **SPL/U-Boot** — even with our ECC/IFWIDTH patch, the most reliable DDR
   bring-up uses the **Terasic-provided SPL** (from their prebuilt image),
   calibrated for the exact DE1-SoC DDR3 layout. It goes on SD partition 3.
2. **Device Tree** — the GSRD only emits `socfpga_cyclone5_socdk.dtb`. The
   DE1-SoC needs `socfpga_cyclone5_de0_nano_soc.dtb` with the HPS↔FPGA bridge
   nodes set to `okay`.

**Solution:** Terasic SPL on partition 3 + our Yocto kernel/rootfs on
partitions 1 and 2, with a patched DTB.

---

## Prerequisites

- Terasic DE1-SoC prebuilt image `DE1_SoC_SD.img` (downloaded once, kept on the
  flashing machine `192.168.100.252`)
- The four `meta-de1soc-*` layers from this repo
- The embedded `soc_system.rbf` and compiled `fpga-load.dtbo` already placed in
  `meta-de1soc-fpga/recipes-bsp/fpga-autoload/files/`, and the prebuilt
  `hps_music_player` binary + WAVs in `meta-de1soc-music/.../files/`
- A 4 GB+ microSD card

---

# §0 — ONE-TIME SETUP  [ONCE — never repeat]

## 0.1 Clone the GSRD and fetch submodules

```bash
cd ~
git clone -b scarthgap https://github.com/altera-fpga/gsrd-socfpga.git
cd gsrd-socfpga
git submodule update --init --recursive
```

## 0.2 Download the Terasic image (for the working SPL)

```bash
wget http://download.terasic.com/downloads/cd-rom/de1-soc/linux_BSP/DE1_SoC_SD.zip
unzip DE1_SoC_SD.zip
# Keep DE1_SoC_SD.img and copy it to the flashing machine:
scp ~/DE1_SoC_SD.img adriel@192.168.100.252:~/
```

## 0.3 Drop the four project layers into the tree

Copy the layers from this project's repo into the GSRD tree (any path works;
inside `~/gsrd-socfpga` keeps everything together):

```bash
cp -r /path/to/repo/meta-de1soc-handoff ~/gsrd-socfpga/
cp -r /path/to/repo/meta-de1soc-net     ~/gsrd-socfpga/
cp -r /path/to/repo/meta-de1soc-music   ~/gsrd-socfpga/
cp -r /path/to/repo/meta-de1soc-fpga    ~/gsrd-socfpga/
```

## 0.4 Skip the GSRD reference bitstream

The GSRD `hw-ref-design` recipe fetches/builds an unused reference FPGA design
and can fail the build. Disable it (this lives in the GSRD layer, so a fresh
clone needs it once):

```bash
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
```

## 0.5 Enter the build environment and register the layers

```bash
cd ~/gsrd-socfpga
. poky/oe-init-build-env cyclone5-gsrd-rootfs

bitbake-layers add-layer ~/gsrd-socfpga/meta-de1soc-handoff
bitbake-layers add-layer ~/gsrd-socfpga/meta-de1soc-net
bitbake-layers add-layer ~/gsrd-socfpga/meta-de1soc-music
bitbake-layers add-layer ~/gsrd-socfpga/meta-de1soc-fpga

# Confirm all four are present:
bitbake-layers show-layers
```

## 0.6 Configure `local.conf`

This adds image features, the root password, the correct DTB, and installs the
three installable recipes (`meta-de1soc-handoff` is a U-Boot `.bbappend` and
applies automatically — it is **not** listed in `IMAGE_INSTALL`):

```bash
grep -q "ssh-server-dropbear" conf/local.conf || cat >> conf/local.conf << 'EOF'

IMAGE_FEATURES += "ssh-server-dropbear"
INHERIT += "extrausers"
EXTRA_USERS_PARAMS = "usermod -p '\$6\$q3kRl3o/yImgF0bP\$nNwm0VkLEeKd2QKEGwbK1DjwJ5QqjEjJvXwAcjDu4Cr0iexwoDbfTOOUKgKWqD7Zb6sJ4zThqOEEHTu5Bj.ai1' root;"
IMAGE_INSTALL:remove = "hw-ref-design"
KERNEL_DEVICETREE:cyclone5 = "intel/socfpga/socfpga_cyclone5_de0_nano_soc.dtb"
IMAGE_INSTALL:append = " de1soc-static-ip hps-music-player fpga-autoload"
EOF
```

## 0.7 Install the device tree compiler

```bash
sudo apt install device-tree-compiler
```

After §0 you never touch any of it again — re-clones aside, future work is
`quick-notes.md`.

---

# §1 — First build

> The first `bitbake core-image-minimal` also produces `mkimage`, which the WIC
> placeholder step below needs. If a step complains `mkimage` is missing on a
> truly empty tree, run the `bitbake core-image-minimal` line first, then come
> back to the placeholder block.

## 1.1 WIC placeholders (boot script + dummy rbf)

The kickstart expects these files to exist. Safe to re-run:

```bash
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

ln -sf socfpga_cyclone5_de0_nano_soc.dtb \
    tmp/deploy/images/cyclone5/socfpga_cyclone5_socdk.dtb 2>/dev/null || true
```

## 1.2 Build the recipes and image

```bash
# Build the project recipes (forces a clean pull of the layer files):
bitbake de1soc-static-ip -c cleansstate && bitbake de1soc-static-ip
bitbake hps-music-player  -c cleansstate && bitbake hps-music-player
bitbake fpga-autoload     -c cleansstate && bitbake fpga-autoload

# Build the full image:
bitbake core-image-minimal
```

## 1.3 (Optional) Build + install the SDK

Only if you need to cross-compile HPS apps (e.g. rebuild `hps_music_player`):

```bash
bitbake core-image-minimal -c populate_sdk
ls tmp/deploy/sdk/*.sh
./tmp/deploy/sdk/poky-glibc-x86_64-core-image-minimal-cortexa9t2hf-neon-toolchain-*.sh

# Per terminal where you cross-compile:
. /opt/poky/5.0.17/environment-setup-cortexa9t2hf-neon-poky-linux-gnueabi
```

---

# §2 — Patch the DTB (enable HPS↔FPGA bridges)

Required after **every** build — the DTB is regenerated each time.

```bash
DTB=tmp/deploy/images/cyclone5/socfpga_cyclone5_de0_nano_soc.dtb
dtc -I dtb -O dts $DTB -o /tmp/de0_nano.dts 2>/dev/null
sed -i '/fpga_bridge@ff400000/,/\};/{s/status = "disabled"/status = "okay"/}' /tmp/de0_nano.dts
sed -i '/fpga_bridge@ff500000/,/\};/{s/status = "disabled"/status = "okay"/}' /tmp/de0_nano.dts
sed -i '/fpga-bridge@ff600000/,/\};/{s/status = "disabled"/status = "okay"/}' /tmp/de0_nano.dts
dtc -I dts -O dtb /tmp/de0_nano.dts -o /tmp/de0_nano_enabled.dtb 2>/dev/null
cp /tmp/de0_nano_enabled.dtb $DTB
```

---

# §3 — Transfer to the flashing machine

```bash
scp tmp/deploy/images/cyclone5/core-image-minimal-cyclone5.rootfs.wic \
    adriel@192.168.100.252:~/
scp /tmp/de0_nano_enabled.dtb \
    adriel@192.168.100.252:~/socfpga_cyclone5_de0_nano_soc.dtb

# Save this checksum to verify after transfer:
md5sum tmp/deploy/images/cyclone5/core-image-minimal-cyclone5.rootfs.wic
```

---

# §4 — Flash the SD card

> ⚠️ **Destructive.** Run on the flashing machine. Confirm the device with
> `lsblk` first — `/dev/mmcblk0` is an example and will be erased.

```bash
ssh adriel@192.168.100.252

# Verify the image arrived intact (compare against §3):
md5sum ~/core-image-minimal-cyclone5.rootfs.wic

lsblk   # confirm which device is the SD card

sudo umount /dev/mmcblk0p* 2>/dev/null
sudo wipefs -a /dev/mmcblk0
sudo dd if=/dev/zero of=/dev/mmcblk0 bs=1M count=100 status=progress
sync

sudo bmaptool copy --nobmap ~/core-image-minimal-cyclone5.rootfs.wic /dev/mmcblk0
sync

# Terasic SPL on partition 3 (Yocto SPL fails DDR init):
sudo dd if=~/DE1_SoC_SD.img of=/dev/mmcblk0p3 bs=512 skip=2048 count=2048
sync

# Boot partition: patched DTB + extlinux:
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

# §5 — Boot & verify (no JTAG, fully automatic)

Insert the card and power the board. The FPGA is programmed by
`fpga-autoload` a couple of seconds into Linux boot, before the daemon starts —
**no Quartus Programmer, no `download.sh`**.

```bash
# Reach the board (static IP from meta-de1soc-net):
ssh root@192.168.100.50        # password: 1234

# Static IP applied?
networkctl status end0                 # expect 192.168.100.50

# FPGA programmed automatically?
cat /sys/class/fpga_manager/fpga0/state    # expect: operating
cat /sys/class/fpga_bridge/br1/state       # expect: enabled
systemctl status fpga-load.service         # active (exited)

# Daemon running after the fabric came up?
systemctl status hps_music_player
journalctl -u hps_music_player             # "shared mem mapped", "songs=N"

# Songs bundled?
ls -l /mnt/music
```

If `fpga0/state` reads `operating` on a cold boot with you doing nothing, the
full HPS+FPGA stack is live from power-on.

---

## After this guide

This file is first-time setup only. For every subsequent rebuild/reflash
(changed a recipe, the daemon, the rbf, or `local.conf`), use **`quick-notes.md`** — you do **not** repeat §0.