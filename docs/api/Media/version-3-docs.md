# `LibKa0s-Media-1.0` — version 3

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Media surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Media-1.0` |
| Files and minors | `Media.lua` minor **3** |
| Shipped in | v1.9.2 |
| Status | **Current** |
| Supersedes | [version 2](./version-2-docs.md) — 49 icons, no textures |
| Superseded by | — |
| Confirm in-game | `LibStub("LibKa0s-Media-1.0").MODULES` → `{ Media = 3 }` |

## What changed at this version

**Additive.** Nothing that existed at version 2 behaves differently, and the only signature to move
gained a second return value rather than changing its first.

| | | Since |
|---|---|---|
| 64 more icons | `ICONS` goes from 49 names to 113: the left/right arrow family, both text-alignment families, two more grid densities, chat and speech-bubble, and the tools, places, sound and session marks. Every version-2 name still resolves. | **3** |
| `TEXTURES` | Seven **statusbar** textures, keyed by the LSM display name a player picks and a profile stores. | **3** |
| `Texture(addonName, name[, vendorPath])` | The vendored path for one of them, extensionless, or `nil`. | **3** |
| `RegisterLSM` returns `fonts, bars` | It registers the textures as `statusbar` alongside the face. A caller reading one return still reads the font count. | **3** |

### The textures, and why they are generated rather than drawn

`tools/artwork/bar_textures.py` synthesizes all seven from named constants — it is the provenance
record the way `icon_cleaner.py` is for the icons, and it is also the licensing answer: nothing was
traced, sampled or copied from anything.

| LSM display name | File | What it is |
|---|---|---|
| `Ka0s Gradient` | `gradient.tga` | An opaque vertical gradient, **pure white at the top**, easing to 58% at the bottom |
| `Ka0s Underline 1` / `2` / `4` | `underline-1/2/4.tga` | Transparent but for a solid band at the **bottom** edge — 2px, 4px, 8px |
| `Ka0s Overline 1` / `2` / `4` | `overline-1/2/4.tga` | The same three, mirrored to the **top** edge |

**Every one is 256×32**, whatever the band inside it does. That is the point of the family: a bar
frame sized for one is sized for all seven, so switching between them gives a player a different
line rather than a different-shaped widget, and an addon can offer the set as one dropdown.

The gradient peaks at **white** where a typical bar texture peaks at light grey. A texture is tinted
by *multiplying*, so grey art mutes a saturated statusbar color; white delivers the caller's color
undiluted, and the shading lives in the falloff. The falloff is eased rather than linear (exponent
1.7), which keeps the top third — the part a player reads the color from — bright.

Transparent pixels are `(0,0,0,0)`, never white-at-zero-alpha: the client resamples these whenever a
bar is not exactly 256 wide, and white under the alpha bleeds a halo out of the band's edge.

**The number is a multiple, not a pixel count.** `4` is four times the base band, and the base band
is 2px of 32. A name carrying a pixel count would be wrong the moment the canvas changed.

### The key is the label

`TEXTURES` is keyed the way `FONTS` is — by the **display name**, not the filename — because that
key is what a dropdown shows *and* what a profile stores. A texture registered under `underline-2`
would give a player a saved setting that reads as a path in every UI that shows it. A test asserts
the pairing in both directions: every key reads as a Ka0s label, every file reads as a path.

## What this major is

The first payload in this library that is not code. `LibKa0s/media/` ships the **art and the type
this collection draws with** — 113 white icon TGAs, seven generated statusbar textures and one
monospace face — and this module is the four functions that reach them, plus the catalogs of what is
there.

It exists because the alternative was already happening. Mythic Meters built 49 icons from Open
Iconic and shipped them under its own `media/`, alongside its own copy of JetBrains Mono, built by a
tool that lived in that one repo. The second addon to want a gear icon would have copied both, and
then there would be two sets of bytes, two licenses to track, two provenance stories, and a
collection whose addons stop looking like one author's work the first time one copy is regenerated
and the other is not.

Depends on LibStub and `LibKa0s-Core-1.0` (minor 1 or newer), and on no addon framework.
LibSharedMedia is **optional**: `RegisterLSM` is a no-op without it, because an addon that does not
carry LSM still wants its icons.

## Why every call takes the addon's own name

A WoW texture path is absolute from `Interface\AddOns\`, and this library is **vendored** — there is
no one path to it, there are as many as there are consumers, and a copy cannot know which one it was
copied into. Lua offers a file no way to ask: `...` carries the addon name only for a file the TOC
loads directly, and `LibKa0s.xml` is loaded from inside `libs/`.

Guessing would be worse than asking, because a wrong texture path **fails silently** — the texture
does not draw, and nothing is raised or logged. So the host passes the name it already has, verbatim,
as the first vararg of every file its TOC loads:

```lua
local addonName, NS = ...
local M = LibStub("LibKa0s-Media-1.0", true)

