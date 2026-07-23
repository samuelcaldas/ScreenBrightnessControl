# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

Validate syntax (Windows, no runtime needed):
```powershell
AutoHotkey.exe /validate brightness.ahk
```

Run the script:
```powershell
AutoHotkey.exe brightness.ahk
```

Check for whitespace errors before committing:
```powershell
git diff --check
```

No build, compilation, or package install step exists.

## Architecture

Two `.ahk` files, one `.ini` config, no external dependencies.

**`brightness_configuration.ahk`** — configuration layer:
- `load_configuration()` reads `brightness.ini` beside the script; missing keys fall back to hardcoded defaults
- `validate_configuration()` normalizes numeric fields, enforces `0 <= Minimum < Maximum <= 100`, positive steps, non-empty unique hotkeys
- `create_hotkey_definitions()` produces a list of `{key, kind, value}` objects — `kind` is `"relative"` (step) or `"absolute"` (min/max)
- `register_hotkeys()` stages all hotkeys as `"Off"` first, then enables them atomically; rolls back on failure

**`brightness.ahk`** — runtime layer:
- `apply_brightness()` is the core per-keypress path: opens WMI, queries current state, computes ideal target, selects nearest supported level in the correct direction, writes only when value changes
- `select_supported_brightness()` / `consider_supported_level()` implement directional discrete-level selection — critical for displays that expose only a few WMI levels; always advances in the requested direction
- `set_brightness()` tolerates empty WMI return codes (some providers do not surface status through AHK)
- `show_brightness_osd()` posts a `SHELLHOOK` message to trigger the native Windows brightness flyout; failure is silently swallowed after one notification

**`brightness.ini`** — user-editable config; script reads it on every keypress (not cached) so edits take effect immediately without restart.

## Key Invariants

- WMI state is reread on every action — never cached between keypresses
- Hotkeys registered atomically: all succeed or all roll back
- Level selection is directional: at a boundary, repeated presses must not re-issue WMI writes
- `set_brightness` skips the write when `target_brightness == current_brightness`
- OSD failure never blocks brightness change; only the first failure notifies

## Testing

No automated tests. Manual checklist after any change:
1. All six hotkeys work
2. Fine and coarse steps in both directions
3. Repeated presses at min/max — no redundant WMI writes
4. External brightness change between presses — script reads fresh WMI state
5. Discrete-level hardware: small steps always advance in requested direction
6. Malformed `brightness.ini` — startup error tray notification, clean exit
7. Missing `brightness.ini` — defaults apply, script starts normally
