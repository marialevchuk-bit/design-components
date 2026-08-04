# Animations — eSIM activated (success)

A single-pass success animation for the moment a traveller's eSIM is activated,
presented as a **modal dialog** (not a full screen). The dialog pops up over a
dimmed scrim; inside it a green progress ring fills to 100% with a live percentage,
then hands off to a SIM card with a green check badge, reading as **one continuous
morph** rather than two separate events. A title and a Continue button follow. It
replaces an indeterminate spinner: the traveller sees definite completion.

It is a dialog: no phone frame, no dedicated screen. The phone frame and the review
controls in the prototype are preview scaffolding and are commented as such — only
the dialog (`.hy-dialog`) on its scrim ships.

| File | What it is |
|------|------------|
| [`esim-activated.json`](./esim-activated.json) | **The asset to ship.** Lottie animation of the 132×132 graphic (ring fills → morph → SIM with check badge). 60fps, 105 frames (1.75s), 4.7 KB. Drop into the Flutter `lottie` package. See "Lottie usage" below. |
| [`esim-activated.html`](./esim-activated.html) | Reference prototype — open in a browser to feel the full moment in context. Links the real `tokens.css` / `components.css`. Controls: Replay, 0.25× slow motion, Reduced motion. Not shipped. |

**What is Lottie vs native.** The JSON is only the animated **graphic**. The
percentage counter, the dialog, the scrim, the title and the Continue button are
**native Flutter** — the counter because Lottie can't render a live number
reliably in the Flutter `lottie` package, the rest because they are ordinary UI.

## How it's wired to the design system

Colours are bound to tokens, not painted hexes:

| In the graphic | Token |
|---|---|
| Progress arc, check badge (`#1DB681`) | `--success` |
| Ring track (`#EBEBEB`) | `--skeleton` |
| Badge cut-out ring / screen | `--background` |
| Continue button fill | `--brand` (`.hy-btn--filled`) |
| Title | `--title6`, `--textPrimary` |

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

**Critical:** phases 2 and 3 overlap by 0.06s. That overlap is what makes the ring and
the SIM read as one morph. Do not sequence them back to back.

---

## Flutter handoff spec

```
ANIMATION SPEC: eSIM activated — success
Component: Modal dialog (NOT a full screen). A dimmed scrim with a centred dialog
  card (.hy-dialog: background fill, 16px radius, dialog shadow, max-width 340).
  Contents top to bottom: graphic (132 x 132, transform origin centre 66,66), title,
  full-width Continue button. No subtitle. No phone frame.
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
   (No subtitle on this screen.)

Stagger / delays: absolute starts above on one 1820ms timeline. Phases 2 and 3
  overlap by 60ms deliberately (the ring-to-SIM morph).
Interruption: never hard-cut. If the dialog is dismissed mid-flight, let it settle to
  the final frame and fade out. Further taps on Continue are ignored until settled.
Reduced motion (MediaQuery.disableAnimationsOf(context) == true):
  Dialog and scrim appear with no entrance (or the app's instant dialog present).
  Skip phases 1-3 entirely; set controller.value = 1.0 so the final frame shows
  immediately: SIM + check badge at full opacity and scale, title and button
  static. No ring, no fills, no translateY.
Suggested Flutter approach: present via showDialog (barrier = the scrim); the dialog
  child is native (.hy-dialog card + title + Continue button). The GRAPHIC
  is the Lottie asset esim-activated.json, played by the lottie package driven by an
  AnimationController (see "Lottie usage" below). The % counter is a native Text
  overlaid on the Lottie, driven by the same controller. A fully-native CustomPaint
  alternative (no asset) is viable too — drawArc sweep = 2*pi*progress from -pi/2, SIM
  as a second painter cross-fading/scaling in — but the Lottie is the chosen handoff.
  Bind native colours to theme: success #1DB681, brand button = brand. Inside the
  Lottie the same colours are baked (success arc/badge, skeleton track, #FAF8F4 badge
  cut-out); SIM body #CFD6DD is graphic-local. Because background/success are constant
  (not partner-themed), baking them is safe.
Assets: esim-activated.json — Lottie, 132×132, 60fps, 105 frames (~1.75s), single
  play, transparent background. Covers phases 1-3 only (ring fill, ring exit, SIM in).
  The dialog entrance, title, button and the % counter are native.
```

## Lottie usage (Flutter)

Add the `lottie` package, bundle `esim-activated.json` as an asset, and drive it with
an `AnimationController` so the native percentage counter can read the same progress.

```dart
// pubspec.yaml: dependencies: lottie: ^3.x   +   assets: - assets/esim-activated.json

class EsimActivatedGraphic extends StatefulWidget {
  const EsimActivatedGraphic({super.key});
  @override
  State<EsimActivatedGraphic> createState() => _EsimActivatedGraphicState();
}

class _EsimActivatedGraphicState extends State<EsimActivatedGraphic>
    with SingleTickerProviderStateMixin {
  // The Lottie graphic is 1.75s; the ring fill (where the % counts) is the first 1.1s.
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1750));

  static const _fillMs = 1100, _totalMs = 1750;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _c.value = 1.0;           // reduced motion: jump to the final SIM frame
      } else {
        _c.forward();
      }
    });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132, height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Lottie.asset('assets/esim-activated.json', controller: _c),
          // native % counter, synced to the same controller; fades out with the ring
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value * _totalMs;
              final pct = (t / _fillMs).clamp(0.0, 1.0);          // 0..1 over the fill
              final opacity = 1.0 - ((t - 1260) / 340).clamp(0.0, 1.0); // ring-exit fade
              if (opacity <= 0) return const SizedBox.shrink();
              return Opacity(
                opacity: opacity,
                child: Text('${(pct * 100).round()}%',
                  style: const TextStyle(
                    fontFamily: 'GeneralSans', fontWeight: FontWeight.w600,
                    fontSize: 26, letterSpacing: -0.5,
                    fontFeatures: [FontFeature.tabularFigures()],
                    // color: theme textPrimary
                  )),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

Notes: the counter reads `_c.value`, so it tracks the ring's easing exactly and stays
in sync if the duration is tuned. It fades out on the same 1260–1600ms window as the
ring inside the Lottie, so the number leaves with the ring at the morph. The title
and the Continue button are separate native widgets shown after (phase 4).

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
