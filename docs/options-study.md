# Options Study: Beam Shaping and Steering Alternatives

Explored on 2026-11-21 at the owner's request, without owner input along the way. Nothing here changes the design yet; [`design.md`](design.md) stays the source of truth. Figures are estimates from geometry and datasheets, not measurements.

**Baseline (the current design):** one flat front-surface mirror on a 1-axis servo pivot (pitch only), two LEDiL FILIPPA-STVZO cutoff optics toed out 4° for a ~30° low beam, two Carclo spot optics, and two fixed IMU-switched cornering lights. About 401 g with the lidar.

## Comparison chart

Scores: ●●●●● best, ● worst. "Mass" and "cost" are changes against the baseline.

| | Baseline | 1a. Convex low-beam mirror | 1b. Crossing beams | 2. Two 2-axis mirrors | 3. Masking tape on the mirror | 4. See-through LCD mask |
|---|---|---|---|---|---|---|
| **What it changes** | — | Low-beam part of the mirror curved sideways (R ≈ 300 mm) | Optics toed *in* so beams cross ahead of the head | Left and right mirrors, each on pitch + yaw | Opaque mask on part of the mirror | Programmable LCD in the beam path |
| **Beam width** | ~30° low beam (toe-out) | ~30–35°, smoother spread, no wedges | Same as toe-out | Low beam steers ±15° into turns | Unchanged | Unchanged |
| **Cutoff** | Sharp (FILIPPA) | Stays sharp; may bow slightly at the edges | Stays sharp | Stays sharp; differential pitch roughly levels it when leaning | Does **not** make a sharp cutoff: only dims | Does **not** make a sharp cutoff unless rebuilt as a projector |
| **Light lost** | Mirror ~5% | Same | Same | Same | Up to the masked fraction | 55–70% (polarisers) |
| **Turns** | Fixed cornering lights | Same | Same | Low beam swings into the turn; could replace the cornering lights | — | In theory, pixel shaping; not practical here |
| **Mass** | ~401 g | −10 g if the mirror is aluminium sheet; 0 g in glass | ~0 g | +30 to +60 g (net of dropping the cornering lights) | 0 g | +40 g or more; far more as a projector |
| **Cost** | — | +$10–20 (sheet + former) | $0 | +$30–40 | $0 | +$30–150 |
| **Complexity / risk** | ●●●● | ●●● custom curved mirror | ●●●● | ●● 4 servos, gimbals, firmware | ●●●●● trivial | ● new optical architecture |
| **Parts availability** | ●●●●● | ●●●● (MIRO-type reflective aluminium sheet) | ●●●●● | ●●●● | ●●●●● | ●● |
| **Verdict** | Keep | **Worth a bench test** as a replacement for the toe-out wedges | **Skip**: no real gain | **Best upgrade path** if weight allows; build as v2 | **Skip** (5-minute bench test to confirm) | **Skip** |

## 1a. Convex mirror for the low beam

**Idea.** Curve the part of the mirror under the two FILIPPA optics sideways (a cylinder whose curvature runs along the left–right axis) so it spreads the low beam horizontally, instead of tilting the optics on wedges.

**How much curvature.** Reflection doubles the mirror's slope change. To widen each low beam by about ±6°, the surface slope must change by ±3° across the ~33 mm the column covers: R ≈ 16.5 mm / tan 3° ≈ **315 mm**, convex. The spot section stays flat, so the high beam keeps its throw.

**Effect on the cutoff.** The curvature only runs left–right, so vertical angles (and the cutoff) are unchanged to first order. Toward the beam's left and right edges the cutoff may bow slightly. Levelling still works because the pivot axis is unchanged.

**Making it.** Bend 0.5–1 mm front-surface reflective aluminium sheet (MIRO-type, ~95% reflective) over a printed former, or use a segmented mirror (flat glass for the spots, curved sheet for the low beam). Aluminium sheet would also save ~10 g over 1.1 mm glass, but thin sheet must be bonded to a stiff backing to stay flat where it should be flat.

**Verdict.** It removes the aluminium wedges and gives a smoother wide beam, at the cost of a custom mirror. Worth a bench comparison against the 4° wedges (same lux grid as B-OPT-04 and B-OPT-08).

## 1b. Crossing beams

**Idea.** Toe the optics *inward* so the left optic's beam goes right and the right optic's goes left, crossing ahead of the head. Far away the combined beam is as wide as with toe-out.

