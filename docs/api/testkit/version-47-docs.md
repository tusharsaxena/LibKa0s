# `testkit` — version 47

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `asserts.lua`, `inventory.lua`, `secrets.lua`, `latch.lua`, `bindings_xml.lua`, `glyphs.lua`, `loader.lua`, `mock_base.lua`, `mock_ace.lua`, `mock_record.lua`, `mock_events.lua`, `mock_resize.lua`, `mock_lines.lua`, `mock_ids.lua`, `mock_bindings.lua`, `mock_layers.lua`, `mock_paint.lua`, `vendor_sync.lua`, `test_eol.lua`, `test_prose.lua`, `prose_lists.lua`, `prose_coverage.lua`, `prose_selftests.lua`, `test_layout_cap.lua`, `test_diagnostics_contract.lua`, `lizard_sighted.lua`, `test_lizard_sighted.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **47** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.84.0 |
| Status | **Current** |
| Supersedes | [version 46](version-46-docs.md) — the same surface, with the Ace fakes in `mock_base.lua` |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `47` |

Everything revision 46 describes is unchanged here except what follows. Revision 47 is one release's
kit (v1.84.0, Ka0sAddonsCommonTasks `docs/2026-10-31-FINDINGS_REMEDIATION/M2_LIBRARY_RELEASE.md`): a later kit
change in that release extends this document rather than taking a revision of its own.

## What changed

### `mock_ace.lua`: the Ace fakes leave `mock_base.lua` (`LK-M2-PEEL`)

A pure move. CallbackHandler-1.0, AceEvent-3.0's event half, AceConsole-3.0's print mixins, AceTimer-3.0, AceConsole-3.0, AceEvent-3.0 and AceAddon-3.0 now sit in `mock_ace.lua`, which `mock_base.lua` loads from its own folder and which raises if missing, as `mock_record.lua` does. Nothing a suite reads moved: `M` and the fakes answer as before. `mock_base.lua` drops from 1465 lines to under 700 and keeps AceGUI's fake, which closes over its tracked frames.

### `glyphs.lua`: a comment

The header said ten skins; there are nine.

## What a consumer owes

Re-vendor the kit with the library, per `docs/releasing.md`. A display string carrying U+2044 goes red
under `Kit.assertDisplayGlyphs`.
