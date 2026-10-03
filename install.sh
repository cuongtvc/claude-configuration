#!/usr/bin/env bash
# Symlink tracked Claude Code config from this repo into ~/.claude, and the
# scripts in bin/ into ~/.local/bin.
# Idempotent: safe to re-run. An existing regular file is moved aside to
# <name>.pre-install.bak (if it differs from the repo copy) before linking.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
dest=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
bindest=$HOME/.local/bin
items=(settings.json statusline.sh CLAUDE.md)

link() {
  local src=$1 dst=$2 name
  name=$(basename "$dst")
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "ok      $name"
    return
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
}

mkdir -p "$dest" "$bindest"
for name in "${items[@]}"; do
  link "$root/claude/$name" "$dest/$name"
done
for src in "$root"/bin/*; do
  link "$src" "$bindest/$(basename "$src")"
done
