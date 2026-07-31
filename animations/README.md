# Animations — eSIM activated (success)

A single-pass success animation for the moment a traveller's eSIM is activated,
presented as a **modal dialog** (not a full screen). The dialog pops up over a
dimmed scrim; inside it a green progress ring fills to 100% with a live percentage,
then hands off to a SIM card with a green check badge, reading as **one continuous
morph** rather than two separate events. Title, subtitle and a Continue button
follow. It replaces an indeterminate spinner: the traveller sees definite completion.

It is a dialog: no phone frame, no dedicated screen. The phone frame and the review
controls in the prototype are preview scaffolding and are commented as such — only
the dialog (`.hy-dialog`) on its scrim ships.

| File | What it is |
|------|------------|
| [`esim-activated.html`](./esim-activated.html) | Interactive prototype. Opens in a browser; links the real `tokens.css` and `components.css`. Controls: Replay, 0.25× slow motion, Reduced motion. |

## How it's wired to the design system

Colours are bound to tokens, not painted hexes:

| In the graphic | Token |
|---|---|
| Progress arc, check badge (`#1DB681`) | `--success` |
| Ring track (`#EBEBEB`) | `--skeleton` |
| Badge cut-out ring / screen | `--background` |
| Continue button fill | `--brand` (`.hy-btn--filled`) |
| Title / subtitle | `--title6` / `--bodyXS400`, `--textPrimary` / `--textHint` |

Only the SIM-body grey (`#CFD6DD`) stays hardcoded — it is specific to this graphic
and is not a partner-themable surface. The green `#1DB681` happens to equal
`--success` exactly.

**One deviation from the source handoff, on purpose:** the handoff measured a 44px /
12px-radius / 16px Continue button. This prototype uses the shipping button component
(`.hy-btn--filled`: 52px / 10px radius / 18px), because rule 3 of the design system is
"one button, three variants". The animation graphic itself matches the handoff exactly.

## Motion — one pass on entry, then hold. Nothing loops or pulses.

| # | Phase | Property | From → To | Start | Duration | Curve |
|---|-------|----------|-----------|-------|----------|-------|
| 0 | Scrim in | opacity | 0 → 1 | 0.00s | 0.20s | `cubic-bezier(.4,0,.2,1)` |
| 0 | Dialog in | opacity + scale | 0→1, 96%→100% | 0.00s | 0.26s | `Curves.decelerate` — `cubic-bezier(0,0,.2,1)` |
| 1 | Ring fills | trim / dash offset | 0% → 100% | 0.00s | 1.10s | `Curves.decelerate` — `cubic-bezier(0,0,.2,1)` |
| 1 | % readout | centred number | 0 → 100 | 0.00s | 1.10s | driven by the ring's own value (same curve) |
| 2 | Ring exits | opacity + scale | 1→0, 100%→86% | 1.26s | 0.34s | `Curves.fastOutSlowIn` — `cubic-bezier(.4,0,.2,1)` |
| 3 | SIM enters | opacity | 0 → 1 | 1.32s | 0.30s | `cubic-bezier(.4,0,.2,1)` |
| 3 | SIM enters | scale | 70% → 100% | 1.32s | 0.42s | `cubic-bezier(.2,.9,.3,1)` |
| 4 | Title | opacity + translateY | 0→1, +8px→0 | 1.44s | 0.30s | `cubic-bezier(.4,0,.2,1)` |
| 5 | Subtitle | opacity + translateY | 0→1, +8px→0 | 1.52s | 0.30s | same |

**Critical:** phases 2 and 3 overlap by 0.06s. That overlap is what makes the ring and
the SIM read as one morph. Do not sequence them back to back.

---

## Flutter handoff spec

