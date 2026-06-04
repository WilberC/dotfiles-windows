# dotfiles-windows

Windows ricing setup: Hyprland-style tiling, status bar, terminal, launcher,
editor settings, and Windows UI patches for Windows 11.

This repo is the source of truth for the configs. `install.ps1` installs the
core tools plus optional tools enabled in `user.conf`, applies the selected
theme, creates symlinks, and registers the Komorebi startup task.

## Quick Start

```powershell
git clone https://github.com/you/dotfiles-windows $env:USERPROFILE\dotfiles-windows
cd $env:USERPROFILE\dotfiles-windows
cp user.conf.example user.conf
notepad user.conf
Get-ChildItem -Recurse -Filter *.ps1 | Unblock-File
.\install.ps1
```

Run the bootstrap from an Administrator PowerShell window the first time.

## Optional Apps

Extra personal apps are installed separately from the automatic bootstrap. Copy
the example config, choose the apps you want, then run the manual app installer:

```powershell
cp apps.conf.example apps.conf
notepad apps.conf
.\install-apps.ps1
```

This keeps `install.ps1` focused on the dotfiles setup while `install-apps.ps1`
only installs apps enabled in `apps.conf`.

## Docs

| Start here | What it covers |
|------------|----------------|
| [Overview](docs/overview.md) | Stack, themes, and how the pieces fit together |
| [Installation](docs/installation.md) | Prerequisites, first-time setup, and new machine setup |
| [Keybindings](docs/keybindings.md) | Komorebi and whkd shortcuts |
| [Daily workflow](docs/daily-workflow.md) | Editing configs, switching themes, updating Zed, and backups |
| [Repository map](docs/repository-map.md) | File layout and symlink targets |
| [Manual steps](docs/manual-steps.md) | Things the script cannot automate |

## Important

Windhawk is optional, but required for the full look. Without it, the native
Windows taskbar and YASB both appear on screen. If `INSTALL_WINDHAWK=true`,
follow the Windhawk section in
[Installation](docs/installation.md#4-install-windhawk-mods) and the detailed
mod notes in [windhawk/README.md](windhawk/README.md).

## Themes

- `rose-pine`: warm dark, closest to the Hyprland rice aesthetic, default
- `catppuccin-mocha`: cool dark, popular alternative

Switch themes by editing `THEME` in `user.conf`, then re-run `.\install.ps1`.
