# Analysis — 20261102-111553

- **Addon:** LibKa0s 1.85.0 (release run, `--release 1.85.0`, the tag's sixth local re-cut; the
  manifest's `addonVersion` is read from the newest tag)
- **Verdict:** green
- **Commit:** c5521e7 (`feat/2026-11-01-full-skinning`), clean, the final tree: nothing but this record follows it
- **Previous run:** [`20261102-020922`](../20261102-020922/) (`--release 1.85.0`, at `ed23709`), the
  fifth re-cut, and the baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.85.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and max CCN is 15. **Perf was not measured**: this
repository ships no `tests/perf.lua`, so v1.85.0 was verified across **three** suites, not four.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261102-020922 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 290 files | [`lint.txt`](lint.txt) | Yes: 289 → 290 files |
| tests | pass | 3926 passed, 3 skipped, 0 failed, 3929 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3921 → 3929 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 86707 NLOC, 12552 functions, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | Yes: 12528 → 12552 functions; max CCN 15 at both |

The three skips are the previous run's. `test_skin_values` is still a declared skip, not a pass.

## What moved

Against [`20261102-020922`](../20261102-020922/): `SG-L1` to `SG-L3` of the owner's second smoke round
(Ka0sAddonsCommonTasks `docs/2026-11-01-SMOKE_FEEDBACK/`), and the `SG-REL` commit that writes what
hosts owe. This is the first re-cut whose battery ran on the final tree.

- **`Launcher.lua` 7** (`SG-L1`): the right-click menu gains Sim mode (`isSimMode`, `toggleSim`) and
  Open settings (every addon, never grayed), and one row rule: a checkbox's tick is asked live, an
  action is a plain button, a gated row of either kind grays with the note.
- **`OptionsSkinPicker.lua` 9** (`SG-L3`): `O.SkinNotice(spec, store)` and `lib.SKIN_NOTICE_VERSION`,
  the once-per-account skin notice. The first addon to ask in a session claims it, the rest record it.
- **`SG-L2`, no code**: one broker object and one LibDBIcon button per addon; nothing in the library or
  a host sets `showInCompartment` or calls `AddButtonToCompartment`, and a test pins it. The second
  entry in a button collector is drawn by the collector, so nothing changed.
- `SkinNotice` keeps its claim on the library table for the session only. An addon the player enables
  later, which has no record, shows the picker once on its first run.
- **The band** is unchanged at eleven files; `OptionsSkinPicker.lua` is about 1300 lines, under its
  1400 trigger. No function above CCN 15 was added.

## Complexity watch list

### Functions the complexity suite warned on

None.

### Files by `layout-§1` band

Eleven, nothing over 1500.

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-11-02, the lead's call under the owner's run guidelines; the owner was not asked
- **Files reviewed:** `Launcher.lua` and `OptionsSkinPicker.lua` moved; `Sim.lua`, `SimTimeline.lua`,
  `SimPanel.lua`, `SimPanelRender.lua` and `Widgets.lua` did not; every `tests/test_sim_*.lua` ran green
- **Effect:** none by default. Sim mode in the menu appears only where a host passes `isSimMode` and
  `toggleSim`.

## Actions

1. The local annotated tag `v1.85.0` is deleted and re-cut on the commit that adds this bundle. It was
   never pushed. The branch push, the merge to `master` and the tag push wait on the owner.
2. Step 8 re-vendors the re-cut tag into every consumer. What hosts owe is one list in
   `docs/releasing.md` (`isSimMode` and `toggleSim`, and the `O.SkinNotice` call with a `skinNotice`
   number in `db.global`).
3. In-client smoke is the owner's and none is marked passed here.
