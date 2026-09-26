# Analysis — 20260926-160448

- **Addon:** LibKa0s 1.61.0 (not a release run: `release` is `null`)
- **Verdict:** green
- **Commit:** cf38896 (`master`), clean
- **Previous run:** 20260926-121411 (the 1.60.0 → 1.61.0 release run, at `7cbe02c`)

## Headline

Green on the three suites that ran: lint 0/0 over 100 files, 1744 of 1745 cases passed with the
one declared skip, and no function above CCN 15 ([`manifest.json`](manifest.json)). **Perf was not
measured**, because this repository ships no `tests/perf.lua`. Nothing moved since the v1.61.0
release run. That is expected: `cf38896` is the `--no-ff` merge of the branch that release run
measured, so the tree is the same. The one thing to act on is the watch list: six band entries have
now carried an *Accepted* disposition through six consecutive release runs (see Actions).

## Suites

| Suite | Status | Result | Artifact | Moved since 20260926-121411 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 100 files | [`lint.txt`](lint.txt) | No (100 files, 0/0) |
| tests | pass | 1744 passed, 1 skipped, 0 failed, 1745 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No. The inventory is byte-identical to the previous bundle's |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | No. Every footer field is identical |

| Metric | Value |
|---|---|
| Total NLOC | 35854 |
| Functions | 5039 |
| Avg NLOC / function | 6.6 |
| Avg CCN | 2.0 |
| Max CCN | 15 |
| Avg tokens / function | 51.7 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 13 |
| Files over the 1500 cap | 2 |

**`perf` was not measured.** The manifest's `skipReason` is *no tests/perf.lua — this addon ships no
offline scenarios*. That is `automated-tests-§3`'s first sanctioned reason, *nothing to run*. It is a
standing hole in this repository's record, not a pass, and at a release gate it reads as NOT
EVALUATED.

**`tests` carries one skip**, the same one as the previous run. The kit's own
`tests/_kit/test_prose.lua` is declined under `CLAUDE.md`'s `localization-§5` deviation row, and
`tests/test_prose.lua` runs in its place ([`tests.txt`](tests.txt), line 1). It counts toward the
total and not toward `passed`.

**`complexity` sits at the ceiling without crossing it.** Max CCN is exactly 15, and six functions
reach it ([`complexity.txt`](complexity.txt)): `lib.Catalog` (`LibKa0s/Bus.lua:358`),
`lib.GetSpellCooldown` (`LibKa0s/Compat.lua:243`), `idHelpIcon` (`LibKa0s/OptionsWidgets.lua:2950`),
`liveTimers` (`testkit/mock_record.lua:95`), `M.__fire` (`testkit/mock_record.lua:580`) and `audit`
(`testkit/test_layout_cap.lua:427`). These are the same six as the previous run. They do not warn,
since the threshold is `> 15`, but one more decision in any of them would put a warned function in
the table and block the next tag. The tool's other thresholds (length > 1000, parameter count > 100)
are also not exceeded. The longest function is `tracedSlash` (`tests/test_slash.lua:734`, 556 lines)
and the most parameters any function takes is 8 (`drawRow`, `LibKa0s/OptionsWidgets.lua:260`;
`commitWrite`, `LibKa0s/Schema.lua:515`).

## What moved

- **lint**: nothing moved. 100 files, 0/0 ([`lint.txt`](lint.txt)). Scope is everything except
  `tests/_kit/`.
- **tests**: nothing moved. 1745 cases, and [`test-cases.md`](test-cases.md) is identical to
  `20260926-121411/test-cases.md`.
- **perf**: still skip.
- **complexity**: nothing moved. NLOC 35854, 5039 functions, avg NLOC 6.6, avg CCN 2.0, avg tokens
  51.7, max CCN 15, 0 warnings, 13 band files and 2 over the cap. All of these match the previous row.
  The same six functions sit at CCN 15.

## Complexity watch list

