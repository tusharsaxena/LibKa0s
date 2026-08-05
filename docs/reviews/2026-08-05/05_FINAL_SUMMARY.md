# Final summary — LibKa0s review cycle, 2026-08-05

> **Status: written ahead of implementation.** This document describes the cycle **assuming every
> change in `02_PROPOSED_CHANGES.md` was applied and every check in `03_SMOKE_TESTS.md` passed.**
> Fill in the sign-off pointers and the commit range when that is actually true; nothing here should
> be read as a record of work already done.

## Headline

A full review of LibKa0s found **no Critical and no High defects**. The shipped library is sound: no
taint exposure, no protected-value leak, no deprecated API, every combat guard that matters present
and genuinely tested, and a suite that caught eight of nine deliberate mutations into load-bearing
guards. What this cycle fixed instead is the repo's own honesty about itself — two release couplings
that `docs/releasing.md` describes as enforced and were not, one test that claimed to pin four
descriptor rules and pinned three, and one docstring that told adopters a bracket costs less than it
does. Plus two one-line fixes in `Perf.lua`: a keyless bracket close no longer raises in the middle
of a live capture, and a cancelled run no longer lends its character-and-zone stamp to the next
report.

The theme is small and specific: **this library's gates are excellent, and the two that were left to
memory are now mechanical.**

## Counts

`Critical fixed: 0, High fixed: 0, Medium fixed: 4, Low fixed: 2`

No findings deferred. F-004 is fixed in its documentation half unconditionally; its measurement half
(a `tests/perf.lua` zero-overhead scenario) is optional under `performance-§9`, which keeps scenarios
per-addon — if it was skipped, record that here as the one deliberate deferral, with the note that
the claim it would pin stays **unverified** until a consumer's own scenario covers the
`P.Open`/`P.Close` pair.

## Changes by theme

### Theme A — the last two remembered couplings became mechanical

**What changed.** `tests/run.lua`'s two hand-maintained lists are now checked against their sources:
a new case parses `LibKa0s/LibKa0s.xml` and asserts the runner loaded exactly those files in that
order, and a second asserts every `tests/test_*.lua` on disk is a declared suite. A third case, in
the versioning suite, fails when the live version key of any of the five majors has no document under
`docs/api/`. `docs/releasing.md` was corrected in two places: step 3 now names `loadAll` alongside
`MAJORS`, and the sentence claiming `test_versioning.lua` already gated API documents was replaced —
it now does.

**Why it mattered.** Both gaps were silent and both were measured during the review. A new file added
to `LibKa0s.xml` and forgotten in `run.lua` left the suite at 480/480 green while the file — which
ships to every consumer and loads in the client — was never executed by any test. A suite file added
to `tests/` and not declared contributed nothing, and a deliberately failing one still reported green.
These are precisely `testing-§9`'s two named silent failure modes, live in the repo `testing-§10`
points at as the reference implementation. The API-document gap inverted the priorities: the kit —
one folder, byte-identity gated, no version negotiation — was enforced, while the five negotiated
majors vendored into eight addons were not.

**Findings covered:** F-001, F-002. **Changes implemented:** C-1, C-2.

**Files touched:**
- `tests/run.lua`
- `tests/test_loadlists.lua` *(new)*
- `tests/test_versioning.lua`
- `docs/releasing.md`
- `docs/test-cases.md`

### Theme B — claims corrected to match what is true and what is checked

**What changed.** The four descriptor arms in `tests/test_perf_core.lua` now assert **which** field
the error names, using the kit's `assertError`, each carrying a `-- red under:` comment naming the
mutation that reddens it. The `P.Open`/`P.Close` docstring in `LibKa0s/Perf.lua` no longer says a
bracket costs "one boolean test and nothing else" — it states the two call frames, points at
`performance-§2`'s inline form as the right shape on a per-frame path, and keeps the pair's
multi-exit rationale. The current API document says the same and tells an adopting addon that its own
zero-overhead scenario must cover whichever form it uses.

**Why it mattered.** A test that asserts only *that* something raised passes just as happily on a
typo in the test. Measured: deleting the `name` requirement from `Perf.lua` left the whole suite green
at 480/480, because a later line indexes `d.name` and raises anyway — with a message that names
nothing. And a docstring that understates a hot-path cost is how a consumer stops using the idiom the
standard mandates, without ever being told there was a trade.

