# `testkit` — version 15

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `loader.lua`, `mock_base.lua`, `vendor_sync.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **15** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.27.0 |
| Status | **Current** |
| Supersedes | [version 14](version-14-docs.md) — `stubFrame` tracks a real enabled state |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `15` |

## What changed at this version

One file, `run-automated-tests.sh`. No Lua surface moves at all: `framework.lua` changes for
`Kit.VERSION` itself and for nothing else, and `loader.lua`, `mock_base.lua` and `vendor_sync.lua`
are untouched. Every assertion, every mock and every loader behaviour is exactly what version 14
shipped.

What moves is the **record** — `docs/automated-tests/RESULTS.md` and the run manifest — in five
places.

| | Was | Is at 15 |
|---|---|---|
| The skipped count | Dropped. The summary regex could not span `, N skipped`, so the total read empty and fell back to `passed + failed` | Read by label, reported in the console line, in the manifest as `suites.tests.skipped`, and in the table's **Tests** cell |
| The **Tests** cell | `passed/total` | `passed/skipped/total`, under the same column name |
| The **Version** cell on a release run | `$ADDON_VERSION` — the version being *replaced* | `version → release` when the manifest carries a `release` |
| The lead-in | Written only when `RESULTS.md` was absent or its header mismatched, so no existing repository could ever receive a correction to it | Regenerated on every run |
| The complexity watch list and the four standing sections | Never written by the runner at all | Generated from this run's own `lizard` output and its manifest |

### Why: a skipped case was reading as a case that did not exist

`framework.lua` has printed `N passed, N failed, N skipped, N total` since the skip status was added
at kit 8. The runner's regex was
`'[0-9]+ passed, [0-9]+ failed(, [0-9]+ total)?'`, which cannot span `, N skipped` — so the match
stopped at `failed`, `awk '{print $5}'` read past the end of it, `TESTS_TOTAL` came back empty and
fell back to `passed + failed`. A suite with three declared skips recorded as a suite three cases
smaller, on every row of every consumer's trend line, and the manifest had no `skipped` key to
contradict it with.

The figures are now read **by their labels** rather than by field position. That is the actual fix:
the summary has grown a column twice, and both times a positional read broke silently on the way
past — `$5` meant "total" before the skip column existed and means "skipped" after it.

```json
"tests": { "status": "pass", "passed": 773, "failed": 0, "skipped": 0, "total": 773, ... }
```

`suites.tests.skipped` is additive. Nothing reads it as a gate: `automated-tests-§3`'s release gate
evaluates `status` and `failed`, and a skip is **NOT EVALUATED** there rather than passed.

### Why: a release run was filed against the version it replaced

`--release X.Y.Z` is produced **before** the tag (`automated-tests-§6`), so the `.toc` still carries
the outgoing version while the run is the incoming one's evidence. Rendering `$ADDON_VERSION` alone
attributed each release's numbers to its predecessor: this repo's own `RESULTS.md` carries a row
reading `Version 1.24.0` whose manifest says `"release": "1.25.0"`. The cell now reads
`1.24.0 → 1.25.0`, which is both facts and no guess.

### Why: the corrected lead-in could not reach a single repository

The runner had two write paths. An `awk` that inserted one row beneath the header, and a
create-the-file branch that carried the header, the lead-in and everything else. The second was
reached only when `RESULTS.md` was **absent** or its column set had changed — which, in a repository
that has ever run this script, is never. So the four-checkpoint lead-in, written to replace a
two-sentence version that reads as *"perf and complexity gate nothing"* (false at the release gate),
sat in unreachable code while ten repositories carried the text it was meant to replace.

At 15 the file is **regenerated whole on every run**, rows preserved in order and the new row
prepended. Generated prose can then move with the script that generates it, which is the point of
generating it.

The one guard that stays is the one that matters: a `RESULTS.md` whose **header** is not the current
column set is still left completely alone, with a warning. Rewriting it would drop every previous
row, and that is the one thing a trend line must never do.

### Why: the watch list and the standing sections had no producer

`automated-tests-§4` **MUST**s a complexity watch list — two tables, warned functions and files by
`layout-§1` band — and a short standing section for each of the four suites. `documentation-§3`
calls `RESULTS.md` generated and never hand-edited. Until this revision the runner wrote one table
row and a fixed lead-in and **nothing else**, so both rules could not be honoured by anybody: the
mandated narrative had no generator, and hand-writing it violated the other rule.

The state on the far side of that collision was not a badly-graded file. It was no file: the record
went stale in ten of ten repositories. `MultiMeters/docs/automated-tests/RESULTS.md` headed a
hand-written watch list *"Current as of `20260809-195454`"* and reported **"None — `lizard` reports 0
warnings"** directly above a table row recording **19**; this repository's own test-suite section
opened with **"499 cases"** against a suite running 764.

The standard settled it at v2.39.0 (`automated-tests-§4`, *the one boundary*) and this is the code
half. Everything below the table is now the runner's, generated from the run that measured it.

## The one boundary

**Exactly one cell in `RESULTS.md` is authored: the watch list's `Disposition`.**

The runner carries a disposition forward **verbatim** while its entry is unchanged, and leaves the
cell **blank** where the entry is new. A blank disposition is the record telling its owner that
something crossed a threshold and nobody has ruled on it yet — which is a stronger signal than a
sentence somebody was supposed to remember to write.

What counts as "the same entry":

- **Functions table** — the same `Function` at the same `Location`, where Location is the **file**,
  not a line range. Pinning the key to line numbers would blank every disposition in a file the
  moment anything above it grew a line, which is exactly the re-arguing the boundary exists to stop.
  Where a file holds two warned functions of the same name — MultiMeters has `Cell` twice in
  `modules/Row.lua` — the measured **CCN** breaks the tie. A tie the CCN cannot break either leaves
  the cell blank: attaching one entry's ruling to a different entry is worse than asking for a new
  one.
- **Band table** — the same `File` in the same `Band`. A file that crossed from *on notice* to *over
  cap* is a new entry and is owed a fresh ruling.

A disposition is never invented, and one that still applies is never dropped — those are the two
ways a runner can destroy the only judgment this file carries.

**If a generated sentence is wrong, the fix is here, in LibKa0s, and reaches the consumer on its
next re-vendor.** Editing the vendored `tests/_kit/` copy is forbidden by `testing-§1` and is
reverted silently by that re-vendor, after which the record is stale again.

## What the generated sections say

`## Test suite` — the case count split into passed / failed / skipped, the bundle's `test-cases.md`
named as the authority, and the trend: flat across three or more runs (which is the coverage-gap
signal the table cannot show), unchanged, or moved, with both figures.

