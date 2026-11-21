# Hardware Design

All figures are design estimates until they're verified on a prototype.
The parts list with links is in [`../hardware/BOM.md`](../hardware/BOM.md).

**Firm constraints** (owner's decision, 2026-11-20). Changing one needs the owner's approval:
- Only the mirror moves. The LEDs and heatsink stay fixed.
- External power only. The head has no battery, and PD is negotiated at the bank.
- Material cost ≤ $450 per unit (raised from $350 on 2026-11-20) and head weight ≤ 350 g, both **with the optional lidar fitted**. The cost excludes the power bank, tools and leftover pack contents.
- The lidar stays optional. Everything must work without it.

## 1. The problem

- An EUC pitches nose-down when it accelerates and nose-up when it brakes. A fixed headlight swings with it.
- When braking, the beam rises into oncoming drivers' eyes. When accelerating, it drops in front of the wheel.
- Hills and crests change the ideal aim more slowly.
- The goal is to keep the beam aligned to the **road** rather than to the wheel.

## 2. Optical concept: fixed LEDs, moving mirror

```
          ┌──── finned aluminium lid = LED heatsink ───────┐
          │  [spot][ low ][ low ][spot]  (row, left→right)  │
          │   TIR  FILIPPA FILIPPA TIR   facing DOWN        │
          │            ↓ ↓ ↓                                │
  window  │     ╲  front-surface mirror @45°, pivots on     │
 ◄════════│      ╲ its long (left-right) axis ── pushrod ── servo
          └─────────────────────────────────────────────────┘
```

**Why a mirror:**
- **Angle doubling.** Tilting the mirror by θ moves the beam by 2θ. Correcting ±15° of pitch needs only ±7.5° of mirror travel.
- **Light moving part.** The mirror is about 30 g of glass, against 200–400 g for a whole lamp head. That means faster response, less servo power and less sensitivity to vibration.
- **Fixed LEDs.** The LEDs stay bolted to the heatsink. There are no flexing wires and no moving thermal joints.
- **Costs:** about 5–8% of the light is lost at the mirror, and the fold makes the housing slightly larger.

**Mirror geometry:**
- The four optics sit in a row along the pivot axis: two 20 mm spot optics and two 33 mm FILIPPA low-beam optics, about 112 mm in all. The mirror is long and thin: about **115 × 55 mm**, about 30 g in 1.9 mm glass (1.1 mm glass would bring it to about 17 g).
- The mirror must be **flat**: any curvature blurs the low-beam cutoff.
- It rotates about its long axis, which gives it a very small moment of inertia.
- Use a **front-surface** mirror (enhanced aluminium, R > 95% across the visible range). A normal back-silvered mirror produces ghost beams and absorbs light.
- The pivot passes through the mirror's **centre of mass**. Bumps and acceleration then create no torque, and the servo only holds position.
- **Pivot:** 2× MR63ZZ bearings on a 3 mm stainless shaft, pressed into printed bosses with CA glue.
- **Linkage:** a pushrod at about 4:1. The servo sweeps ±30° for ±7.5° of mirror, which gives 4× the resolution and hides servo backlash. Response stays well under 50 ms.
- **Window:** about 60 mm tall so the 33 mm low beam can sweep ±15° without clipping.

**Limitation: pitch only.** A single fold mirror corrects pitch but not roll. In a turn, the low-beam cutoff tilts with the lean, so on one side it rises by the lateral angle × tan(lean). Motorcycle low beams have the same limitation. A two-axis mirror could add cornering (steering on yaw rate) later.

**Alternative considered:** moving an aspheric lens sideways in front of a fixed LED (a decentred lens). It avoids the mirror losses but needs larger travel and distorts TIR beams. Rejected for v1.

## 3. Light engine

| Channel | LEDs | Optic | Driver |
|---|---|---|---|
| Spot / high beam | 2× Cree XP-L HI (3535), 5000–6500 K, on 20 mm copper DTP boards | Carclo 10003 narrow spot (~8–12°) in Carclo 10734 holders | BuckBlock A009-D-V-2100 |
| Low beam (the "flood" channel in the firmware) | 2× Cree XP-L HI (3535), about 5000 K, on 20 mm copper DTP boards | **LEDiL FILIPPA-STVZO** (C18612), cutoff beam 22° × 13° | BuckBlock A009-D-V-2100 |

- **Low-beam decision (owner, 2026-11-21):** two FILIPPA-STVZO optics replace the Nichia 519A + Carclo 10003-L25 elliptical flood, which had no cutoff and glared above horizontal. All four LEDs are now XP-L HI. The high-CRI 519A is dropped because it isn't on LEDiL's compatible list.
- **FILIPPA-STVZO** (LEDiL datasheet, simulated): Ø 32.9 mm, 18.5 mm tall, 6.3 g, PMMA, one LED per optic. With an XP-L HI: 7 cd/lm peak, FWHM 22° × 13°, FWTM 32° × 33°, 90% efficient. It mounts by its 1.5 mm flange, with no holder.
- **Cutoff orientation.** The datasheet's beam sketch puts the flat cutoff edge on the same side as the flange's 3.1 mm **orienting rib**. The 45° fold sends light that leaves the optic toward the window downward, so the **rib must point to the back of the housing**, away from the window. The optic plate has a slot for the rib so the optic can't rotate: any rotation tilts the cutoff by the same angle. Confirm the orientation on the bench (B-OPT-06).
- **Focus height.** The datasheet gives the flange height above the PCB only for Luxeon Altilon (10.0 mm) and Osram Oslon (11 mm), not for the XP-L HI. Find it on the bench with printed spacers in 0.1 mm steps, choosing the sharpest cutoff (B-OPT-05).
- **Brighter option to test.** LEDiL lists higher peaks for smaller or rectangular emitters (XP-LR 9.6, XP-GR 10.4, SFT-12R 11.1, Oslon Black Flat 12.6 cd/lm), usually with a sharper cutoff, but they emit fewer lumens than the XP-L HI.
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
| Normal (1.5 A) | ~2400 lm | ~1800 lm |
| Boost (2.1 A) | ~3100 lm | ~2400 lm |

About 600 lm per XP-L HI in normal mode and 780 lm in boost. Out the front assumes the optic (0.85 for the Carclo TIR, 0.90 for the FILIPPA) × mirror (0.95) × window (0.92).

**Beam estimate** (to be measured in B-OPT-04):

| | Spot (2× XP-L HI, Carclo 10003) | Low beam (2× XP-L HI, FILIPPA-STVZO) |
|---|---|---|
| Beam angle | ~8–12° round | 22° wide × 13° tall, sharp top edge |
| Peak intensity, normal (1.5 A) | ~25,000 cd (18–40k) | ~7,300 cd (~73 lux at 10 m) |
| Peak intensity, boost (2.1 A) | ~33,000 cd | ~9,500 cd (~95 lux at 10 m) |
| ANSI throw (to 0.25 lux), normal | ~320 m (270–400 m) | ~170 m |
| ANSI throw, boost | ~360 m | ~195 m |
| Distance to 1 lux, normal | ~160 m | ~85 m |
| Beam width at 30 m | ~5 m | ~12 m |

How it's estimated:
- **Spot:** each beam is treated as a smooth peak with the stated beam angle, about 21 cd per emitted lumen for a 10° spot (15 at 12°, 33 at 8°) after about 0.74 optical efficiency. The biggest uncertainty is the spot's real beam angle with the XP-L HI; Carclo's photometric files would narrow it.
- **Low beam:** LEDiL's 7 cd/lm for the XP-L HI, × 0.95 mirror × 0.92 window, × 600 lm per LED, × 2 optics.
- Two LEDs aimed the same way add. ANSI throw = 2 × √(peak cd).

For scale, good StVZO bicycle lights are about 70–150 lux at 10 m. A car's low beam peaks at roughly 15–20k cd and its high beam at roughly 40–100k cd. The spot has no cutoff by design: it's a high beam, like a car's, for use without oncoming traffic.

**Cutoff and aim.**
- Target (StVZO, from secondary sources): no more than 2 lux at 10 m above about 3.4° over the brightest point, and at least 10 lux at 10 m at the brightest point. Confirm against the official text before claiming compliance.
- Aim the cutoff about **1.2° below horizontal**. With the head at about 0.8 m, it meets the road about 38 m ahead. On a wall 10 m away, the cutoff sits about 20 cm below the lamp's height (calibration step D in `firmware-spec.md`).
- The mirror tilts the beam about the left–right axis, so levelling moves the cutoff up and down without tilting it. Self-levelling also matters here: ECE car rules require automatic levelling for powerful low beams.

## 4. Power: external USB-C PD bank

```
power bank ──USB-C──► PD trigger cable (fixed 15 V, e-marked) ──► IP68 2-pin ──► head
```

### Consumption (estimates, to be measured in B-PWR-06 and R-RUN-01)

| Mode | Input power | Input current at 15 V | Runtime (~50 Wh) |
|---|---|---|---|
| Normal (both channels 1.5 A) | ~21 W | ~1.4 A | ~2.4 h |
| Boost (both channels 2.1 A, at most 60 s at a time) | ~30 W | ~2.0 A | ~1.7 h |
| Typical (low beam normal, spot 50%) | ~16 W | ~1.1 A | ~3 h |
| Optional lidar | +~1 W | +~0.07 A | about 5% less |

Where it goes in normal mode:
- **LEDs:** 2 channels × ~6.2 V × 1.5 A ≈ 18.6 W. With the BuckBlocks at about 90% efficiency, that's ~20.5 W from the input.
- **Electronics:** MCU, IMU, ring LED and a servo that is mostly holding position use well under 1 W. The servo draws brief peaks of up to ~1 A at 5 V, which the 470 µF capacitor on the 5 V rail absorbs.
- **Heat:** about 12 W, shed by the aluminium lid (§8).
- **Parked:** 20% brightness after 2 min still; near zero in sleep after 10 min.

Cold weather cuts usable capacity by about 20%, so plan on about 2 h in normal mode in winter.

### Supply

- **PD at the dry end.** The PD negotiation happens at the bank, inside a pouch. Only plain DC reaches the head. Don't run exposed USB-C pins at 15–20 V in the rain, because they corrode quickly.
- **Bank:** 20,000 mAh that supplies **15 V at 2 A or more** on one USB-C port. **15 V at 3 A (45 W or more) is recommended** for margin in boost. Examples: Baseus Adaman 65 W, JSAUX PB6501, Anker A1383.
- **Usable energy:** about 50 Wh at 15 V.
- **Cable:** a USB-C PD trigger cable fixed at 15 V and e-marked, spliced to an IP68 2-pin connector at the head.
- **Head input protection:**
  - PTC fuse (2.5 A hold). Marginal in boost when hot; see §10.
  - 1N5822 Schottky for reverse polarity. Dissipates ~1 W at 2 A; see §10.
  - P6KE27A TVS diode.
  - 220 µF bulk capacitor.
- **Voltage check:** firmware reads the input voltage. If the bank falls back to 12 V or 9 V, it limits brightness (firmware-spec §6). Below 10 V the BuckBlocks are out of their input range.
- **Optional:** an IP67 magnetic breakaway connector, so the cable separates in a fall.

**Power bank gotchas:**
1. Many banks briefly cut every port when you plug something into another port. **Never plug or unplug anything into the bank while riding.**
2. Banks turn off at low current. After the head goes to sleep, press the bank's button to start the next ride, or pick a bank with a low-current mode.

### Powering from the wheel (researched 2026-11-21)

**Wheel USB ports can't run the head.** No EUC was found that is documented to supply 15 V at 2 A (30 W) from its USB port.
- Wheel specs and manuals list USB-A and USB-C ports "for power output" or "phone charging" without a wattage (for example, the Inmotion V13).
- Many wheels have no USB port at all (for example, one review lists none for the KingSong S22).
- Forum reports put wheel USB ports at about 5 V and 1–2 A (5–10 W), with no mention of 15 V PD. That's a third or less of what the head needs in normal mode.
- A wheel would qualify only if its USB-C port is measured with a USB power meter supplying 15 V at 2 A or more, continuously.

**Other ways to use the wheel's power.** Both would break the "external power only" constraint, so they need the owner's decision:
- **The wheel's 12 V light rail.** Some Leaperkim (Veteran) and Begode wheels have one; stock Begode lights draw about 20 W from it. The head would need about 1.75 A at 12 V in normal mode, more than a stock light, and no rated current for these rails was found. 12 V is inside the BuckBlock's input range, but firmware-spec §6 treats 10–13 V as a failing bank and caps brightness, so that rule would need to change.
- **The main battery** (about 84–151 V, depending on the wheel) through a DC-DC converter. This means opening the wheel and working with high voltage, and may void the warranty.

Sources: [EUC forum: charging a laptop from a wheel](https://forum.electricunicycle.org/topic/21475-using-an-euc-to-charge-a-laptop/), [Inmotion V13 manual](https://device.report/manual/14117718), [KingSong S22 review](https://everythingelectricunicycle.com/kingsong-s22-review-best-suspension-euc-electric-unicycle/), [EUC forum: Sherman 12 V port USB install](https://forum.electricunicycle.org/topic/22791-veteran-sherman-dual-usb-port12v-voltmeter-install/), [EUC forum: Begode front light upgrade](https://forum.electricunicycle.org/topic/30127-upgrading-the-masters-front-light/).

## 5. Housing: 3D-printed ASA with a metal lid

- **Material: ASA.** It resists UV and its glass transition is about 100 °C.
  - PETG softens at about 75–80 °C and creeps.
  - Don't use PLA.
- **Thermal path:** the LEDs screw onto a stock finned aluminium heatsink (about 120×60×20 mm, long enough for the 112 mm optic row) that forms the **lid**. Heat never passes through the plastic.
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

- [x] ~~Does the 519A dome fit the Carclo 10734 holder?~~ No longer needed: the 519A was dropped for the FILIPPA low beam (2026-11-21).
- [ ] BuckBlock analog dimming using 20 kHz PWM + RC: linearity, minimum level.
- [ ] Mirror vibration and ringing at EUC vibration frequencies. Is the balance good enough?
- [ ] Hobby servo deadband and jitter after the 4:1 linkage. Is a gimbal BLDC needed (GBM2804 + SimpleFOC + AS5600)?
- [ ] Does the ASA housing stay sealed over thermal cycles? Long-term creep at the screw bosses?
- [ ] Real TF02-Pro range and dropout rate on wet and dry asphalt at about 4° grazing angle.
- [ ] Head weight on VHB mounts. Is the leash mandatory?
- [ ] Power-on flash: DIM floats until the firmware drives the 2N3904s, so both channels start at 2.1 A. Base pull-ups would stop it, but they also turn the light off if the MCU dies, which loses the full-on failsafe. Accept the flash, or find a way to keep both (e.g. an RC that holds the transistor on only for the first second)?
- [ ] Does the BuckBlock reach zero output with DIM at 0 V? The trolley-mode and crash "beam off" states assume it does.
- [ ] PTC nuisance trips in boost: ~2 A input against an RXEF250 whose 2.5 A hold rating falls to roughly 2 A at 50 °C inside the head. Move to an RXEF300?
- [ ] The 1N5822 dissipates ~1 W at 2 A inside the sealed head. Replace it with a P-MOSFET reverse-polarity stage?
- [ ] P6KE27A clamps at ~37.5 V, above the BuckBlock's 32 V maximum. Low risk with a 20 V bank, but a lower-clamp TVS would cover it.
- [x] Cost over the limit: about $290 core + $98 lidar ≈ $388, against a $350 ceiling. Resolved 2026-11-20: the owner raised the limit to $450, so no parts change.
- [x] **The flood has no cutoff.** Resolved 2026-11-21: the owner chose two LEDiL FILIPPA-STVZO cutoff optics with XP-L HI as the low beam (§3). A shield or masked mirror edge was rejected because a TIR beam isn't an image, so blocking part of it only dims it without making a sharp edge.
- [ ] **Head weight may exceed 350 g with the lidar.** The larger mirror (+~15 g), longer heatsink (+~18 g), larger housing (+~8 g) and FILIPPA optics (+~6 g) add roughly 47 g, taking the estimate from ~280 g to ~327 g, or ~377 g with the lidar (about 50 g). Options: 1.1 mm mirror glass (−13 g), a lighter heatsink, thinner walls away from the seals. (2026-11-21)
- [ ] FILIPPA with XP-L HI: focus height, cutoff sharpness and cutoff orientation are not in LEDiL's data. Bench tests B-OPT-05 and B-OPT-06.
- [ ] Larger mirror (115 × 55 mm, about 5× the moment of inertia): does the servo still settle in under 50 ms (B-MIR-01)?
