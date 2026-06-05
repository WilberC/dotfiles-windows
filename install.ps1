# dotfiles-windows/install.ps1
# Run as Administrator: .\install.ps1
#
# Reads user.conf for all personal settings.
# Safe to re-run - winget skips already installed packages,
# symlinks are confirmed if already correctly linked.

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
$installFlowLauncher = $conf["INSTALL_FLOW_LAUNCHER"] -eq "true"
$installWH = $conf["INSTALL_WINDHAWK"]  -eq "true"
$setupSummary = [System.Collections.Generic.List[object]]::new()

function Write-Step($msg) { Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "   OK   $msg" -ForegroundColor Green }
function Write-Skip($msg) { Write-Host "   SKIP $msg" -ForegroundColor DarkGray }
function Write-Warn($msg) { Write-Host "   WARN $msg" -ForegroundColor Yellow }
function Write-Info($msg) { Write-Host "   INFO $msg" -ForegroundColor Blue }
function Write-Bad($msg)  { Write-Host "   BAD  $msg" -ForegroundColor Red }
function Add-Summary($area, $status, $details) {
    $script:setupSummary.Add([pscustomobject]@{
        Area    = $area
        Status  = $status
        Details = $details
    })
}
function Write-Summary {
    Write-Host "`n>> Setup summary" -ForegroundColor Cyan
    Write-Host "   Area                         Status Details" -ForegroundColor White
    Write-Host "   ----                         ------ -------" -ForegroundColor White

    foreach ($row in $script:setupSummary) {
        $color = switch ($row.Status) {
            "OK"   { "Green" }
            "BAD"  { "Red" }
            "WARN" { "Yellow" }
            "SKIP" { "DarkGray" }
            default { "White" }
        }

        Write-Host ("   {0,-28} " -f $row.Area) -NoNewline
        Write-Host ("{0,-6}" -f $row.Status) -NoNewline -ForegroundColor $color
        Write-Host " $($row.Details)"
    }
}
function Normalize-LinkPath($path) {
    if ([string]::IsNullOrWhiteSpace($path)) {
        return ""
    }

    return ([System.IO.Path]::GetFullPath($path)).TrimEnd('\')
}
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
Add-Summary "winget" "OK" "Available"

# 2. Install core packages
Write-Step "Installing core packages (skips already installed)"
winget import -i "$DotfilesPath\packages.json" `
    --accept-package-agreements --accept-source-agreements
if ($LASTEXITCODE -ne 0) {
    Write-Warn "winget import reported an issue. Review the output above for any missing packages."
    Add-Summary "Core packages" "WARN" "winget reported an issue; review the output above"
} else {
    Add-Summary "Core packages" "OK" "Installed or already present"
}

# 3. Optional: Flow Launcher
Write-Step "Flow Launcher"
if ($installFlowLauncher) {
    Install-WingetPackage "Flow-Launcher.Flow-Launcher" "Flow Launcher"
    Add-Summary "Flow Launcher" "OK" "Installed or already present"
} else {
    Write-Skip "Flow Launcher (set INSTALL_FLOW_LAUNCHER=true in user.conf to enable)"
    Add-Summary "Flow Launcher" "SKIP" "Disabled in user.conf"
}

# 4. Optional: Windhawk
Write-Step "Windhawk"
if ($installWH) {
    Install-WingetPackage "RamenSoftware.Windhawk" "Windhawk"
    Add-Summary "Windhawk" "OK" "Installed or already present"
} else {
    Write-Skip "Windhawk (set INSTALL_WINDHAWK=true in user.conf to enable)"
    Add-Summary "Windhawk" "SKIP" "Disabled in user.conf"
}

# 5. Pull Zed config
Write-Step "Pulling Zed config"
& "$DotfilesPath\update-zed.ps1" -DotfilesPath $DotfilesPath
Add-Summary "Zed config" "OK" "Pulled latest config files"

# 6. Apply theme
Write-Step "Applying theme: $theme"
& "$DotfilesPath\themes\apply-theme.ps1" -Theme $theme -DotfilesPath $DotfilesPath
Add-Summary "Theme" "OK" "Applied '$theme'"

# 7. Symlink configs
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
    $expectedLinkTarget = Normalize-LinkPath $source
    if (-not (Test-Path $source -PathType Any)) {
        Write-Bad "$target cannot be linked"
        Write-Host "        Missing source: $source" -ForegroundColor Red
        Add-Summary $target "BAD" "Expected source is missing: $source"
        continue
    }

    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    if (Test-Path $target -PathType Any) {
        $item = Get-Item $target -Force -ErrorAction SilentlyContinue
        $isLink = $item -and $item.LinkType -in @('SymbolicLink', 'Junction')
        $linkedTarget = ""
        if ($isLink) {
            $linkedTarget = @($item.Target)[0]
        }
        $actualLinkTarget = Normalize-LinkPath $linkedTarget
        if ($isLink -and $actualLinkTarget -eq $expectedLinkTarget) {
            Write-Ok "$target correctly linked -> $source"
            Add-Summary $target "OK" "Correctly linked"
        } else {
            Write-Bad "$target is not correctly linked"
            Write-Host "        Expected: $source" -ForegroundColor Red
            if ($actualLinkTarget) {
                Write-Host "        Current:  $linkedTarget" -ForegroundColor Red
                Add-Summary $target "BAD" "Wrong link target: $linkedTarget"
            } else {
                Write-Host "        Current:  existing non-link item" -ForegroundColor Red
                Add-Summary $target "BAD" "Existing item is not a symlink or junction"
            }
            Write-Warn "Remove it manually to re-link"
        }
        continue
    }
    New-Item -ItemType SymbolicLink -Path $target -Target $source -Force | Out-Null
    Write-Ok "$target correctly linked -> $source"
    Add-Summary $target "OK" "Created link"
}

# 8. Register komorebi login task
Write-Step "Registering komorebi login task"
$komorebicPath = (Get-Command komorebic -ErrorAction Stop).Source
$action    = New-ScheduledTaskAction -Execute $komorebicPath -Argument "start --whkd"
$trigger   = New-ScheduledTaskTrigger -AtLogOn
$settings  = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest
Register-ScheduledTask -TaskName "komorebi-startup" `
    -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null
Write-Ok "komorebi-startup task registered (elevated, runs at login)"
Add-Summary "Komorebi login task" "OK" "Registered elevated startup task"

# 9. Windhawk manual steps
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
    Add-Summary "Windhawk manual mods" "WARN" "Manual install steps still required"
}

Write-Summary

Write-Host "`nDone. Log out and back in, or run: komorebic start --whkd" -ForegroundColor Green
Write-Host "Theme: $theme  |  Edit user.conf to change settings and re-run." -ForegroundColor DarkGray
