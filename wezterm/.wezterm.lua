-- dotfiles-windows/wezterm/.wezterm.lua
-- Values marked "(patched)" are overwritten by themes/apply-theme.ps1
local wezterm = require("wezterm")
local config  = wezterm.config_builder()

-- Appearance (patched by apply-theme.ps1)
config.color_scheme = "rose-pine"
config.window_background_opacity = 0.94
config.win32_system_backdrop = "Acrylic"          # Acrylic | Tabbed | Mica | Disable"          # Acrylic | Tabbed | Mica | Disable"          # Acrylic | Tabbed | Mica | Disable"
config.text_background_opacity   = 1.0
config.window_decorations        = "RESIZE"
config.window_padding            = { left = 12, right = 12, top = 10, bottom = 10 }

-- Font (patched by apply-theme.ps1)
config.font      = wezterm.font("JetBrains Mono", { weight = "Regular" })
config.font_size = 13.0

-- Tab bar
config.enable_tab_bar               = true
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar            = false
config.tab_bar_at_bottom            = true

-- Cursor
config.default_cursor_style  = "BlinkingBar"
config.cursor_blink_ease_in  = "Constant"
config.cursor_blink_ease_out = "Constant"
config.cursor_blink_rate     = 500

config.scrollback_lines = 10000

-- Keybindings
local act = wezterm.action
config.keys = {
  { key = "t",   mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "w",   mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = false }) },
  { key = "Tab", mods = "CTRL",       action = act.ActivateTabRelative(1) },
  { key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },
  { key = "\\",  mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "-",   mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "h",   mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Left") },
  { key = "l",   mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Right") },
  { key = "k",   mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Up") },
  { key = "j",   mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Down") },
  { key = "=",   mods = "CTRL",       action = act.IncreaseFontSize },
  { key = "-",   mods = "CTRL",       action = act.DecreaseFontSize },
  { key = "0",   mods = "CTRL",       action = act.ResetFontSize },
}

-- Default shell (patched by apply-theme.ps1 when WEZTERM_DEFAULT_SHELL=wsl)
-- config.default_prog = { "wsl.exe", "--distribution", "Ubuntu" }

return config
