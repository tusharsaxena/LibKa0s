# `testkit` — version 52

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/`, the files version 51 lists plus `mock_client.lua` |
| Version | **52** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.92.0 |
| Status | **Current** |
| Supersedes | [version 51](version-51-docs.md) — the same surface, with no client profile |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `52` |

Everything revision 51 describes is unchanged here except what follows.

## What changed

### `mock_client.lua`: the client profiles

A new file. Exactly two profiles exist, selected by `KA0S_KIT_CLIENT` (default `retail`):

| | `retail` | `forever` |
|---|---|---|
| `WOW_PROJECT_ID` | 1 | 18 |
| `WOW_PROJECT_MAINLINE` | 1 | 1 |
| `WOW_PROJECT_CAMELOT` | nil (the live Retail shape) | 18 |
| `GetBuildInfo()` | `"12.1.5", "70783", "Nov  3 2026", 120105` | `"1.60.1", "70790", "Nov  3 2026", 16001` |
| Removed | `SetDesaturation` | `GetSpecialization`, `GetSpecializationInfo`, `GetActiveSpecGroup`, `GetTalentInfo`, `SetDesaturation` |

- `MockClient.apply(mocks, name)` stamps a profile on a mock set and returns the name. `name` defaults to `KA0S_KIT_CLIENT`, else `"retail"`. An unknown name raises, from the environment variable too: a typo that fell back to retail would report green for a profile that never ran.
- `MockClient.current()` answers `"retail"` or `"forever"`: the profile last applied, or the one a fresh apply would choose.
- There is no third profile. A case that wants neither project constant sets the mocks directly.

### `loader.lua`: the profile reaches every mock set

`Loader.makeEnv` applies the active profile once to each mock set it builds an environment over, so a suite sees it with no wiring. `Loader.MockClient` exposes the module. A consumer's own `tests/wow_mock.lua` should drop its `GetBuildInfo` and let the profile answer. The profile overwrites any `WOW_PROJECT_*` or `GetBuildInfo` a suite pre-set on a mock set before its first `makeEnv`.

## What a consumer owes

Re-vendor the kit with the library. A consumer case that pins the build or interface number the old mock returned, or that reads a spec global, must read them off the mock (`GetBuildInfo()`) or branch on `MockClient.current()`, because under `KA0S_KIT_CLIENT=forever` they answer differently.
