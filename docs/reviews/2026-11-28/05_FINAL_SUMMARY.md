# Final summary — LibKa0s v1.119.0 review-and-fix cycle (written assuming `03_SMOKE_TESTS.md` passed)

## Headline

The new verdict engine, `LibKa0s-Verdict-1.0`, which Ka0s Drop Watcher and Ka0s Item Search share,
now stays consistent when two addons carry different copies of it. It lets each addon ask which
events it needs instead of copying a list. It stops cleanly when an addon is turned off, and it
applies its own shipped defaults when an addon gives it no settings. The fixes also correct a broken
table in its reference document, a chat line that could lose its addon tag, a slider narrower than
the values it receives, and a kit runner that refused git worktrees.

## Counts

Critical fixed: 0, High fixed: 0, Medium fixed: 2, Low fixed: 9.

**Deferred:** F-012 (per-judgment allocations). It is unmeasured, and it waits for a consumer
capture that brackets `evaluate`.

## Changes by theme

### A. One owner per shared table

- **What changed:** `lib.C` and `lib.ClassData` are refilled in place, and the kernel cache follows
  ClassData.
- **Why it mattered:** a later release bumping one constants file could otherwise leave the
  verdict reading two constant sets, chosen by addon load order.
- **Findings and changes:** F-001; C-01.
- **Files:** `LibKa0s/VerdictConstants.lua`, `LibKa0s/VerdictClassData.lua`,
  `LibKa0s/VerdictEvaluate.lua`, `tests/test_verdict_instances.lua`.

### B. The event surface

- **What changed:** `v:Events()` answers the instance's events, and `StandUp` isolates each host
  registration.
- **Why it mattered:** both consumers kept a hand copy of the event list, and one bad registration
  could half-wire an instance.
- **Findings and changes:** F-002, F-003; C-02.
- **Files:** `LibKa0s/Verdict.lua`, the Verdict API document and manifest,
  `tests/test_verdict_instances.lua`.

### C. Defaults

- **What changed:** `Config()` fills missing keys from `Settings.DEFAULTS`.
- **Why it mattered:** without a config, heirloom protection was off while the shipped default is
  on.
- **Findings and changes:** F-004; C-03.
- **Files:** `LibKa0s/Verdict.lua`, `tests/test_verdict_gear.lua`.

### D. Stood down means inert

- **What changed:** a stood-down instance starts no item load, and one load keeps one waiter per
  callback.
- **Findings and changes:** F-005, F-006; C-04.
- **Files:** `LibKa0s/VerdictFacts.lua`, `LibKa0s/VerdictGear.lua`, `tests/test_verdict_facts.lua`.

### E. Documentation, UX and kit

- **What changed:** a falsifiable double-registration case, the Verdict document's table repaired,
  no unprefixed import line, the weight range reconciled, and the runner accepts worktrees.
- **Findings and changes:** F-007 to F-011; C-05.
- **Files:** `tests/fixture_verdict_client.lua`, `tests/test_verdict_instances.lua`,
  `docs/api/Verdict/version-1.1.1.1.1.1.1.1.1.1.1-docs.md`, `LibKa0s/VerdictSettings.lua`,
  `testkit/run-automated-tests.sh`, `testkit/framework.lua`, `tests/_kit/`.

## API and behavior changes

- New instance member: `v:Events()`.
- `Config()` now fills `heirloomProtect` (and the other five keys) from `Settings.DEFAULTS`.
- `Request` answers `nil, "unavailable"` for an uncached link while stood down.
- The Pawn import's line is silent without `spec.print`. It no longer falls back to the bare
  `print`.
- `Kit.VERSION` rises by one (F-011).

## Migration notes

None. There is no stored data in the library. The consumers' re-vendor and `Events()` adoption are
their own commits.

## Dependency changes

None.

## Test and complexity movement

Before the changes: 5547 cases (5544 passed, 3 skipped) on both profiles. After: about 9 more,
recorded from `--list`. `docs/test-cases.md` and the README `[tests]` badge move in the same commit.
No complexity watch-list entry is expected to move. The highest Verdict function stays at CCN 14.

## Known follow-ups

- F-012: measure with a consumer `/dw perf` capture before changing anything.
- Consumers: adopt `v:Events()` after re-vendoring.

## Verification evidence

`03_SMOKE_TESTS.md` with its sign-off table filled in, and the commit range `IS-R1` to `IS-R10` on
`feat/2026-11-27-itemsearch-split`.

## Suggested PR description

```
LibKa0s v1.119.0 review fixes (LibKa0s-Verdict-1.0)

- Refill lib.C / lib.ClassData in place; the kernel cache follows ClassData (F-001)
- v:Events() for host registration; StandUp isolates each registration (F-002, F-003)
- Config() fills from Settings.DEFAULTS (F-004)
- A stood-down instance starts no load; one waiter per callback (F-005, F-006)
- Falsifiable registration case, doc table, import prefix and weight range,
  kit runner in a worktree (F-007 to F-011)

Deferred: F-012 (unmeasured allocations).
Gate: lua tests/run.lua and KA0S_KIT_CLIENT=forever lua tests/run.lua 0 failed;
luacheck 0/0; pytest tools/seeds green.
```
