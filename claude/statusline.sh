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

cfg=${CLAUDE_CONFIG_DIR:-$HOME/.claude}

# Ponytail level, written by its hooks; missing or "off" = hidden
pt=$(head -n1 "$cfg/.ponytail-active" 2>/dev/null | tr -d '[:space:]')
case $pt in
  ''|off) ;;
  full) printf ' \033[38;5;108m[PONYTAIL]\033[0m' ;;
  ultra) printf ' \033[38;5;173m[PONYTAIL:ULTRA]\033[0m' ;;
  *) printf ' \033[38;5;108m[PONYTAIL:%s]\033[0m' "${pt^^}" ;;
esac

# Caveman mode for this session, written by its hooks; missing or "off" = hidden
sid=$(jq -r '.session_id // empty' <<<"$input" | tr -cd 'A-Za-z0-9_-')
f=$cfg/.caveman-sessions/$sid.mode
[ -n "$sid" ] && [ -f "$f" ] || f=$cfg/.caveman-active
cm=$(head -c 64 "$f" 2>/dev/null | tr -cd 'a-z0-9-')
case $cm in
  ''|off) ;;
  caveman) printf ' \033[38;5;137m[CAVEMAN]\033[0m' ;;
  *) printf ' \033[38;5;137m[CAVEMAN:%s]\033[0m' "${cm^^}" ;;
esac
exit 0
