# `testkit` — version 59

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/`, the files version 57 lists; no file added |
| Version | **59** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.109.0 |
| Status | Superseded |
| Supersedes | [version 58](version-58-docs.md) — the README counted seven suites of its own and thirteen places it sits in |
| Superseded by | [version 60](version-60-docs.md) — each client profile carries its `Enum.BagIndex`, `Enum.BankType` and `C_Bank.CanViewBank` |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `59` |

Everything revision 58 describes is unchanged here except what follows. No file is added. Two files
change: `README.md`, whose counts had gone stale, and `framework.lua`, whose `Kit.VERSION` is 59 and
which changes in nothing else. No public member is added, removed or renamed, no kit case is added,
removed or renamed, no mock changes, and the runner writes what revision 58 wrote. The item is
`FU-LK-KITDOC` of Ka0sAddonsCommonTasks `docs/2026-11-21-SYNC_FOLLOWUPS/`.

## What changed

### The README counts what it can, and names the roster for the rest

`README.md` said the kit carries "seven suites of its own"; it carries eight (`test_client_globals`,
`test_diagnostics_contract`, `test_eol`, `test_layout_cap`, `test_lizard_sighted`, `test_prose`,
`test_skin_switch`, `test_skin_values`), so it says eight. It said it was byte-identical "in thirteen
places — here, this repo's `tests/_kit/`, and each of the eleven consumers'", and that twelve
repositories need its gates, when the roster had grown past both. Those counts move with the roster, so
the file no longer carries them: it sits in every consumer's `tests/_kit/`, and the roster is
WowAddonStandards' `standards/ADDONS.md`, which the README now names. Revision 32 corrected the same
counts by one; a count that a new addon makes wrong is the drift this revision ends.

## What a consumer owes

The whole-folder copy of `tests/_kit/`, as at every revision. A suite that pins `KIT_VERSION` at 58
re-pins it at 59. Nothing else.
