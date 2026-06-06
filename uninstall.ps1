# dotfiles-windows/uninstall.ps1
# Run as Administrator: .\uninstall.ps1
#
# Reads uninstall.conf and removes only the selected startup entries, symlinks,
# generated files, and winget packages.

#Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$DotfilesPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$UninstallConfPath = Join-Path $DotfilesPath "uninstall.conf"
$uninstallSummary = [System.Collections.Generic.List[object]]::new()

if (-not (Test-Path $UninstallConfPath)) {
    Write-Host "uninstall.conf not found. Copy uninstall.conf.example to uninstall.conf and choose what to remove." -ForegroundColor Red
    Write-Host "  cp $DotfilesPath\uninstall.conf.example $UninstallConfPath" -ForegroundColor Yellow
    exit 1
}

$conf = @{}
Get-Content $UninstallConfPath | Where-Object {
    $_ -notmatch '^\s*#' -and $_ -match '='
} | ForEach-Object {
    if ($_ -match '^\s*([^#=\s]+)\s*=\s*"(.*?)"') {
        $conf[$matches[1]] = $matches[2]
    } elseif ($_ -match '^\s*([^#=\s]+)\s*=\s*([^#]*)') {
        $conf[$matches[1]] = $matches[2].Trim()
    }
}

function Write-Step($msg) { Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "   OK   $msg" -ForegroundColor Green }
function Write-Skip($msg) { Write-Host "   SKIP $msg" -ForegroundColor DarkGray }
function Write-Warn($msg) { Write-Host "   WARN $msg" -ForegroundColor Yellow }
function Write-Bad($msg)  { Write-Host "   BAD  $msg" -ForegroundColor Red }
function Add-Summary($area, $status, $details) {
    $script:uninstallSummary.Add([pscustomobject]@{
        Area    = $area
        Status  = $status
        Details = $details
    })
}
function Write-Summary {
    Write-Host "`n>> Uninstall summary" -ForegroundColor Cyan
    Write-Host "   Area                         Status Details" -ForegroundColor White
    Write-Host "   ----                         ------ -------" -ForegroundColor White

    foreach ($row in $script:uninstallSummary) {
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
function Test-Enabled($key) {
    return $conf.ContainsKey($key) -and $conf[$key] -eq "true"
}
function Test-Command($name) {
    return $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}
function Normalize-LinkPath($path) {
    if ([string]::IsNullOrWhiteSpace($path)) {
        return ""
    }

    return ([System.IO.Path]::GetFullPath($path)).TrimEnd('\')
}
function Remove-ManagedLink($target, $source) {
    $expectedLinkTarget = Normalize-LinkPath $source

    if (-not (Test-Path $target -PathType Any)) {
        Write-Skip "$target is already absent"
        Add-Summary $target "SKIP" "Already absent"
        return
    }

    $item = Get-Item $target -Force -ErrorAction SilentlyContinue
    $isLink = $item -and $item.LinkType -in @('SymbolicLink', 'Junction')
    if (-not $isLink) {
        Write-Warn "$target exists but is not a symlink or junction; keeping it"
        Add-Summary $target "WARN" "Existing item is not managed by this repo"
        return
    }

    $linkedTarget = @($item.Target)[0]
    $actualLinkTarget = Normalize-LinkPath $linkedTarget
    if ($actualLinkTarget -ne $expectedLinkTarget) {
        Write-Warn "$target points somewhere else; keeping it"
        Write-Host "        Expected: $source" -ForegroundColor Yellow
        Write-Host "        Current:  $linkedTarget" -ForegroundColor Yellow
        Add-Summary $target "WARN" "Link target did not match repo source"
        return
    }

    Remove-Item -LiteralPath $target -Force
    Write-Ok "$target removed"
    Add-Summary $target "OK" "Removed managed link"
}
function Remove-PathIfPresent($path, $area) {
    if (Test-Path $path -PathType Any) {
        Remove-Item -LiteralPath $path -Force -Recurse
        Write-Ok "$path removed"
        Add-Summary $area "OK" "Removed $path"
    } else {
        Write-Skip "$path is already absent"
        Add-Summary $area "SKIP" "Already absent"
    }
}
function Remove-RunStartupApp($name) {
    $runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $entry = Get-ItemProperty -Path $runKey -Name $name -ErrorAction SilentlyContinue
    if ($entry) {
        Remove-ItemProperty -Path $runKey -Name $name -ErrorAction Stop
        Write-Ok "$name autostart removed from HKCU Run"
        Add-Summary "$name autostart" "OK" "Removed from HKCU Run"
    } else {
        Write-Skip "$name autostart is already absent"
        Add-Summary "$name autostart" "SKIP" "Already absent"
    }
}
function Uninstall-WingetPackage($id, $name) {
    Write-Step $name

    winget uninstall --id $id --exact --accept-source-agreements
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "$name uninstalled or queued by winget"
        Add-Summary $name "OK" "winget uninstall completed"
    } else {
        Write-Warn "winget could not uninstall $name. It may already be absent or require manual removal."
        Add-Summary $name "WARN" "winget uninstall exited with $LASTEXITCODE"
    }
}

if (Test-Enabled "STOP_RUNNING_DESKTOP_TOOLS") {
    Write-Step "Stopping desktop tools"

    if (Test-Command "komorebic") {
        & komorebic stop --whkd 2>$null
        Write-Ok "Komorebi/whkd stop requested"
        Add-Summary "Komorebi/whkd" "OK" "Stop requested"
    } else {
        Write-Skip "komorebic was not found on PATH"
        Add-Summary "Komorebi/whkd" "SKIP" "komorebic not found"
    }

    if (Test-Command "yasbc") {
        & yasbc stop 2>$null
        Write-Ok "YASB stop requested"
        Add-Summary "YASB" "OK" "Stop requested"
    } else {
        Write-Skip "yasbc was not found on PATH"
        Add-Summary "YASB" "SKIP" "yasbc not found"
    }
} else {
    Write-Skip "Stopping desktop tools disabled in uninstall.conf"
    Add-Summary "Desktop tools" "SKIP" "Disabled in uninstall.conf"
}

Write-Step "Startup entries"
if (Test-Enabled "REMOVE_KOMOREBI_STARTUP_TASK") {
    $task = Get-ScheduledTask -TaskName "komorebi-startup" -ErrorAction SilentlyContinue
    if ($task) {
        Unregister-ScheduledTask -TaskName "komorebi-startup" -Confirm:$false
        Write-Ok "komorebi-startup task removed"
        Add-Summary "Komorebi login task" "OK" "Removed scheduled task"
    } else {
        Write-Skip "komorebi-startup task is already absent"
        Add-Summary "Komorebi login task" "SKIP" "Already absent"
    }
} else {
    Write-Skip "Komorebi startup task kept"
    Add-Summary "Komorebi login task" "SKIP" "Kept by uninstall.conf"
}

if (Test-Enabled "DISABLE_YASB_AUTOSTART") {
    if (Test-Command "yasbc") {
        & yasbc disable-autostart
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "YASB autostart disabled"
            Add-Summary "YASB autostart" "OK" "Disabled with yasbc"
        } else {
            Write-Warn "yasbc disable-autostart exited with $LASTEXITCODE"
            Add-Summary "YASB autostart" "WARN" "yasbc reported an issue"
        }
    } else {
        Write-Skip "yasbc was not found on PATH"
        Add-Summary "YASB autostart" "SKIP" "yasbc not found"
    }
} else {
    Write-Skip "YASB autostart kept"
    Add-Summary "YASB autostart" "SKIP" "Kept by uninstall.conf"
}

if (Test-Enabled "REMOVE_FLOW_LAUNCHER_AUTOSTART") {
    Remove-RunStartupApp "Flow Launcher"
} else {
    Write-Skip "Flow Launcher autostart kept"
    Add-Summary "Flow Launcher autostart" "SKIP" "Kept by uninstall.conf"
}

if (Test-Enabled "REMOVE_CONFIG_LINKS") {
    Write-Step "Config links"

    $links = [ordered]@{
        "$HOME\.config\komorebi" = "$DotfilesPath\komorebi"
        "$HOME\.config\yasb"     = "$DotfilesPath\yasb"
        "$HOME\.config\whkdrc"   = "$DotfilesPath\komorebi\whkdrc"
        "$HOME\.wezterm.lua"     = "$DotfilesPath\wezterm\.wezterm.lua"
        "$env:APPDATA\Zed"       = "$DotfilesPath\zed"
    }

    foreach ($target in $links.Keys) {
        Remove-ManagedLink $target $links[$target]
    }
} else {
    Write-Skip "Config links kept"
    Add-Summary "Config links" "SKIP" "Kept by uninstall.conf"
}

if (Test-Enabled "REMOVE_GENERATED_RUNTIME_FILES") {
    Write-Step "Generated runtime files"
    Remove-PathIfPresent "$DotfilesPath\komorebi\applications.json" "Komorebi ASC"
    Remove-PathIfPresent "$DotfilesPath\yasb\yasb.log" "YASB log"
} else {
    Write-Skip "Generated runtime files kept"
    Add-Summary "Runtime files" "SKIP" "Kept by uninstall.conf"
}

if (Test-Enabled "REMOVE_FLOW_LAUNCHER_BACKUPS") {
    Write-Step "Flow Launcher backups"
    Get-ChildItem "$DotfilesPath\flow-launcher" -Filter "*.json" -File -ErrorAction SilentlyContinue |
        ForEach-Object { Remove-PathIfPresent $_.FullName "Flow Launcher backup" }
} else {
    Write-Skip "Flow Launcher backups kept"
    Add-Summary "Flow Launcher backups" "SKIP" "Kept by uninstall.conf"
}

$packages = @(
    @{ Key = "REMOVE_KOMOREBI"; Name = "Komorebi"; Id = "LGUG2Z.komorebi" }
    @{ Key = "REMOVE_WHKD"; Name = "whkd"; Id = "LGUG2Z.whkd" }
    @{ Key = "REMOVE_YASB"; Name = "YASB"; Id = "AmN.yasb" }
    @{ Key = "REMOVE_WEZTERM"; Name = "WezTerm"; Id = "wez.wezterm" }
    @{ Key = "REMOVE_POWERTOYS"; Name = "PowerToys"; Id = "Microsoft.PowerToys" }
    @{ Key = "REMOVE_ZED"; Name = "Zed"; Id = "ZedIndustries.Zed" }
    @{ Key = "REMOVE_FLOW_LAUNCHER"; Name = "Flow Launcher"; Id = "Flow-Launcher.Flow-Launcher" }
    @{ Key = "REMOVE_WINDHAWK"; Name = "Windhawk"; Id = "RamenSoftware.Windhawk" }
    @{ Key = "REMOVE_ZEN"; Name = "Zen Browser"; Id = "Zen-Team.Zen-Browser" }
    @{ Key = "REMOVE_OBSIDIAN"; Name = "Obsidian"; Id = "Obsidian.Obsidian" }
)

$selectedPackages = @($packages | Where-Object { Test-Enabled $_["Key"] })
if ($selectedPackages.Count -gt 0) {
    Write-Step "Checking winget"
    if (-not (Test-Command "winget")) {
        Write-Bad "winget not found. Package removal skipped."
        foreach ($package in $selectedPackages) {
            $packageName = $package["Name"]
            Add-Summary $packageName "BAD" "winget not found"
        }
    } else {
        Write-Ok "winget available"
        foreach ($package in $packages) {
            $packageKey = $package["Key"]
            $packageName = $package["Name"]
            $packageId = $package["Id"]

            if (Test-Enabled $packageKey) {
                Uninstall-WingetPackage $packageId $packageName
            } else {
                Write-Step $packageName
                Write-Skip "$packageName kept by uninstall.conf"
                Add-Summary $packageName "SKIP" "Kept by uninstall.conf"
            }
        }
    }
} else {
    Write-Skip "No packages selected for removal"
    Add-Summary "Packages" "SKIP" "No package remove flags were true"
}

Write-Summary
Write-Host "`nDone. Review any WARN/BAD rows above for manual cleanup." -ForegroundColor Green
