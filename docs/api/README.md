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
docs/api/<Major>/members-<version-key>.json
```

## The member manifest beside each document

The document is prose: accurate, versioned, and not something a test can compare anything against.
`members-<version-key>.json` is the same major's **public surface as data** — every member the
version publishes, with its type — generated from the live module by `tools/gen-api-members.lua`,
never hand-edited, and regenerated and compared on every run by
`tests/test_versioning.lua`.

It exists because eleven addons in this collection hand-write a degradation stub of a LibKa0s surface,
and until now the only way a stub author could answer "what am I obliged to carry?" was to read the
library's source at whatever moment they read it. That is how AbsorbTracker's Options stub came to
omit `SetRenderer` with every suite in that repository green. The kit's
`Kit.assertSurfaceParity(stub, majorName)` enforces exactly this list, and
`Kit.publicMembers` is the one rule both it and the generator apply: no `MAJOR`, no `MINOR`, no
`MODULES`, no `__`-prefixed internals — a stub owes none of those.

It is keyed by version for the same reason the document is. A single `members.json` describing only
HEAD answers the wrong question for every consumer that has not re-vendored yet, which is the whole
failure this directory's shape was built to prevent.

```sh
lua tools/gen-api-members.lua      # from the repo root; rewrites every manifest
```

## Reading the version key

The version key is the module's **LibStub file minors**, in load order, joined with dots. It is
exactly what that major's `lib.MODULES` reports in-game, so the number you read from the game names
the file you need:

| Major | Key shape | In-game check |
|---|---|---|
| `LibKa0s-Core-1.0` | `<Core>` | `LibStub("LibKa0s-Core-1.0").MODULES` |
| `LibKa0s-Env-1.0` | `<Env>` | `LibStub("LibKa0s-Env-1.0").MODULES` |
| `LibKa0s-Compat-1.0` | `<Compat>` | `LibStub("LibKa0s-Compat-1.0").MODULES` |
| `LibKa0s-Lifecycle-1.0` | `<Lifecycle>` | `LibStub("LibKa0s-Lifecycle-1.0").MODULES` |
| `LibKa0s-Bus-1.0` | `<Bus>` | `LibStub("LibKa0s-Bus-1.0").MODULES` |
| `LibKa0s-Schema-1.0` | `<Schema>` | `LibStub("LibKa0s-Schema-1.0").MODULES` |
| `LibKa0s-Pool-1.0` | `<Pool>` | `LibStub("LibKa0s-Pool-1.0").MODULES` |
| `LibKa0s-Item-1.0` | `<Item>` | `LibStub("LibKa0s-Item-1.0").MODULES` |
| `LibKa0s-Media-1.0` | `<Media>` | `LibStub("LibKa0s-Media-1.0").MODULES` |
| `LibKa0s-Widgets-1.0` | `<Widgets>.<WidgetsDragHandle>` | `LibStub("LibKa0s-Widgets-1.0").MODULES` |
| `LibKa0s-DebugLog-1.0` | `<DebugLog>` | `LibStub("LibKa0s-DebugLog-1.0").MODULES` |
| `LibKa0s-Slash-1.0` | `<Slash>` | `LibStub("LibKa0s-Slash-1.0").MODULES` |
| `LibKa0s-Launcher-1.0` | `<Launcher>` | `LibStub("LibKa0s-Launcher-1.0").MODULES` |
| `LibKa0s-Options-1.0` | `<Options>.<OptionsWidgets>.<OptionsTabs>.<OptionsCompose>.<OptionsScroll>.<OptionsNav>` | `LibStub("LibKa0s-Options-1.0").MODULES` |
| `LibKa0s-Perf-1.0` | `<Perf>.<PerfPanel>` | `LibStub("LibKa0s-Perf-1.0").MODULES` |

A multi-file major gets a composite key because its files carry **independent** minors that really do
diverge — the Options major has passed through `O3/W2`, `O3/W3`, `O4/W4` and `O4/W5`. Keying on one
file's minor would have collapsed two genuinely different states into one filename. The files are not
independently adoptable: whole-folder vendoring is what keeps a shell from one copy and a flow engine
from another out of the wild, and LibStub cannot detect that mismatch if it happens.

**A key gains a component when its major gains a file.** The Options key ran three numbers through
`13.12.3`, four from `14.13.1.3` where `OptionsCompose.lua` joined the major, and five from
`21.20.1.7.3` where `OptionsTabs.lua` did, six from `25.31.5.7.4.1` where `OptionsNav.lua` did, eight
from `25.32.1.1.5.7.4.1` where `OptionsIds.lua` and `OptionsIdList.lua` did, nine from
`25.32.1.1.6.1.7.4.1` where `OptionsCombat.lua` did, and ten from `26.1.32.1.1.6.1.7.4.1` where
`OptionsRegistry.lua` did. The order is
load order — `LibKa0s.xml`'s — which is what `tests/test_versioning.lua` derives the expected
filename from, so the two cannot disagree.

## Every shipped version

`Since` columns inside each document name the minor a member first appeared in, so a single document
answers both "what does this version have?" and "when did I get it?".

### `LibKa0s-Core-1.0`

| Version | Files | Shipped in | Status |
|---|---|---|---|
| [8](./Core/version-8-docs.md) | `Core.lua` 8 | v1.56.0 | **Current** |
| [7](./Core/version-7-docs.md) | `Core.lua` 7 | v1.24.0 – v1.55.0 | Superseded |
| [6](./Core/version-6-docs.md) | `Core.lua` 6 | v1.10.0 – v1.23.0 | Superseded |
| [5](./Core/version-5-docs.md) | `Core.lua` 5 | v1.8.0 – v1.9.2 | Superseded |
| [4](./Core/version-4-docs.md) | `Core.lua` 4 | v1.7.0 | Superseded |
| [3](./Core/version-3-docs.md) | `Core.lua` 3 | v1.3.0 – v1.6.3 | Superseded |
| [2](./Core/version-2-docs.md) | `Core.lua` 2 | v1.0.0 – v1.2.0 | Superseded |

### `LibKa0s-Env-1.0`

| Version | Files | Shipped in | Status |
|---|---|---|---|
| [1](./Env/version-1-docs.md) | `Env.lua` 1 | v1.15.0 | **Current** |

### `LibKa0s-Compat-1.0`

| Version | Files | Shipped in | Status |
|---|---|---|---|
| [1](./Compat/version-1-docs.md) | `Compat.lua` 1 | v1.55.0 | **Current** |

### `LibKa0s-Lifecycle-1.0`

| Version | Files | Shipped in | Status |
|---|---|---|---|
| [2](./Lifecycle/version-2-docs.md) | `Lifecycle.lua` 2 | v1.56.0 | **Current** |
| [1](./Lifecycle/version-1-docs.md) | `Lifecycle.lua` 1 | v1.40.0 | Superseded |

### `LibKa0s-Bus-1.0`

| Version | Files | Shipped in | Status |
|---|---|---|---|
| [2](./Bus/version-2-docs.md) | `Bus.lua` 2 | v1.56.0 | **Current** |
| [1](./Bus/version-1-docs.md) | `Bus.lua` 1 | v1.55.0 | Superseded |

### `LibKa0s-Schema-1.0`

| Version | Files | Shipped in | Status |
|---|---|---|---|
| [2](./Schema/version-2-docs.md) | `Schema.lua` 2 | v1.56.0 | **Current** |
| [1](./Schema/version-1-docs.md) | `Schema.lua` 1 | v1.55.0 | Superseded |

### `LibKa0s-Pool-1.0`

| Version | Files | Shipped in | Status |
|---|---|---|---|
| [3](./Pool/version-3-docs.md) | `Pool.lua` 3 | v1.17.0 | **Current** |
| [2](./Pool/version-2-docs.md) | `Pool.lua` 2 | v1.16.0 | Superseded |
| [1](./Pool/version-1-docs.md) | `Pool.lua` 1 | v1.15.0 | Superseded |

### `LibKa0s-Item-1.0`

| Version | Files | Shipped in | Status |
|---|---|---|---|
| [2](./Item/version-2-docs.md) | `Item.lua` 2 | v1.56.0 | **Current** |
| [1](./Item/version-1-docs.md) | `Item.lua` 1 | v1.15.0 – v1.55.0 | Superseded |

### `LibKa0s-Media-1.0`

| Version | Files | Shipped in | Status |
|---|---|---|---|
| [4](./Media/version-4-docs.md) | `Media.lua` 4 | v1.56.0 | **Current** |
| [3](./Media/version-3-docs.md) | `Media.lua` 3 | v1.9.2 – v1.55.0 | Superseded |
| [2](./Media/version-2-docs.md) | `Media.lua` 2 | v1.9.1 | Superseded |
| [1](./Media/version-1-docs.md) | `Media.lua` 1 | v1.9.0 | Superseded |

### `LibKa0s-Widgets-1.0`

| Version | Files | Shipped in | Status |
|---|---|---|---|
| [10.3](./Widgets/version-10.3-docs.md) | `Widgets.lua` 10 · `WidgetsDragHandle.lua` 3 | v1.59.0 | **Current** |
| [10.2](./Widgets/version-10.2-docs.md) | `Widgets.lua` 10 · `WidgetsDragHandle.lua` 2 | v1.56.0 – v1.58.0 | Superseded |
| [9.2](./Widgets/version-9.2-docs.md) | `Widgets.lua` 9 · `WidgetsDragHandle.lua` 2 | v1.48.1 – v1.55.0 | Superseded |
| [9.1](./Widgets/version-9.1-docs.md) | `Widgets.lua` 9 · `WidgetsDragHandle.lua` 1 | v1.48.0 | Superseded |
| [9](./Widgets/version-9-docs.md) | `Widgets.lua` 9 | v1.24.0 – v1.47.0 | Superseded |
| [8](./Widgets/version-8-docs.md) | `Widgets.lua` 8 | v1.19.0 – v1.23.0 | Superseded |
| [7](./Widgets/version-7-docs.md) | `Widgets.lua` 7 | v1.16.0 | Superseded |
| [6](./Widgets/version-6-docs.md) | `Widgets.lua` 6 | v1.15.0 | Superseded |
| [5](./Widgets/version-5-docs.md) | `Widgets.lua` 5 | v1.13.0 | Superseded |
| [4](./Widgets/version-4-docs.md) | `Widgets.lua` 4 | v1.12.0 | Superseded |
| [3](./Widgets/version-3-docs.md) | `Widgets.lua` 3 | v1.11.2 | Superseded |
| [2](./Widgets/version-2-docs.md) | `Widgets.lua` 2 | v1.11.1 | Superseded |
| [1](./Widgets/version-1-docs.md) | `Widgets.lua` 1 | v1.11.0 | Superseded |

### `LibKa0s-DebugLog-1.0`

| Version | Files | Shipped in | Status |
|---|---|---|---|
| [14.1](./DebugLog/version-14.1-docs.md) | `DebugLog.lua` 14 · `DebugLogDiagnostics.lua` 1 | v1.60.0 | **Current** |
| [13](./DebugLog/version-13-docs.md) | `DebugLog.lua` 13 | v1.56.0 – v1.59.0 | Superseded |
| [12](./DebugLog/version-12-docs.md) | `DebugLog.lua` 12 | v1.16.0 | Superseded |
| [11](./DebugLog/version-11-docs.md) | `DebugLog.lua` 11 | v1.15.0 | Superseded |
| [10](./DebugLog/version-10-docs.md) | `DebugLog.lua` 10 | v1.10.1 – v1.13.0 | Superseded |
| [9](./DebugLog/version-9-docs.md) | `DebugLog.lua` 9 | v1.10.0 | Superseded |
| [8](./DebugLog/version-8-docs.md) | `DebugLog.lua` 8 | v1.8.0 – v1.9.2 | Superseded |
| [7](./DebugLog/version-7-docs.md) | `DebugLog.lua` 7 | v1.5.0 – v1.7.0 | Superseded |
| [6](./DebugLog/version-6-docs.md) | `DebugLog.lua` 6 | v1.3.1, v1.4.0 | Superseded |
| [5](./DebugLog/version-5-docs.md) | `DebugLog.lua` 5 | v1.3.0 | Superseded |
| [4](./DebugLog/version-4-docs.md) | `DebugLog.lua` 4 | v1.2.0 | Superseded |
| [3](./DebugLog/version-3-docs.md) | `DebugLog.lua` 3 | v1.0.0, v1.1.0, v1.1.1 | Superseded |

### `LibKa0s-Slash-1.0`

| Version | Files | Shipped in | Status |
|---|---|---|---|
| [16](./Slash/version-16-docs.md) | `Slash.lua` 16 | v1.60.0 | **Current** |
| [15](./Slash/version-15-docs.md) | `Slash.lua` 15 | v1.56.0 – v1.59.0 | Superseded |
| [14](./Slash/version-14-docs.md) | `Slash.lua` 14 | v1.42.0 | Superseded |
| [13](./Slash/version-13-docs.md) | `Slash.lua` 13 | v1.41.0 | Superseded |
| [12](./Slash/version-12-docs.md) | `Slash.lua` 12 | v1.40.0 | Superseded |
| [11](./Slash/version-11-docs.md) | `Slash.lua` 11 | v1.38.0 | Superseded |
| [10](./Slash/version-10-docs.md) | `Slash.lua` 10 | v1.34.0 – v1.37.0 | Superseded |
| [9](./Slash/version-9-docs.md) | `Slash.lua` 9 | v1.33.0 | Superseded |
| [8](./Slash/version-8-docs.md) | `Slash.lua` 8 | v1.32.0 | Superseded |
| [7](./Slash/version-7-docs.md) | `Slash.lua` 7 | v1.8.0 – v1.31.0 | Superseded |
| [6](./Slash/version-6-docs.md) | `Slash.lua` 6 | v1.7.0 | Superseded |
| [5](./Slash/version-5-docs.md) | `Slash.lua` 5 | v1.2.0 – v1.6.3 | Superseded |
| [4](./Slash/version-4-docs.md) | `Slash.lua` 4 | v1.0.0, v1.1.0, v1.1.1 | Superseded |

### `LibKa0s-Launcher-1.0`

| Version | Files | Shipped in | Status |
|---|---|---|---|
| [4](./Launcher/version-4-docs.md) | `Launcher.lua` 4 | v1.58.0 | **Current** |
| [3](./Launcher/version-3-docs.md) | `Launcher.lua` 3 | v1.57.0 | Superseded |
| [2](./Launcher/version-2-docs.md) | `Launcher.lua` 2 | v1.56.0 | Superseded |
| [1](./Launcher/version-1-docs.md) | `Launcher.lua` 1 | v1.39.0 | Superseded |

### `LibKa0s-Options-1.0`

| Version | Files | Shipped in | Status |
|---|---|---|---|
| [26.1.32.1.1.6.1.7.4.1](./Options/version-26.1.32.1.1.6.1.7.4.1-docs.md) | `Options.lua` 26 · `OptionsRegistry.lua` 1 · `OptionsWidgets.lua` 32 · `OptionsIds.lua` 1 · `OptionsIdList.lua` 1 · `OptionsTabs.lua` 6 · `OptionsCombat.lua` 1 · `OptionsCompose.lua` 7 · `OptionsScroll.lua` 4 · `OptionsNav.lua` 1 | v1.62.0 | **Current** |
| [25.32.1.1.6.1.7.4.1](./Options/version-25.32.1.1.6.1.7.4.1-docs.md) | `Options.lua` 25 · `OptionsWidgets.lua` 32 · `OptionsIds.lua` 1 · `OptionsIdList.lua` 1 · `OptionsTabs.lua` 6 · `OptionsCombat.lua` 1 · `OptionsCompose.lua` 7 · `OptionsScroll.lua` 4 · `OptionsNav.lua` 1 | unreleased | Superseded |
| [25.32.1.1.5.7.4.1](./Options/version-25.32.1.1.5.7.4.1-docs.md) | `Options.lua` 25 · `OptionsWidgets.lua` 32 · `OptionsIds.lua` 1 · `OptionsIdList.lua` 1 · `OptionsTabs.lua` 5 · `OptionsCompose.lua` 7 · `OptionsScroll.lua` 4 · `OptionsNav.lua` 1 | unreleased | Superseded |
| [25.31.5.7.4.1](./Options/version-25.31.5.7.4.1-docs.md) | `Options.lua` 25 · `OptionsWidgets.lua` 31 · `OptionsTabs.lua` 5 · `OptionsCompose.lua` 7 · `OptionsScroll.lua` 4 · `OptionsNav.lua` 1 | v1.61.0 | Superseded |
| [24.31.4.7.4](./Options/version-24.31.4.7.4-docs.md) | `Options.lua` 24 · `OptionsWidgets.lua` 31 · `OptionsTabs.lua` 4 · `OptionsCompose.lua` 7 · `OptionsScroll.lua` 4 | v1.56.0 – v1.60.0 | Superseded |
| [23.30.3.7.3](./Options/version-23.30.3.7.3-docs.md) | `Options.lua` 23 · `OptionsWidgets.lua` 30 · `OptionsTabs.lua` 3 · `OptionsCompose.lua` 7 · `OptionsScroll.lua` 3 | v1.53.0 – v1.55.0 | Superseded |
| [23.29.3.7.3](./Options/version-23.29.3.7.3-docs.md) | `Options.lua` 23 · `OptionsWidgets.lua` 29 · `OptionsTabs.lua` 3 · `OptionsCompose.lua` 7 · `OptionsScroll.lua` 3 | v1.52.0 | Superseded |
| [23.28.3.7.3](./Options/version-23.28.3.7.3-docs.md) | `Options.lua` 23 · `OptionsWidgets.lua` 28 · `OptionsTabs.lua` 3 · `OptionsCompose.lua` 7 · `OptionsScroll.lua` 3 | v1.51.0 | Superseded |
| [23.27.3.7.3](./Options/version-23.27.3.7.3-docs.md) | `Options.lua` 23 · `OptionsWidgets.lua` 27 · `OptionsTabs.lua` 3 · `OptionsCompose.lua` 7 · `OptionsScroll.lua` 3 | v1.50.0 | Superseded |
| [23.26.3.7.3](./Options/version-23.26.3.7.3-docs.md) | `Options.lua` 23 · `OptionsWidgets.lua` 26 · `OptionsTabs.lua` 3 · `OptionsCompose.lua` 7 · `OptionsScroll.lua` 3 | v1.49.1 | Superseded |
| [23.25.3.7.3](./Options/version-23.25.3.7.3-docs.md) | `Options.lua` 23 · `OptionsWidgets.lua` 25 · `OptionsTabs.lua` 3 · `OptionsCompose.lua` 7 · `OptionsScroll.lua` 3 | v1.49.0 | Superseded |
| [23.24.3.7.3](./Options/version-23.24.3.7.3-docs.md) | `Options.lua` 23 · `OptionsWidgets.lua` 24 · `OptionsTabs.lua` 3 · `OptionsCompose.lua` 7 · `OptionsScroll.lua` 3 | v1.47.0 | Superseded |
| [23.23.3.7.3](./Options/version-23.23.3.7.3-docs.md) | `Options.lua` 23 · `OptionsWidgets.lua` 23 · `OptionsTabs.lua` 3 · `OptionsCompose.lua` 7 · `OptionsScroll.lua` 3 | v1.46.1 | Superseded |
| [22.23.2.7.3](./Options/version-22.23.2.7.3-docs.md) | `Options.lua` 22 · `OptionsWidgets.lua` 23 · `OptionsTabs.lua` 2 · `OptionsCompose.lua` 7 · `OptionsScroll.lua` 3 | v1.46.0 | Superseded |
| [21.22.1.7.3](./Options/version-21.22.1.7.3-docs.md) | `Options.lua` 21 · `OptionsWidgets.lua` 22 · `OptionsTabs.lua` 1 · `OptionsCompose.lua` 7 · `OptionsScroll.lua` 3 | v1.45.0 | Superseded |
| [21.21.1.7.3](./Options/version-21.21.1.7.3-docs.md) | `Options.lua` 21 · `OptionsWidgets.lua` 21 · `OptionsTabs.lua` 1 · `OptionsCompose.lua` 7 · `OptionsScroll.lua` 3 | v1.44.0 | Superseded |
| [21.20.1.7.3](./Options/version-21.20.1.7.3-docs.md) | `Options.lua` 21 · `OptionsWidgets.lua` 20 · `OptionsTabs.lua` 1 · `OptionsCompose.lua` 7 · `OptionsScroll.lua` 3 | v1.39.0 – v1.43.0 | Superseded |
| [20.19.6.3](./Options/version-20.19.6.3-docs.md) | `Options.lua` 20 · `OptionsWidgets.lua` 19 · `OptionsCompose.lua` 6 · `OptionsScroll.lua` 3 | v1.37.0 – v1.38.0 | Superseded |
| [20.19.5.3](./Options/version-20.19.5.3-docs.md) | `Options.lua` 20 · `OptionsWidgets.lua` 19 · `OptionsCompose.lua` 5 · `OptionsScroll.lua` 3 | v1.36.2 | Superseded |
| [19.19.5.3](./Options/version-19.19.5.3-docs.md) | `Options.lua` 19 · `OptionsWidgets.lua` 19 · `OptionsCompose.lua` 5 · `OptionsScroll.lua` 3 | v1.36.2 | Superseded |
| [19.18.5.3](./Options/version-19.18.5.3-docs.md) | `Options.lua` 19 · `OptionsWidgets.lua` 18 · `OptionsCompose.lua` 5 · `OptionsScroll.lua` 3 | v1.36.1 | Superseded |
| [19.17.5.3](./Options/version-19.17.5.3-docs.md) | `Options.lua` 19 · `OptionsWidgets.lua` 17 · `OptionsCompose.lua` 5 · `OptionsScroll.lua` 3 | v1.36.0 | Superseded |
| [18.16.5.3](./Options/version-18.16.5.3-docs.md) | `Options.lua` 18 · `OptionsWidgets.lua` 16 · `OptionsCompose.lua` 5 · `OptionsScroll.lua` 3 | v1.35.0 | Superseded |
| [18.15.5.3](./Options/version-18.15.5.3-docs.md) | `Options.lua` 18 · `OptionsWidgets.lua` 15 · `OptionsCompose.lua` 5 · `OptionsScroll.lua` 3 | v1.34.0 | Superseded |
| [17.15.4.3](./Options/version-17.15.4.3-docs.md) | `Options.lua` 17 · `OptionsWidgets.lua` 15 · `OptionsCompose.lua` 4 · `OptionsScroll.lua` 3 | v1.33.0 | Superseded |
| [16.15.4.3](./Options/version-16.15.4.3-docs.md) | `Options.lua` 16 · `OptionsWidgets.lua` 15 · `OptionsCompose.lua` 4 · `OptionsScroll.lua` 3 | v1.32.0 | Superseded |
| [15.15.4.3](./Options/version-15.15.4.3-docs.md) | `Options.lua` 15 · `OptionsWidgets.lua` 15 · `OptionsCompose.lua` 4 · `OptionsScroll.lua` 3 | v1.31.0 | Superseded |
| [15.14.3.3](./Options/version-15.14.3.3-docs.md) | `Options.lua` 15 · `OptionsWidgets.lua` 14 · `OptionsCompose.lua` 3 · `OptionsScroll.lua` 3 | v1.27.0 – v1.30.0 | Superseded |
| [14.14.3.3](./Options/version-14.14.3.3-docs.md) | `Options.lua` 14 · `OptionsWidgets.lua` 14 · `OptionsCompose.lua` 3 · `OptionsScroll.lua` 3 | v1.26.0 | Superseded |
| [14.13.3.3](./Options/version-14.13.3.3-docs.md) | `Options.lua` 14 · `OptionsWidgets.lua` 13 · `OptionsCompose.lua` 3 · `OptionsScroll.lua` 3 | v1.26.0 | Superseded |
| [14.13.2.3](./Options/version-14.13.2.3-docs.md) | `Options.lua` 14 · `OptionsWidgets.lua` 13 · `OptionsCompose.lua` 2 · `OptionsScroll.lua` 3 | v1.25.0 | Superseded |
| [14.13.1.3](./Options/version-14.13.1.3-docs.md) | `Options.lua` 14 · `OptionsWidgets.lua` 13 · `OptionsCompose.lua` 1 · `OptionsScroll.lua` 3 | v1.24.0 | Superseded |
| [13.12.3](./Options/version-13.12.3-docs.md) | `Options.lua` 13 · `OptionsWidgets.lua` 12 · `OptionsScroll.lua` 3 | v1.23.0 | Superseded |
| [12.11.3](./Options/version-12.11.3-docs.md) | `Options.lua` 12 · `OptionsWidgets.lua` 11 · `OptionsScroll.lua` 3 | v1.22.0 | Superseded |
| [11.10.3](./Options/version-11.10.3-docs.md) | `Options.lua` 11 · `OptionsWidgets.lua` 10 · `OptionsScroll.lua` 3 | v1.21.0 | Superseded |
| [10.9.3](./Options/version-10.9.3-docs.md) | `Options.lua` 10 · `OptionsWidgets.lua` 9 · `OptionsScroll.lua` 3 | v1.20.0 | Superseded |
| [9.8.3](./Options/version-9.8.3-docs.md) | `Options.lua` 9 · `OptionsWidgets.lua` 8 · `OptionsScroll.lua` 3 | v1.18.1 – v1.19.0 | Superseded |
| [9.7.3](./Options/version-9.7.3-docs.md) | `Options.lua` 9 · `OptionsWidgets.lua` 7 · `OptionsScroll.lua` 3 | v1.18.0 | Superseded |
| [8.7.3](./Options/version-8.7.3-docs.md) | `Options.lua` 8 · `OptionsWidgets.lua` 7 · `OptionsScroll.lua` 3 | v1.8.3 | Superseded |
| [7.7.3](./Options/version-7.7.3-docs.md) | `Options.lua` 7 · `OptionsWidgets.lua` 7 · `OptionsScroll.lua` 3 | v1.8.0 – v1.8.2 | Superseded |
| [7.6.3](./Options/version-7.6.3-docs.md) | `Options.lua` 7 · `OptionsWidgets.lua` 6 · `OptionsScroll.lua` 3 | unreleased | Superseded |
| [6.6.3](./Options/version-6.6.3-docs.md) | `Options.lua` 6 · `OptionsWidgets.lua` 6 · `OptionsScroll.lua` 3 | v1.7.0 | Superseded |
| [5.5.2](./Options/version-5.5.2-docs.md) | `Options.lua` 5 · `OptionsWidgets.lua` 5 · `OptionsScroll.lua` 2 | v1.2.0 – v1.6.3 | Superseded |
| [4.4.2](./Options/version-4.4.2-docs.md) | `Options.lua` 4 · `OptionsWidgets.lua` 4 · `OptionsScroll.lua` 2 | v1.1.0, v1.1.1 | Superseded |
| [3.3.2](./Options/version-3.3.2-docs.md) | `Options.lua` 3 · `OptionsWidgets.lua` 3 · `OptionsScroll.lua` 2 | v1.0.0 | Superseded |

### `LibKa0s-Perf-1.0`

| Version | Files | Shipped in | Status |
|---|---|---|---|
| [13.5](./Perf/version-13.5-docs.md) | `Perf.lua` 13 · `PerfPanel.lua` 5 | v1.56.0 | **Current** |
| [12.5](./Perf/version-12.5-docs.md) | `Perf.lua` 12 · `PerfPanel.lua` 5 | v1.40.0 – v1.55.0 | Superseded |
| [11.5](./Perf/version-11.5-docs.md) | `Perf.lua` 11 · `PerfPanel.lua` 5 | v1.31.0 | Superseded |
| [10.5](./Perf/version-10.5-docs.md) | `Perf.lua` 10 · `PerfPanel.lua` 5 | v1.29.0 – v1.30.0 | Superseded |
| [9.4](./Perf/version-9.4-docs.md) | `Perf.lua` 9 · `PerfPanel.lua` 4 | v1.28.0 | Superseded |
| [8.4](./Perf/version-8.4-docs.md) | `Perf.lua` 8 · `PerfPanel.lua` 4 | v1.27.0 | Superseded |
| [7.4](./Perf/version-7.4-docs.md) | `Perf.lua` 7 · `PerfPanel.lua` 4 | v1.10.2 — v1.26.0 | Superseded |
| [7.3](./Perf/version-7.3-docs.md) | `Perf.lua` 7 · `PerfPanel.lua` 3 | v1.8.0 – v1.10.1 | Superseded |
| [6.3](./Perf/version-6.3-docs.md) | `Perf.lua` 6 · `PerfPanel.lua` 3 | v1.7.0 | Superseded |
| [5.3](./Perf/version-5.3-docs.md) | `Perf.lua` 5 · `PerfPanel.lua` 3 | v1.0.0 – v1.6.3 (every release to date) | Superseded |

### `testkit`

Not a LibStub major and never shipped — vendored to `<Addon>/tests/_kit/`, and versioned by a plain
`Kit.VERSION` integer rather than by file minors, because the files vendor as one folder and
are never adopted separately. It is indexed here because the question it answers is the same one:
*which copy is this consumer holding?*

| Version | Files | First released in | Status |
|---|---|---|---|
| [27](./testkit/version-27-docs.md) | same files **plus `test_diagnostics_contract.lua`**, the kit's fourth own suite: `debug-logging-§14`'s dispatcher contract, run against the consumer's own slash dispatcher through `Kit.diagnostics` (brand, dispatch, console, setDebug, setDisabled, optional retired names and reset): both forms write one report, the debug word in any case, both markers carry the brand and the end marker counts the lines, the report appends, it lands with logging off and leaves it off, both forms run while disabled, and `diag`, `dx` and the retired names run nothing. With `Kit.diagnostics` unset it registers one declared skip naming the rule, so a re-vendor stays green before the addon has its report. `framework.lua`'s `KIT_GATE_RULE` gains the suite's row | v1.60.0 | **Current** |
| [26](./testkit/version-26-docs.md) | same files **plus `asserts.lua`, `prose_lists.lua` and `mock_events.lua`**, the first two peels with no behavior change: `framework.lua`'s assertions and surface-parity gate move to the first and `test_prose.lua`'s published lists to the second, each loaded from its parent's own folder, which takes both parents back under `layout-§1`'s cap; and two new assertions, `Kit.assertErrorMatches(fn, needle, msg)`, which checks the raised text rather than only that something raised, and `Kit.assertLibraryConstant(value, majorName, memberPath, msg)`, which pins a degradation stub's verbatim copy of a library constant byte for byte against the live library, falling back to the exposed LibStub when the surface source maps the major to an instance; and one **behavioral** change, the AceDB fake's `CopyProfile` and `DeleteProfile` raising AceDB-3.0's own messages on a bad name and `SetProfile` stripping defaults from the outgoing profile; and a third file, **`mock_events.lua`**: a recording `EventRegistry` whose callbacks reach `__registrations()` as kind `callback`, raw frame `RegisterEvent` / `RegisterUnitEvent` raising on a name in `__badEvents`, and `C_EventUtils.IsEventValid`; a **behavioral** flip in `mock_base.lua`, a new frame starting shown as `CreateFrame` hands one back in the client, so `M.__shownFrames()` right after a build lists every frame nothing hid; and two gates widened, `test_eol.lua`'s case one also counting every lone CR over the set it already scans, named as `path:line`, and `test_prose.lua` reading the three store-root files named in `prose_lists.lua`'s new `SCAN_BACK`, skipping `docs/superpowers/` and `docs/investigations/`, and carrying the British stem of *synchronize* (92 / 33); and every section citation in a kit string spelled `<file>-§N`, which **renames four case names** (`line-endings-§5`, `layout-§1`, two `localization-§5`), so a consumer regenerates `docs/test-cases.md`; and two **behavioral** changes in `run-automated-tests.sh`: with no `tests/perf.lua` it reads the `## Documented deviations` register (`docs/ARCHITECTURE.md`, then the root `CLAUDE.md`) and records a Rule cell of exactly `performance-§12` as perf skip reason (2) in the manifest's `skipReason` and in `RESULTS.md`, with `KA0S_PERF_EXEMPT=1` counting only where no register exists, and a register it cannot read (no Rule header, no separator, or a row with no cell after its Rule) **fails the whole run with exit 2** before any suite runs or the bundle is made; and an empty watch-list table in `RESULTS.md` now keeps its header row and separator where revision 25 printed `None.`, so that file changes shape | v1.56.0 – v1.59.0 | Superseded |
| [25](./testkit/version-25-docs.md) | same files **plus `test_layout_cap.lua`**, the kit's third own suite: the `layout-§1` cap gate, reading the over-cap census out of the repo's engineer-context hub and taking the hub and the generated-data exempt set through `Kit.layoutCap`. A declaration becomes the **pair** (basename, directory), so a bare name no longer covers the kit's file of that name — a collision and an unreferenced kit suite are both reported, and a decline recorded in `## Documented deviations` is reported once as a skip. `test_eol.lua` gains a second case over the `.gitattributes` body itself, `test_prose.lua` gains `Kit.prose.exempt` for `localization-§5`'s generated-data carve-out in the shape `Kit.layoutCap.exempt` already uses — with two of that carve-out's three conditions **enforced**, a path any `.toc` loads and a path `.pkgmeta` does not ignore both refused, and the same two refusals applied to the waiver file's `skipDirs` and `skipFiles`, which reach the same scan and were checked against nothing; one disclosure line names every path the gate was narrowed by, whichever list supplied it, with the suppressed count — and the automated-test runner names the commit and the tree state on every `RESULTS.md` row. A declaration's `dir` and the runner's `dir` are also read **against each other**, so a suites list that mixes an absolute and a relative spelling of one directory survives being invoked by path from another working directory, and every remedy prints a `dir` a suites list can actually carry rather than this checkout's resolved path. | v1.55.0 | Superseded |
| [24](./testkit/version-24-docs.md) | same files **plus `test_prose.lua`**, the kit's second own suite: the US-English gate of `localization-5`, carrying both published lists whole and reading an optional per-file, per-word `tests/prose_waivers.lua` for the spellings that are game data or a library's field name rather than the repo's English. Adoption is one line in the runner's suite list; `assertSuiteInventory` goes red until it is there. | v1.54.0 | Superseded |
| [23](./testkit/version-23-docs.md) | same files; the resource guard on load (re-launch depth, process-tree cgroup, `ulimit -v`, timeout), the runner's heap budget, leak gate, CPU ceiling, host-path gate and memory-aware `--jobs`, every suite in `run-automated-tests.sh` bounded, and the `mock_base.lua` build lookup that kept every instance alive | v1.43.0 | Superseded |
| [22](./testkit/version-22-docs.md) | + `mock_record.lua` — the five recording surveys (`__registrations`, `__timers()`, `__shownFrames`, `__svWrites`, `__printed`), `__fire` / `__fireUnconditional`, an `AceBucket-3.0` fake, and the raw `frame:RegisterEvent` the frame stub used to forget; the timer queue and the `AceDB-3.0` fake move there with them | v1.40.0 | Superseded |
| [21](./testkit/version-21-docs.md) | same files; the AceGUI fake's `CheckBox` gains a pooled `check` texture (`SetTexture`, `SetVertexColor`, `GetVertexColor`), so a suite can observe `O.ChoiceGrid`'s gold-fill paint and its restoration on `Release` against the stock fixture, with no per-test monkeypatch needed | v1.36.1 | Superseded |
| [1](./testkit/version-1-docs.md) | `framework.lua` · `loader.lua` · `mock_base.lua` · `README.md` | v1.4.0 | Superseded |
| [2](./testkit/version-2-docs.md) | + `run-automated-tests.sh` | v1.6.0 | Superseded |
| [3](./testkit/version-3-docs.md) | same files; runner fixes | v1.6.1 | Superseded |
| [4](./testkit/version-4-docs.md) | same files; full lizard footer in the manifest | v1.6.2 | Superseded |
| [5](./testkit/version-5-docs.md) | same files; wider RESULTS.md table + subset/stale-header honesty | v1.6.3 | Superseded |
| [6](./testkit/version-6-docs.md) | same files; `Max CCN` measured over every function, and `RESULTS.md` rows actually append in a CRLF repo | v1.7.0 | Superseded |
| [7](./testkit/version-7-docs.md) | same files; runs in a repo with no `.toc`; corrected luacheck install hint | unreleased | Superseded |
| [8](./testkit/version-8-docs.md) | + `vendor_sync.lua`; the skip status, `Loader.xmlFiles`, the suite-inventory gate, `Kit.assertSurfaceParity` | v1.8.0 | Superseded |
| [9](./testkit/version-9-docs.md) | same files; `vendor_sync.lua` reads the provenance line from `CLAUDE.md`, via the new `provenanceFile` opt | v1.8.1 | Superseded |
| [20](./testkit/version-20-docs.md) | + `mock_ids.lua`: opt-in id lookups (`C_Spell`, `C_Item` and `C_CurrencyInfo` by id or name) for `O.ResolveId`, `O.IdInput` and `O.IdList`, installed by a harness rather than the base; the AceGUI fake gains `GetText`, `SetType` and `DisableButton`. Not the geometry flip | v1.35.0 | Superseded |
| [19](./testkit/version-19-docs.md) | same files; the AceDB fake's `ResetProfile` fires `OnProfileReset` with the database **alone**, as AceDB-3.0 does, where revision 18 passed the active profile as a third argument. Not the geometry flip, which moves to 20 at the earliest | v1.34.0 | Superseded |
| [18](./testkit/version-18-docs.md) | same files; the AceDB fake's `CopyProfile` fires `OnProfileCopied` with the **source** profile's key as its third argument, as AceDB-3.0 does, where revision 17 passed the active profile. `OnProfileChanged` and `OnProfileReset` keep theirs. Not the geometry flip, which moves to 19 at the earliest | v1.33.0 | Superseded |
| [17](./testkit/version-17-docs.md) | same files; `mock_base.lua` gains the Ace surfaces six consumer harnesses migrate onto — `NewAddon` honoring its mixin list, `GetAddon`, `NewModule` and the lifecycle driven through `AceAddon.frame`; AceEvent on two CallbackHandler registries (string methods, `arg`, `UnregisterAllMessages`, mid-dispatch queueing, `M.__msgRegistry`, `M.__fireEvent`, `M.__badEvents`); the message registration API on the AceEvent library object (`RegisterMessage`, `UnregisterMessage`, a multi-target `UnregisterAllMessages`); a real AceTimer whose cancellation `__fireTimers` honors and counts, with `C_Timer.NewTimer` handles answering `IsCancelled()`; AceConsole's chat commands; AceGUI's layout registry. `NewAddon(target)` with exactly one table argument keeps revision 16's behavior; any other nameless call raises. Not the geometry flip | v1.31.0 | Superseded |
| [16](./testkit/version-16-docs.md) | same files; `mock_base.lua` models `AceGUI:Release` (with the `__released` recorder), gives an `AceEvent:Embed` target the recorded event half the `NewAddon` target has — one implementation for both — and stamps `Printf` beside `Print`; `vendor_sync.lua` asserts the runner is recorded `100755` in the consumer's git index. Not the geometry flip: `GetHeight` still answers 0 until a test arms a frame | v1.30.0 | Superseded |
| [15](./testkit/version-15-docs.md) | + `test_eol.lua`, the kit's own suite: the line-ending gate now reads the whole `git ls-files` set and ships to every consumer, wired as `{ name = "test_eol", dir = "tests/_kit/" }`; the runner records the skipped count, names both versions on a release row, regenerates the whole of `RESULTS.md`, and writes the complexity watch list and the four standing sections `automated-tests-§4` MUSTs; `mock_base.lua` grows `SetAtlas` and the opt-in `f:__setGeom`, with `GetHeight` still answering 0 until a test arms a frame | v1.27.0 | Superseded |
| [14](./testkit/version-14-docs.md) | same files; `stubFrame` tracks a real enabled state, so `SetEnabled`/`IsEnabled`/`Enable`/`Disable` answer for real | v1.20.0 | Superseded |
| [13](./testkit/version-13-docs.md) | same files; `CreateFrame` records its arguments on the frame it returns, so a suite can ask what a frame was NAMED | v1.16.0 | Superseded |
| [12](./testkit/version-12-docs.md) | same files; the loader caches compiled chunks, `vendor_sync` batches its blob reads, and the runner can fan its suites out across processes with `--jobs` | v1.14.0 | Superseded |
| [11](./testkit/version-11-docs.md) | same files; the vendored-payload gate recurses into subdirectories and compares a binary byte for byte | v1.9.0 | Superseded |
| [10](./testkit/version-10-docs.md) | same files; `run-automated-tests.sh` writes the bundle to the terminator `.gitattributes` declares, read per path with `git check-attr eol` | v1.8.2 | Superseded |

The kit's compatibility rule is the one place this directory's model differs. The library negotiates
skew — LibStub compares minors and the highest copy wins, so an older vendored copy is a *supported
state* and its document describes a thing you may legitimately still be running. The kit does not
negotiate: `tests/test_kitsync.lua` requires byte-identity, so a consumer that differs is **out of
sync**, not on an older version. Its documents exist so a not-yet-re-vendored consumer can be
reasoned about, never to make staying behind supported.

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

Never edit a superseded document to describe new behavior. The point of the folder is that an
adopter on an old copy reads what their copy actually does.

## Related contracts that are not API

| Document | What it covers | Compatibility rule |
|---|---|---|
| [`../record-schema.md`](../record-schema.md) | The Perf capture record persisted to SavedVariables | **Clean break allowed** — schema 2 discarded schema 1 with no migration |
| [`../releasing.md`](../releasing.md) | Version numbering, release order, the re-vendor rule, the Consumers table | — |
| [`../../testkit/README.md`](../../testkit/README.md) | What the test kit *is* and how to vendor it — its surface is [above](#testkit) | Never ships; byte-identity enforced |

The API is additive-only forever; the record schema is not. That is the difference between the two,
and it is why they are separate documents rather than sections of one.
