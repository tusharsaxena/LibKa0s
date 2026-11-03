# Analysis — 20261103-123922

- **Addon:** LibKa0s 1.85.0 (release run, `--release 1.85.0`, the tag's thirteenth local re-cut, `R4-REL` after
  `R4-L1`; the manifest's `addonVersion` is read from the newest tag)
- **Verdict:** green
- **Commit:** `f01e213` (`feat/2026-11-01-full-skinning`), clean, the round 4 hosts-owe note: nothing but this record follows it
- **Previous run:** [`20261103-042609`](../20261103-042609/) (at `2f9eb05`), the twelfth re-cut and the
  baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.85.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and max CCN is 15. **Perf was not measured**: this
repository ships no `tests/perf.lua`, so v1.85.0 was verified across **three** suites, not four.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261103-042609 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 292 files | [`lint.txt`](lint.txt) | Yes: 291 → 292 files (the new suite) |
| tests | pass | 3976 passed, 3 skipped, 0 failed, 3979 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3955 → 3979 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 87769 NLOC, 12685 functions, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | Yes: 87346 → 87769 NLOC, 12621 → 12685 functions; max CCN 15 at both |

The three skips are the previous run's: the declined kit prose gate, the diagnostics opt-out case and
`test_skin_values`, which is still a declared skip, not a pass.

## What moved

Against [`20261103-042609`](../20261103-042609/): the owner's fourth smoke round (`R4-L1` of
Ka0sAddonsCommonTasks `docs/2026-11-03-SMOKE_ROUND4/`, the owner's item 1).

- **OptionsCombat minor 4**: an AceGUI `Dropdown` and every type built from it (the `Ka0sMedia_*`
  pickers, AuraMaster's `AuraMasterDropdown`) closes its pullout on a press outside it, on a Ka0s
  settings page or a `Shell`-painted window only. One post-hook on `AceGUI.SetFocus`, and
  `GLOBAL_MOUSE_DOWN` registered through `lib.SafeRegisterEvent` only while such a pullout is open.
  The Options key moves to 37.4.44.2.7.1.8.15.2.4.18.13.5.5.7.6.9.1.1.4, with its API document and
  member manifest; no public member is added.
- Tests: 24 cases more, 3979 total, all in the new `tests/test_options_pullout_close.lua`; no existing
  case moved.

## Complexity watch list

### Functions the complexity suite warned on

None.

### Files by `layout-§1` band

Thirteen, nothing over 1500, the same files at the same line counts as the previous run:
`LibKa0s/OptionsCombat.lua`, the one payload file that moved, is at 438. `LibKa0s/Widgets.lua` (1037)
did not move and its cell stays blank, as at the previous runs: it is unruled, and that is stated
here rather than filled in. `LibKa0s/Skin.lua` is still at 1097, 3 under its 1100 trigger, and
`LibKa0s/SkinPaintExtras.lua` at 1095, 5 under its own.

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-11-03, the lead's call under the owner's run guidelines; the owner was not asked
- **Files reviewed:** no `Sim*.lua`, `Widgets.lua` or `Launcher.lua` moved in this re-cut; every
  `tests/test_sim_*.lua` and `tests/test_widgets_teststrip.lua` ran green

## Actions

1. The local annotated tag `v1.85.0` is re-cut on the commit that adds this bundle. It was never
   pushed. The merge to `master` and the tag push wait on the owner.
2. Step 8 re-vendors the re-cut tag into every consumer (`R4-RV`). What hosts owe is one list in
   `docs/releasing.md`, the smoke round 4 paragraph: a re-vendor and nothing else in code.
3. In-client smoke is the owner's and none is marked passed here.
