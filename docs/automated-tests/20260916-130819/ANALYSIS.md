# Analysis — 20260916-130819

- **Addon:** LibKa0s 1.38.0 → **1.39.0** (the release run for that tag)
- **Verdict:** green
- **Commit:** c9c0e5f7c1d3d9aa69a6c85e2f512297b83eb50b (master), clean
- **Previous run:** 20260916-093057

## Headline

Both gating suites pass: `luacheck` is 0/0 over **61** files and the headless harness runs **1069**
cases with nothing failed and nothing skipped. `perf` is a `skip` — this repo ships no
`tests/perf.lua`, so the run says nothing at all about runtime cost, and at the release gate that is
**NOT EVALUATED** rather than passed. `complexity` warns on nothing: max CCN is 14 across 3008
functions, one under the threshold, exactly as it has been for the last eleven runs.

This is a **release** run and the tree it measured is the tree being tagged, which is the shape
`docs/releasing.md` step 7 asks for and which twenty-eight of this library's first twenty-nine
bundles did not have.

Three things landed in one payload, deliberately: each consumer re-vendors the whole folder, so two
releases would mean eleven repos re-vendoring twice and eleven chances to end up on a mismatched
pair.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260916-093057 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 61 files | [`lint.txt`](lint.txt) | +4 files (57 → 61), still 0/0. |
| tests | pass | 1069 passed, 0 skipped, 0 failed | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | +25 cases (1044 → 1069). |
| perf | skip | 0 scenarios — no `tests/perf.lua` | *(no artifact — the suite did not run)* | No change — a permanent skip, as on every run in `RESULTS.md`. |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | +515 NLOC, +79 functions; every average and the max unmoved. |

