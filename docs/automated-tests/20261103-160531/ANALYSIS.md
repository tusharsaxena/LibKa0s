# Analysis — 20261103-160531

- **Addon:** LibKa0s 1.85.0 (release run, `--release 1.85.0`, the tag's fifteenth local re-cut, `R4-REL3` after
  `R4-L4`; the manifest's `addonVersion` is read from the newest tag)
- **Verdict:** green
- **Commit:** `ef88399` (`feat/2026-11-01-full-skinning`), clean, the round 4 third hosts-owe note: nothing but this record follows it
- **Previous run:** [`20261103-140451`](../20261103-140451/) (at `6858838`), the fourteenth re-cut and the
  baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.85.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and max CCN is 15. **Perf was not measured**: this
repository ships no `tests/perf.lua`, so v1.85.0 was verified across **three** suites, not four.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261103-140451 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 292 files | [`lint.txt`](lint.txt) | No: 292 files at both |
| tests | pass | 3986 passed, 3 skipped, 0 failed, 3989 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3986 -> 3989 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 87978 NLOC, 12707 functions, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | Yes: 87915 -> 87978 NLOC, 12703 -> 12707 functions; max CCN 15 at both |

The three skips are the previous run's: the declined kit prose gate, the diagnostics opt-out case and
`test_skin_values`, which is still a declared skip, not a pass.

## What moved

Against [`20261103-140451`](../20261103-140451/): the HUD icon edge of the owner's fourth smoke round
(Ka0sAddonsCommonTasks `docs/2026-11-03-SMOKE_ROUND4/R4_ADDENDUM_HUD_ICON_EDGE.md`, which follows the
owner's scope answer in `R4_SIGNOFF.md`, "I prefer the HUD icons to keep black edges").

- **`R4-L4`, SkinPaintControls minor 17, Skin key 15.1.26.8.17.16.17.4.9**: `S.IconBorder(frame, { hud = true })`
  draws its edge in `icon.border`, else `divider`, else the body text at 0.4, and never reads
  `icon.outline`; the flag is recorded with the call, so a repaint and a skin switch keep it. Without it,
  or with `hud = false`, nothing changes. The minor moves although v1.85.0 is a local cut, because minor
  16 copies already sit in vendored trees. `opts.hud` is an option of an existing member, so no public
  member moves.
- Tests: 3 cases more, 3989 total, all in `tests/test_skin_icon_border.lua` (18 -> 21): the HUD edge in
  every skin, the window edge with no flag and with `hud = false`, and the flag through a replay and
  skin flips.

## Complexity watch list

### Functions the complexity suite warned on

None.

### Files by `layout-§1` band

Fourteen, nothing over 1500, none came in or left. `LibKa0s/SkinPaintControls.lua` grew 1063 -> 1073
with `R4-L4`, 27 under its 1100 trigger, but the **minor half of its re-check trigger fired**: the file
moved to minor 17. This re-cut carries it unpeeled. The peel adds a shipped file and a re-vendor into
every consumer, so `CLAUDE.md`'s census row leaves it to the lead and the owner, and its Disposition cell
in RESULTS.md now says so. `LibKa0s/SkinPaintExtras.lua` is still at 1095, 5 under its trigger, and
`LibKa0s/Skin.lua` at 1097, 3 under its own. `LibKa0s/Widgets.lua` (1037) did not move and its cell
stays blank, as at the previous runs: it is unruled, and that is stated here rather than filled in.

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-11-03, the lead's call under the owner's run guidelines; the owner was not asked
- **Files reviewed:** no `Sim*.lua`, `Widgets.lua` or `Launcher.lua` moved in this re-cut; every
  `tests/test_sim_*.lua` and `tests/test_widgets_teststrip.lua` ran green

## Actions

1. The local annotated tag `v1.85.0` is re-cut on the commit that adds this bundle. It was never
   pushed. The merge to `master` and the tag push wait on the owner.
2. Step 8 re-vendors the re-cut tag into every consumer (`R4-RV3`). What hosts owe is one list in
   `docs/releasing.md`, the smoke round 4 HUD icon edge paragraph: every HUD site that edges an icon
   through `S.IconBorder` passes `hud = true` (DpsRace's HUD spell rows and chart, MultiMeters' row
   icons, PartyFrameEnhanced's cast icon), and window sites pass nothing (`R4-HUD`).
3. The SkinPaintControls peel, whose minor trigger fired, is the lead's and the owner's call.
4. In-client smoke is the owner's and none is marked passed here.
