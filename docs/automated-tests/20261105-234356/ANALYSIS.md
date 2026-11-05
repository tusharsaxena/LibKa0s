# Analysis — 20261105-234356

- **Addon:** LibKa0s 1.89.0 (release run, `--release 1.89.0`; the manifest's `addonVersion` reads
  1.88.0 because it is taken from the newest tag, and `v1.89.0` is cut after this bundle)
- **Verdict:** green
- **Commit:** `f11b9c0` (`feat/2026-11-05-kit-unregister-guard`), clean: the release's pointers and
  consumer sweep, with nothing but this record after it. The battery ran in the main checkout.
- **Previous run:** [`20261105-064630`](../20261105-064630/) (at `1fdaed5`), v1.88.0's release run,
  which is also the baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.89.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.89.0 was verified
across **three** suites, not four. Nothing to act on before the tag.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261105-064630 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 306 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 4197 passed, 3 skipped, 0 failed, 4200 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4199 -> 4200 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: NLOC and function count only |

| Metric | Value |
|---|---|
| Total NLOC | 93505 |
| Functions | 13463 |
| Avg NLOC / function | 6.9 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.2 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 16 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

Perf is the one suite that is not a clean pass: a standing skip, because the library ships no
offline scenarios (see *Perf* in `RESULTS.md`). It is not measured, not passed.

## What moved

Against [`20261105-064630`](../20261105-064630/) (v1.88.0): the test kit's unregister guard, for a
flake Outfitter Reborn's `tests/test_bar.lua` profile-switch case hit about one run in six.

- **Test kit revision 51** (`367a9f1`): `testkit/mock_ace.lua`'s `Callbacks:unregister` and
  `Callbacks:unregisterAll` clear a target's entry, live and queued, only where one exists, as
  CallbackHandler-1.0 does. Re-vendored into `tests/_kit/`. No file under `LibKa0s/` moved and no
  LibStub minor or major key changed.
- **Docs only** (`f11b9c0`): the release guide, the README's kit line, the API index and the
  version 51 document; no code.
- Lint: 306 files, unchanged (no file added).
- Tests: 4199 -> 4200, one case more, `tests/test_mock_ace.lua`'s *unregistering targets that hold
  no registration leaves a send in flight intact* (39 -> 40 cases, per [`test-cases.md`](test-cases.md)).
  It failed with `invalid key to 'next'` before the guard and passes after it. `test_kit_inventory`'s
  revision case is renamed *the kit is revision 51*, so its count holds. The three skips are
  v1.88.0's, still declared skips, not passes.
- Complexity: 93469 -> 93505 NLOC and 13460 -> 13463 functions (the new case's closures); avg NLOC
  6.8 -> 6.9 by rounding, avg CCN 2.1 and avg tokens 60.2 unchanged. The guard moves
  `Callbacks.unregister` from CCN 8 to 10 and `Callbacks.unregisterAll` from 9 to 11, both counted
  twice (`testkit/` and `tests/_kit/`), both under 15.

## Complexity watch list

### Functions the complexity suite warned on

None.

### Files by `layout-§1` band

Sixteen, nothing over 1500, the same sixteen as v1.88.0. `testkit/mock_ace.lua` (820 lines) and
`tests/test_mock_ace.lua` (737) stay out of the band. `tests/test_toast.lua` (1302) is still
unruled and `LibKa0s/Widgets.lua` (1249) still has a blank Disposition: standing gaps for the
lead, not something this release introduced.

## Preview and simulation data

- **Answer:** Not applicable
- **Files reviewed:** no `Sim.lua`, `SimTimeline.lua`, `SimPanel.lua`, `SimPanelRender.lua` or
  `Widgets.lua` minor moved (`git diff --stat 3555d43 f11b9c0 -- LibKa0s/` names no file), so step
  5's re-look has nothing to re-read and names no hosts.

## Actions

1. Tag `v1.89.0` on the commit that adds this bundle, then merge to `master`.
2. Step 8: Outfitter Reborn re-vendors from the tag first (its `tests/test_bar.lua` flake); every
   other host takes v1.89.0 at its next re-vendor, since no library surface moved.
3. `tests/test_toast.lua`'s band entry and `LibKa0s/Widgets.lua`'s blank Disposition remain the
   lead's rulings.
