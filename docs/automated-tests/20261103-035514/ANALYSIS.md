# Analysis — 20261103-035514

- **Addon:** LibKa0s 1.85.0 (release run, `--release 1.85.0`, the tag's tenth local re-cut, `R3-REL` after
  `R3-FIX`; the manifest's `addonVersion` is read from the newest tag)
- **Verdict:** green
- **Commit:** `3661a71` (`feat/2026-11-01-full-skinning`), clean, the R3-REL hosts-owe commit: nothing but this record follows it
- **Previous run:** [`20261102-235338`](../20261102-235338/) (at `8582037`), the ninth re-cut, and the baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.85.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and max CCN is 15. **Perf was not measured**: this
repository ships no `tests/perf.lua`, so v1.85.0 was verified across **three** suites, not four.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261102-235338 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 291 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 3952 passed, 3 skipped, 0 failed, 3955 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3952 → 3955 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 87346 NLOC, 12620 functions, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | Yes: 87214 → 87346 NLOC, 12601 → 12620 functions; max CCN 15 at both |

The three skips are the previous run's: the declined kit prose gate, the diagnostics opt-out case and
`test_skin_values`, which is still a declared skip, not a pass.

## What moved

Against [`20261102-235338`](../20261102-235338/) (which this run supersedes as the gate record): the
round's independent review (`R3-FIX` of Ka0sAddonsCommonTasks `docs/2026-11-02-SMOKE_ROUND3/`).
No file minor moved: every file touched was already above its v1.84.0 minor in this unshipped release.

- **Pixel edges stay one pixel** (`P.pxWatch`): `S.IconBorder`'s outline and `S.FadeNineSlice`'s ring
  re-size on `UI_SCALE_CHANGED`, `DISPLAY_SIZE_CHANGED` and an ancestor `SetScale` that moves the scale.
- **The icon zoom only tightens**: a host's tighter crop (`S.SquareIcon`'s 0.08) stands.
- **Every skin's `icon.borderStyle` / `icon.borderSize` is Solid 1px**, so the hosts that draw their own
  icon border from them match `IconBorder`.
- Tests: 3 cases more, 3955 total; four existing cases moved their 2 px pins to 1 px.

## Complexity watch list

### Functions the complexity suite warned on

None.

### Files by `layout-§1` band

Thirteen, nothing over 1500, as at the previous run. `LibKa0s/SkinPaintExtras.lua` is at 1098, 2 under
its 1100 trigger, and `LibKa0s/SkinPaintControls.lua` at 1059; both rulings in `CLAUDE.md`'s band
census name the new figure. `LibKa0s/Widgets.lua` (1037) did not move and its cell stays blank, as
at the previous runs: it is unruled, and that is stated here rather than filled in. `LibKa0s/Skin.lua`
is at 1097, 3 under its 1100 trigger.

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-11-03, the lead's call under the owner's run guidelines; the owner was not asked
- **Files reviewed:** no `Sim*.lua`, `Widgets.lua` or `Launcher.lua` moved in this re-cut; every
  `tests/test_sim_*.lua` and `tests/test_widgets_teststrip.lua` ran green

## Actions

1. The local annotated tag `v1.85.0` is re-cut on the commit that adds this bundle. It was never
   pushed. The branch is pushed; the merge to `master` and the tag push wait on the owner.
2. Step 8 re-vendors the re-cut tag into every consumer (`R3-RV` under `R3-FIX`). What hosts owe is
   one list in `docs/releasing.md`, the R3-FIX paragraph.
3. In-client smoke is the owner's and none is marked passed here.
