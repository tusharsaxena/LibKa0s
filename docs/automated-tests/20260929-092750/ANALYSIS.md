# Analysis — 20260929-092750

- **Addon:** LibKa0s 1.62.0 → 1.63.0 (release run, `--release 1.63.0`)
- **Verdict:** green
- **Commit:** 576576e (`feat/2026-09-29-smoke-and-profile`), clean
- **Previous run:** 20260926-193105 (1.62.0, not a release run, at `5dc9f5d`)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.63.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, and `complexity.warnings` is 0. **Perf was not measured**: this repository
ships no `tests/perf.lua`, so v1.63.0 was verified across **three** suites, not four. The run
measured Slash minor 17, the shared `profile` verb: one new suite of 30 cases, one more linted file,
and no movement in the band or the census. Nothing to act on in this repository.

`addonVersion` reads `1.62.0` because a library repo has no TOC and the runner falls back to the
newest tag; `release` is the field that names the version this bundle records. The run is on the
unmerged rollout branch, not `master`: v1.63.0 is tagged locally on that branch and waits on the
owner's go-ahead for the merge and the push.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260926-193105 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 123 files | [`lint.txt`](lint.txt) | +1 file (122 → 123), still 0/0 |
| tests | pass | 1777 passed, 1 skipped, 0 failed, 1778 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | +30 cases (1748 → 1778) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Totals up; every average flat |

| Metric | Value |
|---|---|
| Total NLOC | 36638 |
| Functions | 5099 |
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
(`LibKa0s/Bus.lua:358`), `lib.GetSpellCooldown` (`LibKa0s/Compat.lua:243`), `idHelpIcon`
(`LibKa0s/OptionsIdList.lua:459`), `liveTimers` (`testkit/mock_record.lua:95`), `M.__fire`
(`testkit/mock_record.lua:580`) and `audit` (`testkit/test_layout_cap.lua:427`). None warns, since
the threshold is `> 15`. The new code's densest function is `Sl:ProfileSwitch`, which lizard names
`Sl@875-908` in `LibKa0s/Slash.lua`, at CCN 11.

## What moved

- **lint**: 122 → 123 files, still 0/0 ([`lint.txt`](lint.txt)). The one new file is
  `tests/test_slash_profile.lua`.
- **tests**: 1748 → 1778 ([`test-cases.md`](test-cases.md)). All 30 new cases are in
  `tests/test_slash_profile.lua`, the profile verb's suite; no other suite's count moved.
- **complexity**: NLOC 36218 → 36638 and functions 5050 → 5099; avg NLOC 6.6, avg CCN 2.0, avg
  tokens 51.7 and max CCN 15 are all unchanged, with 0 warnings. The growth is the new suite's
  cases and the profile helpers in `LibKa0s/Slash.lua`. Band 10 and over-cap 0, both unchanged.
  `LibKa0s/Slash.lua` is 995 lines, five under the band; the next Slash minor that adds more than
  that crosses into it and owes a disposition.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua`, `LibKa0s/Perf.lua`, `LibKa0s/Widgets.lua`, `testkit/mock_base.lua`, `tests/test_options.lua`, `tests/test_schema.lua` | 1261, 1193, 1358, 1293, 1422, 1319, 1266, 1454, 1339, 1335 (unchanged) | Carried forward verbatim in `RESULTS.md`; no entry is new, so no cell is blank. |

## Consumer note

A consumer re-vendors both payloads whole (`libs/LibKa0s/` and `tests/_kit/`) and rolls its
provenance line. Nothing moves unless it wires the verb: a `profiles` descriptor field, a `profile`
COMMANDS row calling `CliProfile`, `"profile"` in its own `liveVerbs`, and `CliProfile` on its Slash
degradation stub. The kit stays at revision 31. Every consumer takes v1.63.0 in the rollout's
per-addon items.

## Actions

None in this repository.
