# The LibKa0s API reference

**This directory is the source of truth for every LibKa0s public contract.** The README, the release
checklist and the adoption report all point here rather than restating a surface — a description of
`lib:New` that lives anywhere else in this repo is either a pointer or a bug.

## Why it is versioned by folder rather than by git

Different addons run different versions of the same module at the same time. Re-vendoring is
whole-folder and per-consumer, so at any given moment AbsorbTracker may be on `Slash` 5 while a
consumer that has not been re-vendored is still on 4 — and both need an answer to "what does *my*
copy do?". Git history can answer that, but only if you already know which commit you are asking
about. A folder per version answers it from the number the addon reports in-game.

So: **one document per shipped version of each major**, named for the version, never edited after
its version stops being current.

```
docs/api/<Major>/version-<version-key>-docs.md
```

## Reading the version key

The version key is the module's **LibStub file minors**, in load order, joined with dots. It is
exactly what that major's `lib.MODULES` reports in-game, so the number you read from the game names
the file you need:

| Major | Key shape | In-game check |
|---|---|---|
| `LibKa0s-Core-1.0` | `<Core>` | `LibStub("LibKa0s-Core-1.0").MODULES` |
| `LibKa0s-DebugLog-1.0` | `<DebugLog>` | `LibStub("LibKa0s-DebugLog-1.0").MODULES` |
| `LibKa0s-Slash-1.0` | `<Slash>` | `LibStub("LibKa0s-Slash-1.0").MODULES` |
| `LibKa0s-Options-1.0` | `<Options>.<OptionsWidgets>.<OptionsScroll>` | `LibStub("LibKa0s-Options-1.0").MODULES` |
| `LibKa0s-Perf-1.0` | `<Perf>.<PerfPanel>` | `LibStub("LibKa0s-Perf-1.0").MODULES` |

A multi-file major gets a composite key because its files carry **independent** minors that really do
diverge — the Options major has passed through `O3/W2`, `O3/W3`, `O4/W4` and `O4/W5`. Keying on one
file's minor would have collapsed two genuinely different states into one filename. The files are not
independently adoptable: whole-folder vendoring is what keeps a shell from one copy and a flow engine
from another out of the wild, and LibStub cannot detect that mismatch if it happens.

## Every shipped version

`Since` columns inside each document name the minor a member first appeared in, so a single document
answers both "what does this version have?" and "when did I get it?".

### `LibKa0s-Core-1.0`

| Version | Files | Shipped in | Status |
|---|---|---|---|
| [3](./Core/version-3-docs.md) | `Core.lua` 3 | v1.3.0, v1.3.1 | **Current** |
| [2](./Core/version-2-docs.md) | `Core.lua` 2 | v1.0.0 – v1.2.0 | Superseded |

### `LibKa0s-DebugLog-1.0`

| Version | Files | Shipped in | Status |
|---|---|---|---|
| [6](./DebugLog/version-6-docs.md) | `DebugLog.lua` 6 | v1.3.1 | **Current** |
| [5](./DebugLog/version-5-docs.md) | `DebugLog.lua` 5 | v1.3.0 | Superseded |
| [4](./DebugLog/version-4-docs.md) | `DebugLog.lua` 4 | v1.2.0 | Superseded |
| [3](./DebugLog/version-3-docs.md) | `DebugLog.lua` 3 | v1.0.0, v1.1.0, v1.1.1 | Superseded |

### `LibKa0s-Slash-1.0`

| Version | Files | Shipped in | Status |
|---|---|---|---|
| [5](./Slash/version-5-docs.md) | `Slash.lua` 5 | v1.2.0, v1.3.0, v1.3.1 | **Current** |
| [4](./Slash/version-4-docs.md) | `Slash.lua` 4 | v1.0.0, v1.1.0, v1.1.1 | Superseded |

### `LibKa0s-Options-1.0`

| Version | Files | Shipped in | Status |
|---|---|---|---|
| [5.5.2](./Options/version-5.5.2-docs.md) | `Options.lua` 5 · `OptionsWidgets.lua` 5 · `OptionsScroll.lua` 2 | v1.2.0, v1.3.0, v1.3.1 | **Current** |
| [4.4.2](./Options/version-4.4.2-docs.md) | `Options.lua` 4 · `OptionsWidgets.lua` 4 · `OptionsScroll.lua` 2 | v1.1.0, v1.1.1 | Superseded |
| [3.3.2](./Options/version-3.3.2-docs.md) | `Options.lua` 3 · `OptionsWidgets.lua` 3 · `OptionsScroll.lua` 2 | v1.0.0 | Superseded |

### `LibKa0s-Perf-1.0`

| Version | Files | Shipped in | Status |
|---|---|---|---|
| [5.3](./Perf/version-5.3-docs.md) | `Perf.lua` 5 · `PerfPanel.lua` 3 | v1.0.0 – v1.3.1 (every release) | **Current** |

## Versions with no document

Minors below the ones tabled above existed only on the way to `v1.0.0`, the first tag. **No consumer
ever vendored them**, so they are named here for completeness and nowhere else:

| Major | Undocumented minors | Why |
|---|---|---|
| `LibKa0s-Core-1.0` | `Core` 1–2 → the shipped state is 2, documented; minor 1 never tagged | Extraction and review-gate commits |
| `LibKa0s-DebugLog-1.0` | `DebugLog` 1–2 | Extraction and review-gate commits |
| `LibKa0s-Slash-1.0` | `Slash` 1–3 | Extraction, review gate, `rawget` L resolution |
| `LibKa0s-Options-1.0` | `Options` 1–2, `OptionsWidgets` 1–2, `OptionsScroll` 1 | Extraction and review-gate commits |
| `LibKa0s-Perf-1.0` | `Perf` 1–4, `PerfPanel` 1–2 | Scaffold through the `interface` fix, all pre-tag |

They remain reconstructible from source — every one of them is at a reachable commit in this repo —
if a reason to write one ever appears.

## Adding a version

A minor bump is not released until its API document exists. The full order is in
[`../releasing.md`](../releasing.md); the part that lives here is:

1. Copy the current document to a new file named for the new version key.
2. Mark the old one `Superseded`, and fill in its `Superseded by` row and its closing
   "Moving to …" section.
3. In the new document: set `Status` to **Current**, fill in `Supersedes`, write the
   **What changed at this version** section, and add a `Since` of the new minor to every member,
   descriptor field or row field the bump introduced.
4. Add the row to the table above.

Never edit a superseded document to describe new behaviour. The point of the folder is that an
adopter on an old copy reads what their copy actually does.

## Related contracts that are not API

| Document | What it covers | Compatibility rule |
|---|---|---|
| [`../record-schema.md`](../record-schema.md) | The Perf capture record persisted to SavedVariables | **Clean break allowed** — schema 2 discarded schema 1 with no migration |
| [`../releasing.md`](../releasing.md) | Version numbering, release order, the re-vendor rule, the Consumers table | — |
| [`../../testkit/README.md`](../../testkit/README.md) | The shared headless test kit, vendored as `tests/_kit/` | Never ships; byte-identity enforced |

The API is additive-only forever; the record schema is not. That is the difference between the two,
and it is why they are separate documents rather than sections of one.
