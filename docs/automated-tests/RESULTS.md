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
| [`20260805-002859`](20260805-002859/) | 1.7.0 | 0/0 | 11 | 480/480 | skip | 7975 | 1201 | 6.1 | 1.8 | 12 | 0 | **green** |

## Test suite

480 cases, spread across the library's own surfaces and the kit it vendors: core and debug log,
the slash router, the options panel and its widgets and scroll frame, the perf core with its
command, panel, run and isolation suites, versioning, and `test_kitsync.lua` — which is the one
that asserts `testkit/` and `tests/_kit/` hold the same files and that every one of them is
byte-identical, README included. The generated inventory `test-cases.md` in each bundle is the
authority on what exists at any point.

Two coverage facts are worth naming while the count has no history to speak for it. The suite
exercises the library **headlessly through the mock**, so what it pins is contract and state
transition, not in-client behavior — anything that depends on a real frame, a real event or a real
saved-variables round trip is covered by the consumers' in-game smoke tests, not here. And the perf
suites (`test_perf_core`, `test_perf_command`, `test_perf_panel`, `test_perf_run`,
`test_perf_isolation`) test that the instrumentation **works**, never what it **costs** — see
`## Perf`.

## Lint

Clean over 11 files: 0 warnings, 0 errors. Read that number with its scope attached, because the
scope is narrower than the repo. `.luacheckrc:4` sets `exclude_files = { "tests/", "docs/" }`, so
`luacheck .` covers the 8 shipped library files under `LibKa0s/` plus the 3 Lua sources in
`testkit/` — and **none of the test code**, which is the larger half of the tree by line count.
The kit's Lua is linted once, at its master path in `testkit/`; the vendored `tests/_kit/` copy is
excluded along with the rest of `tests/`, which costs nothing while `test_kitsync.lua` holds the two
copies byte-identical.

## Perf

**This repo ships no `tests/perf.lua`, so `perf` is a permanent `skip` — not a pass, and not a
transient tooling gap.** The record is therefore **silent about runtime cost**. Nothing in this
file, in any bundle beside it, or in the green verdict on any row above says the library is fast,
cheap, or free; it says the question was never asked.

That silence is louder here than it would be in a consumer addon. LibKa0s **is** the perf
instrumentation for the collection — `LibKa0s/Perf.lua` and `LibKa0s/PerfPanel.lua` are what eight
addons profile through — and `performance-§9`'s zero-overhead evidence, that bracketed
instrumentation costs nothing when capture is off, does not exist for the library that supplies the
brackets. The perf test suites pin that the instrumentation behaves correctly; none of them measures
what it costs. Adding scenarios is the only thing that changes any of this.

## Complexity watch list

Current state as of [`20260805-002859`](20260805-002859/) — not that run's diff.
Every function `lizard` warned on, and every file at or above `layout-§1`'s 1000-LOC
on-notice threshold, each with a one-line disposition.

### Functions `lizard` warned on

**None.**

That is a result, not an empty section. Nothing in `LibKa0s/` or `testkit/` exceeds CCN 15. The
highest CCN anywhere in scope is **12** — `Sl` (`LibKa0s/Slash.lua:527-550`) — with `groupContext`
(`LibKa0s/Perf.lua:496-510`) at 11 behind it, so there is real headroom rather than a cluster
sitting on the cap. No disposition is carried, because nothing is warned on.

There is no streak here yet: this is the first recorded run, so the zero is a first measurement and
not a record of anything held. Read it as a baseline until a second row exists.

When these numbers do start moving, remember `lizard` counts every `and`/`or` short-circuit as a
decision. In Lua a run of `t.k = rec.k or D.k` defaulting lines scores high with no visible
branching, so a rising CCN in this library usually means *this function defaults or guards more
fields* rather than *this function grew tangled* — and the two want different fixes
(`performance-§10`).

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `tests/test_options_widgets.lua` | 1114 | **Accepted.** A flat list of independent widget cases; length is case count, not tangle. Split by widget family if it crosses 1500. |
| 1000–1500 (on notice) | `LibKa0s/Perf.lua` | 1052 | **Accepted — the one to watch.** The only shipped file in the band and the widest surface the consumers bind against. Avg CCN is low and its worst function is 11, so this is breadth, not knots; the sampler and the group/scenario bookkeeping are the peel seam if it grows. |

Nothing is over the 1500 cap. Neither entry is marked "newly crossed" — there is no previous run for
either to have crossed since.
