# Skin mockups

Design reference for the LibKa0s skin engine, drawn on 2026-10-25 before any skin code existed. Nothing
here ships to the client: these are browser pages, kept so a later change to a skin can be checked
against the look it was meant to have.

Every mockup draws the same surfaces in each skin: a window (title bar, close button, tabs, search box,
dropdown, buttons, table, scrollbar, footer), a LibKa0s settings page (nav rail, heading, checkboxes,
slider, dropdown, color swatch, drawer), a confirm dialog, a tooltip and a HUD meter.

## The files

| File | What it is |
|---|---|
| [`skins-mockup.html`](skins-mockup.html) | The standalone page. Open it in a browser and click a skin card to repaint every surface. |
| [`canvas/`](canvas/) | The Design-canvas sources the standalone page was flattened from: one `.dc.html` board per skin, `Main.dc.html` (the skin picker), `Preview.dc.html` (the shared surfaces) and `canvas.json` (board layout and titles). They need the canvas runtime (`support.js`, not included) and do not render on their own. |

The standalone page loads its fonts from Google Fonts, so it needs a browser with network access. The
fonts are web stand-ins for the in-game ones, and WoW has no blur, so Glass is translucency only.

The original canvas is https://claude.ai/artifact/Dt32859dvnj1cCWoUkadzj. It is private to the owner.

## The nine skins

| Skin | Look |
|---|---|
| Ka0s Default | Today's look: slate, gold, Blizzard buttons. |
| Obsidian | Flat and quiet, one blue accent. |
| Azeroth | Parchment and leather, like a quest log. |
| Glass | Translucent panels over the world. |
| High Contrast | Black, white and yellow, with larger text. |
| Ember | Charcoal and brass with a fire accent. |
| WoW Default | The vanilla 1.12 look: stone, steel trim, red buttons. |
| WoW Midnight | Night blue, Sunwell gold, void violet. |
| WoW Forever | The EllesmereUI-on-WoW-Forever look: warm charcoal, black title bars, tan accent. |

The page also shows an EllesmereUI board. That one is not a Ka0s skin: it approximates EllesmereUI's
Modern style, and in the client EllesmereUI paints it itself.

## From mockup to code

The token tables in the page's script (one table of colors, fonts and borders per skin) were the starting
point for `LibKa0s/SkinDefs.lua`. The page's own caption says `LibKa0s/Skins/*.lua`, the layout
planned when it was drawn; the skin engine keeps every definition in that one file instead. Where the
mockup and the code disagree, the code wins, and the mockup is not updated to follow it.
