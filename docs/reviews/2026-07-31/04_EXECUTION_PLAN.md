# 04 — Execution Plan

Implements `02_PROPOSED_CHANGES.md`. Ten changes across four milestones.

**Standing rules for every task** (from `testing`, `versioning-git`, `library-stack-§7`):
- TDD: the covering test lands **before or with** the change, never after.
- The commit gate is green `lua tests/run.lua` **and** clean `luacheck .`. No red commits.
- Every touched library file bumps its own `MINOR` **and** gets a matching `CHANGELOG.md` entry in
  the same commit — `test_versioning.lua` enforces the pairing, so a forgotten bump is a red suite,
  not a silent non-ship.
- Files are **not** bumped in lockstep. Only the files actually edited move.
- Work on the existing `feature/libka0s-five-module-extraction` branch. Do **not** open a new branch
  (`anti-patterns` #21).

---

## File-contention map

The critical path is decided almost entirely by `LibKa0s/Options.lua`, which five changes touch.

| File | Changes touching it |
|---|---|
| `LibKa0s/Options.lua` | **C-1, C-2, C-3, C-4, C-8** |
| `LibKa0s/OptionsWidgets.lua` | C-1 (comment), C-6, C-8 |
| `LibKa0s/OptionsScroll.lua` | C-6 |
| `LibKa0s/DebugLog.lua` | C-5, C-7, C-9 |
| `LibKa0s/Core.lua` | C-9 |
| `LibKa0s/Slash.lua` | C-7 |
| `LibKa0s/PerfPanel.lua` | C-6 |
| `tests/fixture_options.lua` | C-8 |
| `tests/test_options.lua` | C-1, C-2, C-4, C-8 |
| `tests/test_versioning.lua` | C-6, C-10 |
| `CHANGELOG.md` | all |
| `README.md` | C-1, C-2 |

**Must serialize:** C-1 → C-2 → C-3 → C-4 → C-8 (all in `Options.lua`).
**Parallelizable:** the `{C-5, C-7-debuglog, C-9-core}` DebugLog/Core lane, the `{C-7-slash}` Slash
lane, and the `{C-10}` kit lane are disjoint from the Options lane and from each other — except
`CHANGELOG.md`, which every lane appends to. Treat `CHANGELOG.md` as a merge-conflict expectation,
not a serialization constraint: each lane appends under its own major's heading.

---

## Milestone M1 — Options hardening (the High findings)

**Done when:** a partial vendor refuses at `:New` with a message naming the missing file; the panel
never nil-calls a maker; a missing required descriptor field errors by name; a combat refusal is
visible with no descriptor printer; `CreateOptionsPanel` is idempotent. Suite green, lint clean.

| Task | Role | Implements | Files |
|---|---|---|---|
| M1-T1 | lua-refactorer | C-1 | `LibKa0s/Options.lua`, `LibKa0s/OptionsWidgets.lua` (comment), `tests/test_options.lua`, `CHANGELOG.md`, `README.md` |
| M1-T2 | lua-refactorer | C-2 | `LibKa0s/Options.lua`, `tests/test_options.lua`, `README.md`, `CHANGELOG.md` |
| M1-T3 | ux-cleanup | C-3 | `LibKa0s/Options.lua`, `tests/test_options.lua`, `CHANGELOG.md` |
| M1-T4 | lua-refactorer | C-4 | `LibKa0s/Options.lua`, `tests/test_options.lua`, `CHANGELOG.md` |

All four serialize on `Options.lua`. Run in the order listed: C-1 changes the tail of `lib:New`, C-2
changes its head, and doing the head first means rebasing C-1's diff for no reason.

`Options.lua`'s `MINOR` moves **once**, at the end of M1, to 2 — not once per task. Four bumps in one
release would be four changelog lines describing one shipped file.

**Note on M1-T2's blast radius:** C-2 is the only change in this set that can break a currently-working
host. Land it, then grep every consumer's Options descriptor for the seven now-required fields
**before** the re-vendor commit in M5.

---

## Milestone M2 — Cross-boundary version integrity

**Done when:** `DebugLog` resolves `MakeCloseButton` through the live Core; every secondary file
declares a shell floor; `test_versioning.lua` asserts the floors exist. Suite green.

| Task | Role | Implements | Files |
|---|---|---|---|
| M2-T1 | wow-api-migrator | C-5 | `LibKa0s/DebugLog.lua`, `tests/test_debuglog.lua`, `CHANGELOG.md` |
| M2-T2 | lua-refactorer | C-6 | `LibKa0s/OptionsWidgets.lua`, `LibKa0s/OptionsScroll.lua`, `LibKa0s/PerfPanel.lua`, `tests/test_versioning.lua`, `docs/releasing.md`, `CHANGELOG.md` |

**Parallelizable with M1** — disjoint files, except M2-T2 touches `OptionsWidgets.lua`, which M1-T1
edits (comment only). Serialize those two, or let M1-T1 land first and rebase.

**M2-T1 needs a real test, not a smoke test.** The existing versioning suite already rigs
load-order scenarios (`iso: a newer probe loading second brings its own panel with it`); reuse that
harness to load a Core at minor 2 with a distinguishable `MakeCloseButton` **after** a DebugLog at
minor 1, and assert the instance draws the new one. Without that test the fix is unfalsifiable and
the finding will regress.

---

## Milestone M3 — Secret-safe totality and the contract bugs

**Done when:** every public rendering entry point in `Slash` and `DebugLog` routes through the
secret-safe stringifier; `RestoreDefaults` passes the page filter; `RenderRows` no longer writes to
caller-owned tables; `solo` beats `pairWith`. Suite green.

| Task | Role | Implements | Files |
|---|---|---|---|
| M3-T1 | taint-hardener | C-7 (Slash half) | `LibKa0s/Slash.lua`, `tests/test_slash.lua`, `CHANGELOG.md` |
| M3-T2 | taint-hardener | C-7 (DebugLog half) | `LibKa0s/DebugLog.lua`, `tests/test_debuglog.lua`, `CHANGELOG.md` |
| M3-T3 | test-fixtures | C-8 prerequisite: widen `rowsForPage` to `(pageKey, filter)` and record the filter | `tests/fixture_options.lua` |
| M3-T4 | lua-refactorer | C-8 | `LibKa0s/Options.lua`, `LibKa0s/OptionsWidgets.lua`, `tests/test_options.lua`, `tests/test_options_widgets.lua`, `CHANGELOG.md` |

**M3-T3 blocks M3-T4** — the filter is structurally unobservable until the fixture widens, so writing
the C-8 test first is impossible without it. This is the one place where a fixture change is the
actual unit of work.

**M3-T2 serializes behind M2-T1** (both in `DebugLog.lua`). M3-T1 and M3-T4 are parallelizable with
each other and with M2.

The test the mock **must** carry, for both halves of C-7: a fake secret value whose `table.concat`
raises and whose `tostring` succeeds. A mock that does not reproduce that asymmetry cannot catch the
bug — same fidelity requirement `anti-patterns` #33 imposes on bus mocks.

---

## Milestone M4 — Cleanups and mechanization

**Done when:** the format forms agree; the probe allocates nothing per call; the kit sync is a red
suite when it drifts. Suite green, lint clean.

| Task | Role | Implements | Files |
|---|---|---|---|
| M4-T1 | lua-refactorer | C-9 (F-012, F-013) | `LibKa0s/Core.lua`, `tests/test_core.lua`, `CHANGELOG.md` |
| M4-T2 | perf | C-9 (F-014, ring buffer) — **optional, drop if the milestone runs long** | `LibKa0s/DebugLog.lua`, `tests/test_debuglog.lua`, `CHANGELOG.md` |
| M4-T3 | test-infra | C-10 | `tests/test_kit_sync.lua` (new), `tests/run.lua`, `docs/releasing.md`, `CHANGELOG.md` |

M4-T1 and M4-T3 are parallelizable. M4-T2 serializes behind M3-T2 (`DebugLog.lua`).

**M4-T2 is the one task worth cutting.** It rewrites the buffer's internal representation and moves
four public readers with it, for a bounded O(500) shift nobody has measured. If the schedule
tightens, defer it and record it in `05_FINAL_SUMMARY.md` under Known follow-ups.

---

## Milestone M5 — Release and re-vendor

**Done when:** the changelog version block matches every file's live minor, the suite proves it, and
every consumer carries a byte-identical copy.

| Task | Role | Files |
|---|---|---|
| M5-T1 | release | `CHANGELOG.md` — the `## Unreleased` version block updated to every file's new minor, `test_versioning.lua` green |
| M5-T2 | release | Follow `docs/releasing.md` end to end; tag semver (a separate axis from any file minor) |
| M5-T3 | release | Re-vendor `LibKa0s/` into **every** consumer; `diff -r` empty in each; **its own commit per consumer** |
| M5-T4 | release | Re-vendor `testkit/` → each consumer's `tests/_kit/`; `diff -r` empty |

**M5-T3 is the step that gets forgotten and the one nothing green will catch** — `anti-patterns` #45.
It is not optional and it is not part of a feature commit.

**C-2's enforcement lands here in practice.** Before M5-T3 touches a consumer, confirm that
consumer's Options descriptor supplies all seven now-required fields, or the re-vendor turns a
working addon into one that errors at enable.

---

## Checkpoints

| # | After | Human verifies |
|---|---|---|
| CP-1 | M1 | The partial-vendor rig (delete `OptionsWidgets.lua`, log in) produces the named refusal, not a nil-call. This is the finding the whole review turns on — verify it in the client, not just in the suite. |
| CP-2 | M2 | The load-order test genuinely fails when C-5's forwarder is reverted to a snapshot. A test that passes either way is not testing the invariant. |
| CP-3 | M3 | The in-combat secret test (smoke C-7 steps 2–4) produces `<secret>` and **zero** Lua errors on a live dummy. Headless mocks are necessary and not sufficient here. |
| CP-4 | M4 | Full `03_SMOKE_TESTS.md` pass, sign-off table filled. |
| CP-5 | M5-T2 | Every consumer's `diff -r` is empty **and** every consumer's own suite is green against the new copy. |

---

## Commit strategy

One commit per task, so each is revertable alone and each carries its own minor bump + changelog
line. Suggested messages, in the repo's existing style:

```
fix(options): refuse a partial vendor at :New instead of nil-calling at panel build   [C-1, F-001, F-016]
feat(options): validate the descriptor, like the other four majors do                 [C-2, F-005]
fix(options): default the printer to the chat frame, so a combat refusal is audible    [C-3, F-004]
fix(options): make CreateOptionsPanel idempotent                                       [C-4, F-010]
fix(debuglog): forward MakeCloseButton through Core instead of snapshotting it         [C-5, F-003]
feat(versioning): declare a shell floor on every paired secondary file                 [C-6, F-006]
fix(slash): route every FormatValue branch through the secret-safe stringifier         [C-7, F-008]
fix(debuglog): secret-guard the public Add entry point                                 [C-7, F-009]
test(options): widen the fixture's rowsForPage so the page filter is observable        [M3-T3]
fix(options): pass the page filter to RestoreDefaults; stop consuming caller tables    [C-8, F-002, F-007, F-015]
perf(core): reuse one probe slot instead of allocating per stringified value           [C-9, F-012, F-013]
test(kit): fail the suite when testkit/ and tests/_kit/ drift                          [C-10, F-011]
docs(changelog): the release version block for every bumped file                       [M5-T1]
chore(vendor): re-vendor LibKa0s into <Consumer>                                       [M5-T3, per consumer]
```
