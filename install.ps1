# dotfiles-windows/install.ps1
# Run as Administrator: .\install.ps1
#
# Reads user.conf for all personal settings.
# Safe to re-run - winget skips already installed packages,
# symlinks are skipped if already correctly linked.

#Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$DotfilesPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Check user.conf exists
if (-not (Test-Path "$DotfilesPath\user.conf")) {
    Write-Host "user.conf not found. Copy user.conf.example to user.conf and fill in your values." -ForegroundColor Red
    Write-Host "  cp $DotfilesPath\user.conf.example $DotfilesPath\user.conf" -ForegroundColor Yellow
    exit 1
}

# Load user.conf
$conf = @{}
Get-Content "$DotfilesPath\user.conf" | Where-Object {
    $_ -notmatch '^\s*#' -and $_ -match '='
} | ForEach-Object {
    if ($_ -match '^\s*([^#=\s]+)\s*=\s*"(.*?)"') {
        $conf[$matches[1]] = $matches[2]
    } elseif ($_ -match '^\s*([^#=\s]+)\s*=\s*([^#]*)') {
        $conf[$matches[1]] = $matches[2].Trim()
    }
}

$theme     = $conf["THEME"]
$installPT = $conf["INSTALL_POWERTOYS"] -eq "true"
$installFlowLauncher = $conf["INSTALL_FLOW_LAUNCHER"] -eq "true"
$installWH = $conf["INSTALL_WINDHAWK"]  -eq "true"

function Write-Step($msg) { Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "   OK   $msg" -ForegroundColor Green }
function Write-Skip($msg) { Write-Host "   SKIP $msg" -ForegroundColor DarkGray }
function Write-Warn($msg) { Write-Host "   WARN $msg" -ForegroundColor Yellow }
function Write-Info($msg) { Write-Host "   INFO $msg" -ForegroundColor Blue }
function Install-WingetPackage($id, $name) {
    winget install --id $id `
        --accept-package-agreements --accept-source-agreements
    Write-Ok "$name installed"
}

# 1. Check winget
Write-Step "Checking winget"
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget not found. Install 'App Installer' from the Microsoft Store."
    exit 1
}
Write-Ok "winget available"

# 2. Install core packages
Write-Step "Installing core packages (skips already installed)"
winget import -i "$DotfilesPath\packages.json" `
    --accept-package-agreements --accept-source-agreements
if ($LASTEXITCODE -ne 0) {
    Write-Warn "winget import reported an issue. Review the output above for any missing packages."
}

# 3. Optional: PowerToys
Write-Step "PowerToys"
if ($installPT) {
    Install-WingetPackage "Microsoft.PowerToys" "PowerToys"
} else {
    Write-Skip "PowerToys (set INSTALL_POWERTOYS=true in user.conf to enable)"
}

# 4. Optional: Flow Launcher
Write-Step "Flow Launcher"
if ($installFlowLauncher) {
    Install-WingetPackage "Flow-Launcher.Flow-Launcher" "Flow Launcher"
} else {
    Write-Skip "Flow Launcher (set INSTALL_FLOW_LAUNCHER=true in user.conf to enable)"
}

# 5. Optional: Windhawk
Write-Step "Windhawk"
if ($installWH) {
    Install-WingetPackage "RamenSoftware.Windhawk" "Windhawk"
} else {
    Write-Skip "Windhawk (set INSTALL_WINDHAWK=true in user.conf to enable)"
}

# 6. Pull Zed config
Write-Step "Pulling Zed config"
& "$DotfilesPath\update-zed.ps1" -DotfilesPath $DotfilesPath

# 7. Apply theme
Write-Step "Applying theme: $theme"
& "$DotfilesPath\themes\apply-theme.ps1" -Theme $theme -DotfilesPath $DotfilesPath

# 8. Symlink configs
Write-Step "Symlinking configs"

$links = [ordered]@{
    "$HOME\.config\komorebi" = "$DotfilesPath\komorebi"
    "$HOME\.config\yasb"     = "$DotfilesPath\yasb"
    "$HOME\.config\whkdrc"   = "$DotfilesPath\komorebi\whkdrc"
    "$HOME\.wezterm.lua"     = "$DotfilesPath\wezterm\.wezterm.lua"
    "$env:APPDATA\Zed"       = "$DotfilesPath\zed"
}

foreach ($target in $links.Keys) {
    $source    = $links[$target]
    $parentDir = Split-Path $target -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    if (Test-Path $target -PathType Any) {
        $item = Get-Item $target -Force -ErrorAction SilentlyContinue
        if ($item -and $item.LinkType -eq 'SymbolicLink' -and $item.Target.TrimEnd('\') -eq $source.TrimEnd('\')) {
            Write-Skip "$target (already linked)"
        } else {
            Write-Warn "$target already exists and is not the expected symlink - remove it manually to re-link"
        }
        continue
    }
    New-Item -ItemType SymbolicLink -Path $target -Target $source -Force | Out-Null
    Write-Ok "$target -> $source"
}

# 9. Register komorebi login task
Write-Step "Registering komorebi login task"
$action    = New-ScheduledTaskAction -Execute "komorebic" -Argument "start --whkd"
$trigger   = New-ScheduledTaskTrigger -AtLogOn
$settings  = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest
Register-ScheduledTask -TaskName "komorebi-startup" `
    -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null
Write-Ok "komorebi-startup task registered (elevated, runs at login)"

# 10. Windhawk manual steps
if ($installWH) {
    Write-Step "Windhawk - manual steps required"
    Write-Info "Windhawk mods must be installed from inside the app."
    Write-Info "Open Windhawk and install these mods in order:"
    Write-Host ""
    Write-Host "   1. windows-11-taskbar-styler          (hides taskbar, YASB takes over)" -ForegroundColor White
    Write-Host "   2. taskbar-auto-hide-when-maximized    (keeps auto-hide working with YASB)" -ForegroundColor White
    Write-Host "   3. windows-11-start-menu-styler        (rounds + darkens Start menu)" -ForegroundColor White
    Write-Host "   4. taskbar-clock-customization         (removes native clock)" -ForegroundColor White
    Write-Host "   5. taskbar-notification-icon-spacing   (tightens tray icons)" -ForegroundColor White
    Write-Host ""
    Write-Info "Settings for each mod are in: $DotfilesPath\windhawk\"
    Write-Info "See windhawk\README.md for full instructions."
}

Write-Host "`nDone. Log out and back in, or run: komorebic start --whkd" -ForegroundColor Green
Write-Host "Theme: $theme  |  Edit user.conf to change settings and re-run." -ForegroundColor DarkGray
