# LibKa0s Perf Extraction — Implementation Plan (rollout steps 1 & 2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract AbsorbTracker's performance harness into `LibKa0s-Perf-1.0` — a LibStub
micro-library with its own repo, tests and green gate — and make AbsorbTracker its first consumer,
with measurements unchanged.

**Architecture:** `LibStub("LibKa0s-Perf-1.0"):New(descriptor)` returns a per-host instance that owns
its own sampler frame, bucket table, FPS arms and step panel. Nothing is shared between hosts except
the code and the stateless JSON encoder — a shared frame would reproduce the exact Addon-Profiler
attribution pathology this harness exists to defeat. The host supplies `suspend`/`resume` and a
handful of optional sinks; the lib supplies the protocol, the record schema, the report and the
panel. The lib registers **no** slash command: it exposes `OnCommand(args)` returning lines, and each
host wires one `perf` entry into its own `COMMANDS` table.

**Tech Stack:** Lua 5.1 (WoW client dialect), LibStub, `luacheck`, a headless `lua tests/run.lua`
harness in each repo. No Ace3 anywhere in the lib.

**Spec:** `LibKa0s/docs/superpowers/specs/2026-07-29-libka0s-perf-extraction-design.md`

**Scope:** rollout steps 1 and 2 only. Step 3 (WowAddonStandards v2.12.0), step 4 (`NEW_ADDON.md`),
step 5 (the other five addons) and step 6 (CurseForge) are deliberately **out of this plan** — the
spec requires them to follow a working extraction, not precede it.

## Global Constraints

- **Lua 5.1 only.** No `goto`, no integer division, no `#!`-isms. `luac -p <file>` syntax-checks one
  file.
- **The lib depends on LibStub and nothing else.** No AceGUI, AceEvent, AceTimer, AceConsole,
  CallbackHandler. The sampler is a raw `OnUpdate` frame, the panel is raw `CreateFrame`, combat is
  `UnitAffectingCombat`. Reaching for an Ace lib here halves the addressable audience — treat it as a
  hard rule, not a preference.
- **No shared frames.** Every frame the lib creates is created inside `:New()`, owned by that
  instance. There is no lib-level singleton frame, ever.
- **The hot-path idiom is frozen:** `local t0 = Perf.on and debugprofilestop()` … `if t0 then
  Perf.Note("key", debugprofilestop() - t0) end`. `on` stays a plain boolean *field* on the instance
  and `Note` stays a plain dot-callable function. No colon methods, no metatable `__index` lookup on
  the hot path, no allocation when capture is off.
- **Instance functions are closures, not metatable methods.** `perf.Note(...)` — dot, never
  `perf:Note(...)`. This is what keeps the call sites identical to today's and keeps per-host state
  private.
- **CRLF.** Both repos pin `* text=auto eol=crlf` in `.gitattributes`. Write files normally; git
  handles it. Do not add a BOM.
- **Green gate in each repo before every commit:** `lua tests/run.lua` (all pass) and `luacheck .`
  (0 warnings / 0 errors).
- **Record schema is 2.** Clean break — there is no v1→v2 migration. Per the user's decision on
  LibKa0s issue #4, the perf ring has not shipped, so a stored ring with any other schema is
  discarded on write rather than converted.
- **Never bump the addon version, and never `git add`/`commit`/`push` without the user's explicit
  go-ahead** (repo rule, `docs/agent-context.md`). Commit steps are written out below; ask before
  running them.
- **Descriptor contract is additive-only** within `-1.0`. Once a field exists, its meaning is frozen.
- Two repo roots are in play. `AT/` = `/mnt/d/Profile/Users/Tushar/Documents/GIT/AbsorbTracker`,
  `LK/` = `/mnt/d/Profile/Users/Tushar/Documents/GIT/LibKa0s`. Paths below are relative to whichever
  root the task names.

## Deviations from the spec, decided here

Three descriptor fields the spec's table does not list, all optional, all needed by the panel and the
help text. Flagged rather than smuggled in:

| Field | Why |
|---|---|
| `slash` | The panel's third column prints the typed form (`/at perf measure a`). Without the host's slash token the column cannot be rendered. Defaults to `"/" .. name:lower()`. |
| `title` | Panel title. Defaults to `name .. " — Perf Run"`; AbsorbTracker passes `"Absorb Tracker"` so the title reads as it does today. |
| `showLog` | `start`, `report` and `dump` open the debug console today. A log *sink* cannot do that (it would pop the console open on every mid-combat lifecycle line). Optional, default no-op. |

Also: `decorate` is called as `decorate(frame, api)` rather than `decorate(frame)`. The extra
argument is additive and lets a host position its close button against the lib's own metrics.

---

## File Structure

### LibKa0s (`LK/`) — new repo, currently holds only `.gitattributes`, `.gitignore`, `docs/`

| Path | Responsibility |
|---|---|
| `LibKa0s/LibKa0s.xml` | Aggregate; lists the module files in load order. **This folder is the vendorable payload** — it is what gets copied to `<Addon>/libs/LibKa0s/`. Nothing else in the repo ships. |
| `LibKa0s/Perf.lua` | `LibStub:NewLibrary("LibKa0s-Perf-1.0", MINOR)`. JSON encoder, descriptor validation, `:New()`, buckets, record assembly, persistence, report, sampler, windows, suspend/resume, `OnCommand`. |
| `LibKa0s/PerfPanel.lua` | Attaches the step panel to the same major. Instance-owned frame, dumb renderer over `Progress()`. |
| `tests/run.lua` | Headless harness + `--list` generator. Same framework as AbsorbTracker's. |
| `tests/loader.lua` | Loads a lib file with WoW globals resolved to the mock set. |
| `tests/wow_mock.lua` | Frame stub, settable `debugprofilestop`, context lookups, stopwatch stubs, a **real** LibStub. |
| `tests/fixture.lua` | `Fixture.new(overrides)` — a `TestHost` instance plus recorded log/chat/suspend calls. |
| `tests/test_perf_core.lua` | Buckets, JSON, record assembly, persistence, report. |
| `tests/test_perf_run.lua` | Sampler, combat-gated windows, suspend/resume, announcements, context. |
| `tests/test_perf_panel.lua` | `Progress()` state machine, panel rendering, cancel, show/hide. |
| `tests/test_perf_command.lua` | `OnCommand` dispatch, usage, status. |
| `.luacheckrc` | `std = "lua51"`, WoW globals, `_G` writable. |
| `README.md` | What it is, the descriptor contract, an integration example, vendoring instructions. |
| `CHANGELOG.md` | Repo semver ↔ per-module LibStub minor. |
| `LICENSE` | MIT, same text as AbsorbTracker's. |
| `docs/record-schema.md` | Schema v2, field by field. |

### AbsorbTracker (`AT/`)

| Path | Change |
|---|---|
| `libs/LibKa0s/` | **Create** — verbatim copy of `LK/LibKa0s/`. |
| `core/Perf.lua` | **Delete** (706 lines). |
| `core/PerfPanel.lua` | **Delete** (242 lines). |
| `core/PerfSetup.lua` | **Create** — the descriptor, and `NS.Perf = LibStub("LibKa0s-Perf-1.0"):New(descriptor)`. ~90 lines. |
| `AbsorbTracker.toc` | Lib block gains `libs\LibKa0s\LibKa0s.xml`; core block swaps two files for one. |
| `core/Bus.lua` | Drop `MSG.PERF` and its doc block — the panel owns its own refresh now, leaving no subscriber. |
| `settings/Slash.lua` | `runPerf` becomes a thin adapter over `NS.Perf.OnCommand`; `PERF_SUBS`, `PERF_USAGE`, `emitPerfLines` are deleted. |
| `.luacheckrc` | Comments repointed from `core/Perf.lua` to `core/PerfSetup.lua`; `_G` unchanged. |
| `tests/wow_mock.lua` | LibStub mock gains a real `NewLibrary`, so the vendored lib can register. |
| `tests/run.lua` | Load list: vendored lib first, `core/PerfSetup.lua` in place of the two deleted files. |
| `tests/test_perf.lua` | **Rewrite** as the integration suite (~18 tests, down from ~130). |
| `tests/perf.lua` | Load list + `NS.Perf.EncodeJSON`/`SCHEMA` sourcing updated. |
| `docs/*` | ARCHITECTURE, performance, file-index, module-map, data-flow, perf-runs/README, complexity, test-cases, README badge. |

---

## Task 1: LibKa0s repo scaffolding and a green gate

Nothing to extract yet — this task exists so every later task has a harness to be green against.

**Files:**
- Create: `LK/LICENSE`, `LK/README.md`, `LK/CHANGELOG.md`, `LK/.luacheckrc`
- Create: `LK/tests/run.lua`, `LK/tests/loader.lua`, `LK/tests/wow_mock.lua`
- Create: `LK/LibKa0s/LibKa0s.xml`, `LK/LibKa0s/Perf.lua` (stub — registration only)
- Create: `LK/tests/test_perf_core.lua` (one test)

**Interfaces:**
- Produces: `LibStub("LibKa0s-Perf-1.0")` resolving to a table with `MAJOR`, `MINOR`, `SCHEMA`,
  `DEFAULT_RING`. `_G.LK_TEST = { test, assertEqual, assertTrue, assertFalse, mocks, lib }`.

- [ ] **Step 1: Copy the licence and pin the lint config**

`LK/LICENSE` — copy `AT/LICENSE` verbatim (MIT, same copyright holder).

`LK/.luacheckrc`:

```lua
std = "lua51"
max_line_length = false
codes = true
exclude_files = { "tests/", "docs/" }
read_globals = {
  "LibStub", "CreateFrame", "UIParent", "UISpecialFrames", "DEFAULT_CHAT_FRAME",
  "time", "date", "debugprofilestop", "UnitAffectingCombat", "InCombatLockdown",
  "C_AddOns", "GetAddOnMetadata",
  -- Blizzard stopwatch, driven by the measurement windows. Called as Lua functions rather than
  -- via "/sw play": RunMacroText is protected and would fail in combat.
  "Stopwatch_Clear", "Stopwatch_Play", "Stopwatch_Pause", "StopwatchFrame",
  -- Capture context, so a saved record says who/where/what.
  "UnitName", "UnitLevel", "UnitClass", "GetRealmName", "GetZoneText", "GetSubZoneText",
  "GetSpecialization", "GetSpecializationInfo", "IsInInstance", "IsInRaid", "IsInGroup",
  "GetNumGroupMembers",
}
-- The host's SavedVariables global is named at runtime by the descriptor, so persistence writes
-- through _G[name]. That is the one sanctioned _G mutation in this library.
globals = { "_G" }
```

- [ ] **Step 2: Write the mock set**

`LK/tests/wow_mock.lua` — port `AT/tests/wow_mock.lua` lines 1–66 (`deepcopy`, `stubFrame`) and
lines 68–131 verbatim **minus** everything the lib never touches (absorbs, health, class colour,
Settings, AceDB/AceGUI/AceConsole/AceTimer). Then add the two pieces the AbsorbTracker mock does not
have:

```lua
  -- Blizzard's stopwatch. Recorded rather than no-opped: which of reset/play/pause fired, and in
  -- what order, is the only observable difference between an armed window and a recording one.
  M.__stopwatch = {}
  local function sw(action) return function() M.__stopwatch[#M.__stopwatch + 1] = action end end
  M.Stopwatch_Clear, M.Stopwatch_Play, M.Stopwatch_Pause = sw("clear"), sw("play"), sw("pause")
  M.StopwatchFrame = stubFrame()

  -- Combat, settable. The sampler polls this rather than listening for PLAYER_REGEN_* (Suspend
  -- unregisters the host's event frames, so window B would never see the event fire).
  M.__inCombat = false
  M.UnitAffectingCombat = function() return M.__inCombat end

  -- Addon metadata, for the record's `interface` field.
  M.C_AddOns = { GetAddOnMetadata = function() return "120007" end }

  -- A REAL LibStub, not a lookup table: the library under test registers into it. Minor tracking
  -- is the actual LibStub contract — a lower minor must not overwrite a higher one.
  local registry, minors = {}, {}
  M.LibStub = setmetatable({
    GetLibrary = function(_, major, silent)
      if not registry[major] and not silent then error("Cannot find a library instance of " .. major) end
      return registry[major], minors[major]
    end,
    NewLibrary = function(_, major, minor)
      minor = tonumber(minor)
      if minors[major] and minors[major] >= minor then return nil end
      registry[major] = registry[major] or {}
      minors[major] = minor
      return registry[major], minors[major]
    end,
  }, { __call = function(self, major, silent) return self:GetLibrary(major, silent) end })
```

