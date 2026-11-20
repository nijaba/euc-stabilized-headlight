# EUC Stabilized Headlight – Bill of Materials (v2)

Version: XIAO ESP32-S3, 3D-printed ASA housing with aluminium heatsink lid, external USB-C PD power bank, servo-driven mirror, optional road-slope lidar.  
Prices: approximate USD street prices, Nov 2026. **Check the live pages before ordering.** Links marked *search* go to a marketplace search because those parts are commodity items with many equivalent sellers.

## Changes since the last design

- **LED driver:** the Mean Well LDD-1500H is discontinued, so it's replaced by the **LEDdynamics BuckBlock A009-D-V-2100**. It's dimmable and rated 2.1 A. Firmware caps it at about 1.5 A in normal mode and allows 2.1 A in a time-limited boost mode.
- **Dimming flicker:** BuckBlock PWM is specified at 200 Hz, which would flicker visibly on a moving wheel. Instead, the 2N3904 interface runs at about 20 kHz with a 10 µF cap on DIM, which turns it into smooth analog dimming. Verify this on the bench.
- **Spot LED:** the SFT-40 is a 5050 package and doesn't fit the 20 mm XP-footprint optic holders, so it's swapped for the **Cree XP-L HI (3535)**. All four LEDs now share the same holder.
- **IMU:** the LSM6DSO32 (±32 g) is used, so crash detection doesn't saturate. Its on-chip temperature sensor replaces the internal NTC.
- **Lidar:** a new optional section H. It shares the I²C bus, so it needs no extra pins.

## A. Control

