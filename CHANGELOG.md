# Changelog

All notable changes to this project are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Packaging study (new build-plan phase 1, before firmware): OpenSCAD model in `cad/`, renders, clearance checks C-PKG-01 to 06 (pass) and mass budget C-MASS-01 (fails: ~556 g with lidar against 350 g).
- `CLAUDE.md` with the owner's firm constraints: mirror-only steering, external power only, ≤ $450 and ≤ 350 g with the lidar fitted, lidar optional.
- `docs/build-plan.md` with phases 0–8.
- `docs/test-plan.md` with test IDs for automated firmware tests, bench tests, enclosure tests and ride tests.
- Design open questions: power-on flash, BuckBlock zero output, fuse derating in boost, 1N5822 heat, TVS clamp voltage.
- `CONTRIBUTING.md` and `SECURITY.md` (private reporting for safety faults as well as security issues).

### Changed
- Layout v2 (owner's requirements, 2026-11-21): heatsink at the bottom with fins fore-aft, LEDs facing up, mount on the back (never the top), rounded exterior (8 mm edges), lidar in a top pocket, lighter walls, window and mirror. Mass ~556 → ~463 g with the lidar (~448 g before rounding); configurations compared in design §5. Design §2 adds how cars and motorcycles level their beams.
- Low beam: two LEDiL FILIPPA-STVZO cutoff optics with XP-L HI replace the Nichia 519A + Carclo elliptical flood (owner, 2026-11-21). Larger mirror, heatsink and window; BOM, calibration step D and tests B-OPT-05 to B-OPT-07 updated; B-OPT-01 retired. Weight estimate now over the 350 g limit with lidar (open question).
- design.md §3: beam estimate (beam angles, peak intensity, throw) and a note that the flood has no cutoff; §10 open question; test B-OPT-04.
- design.md §4: power breakdown, input current per mode, lidar draw, and a 15 V 3 A bank recommendation; why wheel USB ports can't power the head, and the wheel 12 V rail and main-battery alternatives.

### Fixed
- BOM: one thermistor instead of two, one fewer 10 k resistor, totals updated.
- Design: the heatsink lid is finned aluminium, not die-cast.
