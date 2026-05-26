## Calendar Overview (21/05/2026 → 18/06/2026)

| Sprint | Dates | Focus | Active Epics |
|---|---|---|---|
| **Sprint 0** | Thu 21/05 – Sun 24/05 (4 days) | Foundations: lock the contract | `architecture-contract` |
| **Sprint 1** | Mon 25/05 – Sun 31/05 | Toolchain spike — get everything booting | `toolchain-spike` |
| **Sprint 2** | Mon 01/06 – Sun 07/06 | Build HW peripherals + NIOS firmware in parallel | `hardware-peripherals`, `nios-firmware`, `hps-linux` |
| **Sprint 3** | Mon 08/06 – Sun 14/06 | Finish modules + first integration pass | `hardware-peripherals`, `nios-firmware`, `hps-linux` |
| **Sprint 4** | Mon 15/06 – Thu 18/06 (4 days) | Full integration, bug bash, demo | `integration-demo` |

**Demo day: Thursday 18/06/2026.** Treat Wed 17/06 as code freeze.

---

## Sprint 0 — Foundations (21/05 – 24/05)

Lock the contract before anyone codes against it.

| ID | Title | Owner | Days |
|---|---|---|---|
| #001 | configure-repo-ruleset ✅ | Adriel | done |
| #002 | quartus-common-hw-components ✅ | Adriel | done |
| #003 | draft-c1-system-context-diagram | Andres | 1 |
| #004 | draft-c2-container-diagram | Andres | 1 |
| #005 | draft-c3-component-diagram-nios-side | Andres | 1 |
| #006 | draft-c4-component-diagram-hps-side | Andres | 1 |
| #007 | **define-mmio-register-map-v1** ← critical | Adriel + Daniel D. | 2 |
| #008 | document-shared-memory-mailbox-protocol | Adriel | 1 |

**Exit criteria (Sun 24/05):** MMIO map + mailbox protocol signed off by the whole team. Diagrams reviewed.

---

## Sprint 1 — Toolchain Spike (25/05 – 31/05)

The "we are stupid" sprint. Goal: every team member has every tool working end-to-end. **No production code yet.** Parallelize aggressively — these are independent spikes.

| ID | Title | Owner | Days |
|---|---|---|---|
| #009 | spike-nios-ii-hello-world-jtag-uart | Daniel D. | 2 |
| #010 | spike-platform-designer-minimal-system | Adriel | 2 |
| #011 | spike-nios-mmio-led-blink-via-pointer | Daniel D. | 1 |
| #012 | spike-yocto-build-minimal-image-for-de1soc | Adriel | 4 |
| #013 | spike-cross-sdk-compile-hello-world-for-hps | Adriel | 1 |
| #014 | spike-sd-card-boot-hps-from-yocto-image | Adriel | 1 |
| #015 | spike-hps-fpga-bridge-read-write-from-linux | Adriel | 2 |
| #016 | spike-audio-codec-ip-passthrough-mic-to-jack | Daniel C. | 2 |
| #017 | document-toolchain-setup-in-compilation-execution-md | Andres | 2 |

**Exit criteria (Sun 31/05):** Adriel demonstrates the full pipeline once, end-to-end:
1. Program FPGA ✅
2. Load NIOS firmware ✅
3. Boot Linux on HPS from SD ✅
4. Cross-compile a binary, copy it, run it on HPS ✅
5. Sound through codec ✅

**⚠ Yocto is the highest schedule risk.** If #012 slips past Tue 26/05 → fall back to Terasic's prebuilt SD image. Don't burn the sprint on Yocto.

---

## Sprint 2 — Build in Parallel (01/06 – 07/06)

All three implementation epics start simultaneously. Everyone has stubs from the MMIO contract.

**Daniel C. — Hardware Peripherals**
| ID | Title | Days |
|---|---|---|
| #018 | hw-irq-controller-with-debounce | 1 |
| #019 | hw-switch-decoder-and-filter-7seg-display | 1 |
| #020 | hw-timer-module-with-mmio-ctrl | 2 |
| #021 | hw-7seg-decoder-16bit-to-4digit-mmss | 1 |
| #023 | hw-dsp-unit-skeleton-passthrough-mode | 2 |

**Daniel D. — NIOS Firmware**
| ID | Title | Days |
|---|---|---|
| #029 | nios-mmio-driver-headers-from-register-map | 1 |
| #037 | nios-build-cmake-toolchain-configuration | 1 |
| #030 | nios-state-machine-stopped-playing-paused | 2 |
| #031 | nios-isr-play-pause-stop-next-prev | 2 |
| #033 | nios-song-pointer-linked-list-management | 1 |

