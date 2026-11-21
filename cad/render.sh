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

# Layout v4 study (two 2-axis mirrors, lidar between them): renders and mass, reported but not gating.
render4() { name=$1; view=$2; cam=$3; shift 3
  fit=""; case "$cam" in *,0) fit="--viewall --autocenter" ;; esac
  # shellcheck disable=SC2086
  "$OPENSCAD" -o "$OUT/v4-$name.png" --imgsize=1600,1200 --colorscheme=Tomorrow $fit --camera="$cam" -D "view=\"$view\"" "$@" headlight-v4.scad 2>>"$LOG.v4"
}
render4 three-quarter assembly 0,0,0,62,0,140,0
render4 front         front    0,0,0,90,0,180,0 -D show_beams=false --projection=ortho
render4 turning       assembly 0,0,0,62,0,140,0 -D yaw=7.5
render4 cutaway       cutaway  0,-10,45,90,0,270,520 --projection=ortho
render4 top           assembly 0,0,0,0,0,0,0 -D show_beams=false --projection=ortho
render4 under         under    0,0,0,140,0,150,0 -D show_beams=false
render4 on-wheel      wheel    0,0,0,75,0,125,0 -D show_beams=false
render4 wrap-three-quarter assembly 0,0,0,62,0,140,0 -D wrap_sides=true -D taper=8 -D hs_margin=3 -D r_tail=10 -D show_beams=false
render4 wrap-turning  assembly 0,0,0,62,0,140,0 -D wrap_sides=true -D taper=8 -D hs_margin=3 -D r_tail=10 -D yaw=12.5
render4 wrap-top      assembly 0,0,0,0,0,0,0 -D wrap_sides=true -D taper=8 -D hs_margin=3 -D r_tail=10 -D yaw=12.5 --projection=ortho
if grep -q 'C-PKG' "$LOG.v4"; then echo "v4: $(grep -o 'C-PKG[^"]*' "$LOG.v4" | sort -u | head -3)" >> "$LOG"; else echo "v4: C-PKG checks passed" >> "$LOG"; fi
rm -f "$LOG.v4"
"$OPENSCAD" -o "$OUT/v4.echo" headlight-v4.scad 2>/dev/null
"$OPENSCAD" -o "$OUT/v4-shell.stl" -D 'view="stl_shell"' headlight-v4.scad 2>/dev/null
python3 -I weight.py "$OUT/v4.echo" "$OUT/v4-shell.stl" > "$OUT/mass-v4.txt" || true
grep '"PKG' "$OUT/v4.echo" | sed 's/^ECHO: /v4 /' >> "$LOG"
rm -f "$OUT/v4.echo" "$OUT/v4-shell.stl"
echo "v4 (study): $(tail -1 "$OUT/mass-v4.txt")" >> "$LOG"
# v4 with one clear wraparound piece per side (front + corner + side, no pillar).
"$OPENSCAD" -o "$OUT/v4w.echo" -D wrap_sides=true -D taper=8 -D hs_margin=3 -D r_tail=10 headlight-v4.scad 2>/dev/null
"$OPENSCAD" -o "$OUT/v4w-shell.stl" -D wrap_sides=true -D taper=8 -D hs_margin=3 -D r_tail=10 -D 'view="stl_shell"' headlight-v4.scad 2>/dev/null
python3 -I weight.py "$OUT/v4w.echo" "$OUT/v4w-shell.stl" > "$OUT/mass-v4-wrap.txt" || true
grep '"PKG' "$OUT/v4w.echo" | sed 's/^ECHO: /v4-wrap /' >> "$LOG"
rm -f "$OUT/v4w.echo" "$OUT/v4w-shell.stl"
echo "v4 with clear wraparound sides (study): $(tail -1 "$OUT/mass-v4-wrap.txt")" >> "$LOG"
cat "$LOG"
exit $status
