# eSIM home hero animations — handoff

Two looping illustrations used on the home screen above the primary CTA:

| Animation | Home state | CTA under it | Tap target |
|---|---|---|---|
| **activate-download** | Ready to activate (K1, W1) | "Activate your eSIM" · download icon | Opens the activation walkthrough |
| **setup-toggles** | Ready to set up (K2, W2) | "Set up your eSIM" · toggle icon | Opens the settings walkthrough |

Each folder contains:

- `*.html` — **source of truth.** Open in a browser to see the exact motion. The SVG and its CSS are inline.
- `animation.css` — the keyframes on their own, prettified.
- `*.svg` — static geometry only (layer ids, paths, transforms). It does not animate on its own.

---

## Shared

- **Canvas:** 112 × 112 viewBox, rendered at **100 × 100 pt**. `overflow: visible` (the finger slightly overshoots the ring).
- **Loop:** **3.4 s**, infinite. Every element runs on the same clock.
- **Easing:** `cubic-bezier(0.4, 0, 0.2, 1)` on every keyframe (Flutter: `Curves.fastOutSlowIn`).
- **Colour:** everything is the partner primary. Hubby: `#0A0F24`. Tints are the primary at fixed opacity. The only exception is the phone shadow, `#8A8D98`.
- **The whole illustration is tappable** and does the same as the CTA below it.

### Layers (bottom → top)

| Layer | Geometry | Style |
|---|---|---|
| Backdrop disc | circle r50 at (56,56) | primary @ 7 % |
| Ring track | circle r50, stroke 2.5 | primary @ 12 % |
| Ring progress | circle r50, stroke 2.5, round cap, dasharray 314, starts at 12 o'clock (rotate −90°) | primary |
| Phone shadow | rounded rect 30×52 r6.5, offset +3.5 y | `#8A8D98` |
| Phone | rounded rect 30×52 r6.5, stroke 2.2 | fill white, stroke primary |
| Screen | 24×45 r3.5, clipped | primary @ 4 %, glow layer primary @ 10 % |
| Screen content | see per-animation | primary |
| Finger | pointing-hand path, scale 1.15 | white fill, primary stroke 1.3 |

The phone lies flat. Apply this transform to the phone, its shadow and everything on its screen: `translate(56, 64) · scale(1, 0.5) · rotate(−36°)`. Screen strokes use `vector-effect: non-scaling-stroke` so they keep their weight under the squash. In Flutter, apply the matrix to the canvas and divide stroke widths by the scale, or draw in screen space.

---

## 1 · activate-download

Story: the finger taps the phone once, a download arrow drops into the screen, a progress line fills, a tick appears, and the ring closes around it all. Then everything fades out and the loop restarts.

Times are ms from loop start (3400 ms = 100 %).

| Element | Keyframes |
|---|---|
| Finger | 0 enters from (+12, +14), opacity 0 → 204 opacity 1 → 612 at rest → 748 press (scale 0.93, +1 y) → 884 release → 918 gone |
| Tap ripple (r7, stroke 1.8) | 714 scale 0.3, opacity 0 → 816 opacity 0.9 → 1292 scale 1.6, opacity 0 |
| Screen glow | fade in 748 → 952, hold to 3128, out by 3298 |
| Ring track | fade in 952 → 1088, hold to 3060, out by 3298 |
| Ring progress | dashoffset 314 → 0 from 1088 to 2652, hold to 3060, fade out by 3298 |
| Download arrow | 1020 at −9 y, opacity 0 → 1224 opacity 1 → 2040 lands at +1 y → 2244 fades |
| Progress line (16 wide, stroke 2, butt cap) | fills left → right 1020 → 2652, hold to 3060, fade out by 3298 |
| Done tick (r7 disc + white check) | 2584 scale 0.6, opacity 0 → 2788 scale 1.08 → 2924 scale 1 → hold to 3128 → out by 3298 |

**Reduced motion:** static final frame. Ring full, progress line full, tick and glow visible; finger, ripple and arrow hidden.

---

## 2 · setup-toggles

Story: the same flat phone shows two settings rows (This Line, Data Roaming). The finger taps the first toggle, then the second, and each switches on. The ring closes and the loop fades out.

| Element | Keyframes |
|---|---|
| Finger | 0 enters from (+12, +14), opacity 0 → 204 opacity 1 → 544 over toggle 1 → 646 press (0.93) → 748 release → 1020 moves to toggle 2 (+6.5, +4.5) → 1122 press → 1224 release → 1496 hold → 1530 gone |
| Toggle 1 knob / fill | switches on 646 → 850 (knob +4 x, fill 0 → 1), holds to 3128, resets by 3298 |
| Toggle 2 knob / fill | switches on 1122 → 1326, holds to 3128, resets by 3298 |
| Screen glow | fade in 544 → 680, hold to 3128, out by 3298 |
| Ring track | fade in 612 → 748, hold to 3060, out by 3298 |
| Ring progress | dashoffset 314 → 0 from 748 to 2652, hold to 3060, fade out by 3298 |

Toggle geometry: label line 7 wide (primary @ 35 %, stroke 1.8), track 9×6 r3 (primary @ 14 %), fill 9×6 r3 (primary), knob r2.1 white with a 1 pt primary stroke. The rows sit at y −7 and y 4 in screen space.

**Reduced motion:** static final frame. Ring full, both toggles on, glow visible, finger hidden.

---

## Implementation options (Flutter)

1. **Hand-coded (recommended):** one `AnimationController(duration: 3400 ms)..repeat()`, one `CustomPainter` per hero. Drive each element with an `Interval(start, end, curve: Curves.fastOutSlowIn)` built from the tables above. Use `MediaQuery.disableAnimations` for the reduced-motion frame.
2. **Lottie:** rebuild in After Effects from the HTML and export with Bodymovin. It's more convenient, but it adds a dependency and makes partner recolouring harder. A hand-coded painter can take the partner primary as a parameter.

Either way, the colour **must** come from the partner theme. Nothing is hard-coded except the shadow grey.
