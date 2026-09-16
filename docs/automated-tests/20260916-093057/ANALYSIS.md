# Analysis — 20260916-093057

- **Addon:** LibKa0s 1.38.0
- **Verdict:** green
- **Commit:** 5fceda5dbb36031d72bc5d400e0bc144814c5a33 (master), clean
- **Previous run:** 20260916-033929

## Headline

Both gating suites pass: `luacheck` is 0/0 over 57 files and the headless harness runs 1044 cases
with nothing failed and nothing skipped. `perf` is a `skip` — this repo ships no `tests/perf.lua`,
so the run says nothing at all about runtime cost. Every figure in this bundle is identical to
`20260916-033929`, which is the expected result: that run recorded the same commit's tree and
nothing has landed since, so this run is a reproduction check rather than a new measurement. The
only live action items are carried, not new: `tests/test_widgets.lua` sits seven lines under the
`layout-§1` cap, and three watch-list entries have now been carried as **Accepted** well past
`automated-tests-§4`'s three-release shelf life without a tracked ID.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260916-033929 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 57 files | [`lint.txt`](lint.txt) | No change — 0/0 over 57 files in both runs. |
| tests | pass | 1044 passed, 0 skipped, 0 failed | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No change — 1044/0/1044 in both runs; the two files diff clean. |
| perf | skip | 0 scenarios — no `tests/perf.lua` | *(no artifact — the suite did not run)* | No change — a permanent skip, as on every run in `RESULTS.md`. |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | No change — the two `complexity.txt` files diff clean. |

