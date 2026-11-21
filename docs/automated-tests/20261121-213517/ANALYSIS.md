# Analysis — 20261121-213517

- **Addon:** LibKa0s 1.109.0 (release run, `--release 1.109.0`; `addonVersion` reads 1.109.0, the local
  tag the runner's `git describe` found on this commit's parent, and `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `e2f7544` (`feat/2026-11-21-sync-followups`), clean: the whole v1.109.0 release but its
  own record. Since the previous run (`245dc3c`) the tree gained that run's record (`1a330ff`), the
  hand-read census rows (`ccab099`, `docs/api/CONSUMERS.md` and its inputs only) and the citation fix
  (`e2f7544`): `Compat.lua`'s character-identity comment and `Sim.lua`'s sample-character comment now
  cite the standard's forever-quirks-§4, where v2.117.0 moved the WoW Forever names entry out of
  client-quirks-§5. Comment-only, so `Compat.lua` moves to minor 5 (key 5) and `Sim.lua` to minor 4
  (key 4.3.11.4), each with its document and members manifest. The record (this bundle, its
  `RESULTS.md` row and the changelog's release-gate and re-look lines) follows as one commit, and the
  local tag moves onto it.
- **Previous run:** [`20261121-205404`](../20261121-205404/) (at `245dc3c`), superseded by this one for the tag.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.109.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.109.0 was verified
across **three** suites, not four.

Every figure equals the previous run's: the only payload change is two comment lines and two minor
constants, which move no NLOC, function or CCN.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261121-205404 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 382 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 5076 passed, 3 skipped, 0 failed, 5079 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No (two cases renamed by their re-pins) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | No |

| Metric | Value |
|---|---|
| Total NLOC | 113699 |
| Functions | 16329 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.8 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 11 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

The suite was also run under `KA0S_KIT_CLIENT=forever` on the same tree, outside the runner: 5076
passed, 0 failed, 3 skipped, 5079 total.

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

- **Payload:** two files changed, comment-only. `Compat.lua` 4 -> 5 and `Sim.lua` 3 -> 4, each a
  one-line citation and its minor constant. No kit file moved (revision 59).
- **Contract changes:** none. Two more majors move key, Compat 5 and Sim 4.3.11.4, each with its
  document (the superseded 4 and 3.3.11.4 documents gain their *Moving to* sections) and a members
  manifest naming the same members as the one before. No `NEEDS_*` floor rises.
- **Lint:** 382 files, unchanged.
- **Tests:** 5079, unchanged in count; the two pins were re-pinned (`compat: registers minor 5 with
  exactly the seventeen public members`, `sim sample: the shell's minor is 4`). The three skips are
  still declared skips, not passes.
- **Complexity:** unchanged.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | the eleven files [`../RESULTS.md`](../RESULTS.md) lists | see there | Eleven, nothing over 1500, the same eleven as the previous run. Neither changed file is in the band, and no re-check trigger fired; each disposition is in `CLAUDE.md`'s census. |

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-11-21, by hand
- **Files reviewed:** `Sim.lua` moved (3 -> 4, comment-only). Checked against the change:
  `tests/fixture_sim_panel.lua`, every `tests/test_sim_*.lua` and `tests/test_widgets_teststrip.lua`,
  and the new `docs/api/Sim/version-4.3.11.4-docs.md`. Only `tests/test_sim_sample.lua` pins the
  shell's minor, and it is re-pinned; `tests/test_sim_seam.lua` compares the minor to itself. No
  sample character, scenario, seam or strip changed, so no host's scenarios or test-mode data are
  affected and step 8 lists no host for a re-look.
- **Commits since the previous run touching them:** 1 (`e2f7544`)

## Actions

1. Move the local tag `v1.109.0` onto the record commit: the push, the merge to `master` and the
   re-vendor wait on the owner's go-ahead (Ka0sAddonsCommonTasks `docs/2026-11-21-SYNC_FOLLOWUPS/`).
2. Re-vendor every consumer (step 8): as the previous run's actions, plus re-pin `Compat 4` or `Sim 3`
   where a host pins them. No facade member moves.
