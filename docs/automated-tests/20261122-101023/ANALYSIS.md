# Analysis — 20261122-101023

- **Addon:** LibKa0s 1.110.0 (release run, `--release 1.110.0`; `addonVersion` reads 1.109.0, the tag
  the runner's `git describe` found nearest this commit, and `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `8deb4b09` (`feat/2026-11-22-libka0s-101`), clean: the whole v1.110.0 release but its
  own record. The record (this bundle, its `RESULTS.md` row and the changelog's release-gate and
  re-look lines) follows as one commit, and the local tag `v1.110.0` is cut on it.
- **Previous run:** [`20261121-214308`](../20261121-214308/) (at `0641ef5`, the v1.109.0 release record)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.110.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.110.0 was verified
across **three** suites, not four.

Since v1.109.0 the release adds Compat minor 6 (the container groups and bank readers, LibKa0s#101)
and test kit revision 60 (each client profile's `Enum.BagIndex`, `Enum.BankType` and
`C_Bank.CanViewBank`), so lint gains one file and the suite 39 cases. Nothing to act on in the
library; the actions below are the release's own next steps.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261121-214308 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 383 files | [`lint.txt`](lint.txt) | Files 382 -> 383; still 0/0 |
| tests | pass | 5115 passed, 3 skipped, 0 failed, 5118 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Total 5079 -> 5118 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | Totals grew; averages flat |

| Metric | Value |
|---|---|
| Total NLOC | 114347 |
| Functions | 16439 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.7 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 11 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

The suite was also run under `KA0S_KIT_CLIENT=forever` on the same tree, outside the runner: 5115
passed, 0 failed, 3 skipped, 5118 total.

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

- **Payload:** one file changed, `LibKa0s/Compat.lua` 5 -> 6 (683 lines), adding `ContainerGroups`,
  `CONTAINER_PATTERNS_BY_CLIENT`, `CanViewCharacterBank`, `NumPurchasedBankTabs`, `BankerKind` and
  `UnreadyBankContainers`. The kit moved 59 -> 60 (`testkit/mock_client.lua`), re-copied into
  `tests/_kit/`. No `NEEDS_*` floor rises and no member is removed.
- **Contract changes:** additive. Compat key 6 has its document and members manifest; the version 5
  document is Superseded with its *Moving to version 6* section. The testkit version 60 document is
  Current and 59 Superseded.
- **Lint:** 382 -> 383 files, the new suite `tests/test_compat_containers.lua`; still 0/0.
- **Tests:** 5079 -> 5118 (+39). The new suite carries the three consumer copies' cases,
  `tests/test_compat.lua` re-pins minor 6 and twenty-three members, and `tests/test_mock_client.lua`
  covers the profiles' bank shape. The three skips are unchanged, declared skips, not passes.
- **Complexity:** NLOC 113699 -> 114347 and functions 16329 -> 16439, the new readers and cases.
  Average NLOC (6.8) and CCN (2.1) are flat and average tokens moved 60.8 -> 60.7, so the addon grew
  without getting denser. Max CCN is still 15, with 0 warnings.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | the eleven files [`../RESULTS.md`](../RESULTS.md) lists | see there | Eleven, nothing over 1500, the same eleven as the previous run, each disposition carried. `Compat.lua` (683) is not in the band. |

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-11-22, by hand
- **Files reviewed:** none needed. The release moved no minor of `Sim.lua`, `SimTimeline.lua`,
  `SimPanel.lua`, `SimPanelRender.lua` or `Widgets.lua` (the file that defines `W.TestStrip`).
- **Commits since the previous release touching them:** 0
- **Note:** only `Compat.lua` and the test kit moved. A host's Sim seam wraps its own Compat table, so
  the new Compat members do not change any scenario or test-mode strip, and step 8 lists no host for
  a re-look.

## Actions

1. Cut the local tag `v1.110.0` on the record commit. Pushing it, merging to `master` and the
   re-vendor wait on the owner's go-ahead (Ka0sAddonsCommonTasks
   `docs/2026-11-22-LIBKA0S_101_CONTAINER_READER/`, lead's call 7).
2. Re-vendor Bank Ledger, Loot History and Outfitter Reborn (step 8, the run's adoption items). Re-pin
   `Compat 5` and `KIT_VERSION` 59 where a host pins them, and wire the six Compat members or list them
   in `ignore` where a host checks `Kit.assertSurfaceParity` on `LibKa0s-Compat-1.0`.
