#!/usr/bin/env bash
# Check that some installed font can draw the symbols Claude Code's TUI uses
# (⏵⏵ auto mode, ⏸ plan mode, ⏺ bullets, ⎿ output connector, ✻ spinner).
# Missing ones render as boxes or misaligned fallbacks in Terminal.app.
# If any are missing, download Noto Sans Symbols 2, verify it covers them,
# and install it into ~/Library/Fonts; the terminal picks it up as a fallback.
#
# Usage: ./fix-fonts.sh           check, then install if needed
#        ./fix-fonts.sh --check   check only (exit 1 if anything is missing)
set -euo pipefail

noto_url=https://github.com/notofonts/notofonts.github.io/raw/main/fonts/NotoSansSymbols2/hinted/ttf/NotoSansSymbols2-Regular.ttf
font_dir=$HOME/Library/Fonts
noto=$font_dir/NotoSansSymbols2-Regular.ttf

check_only=false
[ "${1:-}" = --check ] && check_only=true

# Reads each font's cmap table directly, so no fontTools needed.
# Args: font files. Prints one line per glyph; exits 1 if any has no font.
coverage() {
  python3 - "$@" <<'EOF'
import struct, sys

GLYPHS = {0x23F5: '⏵', 0x23F8: '⏸', 0x23FA: '⏺', 0x23BF: '⎿', 0x273B: '✻'}

def faces(d):
    if d[:4] != b'ttcf':
        return [0]
    n = struct.unpack('>I', d[8:12])[0]
    return [struct.unpack('>I', d[12 + 4*i:16 + 4*i])[0] for i in range(n)]

def codepoints(path):
    d = open(path, 'rb').read()
    out = set()
    for off in faces(d):
        cm = None
        for i in range(struct.unpack('>H', d[off+4:off+6])[0]):
            tag, _, o, _ = struct.unpack('>4sIII', d[off+12+16*i:off+28+16*i])
            if tag == b'cmap':
                cm = o
        if cm is None:
            continue
        for i in range(struct.unpack('>H', d[cm+2:cm+4])[0]):
            t = cm + struct.unpack('>I', d[cm+8+8*i:cm+12+8*i])[0]
            fmt = struct.unpack('>H', d[t:t+2])[0]
            if fmt == 4:
                n = struct.unpack('>H', d[t+6:t+8])[0] // 2
                ends = struct.unpack('>%dH' % n, d[t+14:t+14+2*n])
                starts = struct.unpack('>%dH' % n, d[t+16+2*n:t+16+4*n])
                for a, b in zip(starts, ends):
                    out.update(cp for cp in GLYPHS if a <= cp <= b)
            elif fmt == 12:
                for g in range(struct.unpack('>I', d[t+12:t+16])[0]):
                    a, b, _ = struct.unpack('>III', d[t+16+12*g:t+28+12*g])
                    out.update(cp for cp in GLYPHS if a <= cp <= b)
    return out

found = {cp: [] for cp in GLYPHS}
for path in sys.argv[1:]:
    try:
        cps = codepoints(path)
    except Exception:
        continue
    for cp in cps:
        found[cp].append(path.rsplit('/', 1)[-1])

missing = False
for cp, ch in GLYPHS.items():
    # A colour-emoji-only match draws as a wide emoji, not a text glyph.
    text = [f for f in found[cp] if 'Emoji' not in f]
    if text:
        print(f'ok      {ch} U+{cp:04X}  {text[0]}')
    elif found[cp]:
        print(f'emoji   {ch} U+{cp:04X}  only {found[cp][0]}')
        missing = True
    else:
        print(f'MISSING {ch} U+{cp:04X}  no installed font')
        missing = True
sys.exit(1 if missing else 0)
EOF
}

installed_fonts() {
  find /System/Library/Fonts /Library/Fonts "$font_dir" -type f \
    \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.ttc' \) 2>/dev/null
}

fonts=()
while IFS= read -r f; do fonts+=("$f"); done < <(installed_fonts)

if coverage "${fonts[@]}"; then
  echo "All symbols covered; nothing to do."
  exit 0
fi
$check_only && exit 1

if [ -e "$noto" ]; then
  echo "Noto Sans Symbols 2 is already installed but symbols are still missing." >&2
  exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
echo "Downloading Noto Sans Symbols 2..."
curl -fsSL -o "$tmp/NotoSansSymbols2-Regular.ttf" "$noto_url"

# Only install if it fixes the gap: re-check with the download added.
if ! coverage "${fonts[@]}" "$tmp/NotoSansSymbols2-Regular.ttf" >/dev/null; then
  echo "Downloaded font doesn't cover the missing symbols; not installing." >&2
  coverage "${fonts[@]}" "$tmp/NotoSansSymbols2-Regular.ttf" >&2 || true
  exit 1
fi

mkdir -p "$font_dir"
cp "$tmp/NotoSansSymbols2-Regular.ttf" "$noto"
echo "Installed $noto"
echo "Open a new terminal window (or restart the terminal) to see the change."
