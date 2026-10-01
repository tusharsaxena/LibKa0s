# LibKa0s

Built to the **[Ka0s WoW Addon Standard](https://github.com/tusharsaxena/WowAddonStandards)**, v2.72.0,
as a library repo. That is a scope of its own. What binds here is `library-stack-§7`'s applicability
list, not the addon rule set, because there is no TOC, no player-facing README, no settings canvas and
no install. [`CLAUDE.md`](CLAUDE.md) says which sections apply and which do not, and you should read it
before changing anything. [`DEPENDENCIES.md`](DEPENDENCIES.md) lists what to install first.

## What it is

LibKa0s is a Ka0s-owned shared library. Ka0s WoW addons vendor it the way they vendor Ace3: each one
copies it into its own `libs/` folder instead of depending on it at runtime. Every module is one
LibStub major, and fifteen of them ship today:

- `LibKa0s-Core-1.0`: the small stateless seams every other module sits on. That means secret-safe
  stringification, the window skin and its close button, a prefixed chat printer,
  `SafeRegisterEvent`, the pcalled event registration helper that stops one unknown event name from
  taking the rest of a registration block down with it, and `MakeResizable`, the bottom-right grip
  the debug console, the copy windows and the perf panel resize from.
- `LibKa0s-Env-1.0` reads the handful of client facts every addon needs, and reads them one way: the
  TOC manifest, the player's map id and the player's zone labels.
- `LibKa0s-Compat-1.0` holds the version-variant spell and spec readers that two or more addons had
  written the same way, plus the secret-value seam (`IsSecret`, `CanAccess`, `IsSafeKey`) every guard
  checks before it compares.
- `LibKa0s-Lifecycle-1.0` is the stand-down latch. An addon can have many reasons to go inert, but
  there is one way down and one way back up. `disabled` and `perf` are two named holds on one set,
  and releasing one never brings back an addon the other is still holding down.
- `LibKa0s-Bus-1.0` keeps the stand-down record for an addon's tracked bus receivers. When the addon
  stands down, every registration goes down; when it stands up, exactly what it wants now comes back.
  The strict declare-once message catalog (`Catalog`) lives here too.
- `LibKa0s-Schema-1.0`: the settings schema's runtime, minus the schema. You get the dotted-path
  primitives, the row registry, the single write seam, the bulk bracket, the profile reset's count
  and the load-time shape check.
- `LibKa0s-Pool-1.0` is the free/active widget pool this collection kept rewriting, keyed and
  unkeyed. Acquire order survives a release.
- `LibKa0s-Item-1.0` treats item identity as four primitives with no policy: read a link, name a
  quality, ask the client to cache an id.
- `LibKa0s-Media-1.0` carries the art and type the collection draws with, inside the payload, along
  with the paths that reach them and the LibSharedMedia registration.
- `LibKa0s-Widgets-1.0` has the flat-skin dropdown button, the reorderable-list drag, the unlocked
  drag handle a player moves a frame by, and the one popup menu that every instance of the dropdown
  drops, shared process-wide.
- `LibKa0s-DebugLog-1.0` is the on-screen debug console: the window, the copy window, the two
  formatters, the buffer, and the seam that turns logging on and off.
- `LibKa0s-Slash-1.0`: the slash dispatcher, the help renderer, the schema CLI
  (`list`/`get`/`set`/`reset`/`resetall`/`version`), the shared `profile` verb and the type-aware
  value parser.
- `LibKa0s-Launcher-1.0` builds the minimap button and the broker plugin as ONE LibDataBroker
  object, registered twice. Neither broker library is a dependency.
- `LibKa0s-Options-1.0` has the most files: ten, under one major. It holds the Blizzard settings-canvas
  shell, the translation from schema row to AceGUI widget, the page's chrome (the tab strip, the
  banner, the header block, the secondary strip and the nav rail), the two-column flow engine that
  lays a page out, and the schema composers that expand one declaration into a canonical block.
- `LibKa0s-Perf-1.0` runs a repeatable A/B performance capture for one host addon.

Every module except Core requires Core, and refuses to register without it.

Each module's full contract lives in [`docs/api/`](docs/api/), one document per shipped version:
the decisions that shaped it, its `lib:New` descriptor and its public surface. This file maps the
modules and points you there. It does not restate them.

## Installing

