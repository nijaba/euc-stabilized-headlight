# Changelog

All notable changes to this project are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- `CLAUDE.md` with the owner's firm constraints: mirror-only steering, external power only, ≤ $450 and ≤ 350 g with the lidar fitted, lidar optional.
- `docs/build-plan.md` with phases 0–8.
- `docs/test-plan.md` with test IDs for automated firmware tests, bench tests, enclosure tests and ride tests.
- Design open questions: power-on flash, BuckBlock zero output, fuse derating in boost, 1N5822 heat, TVS clamp voltage.
- `CONTRIBUTING.md` and `SECURITY.md` (private reporting for safety faults as well as security issues).

### Changed
- design.md §3: beam estimate (beam angles, peak intensity, throw) and a note that the flood has no cutoff; §10 open question; test B-OPT-04.
- design.md §4: power breakdown, input current per mode, lidar draw, and a 15 V 3 A bank recommendation; why wheel USB ports can't power the head, and the wheel 12 V rail and main-battery alternatives.

### Fixed
- BOM: one thermistor instead of two, one fewer 10 k resistor, totals updated.
- Design: the heatsink lid is finned aluminium, not die-cast.
