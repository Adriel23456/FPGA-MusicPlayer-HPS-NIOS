# Yocto: DE1-SoC HPS ARM Cortex-A9 — Linux Image Build Guide

## Background: Why We Mix Terasic + Yocto

The GSRD (Golden System Reference Design) `cyclone5` machine targets the **Altera Cyclone V SoCDK**
reference board, not the DE1-SoC. Two critical differences:

1. **SPL/U-Boot**: The Yocto-built SPL fails DDR initialization on the DE1-SoC because the
   handoff-generated config has ECC enabled, but the DE1-SoC has no ECC DRAM hardware. The
   Terasic-provided SPL (from their prebuilt Linux image) is calibrated for the exact DE1-SoC
   DDR3 layout and works reliably.

2. **Device Tree**: The GSRD only produces `socfpga_cyclone5_socdk.dtb` (for the SoCDK). The
   DE1-SoC requires `socfpga_cyclone5_de0_nano_soc.dtb` (hardware-compatible) with bridge
   nodes manually enabled and the correct boot arguments.

**Solution**: Use the Terasic SPL on partition 3 + our Yocto kernel/rootfs on partitions 1 and 2,
with a patched DTB and a custom boot script.

---

## Prerequisites

- Terasic DE1-SoC Linux prebuilt image: `DE1_SoC_SD.img` (downloaded once, kept on the
  remote/flashing machine)
- A 4GB+ microSD card

---

## ONE-TIME SETUP (only run once, on classic):

```bash
# Clone official Altera GSRD repo
cd ~
git clone -b scarthgap https://github.com/altera-fpga/gsrd-socfpga.git
cd gsrd-socfpga
git submodule update --init --recursive

# Download Terasic prebuilt image (needed for working SPL)
wget http://download.terasic.com/downloads/cd-rom/de1-soc/linux_BSP/DE1_SoC_SD.zip
unzip DE1_SoC_SD.zip
# Keep DE1_SoC_SD.img — copy it to the remote/flashing machine too:
scp ~/DE1_SoC_SD.img adriel@192.168.100.252:~/

# Patch hw-ref-design to skip FPGA bitstream download
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

# Patch U-Boot handoff: disable ECC and fix IFWIDTH for DE1-SoC DDR
cd ~/gsrd-socfpga
. poky/oe-init-build-env cyclone5-gsrd-rootfs
devtool modify virtual/bootloader
cd ~/gsrd-socfpga/cyclone5-gsrd-rootfs/workspace/sources/u-boot-socfpga

python3 arch/arm/mach-socfpga/cv_bsp_generator/cv_bsp_generator.py \
    -i /path/to/your/quartus/hps_isw_handoff/HPS_ARM_component \
    -o board/altera/cyclone5-socdk/qts

# Disable ECC (DE1-SoC has no ECC DRAM):
sed -i 's/#define CFG_HPS_SDR_CTRLCFG_CTRLCFG_ECCEN.*$/#define CFG_HPS_SDR_CTRLCFG_CTRLCFG_ECCEN\t\t\t\t0/' board/altera/cyclone5-socdk/qts/sdram_config.h
sed -i 's/#define CFG_HPS_SDR_CTRLCFG_CTRLCFG_ECCCORREN.*$/#define CFG_HPS_SDR_CTRLCFG_CTRLCFG_ECCCORREN\t\t\t0/' board/altera/cyclone5-socdk/qts/sdram_config.h
sed -i 's/#define CFG_HPS_SDR_CTRLCFG_DRAMIFWIDTH_IFWIDTH.*$/#define CFG_HPS_SDR_CTRLCFG_DRAMIFWIDTH_IFWIDTH\t\t\t32/' board/altera/cyclone5-socdk/qts/sdram_config.h

git add board/altera/cyclone5-socdk/qts/
git commit -m "DE1-SoC: disable ECC, set IFWIDTH=32"

cd ~/gsrd-socfpga/cyclone5-gsrd-rootfs
bitbake-layers create-layer ~/gsrd-socfpga/meta-de1soc-handoff
devtool update-recipe -a ~/gsrd-socfpga/meta-de1soc-handoff u-boot-socfpga
bitbake-layers add-layer ~/gsrd-socfpga/meta-de1soc-handoff
bitbake-layers remove-layer ~/gsrd-socfpga/cyclone5-gsrd-rootfs/workspace

# Install device tree compiler
sudo apt install device-tree-compiler
```

---

## ON classic (build machine — every new build):

