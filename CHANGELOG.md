# Changelog

All notable changes to this project are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- `CLAUDE.md` with the owner's firm constraints: mirror-only steering, external power only, ≤ $450 and ≤ 350 g with the lidar fitted, lidar optional.
- `docs/build-plan.md` with phases 0–8.
- `docs/test-plan.md` with test IDs for automated firmware tests, bench tests, enclosure tests and ride tests.
- Design open questions: power-on flash, BuckBlock zero output, fuse derating in boost, 1N5822 heat, TVS clamp voltage.

### Fixed
- BOM: one thermistor instead of two, one fewer 10 k resistor, totals updated.
- Design: the heatsink lid is finned aluminium, not die-cast.
