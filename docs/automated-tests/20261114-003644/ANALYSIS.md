# Analysis — 20261114-003644

- **Addon:** LibKa0s 1.97.0 (release run, `--release 1.98.0`; `addonVersion` is the newest tag the
  runner's `git describe` found, and `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `17c1497` (`feat/2026-11-13-callout-schema`), clean: the release's last code commit,
  which keeps the SchemaRows case under CCN 15, on top of `1f66f40`, which dates the `v1.98.0`
  heading in `CHANGELOG.md` and closes the plan's L12 row
  (`docs/superpowers/plans/2026-11-13-callout.md`). The release's record (this bundle, its
  `RESULTS.md` row and the changelog's release lines) follows it as one commit, and the tag is cut on
  that commit. The battery ran in a clean clone of the branch, named `LibKa0s`, because the runner
  needs a `.git` directory and the worktree's `.git` is a file.
- **Previous run:** [`20261113-233957`](../20261113-233957/) (at `f12a0b3`), v1.97.0's release run.
  A first `--release 1.98.0` run on a clean clone of `1f66f40` (`20261114-003303`, not kept) read
  green but measured one function at CCN 16, the SchemaRows case in `tests/test_callout_schema.lua`
  after the branch review's color row `get` added a branch to it. The release gate allows none over
  15, so the case's stored-row checks moved to a helper (`17c1497`) and the battery ran again; that
  bundle was discarded with its clone and is not in the record.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.98.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.98.0 was verified
across **three** suites, not four. One file enters the 1000–1500 band, `LibKa0s/Callout.lua`, on
notice and unruled (*Actions*); that is not a gate condition.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261113-233957 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 334 files | [`lint.txt`](lint.txt) | Yes: 333 -> 334 files |
| tests | pass | 4484 passed, 3 skipped, 0 failed, 4487 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4462 -> 4487 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | Yes: NLOC, function count, band files |

| Metric | Value |
|---|---|
| Total NLOC | 101466 |
| Functions | 14482 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.3 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 14 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

Against v1.97.0's run, v1.98.0:

- **Callout minor 2** (the host's write route, `d.path` / `d.set` / `d.colorEncode`, and the leaf
  keys `texts.<KEY>`, `muted.<KEY>`, `colors.<kind>`) and **CalloutSettings minor 3** (`SchemaRows`
  and the Options build on the route): Callout key 2.3. No other minor, no `NEEDS_*` floor and no
  kit revision moves. The branch review changed both files once more inside the unreleased minors
  (`967898a`): a whole `texts` / `muted` write is split into leaves on the route, each color row
  reads the stored color in the host's shape, and the text to speech voice row labels its default.
- Lint: 333 -> 334 files, the new `tests/test_callout_schema.lua`. Tests: 4462 -> 4487, its 25
  cases. The three skips are still declared skips, not passes.
- Complexity: NLOC 100849 -> 101466 and functions 14401 -> 14482; the averages and the max did not
  move (avg tokens 60.2 -> 60.3).

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Callout.lua` | 1145 | **New to the band**: 977 at minor 1 -> 1145 with the write route, the leaf keys and the review's whole-table split and color reader. On notice and unruled in `CLAUDE.md`'s band census, its seam named (the write-route section, or the sound section, to a secondary paired on the shell); a peel is a new shipped file and so a release, and the ruling is the lead's (*Actions*) |
| 1000–1500 (on notice) | the other thirteen files of the previous run | see [`../RESULTS.md`](../RESULTS.md) | Carried forward unchanged |

Fourteen, nothing over 1500. The standing triggers the previous run named (`tests/test_media.lua`'s
"next face added to `FONTS`", `LibKa0s/Skin.lua` at 1121, `tests/test_launcher.lua` at 1235) still
stand, unchanged.

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-11-14, by hand
- **Files reviewed:** none needed
- **Commits since the previous release touching them:** 0 that move a Sim, Widgets or `W.TestStrip` minor
- **Note:** v1.98.0 moves only Callout 2 and CalloutSettings 3, so no host's scenarios or test-mode
  strips are affected.

## Actions

1. Cut the tag `v1.98.0` on the commit that adds this bundle, and merge the branch to master (the
   run's orchestrator's, on the owner's go-ahead, plan row L12).
2. **Lead ruling, `LibKa0s/Callout.lua` band row:** new to the band at 1145, on notice. Peel the
   write-route or sound section to a paired secondary at a later release, or accept it with a
   trigger.
3. **Owner ruling, Callout register row:** its one-release trigger fired at v1.97.0 and is still
   pending; Combat Trail's adoption (plan rows C1–C4) is the second release's consumer, not a second
   consumer.
4. Step 8: Ka0s Combat Trail re-vendors this payload and takes the write route in the same change:
   it registers `SchemaRows("callout.")`, seeds its `profile.callout` AceDB defaults from those
   rows (not `DEFAULTS`), lists `callout.point` in its Schema's `writeThrough`, and passes `path`,
   `set` and its Options `colorEncode` to `New`. A host's Callout instance stub gains `SchemaRows`.
5. Rule on the standing band triggers above before the next tag (carried from the previous runs).
