# CAD

`headlight.scad` is a parametric packaging model of the head (build-plan phase 1). Every bought part is a simple solid at its datasheet size and printed parts are plain shells, so it checks fit, mirror sweep and mass. It isn't the printable housing yet.

## Run

Needs [OpenSCAD](https://openscad.org) (2021.01 or newer) and Python 3 (standard library only).

```bash
cad/render.sh
```

It renders the views below to `renders/`, runs the clearance checks (C-PKG-01 to 13) and the mass budget (C-MASS-01, `weight.py`, which measures the printed shell and brow from exported STL volumes), and writes the results to `renders/checks.txt` and `renders/mass.txt`. The exit status is non-zero if any check fails. Set `OPENSCAD` if the binary isn't on your PATH.

To explore, open `headlight.scad` in OpenSCAD and change `view` (`assembly`, `cutaway`, `exploded`, `front`, `under`, `wheel`), `tilt` (−7.5 to 7.5), `n_fil`, `n_spot`, `lidar_on_head`, `show_beams`, and the shape parameters `taper`, `roof_drop`, `r_tail` and `hood_tail`.

## Views

| File | Shows |
|---|---|
| `three-quarter.png` | Assembled head with the lidar pocket and the beams |
| `under.png` | From below: the heatsink fins running fore-aft |
| `front.png` | Front, orthographic |
| `cutaway.png`, `cutaway-up.png`, `cutaway-down.png` | Section through the middle at nominal and full mirror tilt |
| `exploded.png` | Heatsink, optics, mirror, electronics, body, window, lidar pod |
| `no-lidar.png` | Assembled head without the lidar |
| `side.png`, `top.png` | Side and top profiles, orthographic: the tapered, sloping v3 shape |
| `rear-quarter.png` | From behind: tail, mount boss, gland and vent |
| `on-wheel.png` | On a generic 16" wheel for scale (not any real model) |

## Layout v4 study

`headlight-v4.scad` models the alternative with two independent 2-axis mirror modules and the lidar on its side between them, with no cornering lights or brow. `render.sh` renders it as `renders/v4-*.png` and writes its mass to `renders/mass-v4.txt`; its results are reported but don't affect the exit status. Extra variables: `yaw` (−7.5 to 7.5) and `yaw_max`.

## Results (2026-11-21)

Layout v3 (aerodynamic, lean): heatsink at the bottom with fins fore-aft, mount on the back, a tapered body with a sloping roof and a brow fairing for the lidar and cornering lights. All clearance checks pass. The head is about 401 g with the lidar against the 400 g limit; see `renders/mass.txt` and design.md §5 "Packaging study".
