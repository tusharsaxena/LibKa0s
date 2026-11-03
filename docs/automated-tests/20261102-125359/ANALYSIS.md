# Analysis — 20261102-125359

- **Addon:** LibKa0s 1.85.0 (release run, `--release 1.85.0`, the tag's seventh local re-cut; the
  manifest's `addonVersion` is read from the newest tag)
- **Verdict:** green
- **Commit:** 6516984 (`feat/2026-11-01-full-skinning`), clean, the final tree: nothing but this record follows it
- **Previous run:** [`20261102-111553`](../20261102-111553/) (`--release 1.85.0`, at `c5521e7`), the
  sixth re-cut, and the baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.85.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and max CCN is 15. **Perf was not measured**: this
repository ships no `tests/perf.lua`, so v1.85.0 was verified across **three** suites, not four.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261102-020922 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 290 files | [`lint.txt`](lint.txt) | No (290 files at both) |
| tests | pass | 3928 passed, 3 skipped, 0 failed, 3931 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3929 → 3931 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 86787 NLOC, 12560 functions, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | Yes: 12552 → 12560 functions; max CCN 15 at both |

The three skips are the previous run's. `test_skin_values` is still a declared skip, not a pass.

## What moved

Against [`20261102-111553`](../20261102-111553/): `SG-L3` of the owner's second smoke round
(Ka0sAddonsCommonTasks `docs/2026-11-01-SMOKE_FEEDBACK/`), after the review found the notice could show twice.

- **`OptionsSkinPicker.lua` 9, changed in place** (`SG-L3`; the minor does not move, because v1.85.0 was
  never pushed): `O.SkinNotice` now makes the claim on a `seen` answer too, so an addon that has seen it
  silences one that has not. The first show waits three seconds for login to settle and answers
  `nil, "queued"`, re-checking the claim then; combat in that moment asks again every five seconds. A
  third argument, `recordOnly`, lets a stood-down host record or silence without showing (`nil, "standdown"`).
- Tests: `test_options_skin_notice.lua` is rewritten for the settle (5 cases, 3931 total). Three cases
  pin the defect: a seen addon silences an earlier one, a stood-down host claims on `seen`, and combat in
  the settle retries.
- Docs: the Options version snapshot, the changelog and the hosts-owe list in `docs/releasing.md`.
- **The band** is unchanged at eleven files; `OptionsSkinPicker.lua` is 1338 lines, under its 1400
  trigger. No function above CCN 15 was added.

## Complexity watch list

### Functions the complexity suite warned on

None.

### Files by `layout-§1` band

Eleven, nothing over 1500.

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-11-02, the lead's call under the owner's run guidelines; the owner was not asked
- **Files reviewed:** `OptionsSkinPicker.lua` moved; no `Sim*.lua` or `Launcher.lua` moved in this re-cut;
  every `tests/test_sim_*.lua` ran green

## Actions

1. The local annotated tag `v1.85.0` is deleted and re-cut on the commit that adds this bundle. It was
   never pushed. The branch push, the merge to `master` and the tag push wait on the owner.
2. Step 8 re-vendors the re-cut tag into every consumer. What hosts owe is one list in
   `docs/releasing.md` (`isSimMode` and `toggleSim`, and the `O.SkinNotice` call with a `skinNotice`
   number in `db.global`).
3. In-client smoke is the owner's and none is marked passed here.
