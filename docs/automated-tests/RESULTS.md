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

Current state as of [`20260807-114658`](20260807-114658/) — not that run's diff. Every function
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

Seven rows now, six of them identical, so the zero is a held result rather than a first measurement.
It is still not a trend: the library has not changed in that window, so what the rows show is a
stable tree measured repeatedly, not a complexity figure that has been held down.

When these numbers do start moving, remember `lizard` counts every `and`/`or` short-circuit as a
decision. In Lua a run of `t.k = rec.k or D.k` defaulting lines scores high with no visible
branching, so a rising CCN in this library usually means *this function defaults or guards more
fields* rather than *this function grew tangled* — and the two want different fixes
(`performance-§10`).

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Perf.lua` | 1163 | **Accepted, expired — the one to watch, and the one now owed an ID.** Was 1052; it grew for the observed-containment record and the keyed `Open`/`Close` bracket. Still the only shipped file in the band and the widest surface the consumers bind against. Worst function in the file is `groupContext` at CCN 11 and the file's avg CCN is 3.4, so this is breadth, not knots; the sampler and the group/scenario bookkeeping are the peel seam if it crosses 1500. |
| 1000–1500 (on notice) | `tests/test_options_widgets.lua` | 1114 | **Accepted, expired — unchanged in LOC, but owed an ID.** A flat list of independent widget cases; length is case count, not tangle. Split by widget family if it crosses 1500. |

Nothing is over the 1500 cap. Neither entry is marked "newly crossed" — both were already in the
band at `20260805-002859`, and both held their LOC exactly at `20260807-114658`: 1163 and 1114, the
same figures they carried at `20260807-022509`, `20260807-102629` and `20260807-105553`. No `.lua`
file has moved in that window, shipped or test, so neither number could have.

**Both dispositions are three of their three releases old, and the shelf life has expired.** Each has
been carried as *Accepted* through the v1.8.0 (`20260805-123655`), v1.8.1 (`20260806-180959`) and
v1.8.2 (`20260807-105553`) release runs; the ordinary runs in between, this one included, do not
count against it and do not restart the clock either. `automated-tests-§4` (anti-pattern #53) says
each is at this point owed either a fix or a **tracked deviation ID with an owner**, after which the
disposition reads *Already tracked as `<id>`* and the argument stops being re-had.

**Neither has one, and v1.8.2 shipped without closing it — recorded here rather than allowed to pass
quietly, and re-stated at `20260807-114658` rather than quietly re-affirmed.** It is not a
release-gate failure: the gate is the four suites plus zero functions above CCN 15
(`20260807-105553` reports max CCN **14** and zero `lizard` warnings, as does this run), and the
shelf life is a separate obligation this file owes. It is also not something the v1.8.2 release could
honestly have discharged — that release is a one-file fix to a shell script and touches neither band
file, so a fix was out of scope and a deviation ID is a judgement about `LibKa0s/Perf.lua`'s future
shape rather than a bookkeeping step. **Owed before v1.8.3: one issue per row on the repo's issue
store, named here.** Until then each disposition above is *Accepted, expired* and should be read as a
decision nobody has re-taken, not as one that keeps being re-affirmed.
