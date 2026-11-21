# Build Plan

Phases in order. Work on the current phase only, and tick each item when it passes. Test IDs refer to [`test-plan.md`](test-plan.md).

**Current phase: 1.** Phase 0 is complete.

## Phase 0: Project setup and budget

- [x] Concept, requirements, mirror-steering approach
- [x] BOM v2 (XIAO ESP32-S3, printed housing, external power, optional lidar)
- [x] `CLAUDE.md`, build plan, test plan, changelog
- [x] `CONTRIBUTING.md` and `SECURITY.md`
- [x] Branch protection on `main` (signed commits, PR required)
- [x] Material cost within the limit: ~$388 with the lidar (~$398 after the FILIPPA low beam), under the $450 limit set on 2026-11-20

## Phase 1: Firmware core on the bench

Goal: the IMU filter drives the servo, checked with a laser pointer on the mirror.

- [ ] PlatformIO project in `firmware/` with a `native` test environment and a `xiao_esp32s3` board environment
- [ ] Test-plan ID check (U-PLAN-01)
- [ ] Pure modules: pitch filter, road follow, mirror command (U-FILT, U-ROAD, U-MIR)
- [ ] Hardware layer: LSM6DSO32 over I²C, servo PWM on LEDC
- [ ] Serial telemetry: pitch, mirror command, state
- [ ] Laser-on-mirror bench: response, jitter, range (B-MIR-01 to B-MIR-03)
- [ ] Decide: hobby servo is good enough, or move to a gimbal BLDC (design.md §10)

## Phase 2: Power and LED drivers on the bench

Goal: the protoboard powers both channels safely and dims them smoothly.

- [ ] Protoboard: input protection, 5 V rail, 2N3904 DIM stages, voltage divider, NTC
- [ ] BuckBlock dimming: linearity, minimum level, zero output (B-DRV-01, B-DRV-02)
- [ ] Dead-MCU failsafe and power-on flash (B-DRV-03, B-DRV-04); decide how to handle the flash
- [ ] Input protection: fuse in boost when hot, reverse polarity, overvoltage (B-PWR-01 to B-PWR-03)
- [ ] Bank fallbacks, USB while powered, input power (B-PWR-04 to B-PWR-06)

## Phase 3: Optics and mirror mechanism

Goal: the mirror size and window height are proven before CAD fixes them.

- [ ] FILIPPA focus height and cutoff with XP-L HI (B-OPT-05, B-OPT-06, B-OPT-07)
- [ ] Beam clipping across ±7.5° of mirror (B-OPT-02)
- [ ] Mirror balance and ringing under vibration (B-MIR-04)
- [ ] Light output, beam intensity and angles, heatsink temperature rise (B-OPT-03, B-OPT-04, B-THM-01, B-THM-02)

## Phase 4: Firmware features

- [ ] Calibration A–D, saved in NVS (U-CAL)
- [ ] Auto-off state machine and sleep (U-OFF, B-SLP-01)
- [ ] Thermal derating and boost limits (U-THM)
- [ ] Input-voltage handling (U-VIN)
- [ ] BLE remote, head button (U-REM, B-REM-01, B-REM-02)
- [ ] Safety invariant tests (U-SAFE)
- [ ] DIY remote firmware (XIAO nRF52840)

## Phase 5: Housing

- [ ] Parametric CAD: body, bezel, mirror cradle, servo bracket, optic plate, electronics tray, mount boss, remote case
- [ ] Print in ASA, fit-check every part
- [ ] Leak test empty, then after thermal cycling (E-SEAL-01 to E-SEAL-03)
- [ ] Weight and mount pull test (E-MNT-01, E-MNT-02)

## Phase 6: Integration and ride tests

- [ ] Full assembly, calibration on the wheel
- [ ] Ride tests: aim, hills, auto-off, temperature, runtime (R-AIM, R-OFF, R-THM, R-RUN)
- [ ] Filter tuning from logged rides
- [ ] User guide: mounting, calibration, remote

## Phase 7: Optional road-slope lidar

- [ ] Lidar rules in firmware (U-LID)
- [ ] Range and dropouts on real asphalt (B-LID-01)
- [ ] Ride test at crests, dips and obstacles (R-LID-01)

## Phase 8: Custom PCB

- [ ] Schematic and layout replacing the protoboard
- [ ] Re-run the phase 2 bench tests on the PCB
