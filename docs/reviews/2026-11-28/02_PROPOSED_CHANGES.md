# Proposed changes — LibKa0s v1.119.0 review (2026-11-28)

**The standard version checked against:** Ka0s WoW Addon Standard **v2.121.0** (2026-11-25). It was
fetched over the network from `raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master`.
The sibling checkout at `b83f039c` is behind origin `e23dcd5f`, so it was not used.

The branch has not shipped: v1.119.0 is unreleased and no consumer is merged. So every change below
can land in **v1.119.0 itself, before the tag**, with every Verdict file still at minor 1 (the
CHANGELOG's rule: "Every file is unreleased, so none bumps"). If the tag is cut first, each change
that touches a payload file instead bumps that file's minor and needs a re-vendor into DropWatcher
and ItemSearch.

## HLD

### Theme A: one owner per shared table, and dependents read it at call time (F-001)

Today `VerdictConstants.lua` and `VerdictClassData.lua` each build a **new** table on every run,
and seven files capture the old one at load. Two directions were considered:

1. **Keep the table, refill it.** Use `local C = lib.C or {}` / `lib.C = C`, and clear and repopulate
   it in place, the way the shell keeps `lib.__methods`. Every captured `local C = lib.C` then stays
   valid across an upgrade. This is a two-line change per owner file and nothing else moves.
   **Chosen.**
2. Read `lib.C` at call time everywhere. This touches every use site across seven files, and the
   kernel's hot path would pay a table lookup per access. **Rejected**: it costs more for the same
   guarantee.

The same refill pattern applies to `lib.ClassData`. `VerdictEvaluate.lua`'s `kernels` cache must
also be invalidated when ClassData re-runs: it can key its cache on the list's identity, or ClassData
can bump a generation number that Evaluate checks. Without one of those it keeps the old kernel. The
other owner files (`TierTokens`, `Reads`, `Collect`, `Score`, `Gear`, `Facts`, `Settings`) are read
through `lib.X` at call time by their dependents. The Verdict document should record that rule once,
so later minors keep to it.

Trade-off: refilling in place means a table that an older copy's code holds sees the new values.
That is the point of the change, and it matches how the shell's method table already behaves
(`docs/api/Verdict/...-docs.md:92-95`).

### Theme B: the instance publishes its events, and isolates the host's registration (F-002, F-003)

- Add **`v:Events()`**, an array of event names for the instance's client (derived from
  `eventsFor`), so a host registers exactly that set through
  `SafeRegisterEvents(target, v:Events(), handler, rejected)` (events-frames-taint-§1) and its
  hand-kept `EVENTS` table is retired. This is an additive member.
- In `StandUp`, wrap each `host.registerEvent` call in `pcall`, and set `__registered` only to the
  names that bound. One bad name then cannot abort the block or block a later stand-up.
- Rejected: having the library register on a frame of its own. The host contract deliberately routes
  events through the host, so its stand-down and simulator replay reach them (the DropWatcher
  `core/VerdictSetup.lua` header records why).

### Theme C: say what the defaults are, and apply them (F-004)

`Config()` fills keys the host left out from `lib.Settings.DEFAULTS`, when Settings is loaded, so
"no config judges on the defaults" becomes true. The alternative was to fix the doc to say
heirloom protection is off without a config. It was **rejected**: the shipped settings default is
on, and two answers to one question is the drift the schema rules exist to stop (architecture-§5:
one defaults source).

### Theme D: stood down means inert (F-005, F-006)

`Request` (and therefore `Facts` loads and `Judge`) answers `nil, "unavailable"` while `self.down`
is set, and starts no job. `Request` adds a waiter only once per distinct callback, or `Judge` keeps
one waiter per link. Hosts already treat `onChange("item")` as "repaint once".

### Theme E: small documentation, UX and tooling fixes (F-007 to F-012)

- F-007: give the double-registration case a fixture that counts registrations, and a
  `-- red under:` comment.
- F-008: delete the stray blank line in the Verdict document.
- F-009: the fallback becomes `LibKa0s-Core-1.0`'s prefixed printer when the host passes no
  `spec.print`, or no chat line at all. Never the bare `print`.
- F-010: widen the slider to the range the check accepts, or clamp an imported weight to the slider
  range and say so in the import line.
- F-011: in the kit runner, test `git rev-parse --git-dir` instead of `-d .git`.
- F-012: no change now. Measure first (see `03_SMOKE_TESTS.md`).

## Upstream change-set

None. Nothing here targets a vendored path. `LibKa0s/` and `testkit/` are this repository's
authored source, and this document proposes no edit under any consumer's `libs/` or `tests/_kit/`.

## LLD

### C-01 Shared tables refilled in place (F-001)

- `LibKa0s/VerdictConstants.lua:33-34`:
  ```lua
  -- before
  local C = {}
  lib.C = C
  -- after
  local C = lib.C or {}
  for k in pairs(C) do C[k] = nil end   -- a newer copy refills the one table every file holds
  lib.C = C
  ```
- `LibKa0s/VerdictClassData.lua:53-54`: the same change for `CD`. Also stamp
  `lib.__classDataGen = (lib.__classDataGen or 0) + 1`.
