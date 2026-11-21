#!/usr/bin/env python3
"""Mass budget for the headlight head (test C-MASS-01).

Usage: weight.py MODEL.echo SHELL.stl [HOOD.stl]

MODEL.echo is OpenSCAD's echo output for headlight.scad; SHELL.stl and
HOOD.stl are the printed body shell and brow fairing exported from it
(render.sh writes all three). The printed parts' mass comes from the STL
volumes, so the shaped body is measured, not approximated. Standard library only.
"""
import re
import sys
from pathlib import Path

LIMIT_G = 400  # firm constraint: head with the optional lidar fitted (raised from 350 g, 2026-11-21)

ASA, PC, GLASS, ALU, STEEL, COPPER = 1.07, 1.20, 2.50, 2.70, 7.90, 8.90  # g/cm³
CM3 = 1e-3


def read_echo(path):
    text = Path(path).read_text()
    pkg = next(l for l in text.splitlines() if '"PKG ' in l)
    mass = next(l for l in text.splitlines() if '"MASS ' in l)
    name = re.search(r"config=(\S+)", pkg).group(1)
    return name, {k: float(v) for k, v in re.findall(r"(\w+)=([\d.]+)", mass)}


def stl_volume_mm3(path):
    """Volume of a closed ASCII STL mesh (OpenSCAD's default export), by signed tetrahedra."""
    verts = [tuple(map(float, l.split()[1:4])) for l in Path(path).read_text().splitlines()
             if l.strip().startswith("vertex")]
    vol = 0.0
    for i in range(0, len(verts) - 2, 3):
        (ax, ay, az), (bx, by, bz), (cx, cy, cz) = verts[i:i + 3]
        vol += ax * (by * cz - bz * cy) - ay * (bx * cz - bz * cx) + az * (bx * cy - by * cx)
    return abs(vol) / 6.0


def budget(g, shell_mm3, hood_mm3):
    n_led = g["n_fil"] + g["n_spot"]
    n_servo = g.get("n_servo", 1)            # v4 has four (pitch + yaw per mirror)
    n_frames = g.get("n_frames", 0)          # v4 gimbal frames
    cornering = g.get("cornering", 1)        # v3 has cornering lights; v4 replaces them with yaw steering
    toe = g.get("toe", 1)
    parts = {
        "Heatsink (aluminium, bottom)": g["hs_mm3"] * CM3 * ALU,
        "Body shell (ASA, measured)": shell_mm3 * CM3 * ASA,
        "Brow fairing (ASA, measured)": hood_mm3 * CM3 * ASA,
        "Bezel, bosses, ribs (ASA)": g.get("ribs_g", 10),
        "Window (polycarbonate)": g["window_mm3"] * CM3 * PC,
        "Mirror (front-surface glass)": g["mirror_mm3"] * CM3 * GLASS,
        "Mirror cradle, shaft, bearings": 5 + 3.14159 * 1.5**2 * g["shaft_mm"] * CM3 * STEEL + 0.6,
        "Gimbal frames, yaw pins, bearings": n_frames * (6 + 1.2),
        "Optic plate (ASA)": 6,
        "LEDs on 20 mm copper stars": n_led * 3.14159 * 10**2 * 1.6 * CM3 * COPPER,
        "FILIPPA-STVZO optics": g["n_fil"] * 6.3,
        "Carclo 10003 + 10734 holders": g["n_spot"] * 3.5,
        "FILIPPA toe-out wedges (aluminium)": toe * g["n_fil"] * 2,
        "Servos (5 g class) + linkages": n_servo * (5 + 2),
        "XIAO, IMU, cable": 3 + 1.5 + 1,
        "BuckBlocks, Pololu 5 V": (2 if g["n_spot"] else 1) * 5 + 3,
        "Protoboard, passives, wiring": 15 + 5,
        "Screws + heat-set inserts": 9,
        "O-rings, window gasket": g["seal_mm"] * 3.14159 * 1.0**2 * CM3 * 1.2 + 2,
        "Mount boss + 1/4\"-20 insert": 10,
        "Gland (M8), vent, button, desiccant": 2 + 2 + 3 + 2,
        "2x cornering light (LED, optic, plate, window)": cornering * 2 * (4.5 + 3.5 + 3 + 1.5),
        "2x cornering driver (700 mA buck)": cornering * 2 * 2,
    }
    if g["lidar"]:
        parts["TF02-Pro lidar"] = 50
        parts["Lidar gasket + screws"] = 2
    return parts


def main(echo, shell, hood=None):
    name, g = read_echo(echo)
    parts = budget(g, stl_volume_mm3(shell), stl_volume_mm3(hood) if hood else 0.0)
    print(f"{'Part':48}{name:>14}")
    for k, v in parts.items():
        print(f"{k:48}{v:14.0f}")
    total = sum(parts.values())
    print(f"{'Total':48}{total:14.0f}")
    ok = total <= LIMIT_G
    print(f"C-MASS-01 {name}: {total:.0f} g vs {LIMIT_G} g limit: {'PASS' if ok else 'FAIL'}")
    return 0 if ok else 1


if __name__ == "__main__":
    if len(sys.argv) not in (3, 4):
        sys.exit(__doc__)
    sys.exit(main(*sys.argv[1:]))
