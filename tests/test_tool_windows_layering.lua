-- tests/test_tool_windows_layering.lua — where the library's three tool windows sit (v1.77.0): the
-- debug console (DebugLog minor 21), the perf panel (PerfPanel minor 9) and the sim panel (SimPanel
-- minor 6) are DIALOG, toplevel and clamped, and each re-raises a shown Blizzard StaticPopup when it
-- shows, through Core minor 12's `RaiseStaticPopups`. The copy window the console opens is NOT
-- toplevel: it sits one strata above its opener (FULLSCREEN), and a toplevel FULLSCREEN window would
-- rise over a host's FULLSCREEN modal band on show (XS-12).
--
-- Every case installs the kit's frame-layer recorder (tests/_kit/mock_layers.lua) and restores it,
-- so strata, toplevel, clamp and Raise counts read back. The mock's Show fires no OnShow (the
-- client's does), so `opened` fires it after the public Show, which is what the client does.
--
-- The StaticPopups are read by Core as `_G["StaticPopup" .. i]`, and the loader's environment falls
-- through to the real global table for `_G`, so the popups are installed there and removed after.

local T = _G.LK_TEST
local core, debuglog, mocks = T.core, T.debuglog, T.mocks
local test, assertEqual, assertTrue, assertFalse =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse
local Fixture = dofile("tests/fixture.lua")
local SimF = dofile("tests/fixture_sim_panel.lua")

local POPUPS = { "StaticPopup1", "StaticPopup2", "StaticPopup3", "StaticPopup4", "STATICPOPUP_NUMDIALOGS" }

--- Run `fn(m)` with the layer recorder installed on `m` (default the shared mocks), and every
--- StaticPopup global cleared before and after, so no case leaks a popup into another.
local function layered(fn, m)
  m = m or mocks
  local restore = dofile("tests/_kit/mock_layers.lua")(m)
  local saved = {}
  for _, k in ipairs(POPUPS) do saved[k] = rawget(_G, k); _G[k] = nil end
  local ok, err = pcall(fn, m)
  for _, k in ipairs(POPUPS) do _G[k] = saved[k] end
  restore()
  if not ok then error(err, 0) end
end

--- A popup built on `m` under the recorder, so its Raise is counted; shown or hidden.
local function popup(m, name, shown)
  local p = m.CreateFrame("Frame", name, m.UIParent)
  if shown then p:Show() else p:Hide() end
  _G[name] = p
  return p
end

local function opened(f)
  f:Show()
  f:__fire("OnShow")
  return f
end

local function newConsole(name)
  local enabled = false
  return debuglog:New{
    name = name, title = "Test Host", font = "Interface\\Fonts\\FRIZQT__.TTF",
    isEnabled = function() return enabled end, setEnabled = function(v) enabled = v end,
    print = function() end,
  }
end

local function consoleFrame(name)
  local D = newConsole(name)
  D:Show()
  return D._frameForTest, D
end

local function perfFrame()
  local p = Fixture.new()
  p.ShowPanel()
  return p.__panel()
end

--- A minimal sim bench on its own environment `m`: one scenario, ready at once, panel shown.
local function simFrame(m, Sim)
  local seam = Sim:NewSeam({ Probe = function() return "live" end }, { name = "Host" })
  local sim = Sim:New{
    name = "Host", seam = seam, slash = "/host sim",
    deliver = function() return 1 end,
    isStoodDown = function() return false end,
    scenarios = { names = { "one" }, defs = { one = { label = "One", timeline = function()
      return { { kind = "a", label = "Alpha" } }
    end } } },
    prepare = function(_, _, _, ready) ready() end,
    play = function() return "did" end,
    print = function() end,
    panel = {},
  }
  SimF.recording(m, function() assertTrue(sim:ShowPanel(), "ShowPanel") end)
  return m.__named["HostSimPanel"]
end

--- Run `fn(label, frame)` over a fresh build of each of the three windows. The sim panel lives on
--- its own environment, with the recorder installed on that one.
local built = 0
local function eachWindow(fn)
  built = built + 1
  layered(function()
    fn("console", consoleFrame("LayerConsole" .. built))
    fn("perf panel", perfFrame())
  end)
  local m, Sim = SimF.env()
  layered(function() fn("sim panel", simFrame(m, Sim)) end, m)
end

-- ── where the windows sit ─────────────────────────────────────────────────────────────────

test("tool windows: the console, the perf panel and the sim panel are DIALOG, toplevel and clamped", function()
  -- red under: drop frame:SetToplevel(true) from any of the three
  local seen = 0
  eachWindow(function(label, f)
    assertTrue(type(f) == "table", label .. " built")
    assertEqual(f:GetFrameStrata(), "DIALOG", label .. " strata")
    assertTrue(f:IsToplevel(), label .. " is toplevel")
    assertTrue(f:IsClampedToScreen(), label .. " is clamped")
    seen = seen + 1
  end)
  assertEqual(seen, 3)
end)