**Functions the complexity tool warned on:**

| Function | CCN | Location | Disposition |
|---|---|---|---|
| None. | | | |

**Files by `layout-§1` band** (every Disposition is carried forward unchanged in `RESULTS.md`, and
none is blank, so this run owes no new ruling):

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua` | 1462 | Accepted (re-ruled 2026-09-24). **Past shelf life**, see Actions |
| 1000–1500 (on notice) | `LibKa0s/OptionsTabs.lua` | 1493 | Accepted (re-ruled 2026-09-24). **Past shelf life**, see Actions |
| 1000–1500 (on notice) | `LibKa0s/Perf.lua` | 1319 | Tracked as #7 |
| 1000–1500 (on notice) | `LibKa0s/Widgets.lua` | 1266 | Tracked as #36 |
| 1000–1500 (on notice) | `testkit/framework.lua` | 1386 | Accepted 2026-09-24 (`LK-33`). **Past shelf life**, see Actions |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1454 | On notice, with a re-check trigger at 1490 |
| 1000–1500 (on notice) | `testkit/test_prose.lua` | 1486 | Tracked as #39 |
| 1000–1500 (on notice) | `tests/test_options.lua` | 1339 | Tracked as #35 |
| 1000–1500 (on notice) | `tests/test_options_idsuggest.lua` | 1002 | Accepted 2026-09-24 (`LK-33`). **Past shelf life**, see Actions |
| 1000–1500 (on notice) | `tests/test_options_tabs.lua` | 1218 | Accepted 2026-09-24 (`LK-33`). **Past shelf life**, see Actions |
| 1000–1500 (on notice) | `tests/test_schema.lua` | 1335 | Tracked as #38 |
| 1000–1500 (on notice) | `tests/test_slash.lua` | 1339 | Accepted (re-ruled 2026-09-24). **Past shelf life**, see Actions |
| 1000–1500 (on notice) | `tests/test_widgets.lua` | 1493 | Tracked as #37 |
| > 1500 (over cap) | `LibKa0s/OptionsWidgets.lua` | 3852 | See the `CLAUDE.md` census row (#32) |
| > 1500 (over cap) | `tests/test_options_widgets.lua` | 4086 | See the `CLAUDE.md` census row (#33) |

The two closest to the cap are `LibKa0s/OptionsTabs.lua` and `tests/test_widgets.lua`, both at 1493
with 7 lines of room. `OptionsTabs.lua`'s own re-check trigger is 1495 lines.

## Actions

1. **Six Accepted band dispositions are past their shelf life** (`automated-tests-§4`,
   anti-pattern #53). The entries are `LibKa0s/Options.lua`, `LibKa0s/OptionsTabs.lua`,
   `testkit/framework.lua`, `tests/test_options_idsuggest.lua`, `tests/test_options_tabs.lua` and
   `tests/test_slash.lua`. Each was ruled *Accepted* at the v1.56.0 release run (`446b7c1`, and
   `a77211f` for `test_slash.lua`) and carried verbatim through the v1.57.0, v1.58.0, v1.59.0,
   v1.60.0 and v1.61.0 release runs (`aa37bc9`, `34931c9`, `53c141a`, `bed0eb1`, `c6183bd`), six in
   all. Each now needs either a fix or a tracked issue with an owner, as `LibKa0s/Widgets.lua` and
   `tests/test_widgets.lua` already have (#36, #37). This is new here: no deviation ID or issue
   covers it.
2. **Two carried Disposition cells contradict the measured LOC.** `LibKa0s/OptionsTabs.lua`'s cell
   says "with eleven lines of room", but at 1493 it has 7 (the `CLAUDE.md` band paragraph also says
   seven). `tests/test_slash.lua`'s cell says "1327 now, 173 lines clear of the cap", but this run
   measures 1339, which leaves 161. The Disposition is the authored cell, so the owner should correct
   both when they re-rule under action 1. This record does not change them.
