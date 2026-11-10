# Analysis — 20261110-090851

- **Addon:** LibKa0s 1.95.0 (release run, `--release 1.95.0`)
- **Verdict:** green
- **Commit:** `1266068` (`feat/2026-11-10-quickcomms-forever-emotes`), clean: the last code commit of
  v1.95.0 (`QFE-LK1`, `QFE-LK2` and the `QFE-REV` review fixes of Ka0sAddonsCommonTasks
  `docs/2026-11-10-QUICKCOMMS_FOREVER_EMOTES/`). The release's record (this bundle, its `RESULTS.md`
  row and the changelog's release lines) follows it as one commit, and the tag is cut on that commit.
  The battery ran in the main checkout.
- **Previous run:** [`20261106-191446`](../20261106-191446/) (at `1938837`), v1.91.0's release run.
  v1.92.0, v1.93.0 and v1.94.0 were tagged without a release run, so this is the first measurement
  since v1.91.0 and *What moved* spans four releases.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.95.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.95.0 was verified
across **three** suites, not four.

An earlier release run at `e4493aa` (not committed) found four functions over CCN 15, all from
v1.92.0 / v1.93.0: `lib.New` (Launcher, 16), and the kit's `CG.strip` (19), `CG.scan` (16) and
`CG.judge` (19). `ad603eb` split them with no behavior change (Launcher minor 10, kit revision 54),
which is why v1.95.0 carries those two moves.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261106-191446 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 326 files | [`lint.txt`](lint.txt) | Yes: 313 -> 326 files |
| tests | pass | 4300 passed, 3 skipped, 0 failed, 4303 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4214 -> 4303 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | Yes: NLOC, function count |

| Metric | Value |
|---|---|
| Total NLOC | 97152 |
| Functions | 13898 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Warnings (CCN > 15) | 0 |
| Files over the 1500 cap | 0 |
| Blind files / crashed files | 0 / 0 |

## What moved

Against v1.91.0's run: v1.92.0 and v1.93.0 (the WoW Forever port's library half, with `OptionsHeader`
peeled), v1.94.0 (the per-client default skin and Compat's character identity) and v1.95.0:

- **`LibKa0s-Role-1.0` minor 1**, a new major (`QFE-LK1`): spec, Forever talent groups and the role
  resolution ladder. The review (`QFE-REV`) changed one rule before release: an override is never
  written to `store.last`.
- **DebugLogDiagnostics minor 8** names Role; **Launcher minor 10** and **kit revision 54** are the
  CCN splits above.
- Lint: 313 -> 326 files. Tests: 4214 -> 4303, 29 of them `tests/test_role.lua`'s. The three skips
  are still declared skips, not passes.

## Complexity watch list

### Functions the complexity suite warned on

None.

### Files by `layout-§1` band

Thirteen, nothing over 1500. Two re-check triggers have fired and are owed a ruling before the next
tag; neither is a gate:

- `LibKa0s/Skin.lua` at 1121, past its 1100-line trigger since Skin minor 18 (v1.94.0).
- `tests/test_launcher.lua` at 1235, past its 1200-line trigger (it gained one case here).

## Preview and simulation data

- **Answer:** Not applicable. No Sim or Widgets minor moved, so no host's scenarios or test-mode
  strips are affected.

## Actions

1. Cut the local tag `v1.95.0` on the commit that adds this bundle (it replaces the earlier local
   cut at `e4493aa`, which was never pushed). It is pushed, and the branch merged, only at the
   owner's go-ahead.
2. Step 8: Ka0s Quick Comms re-vendors this payload in this run. Other hosts take it on their own
   schedule; a host suite pinning `Launcher 9`, kit 53 or `DebugLogDiagnostics 7` re-pins.
3. Rule on the two fired band triggers above before the next tag.
