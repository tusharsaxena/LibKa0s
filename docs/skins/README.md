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

## In-game screenshots

[`screenshots/2026-10-26-leg1/`](screenshots/2026-10-26-leg1/) holds the owner's screenshots from the
leg-1 smoke test (LibKa0s v1.78.0 at `7bc3e9b`, Ka0s Loot History as the only adopter). There is one
pair per skin:

- `NN-<skin>-window.png` is the Loot History window on its History tab.
- `NN-<skin>-settings.png` is the settings panel open on General → Appearance.

Unlike the mockups above, these show what the code actually draws. The owner's notes from the same
round (2026-10-26) are in the table.

| # | Skin | Owner's notes, round 1 |
|---|---|---|
| 01 | Ka0s Default | — |
| 02 | Obsidian | Too close to Ka0s Default; darken it. |
| 03 | Azeroth | The title font is hard to read, the tabs do not work, and the parchment is too bright; mute it. |
| 04 | Glass | Too transparent; the buttons and tabs look awkward. |
| 05 | High Contrast | The borders are too thick on most elements. |
| 06 | Ember | — |
| 07 | WoW Default | — |
| 08 | WoW Midnight | The buttons are not Midnight-themed. |
| 09 | WoW Forever | — |
| 10 | EllesmereUI | EllesmereUI painting the addon itself (skin source EllesmereUI), for comparison. |
