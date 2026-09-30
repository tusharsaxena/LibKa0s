-- tests/test_lifecycle_debug.lua — LibKa0s-Lifecycle-1.0's edges reaching the host's debug sink
-- (Lifecycle minor 3, gap G5 of the 2026-09-30 LibKa0s debug-gaps run).
--
-- The descriptor takes `debug(tag, message)`, exactly as LibKa0s-Launcher-1.0's and
-- LibKa0s-Slash-1.0's do. Each stand-down and each stand-up edge writes ONE `Lifecycle` line naming
-- the hold that caused it and the resulting set; a call that fires no edge writes nothing. Absent
-- `debug`, the module stays silent, and the chat (PrintHolds) is what it was at minor 2 either way.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse

local LC = T.lifecycle

--- A latch whose `debug` records `tag|message` and whose callbacks record their edge into the same
--- list, so a case can assert the line lands before the host's teardown or rebuild runs.
local function newLatch(overrides)
  local rec = { logs = {}, chat = {} }
  local d = {
    name      = "TestHost",
    standDown = function() rec.logs[#rec.logs + 1] = "<down>" end,
    standUp   = function() rec.logs[#rec.logs + 1] = "<up>" end,
    print     = function(line) rec.chat[#rec.chat + 1] = line end,
    debug     = function(tag, message) rec.logs[#rec.logs + 1] = tostring(tag) .. "|" .. tostring(message) end,
  }
  for k, v in pairs(overrides or {}) do d[k] = v end
  return LC:New(d), rec
end

local function logs(rec) return table.concat(rec.logs, " || ") end

-- ── the version ────────────────────────────────────────────────────────────────────────────

test("lc debug: Lifecycle is at minor 3", function()
  assertEqual(LC.MINOR, 3)
  assertEqual(LC.MODULES.Lifecycle, 3)
end)

-- ── the edges ──────────────────────────────────────────────────────────────────────────────

test("lc debug: the first hold writes one stand-down line with the hold and the set, before standDown", function()
  local lc, rec = newLatch()
  lc:Hold("disabled")
  assertEqual(logs(rec), "Lifecycle|stood down: added disabled (holds: disabled) || <down>")
end)

test("lc debug: the last release writes one stand-up line with the empty set, before standUp", function()
  local lc, rec = newLatch()
  lc:Hold("perf")
  rec.logs = {}
  lc:Release("perf")
  assertEqual(logs(rec), "Lifecycle|stood up: released perf (holds: none) || <up>")
end)

test("lc debug: Set routes to the same lines as Hold and Release", function()
  local lc, rec = newLatch()
  lc:Set("disabled", true)
  lc:Set("disabled", false)
  assertEqual(logs(rec), "Lifecycle|stood down: added disabled (holds: disabled) || <down> || "
    .. "Lifecycle|stood up: released disabled (holds: none) || <up>")
end)

test("lc debug: a full down-up-down cycle writes one line per edge, in order", function()
  local lc, rec = newLatch()
  lc:Hold("perf"); lc:Release("perf"); lc:Hold("disabled")
  assertEqual(logs(rec), "Lifecycle|stood down: added perf (holds: perf) || <down> || "
    .. "Lifecycle|stood up: released perf (holds: none) || <up> || "
    .. "Lifecycle|stood down: added disabled (holds: disabled) || <down>")
end)

-- ── no edge, no line ───────────────────────────────────────────────────────────────────────

test("lc debug: a second hold while down fires no edge and writes no line", function()
  local lc, rec = newLatch()
  lc:Hold("disabled")
  rec.logs = {}
  assertFalse(lc:Hold("perf"))
  assertEqual(logs(rec), "", "a hold that changes the set but not the edge is not narrated")
end)

test("lc debug: releasing one of two holds fires no edge and writes no line", function()
  local lc, rec = newLatch()
  lc:Hold("disabled"); lc:Hold("perf")
  rec.logs = {}
  assertFalse(lc:Release("perf"))
  assertEqual(logs(rec), "", "the addon is still down; nothing crossed")
  assertTrue(lc:IsDown())
end)

test("lc debug: no-op calls write nothing (re-hold, release unheld, Reevaluate, PrintHolds)", function()
  local lc, rec = newLatch()
  lc:Release("disabled")          -- never held
  lc:Reevaluate()                 -- up and empty: no edge
  lc:Hold("disabled")
  rec.logs = {}
  lc:Hold("disabled")             -- already held
  lc:Reevaluate()                 -- down and non-empty: no edge
  lc:PrintHolds()
  assertEqual(logs(rec), "", "a call that changes nothing writes nothing")
end)

test("lc debug: a raising standDown still leaves its line in the log", function()
  -- The line is written after the edge is recorded and before the callback, so the host's error
  -- reaches its handler with the edge that caused it already in the log.
  local lc, rec = newLatch{ standDown = function() error("teardown boom") end }
  assertTrue(not pcall(lc.Hold, lc, "disabled"), "the host's raise propagates")
  assertEqual(logs(rec), "Lifecycle|stood down: added disabled (holds: disabled)")
end)

test("lc debug: a nested edge from inside standDown logs in the order the edges ran", function()
  local lc
  local rec
  lc, rec = newLatch{ standDown = function() rec.logs[#rec.logs + 1] = "<down>"; lc:Release("x") end }
  lc:Hold("x")
  assertEqual(logs(rec), "Lifecycle|stood down: added x (holds: x) || <down> || "
    .. "Lifecycle|stood up: released x (holds: none) || <up>")
end)

-- ── the sink is optional and cannot break the latch ───────────────────────────────────────

test("lc debug: no debug in the descriptor stays silent and the edges still fire", function()
  local fired = {}
  local lc = LC:New{
    name = "Quiet",
    standDown = function() fired[#fired + 1] = "down" end,
    standUp   = function() fired[#fired + 1] = "up" end,
  }
  lc:Hold("disabled"); lc:Release("disabled")
  assertEqual(table.concat(fired, ","), "down,up")
end)

test("lc debug: a non-function debug field is ignored, not called", function()
  local lc, rec = newLatch{ debug = "not a function" }
  lc:Hold("disabled")
  assertEqual(logs(rec), "<down>")
end)

test("lc debug: a sink that raises does not strand the latch half down", function()
  local lc, rec = newLatch{ debug = function() error("sink boom") end }
  lc:Hold("disabled")
  assertEqual(logs(rec), "<down>", "standDown still ran")
  assertTrue(lc:IsDown())
  lc:Release("disabled")
  assertEqual(logs(rec), "<down> || <up>", "and standUp on the way back")
  assertFalse(lc:IsDown())
end)

test("lc debug: PrintHolds' chat line is unchanged by the sink", function()
  local lc, rec = newLatch()
  lc:PrintHolds()
  lc:Hold("disabled"); lc:Hold("perf")
  lc:PrintHolds()
  assertEqual(rec.chat[1], "up, no holds: (none)")
  assertEqual(rec.chat[2], "stood down, holds: disabled, perf")
end)
