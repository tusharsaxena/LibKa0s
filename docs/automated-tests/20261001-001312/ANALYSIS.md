# Analysis — 20261001-001312

- **Addon:** LibKa0s 1.65.0 (release run, `--release 1.65.0`)
- **Verdict:** green
- **Commit:** 0b1dfeb (`feat/2026-09-30-libka0s-debug-gaps`), clean
- **Previous run:** 20261001-000959 (1.65.0, release run, at `efd520a`)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.65.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, and `complexity.warnings` is 0. **Perf was not measured**: this repository
ships no `tests/perf.lua`, so v1.65.0 was verified across **three** suites, not four.

This run supersedes 20261001-000959 as the v1.65.0 release record. That run was refused at the
release gate: its `manifest.json` records `complexity.warnings` 1 and max CCN 16, one function over
CCN 15, `Sl:CliSet` in `LibKa0s/Slash.lua`, where gap G1's parse-refusal line tested the reason
twice. `0b1dfeb` reads the reason once into a local, with the same semantics, and nothing else
changed. The refused bundle is kept as committed and carries **no `ANALYSIS.md`**: it was committed
with the fix before its write-up, and `automated-tests-§5` forbids backfill, so this paragraph is its
note.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261001-000959 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 133 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 1917 passed, 2 skipped, 0 failed, 1919 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: max CCN 16 → 15, warnings 1 → 0 |

| Metric | Value |
|---|---|
| Total NLOC | 38730 |
| Functions | 5444 |
| Avg NLOC / function | 6.5 |
| Avg CCN | 1.9 |
| Max CCN | 15 |
| Avg tokens / function | 51.4 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 10 |
| Files over the 1500 cap | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). **`tests` carries two skips**, both
the same as at v1.64.0's release run: the kit's own `tests/_kit/test_prose.lua` is declined under
`CLAUDE.md`'s `localization-§5` deviation row, and kit revision 34's *an addon that opts out lands
the report and leaves logging off* is a declared skip in a repo that keeps the default.

## What moved

Against the refused run 20261001-000959, one thing: `Sl:CliSet` goes from CCN 16 to 15 and NLOC
38729 → 38730 (the one local). Lint, the case count and every average are unchanged.

Against v1.64.0's release record, 20260930-190933, which is the comparison a consumer reads:

- **lint**: 0/0 throughout, 127 → 133 files: the new payload file `LibKa0s/DebugLogGates.lua` and
  five new suites.
- **tests**: 1834 → 1919 (+85), all in the five new suites, one per gap: `tests/test_slash_debug.lua`
  (14, G1), `tests/test_debuglog_gates.lua` (20, G2), `tests/test_options_combat_debug.lua` (16, G3),
  `tests/test_atenable.lua` (21, G4) and `tests/test_lifecycle_debug.lua` (14, G5). Each includes
  the silent default (no `debug` passed, nothing written). `tests/test_launcher.lua` stays at 45
  cases, with its expectations re-pinned for the `debugAtEnable` routing.
- **complexity**: NLOC 37575 → 38730 and functions 5254 → 5444; average NLOC 6.6 → 6.5, average
  CCN 1.9 flat, average tokens 51.6 → 51.4. The library grew and did not get denser. Max CCN 15,
  none warned on.
- **band**: still 10 files, 0 over the cap. Five band files moved by a few lines each with the
  combat-refusal wiring (G3): `LibKa0s/Options.lua` 1261 → 1282, `LibKa0s/OptionsWidgets.lua`
  1422 → 1423, `LibKa0s/OptionsIds.lua` 1358 → 1359, `LibKa0s/OptionsIdList.lua` 1193 → 1197,
  `LibKa0s/OptionsTabs.lua` 1293 → 1294. None reached its re-check line; `Options.lua`'s other
  trigger, *the next member added*, fired on the private `O.__combatRefused` and is re-ruled below.
  `LibKa0s/DebugLog.lua` (998) and `LibKa0s/Slash.lua` (999) stay under the band: the new DebugLog
  surface went to `DebugLogGates.lua` (J2 of the run's plan) rather than into the 999-line file.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua` | 1282 | **Re-ruled 2026-10-01: accepted.** The member-added trigger fired on the private `O.__combatRefused` (G3's refusal line), which sits with the instance's combat edges that re-arm it, not in the reset walk; the seam and the trigger stand, counted from this release (`CLAUDE.md` § *The band's terminal states*). |
| 1000–1500 (on notice) | `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua`, `LibKa0s/Perf.lua`, `LibKa0s/Widgets.lua`, `testkit/mock_base.lua`, `tests/test_options.lua`, `tests/test_schema.lua` | as in `RESULTS.md` | Carried forward verbatim in `RESULTS.md`; no re-check trigger reached. |
| under the band (watch) | `LibKa0s/Slash.lua`, `LibKa0s/DebugLog.lua`, `tests/test_debuglog.lua` | 999, 998, 997 | Not in the band. Named because each is within three lines of it; the next addition to any of them puts it on notice, and the peel goes first. |

## Consumer note

The `CHANGELOG.md` v1.65.0 block, *What a consumer owes*, is the list the adoption items work
from: the whole-folder copy and the provenance line; `debug` passed to Slash, Lifecycle, Options
and Launcher; the host's duplicate lines deleted; the hand-rolled change gates replaced by
`DebugOnce` / `DebugChanged` (or re-armed through `onClear`); state lines at enable routed through
`DebugAtEnable`, Launcher's through `debugAtEnable`; and **four members on a DebugLog degradation
stub** under a by-name `assertSurfaceParity` case. The kit stays at revision 34, so no kit case
moves in a consumer.

## Actions

1. Cut the local annotated tag `v1.65.0` on the commit that adds this bundle, its message naming
   the new minors and kit revision 34 (not pushed; the push and the branch's merge wait on the
   owner).
2. In-game, not measurable here: with each consumer's adoption item in, a Slash refusal
   (`/<prefix> set <bad path>`, a feature verb while disabled), a Lifecycle edge (disable and
   enable), a combat-locked settings write and, after `/reload` with logging off, turning logging
   on to see the Launcher's dependency lines, each land one line in the console.
