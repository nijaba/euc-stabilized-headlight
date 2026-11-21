#!/bin/sh
# Render the packaging model to cad/renders/ and run its checks.
# Usage: cad/render.sh   (set OPENSCAD to override the binary path)
set -eu
cd "$(dirname "$0")"
OPENSCAD="${OPENSCAD:-$(command -v openscad || echo /Applications/OpenSCAD-2021.01.app/Contents/MacOS/OpenSCAD)}"
OUT=renders
mkdir -p "$OUT"
LOG="$OUT/checks.txt"
: > "$LOG"

render() { # name view camera [extra args...]; a camera ending in ,0 means "fit to view"
  name=$1; view=$2; cam=$3; shift 3
  fit=""
  case "$cam" in *,0) fit="--viewall --autocenter" ;; esac
  # shellcheck disable=SC2086
  "$OPENSCAD" -o "$OUT/$name.png" --imgsize=1600,1200 --colorscheme=Tomorrow \
    $fit --camera="$cam" -D "view=\"$view\"" "$@" headlight.scad 2>>"$LOG.tmp"
}

render three-quarter assembly 0,0,0,62,0,140,0
render front          front    0,0,0,90,0,180,0  -D show_beams=false --projection=ortho
render under          under    0,0,0,140,0,150,0 -D show_beams=false
render cutaway        cutaway  0,-10,45,90,0,270,520 --projection=ortho
render cutaway-up     cutaway  0,-10,45,90,0,270,520 --projection=ortho  -D tilt=7.5
render cutaway-down   cutaway  0,-10,45,90,0,270,520 --projection=ortho  -D tilt=-7.5
render exploded       exploded 0,0,0,65,0,140,0
render no-lidar       assembly 0,0,0,62,0,140,0  -D lidar_on_head=false
render side           assembly 0,0,0,90,0,90,0   -D show_beams=false --projection=ortho
render top            assembly 0,0,0,0,0,0,0     -D show_beams=false --projection=ortho
render rear-quarter   assembly 0,0,0,65,0,320,0  -D show_beams=false
render on-wheel       wheel    0,0,0,75,0,125,0  -D show_beams=false

# Keep the measurements and any failed check (C-PKG) from the first run.
grep -m2 -E '^ECHO: "(PKG|MASS)' "$LOG.tmp" | sed 's/^ECHO: //' >> "$LOG"
if grep -q 'C-PKG' "$LOG.tmp"; then
  grep 'C-PKG' "$LOG.tmp" | sort -u >> "$LOG"; rm -f "$LOG.tmp"; cat "$LOG"; exit 1
fi
echo "C-PKG-01..13 passed" >> "$LOG"
rm -f "$LOG.tmp"

# Mass budget (C-MASS-01): the printed shell and brow are exported and measured.
status=0
"$OPENSCAD" -o "$OUT/model.echo" headlight.scad 2>/dev/null
"$OPENSCAD" -o "$OUT/shell.stl" -D 'view="stl_shell"' headlight.scad 2>/dev/null
"$OPENSCAD" -o "$OUT/hood.stl"  -D 'view="stl_hood"'  headlight.scad 2>/dev/null
python3 -I weight.py "$OUT/model.echo" "$OUT/shell.stl" "$OUT/hood.stl" > "$OUT/mass.txt" || status=$?
rm -f "$OUT/model.echo" "$OUT/shell.stl" "$OUT/hood.stl"
tail -1 "$OUT/mass.txt" >> "$LOG"
cat "$LOG"
exit $status
