-- tests/test_slash_debug.lua — LibKa0s-Slash-1.0's own refusals reaching the host's debug sink
-- (Slash minor 18, gap G1 of the 2026-09-30 LibKa0s debug-gaps run).
--
-- The descriptor takes `debug(tag, message)`, exactly as LibKa0s-Launcher-1.0's does. Every refusal
-- the dispatcher decides itself writes ONE `Cmd` line naming the verb and the guard: the disabled
-- gate, an unknown verb, get/set/reset usage, not-found, parse and write refusals, a reset with no
-- default, and the profile verb's refusals. Absent `debug`, the module stays silent, and the chat is
-- byte for byte what it was at minor 17 either way.

local T = _G.LK_TEST
local slash, mocks = T.slash, T.mocks
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

local F = dofile("tests/fixture_slash.lua")

local PATH = "units.player.barWidth"

--- A host whose `debug` records `tag|message`; `overrides` reach the descriptor as F.new's do.
local function host(overrides)
  local logs = {}
  local o = { debug = function(tag, message) logs[#logs + 1] = tostring(tag) .. "|" .. tostring(message) end }
  for k, v in pairs(overrides or {}) do o[k] = v end
  local Sl, rec = F.new(o)
  rec.logs = logs
  return Sl, rec
end

local function newStore(names, current)
  local s = { profiles = {}, current = current, sets = {} }
  for _, n in ipairs(names) do s.profiles[n] = true end
  function s:GetProfiles(tbl)
    tbl = tbl or {}
    local i = 0
    for n in pairs(self.profiles) do i = i + 1; tbl[i] = n end
    return tbl, i
  end
  function s:GetCurrentProfile() return self.current end
  function s:SetProfile(name) self.sets[#self.sets + 1] = name; self.current = name end
  return s
end

local function disabledHost(extra)
  local o = { isEnabled = function() return false end, brandName = "Ka0s Test Host" }
  for k, v in pairs(extra or {}) do o[k] = v end
  local Sl, rec = host(o)
  rec.commands[#rec.commands + 1] = { "lock", "Toggle the lock", function() rec.chat[#rec.chat + 1] = "locked" end }
  return Sl, rec
end

local function assertOneLine(rec, want, label)
  assertEqual(#rec.logs, 1, label .. ": exactly one line: " .. table.concat(rec.logs, " || "))
  assertEqual(rec.logs[1], want, label)
end

-- ── the version ────────────────────────────────────────────────────────────────────────────

test("sl debug: Slash is at minor 18", function()
  assertEqual(slash.MINOR, 18)
  assertEqual(slash.MODULES.Slash, 18)
end)

-- ── one line per refusal ───────────────────────────────────────────────────────────────────

test("sl debug: the disabled gate refusing a feature verb writes one Cmd line", function()
  local Sl, rec = disabledHost()
  Sl:OnSlash("lock")
  assertOneLine(rec, "Cmd|refused lock: disabled", "disabled gate")
  assertEqual(#rec.chat, 1, "the chat is still the one refusal line")
end)

test("sl debug: an unknown verb writes one Cmd line", function()
  local Sl, rec = host()
  Sl:OnSlash("frobnicate now")
  assertOneLine(rec, "Cmd|refused frobnicate: unknown verb", "unknown verb")
end)

test("sl debug: an unknown verb while disabled is still an unknown verb, not the gate", function()
  local Sl, rec = disabledHost()
  Sl:OnSlash("lokc")
  assertOneLine(rec, "Cmd|refused lokc: unknown verb", "typo while disabled")
end)

test("sl debug: get's usage and not-found refusals", function()
  local Sl, rec = host()
  Sl:OnSlash("get")
  assertOneLine(rec, "Cmd|refused get: usage", "get usage")
  rec.logs[1] = nil
  Sl:OnSlash("get no.such.path")
  assertOneLine(rec, "Cmd|refused get no.such.path: not found", "get not found")
end)

test("sl debug: set's usage, not-found and parse refusals", function()
  local Sl, rec = host()
  Sl:OnSlash("set")
  assertOneLine(rec, "Cmd|refused set: usage", "set usage")
  rec.logs[1] = nil
  Sl:OnSlash("set no.such.path 3")
  assertOneLine(rec, "Cmd|refused set no.such.path: not found", "set not found")
  rec.logs[1] = nil
  Sl:OnSlash("set " .. PATH .. " wide")
  assertOneLine(rec, "Cmd|refused set " .. PATH .. ": parse (expected a number)", "set parse")
  assertEqual(rec.store[PATH], 200, "nothing stored")
end)

test("sl debug: a write the host's set refuses names the reason", function()
  local Sl, rec = host({ set = function() return false, "must be 1-10", "why" end })
  Sl:OnSlash("set " .. PATH .. " 300")
  assertOneLine(rec, "Cmd|refused set " .. PATH .. ": write refused (must be 1-10)", "set refused")
  local Sl2, rec2 = host({ set = function() return false end })
  Sl2:OnSlash("set " .. PATH .. " 300")
  assertOneLine(rec2, "Cmd|refused set " .. PATH .. ": write refused", "set refused, no reason")
end)

test("sl debug: reset's usage, not-found and no-default refusals", function()
  local Sl, rec = host()
  Sl:OnSlash("reset")
  assertOneLine(rec, "Cmd|refused reset: usage", "reset usage")
  rec.logs[1] = nil
  Sl:OnSlash("reset no.such.path")
  assertOneLine(rec, "Cmd|refused reset no.such.path: not found", "reset not found")
  local Sl2, rec2 = host({ applyDefault = function() return false end })
  Sl2:OnSlash("reset " .. PATH)
  assertOneLine(rec2, "Cmd|refused reset " .. PATH .. ": no default", "reset no default")
end)

test("sl debug: the profile verb's refusals, combat included", function()
  local Sl, rec = host()
  Sl:CliProfile("Main")
  assertOneLine(rec, "Cmd|refused profile: unavailable", "no store")

  local store = newStore({ "Default", "Main" }, "Default")
  local Sp, rp = host({ profiles = function() return store end })
  Sp:ProfileSwitch("Default")
  assertOneLine(rp, "Cmd|refused profile Default: already current", "already")
  rp.logs[1] = nil
  Sp:ProfileSwitch("Nope")
  assertOneLine(rp, "Cmd|refused profile Nope: unknown profile", "unknown profile")
  rp.logs[1] = nil
  local saved = mocks.InCombatLockdown
  mocks.InCombatLockdown = function() return true end
  local ok, err = pcall(function() Sp:CliProfile("Main") end)
  mocks.InCombatLockdown = saved
  assertTrue(ok, tostring(err))
  assertOneLine(rp, "Cmd|refused profile Main: in combat", "combat")
  assertEqual(#store.sets, 0, "nothing switched")
end)

-- ── what writes nothing ────────────────────────────────────────────────────────────────────

test("sl debug: a command that is answered writes no line", function()
  local store = newStore({ "Default", "Main" }, "Default")
  local Sl, rec = host({ profiles = function() return store end })
  Sl:OnSlash("")
  Sl:OnSlash("help")
  Sl:OnSlash("list")
  Sl:OnSlash("get " .. PATH)
  Sl:OnSlash("set " .. PATH .. " 300")
  Sl:OnSlash("reset " .. PATH)
  Sl:OnSlash("version")
  Sl:OnSlash("options")
  Sl:CliProfile("")
  Sl:CliProfile("Main")
  assertEqual(#rec.logs, 0, table.concat(rec.logs, " || "))
end)

test("sl debug: a live verb while disabled writes no line", function()
  local Sl, rec = disabledHost()
  Sl:OnSlash("help")
  Sl:OnSlash("get " .. PATH)
  Sl:OnSlash("")
  assertEqual(#rec.logs, 0, table.concat(rec.logs, " || "))
end)

-- ── the silent default, and the chat unchanged ─────────────────────────────────────────────

local REFUSED = {
  "lock", "frobnicate", "get", "get no.such.path", "set", "set no.such.path 1",
  "set " .. PATH .. " wide", "reset", "reset no.such.path",
}

test("sl debug: with no debug passed, every refusal still answers and nothing raises", function()
  local enabled = { value = true }
  local Sl, rec = F.new({ isEnabled = function() return enabled.value end, brandName = "Ka0s Test Host" })
  rec.commands[#rec.commands + 1] = { "lock", "Toggle the lock", function() end }
  enabled.value = false
  for _, input in ipairs(REFUSED) do
    local ok, err = pcall(function() Sl:OnSlash(input) end)
    assertTrue(ok, input .. ": " .. tostring(err))
  end
  assertTrue(#rec.chat > 0, "the refusals still reach chat")
  local ok, err = pcall(function() Sl:CliProfile("Main") end)
  assertTrue(ok, tostring(err))
end)

test("sl debug: a non-function debug field is ignored", function()
  local Sl, rec = F.new({ debug = "not a function" })
  local ok, err = pcall(function() Sl:OnSlash("frobnicate") end)
  assertTrue(ok, tostring(err))
  assertTrue(#rec.chat > 0)
end)

test("sl debug: the chat is byte for byte the same with and without a debug sink", function()
  local function run(withDebug)
    local o = { isEnabled = function() return false end, brandName = "Ka0s Test Host" }
    if withDebug then o.debug = function() end end
    local Sl, rec = F.new(o)
    rec.commands[#rec.commands + 1] = { "lock", "Toggle the lock", function() end }
    for _, input in ipairs(REFUSED) do Sl:OnSlash(input) end
    Sl:CliProfile("Main")
    return rec.chat
  end
  local bare, wired = run(false), run(true)
  assertEqual(#wired, #bare, "line count")
  for i = 1, #bare do assertEqual(wired[i], bare[i], "chat line " .. i) end
end)
