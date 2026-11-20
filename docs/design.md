# Hardware Design

All figures are design estimates until they're verified on a prototype.
The parts list with links is in [`../hardware/BOM.md`](../hardware/BOM.md).

## 1. The problem

- An EUC pitches nose-down when it accelerates and nose-up when it brakes. A fixed headlight swings with it.
- When braking, the beam rises into oncoming drivers' eyes. When accelerating, it drops in front of the wheel.
- Hills and crests change the ideal aim more slowly.
- The goal is to keep the beam aligned to the **road** rather than to the wheel.

## 2. Optical concept: fixed LEDs, moving mirror

```
          ┌──── finned die-cast lid = LED heatsink ────────┐
          │  [LED][LED][LED][LED]  (row, left→right)        │
          │   TIR  TIR  TIR  TIR   facing DOWN              │
          │            ↓ ↓ ↓                                │
  window  │     ╲  front-surface mirror @45°, pivots on     │
 ◄════════│      ╲ its long (left-right) axis ── pushrod ── servo
          └─────────────────────────────────────────────────┘
```

**Why a mirror:**
- **Angle doubling.** Tilting the mirror by θ moves the beam by 2θ. Correcting ±15° of pitch needs only ±7.5° of mirror travel.
- **Light moving part.** The mirror is about 15 g of glass, against 200–400 g for a whole lamp head. That means faster response, less servo power and less sensitivity to vibration.
- **Fixed LEDs.** The LEDs stay bolted to the heatsink. There are no flexing wires and no moving thermal joints.
- **Costs:** about 5–8% of the light is lost at the mirror, and the fold makes the housing slightly larger.

**Mirror geometry:**
- The four 20 mm optics sit in a row along the pivot axis, so the mirror is long and thin: about 90 × 35 mm.
- It rotates about its long axis, which gives it a very small moment of inertia.
- Use a **front-surface** mirror (enhanced aluminium, R > 95% across the visible range). A normal back-silvered mirror produces ghost beams and absorbs light.
- The pivot passes through the mirror's **centre of mass**. Bumps and acceleration then create no torque, and the servo only holds position.
- **Pivot:** 2× MR63ZZ bearings on a 3 mm stainless shaft, pressed into printed bosses with CA glue.
- **Linkage:** a pushrod at about 4:1. The servo sweeps ±30° for ±7.5° of mirror, which gives 4× the resolution and hides servo backlash. Response stays well under 50 ms.
- **Window:** about 45 mm tall so the beam can sweep ±15° without clipping.

**Limitation: pitch only.** A single fold mirror corrects pitch but not roll. In a turn, the elliptical flood beam tilts with the lean. A two-axis mirror could add cornering (steering on yaw rate) later.

**Alternative considered:** moving an aspheric lens sideways in front of a fixed LED (a decentred lens). It avoids the mirror losses but needs larger travel and distorts TIR beams. Rejected for v1.

## 3. Light engine

| Channel | LEDs | Optic | Driver |
|---|---|---|---|
| Spot / high | 2× Cree XP-L HI (3535) on 20 mm copper DTP boards | Carclo 10003 narrow spot (~8–12°) | BuckBlock A009-D-V-2100 |
| Flood / low | 2× Nichia 519A (3535, high CRI) on 20 mm copper DTP boards | Carclo 10003-L25 elliptical (~44×13°), wide axis horizontal | BuckBlock A009-D-V-2100 |

- All four use **Carclo 10734** holders (XP footprint).
  - The SFT-40 was dropped because it's a 5050 package and doesn't fit these holders.
- **Each channel:** 2 LEDs in series (about 6.2 V) on its own BuckBlock driver.
  - Drivers: 10–32 V input, 2.1 A, buck topology, dimming input.
  - The 15 V supply leaves plenty of headroom.
- **Current limits set by firmware:**
  - ~1.5 A normal.
  - 2.1 A boost, limited in time and by temperature.
- **Dimming:**
  - The BuckBlock datasheet shows a 2N3904 interface for PWM on its 0–10 V input at 200 Hz, which would flicker visibly on a moving vehicle.
  - Instead, drive the 2N3904 at about 20 kHz with a 10 µF capacitor from DIM to ground, which gives smooth analog dimming. **Verify this on the bench.**
- **DIM failsafe:** with the DIM input left open, the BuckBlock runs at its full rated current. If the MCU dies, the light stays **on**. This is intentional, but thermal derating is lost in that state.
- **The Mean Well LDD-1500H** from the first draft is discontinued.

