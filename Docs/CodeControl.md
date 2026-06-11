# Code Control

## Branching Strategy

```
master
  └── develop/**
        └── feature/** | bugfix/** | task/**
```

---

## Branches

### `master`
- **Purpose:** Production-ready releases only. Never pushed to directly.
- **Receives PRs from:** `develop/**` branches exclusively.
- **PR approval:** **1 approval required** before merge.
- **Tagging:** Every merge into `master` is tagged with a semantic version (e.g., `v1.0.0`, `v1.1.0`).

### `develop/**`
- **Purpose:** One branch per Scrum epic or sprint goal (e.g., `develop/audio-pipeline`, `develop/vga-display`).
- **Receives PRs from:** `feature/**`, `bugfix/**`, and `task/**` branches.
- **PR approval:** None — merge once the work is done and CI passes.
- **Lifetime:** Lives until the epic is complete, then merges into `master`.

### `feature/**`, `bugfix/**`, `task/**`
- **Purpose:** Day-to-day work, each branch tied to a single Scrum issue.
  - `feature/**` → new functionality (user story).
  - `bugfix/**` → defect fix.
  - `task/**` → maintenance, refactor, docs, chore.
- **PRs:** Always target the relevant `develop/**` branch.

---

## Flow Summary

```
feature/123-login-ui
    │
    │  PR (no approval needed, CI must pass)
    ▼
develop/auth
    │
    │  PR (1 approval required)
    ▼
master  ← tagged release
```

---

## Rules at a Glance

| Branch          | Push directly? | PR target      | Approval needed? |
|-----------------|----------------|----------------|------------------|
| `master`        | ❌ No          | —              | —                |
| `develop/**`    | ❌ No          | `master`       | ✅ 1 approval    |
| `feature/**`    | ✅ Yes         | `develop/**`   | ❌ No            |
| `bugfix/**`     | ✅ Yes         | `develop/**`   | ❌ No            |
| `task/**`       | ✅ Yes         | `develop/**`   | ❌ No            |

---

## Naming Convention

All names lowercase, hyphen-separated, and descriptive.

### `develop/**` (epic-level)
Tied to a Scrum **epic** or **sprint goal** — use a short epic identifier:

```
develop/<epic-name>
```

Examples:
```
develop/audio-pipeline
develop/sdcard-driver
develop/vga-metadata
develop/nios-mmio
```

### `feature/**`, `bugfix/**`, `task/**` (issue-level)
Tied to a single Scrum **issue** — include the issue ID and a short slug:

```
feature/<issue-id>-<short-description>
bugfix/<issue-id>-<short-description>
task/<issue-id>-<short-description>
```

Examples:
```
feature/42-wav-header-parser
feature/57-button-isr-handler
bugfix/63-7seg-timer-overflow
bugfix/71-vga-sync-glitch
task/12-update-readme
task/19-refactor-mmio-macros
```

---

## Issue Traceability

> **Commits do NOT reference issue IDs. Pull Requests DO.**

- **Commits** describe the change itself — type, scope, and what/why. They
  carry **no** `Refs #` / `Closes #` footers and no issue numbers.
- **Pull Requests** are the traceability point: the issue ID goes in the PR
  **title** (`(#<issue-id>)`) and the PR **description** (`Closes #<issue-id>`).
- Since a branch maps to exactly one issue and a PR closes it, every commit
  is traceable through its PR — duplicating the ID per commit adds noise,
  not information.

---

## Commit Message Convention

Follow **Conventional Commits**:

```
<type>(<scope>): <short summary>

<optional body — what & why, not how>
```

### Types

| Type       | Use for                                                  |
|------------|----------------------------------------------------------|
| `feat`     | New feature or user-visible capability                   |
| `fix`      | Bug fix                                                  |
| `refactor` | Code change that neither fixes a bug nor adds a feature  |
| `perf`     | Performance improvement                                  |
| `docs`     | Documentation only                                       |
| `test`     | Adding or fixing tests                                   |
| `build`    | Build system, toolchain, Quartus/Platform Designer files |
| `ci`       | CI configuration                                         |
| `chore`    | Misc maintenance (no src/test change)                    |
| `style`    | Formatting, whitespace, no logic change                  |

### Scope examples (this project)

`hps`, `nios`, `mmio`, `audio`, `filter`, `vga`, `7seg`, `sdcard`, `isr`, `kernel`, `wav`, `pd` (Platform Designer)

### Rules

- Summary in **imperative mood**, lowercase, no trailing period, ≤72 chars.
- One logical change per commit.
- **No issue references in commits** — traceability lives in the PR
  (see *Issue Traceability* above).

### Examples

```
feat(wav): parse 16-bit PCM headers at 8/16/44.1 kHz

Adds parser to extract sample rate, channel count, and data offset
from RIFF/WAVE headers. Required for HPS-side metadata extraction.
```

```
fix(7seg): clamp MM:SS display when track exceeds 59:59
```

```
refactor(mmio): consolidate filter control registers into a struct
```

```
build(pd): regenerate qsys with NIOS II /e core and on-chip RAM
```

---

## Pull Request Convention

### Title

Mirrors the commit format, **plus the issue ID**:

```
<type>(<scope>): <short summary> (#<issue-id>)
```

Example:
```
feat(filter): add FIR low-pass implementation (#48)
```

### Description Template

```markdown
## Summary
One-paragraph description of what this PR does and why.

## Linked Issue
Closes #<issue-id>

## Type of Change
- [ ] Feature
- [ ] Bugfix
- [ ] Task / chore
- [ ] Refactor
- [ ] Docs

## Changes
- Bullet list of key changes
- Hardware modules touched (if any)
- Software modules touched (if any)

## Testing
- [ ] Synthesized in Quartus without errors
- [ ] Simulated / tested on DE1-SoC
- [ ] Verified on hardware (buttons, audio, VGA, 7-seg)
- Describe the manual test steps

## Screenshots / Captures
(VGA output, 7-seg, signal traces, etc., if applicable)

## Checklist
- [ ] Branch named per convention
- [ ] Commits follow Conventional Commits (no issue IDs in commits)
- [ ] Issue ID present in PR title and "Linked Issue"
- [ ] No secrets or board-specific paths hardcoded
- [ ] Documentation updated if behavior changed
```

### PR Rules

- Keep PRs **small and focused** — one issue, one PR when possible.
- **Squash** is acceptable for `feature/**` → `develop/**`; **merge commit**
  preferred for `develop/**` → `master` to preserve epic history.
- CI must pass before merging into `develop/**` or `master`.
- A PR into `master` must list every issue closed in the epic.

---

## Scrum Integration

- **Epics** → one `develop/**` branch.
- **User stories** → `feature/**` branches.
- **Bugs** → `bugfix/**` branches.
- **Tasks/chores** → `task/**` branches.
- Issue IDs appear in **branch names and PRs only** — never in commits.
- Sprint-end: open a PR from the active `develop/**` into `master` and tag a release.