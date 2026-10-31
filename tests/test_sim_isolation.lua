-- tests/test_sim_isolation.lua -- LibKa0s-Sim-1.0's isolation invariants: every host gets its OWN
-- seam, session, timers and panel on one shared major, and the shell's two attach files only ever
-- pair with the shell copy they shipped beside. tests/test_perf_isolation.lua's idiom, for Sim.
--
-- Two halves. The first builds two hosts on one loaded major and drives one of them, asserting the
-- other never noticed: a provider, an active flag, a timer or a panel frame hoisted to file scope
-- in Sim.lua, SimTimeline.lua or SimPanel.lua would make the second host answer for the first.
-- The second loads real, minor-patched copies of the three files into fresh environments, the way
-- two addons each vendoring their own copy would, and asserts the shell, its step machine and its
-- panel came from the same copy (`__timelineShellMinor` / `__panelShellMinor`, Perf's pairing).

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local F = dofile("tests/fixture_sim_panel.lua")
local Loader = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

--- One host on `Sim`: its own Compat table and seam, a three-step scenario, and a recording
--- descriptor. `h.liveCalls` counts the live client reader; `h.played` the steps played.
local function host(Sim, name)
  local h = { name = name, printed = {}, played = {}, delivered = 0, liveCalls = 0, stoodDown = false }
  h.compat = {
    UnitName = function(unit) h.liveCalls = h.liveCalls + 1; return "live-" .. tostring(unit) end,
  }
  h.seam = Sim:NewSeam(h.compat, { name = name })
  h.sim = Sim:New({
    name = name, seam = h.seam, slash = "/" .. name:lower() .. " sim",
    deliver = function() h.delivered = h.delivered + 1; return 1 end,
    isStoodDown = function() return h.stoodDown end,
    scenarios = { names = { "three" }, defs = { three = { label = "Three", timeline = function()
      return { { kind = "a" }, { kind = "b" }, { kind = "c" } }
    end } } },
    prepare = function(_, _, _, ready) ready() end,
    play = function(step) h.played[#h.played + 1] = step.kind end,
    print = function(line) h.printed[#h.printed + 1] = line end,
  })
  return h
end

--- Two hosts on one fully loaded major (Core, Widgets, Sim, SimTimeline, SimPanel).
local function twoHosts()
  local m, Sim = F.env()
  return m, host(Sim, "HostA"), host(Sim, "HostB")
end

-- -- seams ---------------------------------------------------------------------------------------

test("sim iso: two hosts' seams are separate objects over separate tables", function()
  local _, a, b = twoHosts()
  assertTrue(a.seam ~= b.seam, "one seam shared between hosts would answer one host's providers to both")
  assertEqual(table.concat(a.seam:Keys(), ","), "UnitName")
  assertEqual(table.concat(b.seam:Keys(), ","), "UnitName")
  assertEqual(#a.seam:Unwrapped(), 0, "A is wholly wrapped")
  assertEqual(#b.seam:Unwrapped(), 0, "B is wholly wrapped")
end)

test("sim iso: one host's provider and active flag never reach the other's seam", function()
  local _, a, b = twoHosts()
  a.seam:SetProvider("UnitName", function() return "simA" end)
  assertTrue(a.sim:Start({ scenario = "three" }))
  assertEqual(a.compat.UnitName("target"), "simA", "A answers from its provider while active")
  assertEqual(b.compat.UnitName("target"), "live-target", "B is idle and answers live")
  assertEqual(a.liveCalls, 0, "A's live reader was never reached while active")
  assertEqual(b.liveCalls, 1, "B's was, once")
  -- B claims the same key on its own seam: a shared provider table would raise "already has a
  -- provider" here.
  b.seam:SetProvider("UnitName", function() return "simB" end)
  assertTrue(b.sim:Start({ scenario = "three" }))
  assertEqual(b.compat.UnitName("x"), "simB")
  assertEqual(a.compat.UnitName("x"), "simA")
  a.sim:Stop(); b.sim:Stop()
end)

-- -- sessions ------------------------------------------------------------------------------------

test("sim iso: one host's session, stop and status leave the other's untouched", function()
  local _, a, b = twoHosts()
  assertTrue(a.sim:Start({ scenario = "three", seed = 7 }))
  assertTrue(a.sim:IsActive())
  assertFalse(b.sim:IsActive(), "B never started")
  assertNil(b.sim:Session(), "and has no session")
  assertTrue(b.sim:Start({ scenario = "three", seed = 9 }))
  assertTrue(a.sim:Session() ~= b.sim:Session(), "two sessions")
  assertEqual(a.sim:Status().seed, 7)
  assertEqual(b.sim:Status().seed, 9)
  assertTrue(a.sim:Step())
  assertEqual(a.sim:Status().pos, 1, "A advanced")
  assertEqual(b.sim:Status().pos, 0, "B did not")
  assertEqual(a.sim:Fire("EV"), 1)
  assertEqual(a.delivered, 1)
  assertEqual(b.delivered, 0, "A's Fire reached A's deliver only")
  assertTrue(a.sim:Stop())
  assertFalse(a.sim:IsActive())
  assertTrue(b.sim:IsActive(), "B still runs after A stops")
  assertEqual(b.sim:Fire("EV"), 1, "and still delivers")
  b.sim:Stop()
end)

-- -- timers --------------------------------------------------------------------------------------

test("sim iso: stopping one host kills its timers only", function()
  local m, a, b = twoHosts()
  a.sim:Start({ scenario = "three" })
  b.sim:Start({ scenario = "three" })
  local ran = {}
  assertTrue(a.sim:After(1, function() ran[#ran + 1] = "A" end) ~= nil)
  assertTrue(b.sim:After(1, function() ran[#ran + 1] = "B" end) ~= nil)
  a.sim:Stop()
  m.__fireTimers()
  assertEqual(table.concat(ran, ","), "B", "A's timer died with A's session; B's ran")
  b.sim:Stop()
end)

test("sim iso: one host's Run ticks advance that host only", function()
  local m, a, b = twoHosts()
  a.sim:Start({ scenario = "three" })
  b.sim:Start({ scenario = "three" })
  assertTrue(a.sim:Run())
  assertEqual(table.concat(a.played, ","), "a")
  m.__fireTimers()
  assertEqual(table.concat(a.played, ","), "a,b", "A's tick played A's next step")
  assertEqual(#b.played, 0, "B was never run")
  assertEqual(b.sim:Status().pos, 0)
  a.sim:Stop(); b.sim:Stop()
end)

-- -- panels --------------------------------------------------------------------------------------

test("sim iso: two hosts build separate panel frames, and showing one shows one", function()
  local m, a, b = twoHosts()
  F.recording(m, function()
    assertTrue(a.sim:ShowPanel(), "A shows")
    assertFalse(b.sim:IsPanelShown(), "B's panel is not A's")
    assertTrue(b.sim:ShowPanel(), "B shows")
  end)
  local fa, fb = m.__named.HostASimPanel, m.__named.HostBSimPanel
  assertTrue(fa ~= nil and fb ~= nil, "both panels built, each under its own host's name")
  assertTrue(fa ~= fb, "one frame shared between hosts would draw one host's run")
  a.sim:HidePanel()
  assertFalse(a.sim:IsPanelShown(), "A hidden")
  assertTrue(b.sim:IsPanelShown(), "B still shown")
  b.sim:HidePanel()
end)

test("sim iso: each panel composes its own host's rows", function()
  local _, a, b = twoHosts()
  a.sim:Start({ scenario = "three" })
  a.sim:Step()
  local ra, rb = a.sim:PanelRows(), b.sim:PanelRows()
  assertEqual(ra[1].state, "done", "A's first row has run")
  assertTrue(rb[1].state ~= "done", "B's has not: " .. tostring(rb[1].state))
  a.sim:Stop()
end)

-- -- shell / timeline / panel pairing across vendored copies ----------------------------------
--
-- LibStub picks one Sim shell per major. The two attach files guard on their own minor AND on the
-- shell's (`__timelineShellMinor` / `__panelShellMinor`), so a newer shell loading second brings
-- its own step machine and panel with it, an older copy loading second replaces nothing, and a
-- higher attach-file minor over the same shell still wins. Each copy stamps the half that won.

local function readSource(path)
  local f = assert(io.open(path, "r"))
  local src = f:read("*a")
  f:close()
  return src
end

local SIM_SRC = readSource("LibKa0s/Sim.lua")
local TIMELINE_SRC = readSource("LibKa0s/SimTimeline.lua")
local RENDER_SRC = readSource("LibKa0s/SimPanelRender.lua")
local PANEL_SRC = readSource("LibKa0s/SimPanel.lua")

-- The guard lines read `lib.__timelineShellMinor == lib.MINOR`; the single `=` in the tag patterns
-- below matches only the assignment after them.

--- `src` with `pattern` replaced exactly once; a pattern that stopped matching fails loudly.
local function sub(src, pattern, replacement, what)
  local out, n = src:gsub(pattern, replacement, 1)
  assertEqual(n, 1, "patching " .. what .. " in the real source")
  return out
end

--- One vendored copy: the three files with their minors patched and each stamped with `tag`.
local function copy(tag, shellMinor, timelineMinor, panelMinor)
  local sim = sub(SIM_SRC, 'local MAJOR, MINOR = "LibKa0s%-Sim%-1%.0", %d+',
    'local MAJOR, MINOR = "LibKa0s-Sim-1.0", ' .. shellMinor, "the shell minor")
  sim = sub(sim, "lib%.MAJOR, lib%.MINOR = MAJOR, MINOR",
    'lib.MAJOR, lib.MINOR = MAJOR, MINOR lib.__shellTag = "' .. tag .. '"', "the shell tag")
  local timeline = sub(TIMELINE_SRC, "local TIMELINE_MINOR = %d+",
    "local TIMELINE_MINOR = " .. timelineMinor, "the timeline minor")
  timeline = sub(timeline, "lib%.__timelineShellMinor = lib%.MINOR",
    'lib.__timelineShellMinor = lib.MINOR lib.__timelineTag = "' .. tag .. '"', "the timeline tag")
  local panel = sub(PANEL_SRC, "local SIM_PANEL_MINOR = %d+",
    "local SIM_PANEL_MINOR = " .. panelMinor, "the panel minor")
  panel = sub(panel, "lib%.__panelShellMinor = lib%.MINOR",
    'lib.__panelShellMinor = lib.MINOR lib.__panelTag = "' .. tag .. '"', "the panel tag")
  return { tag = tag, sim = sim, timeline = timeline, render = RENDER_SRC, panel = panel }
end

--- Load whole copies in the order the client would, each copy's three files together. Core and
--- Widgets are loaded once, ahead of every copy: skew between their copies is not this file's
--- question, and SimPanel.lua's attach floor needs both.
local function loadCopies(...)
  local env = buildMocks()
  Loader.load("LibKa0s/Core.lua", nil, env)
  Loader.load("LibKa0s/Widgets.lua", nil, env)
  for _, c in ipairs({ ... }) do
    Loader.loadSource(c.sim, c.tag .. "/Sim.lua", nil, env)
    Loader.loadSource(c.timeline, c.tag .. "/SimTimeline.lua", nil, env)
    Loader.loadSource(c.panel, c.tag .. "/SimPanel.lua", nil, env)
    Loader.loadSource(c.render, c.tag .. "/SimPanelRender.lua", nil, env)
  end
  return env.LibStub("LibKa0s-Sim-1.0")
end

test("sim iso: a newer shell loading second re-attaches its own timeline and panel", function()
  -- HostY ships shell 1, HostX shell 2, both with timeline 1 and panel 1. Y loads first. X's shell
  -- wins the LibStub race, so leaving Y's attach files in place pairs X's shell with Y's
  -- __AttachTimeline and __AttachPanel.
  local lib = loadCopies(copy("Y", 1, 1, 1), copy("X", 2, 1, 1))
  assertEqual(lib.MINOR, 2, "the higher shell minor won")
  assertEqual(lib.__shellTag, "X", "and it is X's shell")
  assertEqual(lib.__timelineTag, "X", "so the timeline must be X's too, not Y's")
  assertEqual(lib.__panelTag, "X", "and the panel X's")
  assertEqual(lib.__timelineShellMinor, 2, "the timeline is paired on the winning shell's minor")
  assertEqual(lib.__panelShellMinor, 2, "and so is the panel")
end)

test("sim iso: an older copy loading second replaces nothing", function()
  local lib = loadCopies(copy("X", 2, 1, 1), copy("Y", 1, 1, 1))
  assertEqual(lib.MINOR, 2, "Y's shell lost the race, as LibStub intends")
  assertEqual(lib.__shellTag, "X")
  assertEqual(lib.__timelineTag, "X", "Y's timeline must not clobber X's")
  assertEqual(lib.__panelTag, "X", "nor Y's panel X's")
end)

test("sim iso: a higher SimPanel minor over the same shell still wins", function()
  local lib = loadCopies(copy("Y", 1, 1, 1), copy("X", 1, 1, 2))
  assertEqual(lib.__shellTag, "Y", "the shell minors tie, so the first copy's shell stands")
  assertEqual(lib.__timelineTag, "Y", "and so does its timeline, whose minor ties too")
  assertEqual(lib.__panelTag, "X", "the panel counter still decides between panels")
  assertEqual(lib.MODULES.SimPanel, 2)
end)

test("sim iso: the paired copy actually drives a session (the attach is live, not a stamp)", function()
  local lib = loadCopies(copy("Y", 1, 1, 1), copy("X", 2, 1, 1))
  local printed = {}
  local seam = lib:NewSeam({ Probe = function() return 1 end }, { name = "Host" })
  local sim = lib:New({
    name = "Host", seam = seam, slash = "/host sim",
    deliver = function() return 0 end, isStoodDown = function() return false end,
    scenarios = { names = { "one" }, defs = { one = { timeline = function() return { { kind = "a" } } end } } },
    prepare = function(_, _, _, ready) ready() end, play = function() end,
    print = function(line) printed[#printed + 1] = line end,
  })
  assertTrue(sim:RunVerb("start one"), "the timeline's grammar answered, not the NO_TIMELINE fallback")
  assertTrue(sim:Step())
  assertTrue(#sim:PanelRows() > 0, "the panel's rows, not the fallback's {}")
  sim:Stop()
end)