**Output estimate:**

| Mode | Emitted | Out the front |
|---|---|---|
| Normal (1.5 A) | ~2000 lm | ~1500 lm |
| Boost (2.1 A) | ~2700 lm | ~2000 lm |

The out-the-front figures assume about 0.75 total efficiency (TIR × mirror × window).

## 4. Power: external USB-C PD bank

```
power bank ──USB-C──► PD trigger cable (fixed 15 V, e-marked) ──► IP68 2-pin ──► head
```

- **PD at the dry end.** The PD negotiation happens at the bank, inside a pouch. Only plain DC reaches the head. Don't run exposed USB-C pins at 15–20 V in the rain, because they corrode quickly.
- **Bank:** 20,000 mAh with 15 V ≥ 2 A on USB-C, for example Baseus Adaman 65 W, JSAUX PB6501 or Anker A1383.
- **Usable energy:** about 50 Wh at 15 V.
- **Head input protection:**
  - PTC fuse (2.5 A hold).
  - 1N5822 Schottky for reverse polarity.
  - P6KE27A TVS diode.
  - 220 µF bulk capacitor.
- **Voltage check:** firmware reads the input voltage. If the bank only supplies 9 V, it limits brightness, because 9 V is below the BuckBlock's input range.
- **Optional:** an IP67 magnetic breakaway connector, so the cable separates in a fall.

| Mode | Input power | Runtime (~50 Wh) |
|---|---|---|
| Normal (both channels 1.5 A) | ~21 W | ~2.4 h |
| Boost (both channels 2.1 A) | ~30 W | ~1.7 h |
| Typical (flood normal, spot 50%) | ~16 W | ~3 h |

Cold weather cuts usable capacity by about 20%.

**Power bank gotchas:**
1. Many banks briefly cut every port when you plug something into another port. **Never plug or unplug anything into the bank while riding.**
2. Banks turn off at low current. After the head goes to sleep, press the bank's button to start the next ride, or pick a bank with a low-current mode.

## 5. Housing: 3D-printed ASA with a metal lid

- **Material: ASA.** It resists UV and its glass transition is about 100 °C.
  - PETG softens at about 75–80 °C and creeps.
  - Don't use PLA.
- **Thermal path:** the LEDs screw onto a stock finned aluminium heatsink (about 100×60×20 mm) that forms the **lid**. Heat never passes through the plastic.
- **Print settings:**
  - 4–5 perimeters (≥ 2 mm walls), 0.2 mm layers.
  - Hotter nozzle for layer bonding, flow at about 103%.
  - Print the sealing face flat on the bed.
- **Surface sealing:** acetone-vapour smoothing, or XTC-3D epoxy brushed inside and out.
- **Lid seal:** 2 mm silicone O-ring cord in a printed groove. M3 screws into CNC Kitchen heat-set inserts about every 30 mm.
- **Window:**
  - 2–3 mm polycarbonate or tempered glass in a gasketed printed bezel.
  - Treat the inside with anti-fog.
  - If you bond it, use **neutral-cure / sensor-safe** RTV only. Acetoxy silicone releases acetic acid, which tarnishes the mirror and LED phosphor.
- **Vent:** an Amphenol LTW M8 ePTFE pressure vent plus desiccant. Without it, warm-up/cool-down cycles pull moisture past the seals and fog the window.
- **Penetrations:**
  - M12 IP68 cable gland, or a panel-mount IP68 connector.
  - Adafruit 16 mm rugged button with an LED ring (comes with a gasket).
- **Interior:** printed matte black to kill stray light. A lighter colour outside reduces sun heating.
- **Leak test:** submerge the empty housing with a tissue inside before any electronics go in.

**Printed parts:**
- body
- front bezel
- mirror cradle
- servo bracket + lever
- optic plate
- electronics tray
- mount boss
- lidar bracket (optional)
- remote case

## 6. Mounting

- **Interface:** a captive 1/4"-20 brass insert in a printed boss. This is the most universal standard, and it takes GoPro adaptors.
- **Base options:**
  1. **Trolley-handle tube clamp.** The strongest option.
  2. **GoPro curved VHB bases** on the shell, above or below the stock light.
  3. Use two bases plus a leash.
- **Aim doesn't need to be precise.** Calibration learns the mount orientation. The light only needs to face forward within about 10°.

## 7. Electronics

