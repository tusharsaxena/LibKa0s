# Analysis — 20261004-143758

- **Addon:** LibKa0s 1.68.1 (release run, `--release 1.68.1`; `addonVersion` reads 1.68.0, the
  newest tag, because a library has no `.toc` and v1.68.1 is not tagged yet)
- **Verdict:** green
- **Commit:** 84cd24a (`feat/2026-10-04-dev-copilot-rename`), clean
- **Previous run:** 20261002-232612 (1.68.0, release run, at `6ffa4ca`, green; the run the `v1.68.0`
  tag was cut from)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.68.1`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and `complexity.blindFiles` is 0. **Perf was not
measured**: this repository ships no `tests/perf.lua`, so v1.68.1 was verified across **three**
suites, not four. Every figure matches the previous run, because no payload file and no test case
changed. This is the run the `v1.68.1` tag is cut from.

## Why this run exists

v1.68.1 is the library's half of the `wow-addon` → `dev-copilot` plugin rename: test kit revision 36
renames the plugin's commands in one printed `RESULTS.md` line and four comments, and the live docs
follow. An earlier `--release 1.68.1` run at `060e2df` (20261004-143527) was discarded uncommitted:
the commit after it corrected `CHANGELOG.md`'s standards-pointer sentence, which would otherwise have
put a second change between the measured tree and the tagged one. This run measures that corrected
commit.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261002-232612 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 146 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 2023 passed, 2 skipped, 0 failed, 2025 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | No |

| Metric | Value |
|---|---|
| Total NLOC | 40807 |
| Functions | 6132 |
| Avg NLOC / function | 6.7 |
| Avg CCN | 2.0 |
| Max CCN | 15 |
| Avg tokens / function | 54.4 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 6 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost. **`tests` carries two skips**, the same two as at v1.68.0's release run: the kit's own
`tests/_kit/test_prose.lua`, declined under `CLAUDE.md`'s `localization-§5` deviation row, and the
diagnostics contract's opt-out case, a declared skip in a repo that keeps the default.

## What moved

Against v1.68.0's release record, 20261002-232612: nothing. lint 146 files 0/0, tests 2025, and every
complexity figure are identical. The kit files that changed (`run-automated-tests.sh`, `test_eol.lua`,
`framework.lua`'s `Kit.VERSION` 35 → 36, mirrored in `tests/_kit/`) changed comments, one printed
string and one integer; `tests/test_kit_inventory.lua` pins revision 36 with the same case count.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua`, `testkit/mock_base.lua` | as in `RESULTS.md` | Carried forward verbatim in `RESULTS.md`; none of the six changed in this release. |
| under the band (watch) | `LibKa0s/DebugLog.lua`, `tests/test_debuglog.lua`, `testkit/framework.lua`, `tests/test_options.lua` | 999, 997, 994, 988 | Unchanged in length (`framework.lua`'s one edited line is the revision integer). |

## Actions

1. After the owner's go-ahead: tag the commit that adds this bundle `v1.68.1`, merge the branch,
   push the branch's merge and the tag.
2. Step 8 of `docs/releasing.md`: re-vendor every consumer from `v1.68.1` (the rename's Stage B).
