# LibKa0s: the five-module extraction — design

**Status:** proposed, awaiting approval.
**Date:** 2026-07-30.
**Scope:** four new LibStub majors in `LibKa0s`, one non-shipping shared test kit, and the
AbsorbTracker migration that consumes all five. Downstream: the Ka0s WoW Addon Standard, the
`wow-addon` Claude Code plugin, and a rewritten adoption prompt for the remaining seven addons.
**Branch:** `feature/libka0s-five-module-extraction`, in both `LibKa0s` and `AbsorbTracker`.

This follows the precedent set by
[`2026-07-29-libka0s-perf-extraction-design.md`](./2026-07-29-libka0s-perf-extraction-design.md) —
extract, prove against one real consumer, only then change the standard.

---

## 1. Why

Seven addons in the collection carry near-verbatim copies of the same four concerns. The debug
console alone is ~3,000 lines duplicated seven ways, in six files whose function lists line up
row-for-row. `standards/standards/debug-logging.md` is 148 lines of prescription that fixes the
frame size, the strata, the two formatters verbatim as code, the exact hex colours, the line cap
and the enable seam — a library the standard already wrote, transcribed by hand seven times.

The same argument holds, with decreasing force, for the options toolkit, the schema-driven slash
core, and the secret-safe print seam. It holds most sharply for the last: `KickCD/core/Util.lua`
has **no secret guard on its printer at all**, and nothing in the collection would ever have told
us. A duplicated formatter is a nuisance; a missing secret guard is a ticker-killing bug in combat.

### The three-part test a candidate has to pass

Perf earned its extraction by being duplicated-or-about-to-be, **normatively specified** (so no
addon has licence to differ), and **host-parameterisable through a descriptor**. All five
candidates here pass. Ranked by duplication × normativity, then adjusted for extraction risk, the
order of work is:

| # | Module | Duplication | Normativity | Risk |
|---|---|---|---|---|
| 1 | shared test kit (`testkit/`) | 9 copies of 3 files, all drifted | testing-§5 | **lowest** — dev-time only, never ships |
| 2 | `LibKa0s-Core-1.0` | 8 copies, 1 silently wrong | events-frames-taint-§8 | low — ~60 lines, stateless |
| 3 | `LibKa0s-DebugLog-1.0` | 7 copies, ~3,000 lines | debug-logging, near-total | medium |
| 4 | `LibKa0s-Slash-1.0` | 4+ copies, 2 shapes | slash-commands-§4/§5 | medium — user-visible strings |
| 5 | `LibKa0s-Options-1.0` | 7 copies, ~2,500 lines | options-ui | **highest** — see §9 R1 |

The order is not the ranking. It is a dependency order, argued in §8.

---

## 2. What is NOT in scope

Named here so the plan cannot quietly grow.

- **The message bus.** 56 lines, two consumers, and its substance is `AceEvent:Embed` plus a naming
  convention. A library buys ~15 lines. The convention belongs in `architecture.md`, not in a major.
- **`Compat`.** The export lists barely intersect — only `GetAddOnMetadata` is universal. Sharing
  the union makes every addon carry every other addon's shims.
- **`Database`.** The shape is common; the migrations are 100% addon-specific. KickCD's is 776 lines
  and almost none of it generalises.
- **`LSMPatch`.** Folds into a future media module, not its own major.
- **Tier-2 `Util` helpers** — `DeepCopy`, `SplitPath`, `Clamp`, `Round`, `FormatBytes`,
  `PlayerKey`, money/date formatters, colour codecs, anchor save/restore. Enumerated in §4.2 and
  deliberately deferred: within a major the contract is additive-only, so every function shipped in
  `-1.0` is frozen across eight vendored copies forever. Shipping `Util.Snap` because PanelMaster
  has one is a permanent liability for a single caller.
- **Migrating the other seven addons.** That is the adoption prompt's job (§12), run per-addon in
  its own repo, after this lands.

---

## 3. The shape of the library after this change

```
LibKa0s/
  LibKa0s/                  <- the vendorable payload; nothing else ships
    LibKa0s.xml             <- one aggregate XML, dependency-ordered (§3.1)
    Core.lua                <- LibKa0s-Core-1.0
    DebugLog.lua            <- LibKa0s-DebugLog-1.0
    Slash.lua               <- LibKa0s-Slash-1.0
    Options.lua             <- LibKa0s-Options-1.0  (primary)
    OptionsWidgets.lua      <- LibKa0s-Options-1.0  (secondary)
    OptionsScroll.lua       <- LibKa0s-Options-1.0  (secondary)
    Perf.lua                <- LibKa0s-Perf-1.0     (existing)
    PerfPanel.lua           <- LibKa0s-Perf-1.0     (existing)
  testkit/                  <- NEW. vendored to <Addon>/tests/_kit/, never ships
    framework.lua
    loader.lua
    mock_base.lua
    README.md
  tests/  docs/  README.md  CHANGELOG.md  LICENSE
```

### 3.1 One aggregate XML, not per-module

The survey flagged this as a live decision the current single-file XML does not answer. **Decision:
keep one `LibKa0s.xml` listing every module in dependency order.**

Reasons, in order of weight:

1. `releasing.md`'s whole-folder `cp` + `diff -r` recipe is the *only* mechanism that has ever
   caught a stale vendored copy — and it caught one during the Perf extraction, while both repos'
   test suites stayed green. Per-module XMLs invite per-module re-vendoring, which is precisely how
   cross-major minor skew gets manufactured (§9 R2).
2. The aspiration in the Perf spec that each addon "vendor and TOC-list only the modules it uses"
   is real but cheap to lose: the whole payload is under 200 KB of Lua, `libs/` is already excluded
   from lint and unaffected by `.pkgmeta`, and an unused major costs one `NewLibrary` call at load.
3. It means **zero TOC churn** in every consumer. `libs\LibKa0s\LibKa0s.xml` is already at
   `AbsorbTracker.toc:27`; the new modules ride the existing line.

