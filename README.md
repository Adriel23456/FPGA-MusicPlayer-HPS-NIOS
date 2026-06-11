# FPGA Music Player — HPS + NIOS II

Hybrid SoC WAV music player on the **Terasic DE1-SoC** (Cyclone V). The HPS
ARM Cortex-A9 runs a custom **Yocto Linux** image whose daemon serves songs
and metadata from the SD card; a bare-metal **Nios II** soft-core in the FPGA
fabric runs the player application (FSM, interrupts, MMIO peripherals); and
**custom SystemVerilog hardware** handles every hard-timing path — playback
timer, VGA, and a DSP unit with three selectable audio filters applied live
on the output stream. The whole stack boots autonomously from power-on:
no JTAG, no host PC, no manual steps.

---

## Table of Contents

1. [Features](#features)
2. [How We Solved It](#how-we-solved-it)
3. [Design Methodology](#design-methodology)
4. [Repository Layout](#repository-layout)
5. [User Controls](#user-controls)
6. [Documentation Index](#documentation-index)
7. [Development Workflow](#development-workflow)
8. [Team](#team)
9. [License](#license)

---

## Features

- Plays **16-bit PCM WAV** files at **8 / 16 / 44.1 kHz** from the micro-SD
  card. The WM8731 codec is reprogrammed per source rate; 8 kHz plays
  bit-exact (1:1), while 16 / 44.1 kHz go through a 16.16 fixed-point
  linear-interpolation resampler tuned to the effective DAC rate.
- Library of **14 songs** with continuous playback and automatic next-track
  on song end.
- Playback controls: **play/pause, stop, next, previous** — fully
  **interrupt-driven**, no busy-waiting on user input.
- **3 hardware audio filters** + passthrough, selected with 2 switches and
  applied inline by the DSP module without interrupting playback:
  `A` FIR low-pass · `b` band-pass · `C` reverberation.
- **VGA 640×480** character display: song name, artist, album, duration,
  current index `X/N`, and player state.
- **7-segment displays**: elapsed time `MM:SS` (HEX5–HEX2) + active filter
  (HEX0), driven by a custom hardware MusicTimer.
- **Zero-touch boot**: the Yocto image programs the FPGA via a device tree
  overlay seconds into boot, then launches the music daemon — verified
  working evidence in [`Evidence/Evidence.md`](Evidence/Evidence.md).

---

## How We Solved It

Two processors, one shared-memory contract, and hardware where timing is hard:

- **HPS ARM Cortex-A9 — the librarian.** Runs a minimal Yocto Linux image
  built from four custom layers (see
  [`YoctoLinuxProject/`](YoctoLinuxProject/)). The `hps_music_player`
  daemon is a pure **slave**: it scans `/mnt/music`, parses WAV headers,
  and answers Nios II requests (catalog, metadata, audio buffers) over the
  HPS→FPGA bridge — it never initiates anything.

- **NIOS II soft-core — the conductor.** Bare-metal C with direct volatile
  MMIO access (no HAL wrappers in the hot path). Owns the playback FSM
  (Stopped/Playing/Paused), the button/switch ISRs, the per-rate codec
  configuration + resampling engine, the VGA character buffer, and the
  timer commands.

- **Shared-memory protocol.** On-chip RAM exposed to the HPS through the
  H2F bridge (mapped at `0xC000E000`) is the single communication channel:
  an event/ack handshake (Nios II writes `NIOS_EVENT_*`, the HPS echoes the
  ack) plus a **3-buffer audio ring** with per-buffer state
  (EMPTY → FILLING → READY → CONSUMING) and the current song's metadata.
  Both sides compile against the **same** `shared_protocol.h` — the
  contract is one header, visualized in
  [`Docs/MemoryContract.png`](Docs/MemoryContract.png).

- **Custom FPGA hardware.** MusicTimer (clock-accurate `MM:SS` counting with
  a command handshake), the 2-bit Filter Decoder, and the DSP module sitting
  after the audio output — filtering never touches software, guaranteeing
  glitch-free playback under any CPU load.

- **Autonomous boot chain.** Terasic SPL → U-Boot → Linux → `fpga-autoload`
  programs the fabric via configfs overlay → daemon starts → Nios II
  (embedded in the bitstream's on-chip RAM init) handshakes and the player
  is live. Details in the [`YoctoLinuxProject/`](YoctoLinuxProject/) layer
  READMEs and build notes.

---

## Design Methodology

The system was developed with an ESL **hardware/software codesign**
methodology (SER: Specification – Exploration – Refinement, with a
meet-in-the-middle integration of Platform Designer IP). The design was
refined through a chain of Models of Computation before implementation:

```
SM (Specification Model) → PSM (Process State Machine)
    → TLM (Transaction-Level Model) → CAM (Cycle-Accurate Model)
    → Quartus + firmware
```

Every diagram, the decisions locked at each step, and the Quartus block
diagrams are documented in
[`Docs/ArchitectureDiagrams/`](Docs/ArchitectureDiagrams/).

---

## Repository Layout

```
.
├── MusicPlayerQuartus22/               # FPGA design (Quartus Prime 22.1 + Platform Designer)
│                                       #   top-level SV, custom RTL (MusicTimer, DSP,
│                                       #   Filter Decoder), Qsys system, constraints
├── SoftwareDevelopment/
│   ├── NIOS-II/                        # Bare-metal Nios II firmware + numbered build scripts
│   ├── HPS/                            # hps_music_player daemon (CMake, Yocto SDK)
│   │   ├── include/                    #   shared_protocol.h = the HW/SW contract
│   │   └── src/
│   ├── NIOS-II_Workflow.md             # Complete Nios II build/run/sim workflow
│   └── HPS_Workflow.md                 # Complete HPS cross-compile/deploy workflow
├── YoctoLinuxProject/                  # Custom embedded Linux for the HPS
│   ├── cyclone5-gsrd-rootfs/           #   Yocto build environment (GSRD scarthgap)
│   ├── meta-de1soc-handoff/            #   U-Boot DDR3 fix + kernel /dev/mem config
│   ├── meta-de1soc-fpga/               #   Boot-time FPGA programming (rbf + overlay)
│   ├── meta-de1soc-music/              #   Daemon + WAV library + systemd unit
│   ├── meta-de1soc-net/                #   Static IP 192.168.100.50 on end0
│   ├── build-notes.md                  #   One-time setup of the build machine
│   └── quick-notes.md                  #   Every-rebuild procedure (build→patch→flash)
├── Docs/
│   ├── ArchitectureDiagrams/           # SM → PSM → TLM → CAM + Quartus diagrams
│   ├── GitRuleSets/                    # Repository rulesets (branch protection)
│   ├── AgileSprintPlanning.md          # Scrum epics, sprints, and issue planning
│   ├── CodeControl.md                  # Branching, commit, and PR conventions
│   └── MemoryContract.png              # Shared-memory layout (HPS ↔ Nios II)
├── Evidence/                           # Photographic proof of the working system
│   └── Evidence.md
├── RequiredSoftware.md                 # Quartus 22.1.2 Linux install + JTAG/ModelSim setup
├── LICENSE
└── README.md
```

---

## User Controls

| Input | Action |
|---|---|
| **KEY[3]** | Play / Pause |
| **KEY[2]** | Stop |
| **KEY[1]** | Previous song |
| **KEY[0]** | Next song |
| **SW[9:8]** | Filter select: `00` = off, `01` = FIR low-pass (`A`), `10` = band-pass (`b`), `11` = reverb (`C`) |
| **SW[1]** | Software reset (handled by the Nios II application) |
| **SW[0]** | Hardware reset (handled by the hardware) |
| **HEX5..2** | Elapsed time `MM:SS` |
| **HEX0** | Active filter indicator |
| **VGA** | Metadata: song name, artist, album, duration, state, `X / N` |

---

## Documentation Index

| Topic | Document |
|---|---|
| Required tooling (Quartus 22.1.2 Linux, ModelSim, JTAG udev) | [`RequiredSoftware.md`](RequiredSoftware.md) |
| Nios II firmware: setup, build, JTAG load, embedded-`.sof`, ModelSim | [`SoftwareDevelopment/NIOS-II_Workflow.md`](SoftwareDevelopment/NIOS-II_Workflow.md) |
| HPS daemon: SDK cross-compile, deploy, bake into the image | [`SoftwareDevelopment/HPS_Workflow.md`](SoftwareDevelopment/HPS_Workflow.md) |
| Yocto image: first-time setup of the build machine | [`YoctoLinuxProject/build-notes.md`](YoctoLinuxProject/build-notes.md) |
| Yocto image: rebuild → DTB patch → transfer → flash → verify | [`YoctoLinuxProject/quick-notes.md`](YoctoLinuxProject/quick-notes.md) |
| Per-layer details (purpose, contents, update procedure) | `YoctoLinuxProject/meta-de1soc-*/README` |
| Codesign methodology and all architecture models | [`Docs/ArchitectureDiagrams/`](Docs/ArchitectureDiagrams/) |
| Shared-memory contract (HPS ↔ Nios II) | [`Docs/MemoryContract.png`](Docs/MemoryContract.png) |
| Git branching, commits, PR conventions | [`Docs/CodeControl.md`](Docs/CodeControl.md) |
| Sprint planning and issue tracking | [`Docs/AgileSprintPlanning.md`](Docs/AgileSprintPlanning.md) |
| Working-system evidence (photos + captures) | [`Evidence/Evidence.md`](Evidence/Evidence.md) |

---

## Development Workflow

We follow **Agile / Scrum**: epics map to `develop/**` branches, user
stories/bugs/tasks map to `feature|bugfix|task/**` branches, all tracked as
issues. The full sprint plan (21/05/2026 → 11/06/2026) lives in
[`Docs/AgileSprintPlanning.md`](Docs/AgileSprintPlanning.md). Branch
naming, Conventional Commits, and PR rules — including that issue IDs live
in PRs and branch names, never in commits — are defined in
[`Docs/CodeControl.md`](Docs/CodeControl.md).

These conventions are **enforced** by GitHub repository rulesets (exported
in [`Docs/GitRuleSets/`](Docs/GitRuleSets/)):

| Ruleset | Applies to | Enforces |
|---|---|---|
| `Protect-master` | `master` | PR required with **2 approving reviews**; no deletion; no force-push |
| `Protect-develop` | `develop/**` | PR required (0 approvals — CI gate); no deletion; no force-push |

---

## Team

| Member | Role |
|---|---|
| **Adriel S. Chaves Salazar** | Hardware & Software integration · Team Leader |
| **Daniel Duarte Cordero** | HPS ↔ NIOS II bridge (shared-memory communication) |
| **Daniel Cob Beirute** | Hardware designer — audio filters |
| **Andres Guzman Rojas** | Documentation · bug fixing (hardware & software) |

Course: **Embedded Systems**, TEC — 2026 S1.

---

## License

Released under the [MIT License](LICENSE).