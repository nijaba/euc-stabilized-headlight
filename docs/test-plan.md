# Test Plan

Every test has an ID. This file is the full list of what's covered.

| Prefix | Level | How it runs | Where results go |
|---|---|---|---|
| `U-` | Automated firmware tests | `pio test -e native` on the host, against pure modules with no hardware I/O | CI and the test run |
| `B-` | Bench tests | By hand, on the bench | The Status column here: date and result |
| `E-` | Enclosure and mount tests | By hand | The Status column here |
| `R-` | Ride tests | On the wheel, with serial or flash logs | The Status column here |
| `C-` | Packaging checks | `cad/render.sh`, against the OpenSCAD model | `cad/renders/checks.txt` and the Status column here |

**Naming.** An automated test's function name starts with its ID, with `-` replaced by `_`. For example, `U-FILT-02` is `test_U_FILT_02_braking_does_not_tilt`. U-PLAN-01 checks that every `U-` ID in this file has a test and every test's ID is in this file.

**Rules.**
- Pure modules take `now` and sensor readings as inputs. No test depends on the date or the wall clock.
- A bug fix's test must fail without the fix.
- Ride tests start only after the matching bench tests pass, and always with a backup light.

Status is "–" until a test exists or has been run.

## Automated firmware tests (`U-`)

### Test infrastructure

| ID | What it checks | Spec | Status |
|---|---|---|---|
| U-PLAN-01 | Every `U-` ID in this plan has a test, and every test name's ID is in this plan | — | – |

### Pitch filter

| ID | What it checks | Spec | Status |
|---|---|---|---|
| U-FILT-01 | Gyro integration tracks a known pitch rate | FW §2 | – |
| U-FILT-02 | 0.5 g of braking with the wheel level produces no tilt correction (accelerometer gated off) | FW §2 | – |
| U-FILT-03 | The gate rejects accelerometer correction when the pitch rate is above 5°/s | FW §2 | – |
| U-FILT-04 | When steady, pitch converges to the accelerometer pitch | FW §2 | – |

### Road follow

| ID | What it checks | Spec | Status |
|---|---|---|---|
| U-ROAD-01 | On a sustained hill, the road reference settles with a time constant of about 4 s | FW §2 | – |
| U-ROAD-02 | With `follow_road` off, the beam holds gravity level | FW §2 | – |

### Mirror command

| ID | What it checks | Spec | Status |
|---|---|---|---|
| U-MIR-01 | The mirror moves by half the pitch error, in the opposite direction | FW §2, design §2 | – |
| U-MIR-02 | The mirror command is clamped to ±7.5° | FW §2 | – |
| U-MIR-03 | Servo command = trim + mirror × linkage ratio, clamped to the mechanical limits | FW §2 | – |

### Calibration

| ID | What it checks | Spec | Status |
|---|---|---|---|
| U-CAL-01 | Level calibration stores the gravity vector in IMU axes | FW §3 B | – |
| U-CAL-02 | Rocking the wheel yields the main axis of the gyro motion as the pitch axis | FW §3 C | – |
| U-CAL-03 | With the head mounted up to 10° off in any direction, pitch is still measured correctly after calibration | FW §3 | – |
| U-CAL-04 | Calibration values survive a save and load round trip | FW §3 | – |

### Auto-off

| ID | What it checks | Spec | Status |
|---|---|---|---|
| U-OFF-01 | Pitch more than 35° from level for over 0.3 s turns the beam off and parks the mirror; level for 1 s turns it back on | FW §4 | – |
| U-OFF-02 | An impact over 4 g or roll over 60°, then stillness, turns the beam off until a button press | FW §4 | – |
| U-OFF-03 | Still for 2 min dims to 20%; still for 10 min goes to sleep | FW §4 | – |
| U-OFF-04 | A motion interrupt restores the last mode | FW §4 | – |
| U-OFF-05 | Inputs held at each threshold don't make the state chatter (hysteresis) | FW §4 | – |

### Thermal derating

| ID | What it checks | Spec | Status |
|---|---|---|---|
| U-THM-01 | Heatsink derating: full below 60 °C; spot dims first, then flood, to 40% at 80 °C; flood only at 25% above 80 °C | FW §5 | – |
| U-THM-02 | Above 90 °C, or with the NTC open or shorted, output drops to 10% | FW §5 | – |
| U-THM-03 | Internal temperature above 65 °C caps total power | FW §5 | – |
| U-THM-04 | Brightness ramps at most 2% per second, with 5 °C hysteresis | FW §5 | – |
| U-THM-05 | Boost is allowed only below 60 °C and for at most 60 s at a time | FW §5 | – |

