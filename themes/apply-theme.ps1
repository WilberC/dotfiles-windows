# themes/apply-theme.ps1
# Called by install.ps1 - reads the active theme .conf and patches config files.
# Safe to re-run.

param(
    [string]$Theme        = "rose-pine",
    [string]$DotfilesPath = (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
)

$themeFile = "$DotfilesPath\themes\$Theme.conf"
if (-not (Test-Path $themeFile)) {
    Write-Warning "Theme file not found: $themeFile - skipping"
    return
}

# Parse theme .conf
$t = @{}
Get-Content $themeFile | Where-Object { $_ -notmatch '^\s*#' -and $_ -match '=' } | ForEach-Object {
    if ($_ -match '^\s*([^#=\s]+)\s*=\s*"(.*?)"') {
        $t[$matches[1]] = $matches[2]
    } elseif ($_ -match '^\s*([^#=\s]+)\s*=\s*([^#]*)') {
        $t[$matches[1]] = $matches[2].Trim()
    }
}

# Validate required theme keys
$requiredKeys = @(
    'WEZTERM_COLOR_SCHEME', 'ZED_THEME', 'YASB_BAR_BG', 'YASB_BORDER',
    'KOMOREBI_BORDER_SINGLE', 'KOMOREBI_BORDER_STACK', 'KOMOREBI_BORDER_MONOCLE'
)
foreach ($k in $requiredKeys) {
    if (-not $t.ContainsKey($k)) {
        Write-Warning "Theme '$Theme' is missing key '$k' - aborting theme apply"
        return
    }
}

# Parse user.conf
$uc = @{}
Get-Content "$DotfilesPath\user.conf" | Where-Object { $_ -notmatch '^\s*#' -and $_ -match '=' } | ForEach-Object {
    if ($_ -match '^\s*([^#=\s]+)\s*=\s*"(.*?)"') {
        $uc[$matches[1]] = $matches[2]
    } elseif ($_ -match '^\s*([^#=\s]+)\s*=\s*([^#]*)') {
        $uc[$matches[1]] = $matches[2].Trim()
    }
}

# Patch wezterm/.wezterm.lua
$weztermLua = "$DotfilesPath\wezterm\.wezterm.lua"
$lua = Get-Content $weztermLua -Raw

$weztermColorScheme = $t['WEZTERM_COLOR_SCHEME']
$weztermFont        = $uc['WEZTERM_FONT']
$weztermFontSize    = $uc['WEZTERM_FONT_SIZE']
$weztermOpacity     = $uc['WEZTERM_OPACITY']
$weztermBlur        = $uc['WEZTERM_BLUR']

$lua = $lua -replace 'color_scheme\s*=\s*"[^"]*"',            "color_scheme = `"$weztermColorScheme`""
$lua = $lua -replace 'font\s*=\s*wezterm\.font\("[^"]*"(?:,\s*\{[^}]*\})?\)', "font = wezterm.font(`"$weztermFont`")"
$lua = $lua -replace 'font_size\s*=\s*[\d.]+',                 "font_size = $weztermFontSize"
$lua = $lua -replace 'window_background_opacity\s*=\s*[\d.]+', "window_background_opacity = $weztermOpacity"
$lua = $lua -replace 'win32_system_backdrop\s*=\s*"[^"]*"',    "win32_system_backdrop = `"$weztermBlur`""

# Patch WSL default shell - matches both the comment (first run) and the live line (re-runs)
if ($uc['WEZTERM_DEFAULT_SHELL'] -eq "wsl") {
    $distro = $uc['WSL_DISTRO']
    $lua = $lua -replace '(?:-- )?config\.default_prog\s*=.*', "config.default_prog = { `"wsl.exe`", `"--distribution`", `"$distro`" }"
}

Set-Content $weztermLua $lua -NoNewline

# Patch zed/settings.json
$zedSettings = "$DotfilesPath\zed\settings.json"
if (Test-Path $zedSettings) {
    $zed = Get-Content $zedSettings -Raw

    $zedTheme = $t['ZED_THEME']
    $zedFont  = $uc['WEZTERM_FONT']

    $zed = $zed -replace '("dark"\s*:\s*")[^"]*(")', "`${1}$zedTheme`${2}"
    $zed = $zed -replace '("buffer_font_family"\s*:\s*")[^"]*(")', "`${1}$zedFont`${2}"
    $zed = $zed -replace '("terminal"\s*:\s*\{[^}]*?"font_family"\s*:\s*")[^"]*(")', "`${1}$zedFont`${2}"

    Set-Content $zedSettings $zed -NoNewline
}

# Patch yasb/styles.css
$cssFile = "$DotfilesPath\yasb\styles.css"
$css = Get-Content $cssFile -Raw

$yasbBarBg = $t['YASB_BAR_BG']
$yasbBorder = $t['YASB_BORDER']

$css = $css -replace '(?s)(\.yasb-bar\s*\{[^}]*?)background-color:\s*[^;]+;', "`${1}background-color: $yasbBarBg;"
$css = $css -replace '(?s)(\.yasb-bar\s*\{[^}]*?)border-bottom:\s*[^;]+;',    "`${1}border-bottom: 1px solid $yasbBorder;"

Set-Content $cssFile $css -NoNewline

# Patch komorebi/komorebi.json border colours (raw, preserves formatting)
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