`M.UnitAffectingCombat` replaces AbsorbTracker's hard-coded `false`. Keep `M.__profileMs` /
`M.debugprofilestop`, `M.time`, `M.date`, `M.CreateFrame`, `M.UIParent`, `M.UISpecialFrames`,
`M.DEFAULT_CHAT_FRAME`, and the whole `M.__context` block with its accessors, verbatim.

- [ ] **Step 3: Write the loader**

`LK/tests/loader.lua` — copy `AT/tests/loader.lua` verbatim, with two changes: drop
`Loader.addonName` and call the chunk with no arguments (`return chunk()`), because a library file
is not an addon file and receives no `(addonName, NS)` pair.

- [ ] **Step 4: Write the runner**

`LK/tests/run.lua` — copy `AT/tests/run.lua`'s framework (lines 1–21 and 100–153) and replace the
addon bootstrap with:

```lua
local Loader     = dofile("tests/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local mocks = buildMocks()
Loader.loadAll({ "LibKa0s/Perf.lua", "LibKa0s/PerfPanel.lua" }, mocks)

_G.LK_TEST = {
  mocks = mocks, lib = mocks.LibStub("LibKa0s-Perf-1.0"), test = test,
  assertEqual = assertEqual, assertTrue = assertTrue, assertFalse = assertFalse,
}

local SUITES = { "test_perf_core", "test_perf_run", "test_perf_panel", "test_perf_command" }
```

`Loader.loadAll(paths, mocks)` loses the `NS` parameter. In Task 1 only `Perf.lua` exists — list just
that file and add `PerfPanel.lua` in Task 5. Keep `--list` byte-identical in behaviour to
AbsorbTracker's, including the `## Totals` table.

- [ ] **Step 5: Write the registration stub**

`LK/LibKa0s/Perf.lua`:

```lua
-- LibKa0s-Perf-1.0 — a repeatable A/B performance capture for World of Warcraft addons.
--
-- The value here is not the bucket counter. It is the PROTOCOL: two combat-gated measurement
-- windows over the same fight, differing only in whether the host addon is inert, with load order
-- and shared-frame ownership held fixed. WoW's own Addon Profiler cannot answer "is this cost even
-- ours?", because it bills a shared library's dispatch frame to whichever addon created it — so
-- enabling and disabling addons moves the blame around. Suspending changes only whether the host's
-- code runs.
--
-- Every instance owns its own frames. A lib-level shared frame would reproduce that exact
-- attribution pathology: the measuring instrument corrupting the attribution it exists to fix.
--
-- Depends on LibStub and nothing else, deliberately — no Ace3, so the lib is adoptable by addons
-- that are not on the Ace substrate.

local MAJOR, MINOR = "LibKa0s-Perf-1.0", 1
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

lib.MAJOR, lib.MINOR = MAJOR, MINOR

-- Record schema emitted by BuildRecord. See docs/record-schema.md.
lib.SCHEMA = 2

-- Default depth of the SavedVariables capture ring. Small on purpose: these are diagnostic
-- snapshots read by hand, not telemetry.
lib.DEFAULT_RING = 10
```

`LK/LibKa0s/LibKa0s.xml`:

```xml
<Ui xmlns="http://www.blizzard.com/wow/ui/">
	<Script file="Perf.lua"/>
</Ui>
```

(`PerfPanel.lua` is added to the XML in Task 5.)

- [ ] **Step 6: Write the failing test**

`LK/tests/test_perf_core.lua`:

```lua
-- tests/test_perf_core.lua — buckets, JSON encoding, record assembly, persistence, reporting.

local T = _G.LK_TEST
local lib = T.lib
local test, assertEqual = T.test, T.assertEqual

test("lib: registers under its major with a schema and a default ring", function()
  assertEqual(lib.MAJOR, "LibKa0s-Perf-1.0", "major")
  assertEqual(lib.SCHEMA, 2, "schema")
  assertEqual(lib.DEFAULT_RING, 10, "default ring")
end)
```

- [ ] **Step 7: Run the gate**

```bash
cd /mnt/d/Profile/Users/Tushar/Documents/GIT/LibKa0s && lua tests/run.lua && luacheck .
```

Expected: `1 passed, 0 failed, 1 total`, and luacheck `0 warnings / 0 errors`.

- [ ] **Step 8: Write the README and CHANGELOG skeletons**

`LK/README.md` — for now: what LibKa0s is, that it is vendored not depended on, the repo layout
block from the spec, and the green-gate commands. The descriptor contract section is written in
Task 7, once the contract is real.

`LK/CHANGELOG.md`:

```markdown
# Changelog

Two version numbers, and they are not the same thing. The repo carries a semver tag for humans.
Each module separately carries a LibStub **MINOR** integer that increments on every released change
to that module — that is what LibStub compares when it picks a winner between vendored copies.

## Unreleased

- `LibKa0s-Perf-1.0` minor 1 — initial extraction from AbsorbTracker (issue
  [#17](https://github.com/tusharsaxena/AbsorbTracker/issues/17)).
```

- [ ] **Step 9: Commit** *(ask first — repo rule)*

```bash
git add -A
git commit -m "chore: scaffold the LibKa0s repo and its green gate"
```

---

## Task 2: The JSON encoder, the descriptor, and `:New()`

**Files:**
- Modify: `LK/LibKa0s/Perf.lua`
- Create: `LK/tests/fixture.lua`
- Modify: `LK/tests/test_perf_core.lua`

**Interfaces:**
- Consumes: `lib.SCHEMA`, `lib.DEFAULT_RING` from Task 1.
- Produces:
  - `lib.EncodeJSON(value) -> string` (static, stateless)
  - `lib:New(descriptor) -> perf` where `perf` carries the fields and closures listed below
  - `perf.on`, `perf.suspended`, `perf.run` (booleans), `perf.armed`, `perf.recording` (arm name or
    nil), `perf.label`, `perf.context`
  - `perf.BUCKET_ORDER` (array of keys, descriptor order), `perf.BUCKET_WITHIN` (`[key] = parentKey`)
  - `perf.Note(key, ms)`, `perf.Reset()`, `perf.Progress() -> table`, `perf.MarkReviewed(key) -> bool`
  - `perf.Log(fmt, ...)`, `perf.Announce(fmt, ...)`
  - test seams `perf.__buckets()`, `perf.__fpsArms()`, `perf.__completed()`, `perf.__reviewed()`
  - `Fixture.new(overrides) -> perf, rec` where `rec = { log = {}, chat = {}, calls = {} }`

- [ ] **Step 1: Write the failing tests**

Append to `LK/tests/test_perf_core.lua`:

```lua
local Fixture = dofile("tests/fixture.lua")

test("lib: New requires a name, an sv global and a suspend/resume pair", function()
  local ok = pcall(function() lib:New({ sv = "X", suspend = function() end, resume = function() end }) end)
  T.assertFalse(ok, "missing name must error")
  ok = pcall(function() lib:New({ name = "X", suspend = function() end, resume = function() end }) end)
  T.assertFalse(ok, "missing sv must error")
  ok = pcall(function() lib:New({ name = "X", sv = "XDB", resume = function() end }) end)
  T.assertFalse(ok, "missing suspend must error")
end)

test("lib: two instances share no state", function()
  local a = Fixture.new({ name = "HostA", sv = "HostAPerfDB" })
  local b = Fixture.new({ name = "HostB", sv = "HostBPerfDB" })
  a.Note("outer", 5)
  assertEqual(a.__buckets().outer.calls, 1, "A recorded")
  assertEqual(b.__buckets().outer, nil, "B untouched")
end)

test("lib: bucket order and nesting come from the descriptor", function()
  local p = Fixture.new()
  assertEqual(p.BUCKET_ORDER[1], "outer", "first bucket")
  assertEqual(p.BUCKET_ORDER[2], "inner", "second bucket")
  assertEqual(p.BUCKET_WITHIN.inner, "outer", "declared nesting")
  assertEqual(p.BUCKET_WITHIN.outer, nil, "top-level bucket has no parent")
end)

test("lib: the capture gate starts off", function()
  local p = Fixture.new()
  T.assertFalse(p.on, "on")
  T.assertFalse(p.run, "run")
  T.assertFalse(p.suspended, "suspended")
end)
```

Then move these tests across from `AT/tests/test_perf.lua` unchanged in intent, retargeted at a
`Fixture.new()` instance instead of `NS.Perf` (names kept so the two suites stay greppable against
each other — change the `perf:` prefix to `lib:`):

- `Note accumulates calls, total and max` (AT:46)
- `Note tracks unrelated buckets independently` (AT:57)
- `Reset clears every bucket and both fps arms` (AT:65)
- all eight `EncodeJSON …` tests (AT:77–115) — these call `lib.EncodeJSON` statically, no instance

- [ ] **Step 2: Write the fixture**

`LK/tests/fixture.lua`:

```lua
-- A throwaway host for the library under test. Each Fixture.new() is a fresh instance with its own
-- state, which is the point: the lib's central promise is that hosts share nothing.

local T = _G.LK_TEST
local Fixture = {}

-- `rec` captures everything the instance sends outward, so a test can assert on the host contract
-- (what got logged, what got printed, whether suspend actually fired) rather than on internals.
function Fixture.new(overrides)
  local rec = { log = {}, chat = {}, calls = {}, decorated = nil }
  local d = {
    name    = "TestHost",
    title   = "Test Host",
    slash   = "/th",
    version = "1.2.3",
    sv      = "TestHostPerfDB",
    buckets = {
      { key = "outer" },
      { key = "inner", within = "outer" },
    },
    suspend = function() rec.calls[#rec.calls + 1] = "suspend" end,
    resume  = function() rec.calls[#rec.calls + 1] = "resume"  end,
    log     = function(line) rec.log[#rec.log + 1] = line end,
    print   = function(line) rec.chat[#rec.chat + 1] = line end,
  }
  for k, v in pairs(overrides or {}) do d[k] = v end
  _G[d.sv] = nil                       -- every fixture starts with an empty ring
  T.mocks.__profileMs = 0
  T.mocks.__inCombat  = false
  T.mocks.__stopwatch = {}
  return T.lib:New(d), rec
end

return Fixture
```

- [ ] **Step 3: Run the tests to verify they fail**

```bash
cd /mnt/d/Profile/Users/Tushar/Documents/GIT/LibKa0s && lua tests/run.lua
```

Expected: FAIL — `attempt to call field 'New' (a nil value)` / `EncodeJSON` nil.

- [ ] **Step 4: Move the JSON encoder**

Append to `LK/LibKa0s/Perf.lua` the block from `AT/core/Perf.lua:208–265` — the comment header,
`encodeNumber`, `ESCAPES`, `encodeString`, `sortedKeys`, and the encoder itself — renamed from
`P.EncodeJSON` to `lib.EncodeJSON`, with its recursive self-calls updated to match. It is static and
stateless: hosts share it and that is fine, since it holds nothing.

- [ ] **Step 5: Write the descriptor validation and the instance constructor**

