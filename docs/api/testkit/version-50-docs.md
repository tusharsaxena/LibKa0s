# `testkit` — version 50

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/`, the files version 47 lists, plus `skin_values.lua`, `skin_switch.lua`, `test_skin_values.lua` and `test_skin_switch.lua` |
| Version | **50** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.85.0 |
| Status | **Current** |
| Supersedes | [version 49](version-49-docs.md) — the same surface, with two new kit suites |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `50` |

Everything revision 49 describes is unchanged here except what follows.

## What changed

### `skin_values.lua`, `test_skin_values.lua`: the typed-value gate (`FS-GATE`)

The hard-coded color gate eight addons each carried as `tests/test_skin_literals.lua`, 61 allow entries between them and colors only, generalized and shipped. It keeps their three behaviors: a stale allow row fails, no git fails, and a planted literal of each shape proves the check on every run.

It now reads textures too: a client path in a string, under `Interface\` or `Fonts\`, and a literal handed to a texture or atlas setter, whether a path, a name or a file id. It adds `SetStatusBarColor` and `SetShadowColor` to the color calls, and DpsRace's `{ text, r, g, b }` row shape, for components from 0 to 1. A real lexer replaces the line-cutting of the copies, so a block comment and a `)` in a string read correctly.

`V.scan(src, { path, calls })`, `V.collect(opts)`, `V.judge(sources, opts)`, `V.rowProblems(rows)` and `V.pathCategory(path)` are the module. `V.SCOPE`, `V.COLOR_ARGS`, `V.TEXTURE_SETTERS`, `V.PATH_RULES`, `V.COLOR_RULES` and `V.TEXTURE_RULES` are the tables.

The kit-shared categories, so a host types none of them:

| | Category |
|---|---|
| By file | the seam `core/SkinSetup.lua`; `defaults/`, the companion-off look; `locales/` |
| Colors | chat lines (L13); hyperlink and quality colors; escape builders and `\|c` search patterns; locale strings; meaning color tables; neutral 1,1,1 resets; white bases for tinting; StaticPopup text |
| Textures | spell and item icons; L10 art; A6 Blizzard art, with D9's resize grip; the white base; degraded or ignored-panel stock paths; L12 mono; LSM picks and client defaults; the Ace profile page; `media/` paths |

An alpha literal over token components is no hit at all. A category reads what the line says and stops there: a client default counts only in a fallback's shape, so `bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")` is a hit and `C.FALLBACK_TEXTURE = ...` is not; white text is a hit and a 1,1,1 vertex reset is not; a meaning table is one whose name holds both a meaning word and a color word, as whole words, so `STATUS_COLORS` and `BROADCAST_COLOR` are none.

Some categories ask for more than a path or a shape:

- **White for tinting.** `SetColorTexture(1, 1, 1, a)` and a setter handed `WHITE8X8` count only when `SetVertexColor`, `SetGradient` or `GetXTexture():SetVertexColor` on that object's last name follows in the file. White nothing tints is white under every skin. A tint a host's helper does is a row's to name. A `WHITE8X8` that is only a name, a constant or a backdrop field stays a tint base.
- **`SetStatusBarTexture` takes no category but a fallback's or an LSM pick's**: `WHITE8X8` and a `media/` path there both stand where `bar.texture` belongs.
- **`media/` takes no font face**, by its `.ttf` or `.otf` or by a `SetFont` on the line.
- **A quality color needs a lookup or a real link**: `|Hitem:` in the string, `ITEM_QUALITY`, or a name holding `quality` that is called or indexed. The word in a string is not enough.

A numeric component is a literal however it is spelled, `1.`, `.5` or `0x1`, and a fallback counts: `fs:SetTextColor(c.r or 1, ...)` is a hit. `SetSwipeColor` is read, and so is `CreateColor` wherever it stands, which is what a `SetGradient` is handed.

### `skin_switch.lua`, `test_skin_switch.lua`: the switch test (`FS-GATE`)

A host declares its painted surfaces, and each one must change on a skin switch. `W.probeTokens(Skin)` builds a probe skin that gives every token its own value, as ConsumableMaster's flip test does for its own tokens, because real skins share tokens (`icon.arrow` is `hud.label`, `menu.text` is `text.body`) and would fail falsely. Colors are unique across the schema, numbers move by one, bools flip, and a string takes another skin's value so a font or bar key still resolves.

