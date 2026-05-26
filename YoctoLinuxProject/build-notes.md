# Yocto Image & SDK Setup Guide

## Prerequisites

- Poky Scarthgap 5.0.15 installed at `~/poky-scarthgap-5.0.15`
- `meta-raspberrypi` layer cloned alongside Poky
- `meta-rpi4-config` layer (WiFi provisioning) in Poky root
- `meta-robot` layer (RoboVac application) in Poky root

## 1. Initialize the build environment

```bash
cd ~/poky-scarthgap-5.0.15
source oe-init-build-env rpi4
bitbake-layers add-layer ../meta-raspberrypi
bitbake-layers add-layer ../meta-rpi4-config
bitbake-layers add-layer ../meta-robot
```

## 2. Configure the build

Copy the project's `bblayers.conf` and `local.conf` into `rpi4/conf/`, replacing the defaults.

## 3. Build the image

```bash
bitbake core-image-minimal
```

The output image will be at:

```
tmp/deploy/images/raspberrypi4/core-image-minimal-raspberrypi4.rootfs.wic.bz2
```

## 4. Build the cross-compilation SDK

```bash
bitbake core-image-minimal -c populate_sdk
```

The SDK installer script will be at:

```bash
ls tmp/deploy/sdk/*.sh
# Example:
# poky-glibc-x86_64-core-image-minimal-cortexa7t2hf-neon-vfpv4-raspberrypi4-toolchain-5.0.15.sh
```

## 5. Install the SDK

```bash
./tmp/deploy/sdk/poky-glibc-x86_64-core-image-minimal-cortexa7t2hf-neon-vfpv4-raspberrypi4-toolchain-5.0.15.sh
```

Follow the prompts. Default install path is `/opt/poky/5.0.15/`.

## 6. Cross-compile projects

Before building any project (`librobot-6.0.1`, etc.), source the SDK environment:

```bash
. /opt/poky/5.0.15/environment-setup-cortexa7t2hf-neon-vfpv4-poky-linux-gnueabi
```

Then build as usual:

```bash
cd robot-6.0.1 && mkdir build && cd build
cmake ../ -DCMAKE_INSTALL_PREFIX:PATH=$(pwd)/usr
make && make install
```

## Quick reference

| Task | Command |
|------|---------|
| Build image | `bitbake core-image-minimal` |
| Build SDK | `bitbake core-image-minimal -c populate_sdk` |
| Source SDK | `. /opt/poky/5.0.15/environment-setup-cortexa7t2hf-neon-vfpv4-poky-linux-gnueabi` |
| Rebuild RoboVac only | `bitbake -c cleansstate robot && bitbake robot` |
| SSH into Pi | `ssh root@192.168.100.131` |