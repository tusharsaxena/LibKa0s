# `testkit` — version 45

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `asserts.lua`, `inventory.lua`, `secrets.lua`, `latch.lua`, `bindings_xml.lua`, `loader.lua`, `mock_base.lua`, `mock_record.lua`, `mock_events.lua`, `mock_resize.lua`, `mock_lines.lua`, `mock_ids.lua`, `mock_bindings.lua`, `mock_layers.lua`, `mock_paint.lua`, `vendor_sync.lua`, `test_eol.lua`, `test_prose.lua`, `prose_lists.lua`, `prose_coverage.lua`, `prose_selftests.lua`, `test_layout_cap.lua`, `test_diagnostics_contract.lua`, `lizard_sighted.lua`, `test_lizard_sighted.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **45** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.82.0 (unreleased) |
| Status | **Current** |
| Supersedes | [version 44](version-44-docs.md) — `mock_paint.lua`'s `SetTextColor` reset a string's alpha to 1 when given three numbers |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `45` |

Everything revision 44 describes is unchanged here except what follows. Revision 45 is one
release's kit (v1.82.0, Ka0sAddonsCommonTasks `docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK/`): a later
kit change in that release extends this document rather than taking a revision of its own.

## What changed

### `mock_paint.lua`: `SetTextColor` keeps the alpha it is not given (`LK-14`)

A FontString told `SetTextColor(r, g, b)` with no fourth number keeps the alpha it already had;
told an alpha, it takes it; a string never given one is opaque. Revision 44 reset the alpha to 1 on
every three-number call. The client keeps it, and the difference hid a real defect: DpsRace's Arm
Race label, painted once in a 0.4-alpha disabled color, drew its enabled `btnPrimary.text` at 0.4 in
three skins (the bundle's image-55..57, measured to the pixel: Obsidian's white at 0.4 over its
`#1E80D0` fill is `(121, 179, 227)`). `tests/test_mock_paint.lua` pins the rule, and
`tests/test_skin_button_contrast.lua` the library fix it exposed (SkinPaint minor 13's `P.color`).

**Fidelity note.** Only the recorder's FontString changes. `SetVertexColor`, `SetShadowColor` and the
base mock's own frames are as revision 44 left them: nothing has measured the client's rule for them.

No documented member is renamed or removed and no case name changes.

## What a consumer owes

Re-vendor `tests/_kit/` whole:

```sh
cp -r testkit/. tests/_kit/
git update-index --chmod=+x tests/_kit/run-automated-tests.sh
lua tests/run.lua --list > docs/test-cases.md
```

A suite that paints a string translucent under the recorder and then asserts an opaque color it set
with three numbers now reads the kept alpha: that is the client's answer, and the code under test
passes the alpha itself. A consumer's own prose that names the revision it holds moves to 45 in the
same commit.
