# Analysis — 20261126-131708

- **Addon:** LibKa0s 1.117.0 (release run, `--release 1.118.0`; `addonVersion` reads 1.117.0 because
  the local tag `v1.117.0` is the nearest `git describe` finds; `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `c06c772c` (`feat/2026-11-26-owner-feedback-round4`), clean: the v1.118.0 release, all
  but its own record. The record (this bundle, its `RESULTS.md` row and the changelog's release-gate
  lines) follows as one commit, and the local tag `v1.118.0`, never pushed, is cut on it.
- **Previous run:** [`20261126-002415`](../20261126-002415/) (at `1a61374e`, the v1.117.0 record)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.118.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and max CCN is 15. **Perf was not measured**: this
repository ships no `tests/perf.lua`, so v1.118.0 was verified across **three** suites, not four.

The release moves one payload file, `LibKa0s/Media.lua` to minor 14 (`R4-LK-01`: `ICONS` gains
`dash`, a thick rounded bar the library draws itself), and adds two payload files,
`LibKa0s/media/icons/dash.tga` and `LibKa0s/media/icons/CREDITS.txt`. The kit stays at revision 65.
The first run of this battery at this commit is this one; nothing was discarded.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261126-002415 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 394 files | [`lint.txt`](lint.txt) | No (394 files) |
| tests | pass | 5263 passed, 3 skipped, 0 failed, 5266 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 5263 -> 5266 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | NLOC +55, functions +4; averages flat but tokens |

| Metric | Value |
|---|---|
| Total NLOC | 117598 |
| Functions | 16874 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 61.1 |
| Warnings (CCN > 15) | 0 |

The suite was also run under `KA0S_KIT_CLIENT=forever` on the same tree, outside the runner: 5263
passed, 0 failed, 3 skipped, 5266 total. The seed tool's own cases, `python3 -m pytest -q tools/seeds`,
ran outside the runner too: 18 passed. `python3 -I tools/artwork/dash_icon.py --check` reports the
committed `dash.tga` is what the generator draws. The complexity suite measures Lua only, so the two
Python tools are not in its figures.

## What moved

- **Payload:** `LibKa0s/Media.lua` (minor 13 -> 14): `dash` appended to the hand-written `ICONS`
  block, after `shield`, so no stored name or path moves. `MediaIcons.lua` unchanged at minor 1. Two
  files added under `media/icons/`: `dash.tga` (64x64 RLE 32-bit, white, 28 x 14 px opaque) and
  `CREDITS.txt`. No `NEEDS_*` floor rises.
- **Contract changes:** `docs/api/Media/version-14.1-docs.md` and `members-14.1.json` are new and
  supersede version 13.1. Additive only.
- **Lint:** no change in the checked set (394 files); `tools/artwork/dash_icon.py` is Python.
- **Tests:** 5263 -> 5266: three new cases in `tests/test_media.lua` (the 114th name and its path; the
  bar's size, width against the fat arrow's stem, rounded ends and white; the credit file). Two cases
  re-pin: the Open Iconic folder counts 225, and `ICONS[114]` is `dash`. The three skips are
  unchanged, declared skips, not passes.
- **Complexity:** NLOC 117543 -> 117598 and functions 16870 -> 16874, the new cases and their
  TGA-box helper. Max CCN still 15, 0 warnings.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `tests/test_media.lua` | 1117 | **Its re-check trigger (1100 lines) fired at this release**, with the three `dash` cases (1048 -> 1117). A suite, so a peel is no release; the seam stays the font inventory and license section, to a suite of its own. Left to the lead. |
| 1000–1500 (on notice) | the eleven other files [`../RESULTS.md`](../RESULTS.md) lists | see there | The same eleven as the previous run, each disposition carried; none moved. |

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-11-26, by hand
- **Files reviewed:** none needed: no Sim file and not `Widgets.lua` moved in this release.
- **Commits since the previous release touching them:** 0.
- **Note:** the release moves Media 14 only.

## Actions

1. Cut the local tag `v1.118.0` on this record commit. Pushing it, merging to `master` and the
   re-vendor's merge wait on the owner's go-ahead (Ka0sAddonsCommonTasks
   `docs/2026-11-26-OWNER_FEEDBACK_ROUND4/`).
2. Drop Watcher re-vendors v1.118.0 in the same run (`R4-DW-00`), declares `dash` and draws it as the
   "no skill-up" mark (`R4-DW-02`); it is the only addon that re-vendors.
3. `tests/test_media.lua` crossed its 1100-line trigger; the peel (fonts section to its own suite) is
   the lead's call.