1. Copy `LibKa0s/` into `<Addon>/libs/LibKa0s/`. Copy the whole folder, every time. The modules are
   siblings that ship as one released copy, and every file except `Core.lua` returns without
   registering anything when `Core.lua` is missing or older than the minor it needs. If `Options.lua`
   bails that way, `OptionsRegistry.lua`, `OptionsWidgets.lua`, `OptionsIds.lua`, `OptionsIdList.lua`,
   `OptionsTabs.lua`, `OptionsCombat.lua`, `OptionsCompose.lua`, `OptionsScroll.lua` and `OptionsNav.lua`
   bail too, on their own `LibStub("LibKa0s-Options-1.0", true)` lookup, so the whole ten-file module
   is absent instead of half-attached. `WidgetsReorder.lua` and `WidgetsDragHandle.lua` do the same
   behind `Widgets.lua`, and `PerfCommands.lua` and `PerfPanel.lua` behind `Perf.lua`.
   Since v1.48.0 the folder has carried one more file than it used to. That is why you copy the whole
   folder, and never just the files you happen to have.
2. Add `libs\LibKa0s\LibKa0s.xml` to the TOC's lib block, after Ace3.
3. If you adopt Perf, declare `## SavedVariables: <Addon>PerfDB` in the TOC. That is the global name
   you'll pass as the descriptor's `sv`. Core and DebugLog persist nothing.

Do **not** list LibKa0s under `## Dependencies:`. It is vendored, not depended on, and every Ka0s
addon must work with no other addon installed.

## The modules

There are fifteen LibStub majors, and a host adopts each one independently. The full contract for
each (the descriptor, every public member, every row field) lives in [`docs/api/`](docs/api/), one
document per shipped version. This section is the map and that directory is the reference. Nothing
here restates a signature, because a second copy of a contract is a contract that drifts.

