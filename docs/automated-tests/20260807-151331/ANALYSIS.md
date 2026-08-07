# Analysis — 20260807-151331

- **Addon:** LibKa0s 1.8.2 (manifest `release` 1.8.3 — the pre-tag release run, see below)
- **Verdict:** green
- **Commit:** dc1621f47f53304ffabc093174e8cba585e90c4f (master, dirty)
- **Previous run:** [`20260807-114658`](../20260807-114658/) — the ordinary run after the v1.8.2 bump

## Headline

Green, and the **release run for v1.8.3** (`docs/releasing.md` step 7). Both gating suites pass —
`luacheck` clean over 12 files, 502 of 502 harness cases passing with nothing skipped — and
`complexity` records zero functions above CCN 15 for the seventh consecutive run, so
`automated-tests-§3`'s release gate is met.

This is the first run in six whose numbers actually moved, because it is the first in six where a
shipped `.lua` file moved: `LibKa0s/Options.lua` goes to minor 8 with one new member,
`O.RefreshPanel(ctx, structural)`. Tests are up 3 (499 → 502) and NLOC up 40 (8636 → 8676).

**One new item, and it is mine.** `tests/test_options.lua` crossed the `layout-§1` 1000-line band in
this run — 1001 LOC, from 968 — because the three cases covering the new member landed in it. It is
one line over, it is a flat list of independent cases rather than control flow, and it is on notice
rather than over the 1500 cap. It is still a third row on a watch list whose existing two rows are
already carrying an expired shelf life.

## Suites

| Suite | Status | Result | Artifact | Moved since `20260807-114658` |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 12 files | [`lint.txt`](lint.txt) | No change — same 12 files, same clean result |
| tests | pass | 502 passed, 0 skipped, 0 failed, 502 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | **+3 cases** — the new `O.RefreshPanel` block |
| perf | skip | 0 scenarios — no `tests/perf.lua` | none — the suite did not run | No change — permanent skip, see below |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | **NLOC +40, functions +7**; every rate and average unmoved |

**Complexity, in full** — every field of `lizard`'s footer as recorded in
[`manifest.json`](manifest.json) `suites.complexity`, totals and averages both:

| Metric | Value | Previous |
|---|---|---|
| Total NLOC | 8676 | 8636 |
| Functions | 1249 | 1242 |
| Avg NLOC / function | 6.3 | 6.3 |
| Avg CCN | 1.9 | 1.9 |
| Max CCN | 14 | 14 |
| Avg tokens / function | 48.8 | 48.8 |
| Warnings (CCN > 15) | 0 | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 | 0.00 / 0.00 |
| Files in the 1000–1500 band | 3 | 2 |
| Files over the 1500 cap | 0 | 0 |

`perf` is the one suite that is not a clean pass, and it is a **skip, not a pass**. The repo ships no
`tests/perf.lua`, so there was nothing to run and this bundle says nothing about the library's runtime
cost. That is the first of `automated-tests-§3`'s two sanctioned `perf` skip reasons — the absence of
scenarios, not a ratified `performance-§12` exemption — and it is a standing fact about this repo
rather than a tooling gap on this machine. The narrower zero-overhead claim `performance-§2` asks of
this library is held as a test case instead (`tests/test_perf_isolation.lua`), inside the `tests`
suite above. It is worth restating on a **release** run: v1.8.3 ships with the instrumentation's
capture-on cost unmeasured, exactly as v1.8.0 through v1.8.2 did.

## What moved

- **lint** — 0/0 over 12 files, identical to the previous six runs. `.luacheckrc`'s
  `exclude_files = { "tests/", "docs/" }` scope is unchanged, so the comparison is like for like.
  Note what that scope means here: the file this release changes, `LibKa0s/Options.lua`, is inside
  the checked set, so the clean run is evidence about the shipped change and not only about
  untouched files.
- **tests** — 499 → **502**. Three new cases, all in `tests/test_options.lua`, all covering the new
  member: that `RefreshPanel` touches one page and not its neighbours on both tiers, that it defers
  a hidden page to its next show *and* that the show actually repaints, and that a non-ctx argument
  is a no-op rather than a raise. The inventory in [`test-cases.md`](test-cases.md) carries the same
  case names as before plus those three; nothing was renamed or removed.
- **perf** — skip, identical, and for the identical reason. Seven consecutive runs.
- **complexity** — NLOC 8636 → 8676 (+40) and functions 1242 → 1249 (+7), which is the new member
  plus its three cases and their local helpers. **Every average, rate and maximum is unchanged**:
  avg NLOC 6.3, avg CCN 1.9, max CCN 14, avg tokens 48.8, 0 warnings. The addition is flat code, so
  it moved the totals and not the shape. The top functions by CCN are unchanged and unchanged in
  position: `Kit.run` (14, `testkit/framework.lua:394-433`), `Kit.assertSuiteInventory`
  (13, `testkit/framework.lua:277-316`) and the anonymous case body at `tests/test_eol.lua:91-126`
  (13). `O.RefreshPanel` itself is CCN 2 — one type guard and a delegation.
