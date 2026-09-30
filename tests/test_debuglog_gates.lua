-- tests/test_debuglog_gates.lua — LibKa0s-DebugLog-1.0's change gates (DebugLogGates.lua,
-- minor 1) and the shell's `onClear` descriptor hook (DebugLog minor 18). Gap G2 of the
-- 2026-09-30 debug-gaps run: five hosts hand-rolled a "log once" or "log on change" helper, and
-- none of them was re-armed by the console's Clear, because Clear offered the host no hook.
--
-- What is pinned here: the silent default (no `onClear`, logging off), the two gates' semantics,
-- their re-arming by Clear and by turning logging on, the per-key forget, the bound, and that the
-- line is built only when logging is on.

local T = _G.LK_TEST
local debuglog = T.debuglog
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse

-- The same stand-in for a combat secret tests/test_debuglog.lua uses.
local secretMock = setmetatable({}, { __concat = function() return "secret-propagated" end })

local function newLog(overrides)
  local rec = { enabled = true, clears = 0, chat = {} }
  local d = {
    name       = "GateTest",
    title      = "Gate Test",
    font       = "Interface\\Fonts\\FRIZQT__.TTF",
    isEnabled  = function() return rec.enabled end,
    setEnabled = function(v) rec.enabled = v end,
    print      = function(line) rec.chat[#rec.chat + 1] = line end,
  }
  for k, v in pairs(overrides or {}) do d[k] = v end
  return debuglog:New(d), rec
end

--- How many buffer lines carry `needle`.
local function count(D, needle)
  local n = 0
  for _, line in ipairs(D.buffer) do
    if line:find(needle, 1, true) then n = n + 1 end
  end
  return n
end

--- A value whose every stringification is counted, to prove a line was never built.
local function counted()
  local box = { n = 0 }
  box.v = setmetatable({}, { __tostring = function() box.n = box.n + 1; return "counted" end })
  return box
end

-- ── registration ─────────────────────────────────────────────────────────────────────────

test("gates: the file registers under the major, paired on the live shell, with its bound pinned", function()
  assertEqual(debuglog.MINOR, 18)
  assertEqual(debuglog.MODULES.DebugLog, 18)
  assertEqual(debuglog.MODULES.DebugLogGates, 1)
  assertEqual(debuglog.__gatesShellMinor, debuglog.MINOR, "paired on the live shell")
  assertEqual(debuglog.GATE_MAX_KEYS, 256, "the literal the api document cites")
  local D = newLog()
  for _, name in ipairs({ "DebugOnce", "DebugChanged", "DebugForget" }) do
    assertEqual(type(D[name]), "function", name .. " is on the instance")
  end
end)

-- ── the onClear hook ─────────────────────────────────────────────────────────────────────

test("onClear: absent, Clear empties the buffer and writes nothing (the silent default)", function()
  local D = newLog()
  D.Debug("T", "one"); D.Debug("T", "two")
  local ok = pcall(function() D:Clear() end)
  assertTrue(ok, "Clear with no hook does not raise")
  assertEqual(D:BufferSize(), 0, "nothing written after the wipe")
end)

test("onClear: a non-function field is ignored, as every optional descriptor field is", function()
  local D = newLog({ onClear = "not a function" })
  D.Debug("T", "one")
  D:Clear()
  assertEqual(D:BufferSize(), 0)
end)

test("onClear: called once per Clear, after the buffer is empty, and its own line lands", function()
  local D
  local seen = {}
  D = newLog({ onClear = function()
    seen[#seen + 1] = D:BufferSize()
    D.Debug("Host", "re-armed")
  end })
  D.Debug("T", "before")
  D:Clear()
  assertEqual(#seen, 1, "once")
  assertEqual(seen[1], 0, "the hook runs after the wipe")
  assertEqual(D:BufferSize(), 1, "only the hook's line")
  assertEqual(count(D, "[Host] re-armed"), 1)
  D:Clear()
  assertEqual(#seen, 2, "and again on the next Clear")
end)

test("onClear: a raising hook costs one line, not the Clear", function()
  local D = newLog({ onClear = function() error("boom") end })
  D.Debug("T", "before")
  local ok = pcall(function() D:Clear() end)
  assertTrue(ok, "Clear does not raise")
  assertEqual(count(D, "before"), 0, "the buffer was still wiped")
  assertEqual(D:BufferSize(), 1, "one line")
  assertEqual(count(D, "onClear raised"), 1, "naming the hook")
  assertEqual(count(D, "boom"), 1, "and carrying the error")
end)

test("onClear: not called by turning logging on or off", function()
  local calls = 0
  local D = newLog({ onClear = function() calls = calls + 1 end })
  D:SetEnabled(false); D:SetEnabled(true)
  assertEqual(calls, 0)
end)

-- ── DebugOnce ────────────────────────────────────────────────────────────────────────────

test("DebugOnce: the first call per key writes, formatted as D.Debug formats, and the rest do not", function()
  local D = newLog()
  assertTrue(D.DebugOnce("k", "Tag", "hello %s %d", "world", 3), "written: true")
  assertFalse(D.DebugOnce("k", "Tag", "hello %s %d", "again", 4), "held: false")
  assertEqual(count(D, "[Tag] hello world 3"), 1)
  assertEqual(count(D, "again"), 0)
  assertTrue(D.DebugOnce("k2", "Tag", "other"), "a second key is its own")
  assertEqual(count(D, "[Tag] other"), 1)
end)

test("DebugOnce: logging off writes nothing, remembers nothing and builds nothing", function()
  local D, rec = newLog()
  rec.enabled = false
  local box = counted()
  assertFalse(D.DebugOnce("k", "Tag", "v=%s", box.v))
  assertEqual(box.n, 0, "the argument was never stringified")
  assertEqual(D:BufferSize(), 0)
  rec.enabled = true
  assertTrue(D.DebugOnce("k", "Tag", "v=%s", "now"), "the key was not spent while off")
end)

test("DebugOnce: Clear re-arms every key", function()
  local D = newLog()
  D.DebugOnce("k", "Tag", "line")
  D:Clear()
  assertTrue(D.DebugOnce("k", "Tag", "line"), "speaks again after Clear")
  assertEqual(D:BufferSize(), 1)
end)

test("DebugOnce: turning logging on re-arms every key", function()
  local D = newLog()
  D.DebugOnce("k", "Tag", "line")
  D:SetEnabled(false)
  D:SetEnabled(true)
  assertTrue(D.DebugOnce("k", "Tag", "line"), "a new session hears it again")
  assertEqual(count(D, "[Tag] line"), 2)
end)

-- ── DebugChanged ─────────────────────────────────────────────────────────────────────────

test("DebugChanged: writes the first line, holds a repeat, and writes a change", function()
  local D = newLog()
  assertTrue(D.DebugChanged("w1", "Render", "rows=%d", 3))
  assertFalse(D.DebugChanged("w1", "Render", "rows=%d", 3), "same line: held")
  assertTrue(D.DebugChanged("w1", "Render", "rows=%d", 4), "changed: written")
  assertTrue(D.DebugChanged("w1", "Render", "rows=%d", 3), "back to the old value is a change too")
  assertEqual(count(D, "[Render] rows=3"), 2)
  assertEqual(count(D, "[Render] rows=4"), 1)
end)

test("DebugChanged: keys are independent, and a new tag is a change", function()
  local D = newLog()
  D.DebugChanged("w1", "Render", "rows=%d", 3)
  assertTrue(D.DebugChanged("w2", "Render", "rows=%d", 3), "another key's first line")
  assertTrue(D.DebugChanged("w1", "Layout", "rows=%d", 3), "same text, other tag")
  assertEqual(D:BufferSize(), 3)
end)

test("DebugChanged: logging off writes nothing, remembers nothing and builds nothing", function()
  local D, rec = newLog()
  D.DebugChanged("w1", "Render", "rows=%d", 3)
  rec.enabled = false
  local box = counted()
  assertFalse(D.DebugChanged("w1", "Render", "v=%s", box.v))
  assertEqual(box.n, 0, "never stringified")
  rec.enabled = true
  assertFalse(D.DebugChanged("w1", "Render", "rows=%d", 3), "the memory is the last line written")
end)

test("DebugChanged: Clear and turning logging on both re-arm it", function()
  local D = newLog()
  D.DebugChanged("w1", "Render", "rows=%d", 3)
  D:Clear()
  assertTrue(D.DebugChanged("w1", "Render", "rows=%d", 3), "after Clear")
  D:SetEnabled(false); D:SetEnabled(true)
  assertTrue(D.DebugChanged("w1", "Render", "rows=%d", 3), "after the enable edge")
end)

-- ── DebugForget, keys, the bound ─────────────────────────────────────────────────────────

test("DebugForget: re-arms one key in both gates and leaves the others", function()
  local D = newLog()
  D.DebugOnce("a", "T", "once a"); D.DebugOnce("b", "T", "once b")
  D.DebugChanged("a", "T", "same"); D.DebugChanged("b", "T", "same")
  D.DebugForget("a")
  assertTrue(D.DebugOnce("a", "T", "once a"), "a's once re-armed")
  assertTrue(D.DebugChanged("a", "T", "same"), "a's change memory re-armed")
  assertFalse(D.DebugOnce("b", "T", "once b"), "b untouched")
  assertFalse(D.DebugChanged("b", "T", "same"), "b untouched")
end)

test("gates: a nil key is a key of its own, not a raise", function()
  local D = newLog()
  local ok, first = pcall(D.DebugOnce, nil, "T", "nil once")
  assertTrue(ok and first, "written")
  assertFalse(D.DebugOnce(nil, "T", "nil once"), "and held")
  assertTrue(select(2, pcall(D.DebugChanged, nil, "T", "x")), "DebugChanged too")
  assertTrue(pcall(D.DebugForget, nil), "and forget")
  assertTrue(D.DebugOnce(nil, "T", "nil once"), "which re-armed it")
end)

test("gates: past GATE_MAX_KEYS keys the memory is wiped rather than grown", function()
  local D = newLog()
  local cap = debuglog.GATE_MAX_KEYS
  D.DebugOnce("first", "T", "first")
  for i = 2, cap do D.DebugOnce("k" .. i, "T", "x") end
  assertFalse(D.DebugOnce("first", "T", "first"), "still held at the cap")
  D.DebugOnce("one-more", "T", "x")
  assertTrue(D.DebugOnce("first", "T", "first"), "the wipe re-armed it: a repeat line, never growth")
end)

test("gates: plain functions, bound bare as hosts bind D.Debug", function()
  local D = newLog()
  local once, changed, forget = D.DebugOnce, D.DebugChanged, D.DebugForget
  assertTrue(once("k", "T", "bare once"))
  assertTrue(changed("k", "T", "bare changed"))
  forget("k")
  assertTrue(once("k", "T", "bare once"))
end)

test("gates: secret-safe, and an unsatisfiable format still lands as D.Debug's does", function()
  local D = newLog()
  local ok = pcall(D.DebugOnce, "s", "Absorb", "value=%s", secretMock)
  assertTrue(ok, "no raise on a secret")
  assertEqual(count(D, "value=<secret>"), 1, "rendered as D.Debug renders it")
  ok = pcall(D.DebugChanged, "d", "Absorb", "total=%d", secretMock)
  assertTrue(ok, "a secret in a %d slot does not raise")
  assertEqual(count(D, "total=%d <secret>"), 1, "the fallback line")
end)

-- ── without the file ─────────────────────────────────────────────────────────────────────

test("gates: an instance built without DebugLogGates.lua has no gates, and onClear still fires", function()
  local saved = debuglog.__installGates
  debuglog.__installGates = nil
  local calls = 0
  local ok, err = pcall(function()
    local D = newLog({ onClear = function() calls = calls + 1 end })
    assertEqual(D.DebugOnce, nil)
    assertEqual(D.DebugChanged, nil)
    D.Debug("T", "x")
    D:Clear()
    D:SetEnabled(false); D:SetEnabled(true)
  end)
  debuglog.__installGates = saved
  if not ok then error(err, 0) end
  assertEqual(calls, 1, "the hook is the shell's, not the gates'")
end)
