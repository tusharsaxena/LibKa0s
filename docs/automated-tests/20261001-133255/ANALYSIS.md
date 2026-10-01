# Analysis — 20261001-133255

- **Addon:** LibKa0s 1.66.0 (release run, `--release 1.66.0`; `addonVersion` reads 1.65.0, the last tag)
- **Verdict:** green
- **Commit:** a964c5a (`feat/2026-10-01-github-issue-pass`), clean
- **Previous run:** 20261001-122702 (1.66.0, release run, at `b68583a`, refused at the gate)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.66.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and `complexity.blindFiles` is 0. **Perf was not
measured**: this repository ships no `tests/perf.lua`, so v1.66.0 was verified across **three**
suites, not four. This is the library's first release measured through kit revision 35's sighted
complexity shadow.

This run supersedes 20261001-122702 as the v1.66.0 release record. That run was refused at the
release gate on `complexity.warnings` 2, both length-only: `lib.__AttachIdList`
(`LibKa0s/OptionsIdList.lua`, CCN 1) and `lib.__AttachWidgets` (`LibKa0s/OptionsWidgets.lua`,
CCN 6), the two files' attach closures, first listed under the sighted shadow and over lizard's
default 1000-line function length. Between the two runs the kit runner began passing lizard
`-L 1500` (`GI-LK-10R`), so the length threshold is `layout-§1`'s file cap and a warning means CCN
above 15 alone, as standard v2.74.0's `automated-tests-§3` now reads it; and `Perf.lua` and
`Slash.lua` were peeled out of the 1000–1500 band (`GI-LK-07R`, `GI-LK-03R`). The refused bundle
keeps no `ANALYSIS.md`: it was committed as the record of a refused run, and `automated-tests-§5`
forbids backfill, so this paragraph is its note.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261001-122702 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 144 files | [`lint.txt`](lint.txt) | Files 142 → 144 |
| tests | pass | 1997 passed, 2 skipped, 0 failed, 1999 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 1994 → 1999 (+5) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: warnings 2 → 0, band files 8 → 6 |

| Metric | Value |
|---|---|
| Total NLOC | 40283 |
| Functions | 6041 |
| Avg NLOC / function | 6.7 |
| Avg CCN | 2.0 |
| Max CCN | 15 |
| Avg tokens / function | 54.6 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 6 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run): the record is silent about runtime
cost. **`tests` carries two skips**, the same two as at v1.65.0's release run: the kit's own
`tests/_kit/test_prose.lua` is declined under `CLAUDE.md`'s `localization-§5` deviation row, and
the diagnostics contract's *an addon that opts out lands the report and leaves logging off* is a
declared skip in a repo that keeps the default.

## What moved

Against the refused run 20261001-122702:

- **lint**: 0/0, 142 → 144 files: the two new payload files `LibKa0s/PerfSampler.lua` and
  `LibKa0s/SlashParse.lua`.
- **tests**: 1994 → 1999 (+5): the paired-minor and load-without cases for the two peels, and the
  runner case that an 1100-line CCN-1 function records no warning.
- **complexity**: warnings 2 → 0 (the `-L 1500` threshold; neither attach closure changed), NLOC
  40125 → 40283, functions 6014 → 6041, average NLOC 6.8 → 6.7, average CCN 2.0 flat, average
  tokens 54.6 flat, max CCN 15 flat, blind files 0 flat.
- **band**: 8 → 6 files. `LibKa0s/Perf.lua` 1307 → 975 (the capture to `PerfSampler.lua`, 418) and
  `LibKa0s/Slash.lua` 1030 → 877 (the parser to `SlashParse.lua`, 195) left it.

Against v1.65.0's release record, 20261001-001312, which is the comparison a consumer reads:

- **lint**: 0/0 throughout, 133 → 144 files.
- **tests**: 1919 → 1999 (+80), across the issue pass's items; the two test-suite splits
  (`tests/test_options_render.lua`, `tests/test_schema_write.lua`) moved cases without changing
  totals.
- **complexity**: NLOC 38730 → 40283, functions 5444 → 6041, average NLOC 6.5 → 6.7, average CCN
  1.9 → 2.0, average tokens 51.4 → 54.6. That run was **unsighted** (kit revision 34): part of the
  +597 functions are ones lizard always dropped and the sighted shadow now lists, so the averages
  are not a like-for-like density comparison. The functions the sighted suite newly measured above
  CCN 15 were brought to 15 or under before this run (`GI-LK-11`); none is warned on here.
- **band**: 10 → 6 files. Out: `LibKa0s/Perf.lua` (975), `LibKa0s/Widgets.lua` (655),
  `tests/test_options.lua` (988) and `tests/test_schema.lua` (705). `LibKa0s/OptionsTabs.lua`
  1294 → 1349 and `LibKa0s/OptionsWidgets.lua` 1423 → 1444 with OptionsTabs minor 8's three fields
  and `RenderGrid`'s `parent` and `opts.gap`; neither reached its re-check line (1400; 1450).

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua`, `testkit/mock_base.lua` | as in `RESULTS.md` | Carried forward verbatim in `RESULTS.md`; no re-check trigger reached. `OptionsWidgets.lua` at 1444 is six lines from its 1450 trigger, and the next maker added fires it. |
| under the band (watch) | `LibKa0s/DebugLog.lua`, `tests/test_debuglog.lua`, `testkit/framework.lua`, `tests/test_options.lua` | 999, 997, 994, 988 | Not in the band. Named because each is within a dozen lines of it; the next addition to any of them puts it on notice, and the peel goes first. |

## Actions

1. Cut the local annotated tag `v1.66.0` on the commit that adds this bundle, its message naming
   the new minors and kit revision 35 (not pushed; the push and the branch's merge wait on the
   owner).
2. Step 8 of `docs/releasing.md`: re-vendor every consumer, one `GI-<XX>-RV` item each in the
   2026-10-01 issue pass, with the in-game smoke checks the `CHANGELOG.md` v1.66.0 block's
   *What a consumer owes* lists (drag-reorder, typed and clicked perf run, typed `set`, the host's
   own parse-refusal wording). In-game, not measurable here.
