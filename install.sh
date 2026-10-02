#!/usr/bin/env bash
# Symlink tracked Claude Code config from this repo into ~/.claude.
# Idempotent: safe to re-run. An existing regular file is moved aside to
# <name>.pre-install.bak (if it differs from the repo copy) before linking.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/claude
dest=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
items=(settings.json statusline.sh CLAUDE.md)

mkdir -p "$dest"
for name in "${items[@]}"; do
  src=$repo/$name
  dst=$dest/$name
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "ok      $name"
    continue
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    # A regular file here usually means a tool replaced the symlink on save.
    if [ ! -L "$dst" ] && ! cmp -s "$dst" "$src"; then
      echo "WARN    $name differs from repo copy; saved as $name.pre-install.bak" >&2
      diff -u "$src" "$dst" >&2 || true
    fi
    mv "$dst" "$dst.pre-install.bak"
  fi
  ln -s "$src" "$dst"
  echo "linked  $name"
done
