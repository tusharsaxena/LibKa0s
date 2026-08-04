# Analysis — 20260805-002859

- **Addon:** LibKa0s 1.7.0
- **Verdict:** green
- **Commit:** 64c1b8a721a3510ed77c378278b289c287969383 (master), dirty
- **Started:** 2026-08-05T00:28:59+05:30
- **Previous run:** none — this is the first recorded run

## Headline

**The library that owns the runner has never run it.** LibKa0s vendors
`run-automated-tests.sh` to eight consumers and its own suite asserts the two copies are
byte-identical, but until this run there was no `docs/automated-tests/` here at all — the kit's own
output path had never been executed in the kit's own repo. It did not work: the runner required a
`.toc` at the repo root, and an embeddable library does not have one, so it exited 2 before reaching
a single suite. That gap is why kit bugs reached rev 6 before anyone saw them. With the root-detection
fix in place both gating suites are clean — `luacheck` reports 0 warnings / 0 errors across 11 files
and the headless harness passes 480 of 480 cases — `lizard` warns on nothing, and `perf` is a
**skip**, not a pass. Every figure below is a **baseline**: there is no previous row to diff against,
so nothing here is a regression and nothing is an improvement.

## Suites

| Suite | Status | Result | Artifact | Moved since previous run |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 11 files | [`lint.txt`](lint.txt) | — first run |
| tests | pass | 480 passed, 0 failed, 480 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | — first run |
| perf | skip | — | — (not run) | — first run |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | — first run |

### Complexity in full

Every field of `lizard`'s footer, plus the two derived file counts. The **averages** are what make
this run comparable to the next one across a change in size: a total that rises because the library
grew is a different fact from an average that rises because it got denser, and only the second is a
complexity signal. Reporting the totals alone would make an expanding library look like a degrading
one at every release until nobody read the row. Every value here is `manifest.json`'s
`suites.complexity`.

| Metric | Value |
|---|---|
| Total NLOC | 7975 |
| Functions | 1201 |
| Avg NLOC / function | 6.1 |
| Avg CCN | 1.8 |
| Max CCN | 12 |
| Avg tokens / function | 47.5 |
| Warnings (CCN > 15) | 0 |
| Warning rate — `Fun Rt` / `nloc Rt` | 0.00 / 0.00 |
| Files in the 1000–1500 band | 2 |
| Files over the 1500 cap | 0 |

Three of four suites ran. `perf` and `complexity` are **recorded, non-gating** — they inform, they
do not fail the run.

**`perf` is a skip.** `manifest.json` records the reason verbatim: `no tests/perf.lua — this addon
ships no offline scenarios`. Nothing was measured, so this record says **nothing** about the
library's runtime cost, and it must not be read as evidence that the cost is fine. That matters more
here than in a consumer: LibKa0s ships `Perf.lua` and `PerfPanel.lua`, the instrumentation eight
addons profile *through*, and the zero-overhead claim `performance-§9` asks for — that bracketed
instrumentation is free when capture is off — has no measurement behind it in this repo. The one
library best placed to prove it is the one not proving it. Only adding scenarios changes that.

**The run required a fix to the runner to happen at all**, which is why the commit above is marked
dirty. `run-automated-tests.sh` located the addon with `ls -1 ./*.toc` and exited with `no .toc at
the repo root` when it found none. Every consumer is an addon and has a `.toc`; LibKa0s is a library
loaded through its host's TOC and has never had one, so the runner was structurally incapable of
running here. The fix takes identity from the repo directory and version from the newest semver tag
— the only repo-wide number a library has, since its files carry per-file LibStub minors instead —
which is where the `1.7.0` in this manifest came from. It was made in `testkit/` and re-vendored to
`tests/_kit/`, per `automated-tests-§2`; the vendored copy was never edited directly.

## What moved

**First run — nothing to diff against; every figure above is a baseline reading.** The next run is
the first one that can say something moved, and this record is what it will be read against.

Worth stating plainly rather than leaving to silence: the 480 test cases, the 11 linted files, the
7975 NLOC and the zero `lizard` warnings are all first observations, not confirmations. The zero
warning count in particular is a measurement, not a streak — this repo has no history of warned
functions to have cleared.

## Complexity watch list

### Functions `lizard` warned on

**None.** No function in this library or its `testkit/` exceeds CCN 15, and that is the result rather
than an empty section. The highest CCN measured anywhere in scope is **12** — `Sl`
(`LibKa0s/Slash.lua:527-550`), three under the cap — followed by `groupContext`
(`LibKa0s/Perf.lua:496-510`) at 11. Nothing is close enough to the line to carry a disposition.

Read that headroom with `lizard`'s Lua behavior in mind: it counts every `and`/`or` short-circuit as
a decision, so a run of `t.k = rec.k or D.k` defaulting lines scores as branching that is not there
(`performance-§10`). A library this defaulting-heavy scoring a max of 12 means the real control flow
is flatter still.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `tests/test_options_widgets.lua` | 1114 | **Accepted.** A flat list of independent widget cases — length here is case count, not tangle. Split by widget family if it crosses 1500. |
| 1000–1500 (on notice) | `LibKa0s/Perf.lua` | 1052 | **Accepted for now, and the one to watch.** The only shipped file in the band, and the largest single surface the eight consumers bind against. Its avg CCN is low and its worst function is 11, so this is breadth rather than knots; the sampler and the group/scenario bookkeeping are the seam if it grows. |

No file is over the 1500 cap. Both band entries are baselines — neither "newly crossed," because
there is no previous run for them to have crossed since.

## Actions

1. **Ship the kit's root-detection fix to the consumers.** `testkit/run-automated-tests.sh` no longer
   requires a `.toc`; the eight vendored copies are unaffected in behavior (they all have one) but
   drift from the master copy until re-vendored, and `tests/test_kitsync.lua` only enforces the two
   copies *in this repo*. Nothing catches consumer drift automatically.
2. **Consider `tests/perf.lua` for this repo.** Named here because the `perf` skip above is a
   standing fact with no owner: no deviation ID, no review finding, nothing tracking it. It is new
   here. LibKa0s is where `performance-§9`'s zero-overhead evidence would be most load-bearing, since
   every consumer inherits the instrumentation rather than writing it.
3. **`.luacheckrc` excludes `tests/`**, so the `0/0` above covers the 8 library files and the 3
   `testkit/` sources and none of the test code. Recorded so the clean row is not read as wider than
   it is; no change proposed in this run.
