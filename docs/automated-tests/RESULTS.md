# Automated test results

<!-- The newest run is prepended by tests/_kit/run-automated-tests.sh. -->
<!-- This file is OVERWRITTEN IN PLACE — the git history of this one path is the trend line. -->

One row per run. The frozen evidence for each is in the dated folder beside this file;
the analysis of a given run is its `ANALYSIS.md`.

**`lint` and `tests` gate. `perf` and `complexity` are recorded and never fail a run** —
they are read and compared, not thresholded. A `skip` is a suite that did not run at all,
which is never the same as a pass.

| Run | Version | Lint w/e | Files | Tests | Perf | NLOC | Funcs | Avg NLOC | Avg CCN | Max CCN | CCN warn | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| [`20260824-024124`](20260824-024124/) | 1.10.2 | 0/0 | 14 | 549/549 | skip | 9640 | 1401 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260823-235820`](20260823-235820/) | 1.10.1 | 0/0 | 13 | 531/531 | skip | 9168 | 1320 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260823-195133`](20260823-195133/) | 1.10.0 | 0/0 | 13 | 528/528 | skip | 9126 | 1313 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260823-191126`](20260823-191126/) | 1.9.2 | 0/0 | 13 | 526/526 | skip | 9118 | 1309 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260823-183503`](20260823-183503/) | 1.9.1 | 0/0 | 13 | 517/517 | skip | 8952 | 1274 | 6.4 | 1.9 | 14 | 0 | **green** |
| [`20260823-150620`](20260823-150620/) | 1.9.0 | 0/0 | 13 | 514/514 | skip | 8869 | 1270 | 6.4 | 1.9 | 14 | 0 | **green** |
| [`20260823-144602`](20260823-144602/) | 1.8.3 | 0/0 | 13 | 513/513 | skip | 8862 | 1269 | 6.4 | 1.9 | 14 | 0 | **green** |
| [`20260807-151331`](20260807-151331/) | 1.8.2 | 0/0 | 12 | 502/502 | skip | 8676 | 1249 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260807-114658`](20260807-114658/) | 1.8.2 | 0/0 | 12 | 499/499 | skip | 8636 | 1242 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260807-105553`](20260807-105553/) | 1.8.1 | 0/0 | 12 | 499/499 | skip | 8636 | 1242 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260807-102629`](20260807-102629/) | 1.8.1 | 0/0 | 12 | 499/499 | skip | 8636 | 1242 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260807-022509`](20260807-022509/) | 1.8.1 | 0/0 | 12 | 498/498 | skip | 8557 | 1237 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260806-180959`](20260806-180959/) | 1.8.0 | 0/0 | 12 | 498/498 | skip | 8557 | 1237 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260805-123655`](20260805-123655/) | 1.7.0 | 0/0 | 12 | 498/498 | skip | 8555 | 1237 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260805-002859`](20260805-002859/) | 1.7.0 | 0/0 | 11 | 480/480 | skip | 7975 | 1201 | 6.1 | 1.8 | 12 | 0 | **green** |

## Test suite

499 cases, spread across the library's own surfaces and the kit it vendors: core and debug log,
the slash router, the options panel and its widgets and scroll frame, the perf core with its
command, panel, run and isolation suites, versioning, `test_prose.lua` — US English and retired
section notation across the shipped payload — `test_kitsync.lua`, which asserts that `testkit/` and
`tests/_kit/` hold the same files and that every one of them is byte-identical, README included, and
`test_eol.lua`, which asks git what each tracked file under `docs/automated-tests/` is *declared* to
be and then reads the bytes. The generated inventory `test-cases.md` in each bundle is the authority
on what exists at any point.

The count is now flat at 499 across three runs — `20260807-102629`, the v1.8.2 release run
`20260807-105553`, and `20260807-114658` — carrying the same case names and not merely the same
total. It last moved at `20260807-102629`, 498 to 499, when `test_eol.lua` was added; before that it
held at 498 across `20260805-123655`, `20260806-180959` and `20260807-022509`. A flat suite over a
flat library is not a coverage gap, and nothing has shipped in this window: v1.8.2 moves no `.lua`
file at all. The reading changes the moment a run adds source without adding cases, which is the
thing the table cannot show and this section exists to say.

Two coverage facts are worth naming while the count has no long history to speak for it. The suite
exercises the library **headlessly through the mock**, so what it pins is contract and state
transition, not in-client behavior — anything that depends on a real frame, a real event or a real
saved-variables round trip is covered by the consumers' in-game smoke tests, not here. And the perf
suites (`test_perf_core`, `test_perf_command`, `test_perf_panel`, `test_perf_run`,
`test_perf_isolation`) test that the instrumentation **works**, never what it **costs** — see
`## Perf`.