### Input voltage

| ID | What it checks | Spec | Status |
|---|---|---|---|
| U-VIN-01 | ADC reading converts to input voltage through the 120 k / 15 k divider | design §7 | – |
| U-VIN-02 | Voltage table: normal at ≥ 13 V; capped and warning at 10–13 V; flood only at 30% below 10 V | FW §6 | – |

### Remote and button

| ID | What it checks | Spec | Status |
|---|---|---|---|
| U-REM-01 | Click, hold, double-click and hold-3 s map to the actions in the table | FW §7 | – |
| U-REM-02 | Hold-3 s on/off is ignored while the wheel is moving | FW §7 | – |
| U-REM-03 | A remote disconnect keeps the current mode | FW §7 | – |
| U-REM-04 | The head button produces the same actions as the remote | FW §7 | – |

### Lidar fusion (optional hardware)

| ID | What it checks | Spec | Status |
|---|---|---|---|
| U-LID-01 | The grade formula gives the right slope for known heights, ranges and angles | FW §8 | – |
| U-LID-02 | An implied grade above +12% or a sudden range drop is ignored and never lifts the beam | FW §8 | – |
| U-LID-03 | No return or maximum range gives a small downward bias, then decays to the IMU estimate | FW §8 | – |
| U-LID-04 | Low signal strength or dropouts move the weight toward the IMU estimate | FW §8 | – |
| U-LID-05 | Healthy returns blend as `road_imu + k·(lidar_grade − road_imu)` | FW §8 | – |
| U-LID-06 | With no lidar fitted, the output is identical to IMU-only | FW §8, CLAUDE.md | – |

### Cornering lights

| ID | What it checks | Spec | Status |
|---|---|---|---|
| U-CRN-01 | The lit side is the side the wheel turns toward; lean and yaw rate must agree | FW §10 | – |
| U-CRN-02 | On above 8° lean or 20°/s yaw rate for 150 ms; off below 5° and 12°/s for 400 ms (hysteresis) | FW §10 | – |
| U-CRN-03 | Brightness 40% at the threshold rising to 100% at 20°; fade in 0.2 s, out 0.6 s | FW §10 | – |
| U-CRN-04 | Off when stationary, parked or on a sensor fault | FW §10 | – |
| U-CRN-05 | After 20 s at full power, a side drops to 50% until it has been off for 20 s | FW §10 | – |
| U-CRN-06 | Cornering lights never change the main beam's brightness or the mirror command | FW §1.6 | – |

### Safety invariants

These run long randomised input sequences against the whole control and state logic.

| ID | What it checks | Spec | Status |
|---|---|---|---|
| U-SAFE-01 | While moving, no remote input or temperature turns the beam fully off | FW §1.1 | – |
| U-SAFE-02 | No lidar input raises the beam above where the IMU alone would put it | FW §1.2 | – |
| U-SAFE-03 | Losing the lidar falls back to IMU only; losing the IMU fixes the mirror at the calibrated aim with reduced brightness; losing the remote keeps the mode | FW §1.3 | – |
| U-SAFE-04 | No brightness change, from any cause, steps faster than the rate limit | FW §1.4 | – |

## Packaging checks (`C-`)

Each check's message in `cad/headlight.scad` or `cad/weight.py` starts with its ID.

