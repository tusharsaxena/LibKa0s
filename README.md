# LibKa0s

Built to the **[Ka0s WoW Addon Standard](https://github.com/tusharsaxena/WowAddonStandards)**, v2.89.0,
as a library repo. That is a scope of its own. What binds here is `library-stack-§7`'s applicability
list, not the addon rule set, because there is no TOC, no player-facing README, no settings canvas and
no install. [`CLAUDE.md`](CLAUDE.md) says which sections apply and which do not, and you should read it
before changing anything. [`DEPENDENCIES.md`](DEPENDENCIES.md) lists what to install first.

## What it is

LibKa0s is a Ka0s-owned shared library. Ka0s WoW addons vendor it the way they vendor Ace3: each one
copies it into its own `libs/` folder instead of depending on it at runtime. Every module is one
LibStub major, and eighteen of them ship today:

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
- `LibKa0s-Item-1.0` treats item identity as five primitives with no policy: read a link and its
  bonus ids, name a quality, ask the client to cache an id.
- `LibKa0s-Glow-1.0` is the stateless LibCustomGlow-1.0 driver: one of four glow styles and its knob
  values mapped to LibCustomGlow's positional arguments, with its two traps handled. It resolves
  LibCustomGlow-1.0 at call time and does nothing without it.
- `LibKa0s-Media-1.0` carries the art and type the collection draws with, inside the payload, along
  with the paths that reach them and the LibSharedMedia registration.
- `LibKa0s-Skin-1.0` is the skin engine: which skin each addon wears, chosen per addon, what each
  token resolves to, and the per-addon record of painted frames that lets a skin switch repaint them
  live. It ships nine skins: Ka0s Default (today's look) and eight more drawn from the owner's
  mockups, and an EllesmereUI provider that hands an addon's frames to EllesmereUI's own skin.
- `LibKa0s-Widgets-1.0` has the flat-skin dropdown button, the reorderable-list drag, the unlocked
  drag handle a player moves a frame by, a pooled line chart over a time axis, `SearchBox` (the flat
  filter-bar search box in the dropdown's skin, with a gold focus line), `TestStrip` (the amber band
  a window lays over sample data in test mode), an autocomplete list hung under a search box, and
  the one popup menu that every instance of the dropdown drops, shared
  process-wide.
- `LibKa0s-DebugLog-1.0` is the on-screen debug console: the window, the copy window, the two
  formatters, the buffer, and the seam that turns logging on and off.
- `LibKa0s-Slash-1.0`: the slash dispatcher, the help renderer, the schema CLI
  (`list`/`get`/`set`/`reset`/`resetall`/`version`), the shared `profile` verb and the type-aware
  value parser.
- `LibKa0s-Launcher-1.0` builds the minimap button and the broker plugin as ONE LibDataBroker
  object, registered twice. Neither broker library is a dependency.
- `LibKa0s-Options-1.0` has the most files: thirteen, under one major. It holds the Blizzard
  settings-canvas shell, the translation from schema row to AceGUI widget, the page's chrome (the tab
  strip, the banner, the header block, the secondary strip and the nav rail), the two-column flow
  engine that lays a page out, the drawer that folds a row of choices under a header bar, the key binding model under a
  settings-page Keybindings tab, the Appearance tab where a player picks an addon's skin, and the schema composers that expand one declaration into a canonical block.
- `LibKa0s-Perf-1.0` runs a repeatable A/B performance capture for one host addon.
- `LibKa0s-Sim-1.0` is the in-client simulator's shell. So far it is the Compat answer seam: a
  host's own Compat table, wrapped in place once, that answers from the simulator while a session
  runs and costs one field test per call while none does, and the session that binds it: start and
  its refusals, the two-phase stop, simulated event delivery and timers that die with the session,
  the step machine that plays a scenario's steps behind the host's gate, the typed verbs every
  host's `sim` slash verb shares, and the docked step panel that clicks through them.

Every module except Core requires Core, and refuses to register without it.

Each module's full contract lives in [`docs/api/`](docs/api/), one document per shipped version:
the decisions that shaped it, its `lib:New` descriptor and its public surface. This file maps the
modules and points you there. It does not restate them.

## Installing

1. Copy `LibKa0s/` into `<Addon>/libs/LibKa0s/`. Copy the whole folder, every time. The modules are
   siblings that ship as one released copy, and every file except `Core.lua` returns without
   registering anything when `Core.lua` is missing or older than the minor it needs. If `Options.lua`
   bails that way, `OptionsRegistry.lua`, `OptionsWidgets.lua`, `OptionsIds.lua`, `OptionsIdList.lua`,
   `OptionsTabs.lua`, `OptionsCombat.lua`, `OptionsCompose.lua`, `OptionsScroll.lua`, `OptionsNav.lua`,
   `OptionsDrawer.lua`, `OptionsKeybinds.lua` and `OptionsAppearance.lua` bail too, on their own `LibStub("LibKa0s-Options-1.0", true)` lookup, so the whole thirteen-file module
   is absent instead of half-attached. `WidgetsReorder.lua`, `WidgetsDragHandle.lua`, `WidgetsLineChart.lua`, `WidgetsAutocomplete.lua` and `WidgetsCopyWindow.lua` do the same
   behind `Widgets.lua`, `SkinDefs.lua`, `SkinPaint.lua`, `SkinPaintExtras.lua`, `SkinPaintControls.lua`, `SkinEUI.lua` and `SkinAce.lua` behind `Skin.lua` (the extras, the controls and the AceGUI rows also behind `SkinPaint.lua`, whose painter helpers they use), `SlashParse.lua` behind `Slash.lua`, and `PerfSampler.lua`, `PerfCommands.lua` and
   `PerfPanel.lua` behind `Perf.lua`, and `SimTimeline.lua` and `SimPanel.lua` behind `Sim.lua`.
   `SimPanel.lua` also returns when Widgets is absent, since its scenario picker is a
   `W.Dropdown`; the simulator then runs headless from its slash verb, with no panel.
   Since v1.48.0 the folder has carried one more file than it used to. That is why you copy the whole
   folder, and never just the files you happen to have.
   **The one exception is `media/icons/`** (`library-stack-§7`, standard v2.85.0): it holds 5,836 icons,
   about 18 MB (28 MB on disk), and an addon ships only the icons it declares. Put one line directly under the
   provenance line in the addon's `CLAUDE.md` — `LibKa0s icons: all (icon picker).` for an addon whose
   UI lets the player choose among the catalog, `LibKa0s icons: none.`, or the names it draws,
   `LibKa0s icons: settings, close, ph:sword.` — then, after the copy, run
   `lua tools/prune-icons.lua <Addon>` from this checkout. The addon's vendor-sync gate (kit revision
   40) holds the copy to that line; see [docs/releasing.md](docs/releasing.md#re-vendoring-consumers).
   Icons the library draws for you count as yours: `close` (`Core.MakeCloseButton`, so the debug
   console, the perf panel and the Widgets copy window), `clear` and `copy` (the debug console) and
   `info` (the Options id list's help mark). A host that wires the debug console declares at least
   `close, copy, clear`; a pruned one draws blank, not the text fallback. Those four are the whole
   set, and it is closed at v1.75.0 (`library-stack-§7`, standard v2.86.0): no later release resolves
   a further name from your folder, and art you pass to a library widget (`W.TestStrip`'s mark, the
   simulator panel's step marks) is your own use, declared as such.
2. Add `libs\LibKa0s\LibKa0s.xml` to the TOC's lib block, after Ace3.
3. If you adopt Perf, declare `## SavedVariables: <Addon>PerfDB` in the TOC. That is the global name
   you'll pass as the descriptor's `sv`. Core and DebugLog persist nothing.

Do **not** list LibKa0s under `## Dependencies:`. It is vendored, not depended on, and every Ka0s
addon must work with no other addon installed.

## The modules

There are eighteen LibStub majors, and a host adopts each one independently. The full contract for
each (the descriptor, every public member, every row field) lives in [`docs/api/`](docs/api/), one
document per shipped version. This section is the map and that directory is the reference. Nothing
here restates a signature, because a second copy of a contract is a contract that drifts.

| Major | What it is | Files | Current version |
|---|---|---|---|
| `LibKa0s-Core-1.0` | The secret-safe seam, the shared window skin, and the prefixed chat printer. It depends on LibStub and nothing else, and that is what keeps the rest adoptable by non-Ace addons. | `Core.lua` | [13](docs/api/Core/version-13-docs.md) |
| `LibKa0s-Env-1.0` | The handful of client facts every Ka0s addon reads, read one way: the TOC manifest, the player's map id and the player's zone labels. It has no state, no frames and no events. | `Env.lua` | [2](docs/api/Env/version-2-docs.md) |
| `LibKa0s-Compat-1.0` | The version-variant client readers that two or more Ka0s addons wrote the same way: `GetSpellInfo`, `GetSpellName`, `GetSpellTexture`, `GetSpellCooldown`, `GetSpecialization` and `GetSpecializationInfo`, each a ladder from the namespaced API down to the deprecated global. Add the secret-value seam every guard asks before it compares (`IsSecret`, `CanAccess`, `IsSafeKey`) and you have nine stateless functions, with no frames, no events and no addon framework. | `Compat.lua` | [1](docs/api/Compat/version-1-docs.md) |
| `LibKa0s-Lifecycle-1.0` | The stand-down latch: a hold set, an edge, and two host callbacks. `standDown` fires only when the set goes from empty to non-empty and `standUp` only when it goes back to empty, so a perf run that ends under a `disabled` hold does not bring the addon back. There is deliberately no `StandUp()` member, because a bare stand-up is the bug the latch exists to prevent. Persists nothing. | `Lifecycle.lua` | [3](docs/api/Lifecycle/version-3-docs.md) |
| `LibKa0s-Bus-1.0` | The stand-down record for an addon's tracked bus receivers. `New` builds an instance whose `NewTarget` hands out AceEvent targets that remember what they are registered for, so `StandDown` takes every event and message down and `StandUp` puts back what is wanted now, `arg` included. Beside it sits `Catalog`, the strict declare-once message catalog, which validates the `Ka0s_<Addon>_<Event>` names at load and raises on a mistyped key. Bus owns no hold set; the host calls it from its own Lifecycle callbacks. AceEvent is resolved at call time, never required. | `Bus.lua` | [2](docs/api/Bus/version-2-docs.md) |
| `LibKa0s-Schema-1.0` | The settings schema's runtime without the schema. The host keeps its rows, and this module supplies the dotted-path primitives (`SplitPath`, `Read`, `Write`, `SameValue`), the path index, the single write seam `Set` and its all-or-nothing batch `SetMany`, the bulk bracket that makes a sweep one debug line, the profile reset's changed-row count and `Validate`. It owns no storage, sends no message and formats no value. | `Schema.lua` | [2](docs/api/Schema/version-2-docs.md) |
| `LibKa0s-Pool-1.0` | The free/active widget pool this collection kept rewriting, in a keyed and an unkeyed form. `ReleaseAll` parks backward, so a position gets its own object back on the next pass. The keyed form leaves order undefined on purpose. | `Pool.lua` | [3](docs/api/Pool/version-3-docs.md) |
| `LibKa0s-Item-1.0` | Item identity as five primitives and no policy: read an item link and its bonus ids, name a quality, ask the client to cache an id. What an uncached item *means* stays the host's decision, because two addons here disagree about it in writing. | `Item.lua` | [3](docs/api/Item/version-3-docs.md) |
| `LibKa0s-Glow-1.0` | The stateless LibCustomGlow-1.0 driver. `Start(frame, style, knobs, key, frameLevel)` and `Stop(frame, style, key)` map one of four styles (`button`, `proc`, `pixel`, `autocast`) and its knob values to LibCustomGlow's positional arguments, with its two traps handled (`pixelLength` 0 means automatic; a boolean is false only when false). No defaults, no ranges, no lifecycle: the repaint gate, the proc burst and the triggers stay the host's. LibCustomGlow-1.0 is resolved at call time, and without it nothing is drawn. | `Glow.lua` | [1](docs/api/Glow/version-1-docs.md) |
| `LibKa0s-Media-1.0` | The art and type this collection draws with: 5,836 white icon TGAs from three sets (Open Iconic and Phosphor, MIT; Game-icons.net, CC BY 3.0), seven generated statusbar textures, the Glass skin's generated rounded border and fill (the LSM `border` and `background` catalogs), and six SIL OFL faces: JetBrains Mono plus the skins' Barlow, Cinzel SemiBold and Atkinson Hyperlegible, each under its own locale mask. All of it sits inside the payload, along with the paths that reach it, the set catalog and the LibSharedMedia registration. | `Media.lua`, `MediaIcons.lua`, `media/` | [7.1](docs/api/Media/version-7.1-docs.md) |
| `LibKa0s-Skin-1.0` | The skin engine. A skin is a token table; each addon registers as an **owner** (`Skin:RegisterOwner`, its folder name) and wears its own choice of skin, read once from its profile and moved by `SetChoice`, which resolves the skin, repaints every frame recorded for that owner (and no other), and fires the owner's `OnLooksChanged`. `Skin:For(owner)` is the owner's facade, the painting vocabulary as late-bound trampolines that survive a minor upgrade. `FROM_SKIN`, `Resolve` and `ResetToSkin` let a HUD setting follow the skin. `SkinDefs.lua` holds the token schema and the nine skins: Ka0s Default, whose tokens are today's constants, then Obsidian, Azeroth, Glass, High Contrast, Ember, WoW Default, WoW Midnight and WoW Forever. `SkinPaint.lua`, `SkinPaintExtras.lua` and `SkinPaintControls.lua` are the primitives the facade calls (`S.Shell`, `S.Button`, `S.ListRow`, ...): each paints from the owner's tokens, fades stock art by alpha, keeps its overlays on a holder frame, records what it painted so a skin switch repaints it, and on Ka0s Default makes exactly the paint calls the code it replaces makes today. `SkinEUI.lua` is the EllesmereUI provider: an owner on the `eui` source is painted by EllesmereUI's own skinning facade while its gate holds (`GetEUIStatus`), with the Ka0s extras colored from EllesmereUI's accent, panel color and font, one reload away from a Ka0s skin once EllesmereUI has painted. `SkinAce.lua` paints the AceGUI rows a settings page acquires for that page's owner (`PaintAce`, through a proxy on the Options instance's `O.AceGUI`) and gives each one back to AceGUI's shared pool stock on release. | `Skin.lua`, `SkinDefs.lua`, `SkinPaint.lua`, `SkinPaintExtras.lua`, `SkinPaintControls.lua`, `SkinEUI.lua`, `SkinAce.lua` | [4.6.3.1.1.1.1](docs/api/Skin/version-4.6.3.1.1.1.1-docs.md) |
| `LibKa0s-Widgets-1.0` | The collection's flat-skin dropdown button and the one popup menu every instance of it drops, shared process-wide across addons. Then `SearchBox`, the flat filter-bar search box in the same skin, with a hint while empty and a gold border while it has focus. Then `TestStrip`, the mode strip: the amber band a window lays between its chrome and sample data while test mode is on, or with `kind = "sim"` the cyan band of a simulation, born hidden and placed by the host. Then `ReorderList`, which gives any list drag-to-reorder: the handle, the copy carried under the cursor, the insertion line, the bounded box each row sits in and the clamp, but no row content at all. And `DragHandle`, the labeled strip with a help mark (and optionally a close mark) that a player drags a movable frame by. And `LineChart`, a pooled line chart over a time axis with markers, dashed ranges and a hover crosshair. And `Autocomplete`, a suggestion list hung directly under a host's `EditBox`, in the box's own width and skin, with a debounced provider and keyboard picking. Widgets takes its art and its glyph face as parameters, because a vendored copy cannot know which addon folder it sits in. Every constructor takes an optional skin owner, the caller's folder name: once that addon registered it with `LibKa0s-Skin-1.0` the control wears and follows its skin, the shared menu included, and any other name draws exactly as before. | `Widgets.lua`, `WidgetsReorder.lua`, `WidgetsDragHandle.lua`, `WidgetsLineChart.lua`, `WidgetsAutocomplete.lua`, `WidgetsCopyWindow.lua` | [16.2.6.4.4.1](docs/api/Widgets/version-16.2.6.4.4.1-docs.md) |
| `LibKa0s-DebugLog-1.0` | The on-screen debug console (movable window, color-coded log, copy box, and the one seam that turns logging on and off), plus the diagnostics report a player sends with a bug report, the change gates (log once, log on change) the console re-arms on Clear and on enable, and the at-enable queue that holds a state line written while logging is off until it is turned on. The library writes the markers, the identity header and the cap, and runs each section an addon supplies under its own pcall. The console window lives in its own file, and it wears and follows its skin owner, the host's `addonName`, once that addon registered with `LibKa0s-Skin-1.0`. | `DebugLog.lua`, `DebugLogDiagnostics.lua`, `DebugLogGates.lua`, `DebugLogWindow.lua` | [22.4.1.1](docs/api/DebugLog/version-22.4.1.1-docs.md) |
| `LibKa0s-Slash-1.0` | The slash dispatcher, help renderer, schema CLI and type-aware value parser. In other words, everything between "the user typed `/at something`" and "a setting changed". | `Slash.lua`, `SlashParse.lua` | [20.2](docs/api/Slash/version-20.2-docs.md) |
| `LibKa0s-Launcher-1.0` | The minimap button and the broker plugin, as ONE LibDataBroker-1.1 object of `type = "launcher"` registered twice: with LibDBIcon-1.0 for the button, and with whatever broker display the player runs. It has one `OnClick`, implementing launcher-§2. Left-click opens the settings panel; right-click opens the client's context menu of the toggles the host supplies (Enabled, Locked, Test mode, Show window). There is one library-drawn status tooltip (launcher-§1), and LibDBIcon's own `minimap` table comes from the host. Neither broker library is a dependency. Both are resolved with `LibStub(…, true)` at register time, and every degradation is named, not raised. | `Launcher.lua` | [5](docs/api/Launcher/version-5-docs.md) |
| `LibKa0s-Options-1.0` | The settings panel: canvas shell, page registry, lazy Defaults button, the refresh trio, five widget makers, a grid of one-choice-per-row checkbox cells, an input and list for adding spells, items or currencies by id, link or name, the two-column flow engine, the tab strip every page draws, the nav rail a page that edits one instance out of many may lead with, a drawer (a header bar that opens a bordered box of ordinary rows), the Keybindings tab that edits a host's own key bindings in the client's binding set, the Appearance tab where a player picks the skin an addon wears (and copies it to every other loaded Ka0s addon), and the schema composers that expand one declaration into a canonical font / border / bar / Master-controls block (a media picker can follow the skin through an opt-in companion). A page whose host is a registered skin owner wears that owner's skin: header, tab strip, nav rail, drawers, combat cover, scrollbar and the AceGUI rows. It also carries the one registry fixup that has to be the library's, because AceGUI's widget table is shared by every addon in the client. | `Options.lua`, `OptionsRegistry.lua`, `OptionsWidgets.lua`, `OptionsIds.lua`, `OptionsIdList.lua`, `OptionsTabs.lua`, `OptionsCombat.lua`, `OptionsCompose.lua`, `OptionsScroll.lua`, `OptionsNav.lua`, `OptionsDrawer.lua`, `OptionsKeybinds.lua`, `OptionsAppearance.lua` | [33.3.35.4.6.10.3.12.6.3.2.5.1](docs/api/Options/version-33.3.35.4.6.10.3.12.6.3.2.5.1-docs.md) |
| `LibKa0s-Perf-1.0` | A repeatable A/B performance capture for one host: the probe, the guided run, the record, and the clickable step panel. | `Perf.lua`, `PerfSampler.lua`, `PerfCommands.lua`, `PerfPanel.lua` | [15.1.1.10](docs/api/Perf/version-15.1.1.10-docs.md) |
| `LibKa0s-Sim-1.0` | The in-client simulator's shell. `Sim:NewSeam(compat, opts)` wraps a host's own Compat table in place, once: every non-pure function answers from the simulator's providers while a bound session is active, a guarded member never reaches the client while active, and an idle call costs one field test. The seam carries `SetProvider`, `Live`, `Keys` and `Unwrapped`. `Sim:New(d)` binds one session to a seam: `Start` (the scenarios read at call time; unknown scenario, already running, the host's refusal read live, stood down; the host's own start fields passed through to `prepare`), a two-phase `Stop` (guarded steps while the seam still answers, then cleanup with it off), `Fire`, `After`, `DeliverForCleanup`, listeners and `Status`. `SimTimeline.lua` plays the scenario's steps behind the host's `gate`: `Step`, `Run` (a per-step delay), `Pause`, `Resume` and `Restart`, and `RunVerb(line)` gives every host one typed grammar (`start`, the controls, `status`, `panel`, then the host's own verbs; no `help` verb). `SimPanel.lua` draws the docked step panel (Start, one row per step, Stop, each beside its typed command; a click runs the same verb, a row ahead plays every step up to it), the scenario picker and the run controls, placed beside the host's window with a session-only dragged point; `PanelRows()` answers the composed rows. The library never touches SavedVariables and carries no behavior flags. | `Sim.lua`, `SimTimeline.lua`, `SimPanel.lua` | [2.3.7](docs/api/Sim/version-2.3.7-docs.md) |

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
to suites as `KIT_VERSION`), so a consumer can say which copy it holds; v1.78.0 carries revision
43. Its full surface is in
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
different vendored copy of each. As of **v1.75.0**, which adds two majors (`Glow` 1, and `Sim` 2
with `SimTimeline` 2 and `SimPanel` 2) and moves eight existing files' minors (`Core` 10 to 11,
`Item` 2 to 3, `Widgets` 12 to 13, `DebugLog` 19 to 20, `DebugLogDiagnostics` 2 to 3,
`OptionsIdList` 4 to 5, `OptionsTabs` 8 to 9 and `PerfPanel` 6 to 7): `Core = { Core = 11 }`,
`Env = { Env = 2 }`, `Compat = { Compat = 1 }`, `Lifecycle = { Lifecycle = 3 }`, `Bus = { Bus = 2 }`,
`Schema = { Schema = 2 }`, `Pool = { Pool = 3 }`, `Item = { Item = 3 }`, `Glow = { Glow = 1 }`,
`Media = { Media = 5, MediaIcons = 1 }`,
`Widgets = { Widgets = 13, WidgetsReorder = 1, WidgetsDragHandle = 4, WidgetsLineChart = 3, WidgetsAutocomplete = 2 }`, `DebugLog = { DebugLog = 20, DebugLogDiagnostics = 3, DebugLogGates = 1 }`, `Slash = { Slash = 20, SlashParse = 2 }`,
`Launcher = { Launcher = 5 }`,
`Options = { Options = 29, OptionsRegistry = 2, OptionsWidgets = 34, OptionsIds = 2, OptionsIdList = 5, OptionsTabs = 9, OptionsCombat = 1, OptionsCompose = 7, OptionsScroll = 4, OptionsNav = 2, OptionsDrawer = 1 }`,
`Perf = { Perf = 15, PerfSampler = 1, PerfCommands = 1, PerfPanel = 7 }`,
`Sim = { Sim = 2, SimTimeline = 2, SimPanel = 2 }`. Those numbers move every release, so read them from the top of
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

