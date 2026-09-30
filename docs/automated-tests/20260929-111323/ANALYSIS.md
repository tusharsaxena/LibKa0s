# Analysis — 20260929-111323

- **Addon:** LibKa0s 1.63.0 (release run, `--release 1.63.0`)
- **Verdict:** green
- **Commit:** 626aec0 (`feat/2026-09-29-smoke-and-profile`), clean
- **Previous run:** 20260929-092750 (1.63.0, release run, at `576576e`)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.63.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, and `complexity.warnings` is 0. **Perf was not measured**: this repository
ships no `tests/perf.lua`, so v1.63.0 was verified across **three** suites, not four.

This is the v1.63.0 release run **re-taken**. The previous bundle, `20260929-092750`, measured
`576576e`, and the tree then gained one documentation-only commit, `626aec0`, which corrects the
release's consumer guidance (see *Consumer note* below). The release record has to describe the
released tree, so the run is taken again from that commit. No Lua byte moved between the two, and
every figure below is identical to the previous run's. `20260929-092750` stays as it was written,
including its consumer note, which this bundle supersedes.

`addonVersion` reads `1.63.0` here where the previous run read `1.62.0`: a library repo has no TOC,
the runner falls back to the newest tag, and the local `v1.63.0` tag existed by the time of this
run. `release` is the field that names the version this bundle records. The run is on the unmerged
rollout branch, not `master`; the tag's placement, the merge and the push wait on the owner.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260929-092750 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 123 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 1777 passed, 1 skipped, 0 failed, 1778 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No (1778 → 1778) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | No |

| Metric | Value |
|---|---|
| Total NLOC | 36638 |
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

Nothing measured. The one commit between the two runs, `626aec0`, touches five Markdown files
(`CHANGELOG.md`, `docs/releasing.md`, `docs/api/README.md` and the Slash version-16 and version-17
documents) and none of the linted, tested or measured files. [`test-cases.md`](test-cases.md) is
byte-identical to the previous bundle's and to `docs/test-cases.md` at HEAD.

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

A consumer re-vendors both payloads whole (`libs/LibKa0s/` and `tests/_kit/`) and rolls its
provenance line. The kit stays at revision 31. **This corrects the previous bundle's note**, which
said nothing moves unless a consumer wires the verb.

**The copy alone turns one test red in six consumers.** A suite that runs the kit's by-name
`T.assertSurfaceParity(<stub>, "LibKa0s-Slash-1.0", ignore)` compares its Slash degradation stub
against `Kit.publicMembers` of the live dispatcher instance its runner registered with
`Kit.setSurfaceSource`. It does not read the member manifest (`members-17.json` lists only the
lib-level table). That instance now carries `CliProfile` and `ProfileSwitch`, so the case fails with
`CliProfile is missing (live: function); ProfileSwitch is missing (live: function)` until the stub
carries **both**, each printing the library-absent line, or names the one it does not carry in the
call's `ignore` list. Whether the host wires the verb does not change this.

Measured on 2026-09-29 by cloning each consumer's `master` into a scratch directory (all eleven green
before the drop-in), copying in the v1.63.0 payloads and moving the provenance line:
AbsorbTracker, AuraMaster, KickCD, PartyFrameEnhanced, PrettyChat and WhatGroup each fail exactly
that case and nothing else. BankLedger, ConsumableMaster, LootHistory, MultiMeters and PanelMaster
stay green, because their Slash parity case compares two tables they build themselves, or they have
none. Wiring the verb (a `profiles` descriptor field, a `profile` COMMANDS row calling
`CliProfile`, `"profile"` in the host's own `liveVerbs`) is each consumer's own rollout item.

## Actions

None in this repository. The six consumers named above owe the two stub members, or an ignore entry,
in the same commit as their re-vendor.
