# No-eSIM flow: onboarding animations (Lottie)

The three onboarding animations from **Webapp redesign · FLOW · NEW CUSTOMER WITHOUT AN ESIM**, rebuilt as Lottie from the design file's CSS keyframes.

| File | Screen | Canvas | Length | Playback |
|---|---|---|---|---|
| `1-esim-intro.json` | What is an eSIM? (pulsing SIM) | 200 × 200 | 2.4 s @ 60 fps | loop |
| `2-choose-data-plan.json` | Choose your data plan (globe, pin, plan chips) | 264 × 211 | 2.5 s @ 60 fps | once, hold last frame |
| `3-three-steps.json` | Three steps to get online (journey timeline) | 342 × 209 | 2.5 s @ 60 fps | once, hold last frame |

- Text is outlined Inter, so no fonts need to be bundled.
- The intro art is 170 px in the design; the canvas is 200 px so the 1.4× pulse isn't clipped (offset it by −15 px).
- `preview.html` plays all three (it loads lottie-web from cdnjs and fetches the JSON files next to it).
- `tools/` holds the generator: `fragments.py` is the CSS reference rebuild, `make_lottie.py` writes the JSON.
