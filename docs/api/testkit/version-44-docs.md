# `testkit` — version 44

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `asserts.lua`, `inventory.lua`, `secrets.lua`, `latch.lua`, `bindings_xml.lua`, `loader.lua`, `mock_base.lua`, `mock_record.lua`, `mock_events.lua`, `mock_resize.lua`, `mock_lines.lua`, `mock_ids.lua`, `mock_bindings.lua`, `mock_layers.lua`, `mock_paint.lua`, `vendor_sync.lua`, `test_eol.lua`, `test_prose.lua`, `prose_lists.lua`, `prose_coverage.lua`, `prose_selftests.lua`, `test_layout_cap.lua`, `test_diagnostics_contract.lua`, `lizard_sighted.lua`, `test_lizard_sighted.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **44** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.79.0 |
| Status | **Current** |
| Supersedes | [version 43](version-43-docs.md) — a StatusBar built under the paint recorder answered `SetStatusBarTexture`, `SetStatusBarColor` and `GetStatusBarColor` from the base's metatable (the frame), so a bar's fill could not be asserted |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `44` |

Everything revision 43 describes is unchanged here except what follows. No file is added; only
`mock_paint.lua` changes, with `framework.lua`'s `Kit.VERSION`. It was made for the Skin major's
`S.BarTexture` (LibKa0s#63, SO-02 of Ka0sAddonsCommonTasks
`docs/2026-10-28-SKIN_OVERRIDES_AND_PICKER/`), which paints a bar's fill on a Texture or a StatusBar.
Revision 44 is one release's kit: a later kit change in v1.79.0 extends this document rather than
taking a revision of its own.

## What changed

### `mock_paint.lua`: the StatusBar family

A frame `M.CreateFrame` builds as `"StatusBar"` while the recorder is installed (or one handed to
`M.__paintFrame`) also answers, rawset on the frame:

| Method | Answer |
|---|---|
| `GetObjectType()` / `IsObjectType(kind)` | `"StatusBar"`; `IsObjectType` is true for `"StatusBar"`, `"Frame"` and `"Region"`. A plain frame keeps the base's answer, so a primitive's kind check reads every other frame as it did under revision 43 |
| `SetStatusBarTexture(asset)` | a path sets the fill's file (`SetTexture` on the fill); a Texture region handed in becomes the fill and takes the color the old fill carried |
| `GetStatusBarTexture()` | the fill: a Texture region of the bar (layer `ARTWORK`), made on first use and kept, so it is listed by `GetRegions` from then on, as the client's bar texture is |
| `SetStatusBarColor(r, g, b[, a])` / `GetStatusBarColor()` | the fill's vertex color, alpha defaulting to 1; `1, 1, 1, 1` until set. A new file keeps the color, as in the client |
| `SetMinMaxValues(lo, hi)` / `GetMinMaxValues()` | recorded; `0, 1` until set |
| `SetValue(v)` / `GetValue()` | recorded; `0` until set |

**The survey** gains two fields for a StatusBar whose fill exists: `statusBarTexture` (the fill's
file) and `statusBarColor` (its vertex color, `{ r, g, b, a }`); nil otherwise.

**Fidelity notes.** `restore()` puts the family's methods back on an in-place frame with the rest.
Orientation, reverse fill and the fill's texel geometry are not modeled: no suite asks them yet.

No documented member is renamed or removed and no case name changes.

## What a consumer owes

Re-vendor `tests/_kit/` whole:

```sh
cp -r testkit/. tests/_kit/
git update-index --chmod=+x tests/_kit/run-automated-tests.sh
lua tests/run.lua --list > docs/test-cases.md
```

Nothing else: the recorder is opt-in, and a suite that never builds a StatusBar under it sees
revision 43's answers. A consumer's own prose that names the revision it holds moves to 44 in the
same commit.
