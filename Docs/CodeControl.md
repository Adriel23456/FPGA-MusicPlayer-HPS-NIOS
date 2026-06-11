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
- **Purpose:** Production-ready releases only. Nothing is pushed here directly.
- **Receives PRs from:** `develop/**` branches exclusively.
- **PR Approval:** **1 approval required** before merge.
- **Tagging:** Every merge into `master` is tagged with a semantic version (e.g., `v1.0.0`, `v1.1.0`).

---

### `develop/**`
- **Purpose:** Represents a major Scrum epic or sprint goal (e.g., `develop/audio-pipeline`, `develop/vga-display`).
- **Receives PRs from:** `feature/**`, `bugfix/**`, and `task/**` branches.
- **PR Approval:** **No approval required** — merge freely once your work is done and CI passes.
- **Lifetime:** Lives until the epic is complete, then merged into `master`.

---

### `feature/**`, `bugfix/**`, `task/**`
- **Purpose:** Day-to-day implementation tied to a Scrum issue.
  - `feature/**` → new functionality (user story).
  - `bugfix/**` → defect fix.
  - `task/**` → maintenance, refactor, docs, chore.
- **PRs:** Always open a PR to the relevant `develop/**` branch when ready.

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

All names lowercase, hyphen-separated, descriptive, and reference the Scrum issue ID when applicable.

### `develop/**` (epic-level)
Tied to a Scrum **epic** or **sprint goal**. Use a short epic identifier:

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
Tied to a single Scrum **issue**. Include the issue ID and a short slug:

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

## Commit Message Convention

Follow **Conventional Commits**. Format:

```
<type>(<scope>): <short summary>

<optional body — what & why, not how>

<optional footer — issue refs, breaking changes>
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
- Reference the Scrum issue in the footer: `Refs #42` or `Closes #42`.
- One logical change per commit.

### Examples

```
feat(wav): parse 16-bit PCM headers at 8/16/44.1 kHz

Adds parser to extract sample rate, channel count, and data offset
from RIFF/WAVE headers. Required for HPS-side metadata extraction.

Closes #42
```

```
fix(7seg): clamp MM:SS display when track exceeds 59:59

Refs #63
```

```
refactor(mmio): consolidate filter control registers into a struct

Refs #71
```

```
build(pd): regenerate qsys with NIOS II /e core and on-chip RAM
```

---

## Pull Request Convention

### Title

Mirror the commit convention:

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
- [ ] Commits follow Conventional Commits
- [ ] No secrets or board-specific paths hardcoded
- [ ] Documentation updated if behavior changed
```

### PR Rules

- Keep PRs **small and focused** — one issue, one PR when possible.
- All commits **squashed** is acceptable for `feature/**` → `develop/**`; **merge commit** preferred for `develop/**` → `master` to preserve epic history.
- CI must pass before merging into `develop/**` or `master`.
- A PR into `master` must list every issue closed in the epic.

---

## Scrum Integration

- **Epics** → one `develop/**` branch.
- **User stories** → `feature/**` branch.
- **Bugs** → `bugfix/**` branch.
- **Tasks/chores** → `task/**` branch.
- Every branch and PR references the Jira/GitHub issue ID.
- Sprint-end: open PR from active `develop/**` into `master`, tag a release.