# Analysis — 20260924-234934

- **Addon:** LibKa0s 1.57.0 → 1.58.0 (release run, `--release 1.58.0`)
- **Verdict:** green
- **Commit:** 02999d0 (`feat/2026-09-23-review-audit-remediation`), clean
- **Previous run:** 20260924-225548 (1.56.0 → 1.57.0)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.58.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, and `complexity.warnings` is 0. **Perf was not measured**: this repository
ships no `tests/perf.lua`, so v1.58.0 was verified across **three** suites, not four. The run
measured one change, `LibKa0s-Launcher-1.0` minor 4 (left-click opens settings, right-click opens
the options menu, `LK-37`), and there are 4 more cases than at v1.57.0's release run. Nothing to
act on in this repository.

`addonVersion` reads `1.57.0` because a library repo has no TOC and the runner falls back to the
newest tag; `release` is the field that names the version this bundle records.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260924-225548 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 93 files | [`lint.txt`](lint.txt) | +1 file (92 → 93), still 0/0 |
| tests | pass | 1665 passed, 1 skipped, 0 failed, 1666 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | +4 cases (1662 → 1666) |
| perf | skip | not measured — no `tests/perf.lua` | — | No. |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Totals up, averages flat |

| Metric | Value |
|---|---|
| Total NLOC | 34110 |
| Functions | 4787 |
| Avg NLOC / function | 6.6 |
| Avg CCN | 2.0 |
| Max CCN | 15 |
| Avg tokens / function | 51.8 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 13 |
| Files over the 1500 cap | 2 |

**`perf` was not measured.** The manifest's `skipReason` is *no tests/perf.lua — this addon ships no
offline scenarios*: `automated-tests-§3`'s first sanctioned reason, nothing to run. It is a known
hole in this repository's gate, not a pass, and the `CHANGELOG.md` block says so in its
release-notes line.

**`tests` carries one skip**, the same one as the previous run: the kit's own
`tests/_kit/test_prose.lua` is declined under `CLAUDE.md`'s `localization-§5` deviation row and
`tests/test_prose.lua` runs in its place ([`tests.txt`](tests.txt), line 1). It is counted in the
total and not in `passed`.

## What moved

- **lint**: 92 → 93 files, 0/0. The new file is `tests/mock_menu.lua`, the headless stand-in for
  the client's context-menu API; `.luacheckrc` gains `MenuUtil` and `MenuResponse` as read globals.
- **tests**: 1662 → 1666. `tests/test_launcher.lua` gains fifteen cases and loses eleven: the
  minor-2 and minor-3 cases that pinned the left-click rungs, the disabled refusal, the rung hints
  and `disabledLine`'s requirement are replaced, because minor 4 retires those contracts. Among the
  fifteen are a 16-cell matrix of the four accessor-and-toggle pairs present or absent, and the
  tooltip's 36-cell matrix, now over retired fields passed or not in place of the rung
  ([`test-cases.md`](test-cases.md)).
- **complexity**: NLOC 33910 → 34110 and functions 4766 → 4787; avg NLOC 6.6 and avg CCN 2.0 do not
  move, avg tokens 51.7 → 51.8, max CCN stays 15 with 0 warnings. The growth is the menu's small
  closures in `LibKa0s/Launcher.lua` (443 → 512 lines), `tests/mock_menu.lua` (103) and the new
  cases in `tests/test_launcher.lua` (863 → 974). Band and over-cap counts are unchanged (13 and 2).

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None warned on at this run.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | the thirteen files in `RESULTS.md` | unchanged | Carried forward; no file entered or left the band and none moved. |
| > 1500 (over cap) | `LibKa0s/OptionsWidgets.lua`, `tests/test_options_widgets.lua` | 3852, 4086 | Carried forward (census rows #32, #33). |

No entry is new, so no Disposition cell in `RESULTS.md` is blank: the runner carried every one
forward verbatim, and this release touches none of the files they name.

## Consumer note for the M6 re-vendors

This payload changes what every host's launcher does on a click without the host adopting anything:
left-click opens the settings panel on every host in either state, so a rung (a)/(b) `onClick` stops
running and the disabled refusal no longer prints; right-click still opens the panel until the host
passes an accessor-and-toggle pair; and the tooltip's hints read `Open settings` / `Options menu`.
A read-only grep of the eleven working trees (2026-09-24) finds launcher clicks driven in every
consumer's `tests/test_launcher.lua` (MultiMeters: `tests/test_launchersetup.lua`) and in every
`tests/test_disabled.lua`, plus AuraMaster `tests/test_slash_verbs.lua`, LootHistory
`tests/test_panel.lua`, MultiMeters `tests/test_degraded.lua` and WhatGroup
`tests/test_frame_secure.lua`. Assertions on a left click's action, on the refusal line or on
minor 3's hints move with each M6 item, which also wires the pairs and deletes the retired fields.
A consumer test of the menu itself needs a `MenuUtil` fake of its own: the kit does not ship one.

## Actions

None in this repository. The re-vendors and host adoptions are the M6 items, one per consumer.
