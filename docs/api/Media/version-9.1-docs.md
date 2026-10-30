# `LibKa0s-Media-1.0` — version 9.1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Media surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Media-1.0` |
| Files and minors | `Media.lua` minor **9** · `MediaIcons.lua` minor **1** |
| Shipped in | v1.79.0 |
| Status | Superseded |
| Supersedes | [version 8.1](./version-8.1-docs.md) (shipped in v1.78.0) — the same surface without Oxanium in `FONTS`, and without `Ka0s Default` and the seven skins' own bars in `TEXTURES` |
| Superseded by | [version 10.1](./version-10.1-docs.md) |
| Confirm in-game | `LibStub("LibKa0s-Media-1.0").MODULES` → `{ Media = 9, MediaIcons = 1 }` |

## What changed at this version

**Additive.** Nothing version 8.1 had resolves differently and no signature moves. Ten catalog
entries arrive: Ka0s Default's own face and bar texture (the owner's choice, 2026-10-28), and a bar
texture of its own for each of seven more skins (the owner's approved mockup, SO-04);
`LibKa0s-Skin-1.0`'s SkinDefs minor 14 names them all. `MediaIcons.lua` does not move.

| | | Since |
|---|---|---|
| `Ka0s Oxanium SemiBold` and `Ka0s Oxanium Bold` in `FONTS` | `{ file = "Oxanium-SemiBold.ttf", license = "Oxanium-OFL.txt", langmask = { "western" } }` and the same with `Oxanium-Bold.ttf`: Ka0s Default's faces, SemiBold for body and HUD text, Bold for titles. SIL OFL 1.1 like every face here, chosen as the free face nearest the owner's first pick. Static instances cut by `tools/artwork/fonts.py` from google/fonts' variable `Oxanium[wght].ttf` at wght 600 and 700, pinned by commit; `Oxanium-OFL.txt` records the instancing above the license text. Latin only, so western. `FONTS` holds seventeen entries. | **9** |
| `Ka0s Default` in `TEXTURES` | `{ file = "ka0s-default.tga" }`: Ka0s Default's bar texture, drawn by `tools/artwork/bar_textures.py` like the other seven: dim at the top, a highlight low on the bar and a short lip, on the same 256×32 RLE 32-bit canvas. | **9** |
| Seven skins' bars in `TEXTURES` | `Ka0s Matte` (`matte.tga`, Obsidian), `Ka0s Parchment` (`parchment.tga`, Azeroth), `Ka0s Glass Bar` (`glass-bar.tga`, Glass), `Ka0s Solid` (`solid.tga`, High Contrast), `Ka0s Forge` (`forge.tga`, Ember), `Ka0s Satin` (`satin.tga`, WoW Midnight) and `Ka0s Classic` (`classic.tga`, WoW Forever), from the same tool on the same canvas, opaque and gray. WoW Default keeps the client's `Blizzard` bar and ships none. **Glass Bar**, not Glass, because `Ka0s Glass` is already the Glass border and background. `TEXTURES` holds fifteen entries, and `RegisterLSM` counts fifteen bars. | **9** |

## What version 8.1 changed

**Additive.** Nothing version 5.1 had resolves differently, no signature moves, and `RegisterLSM`
gains two return values after the two it had. What arrives is the art the skin engine
(`LibKa0s-Skin-1.0`, the 2026-10-25 skinning run) names by LibSharedMedia key: fourteen OFL faces
(since minor 8) and the Glass skin's rounded border and fill. `MediaIcons.lua` does not move; it re-attaches to the new
shell on its own guard.

**Minor 7, before the release left the machine.** Minor 6 was this version's first key, `6.1`, and
never shipped: the owner's client reported "Attempt to register an invalid font" from every addon
that loaded after LootHistory (see *A held key is never offered* below), so the fix bumped `Media.lua`
to 7 inside the unpushed v1.78.0 and this document moved to `7.1` with it. **Minor 8**, also before
any push (the owner's round-5 notes, 2026-10-28): every skin draws a family of its own, so the
catalog's skin faces became Inter, Nunito, Vollkorn, Bitter, Philosopher, Fira Sans and Atkinson
Hyperlegible, a regular and a title weight each, and minor 6's Barlow and Cinzel left; the document
moved to `8.1`. The *Since* column keeps the minor each member arrived at.

| | | Since |
|---|---|---|
| Fourteen skin faces in `FONTS` | `Ka0s Inter` / `Ka0s Inter SemiBold`, `Ka0s Nunito` / `Ka0s Nunito SemiBold`, `Ka0s Vollkorn` / `Ka0s Vollkorn Bold`, `Ka0s Bitter` / `Ka0s Bitter Bold`, `Ka0s Philosopher` / `Ka0s Philosopher Bold`, `Ka0s Fira Sans` / `Ka0s Fira Sans SemiBold`, `Ka0s Atkinson` / `Ka0s Atkinson Bold`, SIL OFL 1.1, each license beside its file in `media/fonts/`. `FONTS` holds fifteen entries. Minor 6 had five (`Ka0s Barlow`, `Ka0s Barlow SemiBold`, `Ka0s Cinzel` and the two Atkinson weights); those three keys left at minor 8, never shipped. | **6**, **8** |
| `langmask` on every `FONTS` entry | An array of LibSharedMedia locale groups, the suffix of `LSM.LOCALE_BIT_<group>`. JetBrains Mono and the twelve faces with Cyrillic are `{ "western", "ruRU" }`; Atkinson Hyperlegible's two are `{ "western" }`. Version 5.1 applied one western + ruRU mask to every face. | **6** |
| `BORDERS`, `Border(addonName, name[, vendorPath])` | The LSM `border` catalog: `["Ka0s Glass"] = { file = "glass-border.tga", edgeSize = 8 }`, and its extensionless path. | **6** |
| `BACKGROUNDS`, `Background(addonName, name[, vendorPath])` | The LSM `background` catalog: `["Ka0s Glass"] = { file = "glass-fill.tga", slice = 8 }`, and its extensionless path. | **6** |
| `RegisterLSM` returns `fonts, bars, borders, backgrounds` | It registers the two new catalogs as `border` and `background`, each face under its own mask, and counts each kind the way it counts fonts (what LSM holds afterwards). `0, 0, 0, 0` without LSM. | **6** |
| `RegisterLSM` never offers a held key | When `LSM:IsValid(type, name)` already answers true, `Register` is not called and the key counts as held. Minor 6 offered every key and read `IsValid` afterwards. An LSM without `IsValid` still sees every call, each counted. | **7** |

**The new keys resolve into one addon's folder in leg 1.** LibSharedMedia keeps the first
registration of a key. While LootHistory is the only consumer that vendors this version, its
`RegisterLSM` is the first to offer the new keys, so `Ka0s Inter` and the rest resolve into
`Interface\AddOns\LootHistory\libs\LibKa0s\media\...`. An addon that loads before it runs its
own older copy, which does not offer them at all; one that loads after it runs this version's
`RegisterLSM` (LibStub keeps the highest minor), finds the keys held and, from minor 7, offers
nothing. The skinning run's second leg re-vendors the files into every consumer. A host
draws a skin face through LSM (`LSM:Fetch("font", "Ka0s Inter")`) and falls back to its template
font or `STANDARD_TEXT_FONT` when the key is not valid on the client's locale; it never builds the
path of a face another addon may have registered.

## What version 5.1 changed

**Additive, and the catalog grows fifty-fold.** Every name version 4 had still resolves to the same
path, in the same position in `ICONS`; no signature moves. The major gains a second file,
`MediaIcons.lua`, generated by `tools/artwork/icon_cleaner.py`, so the version key has two numbers
from here on (`<Media>.<MediaIcons>`).

| | | Since |
|---|---|---|
| Three icon sets | `ICONS` goes from 113 names to **5,836**: the other 111 Open Iconic marks (flat, unprefixed, under their upstream names), 1,434 Phosphor Fill marks (`ph:<name>`, MIT, the `*-logo` brand marks dropped) and 4,178 Game-icons.net marks (`gi:<name>`, CC BY 3.0). The 113 hand-written names stay first and in version 4's order. | **5** |
| `ICON_SETS` | Array of `{ id, prefix, dir, label, license }`, one row per set, in browser order: `open-iconic` (`""`, `""`), `phosphor` (`"ph:"`, `"phosphor"`), `game-icons` (`"gi:"`, `"game-icons"`). A browser filters by set from it. | **5** |
| `Icon` resolves a prefix | `ph:sword` answers `...\media\icons\phosphor\sword`. The name must still be in `ICONS`: an unknown prefix (`zz:sword`), or a set's mark asked for without its prefix (`sword`), answers `nil`. | **5** |
| `IconAuthor(name)` | The credited author of a Game-icons mark (`"Lorc"`, `"Delapouite"`, ...), or `nil` for any other name, an unknown one or a non-string included. CC BY attribution is per author. | **5** |
| `MediaIcons.lua` | The generated half of the catalog: packed name strings, split at load and appended to `ICONS` in place (the table keeps its identity). A secondary file paired on the shell's minor (`__iconsMinor` / `__iconsShellMinor`); a copy without it still has the 113 hand-written names. | MediaIcons **1** |

**What it costs a consumer.** The payload is whole-folder (`library-stack-§7`), so every addon that
re-vendors carries all of the art, about 28 MB unpacked, whether it draws a glyph or not. *(Amended
2026-10-20, no code change: from `library-stack-§7` at standard v2.85.0 and kit revision 40,
`media/icons/` (about 18 MB of it, 28 MB on disk) is the one carve-out, and a consumer ships only the icons it declares; see
the Vendoring section below.)* WoW loads a
texture only on `SetTexture`, so the runtime cost is the catalog's strings: one table of 5,836 names
and the author map, built once by the copy LibStub keeps.

## What version 4 changed

**Behavioral, one function.** No member is added or removed and no signature moves; the member
manifest differs from version 3's only in the minor. `RegisterLSM` changes in two ways (review
finding `LibKa0s-R-04`):

| | | Since |
|---|---|---|
| The face carries a langmask | JetBrains Mono is registered with `LSM.LOCALE_BIT_western + LSM.LOCALE_BIT_ruRU`, so a ruRU client keeps it. At version 3 it carried no mask, and LibSharedMedia refuses a maskless font on every non-western client: on ruRU, koKR, zhCN and zhTW the face never reached the dropdown. An LSM that publishes no `LOCALE_BIT_*` constants gets the plain call. | **4** |
| The count is what LSM holds | `fonts` and `bars` count an entry only when `LSM:IsValid(type, name)` answers true after the call. Version 3 counted every `Register` call, so it answered `1` on a client that had refused the face. A key another copy registered first still counts, because LSM has it. An LSM with no `IsValid` method (a test fake; the real LSM-3.0 has one) cannot be asked, so there every `Register` call counts, as in version 3. | **4** |

**CJK clients are excluded on purpose.** The face has Latin and Cyrillic glyphs and no Hangul or Han,
so on koKR, zhCN and zhTW it would draw a player's own text as boxes. It does not belong in their
font dropdown, and `RegisterLSM` answers `0` fonts there. A host that draws with `Font(...)` directly
still gets the path on every client.

## What version 3 added

**Additive.** Nothing that existed at version 2 behaves differently, and the only signature to move
gained a second return value rather than changing its first.

| | | Since |
|---|---|---|
| 64 more icons | `ICONS` goes from 49 names to 113: the left/right arrow family, both text-alignment families, two more grid densities, chat and speech-bubble, and the tools, places, sound and session marks. Every version-2 name still resolves. | 3 |
| `TEXTURES` | Seven **statusbar** textures, keyed by the LSM display name a player picks and a profile stores. | 3 |
| `Texture(addonName, name[, vendorPath])` | The vendored path for one of them, extensionless, or `nil`. | 3 |
| `RegisterLSM` returns `fonts, bars` | It registers the textures as `statusbar` alongside the face. A caller reading one return still reads the font count. | 3 |

### The textures, and why they are generated rather than drawn

`tools/artwork/bar_textures.py` synthesizes all fifteen from named constants — it is the provenance
record the way `icon_cleaner.py` is for the icons, and it is also the licensing answer: nothing was
traced, sampled or copied from anything.

| LSM display name | File | What it is |
|---|---|---|
| `Ka0s Gradient` | `gradient.tga` | An opaque vertical gradient, **pure white at the top**, easing to 58% at the bottom |
| `Ka0s Underline 1` / `2` / `4` | `underline-1/2/4.tga` | Transparent but for a solid band at the **bottom** edge — 2px, 4px, 8px |
| `Ka0s Overline 1` / `2` / `4` | `overline-1/2/4.tga` | The same three, mirrored to the **top** edge |
| `Ka0s Default` | `ka0s-default.tga` | Ka0s Default's bar, since **9**: opaque, dim at the top, a highlight **low** on the bar and a short lip at the bottom edge |
| `Ka0s Matte` | `matte.tga` | Obsidian's bar, since **9**: flat at 86%, one white row at the top and one 62% row at the bottom |
| `Ka0s Parchment` | `parchment.tga` | Azeroth's bar, since **9**: a soft fall from 97% to 77% under a seeded 2D mottle of ±6%, blurred wide along the bar with a wrap, so it **tiles horizontally without a seam**; the one bar whose columns differ |
| `Ka0s Glass Bar` | `glass-bar.tga` | Glass's bar, since **9**: an upper half falling from white to 88%, then a step to 70% rising to 82% at the bottom |
| `Ka0s Solid` | `solid.tga` | High Contrast's bar, since **9**: white everywhere, the tint and nothing else |
| `Ka0s Forge` | `forge.tga` | Ember's bar, since **9**: 60% at the top, rising on an eased curve, with a hot band low on the bar |
| `Ka0s Satin` | `satin.tga` | WoW Midnight's bar, since **9**: one broad sheen a little above the middle over a 68% floor |
| `Ka0s Classic` | `classic.tga` | WoW Forever's bar, since **9**: a highlight high on the bar over a gentle fall to the bottom |

**Every one is 256×32**, whatever the band inside it does. That is the point of the family: a bar
frame sized for one is sized for all fifteen, so switching between them gives a player a different
line rather than a different-shaped widget, and an addon can offer the set as one dropdown.

The gradient peaks at **white** where a typical bar texture peaks at light gray. A texture is tinted
by *multiplying*, so gray art mutes a saturated statusbar color; white delivers the caller's color
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
this collection draws with** — 5,836 white icon TGAs from three sets, fifteen generated statusbar
textures, the Glass skin's generated border and fill, a monospace face, fourteen OFL skin faces and
Ka0s Default's two Oxanium weights — and this module is the seven functions that reach them, plus
the catalogs of what is there.

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
| `Icon(addonName, name[, vendorPath])` | 1 (extensionless since **2**; prefixes since **5**) | The texture path for one icon, **without an extension** — the client appends it — or `nil` when `name` is not in `ICONS` or `addonName` is missing or empty. The file behind it is `<name>.tga`, in the folder of the set whose prefix `name` carries (`ph:sword` → `phosphor\sword.tga`). |
| `IconAuthor(name)` | **5** | The credited author of a Game-icons mark, or `nil` for every other name. |
| `ICON_SETS` | **5** | Array of `{ id, prefix, dir, label, license }`: the three icon sets, in browser order. `dir` is the set's folder under `media\icons` (`""`: that folder itself); `license` the file in it recording the set's terms. |
| `Border(addonName, name[, vendorPath])` | **6** | The path of one shipped border (a backdrop edge file), extensionless, or `nil` when `name` is not a key of `BORDERS` or `addonName` is missing or empty. |
| `BORDERS` | **6** | Map of LSM `border` name → `{ file, edgeSize }`. `edgeSize` is the backdrop edge size the art is drawn for. |
| `Background(addonName, name[, vendorPath])` | **6** | The path of one shipped background, extensionless, or `nil` when `name` is not a key of `BACKGROUNDS` or `addonName` is missing or empty. |
| `BACKGROUNDS` | **6** | Map of LSM `background` name → `{ file, slice }`. `slice` is the nine-slice margin to pass `SetTextureSliceMargins`. |
| `Texture(addonName, name[, vendorPath])` | 3 | The path of one shipped statusbar texture, extensionless, or `nil` when `name` is not a key of `TEXTURES` or `addonName` is missing or empty. |
| `TEXTURES` | 3 (`Ka0s Default` and the seven skins' bars: **9**) | Map of LSM display name → `{ file }`. The catalog of the fifteen bar textures. |
| `Font(addonName, name[, vendorPath])` | 1 | The font path for one registered face, or `nil` when `name` is not a key of `FONTS` or `addonName` is missing or empty. |
| `RegisterLSM(addonName[, vendorPath])` | 1 (second return: 3; langmask and counted-only-if-held: 4; per-face mask, borders and backgrounds: **6**; a held key is never offered: **7**) | Register every shipped font, statusbar texture, border and background with LibSharedMedia under its catalog name, each font under the mask its `langmask` list builds. Returns `fonts, bars, borders, backgrounds`, each counting what LSM holds afterwards (`LSM:IsValid`); **`0, 0, 0, 0` when LSM is absent, which is not an error**. |
| `ICONS` | 1 (three sets since **5**) | Array of every icon name: the set's prefix, then the file's own basename. The catalog — enumerate it rather than hard-coding a list. The 113 hand-written names come first, in version 4's order; `MediaIcons.lua` appends the rest at load. |
| `FONTS` | 1 (six faces and `langmask`: **6**; Oxanium's two: **9**) | Map of LSM name → `{ file, license, langmask }`: two basenames under `media/fonts/` and the array of LSM locale groups the face can draw (`"western"`, `"ruRU"`, ...). |
| `VENDOR_PATH` | 1 | `"libs\\LibKa0s"` — where the collection vendors this library, and the default third argument above. |
| `MODULES` | 1 | `{ Media = <minor>, MediaIcons = <minor> }` — the live minors, and the value that picks this document. |

**Consumer census, v1.67.0** ([`CONSUMERS.md`](../CONSUMERS.md)). No host calls or passes these:

- `lib.FONTS`: no consumer as of v1.67.0, kept because it is the catalog `Font` and `RegisterLSM` read; all eleven hosts reach it through those two.
- `lib.ICONS`: no consumer as of v1.67.0, kept because it is the catalog `Icon` reads; all eleven hosts reach it through `Icon`. Ka0s Quick Comms has read it since (its `NS.IconNames`, for its icon browser), which is the reader `ICON_SETS` and `IconAuthor` were added for.
- `lib.TEXTURES`: no consumer as of v1.67.0, kept because it is the catalog `Texture` and `RegisterLSM` read, and `RegisterLSM` registers every entry for LibSharedMedia pickers.
- `lib.Texture`: no consumer as of v1.67.0, kept because `RegisterLSM` publishes the same textures to LibSharedMedia, which is how hosts offer them; a host drawing one directly needs a path.
- `lib.VENDOR_PATH`: no consumer as of v1.67.0, kept because it is the default every Media reader falls back to when `vendorPath` is omitted, which every host does.

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

64×64 32-bit RLE TGAs under `media/icons/`, from three sets. Each set's license ships in its folder.

| Set | `ICON_SETS` id | Prefix | Folder | Marks | License |
|---|---|---|---|---|---|
| [Open Iconic](https://github.com/iconic/open-iconic) | `open-iconic` | none | `media/icons/` | 224 (113 semantic keys + 111 upstream names) | MIT, `LICENSE-open-iconic.txt` |
| [Phosphor](https://github.com/phosphor-icons/core), Fill weight | `phosphor` | `ph:` | `media/icons/phosphor/` | 1,434 (the 78 `*-logo` brand marks dropped) | MIT, `LICENSE-phosphor.txt` |
| [Game-icons.net](https://game-icons.net) | `game-icons` | `gi:` | `media/icons/game-icons/` | 4,178 | CC BY 3.0, `LICENSE-game-icons.txt` and `AUTHORS.txt` |

**The prefix exists because the sets reuse each other's names** — star, heart and bug are in all
three. `:` occurs in no Open Iconic name, so the split is unambiguous, and Open Iconic stays
unprefixed because its names predate the other sets and consumers store the paths they resolve to.

**Game-icons is CC BY 3.0, which asks three things**, and all three travel with the art:
attribution per author (`IconAuthor(name)` at runtime, `media/icons/game-icons/AUTHORS.txt` on disk,
one line per mark), a link to the license (in `LICENSE-game-icons.txt`, with upstream's notice
verbatim), and a statement of what was changed (in both files: rasterized to 64×64 TGA, background
square removed, recolored white, colliding names suffixed with the author's folder, British
spellings respelled). Two upstream folders do not ship: `badges` and `various-artists`, which have no
author upstream's notice credits. A consumer that draws these marks credits the authors in its own
README (`documentation-§1`'s Credits section).

**Names.** A Phosphor name is upstream's file name without its `-fill` suffix. A Game-icons name is
upstream's file name; a name two authors both drew carries the author's folder name as a suffix on
every copy (`gi:bone-knife-lorc`, `gi:bone-knife-delapouite`), and a name the US-English gate would
reject is respelled (`gi:armored-shell`, `gi:ring-mold`, `gi:morbid-humor`, `gi:tarot-20-judgment`).

**They are white, and that is part of the contract.** A texture is tinted by *multiplying*, so white
art becomes any color a caller asks for and black art stays black whatever it is asked for. Every
mark here is flat white with its entire shape in the alpha channel. Art added later must be too, or
one icon silently stops obeying a host's color setting. Game-icons ship white on a black square; the
generator takes the alpha from the luminance, which removes the square, and checks that every
corner pixel is transparent afterwards.

**The 113 hand-written names, grouped as `lib.ICONS` groups them** — the source is the catalog, and this table
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
repos and the commit each set is pinned to, the licenses, which glyph each semantic key draws, every
author, every filter and every transformation applied — because it is the program that produces the
art. Regenerate with the tool's venv (`DEPENDENCIES.md`): `--fetch` downloads the Open Iconic PNGs
and clones the two SVG sets at their pinned commits into `tools/artwork/.cache/`, and `--build`
renders every set and rewrites `MediaIcons.lua`, the license files and `AUTHORS.txt`. A semantic key
is one row in its `GLYPHS` table plus a row in `ICONS` in `Media.lua`; every other name is generated.
`tests/test_media.lua` checks each set's names against its folder in both directions.

## The fonts

| LSM name | File | License | Locales | Used by |
|---|---|---|---|---|
| `JetBrains Mono` | `JetBrainsMono-Regular.ttf` | `JetBrainsMono-OFL.txt` | western, ruRU | the debug console, meters, perf tables |
| `Ka0s Inter` / `Ka0s Inter SemiBold` | `Inter-Regular.ttf` / `Inter-SemiBold.ttf` | `Inter-OFL.txt` | western, ruRU | Obsidian |
| `Ka0s Nunito` / `Ka0s Nunito SemiBold` | `Nunito-Regular.ttf` / `Nunito-SemiBold.ttf` | `Nunito-OFL.txt` | western, ruRU | Glass |
| `Ka0s Vollkorn` / `Ka0s Vollkorn Bold` | `Vollkorn-Regular.ttf` / `Vollkorn-Bold.ttf` | `Vollkorn-OFL.txt` | western, ruRU | Azeroth |
| `Ka0s Bitter` / `Ka0s Bitter Bold` | `Bitter-Regular.ttf` / `Bitter-Bold.ttf` | `Bitter-OFL.txt` | western, ruRU | Ember |
| `Ka0s Philosopher` / `Ka0s Philosopher Bold` | `Philosopher-Regular.ttf` / `Philosopher-Bold.ttf` | `Philosopher-OFL.txt` | western, ruRU | WoW Midnight |
| `Ka0s Fira Sans` / `Ka0s Fira Sans SemiBold` | `FiraSans-Regular.ttf` / `FiraSans-SemiBold.ttf` | `FiraSans-OFL.txt` | western, ruRU | WoW Forever |
| `Ka0s Atkinson` / `Ka0s Atkinson Bold` | `AtkinsonHyperlegible-Regular.ttf` / `-Bold.ttf` | `AtkinsonHyperlegible-OFL.txt` | western | High Contrast |
| `Ka0s Oxanium SemiBold` / `Ka0s Oxanium Bold` | `Oxanium-SemiBold.ttf` / `Oxanium-Bold.ttf` | `Oxanium-OFL.txt` | western | Ka0s Default (SemiBold for body and HUD, Bold for titles), since **9** |

The first of each pair is the skin's body face, the second its titles: one family per skin, since
minor 8. Ka0s Default draws Oxanium, SemiBold for body and HUD text and Bold for titles (since
**9**); WoW Default draws the client's Friz Quadrata, which this library does not ship. Every face is
SIL OFL 1.1 and its license ships beside it; Bitter reserves only the name
"Bitter Pro", which nothing here uses. `tools/artwork/fonts.py` is the provenance record for the
skin faces: it pins each to a google/fonts commit and a SHA-256, and builds the shipped files.
Philosopher, Fira Sans and Atkinson Hyperlegible ship as upstream publishes them. Inter, Nunito,
Vollkorn, Bitter and Oxanium are published only as variable fonts, and the client is not known to
honor a variable axis, so the tool cuts static instances (weight 400 and the title weight, Oxanium
at 600 and 700; Inter's optical size at 14) with fontTools and renames each for its weight; each family's `-OFL.txt` records that
above the license text.

**JetBrains Mono is the monospace.** A meter, a debug console and a perf table are all grids of digits
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

**The first registration wins.** LSM keeps the first path offered under a key and answers `false` to
every later `Register` for it. Each consumer offers a *different* path, its own
`Interface\AddOns\<Addon>\libs\LibKa0s\...`, so what makes a second consumer harmless is not an
identical triple: every one of those paths names identical bytes, the same file vendored whole into
each addon. Whichever copy wins, the player sees the same face under the same name, and each
consumer's `RegisterLSM` counts it, because LSM holds it.

**A held key is never offered** (since **7**). A later `Register` is not silent: LibSharedMedia-3.0
validates a font, border or background *file* before its first-registration-wins check, and reports
a missing one through `geterrorhandler()` ("Attempt to register an invalid font"), held key or not.
Non-fatal, but one BugSack entry per key per addon. Because LibStub keeps the highest minor, a host
whose own vendored folder predates a key's art still runs the newest copy's `RegisterLSM`, which
builds the path into that host's folder, where the file does not exist. Minor 6 did exactly this on
the owner's client once LootHistory vendored it and the other addons still carried minor 5. From
minor 7, a key `LSM:IsValid` already answers for is skipped and counted. **What remains:** a key
nobody holds yet is still offered at the caller's own folder, so a host that vendors this version
but never calls `RegisterLSM` at file load leaves the new keys unheld, and the next addon to call it
reports the missing files. That case ends when every consumer re-vendors v1.78.0 and carries the
files.

**Each face carries its own mask** (western + ruRU since 4; per face since **6**). On a non-western
client LSM refuses a font with no langmask, and one whose mask lacks the client's locale bit.
JetBrains Mono covers Latin and Cyrillic, so western and ruRU clients get it in the dropdown and
koKR, zhCN and zhTW clients do not: the face has no glyphs for their text. The six families minor 8
added cover Cyrillic as well and are western + ruRU; Atkinson Hyperlegible has no Cyrillic and is
western only. A skin that names a face the client refused falls back to the client's own font.

## The Glass border and background

| LSM kind | LSM name | File | Size | Drawn with |
|---|---|---|---|---|
| `border` | `Ka0s Glass` | `glass-border.tga` | 256×32 | `SetBackdrop{ edgeFile = <path>, edgeSize = 8 }`: a 1px line with radius-8 corners |
| `background` | `Ka0s Glass` | `glass-fill.tga` | 32×32 | `SetTextureSliceMargins(8, 8, 8, 8)` with the stretched slice mode: a rounded fill whose corners stay 8×8 |

Both are white, uncompressed 32-bit TGAs with the shape in the alpha channel, tinted at runtime
like every other texture here, and both sit in `media/textures/` beside the statusbars.
`tools/artwork/glass_textures.py` synthesizes them and is their provenance record: nothing was
traced or sampled. The border uses the client's backdrop edge-file layout (eight cells: left, right,
top and bottom edges, then the four corners, each sampled 1/16 inset), so it also works in any
addon's LSM border picker. At edge size 8 its corner arc sits exactly on the fill's, so a Glass
frame is the fill tinted with the skin's background color plus the border tinted with its border
color.

The in-client keys the skins use (`Blizzard Dialog`, `Blizzard Tooltip`, `Blizzard Dialog
Background`, `Solid`, ...) are LibSharedMedia's own defaults, so this major registers none of them.


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

**Pass only names your addon declares** (from kit revision 40; see *Vendoring* below). `Icon` answers
a path for **any** name in `ICONS`, whatever your copy ships, because the catalog is the whole
`MediaIcons.lua` in every copy. A name your `LibKa0s icons:` line does not declare points at a file
your copy no longer has, and a texture that fails to load draws nothing and raises nothing. The path
is built from the `addonName` you pass, so it always points into **your** `libs/` folder: whichever
copy of Media LibStub keeps, a pruned copy elsewhere cannot break your icons, and yours cannot break
another addon's.

**A pruned icon is a blank texture, not a fallback.** `Icon` answers `nil` only for a name outside
`ICONS`; for a catalog name whose file your copy does not ship it still answers the path. Anything
that falls back on `nil` (the text button, the `×`, the client glyph) therefore never falls back,
and the control draws nothing. That includes the icons LibKa0s draws **for you**, which your line
must declare: `close` (`Core.MakeCloseButton` given your addon name, so the DebugLog console,
`PerfPanel.lua` and the Widgets copy window), `clear` and `copy` (the DebugLog console) and `info`
(the Options id list's help mark, unless the spec passes `helpIcon`). A host that wires the debug
console declares at least `close, copy, clear`.

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

**Except the icons, from kit revision 40** (`library-stack-§7`, standard v2.85.0). The addon declares,
in one line directly under its `CLAUDE.md` provenance line, which icons it ships —
`LibKa0s icons: all (icon picker).` (only for a UI that lets the player choose among the catalog),
`LibKa0s icons: none.`, or `lib.ICONS` names such as `LibKa0s icons: settings, close, ph:sword.` —
and after the copy runs `lua tools/prune-icons.lua <Addon>` from the LibKa0s checkout. Each set's
attribution files ship with it when any of its icons does. The icons LibKa0s draws for the host
(`close`, `clear`, `copy`, `info`; see above) belong in the line too. The rest of the payload, `MediaIcons.lua`,
`fonts/` and `textures/` included, is still copied whole, and `tools/prune-icons.lua` never touches
`fonts/` or `textures/`. See
[`../testkit/version-40-docs.md`](../testkit/version-40-docs.md).

The consumer-side gate compares the vendored payload against the tag byte for byte
(`tests/_kit/vendor_sync.lua`). It had to change to carry this major: it listed one directory level
and normalized line endings on everything, which is right for Lua and wrong for a TGA. **Kit revision
11 or newer is required** to vendor a payload with `media/` in it — see
[`../testkit/version-11-docs.md`](../testkit/version-11-docs.md).

## Moving to version 10.1

**Take it; three keys leave.** Version 10.1 moves no signature. What arrives in `FONTS`: `Ka0s
Prototype` (Ka0s Default's face, western only, under its author's terms in `Prototype.txt`, not the
OFL) and `Ka0s Fira Sans Medium` (WoW Forever's body face, SIL OFL 1.1 in `FiraSans-OFL.txt`). What
leaves, with its files: `Ka0s Oxanium SemiBold`, `Ka0s Oxanium Bold` and `Ka0s Fira Sans`, which no
skin names from `LibKa0s-Skin-1.0`'s SkinDefs minor 17. A host that names one of them in code or in
a degradation copy of Ka0s Default's face moves to the new one; `RegisterLSM` counts sixteen fonts.
See [version 10.1](./version-10.1-docs.md).
