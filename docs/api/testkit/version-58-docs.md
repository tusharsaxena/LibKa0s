# `testkit` — version 58

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/`, the files version 57 lists; no file added |
| Version | **58** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | unreleased (the release after v1.107.0) |
| Status | **Current** |
| Supersedes | [version 57](version-57-docs.md) — the skin-switch test passed a surface when any one setter moved, so a bar whose color followed the skin passed with a texture that never did, and the typed-value scanner read colors only in calls, escapes and `{ text, r, g, b }` rows |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `58` |

Everything revision 57 describes is unchanged here except what follows. Five files change:
`framework.lua` (`Kit.VERSION` is 58), `skin_switch.lua` and `test_skin_switch.lua` (SD-LK-97.18 and
the owner's U-5), `skin_values.lua` and `test_skin_values.lua` (SD-LK-97.19 and the owner's U-6),
and `README.md` describes them. The item ids are `SD-LK-GUARD` of Ka0sAddonsCommonTasks
`docs/2026-11-20-LIBKA0S_94_97_99_100/`, from the audit `docs/2026-11-20-SKIN_DEFAULTS_AUDIT/`
(LibKa0s#97: under any skin every skinnable element takes the skin's value by default).

## What changed

### The skin-switch test compares each setter family on its own (97.18, U-5)

Through revision 57 `compare` passed a surface as soon as any steady key differed between the home
draws and the probe draws. A StatusBar whose `SetStatusBarColor` read a token passed whatever its
texture did, which is the Combat Trail class of regression the audit found in four addons.

- **The families.** `W.FAMILY` maps each spied setter to `texture` (`SetStatusBarTexture`,
  `SetTexture`, `SetAtlas`, `SetBackdrop` and the button texture setters), `color` (`SetTextColor`,
  `SetColorTexture`, `SetVertexColor`, `SetGradient`, the two backdrop colors, `SetStatusBarColor`),
  `font` (`SetFont`, `SetFontObject`) or `shadow` (`SetShadowColor`, `SetShadowOffset`). `SetAlpha`,
  `SetDesaturated`, `SetText`, `SetFormattedText`, `AddLine` and `AddDoubleLine` are in no family:
  they count toward a surface changing at all, and are asked nothing on their own. `W.FAMILIES` is
  the report order: texture, color, font, shadow.
- **What has to move.** The noise floor is unchanged (a key the two home flips disagree on is
  dropped first). Then a family the surface drew has to move on its own: `color` always, `font` and
  `shadow` in the first pass only, because the second holds the owner's fonts ignored and a face
  stays put there by rule. `texture` is not asked by default, because a white base under a token
  tint is a correct texture that never moves. The cost: a plain Texture drawn from skin art (a
  background, a window art path) that stops following still passes on its tint unless its surface
  declares `expect = "texture"`, so every art-textured surface should declare it.
- **Every StatusBar's fill.** Each StatusBar the surface holds (an object whose `GetObjectType`
  answers `"StatusBar"`, or a stand-in with no `GetObjectType` that has `SetStatusBarTexture`) has
  to draw its fill on a switch and move it. The fill is read off the bar's `SetStatusBarTexture` and
  off `SetTexture` or `SetAtlas` on the Texture its `GetStatusBarTexture` answers, which the spy now
  walks (part c): a host that draws `bar:GetStatusBarTexture():SetTexture(path)` is read. A bar's
  fill is `bar.texture`'s place under every skin, the same reading the typed-value scanner gives a
  path in `SetStatusBarTexture`.
- **A string with a moving face and no color.** An object that is a FontString or an EditBox (or a
  stand-in with `SetTextColor` and no `GetObjectType`) whose `font` keys moved while no
  `SetTextColor` reached it on any of the compared flips is reported: the skin's face over the
  client's color. A `SetFontObject` (a font object carries its own color) or a `SetText` /
  `SetFormattedText` whose text carries a `|c` escape counts as a color set, so a host coloring a
  string either way is not flagged.
- **The messages.** `"<surface> did not change its <family> on a skin switch (<setters> drew the
  same under the probe), while its <families> moved: each family follows the skin on its own"`;
  `"<surface> holds a StatusBar whose texture did not change on a skin switch (...)"` and `"... that
  drew no texture on a skin switch"`; `"<surface> drew no texture on a skin switch, and it expects
  one"`; `"<surface> holds a string whose face follows the skin while its color is never set on a
  switch (no SetTextColor, SetFontObject or |c escape) ..."`. The revision-50 messages for a surface that changed nothing are
  unchanged.

