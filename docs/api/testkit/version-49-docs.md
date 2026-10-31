# `testkit` — version 49

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/`, the files version 47 lists |
| Version | **49** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.85.0 (unreleased) |
| Status | **Current** |
| Supersedes | [version 48](version-48-docs.md) — the same surface, with seven library-drawn icons |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `49` |

Everything revision 48 describes is unchanged here except what follows.

## What changed

### `vendor_sync.lua`: `chevron-up` (`FS-L7`)

`VendorSync.LIBRARY_MARKS` gains `chevron-up`, the up step button of every skinned scroll bar. `chevron-down` was already listed.

## What a consumer owes

Re-vendor the kit with the library, per `docs/releasing.md`, and add `chevron-up` to the `LibKa0s icons:` line, or the gate stays red.
