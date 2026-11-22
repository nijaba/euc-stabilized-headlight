# Changelog

All notable changes to this project are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Firmware README: how to fix the board build when pioarduino's own PlatformIO fork (6.2.0.post1) makes the platform refuse to install.
- BOM bench kit: a list of five bench tools the phase 2–3 tests need (bench power supply, multimeter, thermometer, USB-C data cable, soldering iron; ~$153, skip what you own), kept out of the kit total. Site's phase 2 bench-kit figure corrected from ~$263 to ~$339.
- Board build (owner's platform decision, 2026-11-22): `pio run -e xiao_esp32s3` builds with Arduino-ESP32 3.3.12 through the community pioarduino platform, pinned to release 55.03.312-1 with its digest noted; needs PlatformIO Core 6.2. A minimal `src/main.cpp` prints a boot line. Design §7/§10, firmware-spec, build plan and CLAUDE.md updated. Not yet flashed to a board.
- Firmware phase 2 start: PlatformIO project in `firmware/` with host tests (`pio test -e native`). Pure modules for the gated pitch filter, the hill follower and the mirror/servo command (firmware-spec §2), with tests U-FILT-01..04, U-ROAD-01..06, U-MIR-01..03 and the test-plan ID check U-PLAN-01 (now: tests must be in the plan, and rows marked as passing must have tests). Each test was checked to fail with its logic broken. Open question added: Arduino-ESP32 3.x needs the community pioarduino platform.
- Build plan: phase 5 gains the owner decision on the turn-swing cap and the outside beam as a gate before the v4 turn rule is written and coded (U-TURN-01); v3-only items (cornering lights, toe-out wedges, convex mirror) leave phases 4 and 5; B-OPT-08 now measures v4's cutoff roll; current phase set to 2.
- Cutoff roll in turns (design §5, 2026-11-22): swinging a beam also rolls its cutoff by the swing angle, so the planned 20 m look-ahead over-tilts the turn-side cutoff in slow, tight turns (up to 20° the wrong way). Proposed cap at the lean + 3°; the outside beam's full-lean tilt is left open. The v4 ride demo gains a slow corner and optional Cutoff roll and Cap swing views; firmware-spec §10/§12 notes and planned test U-TURN-01.
- Owner's render review (2026-11-21): v4 body narrowed from 200 to ~151 mm (target 150). The Benewake TFS20-L lidar (1.35 g, 3.3 V) replaces the TF02-Pro in a small roof pod, the modules sit side by side around a centre post, one clear piece wraps the whole front, inward yaw is cut to a 2.5° aim trim, and an exploded render is added. Head ~341 g (was ~399 g), material cost ~$401 with the lidar (was ~$440). C-PKG-18 now checks against the inner skin, which found and fixed a mirror end touching the front wall; body taper 4 mm, clear-corner radius 12 mm, front clearance 5 mm. BOM, bench kit (two BuckBlocks, a TFS20-L), design §5/§9, firmware-spec §8 and tests C-PKG-14..16/18, B-LID-02, B-THM-03 updated. Mirror-damping options recorded as an open question.
- Lidar moved under the beams (owner, 2026-11-21): the TFS20-L now sits inside the nose, on the floor between the modules and below the clear piece, behind its own window over a shallow rounded chin, instead of in a roof pod. Head height back to ~112 mm with the fins (128 mm at the pod), head ~331 g. New check C-PKG-19; B-THM-03 now measures the lidar inside the head.
- Proposal: high beam widened at low speed by swinging the two spots apart (up to 5° each, narrowing by 40 km/h), firmware-spec §12; speed estimated from the IMU (owner's decision), with resets when still and corrections in turns. Ride demo shows it.
- Site and README say the project is a concept design and invite ideas as GitHub issues rather than builds.
- GitHub Pages serves `docs/`, so the README's demo link opens the live page (`docs/.nojekyll` serves the files as they are).
- Project site home page (`docs/index.html`): the problem, how it works, the embedded ride demo, renders, anticipated spec, limits, parts, safety rules, roadmap and links. Its renders live in `docs/img/`, refreshed by `cad/render.sh`.
- Ride demo: low-beam and high-beam modes (the high beam adds the two spots), and the lidar fitted by default.
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
- Spot optics (2026-11-22): the Carclo 10003 is bought from Mouser ($2.46, in stock), alongside the FILIPPA optics. Section C $153.56, cash outlay ~$535, bench kit $345.03; per-unit cost still ~$403 with the lidar.
- Bench mirror (2026-11-22): the test piece is a 1 mm glass front-surface mirror, a 6″ × 6″ sample from opticalmirror.com ($9.95), because 1.1 mm is hard to find in the US; section C notes the US 1.0 mm sources for the build. 2N3904 row says single TO-92 parts, buy ~10. Bench kit $345.32.
- LED drivers (2026-11-22): the BuckBlock A009-D-V-2100 is now bought from LEDSupply ($21.77, in stock) because DigiKey quoted an 8-week lead time. Material ~$403 with the lidar (limit $450), cash outlay ~$536, bench kit $347.37.
- Bench kit laser (2026-11-22): spec clarified as a wired brass-barrel module with adjustable focus, ≤ 5 mW, so it can be aimed at the mirror apart from the breadboard. No price change.
- PD trigger (2026-11-22): the Pimoroni 15 V trigger cable (~$49 shipped to the US) is replaced by the Adafruit HUSB238 trigger board (#5807, $5.95) jumpered to 15 V, plus a short 3 A USB-C cable; it rides in the pouch in heat-shrink. Design §4 drops the e-marked requirement (the head draws 2 A at most). Per-unit cost unchanged (~$402 with the lidar); bench kit $345.83.
- Protoboard (2026-11-22): the half-size Adafruit Perma-Proto #1609 is out of stock, so the BOM uses the full-size #1606 ($10.95), cut in half (one half for the head, one spare). Cash outlay ~$534 (was ~$528), material per unit ~$402 with the lidar (was ~$401), bench kit ~$346 (was ~$339).
- v4 ride demo: the “Old hill follower (4 s)” comparison is removed; the demo runs only the adopted hill follower (firmware-spec §2).
- v4 model: the curved clear sides are now the only version (flat front dropped, owner 2026-11-21) and the default; `render.sh` renders only it. Per-side yaw (`yaw_l`, `yaw_r`) so the turn renders show only the turn-side beam swinging. Site headline mentions turns.
- Layout v4 adopted (owner, 2026-11-21): two mirrors on 2-axis gimbals, four servos, clear wraparound sides, lidar in the body, no cornering lights. Design, firmware spec, build plan, CLAUDE.md, BOM (≈ $440 per unit with the lidar, ~393 g) and README updated; `render.sh` now gates on v4.
- Hill follower (firmware-spec §2, adopted 2026-11-21): removes the pitch the measured acceleration explains, then follows with τ = 0.3 s instead of 4 s, freezing 0.3 s after hard acceleration or a jolt. Fixes the beam dropping while accelerating and lagging over crests. U-ROAD-01 and R-AIM-02 now require 1 s.
- Weight limit raised from 350 g to 400 g with the lidar (owner, 2026-11-21). Layout v3: aerodynamic shape (tapered, sloping roof, soft tail, brow fairing) and lean package (1.6 mm walls, smaller heatsink, 1.5 mm window, 5 g servo, fewer screws, M8 gland); printed parts now measured from STL volumes; ~401 g. Design §2 explains the mirror's size.
- Layout v2 (owner's requirements, 2026-11-21): heatsink at the bottom with fins fore-aft, LEDs facing up, mount on the back (never the top), rounded exterior (8 mm edges), lidar in a top pocket, lighter walls, window and mirror. Mass ~556 → ~463 g with the lidar (~448 g before rounding); configurations compared in design §5. Design §2 adds how cars and motorcycles level their beams.
- Low beam: two LEDiL FILIPPA-STVZO cutoff optics with XP-L HI replace the Nichia 519A + Carclo elliptical flood (owner, 2026-11-21). Larger mirror, heatsink and window; BOM, calibration step D and tests B-OPT-05 to B-OPT-07 updated; B-OPT-01 retired. Weight estimate now over the 350 g limit with lidar (open question).
- design.md §3: beam estimate (beam angles, peak intensity, throw) and a note that the flood has no cutoff; §10 open question; test B-OPT-04.
- design.md §4: power breakdown, input current per mode, lidar draw, and a 15 V 3 A bank recommendation; why wheel USB ports can't power the head, and the wheel 12 V rail and main-battery alternatives.

### Fixed
- v4 model with the curved clear sides: the front face was drawn ~12 mm too far back (corner spheres placed for an 18 mm corner but sized 6 mm), so the mirrors, optics and lidar poked through the skin and the shell measured light. Corner now an arc, 1 mm more front clearance for the mirror at full tilt and swing, new check C-PKG-18 (`cad/fit-v4.scad`). Mass ~393 → ~399 g with the lidar (limit 400 g).
- BOM: one thermistor instead of two, one fewer 10 k resistor, totals updated.
- Design: the heatsink lid is finned aluminium, not die-cast.
