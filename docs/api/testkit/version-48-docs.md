# `testkit` — version 48

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/`, the files version 47 lists |
| Version | **48** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.85.0 (unreleased) |
| Status | Superseded |
| Supersedes | [version 47](version-47-docs.md) — the same surface, with no check on the library-drawn icons |
| Superseded by | [version 49](version-49-docs.md) |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `48` |

Everything revision 47 describes is unchanged here except what follows.

## What changed

### `vendor_sync.lua`: the library-drawn icons (`FS-L6`)

`VendorSync.LIBRARY_MARKS` lists what LibKa0s draws on a host's behalf: `chevron-down`, `close`, `confirm`, `info`, `move`, `reset` and `volume-high`. `VendorSync.missingMarks(decl, cat)` answers the ones a list declaration leaves out. The gate goes red on any, since a pruned icon draws blank and raises nothing. `none` and `all` have nothing to miss, and a name the tag's catalog does not carry is not asked for.

## What a consumer owes

Re-vendor the kit with the library, per `docs/releasing.md`, and add the seven names to the `LibKa0s icons:` line, or the gate stays red.
