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
6. The cornering lights only add light. They never dim or move the main beam, and any fault turns them off.

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
- **Response time (owner requirement, 2026-11-21).** The wheel pitches up to **±10°** when accelerating or braking, and the beam must adapt in **under 1 s**.
  - **Pitch from accelerating or braking:** the mirror cancels it directly. A 10° change needs 5° of mirror, and the servo moves that in under 50 ms (design §2, B-MIR-01), so the beam is corrected within about 0.1 s.
  - **A change of road grade:** the hill follower must settle within 1 s. The current line above can't: with τ = 4 s it takes about 12 s.
- **Hill follower: proposed change (2026-11-21, owner to decide).** The v4 ride demo, which runs this loop with ±10° of pitch, shows three faults in the line above:
  - **Acceleration reads as a hill.** After 3 s of acceleration at 10° of pitch, the cutoff creeps from 38 m to about 7 m; after braking it overshoots to about 79 m.
  - **Even a gentle speed-up of 0.15 m/s² does it.** That tilts the wheel only 0.9°, but the follower soon treats it as a downhill and the cutoff falls to about 18–24 m.
  - **Slow over a crest.** Going from +8% to −8%, the estimate keeps the climb, so the cutoff points above the falling road for about 4 s after the top (IMU only).

  Proposed fix: before following, remove the pitch that the measured acceleration explains, then follow fast. Freeze only during hard acceleration or a jolt.

  ```c
  // longitudinal acceleration: what the accelerometer sees beyond gravity at the gyro's pitch
  float a_long = G * (sinf(acc_pitch) - sinf(pitch));
  float tilt   = K_TILT * atan2f(a_long, G);                 // pitch the acceleration explains; K_TILT ≈ 1
  float raw    = pitch + tilt;                                // pitch with the acceleration lean removed ≈ road grade
  bool  jolt   = fabsf(a_long) > 1.0f || fabsf(norm(acc)/G - 1) > 0.2f;
  hold = jolt ? 0.3f : fmaxf(0, hold - dt);                   // 0.3 s hold-off after hard acceleration or a bump
  if (hold == 0) road_imu += (raw - road_imu) * dt / TAU_ROAD; // TAU_ROAD = 0.3 s: 95% settled in 0.9 s
  ```
  - **Why it can be fast:** the old follower had to be slow because the only signal it had was pitch, which mixes hills and acceleration. Removing the acceleration's share first leaves mostly the road grade, so a 0.3 s time constant is safe. A grade change settles within 0.9 s, inside the 1 s requirement.
  - **`K_TILT`:** how much the wheel pitches per unit of `atan(a/g)`. 1.0 means the wheel pitches by the balance angle, so 10° at about 1.7 m/s². The default is 1.0. It is learned from steady accelerations on flat ground, or set from the calibration page (§11).
  - **Why freeze at all:** above 1 m/s² (about 6° of tilt), an error in `K_TILT` would matter. A bump's jolt corrupts both the pitch and `a_long` for a moment. Holding 0.3 s covers both.
  - **Simulated result** (perfect IMU, servo 150°/s at the mirror, same ride with ±10° of pitch):

    | Part of the ride | Current spec | Proposed |
    |---|---|---|
    | Accelerating, 10° nose-down | cutoff 38 → 7 m | 38 m |
    | Braking, 10° nose-up | up to 79 m | ≤ 38 m |
    | Gentle 0.15 m/s² speed-up | 18–24 m | 38 m |
    | Time above the road after an 8% crest | ~4.1 s | ~1.9 s |
    | Pitch correction for accelerating or braking | ~0.05 s (servo) | ~0.05 s (servo) |
    | Grade change, 95% settled | ~12 s | ~0.9 s |

  - **If the wheel pitches 20% more or less than `K_TILT` assumes:** the cutoff stays between 31 and 50 m through hard acceleration and braking.
  - **Not fixable by the IMU:** before a crest, a beam parallel to the climbing road passes over the top; at the bottom of a hill, the rising road ahead catches the beam short (about 11 m). Only the lidar, which sees the road ahead, removes these.
  - **Tests if adopted:**
    - U-ROAD-01: changes to "a grade step settles to 95% within 1 s".
    - U-ROAD-03: a 10° acceleration lean with `K_TILT` correct moves `road_imu` by under 0.3°.
    - U-ROAD-04: a 0.15 m/s² acceleration for 8 s moves `road_imu` by under 0.3°.
    - U-ROAD-05: `a_long` over 1 m/s² or a 0.2 g jolt freezes the follower, which resumes 0.3 s later.
    - B-MIR-01: stays at under 50 ms for the mirror (unchanged).
    - R-ROAD-01: on a real crest, the cutoff doesn't stay above the road for more than 1.5 s after the top.
    - R-ROAD-02: `K_TILT` learned on flat ground is within 20% of a hand measurement, and with it the cutoff stays between 30 and 50 m through a hard acceleration and a hard stop.
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
| Triple-click then hold 2 s, **stationary only** | Start the Wi-Fi calibration page (§11) |
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

