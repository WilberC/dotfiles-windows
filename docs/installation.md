# Installation

## Prerequisites

Do these manually before running the bootstrap.

### 1. Install a Nerd Font

YASB, WezTerm, Zed terminals, and the workspace indicators require a Nerd Font.
Recommended: BerkeleyMono Nerd Font.

Download, extract, right-click the `.ttf` files, then choose **Install for all
users**.

### 2. Update winget

Open the Microsoft Store, search **App Installer**, and update it.

Winget ships with Windows 11, but it can be outdated on a fresh install:
[App Installer](https://apps.microsoft.com/detail/9NBLGGH4NNS1?hl=es-mx&gl=PE&ocid=pdpshare).

<img width="1087" height="89" alt="App Installer in Microsoft Store" src="https://github.com/user-attachments/assets/ac5fa4ee-d45d-434c-9a77-022acfa4b03d" />

### 3. Enable Developer Mode

Enable Developer Mode so PowerShell can create symlinks without needing
Administrator every time:

**Settings -> System -> For developers -> Developer Mode -> On**

The bootstrap still needs to run as Administrator once.

<img width="880" height="720" alt="Windows Developer Mode setting" src="https://github.com/user-attachments/assets/dc11888d-407a-4962-bed3-7d1dffb6febf" />

### 4. Set PowerShell execution policy

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## Where To Put This Repo

Clone it to a permanent location. The symlinks created by `install.ps1` point
into this directory. If you move the repo later, re-run the bootstrap.

Recommended path:

```powershell
$env:USERPROFILE\dotfiles-windows
```

That expands to `C:\Users\<you>\dotfiles-windows` on a standard install.

Do not clone into `Downloads`, `Desktop`, or any folder you might clean up.

## First-Time Setup

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

- `WSL_DISTRO`: run `wsl --list` to find your distro name
- `WEZTERM_FONT`: must match the Nerd Font you installed
- `THEME`: `rose-pine` or `catppuccin-mocha`
- Optional installers: set `INSTALL_FLOW_LAUNCHER` or `INSTALL_WINDHAWK` to `false` to skip those apps

Everything else has sensible defaults.

### 3. Run the bootstrap as Administrator

Right-click PowerShell, choose **Run as Administrator**, then run:

```powershell
cd $env:USERPROFILE\dotfiles-windows
Get-ChildItem -Recurse -Filter *.ps1 | Unblock-File
.\install.ps1
```

The script will:

- Install core packages via winget
- Install optional packages enabled in `user.conf`
- Pull the latest Zed config from `WilberC/dotfiles`
- Apply your chosen theme to all config files
- Symlink configs from the repo into the locations each app expects
- Register a login task that starts Komorebi and whkd, reloads Komorebi config,
  and reapplies workspaces/rules automatically

### 4. Install Windhawk mods

If `INSTALL_WINDHAWK=true`, open Windhawk after `install.ps1` finishes and
install these mods in order:

| Mod | Purpose |
|-----|---------|
| `windows-11-taskbar-styler` | Hides the native taskbar so YASB takes over |
| `taskbar-auto-hide-when-maximized` | Keeps auto-hide working alongside YASB |
| `windows-11-start-menu-styler` | Rounds and darkens the Start menu |
| `taskbar-clock-customization` | Removes the native clock because YASB shows it |
| `taskbar-notification-icon-spacing` | Tightens tray icon spacing |

For each mod, copy the settings from the matching file in `windhawk/*.yaml`.
Full instructions are in [windhawk/README.md](../windhawk/README.md).

### 5. Set Windows accent color

Go to:

**Settings -> Personalisation -> Colours -> Accent colour**

Recommended values:

- Rose Pine: `#31748f` / Pine
- Catppuccin Mocha: `#89b4fa` / Blue

### 6. Log out and back in

Komorebi starts automatically at login via the scheduled task. The task runs
`.\reload-configs.ps1 -Startup`, which starts Komorebi/whkd, reloads
`komorebi.json`, and reapplies named workspaces/rules. To start it manually
right now:

```powershell
.\reload-configs.ps1 -Startup
```

## New Machine Setup

```powershell
# 1. Clone to the same permanent path
git clone https://github.com/you/dotfiles-windows $env:USERPROFILE\dotfiles-windows
cd $env:USERPROFILE\dotfiles-windows

# 2. Create user.conf, which is gitignored and not cloned
cp user.conf.example user.conf
notepad user.conf

# 3. Bootstrap from an Administrator PowerShell
.\install.ps1

# 4. If INSTALL_WINDHAWK=true, install Windhawk mods manually
```

## Uninstalling

To remove the managed setup, copy and edit the uninstall config:

```powershell
cp uninstall.conf.example uninstall.conf
notepad uninstall.conf
.\uninstall.ps1
```

Every `REMOVE_*` setting controls one package, startup entry, config link, or
generated file group. Set an item to `"false"` to keep it. Config links are only
removed when they still point back into this repo.
