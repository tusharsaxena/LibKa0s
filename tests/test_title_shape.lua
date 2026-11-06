-- tests/test_title_shape.lua -- cause L9 of Ka0sAddonsCommonTasks docs/2026-11-01-FULL_SKINNING, the
-- library's half: one title bar shape. The console, the copy window, the perf panel and the sim panel
-- all draw a bar as high as `title.height`, the band S.Shell paints (row 698), and S.TitleBar's
-- `opts.place` gives a hand-built bar the token's height and places its text by `title.align`, which
-- justifying a string with no width to justify in cannot do (the hosts' rows).

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = K.test, K.assertEqual, K.assertTrue, K.assertNil

local F = dofile("tests/fixture_skin_paint.lua")

local OWNER = "LootHistory"
local TOOL_FILES = { "Widgets", "WidgetsDropdown", "WidgetsCopyWindow", "DebugLog", "DebugLogDiagnostics", "DebugLogGates",
  "DebugLogWindow", "Lifecycle", "Perf", "PerfSampler", "PerfCommands", "PerfPanel", "Sim", "SimTimeline",
  "SimPanel", "SimPanelRender" }

--- The paint mock's frames take sizes and anchors without keeping them: this suite reads both.
local function geometry(f)
  local points = {}
  rawset(f, "SetHeight", function(self, h) rawset(self, "__testH", h) end)
  rawset(f, "GetHeight", function(self) return rawget(self, "__testH") or 0 end)
  rawset(f, "SetPoint", function(_, ...) points[#points + 1] = { ... } end)
  rawset(f, "GetPoint", function(_, i) return unpack(points[i or 1] or {}) end)
end

local function env()
  local files = {}
  for _, f in ipairs(F.FILES) do files[#files + 1] = f end
  for _, f in ipairs(TOOL_FILES) do files[#files + 1] = f end
  local m, Skin = F.env({ files = files })
  m.__named = {}
  local create = m.CreateFrame
  m.CreateFrame = function(kind, name, ...)
    local f = create(kind, name, ...)
    geometry(f)
    if name then m.__named[name] = f end
    return f
  end
  return m, Skin
end

local function tokenHeight(Skin) return Skin:ResolveSkin("ka0s")["title.height"] end

local function console(m, owner)
  local D = m.LibStub("LibKa0s-DebugLog-1.0"):New{
    name = "Host", addonName = owner, title = "Host", font = "Interface\\Fonts\\ARIALN.TTF",
    isEnabled = function() return false end, setEnabled = function() end, print = function() end,
  }
  D:Show()
  return D._frameForTest
end

local function perf(m, owner)
  local lc = m.LibStub("LibKa0s-Lifecycle-1.0"):New{
    name = "PerfHost", standDown = function() end, standUp = function() end,
  }
  local P = m.LibStub("LibKa0s-Perf-1.0"):New{
    name = "PerfHost", addonName = owner, title = "Host", slash = "/host",
    sv = "TitleShapePerfDB", lifecycle = lc, log = function() end, print = function() end,
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

-- ── row 698: the tool windows ────────────────────────────────────────────────────────────────

test("title shape: the console's bar is the skin's title.height", function()
  local m, Skin = env()
  assertEqual(console(m, nil).title:GetParent():GetHeight(), tokenHeight(Skin))
end)

test("title shape: the copy window's bar is the skin's title.height, and the text clears it", function()
  local m, Skin = env()
  local W = m.LibStub("LibKa0s-Widgets-1.0")
  local f = W.CopyWindow({ addonName = "NoSkin", name = "Shape" }):Show("x")
  local h = tokenHeight(Skin)
  assertEqual(f.title:GetParent():GetHeight(), h)
  local _, _, y = f.scroll:GetPoint(1)
  assertTrue(-y > h + 1, "the scroll starts under the bar")
end)

--- The panels have no bar: the title sits on the middle of the band S.Shell paints, one px in.
local function assertCenteredOnBand(f, h, what)
  local point, rel, relPoint, x, y = f.title:GetPoint(1)
  assertEqual(point, "CENTER", what); assertTrue(rel == f, what); assertEqual(relPoint, "TOP", what)
  assertEqual(x, 0, what); assertEqual(y, -(1 + h / 2), what)
end

test("title shape: the perf panel's title sits on the band's middle, with its close", function()
  local m, Skin = env()
  local h = tokenHeight(Skin)
  local f = perf(m, nil)
  assertCenteredOnBand(f, h, "perf")
  local _, _, _, _, y = f.closeButton:GetPoint(1)
  assertEqual(y, -(1 + (h - 18) / 2), "the close mark on the same middle")
end)

test("title shape: the sim panel's title sits on the band's middle, with its close", function()
  local m, Skin = env()
  local h = tokenHeight(Skin)
  local f = sim(m, "ShapeSim")
  assertCenteredOnBand(f, h, "sim")
  local _, _, _, _, y = f.closeButton:GetPoint(1)
  assertEqual(y, -(1 + (h - 18) / 2), "the close mark on the same middle")
end)

-- ── the hosts' rows: S.TitleBar's opts.place ─────────────────────────────────────────────────

--- A bar 22 high, its title anchored TOPLEFT by hand.
local function handBuilt(m)
  local bar = m.CreateFrame("Frame", nil, m.UIParent)
  bar:SetHeight(22)
  bar.title = bar:CreateFontString()
  bar.title:SetPoint("TOPLEFT", bar, "TOPLEFT", 3, -3)
  return bar
end

test("title shape: opts.place takes title.height and centers the text under Ka0s Default", function()
  local m, Skin = env()
  local S = F.owner(Skin, OWNER)
  local bar = handBuilt(m)
  S.TitleBar(bar, { place = true })
  assertEqual(bar:GetHeight(), tokenHeight(Skin))
  assertEqual(bar.title:GetNumPoints(), 1, "the hand-placed anchor is gone")
  local point, rel, relPoint, x, y = bar.title:GetPoint(1)
  assertEqual(point, "CENTER"); assertTrue(rel == bar); assertEqual(relPoint, "CENTER")
  assertEqual(x, 0); assertEqual(y, 0)
end)

test("title shape: without opts.place the bar and its anchors are the host's", function()
  local m, Skin = env()
  local S = F.owner(Skin, OWNER)
  local bar = handBuilt(m)
  S.TitleBar(bar)
  assertEqual(bar:GetHeight(), 22)
  assertEqual((bar.title:GetPoint(1)), "TOPLEFT")
end)

--- A skin that aligns its titles to `align`, worn by OWNER.
local function aligned(Skin, align)
  Skin:RegisterSkin({ key = "shape" .. align, label = "Shape", tokens = { ["title.align"] = align } })
  return F.owner(Skin, OWNER, "shape" .. align)
end

test("title shape: a skin's alignment places the text, clear of what the host reserved", function()
  local m, Skin = env()
  local S = aligned(Skin, "LEFT")
  local bar = handBuilt(m)
  S.TitleBar(bar, { place = { left = 40, right = 60 } })
  local point, rel, relPoint, x = bar.title:GetPoint(1)
  assertEqual(point, "LEFT"); assertTrue(rel == bar); assertEqual(relPoint, "LEFT"); assertEqual(x, 40)
  assertEqual(bar.title:GetJustifyH(), "LEFT", "and it is still justified")
end)

test("title shape: a right-aligned skin measures in from the right, 8 px unless reserved", function()
  local m, Skin = env()
  local S = aligned(Skin, "RIGHT")
  local bar = handBuilt(m)
  S.TitleBar(bar, { place = true })
  local point, _, _, x = bar.title:GetPoint(1)
  assertEqual(point, "RIGHT"); assertEqual(x, -8)
  S.TitleBar(bar, { place = { right = 60 } })
  point, _, _, x = bar.title:GetPoint(1)
  assertEqual(point, "RIGHT"); assertEqual(x, -60)
  assertEqual(bar.title:GetNumPoints(), 1, "a repaint leaves one anchor")
end)

test("title shape: a live switch places the text again", function()
  local m, Skin = env()
  local S = aligned(Skin, "LEFT")
  local bar = handBuilt(m)
  S.TitleBar(bar, { place = true })
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertEqual((bar.title:GetPoint(1)), "CENTER")
end)

test("title shape: placing a bar with no text still takes the height", function()
  local m, Skin = env()
  local S = F.owner(Skin, OWNER)
  local bar = m.CreateFrame("Frame", nil, m.UIParent)
  S.TitleBar(bar, { place = true })
  assertEqual(bar:GetHeight(), tokenHeight(Skin))
  assertNil(rawget(bar, "title"))
end)
