# Claude Design System

A design language for Claude — warm, calm and human. This repo is the source of
truth for colour, type, spacing, shape, elevation, motion and components, built
in the format of a single reference page plus reusable tokens.

## What's here

| File | What it is |
|------|------------|
| [`index.html`](./index.html) | **The source-of-truth page.** A self-contained specimen document — open it in a browser. Covers all 11 sections (Read this first → Figma mapping) with live component demos and a light/dark toggle. |
| [`tokens.css`](./tokens.css) | **The design tokens** as CSS custom properties, with full `light` and `dark` themes. Import this into any web surface and build against the variables. |

## The five decisions

1. **The canvas is warm, not white** — ivory `#FAF9F5` with cream `#F0EEE6` panels; pure white only for raised surfaces.
2. **One accent: clay** — the coral `#D97757` carries every primary action, and nothing else competes with it.
3. **Claude speaks in serif, the UI speaks in sans** — answers and reading copy are serif; all chrome is a grotesque sans.
4. **There is a dark mode** — a warm charcoal, never pure black; every token has a light and a dark value.
5. **Quiet by default, soft when it lifts** — flat surfaces with hairline borders; only menus, dialogs and toasts cast a soft, warm shadow.

## Using the tokens

```html
<link rel="stylesheet" href="tokens.css">
```

```css
.primary-button {
  background: var(--clay);
  color: var(--on-clay);
  border-radius: var(--radius-10);
  padding: 0 var(--space-20);
  font: var(--body-strong);
}
.primary-button:hover { background: var(--clay-hover); }
```

Theme is driven by a `data-theme` attribute on `:root` (`light` or `dark`); with
no attribute set it follows the OS via `prefers-color-scheme`.

```html
<html data-theme="dark"> … </html>
```

## Token groups

- **Colour** — surfaces (`bg`, `bg-panel`, `surface`, `surface-sunken`), borders, ink (`text` → `text-faint`), primary (`clay` + states/tints), decorative earth (`kraft`, `manilla`), and muted semantics (`success` / `danger` / `warning` / `info`, each with `-soft` and `-border`).
- **Type** — two families (`--serif`, `--sans`) plus `--mono`, and 12 composed styles (`--display1` … `--code`). Reading copy is serif; UI is sans.
- **Spacing** — a 4-based scale, `--space-2` … `--space-64`.
- **Shape** — `--radius-6` … `--radius-24` + `--radius-pill`, and four stroke widths.
- **Elevation** — `--shadow-soft` / `-raised` / `-overlay` and the clay `--focus-ring`.

## Building it in Figma

Mirror the token names one-to-one as Figma variables, and model the theme as a
**variable mode** (light / dark) on a single collection — not two component
sets. See section 11 of `index.html` for the full mapping.

## Status & stand-ins

This is `v1.0`. Two things are placeholders pending the real assets:

- **Typefaces** — specimens render in **Fraunces** (serif) and **Hanken Grotesk**
  (sans) as open stand-ins for the licensed Tiempos/Copernicus + Styrene faces.
  The token names describe the intent; swap the font files when licensed.
- **The mark** — the sunburst asterisk is a functional stand-in for layout and
  spacing. Replace it with the official trademarked artwork before shipping.

Adapted in structure from the Hubby eSIM design-system reference format; all
colour, type and component values express Claude's own visual language.
