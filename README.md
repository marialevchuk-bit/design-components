# Hubby eSIM — Design System

The Hubby app's visual conventions, translated out of the design-system overview
into a **reusable, enforceable system**: design tokens plus a component library
that future designs build on. Use these files and a new screen inherits Hubby's
conventions by construction — spacing, colour, type, radii, states and partner
theming all come for free.

## What's here

| File | What it is |
|------|------------|
| [`tokens.css`](./tokens.css) | **The source of truth.** Every colour, type style, spacing step, radius, stroke and shadow as a CSS custom property. Token names match the shipping Flutter code verbatim. |
| [`components.css`](./components.css) | **The component library.** Button, input, search, card, badge, status pill, bottom sheet, dialog, bottom nav, snackbar, skeleton, progress — built strictly from the tokens as `hy-*` classes. |
| [`fonts/`](./fonts) | **GeneralSans** — the shipping typeface, weights 400/500/600 as WOFF2 (~24 KB each). Loaded by `tokens.css` via `@font-face`. |
| [`index.html`](./index.html) | **The living styleguide.** Renders the real components (not mockups) and documents all conventions. Open it in a browser; switch partners live. |
| [`animations/`](./animations) | **Motion prototypes + Flutter handoff specs.** Interactive, token-bound animation references for the dev team. First up: the eSIM-activated success animation. |

## The five rules (do not break these)

1. **Brand is a variable, not a value.** `--brand` defaults to Hubby orange `#FF8800`; every partner overrides it at runtime. Bind buttons, pills, badges, progress fills and the nav to `--brand` / `--brand-soft` / `--brand-pressed`. Never paint a brand hex.
2. **No dark mode.** One light theme. A dark variant is new design work, not a port.
3. **One button, three variants.** 52px · 10px radius · 18/500 label. Filled, outlined, soft — nothing else.
4. **Flat, with one exception.** Only dialogs and bottom sheets cast a shadow.
5. **Touch only — no hover.** States are pressed, focused, disabled. Hover is deliberately off.

## Using it

```html
<link rel="stylesheet" href="tokens.css">
<link rel="stylesheet" href="components.css">

<!-- Components inherit every convention. -->
<button class="hy-btn hy-btn--filled">Buy now</button>
<span class="hy-status hy-status--success"><span class="hy-status__dot"></span>Connected</span>
```

Building custom UI? Reach for the tokens rather than raw values:

```css
.my-thing {
  background: var(--surface);
  border: 1.2px solid var(--border);
  border-radius: var(--radius-14);   /* default card */
  padding: var(--space-16);
  font: var(--bodyS500);             /* the workhorse text style */
}
```

## Partner theming (white-label)

The whole point of `--brand` being a variable: re-skin any subtree by overriding
the brand tokens on a wrapper. Nothing else changes.

```html
<div class="partner-a">     <!-- #1F6FEB -->
  <button class="hy-btn hy-btn--filled">Buy now</button>  <!-- now blue -->
</div>
```

Add a partner by copying the `.partner-a` block in `tokens.css` and swapping the
five brand values. The styleguide's partner switcher shows it live.

## Token groups

- **Brand** — `--brand`, `--brand-pressed`, `--brand-soft`, `--brand-selected`, `--on-brand` (all overridable).
- **Surfaces & borders** — `--background`, `--surface`, `--border`, `--borderStrong`, `--skeleton`, `--staticSecondaryColor`.
- **Grayscale** — `--grayscale100…900` + role aliases (`--textPrimary`, `--textSecondary`, `--textHint`, `--textDisabled`, `--hairline`).
- **Semantic** — `--success` / `--danger` / `--staticGreen` (+ `light*`), and three `--status*` ramps (bg / border / dot / text — never mixed).
- **Type** — `--font` (GeneralSans), the named styles (`--title1…7`, `--bodyXL400…bodyXXS400`, `--labelM/S`, `--dataMeterText`, `--usageNumber`) and five tracking values.
- **Spacing** — `--space-2…32` (core 4/8/12/16/24/32), plus `--size-button`.
- **Shape** — `--radius-4…24` + `--radius-pill`, and six `--stroke-*` widths.
- **Elevation** — `--shadow-soft` / `-sheet` / `-strong` and `--ring`.

## Figma

Mirror the token names one-to-one as Figma variables. Model the brand as **one
variable with a mode per partner**; set line-height as a **percentage**, not px,
so the tier rule holds. See section 09 of the styleguide.

## Notes & stand-ins

- Reconstructed from **Flutter build v2.12.0**. Where a specimen disagrees with a
  screenshot, the tokens are right.
- **GeneralSans** is bundled in `fonts/` (weights 400/500/600, no italic — the
  only weights the scale uses) and loaded by `tokens.css`. `--font` keeps a
  system-sans fallback for the brief moment before it loads.
- Icons here are inline placeholders for layout. New brandable icons must draw
  their adaptive shapes in `#23262f` (swapped for the partner colour at load);
  two-tone icons keep a fixed `#ededed` backing.
