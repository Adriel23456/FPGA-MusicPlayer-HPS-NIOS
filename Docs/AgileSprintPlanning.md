# Agile Sprint Planning — FPGA Music Player (HPS + NIOS II)

## Calendar Overview (21/05/2026 → 11/06/2026)

| Sprint | Dates | Focus | Epic branch |
|---|---|---|---|
| **Sprint 1 — Initial** | Thu 21/05 – Wed 27/05 (7 days) | Design foundations + every development tool working end-to-end | `develop/design-foundations` |
| **Sprint 2 — Development** | Thu 28/05 – Tue 09/06 (13 days) | Integration of all the functionality sections of the project | `develop/software-hardware-integration` |
| **Sprint 3 — Docs** | Wed 10/06 – Thu 11/06 (2 days) | Fix the documentation and clear everything up | `develop/git-flow-and-documentation` |

**Delivery day: Thursday 11/06/2026.** Treat Tue 09/06 end of day as code freeze — Sprint 3 touches documentation only.

Each sprint maps 1:1 to one `develop/**` epic branch. Issues **#001–#010**
are the branch-level issues that name the working branches
(`feature/<issue-id>-<slug>`, per `CodeControl.md`); issues **#011+** are
the work items they contain. A single branch (and often a single commit)
may close several of its work-item issues — the PR description lists every
`<issue-id>` it closes.

---

## Sprint 1 — Initial: Design + Tools (21/05 – 27/05)

Lock the design and the toolchain before anyone codes against them. Two
tracks in parallel: **design** (the MoC refinement chain SM → PSM → TLM,
plus the HPS↔NIOS contract) and **tools** (everyone can build, load, and
boot by the end of the sprint). No production application code yet.

**#001 — `task/001-configure-repo-ruleset`** (Adriel, 1 day)
| Issue | Work item | Days |
|---|---|---|
| #011 | Initial project scaffolding (folder structure, .gitignore, LICENSE) | 0.5 |
| #012 | GitHub rulesets: protect `master` (2 approvals) and `develop/**` (PR + CI) | 0.5 |
| #013 | Publish this sprint plan + CodeControl conventions | — |

**#002 — `feature/002-quartus-common-hw-components`** (Adriel + Daniel D., 3 days)
| Issue | Work item | Days |
|---|---|---|
| #014 | Platform Designer base system: Nios II /e core, on-chip RAM, JTAG UART, PIOs | 1 |
| #015 | NIOS II software platform: BSP generation + numbered Linux build scripts | 1 |
| #016 | ModelSim simulation flow with memory-init artifacts | 0.5 |
| #017 | Architecture decision notes for NIOS II adoption + SM/PSM diagrams | 0.5 |
| #018 | Codec spike: WM8731 driver validated with a 440 Hz square-wave test (Daniel C.) | 1 |

**#003 — `feature/003-hps-system-integration-and-nios-intercomunication`** (Adriel, 3 days)
| Issue | Work item | Days |
|---|---|---|
| #019 | Integrate the Cyclone V HPS into the platform; update diagrams (TLM) | 1 |
| #020 | **Yocto custom image booting the DE1-SoC HPS** ← critical | 2 |
| #021 | Linux-native Quartus + Nios II toolchain workflow, collaborative .gitignore | 0.5 |

**#004 — `bugfix/004-bsp-optimization-flags-setup-scripts`** (Adriel, 0.5 days)
| Issue | Work item | Days |
|---|---|---|
| #022 | Reserved defect slot for toolchain issues found while spiking (expected: BSP size/optimization flags — the on-chip RAM is small) | 0.5 |

**Exit criteria (Wed 27/05):** rulesets active; base Qsys system compiles;
firmware builds and loads from the numbered scripts; codec proven with a
tone; the HPS boots our Yocto image; the epic merges into `master` via PR.

