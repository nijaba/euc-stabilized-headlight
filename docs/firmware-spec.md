# Firmware Specification

- **Target:** Seeed XIAO ESP32-S3.
- **Framework:** Arduino-ESP32 core 3.x under PlatformIO.
- **BLE:** NimBLE-Arduino, acting as an HID host.
- **Pin map:** see [`design.md` §7](design.md#7-electronics).

## 1. Safety invariants (always true)

1. The beam is **never switched fully off by the remote or by heat while the wheel is moving.**
2. An obstacle detected by the lidar can **never raise** the beam.
3. Losing a sensor or the remote falls back to a safe state:
   - lidar → IMU only
   - IMU → fixed mirror at the calibrated aim, reduced brightness
   - remote → keep the current mode
4. All brightness changes are rate-limited, so there are no visible steps or flicker.
5. If the MCU dies, the BuckBlock DIM inputs float and the light runs at full current (hardware failsafe).

## 2. Control loop (200–400 Hz)

```c
// gated complementary filter: trust the accelerometer only when not accelerating
pitch += gyro_pitch_rate * dt;                       // rate about the learned pitch axis
bool steady = fabsf(norm(acc)/G - 1) < 0.03f && fabsf(gyro_pitch_rate) < 5.0f;
if (steady) pitch += 0.02f * (acc_pitch - pitch);    // slow absolute correction

road_imu += (pitch - road_imu) * dt / TAU_ROAD;      // hill following, TAU ≈ 4 s
road      = lidar_ok ? blend(road_imu, lidar_grade) : road_imu;

float err    = pitch - (follow_road ? road : level_offset);
float mirror = clamp(-err / 2 + aim_down / 2, -7.5f, 7.5f);   // mirror doubles the angle
servo_write_deg(trim + mirror * LINKAGE_RATIO);                // ≈ 4:1
```

- **Why the gate:** the accelerometer can't tell braking from tilting. 0.5 g of braking reads as about 27° of false tilt.
- **Road reference:** `follow_road` (on by default) aims the beam at the road. When off, the beam holds pure gravity level.
- **Servo output:** 50–333 Hz PWM from the ESP32's LEDC peripheral, clamped to the mechanical limits.

## 3. Calibration (saved in NVS)

| Step | When | Procedure | Stored |
|---|---|---|---|
| A. Mirror trim | Once, at home | Aim at a wall; remote clicks move the hotspot to lamp height | `trim` (servo µs) |
| B. Level | After mounting | Hold the wheel upright with the **pedals level** (phone level app), hold the button 3 s, keep still 2 s | gravity vector in IMU axes; lidar height `h` (if fitted) |
| C. Pitch axis | Right after B | LED blinks: rock the wheel forward and back 3 times by the handle | pitch axis = main axis of the gyro motion |
| D. Aim | At a wall 10 m away, or on the first night ride | Aim mode: remote moves the low-beam cutoff line to about 20 cm below the lamp's height on the wall (about 1.2° down, so it meets the road about 38 m ahead with the head at 0.8 m) | `aim_down` |

- After calibration, pitch is measured as rotation about the learned axis, relative to the learned gravity vector. The head only needs to face forward within about 10°.
- **Optional:** slowly refine `level_offset` from the average steady pitch while cruising on flat road.

## 4. Auto-off state machine

| Condition | Detection | Action |
|---|---|---|
| Picked up / trolley mode | `|pitch − level| > 35°` for > 0.3 s | Beam off at once, mirror parked. Back on when level for 1 s |
| Crash / wheel on its side | Impact > 4 g **or** roll > 60°, then still | Off; button press to restore |
| Parked | Gyro RMS ≈ 0 for 2 min (a ridden EUC always wobbles a little) | Dim to 20% |
| Parked for longer | Same, 10 min | Sleep: IMU wake-on-motion on INT1, ESP32 light sleep. The bank may cut power, which is fine |
| Moving again | IMU interrupt | Restore the last mode |

All transitions have hysteresis.

## 5. Thermal derating

Inputs:
- the heatsink NTC (D1)
- the IMU's on-chip temperature sensor (internal temperature)

| Heatsink | Action |
|---|---|
| < 60 °C | Full power |
| 60–80 °C | Spot dims first, then flood, linearly down to 40% |
| > 80 °C | Flood only at 25%, ring LED amber pattern |
| > 90 °C or NTC open/short | 10% failsafe |
| Internal > 65 °C | Cap total power |

- Ramp at most 2% per second, with 5 °C hysteresis.
- Minimum brightness while moving (see invariant 1).
- Boost mode (2.1 A) is allowed only below 60 °C and for at most 60 s at a time.

## 6. Input-voltage handling

| Input voltage | Action |
|---|---|
| ≥ 13 V | Normal |
| 10–13 V (bank fell back to 12 V or 9 V) | Cap brightness; warn with the ring LED |
| < 10 V | Flood only at 30%, warn |

## 7. BLE remote

- The head is a NimBLE HID host and bonds only to the whitelisted remote.

**Remote options:**
- **Cheap:** a BLE camera shutter or page-turner ring (HID consumer keys).
  - These sleep, and the first press after sleeping can take 1–3 s or be lost.
- **Recommended:** DIY XIAO nRF52840 with 2 buttons.
  - Stays connected at about 100 ms intervals, so presses arrive in roughly 100 ms or less.
  - Lasts days on 150 mAh.

| Input | Action |
|---|---|
| Click | Low ↔ high |
| Hold | Flash-to-pass (high while held) |
| Double-click | Low-beam level 50 / 75 / 100% |
| Hold 3 s, **stationary only** | On / off |
| Combos (TBD) | Enter trim mode (A) / aim mode (D), boost |

If the remote disconnects, the light keeps its current mode. The button on the head mirrors the remote's actions.

## 8. Lidar road-slope fusion (optional TF02-Pro)

- **Input:** range `d` and signal strength at 100 Hz, over I²C.
- **Grade:** `φ = atan2(h − d·sin β, d·cos β)`, where `β` is the ray's true depression angle from the IMU.
- **Filtering:** median over about 100 ms, then rate-limited.

**Rejection rules:**

| Situation | Signature | Response |
|---|---|---|
| Obstacle (car, person, kerb) | Implied grade > +12% or a sudden range drop | Ignore; hold the last good value, decaying to `road_imu`. **Never lift.** |
| Crest / road falls away | No return or range at the maximum | Small downward bias, then decay to `road_imu` |
| Wet / specular road, spray | Low signal strength or dropouts | Lower weight → `road_imu` |
| Healthy | Consistent returns, plausible grade | Blend: `road = road_imu + k·(lidar_grade − road_imu)` |

## 9. Telemetry and debugging

- Serial log over the XIAO's USB-C: pitch, mirror command, temperatures, input voltage, state.
- Optional: log to flash at 50 Hz for analysing rides afterwards.