| Major | What it is | Files | Current version |
|---|---|---|---|
| `LibKa0s-Core-1.0` | The secret-safe seam, the shared window skin, and the prefixed chat printer. It depends on LibStub and nothing else, and that is what keeps the rest adoptable by non-Ace addons. | `Core.lua` | [9](docs/api/Core/version-9-docs.md) |
| `LibKa0s-Env-1.0` | The handful of client facts every Ka0s addon reads, read one way: the TOC manifest, the player's map id and the player's zone labels. It has no state, no frames and no events. | `Env.lua` | [1](docs/api/Env/version-1-docs.md) |
| `LibKa0s-Compat-1.0` | The version-variant client readers that two or more Ka0s addons wrote the same way: `GetSpellInfo`, `GetSpellName`, `GetSpellTexture`, `GetSpellCooldown`, `GetSpecialization` and `GetSpecializationInfo`, each a ladder from the namespaced API down to the deprecated global. Add the secret-value seam every guard asks before it compares (`IsSecret`, `CanAccess`, `IsSafeKey`) and you have nine stateless functions, with no frames, no events and no addon framework. | `Compat.lua` | [1](docs/api/Compat/version-1-docs.md) |
| `LibKa0s-Lifecycle-1.0` | The stand-down latch: a hold set, an edge, and two host callbacks. `standDown` fires only when the set goes from empty to non-empty and `standUp` only when it goes back to empty, so a perf run that ends under a `disabled` hold does not bring the addon back. There is deliberately no `StandUp()` member, because a bare stand-up is the bug the latch exists to prevent. Persists nothing. | `Lifecycle.lua` | [3](docs/api/Lifecycle/version-3-docs.md) |
| `LibKa0s-Bus-1.0` | The stand-down record for an addon's tracked bus receivers. `New` builds an instance whose `NewTarget` hands out AceEvent targets that remember what they are registered for, so `StandDown` takes every event and message down and `StandUp` puts back what is wanted now, `arg` included. Beside it sits `Catalog`, the strict declare-once message catalog, which validates the `Ka0s_<Addon>_<Event>` names at load and raises on a mistyped key. Bus owns no hold set; the host calls it from its own Lifecycle callbacks. AceEvent is resolved at call time, never required. | `Bus.lua` | [2](docs/api/Bus/version-2-docs.md) |
| `LibKa0s-Schema-1.0` | The settings schema's runtime without the schema. The host keeps its rows, and this module supplies the dotted-path primitives (`SplitPath`, `Read`, `Write`, `SameValue`), the path index, the single write seam `Set` and its all-or-nothing batch `SetMany`, the bulk bracket that makes a sweep one debug line, the profile reset's changed-row count and `Validate`. It owns no storage, sends no message and formats no value. | `Schema.lua` | [2](docs/api/Schema/version-2-docs.md) |
| `LibKa0s-Pool-1.0` | The free/active widget pool this collection kept rewriting, in a keyed and an unkeyed form. `ReleaseAll` parks backward, so a position gets its own object back on the next pass. The keyed form leaves order undefined on purpose. | `Pool.lua` | [3](docs/api/Pool/version-3-docs.md) |
| `LibKa0s-Item-1.0` | Item identity as four primitives and no policy: read an item link, name a quality, ask the client to cache an id. What an uncached item *means* stays the host's decision, because two addons here disagree about it in writing. | `Item.lua` | [2](docs/api/Item/version-2-docs.md) |
| `LibKa0s-Media-1.0` | The art and type this collection draws with: 113 white icon TGAs (Open Iconic, MIT), seven generated statusbar textures, and JetBrains Mono (SIL OFL). All of it sits inside the payload, along with the paths that reach it and the LibSharedMedia registration. | `Media.lua`, `media/` | [4](docs/api/Media/version-4-docs.md) |
| `LibKa0s-Widgets-1.0` | The collection's flat-skin dropdown button and the one popup menu every instance of it drops, shared process-wide across addons. Then `ReorderList`, which gives any list drag-to-reorder: the handle, the copy carried under the cursor, the insertion line, the bounded box each row sits in and the clamp, but no row content at all. And `DragHandle`, the labeled strip with a help mark (and optionally a close mark) that a player drags a movable frame by. Widgets takes its art and its glyph face as parameters, because a vendored copy cannot know which addon folder it sits in. | `Widgets.lua`, `WidgetsReorder.lua`, `WidgetsDragHandle.lua` | [12.1.3](docs/api/Widgets/version-12.1.3-docs.md) |
| `LibKa0s-DebugLog-1.0` | The on-screen debug console (movable window, color-coded log, copy box, and the one seam that turns logging on and off), plus the diagnostics report a player sends with a bug report, the change gates (log once, log on change) the console re-arms on Clear and on enable, and the at-enable queue that holds a state line written while logging is off until it is turned on. The library writes the markers, the identity header and the cap, and runs each section an addon supplies under its own pcall. | `DebugLog.lua`, `DebugLogDiagnostics.lua`, `DebugLogGates.lua` | [18.2.1](docs/api/DebugLog/version-18.2.1-docs.md) |
| `LibKa0s-Slash-1.0` | The slash dispatcher, help renderer, schema CLI and type-aware value parser. In other words, everything between "the user typed `/at something`" and "a setting changed". | `Slash.lua` | [19](docs/api/Slash/version-19-docs.md) |
| `LibKa0s-Launcher-1.0` | The minimap button and the broker plugin, as ONE LibDataBroker-1.1 object of `type = "launcher"` registered twice: with LibDBIcon-1.0 for the button, and with whatever broker display the player runs. It has one `OnClick`, implementing launcher-§2. Left-click opens the settings panel; right-click opens the client's context menu of the toggles the host supplies (Enabled, Locked, Test mode, Show window). There is one library-drawn status tooltip (launcher-§1), and LibDBIcon's own `minimap` table comes from the host. Neither broker library is a dependency. Both are resolved with `LibStub(…, true)` at register time, and every degradation is named, not raised. | `Launcher.lua` | [5](docs/api/Launcher/version-5-docs.md) |
| `LibKa0s-Options-1.0` | The settings panel: canvas shell, page registry, lazy Defaults button, the refresh trio, five widget makers, a grid of one-choice-per-row checkbox cells, an input and list for adding spells, items or currencies by id, link or name, the two-column flow engine, the tab strip every page draws, the nav rail a page that edits one instance out of many may lead with, and the schema composers that expand one declaration into a canonical font / border / bar / Master-controls block. It also carries the one registry fixup that has to be the library's, because AceGUI's widget table is shared by every addon in the client. | `Options.lua`, `OptionsRegistry.lua`, `OptionsWidgets.lua`, `OptionsIds.lua`, `OptionsIdList.lua`, `OptionsTabs.lua`, `OptionsCombat.lua`, `OptionsCompose.lua`, `OptionsScroll.lua`, `OptionsNav.lua` | [27.2.34.2.2.8.1.7.4.2](docs/api/Options/version-27.2.34.2.2.8.1.7.4.2-docs.md) |
| `LibKa0s-Perf-1.0` | A repeatable A/B performance capture for one host: the probe, the guided run, the record, and the clickable step panel. | `Perf.lua`, `PerfCommands.lua`, `PerfPanel.lua` | [14.1.6](docs/api/Perf/version-14.1.6-docs.md) |

