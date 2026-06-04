# dotfiles-windows/update-zed.ps1
# Pulls the latest Zed config from the canonical dotfiles repo.

param(
    [string]$DotfilesPath = (Split-Path -Parent $MyInvocation.MyCommand.Path)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Ok($msg)   { Write-Host "   OK   $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "   WARN $msg" -ForegroundColor Yellow }

$zedConfigBaseUrl = "https://raw.githubusercontent.com/WilberC/dotfiles/refs/heads/main/shared/.config/zed"
$zedConfigFiles   = @("keymap.json", "settings.json", "tasks.json")
$zedConfigDir     = "$DotfilesPath\zed"

if (-not (Test-Path $zedConfigDir)) {
    New-Item -ItemType Directory -Path $zedConfigDir -Force | Out-Null
}

foreach ($file in $zedConfigFiles) {
    $url = "$zedConfigBaseUrl/$file"
    $target = "$zedConfigDir\$file"

    try {
        Invoke-WebRequest -Uri $url -OutFile $target -UseBasicParsing
        Write-Ok "zed\$file"
    } catch {
        Write-Warn "Could not pull zed\$file from GitHub - keeping local copy"
    }
}
