# eSIM call-to-action icons

Looping icon animations for the three eSIM buttons, rebuilt from the approved
video. Button, pill and motion are measured from the video frame by frame; the
only change is the typeface, GeneralSans.

| File | For |
|------|-----|
| `prototype.html` | Interactive prototype: each button on its own or all three together, replay, 0.25x, reduced motion, zoom, timeline scrubber. Self-contained (fonts inlined). |
| `spec.txt` | The animation spec for developers: loops, phases, durations, curves, reduced motion, button measurements. |
| `cta_icon_animations.dart` | Flutter reference: `EsimCtaButton` plus `DownloadDropIcon`, `ToggleSwitchIcon` and `ZapChargeIcon`, painted in code. |
| `prototype.src.html`, `build.py` | Source of the prototype. Edit the source, then run `python3 motion/cta-icons/build.py`. |

| Button | Icon motion | Loop |
|--------|-------------|------|
| Activate your eSIM | Arrow drops through the tray and falls back into place | 1800 ms |
| Set up your eSIM | Toggle switches on, holds, switches off | 2400 ms |
| Connect eSIM | Bolt retracts, redraws from the top, pulses twice | 2600 ms |
