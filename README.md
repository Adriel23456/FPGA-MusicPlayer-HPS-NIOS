# FPGA Music Player — HPS + NIOS II

Hybrid FPGA WAV music player on the **Terasic DE1-SoC**. The ARM Cortex-A9 (Linux) handles SD card I/O and metadata parsing; the NIOS II soft-core manages real-time control, MMIO peripherals, and button interrupts. Audio is streamed through a custom FIFO sampler into a DSP unit with three selectable digital filters.

---

## Table of Contents

1. [Features](#features)
2. [How We Solve It](#how-we-solve-it)
3. [Repository Layout](#repository-layout)
4. [User Controls](#user-controls)
5. [Documentation](#documentation)
6. [Development Workflow](#development-workflow)
7. [Team](#team)
8. [License](#license)

---

## Features

- Plays **16-bit PCM WAV** files at **8 / 16 / 44.1 kHz** from a micro-SD card.
- Library of **≥ 10 songs** with continuous playback and automatic next-track.
- Playback controls: **play / pause / stop / next / previous** (interrupt-driven).
- **3 digital audio filters** + passthrough, switch-controlled with < 100 ms latency:
  - FIR low-pass
  - Band-pass
  - 3-band equalizer
- **VGA** display showing metadata, current song index, and player state.
- **7-segment displays**: elapsed time `MM:SS` + active filter indicator.

---

## How We Solve It

Two brains, clean split:

- **ARM Cortex-A9 (HPS)** — the *librarian*. Runs minimal Linux (Yocto). Reads the SD card, parses WAV headers, extracts metadata, and ships audio chunks to NIOS II via shared RAM.
- **NIOS II soft-core** — the *conductor*. Bare-metal, pointer-only C. Owns the playback state machine, button ISRs, and all MMIO peripherals.
- **Custom FPGA peripherals** — handle every hard-timing path so software never bottlenecks audio: FIFO sampler, DSP filters, timer, VGA drawer, IRQ controller, switch-decoder, and 7-seg decoders.

Architectural diagrams (C1–C4) live in [`Docs/ArchitectureDiagrams/`](Docs/ArchitectureDiagrams/).

---

## Repository Layout

```
.
├── MusicPlayerQuartus/                 # FPGA design (Quartus + Platform Designer)
│   ├── MusicPlayerQuartus.qpf
│   ├── MusicPlayerQuartus.qsf
│   ├── top.sv
│   ├── rtl/                            # custom HDL modules
│   │   ├── fifo_sampler/
│   │   ├── dsp_unit/
│   │   ├── timer_module/
│   │   ├── vga_drawer/
│   │   └── irq_controller/
│   ├── qsys/                           # Platform Designer system files
│   └── constraints/                    # .sdc timing constraints
├── SoftwareDevelopment/
│   ├── Compilation&Execution.md        # How to use Cross-SDK for this code
│   ├── NIOS/                           # bare-metal NIOS II firmware (C, pointers only)
│   │   ├── src/
│   │   ├── lib/
│   │   ├── include/
│   │   └── CMakeLists.txt
│   └── HPS/                            # ARM userspace (Linux)
│       ├── src/
│       ├── lib/
│       ├── include/
│       └── CMakeLists.txt
├── YoctoLinuxProject/                  # minimal Linux image + boot scripts
├── Docs/
│   ├── CodeControl.md                  # branching / commit / PR conventions
│   ├── mmio_map.md                     # register map (the HW/SW contract)
│   └── ArchitectureDiagrams/           # C1–C4 diagrams of architectural decisions
├── .gitignore
└── README.md
```

---

## User Controls

| Input | Action |
|---|---|
| **KEY[0]** | Next song |
| **KEY[1]** | Previous song |
| **KEY[2]** | Stop |
| **KEY[3]** | Play / Pause |
| **SW[9:8]** | Filter select (`00`=off, `01`=LPF, `10`=BPF, `11`=EQ) |
| **SW[0]** | Reset switch |
| **HEX5..2** | Elapsed time `MM:SS` |
| **HEX0** | Active filter indicator |
| **VGA** | Metadata: song name, artist, album, duration, state, `X / N` |

---

## Documentation

| Topic | Document |
|---|---|
| Build & deploy NIOS / HPS code with the Cross-SDK | [`SoftwareDevelopment/Compilation&Execution.md`](SoftwareDevelopment/Compilation&Execution.md) |
| MMIO register map (hardware/software contract) | [`Docs/mmio_map.md`](Docs/mmio_map.md) |
| Architecture diagrams (C1–C4) | [`Docs/ArchitectureDiagrams/`](Docs/ArchitectureDiagrams/) |
| Git branching, commits, PR conventions | [`Docs/CodeControl.md`](Docs/CodeControl.md) |

---

## Development Workflow

We follow **Agile / Scrum** with epics → user stories → tasks / bugs, tracked as issues. Branch naming, commit convention (Conventional Commits), and PR rules are defined in [`Docs/CodeControl.md`](Docs/CodeControl.md).

---

## Team

| Member | Role |
|---|---|
| **Adriel S. Chaves Salazar** | Hardware & Software integration · Team Leader |
| **Daniel Duarte Cordero** | Software developer — main program logic |
| **Daniel Cob Beirute** | Hardware designer — audio filters |
| **Andres Guzman Rojas** | Documentation · bug fixing (hardware & software) |

Course: **Embedded Systems**, TEC — 2026 S1.

---

## License

Released under the [MIT License](LICENSE).