# Windhawk mods

Windhawk mods are installed from inside the app — they can't be scripted via
the command line. This folder documents which mods to install and what settings
to apply in each one to get the Hyprland-like look.

After running install.ps1, open Windhawk and install each mod below.
Settings are in the matching .json file in this folder.

## Install order matters

1. `windows-11-taskbar-styler`         ← hides/floats the taskbar
2. `windows-taskbar-auto-hide`         ← keeps auto-hide working with YASB
3. `windows-11-start-menu-styler`      ← rounds and darkens the start menu
4. `taskbar-clock-customization`       ← removes clock from taskbar (YASB has it)
5. `taskbar-notification-icon-spacing` ← cleans up the tray

## Strategy

YASB is your bar. The goal with Windhawk is to make the native Windows taskbar
invisible so YASB owns the bottom/top of the screen without two bars fighting.

The Taskbar Styler mod below sets the taskbar to 0 height with auto-hide,
effectively removing it. If you ever need the native taskbar back, just
disable the mod in Windhawk.
