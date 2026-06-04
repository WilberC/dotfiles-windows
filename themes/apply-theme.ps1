# themes/apply-theme.ps1
# Called by install.ps1 — reads the active theme .conf and patches config files.
# Safe to re-run.

param(
    [string]$Theme        = "rose-pine",
    [string]$DotfilesPath = (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
)

$themeFile = "$DotfilesPath\themes\$Theme.conf"
if (-not (Test-Path $themeFile)) {
    Write-Warning "Theme file not found: $themeFile — skipping"
    return
}

# Parse theme .conf
$t = @{}
Get-Content $themeFile | Where-Object { $_ -notmatch '^\s*#' -and $_ -match '=' } | ForEach-Object {
    $k, $v = $_ -split '=', 2
    $t[$k.Trim()] = $v.Trim().Trim('"')
}

# Parse user.conf
$uc = @{}
Get-Content "$DotfilesPath\user.conf" | Where-Object { $_ -notmatch '^\s*#' -and $_ -match '=' } | ForEach-Object {
    $k, $v = $_ -split '=', 2
    $uc[$k.Trim()] = $v.Trim().Trim('"')
}

# ── Patch wezterm/.wezterm.lua ────────────────────────────────────────────────
$weztermLua = "$DotfilesPath\wezterm\.wezterm.lua"
$lua = Get-Content $weztermLua -Raw

$lua = $lua -replace 'color_scheme\s*=\s*"[^"]*"',                    "color_scheme = `"$($t['WEZTERM_COLOR_SCHEME'])`""
$lua = $lua -replace 'font\s*=\s*wezterm\.font\("[^"]*"',              "font = wezterm.font(`"$($uc['WEZTERM_FONT'])`""
$lua = $lua -replace 'font_size\s*=\s*[\d.]+',                         "font_size = $($uc['WEZTERM_FONT_SIZE'])"
$lua = $lua -replace 'window_background_opacity\s*=\s*[\d.]+',         "window_background_opacity = $($uc['WEZTERM_OPACITY'])"
$lua = $lua -replace 'win32_system_backdrop\s*=\s*"[^"]*"',            "win32_system_backdrop = `"$($uc['WEZTERM_BLUR'])`""

if ($uc['WEZTERM_DEFAULT_SHELL'] -eq "wsl") {
    $distro = $uc['WSL_DISTRO']
    $lua = $lua -replace '-- config\.default_prog.*', "config.default_prog = { `"wsl.exe`", `"--distribution`", `"$distro`" }"
}

Set-Content $weztermLua $lua -NoNewline

# ── Patch yasb/styles.css ─────────────────────────────────────────────────────
$cssFile = "$DotfilesPath\yasb\styles.css"
$css = Get-Content $cssFile -Raw

$css = $css -replace 'background-color:\s*rgba\([^)]+\)',  "background-color: $($t['YASB_BAR_BG'])"
$css = $css -replace 'border-bottom:[^;]+;',               "border-bottom: 1px solid $($t['YASB_BORDER']);"

Set-Content $cssFile $css -NoNewline

# ── Patch komorebi/komorebi.json border colours ───────────────────────────────
$kJson = "$DotfilesPath\komorebi\komorebi.json"
$json  = Get-Content $kJson -Raw | ConvertFrom-Json

$json.border_colours.single.light  = $t['KOMOREBI_BORDER_SINGLE']
$json.border_colours.single.dark   = $t['KOMOREBI_BORDER_SINGLE']
$json.border_colours.stack.light   = $t['KOMOREBI_BORDER_STACK']
$json.border_colours.stack.dark    = $t['KOMOREBI_BORDER_STACK']
$json.border_colours.monocle.light = $t['KOMOREBI_BORDER_MONOCLE']
$json.border_colours.monocle.dark  = $t['KOMOREBI_BORDER_MONOCLE']

$json | ConvertTo-Json -Depth 10 | Set-Content $kJson -NoNewline

Write-Host "   OK   Theme '$Theme' applied" -ForegroundColor Green
