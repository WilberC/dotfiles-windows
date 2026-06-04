# dotfiles-windows

Windows ricing setup — Hyprland look and feel on Windows 11.

## Stack

| Tool | Role | Package ID |
|------|------|-----------|
| [Komorebi](https://github.com/LGUG2Z/komorebi) | Tiling window manager | `LGUG2Z.komorebi` |
| [whkd](https://github.com/LGUG2Z/whkd) | Hotkey daemon | `LGUG2Z.whkd` |
| [YASB](https://github.com/da-rth/yasb) | Status bar (replaces taskbar) | `da-rth.yasb` |
| [WezTerm](https://wezfurlong.org/wezterm/) | Terminal with acrylic blur | `wez.wezterm` |
| [Flow Launcher](https://www.flowlauncher.com/) | App launcher | `Flow-Launcher.Flow-Launcher` |
| [PowerToys](https://github.com/microsoft/PowerToys) | System utilities | `Microsoft.PowerToys` |
| [Windhawk](https://windhawk.net/) | Windows UI patcher | `RamenSoftware.Windhawk` |

## Themes

| Theme | Feel |
|-------|------|
| `rose-pine` | Warm dark, closest to Hyprland rice aesthetic **(default)** |
| `catppuccin-mocha` | Cool dark, popular alternative |

Switch theme in `user.conf`, then re-run `.\install.ps1`.

## Structure

```
dotfiles-windows/
├── .gitignore
├── user.conf.example          ← commit this; copy to user.conf locally
├── user.conf                  ← gitignored — your personal settings
├── packages.json              ← winget manifest
├── install.ps1                ← bootstrap script
├── README.md
├── themes/
│   ├── rose-pine.conf
│   ├── catppuccin-mocha.conf
│   └── apply-theme.ps1        ← patches configs from active theme
├── komorebi/
│   ├── komorebi.json
│   └── whkdrc
├── yasb/
│   ├── config.yaml
│   └── styles.css
├── wezterm/
│   └── .wezterm.lua
├── windhawk/
│   ├── README.md              ← manual install instructions
│   ├── taskbar-styler.json    ← hides native taskbar (YASB takes over)
│   ├── start-menu-styler.json ← rounds/darkens Start menu
│   ├── taskbar-clock.json     ← removes native clock
│   └── notification-icons.json
└── flow-launcher/             ← drop your Flow Launcher backup here
```

## First-time setup

```powershell
# 1. Clone the repo
git clone https://github.com/you/dotfiles-windows ~/Downloads/dotfiles-windows
cd ~/Downloads/dotfiles-windows

# 2. Create your personal config
cp user.conf.example user.conf
# Edit user.conf — set your WSL distro name, font, theme, etc.

# 3. Run the bootstrap (as Administrator)
.\install.ps1
```

## Subsequent machines / re-runs

```powershell
.\install.ps1   # safe to re-run, skips what's already done
```

## Windhawk (manual step)

Windhawk mods can't be scripted — install them from inside the app after running `install.ps1`.
Open Windhawk and install in this order:

1. `windows-11-taskbar-styler`         — hides native taskbar, YASB takes over
2. `windows-taskbar-auto-hide`         — keeps auto-hide working with YASB
3. `windows-11-start-menu-styler`      — rounds and darkens Start menu
4. `taskbar-clock-customization`       — removes native clock (YASB has it)
5. `taskbar-notification-icon-spacing` — tightens tray icon spacing

Settings for each mod are in `windhawk/*.json`. See [`windhawk/README.md`](windhawk/README.md) for full instructions.

## Updating the package list

```powershell
winget export -o packages.json
```

## Notes

- `work_area_offset.top: 40` in `komorebi.json` reserves space for YASB
- Acrylic blur in WezTerm requires Windows 11
- `user.conf` is gitignored — never committed. `user.conf.example` is the committed reference
- Flow Launcher: back up via *Settings → General → Backup*, commit to `flow-launcher/`
