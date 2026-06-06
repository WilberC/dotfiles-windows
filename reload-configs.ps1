# dotfiles-windows/reload-configs.ps1
# Reloads configs that do not automatically pick up changes.

param(
    [switch]$All,
    [switch]$Komorebi,
    [switch]$Whkd,
    [switch]$Yasb
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step($msg) { Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "   OK   $msg" -ForegroundColor Green }
function Write-Skip($msg) { Write-Host "   SKIP $msg" -ForegroundColor DarkGray }
function Write-Warn($msg) { Write-Host "   WARN $msg" -ForegroundColor Yellow }
function Write-Bad($msg)  { Write-Host "   BAD  $msg" -ForegroundColor Red }

function Test-Command($name) {
    return $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

function Invoke-KomorebiReload {
    Write-Step "Reloading Komorebi configuration"

    if (-not (Test-Command "komorebic")) {
        Write-Bad "komorebic was not found on PATH"
        return $false
    }

    $komorebiConfig = Join-Path $HOME ".config\komorebi\komorebi.json"

    if (-not (Test-Path -LiteralPath $komorebiConfig)) {
        Write-Bad "komorebi.json was not found at $komorebiConfig"
        return $false
    }

    & komorebic replace-configuration $komorebiConfig

    if ($LASTEXITCODE -eq 0) {
        Write-Ok "$komorebiConfig reloaded"
        return $true
    }

    Write-Bad "komorebic replace-configuration failed with exit code $LASTEXITCODE"
    return $false
}

function Invoke-WhkdRestart {
    Write-Step "Restarting whkd through Komorebi"

    if (-not (Test-Command "komorebic")) {
        Write-Bad "komorebic was not found on PATH"
        return $false
    }

    $komorebiConfig = Join-Path $HOME ".config\komorebi\komorebi.json"

    if (-not (Test-Path -LiteralPath $komorebiConfig)) {
        Write-Bad "komorebi.json was not found at $komorebiConfig"
        return $false
    }

    & komorebic stop --whkd
    & komorebic start --config $komorebiConfig --clean-state --whkd

    if ($LASTEXITCODE -eq 0) {
        Write-Ok "whkd restarted"
        return $true
    }

    Write-Bad "komorebic start --whkd failed with exit code $LASTEXITCODE"
    return $false
}

function Invoke-KomorebiWorkspaceSetup {
    Write-Step "Applying Komorebi workspace setup"

    if (-not (Test-Command "komorebic")) {
        Write-Bad "komorebic was not found on PATH"
        return $false
    }

    & komorebic ensure-named-workspaces 0 game zen terminals zed "dev browsers"
    & komorebic ensure-named-workspaces 1 alt

    & komorebic named-workspace-layout game bsp
    & komorebic named-workspace-layout zen bsp
    & komorebic named-workspace-layout terminals bsp
    & komorebic named-workspace-layout zed bsp
    & komorebic named-workspace-layout "dev browsers" columns
    & komorebic named-workspace-layout alt bsp

    & komorebic named-workspace-tiling game disable
    & komorebic named-workspace-tiling zen enable
    & komorebic named-workspace-tiling terminals enable
    & komorebic named-workspace-tiling zed enable
    & komorebic named-workspace-tiling "dev browsers" enable
    & komorebic named-workspace-tiling alt disable

    $workspaceNames = @("game", "zen", "terminals", "zed", "dev browsers", "alt")
    foreach ($workspaceName in $workspaceNames) {
        & komorebic clear-named-workspace-rules $workspaceName
    }

    & komorebic initial-named-workspace-rule exe steam.exe game
    & komorebic initial-named-workspace-rule exe RiotClientServices.exe game
    & komorebic initial-named-workspace-rule exe "Riot Client.exe" game
    & komorebic initial-named-workspace-rule exe LeagueClient.exe game
    & komorebic initial-named-workspace-rule exe LeagueClientUx.exe game
    & komorebic initial-named-workspace-rule exe "League of Legends.exe" game
    & komorebic initial-named-workspace-rule title "League of Legends" game
    & komorebic initial-named-workspace-rule exe zen.exe zen
    & komorebic initial-named-workspace-rule exe Zen.exe zen
    & komorebic initial-named-workspace-rule exe wezterm-gui.exe terminals
    & komorebic initial-named-workspace-rule exe WezTerm.exe terminals
    & komorebic initial-named-workspace-rule exe wezterm.exe terminals
    & komorebic initial-named-workspace-rule exe zed.exe zed
    & komorebic initial-named-workspace-rule exe Zed.exe zed
    & komorebic initial-named-workspace-rule exe chromium.exe "dev browsers"
    & komorebic initial-named-workspace-rule exe Chromium.exe "dev browsers"

    if ($LASTEXITCODE -eq 0) {
        Write-Ok "Named workspaces and routing rules applied"
        return $true
    }

    Write-Bad "Komorebi workspace setup failed with exit code $LASTEXITCODE"
    return $false
}

function Invoke-YasbRestart {
    Write-Step "Restarting YASB"

    if (-not (Test-Command "yasbc")) {
        Write-Bad "yasbc was not found on PATH"
        return $false
    }

    & yasbc stop
    & yasbc start

    if ($LASTEXITCODE -eq 0) {
        Write-Ok "YASB restarted"
        return $true
    }

    Write-Bad "yasbc start failed with exit code $LASTEXITCODE"
    return $false
}

if (-not ($All -or $Komorebi -or $Whkd -or $Yasb)) {
    $Komorebi = $true
}

$hadFailure = $false

if ($All -or $Komorebi) {
    $hadFailure = -not (Invoke-KomorebiReload) -or $hadFailure
}

if ($All -or $Whkd) {
    $hadFailure = -not (Invoke-WhkdRestart) -or $hadFailure
} else {
    Write-Skip "whkdrc auto-reloads on change"
}

if ($All -or $Yasb) {
    $hadFailure = -not (Invoke-YasbRestart) -or $hadFailure
} else {
    Write-Skip "YASB config and styles are watched"
}

if (-not $hadFailure -and ($All -or $Komorebi -or $Whkd)) {
    $hadFailure = -not (Invoke-KomorebiWorkspaceSetup) -or $hadFailure
}

Write-Skip "WezTerm and Zed watch their linked config files"

if ($hadFailure) {
    exit 1
}
