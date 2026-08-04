# Collection-wide CCN elimination — design

**Date:** 2026-08-04
**Scope:** LibKa0s + AbsorbTracker, BankLedger, ConsumableMaster, KickCD, LootHistory,
PanelMaster, WhatGroup, prettychat
**Branch:** `feat/fix-ccn` in every repo
**Goal:** zero functions with cyclomatic complexity > 15 in
`lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .`, with behavior unchanged.

## Why now

`lizard` warnings have been recorded and accepted, run after run, in every addon's
`docs/automated-tests/<stamp>/complexity.txt`. An accepted warning that is never acted on stops
being a signal: the watch list grows, the disposition column fills with "accepted", and the next
genuinely alarming function is indistinguishable from the eighty-six already sitting there. The
decision here is to clear the board once, so that a future CCN > 15 means something again.

The measurement is not a gate and does not become one (`automated-tests-§3` is explicit that
`perf` and `complexity` record rather than fail). This is a one-time cleanup of the recorded
backlog, not a new commit gate.

## Starting state

Measured 2026-08-04 on `master`/`main`, before any change. All repos lint clean and all headless
suites pass.

| Repo | CCN > 15 | luacheck | headless |
|---|---|---|---|
| AbsorbTracker | 2 | 0/0 | 469 pass |
| BankLedger | 14 | 0/0 | 689 pass |
| ConsumableMaster | 20 | 0/0 | 605 pass |
| KickCD | 20 | 0/0 | 648 pass |
| LootHistory | 9 | 0/0 | 563 pass |
| PanelMaster | 9 | 0/0 | 696 pass |
| WhatGroup | 3 | 0/0 | 415 pass |
| prettychat | 2 | 0/0 | 255 pass |
| LibKa0s | 7 | 0/0 | 420 pass |
| **Total** | **86** | | **4760 pass** |

Worst offenders: ConsumableMaster `DUMP_TARGETS.pick.run` (62), LootHistory `NS:RunMigrations`
(56) and `Database:QueryList` (58), PanelMaster `Artwork.BuildArtSpec` (51), PanelMaster
`R.Sanitize` (40), KickCD `ReskinStructure` (36), ConsumableMaster `commitMacro` (35),
BankLedger and PanelMaster `wow_mock.lua` stub-frame `__index` (33 and 21).

LibKa0s' own seven are in scope. Addon `lizard` runs exclude `./libs/*`, so the vendored copies
never showed up in an addon report — but the library is measured in its own repo and is the
upstream everything else builds on.

## What is causing the complexity

Every one of the 86 functions was read in full. The shapes, by frequency:

| Pattern | Count | What it is |
|---|---|---|
| `guard-stack` | 21 | a wall of `if not x then return end` plus `a and b` conditions |
| `field-defaulting` | 14 | long runs of `t.k = rec.k or D.k`, one `or` per field, each a branch |
| `options-builder` | 11 | one function assembling N independent UI sub-parts inline |
| `elseif-dispatch` | 10 | a hand-written `if v == "a" ... elseif v == "b"` chain |
| `schema-migration-chain` | 4 | sequential `if schemaVersion < N then ... end` ladders |
| `mock-index-dispatch` | 2 | test stub-frame `__index` written as an if/elseif chain |
| remainder | 24 | one-off builders, render dispatchers, report assemblers |

Lua-specific note that drives much of this: `lizard` counts `and`/`or` short-circuits as
decisions. A block of twelve `t.k = rec.k or D.k` lines is CCN 13 on its own with no visible
branching at all. That is why `field-defaulting` and `guard-stack` together account for 40% of
the warnings, and why the fix for them is a defaults/rules table plus a loop rather than any
restructuring of logic.

## The refactor vocabulary

Four shapes, applied in this order of preference. Nothing else is used.

1. **Table-driven dispatch** replaces an `if/elseif` chain. The table is module-level and built
   once at file load, never per call.
2. **A named file-local helper** extracted for a self-contained block, where the block has a name
   a reader would recognize.
3. **A data table plus a loop** replaces repeated field defaulting or validation. Absence is
   tested with `== nil`, not `or`, wherever a stored `false` or `0` must survive.
4. **Splitting a builder** that assembles N independent sub-parts into N small builders.

Explicitly forbidden: moving a body wholesale into one helper to move the number below the
threshold. Each resulting function must be a unit a reader can name. A proposal whose only
justification is the metric is rejected in review.

**Hot paths** — `OnUpdate`, per-frame render, event handlers — must not gain a table allocation
per call. Where a hot function is refactored, the tables it uses are module-level constants.
Affected: KickCD `Icon:Apply`, `Icon:UpdateGlow`, `Cooldowns:PollSpell`; ConsumableMaster
`BB.ApplyStyle`, `bindEntry`, `P.Recompute`; BankLedger/LootHistory `QueryList`.

## Milestone 1 — LibKa0s upstream

Five promotions, chosen from roughly twenty candidates by the test: present in 2+ repos with the
same semantics, no per-addon escape hatches needed, and a stable abstraction rather than a
coincidence of today's code.

