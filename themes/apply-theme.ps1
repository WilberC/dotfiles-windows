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

# Validate required theme keys
$requiredKeys = @(
    'WEZTERM_COLOR_SCHEME', 'YASB_BAR_BG', 'YASB_BORDER',
    'KOMOREBI_BORDER_SINGLE', 'KOMOREBI_BORDER_STACK', 'KOMOREBI_BORDER_MONOCLE'
)
foreach ($k in $requiredKeys) {
    if (-not $t.ContainsKey($k)) {
        Write-Warning "Theme '$Theme' is missing key '$k' — aborting theme apply"
        return
    }
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

$lua = $lua -replace 'color_scheme\s*=\s*"[^"]*"',            "color_scheme = `"$($t['WEZTERM_COLOR_SCHEME'])`""
$lua = $lua -replace 'font\s*=\s*wezterm\.font\("[^"]*"',      "font = wezterm.font(`"$($uc['WEZTERM_FONT'])`""
$lua = $lua -replace 'font_size\s*=\s*[\d.]+',                 "font_size = $($uc['WEZTERM_FONT_SIZE'])"
$lua = $lua -replace 'window_background_opacity\s*=\s*[\d.]+', "window_background_opacity = $($uc['WEZTERM_OPACITY'])"
$lua = $lua -replace 'win32_system_backdrop\s*=\s*"[^"]*"',    "win32_system_backdrop = `"$($uc['WEZTERM_BLUR'])`""

# Patch WSL default shell — matches both the comment (first run) and the live line (re-runs)
if ($uc['WEZTERM_DEFAULT_SHELL'] -eq "wsl") {
    $distro = $uc['WSL_DISTRO']
    $lua = $lua -replace '(?:-- )?config\.default_prog\s*=.*', "config.default_prog = { `"wsl.exe`", `"--distribution`", `"$distro`" }"
}

Set-Content $weztermLua $lua -NoNewline

# ── Patch yasb/styles.css ─────────────────────────────────────────────────────
$cssFile = "$DotfilesPath\yasb\styles.css"
$css = Get-Content $cssFile -Raw

$css = $css -replace '(?<=\.yasb-bar\s*\{[^}]*)background-color:\s*[^;]+;', "background-color: $($t['YASB_BAR_BG']);"
$css = $css -replace '(?<=\.yasb-bar\s*\{[^}]*)border-bottom:\s*[^;]+;',    "border-bottom: 1px solid $($t['YASB_BORDER']);"

Set-Content $cssFile $css -NoNewline

# ── Patch komorebi/komorebi.json border colours (raw, preserves formatting) ──
$kJsonPath = "$DotfilesPath\komorebi\komorebi.json"
$kRaw      = Get-Content $kJsonPath -Raw

foreach ($border in @(
    @{ name = 'single';  color = $t['KOMOREBI_BORDER_SINGLE']  },
    @{ name = 'stack';   color = $t['KOMOREBI_BORDER_STACK']   },
    @{ name = 'monocle'; color = $t['KOMOREBI_BORDER_MONOCLE'] }
)) {
    $n   = $border.name
    $c   = $border.color
    $rep = '${1}' + $c + '${2}'
    # Replace the "light" value inside this border type's inline object
    $kRaw = $kRaw -replace "(?s)(`"$n`"\s*:\s*\{[^}]*?`"light`"\s*:\s*`")[^`"]*(`")", $rep
    # Replace the "dark" value inside this border type's inline object
    $kRaw = $kRaw -replace "(?s)(`"$n`"\s*:\s*\{[^}]*?`"dark`"\s*:\s*`")[^`"]*(`")", $rep
}

Set-Content $kJsonPath $kRaw -NoNewline

Write-Host "   OK   Theme '$Theme' applied" -ForegroundColor Green
