# Analysis — 20261102-000358

- **Addon:** LibKa0s 1.85.0 (release run, `--release 1.85.0`, the tag's fourth local re-cut; the
  manifest's `addonVersion` is read from the newest tag)
- **Verdict:** green
- **Commit:** ca76511 (`feat/2026-11-01-full-skinning`), clean
- **Previous run:** [`20261101-195248`](../20261101-195248/) (`--release 1.85.0`, at `d9a045a`), the
  third re-cut, and the baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.85.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and max CCN is 15. **Perf was not measured**: this
repository ships no `tests/perf.lua`, so v1.85.0 was verified across **three** suites, not four.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261101-195248 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 289 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 3906 passed, 3 skipped, 0 failed, 3909 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3905 → 3909 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 86287 NLOC, 12462 functions, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | Yes: 12454 → 12462 functions; max CCN 15 at both |

The three skips are the previous run's. `test_skin_values` is still a declared skip, not a pass.

## What moved

Against [`20261101-195248`](../20261101-195248/), seven commits: `2ad1a50`, that run's own record;
`fe7b762`, `e7603da`, `5353215`, `bb87743` and `a50b539`, `SF-L1` to `SF-L5` of the owner's smoke
feedback (Ka0sAddonsCommonTasks `docs/2026-11-01-SMOKE_FEEDBACK/`); and `ca76511`, step 8 of
`docs/releasing.md`.

- **The picker's tooltips wrap** (`OptionsSkinPicker.lua` minor 8).
- **`list.header.arrow`**, a table's sort arrow, and headers in the skin's color (`SkinDefs.lua` 26,
  `SkinDefsOthers.lua` 8, `SkinPaintControls.lua` 16). This is the one new thing a host owes.
- **Every skin's values**: `list.stripe` stands 5% off the window, `title.bg` 5% off it, `divider` 10%
  off both, and High Contrast's edges are 1px. Ka0s Default moves in `title.bg` only, by the owner's
  all-skins ruling. Its stripe and its gold on gold arrow stay.
- **The band** is nine files, membership unchanged. `LibKa0s/OptionsSkinPicker.lua` moves 1267 → 1269.
  Its `CLAUDE.md` disposition still reads 1267 at minor 7, dated: an agent of this run does not edit
  `CLAUDE.md`, so the next sync-docs pass owes that row. No function was added there.

## Complexity watch list

### Functions the complexity suite warned on

None.

### Files by `layout-§1` band

Nine, nothing over 1500, none newly crossed.

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-11-02, the lead's call under the owner's run guidelines, standing for this re-cut;
  the owner was not asked
- **Files reviewed:** `Sim.lua`, `SimTimeline.lua`, `SimPanel.lua`, `SimPanelRender.lua`,
  `Widgets.lua`, `tests/fixture_sim_panel.lua`, every `tests/test_sim_*.lua` and
  `tests/test_widgets_teststrip.lua` did not move since the previous cut, and all ran green here
- **Effect:** none. The strip and Sim panel only repaint through the moved tokens.

## Actions

1. The local annotated tag `v1.85.0` is deleted and re-cut on the commit that adds this bundle. It was
   never pushed (`git ls-remote` shows no such tag). The branch push, the merge to `master` and the
   tag push wait on the owner.
2. Step 8 re-vendors the re-cut tag into every consumer on the run's branch. BankLedger and
   LootHistory read `list.header.arrow` for their sort marks.
3. In-client smoke is the owner's and none is marked passed here.