No case has ever reported a `skip` on any row above; the passed figure and the total have been equal
on all seven runs, so nothing in this trend line is claiming coverage that was not exercised.

## Lint

Clean over 12 files: 0 warnings, 0 errors. Read that number with its scope attached, because the
scope is narrower than the repo. `.luacheckrc:4` sets `exclude_files = { "tests/", "docs/" }`, so
`luacheck .` covers the 8 shipped library files under `LibKa0s/` plus the 4 Lua sources in
`testkit/` — and **none of the test code**, which is the larger half of the tree by line count.
The kit's Lua is linted once, at its master path in `testkit/`; the vendored `tests/_kit/` copy is
excluded along with the rest of `tests/`, which costs nothing while `test_kitsync.lua` holds the two
copies byte-identical.

The file count has sat at 12 since `20260805-123655` and the clean result at every row on the table,
including the first. That clean result is real — six of the eight linted sources were edited between
`20260805-002859` and now (`Core`, `DebugLog`, `Options`, `OptionsWidgets`, `Perf`, `Slash`, plus
`testkit/framework.lua` and `testkit/vendor_sync.lua`) and none of it introduced a warning. But the
excluded half also grew over the same window, by 19 cases, and none of that code is looked at by
`luacheck` at all. A `0/0` that never changes is therefore partly a statement about what is not in
scope, which is why the exclusion is restated here every run rather than assumed known.

## Perf

**This repo ships no `tests/perf.lua`, so `perf` is a permanent `skip` — not a pass, and not a
transient tooling gap.** That is the first of `automated-tests-§3`'s two sanctioned reasons: nothing
to run, rather than a ratified `performance-§12` no-combat-path exemption, which this repo does not
hold. The record is therefore **silent about runtime cost**. Nothing in this file, in any bundle
beside it, or in the green verdict on any row above says the library is fast, cheap, or free; it says
the question was never asked.

That silence is narrower than it looks, and one part of it has since been filled. LibKa0s **is** the
perf instrumentation for the collection — `LibKa0s/Perf.lua` and `LibKa0s/PerfPanel.lua` are what
eight addons profile through — so the zero-overhead evidence `performance-§2` demands, that a
bracketed path costs nothing when capture is off, is owed **by this repo** and not by its hosts. It is
now held as a test case rather than as a scenario: `tests/test_perf_isolation.lua:66` runs 10,000
dormant `Open`/`Close` pairs with the gate off and pins heap growth under 1 KB with nothing recorded.
That runs in the green gate, on every commit.

What remains unmeasured is the cost of the instrumentation while it is **on** — the sampler, the
record build, the panel — and no scenario file is planned, because `performance-§9`'s own bullet keeps
scenarios per-addon. `docs/automated-tests/README.md` § *Why that skip is permanent* records that
disposition, dated, with the condition that would reopen it.

## Complexity watch list

Current state as of [`20260823-235820`](20260823-235820/) — not that run's diff. Every function
`lizard` warned on, and every file at or above `layout-§1`'s 1000-LOC on-notice threshold, each with
a one-line disposition.

### Functions `lizard` warned on

**None.**

That is a result, not an empty section. Nothing in `LibKa0s/` or `testkit/` exceeds CCN 15. The
highest CCN anywhere in scope is **14** — `Kit.run` (`testkit/framework.lua:394-433`) — with
`Kit.assertSuiteInventory` (`testkit/framework.lua:277-316`) and the anonymous case body at
`tests/test_eol.lua:91-126` tied at 13, and `Sl` (`LibKa0s/Slash.lua:527-550`) at 12 behind them. No
disposition is carried, because nothing is warned on.

That top group last moved at `20260805-123655`, when the ceiling went 12 to 14 and both new entries
landed in the kit rather than in the shipped library: `Kit.run` gained the `skip` status arm and the
suite-inventory call, and `Kit.assertSuiteInventory` is a two-way set comparison with one branch per
divergence class. Neither is tangle and neither is near the cap, but the headroom is one arm narrower
than it was — a third arm added to either is the thing to notice.