**⚠ Yocto (#020) is the highest schedule risk of the project.** If the
image does not boot by Mon 26/05 → fall back to Terasic's prebuilt SD image
(or a hybrid: their SPL + our rootfs) and move on. Don't burn the sprint on
it.

---

## Sprint 2 — Development: Functional Integration (28/05 – 09/06)

One epic, four sequential blocks. Each block ends with working hardware —
integration is continuous, not deferred to a final sprint. The
`shared_protocol.h` contract is stubbed first so the NIOS side never waits
on the HPS side.

### Block A — NIOS II audio execution system (28/05 – 31/05)

**#005 — `feature/005-NIOSII-audio-execution-system`** (Daniel D. + Adriel)
| Issue | Work item | Owner | Days |
|---|---|---|---|
| #023 | Main playback FSM: Stopped / Playing / Paused | Daniel D. | 1 |
| #024 | Edge-triggered IRQ handling: KEY3–KEY0 actions + SW reset (no busy-wait) | Adriel | 1 |
| #025 | Fixed-rate playback engine with fractional (16.16) resampling | Adriel | 1.5 |
| #026 | FSM integrated against a **dummy HPS contract** (`shared_protocol.h` v1) | Daniel D. | 1 |
| #027 | Setup/execution control docs for the build scripts | Andres | 0.5 |

### Block B — HPS bridge + real audio data (01/06 – 04/06)

**#006 — `feature006/HPS_NIOSII_interconnection`** (Daniel D.)
| Issue | Work item | Owner | Days |
|---|---|---|---|
| #028 | Shared-RAM bridge: event/ack handshake + 3-buffer audio ring | Daniel D. | 2 |
| #029 | HPS daemon: SD scan, WAV parsing, metadata, buffer service (slave role) | Daniel D. + Adriel | 1 |
| #030 | System architecture diagram updated to the as-built bridge | Andres | 0.5 |
| #031 | Codec reproduction from real WAV data; per-rate tuning for 8/16/44.1 kHz | Adriel | 1.5 |

### Block C — Complete functionality + autonomous boot (05/06 – 06/06)

**#007 — `feature007/design-justification-and-complete-functionality`** (Adriel + Daniel D.)
| Issue | Work item | Owner | Days |
|---|---|---|---|
| #032 | Remove HALs → direct volatile MMIO; fix ring coherency; relocate RAM to 32 KB | Adriel + Daniel D. | 1 |
| #033 | **Fully autonomous boot from microSD** (fpga-autoload + daemon + embedded firmware) | Adriel | 1 |
| #034 | VGA metadata + 7-seg timer verified against the full path | Daniel D. | 0.5 |
| #035 | Design justification consolidated into the diagrams (CAM) | Andres | 0.5 |

### Block D — DSP filters (07/06 – 09/06)

Filters come **last by design**: they are hardware-only and sit after the
audio output, so they depend on a stable audio path but nothing depends on
them — they are also the first scope cut if the schedule slips.

**#008 — `feature/008-filter-design`** (Daniel C. + Adriel)
| Issue | Work item | Owner | Days |
|---|---|---|---|
| #036 | DSP IP foundation: passthrough skeleton + 2-bit filter decoder + HEX0 | Daniel C. | 1 |
| #037 | Real-time filters with I2S interception: FIR low-pass, band-pass, reverb | Adriel + Daniel C. | 1.5 |

**#009 — `feature009/quality-of-life-improvements`** (Daniel C., 0.5 days)
| Issue | Work item | Owner | Days |
|---|---|---|---|
| #038 | Polish pass + epic close: merge `develop/software-hardware-integration` into `master` via PR | Daniel C. | 0.5 |

**Exit criteria (Tue 09/06):** full player from power-on with no host PC:
≥ 10 songs, all controls interrupt-driven, VGA + 7-seg live, three filters
switchable during playback. Evidence photos captured for `Evidence/`.

---

## Sprint 3 — Docs: Documentation & Cleanup (10/06 – 11/06)

Code is frozen. Epic `develop/git-flow-and-documentation`, single working
branch.

**#010 — `feature010/fixed-documentation-and-git-flow`** (All, lead: Andres)
| Issue | Work item | Owner |
|---|---|---|
| #039 | Rewrite `NIOS-II_Workflow.md` for the Linux-native numbered scripts | Adriel + Andres |
| #040 | Write `HPS_Workflow.md` (SDK cross-compile, deploy, bake into image) | Adriel + Andres |
| #041 | Rewrite `RequiredSoftware.md` (Quartus 22.1.2 Linux only) | Andres |
| #042 | Replace template READMEs of the four `meta-de1soc-*` Yocto layers | Adriel |
| #043 | `Evidence/` directory + `Evidence.md` | Andres |
| #044 | `ArchitectureDiagrams/` README (SM → PSM → TLM → CAM methodology) | Andres |
| #045 | Align `CodeControl.md` with the enforced rulesets; export to `Docs/GitRuleSets/` | Adriel |
| #046 | Rebuild the main `README.md` with the complete development | Adriel |
| #047 | Code commenting + cleanup pass | All |

**Exit criteria (Thu 11/06):** every document reflects the final system;
PR into `master`, tagged release. Delivery.

---

## Daily Standup Rule

10 minutes, every morning. Three questions only:
1. What did I finish yesterday?
2. What am I doing today?
3. What's blocking me?

If something is blocked for > 24 h → Adriel reshuffles ownership.

---

## Risk Register

| Risk | Likelihood | Mitigation |
|---|---|---|
| Yocto build/boot fails repeatedly (#020) | **High** | Time-boxed to Sprint 1; fall back to Terasic prebuilt image or hybrid (their SPL + our rootfs) |
| Shared-memory contract changes mid-sprint (#026/#028) | Medium | Stub it in Block A as `shared_protocol.h` v1; any later change = team-wide PR review (both sides rebuild from the same header) |
| Audio rates beyond 8 kHz unstable (#025/#031) | High | Resampling engine designed rate-agnostic from day one (per-rate step + codec config); 8 kHz 1:1 is the guaranteed baseline |
| Filters not done in time (#036/#037) | Medium | Scheduled last (Block D); ship passthrough + FIR low-pass minimum |
| Ring-buffer coherency bugs between HPS and NIOS (#032) | Medium | Budgeted refactor slot in Block C before declaring functionality complete |

---

## Scope-cut order (if we fall behind)

In this exact order, drop:
1. Reverberation filter (part of #037)
2. Band-pass filter (part of #037)
3. 44.1 kHz support (part of #031 — keep 8/16 kHz)
4. WAV metadata extraction (part of #029 — use filename only)

Never cut: playback, the shared-memory bridge, timer, one filter +
passthrough, basic VGA, interrupt-driven buttons, autonomous boot.