### Three optional surface fields (97.18 c, d)

| Field | Meaning |
|---|---|
| `expect` | A family name or a list of them. Each must be drawn on a switch **and** move. `expect = "texture"` is the declaration for a data fill drawn on a Texture (`S.BarTexture` on a Texture, a Charts bar row, a `W.Bar`): the default asks no Texture path to move |
| `hold` | A family name or a list of them a ruling keeps fixed on this surface: left out of the per-family check (and `hold = "texture"` leaves the StatusBar fill check out, `hold = "color"` the colorless-face check). The surface still has to change at all |
| `clear` | `true`: a StatusBar drawn clear (its `GetAlpha()` 0, or the alpha `GetStatusBarColor` answers 0) is left out of the fill check. A bar that is a value holder under a Texture the host draws over it |

`W.factsProblems` rejects an `expect` or `hold` that is not a known family name or a non-empty list
of them, a family named in both `expect` and `hold` (`"surface ... names ... in both expect and
hold"`: a family is asked to move or held fixed, never both), and a `clear` that is not a boolean.

### The library declares its own surfaces (97.18 a, e)

LibKa0s's `tests/fixture_skin_switch.lua` (this repo only, not the kit) installs a LibSharedMedia
fake answering every shipped skin's `bar.texture`, `font.body`, `font.title`, `font.mono` and
`hud.font` key with a path of its own. With none, `P.media` resolved no bar texture under any skin,
so `BarTexture` painted `WHITE8X8` under all of them and a bar that stopped following could not be
told from one that followed. The fixture declares six library surfaces beside its three: a Bar and a
Charts bar row (each `expect = "texture"`), a TestStrip, a Footer, a DragHandle and a Dropdown row.

### The typed-value scanner reads the shapes a color is kept in (97.19)

| Shape | Reported | Not reported |
|---|---|---|
| `table` | a table constructor of exactly three or four components (`local NORMAL = { 1, 0.82, 0 }`), a trailing separator allowed, over several lines too | two numbers, a number above 1 or below 0 |
| `keyed` | `{ r = .., g = .., b = .. }`, an `a` allowed, each a component (`C.MESSAGE = { r = 0.2, g = 0.75, b = 0.3 }`) | any other key in the table |
| `assign` | three or four names assigned three or four components in one statement on one line (`local LINE_R, LINE_G, LINE_B = 1, 0.82, 0`), when a value is a fraction or the names end r, g, b (and a); a name ending in a digit or an underscore (`u1`, `x_`) ends in no channel letter | whole numbers to names that are no channels (`local rows, named, done = 0, 0, 0`, `local u1, v1, u2, v2 = 0, 0, 1, 1`) |
| `return` | a `return` of three or four components with a fraction or a 1 among them (`return 0.45, 0.45, 0.5`, `return 1, 1, 1`), every `return` on the line read | `return 0, 0, 0` |
| `call` | `RGBA(c, r, g, b, a)` with a literal at 2, 3 or 4 (`NS.RGBA(stored, 0.35, 0.55, 0.85, 1)`), through `V.GLOBAL_COLOR_ARGS`, which now carries `CreateColor` too | `RGBA(c, dr, dg, db, 1)` |

