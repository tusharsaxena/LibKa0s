# Analysis — 20260926-182957

- **Addon:** LibKa0s 1.61.0 → 1.62.0 (release run, `--release 1.62.0`)
- **Verdict:** green
- **Commit:** e636e9d (`feat/2026-09-26-automated-tests-sweep`), clean
- **Previous run:** 20260926-160448 (1.61.0, not a release run, at `cf38896`)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.62.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, and `complexity.warnings` is 0. **Perf was not measured**: this repository
ships no `tests/perf.lua`, so v1.62.0 was verified across **three** suites, not four. The run
measured the library's half of the 2026-09-26 automated-tests sweep: four peels that take
`LibKa0s-Options-1.0` to ten files (26.1.32.1.1.6.1.7.4.1), the test kit at revision 31, and the
suite splits that go with them. **The census is empty** (`overCapFiles` 0, was 2) and the band holds
10 files (was 13). There are 3 more cases than at the previous run, all in the kit's runner suite.
Nothing to act on in this repository.

`addonVersion` reads `1.61.0` because a library repo has no TOC and the runner falls back to the
newest tag; `release` is the field that names the version this bundle records. The run is on the
unmerged sweep branch, not `master`: v1.62.0 is tagged locally on that branch and waits on the
sweep's finalize for the merge and the push.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260926-160448 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 122 files | [`lint.txt`](lint.txt) | +22 files (100 → 122), still 0/0 |
| tests | pass | 1747 passed, 1 skipped, 0 failed, 1748 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | +3 cases (1745 → 1748) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Totals up; every average flat |

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
offline scenarios*: `automated-tests-§3`'s first sanctioned reason, nothing to run. It is a known
hole in this repository's gate, not a pass, and the `CHANGELOG.md` block says so in its
release-gate line.

**`tests` carries one skip**, the same one as the previous run: the kit's own
`tests/_kit/test_prose.lua` is declined under `CLAUDE.md`'s `localization-§5` deviation row and
`tests/test_prose.lua` runs in its place ([`tests.txt`](tests.txt), line 1). It is counted in the
total and not in `passed`.

**`complexity` sits at the ceiling without crossing it.** Max CCN is exactly 15, and the same six
functions reach it as at the previous run ([`complexity.txt`](complexity.txt)): `lib.Catalog`
(`LibKa0s/Bus.lua:358`), `lib.GetSpellCooldown` (`LibKa0s/Compat.lua:243`), `idHelpIcon` (now
`LibKa0s/OptionsIdList.lua:459`, moved unchanged by the id peel), `liveTimers`
(`testkit/mock_record.lua:95`), `M.__fire` (`testkit/mock_record.lua:580`) and `audit`
(`testkit/test_layout_cap.lua:427`). None warns, since the threshold is `> 15`. The longest function
is now the instance closure in `LibKa0s/Options.lua` (lines 919–1261, 343 lines), and the most
parameters any function takes is still 8 (`drawRow`, `LibKa0s/OptionsWidgets.lua:268`;
`commitWrite`, `LibKa0s/Schema.lua:515`).

## What moved

- **lint**: 100 → 122 files, still 0/0 ([`lint.txt`](lint.txt)). The sweep added 25 `.lua` files;
  22 are inside the checked set and the other three are `tests/_kit/`'s copies of the new kit files,
  which `.luacheckrc` excludes. The 22: `LibKa0s/OptionsRegistry.lua`, `OptionsIds.lua`,
  `OptionsIdList.lua` and `OptionsCombat.lua`; `testkit/inventory.lua`, `prose_coverage.lua` and
  `prose_selftests.lua`; four `tests/fixture_*.lua` benches; and eleven new suites.
- **tests**: 1745 → 1748 ([`test-cases.md`](test-cases.md)). All three new cases are in
  `tests/test_kit_runner.lua` (7 → 10): kit revision 30's `None.` under an empty watch-list table, and
  revision 31's two band-table exemption cases. The rest of the inventory moved without changing
  count, and every split kept its cases whole: `test_options_widgets.lua` 227 → 53 with 174 to
  `test_options_choicegrid` (22), `_flow` (42), `_landing` (18), `_ids` (35), `_idlist` (24) and
  `_idlist_layout` (33); `test_widgets.lua` 81 → 57 with 24 to `test_widgets_reorderlist.lua`;
  `test_slash.lua` 110 → 70 with 24 to `test_slash_parse.lua` and 16 to `test_slash_disabled.lua`;
  `test_options_tabs.lua` 54 → 41 with 13 to `test_options_tabbed.lua`; `test_options_idsuggest.lua`
  40 → 29 with 11 to `test_options_idsuggest_frames.lua`.
- **complexity**: NLOC 35854 → 36218 and functions 5039 → 5050; avg NLOC 6.6, avg CCN 2.0, avg
  tokens 51.7 and max CCN 15 are all unchanged, with 0 warnings. The growth is the attach seams and
  fixture benches the peels needed, not new logic. Band 13 → 10 and over-cap 2 → 0.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua` | 1462 → 1261 | Carried forward: peeled (`LK-ATS-04`), then accepted; re-check at the next member or 1400 lines. |
| 1000–1500 (on notice) | `LibKa0s/OptionsTabs.lua` | 1493 → 1293 | Carried forward: peeled (`LK-ATS-03`), then accepted; re-check at the next member or 1400 lines. |
| 1000–1500 (on notice) | `LibKa0s/OptionsWidgets.lua` | 3852 → 1422 | **New to the band** (off the census): ruled at this run, accepted, re-check at 1450 lines or the next maker. |
| 1000–1500 (on notice) | `LibKa0s/OptionsIds.lua` | 1358 (new file) | **New**: ruled at this run, accepted, re-check at 1450 lines. |
| 1000–1500 (on notice) | `LibKa0s/OptionsIdList.lua` | 1193 (new file) | **New**: ruled at this run, accepted, re-check at 1350 lines. |
| 1000–1500 (on notice) | `LibKa0s/Perf.lua`, `LibKa0s/Widgets.lua`, `testkit/mock_base.lua`, `tests/test_options.lua`, `tests/test_schema.lua` | 1319, 1266, 1454, 1339, 1335 (unchanged) | Carried forward (#7, #36, the 1490-line trigger, #35, #38). |
| left the band | `testkit/framework.lua`, `testkit/test_prose.lua`, `tests/test_options_idsuggest.lua`, `tests/test_options_tabs.lua`, `tests/test_slash.lua`, `tests/test_widgets.lua` | 984, 750, 691, 954, 848, 861 | Peeled or split in the sweep; the runner dropped their rows. |
| > 1500 (over cap) | `LibKa0s/OptionsWidgets.lua`, `tests/test_options_widgets.lua` | 3852, 4086 → 1422, 717 | Off the census (#32, #33). |

The three new entries were the only blank Disposition cells the runner left in `RESULTS.md`; each is
ruled there, from `CLAUDE.md`'s id-peel rulings. The six band entries the previous run's Actions
named as past `automated-tests-§4`'s shelf life (`ATS-03`) are resolved: four left the band and two
carry a fresh peeled-then-accepted ruling.

## Consumer note

A consumer re-vendors both payloads whole (`libs/LibKa0s/` and `tests/_kit/`), rolls its provenance
line, and changes nothing else: no member, descriptor field, row field, kit case or `NEEDS_*` floor
moves. Every consumer takes v1.62.0 in the sweep's `<P>-ATS-RV` items.

## Actions

None in this repository.
