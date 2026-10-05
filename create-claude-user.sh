#!/usr/bin/env bash
# Create a sudo user and install Claude Code for them (Debian/Ubuntu).
# Re-running for an existing user asks whether to delete it (and its home)
# and start fresh; otherwise the account and password are kept, and the user
# is only added to the sudo group and given Claude Code.
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
command -v sudo >/dev/null || missing+=(sudo)
command -v curl >/dev/null || missing+=(curl)
command -v pkill >/dev/null || missing+=(procps)
if [ ${#missing[@]} -gt 0 ]; then
  echo "install ${missing[*]}"
  apt-get update -q
  DEBIAN_FRONTEND=noninteractive apt-get install -y -q "${missing[@]}"
fi

if id "$user" >/dev/null 2>&1; then
  # No terminal (e.g. ssh host 'bash -s' < script) counts as "no".
  { : </dev/tty; } 2>/dev/null &&
    read -r -p "user $user exists; delete it and its home, then recreate? [y/N] " ans </dev/tty || ans=
  if [[ $ans == [yY] ]]; then
    uid=$(id -u "$user")
    [ "$uid" -ge 1000 ] || die "refusing to delete system user $user (uid $uid)"
    [ "$user" != "${SUDO_USER:-}" ] || die "refusing to delete the user running this script"
    pkill -KILL -u "$user" || true  # userdel would leave them running
    userdel -r "$user"
    echo "deleted user $user"
  fi
fi

if id "$user" >/dev/null 2>&1; then
  echo "ok      user $user exists"
else
  useradd -m -s /bin/bash "$user"
  echo "created user $user"
fi

# Also covers a previous run whose password prompt failed: without a password
# the user could never use sudo.
passwd -S "$user" | grep -q "^$user P " || { echo "set password for $user"; passwd "$user"; }

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

v=$(sudo -iu "$user" claude --version) || die "claude not found on $user's PATH after install"

echo
echo "done: $user ($v)"
echo "next: su - $user, then run claude to log in"