| Item | Part / spec | Qty | Unit $ | Ext $ | Source | Notes |
|---|---|---|---|---|---|---|
| MCU | Seeed Studio XIAO ESP32-S3 (non-Sense, SKU 113991114) | 1 | 7.49 | 7.49 | [link](https://www.seeedstudio.com/XIAO-ESP32S3-p-5627.html) | Dual-core 240 MHz, FPU, BLE 5 |
| IMU | Adafruit LSM6DSO32 6-DoF, ±32 g (#4692) | 1 | 12.50 | 12.50 | [link](https://www.adafruit.com/product/4692) | ±32 g range handles crash detection; 2 INT pins |
| IMU cable | STEMMA QT / Qwiic JST-SH 4-pin, 50 mm (Adafruit #4399) | 1 | 0.95 | 0.95 | [link](https://www.adafruit.com/product/4399) | Or solder wires directly |
| **Subtotal** | | | | **20.94** | | |

## B. Power electronics

| Item | Part / spec | Qty | Unit $ | Ext $ | Source | Notes |
|---|---|---|---|---|---|---|
| LED driver ×2 (spot, flood) | LEDdynamics BuckBlock A009-D-V-2100 (10–32 V in, 2.1 A, dimmable) | 2 | 21.00 | 42.00 | [link](https://www.digikey.com/en/products/detail/leddynamics-inc/0A009-D-V-2100/22578489) | Replaces the discontinued Mean Well LDD-1500H. Firmware caps at ~1.5 A normal, 2.1 A boost. Also sold at ledsupply.com/led-drivers/buckblock-dc-led-driver |
| 5 V regulator | Pololu D36V28F5 (5 V 3.2 A, 5.3–50 V in) | 1 | 23.95 | 23.95 | [link](https://www.pololu.com/product/3782) | Feeds servo + XIAO. Cheaper option: generic MP1584 5 V module (~$2) for prototyping |
| Dim / ring-LED transistors | 2N3904 NPN, TO-92 | 3 | 0.15 | 0.45 | [search](https://www.digikey.com/en/products/result?keywords=2N3904+TO-92) | 2 for BuckBlock DIM (datasheet's MCU interface), 1 for button ring LED |
| DIM smoothing caps | 10 µF 25 V ceramic or electrolytic | 2 | 0.30 | 0.60 | [search](https://www.digikey.com/en/products/result?keywords=10uF+25V+radial+capacitor) | Turns 20 kHz PWM into smooth analog dimming (no 200 Hz flicker) – confirm on bench |
| Reverse-polarity diode | 1N5822 Schottky 3 A 40 V | 1 | 0.35 | 0.35 | [search](https://www.digikey.com/en/products/result?keywords=1N5822) |  |
| 5 V OR-ing diode | 1N5817 Schottky | 1 | 0.25 | 0.25 | [search](https://www.digikey.com/en/products/result?keywords=1N5817) | Safe to plug in USB for flashing while powered |
| Input TVS | P6KE27A (through-hole) | 1 | 0.45 | 0.45 | [search](https://www.digikey.com/en/products/result?keywords=P6KE27A) |  |
| Input fuse | Littelfuse RXEF250 PTC, 2.5 A hold | 1 | 0.60 | 0.60 | [search](https://www.digikey.com/en/products/result?keywords=RXEF250) | Resettable |
| Bulk caps | 220 µF 35 V (input) + 470 µF 10 V (servo rail), low-ESR electrolytic | 2 | 0.50 | 1.00 | [search](https://www.digikey.com/en/products/result?keywords=220uF+35V+low+ESR+radial) |  |
| Thermistors | Vishay NTCLE100E3103JB0, 10 k NTC | 2 | 0.55 | 1.10 | [search](https://www.digikey.com/en/products/result?keywords=NTCLE100E3103JB0) | Heatsink + internal; fix with paste + Kapton |
| Resistors | 1/4 W kit (need 120 k, 15 k, 10 k ×2, 1 k ×3, 100 Ω) | 1 | 8.00 | 8.00 | [search](https://www.amazon.com/s?k=1/4W+metal+film+resistor+kit) | Skip if you have a kit |
| Protoboard | Adafruit Perma-Proto half-size (#1609) | 1 | 4.50 | 4.50 | [link](https://www.adafruit.com/product/1609) | Custom PCB later |
| Wire | Silicone wire 22 AWG + 26 AWG | 1 | 10.00 | 10.00 | [search](https://www.amazon.com/s?k=silicone+wire+22+awg+26+awg+kit) |  |
| **Subtotal** | | | | **93.25** | | |

## C. Optics & mechanism

| Item | Part / spec | Qty | Unit $ | Ext $ | Source | Notes |
|---|---|---|---|---|---|---|
| Spot LEDs | Cree XP-L HI (3535) on 20 mm DTP copper, 5000–6500 K | 2 | 6.50 | 13.00 | [link](https://kaidomain.com/XP-L-HI-10W-3A-1095-Lumens-SMD-3535-LED) | Choose the '20mm DTP Copper' option (+$1.20). Swapped in for SFT-40 (5050 doesn't fit the XP holder) |
| Flood LEDs | Nichia 519A (3535) on 20 mm DTP copper, 4500–5000 K | 2 | 3.20 | 6.40 | [link](https://kaidomain.com/SMD-LEDs/Nichia-LEDs/519A-7_04W-2200mA-SMD-3535-LED) | 2.2 A rated; high CRI = better road texture |
| Spot optics | Carclo 10003 narrow spot, 20 mm (~8–12°) | 2 | 2.75 | 5.50 | [link](https://www.ledsupply.com/led-optics/10003-carclo-lens-20mm-narrow-spot-led-optic) |  |
| Flood optics | Carclo 10003-L25 elliptical, 20 mm (~44×13°) | 2 | 3.25 | 6.50 | [link](https://www.ledsupply.com/led-optics/10003-l25-carclo-lens-20mm-elliptical-spot-led-optic) | Mount with the wide axis horizontal |
| Optic holders | Carclo 10734, 20 mm, XP footprint | 4 | 0.80 | 3.20 | [link](https://www.digikey.com/en/products/detail/carclo-technical-plastics/10734/2641685) | Check the 519A dome fits before ordering more |
| Mirror | Front-surface (first-surface) glass mirror, enhanced Al, cut to ~90×35 mm | 1 | 18.00 | 18.00 | [link](https://www.edmundoptics.com/f/first-surface-mirrors/12017/) | Edmund: precise, pricier. Budget: https://www.aliexpress.com/w/wholesale-front-surface-mirror-glass.html (glass, not acrylic). Score on the back face to cut |
| Pivot bearings | MR63ZZ (3×6×2.5 mm), pack of 10 | 1 | 8.00 | 8.00 | [search](https://www.amazon.com/s?k=MR63ZZ+bearing) |  |
| Pivot shaft | 3 mm stainless steel rod, 100 mm | 1 | 6.00 | 6.00 | [search](https://www.amazon.com/s?k=3mm+stainless+steel+rod+100mm) |  |
| Linkage | RC pushrod set: 1.2 mm Z-bend wire + clevis / EZ connector | 1 | 7.00 | 7.00 | [search](https://www.amazon.com/s?k=rc+pushrod+clevis+kit+1.2mm) | Gives the 4:1 lever ratio |
| Servo | EMAX ES08MD II, digital, metal gear, 12–13 g | 1 | 14.00 | 14.00 | [link](https://www.readymaderc.com/products/details/emax-es08mdii-12g-digital-metal-gear-servo) | Also AMain Hobbies, RaceDayQuads |
| Heatsink (= lid) | Finned aluminium heatsink ~100×60×20 mm | 1 | 9.00 | 9.00 | [search](https://www.amazon.com/s?k=aluminum+heatsink+100x60x20mm) | LED stars screw to the flat side; drill/tap M3 |
| Thermal paste | Arctic MX-4 (or similar) | 1 | 7.00 | 7.00 | [search](https://www.amazon.com/s?k=Arctic+MX-4) | Skip if you have it |
| **Subtotal** | | | | **103.60** | | |

## D. Housing & sealing

| Item | Part / spec | Qty | Unit $ | Ext $ | Source | Notes |
|---|---|---|---|---|---|---|
| Filament | ASA 1 kg (Polymaker / Prusament) – ~150 g used | 1 | 25.00 | 25.00 | [search](https://www.amazon.com/s?k=ASA+filament+1kg) | Black interior parts can be same spool |
| Window | Polycarbonate sheet 2–3 mm (or 3 mm tempered glass), cut to ~100×50 mm | 1 | 10.00 | 10.00 | [search](https://www.amazon.com/s?k=polycarbonate+sheet+3mm+8x10) |  |
| Anti-fog | Rain-X Anti-Fog (inside of window) | 1 | 6.00 | 6.00 | [search](https://www.amazon.com/s?k=Rain-X+anti+fog) |  |
| O-ring | Silicone O-ring cord, 2 mm, 2 m | 1 | 8.00 | 8.00 | [search](https://www.amazon.com/s?k=silicone+o-ring+cord+2mm) | Glue the ends with CA glue |
| Heat-set inserts | CNC Kitchen M3 short (M3×3.0), 100 pcs | 1 | 10.00 | 10.00 | [link](https://www.3djake.com/cnc-kitchen/threaded-inserts-m3-short) | Also at prusa3d.com |
| Screws | M3 A2 stainless assortment (6–16 mm, button head) | 1 | 10.00 | 10.00 | [search](https://www.amazon.com/s?k=M3+stainless+button+head+screw+assortment) |  |
| Mount insert | 1/4"-20 brass heat-set insert (or captive 1/4"-20 nut) | 1 | 6.00 | 6.00 | [search](https://www.amazon.com/s?k=1/4-20+heat+set+insert+brass) | Main structural anchor |
| Pressure vent | Amphenol LTW VT-BPM08BK-NO8001, M8 ePTFE vent, IP68 | 1 | 4.00 | 4.00 | [link](https://www.masterelectronics.com/en/amphenol-ltw/vtbpm08bkno8001-64689643.html) | Also search the same part number at Mouser/DigiKey |
| Cable gland | M12 nylon IP68 gland, 3–6.5 mm cable | 1 | 5.00 | 5.00 | [search](https://www.amazon.com/s?k=M12+cable+gland+IP68+3-6.5mm) | Only if not using a panel connector |
| Button | Adafruit Rugged Metal Pushbutton, 16 mm, LED ring, momentary (#560 green / #481 blue) | 1 | 4.95 | 4.95 | [link](https://www.adafruit.com/product/560) | Includes rubber gasket; 6 V LED – run from 5 V via 2N3904 |
| Desiccant | 1–2 g silica gel packs | 1 | 6.00 | 6.00 | [search](https://www.amazon.com/s?k=silica+gel+packets+1+gram) |  |
| Sealant | Sensor-safe neutral-cure RTV (e.g. Permatex Ultra Black 82180) | 1 | 8.00 | 8.00 | [search](https://www.amazon.com/s?k=Permatex+82180) | Do NOT use acetoxy (vinegar-smell) silicone near the mirror/LEDs |
| Surface sealer (optional) | Smooth-On XTC-3D epoxy coating | 1 | 25.00 | 25.00 | [search](https://www.amazon.com/s?k=XTC-3D) | Skip if acetone-vapour smoothing the ASA |
| **Subtotal** | | | | **127.95** | | |

## E. Mounting

| Item | Part / spec | Qty | Unit $ | Ext $ | Source | Notes |
|---|---|---|---|---|---|---|
| Adhesive bases | GoPro Curved + Flat Adhesive Mounts (AACFT-001, 6 pcs) | 1 | 19.99 | 19.99 | [link](https://www.bhphotovideo.com/c/product/895457-REG/GoPro_130_02095_000_Flat_Curved_Adhesive_Mounts.html) |  |
| Adapter | 1/4"-20 tripod screw to GoPro adapter | 1 | 6.00 | 6.00 | [search](https://www.amazon.com/s?k=1/4-20+to+gopro+mount+adapter) |  |
| Bar clamp | GoPro-compatible tube clamp, 15–35 mm (trolley handle) | 1 | 10.00 | 10.00 | [search](https://www.amazon.com/s?k=gopro+handlebar+clamp+aluminum) | Strongest mounting option |
| Leash | Coiled lanyard / tether with mini carabiner | 1 | 8.00 | 8.00 | [search](https://www.amazon.com/s?k=coiled+tether+lanyard+carabiner) |  |
| **Subtotal** | | | | **43.99** | | |

## F. External power

| Item | Part / spec | Qty | Unit $ | Ext $ | Source | Notes |
|---|---|---|---|---|---|---|
| Power bank | Baseus Adaman 65 W 20,000 mAh (15 V / 3 A on USB-C) | 1 | 50.00 | 50.00 | [link](https://www.baseus.com/products/adaman-power-bank-65w-20000mah) | Any 20 Ah bank with 15 V ≥ 2 A PD works (alt: JSAUX PB6501, Anker A1383). $0 if you own one |
| PD trigger cable | USB-C PD → 5.5 mm barrel, fixed 15 V, e-marked | 1 | 12.00 | 12.00 | [link](https://shop.pimoroni.com/products/usb-type-c-3-1-pd-to-5-5mm-barrel-jack-cable-1-2m-long-with-e-mark) | Cut the barrel off and splice to the IP68 connector |
| Waterproof connector | IP68 2-pin inline connector pair (SP13 / M12 style) | 1 | 7.00 | 7.00 | [search](https://www.amazon.com/s?k=IP68+2+pin+waterproof+connector) |  |
| Pouch | Waterproof pouch/bag for the power bank | 1 | 12.00 | 12.00 | [search](https://www.amazon.com/s?k=waterproof+dry+pouch+power+bank) |  |
| Breakaway (optional) | IP67 magnetic 2-pin connector | 1 | 10.00 | 10.00 | [search](https://www.amazon.com/s?k=waterproof+magnetic+connector+2+pin) | Pops apart in a fall |
| **Subtotal** | | | | **91.00** | | |

## G. Remote (DIY)

| Item | Part / spec | Qty | Unit $ | Ext $ | Source | Notes |
|---|---|---|---|---|---|---|
| Remote MCU | Seeed Studio XIAO nRF52840 (non-Sense) | 1 | 9.90 | 9.90 | [link](https://www.seeedstudio.com/Seeed-XIAO-BLE-nRF52840-p-5201.html) | Has LiPo charging built in |
| Battery | LiPo 3.7 V 150 mAh (Adafruit #1317) | 1 | 5.95 | 5.95 | [link](https://www.adafruit.com/product/1317) |  |
| Buttons | IP67 sealed tactile switch (e.g. C&K KSC series) | 2 | 1.20 | 2.40 | [search](https://www.digikey.com/en/products/result?keywords=IP67+tactile+switch) |  |
| Strap | Hook-and-loop strap, 20 mm | 1 | 5.00 | 5.00 | [search](https://www.amazon.com/s?k=velcro+strap+20mm) | Case printed from the ASA spool |
| **Subtotal** | | | | **23.25** | | |

## H. Road-slope lidar (optional)

| Item | Part / spec | Qty | Unit $ | Ext $ | Source | Notes |
|---|---|---|---|---|---|---|
| Lidar | Benewake TF02-Pro, IP65, 13.5 m @10% reflectivity, UART/I²C, 5–12 V | 1 | 92.49 | 92.49 | [link](https://www.racedayquads.com/products/benewake-tf02-pro-ip65-lidar) | Also Lumenier / GetFPV (~$100). Runs on the shared I²C bus (one-time UART command to switch modes) |
| Lidar gasket + screws | EPDM foam gasket strip 3 mm + M2.5 stainless screws | 1 | 6.00 | 6.00 | [search](https://www.amazon.com/s?k=EPDM+foam+gasket+tape+3mm) | Seals the lidar face in its own front cut-out |
| **Subtotal** | | | | **98.49** | | |

### Cheaper remote alternative (replaces section G)

| Item | Part / spec | Qty | Unit $ | Ext $ | Source | Notes |
|---|---|---|---|---|---|---|
| BLE shutter / page-turner ring | Generic BLE HID remote | 1 | 6.00 | 6.00 | [search](https://www.amazon.com/s?k=bluetooth+camera+shutter+remote) | Replaces all of section G. May lose the first press after it sleeps |

## 3D-printed parts (no purchase)

| Part | Notes |
|---|---|
| Body | ASA, 5 perimeters, open top, O-ring groove, vent + button + gland bosses |
| Front bezel | ASA, clamps window with gasket |
| Mirror cradle | ASA, pivots on MR63 bearings, balanced about the shaft |
| Servo bracket + lever arm | ASA, sets the 4:1 ratio |
| Optic plate | ASA, locates the 4 Carclo holders on the heatsink |
| Electronics tray | ASA, holds the protoboard, BuckBlocks, Pololu |
| Mount boss | ASA, holds the 1/4"-20 insert |
| Remote case | ASA or TPU, 2 buttons + strap slots |
| Lidar bracket (if section H) | ASA, fixed to the body (not the mirror), aims the lidar ~3–5° below the beam axis |

## Cost summary

| | USD |
|---|---|
| Core build, cash outlay (sections A–G, excluding the 2 optional items) | **469** |
| Optional extras (XTC-3D coating, magnetic breakaway) | +35 |
| Road-slope lidar (section H) | +98 |
| Subtract if you already own a power bank, filament, resistor kit, wire, paste | −100 |
| Packs and spools left over after one unit (inserts, screws, O-ring cord, bearings, mounts…) | ≈ 129 |
| **Material actually used per unit, without lidar or power bank** | **≈ 290** |

Tools not included: 3D printer, soldering iron with a heat-set insert tip, multimeter, glass cutter, drill and M3 tap.

## Pin map (XIAO ESP32-S3)

| Pin | GPIO | Function |
|---|---|---|
| D0 | 1 | Input voltage sense (120 k / 15 k) |
| D1 | 2 | Heatsink NTC |
| D2 | 3 | IMU INT1 (wake-on-motion) |
| D3 | 4 | Spare |
| D4 | 5 | I²C SDA (IMU + lidar) |
| D5 | 6 | I²C SCL |
| D6 | 43 | Status / button ring LED (via 2N3904) |
| D7 | 44 | Button (to GND, internal pull-up) |
| D8 | 7 | Spot BuckBlock DIM (via 2N3904 + 10 µF) |
| D9 | 8 | Flood BuckBlock DIM (via 2N3904 + 10 µF) |
| D10 | 9 | Servo PWM |

The internal temperature comes from the LSM6DSO32's on-chip sensor. USB-C on the XIAO is used for flashing and serial logging.
