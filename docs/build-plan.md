# Build Plan

Phases in order. Work on the current phase only, and tick each item when it passes. Test IDs refer to [`test-plan.md`](test-plan.md).

**Current phase: 2.** Phases 0 and 1 are complete.

## Phase 0: Project setup and budget

- [x] Concept, requirements, mirror-steering approach
- [x] BOM v2 (XIAO ESP32-S3, printed housing, external power, optional lidar)
- [x] `CLAUDE.md`, build plan, test plan, changelog
- [x] `CONTRIBUTING.md` and `SECURITY.md`
- [x] Branch protection on `main` (signed commits, PR required)
- [x] Material cost within the limit: ~$388 with the lidar (~$423 after the FILIPPA low beam, cornering lights and lean package), under the $450 limit set on 2026-11-20; ~$440 for layout v4, ~$401 with the TFS20-L lidar (2026-11-21)

## Phase 1: Packaging study

Goal: a parametric model and renders of the whole head prove it fits, sweeps and stays within the weight limit before parts are bought or firmware is written (owner's decision, 2026-11-21).

- [x] OpenSCAD model in `cad/` with every part at datasheet size: heatsink, optics, mirror and pivot, servo and linkage, electronics, seals, mount, optional lidar
- [x] Clearance checks across the mirror's full sweep and the beam through the window (C-PKG)
- [x] Mass budget from part masses and printed volumes (C-MASS-01): ~556 g with the lidar, over the limit
- [x] Renders: three-quarter, front, side cut-away, exploded, on a generic wheel for scale
- [x] Layout v2: heatsink at the bottom, fins fore-aft, mount on the back, weight savings (owner's requirements, 2026-11-21)
- [x] Owner decision on the weight: limit raised to 400 g, lidar stays on the head, two spots kept (2026-11-21)
- [x] Layout v3: aerodynamic tapered shape and lean package; printed parts measured from the model
- [x] Layout v4 study: two 2-axis mirrors, lidar in the body, no cornering lights or brow (~410 g)
- [x] Owner decision: v4 adopted, with one clear wraparound piece per side (2026-11-21)
- [x] Owner review of the renders (2026-11-21): narrow the body (target ~150 mm), fins fine, sides stay clear, add an exploded view. Done with the TFS20-L lidar, moved low into the nose under the beams: ~151 mm body, design §5 updated

## Phase 2: Firmware core on the bench

**Order the bench kit first** (`hardware/BOM.md`, "Bench kit"). Why a bench kit rather than the final board (2026-11-21):
- There is no final board to order yet. v1 is wired on protoboard (design §7); a custom PCB is phase 9.
- A PCB designed now would freeze choices the bench tests haven't settled: v3 or v4 (one servo or four, cornering drivers or not), the dimming interface and the power-on flash fix (B-DRV), the fuse rating (B-PWR-01), and the extra GPIO on the XIAO's back pads. Each respin costs money and 1–3 weeks.
- Most bench-kit parts are the real parts and go into the final build. The extras are about $45 of tools and test pieces.
- Firmware can start straight away: the pure logic runs on the computer (`pio test -e native`), and the bench kit tests the hardware layer (IMU, servo PWM, LED dimming) and the laser-on-mirror checks.
- On a breadboard, everything can be probed and changed in minutes.


Goal: the IMU filter drives the servo, checked with a laser pointer on the mirror.

- [ ] PlatformIO project in `firmware/` with a `native` test environment and a `xiao_esp32s3` board environment. Native done 2026-11-22; board environment builds 2026-11-22 (pioarduino, design §7), not yet flashed
- [x] Test-plan ID check (U-PLAN-01), 2026-11-22
- [x] Pure modules: pitch filter, road follow, mirror command (U-FILT, U-ROAD, U-MIR), host tests pass 2026-11-22
- [ ] Hardware layer: LSM6DSO32 over I²C, servo PWM on LEDC
- [ ] Serial telemetry: pitch, mirror command, state
- [ ] Laser-on-mirror bench: response, jitter, range (B-MIR-01 to B-MIR-03)
- [ ] Decide: hobby servo is good enough, or move to a gimbal BLDC (design.md §10)

## Phase 3: Power and LED drivers on the bench

Goal: the protoboard powers both channels safely and dims them smoothly.

- [ ] Protoboard: input protection, 5 V rail, 2N3904 DIM stages, voltage divider, NTC
- [ ] BuckBlock dimming: linearity, minimum level, zero output (B-DRV-01, B-DRV-02)
- [ ] Dead-MCU failsafe and power-on flash (B-DRV-03, B-DRV-04); decide how to handle the flash
- [ ] Input protection: fuse in boost when hot, reverse polarity, overvoltage (B-PWR-01 to B-PWR-03)
- [ ] Bank fallbacks, USB while powered, input power (B-PWR-04 to B-PWR-06)

## Phase 4: Optics and mirror mechanism

Goal: the mirror size and window height are proven before CAD fixes them.

- [ ] FILIPPA focus height and cutoff with XP-L HI (B-OPT-05, B-OPT-06, B-OPT-07)
- [ ] v4 cutoff roll: the FILIPPA cutoff's roll across the yaw travel against the model, swing = roll (B-OPT-08; design §5, cutoff roll in turns)
- [ ] Beam clipping across ±7.5° of mirror (B-OPT-02)
- [ ] Mirror balance and ringing under vibration (B-MIR-04)
- [ ] Light output, beam intensity and angles, heatsink temperature rise (B-OPT-03, B-OPT-04, B-THM-01, B-THM-02)

Dropped with layout v4 (2026-11-21), kept in the test plan for v3: toe-out wedges, cornering lights (B-CRN-01, B-CRN-02) and the convex low-beam mirror (B-OPT-09).

## Phase 5: Firmware features

- [ ] Calibration A–D, saved in NVS (U-CAL)
- [ ] Auto-off state machine and sleep (U-OFF, B-SLP-01)
- [ ] Thermal derating and boost limits (U-THM)
- [ ] Input-voltage handling (U-VIN)
- [ ] BLE remote, head button (U-REM, B-REM-01, B-REM-02)
- [ ] **Owner decision, gate for turn steering:** the turn-swing cap (proposed: lean + 3°) and what to do about the outside beam's full-lean tilt (design §5, cutoff roll in turns). The turn rule is not written or coded before this.
- [ ] v4 turn steering: the yaw rule and its safety invariant written into firmware-spec §10, then coded (U-TURN-01)
- [ ] Safety invariant tests (U-SAFE)
- [ ] DIY remote firmware (XIAO nRF52840)

## Phase 6: Housing

- [ ] Decide the service cover position and how firmware updates reach the head without opening it (design §10)
- [ ] Parametric CAD: body, bezel, mirror cradle, servo bracket, optic plate, electronics tray, desiccant holder, mount boss, remote case
- [ ] Print in ASA, fit-check every part
- [ ] Leak test empty, then after thermal cycling (E-SEAL-01 to E-SEAL-03)
- [ ] Weight and mount pull test (E-MNT-01, E-MNT-02)

## Phase 7: Integration and ride tests

- [ ] Full assembly, calibration on the wheel
- [ ] Ride tests: aim, hills, auto-off, temperature, runtime, turns (R-AIM, R-OFF, R-THM, R-RUN, R-CRN)
- [ ] Filter tuning from logged rides
- [ ] User guide: mounting, calibration, remote

## Phase 8: Optional road-slope lidar

- [ ] Lidar rules in firmware (U-LID)
- [ ] Range through the nose window, then dropouts on real asphalt (B-LID-02, B-LID-01); lidar temperature inside the head (B-THM-03)
- [ ] Ride test at crests, dips and obstacles (R-LID-01)

## Phase 9: Custom PCB

- [ ] Schematic and layout replacing the protoboard
- [ ] Re-run the phase 2 bench tests on the PCB
