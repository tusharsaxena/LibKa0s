# Analysis — 20260926-193105

- **Addon:** LibKa0s 1.62.0 (label: *final automated-tests sweep run*; not a release run)
- **Verdict:** green
- **Commit:** 5dc9f5d (`feat/2026-09-26-automated-tests-sweep`), clean
- **Previous run:** 20260926-182957 (the v1.62.0 release run, at `e636e9d`)

## Headline

Green on the three suites that ran ([`manifest.json`](manifest.json)): lint 0/0 over 122 files,
1747 of 1748 cases passed with the one declared skip, and complexity at 0 warnings with max CCN 15.
**Perf was not measured**, because this repository ships no `tests/perf.lua`. Every figure matches the
previous run. The one commit between the two runs (`5dc9f5d`) touched only the release record, so
nothing moved. This is the closing reading of the 2026-09-26 automated-tests sweep, and there is
nothing to act on in this repository.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260926-182957 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 122 files | [`lint.txt`](lint.txt) | No (122 files, 0/0) |
| tests | pass | 1747 passed, 1 skipped, 0 failed, 1748 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No (inventory identical) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | No (every per-function row identical) |

| Metric | Value |
|---|---|
| Total NLOC | 36218 |
| Functions | 5050 |
| Avg NLOC / function | 6.6 |
| Avg CCN | 2.0 |
| Max CCN | 15 |
| Avg tokens / function | 51.7 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 10 |
| Files over the 1500 cap | 0 |

**`perf` was not measured.** The manifest's `skipReason` is *no tests/perf.lua — this addon ships no
offline scenarios*. That is `automated-tests-§3`'s first sanctioned reason, nothing to run. The record
says nothing about runtime cost. It does not say the library is cheap.

**`tests` carries one skip**, the same one as the previous run. The kit's own
`tests/_kit/test_prose.lua` is declined under `CLAUDE.md`'s `localization-§5` deviation row, and
`tests/test_prose.lua` runs in its place ([`tests.txt`](tests.txt), line 1). The skip counts toward
the total and not toward `passed`.

**`complexity` sits at the ceiling without crossing it.** Max CCN is exactly 15, and the same six
functions reach it as at the previous run ([`complexity.txt`](complexity.txt)): `lib.Catalog`
(`LibKa0s/Bus.lua:358`), `lib.GetSpellCooldown` (`LibKa0s/Compat.lua:243`), `idHelpIcon`
(`LibKa0s/OptionsIdList.lua:459`), `liveTimers` (`testkit/mock_record.lua:95`), `M.__fire`
(`testkit/mock_record.lua:580`) and `audit` (`testkit/test_layout_cap.lua:427`). None of them warns,
because the threshold is `> 15`.

## What moved

Against the previous run, 20260926-182957:

- **lint**: nothing moved. 122 files, 0/0 ([`lint.txt`](lint.txt)).
- **tests**: nothing moved. 1748 cases, and the generated inventory is identical line for line apart
  from its stamp ([`test-cases.md`](test-cases.md)).
- **perf**: still a skip.
- **complexity**: nothing moved. The per-function rows in [`complexity.txt`](complexity.txt) are
  identical to the previous bundle's, so the totals, the averages, the band (10) and the census (0)
  are all unchanged.

Against the sweep's opening run, 20260926-160448 (at `cf38896`), which is the record the sweep set out
to move:

- lint: 100 → 122 files, 0/0 throughout.
- tests: 1745 → 1748 cases, with 1 skip throughout.
- complexity: NLOC 35854 → 36218 and functions 5039 → 5050. Avg NLOC 6.6, avg CCN 2.0, avg tokens
  51.7 and max CCN 15 did not move, and warnings stayed at 0. **Band 13 → 10, over-cap 2 → 0.**
  Six files left the band: `testkit/framework.lua`, `testkit/test_prose.lua`,
  `tests/test_options_idsuggest.lua`, `tests/test_options_tabs.lua`, `tests/test_slash.lua` and
  `tests/test_widgets.lua`. Both census files came off: `LibKa0s/OptionsWidgets.lua` dropped into
  the band and `tests/test_options_widgets.lua` dropped below it. `LibKa0s/Options.lua` and
  `LibKa0s/OptionsTabs.lua` stayed in the band at lower counts. Two new files entered it,
  `LibKa0s/OptionsIds.lua` and `LibKa0s/OptionsIdList.lua`.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua` | 1261 | Carried: peeled (`LK-ATS-04`), then accepted at 1261; re-check at the next member or 1400 lines. |
| 1000–1500 (on notice) | `LibKa0s/OptionsIdList.lua` | 1193 | Carried: accepted (`LK-ATS-01`, #32); re-check at 1350 lines. |
| 1000–1500 (on notice) | `LibKa0s/OptionsIds.lua` | 1358 | Carried: accepted (`LK-ATS-01`, #32); re-check at 1450 lines. |
| 1000–1500 (on notice) | `LibKa0s/OptionsTabs.lua` | 1293 | Carried: peeled (`LK-ATS-03`), then accepted at 1293; re-check at the next member or 1400 lines. |
| 1000–1500 (on notice) | `LibKa0s/OptionsWidgets.lua` | 1422 | Carried: accepted (`LK-ATS-01`, #32); re-check at 1450 lines or the next maker. |
| 1000–1500 (on notice) | `LibKa0s/Perf.lua` | 1319 | Carried: tracked as #7 (open). Worst function `groupContext`, CCN 11. |
| 1000–1500 (on notice) | `LibKa0s/Widgets.lua` | 1266 | Carried: tracked as #36 (open). |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1454 | Carried: on notice, 46 lines from the cap; re-check at 1490 lines or a kit change adding more than 30 here. |
| 1000–1500 (on notice) | `tests/test_options.lua` | 1339 | Carried: tracked as #35 (open). |
| 1000–1500 (on notice) | `tests/test_schema.lua` | 1335 | Carried: tracked as #38 (open). |

The runner left no blank Disposition cell in `RESULTS.md`. Nothing is new to the band and nothing
left it since the previous run. Every carried cell's figures (LOC, re-check triggers, the distance
to the cap, `groupContext`'s CCN, and the open state of #7, #35, #36 and #38) were re-checked
against this run and the tree, and all of them still hold. No cell needed a refresh (`ATS-23`).
`RESULTS.md`'s Disposition column is unchanged from the previous run.

## Actions

None in this repository.
