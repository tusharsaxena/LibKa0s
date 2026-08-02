# LibKa0s

## What it is

A Ka0s-owned shared library, vendored into Ka0s WoW addons the way Ace3 is — copied into each
addon's `libs/` folder rather than depended on at runtime. One LibStub major per module. Five
modules ship today:

- **`LibKa0s-Core-1.0`** — the small stateless seams every other module sits on: secret-safe
  stringification, the window skin and its close button, and a prefixed chat printer.
- **`LibKa0s-DebugLog-1.0`** — the on-screen debug console: the window, the copy window, the two
  formatters, the buffer, and the seam that turns logging on and off.
- **`LibKa0s-Slash-1.0`** — the slash dispatcher, the help renderer, the schema CLI
  (`list`/`get`/`set`/`reset`/`resetall`/`version`) and the type-aware value parser.
- **`LibKa0s-Options-1.0`** — the Blizzard settings-canvas shell, the schema-row to AceGUI widget
  translation, and the two-column flow engine that lays a page out. Three files, one major.
- **`LibKa0s-Perf-1.0`** — a repeatable A/B performance capture for one host addon.

DebugLog, Slash, Options and Perf each require Core and refuse to register without it.

Each module's full contract — the decisions that shaped it, its `lib:New` descriptor, its public
surface — lives in [`docs/api/`](docs/api/), one document per shipped version. This file maps the
modules and points there; it does not restate them.

## Installing

1. Copy `LibKa0s/` into `<Addon>/libs/LibKa0s/` — the whole folder, every time. The modules are
   siblings that ship as one released copy, and `DebugLog.lua`, `Slash.lua`, `Options.lua` and
   `Perf.lua` each return without registering at all when `Core.lua` is missing or older than the
   minor they need. When `Options.lua` bails that way, `OptionsWidgets.lua` and `OptionsScroll.lua`
   bail too on their own `LibStub("LibKa0s-Options-1.0", true)` lookup, so the whole three-file
   module is absent rather than half-attached.