Consequence to write down: **`releasing.md` gains a rule that re-vendoring is whole-folder, always,
never per-module.**

Load order inside the XML is dependency order and it matters:

```xml
<Ui xmlns="http://www.blizzard.com/wow/ui/">
	<Script file="Core.lua"/>
	<Script file="DebugLog.lua"/>
	<Script file="Slash.lua"/>
	<Script file="Options.lua"/>
	<Script file="OptionsWidgets.lua"/>
	<Script file="OptionsScroll.lua"/>
	<Script file="Perf.lua"/>
	<Script file="PerfPanel.lua"/>
</Ui>
```

### 3.2 Inter-module dependency rules

This is the first time a LibKa0s major depends on another. Three hard rules, each with a reason:

1. **Core exports only stateless functions on the cross-module path.** No `Core:New` result is ever
   passed between modules. A stateless function that existed at minor 1 still exists at minor 9, so
   the additive-only contract makes "a Core from any vendored copy works with a DebugLog from any
   other" true by construction. Instances have state, and state drifts.
2. **Every dependent module declares a minimum and refuses below it**, rather than erroring at
   first use:
   ```lua
   local core = LibStub and LibStub("LibKa0s-Core-1.0", true)
   local NEEDS_CORE = 1
   if not core or (core.MINOR or 0) < NEEDS_CORE then return end   -- no NewLibrary; module absent
   ```
   The failure then presents as *"the settings panel is missing"* — which the host's degradation
   stub reports honestly — rather than `attempt to call field 'X' (a nil value)` mid-panel-build in
   whichever addon the user happened to open.
3. **No module depends on a module above it in the XML.** Core ← DebugLog, Core ← Slash,
   Core ← Options. Options does **not** consume Slash (§5.4). Perf depends on nothing (§3.3).

### 3.3 Perf consumes Core — and a live bug goes with it

`Perf.lua` documents "Depends on LibStub and nothing else, deliberately — no Ace3, so the lib is
adoptable by addons that are not on the Ace substrate," and `performance.md` repeats it normatively.

**Decision (yours, D2): Perf consumes `LibKa0s-Core-1.0`.** It takes `SafeToString`, `SKIN`,
`ApplySkin` and `MakeCloseButton` from Core rather than carrying private copies.

Three consequences, each of which the plan must handle rather than assume away:

1. **The letter of the invariant changes; its substance does not.** The property that made
   "LibStub and nothing else" worth having is *no Ace3 dependency*, so a non-Ace addon can adopt
   Perf. Core depends on LibStub alone and embeds nothing, so that property survives intact. What
   changes is the count — one vendored sibling file instead of zero. `performance.md` must be
   re-scoped in M10 from "LibStub and nothing else" to "LibStub and `LibKa0s-Core-1.0`, and no
   addon framework" — this is now a **required** standard change, not an optional one.
2. **Perf becomes absent, not degraded, when Core is missing.** Per the §3.2 rule it declares
   `NEEDS_CORE` and refuses to `NewLibrary` below it, so the host's `PerfSetup` stub fires and
   reports honestly. Because re-vendoring is whole-folder-only (§3.1), Core is always present in
   practice — but the branch must exist and be tested.
3. **It resolves the `PerfPanel` comment/code contradiction.** `PerfPanel.lua` says "the close
   button, the divider and the backdrop skin are the host's to draw — this library knows nothing
   about a host's chrome," and then unconditionally sets a backdrop whose values are byte-identical
   to `AbsorbTracker/core/DebugLog.lua`'s. With Core owning `SKIN`, that becomes true as written.
   `PerfPanel` gains a default close button from `Core.MakeCloseButton` when the host supplies no
   `decorate`; the `decorate` field itself stays (the contract is additive-only, so it cannot be
   removed), and AbsorbTracker's existing `decorate` is left alone to keep the diff honest.

The stringifier Perf inherits is the corrected one, because the crosscheck found a real, live bug
in the private copy it is replacing (`Perf.lua:130-137`):

```lua
local function safeToString(v)
  if v == nil then return "nil" end
  local t = type(v)
  if t == "string" then return v end          -- <- a secret IS a string or number
  if t == "number" or t == "boolean" then return tostring(v) end
  local ok, s = pcall(tostring, v)            -- <- unreachable for the case it exists for
  return ok and s or "?"
end
```

`AbsorbTracker/core/Util.lua` states the invariant that this violates: a secret survives `tostring()`
**and** the `..` operator, and raises only at `table.concat` — so detection must probe
`table.concat`, never `..` and never `type()`. A real secret is a number or a string, so Perf's
guard returns it untouched. The verified failure path:

`Perf.render()` → `hostLog(line)` → `AbsorbTracker/core/PerfSetup.lua:96` `NS.DebugLog:Add("Perf", line)`
→ `DebugLog.lua:225` writes it into `D.buffer` → `DebugLog.lua:319` `table.concat(D.buffer, "\n")`
in `D:ShowCopy()` **raises**, and the Copy button is dead for the rest of the session.

This is exactly the class of bug the extraction exists to end, and it is already inside the library.
Perf's private `safeToString` is **deleted**, not fixed in place — it becomes a call to
`Core.SafeToString`, which is the canonical `table.concat`-probe algorithm. One implementation, one
place to be wrong.

---

## 4. `LibKa0s-Core-1.0`

The smallest module and the one every other depends on. Two concerns that have nothing to do with
each other except that both are tiny, stateless, and shared by everything: the **secret-safe seam**
and the **window chrome seam**.

### 4.1 Public surface

```lua
-- stateless, lib-level — callable without an instance
lib.IsConcatSafe(v)               -> boolean
lib.SafeToString(v)               -> string        -- non-concatenable -> lib.SECRET
lib.SECRET                        =  "<secret>"    -- exported so tests and docs cannot drift
lib.SKIN                          =  { bgFile=, edgeFile=, edgeSize=, insets=, bg={}, border={} }
lib.ApplySkin(frame)                               -- no-op when frame has no SetBackdrop
lib.MakeCloseButton(parent, onClick) -> Button|nil -- the thin × glyph

-- instance, for the prefixed chat printer
lib:New(descriptor)               -> printer
  printer.Print(...)                               -- space-joined, prefix-tagged, secret-safe
  printer.Format(fmt, ...)                         -- ConsumableMaster's KCM.Say form
```