**Why it doesn't help much.** The hope would be a smaller window, because crossing beams are narrowest where they cross. But to cross at the window, about 50 mm of light path from the optics, the outer spots (46 mm off-centre) would have to aim inward by about 43°, which is useless. With a realistic 4° toe-in, the low-beam columns move only ~3.5 mm inward at the window, and the window's width is set by the spot beams at the ends anyway. The body's length is set by the mirror and optic row, not the window. Glare and cutoff are the same as toe-out.

**Verdict.** No meaningful gain; keep toe-out (or 1a).

## 2. Two independent 2-axis mirrors

**Idea.** Split the mirror into a left and a right mirror (each under one FILIPPA and one spot), each on two axes: pitch (levelling) and yaw (steering left–right). No weight limit for this one, as the owner asked.

**What it adds.**
- **Adaptive bending light, like cars' AFS:** both low beams swing up to about ±15° into a turn, driven by yaw rate and lean. This could replace the fixed cornering lights (−33 g and a simpler brow).
- **Better behaviour when leaning.** One mirror can't roll the cutoff: rotating a flat mirror about its own normal doesn't rotate the reflected beam. But with two mirrors, the firmware can raise the inside half of the beam and lower the outside half, a two-step approximation of keeping the cutoff level through a lean.
- **Independent aim:** the spots can be aimed further out while the low beam stays put.
- **Redundancy:** if one servo fails, the other half still levels.

**What it costs.**
- Four servos (or two compact 2-axis gimbals), two pivot frames and a split cradle: roughly +50–90 g before dropping the cornering lights, so about **+30 to +60 g net**.
- A window about 14 mm wider for ±15° of yaw steering (+2 × 27 mm × tan 15°).
- About **+$30–40** (servos, bearings, linkages).
- Firmware: coordinated 4-axis control, calibration of both mirrors, failure handling.
- Two-axis motion on one mirror means the cutoff tilts slightly when pitch and yaw combine (compound angle), which needs a correction table.

**Verdict.** The most capable option and the natural "v2" headlight. It belongs after v1 is proven, and needs a higher weight limit (~430–460 g).

## 3. Masking tape on the mirror for the cutoff

**Idea.** Put opaque tape over part of the mirror to block the light that would go above the cutoff.

**Why it doesn't work here.** A sharp cutoff is an edge in *angle*, not in position. A TIR optic sends every direction of its beam through almost every point of its exit face, so at the mirror (20–30 mm away) any point carries light heading in many directions. Masking part of the mirror removes a fraction of all directions, which dims the beam with only a soft gradient. A mask only creates a sharp cutoff where the optics form an image, which is how car projector headlamps work: a shield sits at the lens's focal plane. The FILIPPA already solves the cutoff, so a mask adds nothing.

**Verdict.** Skip. A 5-minute bench check with tape and a Carclo elliptical optic would confirm it.

## 4. See-through LCD for the cutoff

**Idea.** Put a transparent LCD in the beam and darken pixels to shape the cutoff, or to carve out oncoming traffic.

**Why it doesn't work here.**
- **Same imaging problem as the tape:** a mask only shapes the far beam at an image plane. In front of TIR optics it just dims zones with heavy blur.
- **Light loss:** an LCD's polarisers pass at most 40–45% of unpolarised light, less with colour filters. The head would need roughly 2–3× the LED power for the same light, and the LCD would absorb that heat.
- **Environment:** liquid crystal slows down badly below 0 °C and has upper temperature limits close to what a headlight interior reaches. Sunlight and UV degrade it.
- **To do it properly** you'd build a small projector (LED → condenser → LCD at the focal plane → projection lens 40–60 mm), with system efficiency around 10–20%. Car makers tried LCD masks and moved to DMD micromirrors and micro-LED arrays, which aren't available to hobbyists.

**Verdict.** Skip.

## Recommendation

1. **Keep the baseline for v1.**
2. **Bench-test the convex low-beam mirror (1a)** against the 4° toe-out wedges when the optics are on the bench (build-plan phase 4, test B-OPT-09). If it's as good, it removes the wedges and may save ~10 g with an aluminium mirror.
3. **Plan two 2-axis mirrors (2) as the v2 headlight**, once v1 has ride data. It could replace the cornering lights and partly level the cutoff in turns.
4. **Drop crossing beams, masking and LCD.**
