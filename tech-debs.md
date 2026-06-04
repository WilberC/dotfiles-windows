# Tech Debts

This file tracks future workflow improvements that should stay inside this
dotfiles repo so the setup remains pushable and reproducible.

## TD-001: Saved WezTerm Dev Sessions

Add saved WezTerm sessions for terminal-only development workflows. These
sessions should restore named terminal layouts with panes opened in specific
working directories, but should not launch editors, browsers, or other apps.

## TD-002: Config-Driven Terminal Session Definitions

Store terminal session definitions in this repo, under `dotfiles-windows`, as
the only source of truth. Each session should declare its name, shell, pane
layout, and working directories in a small tracked config file.

## TD-003: Shortcut To Open Named Terminal Sessions

Add a future YASB or whkd shortcut for opening a named WezTerm session. The
shortcut should call the session launcher without adding Zed, browser tabs, or
other non-terminal dev automation.

## TD-004: Optional Komorebi Routing For WezTerm Sessions

Optionally route restored WezTerm session windows to the right Komorebi
workspace. This should be added only after terminal session restoration exists,
so routing can be tested against real session window titles or classes.

## References

- WezTerm CLI: https://wezterm.org/cli/cli/index.html
- WezTerm split-pane: https://wezterm.org/cli/cli/split-pane.html
- WezTerm start: https://wezterm.org/cli/start.html
