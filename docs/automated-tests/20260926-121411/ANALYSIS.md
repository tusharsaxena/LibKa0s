# Analysis — 20260926-121411

- **Addon:** LibKa0s 1.60.0 → 1.61.0 (release run, `--release 1.61.0`)
- **Verdict:** green
- **Commit:** 7cbe02c (`feat/2026-09-26-settings-redesign`), clean
- **Previous run:** 20260926-034006 (1.59.0 → 1.60.0)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.61.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, and `complexity.warnings` is 0. **Perf was not measured**: this repository
ships no `tests/perf.lua`, so v1.61.0 was verified across **three** suites, not four. The run
measured the library's half of the Ka0s WoW Addon Standard v2.69.0's nav rail (`options-ui-§13`,
`options-ui-§14`): `Options.lua` minor 25, `OptionsTabs.lua` minor 5 and the new `OptionsNav.lua`
minor 1 (`LibKa0s-Options-1.0` 25.31.5.7.4.1). The kit stays at revision 27. There are 15 more
cases than at v1.60.0's release run. Nothing to act on in this repository.

`addonVersion` reads `1.60.0` because a library repo has no TOC and the runner falls back to the
newest tag; `release` is the field that names the version this bundle records. The run is on the
unmerged feature branch, not `master`: v1.61.0 is tagged locally on that branch and waits on the
owner's go-ahead for the merge and the push.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260926-034006 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 100 files | [`lint.txt`](lint.txt) | +2 files (98 → 100), still 0/0 |
| tests | pass | 1744 passed, 1 skipped, 0 failed, 1745 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | +15 cases (1730 → 1745) |
| perf | skip | not measured — no `tests/perf.lua` | — | No. |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Totals up, avg NLOC 6.5 → 6.6 and avg tokens 51.6 → 51.7, avg CCN flat |

| Metric | Value |
|---|---|
| Total NLOC | 35854 |
| Functions | 5039 |
| Avg NLOC / function | 6.6 |
| Avg CCN | 2.0 |
| Max CCN | 15 |
| Avg tokens / function | 51.7 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 13 |
| Files over the 1500 cap | 2 |

**`perf` was not measured.** The manifest's `skipReason` is *no tests/perf.lua — this addon ships no
offline scenarios*: `automated-tests-§3`'s first sanctioned reason, nothing to run. It is a known
hole in this repository's gate, not a pass, and the `CHANGELOG.md` block says so in its
release-gate line.

**`tests` carries one skip**, the same one as the previous run: the kit's own
`tests/_kit/test_prose.lua` is declined under `CLAUDE.md`'s `localization-§5` deviation row and
`tests/test_prose.lua` runs in its place ([`tests.txt`](tests.txt), line 1). It is counted in the
total and not in `passed`.

## What moved

- **lint**: 98 → 100 files, still 0/0 ([`lint.txt`](lint.txt)). The two new files are both inside
  the checked set: `LibKa0s/OptionsNav.lua` and `tests/test_options_nav.lua`.
- **tests**: 1730 → 1745 ([`test-cases.md`](test-cases.md)). The new suite
  `tests/test_options_nav.lua` carries 14 of the 15: the rail's drawing and pool, the one inset the
  strip, the content panel and the scroll read, the zero-width first render, the probe's alignment
  with the drawn selected tab, and a page with no rail laid out as at v1.60.0.
  `tests/test_options_combat.lua` gains one (32 → 33), "combat: REGEN_DISABLED covers a page's nav
  rail, and a rail click in combat is refused". Every other suite's count is unchanged.
- **complexity**: NLOC 35354 → 35854 and functions 4975 → 5039; avg NLOC 6.5 → 6.6 and avg tokens
  51.6 → 51.7, avg CCN stays 2.0, max CCN stays 15 with 0 warnings. The growth is the new
  `LibKa0s/OptionsNav.lua` (271 lines) and its suite, neither of which is in the band. Band and
  over-cap counts are unchanged (13 and 2).

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None warned on at this run.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | the eleven other files in `RESULTS.md` | unchanged | Carried forward; no file entered or left the band. |
| 1000–1500 (on notice) | `LibKa0s/Options.lua` | 1457 → 1462 | Carried forward. Under its re-check trigger (the next member added, or 1475 lines): minor 25 adds no `O.*` member, only the guarded inset read in `anchorScroll`. |
| 1000–1500 (on notice) | `LibKa0s/OptionsTabs.lua` | 1489 → 1493 | Carried forward. Under its re-check trigger (the next member added, or 1495 lines): minor 5 adds no member, only the guarded inset reads in `placeTabs` and `drawContentPanel`; `O.NavRail` went to the new `OptionsNav.lua`, as the ruling requires. |
| > 1500 (over cap) | `LibKa0s/OptionsWidgets.lua`, `tests/test_options_widgets.lua` | 3852, 4086 | Carried forward (census rows #32, #33). |

No entry is new, so no Disposition cell in `RESULTS.md` is blank: the runner carried every one
forward verbatim and re-measured the two LOC figures above.

## Consumer note

The `CHANGELOG.md` block's consumer section lists what a host owes on the v1.61.0 re-vendor: the
copy (the kit bytes are unchanged at revision 27), the provenance line, and a `NavRail` no-op in an
Options degradation stub pinned by name. Only AuraMaster takes v1.61.0 now, on its unmerged
`feat/2026-09-26-settings-redesign` (the settings redesign's SR-AM-01). The other ten consumers stay
on v1.60.0 until they take the rail or a later release.

## Actions

None in this repository. AuraMaster's re-vendor is SR-AM-01.
