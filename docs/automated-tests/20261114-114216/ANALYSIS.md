# Analysis — 20261114-114216

- **Addon:** LibKa0s 1.98.0 (release run, `--release 1.99.0`; `addonVersion` is the newest tag the
  runner's `git describe` found, and `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `179f96d` (`feat/2026-11-14-callout-layout`), clean: the release's first commit, which
  dates the `v1.99.0` heading in `CHANGELOG.md`, moves the `docs/releasing.md` and README pointers to
  v1.99.0 and closes the plan's L14 row (`docs/superpowers/plans/2026-11-13-callout.md`), on top of
  `394da9a`, the branch review's fixes. The release's record (this bundle, its `RESULTS.md` row and
  the changelog's release lines) follows it as one commit, and the tag is cut on that commit. The
  battery ran in a clean clone of the branch, named `LibKa0s`, because the runner needs a `.git`
  directory and the worktree's `.git` is a file.
- **Previous run:** [`20261114-003644`](../20261114-003644/) (at `17c1497`), v1.98.0's release run.
  An earlier `--release 1.99.0` run of the same commit in a clone named `rel` (`20261114-114058`,
  not kept) read the same figures; it was discarded because its manifest named the addon `rel`, the
  clone's folder, rather than `LibKa0s`.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.99.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.99.0 was verified
across **three** suites, not four. The band count holds at fourteen; `LibKa0s/Callout.lua` grows
inside it to 1277, still on notice and unruled (*Actions*); that is not a gate condition.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261114-003644 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 337 files | [`lint.txt`](lint.txt) | Yes: 334 -> 337 files |
| tests | pass | 4529 passed, 3 skipped, 0 failed, 4532 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4487 -> 4532 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | Yes: NLOC, function count, averages |

| Metric | Value |
|---|---|
| Total NLOC | 102596 |
| Functions | 14620 |
| Avg NLOC / function | 6.9 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.5 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 14 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

Against v1.98.0's run, v1.99.0:

- **Callout minor 3** (the glow as AuraMaster's: an on/off `glow` with intensity, thickness, offsets
  and its color choices; `GLOW_LEGACY` and `MigrateGlow`; eight voice packs with the arena announcer
  the default) and **CalloutSettings minor 4** (`SettingsTab`, `layout = "side"`, `texts = false`,
  "Countdown 10 to 1", the Glow rows): Callout key 3.4. **OptionsNav minor 7** (`O.SideTabs`): the
  Options key moves one place. No other minor, no `NEEDS_*` floor and no kit revision moves (56).
  The payload gains six voice-pack folders under `media/sounds/callout/`; no Lua file is added.
- The branch review changed both moved files once more inside the unreleased minors (`394da9a`): a
  `glow` write over a stored old choice keeps the intensity and thickness it implied, and a freed
  side rail goes back to client art before another instance takes it, each with a regression case.
- Lint: 334 -> 337 files, the new `tests/test_options_sidetabs.lua`, `tests/test_callout_layout.lua`
  and `tests/test_callout_glow.lua`. Tests: 4487 -> 4532. The three skips are still declared skips,
  not passes.
- Complexity: NLOC 101466 -> 102596 and functions 14482 -> 14620; avg NLOC 6.8 -> 6.9 and avg
  tokens 60.3 -> 60.5; avg CCN and the max did not move.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Callout.lua` | 1277 | **Grown in the band**: 1145 at v1.98.0 -> 1235 with L15's glow, 1260 with L16's pack rows and `Set`'s old glow choice, 1277 with the review's `keepLegacyLook`; under the ~1300 split point `CLAUDE.md`'s census names. On notice and unruled, its seam named (the write-route section, or the sound section, to a secondary paired on the shell); a peel is a new shipped file and so a release, and the ruling is the lead's (*Actions*) |
| 1000–1500 (on notice) | the other thirteen files of the previous run | see [`../RESULTS.md`](../RESULTS.md) | Carried forward unchanged |

Fourteen, nothing over 1500. The standing triggers the previous runs named still stand, unchanged.

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-11-14, by hand
- **Files reviewed:** none needed
- **Commits since the previous release touching them:** 0 that move a Sim, Widgets or `W.TestStrip` minor
- **Note:** v1.99.0 moves only Callout 3, CalloutSettings 4 and OptionsNav 7, so no host's scenarios
  or test-mode strips are affected.

## Actions

1. Cut the tag `v1.99.0` on the commit that adds this bundle, and merge the branch to master (the
   run's orchestrator's, on the owner's go-ahead, plan row L14).
2. **Lead ruling, `LibKa0s/Callout.lua` band row:** 1277, near the ~1300 split point. The next
   Callout change should peel the write-route or sound section to a paired secondary, or the lead
   accepts it with a trigger.
3. Step 8: Ka0s Combat Trail re-vendors this payload. Its Callout instance stub gains `SettingsTab`
   and `GetGlowColor`, an Options instance stub `SideTabs`; a suite comparing `Get("glow")` to a
   string compares to the boolean; it passes `d.packs` (or ships `callout/male-arena-john`) so the
   new default voice plays; a host carrying `female-bella` credits SIWIS and Koniwa `tnc`.
4. Rule on the standing band triggers before the next tag (carried from the previous runs).
