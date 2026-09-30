-- tests/test_atenable.lua — the console's at-enable queue (`D.DebugAtEnable`, DebugLogGates.lua
-- minor 1) and LibKa0s-Launcher-1.0's use of it (Launcher minor 5). Gap G4 of the 2026-09-30
-- debug-gaps run: the launcher's dependency lines (LibDataBroker / LibDBIcon found or missing,
-- registered) are written at OnEnable, when the session-only logging flag is always off, so they
-- never landed. debug-logging-§8 asks for dependencies "once at enable"; the queue holds a state
-- line written while logging is off and writes it when logging is turned on.
--
-- What is pinned here: the silent defaults (nothing queued, no `debug` and no `debugAtEnable` on the
-- launcher), writing at once when logging is on, holding and flushing when it is off, the order,
-- the one-shot flush, the duplicate hold, the bound and its drop line, that Clear neither drops nor
-- flushes the queue, the instance without the file, and the launcher's lines landing end to end.

local T = _G.LK_TEST
local debuglog, launcher, mocks = T.debuglog, T.launcher, T.mocks
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse

local secretMock = setmetatable({}, { __concat = function() return "secret-propagated" end })

local function newLog(overrides)
  local rec = { enabled = false, chat = {} }
  local d = {
    name       = "AtEnableTest",
    title      = "At Enable Test",
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

--- The index of the first buffer line carrying `needle`, or nil.
local function indexOf(D, needle)
  for i, line in ipairs(D.buffer) do
    if line:find(needle, 1, true) then return i end
  end
end

-- ── registration ─────────────────────────────────────────────────────────────────────────

test("atenable: the instance carries DebugAtEnable, with its bound pinned", function()
  assertEqual(debuglog.AT_ENABLE_MAX, 32, "the literal the api document cites")
  local D = newLog()
  assertEqual(type(D.DebugAtEnable), "function")
end)

-- ── logging on ───────────────────────────────────────────────────────────────────────────

test("atenable: logging on, the line is written at once, formatted as D.Debug formats", function()
  local D, rec = newLog()
  rec.enabled = true
  assertTrue(D.DebugAtEnable("Launcher", "found %s v%d", "LibDBIcon-1.0", 2), "written: true")
  assertEqual(count(D, "[Launcher] found LibDBIcon-1.0 v2"), 1)
  D:SetEnabled(false); D:SetEnabled(true)
  assertEqual(count(D, "found LibDBIcon-1.0"), 1, "nothing was queued, so the enable edge adds none")
end)

-- ── logging off: held, then flushed ──────────────────────────────────────────────────────

test("atenable: logging off, nothing is written; turning logging on writes it after the bracket", function()
  local D = newLog({ initSummary = function() return "Host v1, schema 2" end })
  assertFalse(D.DebugAtEnable("Launcher", "registered"), "held: false")
  assertEqual(D:BufferSize(), 0, "nothing in the console while off")
  D:SetEnabled(true)
  local bracket, summary, line = indexOf(D, "[Debug] logging enabled"), indexOf(D, "[Init] Host v1"),
    indexOf(D, "[Launcher] registered")
  assertTrue(bracket and summary and line, "all three landed")
  assertTrue(bracket < line and summary < line, "after the session bracket and the host summary")
end)

test("atenable: held lines flush in the order they were written", function()
  local D = newLog()
  D.DebugAtEnable("Launcher", "LibDataBroker-1.1 found")
  D.DebugAtEnable("Launcher", "LibDBIcon-1.0 found")
  D.DebugAtEnable("Launcher", "registered")
  D:SetEnabled(true)
  local a, b, c = indexOf(D, "LibDataBroker-1.1 found"), indexOf(D, "LibDBIcon-1.0 found"),
    indexOf(D, "[Launcher] registered")
  assertTrue(a and b and c and a < b and b < c, "first written, first flushed")
end)

test("atenable: the flush is one-shot, a second enable edge does not repeat it", function()
  local D = newLog()
  D.DebugAtEnable("Launcher", "registered")
  D:SetEnabled(true)
  D:SetEnabled(false); D:SetEnabled(true)
  assertEqual(count(D, "[Launcher] registered"), 1)
end)

test("atenable: an identical line already held is held once", function()
  local D = newLog()
  D.DebugAtEnable("Launcher", "LibDBIcon-1.0 absent; broker plugin only")
  D.DebugAtEnable("Launcher", "LibDBIcon-1.0 absent; broker plugin only")
  D.DebugAtEnable("Other", "LibDBIcon-1.0 absent; broker plugin only")
  D:SetEnabled(true)
  assertEqual(count(D, "[Launcher] LibDBIcon-1.0 absent"), 1, "a Register retried at login is one line")
  assertEqual(count(D, "[Other] LibDBIcon-1.0 absent"), 1, "another tag is another line")
end)

test("atenable: past AT_ENABLE_MAX the later lines are dropped, and one line says how many", function()
  local D = newLog()
  local cap = debuglog.AT_ENABLE_MAX
  for i = 1, cap + 3 do D.DebugAtEnable("State", "line %d", i) end
  D:SetEnabled(true)
  assertEqual(count(D, "[State] line "), cap, "the first AT_ENABLE_MAX lines")
  assertEqual(count(D, "[State] line " .. cap), 1, "the last kept is line " .. cap)
  assertEqual(count(D, "[State] line " .. (cap + 1)), 0, "the later ones were dropped")
  assertEqual(count(D, "[Debug] at-enable queue full: 3 later lines dropped"), 1, "and counted")
  D:SetEnabled(false)
  D.DebugAtEnable("State", "after")
  D:SetEnabled(true)
  assertEqual(count(D, "queue full"), 1, "the count went with the flush")
  assertEqual(count(D, "[State] after"), 1, "and the queue takes lines again")
end)

test("atenable: Clear neither drops nor flushes a held line", function()
  local D = newLog()
  D.DebugAtEnable("Launcher", "registered")
  D:Clear()
  assertEqual(D:BufferSize(), 0, "Clear did not flush it")
  D:SetEnabled(true)
  assertEqual(count(D, "[Launcher] registered"), 1, "and did not drop it")
end)

test("atenable: turning logging off does not flush", function()
  local D = newLog()
  D.DebugAtEnable("Launcher", "registered")
  D:SetEnabled(false)
  assertEqual(count(D, "registered"), 0)
end)

test("atenable: a held line is secret-safe, and an unsatisfiable format still lands", function()
  local D = newLog()
  assertTrue(pcall(D.DebugAtEnable, "State", "v=%s", "value"))
  assertTrue(pcall(D.DebugAtEnable, "State", "s=%s", secretMock), "no raise on a secret")
  assertTrue(pcall(D.DebugAtEnable, "State", "n=%d", secretMock), "nor in a %d slot")
  D:SetEnabled(true)
  assertEqual(count(D, "[State] v=value"), 1)
  assertEqual(count(D, "s=<secret>"), 1, "rendered as D.Debug renders it")
  assertEqual(count(D, "n=%d <secret>"), 1, "the fallback line")
end)

test("atenable: plain function, bound bare as hosts bind D.Debug", function()
  local D = newLog()
  local atEnable = D.DebugAtEnable
  atEnable("Bare", "bound")
  D:SetEnabled(true)
  assertEqual(count(D, "[Bare] bound"), 1)
end)

test("atenable: nothing held, turning logging on writes only the bracket (the silent default)", function()
  local D = newLog()
  D:SetEnabled(true)
  assertEqual(count(D, "queue full"), 0)
  assertEqual(D:BufferSize(), 1, "the bracket line alone")
end)

test("atenable: an instance built without DebugLogGates.lua has no queue, and enabling still works", function()
  local saved = debuglog.__installGates
  debuglog.__installGates = nil
  local ok, err = pcall(function()
    local D = newLog()
    assertEqual(D.DebugAtEnable, nil)
    D:SetEnabled(true)
    assertEqual(count(D, "[Debug] logging enabled"), 1)
  end)
  debuglog.__installGates = saved
  if not ok then error(err, 0) end
end)

-- ── the launcher ─────────────────────────────────────────────────────────────────────────
--
-- The broker fakes are tests/test_launcher.lua's, found in the mock's LibStub registry; registered
-- here only if this suite runs alone.

local LDB = mocks.LibStub:GetLibrary("LibDataBroker-1.1", true)
if not LDB then
  LDB = mocks.LibStub:NewLibrary("LibDataBroker-1.1", 1)
  LDB.__objects = {}
  function LDB:NewDataObject(name, tbl)
    if self.__objects[name] then return nil end
    self.__objects[name] = tbl
    return tbl
  end
  function LDB:GetDataObjectByName(name) return self.__objects[name] end
end
if not mocks.LibStub:GetLibrary("LibDBIcon-1.0", true) then
  local ICON = mocks.LibStub:NewLibrary("LibDBIcon-1.0", 1)
  ICON.__buttons = {}
  function ICON:Register(name, object, db) self.__buttons[name] = { object = object, db = db } end
  function ICON:Show() end
  function ICON:Hide() end
end

local seq = 0
local function launcherFixture(over)
  seq = seq + 1
  local rec = { logs = {}, held = {}, lines = {}, minimap = {} }
  local d = {
    name = "AtEnableHost" .. seq,
    icon = "Interface\\AddOns\\AtEnableHost\\media\\logos\\host.logo.128.tga",
    minimap = function() return rec.minimap end,
    openSettings = function() end,
    print = function(line) rec.lines[#rec.lines + 1] = line end,
    debug = function(tag, message) rec.logs[#rec.logs + 1] = tag .. ": " .. message end,
    debugAtEnable = function(tag, message) rec.held[#rec.held + 1] = tag .. ": " .. message end,
  }
  for k, v in pairs(over or {}) do d[k] = v end
  rec.d = d
  return rec
end

test("launcher: neither debug nor debugAtEnable passed, Register is silent and does not raise", function()
  local rec = launcherFixture({ debug = false, debugAtEnable = false })
  local L = launcher:New(rec.d)
  local ok, wired = pcall(function() return L:Register() end)
  assertTrue(ok, "no raise")
  assertTrue(wired, "and the launcher is wired")
  assertEqual(#rec.logs + #rec.held + #rec.lines, 0, "nothing written anywhere")
end)

test("launcher: with debugAtEnable, the registration line goes to it, not to debug", function()
  local rec = launcherFixture()
  launcher:New(rec.d):Register()
  assertEqual(table.concat(rec.held, "|"), "Launcher: registered")
  assertEqual(#rec.logs, 0, "not written twice")
end)

test("launcher: with debug alone, the registration line goes to debug, as before minor 5", function()
  local rec = launcherFixture({ debugAtEnable = false })
  launcher:New(rec.d):Register()
  assertEqual(table.concat(rec.logs, "|"), "Launcher: registered")
end)

test("launcher: a missing minimap table is a state line, held for enable", function()
  local rec = launcherFixture({ minimap = function() return nil end })
  launcher:New(rec.d):Register()
  assertTrue(table.concat(rec.held, "|"):find("descriptor.minimap answered no table", 1, true) ~= nil)
  assertEqual(#rec.logs, 0)
end)

test("launcher: event lines (shown / hidden) stay on debug when debugAtEnable is passed", function()
  local rec = launcherFixture()
  local L = launcher:New(rec.d)
  L:Register()
  L:SetShown(false)
  assertEqual(table.concat(rec.logs, "|"), "Launcher: hidden", "an event is not held for enable")
end)

test("launcher: end to end, a Register at OnEnable lands the first time logging is turned on", function()
  local D = newLog()
  local rec = launcherFixture({ debug = D.Debug, debugAtEnable = D.DebugAtEnable })
  local L = launcher:New(rec.d)
  assertTrue(L:Register())
  assertEqual(D:BufferSize(), 0, "logging is off at login: nothing yet")
  L:SetShown(false)
  assertEqual(D:BufferSize(), 0, "and an event while off is gated, as D.Debug gates it")
  D:SetEnabled(true)
  assertEqual(count(D, "[Launcher] registered"), 1, "the state line landed")
  assertEqual(count(D, "hidden"), 0, "the event did not")
end)