**1. `LibKa0s-Options` gains `O.TextRow` and `O.BuildLandingPage`, plus four `LAYOUT` constants**
(`LANDING_LOGO = 300`, `LANDING_GAP_LOGO = 8`, `LANDING_GAP_DESC = 12`, `LANDING_GAP_HEAD = 6`).
Three repos define a function literally named `Helpers.BuildMainContent` rendering the same
landing page with the same constants; only the logo path and the source of the one-liner differ.
Every primitive it needs (`EnsureScroll`, `ClearScroll`, `AddSpacer`, `Section`) is already in
this major. `O.TextRow` earns its place independently — the
`if w.label and w.label.SetJustifyH` guard pair appears in six repos, 28 times.

**2. `LibKa0s-Slash` gains `lib.SplitVerb`, `lib.FindCommand`, `lib.CommandRows`, `lib.ParseBool`.**
`findCommand` and `lowerFirst` are byte-identical file-locals in KickCD and ConsumableMaster.
Both repos also hand-roll a sub-help row format that renders identically to the library's own
`FormatRow` — so both already use the library's formatter for top-level help and a private copy
for the second level. `CommandRows` generalizes the existing instance-local `rows(indent)`, so
`HelpRows`/`LandingRows` become one-liners over it and every level renders through one formatter
by construction. `ParseBool`'s eight-word set exists in three places, one of them already inside
`Slash.lua` but unreachable.

`SplitVerb` lowercases the verb and preserves the remainder's case. That asymmetry is the
contract: verbs are identifiers, arguments are user data (AceDB profile names and schema paths
are case-sensitive).

**3. `LibKa0s-Core` gains `lib.RGBA(c, dr, dg, db, da)`** — reads a stored color in either the
keyed `{r=,g=,b=,a=}` or positional `{r,g,b,a}` shape, returns four numbers. Promoted mainly
because the library itself holds two disagreeing copies: `Slash.FormatValue` reads both shapes,
`OptionsWidgets.decodeColor` reads only the keyed one, so the library's CLI renders colors its
own widget cannot decode.

Two adoption constraints, both mandatory. *(a)* `Slash.lua` and `Options.lua` declare
`NEEDS_CORE = 1`, and `docs/releasing.md` treats raising that floor as a breaking change to the
vendoring — this is the documented reason `enumList` is duplicated between two majors rather
than hoisted. So `lib.RGBA` ships for hosts now; the library's own two call sites adopt it only
alongside a floor raise made for other reasons. *(b)* When `Slash.FormatValue` does adopt it,
that is a real behavior change for malformed mixed-shape input — today it mixes shapes per
channel, so `{r=1, [2]=0.5}` yields `g = 0.5` where `lib.RGBA`'s shape-wins rule yields the
default. Land it with a case pinning that input.

**4. `LibKa0s-Perf` gains `P.Open()` / `P.Close(t0, key)`.** Three repos instrument today.
KickCD's `Cooldowns:PollSpell` has four exits, each needing its own
`if __t0 then P.Note(key, debugprofilestop() - __t0) end` — eight of its nineteen CCN is
instrumentation, not logic, and that function's own comment records that instrumentation was
originally omitted *because* the exits made it awkward, an omission that then cost 73.9 ms of
unattributed time in the first live capture. `P.Close` treats a nil `t0` as a silent no-op,
which collapses every exit to one unconditional statement.

Deliberately **not** a closure-returning `P.Bracket(key)`: a closure per bracket allocates on a
path whose entire contract is costing nothing when the probe is off.

**5. `testkit/mock_base.lua` gains `M.__frameMethods` and `M.__makeStubFrame(extra)`.** Four
repos independently rewrote the base stub frame to record real geometry, with near-verbatim
comments; two of those rewrites are CCN > 15 offenders (BankLedger 33, PanelMaster 21). KickCD
has already converted its copy to the exact table-of-plain-methods shape proposed, so the
destination is proven rather than speculative. Plain methods rather than the current
closure-factory (`function() return f end` allocates on every property miss).

This goes to `testkit/`, never to a shipped module — the kit is not a LibStub major and a frame
stub compiled into a shipped addon would be a defect.

**Migration risk, and why this one lands last:** giving the base a recording `GetWidth` changes
what AbsorbTracker, ConsumableMaster and prettychat see — they currently get a hard `0` and
would now get the real value, so any `GetWidth() == 0` assertion flips. That is a loud red rather
than a silent drift, and `tests/test_kitsync.lua` enforces byte-identity so the re-vendor cannot
be done halfway. It lands after every addon-side refactor, on its own commit, with all eight
suites run before re-vendoring.

The base's initial `__shown` value stays **unchanged** (frames start hidden). BankLedger and
PanelMaster start them shown and document that as deliberate; flipping the base would silently
invert assertions in the repos that did not override.

### What was deliberately not promoted

