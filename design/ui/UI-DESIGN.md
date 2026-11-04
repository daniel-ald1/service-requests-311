# UI Design Tokens — service-requests-311

> I keep every chart and the Tableau dashboard on these tokens so the
> project reads as one piece. No invented employers, no real persons.

## Palette

| Token    | Hex       | Use                          |
|----------|-----------|------------------------------|
| `bg`     | `#F6F8FA` | Figure / app background      |
| `card`   | `#FFFFFF` | Axes / card background       |
| `ink`    | `#1B2A3A` | Titles, annotations          |
| `muted`  | `#5B6B7A` | Axis labels, tick labels     |
| `grid`   | `#E2E8F0` | Y-gridlines, bottom/left spines |
| `accent` | `#2563EB` | Monthly line, top-type bars  |
| `accent-2` | `#0EA5E9` | Secondary highlights      |

## Priority colors (fixed order Low → Critical)

| Priority | Hex       |
|----------|-----------|
| Low      | `#94A3B8` |
| Medium   | `#38BDF8` |
| High     | `#F59E0B` |
| Critical | `#DC2626` |

## Typography

- Family: Segoe UI, fallback Inter, fallback DejaVu Sans.
- Title: 15pt, semibold, `ink`, left-aligned.
- Axis labels / ticks: 10.5pt, `muted`.
- Annotations / bar value labels: 10pt, semibold (annotations in
  `ink`, in-bar labels in white centered on the bar).

## Chart rules (matplotlib)

- Figure size 12 × 6.75 in, saved at 150 dpi → 1800 × 1012 px.
- Figure facecolor `bg`, axes facecolor `card`.
- Y-grid only: `grid` at 0.8pt, `set_axisbelow(True)`.
- No top/right spines; left/bottom spines in `grid`.
- Monthly line: `accent`, 2.5pt, circle markers with `card` edge,
  peak + valley annotated.
- Top-type bars: `accent`, sorted desc, white centered value labels.
- Priority bars: Low → Critical order with the four hexes above,
  white centered value labels.
- Titles never use the word "Synthetic".

## Tableau

- I mirror these tokens in `tableau/dashboard.twb` (dashboard 1600 × 900):
  light background, blue trend line / bars, the four priority hexes,
  muted axis text. See `tableau/TABLEAU-CONNECT.md` to open it.
