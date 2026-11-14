# Analysis — 20261114-163156

- **Addon:** LibKa0s 1.101.0 (release run, `--release 1.102.0`; `addonVersion` is the newest tag the
  runner's `git describe` found, and `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `715b291` (`feat/2026-11-14-callout-defaults`), clean: the v1.102.0 release commit.
  This branch was prepared as v1.101.0 (Callout key 4.5), but another branch's WaypointArrow release
  took v1.101.0 first (tag at `8c506bf`). That tag's commit is merged in (`733f01c`), this branch's
  release is renumbered to v1.102.0 (`08edaec`) and dated (`715b291`), and this branch's two bundles
  stamped 1.101.0 (`20261114-153219`, `20261114-154613`) were removed in the merge, as at the v1.99.0
  renumber: they recorded a 1.101.0 nobody tagged. The battery ran in a clean clone of the branch,
  named `LibKa0s`, because the runner needs a `.git` directory and the worktree's `.git` is a file.
- **Previous run:** [`20261114-153100`](../20261114-153100/) (at `25c3ecd`), the v1.101.0 release
  run.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.102.0`, `git.dirty` is `false`, `git.sha` is
`715b291`, the parent of the commit that adds this bundle, lint, tests and complexity are `pass`,
`complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are 0. **Perf was not
measured**: this repository ships no `tests/perf.lua`, so v1.102.0 was verified across **three**
suites, not four. The band count holds at fifteen; `LibKa0s/Callout.lua` is 1283 inside it, still on
notice and unruled (*Actions*); that is not a gate condition.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261114-153100 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 345 files | [`lint.txt`](lint.txt) | No: 345 files |
| tests | pass | 4627 passed, 3 skipped, 0 failed, 4630 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4629 -> 4630 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | Yes: NLOC 105298 -> 105349, functions 15013 -> 15015 |

| Metric | Value |
|---|---|
| Total NLOC | 105349 |
| Functions | 15015 |
| Avg NLOC / function | 6.9 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.6 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 15 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

Against `20261114-153100` (v1.101.0): this branch's Callout change, L17. Callout minor 4 takes the
owner's Look defaults (Oxanium SemiBold as `FONT_DEFAULT`, the shadow at 1, 1, a black glow at full
intensity, 1 px thick, at 1, -1, `glowCustom` on) and CalloutSettings minor 5 draws no sample line
in the one tab; key 4.5, no member added or removed. Tests 4629 -> 4630 is that change's one new
layout case. NLOC +51 and functions +2 are the Callout files and their re-pinned suites. Lint holds at
345 files and the kit at revision 56.

The merge also moved five test fixtures (`fixture_charts`, `fixture_icon_browser`,
`fixture_skin_picker`, `fixture_media`, `fixture_appearance`) onto the runner's shared loader
(`LK_TEST.loader`). The merged run had crossed the kit's 256 MB leak gate (299 MB after
`test_eol.lua`), where each parent alone stayed a few MB under it. Each private loader held a compiled
copy of every file it loaded for the whole run. No case changed, and the leak peak is now about 225 MB
above the start, measured by hand with `KA0S_KIT_LEAK_MB` and not by this bundle.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Callout.lua` | 1283 | **Grown in the band**: 1277 at v1.100.0 -> 1283 with L17's defaults and their header note, no function added; 17 under the ~1300 split point `CLAUDE.md`'s census names. On notice and unruled, its seam named (the write-route section, or the sound section, to a secondary paired on the shell); the ruling is the lead's (*Actions*) |
| 1000–1500 (on notice) | the other fourteen files of the previous run | see [`../RESULTS.md`](../RESULTS.md) | Carried forward unchanged, `LibKa0s/WaypointArrow.lua` at 1253 among them |

Fifteen, nothing over 1500. `CalloutSettings.lua` (917) stays under the band.

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-11-14, by hand
- **Files reviewed:** none needed
- **Commits since the previous release touching them:** 0 that move a Sim, Widgets or `W.TestStrip` minor
- **Note:** v1.102.0 moves only Callout 4 and CalloutSettings 5, so no host's scenarios or
  test-mode strips are affected.

## Actions

1. Cut the tag `v1.102.0` on the commit that adds this bundle, and merge the branch to master (the
   run's orchestrator's, on the owner's go-ahead, plan row L17). Merging it also brings in v1.101.0,
   whose own branch is not yet on master.
2. **The register's Callout row:** the owner ruled on 2026-11-14 to keep the module and relax
   `library-stack-§7`'s bar 1 (WowAddonStandards v2.109.0, not yet merged). The row retires when
   that merges.
3. **Lead ruling, `LibKa0s/Callout.lua` band row:** 1283, 17 under the ~1300 split point. The next
   Callout change should peel the write-route or sound section to a paired secondary, or the lead
   accepts it with a trigger.
4. Step 8: Ka0s Combat Trail re-vendors this payload. A suite pinning the Callout's `MODULES`
   re-pins 4 and 5; a suite pinning the old Look defaults or a schema row's default re-pins the
   owner's; a suite reading `view.preview` from `layout = "side"` reads nil. No stub changes. The
   same re-vendor carries v1.101.0's WaypointArrow 2 and OptionsWidgets 46.
5. Rule on the standing band triggers before the next tag (carried from the previous runs).