The most-nominated candidate, a **shared schema-migration runner**, is rejected. It appears in 8
repos in five incompatible variants that disagree on who stamps the version (runner vs. step),
when (per step vs. once at the end), whether a failed step still stamps, and what a missing step
does. KickCD's whole design premise is that the version stamp *cannot be trusted* under AceDB —
its `FoldLegacyUnits` runs unconditionally and shape-driven because AceDB's defaults merge
backfills `schemaVersion` to current the moment `db.global` is first accessed, masking a legacy
account as current. A shared runner needs five escape hatches to own an eight-line loop of CCN 4,
while risking silent corruption of users' SavedVariables. The CCN win (LootHistory 56 → 8) comes
from moving the step bodies into a local ordered table, which each addon does for itself.

Also rejected, with reasons recorded in the analysis bundle: `core.CallIf` (400+ sites across 9
repos — trades readable method calls for stringly-typed lookups and erases the three distinct
reasons those guards exist); the multi-select filter dropdown and its `setToFilter`/`asSet` tail
(2 repos, actively diverging, zero headless coverage, wrong layer — raw `CreateFrame` widgetry
in an AceGUI library); `Query.Compile` (2 repos, disjoint field sets, hottest read path in both);
`GroupedTable`/`groupOf` (2 repos, barely-overlapping modes; the one genuinely shared thing is a
one-line key format); `core.ApplyDefaults` (three callers want incompatible `or` vs `== nil`
rules, and normalizing that away would corrupt SavedVariables); the sub-verb *dispatcher* as
opposed to its primitives (per-host control flow — KickCD's bare `/kcd debug` toggles a window
first, ConsumableMaster resolves a category object between levels); the class-color lookup
(belongs in each addon's `core/Compat.lua`, the designated home for game-API knowledge); and the
deterministic RNG behind the demo datasets (two addons assert their generated fixtures
byte-identical run to run, and that identity is a property of the call sequence, not the
generator — one library edit could silently regenerate two addons' fixtures).

### LibKa0s' own seven

Fixed in the same milestone: `P.Progress` (32), `O.RenderRows` (25), `lib.FormatValue` (25),
`lib.ApplySkin` (21), `setEnabled` (18), `lib.PatchAlwaysShowScrollbar` (17), `P.FormatReport`
(16).

`lib.ApplySkin` keeps its `type(x) == "function"` guard style rather than truthiness. The
comment there records that a consumer's mock answering every key truthily is what broke fourteen
cases on a re-vendor; that distinction survives the refactor.

## Milestone 2 — the eight addons

Independent per repo, run in parallel. Per-repo counts: ConsumableMaster 20, KickCD 20,
BankLedger 14, LootHistory 9, PanelMaster 9, WhatGroup 3, AbsorbTracker 2, prettychat 2.

Two functions are rated **high risk** and get a characterization test written before they are
touched, not after: ConsumableMaster `commitMacro` (35 — writes real macros, five parameters)
and BankLedger `LT:BuildTestData` (18 — a builder with a nested closure whose output is asserted
byte-identical).

**Sixteen of the 86 have no headless coverage at all.** Each gets a characterization test
pinning current behavior *before* the refactor, so the refactor has something to be verified
against:

BankLedger `menu:Populate`, `groupOf`, `P:Diagnose`, stub-frame `__index`; ConsumableMaster
`MD.SetTooltip`, `BB.ApplyStyle`, the `KCM_RESET_CATEGORY` `OnAccept`; KickCD
`Compat.DebugInterrupt`, `NS:OpenSettings`, `Castbar:DebugDump`, `getCooldownManagerSpellSet`,
the add-spell `OnAccept`, `buildRow`; LootHistory `menu:Populate`, `dd:UpdateMultiLabel`;
PanelMaster stub-frame `__index`.

Where a function is genuinely unreachable headlessly (a `StaticPopup` handler needing a live
frame), the characterization test covers the extracted pure helpers instead, and the commit says
so.

## Milestone 3 — verification and delivery

Per repo, all four must hold before the work is called done:

1. `luacheck . --quiet` — 0 warnings, 0 errors.
2. `lua5.1 tests/run.lua` — all pass, and the test count is **greater than or equal to** the
   baseline in the table above. A drop means a test was deleted.
3. `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` — no function with CCN > 15.
4. An adversarial behavior-preservation review of the full diff, per repo, by an agent that did
   not write it. Chat output strings, event registration, SavedVariables shape, and hot-path
   allocation are the four things it is pointed at specifically.

Then a fresh `tests/_kit/run-automated-tests.sh` bundle per addon under
`docs/automated-tests/<YYYYMMDD-HHMMSS>/`, with its row prepended to `RESULTS.md` and the watch
list reading "None." for functions.

**Delivery: branch only.** `feat/fix-ccn` is left unmerged and untagged in all nine repos. No
version bump, no CHANGELOG entry, no tag, no release. Review and merge are the maintainer's.

## Explicit non-goals

- No new commit gate on complexity. The standard's `MUST NOT gate commits` is retained.
- No change to the Ka0s standard's text in this work. If the collection wants a ruling on
  migration-stamp ownership or the collapsed-group key format — both surfaced by the analysis —
  that is a separate `harvest-standards` run.
- No behavior changes, including no bug fixes noticed in passing. Anything found is recorded and
  reported, not fixed here; a behavior change hidden inside an 86-function refactor is
  unreviewable.
- No version bumps or releases in any repo.
