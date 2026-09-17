# `testkit` — version 23

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `loader.lua`, `mock_base.lua`, `mock_record.lua`, `mock_ids.lua`, `vendor_sync.lua`, `test_eol.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **23** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.43.0 |
| Status | **Current** |
| Supersedes | [version 22](version-22-docs.md) — the recording surveys |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `23` |

Everything revision 22 describes is unchanged here except what follows. No file is added. Four
change: `framework.lua` (the resource guard and the runner's gates), `mock_base.lua` (the build
lookup that leaked), `run-automated-tests.sh` (every suite bounded) and `README.md` (a section). No
member a suite calls is added, removed, renamed or resignatured, and **a consumer adopts all of it by
re-vendoring, with no change to its own runner**.

## Why

A headless run in this collection took its whole machine down twice in one day, and neither failure
said anything until the kernel's OOM killer did:

- **A runner that started itself.** A scratch probe left in one addon's `tests/` and registered in
  its runner made the `lua tests/run.lua --list` child that addon's own list-mode suite starts start
  another, forever — a chain of ~700 MB processes growing ~145 MB/s until the VM, and the editor
  session driving it, were killed. A per-process `ulimit -v` would not have stopped it: every link
  in the chain fitted under any sensible cap.
- **A harness that kept everything it built.** One consumer's suite peaked at 1.75 GB. It builds a
  fresh addon instance per case (`T.load()`), which is the right shape, and every one of the 1,678
  instances was still reachable at the end of the run — 685 MB of live heap no case would ever use
  again. The retainer was in this kit (see *The leak* below), so every consumer had it, in proportion
  to how many instances it builds. After the fix the same suite peaks at **41 MB** and its live heap
  is flat at 6 MB from the first instance to the last.

## The process guard

`framework.lua` re-launches the process it is loaded into, once, under four bounds. It happens on
**load** — the first thing every runner does — so it covers `tests/run.lua`, `tests/perf.lua` and any
script that loads the kit, before any addon source is loaded.

| Bound | Mechanism | Variable | Default |
|---|---|---|---|
| Re-launch depth | Each guarded process exports `KA0S_KIT_DEPTH` one higher than it found it; past the limit it refuses with exit **3** and a message naming the chain | `KA0S_KIT_MAX_DEPTH` | 4 |
| Process-tree memory | The outermost process (depth 1) runs in `systemd-run --user --scope` with `MemoryMax`, `MemorySwapMax=0` and `TasksMax`; skipped where systemd is absent | `KA0S_KIT_TREE_MB`, `KA0S_KIT_TASKS` | half of RAM, 256 |
| Process memory | `ulimit -v` — an allocation past it is Lua's catchable "not enough memory", so the case fails by name | `KA0S_KIT_PROC_MB` | 2048 |
| Wall clock | `timeout --foreground -k 10` — exit **124** | `KA0S_KIT_TIMEOUT_S` | 900 |

- **Nothing downstream has to cooperate.** A suite that starts the runner through a bare `io.popen`
  still starts a process that loads this file and reads the depth its parent exported.
- **The re-launched process knows it is the guarded one by a marker argument** (`--kit-guarded`,
  removed from `arg` before the runner sees it), not by an environment variable, because a variable
  would be inherited by the children it starts and they would skip the guard.
- **Idempotent within a process.** A suite that `dofile`s the kit again gets the kit, not a second run.
- **The exit code is the run's exit code**, normalized across Lua 5.1's wait status and 5.2's triple.
  124 and 137 are explained on stderr, so a stopped run never reads as a test failure.
- `KA0S_KIT_GUARD=off` disables the guard — for a debugger, never for a gate. `KA0S_KIT_CGROUP=off`
  drops only the scope. A limit of `0` drops that limit.

## The runner's gates

Resolved in `Kit.run` from `opts`, then from the environment, which wins so an operator can raise one
for a single run without editing a runner.

| Gate | What fails | `opts` field | Variable | Default |
|---|---|---|---|---|
| Heap budget | After any case, a **live** heap over the budget: a `FAIL  heap budget` line naming the case, and the run stops | `heapBudgetMB` | `KA0S_KIT_HEAP_MB` | 1024 |
| Leak gate | At a suite boundary, a live heap more than the budget above where the run started: one `FAIL  leak gate` line naming the suite | `leakBudgetMB` | `KA0S_KIT_LEAK_MB` | 256 |
| CPU ceiling | A case, or a suite file's load, running past the ceiling fails with `kit limit: went past its N s CPU ceiling` | `caseSeconds` | `KA0S_KIT_CASE_S` | 120 |
| Host path | A suite whose source names a WSL drive mount, a Linux or macOS home, or a Windows profile raises before it loads | — | — | — |
| Memory-aware `--jobs` | Workers capped at three quarters of `MemAvailable` over the per-worker figure, never below one | — | `KA0S_KIT_SHARD_MB` | 512 |

- **Live, not counted.** Both heap gates read `collectgarbage("count")` first and pay for a full
  collection only when that reading is already over, so garbage waiting to be swept never fails a
  gate and a run inside its budgets never pays for one.
- **The CPU ceiling cannot be outrun.** Once past the deadline its hook fires on every instruction, so
  a body that swallows the error in its own `pcall` raises again on its first instruction outside it.
  A nested bounded call restores the hook it replaced.
- The heap-gate and leak-gate failures are counted as failures, like the parallel runner's "shard
  produced no result line", so the totals line can read one higher than the case count.

## The leak

`mock_base.lua` found a target's build through a process-wide table keyed by the target's `__events`
table and weak on its keys. Its value, the build, reaches its key again —
`build → events → AceEvent → embeds → target → __events` — and **Lua 5.1 has no ephemerons**: a
weak-keyed entry whose value references its own key is never collected. So no build was ever
collected, and neither was any table ever embedded in one. The build now rides on the `__events`
table's metatable (`__kitBuild`), where it lives and dies with the table. `__events` had no metatable,
and a metatable is invisible to `next` and `pairs`, so everything a suite reads off `__events` is
unchanged. `tests/test_mock_base.lua`'s *a dropped mock build takes every target embedded in it with
it* pins it.

## `run-automated-tests.sh`

Every suite — `luacheck`, the headless run and its `--list`, `tests/perf.lua`, `lizard` — runs through
a `bounded` function applying the same `KA0S_KIT_PROC_MB` and `KA0S_KIT_TIMEOUT_S` bounds. It is the
only bound `luacheck` and `lizard` have, since neither loads the kit.

## Adopting

Re-vendor. A suite that legitimately needs more than a default declares it in its runner's `Kit.run`
options — which the Ka0s WoW Addon Standard treats as a documented deviation, not a setting.
`tests/test_kit_limits.lua` here pins the guard (across real child processes, through
`tests/fixture_guard.lua`) and every gate.
