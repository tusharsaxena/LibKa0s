# Analysis — 20260924-040553

- **Addon:** LibKa0s 1.55.0 → 1.56.0 (release run, `--release 1.56.0`)
- **Verdict:** green
- **Commit:** 326494e (`feat/2026-09-23-review-audit-remediation`), clean
- **Previous run:** 20260923-144526 (1.54.2 → 1.55.0)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.56.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, and `complexity.warnings` is 0. **Perf was not measured**: this repository
ships no `tests/perf.lua`, so v1.56.0 was verified across **three** suites, not four. The run
measured the library half of the 2026-09-23 review-and-audit remediation: twelve majors' minors
move, the kit is at revision 26, and there are 163 more cases than at v1.55.0's release run.

`addonVersion` reads `1.55.0` because a library repo has no TOC and the runner falls back to the
newest tag; `release` is the field that names the version this bundle records.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260923-144526 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 92 files | [`lint.txt`](lint.txt) | +11 files (81 → 92) |
| tests | pass | 1647 passed, 1 skipped, 0 failed, 1648 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | +163 cases (1485 → 1648) |
| perf | skip | not measured — no `tests/perf.lua` | — | No. |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Totals up, averages flat |

**`perf` was not measured.** The manifest's `skipReason` is *no tests/perf.lua — this addon ships no
offline scenarios*: `automated-tests-§3`'s first sanctioned reason, nothing to run. It is not a
`performance-§12` exemption, because this repository's `## Documented deviations` register carries
no such row. The record says nothing about the library's runtime cost.

**The one skipped case** is the suite inventory's record of the declined kit prose gate
(`tests/_kit/test_prose.lua`), which `CLAUDE.md`'s `localization-§5` register row declines in favor
of `tests/test_prose.lua`. It is counted in the total and in neither `passed` nor `failed`.

| Metric | Value |
|---|---|
| Total NLOC | 33581 |
| Functions | 4706 |
| Avg NLOC / function | 6.6 |
| Avg CCN | 2.0 |
| Max CCN | 15 |
| Avg tokens / function | 51.8 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 13 |
| Files over the 1500 cap | 2 |

## What moved

- **lint**: 81 → **92** files, still 0/0. Among the new files are kit revision 26's
  `testkit/asserts.lua`, `testkit/prose_lists.lua` and `testkit/mock_events.lua`, and suites the
  remediation added beside the modules they pin, such as `tests/test_schema_batch.lua`,
  `tests/test_kit_asserts.lua` and `tests/test_mock_events.lua`.
- **tests**: 1485 → **1648** (+163), 0 failed both times, 1 skip both times (the same declined
  gate).
- **complexity, totals**: NLOC 30419 → **33581** (+3162), functions 4248 → **4706** (+458).
- **complexity, averages**: flat. Avg CCN 2.0, avg NLOC/function 6.6, max CCN 15; avg tokens 52.1
  → **51.8**. The library grew; it did not get denser.