- **version** — the manifest stamps `addonVersion` **1.8.2** while `release` says **1.8.3**, and the
  two disagreeing is correct here rather than a defect. This repo has no `.toc`, so the runner reads
  `addonVersion` from `git describe --tags` (`run-automated-tests.sh:76`), and `v1.8.3` does not
  exist yet — step 7 requires the bundle to be produced *before* the tag so the tagged tree contains
  the evidence for itself. `release: "1.8.3"` is the field that ties this run to the version, which
  is exactly what `--release` is for. The same disagreement is on the record at `20260807-105553`.
- **git dirty** — `true`, and expected for the same reason: this is the pre-tag run of a working
  tree that is about to become the release commit.
- **bundle line endings** — second ordinary run on test-kit revision 10. All five artifacts carry
  equal CR and LF byte counts (`complexity.txt` 1294/1294, `lint.txt` 14/14, `manifest.json` 19/19,
  `test-cases.md` 571/571, `tests.txt` 504/504), matching this repo's `* text=auto eol=crlf` pin.
  This is a property of how the bundle was written, not a measurement of the library.

## Complexity watch list

### Functions `lizard` warned on

**None.** Nothing in `LibKa0s/` or `testkit/` exceeds CCN 15; the highest anywhere in scope is 14.
No disposition is carried, because nothing is warned on.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Perf.lua` | 1163 | **Already tracked as [`#7`](https://github.com/tusharsaxena/LibKa0s/issues/7)** (owner: @tusharsaxena). Unchanged in LOC since `20260807-022509`. Not a violation — under `layout-§1`'s 1500 cap — and the issue records the decision, the peel seam and the hard trigger so it is not re-argued each run. |
| 1000–1500 (on notice) | `tests/test_options_widgets.lua` | 1114 | **Already tracked as [`#8`](https://github.com/tusharsaxena/LibKa0s/issues/8)** (owner: @tusharsaxena). Unchanged in LOC across the last five runs. A flat list of independent widget cases; length is case count, not tangle. |
| 1000–1500 (on notice) | `tests/test_options.lua` | 1001 | **NEWLY CROSSED in this run, by one line, and owed a tracked ID.** 968 → 1001, from the three `O.RefreshPanel` cases. Same shape as the row above it — a flat list of independent cases, so the length is case count and not control flow; nothing in the file warns. Under the 1500 cap, so there is no violation to remedy and a split is declined today. The peel seam if it grows is the render/refresh block, now large enough to stand alone as `tests/test_options_render.lua`. Its `automated-tests-§4` clock starts at **v1.8.3**. |

Nothing is over the 1500 cap, and nothing in this run warns on CCN.

**The two pre-existing rows are discharged and stay discharged.** Their shelf life expired at v1.8.2
and was settled there rather than deferred: [`#7`](https://github.com/tusharsaxena/LibKa0s/issues/7)
and [`#8`](https://github.com/tusharsaxena/LibKa0s/issues/8) each name the file, its LOC, why a split
is declined, the peel seam and the 1500-LOC hard trigger, and each carries an owner. `RESULTS.md`
carries that record; the previous run's ANALYSIS still described them as *Accepted, expired* and
*owed before v1.8.3*, which was already out of date when it was written. Read those two rows as
decisions taken, not re-affirmed by default.

**The third row is genuinely new and is this release's own debt.** It needs the same treatment the
other two got — an issue with an owner — before the disposition can read *Already tracked*. It does
not gate v1.8.3: the release gate is the four suites plus zero functions above CCN 15, and this run
reports max CCN 14 with zero `lizard` warnings.

## Actions

1. **File one issue for `tests/test_options.lua`** (1001 LOC) on the LibKa0s issue store, in the
   shape of [`#7`](https://github.com/tusharsaxena/LibKa0s/issues/7) and
   [`#8`](https://github.com/tusharsaxena/LibKa0s/issues/8) — file, LOC, why a split is declined
   today, the peel seam, the 1500-LOC trigger, an owner — then replace the disposition above and in
   `RESULTS.md` with *Already tracked as `<id>`*. This is the one debt v1.8.3 opens and does not
   close. `#7` and `#8` need nothing.
2. **Re-vendor the consumers** (`docs/releasing.md` step 8). `LibKa0s/Options.lua` moved, so
   `libs/LibKa0s/` is no longer byte-identical in any consumer that has not been re-copied, and each
   consumer's `CLAUDE.md` provenance line moves in the same commit as the bytes. PanelMaster is done
   in the same change as this release — it is the host whose bug prompted the new member.
3. **Nothing else.** No suite regressed, no gating threshold was crossed, and no average moved.
