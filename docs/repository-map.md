# Repository Map

## Layout

```text
dotfiles-windows/
|-- .gitignore
|-- README.md
|-- docs/
|   |-- daily-workflow.md
|   |-- installation.md
|   |-- keybindings.md
|   |-- manual-steps.md
|   |-- overview.md
|   `-- repository-map.md
|-- user.conf.example
|-- user.conf
|-- packages.json
|-- install.ps1
|-- update-zed.ps1
|-- themes/
|   |-- rose-pine.conf
|   |-- catppuccin-mocha.conf
|   `-- apply-theme.ps1
|-- komorebi/
|   |-- komorebi.json
|   `-- whkdrc
|-- yasb/
|   |-- config.yaml
|   `-- styles.css
|-- wezterm/
|   `-- .wezterm.lua
|-- zed/
|   |-- keymap.json
|   |-- settings.json
|   `-- tasks.json
|-- windhawk/
|   |-- README.md
|   |-- taskbar-styler.yaml
|   |-- taskbar-auto-hide.yaml
|   |-- start-menu-styler.yaml
|   |-- taskbar-clock.yaml
|   `-- notification-icon.yaml
`-- flow-launcher/
```

## Important Files

| File | Purpose |
|------|---------|
| `user.conf.example` | Committed reference config; copy to `user.conf` locally |
| `user.conf` | Gitignored personal settings |
| `packages.json` | winget manifest for always-installed core packages |
| `install.ps1` | Bootstrap: install core and optional packages, apply theme, symlink configs, register login task |
| `update-zed.ps1` | Pulls latest Zed config from `WilberC/dotfiles` |
| `themes/*.conf` | Theme palettes and per-app values |
| `themes/apply-theme.ps1` | Patches WezTerm, YASB, and Komorebi from the active theme |
| `komorebi/komorebi.json` | BSP layout, workspaces, themed borders |
| `komorebi/whkdrc` | `alt+hjkl` focus and move bindings, workspace shortcuts |
| `yasb/config.yaml` | Workspaces, layout, clock, CPU, memory, volume, battery, network, power menu |
| `yasb/styles.css` | Bar theme patched by `apply-theme.ps1` |
| `wezterm/.wezterm.lua` | Acrylic blur, font, tab bar, pane keybinds |
| `zed/*.json` | Zed config pulled from `WilberC/dotfiles` |
| `windhawk/*.yaml` | Manual Windhawk mod settings |
| `flow-launcher/` | Drop Flow Launcher backups here |

## Symlinks Created By install.ps1

```text
$HOME\.config\komorebi  ->  dotfiles-windows\komorebi\
$HOME\.config\yasb      ->  dotfiles-windows\yasb\
$HOME\.config\whkdrc    ->  dotfiles-windows\komorebi\whkdrc
$HOME\.wezterm.lua      ->  dotfiles-windows\wezterm\.wezterm.lua
$env:APPDATA\Zed        ->  dotfiles-windows\zed\
```
