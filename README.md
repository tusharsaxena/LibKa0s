# LibKa0s

Built to the **[Ka0s WoW Addon Standard](https://github.com/tusharsaxena/WowAddonStandards)**, v2.28.0
— as a **library repo**, which is a scope of its own: `library-stack-§7`'s applicability list is what
binds here, not the addon rule set, because there is no TOC, no player-facing README, no settings
canvas and no install. [`CLAUDE.md`](CLAUDE.md) spells out which sections apply and which do not, and
is the first file to read before changing anything. [`DEPENDENCIES.md`](DEPENDENCIES.md) is what to
install first.

## What it is

A Ka0s-owned shared library, vendored into Ka0s WoW addons the way Ace3 is — copied into each
addon's `libs/` folder rather than depended on at runtime. One LibStub major per module. Ten
modules ship today:

- **`LibKa0s-Core-1.0`** — the small stateless seams every other module sits on: secret-safe
  stringification, the window skin and its close button, and a prefixed chat printer.
- **`LibKa0s-Env-1.0`** — the handful of client facts every addon reads, read one way: the TOC
  manifest, the player's map id and the player's zone labels.
- **`LibKa0s-Pool-1.0`** — the free/active widget pool this collection kept rewriting, keyed and
  unkeyed, with the acquire order preserved across a release.
- **`LibKa0s-Item-1.0`** — item identity as four primitives and no policy: read a link, name a
  quality, ask the client to cache an id.
- **`LibKa0s-Media-1.0`** — the art and type the collection draws with, inside the payload, plus the
  paths that reach them and the LibSharedMedia registration.
- **`LibKa0s-Widgets-1.0`** — the flat-skin dropdown button, the reorderable-list drag, and the one popup menu every instance of
  it drops, shared process-wide.
- **`LibKa0s-DebugLog-1.0`** — the on-screen debug console: the window, the copy window, the two
  formatters, the buffer, and the seam that turns logging on and off.
- **`LibKa0s-Slash-1.0`** — the slash dispatcher, the help renderer, the schema CLI
  (`list`/`get`/`set`/`reset`/`resetall`/`version`) and the type-aware value parser.
- **`LibKa0s-Options-1.0`** — the Blizzard settings-canvas shell, the schema-row to AceGUI widget
  translation, and the two-column flow engine that lays a page out. Three files, one major.
- **`LibKa0s-Perf-1.0`** — a repeatable A/B performance capture for one host addon.

Every module but Core requires Core, and refuses to register without it.

Each module's full contract — the decisions that shaped it, its `lib:New` descriptor, its public
surface — lives in [`docs/api/`](docs/api/), one document per shipped version. This file maps the
modules and points there; it does not restate them.

## Installing

1. Copy `LibKa0s/` into `<Addon>/libs/LibKa0s/` — the whole folder, every time. The modules are
   siblings that ship as one released copy, and every file but `Core.lua` returns without
   registering at all when `Core.lua` is missing or older than the minor it needs. When `Options.lua` bails that way, `OptionsWidgets.lua` and `OptionsScroll.lua`
   bail too on their own `LibStub("LibKa0s-Options-1.0", true)` lookup, so the whole three-file
   module is absent rather than half-attached.
2. Add `libs\LibKa0s\LibKa0s.xml` to the TOC's lib block, after Ace3.
3. If you adopt Perf, declare `## SavedVariables: <Addon>PerfDB` in the TOC (the global name you'll
   pass as the descriptor's `sv`). Core and DebugLog persist nothing.

Do **not** list LibKa0s under `## Dependencies:` — it is vendored, not depended on, and every Ka0s
addon must work with no other addon installed.

## The modules

Ten LibStub majors, adopted independently. **The full contract for each — the descriptor, every
public member, every row field — lives in [`docs/api/`](docs/api/), one document per shipped
version.** This section is the map; that directory is the reference. Nothing here restates a
signature, because a second copy of a contract is a contract that drifts.

| Major | What it is | Files | Current version |
|---|---|---|---|
| `LibKa0s-Core-1.0` | The secret-safe seam, the shared window skin, and the prefixed chat printer. Depends on LibStub and nothing else, which is what keeps the rest adoptable by non-Ace addons. | `Core.lua` | [6](docs/api/Core/version-6-docs.md) |
| `LibKa0s-Env-1.0` | The handful of client facts every Ka0s addon reads, read one way: the TOC manifest, the player's map id and the player's zone labels. No state, no frames, no events. | `Env.lua` | [1](docs/api/Env/version-1-docs.md) |
| `LibKa0s-Pool-1.0` | The free/active widget pool this collection kept rewriting, in a keyed and an unkeyed form. `ReleaseAll` parks backward, so a position gets its own object back on the next pass; the keyed form leaves order undefined on purpose. | `Pool.lua` | [3](docs/api/Pool/version-3-docs.md) |
| `LibKa0s-Item-1.0` | Item identity as four primitives and no policy — read an item link, name a quality, ask the client to cache an id. What an uncached item *means* stays the host's decision, because two addons here disagree in writing. | `Item.lua` | [1](docs/api/Item/version-1-docs.md) |
| `LibKa0s-Media-1.0` | The art and type this collection draws with: 113 white icon TGAs (Open Iconic, MIT), seven generated statusbar textures, and JetBrains Mono (SIL OFL) — all inside the payload, plus the paths that reach them and the LibSharedMedia registration. | `Media.lua`, `media/` | [3](docs/api/Media/version-3-docs.md) |
| `LibKa0s-Widgets-1.0` | The collection's flat-skin dropdown button and the one popup menu every instance of it drops — shared process-wide, across addons — plus `ReorderList`, which gives any list drag-to-reorder: the handle, the copy carried under the cursor, the insertion line and the clamp, and no row content at all. Takes its art and its glyph face as parameters, because a vendored copy cannot know which addon folder it sits in. | `Widgets.lua` | [8](docs/api/Widgets/version-8-docs.md) |
| `LibKa0s-DebugLog-1.0` | The on-screen debug console: movable window, colour-coded log, copy box, and the one seam that turns logging on and off. | `DebugLog.lua` | [12](docs/api/DebugLog/version-12-docs.md) |
| `LibKa0s-Slash-1.0` | The slash dispatcher, help renderer, schema CLI and type-aware value parser — everything between "the user typed `/at something`" and "a setting changed". | `Slash.lua` | [7](docs/api/Slash/version-7-docs.md) |
| `LibKa0s-Options-1.0` | The settings panel: canvas shell, page registry, lazy Defaults button, the refresh trio, five widget makers and the two-column flow engine. | `Options.lua`, `OptionsWidgets.lua`, `OptionsScroll.lua` | [8.7.3](docs/api/Options/version-8.7.3-docs.md) |
| `LibKa0s-Perf-1.0` | A repeatable A/B performance capture for one host: the probe, the guided run, the record, and the clickable step panel. | `Perf.lua`, `PerfPanel.lua` | [7.4](docs/api/Perf/version-7.4-docs.md) |

Every major but Core depends on LibStub and `LibKa0s-Core-1.0` and on no addon framework, and each
returns before `NewLibrary` if Core is missing or below the minor it needs — so a consumer that
copied a new `Perf.lua` over an old `Core.lua` gets no probe at all rather than a half-updated one.

### Finding the document for the copy you are running

Ask the game, not the changelog. Each major publishes `lib.MODULES`, naming the live minor of every
file in that major; those numbers, joined in load order, are the filename:

```lua
/dump LibStub("LibKa0s-Options-1.0").MODULES
--> { Options = 7, OptionsWidgets = 7, OptionsScroll = 3 }
--> docs/api/Options/version-7.7.3-docs.md
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

Both must be 0/0 before a release — `lua tests/run.lua` reports
`N passed, 0 failed, S skipped, N total`, and `luacheck .` reports
`0 warnings / 0 errors`. A skipped case is a case that did not run — never a pass — and the
suite prints why beside it.

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
different vendored copy of each. As of **v1.19.0**: `Core = { Core = 6 }`,
`Env = { Env = 1 }`, `Pool = { Pool = 3 }`, `Item = { Item = 1 }`, `Media = { Media = 3 }`,
`Widgets = { Widgets = 8 }`, `DebugLog = { DebugLog = 12 }`, `Slash = { Slash = 7 }`,
`Options = { Options = 9, OptionsWidgets = 8, OptionsScroll = 3 }`,
`Perf = { Perf = 7, PerfPanel = 4 }`. Those numbers move every release — read them from the top of
each file, or from the newest version block in [CHANGELOG.md](CHANGELOG.md), rather than from here.
That per-major grouping is what answers "which panel is
attached to which probe?" from in-game, once several addons each ship their own vendored copy.
`tests/test_versioning.lua` enforces that `MODULES` and `CHANGELOG.md`'s version block agree, so a
bump cannot land without its changelog entry, nor an entry without its bump.

Those same numbers name the API document for the copy in front of you —
`{ Options = 8, OptionsWidgets = 7, OptionsScroll = 3 }` is
[`docs/api/Options/version-8.7.3-docs.md`](docs/api/Options/version-8.7.3-docs.md). A minor bump is
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
  Env.lua            -- LibKa0s-Env-1.0, MINOR at the top of the file; needs Core
  Pool.lua           -- LibKa0s-Pool-1.0, MINOR at the top of the file; needs Core
  Item.lua           -- LibKa0s-Item-1.0, MINOR at the top of the file; needs Core
  Media.lua          -- LibKa0s-Media-1.0, MINOR at the top of the file; needs Core
  media/             -- THE ONLY NON-CODE PAYLOAD: icons/ (113 white TGAs, Open Iconic MIT),
                        textures/ (7 generated statusbar bars) and fonts/ (JetBrains Mono, SIL
                        OFL); the two third-party sets carry their license beside them
  Widgets.lua        -- LibKa0s-Widgets-1.0, MINOR at the top of the file; needs Core
  DebugLog.lua       -- LibKa0s-DebugLog-1.0, MINOR at the top of the file; needs Core
  Slash.lua          -- LibKa0s-Slash-1.0, MINOR at the top of the file; needs Core
  Options.lua        -- LibKa0s-Options-1.0, MINOR at the top of the file; needs Core
  OptionsWidgets.lua -- the makers + the flow engine, same module, WIDGETS_MINOR of its own
  OptionsScroll.lua  -- the always-shown scrollbar patch, same module, SCROLL_MINOR of its own
  Perf.lua           -- LibKa0s-Perf-1.0, MINOR at the top of the file; needs Core
  PerfPanel.lua      -- the clickable step panel, part of the same module, PANEL_MINOR of its own
  LICENSE            -- ships INSIDE the payload, so every vendored copy carries the MIT notice
tools/artwork/       -- icon_cleaner.py rebuilds media/icons/ from Open Iconic; bar_textures.py
                        synthesizes media/textures/ from named constants. Both ARE the provenance
                        record for their art -- upstream repo and license for the first, every value
                        that decides a pixel for the second. Not shipped, not a build step: the TGAs
                        are committed and the tools are how they are regenerated
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
  fast-gate-adoption-prompt.md -- the drop-in brief for adopting the fast test gate in a consumer
  adoption-report.md -- the reusable adoption-fidelity report, run per date into adoption/
  adoption/          -- frozen dated adoption reports, one folder per run
  test-cases.md      -- generated case inventory
  automated-tests/   -- the out-of-game test record: README.md (the local how-to), RESULTS.md
                        (one row per run, overwritten in place — its git history is the trend
                        line) and one frozen <YYYYMMDD-HHMMSS>/ bundle per run, never edited
                        after it is written and never pruned
  audits/            -- frozen dated standards-audit bundles
  reviews/           -- frozen dated review bundles
  superpowers/       -- the extraction plans and design specs, kept as the record of why
LICENSE              -- also copied into LibKa0s/ above, so the payload carries it
README.md
CLAUDE.md            -- which standards sections bind a LIBRARY repo, and the compliance directive
DEPENDENCIES.md      -- the toolchain: lua5.1 (setfenv), luacheck, lizard, and how to install them
CHANGELOG.md         -- required at a library root, unlike an addon root: tests/test_versioning.lua
                        asserts it accounts for the version every file is at
.luacheckrc
```
