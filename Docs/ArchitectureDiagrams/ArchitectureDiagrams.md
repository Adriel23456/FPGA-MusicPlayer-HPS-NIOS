# Architecture Diagrams — Hardware/Software Codesign Models

This directory documents the design trajectory of the FPGA Music Player
following an ESL (Electronic System Level) **hardware/software codesign
methodology**. The system was not coded directly: it was refined through a
chain of Models of Computation (MoC), each one lowering the abstraction
level and locking in design decisions, until the model was accurate enough
to map 1:1 onto the final implementation (Nios II firmware, HPS daemon, and
custom SystemVerilog hardware).

Refinement chain:

```
Specification Model (SM)
        │  partition behavior into processes
        ▼
Process State Machine (PSM)
        │  map processes onto HW/SW and define states/events
        ▼
Transaction-Level Model (TLM)
        │  map channels onto buses, IPs, and MMIO
        ▼
Cycle-Accurate Model (CAM)
        │  register maps, RTL behavior, clock-level timing
        ▼
Implementation (Quartus Platform Designer + firmware)
```

---

## 000InitialDiagram.pdf — Initial Concept

The very first sketch of the project: how the system was *imagined* before
any methodology was applied. **It is outdated** and intentionally kept as-is
— comparing it against the final diagrams shows how much the SER iterations
reshaped the solution (partitioning, communication, and filtering all
changed). Useful as the starting reference point only.

## 00SystemDesignMethodology.png — Methodology

Defines *how* every other diagram in this folder was produced:

- **SER (Specification – Exploration – Refinement)**: from a specification,
  system synthesis explores candidate partitions; each branch (SW
  compilation → machine code, HW synthesis → netlists) produces IP blocks,
  and an **estimation feedback loop** returns to system synthesis to retry
  with better information. This loop is what drove the SM → PSM → TLM → CAM
  iterations.
- **Meet in the Middle**: lower-level components are created (or inserted as
  existing IP) first, and the high-level design is built on top of them —
  while the overall system behavior still constrains every level. In
  practice: Platform Designer IPs (PIOs, VGA char buffer, on-chip RAM,
  bridges) were chosen/inserted bottom-up, and the application logic was
  designed top-down to meet them.

## 01GeneralSystemOverview.png — System Overview

The user-facing definition of the solution, fixing the external contract
before any internal modeling:

- **I/O**: VGA 640×480 character display for metadata/state, SD card holding
  the Yocto image and songs, 3.5 mm audio out (16-bit WAV at 8/16/44.1 kHz),
  and the external PAM amplifier + speakers.
- **7-seg assignment**: HEX5–HEX2 = playback timer `MM:SS`, HEX0 = active
  filter (`0` none, `A` FIR low-pass, `b` band-pass, `C` reverberation).
- **User interface**: SW9–SW8 = 2-bit filter select (00/01/10/11),
  SW1 = software reset, SW0 = hardware reset, KEY3–KEY0 =
  play/pause, stop, prev, next.
- **Processing split (first partition decision)**: Nios II runs the main
  application; the HPS transfers audio data to it.

## 02GeneralSpecificationModel(SM).png — Specification Model

The first formal MoC: pure **behavior**, no architecture. The system is
decomposed into processes P1–P16 (boot, audio system init, interrupt
system, the five user actions, display update, timer update, filtering,
song-end handling, resets) connected by simple arrows (sequence) and
**bridge channels** (Audio Request / Audio Answer) that already express the
producer/consumer parallelism between the player and the audio data system
(P13/P14).

Design decisions locked here: SD-card data retrieval runs **in parallel**
with the main application; filtering happens **after** audio output
generation (pointing to a hardware implementation); user input is
**interrupt-driven**, never busy-waited.

## 03GeneralProcessStateMachine(PSM).png — Process State Machine

The SM processes are grouped into a hierarchy of sequential and
**concurrent (PP)** processes, each with pseudocode, and the playback FSM
appears explicitly:

