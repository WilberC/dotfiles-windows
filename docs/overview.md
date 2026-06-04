# Overview

This is an opinionated Windows 11 rice inspired by Hyprland setups.

It combines a tiling window manager, custom status bar, acrylic terminal, app
launcher, editor config, and optional Windows shell patches. Configs live in
this repo; the apps read them through symlinks created by `install.ps1`.

## Stack

The core setup is Komorebi, whkd, YASB, WezTerm, and Zed. Optional tools can
be enabled or skipped in `user.conf`.

| Tool | Role | Why this one |
|------|------|--------------|
| [Komorebi](https://github.com/LGUG2Z/komorebi) | Tiling window manager | BSP tiling, per-workspace layouts, fine-grained control |
| [whkd](https://github.com/LGUG2Z/whkd) | Hotkey daemon | Pairs with Komorebi, Hyprland-style `alt+hjkl` bindings |
| [YASB](https://github.com/da-rth/yasb) | Status bar | Waybar equivalent; replaces the native taskbar |
| [WezTerm](https://wezfurlong.org/wezterm/) | Terminal | Strong acrylic and blur support on Windows 11, Lua config |
| [Zed](https://zed.dev/) | Code editor | Fast editor with Vim mode, autosave, and themed settings |
| [Flow Launcher](https://www.flowlauncher.com/) | Optional app launcher | Rofi/Wofi equivalent for Windows |
| [PowerToys](https://github.com/microsoft/PowerToys) | System utilities | Color picker, PowerRename, window snapping hints, and more |
| [Windhawk](https://windhawk.net/) | Optional Windows UI patcher | Hides the native taskbar so YASB owns the screen |

## Why Windhawk Completes The Look

Without Windhawk you get two bars on screen: the native Windows taskbar and
YASB. Windhawk patches the taskbar to zero height and opacity, making YASB the
only visible bar.

## Themes

| Theme | Feel |
|-------|------|
| `rose-pine` | Warm dark, closest to the Hyprland rice aesthetic, default |
| `catppuccin-mocha` | Cool dark, popular alternative |

Switch by editing `THEME` in `user.conf`, then re-running `.\install.ps1`.
