# Windhawk mods

Windhawk mods are installed from inside the app - they can't be scripted via
the command line. This folder documents which mods to install and what settings
to apply in each one to get the Hyprland-like look.

Keep future Windhawk settings aligned with a Linux tiling desktop feel:
minimal native chrome, YASB as the real bar, compact tray spacing, and
Komorebi/whkd handling the window-management workflow. When Windhawk exposes
new settings, use the pasted fields as the schema and tune the values toward
that goal instead of copying defaults directly.

After running install.ps1, open Windhawk and install each mod below.
Settings are in the matching `.yaml` file in this folder. The Windhawk Settings
tab uses this YAML-like format, not JSON.

## Install order matters

1. `windows-11-taskbar-styler` - hides/floats the taskbar
2. `taskbar-auto-hide-when-maximized` - keeps auto-hide working with YASB
3. `windows-11-start-menu-styler` - rounds and darkens the start menu
4. `taskbar-clock-customization` - removes clock from taskbar (YASB has it)
5. `taskbar-notification-icon-spacing` - cleans up the tray

## Settings files

Apply these from each mod's Settings tab:

| Windhawk mod | Settings file |
| --- | --- |
| `windows-11-taskbar-styler` | `taskbar-styler.yaml` |
| `taskbar-auto-hide-when-maximized` | `taskbar-auto-hide.yaml` |
| `windows-11-start-menu-styler` | `start-menu-styler.yaml` |
| `taskbar-clock-customization` | `taskbar-clock.yaml` |
| `taskbar-notification-icon-spacing` | `notification-icon.yaml` |

## Strategy

YASB is your bar. The goal with Windhawk is to make the native Windows taskbar
invisible so YASB owns the bottom/top of the screen without two bars fighting.

The Taskbar Styler mod below sets the taskbar to 0 height with auto-hide,
effectively removing it. If you ever need the native taskbar back, just
disable the mod in Windhawk.
