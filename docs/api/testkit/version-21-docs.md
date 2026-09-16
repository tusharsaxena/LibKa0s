# `testkit` — version 21

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `loader.lua`, `mock_base.lua`, `mock_ids.lua`, `vendor_sync.lua`, `test_eol.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **21** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.36.1 |
| Status | Superseded |
| Supersedes | [version 20](version-20-docs.md) — `mock_ids.lua` and its two opt-ins |
| Superseded by | [revision 22](./version-22-docs.md) |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `21` |

Everything revision 20 describes is unchanged here except the one addition below.

## What changed at this version

Revision 21 gives the AceGUI fake's `CheckBox` a real `check` texture, **pooled across
Create/Release the one way a real one is**: AceGUI pools the underlying FRAME, not the Lua widget
table, so a CheckBox's `check` texture is the one thing that survives a `Release` and is handed to
the very next `CheckBox` this factory creates, even though every other field on a widget from this
factory is fresh (`aceGUI:Release`'s "two differences, both deliberate" note in `mock_base.lua`
still holds for everything else).

This closes the test gap behind LibKa0s-Options-1.0 v1.36.1's fix: before this revision, the stock
CheckBox fake carried no `.check` at all, so `LibKa0s/OptionsWidgets.lua`'s `choiceFill` always took
its early guard and its gold-fill paint — and the vertex-color leak into a recycled CheckBox — was
never exercised by the suite. `tests/test_options_widgets.lua` now pins both the paint and its
restoration directly against the stock fixture, with no per-test monkeypatch needed for either.

| Member | Contract |
|---|---|
| `cb.check` | A texture-shaped table: `SetTexture(path)`, `SetVertexColor(r, g, b)`, `GetVertexColor() -> r, g, b`. Starts white (`1, 1, 1`) on a CheckBox this factory has never handed out before. |

Pooling is narrow and deliberate, not a reversal of "this factory never reuses a widget": only the
`check` texture object is kept across a `Release`, mirroring the one piece of frame state a real
AceGUI CheckBox's `OnAcquire` resets incompletely (texture and texcoord, never vertex color). A
CheckBox recycled from the pool starts with `texturePath` cleared, same as a real one's `OnAcquire`,
and whatever vertex color the previous tenant left it in — which is exactly the shape of hazard a
production fix must guard against, and now the one this kit can prove a fix against.

One file changes: `framework.lua` (the revision number) and `mock_base.lua` (the pooled texture).
`loader.lua`, `mock_ids.lua`, `vendor_sync.lua`, `test_eol.lua`, `run-automated-tests.sh` and
`README.md` are untouched.

### Revision 21 is not the geometry flip

Revision 19 moved the flip, deleting `self.__geomLive and` from `GetHeight` and `GetWidth`, to "20
at the earliest". Revisions 20 and 21 do not ship it. A frame nobody armed still answers 0. The flip
is still its own revision with its own adoption.