**Complexity metrics** (all from [`manifest.json`](manifest.json) `suites.complexity`, which mirrors
[`complexity.txt`](complexity.txt)'s footer):

| Metric | Value | 20260916-093057 |
|---|---|---|
| Total NLOC | 21193 | 20678 |
| Functions | 3008 | 2929 |
| Avg NLOC / function | 6.5 | 6.5 |
| Avg CCN | 2.0 | 2.0 |
| Max CCN | 14 | 14 |
| Avg tokens / function | 51.7 | 51.9 |
| Warnings (CCN > 15) | 0 | 0 |
| Warning rate | 0.00 fun / 0.00 nloc | 0.00 / 0.00 |
| Files in 1000–1500 band | 7 | 7 |
| Files over 1500 cap | 2 | 2 |

**`perf` — skip, not pass.** Runtime cost was **not measured** in this run. The library ships no
offline scenario file, so there was nothing for the runner to execute; `manifest.json` records
`"skipReason": "no tests/perf.lua — this addon ships no offline scenarios"` and `"scenarios": 0`.
This is `automated-tests-§3`'s *nothing to run* reason, not a ratified `performance-§12` exemption.
Nothing in this bundle supports a claim that LibKa0s is fast or cheap at runtime — and that is worth
repeating **at a release**, because this release adds a click handler that runs inside the client's
own dispatch and a broker object a display may poll.

## What moved

**+4 linted files, +25 cases, +515 NLOC, +79 functions**, and not one of the four complexity
averages moved. Three changes:

1. **`LibKa0s/Launcher.lua`** (new major, 120 NLOC / 12 functions, avg CCN 4.9). The densest new
   file per function in the payload, and the density is real: `Register` walks two optional library
   lookups and a table resolution with a named degradation at each, which is four branches that all
   have to be there. No function in it warns; the file's worst is well under the threshold.
2. **`LibKa0s/OptionsTabs.lua`** (422 NLOC / 44 functions, avg CCN 4.3) and the 900 lines it took
   out of `LibKa0s/OptionsWidgets.lua` (2181 → 1671 NLOC). This is the only part of the run where
   NLOC moved between files rather than into them, and it is worth reading as one number: the two
   files together are within a few lines of what the one file was, because the peel is a move.
3. **`tests/test_options_tabs.lua`** (514 NLOC / 85 functions, avg CCN 1.4) and the 36 cases it took
   whole out of `tests/test_options_widgets.lua`. The repository's case total is **1069 before the
   peel and 1069 after**; `test_options_widgets.lua` carried 221 alone and the pair carries 185 + 36.

The +25 cases are the three `MasterControls` `minimapPath` cases and the twenty-two
`LibKa0s-Launcher-1.0` cases. The peel added none, which is the point of moving cases whole.

## Complexity watch list

**Functions `lizard` warned on:**

None. Max CCN across all 3008 functions is 14, one under the threshold, and the warning rate is 0.00
on both the function and NLOC measures.

**Files by layout band:**

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua` | 1312 | Accepted, carried. 1307 → 1312 this release, from the guarded `__AttachTabs` call and the header rewrite. Still 38 lines under its own 1350 re-check. No function in the file warns. |
| 1000–1500 (on notice) | `LibKa0s/Perf.lua` | 1231 | Already tracked as [`#7`](https://github.com/tusharsaxena/LibKa0s/issues/7). Unmoved this release. |
| 1000–1500 (on notice) | `LibKa0s/Widgets.lua` | 1232 | **Accepted, and past its shelf life**, unchanged since the v1.27.0 release run. Carried from `20260916-093057`, where it was already flagged; this release did not touch it and did not fix it. Owed a tracked ID with an owner, or a peel. |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1499 | On notice, one line from breach, carried unchanged — the kit did not move this release. Its own rule stands: the next kit change that adds anything peels first or opens an issue naming the seam. |
| 1000–1500 (on notice) | `tests/test_options.lua` | 1303 | **Accepted past its shelf life**, carried. The "owed a tracked ID" note has now run since v1.8.3. |
| 1000–1500 (on notice) | `tests/test_slash.lua` | 1054 | Accepted, carried. Its `automated-tests-§4` clock started at v1.34.0 and has one release left to run. |
| 1000–1500 (on notice) | `tests/test_widgets.lua` | 1493 | **Accepted, seven lines from breach — the sharpest item in this bundle, and it was the sharpest item in the last one too.** The next case added to it breaches `layout-§1`. This release peeled two other files and left this one where it was. |
| > 1500 (over cap) | `LibKa0s/OptionsWidgets.lua` | 2812 | **3700 → 2812 this release.** [`#16`](https://github.com/tusharsaxena/LibKa0s/issues/16) is closed — its seam, the tab and page chrome, is now `LibKa0s/OptionsTabs.lua` (973). The file is still over the cap, so the census row stays, retargeted at the id surface as [`#32`](https://github.com/tusharsaxena/LibKa0s/issues/32). |
| > 1500 (over cap) | `tests/test_options_widgets.lua` | 3219 | **3997 → 3219 this release**, 36 cases to `tests/test_options_tabs.lua` (842). [`#8`](https://github.com/tusharsaxena/LibKa0s/issues/8) is closed; the row stays, retargeted as [`#33`](https://github.com/tusharsaxena/LibKa0s/issues/33), which records that the id cases alone do **not** clear the cap here and that the further cut is chosen after #32 rather than guessed at now. |
| under 1000 (new) | `LibKa0s/OptionsTabs.lua` | 973 | New this release and clear of the band. Named so a reader can see the peel landed with headroom rather than one edit from its own disposition. |
| under 1000 (new) | `tests/test_options_tabs.lua` | 842 | Same. |

`lizard` counts every `and`/`or` short-circuit as a decision, so in Lua a run of `t.k = rec.k or D.k`
defaulting lines scores high with no visible branching. `LibKa0s/Launcher.lua` (4.9) and
`LibKa0s/OptionsTabs.lua` (4.3) are the two densest files in the payload by that measure, and in both
cases a read of the source says the density is guards that have to exist: an optional library that
may be absent, a texture call a headless mock answers inertly, a frame that has no width until the
canvas lays itself out.

## Actions

1. `tests/test_widgets.lua` (1493 LOC) — **carried for a third release.** Open a tracked issue naming
   the split seam before the next case lands, since that case breaches `layout-§1`. The stated
   pairing rule says it splits when `LibKa0s/Widgets.lua` splits, so the issue should record that
   dependency rather than propose an independent peel.
2. `LibKa0s/Widgets.lua` (1232 LOC), `tests/test_options.lua` (1303 LOC) — both still carried as a
   bare **Accepted** past `automated-tests-§4`'s three-consecutive-release shelf life. Each is owed
   either a peel or a tracked deviation ID with an owner.
3. `testkit/mock_base.lua` (1499 LOC) — its trigger is live: the next kit revision that adds a line
   breaches the cap.
4. `perf` — decide which it is: add `tests/perf.lua` scenarios, or ratify a `performance-§12`
   no-combat-path exemption. This release is a good prompt for the first of those, because it added
   a click handler on the client's own dispatch path.
5. **Step 8 of `docs/releasing.md` is outstanding and is bigger than a re-vendor.** Eleven consumers
   take this payload, and adopting `LibKa0s-Launcher-1.0` is `launcher-§5`'s five-step changeset per
   addon — vendor LibDataBroker-1.1 and LibDBIcon-1.0, generate the 128×128 logo, build the object,
   declare `minimapPath`, record the rung in `ADDONS.md` — with a `db.profile.minimap` →
   `db.global.minimap` migration for Multi Meters alone. **An addon that adopts the launcher without
   the logo ships a button that draws nothing**, which is worse than the state before it adopted.
