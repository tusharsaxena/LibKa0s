# Analysis — 20261101-133851

- **Addon:** LibKa0s 1.85.0 (release run, `--release 1.85.0`, the tag's first local re-cut; the
  manifest's `addonVersion` is read from the newest tag)
- **Verdict:** green
- **Commit:** 09e57dc (`feat/2026-11-01-full-skinning`), clean
- **Previous run:** [`20261101-120315`](../20261101-120315/) (`--release 1.85.0`, at `2ea32ae`), the
  first cut, and the baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.85.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `complexity.blindFiles` is 0 and
`complexity.crashedFiles` is 0. **Perf was not measured**: this repository ships no
`tests/perf.lua`, so v1.85.0 was verified across **three** suites, not four.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261101-120315 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 280 files | [`lint.txt`](lint.txt) | Yes: 279 → 280 files |
| tests | pass | 3755 passed, 2 skipped, 0 failed, 3757 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3730 → 3757 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: 11981 → 12023 functions; max CCN 15 at both, warnings 0 at both |

| Metric | Value |
|---|---|
| Total NLOC | 83377 |
| Functions | 12023 |
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

Against [`20261101-120315`](../20261101-120315/), two commits, `27d4136` and `09e57dc`, what the
AbsorbTracker pilot found missing: `S.BarGloss`, `S.HudFont` and `Skin.FollowOnce`, Skin minor 14 and
SkinPaintExtras minors 14 and 15. All three are additive, and Ka0s Default's look does not move.

- **tests** 27 more cases, in the new `tests/test_skin_hud_members.lua`.
- **lint** one more file, that suite.
- **complexity** 42 more functions, max CCN unchanged.
- **the band** is unchanged in membership. `LibKa0s/Skin.lua` grows from 1053 to 1071 lines, 29 under
  its trigger. `LibKa0s/SkinPaintExtras.lua` grows to 905, outside the band. `LibKa0s/SkinPaint.lua`
  did not move, so its register row's peel is not owed.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

Nine, nothing over 1500, none newly crossed. `LibKa0s/Skin.lua` (1071) was carried as *Accepted*
across this release's first cut and v1.84.0's, and that run's write-up said one more carry owed a
fix or a tracked deviation ID (anti-pattern #53). This run is that carry, so the file rejoins
`CLAUDE.md`'s tenth `automated-tests-§4` row, on the seam and trigger the census already named, and
its disposition moves with it in this commit. The ruling is the lead's and the owner has not seen it.

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-11-01, the lead's call under the owner's run guidelines, standing for the re-cut;
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
   the Options document's *Moving to this version*.
3. The hosts step 5 named re-look at their scenarios or strips at their next release.
4. In-client smoke is the owner's and none is marked passed here.
