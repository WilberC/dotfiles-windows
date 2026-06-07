local defs = require("workspace-defs")

local M = {}

local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", [["'"']]) .. "'"
end

local function title_command(title)
  if not title or title == "" then
    return nil
  end

  return "printf '\\033]2;%s\\007' " .. shell_quote(title)
end

local function interactive_command(pane_def)
  local parts = {}
  local title = title_command(pane_def.title)
  if title then
    table.insert(parts, title)
  end

  if pane_def.command and pane_def.command ~= "" then
    table.insert(parts, pane_def.command)
  end

  table.insert(parts, "exec ${SHELL:-bash} -l")
  return table.concat(parts, "; ")
end

local function wsl_args(pane_def, workspace_def)
  local distro = pane_def.distro or workspace_def.distro or defs.distro or "Ubuntu"
  local cwd = pane_def.cwd or workspace_def.cwd or "~"
  local args = { "wsl.exe", "-d", distro, "--cd", cwd }

  if pane_def.title or pane_def.command then
    table.insert(args, "--exec")
    table.insert(args, "bash")
    table.insert(args, "-lc")
    table.insert(args, interactive_command(pane_def))
  end

  return args
end

local function pane_spec(tab_def, pane_def, workspace_def)
  local spec = {}
  for key, value in pairs(tab_def) do
    spec[key] = value
  end
  for key, value in pairs(pane_def or {}) do
    spec[key] = value
  end

  spec.args = wsl_args(spec, workspace_def)
  return spec
end

local function normalize_direction(split)
  if split == "bottom" or split == "down" then
    return "Bottom"
  end
  if split == "left" then
    return "Left"
  end
  if split == "top" or split == "up" then
    return "Top"
  end
  return "Right"
end

local function apply_splits(root_pane, tab_def, workspace_def)
  local panes = tab_def.panes or {}
  local last_pane = root_pane

  for index = 2, #panes do
    local def = panes[index]
    local target = root_pane
    if def.target == "last" then
      target = last_pane
    end

    last_pane = target:split({
      direction = normalize_direction(def.split),
      size = def.size or 0.5,
      args = pane_spec(tab_def, def, workspace_def).args,
    })
  end
end

function M.launch(wezterm, mux, name)
  local workspace_def = defs.workspaces[name]
  if not workspace_def then
    wezterm.log_error("Unknown WezTerm workspace: " .. tostring(name))
    return nil
  end

  local tabs = workspace_def.tabs or {}
  if #tabs == 0 then
    wezterm.log_error("Workspace has no tabs: " .. tostring(name))
    return nil
  end

  local first_tab = tabs[1]
  local first_pane = first_tab.panes and first_tab.panes[1] or first_tab
  local tab, root_pane, window = mux.spawn_window({
    workspace = name,
    args = pane_spec(first_tab, first_pane, workspace_def).args,
  })
  tab:set_title(first_tab.title or workspace_def.label or name)
  apply_splits(root_pane, first_tab, workspace_def)

  for index = 2, #tabs do
    local tab_def = tabs[index]
    local tab_pane = tab_def.panes and tab_def.panes[1] or tab_def
    local new_tab, new_root = window:spawn_tab({
      args = pane_spec(tab_def, tab_pane, workspace_def).args,
    })
    new_tab:set_title(tab_def.title or ("tab " .. index))
    apply_splits(new_root, tab_def, workspace_def)
  end

  window:gui_window():maximize()
  return window
end

function M.gui_startup(wezterm, mux, cmd)
  local requested = nil

  if cmd and cmd.args and defs.workspaces[cmd.args[1]] then
    requested = cmd.args[1]
  end

  if requested and defs.workspaces[requested] then
    M.launch(wezterm, mux, requested)
    return
  end

  local _, _, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end

function M.selector(wezterm)
  local choices = {}
  local names = {}

  for name, _ in pairs(defs.workspaces or {}) do
    table.insert(names, name)
  end
  table.sort(names)

  for _, name in ipairs(names) do
    local workspace_def = defs.workspaces[name]
    table.insert(choices, {
      id = name,
      label = workspace_def.label or name,
    })
  end

  return wezterm.action_callback(function(window, pane)
    window:perform_action(wezterm.action.InputSelector({
      title = "Open workspace",
      fuzzy = true,
      choices = choices,
      action = wezterm.action_callback(function(_, _, id)
        if id then
          M.launch(wezterm, wezterm.mux, id)
        end
      end),
    }), pane)
  end)
end

return M