- `P_Reset → P_Boot` run once, then fork the concurrent superstate:
  `P_NIOS` (interrupt-driven controller with the `PlaybackStates`
  StateChart: Stopped / Playing / Paused), `P_HPS` (pure slave, blocks on
  `c_data`, zero CPU waste), `P_Display`, `P_MusicTimer`, `P_AudioFilter`.
- Named channels appear: `c_interrupt`, `c_data`, `c_timerCtrl`,
  `c_stateOut` — the future physical interfaces.

Design decisions locked here: dual-CPU architecture (Nios II = controller,
HPS = data slave over a shared memory channel); two reset types (HW reset
vs. SW reset as an internal event of `P_NIOS`); the timer is hybrid
(FPGA hardware counts, Nios II commands RUNNING/PAUSED/RESET); filtering is
**hardware-only**, four modes including passthrough, no software in the
audio path.

## 04GeneralTransactionLevelModel(TLM).png — Transaction-Level Model

The PSM is mapped onto **architecture**: every process lands on a device/IP
and every channel lands on a bus. Each block is annotated with the SM/PSM
process numbers it implements, keeping full traceability between models.

- `c_data` → **On-Chip Memory (shared RAM)** between HPS_ARM and CPU_NIOS_II.
- `c_interrupt` → the **IRQ bus**; peripherals are separated from the Nios II
  instruction/data bus by an **MMIO Bridge**.
- `c_timerCtrl` → **two PIOs** (TimerInput, TimerOutput) flanking the custom
  SystemVerilog **MusicTimer** module; user inputs and reset get dedicated
  PIOs (ActionInput, ResetInput).
- Display → VGA Character Buffer + VGA Controller + Clock Bridge (640×480,
  char buffer, not a pixel framebuffer). Audio → AudioClock, Audio Out, and
  Audio/Video Config IPs (16-bit PCM).
- Filters → 2-bit hardware **Filter Decoder** (SW9–SW8) feeding the custom
  **DSP module** placed after the audio output.
- JTAG UART included for debugging/flashing the Nios II.

## 05FlowchartForTheCycleAccurateModel.png — CAM Flowchart

The complete control flow of the final system, end to end, before dropping
to register level: power-on → HPS boots the Yocto image and starts the
daemon (slave, serving Initial Info / Song Buffer / New Song actions over
the shared RAM) → FPGA auto-load → Nios II app init (VGA, audio, timer
drivers, FSM) → initial handshake → the interrupt-driven main loop with
every user action expanded (play/pause, stop, next, prev, app reset),
including state transitions, VGA updates, timer commands, buffer refills,
song-end auto-next, and the parallel DSP filter path (P42–P46). This is the
behavioral reference the firmware was written against.

## 06CycleAccurateModel(CAM).png — Cycle-Accurate Model

The lowest-level model: every block from the TLM with its **register map,
base address, bit-level interface, and RTL/cycle behavior** — MusicTimer
handshake protocol with the Nios II, PIO layouts (0x83000–0x83080 range),
VGA character grid addressing (0x08000000), the On-Chip-Memory dual-port
arrangement (Nios II instruction+data vs. HPS H2F access), the fractional
resampling engine (16.16 fixed-point, 8/16/44.1 kHz → 48 kHz), the boot
phase (preloader → FPGA configuration → HPS Linux), IRQ priorities, the
Filter Decoder combinational logic, the DSP pipeline, and the external
chain (WM8731 codec MCLK → PAM8403 → speakers). The implementation follows
this document directly.

## 07MusicPlayerPlatformDesign.pdf / 07MusicPlayerPlatformDesign2.pdf — Quartus Block Diagrams

Generated by **Quartus Prime** from the implemented design — the ground
truth that the models above converged to:

- `07MusicPlayerPlatformDesign.pdf` — the **Platform Designer (Qsys) system**:
  Nios II, on-chip RAM, PIOs, VGA IPs, audio IPs, bridges, and the custom
  modules, with their actual interconnect.
- `07MusicPlayerPlatformDesign2.pdf` — the **full project** top-level block
  diagram, including everything around the Platform Designer system.