#!/usr/bin/env bash
# Claude Code status line: user@host:cwd (branch) ctx:USEDk/SIZEk

input=$(cat)

cwd=$(jq -r '.workspace.current_dir' <<<"$input")
# Show $HOME as ~ (display only; git below still needs the real path)
dir=$cwd
case $dir in "$HOME"|"$HOME"/*) dir="~${dir#"$HOME"}" ;; esac
printf '\033[01;32m%s@%s:\033[01;34m%s\033[00m' "$(whoami)" "$(hostname -s)" "$dir"

# Git branch, or short hash when detached
br=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
[ -z "$br" ] && br=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
[ -n "$br" ] && printf ' \033[33m(%s)\033[00m' "$br"

# Tokens currently in context, and the window size
tok=$(jq -r '.context_window.current_usage | if . then (.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens) else empty end' <<<"$input")
win=$(jq -r '.context_window.context_window_size // empty' <<<"$input")
if [ -n "$tok" ]; then
  printf ' ctx:%dk' $(( (tok + 500) / 1000 ))
  [ -n "$win" ] && printf '/%dk' $(( win / 1000 ))
fi
exit 0
