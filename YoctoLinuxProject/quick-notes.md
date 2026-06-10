# Cyclone V GSRD — Full Build & Flash Procedure

---

## 1. Enter the Build Environment
> Run this every new terminal session.

```bash
cd ~/gsrd-socfpga
. poky/oe-init-build-env cyclone5-gsrd-rootfs
```

---

## 2. Build

> Only run the `cleansstate` lines if you changed files in that recipe.

```bash
# If you changed hps-music-player files:
bitbake hps-music-player -c cleansstate && bitbake hps-music-player

# If you changed fpga-autoload files:
bitbake fpga-autoload -c cleansstate && bitbake fpga-autoload

# Full image:
bitbake core-image-minimal

# SDK (optional):
bitbake core-image-minimal -c populate_sdk
ls tmp/deploy/sdk/*.sh

. /opt/poky/5.0.17/environment-setup-cortexa9t2hf-neon-poky-linux-gnueabi
```

---

## 3. Patch the DTB
> Required every build — the DTB is regenerated each time.

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

## 4. Transfer to Flashing Machine

```bash
scp tmp/deploy/images/cyclone5/core-image-minimal-cyclone5.rootfs.wic adriel@192.168.100.252:~/
scp /tmp/de0_nano_enabled.dtb adriel@192.168.100.252:~/socfpga_cyclone5_de0_nano_soc.dtb

# Save this checksum to verify after transfer:
md5sum tmp/deploy/images/cyclone5/core-image-minimal-cyclone5.rootfs.wic
```

---

## 5. Flash the SD Card
> ⚠️ Run on the flashing machine (192.168.100.252). Confirm device with `lsblk` — this erases it.

```bash
ssh adriel@192.168.100.252

# Verify checksum matches step 4:
md5sum ~/core-image-minimal-cyclone5.rootfs.wic

lsblk   # confirm /dev/mmcblk0 is the SD card

sudo umount /dev/mmcblk0p* 2>/dev/null
sudo wipefs -a /dev/mmcblk0
sudo dd if=/dev/zero of=/dev/mmcblk0 bs=1M count=100 status=progress
sync

sudo bmaptool copy --nobmap ~/core-image-minimal-cyclone5.rootfs.wic /dev/mmcblk0
sync

# Terasic SPL on partition 3 (Yocto SPL fails DDR init):
sudo dd if=~/DE1_SoC_SD.img of=/dev/mmcblk0p3 bs=512 skip=2048 count=2048
sync

# Write boot partition: patched DTB + extlinux:
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

## 6. Boot, Program FPGA & Verify

1. Insert the SD card and power the board.

```bash
# Static IP applied?
networkctl status end0        # should show 192.168.100.50, not a DHCP address

# Daemon running?
systemctl status hps_music_player
journalctl -u hps_music_player   # look for: "shared mem mapped", "songs=N"

# Songs present?
ls -l /mnt/music

# Bridge enabled?
cat /sys/class/fpga_bridge/br1/state   # expected: enabled
```

This is how to use minicom with UART conection!
```bash
sudo minicom -D /dev/ttyUSB0 -b 115200
```