- `LibKa0s/VerdictEvaluate.lua:591-599` (`kernelFor`): rebuild the cache when
  `kernels.__gen ~= lib.__classDataGen`.
- Tests: a new case in `tests/test_verdict_instances.lua`. Load the payload, then re-load
  `VerdictConstants.lua` alone with `CONSTANTS_MINOR` at 2 and a changed `QUALITY.HEIRLOOM`, then
  assert that `lib.Evaluate` reads the new value. `-- red under: local C = {}`. This adds 1 case,
  so `docs/test-cases.md` and the README `[tests]` badge move in the same commit (testing-§7).
- Risk: low. The clear-then-refill happens at file load, before any instance judges.

### C-02 `v:Events()` and an isolated `StandUp` (F-002, F-003)

- `LibKa0s/Verdict.lua`: add `function methods:Events()`, which answers the sorted keys of
  `eventsFor(self.client)` as a fresh array. In `StandUp` (`:225-233`):
  ```lua
  local ok = pcall(host.registerEvent, event, handler)
  if ok then self.__registered[#self.__registered + 1] = event
  else self:Debug("VERDICT", "registerEvent refused %s", tostring(event)) end
  ```
- Docs: add a row for the method in the instance table of
  `docs/api/Verdict/version-1.1.1.1.1.1.1.1.1.1.1-docs.md`, plus the members manifest
  (`tools/gen-api-members.lua` regenerates it; never edit it by hand).
- Tests: assert that `v:Events()` matches the registered set per client (2 cases), and that a raising
  `registerEvent` still binds the rest (1 case, `-- red under:` the bare call). This adds 3 cases;
  the inventory and badge move.
- Consumer follow-up, outside this repo: each `core/VerdictSetup.lua` registers
  `NS.VerdictEngine:Events()` and drops its `EVENTS` table. This is the consumers' own change, made
  after they re-vendor.

### C-03 `Config()` fills from `Settings.DEFAULTS` (F-004)

- `LibKa0s/Verdict.lua:142-148`: after the copy, run
  `for k, v in pairs(lib.Settings and lib.Settings.DEFAULTS or {}) do if out[k] == nil then out[k] = v end end`,
  and keep `verdictMode` last. The map defaults are shared read-only tables. Neither the kernel nor
  the scorers write into them (the editors always hand `spec.set` a fresh map), so a reference is
  safe.
- `docs/api/Verdict/...-docs.md:100`: the sentence becomes true as written.
- Tests: no config, an heirloom in the slot, verdict `sidegrade`. 1 case; the inventory and badge
  move.

### C-04 Stood down is inert (F-005, F-006)

- `LibKa0s/VerdictFacts.lua:419-434`: `if self.down then return self:Facts(link), "unavailable" end`,
  placed after the cache read, so a cached answer still returns.
- `:432`: skip the append when the same function is already among `job.waiters`. The
  `VerdictGear.lua:492` closure becomes one per-instance function created once, so the check matches.
- Tests: a stood-down `Request` arms no timer (assert `W.timers() == 0` **after** asserting a
  non-stood-down control arms 1, so the negative assertion is falsifiable), and two `Judge` calls on
  a loading link fire `item` once. 2 cases; the inventory and badge move.

### C-05 Documentation, UX and tooling (F-007 to F-011)

- F-007: `tests/fixture_verdict_client.lua:283` counts calls (`W.registered[event] = (W.registered[event] or 0) + 1`),
  and `tests/test_verdict_instances.lua:123-124` asserts each count is 1. The case count does not
  change.
- F-008: delete line 81 of the Verdict document.
- F-009: `LibKa0s/VerdictSettings.lua:479` falls back to `nil`, so the import is silent without a
  printer. A library cannot pick a host's prefix.
- F-010: `LibKa0s/VerdictSettings.lua:274`, together with the import path: clamp to
  `[WEIGHT_MIN, WEIGHT_MAX]` in `importScale` and name the clamped stats in `ImportText`. Widening
  the slider was the alternative; the owner decides between the two.
- F-011: `testkit/run-automated-tests.sh:89`:
  `if ! git rev-parse --git-dir >/dev/null 2>&1; then`. This is a kit change, so `Kit.VERSION`
  rises and the kit-sync gate copies it to `tests/_kit/` in the same commit (testing-§11).

## Standards conformance (per change)

| Change | Rule that shaped it | New deviation? |
|---|---|---|
| C-01 | versioning-git, library-stack-§7: no `NEEDS_*` floor rises and no member moves, so the release stays additive | none |
| C-02 | events-frames-taint-§1 (per-event isolation, `SafeRegisterEvents`); library-stack-§7 (additive member) | none |
| C-03 | architecture-§5 (one defaults source) | none |
| C-04 | slash-commands-§7's stand-down spirit (nothing arms while down), applied to the instance | none |
| C-05 | testing-§12 (falsifiable negatives), slash-commands-§4 (no unprefixed chat), testing-§11 (kit sync) | none |

**Rejected because of the standard:** a library-side `print` fallback with a hard-coded prefix
(slash-commands-§4: the prefix is the host's brand).

**Watch-list note for the next release:** C-01 and C-02 each add a few branches to `kernelFor` and
`StandUp`. Neither is near CCN 15 today; the highest Verdict function is CCN 14
(`methods.ScoreFor`), which these changes do not touch.