## 10. Cornering lights

Two fixed lights aimed 30° outward and 10° down (design §3). Left on D3, right on a back-pad GPIO, each through a 700 mA driver's PWM input.

- **Inputs:** lean angle (roll about the learned forward axis, from the same gated filter as pitch) and yaw rate (gyro about the learned vertical axis). `now` is passed in.
- **Side:** the side the wheel turns toward: the sign of the yaw rate, which must agree with the lean direction.
- **On:** while moving, when |lean| > 8° **or** |yaw rate| > 20°/s for 150 ms.
- **Off:** when |lean| < 5° **and** |yaw rate| < 12°/s for 400 ms, when stationary or parked, or on any sensor fault.
- **Brightness:** 40% at the threshold, rising linearly to 100% at 20° of lean.
- **Fades:** in over 0.2 s, out over 0.6 s.
- **Thermal cap:** after 20 s continuously at full power on one side, that side falls to 50% until it has been off for 20 s.
- Only one side is lit at a time. If the inputs flip side, the old side fades out as the new one fades in.

## 11. Calibration and settings: how they're controlled (decided 2026-11-21)

**Decision (owner, 2026-11-21): option B, the Wi-Fi calibration page, with the button and remote (A) kept as a full fallback.** Every calibration step and the everyday controls stay usable without a phone; the page adds feedback, settings and logs.

Options considered:

| Option | What the rider uses | Works on | Extra parts | Effort | Notes |
|---|---|---|---|---|---|
| A. Button and remote only (current) | Button holds and clicks, ring-LED blinks | — | None | Low | Hard to see what's happening; no logs |
| **B. Calibration page over the head's own Wi-Fi (recommended)** | Any phone's browser, joined to the head's hotspot | iPhone and Android, no install | None (the ESP32-S3 has Wi-Fi) | Medium | Live pitch and aim, guided steps, settings, ride-log download |
| C. Web Bluetooth page | A browser page talking Bluetooth to the head | Android and desktop Chrome only; **not iPhone** | None | Medium | Rules out iPhone riders |
| D. Native phone app | An app from the app stores | iPhone and Android | None | High | Store accounts, reviews and upkeep; overkill |

**How B works:**
- **Starting it:** on the head button, triple-click then hold 2 s, **stationary only**; or a remote combo (TBD, §7). A plain hold is avoided because hold 3 s is already on/off. The head starts a hotspot named `EUC-Light-` plus a random 4-character suffix, with a random WPA2 password generated on first boot and shown in the serial log and on a printed label. No personal data.
- **It stops** after 10 min idle, or as soon as the wheel moves. The hotspot is never on while riding.
- **The page,** served from the ESP32's flash:
  - live pitch and roll
  - guided calibration steps A–D with a mirror-trim slider and an aim slider
  - settings: modes, brightness levels, cornering thresholds or, for v4, yaw limits
  - ride-log download as CSV
  - over-the-air updates possibly later
- **Fallback:** if the phone or the page fails, every step in §3 still works with the button and the remote, exactly as before.
- **Safety:** the firmware validates every setting and clamps it to safe ranges. No setting can break a safety invariant (§1); for example, the minimum brightness while moving has a floor.
- **Security, from the project rules:**
  - a strict Content Security Policy, with no external scripts or fonts
  - every displayed value escaped
  - writes as POST with a JSON body and a request ID applied once
  - a rate limit on writes
  - the password changeable from the page
- **Dependencies:** Arduino-ESP32's built-in Wi-Fi and WebServer, so no new libraries. Wi-Fi draws ~100 mA, only while calibrating.

**Tests:** U-CFG-01 to U-CFG-04 and B-CFG-01 in the test plan. The page itself is designed under the project's web rules when the firmware reaches it.