- **bands**: 10 → **13** in 1000–1500, 3 → **2** over the cap. `testkit/framework.lua` left the
  census for the band (1583 → 1385, kit revision 26's peel); `tests/test_options_tabs.lua` (1218)
  and `tests/test_options_idsuggest.lua` (1002) crossed into the band;
  `LibKa0s/OptionsWidgets.lua` came down 3922 → 3852.

## Complexity watch list

Carried in full in [`RESULTS.md`](../RESULTS.md), regenerated from this run's own output, with every
Disposition cell ruled at this run.

### Functions warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None warned: zero functions above CCN 15, which is the gate's condition. **Six functions sit exactly
at 15**, the ceiling. They are recorded here as watch entries because the runner lists only
functions above it (review finding `LibKa0s-R-15`, which named four and was corrected to six).
Each figure is from [`complexity.txt`](complexity.txt):

- `lib.Catalog`, `LibKa0s/Bus.lua:358-410`
- `lib.GetSpellCooldown`, `LibKa0s/Compat.lua:243-260`
- `idHelpIcon`, `LibKa0s/OptionsWidgets.lua:2950-2959`
- `liveTimers`, `testkit/mock_record.lua:95-113`
- `M.__fire`, `testkit/mock_record.lua:580-604`
- `audit`, `testkit/test_layout_cap.lua:427-463`

None of them is tangled: each is a run of guards or `or`-defaults, and each `and`/`or` counts as a
decision. **Watch, with a hard rule:** one more branch in any of them fails the tag, so a change
that touches one splits it first, with its behavior pinned before the split, as v1.55.0's release
run did for Schema's `Set` and `Validate`.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua` | 1457 | Re-ruled 2026-09-24, accepted; re-check at the next member or 1475 |
| 1000–1500 (on notice) | `LibKa0s/OptionsTabs.lua` | 1489 | Re-ruled 2026-09-24, accepted; re-check at the next member or 1495 |
| 1000–1500 (on notice) | `LibKa0s/Perf.lua` | 1319 | Issue #7 |
| 1000–1500 (on notice) | `LibKa0s/Widgets.lua` | 1266 | Issue #36 |
| 1000–1500 (on notice) | `testkit/framework.lua` | 1385 | Accepted at this run; re-check at 1450 or a 60-line kit addition |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1454 | On notice; re-check at 1490 or a 30-line kit addition |
| 1000–1500 (on notice) | `testkit/test_prose.lua` | 1486 | Issue #39 |
| 1000–1500 (on notice) | `tests/test_options.lua` | 1339 | Issue #35 |
| 1000–1500 (on notice) | `tests/test_options_idsuggest.lua` | 1002 | Accepted at this run; peels with #32 |
| 1000–1500 (on notice) | `tests/test_options_tabs.lua` | 1218 | Accepted at this run; re-check at 1350 or the next `OptionsTabs.lua` member |
| 1000–1500 (on notice) | `tests/test_schema.lua` | 1335 | Issue #38 |
| 1000–1500 (on notice) | `tests/test_slash.lua` | 1327 | Carried: re-check at 1350 |
| 1000–1500 (on notice) | `tests/test_widgets.lua` | 1493 | Issue #37 |
| > 1500 (over cap) | `LibKa0s/OptionsWidgets.lua` | 3852 | See the census row, `CLAUDE.md` § *Files over the 1500-line cap* (#32) |
| > 1500 (over cap) | `tests/test_options_widgets.lua` | 4086 | See the census row, `CLAUDE.md` § *Files over the 1500-line cap* (#33) |

The two over-cap cells replace dispositions that contradicted the census (audit finding
`LibKa0s-A-02`): the OptionsWidgets row pointed at closed #16 and at a deleted
`tests/test_layout_cap.lua`, the suite's row pointed at closed #8, and `testkit/framework.lua`'s
over-cap row was blank. The band cells cite the issues `LK-32` filed or its dated re-rules. The
four entries with no issue (`testkit/framework.lua`, `tests/test_options_idsuggest.lua`,
`tests/test_options_tabs.lua`, and `testkit/mock_base.lua`, re-read) carry a dated ruling and a
re-check trigger.

## Record corrections

Frozen bundles are not edited, so each correction is stated once, here.

- **Six tags shipped with no bundle.** `v1.28.0`, `v1.29.0`, `v1.36.0`, `v1.36.1`, `v1.54.1` and
  `v1.54.2` have no manifest whose `release` names them: `grep -l '"release": "<X.Y.Z>"'
  docs/automated-tests/*/manifest.json` prints nothing for any of them. `v1.24.0`, which
  `docs/releasing.md` already names, is a seventh. None is backfilled. From v1.56.0 on,
  `docs/releasing.md` step 7's precondition block refuses a tag with no such bundle.
- **The release-run `ANALYSIS.md` gap.** Of the 38 release-stamped bundles from 2026-09-08 through
  v1.55.0, 32 carry no `ANALYSIS.md`, and the most recent is v1.55.0's own release run,
  `20260923-144526`. `automated-tests-§5` makes the file a MUST at every release run. This bundle is
  the first release run since `20260922-202214` to carry one, and `docs/releasing.md` step 7 now
  asks for it as a numbered sub-step before the tag.
- **`20260916-093057/ANALYSIS.md:60-62` misread that gap.** It said the missing write-ups since
  `20260908-181447` were not a breach, because the file is mandatory only at a release. Every one
  of the eighteen bundles between those two stamps is a release run (each manifest carries a
  `release`), so each missing `ANALYSIS.md` was a breach of `automated-tests-§5`.
- **`20260908-181447/ANALYSIS.md:92` over-counted by one** (audit finding `LibKa0s-A-11`). It read
  "Twenty of this repository's thirty-four bundles carry no `ANALYSIS.md`"; the figure was
  **nineteen**, as that bundle's own next line (:93) says. No later write-up corrected it until
  this one.

## Consumer dry-run of the v1.56.0 payload

Taken on 2026-09-24 from this commit's `LibKa0s/` and `testkit/`, copied whole over `libs/LibKa0s/`
and `tests/_kit/` in a `git archive HEAD` copy of each of the eleven addons'
`feat/2026-09-23-review-audit-remediation` branch. Each copy was put under a throwaway `git init`,
so the gates that read the tracked tree (`eol`, `prose`, the layout cap) read it as they do in the
addon. No addon repository was touched. Each addon was also run the same way on its own vendored
v1.55.0 payload as a baseline, and **every baseline was green**, so every red below comes from this
payload. `test_vendor_sync` skips in a copy (no sibling checkout), in both runs.

| Addon | Base (v1.55.0) | Payload (v1.56.0) | Reds |
|---|---|---|---|
| AbsorbTracker (`f4b61a6`) | 708 / 0 / 2 of 710 | 707 / 1 / 2 | 1 |
| AuraMaster (`0ede122`) | 1294 / 0 / 2 of 1296 | 1289 / 5 / 2 | 5 |
| BankLedger (`24ede85`) | 1015 / 0 / 2 of 1017 | 1013 / 2 / 2 | 2 |
| ConsumableMaster (`38f3901`) | 996 / 0 / 2 of 998 | 995 / 1 / 2 | 1 |
| KickCD (`f28df97`) | 1048 / 0 / 2 of 1050 | 1046 / 2 / 2 | 2 |
| LootHistory (`36072e5`) | 856 / 0 / 2 of 858 | 854 / 2 / 2 | 2 |
| MultiMeters (`888e26f`) | 1946 / 0 / 2 of 1948 | 1939 / 7 / 2 | 7 |
| PanelMaster (`7183100`) | 882 / 0 / 2 of 884 | 881 / 1 / 2 | 1 |
| PartyFrameEnhanced (`4c2a7e6`) | 287 / 0 / 2 of 289 | 278 / 9 / 2 | 9 |
| PrettyChat (`e561b79`) | 436 / 0 / 2 of 438 | 433 / 3 / 2 | 3 |
| WhatGroup (`7177411`) | 725 / 0 / 2 of 727 | 722 / 3 / 2 | 3 |

Figures are passed / failed / skipped. The red cases, per addon, with the change behind each:

- **AbsorbTracker**: `parity: the Schema stub's instance carries every member of a live instance`
  (`SetMany` missing; Schema minor 2).
- **AuraMaster**: `disabled: every frame that was shown is hidden, at the source`; `disabled: firing
  every baseline event writes nothing, says nothing and shows nothing` (30 frames);
  `disabled: the launcher's left-click is refused and its right-click still opens the panel`
  (30 frames). All three come from frames starting shown (kit 26). Also `docs: every file:line
  citation sits within 3 lines of a name its own sentence gives in backticks` (`DEPENDENCIES.md`
  cites `tests/_kit/framework.lua:631-643`, which kit 26's peel moved) and `eol: every tracked file
  carries the terminator .gitattributes declares for it` (a lone CR at `tests/page_helpers.lua:80`).
- **BankLedger**: `Launcher: a host with neither broker library reports it and does NOT raise` (the
  missing-library notice now prints once per process, and an earlier case already printed it;
  Launcher minor 2); `LibKa0s-Schema degraded: the stub instance carries every member the addon
  reaches` (`SetMany`).
- **ConsumableMaster**: `prose: no authored file carries a British spelling from
  localization-§5's published list` (`docs/perf-analysis/README.md:25` and `:26`, a store-root file
  the gate now reads; `docs/settings-panel.md:80`, the newly listed stem of *synchronize*).
- **KickCD**: the same `prose` case (`docs/perf-analysis/README.md:35` and `:36`;
  `docs/settings-panel.md:168` and `settings/Panel_Render.lua:61`, the *synchronize* stem); the
  `eol` case (852 lone CRs in the frozen `docs/reviews/2026-09-23/` bundle, as `LK-06`'s dry run
  found).
- **LootHistory**: `parity: the Schema stub instance carries every member of the live runtime`
  (`SetMany`); `Widgets: the seam builds a real library dropdown, art passed as parameters` (the
  case pins Widgets minor 9, and the payload is 10).
- **MultiMeters**: the `prose` case (`tests/test_options_panel.lua:1091`, the *synchronize* stem);
  `Blocks: a drag reports where it landed`, `Blocks: the page hands LibKa0s the boundary, so a shown
  column stops at the rule`, `Blocks: an enabled block cannot be dragged past the last enabled one`,
  `Blocks: a list with nothing disabled drags end to end`, `Blocks: an empty item list still builds
  and finishes a controller` and `Columns: dragging a block reorders the stored array`. All six come
  from Widgets minor 10: `ReorderList` polls on its own ghost frame and pools its drop line, so a
  test that drives the drag through the host row's `OnUpdate` or reads the cached drop line no
  longer reaches it.
- **PanelMaster**: `Parity: the Schema seam's degraded surface matches the live one, on both levels`
  (`SetMany`).
- **PartyFrameEnhanced**: `providers: hidden member frames and raid tokens are skipped` (a fixture
  that relied on a frame starting hidden). `disabled: the baseline — enabled, the addon registers
  and draws`, `disabled: every registration the addon owns is UNREGISTERED, not gated`,
  `disabled: re-enabled, the addon rebuilds from CURRENT state`, `disabled: two holds, one latch —
  releasing one never resurrects the other's addon` and `disabled: the suite leaves the world enabled
  for the suites after it`: the suite's `sig` helper indexes `r.target`, which kit 26's new
  `callback` record does not carry. `disabled: every frame that was on screen is hidden, and refused
  at the source` (8 frames left shown; frames start shown) and `disabled: no game event produces a
  write, a line, or a frame` (a nil `bar` downstream of the same). `optionssetup: Reset All resets
  the active profile only — the list and the active profile stay` (no `PROFILE` message reached the
  elements; the AceDB fake's profile path changed at kit 26, and the exact cause is not isolated
  here).
- **PrettyChat**: `a settings page shown in combat is covered, not drawn and not closed` (the test
  finds no `Categories` subcategory; read as Options minor 24's park, since the panel is created
  while the test holds combat and registers only at `PLAYER_REGEN_ENABLED`); `the Schema stub
  carries the whole live surface, library and instance` (`SetMany`); `the buffer is capped and drops
  its oldest lines first` (1520 lines held against 1500: DebugLog minor 13 trims in batches at the
  cap).
- **WhatGroup**: `panel: registering during combat still registers (options-ui-§9)`, `panel: a login
  taken in combat needs no second registration` and `lifecycle: a login taken in combat still
  registers the panel`. All three pin the eager registration `options-ui-§9` states, which Options
  minor 24's park replaces; the open `options-ui-§9` row in `CLAUDE.md`'s register is this conflict.

Each of these is owed by its addon before or in its v1.56.0 re-vendor, and the owner's standing
ruling applies: a red is fixed in the addon, never by weakening an assertion. Some are not plain test
updates. The three WhatGroup cases and PrettyChat's combat case turn on the `options-ui-§9` ruling
still owed (keep the park and amend the standard, or register at once). PrettyChat's buffer case,
LootHistory's minor pin and PartyFrameEnhanced's `target` cases pin library or kit behavior whose
documented contract changed, so those tests move with the contract.

## Actions

1. **Owner ruling on `options-ui-§9`** (`CLAUDE.md`'s provisional register row, from `LK-25`). It is
   owed before `v1.56.0` is pushed or any consumer re-vendors it. The tag is cut locally on the
   commit that carries this bundle; if the ruling narrows `LK-25`, the tag moves with the fix. Not
   new: the register row names it.
2. **Each addon's reds above** go to its pre-re-vendor fixes in the remediation plan's Milestone 2.
   This is the payload's final dry run; the kit 26 reds agree with what `LK-05`, `LK-06` and `LK-07`
   found.
3. **The six CCN-15 functions**: watch, as above. Not new (`LibKa0s-R-15`).
