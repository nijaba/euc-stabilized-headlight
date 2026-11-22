# Firmware

ESP32-S3 firmware for the headlight (PlatformIO). Behaviour is defined in [../docs/firmware-spec.md](../docs/firmware-spec.md); tests are listed in [../docs/test-plan.md](../docs/test-plan.md).

## Run the tests

```bash
pio test -e native
```

These run on the computer, with no board. They include the test-plan ID check (U-PLAN-01).

## Layout

```
platformio.ini            environments: native (host tests); the board environment comes later
lib/headlight_core/src/   pure logic: no Arduino, no clock, no hardware I/O
  pitch_filter.*          gated complementary pitch filter (spec §2)
  road_follow.*           hill follower: road grade from the IMU (spec §2)
  mirror_cmd.*            mirror and servo command (spec §2)
test/
  imu_sim.h               ideal IMU used by the tests
  test_filter/            U-FILT
  test_road/              U-ROAD
  test_mirror/            U-MIR
  test_plan/              U-PLAN-01: tests and test plan agree
```

## Rules

- Pure logic takes `dt`, `now` and sensor readings as arguments; it never reads the clock or hardware.
- Every test function's name starts with its test-plan ID, for example `test_U_FILT_02_...`, and the row is added to the plan in the same change. When a test passes, mark its row's status.
- The board environment (`xiao_esp32s3`) and the hardware layer wait on the platform choice (design §10: Arduino-ESP32 3.x needs the community pioarduino platform).
