#!/usr/bin/env python3
"""Mass budget for the headlight head (test C-MASS-01).

Usage: weight.py BASELINE.echo [VARIANT.echo ...]

Each .echo file is OpenSCAD's echo output for one configuration of
headlight.scad (render.sh writes them). The first file is the baseline that
C-MASS-01 judges; the others are shown for comparison. Standard library only.
"""
import re
import sys
from pathlib import Path

LIMIT_G = 350  # firm constraint: head with the optional lidar fitted

ASA, PC, GLASS, ALU, STEEL, COPPER = 1.07, 1.20, 2.50, 2.70, 7.90, 8.90  # g/cm³
CM3 = 1e-3


def read(path):
    text = Path(path).read_text()
    pkg = next(l for l in text.splitlines() if '"PKG ' in l)
    mass = next(l for l in text.splitlines() if '"MASS ' in l)
    name = re.search(r"config=(\S+)", pkg).group(1)
    return name, {k: float(v) for k, v in re.findall(r"(\w+)=([\d.]+)", mass)}


def budget(g):
    n_led = g["n_fil"] + g["n_spot"]
    parts = {
        "Heatsink (aluminium, bottom)": g["hs_mm3"] * CM3 * ALU,
        "Body shell (ASA)": g["shell_area_mm2"] * g["wall_mm"] * CM3 * ASA,
        "Bezel, bosses, ribs (ASA)": 12,
        "Window (polycarbonate)": g["window_mm3"] * CM3 * PC,
        "Mirror (front-surface glass)": g["mirror_mm3"] * CM3 * GLASS,
        "Mirror cradle, shaft, bearings": 5 + 3.14159 * 1.5**2 * g["shaft_mm"] * CM3 * STEEL + 0.6,
        "Optic plate (ASA)": 6,
        "LEDs on 20 mm copper stars": n_led * 3.14159 * 10**2 * 1.6 * CM3 * COPPER,
        "FILIPPA-STVZO optics": g["n_fil"] * 6.3,
        "Carclo 10003 + 10734 holders": g["n_spot"] * 3.5,
        "Servo ES08MD II + linkage": 12 + 2,
        "XIAO, IMU, cable": 3 + 1.5 + 1,
        "BuckBlocks, Pololu 5 V": (2 if g["n_spot"] else 1) * 5 + 3,
        "Protoboard, passives, wiring": 15 + 5,
        "Screws + heat-set inserts": 14,
        "O-rings, window gasket": g["seal_mm"] * 3.14159 * 1.0**2 * CM3 * 1.2 + 2,
        "Mount boss + 1/4\"-20 insert": 10,
        "Gland, vent, button, desiccant": 4 + 2 + 3 + 2,
    }
    if g["lidar"]:
        parts["TF02-Pro lidar"] = 50
        parts["Lidar pocket (ASA) + gasket"] = g["lidar_pod_area_mm2"] * g["wall_mm"] * CM3 * ASA + 2
    return parts


def main(paths):
    configs = [read(p) for p in paths]
    budgets = [budget(g) for _, g in configs]
    names = list(dict.fromkeys(k for b in budgets for k in b))
    head = f"{'Part':34}" + "".join(f"{n:>16}" for n, _ in configs)
    print(head)
    for k in names:
        print(f"{k:34}" + "".join(f"{b.get(k, 0):16.0f}" for b in budgets))
    totals = [sum(b.values()) for b in budgets]
    print(f"{'Total':34}" + "".join(f"{t:16.0f}" for t in totals))
    base_name, base = configs[0]
    ok = totals[0] <= LIMIT_G
    print(f"C-MASS-01 {base_name}: {totals[0]:.0f} g vs {LIMIT_G} g limit: {'PASS' if ok else 'FAIL'}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
