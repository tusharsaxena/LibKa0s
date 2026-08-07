# Analysis — 20260807-114658

- **Addon:** LibKa0s 1.8.2
- **Verdict:** green
- **Commit:** 40f4e50ac439b01331a77bfbc07c8009a093ef96 (master)
- **Previous run:** [`20260807-105553`](../20260807-105553/) — the `--release 1.8.2` run, taken while the tree still stamped 1.8.1

## Headline

Green. Both gating suites pass — `luacheck` clean over 12 files, 499 of 499 harness cases passing
with nothing skipped — and `complexity` records zero functions above CCN 15 for the sixth consecutive
run. Every measured figure is what the previous run reported, field for field; the only thing that
moved is the version the manifest stamps, 1.8.1 to 1.8.2, because the previous run was the release
run taken before the bump landed. The one item to act on is not from this run's numbers at all: the
two entries on the file band watch list are still carried as *Accepted, expired* with no deviation
ID, a debt `RESULTS.md` recorded at v1.8.2 and this run inherits unchanged.

## Suites

| Suite | Status | Result | Artifact | Moved since `20260807-105553` |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 12 files | [`lint.txt`](lint.txt) | No change — same 12 files, same clean result |
| tests | pass | 499 passed, 0 skipped, 0 failed, 499 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No change — same count, same inventory |
| perf | skip | 0 scenarios — no `tests/perf.lua` | none — the suite did not run | No change — permanent skip, see below |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | No change in any footer field |

**Complexity, in full** — every field of `lizard`'s footer as recorded in
[`manifest.json`](manifest.json) `suites.complexity`, totals and averages both:

| Metric | Value |
|---|---|
| Total NLOC | 8636 |
| Functions | 1242 |
| Avg NLOC / function | 6.3 |
| Avg CCN | 1.9 |
| Max CCN | 14 |
| Avg tokens / function | 48.8 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 2 |
| Files over the 1500 cap | 0 |

`perf` is the one suite that is not a clean pass, and it is a **skip, not a pass**. The repo ships no
`tests/perf.lua`, so there was nothing to run and this bundle says nothing about the library's runtime
cost. That is the first of `automated-tests-§3`'s two sanctioned `perf` skip reasons — the absence of
scenarios, not a ratified `performance-§12` exemption — and it is a standing fact about this repo
rather than a tooling gap on this machine. The narrower zero-overhead claim `performance-§2` asks of
this library is held as a test case instead (`tests/test_perf_isolation.lua`), inside the `tests`
suite above, so it is measured on every commit; what remains unmeasured is the cost of the
instrumentation while capture is **on**.

## What moved

- **lint** — 0/0 over 12 files, identical to `20260807-105553` and to the four runs before it.
  `.luacheckrc`'s `exclude_files = { "tests/", "docs/" }` scope is unchanged, so the comparison is
  like for like.
- **tests** — 499/499, identical. The inventory in [`test-cases.md`](test-cases.md) carries the same
  case names, not merely the same total; `tests/test_eol.lua` remains the most recent addition
  (it arrived at `20260807-102629`).
- **perf** — skip, identical, and for the identical reason. Six consecutive runs.
- **complexity** — every footer field identical: 8636 NLOC, 1242 functions, avg NLOC 6.3, avg CCN 1.9,
  max CCN 14, avg tokens 48.8, 0 warnings. No `.lua` file moved between the two runs, so this is a
  stable tree measured twice rather than a figure held down by effort. The top three by CCN are
  unchanged and unchanged in position: `Kit.run` (14, `testkit/framework.lua:394-433`),
  `Kit.assertSuiteInventory` (13, `testkit/framework.lua:277-316`) and the anonymous case body at
  `tests/test_eol.lua:91-126` (13), with `Sl` (12, `LibKa0s/Slash.lua:527-550`) behind them.
- **version** — 1.8.1 to 1.8.2 in the manifest. This is the only field that moved anywhere in the
  run, and it moved because the previous row was the `--release 1.8.2` bundle produced *before* the
  bump edited the tree. Nothing was measured differently.
- **bundle line endings** — first ordinary run on test-kit revision 10, whose `normalize_eol` pass
  writes the bundle with the terminator `.gitattributes` declares instead of always LF. All five
  artifacts in this directory carry equal CR and LF byte counts (`complexity.txt` 1287/1287,
  `lint.txt` 14/14, `manifest.json` 19/19, `test-cases.md` 568/568, `tests.txt` 501/501), matching
  this repo's `* text=auto eol=crlf` pin. This is a property of how the bundle was written, not a
  measurement of the addon.

## Complexity watch list

### Functions `lizard` warned on

**None.** Nothing in `LibKa0s/` or `testkit/` exceeds CCN 15; the highest anywhere in scope is 14.
No disposition is carried, because nothing is warned on.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Perf.lua` | 1163 | **Accepted, expired — owed a tracked deviation ID.** Not newly crossed; in the band since `20260805-002859` and unchanged in LOC since `20260807-022509`. Breadth, not tangle: the worst function in the file is `groupContext` at CCN 11 and the file's avg CCN is 3.4, so what the length buys is surface area — the sampler plus the group/scenario bookkeeping is the peel seam if it crosses 1500. |
| 1000–1500 (on notice) | `tests/test_options_widgets.lua` | 1114 | **Accepted, expired — owed a tracked deviation ID.** Not newly crossed; same band and same LOC across the last four runs. A flat list of independent widget cases, so the length is case count rather than control flow. Split by widget family if it crosses 1500. |

Nothing is over the 1500 cap, and nothing newly crossed either threshold in this run. Both
dispositions have been carried as *Accepted* through three consecutive release runs — v1.8.0
(`20260805-123655`), v1.8.1 (`20260806-180959`) and v1.8.2 (`20260807-105553`) — so under
`automated-tests-§4` (anti-pattern #53) the shelf life has expired and each is owed a fix or a
tracked deviation ID with an owner. Neither has one, and this run does not discharge it: no `.lua`
file moved, so there is nothing here that could have.

## Actions

1. **File one issue per band-list row**, on the LibKa0s issue store, and replace each disposition
   with *Already tracked as `<id>`*. Covers `LibKa0s/Perf.lua` (1163 LOC) and
   `tests/test_options_widgets.lua` (1114 LOC). This is the expired shelf life above, carried over
   from `20260807-105553` rather than new here — it has no owner in the addon's own tracking yet,
   which is exactly the gap the issue closes. Owed before v1.8.3.
2. **Nothing else.** No suite regressed, no threshold was newly crossed, and no figure moved.