```
ANIMATION SPEC: eSIM activated — success
Component: Modal dialog (NOT a full screen). A dimmed scrim with a centred dialog
  card (.hy-dialog: background fill, 16px radius, dialog shadow, max-width 340).
  Contents top to bottom: graphic (132 x 132, transform origin centre 66,66), title,
  subtitle, full-width Continue button. No phone frame.
Purpose: Confirm the eSIM is now active with a definite, celebratory completion,
  then move the traveller on to Set up.
Trigger: Dialog shown on activation success. Animation auto-plays once as it opens.
  Continue dismisses the dialog and advances to the Set up step.

Phases (one AnimationController, duration 1820ms, Interval-wrapped curves):
0. Modal opens: scrim opacity 0 -> 1 (200ms, Cubic(0.4,0,0.2,1)) AND dialog
   opacity 0 -> 1 + scale 0.96 -> 1.0 (260ms, Curves.decelerate Cubic(0,0,0.2,1)),
   both from start 0ms. The ring fill (phase 1) runs underneath from 0ms, so the
   card pops up with the ring already beginning to fill. Standard Material/Cupertino
   dialog entrance is acceptable if the app already has one; these values match it.
1. Progress ring: trim / stroke-dash 0% -> 100%
   Duration: 1100ms | Curve: Curves.decelerate  Cubic(0,0,0.2,1)  | start 0ms
   Percentage readout: integer 0 -> 100, centred in the ring, driven by the SAME
   animated value as the ring (not a separate tween) so it tracks the easing exactly.
   Render as e.g. "${(ringFill.value * 100).round()}%". It exits with the ring in
   phase 2 (same opacity + scale). Use tabular figures so the digits do not jitter.
2. Ring exits: opacity 1 -> 0  AND  scale 1.0 -> 0.86
   Duration: 340ms  | Curve: Curves.fastOutSlowIn Cubic(0.4,0,0.2,1) | start 1260ms
3. SIM enters: opacity 0 -> 1
   Duration: 300ms  | Curve: Cubic(0.4,0,0.2,1) | start 1320ms
   SIM enters: scale 0.70 -> 1.0
   Duration: 420ms  | Curve: Cubic(0.2,0.9,0.3,1) (gentle settle) | start 1320ms
4. Title: opacity 0 -> 1  AND  translateY +8px -> 0
   Duration: 300ms  | Curve: Cubic(0.4,0,0.2,1) | start 1440ms
5. Subtitle: opacity 0 -> 1  AND  translateY +8px -> 0
   Duration: 300ms  | Curve: Cubic(0.4,0,0.2,1) | start 1520ms

Stagger / delays: absolute starts above on one 1820ms timeline. Phases 2 and 3
  overlap by 60ms deliberately (the ring-to-SIM morph). Title/subtitle stagger 80ms.
Interruption: never hard-cut. If the dialog is dismissed mid-flight, let it settle to
  the final frame and fade out. Further taps on Continue are ignored until settled.
Reduced motion (MediaQuery.disableAnimationsOf(context) == true):
  Dialog and scrim appear with no entrance (or the app's instant dialog present).
  Skip phases 1-3 entirely; set controller.value = 1.0 so the final frame shows
  immediately: SIM + check badge at full opacity and scale, title, subtitle and
  button all static. No ring, no fills, no translateY.
Suggested Flutter approach: present via showDialog (barrier = the scrim); the dialog
  child is the animated content. One AnimationController + CustomPaint. The ring is a
  drawArc whose sweep = 2*pi*progress from -pi/2 (12 o'clock, clockwise). The SIM +
  badge is a second CustomPaint (or a small Stack of shapes) cross-fading/scaling in.
  Wrap each phase in CurvedAnimation(parent: c, curve: Interval(startMs/1820,
  (startMs+durMs)/1820, curve: ...)). No flutter_animate needed; no app state for the
  animation itself. Bind colours to theme: success #1DB681, ring track = skeleton,
  badge cut-out ring = background, button = brand. SIM body #CFD6DD is graphic-local.
Assets: none. Everything is drawn in code — no Lottie, no Rive. The animation is
  simple enough that a native AnimationController is smaller, sharper on device and
  easier to tweak than an imported asset. esim-activated-layers.svg (in the design
  handoff bundle) is a geometry reference only.
```

### Geometry reference

- Ring: track + arc, `r = 46`, centred `(66,66)`, stroke width `8`, arc round-capped.
  Circumference `2·π·46 = 289.03` (the dash length).
- Percentage readout: centred text at `(66,66)`, `26px / 600`, colour `--textPrimary`,
  tabular figures, letter-spacing `-0.02em`. Shows `0%`…`100%`.
- SIM body: `56 × 68`, corner radius `8`, top-right chamfer `14px`. Three white pins,
  `5 × 14`, radius `2.5`.
- Check badge: circle `r = 17` at the SIM's lower-right, ringed by a `3px` stroke in
  the screen background colour so it cuts cleanly out of the SIM. Tick stroke `2.8`,
  round cap and join.
