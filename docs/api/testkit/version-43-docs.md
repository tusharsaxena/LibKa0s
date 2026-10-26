# `testkit` — version 43

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `asserts.lua`, `inventory.lua`, `secrets.lua`, `latch.lua`, `bindings_xml.lua`, `loader.lua`, `mock_base.lua`, `mock_record.lua`, `mock_events.lua`, `mock_resize.lua`, `mock_lines.lua`, `mock_ids.lua`, `mock_bindings.lua`, `mock_layers.lua`, `mock_paint.lua`, `vendor_sync.lua`, `test_eol.lua`, `test_prose.lua`, `prose_lists.lua`, `prose_coverage.lua`, `prose_selftests.lua`, `test_layout_cap.lua`, `test_diagnostics_contract.lua`, `lizard_sighted.lua`, `test_lizard_sighted.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **43** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.78.0 |
| Status | **Current** |
| Supersedes | [version 42](version-42-docs.md) — `CreateTexture` and `CreateFontString` answered the frame itself, and no paint call (colors, fonts, textures, backdrops) was recorded anywhere a skin suite could read it |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `43` |

Everything revision 42 describes is unchanged here except what follows. One file is added,
`mock_paint.lua`, and `mock_base.lua` gains one comment line pointing at it from its *Known
divergence* paragraph (1465 lines). Revision 43 is one release's kit: LibKa0s v1.78.0 ships it once,
and a later kit change in that release extends this document rather than taking a revision of its
own.

## What changed

### `mock_paint.lua`, an opt-in paint recorder

Through revision 42 the base answered every capitalized method it does not define with the frame
(`mock_base.lua`'s metatable): `CreateTexture` and `CreateFontString` handed back the frame itself,
and `SetColorTexture`, `SetVertexColor`, `SetTextColor`, `SetFont`, `SetBackdrop` and the rest stored
nothing. The base keeps that as its default, for the parity-baseline reason its *Known divergence*
paragraph gives. This file answers the paint surface for a suite that asks, which the skin engine's
suites planned for v1.78.0 and any consumer's skin suite need.

```lua
local restore = dofile("tests/_kit/mock_paint.lua")(M)
-- every frame M.CreateFrame builds from here records paint
restore()   -- M.CreateFrame, M.UIParent's fields and every __paintFrame'd frame are the base's again
```

It wraps `M.CreateFrame`, so every frame created **after** install gets the frame methods below rawset
on it, and decorates `M.UIParent` in place when that is a table. It composes with `mock_layers.lua`
in either order.

**Frame methods:**

| Method | Answer |
|---|---|
| `CreateTexture(name, layer, template, sublevel)` | a **new** Texture region owned by the frame |
| `CreateFontString(name, layer, template)` | a **new** FontString region owned by the frame |
| `GetRegions()` / `GetNumRegions()` | those regions, in creation order |
| `GetChildren()` / `GetNumChildren()` | every recorded frame whose raw `__parent` is this frame, in creation order; read at call time, so `mock_layers.lua`'s `SetParent` moves a child between lists |
| `SetBackdrop(t)` / `GetBackdrop()` | the table as given; `nil` clears it and both colors |
| `SetBackdropColor(r, g, b[, a])` / `GetBackdropColor()` | `nil` with no backdrop, `1, 1, 1, 1` until set; alpha defaults to 1 |
| `SetBackdropBorderColor(...)` / `GetBackdropBorderColor()` | likewise |
| `SetAlpha(a)` / `GetAlpha()` | 1 until set |

`Show` / `Hide` / `IsShown`, the scripts and `HookScript`'s chaining stay the base's. `SetBackdrop`
answers on any recorded frame, `BackdropTemplate` or not: the base records the template in
`__template`, and a suite that cares asserts it there.

**NineSlice.** A frame whose template names `NineSlicePanelTemplate`, `PortraitFrameTemplate`,
`ButtonFrameTemplate`, `DefaultPanelTemplate`, `DefaultPanelFlatTemplate`, `SimplePanelTemplate`,
`InsetFrameTemplate` or `TooltipBackdropTemplate` (a comma-separated list is read token by token)
gets a recorded child frame at `frame.NineSlice` whose nine pieces are Texture regions of it, keyed
by the client's names: `TopLeftCorner`, `TopRightCorner`, `BottomLeftCorner`, `BottomRightCorner`,
`TopEdge`, `BottomEdge`, `LeftEdge`, `RightEdge`, `Center` (published as `M.__nineSliceKeys`; the
corners and edges in `BORDER`, the center in `BACKGROUND`). `M.__paintNineSlice(frame)` attaches one
by hand and answers it.

**Regions.** A region starts shown, white, opaque and unpainted, and answers:

| Family | Methods |
|---|---|
| Every region | `Show` / `Hide` / `SetShown` / `IsShown`; `IsVisible` (shown, and its owner visible); `SetAlpha` / `GetAlpha`; `GetParent` / `SetParent` (moves it between owners' region lists); `GetObjectType` / `IsObjectType`; `GetName`; `SetDrawLayer` / `GetDrawLayer`; `SetVertexColor` / `GetVertexColor`; `SetPoint` / `ClearAllPoints` / `SetAllPoints` / `GetNumPoints` / `GetPoint`; `SetSize` / `SetWidth` / `SetHeight` / `GetWidth` / `GetHeight` / `GetSize` (0 until set); `SetScale` / `GetScale`; `SetIgnoreParentAlpha` / `IsIgnoringParentAlpha` |
| Texture | `SetColorTexture`, `SetTexture` / `GetTexture`, `SetAtlas` / `GetAtlas` (a color texture, a file and an atlas replace one another, as in the client; `SetAtlas(name, true)` sizes the region from `M.__atlasSizes` and records the name in `__atlas`, the field the base's frames use); `SetGradient(orientation, minColor, maxColor)` (colors copied as `{ r, g, b, a }`); `SetTexCoord` (four or eight numbers) / `GetTexCoord` (the eight corner numbers); `SetDesaturated` / `IsDesaturated` / `SetDesaturation` / `GetDesaturation`; `SetBlendMode` / `GetBlendMode`; `SetHorizTile` / `SetVertTile` and their getters; `SetTextureSliceMargins` / `SetTextureSliceMode`; `SetSnapToPixelGrid`; `SetTexelSnappingBias`; `SetRotation` / `GetRotation` |
| FontString | `SetText` / `GetText` / `SetFormattedText`; `SetTextColor` / `GetTextColor`; `SetFont(path, size, flags)` / `GetFont` (else the font object's `GetFont`, a string name read from `_G`); `SetFontObject` / `GetFontObject`; `SetShadowOffset` / `GetShadowOffset`; `SetShadowColor` / `GetShadowColor`; `SetJustifyH` / `SetJustifyV` and their getters; `SetWordWrap` / `CanWordWrap`; `SetNonSpaceWrap` / `CanNonSpaceWrap`; `SetIndentedWordWrap`; `SetMaxLines` / `GetMaxLines`; `SetSpacing` / `GetSpacing`; `SetTextScale` / `GetTextScale`; `GetStringWidth` / `GetStringHeight` / `GetUnboundedStringWidth` (0: unarmed geometry) |

Any other capitalized method on a region **raises**, naming itself, as `mock_lines.lua`'s Line does:
a FontString told `SetTexture` fails in the client, and it fails here. Model a missing method in
`mock_paint.lua` when the client answers it.

**The survey.** `M.__paint(obj)` answers a fresh table for a region or a recorded frame: `kind`
(`"Texture"`, `"FontString"` or `"Frame"`), `frameType`, `template`, `shown`, `alpha` (1 when
unset), `layer`, `sublevel`, `color`, `vertex`, `gradient`, `texture`, `atlas`, `texCoord`,
`desaturated`, `blend`, `text`, `textColor`, `font`, `fontObject`, `shadowOffset`, `shadowColor`,
`backdrop`, `backdropColor`, `backdropBorderColor`; nil where nothing was painted. Colors are
`{ r, g, b, a }` arrays.

**Fidelity notes.** Off by default: a suite that never installs the file sees the base exactly as
revision 42 left it, `CreateTexture` answering the frame included. Frames built before the install,
and frames the base builds for itself (`GameTooltip`, the Ace fakes' frames, `M.__stubFrame()`), stay
plain until a suite hands them to `M.__paintFrame(frame)`; `restore()` puts those back, with
`M.UIParent`, and removes `M.__paint`, `M.__paintFrame`, `M.__paintNineSlice` and
`M.__nineSliceKeys`. Frames `M.CreateFrame` built while installed keep their recorder. Code that
cached `local CreateFrame = CreateFrame` at load keeps the function it cached, so install before
loading the code under test when it does that. `GetRegions` lists only the regions this file made:
a `CreateLine` Line (`mock_lines.lua`) stays in the frame's `__madeLines`.

No documented member is renamed or removed and no case name changes.

## What a consumer owes

Re-vendor `tests/_kit/` whole:

```sh
cp -r testkit/. tests/_kit/
git update-index --chmod=+x tests/_kit/run-automated-tests.sh
lua tests/run.lua --list > docs/test-cases.md
```

Nothing else: the recorder is opt-in. A consumer's own prose that names the revision it holds moves
to 43 in the same commit. A suite that asserts a skin installs `mock_paint.lua` and restores it in a
finally-style block.