**MCU: Seeed XIAO ESP32-S3**
- Dual-core 240 MHz with a hardware floating-point unit, BLE 5, 21 × 17.8 mm.
- Chosen over the C3: about $2 more, but it has a floating-point unit and headroom for lidar fusion and the BLE host.

**IMU: Adafruit LSM6DSO32**
- 6-axis, ±32 g, so crash detection doesn't saturate.
- Two interrupt pins, plus an on-chip temperature sensor used for internal temperature.

**Pin map:**

| Pin | GPIO | Function |
|---|---|---|
| D0 | 1 | Input voltage sense (120 k / 15 k divider; 20 V → ~2.2 V) |
| D1 | 2 | Heatsink NTC (10 k NTC + 10 k pull-up) |
| D2 | 3 | IMU INT1: wake-on-motion |
| D3 | 4 | Spare |
| D4 | 5 | I²C SDA (IMU + lidar) |
| D5 | 6 | I²C SCL |
| D6 | 43 | Button ring LED (6 V LED from 5 V via 2N3904) |
| D7 | 44 | Button (to GND, internal pull-up) |
| D8 | 7 | Spot BuckBlock DIM (2N3904 + 10 µF) |
| D9 | 8 | Flood BuckBlock DIM (2N3904 + 10 µF) |
| D10 | 9 | Servo PWM |

**5 V rail:**
- Pololu D36V28F5 feeds the servo and the XIAO's 5 V pin through a 1N5817.
- The diode makes it safe to plug in USB for flashing while the head is powered.
- 470 µF capacitor on the servo rail.

**Build:** protoboard for v1, custom PCB later.

## 8. Thermal

- **Heat:** about 12 W at normal output, roughly 65% of LED electrical power.
- **Heatsink rise:**
  - About 2.5 K/W in still air, so about 30 K above ambient when stationary.
  - About 0.8 K/W at 25 km/h, so about 10 K above ambient.
- **Firmware derating** (thresholds in `firmware-spec.md`):
  - Spot dims before flood.
  - There's always a minimum brightness while moving.
- **Internal temperature** is capped to protect the ASA and the servo.

## 9. Optional: road-slope lidar (look-ahead)

**Sensor: Benewake TF02-Pro**
- IP65, 0.1–13.5 m at 10% reflectivity, 100 Hz, I²C/UART, 5–12 V.
- Mounted on the **body** (never the mirror) in its own gasketed front cut-out, aimed about 3–5° below the beam axis.
- The TFmini Plus was rejected: only about 4 m range at 10% reflectivity.
- Asphalt is dark in infrared and the ray hits it at a shallow angle, so expect real range below the spec. Start aiming about 8 m ahead and tune.

**Geometry:**
- The sensor sits at height `h` above the road (learned during level calibration as `h = d·sin β`).
- The IMU gives the ray's true depression angle `β`, and the lidar gives the range `d`.
- Road height ahead: `z = h − d·sin β`, at a distance `x = d·cos β`.
- Grade ahead: `φ = atan2(z, x)`.

**What it adds:**
- The IMU road-follow filter already handles long hills.
- The lidar adds about 0.5–1 s of look-ahead at crests and dips (10 m at 40 km/h ≈ 0.9 s):
  - It lifts the beam before a dip's up-slope.
  - It lowers the beam before a crest.

**Rules** (full detail in `firmware-spec.md`):
- An obstacle must never lift the beam.
- A missing return means a small downward bias, then a fall back to the IMU estimate.
- The lidar estimate is always blended with the IMU estimate, never used alone.

**Power and wiring:** about 1 W at 5 V. It shares the I²C bus after a one-time UART command switches it to I²C mode.

## 10. Open questions and risks

- [ ] Does the 519A dome fit the Carclo 10734 holder? (It's specified for XP-G.)
- [ ] BuckBlock analog dimming using 20 kHz PWM + RC: linearity, minimum level.
- [ ] Mirror vibration and ringing at EUC vibration frequencies. Is the balance good enough?
- [ ] Hobby servo deadband and jitter after the 4:1 linkage. Is a gimbal BLDC needed (GBM2804 + SimpleFOC + AS5600)?
- [ ] Does the ASA housing stay sealed over thermal cycles? Long-term creep at the screw bosses?
- [ ] Real TF02-Pro range and dropout rate on wet and dry asphalt at about 4° grazing angle.
- [ ] Head weight on VHB mounts. Is the leash mandatory?