**Findings covered:** F-003, F-004. **Changes implemented:** C-3, C-4.

**Files touched:**
- `tests/test_perf_core.lua`
- `LibKa0s/Perf.lua` *(comment only)*
- `docs/api/Perf/version-7.3-docs.md`
- `tests/perf.lua` *(new, optional)*

### Theme C — two small `Perf.lua` correctness fixes

**What changed.** `P.Note` refuses a non-string key instead of raising `table index is nil`, so a host
that writes `P.Close(t0)` without its bucket key no longer takes down whatever was measuring — a
failure that only ever appeared **inside a live capture**, in a user's session. And `P.Cancel` now
clears `P.context` alongside `P.label`, so a typed `perf report` after a cancel prints an empty report
rather than an empty report wearing the discarded run's character, realm, spec and zone.

**Why it mattered.** Both were the opposite of the fail-early care the rest of the file shows: the
descriptor raises a framed message for a missing `name`, `sv`, `suspend`, `resume` or bucket key, but
the one mistake that surfaces mid-fight had no guard at all. The context leak is cosmetic, but these
records are read weeks later and a stale who/where reads as data.

**Findings covered:** F-005, F-006. **Changes implemented:** C-5, C-6.

**Files touched:**
- `LibKa0s/Perf.lua`
- `tests/test_perf_core.lua`
- `tests/test_perf_run.lua`

## API / behavior changes

Additive and non-breaking. A host written against `Perf.lua` minor 6 is correct here unmodified.

- **No member added, removed or repurposed.** `library-stack-§7`'s additive-only rule is untouched.
- **`P.Note(key, ms)`** now returns without writing when `key` is not a string. Previously it raised.
  No host doing the right thing observes a difference.
- **`P.Cancel()`** now clears `P.context`. A record built after a cancel carries no context block —
  representable already, since `P.ContextLines(nil)` returns `{}`.
- **No slash subcommand added, renamed or removed** — the library registers none by design
  (`LibKa0s/Perf.lua:870-876`).
- **No locale key added or renamed.** `lib.STRINGS` is unchanged in all five majors.
- **No new descriptor field** in any major.

## Saved-variable / migration notes

**None.** `lib.SCHEMA` stays at 2 and the record shape is unchanged — a record with no `context` was
already representable, since `P.Context()` degrades every lookup to `"?"`. Existing
`<Addon>PerfDB` rings are read and appended to exactly as before; no reset and no migration.

## Deprecated-API migrations

**None — the sweep found nothing to migrate.** Recorded so a future reviewer need not repeat it:

| Checked for | Found in this repo |
|---|---|
| `InterfaceOptions_AddCategory` | none — `Settings.RegisterCanvasLayoutCategory` + `RegisterAddOnCategory` (`LibKa0s/Options.lua:548-571`) |
| `Settings.OpenToCategory(frame)` | none — passed `mainCategory:GetID()` (`LibKa0s/Options.lua:571`, `:645`) |
| `GetSpellInfo`, `UnitAura*`, `GetContainerItemInfo`, `IsAddOnLoaded` | none — the library calls no spell, aura or container API at all |
| `SetBackdrop` without `BackdropTemplate` | none — every backdrop frame inherits it (`Core.lua:141`, `DebugLog.lua:281`, `:448`, `PerfPanel.lua:156`) |
| `setmetatable` on a Blizzard widget | none |

## Performance impact

**No measured before/after numbers, and none is claimed.** No change in this cycle alters a hot path:
C-5 adds one type test on the **on** path only, C-6 clears a field on an explicit user action, and
C-4 is a comment plus a document. `performance-§2`'s off-path contract — no allocation, no call, no
format inside a dormant bracket — is unchanged.

If M3-T1 shipped the optional `tests/perf.lua`, record its first run's **per-iteration allocation**
figures for the three arms (unbracketed, inline `P.on` idiom, `Open`/`Close` pair) here, with the
scenario name beside each. Until then the `perf` suite stays a documented `skip` in
`docs/automated-tests/RESULTS.md` and the cost claim is **unverified**, which is what that file
already says.