2. Add `libs\LibKa0s\LibKa0s.xml` to the TOC's lib block, after Ace3.
3. If you adopt Perf, declare `## SavedVariables: <Addon>PerfDB` in the TOC (the global name you'll
   pass as the descriptor's `sv`). Core and DebugLog persist nothing.

Do **not** list LibKa0s under `## Dependencies:` — it is vendored, not depended on, and every Ka0s
addon must work with no other addon installed.

## The modules

Five LibStub majors, adopted independently. **The full contract for each — the descriptor, every
public member, every row field — lives in [`docs/api/`](docs/api/), one document per shipped
version.** This section is the map; that directory is the reference. Nothing here restates a
signature, because a second copy of a contract is a contract that drifts.

| Major | What it is | Files | Current version |
|---|---|---|---|
| `LibKa0s-Core-1.0` | The secret-safe seam, the shared window skin, and the prefixed chat printer. Depends on LibStub and nothing else, which is what keeps the rest adoptable by non-Ace addons. | `Core.lua` | [3](docs/api/Core/version-3-docs.md) |
| `LibKa0s-DebugLog-1.0` | The on-screen debug console: movable window, colour-coded log, copy box, and the one seam that turns logging on and off. | `DebugLog.lua` | [6](docs/api/DebugLog/version-6-docs.md) |
| `LibKa0s-Slash-1.0` | The slash dispatcher, help renderer, schema CLI and type-aware value parser — everything between "the user typed `/at something`" and "a setting changed". | `Slash.lua` | [5](docs/api/Slash/version-5-docs.md) |
| `LibKa0s-Options-1.0` | The settings panel: canvas shell, page registry, lazy Defaults button, the refresh trio, five widget makers and the two-column flow engine. | `Options.lua`, `OptionsWidgets.lua`, `OptionsScroll.lua` | [5.5.2](docs/api/Options/version-5.5.2-docs.md) |
| `LibKa0s-Perf-1.0` | A repeatable A/B performance capture for one host: the probe, the guided run, the record, and the clickable step panel. | `Perf.lua`, `PerfPanel.lua` | [5.3](docs/api/Perf/version-5.3-docs.md) |

Every major but Core depends on LibStub and `LibKa0s-Core-1.0` and on no addon framework, and each
returns before `NewLibrary` if Core is missing or below the minor it needs — so a consumer that
copied a new `Perf.lua` over an old `Core.lua` gets no probe at all rather than a half-updated one.

### Finding the document for the copy you are running

Ask the game, not the changelog. Each major publishes `lib.MODULES`, naming the live minor of every
file in that major; those numbers, joined in load order, are the filename:

```lua
/dump LibStub("LibKa0s-Options-1.0").MODULES
--> { Options = 5, OptionsWidgets = 5, OptionsScroll = 2 }
--> docs/api/Options/version-5.5.2-docs.md
```

[`docs/api/README.md`](docs/api/README.md) indexes every shipped version of every major, which
release carried it, and which minors were never shipped at all.

### Two contracts, two different rules

The **API** — `lib:New`, descriptor fields, instance members — is **additive-only forever**: a field
may be added in a later minor, never removed or repurposed, so a host written against minor 1 keeps
working unmodified against any later minor.

The **record schema** — the Perf capture persisted to SavedVariables — is not. Schema 2 took a clean
break from schema 1 with no migration. It is documented separately, in
[`docs/record-schema.md`](docs/record-schema.md), precisely because it obeys the opposite rule.

## The `L` trap

Every module that takes an `L` override resolves it with **`rawget`** — the host's table first, then
the module's own `STRINGS`. `rawget` is deliberate, and it is what makes the override safe against
**a locale table with a metatable fallback** — which is what every Ka0s addon has, because the
standard mandates one (anti-patterns #2, "AceLocale strict mode — use metatable fallback"):

```lua
local L = setmetatable({}, { __index = function(_, k) return k end })   -- locales/enUS.lua
```

`L["STEP_START"]` on such a table answers `"STEP_START"`. Before `DebugLog` minor 3 / `Slash` minor 3
/ `Perf` minor 4 the resolver used a plain index, accepted that synthesised string, and so never
reached this library's own strings — the host rendered raw keys (`STEP_START`,
`PANEL_TITLE_SUFFIX`, `LIST_HEADER`) in place of English, for every key at once, visible only in
game. KickCD shipped a perf panel titled `Ka0s KickCDPANEL_TITLE_SUFFIX` this way.

`rawget` asks the only question that matters — *did the host actually put a value here?* — so a
genuine entry still overrides and a fallback-only table correctly falls through. **You no longer have
to strip your locale table before passing it.** The guidance below is still the clearer habit, and it
is what keeps a host working against an older vendored copy:

- **Translating nothing?** Omit `L`. This is the common case, and it is what AbsorbTracker does for
  every module.
- **Translating something?** Build a plain table of just those keys:

  ```lua
  L = { LIST_HEADER = ("|cff33ff99%s|r"):format(NS.L["Available settings"]) },
  ```

  The values may come from the locale table; the **table you pass** must not be it.
- **SHOULD NOT** pass `NS.L`, an AceLocale table, or anything else whose `__index` synthesises a
  value for an unknown key. It is safe from the minors above, but a host that does so gets no
  override at all from the keys it *did* translate through the fallback, and it breaks outright
  against any older vendored copy still carrying the plain-index resolver.

A host suite can pin this cheaply: assert that a rendered label does not match `^[A-Z][A-Z0-9_]+$`.
A resolved string is prose; an unresolved one is the key, and no English label is SCREAMING_SNAKE_CASE.

## Development

Green gate before every commit, run from the repo root:

```bash
lua tests/run.lua
luacheck .
```

Both must be 0/0 before a release — `lua tests/run.lua` reports `N passed, 0 failed, N total`,
`luacheck .` reports `0 warnings / 0 errors`.

`docs/test-cases.md` is the generated inventory of what the suite covers, and it is the
authoritative case count. Regenerate it in the same change that adds or removes a test:

```bash
lua tests/run.lua --list > docs/test-cases.md
```

`--list` builds every suite and prints the case names without running them, so it is also the
quickest way to see whether a new suite file is actually wired into the suite list. The renderer in
`testkit/framework.lua` writes CRLF itself, matching `docs/`'s `.gitattributes` convention — there
is no `| sed 's/$/\r/'` to remember, because a regeneration command with a pipeline in it is one
someone eventually runs without the pipeline.

### The shared test kit

`testkit/` holds the registry, the assertions, the source loader and the universal half of the
WoW-API mock, shared across the collection and vendored into each addon as `tests/_kit/`. It is
**not** a LibStub major and never ships, but it does carry a plain revision integer — `Kit.VERSION`,
exposed to suites as `KIT_VERSION` — so a consumer can name which copy it holds. Its full surface is
in [`docs/api/testkit/`](docs/api/testkit/), indexed alongside the majors;
[`testkit/README.md`](./testkit/README.md) covers what it is and the vendoring discipline.

This repo consumes its own kit through `tests/_kit/` rather than reaching into `testkit/` directly,
so LibKa0s is a consumer on the same terms as every addon: a kit change that would break a consumer
breaks this repo first. `tests/test_kitsync.lua` enforces the byte-identity rather than trusting a
remembered `diff -r` — every file, README included, no line-ending normalisation.

### Versioning

Two version numbers, and they are not the same thing. The repo carries a semver tag for humans; each
**file** in `LibKa0s/` separately carries a LibStub **minor** integer, bumped on every released change
to that file — that is what LibStub compares when it picks a winner between two vendored copies, so a
released change that skips its bump reaches no host that already carries the old copy.

Each major publishes its own `lib.MODULES`, naming the live minor of every file *in that major* —
there is no single combined table, because the majors are independent and a host may hold a
different vendored copy of each. As of **v1.4.0**: `Core = { Core = 3 }`,
`DebugLog = { DebugLog = 6 }`, `Slash = { Slash = 5 }`,
`Options = { Options = 5, OptionsWidgets = 5, OptionsScroll = 2 }`,
`Perf = { Perf = 5, PerfPanel = 3 }`. Those numbers move every release — read them from the top of
each file, or from the newest version block in [CHANGELOG.md](CHANGELOG.md), rather than from here.
That per-major grouping is what answers "which panel is
attached to which probe?" from in-game, once several addons each ship their own vendored copy.
`tests/test_versioning.lua` enforces that `MODULES` and `CHANGELOG.md`'s version block agree, so a
bump cannot land without its changelog entry, nor an entry without its bump.

Those same numbers name the API document for the copy in front of you —
`{ Options = 5, OptionsWidgets = 5, OptionsScroll = 2 }` is
[`docs/api/Options/version-5.5.2-docs.md`](docs/api/Options/version-5.5.2-docs.md). A minor bump is
not released until its API document exists; see [`docs/api/README.md`](docs/api/README.md).

Full release order — bump, changelog, regenerate, tag, then **re-vendor every consumer** — is in
[docs/releasing.md](docs/releasing.md). That last step is the one that gets forgotten: it already
happened once, with both repos' suites green throughout.

Re-vendoring is **whole-folder**, never file by file. Every dependent major — DebugLog, Slash,
Options and Perf — resolves `LibKa0s-Core-1.0` before it calls `NewLibrary` and returns outright if
Core is missing or below the minor it needs, so a consumer that copied a new `Perf.lua` over an old
`Core.lua` gets no probe at all rather than a half-updated one — the host's setup stub then says
"perf is not installed", which is the honest answer. AbsorbTracker's `core/DebugLogSetup.lua` and
`settings/OptionsSetup.lua` report the same way for their modules.

## Repo layout

```
LibKa0s/            -- the only folder that ships; vendor this into <Addon>/libs/LibKa0s/
  LibKa0s.xml        -- lib load list, referenced from the host addon's TOC lib block; Core first
  Core.lua           -- LibKa0s-Core-1.0, MINOR at the top of the file
  DebugLog.lua       -- LibKa0s-DebugLog-1.0, MINOR at the top of the file; needs Core
  Slash.lua          -- LibKa0s-Slash-1.0, MINOR at the top of the file; needs Core
  Options.lua        -- LibKa0s-Options-1.0, MINOR at the top of the file; needs Core
  OptionsWidgets.lua -- the makers + the flow engine, same module, WIDGETS_MINOR of its own
  OptionsScroll.lua  -- the always-shown scrollbar patch, same module, SCROLL_MINOR of its own
  Perf.lua           -- LibKa0s-Perf-1.0, MINOR at the top of the file; needs Core
  PerfPanel.lua      -- the clickable step panel, part of the same module, PANEL_MINOR of its own
  LICENSE            -- ships INSIDE the payload, so every vendored copy carries the MIT notice
testkit/             -- the shared headless harness, vendored into each addon as tests/_kit/
                        (never shipped: it lives under tests/, which every .pkgmeta already excludes)
                        Kit.VERSION at the top of framework.lua names the revision
tests/               -- this repo's own test harness, consuming testkit/ through tests/_kit/
docs/                -- development docs (not shipped)
  api/               -- THE API REFERENCE, and the source of truth for every public contract
                        <Major>/version-<minors>-docs.md, one per shipped version, never edited
                        after that version stops being current; api/README.md indexes them all
  releasing.md       -- the two version numbers, the release order, the re-vendor rule
  record-schema.md   -- the capture record, field by field
  adoption-prompt.md -- the per-addon adoption prompt
  adoption-report.md -- the reusable adoption-fidelity report, run per date into adoption/
  adoption/          -- frozen dated adoption reports, one folder per run
  test-cases.md      -- generated case inventory
  reviews/           -- frozen dated review bundles
  superpowers/       -- the extraction plans and design specs, kept as the record of why
LICENSE              -- also copied into LibKa0s/ above, so the payload carries it
README.md
CHANGELOG.md
.luacheckrc
```