M.Icon(addonName, "settings")
--> "Interface\\AddOns\\MythicMeters\\libs\\LibKa0s\\media\\icons\\settings"
```

## Lib-level surface

Read straight off the LibStub table. Every function is stateless.

| Name | Since | Meaning |
|---|---|---|
| `Icon(addonName, name[, vendorPath])` | 1 (extensionless since **2**) | The texture path for one icon, **without an extension** — the client appends it — or `nil` when `name` is not in `ICONS` or `addonName` is missing or empty. The file behind it is `<name>.tga`. |
| `Texture(addonName, name[, vendorPath])` | **3** | The path of one shipped statusbar texture, extensionless, or `nil` when `name` is not a key of `TEXTURES` or `addonName` is missing or empty. |
| `TEXTURES` | **3** | Map of LSM display name → `{ file }`. The catalog of the seven bar textures. |
| `Font(addonName, name[, vendorPath])` | 1 | The font path for one registered face, or `nil` when `name` is not a key of `FONTS` or `addonName` is missing or empty. |
| `RegisterLSM(addonName[, vendorPath])` | 1 (second return: **3**) | Register every shipped font **and every shipped statusbar texture** with LibSharedMedia under its catalog name. Returns `fonts, bars`; **`0, 0` when LSM is absent, which is not an error**. |
| `ICONS` | 1 | Array of every icon name, which is each file's own basename. The catalog — enumerate it rather than hard-coding a list. |
| `FONTS` | 1 | Map of LSM name → `{ file, license }`, both basenames under `media/fonts/`. |
| `VENDOR_PATH` | 1 | `"libs\\LibKa0s"` — where the collection vendors this library, and the default third argument above. |
| `MODULES` | 1 | `{ Media = <minor> }` — the live minor, and the value that picks this document. |

### An unknown name answers `nil`, deliberately

Because the failure it replaces is invisible. A misspelt name built into a path yields a texture that
does not load, and a texture that does not load draws nothing and raises nothing: the control is
simply absent, through every green test suite and every session, until somebody looks at the right
part of the screen. `nil` is a value the caller can see — it drops into the kind of fallback ladder a
host already has for art that fails to load, and a host without one gets a nil where it expected a
string rather than a button that quietly is not there.

The lookup is **case-sensitive**: `"Settings"` is not `"settings"`.

### `vendorPath`

Nothing in the collection passes it today. It exists so that a repo which vendors somewhere other
than `libs/LibKa0s` is not forced to rebuild the path string by hand — a second place to spell one
path is a second place for it to drift.

## The icons

64×64 32-bit RLE TGAs in `media/icons/`, from [Open Iconic](https://github.com/iconic/open-iconic)
(MIT — the notice ships beside the art as `media/icons/LICENSE-open-iconic.txt`). Open Iconic was
chosen because its marks are drawn to stay legible at 8px, which is the property that matters when a
header draws them at 16.

**They are white, and that is part of the contract.** A texture is tinted by *multiplying*, so white
art becomes any color a caller asks for and black art stays black whatever it is asked for. Every
mark here is flat white with its entire shape in the alpha channel. Art added later must be too, or
one icon silently stops obeying a host's color setting.

**All 113 names, grouped as `lib.ICONS` groups them** — the source is the catalog, and this table
follows its order so the two can be read side by side. Enumerate `ICONS` rather than copying this
table into a host: a name added upstream reaches an addon that enumerates and never reaches one that
hard-codes.

| Group | Names |
|---|---|
| Window header strip | `close` · `minimise` · `expand` · `lock` · `unlock` · `settings` · `segment` · `reset` · `export` · `sort-up` · `sort-down` |
| Core actions | `copy` · `clear` · `add` · `edit` · `confirm` · `cancel` · `search` · `undo` · `redo` · `import` |
| Status and feedback | `info` · `warning` · `help` · `ban` · `bug` |
| State | `pin` · `eye` · `star` |
| Layout | `move` · `resize` · `fullscreen-enter` · `fullscreen-exit` · `grid` · `list` · `layers` |
| Navigation | `chevron-left` · `chevron-right` · `chevron-up` · `chevron-down` |
| Data | `chart` · `graph` · `spreadsheet` · `timer` · `clock` |
| Arrows — up/down, every weight | `arrow-up` · `arrow-down` · `arrow-thick-up` · `arrow-thick-down` · `arrow-circle-up` · `arrow-circle-down` · `collapse-up` · `collapse-down` · `expand-up` · `expand-down` · `align-top` · `align-bottom` |
| Arrows — marks drawing TWO | `sort-asc` · `sort-desc` · `transfer` · `elevator` |
| Talking | `chat` · `speech-bubble` |
| Arrows — left/right | `arrow-left` · `arrow-right` · `arrow-thick-left` · `arrow-thick-right` · `arrow-circle-left` · `arrow-circle-right` · `caret-left` · `caret-right` · `expand-left` · `expand-right` |
| Text alignment | `align-left` · `align-center` · `align-right` · `justify-left` · `justify-center` · `justify-right` |
| Layout, continued | `grid-two-up` · `grid-four-up` · `resize-height` · `resize-width` |
| Status and state, continued | `circle-check` · `task` · `thumb-up` · `thumb-down` · `heart` · `bookmark` |
| Place and navigation | `home` · `location` · `map-marker` · `external-link` · `link-intact` |
| Tools and devices | `wrench` · `terminal` · `monitor` · `video` · `aperture` · `zoom-in` · `zoom-out` |
| Sound | `volume-high` · `volume-low` · `volume-off` |
| Documents and labels | `document` · `tag` · `tags` |
| Session | `account-login` · `account-logout` |
| Entities | `person` · `people` · `target` · `shield` |

**`sort-up`/`sort-down` and `sort-asc`/`sort-desc` are not the same mark.** The first pair is one
arrow each and is what a column header wants; the second draws **two** arrows and reads as *the
control that changes sort direction*, not as *the direction it is sorted*. A column header taking
`sort-asc` gets a busier mark than the row of headers beside it.

**Two marks are deliberately absent**, because Open Iconic has no glyph for either and a hand-drawn
substitute would be the one icon in the set that looks foreign:

- **`save`** — the set ships no floppy. `confirm` carries the meaning.
- **`hidden`** — there is no crossed-out eye. `eye` drawn dimmed is the state, the way a two-state
  control already distinguishes itself; unlike the padlock, this one has no second glyph.

`tools/artwork/icon_cleaner.py` in this repo is **the provenance record** for all of it: the upstream
repo, the license, which glyph each name draws, and every transformation applied — because it is the
program that produces the art. Regenerate with `python3 tools/artwork/icon_cleaner.py`; adding a mark
is one row in its `GLYPHS` table plus a row in `ICONS` here, and `tests/test_media.lua` fails if
either side is missing.

## The font

| LSM name | File | License |
|---|---|---|
| `JetBrains Mono` | `JetBrainsMono-Regular.ttf` | `JetBrainsMono-OFL.txt` (SIL OFL 1.1) |

**One face, and it is monospace.** A meter, a debug console and a perf table are all grids of digits
that change while you are reading them, and in a proportional face every digit is a different width —
so the column visibly shivers as it ticks. JetBrains Mono pins them to a grid. It is also the face
`LibKa0s-DebugLog-1.0` has always required its host to supply; carrying it here is what stops each
host answering with a different one.

### What registration buys that a path does not

A host can draw with `Font(...)` and never touch LSM. What `RegisterLSM` adds is the **settings
panel**: an LSM-registered face appears in the font dropdown beside every other font the player has,
and a profile can then store the **name** — portable across installs — rather than a path naming one
addon's folder.

Call it at **file load**, not at `PLAYER_LOGIN`. LibSharedMedia is vendored under `libs/` and has
already run by the time a TOC reaches the consumer's own files, and a default naming a face LSM has
not heard of yet resolves to nothing.

Registration is **idempotent** — LSM charges nothing for an identical `(mediatype, key, path)` triple
— so two consumers each registering at load is not a conflict. Two consumers registering *different*
paths under one key would be, and that is precisely the collision this module removes: every consumer
now points at the same bytes under the same name.

## Adopting it

```lua
-- core/MediaSetup.lua, or wherever the addon does its library wiring
local addonName, NS = ...

