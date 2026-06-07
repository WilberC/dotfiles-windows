-- dotfiles-windows/wezterm/.wezterm.lua
-- Values marked "(patched)" are overwritten by themes/apply-theme.ps1
local wezterm = require("wezterm")
local config_dir = wezterm.config_dir
local default_repo_dir = wezterm.home_dir .. "\\dotfiles-windows\\wezterm"

package.path = config_dir .. "\\?.lua;" .. config_dir .. "/?.lua;" .. package.path
package.path = default_repo_dir .. "\\?.lua;" .. default_repo_dir .. "/?.lua;" .. package.path
wezterm.add_to_config_reload_watch_list(config_dir .. "\\workspace-defs.lua")
wezterm.add_to_config_reload_watch_list(config_dir .. "\\workspaces.lua")
wezterm.add_to_config_reload_watch_list(default_repo_dir .. "\\workspace-defs.lua")
wezterm.add_to_config_reload_watch_list(default_repo_dir .. "\\workspaces.lua")

local mux     = wezterm.mux
local config  = wezterm.config_builder()
local workspaces = require("workspaces")

wezterm.on("gui-startup", function(cmd)
  workspaces.gui_startup(wezterm, mux, cmd)
end)

-- Appearance (patched by apply-theme.ps1)
config.color_scheme = "rose-pine"
config.window_background_opacity = 0.92
config.win32_system_backdrop = "Acrylic"
config.text_background_opacity   = 1.0
config.window_decorations        = "RESIZE"
config.window_padding            = { left = 12, right = 12, top = 10, bottom = 10 }
config.colors = {
  selection_fg = "#191724",
  selection_bg = "#9ccfd8",
}

-- Font (patched by apply-theme.ps1)
config.font = wezterm.font("JetBrainsMono Nerd Font")
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
local workspace_selector = workspaces.selector(wezterm)
local copy_or_interrupt = wezterm.action_callback(function(window, pane)
  if window:get_selection_text_for_pane(pane) ~= "" then
    window:perform_action(act.CopyTo("Clipboard"), pane)
  else
    window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
  end
end)

local show_shortcuts = wezterm.action_callback(function(window, pane)
  window:perform_action(act.InputSelector({
    title = "Useful shortcuts",
    fuzzy = true,
    choices = {
      { id = "section_useful", label = "-- Useful shortcuts --" },
      { id = "split_right", label = "Ctrl+Shift+\\  Split pane right" },
      { id = "split_down",  label = "Ctrl+Shift+-  Split pane down" },
      { id = "move_left",   label = "Ctrl+Shift+H  Move to left pane" },
      { id = "move_down",   label = "Ctrl+Shift+J  Move to lower pane" },
      { id = "move_up",     label = "Ctrl+Shift+K  Move to upper pane" },
      { id = "move_right",  label = "Ctrl+Shift+L  Move to right pane" },
      { id = "close_pane",  label = "Ctrl+W        Close current pane" },
      { id = "new_tab",     label = "Ctrl+T        New tab" },
      { id = "close_tab",   label = "Ctrl+Shift+W  Close current tab" },
      { id = "next_tab",    label = "Ctrl+Tab      Next tab" },
      { id = "prev_tab",    label = "Ctrl+Shift+Tab Previous tab" },
      { id = "workspace",   label = "Ctrl+Shift+O  Open project workspace" },
      { id = "search",      label = "Ctrl+F        Search scrollback" },
      { id = "section_other", label = "-- Other shortcuts --" },
      { id = "all_actions", label = "Open full WezTerm action list" },
    },
    action = wezterm.action_callback(function(inner_window, inner_pane, id)
      local actions = {
        split_right = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
        split_down  = act.SplitVertical({ domain = "CurrentPaneDomain" }),
        move_left   = act.ActivatePaneDirection("Left"),
        move_down   = act.ActivatePaneDirection("Down"),
        move_up     = act.ActivatePaneDirection("Up"),
        move_right  = act.ActivatePaneDirection("Right"),
        close_pane  = act.CloseCurrentPane({ confirm = false }),
        new_tab     = act.SpawnTab("CurrentPaneDomain"),
        close_tab   = act.CloseCurrentTab({ confirm = false }),
        next_tab    = act.ActivateTabRelative(1),
        prev_tab    = act.ActivateTabRelative(-1),
        workspace   = workspace_selector,
        search      = act.Search("CurrentSelectionOrEmptyString"),
        all_actions = act.ShowLauncherArgs({ flags = "FUZZY|KEY_ASSIGNMENTS" }),
      }

      if id and actions[id] then
        inner_window:perform_action(actions[id], inner_pane)
      end
    end),
  }), pane)
end)

config.keys = {
  { key = "o",   mods = "CTRL|SHIFT", action = workspace_selector },
  { key = "p",   mods = "CTRL|SHIFT", action = show_shortcuts },
  { key = "c",   mods = "CTRL",       action = copy_or_interrupt },
  { key = "f",   mods = "CTRL",       action = act.Search("CurrentSelectionOrEmptyString") },
  { key = "v",   mods = "CTRL",       action = act.PasteFrom("Clipboard") },

  -- Ghostty/macOS-style splits, adapted for Windows to avoid the Super key.
  { key = "d",   mods = "CTRL",       action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "d",   mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "w",   mods = "CTRL",       action = act.CloseCurrentPane({ confirm = false }) },
  { key = "t",   mods = "CTRL",       action = act.SpawnTab("CurrentPaneDomain") },

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

config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = "Right" } },
    mods = "NONE",
    action = act.PasteFrom("Clipboard"),
  },
}

-- Default shell (patched by apply-theme.ps1 when WEZTERM_DEFAULT_SHELL=wsl)
config.default_prog = { "wsl.exe", "--distribution", "Ubuntu", "--cd", "~" }

return config
