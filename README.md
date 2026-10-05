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

Add fix-fonts.sh to install a fallback font for Claude Code TUI symbols
  
Claude Code's TUI uses symbols (⏵ ⏸ ⏺ ⎿ ✻) that some macOS setups have
no text font for. Terminal.app then draws them as boxes or misaligned
fallbacks.
  
The script reads the cmap table of each installed font to check which
symbols are covered. Fonts that only cover a symbol as colour emoji
don't count. If anything is missing, it downloads Noto Sans Symbols 2,
checks that the font fills the gap, and installs it into
~/Library/Fonts. Pass --check to only report, without installing.

Not tracked: credentials, history, sessions, caches, and `agents/` (those
link to the `claudecode-opencode` repo).

## ccm

`bin/ccm` (linked into `~/.local/bin` by `install.sh`) asks Claude for a
commit message for the current changes: staged ones if any, otherwise all
changes including untracked files.

```sh
ccm                    # show message, then Commit? [y/N/e]
ccm -p | git commit -F -   # print only
ccm -y "fixes the font fallback"   # commit straight away, with a hint
ccm -m sonnet          # model override (default: $CLAUDE_COMMIT_MODEL or haiku)
ccm -u                 # also print token usage and cost to stderr
```

It runs `claude -p` with no tools, no settings or CLAUDE.md, no MCP servers,
no skills and a short custom system prompt, so the request is little more
than the diff. Lock files and minified files are left out of the diff, and
diffs over 2000 lines (`CCM_MAX_LINES`) are truncated.
Thinking is disabled (`CCM_THINKING=<budget>` turns it back on): on haiku it
took ~10x the output tokens and 5x the time for no better a message.

## create-claude-user.sh

Creates a sudo user and installs Claude Code for them (Debian/Ubuntu, run as
root on the target machine):

```sh
sudo ./create-claude-user.sh alice
```

It installs `sudo` and `curl` if missing, creates the user (prompting for a
password), adds them to the `sudo` group (password sudo), and runs the native
Claude Code installer as that user, so it lands in `~/.local/bin` and
auto-updates. Re-running is safe: an existing user keeps their account and
password, and an existing install is left alone. Log in afterwards with
`su - alice` and `claude`. It does not set up SSH keys or copy this repo's
config.
