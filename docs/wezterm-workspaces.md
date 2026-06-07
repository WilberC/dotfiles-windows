# WezTerm Workspaces

This setup replaces the macOS `gtab`/Ghostty AppleScript pattern with native
WezTerm Lua running from the Windows-side config.

## Files

| File | Purpose |
|------|---------|
| `wezterm/.wezterm.lua` | Windows WezTerm entrypoint, symlinked to `$HOME\.wezterm.lua` |
| `wezterm/wezterm.lua` | Directory-style entrypoint for `$HOME\.config\wezterm` |
| `wezterm/workspaces.lua` | Workspace launcher: windows, tabs, splits, WSL args |
| `wezterm/workspace-defs.lua` | Project-specific workspace definitions |

## Launch Model

Every pane launches through Windows WezTerm into WSL2. Use Linux paths for
Linux-side repos and `/mnt/c/...` paths for repos checked out on Windows.

```powershell
wsl.exe -d Ubuntu --cd /path/in/wsl
```

When a pane has a `command`, the launcher uses:

```powershell
wsl.exe -d Ubuntu --cd /path/in/wsl --exec bash -lc "<command>; exec ${SHELL:-bash} -l"
```

That lets startup commands finish and leave you in an interactive shell.

## Defining A Workspace

Edit `wezterm/workspace-defs.lua`:

```lua
return {
  default = nil,
  distro = "Ubuntu",

  workspaces = {
    ["my-app"] = {
      label = "my app",
      tabs = {
        {
          title = "app",
          cwd = "/mnt/c/Users/wilbe/src/my-app",
          panes = {
            { title = "server", command = "npm run dev" },
            { title = "shell", split = "right", size = 0.4 },
            { title = "tests", split = "bottom", size = 0.35, command = "npm test" },
          },
        },
        {
          title = "editor",
          cwd = "~/src/my-app",
          command = "nvim",
        },
      },
    },
  },
}
```

Pane fields:

| Field | Meaning |
|-------|---------|
| `title` | Terminal title for that pane |
| `cwd` | WSL working directory; inherits from the tab |
| `command` | Optional startup command |
| `split` | `right`, `bottom`, `left`, or `top`; defaults to `right` |
| `size` | Fraction for the new split; defaults to `0.5` |
| `target` | `main` by default, or `last` for chained splits |
| `distro` | Optional per-pane WSL distro override |

## Opening Workspaces

Default startup opens a normal fresh terminal at `~`. Save and restore are
manual only; nothing restores a project workspace automatically.

Inside WezTerm, press:

```text
Ctrl+Shift+O
```

To start a specific workspace from PowerShell:

```powershell
wezterm start --always-new-process -- dotfiles-windows
```

## Notes

- WezTerm runs as a Windows app, so this config intentionally stays on the
  Windows side and is tracked in this repo.
- Project paths are WSL paths because `wsl.exe --cd` receives them directly.
- Ad hoc session save/restore is a separate layer. If you add
  `resurrect.wezterm` later, bind save and restore to keys and keep automatic
  restore disabled.
