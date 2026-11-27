# Who calls what: the LibKa0s consumer census

**Stamped v1.109.0** (the library at `feat/2026-11-21-sync-followups`, whose public surface is v1.108.0's: the v1.109.0 peels
move code between files and no member), re-measured 2026-11-21 across the nineteen addons in
`WowAddonStandards/standards/ADDONS.md`, each read at its `master` (a `git archive` of the branch, so an addon with a
feature branch checked out was measured as merged, not as in flight). That run is `FU-LK-CONSUMERS` of
`Ka0sAddonsCommonTasks/docs/2026-11-21-SYNC_FOLLOWUPS`, with the v1.83.0 copy of the tool unchanged. Ka0s Combat Trail,
Outfitter Reborn, Range Master and Character Ledger are new to the census since v1.83.0; DpsRace is gone from the roster, so
its hits are gone from every row, and the hand-read host lists carried from v1.83.0 have their DpsRace entries struck.

**What the scan could not do, and the hand read that followed.** The tables below are the scan's, with every verdict
v1.83.0 read by hand carried forward unchanged (its `kept because` reason and, for the 32 rows then marked *read by
hand*, its host list). The scan left 152 zero-consumer exports with no hand verdict, `zero — UNREAD` in its first render
(commit `5a77e534`): exports added since v1.83.0 (most of them `LibKa0s-WaypointArrow-1.0`'s 65 and
`LibKa0s-Callout-1.0`'s 39, then Widgets, IconBrowser, Charts and Tooltip) and the few whose last caller left. The tool
does not resolve those two majors' instances (its `INSTANCE` table predates them), and it counts a descriptor only where
it is a literal handed to `:New(` or `CopyWindow(`.

**The 152 were then read by hand** (the same item, `FU-LK-CONSUMERS`): each export searched for by name in the nineteen
addons' `master` (`libs/` and `tests/_kit/` excluded) and in this library's own files, then read at every hit. Each
verdict is a row of the run's `verdicts.tsv` (a reason for each zero, a `hand_hosts` list for each consumer found), and
both tables were rendered again by the same `census-render.lua`, so no generated row was edited by hand. **Fifteen have
consumers the scan cannot see**, each marked *read by hand*: descriptor fields a host hands through its own wrapper
(Callout's `name`, `db`, `path`, `set` and `colorEncode` through Combat Trail's `NS.NewCallout(d)`, and Toast's
`soundFile`, `stackGap` and `stackGrow` through `NS.NewToast(d)`), and the strip dock's fields, which hosts pass in
`TestStrip`'s options or `DockTestStrip`'s spec (Widgets' `dock` with 11 hosts, `titleBar` 7, `window` 6, `target` 5,
`clear` and `onOffset` 4 each, `gap` 3). **The other 137 are zero:** 109 are read inside the library only (a
validator's list, a layout constant, a pure helper published for a suite, an English fallback a host overrides by key);
20 are descriptor fields no host passes, each host keeping the default; one is a scan artifact (Core's `Hide` is
`d.Hide` on a divider texture, not a descriptor field); and **seven have no reader anywhere outside their own
definition and the library's suite**: Core `HasSettings`, Tooltip `SetCloseTip`, Callout `GLOWS` and `SETTINGS`,
WaypointArrow `IsStyle` and `MENU_ITEMS`, and Widgets `OwnerWarnings`, kept for the published surface because `-1.0` is
additive-only. The carried Toast rows read by hand at v1.83.0 (`build`, `name`, `width` and the rest, Drop Watcher alone)
predate Combat Trail's and Quick Comms' toasts, which pass the same fields through their own `NS.NewToast(d)`; those
rows were not read again here, so their counts are low. Everything from *The numbers* to *Method* below the next rule is
the v1.83.0 page's text, kept as that run's record.

| Verdict at v1.109.0 | Exports |
|---|---|
| consumed (three or more hosts) | 364 |
| thin (one or two hosts) | 158 |
| zero, a verdict carried from v1.83.0 | 166 (161 documented, 5 deliberate host copies) |
| zero, read by hand at v1.109.0 | 137 (109 read inside the library only, 20 descriptor fields no host passes, 7 with no reader, 1 scan artifact) |
| **total** | **825** (358 lib-level, 231 instance, 236 descriptor fields, across twenty-five majors) |

---

**Stamped v1.83.0** (tag `v1.83.0`, at `6c816fd`), re-measured 2026-10-31 across the sixteen addons
in `WowAddonStandards/standards/ADDONS.md`, each as checked out that day with v1.83.0 vendored: DpsRace on its own feature
branch, the others on or about to take `feat/2026-10-31-findings-remediation`. That run is `FX-LK-DOCS` of
`Ka0sAddonsCommonTasks/docs/2026-10-31-FINDINGS_REMEDIATION`. Ka0s DPS Race and Ka0s Skin Tester are new to the census
since v1.75.0, and v1.76.0 to v1.82.0 were never measured, so this run is also their first.

**DpsRace is retired and is not a consumer (2026-11-19).** Ka0s DPS Race was merged into Ka0s Combat Trail and left
the roster (`AF-DR-LK` of `Ka0sAddonsCommonTasks/docs/2026-11-19-ADOPTION_FEEDBACK`); its repository is kept as a checkout
and is out of every sweep. Every DpsRace name, hit and file:line on this page is the v1.83.0 measurement above, kept as
measured rather than rewritten by hand, because the host counts and hit totals beside each name are the scan's and a
count edited without a re-scan is measured nowhere. Read each row as if DpsRace were struck from it. The next re-run (see
[Re-running it](#re-running-it)) drops it from the roster and restamps the page; the verdicts it will move are known now:
three exports whose only measured caller was DpsRace go to zero and owe a hand verdict (Core `lib.RaiseStaticPopups`, Skin
`Untrack`, Toast `PREVIEW`), two consumed rows fall to thin (Widgets `width` and `height`, three hosts with it), and five
thin rows lose one of their two hosts (every row whose two names include DpsRace, `ResolveId` and `SessionCheckbox` among them).

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

**v1.117.0, not in the census (2026-11-26), spots from world coordinates and Full, `vendx` prices.** `ForeverDB.lua`
minor 4 adds `WorldToMap`, `VendorPriceAt`, `FullStatus`, `LoadFull` and `FullCost`, and changes `Spots` (it also reads
ForeverDB_Full's `spz` and the base `spw`, and answers its origin second) and `VendorPrice` (the lowest across `vendx`
and `vp`) (`ISR3-LK-01` of Ka0sAddonsCommonTasks `docs/2026-11-25-ITEM_SEARCH_ROUND3/`;
[the document](ForeverDB/version-4-docs.md)). None gets a row here yet. **Drop Watcher is still the only consumer**
(`core/ForeverDBSetup.lua`), and in the same run it adopts `LoadFull` (its own policy: on the Item Search window's
first open, never from the tooltip, deferred past combat), `VendorPriceAt` and `Spots`' origin. A host with a by-name
parity case for a library-absent stub of this major adds the five new members at its re-vendor.

**v1.116.0, not in the census (2026-11-25), objects with names; Drop Watcher the one consumer.** `ForeverDB.lua`
minor 3 adds `Object` (`ISF-LK-01` of Ka0sAddonsCommonTasks `docs/2026-11-25-ITEM_SEARCH_FEEDBACK/`;
[the document](ForeverDB/version-3-docs.md)). It gets no row here yet. **No host calls it at the tag:** Drop Watcher
adopts it in the same run, to name its object sources (merging same-named objects and leaving out nameless ones).
**`LibKa0s-ForeverDB-1.0`'s only consumer is Drop Watcher** (`core/ForeverDBSetup.lua`) from that run: Character Ledger
and Outfitter Reborn remove their ForeverDB reads and their `## OptionalDeps` entry (that bundle's `03_SPEC.md` §8) and
stop looking the major up, keeping their vendored copies unchanged. A host with a by-name parity case for a
library-absent stub of this major adds `Object` at its re-vendor.

**v1.115.0, not in the census (2026-11-25), Item Search's lookups.** `ForeverDB.lua` minor 2 adds `SearchItems`,
`QuestsForItem`, `RewardFrom`, `StartsQuest` and `SkinnedFrom` (`IS-LK-01` of Ka0sAddonsCommonTasks
`docs/2026-11-25-ITEM_SEARCH/`; [the document](ForeverDB/version-2-docs.md)). None gets a row here yet. **No host calls
them at the tag:** Drop Watcher adopts all five for its Item Search in the same run. The major's runtime consumers become
Drop Watcher, Character Ledger and Outfitter Reborn; Loot History and Bank Ledger drop their ForeverDB features in that run
and stop looking the major up. A host with a by-name parity case for a library-absent stub of this major adds the five
members at its re-vendor.

**v1.114.0, not in the census (2026-11-25), the ForeverDB reader.** The new major `LibKa0s-ForeverDB-1.0`
(`ForeverDB.lua` minor 1: `Available`, `IsLoaded`, `Status`, `Meta`, `NPC`, `Item`, `Quest`, `ItemSources`,
`VendorPrice`, `Spots`, `TrainerSpells`; `SF-LK-01` of Ka0sAddonsCommonTasks `docs/2026-11-25-SEEDS_AND_FOREVERDB/`,
LibKa0s#105; [the document](ForeverDB/version-1-docs.md)). None gets a row here yet. **No host calls them at the
tag:** the library's own diagnostics report reads `Status` (DebugLogDiagnostics minor 12), and the five consumers the
owner named on 2026-11-25 (Drop Watcher, Loot History, Bank Ledger, Character Ledger, Outfitter Reborn) adopt the major in
the same run, each through its own feature; the next census re-run reads them. A host with a by-name parity case for a
library-absent stub of this major adds the eleven members at its adoption.

**v1.105.0, not in the census (2026-11-16).** DebugLog shell minor 23 and DebugLogDiagnostics minor 11
add the report seam (`LK-79`, LibKa0s#79): the instance's `Report` and `Serialize`, the lib-level `Serialize` and
the string `REPORT_WRITTEN` ([the document](DebugLog/version-23.11.1.5-docs.md)). None gets a row here yet. **No host
consumes them at the tag**: Ka0s Consumable Master's addon-local `DL.Report` and `SlashDump.Serialize` are the
reference they were lifted from, and its one-line lift onto `D:Report` is its adoption item, as is every other
host's report verb. Every host with a by-name DebugLog parity case (fourteen) adds `Report` and `Serialize` to its
library-absent stub at its re-vendor.

**v1.105.0, not in the census (2026-11-16), the header marks.** WidgetsHeader minor 1 (new) adds
`W.HeaderButtons`, `W.HeaderButton`, `W.HEADER` and `W.HEADER_STRINGS`, and Core minor 18 adds
`Core.RegisterSettingsOpener`, `Core.HasSettings` and `Core.OpenSettings` (`LK-86`, LibKa0s#86;
[the Widgets document](Widgets/version-27.2.7.14.1.7.8.6.1.1-docs.md), [the Core document](Core/version-18.1-docs.md)).
None gets a row here yet. **No host calls them at the tag:** the library's own windows use them, the launcher fills the
registry in every host from the re-vendor alone, and a host window's strip is its adoption item (LibKa0s#86).

**v1.105.0, not in the census (2026-11-16), the sample characters.** Sim minor 3 adds the lib-level
`Sim.SAMPLE` and `Sim.Sample` (`LK-87`, LibKa0s#87; [the Sim document](Sim/version-3.3.11.4-docs.md)). Neither gets a
row here yet. **No host reads them at the tag:** each host's own sample characters (Combat Trail's, DpsRace's, Bank
Ledger's, What Group's and the others research note R6 of Ka0sAddonsCommonTasks `docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS/`
lists) move onto them at its adoption, in that run's phase [3].

**v1.105.0, not in the census (2026-11-16), the data bar.** WidgetsBar minor 1 (new) adds `W.Bar`,
`W.BarStyle`, `W.BarCompute`, `W.BarText`, `W.BarFormatTimer`, `W.BarShade`, `W.AcquireBar`, `W.ReleaseBars` and
`W.BAR` (`LK-80`, LibKa0s#80; [the Widgets document](Widgets/version-27.2.7.14.1.7.8.6.1.1-docs.md)). None gets a row here yet. **No
host calls them at the tag:** Ka0s Character Ledger, the one consumer by the owner's 2026-11-16 ruling, adopts them in
phase [3] of Ka0sAddonsCommonTasks `docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS/` and drops its `modules/Bar.lua`.

**v1.105.0, not in the census (2026-11-16), the tooltip placers and the launcher's own rows.** The new major
`LibKa0s-Tooltip-1.0` (`Tooltip.lua` minor 1: `TIP_GAP`, `Own`, `PlaceBeside`, `PlaceAttached`, `PlaceLauncher`,
`SetGroup`, `GroupOf`, `Replace`; `LK-92A`, LibKa0s#92; [the document](Tooltip/version-1-docs.md)), Charts minor 2's
`host.group` and `ctx:PlaceTip` ([the document](Charts/version-2.1-docs.md)), a drag handle's opt-in `spec.settings`
(WidgetsDragHandle minor 14) and Launcher minor 11's `extraEntries` descriptor field ([the document](Launcher/version-11-docs.md)).
None gets a row here yet. **No host calls them at the tag:** the library's own widgets are the Tooltip major's only callers,
each host's own tooltips move onto it at its adoption (LibKa0s#92), and `extraEntries` has one consumer by the owner's
2026-11-16 ruling, Ka0s Character Ledger, which adopts it in phase [3] of the same bundle.

**v1.105.0, not in the census (2026-11-17), smoke round 1's title-bar tooltips and colors.** `LibKa0s-Tooltip-1.0`
minor 1 also carries `AttachTitleTip`, `CLOSE_STRINGS`, `SetCloseTip` and `CloseTip` (`SR-L2` of
Ka0sAddonsCommonTasks `docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS/`, its `SR1_SMOKE_ROUND1.md`; [the document](Tooltip/version-1-docs.md)),
WidgetsDragHandleTip minor 1 `W.DRAG_HANDLE_STRINGS` ([the document](Widgets/version-27.2.7.14.1.7.8.6.1.1-docs.md)), and DebugLog
minor 23 the strings `TOGGLE_TIP`, `DIAGNOSTICS_TIP`, `COPY_TIP`, `CLEAR_TIP` and `SETTINGS_TIP` ([the document](DebugLog/version-23.11.1.5-docs.md)).
None gets a row here yet. **No host calls them at the tag:** the library's own title-bar controls are their only
callers, and a host reaches them only through its `L` (the console's strings, a strip's `spec.L`) or a window's
`closeTip`. A host's own windows' title-bar tooltips and colors are its `SR-<ABBR>` item of the same bundle. The
smoke round's color and band changes (`SR-L3`: `close.rest` follows `icon.tint`, marks light in `text.link`; `SR-L4`:
`list.header.bg` in every skin) move token values, not members, so no census row moves for them either. Nor does smoke
round 2 (`SR2-L1`: `text.link` in Azeroth, Glass, WoW Midnight and WoW Forever; `SR2-L2`: 1px window edges and no
`win.inner` in WoW Midnight, Azeroth and Ember, of `SR2_SMOKE_ROUND2.md`): token values again, in `SkinDefsOthers.lua` minor 10.
`SR2-L3` (footer button hover: Azeroth's `btn.hover`, WoW Midnight's `btnPrimary.hover`, the sim panel's buttons on
`text.link`) moves values too, in SkinDefsOthers minor 10, SimPanel minor 11 and SimPanelRender minor 4, and no member.
`SR2-L4` (1px popup, menu and tooltip edges in Azeroth and WoW Midnight, WoW Default's declared tooltip edge) moves
values alone, in SkinDefsOthers minor 10.
`SR2-L5` (a primary button hovers by its fill) adds the tokens `btnPrimary.hoverBg`, `btnPrimary.hoverBgTop` and
`btnPrimary.hoverBgBottom` (SkinDefs minor 28, SkinDefsOthers minor 10) and moves `S.Button`'s primary hover in
SkinPaintControls minor 18 ([the document](Skin/version-18.1.28.10.19.19.1.1.18.4.9-docs.md)): tokens and a behavior,
no member, so no census row moves. **A host owes:** a suite that pins a primary's hovered label at `btnPrimary.hover`,
its fill unchanged under the pointer, or a list of the schema's names re-pins it (the CHANGELOG's re-pin list), and a
host skin that sets its own `btnPrimary.bg` declares a `btnPrimary.hoverBg` beside it, since an absent token resolves to
Ka0s Default's (its burnt orange).

**v1.99.0, not in the census (2026-11-14).** The release adds a major,
`LibKa0s-WaypointArrow-1.0` (its lib-level members in `docs/api/WaypointArrow/members-1.1.json`, the descriptor's
fields and the instance's members in [its document](WaypointArrow/version-1.1-docs.md)): the waypoint arrow with
its settings rows (`WaypointArrowSettings.lua`), moved out of Ka0s Character Ledger. None gets a row here yet. **Its
one consumer is Ka0s Character Ledger**, adopted on its round-8 plan row R8-5 (`modules/WaypointArrow.lua`, an
adapter that calls `New`, `ConfigureFrom`, `SetTarget`, `Clear`, `ShowSample` / `HideSample`, `SetPosition`, `IsShown`
and `Update` on the instance and `SettingsRows` on the lib, in place of its own arrow and art), so the major's verdict
is *one* when the census next counts it. The owner accepted the one-consumer promotion on 2026-11-14 (`CLAUDE.md`, *Documented
deviations*). DebugLogDiagnostics minor 10 names the major on the report's `LibKa0s running:` line and moves no
member.

**v1.96.0, not in the census (2026-11-13).** The release adds a major,
`LibKa0s-Callout-1.0` (its twenty-five lib-level members in `docs/api/Callout/members-1.1.json`, the
descriptor's eight fields and the instance's twenty-six members in [its document](Callout/version-1.1-docs.md)),
the center-screen call-out with its settings section (`CalloutSettings.lua`), built for Ka0s Combat
Trail's race countdown ([#85](https://github.com/tusharsaxena/LibKa0s/issues/85)). None gets a row
here yet. **No host has adopted it.** Combat Trail (its re-vendor replaces the race countdown, its cue
sounds and their settings with one instance) is its one planned consumer, **pending**, so the
major's verdict is *zero — planned at v1.96.0* until Combat Trail calls `Callout:New` (the owner's
rulings of 2026-11-13, `docs/superpowers/plans/2026-11-13-callout.md`).
DebugLogDiagnostics minor 9 names the major on the report's `LibKa0s running:` line and moves no
member.

**v1.88.0, not in the census (2026-11-05).** Toast minor 4 adds the stack: the optional descriptor
fields `stack`, `stackGrow` and `stackGap`, the lib-level `STACK_GAP` and the instance members `SetStack`, `Visible` and
`FrameFor` ([its document](Toast/version-4-docs.md)). Ka0s Drop Watcher is the one planned consumer (its issue #14: `stack`,
`stackGrow` and `SetStack` behind its settings rows); Ka0s DPS Race stays one toast at a time and passes none of them. They
get no rows until the next run, when Drop Watcher's re-vendor has landed.

**v1.87.0, not in the census (2026-11-05).** Widgets minor 23 adds `W.ContextMenu`'s cascading menus: the row options
`submenu`, `radio` and `selected` and the open's `opts.check` ([its document](Widgets/version-23.5.12.6.7.5-docs.md)). No lib-level
member moves, so `docs/api/Widgets/members-23.5.12.6.7.5.json` lists the same surface as minor 22's. **No host passes them yet.**
Outfitter Reborn is the intended consumer (`core/WidgetsSetup.lua`'s `NS.OpenMenu`, its outfit menu's Key binding, Title,
Bank and Automation levels; OutfitterReborn `docs/superpowers/plans/2026-11-05-smoke-round-2.md`, Task 3.1), so the
options' verdict is *zero — planned at v1.87.0* until it re-vendors. They get no rows until the next run.

**v1.86.0, not in the census (2026-11-04).** The release adds a major,
`LibKa0s-IconBrowser-1.0` (its twelve lib-level members in
`docs/api/IconBrowser/members-1.1.1.json`, the `spec` fields, the tab descriptor's fields and the
browser's members in [its document](IconBrowser/version-1.1.1-docs.md)), promoted from Ka0s Quick
Comms' icon browser for Quick Comms and Outfitter Reborn (OutfitterReborn
`docs/superpowers/plans/2026-11-04-sheet-window-feedback.md`, M1). None gets a row here yet. **No host
has adopted it.** Quick Comms (its re-vendor turns `settings/IconBrowser.lua` into the adapter that
calls `IB:New`) and Outfitter Reborn (its outfit icon picker) are its two intended consumers, both
**pending**, so the major's verdict is *zero — planned at v1.86.0* until both call `IB:New`.
DebugLogDiagnostics minor 7 names the major on the report's `LibKa0s running:` line and moves no
member.

**v1.85.0, not in the census (2026-11-01).** Launcher minor 6 adds the optional descriptor
field `owner`, which no host passes: the tooltip reads the skin through `name` on all sixteen, and
`owner` is for a host whose skin owner is not its folder name. It gets no row until the next run.

**v1.85.0, not in the census (2026-11-01).** The owner's rulings of the same day add the skin facade's `S.BarBorder` and `S.HoverArt` (SkinPaintExtras minor 16) and `W.ContextMenu` (Widgets minor 21), and optional arguments on `S.HudFont`, `S.HudShadow`, `S.Mark` and `S.IconBorder`. No host calls them yet, and no public member is retired. `O.__hoverArt` stays private: QuickComms' `settings/IconBrowser.lua:373` is the one host call, and it moves to `S.HoverArt`. They get no rows until the next run.

**v1.85.0, not in the census (2026-11-01).** Toast minor 2 adds the optional descriptor field
`soundFile`, the file alternative to `soundKit`, which no host passes yet. It gets no row until the next run.

**v1.84.0, not in the census (2026-10-31, unreleased).** The release adds a major,
`LibKa0s-Charts-1.0` (`Charts:New` and its nine lib-level members in
`docs/api/Charts/members-1.1.json`, and the context's members in
[its document](Charts/version-1.1-docs.md)), promoted under
[LibKa0s#66](https://github.com/tusharsaxena/LibKa0s/issues/66). None gets a row here yet. **No host
has adopted it.** Ka0s Loot History and Ka0s DPS Race are its two intended consumers and hold their
own copies until their re-vendor, so the major's verdict is *zero — planned at v1.84.0* until both
call `Charts:New`.

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

**v1.85.0, not in the census (2026-11-01).** The release adds the skin facade's `S.BarGloss` and `S.HudFont` (SkinPaintExtras minors 14 and 15) and `Skin.FollowOnce` (Skin minor 14), for the flips of Ka0sAddonsCommonTasks `docs/2026-11-01-FULL_SKINNING/`. No host calls them yet, and no public member is retired. The stamp and its numbers stand until the next census re-run measures them.

**v1.83.0, first recorded (2026-10-31).** The release adds Options' `Ka0sMedia_*` AceGUI picker types
(`OptionsMedia.lua`, new at minor 1), an unregistered `LSM30_*` row's fall back to them (OptionsWidgets
minor 38; from minor 41, at v1.84.0, every `LSM30_*` row draws them, registered or not), thirteen more faces (Media minor 11) and `"hud"` as `Skin.OUTLINE_DEFAULT` (Skin minor 10). No
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
| Core | `lib.HasSettings` | no host calls it; the library's own suite (tests/test_header_buttons.lua) is its only reader | call 0 | zero — kept, documented |
| Core | `lib.RegisterSettingsOpener` | internal only: called by Launcher:New for every host | call 0 | zero — kept, documented |
| Core | `Hide` (descriptor) | scan artifact; `d` there is a texture, not a descriptor | call 0 | zero — kept, documented |
| Tooltip | `lib.CLOSE_STRINGS` | internal only: read by `lib.CloseTip` (Tooltip.lua:464) | call 0 | zero — kept, documented |
| Tooltip | `lib.GroupOf` | internal only; DropWatcher's `RT.GroupOf` (modules/RowTooltip.lua:101) is its own resolver for its docked panels, handed to `PlaceBeside` as an explicit group, not a copy of this one | call 0 · name-only 2 · def 1 · test 11 | zero — kept, documented |
| Tooltip | `lib.SetCloseTip` | no host calls it; the library's own suite is its only caller | call 0 | zero — kept, documented |
| Role | `lib.TALENT_GROUP_ROLE` | internal only: read through its local alias | call 0 | zero — kept, documented |
| Lifecycle | `Hold` (instance) | stubs only (18 stub lines across 6 hosts) | call 0 · name-only 5 · def 5 · stub 34 · test 113 | zero — kept, documented |
| Lifecycle | `PrintHolds` (instance) | stubs only | call 0 · stub 17 · test 6 | zero — kept, documented |
| Lifecycle | `Release` (instance) | stubs only; the 7 name hits are other tables' `Release` | call 0 · name-only 18 · def 10 · stub 33 · test 201 | zero — kept, documented |
| Lifecycle | `name` (instance) | instance data field | call 0 · name-only 978 · def 7 · stub 301 · test 13604 | zero — kept, documented |
| Schema | `lib.STRINGS` | no host reads the table by name | call 0 · name-only 1 · stub 5 · test 191 | zero — kept, documented |
| Toast | `lib.DURATION` | name-only hits are host constants of the same name | call 0 · name-only 2 · test 18 | zero — kept, documented |
| Toast | `lib.HEIGHT` | name-only hits are host constants of the same name | call 0 · name-only 26 · test 92 | zero — kept, documented |
| Toast | `lib.MAX_QUEUE` | name-only hits are host constants of the same name | call 0 · name-only 5 · test 6 | zero — kept, documented |
| Toast | `lib.POINT` | name-only hits are host constants of the same name | call 0 · name-only 4 · stub 6 · test 100 | zero — kept, documented |
| Toast | `lib.STRATA` | name-only hits are host constants of the same name | call 0 · name-only 93 · test 115 | zero — kept, documented |
| Toast | `lib.WIDTH` | name-only hits are host constants of the same name | call 0 · name-only 52 · test 55 | zero — kept, documented |
| Toast | `soundKit` (descriptor) | no host passes it | call 0 | zero — kept, documented |
| Callout | `lib.ANIMS` | internal only (Callout.lua:307, 835) | call 0 | zero — kept, documented |
| Callout | `lib.CHANNELS` | internal only (Callout.lua:308); the name hits are Combat Trail's own `Share.CHANNELS` and other addons' locals | call 0 · name-only 2 · test 2 | zero — kept, documented |
| Callout | `lib.DEFAULTS` | internal only; read by Combat Trail's tests (tests/test_countdown.lua) to hold its seeded profile to it | call 0 · name-only 6 · stub 1 · test 12 | zero — kept, documented |
| Callout | `lib.FOLLOW_FROM` | internal only | call 0 | zero — kept, documented |
| Callout | `lib.FONT_DEFAULT` | internal only (Callout.lua:480, CalloutSettings.lua:250) | call 0 | zero — kept, documented |
| Callout | `lib.FONT_FACES` | internal only | call 0 | zero — kept, documented |
| Callout | `lib.FONT_GAME` | internal only (Callout.lua:479, CalloutSettings.lua:279) | call 0 | zero — kept, documented |
| Callout | `lib.FONT_SKIN` | internal only; Character Ledger's `FONT_SKIN` (settings/Trainers.lua:67) is a WaypointArrow settings word, not this | call 0 | zero — kept, documented |
| Callout | `lib.FROM_SKIN` | internal only; every host name hit is LibKa0s-Skin-1.0's `FROM_SKIN` or a host stub's copy of it | call 0 · name-only 16 · stub 59 · test 64 | zero — kept, documented |
| Callout | `lib.FollowKeys` | internal only | call 0 | zero — kept, documented |
| Callout | `lib.GLOWS` | no reader at all, inside the library or out: kept for the published surface | call 0 | zero — kept, documented |
| Callout | `lib.KINDS` | internal only (Callout.lua:128, CalloutSettings.lua:481); read by Combat Trail's tests (tests/test_callout_settings.lua:55) to count the rows | call 0 · name-only 7 · test 17 | zero — kept, documented |
| Callout | `lib.LINES` | read by Combat Trail's tests only (tests/test_countdown.lua:156); the library builds it from `STOCK_ORDER` and `MAX_FROM` | call 0 · name-only 2 · stub 1 · test 16 | zero — kept, documented |
| Callout | `lib.MAX_FROM` | internal only; read by Combat Trail's tests (tests/test_countdown.lua:358) | call 0 · test 1 | zero — kept, documented |
| Callout | `lib.MEANING` | internal only | call 0 | zero — kept, documented |
| Callout | `lib.OFF` | internal only; the name hits are other tables' `OFF` | call 0 · name-only 10 · stub 8 · test 109 | zero — kept, documented |
| Callout | `lib.OUTLINES` | internal only (Callout.lua:302) | call 0 | zero — kept, documented |
| Callout | `lib.PACKS` | internal only; read by Combat Trail's tests (tests/test_countdown.lua:152) to hold `NS.CALLOUT_PACKS` to it | call 0 · test 10 | zero — kept, documented |
| Callout | `lib.PLAY_COUNTDOWN` | internal only (CalloutSettings.lua:295); read by Combat Trail's tests (tests/test_countdown.lua:176) | call 0 · test 2 | zero — kept, documented |
| Callout | `lib.SETTINGS` | no reader outside its own definition (Callout.lua:314); the name hits are other majors' `SETTINGS` | call 0 · name-only 2 · stub 1 · test 17 | zero — kept, documented |
| Callout | `lib.SETTINGS_SIDE_TABS` | internal only | call 0 | zero — kept, documented |
| Callout | `lib.SETTINGS_STRINGS` | internal only (CalloutSettings.lua:203) | call 0 | zero — kept, documented |
| Callout | `lib.SETTINGS_TABS` | internal only | call 0 | zero — kept, documented |
| Callout | `lib.SIZE_MAX` | internal only (Callout.lua:302, CalloutSettings.lua:398) | call 0 | zero — kept, documented |
| Callout | `lib.SIZE_MIN` | internal only (Callout.lua:302, CalloutSettings.lua:398) | call 0 | zero — kept, documented |
| Callout | `lib.SOUND_EXT` | internal only; read by Combat Trail's tests (tests/test_countdown.lua:157) | call 0 · test 2 | zero — kept, documented |
| Callout | `lib.STOCK` | internal only (CalloutRoute.lua:73, CalloutSettings.lua:296) | call 0 · test 1 | zero — kept, documented |
| Callout | `lib.STOCK_ORDER` | internal only (Callout.lua:166, CalloutRoute.lua:130) | call 0 | zero — kept, documented |
| Callout | `lib.STRATA` | internal only; the name hits are other majors' and hosts' `STRATA` | call 0 · name-only 93 · test 115 | zero — kept, documented |
| Callout | `lib.TTS` | internal only (Callout.lua:282, CalloutSettings.lua:446) | call 0 | zero — kept, documented |
| Callout | `lib.WIDTH` | internal only; the name hits are other tables' `WIDTH` | call 0 · name-only 52 · test 55 | zero — kept, documented |
| Callout | `label` (descriptor) | no descriptor passes it (CombatTrail modules/Countdown.lua:88 and core/CalloutSetup.lua:90-95 are the only fields set) | call 0 | zero — kept, documented |
| Callout | `soundsBase` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Callout | `vendorPath` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| WaypointArrow | `lib.ARRIVE` | internal only; Character Ledger keeps the default | call 0 · test 1 | zero — kept, documented |
| WaypointArrow | `lib.ART` | internal only; Character Ledger's `C.ART` (modules/Chrome.lua:114) is its own control-strip pitch | call 0 · name-only 4 · test 10 | zero — kept, documented |
| WaypointArrow | `lib.COMPACT_FROM` | internal only | call 0 | zero — kept, documented |
| WaypointArrow | `lib.DEFAULTS` | internal only; read by Character Ledger's tests (tests/test_round8.lua:670, tests/test_round9.lua:81) to hold its seeded profile to it | call 0 · name-only 6 · stub 1 · test 12 | zero — kept, documented |
| WaypointArrow | `lib.DEFAULT_POINT` | internal only | call 0 · name-only 3 | zero — kept, documented |
| WaypointArrow | `lib.DEFAULT_STYLE` | internal only | call 0 | zero — kept, documented |
| WaypointArrow | `lib.DISTANCE_UNITS` | internal only (WaypointArrow.lua:201, WaypointArrowSettings.lua:137) | call 0 | zero — kept, documented |
| WaypointArrow | `lib.Distance` | internal only; Character Ledger's `NS.Trainers.Distance` (modules/Trainers.lua:150) is its own trainer-popup measure | call 0 · name-only 4 · def 3 · test 10 | zero — kept, documented |
| WaypointArrow | `lib.DistanceUnitsValues` | internal only; Character Ledger takes the row through `SettingsRows` | call 0 | zero — kept, documented |
| WaypointArrow | `lib.FAR` | internal only (WaypointArrow.lua:237, 1264) | call 0 · test 10 | zero — kept, documented |
| WaypointArrow | `lib.FLAGS_FROM_SKIN` | internal only (WaypointArrow.lua:129, 663) | call 0 · name-only 3 | zero — kept, documented |
| WaypointArrow | `lib.FONT_DEFAULT` | internal only (WaypointArrow.lua:128, WaypointArrowSettings.lua:200) | call 0 | zero — kept, documented |
| WaypointArrow | `lib.FONT_FLAGS` | internal only (WaypointArrow.lua:195); Character Ledger's `FONT_FLAGS` (settings/Trainers.lua:61) is a settings word it hands `SettingsRows` | call 0 · name-only 1 · stub 5 · test 19 | zero — kept, documented |
| WaypointArrow | `lib.FONT_SIZE_MAX` | internal only (WaypointArrow.lua:192, WaypointArrowSettings.lua:220) | call 0 | zero — kept, documented |
| WaypointArrow | `lib.FONT_SIZE_MIN` | internal only (WaypointArrow.lua:192, WaypointArrowSettings.lua:220) | call 0 | zero — kept, documented |
| WaypointArrow | `lib.Fade` | internal only | call 0 · test 14 | zero — kept, documented |
| WaypointArrow | `lib.FormatDistance` | internal only; Character Ledger overrides its words through `d.strings` | call 0 | zero — kept, documented |
| WaypointArrow | `lib.GROUND` | internal only (WaypointArrow.lua:257, 263) | call 0 | zero — kept, documented |
| WaypointArrow | `lib.GroundFrame` | internal only | call 0 | zero — kept, documented |
| WaypointArrow | `lib.GroundTexCoord` | internal only | call 0 | zero — kept, documented |
| WaypointArrow | `lib.HIT_PAD` | internal only | call 0 | zero — kept, documented |
| WaypointArrow | `lib.IsStyle` | no reader outside its own definition (WaypointArrow.lua:1269); the library's suite is its only caller: kept for the published surface | call 0 | zero — kept, documented |
| WaypointArrow | `lib.MEDIA_DIR` | internal only | call 0 | zero — kept, documented |
| WaypointArrow | `lib.MENU_ITEMS` | no reader at all, inside the library or out (WaypointArrow.lua:154): kept for the published surface | call 0 | zero — kept, documented |
| WaypointArrow | `lib.MapWorldPos` | internal only, through the local; Character Ledger's `NS.Compat.MapWorldPos` (core/Compat.lua:406) is its own | call 0 · name-only 3 · def 1 · test 4 | zero — kept, documented |
| WaypointArrow | `lib.Mix` | internal only | call 0 · test 1 | zero — kept, documented |
| WaypointArrow | `lib.NEAR` | internal only (WaypointArrow.lua:237, 1264) | call 0 · test 17 | zero — kept, documented |
| WaypointArrow | `lib.POSITION_MAX` | internal only (WaypointArrow.lua:202) | call 0 | zero — kept, documented |
| WaypointArrow | `lib.POSITION_MIN` | internal only (WaypointArrow.lua:202) | call 0 | zero — kept, documented |
| WaypointArrow | `lib.PlayerFacing` | internal only, through the local | call 0 | zero — kept, documented |
| WaypointArrow | `lib.PlayerWorldPos` | internal only, through the local; Character Ledger's `NS.Compat.PlayerWorldPos` (core/Compat.lua:421) is its own | call 0 · name-only 1 · def 1 · test 4 | zero — kept, documented |
| WaypointArrow | `lib.Rotation` | internal only; read by Character Ledger's tests (tests/test_round6.lua:1169) | call 0 · test 3 | zero — kept, documented |
| WaypointArrow | `lib.SAMPLE_ROTATION` | internal only; read by Character Ledger's tests (tests/test_round6.lua:1363) | call 0 · test 1 | zero — kept, documented |
| WaypointArrow | `lib.SAMPLE_YARDS` | internal only; read by Character Ledger's tests (tests/test_round6.lua:1362) | call 0 · test 1 | zero — kept, documented |
| WaypointArrow | `lib.SCALE_MAX` | internal only (WaypointArrow.lua:189, WaypointArrowSettings.lua:172) | call 0 | zero — kept, documented |
| WaypointArrow | `lib.SCALE_MIN` | internal only (WaypointArrow.lua:189, WaypointArrowSettings.lua:172) | call 0 | zero — kept, documented |
| WaypointArrow | `lib.SCALE_STEP` | internal only | call 0 | zero — kept, documented |
| WaypointArrow | `lib.SETTINGS` | internal only; Character Ledger reaches it through `ConfigureFrom` | call 0 · name-only 2 · stub 1 · test 17 | zero — kept, documented |
| WaypointArrow | `lib.SETTINGS_STRINGS` | internal only (WaypointArrowSettings.lua:115) | call 0 | zero — kept, documented |
| WaypointArrow | `lib.SHADOW_BOX` | internal only | call 0 | zero — kept, documented |
| WaypointArrow | `lib.SHADOW_OFFSET` | internal only | call 0 | zero — kept, documented |
| WaypointArrow | `lib.SHARE_LEAD` | internal only | call 0 | zero — kept, documented |
| WaypointArrow | `lib.SKIN_FAR` | internal only | call 0 | zero — kept, documented |
| WaypointArrow | `lib.SKIN_NEAR` | internal only | call 0 | zero — kept, documented |
| WaypointArrow | `lib.STRATA` | internal only (WaypointArrow.lua:539); the name hits are other majors' and hosts' `STRATA` | call 0 · name-only 93 · test 115 | zero — kept, documented |
| WaypointArrow | `lib.STRINGS` | internal only (WaypointArrow.lua:277, 897) | call 0 · name-only 1 · stub 5 · test 191 | zero — kept, documented |
| WaypointArrow | `lib.STYLES` | internal only (WaypointArrow.lua:1269, WaypointArrowSettings.lua:126) | call 0 · name-only 7 · test 23 | zero — kept, documented |
| WaypointArrow | `lib.ShareText` | internal only | call 0 | zero — kept, documented |
| WaypointArrow | `lib.StyleValues` | internal only; Character Ledger takes the row through `SettingsRows` | call 0 | zero — kept, documented |
| WaypointArrow | `lib.TEXT_GAP` | internal only | call 0 · name-only 7 · test 1 | zero — kept, documented |
| WaypointArrow | `lib.TEXT_POSITIONS` | internal only (WaypointArrow.lua:199, WaypointArrowSettings.lua:136) | call 0 | zero — kept, documented |
| WaypointArrow | `lib.TEXT_ROOM` | internal only | call 0 | zero — kept, documented |
| WaypointArrow | `lib.TextPositionValues` | internal only; Character Ledger takes the row through `SettingsRows` | call 0 | zero — kept, documented |
| WaypointArrow | `lib.UNITS` | internal only; Character Ledger's `UNITS` (settings/Trainers.lua:75) is a settings word | call 0 · name-only 11 · test 40 | zero — kept, documented |
| WaypointArrow | `arrive` (descriptor) | no descriptor passes it (Character Ledger's one `Arrow:New`, modules/WaypointArrow.lua:209) | call 0 | zero — kept, documented |
| WaypointArrow | `canDrag` (descriptor) | no descriptor passes it; the omission is recorded at the call | call 0 | zero — kept, documented |
| WaypointArrow | `far` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| WaypointArrow | `format` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| WaypointArrow | `mediaBase` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| WaypointArrow | `menu` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| WaypointArrow | `near` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| WaypointArrow | `onMoved` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| WaypointArrow | `parent` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| WaypointArrow | `point` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| WaypointArrow | `vendorPath` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Charts | `lib.RangeScale` | internal only | call 0 | zero — kept, documented |
| Charts | `lib.StripLabels` | internal only | call 0 | zero — kept, documented |
| Charts | `lib.StripSlots` | internal only | call 0 | zero — kept, documented |
| Charts | `lib.tipText` | internal only; DropWatcher's `tipText` (tests/run.lua:101) is its own test helper | call 0 · test 40 | zero — kept, documented |
| Media | `lib.BACKGROUNDS` | no host call | call 0 | zero — kept, documented |
| Media | `lib.BORDERS` | no host call | call 0 | zero — kept, documented |
| Media | `lib.Background` | no host call | call 0 · name-only 5 · def 1 · test 90 | zero — kept, documented |
| Media | `lib.Border` | no host call | call 0 · name-only 5 · def 3 · test 144 | zero — kept, documented |
| Media | `lib.FONTS` | no host reads the table by name | call 0 · test 37 | zero — kept, documented |
| Media | `lib.ICONS` | internal only; read by five hosts' tests (BankLedger, LibKa0sSkinTester, LootHistory, PrettyChat, RangeMaster tests/test_mediasetup.lua) to hold their pruned `media/icons/` to it | call 0 · test 43 | zero — kept, documented |
| Media | `lib.ICON_SETS` | internal only | call 0 | zero — kept, documented |
| Media | `lib.IconAuthor` | internal only, from another major | call 0 | zero — kept, documented |
| Media | `lib.TEXTURES` | no host reads the table by name | call 0 · test 5 | zero — kept, documented |
| Media | `lib.Texture` | ConsumableMaster's two `Texture` hits are its own `MacroDisplay.Texture` | call 0 · name-only 12 · def 2 · stub 2 · test 207 | zero — kept, documented |
| Media | `lib.VENDOR_PATH` | default value | call 0 · test 2 | zero — kept, documented |
| Skin | `lib.CLIENT_DEFAULTS` | internal only; read by host tests only | call 0 · test 4 | zero — kept, documented |
| Skin | `lib.GetOverride` | no host calls it; read by hand | call 0 · test 36 | zero — kept, documented |
| Skin | `lib.GetSkin` | no host calls it; read by hand | call 0 · test 14 | zero — kept, documented |
| Skin | `lib.IsFromSkin` | no host calls it; read by hand | call 0 | zero — kept, documented |
| Skin | `lib.OUTLINE_DEFAULT` | name-only hits are unrelated host tables | call 0 · test 23 | zero — kept, documented |
| Skin | `lib.OUTLINE_MODES` | name-only hits are unrelated host tables | call 0 · test 19 | zero — kept, documented |
| Skin | `lib.OnReloadRequest` | no host calls it; read by hand | call 0 · test 7 | zero — kept, documented |
| Skin | `lib.OwnerLabel` | no host calls it; read by hand | call 0 · test 16 | zero — kept, documented |
| Skin | `lib.Owners` | no host calls it; read by hand | call 0 | zero — kept, documented |
| Skin | `lib.RETIRED_FONTS` | internal only; fifteen hosts carry a local `RETIRED_FONTS` copy in `core/Database.lua` or `core/Database_Migrations.lua` (for example PartyFrameEnhanced core/Database.lua:147, WhatGroup core/Database.lua:30) | call 0 · name-only 12 | zero — kept, documented |
| Skin | `lib.RegisterSkin` | no host calls it; read by hand | call 0 · test 45 | zero — kept, documented |
| Skin | `lib.Repaint` | no host calls it; read by hand | call 0 · name-only 2 · def 3 · test 13 | zero — kept, documented |
| Skin | `lib.SCHEMA` | no host calls it; read by hand | call 0 · name-only 1 · stub 1 · test 27 | zero — kept, documented |
| Skin | `lib.SOURCES` | name-only hits are unrelated host tables | call 0 · name-only 2 · test 11 | zero — kept, documented |
| Skin | `lib.Track` | name-only and def hits are QuickComms own `Slices.Track` | call 0 · name-only 2 · def 2 · test 37 | zero — kept, documented |
| Skin | `lib.VOCAB` | stub hits are comments naming it | call 0 · stub 19 · test 17 | zero — kept, documented |
| Skin | `lib.WriteChoice` | no host calls it; read by hand | call 0 · test 60 | zero — kept, documented |
| Skin | `lib.byOwner` | name-only and stub hits are unrelated host words | call 0 · test 2 | zero — kept, documented |
| Skin | `lib.euiFacade` | name-only and stub hits are unrelated host words | call 0 | zero — kept, documented |
| Skin | `lib.euiPainted` | name-only and stub hits are unrelated host words | call 0 | zero — kept, documented |
| Skin | `lib.euiRegistered` | name-only and stub hits are unrelated host words | call 0 | zero — kept, documented |
| Skin | `lib.facades` | name-only and stub hits are unrelated host words | call 0 · test 1 | zero — kept, documented |
| Skin | `lib.owners` | name-only and stub hits are unrelated host words | call 0 · test 86 | zero — kept, documented |
| Skin | `lib.painted` | name-only and stub hits are unrelated host words | call 0 · name-only 4 · stub 1 · test 739 | zero — kept, documented |
| Skin | `lib.prim` | name-only and stub hits are unrelated host words | call 0 · test 13 | zero — kept, documented |
| Skin | `lib.shared` | name-only and stub hits are unrelated host words | call 0 · name-only 4 · stub 28 · test 921 | zero — kept, documented |
| Skin | `lib.skins` | name-only and stub hits are unrelated host words | call 0 · stub 4 · test 193 | zero — kept, documented |
| Skin | `addonName` (descriptor) | not a Skin descriptor field | call 0 | zero — kept, documented |
| Skin | `thirdPartySkinAddons` (descriptor) | not a descriptor field | call 0 | zero — kept, documented |
| Skin | `thirdPartySkinsOff` (descriptor) | not a descriptor field | call 0 | zero — kept, documented |
| Widgets | `lib.AUTOCOMPLETE` | no host reads it | call 0 | zero — kept, documented |
| Widgets | `lib.BAR` | internal only; Character Ledger's degradation stub mirrors it (core/WidgetsSetup.lua:97) and its tests read it | call 0 · name-only 5 · stub 1 · test 41 | zero — kept, documented |
| Widgets | `lib.BarCompute` | internal only; read by host tests only | call 0 · test 6 | zero — kept, documented |
| Widgets | `lib.BarShade` | internal only; Character Ledger's `BarShade` (core/WidgetsSetup.lua:93) is its library-absent stub | call 0 · def 1 · test 2 | zero — kept, documented |
| Widgets | `lib.ChartMath` | no host calls it; LootHistory aligns its in/out strip through the chart instance's `XToPixel` instead | call 0 · test 2 | zero — kept, documented |
| Widgets | `lib.DRAG_HANDLE_STRINGS` | internal only | call 0 | zero — kept, documented |
| Widgets | `lib.HEADER_STRINGS` | internal only; read by WhatGroup's tests (tests/test_frame_header.lua:109) | call 0 · test 2 | zero — kept, documented |
| Widgets | `lib.HeaderButton` | internal only | call 0 · test 3 | zero — kept, documented |
| Widgets | `lib.OwnerWarnings` | no reader at all, inside the library or out (Widgets.lua:231; Charts.lua:420 cites it in a comment): kept for the published surface | call 0 | zero — kept, documented |
| Widgets | `applySkin` (descriptor) | no host passes it since v1.80.0 | call 0 | zero — kept, documented |
| Widgets | `backdrop` (descriptor) | no `CopyWindow` descriptor passes it | call 0 | zero — kept, documented |
| Widgets | `hoverXs` (descriptor) | hit scan sees no descriptor literal naming it | call 0 | zero — kept, documented |
| Widgets | `inset` (descriptor) | no `TestStrip` options or `DockTestStrip` spec passes it | call 0 | zero — kept, documented |
| Widgets | `integer` (descriptor) | hit scan sees no descriptor literal naming it | call 0 | zero — kept, documented |
| Widgets | `makeCloseButton` (descriptor) | no `CopyWindow` descriptor passes it | call 0 | zero — kept, documented |
| Widgets | `markers` (descriptor) | hit scan sees no descriptor literal naming it | call 0 | zero — kept, documented |
| Widgets | `onSettings` (descriptor) | no `CopyWindow` passes it; AbsorbTracker's `onSettings` (modules/Bar.lua:149) goes to `DragHandle`'s options table, an alias of its `settings` (WidgetsDragHandle.lua:576), outside this definition | call 0 | zero — kept, documented |
| Widgets | `scrollName` (descriptor) | library-internal caller only | call 0 | zero — kept, documented |
| Widgets | `series` (descriptor) | hit scan sees no descriptor literal naming it | call 0 | zero — kept, documented |
| Widgets | `xMax` (descriptor) | hit scan sees no descriptor literal naming it | call 0 | zero — kept, documented |
| Widgets | `xMin` (descriptor) | hit scan sees no descriptor literal naming it | call 0 | zero — kept, documented |
| Widgets | `yMax` (descriptor) | hit scan sees no descriptor literal naming it | call 0 | zero — kept, documented |
| Widgets | `yMin` (descriptor) | hit scan sees no descriptor literal naming it | call 0 | zero — kept, documented |
| DebugLog | `lib.AT_ENABLE_MAX` | tuning constant | call 0 · test 1 | zero — kept, documented |
| DebugLog | `lib.BUFFER_SLACK` | tuning constant | call 0 · test 1 | zero — kept, documented |
| DebugLog | `lib.DIAG_MAX_LINES` | tuning constant | call 0 · test 1 | zero — kept, documented |
| DebugLog | `lib.DIAG_MAX_PER_LIST` | tuning constant | call 0 | zero — kept, documented |
| DebugLog | `lib.GATE_MAX_KEYS` | tuning constant | call 0 | zero — kept, documented |
| DebugLog | `lib.MAX_BUFFER` | read by host tests only | call 0 · test 8 | zero — kept, documented |
| DebugLog | `lib.MakeCloseButton` | the 21 name hits are `Core.MakeCloseButton` calls | call 0 · name-only 40 · def 19 · stub 37 · test 174 | zero — kept, documented |
| DebugLog | `lib.STRINGS` | no host reads the table by name | call 0 · name-only 1 · stub 5 · test 191 | zero — kept, documented |
| DebugLog | `lib.TIME_COPY` | diagnostic switch | call 0 | zero — kept, documented |
| DebugLog | `BufferSize` (instance) | read by host tests only (62 hits) | call 0 · stub 15 · test 72 | zero — kept, documented |
| DebugLog | `BuildDiagnostics` (instance) | read by host tests only | call 0 · stub 21 · test 38 | zero — kept, documented |
| DebugLog | `CopyText` (instance) | read by host tests only | call 0 · stub 7 · test 29 | zero — kept, documented |
| DebugLog | `FindLine` (instance) | read by host tests only (88 hits) | call 0 · stub 15 · test 118 | zero — kept, documented |
| DebugLog | `LastLine` (instance) | read by host tests only | call 0 · stub 15 · test 53 | zero — kept, documented |
| DebugLog | `MakeCloseButton` (instance) | mirror of the lib-level member | call 0 · name-only 40 · def 19 · stub 37 · test 174 | zero — kept, documented |
| DebugLog | `Text` (instance) | the 15 name hits are `Sl:Text` (LibKa0s-Slash-1.0) calls | call 0 · name-only 282 · def 6 · stub 52 · test 490 | zero — kept, documented |
| DebugLog | `buffer` (instance) | read by host tests only (478 hits) | call 0 · stub 21 · test 657 | zero — kept, documented |
| DebugLog | `applySkin` (descriptor) | no host passes it since v1.80.0 | call 0 | zero — kept, documented |
| DebugLog | `diagnosticsEnablesLogging` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| DebugLog | `makeCloseButton` (descriptor) | BankLedger core/DebugLogSetup.lua:146 and LootHistory core/DebugLogSetup.lua:163 record why | call 0 | zero — kept, documented |
| DebugLog | `onSettings` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| DebugLog | `skin` (descriptor) | no descriptor passes it (MultiMeters settings/Schema_Compose.lua:248 is a locale key) | call 0 | zero — kept, documented |
| Slash | `CliResetAll` (instance) | LootHistory settings/Slash.lua:433-435 and BankLedger settings/Slash.lua:478-479 record why | call 0 · name-only 6 · def 3 · stub 11 · test 64 | zero — deliberate host copy |
| Launcher | `lib.STRINGS` | no host reads the table by name | call 0 · name-only 1 · stub 5 · test 191 | zero — kept, documented |
| Launcher | `Object` (instance) | read by host tests only (110 hits) | call 0 · def 2 · stub 15 · test 140 | zero — kept, documented |
| Launcher | `L` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Launcher | `entryClients` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Launcher | `owner` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Options | `lib.APPEARANCE_STRINGS` | no host call | call 0 · stub 1 · test 1 | zero — kept, documented |
| Options | `lib.KEYBIND_STRINGS` | no host call | call 0 · test 9 | zero — kept, documented |
| Options | `lib.LAYOUT` | KickCD core/Constants.lua:109-116 records the deletion; no host reads the table by name | call 0 · name-only 7 · stub 2 · test 106 | zero — kept, documented |
| Options | `lib.PatchAlwaysShowScrollbar` | reached through `EnsureScroll` | call 0 · stub 16 · test 25 | zero — kept, documented |
| Options | `lib.SKIN_NOTICE_VERSION` | internal only; read by Combat Trail's test harness (tests/run.lua:72) | call 0 · test 2 | zero — kept, documented |
| Options | `lib.SKIN_PICKER_STRINGS` | no host call | call 0 · test 17 | zero — kept, documented |
| Options | `lib.STRINGS` | no host reads the table by name | call 0 · name-only 1 · stub 5 · test 191 | zero — kept, documented |
| Options | `CHROME_GAP` (instance) | no host draws such chrome today | call 0 · name-only 2 · stub 7 · test 25 | zero — kept, documented |
| Options | `FONT_FLAGS` (instance) | MultiMeters settings/Schema_Compose.lua:165-184 records why | call 0 · name-only 1 · stub 5 · test 19 | zero — deliberate host copy |
| Options | `FONT_FLAGS_SORT` (instance) | MultiMeters settings/Schema_Compose.lua:184 | call 0 · stub 4 · test 16 | zero — deliberate host copy |
| Options | `ID_NAME_HINT` (instance) | reached through `IdInput` | call 0 · stub 24 · test 4 | zero — kept, documented |
| Options | `KeybindRows` (instance) | stubs only | call 0 · stub 31 · test 32 | zero — kept, documented |
| Options | `PatchAlwaysShowScrollbar` (instance) | reached through `EnsureScroll` | call 0 · stub 16 · test 25 | zero — kept, documented |
| Options | `RenderSchema` (instance) | superseded in practice | call 0 · stub 21 · test 25 | zero — kept, documented |
| Options | `SetChromeHeight` (instance) | reached through the chrome makers | call 0 · stub 20 · test 3 | zero — kept, documented |
| Options | `TAB_H` (instance) | no host measures its own strip today | call 0 · name-only 5 · stub 6 · test 37 | zero — kept, documented |
| Options | `UnnamedCandidates` (instance) | reached through `IdInput` | call 0 · stub 21 · test 2 | zero — kept, documented |
| Options | `VISIBILITY_SORT` (instance) | MultiMeters settings/Schema_Compose.lua:602-611 records why | call 0 · stub 4 · test 16 | zero — deliberate host copy |
| Options | `VISIBILITY_VALUES` (instance) | MultiMeters settings/Schema_Compose.lua:602-611 records why | call 0 · stub 4 · test 16 | zero — deliberate host copy |
| Options | `afterRestoreAll` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| IconBrowser | `lib.BUILTIN_TABS` | internal only | call 0 · test 1 | zero — kept, documented |
| IconBrowser | `lib.GLYPH_LABELS` | internal only | call 0 | zero — kept, documented |
| IconBrowser | `lib.MacroIcons` | internal only | call 0 · test 2 | zero — kept, documented |
| IconBrowser | `lib.SKIN_TOKENS` | internal only; the name hits are each host's own `NS.SKIN_TOKENS` | call 0 · name-only 29 · stub 16 · test 31 | zero — kept, documented |
| IconBrowser | `lib.STRINGS` | no host reads the table by name; the name hits are other majors' `STRINGS` | call 0 · name-only 1 · stub 5 · test 191 | zero — kept, documented |
| IconBrowser | `lib.Sources` | internal only | call 0 · test 2 | zero — kept, documented |
| IconBrowser | `lib.WOWHEAD_ICONS` | internal only | call 0 | zero — kept, documented |
| Perf | `lib.DEFAULT_RING` | default value | call 0 · test 2 | zero — kept, documented |
| Perf | `lib.SCHEMA` | read by host tests only | call 0 · name-only 1 · stub 1 · test 27 | zero — kept, documented |
| Perf | `lib.STRINGS` | no host reads the table by name | call 0 · name-only 1 · stub 5 · test 191 | zero — kept, documented |
| Perf | `Announce` (instance) | reached through `OnCommand` | call 0 · name-only 4 · def 1 · test 31 | zero — kept, documented |
| Perf | `BuildRecord` (instance) | reached through `OnCommand` | call 0 · name-only 1 · def 1 · test 26 | zero — kept, documented |
| Perf | `Cancel` (instance) | reached through `OnCommand` | call 0 · name-only 111 · def 13 · test 144 | zero — kept, documented |
| Perf | `Close` (instance) | no host brackets with `Open`/`Close` | call 0 · name-only 31 · def 15 · stub 4 · test 198 | zero — kept, documented |
| Perf | `Context` (instance) | reached through `OnCommand` | call 0 · name-only 16 · def 5 · test 41 | zero — kept, documented |
| Perf | `ContextLines` (instance) | reached through `OnCommand` | call 0 | zero — kept, documented |
| Perf | `EXPERIMENTS` (instance) | library-internal table (not in the instance table) | call 0 | zero — kept, documented |
| Perf | `FormatReport` (instance) | reached through `OnCommand` | call 0 · test 3 | zero — kept, documented |
| Perf | `HidePanel` (instance) | reached through `OnCommand` and the panel | call 0 · name-only 19 · def 1 · stub 1 · test 64 | zero — kept, documented |
| Perf | `IsPanelShown` (instance) | read by host tests only | call 0 · name-only 22 · stub 1 · test 84 | zero — kept, documented |
| Perf | `LABELS` (instance) | library-internal table (not in the instance table) | call 0 · name-only 10 · test 26 | zero — kept, documented |
| Perf | `Log` (instance) | reached through `OnCommand` | call 0 · name-only 12 · def 2 · test 34 | zero — kept, documented |
| Perf | `MarkReviewed` (instance) | reached through `OnCommand` | call 0 · test 1 | zero — kept, documented |
| Perf | `Measure` (instance) | reached through `OnCommand` | call 0 · name-only 4 · def 1 · test 14 | zero — kept, documented |
| Perf | `Open` (instance) | no host brackets with `Open`/`Close` | call 0 · name-only 69 · def 25 · stub 5 · test 781 | zero — kept, documented |
| Perf | `PanelIsActionable` (instance) | no `decorate` host | call 0 | zero — kept, documented |
| Perf | `PanelStateOf` (instance) | no `decorate` host | call 0 · test 2 | zero — kept, documented |
| Perf | `Progress` (instance) | reached through the panel | call 0 · test 1 | zero — kept, documented |
| Perf | `RefreshPanel` (instance) | reached through the library's own transitions | call 0 · name-only 51 · stub 15 · test 48 | zero — kept, documented |
| Perf | `Reset` (instance) | reached through `OnCommand` | call 0 · name-only 11 · def 13 · stub 19 · test 647 | zero — kept, documented |
| Perf | `Resume` (instance) | reached through `OnCommand` | call 0 · name-only 21 · def 53 · test 307 | zero — kept, documented |
| Perf | `SCHEMA` (instance) | read by host tests only | call 0 · name-only 1 · stub 1 · test 27 | zero — kept, documented |
| Perf | `STEPS` (instance) | reached through the panel | call 0 · test 16 | zero — kept, documented |
| Perf | `Save` (instance) | reached through `OnCommand` | call 0 · name-only 8 · def 7 · test 230 | zero — kept, documented |
| Perf | `ShowPanel` (instance) | reached through `OnCommand` | call 0 · name-only 20 · def 4 · stub 1 · test 47 | zero — kept, documented |
| Perf | `Start` (instance) | reached through `OnCommand` | call 0 · name-only 26 · def 19 · test 353 | zero — kept, documented |
| Perf | `StatusLines` (instance) | reached through `OnCommand` | call 0 · test 1 | zero — kept, documented |
| Perf | `Stop` (instance) | reached through `OnCommand` | call 0 · name-only 83 · def 14 · stub 1 · test 338 | zero — kept, documented |
| Perf | `Suspend` (instance) | reached through `OnCommand` | call 0 · name-only 15 · def 60 · test 240 | zero — kept, documented |
| Perf | `TogglePanel` (instance) | reached through `OnCommand` | call 0 · name-only 6 · test 1 | zero — kept, documented |
| Perf | `Usage` (instance) | reached through `OnCommand` | call 0 · name-only 22 · def 1 · test 136 | zero — kept, documented |
| Perf | `context` (instance) | instance data field (not in the instance table) | call 0 · name-only 2 · def 4 · test 255 | zero — kept, documented |
| Perf | `descriptor` (instance) | instance data field (not in the instance table) | call 0 · stub 12 · test 1022 | zero — kept, documented |
| Perf | `name` (instance) | instance data field (not in the instance table) | call 0 · name-only 978 · def 7 · stub 301 · test 13604 | zero — kept, documented |
| Perf | `ringMax` (instance) | instance data field (not in the instance table) | call 0 | zero — kept, documented |
| Perf | `slash` (instance) | instance data field (not in the instance table) | call 0 · name-only 3 · stub 107 · test 1891 | zero — kept, documented |
| Perf | `title` (instance) | instance data field (not in the instance table) | call 0 · name-only 375 · def 11 · stub 39 · test 2188 | zero — kept, documented |
| Perf | `L` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Perf | `decorate` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Perf | `onChange` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Perf | `onSettings` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Perf | `ring` (descriptor) | no descriptor passes it | call 0 | zero — kept, documented |
| Sim | `lib.SAMPLE` | internal only; read by host tests only (BankLedger, DropWatcher, CharacterLedger), which hold their library-absent fallbacks to it | call 0 · name-only 7 · test 18 | zero — kept, documented |
| Sim | `lib.STRINGS` | no host reads the table by name; LootHistory settings/Slash.lua:233 is LibKa0s-Slash-1.0's `lib.STRINGS` | call 0 · name-only 1 · stub 5 · test 191 | zero — kept, documented |
| Sim | `PanelRows` (instance) | reached through the library's step panel; the host defs are library-absent stubs | call 0 · def 6 · test 40 | zero — kept, documented |
| Sim | `Pause` (instance) | BankLedger's only "call" is its library-absent stub (core/SimSetup.lua:76-91, host contract H9), which the scan's block detector misses; DropWatcher's and LootHistory's name hits are their own stubs and other tables' members | call 2 · name-only 5 · def 3 · test 18 | zero — kept, documented (read by hand) |
| Sim | `RefreshPanel` (instance) | BankLedger's only "call" is its library-absent stub (core/SimSetup.lua:76-91, host contract H9), which the scan's block detector misses; the name hits are other tables' members and the other hosts' stubs | call 2 · name-only 49 · stub 15 · test 48 | zero — kept, documented (read by hand) |
| Sim | `Restart` (instance) | BankLedger's only "call" is its library-absent stub (core/SimSetup.lua:76-91, host contract H9), which the scan's block detector misses; DropWatcher's and LootHistory's name hits are their own stubs and other tables' members | call 2 · name-only 4 · test 12 | zero — kept, documented (read by hand) |
| Sim | `Resume` (instance) | BankLedger's only "call" is its library-absent stub (core/SimSetup.lua:76-91, host contract H9), which the scan's block detector misses; DropWatcher's and LootHistory's name hits are their own stubs and other tables' members | call 2 · name-only 19 · def 53 · test 307 | zero — kept, documented (read by hand) |
| Sim | `Run` (instance) | BankLedger's only "call" is its library-absent stub (core/SimSetup.lua:76-91, host contract H9), which the scan's block detector misses; DropWatcher's and LootHistory's name hits are their own stubs and other tables' members | call 3 · name-only 25 · def 8 · stub 6 · test 461 | zero — kept, documented (read by hand) |
| Sim | `Step` (instance) | AuraMaster's hits are `E.LuaCurveType.Step`; the host defs are library-absent stubs | call 0 · name-only 5 · def 7 · test 170 | zero — kept, documented |
| Sim | `TogglePanel` (instance) | BankLedger's only "call" is its library-absent stub (core/SimSetup.lua:76-91, host contract H9), which the scan's block detector misses; the name hits are other tables' members and the other hosts' stubs | call 2 · name-only 4 · test 1 | zero — kept, documented (read by hand) |
| Sim | `Unwrapped` (instance) | read by host tests only (all three Sim hosts); the host defs are library-absent seam stubs | call 0 · name-only 2 · def 7 · test 28 | zero — kept, documented |
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
| Core | `lib.ApplySkin` | 13: AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PremadeGroupsFilterExtension, QuickComms, RangeMaster, WhatGroup | call 13 · name-only 28 · def 9 · stub 32 · test 114 | consumed (13) |
| Core | `lib.ClassColor` | 6: AuraMaster, CharacterLedger, CombatTrail, MultiMeters, PartyFrameEnhanced, RangeMaster | call 7 · name-only 39 · def 3 · stub 8 · test 27 | consumed (6) |
| Core | `lib.HasSettings` | none | call 0 | zero — kept, documented |
| Core | `lib.IsConcatSafe` | 18: AbsorbTracker, BankLedger, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 18 · name-only 11 · stub 37 · test 97 | consumed (18) |
| Core | `lib.MakeCloseButton` | 17: AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 17 · name-only 23 · def 19 · stub 37 · test 174 | consumed (17) |
| Core | `lib.MakeResizable` | 8: BankLedger, CharacterLedger, CombatTrail, DropWatcher, LootHistory, MultiMeters, OutfitterReborn, QuickComms | call 8 · name-only 15 · def 2 · stub 9 · test 52 | consumed (8) |
| Core | `lib.New` | all 19 | call 19 · name-only 239 · def 39 · stub 29 · test 1103 | consumed (19) |
| Core | `lib.OpenSettings` | AuraMaster `settings/PresetPicker.lua:488` | call 1 · name-only 27 · def 10 · test 60 | thin (1) |
| Core | `lib.RGBA` | ConsumableMaster `core/CoreSetup.lua:163`; MultiMeters `core/CoreSetup.lua:243`; QuickComms `settings/SchemaMembers.lua:447` | call 4 · name-only 7 · stub 2 · test 49 | consumed (3) |
| Core | `lib.RaiseStaticPopups` | 4: AuraMaster, CombatTrail, OutfitterReborn, RangeMaster | call 4 · name-only 4 · stub 2 · test 5 | consumed (4) |
| Core | `lib.RegisterSettingsOpener` | none | call 0 | zero — kept, documented |
| Core | `lib.ResolveColor` | 10: AbsorbTracker, AuraMaster, ConsumableMaster, DropWatcher, KickCD, OutfitterReborn, PanelMaster, PartyFrameEnhanced, QuickComms, RangeMaster | call 11 · name-only 31 · def 1 · stub 9 · test 22 | consumed (10) |
| Core | `lib.SECRET` | 4: AbsorbTracker, KickCD, MultiMeters, RangeMaster | call 4 · name-only 3 · stub 12 · test 338 | consumed (4) |
| Core | `lib.SKIN` | 11: AuraMaster, CharacterLedger, CombatTrail, DropWatcher, LibKa0sSkinTester, MultiMeters, OutfitterReborn, PremadeGroupsFilterExtension, QuickComms, RangeMaster, WhatGroup | call 11 · name-only 8 · stub 27 · test 69 | consumed (11) |
| Core | `lib.SafeRegisterEvent` | all 19 | call 19 · name-only 89 · def 1 · stub 30 · test 73 | consumed (19) |
| Core | `lib.SafeRegisterEvents` | 14: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, DropWatcher, KickCD, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster | call 14 · name-only 4 · def 1 · stub 15 · test 12 | consumed (14) |
| Core | `lib.SafeRegisterUnitEvent` | 14: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, DropWatcher, KickCD, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster | call 14 · name-only 30 · def 1 · stub 15 · test 17 | consumed (14) |
| Core | `lib.SafeToString` | all 19 | call 19 · name-only 91 · stub 102 · test 193 | consumed (19) |
| Core | `Hide` (descriptor) | none | call 0 | zero — kept, documented |
| Core | `prefix` (descriptor) | all 19 | call 19 | consumed (19) |
| Core | `sep` (descriptor) | PrettyChat `core/CoreSetup.lua:176` | call 1 | thin (1) |
| Core | `sink` (descriptor) | 6: ConsumableMaster, DropWatcher, LibKa0sSkinTester, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 6 | consumed (6) |
| Tooltip | `lib.AttachTitleTip` | 4: BankLedger, CharacterLedger, CombatTrail, MultiMeters | call 8 · test 6 | consumed (4) |
| Tooltip | `lib.CLOSE_STRINGS` | none | call 0 | zero — kept, documented |
| Tooltip | `lib.CloseTip` | BankLedger `modules/Browser_Chrome.lua:82`; MultiMeters `modules/HeaderControls.lua:522` | call 3 | thin (2) |
| Tooltip | `lib.GroupOf` | none | call 0 · name-only 2 · def 1 · test 11 | zero — kept, documented |
| Tooltip | `lib.Own` | 5: CombatTrail, ConsumableMaster, MultiMeters, QuickComms, RangeMaster | call 7 · name-only 10 · def 3 · test 18 | consumed (5) |
| Tooltip | `lib.PlaceAttached` | 7: CharacterLedger, CombatTrail, DropWatcher, LibKa0sSkinTester, LootHistory, OutfitterReborn, QuickComms | call 12 · name-only 4 · def 2 · test 66 | consumed (7) |
| Tooltip | `lib.PlaceBeside` | 12: CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PremadeGroupsFilterExtension, QuickComms, RangeMaster, WhatGroup | call 21 · name-only 6 · def 1 · test 79 | consumed (12) |
| Tooltip | `lib.PlaceLauncher` | CharacterLedger `modules/Chrome.lua:237` | call 1 · name-only 1 · def 1 · test 5 | thin (1) |
| Tooltip | `lib.Replace` | LootHistory `core/Compat.lua:646`; OutfitterReborn `core/CoreSetup.lua:149` | call 2 · name-only 2 · test 23 | thin (2) |
| Tooltip | `lib.SetCloseTip` | none | call 0 | zero — kept, documented |
| Tooltip | `lib.SetGroup` | ConsumableMaster `modules/MacroBar.lua:179` | call 2 · name-only 5 · def 3 · test 9 | thin (1) |
| Tooltip | `lib.TIP_GAP` | 6: CombatTrail, LibKa0sSkinTester, MultiMeters, QuickComms, RangeMaster, WhatGroup | call 7 · name-only 7 · test 48 | consumed (6) |
| Env | `lib.GetAddOnMetadata` | all 19 | call 19 · name-only 36 · def 1 · test 140 | consumed (19) |
| Env | `lib.GetPlayerMapID` | BankLedger `core/EnvSetup.lua:83`; LootHistory `core/Compat.lua:86` | call 2 · test 3 | thin (2) |
| Env | `lib.GetZone` | BankLedger `core/EnvSetup.lua:99`; LootHistory `core/Compat.lua:77` | call 2 · test 3 | thin (2) |
| Env | `lib.Version` | all 19 | call 19 · name-only 58 · def 21 · stub 25 · test 315 | consumed (19) |
| Compat | `lib.CanAccess` | 6: AuraMaster, CombatTrail, DropWatcher, MultiMeters, OutfitterReborn, RangeMaster | call 6 · name-only 34 · test 75 | consumed (6) |
| Compat | `lib.CharacterKey` | 5: DropWatcher, MultiMeters, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 7 · name-only 2 · def 2 · test 18 | consumed (5) |
| Compat | `lib.ClientKey` | 7: AuraMaster, CombatTrail, ConsumableMaster, DropWatcher, OutfitterReborn, QuickComms, RangeMaster | call 7 · name-only 39 · def 3 · test 101 | consumed (7) |
| Compat | `lib.ForClient` | 6: AuraMaster, CombatTrail, ConsumableMaster, DropWatcher, OutfitterReborn, RangeMaster | call 6 · name-only 69 · def 2 · test 54 | consumed (6) |
| Compat | `lib.GetSpecialization` | 8: CombatTrail, ConsumableMaster, DropWatcher, KickCD, MultiMeters, OutfitterReborn, PremadeGroupsFilterExtension, RangeMaster | call 10 · name-only 16 · test 74 | consumed (8) |
| Compat | `lib.GetSpecializationInfo` | 8: CombatTrail, ConsumableMaster, DropWatcher, KickCD, MultiMeters, OutfitterReborn, PremadeGroupsFilterExtension, RangeMaster | call 10 · name-only 13 · def 1 · test 85 | consumed (8) |
| Compat | `lib.GetSpellCooldown` | KickCD `core/Compat.lua:101`; WhatGroup `core/Compat.lua:97` | call 2 · name-only 5 · def 1 · test 97 | thin (2) |
| Compat | `lib.GetSpellInfo` | 4: AuraMaster, KickCD, MultiMeters, RangeMaster | call 4 · name-only 36 · def 1 · test 157 | consumed (4) |
| Compat | `lib.GetSpellName` | ConsumableMaster `core/Compat.lua:124`; LootHistory `core/Compat.lua:170`; WhatGroup `core/Compat.lua:52` | call 3 · name-only 17 · test 128 | consumed (3) |
| Compat | `lib.GetSpellTexture` | KickCD `core/Compat.lua:160`; MultiMeters `core/Compat.lua:79`; WhatGroup `core/Compat.lua:60` | call 3 · name-only 14 · test 76 | consumed (3) |
| Compat | `lib.IsForever` | 4: AuraMaster, CombatTrail, DropWatcher, RangeMaster | call 4 · name-only 14 · def 3 · test 89 | consumed (4) |
| Compat | `lib.IsRetail` | 4: AuraMaster, CombatTrail, DropWatcher, RangeMaster | call 4 · name-only 1 · def 2 · test 39 | consumed (4) |
| Compat | `lib.IsSafeKey` | 7: AuraMaster, CombatTrail, DropWatcher, MultiMeters, OutfitterReborn, QuickComms, RangeMaster | call 7 · name-only 74 · test 58 | consumed (7) |
| Compat | `lib.IsSecret` | 12: AuraMaster, CombatTrail, ConsumableMaster, DropWatcher, KickCD, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, QuickComms, RangeMaster, WhatGroup | call 12 · name-only 192 · def 1 · test 118 | consumed (12) |
| Compat | `lib.RealmKey` | 4: CombatTrail, MultiMeters, PremadeGroupsFilterExtension, WhatGroup | call 4 · name-only 1 · test 10 | consumed (4) |
| Compat | `lib.RegionalNames` | 6: DropWatcher, MultiMeters, OutfitterReborn, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 6 · name-only 14 · def 1 · test 18 | consumed (6) |
| Compat | `lib.UnitCharacterName` | 8: CombatTrail, DropWatcher, MultiMeters, OutfitterReborn, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 9 · name-only 18 · def 4 · test 31 | consumed (8) |
| Role | `lib.Groups` | DropWatcher `core/CompatClient.lua:123`; QuickComms `core/Compat.lua:457` | call 6 · name-only 37 · def 5 · stub 2 · test 224 | thin (2) |
| Role | `lib.Resolve` | DropWatcher `core/CompatClient.lua:179`; QuickComms `core/Compat.lua:220` | call 3 · name-only 100 · def 19 · stub 19 · test 342 | thin (2) |
| Role | `lib.SetOverride` | DropWatcher `core/CompatClient.lua:202`; QuickComms `core/Compat.lua:257` | call 4 · name-only 38 · test 33 | thin (2) |
| Role | `lib.Spec` | DropWatcher `core/Compat.lua:353`; QuickComms `core/Compat.lua:135` | call 3 · name-only 20 · def 3 · test 74 | thin (2) |
| Role | `lib.SpecsForClass` | QuickComms `core/Compat.lua:271` | call 2 · name-only 1 · def 1 · test 1 | thin (1) |
| Role | `lib.TALENT_GROUP_ROLE` | none | call 0 | zero — kept, documented |
| Lifecycle | `lib.HOLD_DISABLED` | all 19 | call 21 · name-only 43 · stub 13 · test 34 | consumed (19) |
| Lifecycle | `lib.HOLD_PERF` | 12: AuraMaster, CharacterLedger, CombatTrail, DropWatcher, LibKa0sSkinTester, LootHistory, OutfitterReborn, PanelMaster, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 12 · name-only 1 · stub 10 · test 113 | consumed (12) |
| Lifecycle | `lib.New` | 16: AuraMaster, BankLedger, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 16 · name-only 242 · def 39 · stub 29 · test 1103 | consumed (16) |
| Lifecycle | `Hold` (instance) | none | call 0 · name-only 5 · def 5 · stub 34 · test 113 | zero — kept, documented |
| Lifecycle | `Holds` (instance) | all 19 | call 30 · stub 19 · test 32 | consumed (19) |
| Lifecycle | `IsDown` (instance) | all 19 | call 41 · name-only 16 · def 1 · stub 17 · test 65 | consumed (19) |
| Lifecycle | `IsHeld` (instance) | 12: AuraMaster, BankLedger, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, LibKa0sSkinTester, MultiMeters, OutfitterReborn, QuickComms, RangeMaster, WhatGroup | call 14 · stub 19 · test 33 | consumed (12) |
| Lifecycle | `PrintHolds` (instance) | none | call 0 · stub 17 · test 6 | zero — kept, documented |
| Lifecycle | `Reevaluate` (instance) | 13: AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 13 · name-only 11 · def 2 · stub 18 · test 20 | consumed (13) |
| Lifecycle | `Release` (instance) | none | call 0 · name-only 18 · def 10 · stub 33 · test 201 | zero — kept, documented |
| Lifecycle | `Set` (instance) | all 19 | call 34 · name-only 288 · def 31 · stub 45 · test 3412 | consumed (19) |
| Lifecycle | `name` (instance) | none | call 0 · name-only 978 · def 7 · stub 301 · test 13604 | zero — kept, documented |
| Lifecycle | `debug` (descriptor) | all 19 | call 19 | consumed (19) |
| Lifecycle | `name` (descriptor) | all 19 | call 19 | consumed (19) |
| Lifecycle | `print` (descriptor) | all 19 | call 19 | consumed (19) |
| Lifecycle | `standDown` (descriptor) | all 19 | call 19 | consumed (19) |
| Lifecycle | `standUp` (descriptor) | all 19 | call 19 | consumed (19) |
| Bus | `lib.Catalog` | 14: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, QuickComms, RangeMaster | call 15 · name-only 6 · def 1 · stub 11 · test 67 | consumed (14) |
| Bus | `lib.New` | 10: AbsorbTracker, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, MultiMeters, OutfitterReborn, PartyFrameEnhanced, QuickComms, RangeMaster | call 10 · name-only 248 · def 39 · stub 29 · test 1103 | consumed (10) |
| Bus | `NewTarget` (instance) | 6: CombatTrail, ConsumableMaster, DropWatcher, OutfitterReborn, PartyFrameEnhanced, QuickComms | call 31 · name-only 4 · stub 11 · test 50 | consumed (6) |
| Bus | `StandDown` (instance) | 6: CombatTrail, ConsumableMaster, DropWatcher, OutfitterReborn, PartyFrameEnhanced, QuickComms | call 6 · name-only 44 · def 36 · stub 27 · test 108 | consumed (6) |
| Bus | `StandUp` (instance) | 6: CombatTrail, ConsumableMaster, DropWatcher, OutfitterReborn, PartyFrameEnhanced, QuickComms | call 6 · name-only 35 · def 24 · stub 29 · test 72 | consumed (6) |
| Bus | `isDown` (descriptor) | 10: AbsorbTracker, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, MultiMeters, OutfitterReborn, PartyFrameEnhanced, QuickComms, RangeMaster | call 10 | consumed (10) |
| Bus | `name` (descriptor) | 10: AbsorbTracker, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, MultiMeters, OutfitterReborn, PartyFrameEnhanced, QuickComms, RangeMaster | call 10 | consumed (10) |
| Schema | `lib.New` | all 19 | call 20 · name-only 238 · def 39 · stub 29 · test 1103 | consumed (19) |
| Schema | `lib.Read` | 10: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, KickCD, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, RangeMaster | call 20 · name-only 29 · def 23 · stub 7 · test 172 | consumed (10) |
| Schema | `lib.STRINGS` | none | call 0 · name-only 1 · stub 5 · test 191 | zero — kept, documented |
| Schema | `lib.SameValue` | AuraMaster `settings/Schema.lua:600`; BankLedger `settings/Schema.lua:891` | call 2 · name-only 15 · def 14 · stub 4 · test 20 | thin (2) |
| Schema | `lib.SplitPath` | 6: AuraMaster, CharacterLedger, CombatTrail, KickCD, MultiMeters, OutfitterReborn | call 6 · name-only 48 · def 18 · stub 6 · test 12 | consumed (6) |
| Schema | `lib.Write` | 7: AbsorbTracker, AuraMaster, CombatTrail, KickCD, PanelMaster, PartyFrameEnhanced, RangeMaster | call 9 · name-only 34 · def 19 · stub 4 · test 33 | consumed (7) |
| Schema | `AddRows` (instance) | 13: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, ConsumableMaster, KickCD, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PrettyChat, RangeMaster | call 18 · name-only 21 · def 17 · stub 2 · test 18 | consumed (13) |
| Schema | `AllRows` (instance) | 5: AbsorbTracker, BankLedger, OutfitterReborn, PrettyChat, RangeMaster | call 9 · name-only 9 · def 16 · stub 4 · test 35 | consumed (5) |
| Schema | `ApplyDefault` (instance) | 10: AbsorbTracker, BankLedger, CharacterLedger, CombatTrail, KickCD, MultiMeters, OutfitterReborn, PartyFrameEnhanced, PrettyChat, RangeMaster | call 16 · name-only 51 · def 18 · stub 17 · test 132 | consumed (10) |
| Schema | `BulkAdd` (instance) | AuraMaster `settings/Schema.lua:620`; PrettyChat `settings/Schema.lua:853` | call 2 · name-only 1 · def 14 · stub 2 · test 7 | thin (2) |
| Schema | `BulkBegin` (instance) | 11: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, KickCD, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, RangeMaster | call 21 · name-only 22 · def 16 · stub 7 · test 37 | consumed (11) |
| Schema | `BulkEnd` (instance) | 11: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, KickCD, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, RangeMaster | call 21 · name-only 22 · def 16 · stub 7 · test 44 | consumed (11) |
| Schema | `BulkRun` (instance) | 11: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PrettyChat, RangeMaster | call 14 · name-only 10 · def 16 · stub 7 · test 12 | consumed (11) |
| Schema | `ConsumeResetCount` (instance) | 4: AbsorbTracker, KickCD, PartyFrameEnhanced, RangeMaster | call 4 · name-only 15 · def 14 · stub 2 · test 10 | consumed (4) |
| Schema | `CountOffDefault` (instance) | PrettyChat `settings/Schema.lua:661` | call 1 · def 14 · stub 2 · test 6 | thin (1) |
| Schema | `Default` (instance) | BankLedger `settings/Schema.lua:916`; PanelMaster `settings/Schema.lua:929` | call 2 · name-only 8 · def 15 · stub 15 · test 2114 | thin (2) |
| Schema | `FindRow` (instance) | 13: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, ConsumableMaster, KickCD, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PrettyChat, RangeMaster | call 40 · name-only 55 · def 16 · stub 12 · test 350 | consumed (13) |
| Schema | `Get` (instance) | 12: AbsorbTracker, BankLedger, CharacterLedger, CombatTrail, ConsumableMaster, KickCD, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PrettyChat, RangeMaster | call 21 · name-only 536 · def 52 · stub 19 · test 2303 | consumed (12) |
| Schema | `InBulk` (instance) | AuraMaster `settings/Schema.lua:582`; CharacterLedger `settings/OptionsSetup.lua:35` | call 4 · name-only 1 · def 14 · stub 2 · test 17 | thin (2) |
| Schema | `Reindex` (instance) | AuraMaster `settings/Schema.lua:292` | call 1 · def 14 · stub 2 · test 15 | thin (1) |
| Schema | `ResetCounted` (instance) | 5: AbsorbTracker, CharacterLedger, KickCD, PartyFrameEnhanced, RangeMaster | call 5 · name-only 7 · def 14 · stub 2 · test 5 | consumed (5) |
| Schema | `Set` (instance) | 12: AbsorbTracker, BankLedger, CharacterLedger, CombatTrail, ConsumableMaster, KickCD, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PrettyChat, RangeMaster | call 29 · name-only 293 · def 31 · stub 45 · test 3412 | consumed (12) |
| Schema | `SetMany` (instance) | 5: CharacterLedger, ConsumableMaster, MultiMeters, OutfitterReborn, PanelMaster | call 5 · name-only 9 · def 15 · stub 5 · test 133 | consumed (5) |
| Schema | `Validate` (instance) | 10: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, KickCD, OutfitterReborn, PanelMaster, PartyFrameEnhanced, RangeMaster | call 11 · name-only 11 · def 19 · stub 2 · test 33 | consumed (10) |
| Schema | `L` (descriptor) | 4: BankLedger, LootHistory, MultiMeters, PanelMaster | call 4 | consumed (4) |
| Schema | `resetExempt` (descriptor) | 16: AbsorbTracker, BankLedger, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, RangeMaster, WhatGroup | call 16 | consumed (16) |
| Schema | `rows` (descriptor) | all 19 | call 20 | consumed (19) |
| Schema | `writeThrough` (descriptor) | 14: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, KickCD, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, QuickComms, RangeMaster | call 14 | consumed (14) |
| Pool | `lib.Acquire` | 10: AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, LootHistory, MultiMeters, OutfitterReborn, QuickComms, RangeMaster | call 52 · name-only 26 · def 15 · test 70 | consumed (10) |
| Pool | `lib.AcquireKeyed` | KickCD `modules/IconGrid.lua:208`; RangeMaster `modules/Container.lua:808` | call 3 · def 4 · test 8 | thin (2) |
| Pool | `lib.Counts` | LootHistory `modules/Diagnostics.lua:336` | call 2 · name-only 3 · def 14 · test 86 | thin (1) |
| Pool | `lib.CountsKeyed` | KickCD `modules/Diagnostics.lua:183`; RangeMaster `modules/Container.lua:1040` | call 3 · def 4 · test 7 | thin (2) |
| Pool | `lib.New` | 10: AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, LootHistory, MultiMeters, OutfitterReborn, QuickComms, RangeMaster | call 43 · name-only 215 · def 39 · stub 29 · test 1103 | consumed (10) |
| Pool | `lib.NewKeyed` | KickCD `modules/IconGrid.lua:107`; RangeMaster `modules/Container.lua:142` | call 4 · def 4 · test 5 | thin (2) |
| Pool | `lib.ReleaseAll` | 10: AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, LootHistory, MultiMeters, OutfitterReborn, QuickComms, RangeMaster | call 56 · name-only 13 · def 12 · test 44 | consumed (10) |
| Pool | `lib.ReleaseAllKeyed` | KickCD `modules/IconGrid.lua:225`; RangeMaster `modules/Container.lua:989` | call 5 · def 4 · test 6 | thin (2) |
| Item | `lib.BonusIDsFromLink` | BankLedger `core/Util.lua:106`; LootHistory `modules/Export.lua:36`; OutfitterReborn `core/ItemSetup.lua:20` | call 4 · name-only 1 · def 3 · test 35 | consumed (3) |
| Item | `lib.ItemIDFromLink` | 5: BankLedger, ConsumableMaster, DropWatcher, LootHistory, OutfitterReborn | call 20 · name-only 1 · def 5 · test 36 | consumed (5) |
| Item | `lib.LoadItem` | BankLedger `modules/Backfill.lua:158`; DropWatcher `modules/ItemFacts.lua:320`; LootHistory `core/Database.lua:522` | call 6 · def 3 · test 22 | consumed (3) |
| Item | `lib.QualityFromLink` | DropWatcher `core/ItemRead.lua:165`; LootHistory `core/Compat.lua:238` | call 2 · def 3 · test 9 | thin (2) |
| Item | `lib.QualityLabel` | BankLedger `core/Constants.lua:266`; DropWatcher `modules/InsightsFilters.lua:327`; LootHistory `core/Constants.lua:177` | call 22 · def 3 · test 26 | consumed (3) |
| Glow | `lib.Start` | DropWatcher `modules/Glow.lua:147`; KickCD `modules/IconGrid_Render.lua:614`; QuickComms `modules/Glow.lua:81` | call 4 · name-only 22 · def 19 · test 353 | consumed (3) |
| Glow | `lib.Stop` | DropWatcher `modules/Glow.lua:122`; KickCD `modules/IconGrid_Render.lua:523`; QuickComms `modules/Glow.lua:69` | call 4 · name-only 79 · def 14 · stub 1 · test 338 | consumed (3) |
| Toast | `lib.DURATION` | none | call 0 · name-only 2 · test 18 | zero — kept, documented |
| Toast | `lib.HEIGHT` | none | call 0 · name-only 26 · test 92 | zero — kept, documented |
| Toast | `lib.MAX_QUEUE` | none | call 0 · name-only 5 · test 6 | zero — kept, documented |
| Toast | `lib.New` | 4: CharacterLedger, CombatTrail, DropWatcher, QuickComms | call 4 · name-only 254 · def 39 · stub 29 · test 1103 | consumed (4) |
| Toast | `lib.POINT` | none | call 0 · name-only 4 · stub 6 · test 100 | zero — kept, documented |
| Toast | `lib.PREVIEW` | CombatTrail `core/ToastSetup.lua:18` | call 1 · test 17 | thin (1) |
| Toast | `lib.STACK_GAP` | DropWatcher `core/ToastSetup.lua:36` | call 1 | thin (1) |
| Toast | `lib.STRATA` | none | call 0 · name-only 93 · test 115 | zero — kept, documented |
| Toast | `lib.WIDTH` | none | call 0 · name-only 52 · test 55 | zero — kept, documented |
| Toast | `build` (descriptor) | DropWatcher `modules/Toast.lua:504` | call 1 | thin (1, read by hand) |
| Toast | `debug` (descriptor) | CharacterLedger `modules/Alerts.lua:453` | call 1 | thin (1) |
| Toast | `defaultPosition` (descriptor) | DropWatcher `modules/Toast.lua:508` | call 0 | thin (1, read by hand) |
| Toast | `draggable` (descriptor) | DropWatcher `modules/Toast.lua:513` | call 1 | thin (1, read by hand) |
| Toast | `duration` (descriptor) | DropWatcher `modules/Toast.lua:509` | call 1 | thin (1, read by hand) |
| Toast | `getPosition` (descriptor) | DropWatcher `modules/Toast.lua:514` | call 1 | thin (1, read by hand) |
| Toast | `height` (descriptor) | DropWatcher `modules/Toast.lua:506` | call 0 | thin (1, read by hand) |
| Toast | `maxQueue` (descriptor) | DropWatcher `modules/Toast.lua:507` | call 0 | thin (1, read by hand) |
| Toast | `name` (descriptor) | DropWatcher `modules/Toast.lua:503` | call 1 | thin (1, read by hand) |
| Toast | `owner` (descriptor) | 4: CharacterLedger, CombatTrail, DropWatcher, QuickComms | call 4 | consumed (4) |
| Toast | `scale` (descriptor) | DropWatcher `modules/Toast.lua:510` | call 0 | thin (1, read by hand) |
| Toast | `setPosition` (descriptor) | DropWatcher `modules/Toast.lua:515` | call 1 | thin (1, read by hand) |
| Toast | `sound` (descriptor) | DropWatcher `modules/Toast.lua:511` | call 1 | thin (1, read by hand) |
| Toast | `soundFile` (descriptor) | CombatTrail `modules/BestToast.lua:366` | call 0 | thin (1, read by hand) |
| Toast | `soundKit` (descriptor) | none | call 0 | zero — kept, documented |
| Toast | `stack` (descriptor) | CharacterLedger `modules/Alerts.lua:441` | call 1 | thin (1) |
| Toast | `stackGap` (descriptor) | DropWatcher `modules/Toast.lua:551` | call 0 | thin (1, read by hand) |
| Toast | `stackGrow` (descriptor) | DropWatcher `modules/Toast.lua:549`; QuickComms `modules/AutoThank_Toast.lua:202` | call 0 | thin (2, read by hand) |
| Toast | `width` (descriptor) | DropWatcher `modules/Toast.lua:505` | call 1 | thin (1, read by hand) |
| Callout | `lib.ANIMS` | none | call 0 | zero — kept, documented |
| Callout | `lib.CHANNELS` | none | call 0 · name-only 2 · test 2 | zero — kept, documented |
| Callout | `lib.DEFAULTS` | none | call 0 · name-only 6 · stub 1 · test 12 | zero — kept, documented |
| Callout | `lib.FOLLOW_FROM` | none | call 0 | zero — kept, documented |
| Callout | `lib.FONT_DEFAULT` | none | call 0 | zero — kept, documented |
| Callout | `lib.FONT_FACES` | none | call 0 | zero — kept, documented |
| Callout | `lib.FONT_GAME` | none | call 0 | zero — kept, documented |
| Callout | `lib.FONT_SKIN` | none | call 0 | zero — kept, documented |
| Callout | `lib.FROM_SKIN` | none | call 0 · name-only 16 · stub 59 · test 64 | zero — kept, documented |
| Callout | `lib.FollowKeys` | none | call 0 | zero — kept, documented |
| Callout | `lib.GLOWS` | none | call 0 | zero — kept, documented |
| Callout | `lib.GLOW_LEGACY` | CombatTrail `core/Database.lua:124` | call 1 | thin (1) |
| Callout | `lib.KINDS` | none | call 0 · name-only 7 · test 17 | zero — kept, documented |
| Callout | `lib.LINES` | none | call 0 · name-only 2 · stub 1 · test 16 | zero — kept, documented |
| Callout | `lib.MAX_FROM` | none | call 0 · test 1 | zero — kept, documented |
| Callout | `lib.MEANING` | none | call 0 | zero — kept, documented |
| Callout | `lib.MigrateGlow` | CombatTrail `core/Database.lua:167` | call 1 | thin (1) |
| Callout | `lib.MoveToSkin` | CombatTrail `core/Database.lua:104` | call 2 | thin (1) |
| Callout | `lib.New` | CombatTrail `core/CalloutSetup.lua:96` | call 1 · name-only 257 · def 39 · stub 29 · test 1103 | thin (1) |
| Callout | `lib.OFF` | none | call 0 · name-only 10 · stub 8 · test 109 | zero — kept, documented |
| Callout | `lib.OUTLINES` | none | call 0 | zero — kept, documented |
| Callout | `lib.PACKS` | none | call 0 · test 10 | zero — kept, documented |
| Callout | `lib.PLAY_COUNTDOWN` | none | call 0 · test 2 | zero — kept, documented |
| Callout | `lib.SETTINGS` | none | call 0 · name-only 2 · stub 1 · test 17 | zero — kept, documented |
| Callout | `lib.SETTINGS_SIDE_TABS` | none | call 0 | zero — kept, documented |
| Callout | `lib.SETTINGS_STRINGS` | none | call 0 | zero — kept, documented |
| Callout | `lib.SETTINGS_TABS` | none | call 0 | zero — kept, documented |
| Callout | `lib.SIZE_MAX` | none | call 0 | zero — kept, documented |
| Callout | `lib.SIZE_MIN` | none | call 0 | zero — kept, documented |
| Callout | `lib.SOUND_EXT` | none | call 0 · test 2 | zero — kept, documented |
| Callout | `lib.STOCK` | none | call 0 · test 1 | zero — kept, documented |
| Callout | `lib.STOCK_ORDER` | none | call 0 | zero — kept, documented |
| Callout | `lib.STRATA` | none | call 0 · name-only 93 · test 115 | zero — kept, documented |
| Callout | `lib.TTS` | none | call 0 | zero — kept, documented |
| Callout | `lib.WIDTH` | none | call 0 · name-only 52 · test 55 | zero — kept, documented |
| Callout | `addon` (descriptor) | CombatTrail `core/CalloutSetup.lua:90` | call 1 | thin (1) |
| Callout | `colorEncode` (descriptor) | CombatTrail `modules/Countdown.lua:96` | call 0 | thin (1, read by hand) |
| Callout | `db` (descriptor) | CombatTrail `modules/Countdown.lua:90` | call 0 | thin (1, read by hand) |
| Callout | `debug` (descriptor) | CombatTrail `core/CalloutSetup.lua:93` | call 1 | thin (1) |
| Callout | `label` (descriptor) | none | call 0 | zero — kept, documented |
| Callout | `name` (descriptor) | CombatTrail `modules/Countdown.lua:89` | call 0 | thin (1, read by hand) |
| Callout | `packs` (descriptor) | CombatTrail `core/CalloutSetup.lua:92` | call 1 | thin (1) |
| Callout | `path` (descriptor) | CombatTrail `modules/Countdown.lua:94` | call 0 | thin (1, read by hand) |
| Callout | `set` (descriptor) | CombatTrail `modules/Countdown.lua:95` | call 0 | thin (1, read by hand) |
| Callout | `skin` (descriptor) | CombatTrail `core/CalloutSetup.lua:91` | call 1 | thin (1) |
| Callout | `soundsBase` (descriptor) | none | call 0 | zero — kept, documented |
| Callout | `vendorPath` (descriptor) | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.ARRIVE` | none | call 0 · test 1 | zero — kept, documented |
| WaypointArrow | `lib.ART` | none | call 0 · name-only 4 · test 10 | zero — kept, documented |
| WaypointArrow | `lib.COMPACT_FROM` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.DEFAULTS` | none | call 0 · name-only 6 · stub 1 · test 12 | zero — kept, documented |
| WaypointArrow | `lib.DEFAULT_POINT` | none | call 0 · name-only 3 | zero — kept, documented |
| WaypointArrow | `lib.DEFAULT_STYLE` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.DISTANCE_UNITS` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.Distance` | none | call 0 · name-only 4 · def 3 · test 10 | zero — kept, documented |
| WaypointArrow | `lib.DistanceUnitsValues` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.FAR` | none | call 0 · test 10 | zero — kept, documented |
| WaypointArrow | `lib.FLAGS_FROM_SKIN` | none | call 0 · name-only 3 | zero — kept, documented |
| WaypointArrow | `lib.FONT_DEFAULT` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.FONT_FLAGS` | none | call 0 · name-only 1 · stub 5 · test 19 | zero — kept, documented |
| WaypointArrow | `lib.FONT_SIZE_MAX` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.FONT_SIZE_MIN` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.Fade` | none | call 0 · test 14 | zero — kept, documented |
| WaypointArrow | `lib.FormatDistance` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.GROUND` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.GroundFrame` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.GroundTexCoord` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.HIT_PAD` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.IsStyle` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.MEDIA_DIR` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.MENU_ITEMS` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.MapWorldPos` | none | call 0 · name-only 3 · def 1 · test 4 | zero — kept, documented |
| WaypointArrow | `lib.Mix` | none | call 0 · test 1 | zero — kept, documented |
| WaypointArrow | `lib.NEAR` | none | call 0 · test 17 | zero — kept, documented |
| WaypointArrow | `lib.New` | CharacterLedger `modules/WaypointArrow.lua:209` | call 1 · name-only 257 · def 39 · stub 29 · test 1103 | thin (1) |
| WaypointArrow | `lib.POSITION_MAX` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.POSITION_MIN` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.PlayerFacing` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.PlayerWorldPos` | none | call 0 · name-only 1 · def 1 · test 4 | zero — kept, documented |
| WaypointArrow | `lib.Rotation` | none | call 0 · test 3 | zero — kept, documented |
| WaypointArrow | `lib.SAMPLE_ROTATION` | none | call 0 · test 1 | zero — kept, documented |
| WaypointArrow | `lib.SAMPLE_YARDS` | none | call 0 · test 1 | zero — kept, documented |
| WaypointArrow | `lib.SCALE_MAX` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.SCALE_MIN` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.SCALE_STEP` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.SETTINGS` | none | call 0 · name-only 2 · stub 1 · test 17 | zero — kept, documented |
| WaypointArrow | `lib.SETTINGS_STRINGS` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.SHADOW_BOX` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.SHADOW_OFFSET` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.SHARE_LEAD` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.SKIN_FAR` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.SKIN_NEAR` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.STRATA` | none | call 0 · name-only 93 · test 115 | zero — kept, documented |
| WaypointArrow | `lib.STRINGS` | none | call 0 · name-only 1 · stub 5 · test 191 | zero — kept, documented |
| WaypointArrow | `lib.STYLES` | none | call 0 · name-only 7 · test 23 | zero — kept, documented |
| WaypointArrow | `lib.SettingsRows` | CharacterLedger `modules/WaypointArrow.lua:374` | call 2 · name-only 1 · def 2 · test 1 | thin (1) |
| WaypointArrow | `lib.ShareText` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.StyleValues` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.TEXT_GAP` | none | call 0 · name-only 7 · test 1 | zero — kept, documented |
| WaypointArrow | `lib.TEXT_POSITIONS` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.TEXT_ROOM` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.THROTTLE` | CharacterLedger `modules/WaypointArrow.lua:40` | call 1 · name-only 9 · test 15 | thin (1) |
| WaypointArrow | `lib.TextPositionValues` | none | call 0 | zero — kept, documented |
| WaypointArrow | `lib.UNITS` | none | call 0 · name-only 11 · test 40 | zero — kept, documented |
| WaypointArrow | `addon` (descriptor) | CharacterLedger `modules/WaypointArrow.lua:210` | call 1 | thin (1) |
| WaypointArrow | `arrive` (descriptor) | none | call 0 | zero — kept, documented |
| WaypointArrow | `canDrag` (descriptor) | none | call 0 | zero — kept, documented |
| WaypointArrow | `debug` (descriptor) | CharacterLedger `modules/WaypointArrow.lua:217` | call 1 | thin (1) |
| WaypointArrow | `far` (descriptor) | none | call 0 | zero — kept, documented |
| WaypointArrow | `format` (descriptor) | none | call 0 | zero — kept, documented |
| WaypointArrow | `mediaBase` (descriptor) | none | call 0 | zero — kept, documented |
| WaypointArrow | `menu` (descriptor) | none | call 0 | zero — kept, documented |
| WaypointArrow | `menuItems` (descriptor) | CharacterLedger `modules/WaypointArrow.lua:216` | call 1 | thin (1) |
| WaypointArrow | `name` (descriptor) | CharacterLedger `modules/WaypointArrow.lua:210` | call 1 | thin (1) |
| WaypointArrow | `near` (descriptor) | none | call 0 | zero — kept, documented |
| WaypointArrow | `onArrive` (descriptor) | CharacterLedger `modules/WaypointArrow.lua:214` | call 1 | thin (1) |
| WaypointArrow | `onClear` (descriptor) | CharacterLedger `modules/WaypointArrow.lua:215` | call 1 | thin (1) |
| WaypointArrow | `onClick` (descriptor) | CharacterLedger `modules/WaypointArrow.lua:214` | call 1 | thin (1) |
| WaypointArrow | `onEnter` (descriptor) | CharacterLedger `modules/WaypointArrow.lua:214` | call 1 | thin (1) |
| WaypointArrow | `onLeave` (descriptor) | CharacterLedger `modules/WaypointArrow.lua:214` | call 1 | thin (1) |
| WaypointArrow | `onMoved` (descriptor) | none | call 0 | zero — kept, documented |
| WaypointArrow | `onSampleClear` (descriptor) | CharacterLedger `modules/WaypointArrow.lua:215` | call 1 | thin (1) |
| WaypointArrow | `parent` (descriptor) | none | call 0 | zero — kept, documented |
| WaypointArrow | `paths` (descriptor) | CharacterLedger `modules/WaypointArrow.lua:213` | call 1 | thin (1) |
| WaypointArrow | `point` (descriptor) | none | call 0 | zero — kept, documented |
| WaypointArrow | `set` (descriptor) | CharacterLedger `modules/WaypointArrow.lua:213` | call 1 | thin (1) |
| WaypointArrow | `skin` (descriptor) | CharacterLedger `modules/WaypointArrow.lua:210` | call 1 | thin (1) |
| WaypointArrow | `strata` (descriptor) | CharacterLedger `modules/WaypointArrow.lua:210` | call 1 | thin (1) |
| WaypointArrow | `strings` (descriptor) | CharacterLedger `modules/WaypointArrow.lua:216` | call 1 | thin (1) |
| WaypointArrow | `vendorPath` (descriptor) | none | call 0 | zero — kept, documented |
| Charts | `lib.K` | CombatTrail `modules/Results_Insights.lua:415`; DropWatcher `modules/InsightsSections.lua:81`; LootHistory `modules/Analytics.lua:187` | call 12 · name-only 2 · test 236 | consumed (3) |
| Charts | `lib.New` | CombatTrail `modules/Results_Insights.lua:775`; DropWatcher `modules/WindowInsights.lua:157`; LootHistory `modules/AnalyticsCharts.lua:41` | call 3 · name-only 255 · def 39 · stub 29 · test 1103 | consumed (3) |
| Charts | `lib.OTHER` | LootHistory `modules/AnalyticsFormat.lua:173` | call 1 · name-only 8 · stub 1 · test 251 | thin (1) |
| Charts | `lib.RangeScale` | none | call 0 | zero — kept, documented |
| Charts | `lib.StackSegments` | LootHistory `modules/AnalyticsFormat.lua:165` | call 1 · name-only 2 · def 1 · test 12 | thin (1) |
| Charts | `lib.StripLabels` | none | call 0 | zero — kept, documented |
| Charts | `lib.StripSlots` | none | call 0 | zero — kept, documented |
| Charts | `lib.fitFontSize` | LootHistory `modules/Analytics.lua:187` | call 1 | thin (1) |
| Charts | `lib.tipText` | none | call 0 · test 40 | zero — kept, documented |
| Charts | `lib.truncate` | CombatTrail `modules/Results_Insights.lua:490` | call 1 · test 3 | thin (1) |
| Media | `lib.BACKGROUNDS` | none | call 0 | zero — kept, documented |
| Media | `lib.BORDERS` | none | call 0 | zero — kept, documented |
| Media | `lib.Background` | none | call 0 · name-only 5 · def 1 · test 90 | zero — kept, documented |
| Media | `lib.Border` | none | call 0 · name-only 5 · def 3 · test 144 | zero — kept, documented |
| Media | `lib.FONTS` | none | call 0 · test 37 | zero — kept, documented |
| Media | `lib.Font` | all 19 | call 19 · name-only 76 · def 3 · stub 20 · test 317 | consumed (19) |
| Media | `lib.ICONS` | none | call 0 · test 43 | zero — kept, documented |
| Media | `lib.ICON_SETS` | none | call 0 | zero — kept, documented |
| Media | `lib.Icon` | all 19 | call 19 · name-only 168 · def 22 · test 697 | consumed (19) |
| Media | `lib.IconAuthor` | none | call 0 | zero — kept, documented |
| Media | `lib.RegisterLSM` | all 19 | call 19 · test 14 | consumed (19) |
| Media | `lib.TEXTURES` | none | call 0 · test 5 | zero — kept, documented |
| Media | `lib.Texture` | none | call 0 · name-only 12 · def 2 · stub 2 · test 207 | zero — kept, documented |
| Media | `lib.VENDOR_PATH` | none | call 0 · test 2 | zero — kept, documented |
| Skin | `lib.AliasAceType` | AuraMaster `settings/OptionsSetup.lua:98` | call 1 · test 5 | thin (1) |
| Skin | `lib.CLIENT_DEFAULTS` | none | call 0 · test 4 | zero — kept, documented |
| Skin | `lib.Color` | 13: AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 0 · name-only 162 · def 7 · stub 19 · test 408 | consumed (13, read by hand) |
| Skin | `lib.DEFAULT` | CombatTrail `core/SkinSetup.lua:165`; LootHistory `core/SkinSetup.lua:833` | call 2 · name-only 11 · stub 19 · test 59 | thin (2) |
| Skin | `lib.DefaultSkin` | 17: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 17 · test 34 | consumed (17) |
| Skin | `lib.DrawsKey` | PremadeGroupsFilterExtension `modules/Diagnostics.lua:103` | call 1 · test 5 | thin (1) |
| Skin | `lib.FROM_SKIN` | PartyFrameEnhanced `core/SkinSetup.lua:152` | call 1 · name-only 15 · stub 59 · test 64 | thin (1) |
| Skin | `lib.FollowOnce` | 8: AbsorbTracker, AuraMaster, ConsumableMaster, DropWatcher, KickCD, MultiMeters, PartyFrameEnhanced, QuickComms | call 16 · test 11 | consumed (8) |
| Skin | `lib.For` | all 19 | call 19 · name-only 25 · def 4 · test 195 | consumed (19) |
| Skin | `lib.GetChoice` | 4: CharacterLedger, LibKa0sSkinTester, PremadeGroupsFilterExtension, QuickComms | call 6 · name-only 2 · test 135 | consumed (4) |
| Skin | `lib.GetEUIStatus` | PremadeGroupsFilterExtension `core/SkinSetup.lua:563`; QuickComms `core/SkinSetup.lua:828` | call 4 · test 6 | thin (2) |
| Skin | `lib.GetIgnore` | 11: AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PrettyChat, QuickComms, RangeMaster | call 20 · name-only 2 · test 57 | consumed (11) |
| Skin | `lib.GetOutline` | LibKa0sSkinTester `modules/ShowroomFonts.lua:146` | call 0 · name-only 1 · test 102 | thin (1, read by hand) |
| Skin | `lib.GetOverride` | none | call 0 · test 36 | zero — kept, documented |
| Skin | `lib.GetSkin` | none | call 0 · test 14 | zero — kept, documented |
| Skin | `lib.IsFromSkin` | none | call 0 | zero — kept, documented |
| Skin | `lib.IsOwner` | LibKa0sSkinTester `modules/Diagnostics.lua:47` | call 1 · test 23 | thin (1) |
| Skin | `lib.OUTLINE_DEFAULT` | none | call 0 · test 23 | zero — kept, documented |
| Skin | `lib.OUTLINE_MODES` | none | call 0 · test 19 | zero — kept, documented |
| Skin | `lib.OnLooksChanged` | 15: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 0 · name-only 72 · def 2 · stub 19 · test 87 | consumed (15, read by hand) |
| Skin | `lib.OnRelease` | 9: AuraMaster, BankLedger, CharacterLedger, ConsumableMaster, DropWatcher, KickCD, LootHistory, PremadeGroupsFilterExtension, QuickComms | call 18 · test 61 | consumed (9) |
| Skin | `lib.OnReloadRequest` | none | call 0 · test 7 | zero — kept, documented |
| Skin | `lib.OwnerLabel` | none | call 0 · test 16 | zero — kept, documented |
| Skin | `lib.Owners` | none | call 0 | zero — kept, documented |
| Skin | `lib.PaintAce` | 13: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, PanelMaster, PremadeGroupsFilterExtension, QuickComms, RangeMaster, WhatGroup | call 26 · test 27 | consumed (13) |
| Skin | `lib.PaintAceTree` | all 19 | call 38 · test 22 | consumed (19) |
| Skin | `lib.PendingReload` | LibKa0sSkinTester `modules/Diagnostics.lua:48`; PremadeGroupsFilterExtension `core/SkinSetup.lua:573` | call 3 · test 1 | thin (2) |
| Skin | `lib.RETIRED_FONTS` | none | call 0 · name-only 12 | zero — kept, documented |
| Skin | `lib.RegisterOwner` | all 19 | call 19 · test 45 | consumed (19) |
| Skin | `lib.RegisterSkin` | none | call 0 · test 45 | zero — kept, documented |
| Skin | `lib.Repaint` | none | call 0 · name-only 2 · def 3 · test 13 | zero — kept, documented |
| Skin | `lib.ResetToSkin` | 10: AbsorbTracker, AuraMaster, BankLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, MultiMeters, QuickComms, RangeMaster | call 20 · test 31 | consumed (10) |
| Skin | `lib.Resolve` | 8: AbsorbTracker, AuraMaster, ConsumableMaster, DropWatcher, KickCD, MultiMeters, PartyFrameEnhanced, QuickComms | call 0 · name-only 103 · def 19 · stub 19 · test 342 | consumed (8, read by hand) |
| Skin | `lib.ResolveSkin` | 4: AuraMaster, CombatTrail, KickCD, LootHistory | call 8 · name-only 4 · test 120 | consumed (4) |
| Skin | `lib.SCHEMA` | none | call 0 · name-only 1 · stub 1 · test 27 | zero — kept, documented |
| Skin | `lib.SOURCES` | none | call 0 · name-only 2 · test 11 | zero — kept, documented |
| Skin | `lib.SetChoice` | all 19 | call 19 · test 422 | consumed (19) |
| Skin | `lib.SetIgnore` | all 19 | call 38 · test 131 | consumed (19) |
| Skin | `lib.SetOutline` | all 19 | call 38 · test 60 | consumed (19) |
| Skin | `lib.SetOverride` | all 19 | call 38 · name-only 4 · test 33 | consumed (19) |
| Skin | `lib.Skins` | all 19 | call 42 · name-only 5 · test 69 | consumed (19) |
| Skin | `lib.Token` | 7: AbsorbTracker, BankLedger, ConsumableMaster, DropWatcher, LootHistory, PremadeGroupsFilterExtension, QuickComms | call 6 · name-only 39 · stub 34 · test 251 | consumed (7, read by hand) |
| Skin | `lib.Track` | none | call 0 · name-only 2 · def 2 · test 37 | zero — kept, documented |
| Skin | `lib.Untrack` | 5: CombatTrail, ConsumableMaster, KickCD, MultiMeters, QuickComms | call 5 · name-only 1 · def 1 · test 7 | consumed (5) |
| Skin | `lib.VOCAB` | none | call 0 · stub 19 · test 17 | zero — kept, documented |
| Skin | `lib.WriteChoice` | none | call 0 · test 60 | zero — kept, documented |
| Skin | `lib.byOwner` | none | call 0 · test 2 | zero — kept, documented |
| Skin | `lib.euiFacade` | none | call 0 | zero — kept, documented |
| Skin | `lib.euiPainted` | none | call 0 | zero — kept, documented |
| Skin | `lib.euiRefused` | CombatTrail `core/SkinSetup.lua:696`; OutfitterReborn `core/SkinSetup.lua:551` | call 2 | thin (2) |
| Skin | `lib.euiRegistered` | none | call 0 | zero — kept, documented |
| Skin | `lib.facades` | none | call 0 · test 1 | zero — kept, documented |
| Skin | `lib.owners` | none | call 0 · test 86 | zero — kept, documented |
| Skin | `lib.painted` | none | call 0 · name-only 4 · stub 1 · test 739 | zero — kept, documented |
| Skin | `lib.prim` | none | call 0 · test 13 | zero — kept, documented |
| Skin | `lib.shared` | none | call 0 · name-only 4 · stub 28 · test 921 | zero — kept, documented |
| Skin | `lib.skins` | none | call 0 · stub 4 · test 193 | zero — kept, documented |
| Skin | `addonName` (descriptor) | none | call 0 | zero — kept, documented |
| Skin | `thirdPartySkinAddons` (descriptor) | none | call 0 | zero — kept, documented |
| Skin | `thirdPartySkinsOff` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `lib.AUTOCOMPLETE` | none | call 0 | zero — kept, documented |
| Widgets | `lib.AcquireBar` | CharacterLedger `modules/Broker.lua:352` | call 1 · def 1 · test 8 | thin (1) |
| Widgets | `lib.Autocomplete` | BankLedger `modules/Browser.lua:213`; LootHistory `core/WidgetsSetup.lua:295` | call 4 · name-only 2 · test 52 | thin (2) |
| Widgets | `lib.BAR` | none | call 0 · name-only 5 · stub 1 · test 41 | zero — kept, documented |
| Widgets | `lib.Bar` | RangeMaster `modules/Elements_Indicator.lua:57`; CharacterLedger `modules/Journal.lua:701` | call 5 · name-only 21 · def 4 · stub 1 · test 643 | thin (2) |
| Widgets | `lib.BarCompute` | none | call 0 · test 6 | zero — kept, documented |
| Widgets | `lib.BarFormatTimer` | CharacterLedger `modules/RowTooltip.lua:48` | call 1 · def 1 · test 6 | thin (1) |
| Widgets | `lib.BarShade` | none | call 0 · def 1 · test 2 | zero — kept, documented |
| Widgets | `lib.BarStyle` | RangeMaster `modules/Elements_Indicator.lua:58`; CharacterLedger `modules/BarStyle.lua:122` | call 2 · name-only 17 · def 1 · stub 32 · test 38 | thin (2) |
| Widgets | `lib.BarText` | CharacterLedger `modules/Interact.lua:157` | call 4 · test 3 | thin (1) |
| Widgets | `lib.ChartMath` | none | call 0 · test 2 | zero — kept, documented |
| Widgets | `lib.CloseMenu` | 9: BankLedger, CharacterLedger, CombatTrail, DropWatcher, LootHistory, MultiMeters, OutfitterReborn, PremadeGroupsFilterExtension, QuickComms | call 14 · name-only 25 · def 7 · test 64 | consumed (9) |
| Widgets | `lib.ContextMenu` | 6: CharacterLedger, CombatTrail, DropWatcher, MultiMeters, OutfitterReborn, QuickComms | call 12 · name-only 4 · def 4 · test 90 | consumed (6) |
| Widgets | `lib.CopyWindow` | 5: BankLedger, CombatTrail, LootHistory, MultiMeters, QuickComms | call 9 · name-only 3 · def 1 · test 17 | consumed (5) |
| Widgets | `lib.DRAG_HANDLE` | 4: AbsorbTracker, AuraMaster, KickCD, QuickComms | call 6 · test 27 | consumed (4) |
| Widgets | `lib.DRAG_HANDLE_STRINGS` | none | call 0 | zero — kept, documented |
| Widgets | `lib.DockTestStrip` | AuraMaster `modules/Anchors.lua:1120`; RangeMaster `modules/Container.lua:649` | call 4 · name-only 2 · test 7 | thin (2) |
| Widgets | `lib.DragHandle` | 6: AbsorbTracker, AuraMaster, ConsumableMaster, KickCD, QuickComms, RangeMaster | call 12 · name-only 2 · def 1 · test 69 | consumed (6) |
| Widgets | `lib.Dropdown` | 11: AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, LootHistory, MultiMeters, OutfitterReborn, PremadeGroupsFilterExtension, QuickComms, RangeMaster | call 14 · name-only 5 · stub 19 · test 319 | consumed (11) |
| Widgets | `lib.FOOTER` | 8: AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, LootHistory, OutfitterReborn, RangeMaster | call 8 · test 53 | consumed (8) |
| Widgets | `lib.Footer` | 8: AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, LootHistory, OutfitterReborn, RangeMaster | call 14 · name-only 3 · def 2 · stub 18 · test 61 | consumed (8) |
| Widgets | `lib.HEADER` | 5: CharacterLedger, CombatTrail, OutfitterReborn, PremadeGroupsFilterExtension, QuickComms | call 5 · name-only 22 · test 54 | consumed (5) |
| Widgets | `lib.HEADER_STRINGS` | none | call 0 · test 2 | zero — kept, documented |
| Widgets | `lib.HeaderButton` | none | call 0 · test 3 | zero — kept, documented |
| Widgets | `lib.HeaderButtons` | 12: AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, LootHistory, MultiMeters, OutfitterReborn, PremadeGroupsFilterExtension, QuickComms, RangeMaster, WhatGroup | call 20 · name-only 12 · def 4 · test 101 | consumed (12) |
| Widgets | `lib.IconText` | OutfitterReborn `core/WidgetsSetup.lua:257` | call 2 · name-only 1 · def 1 · test 5 | thin (1) |
| Widgets | `lib.LINE_CHART` | LootHistory `core/WidgetsSetup.lua:277` | call 1 · test 1 | thin (1) |
| Widgets | `lib.LineChart` | LootHistory `core/WidgetsSetup.lua:261` | call 3 · name-only 2 · test 6 | thin (1) |
| Widgets | `lib.OwnerWarnings` | none | call 0 | zero — kept, documented |
| Widgets | `lib.ROW_BOX` | 4: CharacterLedger, ConsumableMaster, KickCD, LootHistory | call 6 · test 12 | consumed (4) |
| Widgets | `lib.ReleaseBars` | CharacterLedger `modules/Broker.lua:543` | call 1 · def 1 · test 5 | thin (1) |
| Widgets | `lib.ReorderList` | 6: CharacterLedger, ConsumableMaster, KickCD, LootHistory, QuickComms, RangeMaster | call 15 · name-only 2 · test 68 | consumed (6) |
| Widgets | `lib.SearchBox` | BankLedger `modules/Browser.lua:196`; DropWatcher `core/WidgetsSetup.lua:64`; LootHistory `core/WidgetsSetup.lua:153` | call 5 · name-only 3 · test 42 | consumed (3) |
| Widgets | `lib.TEST_STRIP` | DropWatcher `core/WidgetsSetup.lua:127`; MultiMeters `modules/Window.lua:88`; OutfitterReborn `core/WidgetsSetup.lua:282` | call 3 · test 21 | consumed (3) |
| Widgets | `lib.TestStrip` | 10: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, LootHistory, MultiMeters, OutfitterReborn, RangeMaster | call 22 · name-only 4 · def 2 · test 62 | consumed (10) |
| Widgets | `addonName` (descriptor) | 6: BankLedger, CombatTrail, LibKa0sSkinTester, LootHistory, MultiMeters, QuickComms | call 6 | consumed (6) |
| Widgets | `anchorTo` (descriptor) | 4: BankLedger, CombatTrail, LootHistory, MultiMeters | call 4 | consumed (4) |
| Widgets | `applySkin` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `backdrop` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `clear` (descriptor) | 4: AbsorbTracker, AuraMaster, KickCD, RangeMaster | call 0 | consumed (4, read by hand) |
| Widgets | `dock` (descriptor) | 11: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, KickCD, LootHistory, MultiMeters, OutfitterReborn, RangeMaster | call 0 | consumed (11, read by hand) |
| Widgets | `editWidth` (descriptor) | MultiMeters `modules/Export_Modal.lua:349` | call 1 | thin (1) |
| Widgets | `font` (descriptor) | BankLedger `modules/Export.lua:285`; LootHistory `modules/Export.lua:377`; MultiMeters `modules/Export_Modal.lua:347` | call 3 | consumed (3) |
| Widgets | `fontSize` (descriptor) | LootHistory `modules/Export.lua:378`; MultiMeters `modules/Export_Modal.lua:348` | call 2 | thin (2) |
| Widgets | `gap` (descriptor) | AuraMaster `modules/Anchors.lua:1201`; KickCD `modules/SimStrip.lua:93`; RangeMaster `modules/Container.lua:632` | call 0 | consumed (3, read by hand) |
| Widgets | `height` (descriptor) | CombatTrail `core/WidgetsSetup.lua:270`; LibKa0sSkinTester `modules/ShowroomWidgets.lua:203`; MultiMeters `modules/Export_Modal.lua:345` | call 3 | consumed (3) |
| Widgets | `hoverXs` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `inset` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `integer` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `makeCloseButton` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `markers` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `name` (descriptor) | 5: BankLedger, CombatTrail, LibKa0sSkinTester, LootHistory, MultiMeters | call 5 | consumed (5) |
| Widgets | `onOffset` (descriptor) | 4: BankLedger, DropWatcher, LootHistory, MultiMeters | call 0 | consumed (4, read by hand) |
| Widgets | `onSettings` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `scrollName` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `series` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `target` (descriptor) | 5: AbsorbTracker, AuraMaster, DropWatcher, KickCD, RangeMaster | call 0 | consumed (5, read by hand) |
| Widgets | `title` (descriptor) | 5: BankLedger, CombatTrail, LibKa0sSkinTester, LootHistory, MultiMeters | call 5 | consumed (5) |
| Widgets | `titleBar` (descriptor) | 7: BankLedger, CharacterLedger, CombatTrail, DropWatcher, LootHistory, MultiMeters, OutfitterReborn | call 0 | consumed (7, read by hand) |
| Widgets | `width` (descriptor) | CombatTrail `core/WidgetsSetup.lua:270`; LibKa0sSkinTester `modules/ShowroomWidgets.lua:203`; MultiMeters `modules/Export_Modal.lua:344` | call 3 | consumed (3) |
| Widgets | `window` (descriptor) | 6: BankLedger, CharacterLedger, CombatTrail, DropWatcher, LootHistory, MultiMeters | call 0 | consumed (6, read by hand) |
| Widgets | `xMax` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `xMin` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `yMax` (descriptor) | none | call 0 | zero — kept, documented |
| Widgets | `yMin` (descriptor) | none | call 0 | zero — kept, documented |
| DebugLog | `lib.AT_ENABLE_MAX` | none | call 0 · test 1 | zero — kept, documented |
| DebugLog | `lib.BUFFER_SLACK` | none | call 0 · test 1 | zero — kept, documented |
| DebugLog | `lib.DIAG_MAX_LINES` | none | call 0 · test 1 | zero — kept, documented |
| DebugLog | `lib.DIAG_MAX_PER_LIST` | none | call 0 | zero — kept, documented |
| DebugLog | `lib.FormatColored` | ConsumableMaster `core/DebugLogSetup.lua:361` | call 1 · stub 6 · test 62 | thin (1) |
| DebugLog | `lib.FormatPlain` | ConsumableMaster `core/DebugLogSetup.lua:361` | call 1 · stub 8 · test 79 | thin (1) |
| DebugLog | `lib.GATE_MAX_KEYS` | none | call 0 | zero — kept, documented |
| DebugLog | `lib.MAX_BUFFER` | none | call 0 · test 8 | zero — kept, documented |
| DebugLog | `lib.MakeCloseButton` | none | call 0 · name-only 40 · def 19 · stub 37 · test 174 | zero — kept, documented |
| DebugLog | `lib.New` | all 19 | call 19 · name-only 239 · def 39 · stub 29 · test 1103 | consumed (19) |
| DebugLog | `lib.STRINGS` | none | call 0 · name-only 1 · stub 5 · test 191 | zero — kept, documented |
| DebugLog | `lib.Serialize` | ConsumableMaster `core/DebugLogSetup.lua:344` | call 1 · name-only 1 · stub 29 · test 19 | thin (1) |
| DebugLog | `lib.TIME_COPY` | none | call 0 | zero — kept, documented |
| DebugLog | `Add` (instance) | 15: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, PrettyChat, QuickComms, RangeMaster | call 28 · name-only 88 · def 10 · stub 23 · test 429 | consumed (15) |
| DebugLog | `BufferSize` (instance) | none | call 0 · stub 15 · test 72 | zero — kept, documented |
| DebugLog | `BuildDiagnostics` (instance) | none | call 0 · stub 21 · test 38 | zero — kept, documented |
| DebugLog | `Clear` (instance) | ConsumableMaster `core/DebugLogSetup.lua:314` | call 1 · name-only 50 · def 18 · stub 19 · test 603 | thin (1) |
| DebugLog | `ConsoleCheckbox` (instance) | 12: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, DropWatcher, LibKa0sSkinTester, OutfitterReborn, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, RangeMaster, WhatGroup | call 15 · stub 16 · test 42 | consumed (12) |
| DebugLog | `CopyText` (instance) | none | call 0 · stub 7 · test 29 | zero — kept, documented |
| DebugLog | `Debug` (instance) | all 19 | call 19 · name-only 975 · stub 74 · test 656 | consumed (19) |
| DebugLog | `DebugAtEnable` (instance) | all 19 | call 49 · name-only 30 · def 1 · stub 33 · test 21 | consumed (19) |
| DebugLog | `DebugChanged` (instance) | 16: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, OutfitterReborn, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 26 · name-only 29 · def 1 · stub 29 · test 28 | consumed (16) |
| DebugLog | `DebugForget` (instance) | 8: AuraMaster, BankLedger, ConsumableMaster, KickCD, LootHistory, PartyFrameEnhanced, PremadeGroupsFilterExtension, WhatGroup | call 11 · name-only 7 · def 1 · stub 20 · test 3 | consumed (8) |
| DebugLog | `DebugOnce` (instance) | 16: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, LibKa0sSkinTester, LootHistory, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 22 · name-only 27 · def 3 · stub 31 · test 47 | consumed (16) |
| DebugLog | `DebugVerb` (instance) | 9: CharacterLedger, CombatTrail, DropWatcher, LibKa0sSkinTester, OutfitterReborn, PanelMaster, PremadeGroupsFilterExtension, QuickComms, RangeMaster | call 9 · stub 24 · test 36 | consumed (9) |
| DebugLog | `FindLine` (instance) | none | call 0 · stub 15 · test 118 | zero — kept, documented |
| DebugLog | `Hide` (instance) | 7: BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PanelMaster, PrettyChat | call 9 · name-only 903 · def 27 · stub 24 · test 1317 | consumed (7) |
| DebugLog | `IsEnabled` (instance) | 4: AuraMaster, CombatTrail, ConsumableMaster, PrettyChat | call 5 · name-only 40 · def 3 · stub 39 · test 234 | consumed (4) |
| DebugLog | `IsShown` (instance) | 17: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PrettyChat, QuickComms, RangeMaster | call 25 · name-only 389 · def 15 · stub 39 · test 3824 | consumed (17) |
| DebugLog | `LastLine` (instance) | none | call 0 · stub 15 · test 53 | zero — kept, documented |
| DebugLog | `MakeCloseButton` (instance) | none | call 0 · name-only 40 · def 19 · stub 37 · test 174 | zero — kept, documented |
| DebugLog | `RefreshHeader` (instance) | ConsumableMaster `core/DebugLogSetup.lua:318` | call 1 · stub 17 · test 11 | thin (1) |
| DebugLog | `Report` (instance) | 15: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PrettyChat, QuickComms | call 22 · name-only 11 · def 2 · stub 29 · test 104 | consumed (15) |
| DebugLog | `RunDiagnostics` (instance) | all 19 | call 25 · name-only 4 · stub 29 · test 85 | consumed (19) |
| DebugLog | `Serialize` (instance) | ConsumableMaster `core/DebugLogSetup.lua:344` | call 1 · name-only 1 · stub 29 · test 19 | thin (1) |
| DebugLog | `SetEnabled` (instance) | 10: AbsorbTracker, AuraMaster, BankLedger, CombatTrail, ConsumableMaster, LootHistory, MultiMeters, PartyFrameEnhanced, PrettyChat, WhatGroup | call 15 · name-only 64 · def 8 · stub 39 · test 402 | consumed (10) |
| DebugLog | `Show` (instance) | 17: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PrettyChat, QuickComms, RangeMaster | call 29 · name-only 543 · def 26 · stub 22 · test 1932 | consumed (17) |
| DebugLog | `ShowCopy` (instance) | ConsumableMaster `core/DebugLogSetup.lua:317` | call 1 · def 2 · stub 17 · test 33 | thin (1) |
| DebugLog | `Text` (instance) | none | call 0 · name-only 282 · def 6 · stub 52 · test 490 | zero — kept, documented |
| DebugLog | `Toggle` (instance) | 18: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 20 · name-only 39 · def 21 · stub 20 · test 405 | consumed (18) |
| DebugLog | `UpdateScrollBar` (instance) | ConsumableMaster `core/DebugLogSetup.lua:319` | call 1 · stub 17 · test 23 | thin (1) |
| DebugLog | `UpdateStatus` (instance) | ConsumableMaster `core/DebugLogSetup.lua:320` | call 1 · stub 17 · test 18 | thin (1) |
| DebugLog | `buffer` (instance) | none | call 0 · stub 21 · test 657 | zero — kept, documented |
| DebugLog | `L` (descriptor) | 10: AbsorbTracker, AuraMaster, CharacterLedger, DropWatcher, LibKa0sSkinTester, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, RangeMaster, WhatGroup | call 10 | consumed (10) |
| DebugLog | `addonName` (descriptor) | all 19 | call 19 | consumed (19) |
| DebugLog | `applySkin` (descriptor) | none | call 0 | zero — kept, documented |
| DebugLog | `brandName` (descriptor) | 18: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 18 | consumed (18) |
| DebugLog | `diagnostics` (descriptor) | all 19 | call 19 | consumed (19) |
| DebugLog | `diagnosticsEnablesLogging` (descriptor) | none | call 0 | zero — kept, documented |
| DebugLog | `font` (descriptor) | all 19 | call 19 | consumed (19) |
| DebugLog | `fontSize` (descriptor) | ConsumableMaster `core/DebugLogSetup.lua:215` | call 1 | thin (1) |
| DebugLog | `initSummary` (descriptor) | all 19 | call 19 | consumed (19) |
| DebugLog | `isEnabled` (descriptor) | all 19 | call 19 | consumed (19) |
| DebugLog | `makeCloseButton` (descriptor) | none | call 0 | zero — kept, documented |
| DebugLog | `name` (descriptor) | all 19 | call 19 | consumed (19) |
| DebugLog | `onClear` (descriptor) | AuraMaster `core/DebugLogSetup.lua:207`; ConsumableMaster `core/DebugLogSetup.lua:284`; MultiMeters `core/DebugLogSetup.lua:428` | call 3 | consumed (3) |
| DebugLog | `onSettings` (descriptor) | none | call 0 | zero — kept, documented |
| DebugLog | `onVisibilityChanged` (descriptor) | all 19 | call 19 | consumed (19) |
| DebugLog | `print` (descriptor) | all 19 | call 19 | consumed (19) |
| DebugLog | `safeToString` (descriptor) | 16: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 16 | consumed (16) |
| DebugLog | `setEnabled` (descriptor) | all 19 | call 19 | consumed (19) |
| DebugLog | `skin` (descriptor) | none | call 0 | zero — kept, documented |
| DebugLog | `slash` (descriptor) | all 19 | call 19 | consumed (19) |
| DebugLog | `title` (descriptor) | all 19 | call 19 | consumed (19) |
| Slash | `lib.CommandRows` | ConsumableMaster `settings/Slash.lua:674`; KickCD `settings/Slash.lua:416` | call 2 · name-only 7 · stub 5 · test 13 | thin (2) |
| Slash | `lib.DISABLED_LINE_FORMAT` | LootHistory `settings/Slash.lua:228`; OutfitterReborn `core/LifecycleSetup.lua:150`; PanelMaster `settings/Slash.lua:787` | call 3 · stub 52 · test 68 | consumed (3) |
| Slash | `lib.FindCommand` | ConsumableMaster `settings/Slash.lua:673`; KickCD `settings/Slash.lua:415` | call 2 · name-only 7 · stub 3 · test 12 | thin (2) |
| Slash | `lib.FormatKV` | 11: AbsorbTracker, AuraMaster, DropWatcher, LibKa0sSkinTester, LootHistory, PanelMaster, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 11 · name-only 6 · stub 8 · test 47 | consumed (11) |
| Slash | `lib.FormatRow` | AbsorbTracker `settings/Slash.lua:43`; PartyFrameEnhanced `settings/Slash.lua:291` | call 2 · stub 8 · test 29 | thin (2) |
| Slash | `lib.FormatValue` | 16: AbsorbTracker, AuraMaster, BankLedger, CombatTrail, ConsumableMaster, DropWatcher, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 18 · name-only 10 · def 4 · stub 4 · test 27 | consumed (16) |
| Slash | `lib.LIVE_VERBS` | 12: AbsorbTracker, AuraMaster, BankLedger, CombatTrail, KickCD, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PrettyChat, RangeMaster, WhatGroup | call 12 · name-only 2 · stub 8 · test 47 | consumed (12) |
| Slash | `lib.New` | 14: AbsorbTracker, AuraMaster, BankLedger, CombatTrail, ConsumableMaster, KickCD, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PrettyChat, RangeMaster, WhatGroup | call 14 · name-only 244 · def 39 · stub 29 · test 1103 | consumed (14) |
| Slash | `lib.ParseBool` | ConsumableMaster `settings/Slash.lua:504`; MultiMeters `settings/Slash.lua:489` | call 2 · name-only 1 · def 1 · stub 1 · test 12 | thin (2) |
| Slash | `lib.ParseValue` | 5: AuraMaster, BankLedger, ConsumableMaster, KickCD, PanelMaster | call 5 · stub 8 · test 7 | consumed (5) |
| Slash | `lib.ProfileNames` | AbsorbTracker `settings/Slash.lua:560` | call 2 · test 2 | thin (1) |
| Slash | `lib.STRINGS` | LootHistory `settings/Slash.lua:246` | call 1 · stub 5 · test 191 | thin (1) |
| Slash | `lib.SplitVerb` | AbsorbTracker `settings/Slash.lua:402`; ConsumableMaster `settings/Slash.lua:672`; KickCD `settings/Slash.lua:414` | call 6 · name-only 10 · stub 5 · test 16 | consumed (3) |
| Slash | `BuildListLines` (instance) | BankLedger `settings/Slash.lua:495`; LootHistory `settings/Slash.lua:535`; PanelMaster `settings/Slash.lua:768` | call 3 · name-only 2 · def 1 · stub 10 · test 49 | consumed (3) |
| Slash | `CliGet` (instance) | 18: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, RangeMaster, WhatGroup | call 24 · name-only 3 · stub 10 · test 40 | consumed (18) |
| Slash | `CliList` (instance) | all 19 | call 19 · name-only 3 · stub 10 · test 14 | consumed (19) |
| Slash | `CliProfile` (instance) | 16: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 20 · name-only 3 · def 1 · stub 15 · test 56 | consumed (16) |
| Slash | `CliReset` (instance) | 18: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, RangeMaster, WhatGroup | call 18 · name-only 3 · stub 10 · test 39 | consumed (18) |
| Slash | `CliResetAll` (instance) | none | call 0 · name-only 6 · def 3 · stub 11 · test 64 | zero — deliberate host copy |
| Slash | `CliSet` (instance) | 18: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, RangeMaster, WhatGroup | call 24 · name-only 11 · stub 16 · test 118 | consumed (18) |
| Slash | `CliVersion` (instance) | 13: BankLedger, CharacterLedger, CombatTrail, DropWatcher, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 13 · name-only 3 · stub 14 · test 15 | consumed (13) |
| Slash | `DisabledLine` (instance) | 16: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, QuickComms, RangeMaster, WhatGroup | call 17 · name-only 13 · def 1 · stub 35 · test 125 | consumed (16) |
| Slash | `HelpHeader` (instance) | LootHistory `settings/Slash.lua:533` | call 1 · stub 8 · test 23 | thin (1) |
| Slash | `HelpRows` (instance) | LootHistory `settings/Slash.lua:534`; MultiMeters `settings/Slash.lua:932`; PanelMaster `settings/Slash.lua:766` | call 3 · stub 19 · test 28 | consumed (3) |
| Slash | `LandingRows` (instance) | all 19 | call 19 · name-only 12 · stub 27 · test 54 | consumed (19) |
| Slash | `OnSlash` (instance) | all 19 | call 19 · name-only 20 · def 2 · stub 23 · test 909 | consumed (19) |
| Slash | `PrintHelp` (instance) | all 19 | call 22 · name-only 3 · stub 48 · test 34 | consumed (19) |
| Slash | `ProfileSwitch` (instance) | 6: AbsorbTracker, BankLedger, ConsumableMaster, LootHistory, PanelMaster, PartyFrameEnhanced | call 6 · def 1 · stub 20 · test 40 | consumed (6) |
| Slash | `SetRowAnnotator` (instance) | AbsorbTracker `settings/Slash.lua:826`; AuraMaster `settings/Slash.lua:655` | call 2 · stub 15 | thin (2) |
| Slash | `Text` (instance) | LootHistory `settings/Slash.lua:574`; PanelMaster `settings/Slash.lua:779`; PrettyChat `settings/Slash.lua:424` | call 3 · name-only 279 · def 6 · stub 52 · test 490 | consumed (3) |
| Slash | `L` (descriptor) | 5: ConsumableMaster, KickCD, LibKa0sSkinTester, PanelMaster, WhatGroup | call 5 | consumed (5) |
| Slash | `aliases` (descriptor) | 9: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, KickCD, MultiMeters, PartyFrameEnhanced, RangeMaster | call 9 | consumed (9) |
| Slash | `allRows` (descriptor) | all 19 | call 19 | consumed (19) |
| Slash | `applyDefault` (descriptor) | all 19 | call 19 | consumed (19) |
| Slash | `brandName` (descriptor) | all 19 | call 19 | consumed (19) |
| Slash | `bulkBegin` (descriptor) | 11: AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, KickCD, LootHistory, MultiMeters, OutfitterReborn, QuickComms, RangeMaster | call 11 | consumed (11) |
| Slash | `bulkEnd` (descriptor) | 11: AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, KickCD, LootHistory, MultiMeters, OutfitterReborn, QuickComms, RangeMaster | call 11 | consumed (11) |
| Slash | `colorDecode` (descriptor) | AuraMaster `settings/Slash.lua:648`; ConsumableMaster `settings/Slash.lua:653` | call 2 | thin (2) |
| Slash | `colorEncode` (descriptor) | AuraMaster `settings/Slash.lua:649`; ConsumableMaster `settings/Slash.lua:654` | call 2 | thin (2) |
| Slash | `commands` (descriptor) | all 19 | call 19 | consumed (19) |
| Slash | `debug` (descriptor) | all 19 | call 19 | consumed (19) |
| Slash | `findRow` (descriptor) | all 19 | call 19 | consumed (19) |
| Slash | `format` (descriptor) | 10: AuraMaster, BankLedger, CombatTrail, ConsumableMaster, DropWatcher, LootHistory, MultiMeters, OutfitterReborn, PrettyChat, QuickComms | call 10 | consumed (10) |
| Slash | `get` (descriptor) | all 19 | call 19 | consumed (19) |
| Slash | `groupKey` (descriptor) | all 19 | call 19 | consumed (19) |
| Slash | `isEnabled` (descriptor) | all 19 | call 19 | consumed (19) |
| Slash | `liveVerbs` (descriptor) | 18: AbsorbTracker, AuraMaster, BankLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 18 | consumed (18) |
| Slash | `parse` (descriptor) | 9: AuraMaster, BankLedger, ConsumableMaster, KickCD, LibKa0sSkinTester, PanelMaster, PrettyChat, QuickComms, WhatGroup | call 9 | consumed (9) |
| Slash | `print` (descriptor) | all 19 | call 19 | consumed (19) |
| Slash | `profiles` (descriptor) | 16: AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 16 | consumed (16) |
| Slash | `set` (descriptor) | all 19 | call 19 | consumed (19) |
| Slash | `slash` (descriptor) | all 19 | call 19 | consumed (19) |
| Slash | `slashAliases` (descriptor) | all 19 | call 19 | consumed (19) |
| Slash | `version` (descriptor) | all 19 | call 19 | consumed (19) |
| Launcher | `lib.New` | all 19 | call 19 · name-only 239 · def 39 · stub 29 · test 1103 | consumed (19) |
| Launcher | `lib.STRINGS` | none | call 0 · name-only 1 · stub 5 · test 191 | zero — kept, documented |
| Launcher | `IsRegistered` (instance) | 7: AbsorbTracker, DropWatcher, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 7 · name-only 1 · stub 15 · test 67 | consumed (7) |
| Launcher | `IsShown` (instance) | 9: AbsorbTracker, BankLedger, CombatTrail, DropWatcher, OutfitterReborn, PremadeGroupsFilterExtension, QuickComms, RangeMaster, WhatGroup | call 9 · name-only 405 · def 15 · stub 39 · test 3824 | consumed (9) |
| Launcher | `Object` (instance) | none | call 0 · def 2 · stub 15 · test 140 | zero — kept, documented |
| Launcher | `Register` (instance) | all 19 | call 19 · name-only 58 · def 25 · stub 27 · test 464 | consumed (19) |
| Launcher | `SetShown` (instance) | all 19 | call 19 · name-only 396 · def 2 · stub 27 · test 81 | consumed (19) |
| Launcher | `L` (descriptor) | none | call 0 | zero — kept, documented |
| Launcher | `debug` (descriptor) | 18: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 18 | consumed (18) |
| Launcher | `debugAtEnable` (descriptor) | 18: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 18 | consumed (18) |
| Launcher | `entryClients` (descriptor) | none | call 0 | zero — kept, documented |
| Launcher | `extraEntries` (descriptor) | CharacterLedger `core/LauncherSetup.lua:68` | call 1 | thin (1) |
| Launcher | `icon` (descriptor) | 18: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 18 | consumed (18) |
| Launcher | `isEnabled` (descriptor) | 18: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 18 | consumed (18) |
| Launcher | `isLocked` (descriptor) | 15: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, ConsumableMaster, DropWatcher, KickCD, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, QuickComms, RangeMaster, WhatGroup | call 15 | consumed (15) |
| Launcher | `isTestMode` (descriptor) | 11: AuraMaster, BankLedger, CharacterLedger, DropWatcher, LootHistory, MultiMeters, OutfitterReborn, PremadeGroupsFilterExtension, QuickComms, RangeMaster, WhatGroup | call 11 | consumed (11) |
| Launcher | `label` (descriptor) | 18: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 18 | consumed (18) |
| Launcher | `minimap` (descriptor) | 18: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 18 | consumed (18) |
| Launcher | `name` (descriptor) | 18: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 18 | consumed (18) |
| Launcher | `onTooltipShow` (descriptor) | BankLedger `core/LauncherSetup.lua:287`; LootHistory `core/LauncherSetup.lua:273`; OutfitterReborn `core/LauncherSetup.lua:169` | call 3 | consumed (3) |
| Launcher | `openSettings` (descriptor) | 18: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 18 | consumed (18) |
| Launcher | `openSkinPicker` (descriptor) | 18: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 18 | consumed (18) |
| Launcher | `owner` (descriptor) | none | call 0 | zero — kept, documented |
| Launcher | `print` (descriptor) | 18: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 18 | consumed (18) |
| Launcher | `setEnabled` (descriptor) | 18: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 18 | consumed (18) |
| Launcher | `version` (descriptor) | 18: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 18 | consumed (18) |
| Options | `lib.APPEARANCE_STRINGS` | none | call 0 · stub 1 · test 1 | zero — kept, documented |
| Options | `lib.KEYBIND_STRINGS` | none | call 0 · test 9 | zero — kept, documented |
| Options | `lib.LAYOUT` | none | call 0 · name-only 7 · stub 2 · test 106 | zero — kept, documented |
| Options | `lib.New` | all 19 | call 19 · name-only 239 · def 39 · stub 29 · test 1103 | consumed (19) |
| Options | `lib.PatchAlwaysShowScrollbar` | none | call 0 · stub 16 · test 25 | zero — kept, documented |
| Options | `lib.SKIN_NOTICE_VERSION` | none | call 0 · test 2 | zero — kept, documented |
| Options | `lib.SKIN_PICKER_STRINGS` | none | call 0 · test 17 | zero — kept, documented |
| Options | `lib.STRINGS` | none | call 0 · name-only 1 · stub 5 · test 191 | zero — kept, documented |
| Options | `AceGUI` (instance) | 6: AuraMaster, BankLedger, PanelMaster, PremadeGroupsFilterExtension, QuickComms, WhatGroup | call 11 · name-only 63 · stub 29 · test 984 | consumed (6) |
| Options | `AddSpacer` (instance) | 8: AuraMaster, BankLedger, CharacterLedger, LootHistory, MultiMeters, PremadeGroupsFilterExtension, PrettyChat, WhatGroup | call 33 · name-only 28 · stub 19 · test 12 | consumed (8) |
| Options | `AppearanceRows` (instance) | CombatTrail `settings/General.lua:210` | call 1 · def 1 · stub 31 · test 14 | thin (1) |
| Options | `AppearanceTab` (instance) | 18: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 18 · name-only 1 · def 1 · stub 23 · test 30 | consumed (18) |
| Options | `AttachTooltip` (instance) | 9: AbsorbTracker, AuraMaster, CharacterLedger, ConsumableMaster, KickCD, MultiMeters, PanelMaster, PrettyChat, WhatGroup | call 30 · name-only 70 · def 1 · stub 18 · test 35 | consumed (9) |
| Options | `BANNER_H` (instance) | AbsorbTracker `settings/UnitPanel.lua:138`; PanelMaster `settings/PanelEditor.lua:519` | call 5 · stub 6 · test 31 | thin (2) |
| Options | `BUTTON_PAIR_REL` (instance) | AuraMaster `settings/GeneralSpells.lua:602`; LootHistory `settings/Panel.lua:51`; PanelMaster `settings/Panel.lua:58` | call 7 · name-only 9 · stub 7 · test 38 | consumed (3) |
| Options | `BarGroup` (instance) | 7: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, KickCD, PanelMaster, PartyFrameEnhanced | call 10 · stub 16 · test 21 | consumed (7) |
| Options | `BorderGroup` (instance) | 10: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, DropWatcher, KickCD, OutfitterReborn, PanelMaster, PartyFrameEnhanced, RangeMaster | call 21 · name-only 5 · def 1 · stub 16 · test 23 | consumed (10) |
| Options | `BuildLandingPage` (instance) | 17: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 17 · name-only 3 · stub 5 · test 61 | consumed (17) |
| Options | `CHROME_GAP` (instance) | none | call 0 · name-only 2 · stub 7 · test 25 | zero — kept, documented |
| Options | `CLASS_COLOR_NOTE` (instance) | AuraMaster `settings/Bars.lua:105`; PanelMaster `settings/PanelEditor.lua:394` | call 3 · name-only 1 · stub 4 · test 28 | thin (2) |
| Options | `ChoiceGrid` (instance) | AuraMaster `settings/Filters.lua:666` | call 2 · stub 20 · test 4 | thin (1) |
| Options | `ClearScroll` (instance) | all 19 | call 32 · name-only 3 · stub 21 · test 66 | consumed (19) |
| Options | `ColorPair` (instance) | 8: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, KickCD, OutfitterReborn, PartyFrameEnhanced, RangeMaster | call 19 · name-only 13 · def 1 · stub 16 · test 17 | consumed (8) |
| Options | `CreateOptionsPanel` (instance) | all 19 | call 19 · name-only 9 · stub 33 · test 56 | consumed (19) |
| Options | `CreatePanel` (instance) | all 19 | call 61 · name-only 8 · def 1 · stub 20 · test 102 | consumed (19) |
| Options | `Drawer` (instance) | QuickComms `settings/Groups_When.lua:675` | call 0 · name-only 1 · stub 38 · test 19 | thin (1, read by hand) |
| Options | `EnsureDefaultsButton` (instance) | LibKa0sSkinTester `settings/OptionsSetup.lua:338`; WhatGroup `settings/OptionsSetup.lua:332` | call 2 · def 2 · stub 18 · test 22 | thin (2) |
| Options | `EnsureScroll` (instance) | 13: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PanelMaster, PremadeGroupsFilterExtension, PrettyChat, RangeMaster, WhatGroup | call 39 · name-only 16 · def 1 · stub 31 · test 26 | consumed (13) |
| Options | `FONT_FLAGS` (instance) | none | call 0 · name-only 1 · stub 5 · test 19 | zero — deliberate host copy |
| Options | `FONT_FLAGS_SORT` (instance) | none | call 0 · stub 4 · test 16 | zero — deliberate host copy |
| Options | `FontGroup` (instance) | 9: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, DropWatcher, KickCD, OutfitterReborn, PartyFrameEnhanced, RangeMaster | call 15 · name-only 5 · def 1 · stub 17 · test 18 | consumed (9) |
| Options | `HideSkinPicker` (instance) | 11: AuraMaster, BankLedger, CharacterLedger, CombatTrail, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PrettyChat | call 22 · name-only 72 · def 19 · stub 32 · test 239 | consumed (11) |
| Options | `ID_NAME_HINT` (instance) | none | call 0 · stub 24 · test 4 | zero — kept, documented |
| Options | `IdInput` (instance) | KickCD `settings/Spells_Header.lua:233` | call 1 · name-only 1 · stub 20 · test 21 | thin (1) |
| Options | `IdList` (instance) | 4: AuraMaster, BankLedger, CombatTrail, LootHistory | call 8 · name-only 2 · stub 23 · test 111 | consumed (4) |
| Options | `InlineButtonPair` (instance) | 7: AuraMaster, BankLedger, CombatTrail, MultiMeters, OutfitterReborn, PremadeGroupsFilterExtension, RangeMaster | call 26 · name-only 8 · def 1 · stub 19 · test 18 | consumed (7) |
| Options | `KEYBINDS_UNCHANGED` (instance) | 10: BankLedger, CharacterLedger, CombatTrail, DropWatcher, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, QuickComms, WhatGroup | call 10 · stub 25 · test 21 | consumed (10) |
| Options | `KeybindRows` (instance) | none | call 0 · stub 31 · test 32 | zero — kept, documented |
| Options | `KeybindingsTab` (instance) | 10: BankLedger, CharacterLedger, CombatTrail, DropWatcher, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, QuickComms, WhatGroup | call 10 · stub 32 · test 12 | consumed (10) |
| Options | `LSMValues` (instance) | 4: AbsorbTracker, CombatTrail, MultiMeters, RangeMaster | call 5 · name-only 1 · def 1 · stub 16 · test 59 | consumed (4) |
| Options | `LabelFont` (instance) | PanelMaster `settings/PanelEditor.lua:274` | call 1 · name-only 8 · def 4 · stub 21 · test 16 | thin (1) |
| Options | `MASTER_GROUP` (instance) | 15: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, OutfitterReborn, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 18 · name-only 3 · stub 14 · test 59 | consumed (15) |
| Options | `MasterControls` (instance) | 14: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, OutfitterReborn, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, RangeMaster, WhatGroup | call 14 · name-only 6 · def 1 · stub 28 · test 71 | consumed (14) |
| Options | `NavRail` (instance) | 4: AuraMaster, KickCD, MultiMeters, RangeMaster | call 4 · stub 27 · test 20 | consumed (4) |
| Options | `OpenOptionsPanel` (instance) | 14: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, ConsumableMaster, KickCD, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PrettyChat, RangeMaster | call 26 · name-only 42 · stub 24 · test 297 | consumed (14) |
| Options | `PADDING_X` (instance) | PanelMaster `settings/Panel.lua:490` | call 2 · stub 2 · test 32 | thin (1) |
| Options | `PageBanner` (instance) | 5: AuraMaster, CombatTrail, KickCD, MultiMeters, RangeMaster | call 7 · name-only 3 · stub 20 · test 46 | consumed (5) |
| Options | `PageHeader` (instance) | 4: AbsorbTracker, CharacterLedger, KickCD, PanelMaster | call 5 · name-only 1 · stub 20 · test 22 | consumed (4) |
| Options | `PatchAlwaysShowScrollbar` (instance) | none | call 0 · stub 16 · test 25 | zero — kept, documented |
| Options | `PositionBlock` (instance) | CombatTrail `settings/Hud.lua:292` | call 2 · name-only 1 · def 1 · stub 19 · test 15 | thin (1) |
| Options | `ROW_VSPACER` (instance) | 4: AuraMaster, BankLedger, PrettyChat, WhatGroup | call 7 · name-only 6 · stub 8 · test 46 | consumed (4) |
| Options | `RefreshAllPanels` (instance) | 11: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, KickCD, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, RangeMaster | call 27 · name-only 13 · def 1 · stub 18 · test 145 | consumed (11) |
| Options | `RefreshPanel` (instance) | 16: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, PanelMaster, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 37 · name-only 14 · stub 15 · test 48 | consumed (16) |
| Options | `RefreshScalars` (instance) | 15: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PremadeGroupsFilterExtension, PrettyChat, QuickComms, WhatGroup | call 32 · name-only 5 · def 1 · stub 16 · test 83 | consumed (15) |
| Options | `RegisterOptionsPage` (instance) | all 19 | call 32 · name-only 49 · def 3 · stub 23 · test 33 | consumed (19) |
| Options | `RenderField` (instance) | PanelMaster `settings/Panel.lua:145`; PremadeGroupsFilterExtension `settings/Panel.lua:171`; PrettyChat `settings/Panel.lua:530` | call 6 · name-only 7 · def 1 · stub 18 · test 38 | consumed (3) |
| Options | `RenderGrid` (instance) | 5: AuraMaster, ConsumableMaster, KickCD, MultiMeters, RangeMaster | call 20 · name-only 16 · stub 18 · test 19 | consumed (5) |
| Options | `RenderRows` (instance) | 5: AuraMaster, CombatTrail, KickCD, LootHistory, MultiMeters | call 20 · name-only 10 · stub 18 · test 53 | consumed (5) |
| Options | `RenderSchema` (instance) | none | call 0 · stub 21 · test 25 | zero — kept, documented |
| Options | `RenderTabbedSchema` (instance) | 17: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, KickCD, LibKa0sSkinTester, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 27 · name-only 3 · stub 36 · test 92 | consumed (17) |
| Options | `ResetAllTooltip` (instance) | 10: BankLedger, CharacterLedger, DropWatcher, LibKa0sSkinTester, LootHistory, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 10 · stub 28 · test 25 | consumed (10) |
| Options | `ResolveId` (instance) | AuraMaster `settings/GeneralSpells.lua:725`; CombatTrail `modules/LaneIgnore.lua:89` | call 5 · name-only 1 · stub 22 · test 9 | thin (2) |
| Options | `RestoreAllDefaults` (instance) | 15: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, RangeMaster, WhatGroup | call 28 · name-only 7 · def 5 · stub 21 · test 209 | consumed (15) |
| Options | `RestoreDefaults` (instance) | 10: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, DropWatcher, KickCD, MultiMeters, OutfitterReborn, PartyFrameEnhanced, RangeMaster | call 19 · name-only 8 · def 4 · stub 12 · test 194 | consumed (10) |
| Options | `SECTION_HEADING_H` (instance) | PanelMaster `settings/Panel.lua:57` | call 1 · name-only 1 · stub 7 · test 32 | thin (1) |
| Options | `Section` (instance) | 6: AuraMaster, CharacterLedger, ConsumableMaster, MultiMeters, PremadeGroupsFilterExtension, RangeMaster | call 25 · name-only 12 · def 4 · stub 18 · test 114 | consumed (6) |
| Options | `SelectTab` (instance) | 5: AuraMaster, CombatTrail, KickCD, MultiMeters, RangeMaster | call 6 · name-only 12 · def 7 · stub 27 · test 285 | consumed (5) |
| Options | `SessionCheckbox` (instance) | CombatTrail `settings/History.lua:333`; ConsumableMaster `settings/Panel.lua:704` | call 2 · stub 18 · test 21 | thin (2) |
| Options | `SetChromeHeight` (instance) | none | call 0 · stub 20 · test 3 | zero — kept, documented |
| Options | `SetRenderer` (instance) | 18: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 52 · name-only 7 · def 2 · stub 20 · test 46 | consumed (18) |
| Options | `SideTabs` (instance) | RangeMaster `settings/BandSets.lua:432` | call 1 · stub 27 | thin (1) |
| Options | `SkinNotice` (instance) | 9: AuraMaster, BankLedger, CombatTrail, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PrettyChat | call 27 · name-only 24 · def 1 · stub 18 | consumed (9) |
| Options | `SkinPicker` (instance) | 11: AuraMaster, BankLedger, CharacterLedger, CombatTrail, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PrettyChat | call 22 · name-only 16 · def 1 · stub 31 · test 163 | consumed (11) |
| Options | `SkinVerb` (instance) | 11: AuraMaster, BankLedger, CharacterLedger, CombatTrail, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PrettyChat | call 16 · name-only 13 · def 1 · stub 27 · test 159 | consumed (11) |
| Options | `StrataTooltip` (instance) | 6: AuraMaster, CharacterLedger, CombatTrail, PanelMaster, PartyFrameEnhanced, RangeMaster | call 7 · name-only 3 · stub 27 · test 25 | consumed (6) |
| Options | `SubTabStrip` (instance) | BankLedger `settings/Panel.lua:483`; LootHistory `settings/Panel.lua:494` | call 2 · name-only 2 · stub 14 · test 11 | thin (2) |
| Options | `TAB_H` (instance) | none | call 0 · name-only 5 · stub 6 · test 37 | zero — kept, documented |
| Options | `TabStrip` (instance) | 5: KickCD, LootHistory, MultiMeters, PanelMaster, PrettyChat | call 8 · name-only 3 · stub 23 · test 76 | consumed (5) |
| Options | `TextRow` (instance) | 9: AuraMaster, BankLedger, CharacterLedger, CombatTrail, KickCD, MultiMeters, PremadeGroupsFilterExtension, PrettyChat, RangeMaster | call 66 · name-only 36 · stub 10 · test 25 | consumed (9) |
| Options | `UnnamedCandidates` (instance) | none | call 0 · stub 21 · test 2 | zero — kept, documented |
| Options | `VISIBILITY_SORT` (instance) | none | call 0 · stub 4 · test 16 | zero — deliberate host copy |
| Options | `VISIBILITY_VALUES` (instance) | none | call 0 · stub 4 · test 16 | zero — deliberate host copy |
| Options | `addonName` (descriptor) | all 19 | call 19 | consumed (19) |
| Options | `afterRestoreAll` (descriptor) | none | call 0 | zero — kept, documented |
| Options | `allRows` (descriptor) | 18: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 18 | consumed (18) |
| Options | `applyDefault` (descriptor) | 18: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 18 | consumed (18) |
| Options | `buildMain` (descriptor) | all 19 | call 19 | consumed (19) |
| Options | `bulkBegin` (descriptor) | 17: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, RangeMaster, WhatGroup | call 17 | consumed (17) |
| Options | `bulkEnd` (descriptor) | 17: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, RangeMaster, WhatGroup | call 17 | consumed (17) |
| Options | `colorDecode` (descriptor) | 11: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, KickCD, MultiMeters, OutfitterReborn, PartyFrameEnhanced, QuickComms, RangeMaster | call 11 | consumed (11) |
| Options | `colorEncode` (descriptor) | 11: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, KickCD, MultiMeters, OutfitterReborn, PartyFrameEnhanced, QuickComms, RangeMaster | call 11 | consumed (11) |
| Options | `debug` (descriptor) | all 19 | call 19 | consumed (19) |
| Options | `get` (descriptor) | all 19 | call 19 | consumed (19) |
| Options | `getLSM` (descriptor) | all 19 | call 19 | consumed (19) |
| Options | `mainPanelName` (descriptor) | all 19 | call 19 | consumed (19) |
| Options | `onAceGUI` (descriptor) | 11: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, KickCD, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, RangeMaster | call 11 | consumed (11) |
| Options | `parentTitle` (descriptor) | all 19 | call 19 | consumed (19) |
| Options | `print` (descriptor) | all 19 | call 19 | consumed (19) |
| Options | `resetProfile` (descriptor) | all 19 | call 19 | consumed (19) |
| Options | `rowsForPage` (descriptor) | all 19 | call 19 | consumed (19) |
| Options | `scheduleTimer` (descriptor) | 15: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, DropWatcher, KickCD, LootHistory, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, RangeMaster | call 15 | consumed (15) |
| Options | `set` (descriptor) | all 19 | call 19 | consumed (19) |
| Options | `skipRestoreAll` (descriptor) | 18: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, PremadeGroupsFilterExtension, PrettyChat, QuickComms, RangeMaster, WhatGroup | call 18 | consumed (18) |
| Options | `sliderCommit` (descriptor) | ConsumableMaster `settings/OptionsSetup.lua:232` | call 1 | thin (1) |
| Options | `validate` (descriptor) | 17: AbsorbTracker, AuraMaster, BankLedger, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, MultiMeters, OutfitterReborn, PanelMaster, PartyFrameEnhanced, PremadeGroupsFilterExtension, QuickComms, RangeMaster, WhatGroup | call 17 | consumed (17) |
| IconBrowser | `lib.BUILTIN_TABS` | none | call 0 · test 1 | zero — kept, documented |
| IconBrowser | `lib.ColorFrom` | QuickComms `modules/Library.lua:305` | call 1 · def 1 · test 1 | thin (1) |
| IconBrowser | `lib.GLYPH_LABELS` | none | call 0 | zero — kept, documented |
| IconBrowser | `lib.IsGlyph` | OutfitterReborn `modules/IconBrowserSetup.lua:49`; QuickComms `modules/Library.lua:270` | call 2 · name-only 15 · def 3 · test 20 | thin (2) |
| IconBrowser | `lib.MacroIcons` | none | call 0 · test 2 | zero — kept, documented |
| IconBrowser | `lib.New` | OutfitterReborn `modules/IconBrowserSetup.lua:136`; QuickComms `settings/IconBrowser.lua:60` | call 4 · name-only 254 · def 39 · stub 29 · test 1103 | thin (2) |
| IconBrowser | `lib.SKIN_TOKENS` | none | call 0 · name-only 29 · stub 16 · test 31 | zero — kept, documented |
| IconBrowser | `lib.STRINGS` | none | call 0 · name-only 1 · stub 5 · test 191 | zero — kept, documented |
| IconBrowser | `lib.Sources` | none | call 0 · test 2 | zero — kept, documented |
| IconBrowser | `lib.Tint` | OutfitterReborn `modules/IconBrowserSetup.lua:66`; QuickComms `modules/Library.lua:298` | call 2 · name-only 4 · def 3 · test 9 | thin (2) |
| IconBrowser | `lib.ValidColor` | OutfitterReborn `modules/IconBrowserSetup.lua:59`; QuickComms `modules/Library.lua:288` | call 3 · name-only 2 · def 1 · test 5 | thin (2) |
| IconBrowser | `lib.WOWHEAD_ICONS` | none | call 0 | zero — kept, documented |
| Perf | `lib.DEFAULT_RING` | none | call 0 · test 2 | zero — kept, documented |
| Perf | `lib.EncodeJSON` | CharacterLedger `core/PerfSetup.lua:10` | call 1 · test 18 | thin (1) |
| Perf | `lib.New` | 14: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, QuickComms, RangeMaster | call 14 · name-only 244 · def 39 · stub 29 · test 1103 | consumed (14) |
| Perf | `lib.SCHEMA` | none | call 0 · name-only 1 · stub 1 · test 27 | zero — kept, documented |
| Perf | `lib.STRINGS` | none | call 0 · name-only 1 · stub 5 · test 191 | zero — kept, documented |
| Perf | `Announce` (instance) | none | call 0 · name-only 4 · def 1 · test 31 | zero — kept, documented |
| Perf | `BuildRecord` (instance) | none | call 0 · name-only 1 · def 1 · test 26 | zero — kept, documented |
| Perf | `Cancel` (instance) | none | call 0 · name-only 111 · def 13 · test 144 | zero — kept, documented |
| Perf | `Close` (instance) | none | call 0 · name-only 31 · def 15 · stub 4 · test 198 | zero — kept, documented |
| Perf | `Context` (instance) | none | call 0 · name-only 16 · def 5 · test 41 | zero — kept, documented |
| Perf | `ContextLines` (instance) | none | call 0 | zero — kept, documented |
| Perf | `EXPERIMENTS` (instance) | none | call 0 | zero — kept, documented |
| Perf | `EncodeJSON` (instance) | CharacterLedger `core/PerfSetup.lua:10` | call 1 · test 18 | thin (1) |
| Perf | `FormatReport` (instance) | none | call 0 · test 3 | zero — kept, documented |
| Perf | `HidePanel` (instance) | none | call 0 · name-only 19 · def 1 · stub 1 · test 64 | zero — kept, documented |
| Perf | `IsPanelShown` (instance) | none | call 0 · name-only 22 · stub 1 · test 84 | zero — kept, documented |
| Perf | `LABELS` (instance) | none | call 0 · name-only 10 · test 26 | zero — kept, documented |
| Perf | `Log` (instance) | none | call 0 · name-only 12 · def 2 · test 34 | zero — kept, documented |
| Perf | `MarkReviewed` (instance) | none | call 0 · test 1 | zero — kept, documented |
| Perf | `Measure` (instance) | none | call 0 · name-only 4 · def 1 · test 14 | zero — kept, documented |
| Perf | `Note` (instance) | 14: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, QuickComms, RangeMaster | call 122 · name-only 13 · def 5 · stub 15 · test 212 | consumed (14) |
| Perf | `OnCommand` (instance) | 14: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, QuickComms, RangeMaster | call 16 · def 3 · stub 17 · test 42 | consumed (14) |
| Perf | `Open` (instance) | none | call 0 · name-only 69 · def 25 · stub 5 · test 781 | zero — kept, documented |
| Perf | `PanelIsActionable` (instance) | none | call 0 | zero — kept, documented |
| Perf | `PanelStateOf` (instance) | none | call 0 · test 2 | zero — kept, documented |
| Perf | `Progress` (instance) | none | call 0 · test 1 | zero — kept, documented |
| Perf | `RefreshPanel` (instance) | none | call 0 · name-only 51 · stub 15 · test 48 | zero — kept, documented |
| Perf | `Reset` (instance) | none | call 0 · name-only 11 · def 13 · stub 19 · test 647 | zero — kept, documented |
| Perf | `Resume` (instance) | none | call 0 · name-only 21 · def 53 · test 307 | zero — kept, documented |
| Perf | `SCHEMA` (instance) | none | call 0 · name-only 1 · stub 1 · test 27 | zero — kept, documented |
| Perf | `STEPS` (instance) | none | call 0 · test 16 | zero — kept, documented |
| Perf | `Save` (instance) | none | call 0 · name-only 8 · def 7 · test 230 | zero — kept, documented |
| Perf | `ShowPanel` (instance) | none | call 0 · name-only 20 · def 4 · stub 1 · test 47 | zero — kept, documented |
| Perf | `Start` (instance) | none | call 0 · name-only 26 · def 19 · test 353 | zero — kept, documented |
| Perf | `StatusLines` (instance) | none | call 0 · test 1 | zero — kept, documented |
| Perf | `Stop` (instance) | none | call 0 · name-only 83 · def 14 · stub 1 · test 338 | zero — kept, documented |
| Perf | `Suspend` (instance) | none | call 0 · name-only 15 · def 60 · test 240 | zero — kept, documented |
| Perf | `TogglePanel` (instance) | none | call 0 · name-only 6 · test 1 | zero — kept, documented |
| Perf | `Usage` (instance) | none | call 0 · name-only 22 · def 1 · test 136 | zero — kept, documented |
| Perf | `armed` (instance) | ConsumableMaster `core/Diagnostics.lua:137` | call 1 · name-only 7 · def 2 · stub 1 · test 746 | thin (1) |
| Perf | `context` (instance) | none | call 0 · name-only 2 · def 4 · test 255 | zero — kept, documented |
| Perf | `descriptor` (instance) | none | call 0 · stub 12 · test 1022 | zero — kept, documented |
| Perf | `label` (instance) | ConsumableMaster `core/Diagnostics.lua:137` | call 1 · name-only 681 · def 8 · stub 50 · test 5293 | thin (1) |
| Perf | `name` (instance) | none | call 0 · name-only 978 · def 7 · stub 301 · test 13604 | zero — kept, documented |
| Perf | `on` (instance) | 14: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, QuickComms, RangeMaster | call 122 · name-only 30 · def 4 · stub 476 · test 16677 | consumed (14) |
| Perf | `recording` (instance) | ConsumableMaster `core/Diagnostics.lua:137` | call 1 · name-only 3 · stub 3 · test 209 | thin (1) |
| Perf | `ringMax` (instance) | none | call 0 | zero — kept, documented |
| Perf | `run` (instance) | ConsumableMaster `core/Diagnostics.lua:137` | call 1 · name-only 32 · def 51 · stub 30 · test 2740 | thin (1) |
| Perf | `slash` (instance) | none | call 0 · name-only 3 · stub 107 · test 1891 | zero — kept, documented |
| Perf | `title` (instance) | none | call 0 · name-only 375 · def 11 · stub 39 · test 2188 | zero — kept, documented |
| Perf | `L` (descriptor) | none | call 0 | zero — kept, documented |
| Perf | `addonName` (descriptor) | 14: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, QuickComms, RangeMaster | call 14 | consumed (14) |
| Perf | `buckets` (descriptor) | 14: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, QuickComms, RangeMaster | call 14 | consumed (14) |
| Perf | `decorate` (descriptor) | none | call 0 | zero — kept, documented |
| Perf | `lifecycle` (descriptor) | 14: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, QuickComms, RangeMaster | call 14 | consumed (14) |
| Perf | `log` (descriptor) | 14: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, QuickComms, RangeMaster | call 14 | consumed (14) |
| Perf | `name` (descriptor) | 14: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, QuickComms, RangeMaster | call 14 | consumed (14) |
| Perf | `onChange` (descriptor) | none | call 0 | zero — kept, documented |
| Perf | `onSettings` (descriptor) | none | call 0 | zero — kept, documented |
| Perf | `print` (descriptor) | 14: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, QuickComms, RangeMaster | call 14 | consumed (14) |
| Perf | `ring` (descriptor) | none | call 0 | zero — kept, documented |
| Perf | `showLog` (descriptor) | 14: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, QuickComms, RangeMaster | call 14 | consumed (14) |
| Perf | `slash` (descriptor) | 14: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, QuickComms, RangeMaster | call 14 | consumed (14) |
| Perf | `sv` (descriptor) | 14: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, QuickComms, RangeMaster | call 14 | consumed (14) |
| Perf | `title` (descriptor) | 14: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, QuickComms, RangeMaster | call 14 | consumed (14) |
| Perf | `version` (descriptor) | 14: AbsorbTracker, AuraMaster, CharacterLedger, CombatTrail, ConsumableMaster, DropWatcher, KickCD, LibKa0sSkinTester, LootHistory, MultiMeters, OutfitterReborn, PartyFrameEnhanced, QuickComms, RangeMaster | call 14 | consumed (14) |
| Sim | `lib.New` | 9: AbsorbTracker, BankLedger, CharacterLedger, CombatTrail, DropWatcher, KickCD, LootHistory, MultiMeters, RangeMaster | call 10 · name-only 248 · def 39 · stub 29 · test 1103 | consumed (9) |
| Sim | `lib.NewSeam` | 9: AbsorbTracker, BankLedger, CharacterLedger, CombatTrail, DropWatcher, KickCD, LootHistory, MultiMeters, RangeMaster | call 9 · test 8 | consumed (9) |
| Sim | `lib.SAMPLE` | none | call 0 · name-only 7 · test 18 | zero — kept, documented |
| Sim | `lib.STRINGS` | none | call 0 · name-only 1 · stub 5 · test 191 | zero — kept, documented |
| Sim | `lib.Sample` | 8: BankLedger, CharacterLedger, CombatTrail, DropWatcher, KickCD, LootHistory, MultiMeters, WhatGroup | call 8 · name-only 5 · def 5 · test 106 | consumed (8) |
| Sim | `AddListener` (instance) | 8: AbsorbTracker, BankLedger, CharacterLedger, DropWatcher, KickCD, LootHistory, MultiMeters, RangeMaster | call 11 · name-only 5 · test 2 | consumed (8) |
| Sim | `After` (instance) | 4: BankLedger, DropWatcher, KickCD, MultiMeters | call 12 · name-only 91 · def 7 · stub 1 · test 210 | consumed (4) |
| Sim | `DeliverForCleanup` (instance) | DropWatcher `modules/SimEvents.lua:806`; KickCD `modules/Sim.lua:485` | call 5 · def 6 · test 2 | thin (2) |
| Sim | `Fire` (instance) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 36 · name-only 12 · def 7 · test 188 | consumed (5) |
| Sim | `HidePanel` (instance) | DropWatcher `modules/SimPanel.lua:134` | call 12 · name-only 7 · def 1 · stub 1 · test 64 | thin (1, read by hand) |
| Sim | `IsActive` (instance) | 8: AbsorbTracker, BankLedger, CharacterLedger, DropWatcher, KickCD, LootHistory, MultiMeters, RangeMaster | call 71 · name-only 45 · def 12 · stub 1 · test 346 | consumed (8) |
| Sim | `IsDelivering` (instance) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 8 · name-only 4 · test 14 | consumed (5) |
| Sim | `IsPanelShown` (instance) | DropWatcher `modules/SimScenario.lua:197`; LootHistory `modules/Sim.lua:255` | call 12 · name-only 10 · stub 1 · test 84 | thin (2, read by hand) |
| Sim | `Keys` (instance) | BankLedger `modules/Diagnostics.lua:92`; LootHistory `modules/Diagnostics.lua:369`; MultiMeters `core/Diagnostics_Runtime.lua:411` | call 0 · name-only 6 · def 9 · test 58 | consumed (3, read by hand) |
| Sim | `Live` (instance) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 0 · name-only 38 · def 12 · test 72 | consumed (5, read by hand) |
| Sim | `OnStop` (instance) | 8: AbsorbTracker, BankLedger, CharacterLedger, DropWatcher, KickCD, LootHistory, MultiMeters, RangeMaster | call 18 · name-only 5 · test 2 | consumed (8) |
| Sim | `OnStopGuarded` (instance) | BankLedger `core/SimSetup.lua:82`; DropWatcher `modules/Sim.lua:344`; MultiMeters `core/SimSetup.lua:127` | call 4 · name-only 4 · test 1 | consumed (3) |
| Sim | `PanelRows` (instance) | none | call 0 · def 6 · test 40 | zero — kept, documented |
| Sim | `Pause` (instance) | none | call 2 · name-only 5 · def 3 · test 18 | zero — kept, documented (read by hand) |
| Sim | `RefreshPanel` (instance) | none | call 2 · name-only 49 · stub 15 · test 48 | zero — kept, documented (read by hand) |
| Sim | `ResetPanelPosition` (instance) | DropWatcher `modules/Window.lua:861` | call 3 · name-only 4 · test 5 | thin (1, read by hand) |
| Sim | `Restart` (instance) | none | call 2 · name-only 4 · test 12 | zero — kept, documented (read by hand) |
| Sim | `Resume` (instance) | none | call 2 · name-only 19 · def 53 · test 307 | zero — kept, documented (read by hand) |
| Sim | `Run` (instance) | none | call 3 · name-only 25 · def 8 · stub 6 · test 461 | zero — kept, documented (read by hand) |
| Sim | `RunVerb` (instance) | 8: AbsorbTracker, BankLedger, CharacterLedger, DropWatcher, KickCD, LootHistory, MultiMeters, RangeMaster | call 26 · name-only 16 · def 10 · stub 3 · test 76 | consumed (8) |
| Sim | `Session` (instance) | 5: BankLedger, CharacterLedger, DropWatcher, KickCD, MultiMeters | call 34 · name-only 10 · def 9 · test 73 | consumed (5) |
| Sim | `SetProvider` (instance) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 0 · name-only 9 · def 7 · test 19 | consumed (5, read by hand) |
| Sim | `ShowPanel` (instance) | 7: AbsorbTracker, BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters, RangeMaster | call 13 · name-only 7 · def 4 · stub 1 · test 47 | consumed (7) |
| Sim | `Start` (instance) | DropWatcher `modules/SimScenario.lua:256`; RangeMaster `modules/Sim.lua:176` | call 2 · name-only 24 · def 19 · test 353 | thin (2) |
| Sim | `Status` (instance) | 6: BankLedger, CharacterLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 14 · name-only 12 · def 14 · test 201 | consumed (6) |
| Sim | `Step` (instance) | none | call 0 · name-only 5 · def 7 · test 170 | zero — kept, documented |
| Sim | `Steps` (instance) | BankLedger `modules/Sim.lua:200`; DropWatcher `modules/Diagnostics.lua:450`; LootHistory `modules/Sim.lua:324` | call 9 · def 7 · stub 1 · test 30 | consumed (3) |
| Sim | `Stop` (instance) | 8: AbsorbTracker, BankLedger, CharacterLedger, DropWatcher, KickCD, LootHistory, MultiMeters, RangeMaster | call 25 · name-only 58 · def 14 · stub 1 · test 338 | consumed (8) |
| Sim | `TogglePanel` (instance) | none | call 2 · name-only 4 · test 1 | zero — kept, documented (read by hand) |
| Sim | `Unwrapped` (instance) | none | call 0 · name-only 2 · def 7 · test 28 | zero — kept, documented |
| Sim | `L` (descriptor) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 5 | consumed (5) |
| Sim | `addonName` (descriptor) | none | call 0 | zero — kept, documented |
| Sim | `check` (descriptor) | 5: BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters | call 0 | consumed (5, read by hand) |
| Sim | `close` (descriptor) | none | call 0 | zero — kept, documented |
| Sim | `debug` (descriptor) | 7: AbsorbTracker, BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters, RangeMaster | call 7 | consumed (7) |
| Sim | `deliver` (descriptor) | 8: AbsorbTracker, BankLedger, CombatTrail, DropWatcher, KickCD, LootHistory, MultiMeters, RangeMaster | call 8 | consumed (8) |
| Sim | `footer` (descriptor) | none | call 0 | zero — kept, documented |
| Sim | `gate` (descriptor) | 4: BankLedger, CombatTrail, LootHistory, MultiMeters | call 4 | consumed (4) |
| Sim | `isStoodDown` (descriptor) | 8: AbsorbTracker, BankLedger, CombatTrail, DropWatcher, KickCD, LootHistory, MultiMeters, RangeMaster | call 8 | consumed (8) |
| Sim | `name` (descriptor) | 8: AbsorbTracker, BankLedger, CombatTrail, DropWatcher, KickCD, LootHistory, MultiMeters, RangeMaster | call 8 | consumed (8) |
| Sim | `onClick` (descriptor) | none | call 0 | zero — kept, documented |
| Sim | `panel` (descriptor) | 8: AbsorbTracker, BankLedger, CombatTrail, DropWatcher, KickCD, LootHistory, MultiMeters, RangeMaster | call 8 | consumed (8) |
| Sim | `play` (descriptor) | 8: AbsorbTracker, BankLedger, CombatTrail, DropWatcher, KickCD, LootHistory, MultiMeters, RangeMaster | call 8 | consumed (8) |
| Sim | `prepare` (descriptor) | 8: AbsorbTracker, BankLedger, CombatTrail, DropWatcher, KickCD, LootHistory, MultiMeters, RangeMaster | call 8 | consumed (8) |
| Sim | `print` (descriptor) | 8: AbsorbTracker, BankLedger, CombatTrail, DropWatcher, KickCD, LootHistory, MultiMeters, RangeMaster | call 8 | consumed (8) |
| Sim | `refusal` (descriptor) | 8: AbsorbTracker, BankLedger, CombatTrail, DropWatcher, KickCD, LootHistory, MultiMeters, RangeMaster | call 8 | consumed (8) |
| Sim | `rows` (descriptor) | none | call 0 | zero — kept, documented |
| Sim | `scenarios` (descriptor) | 8: AbsorbTracker, BankLedger, CombatTrail, DropWatcher, KickCD, LootHistory, MultiMeters, RangeMaster | call 8 | consumed (8) |
| Sim | `seam` (descriptor) | 8: AbsorbTracker, BankLedger, CombatTrail, DropWatcher, KickCD, LootHistory, MultiMeters, RangeMaster | call 8 | consumed (8) |
| Sim | `slash` (descriptor) | 8: AbsorbTracker, BankLedger, CombatTrail, DropWatcher, KickCD, LootHistory, MultiMeters, RangeMaster | call 8 | consumed (8) |
| Sim | `statusLine` (descriptor) | DropWatcher `modules/Sim.lua:292`; MultiMeters `modules/Sim.lua:344` | call 2 | thin (2) |
| Sim | `stepDelay` (descriptor) | 8: AbsorbTracker, BankLedger, CombatTrail, DropWatcher, KickCD, LootHistory, MultiMeters, RangeMaster | call 8 | consumed (8) |
| Sim | `stopText` (descriptor) | 7: AbsorbTracker, BankLedger, DropWatcher, KickCD, LootHistory, MultiMeters, RangeMaster | call 7 | consumed (7) |
| Sim | `title` (descriptor) | 4: BankLedger, DropWatcher, LootHistory, MultiMeters | call 0 | consumed (4, read by hand) |
| Sim | `tooltip` (descriptor) | none | call 0 | zero — kept, documented |
| Sim | `usage` (descriptor) | CombatTrail `modules/Sim.lua:328`; DropWatcher `modules/Sim.lua:291`; LootHistory `modules/Sim.lua:375` | call 3 | consumed (3) |
| Sim | `verbs` (descriptor) | DropWatcher `modules/Sim.lua:289`; LootHistory `modules/Sim.lua:373` | call 2 | thin (2) |
| Sim | `why` (descriptor) | DropWatcher `modules/Sim.lua:290`; LootHistory `modules/Sim.lua:374` | call 2 | thin (2) |

## Re-running it

From this repo's root, with every addon checked out as a sibling:

```sh
/home/tushar/.claude/dev-copilot/bin/ka0s-bounded \
  lua ../Ka0sAddonsCommonTasks/docs/2026-10-02-LIBKA0S_CENSUS_ADOPTION/plan-data/census.lua \
      .. <output folder>
```

At v1.83.0 that was the copy in `../Ka0sAddonsCommonTasks/docs/2026-10-31-FINDINGS_REMEDIATION/plan-data/census-v1.83.0/`,
with that folder as the output. At v1.109.0 the same copy ran with each addon's `master` extracted into a scratch
GIT root (`git archive master`, then `git init` and `git add -A` so `ls-files` answers) and `ADDONS.md` from the
standard's `master`, and the v1.83.0 `verdicts.tsv` and `issues.tsv` copied beside the output, DpsRace struck from
their host lists; it took eight minutes under the bounded runner. Write a new run's output to a folder of its own, never into a
frozen bundle. Render from inside the output folder with
`lua census-render.lua table|zero|doclines . <stamp> <roster size>`.

The scan takes about five minutes. Then read every export whose verdict moved, every new export,
and every call hit that sits in a host's degradation stub, and update `verdicts.tsv` and this page
together. The tool classifies hits, but only reading the code settles
a verdict.
