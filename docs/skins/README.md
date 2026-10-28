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

The screenshots live in `media/screenshots/skins/`, one folder per iteration of the skins, numbered in
order: `v1`, `v2`, and the next set is `v3`. A set of the Skin Tester's showroom lives in this
repository, in `media/screenshots/skins/vN/SkinTester/`; a set of an addon's own window lives in that
addon's repository, under the same `media/screenshots/skins/vN/`.

[`v1/`](../../media/screenshots/skins/v1/) holds the owner's screenshots from the
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

[`v2/`](../../media/screenshots/skins/v2/) holds the owner's screenshots after the fifth round of skin notes
(2026-10-28, LibKa0s v1.78.0 at `b2f6ec6`), which the owner called the skins looking great, each
cropped to the window:

- [`v2/SkinTester/`](../../media/screenshots/skins/v2/SkinTester/): the Skin Tester's showroom, every element a skin
  paints, with its showcases in [`showcase/`](../../media/screenshots/skins/v2/SkinTester/showcase/).
- Loot History's History tab in the same nine skins, with its own `showcase/`, is in the
  LootHistory repository at `media/screenshots/skins/v2/`.

Each crop is `NN-<skin key>.png`, numbered in the order `SkinDefs.lua` registers the skins. Each set's
`showcase/` folder has every skin at a glance, seven ways, each as a PNG and a JPEG, every skin under a
label with its name and swatches:

| Showcase | What it shows |
|---|---|
| `standalone` | Every window on its own, in a grid. |
| `fan` | A hand of cards around a pivot below: Ka0s Default flat in the centre and in front, the rest tilting away behind it. |
| `staircase` | One cascade from the top left to the bottom right, Ka0s Default in front. |
| `hero` | Ka0s Default large on top, the other skins in a grid below it. |
| `coverflow` | Ka0s Default flat in the centre, the others turned away in perspective on both sides. |
| `slices` | One window cut into slanted bands, each band a different skin. |
| `deck` | One row fanned out to the right like a spread deck, Ka0s Default in front at the left. |

All seven sit on the dark Slate background, lit a little behind the windows, with a faint light rim on
each window so the near-black skins stand out. They are drawn at the crops' own resolution (the Skin
Tester's standalone is 3778×2910), so scale them down for wherever they go.

## Making a new set

`tools/skin_gallery.py` does the cropping and the showcase for any addon. Take one screenshot of the
same window per skin, then, from this repository's root, write the set to the next free `vN`:

```sh
# the Skin Tester's showroom, kept here
python3 -P tools/skin_gallery.py --title "Ka0s Skin Tester" \
    --out media/screenshots/skins/v3/SkinTester  shot1.png ... shot9.png
# an addon's own window, kept in that addon's repository
python3 -P tools/skin_gallery.py --title "Ka0s Loot History" \
    --out ../LootHistory/media/screenshots/skins/v3  shot1.png ... shot9.png
```

The screenshots go in `SkinDefs.lua`'s order (Ka0s Default first); or put them in one folder named
`<skin key>.png` and pass `--dir` instead. The skins, their order and their labels are read from
`SkinDefs.lua`, so a new or renamed skin needs no change to the script: run it again with one more
screenshot. `--skins obsidian,glass` shoots a subset, `--no-crop` keeps screenshots already cropped,
`--from-crops` rebuilds only the showcases from a set's own crops, `--cols` sets the standalone grid's
columns, `--layouts fan,hero` builds only some of the showcases, and `--bg plum` or `--bg graphite`
swaps Slate for one of the two other dark grounds. The crop finds the window's outermost straight edges, so
leave a little of the world showing on every side; a skin with rounded corners (Glass) keeps a few
pixels of world in its corners.
