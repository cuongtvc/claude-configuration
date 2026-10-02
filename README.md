# claude-configuration

My Claude Code config (`~/.claude`), version-controlled.

`claude/` mirrors the files tracked from `~/.claude`:

- `settings.json`: user settings
- `statusline.sh`: status line (`user@host:cwd (branch) ctx:USEDk/SIZEk`)
- `CLAUDE.md`: global instructions

## Install

```sh
./install.sh
```

This symlinks each file into `~/.claude`. Re-run it any time: if Claude Code
ever replaces a symlink with a regular file when saving, the script warns,
shows the diff, and moves that file aside before relinking.

Not tracked: credentials, history, sessions, caches, and `agents/` (those
link to the `claudecode-opencode` repo).