```lua
-- ── Strings ────────────────────────────────────────────────────────────────────────────────
--
-- Every user-visible string routes through here so a host can override any of them via the
-- optional `L` table, keyed identically. Hosts on the Ka0s standard pass their NS.L; hosts that
-- are not localised pass nothing and get these.

lib.STRINGS = {
  PANEL_TITLE_SUFFIX = " \226\128\148 Perf Run",
  STEP_START    = "Start perf run",
  STEP_MEASURE_A = "Measure A (with the addon)",
  STEP_MEASURE_B = "Measure B (without the addon)",
  STEP_FINISH   = "Finish perf run",
  STEP_REPORT   = "Report",
  STEP_DUMP     = "JSON Dump",
  STEP_CANCEL   = "Cancel perf run",
}

-- ── Instances ──────────────────────────────────────────────────────────────────────────────

local function required(d, key, wanted)
  if type(d[key]) ~= wanted then
    error(("LibKa0s-Perf: descriptor.%s must be a %s"):format(key, wanted), 3)
  end
end

--- Create a perf instance for one host addon. Every instance owns its own sampler frame, bucket
--- table, FPS arms and panel — see the header on why that is non-negotiable.
function lib:New(descriptor)
  local d = descriptor or {}
  required(d, "name", "string")
  required(d, "sv", "string")
  required(d, "suspend", "function")
  required(d, "resume", "function")

  local P = {}

  -- Optional host sinks, resolved once so the hot-ish paths do not re-branch on presence.
  local noop     = function() end
  local hostLog  = type(d.log)     == "function" and d.log     or function(line) print(line) end
  local hostPrint= type(d.print)   == "function" and d.print   or function(line) print(line) end
  local showLog  = type(d.showLog) == "function" and d.showLog or noop
  local onChange = type(d.onChange)== "function" and d.onChange or noop
  local L        = d.L or {}
  local function tr(key) return L[key] or lib.STRINGS[key] or key end

  -- Mirrored onto the instance as a convenience: call sites that hold only `NS.Perf` should not
  -- have to reach back through LibStub for the schema number or the encoder.
  P.SCHEMA     = lib.SCHEMA
  P.EncodeJSON = lib.EncodeJSON

  P.descriptor = d
  P.name    = d.name
  P.slash   = d.slash or ("/" .. d.name:lower())
  P.title   = d.title or d.name
  P.ringMax = tonumber(d.ring) or lib.DEFAULT_RING

  -- Report order, and the declared nesting. Membership controls only PRESENTATION — Note() accepts
  -- any key, so a bracket nobody declared still records, it just does not print.
  P.BUCKET_ORDER, P.BUCKET_WITHIN = {}, {}
  for _, b in ipairs(d.buckets or {}) do
    P.BUCKET_ORDER[#P.BUCKET_ORDER + 1] = b.key
    if b.within then P.BUCKET_WITHIN[b.key] = b.within end
  end

  -- Capture running? Read directly by every bracket call site, so it must stay a plain boolean
  -- field on a plain table — no metatable, no accessor.
  P.on        = false
  P.suspended = false
  P.run       = false     -- between Start() and Stop()
  P.armed     = nil       -- window armed, waiting for combat
  P.recording = nil       -- window currently recording

  local buckets   = {}
  local completed = { active = false, suspended = false }
  local reviewed  = { report = false, dump = false }
  local fpsArms   = {
    active    = { seconds = 0, frames = 0 },
    suspended = { seconds = 0, frames = 0 },
  }

  function P.Note(key, ms)
    local b = buckets[key]
    if not b then
      b = { calls = 0, totalMs = 0, maxMs = 0 }
      buckets[key] = b
    end
    b.calls   = b.calls + 1
    b.totalMs = b.totalMs + ms
    if ms > b.maxMs then b.maxMs = ms end
  end

  function P.Reset()
    buckets   = {}
    completed = { active = false, suspended = false }
    reviewed  = { report = false, dump = false }
    fpsArms   = {
      active    = { seconds = 0, frames = 0 },
      suspended = { seconds = 0, frames = 0 },
    }
  end

  -- Test seams: expose the live tables without letting callers swap them out.
  function P.__buckets()   return buckets   end
  function P.__fpsArms()   return fpsArms   end
  function P.__completed() return completed end
  function P.__reviewed()  return reviewed  end

  return P
end
```

The remaining tasks each append their own closures to the body of `lib:New` before the `return P`,
and Task 5 hangs the panel off the same closure scope. Keep the ordering: state, accounting, output,
record, persistence, report, windows, panel, command.

- [ ] **Step 6: Move the output helpers**

Inside `lib:New`, after the test seams, append the block adapted from `AT/core/Perf.lua:167–206`:
`stripColors` and `render` become file-local helpers **above** `lib:New` (they are stateless);
`P.Log` and `P.Announce` become closures over `hostLog` / `hostPrint`:

```lua
  --- Console only. Phase transitions and anything else worth having in the copied log.
  function P.Log(fmt, ...)
    hostLog(stripColors(render(fmt, ...)))
  end

  --- Chat AND console. For what the user must see while looking at the game rather than at the
  --- console — recording starting and ending mid-combat, above all.
  function P.Announce(fmt, ...)
    local msg = render(fmt, ...)
    hostPrint(msg)
    hostLog(stripColors(msg))
  end
```

`render` currently calls `NS.SafeToString`. The lib has no NS: replace that call with a local

```lua
local function safeToString(v)
  if v == nil then return "nil" end
  local t = type(v)
  if t == "string" then return v end
  if t == "number" or t == "boolean" then return tostring(v) end
  -- 12.0 secret values raise on tostring in some paths; never let a log line error a capture.
  local ok, s = pcall(tostring, v)
  return ok and s or "?"
end
```

- [ ] **Step 7: Add `publishState`, `Progress` and `MarkReviewed`**

Move `AT/core/Perf.lua:108–164` into the closure. `publishState` becomes:

```lua
  -- Something moved: repaint the panel, then let the host republish on its own bus if it cares.
  -- The panel refreshes DIRECTLY rather than via a message — it owns the state it renders, so the
  -- bus hop the addon-local version used was never load-bearing.
  local function publishState()
    if P.RefreshPanel then P.RefreshPanel() end
    onChange()
  end
```

`Progress()` moves verbatim — it reads only `P.run/armed/recording`, `completed` and `reviewed`, all
of which are in scope.

- [ ] **Step 8: Run the tests**

```bash
cd /mnt/d/Profile/Users/Tushar/Documents/GIT/LibKa0s && lua tests/run.lua && luacheck .
```

Expected: PASS for every test written in Step 1; luacheck 0/0.

- [ ] **Step 9: Commit** *(ask first)*

```bash
git add -A
git commit -m "feat(perf): the JSON encoder, the descriptor contract and per-host instances"
```

---

## Task 3: Record assembly, persistence and the report

**Files:**
- Modify: `LK/LibKa0s/Perf.lua`
- Modify: `LK/tests/test_perf_core.lua`

**Interfaces:**
- Consumes: `perf.Note`, `perf.Reset`, `perf.__fpsArms`, `perf.BUCKET_ORDER`, `perf.BUCKET_WITHIN`,
  `lib.SCHEMA`, `lib.EncodeJSON` from Task 2.
- Produces:
  - `perf.Context() -> ctx`, `perf.ContextLines(ctx) -> {string}`
  - `perf.BuildRecord(label) -> record` — schema 2: `{ schema, addon, source, version, interface,
    timestamp, label, buckets = { [key] = { calls, totalMs, maxMs, within? } },
    fps = { active = arm, suspended = arm, deltaMsPerFrame }, context }`
  - `perf.Save(record) -> db` writing `_G[descriptor.sv]`
  - `perf.FormatReport(record) -> {string}`

- [ ] **Step 1: Write the failing tests**

Move across from `AT/tests/test_perf.lua`, retargeted at `Fixture.new()`:

- record assembly (AT:118–158) — all five
- the SavedVariables ring (AT:162–192) — the first three; `Save is outside the AceDB tree` is an
  AbsorbTracker concern and **stays there**
- report formatting (AT:196–235) — all five
- capture context (AT:655–725) — all seven

`Save creates the perf global and appends the run` reads `_G.TestHostPerfDB` instead of
`_G.AbsorbTrackerPerfDB`. `Save trims the ring to RING_MAX` uses `Fixture.new({ ring = 3 })` and
asserts on 3, which also covers the descriptor's ring override.

Then add the four tests for what is new in v2:

```lua
test("lib: a record names the addon that produced it", function()
  local p = Fixture.new()
  local r = p.BuildRecord("cap")
  assertEqual(r.addon, "TestHost", "addon")
  assertEqual(r.schema, 2, "schema")
  assertEqual(r.version, "1.2.3", "host version")
end)

test("lib: a nested bucket carries its parent into the record", function()
  local p = Fixture.new()
  p.Note("outer", 4)
  p.Note("inner", 1)
  local r = p.BuildRecord("cap")
  assertEqual(r.buckets.inner.within, "outer", "declared nesting travels with the record")
  assertEqual(r.buckets.outer.within, nil, "a top-level bucket carries none")
end)

test("lib: FormatReport indents a nested bucket under its parent", function()
  local p = Fixture.new()
  p.Note("outer", 4)
  p.Note("inner", 1)
  local lines = table.concat(p.FormatReport(p.BuildRecord("cap")), "\n")
  T.assertTrue(lines:find("\n  inner", 1, true) ~= nil, "inner is indented two spaces")
  T.assertTrue(lines:find("outer contains inner", 1, true) ~= nil, "the nesting is spelled out")
end)

test("lib: a flat bucket set gets no nesting footer", function()
  local p = Fixture.new({ buckets = { { key = "solo" } } })
  p.Note("solo", 1)
  local lines = table.concat(p.FormatReport(p.BuildRecord("cap")), "\n")
  T.assertTrue(lines:find("do not sum", 1, true) == nil, "nothing nests, so say nothing")
end)

test("lib: a ring written under another schema is discarded, not converted", function()
  local p = Fixture.new()
  _G.TestHostPerfDB = { schema = 1, runs = { { schema = 1 }, { schema = 1 } } }
  p.Save(p.BuildRecord("cap"))
  assertEqual(_G.TestHostPerfDB.schema, 2, "stamped with the current schema")
  assertEqual(#_G.TestHostPerfDB.runs, 1, "the v1 records are gone, not migrated")
end)
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd /mnt/d/Profile/Users/Tushar/Documents/GIT/LibKa0s && lua tests/run.lua
```

Expected: FAIL — `attempt to call field 'BuildRecord' (a nil value)`.

- [ ] **Step 3: Move context capture**

Move `AT/core/Perf.lua:456–509` (`groupContext`, `P.Context`, `P.ContextLines`) into the closure,
unchanged. They touch only WoW globals and are already existence-checked throughout.

- [ ] **Step 4: Move record assembly, with the v2 additions**

Move `AT/core/Perf.lua:267–317`. `arm()` becomes a file-local (stateless). `interfaceVersion` loses
its `NS.Compat` dependency:

```lua
-- The host's TOC Interface value as a number. C_AddOns is the modern accessor and the global is the
-- pre-10.1 one; a client with neither degrades to 0 rather than erroring mid-capture.
local function interfaceVersion(name)
  local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  local raw = getMeta and getMeta(name, "Interface")
  return tonumber(raw) or 0
end
```

`BuildRecord` gains `addon` and per-bucket `within`:

```lua
    local out = {}
    for key, b in pairs(buckets) do
      out[key] = { calls = b.calls, totalMs = b.totalMs, maxMs = b.maxMs, within = P.BUCKET_WITHIN[key] }
    end

    return {
      schema    = lib.SCHEMA,
      addon     = d.name,
      source    = "ingame",
      version   = d.version or "?",
      interface = interfaceVersion(d.name),
      timestamp = time and time() or 0,
      label     = label or "",
      buckets   = out,
      fps       = { active = active, suspended = suspended, deltaMsPerFrame = delta },
      context   = P.context,
    }
```

- [ ] **Step 5: Move persistence, with the clean-break schema check**

```lua
  --- Append a record to the host's SavedVariables ring, trimming the oldest past ringMax.
  ---
  --- Writes _G[sv] directly rather than going through the host's settings DB. A perf ring inside an
  --- AceDB profile tree would be copied by "copy profile", wiped by "reset profile", and would swap
  --- out from under a capture on a profile switch — none of which is wanted for diagnostics.
  ---
  --- A ring stored under a different schema is DISCARDED rather than migrated: these are diagnostic
  --- snapshots, not user data, and a half-converted record is worse than an absent one.
  function P.Save(record)
    local db = _G[d.sv]
    if type(db) ~= "table" then
      db = {}
      _G[d.sv] = db
    end
    if db.schema ~= lib.SCHEMA then
      local dropped = db.runs and #db.runs or 0
      if dropped > 0 then
        P.Log("perf ring was schema %s, now %s \226\128\148 discarded %s old record(s)",
          tostring(db.schema), tostring(lib.SCHEMA), tostring(dropped))
      end
      db.runs = nil
    end
    db.schema = lib.SCHEMA
    db.runs = db.runs or {}
    db.runs[#db.runs + 1] = record
    while #db.runs > P.ringMax do table.remove(db.runs, 1) end
    return db
  end
```

- [ ] **Step 6: Move the report, rendering nesting as a tree**

Move `AT/core/Perf.lua:342–388`. Three changes:

1. The header line names the addon: `add("capture: %s  (%s, schema %d, v%s)", label, record.addon,
   record.schema, record.version)`.
2. The delta hint loses the addon-specific slash form:
   `add("delta:     (needs both arms \226\128\148 arm Experiment B mid-capture)")`.
3. Buckets indent by declared depth, and the footer is generated:

```lua
    -- Buckets in declared order, indented by nesting depth. ms/s divides by the ACTIVE seconds
    -- only: no bucket can accrue while suspended, so including that arm would understate every rate.
    local function depthOf(key)
      local n, parent = 0, record.buckets[key] and record.buckets[key].within or P.BUCKET_WITHIN[key]
      while parent and n < 8 do                        -- the guard is against a malformed descriptor
        n, parent = n + 1, P.BUCKET_WITHIN[parent]
      end
      return n
    end

    local secs = f.active.seconds
    add("")
    add("%-14s %8s %10s %10s %9s", "bucket", "calls", "total ms", "ms/s", "max ms")
    for _, key in ipairs(P.BUCKET_ORDER) do
      local b = record.buckets[key]
      if b then
        local name = ("  "):rep(depthOf(key)) .. key
        add("%-14s %8d %10.2f %10.3f %9.3f",
          name, b.calls, b.totalMs, secs > 0 and (b.totalMs / secs) or 0, b.maxMs)
      end
    end

    -- Nested totals are not disjoint and must never be summed. Spelling out which contains which
    -- beats trusting the reader to notice the indentation.
    local pairsOut = {}
    for _, key in ipairs(P.BUCKET_ORDER) do
      local parent = P.BUCKET_WITHIN[key]
      if parent and record.buckets[key] then
        pairsOut[#pairsOut + 1] = ("%s contains %s"):format(parent, key)
      end
    end
    if #pairsOut > 0 then
      add("(buckets nest: %s \226\128\148 do not sum)", table.concat(pairsOut, ", "))
    end
```

- [ ] **Step 7: Run the tests**

```bash
cd /mnt/d/Profile/Users/Tushar/Documents/GIT/LibKa0s && lua tests/run.lua && luacheck .
```

Expected: all pass, 0/0.

- [ ] **Step 8: Commit** *(ask first)*

```bash
git add -A
git commit -m "feat(perf): schema v2 records, the ring, and a report that renders nesting"
```

---

## Task 4: The sampler, the combat-gated windows, and suspend/resume

**Files:**
- Modify: `LK/LibKa0s/Perf.lua`
- Create: `LK/tests/test_perf_run.lua`
- Modify: `LK/tests/run.lua` (add the suite to `SUITES` — it is already listed from Task 1)

**Interfaces:**
- Consumes: everything from Tasks 2–3.
- Produces:
  - `perf.EXPERIMENTS = { a = "active", b = "suspended" }`, `perf.LABELS = { active = "A", suspended = "B" }`
  - `perf.Start(label)`, `perf.Measure(token) -> arm | nil, err`, `perf.Stop() -> record`,
    `perf.Cancel() -> bool`, `perf.Suspend() -> bool`, `perf.Resume() -> bool`
  - test seam `perf.__sampler()`

- [ ] **Step 1: Write the failing tests**

`LK/tests/test_perf_run.lua` — header, then the helpers ported from `AT/tests/test_perf.lua:465–493`
with the mock-driven combat flag:

```lua
-- tests/test_perf_run.lua — the sampler, the combat-gated measurement windows, suspend/resume,
-- and the announcements that come out of them.

local T = _G.LK_TEST
local mocks = T.mocks
local test, assertEqual, assertTrue, assertFalse =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse
local Fixture = dofile("tests/fixture.lua")

-- Drive one sampler frame by hand. The real client calls OnUpdate every frame with the elapsed
-- seconds; a test says exactly how much time passed and whether the player was in combat, so every
-- assertion below is exact rather than wall-clock flaky.
local function tick(p, seconds, combat)
  mocks.__inCombat = combat and true or false
  local f = p.__sampler()
  assertTrue(f ~= nil, "sampler frame exists")
  f:__fire("OnUpdate", seconds)
end
```

Then port these from `AT/tests/test_perf.lua`, substituting `p` for `P` and `tick(p, …)` for
`tick(…)`:

- the whole `combat-gated measurement windows` section (AT:495–648) — 15 tests
- `suspend returns false when already suspended` (AT:291), `resume returns false when not
  suspended` (AT:298), `the suspended state is session-only, never persisted` (AT:365)
- the whole `experiment announcements` section (AT:729–837) — 6 tests
- `starting an experiment logs it` (AT:395), `stopping an experiment logs both arm durations`
  (AT:404), `suspend and resume are logged` (AT:415), `a no-op suspend or resume logs nothing`
  (AT:424), `nothing is logged when no run is happening` (AT:455)

`captureDebugLines` (AT:385) is replaced by reading `rec.log` from the fixture; `lifecycle lines
appear even with debug logging OFF` (AT:438) is an AbsorbTracker concern (it is about `NS.State.debug`
gating) and **stays there**.

Add three tests for the host contract, which is new:

```lua
test("lib: measure b calls the host's suspend, measure a its resume", function()
  local p, rec = Fixture.new()
  p.Start("cap")
  p.Measure("b")
  assertEqual(rec.calls[#rec.calls], "suspend", "arming B suspends the host")
  p.Measure("a")
  assertEqual(rec.calls[#rec.calls], "resume", "arming A resumes it")
end)

test("lib: cancelling a suspended run restores the host", function()
  local p, rec = Fixture.new()
  p.Start("cap")
  p.Measure("b")
  p.Cancel()
  assertEqual(rec.calls[#rec.calls], "resume", "cancel must never strand a host inert")
  assertFalse(p.suspended, "suspended cleared")
end)

test("lib: the stopwatch is driven per window", function()
  local p = Fixture.new()
  p.Start("cap")
  mocks.__stopwatch = {}
  p.Measure("a")
  assertEqual(mocks.__stopwatch[1], "clear", "arming resets the stopwatch")
  tick(p, 0.1, true)
  assertEqual(mocks.__stopwatch[2], "play", "recording starts it")
  tick(p, 0.1, false)
  assertEqual(mocks.__stopwatch[3], "pause", "the window closing pauses it")
end)
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd /mnt/d/Profile/Users/Tushar/Documents/GIT/LibKa0s && lua tests/run.lua
```

Expected: FAIL — `attempt to call field 'Start' (a nil value)`.

- [ ] **Step 3: Move the windows and the sampler**

Move `AT/core/Perf.lua:390–652` into the closure — the long comment header (it is the design
rationale for the whole protocol and must survive the move), `P.EXPERIMENTS`, `P.LABELS`, the
`sampler` local, `ensureSampler`, `P.__sampler`, `stopwatch`, `inCombat`, `openWindow`,
`closeWindow`, `onUpdate`, `P.Start`, `P.Measure`, `P.Stop`, `P.Cancel`.

Two edits only:

1. `ensureSampler` names the frame after the host so a `/framestack` in-game says who owns it:

```lua
  local function ensureSampler()
    if sampler then return sampler end
    if type(CreateFrame) ~= "function" then return nil end
    -- Created under the CALLING HOST's ownership, never shared between instances. A shared sampler
    -- would bill its OnUpdate to whichever addon created it — the precise attribution failure this
    -- library exists to work around.
    sampler = CreateFrame("Frame", d.name .. "PerfSampler")
    sampler:Hide()
    return sampler
  end
```

2. The `P.Start` comment that references `§12.4` and `NS.Debug` is rewritten — the lib has no such
gate, and its lifecycle lines are never gated (a user who started a run should not have to have
enabled debug logging first to see it working).

- [ ] **Step 4: Write suspend/resume over the host callbacks**

Replacing `AT/core/Perf.lua:654–706`:

```lua
  -- ── Suspend / resume ─────────────────────────────────────────────────────────────────────
  --
  -- The host owns what "inert" means; the lib owns only the state and the announcement. Two rules
  -- the host contract depends on, both learned the hard way and both documented in the README:
  --
  --   * Suspend MUST make the addon inert WITHOUT a reload. Reloading or disabling an addon shifts
  --     shared-frame ownership, which is the confound that makes the built-in Addon Profiler
  --     useless for this question.
  --   * Visibility MUST be enforced at the source — a `perf.suspended` check inside the host's own
  --     show-decision — rather than by imperatively hiding frames here. Otherwise a combat
  --     transition, a target swap or a settings change re-shows a bar behind suspend's back.

  function P.Suspend()
    if P.suspended then return false end
    P.suspended = true
    P.Log("addon SUSPENDED \226\128\148 inert")
    d.suspend()
    return true
  end

  function P.Resume()
    if not P.suspended then return false end
    P.suspended = false
    P.Log("addon RESUMED \226\128\148 events and frames restored")
    d.resume()
    return true
  end
```

- [ ] **Step 5: Run the tests**

```bash
cd /mnt/d/Profile/Users/Tushar/Documents/GIT/LibKa0s && lua tests/run.lua && luacheck .
```

Expected: all pass, 0/0.

- [ ] **Step 6: Commit** *(ask first)*

```bash
git add -A
git commit -m "feat(perf): the combat-gated measurement windows and the host suspend contract"
```

---

## Task 5: The step panel

**Files:**
- Create: `LK/LibKa0s/PerfPanel.lua`
- Modify: `LK/LibKa0s/LibKa0s.xml`, `LK/LibKa0s/Perf.lua` (expose the hook), `LK/tests/run.lua`
- Create: `LK/tests/test_perf_panel.lua`

**Interfaces:**
- Consumes: `perf.Progress`, `perf.slash`, `perf.title`, `perf.name`, the `tr` string lookup, and
  the `publishState` → `P.RefreshPanel()` call from Task 2.
- Produces: `perf.ShowPanel()`, `perf.HidePanel()`, `perf.TogglePanel()`, `perf.IsPanelShown() -> bool`,
  `perf.RefreshPanel()`, `perf.PanelStateOf(key) -> string`, `perf.PanelIsActionable(key) -> bool`,
  `perf.STEPS` (array of `{ key, label, command }`), test seam `perf.__panel()`.
- Produces: `lib.__AttachPanel(P, d, tr, runCommand)` — internal, called at the end of `lib:New`.

- [ ] **Step 1: Write the failing tests**

`LK/tests/test_perf_panel.lua` — port from `AT/tests/test_perf.lua`:

- the whole `the step panel` section (AT:839–1087) — 20 tests
- the whole `the cancel step` section (AT:1091–1176) — 7 tests
- the whole `the three-column layout` section (AT:1176–1215) — 3 tests
- the whole `showing and hiding the panel` section (AT:1215–1330) — 8 tests

Substitutions throughout: `P` → a per-test `Fixture.new()`; `NS.PerfPanel:Refresh()` →
`p.RefreshPanel()`; `Panel.StateOf` → `p.PanelStateOf`; `Panel.IsActionable` → `p.PanelIsActionable`;
`Panel.__frame()` → `p.__panel()`; `"/at perf measure a"` → `"/th perf measure a"`;
`"Absorb Tracker \226\128\148 Perf Run"` → `"Test Host \226\128\148 Perf Run"`.

`the panel refreshes off the bus, not by polling` (AT:1048) becomes:

```lua
test("lib: the panel repaints itself on every state transition", function()
  local p = Fixture.new()
  p.ShowPanel()
  p.Start("cap")
  assertEqual(p.__panel().buttons.measureA.__state, "ready",
    "no bus hop: the panel owns the state it renders and repaints directly")
end)
```

`the close button hides the panel and leaves the run alone` (AT:1319) is rewritten against
`decorate`, since the close button is now the host's:

```lua
test("lib: decorate is handed the frame and a way to close it", function()
  local seen
  local p = Fixture.new({
    decorate = function(frame, api)
      seen = { frame = frame, hide = api.Hide, titleH = api.TITLE_H }
    end,
  })
  p.ShowPanel()
  assertTrue(seen ~= nil and seen.frame ~= nil, "decorate ran once, with the frame")
  assertTrue(type(seen.hide) == "function", "and a Hide it can wire to a close button")
  assertTrue(type(seen.titleH) == "number", "and the metrics to position against")
  seen.hide()
  assertFalse(p.IsPanelShown(), "hiding through the api works")
  assertTrue(p.run == false, "and never touches the run")
end)

test("lib: a host that passes no decorate still gets a working panel", function()
  local p = Fixture.new()
  p.ShowPanel()
  assertTrue(p.IsPanelShown(), "degrades to a plain frame, not an error")
end)
```

- [ ] **Step 2: Add the suite and run to verify it fails**

Add `"test_perf_panel"` to `SUITES` in `LK/tests/run.lua` (already listed if Task 1 was followed) and
add `"LibKa0s/PerfPanel.lua"` to the `Loader.loadAll` list.

```bash
cd /mnt/d/Profile/Users/Tushar/Documents/GIT/LibKa0s && lua tests/run.lua
```

Expected: FAIL — `loadfile(LibKa0s/PerfPanel.lua)` cannot find the file.

- [ ] **Step 3: Write the panel module**

`LK/LibKa0s/PerfPanel.lua` — the whole of `AT/core/PerfPanel.lua`, restructured from a singleton
module into a factory attached to the same LibStub major:

```lua
-- LibKa0s-Perf-1.0 — the clickable step panel for a perf run.
--
-- Part of the Perf module rather than a major of its own: it is the same feature, and splitting it
-- across LibStub majors would let a host end up with a panel from one copy and a probe from another.
-- The guard below is the standard multi-file idiom — if an older copy of Perf.lua won the LibStub
-- race, or a newer panel is already attached, this file is a no-op.

local lib = LibStub and LibStub("LibKa0s-Perf-1.0", true)
if not lib then return end
local PANEL_MINOR = 1
if lib.__panelMinor and lib.__panelMinor >= PANEL_MINOR then return end
lib.__panelMinor = PANEL_MINOR

-- Three columns: status dot, step, slash command. The command column is the point — it teaches the
-- typed form while you click, so the panel is a crutch you can stop needing.
local ROW_W, ROW_H, GAP = 360, 22, 4
local DOT_X, DOT = 8, 8
local LABEL_X   = 26
local CMD_PAD   = 10
local TITLE_H = 24
local PAD = 8
```

Then `BACKDROP`, `COLORS`, `CMD_COLOR` verbatim from `AT/core/PerfPanel.lua:29–53`, and:

```lua
-- Ordered, and the order IS the workflow. `key` matches a field of Progress(); `command` is the
-- sub-verb the host's slash handler will be given.
local STEPS = {
  { key = "start",    string = "STEP_START",     command = "perf start"     },
  { key = "measureA", string = "STEP_MEASURE_A", command = "perf measure a" },
  { key = "measureB", string = "STEP_MEASURE_B", command = "perf measure b" },
  { key = "finish",   string = "STEP_FINISH",    command = "perf finish"    },
  { key = "report",   string = "STEP_REPORT",    command = "perf report"    },
  { key = "dump",     string = "STEP_DUMP",      command = "perf dump"      },
  -- Outside the linear progression: clickable for as long as there is a run to abandon, and
  -- doubles as nothing once there is not — an live-looking button that discards nothing is just a
  -- way to worry someone.
  { key = "cancel",   string = "STEP_CANCEL",    command = "perf cancel"    },
}

--- Attach the panel closures to one instance. Called at the end of lib:New, so every host gets its
--- own frame — created lazily, on first show, under that host's ownership.
function lib.__AttachPanel(P, d, tr, runCommand)
  local frame
  local decorate = type(d.decorate) == "function" and d.decorate or nil

  P.STEPS = {}
  for i, s in ipairs(STEPS) do
    P.STEPS[i] = { key = s.key, label = tr(s.string), command = s.command }
  end

  local function setColor(fs, state)
    local c = COLORS[state] or COLORS.locked
    fs:SetTextColor(c[1], c[2], c[3])
  end

  function P.PanelStateOf(key)
    if not P.Progress then return "locked" end
    return P.Progress()[key] or "locked"
  end

  function P.PanelIsActionable(key)
    local state = P.PanelStateOf(key)
    return state == "ready" or state == "cancel" or state == "used"
  end
  ...
end
```

`makeStepButton` moves in as a local inside `__AttachPanel` (it closes over `P` and the slash
prefix). Three changes from the addon version:

1. The command column reads `P.slash .. " " .. step.command` rather than a hard-coded `"/at "`.
2. The click handler calls `runCommand(step.command)` — supplied by `lib:New` as
   `function(cmd) P.OnCommand(cmd:match("^perf%s*(.*)$")) end` in Task 6, so a click and a typed
   command take the same path. Until Task 6 lands, pass `function() end` and the panel tests that
   assert dispatch will be written in Task 6.
3. `EnsureFrame` names the frame `d.name .. "PerfPanel"`, titles it
   `P.title .. tr("PANEL_TITLE_SUFFIX")`, calls `decorate(frame, { Show = P.ShowPanel, Hide =
   P.HidePanel, Toggle = P.TogglePanel, TITLE_H = TITLE_H, PAD = PAD, ROW_W = ROW_W })` where the
   addon version built the DebugLog close button, and inserts `d.name .. "PerfPanel"` into
   `UISpecialFrames`.

`Panel:Refresh` becomes `P.RefreshPanel`, `Panel:Show/Hide/Toggle/IsShown` become
`P.ShowPanel/HidePanel/TogglePanel/IsPanelShown`, `Panel.__frame` becomes `P.__panel`. The bus
subscription at `AT/core/PerfPanel.lua:236–242` is **deleted** — `publishState` calls
`P.RefreshPanel()` directly.

Keep `b.__label`, `b.__state`, `b.__command` — the headless suite reads them, for the reason given in
the comment at `AT/core/PerfPanel.lua:210`.

- [ ] **Step 4: Call the factory from `New`**

At the end of `lib:New`, immediately before `return P`:

```lua
  -- The panel is part of this module; a copy of the lib without PerfPanel.lua loaded still works,
  -- it just has no panel. Hosts reach it through P.ShowPanel and friends.
  if lib.__AttachPanel then lib.__AttachPanel(P, d, tr, function(cmd) return P.OnCommand(cmd) end) end
```

and add the no-panel fallbacks just above it, so a host can call them unconditionally:

```lua
  P.ShowPanel     = function() end
  P.HidePanel     = function() end
  P.TogglePanel   = function() end
  P.RefreshPanel  = function() end
  P.IsPanelShown  = function() return false end
```

- [ ] **Step 5: Add the file to the XML**

```xml
<Ui xmlns="http://www.blizzard.com/wow/ui/">
	<Script file="Perf.lua"/>
	<Script file="PerfPanel.lua"/>
</Ui>
```

- [ ] **Step 6: Run the tests**

```bash
cd /mnt/d/Profile/Users/Tushar/Documents/GIT/LibKa0s && lua tests/run.lua && luacheck .
```

Expected: all pass, 0/0.

- [ ] **Step 7: Commit** *(ask first)*

```bash
git add -A
git commit -m "feat(perf): the step panel, one frame per host, styled by the host"
```

---

## Task 6: `OnCommand` — behaviour without a slash command

**Files:**
- Modify: `LK/LibKa0s/Perf.lua`
- Create: `LK/tests/test_perf_command.lua`

**Interfaces:**
- Consumes: everything above.
- Produces: `perf.OnCommand(args) -> lines` (array of strings for the host to print; never nil),
  `perf.Usage() -> lines`, `perf.StatusLines() -> lines`.

The lib MUST NOT register a slash command — the Ka0s standard mandates schema-driven dispatch
through each addon's own `COMMANDS` table, and third parties do not use that pattern at all. The lib
supplies behaviour and help text; the host owns its slash surface.

- [ ] **Step 1: Write the failing tests**

`LK/tests/test_perf_command.lua`:

```lua
-- tests/test_perf_command.lua — the command surface the host wires into its own slash table.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse
local Fixture = dofile("tests/fixture.lua")

local function joined(lines) return table.concat(lines or {}, "\n") end

test("cmd: OnCommand always returns a line table, never nil", function()
  local p = Fixture.new()
  assertTrue(type(p.OnCommand("")) == "table", "bare")
  assertTrue(type(p.OnCommand("start")) == "table", "start")
  assertTrue(type(p.OnCommand("nonsense")) == "table", "unknown")
end)

test("cmd: start begins a run and shows the panel", function()
  local p = Fixture.new()
  p.OnCommand("start")
  assertTrue(p.run, "run began")
  assertTrue(p.IsPanelShown(), "the panel is the entry point, so start opens it")
end)

test("cmd: a label is appended to the timestamp, never replaces it", function()
  local p = Fixture.new()
  p.OnCommand("start solo dummy")
  assertTrue(p.label:find("solo dummy", 1, true) ~= nil, "label present")
  assertTrue(#p.label > #"solo dummy", "stamped as well")
end)

test("cmd: measure reports which window armed and whether the host is suspended", function()
  local p = Fixture.new()
  p.OnCommand("start")
  local out = joined(p.OnCommand("measure b"))
  assertTrue(out:find("B", 1, true) ~= nil, "names the window as the user typed it")
  assertTrue(out:upper():find("SUSPENDED", 1, true) ~= nil, "says the host is suspended")
end)

test("cmd: measure outside a run tells you to start one", function()
  local p = Fixture.new()
  assertTrue(joined(p.OnCommand("measure a")):find("start", 1, true) ~= nil, "points at start")
end)

test("cmd: measure rejects an unknown window token", function()
  local p = Fixture.new()
  p.OnCommand("start")
  assertTrue(joined(p.OnCommand("measure z")):find("unknown", 1, true) ~= nil, "rejected")
end)

test("cmd: finish resumes the host before it saves", function()
  local p, rec = Fixture.new()
  p.OnCommand("start")
  p.OnCommand("measure b")
  p.OnCommand("finish")
  assertFalse(p.suspended, "an error in Save must never strand the host inert")
  assertEqual(rec.calls[#rec.calls], "resume", "resume came from the host")
  assertEqual(#_G.TestHostPerfDB.runs, 1, "and the record was saved")
end)

test("cmd: finish prints no report", function()
  local p, rec = Fixture.new()
  p.OnCommand("start")
  p.OnCommand("finish")
  assertTrue(joined(rec.log):find("bucket", 1, true) == nil,
    "finish fires as a fight ends, when a dozen unread lines is the wrong gift")
end)

test("cmd: report writes the summary to the log sink and opens it", function()
  local opened = false
  local p, rec = Fixture.new({ showLog = function() opened = true end })
  p.OnCommand("start")
  p.OnCommand("finish")
  p.OnCommand("report")
  assertTrue(joined(rec.log):find("capture:", 1, true) ~= nil, "the report went to the log")
  assertTrue(opened, "and the host was asked to show it")
  assertEqual(p.Progress().report, "used", "and the step is marked without being disabled")
end)

test("cmd: dump writes one line of JSON to the log sink", function()
  local p, rec = Fixture.new()
  p.OnCommand("start")
  p.OnCommand("finish")
  p.OnCommand("dump")
  local last = rec.log[#rec.log]
  assertEqual(last:sub(1, 1), "{", "one JSON object")
  assertTrue(last:find('"addon":"TestHost"', 1, true) ~= nil, "self-identifying")
  assertEqual(p.Progress().dump, "used", "marked")
end)

test("cmd: cancel refuses when there is nothing to cancel", function()
  local p = Fixture.new()
  assertTrue(joined(p.OnCommand("cancel")):find("no perf run", 1, true) ~= nil, "said so")
end)

test("cmd: show, hide and toggle drive the panel and nothing else", function()
  local p = Fixture.new()
  p.OnCommand("start")
  p.OnCommand("hide")
  assertFalse(p.IsPanelShown(), "hidden")
  assertTrue(p.run, "hiding a panel is not abandoning a capture")
  p.OnCommand("toggle")
  assertTrue(p.IsPanelShown(), "back")
end)

test("cmd: a bare command reports the phase and prints the usage", function()
  local p = Fixture.new()
  local out = joined(p.OnCommand(""))
  assertTrue(out:find("stopped", 1, true) ~= nil, "phase")
  assertTrue(out:find("/th perf", 1, true) ~= nil, "usage carries the host's own slash token")
  assertTrue(p.IsPanelShown(), "bare IS the entry point")
end)

test("cmd: usage never hard-codes a slash prefix", function()
  local p = Fixture.new({ slash = "/kick" })
  assertTrue(joined(p.Usage()):find("/kick perf", 1, true) ~= nil, "host's prefix")
  assertTrue(joined(p.Usage()):find("/th", 1, true) == nil, "and only the host's")
end)

test("cmd: clicking a ready panel row takes the same path as typing it", function()
  local p = Fixture.new()
  p.ShowPanel()
  p.__panel().buttons.start:__fire("OnClick")
  assertTrue(p.run, "the click started the run")
end)

test("cmd: clicking a locked panel row does nothing", function()
  local p = Fixture.new()
  p.ShowPanel()
  p.__panel().buttons.finish:__fire("OnClick")
  assertFalse(p.run, "a step that runs out of order corrupts the run it was meant to protect")
end)
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd /mnt/d/Profile/Users/Tushar/Documents/GIT/LibKa0s && lua tests/run.lua
```

Expected: FAIL — `attempt to call field 'OnCommand' (a nil value)`.

- [ ] **Step 3: Write the usage text**

Inside `lib:New`, adapted from `AT/settings/Slash.lua:273–290`, with `P.slash` substituted for the
hard-coded `/at` and the AbsorbTracker-specific SavedVariables name replaced by `d.sv`:

