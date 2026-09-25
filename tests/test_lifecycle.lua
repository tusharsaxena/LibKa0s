-- tests/test_lifecycle.lua — the stand-down latch's hard invariants, one case each.
--
-- Every case here is a negative assertion wearing a positive one's clothes: what is actually under
-- test is that a callback did NOT run. `standDown` twice tears down an addon that is already torn
-- down; `standUp` once too often resurrects an addon a player switched off. Both are silent in the
-- client — the addon looks fine and costs what it always cost — so the suite is the only place
-- either can be seen.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertError =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertError

local LC = T.lifecycle

--- A latch plus a recorder of the edges it fired, in order: "down", "up", "down", …
---
--- The order matters as much as the count, and a bare pair of counters cannot show it: a latch that
--- fired up-then-down where it should have fired down-then-up has the right totals and the wrong
--- behavior, and the host is left rebuilt-then-torn-down with nothing registered.
local function newLatch(overrides)
  local rec = { edges = {}, chat = {} }
  local d = {
    name      = "TestHost",
    standDown = function(...) rec.edges[#rec.edges + 1] = "down"; rec.downArgs = select("#", ...) end,
    standUp   = function(...) rec.edges[#rec.edges + 1] = "up";   rec.upArgs   = select("#", ...) end,
    print     = function(line) rec.chat[#rec.chat + 1] = line end,
  }
  for k, v in pairs(overrides or {}) do d[k] = v end
  return LC:New(d), rec
end

local function edges(rec) return table.concat(rec.edges, ",") end

--- `fn` raises, and the raised text names `needle`. assertError alone only proves SOMETHING was
--- raised, which a typo in the call under test satisfies just as well as the guard being tested.
local function assertRaises(fn, needle)
  local err = assertError(fn, "expected a raise naming '" .. needle .. "'")
  assertTrue(err:find(needle, 1, true) ~= nil, "raised: " .. err .. " (wanted '" .. needle .. "')")
end

-- ── the descriptor ─────────────────────────────────────────────────────────────

test("lifecycle: the major is registered and floors on Core", function()
  assertTrue(LC ~= nil, "LibKa0s-Lifecycle-1.0 registered")
  assertEqual(LC.MAJOR, "LibKa0s-Lifecycle-1.0")
  assertEqual(LC.MODULES.Lifecycle, LC.MINOR, "the file reports its own live version")
end)

test("lifecycle: the reserved hold keys are exported rather than spelled per host", function()
  -- Two majors and eleven hosts have to agree on these two strings. Exported, there is one
  -- spelling; typed at each call site there are fourteen, and the day one of them reads "Perf" the
  -- perf arm holds a key nothing releases.
  assertEqual(LC.HOLD_DISABLED, "disabled")
  assertEqual(LC.HOLD_PERF, "perf")
end)

test("lifecycle: New refuses a descriptor missing any required field", function()
  assertRaises(function() LC:New(nil) end, "descriptor.name")
  assertRaises(function() LC:New{ name = "X" } end, "descriptor.standDown")
  assertRaises(function() LC:New{ name = "X", standDown = function() end } end, "descriptor.standUp")
end)

test("lifecycle: a fresh latch is up, holds nothing, and has fired nothing", function()
  local lc, rec = newLatch()
  assertFalse(lc:IsDown(), "a fresh latch is up")
  assertEqual(#lc:Holds(), 0)
  assertEqual(edges(rec), "", "New fires no edge — construction is not a transition")
end)

-- ── the edges ──────────────────────────────────────────────────────────────────

test("lifecycle: the first hold stands down, and the callbacks take no arguments", function()
  local lc, rec = newLatch()
  assertTrue(lc:Hold("disabled"), "the call that stood the addon down says so")
  assertEqual(edges(rec), "down")
  assertTrue(lc:IsDown())
  assertTrue(lc:IsHeld("disabled"))
  -- The contract is "called with no arguments". A host that started reading a first argument would
  -- be reading whatever a later minor happened to pass, which is how an additive change becomes a
  -- breaking one.
  assertEqual(rec.downArgs, 0)
end)

test("lifecycle: holding a key already held is a no-op and does NOT stand down again", function()
  -- red under: drop the `if holds[key] then return false end` guard in Hold
  local lc, rec = newLatch()
  lc:Hold("disabled")
  assertFalse(lc:Hold("disabled"), "the second hold changed nothing")
  assertEqual(edges(rec), "down", "standDown ran once, not twice")
  assertEqual(#lc:Holds(), 1, "the set did not grow")
end)

test("lifecycle: releasing a key that is not held is a no-op and does NOT stand up", function()
  -- red under: drop the `if not holds[key] then return false end` guard in Release
  --
  -- This is the bare stand-up the whole major exists to prevent, arriving through the front door:
  -- a teardown path that releases a hold it never took would rebuild an addon nobody stood down.
  local lc, rec = newLatch()
  assertFalse(lc:Release("perf"), "releasing an untaken key changed nothing")
  assertEqual(edges(rec), "", "standUp never ran")
  assertFalse(lc:IsDown())
end)

test("lifecycle: Hold(a); Hold(b); Release(a) stands down ONCE and never stands up", function()
  -- red under: make Release fire standUp whenever it removes a key, rather than on the edge
  --
  -- The four-state case a boolean cannot hold. `b` is still taken, so the addon is still down, and
  -- an addon a player disabled must not come back because a perf run ended.
  local lc, rec = newLatch()
  lc:Hold("a")
  lc:Hold("b")
  lc:Release("a")
  assertEqual(edges(rec), "down")
  assertTrue(lc:IsDown(), "still down — b is still held")
  assertEqual(table.concat(lc:Holds(), ","), "b")
end)

test("lifecycle: Hold; Release; Hold fires down, up, down — in that order, once each", function()
  local lc, rec = newLatch()
  lc:Hold("a"); lc:Release("a"); lc:Hold("a")
  assertEqual(edges(rec), "down,up,down")
end)

test("lifecycle: hold order is irrelevant to the edge count, in both directions", function()
  local lc1, rec1 = newLatch()
  lc1:Hold("a"); lc1:Hold("b"); lc1:Release("b"); lc1:Release("a")
  assertEqual(edges(rec1), "down,up", "a,b then b,a")

  local lc2, rec2 = newLatch()
  lc2:Hold("b"); lc2:Hold("a"); lc2:Release("a"); lc2:Release("b")
  assertEqual(edges(rec2), "down,up", "b,a then a,b")
end)

test("lifecycle: the perf hold released under a live disabled hold leaves the addon down", function()
  -- The exact sequence performance-§6's "resume before saving or reporting" produces on an addon
  -- the player has switched off mid-run: the perf arm releases its own hold and nothing else, and
  -- `disabled` is what keeps the addon inert.
  local lc, rec = newLatch()
  lc:Hold(LC.HOLD_PERF)
  lc:Hold(LC.HOLD_DISABLED)
  assertFalse(lc:Release(LC.HOLD_PERF), "the release was not an edge")
  assertEqual(edges(rec), "down")
  assertTrue(lc:IsDown())
  assertTrue(lc:Release(LC.HOLD_DISABLED), "the last hold out is the edge")
  assertEqual(edges(rec), "down,up")
end)

-- ── Set, the shape a settings onChange actually has ────────────────────────────

test("lifecycle: Set(key, truthy) holds and Set(key, falsy) releases", function()
  local lc, rec = newLatch()
  lc:Set("disabled", true)
  assertEqual(edges(rec), "down")
  lc:Set("disabled", false)
  assertEqual(edges(rec), "down,up")
  -- nil is falsy and must release rather than raise: an onChange handed a stored value that was
  -- never written reads nil, and a latch that raised there would break the panel rather than the
  -- setting.
  lc:Set("disabled", true)
  lc:Set("disabled", nil)
  assertEqual(edges(rec), "down,up,down,up")
end)

test("lifecycle: Set is idempotent in both directions", function()
  local lc, rec = newLatch()
  lc:Set("disabled", true); lc:Set("disabled", true)
  lc:Set("disabled", false); lc:Set("disabled", false)
  assertEqual(edges(rec), "down,up")
end)

-- ── Reevaluate ─────────────────────────────────────────────────────────────────

test("lifecycle: Reevaluate fires nothing when the set has not crossed", function()
  -- red under: make Reevaluate call standDown/standUp unconditionally
  --
  -- A host calls this after every profile switch. Firing on a non-edge would tear an addon down
  -- and rebuild it every time the player changed profiles, which is a visible flicker and a
  -- pointless re-registration of everything it owns.
  local lc, rec = newLatch()
  lc:Reevaluate()
  assertEqual(edges(rec), "", "up, and it stayed up")
  lc:Hold("disabled")
  lc:Reevaluate(); lc:Reevaluate()
  assertEqual(edges(rec), "down", "down, and it stayed down")
end)

-- ── the reporting surface ──────────────────────────────────────────────────────

test("lifecycle: Holds answers a FRESH sorted array, not the internal table", function()
  local lc = newLatch()
  lc:Hold("perf"); lc:Hold("disabled"); lc:Hold("combat")
  assertEqual(table.concat(lc:Holds(), ","), "combat,disabled,perf", "sorted, so a suite can assert on it")
  local first = lc:Holds()
  first[#first + 1] = "injected"
  assertEqual(table.concat(lc:Holds(), ","), "combat,disabled,perf",
    "mutating the answer did not mutate the hold set")
  assertTrue(lc:Holds() ~= lc:Holds(), "a fresh table every call")
end)

test("lifecycle: the library prints nothing unless a line is asked for", function()
  local lc, rec = newLatch()
  lc:Hold("disabled"); lc:Release("disabled")
  assertEqual(#rec.chat, 0, "an edge is not an announcement")
  lc:PrintHolds()
  assertEqual(#rec.chat, 1)
  assertTrue(rec.chat[1]:find("(none)", 1, true) ~= nil, "up, with no holds")
  lc:Hold("perf")
  lc:PrintHolds()
  assertTrue(rec.chat[2]:find("perf", 1, true) ~= nil)
end)

test("lifecycle: PrintHolds with no host printer answers false rather than raising", function()
  local lc = LC:New{ name = "X", standDown = function() end, standUp = function() end }
  assertFalse(lc:PrintHolds())
end)

-- ── the invariants that are about failure ──────────────────────────────────────

test("lifecycle: a raising standUp still leaves the hold set empty and the latch up", function()
  -- red under: move the `down = wanted` assignment to AFTER the callback call in edge()
  --
  -- The set is mutated and the edge recorded BEFORE the host callback runs, so an error inside the
  -- host cannot strand the latch in a state where the addon is neither down nor up. Update-after
  -- would leave the latch believing the addon was still down over an empty hold set: the next
  -- Hold fires no standDown, and the addon is half-alive with no hold left to release.
  local lc = LC:New{
    name = "X",
    standDown = function() end,
    standUp = function() error("host blew up rebuilding") end,
  }
  lc:Hold("disabled")
  local ok = pcall(function() lc:Release("disabled") end)
  assertFalse(ok, "the host's error reaches the host, unswallowed")
  assertEqual(#lc:Holds(), 0, "the set is empty")
  assertFalse(lc:IsDown(), "and the latch agrees the addon is up")
end)

test("lifecycle: a raising standDown leaves the hold taken, so the release path still works", function()
  local lc = LC:New{
    name = "X",
    standDown = function() error("host blew up tearing down") end,
    standUp = function() end,
  }
  local ok = pcall(function() lc:Hold("disabled") end)
  assertFalse(ok)
  assertTrue(lc:IsHeld("disabled"), "the hold is taken — a half-completed teardown is still down")
  assertTrue(lc:IsDown())
  assertTrue(lc:Release("disabled"), "and releasing it is an edge, so the host can rebuild")
end)

-- ── re-entrancy ────────────────────────────────────────────────────────────────

test("lifecycle: a standDown that releases a hold fires standUp nested, and the latch ends up", function()
  -- A characterization, not a feature: New's docstring says a callback MUST NOT take or release a
  -- hold. This pins what happens when one does anyway, so the behavior cannot change unannounced.
  -- The nested edge runs to completion inside the outer one — "up" lands between standDown's entry
  -- and its exit — and because `down` is recorded before each callback the latch is consistent
  -- afterwards: the set is empty and IsDown() agrees.
  local trace, lc = {}, nil
  lc = LC:New{
    name = "X",
    standDown = function()
      trace[#trace + 1] = "down:enter"
      -- Called first and stored: `trace[#trace + 1] = lc:Release(...)` would take the index
      -- before the nested standUp appends, and overwrite its entry.
      local edged = lc:Release("disabled")
      trace[#trace + 1] = edged and "release:edge" or "release:no-edge"
      trace[#trace + 1] = "down:exit"
    end,
    standUp = function() trace[#trace + 1] = "up" end,
  }
  assertTrue(lc:Hold("disabled"), "the outer Hold still answers that it stood the addon down")
  assertEqual(table.concat(trace, ","), "down:enter,up,release:edge,down:exit",
    "standUp fires nested, before standDown returns")
  assertFalse(lc:IsDown(), "the latch ends up")
  assertFalse(lc:IsHeld("disabled"))
  assertEqual(#lc:Holds(), 0, "the set is empty")
end)

test("lifecycle: Hold and Release refuse a key that is not a non-empty string", function()
  local lc = newLatch()
  assertRaises(function() lc:Hold(nil) end, "string key")
  assertRaises(function() lc:Hold("") end, "string key")
  assertRaises(function() lc:Release(42) end, "string key")
end)

test("lifecycle: two latches share nothing", function()
  local a, recA = newLatch()
  local b, recB = newLatch()
  a:Hold("disabled")
  assertFalse(b:IsDown(), "one addon standing down does not stand another one down")
  assertEqual(edges(recA), "down")
  assertEqual(edges(recB), "")
end)
