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

    & komorebic reload-configuration

    if ($LASTEXITCODE -eq 0) {
        Write-Ok "komorebi/komorebi.json reloaded"
        return $true
    }

    Write-Bad "komorebic reload-configuration failed with exit code $LASTEXITCODE"
    return $false
}

function Invoke-WhkdRestart {
    Write-Step "Restarting whkd through Komorebi"

    if (-not (Test-Command "komorebic")) {
        Write-Bad "komorebic was not found on PATH"
        return $false
    }

    & komorebic stop --whkd
    & komorebic start --whkd

    if ($LASTEXITCODE -eq 0) {
        Write-Ok "whkd restarted"
        return $true
    }

    Write-Bad "komorebic start --whkd failed with exit code $LASTEXITCODE"
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

Write-Skip "WezTerm and Zed watch their linked config files"

if ($hadFailure) {
    exit 1
}
