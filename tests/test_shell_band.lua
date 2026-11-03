-- tests/test_shell_band.lua -- R5-L2 of Ka0sAddonsCommonTasks docs/2026-11-03-SMOKE_ROUND5 (feedback
-- item 3, images 34 to 37, 46, 49 and 50; the lead's call 3 in 00_PLAN.md): S.Shell's top band draws
-- above a backdrop window's own fill. It was a BACKGROUND -5 region of the window, and a
-- BackdropTemplate frame's Center piece is BACKGROUND at sublevel 0, so every window that relied on
-- the band without a child title bar showed none in any skin: DpsRace's four windows, and every
-- library window (the debug console, the copy window, the perf panel, the sim panels, the skin
-- picker). The band now sits at BACKGROUND sublevel P.BAND_SUB (3) on a backdrop frame, as P.box
-- puts a backdrop box's gradient at BACKGROUND 1 "over its fill"; a frame with no backdrop keeps -5
-- over its -8 fill region. The bottom bar is not moved (the skeptic's correction): LootHistory's
-- footer would otherwise gain a near-black strip. Toasts opt out (Toast minor 3, noTopBar), and a host
-- that paints Shell twice, once bare through Core.ApplySkin and once with its opts, keeps its opts on
-- a later bare call, so it ends with exactly one band (its own child title bar).
--
-- The kit's paint recorder keeps each region's layer and sublevel (mock_paint.lua's newRegion).

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse = K.test, K.assertEqual, K.assertTrue, K.assertFalse

local F = dofile("tests/fixture_skin_paint.lua")
local Bench = dofile("tests/fixture_skin_picker.lua")

local OWNER = "LootHistory"
local TOOL_FILES = { "Widgets", "WidgetsCopyWindow", "DebugLog", "DebugLogDiagnostics", "DebugLogGates",
  "DebugLogWindow", "Lifecycle", "Perf", "PerfSampler", "PerfCommands", "PerfPanel", "Sim", "SimTimeline",
  "SimPanel", "SimPanelRender", "Toast" }

local function env()
  local files = {}
  for _, f in ipairs(F.FILES) do files[#files + 1] = f end
  for _, f in ipairs(TOOL_FILES) do files[#files + 1] = f end
  local m, Skin = F.env({ files = files })
  m.__named = {}
  local create = m.CreateFrame
  m.CreateFrame = function(kind, name, ...)
    local f = create(kind, name, ...)
    if name then m.__named[name] = f end
    return f
  end
  return m, Skin
end

local function keys(Skin)
  local out = {}
  for _, def in ipairs(Skin:Skins()) do out[#out + 1] = def.key end
  return out
end

local function layerOf(t) return t.__layer, t.__sublevel or 0 end

--- The window's top band is shown, in BACKGROUND, above a backdrop's Center (sublevel 0).
local function assertBandOverFill(Skin, f, what)
  local top = F.region(Skin, f, "top")
  assertTrue(top ~= nil, what .. ": a top band")
  assertTrue(top:IsShown(), what .. ": the band is shown")
  local layer, sub = layerOf(top)
  assertEqual(layer, "BACKGROUND", what .. ": the band stays in BACKGROUND, under every host region")
  assertTrue(sub > 0, ("%s: the band's sublevel %d sits above the backdrop's Center at 0"):format(what, sub))
end

local function bandHidden(Skin, f)
  local top = F.region(Skin, f, "top")
  return top == nil or not top:IsShown()
end

-- ── the layer ────────────────────────────────────────────────────────────────────────────────

test("shell band: on a backdrop window the top band draws above the backdrop's fill, in every skin", function()
  -- red under: BACKGROUND -5, which the backdrop's Center (BACKGROUND 0) covered in every skin.
  local m, Skin = env()
  F.owner(Skin, OWNER)
  local S = Skin:For(OWNER)
  local f = F.window(m)
  S.Shell(f)
  for _, key in ipairs(keys(Skin)) do
    Skin:SetChoice(OWNER, "ka0s", key)
    assertBandOverFill(Skin, f, key)
  end
end)

test("shell band: the window gradient, its art and the bottom bar keep their sublevels", function()
  -- The lead's call 3: the top band only. LootHistory, the owner's reference window, is a backdrop
  -- frame with { noTopBar, bottomBar } and Ka0s Default's foot.bg at 0.9; lifting the bottom bar
  -- would draw a near-black footer strip it does not draw today.
  local m, Skin = env()
  local S = F.owner(Skin, OWNER, "midnight")   -- WoW Midnight: a window gradient
  local f = F.window(m)
  S.Shell(f, { noTopBar = true, bottomBar = 26 })
  local grad = F.region(Skin, f, "grad")
  assertEqual(select(2, layerOf(grad)), -7, "the window gradient at -7")
  local bottom = F.region(Skin, f, "bottom")
  local layer, sub = layerOf(bottom)
  assertEqual(layer, "BACKGROUND"); assertEqual(sub, -5, "the bottom bar at -5, unchanged")
  assertTrue(bandHidden(Skin, f), "noTopBar: no top band")
end)

test("shell band: a window with no backdrop keeps its band at -5 over its own fill", function()
  -- Premade Groups Filter Extension's portrait frame, whose band already showed (image 42).
  local m, Skin = env()
  local S = F.owner(Skin, OWNER)
  local f = F.window(m)
  rawset(f, "SetBackdrop", nil)
  S.Shell(f)
  local _, fillSub = layerOf(F.region(Skin, f, "fill"))
  local _, topSub = layerOf(F.region(Skin, f, "top"))
  assertEqual(fillSub, -8, "the fill region")
  assertEqual(topSub, -5, "the band, as before")
  assertTrue(F.region(Skin, f, "top"):IsShown())
end)

-- ── one band, however often a host paints ───────────────────────────────────────────────────

test("shell band: a host that paints Shell twice ends with its own title bar as the one band", function()
  -- Drop Watcher (Window.lua), WhatGroup (FrameLayout.lua then FrameSkin.lua) and MultiMeters
  -- (Window_Frame.lua's paintShell) call NS.ApplySkin(frame), a bare Shell through Core.ApplySkin,
  -- then Shell(frame, { noTopBar = true }) under a child title bar. red under: a later bare call
  -- (a refresh that runs NS.ApplySkin again) dropping noTopBar, so the now-visible Shell band
  -- showed behind the child bar.
  local m, Skin = env()
  F.owner(Skin, OWNER)
  local S = Skin:For(OWNER)
  local core = m.LibStub("LibKa0s-Core-1.0")
  local f = F.window(m)
  core.ApplySkin(f, nil, OWNER)
  S.Shell(f, { noTopBar = true })
  assertTrue(bandHidden(Skin, f), "after the two paints")
  core.ApplySkin(f, nil, OWNER)
  assertTrue(bandHidden(Skin, f), "a later bare paint keeps the host's noTopBar")
  for _, key in ipairs(keys(Skin)) do
    Skin:SetChoice(OWNER, "ka0s", key)
    assertTrue(bandHidden(Skin, f), key .. ": a switch replays the host's opts")
  end
  S.Shell(f, {})
  assertBandOverFill(Skin, f, "an explicit opts table is the host's new word")
end)

-- ── the library's windows ───────────────────────────────────────────────────────────────────

local function console(m, owner)
  local D = m.LibStub("LibKa0s-DebugLog-1.0"):New{
    name = "Band" .. owner, addonName = owner, title = "Host", font = "Interface\\Fonts\\ARIALN.TTF",
    isEnabled = function() return false end, setEnabled = function() end, print = function() end,
  }
  D:Show()
  return D, D._frameForTest
end

local function perf(m, owner)
  local lc = m.LibStub("LibKa0s-Lifecycle-1.0"):New{
    name = "BandPerf", standDown = function() end, standUp = function() end,
  }
  local P = m.LibStub("LibKa0s-Perf-1.0"):New{
    name = "BandPerf", addonName = owner, title = "Host", slash = "/host",
    sv = "ShellBandPerfDB", lifecycle = lc, log = function() end, print = function() end,
  }
  P.ShowPanel()
  return P.__panel()
end

local function sim(m, name)
  local Sim = m.LibStub("LibKa0s-Sim-1.0")
  local s = Sim:New{
    name = name, seam = Sim:NewSeam({ Probe = function() return "live" end }, { name = name }),
    slash = "/host sim", deliver = function() return 1 end, isStoodDown = function() return false end,
    scenarios = { names = { "one" }, defs = { one = { label = "One", timeline = function()
      return { { kind = "a", label = "Alpha" } }
    end } } },
    prepare = function(_, _, _, ready) ready() end, play = function() return "did" end,
    print = function() end, panel = {},
  }
  assertTrue(s:ShowPanel(), "ShowPanel")
  return m.__named[name .. "SimPanel"]
end

test("shell band: every library window shows the band, through every skin switch", function()
  -- The lead's call 3: the debug console (image 37), the copy window, the perf panel and the sim
  -- panel (images 49 and 50) are backdrop frames painted through Core.ApplySkin with their owner.
  local m, Skin = env()
  F.owner(Skin, OWNER)
  local D, con = console(m, OWNER)
  D:ShowCopy()
  local windows = {
    console = con, copy = D._copyFrameForTest, perf = perf(m, OWNER), sim = sim(m, OWNER),
  }
  for _, key in ipairs(keys(Skin)) do
    Skin:SetChoice(OWNER, "ka0s", key)
    for what, f in pairs(windows) do assertBandOverFill(Skin, f, key .. " " .. what) end
  end
end)

test("shell band: no frame the library paints with noTopBar draws a band", function()
  -- SimPanel.lua paints each of its buttons Shell(b, { noTopBar = true }); every such record, in
  -- every library window, keeps its band hidden through the switches.
  local m, Skin = env()
  F.owner(Skin, OWNER)
  local D = console(m, OWNER)
  D:ShowCopy()
  perf(m, OWNER)
  sim(m, OWNER)
  for _, key in ipairs({ "ka0s", "obsidian", "midnight" }) do
    Skin:SetChoice(OWNER, "ka0s", key)
    for frame, rec in pairs(Skin.painted) do
      local call = rec.calls.Shell
      local opts = call and call[1]
      if type(opts) == "table" and opts.noTopBar then
        assertTrue(bandHidden(Skin, frame), key .. ": a noTopBar frame wears no band")
      end
    end
  end
end)

test("shell band: the skin picker shows the band", function()
  local _, Skin, lib = Bench.env()
  local store = Bench.register(Skin, Bench.OWNER)
  local O = Bench.instance(lib, Bench.OWNER)
  local f = O.SkinPicker(Bench.specFor(store))
  for _, key in ipairs({ "ka0s", "obsidian", "glass", "midnight" }) do
    Skin:SetChoice(Bench.OWNER, "ka0s", key)
    assertBandOverFill(Skin, f, key .. " picker")
  end
end)

-- ── the toast opts out ───────────────────────────────────────────────────────────────────────

test("shell band: a toast draws no band, in any skin", function()
  -- A toast has no title bar (the lead's call 3). red under: Toast.decorate's bare Core.ApplySkin,
  -- which now shows a 30 px band across the top of DpsRace's and Drop Watcher's toasts.
  local m, Skin = env()
  F.owner(Skin, OWNER)
  local Toast = m.LibStub("LibKa0s-Toast-1.0")
  local t = Toast:New{ owner = OWNER, build = function() return 300, 50 end }
  t:Show("a")
  local f = t:Frame()
  assertTrue(Skin.painted[f] ~= nil, "the toast wears the owner's skin")
  for _, key in ipairs(keys(Skin)) do
    Skin:SetChoice(OWNER, "ka0s", key)
    assertTrue(bandHidden(Skin, f), key .. ": no band on the toast")
  end
  t:Show("b")
  assertFalse(not bandHidden(Skin, f), "a second payload repaints nothing back")
end)
