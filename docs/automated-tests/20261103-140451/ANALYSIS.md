# Analysis — 20261103-140451

- **Addon:** LibKa0s 1.85.0 (release run, `--release 1.85.0`, the tag's fourteenth local re-cut, `R4-REL2` after
  `R4-L2`, `R4-L3` and `R4-SEP`; the manifest's `addonVersion` is read from the newest tag)
- **Verdict:** green
- **Commit:** `6858838` (`feat/2026-11-01-full-skinning`), clean, the round 4 second hosts-owe note: nothing but this record follows it
- **Previous run:** [`20261103-123922`](../20261103-123922/) (at `f01e213`), the thirteenth re-cut and the
  baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.85.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and max CCN is 15. **Perf was not measured**: this
repository ships no `tests/perf.lua`, so v1.85.0 was verified across **three** suites, not four.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261103-123922 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 292 files | [`lint.txt`](lint.txt) | No: 292 files at both |
| tests | pass | 3983 passed, 3 skipped, 0 failed, 3986 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3979 -> 3986 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 87915 NLOC, 12703 functions, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | Yes: 87769 -> 87915 NLOC, 12685 -> 12703 functions; max CCN 15 at both |

The three skips are the previous run's: the declined kit prose gate, the diagnostics opt-out case and
`test_skin_values`, which is still a declared skip, not a pass.

## What moved

Against [`20261103-123922`](../20261103-123922/): the second milestone of the owner's fourth smoke round
(Ka0sAddonsCommonTasks `docs/2026-11-03-SMOKE_ROUND4/`, the owner's sign-off in `R4_SIGNOFF.md`).

- **`R4-L2`, SkinDefs minor 26**: Ka0s Default's title band is the opaque dark gold gradient
  `title.bgTop` `#3A2F0A` over `title.bgBottom` `#1F1905`; `title.bg` is the blend `#2C2408`, and the
  skin picker's second Ka0s Default swatch is the header.
- **`R4-L3`, SkinDefs 26, SkinDefsOthers 8, SkinPaintControls 16, SkinPaintExtras 16, SkinEUI 4**: the
  new nilable `icon.outline` token, a window's icon outline, drawn by `S.IconBorder` and `S.SquareIcon`
  before `icon.border`; `icon.border`, the HUD edges, does not move in any skin.
- **`R4-SEP`, Core 15, DebugLogWindow 3**: the debug console makes no `frame.divider`, and
  `Core.ApplySkin`, so `S.Shell`, hides any `frame.divider` on every call; no window the library draws
  or paints has a line under its title.
- None of these minors has shipped, so no minor and no key moves; no public member moves.
- Tests: 7 cases more, 3986 total: 2 in `tests/test_skin_defs.lua`, 4 in
  `tests/test_skin_icon_border.lua` and 1 in `tests/test_skin_paint.lua`. Existing cases in
  `tests/test_core.lua`, `tests/test_debuglog.lua`, `tests/test_skin_host_gaps.lua` and
  `tests/test_skin_paint_controls.lua` moved with the look they pin.

## Complexity watch list

### Functions the complexity suite warned on

None.

### Files by `layout-§1` band

Fourteen, nothing over 1500. One came in: `tests/test_debuglog.lua`, at 1000 with `R4-SEP`'s console
cases, ruled **accepted** in `CLAUDE.md`'s band census at this re-cut (a suite, so a peel is no
release; seam: the close-button factory across a Core upgrade section; trigger: 1100 lines or the
next console case). `LibKa0s/SkinPaintControls.lua` grew 1060 -> 1063 with `R4-L3`, 37 under its
1100 trigger, and its census entry moved with it. `LibKa0s/SkinPaintExtras.lua` is still at 1095, 5
under its trigger, and `LibKa0s/Skin.lua` at 1097, 3 under its own. `LibKa0s/Widgets.lua` (1037) did
not move and its cell stays blank, as at the previous runs: it is unruled, and that is stated here
rather than filled in.

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-11-03, the lead's call under the owner's run guidelines; the owner was not asked
- **Files reviewed:** no `Sim*.lua`, `Widgets.lua` or `Launcher.lua` moved in this re-cut; every
  `tests/test_sim_*.lua` and `tests/test_widgets_teststrip.lua` ran green

## Actions

1. The local annotated tag `v1.85.0` is re-cut on the commit that adds this bundle. It was never
   pushed. The merge to `master` and the tag push wait on the owner.
2. Step 8 re-vendors the re-cut tag into every consumer (`R4-RV2`). What hosts owe is one list in
   `docs/releasing.md`, the smoke round 4 second paragraph: MultiMeters' `NS.SKIN_FALLBACK` copy of
   `title.bg`, host suites that pin `S.IconBorder`'s edge, and every header line a host draws itself.
3. In-client smoke is the owner's and none is marked passed here.
