-- Project workspace definitions for Windows WezTerm + WSL2.
--
-- CWD values are WSL paths. Windows-side repos use /mnt/c/... paths.
-- Every pane launches through:
--   wsl.exe -d <distro> --cd <cwd>
--
-- Use `command` for one-time startup commands. The command is run through
-- bash -lc and then drops back into an interactive shell when it exits.

local dotfiles_windows = "/mnt/c/Users/wilbe/dotfiles-windows"

return {
  -- Keep startup as a normal fresh terminal. Open named workspaces manually
  -- with Ctrl+Shift+O or `wezterm start -- <name>`.
  default = nil,
  distro = "Ubuntu",

  workspaces = {
    ["dotfiles-windows"] = {
      label = "dotfiles-windows",
      tabs = {
        {
          title = "dotfiles",
          cwd = dotfiles_windows,
          panes = {
            {
              title = "shell",
            },
            {
              title = "git",
              split = "right",
              size = 0.38,
              command = "git status --short",
            },
          },
        },
        {
          title = "editor",
          cwd = dotfiles_windows,
          command = "if command -v nvim >/dev/null 2>&1; then nvim; elif command -v vim >/dev/null 2>&1; then vim; elif command -v nano >/dev/null 2>&1; then nano README.md; else printf 'No editor found. Install nvim, vim, or nano.\\n'; fi",
        },
      },
    },

    example = {
      label = "example project",
      tabs = {
        {
          title = "app",
          cwd = "~/src/example",
          panes = {
            {
              title = "server",
              command = "npm run dev",
            },
            {
              title = "shell",
              split = "right",
              size = 0.4,
            },
            {
              title = "tests",
              split = "bottom",
              size = 0.35,
              command = "npm test",
            },
          },
        },
        {
          title = "notes",
          cwd = "~/src/example",
          command = "nvim README.md",
        },
      },
    },
  },
}
