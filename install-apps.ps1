# dotfiles-windows/install-apps.ps1
# Run manually: .\install-apps.ps1
#
# Reads apps.conf and installs only apps set to "true".

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$DotfilesPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppsConfPath = Join-Path $DotfilesPath "apps.conf"

if (-not (Test-Path $AppsConfPath)) {
    Write-Host "apps.conf not found. Copy apps.conf.example to apps.conf and choose apps to install." -ForegroundColor Red
    Write-Host "  cp $DotfilesPath\apps.conf.example $AppsConfPath" -ForegroundColor Yellow
    exit 1
}

$conf = @{}
Get-Content $AppsConfPath | Where-Object {
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

function Install-WingetPackage($id, $name) {
    winget install --id $id --exact `
        --accept-package-agreements --accept-source-agreements
    Write-Ok "$name installed"
}

Write-Step "Checking winget"
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget not found. Install 'App Installer' from the Microsoft Store."
    exit 1
}
Write-Ok "winget available"

$apps = @(
    @{ Key = "INSTALL_ZEN"; Name = "Zen Browser"; Id = "Zen-Team.Zen-Browser" }
    @{ Key = "INSTALL_OBSIDIAN"; Name = "Obsidian"; Id = "Obsidian.Obsidian" }
)

foreach ($app in $apps) {
    Write-Step $app.Name
    if ($conf[$app.Key] -eq "true") {
        Install-WingetPackage $app.Id $app.Name
    } else {
        Write-Skip "$($app.Name) (set $($app.Key)=`"true`" in apps.conf to enable)"
    }
}

Write-Host "`nDone installing selected apps." -ForegroundColor Green