| ID | What it checks | Pass if | Status |
|---|---|---|---|
| C-PKG-01 | The optic row fits along the mirror | Row length ≤ mirror length | Pass (v2), 2026-11-21 |
| C-PKG-02 | The mirror clears the front wall at full tilt | At least 1 mm | Pass (v2), 2026-11-21 |
| C-PKG-03 | The mirror stays out of the electronics slot at full tilt | At least 1 mm | Pass (v2), 2026-11-21 |
| C-PKG-04 | The window aperture stays above the floor, and the mirror clears the optics at full tilt | At least 1 mm each | Pass (v2), 2026-11-21 |
| C-PKG-05 | Every beam fits the window width (FWTM spread, ±15° steering) | Beam reach ≤ half the inner length | Pass (v2), 2026-11-21 |
| C-PKG-06 | The servo fits the back slot, set 4 mm in from the back wall | Servo front ≤ slot depth − 2 mm | Pass (v2), 2026-11-21 |
| C-PKG-07 | The bottom heatsink fits inside the floor | Heatsink depth ≤ inner depth | Pass (v2), 2026-11-21 |
| C-PKG-08 | The window and bezel stay on the flat front, clear of the rounded bottom edge | Bezel bottom ≥ edge radius above the floor | Pass (v2), 2026-11-21 |
| C-PKG-09 | The cornering lights clear the lidar in the top brow | No overlap | Pass (2 FILIPPA + 2 spot); fails with 1 FILIPPA + 1 spot, 2026-11-21 |
| C-PKG-10 | The cornering lights stay within the end of the body | At most 2 mm past the end | Pass, 2026-11-21 |
| C-PKG-11 | The sloping roof leaves the electronics board at least 45 mm tall | Board height ≥ 45 mm | Pass (v3), 2026-11-21 |
| C-PKG-12 | The servo fits inside the rounded, tapered tail | Servo inside the tail's inner wall | Pass (v3), 2026-11-21 |
| C-PKG-13 | The electronics board fits the flat part of the tail | Board width ≥ 55 mm | Pass (v3), 2026-11-21 |
| C-PKG-14 | v4 only: the lidar on its side fits inside the body | Lidar top below the inner roof | Pass (v4 study), 2026-11-21 |
| C-PKG-15 | v4 only: each module's beam clears the lidar bay at full inward yaw | Inner beam edge outside the bay | Pass (v4 study), 2026-11-21 |
| C-PKG-16 | v4 only: the gimbal frames clear the lidar bay | No overlap | Pass (v4 study), 2026-11-21 |
| C-MASS-01 | Head mass with the lidar, printed parts measured from the model's STL volumes, bought parts from datasheets | ≤ 400 g | See `cad/renders/checks.txt`; ~401 g in v3, 2026-11-21 |

## Bench tests (`B-`)

### Mirror and servo

| ID | What it checks | Pass if | Status |
|---|---|---|---|
| B-MIR-01 | Step response, laser pointer on the mirror, spot on a wall | Settles in under 50 ms | – |
| B-MIR-02 | Jitter and deadband after the 4:1 linkage | Spot jitter below 0.1° of beam at rest | – |
| B-MIR-03 | Full travel | ±7.5° of mirror with no binding | – |
| B-MIR-04 | Balance: shake the assembly at EUC vibration frequencies | No visible ringing of the spot | – |
| B-MIR-05 | v4 only: each gimbal's backlash and ringing on both axes, laser on the mirror, with and without anti-backlash springs | Spot jitter below 0.1° of beam on both axes; settles in under 50 ms | – |
| B-VIB-01 | Vibration on the wheel: log the IMU's acceleration spectrum while riding over rough road, with the head mounted | Record the main frequencies and peak g, to set B-MIR-04/05 and E-VIB-01 | – |

### Optics

| ID | What it checks | Pass if | Status |
|---|---|---|---|
| B-OPT-01 | The Nichia 519A dome fits the Carclo 10734 holder | Retired 2026-11-21: the 519A is no longer used | Retired |
| B-OPT-02 | Beam clipping at the mirror and window across ±7.5° | No visible clipping at either end | – |
| B-OPT-03 | Light output (lux at a fixed distance, converted to lumens) | Within 20% of the design estimate | – |
| B-OPT-04 | Peak intensity and beam angles of each channel (lux grid on a wall at 10 m, both modes) | Spot and low beam within 30% of the design §3 beam estimate; record the real beam angles | – |
| B-OPT-05 | FILIPPA flange height above the XP-L HI board, set with printed spacers in 0.1 mm steps | Height recorded where the cutoff is sharpest on a wall at 10 m | – |
| B-OPT-06 | Cutoff orientation with the orienting rib toward the front of the housing (LEDs facing up), through the mirror | Cutoff is at the top of the beam and horizontal within ±0.5° | – |
| B-OPT-07 | Glare above the cutoff, lux on a wall at 10 m, aimed per calibration step D | ≤ 2 lux above 3.4° over the brightest point; ≥ 10 lux at the brightest point | – |
| B-OPT-08 | Toed-out low beam (4° wedges): beam width, and cutoff tilt at both ends of the mirror's travel | Width ~30° FWHM; cutoff tilt ≤ 2° | – |
| B-OPT-09 | Convex low-beam mirror (R ≈ 315 mm, reflective aluminium sheet on a printed former) against the 4° toe-out wedges, same lux grid as B-OPT-04 | Record width, peak and cutoff bow; adopt if as wide and as sharp | – |
| B-CRN-01 | Cornering lights aimed 30° out, 10° down: lux on a wall at 10 m above horizontal | ≤ 2 lux above horizontal; ~10 lux at the peak | – |
| B-CRN-02 | Cornering spreader plate temperature after 20 s at full power, then at 50% | Plate stays below 70 °C | – |

