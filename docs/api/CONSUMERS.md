# Who calls what: the LibKa0s consumer census

**Stamped v1.75.0** (tag `v1.75.0`, local, at `9e5c4e2`), re-measured 2026-10-23 across the
fourteen addons in `WowAddonStandards/standards/ADDONS.md`, each on its
`feat/2026-10-22-libka0s-issues-45-58` branch with v1.75.0 vendored, after every adoption of the
LibKa0s issues #45-#58 run had landed. That run is item `LK-23` of
`Ka0sAddonsCommonTasks/docs/2026-10-22-LIBKA0S_ISSUES_45_58`. The three Sim hosts carry the tag's
final payload through their `*-RV3` refresh and the other eleven through addendum 03's `*-RV2`.
Three addons are new to the census since v1.71.0: Ka0s Drop Watcher, Ka0s Premade Groups Filter
Extension and Ka0s Quick Comms joined the roster after it, and v1.72.0 to v1.74.0 were never
measured, so this run is also their first. The v1.71.0 run was taken on 2026-10-07 across the
eleven addons of that day, the v1.70.0 run earlier the same day and the v1.69.0 run on 2026-10-06,
the same way. The v1.67.0 run was taken on the same branch with v1.67.0 vendored, by item
`CA-LK-04` of `Ka0sAddonsCommonTasks/docs/2026-10-02-LIBKA0S_CENSUS_ADOPTION`, after the nine
issues the first run filed were fixed. The first run was taken at v1.66.0 for
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