Every major except Core depends on LibStub and `LibKa0s-Core-1.0`, and on no addon framework. Each
one returns before `NewLibrary` if Core is missing or below the minor it needs. So a consumer that
copied a new `Perf.lua` over an old `Core.lua` gets no probe at all, rather than a half-updated one.

One Options asymmetry is worth knowing before you plan a page around it: **`RenderGrid` does not
lay out.** `RenderRows` ends with `scroll:DoLayout()`; `RenderGrid` does not, because hosts render
several grids into one page and lay out once. Call `container:DoLayout()` after your last render.

### Finding the document for the copy you are running

Ask the game, not the changelog. Each major publishes `lib.MODULES`, which names the live minor of
every file in that major. Join those numbers in load order and you have the filename:

```lua
/dump LibStub("LibKa0s-Options-1.0").MODULES
--> { Options = 7, OptionsWidgets = 7, OptionsScroll = 3 }
--> docs/api/Options/version-7.7.3-docs.md
```

[`docs/api/README.md`](docs/api/README.md) indexes every shipped version of every major, the release
that carried it, and the minors that were never shipped at all.

### Two contracts, two different rules

The API (`lib:New`, descriptor fields, instance members) is **additive-only forever**. A later minor
may add a field but never removes or repurposes one, so a host written against minor 1 keeps working,
unmodified, against any later minor.

The record schema is the Perf capture persisted to SavedVariables, and it plays by the opposite
rule. Schema 2 was a clean break from schema 1, with no migration. That is exactly why it has its own
document, [`docs/record-schema.md`](docs/record-schema.md).

## The `L` trap

Every module that takes an `L` override resolves it with `rawget`: the host's table first, then the
module's own `STRINGS`. That choice is deliberate. `rawget` makes the override safe against a locale
table with a metatable fallback, and every Ka0s addon has one of those, because the standard mandates
it (anti-patterns #2, "AceLocale strict mode — use metatable fallback"):

```lua
local L = setmetatable({}, { __index = function(_, k) return k end })   -- locales/enUS.lua
```

On such a table, `L["STEP_START"]` answers `"STEP_START"`. Before `DebugLog` minor 3 / `Slash` minor 3
/ `Perf` minor 4, the resolver used a plain index. It took that synthesized string at face value and
never reached this library's own strings. Hosts rendered raw keys (`STEP_START`,
`PANEL_TITLE_SUFFIX`, `LIST_HEADER`) in place of English, for every key at once, and nothing showed
it outside the game. KickCD shipped a perf panel titled `Ka0s KickCDPANEL_TITLE_SUFFIX` this way.

`rawget` asks the question the resolver should have asked all along: *did the host actually put a value here?* A
genuine entry still overrides, and a fallback-only table falls through as it should. **You no longer
have to strip your locale table before passing it.** The guidance below is still the clearer habit,
though, and it keeps a host working against an older vendored copy:

- If you translate nothing, omit `L`. That is the common case, and it is what AbsorbTracker does for
  every module.
- If you translate something, build a plain table of just those keys:

  ```lua
  L = { LIST_HEADER = ("|cff33ff99%s|r"):format(NS.L["Available settings"]) },
  ```

  The values may come from the locale table. The table you pass must not be it.
- You **SHOULD NOT** pass `NS.L`, an AceLocale table, or anything else whose `__index` synthesizes a
  value for an unknown key. From the minors above it is safe. Still, a host that does it gets no
  override at all for the keys it *did* translate through the fallback, and it breaks outright
  against any older vendored copy that still has the plain-index resolver.

A host suite can pin this cheaply: assert that a rendered label does not match `^[A-Z][A-Z0-9_]+$`.
A resolved string is prose. An unresolved one is the key, and no English label is SCREAMING_SNAKE_CASE.

## Development

Run the green gate from the repo root before every commit:

```bash
lua tests/run.lua
luacheck .
```

Both must be 0/0 before a release. `lua tests/run.lua` reports
`N passed, 0 failed, S skipped, N total`, and `luacheck .` reports `0 warnings / 0 errors`. A skipped
case is a case that did not run. It never counts as a pass, and the suite prints the reason beside it.

`docs/test-cases.md` is the generated inventory of what the suite covers, and it is the authoritative
case count. Regenerate it in the same change that adds or removes a test:

```bash
lua tests/run.lua --list > docs/test-cases.md
```

