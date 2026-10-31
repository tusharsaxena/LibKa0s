# `testkit` — version 46

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `asserts.lua`, `inventory.lua`, `secrets.lua`, `latch.lua`, `bindings_xml.lua`, `glyphs.lua`, `loader.lua`, `mock_base.lua`, `mock_record.lua`, `mock_events.lua`, `mock_resize.lua`, `mock_lines.lua`, `mock_ids.lua`, `mock_bindings.lua`, `mock_layers.lua`, `mock_paint.lua`, `vendor_sync.lua`, `test_eol.lua`, `test_prose.lua`, `prose_lists.lua`, `prose_coverage.lua`, `prose_selftests.lua`, `test_layout_cap.lua`, `test_diagnostics_contract.lua`, `lizard_sighted.lua`, `test_lizard_sighted.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **46** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.83.0 |
| Status | Superseded |
| Supersedes | [version 45](version-45-docs.md) — the safe set read from the fifteen faces of v1.82.0 |
| Superseded by | [version 47](version-47-docs.md) |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `46` |

Everything revision 45 describes is unchanged here except what follows. Revision 46 is one release's
kit (v1.83.0, Ka0sAddonsCommonTasks `docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES/`): a later kit
change in that release extends this document rather than taking a revision of its own.

## What changed

### `glyphs.lua`: the safe set follows the v1.83.0 faces (`LK-F01`)

The generated block lists the twenty-eight faces in `LibKa0s/media/fonts`. U+2044, FRACTION SLASH,
leaves the safe set, because Emblem has no such glyph; a string carrying one is a hit from this
revision. Every other non-ASCII character the set held stays, so 117 of the 118 remain. Real Friz
Quadrata is in the folder, so the set measures it rather than assuming it; a client's own
`Fonts/FRIZQT__.TTF` is still not read. The folder also keeps faces no skin names now, since a player
can pick any of them as an override.

## What a consumer owes

Re-vendor the kit with the library, per `docs/releasing.md`. A display string carrying U+2044 goes red
under `Kit.assertDisplayGlyphs`.

## Moving to the next version

A re-vendor copies the whole folder, so `mock_ace.lua` arrives with it. Nothing else moves.
