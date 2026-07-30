# LibKa0s — shared library substrate, with Perf as its first module

Date: 2026-07-29
Repos touched: `LibKa0s` (new), `AbsorbTracker`, `WowAddonStandards`, `wow-addon`
Predecessor: AbsorbTracker `docs/superpowers/specs/2026-07-29-perf-instrumentation-design.md`
(issue [#17](https://github.com/tusharsaxena/AbsorbTracker/issues/17))

## Problem

AbsorbTracker's performance instrumentation — `core/Perf.lua` (706 lines), `core/PerfPanel.lua`
(242), `tests/test_perf.lua` (1,330) — works, and the guided `/at perf` run has proven itself. It
is currently trapped in one addon.

The value in it is not the bucket counter. It is the **protocol**: a repeatable A/B on the same
fight with load order held fixed, which is the only way to answer "is this cost even ours?" after
the July 14 investigation established that WoW's own Addon Profiler cannot. That protocol is
subtle, was expensive to get right, and nobody will re-derive it correctly per addon.

Six Ka0s addons want it: AbsorbTracker, KickCD, LootHistory, BankLedger, ConsumableMaster,
WhatGroup. (`WhoGotLoots` and `BuffTextNotifications` are not Ace3 and not yet on the standard —
flat layout, no `libs/`, multi-value `## Interface`. They are out of scope until migrated.)

## Goal

Extract the reusable part into `LibKa0s`, a Ka0s-owned shared library vendored like Ace3; adopt it
in all six addons; and promote the pattern into the Ka0s WoW Addon Standard so future addons are
born with it. Design for eventual public release on CurseForge.

**Not in scope:** migrating `WhoGotLoots` / `BuffTextNotifications` to the standard; moving any
module other than Perf into `LibKa0s`; changing what AbsorbTracker measures.

## Decisions taken

| Question | Decision |
|---|---|
| Ships to users, or dev-only? | **Ships always.** Any user can run `/xx perf` and send the JSON. |
| How much is shared? | **Primitives + the full guided run.** Suspend/Resume stay host-supplied. |
| Distribution mechanism | **Vendored LibStub micro-lib.** Not copied source, not a dependency addon. |
| Lib granularity | **`LibKa0s` umbrella, one LibStub major per module** — mirrors Ace3. |
| Persistence | **Per-addon `<Addon>PerfDB`.** No shared global, no cross-addon merge tool. |
| Standard adoption | **MUST** for wiring, **SHOULD** for coverage. |

A **standalone dependency addon** was rejected: `library-stack-§6` forbids requiring another addon,
so it would be a standing deviation, and it buys nothing a vendored lib does not.

**Copied source** was rejected for three reasons. LibStub deduplicates — six installed addons load
one copy of the code, not six, which matters now that it ships. The code is subtle (bucket nesting,
ring cap, JSON key ordering, the free-when-off idiom) and six divergent copies means six places a
fix lands or does not. And `library-stack-§3` already blesses vendoring an addon-private micro-lib,
so the lib is a conforming change rather than a deviation.

## Architecture

### The lib

Repo `LibKa0s`, vendored at `libs/LibKa0s/` in each consumer. Folder-per-lib with an aggregate
`LibKa0s.xml`, exactly as Ace3 does. Each module is its own LibStub major:

```lua
NS.Perf = LibStub("LibKa0s-Perf-1.0"):New(descriptor)
```

One LibStub major per module rather than one for the whole lib, because LibStub dedup picks the
highest minor of a *major*. Under a single major, an addon vendoring a copy that predates a module
would be served a lib missing that module, and every host would need presence guards. Per-module
majors keep version skew narrow, let each addon vendor and TOC-list only the modules it uses
(required by `library-stack-§3`), and make adding future modules purely additive — each adopted on
its own schedule rather than in a lockstep migration.

**`LibKa0s-Perf-1.0` depends on LibStub and nothing else.** The sampler is a raw `OnUpdate` frame,
the panel is raw `CreateFrame`, combat state is `InCombatLockdown`. No AceGUI, AceEvent, or
AceTimer. This is deliberate and must be protected: it is what makes the lib adoptable by
developers who are not on Ace3, and it would be easy to reach for AceTimer later and quietly halve
the addressable audience.

### Per-host instances

`:New()` returns an instance owning its own sampler frame, bucket table, ring, and panel. Nothing
is shared between hosts except the code and the stateless JSON encoder.

**This is the single most important rule in the design.** The July 14 investigation established
that WoW's Addon Profiler attributes a *shared* frame's CPU to the first-alphabetical addon holding
it. A perf lib creating one shared `OnUpdate` frame for all hosts would reproduce that exact
pathology — the measuring instrument corrupting the attribution it exists to fix. Every frame the
lib creates is created under the calling host's ownership.

### The descriptor

```lua
{
  name     = "AbsorbTracker",
  version  = NS.version,
  sv       = "AbsorbTrackerPerfDB",    -- host declares it in its own TOC
  ring     = 10,                       -- optional, default 10
  buckets  = {                         -- ordered; nesting declared, not prose
      { key = "absorbEvent" },
      { key = "repaintPass" },
      { key = "paintBar",   within = "repaintPass" },
      { key = "appearance", within = "repaintPass" },
      { key = "visibility", within = "repaintPass" },
  },
  suspend  = function() ... end,       -- required; host-owned
  resume   = function() ... end,       -- required
  log      = function(line) ... end,   -- optional; default chat frame
  print    = function(line) ... end,   -- optional; default chat frame
  decorate = function(frame) ... end,  -- optional; host styles the panel
  onChange = function() ... end,       -- optional; host republishes on its bus
  L        = NS.L,                     -- optional string table
}
```

`sv`, `name`, and the `suspend`/`resume` pair are required. Everything else degrades.

Declaring bucket nesting is an upgrade on the current implementation, where "repaintPass contains
paintBar" is prose in the report. With it declared, `FormatReport` renders an indented tree and
labels non-summable totals structurally instead of trusting the reader.

### Public surface

Per-instance: `on` (the hot gate field), `Note`, `Reset`, `Start`, `Measure`, `Stop`, `Cancel`,
`Suspend`, `Resume`, `BuildRecord`, `Save`, `FormatReport`, `Context`, `ContextLines`, `Progress`,
`MarkReviewed`, `Log`, `Announce`, `TogglePanel`, `OnCommand`. Static: `lib.EncodeJSON`.

The hot-path idiom survives unchanged — `local t0 = Perf.on and debugprofilestop()` is still an
upvalue read plus a field read plus a boolean test when capture is off.

### Two extraction boundaries

**The lib must not register slash commands.** `slash-commands` mandates schema-driven dispatch
through each addon's own `COMMANDS` table with the cyan tag. The lib exposes `perf:OnCommand(args)`
returning lines; each host wires one `perf` entry into its existing `COMMANDS`. The host keeps
ownership of its slash surface; the lib supplies behaviour and help text. This also keeps the lib
neutral for third parties who do not use the Ka0s command pattern.

**The panel cannot assume `NS.DebugLog`.** `PerfPanel` today calls `NS.DebugLog.MakeCloseButton`
and refreshes off `NS.MSG.PERF`. In lib form the panel refreshes itself directly — it owns the
state, so the bus hop was never needed — and styling degrades to a plain frame when `decorate` is
absent. Every Ka0s addon has a DebugLog per the standard, so in practice all six pass `decorate`.

### Record schema v2

Schema bumps from 1 to 2. Two additions, both driven by the lib being multi-host:

- `addon` — the host's name, so a record identifies itself outside the file it came from.
- `within` on each bucket entry, so a reader can render the nesting tree without the descriptor.

Everything else is unchanged. Bumping is cheap now and impossible later once six addons and
third parties are emitting records.

### Persistence, and why there is no shared DB

Each addon declares its own `<Addon>PerfDB` global in its own TOC and hands the name to the lib.

A shared `LibKa0sPerfDB` was considered and rejected on mechanics, not purity. A LibStub library
cannot declare SavedVariables — only an addon's TOC can — so the global would have to be declared
by all six addons, and WoW then:

- **on save**, writes the current value of every declared global into *that addon's own* file, so
  six addons declaring one global produces six identical full copies on disk;
- **on load**, executes each SV file's plain `LibKa0sPerfDB = { ... }` assignment in addon load
  order, each **overwriting** the previous wholesale. There is no merge.

In steady state that is merely wasteful. It breaks when copies diverge — an addon disabled for a
session, updated, reinstalled, a partial WTF copy between machines, or an uninstalled addon leaving
a stale file that loads later and clobbers current data. Worse, anything written during addon A's
load is destroyed when addon B's SV file assigns over it: order-dependent data loss with no error,
the worst failure shape for a diagnostics tool.

The ecosystem norm reflects this — AceDB operates on a table the addon declares and hands over;
LibDBIcon stores state inside the host's DB. Libraries are stateless with respect to persistence.

Per-addon globals also keep every addon working in isolation, which is the goal `library-stack-§6`
exists to protect, and keeps the `savedvariables` carve-out narrow: *one* diagnostics global per
addon, named after that addon.

### Testing

The bulk of `tests/test_perf.lua` moves to the `LibKa0s` repo with its own headless Lua 5.1 harness
and its own green gate (`lua tests/run.lua`, `luacheck .`, 0/0), mirroring the addon standard.

What stays in each addon is a smaller integration test: the descriptor is well-formed, every
declared bucket is actually reached, and `Suspend` truly makes that addon inert.

`tests/perf.lua` — the offline scenario runner — **stays per-addon**, since its scenarios are about
that addon's own hot paths. Its `probeOverhead` scenario remains the required evidence that the
instrumentation is free when capture is off.

## Standard changes (WowAddonStandards → v2.12.0)

All three of AbsorbTracker's recorded deviations are **promoted into the standard** rather than
remaining deviations.

### New section: `standards/standards/performance.md`

Added to the `STANDARDS.md` Sections list.

1. **The instrumentation lib** — vendor `LibKa0s-Perf`, one instance per addon, created at load and
   stashed on `NS`.
2. **The bracket idiom** — the gated `local t0 = Perf.on and debugprofilestop()` form, and the hard
   rule that instrumentation MUST NOT allocate or call when capture is off, with the offline
   `probeOverhead` scenario as required evidence. *(Promotes deviation #2.)*
3. **Bucket declaration**, including nesting, and the rule that nested totals are never summed.
4. **The `perf` slash verb** — reserved, dispatched through the addon's `COMMANDS` table, never
   registered by the lib. Cross-refs `slash-commands`.
5. **`<Addon>PerfDB`** — a second top-level SV global holding a capture ring, outside the AceDB tree
   so it never rides profile copy, reset, or switch. *(Promotes deviation #3.)*
6. **The Suspend/Resume host contract** — make the addon inert without a reload; enforce visibility
   at the source (a suspended check in the show-decision ladder) rather than by imperatively hiding
   frames, so nothing can re-show behind suspend's back.
7. **The capture protocol** — clean arm first (addon plus stock UI, everything else disabled),
   suspend as the finer second arm, and why: reloading or disabling shifts shared-frame ownership,
   the confound that broke the July 14 investigation.
8. **Record schema v2 and `docs/perf-runs/`** as the storage convention, so runs compare across
   versions.
9. **The offline runner** `tests/perf.lua` — outside the green gate, asserts only deterministic
   quantities (call counts, bytes allocated), MUST NOT assert wall-clock.
10. **Complexity** — `lizard` excluding `libs/`, report-only into a committed `docs/complexity.md`,
    explicitly not gating. *(Promotes deviation #1, which issue #17 assigned upstream.)*

**Adoption strength: MUST for wiring** (vendor the lib, expose `/xx perf`, declare `<Addon>PerfDB`,
implement Suspend/Resume), **SHOULD for coverage** (which hot paths get buckets — genuinely
addon-specific; some addons have almost no hot path). MUST on wiring is what makes runs comparable
across the collection and makes "run `/xx perf` and send me the JSON" true of any Ka0s addon.

### Edits to existing sections

| Section | Change |
|---|---|
| `library-stack` | New "Ka0s shared libs" table with `LibKa0s`; Ka0s-owned, vendored like Ace3, module-per-major |
| `savedvariables` | Carve-out for the diagnostics global — the only sanctioned non-AceDB SV |
| `toc-file` | Second SV global; `LibKa0s` placement in the lib load block, after Ace3 |
| `slash-commands` | Reserve `perf` |
| `testing` | The perf runner's outside-the-gate status; the per-addon descriptor/suspend integration test |
| `documentation` | `docs/performance.md` and `docs/perf-runs/README.md` join the docs set |
| `debug-logging` | The panel's `decorate` relationship to the console |
| `anti-patterns` | Two entries: ungated instrumentation in hot paths; shared frames for measurement (the instrument corrupting its own attribution) |
| `open-evolutions` | Record `LibKa0s` as the path for future shared modules |

### Plugin

The `wow-addon` plugin needs almost nothing, which validates its design. `agents/standards-audit.md`
discovers sections by following the `STANDARDS.md` Sections list rather than hard-coding filenames,
so `performance.md` is picked up automatically. `commands/new-addon.md` follows `NEW_ADDON.md` and
inherits the scaffolding. The only work is updating `NEW_ADDON.md` and `NEW_ADDON_CONTEXT.md`.

## Distribution and shipping

Two phases. Phase 1 starts immediately; phase 2 is gated on rollout step 5.

### Phase 1 — GitHub source, vendored by hand

Source of truth: <https://github.com/tusharsaxena/LibKa0s> (public, MIT).

Consumers vendor it: copy the lib folder into the addon's `libs/` and commit it, exactly as they
already do for Ace3. No packager `externals:` — `library-stack-§3` forbids that for Ka0s addons,
and the point is that every addon is installable by copying its folder into `Interface/AddOns/`
with no packager step.

This constrains the repo layout. The vendorable payload must sit in its own subfolder so it copies
verbatim, with tests and docs *outside* it:

```
LibKa0s/                  <- repo root
  LibKa0s/                <- this folder is what gets copied to <Addon>/libs/LibKa0s/
    LibKa0s.xml           <- aggregate; lists the modules
    Perf.lua              <- LibStub("LibKa0s-Perf-1.0")
  tests/
  docs/
  README.md
  LICENSE
```

Updating a consumer is: copy the folder, run the addon's green gate, commit. There is no version
pinning mechanism beyond "which copy each addon happens to hold" — LibStub resolves the winner at
runtime, so a stale consumer is served the newest vendored copy present on the machine. That is the
normal Ace3 situation and is why the descriptor contract must be additive-only.

**Two version numbers, and they are not the same thing.** The repo carries a semver tag for humans
(`v1.2.0`, changelog, release notes). Each module separately carries a LibStub **MINOR** integer
that must increment monotonically on every released change to that module — it is what LibStub
compares to pick a winner. A release that touches only `Perf.lua` bumps the repo semver and the
Perf minor, and nothing else.

### Phase 2 — CurseForge library project

The design goal from day one is that this is publishable, not that it is published yet. What phase
2 adds:

- **`.pkgmeta` as a library project** with `package-as: LibKa0s`, plus `X-Curse-Project-ID`.
- **A minimal `.toc`**, so the lib is installable standalone as well as embedded. This is normal for
  published libs and helps testing and discoverability; LibStub dedup means an embedded copy and a
  standalone install coexist correctly. It does **not** make the lib a dependency — Ka0s addons MUST
  keep vendoring it and MUST NOT list it under `## Dependencies:` (`library-stack-§6`).
- **Both consumption paths supported.** Ka0s addons vendor. Third parties may vendor *or* pull it
  via packager `externals:` — the lib must not care which.
- **`#@no-lib-strip@` guards** in consumer TOCs so third parties can strip embedded copies.
- **A public README documenting the descriptor contract**, an integration example, and the
  changelog with migration notes.

**Publication is gated on rollout step 5** — six independent consumers first. Once published the
contract is frozen in the wild.

### What being publishable requires of the design now

Built in from the start rather than retrofitted, because a published lib cannot break its contract
afterward.

- **No assumption the host follows the Ka0s standard.** `log`, `print`, `decorate`, `onChange`, and
  `L` are all optional with sane fallbacks. `OnCommand` returns lines rather than printing.
- **Strings are overridable** via the optional `L` table. Ka0s addons pass `NS.L`.
- **LibStub minor discipline is a promise.** Within `-1.0` the descriptor contract may only grow,
  never break — once public, you cannot know who has vendored what.
- **LibStub-only dependency** is a feature to protect, not an accident.

## Rollout

Ordered to delay both the standards change and publication until the design has survived contact.

1. **Extract to `LibKa0s`.** Tests move with it; the lib gets its own green gate. Parity check
   against current AbsorbTracker behaviour.
2. **AbsorbTracker becomes consumer #1.** `core/Perf.lua` and `core/PerfPanel.lua` are deleted,
   replaced by the vendored lib plus a descriptor. Green gate, then re-run an in-game capture and
   confirm the numbers match the pre-extraction ones. *An extraction that changes the measurements
   is a bug in the extraction.*
3. **Standards update to v2.12.0** — `performance.md` plus the cross-section edits, only now, once
   one real addon proves the shape.
4. **`NEW_ADDON.md` / `NEW_ADDON_CONTEXT.md`**, so new addons are born with it.
5. **Roll to the remaining five**, starting with **KickCD** — the reference implementation and the
   most structurally complex, so the one most likely to expose a descriptor assumption that only
   held for AbsorbTracker. Then LootHistory, BankLedger, ConsumableMaster, WhatGroup.
6. **Publish to CurseForge** — last, gated on step 5 finishing. Six independent consumers is the
   pressure test that finds API mistakes.

Steps 3 and 2 must not be reordered. Writing the normative section from the design rather than from
a working extraction is how a standard acquires rules that do not survive their second
implementation.

## Risks

| Risk | Mitigation |
|---|---|
| The lib's own frames re-create the shared-frame attribution trap | Per-host instances; no lib-level shared frame. Verified by the step 2 parity capture. |
| Extraction silently changes measurements | Step 2 re-runs an in-game capture and diffs against pre-extraction numbers before anything else proceeds. |
| The descriptor fits only AbsorbTracker | KickCD deliberately goes second, before the API is frozen or published. |
| Six addons now carry ~900 vendored lines | Accepted cost of the ship-always decision; LibStub dedup means one copy loads regardless of how many are installed. |
| Version skew across six vendored copies | Per-module LibStub majors keep skew narrow; descriptor contract is additive-only. |

## Open questions

Tracked as issues on <https://github.com/tusharsaxena/LibKa0s>.

- [#1](https://github.com/tusharsaxena/LibKa0s/issues/1) — **Regression thresholds and gates** stay
  unset, carried forward from the predecessor spec. They cannot be chosen before baseline numbers
  exist across more than one addon. Blocked on rollout step 5.
- [#2](https://github.com/tusharsaxena/LibKa0s/issues/2) — **Which further modules move into
  `LibKa0s`** (Compat, DebugLog, the bus). The module-per-major structure makes each an
  independent, additive decision.
- [#3](https://github.com/tusharsaxena/LibKa0s/issues/3) — **CurseForge publication**, phase 2 of
  the shipping plan. Gated on rollout step 5.
- [#4](https://github.com/tusharsaxena/LibKa0s/issues/4) — **Schema v1 records alongside v2.**
  AbsorbTracker has committed schema-1 captures and users will have schema-1 rings at upgrade time.
