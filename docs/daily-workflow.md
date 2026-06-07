# Daily Workflow

## Editing Configs

All configs live in this repo. The symlinks created by `install.ps1` make the
repo the source of truth, so editing a file here changes it for the running app.

| Config | Auto-reloads? |
|--------|---------------|
| `yasb/config.yaml` | Yes, via `watch_config: true` |
| `yasb/styles.css` | Yes, via `watch_stylesheet: true` |
| `wezterm/.wezterm.lua` | Yes, WezTerm watches it |
| `wezterm/workspace-defs.lua` | Yes, through the watched WezTerm config |
| `zed/*.json` | Yes, pulled from `WilberC/dotfiles`, then watched by Zed |
| `komorebi/komorebi.json` | No, run `.\reload-configs.ps1` |
| `komorebi/whkdrc` | Yes, whkd restarts on change |

To reload only the configs that need manual help:

```powershell
.\reload-configs.ps1
```

If a watched app needs a hard refresh anyway:

```powershell
.\reload-configs.ps1 -Whkd
.\reload-configs.ps1 -Yasb
.\reload-configs.ps1 -All
```

## Opening WezTerm Project Workspaces

Named project layouts live in `wezterm/workspace-defs.lua`. Each tab and pane
launches through Windows WezTerm into WSL2 with `wsl.exe -d Ubuntu --cd ...`.
Use `/mnt/c/...` paths for repos that live on the Windows filesystem.

Normal WezTerm startup stays as a fresh WSL terminal at `~`. Project layouts
and any future save/restore flow are manual only.

Inside WezTerm, press:

```text
Ctrl+Shift+O
```

To open one from PowerShell:

```powershell
wezterm start --always-new-process -- dotfiles-windows
```

See [WezTerm workspaces](wezterm-workspaces.md) for the workspace schema.

## Switching Themes

```powershell
# Edit user.conf and change THEME="catppuccin-mocha"
notepad user.conf

# Re-run the bootstrap; only the theme step does real work
.\install.ps1
```

## Updating Zed Config

Zed config is canonical in `WilberC/dotfiles` and is pulled during
`install.ps1`. To refresh only Zed without running the full bootstrap:

```powershell
.\update-zed.ps1
```

## Committing Changes

```powershell
cd $env:USERPROFILE\dotfiles-windows
git add .
git commit -m "tweak komorebi gaps"
git push
```

## Updating The Package List

```powershell
winget export -o packages.json
git add packages.json
git commit -m "update packages"
```

## Backing Up Flow Launcher Settings

In Flow Launcher:

**Settings -> General -> Backup / Restore -> Backup**

The backup lands in `%APPDATA%\FlowLauncher\Backups`. Copy it into
`flow-launcher/` in this repo and commit it.
