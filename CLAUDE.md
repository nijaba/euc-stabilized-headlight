# EUC Stabilized Headlight

An open-hardware, self-levelling headlight for electric unicycles. Two mirrors, each tilted by servos on two axes, keep the beam level while the wheel pitches and swing it into turns (layout v4). The project covers the ESP32-S3 firmware, a 3D-printed housing and a bill of materials.

- `docs/design.md` is the source of truth for the hardware. `docs/firmware-spec.md` is the source of truth for firmware behaviour. Read the relevant section before changing anything.
- `docs/build-plan.md` lists the phases in order. Work on the current phase only, and tick items as they pass.
- `docs/test-plan.md` lists every test by ID: automated firmware tests, bench tests, enclosure tests and ride tests.

## Firm constraints

The owner decided these (2026-11-20). Ask before trading one away.

- **Mirror steering.** The LEDs and heatsinks never move. Only the mirrors tilt to steer the beams.
- **External power only.** The head has no battery. USB-C PD is negotiated at the power bank, in its pouch, and only plain DC reaches the head.
- **Material cost ≤ $450 per unit, with the optional lidar fitted** (raised from $350 on 2026-11-20). This excludes the power bank, tools, and packs left over after one unit. The current estimate is about $409 for layout v4 with the TFS20-L lidar (2026-11-22).
- **Head weight ≤ 400 g, with the optional lidar fitted** (raised from 350 g on 2026-11-21).
- **The lidar stays optional.** The firmware and housing must work fully without it.
- **No personal data in the repository:** no real names, hostnames, accounts or locations in code, docs, tests or commit messages. Personal build or ride notes go in `*.local.md`, which git ignores. The one approved exception is the repository's GitHub handle, in repository links and `CODEOWNERS`.

Current choices that are not firm constraints (change them through the design doc): XIAO ESP32-S3, Arduino-ESP32 3.x under PlatformIO, NimBLE, BuckBlock drivers, four hobby servos, ASA housing with thermoformed polycarbonate sides, layout v4 (adopted 2026-11-21).

## Commands

`firmware/` is a PlatformIO project. Both environments build; the board one uses the pinned pioarduino platform (design §7) and needs PlatformIO Core 6.2 or later:

```bash
pio test -e native          # automated firmware tests on the host, including the test-plan ID check
pio run -e xiao_esp32s3     # build for the board
pio run -e xiao_esp32s3 -t upload && pio device monitor   # flash and watch the serial log
```

Packaging model (needs OpenSCAD; set `OPENSCAD` if it isn't on the PATH):

```bash
cad/render.sh               # renders to cad/renders/, runs C-PKG and C-MASS checks
```

## Layout

```
README.md            overview, goals, key figures
docs/design.md       hardware design: optics, mirror, power, housing, thermal, electronics, lidar
docs/firmware-spec.md firmware behaviour: control loop, calibration, auto-off, derating, remote, lidar
docs/index.html      project site home (GitHub Pages serves docs/); keep its figures in step with the docs
docs/v4-ride-demo.html animated simulation of the v4 levelling and turn steering (keep in step with firmware-spec §2)
docs/build-plan.md   phases in order, with checkboxes
docs/test-plan.md    every test by ID, with its status
hardware/BOM.md/.csv bill of materials (keep the two in sync)
firmware/            ESP32-S3 firmware (to do)
cad/                 OpenSCAD packaging model, render script, mass budget
```

## Rules that must always hold

These are the safety invariants from firmware-spec.md §1. Each one has tests in the test plan.

- The beam is never switched fully off by the remote or by heat while the wheel is moving.
- An obstacle detected by the lidar can never raise the beam.
- Losing a sensor or the remote falls back to a safe state (lidar → IMU only; IMU → fixed mirror at the calibrated aim, reduced brightness; remote → keep the current mode).
- All brightness changes are rate-limited.
- If the MCU dies, the LED drivers run at full current (hardware failsafe).
- The cornering lights only add light: they never dim or move the main beam, and any fault turns them off.

## How to work here

1. Read the matching part of the design doc or firmware spec. If it's silent or wrong, ask. When the owner decides, update the doc in the same change, with the date of the decision.
2. Keep pure logic (filter, mirror maths, state machines, derating tables, lidar rules) in modules with no hardware I/O, so it runs under `pio test -e native`. Pass `now` and sensor readings in; never read the clock or hardware inside them.
3. Every automated test's name starts with its test-plan ID, for example `test_U_FILT_02_braking_does_not_tilt`. Add the row to `docs/test-plan.md` in the same change. Bench, enclosure and ride tests are recorded in the plan with a date and result.
4. A bug fix's test must fail without the fix: remove the fix once and watch it fail.
5. When a part changes, update `hardware/BOM.md`, `hardware/BOM.csv` and the cost summary together, and check the cost and weight limits.
6. One branch and one PR per task, including docs and a `CHANGELOG.md` line. Ask before merging each PR, and merge with a merge commit. Commits are signed; never bypass signing.
7. Say plainly what wasn't verified, for example "logic tested on the host only, not on the board".
