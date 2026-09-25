# Analysis — 20260926-034006

- **Addon:** LibKa0s 1.59.0 → 1.60.0 (release run, `--release 1.60.0`)
- **Verdict:** green
- **Commit:** 2fdca6e (`master`), clean
- **Previous run:** 20260925-170346 (1.58.0 → 1.59.0)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.60.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, and `complexity.warnings` is 0. **Perf was not measured**: this repository
ships no `tests/perf.lua`, so v1.60.0 was verified across **three** suites, not four. The run
measured the library's half of the Ka0s WoW Addon Standard v2.68.0's diagnostics dump
(`debug-logging-§14`): `DebugLog.lua` minor 14 and the new `DebugLogDiagnostics.lua` minor 1
(`LibKa0s-DebugLog-1.0` 14.1), `Slash.lua` minor 16, and kit revision 27's shared diagnostics
contract. There are 53 more cases than at v1.59.0's release run. Nothing to act on in this
repository.

`addonVersion` reads `1.59.0` because a library repo has no TOC and the runner falls back to the
newest tag; `release` is the field that names the version this bundle records.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260925-170346 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 98 files | [`lint.txt`](lint.txt) | +5 files (93 → 98), still 0/0 |
| tests | pass | 1729 passed, 1 skipped, 0 failed, 1730 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | +53 cases (1677 → 1730) |
| perf | skip | not measured — no `tests/perf.lua` | — | No. |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Totals up, avg NLOC and avg tokens down, avg CCN flat |

| Metric | Value |
|---|---|
| Total NLOC | 35354 |
| Functions | 4975 |
| Avg NLOC / function | 6.5 |
| Avg CCN | 2.0 |
| Max CCN | 15 |
| Avg tokens / function | 51.6 |
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

- **lint**: 93 → 98 files, still 0/0 ([`lint.txt`](lint.txt)). The five new files are all inside
  the checked set: `LibKa0s/DebugLogDiagnostics.lua`, `testkit/test_diagnostics_contract.lua`,
  `tests/fixture_diagnostics.lua`, `tests/test_debuglog_copytiming.lua` and
  `tests/test_debuglog_diagnostics.lua`. The vendored copy of the contract under `tests/_kit/` is
  excluded by `.luacheckrc`, as the rest of `tests/_kit/` is.
- **tests**: 1677 → 1730 ([`test-cases.md`](test-cases.md)). Three new suites carry 52 of the 53:
  `tests/test_debuglog_diagnostics.lua` (35, the report helper), `tests/test_debuglog_copytiming.lua`
  (10, the copy-timing switch and the 3000-line buffer) and the kit's
  `tests/_kit/test_diagnostics_contract.lua` (7, run against this repo's fixture dispatcher).
  `tests/test_slash.lua` gains one (109 → 110), a disabled host running `diagnostics` through the
  default live set, and renames its live-verb case from twelve reserved verbs to thirteen. Every
  other suite's count is unchanged; `tests/test_debuglog.lua` rewrites its cap and slack cases on
  `lib.MAX_BUFFER` and `lib.BUFFER_SLACK` without changing its count.
- **complexity**: NLOC 34348 → 35354 and functions 4820 → 4975; avg NLOC 6.6 → 6.5 and avg tokens
  51.9 → 51.6, avg CCN stays 2.0, max CCN stays 15 with 0 warnings. The growth is the new
  `LibKa0s/DebugLogDiagnostics.lua` and its suites, none of which is in the band. Band and over-cap
  counts are unchanged (13 and 2).

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None warned on at this run.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | the thirteen files in `RESULTS.md` | two moved | Carried forward; no file entered or left the band. |
| 1000–1500 (on notice) | `tests/test_slash.lua` | 1327 → 1339 | Carried forward. Its re-check trigger (a Slash minor that adds parser cases, or 1400 lines) has not fired: minor 16 adds one live-verb case and no parser case. |
| 1000–1500 (on notice) | `testkit/framework.lua` | 1385 → 1386 | Carried forward. One line, the `KIT_GATE_RULE` row for the new contract suite, under its trigger of 60 lines in one revision or 1450. |
| > 1500 (over cap) | `LibKa0s/OptionsWidgets.lua`, `tests/test_options_widgets.lua` | 3852, 4086 | Carried forward (census rows #32, #33). |

No entry is new, so no Disposition cell in `RESULTS.md` is blank: the runner carried every one
forward verbatim. The two cells above whose LOC moved still name their older figures in prose
(1327 and 1385); the cells are carried, not re-ruled, at this run, and `CLAUDE.md` already records
`tests/test_slash.lua` at 1339.

## Consumer note

Every consumer owes the v1.60.0 re-vendor, which the `CHANGELOG.md` block's consumer section lists:
the copy and kit revision 27, the provenance line, `RunDiagnostics`, `BuildDiagnostics` and
`DebugVerb` on the DebugLog degradation stub, `diagnostics` in any literal or degraded live-verb
list, and any suite literal of 1500 re-pinned on `lib.MAX_BUFFER`. Those are the diagnostics
rollout's M3 items, one per consumer.

## Actions

None in this repository. The consumer re-vendors are the rollout's M3.