**Adriel — HW heavy modules + HPS scaffolding**
| ID | Title | Days |
|---|---|---|
| #022 | hw-fifo-sampler-module-mmio ← critical | 3 |
| #038 | yocto-recipe-for-musicplayer-hps-binary | 1 |
| #039 | hps-sd-card-mount-and-songs-folder-scan | 1 |
| #040 | hps-wav-header-parser-16bit-pcm | 2 |

**Andres — Docs + bug triage support**
| ID | Title | Days |
|---|---|---|
| #054a | keep-architecture-diagrams-in-sync-with-actual-code | ongoing |
| — | early bug triage as PRs land | ongoing |

**Exit criteria (Sun 07/06):** IRQ controller + timer + filter 7-seg working on board. NIOS state machine transitions correctly under stubbed audio. HPS reads SD and lists WAV files.

---

## Sprint 3 — Finish Modules + First Integration (08/06 – 14/06)

**Daniel C. — Hardware (filters + VGA)**
| ID | Title | Days |
|---|---|---|
| #024 | hw-dsp-fir-low-pass-filter | 2 |
| #025 | hw-dsp-band-pass-filter | 2 |
| #026 | hw-dsp-3band-equalizer | 3 |
| #027 | hw-vga-signal-generator-640x480 | 2 |

**Daniel D. — NIOS (audio path + display)**
| ID | Title | Days |
|---|---|---|
| #032 | nios-fifo-refill-loop-from-shared-ram | 2 |
| #034 | nios-vga-metadata-update-on-state-change | 1 |
| #035 | nios-timer-control-on-state-transitions | 1 |
| #036 | nios-song-ended-auto-next-handler | 1 |

**Adriel — HPS data path + VGA drawer**
| ID | Title | Days |
|---|---|---|
| #028 | hw-vga-drawer-text-from-mmio-buffer | 3 |
| #041 | hps-metadata-extractor-list-info-chunk-with-filename-fallback | 1 |
| #042 | hps-shared-memory-mailbox-protocol-impl | 2 |
| #043 | hps-audio-chunk-loader-feed-shared-ram | 2 |
| #044 | hps-respond-to-nios-next-prev-requests | 1 |
| #045 | hps-init-handshake-with-nios-on-boot | 1 |

**Andres — bug fixing as issues emerge**
- Open `bugfix/<id>-*` branches as integration problems appear.

**Exit criteria (Sun 14/06):** end-to-end audio plays one song (no filters yet). VGA shows static metadata. Timer counts.

---

## Sprint 4 — Integration & Demo (15/06 – 18/06)

**Code freeze: Wednesday 17/06 end of day. Demo: Thursday 18/06.**

| ID | Title | Owner | Day |
|---|---|---|---|
| #046 | integrate-audio-end-to-end-hps-nios-fifo-dsp-codec | Adriel | Mon 15/06 |
| #047 | integrate-vga-with-real-metadata-from-hps | Adriel + Daniel D. | Mon 15/06 |
| #048 | integrate-timer-7seg-with-real-playback | Daniel D. | Tue 16/06 |
| #049 | integrate-filter-switches-with-dsp-and-7seg | Daniel C. | Tue 16/06 |
| #050 | tune-fifo-watermark-and-refill-block-size | Adriel | Tue 16/06 |
| #051 | tune-button-debounce-and-response-time | Daniel C. | Tue 16/06 |
| #052 | bug-bash | All | Wed 17/06 |
| #053 | record-demo-video-and-write-final-report | Andres | Wed 17/06 |
| #054 | finalize-architecture-diagrams-with-as-built | Andres | Wed 17/06 |

**Thursday 18/06 morning:** dry run × 2. **Afternoon:** demo.

---

## Daily Standup Rule

10 minutes, every morning. Three questions only:
1. What did I finish yesterday?
2. What am I doing today?
3. What's blocking me?

If something is blocked for >24h → Adriel reshuffles.

---

## Risk Register

| Risk | Likelihood | Mitigation |
|---|---|---|
| Yocto build fails repeatedly | **High** | Fall back to Terasic's prebuilt SD image after Tue 26/05 |
| MMIO map changes mid-sprint | Medium | Lock at end of Sprint 0; any change = team-wide PR review |
| FIFO sampler tricky to get right | High | Adriel owns it, starts Sprint 2 day 1, has 3 days |
| Filters not done in time | Medium | Ship with passthrough + 1 filter (LPF). Drop BPF/EQ first if needed. |
| Linux on HPS not booting | High | Spike #012–#014 must finish Sprint 1. If not → demo HW + NIOS only with audio data in on-chip ROM. |

---

## Scope-cut order (if you fall behind)

In this exact order, drop:
1. 3-band equalizer (#026)
2. Band-pass filter (#025)
3. VGA metadata refresh on every state change (static screen instead)
4. WAV metadata extraction (use filename only)

Never cut: playback, FIFO, timer, one filter + passthrough, basic VGA, buttons.