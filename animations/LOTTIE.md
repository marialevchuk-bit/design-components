# Home hero animations: Lottie files

Three looping heroes for the home screen, one above each primary CTA. The whole hero is a tap target that does the same as the button below it.

| File | Home state | CTA | Loop | Reduced-motion still |
|---|---|---|---|---|
| `activate-download.json` | Ready to activate | Activate your eSIM | 3.4 s · 204 frames | frame 180 |
| `setup-toggles.json` | Ready to set up | Set up your eSIM | 3.4 s · 204 frames | frame 180 |
| `choose-destination.json` | Choose destination | Choose destination | 3.6 s · 216 frames | frame 184 |

All files: 60 fps, transparent background, `lottie` package.

## Size

The canvas is **152 × 152**: the 112 × 112 design box plus 20 units of padding on every side, because the finger and the falling pin move outside the box. Lay the hero out in a 100 × 100 pt box and let the animation overflow it:

```dart
SizedBox(
  width: 100, height: 100,
  child: OverflowBox(
    maxWidth: 135.7, maxHeight: 135.7,
    child: Lottie.asset('assets/lottie/activate-download.json', repeat: true),
  ),
)
```

## Reduced motion

When `MediaQuery.disableAnimationsOf(context)` is true, show the still frame from the table above and don't play the animation:

```dart
Lottie.asset(path, animate: false, controller: controller)
// controller.value = stillFrame / totalFrames  (e.g. 180 / 204)
```

## Partner colour

Every navy fill and stroke is named `primary`, including the tints, which carry their opacity separately. Recolour with a value delegate:

```dart
delegates: LottieDelegates(values: [
  ValueDelegate.color(const ['**', 'primary'], value: partnerPrimary),
  ValueDelegate.strokeColor(const ['**', 'primary'], value: partnerPrimary),
]),
```

The tints keep their opacity, so only the base colour changes. The phone shadow (`#8A8D98`) and the white fills stay fixed.

## Preview

Open `lottie-preview.html` in a browser. It plays all three JSON files and has replay, 0.25× slow-motion, 2× size and reduced-motion controls.
