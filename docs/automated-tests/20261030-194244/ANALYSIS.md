# Analysis — 20261030-194244

- **Addon:** LibKa0s 1.82.0 (release run, `--release 1.82.0`; `addonVersion` reads 1.82.0 because
  a library repo has no TOC and the runner falls back to `git describe`, which found the first,
  local `v1.82.0` tag at `11a9c9a`. That tag is re-cut on the commit that adds this bundle)
- **Verdict:** green
- **Commit:** 9d83cd4 (`feat/2026-10-30-skin-fonts-feedback`), clean
- **Previous run:** [`20261030-190625`](../20261030-190625/) (`--release 1.82.0`, at `c6a9fb7`),
  the first v1.82.0 release run, is the baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.82.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `complexity.blindFiles` is 0 and
`complexity.crashedFiles` is 0. **Perf was not measured**: this repository ships no
`tests/perf.lua`, so v1.82.0 was verified across **three** suites, not four.

This run supersedes `20261030-190625` as v1.82.0's release record. That run measured `c6a9fb7`,
which still carried the vendor-sync gap below, and the first local tag was cut over it.

## Why this run exists

Addendum 05 of Ka0sAddonsCommonTasks `docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK/` (`LK-A2`): ST-01's
trial re-vendor of the first v1.82.0 tag went red in its first consumer. The test kit's
`vendor_sync.lua` `BINARY_EXT` table stopped at `zip`, so the gate stripped CR from the shipped
`media/fonts/Expressway-EULA.pdf` and a byte-identical vendored copy failed *matches the library
repo at v1.82.0*. Every consumer would have gone red. Three commits sit between the two runs:

- `11a9c9a` (`LK-90`): the first release record, `20261030-190625`, and its CHANGELOG lines.
- `7914c51` (`LK-A2`): `BINARY_EXT` carries all twenty extensions `.gitattributes` pins `binary`;
  the predicate is published as `VendorSync.isBinary`; two new kit-sync cases (a CR LF PDF compared
  raw, and the table kept in step with `.gitattributes`). Both kit copies are byte-identical; kit
  revision stays 45, which no pushed tag has released.
- `9d83cd4` (`LK-A2`, the review): a third case pins the text side of the split, a fixture
  `Guide.html` whose LF blob a CR LF consumer copy must still match.

No file under `LibKa0s/` moved, so no LibStub minor moved: the fix is in `testkit/` alone.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261030-190625 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 246 files | [`lint.txt`](lint.txt) | No: 246 files, 0/0 at both |
| tests | pass | 3412 passed, 2 skipped, 0 failed, 3414 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3411 → 3414 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: +49 NLOC, +5 functions; max CCN 15 at both, warnings 0 at both |

| Metric | Value |
|---|---|
| Total NLOC | 75530 |
| Functions | 10995 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 58.8 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 14 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost. **`tests` carries two skips**, the same two as at the previous run: the kit's own
`tests/_kit/test_prose.lua`, declined under `CLAUDE.md`'s `localization-§5` deviation row, and the
diagnostics contract's opt-out case, a declared skip in a repo that keeps the default.

## What moved

Against [`20261030-190625`](../20261030-190625/):

- **lint** is unchanged: the same 246 files, 0/0. No file was added; `tests/test_kit_vendor_sync.lua`
  and the two `vendor_sync.lua` copies changed in place.
- **tests** grow by 3 cases (3411 → 3414; 3409 → 3412 passed), all in `test_kit_vendor_sync`
  (19 → 22 there, per [`test-cases.md`](test-cases.md)): the CR LF PDF compared byte for byte, the
  `.gitattributes` guard, and the CR LF text copy of an LF blob. None fails, and the skipped count
  stays at 2.
- **complexity** grows by 49 NLOC (75481 → 75530) and 5 functions (10990 → 10995): the new cases'
  closures and `VendorSync.isBinary`. Every average holds (NLOC 6.8, CCN 2.1, tokens 58.8). Max CCN
  is 15 and no function is warned on.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

The same fourteen files as at `20261030-190625`, at the same line counts: outside the two bundles,
`git diff c6a9fb7 9d83cd4` touches only `CHANGELOG.md`, `docs/api/testkit/version-45-docs.md`,
`docs/test-cases.md`, the two `vendor_sync.lua` copies and `tests/test_kit_vendor_sync.lua`, and
none of them is in the band. Their dispositions are that run's, carried forward unchanged; see its
[`ANALYSIS.md`](../20261030-190625/ANALYSIS.md) and `RESULTS.md`'s watch list.
`tests/test_kit_vendor_sync.lua` is 418 lines.

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-10-30, by hand (`docs/releasing.md` step 5, *The preview and simulation re-look*)
- **Files reviewed:** none required. `git diff v1.81.0 -- LibKa0s/Sim.lua LibKa0s/SimTimeline.lua
  LibKa0s/SimPanel.lua LibKa0s/Widgets.lua` still moves no minor; the three commits since the
  previous run touch no file under `LibKa0s/`
- **Commits since the previous release touching them:** none

## Actions

1. The local annotated tag `v1.82.0` is re-cut from `11a9c9a` onto the commit that adds this
   bundle. Neither cut was pushed (`git ls-remote --tags origin` lists no `v1.82.0`), so moving it
   is safe; the branch push, the merge to `master` and the tag push wait on the owner.
2. ST-01 re-vendors from the re-cut tag; with the fix in it, the vendored
   `media/fonts/Expressway-EULA.pdf` compares raw and the vendor-sync case passes.
3. The open actions of [`20261030-190625`](../20261030-190625/ANALYSIS.md) stand unchanged
   (standard v2.93.0 merges with this release; `LibKa0s/Skin.lua` and `LibKa0s/SkinDefs.lua` sit
   at their triggers; in-client smoke is the owner's, and none is marked passed here).
