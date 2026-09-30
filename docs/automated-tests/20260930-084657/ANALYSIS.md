# Analysis — 20260930-084657

- **Addon:** LibKa0s 1.63.0 (release run, `--release 1.63.0`)
- **Verdict:** green
- **Commit:** 06cc010 (`feat/2026-09-29-smoke-and-profile`), clean
- **Previous run:** 20260929-113624 (1.63.0, release run, at `ac61f37`)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.63.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, and `complexity.warnings` is 0. **Perf was not measured**: this repository
ships no `tests/perf.lua`, so v1.63.0 was verified across **three** suites, not four.

This is the v1.63.0 release run taken a **fourth** time, and the one the tag is cut from. The tag
was never published, and on 2026-09-30 the owner folded **kit revision 32** into this release: a
README-only correction (`testkit/README.md` counted ten consumers and twelve copies; there are
eleven and thirteen) plus `Kit.VERSION` 31 → 32, in `06cc010`. The commit between the two runs,
`a05ae00`, is the rollout's doc sync and touches no payload file. A release record has to describe
the released tree, so the run is taken again. Earlier bundles stay as they were written.

**The tag.** When this run was taken the local, unpushed annotated `v1.63.0` pointed at `dd7a774`,
the previous record commit. `docs/releasing.md` step 7 requires the tag to sit on the commit this
bundle's `git.sha` names or on its child (the record commit), so `v1.63.0` is re-pointed at the
commit that adds this bundle, on the owner's instruction to fold revision 32 in.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260929-113624 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 123 files | [`lint.txt`](lint.txt) | No (byte-identical) |
| tests | pass | 1777 passed, 1 skipped, 0 failed, 1778 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | One case renamed (1778 → 1778) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | No (byte-identical) |

| Metric | Value |
|---|---|
| Total NLOC | 36639 |
| Functions | 5099 |
| Avg NLOC / function | 6.6 |
| Avg CCN | 2.0 |
| Max CCN | 15 |
| Avg tokens / function | 51.7 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 10 |
| Files over the 1500 cap | 0 |

**`perf` was not measured.** The manifest's `skipReason` is *no tests/perf.lua — this addon ships no
offline scenarios*: `automated-tests-§3`'s first sanctioned reason, nothing to run. It is a known
hole in this repository's gate, not a pass, and the `CHANGELOG.md` block says so in its
release-gate line.

**`tests` carries one skip**, the same one as the previous run: the kit's own
`tests/_kit/test_prose.lua` is declined under `CLAUDE.md`'s `localization-§5` deviation row and
`tests/test_prose.lua` runs in its place ([`tests.txt`](tests.txt), line 1).

**`complexity` is byte-identical to the previous run's**: max CCN 15, reached by the same six
functions, none warned on.

## What moved

One case name. `tests/test_kit_inventory.lua`'s pin reads "the kit is revision 32" where it read
"the kit is revision 31", so [`test-cases.md`](test-cases.md) and [`tests.txt`](tests.txt) each
differ from the previous bundle's in that one line. `testkit/framework.lua` changes only its
`Kit.VERSION` line, which lizard does not count as a function, and `testkit/README.md` is prose, so
[`complexity.txt`](complexity.txt) and [`lint.txt`](lint.txt) are byte-identical to the previous
bundle's. Nothing under `LibKa0s/` moved.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua`, `LibKa0s/Perf.lua`, `LibKa0s/Widgets.lua`, `testkit/mock_base.lua`, `tests/test_options.lua`, `tests/test_schema.lua` | 1261, 1193, 1358, 1293, 1422, 1319, 1266, 1454, 1339, 1335 (unchanged) | Carried forward verbatim in `RESULTS.md`; no entry is new, so no cell is blank. |

## Consumer note

`20260929-111323`'s note stands, with one change: the kit is now **revision 32**. A consumer
re-vendors both payloads whole (`libs/LibKa0s/` and `tests/_kit/`), rolls its provenance line, and
moves any `kit revision 31` citation in its own prose to 32. A consumer that already took v1.63.0 at
`dd7a774` owes only the `tests/_kit/` copy (`README.md` and `framework.lua` differ), since its
vendor-sync case compares against the tag. The Slash stub guidance (`CliProfile` and
`ProfileSwitch`) is unchanged.

## Actions

- Re-point the local `v1.63.0` tag at the commit that adds this bundle (owner-approved 2026-09-30).
- Re-vendor `tests/_kit/` in the eleven consumers.
