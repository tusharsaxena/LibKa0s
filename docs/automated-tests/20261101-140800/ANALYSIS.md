# Analysis — 20261101-140800

- **Addon:** LibKa0s 1.85.0 (release run, `--release 1.85.0`, the tag's second local re-cut; the
  manifest's `addonVersion` is read from the newest tag)
- **Verdict:** green
- **Commit:** fb01cee (`feat/2026-11-01-full-skinning`), clean
- **Previous run:** [`20261101-133851`](../20261101-133851/) (`--release 1.85.0`, at `09e57dc`), the
  first re-cut, and the baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.85.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `complexity.blindFiles` is 0 and
`complexity.crashedFiles` is 0. **Perf was not measured**: this repository ships no
`tests/perf.lua`, so v1.85.0 was verified across **three** suites, not four.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261101-133851 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 280 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 3759 passed, 2 skipped, 0 failed, 3761 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3757 → 3761 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: 12023 → 12031 functions; max CCN 15 at both, warnings 0 at both |

| Metric | Value |
|---|---|
| Total NLOC | 83441 |
| Functions | 12031 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 59.7 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 9 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost. **`tests` carries two skips**, the same count as at the previous run.

## What moved

Against [`20261101-133851`](../20261101-133851/), two commits: `a68f83f`, that run's own record, and
`fb01cee`, Toast minor 2. `d.soundFile` is an additive descriptor field, so `Toast`'s public members
are unchanged and a host that does not pass it plays what it played. The only code files that moved
are `LibKa0s/Toast.lua` and `tests/test_toast.lua`.

- **tests** four more cases, in `tests/test_toast.lua`.
- **lint** unchanged at 280 files; no file was added.
- **complexity** eight more functions, max CCN unchanged.
- **the band** is unchanged in membership. `LibKa0s/Toast.lua` grows from 460 to 479 lines, outside
  the band, and no band file moved.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

Nine, nothing over 1500, none newly crossed, and none of the nine moved since the previous run, so
no disposition moves and no shelf life is spent by a change in this run.

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-11-01, the lead's call under the owner's run guidelines, standing for this re-cut;
  the owner was not asked
- **Files reviewed:** none new. `Sim.lua`, `SimTimeline.lua`, `SimPanel.lua`, `SimPanelRender.lua`,
  `Widgets.lua`, `tests/fixture_sim_panel.lua`, every `tests/test_sim_*.lua` and
  `tests/test_widgets_teststrip.lua` did not move since that answer
- **Commits since the previous cut touching them:** none

## Actions

1. The local annotated tag `v1.85.0` is deleted and re-cut on the commit that adds this bundle. It was
   never pushed (`git ls-remote` shows no such tag). The branch push, the merge to `master` and the
   tag push wait on the owner.
2. Step 8 re-vendors the re-cut tag into every consumer on the run's branch, and each flip follows
   the Options document's *Moving to this version*. Toast minor 2 adds no member, so no facade or
   stub owes anything for it.
3. The hosts step 5 named re-look at their scenarios or strips at their next release.
4. In-client smoke is the owner's and none is marked passed here.
