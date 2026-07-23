# ScreenBrightnessControl

ScreenBrightnessControl is an AutoHotkey v2 script for changing a Windows laptop's internal display brightness through WMI. It provides configurable fine and coarse adjustments plus direct minimum and maximum shortcuts.

## Requirements and installation

Install [AutoHotkey v2.0 or later](https://www.autohotkey.com/), then clone or download this repository. Start the script by double-clicking `brightness.ahk` or running:

```powershell
AutoHotkey.exe brightness.ahk
```

## Default hotkeys

| Shortcut | Action |
| --- | --- |
| `Win + ,` | Decrease by 3% |
| `Win + .` | Increase by 3% |
| `Ctrl + Alt + Down` | Decrease by 10% |
| `Ctrl + Alt + Up` | Increase by 10% |
| `Ctrl + Alt + End` | Set to 0% |
| `Ctrl + Alt + Home` | Set to 100% |

Brightness remains within the configured minimum and maximum. The script rereads the current WMI state for every action, then chooses the nearest hardware-supported level in the requested direction. This prevents small steps from stalling on displays that expose only discrete levels. Repeated input at either boundary does not issue redundant WMI writes.

## Configuration

Edit `brightness.ini` beside the script to customize limits, step sizes, or shortcuts. The checked-in file contains the defaults. If the file or an individual key is missing, the script uses its internal default for that value.

```ini
[Brightness]
Minimum=10
Maximum=90
FineStep=2
CoarseStep=5

[Hotkeys]
FineDecrease=#,
FineIncrease=#.
```

Brightness limits must be integers satisfying `0 <= Minimum < Maximum <= 100`; step sizes must be positive integers. A configured boundary that is not supported by the display resolves to the nearest supported hardware level inside the configured range. All six hotkeys must be valid, non-empty, and unique. AutoHotkey modifier symbols are `#` (Win), `^` (Ctrl), `!` (Alt), and `+` (Shift).

## Compatibility and verification

The script controls the first active internal display exposed by Windows WMI. External monitors that require DDC/CI may not work. After changing the script or configuration, validate its syntax with `AutoHotkey.exe /validate brightness.ahk`, then manually verify all six shortcuts, discrete-level stepping in both directions, both boundaries, repeated key presses, on-screen feedback, and an external brightness change between shortcuts.

## License

Licensed under the MIT License. See [LICENSE](LICENSE).