```lua
  --- Help text for the host to print. Returned rather than printed, so a host can fold it into its
  --- own help output however it likes.
  function P.Usage()
    local s = P.slash
    return {
      ("usage: |cFFFFFF00%s perf <start|measure|finish|cancel|report|dump|show|hide|toggle>|r"):format(s)
        .. " \226\128\148 or just click the panel",
      "  |cFFFFFF00start [label]|r  begin a run; zeroes the counters and records who/where you are.",
      "                 The label is appended to the timestamp so runs are tellable apart.",
      "  |cFFFFFF00measure a|r      arm Experiment A \226\128\148 addon ACTIVE. Recording starts the moment",
      "                 combat does and ends when combat ends. Nothing between is measured.",
      "  |cFFFFFF00measure b|r      arm Experiment B \226\128\148 same, but suspends the addon first, so the",
      "                 two experiments differ by the addon and nothing else.",
      ("  |cFFFFFF00finish|r         end the run, save it to %s and lift any suspend."):format(d.sv),
      "                 Prints nothing \226\128\148 use `report` when you want to read it. `/reload` to flush.",
      "  |cFFFFFF00cancel|r         abandon the run \226\128\148 discards it unsaved and restores the addon.",
      "                 Only available while a run is actually in flight.",
      "  |cFFFFFF00report|r         print the summary; opens the log window if it is hidden.",
      "  |cFFFFFF00dump|r           render the run as one line of JSON in the log, for pasting",
      "                 somewhere. Same data the summary is built from.",
      "  |cFFFFFF00show|r / |cFFFFFF00hide|r / |cFFFFFF00toggle|r   the step panel. Hiding it never touches the run.",
    }
  end
```

- [ ] **Step 4: Write the dispatch table**

Port `AT/settings/Slash.lua:297–408` into the closure. Each handler now **appends to a `lines` table**
rather than calling `print`, and the console-opening side effects go through `showLog()`:

```lua
  -- Sub-verb handlers, one entry each. A dispatch table rather than an if/elseif ladder: the ladder
  -- form measured CCN 24 under `lizard`, the worst in the addon this was extracted from, purely
  -- from the shape of the dispatch. Each handler here is CCN 1-3 and reads on its own.
  --
  -- Handlers take (out, rest) and append chat lines to `out`. Returning lines rather than printing
  -- them is what lets the host own its output — and is why the lib needs no chat frame of its own.
  local SUBS = {}

  -- `rest` is the free text after the sub-verb: an optional capture label. Captures accumulate in a
  -- ring across sessions, so an auto-timestamp alone makes two runs from the same afternoon
  -- near-impossible to tell apart when reading the SavedVariables file later. A supplied label is
  -- appended to the timestamp, never replaces it.
  function SUBS.start(out, rest)
    local stamp = date and date("%Y-%m-%d %H:%M") or "capture"
    local label = (rest or ""):match("^%s*(.-)%s*$")
    P.Start(label ~= "" and (stamp .. " " .. label) or stamp)
    P.Announce("perf run |cff40ff40STARTED|r \226\128\148 %s", P.label or "unlabelled")
    for _, line in ipairs(P.ContextLines(P.context)) do out[#out + 1] = line end
    showLog()
    -- The clickable equivalent of the steps just printed. Chat scrolls away the moment combat
    -- starts; the panel does not.
    P.ShowPanel()
  end

  function SUBS.measure(out, rest)
    local token = (rest or ""):match("^(%S*)")
    local armName, err = P.Measure(token)
    if not armName then
      if err == "no experiment" then
        out[#out + 1] = ("start one first \226\128\148 `%s perf start`"):format(P.slash)
      else
        out[#out + 1] = ("unknown window '%s' \226\128\148 use `measure a` or `measure b`")
          :format(token ~= "" and token or "?")
      end
      return
    end
    out[#out + 1] = ("Experiment |cFFFFFF00%s|r |cffffff00ARMED|r (%s) \226\128\148 recording starts "
      .. "when combat does, and ends when combat does"):format(token:upper(),
      armName == "suspended" and "addon |cffff4040SUSPENDED|r" or "addon |cff40ff40active|r")
  end

  function SUBS.show()   P.ShowPanel()   end
  function SUBS.hide()   P.HidePanel()   end
  function SUBS.toggle() P.TogglePanel() end

  function SUBS.cancel(out)
    if not P.Cancel() then
      out[#out + 1] = "no perf run to cancel"
      return
    end
    out[#out + 1] = "perf run |cffcc5252CANCELLED|r \226\128\148 nothing saved"
  end

  function SUBS.finish(out)
    if not P.run then
      out[#out + 1] = ("no perf run is active \226\128\148 `%s perf start`"):format(P.slash)
      return
    end
    local record = P.Stop()
    -- Resume BEFORE saving or formatting. Experiment B leaves the host inert, and with no manual
    -- resume verb the only other way back is a /reload — so an error in Save or FormatReport must
    -- not be able to strand the addon dead for the rest of the session.
    if P.suspended then
      P.Resume()
      out[#out + 1] = "addon |cff40ff40RESUMED|r \226\128\148 restored"
    end
    P.Save(record)
    -- Deliberately does NOT print the summary. `finish` fires the moment a fight ends, when the log
    -- is buried under combat output and the numbers scroll past unread.
    P.Announce("perf run |cffff4040FINISHED|r \226\128\148 saved; `Report` or `Dump` in the panel "
      .. "to read it, `/reload` to flush it to SavedVariables")
  end

  function SUBS.report()
    showLog()
    for _, line in ipairs(P.FormatReport(P.BuildRecord(P.label))) do P.Log(line) end
    P.MarkReviewed("report")
  end

  -- Writes the JSON to the log, NOT a popup. The log is the window you already have open and can
  -- scroll; popping a modal over the game for something you may only want to glance at is the wrong
  -- default.
  function SUBS.dump()
    showLog()
    P.Log(lib.EncodeJSON(P.BuildRecord(P.label)))
    P.MarkReviewed("dump")
  end

  --- Phase summary plus the usage. Bare `<slash> perf` IS the entry point: the panel's first row
  --- starts a run, so this is how someone who remembers one command reaches all of them.
  function P.StatusLines()
    local phase = "|cffff4040stopped|r"
    if P.recording then
      phase = ("|cff40ff40SAMPLING window %s|r"):format(P.recording)
    elseif P.armed then
      phase = ("|cffffff00window %s armed|r \226\128\148 waiting for combat"):format(P.armed)
    elseif P.run then
      phase = "|cffffff00run active|r \226\128\148 no experiment armed"
    end
    local out = { ("perf %s, addon %s"):format(phase,
      P.suspended and "|cffff4040SUSPENDED|r" or "|cff40ff40active|r") }
    for _, line in ipairs(P.Usage()) do out[#out + 1] = line end
    return out
  end

  --- Run one perf sub-command. `args` is everything after the host's own `perf` verb. Returns the
  --- chat lines the host should print — never nil, so a caller can always ipairs() the result.
  function P.OnCommand(args)
    args = tostring(args or "")
    -- A panel row hands back its full command ("perf measure a"); a slash handler hands back only
    -- what followed its own verb. Accept both so the two paths cannot diverge.
    args = args:gsub("^%s*perf%s*", "")
    local sub = (args:match("^(%S*)") or ""):lower()
    local handler = SUBS[sub]
    if not handler then
      P.ShowPanel()
      return P.StatusLines()
    end
    local out = {}
    handler(out, args:match("^%S*%s+(.*)$"))
    return out
  end
```

- [ ] **Step 5: Run the tests**

```bash
cd /mnt/d/Profile/Users/Tushar/Documents/GIT/LibKa0s && lua tests/run.lua && luacheck .
```

Expected: all pass, 0/0. If `clicking a ready panel row` fails, the `runCommand` wiring from Task 5
Step 4 is what to check.

- [ ] **Step 6: Commit** *(ask first)*

```bash
git add -A
git commit -m "feat(perf): OnCommand — the whole guided run, with no slash command of its own"
```

---

## Task 7: LibKa0s documentation, and close issue #4

**Files:**
- Modify: `LK/README.md`, `LK/CHANGELOG.md`
- Create: `LK/docs/record-schema.md`

**Interfaces:** none — documentation only.

- [ ] **Step 1: Write the descriptor contract into the README**

`LK/README.md` gains, in this order:

1. **What it is** — a Ka0s-owned shared library, vendored like Ace3, one LibStub major per module.
   `LibKa0s-Perf-1.0` is the first module.
2. **Why it exists** — the two-line version of the spec's Problem section: WoW's Addon Profiler
   attributes a shared frame's CPU to whichever addon created it, so the only trustworthy answer
   comes from an A/B on the same fight with load order held fixed.
3. **Installing** — copy `LibKa0s/` into `<Addon>/libs/LibKa0s/`, add
   `libs\LibKa0s\LibKa0s.xml` to the TOC's lib block after Ace3, declare
   `## SavedVariables: <Addon>PerfDB`. Do **not** list LibKa0s under `## Dependencies:` — it is
   vendored, and every Ka0s addon must work with no other addon installed.
4. **The descriptor**, as a table: field, type, required, meaning. Copy the field list from the spec's
   Architecture section and add `slash`, `title`, `showLog` with the reasons from the Deviations
   table at the top of this plan. State the additive-only rule: within `-1.0` a field may be added,
   never removed or repurposed.
5. **A worked integration example** — AbsorbTracker's real `core/PerfSetup.lua` from Task 9, verbatim.
6. **The host contract for `suspend`/`resume`** — the two rules from Task 4 Step 4's comment block,
   spelled out, because a host that gets these wrong produces a capture that lies rather than one
   that errors.
7. **The public surface** — the list from the spec, as a table of name → one-line meaning.
8. **Development** — `lua tests/run.lua`, `luacheck .`, and the note that both must be 0/0 before a
   release, plus the two-version rule (repo semver for humans, per-module LibStub minor for LibStub).

- [ ] **Step 2: Document the record schema**

`LK/docs/record-schema.md` — adapt `AT/docs/perf-runs/README.md`, which already documents schema 1.
Field-by-field for v2, with a worked example record. Call out the two v2 additions explicitly
(`addon` at the top level, `within` per bucket) and state the clean-break rule: a stored ring under
any other schema is discarded on the next `Save`, because these are diagnostic snapshots and a
half-converted record is worse than an absent one.

- [ ] **Step 3: Run the gate and commit** *(ask first)*

```bash
cd /mnt/d/Profile/Users/Tushar/Documents/GIT/LibKa0s && lua tests/run.lua && luacheck .
git add -A
git commit -m "docs: the descriptor contract, the host contract, and record schema v2"
```

- [ ] **Step 4: Close issue #4 with the decision**

```bash
gh issue close 4 --repo tusharsaxena/LibKa0s --comment "Resolved as a clean break: the perf ring has not shipped in any addon, so there are no v1 rings in the wild to migrate. Save() now discards a ring stored under any other schema and stamps schema 2 — see LibKa0s/Perf.lua and docs/record-schema.md. The committed schema-1 capture in AbsorbTracker's docs/perf-runs/ stays as history and is not re-read by the addon."
```

---

## Task 8: Vendor the lib into AbsorbTracker, with nothing yet consuming it

This task lands the lib and the harness support **without** removing anything, so it is green on its
own and the swap in Task 9 is a swap rather than a rewrite-plus-swap.

**Files:**
- Create: `AT/libs/LibKa0s/` (copy of `LK/LibKa0s/`)
- Modify: `AT/AbsorbTracker.toc`, `AT/tests/wow_mock.lua`, `AT/tests/run.lua`

**Interfaces:**
- Produces: `LibStub("LibKa0s-Perf-1.0")` resolvable both in-game and in the headless harness.

- [ ] **Step 1: Copy the payload**

```bash
cd /mnt/d/Profile/Users/Tushar/Documents/GIT/AbsorbTracker
mkdir -p libs/LibKa0s
cp ../LibKa0s/LibKa0s/LibKa0s.xml ../LibKa0s/LibKa0s/Perf.lua ../LibKa0s/LibKa0s/PerfPanel.lua libs/LibKa0s/
lua -e 'assert(loadfile("libs/LibKa0s/Perf.lua")); assert(loadfile("libs/LibKa0s/PerfPanel.lua")); print("syntax ok")'
```

Nothing else from the LibKa0s repo is copied. `tests/`, `docs/`, `README.md` and `LICENSE` stay
upstream — the vendorable payload is exactly the inner folder.

- [ ] **Step 2: Add it to the TOC**

In `AT/AbsorbTracker.toc`, inside the `#@no-lib-strip@` block, after the last Ace line and before
`libs\LibSharedMedia-3.0\lib.xml`:

```
libs\LibKa0s\LibKa0s.xml
```

