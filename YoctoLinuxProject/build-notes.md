## One-Time Setup

```bash
# Clone the official Altera GSRD repo with all submodules
cd ~
git clone -b scarthgap https://github.com/altera-fpga/gsrd-socfpga.git
cd gsrd-socfpga
git submodule update --init --recursive
```

---

## Initialize Build Environment

```bash
cd ~/gsrd-socfpga
. cyclone5-gsrd-build.sh build_setup
```

---

## Configure `local.conf`

```bash
cat >> ~/gsrd-socfpga/cyclone5-gsrd-rootfs/conf/local.conf << 'ENDOFCONF'

IMAGE_FEATURES += "ssh-server-dropbear"
INHERIT += "extrausers"
EXTRA_USERS_PARAMS = "usermod -p '\$6\$q3kRl3o/yImgF0bP\$nNwm0VkLEeKd2QKEGwbK1DjwJ5QqjEjJvXwAcjDu4Cr0iexwoDbfTOOUKgKWqD7Zb6sJ4zThqOEEHTu5Bj.ai1' root;"
IMAGE_INSTALL:remove = "hw-ref-design"
ENDOFCONF
```

---

## Patch `hw-ref-design` to Skip the FPGA Bitstream Download

```bash
cat > ~/gsrd-socfpga/meta-intel-fpga-refdes/recipes-bsp/ghrd/hw-ref-design.bbappend << 'ENDOFBBAPPEND'
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
ENDOFBBAPPEND
```

---

## Create Missing WIC Dependencies

```bash
# Generate u-boot.scr boot script
cat > /tmp/cyclone5_boot.txt << 'ENDOFBOOT'
load mmc 0:1 ${kernel_addr_r} zImage
load mmc 0:1 ${fdt_addr_r} socfpga_cyclone5_socdk.dtb
bootz ${kernel_addr_r} - ${fdt_addr_r}
ENDOFBOOT

MKIMAGE=$(find ~/gsrd-socfpga/cyclone5-gsrd-rootfs/tmp -name mkimage -type f 2>/dev/null | head -1)

$MKIMAGE -T script -A arm -O linux -C none \
    -n "Boot Script" \
    -d /tmp/cyclone5_boot.txt \
    ~/gsrd-socfpga/cyclone5-gsrd-rootfs/tmp/deploy/images/cyclone5/u-boot.scr

# Create dummy FPGA bitstream placeholder
mkdir -p ~/gsrd-socfpga/cyclone5-gsrd-rootfs/tmp/deploy/images/cyclone5/cyclone5_gsrd_ghrd/
touch ~/gsrd-socfpga/cyclone5-gsrd-rootfs/tmp/deploy/images/cyclone5/cyclone5_gsrd_ghrd/soc_system.rbf
```

---

## Build

```bash
cd ~/gsrd-socfpga/cyclone5-gsrd-rootfs
bitbake -c cleansstate hw-ref-design
bitbake core-image-minimal
```

---

## Flash and Connect

```bash
# On build machine — transfer image:
scp ~/gsrd-socfpga/cyclone5-gsrd-rootfs/tmp/deploy/images/cyclone5/core-image-minimal-cyclone5.wic \
    adriel@192.168.100.252:~/

# On remote machine — flash SD card:
lsblk
sudo umount /dev/mmcblk0p* 2>/dev/null
sudo wipefs -a /dev/mmcblk0
sudo dd if=/dev/zero of=/dev/mmcblk0 bs=1M count=100 status=progress
sync
sudo bmaptool copy --nobmap ~/core-image-minimal-cyclone5.wic /dev/mmcblk0
sync

# Discover DE1-SoC on network:
sudo nmap -sn 192.168.100.0/24

# SSH in:
ssh root@<de1soc-ip>
```