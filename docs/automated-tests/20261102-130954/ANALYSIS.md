# Analysis — 20261102-130954

- **Addon:** LibKa0s 1.85.0 (release run, `--release 1.85.0`, the tag's eighth local re-cut; the
  manifest's `addonVersion` is read from the newest tag)
- **Verdict:** green
- **Commit:** HEAD of this run (the SG-L3 timer removal) (`feat/2026-11-01-full-skinning`), clean, the final tree: nothing but this record follows it
- **Previous run:** [`20261102-125359`](../20261102-125359/) (at `6516984`), the seventh re-cut, and the baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.85.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and max CCN is 15. **Perf was not measured**: this
repository ships no `tests/perf.lua`, so v1.85.0 was verified across **three** suites, not four.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261102-125359 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 290 files | [`lint.txt`](lint.txt) | No (290 files at both) |
| tests | pass | 3928 passed, 3 skipped, 0 failed, 3931 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No (3931 at both) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 86744 NLOC, 12555 functions, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | Yes: 12560 → 12555 functions; max CCN 15 at both |

The three skips are the previous run's. `test_skin_values` is still a declared skip, not a pass.

## What moved

Against [`20261102-125359`](../20261102-125359/) (which this run supersedes as the gate record): the
`SG-L3` notice lost its settle delay.

- **`OptionsSkinPicker.lua` 9, changed in place again**: the three-second login-settle timer and its
  `queued` answer are gone. The timer outlived a stand-down (hosts' suites caught it: a timer left armed
  after the stand-down) and deferred every host's first-run picker. What stays from the previous cut:
  a `seen` answer claims, and `recordOnly` is the stood-down host's third argument.
- **Residual, stated plainly**: an addon with no record that loads before every addon that has one still
  shows the notice once. That is its own first-run picker's job anyway.
- Tests: `test_options_skin_notice.lua` has five cases; the case for `seen` silencing a later addon and
  the stood-down case are the two that fail on the previous code. 3931 total, as before.
- **The band** is unchanged at eleven files; `OptionsSkinPicker.lua` is under its 1400 trigger. No
  function above CCN 15 was added.

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