Re-vendoring is **whole-folder**, never file by file, with one carve-out: `media/icons/` ships only the
icons the consumer declares (see *Installing* above). Every major except Core (Env, Compat, Lifecycle,
Bus, Schema, Pool, Item, Glow, Media, Skin, Widgets, DebugLog, Slash, Launcher, Options, Perf and Sim) resolves
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
  Glow.lua           -- LibKa0s-Glow-1.0, MINOR at the top of the file; needs Core (LibCustomGlow-1.0
                        is the host's, resolved at call time)
  Media.lua          -- LibKa0s-Media-1.0, MINOR at the top of the file; needs Core
  MediaIcons.lua     -- the generated icon catalog, same module, ICONS_MINOR of its own;
                        written by tools/artwork/icon_cleaner.py, never by hand
  media/             -- THE ONLY NON-CODE PAYLOAD: icons/ (224 Open Iconic TGAs, MIT, flat;
                        phosphor/ 1,434 Phosphor Fill, MIT; game-icons/ 4,178 Game-icons.net,
                        CC BY 3.0, with AUTHORS.txt), textures/ (7 generated statusbar bars and
                        the Glass skin's generated border and fill) and fonts/ (JetBrains Mono,
                        Barlow, Cinzel SemiBold, Atkinson Hyperlegible, all SIL OFL); every
                        third-party set carries its license beside it
  Skin.lua           -- LibKa0s-Skin-1.0, MINOR at the top of the file; needs Core
  SkinDefs.lua       -- the token schema and the skins, same module, DEFS_MINOR of its own
  SkinPaint.lua      -- the paint primitives' helpers, Shell, Panel, the faders, PAINT_MINOR
  SkinPaintExtras.lua -- the window extras, text and getters, same module, EXTRAS_MINOR
  SkinPaintControls.lua -- the control primitives, same module, CONTROLS_MINOR of its own
  SkinEUI.lua        -- the EllesmereUI provider, same module, EUI_MINOR of its own
  SkinAce.lua        -- the AceGUI rows, same module, ACE_MINOR of its own
  Widgets.lua        -- LibKa0s-Widgets-1.0, MINOR at the top of the file; needs Core
  WidgetsReorder.lua -- ReorderList and the row box, same module, REORDER_MINOR of its own
  WidgetsDragHandle.lua -- the unlocked drag handle, same module, DRAG_MINOR of its own
  WidgetsLineChart.lua -- the line chart, same module, CHART_MINOR of its own
  WidgetsAutocomplete.lua -- the autocomplete list, same module, AUTOCOMPLETE_MINOR of its own
  WidgetsCopyWindow.lua -- the copy window, same module, COPY_MINOR of its own
  DebugLog.lua       -- LibKa0s-DebugLog-1.0, MINOR at the top of the file; needs Core
  DebugLogDiagnostics.lua -- the diagnostics report, same module, DIAG_MINOR of its own
  DebugLogGates.lua  -- the change gates and the at-enable queue, same module, GATES_MINOR
  DebugLogWindow.lua -- the console window and its skin owner, same module, WINDOW_MINOR of its own
  Slash.lua          -- LibKa0s-Slash-1.0, MINOR at the top of the file; needs Core
  SlashParse.lua     -- the value parser behind `set`, same module, PARSE_MINOR of its own
  Launcher.lua       -- LibKa0s-Launcher-1.0, MINOR at the top of the file; needs Core
  Options.lua        -- LibKa0s-Options-1.0, MINOR at the top of the file; needs Core
  OptionsRegistry.lua -- the page registry, the category and its combat park, REGISTRY_MINOR
  OptionsWidgets.lua -- the makers + the flow engine, same module, WIDGETS_MINOR of its own
  OptionsIds.lua     -- id resolution, suggestions and the id input, same module, IDS_MINOR
  OptionsIdList.lua  -- the editable id list, same module, IDLIST_MINOR of its own
  OptionsTabs.lua    -- the page's chrome: strip, banner, header block, sub-strip, TABS_MINOR
  OptionsCombat.lua  -- the combat lock's event frame, dispatcher and cover, COMBAT_MINOR
  OptionsCompose.lua -- the schema composers, same module, COMPOSE_MINOR of its own
  OptionsScroll.lua  -- the always-shown scrollbar patch and the chrome's skin helpers, SCROLL_MINOR of its own
  OptionsNav.lua     -- the nav rail a page may lead with, same module, NAV_MINOR of its own
  OptionsDrawer.lua  -- the drawer: a header bar over a box of rows, same module, DRAWER_MINOR
  OptionsKeybinds.lua -- the Keybindings tab and its binding model, same module, KEYBINDS_MINOR
  OptionsAppearance.lua -- the Appearance tab: skin source, skin, copy to every addon, APPEARANCE_MINOR
  Perf.lua           -- LibKa0s-Perf-1.0, MINOR at the top of the file; needs Core
  PerfSampler.lua    -- the capture: brackets, combat-gated windows, the FPS sampler, same module, SAMPLER_MINOR of its own
  PerfCommands.lua   -- the perf command surface a host wires in, same module, COMMANDS_MINOR of its own
  PerfPanel.lua      -- the clickable step panel, part of the same module, PANEL_MINOR of its own
  Sim.lua            -- LibKa0s-Sim-1.0, MINOR at the top of the file; needs Core
  SimTimeline.lua    -- the gated step machine and RunVerb, same module, TIMELINE_MINOR of its own
  SimPanel.lua       -- the docked step panel, picker and controls, same module, SIM_PANEL_MINOR of its own;
                        also needs Widgets (the picker's W.Dropdown)
  LICENSE            -- ships INSIDE the payload, so every vendored copy carries the MIT notice
tools/gen-api-members.lua -- writes docs/api/<Major>/members-<version-key>.json from the LIVE
                        surface, loaded through the same mock the suites use. Generated, never
                        hand-edited; tests/test_versioning.lua regenerates and compares on every run
tools/prune-icons.lua -- after the cp -r re-vendor, deletes every icon under <Addon>/libs/LibKa0s/
                        media/icons/ that the addon's `LibKa0s icons:` line does not declare, with
                        the kit's own parser (testkit/vendor_sync.lua). Pure Lua 5.1
tools/artwork/       -- icon_cleaner.py rebuilds media/icons/ and MediaIcons.lua from Open Iconic,
                        Phosphor and Game-icons (pinned commits, its own venv); bar_textures.py
                        and glass_textures.py synthesize media/textures/ from named constants;
                        fonts.py fetches the OFL skin faces at pinned commits and cuts Cinzel's
                        static SemiBold. Each IS the provenance record for its art -- upstream
                        repos, commits, licenses and authors, or every value that decides a
                        pixel. Not shipped, not a build step: the art is committed and the tools
                        regenerate it
testkit/             -- the shared headless harness, vendored into each addon as tests/_kit/
                        (never shipped: it lives under tests/, which every .pkgmeta already excludes)
                        Kit.VERSION at the top of framework.lua names the revision
tests/               -- this repo's own test harness, consuming testkit/ through tests/_kit/
docs/                -- development docs (not shipped)
  api/               -- THE API REFERENCE, and the source of truth for every public contract
                        <Major>/version-<minors>-docs.md, one per shipped version, never edited
                        after that version stops being current; api/README.md indexes them all.
                        Beside each, <Major>/members-<minors>.json -- the same version's public
                        surface as DATA, which is what a degradation stub is checked against.
                        api/CONSUMERS.md is the consumer census: which hosts call each public
                        export, stamped with the release it measured
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

## Credits

The icon art in `LibKa0s/media/icons/` comes from three sets, each license shipped beside its art:

- **[Open Iconic](https://github.com/iconic/open-iconic)** by Waybury, MIT
  (`media/icons/LICENSE-open-iconic.txt`).
- **[Phosphor Icons](https://github.com/phosphor-icons/core)**, the Fill weight, MIT
  (`media/icons/phosphor/LICENSE-phosphor.txt`).
- **[Game-icons.net](https://game-icons.net)**, CC BY 3.0 (`media/icons/game-icons/LICENSE-game-icons.txt`).
  Icons made by Lorc, Delapouite, Skoll, Caro Asercion, Viscious Speed, Sbed, Aussiesim,
  DarkZaitzev, Cathelineau, Quoting, Faithtoken, Lord Berandas, PriorBlue, Willdabeast, Carl Olsen,
  Felbrigg, Lucas, SeregaCthtuf, Guard13007, John Redman, Kier Heyl, Pierre Leducq, Rihlsul, Andy
  Meneely, GeneralAce135, HeavenlyDog, Zajkonur, Zeromancer, Catsu, Irongamer, John Colburn, Pepijn
  Poolman, Sparker, SpencerDub and Starseeker. Every mark's author is listed in
  `media/icons/game-icons/AUTHORS.txt`. Changed from the originals: rasterized to 64×64 TGA,
  background removed, recolored white, some names suffixed or respelled.

The fonts in `LibKa0s/media/fonts/` are all SIL OFL 1.1, each license shipped beside the face:

- **[JetBrains Mono](https://github.com/JetBrains/JetBrainsMono)** by JetBrains
  (`media/fonts/JetBrainsMono-OFL.txt`).
- **[Barlow](https://github.com/jpt/barlow)** by The Barlow Project Authors, Regular and SemiBold
  (`media/fonts/Barlow-OFL.txt`).
- **[Cinzel](https://github.com/NDISCOVER/Cinzel)** by The Cinzel Project Authors, SemiBold
  (`media/fonts/Cinzel-OFL.txt`). Changed from the original: a static instance at weight 600 cut
  from upstream's variable font, renamed "Cinzel SemiBold"; no glyph edited.
- **[Atkinson Hyperlegible](https://www.brailleinstitute.org/freefont/)** by the Braille Institute
  of America, Regular and Bold (`media/fonts/AtkinsonHyperlegible-OFL.txt`).

`tools/artwork/fonts.py` records where each face came from (google/fonts, pinned by commit and
SHA-256).