**Complexity metrics** (all from [`manifest.json`](manifest.json) `suites.complexity`, which mirrors
[`complexity.txt`](complexity.txt)'s footer):

| Metric | Value |
|---|---|
| Total NLOC | 20678 |
| Functions | 2929 |
| Avg NLOC / function | 6.5 |
| Avg CCN | 2.0 |
| Max CCN | 14 |
| Avg tokens / function | 51.9 |
| Warnings (CCN > 15) | 0 |
| Warning rate | 0.00 fun / 0.00 nloc |
| Files in 1000–1500 band | 7 |
| Files over 1500 cap | 2 |

**`perf` — skip, not pass.** Runtime cost was **not measured** in this run. The library ships no
offline scenario file, so there was nothing for the runner to execute; `manifest.json` records
`"skipReason": "no tests/perf.lua — this addon ships no offline scenarios"` and `"scenarios": 0`.
This is `automated-tests-§3`'s *nothing to run* reason, not a ratified `performance-§12` exemption,
and it blocks a release gate until either a scenario file exists or the exemption is ratified.
Nothing in this bundle supports a claim that LibKa0s is fast or cheap at runtime.

## What moved

Nothing. `20260916-033929` and this run measured the same commit with the same toolchain
(Lua 5.1.5, Luacheck 1.2.0, lizard 1.24.0) and produced byte-identical `lint.txt`, `tests.txt` and
`complexity.txt`. Reading further back in [`RESULTS.md`](../RESULTS.md), the last run that actually
moved anything was `20260916-015507` → `20260916-033929`: +2 cases (1042 → 1044), +20 NLOC
(20658 → 20678) and +2 functions (2927 → 2929), from the v1.38.0 bare-slash work. The averages
(6.5 NLOC, 2.0 CCN) and max CCN (14) have not moved across any of the last ten runs.

One non-numeric observation: `20260916-033929` shipped **without** an `ANALYSIS.md`, as did every run
since `20260908-181447`. The playbook treats that file as recommended outside releases and mandatory
at one, so this is not a breach, but it does mean the trend above had to be rebuilt from `RESULTS.md`
rows rather than read out of a prior write-up.

## Complexity watch list

**Functions `lizard` warned on:**

None. Max CCN across all 2929 functions is 14, one under the threshold, and the warning rate is
0.00 on both the function and NLOC measures.

**Files by layout band:**

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua` | 1307 | Accepted, carried from `RESULTS.md` unchanged. 1284 → 1307 since the v1.34.0 re-ruling; still 43 lines under its own 1350 re-check and 193 under the cap. No function in the file warns. |
| 1000–1500 (on notice) | `LibKa0s/Perf.lua` | 1231 | Already tracked as [`#7`](https://github.com/tusharsaxena/LibKa0s/issues/7) (owner: @tusharsaxena). Breadth, not knots — the file's avg CCN is 3.5 and its worst function is CCN 11. |
| 1000–1500 (on notice) | `LibKa0s/Widgets.lua` | 1232 | **Accepted, and past its shelf life.** Unchanged since the v1.27.0 release run — that is well beyond `automated-tests-§4`'s three-consecutive-release limit on a bare "Accepted". Owed a tracked ID with an owner, or a peel. Holds two CCN-13 functions (`list@1178-1219`, `paintMenuRow@126-159`); at avg CCN 4.4 this file is the densest in the band, so the density is real control flow and not `or`-defaulting. |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1499 | On notice, one line from breach and carried unchanged. Its own rule already fires: the next kit change that adds anything peels first or opens an issue naming the seam. Flat builder of independent fakes at avg CCN 2.1 — length is breadth. |
| 1000–1500 (on notice) | `tests/test_options.lua` | 1303 | **Accepted past its shelf life.** Crossed at `20260807-151331` (v1.8.3) already marked "owed a tracked ID"; that clock has run for eleven minor versions and no ID exists. Flat case list, avg CCN 1.1, nothing warned. |
| 1000–1500 (on notice) | `tests/test_slash.lua` | 1054 | Accepted, carried. Crossed at `20260913-002423` (v1.34.0); 446 under the cap, avg CCN 1.3. Its `automated-tests-§4` clock started at v1.34.0 and has two releases left to run. |
| 1000–1500 (on notice) | `tests/test_widgets.lua` | 1493 | **Accepted, seven lines from breach — the sharpest item in this bundle.** Flat since the v1.27.0 release run, which also puts it past the three-release shelf life. The next case added to it breaches `layout-§1`, and it wants an issue naming the seam before that, not after. |
| > 1500 (over cap) | `LibKa0s/OptionsWidgets.lua` | 3700 | Already tracked as [`#16`](https://github.com/tusharsaxena/LibKa0s/issues/16) (owner: @tusharsaxena), ruled 2026-09-08 (`M4-14`). Carried unchanged; `tests/test_layout_cap.lua` reddens if it ever drops off the census. |
| > 1500 (over cap) | `tests/test_options_widgets.lua` | 3997 | Already tracked as [`#8`](https://github.com/tusharsaxena/LibKa0s/issues/8) (owner: @tusharsaxena). Carried unchanged; peels along whatever seam [`#16`](https://github.com/tusharsaxena/LibKa0s/issues/16) chooses, in that file's own commit, so that `testing-§1`'s one-suite-one-module pairing survives. |

`lizard` counts every `and`/`or` short-circuit as a decision, so in Lua a run of
`t.k = rec.k or D.k` defaulting lines scores high with no visible branching. Of the band entries
above, only `LibKa0s/Widgets.lua` (avg CCN 4.4) and `LibKa0s/OptionsWidgets.lua` (3.8) carry density
that reads as genuine control flow; the four test files sit at 1.1–1.3, which is case count and not
tangle.

## Actions

1. `tests/test_widgets.lua` (1493 LOC) — open a tracked issue naming the split seam **before** the
   next case lands, since that case breaches `layout-§1`. The stated pairing rule says it splits by
   widget family the moment `LibKa0s/Widgets.lua` splits, so the issue should record that dependency
   rather than propose an independent peel.
2. `LibKa0s/Widgets.lua` (1232 LOC), `tests/test_options.lua` (1303 LOC) — both have been carried as
   a bare **Accepted** past `automated-tests-§4`'s three-consecutive-release shelf life. Each is owed
   either a peel or a tracked deviation ID with an owner; the `test_options.lua` row has said "owed a
   tracked ID" since v1.8.3.
3. `testkit/mock_base.lua` (1499 LOC) — its own trigger is live now, not later: the next kit revision
   that adds a line breaches the cap, so the Ace-fakes seam wants an issue this cycle.
4. `perf` — decide which it is: add `tests/perf.lua` scenarios, or ratify a `performance-§12`
   no-combat-path exemption. Today it is an unratified skip, and it is **NOT EVALUATED** at the
   release gate rather than passed.