`## Lint` — warnings, errors and file count, plus **what `.luacheckrc` excludes**, restated every
run. A `0/0` means nothing without its scope.

`## Perf` — the scenario count, or a `skip` that says **which** of `automated-tests-§3`'s two
sanctioned reasons it is: no `tests/perf.lua` at all (the record is silent about runtime cost), or a
tooling gap on this host (install it and re-run).

`## Complexity watch list` — the run's max CCN, function count, warned count and band counts, then
the two tables, then the reading note that `lizard` scores every `and`/`or` short-circuit as a
decision.

## For consumers: the counts do not move, the record does

Nothing in the Lua surface changes, so **no suite gains or loses a case** on adoption. What changes
is the file the next run writes.

Expect, on the first run after re-vendoring:

- the **Tests** column gains a middle figure — `773/773` becomes `773/0/773`. Older rows keep the
  two-part shape and are preserved untouched; the trend reads across the change, because both shapes
  end in the total;
- the lead-in above the table is replaced with the four-checkpoint text;
- a complexity watch list and four standing sections appear below the table, with **every
  disposition blank** — there was no generated table to carry them forward from. Ruling on those
  blanks is the owner's step 3 in `AUTOMATED_TESTS.md`, and it is a one-time cost;
- any hand-written prose below the table is replaced. Copy a disposition worth keeping into the
  generated table's cell **in the same commit**, or it is gone.

That last point is the only sharp edge in this revision, and it is deliberate: hand-written prose
below the table is the thing being retired.

## Adopting it is one commit

```sh
cp -r testkit/. <Addon>/tests/_kit/
diff -r testkit <Addon>/tests/_kit             # must be empty
cd <Addon> && lua tests/run.lua && luacheck .
```

There is nothing to switch on and nothing to configure. The suite should be green immediately and at
the same count; if it is not, the failure is not this kit revision.

## Vendoring

Whole-folder, from the library repo's root — the same cwd `docs/releasing.md` assumes:

```sh
cp -r testkit/. <Addon>/tests/_kit/
diff -r testkit <Addon>/tests/_kit             # must be empty
cd <Addon> && lua tests/run.lua && luacheck .
```

**Never edit `tests/_kit/` in a consumer.** A kit problem is a finding to fix here and re-vendor; a
local patch is a fork nobody knows about, and the next re-vendor silently reverts it.

LibKa0s is a consumer on the same terms as every addon: it reaches its own kit through `tests/_kit/`
rather than into `testkit/` directly, so `diff -r testkit tests/_kit` is the same gate here as it is
downstream, and a kit change that would break a consumer breaks this repo first.

## Bumping the revision

1. Change the kit, with its test.
2. Bump `Kit.VERSION` at the top of `testkit/framework.lua`.
3. Write `docs/api/testkit/version-<N>-docs.md`; mark this one `Superseded` and fill in its
   `Superseded by`. `tests/test_kitsync.lua` fails if the document for the live version is missing.
4. Re-vendor into `tests/_kit/` here **and** into every consumer's `tests/_kit/`, then run each
   repo's suite.
5. Add the row to [`../README.md`](../README.md).