- [ ] **Step 3: Give the mock a real LibStub**

Replace `AT/tests/wow_mock.lua:419–425` with a LibStub that can both serve the Ace mocks and accept a
real registration:

```lua
  -- LibStub. The Ace libraries are mocks looked up from `libs`; the vendored LibKa0s modules
  -- register for real through NewLibrary, exactly as they do in the client. LibStub("X") and
  -- LibStub("X", true) both resolve to whatever is registered, or nil — mirroring the addon's
  -- soft-optional lib usage (LibSharedMedia / AceGUI are absent headlessly).
  local minors = {}
  M.LibStub = setmetatable({
    GetLibrary = function(_, n) return libs[n], minors[n] end,
    NewLibrary = function(_, major, minor)
      minor = tonumber(minor)
      if minors[major] and minors[major] >= minor then return nil end
      libs[major] = libs[major] or {}
      minors[major] = minor
      return libs[major], minors[major]
    end,
  }, { __call = function(self, n) return self:GetLibrary(n) end })
```

- [ ] **Step 4: Load the lib in the harness**

In `AT/tests/run.lua`, at the top of the `Loader.loadAll` list — **before** `locales/enUS.lua`, so it
mirrors the TOC's load order:

```lua
  "libs/LibKa0s/Perf.lua",
  "libs/LibKa0s/PerfPanel.lua",
```

- [ ] **Step 5: Run the full gate**

```bash
cd /mnt/d/Profile/Users/Tushar/Documents/GIT/AbsorbTracker && lua tests/run.lua | tail -1 && luacheck .
```

Expected: the same pass count as before this task (the lib is loaded but nothing calls it), and
luacheck 0/0 — `libs/` is already excluded, so the vendored code is not linted here. It was linted
upstream.

- [ ] **Step 6: Commit** *(ask first)*

```bash
git add -A
git commit -m "chore(libs): vendor LibKa0s"
```

---

## Task 9: AbsorbTracker becomes consumer #1

The extraction proper. `core/Perf.lua` and `core/PerfPanel.lua` are deleted; a descriptor replaces
them. **An extraction that changes the measurements is a bug in the extraction** — the call sites in
`core/AbsorbTracker.lua`, `modules/Display.lua` and `modules/Timer.lua` are not touched at all, which
is the strongest available evidence that the hot path is unchanged.

**Files:**
- Create: `AT/core/PerfSetup.lua`
- Delete: `AT/core/Perf.lua`, `AT/core/PerfPanel.lua`
- Modify: `AT/AbsorbTracker.toc`, `AT/core/Bus.lua`, `AT/settings/Slash.lua`, `AT/.luacheckrc`,
  `AT/tests/run.lua`

**Interfaces:**
- Consumes: `LibStub("LibKa0s-Perf-1.0"):New(descriptor)`.
- Produces: `NS.Perf` — same field and function names the call sites already use (`on`, `suspended`,
  `Note`), plus the lib's surface. `NS.PerfPanel` **ceases to exist**; `NS.Perf.ShowPanel()` and
  friends replace it.

- [ ] **Step 1: Write the descriptor**

`AT/core/PerfSetup.lua`:

```lua
local addonName, NS = ...

-- core/PerfSetup.lua — wires the addon into LibKa0s-Perf (issue #17).
--
-- The probe itself lives in libs/LibKa0s/Perf.lua and is shared across every Ka0s addon; this file
-- is only the part that is ours: which hot paths get buckets, what "suspended" means here, and where
-- the output goes. See libs/LibKa0s/README-less note: the contract is documented in the LibKa0s
-- repo, docs/record-schema.md and the README's descriptor table.
--
-- The instance is created at LOAD TIME, before any module takes `local Perf = NS.Perf` as an
-- upvalue — this file sits immediately after core/Util.lua in the TOC for exactly that reason.

local lib = LibStub and LibStub("LibKa0s-Perf-1.0", true)
if not lib then
    -- A missing vendored lib must degrade, not error at load: the addon's own function is unaffected
    -- by the absence of a diagnostics harness. The stub carries just enough surface for the bracket
    -- idiom and the show-decision ladder to keep working.
    NS.Perf = { on = false, suspended = false, Note = function() end }
    return
end

NS.Perf = lib:New({
    name    = addonName,
    title   = "Absorb Tracker",
    slash   = "/at",
    version = NS.version,
    sv      = "AbsorbTrackerPerfDB",

    -- Ordered for the report, and the nesting is DECLARED rather than left as prose: repaintPass
    -- contains the three per-bar buckets, so their totals must never be summed as if disjoint.
    buckets = {
        { key = "absorbEvent" },                        -- addon:OnAbsorbChanged
        { key = "repaintPass" },                        -- doRepaint, one coalesced pass over every unit
        { key = "paintBar",    within = "repaintPass" },-- NS.UpdateAbsorbBar, per bar
        { key = "appearance",  within = "repaintPass" },-- NS.UpdateBarAppearance, per bar
        { key = "visibility",  within = "repaintPass" },-- NS.ApplyVisibility, per bar
    },

    --- Make the addon inert without a /reload.
    ---
    --- Visibility is NOT enforced by hiding frames here. NS.ShouldShowBar checks NS.Perf.suspended
    --- as step 0 of its ladder, so publishing VISIBILITY is enough and nothing — a combat
    --- transition, a target swap, a settings change — can re-show a bar behind suspend's back.
    suspend = function()
        local addon = NS.addon
        if addon then
            local frames = addon.__unitEventFrames
            if frames then
                for _, f in pairs(frames) do f:UnregisterAllEvents() end
            end
            if addon.UnregisterEvent then
                for _, event in ipairs({
                    "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
                    "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED",
                }) do
                    addon:UnregisterEvent(event)
                end
            end
        end
        if NS.CancelPendingRepaint then NS.CancelPendingRepaint() end
        if NS.bus then NS.bus:SendMessage(NS.MSG.VISIBILITY) end
    end,

    --- Restore everything suspend took away. SyncUnitEventFrames rebuilds the per-unit registrations
    --- from the CURRENT enabled set, so a unit toggled while suspended comes back correctly.
    resume = function()
        local addon = NS.addon
        if addon then
            if addon.RegisterLifecycleEvents then addon:RegisterLifecycleEvents() end
            if addon.SyncUnitEventFrames then addon:SyncUnitEventFrames() end
        end
        if NS.bus then
            NS.bus:SendMessage(NS.MSG.VISIBILITY)
            NS.bus:SendMessage(NS.MSG.APPEARANCE)
            NS.bus:SendMessage(NS.MSG.REPAINT)
        end
    end,

    -- Perf output is deliberately NOT gated on NS.State.debug, unlike NS.Debug. That gate keeps the
    -- addon free when idle, and a perf run is explicit user action — none of it executes unless
    -- someone typed `/at perf start`. Gating it meant a user who started a run without first
    -- enabling debug logging watched a console that stayed empty while a capture was plainly running.
    log = function(line)
        if NS.DebugLog and NS.DebugLog.Add then
            NS.DebugLog:Add("Perf", line)
        else
            NS.Print(line)
        end
    end,

    print = function(line) NS.Print(line) end,

    -- `start`, `report` and `dump` want the console in front of the user. Everything else must not
    -- pop it open — a lifecycle line mid-combat is the last moment to throw a window on screen.
    showLog = function()
        if NS.DebugLog and NS.DebugLog.Show and not NS.DebugLog:IsShown() then
            NS.DebugLog:Show()
        end
    end,

    -- Built by the debug console's own close-button factory rather than a lookalike, so the two
    -- windows cannot drift apart. Guarded only because a close button is worth degrading over,
    -- not erroring over.
    decorate = function(frame, api)
        if NS.DebugLog and NS.DebugLog.MakeCloseButton then
            local close = NS.DebugLog.MakeCloseButton(frame, api.Hide)
            close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -(api.TITLE_H - 18) / 2)
            frame.closeButton = close
        end
    end,
})
```

- [ ] **Step 2: Delete the two extracted files and repoint the TOC**

```bash
cd /mnt/d/Profile/Users/Tushar/Documents/GIT/AbsorbTracker
git rm core/Perf.lua core/PerfPanel.lua
```

In `AbsorbTracker.toc`, replace the two lines

```
core\Perf.lua
core\PerfPanel.lua
```

with

```
core\PerfSetup.lua
```

The position is load-bearing and unchanged: after `core/Util.lua`, before `core/Data.lua`, so
`modules/Display.lua` and `modules/Timer.lua` can take `local Perf = NS.Perf` as a load-time upvalue.

- [ ] **Step 3: Drop the now-subscriberless bus message**

In `AT/core/Bus.lua`, delete the `PERF` entry (line 60) and its documentation block (lines 32–34).
The panel lives in the lib and repaints itself directly — it owns the state it renders, so the bus
hop was never load-bearing, and a message with no subscriber is dead wiring.

- [ ] **Step 4: Reduce `runPerf` to an adapter**

In `AT/settings/Slash.lua`, delete `ensureConsole` (lines 256–260, now `showLog` in the descriptor),
`emitPerfLines` (262–271), `PERF_USAGE` (273–290), `PERF_SUBS` (297–383) and `printPerfStatus`
(386–401). Replace `runPerf` (403–408) with:

```lua
-- The whole guided run lives in LibKa0s-Perf; this is only the dispatch. The lib deliberately
-- registers no slash command of its own (slash-commands-§: every verb goes through this table with
-- the cyan tag), so it hands back lines and we print them.
function runPerf(rest)
    for _, line in ipairs(NS.Perf.OnCommand(rest or "")) do print(line) end
end
```

The `COMMANDS` entry at line 83 is unchanged. Check the `perf` help line in whatever help text
`COMMANDS` renders still reads correctly — the detailed usage now comes from `NS.Perf.Usage()`.

- [ ] **Step 5: Repoint the luacheck comments**

In `AT/.luacheckrc`, the three comments that name `core/Perf.lua` (lines 16, 30, and the stopwatch
block) now describe code that lives in `libs/LibKa0s/Perf.lua`. The `read_globals` entries for the
stopwatch and the context lookups are **no longer needed** — `libs/` is excluded from the lint — so
delete them along with `debugprofilestop`… **except** `debugprofilestop`, which the bracket call
sites in `core/AbsorbTracker.lua`, `modules/Display.lua` and `modules/Timer.lua` still use. Keep
`AbsorbTrackerPerfDB` in `globals`: `core/PerfSetup.lua` names it and the TOC declares it.

Verify by running luacheck; an unused `read_globals` entry is not an error, so removing them is a
tidiness step — if in doubt, keep and repoint the comment.

- [ ] **Step 6: Update the harness load list**

In `AT/tests/run.lua`, replace `"core/Perf.lua"` and `"core/PerfPanel.lua"` with
`"core/PerfSetup.lua"` in the same position.

- [ ] **Step 7: Run the gate and expect the perf suite to fail**

```bash
cd /mnt/d/Profile/Users/Tushar/Documents/GIT/AbsorbTracker && lua tests/run.lua | tail -5
```

Expected: every non-perf suite passes; `tests/test_perf.lua` fails extensively, because it tests the
implementation that just moved. Task 10 rewrites it. **Do not commit here** — the gate is red, and
Task 10 is what makes it green.

---

## Task 10: The AbsorbTracker integration suite

What stays in the addon is the smaller test the spec asks for: the descriptor is well-formed, every
declared bucket is actually reached, and Suspend truly makes *this* addon inert. The pure logic is
already covered upstream in `LibKa0s`, and duplicating it here would mean two places to fix a bug.

**Files:**
- Rewrite: `AT/tests/test_perf.lua`
- Modify: `AT/tests/perf.lua`, `AT/docs/test-cases.md`, `AT/README.md`

**Interfaces:**
- Consumes: `NS.Perf` from Task 9.

- [ ] **Step 1: Rewrite the suite**

`AT/tests/test_perf.lua`, replacing all 1,330 lines:

