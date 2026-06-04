# dotfiles-windows

Windows ricing setup — Hyprland look and feel on Windows 11.

Tiling window manager, custom status bar replacing the native taskbar, acrylic
terminal, app launcher, and a themed Start menu. One script installs and wires
everything together. Configs live in this repo; apps read them via symlinks.

---

## Stack

Every tool here is load-bearing. This is an opinionated setup — nothing is
decorative.

| Tool | Role | Why this one |
|------|------|-------------|
| [Komorebi](https://github.com/LGUG2Z/komorebi) | Tiling window manager | BSP tiling, per-workspace layouts, fine-grained control |
| [whkd](https://github.com/LGUG2Z/whkd) | Hotkey daemon | Pairs with Komorebi, Hyprland-style `alt+hjkl` bindings |
| [YASB](https://github.com/da-rth/yasb) | Status bar | Waybar equivalent — replaces the native taskbar entirely |
| [WezTerm](https://wezfurlong.org/wezterm/) | Terminal | Best acrylic/blur support on Windows 11, Lua config |
| [Flow Launcher](https://www.flowlauncher.com/) | App launcher | Rofi/Wofi equivalent for Windows |
| [PowerToys](https://github.com/microsoft/PowerToys) | System utilities | Color picker, PowerRename, window snapping hints, and more |
| [Windhawk](https://windhawk.net/) | Windows UI patcher | **Required** — hides the native taskbar so YASB owns the screen |

> **Why Windhawk is not optional:** without it you get two bars on screen —
> the native Windows taskbar and YASB. Windhawk patches the taskbar to zero
> height and opacity, making YASB the only bar. The setup looks broken without it.

---

## Themes

| Theme | Feel |
|-------|------|
| `rose-pine` | Warm dark, closest to Hyprland rice aesthetic **(default)** |
| `catppuccin-mocha` | Cool dark, popular alternative |

Switch by editing `THEME` in `user.conf`, then re-running `.\install.ps1`.

---

## Prerequisites

Before running the bootstrap, do these manually — they can't be scripted:

**1. Install a Nerd Font**

YASB and the workspace indicators require a Nerd Font. Recommended:
[JetBrains Mono Nerd Font](https://www.nerdfonts.com/font-downloads)

Download → extract → right-click the `.ttf` files → **Install for all users**.

**2. Make sure winget is up to date**

Open the Microsoft Store → search **App Installer** → update it.
Winget ships with Windows 11 but may be outdated on a fresh install.

[Link](https://apps.microsoft.com/detail/9NBLGGH4NNS1?hl=es-mx&gl=PE&ocid=pdpshare)

<img width="1087" height="89" alt="image" src="https://github.com/user-attachments/assets/ac5fa4ee-d45d-434c-9a77-022acfa4b03d" />

**3. Enable Developer Mode (for symlinks without Admin every time)**

*Settings → System → For developers → Developer Mode → On*

This lets PowerShell create symlinks. The bootstrap still needs to run as
Administrator once, but subsequent `New-Item -SymbolicLink` calls will work
from a normal shell.

<img width="880" height="720" alt="image" src="https://github.com/user-attachments/assets/dc11888d-407a-4962-bed3-7d1dffb6febf" />


**4. Set execution policy**

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

---

## Where to put this repo

Clone it to a permanent location. The symlinks created by `install.ps1` point
into this directory — if you move the repo later, you'll need to re-run the
bootstrap to fix them.

**Recommended path:** `$env:USERPROFILE\dotfiles-windows`

That expands to `C:\Users\<you>\dotfiles-windows` on a standard install.

```powershell
git clone https://github.com/you/dotfiles-windows $env:USERPROFILE\dotfiles-windows
```

Do **not** clone into `Downloads`, `Desktop`, or any folder you might clean up.

---

## First-time setup

### 1. Clone to its permanent home

```powershell
git clone https://github.com/you/dotfiles-windows $env:USERPROFILE\dotfiles-windows
cd $env:USERPROFILE\dotfiles-windows
```

### 2. Create your personal config

```powershell
cp user.conf.example user.conf
notepad user.conf
```

Minimum edits required:
- `WSL_DISTRO` — run `wsl --list` to find your distro name
- `WEZTERM_FONT` — must match the Nerd Font you installed
- `THEME` — `rose-pine` or `catppuccin-mocha`

Everything else has sensible defaults.

### 3. Run the bootstrap as Administrator

Right-click PowerShell → **Run as Administrator**, then:

```powershell
cd $env:USERPROFILE\dotfiles-windows
.\install.ps1
```

The script will:
- Install all packages via winget
- Apply your chosen theme to all config files
- Symlink configs from the repo into the locations each app expects
- Register a login task that starts Komorebi + whkd automatically

### 4. Install Windhawk mods (manual — required for the full look)

Open Windhawk after `install.ps1` finishes and install these mods in order:

1. `windows-11-taskbar-styler`         — hides native taskbar (YASB takes over)
2. `windows-taskbar-auto-hide`         — keeps auto-hide working alongside YASB
3. `windows-11-start-menu-styler`      — rounds and darkens the Start menu
4. `taskbar-clock-customization`       — removes native clock (YASB shows it)
5. `taskbar-notification-icon-spacing` — tightens tray icon spacing

For each mod, copy the settings from the matching file in `windhawk/*.json`.
Full instructions in [`windhawk/README.md`](windhawk/README.md).

### 5. Set Windows accent color

*Settings → Personalisation → Colours → Accent colour*

Rose Pine: `#31748f` (Pine) — Catppuccin Mocha: `#89b4fa` (Blue)

### 6. Log out and back in

Komorebi starts automatically at login via the scheduled task. Or start it
manually right now:

```powershell
komorebic start --whkd
```

---

## Keybindings

| Key | Action |
|-----|--------|
| `Alt + H/J/K/L` | Focus window left/down/up/right |
| `Alt + Shift + H/J/K/L` | Move window left/down/up/right |
| `Alt + Ctrl + H/L` | Resize horizontal |
| `Alt + Ctrl + K/J` | Resize vertical |
| `Alt + 1–5` | Switch workspace |
| `Alt + Shift + 1–5` | Move window to workspace |
| `Alt + T` | Toggle tiling |
| `Alt + M` | Toggle monocle |
| `Alt + F` | Toggle maximize |
| `Alt + Shift + F` | Toggle float |
| `Alt + ←/→` | Cycle stack |
| `Alt + Shift + R` | Retile |
| `Alt + Shift + Q` | Close window |

---

## Daily workflow

### Editing configs

All configs live in this repo. The symlinks created by `install.ps1` make the
repo the source of truth — editing a file here changes it for the running app.

| Config | Auto-reloads? |
|--------|--------------|
| `yasb/config.yaml` | Yes — `watch_config: true` |
| `yasb/styles.css` | Yes — `watch_stylesheet: true` |
| `wezterm/.wezterm.lua` | Yes — WezTerm watches it |
| `komorebi/komorebi.json` | No — run `komorebic reload-configuration` |
| `komorebi/whkdrc` | Yes — whkd restarts on change |

### Switching themes

```powershell
# Edit user.conf: change THEME="catppuccin-mocha"
notepad user.conf

# Re-run the bootstrap — only the theme step does real work
.\install.ps1
```

### After editing, commit to the repo

```powershell
cd $env:USERPROFILE\dotfiles-windows
git add .
git commit -m "tweak komorebi gaps"
git push
```

### Updating the package list

```powershell
winget export -o packages.json
git add packages.json && git commit -m "update packages"
```

### Backing up Flow Launcher settings

In Flow Launcher: *Settings → General → Backup / Restore → Backup*

The backup lands in `%APPDATA%\FlowLauncher\Backups`. Copy it into
`flow-launcher/` in this repo and commit it.

---

## Setting up on a new machine

```powershell
# 1. Clone to the same permanent path
git clone https://github.com/you/dotfiles-windows $env:USERPROFILE\dotfiles-windows
cd $env:USERPROFILE\dotfiles-windows

# 2. Create user.conf (gitignored, not cloned)
cp user.conf.example user.conf
notepad user.conf   # set WSL_DISTRO, font, theme

# 3. Bootstrap
.\install.ps1       # run as Administrator

# 4. Windhawk mods (manual — see step 4 above)
```

---

## Repo structure

```
dotfiles-windows/
├── .gitignore
├── user.conf.example          ← committed reference — copy to user.conf locally
├── user.conf                  ← gitignored — your personal settings
├── packages.json              ← winget manifest (core packages)
├── install.ps1                ← bootstrap: install + theme + symlink + login task
├── README.md
├── themes/
│   ├── rose-pine.conf         ← full Rose Pine palette + per-app values
│   ├── catppuccin-mocha.conf  ← full Catppuccin Mocha palette
│   └── apply-theme.ps1        ← patches wezterm, yasb, komorebi from active theme
├── komorebi/
│   ├── komorebi.json          ← BSP layout, 5 workspaces, themed borders
│   └── whkdrc                 ← alt+hjkl focus/move, alt+1-5 workspaces
├── yasb/
│   ├── config.yaml            ← workspaces, layout, clock, cpu, memory, volume, battery, network, power menu
│   └── styles.css             ← bar theme (patched by apply-theme.ps1)
├── wezterm/
│   └── .wezterm.lua           ← acrylic blur, font, tab bar, pane keybinds
├── windhawk/
│   ├── README.md              ← manual install instructions + mod order
│   ├── taskbar-styler.json    ← hides native taskbar
│   ├── start-menu-styler.json ← rounds + darkens Start menu
│   ├── taskbar-clock.json     ← removes native clock
│   └── notification-icons.json
└── flow-launcher/             ← drop your Flow Launcher backup here (gitignored)
```

**Symlinks created by `install.ps1`:**

```
$HOME\.config\komorebi  →  dotfiles-windows\komorebi\
$HOME\.config\yasb      →  dotfiles-windows\yasb\
$HOME\.config\whkdrc    →  dotfiles-windows\komorebi\whkdrc
$HOME\.wezterm.lua      →  dotfiles-windows\wezterm\.wezterm.lua
```

---

## What is not automated

| Thing | Why | Workaround |
|-------|-----|-----------|
| Windhawk mod installation | No CLI available | Manual — see step 4 and `windhawk/README.md` |
| Nerd Font installation | Not on winget | Download from nerdfonts.com, install manually (prerequisite) |
| Flow Launcher settings | App-managed | Backup via app settings, commit to `flow-launcher/` |
| Windows accent color | Settings app only | Set manually — see step 5 |
