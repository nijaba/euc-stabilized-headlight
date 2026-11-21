# Changelog

All notable changes to this project are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- v4 ride demo page (`docs/v4-ride-demo.html`), linked from the README: a standalone simulation of the levelling loop and turn steering.
- v4 turning behaviour decided: only the turn-side beam swings into the curve, the other stays straight (design §5).
- Beam response requirement (owner, 2026-11-21): ±10° of pitch, beam adapts in under 1 s. Tests U-ROAD-03..06, R-ROAD-01..02.
- Calibration and settings control decided (firmware-spec §11): a page over the head's own Wi-Fi, with the button and remote as a full fallback; no phone app. Tests U-CFG-01..04, B-CFG-01.
- Bench kit (BOM) to order before firmware, and why it comes before any PCB (build plan phase 2).
- v4 clear wraparound sides (study): one thermoformed piece per side across the front, corner and side, no pillar; outward beam swing ±25°; ~200 mm wide, ~393 g (design §5, C-PKG-17, B-OPT-10, E-SEAL-05).
- Waterproofing and vibration review for v3 and v4 (design §5): seal inventory, IP65 target, vibration measures; tests B-MIR-05, B-VIB-01, E-SEAL-04, E-VIB-01.
- Layout v4 study (`cad/headlight-v4.scad`): two 2-axis mirror modules steering ±15° into turns, the lidar on its side between them, no cornering lights or brow; ~221 × 70 × 108 mm, ~410 g (C-PKG-14 to 16). v3 remains the design pending the owner's choice.
- `docs/options-study.md`: comparison chart of a convex low-beam mirror, crossing beams, two 2-axis mirrors, a masked mirror and an LCD mask (2026-11-21); bench test B-OPT-09 for the convex mirror.
- Cornering lights and toe-out (owner, 2026-11-21): two IMU-switched XP-L HI + Carclo elliptical lights in a rounded top brow, aimed 30° out and 10° down (firmware-spec §10, safety invariant 6, U-CRN, B-CRN, R-CRN); FILIPPA optics toed out 4° on aluminium wedges for a ~30° low beam (B-OPT-08). BOM +$33; mass ~517 g with lidar.
- Packaging study (new build-plan phase 1, before firmware): OpenSCAD model in `cad/`, renders, clearance checks C-PKG-01 to 06 (pass) and mass budget C-MASS-01 (fails: ~556 g with lidar against 350 g).
- `CLAUDE.md` with the owner's firm constraints: mirror-only steering, external power only, ≤ $450 and ≤ 350 g with the lidar fitted, lidar optional.
- `docs/build-plan.md` with phases 0–8.
- `docs/test-plan.md` with test IDs for automated firmware tests, bench tests, enclosure tests and ride tests.
- Design open questions: power-on flash, BuckBlock zero output, fuse derating in boost, 1N5822 heat, TVS clamp voltage.
- `CONTRIBUTING.md` and `SECURITY.md` (private reporting for safety faults as well as security issues).

### Changed
- Layout v4 adopted (owner, 2026-11-21): two mirrors on 2-axis gimbals, four servos, clear wraparound sides, lidar in the body, no cornering lights. Design, firmware spec, build plan, CLAUDE.md, BOM (≈ $440 per unit with the lidar, ~393 g) and README updated; `render.sh` now gates on v4.
- Hill follower (firmware-spec §2, adopted 2026-11-21): removes the pitch the measured acceleration explains, then follows with τ = 0.3 s instead of 4 s, freezing 0.3 s after hard acceleration or a jolt. Fixes the beam dropping while accelerating and lagging over crests. U-ROAD-01 and R-AIM-02 now require 1 s.
- Weight limit raised from 350 g to 400 g with the lidar (owner, 2026-11-21). Layout v3: aerodynamic shape (tapered, sloping roof, soft tail, brow fairing) and lean package (1.6 mm walls, smaller heatsink, 1.5 mm window, 5 g servo, fewer screws, M8 gland); printed parts now measured from STL volumes; ~401 g. Design §2 explains the mirror's size.
- Layout v2 (owner's requirements, 2026-11-21): heatsink at the bottom with fins fore-aft, LEDs facing up, mount on the back (never the top), rounded exterior (8 mm edges), lidar in a top pocket, lighter walls, window and mirror. Mass ~556 → ~463 g with the lidar (~448 g before rounding); configurations compared in design §5. Design §2 adds how cars and motorcycles level their beams.
- Low beam: two LEDiL FILIPPA-STVZO cutoff optics with XP-L HI replace the Nichia 519A + Carclo elliptical flood (owner, 2026-11-21). Larger mirror, heatsink and window; BOM, calibration step D and tests B-OPT-05 to B-OPT-07 updated; B-OPT-01 retired. Weight estimate now over the 350 g limit with lidar (open question).
- design.md §3: beam estimate (beam angles, peak intensity, throw) and a note that the flood has no cutoff; §10 open question; test B-OPT-04.
- design.md §4: power breakdown, input current per mode, lidar draw, and a 15 V 3 A bank recommendation; why wheel USB ports can't power the head, and the wheel 12 V rail and main-battery alternatives.

### Fixed
- BOM: one thermistor instead of two, one fewer 10 k resistor, totals updated.
- Design: the heatsink lid is finned aluminium, not die-cast.
