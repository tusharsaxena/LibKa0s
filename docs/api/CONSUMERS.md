# Who calls what: the LibKa0s consumer census

**Stamped v1.83.0** (tag `v1.83.0`, at `6c816fd`), re-measured 2026-10-31 across the sixteen addons
in `WowAddonStandards/standards/ADDONS.md`, each as checked out that day with v1.83.0 vendored: DpsRace on its own feature
branch, the others on or about to take `feat/2026-10-31-findings-remediation`. That run is `FX-LK-DOCS` of
`Ka0sAddonsCommonTasks/docs/2026-10-31-FINDINGS_REMEDIATION`. Ka0s DPS Race and Ka0s Skin Tester are new to the census
since v1.75.0, and v1.76.0 to v1.82.0 were never measured, so this run is also their first.

The v1.75.0 run was taken on 2026-10-23 across fourteen addons (item `LK-23` of
`Ka0sAddonsCommonTasks/docs/2026-10-22-LIBKA0S_ISSUES_45_58`), the v1.71.0 run on 2026-10-07 across eleven, the v1.70.0
run earlier the same day and the v1.69.0 run on 2026-10-06. The v1.67.0 run was taken by item
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

590 public exports across nineteen majors: 186 lib-level members, 225 instance members and 179
descriptor fields, all of them measured at v1.83.0.

| Verdict | Exports | Meaning |
|---|---|---|
| consumed | 321 | Called, or passed, by three or more hosts |
| thin | 99 | One or two hosts. A misfit found by the next host is a library gap on first contact |
| **zero** | **170** | No host calls it. Each one is split below |

Thirty-three of the 590 verdicts were set by reading the code where the scan could not see, or saw
wrong; each is marked *read by hand* in its row and explained under [Method](#method), step 5.

The 170 zero-consumer exports:

| Split | Exports | What happens |
|---|---|---|
| host duplicate | 0 | None at v1.83.0. Widgets `lib.Autocomplete`, the one at the v1.70.0 tag, has been thin (2) since v1.71.0: LootHistory and BankLedger both adopted it, and LootHistory's Timeline no longer hand-rolls its own list. None of the eight from v1.66.0 is left either: seven were adopted, and Options `lib.LAYOUT` left the split when KickCD deleted its two header copies instead of reading them; it is now documented (see [What moved since v1.66.0](#what-moved-since-v1660)) |
| suspect shape | 0 | Both from v1.66.0 were settled at v1.67.0: Core 10 gave `MakeResizable` its lock gate ([#41](https://github.com/tusharsaxena/LibKa0s/issues/41)), and every host now passes the Options descriptor's `addonName` ([#42](https://github.com/tusharsaxena/LibKa0s/issues/42)) |
| deliberate host copy | 5 | A host keeps its own copy on purpose, with the reason recorded beside it. Listed, not re-opened |
| documented | 165 | No duplicate and no host waiting for it. Each gets a "no consumer as of vX, kept because ..." line in its major's live document, stamped with the census that first recorded it: v1.67.0 for the earlier ones, v1.69.0 for the line-chart exports, v1.70.0 for `lib.AUTOCOMPLETE`, v1.75.0 for the sixteen Sim exports |

Most of the 165 fall into four groups. The rows below give each export's own reason.

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

**v1.83.0 re-run (2026-10-31).** The first re-run since v1.75.0, with the roster at sixteen. Ninety-eight
exports are new to the table and none leaves. Sixty-four of them were zero to the scan, and eighteen of those are real
calls it cannot see, marked *read by hand*: a host reaches the Skin major's `Color`, `Resolve`, `Token` and
`OnLooksChanged` on the view `Skin:For(owner)` returns, Ka0s Skin Tester reaches `GetOutline` through a guarded local, and
a Toast descriptor goes through each host's `NS.NewToast` seam, so its literal is not beside `:New(`. The other forty-six
are documented. Among the older rows, `height` and `width` on Widgets, `BANNER_H` and `LSMValues` on Options and six
Sim members rose to consumed with their new hosts. `Options.RenderSchema` left the zero set with its first host call, in
Ka0s Skin Tester. `CountOffDefault` (Schema) fell to thin (1) and `PageBanner` (Options) to thin (2): the other hosts' hits
are stubs or comments. `applySkin` on Widgets and DebugLog fell to zero, because every host left it at the skinning
rollout for the skin owner path, so the two rows are documented rather than retired. The nine rows the page carried as
*planned at v1.77.0* are measured now, and the Sim `by-hand` rows carry KickCD's and MultiMeters' sites. The entries
below stay as the record of what each release added.

**v1.83.0, first recorded (2026-10-31).** The release adds Options' `Ka0sMedia_*` AceGUI picker types
(`OptionsMedia.lua`, new at minor 1), an unregistered `LSM30_*` row's fall back to them (OptionsWidgets
minor 38), thirteen more faces (Media minor 11) and `"hud"` as `Skin.OUTLINE_DEFAULT` (Skin minor 10). No
public member is retired. What each host owes on re-vendor is the CHANGELOG's v1.83.0 *What a consumer
owes* and each document's. The addons adopted them in Ka0sAddonsCommonTasks
`docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES/`'s M2, and the re-run above measures them.

**v1.82.0, not in the census (2026-10-30).** The release adds Skin's font outline mode
(`Skin:GetOutline`, `Skin:SetOutline`, `OUTLINE_MODES`, `OUTLINE_DEFAULT`; Skin minor 9) and the paint
helpers `S.FontFlags` and `S.HudFontSize` (SkinPaintExtras minor 7), Options' `O.SkinVerb` and `shownWhen`'s
`any` form (`OptionsSwitch.lua`, new at minor 1), Widgets' `DRAG_HANDLE.FIT_SLACK` and the drag
handle's `spec.onRefit` (WidgetsDragHandle minor 8), and the test kit's display-glyph guard
(`Kit.assertDisplayGlyphs`, revision 45). What each host owes on re-vendor is the CHANGELOG's
v1.82.0 *What a consumer owes* and each document's. None gets a row here yet, and the v1.75.0 stamp
and its numbers stand: the addons adopt them in Ka0sAddonsCommonTasks
`docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK/`'s M2, and the next census re-run measures them.

**v1.81.0, not in the census (2026-10-30).** The release adds Skin's `Skin:DrawsKey` (Skin minor 8),
the public form of v1.80.0's internal `__DrawsKey`, and `S.PageButton`'s `opts` (SkinPaintControls
minor 10). It retires v1.80.0's `opts.stockDefault` (SkinPaint minor 12): the key is ignored, so a
consumer that passes it (Ka0s Quick Comms, DpsRace's custom box in `modules/Hud_States.lua`, Ka0s Skin
Tester) paints the Ka0s look under Ka0s Default until it drops the key. What each host owes on
re-vendor is the Skin and Widgets documents' *What a consumer owes*: drop `stockDefault`, handle a nil
`hud.font` / `hud.outline` while fonts are ignored (Skin minor 8), name a `ResetToSkin` companion or
pass `{ companions = true }` before dropping a seeding workaround, and give a reorder list on a
window `panel = false` (WidgetsReorder minor 3). The skin picker (OptionsSkinPicker minor 2) titles its window
`SKIN_PICKER_STRINGS.TITLE`, "Choose a skin", where `TITLE_FOR` named the addon, and puts the
addon's label on its own line, `frame.ownerLabel`. `Core.MakeResizable` takes `opts.owner` (Core
minor 14), a registered skin owner whose `icon.grip` tints the grip; the library's own windows pass
theirs, and a host's own resizable window may. None gets a row here yet, and the v1.75.0 stamp and its numbers stand: the
addons adopt them in Ka0sAddonsCommonTasks `docs/2026-10-30-SKIN_LIBRARY_FOLLOWUPS/`'s M2, and the
next census re-run measures them.

**v1.80.0, not in the census (2026-10-29).** The release adds Skin's `Skin:AliasAceType` (SkinAce
minor 4) and three opt-in surfaces with no member of their own: `RegisterOwner`'s `tokens` (owner
tokens, Skin minor 7, with `S.Text` given a token name, SkinPaintExtras minor 5), the primitives'
`opts.tokens` slot remap and `opts.stockDefault`, plus the icon border family's two tokens (SkinDefs
minor 15, drawn by `S.IconBorder`'s `fromSkin`) and `O.BorderGroup`'s `fromSkin = "icon"`
(OptionsCompose minor 13). None gets a row here yet, and the v1.75.0 stamp and its numbers stand: the
fourteen addons of Ka0sAddonsCommonTasks `docs/2026-10-29-SKINNING_ROLLOUT/` adopt them in its M2, and
the census re-run after that pass measures them with v1.78.0's and v1.79.0's exports.