## Test and complexity movement

- **Pass count: 480 → 485.** `docs/test-cases.md` was regenerated with
  `lua tests/run.lua --list` in the **same commit** as each change that moved the count, never as a
  follow-up (`testing-§5`). This repo has no README `[tests]` badge — it is a library, not a
  player-facing addon — so there is no badge to move.
- New cases: 2 (load lists), 1 (API document), 1 (keyless bracket), 1 (context cleared). One existing
  case strengthened rather than added (the descriptor arms).
- If `tests/perf.lua` shipped, its scenarios appear in **neither** `docs/test-cases.md` nor any pass
  count (`testing-§7`).
- **Complexity: no movement expected.** Today's maximum is CCN **12** (`Sl:CliSet`,
  `LibKa0s/Slash.lua:527-550`), with `groupContext` at 11 behind it and zero functions warned on.
  C-5 adds one guard to a CCN-2 function. `LibKa0s/Perf.lua` stays in `layout-§1`'s 1000–1500
  on-notice band at roughly 1054 lines, and remains the one shipped file there. To be confirmed by
  the next release's regeneration — not by running `lizard` into the repo now.

## Known follow-ups

- **`tests/perf.lua`, if it was deferred.** `performance-§9` keeps scenarios per-addon, so the
  library is not obliged — but the `Open`/`Close` off-path cost is a number no consumer's scenario is
  currently asked to produce, and until one does, `performance-§2`'s required evidence for the pair
  does not exist anywhere in the collection.
- **An `xmlFiles()` derivation in `testkit/loader.lua`**, mirroring `tocFiles`. Deliberately not done:
  `library-stack-§7`'s promotion bars need two consumers with the same semantics, and there is
  exactly one library repo. Revisit if a second appears — never on frequency alone.
- **A second automated-test run** to turn `RESULTS.md`'s single row into a trend. The current zero-CCN
  result is a first measurement, and that file correctly says so; it is not yet a streak.

## Verification evidence

- Manual in-client checklist: [`03_SMOKE_TESTS.md`](03_SMOKE_TESTS.md) — sign-off table to be filled
  in by whoever runs it, **in a consuming addon**, since LibKa0s ships nothing a player installs.
- Headless evidence at review time: `luacheck` 0/0 over 11 files; `lua5.1 tests/run.lua`
  480/480; `--list` byte-identical to `docs/test-cases.md`; `lizard` 0 warnings, max CCN 12;
  `diff -r testkit/ tests/_kit/` empty. Recorded in
  [`01_FINDINGS.md`](01_FINDINGS.md)'s measurement block.
- Commit range / PR: _to be filled in._

## Suggested commit message

```
review 2026-08-05: close the last two remembered release gates, two Perf fixes

No Critical or High findings — the shipped library reviewed clean on taint,
protected values, deprecated APIs and combat guards, and eight of nine mutation
probes into load-bearing guards were caught by the existing suite.

What this cycle fixes is the repo's own honesty about itself:

- F-001  tests/run.lua's library-file list and suite list are now gated against
         LibKa0s.xml and the tests/ directory. Both gaps were silent and both
         were measured: a new file in the XML, and a deliberately failing
         unlisted suite, each left the run at 480/480 green (testing-§9).
- F-002  docs/releasing.md claimed test_versioning gated docs/api/. It didn't.
         Now it does, for all five majors (library-stack-§7).
- F-003  The Perf descriptor test asserted "it raised" without asserting what.
         Deleting the `name` requirement left the suite green; it no longer does
         (testing-§12).
- F-004  P.Open/P.Close cost two calls, not "one boolean test and nothing else".
         Docstring and API document corrected; performance-§2's inline idiom is
         named as the right shape on a per-frame path.
- F-005  P.Note refuses a non-string key instead of raising mid-capture.
- F-006  P.Cancel clears P.context, so a report after a cancel no longer wears
         the discarded run's character and zone.

Perf.lua minor 6 -> 7 (PerfPanel unchanged at 3); changelog entry and
docs/api/Perf/version-7.3-docs.md accompany it. Consumers re-vendor the whole
LibKa0s/ folder in a commit of their own.

Tests: 480 -> 485, docs/test-cases.md regenerated with each change.
```
