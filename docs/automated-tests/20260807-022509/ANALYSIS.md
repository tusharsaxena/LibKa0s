# Analysis — 20260807-022509

- **Addon:** LibKa0s 1.8.1
- **Verdict:** green
- **Commit:** ad2d3262a2919e2e9b05e24abbd9f19db456909a (master), clean
- **Previous run:** [`20260806-180959`](../20260806-180959/) — LibKa0s 1.8.0, green, the `--release 1.8.1` run

## Headline

Both gating suites are clean and nothing moved. This is the **first post-tag run on v1.8.1's own
bytes** — the previous row recorded the release run that produced the tag, taken on a dirty tree at
`d77e19d` while the manifest still read `"addonVersion": "1.8.0"`; this one is that tree committed,
clean, at `ad2d326`, and every measured figure is identical. That identity is the point of running
it: the release record and the committed tree agree, so nothing slipped in between the measurement
and the tag.

There is nothing to act on in the code. One standing item is worth naming, and it is about the
*record* rather than the library: the v1.8.1 release run ([`20260806-180959`](../20260806-180959/))
carries no `ANALYSIS.md`, which `automated-tests-§5` makes a MUST at a release. That bundle is
frozen and is not edited to fix it — this analysis is where it gets said.

## Suites

Every row links its artifact, so a reader can get from a figure to the evidence in one click. A
skipped suite links nothing — there is no artifact — and says what was not measured.

| Suite | Status | Result | Artifact | Moved since 20260806-180959 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 12 files | [`lint.txt`](lint.txt) | unchanged — 0/0 over the same 12 files |
| tests | pass | 498 passed, 0 skipped, 0 failed, 498 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | unchanged — `test-cases.md` is byte-identical to the previous run's |
| perf | skip | not run — the repo ships no `tests/perf.lua`, so there are no offline scenarios (0 scenarios) | — (no artifact) | unchanged — a permanent skip, not a pass |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | unchanged — `complexity.txt` is byte-identical to the previous run's |

**Complexity is reported in full**, because a single figure cannot be compared across a change in
size. Every value below is `manifest.json`'s `suites.complexity`, which records all eight fields of
`lizard`'s footer; the footer itself is at the bottom of [`complexity.txt`](complexity.txt).

| Metric | Value |
|---|---|
| Total NLOC | 8557 |
| Functions | 1237 |
| Avg NLOC / function | 6.3 |
| Avg CCN | 1.9 |
| Max CCN | 14 |
| Avg tokens / function | 48.6 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 2 |
| Files over the 1500 cap | 0 |

The averages are the part that carries the signal. Nothing in this repo grew this run, so totals and
averages held together — but the reason to print both is that a total which rises with the addon is
a different fact from an average that rises because the code got denser, and only the second is a
complexity signal.

`perf` is the one suite that is not a clean pass, and it is a **skip — not a failure, and not a
pass**. The manifest's `skipReason` is `no tests/perf.lua — this addon ships no offline scenarios`,
the first of `automated-tests-§3`'s two sanctioned reasons: there was nothing to run, rather than a
tool that was missing. This run is therefore **silent about runtime cost**, and the green verdict
above says nothing about it either way. That is a standing fact about the repo, not a regression —
[`../README.md`](../README.md) § *Why that skip is permanent, and what closes the gap instead*
carries the dated disposition and the condition that would reopen it.

## What moved

- **lint** — nothing. 0 warnings / 0 errors across 12 files, both runs. The file count held at 12,
  so no source entered or left `luacheck`'s scope.
- **tests** — nothing. 498 passed / 0 skipped / 0 failed / 498 total, both runs, and this bundle's
  `test-cases.md` diffs clean against the previous bundle's, so the inventory itself is unchanged
  rather than merely the count.
- **perf** — nothing, and nothing could: no scenarios exist to move.
- **complexity** — nothing. `complexity.txt` is byte-identical to the previous run's; NLOC 8557,
  1237 functions, avg NLOC 6.3, avg CCN 1.9, max CCN 14, avg tokens 48.6 and 0 warnings all held.
- **manifest fields that are not measurements** — `addonVersion` 1.8.0 → 1.8.1, because the tag now
  exists and the runner derives the version from the newest tag; `git.dirty` true → false; and
  `release` `"1.8.1"` → `null`, because this is an ordinary run rather than a release run.

Four rows now stand at 0 lint findings, 0 test failures and 0 CCN warnings. Three of them share
their figures exactly, which makes this a held result rather than a trend — nothing has changed
since `20260805-123655` in anything `luacheck` or `lizard` can see.

## Complexity watch list

### Functions `lizard` warned on

**None.**

That is a result, not an empty section. Nothing in `LibKa0s/` or `testkit/` exceeds CCN 15, so no
function carries a disposition. The highest three in scope, read off
[`complexity.txt`](complexity.txt), are unchanged from the previous two runs: `Kit.run` at 14
(`testkit/framework.lua:394-433`), `Kit.assertSuiteInventory` at 13
(`testkit/framework.lua:277-316`) and `Sl` at 12 (`LibKa0s/Slash.lua:527-550`). All three are
dispatch and defaulting rather than tangled control flow — `lizard` scores every Lua `and`/`or`
short-circuit as a decision — so the number to watch is a new *arm*, not a new line.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Perf.lua` | 1163 | **Accepted — the one to watch.** Unchanged at 1163 since `20260805-123655`. Still the only shipped file in the band and the widest surface the consumers bind against. Its worst function is 11, so this is breadth rather than knots; the sampler and the group/scenario bookkeeping are the peel seam if it crosses 1500. Carried as Accepted across **two** consecutive release runs — the next release run is the third, at which `automated-tests-§4` owes a fix or a tracked deviation ID with an owner. |
| 1000–1500 (on notice) | `tests/test_options_widgets.lua` | 1114 | **Accepted, unchanged.** A flat list of independent widget cases; the length is case count, not tangle. Split by widget family if it crosses 1500. Same two-of-three release count as the row above. |

Nothing is over the 1500 cap, and nothing newly crossed a band this run — both entries were already
in the band at `20260805-002859`.

## Actions

1. **The v1.8.1 release bundle carries no `ANALYSIS.md`.**
   `docs/automated-tests/20260806-180959/manifest.json` records `"release": "1.8.1"`, and
   `automated-tests-§5` makes the write-up a MUST at a release. The bundle is frozen and is **not**
   back-filled; the gap is recorded here instead. It is new — no deviation ID or review finding
   currently owns it — and the fix belongs to whatever produces the next release run.
2. **Two watch-list dispositions are two releases into a three-release shelf life.**
   `LibKa0s/Perf.lua` and `tests/test_options_widgets.lua` have been carried as *Accepted* through
   the v1.8.0 and v1.8.1 release runs. At the next release each is owed either a fix or a tracked
   deviation ID with an owner (`automated-tests-§4`, anti-pattern #53). Nothing is due in this run.