**v1.79.0, not in the census (2026-10-28).** The skin half of the release adds Skin's
`Skin:GetOverride` and `Skin:SetOverride` with `Skin:WriteChoice`'s `media` (Skin minor 6), the facade
primitive `S.BarTexture` (SkinPaintExtras minor 4), the Options instance members `SkinPicker` and
`HideSkinPicker` with the lib-level `SKIN_PICKER_STRINGS` (OptionsSkinPicker minor 1),
`OpenOptionsPanel`'s `pageKey` (OptionsRegistry minor 4), seven `APPEARANCE_STRINGS` keys
(OptionsAppearance minor 3) and the Media catalog's Oxanium faces and eight generated bars (Media
minor 9). None gets a row here yet, and the v1.75.0 stamp and its numbers stand: LootHistory and
Ka0s Skin Tester adopt them (`LH-01` and `ST-01` of Ka0sAddonsCommonTasks
`docs/2026-10-28-SKIN_OVERRIDES_AND_PICKER/`), and the other consumers at the skinning adoption pass,
whose census re-run measures them all at once. The Toast half adds a major,
`LibKa0s-Toast-1.0` (`Toast:New` and seven lib-level constants in
`docs/api/Toast/members-1.json`, and the fifteen instance members of
[its document](Toast/version-1-docs.md)), promoted under
[LibKa0s#60](https://github.com/tusharsaxena/LibKa0s/issues/60). None gets a row here yet, and the
v1.75.0 stamp and its numbers stand. **No host has adopted it.** Its two intended consumers are
named so the re-run knows where to look: Ka0s DPS Race (its new-best toast, DpsRace#5, vendoring
`Toast.lua` alone beside its v1.77.0 copy until its next full re-vendor) and Ka0s Drop Watcher (its
upgrade toast, `modules/Toast.lua`, which keeps its content, qualification and combat hold). Ka0s
DPS Race is not on the roster this census measured, so its first measurement is also its first
appearance here. Both are `library-stack-§7`'s two consumers; until both call `Toast:New`, the
major's verdict is *zero — planned at v1.79.0*.

**v1.78.0, not in the census (2026-10-25).** The release adds a major, `LibKa0s-Skin-1.0`
(its members in `docs/api/Skin/members-5.13.10.3.8.1.3.json`), the Options instance members
`AppearanceTab` and `AppearanceRows` with the lib-level `APPEARANCE_STRINGS` (OptionsAppearance minor
1), Skin's `Skin:OwnerLabel` and `Skin:WriteChoice`, the Appearance tab's Scope pair `Skin:GetIgnore` and
`Skin:SetIgnore` (Skin minor 5, 2026-10-27), an `owner` option on every Widgets constructor,
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

**The v1.83.0 run** used the v1.75.0 copy of the tool unchanged, with the sixteen-addon roster it reads from `ADDONS.md`,
and rendered with `census-render.lua table|zero|doclines . v1.83.0 16`. Its data, `summary.tsv`, `hits.tsv` and the carried
`verdicts.tsv`, is in `Ka0sAddonsCommonTasks/docs/2026-10-31-FINDINGS_REMEDIATION/plan-data/census-v1.83.0/`.

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
2. **What is searched.** Every git-tracked `.lua` file of the sixteen addons, excluding `libs/` and
   `tests/_kit/`: 2033 files at v1.83.0 (1575 across fourteen at v1.75.0, 1135 across eleven at v1.71.0).
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

   **From v1.75.0 a hand-read verdict can override the scan's host set**, and thirty-three do, each
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
| Lifecycle | `Hold` (instance) | stubs only (18 stub lines across 6 hosts) | call 0 · name-only 2 · def 2 · stub 28 · test 83 | zero — kept, documented |
| Lifecycle | `PrintHolds` (instance) | stubs only | call 0 · stub 14 · test 5 | zero — kept, documented |
| Lifecycle | `Release` (instance) | stubs only; the 7 name hits are other tables' `Release` | call 0 · name-only 16 · def 7 · stub 27 · test 161 | zero — kept, documented |
| Lifecycle | `name` (instance) | instance data field | call 0 · name-only 562 · def 5 · stub 246 · test 9178 | zero — kept, documented |
| Schema | `lib.STRINGS` | no host reads the table by name | call 0 · name-only 1 · stub 5 · test 169 | zero — kept, documented |
| Toast | `lib.DURATION` | name-only hits are host constants of the same name | call 0 · test 1 | zero — kept, documented |
| Toast | `lib.HEIGHT` | name-only hits are host constants of the same name | call 0 · name-only 18 · test 25 | zero — kept, documented |
| Toast | `lib.MAX_QUEUE` | name-only hits are host constants of the same name | call 0 · name-only 3 · test 2 | zero — kept, documented |
| Toast | `lib.POINT` | name-only hits are host constants of the same name | call 0 · name-only 4 · stub 6 · test 16 | zero — kept, documented |
| Toast | `lib.STRATA` | name-only hits are host constants of the same name | call 0 · name-only 56 · test 90 | zero — kept, documented |
| Toast | `lib.WIDTH` | name-only hits are host constants of the same name | call 0 · name-only 14 · test 18 | zero — kept, documented |
| Toast | `soundKit` (descriptor) | no host passes it | call 0 | zero — kept, documented |
| Media | `lib.BACKGROUNDS` | no host call | call 0 | zero — kept, documented |
| Media | `lib.BORDERS` | no host call | call 0 | zero — kept, documented |
| Media | `lib.Background` | no host call | call 0 · name-only 5 · def 1 · test 77 | zero — kept, documented |
| Media | `lib.Border` | no host call | call 0 · name-only 3 · def 1 · test 130 | zero — kept, documented |
| Media | `lib.FONTS` | no host reads the table by name | call 0 · test 33 | zero — kept, documented |
| Media | `lib.TEXTURES` | no host reads the table by name | call 0 · test 5 | zero — kept, documented |
| Media | `lib.Texture` | ConsumableMaster's two `Texture` hits are its own `MacroDisplay.Texture` | call 0 · name-only 11 · def 2 · stub 2 · test 113 | zero — kept, documented |
| Media | `lib.VENDOR_PATH` | default value | call 0 · test 1 | zero — kept, documented |
| Skin | `lib.GetOverride` | no host calls it; read by hand | call 0 · test 35 | zero — kept, documented |
| Skin | `lib.GetSkin` | no host calls it; read by hand | call 0 · test 6 | zero — kept, documented |
| Skin | `lib.IsFromSkin` | no host calls it; read by hand | call 0 | zero — kept, documented |
| Skin | `lib.OUTLINE_DEFAULT` | name-only hits are unrelated host tables | call 0 · test 24 | zero — kept, documented |
| Skin | `lib.OUTLINE_MODES` | name-only hits are unrelated host tables | call 0 · test 20 | zero — kept, documented |
| Skin | `lib.OnReloadRequest` | no host calls it; read by hand | call 0 · test 8 | zero — kept, documented |
| Skin | `lib.OwnerLabel` | no host calls it; read by hand | call 0 · test 15 | zero — kept, documented |
| Skin | `lib.Owners` | no host calls it; read by hand | call 0 | zero — kept, documented |
| Skin | `lib.RegisterSkin` | no host calls it; read by hand | call 0 · test 14 | zero — kept, documented |
| Skin | `lib.Repaint` | no host calls it; read by hand | call 0 · def 1 · test 14 | zero — kept, documented |
| Skin | `lib.SCHEMA` | no host calls it; read by hand | call 0 · name-only 1 · stub 1 · test 26 | zero — kept, documented |
| Skin | `lib.SOURCES` | name-only hits are unrelated host tables | call 0 · name-only 2 · test 11 | zero — kept, documented |
| Skin | `lib.Track` | name-only and def hits are QuickComms own `Slices.Track` | call 0 · name-only 1 · def 1 · test 15 | zero — kept, documented |
| Skin | `lib.VOCAB` | stub hits are comments naming it | call 0 · stub 16 · test 9 | zero — kept, documented |
| Skin | `lib.WriteChoice` | no host calls it; read by hand | call 0 · test 61 | zero — kept, documented |
| Skin | `lib.byOwner` | name-only and stub hits are unrelated host words | call 0 · test 1 | zero — kept, documented |
| Skin | `lib.euiFacade` | name-only and stub hits are unrelated host words | call 0 | zero — kept, documented |
| Skin | `lib.euiPainted` | name-only and stub hits are unrelated host words | call 0 | zero — kept, documented |
| Skin | `lib.euiRefused` | name-only and stub hits are unrelated host words | call 0 | zero — kept, documented |
| Skin | `lib.euiRegistered` | name-only and stub hits are unrelated host words | call 0 | zero — kept, documented |
| Skin | `lib.facades` | name-only and stub hits are unrelated host words | call 0 · test 1 | zero — kept, documented |
| Skin | `lib.owners` | name-only and stub hits are unrelated host words | call 0 · test 54 | zero — kept, documented |
| Skin | `lib.painted` | name-only and stub hits are unrelated host words | call 0 · name-only 4 · test 483 | zero — kept, documented |
| Skin | `lib.prim` | name-only and stub hits are unrelated host words | call 0 · test 10 | zero — kept, documented |
| Skin | `lib.shared` | name-only and stub hits are unrelated host words | call 0 · name-only 9 · def 2 · stub 28 · test 746 | zero — kept, documented |
| Skin | `lib.skins` | name-only and stub hits are unrelated host words | call 0 · stub 3 · test 139 | zero — kept, documented |
| Skin | `addonName` (descriptor) | not a Skin descriptor field | call 0 | zero — kept, documented |
| Skin | `thirdPartySkinAddons` (descriptor) | not a descriptor field | call 0 | zero — kept, documented |
| Skin | `thirdPartySkinsOff` (descriptor) | not a descriptor field | call 0 | zero — kept, documented |
| Widgets | `lib.AUTOCOMPLETE` | no host reads it | call 0 | zero — kept, documented |
| Widgets | `lib.ChartMath` | no host calls it; LootHistory aligns its in/out strip through the chart instance's `XToPixel` instead | call 0 · test 2 | zero — kept, documented |
| Widgets | `applySkin` (descriptor) | no host passes it since v1.80.0 | call 0 | zero — kept, documented |
| Widgets | `backdrop` (descriptor) | no `CopyWindow` descriptor passes it | call 0 | zero — kept, documented |
| Widgets | `hostBackdrop` (descriptor) | not a descriptor field | call 0 | zero — kept, documented |
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
| DebugLog | `lib.MakeCloseButton` | the 21 name hits are `Core.MakeCloseButton` calls | call 0 · name-only 36 · def 16 · stub 30 · test 145 | zero — kept, documented |
| DebugLog | `lib.STRINGS` | no host reads the table by name | call 0 · name-only 1 · stub 5 · test 169 | zero — kept, documented |
| DebugLog | `lib.TIME_COPY` | diagnostic switch | call 0 | zero — kept, documented |
| DebugLog | `BufferSize` (instance) | read by host tests only (62 hits) | call 0 · stub 13 · test 63 | zero — kept, documented |
| DebugLog | `BuildDiagnostics` (instance) | read by host tests only | call 0 · stub 19 · test 33 | zero — kept, documented |
| DebugLog | `CopyText` (instance) | read by host tests only | call 0 · stub 7 · test 23 | zero — kept, documented |
| DebugLog | `FindLine` (instance) | read by host tests only (88 hits) | call 0 · stub 13 · test 91 | zero — kept, documented |
| DebugLog | `LastLine` (instance) | read by host tests only | call 0 · stub 13 · test 51 | zero — kept, documented |
| DebugLog | `MakeCloseButton` (instance) | mirror of the lib-level member | call 0 · name-only 36 · def 16 · stub 30 · test 145 | zero — kept, documented |
| DebugLog | `Text` (instance) | the 15 name hits are `Sl:Text` (LibKa0s-Slash-1.0) calls | call 0 · name-only 172 · def 3 · stub 45 · test 387 | zero — kept, documented |
| DebugLog | `buffer` (instance) | read by host tests only (478 hits) | call 0 · stub 18 · test 537 | zero — kept, documented |
| DebugLog | `applySkin` (descriptor) | no host passes it since v1.80.0 | call 0 | zero — kept, documented |
| DebugLog | `diagnosticsEnablesLogging` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| DebugLog | `makeCloseButton` (descriptor) | BankLedger core/DebugLogSetup.lua:146 and LootHistory core/DebugLogSetup.lua:163 record why | call 0 | zero — kept, documented |
| DebugLog | `skin` (descriptor) | no descriptor passes it (MultiMeters settings/Schema_Compose.lua:248 is a locale key) | call 0 | zero — kept, documented |
| Slash | `CliResetAll` (instance) | LootHistory settings/Slash.lua:433-435 and BankLedger settings/Slash.lua:478-479 record why | call 0 · name-only 6 · def 3 · stub 10 · test 63 | zero — deliberate host copy |
| Launcher | `lib.STRINGS` | no host reads the table by name | call 0 · name-only 1 · stub 5 · test 169 | zero — kept, documented |
| Launcher | `Object` (instance) | read by host tests only (110 hits) | call 0 · stub 12 · test 116 | zero — kept, documented |
| Launcher | `L` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Options | `lib.APPEARANCE_STRINGS` | no host call | call 0 · stub 1 · test 1 | zero — kept, documented |
| Options | `lib.KEYBIND_STRINGS` | no host call | call 0 · test 9 | zero — kept, documented |
| Options | `lib.LAYOUT` | KickCD core/Constants.lua:109-116 records the deletion; no host reads the table by name | call 0 · name-only 7 · stub 1 · test 101 | zero — kept, documented |
| Options | `lib.PatchAlwaysShowScrollbar` | reached through `EnsureScroll` | call 0 · stub 13 · test 24 | zero — kept, documented |
| Options | `lib.SKIN_PICKER_STRINGS` | no host call | call 0 · test 17 | zero — kept, documented |
| Options | `lib.STRINGS` | no host reads the table by name | call 0 · name-only 1 · stub 5 · test 169 | zero — kept, documented |
| Options | `AppearanceRows` (instance) | stubs only | call 0 · def 1 · stub 27 · test 12 | zero — kept, documented |
| Options | `CHROME_GAP` (instance) | no host draws such chrome today | call 0 · name-only 3 · stub 7 · test 23 | zero — kept, documented |
| Options | `FONT_FLAGS` (instance) | MultiMeters settings/Schema_Compose.lua:165-184 records why | call 0 · name-only 1 · stub 5 · test 16 | zero — deliberate host copy |
| Options | `FONT_FLAGS_SORT` (instance) | MultiMeters settings/Schema_Compose.lua:184 | call 0 · stub 4 · test 14 | zero — deliberate host copy |
| Options | `ID_NAME_HINT` (instance) | reached through `IdInput` | call 0 · stub 21 · test 3 | zero — kept, documented |
| Options | `KeybindRows` (instance) | stubs only | call 0 · stub 28 · test 27 | zero — kept, documented |
| Options | `PatchAlwaysShowScrollbar` (instance) | reached through `EnsureScroll` | call 0 · stub 13 · test 24 | zero — kept, documented |
| Options | `SetChromeHeight` (instance) | reached through the chrome makers | call 0 · stub 17 · test 4 | zero — kept, documented |
| Options | `TAB_H` (instance) | no host measures its own strip today | call 0 · name-only 5 · stub 6 · test 27 | zero — kept, documented |
| Options | `UnnamedCandidates` (instance) | reached through `IdInput` | call 0 · stub 18 · test 1 | zero — kept, documented |
| Options | `VISIBILITY_SORT` (instance) | MultiMeters settings/Schema_Compose.lua:602-611 records why | call 0 · stub 4 · test 14 | zero — deliberate host copy |
| Options | `VISIBILITY_VALUES` (instance) | MultiMeters settings/Schema_Compose.lua:602-611 records why | call 0 · stub 4 · test 14 | zero — deliberate host copy |
| Options | `afterRestoreAll` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Perf | `lib.DEFAULT_RING` | default value | call 0 · test 2 | zero — kept, documented |
| Perf | `lib.EncodeJSON` | read by host tests only | call 0 · test 17 | zero — kept, documented |
| Perf | `lib.SCHEMA` | read by host tests only | call 0 · name-only 1 · stub 1 · test 26 | zero — kept, documented |
| Perf | `lib.STRINGS` | no host reads the table by name | call 0 · name-only 1 · stub 5 · test 169 | zero — kept, documented |
| Perf | `Announce` (instance) | reached through `OnCommand` | call 0 · name-only 3 · def 1 · test 24 | zero — kept, documented |
| Perf | `BuildRecord` (instance) | reached through `OnCommand` | call 0 · name-only 1 · def 1 · test 22 | zero — kept, documented |
| Perf | `Cancel` (instance) | reached through `OnCommand` | call 0 · name-only 88 · def 7 · test 123 | zero — kept, documented |
| Perf | `Close` (instance) | no host brackets with `Open`/`Close` | call 0 · name-only 18 · def 5 · stub 3 · test 99 | zero — kept, documented |
| Perf | `Context` (instance) | reached through `OnCommand` | call 0 · name-only 14 · def 2 · test 13 | zero — kept, documented |
| Perf | `ContextLines` (instance) | reached through `OnCommand` | call 0 | zero — kept, documented |
| Perf | `EXPERIMENTS` (instance) | library-internal table (not in the instance table) | call 0 | zero — kept, documented |
| Perf | `EncodeJSON` (instance) | read by host tests only | call 0 · test 17 | zero — kept, documented |
| Perf | `FormatReport` (instance) | reached through `OnCommand` | call 0 · test 3 | zero — kept, documented |
| Perf | `HidePanel` (instance) | reached through `OnCommand` and the panel | call 0 · name-only 6 · test 35 | zero — kept, documented |
| Perf | `IsPanelShown` (instance) | read by host tests only | call 0 · name-only 7 · test 34 | zero — kept, documented |
| Perf | `LABELS` (instance) | library-internal table (not in the instance table) | call 0 · name-only 13 · test 22 | zero — kept, documented |
| Perf | `Log` (instance) | reached through `OnCommand` | call 0 · name-only 3 · def 1 · test 17 | zero — kept, documented |
| Perf | `MarkReviewed` (instance) | reached through `OnCommand` | call 0 · test 1 | zero — kept, documented |
| Perf | `Measure` (instance) | reached through `OnCommand` | call 0 · name-only 3 · def 1 · test 10 | zero — kept, documented |
| Perf | `Open` (instance) | no host brackets with `Open`/`Close` | call 0 · name-only 43 · def 16 · stub 4 · test 420 | zero — kept, documented |
| Perf | `PanelIsActionable` (instance) | no `decorate` host | call 0 | zero — kept, documented |
| Perf | `PanelStateOf` (instance) | no `decorate` host | call 0 · test 2 | zero — kept, documented |
| Perf | `Progress` (instance) | reached through the panel | call 0 | zero — kept, documented |
| Perf | `RefreshPanel` (instance) | reached through the library's own transitions | call 0 · name-only 41 · stub 13 · test 40 | zero — kept, documented |
| Perf | `Reset` (instance) | reached through `OnCommand` | call 0 · name-only 12 · def 10 · stub 17 · test 561 | zero — kept, documented |
| Perf | `Resume` (instance) | reached through `OnCommand` | call 0 · name-only 19 · def 22 · test 85 | zero — kept, documented |
| Perf | `SCHEMA` (instance) | read by host tests only | call 0 · name-only 1 · stub 1 · test 26 | zero — kept, documented |
| Perf | `STEPS` (instance) | reached through the panel | call 0 · test 13 | zero — kept, documented |
| Perf | `Save` (instance) | reached through `OnCommand` | call 0 · name-only 13 · def 6 · test 177 | zero — kept, documented |
| Perf | `ShowPanel` (instance) | reached through `OnCommand` | call 0 · name-only 10 · test 38 | zero — kept, documented |
| Perf | `Start` (instance) | reached through `OnCommand` | call 0 · name-only 15 · def 14 · test 285 | zero — kept, documented |
| Perf | `StatusLines` (instance) | reached through `OnCommand` | call 0 · test 1 | zero — kept, documented |
| Perf | `Stop` (instance) | reached through `OnCommand` | call 0 · name-only 60 · def 12 · test 230 | zero — kept, documented |
| Perf | `Suspend` (instance) | reached through `OnCommand` | call 0 · name-only 5 · def 23 · test 109 | zero — kept, documented |
| Perf | `TogglePanel` (instance) | reached through `OnCommand` | call 0 · name-only 5 · test 1 | zero — kept, documented |
| Perf | `Usage` (instance) | reached through `OnCommand` | call 0 · name-only 28 · def 3 · test 116 | zero — kept, documented |
| Perf | `context` (instance) | instance data field (not in the instance table) | call 0 · name-only 2 · def 2 · test 221 | zero — kept, documented |
| Perf | `descriptor` (instance) | instance data field (not in the instance table) | call 0 · stub 11 · test 880 | zero — kept, documented |
| Perf | `name` (instance) | instance data field (not in the instance table) | call 0 · name-only 562 · def 5 · stub 246 · test 9178 | zero — kept, documented |
| Perf | `ringMax` (instance) | instance data field (not in the instance table) | call 0 | zero — kept, documented |
| Perf | `slash` (instance) | instance data field (not in the instance table) | call 0 · name-only 3 · stub 88 · test 1597 | zero — kept, documented |
| Perf | `title` (instance) | instance data field (not in the instance table) | call 0 · name-only 187 · def 8 · stub 31 · test 1135 | zero — kept, documented |
| Perf | `L` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Perf | `decorate` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Perf | `onChange` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Perf | `ring` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Sim | `lib.STRINGS` | no host reads the table by name; LootHistory settings/Slash.lua:233 is LibKa0s-Slash-1.0's `lib.STRINGS` | call 0 · name-only 1 · stub 5 · test 169 | zero — kept, documented |
| Sim | `PanelRows` (instance) | reached through the library's step panel; the host defs are library-absent stubs | call 0 · def 5 · test 40 | zero — kept, documented |
| Sim | `Pause` (instance) | BankLedger's only "call" is its library-absent stub (core/SimSetup.lua:76-91, host contract H9), which the scan's block detector misses; DropWatcher's and LootHistory's name hits are their own stubs and other tables' members | call 2 · name-only 4 · def 2 · test 14 | zero — kept, documented (read by hand) |
| Sim | `RefreshPanel` (instance) | BankLedger's only "call" is its library-absent stub (core/SimSetup.lua:76-91, host contract H9), which the scan's block detector misses; the name hits are other tables' members and the other hosts' stubs | call 2 · name-only 39 · stub 13 · test 40 | zero — kept, documented (read by hand) |
| Sim | `Restart` (instance) | BankLedger's only "call" is its library-absent stub (core/SimSetup.lua:76-91, host contract H9), which the scan's block detector misses; DropWatcher's and LootHistory's name hits are their own stubs and other tables' members | call 2 · name-only 3 · test 14 | zero — kept, documented (read by hand) |
| Sim | `Resume` (instance) | BankLedger's only "call" is its library-absent stub (core/SimSetup.lua:76-91, host contract H9), which the scan's block detector misses; DropWatcher's and LootHistory's name hits are their own stubs and other tables' members | call 2 · name-only 17 · def 22 · test 85 | zero — kept, documented (read by hand) |
| Sim | `Run` (instance) | BankLedger's only "call" is its library-absent stub (core/SimSetup.lua:76-91, host contract H9), which the scan's block detector misses; DropWatcher's and LootHistory's name hits are their own stubs and other tables' members | call 2 · name-only 18 · def 6 · stub 4 · test 376 | zero — kept, documented (read by hand) |
| Sim | `Step` (instance) | AuraMaster's hits are `E.LuaCurveType.Step`; the host defs are library-absent stubs | call 0 · name-only 3 · def 5 · test 85 | zero — kept, documented |
| Sim | `TogglePanel` (instance) | BankLedger's only "call" is its library-absent stub (core/SimSetup.lua:76-91, host contract H9), which the scan's block detector misses; the name hits are other tables' members and the other hosts' stubs | call 2 · name-only 3 · test 1 | zero — kept, documented (read by hand) |
| Sim | `Unwrapped` (instance) | read by host tests only (all three Sim hosts); the host defs are library-absent seam stubs | call 0 · name-only 1 · def 5 · test 24 | zero — kept, documented |
| Sim | `addonName` (descriptor) | library-internal: SimPanel.lua's renderer reads `d.addonName` off the table its adapter builds (`renderer`, SimPanel.lua:827), not off the host's descriptor | call 0 | zero — kept, documented |
| Sim | `close` (descriptor) | library-internal: SimPanel.lua's renderer reads `d.close` off the table its adapter builds (`renderer`, SimPanel.lua:827), not off the host's descriptor | call 0 | zero — kept, documented |
| Sim | `footer` (descriptor) | library-internal: SimPanel.lua's renderer reads `d.footer` off the table its adapter builds (`renderer`, SimPanel.lua:827), not off the host's descriptor | call 0 | zero — kept, documented |
| Sim | `onClick` (descriptor) | library-internal: SimPanel.lua's renderer reads `d.onClick` off the table its adapter builds (`renderer`, SimPanel.lua:827), not off the host's descriptor | call 0 | zero — kept, documented |
| Sim | `rows` (descriptor) | library-internal: SimPanel.lua's renderer reads `d.rows` off the table its adapter builds (`renderer`, SimPanel.lua:827), not off the host's descriptor | call 0 | zero — kept, documented |
| Sim | `tooltip` (descriptor) | library-internal: SimPanel.lua's renderer reads `d.tooltip` off the table its adapter builds (`renderer`, SimPanel.lua:827), not off the host's descriptor | call 0 | zero — kept, documented |

## Every export

Consumers lists each calling host with its first production call when there are three or fewer,
and the host names otherwise. Every hit with its file and line is in a run's `hits.tsv` (the v1.83.0 run's is `census-v1.83.0/hits.tsv` in the 2026-10-31 bundle, the v1.75.0 run's `census-v1.75.0/hits.tsv` in the 2026-10-22 bundle; the v1.71.0 run's was not kept, see [Method](#method)). A row read by hand names the call site that reading found. Hits for an
export called by three or more hosts are capped there at five per host per class, and the counts
here are uncapped.

| Major | Export | Consumers (first production call per host) | Hits by class | Verdict |
|---|---|---|---|---|
| Core | `lib.ApplySkin` | 10: AuraMaster, BankLedger, DpsRace, DropWatcher, LibKa0sSkinTester, LootHistory, MultiMeters, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 10 · name-only 20 · def 7 · stub 26 · test 84 | consumed (10) |
| Core | `lib.ClassColor` | AuraMaster `core/CoreSetup.lua:151`; MultiMeters `core/CoreSetup.lua:264` | call 2 · name-only 30 · def 3 · stub 3 · test 28 | thin (2) |
| Core | `lib.IsConcatSafe` | 15: AbsorbTracker, BankLedger, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 15 · name-only 12 · stub 31 · test 99 | consumed (15) |
| Core | `lib.MakeCloseButton` | 14: AuraMaster, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 14 · name-only 22 · def 16 · stub 30 · test 145 | consumed (14) |
| Core | `lib.MakeResizable` | 6: BankLedger, DpsRace, DropWatcher, LootHistory, MultiMeters, QuickComms | call 6 · name-only 10 · def 1 · stub 7 · test 45 | consumed (6) |
| Core | `lib.New` | all 16 | call 16 · name-only 200 · def 32 · stub 22 · test 974 | consumed (16) |
| Core | `lib.RGBA` | ConsumableMaster `core/CoreSetup.lua:163`; MultiMeters `core/CoreSetup.lua:243`; QuickComms `settings/SchemaMembers.lua:364` | call 4 · name-only 7 · stub 2 · test 36 | consumed (3) |
| Core | `lib.RaiseStaticPopups` | DpsRace `core/CoreSetup.lua:99` | call 1 · name-only 2 · stub 1 · test 1 | thin (1) |
| Core | `lib.ResolveColor` | 9: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, DropWatcher, KickCD, PanelMaster, PartyFrameEnhanced, QuickComms | call 10 · name-only 42 · def 1 · stub 6 · test 18 | consumed (9) |
| Core | `lib.SECRET` | AbsorbTracker `core/CoreSetup.lua:136`; KickCD `core/CoreSetup.lua:197`; MultiMeters `core/CoreSetup.lua:236` | call 3 · name-only 3 · stub 10 · test 306 | consumed (3) |
| Core | `lib.SKIN` | 8: AuraMaster, DpsRace, DropWatcher, LibKa0sSkinTester, MultiMeters, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 8 · name-only 8 · stub 22 · test 58 | consumed (8) |
| Core | `lib.SafeRegisterEvent` | all 16 | call 16 · name-only 58 · def 1 · stub 24 · test 63 | consumed (16) |
| Core | `lib.SafeRegisterEvents` | 11: AbsorbTracker, AuraMaster, DpsRace, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms | call 11 · name-only 2 · def 1 · stub 12 · test 11 | consumed (11) |
| Core | `lib.SafeRegisterUnitEvent` | 11: AbsorbTracker, AuraMaster, DpsRace, DropWatcher, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms | call 11 · name-only 15 · def 1 · stub 12 · test 11 | consumed (11) |
| Core | `lib.SafeToString` | all 16 | call 16 · name-only 72 · stub 56 · test 186 | consumed (16) |
| Core | `prefix` (descriptor) | all 16 | call 16 | consumed (16) |
| Core | `sep` (descriptor) | PrettyChat `core/CoreSetup.lua:176` | call 1 | thin (1) |
| Core | `sink` (descriptor) | 6: ConsumableMaster, DropWatcher, LibKa0sSkinTester, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 6 | consumed (6) |
| Env | `lib.GetAddOnMetadata` | all 16 | call 16 · name-only 31 · test 131 | consumed (16) |
| Env | `lib.GetPlayerMapID` | BankLedger `core/EnvSetup.lua:83`; LootHistory `core/Compat.lua:86` | call 2 · test 3 | thin (2) |
| Env | `lib.GetZone` | BankLedger `core/EnvSetup.lua:99`; LootHistory `core/Compat.lua:77` | call 2 · test 3 | thin (2) |
| Env | `lib.Version` | all 16 | call 16 · name-only 49 · def 18 · stub 21 · test 287 | consumed (16) |
| Compat | `lib.CanAccess` | 4: AuraMaster, DpsRace, DropWatcher, MultiMeters | call 4 · name-only 31 · test 72 | consumed (4) |
| Compat | `lib.GetSpecialization` | 6: ConsumableMaster, DpsRace, DropWatcher, KickCD, MultiMeters, PremadeGroupsFilterExtension | call 7 · name-only 12 · test 82 | consumed (6) |
| Compat | `lib.GetSpecializationInfo` | 6: ConsumableMaster, DpsRace, DropWatcher, KickCD, MultiMeters, PremadeGroupsFilterExtension | call 7 · name-only 10 · test 90 | consumed (6) |
| Compat | `lib.GetSpellCooldown` | KickCD `core/Compat.lua:101`; WhatGroup `core/Compat.lua:76` | call 2 · name-only 5 · def 1 · test 97 | thin (2) |
| Compat | `lib.GetSpellInfo` | AuraMaster `core/Compat.lua:425`; KickCD `core/Compat.lua:169`; MultiMeters `core/Compat.lua:78` | call 3 · name-only 27 · def 1 · test 140 | consumed (3) |
| Compat | `lib.GetSpellName` | ConsumableMaster `core/Compat.lua:83`; LootHistory `core/Compat.lua:170`; WhatGroup `core/Compat.lua:52` | call 3 · name-only 16 · test 126 | consumed (3) |
| Compat | `lib.GetSpellTexture` | KickCD `core/Compat.lua:160`; MultiMeters `core/Compat.lua:79`; WhatGroup `core/Compat.lua:60` | call 3 · name-only 12 · test 69 | consumed (3) |
| Compat | `lib.IsSafeKey` | 5: AuraMaster, DpsRace, DropWatcher, MultiMeters, QuickComms | call 5 · name-only 65 · test 49 | consumed (5) |
| Compat | `lib.IsSecret` | 9: AuraMaster, ConsumableMaster, DpsRace, DropWatcher, KickCD, MultiMeters, PartyFrameEnhanced, QuickComms, WhatGroup | call 9 · name-only 119 · test 99 | consumed (9) |
| Lifecycle | `lib.HOLD_DISABLED` | all 16 | call 18 · name-only 37 · stub 11 · test 32 | consumed (16) |
| Lifecycle | `lib.HOLD_PERF` | 9: AuraMaster, DpsRace, DropWatcher, LibKa0sSkinTester, LootHistory, PanelMaster, PrettyChat, QuickComms, WhatGroup | call 9 · stub 9 · test 96 | consumed (9) |
| Lifecycle | `lib.New` | 14: AuraMaster, BankLedger, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 14 · name-only 202 · def 32 · stub 22 · test 974 | consumed (14) |
| Lifecycle | `Hold` (instance) | none | call 0 · name-only 2 · def 2 · stub 28 · test 83 | zero — kept, documented |
| Lifecycle | `Holds` (instance) | all 16 | call 26 · stub 14 · test 26 | consumed (16) |
| Lifecycle | `IsDown` (instance) | all 16 | call 34 · name-only 16 · def 1 · stub 14 · test 59 | consumed (16) |
| Lifecycle | `IsHeld` (instance) | 9: AuraMaster, BankLedger, ConsumableMaster, DpsRace, DropWatcher, LibKa0sSkinTester, MultiMeters, QuickComms, WhatGroup | call 10 · stub 15 · test 29 | consumed (9) |
| Lifecycle | `PrintHolds` (instance) | none | call 0 · stub 14 · test 5 | zero — kept, documented |
| Lifecycle | `Reevaluate` (instance) | 13: AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 13 · name-only 11 · def 2 · stub 14 · test 19 | consumed (13) |
| Lifecycle | `Release` (instance) | none | call 0 · name-only 16 · def 7 · stub 27 · test 161 | zero — kept, documented |
| Lifecycle | `Set` (instance) | all 16 | call 31 · name-only 242 · def 19 · stub 39 · test 2894 | consumed (16) |
| Lifecycle | `name` (instance) | none | call 0 · name-only 562 · def 5 · stub 246 · test 9178 | zero — kept, documented |
| Lifecycle | `debug` (descriptor) | all 16 | call 16 | consumed (16) |
| Lifecycle | `name` (descriptor) | all 16 | call 16 | consumed (16) |
| Lifecycle | `print` (descriptor) | all 16 | call 16 | consumed (16) |
| Lifecycle | `standDown` (descriptor) | all 16 | call 16 | consumed (16) |
| Lifecycle | `standUp` (descriptor) | all 16 | call 16 | consumed (16) |
| Bus | `lib.Catalog` | 11: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, QuickComms | call 12 · name-only 6 · def 1 · stub 8 · test 65 | consumed (11) |
| Bus | `lib.New` | 7: AbsorbTracker, ConsumableMaster, DpsRace, DropWatcher, MultiMeters, PartyFrameEnhanced, QuickComms | call 7 · name-only 209 · def 32 · stub 22 · test 974 | consumed (7) |
| Bus | `NewTarget` (instance) | 5: ConsumableMaster, DpsRace, DropWatcher, PartyFrameEnhanced, QuickComms | call 23 · name-only 2 · stub 8 · test 40 | consumed (5) |
| Bus | `StandDown` (instance) | 5: ConsumableMaster, DpsRace, DropWatcher, PartyFrameEnhanced, QuickComms | call 5 · name-only 24 · def 18 · stub 20 · test 88 | consumed (5) |
| Bus | `StandUp` (instance) | 5: ConsumableMaster, DpsRace, DropWatcher, PartyFrameEnhanced, QuickComms | call 5 · name-only 27 · def 18 · stub 22 · test 63 | consumed (5) |
| Bus | `isDown` (descriptor) | 7: AbsorbTracker, ConsumableMaster, DpsRace, DropWatcher, MultiMeters, PartyFrameEnhanced, QuickComms | call 7 | consumed (7) |
| Bus | `name` (descriptor) | 7: AbsorbTracker, ConsumableMaster, DpsRace, DropWatcher, MultiMeters, PartyFrameEnhanced, QuickComms | call 7 | consumed (7) |
| Schema | `lib.New` | all 16 | call 16 · name-only 200 · def 32 · stub 22 · test 974 | consumed (16) |
| Schema | `lib.Read` | 7: AbsorbTracker, AuraMaster, DpsRace, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced | call 11 · name-only 20 · def 18 · stub 7 · test 121 | consumed (7) |
| Schema | `lib.STRINGS` | none | call 0 · name-only 1 · stub 5 · test 169 | zero — kept, documented |
| Schema | `lib.SameValue` | AuraMaster `settings/Schema.lua:566`; BankLedger `settings/Schema.lua:854` | call 2 · name-only 13 · def 12 · stub 4 · test 18 | thin (2) |
| Schema | `lib.SplitPath` | 4: AuraMaster, DpsRace, KickCD, MultiMeters | call 4 · name-only 38 · def 15 · stub 6 · test 12 | consumed (4) |
| Schema | `lib.Write` | 5: AbsorbTracker, AuraMaster, KickCD, PanelMaster, PartyFrameEnhanced | call 6 · name-only 29 · def 15 · stub 4 · test 29 | consumed (5) |
| Schema | `AddRows` (instance) | 10: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DpsRace, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 14 · name-only 19 · def 14 · stub 2 · test 16 | consumed (10) |
| Schema | `AllRows` (instance) | AbsorbTracker `settings/OptionsSetup.lua:98`; BankLedger `modules/Diagnostics.lua:134`; PrettyChat `settings/OptionsSetup.lua:316` | call 7 · name-only 6 · def 13 · stub 3 · test 25 | consumed (3) |
| Schema | `ApplyDefault` (instance) | 7: AbsorbTracker, BankLedger, DpsRace, KickCD, MultiMeters, PartyFrameEnhanced, PrettyChat | call 13 · name-only 43 · def 15 · stub 13 · test 102 | consumed (7) |
| Schema | `BulkAdd` (instance) | AuraMaster `settings/Schema.lua:586`; PrettyChat `settings/Schema.lua:853` | call 2 · name-only 1 · def 12 · stub 2 · test 7 | thin (2) |
| Schema | `BulkBegin` (instance) | 8: AbsorbTracker, AuraMaster, BankLedger, DpsRace, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced | call 15 · name-only 23 · def 13 · stub 6 · test 21 | consumed (8) |
| Schema | `BulkEnd` (instance) | 8: AbsorbTracker, AuraMaster, BankLedger, DpsRace, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced | call 15 · name-only 23 · def 13 · stub 6 · test 28 | consumed (8) |
| Schema | `BulkRun` (instance) | 8: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 9 · name-only 10 · def 13 · stub 6 · test 10 | consumed (8) |
| Schema | `ConsumeResetCount` (instance) | AbsorbTracker `settings/Schema.lua:449`; KickCD `core/Database.lua:630`; PartyFrameEnhanced `settings/Schema.lua:334` | call 3 · name-only 14 · def 12 · stub 2 · test 9 | consumed (3) |
| Schema | `CountOffDefault` (instance) | PrettyChat `settings/Schema.lua:661` | call 1 · def 12 · stub 2 · test 6 | thin (1) |
| Schema | `Default` (instance) | BankLedger `settings/Schema.lua:879`; PanelMaster `settings/Schema.lua:928` | call 2 · name-only 7 · def 13 · stub 12 · test 1585 | thin (2) |
| Schema | `FindRow` (instance) | 10: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DpsRace, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 28 · name-only 53 · def 13 · stub 12 · test 251 | consumed (10) |
| Schema | `Get` (instance) | 9: AbsorbTracker, BankLedger, ConsumableMaster, DpsRace, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 17 · name-only 325 · def 31 · stub 17 · test 1425 | consumed (9) |
| Schema | `InBulk` (instance) | AuraMaster `settings/Schema.lua:548` | call 1 · name-only 1 · def 12 · stub 2 · test 17 | thin (1) |
| Schema | `Reindex` (instance) | AuraMaster `settings/Schema.lua:284` | call 1 · def 12 · stub 2 · test 13 | thin (1) |
| Schema | `ResetCounted` (instance) | AbsorbTracker `settings/Schema.lua:446`; KickCD `settings/OptionsSetup.lua:130`; PartyFrameEnhanced `settings/Schema.lua:331` | call 3 · name-only 7 · def 12 · stub 2 · test 5 | consumed (3) |
| Schema | `Set` (instance) | 9: AbsorbTracker, BankLedger, ConsumableMaster, DpsRace, KickCD, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 20 · name-only 253 · def 19 · stub 39 · test 2894 | consumed (9) |
| Schema | `SetMany` (instance) | ConsumableMaster `settings/Panel.lua:775`; MultiMeters `settings/Schema_Paths.lua:707`; PanelMaster `settings/Schema.lua:926` | call 3 · name-only 6 · def 12 · stub 5 · test 95 | consumed (3) |
| Schema | `Validate` (instance) | 7: AbsorbTracker, AuraMaster, BankLedger, DpsRace, KickCD, PanelMaster, PartyFrameEnhanced | call 7 · name-only 8 · def 15 · stub 2 · test 28 | consumed (7) |
| Schema | `L` (descriptor) | 4: BankLedger, LootHistory, MultiMeters, PanelMaster | call 4 | consumed (4) |
| Schema | `resetExempt` (descriptor) | 13: AbsorbTracker, BankLedger, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 13 | consumed (13) |
| Schema | `rows` (descriptor) | all 16 | call 16 | consumed (16) |
| Schema | `writeThrough` (descriptor) | 11: AbsorbTracker, AuraMaster, BankLedger, DpsRace, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, QuickComms | call 11 | consumed (11) |
| Pool | `lib.Acquire` | 7: AuraMaster, BankLedger, DpsRace, DropWatcher, LootHistory, MultiMeters, QuickComms | call 42 · name-only 21 · def 9 · test 55 | consumed (7) |
| Pool | `lib.AcquireKeyed` | KickCD `modules/IconGrid.lua:208` | call 1 · def 1 · test 4 | thin (1) |
| Pool | `lib.Counts` | LootHistory `modules/Diagnostics.lua:336` | call 2 · name-only 3 · def 10 · test 87 | thin (1) |
| Pool | `lib.CountsKeyed` | KickCD `modules/Diagnostics.lua:183` | call 1 · def 1 · test 4 | thin (1) |
| Pool | `lib.New` | 7: AuraMaster, BankLedger, DpsRace, DropWatcher, LootHistory, MultiMeters, QuickComms | call 49 · name-only 167 · def 32 · stub 22 · test 974 | consumed (7) |
| Pool | `lib.NewKeyed` | KickCD `modules/IconGrid.lua:107` | call 1 · def 1 · test 3 | thin (1) |
| Pool | `lib.ReleaseAll` | 7: AuraMaster, BankLedger, DpsRace, DropWatcher, LootHistory, MultiMeters, QuickComms | call 43 · name-only 4 · def 9 · test 45 | consumed (7) |
| Pool | `lib.ReleaseAllKeyed` | KickCD `modules/IconGrid.lua:225` | call 1 · def 1 · test 3 | thin (1) |
| Item | `lib.BonusIDsFromLink` | BankLedger `core/Util.lua:106`; LootHistory `modules/Export.lua:36` | call 3 · def 2 · test 29 | thin (2) |
| Item | `lib.ItemIDFromLink` | 4: BankLedger, ConsumableMaster, DropWatcher, LootHistory | call 12 · def 4 · test 30 | consumed (4) |
| Item | `lib.LoadItem` | BankLedger `modules/Backfill.lua:158`; DropWatcher `modules/ItemFacts.lua:244`; LootHistory `core/Database.lua:489` | call 5 · def 3 · test 22 | consumed (3) |
| Item | `lib.QualityFromLink` | DropWatcher `core/ItemRead.lua:164`; LootHistory `core/Compat.lua:238` | call 2 · def 3 · test 9 | thin (2) |
| Item | `lib.QualityLabel` | BankLedger `core/Constants.lua:255`; LootHistory `core/Constants.lua:177` | call 20 · def 3 · test 25 | thin (2) |
| Glow | `lib.Start` | DropWatcher `modules/Glow.lua:136`; KickCD `modules/IconGrid_Render.lua:511`; QuickComms `modules/Glow.lua:81` | call 4 · name-only 11 · def 14 · test 285 | consumed (3) |
| Glow | `lib.Stop` | DropWatcher `modules/Glow.lua:111`; KickCD `modules/IconGrid_Render.lua:420`; QuickComms `modules/Glow.lua:69` | call 4 · name-only 56 · def 12 · test 230 | consumed (3) |
| Toast | `lib.DURATION` | none | call 0 · test 1 | zero — kept, documented |
| Toast | `lib.HEIGHT` | none | call 0 · name-only 18 · test 25 | zero — kept, documented |
| Toast | `lib.MAX_QUEUE` | none | call 0 · name-only 3 · test 2 | zero — kept, documented |
| Toast | `lib.New` | DpsRace `core/ToastSetup.lua:37`; DropWatcher `core/ToastSetup.lua:36` | call 2 · name-only 214 · def 32 · stub 22 · test 974 | thin (2) |
| Toast | `lib.POINT` | none | call 0 · name-only 4 · stub 6 · test 16 | zero — kept, documented |
| Toast | `lib.PREVIEW` | DpsRace `core/ToastSetup.lua:17` | call 1 · test 16 | thin (1) |
| Toast | `lib.STRATA` | none | call 0 · name-only 56 · test 90 | zero — kept, documented |
| Toast | `lib.WIDTH` | none | call 0 · name-only 14 · test 18 | zero — kept, documented |
| Toast | `build` (descriptor) | DpsRace `modules/BestToast.lua:287`; DropWatcher `modules/Toast.lua:504` | call 0 | thin (2, read by hand) |
| Toast | `debug` (descriptor) | DpsRace `modules/BestToast.lua:296` | call 0 | thin (1, read by hand) |
| Toast | `defaultPosition` (descriptor) | DropWatcher `modules/Toast.lua:508` | call 0 | thin (1, read by hand) |
| Toast | `draggable` (descriptor) | DpsRace `modules/BestToast.lua:293`; DropWatcher `modules/Toast.lua:513` | call 0 | thin (2, read by hand) |
| Toast | `duration` (descriptor) | DpsRace `modules/BestToast.lua:290`; DropWatcher `modules/Toast.lua:509` | call 0 | thin (2, read by hand) |
| Toast | `getPosition` (descriptor) | DpsRace `modules/BestToast.lua:294`; DropWatcher `modules/Toast.lua:514` | call 0 | thin (2, read by hand) |
| Toast | `height` (descriptor) | DpsRace `modules/BestToast.lua:289`; DropWatcher `modules/Toast.lua:506` | call 0 | thin (2, read by hand) |
| Toast | `maxQueue` (descriptor) | DropWatcher `modules/Toast.lua:507` | call 0 | thin (1, read by hand) |
| Toast | `name` (descriptor) | DpsRace `modules/BestToast.lua:286`; DropWatcher `modules/Toast.lua:503` | call 0 | thin (2, read by hand) |
| Toast | `owner` (descriptor) | DpsRace `core/ToastSetup.lua:36`; DropWatcher `core/ToastSetup.lua:35` | call 2 | thin (2) |
| Toast | `scale` (descriptor) | DpsRace `modules/BestToast.lua:291`; DropWatcher `modules/Toast.lua:510` | call 0 | thin (2, read by hand) |
| Toast | `setPosition` (descriptor) | DpsRace `modules/BestToast.lua:295`; DropWatcher `modules/Toast.lua:515` | call 0 | thin (2, read by hand) |
| Toast | `sound` (descriptor) | DpsRace `modules/BestToast.lua:292`; DropWatcher `modules/Toast.lua:511` | call 0 | thin (2, read by hand) |
| Toast | `soundKit` (descriptor) | none | call 0 | zero — kept, documented |
| Toast | `width` (descriptor) | DpsRace `modules/BestToast.lua:288`; DropWatcher `modules/Toast.lua:505` | call 0 | thin (2, read by hand) |
| Media | `lib.BACKGROUNDS` | none | call 0 | zero — kept, documented |
| Media | `lib.BORDERS` | none | call 0 | zero — kept, documented |
| Media | `lib.Background` | none | call 0 · name-only 5 · def 1 · test 77 | zero — kept, documented |
| Media | `lib.Border` | none | call 0 · name-only 3 · def 1 · test 130 | zero — kept, documented |
| Media | `lib.FONTS` | none | call 0 · test 33 | zero — kept, documented |
| Media | `lib.Font` | all 16 | call 16 · name-only 73 · def 2 · stub 17 · test 280 | consumed (16) |
| Media | `lib.ICONS` | QuickComms `core/MediaSetup.lua:68` | call 1 · test 24 | thin (1) |
| Media | `lib.ICON_SETS` | QuickComms `core/MediaSetup.lua:75` | call 1 · test 1 | thin (1) |
| Media | `lib.Icon` | all 16 | call 16 · name-only 95 · def 17 · test 476 | consumed (16) |
| Media | `lib.IconAuthor` | QuickComms `core/MediaSetup.lua:83` | call 2 · name-only 1 · def 1 · test 1 | thin (1) |
| Media | `lib.RegisterLSM` | all 16 | call 16 · test 11 | consumed (16) |
| Media | `lib.TEXTURES` | none | call 0 · test 5 | zero — kept, documented |
| Media | `lib.Texture` | none | call 0 · name-only 11 · def 2 · stub 2 · test 113 | zero — kept, documented |
| Media | `lib.VENDOR_PATH` | none | call 0 · test 1 | zero — kept, documented |
| Skin | `lib.AliasAceType` | AuraMaster `settings/OptionsSetup.lua:92` | call 1 · test 4 | thin (1) |
| Skin | `lib.Color` | 14: AuraMaster, BankLedger, ConsumableMaster, DpsRace, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 0 · name-only 104 · def 4 · stub 16 · test 244 | consumed (14, read by hand) |
| Skin | `lib.DEFAULT` | DpsRace `core/SkinSetup.lua:153`; LootHistory `core/SkinSetup.lua:677` | call 2 · name-only 9 · stub 16 · test 39 | thin (2) |
| Skin | `lib.DrawsKey` | PremadeGroupsFilterExtension `modules/Diagnostics.lua:103` | call 1 · test 5 | thin (1) |
| Skin | `lib.FROM_SKIN` | PartyFrameEnhanced `core/SkinSetup.lua:137` | call 1 · name-only 10 · stub 49 · test 65 | thin (1) |
| Skin | `lib.For` | all 16 | call 16 · name-only 15 · def 2 · test 130 | consumed (16) |
| Skin | `lib.GetChoice` | LibKa0sSkinTester `modules/Diagnostics.lua:45`; PremadeGroupsFilterExtension `core/SkinSetup.lua:463`; QuickComms `core/SkinSetup.lua:622` | call 5 · name-only 2 · test 113 | consumed (3) |
| Skin | `lib.GetEUIStatus` | PremadeGroupsFilterExtension `core/SkinSetup.lua:453`; QuickComms `core/SkinSetup.lua:624` | call 4 · test 6 | thin (2) |
| Skin | `lib.GetIgnore` | 10: AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PrettyChat, QuickComms | call 14 · name-only 2 · test 50 | consumed (10) |
| Skin | `lib.GetOutline` | LibKa0sSkinTester `modules/ShowroomFonts.lua:146` | call 0 · name-only 1 · test 105 | thin (1, read by hand) |
| Skin | `lib.GetOverride` | none | call 0 · test 35 | zero — kept, documented |
| Skin | `lib.GetSkin` | none | call 0 · test 6 | zero — kept, documented |
| Skin | `lib.IsFromSkin` | none | call 0 | zero — kept, documented |
| Skin | `lib.IsOwner` | LibKa0sSkinTester `modules/Diagnostics.lua:47` | call 1 · test 19 | thin (1) |
| Skin | `lib.OUTLINE_DEFAULT` | none | call 0 · test 24 | zero — kept, documented |
| Skin | `lib.OUTLINE_MODES` | none | call 0 · test 20 | zero — kept, documented |
| Skin | `lib.OnLooksChanged` | all 16 | call 0 · name-only 52 · def 1 · stub 16 · test 68 | consumed (16, read by hand) |
| Skin | `lib.OnRelease` | 8: AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LootHistory, PremadeGroupsFilterExtension, QuickComms | call 16 · test 57 | consumed (8) |
| Skin | `lib.OnReloadRequest` | none | call 0 · test 8 | zero — kept, documented |
| Skin | `lib.OwnerLabel` | none | call 0 · test 15 | zero — kept, documented |
| Skin | `lib.Owners` | none | call 0 | zero — kept, documented |
| Skin | `lib.PaintAce` | 12: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 24 · test 20 | consumed (12) |
| Skin | `lib.PaintAceTree` | all 16 | call 32 · test 21 | consumed (16) |
| Skin | `lib.PendingReload` | LibKa0sSkinTester `modules/Diagnostics.lua:48`; PremadeGroupsFilterExtension `core/SkinSetup.lua:463` | call 3 · test 1 | thin (2) |
| Skin | `lib.RegisterOwner` | all 16 | call 16 · test 41 | consumed (16) |
| Skin | `lib.RegisterSkin` | none | call 0 · test 14 | zero — kept, documented |
| Skin | `lib.Repaint` | none | call 0 · def 1 · test 14 | zero — kept, documented |
| Skin | `lib.ResetToSkin` | 7: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, DropWatcher, KickCD, QuickComms | call 10 · test 20 | consumed (7) |
| Skin | `lib.Resolve` | 9: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, DropWatcher, KickCD, MultiMeters, PartyFrameEnhanced, QuickComms | call 0 · name-only 65 · def 12 · stub 16 · test 214 | consumed (9, read by hand) |
| Skin | `lib.ResolveSkin` | 4: AuraMaster, DpsRace, KickCD, LootHistory | call 8 · name-only 4 · test 65 | consumed (4) |
| Skin | `lib.SCHEMA` | none | call 0 · name-only 1 · stub 1 · test 26 | zero — kept, documented |
| Skin | `lib.SOURCES` | none | call 0 · name-only 2 · test 11 | zero — kept, documented |
| Skin | `lib.SetChoice` | all 16 | call 16 · test 182 | consumed (16) |
| Skin | `lib.SetIgnore` | all 16 | call 32 · test 76 | consumed (16) |
| Skin | `lib.SetOutline` | all 16 | call 32 · test 58 | consumed (16) |
| Skin | `lib.SetOverride` | all 16 | call 32 · test 29 | consumed (16) |
| Skin | `lib.Skins` | all 16 | call 36 · name-only 5 · test 33 | consumed (16) |
| Skin | `lib.Token` | 8: AbsorbTracker, BankLedger, ConsumableMaster, DpsRace, DropWatcher, LootHistory, PremadeGroupsFilterExtension, QuickComms | call 0 · name-only 20 · stub 30 · test 181 | consumed (8, read by hand) |
| Skin | `lib.Track` | none | call 0 · name-only 1 · def 1 · test 15 | zero — kept, documented |
| Skin | `lib.Untrack` | DpsRace `modules/Style.lua:296` | call 1 | thin (1) |
| Skin | `lib.VOCAB` | none | call 0 · stub 16 · test 9 | zero — kept, documented |
| Skin | `lib.WriteChoice` | none | call 0 · test 61 | zero — kept, documented |
| Skin | `lib.byOwner` | none | call 0 · test 1 | zero — kept, documented |
| Skin | `lib.euiFacade` | none | call 0 | zero — kept, documented |
| Skin | `lib.euiPainted` | none | call 0 | zero — kept, documented |
| Skin | `lib.euiRefused` | none | call 0 | zero — kept, documented |
| Skin | `lib.euiRegistered` | none | call 0 | zero — kept, documented |
| Skin | `lib.facades` | none | call 0 · test 1 | zero — kept, documented |
| Skin | `lib.owners` | none | call 0 · test 54 | zero — kept, documented |
| Skin | `lib.painted` | none | call 0 · name-only 4 · test 483 | zero — kept, documented |
| Skin | `lib.prim` | none | call 0 · test 10 | zero — kept, documented |
| Skin | `lib.shared` | none | call 0 · name-only 9 · def 2 · stub 28 · test 746 | zero — kept, documented |
| Skin | `lib.skins` | none | call 0 · stub 3 · test 139 | zero — kept, documented |
| Skin | `addonName` (descriptor) | none | call 0 | zero — kept, documented |
| Skin | `thirdPartySkinAddons` (descriptor) | none | call 0 | zero — kept, documented |
| Skin | `thirdPartySkinsOff` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `lib.AUTOCOMPLETE` | none | call 0 | zero — kept, documented |
| Widgets | `lib.Autocomplete` | BankLedger `modules/Browser.lua:223`; LootHistory `core/WidgetsSetup.lua:292` | call 4 · name-only 2 · test 52 | thin (2) |
| Widgets | `lib.ChartMath` | none | call 0 · test 2 | zero — kept, documented |
| Widgets | `lib.CloseMenu` | 6: BankLedger, DpsRace, DropWatcher, LootHistory, MultiMeters, QuickComms | call 9 · name-only 12 · def 3 · test 40 | consumed (6) |
| Widgets | `lib.CopyWindow` | 5: BankLedger, DpsRace, LootHistory, MultiMeters, QuickComms | call 9 · name-only 3 · def 1 · test 16 | consumed (5) |
| Widgets | `lib.DRAG_HANDLE` | 4: AbsorbTracker, AuraMaster, KickCD, QuickComms | call 6 · test 21 | consumed (4) |
| Widgets | `lib.DragHandle` | 5: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, QuickComms | call 10 · name-only 2 · def 1 · test 39 | consumed (5) |
| Widgets | `lib.Dropdown` | 6: BankLedger, DpsRace, DropWatcher, LootHistory, MultiMeters, QuickComms | call 7 · name-only 4 · stub 15 · test 250 | consumed (6) |
| Widgets | `lib.LINE_CHART` | LootHistory `core/WidgetsSetup.lua:274` | call 1 · test 1 | thin (1) |
| Widgets | `lib.LineChart` | LootHistory `core/WidgetsSetup.lua:258` | call 3 · name-only 2 · test 6 | thin (1) |
| Widgets | `lib.ROW_BOX` | ConsumableMaster `settings/Category.lua:581`; KickCD `settings/Spells_Rows.lua:295`; LootHistory `core/WidgetsSetup.lua:217` | call 5 · test 12 | consumed (3) |
| Widgets | `lib.ReorderList` | 4: ConsumableMaster, KickCD, LootHistory, QuickComms | call 11 · name-only 2 · test 63 | consumed (4) |
| Widgets | `lib.SearchBox` | BankLedger `modules/Browser.lua:206`; DropWatcher `core/WidgetsSetup.lua:61`; LootHistory `core/WidgetsSetup.lua:150` | call 5 · name-only 3 · test 42 | consumed (3) |
| Widgets | `lib.TEST_STRIP` | 4: BankLedger, DpsRace, LootHistory, MultiMeters | call 7 · test 7 | consumed (4) |
| Widgets | `lib.TestStrip` | 5: BankLedger, DpsRace, DropWatcher, LootHistory, MultiMeters | call 12 · name-only 2 · test 43 | consumed (5) |
| Widgets | `addonName` (descriptor) | 6: BankLedger, DpsRace, LibKa0sSkinTester, LootHistory, MultiMeters, QuickComms | call 6 | consumed (6) |
| Widgets | `anchorTo` (descriptor) | 4: BankLedger, DpsRace, LootHistory, MultiMeters | call 4 | consumed (4) |
| Widgets | `applySkin` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `backdrop` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `editWidth` (descriptor) | MultiMeters `modules/Export_Modal.lua:335` | call 1 | thin (1) |
| Widgets | `font` (descriptor) | BankLedger `modules/Export.lua:285`; LootHistory `modules/Export.lua:377`; MultiMeters `modules/Export_Modal.lua:333` | call 3 | consumed (3) |
| Widgets | `fontSize` (descriptor) | LootHistory `modules/Export.lua:378`; MultiMeters `modules/Export_Modal.lua:334` | call 2 | thin (2) |
| Widgets | `height` (descriptor) | DpsRace `core/WidgetsSetup.lua:71`; LibKa0sSkinTester `modules/ShowroomWidgets.lua:171`; MultiMeters `modules/Export_Modal.lua:331` | call 3 | consumed (3) |
| Widgets | `hostBackdrop` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `hoverXs` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `integer` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `makeCloseButton` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `markers` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `name` (descriptor) | 5: BankLedger, DpsRace, LibKa0sSkinTester, LootHistory, MultiMeters | call 5 | consumed (5) |
| Widgets | `scrollName` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `series` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `title` (descriptor) | 5: BankLedger, DpsRace, LibKa0sSkinTester, LootHistory, MultiMeters | call 5 | consumed (5) |
| Widgets | `width` (descriptor) | DpsRace `core/WidgetsSetup.lua:71`; LibKa0sSkinTester `modules/ShowroomWidgets.lua:171`; MultiMeters `modules/Export_Modal.lua:330` | call 3 | consumed (3) |
| Widgets | `xMax` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `xMin` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `yMax` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `yMin` (descriptor) | none | call 0 | zero — kept, documented |
| DebugLog | `lib.AT_ENABLE_MAX` | none | call 0 | zero — kept, documented |
| DebugLog | `lib.BUFFER_SLACK` | none | call 0 · test 1 | zero — kept, documented |
| DebugLog | `lib.DIAG_MAX_LINES` | none | call 0 · test 1 | zero — kept, documented |
| DebugLog | `lib.DIAG_MAX_PER_LIST` | none | call 0 | zero — kept, documented |
| DebugLog | `lib.FormatColored` | ConsumableMaster `core/DebugLogSetup.lua:310` | call 1 · stub 6 · test 59 | thin (1) |
| DebugLog | `lib.FormatPlain` | ConsumableMaster `core/DebugLogSetup.lua:310` | call 1 · stub 8 · test 76 | thin (1) |
| DebugLog | `lib.GATE_MAX_KEYS` | none | call 0 | zero — kept, documented |
| DebugLog | `lib.MAX_BUFFER` | none | call 0 · test 8 | zero — kept, documented |
| DebugLog | `lib.MakeCloseButton` | none | call 0 · name-only 36 · def 16 · stub 30 · test 145 | zero — kept, documented |
| DebugLog | `lib.New` | all 16 | call 16 · name-only 200 · def 32 · stub 22 · test 974 | consumed (16) |
| DebugLog | `lib.STRINGS` | none | call 0 · name-only 1 · stub 5 · test 169 | zero — kept, documented |
| DebugLog | `lib.TIME_COPY` | none | call 0 | zero — kept, documented |
| DebugLog | `Add` (instance) | 13: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PartyFrameEnhanced, PrettyChat, QuickComms | call 31 · name-only 77 · def 8 · stub 19 · test 324 | consumed (13) |
| DebugLog | `BufferSize` (instance) | none | call 0 · stub 13 · test 63 | zero — kept, documented |
| DebugLog | `BuildDiagnostics` (instance) | none | call 0 · stub 19 · test 33 | zero — kept, documented |
| DebugLog | `Clear` (instance) | ConsumableMaster `core/DebugLogSetup.lua:286` | call 1 · name-only 32 · def 10 · stub 16 · test 498 | thin (1) |
| DebugLog | `ConsoleCheckbox` (instance) | 9: AbsorbTracker, AuraMaster, DpsRace, DropWatcher, LibKa0sSkinTester, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 12 · stub 13 · test 37 | consumed (9) |
| DebugLog | `CopyText` (instance) | none | call 0 · stub 7 · test 23 | zero — kept, documented |
| DebugLog | `Debug` (instance) | all 16 | call 16 · name-only 824 · stub 59 · test 602 | consumed (16) |
| DebugLog | `DebugAtEnable` (instance) | all 16 | call 39 · name-only 26 · def 1 · stub 26 · test 20 | consumed (16) |
| DebugLog | `DebugChanged` (instance) | 13: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 23 · name-only 22 · def 1 · stub 22 · test 27 | consumed (13) |
| DebugLog | `DebugForget` (instance) | 8: AuraMaster, BankLedger, ConsumableMaster, KickCD, LootHistory, PartyFrameEnhanced, PremadeGroupsFilterExtension, WhatGroup | call 11 · name-only 7 · def 1 · stub 17 · test 3 | consumed (8) |
| DebugLog | `DebugOnce` (instance) | 13: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, DropWatcher, LibKa0sSkinTester, LootHistory, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 19 · name-only 24 · def 3 · stub 24 · test 47 | consumed (13) |
| DebugLog | `DebugVerb` (instance) | 6: DpsRace, DropWatcher, LibKa0sSkinTester, PanelMaster, PremadeGroupsFilterExtension, QuickComms | call 6 · stub 21 · test 31 | consumed (6) |
| DebugLog | `FindLine` (instance) | none | call 0 · stub 13 · test 91 | zero — kept, documented |
| DebugLog | `Hide` (instance) | 7: BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PanelMaster, PrettyChat | call 8 · name-only 619 · def 16 · stub 19 · test 820 | consumed (7) |
| DebugLog | `IsEnabled` (instance) | AuraMaster `core/DebugLogSetup.lua:27`; ConsumableMaster `core/DebugLogSetup.lua:283`; PrettyChat `core/Util.lua:66` | call 3 · name-only 30 · def 3 · stub 33 · test 200 | consumed (3) |
| DebugLog | `IsShown` (instance) | 14: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat, QuickComms | call 27 · name-only 183 · def 10 · stub 33 · test 2408 | consumed (14) |
| DebugLog | `LastLine` (instance) | none | call 0 · stub 13 · test 51 | zero — kept, documented |
| DebugLog | `MakeCloseButton` (instance) | none | call 0 · name-only 36 · def 16 · stub 30 · test 145 | zero — kept, documented |
| DebugLog | `RefreshHeader` (instance) | ConsumableMaster `core/DebugLogSetup.lua:290` | call 1 · stub 15 · test 10 | thin (1) |
| DebugLog | `RunDiagnostics` (instance) | all 16 | call 22 · name-only 4 · stub 25 · test 71 | consumed (16) |
| DebugLog | `SetEnabled` (instance) | 9: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, LootHistory, MultiMeters, PartyFrameEnhanced, PrettyChat, WhatGroup | call 14 · name-only 46 · def 4 · stub 32 · test 370 | consumed (9) |
| DebugLog | `Show` (instance) | 14: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat, QuickComms | call 32 · name-only 390 · def 11 · stub 18 · test 1356 | consumed (14) |
| DebugLog | `ShowCopy` (instance) | ConsumableMaster `core/DebugLogSetup.lua:289` | call 1 · name-only 1 · def 2 · stub 15 · test 26 | thin (1) |
| DebugLog | `Text` (instance) | none | call 0 · name-only 172 · def 3 · stub 45 · test 387 | zero — kept, documented |
| DebugLog | `Toggle` (instance) | 15: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DpsRace, DropWatcher, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 17 · name-only 18 · def 13 · stub 17 · test 249 | consumed (15) |
| DebugLog | `UpdateScrollBar` (instance) | ConsumableMaster `core/DebugLogSetup.lua:291` | call 1 · stub 15 · test 23 | thin (1) |
| DebugLog | `UpdateStatus` (instance) | ConsumableMaster `core/DebugLogSetup.lua:292` | call 1 · stub 15 · test 18 | thin (1) |
| DebugLog | `buffer` (instance) | none | call 0 · stub 18 · test 537 | zero — kept, documented |
| DebugLog | `L` (descriptor) | 8: AbsorbTracker, AuraMaster, DropWatcher, LibKa0sSkinTester, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 8 | consumed (8) |
| DebugLog | `addonName` (descriptor) | all 16 | call 16 | consumed (16) |
| DebugLog | `applySkin` (descriptor) | none | call 0 | zero — kept, documented |
| DebugLog | `brandName` (descriptor) | 15: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 15 | consumed (15) |
| DebugLog | `diagnostics` (descriptor) | all 16 | call 16 | consumed (16) |
| DebugLog | `diagnosticsEnablesLogging` (descriptor) | none | call 0 | zero — kept, documented |
| DebugLog | `font` (descriptor) | all 16 | call 16 | consumed (16) |
| DebugLog | `fontSize` (descriptor) | ConsumableMaster `core/DebugLogSetup.lua:189` | call 1 | thin (1) |
| DebugLog | `initSummary` (descriptor) | all 16 | call 16 | consumed (16) |
| DebugLog | `isEnabled` (descriptor) | all 16 | call 16 | consumed (16) |
| DebugLog | `makeCloseButton` (descriptor) | none | call 0 | zero — kept, documented |
| DebugLog | `name` (descriptor) | all 16 | call 16 | consumed (16) |
| DebugLog | `onClear` (descriptor) | AuraMaster `core/DebugLogSetup.lua:189`; ConsumableMaster `core/DebugLogSetup.lua:258`; MultiMeters `core/DebugLogSetup.lua:410` | call 3 | consumed (3) |
| DebugLog | `onVisibilityChanged` (descriptor) | all 16 | call 16 | consumed (16) |
| DebugLog | `print` (descriptor) | all 16 | call 16 | consumed (16) |
| DebugLog | `safeToString` (descriptor) | 13: AbsorbTracker, AuraMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 13 | consumed (13) |
| DebugLog | `setEnabled` (descriptor) | all 16 | call 16 | consumed (16) |
| DebugLog | `skin` (descriptor) | none | call 0 | zero — kept, documented |
| DebugLog | `slash` (descriptor) | all 16 | call 16 | consumed (16) |
| DebugLog | `title` (descriptor) | all 16 | call 16 | consumed (16) |
| Slash | `lib.CommandRows` | ConsumableMaster `settings/Slash.lua:669`; KickCD `settings/Slash.lua:416` | call 2 · name-only 6 · stub 5 · test 13 | thin (2) |
| Slash | `lib.DISABLED_LINE_FORMAT` | LootHistory `settings/Slash.lua:215`; PanelMaster `settings/Slash.lua:768` | call 2 · stub 44 · test 63 | thin (2) |
| Slash | `lib.FindCommand` | ConsumableMaster `settings/Slash.lua:668`; KickCD `settings/Slash.lua:415` | call 2 · name-only 6 · stub 3 · test 12 | thin (2) |
| Slash | `lib.FormatKV` | 10: AbsorbTracker, AuraMaster, DropWatcher, LibKa0sSkinTester, LootHistory, PanelMaster, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 10 · name-only 6 · stub 8 · test 47 | consumed (10) |
| Slash | `lib.FormatRow` | AbsorbTracker `settings/Slash.lua:43`; PartyFrameEnhanced `settings/Slash.lua:282` | call 2 · stub 4 · test 25 | thin (2) |
| Slash | `lib.FormatValue` | 14: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DpsRace, DropWatcher, LibKa0sSkinTester, LootHistory, MultiMeters, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 16 · name-only 10 · def 4 · stub 4 · test 26 | consumed (14) |
| Slash | `lib.LIVE_VERBS` | 10: AbsorbTracker, AuraMaster, BankLedger, DpsRace, KickCD, LootHistory, MultiMeters, PanelMaster, PrettyChat, WhatGroup | call 10 · name-only 1 · stub 8 · test 45 | consumed (10) |
| Slash | `lib.New` | 12: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DpsRace, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat, WhatGroup | call 12 · name-only 204 · def 32 · stub 22 · test 974 | consumed (12) |
| Slash | `lib.ParseBool` | ConsumableMaster `settings/Slash.lua:499`; MultiMeters `settings/Slash.lua:489` | call 2 · name-only 1 · def 1 · stub 1 · test 12 | thin (2) |
| Slash | `lib.ParseValue` | 5: AuraMaster, BankLedger, ConsumableMaster, KickCD, PanelMaster | call 5 · stub 8 · test 6 | consumed (5) |
| Slash | `lib.ProfileNames` | AbsorbTracker `settings/Slash.lua:542` | call 2 · test 2 | thin (1) |
| Slash | `lib.STRINGS` | LootHistory `settings/Slash.lua:233` | call 1 · stub 5 · test 169 | thin (1) |
| Slash | `lib.SplitVerb` | AbsorbTracker `settings/Slash.lua:389`; ConsumableMaster `settings/Slash.lua:667`; KickCD `settings/Slash.lua:414` | call 6 · name-only 8 · stub 5 · test 16 | consumed (3) |
| Slash | `BuildListLines` (instance) | BankLedger `settings/Slash.lua:457`; LootHistory `settings/Slash.lua:513`; PanelMaster `settings/Slash.lua:749` | call 3 · name-only 2 · def 1 · stub 9 · test 47 | consumed (3) |
| Slash | `CliGet` (instance) | 15: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, WhatGroup | call 18 · name-only 3 · stub 9 · test 40 | consumed (15) |
| Slash | `CliList` (instance) | all 16 | call 16 · name-only 3 · stub 9 · test 14 | consumed (16) |
| Slash | `CliProfile` (instance) | 15: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 19 · name-only 3 · def 1 · stub 14 · test 55 | consumed (15) |
| Slash | `CliReset` (instance) | 15: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, WhatGroup | call 15 · name-only 3 · stub 9 · test 39 | consumed (15) |
| Slash | `CliResetAll` (instance) | none | call 0 · name-only 6 · def 3 · stub 10 · test 63 | zero — deliberate host copy |
| Slash | `CliSet` (instance) | 15: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, WhatGroup | call 19 · name-only 8 · stub 15 · test 120 | consumed (15) |
| Slash | `CliVersion` (instance) | 11: BankLedger, DpsRace, DropWatcher, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 11 · name-only 3 · stub 12 · test 14 | consumed (11) |
| Slash | `DisabledLine` (instance) | 13: AbsorbTracker, AuraMaster, BankLedger, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, QuickComms, WhatGroup | call 14 · name-only 11 · def 1 · stub 30 · test 110 | consumed (13) |
| Slash | `HelpHeader` (instance) | LootHistory `settings/Slash.lua:511` | call 1 · stub 7 · test 20 | thin (1) |
| Slash | `HelpRows` (instance) | LootHistory `settings/Slash.lua:512`; MultiMeters `settings/Slash.lua:918`; PanelMaster `settings/Slash.lua:747` | call 3 · stub 16 · test 20 | consumed (3) |
| Slash | `LandingRows` (instance) | all 16 | call 16 · name-only 10 · stub 22 · test 47 | consumed (16) |
| Slash | `OnSlash` (instance) | all 16 | call 16 · name-only 17 · def 2 · stub 20 · test 637 | consumed (16) |
| Slash | `PrintHelp` (instance) | all 16 | call 18 · name-only 3 · stub 41 · test 31 | consumed (16) |
| Slash | `ProfileSwitch` (instance) | 6: AbsorbTracker, BankLedger, ConsumableMaster, LootHistory, PanelMaster, PartyFrameEnhanced | call 6 · def 1 · stub 17 · test 40 | consumed (6) |
| Slash | `SetRowAnnotator` (instance) | AbsorbTracker `settings/Slash.lua:806`; AuraMaster `settings/Slash.lua:615` | call 2 · stub 12 | thin (2) |
| Slash | `Text` (instance) | LootHistory `settings/Slash.lua:552`; PanelMaster `settings/Slash.lua:760`; PrettyChat `settings/Slash.lua:423` | call 3 · name-only 169 · def 3 · stub 45 · test 387 | consumed (3) |
| Slash | `L` (descriptor) | 5: ConsumableMaster, KickCD, LibKa0sSkinTester, PanelMaster, WhatGroup | call 5 | consumed (5) |
| Slash | `aliases` (descriptor) | 7: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, KickCD, MultiMeters, PartyFrameEnhanced | call 7 | consumed (7) |
| Slash | `allRows` (descriptor) | all 16 | call 16 | consumed (16) |
| Slash | `applyDefault` (descriptor) | all 16 | call 16 | consumed (16) |
| Slash | `brandName` (descriptor) | all 16 | call 16 | consumed (16) |
| Slash | `bulkBegin` (descriptor) | 8: AuraMaster, BankLedger, DpsRace, DropWatcher, KickCD, LootHistory, MultiMeters, QuickComms | call 8 | consumed (8) |
| Slash | `bulkEnd` (descriptor) | 8: AuraMaster, BankLedger, DpsRace, DropWatcher, KickCD, LootHistory, MultiMeters, QuickComms | call 8 | consumed (8) |
| Slash | `colorDecode` (descriptor) | AuraMaster `settings/Slash.lua:608`; ConsumableMaster `settings/Slash.lua:648` | call 2 | thin (2) |
| Slash | `colorEncode` (descriptor) | AuraMaster `settings/Slash.lua:609`; ConsumableMaster `settings/Slash.lua:649` | call 2 | thin (2) |
| Slash | `commands` (descriptor) | all 16 | call 16 | consumed (16) |
| Slash | `debug` (descriptor) | all 16 | call 16 | consumed (16) |
| Slash | `findRow` (descriptor) | all 16 | call 16 | consumed (16) |
| Slash | `format` (descriptor) | 9: AuraMaster, BankLedger, ConsumableMaster, DpsRace, DropWatcher, LootHistory, MultiMeters, PrettyChat, QuickComms | call 9 | consumed (9) |
| Slash | `get` (descriptor) | all 16 | call 16 | consumed (16) |
| Slash | `groupKey` (descriptor) | all 16 | call 16 | consumed (16) |
| Slash | `isEnabled` (descriptor) | all 16 | call 16 | consumed (16) |
| Slash | `liveVerbs` (descriptor) | all 16 | call 16 | consumed (16) |
| Slash | `parse` (descriptor) | 9: AuraMaster, BankLedger, ConsumableMaster, KickCD, LibKa0sSkinTester, PanelMaster, PrettyChat, QuickComms, WhatGroup | call 9 | consumed (9) |
| Slash | `print` (descriptor) | all 16 | call 16 | consumed (16) |
| Slash | `profiles` (descriptor) | 15: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 15 | consumed (15) |
| Slash | `set` (descriptor) | all 16 | call 16 | consumed (16) |
| Slash | `slash` (descriptor) | all 16 | call 16 | consumed (16) |
| Slash | `slashAliases` (descriptor) | all 16 | call 16 | consumed (16) |
| Slash | `version` (descriptor) | all 16 | call 16 | consumed (16) |
| Launcher | `lib.New` | all 16 | call 16 · name-only 200 · def 32 · stub 22 · test 974 | consumed (16) |
| Launcher | `lib.STRINGS` | none | call 0 · name-only 1 · stub 5 · test 169 | zero — kept, documented |
| Launcher | `IsRegistered` (instance) | 6: AbsorbTracker, DropWatcher, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 6 · name-only 1 · stub 12 · test 59 | consumed (6) |
| Launcher | `IsShown` (instance) | 7: AbsorbTracker, BankLedger, DpsRace, DropWatcher, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 7 · name-only 203 · def 10 · stub 33 · test 2408 | consumed (7) |
| Launcher | `Object` (instance) | none | call 0 · stub 12 · test 116 | zero — kept, documented |
| Launcher | `Register` (instance) | all 16 | call 16 · name-only 43 · def 20 · stub 23 · test 382 | consumed (16) |
| Launcher | `SetShown` (instance) | all 16 | call 16 · name-only 274 · def 2 · stub 21 · test 72 | consumed (16) |
| Launcher | `L` (descriptor) | none | call 0 | zero — kept, documented |
| Launcher | `debug` (descriptor) | all 16 | call 16 | consumed (16) |
| Launcher | `debugAtEnable` (descriptor) | all 16 | call 16 | consumed (16) |
| Launcher | `icon` (descriptor) | all 16 | call 16 | consumed (16) |
| Launcher | `isEnabled` (descriptor) | all 16 | call 16 | consumed (16) |
| Launcher | `isLocked` (descriptor) | 13: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DpsRace, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, QuickComms, WhatGroup | call 13 | consumed (13) |
| Launcher | `isTestMode` (descriptor) | 8: AuraMaster, BankLedger, DpsRace, DropWatcher, LootHistory, MultiMeters, QuickComms, WhatGroup | call 8 | consumed (8) |
| Launcher | `label` (descriptor) | all 16 | call 16 | consumed (16) |
| Launcher | `minimap` (descriptor) | all 16 | call 16 | consumed (16) |
| Launcher | `name` (descriptor) | all 16 | call 16 | consumed (16) |
| Launcher | `onTooltipShow` (descriptor) | BankLedger `core/LauncherSetup.lua:282`; LootHistory `core/LauncherSetup.lua:208` | call 2 | thin (2) |
| Launcher | `openSettings` (descriptor) | all 16 | call 16 | consumed (16) |
| Launcher | `print` (descriptor) | all 16 | call 16 | consumed (16) |
| Launcher | `setEnabled` (descriptor) | all 16 | call 16 | consumed (16) |
| Launcher | `version` (descriptor) | all 16 | call 16 | consumed (16) |
| Options | `lib.APPEARANCE_STRINGS` | none | call 0 · stub 1 · test 1 | zero — kept, documented |
| Options | `lib.KEYBIND_STRINGS` | none | call 0 · test 9 | zero — kept, documented |
| Options | `lib.LAYOUT` | none | call 0 · name-only 7 · stub 1 · test 101 | zero — kept, documented |
| Options | `lib.New` | all 16 | call 16 · name-only 200 · def 32 · stub 22 · test 974 | consumed (16) |
| Options | `lib.PatchAlwaysShowScrollbar` | none | call 0 · stub 13 · test 24 | zero — kept, documented |
| Options | `lib.SKIN_PICKER_STRINGS` | none | call 0 · test 17 | zero — kept, documented |
| Options | `lib.STRINGS` | none | call 0 · name-only 1 · stub 5 · test 169 | zero — kept, documented |
| Options | `AceGUI` (instance) | 6: BankLedger, KickCD, PanelMaster, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 11 · name-only 56 · stub 27 · test 907 | consumed (6) |
| Options | `AddSpacer` (instance) | 7: AuraMaster, BankLedger, LootHistory, MultiMeters, PremadeGroupsFilterExtension, PrettyChat, WhatGroup | call 28 · name-only 24 · stub 16 · test 12 | consumed (7) |
| Options | `AppearanceRows` (instance) | none | call 0 · def 1 · stub 27 · test 12 | zero — kept, documented |
| Options | `AppearanceTab` (instance) | 15: AbsorbTracker, AuraMaster, BankLedger, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 15 · name-only 1 · def 1 · stub 20 · test 27 | consumed (15) |
| Options | `AttachTooltip` (instance) | 8: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, MultiMeters, PanelMaster, PrettyChat, WhatGroup | call 30 · name-only 69 · def 1 · stub 15 · test 28 | consumed (8) |
| Options | `BANNER_H` (instance) | AbsorbTracker `settings/UnitPanel.lua:138`; KickCD `settings/Panel_Render.lua:204`; PanelMaster `settings/PanelEditor.lua:524` | call 6 · name-only 3 · stub 6 · test 43 | consumed (3) |
| Options | `BUTTON_PAIR_REL` (instance) | AuraMaster `settings/GeneralSpells.lua:602`; LootHistory `settings/Panel.lua:51`; PanelMaster `settings/Panel.lua:58` | call 7 · name-only 7 · stub 7 · test 35 | consumed (3) |
| Options | `BarGroup` (instance) | 6: AbsorbTracker, AuraMaster, DpsRace, KickCD, PanelMaster, PartyFrameEnhanced | call 13 · stub 13 · test 19 | consumed (6) |
| Options | `BorderGroup` (instance) | 7: AbsorbTracker, AuraMaster, DpsRace, DropWatcher, KickCD, PanelMaster, PartyFrameEnhanced | call 13 · name-only 5 · def 1 · stub 13 · test 19 | consumed (7) |
| Options | `BuildLandingPage` (instance) | 14: AbsorbTracker, AuraMaster, BankLedger, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 14 · name-only 3 · stub 4 · test 59 | consumed (14) |
| Options | `CHROME_GAP` (instance) | none | call 0 · name-only 3 · stub 7 · test 23 | zero — kept, documented |
| Options | `CLASS_COLOR_NOTE` (instance) | AuraMaster `settings/Bars.lua:100`; PanelMaster `settings/PanelEditor.lua:399` | call 3 · name-only 1 · stub 4 · test 24 | thin (2) |
| Options | `ChoiceGrid` (instance) | AuraMaster `settings/Filters.lua:666` | call 2 · stub 17 · test 3 | thin (1) |
| Options | `ClearScroll` (instance) | all 16 | call 26 · name-only 3 · stub 18 · test 60 | consumed (16) |
| Options | `ColorPair` (instance) | 5: AbsorbTracker, AuraMaster, DpsRace, KickCD, PartyFrameEnhanced | call 13 · name-only 13 · def 1 · stub 13 · test 15 | consumed (5) |
| Options | `CreateOptionsPanel` (instance) | all 16 | call 16 · name-only 6 · stub 28 · test 49 | consumed (16) |
| Options | `CreatePanel` (instance) | all 16 | call 50 · name-only 8 · def 1 · stub 17 · test 97 | consumed (16) |
| Options | `Drawer` (instance) | QuickComms `settings/Groups_When.lua:675` | call 0 · name-only 1 · stub 34 · test 15 | thin (1, read by hand) |
| Options | `EnsureDefaultsButton` (instance) | LibKa0sSkinTester `settings/OptionsSetup.lua:330`; WhatGroup `settings/OptionsSetup.lua:321` | call 2 · def 2 · stub 15 · test 22 | thin (2) |
| Options | `EnsureScroll` (instance) | 11: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PanelMaster, PremadeGroupsFilterExtension, PrettyChat, WhatGroup | call 32 · name-only 15 · def 1 · stub 27 · test 25 | consumed (11) |
| Options | `FONT_FLAGS` (instance) | none | call 0 · name-only 1 · stub 5 · test 16 | zero — deliberate host copy |
| Options | `FONT_FLAGS_SORT` (instance) | none | call 0 · stub 4 · test 14 | zero — deliberate host copy |
| Options | `FontGroup` (instance) | 6: AbsorbTracker, AuraMaster, DpsRace, DropWatcher, KickCD, PartyFrameEnhanced | call 12 · name-only 5 · def 1 · stub 14 · test 20 | consumed (6) |
| Options | `HideSkinPicker` (instance) | 9: AuraMaster, BankLedger, DpsRace, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 18 · name-only 58 · def 16 · stub 28 · test 146 | consumed (9) |
| Options | `ID_NAME_HINT` (instance) | none | call 0 · stub 21 · test 3 | zero — kept, documented |
| Options | `IdInput` (instance) | KickCD `settings/Spells_Header.lua:228` | call 1 · name-only 1 · stub 17 · test 20 | thin (1) |
| Options | `IdList` (instance) | 4: AuraMaster, BankLedger, DpsRace, LootHistory | call 7 · name-only 1 · stub 20 · test 116 | consumed (4) |
| Options | `InlineButtonPair` (instance) | 5: AuraMaster, BankLedger, DpsRace, MultiMeters, PremadeGroupsFilterExtension | call 13 · name-only 9 · def 1 · stub 16 · test 18 | consumed (5) |
| Options | `KEYBINDS_UNCHANGED` (instance) | 8: BankLedger, DpsRace, DropWatcher, LibKa0sSkinTester, LootHistory, MultiMeters, QuickComms, WhatGroup | call 8 · stub 22 · test 19 | consumed (8) |
| Options | `KeybindRows` (instance) | none | call 0 · stub 28 · test 27 | zero — kept, documented |
| Options | `KeybindingsTab` (instance) | 8: BankLedger, DpsRace, DropWatcher, LibKa0sSkinTester, LootHistory, MultiMeters, QuickComms, WhatGroup | call 8 · stub 29 · test 9 | consumed (8) |
| Options | `LSMValues` (instance) | AbsorbTracker `settings/Appearance.lua:250`; LibKa0sSkinTester `settings/Schema.lua:229`; MultiMeters `settings/Schema_Compose.lua:258` | call 3 · name-only 1 · def 1 · stub 13 · test 56 | consumed (3) |
| Options | `MASTER_GROUP` (instance) | 12: AbsorbTracker, AuraMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 13 · name-only 2 · stub 13 · test 55 | consumed (12) |
| Options | `MasterControls` (instance) | 11: AbsorbTracker, AuraMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 11 · name-only 6 · def 1 · stub 24 · test 52 | consumed (11) |
| Options | `NavRail` (instance) | AuraMaster `settings/OptionsSetup.lua:644`; KickCD `settings/Panel_Render.lua:432`; MultiMeters `settings/OptionsSetup.lua:643` | call 3 · stub 24 · test 20 | consumed (3) |
| Options | `OpenOptionsPanel` (instance) | 11: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DpsRace, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 14 · name-only 24 · stub 19 · test 180 | consumed (11) |
| Options | `PADDING_X` (instance) | PanelMaster `settings/Panel.lua:504` | call 2 · stub 2 · test 30 | thin (1) |
| Options | `PageBanner` (instance) | AuraMaster `settings/OptionsSetup.lua:480`; MultiMeters `settings/Windows.lua:242` | call 3 · name-only 3 · stub 18 · test 33 | thin (2) |
| Options | `PageHeader` (instance) | AbsorbTracker `settings/UnitPanel.lua:336`; KickCD `settings/Panel_Render.lua:203`; PanelMaster `settings/PanelEditor.lua:514` | call 5 · name-only 1 · stub 18 · test 28 | consumed (3) |
| Options | `PatchAlwaysShowScrollbar` (instance) | none | call 0 · stub 13 · test 24 | zero — kept, documented |
| Options | `ROW_VSPACER` (instance) | 4: AuraMaster, BankLedger, PrettyChat, WhatGroup | call 7 · name-only 4 · stub 8 · test 43 | consumed (4) |
| Options | `RefreshAllPanels` (instance) | 8: AbsorbTracker, AuraMaster, BankLedger, DpsRace, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced | call 22 · name-only 12 · def 1 · stub 15 · test 139 | consumed (8) |
| Options | `RefreshPanel` (instance) | 13: AuraMaster, BankLedger, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 30 · name-only 11 · stub 13 · test 40 | consumed (13) |
| Options | `RefreshScalars` (instance) | 12: AuraMaster, BankLedger, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 22 · name-only 4 · def 1 · stub 14 · test 32 | consumed (12) |
| Options | `RegisterOptionsPage` (instance) | all 16 | call 30 · name-only 37 · def 3 · stub 19 · test 28 | consumed (16) |
| Options | `RenderField` (instance) | 4: KickCD, PanelMaster, PremadeGroupsFilterExtension, PrettyChat | call 8 · name-only 4 · def 1 · stub 15 · test 37 | consumed (4) |
| Options | `RenderGrid` (instance) | 4: AuraMaster, ConsumableMaster, KickCD, MultiMeters | call 15 · name-only 18 · stub 15 · test 19 | consumed (4) |
| Options | `RenderRows` (instance) | 4: AuraMaster, KickCD, LootHistory, MultiMeters | call 19 · name-only 12 · stub 15 · test 49 | consumed (4) |
| Options | `RenderSchema` (instance) | LibKa0sSkinTester `settings/Panel.lua:232` | call 1 · stub 18 · test 25 | thin (1) |
| Options | `RenderTabbedSchema` (instance) | 14: AbsorbTracker, AuraMaster, BankLedger, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 20 · name-only 2 · stub 32 · test 85 | consumed (14) |
| Options | `ResetAllTooltip` (instance) | 8: BankLedger, DropWatcher, LibKa0sSkinTester, LootHistory, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 8 · stub 25 · test 20 | consumed (8) |
| Options | `ResolveId` (instance) | AuraMaster `settings/GeneralSpells.lua:725`; DpsRace `modules/LateIgnore.lua:234` | call 3 · name-only 1 · stub 19 · test 10 | thin (2) |
| Options | `RestoreAllDefaults` (instance) | 12: AbsorbTracker, AuraMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 21 · name-only 7 · def 5 · stub 18 · test 193 | consumed (12) |
| Options | `RestoreDefaults` (instance) | 7: AbsorbTracker, AuraMaster, DpsRace, DropWatcher, KickCD, MultiMeters, PartyFrameEnhanced | call 13 · name-only 7 · def 4 · stub 9 · test 160 | consumed (7) |
| Options | `SECTION_HEADING_H` (instance) | PanelMaster `settings/Panel.lua:57` | call 1 · name-only 1 · stub 7 · test 29 | thin (1) |
| Options | `Section` (instance) | 4: AuraMaster, ConsumableMaster, MultiMeters, PremadeGroupsFilterExtension | call 17 · name-only 14 · def 3 · stub 15 · test 72 | consumed (4) |
| Options | `SelectTab` (instance) | AuraMaster `settings/Filters.lua:380`; KickCD `settings/Panel_Render.lua:490`; MultiMeters `settings/OptionsSetup.lua:690` | call 4 · name-only 11 · def 6 · stub 24 · test 177 | consumed (3) |
| Options | `SessionCheckbox` (instance) | ConsumableMaster `settings/Panel.lua:690`; DpsRace `settings/Race.lua:201` | call 2 · stub 15 · test 24 | thin (2) |
| Options | `SetChromeHeight` (instance) | none | call 0 · stub 17 · test 4 | zero — kept, documented |
| Options | `SetRenderer` (instance) | 15: AbsorbTracker, AuraMaster, BankLedger, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 43 · name-only 7 · def 2 · stub 17 · test 44 | consumed (15) |
| Options | `SkinPicker` (instance) | 9: AuraMaster, BankLedger, DpsRace, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 18 · name-only 14 · def 1 · stub 27 · test 121 | consumed (9) |
| Options | `SkinVerb` (instance) | 9: AuraMaster, BankLedger, DpsRace, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat | call 13 · name-only 11 · def 1 · stub 24 · test 144 | consumed (9) |
| Options | `StrataTooltip` (instance) | AuraMaster `settings/Layout.lua:387`; PanelMaster `settings/PanelEditorTabs.lua:472`; PartyFrameEnhanced `settings/General.lua:46` | call 3 · name-only 3 · stub 24 · test 19 | consumed (3) |
| Options | `SubTabStrip` (instance) | BankLedger `settings/Panel.lua:483`; LootHistory `settings/Panel.lua:494` | call 2 · name-only 1 · stub 14 · test 9 | thin (2) |
| Options | `TAB_H` (instance) | none | call 0 · name-only 5 · stub 6 · test 27 | zero — kept, documented |
| Options | `TabStrip` (instance) | 5: KickCD, LootHistory, MultiMeters, PanelMaster, PrettyChat | call 8 · name-only 5 · stub 20 · test 77 | consumed (5) |
| Options | `TextRow` (instance) | 7: AuraMaster, BankLedger, DpsRace, KickCD, MultiMeters, PremadeGroupsFilterExtension, PrettyChat | call 51 · name-only 36 · stub 9 · test 32 | consumed (7) |
| Options | `UnnamedCandidates` (instance) | none | call 0 · stub 18 · test 1 | zero — kept, documented |
| Options | `VISIBILITY_SORT` (instance) | none | call 0 · stub 4 · test 14 | zero — deliberate host copy |
| Options | `VISIBILITY_VALUES` (instance) | none | call 0 · stub 4 · test 14 | zero — deliberate host copy |
| Options | `addonName` (descriptor) | all 16 | call 16 | consumed (16) |
| Options | `afterRestoreAll` (descriptor) | none | call 0 | zero — kept, documented |
| Options | `allRows` (descriptor) | 15: AbsorbTracker, AuraMaster, BankLedger, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 15 | consumed (15) |
| Options | `applyDefault` (descriptor) | 15: AbsorbTracker, AuraMaster, BankLedger, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 15 | consumed (15) |
| Options | `buildMain` (descriptor) | all 16 | call 16 | consumed (16) |
| Options | `bulkBegin` (descriptor) | 14: AbsorbTracker, AuraMaster, BankLedger, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 14 | consumed (14) |
| Options | `bulkEnd` (descriptor) | 14: AbsorbTracker, AuraMaster, BankLedger, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 14 | consumed (14) |
| Options | `colorDecode` (descriptor) | 8: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, KickCD, MultiMeters, PartyFrameEnhanced, QuickComms | call 8 | consumed (8) |
| Options | `colorEncode` (descriptor) | 8: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, KickCD, MultiMeters, PartyFrameEnhanced, QuickComms | call 8 | consumed (8) |
| Options | `debug` (descriptor) | all 16 | call 16 | consumed (16) |
| Options | `get` (descriptor) | all 16 | call 16 | consumed (16) |
| Options | `getLSM` (descriptor) | all 16 | call 16 | consumed (16) |
| Options | `mainPanelName` (descriptor) | all 16 | call 16 | consumed (16) |
| Options | `onAceGUI` (descriptor) | 8: AbsorbTracker, AuraMaster, BankLedger, DpsRace, KickCD, LootHistory, MultiMeters, PartyFrameEnhanced | call 8 | consumed (8) |
| Options | `parentTitle` (descriptor) | all 16 | call 16 | consumed (16) |
| Options | `print` (descriptor) | all 16 | call 16 | consumed (16) |
| Options | `resetProfile` (descriptor) | all 16 | call 16 | consumed (16) |
| Options | `rowsForPage` (descriptor) | all 16 | call 16 | consumed (16) |
| Options | `scheduleTimer` (descriptor) | 12: AbsorbTracker, AuraMaster, BankLedger, DpsRace, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms | call 12 | consumed (12) |
| Options | `set` (descriptor) | all 16 | call 16 | consumed (16) |
| Options | `skipRestoreAll` (descriptor) | 15: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 15 | consumed (15) |
| Options | `sliderCommit` (descriptor) | ConsumableMaster `settings/OptionsSetup.lua:271` | call 1 | thin (1) |
| Options | `validate` (descriptor) | 14: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 14 | consumed (14) |
| Perf | `lib.DEFAULT_RING` | none | call 0 · test 2 | zero — kept, documented |
| Perf | `lib.EncodeJSON` | none | call 0 · test 17 | zero — kept, documented |
| Perf | `lib.New` | 11: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 11 · name-only 205 · def 32 · stub 22 · test 974 | consumed (11) |
| Perf | `lib.SCHEMA` | none | call 0 · name-only 1 · stub 1 · test 26 | zero — kept, documented |
| Perf | `lib.STRINGS` | none | call 0 · name-only 1 · stub 5 · test 169 | zero — kept, documented |
| Perf | `Announce` (instance) | none | call 0 · name-only 3 · def 1 · test 24 | zero — kept, documented |
| Perf | `BuildRecord` (instance) | none | call 0 · name-only 1 · def 1 · test 22 | zero — kept, documented |
| Perf | `Cancel` (instance) | none | call 0 · name-only 88 · def 7 · test 123 | zero — kept, documented |
| Perf | `Close` (instance) | none | call 0 · name-only 18 · def 5 · stub 3 · test 99 | zero — kept, documented |
| Perf | `Context` (instance) | none | call 0 · name-only 14 · def 2 · test 13 | zero — kept, documented |
| Perf | `ContextLines` (instance) | none | call 0 | zero — kept, documented |
| Perf | `EXPERIMENTS` (instance) | none | call 0 | zero — kept, documented |
| Perf | `EncodeJSON` (instance) | none | call 0 · test 17 | zero — kept, documented |
| Perf | `FormatReport` (instance) | none | call 0 · test 3 | zero — kept, documented |
| Perf | `HidePanel` (instance) | none | call 0 · name-only 6 · test 35 | zero — kept, documented |
| Perf | `IsPanelShown` (instance) | none | call 0 · name-only 7 · test 34 | zero — kept, documented |
| Perf | `LABELS` (instance) | none | call 0 · name-only 13 · test 22 | zero — kept, documented |
| Perf | `Log` (instance) | none | call 0 · name-only 3 · def 1 · test 17 | zero — kept, documented |
| Perf | `MarkReviewed` (instance) | none | call 0 · test 1 | zero — kept, documented |
| Perf | `Measure` (instance) | none | call 0 · name-only 3 · def 1 · test 10 | zero — kept, documented |
| Perf | `Note` (instance) | 11: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 87 · name-only 11 · def 4 · stub 11 · test 186 | consumed (11) |
| Perf | `OnCommand` (instance) | 11: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 13 · def 3 · stub 13 · test 35 | consumed (11) |
| Perf | `Open` (instance) | none | call 0 · name-only 43 · def 16 · stub 4 · test 420 | zero — kept, documented |
| Perf | `PanelIsActionable` (instance) | none | call 0 | zero — kept, documented |
| Perf | `PanelStateOf` (instance) | none | call 0 · test 2 | zero — kept, documented |
| Perf | `Progress` (instance) | none | call 0 | zero — kept, documented |
| Perf | `RefreshPanel` (instance) | none | call 0 · name-only 41 · stub 13 · test 40 | zero — kept, documented |
| Perf | `Reset` (instance) | none | call 0 · name-only 12 · def 10 · stub 17 · test 561 | zero — kept, documented |
| Perf | `Resume` (instance) | none | call 0 · name-only 19 · def 22 · test 85 | zero — kept, documented |
| Perf | `SCHEMA` (instance) | none | call 0 · name-only 1 · stub 1 · test 26 | zero — kept, documented |
| Perf | `STEPS` (instance) | none | call 0 · test 13 | zero — kept, documented |
| Perf | `Save` (instance) | none | call 0 · name-only 13 · def 6 · test 177 | zero — kept, documented |
| Perf | `ShowPanel` (instance) | none | call 0 · name-only 10 · test 38 | zero — kept, documented |
| Perf | `Start` (instance) | none | call 0 · name-only 15 · def 14 · test 285 | zero — kept, documented |
| Perf | `StatusLines` (instance) | none | call 0 · test 1 | zero — kept, documented |
| Perf | `Stop` (instance) | none | call 0 · name-only 60 · def 12 · test 230 | zero — kept, documented |
| Perf | `Suspend` (instance) | none | call 0 · name-only 5 · def 23 · test 109 | zero — kept, documented |
| Perf | `TogglePanel` (instance) | none | call 0 · name-only 5 · test 1 | zero — kept, documented |
| Perf | `Usage` (instance) | none | call 0 · name-only 28 · def 3 · test 116 | zero — kept, documented |
| Perf | `armed` (instance) | ConsumableMaster `core/Diagnostics.lua:137` | call 1 · name-only 7 · def 3 · stub 1 · test 601 | thin (1) |
| Perf | `context` (instance) | none | call 0 · name-only 2 · def 2 · test 221 | zero — kept, documented |
| Perf | `descriptor` (instance) | none | call 0 · stub 11 · test 880 | zero — kept, documented |
| Perf | `label` (instance) | ConsumableMaster `core/Diagnostics.lua:137` | call 1 · name-only 515 · def 4 · stub 32 · test 3897 | thin (1) |
| Perf | `name` (instance) | none | call 0 · name-only 562 · def 5 · stub 246 · test 9178 | zero — kept, documented |
| Perf | `on` (instance) | 11: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 85 · name-only 10 · def 1 · stub 343 · test 11796 | consumed (11) |
| Perf | `recording` (instance) | ConsumableMaster `core/Diagnostics.lua:137` | call 1 · stub 3 · test 173 | thin (1) |
| Perf | `ringMax` (instance) | none | call 0 | zero — kept, documented |
| Perf | `run` (instance) | ConsumableMaster `core/Diagnostics.lua:137` | call 1 · name-only 149 · def 37 · stub 29 · test 3305 | thin (1) |
| Perf | `slash` (instance) | none | call 0 · name-only 3 · stub 88 · test 1597 | zero — kept, documented |
| Perf | `title` (instance) | none | call 0 · name-only 187 · def 8 · stub 31 · test 1135 | zero — kept, documented |
| Perf | `L` (descriptor) | none | call 0 | zero — kept, documented |
| Perf | `addonName` (descriptor) | 11: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 11 | consumed (11) |
| Perf | `buckets` (descriptor) | 11: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 11 | consumed (11) |
| Perf | `decorate` (descriptor) | none | call 0 | zero — kept, documented |
| Perf | `lifecycle` (descriptor) | 11: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 11 | consumed (11) |
| Perf | `log` (descriptor) | 11: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 11 | consumed (11) |
| Perf | `name` (descriptor) | 11: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 11 | consumed (11) |
| Perf | `onChange` (descriptor) | none | call 0 | zero — kept, documented |
| Perf | `print` (descriptor) | 11: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 11 | consumed (11) |
| Perf | `ring` (descriptor) | none | call 0 | zero — kept, documented |
| Perf | `showLog` (descriptor) | 11: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 11 | consumed (11) |
| Perf | `slash` (descriptor) | 11: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 11 | consumed (11) |
| Perf | `sv` (descriptor) | 11: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 11 | consumed (11) |
| Perf | `title` (descriptor) | 11: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 11 | consumed (11) |
| Perf | `version` (descriptor) | 11: AbsorbTracker, AuraMaster, ConsumableMaster, DpsRace, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PartyFrameEnhanced, QuickComms | call 11 | consumed (11) |
| Sim | `lib.New` | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 5 · name-only 211 · def 32 · stub 22 · test 974 | consumed (5) |
| Sim | `lib.NewSeam` | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 5 · test 8 | consumed (5) |
| Sim | `lib.STRINGS` | none | call 0 · name-only 1 · stub 5 · test 169 | zero — kept, documented |
| Sim | `AddListener` (instance) | BankLedger `core/SimSetup.lua:82`; LootHistory `modules/SimPanel.lua:111`; MultiMeters `core/SimSetup.lua:124` | call 4 · name-only 3 | consumed (3) |
| Sim | `After` (instance) | 4: BankLedger, DropWatcher, KickCD, MultiMeters | call 7 · name-only 49 · def 6 · stub 1 · test 188 | consumed (4) |
| Sim | `DeliverForCleanup` (instance) | DropWatcher `modules/SimEvents.lua:513`; KickCD `modules/Sim.lua:433` | call 4 · def 5 · test 2 | thin (2) |
| Sim | `Fire` (instance) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 26 · name-only 7 · def 6 · test 185 | consumed (5) |
| Sim | `HidePanel` (instance) | DropWatcher `modules/SimPanel.lua:134` | call 3 · name-only 3 · test 35 | thin (1, read by hand) |
| Sim | `IsActive` (instance) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 41 · name-only 22 · def 8 · test 181 | consumed (5) |
| Sim | `IsDelivering` (instance) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 7 · name-only 3 · test 8 | consumed (5) |
| Sim | `IsPanelShown` (instance) | DropWatcher `modules/SimScenario.lua:197`; LootHistory `modules/Sim.lua:255` | call 4 · name-only 3 · test 34 | thin (2, read by hand) |
| Sim | `Keys` (instance) | BankLedger `modules/Diagnostics.lua:92`; LootHistory `modules/Diagnostics.lua:369`; MultiMeters `core/Diagnostics_Runtime.lua:411` | call 0 · name-only 5 · def 7 · test 53 | consumed (3, read by hand) |
| Sim | `Live` (instance) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 0 · name-only 22 · def 7 · test 76 | consumed (5, read by hand) |
| Sim | `OnStop` (instance) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 13 · name-only 3 · test 2 | consumed (5) |
| Sim | `OnStopGuarded` (instance) | BankLedger `core/SimSetup.lua:82`; DropWatcher `modules/Sim.lua:306`; MultiMeters `core/SimSetup.lua:124` | call 4 · name-only 3 · test 1 | consumed (3) |
| Sim | `PanelRows` (instance) | none | call 0 · def 5 · test 40 | zero — kept, documented |
| Sim | `Pause` (instance) | none | call 2 · name-only 4 · def 2 · test 14 | zero — kept, documented (read by hand) |
| Sim | `RefreshPanel` (instance) | none | call 2 · name-only 39 · stub 13 · test 40 | zero — kept, documented (read by hand) |
| Sim | `ResetPanelPosition` (instance) | DropWatcher `modules/Window.lua:861` | call 3 · name-only 3 · test 4 | thin (1, read by hand) |
| Sim | `Restart` (instance) | none | call 2 · name-only 3 · test 14 | zero — kept, documented (read by hand) |
| Sim | `Resume` (instance) | none | call 2 · name-only 17 · def 22 · test 85 | zero — kept, documented (read by hand) |
| Sim | `Run` (instance) | none | call 2 · name-only 18 · def 6 · stub 4 · test 376 | zero — kept, documented (read by hand) |
| Sim | `RunVerb` (instance) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 5 · name-only 1 · def 6 · stub 1 · test 33 | consumed (5) |
| Sim | `Session` (instance) | 4: BankLedger, DropWatcher, KickCD, MultiMeters | call 27 · name-only 10 · def 7 · test 69 | consumed (4) |
| Sim | `SetProvider` (instance) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 0 · name-only 8 · def 5 · test 19 | consumed (5, read by hand) |
| Sim | `ShowPanel` (instance) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 7 · name-only 3 · test 38 | consumed (5) |
| Sim | `Start` (instance) | DropWatcher `modules/SimScenario.lua:228` | call 1 · name-only 14 · def 14 · test 285 | thin (1) |
| Sim | `Status` (instance) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 12 · name-only 9 · def 11 · test 171 | consumed (5) |
| Sim | `Step` (instance) | none | call 0 · name-only 3 · def 5 · test 85 | zero — kept, documented |
| Sim | `Steps` (instance) | BankLedger `modules/Sim.lua:200`; DropWatcher `modules/Diagnostics.lua:393`; LootHistory `modules/Sim.lua:323` | call 9 · def 6 · stub 1 · test 23 | consumed (3) |
| Sim | `Stop` (instance) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 18 · name-only 42 · def 12 · test 230 | consumed (5) |
| Sim | `TogglePanel` (instance) | none | call 2 · name-only 3 · test 1 | zero — kept, documented (read by hand) |
| Sim | `Unwrapped` (instance) | none | call 0 · name-only 1 · def 5 · test 24 | zero — kept, documented |
| Sim | `L` (descriptor) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 5 | consumed (5) |
| Sim | `addonName` (descriptor) | none | call 0 | zero — kept, documented |
| Sim | `check` (descriptor) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 0 | consumed (5, read by hand) |
| Sim | `close` (descriptor) | none | call 0 | zero — kept, documented |
| Sim | `debug` (descriptor) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 5 | consumed (5) |
| Sim | `deliver` (descriptor) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 5 | consumed (5) |
| Sim | `footer` (descriptor) | none | call 0 | zero — kept, documented |
| Sim | `gate` (descriptor) | BankLedger `modules/Sim.lua:430`; LootHistory `modules/Sim.lua:370`; MultiMeters `modules/Sim.lua:325` | call 3 | consumed (3) |
| Sim | `isStoodDown` (descriptor) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 5 | consumed (5) |
| Sim | `name` (descriptor) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 5 | consumed (5) |
| Sim | `onClick` (descriptor) | none | call 0 | zero — kept, documented |
| Sim | `panel` (descriptor) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 5 | consumed (5) |
| Sim | `play` (descriptor) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 5 | consumed (5) |
| Sim | `prepare` (descriptor) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 5 | consumed (5) |
| Sim | `print` (descriptor) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 5 | consumed (5) |
| Sim | `refusal` (descriptor) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 5 | consumed (5) |
| Sim | `rows` (descriptor) | none | call 0 | zero — kept, documented |
| Sim | `scenarios` (descriptor) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 5 | consumed (5) |
| Sim | `seam` (descriptor) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 5 | consumed (5) |
| Sim | `slash` (descriptor) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 5 | consumed (5) |
| Sim | `statusLine` (descriptor) | DropWatcher `modules/Sim.lua:292`; MultiMeters `modules/Sim.lua:332` | call 2 | thin (2) |
| Sim | `stepDelay` (descriptor) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 5 | consumed (5) |
| Sim | `stopText` (descriptor) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 5 | consumed (5) |
| Sim | `title` (descriptor) | 4: BankLedger, DropWatcher, LootHistory, MultiMeters | call 0 | consumed (4, read by hand) |
| Sim | `tooltip` (descriptor) | none | call 0 | zero — kept, documented |
| Sim | `usage` (descriptor) | DropWatcher `modules/Sim.lua:291`; LootHistory `modules/Sim.lua:374` | call 2 | thin (2) |
| Sim | `verbs` (descriptor) | DropWatcher `modules/Sim.lua:289`; LootHistory `modules/Sim.lua:372` | call 2 | thin (2) |
| Sim | `why` (descriptor) | DropWatcher `modules/Sim.lua:290`; LootHistory `modules/Sim.lua:373` | call 2 | thin (2) |

## Re-running it

From this repo's root, with every addon checked out as a sibling:

```sh
/home/tushar/.claude/dev-copilot/bin/ka0s-bounded \
  lua ../Ka0sAddonsCommonTasks/docs/2026-10-02-LIBKA0S_CENSUS_ADOPTION/plan-data/census.lua \
      .. <output folder>
```

At v1.83.0 that was the copy in `../Ka0sAddonsCommonTasks/docs/2026-10-31-FINDINGS_REMEDIATION/plan-data/census-v1.83.0/`,
with that folder as the output; write a new run's output to a folder of its own, never into a
frozen bundle. Render from inside the output folder with
`lua census-render.lua table|zero|doclines . <stamp> <roster size>`.

The scan takes about five minutes. Then read every export whose verdict moved, every new export,
and every call hit that sits in a host's degradation stub, and update `verdicts.tsv` and this page
together. The tool classifies hits, but only reading the code settles
a verdict.
