# Analysis — 20260924-225548

- **Addon:** LibKa0s 1.56.0 → 1.57.0 (release run, `--release 1.57.0`)
- **Verdict:** green
- **Commit:** 281f26f (`feat/2026-09-23-review-audit-remediation`), clean
- **Previous run:** 20260924-040553 (1.55.0 → 1.56.0)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.57.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, and `complexity.warnings` is 0. **Perf was not measured**: this repository
ships no `tests/perf.lua`, so v1.57.0 was verified across **three** suites, not four. The run
measured one change, `LibKa0s-Launcher-1.0` minor 3 (the library-drawn status tooltip, `LK-36`),
and there are 14 more cases than at v1.56.0's release run. Nothing to act on in this repository.

`addonVersion` reads `1.56.0` because a library repo has no TOC and the runner falls back to the
newest tag; `release` is the field that names the version this bundle records.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260924-040553 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 92 files | [`lint.txt`](lint.txt) | No (92 files, 0/0) |
| tests | pass | 1661 passed, 1 skipped, 0 failed, 1662 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | +14 cases (1648 → 1662) |
| perf | skip | not measured — no `tests/perf.lua` | — | No. |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Totals up, averages flat |

| Metric | Value |
|---|---|
| Total NLOC | 33910 |
| Functions | 4766 |
| Avg NLOC / function | 6.6 |
| Avg CCN | 2.0 |
| Max CCN | 15 |
| Avg tokens / function | 51.7 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 13 |
| Files over the 1500 cap | 2 |

**`perf` was not measured.** The manifest's `skipReason` is *no tests/perf.lua — this addon ships no
offline scenarios*: `automated-tests-§3`'s first sanctioned reason, nothing to run. It is a known
hole in this repository's gate, not a pass, and the `CHANGELOG.md` block says so in its
release-notes line.

**`tests` carries one skip**, the same one as the previous run: the kit's own
`tests/_kit/test_prose.lua` is declined under `CLAUDE.md`'s `localization-§5` deviation row and
`tests/test_prose.lua` runs in its place ([`tests.txt`](tests.txt), line 1). It is counted in the
total and not in `passed`.

## What moved

- **lint**: unchanged, 0/0 in 92 files. No file was added.
- **tests**: 1648 → 1662. `tests/test_launcher.lua` gains fifteen cases and loses one: the minor-2
  case pinning the `onTooltipShow` pass-through is replaced, because minor 3 retires that contract.
  One of the fifteen is a 36-cell matrix over enabled/disabled, rung (a)/(b) or (c), lock
  absent/Yes/No and test mode absent/On/Off ([`test-cases.md`](test-cases.md)).
- **complexity**: NLOC 33581 → 33910 and functions 4706 → 4766; avg NLOC 6.6 and avg CCN 2.0 do not
  move, avg tokens 51.8 → 51.7, max CCN stays 15 with 0 warnings. The growth is the tooltip's six
  small closures in `LibKa0s/Launcher.lua` (now 443 lines) and the new cases in
  `tests/test_launcher.lua` (863 lines). Band and over-cap counts are unchanged (13 and 2).

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None warned on at this run.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | the thirteen files in `RESULTS.md` | unchanged | Carried forward; no file entered or left the band and none moved. |
| > 1500 (over cap) | `LibKa0s/OptionsWidgets.lua`, `tests/test_options_widgets.lua` | 3852, 4086 | Carried forward (census rows #32, #33). |

No entry is new, so no Disposition cell in `RESULTS.md` is blank: the runner carried every one
forward verbatim, and this release touches none of the files they name.

## Consumer note for the M5 re-vendors

This payload changes what every host's launcher shows on hover without the host adopting anything,
so three consumer suites that call the object's `OnTooltipShow` will see the library's block
around their own lines: BankLedger `tests/test_launcher.lua`, LootHistory `tests/test_launcher.lua`
and MultiMeters `tests/test_launchersetup.lua` (a read-only grep of each working tree, 2026-09-24).
Their assertions on line positions or counts move with each M5 item, which also cuts the host's hook
down to its own lines (anti-pattern #89). The other eight hosts pass no hook and no test of theirs
calls it.

## Actions

None in this repository. The re-vendors and host adoptions are the M5 items, one per consumer.