501 public exports across seventeen majors: 118 lib-level members, 221 instance members and 162
descriptor fields. Nine of them are new at v1.77.0 and not yet measured (see
[What moved since v1.66.0](#what-moved-since-v1660)); the other 492 are the v1.75.0 census.

| Verdict | Exports | Meaning |
|---|---|---|
| consumed | 287 | Called, or passed, by three or more hosts |
| thin | 82 | One or two hosts. A misfit found by the next host is a library gap on first contact |
| **zero** | **132** | No host calls it. Each one is split below |

Fifteen of the 492 verdicts were set by reading the code where the scan could not see, or saw
wrong; each is marked *read by hand* in its row and explained under [Method](#method), step 5.

The 132 zero-consumer exports:

| Split | Exports | What happens |
|---|---|---|
| host duplicate | 0 | None at v1.75.0. Widgets `lib.Autocomplete`, the one at the v1.70.0 tag, has been thin (2) since v1.71.0: LootHistory and BankLedger both adopted it, and LootHistory's Timeline no longer hand-rolls its own list. None of the eight from v1.66.0 is left either: seven were adopted, and Options `lib.LAYOUT` left the split when KickCD deleted its two header copies instead of reading them; it is now documented (see [What moved since v1.66.0](#what-moved-since-v1660)) |
| suspect shape | 0 | Both from v1.66.0 were settled at v1.67.0: Core 10 gave `MakeResizable` its lock gate ([#41](https://github.com/tusharsaxena/LibKa0s/issues/41)), and every host now passes the Options descriptor's `addonName` ([#42](https://github.com/tusharsaxena/LibKa0s/issues/42)) |
| deliberate host copy | 5 | A host keeps its own copy on purpose, with the reason recorded beside it. Listed, not re-opened |
| documented | 118 | No duplicate and no host waiting for it. Each gets a "no consumer as of vX, kept because ..." line in its major's live document, stamped with the census that first recorded it: v1.67.0 for the earlier ones, v1.69.0 for the line-chart exports, v1.70.0 for `lib.AUTOCOMPLETE`, v1.75.0 for the sixteen Sim exports |
| planned at v1.77.0 | 9 | New at v1.77.0, with named adopters in M2 (eight) or M3 (`ResetAllTooltip`, seven adopters) of Ka0sAddonsCommonTasks `docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`; not measured. Each moves to its measured verdict when the census is re-run |

Most of the 118 fall into four groups. The rows below give each export's own reason.

- **Reached through the library's own code, never by name.** Examples: the Perf instance methods
  that the `/x perf` verbs dispatch to through `OnCommand`, and the Sim step controls (`Run`,
  `Pause`, `Resume`, `Restart`) that the `/x sim` verbs dispatch to through `RunVerb`; the Media
  catalogs that `Font` / `Icon` / `Texture` read; `Lifecycle` `Hold` / `Release` behind `Set`;
  Options' `SetChromeHeight` behind the chrome makers; the six fields of the Sim-private step-panel
  renderer's descriptor, which only `SimPanel.lua`'s own adapter fills.
- **Read by host tests only.** For example DebugLog's `buffer`, `FindLine`, `LastLine`, `BufferSize`,
  `CopyText` and `BuildDiagnostics`, and Sim's `seam:Unwrapped()`, which every Sim host's suite
  asserts empty. Hundreds of test lines read them, and no production line does. The census does
  not count a test as a consumer.
- **Tuning constants published so the number is cited rather than restated.** For example
  `MAX_BUFFER`, `BUFFER_SLACK`, `DIAG_MAX_LINES` and `DEFAULT_RING`.
- **Opt-in overrides every host leaves at the default.** For example DebugLog's `skin` and
  `makeCloseButton`, Perf's `decorate`, `ring`, `onChange` and `L`, and Launcher's `L`.

## What moved since v1.66.0

**v1.78.0, not in the census (2026-10-25).** The release adds a major, `LibKa0s-Skin-1.0`
(its members in `docs/api/Skin/members-4.7.4.1.2.1.1.json`), the Options instance members
`AppearanceTab` and `AppearanceRows` with the lib-level `APPEARANCE_STRINGS` (OptionsAppearance minor
1), Skin's `Skin:OwnerLabel` and `Skin:WriteChoice`, an `owner` option on every Widgets constructor,
`ApplySkin`'s `owner` (Core minor 13), the media pickers' `fromSkin` (OptionsCompose minor 12), the
`skinValue` row field (OptionsWidgets minor 35), `series[i].colorIndex` (WidgetsLineChart minor 4) and
the Media catalogs `BORDERS` / `BACKGROUNDS` with their readers (Media minor 6). None gets a row
here yet, and the v1.75.0 stamp and its numbers stand: in leg 1 of Ka0sAddonsCommonTasks
`docs/2026-10-25-SKINNING/` only LootHistory re-vendors and adopts (its `LH-*` items), and the other
consumers adopt at leg 2, whose census re-run measures them all at once.

**v1.77.0 rows, planned and not measured (2026-10-24).** Eight rows are added without a re-run, and
the v1.75.0 stamp stands: Options `KeybindingsTab`, `KeybindRows` and `KEYBINDS_UNCHANGED`
(OptionsKeybinds minor 2) and `StrataTooltip` (OptionsCompose minor 8), all instance members;
Core `lib.RaiseStaticPopups` (Core minor 12), which the library's own three tool windows call; and
the `DragHandle` spec fields `level` and `ignoreParentAlpha` with the handle method `ApplyLevel`
(WidgetsDragHandle minor 5). Their adopters are planned, not measured: each row's verdict is
*zero — planned at v1.77.0* until the adopting items of that run's M2 land and the census is
re-run, which sets the measured verdict. `lib.KEYBIND_STRINGS` (OptionsKeybinds minor 1), the one
other public name v1.77.0 adds, gets no row until that re-run, since no adopter reads it by name
(a host passes `spec.strings`).

**v1.77.0's settings-layout extension, planned and not measured (2026-10-24).** One row is added the
same way, Options `ResetAllTooltip` (OptionsCompose minor 11, an instance member), with its adopters
in M3 of Ka0sAddonsCommonTasks `docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`: the seven General pages
whose header Defaults is the global reset (BankLedger, DropWatcher, LootHistory,
PremadeGroupsFilterExtension, PrettyChat, QuickComms and WhatGroup). The row first named MultiMeters
as an eighth, but its General Defaults is a page reset and does not adopt it; the row was corrected
from each addon's master on 2026-10-24. The rest of that extension is new fields on
existing exports, so it amends rows rather than adding them: `MasterControls` gains `notes`,
`resetPositionTooltip` and `lockIsPreview` (OptionsCompose minor 9) with the *Master opacity* label
and the frameless packing, and `BarGroup`, `FontGroup`, `BorderGroup` and `ColorPair` gain
`tooltips` (minor 10). Each amended row keeps its v1.75.0 verdict, which counts calls of the export
and not of its fields.

**v1.75.0 re-run (2026-10-23).** Seventy exports are new and none leaves. `O.__releaseChrome`,
which OptionsTabs minor 9 stops exporting
([#45](https://github.com/tusharsaxena/LibKa0s/issues/45)), never had a row here: the scan
enumerates through `Kit.publicMembers`, which drops a `__` member, so its going changes no row. The
new rows, each read from the code:

- **`LibKa0s-Glow-1.0`** (new, [#56](https://github.com/tusharsaxena/LibKa0s/issues/56)):
  `lib.Start` and `lib.Stop` are consumed (3), by DropWatcher, KickCD and Quick Comms, each through
  its `NS.GlowLib` seam (`core/GlowSetup.lua`), drawing in `modules/Glow.lua` (DropWatcher, Quick
  Comms) and `modules/IconGrid_Render.lua` (KickCD).
- **`LibKa0s-Sim-1.0`** (new, [#54](https://github.com/tusharsaxena/LibKa0s/issues/54)): 61
  exports. `lib.NewSeam` and `lib.New` are consumed (3), by BankLedger, DropWatcher and LootHistory.
  Of the 30 instance members (the session's and the seam's), ten are consumed, eleven thin and nine
  zero; of the 28 descriptor fields, seventeen are consumed, five thin and six zero. Many thin
  instance counts are lower bounds in the way *Method* says: a host that drives a control through
  its `/x sim` verbs reaches it inside the library. Fourteen Sim rows are read by hand (see
  *Method*, step 5).
  **Planned at v1.76.0:** MultiMeters and KickCD become `LibKa0s-Sim-1.0` consumers in the v1.76.0
  run (its M3; MultiMeters#60, KickCD#38), each with its own seam (`Sim:NewSeam`) and session
  (`Sim:New`) lookups, which would make `lib.NewSeam` and `lib.New` consumed (5). The counts above
  stand until those adoptions land and the census is re-run for v1.76.0.
- **`LibKa0s-Widgets-1.0` minor 13**: `lib.SearchBox` is consumed (3), by BankLedger
  (`modules/Browser.lua`), DropWatcher and LootHistory (both through `core/WidgetsSetup.lua`)
  ([#52](https://github.com/tusharsaxena/LibKa0s/issues/52)). `lib.TestStrip` is consumed (4), by
  BankLedger (its browser and its session window), DropWatcher, LootHistory and MultiMeters
  (`modules/Window.lua`); `lib.TEST_STRIP` is consumed (3), by the same hosts but DropWatcher, which
  draws the strip and does not read the constant ([#48](https://github.com/tusharsaxena/LibKa0s/issues/48)).
  **Widgets minor 14** (v1.76.0) adds no member: `TestStrip` gains `opts.kind = "sim"` and the
  read-only `strip.kind`, which BankLedger, DropWatcher, LootHistory, MultiMeters and KickCD are to
  consume in the v1.76.0 run. The counts above stand until those adopters land and the census is
  re-run for v1.76.0.
- **`LibKa0s-Item-1.0` minor 3**: `lib.BonusIDsFromLink` is thin (2), BankLedger and LootHistory,
  the two hosts the promotion named ([#51](https://github.com/tusharsaxena/LibKa0s/issues/51)).
- **`W.StepPanel` has no row.** The release plan expected it to be an export with two in-library
  callers (Perf and Sim). LK-11's spike took outcome B
  ([#53](https://github.com/tusharsaxena/LibKa0s/issues/53)): the renderer is a file-local of
  `SimPanel.lua`, duplicated on purpose with `PerfPanel.lua`'s, and `lib.__StepPanel` is only its
  internal test seam, so there is no public member to count. Its descriptor's fields still appear
  under Sim, because the scan reads every `d.<field>` in a major's files: six are zero, documented,
  and `title` and `check` are consumed (3) by hand, as the host-facing `panel.title` and
  `panel.check`.
- **Never measured before, from v1.72.0 to v1.74.0**: Media's `lib.ICON_SETS` and `lib.IconAuthor`
  are thin (1), Quick Comms (`core/MediaSetup.lua`); Options' `Drawer` (instance) is thin (1) by
  hand, Quick Comms' When tab.

Verdicts moved on existing rows, most of them because the roster grew. `lib.ICONS` (Media) goes
from zero to thin (1): Quick Comms reads it in `core/MediaSetup.lua`. Ten go from thin to
consumed: Core `lib.RGBA` (Quick Comms) and `sink` (descriptor; DropWatcher, Premade Groups Filter
Extension and Quick Comms), Compat `lib.CanAccess` (DropWatcher) and `lib.IsSafeKey` (DropWatcher,
Quick Comms), Bus `NewTarget`, `StandDown` and `StandUp` (DropWatcher, Quick Comms), Item
`lib.LoadItem` (DropWatcher), DebugLog `DebugVerb` (DropWatcher, Premade Groups Filter Extension,
Quick Comms) and Options `RenderField` (Premade Groups Filter Extension). One goes down: Options
`SECTION_HEADING_H` (instance) goes from consumed (3) to thin (1), because BankLedger and
LootHistory stopped reading it when their settings landing pages moved onto the library's builder
(BankLedger `289ba5c`, LootHistory `10ad212`); PanelMaster still reads it. No consumed or thin
export lost its last host.

**v1.71.0 re-run (2026-10-07).** One verdict moved: `lib.Autocomplete` goes from zero (host
duplicate) to thin (2), through BankLedger's search-box seam in `modules/Browser.lua` and
LootHistory's `NS.MakeAutocomplete` seam in `core/WidgetsSetup.lua`. No export is new. The release
adds `ChartMath.ClipSegment`, but the scan counts `lib.ChartMath` as one lib-level export (still
zero, documented), and `Kit.secret` is a test-kit member, outside the census. Hit counts moved on
other rows because the hosts' code changed around them; no other host set changed.

**v1.70.0 re-run (2026-10-07).** One verdict moved: `lib.LINE_CHART` goes from zero to thin (1),
because LootHistory's `core/WidgetsSetup.lua` now reads it. Two exports are new, both from
`WidgetsAutocomplete.lua` minor 1. `lib.Autocomplete` is a **host duplicate** at the tag: the
library list was promoted from LootHistory's Timeline picker, which still hand-rolls it, and the two
named adopters (LootHistory on every tab, BankLedger on its search box) land after the tag on their
plan tasks B2 and C2. The next re-run should find it thin (2). `lib.AUTOCOMPLETE` has no host read
and is kept as the published constants; zero, documented. `WidgetsLineChart.lua` minor 2's
`opts.pxPerPoint` is read off the chart's stored options (`c.__opts.pxPerPoint`), not as
`d.<field>`, so the scan does not enumerate it, and the autocomplete's own `opts` fields are outside
it for the same reason (Method, step 1).

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
(pure Lua 5.1), copied from the v1.66.0 run with its logic unchanged. **The v1.75.0 run** used a
copy of it kept beside its output, in
`Ka0sAddonsCommonTasks/docs/2026-10-22-LIBKA0S_ISSUES_45_58/plan-data/census-v1.75.0/` (the
2026-10-02 bundle is frozen, so nothing was written into it), with two changes recorded in its
header and nothing else: the roster fix the v1.71.0 run made in a scratch copy (below), and
`LibKa0s-Sim-1.0`'s two instance locals, `sim` (what `lib:New` returns) and `seam` (what
`lib:NewSeam` returns). Its raw output is `summary.tsv` and `hits.tsv` there; the hand-read
verdicts are `verdicts.tsv`, carried from v1.70.0 with the rows for every new zero and every
by-hand verdict added, and the issues the v1.66.0 run filed are `issues.tsv`. The tables on this
page are rendered from those files by the `census-render.lua` beside them, which differs from the
2026-10-02 renderer in two ways: the roster size is an argument (`all 14`, not `all 11`), and a
verdict row's `hand_hosts` column overrides the scan's host set (step 5). The v1.70.0 and v1.69.0
data stay in the 2026-10-02 bundle and the v1.66.0 data in
`docs/2026-10-01-GITHUB_ISSUE_PASS/plan-data/census/`.

**The v1.71.0 run** used the same tool with one fix to its roster read: WowAddonStandards v2.77.0
turned `ADDONS.md`'s Folder column from links into plain code text, and the tool's row pattern
required the link, so unpatched it searched no files at all. The patched pattern takes either form.
The fix was made to a scratch copy, so the tool beside the v1.70.0 data still carries the old
pattern; its raw output was not kept beside it, and the v1.70.0 `verdicts.tsv` carried forward
unchanged, as no hand-read verdict moved (the one moved verdict is mechanical: a zero-consumer
export gained hosts).

1. **What is enumerated.**
   - *lib*: every member of each major's live library table, loaded through this repo's mock
     exactly as `tools/gen-api-members.lua` does and filtered by the same `Kit.publicMembers` rule.
     These are the `members-*.json` entries.
   - *instance*: every public member a major's own files define on what `lib:New` returns, found
     statically as `function R.X(`, `function R:X(` or `R.X =`, where `R` is the major's instance
     local (`Sl`, `D`, `O`, `P`, `S`, `B`, `LC`, `Lb`, and Sim's two, `sim` and `seam`).
   - *descriptor*: every field a major's files read as `d.<field>`, outside comments.

   A field read through another name (Schema's `format` and `debug`, for example) is outside this
   definition and is not counted.
2. **What is searched.** Every git-tracked `.lua` file of the fourteen addons, excluding `libs/` and
   `tests/_kit/`: 1575 files at v1.75.0 (1135 across eleven at v1.71.0).
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

   **From v1.75.0 a hand-read verdict can override the scan's host set**, and fifteen do, each
   marked *read by hand*; the raw class counts in the row stay as the scan measured them. Two scan
   blind spots surfaced with the Sim major. A host reaches the seam only through
   `NS.SimSeam = Sim:NewSeam(...)`, and the scan learns instances from `:New(` alone, so every seam
   call is name-only: `Live` and `SetProvider` are consumed (3) and `Keys` thin (2) by hand. The
   same blind spot covers Options' `Drawer`, which Quick Comms calls as `H().Drawer(ctx, ...)` on
   the Options instance `H()` returns, so it is thin (1) by hand. A field nested under a descriptor
   sub-table is not enumerated, so Sim's `title` and `check`, which every host passes as
   `panel.title` and `panel.check`, are consumed (3) by hand. The other way round, BankLedger's Sim
   degradation stubs (`core/SimSetup.lua:76-91`, host contract H9) are plain assignments the
   stub-block detector does not recognize, so they scored as calls: `Run`, `Pause`, `Resume`,
   `Restart`, `RefreshPanel` and `TogglePanel` are zero by hand, and `HidePanel`, `IsPanelShown`
   and `ResetPanelPosition` thin (1), DropWatcher's real calls alone.

Three limits, plus the two blind spots above. A host that reaches an instance only through a function parameter registers as
name-only, so a **thin** count is a lower bound. A name shared by several majors (`New`, `STRINGS`)
is resolved per receiver, not per name. A function's options table is not a descriptor, so
`MakeResizable`'s `opts` fields (`canResize`, `onResizeStop` and `gripParent` from Core 10) are not
counted on their own.

## The zero-consumer set

*Evidence* is the hand-read finding: where the duplicate lives, why nothing calls the export, or
where a deliberate copy records its reason. *Hits by class* is the tool's raw count.

| Major | Export | Evidence | Hits by class | Verdict |
|---|---|---|---|---|
| Lifecycle | `Hold` (instance) | stubs only (18 stub lines across 6 hosts) | call 0 · stub 24 · test 72 | zero — kept, documented |
| Lifecycle | `PrintHolds` (instance) | stubs only | call 0 · stub 12 · test 5 | zero — kept, documented |
| Lifecycle | `Release` (instance) | stubs only; the 7 name hits are other tables' `Release` | call 0 · name-only 13 · def 5 · stub 23 · test 112 | zero — kept, documented |
| Lifecycle | `name` (instance) | instance data field | call 0 · name-only 439 · def 3 · stub 104 · test 7587 | zero — kept, documented |
| Schema | `lib.STRINGS` | no host reads the table by name | call 0 · name-only 1 · stub 4 · test 150 | zero — kept, documented |
| Media | `lib.FONTS` | no host reads the table by name | call 0 · test 29 | zero — kept, documented |
| Media | `lib.TEXTURES` | no host reads the table by name | call 0 · test 3 | zero — kept, documented |
| Media | `lib.Texture` | ConsumableMaster's two `Texture` hits are its own `MacroDisplay.Texture` | call 0 · name-only 11 · def 2 · test 71 | zero — kept, documented |
| Media | `lib.VENDOR_PATH` | default value | call 0 · test 1 | zero — kept, documented |
| Widgets | `lib.AUTOCOMPLETE` | no host reads it | call 0 | zero — kept, documented |
| Widgets | `lib.ChartMath` | no host calls it; LootHistory aligns its in/out strip through the chart instance's `XToPixel` instead | call 0 · test 2 | zero — kept, documented |
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
| DebugLog | `lib.MakeCloseButton` | the 21 name hits are `Core.MakeCloseButton` calls | call 0 · name-only 29 · def 14 · stub 25 · test 128 | zero — kept, documented |
| DebugLog | `lib.STRINGS` | no host reads the table by name | call 0 · name-only 1 · stub 4 · test 150 | zero — kept, documented |
| DebugLog | `lib.TIME_COPY` | diagnostic switch | call 0 | zero — kept, documented |
| DebugLog | `BufferSize` (instance) | read by host tests only (62 hits) | call 0 · stub 12 · test 62 | zero — kept, documented |
| DebugLog | `BuildDiagnostics` (instance) | read by host tests only | call 0 · stub 18 · test 32 | zero — kept, documented |
| DebugLog | `CopyText` (instance) | read by host tests only | call 0 · stub 6 · test 22 | zero — kept, documented |
| DebugLog | `FindLine` (instance) | read by host tests only (88 hits) | call 0 · stub 12 · test 89 | zero — kept, documented |
| DebugLog | `LastLine` (instance) | read by host tests only | call 0 · stub 12 · test 50 | zero — kept, documented |
| DebugLog | `MakeCloseButton` (instance) | mirror of the lib-level member | call 0 · name-only 29 · def 14 · stub 25 · test 128 | zero — kept, documented |
| DebugLog | `Text` (instance) | the 15 name hits are `Sl:Text` (LibKa0s-Slash-1.0) calls | call 0 · name-only 18 · def 1 · stub 12 · test 261 | zero — kept, documented |
| DebugLog | `buffer` (instance) | read by host tests only (478 hits) | call 0 · stub 16 · test 508 | zero — kept, documented |
| DebugLog | `diagnosticsEnablesLogging` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| DebugLog | `makeCloseButton` (descriptor) | BankLedger core/DebugLogSetup.lua:146 and LootHistory core/DebugLogSetup.lua:163 record why | call 0 | zero — kept, documented |
| DebugLog | `skin` (descriptor) | no descriptor passes it (MultiMeters settings/Schema_Compose.lua:248 is a locale key) | call 0 | zero — kept, documented |
| Slash | `CliResetAll` (instance) | LootHistory settings/Slash.lua:433-435 and BankLedger settings/Slash.lua:478-479 record why | call 0 · name-only 6 · def 3 · stub 9 · test 64 | zero — deliberate host copy |
| Launcher | `lib.STRINGS` | no host reads the table by name | call 0 · name-only 1 · stub 4 · test 150 | zero — kept, documented |
| Launcher | `Object` (instance) | read by host tests only (110 hits) | call 0 · stub 10 · test 114 | zero — kept, documented |
| Launcher | `L` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Options | `lib.LAYOUT` | KickCD core/Constants.lua:109-116 records the deletion; no host reads the table by name | call 0 · name-only 7 · test 97 | zero — kept, documented |
| Options | `lib.PatchAlwaysShowScrollbar` | reached through `EnsureScroll` | call 0 · stub 11 · test 20 | zero — kept, documented |
| Options | `lib.STRINGS` | no host reads the table by name | call 0 · name-only 1 · stub 4 · test 150 | zero — kept, documented |
| Options | `CHROME_GAP` (instance) | no host draws such chrome today | call 0 · name-only 3 · stub 6 · test 19 | zero — kept, documented |
| Options | `FONT_FLAGS` (instance) | MultiMeters settings/Schema_Compose.lua:165-184 records why | call 0 · name-only 1 · stub 4 · test 14 | zero — deliberate host copy |
| Options | `FONT_FLAGS_SORT` (instance) | MultiMeters settings/Schema_Compose.lua:184 | call 0 · stub 3 · test 12 | zero — deliberate host copy |
| Options | `ID_NAME_HINT` (instance) | reached through `IdInput` | call 0 · stub 17 · test 3 | zero — kept, documented |
| Options | `PatchAlwaysShowScrollbar` (instance) | reached through `EnsureScroll` | call 0 · stub 11 · test 20 | zero — kept, documented |
| Options | `RenderSchema` (instance) | superseded in practice | call 0 · stub 16 · test 24 | zero — kept, documented |
| Options | `SetChromeHeight` (instance) | reached through the chrome makers | call 0 · stub 15 · test 4 | zero — kept, documented |
| Options | `TAB_H` (instance) | no host measures its own strip today | call 0 · name-only 5 · stub 5 · test 20 | zero — kept, documented |
| Options | `UnnamedCandidates` (instance) | reached through `IdInput` | call 0 · stub 16 · test 1 | zero — kept, documented |
| Options | `VISIBILITY_SORT` (instance) | MultiMeters settings/Schema_Compose.lua:602-611 records why | call 0 · stub 3 · test 12 | zero — deliberate host copy |
| Options | `VISIBILITY_VALUES` (instance) | MultiMeters settings/Schema_Compose.lua:602-611 records why | call 0 · stub 3 · test 12 | zero — deliberate host copy |
| Options | `afterRestoreAll` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Perf | `lib.DEFAULT_RING` | default value | call 0 · test 2 | zero — kept, documented |
| Perf | `lib.EncodeJSON` | read by host tests only | call 0 · test 14 | zero — kept, documented |
| Perf | `lib.SCHEMA` | read by host tests only | call 0 · stub 1 · test 24 | zero — kept, documented |
| Perf | `lib.STRINGS` | no host reads the table by name | call 0 · name-only 1 · stub 4 · test 150 | zero — kept, documented |
| Perf | `Announce` (instance) | reached through `OnCommand` | call 0 · name-only 3 · def 1 · test 20 | zero — kept, documented |
| Perf | `BuildRecord` (instance) | reached through `OnCommand` | call 0 · name-only 1 · def 1 · test 21 | zero — kept, documented |
| Perf | `Cancel` (instance) | reached through `OnCommand` | call 0 · name-only 68 · def 5 · test 88 | zero — kept, documented |
| Perf | `Close` (instance) | no host brackets with `Open`/`Close` | call 0 · name-only 18 · def 5 · stub 2 · test 87 | zero — kept, documented |
| Perf | `Context` (instance) | reached through `OnCommand` | call 0 · name-only 12 · def 1 · test 12 | zero — kept, documented |
| Perf | `ContextLines` (instance) | reached through `OnCommand` | call 0 | zero — kept, documented |
| Perf | `EXPERIMENTS` (instance) | library-internal table (not in the instance table) | call 0 | zero — kept, documented |
| Perf | `EncodeJSON` (instance) | read by host tests only | call 0 · test 14 | zero — kept, documented |
| Perf | `FormatReport` (instance) | reached through `OnCommand` | call 0 · test 3 | zero — kept, documented |
| Perf | `HidePanel` (instance) | reached through `OnCommand` and the panel | call 0 · name-only 4 · test 31 | zero — kept, documented |
| Perf | `IsPanelShown` (instance) | read by host tests only | call 0 · name-only 4 · test 30 | zero — kept, documented |
| Perf | `LABELS` (instance) | library-internal table (not in the instance table) | call 0 · name-only 8 · test 14 | zero — kept, documented |
| Perf | `Log` (instance) | reached through `OnCommand` | call 0 · name-only 3 · def 1 · test 17 | zero — kept, documented |
| Perf | `MarkReviewed` (instance) | reached through `OnCommand` | call 0 · test 1 | zero — kept, documented |
| Perf | `Measure` (instance) | reached through `OnCommand` | call 0 · name-only 1 · test 6 | zero — kept, documented |
| Perf | `Open` (instance) | no host brackets with `Open`/`Close` | call 0 · name-only 39 · def 14 · stub 3 · test 357 | zero — kept, documented |
| Perf | `PanelIsActionable` (instance) | no `decorate` host | call 0 | zero — kept, documented |
| Perf | `PanelStateOf` (instance) | no `decorate` host | call 0 · test 2 | zero — kept, documented |
| Perf | `Progress` (instance) | reached through the panel | call 0 | zero — kept, documented |
| Perf | `RefreshPanel` (instance) | reached through the library's own transitions | call 0 · name-only 36 · stub 11 · test 28 | zero — kept, documented |
| Perf | `Reset` (instance) | reached through `OnCommand` | call 0 · name-only 4 · def 4 · stub 8 · test 451 | zero — kept, documented |
| Perf | `Resume` (instance) | reached through `OnCommand` | call 0 · name-only 12 · def 15 · test 77 | zero — kept, documented |
| Perf | `SCHEMA` (instance) | read by host tests only | call 0 · stub 1 · test 24 | zero — kept, documented |
| Perf | `STEPS` (instance) | reached through the panel | call 0 · test 13 | zero — kept, documented |
| Perf | `Save` (instance) | reached through `OnCommand` | call 0 · name-only 3 · def 3 · test 111 | zero — kept, documented |
| Perf | `ShowPanel` (instance) | reached through `OnCommand` | call 0 · name-only 5 · test 27 | zero — kept, documented |
| Perf | `Start` (instance) | reached through `OnCommand` | call 0 · name-only 12 · def 10 · test 181 | zero — kept, documented |
| Perf | `StatusLines` (instance) | reached through `OnCommand` | call 0 · test 1 | zero — kept, documented |
| Perf | `Stop` (instance) | reached through `OnCommand` | call 0 · name-only 43 · def 10 · test 123 | zero — kept, documented |
| Perf | `Suspend` (instance) | reached through `OnCommand` | call 0 · name-only 4 · def 15 · test 101 | zero — kept, documented |
| Perf | `TogglePanel` (instance) | reached through `OnCommand` | call 0 · name-only 3 · test 1 | zero — kept, documented |
| Perf | `Usage` (instance) | reached through `OnCommand` | call 0 · test 47 | zero — kept, documented |
| Perf | `context` (instance) | instance data field (not in the instance table) | call 0 · name-only 2 · def 2 · test 200 | zero — kept, documented |
| Perf | `descriptor` (instance) | instance data field (not in the instance table) | call 0 · stub 10 · test 761 | zero — kept, documented |
| Perf | `name` (instance) | instance data field (not in the instance table) | call 0 · name-only 439 · def 3 · stub 104 · test 7587 | zero — kept, documented |
| Perf | `ringMax` (instance) | instance data field (not in the instance table) | call 0 | zero — kept, documented |
| Perf | `slash` (instance) | instance data field (not in the instance table) | call 0 · name-only 3 · stub 75 · test 1445 | zero — kept, documented |
| Perf | `title` (instance) | instance data field (not in the instance table) | call 0 · name-only 108 · def 7 · stub 2 · test 729 | zero — kept, documented |
| Perf | `L` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Perf | `decorate` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Perf | `onChange` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Perf | `ring` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Sim | `lib.STRINGS` | no host reads the table by name; LootHistory settings/Slash.lua:233 is LibKa0s-Slash-1.0's `lib.STRINGS` | call 0 · name-only 1 · stub 4 · test 150 | zero — kept, documented |
| Sim | `PanelRows` (instance) | reached through the library's step panel; the host defs are library-absent stubs | call 0 · def 3 · test 20 | zero — kept, documented |
| Sim | `Pause` (instance) | BankLedger's only "call" is its library-absent stub (core/SimSetup.lua:76-91, host contract H9), which the scan's block detector misses; DropWatcher's and LootHistory's name hits are their own stubs and other tables' members | call 1 · name-only 3 · def 1 · test 3 | zero — kept, documented (read by hand) |
| Sim | `RefreshPanel` (instance) | BankLedger's only "call" is its library-absent stub (core/SimSetup.lua:76-91, host contract H9), which the scan's block detector misses; the name hits are other tables' members and the other hosts' stubs | call 1 · name-only 35 · stub 11 · test 28 | zero — kept, documented (read by hand) |
| Sim | `Restart` (instance) | BankLedger's only "call" is its library-absent stub (core/SimSetup.lua:76-91, host contract H9), which the scan's block detector misses; DropWatcher's and LootHistory's name hits are their own stubs and other tables' members | call 1 · name-only 2 · test 7 | zero — kept, documented (read by hand) |
| Sim | `Resume` (instance) | BankLedger's only "call" is its library-absent stub (core/SimSetup.lua:76-91, host contract H9), which the scan's block detector misses; DropWatcher's and LootHistory's name hits are their own stubs and other tables' members | call 1 · name-only 11 · def 15 · test 77 | zero — kept, documented (read by hand) |
| Sim | `Run` (instance) | BankLedger's only "call" is its library-absent stub (core/SimSetup.lua:76-91, host contract H9), which the scan's block detector misses; DropWatcher's and LootHistory's name hits are their own stubs and other tables' members | call 1 · name-only 15 · def 5 · stub 3 · test 265 | zero — kept, documented (read by hand) |
| Sim | `Step` (instance) | AuraMaster's hits are `E.LuaCurveType.Step`; the host defs are library-absent stubs | call 0 · name-only 3 · def 3 · test 71 | zero — kept, documented |
| Sim | `TogglePanel` (instance) | BankLedger's only "call" is its library-absent stub (core/SimSetup.lua:76-91, host contract H9), which the scan's block detector misses; the name hits are other tables' members and the other hosts' stubs | call 1 · name-only 2 · test 1 | zero — kept, documented (read by hand) |
| Sim | `Unwrapped` (instance) | read by host tests only (all three Sim hosts); the host defs are library-absent seam stubs | call 0 · def 3 · test 13 | zero — kept, documented |
| Sim | `addonName` (descriptor) | library-internal: SimPanel.lua's renderer reads `d.addonName` off the table its adapter builds (`renderer`, SimPanel.lua:827), not off the host's descriptor | call 0 | zero — kept, documented |
| Sim | `close` (descriptor) | library-internal: SimPanel.lua's renderer reads `d.close` off the table its adapter builds (`renderer`, SimPanel.lua:827), not off the host's descriptor | call 0 | zero — kept, documented |
| Sim | `footer` (descriptor) | library-internal: SimPanel.lua's renderer reads `d.footer` off the table its adapter builds (`renderer`, SimPanel.lua:827), not off the host's descriptor | call 0 | zero — kept, documented |
| Sim | `onClick` (descriptor) | library-internal: SimPanel.lua's renderer reads `d.onClick` off the table its adapter builds (`renderer`, SimPanel.lua:827), not off the host's descriptor | call 0 | zero — kept, documented |
| Sim | `rows` (descriptor) | library-internal: SimPanel.lua's renderer reads `d.rows` off the table its adapter builds (`renderer`, SimPanel.lua:827), not off the host's descriptor | call 0 | zero — kept, documented |
| Sim | `tooltip` (descriptor) | library-internal: SimPanel.lua's renderer reads `d.tooltip` off the table its adapter builds (`renderer`, SimPanel.lua:827), not off the host's descriptor | call 0 | zero — kept, documented |

## Every export

Consumers lists each calling host with its first production call when there are three or fewer,
and the host names otherwise. Every hit with its file and line is in a run's `hits.tsv` (the v1.75.0 run's is `census-v1.75.0/hits.tsv` in the 2026-10-22 bundle; the v1.71.0 run's was not kept, see [Method](#method)). A row read by hand names the call site that reading found. Hits for an
export called by three or more hosts are capped there at five per host per class, and the counts
here are uncapped.

| Major | Export | Consumers (first production call per host) | Hits by class | Verdict |
|---|---|---|---|---|
| Core | `lib.ApplySkin` | 9: AuraMaster, BankLedger, DropWatcher, LootHistory, MultiMeters, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 9 · name-only 26 · def 2 · stub 12 · test 27 | consumed (9) |
| Core | `lib.ClassColor` | AuraMaster `core/CoreSetup.lua:151`; MultiMeters `core/CoreSetup.lua:264` | call 2 · name-only 13 · def 2 · stub 3 · test 22 | thin (2) |
| Core | `lib.IsConcatSafe` | 13: AbsorbTracker, BankLedger, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 13 · name-only 12 · stub 27 · test 87 | consumed (13) |
| Core | `lib.MakeCloseButton` | 12: AuraMaster, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 12 · name-only 17 · def 14 · stub 25 · test 128 | consumed (12) |
| Core | `lib.MakeResizable` | 5: BankLedger, DropWatcher, LootHistory, MultiMeters, QuickComms | call 5 · name-only 5 · stub 6 · test 39 | consumed (5) |
| Core | `lib.New` | all 14 | call 14 · name-only 157 · def 23 · stub 19 · test 816 | consumed (14) |
| Core | `lib.RGBA` | ConsumableMaster `core/CoreSetup.lua:163`; MultiMeters `core/CoreSetup.lua:243`; QuickComms `settings/SchemaMembers.lua:350` | call 4 · name-only 8 · stub 2 · test 35 | consumed (3) |
| Core | `lib.RaiseStaticPopups` | none in a host by design; internal callers DebugLog (`DebugLog.lua`), Perf (`PerfPanel.lua`) and Sim (`SimPanel.lua`), each tool window on show | not measured (new at v1.77.0) | zero — planned at v1.77.0 (M2 of Ka0sAddonsCommonTasks `docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`) |
| Core | `lib.ResolveColor` | 8: AbsorbTracker, AuraMaster, ConsumableMaster, DropWatcher, KickCD, PanelMaster, PartyFrameEnhanced, QuickComms | call 9 · name-only 41 · def 1 · stub 6 · test 17 | consumed (8) |
| Core | `lib.SECRET` | AbsorbTracker `core/CoreSetup.lua:136`; KickCD `core/CoreSetup.lua:194`; MultiMeters `core/CoreSetup.lua:236` | call 3 · name-only 3 · stub 10 · test 304 | consumed (3) |
| Core | `lib.SKIN` | 7: AuraMaster, DropWatcher, MultiMeters, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 7 · name-only 10 · stub 21 · test 31 | consumed (7) |
| Core | `lib.SafeRegisterEvent` | all 14 | call 14 · name-only 40 · def 1 · stub 21 · test 57 | consumed (14) |
| Core | `lib.SafeRegisterEvents` | 10: AbsorbTracker, AuraMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms | call 10 · name-only 2 · def 1 · stub 11 · test 10 | consumed (10) |
| Core | `lib.SafeRegisterUnitEvent` | 10: AbsorbTracker, AuraMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms | call 10 · name-only 14 · def 1 · stub 11 · test 10 | consumed (10) |
| Core | `lib.SafeToString` | all 14 | call 14 · name-only 66 · stub 50 · test 163 | consumed (14) |
| Core | `prefix` (descriptor) | all 14 | call 14 | consumed (14) |
| Core | `sep` (descriptor) | PrettyChat `core/CoreSetup.lua:176` | call 1 | thin (1) |
| Core | `sink` (descriptor) | 5: ConsumableMaster, DropWatcher, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 5 | consumed (5) |
| Env | `lib.GetAddOnMetadata` | all 14 | call 14 · name-only 28 · test 118 | consumed (14) |
| Env | `lib.GetPlayerMapID` | BankLedger `core/EnvSetup.lua:83`; LootHistory `core/Compat.lua:86` | call 2 · test 3 | thin (2) |
| Env | `lib.GetZone` | BankLedger `core/EnvSetup.lua:99`; LootHistory `core/Compat.lua:77` | call 2 · test 3 | thin (2) |
| Env | `lib.Version` | all 14 | call 14 · name-only 42 · def 16 · stub 17 · test 260 | consumed (14) |
| Compat | `lib.CanAccess` | AuraMaster `core/Secrets.lua:53`; DropWatcher `core/Compat.lua:28`; MultiMeters `core/Secrets.lua:191` | call 3 · name-only 29 · test 65 | consumed (3) |
| Compat | `lib.GetSpecialization` | 5: ConsumableMaster, DropWatcher, KickCD, MultiMeters, PremadeGroupsFilterExtension | call 6 · name-only 6 · test 56 | consumed (5) |
| Compat | `lib.GetSpecializationInfo` | 5: ConsumableMaster, DropWatcher, KickCD, MultiMeters, PremadeGroupsFilterExtension | call 6 · name-only 5 · test 63 | consumed (5) |
| Compat | `lib.GetSpellCooldown` | KickCD `core/Compat.lua:101`; WhatGroup `core/Compat.lua:76` | call 2 · name-only 5 · test 76 | thin (2) |
| Compat | `lib.GetSpellInfo` | AuraMaster `core/Compat.lua:425`; KickCD `core/Compat.lua:169`; MultiMeters `core/Compat.lua:78` | call 3 · name-only 23 · def 1 · test 131 | consumed (3) |
| Compat | `lib.GetSpellName` | ConsumableMaster `core/Compat.lua:83`; LootHistory `core/Compat.lua:170`; WhatGroup `core/Compat.lua:52` | call 3 · name-only 14 · test 122 | consumed (3) |
| Compat | `lib.GetSpellTexture` | KickCD `core/Compat.lua:160`; MultiMeters `core/Compat.lua:79`; WhatGroup `core/Compat.lua:60` | call 3 · name-only 10 · test 64 | consumed (3) |
| Compat | `lib.IsSafeKey` | 4: AuraMaster, DropWatcher, MultiMeters, QuickComms | call 4 · name-only 50 · test 43 | consumed (4) |
| Compat | `lib.IsSecret` | 8: AuraMaster, ConsumableMaster, DropWatcher, KickCD, MultiMeters, PartyFrameEnhanced, QuickComms, WhatGroup | call 8 · name-only 115 · test 89 | consumed (8) |
| Lifecycle | `lib.HOLD_DISABLED` | all 14 | call 16 · name-only 31 · stub 9 · test 27 | consumed (14) |
| Lifecycle | `lib.HOLD_PERF` | 7: AuraMaster, DropWatcher, LootHistory, PanelMaster, PrettyChat, QuickComms, WhatGroup | call 7 · stub 8 · test 76 | consumed (7) |
| Lifecycle | `lib.New` | 12: AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LootHistory, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 12 · name-only 159 · def 23 · stub 19 · test 816 | consumed (12) |
| Lifecycle | `Hold` (instance) | none | call 0 · stub 24 · test 72 | zero — kept, documented |
| Lifecycle | `Holds` (instance) | all 14 | call 24 · stub 12 · test 24 | consumed (14) |
| Lifecycle | `IsDown` (instance) | all 14 | call 27 · name-only 10 · def 1 · stub 12 · test 50 | consumed (14) |
| Lifecycle | `IsHeld` (instance) | 7: AuraMaster, BankLedger, ConsumableMaster, DropWatcher, MultiMeters, QuickComms, WhatGroup | call 8 · stub 12 · test 25 | consumed (7) |
| Lifecycle | `PrintHolds` (instance) | none | call 0 · stub 12 · test 5 | zero — kept, documented |
| Lifecycle | `Reevaluate` (instance) | 12: AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 12 · name-only 11 · def 2 · stub 12 · test 12 | consumed (12) |
| Lifecycle | `Release` (instance) | none | call 0 · name-only 13 · def 5 · stub 23 · test 112 | zero — kept, documented |
| Lifecycle | `Set` (instance) | all 14 | call 27 · name-only 132 · def 15 · stub 35 · test 2513 | consumed (14) |
| Lifecycle | `name` (instance) | none | call 0 · name-only 439 · def 3 · stub 104 · test 7587 | zero — kept, documented |
| Lifecycle | `debug` (descriptor) | all 14 | call 14 | consumed (14) |
| Lifecycle | `name` (descriptor) | all 14 | call 14 | consumed (14) |
| Lifecycle | `print` (descriptor) | all 14 | call 14 | consumed (14) |
| Lifecycle | `standDown` (descriptor) | all 14 | call 14 | consumed (14) |
| Lifecycle | `standUp` (descriptor) | all 14 | call 14 | consumed (14) |
| Bus | `lib.Catalog` | 11: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, QuickComms | call 12 · name-only 6 · def 1 · stub 7 · test 65 | consumed (11) |
| Bus | `lib.New` | 6: AbsorbTracker, ConsumableMaster, DropWatcher, MultiMeters, PartyFrameEnhanced, QuickComms | call 6 · name-only 165 · def 23 · stub 19 · test 816 | consumed (6) |
| Bus | `NewTarget` (instance) | 4: ConsumableMaster, DropWatcher, PartyFrameEnhanced, QuickComms | call 21 · name-only 2 · stub 7 · test 40 | consumed (4) |
| Bus | `StandDown` (instance) | 4: ConsumableMaster, DropWatcher, PartyFrameEnhanced, QuickComms | call 4 · name-only 21 · def 16 · stub 17 · test 82 | consumed (4) |
| Bus | `StandUp` (instance) | 4: ConsumableMaster, DropWatcher, PartyFrameEnhanced, QuickComms | call 4 · name-only 24 · def 16 · stub 19 · test 61 | consumed (4) |
| Bus | `isDown` (descriptor) | 6: AbsorbTracker, ConsumableMaster, DropWatcher, MultiMeters, PartyFrameEnhanced, QuickComms | call 6 | consumed (6) |
| Bus | `name` (descriptor) | 6: AbsorbTracker, ConsumableMaster, DropWatcher, MultiMeters, PartyFrameEnhanced, QuickComms | call 6 | consumed (6) |
| Schema | `lib.New` | all 14 | call 14 · name-only 157 · def 23 · stub 19 · test 816 | consumed (14) |
| Schema | `lib.Read` | 6: AbsorbTracker, AuraMaster, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced | call 9 · name-only 16 · def 15 · stub 7 · test 105 | consumed (6) |
| Schema | `lib.STRINGS` | none | call 0 · name-only 1 · stub 4 · test 150 | zero — kept, documented |
| Schema | `lib.SameValue` | AuraMaster `settings/Schema.lua:566`; BankLedger `settings/Schema.lua:717` | call 2 · name-only 12 · def 11 · stub 4 · test 16 | thin (2) |
| Schema | `lib.SplitPath` | AuraMaster `settings/Schema.lua:181`; KickCD `settings/Slash.lua:156`; MultiMeters `settings/Schema_Paths.lua:824` | call 3 · name-only 31 · def 13 · stub 6 · test 11 | consumed (3) |
| Schema | `lib.Write` | 5: AbsorbTracker, AuraMaster, KickCD, PanelMaster, PartyFrameEnhanced | call 6 · name-only 27 · def 13 · stub 4 · test 27 | consumed (5) |
| Schema | `AddRows` (instance) | 9: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 13 · name-only 14 · def 12 · stub 2 · test 17 | consumed (9) |
| Schema | `AllRows` (instance) | AbsorbTracker `settings/OptionsSetup.lua:98`; BankLedger `modules/Diagnostics.lua:134`; PrettyChat `settings/OptionsSetup.lua:288` | call 7 · name-only 6 · def 11 · stub 3 · test 23 | consumed (3) |
| Schema | `ApplyDefault` (instance) | 6: AbsorbTracker, BankLedger, KickCD, MultiMeters, PartyFrameEnhanced, PrettyChat | call 12 · name-only 37 · def 13 · stub 11 · test 104 | consumed (6) |
| Schema | `BulkAdd` (instance) | AuraMaster `settings/Schema.lua:586`; PrettyChat `settings/Schema.lua:1063` | call 2 · name-only 1 · def 11 · stub 2 · test 5 | thin (2) |
| Schema | `BulkBegin` (instance) | 8: AbsorbTracker, AuraMaster, BankLedger, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 15 · name-only 19 · def 11 · stub 6 · test 24 | consumed (8) |
| Schema | `BulkEnd` (instance) | 8: AbsorbTracker, AuraMaster, BankLedger, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 15 · name-only 19 · def 11 · stub 6 · test 31 | consumed (8) |
| Schema | `BulkRun` (instance) | 7: AbsorbTracker, AuraMaster, ConsumableMaster, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 9 · name-only 9 · def 11 · stub 6 · test 10 | consumed (7) |
| Schema | `ConsumeResetCount` (instance) | AbsorbTracker `settings/Schema.lua:453`; KickCD `core/Database.lua:622`; PartyFrameEnhanced `settings/Schema.lua:337` | call 3 · name-only 12 · def 11 · stub 2 · test 6 | consumed (3) |
| Schema | `CountOffDefault` (instance) | AbsorbTracker `settings/Schema.lua:447`; PartyFrameEnhanced `settings/Schema.lua:331`; PrettyChat `settings/Schema.lua:871` | call 3 · def 11 · stub 2 · test 5 | consumed (3) |
| Schema | `Default` (instance) | BankLedger `settings/Schema.lua:742`; PanelMaster `settings/Schema.lua:806` | call 2 · name-only 6 · def 11 · stub 2 · test 683 | thin (2) |
| Schema | `FindRow` (instance) | 9: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 28 · name-only 46 · def 11 · stub 11 · test 192 | consumed (9) |
| Schema | `Get` (instance) | 8: AbsorbTracker, BankLedger, ConsumableMaster, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 16 · name-only 256 · def 26 · stub 14 · test 1223 | consumed (8) |
| Schema | `InBulk` (instance) | AuraMaster `settings/Schema.lua:548` | call 1 · name-only 2 · def 11 · stub 2 · test 16 | thin (1) |
| Schema | `Reindex` (instance) | AuraMaster `settings/Schema.lua:284` | call 1 · def 11 · stub 2 · test 13 | thin (1) |
| Schema | `ResetCounted` (instance) | AbsorbTracker `settings/Schema.lua:450`; KickCD `settings/OptionsSetup.lua:130`; PartyFrameEnhanced `settings/Schema.lua:334` | call 3 · name-only 6 · def 11 · stub 2 · test 4 | consumed (3) |
| Schema | `Set` (instance) | 8: AbsorbTracker, BankLedger, ConsumableMaster, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 21 · name-only 138 · def 15 · stub 35 · test 2513 | consumed (8) |
| Schema | `SetMany` (instance) | 4: ConsumableMaster, MultiMeters, PanelMaster, PrettyChat | call 4 · name-only 5 · def 11 · stub 5 · test 93 | consumed (4) |
| Schema | `Validate` (instance) | 6: AbsorbTracker, AuraMaster, BankLedger, KickCD, PanelMaster, PartyFrameEnhanced | call 6 · name-only 8 · def 14 · stub 2 · test 63 | consumed (6) |
| Schema | `L` (descriptor) | 4: BankLedger, LootHistory, MultiMeters, PanelMaster | call 4 | consumed (4) |
| Schema | `resetExempt` (descriptor) | 11: AbsorbTracker, BankLedger, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 11 | consumed (11) |
| Schema | `rows` (descriptor) | all 14 | call 14 | consumed (14) |
| Schema | `writeThrough` (descriptor) | 10: AbsorbTracker, AuraMaster, BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, QuickComms | call 10 | consumed (10) |
| Pool | `lib.Acquire` | 6: AuraMaster, BankLedger, DropWatcher, LootHistory, MultiMeters, QuickComms | call 26 · name-only 9 · def 7 · test 41 | consumed (6) |
| Pool | `lib.AcquireKeyed` | KickCD `modules/IconGrid.lua:206` | call 1 · def 1 · test 4 | thin (1) |
| Pool | `lib.Counts` | LootHistory `modules/Diagnostics.lua:336` | call 2 · name-only 2 · def 8 · test 65 | thin (1) |
| Pool | `lib.CountsKeyed` | KickCD `modules/Diagnostics.lua:183` | call 1 · def 1 · test 4 | thin (1) |
| Pool | `lib.New` | 6: AuraMaster, BankLedger, DropWatcher, LootHistory, MultiMeters, QuickComms | call 37 · name-only 134 · def 23 · stub 19 · test 816 | consumed (6) |
| Pool | `lib.NewKeyed` | KickCD `modules/IconGrid.lua:107` | call 1 · def 1 · test 3 | thin (1) |
| Pool | `lib.ReleaseAll` | 6: AuraMaster, BankLedger, DropWatcher, LootHistory, MultiMeters, QuickComms | call 29 · name-only 2 · def 7 · test 25 | consumed (6) |
| Pool | `lib.ReleaseAllKeyed` | KickCD `modules/IconGrid.lua:223` | call 1 · def 1 · test 3 | thin (1) |
| Item | `lib.BonusIDsFromLink` | BankLedger `core/Util.lua:106`; LootHistory `modules/Export.lua:36` | call 3 · def 2 · test 29 | thin (2) |
| Item | `lib.ItemIDFromLink` | 4: BankLedger, ConsumableMaster, DropWatcher, LootHistory | call 12 · def 4 · test 30 | consumed (4) |
| Item | `lib.LoadItem` | BankLedger `modules/Backfill.lua:158`; DropWatcher `modules/ItemFacts.lua:244`; LootHistory `core/Database.lua:489` | call 5 · def 3 · test 22 | consumed (3) |
| Item | `lib.QualityFromLink` | DropWatcher `core/ItemRead.lua:171`; LootHistory `core/Compat.lua:238` | call 2 · def 3 · test 9 | thin (2) |
| Item | `lib.QualityLabel` | BankLedger `core/Constants.lua:198`; LootHistory `core/Constants.lua:178` | call 20 · def 3 · test 26 | thin (2) |
| Glow | `lib.Start` | DropWatcher `modules/Glow.lua:135`; KickCD `modules/IconGrid_Render.lua:487`; QuickComms `modules/Glow.lua:77` | call 4 · name-only 8 · def 10 · test 181 | consumed (3) |
| Glow | `lib.Stop` | DropWatcher `modules/Glow.lua:110`; KickCD `modules/IconGrid_Render.lua:396`; QuickComms `modules/Glow.lua:65` | call 4 · name-only 39 · def 10 · test 123 | consumed (3) |
| Media | `lib.FONTS` | none | call 0 · test 29 | zero — kept, documented |
| Media | `lib.Font` | all 14 | call 14 · name-only 7 · def 1 · test 99 | consumed (14) |
| Media | `lib.ICONS` | QuickComms `core/MediaSetup.lua:52` | call 1 · test 22 | thin (1) |
| Media | `lib.ICON_SETS` | QuickComms `core/MediaSetup.lua:59` | call 1 · test 1 | thin (1) |
| Media | `lib.Icon` | all 14 | call 14 · name-only 78 · def 14 · test 422 | consumed (14) |
| Media | `lib.IconAuthor` | QuickComms `core/MediaSetup.lua:67` | call 2 · name-only 1 · def 1 · test 1 | thin (1) |
| Media | `lib.RegisterLSM` | all 14 | call 14 · test 9 | consumed (14) |
| Media | `lib.TEXTURES` | none | call 0 · test 3 | zero — kept, documented |
| Media | `lib.Texture` | none | call 0 · name-only 11 · def 2 · test 71 | zero — kept, documented |
| Media | `lib.VENDOR_PATH` | none | call 0 · test 1 | zero — kept, documented |
| Widgets | `lib.AUTOCOMPLETE` | none | call 0 | zero — kept, documented |
| Widgets | `lib.Autocomplete` | BankLedger `modules/Browser.lua:335`; LootHistory `core/WidgetsSetup.lua:272` | call 4 · test 47 | thin (2) |
| Widgets | `lib.ChartMath` | none | call 0 · test 2 | zero — kept, documented |
| Widgets | `lib.CloseMenu` | 4: BankLedger, DropWatcher, LootHistory, MultiMeters | call 6 · name-only 8 · def 2 · test 28 | consumed (4) |
| Widgets | `lib.CopyWindow` | 4: BankLedger, LootHistory, MultiMeters, QuickComms | call 7 · name-only 2 · def 1 · test 11 | consumed (4) |
| Widgets | `lib.DRAG_HANDLE` | 4: AbsorbTracker, AuraMaster, KickCD, QuickComms | call 6 · test 18 | consumed (4) |
| Widgets | `lib.DragHandle` | 5: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, QuickComms | call 10 · def 1 · test 22 | consumed (5) |
| Widgets | `lib.Dropdown` | 4: BankLedger, DropWatcher, LootHistory, MultiMeters | call 4 · name-only 2 · test 195 | consumed (4) |
| Widgets | `lib.LINE_CHART` | LootHistory `core/WidgetsSetup.lua:254` | call 1 · test 1 | thin (1) |
| Widgets | `lib.LineChart` | LootHistory `core/WidgetsSetup.lua:242` | call 3 · test 3 | thin (1) |
| Widgets | `lib.ROW_BOX` | ConsumableMaster `settings/Category.lua:581`; KickCD `settings/Spells_Rows.lua:292`; LootHistory `core/WidgetsSetup.lua:201` | call 5 · test 12 | consumed (3) |
| Widgets | `lib.ReorderList` | 4: ConsumableMaster, KickCD, LootHistory, QuickComms | call 12 · name-only 1 · test 44 | consumed (4) |
| Widgets | `lib.SearchBox` | BankLedger `modules/Browser.lua:319`; DropWatcher `core/WidgetsSetup.lua:49`; LootHistory `core/WidgetsSetup.lua:140` | call 5 · name-only 1 · test 31 | consumed (3) |
| Widgets | `lib.TEST_STRIP` | BankLedger `modules/Browser.lua:765`; LootHistory `core/WidgetsSetup.lua:304`; MultiMeters `modules/Window.lua:76` | call 6 · test 6 | consumed (3) |
| Widgets | `lib.TestStrip` | 4: BankLedger, DropWatcher, LootHistory, MultiMeters | call 9 · test 20 | consumed (4); `kind = "sim"` (Widgets 14) to be consumed by BankLedger, DropWatcher, LootHistory, MultiMeters and KickCD in v1.76.0, counts unchanged until they land |
| Widgets | `ApplyLevel` (instance) | none yet; planned: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, QuickComms (a host calls it on its drag handle after a re-level or re-parent) | not measured (new at v1.77.0) | zero — planned at v1.77.0 (M2 of Ka0sAddonsCommonTasks `docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`) |
| Widgets | `addonName` (descriptor) | 4: BankLedger, LootHistory, MultiMeters, QuickComms | call 4 | consumed (4) |
| Widgets | `anchorTo` (descriptor) | BankLedger `modules/Export.lua:290`; LootHistory `modules/Export.lua:377`; MultiMeters `modules/Export_Modal.lua:381` | call 3 | consumed (3) |
| Widgets | `applySkin` (descriptor) | BankLedger `modules/Export.lua:287`; LootHistory `modules/Export.lua:374`; MultiMeters `modules/Export_Modal.lua:375` | call 3 | consumed (3) |
| Widgets | `backdrop` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `editWidth` (descriptor) | MultiMeters `modules/Export_Modal.lua:374` | call 1 | thin (1) |
| Widgets | `font` (descriptor) | BankLedger `modules/Export.lua:286`; LootHistory `modules/Export.lua:372`; MultiMeters `modules/Export_Modal.lua:372` | call 3 | consumed (3) |
| Widgets | `fontSize` (descriptor) | LootHistory `modules/Export.lua:373`; MultiMeters `modules/Export_Modal.lua:373` | call 2 | thin (2) |
| Widgets | `height` (descriptor) | MultiMeters `modules/Export_Modal.lua:370` | call 1 | thin (1) |
| Widgets | `hoverXs` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `ignoreParentAlpha` (descriptor) | none yet; planned: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, QuickComms (a `DragHandle` spec field) | not measured (new at v1.77.0) | zero — planned at v1.77.0 (M2 of Ka0sAddonsCommonTasks `docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`) |
| Widgets | `integer` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `level` (descriptor) | none yet; planned: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, QuickComms (a `DragHandle` spec field) | not measured (new at v1.77.0) | zero — planned at v1.77.0 (M2 of Ka0sAddonsCommonTasks `docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`) |
| Widgets | `makeCloseButton` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `markers` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `name` (descriptor) | BankLedger `modules/Export.lua:284`; LootHistory `modules/Export.lua:370`; MultiMeters `modules/Export_Modal.lua:368` | call 3 | consumed (3) |
| Widgets | `scrollName` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `series` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `title` (descriptor) | BankLedger `modules/Export.lua:285`; LootHistory `modules/Export.lua:371`; MultiMeters `modules/Export_Modal.lua:371` | call 3 | consumed (3) |
| Widgets | `width` (descriptor) | MultiMeters `modules/Export_Modal.lua:369` | call 1 | thin (1) |
| Widgets | `xMax` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `xMin` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `yMax` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `yMin` (descriptor) | none | call 0 | zero — kept, documented |
| DebugLog | `lib.AT_ENABLE_MAX` | none | call 0 | zero — kept, documented |
| DebugLog | `lib.BUFFER_SLACK` | none | call 0 · test 1 | zero — kept, documented |
| DebugLog | `lib.DIAG_MAX_LINES` | none | call 0 · test 1 | zero — kept, documented |
| DebugLog | `lib.DIAG_MAX_PER_LIST` | none | call 0 | zero — kept, documented |
| DebugLog | `lib.FormatColored` | ConsumableMaster `core/DebugLogSetup.lua:310` | call 1 · stub 6 · test 54 | thin (1) |
| DebugLog | `lib.FormatPlain` | ConsumableMaster `core/DebugLogSetup.lua:310` | call 1 · stub 8 · test 69 | thin (1) |
| DebugLog | `lib.GATE_MAX_KEYS` | none | call 0 | zero — kept, documented |
| DebugLog | `lib.MAX_BUFFER` | none | call 0 · test 8 | zero — kept, documented |
| DebugLog | `lib.MakeCloseButton` | none | call 0 · name-only 29 · def 14 · stub 25 · test 128 | zero — kept, documented |
| DebugLog | `lib.New` | all 14 | call 14 · name-only 157 · def 23 · stub 19 · test 816 | consumed (14) |
| DebugLog | `lib.STRINGS` | none | call 0 · name-only 1 · stub 4 · test 150 | zero — kept, documented |
| DebugLog | `lib.TIME_COPY` | none | call 0 | zero — kept, documented |
| DebugLog | `Add` (instance) | 11: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, PrettyChat, QuickComms | call 27 · name-only 9 · def 5 · stub 17 · test 281 | consumed (11) |
| DebugLog | `BufferSize` (instance) | none | call 0 · stub 12 · test 62 | zero — kept, documented |
| DebugLog | `BuildDiagnostics` (instance) | none | call 0 · stub 18 · test 32 | zero — kept, documented |
| DebugLog | `Clear` (instance) | ConsumableMaster `core/DebugLogSetup.lua:286` | call 1 · name-only 24 · def 7 · stub 14 · test 445 | thin (1) |
| DebugLog | `ConsoleCheckbox` (instance) | 7: AbsorbTracker, AuraMaster, DropWatcher, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 10 · stub 11 · test 32 | consumed (7) |
| DebugLog | `CopyText` (instance) | none | call 0 · stub 6 · test 22 | zero — kept, documented |
| DebugLog | `Debug` (instance) | all 14 | call 14 · name-only 779 · stub 52 · test 558 | consumed (14) |
| DebugLog | `DebugAtEnable` (instance) | all 14 | call 34 · name-only 22 · def 1 · stub 22 · test 18 | consumed (14) |
| DebugLog | `DebugChanged` (instance) | 11: AbsorbTracker, AuraMaster, ConsumableMaster, DropWatcher, KickCD, LootHistory, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 21 · name-only 24 · def 1 · stub 18 · test 26 | consumed (11) |
| DebugLog | `DebugForget` (instance) | 8: AuraMaster, BankLedger, ConsumableMaster, KickCD, LootHistory, PartyFrameEnhanced, PremadeGroupsFilterExtension, WhatGroup | call 11 · name-only 7 · def 1 · stub 15 · test 3 | consumed (8) |
| DebugLog | `DebugOnce` (instance) | 11: AbsorbTracker, AuraMaster, ConsumableMaster, DropWatcher, LootHistory, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 17 · name-only 23 · def 3 · stub 20 · test 44 | consumed (11) |
| DebugLog | `DebugVerb` (instance) | 4: DropWatcher, PanelMaster, PremadeGroupsFilterExtension, QuickComms | call 4 · stub 18 · test 29 | consumed (4) |
| DebugLog | `FindLine` (instance) | none | call 0 · stub 12 · test 89 | zero — kept, documented |
| DebugLog | `Hide` (instance) | 7: BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PanelMaster, PrettyChat | call 8 · name-only 540 · def 10 · stub 17 · test 669 | consumed (7) |
| DebugLog | `IsEnabled` (instance) | AuraMaster `core/DebugLogSetup.lua:27`; ConsumableMaster `core/DebugLogSetup.lua:283`; PrettyChat `core/Util.lua:66` | call 3 · name-only 31 · def 4 · stub 15 · test 144 | consumed (3) |
| DebugLog | `IsShown` (instance) | 12: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat, QuickComms | call 25 · name-only 143 · def 4 · stub 29 · test 1601 | consumed (12) |
| DebugLog | `LastLine` (instance) | none | call 0 · stub 12 · test 50 | zero — kept, documented |
| DebugLog | `MakeCloseButton` (instance) | none | call 0 · name-only 29 · def 14 · stub 25 · test 128 | zero — kept, documented |
| DebugLog | `RefreshHeader` (instance) | ConsumableMaster `core/DebugLogSetup.lua:290` | call 1 · stub 14 · test 9 | thin (1) |
| DebugLog | `RunDiagnostics` (instance) | all 14 | call 20 · name-only 4 · stub 21 · test 69 | consumed (14) |
| DebugLog | `SetEnabled` (instance) | 9: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, LootHistory, MultiMeters, PartyFrameEnhanced, PrettyChat, WhatGroup | call 14 · name-only 31 · def 4 · stub 27 · test 349 | consumed (9) |
| DebugLog | `Show` (instance) | 12: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat, QuickComms | call 29 · name-only 320 · def 5 · stub 16 · test 958 | consumed (12) |
| DebugLog | `ShowCopy` (instance) | ConsumableMaster `core/DebugLogSetup.lua:289` | call 1 · def 1 · stub 14 · test 16 | thin (1) |
| DebugLog | `Text` (instance) | none | call 0 · name-only 18 · def 1 · stub 12 · test 261 | zero — kept, documented |
| DebugLog | `Toggle` (instance) | 13: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DropWatcher, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 15 · name-only 12 · def 10 · stub 15 · test 224 | consumed (13) |
| DebugLog | `UpdateScrollBar` (instance) | ConsumableMaster `core/DebugLogSetup.lua:291` | call 1 · stub 14 · test 20 | thin (1) |
| DebugLog | `UpdateStatus` (instance) | ConsumableMaster `core/DebugLogSetup.lua:292` | call 1 · stub 14 · test 15 | thin (1) |
| DebugLog | `buffer` (instance) | none | call 0 · stub 16 · test 508 | zero — kept, documented |
| DebugLog | `L` (descriptor) | 7: AbsorbTracker, AuraMaster, DropWatcher, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 7 | consumed (7) |
| DebugLog | `addonName` (descriptor) | all 14 | call 14 | consumed (14) |
| DebugLog | `applySkin` (descriptor) | BankLedger `core/DebugLogSetup.lua:142`; LootHistory `core/DebugLogSetup.lua:159` | call 2 | thin (2) |
| DebugLog | `brandName` (descriptor) | 13: AbsorbTracker, AuraMaster, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 13 | consumed (13) |
| DebugLog | `diagnostics` (descriptor) | all 14 | call 14 | consumed (14) |
| DebugLog | `diagnosticsEnablesLogging` (descriptor) | none | call 0 | zero — kept, documented |
| DebugLog | `font` (descriptor) | all 14 | call 14 | consumed (14) |
| DebugLog | `fontSize` (descriptor) | ConsumableMaster `core/DebugLogSetup.lua:189` | call 1 | thin (1) |
| DebugLog | `initSummary` (descriptor) | all 14 | call 14 | consumed (14) |
| DebugLog | `isEnabled` (descriptor) | all 14 | call 14 | consumed (14) |
| DebugLog | `makeCloseButton` (descriptor) | none | call 0 | zero — kept, documented |
| DebugLog | `name` (descriptor) | all 14 | call 14 | consumed (14) |
| DebugLog | `onClear` (descriptor) | AuraMaster `core/DebugLogSetup.lua:189`; ConsumableMaster `core/DebugLogSetup.lua:258`; MultiMeters `core/DebugLogSetup.lua:410` | call 3 | consumed (3) |
| DebugLog | `onVisibilityChanged` (descriptor) | all 14 | call 14 | consumed (14) |
| DebugLog | `print` (descriptor) | all 14 | call 14 | consumed (14) |
| DebugLog | `safeToString` (descriptor) | 11: AbsorbTracker, AuraMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 11 | consumed (11) |
| DebugLog | `setEnabled` (descriptor) | all 14 | call 14 | consumed (14) |
| DebugLog | `skin` (descriptor) | none | call 0 | zero — kept, documented |
| DebugLog | `slash` (descriptor) | all 14 | call 14 | consumed (14) |
| DebugLog | `title` (descriptor) | all 14 | call 14 | consumed (14) |
| Slash | `lib.CommandRows` | ConsumableMaster `settings/Slash.lua:662`; KickCD `settings/Slash.lua:415` | call 2 · name-only 6 · stub 5 · test 13 | thin (2) |
| Slash | `lib.DISABLED_LINE_FORMAT` | LootHistory `settings/Slash.lua:215`; PanelMaster `settings/Slash.lua:752` | call 2 · stub 36 · test 53 | thin (2) |
| Slash | `lib.FindCommand` | ConsumableMaster `settings/Slash.lua:661`; KickCD `settings/Slash.lua:414` | call 2 · name-only 6 · stub 3 · test 12 | thin (2) |
| Slash | `lib.FormatKV` | 9: AbsorbTracker, AuraMaster, DropWatcher, LootHistory, PanelMaster, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 9 · name-only 6 · stub 8 · test 47 | consumed (9) |
| Slash | `lib.FormatRow` | AbsorbTracker `settings/Slash.lua:43`; PartyFrameEnhanced `settings/Slash.lua:277` | call 2 · stub 3 · test 24 | thin (2) |
| Slash | `lib.FormatValue` | 12: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DropWatcher, LootHistory, MultiMeters, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 14 · name-only 10 · def 4 · stub 4 · test 25 | consumed (12) |
| Slash | `lib.LIVE_VERBS` | 9: AbsorbTracker, AuraMaster, BankLedger, KickCD, LootHistory, MultiMeters, PanelMaster, PrettyChat, WhatGroup | call 9 · stub 7 · test 38 | consumed (9) |
| Slash | `lib.New` | 11: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat, WhatGroup | call 11 · name-only 160 · def 23 · stub 19 · test 816 | consumed (11) |
| Slash | `lib.ParseBool` | ConsumableMaster `settings/Slash.lua:492`; MultiMeters `settings/Slash.lua:479` | call 2 · name-only 1 · def 1 · stub 1 · test 12 | thin (2) |
| Slash | `lib.ParseValue` | 5: AuraMaster, BankLedger, ConsumableMaster, KickCD, PanelMaster | call 5 · stub 7 · test 6 | consumed (5) |
| Slash | `lib.ProfileNames` | AbsorbTracker `settings/Slash.lua:537` | call 2 · test 2 | thin (1) |
| Slash | `lib.STRINGS` | LootHistory `settings/Slash.lua:233` | call 1 · stub 4 · test 150 | thin (1) |
| Slash | `lib.SplitVerb` | AbsorbTracker `settings/Slash.lua:384`; ConsumableMaster `settings/Slash.lua:660`; KickCD `settings/Slash.lua:413` | call 6 · name-only 8 · stub 5 · test 16 | consumed (3) |
| Slash | `BuildListLines` (instance) | BankLedger `settings/Slash.lua:457`; LootHistory `settings/Slash.lua:510`; PanelMaster `settings/Slash.lua:733` | call 3 · name-only 2 · def 1 · stub 8 · test 46 | consumed (3) |
| Slash | `CliGet` (instance) | 13: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, WhatGroup | call 16 · name-only 3 · stub 8 · test 40 | consumed (13) |
| Slash | `CliList` (instance) | all 14 | call 14 · name-only 3 · stub 8 · test 13 | consumed (14) |
| Slash | `CliProfile` (instance) | all 14 | call 18 · name-only 3 · def 1 · stub 13 · test 48 | consumed (14) |
| Slash | `CliReset` (instance) | 13: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, WhatGroup | call 13 · name-only 3 · stub 8 · test 39 | consumed (13) |
| Slash | `CliResetAll` (instance) | none | call 0 · name-only 6 · def 3 · stub 9 · test 64 | zero — deliberate host copy |
| Slash | `CliSet` (instance) | 13: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, WhatGroup | call 16 · name-only 8 · stub 14 · test 100 | consumed (13) |
| Slash | `CliVersion` (instance) | 9: BankLedger, DropWatcher, LootHistory, MultiMeters, PanelMaster, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 9 · name-only 3 · stub 10 · test 14 | consumed (9) |
| Slash | `DisabledLine` (instance) | 10: AbsorbTracker, AuraMaster, BankLedger, DropWatcher, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, QuickComms, WhatGroup | call 11 · name-only 9 · def 1 · stub 27 · test 91 | consumed (10) |
| Slash | `HelpHeader` (instance) | LootHistory `settings/Slash.lua:508` | call 1 · stub 6 · test 20 | thin (1) |
| Slash | `HelpRows` (instance) | LootHistory `settings/Slash.lua:509`; MultiMeters `settings/Slash.lua:908`; PanelMaster `settings/Slash.lua:731` | call 3 · stub 13 · test 20 | consumed (3) |
| Slash | `LandingRows` (instance) | all 14 | call 14 · name-only 9 · stub 19 · test 41 | consumed (14) |
| Slash | `OnSlash` (instance) | all 14 | call 14 · name-only 15 · def 2 · stub 18 · test 503 | consumed (14) |
| Slash | `PrintHelp` (instance) | all 14 | call 15 · name-only 3 · stub 37 · test 31 | consumed (14) |
| Slash | `ProfileSwitch` (instance) | 6: AbsorbTracker, BankLedger, ConsumableMaster, LootHistory, PanelMaster, PartyFrameEnhanced | call 6 · def 1 · stub 15 · test 36 | consumed (6) |
| Slash | `SetRowAnnotator` (instance) | AbsorbTracker `settings/Slash.lua:801`; AuraMaster `settings/Slash.lua:611` | call 2 · stub 10 | thin (2) |
| Slash | `Text` (instance) | LootHistory `settings/Slash.lua:549`; PanelMaster `settings/Slash.lua:744`; PrettyChat `settings/Slash.lua:418` | call 3 · name-only 15 · def 1 · stub 12 · test 261 | consumed (3) |
| Slash | `L` (descriptor) | 4: ConsumableMaster, KickCD, PanelMaster, WhatGroup | call 4 | consumed (4) |
| Slash | `aliases` (descriptor) | 6: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, MultiMeters, PartyFrameEnhanced | call 6 | consumed (6) |
| Slash | `allRows` (descriptor) | all 14 | call 14 | consumed (14) |
| Slash | `applyDefault` (descriptor) | all 14 | call 14 | consumed (14) |
| Slash | `brandName` (descriptor) | all 14 | call 14 | consumed (14) |
| Slash | `bulkBegin` (descriptor) | 7: AuraMaster, BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters, QuickComms | call 7 | consumed (7) |
| Slash | `bulkEnd` (descriptor) | 7: AuraMaster, BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters, QuickComms | call 7 | consumed (7) |
| Slash | `colorDecode` (descriptor) | AuraMaster `settings/Slash.lua:604`; ConsumableMaster `settings/Slash.lua:641` | call 2 | thin (2) |
| Slash | `colorEncode` (descriptor) | AuraMaster `settings/Slash.lua:605`; ConsumableMaster `settings/Slash.lua:642` | call 2 | thin (2) |
| Slash | `commands` (descriptor) | all 14 | call 14 | consumed (14) |
| Slash | `debug` (descriptor) | all 14 | call 14 | consumed (14) |
| Slash | `findRow` (descriptor) | all 14 | call 14 | consumed (14) |
| Slash | `format` (descriptor) | 8: AuraMaster, BankLedger, ConsumableMaster, DropWatcher, LootHistory, MultiMeters, PrettyChat, QuickComms | call 8 | consumed (8) |
| Slash | `get` (descriptor) | all 14 | call 14 | consumed (14) |
| Slash | `groupKey` (descriptor) | all 14 | call 14 | consumed (14) |
| Slash | `isEnabled` (descriptor) | all 14 | call 14 | consumed (14) |
| Slash | `liveVerbs` (descriptor) | all 14 | call 14 | consumed (14) |
| Slash | `parse` (descriptor) | 8: AuraMaster, BankLedger, ConsumableMaster, KickCD, PanelMaster, PrettyChat, QuickComms, WhatGroup | call 8 | consumed (8) |
| Slash | `print` (descriptor) | all 14 | call 14 | consumed (14) |
| Slash | `profiles` (descriptor) | all 14 | call 14 | consumed (14) |
| Slash | `set` (descriptor) | all 14 | call 14 | consumed (14) |
| Slash | `slash` (descriptor) | all 14 | call 14 | consumed (14) |
| Slash | `slashAliases` (descriptor) | all 14 | call 14 | consumed (14) |
| Slash | `version` (descriptor) | all 14 | call 14 | consumed (14) |
| Launcher | `lib.New` | all 14 | call 14 · name-only 157 · def 23 · stub 19 · test 816 | consumed (14) |
| Launcher | `lib.STRINGS` | none | call 0 · name-only 1 · stub 4 · test 150 | zero — kept, documented |
| Launcher | `IsRegistered` (instance) | 6: AbsorbTracker, DropWatcher, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 6 · name-only 1 · stub 10 · test 55 | consumed (6) |
| Launcher | `IsShown` (instance) | 6: AbsorbTracker, BankLedger, DropWatcher, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 6 · name-only 162 · def 4 · stub 29 · test 1601 | consumed (6) |
| Launcher | `Object` (instance) | none | call 0 · stub 10 · test 114 | zero — kept, documented |
| Launcher | `Register` (instance) | all 14 | call 14 · name-only 40 · def 19 · stub 21 · test 349 | consumed (14) |
| Launcher | `SetShown` (instance) | all 14 | call 14 · name-only 165 · stub 19 · test 63 | consumed (14) |
| Launcher | `L` (descriptor) | none | call 0 | zero — kept, documented |
| Launcher | `debug` (descriptor) | all 14 | call 14 | consumed (14) |
| Launcher | `debugAtEnable` (descriptor) | all 14 | call 14 | consumed (14) |
| Launcher | `icon` (descriptor) | all 14 | call 14 | consumed (14) |
| Launcher | `isEnabled` (descriptor) | all 14 | call 14 | consumed (14) |
| Launcher | `isLocked` (descriptor) | 12: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, QuickComms, WhatGroup | call 12 | consumed (12) |
| Launcher | `isTestMode` (descriptor) | 7: AuraMaster, BankLedger, DropWatcher, LootHistory, MultiMeters, QuickComms, WhatGroup | call 7 | consumed (7) |
| Launcher | `label` (descriptor) | all 14 | call 14 | consumed (14) |
| Launcher | `minimap` (descriptor) | all 14 | call 14 | consumed (14) |
| Launcher | `name` (descriptor) | all 14 | call 14 | consumed (14) |
| Launcher | `onTooltipShow` (descriptor) | BankLedger `core/LauncherSetup.lua:270`; LootHistory `core/LauncherSetup.lua:192` | call 2 | thin (2) |
| Launcher | `openSettings` (descriptor) | all 14 | call 14 | consumed (14) |
| Launcher | `print` (descriptor) | all 14 | call 14 | consumed (14) |
| Launcher | `setEnabled` (descriptor) | all 14 | call 14 | consumed (14) |
| Launcher | `version` (descriptor) | all 14 | call 14 | consumed (14) |
| Options | `lib.LAYOUT` | none | call 0 · name-only 7 · test 97 | zero — kept, documented |
| Options | `lib.New` | all 14 | call 14 · name-only 157 · def 23 · stub 19 · test 816 | consumed (14) |
| Options | `lib.PatchAlwaysShowScrollbar` | none | call 0 · stub 11 · test 20 | zero — kept, documented |
| Options | `lib.STRINGS` | none | call 0 · name-only 1 · stub 4 · test 150 | zero — kept, documented |
| Options | `AceGUI` (instance) | 5: BankLedger, KickCD, PanelMaster, PremadeGroupsFilterExtension, WhatGroup | call 17 · name-only 72 · stub 12 · test 658 | consumed (5) |
| Options | `AddSpacer` (instance) | 8: AuraMaster, BankLedger, LootHistory, MultiMeters, PanelMaster, PremadeGroupsFilterExtension, PrettyChat, WhatGroup | call 30 · name-only 22 · stub 14 · test 11 | consumed (8) |
| Options | `AttachTooltip` (instance) | 8: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, MultiMeters, PanelMaster, PrettyChat, WhatGroup | call 29 · name-only 69 · def 1 · stub 13 · test 24 | consumed (8) |
| Options | `BANNER_H` (instance) | AbsorbTracker `settings/UnitPanel.lua:126`; PanelMaster `settings/PanelEditor.lua:510` | call 5 · name-only 3 · stub 5 · test 31 | thin (2) |
| Options | `BUTTON_PAIR_REL` (instance) | AuraMaster `settings/GeneralSpells.lua:602`; LootHistory `settings/Panel.lua:38`; PanelMaster `settings/Panel.lua:59` | call 7 · name-only 7 · stub 6 · test 31 | consumed (3) |
| Options | `BarGroup` (instance) | 5: AbsorbTracker, AuraMaster, KickCD, PanelMaster, PartyFrameEnhanced; v1.77.0 adds `tooltips` beside `labels` (OptionsCompose minor 10, `options-ui-§16`): planned AbsorbTracker, in M3 of Ka0sAddonsCommonTasks `docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`, not measured | call 7 · stub 11 · test 17 | consumed (5) |
| Options | `BorderGroup` (instance) | 6: AbsorbTracker, AuraMaster, DropWatcher, KickCD, PanelMaster, PartyFrameEnhanced; v1.77.0 adds `tooltips` beside `labels` (OptionsCompose minor 10, `options-ui-§16`): planned AbsorbTracker, in M3 of Ka0sAddonsCommonTasks `docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`, not measured | call 12 · name-only 5 · def 1 · stub 11 · test 17 | consumed (6) |
| Options | `BuildLandingPage` (instance) | 12: AbsorbTracker, AuraMaster, BankLedger, DropWatcher, KickCD, LootHistory, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 12 · name-only 3 · stub 3 · test 52 | consumed (12) |
| Options | `CHROME_GAP` (instance) | none | call 0 · name-only 3 · stub 6 · test 19 | zero — kept, documented |
| Options | `CLASS_COLOR_NOTE` (instance) | AuraMaster `settings/Bars.lua:96`; PanelMaster `settings/PanelEditor.lua:387` | call 3 · name-only 1 · stub 3 · test 22 | thin (2) |
| Options | `ChoiceGrid` (instance) | AuraMaster `settings/Filters.lua:634` | call 2 · stub 15 · test 3 | thin (1) |
| Options | `ClearScroll` (instance) | all 14 | call 22 · name-only 3 · stub 16 · test 55 | consumed (14) |
| Options | `ColorPair` (instance) | 4: AbsorbTracker, AuraMaster, KickCD, PartyFrameEnhanced; v1.77.0 adds `tooltips` beside `labels` (OptionsCompose minor 10, `options-ui-§16`): planned AbsorbTracker, in M3 of Ka0sAddonsCommonTasks `docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`, not measured | call 11 · name-only 13 · def 1 · stub 11 · test 14 | consumed (4) |
| Options | `CreateOptionsPanel` (instance) | all 14 | call 14 · name-only 5 · stub 23 · test 47 | consumed (14) |
| Options | `CreatePanel` (instance) | all 14 | call 43 · name-only 8 · def 1 · stub 15 · test 91 | consumed (14) |
| Options | `Drawer` (instance) | QuickComms `settings/Groups_When.lua:653` | call 0 · name-only 1 · stub 16 · test 13 | thin (1, read by hand) |
| Options | `EnsureDefaultsButton` (instance) | WhatGroup `settings/OptionsSetup.lua:287` | call 1 · def 1 · stub 13 · test 21 | thin (1) |
| Options | `EnsureScroll` (instance) | 11: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PanelMaster, PremadeGroupsFilterExtension, PrettyChat, WhatGroup | call 36 · name-only 14 · def 1 · stub 21 · test 24 | consumed (11) |
| Options | `FONT_FLAGS` (instance) | none | call 0 · name-only 1 · stub 4 · test 14 | zero — deliberate host copy |
| Options | `FONT_FLAGS_SORT` (instance) | none | call 0 · stub 3 · test 12 | zero — deliberate host copy |
| Options | `FontGroup` (instance) | 4: AbsorbTracker, AuraMaster, KickCD, PartyFrameEnhanced; v1.77.0 adds `tooltips` beside `labels` (OptionsCompose minor 10, `options-ui-§16`): planned AbsorbTracker, in M3 of Ka0sAddonsCommonTasks `docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`, not measured | call 9 · name-only 5 · def 1 · stub 11 · test 12 | consumed (4) |
| Options | `ID_NAME_HINT` (instance) | none | call 0 · stub 17 · test 3 | zero — kept, documented |
| Options | `IdInput` (instance) | KickCD `settings/Spells_Header.lua:228` | call 1 · name-only 1 · stub 15 · test 19 | thin (1) |
| Options | `IdList` (instance) | AuraMaster `settings/Filters.lua:809`; BankLedger `settings/Panel.lua:389`; LootHistory `settings/Panel.lua:338` | call 4 · name-only 1 · stub 18 · test 98 | consumed (3) |
| Options | `InlineButtonPair` (instance) | 5: AuraMaster, BankLedger, MultiMeters, PanelMaster, PremadeGroupsFilterExtension | call 10 · name-only 11 · def 1 · stub 14 · test 11 | consumed (5) |
| Options | `KEYBINDS_UNCHANGED` (instance) | none yet; planned: BankLedger, DpsRace, DropWatcher, LootHistory, MultiMeters, QuickComms, WhatGroup | not measured (new at v1.77.0) | zero — planned at v1.77.0 (M2 of Ka0sAddonsCommonTasks `docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`) |
| Options | `KeybindRows` (instance) | none yet; planned: BankLedger, DpsRace, DropWatcher, LootHistory, MultiMeters, QuickComms, WhatGroup | not measured (new at v1.77.0) | zero — planned at v1.77.0 (M2 of Ka0sAddonsCommonTasks `docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`) |
| Options | `KeybindingsTab` (instance) | none yet; planned: BankLedger, DpsRace, DropWatcher, LootHistory, MultiMeters, QuickComms, WhatGroup | not measured (new at v1.77.0) | zero — planned at v1.77.0 (M2 of Ka0sAddonsCommonTasks `docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`) |
| Options | `LSMValues` (instance) | AbsorbTracker `settings/Appearance.lua:188`; MultiMeters `settings/Schema_Compose.lua:394` | call 2 · name-only 1 · def 1 · stub 11 · test 36 | thin (2) |
| Options | `MASTER_GROUP` (instance) | 10: AbsorbTracker, AuraMaster, DropWatcher, KickCD, LootHistory, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 11 · name-only 2 · stub 9 · test 37 | consumed (10) |
| Options | `MasterControls` (instance) | 9: AbsorbTracker, AuraMaster, DropWatcher, KickCD, LootHistory, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, WhatGroup; v1.77.0 (OptionsCompose minor 9, `options-ui-§15`, M3 of Ka0sAddonsCommonTasks `docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`, not measured): `notes` planned BankLedger, ConsumableMaster, LootHistory, WhatGroup; `lockIsPreview` planned AbsorbTracker, ConsumableMaster, KickCD, PartyFrameEnhanced; `resetPositionTooltip` available, adoption per each addon's LY item; the *Master opacity* label and the frameless packing reach every consumer at its RV2 | call 9 · name-only 6 · def 1 · stub 19 · test 45 | consumed (9) |
| Options | `NavRail` (instance) | AuraMaster `settings/OptionsSetup.lua:614`; KickCD `settings/Panel_Render.lua:346`; MultiMeters `settings/OptionsSetup.lua:613` | call 3 · stub 21 · test 20 | consumed (3) |
| Options | `OpenOptionsPanel` (instance) | 10: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 13 · name-only 19 · stub 15 · test 154 | consumed (10) |
| Options | `PADDING_X` (instance) | PanelMaster `settings/Panel.lua:495` | call 2 · stub 2 · test 27 | thin (1) |
| Options | `PageBanner` (instance) | AuraMaster `settings/OptionsSetup.lua:450`; KickCD `settings/Panel_Render.lua:113`; MultiMeters `settings/Windows.lua:224` | call 4 · name-only 3 · stub 15 · test 34 | consumed (3) |
| Options | `PageHeader` (instance) | AbsorbTracker `settings/UnitPanel.lua:269`; KickCD `settings/Spells.lua:672`; PanelMaster `settings/PanelEditor.lua:500` | call 4 · name-only 1 · stub 17 · test 21 | consumed (3) |
| Options | `PatchAlwaysShowScrollbar` (instance) | none | call 0 · stub 11 · test 20 | zero — kept, documented |
| Options | `ROW_VSPACER` (instance) | 6: AbsorbTracker, AuraMaster, BankLedger, PanelMaster, PrettyChat, WhatGroup | call 10 · name-only 3 · stub 7 · test 39 | consumed (6) |
| Options | `RefreshAllPanels` (instance) | 7: AbsorbTracker, AuraMaster, BankLedger, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced | call 22 · name-only 12 · def 1 · stub 13 · test 129 | consumed (7) |
| Options | `RefreshPanel` (instance) | 11: AuraMaster, BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 27 · name-only 9 · stub 11 · test 28 | consumed (11) |
| Options | `RefreshScalars` (instance) | 10: AuraMaster, BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 19 · name-only 4 · def 1 · stub 12 · test 29 | consumed (10) |
| Options | `RegisterOptionsPage` (instance) | all 14 | call 26 · name-only 34 · def 3 · stub 16 · test 15 | consumed (14) |
| Options | `RenderField` (instance) | PanelMaster `settings/Panel.lua:160`; PremadeGroupsFilterExtension `settings/Panel.lua:157`; PrettyChat `settings/Panel.lua:463` | call 6 · name-only 4 · def 1 · stub 13 · test 32 | consumed (3) |
| Options | `RenderGrid` (instance) | 4: AuraMaster, ConsumableMaster, KickCD, MultiMeters | call 16 · name-only 19 · stub 13 · test 20 | consumed (4) |
| Options | `RenderRows` (instance) | 4: AuraMaster, KickCD, LootHistory, MultiMeters | call 16 · name-only 11 · stub 13 · test 46 | consumed (4) |
| Options | `RenderSchema` (instance) | none | call 0 · stub 16 · test 24 | zero — kept, documented |
| Options | `RenderTabbedSchema` (instance) | 12: AbsorbTracker, AuraMaster, BankLedger, DropWatcher, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 17 · name-only 2 · stub 21 · test 46 | consumed (12) |
| Options | `ResetAllTooltip` (instance) | none measured yet; planned (7), each landed on its master: BankLedger `settings/Panel.lua:743`; DropWatcher `settings/Panel.lua:88`; LootHistory `settings/Panel.lua:1152`; PremadeGroupsFilterExtension `settings/Panel.lua:379`; PrettyChat `settings/Panel.lua:799`; QuickComms `settings/Panel.lua:114`; WhatGroup `settings/Panel.lua:326` (a General page's header Defaults tooltip). MultiMeters is not one: its General Defaults is a page reset | not measured (new at v1.77.0) | zero — planned at v1.77.0 (M3 of Ka0sAddonsCommonTasks `docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`) |
| Options | `ResolveId` (instance) | AuraMaster `settings/GeneralSpells.lua:725` | call 1 · name-only 1 · stub 17 · test 8 | thin (1) |
| Options | `RestoreAllDefaults` (instance) | 10: AbsorbTracker, AuraMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 19 · name-only 5 · def 4 · stub 15 · test 150 | consumed (10) |
| Options | `RestoreDefaults` (instance) | 6: AbsorbTracker, AuraMaster, DropWatcher, KickCD, MultiMeters, PartyFrameEnhanced | call 11 · name-only 8 · def 5 · stub 8 · test 151 | consumed (6) |
| Options | `SECTION_HEADING_H` (instance) | PanelMaster `settings/Panel.lua:58` | call 1 · name-only 1 · stub 6 · test 24 | thin (1) |
| Options | `Section` (instance) | 4: AuraMaster, ConsumableMaster, MultiMeters, PremadeGroupsFilterExtension | call 15 · name-only 13 · def 2 · stub 13 · test 50 | consumed (4) |
| Options | `SelectTab` (instance) | AuraMaster `settings/Filters.lua:362`; KickCD `settings/Panel_Render.lua:404`; MultiMeters `settings/OptionsSetup.lua:660` | call 4 · name-only 11 · def 6 · stub 21 · test 165 | consumed (3) |
| Options | `SessionCheckbox` (instance) | ConsumableMaster `settings/Panel.lua:701`; KickCD `settings/Panel_Widgets.lua:43` | call 2 · stub 13 · test 18 | thin (2) |
| Options | `SetChromeHeight` (instance) | none | call 0 · stub 15 · test 4 | zero — kept, documented |
| Options | `SetRenderer` (instance) | 13: AbsorbTracker, AuraMaster, BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 36 · name-only 7 · def 1 · stub 16 · test 39 | consumed (13) |
| Options | `StrataTooltip` (instance) | none yet; planned: AuraMaster, MultiMeters, PanelMaster, PartyFrameEnhanced | not measured (new at v1.77.0) | zero — planned at v1.77.0 (M2 of Ka0sAddonsCommonTasks `docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`) |
| Options | `SubTabStrip` (instance) | BankLedger `settings/Panel.lua:454`; LootHistory `settings/Panel.lua:467` | call 2 · name-only 1 · stub 13 · test 5 | thin (2) |
| Options | `TAB_H` (instance) | none | call 0 · name-only 5 · stub 5 · test 20 | zero — kept, documented |
| Options | `TabStrip` (instance) | 5: KickCD, LootHistory, MultiMeters, PanelMaster, PrettyChat | call 8 · name-only 5 · stub 18 · test 68 | consumed (5) |
| Options | `TextRow` (instance) | 5: AuraMaster, BankLedger, MultiMeters, PremadeGroupsFilterExtension, PrettyChat | call 42 · name-only 37 · stub 8 · test 20 | consumed (5) |
| Options | `UnnamedCandidates` (instance) | none | call 0 · stub 16 · test 1 | zero — kept, documented |
| Options | `VISIBILITY_SORT` (instance) | none | call 0 · stub 3 · test 12 | zero — deliberate host copy |
| Options | `VISIBILITY_VALUES` (instance) | none | call 0 · stub 3 · test 12 | zero — deliberate host copy |
| Options | `addonName` (descriptor) | all 14 | call 14 | consumed (14) |
| Options | `afterRestoreAll` (descriptor) | none | call 0 | zero — kept, documented |
| Options | `allRows` (descriptor) | 13: AbsorbTracker, AuraMaster, BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 13 | consumed (13) |
| Options | `applyDefault` (descriptor) | 13: AbsorbTracker, AuraMaster, BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 13 | consumed (13) |
| Options | `buildMain` (descriptor) | all 14 | call 14 | consumed (14) |
| Options | `bulkBegin` (descriptor) | 12: AbsorbTracker, AuraMaster, BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 12 | consumed (12) |
| Options | `bulkEnd` (descriptor) | 12: AbsorbTracker, AuraMaster, BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 12 | consumed (12) |
| Options | `colorDecode` (descriptor) | 7: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, MultiMeters, PartyFrameEnhanced, QuickComms | call 7 | consumed (7) |
| Options | `colorEncode` (descriptor) | 7: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, MultiMeters, PartyFrameEnhanced, QuickComms | call 7 | consumed (7) |
| Options | `debug` (descriptor) | all 14 | call 14 | consumed (14) |
| Options | `get` (descriptor) | all 14 | call 14 | consumed (14) |
| Options | `getLSM` (descriptor) | 8: AbsorbTracker, AuraMaster, ConsumableMaster, DropWatcher, KickCD, MultiMeters, PartyFrameEnhanced, QuickComms | call 8 | consumed (8) |
| Options | `mainPanelName` (descriptor) | all 14 | call 14 | consumed (14) |
| Options | `onAceGUI` (descriptor) | 7: AbsorbTracker, AuraMaster, BankLedger, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced | call 7 | consumed (7) |
| Options | `parentTitle` (descriptor) | all 14 | call 14 | consumed (14) |
| Options | `print` (descriptor) | all 14 | call 14 | consumed (14) |
| Options | `resetProfile` (descriptor) | all 14 | call 14 | consumed (14) |
| Options | `rowsForPage` (descriptor) | all 14 | call 14 | consumed (14) |
| Options | `scheduleTimer` (descriptor) | 11: AbsorbTracker, AuraMaster, BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms | call 11 | consumed (11) |
| Options | `set` (descriptor) | all 14 | call 14 | consumed (14) |
| Options | `skipRestoreAll` (descriptor) | 13: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 13 | consumed (13) |
| Options | `sliderCommit` (descriptor) | ConsumableMaster `settings/OptionsSetup.lua:271` | call 1 | thin (1) |
| Options | `validate` (descriptor) | 12: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 12 | consumed (12) |
| Perf | `lib.DEFAULT_RING` | none | call 0 · test 2 | zero — kept, documented |
| Perf | `lib.EncodeJSON` | none | call 0 · test 14 | zero — kept, documented |
| Perf | `lib.New` | 9: AbsorbTracker, AuraMaster, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 9 · name-only 162 · def 23 · stub 19 · test 816 | consumed (9) |
| Perf | `lib.SCHEMA` | none | call 0 · stub 1 · test 24 | zero — kept, documented |
| Perf | `lib.STRINGS` | none | call 0 · name-only 1 · stub 4 · test 150 | zero — kept, documented |
| Perf | `Announce` (instance) | none | call 0 · name-only 3 · def 1 · test 20 | zero — kept, documented |
| Perf | `BuildRecord` (instance) | none | call 0 · name-only 1 · def 1 · test 21 | zero — kept, documented |
| Perf | `Cancel` (instance) | none | call 0 · name-only 68 · def 5 · test 88 | zero — kept, documented |
| Perf | `Close` (instance) | none | call 0 · name-only 18 · def 5 · stub 2 · test 87 | zero — kept, documented |
| Perf | `Context` (instance) | none | call 0 · name-only 12 · def 1 · test 12 | zero — kept, documented |
| Perf | `ContextLines` (instance) | none | call 0 | zero — kept, documented |
| Perf | `EXPERIMENTS` (instance) | none | call 0 | zero — kept, documented |
| Perf | `EncodeJSON` (instance) | none | call 0 · test 14 | zero — kept, documented |
| Perf | `FormatReport` (instance) | none | call 0 · test 3 | zero — kept, documented |
| Perf | `HidePanel` (instance) | none | call 0 · name-only 4 · test 31 | zero — kept, documented |
| Perf | `IsPanelShown` (instance) | none | call 0 · name-only 4 · test 30 | zero — kept, documented |
| Perf | `LABELS` (instance) | none | call 0 · name-only 8 · test 14 | zero — kept, documented |
| Perf | `Log` (instance) | none | call 0 · name-only 3 · def 1 · test 17 | zero — kept, documented |
| Perf | `MarkReviewed` (instance) | none | call 0 · test 1 | zero — kept, documented |
| Perf | `Measure` (instance) | none | call 0 · name-only 1 · test 6 | zero — kept, documented |
| Perf | `Note` (instance) | 9: AbsorbTracker, AuraMaster, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 80 · name-only 10 · def 3 · stub 9 · test 155 | consumed (9) |
| Perf | `OnCommand` (instance) | 9: AbsorbTracker, AuraMaster, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 11 · def 3 · stub 10 · test 34 | consumed (9) |
| Perf | `Open` (instance) | none | call 0 · name-only 39 · def 14 · stub 3 · test 357 | zero — kept, documented |
| Perf | `PanelIsActionable` (instance) | none | call 0 | zero — kept, documented |
| Perf | `PanelStateOf` (instance) | none | call 0 · test 2 | zero — kept, documented |
| Perf | `Progress` (instance) | none | call 0 | zero — kept, documented |
| Perf | `RefreshPanel` (instance) | none | call 0 · name-only 36 · stub 11 · test 28 | zero — kept, documented |
| Perf | `Reset` (instance) | none | call 0 · name-only 4 · def 4 · stub 8 · test 451 | zero — kept, documented |
| Perf | `Resume` (instance) | none | call 0 · name-only 12 · def 15 · test 77 | zero — kept, documented |
| Perf | `SCHEMA` (instance) | none | call 0 · stub 1 · test 24 | zero — kept, documented |
| Perf | `STEPS` (instance) | none | call 0 · test 13 | zero — kept, documented |
| Perf | `Save` (instance) | none | call 0 · name-only 3 · def 3 · test 111 | zero — kept, documented |
| Perf | `ShowPanel` (instance) | none | call 0 · name-only 5 · test 27 | zero — kept, documented |
| Perf | `Start` (instance) | none | call 0 · name-only 12 · def 10 · test 181 | zero — kept, documented |
| Perf | `StatusLines` (instance) | none | call 0 · test 1 | zero — kept, documented |
| Perf | `Stop` (instance) | none | call 0 · name-only 43 · def 10 · test 123 | zero — kept, documented |
| Perf | `Suspend` (instance) | none | call 0 · name-only 4 · def 15 · test 101 | zero — kept, documented |
| Perf | `TogglePanel` (instance) | none | call 0 · name-only 3 · test 1 | zero — kept, documented |
| Perf | `Usage` (instance) | none | call 0 · test 47 | zero — kept, documented |
| Perf | `armed` (instance) | ConsumableMaster `core/Diagnostics.lua:137` | call 1 · name-only 6 · def 1 · stub 1 · test 432 | thin (1) |
| Perf | `context` (instance) | none | call 0 · name-only 2 · def 2 · test 200 | zero — kept, documented |
| Perf | `descriptor` (instance) | none | call 0 · stub 10 · test 761 | zero — kept, documented |
| Perf | `label` (instance) | ConsumableMaster `core/Diagnostics.lua:137` | call 1 · name-only 371 · def 2 · stub 13 · test 2731 | thin (1) |
| Perf | `name` (instance) | none | call 0 · name-only 439 · def 3 · stub 104 · test 7587 | zero — kept, documented |
| Perf | `on` (instance) | 9: AbsorbTracker, AuraMaster, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 76 · name-only 7 · def 1 · stub 290 · test 9498 | consumed (9) |
| Perf | `recording` (instance) | ConsumableMaster `core/Diagnostics.lua:137` | call 1 · stub 3 · test 147 | thin (1) |
| Perf | `ringMax` (instance) | none | call 0 | zero — kept, documented |
| Perf | `run` (instance) | ConsumableMaster `core/Diagnostics.lua:137` | call 1 · name-only 20 · def 25 · stub 14 · test 1489 | thin (1) |
| Perf | `slash` (instance) | none | call 0 · name-only 3 · stub 75 · test 1445 | zero — kept, documented |
| Perf | `title` (instance) | none | call 0 · name-only 108 · def 7 · stub 2 · test 729 | zero — kept, documented |
| Perf | `L` (descriptor) | none | call 0 | zero — kept, documented |
| Perf | `addonName` (descriptor) | 9: AbsorbTracker, AuraMaster, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 9 | consumed (9) |
| Perf | `buckets` (descriptor) | 9: AbsorbTracker, AuraMaster, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 9 | consumed (9) |
| Perf | `decorate` (descriptor) | none | call 0 | zero — kept, documented |
| Perf | `lifecycle` (descriptor) | 9: AbsorbTracker, AuraMaster, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 9 | consumed (9) |
| Perf | `log` (descriptor) | 9: AbsorbTracker, AuraMaster, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 9 | consumed (9) |
| Perf | `name` (descriptor) | 9: AbsorbTracker, AuraMaster, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 9 | consumed (9) |
| Perf | `onChange` (descriptor) | none | call 0 | zero — kept, documented |
| Perf | `print` (descriptor) | 9: AbsorbTracker, AuraMaster, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 9 | consumed (9) |
| Perf | `ring` (descriptor) | none | call 0 | zero — kept, documented |
| Perf | `showLog` (descriptor) | 9: AbsorbTracker, AuraMaster, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 9 | consumed (9) |
| Perf | `slash` (descriptor) | 9: AbsorbTracker, AuraMaster, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 9 | consumed (9) |
| Perf | `sv` (descriptor) | 9: AbsorbTracker, AuraMaster, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 9 | consumed (9) |
| Perf | `title` (descriptor) | 9: AbsorbTracker, AuraMaster, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 9 | consumed (9) |
| Perf | `version` (descriptor) | 9: AbsorbTracker, AuraMaster, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 9 | consumed (9) |
| Sim | `lib.New` | BankLedger `modules/Sim.lua:344`; DropWatcher `modules/Sim.lua:275`; LootHistory `modules/Sim.lua:324` | call 3 · name-only 168 · def 23 · stub 19 · test 816 | consumed (3); MultiMeters and KickCD planned at v1.76.0 (MultiMeters#60, KickCD#38), counts unchanged until they land |
| Sim | `lib.NewSeam` | BankLedger `core/SimSetup.lua:98`; DropWatcher `core/SimSetup.lua:87`; LootHistory `core/SimSeam.lua:120` | call 3 · test 4 | consumed (3); MultiMeters and KickCD planned at v1.76.0 (MultiMeters#60, KickCD#38), counts unchanged until they land |
| Sim | `lib.STRINGS` | none | call 0 · name-only 1 · stub 4 · test 150 | zero — kept, documented |
| Sim | `AddListener` (instance) | BankLedger `core/SimSetup.lua:82`; LootHistory `modules/SimPanel.lua:111` | call 3 · name-only 2 | thin (2) |
| Sim | `After` (instance) | BankLedger `core/SimSetup.lua:55`; DropWatcher `modules/SimPool.lua:351` | call 4 · name-only 38 · def 4 · stub 1 · test 123 | thin (2) |
| Sim | `DeliverForCleanup` (instance) | DropWatcher `modules/SimEvents.lua:513` | call 2 · def 3 · test 2 | thin (1) |
| Sim | `Fire` (instance) | BankLedger `core/SimSetup.lua:55`; DropWatcher `modules/Sim.lua:184`; LootHistory `modules/SimDrivers.lua:41` | call 21 · name-only 7 · def 4 · test 112 | consumed (3) |
| Sim | `HidePanel` (instance) | DropWatcher `modules/SimPanel.lua:134` | call 2 · name-only 2 · test 31 | thin (1, read by hand) |
| Sim | `IsActive` (instance) | BankLedger `core/Database.lua:574`; DropWatcher `core/DropWatcher.lua:161`; LootHistory `modules/Browser.lua:541` | call 23 · name-only 9 · def 7 · test 107 | consumed (3) |
| Sim | `IsDelivering` (instance) | BankLedger `core/SimSetup.lua:76`; DropWatcher `modules/History.lua:636`; LootHistory `modules/Sim.lua:165` | call 5 · name-only 2 · test 8 | consumed (3) |
| Sim | `IsPanelShown` (instance) | DropWatcher `modules/SimScenario.lua:197` | call 2 · name-only 2 · test 30 | thin (1, read by hand) |
| Sim | `Keys` (instance) | BankLedger `modules/Diagnostics.lua:92`; LootHistory `modules/Diagnostics.lua:369` | call 0 · name-only 4 · def 5 · test 43 | thin (2, read by hand) |
| Sim | `Live` (instance) | BankLedger `modules/SimWorld.lua:115`; DropWatcher `modules/LootFeed.lua:580`; LootHistory `modules/Sim.lua:185` | call 0 · name-only 16 · def 4 · test 49 | consumed (3, read by hand) |
| Sim | `OnStop` (instance) | BankLedger `core/SimSetup.lua:82`; DropWatcher `modules/Sim.lua:354`; LootHistory `modules/Sim.lua:395` | call 6 · name-only 2 · test 2 | consumed (3) |
| Sim | `OnStopGuarded` (instance) | BankLedger `core/SimSetup.lua:82`; DropWatcher `modules/Sim.lua:306` | call 3 · name-only 2 · test 1 | thin (2) |
| Sim | `PanelRows` (instance) | none | call 0 · def 3 · test 20 | zero — kept, documented |
| Sim | `Pause` (instance) | none | call 1 · name-only 3 · def 1 · test 3 | zero — kept, documented (read by hand) |
| Sim | `RefreshPanel` (instance) | none | call 1 · name-only 35 · stub 11 · test 28 | zero — kept, documented (read by hand) |
| Sim | `ResetPanelPosition` (instance) | DropWatcher `modules/Window.lua:861` | call 2 · name-only 2 · test 4 | thin (1, read by hand) |
| Sim | `Restart` (instance) | none | call 1 · name-only 2 · test 7 | zero — kept, documented (read by hand) |
| Sim | `Resume` (instance) | none | call 1 · name-only 11 · def 15 · test 77 | zero — kept, documented (read by hand) |
| Sim | `Run` (instance) | none | call 1 · name-only 15 · def 5 · stub 3 · test 265 | zero — kept, documented (read by hand) |
| Sim | `RunVerb` (instance) | BankLedger `settings/Schema.lua:902`; DropWatcher `settings/Slash.lua:87`; LootHistory `settings/Schema.lua:1143` | call 3 · def 3 · test 13 | consumed (3) |
| Sim | `Session` (instance) | BankLedger `core/SimSetup.lua:50`; DropWatcher `modules/Sim.lua:86` | call 21 · name-only 8 · def 4 · test 32 | thin (2) |
| Sim | `SetProvider` (instance) | BankLedger `modules/SimWorld.lua:391`; DropWatcher `modules/Sim.lua:218`; LootHistory `modules/SimWorld.lua:475` | call 0 · name-only 5 · def 3 · test 19 | consumed (3, read by hand) |
| Sim | `ShowPanel` (instance) | BankLedger `core/SimSetup.lua:89`; DropWatcher `modules/SimScenario.lua:197` | call 3 · name-only 2 · test 27 | thin (2) |
| Sim | `Start` (instance) | DropWatcher `modules/SimScenario.lua:228` | call 1 · name-only 11 · def 10 · test 181 | thin (1) |
| Sim | `Status` (instance) | BankLedger `modules/Diagnostics.lua:104`; DropWatcher `modules/Sim.lua:123`; LootHistory `modules/Browser.lua:551` | call 10 · name-only 6 · def 8 · test 92 | consumed (3) |
| Sim | `Step` (instance) | none | call 0 · name-only 3 · def 3 · test 71 | zero — kept, documented |
| Sim | `Steps` (instance) | BankLedger `modules/Sim.lua:164`; DropWatcher `modules/Diagnostics.lua:382`; LootHistory `modules/Sim.lua:287` | call 9 · def 4 · stub 1 · test 16 | consumed (3) |
| Sim | `Stop` (instance) | BankLedger `core/BankLedger.lua:258`; DropWatcher `modules/Sim.lua:364`; LootHistory `modules/Sim.lua:168` | call 10 · name-only 33 · def 10 · test 123 | consumed (3) |
| Sim | `TogglePanel` (instance) | none | call 1 · name-only 2 · test 1 | zero — kept, documented (read by hand) |
| Sim | `Unwrapped` (instance) | none | call 0 · def 3 · test 13 | zero — kept, documented |
| Sim | `L` (descriptor) | BankLedger `modules/Sim.lua:358`; DropWatcher `modules/Sim.lua:295`; LootHistory `modules/Sim.lua:341` | call 3 | consumed (3) |
| Sim | `addonName` (descriptor) | none | call 0 | zero — kept, documented |
| Sim | `check` (descriptor) | BankLedger `modules/Sim.lua:304`; DropWatcher `modules/SimPanel.lua:129`; LootHistory `modules/SimPanel.lua:108` | call 0 | consumed (3, read by hand) |
| Sim | `close` (descriptor) | none | call 0 | zero — kept, documented |
| Sim | `debug` (descriptor) | BankLedger `modules/Sim.lua:360`; DropWatcher `modules/Sim.lua:297`; LootHistory `modules/Sim.lua:343` | call 3 | consumed (3) |
| Sim | `deliver` (descriptor) | BankLedger `modules/Sim.lua:349`; DropWatcher `modules/Sim.lua:279`; LootHistory `modules/Sim.lua:328` | call 3 | consumed (3) |
| Sim | `footer` (descriptor) | none | call 0 | zero — kept, documented |
| Sim | `gate` (descriptor) | BankLedger `modules/Sim.lua:355`; LootHistory `modules/Sim.lua:334` | call 2 | thin (2) |
| Sim | `isStoodDown` (descriptor) | BankLedger `modules/Sim.lua:350`; DropWatcher `modules/Sim.lua:280`; LootHistory `modules/Sim.lua:329` | call 3 | consumed (3) |
| Sim | `name` (descriptor) | BankLedger `modules/Sim.lua:345`; DropWatcher `modules/Sim.lua:276`; LootHistory `modules/Sim.lua:325` | call 3 | consumed (3) |
| Sim | `onClick` (descriptor) | none | call 0 | zero — kept, documented |
| Sim | `panel` (descriptor) | BankLedger `modules/Sim.lua:361`; DropWatcher `modules/Sim.lua:293`; LootHistory `modules/Sim.lua:339` | call 3 | consumed (3) |
| Sim | `play` (descriptor) | BankLedger `modules/Sim.lua:353`; DropWatcher `modules/Sim.lua:287`; LootHistory `modules/Sim.lua:332` | call 3 | consumed (3) |
| Sim | `prepare` (descriptor) | BankLedger `modules/Sim.lua:352`; DropWatcher `modules/Sim.lua:283`; LootHistory `modules/Sim.lua:331` | call 3 | consumed (3) |
| Sim | `print` (descriptor) | BankLedger `modules/Sim.lua:359`; DropWatcher `modules/Sim.lua:296`; LootHistory `modules/Sim.lua:342` | call 3 | consumed (3) |
| Sim | `refusal` (descriptor) | BankLedger `modules/Sim.lua:354`; DropWatcher `modules/Sim.lua:281`; LootHistory `modules/Sim.lua:333` | call 3 | consumed (3) |
| Sim | `rows` (descriptor) | none | call 0 | zero — kept, documented |
| Sim | `scenarios` (descriptor) | BankLedger `modules/Sim.lua:351`; DropWatcher `modules/Sim.lua:282`; LootHistory `modules/Sim.lua:330` | call 3 | consumed (3) |
| Sim | `seam` (descriptor) | BankLedger `modules/Sim.lua:346`; DropWatcher `modules/Sim.lua:277`; LootHistory `modules/Sim.lua:326` | call 3 | consumed (3) |
| Sim | `slash` (descriptor) | BankLedger `modules/Sim.lua:347`; DropWatcher `modules/Sim.lua:278`; LootHistory `modules/Sim.lua:327` | call 3 | consumed (3) |
| Sim | `statusLine` (descriptor) | DropWatcher `modules/Sim.lua:292` | call 1 | thin (1) |
| Sim | `stepDelay` (descriptor) | BankLedger `modules/Sim.lua:356`; DropWatcher `modules/Sim.lua:288`; LootHistory `modules/Sim.lua:335` | call 3 | consumed (3) |
| Sim | `stopText` (descriptor) | BankLedger `modules/Sim.lua:357`; DropWatcher `modules/Sim.lua:294`; LootHistory `modules/Sim.lua:340` | call 3 | consumed (3) |
| Sim | `title` (descriptor) | BankLedger `modules/Sim.lua:291`; DropWatcher `modules/SimPanel.lua:118`; LootHistory `modules/SimPanel.lua:97` | call 0 | consumed (3, read by hand) |
| Sim | `tooltip` (descriptor) | none | call 0 | zero — kept, documented |
| Sim | `usage` (descriptor) | DropWatcher `modules/Sim.lua:291`; LootHistory `modules/Sim.lua:338` | call 2 | thin (2) |
| Sim | `verbs` (descriptor) | DropWatcher `modules/Sim.lua:289`; LootHistory `modules/Sim.lua:336` | call 2 | thin (2) |
| Sim | `why` (descriptor) | DropWatcher `modules/Sim.lua:290`; LootHistory `modules/Sim.lua:337` | call 2 | thin (2) |

## Re-running it

From this repo's root, with every addon checked out as a sibling:

```sh
/home/tushar/.claude/dev-copilot/bin/ka0s-bounded \
  lua ../Ka0sAddonsCommonTasks/docs/2026-10-02-LIBKA0S_CENSUS_ADOPTION/plan-data/census.lua \
      .. <output folder>
```

At v1.75.0 that was the copy in `../Ka0sAddonsCommonTasks/docs/2026-10-22-LIBKA0S_ISSUES_45_58/plan-data/census-v1.75.0/`,
with that folder as the output; write a new run's output to a folder of its own, never into a
frozen bundle. Render from inside the output folder with
`lua census-render.lua table|zero|doclines . <stamp> <roster size>`.

The scan takes about three minutes. Then read every export whose verdict moved, every new export,
and every call hit that sits in a host's degradation stub, and update `verdicts.tsv` and this page
together. The tool classifies hits, but only reading the code settles
a verdict.
