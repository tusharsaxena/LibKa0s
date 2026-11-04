# Analysis — 20261105-030351

- **Addon:** LibKa0s 1.87.0 (release run, `--release 1.87.0`; the manifest's `addonVersion` reads
  1.86.0 because it is taken from the newest tag, and `v1.87.0` is cut after this bundle)
- **Verdict:** green
- **Commit:** `95feb1b` (`feat/2026-11-05-cascading-menus`), clean: the release commit, with nothing
  but this record after it
- **Previous run:** [`20261104-190021`](../20261104-190021/) (at `3b69e82`), v1.86.0's release run,
  which is also the baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.87.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.87.0 was verified
across **three** suites, not four. Nothing to act on before the tag.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261104-190021 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 306 files | [`lint.txt`](lint.txt) | Files 305 -> 306 |
| tests | pass | 4159 passed, 3 skipped, 0 failed, 4162 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4144 -> 4162 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Totals only; max CCN 15 and 0 warnings unchanged |

| Metric | Value |
|---|---|
| Total NLOC | 92851 |
| Functions | 13385 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.1 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 15 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

Perf is the one suite that is not a clean pass: a standing skip, because the library ships no
offline scenarios (see *Perf* in `RESULTS.md`). It is not measured, not passed.

## What moved

Against [`20261104-190021`](../20261104-190021/) (v1.86.0): true cascading menus for Outfitter
Reborn's outfit menu (OutfitterReborn `docs/superpowers/plans/2026-11-05-smoke-round-2.md`, Task 1).

- **Widgets minor 23, key 23.5.12.6.7.5** (`fb2bf89`): a `W.ContextMenu` row's `submenu = rows` opens
  a child level beside the row, one pooled frame per depth, the parent kept; `radio`, `selected` and
  `opts.check` draw a tick. No lib-level member moves. Every other key is unchanged from v1.86.0; kit
  revision 50, no kit file moved.
- **The review fix** (`b8da2ce`): one line of `docs/releasing.md`; no code.
- **The release commit** (`95feb1b`): docs, pointers and the step-9 Consumers re-sweep; no code.
- Lint: 305 -> 306 files, the one new suite `tests/test_widgets_submenu.lua`.
- Tests: 4144 -> 4162, 18 cases more, all in `test_widgets_submenu.lua` (18, per
  [`test-cases.md`](test-cases.md)). The three skips are v1.86.0's: the declined kit prose gate, the
  diagnostics opt-out case and `test_skin_values`, still declared skips, not passes.
- Complexity: 92405 -> 92851 NLOC and 13322 -> 13385 functions as `Widgets.lua` grew; avg NLOC 6.8,
  avg CCN 2.1 and avg tokens 60.1 unchanged. That is growth, not density.

## Complexity watch list

### Functions the complexity suite warned on

None.

### Files by `layout-§1` band

Fifteen, the same fifteen as v1.86.0, nothing over 1500. `LibKa0s/Widgets.lua` moved 1058 -> 1249
with minor 23 and still has a blank Disposition, as it did at v1.85.0 and v1.86.0; `CLAUDE.md`'s band
census records it as unruled, its seam the search box, and the ruling is the lead's. No other band
file moved.

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-11-05, by hand (`docs/releasing.md` step 5)
- **Files reviewed:** `tests/test_widgets_teststrip.lua` (the strip's right-click menu),
  `LibKa0s/SimPanel.lua`'s `closeMenu`, `tests/test_sim_panel.lua`'s `W.CloseMenu` cases,
  `tests/fixture_sim_panel.lua`, and `docs/api/Widgets/version-23.5.12.6.7.5-docs.md`
- **Commits since the previous release touching them:** 1 (`fb2bf89`: `Widgets.lua` minor 23, and
  `tests/fixture_sim_panel.lua` sharing the runner's loader, no case changed)
- **Note:** the strip's menu and the Sim panel's scenario picker open flat menus and close through
  `W.CloseMenu`, which still closes every level, so no host's scenarios or test-mode strips change
  and no host is named for step 8.

## Actions

1. Tag `v1.87.0` on the commit that adds this bundle, on `feat/2026-11-05-cascading-menus`, and push
   the branch and the tag (the owner's ruling for this run). The merge to `master` waits for the
   owner.
2. Step 8: Outfitter Reborn re-vendors from the tag (its plan's Task 3.1); the other hosts take
   v1.87.0 at their next re-vendor, since their menus are flat.
3. `LibKa0s/Widgets.lua`'s blank Disposition (1249 lines) is the lead's ruling, carried from v1.85.0.
