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
python3 -I weight.py "$OUT/model.echo" "$OUT/shell.stl" "$OUT/hood.stl" > "$OUT/mass.txt" || true   # v3: earlier layout, reported only
rm -f "$OUT/model.echo" "$OUT/shell.stl" "$OUT/hood.stl"
tail -1 "$OUT/mass.txt" >> "$LOG"

# Layout v4, adopted 2026-11-21 (two 2-axis mirrors side by side, TFS20-L lidar in a roof pod since 2026-11-21). Its C-PKG checks and mass gate the exit status. Only the clear-wraparound version is modelled now (owner, 2026-11-21).
render4() { name=$1; view=$2; cam=$3; shift 3
  fit=""; case "$cam" in *,0) fit="--viewall --autocenter" ;; esac
  # shellcheck disable=SC2086
  "$OPENSCAD" -o "$OUT/v4-$name.png" --imgsize=1600,1200 --colorscheme=Tomorrow $fit --camera="$cam" -D "view=\"$view\"" "$@" headlight-v4.scad 2>>"$LOG.v4"
}
render4 three-quarter assembly 0,0,0,62,0,140,0 -D show_beams=false
render4 front         front    0,0,0,90,0,180,0 -D show_beams=false --projection=ortho
render4 turning       assembly 0,0,0,62,0,140,0 -D yaw_l=12.5 -D yaw_r=0
render4 cutaway       cutaway  0,-10,45,90,0,270,520 --projection=ortho
render4 top           assembly 0,0,0,0,0,0,0 -D yaw_l=12.5 -D yaw_r=0 --projection=ortho
render4 under         under    0,0,0,140,0,150,0 -D show_beams=false
render4 on-wheel      wheel    0,0,0,75,0,125,0 -D show_beams=false
render4 exploded      exploded 0,0,0,65,0,145,0 -D show_beams=false
if grep -q 'C-PKG' "$LOG.v4"; then status=1; echo "v4: $(grep -o 'C-PKG[^"]*' "$LOG.v4" | sort -u | head -3)" >> "$LOG"; else echo "v4: C-PKG checks passed" >> "$LOG"; fi
rm -f "$LOG.v4"
# C-PKG-18: nothing inside pokes into the wall (inner skin; the lidar against its pod), with the mirrors at every corner of their travel.
fit_fail=""
fit_check() { "$OPENSCAD" -o "$OUT/fit.stl" -D 'view="none"' "$@" fit-v4.scad 2>&1 | grep -q "top level object is empty"; }
fit_check -D 'part="fixed"' || fit_fail="$fit_fail fixed-parts"
for tp in "7.5 12.5" "-7.5 12.5" "7.5 -2.5" "-7.5 -2.5"; do   # yaw: full outward, full inward trim
  # shellcheck disable=SC2086
  set -- $tp
  fit_check -D 'part="mirrors"' -D "tilt=$1" -D "yaw=$2" || fit_fail="$fit_fail mirrors(tilt=$1,yaw=$2)"
done
rm -f "$OUT/fit.stl"
if [ -n "$fit_fail" ]; then status=1; echo "C-PKG-18 v4: parts poke through the skin:$fit_fail" >> "$LOG"; else echo "C-PKG-18 v4: nothing pokes through the skin at any mirror pose" >> "$LOG"; fi
"$OPENSCAD" -o "$OUT/v4.echo" headlight-v4.scad 2>/dev/null
"$OPENSCAD" -o "$OUT/v4-shell.stl" -D 'view="stl_shell"' headlight-v4.scad 2>/dev/null
python3 -I weight.py "$OUT/v4.echo" "$OUT/v4-shell.stl" > "$OUT/mass-v4.txt" || status=$?
grep '"PKG' "$OUT/v4.echo" | sed 's/^ECHO: /v4 /' >> "$LOG"
rm -f "$OUT/v4.echo" "$OUT/v4-shell.stl"
echo "v4 (adopted, clear wraparound sides): $(tail -1 "$OUT/mass-v4.txt")" >> "$LOG"
# The project site (GitHub Pages, docs/) shows these renders; keep its copies current.
for f in three-quarter turning top cutaway under on-wheel front exploded; do cp "$OUT/v4-$f.png" ../docs/img/; done
cat "$LOG"
exit $status