`--list` builds every suite and prints the case names without running them, which also makes it the
quickest way to check that a new suite file is actually wired into the suite list. The renderer in
`testkit/framework.lua` writes CRLF itself, matching the `.gitattributes` convention for `docs/`. You
don't need a `| sed 's/$/\r/'` on the end. A regeneration command with a pipeline in it is one that
somebody eventually runs without the pipeline.

### The shared test kit

`testkit/` holds the registry, the assertions, the source loader and the universal half of the
WoW-API mock. The whole collection shares it, and each addon vendors it as `tests/_kit/`. It is not a
LibStub major and it never ships, but it does carry a plain revision integer, `Kit.VERSION` (exposed
to suites as `KIT_VERSION`), so a consumer can say which copy it holds. Its full surface is in
[`docs/api/testkit/`](docs/api/testkit/), indexed alongside the majors, and
[`testkit/README.md`](./testkit/README.md) covers what it is and the vendoring discipline.

This repo consumes its own kit through `tests/_kit/` instead of reaching into `testkit/` directly.
That puts LibKa0s on the same terms as every addon: a kit change that would break a consumer breaks
this repo first. `tests/test_kitsync.lua` enforces the byte-identity, so nobody has to trust a
remembered `diff -r`. It checks every file, README included, with no line-ending normalization.

### Versioning

There are two version numbers, and they are not the same thing. The repo carries a semver tag for
humans. Separately, each **file** in `LibKa0s/` carries a LibStub **minor** integer, bumped on every
released change to that file. LibStub compares that minor when it picks a winner between two
vendored copies, so a released change that skips its bump never reaches a host that already carries
the old copy.

Each major publishes its own `lib.MODULES`, naming the live minor of every file *in that major*.
There is no single combined table, because the majors are independent and a host may hold a
different vendored copy of each. As of **v1.65.0**, which moves eleven files' minors (Slash, DebugLog, Options, OptionsRegistry, OptionsWidgets, OptionsIds, OptionsIdList, OptionsTabs, OptionsNav, Launcher, Lifecycle), adds one file (DebugLogGates) and adds no major: `Core = { Core = 9 }`,
`Env = { Env = 1 }`, `Compat = { Compat = 1 }`, `Lifecycle = { Lifecycle = 3 }`, `Bus = { Bus = 2 }`,
`Schema = { Schema = 2 }`, `Pool = { Pool = 3 }`, `Item = { Item = 2 }`,
`Media = { Media = 4 }`,
`Widgets = { Widgets = 11, WidgetsDragHandle = 3 }`, `DebugLog = { DebugLog = 18, DebugLogDiagnostics = 2, DebugLogGates = 1 }`, `Slash = { Slash = 18 }`,
`Launcher = { Launcher = 5 }`,
`Options = { Options = 27, OptionsRegistry = 2, OptionsWidgets = 33, OptionsIds = 2, OptionsIdList = 2, OptionsTabs = 7, OptionsCombat = 1, OptionsCompose = 7, OptionsScroll = 4, OptionsNav = 2 }`,
`Perf = { Perf = 13, PerfPanel = 6 }`. Those numbers move every release, so read them from the top of
each file, or from the newest version block in [CHANGELOG.md](CHANGELOG.md), not from here. Grouping
by major is what lets you answer "which panel is attached to which probe?" from inside the game, once
several addons each ship their own vendored copy. `tests/test_versioning.lua` checks that `MODULES`
and the version block in `CHANGELOG.md` agree, so a bump cannot land without its changelog entry, and
an entry cannot land without its bump.

Those same numbers name the API document for the copy in front of you:
`{ Options = 8, OptionsWidgets = 7, OptionsScroll = 3 }` is
[`docs/api/Options/version-8.7.3-docs.md`](docs/api/Options/version-8.7.3-docs.md). A minor bump is
not released until its API document exists; see [`docs/api/README.md`](docs/api/README.md).

[docs/releasing.md](docs/releasing.md) has the full release order: bump, changelog, regenerate, tag,
then **re-vendor every consumer**. That last step is the one that gets forgotten. It has been
forgotten once already, with both repos' suites green the whole time.

