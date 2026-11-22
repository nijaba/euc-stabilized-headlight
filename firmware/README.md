# Firmware

ESP32-S3 firmware for the headlight (PlatformIO). Behaviour is defined in [../docs/firmware-spec.md](../docs/firmware-spec.md); tests are listed in [../docs/test-plan.md](../docs/test-plan.md).

## Run the tests

```bash
pio test -e native
```

These run on the computer, with no board. They include the test-plan ID check (U-PLAN-01).

## Build for the board

```bash
pio run -e xiao_esp32s3
pio run -e xiao_esp32s3 -t upload && pio device monitor
```

### If the board build says "not compatible with PlatformIO Core v6.2.0-post.1"

Found 2026-11-22 with pioarduino 55.03.312-1. On its first build, the platform installs its own fork of PlatformIO (the `pioarduino` Python package) into PlatformIO's environment, over the `platformio` package. The fork calls itself 6.2.0.post1, which the platform's own check (`>=6.2.0`) reads as older than 6.2.0. Nothing breaks while the platform stays installed, but the next time it has to be installed (a new computer, CI, a cleared cache) PlatformIO refuses it.

Put the real core back, then build. The fork stays installed, so the build doesn't overwrite the core again:

```bash
~/.platformio/penv/bin/python -m pip install --force-reinstall --no-deps "platformio==6.2.0"
pio run -e xiao_esp32s3
```

`pio --version` should then say 6.2.0. Check whether a newer pioarduino release still does this before moving to it.

## On the bench

Wire the IMU to D4/D5 (STEMMA QT), the left pitch servo to D10 and the left yaw servo to D3, power the servos from a 5 V supply (not the XIAO's pin), and open the serial monitor at 115200 baud. Each line reads like `t=12345 pitch=+1.23 road=+0.40 mirror=-0.42 sl=88.3 sr=91.7 timu=31.5 st=RUN`. Tilt the board: the left pitch servo should move half the tilt times the 4:1 linkage, the other way. `st=IMU_LOST` means the IMU stopped answering and the mirrors hold the aim. The right side's servos go on the XIAO's back pads (GPIO41/42), which still need confirming on Seeed's pinout.

## CI

`.github/workflows/ci.yml` runs the host tests and the board build on every PR and on main, when `firmware/`, the test plan or the workflow change. "CI passed" is required to merge into main (branch protection, 2026-11-22). It runs on every PR, and passes when the firmware jobs pass or were skipped because nothing they cover changed. Actions are pinned by SHA; Dependabot proposes updates after 14 days.

## Layout

```
platformio.ini            environments: native (host tests), xiao_esp32s3 (board)
src/                      board code (Arduino); not built on the host
  main.cpp                200 Hz loop: IMU -> filter -> hill follower -> mirror servos, telemetry
  board.h                 pins (design §7) and bench defaults until calibration
  imu_lsm6dso32.*         LSM6DSO32 over I2C: configure, burst-read one sample
  servo_out.*             servo PWM on LEDC
lib/headlight_core/src/   pure logic: no Arduino, no clock, no hardware I/O
  pitch_filter.*          gated complementary pitch filter (spec §2)
  road_follow.*           hill follower: road grade from the IMU (spec §2)
  mirror_cmd.*            mirror and servo command (spec §2)
  imu_convert.*           raw counts to units, pitch inputs for any mounting
  imu_watch.*             IMU-lost detection (spec §1.3)
  servo_pwm.*             servo angle -> pulse -> LEDC duty
  telemetry.*             serial telemetry line (spec §9)
test/
  imu_sim.h               ideal IMU used by the tests
  test_filter/            U-FILT
  test_road/              U-ROAD
  test_mirror/            U-MIR
  test_imu/               U-IMU
  test_servo/             U-SRV
  test_telemetry/         U-TEL
  test_plan/              U-PLAN-01: tests and test plan agree
```

## Rules

- Pure logic takes `dt`, `now` and sensor readings as arguments; it never reads the clock or hardware.
- Every test function's name starts with its test-plan ID, for example `test_U_FILT_02_...`, and the row is added to the plan in the same change. When a test passes, mark its row's status.
- The board environment (`xiao_esp32s3`) uses Arduino-ESP32 3.x through the community pioarduino platform, pinned to one release in `platformio.ini` (design §7). It needs PlatformIO Core 6.2 or later. To move to a newer release, pick one at least 14 days old and update the URL and digest together.
- `src/main.cpp` is the board entry point. The host build skips it; for now it only prints a boot line. The hardware layer comes next.
