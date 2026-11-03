-- tests/test_header_band.lua -- R5-L3 of Ka0sAddonsCommonTasks docs/2026-11-03-SMOKE_ROUND5 (feedback
-- item 5, images 42 and 43; the lead's call 6 in 00_PLAN.md): every header child (the title, the close
-- mark, header buttons, chevrons) is anchored LEFT, CENTER or RIGHT to the title band's own frame at
-- y 0, in every window and every skin, so it sits on the band's geometric middle. S.Band(frame) is
-- that frame: an invisible holder S.Shell lays on every paint at its own inset (`win.borderSize` in
-- from a flat edge, else 1) and `title.height`, kept under `noTopBar`, and flush at the top and 25 px
-- high while EllesmereUI paints the owner. S.Header(frame, spec) places a header on it, the title by
-- `title.align` or the caller's `align` (DpsRace's HUD passes LEFT). Both are recorded, so a switch
-- lays and places them again. Every library window's header is on it.
--
-- Headless, only the anchor shape can be measured (the kit's FontString answers no string height):
-- a LEFT, CENTER or RIGHT point on the band at y 0 IS the band's vertical middle. The glyphs' own
-- baseline is the owner's smoke check.

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = K.test, K.assertEqual, K.assertTrue, K.assertNil

local F = dofile("tests/fixture_skin_paint.lua")
local E = dofile("tests/fixture_skin_eui.lua")
local Bench = dofile("tests/fixture_skin_picker.lua")

local OWNER = "LootHistory"
local TOOL_FILES = { "Widgets", "WidgetsCopyWindow", "DebugLog", "DebugLogDiagnostics", "DebugLogGates",
  "DebugLogWindow", "Lifecycle", "Perf", "PerfSampler", "PerfCommands", "PerfPanel", "Sim", "SimTimeline",
  "SimPanel", "SimPanelRender" }

--- Frames keep their anchors and sizes for this suite (the kit's frames take them without keeping
--- them); ClearAllPoints empties the anchors, SetAllPoints records its relative frame.
local function geometry(f)
  local st = { points = {} }
  rawset(f, "__geo", st)
  rawset(f, "SetPoint", function(_, ...) st.points[#st.points + 1] = { ... } end)
  rawset(f, "ClearAllPoints", function() st.points, st.all = {}, nil end)
  rawset(f, "SetAllPoints", function(self, rel) st.points, st.all = {}, rel or self:GetParent() end)
  rawset(f, "GetNumPoints", function() return #st.points end)
  rawset(f, "GetPoint", function(_, i) return unpack(st.points[i or 1] or {}) end)
  rawset(f, "SetHeight", function(_, h) st.h = h end)
  rawset(f, "GetHeight", function() return st.h or 0 end)
  rawset(f, "SetWidth", function(_, w) st.w = w end)
  rawset(f, "GetWidth", function() return st.w or 0 end)
  rawset(f, "SetSize", function(_, w, h) st.w, st.h = w, h end)
end

local function arm(m)
  m.__named = m.__named or {}
  local create = m.CreateFrame
  m.CreateFrame = function(kind, name, ...)
    local f = create(kind, name, ...)
    if type(f) == "table" then geometry(f) end
    if name then m.__named[name] = f end
    return f
  end
  return m
end

local function env()
  local files = {}
  for _, f in ipairs(F.FILES) do files[#files + 1] = f end
  for _, f in ipairs(TOOL_FILES) do files[#files + 1] = f end
  local m, Skin = F.env({ files = files })
  return arm(m), Skin
end

local function keys(Skin)
  local out = {}
  for _, def in ipairs(Skin:Skins()) do out[#out + 1] = def.key end
  return out
end

--- Where Shell paints the band under `key`: its inset and height.
local function expected(Skin, key)
  local t = Skin:ResolveSkin(key)
  local inset = (t["win.borderStyle"] or "flat") == "flat" and t["win.borderSize"] or 1
  return inset, t["title.height"] or 30
end

local function assertBandAt(b, f, inset, h, what)
  assertTrue(b ~= nil, what .. ": a band frame")
  local g = rawget(b, "__geo")
  assertEqual(#g.points, 2, what .. ": two anchors")
  local p1, r1, q1, x1, y1 = unpack(g.points[1])
  local p2, r2, q2, x2, y2 = unpack(g.points[2])
  assertEqual(p1 .. q1, "TOPLEFTTOPLEFT", what); assertTrue(r1 == f, what)
  assertEqual(x1, inset, what .. ": left inset"); assertEqual(y1, -inset, what .. ": top inset")
  assertEqual(p2 .. q2, "TOPRIGHTTOPRIGHT", what); assertTrue(r2 == f, what)
  assertEqual(x2, -inset, what .. ": right inset"); assertEqual(y2, -inset, what)
  assertEqual(g.h, h, what .. ": the band's height")
end

local CENTERED = { LEFT = true, CENTER = true, RIGHT = true }

--- `region` has exactly one point, LEFT, CENTER or RIGHT, on `band` at y 0: on its vertical middle.
--- A LEFT-aligned title may carry a second, RIGHT, point on the band at y 0 too.
local function assertOnBand(region, band, what)
  local n = region:GetNumPoints()
  assertTrue(n >= 1 and n <= 2, what .. ": anchored")
  for i = 1, n do
    local point, rel, relPoint, _, y = region:GetPoint(i)
    assertTrue(CENTERED[point], ("%s: a %s point, never TOP*"):format(what, tostring(point)))
    assertEqual(relPoint, point, what .. ": to the band's own " .. tostring(point))
    assertTrue(rel == band, what .. ": anchored to the band")
    assertEqual(y, 0, what .. ": y 0, the band's middle")
  end
end

-- ── S.Band ───────────────────────────────────────────────────────────────────────────────────

test("header band: Shell lays the band at its own inset and title.height, in every skin", function()
  -- red under: no band frame (each host re-derived the band, PGFE's titleBand, or hard-coded 1 and 30).
  local m, Skin = env()
  local S = F.owner(Skin, OWNER)
  local f = F.window(m)
  S.Shell(f)
  local seen = {}
  for _, key in ipairs(keys(Skin)) do
    Skin:SetChoice(OWNER, "ka0s", key)
    local inset, h = expected(Skin, key)
    local b = S.Band(f)
    assertBandAt(b, f, inset, h, key)
    seen[inset] = true
    assertTrue(F.region(Skin, f, "band") == b, key .. ": one holder, the record's")
  end
  assertTrue(seen[1] and seen[2], "the nine skins cover a 1 px and a 2 px inset")
end)

test("header band: the band is kept under noTopBar, and S.Band before Shell is the same frame", function()
  local m, Skin = env()
  local S = F.owner(Skin, OWNER, "midnight")
  local f = F.window(m)
  local early = S.Band(f)
  S.Shell(f, { noTopBar = true })
  assertTrue(S.Band(f) == early, "one holder")
  assertBandAt(early, f, 2, 30, "WoW Midnight under noTopBar")
  assertEqual(early:IsShown(), true)
end)

test("header band: under the EllesmereUI source the band is its 25 px bar, flush with the top", function()
  local m, Skin, eui = E.env()
  arm(m)
  local S = E.owner(Skin, OWNER, "eui", "midnight")
  local f = E.window(m)
  S.Shell(f)
  local title = f.title
  local close = m.CreateFrame("Button", nil, f)
  S.Header(f, { title = title, right = { close } })
  assertBandAt(S.Band(f), f, 2, 30, "WoW Midnight before EllesmereUI paints")
  eui.login()
  assertTrue(Skin.euiPainted[OWNER], "EllesmereUI paints the owner")
  local band = S.Band(f)
  assertBandAt(band, f, 0, 25, "EllesmereUI's bar")
  assertOnBand(title, band, "the title on EllesmereUI's bar")
  assertOnBand(close, band, "the close mark on EllesmereUI's bar")
end)

-- ── S.Header ─────────────────────────────────────────────────────────────────────────────────

--- A window with a title, two right controls and one left one, painted and placed.
local function headed(m, S, spec)
  local f = F.window(m)
  S.Shell(f)
  local close, gear = m.CreateFrame("Button", nil, f), m.CreateFrame("Button", nil, f)
  local chevron = m.CreateFrame("Button", nil, f)
  close:SetSize(18, 18); gear:SetSize(20, 20); chevron:SetSize(16, 16)
  local h = { title = f.title, right = { close, gear }, left = { chevron } }
  for k, v in pairs(spec or {}) do h[k] = v end
  S.Header(f, h)
  return f, close, gear, chevron
end

test("header: every child is on the band's middle, in every skin, through every switch", function()
  local m, Skin = env()
  local S = F.owner(Skin, OWNER)
  local f, close, gear, chevron = headed(m, S)
  for _, key in ipairs(keys(Skin)) do
    Skin:SetChoice(OWNER, "ka0s", key)
    local band = S.Band(f)
    local i, h = expected(Skin, key)
    assertBandAt(band, f, i, h, key)
    for what, r in pairs({ title = f.title, close = close, gear = gear, chevron = chevron }) do
      assertOnBand(r, band, key .. " " .. what)
    end
  end
end)

test("header: the controls chain in from the band's edges, and the title clears them", function()
  local m, Skin = env()
  local S = F.owner(Skin, OWNER)
  local f, close, gear, chevron = headed(m, S, { align = "LEFT" })
  assertEqual(select(4, close:GetPoint(1)), -6, "the close mark 6 in from the right")
  assertEqual(select(4, gear:GetPoint(1)), -(6 + 18 + 4), "the next one past it, 4 apart")
  assertEqual(select(4, chevron:GetPoint(1)), 6, "the chevron 6 in from the left")
  local point, _, _, x = f.title:GetPoint(1)
  assertEqual(point, "LEFT"); assertEqual(x, 6 + 16 + 4, "the title clears the chevron")
  assertEqual(f.title:GetJustifyH(), "LEFT")
  assertEqual(f.title:GetNumPoints(), 1, "one anchor, so a repaint leaves one")
end)

test("header: an entry may name its own width and offset", function()
  local m, Skin = env()
  local S = F.owner(Skin, OWNER)
  local f = F.window(m)
  S.Shell(f)
  local a, b = m.CreateFrame("Button", nil, f), m.CreateFrame("Button", nil, f)
  S.Header(f, { right = { { frame = a, x = 10, width = 30 }, { frame = b } } })
  assertEqual(select(4, a:GetPoint(1)), -10)
  assertEqual(select(4, b:GetPoint(1)), -(10 + 30 + 4), "chained past the named width")
end)

--- A skin that aligns its titles to `align`, worn by OWNER.
local function aligned(Skin, align)
  Skin:RegisterSkin({ key = "band" .. align, label = "Band", tokens = { ["title.align"] = align } })
  return F.owner(Skin, OWNER, "band" .. align)
end

test("header: the title follows the skin's title.align, and the caller's align wins", function()
  local m, Skin = env()
  local S = F.owner(Skin, OWNER)
  local f = headed(m, S)
  assertEqual((f.title:GetPoint(1)), "CENTER", "Ka0s Default centers")
  assertEqual(select(4, f.title:GetPoint(1)), 0)
  local g = headed(m, S, { align = "LEFT" })
  assertEqual((g.title:GetPoint(1)), "LEFT", "align LEFT under a CENTER skin (DpsRace's HUD)")
  aligned(Skin, "RIGHT")
  assertEqual((f.title:GetPoint(1)), "RIGHT", "a switch places the title again")
  assertEqual(select(4, f.title:GetPoint(1)), -(6 + 18 + 4 + 20 + 4), "clear of both right controls")
  assertEqual((g.title:GetPoint(1)), "LEFT", "the caller's align holds through a switch")
end)

test("header: a drag strip takes the band's whole rect", function()
  local m, Skin = env()
  local S = F.owner(Skin, OWNER, "midnight")
  local f = F.window(m)
  S.Shell(f)
  local strip = m.CreateFrame("Frame", nil, f)
  S.Header(f, { bars = { strip } })
  assertTrue(rawget(strip, "__geo").all == S.Band(f), "SetAllPoints on the band")
end)

-- ── the library's windows ────────────────────────────────────────────────────────────────────

local function console(m, owner)
  local D = m.LibStub("LibKa0s-DebugLog-1.0"):New{
    name = "Head" .. owner, addonName = owner, title = "Host", font = "Interface\\Fonts\\ARIALN.TTF",
    isEnabled = function() return false end, setEnabled = function() end, print = function() end,
  }
  D:Show()
  return D, D._frameForTest
end

local function perf(m, owner)
  local lc = m.LibStub("LibKa0s-Lifecycle-1.0"):New{
    name = "HeadPerf", standDown = function() end, standUp = function() end,
  }
  local P = m.LibStub("LibKa0s-Perf-1.0"):New{
    name = "HeadPerf", addonName = owner, title = "Host", slash = "/host",
    sv = "HeaderBandPerfDB", lifecycle = lc, log = function() end, print = function() end,
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

test("header: every library window's header is on its band, in every skin", function()
  -- red under: the console's and the copy window's bars at 1,-1 and the perf and sim panels'
  -- -(1 + TITLE_H / 2), a px high under a 2 px edge (WoW Midnight).
  local m, Skin = env()
  local S = F.owner(Skin, OWNER)
  local D, con = console(m, OWNER)
  D:ShowCopy()
  local copy = D._copyFrameForTest
  local pf, sf = perf(m, OWNER), sim(m, OWNER)
  for _, key in ipairs(keys(Skin)) do
    Skin:SetChoice(OWNER, "ka0s", key)
    local b = S.Band(con)
    local i, h = expected(Skin, key)
    assertBandAt(b, con, i, h, key .. " console")
    assertOnBand(con.title, b, key .. " console title")
    for what, c in pairs({ clear = con.clearButton, copy = con.copyButton, toggle = con.debugToggleBtn }) do
      assertOnBand(c, b, key .. " console " .. what)
    end
    assertTrue(rawget(con.title:GetParent(), "__geo").all == b, key .. ": the console's drag bar is the band")
    local cb = S.Band(copy)
    assertOnBand(copy.title, cb, key .. " copy title")
    assertOnBand(copy.closeButton, cb, key .. " copy close")
    for what, f in pairs({ perf = pf, sim = sf }) do
      local fb = S.Band(f)
      assertBandAt(fb, f, i, h, key .. " " .. what)
      assertOnBand(f.title, fb, key .. " " .. what .. " title")
      assertOnBand(f.closeButton, fb, key .. " " .. what .. " close")
    end
  end
end)

test("header: the skin picker's title and close are on its band", function()
  local m, Skin, lib = Bench.env()
  arm(m)
  local store = Bench.register(Skin, Bench.OWNER)
  local O = Bench.instance(lib, Bench.OWNER)
  local f = O.SkinPicker(Bench.specFor(store))
  local S = Skin:For(Bench.OWNER)
  for _, key in ipairs({ "ka0s", "midnight", "glass" }) do
    Skin:SetChoice(Bench.OWNER, "ka0s", key)
    local b = S.Band(f)
    assertOnBand(f.title, b, key .. " picker title")
    assertOnBand(f.close, b, key .. " picker close")
  end
end)

test("header: a window with no skin owner keeps its own anchors", function()
  local m = env()
  local _, con = console(m, "Nobody")
  assertNil(rawget(con.title:GetParent(), "__geo").all, "the bar keeps its 1,-1 anchors")
  assertEqual((con.title:GetPoint(1)), "CENTER")
end)
