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

## Layout

```
platformio.ini            environments: native (host tests), xiao_esp32s3 (board)
src/main.cpp              board entry point (Arduino); not built on the host
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
- The board environment (`xiao_esp32s3`) uses Arduino-ESP32 3.x through the community pioarduino platform, pinned to one release in `platformio.ini` (design §7). It needs PlatformIO Core 6.2 or later. To move to a newer release, pick one at least 14 days old and update the URL and digest together.
- `src/main.cpp` is the board entry point. The host build skips it; for now it only prints a boot line. The hardware layer comes next.