```lua
-- tests/test_perf.lua — this addon's side of the perf harness (issue #17).
--
-- The probe itself is LibKa0s-Perf and is tested in that repo: buckets, JSON, the record schema, the
-- report, the ring, the measurement windows and the panel all have suites there. Duplicating them
-- here would mean two places to fix one bug.
--
-- What is ours, and what this file covers: the descriptor is well-formed, every bucket we declare is
-- actually reached by a bracket, and Suspend genuinely makes THIS addon inert.

local T = _G.AT_TEST
local NS, mocks = T.NS, T.mocks
local test, assertEqual, assertTrue, assertFalse =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse

local P = NS.Perf

-- Drain the repaint queue. Resume() republishes REPAINT, which arms a coalescing timer; left armed,
-- `pending` in modules/Timer.lua stays set for the rest of the PROCESS and every later suite's
-- RequestRepaint quietly coalesces into a pass that never fires. That is invisible here and shows up
-- as unrelated failures three suites away, so every path that resumes drains first.
local function settle()
  NS.CancelPendingRepaint()
  for i = #mocks.__timers, 1, -1 do mocks.__timers[i] = nil end
end

local function resume()
  P.Resume()
  settle()
end

local function reset()
  P.on = false
  P.run = false
  P.armed, P.recording = nil, nil
  P.suspended = false
  P.label = nil
  P.Reset()
  settle()
  mocks.__profileMs = 0
  _G.AbsorbTrackerPerfDB = nil
end

-- ── the descriptor ──────────────────────────────────────────────────────────────────────────

test("perf: the addon holds a real LibKa0s-Perf instance", function()
  reset()
  assertTrue(type(P.Note) == "function", "Note")
  assertTrue(type(P.Start) == "function", "Start")
  assertTrue(type(P.OnCommand) == "function", "OnCommand")
  assertEqual(P.on, false, "the capture gate is a plain boolean field")
end)

test("perf: the descriptor declares this addon's buckets, with their nesting", function()
  reset()
  assertEqual(table.concat(P.BUCKET_ORDER, ","),
    "absorbEvent,repaintPass,paintBar,appearance,visibility", "order")
  assertEqual(P.BUCKET_WITHIN.paintBar, "repaintPass", "paintBar nests")
  assertEqual(P.BUCKET_WITHIN.appearance, "repaintPass", "appearance nests")
  assertEqual(P.BUCKET_WITHIN.visibility, "repaintPass", "visibility nests")
  assertEqual(P.BUCKET_WITHIN.repaintPass, nil, "the pass itself is top level")
end)

test("perf: records identify this addon and land in its own global", function()
  reset()
  P.Save(P.BuildRecord("cap"))
  assertEqual(_G.AbsorbTrackerPerfDB.runs[1].addon, "AbsorbTracker", "self-identifying")
  assertEqual(_G.AbsorbTrackerPerfDB.schema, 2, "schema 2")
end)

test("perf: the ring is outside the AceDB tree", function()
  reset()
  P.Save(P.BuildRecord("cap"))
  local profile = NS.db and NS.db.profile
  assertTrue(profile == nil or profile.perf == nil,
    "a perf ring inside a profile would ride copy, reset and switch")
end)
```

Then port, unchanged in intent, these tests from the current file (they are about *this addon* and
have no equivalent upstream):

- `brackets record nothing while capture is off` (AT:239)
- `paintBar records when capture is on` (AT:246)
- `paintBar does not count a bar that early-outed` (AT:256)
- `repaintPass records one note per coalesced pass` (AT:267)
- `suspend hides bars through the visibility ladder` (AT:281)
- `suspend unregisters every unit event frame` (AT:303)
- `suspend unregisters the lifecycle events` (AT:315)
- `resume restores the lifecycle set from one definition` (AT:324)
- `RequestRepaint no-ops while suspended` (AT:336)
- `CancelPendingRepaint drops a queued pass` (AT:346)
- `suspend leaves no repaint queued behind it` (AT:354)
- `the suspended state is session-only, never persisted` (AT:365)
- `lifecycle lines appear even with debug logging OFF` (AT:438)

Add the two that close the "every declared bucket is actually reached" gap, which nothing tests today:

```lua
test("perf: every declared bucket is reached by a real bracket", function()
  reset()
  P.on = true
  mocks.__absorbs.player = 1000
  mocks.__profileMs = 1
  NS.bus:SendMessage(NS.MSG.REPAINT)
  mocks.__fireTimers()
  if NS.addon and NS.addon.OnAbsorbChanged then
    NS.addon:OnAbsorbChanged("UNIT_ABSORB_AMOUNT_CHANGED", "player")
  end
  P.on = false
  local recorded = P.__buckets()
  for _, key in ipairs(P.BUCKET_ORDER) do
    assertTrue(recorded[key] ~= nil,
      "declared bucket '" .. key .. "' never fired — a bucket nobody reaches is a lie in the report")
  end
  settle()
end)

test("perf: the slash verb dispatches into the lib", function()
  reset()
  NS.Slash:OnSlash("perf start")
  assertTrue(P.run, "typed command reached the lib")
  P.Cancel()
  settle()
end)
```

If `every declared bucket is reached` cannot be made to fire all five from one repaint (for example
`absorbEvent` needing a different entry point), drive each bucket's real entry point explicitly
rather than weakening the assertion — the point of the test is that a declared bucket which no
bracket reaches is a lie in every report.

- [ ] **Step 2: Run the suite**

```bash
cd /mnt/d/Profile/Users/Tushar/Documents/GIT/AbsorbTracker && lua tests/run.lua | tail -3 && luacheck .
```

Expected: all pass, 0/0.

- [ ] **Step 3: Update the offline runner**

`AT/tests/perf.lua` — three edits:

1. Its load list (line 50) swaps `"core/Perf.lua", "core/PerfPanel.lua"` for `"core/PerfSetup.lua"`,
   with `"libs/LibKa0s/Perf.lua", "libs/LibKa0s/PerfPanel.lua"` added at the front.
2. Its record gains `addon = "AbsorbTracker"` so an offline record and an in-game one have the same
   shape, and `within` on the three nested buckets if it hand-builds the bucket table.
3. `NS.Perf.SCHEMA` (line 263) and `NS.Perf.EncodeJSON` (line 284) need no change — Task 2's
   constructor mirrors both onto the instance. Confirm that rather than assuming it.

Then verify the `probeOverhead` scenario still reports zero allocation with capture off:

```bash
cd /mnt/d/Profile/Users/Tushar/Documents/GIT/AbsorbTracker && lua tests/perf.lua
```

Expected: runs clean, and `probeOverhead` shows the same bytes-allocated figure as before the
extraction. **This is the offline half of the parity check** — if it moved, the bracket idiom
changed, which it must not have.

- [ ] **Step 4: Regenerate the test-case docs and the badge**

```bash
cd /mnt/d/Profile/Users/Tushar/Documents/GIT/AbsorbTracker
lua tests/run.lua --list > docs/test-cases.md
grep -n "tests" README.md | head -5
```

Update the README `tests` badge count to the new total from `docs/test-cases.md`'s `**Total**` row,
in the same change (CLAUDE.md requires this).

- [ ] **Step 5: Commit Tasks 9 and 10 together** *(ask first)*

They are one atomic change — Task 9 alone leaves the tree red.

```bash
git add -A
git commit -m "refactor(perf): adopt LibKa0s-Perf, deleting the addon-local probe"
```

---

## Task 11: AbsorbTracker documentation

**Files:**
- Modify: `AT/docs/ARCHITECTURE.md`, `AT/docs/performance.md`, `AT/docs/file-index.md`,
  `AT/docs/module-map.md`, `AT/docs/data-flow.md`, `AT/docs/perf-runs/README.md`,
  `AT/docs/complexity.md`, `AT/CLAUDE.md`, `AT/docs/agent-context.md`, `AT/README.md`

**Interfaces:** none — documentation only.

- [ ] **Step 1: Find every stale reference**

```bash
cd /mnt/d/Profile/Users/Tushar/Documents/GIT/AbsorbTracker
grep -rn "core/Perf\.lua\|core/PerfPanel\.lua\|NS\.PerfPanel\|MSG\.PERF\|PerfStateChanged" docs README.md CLAUDE.md
```

Every hit is a thing this task fixes. Work the list top to bottom.

- [ ] **Step 2: Rewrite the module documentation**

- `docs/ARCHITECTURE.md` — the module map loses two entries and gains `core/PerfSetup.lua`; the
  message-bus section loses `PERF`; add a short subsection saying the harness is now
  `LibKa0s-Perf-1.0`, vendored in `libs/`, and that the addon supplies a descriptor.
- `docs/module-map.md` and `docs/file-index.md` — same swap, with the line counts updated
  (`core/PerfSetup.lua` is ~90 lines against the 948 that left).
- `docs/data-flow.md` — the PERF message's flow is deleted; say instead that the panel repaints
  itself off the instance state.
- `docs/performance.md` — the biggest edit. Keep the whole protocol section (it is still true and
  still ours to explain); repoint every implementation reference at the lib; add a paragraph on the
  descriptor and where the contract is documented (the LibKa0s README).
- `docs/perf-runs/README.md` — schema v2, `addon` and `within`, and a line saying the committed
  `2026-07-29-offline-baseline.json` is a schema-1 capture kept as history, not re-read by the addon.
- `docs/complexity.md` — regenerate if `lizard` is available (`lizard --exclude "libs/*"`), otherwise
  hand-adjust the two deleted files out of the table and note the regeneration is pending.
- `CLAUDE.md` and `docs/agent-context.md` — anywhere the perf probe is described as living in `core/`.

- [ ] **Step 3: Note the standard deviations that are now pending promotion**

The spec promotes AbsorbTracker's three recorded deviations into WowAddonStandards v2.12.0, which is
rollout step 3 and **not in this plan**. In `docs/audits/`'s most recent bundle (or the deviations
list wherever it currently lives), add a line to each of the three noting that promotion is pending
and naming the spec. Do not edit any dated audit's findings themselves — a dated bundle is frozen
history.

- [ ] **Step 4: Verify and commit** *(ask first)*

```bash
cd /mnt/d/Profile/Users/Tushar/Documents/GIT/AbsorbTracker
grep -rn "core/Perf\.lua\|core/PerfPanel\.lua\|NS\.PerfPanel\|MSG\.PERF" docs README.md CLAUDE.md
lua tests/run.lua | tail -1 && luacheck .
git add -A
git commit -m "docs: repoint the perf documentation at LibKa0s"
```

The grep must come back empty except for historical documents (dated audits, investigations, the
changelog) where the reference is a true statement about the past.

---

## Task 12: The in-game parity capture

The spec's step 2 gate: *an extraction that changes the measurements is a bug in the extraction.*
This task is manual and belongs to the user — it needs a live client.

**Files:** `AT/docs/perf-runs/` gains one new capture.

- [ ] **Step 1: Copy the addon to the client and reload**

Both `AbsorbTracker/` and its `libs/LibKa0s/` must be in place. `/reload`.

- [ ] **Step 2: Run the guided capture against the same target as the pre-extraction runs**

`/at perf` opens the panel; walk the rows: Start → Measure A → pull → Measure B → pull → Finish →
Report → Dump. Use a label that says it is the post-extraction run, e.g.
`/at perf start post-extraction dummy`.

- [ ] **Step 3: Diff against the pre-extraction numbers**

Compare against the four captures written up in
`AT/docs/investigations/2026-07-29-combat-fps-drop/raw-captures.md`. What must match, within the
noise of two different fights:

- `deltaMsPerFrame` — the headline. A materially different figure means the extraction changed what
  is being measured.
- the bucket call counts per active second — these are structural, not timing, and should be very
  close.
- the presence of all five buckets.

What is *expected* to differ: `schema` (1 → 2), the new `addon` field, `within` on the three nested
buckets, and the report's indentation.

- [ ] **Step 4: Record the result**

Save the JSON into `AT/docs/perf-runs/<date>-post-extraction.json` and add a short section to
`docs/investigations/2026-07-29-combat-fps-drop/analysis.md` — or a new dated note — stating that the
extraction was verified against the pre-extraction numbers, with both figures side by side.

If the numbers moved: **stop and investigate before proceeding to rollout step 3.** The likely
suspects, in order — a bracket call site accidentally edited, the sampler frame being created
somewhere other than inside `:New()`, or `Perf.on` no longer being a direct field read.

- [ ] **Step 5: Commit the capture** *(ask first)*

```bash
git add docs/perf-runs docs/investigations
git commit -m "docs(perf): the post-extraction parity capture"
```

---

## What this plan deliberately does not do

Rollout steps 3–6 from the spec, each gated on this one finishing:

3. **WowAddonStandards v2.12.0** — the new `standards/standards/performance.md` section plus the nine
   cross-section edits. Writing the normative section from a design rather than from a working
   extraction is how a standard acquires rules that do not survive their second implementation.
4. **`NEW_ADDON.md` / `NEW_ADDON_CONTEXT.md`**, so new addons are born with the harness.
5. **The other five addons**, KickCD first — the most structurally complex, and so the one most
   likely to expose a descriptor assumption that only held for AbsorbTracker.
6. **CurseForge publication**, last, once six independent consumers have pressure-tested the API.
