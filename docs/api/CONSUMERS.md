# Who calls what: the LibKa0s consumer census

**Stamped v1.69.0** (tag `v1.69.0`), re-measured 2026-10-06 across the eleven addons in
`WowAddonStandards/standards/ADDONS.md`, as their sibling working trees stood that day. Only
LootHistory has adopted anything new since v1.67.0 (`LineChart`). The v1.67.0 run was taken on the
same branch with v1.67.0 vendored, by item `CA-LK-04` of
`Ka0sAddonsCommonTasks/docs/2026-10-02-LIBKA0S_CENSUS_ADOPTION`, after the nine issues the first run
filed were fixed. The first run was taken at v1.66.0 for
[#9](https://github.com/tusharsaxena/LibKa0s/issues/9) by item `GI-LK-13` of
`Ka0sAddonsCommonTasks/docs/2026-10-01-GITHUB_ISSUE_PASS`.

This page answers one question per public export: **does any host call it, and if not, why is it
still here?** `-1.0` is frozen additive-only, so nothing below can be deleted. An export with no
consumer is permanent, and its shape is pinned only by this library's own suite. That makes "who
actually calls this" worth answering once, on purpose, instead of re-deriving it in every adoption
cycle. Three earlier records disagreed (`adoption-prompt.md`'s v1.5.0 list, the frozen
`adoption/2026-08-01-v2/03_DEVIATIONS.md`, and an ad hoc grep), and a `grep` count is what produced
the disagreement.

It is a census, so it goes stale. Re-run it (see [Re-running it](#re-running-it)) after any release
that adds a surface, and restamp the page.

## The numbers

420 public exports across fifteen majors: 104 lib-level members, 184 instance members and 132
descriptor fields.

| Verdict | Exports | Meaning |
|---|---|---|
| consumed | 244 | Called, or passed, by three or more hosts |
| thin | 68 | One or two hosts. A misfit found by the next host is a library gap on first contact |
| **zero** | **108** | No host calls it. Each one is split below |

The 108 zero-consumer exports:

| Split | Exports | What happens |
|---|---|---|
| host duplicate | 0 | None left: seven of the eight from v1.66.0 were adopted, and the eighth, Options `lib.LAYOUT`, left the split when KickCD deleted its two header copies instead of reading them; it is now documented (see [What moved since v1.66.0](#what-moved-since-v1660)) |
| suspect shape | 0 | Both from v1.66.0 were settled at v1.67.0: Core 10 gave `MakeResizable` its lock gate ([#41](https://github.com/tusharsaxena/LibKa0s/issues/41)), and every host now passes the Options descriptor's `addonName` ([#42](https://github.com/tusharsaxena/LibKa0s/issues/42)) |
| deliberate host copy | 5 | A host keeps its own copy on purpose, with the reason recorded beside it. Listed, not re-opened |
| documented | 103 | No duplicate and no host waiting for it. Each gets a "no consumer as of v1.69.0, kept because ..." line in its major's live document |

Most of the 103 fall into four groups. The rows below give each export's own reason.

- **Reached through the library's own code, never by name.** Examples: the Perf instance methods
  that the `/x perf` verbs dispatch to through `OnCommand`; the Media catalogs that `Font` / `Icon` /
  `Texture` read; `Lifecycle` `Hold` / `Release` behind `Set`; Options' `SetChromeHeight` behind the
  chrome makers.
- **Read by host tests only.** For example DebugLog's `buffer`, `FindLine`, `LastLine`, `BufferSize`,
  `CopyText` and `BuildDiagnostics`. Hundreds of test lines read them, and no production line does.
  The census does not count a test as a consumer.
- **Tuning constants published so the number is cited rather than restated.** For example
  `MAX_BUFFER`, `BUFFER_SLACK`, `DIAG_MAX_LINES` and `DEFAULT_RING`.
- **Opt-in overrides every host leaves at the default.** For example DebugLog's `skin` and
  `makeCloseButton`, Perf's `decorate`, `ring`, `onChange` and `L`, and Launcher's `L`.

## What moved since v1.66.0

**v1.69.0 re-run (2026-10-06).** No verdict moved. Eleven exports are new, all from
`WidgetsLineChart.lua` minor 1: `lib.LineChart` has one consumer, LootHistory's `NS.MakeLineChart`
seam at `core/WidgetsSetup.lua`, which is the only chart host (thin, 1). `lib.ChartMath` and
`lib.LINE_CHART` have zero host calls and are published for hosts that align decorations to the
chart's mapping; kept. The eight new descriptor fields (`hoverXs`, `integer`, `markers`, `series`,
`xMax`, `xMin`, `yMax`, `yMin`) are read from the data a host hands the chart, which LootHistory
builds in `modules/TimelineModel.lua` and passes through the seam's table, so the scan sees no
literal pass; zero, documented. The v1.66.0 to v1.67.0 table below is unchanged.

Nine exports changed verdict, every one of them through the nine issues the v1.66.0 run filed. No
other verdict moved. Hit counts did move on other rows, because the hosts' code changed around
them.

| Major | Export | v1.66.0 | v1.67.0 | Consumers now | Through |
|---|---|---|---|---|---|
| Core | `lib.MakeResizable` | zero, host duplicate and suspect shape | consumed (3) | BankLedger, LootHistory, MultiMeters | BankLedger#21, LootHistory#33, MultiMeters#58; the lock gate is Core 10 (#41) |
| Core | `lib.SECRET` | zero, host duplicate | consumed (3) | AbsorbTracker, KickCD, MultiMeters | AbsorbTracker#33, KickCD#36, MultiMeters#58 |
| Slash | `lib.SplitVerb` | zero, host duplicate | consumed (3) | AbsorbTracker, ConsumableMaster, KickCD | AbsorbTracker#33, ConsumableMaster#44, KickCD#36 |
| Slash | `lib.FindCommand` | zero, host duplicate | thin (2) | ConsumableMaster, KickCD | ConsumableMaster#44, KickCD#36 |
| Slash | `lib.CommandRows` | zero, host duplicate | thin (2) | ConsumableMaster, KickCD | ConsumableMaster#44, KickCD#36 |
| Slash | `lib.ProfileNames` | zero, host duplicate | thin (1) | AbsorbTracker | AbsorbTracker#33 |
| Options | `PADDING_X` (instance) | zero, host duplicate | thin (1) | PanelMaster | PanelMaster#56 |
| Options | `addonName` (descriptor) | zero, suspect shape | consumed (11) | all 11 | #42 (OptionsIdList 3) |
| Options | `lib.LAYOUT` | zero, host duplicate | zero, kept, documented | none | KickCD#36 deleted its two copies of internal header keys rather than re-reading them, so no duplicate is left |

## Method

The tool is `Ka0sAddonsCommonTasks/docs/2026-10-02-LIBKA0S_CENSUS_ADOPTION/plan-data/census.lua`
(pure Lua 5.1), copied from the v1.66.0 run with its logic unchanged. Its raw output is
`census-v1.69.0/summary.tsv` and `census-v1.69.0/hits.tsv` beside it. The hand-read verdicts are
`census-v1.69.0/verdicts.tsv` and the issues the v1.66.0 run filed are `census-v1.69.0/issues.tsv`.
The tables on this page are rendered from those files by `census-render.lua`. The v1.66.0 data stays
in `docs/2026-10-01-GITHUB_ISSUE_PASS/plan-data/census/`.

1. **What is enumerated.**
   - *lib*: every member of each major's live library table, loaded through this repo's mock
     exactly as `tools/gen-api-members.lua` does and filtered by the same `Kit.publicMembers` rule.
     These are the `members-*.json` entries.
   - *instance*: every public member a major's own files define on what `lib:New` returns, found
     statically as `function R.X(`, `function R:X(` or `R.X =`, where `R` is the major's instance
     local (`Sl`, `D`, `O`, `P`, `S`, `B`, `LC`, `Lb`).
   - *descriptor*: every field a major's files read as `d.<field>`, outside comments.

   A field read through another name (Schema's `format` and `debug`, for example) is outside this
   definition and is not counted.
2. **What is searched.** Every git-tracked `.lua` file of the eleven addons, excluding `libs/` and
   `tests/_kit/`: 1131 files.
3. **How a hit is classified.**
   - **call** is a member access `X.Name` / `X:Name` whose receiver `X` is known to hold that
     major's library table or one of its instances. Receivers are learned per addon from
     `LibStub("LibKa0s-<M>-1.0")` assignments, `<receiver>:New(` results and plain aliases of
     either. A one-line forwarder (`function DL.ShowCopy() D:ShowCopy() end`) counts as a call.
   - **name-only** is an access whose receiver does not resolve: `self:Stop()`, a parameter, or
     another table's member of the same name. It is listed for a reader and never counted.
   - **def** is a host definition of the same name.
   - **stub** is a hit inside a degradation block (`if not <libVar> then ... end`, or the `else`
     arm of `if <libVar> then`).
   - **test** is any hit under `tests/`.

   String literals and comments never count.
4. **Descriptor fields count only where passed.** A field counts when it is a top-level key of the
   table literal handed to `<receiver>:New(` (or `CopyWindow(`), or of the table that a named
   argument is assigned in the same file. A grep for a bare key finds locals: the 2026-08-02 audit
   counted `skin` as consumed on the strength of a local in BankLedger's session window.
5. **What was read by hand.** Every zero-consumer export, every name-only hit standing between an
   export and a zero verdict, and the thin descriptor fields. A **host duplicate** is a host
   implementation of the same behavior, whatever it is called. `lowerFirst` is `SplitVerb`, and a
   hand-built 16x16 size-grabber grip is `MakeResizable`. The tool cannot find those. They were
   found by reading each export's contract and searching the hosts for the behavior.

Three limits. A host that reaches an instance only through a function parameter registers as
name-only, so a **thin** count is a lower bound. A name shared by several majors (`New`, `STRINGS`)
is resolved per receiver, not per name. A function's options table is not a descriptor, so
`MakeResizable`'s `opts` fields (`canResize`, `onResizeStop` and `gripParent` from Core 10) are not
counted on their own.

## The zero-consumer set

*Evidence* is the hand-read finding: where the duplicate lives, why nothing calls the export, or
where a deliberate copy records its reason. *Hits by class* is the tool's raw count.

| Major | Export | Evidence | Hits by class | Verdict |
|---|---|---|---|---|
| Lifecycle | `Hold` (instance) | stubs only (18 stub lines across 6 hosts) | call 0 · stub 18 · test 48 | zero — kept, documented |
| Lifecycle | `PrintHolds` (instance) | stubs only | call 0 · stub 9 · test 5 | zero — kept, documented |
| Lifecycle | `Release` (instance) | stubs only; the 7 name hits are other tables' `Release` | call 0 · name-only 7 · def 2 · stub 17 · test 80 | zero — kept, documented |
| Lifecycle | `name` (instance) | instance data field | call 0 · name-only 232 · def 3 · stub 84 · test 5391 | zero — kept, documented |
| Schema | `lib.STRINGS` | no host reads the table by name | call 0 · name-only 1 · stub 4 · test 147 | zero — kept, documented |
| Media | `lib.FONTS` | no host reads the table by name | call 0 · test 29 | zero — kept, documented |
| Media | `lib.ICONS` | no host reads the table by name | call 0 · test 30 | zero — kept, documented |
| Media | `lib.TEXTURES` | no host reads the table by name | call 0 · test 3 | zero — kept, documented |
| Media | `lib.Texture` | ConsumableMaster's two `Texture` hits are its own `MacroDisplay.Texture` | call 0 · name-only 2 · def 1 · test 40 | zero — kept, documented |
| Media | `lib.VENDOR_PATH` | default value | call 0 · test 1 | zero — kept, documented |
| Widgets | `lib.ChartMath` | no host calls it; LootHistory aligns its in/out strip through the chart instance's `XToPixel` instead | call 0 · test 1 | zero — kept, documented |
| Widgets | `lib.LINE_CHART` | no host reads it | call 0 · test 1 | zero — kept, documented |
| Widgets | `backdrop` (descriptor) | no `CopyWindow` descriptor passes it | call 0 | zero — kept, documented |
| Widgets | `hoverXs` (descriptor) | hit scan sees no descriptor literal naming it | call 0 | zero — kept, documented |
| Widgets | `integer` (descriptor) | hit scan sees no descriptor literal naming it | call 0 | zero — kept, documented |
| Widgets | `makeCloseButton` (descriptor) | no `CopyWindow` descriptor passes it | call 0 | zero — kept, documented |
| Widgets | `markers` (descriptor) | hit scan sees no descriptor literal naming it | call 0 | zero — kept, documented |
| Widgets | `scrollName` (descriptor) | library-internal caller only | call 0 | zero — kept, documented |
| Widgets | `series` (descriptor) | hit scan sees no descriptor literal naming it | call 0 | zero — kept, documented |
| Widgets | `xMax` (descriptor) | hit scan sees no descriptor literal naming it | call 0 | zero — kept, documented |
| Widgets | `xMin` (descriptor) | hit scan sees no descriptor literal naming it | call 0 | zero — kept, documented |
| Widgets | `yMax` (descriptor) | hit scan sees no descriptor literal naming it | call 0 | zero — kept, documented |
| Widgets | `yMin` (descriptor) | hit scan sees no descriptor literal naming it | call 0 | zero — kept, documented |
| DebugLog | `lib.AT_ENABLE_MAX` | tuning constant | call 0 | zero — kept, documented |
| DebugLog | `lib.BUFFER_SLACK` | tuning constant | call 0 · test 1 | zero — kept, documented |
| DebugLog | `lib.DIAG_MAX_LINES` | tuning constant | call 0 · test 1 | zero — kept, documented |
| DebugLog | `lib.DIAG_MAX_PER_LIST` | tuning constant | call 0 | zero — kept, documented |
| DebugLog | `lib.GATE_MAX_KEYS` | tuning constant | call 0 | zero — kept, documented |
| DebugLog | `lib.MAX_BUFFER` | read by host tests only | call 0 · test 8 | zero — kept, documented |
| DebugLog | `lib.MakeCloseButton` | the 21 name hits are `Core.MakeCloseButton` calls | call 0 · name-only 21 · def 11 · stub 19 · test 109 | zero — kept, documented |
| DebugLog | `lib.STRINGS` | no host reads the table by name | call 0 · name-only 1 · stub 4 · test 147 | zero — kept, documented |
| DebugLog | `lib.TIME_COPY` | diagnostic switch | call 0 | zero — kept, documented |
| DebugLog | `BufferSize` (instance) | read by host tests only (62 hits) | call 0 · stub 9 · test 62 | zero — kept, documented |
| DebugLog | `BuildDiagnostics` (instance) | read by host tests only | call 0 · stub 15 · test 31 | zero — kept, documented |
| DebugLog | `CopyText` (instance) | read by host tests only | call 0 · stub 3 · test 22 | zero — kept, documented |
| DebugLog | `FindLine` (instance) | read by host tests only (88 hits) | call 0 · stub 9 · test 88 | zero — kept, documented |
| DebugLog | `LastLine` (instance) | read by host tests only | call 0 · stub 9 · test 50 | zero — kept, documented |
| DebugLog | `MakeCloseButton` (instance) | mirror of the lib-level member | call 0 · name-only 21 · def 11 · stub 19 · test 109 | zero — kept, documented |
| DebugLog | `Text` (instance) | the 15 name hits are `Sl:Text` (LibKa0s-Slash-1.0) calls | call 0 · name-only 15 · stub 6 · test 209 | zero — kept, documented |
| DebugLog | `buffer` (instance) | read by host tests only (478 hits) | call 0 · stub 13 · test 479 | zero — kept, documented |
| DebugLog | `diagnosticsEnablesLogging` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| DebugLog | `makeCloseButton` (descriptor) | BankLedger core/DebugLogSetup.lua:146 and LootHistory core/DebugLogSetup.lua:163 record why | call 0 | zero — kept, documented |
| DebugLog | `skin` (descriptor) | no descriptor passes it (MultiMeters settings/Schema_Compose.lua:248 is a locale key) | call 0 | zero — kept, documented |
| Slash | `CliResetAll` (instance) | LootHistory settings/Slash.lua:433-435 and BankLedger settings/Slash.lua:478-479 record why | call 0 · name-only 6 · def 3 · stub 6 · test 64 | zero — deliberate host copy |
| Launcher | `lib.STRINGS` | no host reads the table by name | call 0 · name-only 1 · stub 4 · test 147 | zero — kept, documented |
| Launcher | `Object` (instance) | read by host tests only (110 hits) | call 0 · stub 7 · test 110 | zero — kept, documented |
| Launcher | `L` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Options | `lib.LAYOUT` | KickCD core/Constants.lua:109-116 records the deletion; no host reads the table by name | call 0 · name-only 7 · test 86 | zero — kept, documented |
| Options | `lib.PatchAlwaysShowScrollbar` | reached through `EnsureScroll` | call 0 · stub 8 · test 20 | zero — kept, documented |
| Options | `lib.STRINGS` | no host reads the table by name | call 0 · name-only 1 · stub 4 · test 147 | zero — kept, documented |
| Options | `CHROME_GAP` (instance) | no host draws such chrome today | call 0 · stub 6 · test 14 | zero — kept, documented |
| Options | `FONT_FLAGS` (instance) | MultiMeters settings/Schema_Compose.lua:165-184 records why | call 0 · stub 4 · test 11 | zero — deliberate host copy |
| Options | `FONT_FLAGS_SORT` (instance) | MultiMeters settings/Schema_Compose.lua:184 | call 0 · stub 3 · test 9 | zero — deliberate host copy |
| Options | `ID_NAME_HINT` (instance) | reached through `IdInput` | call 0 · stub 14 · test 3 | zero — kept, documented |
| Options | `PatchAlwaysShowScrollbar` (instance) | reached through `EnsureScroll` | call 0 · stub 8 · test 20 | zero — kept, documented |
| Options | `RenderSchema` (instance) | superseded in practice | call 0 · stub 13 · test 24 | zero — kept, documented |
| Options | `SetChromeHeight` (instance) | reached through the chrome makers | call 0 · stub 12 · test 3 | zero — kept, documented |
| Options | `TAB_H` (instance) | no host measures its own strip today | call 0 · stub 5 · test 16 | zero — kept, documented |
| Options | `UnnamedCandidates` (instance) | reached through `IdInput` | call 0 · stub 13 · test 1 | zero — kept, documented |
| Options | `VISIBILITY_SORT` (instance) | MultiMeters settings/Schema_Compose.lua:602-611 records why | call 0 · stub 3 · test 9 | zero — deliberate host copy |
| Options | `VISIBILITY_VALUES` (instance) | MultiMeters settings/Schema_Compose.lua:602-611 records why | call 0 · stub 3 · test 9 | zero — deliberate host copy |
| Options | `afterRestoreAll` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Perf | `lib.DEFAULT_RING` | default value | call 0 · test 2 | zero — kept, documented |
| Perf | `lib.EncodeJSON` | read by host tests only | call 0 · test 12 | zero — kept, documented |
| Perf | `lib.SCHEMA` | read by host tests only | call 0 · stub 1 · test 24 | zero — kept, documented |
| Perf | `lib.STRINGS` | no host reads the table by name | call 0 · name-only 1 · stub 4 · test 147 | zero — kept, documented |
| Perf | `Announce` (instance) | reached through `OnCommand` | call 0 · name-only 3 · def 1 · test 4 | zero — kept, documented |
| Perf | `BuildRecord` (instance) | reached through `OnCommand` | call 0 · name-only 1 · def 1 · test 14 | zero — kept, documented |
| Perf | `Cancel` (instance) | reached through `OnCommand` | call 0 · name-only 24 · test 30 | zero — kept, documented |
| Perf | `Close` (instance) | no host brackets with `Open`/`Close` | call 0 · name-only 4 · def 1 · stub 2 · test 62 | zero — kept, documented |
| Perf | `Context` (instance) | reached through `OnCommand` | call 0 · name-only 10 · test 6 | zero — kept, documented |
| Perf | `ContextLines` (instance) | reached through `OnCommand` | call 0 | zero — kept, documented |
| Perf | `EXPERIMENTS` (instance) | library-internal table (not in the instance table) | call 0 | zero — kept, documented |
| Perf | `EncodeJSON` (instance) | read by host tests only | call 0 · test 12 | zero — kept, documented |
| Perf | `FormatReport` (instance) | reached through `OnCommand` | call 0 · test 3 | zero — kept, documented |
| Perf | `HidePanel` (instance) | reached through `OnCommand` and the panel | call 0 · test 17 | zero — kept, documented |
| Perf | `IsPanelShown` (instance) | read by host tests only | call 0 · test 6 | zero — kept, documented |
| Perf | `LABELS` (instance) | library-internal table (not in the instance table) | call 0 · test 10 | zero — kept, documented |
| Perf | `Log` (instance) | reached through `OnCommand` | call 0 · test 4 | zero — kept, documented |
| Perf | `MarkReviewed` (instance) | reached through `OnCommand` | call 0 · test 1 | zero — kept, documented |
| Perf | `Measure` (instance) | reached through `OnCommand` | call 0 · name-only 1 · test 6 | zero — kept, documented |
| Perf | `Open` (instance) | no host brackets with `Open`/`Close` | call 0 · name-only 25 · def 7 · stub 3 · test 209 | zero — kept, documented |
| Perf | `PanelIsActionable` (instance) | no `decorate` host | call 0 | zero — kept, documented |
| Perf | `PanelStateOf` (instance) | no `decorate` host | call 0 · test 2 | zero — kept, documented |
| Perf | `Progress` (instance) | reached through the panel | call 0 | zero — kept, documented |
| Perf | `RefreshPanel` (instance) | reached through the library's own transitions | call 0 · name-only 25 · stub 8 · test 24 | zero — kept, documented |
| Perf | `Reset` (instance) | reached through `OnCommand` | call 0 · name-only 4 · def 3 · stub 8 · test 373 | zero — kept, documented |
| Perf | `Resume` (instance) | reached through `OnCommand` | call 0 · name-only 8 · def 14 · test 70 | zero — kept, documented |
| Perf | `SCHEMA` (instance) | read by host tests only | call 0 · stub 1 · test 24 | zero — kept, documented |
| Perf | `STEPS` (instance) | reached through the panel | call 0 · test 13 | zero — kept, documented |
| Perf | `Save` (instance) | reached through `OnCommand` | call 0 · name-only 1 · def 1 · test 20 | zero — kept, documented |
| Perf | `ShowPanel` (instance) | reached through `OnCommand` | call 0 · test 5 | zero — kept, documented |
| Perf | `Start` (instance) | reached through `OnCommand` | call 0 · name-only 4 · def 2 · test 77 | zero — kept, documented |
| Perf | `StatusLines` (instance) | reached through `OnCommand` | call 0 · test 1 | zero — kept, documented |
| Perf | `Stop` (instance) | reached through `OnCommand` | call 0 · name-only 21 · def 5 · test 32 | zero — kept, documented |
| Perf | `Suspend` (instance) | reached through `OnCommand` | call 0 · name-only 4 · def 15 · test 93 | zero — kept, documented |
| Perf | `TogglePanel` (instance) | reached through `OnCommand` | call 0 | zero — kept, documented |
| Perf | `Usage` (instance) | reached through `OnCommand` | call 0 · test 46 | zero — kept, documented |
| Perf | `context` (instance) | instance data field (not in the instance table) | call 0 · name-only 2 · def 1 · test 167 | zero — kept, documented |
| Perf | `descriptor` (instance) | instance data field (not in the instance table) | call 0 · stub 10 · test 733 | zero — kept, documented |
| Perf | `name` (instance) | instance data field (not in the instance table) | call 0 · name-only 232 · def 3 · stub 84 · test 5391 | zero — kept, documented |
| Perf | `ringMax` (instance) | instance data field (not in the instance table) | call 0 | zero — kept, documented |
| Perf | `slash` (instance) | instance data field (not in the instance table) | call 0 · stub 63 · test 1216 | zero — kept, documented |
| Perf | `title` (instance) | instance data field (not in the instance table) | call 0 · name-only 37 · def 2 · stub 2 · test 380 | zero — kept, documented |
| Perf | `L` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Perf | `decorate` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Perf | `onChange` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Perf | `ring` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |

## Every export

Consumers lists each calling host with its first production call when there are three or fewer,
and the host names otherwise. Every hit with its file and line is in `census-v1.69.0/hits.tsv`. Hits for an
export called by three or more hosts are capped there at five per host per class, and the counts
here are uncapped.

| Major | Export | Consumers (first production call per host) | Hits by class | Verdict |
|---|---|---|---|---|
| Core | `lib.ApplySkin` | 6: AuraMaster, BankLedger, LootHistory, MultiMeters, PartyFrameEnhanced, WhatGroup | call 6 · name-only 17 · def 2 · stub 9 · test 14 | consumed (6) |
| Core | `lib.ClassColor` | AuraMaster `core/CoreSetup.lua:151`; MultiMeters `core/CoreSetup.lua:264` | call 2 · name-only 5 · def 1 · stub 3 · test 14 | thin (2) |
| Core | `lib.IsConcatSafe` | 10: AbsorbTracker, BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat, WhatGroup | call 10 · name-only 10 · stub 21 · test 78 | consumed (10) |
| Core | `lib.MakeCloseButton` | 9: AuraMaster, ConsumableMaster, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat, WhatGroup | call 9 · name-only 12 · def 11 · stub 19 · test 109 | consumed (9) |
| Core | `lib.MakeResizable` | BankLedger `core/CoreSetup.lua:184`; LootHistory `core/CoreSetup.lua:284`; MultiMeters `core/CoreSetup.lua:306` | call 3 · name-only 4 · stub 4 · test 39 | consumed (3) |
| Core | `lib.New` | all 11 | call 11 · name-only 124 · def 16 · stub 16 · test 723 | consumed (11) |
| Core | `lib.RGBA` | ConsumableMaster `core/CoreSetup.lua:163`; MultiMeters `core/CoreSetup.lua:243` | call 2 · name-only 8 · stub 2 · test 35 | thin (2) |
| Core | `lib.ResolveColor` | 6: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, PanelMaster, PartyFrameEnhanced | call 7 · name-only 30 · def 1 · stub 4 · test 17 | consumed (6) |
| Core | `lib.SECRET` | AbsorbTracker `core/CoreSetup.lua:124`; KickCD `core/CoreSetup.lua:194`; MultiMeters `core/CoreSetup.lua:236` | call 3 · name-only 3 · stub 10 · test 297 | consumed (3) |
| Core | `lib.SKIN` | 4: AuraMaster, MultiMeters, PartyFrameEnhanced, WhatGroup | call 4 · name-only 7 · stub 16 · test 25 | consumed (4) |
| Core | `lib.SafeRegisterEvent` | all 11 | call 11 · name-only 39 · def 1 · stub 15 · test 41 | consumed (11) |
| Core | `lib.SafeRegisterEvents` | 7: AbsorbTracker, AuraMaster, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, PrettyChat | call 7 · name-only 2 · def 1 · stub 8 · test 10 | consumed (7) |
| Core | `lib.SafeRegisterUnitEvent` | 7: AbsorbTracker, AuraMaster, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, PrettyChat | call 7 · name-only 14 · def 1 · stub 8 · test 10 | consumed (7) |
| Core | `lib.SafeToString` | all 11 | call 11 · name-only 57 · stub 42 · test 161 | consumed (11) |
| Core | `prefix` (descriptor) | all 11 | call 11 | consumed (11) |
| Core | `sep` (descriptor) | PrettyChat `core/CoreSetup.lua:176` | call 1 | thin (1) |
| Core | `sink` (descriptor) | ConsumableMaster `core/CoreSetup.lua:181`; WhatGroup `core/CoreSetup.lua:177` | call 2 | thin (2) |
| Env | `lib.GetAddOnMetadata` | all 11 | call 11 · name-only 24 · test 96 | consumed (11) |
| Env | `lib.GetPlayerMapID` | BankLedger `core/EnvSetup.lua:82`; LootHistory `core/EnvSetup.lua:88` | call 2 · test 2 | thin (2) |
| Env | `lib.GetZone` | BankLedger `core/EnvSetup.lua:98`; LootHistory `core/EnvSetup.lua:106` | call 2 · test 2 | thin (2) |
| Env | `lib.Version` | all 11 | call 11 · name-only 35 · def 13 · stub 5 · test 248 | consumed (11) |
| Compat | `lib.CanAccess` | AuraMaster `core/Secrets.lua:53`; MultiMeters `core/Secrets.lua:191` | call 2 · name-only 31 · test 55 | thin (2) |
| Compat | `lib.GetSpecialization` | ConsumableMaster `core/Compat.lua:38`; KickCD `core/Compat.lua:252`; MultiMeters `core/Compat.lua:80` | call 3 · name-only 4 · test 43 | consumed (3) |
| Compat | `lib.GetSpecializationInfo` | ConsumableMaster `core/Compat.lua:42`; KickCD `core/Compat.lua:258`; MultiMeters `core/Compat.lua:81` | call 3 · name-only 2 · test 51 | consumed (3) |
| Compat | `lib.GetSpellCooldown` | KickCD `core/Compat.lua:101`; WhatGroup `core/Compat.lua:64` | call 2 · name-only 5 · test 72 | thin (2) |
| Compat | `lib.GetSpellInfo` | AuraMaster `core/Compat.lua:425`; KickCD `core/Compat.lua:169`; MultiMeters `core/Compat.lua:78` | call 3 · name-only 23 · def 1 · test 129 | consumed (3) |
| Compat | `lib.GetSpellName` | ConsumableMaster `core/Compat.lua:83`; LootHistory `core/Compat.lua:103`; WhatGroup `core/Compat.lua:51` | call 3 · name-only 14 · test 116 | consumed (3) |
| Compat | `lib.GetSpellTexture` | KickCD `core/Compat.lua:160`; MultiMeters `core/Compat.lua:79`; WhatGroup `core/Compat.lua:59` | call 3 · name-only 10 · test 62 | consumed (3) |
| Compat | `lib.IsSafeKey` | AuraMaster `core/Secrets.lua:83`; MultiMeters `core/Secrets.lua:248` | call 2 · name-only 30 · test 33 | thin (2) |
| Compat | `lib.IsSecret` | 5: AuraMaster, ConsumableMaster, KickCD, MultiMeters, PartyFrameEnhanced | call 5 · name-only 47 · test 70 | consumed (5) |
| Lifecycle | `lib.HOLD_DISABLED` | all 11 | call 13 · name-only 18 · stub 6 · test 23 | consumed (11) |
| Lifecycle | `lib.HOLD_PERF` | 5: AuraMaster, LootHistory, PanelMaster, PrettyChat, WhatGroup | call 5 · stub 6 · test 48 | consumed (5) |
| Lifecycle | `lib.New` | 9: AuraMaster, BankLedger, ConsumableMaster, KickCD, LootHistory, PanelMaster, PartyFrameEnhanced, PrettyChat, WhatGroup | call 9 · name-only 126 · def 16 · stub 16 · test 723 | consumed (9) |
| Lifecycle | `Hold` (instance) | none | call 0 · stub 18 · test 48 | zero — kept, documented |
| Lifecycle | `Holds` (instance) | all 11 | call 21 · stub 9 · test 21 | consumed (11) |
| Lifecycle | `IsDown` (instance) | all 11 | call 22 · name-only 10 · def 1 · stub 9 · test 48 | consumed (11) |
| Lifecycle | `IsHeld` (instance) | 4: AuraMaster, BankLedger, ConsumableMaster, MultiMeters | call 4 · stub 9 · test 23 | consumed (4) |
| Lifecycle | `PrintHolds` (instance) | none | call 0 · stub 9 · test 5 | zero — kept, documented |
| Lifecycle | `Reevaluate` (instance) | 9: AuraMaster, BankLedger, ConsumableMaster, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat, WhatGroup | call 9 · name-only 11 · def 2 · stub 9 · test 12 | consumed (9) |
| Lifecycle | `Release` (instance) | none | call 0 · name-only 7 · def 2 · stub 17 · test 80 | zero — kept, documented |
| Lifecycle | `Set` (instance) | all 11 | call 18 · name-only 77 · def 10 · stub 29 · test 1851 | consumed (11) |
| Lifecycle | `name` (instance) | none | call 0 · name-only 232 · def 3 · stub 84 · test 5391 | zero — kept, documented |
| Lifecycle | `debug` (descriptor) | all 11 | call 11 | consumed (11) |
| Lifecycle | `name` (descriptor) | all 11 | call 11 | consumed (11) |
| Lifecycle | `print` (descriptor) | all 11 | call 11 | consumed (11) |
| Lifecycle | `standDown` (descriptor) | all 11 | call 11 | consumed (11) |
| Lifecycle | `standUp` (descriptor) | all 11 | call 11 | consumed (11) |
| Bus | `lib.Catalog` | 9: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced | call 10 · name-only 6 · def 1 · stub 7 · test 65 | consumed (9) |
| Bus | `lib.New` | 4: AbsorbTracker, ConsumableMaster, MultiMeters, PartyFrameEnhanced | call 4 · name-only 131 · def 16 · stub 16 · test 723 | consumed (4) |
| Bus | `NewTarget` (instance) | ConsumableMaster `core/Bus.lua:95`; PartyFrameEnhanced `core/Bus.lua:75` | call 2 · name-only 2 · stub 5 · test 8 | thin (2) |
| Bus | `StandDown` (instance) | ConsumableMaster `core/Bus.lua:107`; PartyFrameEnhanced `core/Bus.lua:78` | call 2 · name-only 18 · def 13 · stub 12 · test 64 | thin (2) |
| Bus | `StandUp` (instance) | ConsumableMaster `core/Bus.lua:115`; PartyFrameEnhanced `core/Bus.lua:84` | call 2 · name-only 21 · def 13 · stub 14 · test 52 | thin (2) |
| Bus | `isDown` (descriptor) | 4: AbsorbTracker, ConsumableMaster, MultiMeters, PartyFrameEnhanced | call 4 | consumed (4) |
| Bus | `name` (descriptor) | 4: AbsorbTracker, ConsumableMaster, MultiMeters, PartyFrameEnhanced | call 4 | consumed (4) |
| Schema | `lib.New` | all 11 | call 11 · name-only 124 · def 16 · stub 16 · test 723 | consumed (11) |
| Schema | `lib.Read` | 6: AbsorbTracker, AuraMaster, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced | call 9 · name-only 9 · def 8 · stub 7 · test 88 | consumed (6) |
| Schema | `lib.STRINGS` | none | call 0 · name-only 1 · stub 4 · test 147 | zero — kept, documented |
| Schema | `lib.SameValue` | AuraMaster `settings/Schema.lua:566`; BankLedger `settings/Schema.lua:716` | call 2 · name-only 9 · def 8 · stub 4 · test 16 | thin (2) |
| Schema | `lib.SplitPath` | AuraMaster `settings/Schema.lua:181`; KickCD `settings/Slash.lua:156`; MultiMeters `settings/Schema_Paths.lua:824` | call 3 · name-only 22 · def 10 · stub 6 · test 11 | consumed (3) |
| Schema | `lib.Write` | 5: AbsorbTracker, AuraMaster, KickCD, PanelMaster, PartyFrameEnhanced | call 6 · name-only 13 · def 9 · stub 4 · test 17 | consumed (5) |
| Schema | `AddRows` (instance) | 9: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 13 · name-only 4 · def 9 · stub 2 · test 16 | consumed (9) |
| Schema | `AllRows` (instance) | AbsorbTracker `settings/OptionsSetup.lua:98`; BankLedger `modules/Diagnostics.lua:102`; PrettyChat `settings/OptionsSetup.lua:285` | call 7 · name-only 6 · def 8 · stub 3 · test 23 | consumed (3) |
| Schema | `ApplyDefault` (instance) | 6: AbsorbTracker, BankLedger, KickCD, MultiMeters, PartyFrameEnhanced, PrettyChat | call 12 · name-only 21 · def 10 · stub 8 · test 101 | consumed (6) |
| Schema | `BulkAdd` (instance) | AuraMaster `settings/Schema.lua:586`; PrettyChat `settings/Schema.lua:1044` | call 2 · name-only 1 · def 8 · stub 2 · test 5 | thin (2) |
| Schema | `BulkBegin` (instance) | 8: AbsorbTracker, AuraMaster, BankLedger, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 15 · name-only 12 · def 8 · stub 4 · test 24 | consumed (8) |
| Schema | `BulkEnd` (instance) | 8: AbsorbTracker, AuraMaster, BankLedger, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 15 · name-only 12 · def 8 · stub 4 · test 31 | consumed (8) |
| Schema | `BulkRun` (instance) | 7: AbsorbTracker, AuraMaster, ConsumableMaster, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 9 · name-only 4 · def 8 · stub 6 · test 10 | consumed (7) |
| Schema | `ConsumeResetCount` (instance) | AbsorbTracker `settings/Schema.lua:453`; KickCD `core/Database.lua:622`; PartyFrameEnhanced `settings/Schema.lua:337` | call 3 · name-only 6 · def 8 · stub 2 · test 6 | consumed (3) |
| Schema | `CountOffDefault` (instance) | AbsorbTracker `settings/Schema.lua:447`; PartyFrameEnhanced `settings/Schema.lua:331`; PrettyChat `settings/Schema.lua:852` | call 3 · def 8 · stub 2 · test 4 | consumed (3) |
| Schema | `Default` (instance) | BankLedger `settings/Schema.lua:741`; PanelMaster `settings/Schema.lua:803` | call 2 · name-only 4 · def 8 · stub 2 · test 618 | thin (2) |
| Schema | `FindRow` (instance) | 9: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 28 · name-only 26 · def 8 · stub 8 · test 147 | consumed (9) |
| Schema | `Get` (instance) | 8: AbsorbTracker, BankLedger, ConsumableMaster, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 15 · name-only 127 · def 15 · stub 11 · test 836 | consumed (8) |
| Schema | `InBulk` (instance) | AuraMaster `settings/Schema.lua:548` | call 1 · name-only 1 · def 8 · stub 2 · test 15 | thin (1) |
| Schema | `Reindex` (instance) | AuraMaster `settings/Schema.lua:284` | call 1 · def 8 · stub 2 · test 13 | thin (1) |
| Schema | `ResetCounted` (instance) | AbsorbTracker `settings/Schema.lua:450`; KickCD `settings/OptionsSetup.lua:130`; PartyFrameEnhanced `settings/Schema.lua:334` | call 3 · name-only 3 · def 8 · stub 2 · test 4 | consumed (3) |
| Schema | `Set` (instance) | 8: AbsorbTracker, BankLedger, ConsumableMaster, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 21 · name-only 74 · def 10 · stub 29 · test 1851 | consumed (8) |
| Schema | `SetMany` (instance) | 4: ConsumableMaster, MultiMeters, PanelMaster, PrettyChat | call 4 · name-only 5 · def 8 · stub 5 · test 93 | consumed (4) |
| Schema | `Validate` (instance) | 6: AbsorbTracker, AuraMaster, BankLedger, KickCD, PanelMaster, PartyFrameEnhanced | call 6 · name-only 3 · def 9 · stub 2 · test 23 | consumed (6) |
| Schema | `L` (descriptor) | 4: BankLedger, LootHistory, MultiMeters, PanelMaster | call 4 | consumed (4) |
| Schema | `resetExempt` (descriptor) | 8: AbsorbTracker, BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, WhatGroup | call 8 | consumed (8) |
| Schema | `rows` (descriptor) | all 11 | call 11 | consumed (11) |
| Schema | `writeThrough` (descriptor) | 8: AbsorbTracker, AuraMaster, BankLedger, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced | call 8 | consumed (8) |
| Pool | `lib.Acquire` | 4: AuraMaster, BankLedger, LootHistory, MultiMeters | call 16 · name-only 9 · def 5 · test 39 | consumed (4) |
| Pool | `lib.AcquireKeyed` | KickCD `modules/IconGrid.lua:205` | call 1 · def 1 · test 2 | thin (1) |
| Pool | `lib.Counts` | LootHistory `modules/Diagnostics.lua:329` | call 2 · def 4 · test 33 | thin (1) |
| Pool | `lib.CountsKeyed` | KickCD `modules/Diagnostics.lua:183` | call 1 · def 1 · test 2 | thin (1) |
| Pool | `lib.New` | 4: AuraMaster, BankLedger, LootHistory, MultiMeters | call 31 · name-only 104 · def 16 · stub 16 · test 723 | consumed (4) |
| Pool | `lib.NewKeyed` | KickCD `modules/IconGrid.lua:107` | call 1 · def 1 · test 1 | thin (1) |
| Pool | `lib.ReleaseAll` | 4: AuraMaster, BankLedger, LootHistory, MultiMeters | call 15 · name-only 2 · def 5 · test 23 | consumed (4) |
| Pool | `lib.ReleaseAllKeyed` | KickCD `modules/IconGrid.lua:222` | call 1 · def 1 · test 1 | thin (1) |
| Item | `lib.ItemIDFromLink` | BankLedger `core/Compat.lua:100`; ConsumableMaster `settings/CategoryAddByID.lua:157`; LootHistory `core/Database.lua:354` | call 3 · def 3 · test 29 | consumed (3) |
| Item | `lib.LoadItem` | BankLedger `modules/Backfill.lua:158`; LootHistory `core/Database.lua:354` | call 3 · def 2 · test 19 | thin (2) |
| Item | `lib.QualityFromLink` | LootHistory `core/Compat.lua:171` | call 1 · def 2 · test 9 | thin (1) |
| Item | `lib.QualityLabel` | BankLedger `core/Constants.lua:198`; LootHistory `core/Constants.lua:166` | call 17 · def 2 · test 22 | thin (2) |
| Media | `lib.FONTS` | none | call 0 · test 29 | zero — kept, documented |
| Media | `lib.Font` | all 11 | call 11 · name-only 3 · def 1 · test 63 | consumed (11) |
| Media | `lib.ICONS` | none | call 0 · test 30 | zero — kept, documented |
| Media | `lib.Icon` | all 11 | call 11 · name-only 39 · def 11 · test 239 | consumed (11) |
| Media | `lib.RegisterLSM` | all 11 | call 11 · test 9 | consumed (11) |
| Media | `lib.TEXTURES` | none | call 0 · test 3 | zero — kept, documented |
| Media | `lib.Texture` | none | call 0 · name-only 2 · def 1 · test 40 | zero — kept, documented |
| Media | `lib.VENDOR_PATH` | none | call 0 · test 1 | zero — kept, documented |
| Widgets | `lib.ChartMath` | none | call 0 · test 1 | zero — kept, documented |
| Widgets | `lib.CloseMenu` | BankLedger `modules/Browser.lua:1118`; LootHistory `core/WidgetsSetup.lua:129`; MultiMeters `modules/Export_Modal.lua:850` | call 5 · name-only 4 · def 1 · test 22 | consumed (3) |
| Widgets | `lib.CopyWindow` | BankLedger `modules/Export.lua:281`; LootHistory `core/WidgetsSetup.lua:188`; MultiMeters `modules/Export_Modal.lua:364` | call 5 · name-only 2 · def 1 · test 9 | consumed (3) |
| Widgets | `lib.DRAG_HANDLE` | AbsorbTracker `modules/Bar.lua:180`; AuraMaster `modules/Anchors.lua:465`; KickCD `modules/Castbar_Handle.lua:120` | call 5 · test 7 | consumed (3) |
| Widgets | `lib.DragHandle` | 4: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD | call 9 · test 15 | consumed (4) |
| Widgets | `lib.Dropdown` | BankLedger `modules/Browser.lua:276`; LootHistory `core/WidgetsSetup.lua:103`; MultiMeters `modules/Export_Modal.lua:715` | call 3 · name-only 1 · test 133 | consumed (3) |
| Widgets | `lib.LINE_CHART` | none | call 0 · test 1 | zero — kept, documented |
| Widgets | `lib.LineChart` | LootHistory `core/WidgetsSetup.lua:208` | call 2 · test 3 | thin (1) |
| Widgets | `lib.ROW_BOX` | ConsumableMaster `settings/Category.lua:581`; KickCD `settings/Spells_Rows.lua:292`; LootHistory `core/WidgetsSetup.lua:167` | call 5 · test 11 | consumed (3) |
| Widgets | `lib.ReorderList` | ConsumableMaster `settings/Category.lua:80`; KickCD `settings/Spells.lua:596`; LootHistory `core/WidgetsSetup.lua:156` | call 10 · name-only 1 · test 40 | consumed (3) |
| Widgets | `addonName` (descriptor) | BankLedger `modules/Export.lua:283`; LootHistory `modules/Export.lua:388`; MultiMeters `modules/Export_Modal.lua:367` | call 3 | consumed (3) |
| Widgets | `anchorTo` (descriptor) | BankLedger `modules/Export.lua:290`; LootHistory `modules/Export.lua:396`; MultiMeters `modules/Export_Modal.lua:381` | call 3 | consumed (3) |
| Widgets | `applySkin` (descriptor) | BankLedger `modules/Export.lua:287`; LootHistory `modules/Export.lua:393`; MultiMeters `modules/Export_Modal.lua:375` | call 3 | consumed (3) |
| Widgets | `backdrop` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `editWidth` (descriptor) | MultiMeters `modules/Export_Modal.lua:374` | call 1 | thin (1) |
| Widgets | `font` (descriptor) | BankLedger `modules/Export.lua:286`; LootHistory `modules/Export.lua:391`; MultiMeters `modules/Export_Modal.lua:372` | call 3 | consumed (3) |
| Widgets | `fontSize` (descriptor) | LootHistory `modules/Export.lua:392`; MultiMeters `modules/Export_Modal.lua:373` | call 2 | thin (2) |
| Widgets | `height` (descriptor) | MultiMeters `modules/Export_Modal.lua:370` | call 1 | thin (1) |
| Widgets | `hoverXs` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `integer` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `makeCloseButton` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `markers` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `name` (descriptor) | BankLedger `modules/Export.lua:284`; LootHistory `modules/Export.lua:389`; MultiMeters `modules/Export_Modal.lua:368` | call 3 | consumed (3) |
| Widgets | `scrollName` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `series` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `title` (descriptor) | BankLedger `modules/Export.lua:285`; LootHistory `modules/Export.lua:390`; MultiMeters `modules/Export_Modal.lua:371` | call 3 | consumed (3) |
| Widgets | `width` (descriptor) | MultiMeters `modules/Export_Modal.lua:369` | call 1 | thin (1) |
| Widgets | `xMax` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `xMin` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `yMax` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `yMin` (descriptor) | none | call 0 | zero — kept, documented |
| DebugLog | `lib.AT_ENABLE_MAX` | none | call 0 | zero — kept, documented |
| DebugLog | `lib.BUFFER_SLACK` | none | call 0 · test 1 | zero — kept, documented |
| DebugLog | `lib.DIAG_MAX_LINES` | none | call 0 · test 1 | zero — kept, documented |
| DebugLog | `lib.DIAG_MAX_PER_LIST` | none | call 0 | zero — kept, documented |
| DebugLog | `lib.FormatColored` | ConsumableMaster `core/DebugLogSetup.lua:310` | call 1 · stub 6 · test 49 | thin (1) |
| DebugLog | `lib.FormatPlain` | ConsumableMaster `core/DebugLogSetup.lua:310` | call 1 · stub 8 · test 62 | thin (1) |
| DebugLog | `lib.GATE_MAX_KEYS` | none | call 0 | zero — kept, documented |
| DebugLog | `lib.MAX_BUFFER` | none | call 0 · test 8 | zero — kept, documented |
| DebugLog | `lib.MakeCloseButton` | none | call 0 · name-only 21 · def 11 · stub 19 · test 109 | zero — kept, documented |
| DebugLog | `lib.New` | all 11 | call 11 · name-only 124 · def 16 · stub 16 · test 723 | consumed (11) |
| DebugLog | `lib.STRINGS` | none | call 0 · name-only 1 · stub 4 · test 147 | zero — kept, documented |
| DebugLog | `lib.TIME_COPY` | none | call 0 | zero — kept, documented |
| DebugLog | `Add` (instance) | 9: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, PrettyChat | call 25 · name-only 5 · def 2 · stub 14 · test 169 | consumed (9) |
| DebugLog | `BufferSize` (instance) | none | call 0 · stub 9 · test 62 | zero — kept, documented |
| DebugLog | `BuildDiagnostics` (instance) | none | call 0 · stub 15 · test 31 | zero — kept, documented |
| DebugLog | `Clear` (instance) | ConsumableMaster `core/DebugLogSetup.lua:286` | call 1 · name-only 12 · def 2 · stub 11 · test 301 | thin (1) |
| DebugLog | `ConsoleCheckbox` (instance) | 4: AbsorbTracker, AuraMaster, PartyFrameEnhanced, WhatGroup | call 5 · stub 8 · test 31 | consumed (4) |
| DebugLog | `CopyText` (instance) | none | call 0 · stub 3 · test 22 | zero — kept, documented |
| DebugLog | `Debug` (instance) | all 11 | call 11 · name-only 602 · stub 40 · test 517 | consumed (11) |
| DebugLog | `DebugAtEnable` (instance) | all 11 | call 14 · name-only 14 · def 1 · stub 16 · test 9 | consumed (11) |
| DebugLog | `DebugChanged` (instance) | 8: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, LootHistory, PartyFrameEnhanced, PrettyChat, WhatGroup | call 16 · name-only 16 · def 1 · stub 12 · test 21 | consumed (8) |
| DebugLog | `DebugForget` (instance) | 7: AuraMaster, BankLedger, ConsumableMaster, KickCD, LootHistory, PartyFrameEnhanced, WhatGroup | call 10 · name-only 7 · def 1 · stub 12 · test 2 | consumed (7) |
| DebugLog | `DebugOnce` (instance) | 8: AbsorbTracker, AuraMaster, ConsumableMaster, LootHistory, PanelMaster, PartyFrameEnhanced, PrettyChat, WhatGroup | call 14 · name-only 22 · def 3 · stub 14 · test 42 | consumed (8) |
| DebugLog | `DebugVerb` (instance) | PanelMaster `settings/Slash.lua:415` | call 1 · stub 15 · test 28 | thin (1) |
| DebugLog | `FindLine` (instance) | none | call 0 · stub 9 · test 88 | zero — kept, documented |
| DebugLog | `Hide` (instance) | 7: BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PanelMaster, PrettyChat | call 9 · name-only 383 · def 9 · stub 14 · test 561 | consumed (7) |
| DebugLog | `IsEnabled` (instance) | AuraMaster `core/DebugLogSetup.lua:27`; ConsumableMaster `core/DebugLogSetup.lua:283`; PrettyChat `core/Util.lua:66` | call 3 · name-only 27 · def 3 · stub 12 · test 94 | consumed (3) |
| DebugLog | `IsShown` (instance) | 10: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 23 · name-only 77 · def 3 · stub 23 · test 908 | consumed (10) |
| DebugLog | `LastLine` (instance) | none | call 0 · stub 9 · test 50 | zero — kept, documented |
| DebugLog | `MakeCloseButton` (instance) | none | call 0 · name-only 21 · def 11 · stub 19 · test 109 | zero — kept, documented |
| DebugLog | `RefreshHeader` (instance) | ConsumableMaster `core/DebugLogSetup.lua:290` | call 1 · stub 11 · test 9 | thin (1) |
| DebugLog | `RunDiagnostics` (instance) | all 11 | call 17 · name-only 4 · stub 17 · test 68 | consumed (11) |
| DebugLog | `SetEnabled` (instance) | 9: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, LootHistory, MultiMeters, PartyFrameEnhanced, PrettyChat, WhatGroup | call 14 · name-only 16 · def 4 · stub 20 · test 335 | consumed (9) |
| DebugLog | `Show` (instance) | 10: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 27 · name-only 237 · def 5 · stub 13 · test 787 | consumed (10) |
| DebugLog | `ShowCopy` (instance) | ConsumableMaster `core/DebugLogSetup.lua:289` | call 1 · def 1 · stub 11 · test 16 | thin (1) |
| DebugLog | `Text` (instance) | none | call 0 · name-only 15 · stub 6 · test 209 | zero — kept, documented |
| DebugLog | `Toggle` (instance) | 10: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat, WhatGroup | call 12 · name-only 5 · def 7 · stub 12 · test 78 | consumed (10) |
| DebugLog | `UpdateScrollBar` (instance) | ConsumableMaster `core/DebugLogSetup.lua:291` | call 1 · stub 11 · test 20 | thin (1) |
| DebugLog | `UpdateStatus` (instance) | ConsumableMaster `core/DebugLogSetup.lua:292` | call 1 · stub 11 · test 15 | thin (1) |
| DebugLog | `buffer` (instance) | none | call 0 · stub 13 · test 479 | zero — kept, documented |
| DebugLog | `L` (descriptor) | 4: AbsorbTracker, AuraMaster, PartyFrameEnhanced, WhatGroup | call 4 | consumed (4) |
| DebugLog | `addonName` (descriptor) | all 11 | call 11 | consumed (11) |
| DebugLog | `applySkin` (descriptor) | BankLedger `core/DebugLogSetup.lua:142`; LootHistory `core/DebugLogSetup.lua:159` | call 2 | thin (2) |
| DebugLog | `brandName` (descriptor) | 10: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat, WhatGroup | call 10 | consumed (10) |
| DebugLog | `diagnostics` (descriptor) | all 11 | call 11 | consumed (11) |
| DebugLog | `diagnosticsEnablesLogging` (descriptor) | none | call 0 | zero — kept, documented |
| DebugLog | `font` (descriptor) | all 11 | call 11 | consumed (11) |
| DebugLog | `fontSize` (descriptor) | ConsumableMaster `core/DebugLogSetup.lua:189` | call 1 | thin (1) |
| DebugLog | `initSummary` (descriptor) | all 11 | call 11 | consumed (11) |
| DebugLog | `isEnabled` (descriptor) | all 11 | call 11 | consumed (11) |
| DebugLog | `makeCloseButton` (descriptor) | none | call 0 | zero — kept, documented |
| DebugLog | `name` (descriptor) | all 11 | call 11 | consumed (11) |
| DebugLog | `onClear` (descriptor) | AuraMaster `core/DebugLogSetup.lua:189`; ConsumableMaster `core/DebugLogSetup.lua:258`; MultiMeters `core/DebugLogSetup.lua:410` | call 3 | consumed (3) |
| DebugLog | `onVisibilityChanged` (descriptor) | all 11 | call 11 | consumed (11) |
| DebugLog | `print` (descriptor) | all 11 | call 11 | consumed (11) |
| DebugLog | `safeToString` (descriptor) | 8: AbsorbTracker, AuraMaster, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, PrettyChat, WhatGroup | call 8 | consumed (8) |
| DebugLog | `setEnabled` (descriptor) | all 11 | call 11 | consumed (11) |
| DebugLog | `skin` (descriptor) | none | call 0 | zero — kept, documented |
| DebugLog | `slash` (descriptor) | all 11 | call 11 | consumed (11) |
| DebugLog | `title` (descriptor) | all 11 | call 11 | consumed (11) |
| Slash | `lib.CommandRows` | ConsumableMaster `settings/Slash.lua:662`; KickCD `settings/Slash.lua:415` | call 2 · name-only 6 · stub 5 · test 13 | thin (2) |
| Slash | `lib.DISABLED_LINE_FORMAT` | LootHistory `settings/Slash.lua:208`; PanelMaster `settings/Slash.lua:705` | call 2 · stub 23 · test 47 | thin (2) |
| Slash | `lib.FindCommand` | ConsumableMaster `settings/Slash.lua:661`; KickCD `settings/Slash.lua:414` | call 2 · name-only 6 · stub 3 · test 12 | thin (2) |
| Slash | `lib.FormatKV` | 6: AbsorbTracker, AuraMaster, LootHistory, PanelMaster, PrettyChat, WhatGroup | call 6 · name-only 6 · stub 8 · test 47 | consumed (6) |
| Slash | `lib.FormatRow` | AbsorbTracker `settings/Slash.lua:43`; PartyFrameEnhanced `settings/Slash.lua:275` | call 2 · stub 5 · test 23 | thin (2) |
| Slash | `lib.FormatValue` | 9: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, LootHistory, MultiMeters, PartyFrameEnhanced, PrettyChat, WhatGroup | call 11 · name-only 9 · def 3 · stub 2 · test 21 | consumed (9) |
| Slash | `lib.LIVE_VERBS` | 9: AbsorbTracker, AuraMaster, BankLedger, KickCD, LootHistory, MultiMeters, PanelMaster, PrettyChat, WhatGroup | call 9 · stub 4 · test 36 | consumed (9) |
| Slash | `lib.New` | all 11 | call 11 · name-only 124 · def 16 · stub 16 · test 723 | consumed (11) |
| Slash | `lib.ParseBool` | ConsumableMaster `settings/Slash.lua:492`; MultiMeters `settings/Slash.lua:479` | call 2 · name-only 1 · def 1 · stub 1 · test 12 | thin (2) |
| Slash | `lib.ParseValue` | 5: AuraMaster, BankLedger, ConsumableMaster, KickCD, PanelMaster | call 5 · stub 6 · test 6 | consumed (5) |
| Slash | `lib.ProfileNames` | AbsorbTracker `settings/Slash.lua:527` | call 2 · test 2 | thin (1) |
| Slash | `lib.STRINGS` | LootHistory `settings/Slash.lua:226` | call 1 · stub 4 · test 147 | thin (1) |
| Slash | `lib.SplitVerb` | AbsorbTracker `settings/Slash.lua:374`; ConsumableMaster `settings/Slash.lua:660`; KickCD `settings/Slash.lua:413` | call 6 · name-only 8 · stub 5 · test 16 | consumed (3) |
| Slash | `BuildListLines` (instance) | BankLedger `settings/Slash.lua:455`; LootHistory `settings/Slash.lua:503`; PanelMaster `settings/Slash.lua:687` | call 3 · name-only 2 · def 1 · stub 5 · test 46 | consumed (3) |
| Slash | `CliGet` (instance) | all 11 | call 14 · name-only 3 · stub 5 · test 40 | consumed (11) |
| Slash | `CliList` (instance) | all 11 | call 11 · name-only 3 · stub 5 · test 13 | consumed (11) |
| Slash | `CliProfile` (instance) | all 11 | call 15 · name-only 3 · def 1 · stub 10 · test 48 | consumed (11) |
| Slash | `CliReset` (instance) | all 11 | call 11 · name-only 3 · stub 5 · test 39 | consumed (11) |
| Slash | `CliResetAll` (instance) | none | call 0 · name-only 6 · def 3 · stub 6 · test 64 | zero — deliberate host copy |
| Slash | `CliSet` (instance) | all 11 | call 14 · name-only 8 · stub 11 · test 99 | consumed (11) |
| Slash | `CliVersion` (instance) | 6: BankLedger, LootHistory, MultiMeters, PanelMaster, PrettyChat, WhatGroup | call 6 · name-only 3 · stub 7 · test 14 | consumed (6) |
| Slash | `DisabledLine` (instance) | 7: AbsorbTracker, AuraMaster, BankLedger, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced | call 8 · name-only 5 · def 1 · stub 22 · test 72 | consumed (7) |
| Slash | `HelpHeader` (instance) | LootHistory `settings/Slash.lua:501` | call 1 · stub 3 · test 19 | thin (1) |
| Slash | `HelpRows` (instance) | LootHistory `settings/Slash.lua:502`; MultiMeters `settings/Slash.lua:905`; PanelMaster `settings/Slash.lua:685` | call 3 · stub 10 · test 20 | consumed (3) |
| Slash | `LandingRows` (instance) | all 11 | call 11 · name-only 9 · stub 16 · test 37 | consumed (11) |
| Slash | `OnSlash` (instance) | all 11 | call 11 · name-only 15 · def 2 · stub 15 · test 480 | consumed (11) |
| Slash | `PrintHelp` (instance) | all 11 | call 12 · name-only 3 · stub 31 · test 31 | consumed (11) |
| Slash | `ProfileSwitch` (instance) | 6: AbsorbTracker, BankLedger, ConsumableMaster, LootHistory, PanelMaster, PartyFrameEnhanced | call 6 · def 1 · stub 12 · test 36 | consumed (6) |
| Slash | `SetRowAnnotator` (instance) | AbsorbTracker `settings/Slash.lua:791`; AuraMaster `settings/Slash.lua:589` | call 2 · stub 7 | thin (2) |
| Slash | `Text` (instance) | LootHistory `settings/Slash.lua:542`; PanelMaster `settings/Slash.lua:698`; PrettyChat `settings/Slash.lua:418` | call 3 · name-only 12 · stub 6 · test 209 | consumed (3) |
| Slash | `L` (descriptor) | 4: ConsumableMaster, KickCD, PanelMaster, WhatGroup | call 4 | consumed (4) |
| Slash | `aliases` (descriptor) | 6: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, MultiMeters, PartyFrameEnhanced | call 6 | consumed (6) |
| Slash | `allRows` (descriptor) | all 11 | call 11 | consumed (11) |
| Slash | `applyDefault` (descriptor) | all 11 | call 11 | consumed (11) |
| Slash | `brandName` (descriptor) | all 11 | call 11 | consumed (11) |
| Slash | `bulkBegin` (descriptor) | 5: AuraMaster, BankLedger, KickCD, LootHistory, MultiMeters | call 5 | consumed (5) |
| Slash | `bulkEnd` (descriptor) | 5: AuraMaster, BankLedger, KickCD, LootHistory, MultiMeters | call 5 | consumed (5) |
| Slash | `colorDecode` (descriptor) | AuraMaster `settings/Slash.lua:582`; ConsumableMaster `settings/Slash.lua:641` | call 2 | thin (2) |
| Slash | `colorEncode` (descriptor) | AuraMaster `settings/Slash.lua:583`; ConsumableMaster `settings/Slash.lua:642` | call 2 | thin (2) |
| Slash | `commands` (descriptor) | all 11 | call 11 | consumed (11) |
| Slash | `debug` (descriptor) | all 11 | call 11 | consumed (11) |
| Slash | `findRow` (descriptor) | all 11 | call 11 | consumed (11) |
| Slash | `format` (descriptor) | 6: AuraMaster, BankLedger, ConsumableMaster, LootHistory, MultiMeters, PrettyChat | call 6 | consumed (6) |
| Slash | `get` (descriptor) | all 11 | call 11 | consumed (11) |
| Slash | `groupKey` (descriptor) | all 11 | call 11 | consumed (11) |
| Slash | `isEnabled` (descriptor) | all 11 | call 11 | consumed (11) |
| Slash | `liveVerbs` (descriptor) | all 11 | call 11 | consumed (11) |
| Slash | `parse` (descriptor) | 7: AuraMaster, BankLedger, ConsumableMaster, KickCD, PanelMaster, PrettyChat, WhatGroup | call 7 | consumed (7) |
| Slash | `print` (descriptor) | all 11 | call 11 | consumed (11) |
| Slash | `profiles` (descriptor) | all 11 | call 11 | consumed (11) |
| Slash | `set` (descriptor) | all 11 | call 11 | consumed (11) |
| Slash | `slash` (descriptor) | all 11 | call 11 | consumed (11) |
| Slash | `slashAliases` (descriptor) | all 11 | call 11 | consumed (11) |
| Slash | `version` (descriptor) | all 11 | call 11 | consumed (11) |
| Launcher | `lib.New` | all 11 | call 11 · name-only 124 · def 16 · stub 16 · test 723 | consumed (11) |
| Launcher | `lib.STRINGS` | none | call 0 · name-only 1 · stub 4 · test 147 | zero — kept, documented |
| Launcher | `IsRegistered` (instance) | AbsorbTracker `modules/Diagnostics.lua:299`; PrettyChat `modules/Diagnostics.lua:257`; WhatGroup `modules/Diagnostics.lua:210` | call 3 · name-only 1 · stub 7 · test 51 | consumed (3) |
| Launcher | `IsShown` (instance) | AbsorbTracker `modules/Diagnostics.lua:299`; BankLedger `settings/Schema.lua:350`; WhatGroup `modules/Diagnostics.lua:211` | call 3 · name-only 97 · def 3 · stub 23 · test 908 | consumed (3) |
| Launcher | `Object` (instance) | none | call 0 · stub 7 · test 110 | zero — kept, documented |
| Launcher | `Register` (instance) | all 11 | call 11 · name-only 30 · def 15 · stub 18 · test 335 | consumed (11) |
| Launcher | `SetShown` (instance) | all 11 | call 11 · name-only 57 · stub 16 · test 59 | consumed (11) |
| Launcher | `L` (descriptor) | none | call 0 | zero — kept, documented |
| Launcher | `debug` (descriptor) | all 11 | call 11 | consumed (11) |
| Launcher | `debugAtEnable` (descriptor) | all 11 | call 11 | consumed (11) |
| Launcher | `icon` (descriptor) | all 11 | call 11 | consumed (11) |
| Launcher | `isEnabled` (descriptor) | all 11 | call 11 | consumed (11) |
| Launcher | `isLocked` (descriptor) | 10: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, WhatGroup | call 10 | consumed (10) |
| Launcher | `isTestMode` (descriptor) | 5: AuraMaster, BankLedger, LootHistory, MultiMeters, WhatGroup | call 5 | consumed (5) |
| Launcher | `label` (descriptor) | all 11 | call 11 | consumed (11) |
| Launcher | `minimap` (descriptor) | all 11 | call 11 | consumed (11) |
| Launcher | `name` (descriptor) | all 11 | call 11 | consumed (11) |
| Launcher | `onTooltipShow` (descriptor) | BankLedger `core/LauncherSetup.lua:221`; LootHistory `core/LauncherSetup.lua:159` | call 2 | thin (2) |
| Launcher | `openSettings` (descriptor) | all 11 | call 11 | consumed (11) |
| Launcher | `print` (descriptor) | all 11 | call 11 | consumed (11) |
| Launcher | `setEnabled` (descriptor) | all 11 | call 11 | consumed (11) |
| Launcher | `version` (descriptor) | all 11 | call 11 | consumed (11) |
| Options | `lib.LAYOUT` | none | call 0 · name-only 7 · test 86 | zero — kept, documented |
| Options | `lib.New` | all 11 | call 11 · name-only 124 · def 16 · stub 16 · test 723 | consumed (11) |
| Options | `lib.PatchAlwaysShowScrollbar` | none | call 0 · stub 8 · test 20 | zero — kept, documented |
| Options | `lib.STRINGS` | none | call 0 · name-only 1 · stub 4 · test 147 | zero — kept, documented |
| Options | `AceGUI` (instance) | 4: BankLedger, KickCD, PanelMaster, WhatGroup | call 19 · name-only 41 · stub 12 · test 589 | consumed (4) |
| Options | `AddSpacer` (instance) | 9: AuraMaster, BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PanelMaster, PrettyChat, WhatGroup | call 42 · name-only 13 · stub 11 · test 11 | consumed (9) |
| Options | `AttachTooltip` (instance) | 8: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, MultiMeters, PanelMaster, PrettyChat, WhatGroup | call 29 · name-only 5 · stub 10 · test 18 | consumed (8) |
| Options | `BANNER_H` (instance) | AbsorbTracker `settings/UnitPanel.lua:126`; PanelMaster `settings/PanelEditor.lua:482` | call 5 · stub 5 · test 18 | thin (2) |
| Options | `BUTTON_PAIR_REL` (instance) | AuraMaster `settings/GeneralSpells.lua:602`; LootHistory `settings/Panel.lua:37`; PanelMaster `settings/Panel.lua:59` | call 7 · name-only 3 · stub 6 · test 27 | consumed (3) |
| Options | `BarGroup` (instance) | 5: AbsorbTracker, AuraMaster, KickCD, PanelMaster, PartyFrameEnhanced | call 7 · stub 8 · test 17 | consumed (5) |
| Options | `BorderGroup` (instance) | 5: AbsorbTracker, AuraMaster, KickCD, PanelMaster, PartyFrameEnhanced | call 11 · name-only 2 · def 1 · stub 8 · test 17 | consumed (5) |
| Options | `BuildLandingPage` (instance) | 4: AbsorbTracker, AuraMaster, PartyFrameEnhanced, PrettyChat | call 4 · name-only 2 · stub 3 · test 11 | consumed (4) |
| Options | `CHROME_GAP` (instance) | none | call 0 · stub 6 · test 14 | zero — kept, documented |
| Options | `CLASS_COLOR_NOTE` (instance) | AuraMaster `settings/Bars.lua:96`; PanelMaster `settings/PanelEditor.lua:359` | call 3 · name-only 1 · stub 3 · test 19 | thin (2) |
| Options | `ChoiceGrid` (instance) | AuraMaster `settings/Filters.lua:634` | call 2 · stub 12 · test 3 | thin (1) |
| Options | `ClearScroll` (instance) | all 11 | call 21 · stub 13 · test 55 | consumed (11) |
| Options | `ColorPair` (instance) | 4: AbsorbTracker, AuraMaster, KickCD, PartyFrameEnhanced | call 10 · name-only 4 · def 1 · stub 8 · test 13 | consumed (4) |
| Options | `CreateOptionsPanel` (instance) | all 11 | call 11 · name-only 5 · stub 20 · test 45 | consumed (11) |
| Options | `CreatePanel` (instance) | all 11 | call 36 · name-only 6 · def 1 · stub 12 · test 88 | consumed (11) |
| Options | `EnsureDefaultsButton` (instance) | WhatGroup `settings/OptionsSetup.lua:286` | call 1 · def 1 · stub 10 · test 21 | thin (1) |
| Options | `EnsureScroll` (instance) | 10: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PanelMaster, PrettyChat, WhatGroup | call 38 · name-only 6 · def 1 · stub 18 · test 22 | consumed (10) |
| Options | `FONT_FLAGS` (instance) | none | call 0 · stub 4 · test 11 | zero — deliberate host copy |
| Options | `FONT_FLAGS_SORT` (instance) | none | call 0 · stub 3 · test 9 | zero — deliberate host copy |
| Options | `FontGroup` (instance) | 4: AbsorbTracker, AuraMaster, KickCD, PartyFrameEnhanced | call 9 · name-only 1 · def 1 · stub 8 · test 12 | consumed (4) |
| Options | `ID_NAME_HINT` (instance) | none | call 0 · stub 14 · test 3 | zero — kept, documented |
| Options | `IdInput` (instance) | KickCD `settings/Spells_Header.lua:228` | call 1 · name-only 1 · stub 12 · test 18 | thin (1) |
| Options | `IdList` (instance) | AuraMaster `settings/Filters.lua:809`; BankLedger `settings/Panel.lua:386`; LootHistory `settings/Panel.lua:336` | call 4 · stub 15 · test 58 | consumed (3) |
| Options | `InlineButtonPair` (instance) | 4: AuraMaster, BankLedger, MultiMeters, PanelMaster | call 9 · def 1 · stub 11 · test 9 | consumed (4) |
| Options | `LSMValues` (instance) | AbsorbTracker `settings/Appearance.lua:188`; MultiMeters `settings/Schema_Compose.lua:394` | call 2 · name-only 1 · def 1 · stub 8 · test 36 | thin (2) |
| Options | `MASTER_GROUP` (instance) | 7: AbsorbTracker, AuraMaster, KickCD, LootHistory, PartyFrameEnhanced, PrettyChat, WhatGroup | call 8 · name-only 1 · stub 9 · test 31 | consumed (7) |
| Options | `MasterControls` (instance) | 6: AbsorbTracker, AuraMaster, KickCD, LootHistory, PartyFrameEnhanced, WhatGroup | call 6 · name-only 6 · def 1 · stub 16 · test 44 | consumed (6) |
| Options | `NavRail` (instance) | AuraMaster `settings/OptionsSetup.lua:612`; KickCD `settings/Panel_Render.lua:346`; MultiMeters `settings/OptionsSetup.lua:610` | call 3 · stub 18 · test 20 | consumed (3) |
| Options | `OpenOptionsPanel` (instance) | 10: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 13 · name-only 13 · stub 12 · test 145 | consumed (10) |
| Options | `PADDING_X` (instance) | PanelMaster `settings/Panel.lua:514` | call 2 · stub 2 · test 24 | thin (1) |
| Options | `PageBanner` (instance) | AuraMaster `settings/OptionsSetup.lua:448`; KickCD `settings/Panel_Render.lua:113`; MultiMeters `settings/Windows.lua:224` | call 4 · name-only 1 · stub 12 · test 33 | consumed (3) |
| Options | `PageHeader` (instance) | AbsorbTracker `settings/UnitPanel.lua:269`; KickCD `settings/Spells.lua:672`; PanelMaster `settings/PanelEditor.lua:472` | call 4 · stub 14 · test 20 | consumed (3) |
| Options | `PatchAlwaysShowScrollbar` (instance) | none | call 0 · stub 8 · test 20 | zero — kept, documented |
| Options | `ROW_VSPACER` (instance) | 6: AbsorbTracker, AuraMaster, BankLedger, PanelMaster, PrettyChat, WhatGroup | call 10 · stub 7 · test 35 | consumed (6) |
| Options | `RefreshAllPanels` (instance) | 7: AbsorbTracker, AuraMaster, BankLedger, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced | call 22 · name-only 12 · def 1 · stub 10 · test 129 | consumed (7) |
| Options | `RefreshPanel` (instance) | 8: AuraMaster, BankLedger, KickCD, LootHistory, MultiMeters, PanelMaster, PrettyChat, WhatGroup | call 23 · name-only 2 · stub 8 · test 24 | consumed (8) |
| Options | `RefreshScalars` (instance) | 7: AuraMaster, BankLedger, KickCD, LootHistory, MultiMeters, PrettyChat, WhatGroup | call 13 · name-only 3 · def 1 · stub 9 · test 29 | consumed (7) |
| Options | `RegisterOptionsPage` (instance) | all 11 | call 19 · name-only 33 · def 3 · stub 13 · test 15 | consumed (11) |
| Options | `RenderField` (instance) | PanelMaster `settings/Panel.lua:160`; PrettyChat `settings/Panel.lua:446` | call 4 · def 1 · stub 10 · test 32 | thin (2) |
| Options | `RenderGrid` (instance) | 4: AuraMaster, ConsumableMaster, KickCD, MultiMeters | call 16 · stub 10 · test 20 | consumed (4) |
| Options | `RenderRows` (instance) | 4: AuraMaster, KickCD, LootHistory, MultiMeters | call 16 · name-only 1 · stub 10 · test 46 | consumed (4) |
| Options | `RenderSchema` (instance) | none | call 0 · stub 13 · test 24 | zero — kept, documented |
| Options | `RenderTabbedSchema` (instance) | 9: AbsorbTracker, AuraMaster, BankLedger, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat, WhatGroup | call 13 · name-only 1 · stub 18 · test 46 | consumed (9) |
| Options | `ResolveId` (instance) | AuraMaster `settings/GeneralSpells.lua:725` | call 1 · name-only 1 · stub 14 · test 8 | thin (1) |
| Options | `RestoreAllDefaults` (instance) | 7: AbsorbTracker, AuraMaster, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, WhatGroup | call 16 · name-only 2 · def 1 · stub 12 · test 137 | consumed (7) |
| Options | `RestoreDefaults` (instance) | 5: AbsorbTracker, AuraMaster, KickCD, MultiMeters, PartyFrameEnhanced | call 10 · name-only 3 · def 3 · stub 8 · test 145 | consumed (5) |
| Options | `SECTION_HEADING_H` (instance) | BankLedger `settings/Panel.lua:528`; LootHistory `settings/Panel.lua:903`; PanelMaster `settings/Panel.lua:58` | call 3 · name-only 2 · stub 6 · test 21 | consumed (3) |
| Options | `Section` (instance) | 4: AuraMaster, ConsumableMaster, MultiMeters, WhatGroup | call 15 · name-only 4 · def 1 · stub 10 · test 34 | consumed (4) |
| Options | `SelectTab` (instance) | AuraMaster `settings/Filters.lua:362`; KickCD `settings/Panel_Render.lua:404`; MultiMeters `settings/OptionsSetup.lua:660` | call 4 · name-only 6 · def 5 · stub 18 · test 31 | consumed (3) |
| Options | `SessionCheckbox` (instance) | ConsumableMaster `settings/Panel.lua:702`; KickCD `settings/Panel_Widgets.lua:43` | call 2 · stub 10 · test 18 | thin (2) |
| Options | `SetChromeHeight` (instance) | none | call 0 · stub 12 · test 3 | zero — kept, documented |
| Options | `SetRenderer` (instance) | 10: AbsorbTracker, AuraMaster, BankLedger, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat, WhatGroup | call 29 · name-only 6 · def 1 · stub 13 · test 39 | consumed (10) |
| Options | `SubTabStrip` (instance) | BankLedger `settings/Panel.lua:451`; LootHistory `settings/Panel.lua:465` | call 2 · stub 10 · test 5 | thin (2) |
| Options | `TAB_H` (instance) | none | call 0 · stub 5 · test 16 | zero — kept, documented |
| Options | `TabStrip` (instance) | 5: KickCD, LootHistory, MultiMeters, PanelMaster, PrettyChat | call 8 · name-only 3 · stub 15 · test 67 | consumed (5) |
| Options | `TextRow` (instance) | 4: AuraMaster, BankLedger, MultiMeters, PrettyChat | call 41 · stub 5 · test 20 | consumed (4) |
| Options | `UnnamedCandidates` (instance) | none | call 0 · stub 13 · test 1 | zero — kept, documented |
| Options | `VISIBILITY_SORT` (instance) | none | call 0 · stub 3 · test 9 | zero — deliberate host copy |
| Options | `VISIBILITY_VALUES` (instance) | none | call 0 · stub 3 · test 9 | zero — deliberate host copy |
| Options | `addonName` (descriptor) | all 11 | call 11 | consumed (11) |
| Options | `afterRestoreAll` (descriptor) | none | call 0 | zero — kept, documented |
| Options | `allRows` (descriptor) | 10: AbsorbTracker, AuraMaster, BankLedger, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat, WhatGroup | call 10 | consumed (10) |
| Options | `applyDefault` (descriptor) | 10: AbsorbTracker, AuraMaster, BankLedger, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat, WhatGroup | call 10 | consumed (10) |
| Options | `buildMain` (descriptor) | all 11 | call 11 | consumed (11) |
| Options | `bulkBegin` (descriptor) | 9: AbsorbTracker, AuraMaster, BankLedger, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, WhatGroup | call 9 | consumed (9) |
| Options | `bulkEnd` (descriptor) | 9: AbsorbTracker, AuraMaster, BankLedger, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, WhatGroup | call 9 | consumed (9) |
| Options | `colorDecode` (descriptor) | 6: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, MultiMeters, PartyFrameEnhanced | call 6 | consumed (6) |
| Options | `colorEncode` (descriptor) | 6: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, MultiMeters, PartyFrameEnhanced | call 6 | consumed (6) |
| Options | `debug` (descriptor) | all 11 | call 11 | consumed (11) |
| Options | `get` (descriptor) | all 11 | call 11 | consumed (11) |
| Options | `getLSM` (descriptor) | 6: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, MultiMeters, PartyFrameEnhanced | call 6 | consumed (6) |
| Options | `mainPanelName` (descriptor) | all 11 | call 11 | consumed (11) |
| Options | `onAceGUI` (descriptor) | 7: AbsorbTracker, AuraMaster, BankLedger, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced | call 7 | consumed (7) |
| Options | `parentTitle` (descriptor) | all 11 | call 11 | consumed (11) |
| Options | `print` (descriptor) | all 11 | call 11 | consumed (11) |
| Options | `resetProfile` (descriptor) | all 11 | call 11 | consumed (11) |
| Options | `rowsForPage` (descriptor) | all 11 | call 11 | consumed (11) |
| Options | `scheduleTimer` (descriptor) | 8: AbsorbTracker, AuraMaster, BankLedger, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced | call 8 | consumed (8) |
| Options | `set` (descriptor) | all 11 | call 11 | consumed (11) |
| Options | `skipRestoreAll` (descriptor) | 10: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, PrettyChat, WhatGroup | call 10 | consumed (10) |
| Options | `sliderCommit` (descriptor) | ConsumableMaster `settings/OptionsSetup.lua:271` | call 1 | thin (1) |
| Options | `validate` (descriptor) | 9: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced, WhatGroup | call 9 | consumed (9) |
| Perf | `lib.DEFAULT_RING` | none | call 0 · test 2 | zero — kept, documented |
| Perf | `lib.EncodeJSON` | none | call 0 · test 12 | zero — kept, documented |
| Perf | `lib.New` | 7: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced | call 7 · name-only 128 · def 16 · stub 16 · test 723 | consumed (7) |
| Perf | `lib.SCHEMA` | none | call 0 · stub 1 · test 24 | zero — kept, documented |
| Perf | `lib.STRINGS` | none | call 0 · name-only 1 · stub 4 · test 147 | zero — kept, documented |
| Perf | `Announce` (instance) | none | call 0 · name-only 3 · def 1 · test 4 | zero — kept, documented |
| Perf | `BuildRecord` (instance) | none | call 0 · name-only 1 · def 1 · test 14 | zero — kept, documented |
| Perf | `Cancel` (instance) | none | call 0 · name-only 24 · test 30 | zero — kept, documented |
| Perf | `Close` (instance) | none | call 0 · name-only 4 · def 1 · stub 2 · test 62 | zero — kept, documented |
| Perf | `Context` (instance) | none | call 0 · name-only 10 · test 6 | zero — kept, documented |
| Perf | `ContextLines` (instance) | none | call 0 | zero — kept, documented |
| Perf | `EXPERIMENTS` (instance) | none | call 0 | zero — kept, documented |
| Perf | `EncodeJSON` (instance) | none | call 0 · test 12 | zero — kept, documented |
| Perf | `FormatReport` (instance) | none | call 0 · test 3 | zero — kept, documented |
| Perf | `HidePanel` (instance) | none | call 0 · test 17 | zero — kept, documented |
| Perf | `IsPanelShown` (instance) | none | call 0 · test 6 | zero — kept, documented |
| Perf | `LABELS` (instance) | none | call 0 · test 10 | zero — kept, documented |
| Perf | `Log` (instance) | none | call 0 · test 4 | zero — kept, documented |
| Perf | `MarkReviewed` (instance) | none | call 0 · test 1 | zero — kept, documented |
| Perf | `Measure` (instance) | none | call 0 · name-only 1 · test 6 | zero — kept, documented |
| Perf | `Note` (instance) | 7: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced | call 63 · name-only 9 · def 2 · stub 9 · test 117 | consumed (7) |
| Perf | `OnCommand` (instance) | 7: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced | call 9 · def 1 · stub 10 · test 26 | consumed (7) |
| Perf | `Open` (instance) | none | call 0 · name-only 25 · def 7 · stub 3 · test 209 | zero — kept, documented |
| Perf | `PanelIsActionable` (instance) | none | call 0 | zero — kept, documented |
| Perf | `PanelStateOf` (instance) | none | call 0 · test 2 | zero — kept, documented |
| Perf | `Progress` (instance) | none | call 0 | zero — kept, documented |
| Perf | `RefreshPanel` (instance) | none | call 0 · name-only 25 · stub 8 · test 24 | zero — kept, documented |
| Perf | `Reset` (instance) | none | call 0 · name-only 4 · def 3 · stub 8 · test 373 | zero — kept, documented |
| Perf | `Resume` (instance) | none | call 0 · name-only 8 · def 14 · test 70 | zero — kept, documented |
| Perf | `SCHEMA` (instance) | none | call 0 · stub 1 · test 24 | zero — kept, documented |
| Perf | `STEPS` (instance) | none | call 0 · test 13 | zero — kept, documented |
| Perf | `Save` (instance) | none | call 0 · name-only 1 · def 1 · test 20 | zero — kept, documented |
| Perf | `ShowPanel` (instance) | none | call 0 · test 5 | zero — kept, documented |
| Perf | `Start` (instance) | none | call 0 · name-only 4 · def 2 · test 77 | zero — kept, documented |
| Perf | `StatusLines` (instance) | none | call 0 · test 1 | zero — kept, documented |
| Perf | `Stop` (instance) | none | call 0 · name-only 21 · def 5 · test 32 | zero — kept, documented |
| Perf | `Suspend` (instance) | none | call 0 · name-only 4 · def 15 · test 93 | zero — kept, documented |
| Perf | `TogglePanel` (instance) | none | call 0 | zero — kept, documented |
| Perf | `Usage` (instance) | none | call 0 · test 46 | zero — kept, documented |
| Perf | `armed` (instance) | ConsumableMaster `core/Diagnostics.lua:137` | call 1 · name-only 5 · def 1 · stub 1 · test 378 | thin (1) |
| Perf | `context` (instance) | none | call 0 · name-only 2 · def 1 · test 167 | zero — kept, documented |
| Perf | `descriptor` (instance) | none | call 0 · stub 10 · test 733 | zero — kept, documented |
| Perf | `label` (instance) | ConsumableMaster `core/Diagnostics.lua:137` | call 1 · name-only 275 · stub 10 · test 1972 | thin (1) |
| Perf | `name` (instance) | none | call 0 · name-only 232 · def 3 · stub 84 · test 5391 | zero — kept, documented |
| Perf | `on` (instance) | 7: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced | call 59 · name-only 3 · def 1 · stub 264 · test 7913 | consumed (7) |
| Perf | `recording` (instance) | ConsumableMaster `core/Diagnostics.lua:137` | call 1 · stub 3 · test 130 | thin (1) |
| Perf | `ringMax` (instance) | none | call 0 | zero — kept, documented |
| Perf | `run` (instance) | ConsumableMaster `core/Diagnostics.lua:137` | call 1 · name-only 7 · def 6 · stub 14 · test 1147 | thin (1) |
| Perf | `slash` (instance) | none | call 0 · stub 63 · test 1216 | zero — kept, documented |
| Perf | `title` (instance) | none | call 0 · name-only 37 · def 2 · stub 2 · test 380 | zero — kept, documented |
| Perf | `L` (descriptor) | none | call 0 | zero — kept, documented |
| Perf | `addonName` (descriptor) | 7: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced | call 7 | consumed (7) |
| Perf | `buckets` (descriptor) | 7: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced | call 7 | consumed (7) |
| Perf | `decorate` (descriptor) | none | call 0 | zero — kept, documented |
| Perf | `lifecycle` (descriptor) | 7: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced | call 7 | consumed (7) |
| Perf | `log` (descriptor) | 7: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced | call 7 | consumed (7) |
| Perf | `name` (descriptor) | 7: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced | call 7 | consumed (7) |
| Perf | `onChange` (descriptor) | none | call 0 | zero — kept, documented |
| Perf | `print` (descriptor) | 7: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced | call 7 | consumed (7) |
| Perf | `ring` (descriptor) | none | call 0 | zero — kept, documented |
| Perf | `showLog` (descriptor) | 7: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced | call 7 | consumed (7) |
| Perf | `slash` (descriptor) | 7: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced | call 7 | consumed (7) |
| Perf | `sv` (descriptor) | 7: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced | call 7 | consumed (7) |
| Perf | `title` (descriptor) | 7: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced | call 7 | consumed (7) |
| Perf | `version` (descriptor) | 7: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced | call 7 | consumed (7) |

## Re-running it

From this repo's root, with every addon checked out as a sibling:

```sh
/home/tushar/.claude/dev-copilot/bin/ka0s-bounded \
  lua ../Ka0sAddonsCommonTasks/docs/2026-10-02-LIBKA0S_CENSUS_ADOPTION/plan-data/census.lua \
      .. ../Ka0sAddonsCommonTasks/docs/2026-10-02-LIBKA0S_CENSUS_ADOPTION/plan-data/census-v1.69.0
```

The scan takes about three minutes. Then read every export whose verdict moved, and update
`verdicts.tsv` and this page together. The tool classifies hits, but only reading the code settles
a verdict.