Twelve rows now, every one of them zero, so the result is held rather than first-measured.
It is now closer to a trend than it was: the library HAS changed across those rows — Media, Options,
Core, DebugLog and Perf all moved — and NLOC has gone 8557 to 9168 with the ceiling unmoved at 14.
That is a growing tree holding its shape rather than a static one measured repeatedly.

When these numbers do start moving, remember `lizard` counts every `and`/`or` short-circuit as a
decision. In Lua a run of `t.k = rec.k or D.k` defaulting lines scores high with no visible
branching, so a rising CCN in this library usually means *this function defaults or guards more
fields* rather than *this function grew tangled* — and the two want different fixes
(`performance-§10`).

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Perf.lua` | 1163 | **Already tracked as [`#7`](https://github.com/tusharsaxena/LibKa0s/issues/7)** (owner: @tusharsaxena). Not a violation — the file is under `layout-§1`'s 1500 cap; the issue records the decision and its trigger so it is not re-argued each run. Was 1052; it grew for the observed-containment record and the keyed `Open`/`Close` bracket. Still the only shipped file in the band and the widest surface the consumers bind against. Worst function in the file is `groupContext` at CCN 11 and the file's avg CCN is 3.4, so this is breadth, not knots; the sampler and the group/scenario bookkeeping are the peel seam if it crosses 1500. |
| 1000–1500 (on notice) | `tests/test_options_widgets.lua` | 1114 | **Already tracked as [`#8`](https://github.com/tusharsaxena/LibKa0s/issues/8)** (owner: @tusharsaxena). A flat list of independent widget cases; length is case count, not tangle. Split by widget family if it crosses 1500. |
| 1000–1500 (on notice) | `tests/test_options.lua` | 1001 | **NEWLY CROSSED at `20260807-151331` (v1.8.3), by one line — owed a tracked ID.** 968 → 1001, from the three cases covering `O.RefreshPanel`. Same shape as the row above: a flat list of independent cases, so length is case count, not tangle, and nothing in the file warns on CCN. Under the 1500 cap, so a split is declined today; the peel seam is the render/refresh block, large enough to stand alone as `tests/test_options_render.lua`. Its `automated-tests-§4` clock starts at v1.8.3. |

Nothing is over the 1500 cap. **The third entry is newly crossed at `20260807-151331`**, the v1.8.3
release run and the first run since `20260805-002859` in which any `.lua` file moved at all: the new
`O.RefreshPanel` member and its three cases took `tests/test_options.lua` from 968 to 1001. The first
two entries are not newly crossed and did not move — both were already in the band at
`20260805-002859` and both still read 1163 and 1114, the figures they have carried since
`20260807-022509`.

The new row is owed what the other two now have: an issue with an owner, after which its disposition
reads *Already tracked as `<id>`*. Its shelf-life clock starts at v1.8.3, so it is not yet expired —
it is recorded here on the run that created it so the clock has a start date, which is the failure
mode the paragraphs below describe.

**Both dispositions crossed the shelf life at v1.8.2, and both are now discharged.** Each had been
carried as *Accepted* through the v1.8.0 (`20260805-123655`), v1.8.1 (`20260806-180959`) and v1.8.2
(`20260807-105553`) release runs; the ordinary runs in between, this one included, do not count
against the clock and do not restart it either. `automated-tests-§4` (anti-pattern #53) says each is
at that point owed either a fix or a **tracked deviation ID with an owner**, after which the
disposition reads *Already tracked as `<id>`* and the argument stops being re-had.

Neither was fixed, and both are deliberately not being fixed: `layout-§1` caps a file at 1500 and
both are under it — 1163 and 1114 — so there is no violation to remedy, and the band is *on notice*
rather than a limit. What was missing was the record of a decision somebody had actually taken.
[`#7`](https://github.com/tusharsaxena/LibKa0s/issues/7) and
[`#8`](https://github.com/tusharsaxena/LibKa0s/issues/8) are that record: each names the file, its
LOC, why a split is declined today, the peel seam to execute if it is ever wanted, and the 1500-LOC
hard trigger that turns the decision into a MUST. Both carry an owner.

This was never a release-gate failure — the gate is the four suites plus zero functions above CCN 15,
and `20260807-105553` reports max CCN **14** with zero `lizard` warnings, as does this run. The shelf
life is a separate obligation this file owes, and v1.8.2 could not honestly have discharged it: that
release is a one-file fix to a shell script touching neither band file, so a fix was out of scope and
the deviation IDs are a judgement about each file's future shape rather than a bookkeeping step.
Read the two rows above as decisions that have been taken and recorded, not as decisions being
re-affirmed by default.
