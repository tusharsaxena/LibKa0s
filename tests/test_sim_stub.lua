-- tests/test_sim_stub.lua -- the REFERENCE degradation stub a Sim host builds when
-- `LibStub("LibKa0s-Sim-1.0", true)` answers nil, and the parity cases that keep it whole.
--
-- A host reads `NS.Sim:IsActive()` and `NS.Sim:IsDelivering()` on hot real-event paths and calls
-- `NS.SimSeam:Live(fn, ...)` around client reads, so the stub is mandatory, not optional: one
-- missing member raises on exactly the degraded path the stub exists to survive. The two builders
-- below are the shape every host copies (design-sim §7, the API document's *Adopting it*): the
-- setup file wraps nothing and publishes them in place of the seam and the session.
--
-- Each is pinned two ways. Its answers, member by member. And its surface, with
-- `Kit.assertSurfaceParity` against a LIVE instance (and a live seam) registered through
-- `Kit.setSurfaceSource`: no manifest lists instance members, since `Sim:New` builds them per host,
-- so the live half has to be a real instance. The ignore set is empty, and the reverse comparison
-- is made too, so a stub cannot carry a member the library does not publish (the cut `IsGuarded`
-- and `IsActive` on the seam, OWNER_SCOPE C.7).

local T = _G.LK_TEST
local test, assertEqual, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertFalse, T.assertNil
local F = dofile("tests/fixture_sim_panel.lua")
local Loader = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local MAJOR = "LibKa0s-Sim-1.0"

-- -- the reference stub (copy this into the host's setup file) ---------------------------------

local NEEDS_LINE = "The simulator needs LibKa0s-Sim-1.0."

--- The inert seam: nothing is wrapped, so Live simply calls through.
local function newSeamStub()
  local seam = {}
  function seam.SetProvider() end
  function seam.Live(_, fn, ...) return fn(...) end
  function seam.Keys() return {} end
  function seam.Unwrapped() return {} end
  return seam
end

--- The inert session. `say` is the host's own print; Start and RunVerb print through it, as the
--- live Start prints its refusal line.
local function newSimStub(say)
  local sim = {}
  local function no() return false end
  local function noop() end
  local function absent() return false, "absent" end
  sim.IsActive, sim.IsDelivering, sim.IsPanelShown = no, no, no
  function sim.Fire() return 0 end
  function sim.DeliverForCleanup() return 0 end
  function sim.After() return nil end
  function sim.Start() say(NEEDS_LINE); return false, NEEDS_LINE end
  sim.Stop = no
  sim.OnStop, sim.OnStopGuarded, sim.AddListener = noop, noop, noop
  function sim.Status() return { active = false } end
  function sim.Session() return nil end
  function sim.Steps() return {} end
  function sim.Step() return nil, "absent" end
  sim.Run, sim.Pause, sim.Resume, sim.Restart = absent, absent, absent, absent
  function sim.RunVerb() say(NEEDS_LINE); return false, "absent" end
  sim.ShowPanel, sim.TogglePanel = no, no
  sim.HidePanel, sim.RefreshPanel, sim.ResetPanelPosition = noop, noop, noop
  function sim.PanelRows() return {} end
  return sim
end

-- -- the live halves ------------------------------------------------------------------------------

--- A live seam and instance on a fully loaded major.
local function live(m, Sim)
  if not Sim then m, Sim = F.env() end
  local seam = Sim:NewSeam({ Probe = function() return 1 end }, { name = "Host" })
  local sim = Sim:New({
    name = "Host", seam = seam, slash = "/host sim",
    deliver = function() return 0 end, isStoodDown = function() return false end,
    scenarios = { names = { "one" }, defs = { one = { timeline = function() return { { kind = "a" } } end } } },
    prepare = function(_, _, _, ready) ready() end, play = function() end,
    print = function() end,
  })
  return seam, sim, m
end

--- Run fn with `surface` registered under MAJOR, and put the previous source back on every exit.
local function withSource(surface, fn)
  local restore = T.setSurfaceSource({ [MAJOR] = surface })
  local ok, err = pcall(fn)
  T.setSurfaceSource(restore)
  if not ok then error(err, 0) end
end

local function sortedKeys(t)
  local out = {}
  for k in pairs(t) do out[#out + 1] = tostring(k) end
  table.sort(out)
  return table.concat(out, ",")
end

-- -- the answers ----------------------------------------------------------------------------------

test("sim stub: the session stub answers inert, member by member", function()
  local printed = {}
  local sim = newSimStub(function(line) printed[#printed + 1] = line end)
  assertFalse(sim:IsActive()); assertFalse(sim:IsDelivering()); assertFalse(sim:IsPanelShown())
  assertEqual(sim:Fire("EV", 1), 0)
  assertEqual(sim:DeliverForCleanup("EV"), 0)
  assertNil(sim:After(1, function() end))
  local ok, line = sim:Start({ scenario = "any" })
  assertFalse(ok); assertEqual(line, NEEDS_LINE)
  assertFalse(sim:Stop("standDown"))
  sim:OnStop(function() end); sim:OnStopGuarded(function() end); sim:AddListener(function() end)
  local st = sim:Status()
  assertEqual(sortedKeys(st), "active"); assertFalse(st.active)
  assertNil(sim:Session())
  assertEqual(#sim:Steps(), 0); assertEqual(#sim:PanelRows(), 0)
  local s, code = sim:Step()
  assertNil(s); assertEqual(code, "absent")
  for _, member in ipairs({ "Run", "Pause", "Resume", "Restart" }) do
    local okM, codeM = sim[member](sim)
    assertFalse(okM, member); assertEqual(codeM, "absent", member)
  end
  assertFalse(sim:ShowPanel()); assertFalse(sim:TogglePanel())
  sim:HidePanel(); sim:RefreshPanel(); sim:ResetPanelPosition()
  local before = #printed
  local okV, codeV = sim:RunVerb("start any")
  assertFalse(okV); assertEqual(codeV, "absent")
  assertEqual(#printed, before + 1, "RunVerb prints one line")
  assertEqual(printed[#printed], "The simulator needs LibKa0s-Sim-1.0.")
end)

test("sim stub: the seam stub's Live calls through with every argument and answer", function()
  local seam = newSeamStub()
  local a, b, c = seam:Live(function(x, y) return y, nil, x end, 1, 2)
  assertEqual(a, 2); assertNil(b); assertEqual(c, 1)
  assertEqual(select("#", seam:Live(function() return nil, nil end)), 2, "nil holes survive")
  seam:SetProvider("Anything", function() end)
  assertEqual(#seam:Keys(), 0); assertEqual(#seam:Unwrapped(), 0)
end)

-- -- parity against a live instance ---------------------------------------------------------------

test("sim stub: the session stub carries the live instance's whole surface", function()
  local _, sim = live()
  withSource(sim, function() T.assertSurfaceParity(newSimStub(function() end), MAJOR, {}) end)
end)

test("sim stub: and carries nothing the live instance does not publish", function()
  local _, sim = live()
  T.assertSurfaceParity(newSimStub(function() end), sim, "stub over the live instance", {})
end)

test("sim stub: the seam stub carries the live seam's whole surface, and nothing more", function()
  local seam = live()
  withSource(seam, function() T.assertSurfaceParity(newSeamStub(), MAJOR, {}) end)
  T.assertSurfaceParity(newSeamStub(), seam, "seam stub over the live seam", {})
end)

test("sim stub: the instance surface is the same with or without the attach files", function()
  -- The shell installs a fallback for every timeline and panel member, so a payload missing
  -- SimTimeline.lua or SimPanel.lua publishes the same instance, and one stub fits both.
  local m = buildMocks()
  Loader.load("LibKa0s/Core.lua", nil, m)
  Loader.load("LibKa0s/Sim.lua", nil, m)
  local _, shellOnly = live(m, m.LibStub(MAJOR))
  local _, full = live()
  assertEqual(sortedKeys(shellOnly), sortedKeys(full))
  assertEqual(sortedKeys(newSimStub(function() end)), sortedKeys(full))
end)