A component is a numeric literal from 0 to 1. Two new color categories take only these new shapes,
never a call, so no host row written against revision 57 goes stale: **`tex coords, inset or
padding`** (the code on the line, its comment cut, names `coord`, `crop`, `inset`, `pad`, `margin`
or `offset`, in any case, in a name or a string: `{ 0.07, 0.93, 0.07, 0.93 } -- texcoord` is still a
color hit, `ICON_COORDS = { 0.07, 0.93, 0.07, 0.93 }` is not) and **`fully clear color`** (a `table` whose fourth component, or a `keyed` table whose
`a`, is a literal 0). The existing categories read the new shapes as they read a call: a meaning
color table, a chat line and the rest.

### Kit row categories (U-6)

`V.ROW_CATEGORIES` names what a host row may give in `category` **instead of** a `cause`, for a value
that draws no look and so has no ruling of its own to cite:

| Category | For |
|---|---|
| `"unreachable default"` | a channel default no player sees (`stored.r or 1` where a load backfill fills every channel first) |
| `"white base for tinting"` | white a host's own helper tints, which the kit category of the same name cannot see (it reads a tint on the same object in the same file) |
| `"not a color"` | three or four fractions the scanner reads as a color that are something else, a position, a scale or a weight (`local x, y, s = 0.5, 0.5, 0.8`), on a line that names none of the geometry words the `tex coords, inset or padding` category reads |

A row carries a `cause` id or a `category`, never both; a `category` the kit does not name fails and
the message lists the ones it has. A row with neither fails as before (`has no cause`).

## What a consumer owes

Re-vendor the kit with the library, per `docs/releasing.md`, and run the full suite. **The new checks
may turn a consumer red; that is the point**, and LibKa0s's own suite is green on them. What can
fail, and what to change:

1. **`test_skin_switch`: a family that does not move.** A surface whose color, face or shadow is
   drawn the same under the probe while another family moves. Read the family from the message.
   Fix the paint to read the token; where a ruling keeps it (a meaning color, an owner OVERRIDE),
   declare `hold = { "<family>" }` on that surface and cite the ruling beside it.
2. **`test_skin_switch`: a StatusBar's texture.** Every StatusBar a declared surface holds must draw
   its fill on a switch and move it. Paint it through `S.BarTexture` / `S.ApplyBarFill` (which repaint
   on a switch), or repaint it in the surface's `paint`. A bar drawn clear (alpha 0) under a fill the
   host draws itself: declare `clear = true`, and declare the drawn fill as its own surface with
   `expect = "texture"`.
3. **`test_skin_switch`: a string with no color.** A FontString whose face follows the skin while no
   `SetTextColor`, `SetFontObject` or `|c` escape in its text reaches it on a switch: give it a token
   color on the same repaint. `hold = "color"` turns this check off with the color family's, so it is
   for a string whose color a ruling holds, not a way past a missing color.
4. **New declarations.** A surface that paints a data fill on a Texture should say `expect =
   "texture"`, or a fill that stops following passes on its tint (the audit's BankLedger, LootHistory,
   MultiMeters and OutfitterReborn rows).
5. **`test_skin_values`: new hits.** A color kept in a table, a keyed table, a multi-assignment, a
   `return` or an `RGBA` fallback default is now a hit. Read the token instead, or add a row with its
   `why` and `cause` (or a kit row `category`). Option defaults (`default = { r = .., g = .., b = .. }`)
   are the ruling R-2 case: the default follows the skin, through a FollowOnce key list where a
   stored value equal to the old default must move.
6. **The new category.** A row that borrowed a cause id for bookkeeping (Aura Master's A7 on
   `normal.r or 1`, the Skin Tester's A5 on the NavItem's white base) moves to `category =
   "unreachable default"` / `"white base for tinting"` and drops its `cause`. A new hit on three or
   four fractions that are no color (a position and a scale) takes `category = "not a color"`.