### LED drivers

| ID | What it checks | Pass if | Status |
|---|---|---|---|
| B-DRV-01 | BuckBlock dimming with 20 kHz PWM and 10 µF on DIM | Smooth and monotonic; no visible flicker; minimum level recorded | – |
| B-DRV-02 | DIM held at 0 V | LED output is zero (needed for auto-off) | – |
| B-DRV-03 | MCU unplugged with power on (safety invariant 5) | Both channels run at full current | – |
| B-DRV-04 | Power-on behaviour before firmware takes over | Flash duration recorded; owner decides whether it's acceptable | – |

### Power

| ID | What it checks | Pass if | Status |
|---|---|---|---|
| B-PWR-01 | PTC fuse in boost at about 50 °C ambient for 60 s | No trip | – |
| B-PWR-02 | Reverse polarity, and the 1N5822's temperature at 2 A | No damage; diode temperature recorded | – |
| B-PWR-03 | Overvoltage at the input | TVS protects the drivers | – |
| B-PWR-04 | Bank falling back to 12 V and 9 V | Firmware detects it and caps brightness | – |
| B-PWR-05 | USB plugged into the XIAO while the head is powered | No back-feed, nothing gets hot | – |
| B-PWR-06 | Input power in normal and boost | Within 15% of design §4 | – |

### Thermal, sleep and remote

| ID | What it checks | Pass if | Status |
|---|---|---|---|
| B-THM-01 | Heatsink rise in still air, at walking pace and at 25 km/h, with the airflow along the fins (fore-aft) | Within 25% of design §8 | – |
| B-THM-02 | NTC reading against a thermocouple | Within 3 °C | – |
| B-SLP-01 | Sleep current and wake on motion | Wakes on a nudge; sleep current recorded | – |
| B-REM-01 | DIY nRF52840 remote | Press-to-action latency ≤ 100 ms; battery life estimate recorded | – |
| B-REM-02 | Cheap BLE shutter remote | First-press-after-sleep behaviour recorded | – |
| B-LID-01 | TF02-Pro on dry and wet asphalt at a grazing angle of about 4° | Usable range and dropout rate recorded | – |

## Enclosure and mount tests (`E-`)

| ID | What it checks | Pass if | Status |
|---|---|---|---|
| E-SEAL-01 | Empty housing submerged with a tissue inside | Tissue dry | – |
| E-SEAL-02 | Repeat E-SEAL-01 after 10 hot–cold cycles | Tissue dry | – |
| E-SEAL-03 | Window fogging after cooling from hot, with the vent and desiccant fitted | No fog | – |
| E-SEAL-04 | Hose test, IPX5-style: water jet from all directions for 3 min, empty housing with tissue inside | Tissue dry | – |
| E-VIB-01 | 30 min of vibration on a crude shaker (an orbital sander under the mount works), then a 1 m drop onto grass | No loosened screw, cracked seal, shifted optic or broken joint; E-SEAL-01 still passes | – |
| E-MNT-01 | Head weight, fully assembled with the lidar | ≤ 400 g | – |
| E-MNT-02 | Pull and shake test on each mount option | Mount holds; leash catches the head if it doesn't | – |

## Ride tests (`R-`)

| ID | What it checks | Pass if | Status |
|---|---|---|---|
| R-AIM-01 | Beam position under hard braking and acceleration (camera on the wheel, logs) | Hotspot stays on the road; never rises into oncoming traffic | – |
| R-AIM-02 | Long hills, up and down | Beam follows the road within about 4 s | – |
| R-OFF-01 | Trolley mode and picking the wheel up | Beam goes off and comes back on | – |
| R-OFF-02 | Parking for 2 and 10 min | Dims, then sleeps; wakes when moved | – |
| R-THM-01 | Hour-long ride at night | Heatsink and internal temperatures stay below derating thresholds in normal mode | – |
| R-RUN-01 | Runtime on a 20 Ah bank in normal mode | ≥ 2 h | – |
| R-CRN-01 | Night ride through left and right turns and roundabouts | Inside of each turn lit; no flicker or false triggers on straights | – |
| R-LID-01 | Crests, dips, and an obstacle ahead, with the lidar fitted | Beam leads crests and dips; an obstacle never lifts it | – |
