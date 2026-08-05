# Analysis — 20260805-123655

- **Addon:** LibKa0s 1.7.0 *(the runner derives version from the newest tag; this run is the record for the **v1.8.0** release being cut, `"release": "1.8.0"` in the manifest)*
- **Verdict:** green
- **Commit:** 4ec221e6bfbdd49a0073c955a6bccb0249b185a9 (feat/2026-08-05-audit-review-remediation), dirty
- **Started:** 2026-08-05T12:36:55+05:30
- **Previous run:** [`20260805-002859`](../20260805-002859/) — LibKa0s 1.7.0, green

## Headline

**The first release record this library has ever had.** The previous run was a baseline taken on a
working tree nobody released, with `"release": null`; `docs/releasing.md` step 7 now makes the run a
numbered step and `--release` ties the bundle to the version, so v1.8.0 is the first tagged version
of LibKa0s whose bytes have a test record naming them.

Both gating suites are clean — `luacheck` 0 warnings / 0 errors across **12** files (up from 11: the
new `testkit/vendor_sync.lua` is inside the checked set), and the headless harness passes **498** of
498 cases (up from 480, +18 across the Options layout-publication cases, the Perf containment cases
and the new prose gate). `lizard` warns on nothing. `perf` is a **skip**, not a pass, and is expected
to stay one: this repo ships no `tests/perf.lua`.

Nothing regressed. The two numbers that moved and are worth naming are **Max CCN 12 → 14** and
`LibKa0s/Perf.lua` **1052 → 1163 LOC**, both dispositioned below and both well inside their caps.

## Suites

| Suite | Status | Result | Artifact | Moved since previous run |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 12 files | [`lint.txt`](lint.txt) | +1 file checked (`testkit/vendor_sync.lua`); 0/0 held |
| tests | pass | 498 passed, 0 failed, 498 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | +18 cases, 0 failures either run |
| perf | skip | — | — (not run) | unchanged — no `tests/perf.lua`, a permanent skip |
| complexity | pass | 0 warnings, 8555 NLOC / 1237 funcs, max CCN 14 | [`complexity.txt`](complexity.txt) | NLOC +580, funcs +36, avg CCN 1.8 → 1.9, max CCN 12 → 14 |

## What the release gate reads

`automated-tests-§3`: all four suites at `pass` plus zero functions above CCN 15. Three are `pass`
and the complexity warning count is **0**. The fourth, `perf`, is a `skip` — **NOT EVALUATED, not a
pass** — which is the known and recorded hole this repo's gate carries and which
[`../README.md`](../README.md) documents at length. The tag is cut in the knowledge that the runtime
cost of the library that supplies the collection's instrumentation is still unmeasured.

## Complexity

Nothing exceeds CCN 15. The three highest:

| CCN | Function | File |
|---:|---|---|
| 14 | `Kit.run@394-433` | `testkit/framework.lua` |
| 13 | `Kit.assertSuiteInventory@277-316` | `testkit/framework.lua` |
| 12 | `Sl@527-550` | `LibKa0s/Slash.lua` |

The two new entries are both in the kit, both from this wave, and both are dispatch rather than
tangle: `Kit.run` gained the `skip` status arm and the suite-inventory call, and
`assertSuiteInventory` is a two-way set comparison whose branches are one `if` per divergence class.
`lizard` scores every Lua `and`/`or` short-circuit as a decision, so a run of defaulting lines reads
as branching that is not there (`performance-§10`). Neither is at the cap; both are named here so a
third arm added to either is a visible move rather than a surprise.

## Files on notice

`layout-§1`'s 1000-LOC on-notice band, by raw LOC:

| File | LOC | Was | Disposition |
|---|---:|---:|---|
| `LibKa0s/Perf.lua` | 1163 | 1052 | **Accepted — the one to watch.** Still the only shipped file in the band, and it grew for the observed-containment record and the keyed `Open`/`Close` bracket. Worst function is 11 and avg CCN is 3.4, so this is breadth, not knots. The sampler and the group/scenario bookkeeping remain the peel seam if it crosses 1500. |
| `tests/test_options_widgets.lua` | 1114 | 1114 | **Accepted, unchanged.** A flat list of independent widget cases; length is case count. Split by widget family if it crosses 1500. |

Nothing is over the 1500 cap.
