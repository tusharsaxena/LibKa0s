# Analysis — 20260823-150620

- **Addon:** LibKa0s 1.9.0 (manifest `release` 1.9.1 — the pre-tag release run, see below)
- **Verdict:** green
- **Commit:** 07ce20a (master, dirty)
- **Previous run:** [`20260823-144602`](../20260823-144602/) — the pre-tag release run for v1.9.0

## Headline

Green, and the **release run for v1.9.1** (`docs/releasing.md` step 7), taken hours after the run for
v1.9.0 and for one reason: `Media.Icon` answered a path carrying `.tga`, and the first consumer to
adopt it records from a live client that this spelling draws nothing.

The numbers barely move — NLOC +7, one function, one test case — because the change is one string
concatenation. **The size of the diff is not the size of the defect.** A texture that does not load
draws nothing and raises nothing, so every suite in this bundle would have stayed green with every
icon in the collection invisible. The only thing standing between that and a release is a consumer's
own recorded experience, which is why v1.9.0 lived for about twenty minutes.

The new case (`media: the file behind an icon path is still <name>.tga on disk`) is the part worth
keeping: the path and the file it resolves to are now two different strings, and it asserts both, so
a rename cannot open a gap between them.

## Suites

| Suite | Status | Result | Artifact | Moved since `20260823-144602` |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 13 files | [`lint.txt`](lint.txt) | No change |
| tests | pass | 514 passed, 0 skipped, 0 failed, 514 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | **+1 case** — the path-to-file assertion |
| perf | skip | 0 scenarios — no `tests/perf.lua` | none — the suite did not run | No change — permanent skip |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | **NLOC +7, functions +1**; every average and the max unmoved |

**Complexity, in full** — every field of `lizard`'s footer as recorded in
[`manifest.json`](manifest.json) `suites.complexity`:

| Metric | Value | Previous |
|---|---|---|
| Total NLOC | 8869 | 8862 |
| Functions | 1270 | 1269 |
| Average NLOC | 6.4 | 6.4 |
| Average CCN | 1.9 | 1.9 |
| Max CCN | 14 | 14 |
| Average tokens | 48.9 | 48.9 |
| Functions above CCN 15 | 0 | 0 |
| Warning rate | 0.00 | 0.00 |

## What this run does not cover

Everything the v1.9.0 analysis listed, unchanged and for the same reasons: no suite opens a TGA, the
vendored-payload gate's new recursion and binary compare are exercised for real only in a consumer,
and `RegisterLSM` is driven against a stub. To which this release adds one of its own — **no test
here can tell you which spelling of a texture path the client accepts.** That is an in-game fact, it
is the fact this release turns on, and the evidence for it is a consumer's smoke test rather than
anything in this bundle.