`W.spy(objects)` wraps `W.SETTERS` on the objects and on their regions, children and NineSlice. `W.runSurface(facts, surface, mode)` flips Ka0s Default, probe, Ka0s Default, probe, repaints once more, then flips Ka0s Default, and compares by what each setter was last given. The first flip settles. A key the two home flips disagree on is dropped, because the skin did not move it, and the home and probe flips are compared on what is left. The extra repaint puts the two home flips an odd number of paints apart, so something that alternates per paint disagrees with itself there; its draws are not read, so a host that skips an unchanged repaint loses nothing. A surface with no `paint` skips it, and a surface whose noise has a period of exactly three paints still reads as changing. So a surface fails when it drew the same, fails when it drew nothing, and fails when all it drew moved for reasons of its own. Mode `"clear"` clears the Scope and turns companions on, and every surface runs. Mode `"ignored"` holds the Scope ignored and companions off, and a surface marked `scope` or carrying a `companion` is excluded. `W.factsProblems(facts)` validates the declaration. The probe is unregistered, and the owner's choice and Scope put back, whatever a surface does.

### `inventory.lua`

`KIT_GATE_RULE` names `skinning-§1` for both suites, so a decline reads as one.

### `mock_paint.lua`: a string's own font beats its font object (`R3-DR-1L`)

`FontString:SetFontObject(obj)` keeps a font the string was given with `SetFont`, and `GetFont` still answers it, as the client does. Through the earlier steps of revision 50 it cleared that font, so a suite passed a string that drew its creation face in game under every skin: DpsRace's clocks, made with `SetFont` and then handed to `S.HudFont` (Ka0sAddonsCommonTasks `docs/2026-11-02-SMOKE_ROUND3/`, images 81 and 82). A string that never had its own font answers its object's, as before. Revision 50 is not yet shipped, so the revision does not move.

**What a consumer owes:** nothing, unless a suite gives a string `SetFont` and then reads the face a font object should have put on it. That suite now reads the string's own face, which is what the client draws, and the host code under it is the bug: create the string from a font-object template, or route its face through `S.HudFont`, which now holds its face on any string (Skin document, *What changed*).

## What a consumer owes

**Re-vendoring turns the inventory red until both suites are declared by the pair**, as with every kit suite. A declared suite with no facts is one declared skip, so that commit stays green. The rest is adoption.

### Adopting the typed-value gate

1. Re-vendor. The inventory goes red until both suites are declared by the pair:
   `{ name = "test_skin_values", dir = "tests/_kit/" }` and `{ name = "test_skin_switch", dir = "tests/_kit/" }`.
   With nothing else done, each is one declared skip that names `skinning-§1`, so the re-vendor stays green.
2. Set `Kit.skinValues = {}` in `tests/run.lua`, before `Kit.run`, and run the suite. It lists every typed value no kit category takes.
3. Fix each one through a token, or add a row. A row is `{ file, substring, why, cause }`, all four required: `file` is root-relative, `substring` is plain text on the code line, `why` says why the skin never reaches it, and `cause` is an id such as `L13`, `A6`, `MC` or `FS-AM-02`. Rows live in `Kit.skinValues.rows`.
4. Name the host's own paint calls in `calls`, as AuraMaster's `DrawEdge` is: `calls = { DrawEdge = { 3, 4, 5 } }`, call name to color positions.
5. Delete `tests/test_skin_literals.lua`, or keep only the cases that are not the gate (PanelMaster's picker and tooltip cases, for one). Move its allow rows across, and expect most to go: a row a category already takes goes stale and fails, on purpose.

### Adopting the skin-switch test

1. List what the host paints, one entry per surface, in `Kit.skinSwitch.surfaces`, with `owner` and `skin`:

   ```lua
   Kit.skinSwitch = {
     owner = "AuraMaster",
     skin  = function() return LibStub("LibKa0s-Skin-1.0") end,
     surfaces = {
       { name = "a container's edge", build = function() ... return frame end },
       { name = "the options page's heading", scope = "panel", build = ... },
       { name = "the bar's fill", companion = function(on) ... end, build = ..., paint = ... },
     },
   }
   ```

2. `build` makes and paints the surface and answers what was painted, one or several objects. Its regions, its children and a NineSlice are spied too. A region held only in a field of a plain table is not found, so answer it as well.
3. `paint` is the redraw a mock has no listener for. A primitive the facade tracked repaints by itself and needs none. A surface drawn with `S.HudFont` or a host's `Style` function usually does.
4. `scope` is `"panel"` or `"fonts"`, for a surface Ignore settings panel or Ignore fonts keeps stock. `companion(on)` writes the surface's `<key>FromSkin` row. Either one excludes the surface from the second pass.
5. `reset`, optional, runs after every surface, for what a surface left behind.

The first pass needs nothing from the host's Scope or profile: it clears the Scope and turns the companion on itself. Coverage is the declaration: a surface left out of the list is not tested, and an audit reads the list.

