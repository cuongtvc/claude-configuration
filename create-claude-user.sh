#!/usr/bin/env bash
# Create a sudo user and install Claude Code for them (Debian/Ubuntu).
# Idempotent: safe to re-run. An existing user keeps their account and
# password; they are only added to the sudo group and given Claude Code.
#
# Usage: sudo ./create-claude-user.sh <username>
set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }

[ $# -eq 1 ] || die "usage: $0 <username>"
user=$1
[[ $user =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || die "invalid username: $user"
[ "$(id -u)" -eq 0 ] || die "run as root"

# shellcheck source=/dev/null
. /etc/os-release
case " ${ID:-} ${ID_LIKE:-} " in
  *" debian "* | *" ubuntu "*) ;;
  *) die "unsupported OS: ${PRETTY_NAME:-unknown} (Debian/Ubuntu only)" ;;
esac

missing=()
for cmd in sudo curl; do
  command -v "$cmd" >/dev/null || missing+=("$cmd")
done
if [ ${#missing[@]} -gt 0 ]; then
  echo "install ${missing[*]}"
  apt-get update -q
  DEBIAN_FRONTEND=noninteractive apt-get install -y -q "${missing[@]}"
fi

if id "$user" >/dev/null 2>&1; then
  echo "ok      user $user exists"
else
  useradd -m -s /bin/bash "$user"
  echo "created user $user"
fi

# Also covers a previous run whose password prompt failed: without a password
# the user could never use sudo.
case $(passwd -S "$user" | awk '{print $2}') in
  L | NP)
    echo "set password for $user"
    passwd "$user"
    ;;
esac

usermod -aG sudo "$user"
echo "ok      $user in sudo group"

has_claude() { sudo -iu "$user" claude --version >/dev/null 2>&1; }

if has_claude; then
  echo "ok      claude already installed"
else
  echo "install claude for $user"
  # The native installer puts claude in ~/.local/bin and keeps it updated.
  curl -fsSL https://claude.ai/install.sh | sudo -iu "$user" bash
fi

has_claude || die "claude not found on $user's PATH after install"

echo
echo "done: $user ($(sudo -iu "$user" claude --version))"
echo "next: su - $user, then run claude to log in"
