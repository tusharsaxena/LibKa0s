# `testkit` — version 64

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/`, the files [version 61](version-61-docs.md) lists |
| Version | **64** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.116.0 |
| Status | **Current** |
| Supersedes | [version 63](version-63-docs.md) — the ForeverDB fake held one object, so nothing could exercise `LibKa0s-ForeverDB-1.0` minor 3's `Object` on a shared name, a nameless row or a row that is not a table |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `64` |

Everything revision 63 describes is unchanged here except what follows. No file is added or removed,
no public member of any file is added, removed or renamed, and no kit case is added, removed or
renamed. `framework.lua`'s `Kit.VERSION` is 64. The item is `ISF-LK-01` of Ka0sAddonsCommonTasks
`docs/2026-11-25-ITEM_SEARCH_FEEDBACK/` (its `03_SPEC.md` §2).

## What changed

### `mock_foreverdb.lua`: objects for ForeverDB minor 3

`FDB.fixture()` gains the rows `LibKa0s-ForeverDB-1.0` minor 3's `Object` reads
([its document](../ForeverDB/version-3-docs.md)), in ForeverDB's shape and **invented**, like every
other row of the fake (ForeverDB's data is GPL-3.0; the kit is MIT):

| Table | Rows | What a case can prove with them |
|---|---|---|
| `obj` | four more: `boxA` and `boxB` (both "Fixture Strongbox"), `husk` (a row with no name) and `scrap` (a row that is a string, not a table) | `Object`'s name, a name two objects share, and its nil for a nameless or malformed row; a host's merge by name and its drop of the nameless |
| `item` | one more: `relic` ("Strongbox Relic", a name holding neither "fixture" nor "blade", so no earlier search case moves) | a name for the item the objects drop |
| `odrop` | `relic` ← `boxA` 4000, `boxB` 6000, `husk` 9000, `scrap` 8000 | `ItemSources`' objects for a host to merge (the highest chance of the shared name is 0.6) and to filter (the two likeliest sources have no name) |
| `spm` | `o<boxA>` on `mapA`, `o<boxB>` on `mapB`, one point each | the union of a merged row's spots |

`FDB.IDS` gains `relic` (990109), `boxA` (990302), `boxB` (990303), `husk` (990304) and `scrap`
(990305), every one inside the fake's invented range. `meta.counts` reads `item = 9` and `obj = 5`.
Every row revision 63 had is unchanged, so a consumer case that read the old fixture reads the same
answers.

## What a consumer owes

The whole-folder copy of `tests/_kit/`, as at every revision. A suite that pins `KIT_VERSION` at 63
re-pins it at 64. A consumer case that counts the fixture's items or objects (`#` over `item` or
`obj`, or `meta.counts`) re-counts them.
