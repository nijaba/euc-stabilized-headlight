#!/usr/bin/env python3
"""Mass budget for the headlight head (test C-MASS-01).

Reads the geometry that headlight.scad prints (renders/checks.txt, written by
render.sh) and adds bought-part masses. Prints two columns: the design as
modelled, and a "lean" variant with the weight savings listed in design §10.
Standard library only.
"""
import re
import sys
from pathlib import Path

LIMIT_G = 350  # firm constraint: head with the optional lidar fitted

ASA, PC, GLASS, ALU, STEEL, COPPER = 1.07, 1.20, 2.50, 2.70, 7.90, 8.90  # g/cm³


def geometry():
    text = (Path(__file__).parent / "renders" / "checks.txt").read_text()
    line = next(l for l in text.splitlines() if "MASS " in l)
    return {k: float(v) for k, v in re.findall(r"(\w+)=([\d.]+)", line)}


def budget(g, lean):
    wall = 1.6 if lean else 2.4                     # mm: 4 vs 5 perimeters
    win_t = 2.0 if lean else 2.5
    mirror_scale = 1.1 / 1.9 if lean else 1.0       # 1.1 mm vs 1.9 mm glass
    hs_scale = 0.6 if lean else 1.0                 # thinner base, fewer fins
    cm3 = 1e-3
    parts = {
        # printed and machined, from the model's geometry
        "Heatsink lid (aluminium)": (g["hs_base_mm3"] + g["hs_fins_mm3"]) * cm3 * ALU * hs_scale,
        "Body shell (ASA)": g["shell_area_mm2"] * wall * cm3 * ASA,
        "Bezel, bosses, ribs (ASA)": 15 if not lean else 11,
        "Window (polycarbonate)": g["window_area_mm2"] * win_t * cm3 * PC,
        "Mirror (front-surface glass)": g["mirror_mm3"] * cm3 * GLASS * mirror_scale,
        "Mirror cradle, shaft, bearings": 6 + 6.9 + 0.6,
        "Optic plate (ASA)": 8,
        # bought parts, datasheet or typical values
        "4x LED on 20 mm copper star": 4 * 3.14159 * 10**2 * 1.6 * cm3 * COPPER,
        "2x FILIPPA-STVZO": 2 * 6.3,
        "2x Carclo 10003 + 10734 holder": 2 * 3.5,
        "Servo ES08MD II + linkage": 12 + 2,
        "XIAO, IMU, cable": 3 + 1.5 + 1,
        "2x BuckBlock, Pololu 5 V": 2 * 5 + 3,
        "Protoboard, passives, wiring": 15 + 5,
        "Lid screws + heat-set inserts": 17,
        "O-ring, window gasket": 3.5,
        "Mount boss + 1/4\"-20 insert": 10,
        "Gland, vent, button, desiccant": 4 + 2 + 10 + 2,
    }
    lidar = {
        "TF02-Pro lidar": 50,
        "Lidar pod (ASA) + gasket": 15 if lean else 40,  # lean: in the body, not a separate pod
    }
    return parts, lidar


def main():
    g = geometry()
    cols = [budget(g, lean=False), budget(g, lean=True)]
    print(f"{'Part':38} {'Model':>7} {'Lean':>7}")
    for name in cols[0][0]:
        print(f"{name:38} {cols[0][0][name]:7.0f} {cols[1][0][name]:7.0f}")
    heads = [sum(p.values()) for p, _ in cols]
    print(f"{'Head without lidar':38} {heads[0]:7.0f} {heads[1]:7.0f}")
    for name in cols[0][1]:
        print(f"{name:38} {cols[0][1][name]:7.0f} {cols[1][1][name]:7.0f}")
    totals = [h + sum(l.values()) for h, (_, l) in zip(heads, cols)]
    print(f"{'Head with lidar':38} {totals[0]:7.0f} {totals[1]:7.0f}")
    ok = totals[0] <= LIMIT_G
    print(f"C-MASS-01 head with lidar {totals[0]:.0f} g vs {LIMIT_G} g limit: {'PASS' if ok else 'FAIL'}"
          f" (lean variant {totals[1]:.0f} g)")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