Re-vendoring is **whole-folder**, never file by file. Every major except Core (Env, Compat, Lifecycle,
Bus, Schema, Pool, Item, Media, Widgets, DebugLog, Slash, Launcher, Options and Perf) resolves
`LibKa0s-Core-1.0` before it calls `NewLibrary`, and returns outright if Core is missing or below the
minor it needs. A consumer that copied a new `Perf.lua` over an old `Core.lua` gets no probe at all,
not a half-updated one, and the host's setup stub then says "perf is not installed". That is the
honest answer. AbsorbTracker's `core/DebugLogSetup.lua` and `settings/OptionsSetup.lua` report the
same way for their modules.

## Repo layout

```
LibKa0s/            -- the only folder that ships; vendor this into <Addon>/libs/LibKa0s/
  LibKa0s.xml        -- lib load list, referenced from the host addon's TOC lib block; Core first
  Core.lua           -- LibKa0s-Core-1.0, MINOR at the top of the file
  Env.lua            -- LibKa0s-Env-1.0, MINOR at the top of the file; needs Core
  Compat.lua         -- LibKa0s-Compat-1.0, MINOR at the top of the file; needs Core
  Lifecycle.lua      -- LibKa0s-Lifecycle-1.0, MINOR at the top of the file; needs Core
  Bus.lua            -- LibKa0s-Bus-1.0, MINOR at the top of the file; needs Core
  Schema.lua         -- LibKa0s-Schema-1.0, MINOR at the top of the file; needs Core
  Pool.lua           -- LibKa0s-Pool-1.0, MINOR at the top of the file; needs Core
  Item.lua           -- LibKa0s-Item-1.0, MINOR at the top of the file; needs Core
  Media.lua          -- LibKa0s-Media-1.0, MINOR at the top of the file; needs Core
  media/             -- THE ONLY NON-CODE PAYLOAD: icons/ (113 white TGAs, Open Iconic MIT),
                        textures/ (7 generated statusbar bars) and fonts/ (JetBrains Mono, SIL
                        OFL); the two third-party sets carry their license beside them
  Widgets.lua        -- LibKa0s-Widgets-1.0, MINOR at the top of the file; needs Core
  WidgetsReorder.lua -- ReorderList and the row box, same module, REORDER_MINOR of its own
  WidgetsDragHandle.lua -- the unlocked drag handle, same module, DRAG_MINOR of its own
  DebugLog.lua       -- LibKa0s-DebugLog-1.0, MINOR at the top of the file; needs Core
  DebugLogDiagnostics.lua -- the diagnostics report, same module, DIAG_MINOR of its own
  DebugLogGates.lua  -- the change gates and the at-enable queue, same module, GATES_MINOR
  Slash.lua          -- LibKa0s-Slash-1.0, MINOR at the top of the file; needs Core
  Launcher.lua       -- LibKa0s-Launcher-1.0, MINOR at the top of the file; needs Core
  Options.lua        -- LibKa0s-Options-1.0, MINOR at the top of the file; needs Core
  OptionsRegistry.lua -- the page registry, the category and its combat park, REGISTRY_MINOR
  OptionsWidgets.lua -- the makers + the flow engine, same module, WIDGETS_MINOR of its own
  OptionsIds.lua     -- id resolution, suggestions and the id input, same module, IDS_MINOR
  OptionsIdList.lua  -- the editable id list, same module, IDLIST_MINOR of its own
  OptionsTabs.lua    -- the page's chrome: strip, banner, header block, sub-strip, TABS_MINOR
  OptionsCombat.lua  -- the combat lock's event frame, dispatcher and cover, COMBAT_MINOR
  OptionsCompose.lua -- the schema composers, same module, COMPOSE_MINOR of its own
  OptionsScroll.lua  -- the always-shown scrollbar patch, same module, SCROLL_MINOR of its own
  OptionsNav.lua     -- the nav rail a page may lead with, same module, NAV_MINOR of its own
  Perf.lua           -- LibKa0s-Perf-1.0, MINOR at the top of the file; needs Core
  PerfCommands.lua   -- the perf command surface a host wires in, same module, COMMANDS_MINOR of its own
  PerfPanel.lua      -- the clickable step panel, part of the same module, PANEL_MINOR of its own
  LICENSE            -- ships INSIDE the payload, so every vendored copy carries the MIT notice
tools/gen-api-members.lua -- writes docs/api/<Major>/members-<version-key>.json from the LIVE
                        surface, loaded through the same mock the suites use. Generated, never
                        hand-edited; tests/test_versioning.lua regenerates and compares on every run
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
                        after that version stops being current; api/README.md indexes them all.
                        Beside each, <Major>/members-<minors>.json -- the same version's public
                        surface as DATA, which is what a degradation stub is checked against
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
