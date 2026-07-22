# Repository Guidelines

## Project Structure & Module Organization

This repository is intentionally small. `brightness.ahk` owns startup, WMI brightness control, hardware-level selection, and on-screen feedback. `brightness_configuration.ahk` loads and validates settings and registers dynamic hotkeys; `brightness.ini` defines limits, fine/coarse steps, and six user-facing hotkeys. `README.md` documents installation and usage; `LICENSE` contains the project license. There are no separate test, asset, build, or documentation directories. Keep configuration and runtime responsibilities separated.

## Build, Test, and Development Commands

No compilation, package installation, or linting step is required. Install AutoHotkey v1.1.33 or newer, then run on Windows:

```powershell
AutoHotkey.exe brightness.ahk
```

Double-clicking `brightness.ahk` is also suitable for local use. Before submitting changes, run `git diff --check` to detect whitespace errors. Review `git diff` to confirm that only intended files changed.

## Coding Style & Naming Conventions

Follow AutoHotkey v1 syntax. Use four-space indentation, opening braces on declaration lines, and short single-purpose functions. Name functions and variables in descriptive `snake_case`; use `UPPER_CASE` for constants. Keep user-adjustable values in `brightness.ini`: brightness limits must remain within `0..100`, steps must be positive integers, and hotkeys must be valid, non-empty, and unique. Preserve fail-fast validation before registering any hotkey. Keep WMI `Level[]` selection directional and constrained to supported levels inside configured bounds. Keep `README.md` synchronized whenever configuration or visible behavior changes.

## Testing Guidelines

The project has no automated test framework or coverage requirement. Test manually on Windows with and without `brightness.ini`. Exercise all six dynamic hotkeys, fine/coarse steps, absolute minimum/maximum actions, repeated presses, and the OSD. On hardware with discrete WMI levels, confirm small steps always advance in the requested direction and configured boundaries resolve to supported values inside the range. Change brightness externally between presses to confirm WMI state is reread. Test malformed settings and a monitor without WMI support; failures must notify clearly without partial registration or out-of-range writes. Check multi-monitor behavior when available.

## Commit & Integration Guidelines

The current history does not establish a strict commit convention. Use concise, imperative subjects such as `Fix brightness lower bound`, and keep each commit scoped to one logical change. Work in local Git worktrees; do not create remote pull requests. Merge completed work into `master`, then repeat the relevant manual checks on the merged branch. Include a short change summary and testing evidence when handing work off.
