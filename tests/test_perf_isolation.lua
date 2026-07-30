-- tests/test_perf_isolation.lua — the one invariant the library exists to enforce: every host gets
-- its OWN frames and its own state, and a panel only ever pairs with the probe it shipped beside.
--
-- These are the tests that must FAIL if `local sampler` or the panel's `local frame` is hoisted out
-- of its per-instance closure to file scope. A lib-level shared frame would bill its OnUpdate to
-- whichever addon happened to create it — reproducing the exact Addon Profiler misattribution the
-- whole library is a workaround for. The rest of the suite never noticed, because nothing else
-- drives two instances far enough to make either frame exist.

local T = _G.LK_TEST
local mocks = T.mocks
local test, assertEqual, assertTrue, assertFalse =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse
local Fixture = dofile("tests/fixture.lua")

local function twoHosts()
  local a = Fixture.new({ name = "HostA", sv = "HostAPerfDB", slash = "/ha" })
  local b = Fixture.new({ name = "HostB", sv = "HostBPerfDB", slash = "/hb" })
  return a, b
end

-- ── the sampler frame ───────────────────────────────────────────────────────────────────────

test("iso: two instances create separate sampler frames", function()
  local a, b = twoHosts()
  a.Start("a")
  b.Start("b")
  assertTrue(a.__sampler() ~= nil, "A has a sampler")
  assertTrue(b.__sampler() ~= nil, "B has a sampler")
  assertTrue(a.__sampler() ~= b.__sampler(),
    "a shared sampler would bill both hosts' OnUpdate to whichever addon created it")
  a.Cancel(); b.Cancel()
end)

test("iso: driving one instance's sampler accumulates into that instance alone", function()
  local a, b = twoHosts()
  a.Start("a"); b.Start("b")
  a.Measure("a"); b.Measure("a")
  mocks.__inCombat = true
  a.__sampler():__fire("OnUpdate", 0.5)
  a.__sampler():__fire("OnUpdate", 0.5)
  mocks.__inCombat = false
  assertEqual(a.__fpsArms().active.frames, 2, "A caught both frames")
  assertEqual(a.__fpsArms().active.seconds, 1, "and both half-seconds")
  assertEqual(b.__fpsArms().active.frames, 0, "B was never driven and must have caught nothing")
  a.Cancel(); b.Cancel()
end)

test("iso: an instance's sampler is detached without touching the other's", function()
  local a, b = twoHosts()
  a.Start("a"); b.Start("b")
  a.Stop()
  assertEqual(a.__sampler():GetScript("OnUpdate"), nil, "A's per-frame cost is gone")
  assertTrue(b.__sampler():GetScript("OnUpdate") ~= nil, "B is still measuring")
  b.Cancel()
end)

-- ── the panel frame ─────────────────────────────────────────────────────────────────────────

test("iso: two instances create separate panel frames", function()
  local a, b = twoHosts()
  a.ShowPanel()
  b.ShowPanel()
  assertTrue(a.__panel() ~= nil and b.__panel() ~= nil, "both panels built")
  assertTrue(a.__panel() ~= b.__panel(), "one panel shared between hosts renders one host's run")
  a.HidePanel(); b.HidePanel()
end)

test("iso: each panel renders its own host's state and its own slash prefix", function()
  -- Both panels are built BEFORE either run starts, so a shared frame would still be showing A's
  -- rows when B is asked what it is displaying.
  local a, b = twoHosts()
  a.ShowPanel()
  b.ShowPanel()
  a.Start("a")
  assertEqual(a.__panel().buttons.start.__state, "done", "A has a run in flight")
  assertEqual(b.__panel().buttons.start.__state, "ready", "B has not started anything")
  assertEqual(a.__panel().buttons.start.__command, "/ha perf start", "A's prefix")
  assertEqual(b.__panel().buttons.start.__command, "/hb perf start", "B's prefix")
  a.Cancel()
  a.HidePanel(); b.HidePanel()
end)

test("iso: clicking one host's panel drives that host only", function()
  local a, b = twoHosts()
  a.ShowPanel(); b.ShowPanel()
  a.__panel().buttons.start:__fire("OnClick")
  assertTrue(a.run, "A started")
  assertFalse(b.run, "B is untouched")
  a.Cancel()
  a.HidePanel(); b.HidePanel()
end)

