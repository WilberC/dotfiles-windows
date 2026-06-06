# dotfiles-windows/reload-configs.ps1
# Reloads configs that do not automatically pick up changes.

param(
    [switch]$All,
    [switch]$Startup,
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
    param(
        [int]$Attempts = 1,
        [int]$DelaySeconds = 1
    )

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

    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        & komorebic replace-configuration $komorebiConfig

        if ($LASTEXITCODE -eq 0) {
            Write-Ok "$komorebiConfig reloaded"
            return $true
        }

        if ($attempt -lt $Attempts) {
            Write-Warn "Komorebi reload attempt $attempt failed; retrying in $DelaySeconds seconds"
            Start-Sleep -Seconds $DelaySeconds
        }
    }

    Write-Bad "komorebic replace-configuration failed with exit code $LASTEXITCODE"
    return $false
}

function Invoke-KomorebiStart {
    param(
        [int]$Attempts = 1,
        [int]$DelaySeconds = 1
    )

    Write-Step "Starting Komorebi and whkd"

    if (-not (Test-Command "komorebic")) {
        Write-Bad "komorebic was not found on PATH"
        return $false
    }

    $komorebiConfig = Join-Path $HOME ".config\komorebi\komorebi.json"

    if (-not (Test-Path -LiteralPath $komorebiConfig)) {
        Write-Bad "komorebi.json was not found at $komorebiConfig"
        return $false
    }

    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        & komorebic start --config $komorebiConfig --clean-state --whkd

        if ($LASTEXITCODE -eq 0) {
            Write-Ok "Komorebi and whkd started"
            return $true
        }

        if ($attempt -lt $Attempts) {
            Write-Warn "Komorebi start attempt $attempt failed; retrying in $DelaySeconds seconds"
            Start-Sleep -Seconds $DelaySeconds
        }
    }

    Write-Bad "komorebic start --whkd failed with exit code $LASTEXITCODE"
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

    & komorebic stop --whkd 2>$null
    $stopExitCode = $LASTEXITCODE

    if ($stopExitCode -ne 0) {
        Write-Warn "Komorebi was not already running; starting it now"
    }

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
    & komorebic initial-named-workspace-rule path "C:\Program Files\Zen Browser\zen.exe" zen
    & komorebic initial-named-workspace-rule title "Zen Browser" zen
    & komorebic named-workspace-rule exe zen.exe zen
    & komorebic named-workspace-rule exe Zen.exe zen
    & komorebic named-workspace-rule path "C:\Program Files\Zen Browser\zen.exe" zen
    & komorebic named-workspace-rule title "Zen Browser" zen
    & komorebic initial-named-workspace-rule exe wezterm-gui.exe terminals
    & komorebic initial-named-workspace-rule exe WezTerm.exe terminals
    & komorebic initial-named-workspace-rule exe wezterm.exe terminals
    & komorebic initial-named-workspace-rule class org.wezfurlong.wezterm terminals
    & komorebic initial-named-workspace-rule exe zed.exe zed
    & komorebic initial-named-workspace-rule exe Zed.exe zed
    & komorebic initial-named-workspace-rule exe chromium.exe "dev browsers"
    & komorebic initial-named-workspace-rule exe Chromium.exe "dev browsers"
    & komorebic initial-named-workspace-rule exe chrome.exe "dev browsers"
    & komorebic initial-named-workspace-rule title Chromium "dev browsers"

    for ($attempt = 1; $attempt -le 5; $attempt++) {
        Start-Sleep -Seconds 2
        & komorebic enforce-workspace-rules
    }

    & komorebic focus-monitor-workspace 1 0
    & komorebic focus-monitor-workspace 0 3

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

if (-not ($All -or $Startup -or $Komorebi -or $Whkd -or $Yasb)) {
    $Komorebi = $true
}

$hadFailure = $false

if ($Startup) {
    Write-Step "Waiting for login startup"
    Start-Sleep -Seconds 5

    $hadFailure = -not (Invoke-KomorebiStart -Attempts 10 -DelaySeconds 2) -or $hadFailure
    $hadFailure = -not (Invoke-KomorebiReload -Attempts 10 -DelaySeconds 2) -or $hadFailure

    if (-not $hadFailure) {
        $hadFailure = -not (Invoke-KomorebiWorkspaceSetup) -or $hadFailure
    }

    Write-Skip "YASB uses its own autostart"
    Write-Skip "WezTerm and Zed watch their linked config files"

    if ($hadFailure) {
        exit 1
    }

    exit 0
}

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
