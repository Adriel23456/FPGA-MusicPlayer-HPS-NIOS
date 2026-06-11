# HPS Music Player — Complete Workflow

> **Linux only.** Cross-compiled on the build machine (`classic`) with the
> Yocto SDK, deployed to the board over SSH. Each step says **where** it runs.

## Project Layout

```
SoftwareDevelopment/
└── HPS/
    ├── CMakeLists.txt
    ├── include/
    │   ├── fpga_mem.h             ← /dev/mem mmap of the HPS→FPGA bridge window
    │   ├── hps_audio_streamer.h   ← streams WAV PCM into shared memory
    │   ├── hps_fpga_comm.h        ← command/handshake layer with the Nios II
    │   ├── shared_protocol.h      ← shared memory contract (same file the Nios includes)
    │   └── wav_reader.h           ← WAV parsing
    └── src/
        ├── main.c                 ← daemon entry point
        ├── fpga_mem.c
        ├── hps_fpga_comm.c
        ├── hps_audio_streamer.c
        └── wav_reader.c
```

`shared_protocol.h` is the **single source of truth** for the shared-memory
layout — the Nios II firmware includes the same file. If it changes, rebuild
**both** sides.

---

## Prerequisite (one-time) — Install the Yocto SDK

The SDK is produced by the Yocto build (see the GSRD setup guide §1.3):

```bash
# On classic:
cd ~/gsrd-socfpga
. poky/oe-init-build-env cyclone5-gsrd-rootfs
bitbake core-image-minimal -c populate_sdk
./tmp/deploy/sdk/poky-glibc-x86_64-core-image-minimal-cortexa9t2hf-neon-toolchain-*.sh
# Default install path: /opt/poky/5.0.17
```

---

## Build (every code change)

> Run on **classic**. Source the SDK environment **once per terminal** —
> it replaces `cmake`/`gcc` with the ARM cross toolchain.

```bash
. /opt/poky/5.0.17/environment-setup-cortexa9t2hf-neon-poky-linux-gnueabi

cd SoftwareDevelopment/HPS
mkdir -p build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX:PATH=$(pwd)/usr
make && make install
# Output binary: build/usr/bin/hps_music_player
```

Notes:
- The CMake project builds with `-O2 -Wall` and defines `_DEFAULT_SOURCE`
  (needed for `usleep`/`dirent`).
- Verify the binary is actually ARM, not x86 (catches a forgotten SDK source):

```bash
file usr/bin/hps_music_player    # expect: ELF 32-bit LSB ... ARM
```

---

## Deploy to the Board (quick iteration)

> From **classic**. Board static IP `192.168.100.50`, root password `1234`.

```bash
scp usr/bin/hps_music_player root@192.168.100.50:/usr/bin/
```

The daemon from the flashed image is already running via systemd, so restart
it to pick up the new binary:

```bash
# On the board:
systemctl restart hps_music_player
journalctl -u hps_music_player -f     # "shared mem mapped", "songs=N"
```

To run it manually in the foreground instead (FPGA must be programmed —
`cat /sys/class/fpga_manager/fpga0/state` should read `operating`):

```bash
# On the board:
systemctl stop hps_music_player
hps_music_player
```

---

## Making the Change Permanent (Yocto image)

The `scp` deploy survives reboots of **this** SD card, but a re-flash restores
the binary bundled in the `meta-de1soc-music` layer. To bake the new build in:

```bash
# On classic — replace the prebuilt binary in the layer:
cp build/usr/bin/hps_music_player \
   ~/gsrd-socfpga/meta-de1soc-music/recipes-apps/hps-music-player/files/

# Rebuild the recipe and the image (see the GSRD quick notes):
cd ~/gsrd-socfpga
. poky/oe-init-build-env cyclone5-gsrd-rootfs
bitbake hps-music-player -c cleansstate && bitbake hps-music-player
bitbake core-image-minimal
```

Then follow the normal DTB-patch → transfer → flash procedure.

---

## Adding New Source Files

CMake lists sources explicitly — adding a file means editing `CMakeLists.txt`:

```cmake
add_executable(hps_music_player
    src/main.c
    src/fpga_mem.c
    src/hps_fpga_comm.c
    src/hps_audio_streamer.c
    src/wav_reader.c
    src/your_new_file.c        # ← add here
)
```

Headers go in `include/` (already on the include path). Then rebuild:

```bash
cd build && cmake .. && make && make install
```

---

## Common Errors

**Binary runs on classic but not the board / `Exec format error`**
→ The SDK environment wasn't sourced; you built for x86.
→ Source the environment script, delete `build/`, rebuild.

**`mmap` / `open /dev/mem` fails on the board**
→ Not running as root, or the kernel lacks `iomem=relaxed` (it's in the
  extlinux `APPEND` line of the flashed image).

**Daemon starts but no audio / handshake timeout**
→ FPGA not programmed: `cat /sys/class/fpga_manager/fpga0/state` must read
  `operating` and `br1/state` must read `enabled`.
→ Or `shared_protocol.h` diverged between HPS and Nios II builds — rebuild
  both from the same header.

**`scp: connection refused / no route to host`**
→ Board not booted, or static IP not applied: `networkctl status end0`
  on the board (UART console) should show `192.168.100.50`.