Descriptor:

| Field | Type | Required | Meaning |
|---|---|---|---|
| `prefix` | string \| function | yes | The tag, **verbatim**. A function is re-read per call. |
| `sep` | string | no | Separator between prefix and body. Default `" "`; prettychat passes `""`. |
| `sink` | function(line) | no | Default `DEFAULT_CHAT_FRAME:AddMessage`. WhatGroup and ConsumableMaster pass the global `print`. |

Three details that are load-bearing rather than stylistic:

- **`prefix` may be a function, read at call time.** WhatGroup's `Util.lua` documents that
  `NS.PREFIX` is not yet set when `Util` loads. KickCD's load-time upvalue capture is exactly the
  anti-pattern that forced it to carry a duplicate `"[KCD]"` literal in a second file.
- **`sink` is injectable.** WhatGroup and ConsumableMaster route through the global `print`, and
  their headless harnesses capture at that seam. Hard-coding `DEFAULT_CHAT_FRAME` would make both
  unmigratable without rewriting their tests.
- **The prefix is taken as a literal, never synthesised from an abbreviation.** The eight tags are
  not uniform: AbsorbTracker uses uppercase hex, WhatGroup mixed case, prettychat carries its own
  trailing space.

### 4.2 Deliberately deferred

`DeepCopy`, `SplitPath`, `Clamp`, `Round`, `Snap`, `FormatBytes`, `PlayerKey`, `FormatClock`,
`FormatDate`, `RangeFrom`, `FormatMoney`, `PlainMoney`, `Color`/`ParseColor`/`FormatColor`/`Unpack`,
`SaveAnchor`/`ApplyAnchor`, `Throttle`, `ClassIconMarkup`.

Each is duplicated 2–3 ways and could land later as a Core minor bump or its own major once ≥3
consumers actually want it. AbsorbTracker — consumer #1 — needs **none** of them. Designing API
against addons that are not migrating yet is how a frozen contract acquires dead weight.

### 4.3 The AceConsole clobber — a hard constraint on the print seam

`AceAddon:NewAddon(NS, …)` stamps AceConsole's `:Print` onto `NS`, destroying `NS.Print`. Every
addon in the collection survives this only because `Util.print = NS.Print` keeps a second,
un-clobberable reference that `core/<Addon>.lua` uses to reclaim it.

Meanwhile five files capture the printer at load: `settings/Panel.lua`, `settings/Slash.lua`,
`settings/Helpers.lua`, `settings/General.lua` each do `local print = NS.Print`.

**Therefore: `NS.Util.print` and `NS.Print` must be the identical function value, and it must exist
before the settings files load.** The reclaim repoints `NS.Print` at the *same object* those files
already captured — which is why it works today. A Core printer that returned a fresh function on
reclaim would silently break every one of those captures. The AbsorbTracker mock already reproduces
the clobber, so this is regression-tested; the spec's job is to say it out loud so the obvious
"tidy-up" refactor does not reintroduce it.

---

## 5. The four consuming modules

### 5.1 `LibKa0s-DebugLog-1.0`

The console, the copy window, the two formatters, the enable seam, the sink. Everything in
`debug-logging.md` §1–§7 except the *content* of what gets logged (§8, which is per-addon by
definition).

**Descriptor** — every host literal found in `AbsorbTracker/core/DebugLog.lua` becomes a field:

| Field | Required | Replaces |
|---|---|---|
| `name` | yes | seeds `<name>DebugWindow` / `<name>DebugCopyWindow` frame globals |
| `title` | yes | `"Absorb Tracker"`; lib appends `" — Debug"` |
| `font` | yes | `NS.Constants.FONT_MONO` |
| `fontSize` | no | the three hardcoded `10`s |
| `isEnabled` / `setEnabled` | yes | the `NS.State.debug` read/write pair |
| `print` | no | `NS.Print` (defaults to Core's) |
| `safeToString` | no | `NS.SafeToString` (defaults to Core's) |
| `initSummary` | no | `function() -> string`; replaces the inlined `NS.name`/`version`/schema/profile line |
| `onVisibilityChanged` | no | the `NS.Helpers.RefreshAllPanels` hook on `OnShow`/`OnHide` |
| `slash` | no | composes the ConsoleCheckbox tooltip's `/at debug` reference |
| `L` | no | locale override, keyed to `lib.STRINGS` |
| `skin` | no | overrides `Core.SKIN` |

Note `initSummary` is not a new invention — PanelMaster, BankLedger, LootHistory, WhatGroup and
prettychat **already** factor it out to a host function. AbsorbTracker is the outlier that inlines
it, and the extraction brings it into line.

**Additions from sister copies**, promoted to library API because they are pure buffer
introspection that six test suites currently open-code: `IsEnabled()`, `BufferSize()`,
`LastLine()`, `FindLine(substr)`.

**Stays host-side:** PanelMaster's `Diagnose()` (every line reads its own registry), WhatGroup's
`ack`, ConsumableMaster's tag filtering (a candidate for a later minor, not `-1.0`).

**`.buffer` keeps its name.** Seven AbsorbTracker suites index it directly —
`test_database`, `test_debuglog`, `test_perf`, `test_slash`, `test_slashcmds`, `test_util`,
`test_visibility`. Renaming it is gratuitous breakage; the new accessors exist so *future* suites
stop reaching in.

### 5.2 `LibKa0s-Options-1.0`

Three files, one major. `Options.lua` (panel shell, registry, ctx, header, defaults button),
`OptionsWidgets.lua` (the makers and the two-column flow engine), `OptionsScroll.lua` (the
always-shown scrollbar patch).

**Why the basenames are namespaced:** `test_versioning.lua` builds a plain-text needle
`"<FileBasename> minor <N>"` and searches one shared `CHANGELOG.md`. Basenames must therefore be
globally unique across majors. `Widgets` and `Panel` are exactly the names a future
`LibKa0s-Window-1.0` would want.

**Generic — moves:** `AttachTooltip`, `AddSpacer`, `buildHeader`, `EnsureDefaultsButton`,
`CreatePanel`, `EnsureScroll`, `Section`, `ClearScroll`, `InlineButtonPair`, `RefreshAllPanels`,
`RestoreDefaults`, `LSMValues`, `PatchAlwaysShowScrollbar`, `RenderField`, `SessionCheckbox`,
`RenderRows`, all five widget makers, the layout constants, and the whole page-registration shell
(`RegisterOptionsPage` / `CreateOptionsPanel` / `OpenOptionsPanel` with its combat refusal /
`expandMainCategory`).

**Host — stays:** `RenderUnitPanel` in full (the per-unit mirroring page, ~125 lines),
`ResetAllPositions`, `ctx.unit`, the row fields `unit` and `alwaysPerUnit`, `PartitionUnitRows`,
the `_validPages` allowlist, `BuildMainContent`'s *content*, `settings/Profiles.lua`, the default
`onChange` firing `MSG.APPEARANCE`, `NS.PARENT_TITLE`, every `AbsorbTracker*Panel` frame name.

**The read/write seam becomes descriptor callbacks:** `get(path)`, `set(path, value)`,
`rowsForPage(pageKey, filter)`, `allRows()`, `applyDefault(row)`, `scheduleTimer(fn, delay)`,
`parentTitle`, plus an `afterRestoreAll` hook so AbsorbTracker's `ResetAllPositions()` still runs
inside `RestoreAllDefaults`.

`scheduleTimer` is a descriptor field rather than an AceTimer embed on the library, because the
50 ms colour-picker throttle currently uses `NS.addon:ScheduleTimer` and embedding AceTimer would
be the library's second dependency-budget breach. `PerfSetup`'s host-supplied sinks are the
precedent.

**Two cross-addon divergences the library must absorb rather than pick a winner on:**

- **Colour storage.** AbsorbTracker stores `{r=,g=,b=,a=}`; KickCD stores arrays `{[1],[2],[3],[4]}`.
  The codec is a descriptor option, not baked in.
- **A fifth widget type.** KickCD has `makeEditBox` with `OnEnterPressed`; AbsorbTracker has no
  equivalent. Ships in `-1.0` as `dialogControl = "EditBox"`, because adding a *type* later is
  additive but retrofitting one into a frozen dispatch table is not.

**Test seams become supported API.** The host suite reaches live state today through
`Helpers.__lastUnitCtx` (14 call sites) — and the mock's own comment records that a real bug
shipped *because the General page's ctx had no equivalent and was unreachable*. The library
therefore exposes `Options.__panels()` and `Options.__panelFor(pageKey)`, following `Perf`'s
`P.__buckets()` idiom. The ScrollPatch marker `scroll._atAlwaysScrollbar` is renamed
`_ka0sAlwaysScrollbar`, and `tests/test_widgets.lua:513` — the only assertion pinning the patch —
is updated in the same commit.

### 5.3 `LibKa0s-Slash-1.0`

Owns: the dispatcher, the alias table, help rendering, `FormatKV`, `FormatSchemaValue`,
`BuildListLines`, the type-aware parser, and the verbs `help / config / list / get / set /
resetall / version`, plus `debug` and `profile` as optional lib-provided verb packs.

Host keeps: `lock`, `unlock`, `toggle`, `test`, `update`, `resetposition`, `perf`.

**`reset` converges (your decision, D1).** The library owns `reset <path>`, resetting one setting,
and AbsorbTracker adopts it. Its page-shaped `/at reset <general|bar|border|font>` is **removed**.

This is a deliberate, user-visible behaviour change, and the plan treats it as one:

- The capability is not lost, only the CLI route to it. Every schema-driven page still carries its
  **Defaults** button, which calls `RestoreDefaults(pageKey, ctx)` and resets that page across every
  unit — the exact behaviour `/at reset bar` had. That path is untouched.
- `/at resetall` is unchanged.
- The strings that die with it: `Usage: /at reset <general|bar|border|font>`,
  `Unknown page 'x'. Valid: general, bar, border, font`, and the `"<page> page reset to defaults"`
  ack. Replaced by the collection's `reset <path>` equivalents.
- `tests/test_slashcmds.lua`'s reset block is rewritten, not retargeted — the assertions describe
  behaviour that no longer exists. This is the one place in the programme where the parity rule
  ("no assertion weakened to match new output") is deliberately suspended, and it is suspended
  because you asked for the behaviour to change, not because the extraction forced it.
- It needs a `CHANGELOG.md` entry at the next release. **No version bump as part of this work.**

**Three extension points, without which the migration is a user-visible regression:**

1. **A row annotator.** `Slash:SetRowAnnotator(fn)`, invoked identically at all three sites (list
   row, `get` echo, `set` echo), appended *after* the coloured KV so the gold/white pair stays
   intact, and never applied to `reset`/`resetall`. This is what carries AbsorbTracker's
   `MirrorNote` — the grey `(mirrored — the bar shows Player's appearance)` note that is the only
   thing stopping `/at set units.focus.barWidth 400` from printing a confident confirmation while
   the bar does not move.
2. **A list-grouping strategy.** The sisters group by `group`; AbsorbTracker groups by page × unit
   and emits `[bar / player]` headers. A host-supplied group-key function keeps both.
3. **The parser.** AbsorbTracker's `NS.ParseSchemaValue` does type-aware parsing with clamping,
   enum validation and colour tuples. The sisters' inline coercion does none of that. **The library
   adopts AbsorbTracker's, not the reverse** — otherwise `/at set units.player.barWidth 99999`
   stops clamping to 500, and `/at set` on a colour prints a raw table pointer.

**`NS.COMMANDS` stays host-owned** and is passed into the descriptor. It is not moved into the
library and not moved into `settings/Schema.lua` (where the sisters keep it). This is what keeps
Options from depending on Slash — see §5.4.

### 5.4 The About page: the near-circular dependency, resolved

`settings/About.lua` renders the slash command list. If Options renders the About page and Slash
owns `NS.COMMANDS`, Options consumes Slash.

**Decision: the host owns `NS.COMMANDS` and passes it into both descriptors.** No lib→lib edge.
This mirrors what `performance.md` already mandates for the `perf` verb ("MUST NOT be registered by
the library"), and `NS.SlashCommands = NS.COMMANDS` is already the host-owned alias that keeps the
About page and `/at help` in lockstep.

The same shape applies to the debug-console checkbox: `NS.DebugLog:ConsoleCheckbox()` returns a
plain `{label, tooltip, get, set}` table that `Options.SessionCheckbox` consumes. That spec shape
is **defined once and documented in both modules' READMEs**. It is a data contract crossing between
two libs, assembled by the host. If either library ever reaches for the other, it becomes a real
cycle.

**The two row formats converge on `/at help`'s (your decision, D3).** One lib-owned formatter:
uppercase hex (`|cFFFFFF00` command, `|cFFFFFFFF` description), single spaces around the em dash,
**white** description. The About page adopts it and changes visibly — it currently renders lowercase
hex, double spaces and an uncoloured description.

One judgement call inside that decision, flagged because it is mine and not yours: the `/at help`
shape also carries a **two-space leading indent**, which exists because chat lines need to sit under
a header. The About page renders each row as its own AceGUI `Label` in a panel, where a leading
indent would read as a mistake. So the library exposes the *colouring and spacing* as one shared
formatter, and the **indent stays a property of the chat renderer only**. If you want the indent in
the panel too, say so and it is one line.

Ripple worth knowing about now: the sisters' landing pages (BankLedger, LootHistory, PanelMaster)
are currently consistent with the *About* shape, not the help shape. Converging AbsorbTracker means
those three change when they adopt in M12. That is a wider blast radius than converging the other
way, and it is the direct cost of this choice.

### 5.5 The shared test kit

Lives at `LibKa0s/testkit/`, vendored to `<Addon>/tests/_kit/`.

Four placement facts, each with a reason:

- **Not under `libs/`.** That is the ship payload inside `#@no-lib-strip@`; anything there gets
  zipped.
- **Under `tests/`** so the *existing* `- tests` entry in every `.pkgmeta` already excludes it — no
  `.pkgmeta` change in any addon, and no new ignore rule for the next scaffold to forget.
- **Not a LibStub major.** It is never loaded by the client, has no `MAJOR`/`MINOR`, and registers
  nothing. The spec says so explicitly so an auditor does not flag the missing version registry.
- **Not inside the shipping `LibKa0s/` folder**, which `releasing.md` defines as "the payload and
  nothing else". A sibling `testkit/` keeps that invariant intact.

Contents: `framework.lua` (collect-then-run registry, the assertion set, `--list`, exit code),
`loader.lua` (`makeEnv` **with** `__newindex`, `load`, `loadAll`, `loadSource`, `readTOCOrder`),
`mock_base.lua` (the universal API surface, a KickCD-fidelity frame stub, a **strict** LibStub, and
the four Ace fakes), and a `README.md` carrying the mock-fidelity rules.

An addon's `tests/run.lua` shrinks to its load list, its lifecycle kick and its suite list.
`_G.AT_TEST` keeps its exact key set, so **not one existing test file changes**.

Two behaviours the kit standardises, both currently forked:

- **Collect-then-run**, not run-at-registration. WhatGroup and KickCD run bodies at registration
  time with `--list` short-circuiting; everyone else collects first. Collect-then-run makes `--list`
  a pure filter rather than a second code path.
- **`__newindex` in the loader env.** AbsorbTracker and LibKa0s have it; BankLedger, LootHistory and
  PanelMaster silently drop sandboxed writes to WoW globals. AbsorbTracker's is correct — the
  SavedVariables global and `StaticPopupDialogs` must behave like the client.

---

## 6. The AbsorbTracker end state

### 6.1 TOC

The library block is **unchanged** (§3.1). Core changes:

```
core\Compat.lua
core\Constants.lua        <- FONT_MONO, LOGO_PATH; before DebugLogSetup
core\Namespace.lua        <- NS.PREFIX, NS.name, NS.version; before CoreSetup
core\State.lua            <- NS.State.debug; before DebugLogSetup
core\Bus.lua
core\CoreSetup.lua        <- NEW; publishes NS.Print / NS.Util.print / NS.SafeToString / NS.IsConcatSafe
core\DebugLogSetup.lua    <- NEW; replaces core\DebugLog.lua
core\PerfSetup.lua
core\Data.lua  core\Units.lua  core\Database.lua  core\LSMPatch.lua
core\AbsorbTracker.lua

settings\Schema.lua
settings\Slash.lua        <- descriptor + NS.COMMANDS; shrinks from 446 lines
settings\OptionsSetup.lua <- NEW; replaces Panel/Helpers/ScrollPatch/Widgets
settings\About.lua  General.lua  Bar.lua  Border.lua  Font.lua  Profiles.lua
```

Deleted: `core/DebugLog.lua`, `core/Util.lua`, `settings/Panel.lua`, `settings/Helpers.lua`,
`settings/ScrollPatch.lua`, `settings/Widgets.lua`. `settings/Helpers.lua`'s host residue
(`RenderUnitPanel`, `ResetAllPositions`) moves into `settings/OptionsSetup.lua` or a sibling
`settings/UnitPanel.lua` — the plan will decide on file size grounds.

**`core/PerfSetup.lua:10-11` carries a comment saying it "sits immediately after core/Util.lua in
the TOC for exactly that reason."** `Util.lua` is being deleted. Update that comment in the same
commit or the next reader restores a file that no longer exists.

### 6.2 The four load lists

`AbsorbTracker.toc`, `tests/run.lua`, `tests/perf.lua`, and `test_perf.lua`'s deliberately-partial
`loadDegraded()`. Five new modules × four lists is twenty edits to get right, and **only two of the
four are under the green gate** — `tests/perf.lua` is not run by `lua tests/run.lua` and will rot
silently, while the adoption prompt makes its unchanged `probeOverhead` figure the parity gate.

**Mitigation, done first:** derive the list from the TOC. KickCD's `readTOCOrder` is a working
reference and `tests/loader.lua` is 33 lines, so this is cheap. Failing that, a suite asserting
`run.lua`'s list equals the TOC's `.lua` lines in order.

### 6.3 Degradation when the library is absent

The Perf stub degrades to a four-member table because perf is optional diagnostics reached only by
deferred calls. **That calculus does not survive contact with Options**, and the reason is not
importance — it is *when* the missing code is reached.

`settings/Bar.lua` executes at file load and evaluates `NS.Helpers.LSMValues("statusbar")` inside a
schema-row literal. Same in `Border.lua` and `Font.lua`. With `LSMValues` nil that is
`attempt to call field 'LSMValues' (a nil value)`, so **`settings/Bar.lua` never finishes loading**,
so `NS.RegisterSchemaRows` never runs for the bar page, so a third of `NS.Schema` is missing — and
`/at list`, `/at set units.player.barWidth`, `/at reset` and the profile defaults all break with it.
The addon does not degrade; it half-loads.

So:

- **Core, DebugLog, Slash, Perf get member-answering stubs** — the existing `PerfSetup.lua` shape,
  covering every member the addon calls, each returning an honest "not installed" line rather than
  silence.
- **Options gets a load-completing stub.** `settings/OptionsSetup.lua` must publish an `NS.Helpers`
  carrying every member any page file touches *at load time* — verified today that is exactly
  `LSMValues`, `SECTION_HEADING_H` and `RestoreAllDefaults`. Everything else is reached from
  `CreateOptionsPanel()` and page builders, which are user-triggered, so those can be no-ops, and
  `NS.CreateOptionsPanel` prints one honest line and returns — exactly as it already does when
  AceGUI is missing.
- **`error()` is the wrong answer for all five.** `library-stack-§6` forbids requiring another
  addon, and a missing vendored lib is a packaging accident, not a user choice.
- **Losing the panel is survivable, and that is a design argument.** With Options absent the user
  still has `/at set`, `/at get`, `/at list`, `/at reset` and `/at resetall` — all schema-driven and
  panel-independent. That is a genuinely usable fallback, and it is a reason to keep Slash and
  Options as separate majors rather than folding them together.

**The degraded path must be tested by loading the addon with the library missing, not by
hand-stubbing.** `test_perf.lua`'s `loadDegraded()` stops at `settings/Slash.lua` and never loads a
single page file — so today the degraded suite would stay green straight through the R1 failure.
It gets extended to the full file list, with an assertion that `#NS.Schema` matches the normal
environment. This is the single highest-value new test in the programme.

### 6.4 A prerequisite bug in the mock

`AbsorbTracker/tests/wow_mock.lua`'s LibStub `__call` **drops the `silent` argument** and
`GetLibrary` never errors. LibKa0s's mock is strict. So a setup file written
`LibStub("LibKa0s-Options-1.0")` — no silent flag — passes all 430 AbsorbTracker tests and
**hard-errors in-game in exactly the install the degradation stub exists for.**

Every degradation branch in this programme is untestable-by-construction until this is fixed. It is
a ~6-line change and it lands as the **first commit**, before any module is written, so the suite
can tell us what it catches.

---

## 7. Testing

### 7.1 What moves upstream

Per `testing-§8`, the addon **MUST NOT** keep duplicates of what moves.

- **To `LibKa0s`:** the two DebugLog formatters and buffer mechanics; the four (five) widget makers;
  `RenderRows`' two-column flow with `solo` / `skipRender` / `afterGroup` / `pairWith`;
  `EnsureScroll` laziness; the ScrollPatch; `CreatePanel` / `EnsureDefaultsButton` idempotence;
  `RefreshAllPanels` thrower isolation; the layout constants; the slash dispatcher, help renderer,
  `FormatKV` / `FormatSchemaValue` / `BuildListLines` / parser; the `secretMock` from
  `tests/test_util.lua` **verbatim** — its comment is the spec for what a correct detector must do.
- **Stays in AbsorbTracker:** everything touching `NS.Units`, the mirror partition,
  `RenderUnitPanel`'s two-tier refresher, page-scoped Defaults, the real subcategory registrations,
  `NS.RefreshOptionsPanel` delegation, `reset <page>`, `toggle`/`test`/`lock`/`update`, the
  `MirrorNote` annotator wiring, and the Perf descriptor suite.

Library suites need a **fixture schema and fixture db** in the test kit, because the tests being
moved currently hardcode AbsorbTracker paths (`units.player.barWidth`, `showOnlyInCombat`).

### 7.2 The parity artefact

The Perf extraction's gate was "an extraction that changes the measurements is a bug in the
extraction," proved by a numeric diff. Four of these five modules have no numeric output. The
generalised equivalent:

1. **The call sites are byte-identical.** All 16 `NS.Debug(...)` call sites across
   `core/AbsorbTracker.lua`, `core/Database.lua`, `modules/Display.lua`, `settings/Panel.lua` and
   `settings/Schema.lua` must not move. `git diff` proving that is the strongest available evidence
   that behaviour is unchanged.
2. **`lua tests/perf.lua`'s `probeOverhead` figure is unchanged.** If it moved, the bracket idiom
   changed, which it must not have.
3. **The behavioural half of the existing suite passes with only mechanical retargeting** — no
   assertion weakened, no expectation edited to match new output. Any assertion that genuinely has
   to change is a user-visible change and belongs in §11.

### 7.3 The green gate

Unchanged, in both repos, before every commit: `lua tests/run.lua` (all green) and `luacheck .`
(0/0). Plus, for anything touching the vendored copy:
`diff -r LibKa0s/LibKa0s AbsorbTracker/libs/LibKa0s` **empty**, and
`diff -r LibKa0s/testkit AbsorbTracker/tests/_kit` **empty**.

`docs/test-cases.md` is regenerated and the README `[tests]` badge **count** moves in the same
change, in both repos. Never the version.

---

## 8. Milestones

Eleven, in dependency order. M1–M7 are the one-shot build; M8 and M9 are your gates; M10–M12 follow.

| M | What | Repo | Gate |
|---|---|---|---|
| **M1** | Strict LibStub mock; TOC-derived load list; generalise `test_versioning.lua` to N majors | AT + LK | green |
| **M2** | `testkit/` extracted; AT and LK both consume it; `_G.AT_TEST` unchanged | LK → AT | green, `diff -r` empty |
| **M3** | `LibKa0s-Core-1.0` + Perf's secret-guard fix; AT `core/CoreSetup.lua`; `core/Util.lua` deleted | LK → AT | green |
| **M4** | `LibKa0s-DebugLog-1.0`; AT `core/DebugLogSetup.lua`; `core/DebugLog.lua` deleted | LK → AT | green |
| **M5** | `LibKa0s-Slash-1.0` + annotator/grouping/parser hooks; AT `settings/Slash.lua` rewritten | LK → AT | green |
| **M6** | `LibKa0s-Options-1.0` (3 files); AT `settings/OptionsSetup.lua`; four files deleted | LK → AT | green |
| **M7** | Docs in both repos; `test-cases.md` regenerated; badges; `releasing.md`; extended `loadDegraded` | AT + LK | green |
| **M8** | **`/wow-addon:review` on AbsorbTracker and on LibKa0s** | both | **your call to proceed** |
| **M9** | **In-game smoke tests** (§10) | — | **your sign-off** |
| **M10** | `WowAddonStandards` — five sections rewritten, anti-patterns, version bump | WAS | — |
| **M11** | `wow-addon` plugin — audit/review agents, new-addon command | plugin | — |
| **M12** | `LibKa0s/docs/adoption-prompt.md` rewritten for all five modules + the perf run | LK | — |

**Why this order, not the ranking order.**

*Harness first* because the library cannot host an Options test suite until the AceGUI widget
factory moves into a shared base — LibKa0s's mock today has no AceGUI, no AceDB, no AceAddon, no
timers and no `Settings`. Sequencing the harness after Options would mean writing the Options suite
twice.

*Core second* because DebugLog, Slash and Options all consume it, and because the secret-guard bug
it fixes is live in the shipping library right now.

*Options last* because it is the only extraction that can break the addon's **load** rather than
its panel (§6.3, §9 R1), and because it is the one whose host residue — the per-unit mirroring page
— is genuinely entangled.

**M1 and M2 exist to make later milestones honest**, exactly as the Perf plan's Task 1 existed
purely to give every later task a harness to be green against.

Each milestone is committed separately (no auto-commit — each one asks). M8 and M9 are hard stops:
nothing in `WowAddonStandards`, the plugin, or the adoption prompt is touched until the review is
clean and the in-game smoke tests pass. Writing a normative section from a design rather than from a
*working, verified* extraction is how a standard acquires rules that do not survive their second
implementation.

---

## 9. Risks

**R1 — The Options extraction can break AbsorbTracker's load, and no current test would catch it.**
`settings/Bar.lua` calls `NS.Helpers.LSMValues` at file load; a nil there aborts the file and
silently removes a third of the schema. `loadDegraded()` does not load page files, so the degraded
suite stays green through the entire failure.
*Mitigation:* the load-completing Options stub (§6.3); extend `loadDegraded()` to the full file list
and assert `#NS.Schema` against the normal environment; both in the same commit as the extraction.

**R2 — Five majors, eight vendored copies, no cross-major skew guard.**
`PerfPanel`'s paired `__panelMinor`/`__panelProbeMinor` works only *within* a major and does not
generalise — a panel can re-attach, but an Options instance already returned to a host cannot.
Options-minor-2-against-Core-minor-1 is routine across eight independently re-vendored addons, and
the symptom is a nil-value error at panel build in whichever addon the user opens.
*Mitigation:* Core exports only stateless functions on the cross-module path (§3.2); each dependent
declares `NEEDS_CORE` and refuses to `NewLibrary` below it; `releasing.md` mandates whole-folder
re-vendoring; a cross-major skew suite using `loadSource`, which already exists for exactly this.

**R3 — The secret-safe seam is already wrong inside the library** (§3.3), and four different
algorithms exist across the collection while KickCD's printer has none.
*Mitigation:* Core ships AbsorbTracker's `table.concat`-probe algorithm as canonical, with its
`secretMock` carried into the LibKa0s suite verbatim; Perf's private copy is corrected in M3.

**R4 — Four hand-maintained load lists, one of them ungated** (§6.2).
*Mitigation:* TOC-derived load list in M1, before any module lands, so all subsequent additions are
one edit.

**R5 — The mock cannot detect a missing `silent` flag** (§6.4), making every degradation branch
untested-by-construction.
*Mitigation:* first commit of M1.

**R6 — User-visible string changes.** Enumerated in §11 rather than mitigated, because they are
your decision, not a defect.

---

## 10. In-game smoke tests (M9)

Run on a live character after the build is green. Almost everything here is currently working
behaviour and the point is that none of it changed. **The three exceptions, which are supposed to
look different, are marked ⚠ — check those against the new expected output, not against memory.**

1. `/at` → help index renders; every verb listed; gold command, white description, two-space indent.
   ⚠ `/at reset` is now `reset <path>`, and the page form is gone.
2. `/at config` → panel opens, tree expands, all five sub-pages present. In combat → the single
   grey refusal line, no panel. ⚠ On the About page, the slash-command list now renders in the
   `/at help` colours — brighter yellow command, **white** description, single-spaced em dash.
3. `/at debug` → console opens, monospace, aligned columns, scrollbar and line counter present.
   `/at debug on` → green `ON` ack in chat, `[Debug] logging enabled`, then the `[Init]` line
   naming version, schema and profile. `/at debug off` → red `OFF`, disabled line still lands.
4. Console header toggle, Clear, Copy (`Ctrl+C` selects), Esc closes. Reopen — buffer intact.
5. Settings panel: change a slider, a dropdown, a colour (drag it — the bar should follow live),
   a checkbox. Paired controls grey/ungrey on the same frame.
6. Bar / Border / Font: switch the Unit dropdown; tick "Use same styling as Player" and confirm the
   appearance rows vanish; untick and confirm they return; "Copy styling from Player".
7. `/at list` → `[bar / player]`-style headers present. `/at get units.focus.barWidth` on a mirrored
   focus → the grey `(mirrored — …)` note appears. On player → it does not.
8. `/at set units.player.barWidth 99999` → clamps to 500. `/at set locked` with no value → the
   two-line invalid-value message.
   ⚠ `/at reset units.player.barWidth` resets that one setting. `/at reset bar` now reports an
   unknown path rather than resetting the page. Then open Settings → Bar and confirm its
   **Defaults** button still resets the whole page across all three units — that is where the old
   behaviour lives now, and it must be intact.
9. `/at profile list|new|copy|delete|reset` round-trip; the panel re-syncs after a profile switch.
10. `/at perf` full A/B run: start → measure A → measure B → finish → report → dump. The panel
    renders, the console shows the run, and `AbsorbTrackerPerfDB` gains a record.
11. **The parity capture** — re-run the guided perf capture against the same target as the
    pre-extraction runs in `docs/perf-runs/` and diff bucket call counts and presence. Bucket
    figures moving is a bug in the extraction.
12. `/reload` → debug state is off again (session-only), bar position and profile survive.

I will give you this as a numbered checklist with expected output at M9.

---

## 11. Decisions — asked and settled

Five things that were either a user-visible change or a standard-level divergence. Under this
repo's standards rule they were flagged rather than smuggled. All five are now decided; three went
against my recommendation, which is recorded here so the reasoning is auditable later.

**D1 — `/at reset <page>` → `reset <path>`. DECIDED: converge.** *(I recommended keeping the page
verb as a host verb.)*
AbsorbTracker adopts the collection's per-path `reset`; its page-shaped verb is removed. Detail and
the strings that die with it are in §5.3. The page-reset *capability* survives via each page's
Defaults button. This is the one place the parity rule is deliberately suspended — because the
behaviour was asked to change, not because the extraction forced it. Needs a `CHANGELOG.md` entry
at the next release; no version bump as part of this work.

**D2 — Perf ↔ Core. DECIDED: Perf consumes Core.** *(I recommended keeping the "LibStub and nothing
else" invariant and duplicating 12 lines.)*
Detail in §3.3. The substantive property — no Ace3, so non-Ace addons can adopt Perf — survives,
because Core embeds nothing. What changes is the letter, and **`performance.md`'s normative wording
must be re-scoped in M10**; that is now a required standard change rather than an optional one.
Upside: one stringifier instead of two, and `PerfPanel`'s comment finally matches its code.

**D3 — Help row vs About row. DECIDED: converge on the `/at help` shape.** *(I recommended keeping
both.)*
Uppercase hex, single spaces, white description; the About page changes visibly. The two-space
indent stays chat-only — see §5.4 for that judgement call and how to overrule it. Ripple: the three
sister landing pages currently match the *About* shape and will change when they adopt in M12.

**D4 — `docs/test-cases.md` format. DECIDED: long four-line banner + in-renderer CRLF.** *(As
recommended.)*
Changes AbsorbTracker's committed banner text and produces a doc-churn commit in each repo as it
adopts. Totals must not move — only the markup around them.

**D5 — Scope check on the standard (M10).**
Making the console/toolkit/slash/print seam library-owned means `debug-logging.md`, `options-ui.md`,
`slash-commands.md`, `testing.md` and `library-stack.md` stop describing files that will no longer
exist. That is a **change to the standard**, not a deviation, and it is upstream work in
`WowAddonStandards` that must land *before* the other seven addons adopt — otherwise every addon
that migrates becomes non-compliant with the letter of a standard describing a file it no longer
has. `performance.md` is the precedent for how to word it.
*My recommendation:* proceed as M10, after the M8 review and M9 smoke tests, exactly as you scoped
it.

---

## 12. After the gates

**M10 — `WowAddonStandards`.** Rewrite the five sections to "consume the library + supply these
descriptor fields", demoting the implementation detail to rationale. Add anti-patterns for
hand-rolling a console, editing `libs/`, and forking the toolkit. Extend `library-stack.md` to
describe a multi-module LibKa0s and the inter-module rules of §3.2. Bump the index version and date.

**M11 — the `wow-addon` plugin.** The standards-audit and review agents encode the standard's
expectations and will otherwise flag a compliant lib-consuming addon; the new-addon command must
scaffold consuming LibKa0s from birth. The survey has the file-by-file list.

**M12 — `LibKa0s/docs/adoption-prompt.md`.** Rewritten to cover all five modules plus the perf run,
for the remaining seven addons. The existing prompt's shape is reusable verbatim — read-order,
"work out what this addon actually does", numbered steps, "mistakes that have already cost a
capture", verify-and-report. What is **not** reusable is its central assumption: Perf needed only a
descriptor, while these four require deleting files the addon currently owns.

The per-addon risk notes the survey produced go in it: KickCD is the riskiest for Options (split
Panel files, array colours, a fifth widget type) and for Core (no secret guard at all —
migrating it is a behaviour change, not a refactor); ConsumableMaster is the riskiest for the
harness (its runner already delegates to its own `harness.lua` and discovers suites by shelling out
to `ls`); prettychat is the riskiest for Core (single-argument printer, no varargs, its own
separator).

Adoption order, following the Perf precedent: **KickCD first** — the most structurally complex, so
the most likely to expose a descriptor assumption that only held for AbsorbTracker.