test("tool windows: the console's copy window is FULLSCREEN and not toplevel", function()
  -- red under: SetToplevel on CopyWindow's frame (Widgets.lua), which XS-12 rules out
  layered(function()
    local _, D = consoleFrame("LayerCopy")
    D:Add("T", "a line")
    D:ShowCopy()
    local c = D._copyFrameForTest
    assertEqual(c:GetFrameStrata(), "FULLSCREEN")
    assertFalse(c:IsToplevel(), "the copy window is not toplevel")
  end)
end)

-- ── the popup re-raise ────────────────────────────────────────────────────────────────────

test("tool windows: showing each window raises a shown StaticPopup once and a hidden one never", function()
  -- red under: drop the OnShow raisePopups hook from any of the three
  local seen = 0
  local function check(label, build, m)
    local shown, hidden = popup(m, "StaticPopup1", true), popup(m, "StaticPopup2", false)
    opened(build())
    assertEqual(m.__layers(shown).raised, 1, label .. ": the shown popup raised once")
    assertEqual(m.__layers(hidden).raised, 0, label .. ": the hidden popup never")
    seen = seen + 1
  end
  layered(function(m)
    check("console", function() return consoleFrame("LayerRaise") end, m)
  end)
  layered(function(m) check("perf panel", perfFrame, m) end)
  local m, Sim = SimF.env()
  layered(function() check("sim panel", function() return simFrame(m, Sim) end, m) end, m)
  assertEqual(seen, 3)
end)

test("tool windows: with no StaticPopup globals nothing is raised and nothing errors", function()
  eachWindow(function(label, f)
    opened(f)
    assertTrue(f:IsShown(), label .. " shown")
  end)
  layered(function() assertEqual(core.RaiseStaticPopups(), 0) end)
end)

test("tool windows: an erroring Raise on a popup is swallowed", function()
  layered(function(m)
    local p = popup(m, "StaticPopup1", true)
    rawset(p, "Raise", function() error("boom") end)
    local f = opened(consoleFrame("LayerRaiseErr"))
    assertTrue(f:IsShown(), "the console still showed")
    assertEqual(core.RaiseStaticPopups(), 0, "a failed raise is not counted")
  end)
end)

test("core: RaiseStaticPopups answers the count raised and honors STATICPOPUP_NUMDIALOGS", function()
  -- red under: a hard-coded 4 in place of STATICPOPUP_NUMDIALOGS
  layered(function(m)
    local a, b = popup(m, "StaticPopup1", true), popup(m, "StaticPopup2", false)
    local c = popup(m, "StaticPopup3", true)
    assertEqual(core.RaiseStaticPopups(), 2, "four slots by default: 1 and 3")
    assertEqual(m.__layers(a).raised, 1); assertEqual(m.__layers(b).raised, 0)
    assertEqual(m.__layers(c).raised, 1)
    _G.STATICPOPUP_NUMDIALOGS = 2
    assertEqual(core.RaiseStaticPopups(), 1, "two slots: 1 only")
    assertEqual(m.__layers(c).raised, 1, "the third is outside the client's count")
    _G.StaticPopup4 = { IsShown = true }   -- not a frame: skipped, no error
    _G.STATICPOPUP_NUMDIALOGS = 4
    assertEqual(core.RaiseStaticPopups(), 2)
  end)
end)

test("core: RaiseStaticPopups never shows, hides or re-stratas a popup", function()
  layered(function(m)
    local p = popup(m, "StaticPopup1", true)
    p:SetFrameStrata("DIALOG")
    core.RaiseStaticPopups()
    assertTrue(p:IsShown()); assertEqual(p:GetFrameStrata(), "DIALOG")
    assertFalse(p:IsToplevel(), "no SetToplevel on a Blizzard frame")
    local h = popup(m, "StaticPopup2", false)
    core.RaiseStaticPopups()
    assertFalse(h:IsShown(), "a hidden popup stays hidden")
  end)
end)

-- ── an older vendored Core ────────────────────────────────────────────────────────────────

test("tool windows: with no RaiseStaticPopups in Core the three windows build and show", function()
  -- red under: calling core.RaiseStaticPopups unguarded in any window's OnShow
  local function withoutRaise(c, fn)
    local real = c.RaiseStaticPopups
    c.RaiseStaticPopups = nil
    local ok, err = pcall(fn)
    c.RaiseStaticPopups = real
    if not ok then error(err, 0) end
  end
  withoutRaise(core, function()
    layered(function(m)
      local p = popup(m, "StaticPopup1", true)
      assertTrue(opened(consoleFrame("LayerOldCore")):IsShown(), "console")
      assertTrue(opened(perfFrame()):IsShown(), "perf panel")
      assertEqual(m.__layers(p).raised, 0, "nothing raised without the helper")
    end)
  end)
  local m, Sim = SimF.env()
  withoutRaise(m.LibStub("LibKa0s-Core-1.0"), function()
    layered(function() assertTrue(opened(simFrame(m, Sim)):IsShown(), "sim panel") end, m)
  end)
end)
