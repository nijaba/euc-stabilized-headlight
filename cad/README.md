# CAD

`headlight.scad` is a parametric packaging model of the head (build-plan phase 1). Every bought part is a simple solid at its datasheet size and printed parts are plain shells, so it checks fit, mirror sweep and mass. It isn't the printable housing yet.

## Run

Needs [OpenSCAD](https://openscad.org) (2021.01 or newer) and Python 3 (standard library only).

```bash
cad/render.sh
```

It renders the views below to `renders/`, runs the clearance checks (C-PKG-01 to 07) and the mass budget (C-MASS-01, `weight.py`, with lighter configurations for comparison), and writes the results to `renders/checks.txt` and `renders/mass.txt`. The exit status is non-zero if any check fails. Set `OPENSCAD` if the binary isn't on your PATH.

To explore, open `headlight.scad` in OpenSCAD and change `view` (`assembly`, `cutaway`, `exploded`, `front`, `under`, `wheel`), `tilt` (−7.5 to 7.5), `n_fil`, `n_spot`, `lidar_on_head` and `show_beams`.

## Views

| File | Shows |
|---|---|
| `three-quarter.png` | Assembled head with the lidar pocket and the beams |
| `under.png` | From below: the heatsink fins running fore-aft |
| `front.png` | Front, orthographic |
| `cutaway.png`, `cutaway-up.png`, `cutaway-down.png` | Section through the middle at nominal and full mirror tilt |
| `exploded.png` | Heatsink, optics, mirror, electronics, body, window, lidar pod |
| `no-lidar.png` | Assembled head without the lidar |
| `on-wheel.png` | On a generic 16" wheel for scale (not any real model) |

## Results (2026-11-21)

Layout v2 (heatsink at the bottom, fins fore-aft, mount on the back): all clearance checks pass. The current configuration (2 FILIPPA + 2 spot, lidar on the head) is about 448 g against the 350 g limit, so C-MASS-01 fails. `renders/mass.txt` compares lighter configurations; two of them fit. See design.md §5 "Packaging study".