local Media = LibStub and LibStub("LibKa0s-Media-1.0", true)
if Media then
    Media.RegisterLSM(addonName)
    NS.Icon = function(name) return Media.Icon(addonName, name) end
end
```

Then draw with `NS.Icon("settings")`, and keep whatever fallback the host already has for a texture
that does not load — `nil` from an unknown name lands in the same branch.

**A host with no LibKa0s** (the degraded install every Ka0s addon models) gets `nil` from the
`LibStub` lookup and must degrade as it does for every other module. Icons are chrome: the right
degradation is a control that draws a character, not a control that errors.

## Vendoring

Whole-folder, exactly as before — `media/` is inside the payload, so the copy that already ships the
Lua ships the art too:

```sh
cp -r LibKa0s/. <Addon>/libs/LibKa0s/
diff -r --strip-trailing-cr LibKa0s <Addon>/libs/LibKa0s   # content — MUST be empty
diff -r LibKa0s <Addon>/libs/LibKa0s                       # bytes  — SHOULD be empty
```

The consumer-side gate compares the vendored payload against the tag byte for byte
(`tests/_kit/vendor_sync.lua`). It had to change to carry this major: it listed one directory level
and normalized line endings on everything, which is right for Lua and wrong for a TGA. **Kit revision
11 or newer is required** to vendor a payload with `media/` in it — see
[`../testkit/version-11-docs.md`](../testkit/version-11-docs.md).