-- ── panel / probe pairing across vendored copies ────────────────────────────────────────────
--
-- Two addons each vendor their own copy of the library, and LibStub picks one winner per major.
-- The panel counter alone cannot keep the pair together: two copies can carry the same panel minor
-- over different Perf.lua minors, and then the higher probe wins while the first-loaded copy's
-- panel stays bolted to it. These tests load real, minor-patched copies of both files into a fresh
-- environment and assert the two halves came from the same copy.

local Loader     = dofile("tests/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local function readSource(path)
  local f = assert(io.open(path, "r"))
  local src = f:read("*a")
  f:close()
  return src
end

local PERF_SRC  = readSource("LibKa0s/Perf.lua")
local PANEL_SRC = readSource("LibKa0s/PerfPanel.lua")

-- Patch a copy's two minors and stamp each half with the copy it came from, so the assertion can
-- name the mismatch rather than just observing that something is wrong. Every substitution is
-- counted: a pattern that silently stopped matching would turn these into tests of nothing.
local function copyOf(tag, perfMinor, panelMinor)
  local function sub(src, pattern, replacement, what)
    local out, n = src:gsub(pattern, replacement, 1)
    assertEqual(n, 1, "patching " .. what .. " in the real source")
    return out
  end
  local perf = sub(PERF_SRC, 'local MAJOR, MINOR = "LibKa0s%-Perf%-1%.0", 1',
    'local MAJOR, MINOR = "LibKa0s-Perf-1.0", ' .. perfMinor, "the probe minor")
  perf = sub(perf, "lib%.MAJOR, lib%.MINOR = MAJOR, MINOR",
    'lib.MAJOR, lib.MINOR = MAJOR, MINOR lib.__probeTag = "' .. tag .. '"', "the probe tag")
  local panel = sub(PANEL_SRC, "local PANEL_MINOR = 1",
    "local PANEL_MINOR = " .. panelMinor, "the panel minor")
  panel = sub(panel, "lib%.__panelProbeMinor = lib%.MINOR",
    'lib.__panelProbeMinor = lib.MINOR lib.__panelTag = "' .. tag .. '"', "the panel tag")
  return perf, panel
end

-- Load whole copies in the order the client would, each copy's two files together.
local function loadCopies(env, ...)
  for _, copy in ipairs({ ... }) do
    Loader.loadSource(copy.perf, copy.tag .. "/Perf.lua", env)
    Loader.loadSource(copy.panel, copy.tag .. "/PerfPanel.lua", env)
  end
  return env.LibStub("LibKa0s-Perf-1.0")
end

local function copy(tag, perfMinor, panelMinor)
  local perf, panel = copyOf(tag, perfMinor, panelMinor)
  return { tag = tag, perf = perf, panel = panel }
end

test("iso: a newer probe loading second brings its own panel with it", function()
  -- HostY ships probe 1 + panel 1, HostX ships probe 2 + panel 1. Y loads first. X's probe wins the
  -- LibStub race, so leaving Y's panel attached pairs X's probe with Y's __AttachPanel.
  local l = loadCopies(buildMocks(), copy("Y", 1, 1), copy("X", 2, 1))
  assertEqual(l.MINOR, 2, "the higher probe minor won")
  assertEqual(l.__probeTag, "X", "and it is X's probe")
  assertEqual(l.__panelTag, "X", "so the panel must be X's too, not Y's")
end)

test("iso: an older copy loading second replaces neither half", function()
  local l = loadCopies(buildMocks(), copy("X", 2, 1), copy("Y", 1, 1))
  assertEqual(l.MINOR, 2, "Y's probe lost the race, as LibStub intends")
  assertEqual(l.__probeTag, "X", "X's probe stands")
  assertEqual(l.__panelTag, "X", "and Y's panel must not clobber it")
end)

test("iso: a higher panel minor over the same probe still wins", function()
  local l = loadCopies(buildMocks(), copy("Y", 1, 1), copy("X", 1, 2))
  assertEqual(l.__panelTag, "X", "the panel counter still decides between panels")
end)
