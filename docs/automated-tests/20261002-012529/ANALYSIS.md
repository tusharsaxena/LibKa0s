# Analysis — 20261002-012529

- **Addon:** LibKa0s 1.67.0 (release run, `--release 1.67.0`; `addonVersion` reads 1.66.0, the last tag)
- **Verdict:** green
- **Commit:** 7e07c83 (`feat/2026-10-02-libka0s-census-adoption`), clean
- **Previous run:** 20261001-133255 (1.66.0, release run, at `a964c5a`, green)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.67.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and `complexity.blindFiles` is 0. **Perf was not
measured**: this repository ships no `tests/perf.lua`, so v1.67.0 was verified across **three**
suites, not four.

A small release. Three minors move (Core 10, Options 28, OptionsIdList 3), no file is added, and the
kit stays at revision 35, so the lint file count and the shape of every suite are unchanged from
v1.66.0. What moved is sixteen new cases and the code they cover.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261001-133255 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 144 files | [`lint.txt`](lint.txt) | No (144 files, 0/0) |
| tests | pass | 2013 passed, 2 skipped, 0 failed, 2015 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 1999 → 2015 (+16) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Totals only; warnings 0, band 6, blind 0 all flat |

| Metric | Value |
|---|---|
| Total NLOC | 40568 |
| Functions | 6095 |
| Avg NLOC / function | 6.7 |
| Avg CCN | 2.0 |
| Max CCN | 15 |
| Avg tokens / function | 54.5 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 6 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost. **`tests` carries two skips**, the same two as at v1.66.0's release run: the kit's own
`tests/_kit/test_prose.lua` is declined under `CLAUDE.md`'s `localization-§5` deviation row, and
the diagnostics contract's *an addon that opts out lands the report and leaves logging off* is a
declared skip in a repo that keeps the default.

## What moved

Against v1.66.0's release record, 20261001-133255:

- **lint**: 0/0 in 144 files, unchanged. No payload file was added.
- **tests**: 1999 → 2015 (+16). Ten in `tests/test_core_resize.lua` for Core minor 10's
  `canResize`, `onResizeStop` and `gripParent` (LibKa0s#41), six in
  `tests/test_options_idlist_layout.lua` for OptionsIdList minor 3's loaded-addon rung (LibKa0s#42).
- **complexity**: NLOC 40283 → 40568 (+285), functions 6041 → 6095 (+54), average NLOC 6.7 flat,
  average CCN 2.0 flat, average tokens 54.6 → 54.5, max CCN 15 flat, blind files 0 flat. Both
  changed payload files put their new logic in helpers to stay at or under CCN 15:
  `MakeResizable`'s option resolution in `callbacksOf` (`LibKa0s/Core.lua`), and the help-art
  ladder in `hostLoaded`, `vouchedHost` and `resolveHelpDefault` (`LibKa0s/OptionsIdList.lua`).
- **band**: 6 files, the same six. `LibKa0s/OptionsIdList.lua` 1197 → 1246 (+49, the loaded-addon
  rung and its debug line), 104 lines short of its 1350 re-check trigger. `LibKa0s/Options.lua`
  1282 → 1288 (+6, the Options minor 28 docblock); its trigger is the next member added or 1400
  lines, and minor 28 adds no member, so it is not reached. `LibKa0s/Core.lua` went 755 → 789,
  well clear of the band.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua`, `testkit/mock_base.lua` | as in `RESULTS.md` | Carried forward verbatim in `RESULTS.md`. No re-check trigger was reached (see *What moved*). `OptionsWidgets.lua` is unchanged at 1444, six lines from its 1450 trigger. |
| under the band (watch) | `LibKa0s/DebugLog.lua`, `tests/test_debuglog.lua`, `testkit/framework.lua`, `tests/test_options.lua` | 999, 997, 994, 988 | Not in the band and unchanged since v1.66.0. Each is within a dozen lines of it, so the next addition to any of them puts it on notice, and the peel goes first. |

## Actions

1. Cut the local annotated tag `v1.67.0` on the commit that adds this bundle (not pushed; the
   push and the branch's merge wait on the owner).
2. Step 8 of `docs/releasing.md`: re-vendor every consumer, one `CA-<XX>-RV` item each in the
   2026-10-02 census adoption. The hosts' adoptions of `MakeResizable` (LootHistory, BankLedger,
   MultiMeters) and of the descriptor's `addonName` (all eleven) are their own items there, with
   the in-game smoke checks that bundle's `03_SMOKE_TESTS.md` lists. Those checks are in-game and
   cannot be measured here.
