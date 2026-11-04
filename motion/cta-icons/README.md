# eSIM call-to-action icons

Looping icon animations for the eSIM buttons: three rebuilt from the approved
video, plus the Top up button. Button, pill and motion are measured from the video frame by frame; the
typeface is GeneralSans. After review the motion was slowed down, each loop
now plays every 30 seconds, and the icons are 20px instead of 18px.

| File | For |
|------|-----|
| `prototype.html` | Interactive prototype: each button on its own or all four together, replay, 0.25x, reduced motion, zoom, timeline scrubber. Self-contained (fonts inlined). |
| `spec.txt` | The animation spec for developers: loops, phases, durations, curves, reduced motion, button measurements. |
| `cta_icon_animations.dart` | Flutter reference: `EsimCtaButton` plus `DownloadDropIcon`, `ToggleSwitchIcon`, `ZapChargeIcon` and `PlusIcon`, painted in code. |
| `prototype.src.html`, `build.py` | Source of the prototype. Edit the source, then run `python3 motion/cta-icons/build.py`. |

| Button | Icon motion | Loop |
|--------|-------------|------|
| Activate your eSIM | Arrow sinks through the tray and glides back into place, then still | 30 s |
| Set up your eSIM | Toggle switches on, holds, switches off, then still | 30 s |
| Connect eSIM | Bolt retracts, redraws from the top, pulses gently twice, then still | 30 s |
| Top up | Three options to pick from: Draw, Pop or Rise, then still | 30 s |
