# Analysis — 20260929-113624

- **Addon:** LibKa0s 1.63.0 (release run, `--release 1.63.0`)
- **Verdict:** green
- **Commit:** ac61f37 (`feat/2026-09-29-smoke-and-profile`), clean
- **Previous run:** 20260929-111323 (1.63.0, release run, at `626aec0`)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.63.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, and `complexity.warnings` is 0. **Perf was not measured**: this repository
ships no `tests/perf.lua`, so v1.63.0 was verified across **three** suites, not four.

This is the v1.63.0 release run taken a **third** time, and the one the tag is cut from. The
previous bundle, `20260929-111323`, measured `626aec0`. The tree then gained `ac61f37`, which
strengthens the profile-list ordering test (`tests/test_slash_profile.lua`: the shared fixture gains
a name that byte order and case-insensitive order place differently). A release record has to
describe the released tree, so the run is taken again from that commit. `20260929-111323` and
`20260929-092750` stay as they were written. This bundle carries `20260929-111323`'s consumer note
forward unchanged, because nothing between the two runs touches the payloads.

**The tag.** When this run was taken, the local, unpushed annotated tag `v1.63.0` pointed at
`c53705c`, the first record commit. That commit's tree carries the consumer guidance `626aec0`
corrected, and its release-gate line cites `20260929-092750`. `docs/releasing.md` step 7 requires
the tag to sit on the commit this bundle's `git.sha` names, or on its child (the record commit), so
`v1.63.0` must be re-pointed at the commit that adds this bundle before it is pushed. Moving the tag
is the owner's call, not this run's. `addonVersion` reads `1.63.0` because a library repo has no TOC
and the runner falls back to the newest tag, which already existed. `release` is the field that
names the version this bundle records.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260929-111323 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 123 files | [`lint.txt`](lint.txt) | No (byte-identical) |
| tests | pass | 1777 passed, 1 skipped, 0 failed, 1778 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No (1778 → 1778) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | NLOC only (36638 → 36639) |

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
`tests/test_prose.lua` runs in its place ([`tests.txt`](tests.txt), line 1). It is counted in the
total and not in `passed`.

**`complexity` sits at the ceiling without crossing it.** Max CCN is exactly 15, reached by the same
six functions as at the previous run ([`complexity.txt`](complexity.txt)): `lib.Catalog`
(`LibKa0s/Bus.lua:358`), `lib.GetSpellCooldown` (`LibKa0s/Compat.lua:243`), `idHelpIcon`
(`LibKa0s/OptionsIdList.lua:459`), `liveTimers` (`testkit/mock_record.lua:95`), `M.__fire`
(`testkit/mock_record.lua:580`) and `audit` (`testkit/test_layout_cap.lua:427`). None warns, since
the threshold is `> 15`. `Sl:ProfileSwitch` (lizard's `Sl@875-908` in `LibKa0s/Slash.lua`) is still
the release's densest new function, at CCN 11.

## What moved

One NLOC. The only commit between the two runs, `ac61f37`, changes `tests/test_slash_profile.lua`
alone (five lines added, two removed): the shared profile fixture gains `alpha`, and the list and
`lib.ProfileNames` pins expect it first. Total NLOC moves 36638 → 36639. The function count, the
averages, max CCN and the band list do not move. No case was added or renamed, so
[`test-cases.md`](test-cases.md) is byte-identical to the previous bundle's and to
`docs/test-cases.md` at HEAD, and [`lint.txt`](lint.txt) is byte-identical to the previous
bundle's. Nothing under `LibKa0s/`, `testkit/` or `tests/_kit/` moved, so the payloads a consumer
copies are the ones `20260929-111323` measured.

`RESULTS.md`'s test section now reads the count as flat at 1778 across the last three runs. All
three measure this one release on successive trees, and 1778 is up from 1748 at `20260926-193105`,
the thirty cases this release added. The flat line is not a stalled suite.

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

Unchanged from `20260929-111323`, whose note stands. A consumer re-vendors both payloads whole
(`libs/LibKa0s/` and `tests/_kit/`) and rolls its provenance line; the kit stays at revision 31.
The copy alone turns the kit's by-name Slash `T.assertSurfaceParity` case red in AbsorbTracker,
AuraMaster, KickCD, PartyFrameEnhanced, PrettyChat and WhatGroup until each degradation stub
carries both `CliProfile` and `ProfileSwitch`, or names the one it lacks in `ignore`. BankLedger,
ConsumableMaster, LootHistory, MultiMeters and PanelMaster stay green.

## Actions

- **Re-point the local `v1.63.0` tag** at the commit that adds this bundle, before any push. The
  owner decides this; the run does not move tags.
- The six consumers named above owe the two stub members, or an ignore entry, in the same commit as
  their re-vendor.
