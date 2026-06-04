# dotfiles-windows/install.ps1
# Run as Administrator: .\install.ps1
#
# Reads user.conf for all personal settings.
# Safe to re-run — winget skips already installed packages,
# symlinks are skipped if the target already exists.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$DotfilesPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# ── Check user.conf exists ────────────────────────────────────────────────────
if (-not (Test-Path "$DotfilesPath\user.conf")) {
    Write-Host "user.conf not found. Copy user.conf.example to user.conf and fill in your values." -ForegroundColor Red
    Write-Host "  cp $DotfilesPath\user.conf.example $DotfilesPath\user.conf" -ForegroundColor Yellow
    exit 1
}

# ── Load user.conf ────────────────────────────────────────────────────────────
$conf = @{}
Get-Content "$DotfilesPath\user.conf" | Where-Object {
    $_ -notmatch '^\s*#' -and $_ -match '='
} | ForEach-Object {
    $key, $val = $_ -split '=', 2
    $conf[$key.Trim()] = $val.Trim().Trim('"')
}

$theme     = $conf["THEME"]
$wslDistro = $conf["WSL_DISTRO"]
$installWH = $conf["INSTALL_WINDHAWK"] -eq "true"

function Write-Step($msg) { Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "   OK   $msg" -ForegroundColor Green }
function Write-Skip($msg) { Write-Host "   SKIP $msg" -ForegroundColor DarkGray }
function Write-Warn($msg) { Write-Host "   WARN $msg" -ForegroundColor Yellow }
function Write-Info($msg) { Write-Host "   INFO $msg" -ForegroundColor Blue }

# ── 1. Check winget ───────────────────────────────────────────────────────────
Write-Step "Checking winget"
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget not found. Install 'App Installer' from the Microsoft Store."
    exit 1
}
Write-Ok "winget available"

# ── 2. Install packages ───────────────────────────────────────────────────────
Write-Step "Installing packages (skips already installed)"
winget import -i "$DotfilesPath\packages.json" `
    --accept-package-agreements --accept-source-agreements

if (-not $installWH) {
    Write-Skip "Windhawk not requested (set INSTALL_WINDHAWK=true in user.conf to enable)"
} else {
    Write-Ok "Windhawk included in packages.json — already handled above"
}

# ── 3. Apply theme ────────────────────────────────────────────────────────────
Write-Step "Applying theme: $theme"
& "$DotfilesPath\themes\apply-theme.ps1" -Theme $theme -DotfilesPath $DotfilesPath

# ── 4. Symlink configs ────────────────────────────────────────────────────────
Write-Step "Symlinking configs"

$links = @{
    "$HOME\.config\komorebi" = "$DotfilesPath\komorebi"
    "$HOME\.config\yasb"     = "$DotfilesPath\yasb"
    "$HOME\.config\whkdrc"   = "$DotfilesPath\komorebi\whkdrc"
    "$HOME\.wezterm.lua"     = "$DotfilesPath\wezterm\.wezterm.lua"
}

foreach ($target in $links.Keys) {
    $source = $links[$target]
    if (Test-Path $target) {
        Write-Skip "$target (already exists)"
        continue
    }
    New-Item -ItemType SymbolicLink -Path $target -Target $source -Force | Out-Null
    Write-Ok "$target"
}

# ── 5. Register komorebi login task ──────────────────────────────────────────
Write-Step "Registering komorebi login task"
$action   = New-ScheduledTaskAction -Execute "komorebic" -Argument "start --whkd"
$trigger  = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0
Register-ScheduledTask -TaskName "komorebi-startup" `
    -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null
Write-Ok "komorebi-startup task registered"

# ── 6. Windhawk manual steps ──────────────────────────────────────────────────
if ($installWH) {
    Write-Step "Windhawk — manual steps required"
    Write-Info "Windhawk mods must be installed from inside the app."
    Write-Info "Open Windhawk and install these mods in order:"
    Write-Host ""
    Write-Host "   1. windows-11-taskbar-styler    (hides taskbar, YASB takes over)" -ForegroundColor White
    Write-Host "   2. windows-11-start-menu-styler (rounds + darkens Start menu)" -ForegroundColor White
    Write-Host "   3. taskbar-clock-customization  (removes native clock)" -ForegroundColor White
    Write-Host "   4. taskbar-notification-icon-spacing (tightens tray icons)" -ForegroundColor White
    Write-Host ""
    Write-Info "Settings for each mod are in: $DotfilesPath\windhawk\"
    Write-Info "See windhawk\README.md for full instructions."
}

Write-Host "`nDone. Log out and back in, or run: komorebic start --whkd" -ForegroundColor Green
Write-Host "Theme: $theme  |  Edit user.conf to change settings and re-run." -ForegroundColor DarkGray
