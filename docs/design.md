# Hardware Design

All figures are design estimates until they're verified on a prototype.
The parts list with links is in [`../hardware/BOM.md`](../hardware/BOM.md).

**Layout: v4 adopted (owner's decision, 2026-11-21).** Two mirror modules, each steering one FILIPPA low beam and one spot on a 2-axis gimbal (pitch for levelling, yaw for turns), four 5 g servos, the modules side by side around a centre post, one clear thermoformed piece wrapping the front and both sides, and a small TFS20-L lidar low in the nose, under the beams (since the owner's render review, 2026-11-21: body about 151 mm wide, owner's target 150 mm). No cornering lights, toe-out wedges or brow. The v4 layout, its checks and its turning behaviour are in §5 ("v4"). Earlier sections still describe v3's single mirror, cornering lights and toe-out where marked *(v3)*; they're kept as the record of how the design got here.

**Firm constraints** (owner's decision, 2026-11-20). Changing one needs the owner's approval:
- Only the mirrors move. The LEDs and heatsinks stay fixed.
- External power only. The head has no battery, and PD is negotiated at the bank.
- Material cost ≤ $450 per unit (raised from $350 on 2026-11-20) and head weight ≤ 400 g (raised from 350 g on 2026-11-21), both **with the optional lidar fitted**. The cost excludes the power bank, tools and leftover pack contents.
- The lidar stays optional. Everything must work without it.

## 1. The problem

- An EUC pitches nose-down when it accelerates and nose-up when it brakes. A fixed headlight swings with it.
- When braking, the beam rises into oncoming drivers' eyes. When accelerating, it drops in front of the wheel.
- Hills and crests change the ideal aim more slowly.
- The goal is to keep the beam aligned to the **road** rather than to the wheel.

## 2. Optical concept: fixed LEDs, moving mirror

```
          ┌──── printed ASA cover (lidar pocket on top, optional) ──┐
  window  │      ╱  front-surface mirror @45°, pivots on           │
 ◄════════│     ╱   its long (left-right) axis ── pushrod ── servo  │ electronics
          │            ↑ ↑ ↑                                       │ (back slot)
          │   TIR  FILIPPA FILIPPA TIR   facing UP                 │
          │  [spot][ low ][ low ][spot]  (row, left→right)         │
          └──── aluminium heatsink = floor, fins below, fore-aft ──┘
```

**Layout v2 (owner's requirements, 2026-11-21):** the heatsink sits at the **bottom** of the head, and its **fins run fore-aft**, in the direction of travel, so riding airflow passes between them. A heatsink on top with fins across the airflow (v1) cooled poorly. The LEDs face up into the mirror, which folds the beam forward. The **attachment point is on the back or the bottom, never the top**; v2 puts it on the back because the bottom is the heatsink. The exterior is **rounded**, for safety (nothing sharp in a fall or against a leg) and for looks: the model uses an 8 mm radius on every body edge, rounded window and bezel corners, a rounded lidar pocket and rounded fin ends.

**Why a mirror:**
- **Angle doubling.** Tilting the mirror by θ moves the beam by 2θ. Correcting ±15° of pitch needs only ±7.5° of mirror travel.
- **Light moving part.** The mirror is about 17 g of glass, against 200–400 g for a whole lamp head. That means faster response, less servo power and less sensitivity to vibration.
- **Fixed LEDs.** The LEDs stay bolted to the heatsink. There are no flexing wires and no moving thermal joints.
- **Costs:** about 5–8% of the light is lost at the mirror, and the fold makes the housing slightly larger.

**Mirror geometry:**
- The four optics sit in a row along the pivot axis: two 20 mm spot optics and two 33 mm FILIPPA low-beam optics, about 112 mm in all. The mirror is long and thin: about **114 × 55 mm**, about 17 g in **1.1 mm** front-surface glass.
- The mirror must be **flat**: any curvature blurs the low-beam cutoff.
- **Why it's this size (checked 2026-11-21):** its length is the optic row (two 33 mm FILIPPA and two 20 mm spots, ~112 mm). Its width is the 33 mm low-beam column spread across a mirror tilted to 52.5° at full travel: 33 / cos 52.5° ≈ 54 mm. Alternatives looked at:
  - A 2 × 2 optic layout gives a mirror of the same area (~70 × 90 mm), with ~2.7× the moment of inertia and a window ~28 mm taller, because the two rows reflect at different heights. No gain.
  - Limiting steering to ±10° of beam (±5° of mirror) would trim ~3 mm of width and a few millimetres of window and body. Only worth it if ride logs show the pitch stays within ±10°.
  - Cutting the mirror narrower at the spot ends (20 mm columns) saves ~3 g of glass but complicates the cradle.
  - The real FILIPPA output spreads a little between the optic and the mirror, so the mirror may need to be slightly larger, not smaller. B-OPT-02 checks it.
- It rotates about its long axis, which gives it a very small moment of inertia.
- Use a **front-surface** mirror (enhanced aluminium, R > 95% across the visible range). A normal back-silvered mirror produces ghost beams and absorbs light.
- The pivot passes through the mirror's **centre of mass**. Bumps and acceleration then create no torque, and the servo only holds position.
- **Servo:** a 5 g-class digital micro servo (lean package); the 12 g EMAX ES08MD II is the fallback. The packaging model keeps the larger servo's envelope.
- **Pivot:** 2× MR63ZZ bearings on a 3 mm stainless shaft, pressed into printed bosses with CA glue.
- **Linkage:** a pushrod at about 4:1. The servo sweeps ±30° for ±7.5° of mirror, which gives 4× the resolution and hides servo backlash. Response stays well under 50 ms.
- **Window:** about 124 × 61 mm, 2 mm polycarbonate, so the 33 mm low beam can sweep ±15° without clipping.

**Limitation: pitch only** *(v3; v4's yaw axis and per-mirror pitch answer it, §5)*. A single fold mirror corrects pitch but not roll. In a turn, the low-beam cutoff tilts with the lean: the side on the inside of the turn drops toward the road, shortening reach exactly where the rider needs to look. Motorcycle low beams have the same limitation. The answer here (owner's decision, 2026-11-21) is a wider low beam plus IMU-switched cornering lights (§3), not a second mirror axis.

**How cars and motorcycles do it (researched 2026-11-21):**
- **Cars: automatic levelling.** UN ECE R48 requires automatic headlamp levelling when a light source exceeds 2000 lm, which this head does (~2400 lm emitted). Usually a stepper motor tilts the **whole lighting module** inside the headlamp, driven by a lighting ECU from suspension ride-height sensors. "Dynamic" systems react within fractions of a second to braking and acceleration; "semi-static" ones only correct for load. One research system computes pitch from vehicle acceleration instead of height sensors, which is close to what this head does with its IMU.
- **Cars: matrix and pixel lights.** Matrix LED, DMD (Audi's 1.3 million micromirrors) and micro-LED arrays (Marelli h-Digi, Porsche HD Matrix with 16,384 pixels) switch segments to carve oncoming traffic out of the high beam. They shape the beam electronically, but the sources found don't show them replacing mechanical levelling. The parts aren't sold to hobbyists.
- **Motorcycles.** Yamaha's Tracer 9 GT+ uses its 6-axis IMU to light extra matrix segments when the bike leans past about 7°. BMW has patented a gimballed headlight that counters pitch and lean from the IMU. Aftermarket "adaptive" lights add lean-activated LEDs.
- **What this means here:** moving a light mirror instead of the whole module is unusual but keeps the LEDs and heat path fixed (a firm constraint). The motorcycle approach suggests a cheap answer to the pitch-only limitation: one or two small fixed LEDs aimed into each side of a corner, switched on by the IMU's roll angle, with no extra moving parts. That's a possible later addition.
- Sources: [Hella: headlamp levelling](https://www.hella.com/techworld/us/technical/automotive-lighting/headlamp-levelling-system/), [Valeo: automatic levelling](https://www.valeoservice.com/en-com/passenger-car/car-lighting-headlamps-rear-lamps-fog-lamps/car-automatic-headlamps-levelling-device), [UNECE GRE-83-03](https://unece.org/fileadmin/DAM/trans/doc/2020/wp29gre/GRE-83-03e.pdf), [levelling from acceleration (paper)](https://www.researchgate.net/publication/365289462_An_Automatic_Headlamp_Leveling_System_Based_on_the_Vehicle_Acceleration_Information), [Audi digital matrix](https://www.audi-mediacenter.com/en/the-new-audi-q8-e-tron-15069/new-functions-digital-matrix-led-headlights-15081), [Marelli h-Digi microLED](https://www.marelli.com/en/news/marelli-launches-h-digi-microled.html), [Porsche HD Matrix](https://newsroom.porsche.com/dam/jcr:e403130d-8889-4a47-a745-24cacf547762/PM_HD%20Matrix%20LED%20headlights.pdf), [Yamaha Tracer 9 GT+](https://www.gearpatrol.com/motorcycles/yamaha-tracer-9-gt-plus-headlights/), [BMW gimbal patent](https://www.visordown.com/news/industry/bmw-developing-curious-%E2%80%98gimble%E2%80%99-headlight). Secondary sources; check the current R48 text before relying on the 2000 lm figure.

**Other alternatives (2026-11-21):** a convex low-beam mirror, crossing beams, two 2-axis mirrors, a masked mirror and an LCD mask are compared in [`options-study.md`](options-study.md). Recommendation: keep this design for v1, bench-test the convex mirror against the toe-out wedges, and plan two 2-axis mirrors as v2.

**Alternative considered:** moving an aspheric lens sideways in front of a fixed LED (a decentred lens). It avoids the mirror losses but needs larger travel and distorts TIR beams. Rejected for v1.

## 3. Light engine

| Channel | LEDs | Optic | Driver |
|---|---|---|---|
| Spot / high beam | 2× Cree XP-L HI (3535), 5000–6500 K, on 20 mm copper DTP boards | Carclo 10003 narrow spot (~8–12°) in Carclo 10734 holders | BuckBlock A009-D-V-2100 |
| Low beam (the "flood" channel in the firmware) | 2× Cree XP-L HI (3535), about 5000 K, on 20 mm copper DTP boards | **LEDiL FILIPPA-STVZO** (C18612), cutoff beam 22° × 13° | BuckBlock A009-D-V-2100 |

- **Low-beam decision (owner, 2026-11-21):** two FILIPPA-STVZO optics replace the Nichia 519A + Carclo 10003-L25 elliptical flood, which had no cutoff and glared above horizontal. All four LEDs are now XP-L HI. The high-CRI 519A is dropped because it isn't on LEDiL's compatible list.
- **FILIPPA-STVZO** (LEDiL datasheet, simulated): Ø 32.9 mm, 18.5 mm tall, 6.3 g, PMMA, one LED per optic. With an XP-L HI: 7 cd/lm peak, FWHM 22° × 13°, FWTM 32° × 33°, 90% efficient. It mounts by its 1.5 mm flange, with no holder.
- **Cutoff orientation.** The datasheet's beam sketch puts the flat cutoff edge on the same side as the flange's 3.1 mm **orienting rib**. With the LEDs facing up (layout v2), the 45° fold sends light that leaves the optic toward the window upward, so the **rib must point to the front of the housing**, toward the window. The optic plate has a slot for the rib so the optic can't rotate: any rotation tilts the cutoff by the same angle. Confirm the orientation on the bench (B-OPT-06).
- **Focus height.** The datasheet gives the flange height above the PCB only for Luxeon Altilon (10.0 mm) and Osram Oslon (11 mm), not for the XP-L HI. Find it on the bench with printed spacers in 0.1 mm steps, choosing the sharpest cutoff (B-OPT-05).
- **Toe-out (owner's decision, 2026-11-21):** each FILIPPA leans **4° outward** on a 4° aluminium wedge under its LED board (thermal paste on both faces; a printed wedge would block the heat). Under the mirror, leaning an optic sideways becomes a sideways swing of its beam, so the cutoff stays horizontal. The low beam widens from about 22° to about 30° (FWHM). Side effects: about 15% less peak intensity in the centre, the window grows by a few millimetres, and the cutoffs of the toed-out beams may tilt slightly (estimated 1–2°) when the mirror is at the ends of its travel (B-OPT-08).
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

**Cornering lights (owner's decision, 2026-11-21)** *(v3; v4 replaces them by swinging the turn-side beam, §5)*. One fixed light at each end of a rounded brow across the top front of the head, aimed **30° outward and 10° down**, lit by the IMU when the wheel leans or turns that way (firmware-spec §10). It lights the inside of a turn, where the low beam drops.
- **Each light:** a Cree XP-L HI (about 4000 K) on a 20 mm copper board, a Carclo 10003-L25 elliptical optic (~44 × 13°, wide axis horizontal) in a Carclo 10734 holder, behind a small polycarbonate window in the brow's corner. About 0.7 A, ~2.2 W, ~300 lm, roughly 1,000 cd (~10 lux at 10 m).
- **Glare:** aimed 10° down, the half-intensity top edge of the 13° beam stays about 3.5° below horizontal; only the faint outer fringe reaches the horizon. B-CRN-01 checks it against the 2 lux limit.
- **Heat:** each LED sits on a 24 × 24 × 2 mm aluminium spreader plate. They're only on in turns, and firmware caps continuous full power at 20 s.
- **Drivers:** one small 700 mA constant-current buck module per side with a PWM input, on D3 and one more GPIO (§7).
- **Cost and weight:** about $33 and about 33 g for the pair, wedges and drivers included, plus the brow (§5).

**Output estimate:**

| Mode | Emitted | Out the front |
|---|---|---|
| Normal (1.5 A) | ~2400 lm | ~1800 lm |
| Boost (2.1 A) | ~3100 lm | ~2400 lm |

About 600 lm per XP-L HI in normal mode and 780 lm in boost. Out the front assumes the optic (0.85 for the Carclo TIR, 0.90 for the FILIPPA) × mirror (0.95) × window (0.92).

**Beam estimate** (to be measured in B-OPT-04):

| | Spot (2× XP-L HI, Carclo 10003) | Low beam (2× XP-L HI, FILIPPA-STVZO) |
|---|---|---|
| Beam angle | ~8–12° round | ~30° wide × 13° tall with toe-out, sharp top edge |
| Peak intensity, normal (1.5 A) | ~25,000 cd (18–40k) | ~6,200 cd (~62 lux at 10 m) with 4° toe-out (~7,300 cd without) |
| Peak intensity, boost (2.1 A) | ~33,000 cd | ~8,100 cd (~81 lux at 10 m) |
| ANSI throw (to 0.25 lux), normal | ~320 m (270–400 m) | ~170 m |
| ANSI throw, boost | ~360 m | ~195 m |
| Distance to 1 lux, normal | ~160 m | ~85 m |
| Beam width at 30 m | ~5 m | ~16 m |

How it's estimated:
- **Spot:** each beam is treated as a smooth peak with the stated beam angle, about 21 cd per emitted lumen for a 10° spot (15 at 12°, 33 at 8°) after about 0.74 optical efficiency. The biggest uncertainty is the spot's real beam angle with the XP-L HI; Carclo's photometric files would narrow it.
- **Low beam:** LEDiL's 7 cd/lm for the XP-L HI, × 0.95 mirror × 0.92 window, × 600 lm per LED, × 2 optics.
- Two LEDs aimed the same way add. ANSI throw = 2 × √(peak cd).

**Wider high beam at low speed (v4, proposed 2026-11-21):** in high-beam mode the two mirrors swing the spots apart by up to 5° each, so the high beam is ~20° wide when slow and narrows to the full-reach pencil beam by 40 km/h (firmware-spec §12). Speed comes from an IMU estimate (owner's decision, 2026-11-21).

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
| Optional lidar | +~0.4 W (TFS20-L; TF02-Pro ~1 W) | +~0.03 A | about 2% less |
| Cornering lights (v3 only, in turns only) | +~2.2 W per side | +~0.15 A per side | negligible |

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
- **Thermal path:** the LEDs screw onto a finned aluminium heatsink (about 128 × 45 mm, 3 mm base, 16 fins 1.2 × 14 mm, **fins fore-aft**) that forms the middle of the **floor**. Heat never passes through the plastic. The printed floor around it carries the rest.
- **Print settings:**
  - 4–5 perimeters (≥ 2 mm walls), 0.2 mm layers.
  - Hotter nozzle for layer bonding, flow at about 103%.
  - Print the sealing face flat on the bed.
- **Surface sealing:** acetone-vapour smoothing, or XTC-3D epoxy brushed inside and out.
- **Seals:** 2 mm silicone O-ring cord in printed grooves, around the heatsink opening in the floor and around the removable top cover. M3 screws into CNC Kitchen heat-set inserts about every 30 mm.
- **Window:**
  - 2 mm polycarbonate in a gasketed printed bezel.
  - Treat the inside with anti-fog.
  - If you bond it, use **neutral-cure / sensor-safe** RTV only. Acetoxy silicone releases acetic acid, which tarnishes the mirror and LED phosphor.
- **Vent:** an Amphenol LTW M8 ePTFE pressure vent plus desiccant. Without it, warm-up/cool-down cycles pull moisture past the seals and fog the window.
- **Penetrations:**
  - M12 IP68 cable gland, or a panel-mount IP68 connector.
  - Adafruit 16 mm rugged button with an LED ring (comes with a gasket).
- **Shape:** every external edge rounded, 8 mm radius on the body in the model. The window and bezel sit on the flat part of the front, inside the rounded edges.
- **Interior:** printed matte black to kill stray light. A lighter colour outside reduces sun heating.
- **Leak test:** submerge the empty housing with a tissue inside before any electronics go in.

*v4 with clear wraparound sides (2026-11-21, `wrap_sides = true`, now the model's default and the only v4 version: the flat front is dropped, owner, 2026-11-21).* The owner's idea: on each side, **one thermoformed clear piece** runs from the lidar bay across the front, round an 18 mm-radius corner and 30 mm back along the side, so there's **no pillar** between front and side glass.
- **Why it helps:** the outward beam no longer has to leave through the flat front, so the head's width is set by the mirror modules instead of the beam. The outward swing can grow from ±15° to **±25°** (outward only; inward was limited by the lidar bay, and since 2026-11-21 is only a 2.5° aim trim).
- **Model result (superseded the same day by the 150 mm layout below):** about **200 × 71 × 95 mm** body, 111 mm tall with the heatsink (v4 flat-front: 221 mm), and **~399 g** with the lidar, just within the 400 g limit. *(Corrected 2026-11-21: the first wrap model drew the front face ~12 mm too far back, so internal parts poked through the skin and the shell measured light at ~393 g. Fixed, with 1 mm more front clearance and a new skin check, C-PKG-18.)* To keep the heatsinks on the flat floor of the narrower body, the taper drops to 8 mm and the tail radius to 10 mm.
- **Thermoforming the pieces:**
  - **Material:** UV-stabilised polycarbonate, 1.5 mm. PETG forms at 120–160 °C without drying and is easier, but it's less impact- and UV-resistant.
  - **Drying:** PC must be dried first (about 120 °C for several hours for 1.5 mm sheet) or it bubbles when heated.
  - **Forming temperature:** PC forms at about 170–190 °C, above ASA's ~100 °C softening point. An ASA buck would deform or mark the sheet. Use a buck of plaster, MDF, cast resin or aluminium, or an ASA print skinned with plaster or high-temperature epoxy.
  - **Method:** drape or vacuum forming (a shop-vac box) over the buck, or a heat gun and a simple frame for small pieces. The shape is a simple L with a rounded corner, so it drapes well.
  - **Optics:** a uniform thin shell barely bends the beam, but any mould marks scatter light, which shows as glare. Keep the buck's surface smooth and polished, or form with the inner face off the buck.
  - **Sealing:** each piece sits in a printed groove along its top, bottom and both ends with a neutral-cure RTV bead. There's no bezel across the view.

*v4 at 150 mm: owner's review of the renders (2026-11-21).* The owner reviewed the v4 renders and decided:
- **Width:** the body should be narrower, ideally **150 mm** wide (owner's target, not a firm constraint).
- **Lidar:** the **Benewake TFS20-L** replaces the TF02-Pro (§9). With no lidar bay between them, the two mirror modules sit side by side. It first went in a small pod on the roof; the owner then had it moved **under the beams**, behind a rounded chin (below).
- **Clear sides stay fully clear**, showing the mechanism. One piece now runs across the whole front and round both corners, about 200 mm developed length.
- **The exposed fins under the body are fine.**
- **An exploded view** is added to the renders.

What changed in the model (`cad/headlight-v4.scad`):
- **Inward yaw becomes an aim trim:** since no beam swings inward (§5, turning behaviour), inward mirror travel drops from 7.5° to **2.5°**. That keeps ±5° of beam trim for a mount that isn't quite square. Outward stays 12.5° (beam 25°).
- **Gimbal supports:** a 6 mm centre post holds both modules' inner pitch shafts, and a 4 mm post at each side holds the outer ones. The MR63 bearings move into the gimbal frames, so the posts only hold shaft ends.
- **Servos and board:** the servos move outward to the tail, so the electronics board (≥ 55 mm) still fits between them.
- **Shape tweaks to fit inside the wall at this width:**
  - Body taper 8 → 4 mm each side, so the gimbal frames' rear-outer corners clear the side walls.
  - Clear-corner radius 18 → 12 mm (still easy to drape-form in 1.5 mm PC), so the frames' front-outer corners clear the corner.
  - Front clearance 4 → 5 mm. The stricter skin check found each mirror's outer end touching the inside of the front wall at full outward yaw and forward tilt. The 200 mm model had the same touch, hidden because the check only looked at the outer skin.
- **Stricter skin check (C-PKG-18):** optics, servos, board and mirrors are now checked against the inner skin, so they also clear the wall. The lidar is checked against the outer skin (body plus chin), since its window cuts through the wall.
- **Model result:** about **151 × 72 × 95 mm** body, down from 200 mm, and 112 mm tall with the heatsink fins. With the lidar under the beams nothing rises above the roof (the roof pod first tried added 18 mm). Head mass is **~331 g** with the lidar (C-MASS-01), down from ~399 g: about 48 g from the lidar, 10 g from the smaller shell, and 10 g from dropping the roof pod first tried (the model drew that pod as solid plastic round the lidar, so part of the last 10 g is the earlier figure overcounting).
- **What sets the width now:** the two gimbals, the centre post and the outer posts, not the beams. The last millimetre to 150 would come from the outer posts; the 2.5° trim no longer affects the width.
- **Checks:** C-PKG-14 and 16 are retired (they checked the lidar bay). C-PKG-15 now checks that the spots' light clears the centre post. C-PKG-18 checks the skin with the chin included. New C-PKG-19 checks the lidar in the nose (below).

*Lidar under the beams (owner, 2026-11-21).* After seeing the roof pod as a box on the roof, the owner asked for the lidar to go underneath, with the casing rounded round it into a hump rather than a box.
- **Where it fits:** the 12 mm gap between the two heatsinks is too narrow for the 21 mm sensor, but the strip of floor between the heatsink fins and the front wall is 15 mm deep. The lidar sits there, **inside the body** on the floor, centred between the modules and below the clear piece, looking out through its own small window in the front wall.
- **The hump:** the body's bottom front edge is rounded (6 mm), which would cut across the bottom of the window. A shallow **chin**, a U shape seen from the front (about 42 mm wide, 10 mm deep, 2 mm below the underside), keeps the window face flat and fairs into the underside on both sides. It ends just ahead of the heatsink fins and stays far above their 16.5 mm depth, so the head is no taller: about **112 mm with the fins**, against 128 mm at the roof pod.
- **Gains:** no roof pod or cable hole to seal (the lidar is inside the sealed body, behind one gasketed window), shaded from the sun, and a clean roof.
- **Costs:** the lidar is now inside the head with the LED boards (spot optics about 8 mm away) and in front of the heatsinks, so its 60 °C limit depends on the internal air (B-THM-03 now measures it there). It sits about 110 mm lower, so the ray meets the road at a slightly shallower angle; the firmware learns the height `h` at calibration, so nothing changes there.
- **C-PKG-19:** the lidar clears the spot optics, leaves at least 4 mm of wall between its window and the clear piece above it, and its chin ends ahead of the heatsink fins.

**Waterproofing and vibration review (2026-11-21, v3 and v4).**

*Why it can be sealed at all:* every moving part (mirrors, gimbals, servos, linkages) is inside the box. Nothing moving passes through a wall, so there are no shaft seals; every seal is static.

*Seals by layout:*

| Seal | v3 | v4 |
|---|---|---|
| Heatsink opening(s) in the floor, O-ring | 1 | 2 |
| Service cover (top or back), O-ring | 1 | 1 |
| Main window(s), gasket in bezel | 1 | 2 |
| Lidar | in the brow, own gasket | small window in the nose under the clear piece, gasket (TFS20-L isn't IP-rated, so it sits inside the sealed body) |
| Cornering-light windows | 2 | 0 |
| Gland, vent, button | 3 | 3 |
| Total static seal length (model) | ~0.7 m | ~1.25 m |

v4 has fewer separate openings but about 80% more seal length, so more places for a printing flaw to leak.

*Measures for both:*
- O-ring grooves designed for ~25% squeeze on 2 mm cord, with screw bosses that bottom out (heat-set inserts) so the squeeze can't be overdone.
- Sealing faces printed flat on the bed, 100% infill within 5 mm of any seal, then XTC-3D epoxy or acetone-vapour smoothing. With 1.6 mm walls this matters more.
- Windows bedded in neutral-cure RTV inside the bezel, never acetoxy.
- ePTFE vent and desiccant, so warm-up and cool-down cycles don't pump moist air past the seals.
- Electronics conformal-coated (acrylic), and the gland with a drip loop outside.
- **Target IP65** (rain and wheel spray from any direction), verified by a submersion test (E-SEAL-01/02) and a hose test (E-SEAL-04).

*Vibration (EUC road buzz ~10–200 Hz, kerb impacts of several g):*
- **Mirrors:** each is balanced about its pivot(s), so straight-line shocks make no torque. Rotational vibration still reaches the servo through the linkage, and gear backlash shows up as beam jitter. Measures: the 4:1 lever, a light preload spring on each linkage to take up backlash, MR63 bearings preloaded with a wave washer, silicone grease in the pivots, soft bump stops at the ends of travel.
- **v4's gimbals are harder:** each mirror must balance about two axes, the frame adds mass (lower natural frequency, more ringing), and there are twice as many linkages and bearings to rattle. Each linkage needs its own anti-backlash spring and preloaded ball links (B-MIR-05).
- **5 g servos** have weaker, often plastic, gears. Metal-gear versions are preferred, with the 12 g ES08MD II as the fallback if B-MIR-02/05 show jitter.
- **Electronics:** heavy parts (BuckBlocks, capacitors, the Pololu) held down with silicone; wires strain-relieved; the XIAO soldered rather than socketed; the STEMMA QT plug glued after test.
- **Fasteners:** LED boards and metal parts with low-strength threadlocker. **Never threadlocker near the polycarbonate window or the PMMA optics**, because anaerobic threadlockers crack them; use nylon-insert nuts or screws with a nylon patch there.
- **Lidar:** v3's TF02-Pro is clamped on a foam gasket and is IP65 itself. v4's TFS20-L isn't rated, so it sits inside the sealed body, behind a gasketed window in the nose.
- **Mount:** the 1/4"-20 joint can loosen under vibration: a lock washer on the metal adapter, and the leash always.

*Verdict:* both layouts can be made waterproof to IP65 and vibration-resistant, because nothing moving passes through a wall. v4 carries more risk on both counts (longer seals, two-axis gimbals) and needs its extra tests passed before a ride.

**Printed parts:**
- body
- front bezel
- mirror cradle
- servo bracket + lever
- optic plate
- electronics tray
- mount boss
- lidar pocket in the top cover (optional)
- remote case

**Packaging study (2026-11-21, `cad/headlight.scad`).** An OpenSCAD model with every part at datasheet size. Renders and the full mass table are in `cad/renders/`.

*v1 (heatsink lid on top):* everything fitted, but the head came to ~466 g, or ~556 g with the lidar pod hanging underneath.

*v2 (heatsink at the bottom, fins fore-aft):* everything fits, and two rounds of changes brought the mass down.

*v3 (aerodynamic and lean, 2026-11-21).* The owner raised the weight limit to 400 g, kept the lidar on the head and both spots, and asked for a less boxy, more aerodynamic shape:
- **Shape:** a rounded front (6 mm edges) that **tapers 14 mm narrower each side toward the back**, a **roof that slopes 20 mm down** to a soft 14 mm-radius tail, and a **brow fairing** over the lidar and cornering lights that blends 30 mm back into the roof. The window, lidar lenses and cornering windows sit on the flat front; everything behind them is shaped for the airflow. The mount boss stays on the back.
- **Lean package:** 1.6 mm walls (4 perimeters, below the earlier 2 mm minimum, so the leak and thermal-cycling tests matter more), a smaller heatsink (~96 × 45 mm, 2.5 mm base, 10 fins, §8), 1.5 mm window, a 5 g-class micro servo, fewer screws, an M8 gland.
- **Size:** body about 139 × 70 × 88 mm, about 149 mm tall with the fins and brow.
- **Fit:** checks C-PKG-01 to C-PKG-13 pass, including the electronics board (~60 × 52 mm, tighter than before) and servo fitting under the sloping roof and inside the rounded, tapered tail.
- **Mass:** the printed body and brow are now **measured from the model's geometry** (STL volumes), not approximated: body ~53 g, brow ~33 g. The head comes to **~401 g** with the lidar, right at the 400 g limit. The custom PCB (build-plan phase 9) should take off another ~20 g.
- Further options if needed: foaming lightweight ASA for the brow and other non-sealing parts (~−15 g, material to verify), a LightWare LW20/C lidar (~−45 g but ~$187 more, over the cost limit).

*v4 (two 2-axis mirrors, 2026-11-21, `cad/headlight-v4.scad`).* Modelled at the owner's request and **adopted on 2026-11-21 (owner's decision)**, with the clear wraparound sides below. v3 is kept as the earlier layout.
- **Layout:** two mirror modules, each steering one FILIPPA and one spot, on a gimbal: pitch for levelling and yaw for swinging the beam ±15° into turns. Four 5 g-class servos sit in the back slot, two per side, stacked. The yaw steering replaces the cornering lights and the toe-out wedges, so there's no brow: the lidar sits on its side (~42 × 69 mm) in its own bay between the modules, behind a gasketed opening.
- **Shape:** a low, wide light bar, about **221 × 70 × 108 mm** (v3: 139 × 70 × 149 mm). It's wider than first estimated because a module's beam must clear the lidar bay when it swings inward at full yaw. At 221 mm it's wider than a typical 16" wheel's shell (~190 mm in the generic scale model), so it sticks out ~15 mm each side when mounted on the front.
- **Heatsinks:** two, one under each module's LED boards (~60 × 32 mm, 6 fins each), about 1.6 K/W together at 25 km/h (~19 K rise) and ~2.9 K/W at walking pace.
- **Mass:** about **410 g** with the lidar, ~10 g over the limit. Limiting the swing to ±10° narrows the bar to ~211 mm and brings it to ~395 g, with smaller, warmer heatsinks.
- **Checks:** C-PKG-01 to 16 pass for v4 (14–16 are v4-only: lidar height, inward beam clearing the lidar bay, gimbal frame clearing the bay).
- **Trade against v3:** v4 gains steering into turns, a roughly levelled cutoff when leaning (raise the inside half, lower the outside), software-adjustable spread and a brow-free shape. It costs four servos, gimbals, more firmware and calibration, and ~80 mm more width.
- **Turning behaviour (owner decision, 2026-11-21):** in a turn, only the beam on the turn side swings into the curve, up to 25° outward through the clear wraparound side. The other beam stays straight ahead, so the road being left and anything coming the other way stay lit. Both mirrors still tilt to undo the lean. The yaw target is to be specified in the firmware spec if v4 is adopted (the ride demo uses "aim at the road 20 m ahead along the curve").
- **Cutoff roll in turns (finding, 2026-11-22; proposal, owner to decide).** The light reaches each mirror straight up from its fixed optic. Once the mirror sends the beam in a given direction its orientation is fully set, so a sideways swing also turns the beam pattern about its own axis: **the cutoff rolls by the swing angle** (checked numerically; exact for a level beam, independent of how the gimbal's axes are arranged). A swing into the turn rolls the cutoff against the lean. Results:
  - **Turn-side beam:** tilt ≈ lean − swing. **Outside beam:** tilt = the full lean (inside end down, outside end up).
  - **The 20 m look-ahead over-corrects in slow, tight turns.** The swing grows with 1/radius whatever the speed, while the lean grows with speed²:

    | Turn | Lean | Swing (20 m rule) | Turn-side tilt |
    |---|---|---|---|
    | 10 m radius, 15 km/h | 10° | 25° | 15° the wrong way |
    | 20 m radius, 15 km/h | 5° | 25° | **20° the wrong way** |
    | 20 m radius, 35 km/h | 26° | 25° | about level |
    | 40 m radius, 25 km/h | 7° | 14.5° | 7.5° the wrong way |

    "The wrong way" lifts the cutoff's inside end, which in a turn across traffic points at oncoming drivers. In the ride demo's slow corner (10 m, ~13 km/h) that end sits about 0.7° above the road.
  - **Proposed fix:** cap the swing at the lean + 3° (`swing = min(look-ahead swing, |lean| + 3°)`), so the swung cutoff stays within about 3° of level. It lights less of a slow corner. The levelling must also use the cutoff traced through the mirror, not a level line, or the whole cutoff sits about 1.5° high in a turn.
  - **Still open, the outside beam:** it keeps the full lean, so in the demo's 20 m turn at 29 km/h its outer end sits about 0.7° above the road even with the cap. Options: anchor each cutoff's levelling on its highest end rather than its middle (free; costs reach on that side); also swing the outside beam into the turn (only mirrors move, but reverses the "other beam stays straight" decision); or rotate each FILIPPA above its fixed LED (+2 servos, ~+20–25 g, ~+$25; breaks the "only mirrors move" constraint). A third mirror axis can't help: a flat mirror's orientation is already fixed by the beam direction.
  - The ride demo shows all of this with **Cutoff roll** and **Cap swing** (`docs/v4-ride-demo.html`). The high-beam spread also rolls each low beam by its spread, up to 5° (firmware-spec §12).
  - **Consequence:** no beam ever swings inward. Done 2026-11-21: inward travel cut to a 2.5° aim trim, and the body narrowed (see "v4 at 150 mm" above).

## 6. Mounting

- **Interface:** a captive 1/4"-20 brass insert in a printed boss **on the back** of the head (layout v2; the floor is the heatsink). This is the most universal standard, and it takes GoPro adaptors.
- **Base options:**
  1. **Trolley-handle tube clamp.** The strongest option.
  2. **GoPro curved VHB bases** on the shell, above or below the stock light.
  3. Use two bases plus a leash.
- **Aim doesn't need to be precise.** Calibration learns the mount orientation. The light only needs to face forward within about 10°.

## 7. Electronics

**MCU: Seeed XIAO ESP32-S3**
- Dual-core 240 MHz with a hardware floating-point unit, BLE 5, 21 × 17.8 mm.
- Chosen over the C3: about $2 more, but it has a floating-point unit and headroom for lidar fusion and the BLE host.

**Firmware platform (owner, 2026-11-22):** Arduino-ESP32 3.x under PlatformIO, through the community `pioarduino` platform, because the official PlatformIO platform stops at 2.0.17. It is pinned to one release (now 55.03.312-1, Arduino-ESP32 3.3.12, released 2026-09-22) with its digest noted in `firmware/platformio.ini`; moving to a newer release means picking one at least 14 days old. It needs PlatformIO Core 6.2 or later.

**IMU: Adafruit LSM6DSO32**
- 6-axis, ±32 g, so crash detection doesn't saturate.
- Two interrupt pins, plus an on-chip temperature sensor used for internal temperature.

**Pin map:**

| Pin | GPIO | Function |
|---|---|---|
| D0 | 1 | Input voltage sense (120 k / 15 k divider; 20 V → ~2.2 V) |
| D1 | 2 | Heatsink NTC (10 k NTC + 10 k pull-up) |
| D2 | 3 | IMU INT1: wake-on-motion |
| D3 | 4 | Left mirror yaw servo PWM (v4; was the left cornering light in v3) |
| back pad (MTDI) | 41 | Right mirror pitch servo PWM (v4). Confirm on Seeed's pinout |
| back pad (MTMS) | 42 | Right mirror yaw servo PWM (v4). Confirm on Seeed's pinout |
| D4 | 5 | I²C SDA (IMU + lidar) |
| D5 | 6 | I²C SCL |
| D6 | 43 | Button ring LED (6 V LED from 5 V via 2N3904) |
| D7 | 44 | Button (to GND, internal pull-up) |
| D8 | 7 | Spot BuckBlock DIM (2N3904 + 10 µF) |
| D9 | 8 | Flood BuckBlock DIM (2N3904 + 10 µF) |
| D10 | 9 | Left mirror pitch servo PWM |

Seven LEDC channels are used (four servos, two DIM, the ring LED) of the ESP32-S3's eight.

**5 V rail:**
- Pololu D36V28F5 feeds the four servos and the XIAO's 5 V pin (3.2 A covers four 5 g servos moving at once) through a 1N5817.
- The diode makes it safe to plug in USB for flashing while the head is powered.
- 470 µF capacitor on the servo rail.

**Build:** protoboard for v1, custom PCB later.

## 8. Thermal

- **Heat:** about 12 W at normal output, roughly 65% of LED electrical power.
- **Heatsink (layout v3):** about 96 × 45 mm under the optics, 2.5 mm base, 10 fins 1.2 × 14 mm running fore-aft so riding air flows along them. Sized for moving air, with firmware derating when parked:
  - About 1.4 K/W at 25 km/h, so about 16 K above ambient at 12 W (flat-plate laminar estimate over 45 mm fins).
  - About 2.5 K/W at walking pace (2 m/s), so about 30 K above ambient. On a hot day that reaches the 60 °C start of derating, so the spot may dim slightly at walking pace.
  - About 10 K/W in still air with the fins pointing down, which is too hot at full power. Firmware already dims to 20% after 2 min parked (about 2.4 W, ~24 K rise). The heatsink's ~44 J/K of thermal mass gives about 40 s at full power before it warms by 10 K.
  - Verify in B-THM-01, with airflow along the fins.
- **Firmware derating** (thresholds in `firmware-spec.md`):
  - Spot dims before flood.
  - There's always a minimum brightness while moving.
- **Internal temperature** is capped to protect the ASA and the servo.

## 9. Optional: road-slope lidar (look-ahead)

**Sensor: Benewake TFS20-L** (owner's choice, 2026-11-21, replacing the TF02-Pro so the body can narrow to ~150 mm)
- **Size and mass:** 21 × 15 × 7.9 mm and 1.35 g, against the TF02-Pro's ~69 × 42 × 26 mm and ~50 g.
- **Range:** 0.2–9 m at 10% reflectivity in 100 klux sunlight, 12 m in the dark (TF02-Pro: 13.5 m). The aim point is about 8 m ahead, so the margin is thin; Benewake's datasheet versions disagree, and these are the more cautious figures.
- **Other specs:** 100 Hz default (up to 250 Hz), FoV under 2°, 905 nm VCSEL, Class 1 eye-safe, -20 to +60 °C.
- **Supply and interface:** 3.3 V only (not 5 V), ≤ 0.43 W, peak under 130 mA. I²C at address 0x10 by default, with 3.3 V logic like the XIAO, so the one-time UART mode switch the TF02-Pro needed goes away.
- **Mounting:** on the **body** (never the mirror), low in the nose: on the floor between the two modules, below the clear piece, aimed about 3–5° below the beam axis (on the roof until the owner moved it under, 2026-11-21; §5). The model draws it level; the 3–5° wedge in its printed seat isn't modelled.
  - It has **no IP rating**, so it sits inside the sealed head behind its own small clear window, cut from the polycarbonate sheet and gasketed into the front wall over a shallow rounded chin.
  - A divider between the two lenses, touching the window, stops the window reflecting the laser straight back into the receiver.
  - Range through the window is to be measured on the bench (B-LID-02).
- **Lens face to check:** the model assumes the lenses are on the 21 × 15 face, which makes the window 15 mm tall and needs the chin. Check Benewake's dimension drawing before the shell is printed. If the lenses are on the 21 × 7.9 face, the window is only 8 mm tall but the sensor is 15 mm deep, which reaches back over the heatsinks' front edge: C-PKG-19 has to be re-run and the seat moved.
- **Temperature:** under the beams it's shaded from the sun, but it shares the head's internal air with the LED boards and sits just ahead of the heatsinks. The 60 °C limit applies there; to check in B-THM-03.
- **Alternatives rejected:**
  - TFmini Plus: only about 4 m at 10% reflectivity.
  - TF-Luna: 2.5 m at 10%.
  - TF02-Pro: dropped for its width, ~50 g and ~$40 more.
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

**Power and wiring:** TFS20-L: about 0.4 W from the XIAO's 3.3 V rail (peak under 130 mA), on the shared I²C bus at its default address 0x10. No mode switch needed. (TF02-Pro, v3: about 1 W at 5 V, I²C after a one-time UART command.)

## 10. Open questions and risks

- [x] **Board platform (found 2026-11-22, owner decided 2026-11-22):** Arduino-ESP32 **3.x** through the community `pioarduino` platform, pinned to one release (§7). The official PlatformIO `espressif32` platform (6.12) only ships 2.0.17, an older line whose LEDC servo-PWM API differs.
- [x] ~~Does the 519A dome fit the Carclo 10734 holder?~~ No longer needed: the 519A was dropped for the FILIPPA low beam (2026-11-21).
- [ ] BuckBlock analog dimming using 20 kHz PWM + RC: linearity, minimum level.
- [ ] Mirror vibration and ringing at EUC vibration frequencies. Is the balance good enough? (Owner asked about dampers, 2026-11-21.) The mirror doubles any wobble: 0.1° of mirror flutter moves the cutoff ~13 cm at 38 m. Decide after B-MIR-04/05 and a logged ride, trying these in order:
  1. Balance the gimbals about both axes (already in the design).
  2. A light preload spring on each linkage to take out servo gear backlash (a few grams).
  3. Rubber or TPU isolators at the head mount against high-frequency buzz, without adding a slow wobble the IMU loop would have to chase.
  4. Viscous damping grease on the pivot bearings, at some cost in response time.

  Elastomer dampers on each mirror would fight the servos, so they come last.
- [ ] Hobby servo deadband and jitter after the 4:1 linkage. Is a gimbal BLDC needed (GBM2804 + SimpleFOC + AS5600)?
- [ ] Does the ASA housing stay sealed over thermal cycles? Long-term creep at the screw bosses?
- [ ] Real TFS20-L range and dropout rate on wet and dry asphalt at about 4° grazing angle, through its window (B-LID-01, B-LID-02). Only about 9 m at 10% in sunlight on paper, against an ~8 m aim point.
- [ ] TFS20-L lens face (21 × 15 or 21 × 7.9) from the dimension drawing: sets the window and chin in the nose (C-PKG-19).
- [ ] Head weight on VHB mounts. Is the leash mandatory?
- [ ] Two-axis gimbal backlash and ringing under EUC vibration (v4, B-MIR-05); 5 g servo gear durability.
- [ ] Power-on flash: DIM floats until the firmware drives the 2N3904s, so both channels start at 2.1 A. Base pull-ups would stop it, but they also turn the light off if the MCU dies, which loses the full-on failsafe. Accept the flash, or find a way to keep both (e.g. an RC that holds the transistor on only for the first second)?
- [ ] Does the BuckBlock reach zero output with DIM at 0 V? The trolley-mode and crash "beam off" states assume it does.
- [ ] PTC nuisance trips in boost: ~2 A input against an RXEF250 whose 2.5 A hold rating falls to roughly 2 A at 50 °C inside the head. Move to an RXEF300?
- [ ] The 1N5822 dissipates ~1 W at 2 A inside the sealed head. Replace it with a P-MOSFET reverse-polarity stage?
- [ ] P6KE27A clamps at ~37.5 V, above the BuckBlock's 32 V maximum. Low risk with a 20 V bank, but a lower-clamp TVS would cover it.
- [x] Cost over the limit: about $290 core + $98 lidar ≈ $388, against a $350 ceiling. Resolved 2026-11-20: the owner raised the limit to $450, so no parts change.
- [x] **The flood has no cutoff.** Resolved 2026-11-21: the owner chose two LEDiL FILIPPA-STVZO cutoff optics with XP-L HI as the low beam (§3). A shield or masked mirror edge was rejected because a TIR beam isn't an image, so blocking part of it only dims it without making a sharp edge.
- [ ] **Head weight against the 400 g limit** (raised from 350 g, owner, 2026-11-21): ~399 g with the TF02-Pro for v4 at 200 mm; ~331 g at 151 mm with the TFS20-L under the beams (2026-11-21), 69 g of margin (v3 was ~401 g). The custom PCB should add ~20 g of margin; the part masses are estimates until weighed (E-MNT-01).
- [ ] Heatsink sized for moving air (§8): confirm the riding temperature and the parked derating on the bench (B-THM-01).
- [ ] FILIPPA with XP-L HI: focus height, cutoff sharpness and cutoff orientation are not in LEDiL's data. Bench tests B-OPT-05 and B-OPT-06.
- [ ] Larger mirror (115 × 55 mm, about 5× the moment of inertia): does the servo still settle in under 50 ms (B-MIR-01)?
- [ ] Two free GPIO for the right mirror's servos (v4): the XIAO ESP32-S3's back pads MTDI/GPIO41 and MTMS/GPIO42. Confirm on the board.
- [x] ~~Cornering-light glare and the toed-out cutoff tilt (B-CRN-01, B-OPT-08)~~ v3 only; v4 has neither (2026-11-21).
- [ ] v4 turn steering: write the yaw rule into the firmware spec (the ride demo aims the turn-side beam at the road 20 m ahead, up to 25°) and the safety invariant that goes with it. The rule must limit the cutoff roll the swing causes (§5, cutoff roll in turns: proposed cap at the lean + 3°), and the outside beam's tilt needs a decision.
- [x] Speed source for v4 (high-beam width and turn steering): estimated from the IMU, with resets when still and corrections in turns (owner's decision, 2026-11-21; firmware-spec §12). Its accuracy on long straights is checked in R-SPD-01.
- [x] v4 with no inward yaw: narrow the body (§5). Done 2026-11-21 with the TFS20-L (now under the beams): ~151 mm, checks and mass re-run.
- [x] How calibration and settings are controlled: a calibration page over the head's own Wi-Fi, with the button and remote kept as a full fallback (decided 2026-11-21; firmware-spec §11).