```bash
# Re-enter build environment in a new terminal:
cd ~/gsrd-socfpga
. poky/oe-init-build-env cyclone5-gsrd-rootfs

# Append config to local.conf (check it isn't already there first):
grep -q "ssh-server-dropbear" conf/local.conf || cat >> conf/local.conf << 'EOF'

IMAGE_FEATURES += "ssh-server-dropbear"
INHERIT += "extrausers"
EXTRA_USERS_PARAMS = "usermod -p '\$6\$q3kRl3o/yImgF0bP\$nNwm0VkLEeKd2QKEGwbK1DjwJ5QqjEjJvXwAcjDu4Cr0iexwoDbfTOOUKgKWqD7Zb6sJ4zThqOEEHTu5Bj.ai1' root;"
IMAGE_INSTALL:remove = "hw-ref-design"
KERNEL_DEVICETREE:cyclone5 = "intel/socfpga/socfpga_cyclone5_de0_nano_soc.dtb"
EOF

# Create required WIC placeholder files:
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

# Fix WIC symlink (socdk DTB symlink needed by WIC kickstart):
ln -sf socfpga_cyclone5_de0_nano_soc.dtb \
    tmp/deploy/images/cyclone5/socfpga_cyclone5_socdk.dtb 2>/dev/null || true

# Build:
bitbake core-image-minimal

# Patch DTB to enable HPS-to-FPGA bridges:
DTB=tmp/deploy/images/cyclone5/socfpga_cyclone5_de0_nano_soc.dtb
dtc -I dtb -O dts $DTB -o /tmp/de0_nano.dts 2>/dev/null
sed -i '/fpga_bridge@ff400000/,/\};/{s/status = "disabled"/status = "okay"/}' /tmp/de0_nano.dts
sed -i '/fpga_bridge@ff500000/,/\};/{s/status = "disabled"/status = "okay"/}' /tmp/de0_nano.dts
sed -i '/fpga-bridge@ff600000/,/\};/{s/status = "disabled"/status = "okay"/}' /tmp/de0_nano.dts
dtc -I dts -O dtb /tmp/de0_nano.dts -o /tmp/de0_nano_enabled.dtb 2>/dev/null
cp /tmp/de0_nano_enabled.dtb $DTB

# Transfer image and patched DTB to flashing machine:
scp tmp/deploy/images/cyclone5/core-image-minimal-cyclone5.rootfs.wic \
    adriel@192.168.100.252:~/
scp /tmp/de0_nano_enabled.dtb adriel@192.168.100.252:~/socfpga_cyclone5_de0_nano_soc.dtb
md5sum tmp/deploy/images/cyclone5/core-image-minimal-cyclone5.rootfs.wic

# SDK (optional — for cross-compiling apps):
bitbake core-image-minimal -c populate_sdk
ls tmp/deploy/sdk/*.sh
```

---

## ON remote (flashing machine):

```bash
ssh adriel@192.168.100.252

md5sum ~/core-image-minimal-cyclone5.rootfs.wic

lsblk
sudo umount /dev/mmcblk0p* 2>/dev/null
echo "done"
sudo wipefs -a /dev/mmcblk0
sudo dd if=/dev/zero of=/dev/mmcblk0 bs=1M count=100 status=progress
sync

# Flash Yocto image:
sudo bmaptool copy --nobmap ~/core-image-minimal-cyclone5.rootfs.wic /dev/mmcblk0
sync

# Replace partition 3 with Terasic's working SPL (required — Yocto SPL fails DDR init on DE1-SoC):
sudo dd if=~/DE1_SoC_SD.img of=/dev/mmcblk0p3 bs=512 skip=2048 count=2048
sync

# Fix boot partition:
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

## ON DE1-SoC HPS (after booting with SD card inserted):

```bash
# From classic, discover the board IP:
sudo nmap -sn 192.168.100.0/24

ssh root@<de1soc-ip>
# password: 1234
```

---

## Testing HPS-to-FPGA RAM Connection

First program the FPGA with your `.sof` via Quartus Programmer (JTAG). Then:

```bash
# Check bridge state (should say "enabled"):
cat /sys/class/fpga_bridge/br1/name   # should be hps2fpga
cat /sys/class/fpga_bridge/br1/state  # should be enabled

# Test RAM read/write using mmap (compile once with SDK):
/tmp/fpga_test
# Expected output:
# Before write: 0x????????
# After write:  0xDEADBEEF
```

To compile `fpga_test` (one time on classic with SDK):

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