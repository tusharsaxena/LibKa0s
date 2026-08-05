# Execution plan — LibKa0s, 2026-08-05

Implements [`02_PROPOSED_CHANGES.md`](02_PROPOSED_CHANGES.md). Six changes, three milestones.

**Upstream milestone: none.** This repo is the upstream and vendors no foreign code. `tests/_kit/` is
this repo's own `testkit/` re-vendored into itself; no task below edits `tests/_kit/` — the two tasks
that could imply it (M1-T1, M1-T2) were deliberately scoped to `tests/run.lua` and the suites for
exactly that reason. The one cross-repo obligation is the consumer re-vendor in M3, which is its own
task with its own commit.

---

## Milestone 1 — close the two silent gates

**Why first:** these are pure test/doc additions, they touch no shipped file, and once they are in
place every later milestone is protected by them — M2's minor bump cannot land without its API
document, which is the point of doing C-2 before C-5/C-6.

**Done when:** `lua tests/run.lua` is green at 483 cases; both C-1 falsification probes and the C-2
probe go red on demand (`03_SMOKE_TESTS.md` C-1, C-2); `docs/test-cases.md` regenerated and matching;
`docs/releasing.md` no longer claims a gate that does not exist.

| Task | Owner role | Findings / changes | Files touched |
|---|---|---|---|
| M1-T1 | test-harness-engineer | F-001 / C-1 | `tests/run.lua`, `tests/test_loadlists.lua` (new), `docs/test-cases.md` |
| M1-T2 | test-harness-engineer | F-002 / C-2 | `tests/test_versioning.lua`, `docs/test-cases.md` |
| M1-T3 | test-harness-engineer | F-003 / C-3 | `tests/test_perf_core.lua`, `docs/test-cases.md` |
| M1-T4 | docs-maintainer | F-001, F-002 | `docs/releasing.md` (step 3's `loadAll` half-sentence; the false claim at line 146) |

**Concurrency:** M1-T1, M1-T2 and M1-T3 touch disjoint suite files **but all three regenerate
`docs/test-cases.md`** → they **must serialize** on that file. Run them in order T1 → T2 → T3 and
regenerate the inventory once per task (the standard requires the inventory to move with the change
that moves the count, not in a batch at the end). M1-T4 touches only `docs/releasing.md` and is
**parallelizable** with all three.

**Checkpoint 1 (human):** before M2. Confirm each new case has been *seen red* — a case that has only
ever been green is unfalsified, and `testing-§12` is the whole reason this milestone exists. Confirm
the total is 483 in both the runner output and `docs/test-cases.md`.

---

## Milestone 2 — the two `Perf.lua` fixes and the release paperwork they force

**Why second:** these are the only shipped-code changes, and they trigger a minor bump whose
paperwork M1-T2 now enforces mechanically.

**Done when:** `Perf.lua` `MINOR` is 7; `CHANGELOG.md` carries a `Perf.lua minor 7` entry;
`docs/api/Perf/version-7.3-docs.md` exists and `6.3` is marked superseded with its *Moving to …*
section; `docs/api/README.md` has the new row; the suite is green at 485.

| Task | Owner role | Findings / changes | Files touched |
|---|---|---|---|
| M2-T1 | lua-engineer | F-005 / C-5 | `LibKa0s/Perf.lua`, `tests/test_perf_core.lua`, `docs/test-cases.md` |
| M2-T2 | lua-engineer | F-006 / C-6 | `LibKa0s/Perf.lua`, `tests/test_perf_run.lua`, `docs/test-cases.md` |
| M2-T3 | release-engineer | C-5, C-6 | `LibKa0s/Perf.lua` (`MINOR` → 7), `CHANGELOG.md`, `docs/api/Perf/version-7.3-docs.md` (new), `docs/api/Perf/version-6.3-docs.md`, `docs/api/README.md` |
| M2-T4 | docs-maintainer | F-004 / C-4 (docs half) | `LibKa0s/Perf.lua` (comment at 378-381), `docs/api/Perf/version-7.3-docs.md` |

**Concurrency:** M2-T1, M2-T2, M2-T3 and M2-T4 **all touch `LibKa0s/Perf.lua`** → **must serialize**,
in the order T1 → T2 → T4 → T3. T3 last, deliberately: the minor bump and its changelog entry are the
*record* of everything the file's other tasks did, and bumping first invites a second bump when the
next task lands. T4 before T3 so the corrected wording is already in the file the new API document is
written from.

*Note for M2-T3:* bump **only** `Perf.lua`. `PerfPanel.lua` did not change, so it stays at 3 and the
new version key is `7.3` — lockstep bumping discards the narrow-skew property
(`library-stack-§7`, `docs/releasing.md:25-30`).

**Checkpoint 2 (human):** before M3. Verify `lua tests/run.lua` is green **and** that temporarily
removing the new API document turns it red (M1-T2 actually protecting M2's work is the thing being
confirmed here, not the document's existence). Verify `git diff` on `LibKa0s/Perf.lua` is three
substantive lines plus a comment — a large diff here means something else was refactored in passing.

---

## Milestone 3 — the optional scenario, and the re-vendor

**Why last:** the scenario is measurement, not correctness, and the re-vendor must carry the finished
folder.

**Done when:** if `tests/perf.lua` was added, `lua tests/perf.lua` runs and its scenarios appear in
**neither** `docs/test-cases.md` nor any pass count; and every consumer that vendors LibKa0s has a
standalone re-vendor commit whose `diff -r --strip-trailing-cr` is empty.

| Task | Owner role | Findings / changes | Files touched |
|---|---|---|---|
| M3-T1 | perf-engineer | F-004 / C-4 (scenario half, optional) | `tests/perf.lua` (new) |
| M3-T2 | release-engineer | all | each consumer's `libs/LibKa0s/` — **one commit per consumer repo** |

**Concurrency:** M3-T1 touches only `tests/perf.lua` (not part of the ship payload) and is
**parallelizable** with M3-T2. M3-T2 is N independent commits in N different repos — parallelizable
across repos, but each is its own commit, never folded into a feature diff
(`library-stack-§7`, *Vendor sync*).

*Boundary for M3-T2:* the ship payload is the inner `LibKa0s/` folder only. `tests/`, `testkit/` and
`docs/` stay upstream. Copy the whole folder; never individual files.

**Checkpoint 3 (human):** `03_SMOKE_TESTS.md` executed end to end in one consumer, sign-off table
filled in. In particular C-4's step 1 (`MODULES` reports `Perf = 7`) — that is what proves the
re-vendor actually happened rather than the client still running the old copy.

---

## Critical path

```
M1-T1 → M1-T2 → M1-T3  ──┐                    (serialized on docs/test-cases.md)
M1-T4 ───────────────────┤
                         ├→ Checkpoint 1 → M2-T1 → M2-T2 → M2-T4 → M2-T3 → Checkpoint 2 ─┐
                                                     (serialized on LibKa0s/Perf.lua)     │
                                                                                          ├→ Checkpoint 3
                                                                              M3-T1 ──────┤
                                                                              M3-T2 ──────┘
```

The critical path is M1-T1 → M1-T2 → M1-T3 → M2-T1 → M2-T2 → M2-T4 → M2-T3 → M3-T2. M1-T4 and M3-T1
are free.

## Commit strategy

One commit per task; a task that regenerates `docs/test-cases.md` includes the regenerated file in
its own commit, never in a follow-up.

- `tests: gate run.lua's load lists against LibKa0s.xml and the suite directory (F-001)`
- `tests: fail a release whose major has no API document (F-002)`
- `tests: assert which descriptor field the Perf validation names (F-003)`
- `docs: releasing.md — loadAll is part of adding a module, and test_versioning does not gate api/ (F-001, F-002)`
- `perf: refuse a bucket write with no key rather than raising mid-capture (F-005)`
- `perf: clear the capture context on cancel (F-006)`
- `perf: correct the Open/Close cost claim — two calls, not "nothing else" (F-004)`
- `release: Perf.lua minor 7 — changelog, api/Perf/version-7.3-docs.md`
- `perf: offline zero-overhead scenario for the Open/Close pair (F-004)` *(optional)*
- `vendor: re-vendor LibKa0s (Perf.lua 7)` *(one per consumer repo)*
