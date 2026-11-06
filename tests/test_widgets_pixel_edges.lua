-- tests/test_widgets_pixel_edges.lua -- every Widgets edge of 1 UI unit on a host surface draws ONE
-- PHYSICAL PIXEL (Core minor 16, Widgets minor 24, WidgetsAutocomplete minor 8, SkinPaint minor 19,
-- SkinPaintExtras minor 18; SF1-L1 of Ka0sAddonsCommonTasks docs/2026-11-06-REVENDOR_LIBKA0S_V1_89).
--
-- The owner measured DropWatcher's dropdown at 2 px on top and 1 at the bottom, where LootHistory's,
-- the same W.Dropdown, read 1 and 1: a backdrop's `edgeSize = 1` is one UI UNIT, and at a UI scale
-- where a unit is not a pixel it lands on 1 or 2 by the frame's sub-pixel position. Every case runs at
-- a scale where it is not: PixelUtil's factor 0.75 over an effective scale of 1.5, so one physical
-- pixel is 0.5 UI units, and red under the old code reads 1.
--
-- Pinned: the edge (and the inset the fill sits in) is the pixel size with no skin and under a flat
-- and a non-flat skin; GetBackdrop answers what was asked for; a UI scale change and an ancestor's
-- SetScale re-size it, colors kept; the backdrop's pieces are snapped to the pixel grid.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local F = dofile("tests/fixture_skin_paint.lua")

local OWNER = "LootHistory"
local WFILES = { "Widgets", "WidgetsDropdown", "WidgetsReorder", "WidgetsDragHandle", "WidgetsLineChart", "WidgetsAutocomplete",
                 "WidgetsCopyWindow" }
local PIECES = { "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
                 "TopEdge", "BottomEdge", "LeftEdge", "RightEdge", "Center" }

--- A client whose frames answer `scale.v` as their effective scale (1.5 to start), PixelUtil's
--- factor 0.75, and a hooksecurefunc that post-hooks for real. A frame answers its parent and its
--- last SetScale, and its last SetParent. `noSkin` loads Core and Widgets alone. Answers m, Skin (nil without it), W, scale.
local function env(noSkin)
  local files = {}
  for _, f in ipairs(noSkin and { "Core", "CorePixel" } or F.FILES) do files[#files + 1] = f end
  for _, f in ipairs(WFILES) do files[#files + 1] = f end
  local m, Skin = F.env({ files = files })
  m.__cursorX, m.__cursorY = 100, 100
  local scale = { v = 1.5 }
  m.PixelUtil = { GetPixelToUIUnitFactor = function() return 0.75 end }
  m.hooksecurefunc = function(t, name, fn)
    local orig = t[name]
    rawset(t, name, function(...) local r = orig(...); fn(...); return r end)
  end
  local make = m.CreateFrame
  m.CreateFrame = function(kind, name, parent, ...)
    local f = make(kind, name, parent, ...)
    rawset(f, "GetEffectiveScale", function() return scale.v end)
    local setParent = f.SetParent
    rawset(f, "GetParent", function(self) return rawget(self, "__lkParent") or parent end)
    rawset(f, "SetParent", function(self, p, ...)
      rawset(self, "__lkParent", p)
      if setParent then return setParent(self, p, ...) end
    end)
    rawset(f, "GetScale", function(self) return rawget(self, "__s") or 1 end)
    rawset(f, "SetScale", function(self, s) rawset(self, "__s", s) end)
    return f
  end
  return m, Skin, m.LibStub("LibKa0s-Widgets-1.0"), scale
end

local function drawn(m, f) return m.__paint(f).backdrop end

--- `f`'s drawn backdrop is `px` physical-pixel units thick on every side, its fill inset by the same
--- (`insets` false: a menu, which has none).
local function assertPixel(m, f, px, what, insets)
  local bd = drawn(m, f)
  assertTrue(type(bd) == "table", what .. ": a backdrop is drawn")
  assertEqual(bd.edgeSize, px, what .. ": the edge is one physical pixel, not one UI unit")
  if insets == false then return end
  for _, side in ipairs({ "left", "right", "top", "bottom" }) do
    assertEqual(bd.insets[side], px, what .. ": the fill's " .. side .. " inset is the edge's")
  end
end

local function rgba(c) return F.rgba(c) end

-- ── no skin ──────────────────────────────────────────────────────────────────────────────────

test("pixel edges: the dropdown, the search box and the shared menu are one physical pixel with no skin", function()
  local m, _, W = env(true)
  local parent = m.CreateFrame("Frame", nil, m.UIParent)
  local dd = W.Dropdown(parent, 120, {})
  assertPixel(m, dd, 0.5, "dropdown")
  assertEqual(dd:GetBackdrop().edgeSize, 1, "GetBackdrop answers the table as asked for: 1 px")
  assertEqual(rgba(m.__paint(dd).backdropBorderColor), "0.240,0.240,0.270,0.900", "its line color kept")
  local box = W.SearchBox(parent, 100, { hint = "Search" })
  assertPixel(m, box, 0.5, "search box")
  local menu = W.ContextMenu(parent, { { label = "One" }, { label = "More", submenu = { { label = "Two" } } } })
  assertPixel(m, menu, 0.5, "the shared menu", false)
  assertEqual(rgba(m.__paint(menu).backdropBorderColor), "0,0,0,1", "the menu's black edge kept")
  menu.buttons[2]:__fire("OnClick")
  assertTrue(menu.__child ~= nil, "the cascade opened a level")
  assertPixel(m, menu.__child, 0.5, "a cascading level", false)
end)

test("pixel edges: the autocomplete list is one physical pixel", function()
  local m, _, W = env(true)
  local box = W.SearchBox(m.UIParent, 100, {})
  rawset(box, "GetText", function() return "ab" end)
  local h = W.Autocomplete(box, { provider = function() return { { text = "One" } } end })
  h:Refresh()
  assertPixel(m, h.__list, 0.5, "autocomplete list", false)
end)

test("pixel edges: a UI scale change and an ancestor's SetScale re-size the edge, colors kept", function()
  local m, _, W, scale = env(true)
  local win = m.CreateFrame("Frame", nil, m.UIParent)
  local dd = W.Dropdown(win, 120, {})
  scale.v = 3
  m.UIParent:__fire("OnSizeChanged", 1280, 720)   -- a UI scale change resizes UIParent
  assertPixel(m, dd, 0.25, "dropdown after the UI scale moved")
  assertEqual(rgba(m.__paint(dd).backdropColor), "0.100,0.100,0.120,0.900", "the fill color kept")
  assertEqual(rgba(m.__paint(dd).backdropBorderColor), "0.240,0.240,0.270,0.900", "the line color kept")
  scale.v = 0.75
  win:SetScale(0.5)
  assertPixel(m, dd, 1, "dropdown after its window's SetScale")
  assertEqual(#m.__registrations(), 0, "hooks, never an event registration")
end)

test("pixel edges: the shared menu re-sizes on a UI scale change", function()
  local m, _, W, scale = env(true)
  local menu = W.ContextMenu(m.UIParent, { { label = "One" } })
  scale.v = 3
  m.UIParent:__fire("OnSizeChanged", 1280, 720)
  assertPixel(m, menu, 0.25, "menu after the UI scale moved", false)
  assertEqual(rgba(m.__paint(menu).backdropBorderColor), "0,0,0,1", "its edge color kept")
end)

test("pixel edges: a re-laid backdrop's pieces are snapped to the pixel grid", function()
  -- red under: the template's pieces left unsnapped, which smears a 1 px edge at a fractional
  -- position over two pixels at partial alpha.
  local m, _, W, scale = env(true)
  local dd = W.Dropdown(m.UIParent, 120, {})
  for _, k in ipairs(PIECES) do rawset(dd, k, dd:CreateTexture()) end
  scale.v = 2
  m.UIParent:__fire("OnSizeChanged", 1280, 720)
  for _, k in ipairs(PIECES) do assertTrue(rawget(dd, k).__snap == true, k .. " snapped") end
end)

-- ── under a skin ─────────────────────────────────────────────────────────────────────────────

test("pixel edges: an owned dropdown and search box keep one physical pixel through a flat skin's paint", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  local dd = W.Dropdown(m.UIParent, 120, { owner = OWNER })
  local box = W.SearchBox(m.UIParent, 100, { owner = OWNER })
  assertTrue(Skin.painted[dd] ~= nil, "the skin painted the dropdown")
  assertPixel(m, dd, 0.5, "owned dropdown")
  assertPixel(m, box, 0.5, "owned search box")
  box:__fire("OnEditFocusGained")
  assertPixel(m, box, 0.5, "the focus line too")
  local menu = W.ContextMenu(m.UIParent, { { label = "One" } }, { owner = OWNER })
  assertPixel(m, menu, 0.5, "the owned menu", false)
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertPixel(m, dd, 0.5, "after a skin switch")
end)

test("pixel edges: under a non-flat skin the holder's edge is one physical pixel and re-sizes", function()
  -- WoW Default draws inputs in a 1 px bevelIn edge on the holder, not in the backdrop.
  local m, Skin, W, scale = env()
  F.owner(Skin, OWNER, "wow")
  assertTrue(Skin:Token(OWNER, "input.borderStyle") ~= "flat", "the case needs a non-flat input edge")
  local dd = W.Dropdown(m.UIParent, 120, { owner = OWNER })
  local top = F.region(Skin, dd, "edgeTop")
  assertTrue(top ~= nil and top:IsShown(), "the edge is on the holder")
  local n = Skin:Token(OWNER, "input.borderSize") or 1
  assertEqual(top:GetHeight(), 0.5 * n, "input.borderSize physical pixels")
  assertEqual(F.region(Skin, dd, "edgeLeft"):GetWidth(), 0.5 * n)
  scale.v = 3
  m.UIParent:__fire("OnSizeChanged", 1280, 720)
  assertEqual(F.region(Skin, dd, "edgeTop"):GetHeight(), 0.25 * n, "re-sized on a UI scale change")
end)

-- ── the three lines drawn as textures (SF2-L1, Widgets minor 25, WidgetsReorder minor 6,
-- WidgetsDragHandle minor 13) ─────────────────────────────────────────────────────────────────
--
-- The SF1-L1 review left three lines on one UI unit: the shared menu's divider rule, the ReorderList
-- row boxes (ROW_BOX.EDGE_SIZE = 1) and the DragHandle strips. Each is a texture, not a backdrop, so
-- its thickness is its height (a horizontal line) or its width (a vertical one). Red under the old
-- code: every one reads 1, and stays 1 after the scale moves.

--- A box's or a strip's four edges, top, bottom, left, right: the two across are `px` high and the
--- two down are `px` wide.
local function assertEdges(edges, px, what)
  assertEqual(#edges, 4, what .. ": four edges")
  assertEqual(edges[1]:GetHeight(), px, what .. ": the top edge is one physical pixel high")
  assertEqual(edges[2]:GetHeight(), px, what .. ": the bottom edge is one physical pixel high")
  assertEqual(edges[3]:GetWidth(), px, what .. ": the left edge is one physical pixel wide")
  assertEqual(edges[4]:GetWidth(), px, what .. ": the right edge is one physical pixel wide")
end

test("pixel lines: the menu's divider rule is one physical pixel high at every cascade depth, and re-sizes", function()
  local m, _, W, scale = env(true)
  local rows = { { label = "One" }, { divider = true },
                 { label = "More", submenu = { { label = "Two" }, { divider = true }, { label = "Three" } } } }
  local menu = W.ContextMenu(m.UIParent, rows)
  local rule = menu.buttons[2].__rule
  assertTrue(rule:IsShown(), "the divider row draws its rule")
  assertEqual(rule:GetHeight(), 0.5, "the rule is one physical pixel, not one UI unit")
  menu.buttons[3]:__fire("OnClick")
  local child = menu.__child
  assertTrue(child ~= nil, "the cascade opened a level")
  local deep = child.buttons[2].__rule
  assertTrue(deep:IsShown(), "the cascading level's divider draws its rule")
  assertEqual(deep:GetHeight(), 0.5, "a cascading level's rule is one physical pixel")
  scale.v = 3
  m.UIParent:__fire("OnSizeChanged", 1280, 720)
  assertEqual(rule:GetHeight(), 0.25, "the rule re-sized on a UI scale change")
  assertEqual(deep:GetHeight(), 0.25, "the cascading level's rule re-sized too")
end)

test("pixel lines: a ReorderList row box's edges are one physical pixel, and re-size on a scale change", function()
  local m, _, W, scale = env(true)
  local win = m.CreateFrame("Frame", nil, m.UIParent)
  local list = W.ReorderList({ stride = 30 })
  local row = m.CreateFrame("Frame", nil, win)
  row:SetSize(200, 30)
  list:AddRow(row, {})
  local box = list.boxes[1]
  assertTrue(box ~= nil, "the row has a box")
  assertEqual(W.ROW_BOX.EDGE_SIZE, 1, "the published edge size is unchanged")
  assertEdges(box.edges, 0.5, "row box")
  scale.v = 3
  m.UIParent:__fire("OnSizeChanged", 1280, 720)
  assertEdges(box.edges, 0.25, "row box after the UI scale moved")
  scale.v = 0.75
  win:SetScale(0.5)
  assertEdges(box.edges, 1, "row box after its window's SetScale")
  assertEqual(rgba(box.edges[1].__color), rgba(W.ROW_BOX.EDGE), "the edge color kept")
end)

test("pixel lines: a DragHandle strip's edges are one physical pixel, and re-size on a scale change", function()
  local m, _, W, scale = env(true)
  local win = m.CreateFrame("Frame", nil, m.UIParent)
  local h = W.DragHandle(win, { label = "Buffs", moveFrame = m.CreateFrame("Frame", nil, m.UIParent) })
  assertTrue(h ~= nil and h.__edges ~= nil, "the strip drew its own edges")
  assertEdges(h.__edges, 0.5, "drag handle")
  scale.v = 3
  m.UIParent:__fire("OnSizeChanged", 1280, 720)
  assertEdges(h.__edges, 0.25, "drag handle after the UI scale moved")
  scale.v = 0.75
  win:SetScale(0.5)
  assertEdges(h.__edges, 1, "drag handle after its parent's SetScale")
end)

test("pixel lines: under a skin the three lines stay one physical pixel through a paint and a switch", function()
  -- No skin painter re-sizes these: a skin recolors the rule, the box edges and the strip edges.
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  local menu = W.ContextMenu(m.UIParent, { { label = "One" }, { divider = true } }, { owner = OWNER })
  assertEqual(menu.buttons[2].__rule:GetHeight(), 0.5, "the owned menu's rule")
  local list = W.ReorderList({ stride = 30, owner = OWNER })
  local row = m.CreateFrame("Frame", nil, m.UIParent)
  row:SetSize(200, 30)
  list:AddRow(row, {})
  assertEdges(list.boxes[1].edges, 0.5, "an owned row box")
  local h = W.DragHandle(m.UIParent, { label = "Buffs", moveFrame = m.CreateFrame("Frame", nil, m.UIParent),
                                       owner = OWNER })
  assertEdges(h.__edges, 0.5, "an owned drag handle")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertEdges(h.__edges, 0.5, "the owned drag handle after a skin switch")
  menu = W.ContextMenu(m.UIParent, { { label = "One" }, { divider = true } }, { owner = OWNER })
  assertEqual(menu.buttons[2].__rule:GetHeight(), 0.5, "the owned menu's rule after a skin switch")
end)

-- ── the line chart's Lines (FU-L1, WidgetsLineChart minor 7) ──────────────────────────────────
--
-- Ka0sAddonsCommonTasks docs/2026-11-06-FOLLOWUPS_V1_91, section 1: the axis, the grid, the markers,
-- the crosshair and a series drew `Line:SetThickness(1)` (1.5 for a series), which is UI UNITS. A Line's
-- thickness is now read as PHYSICAL pixels, a host's `series[i].thickness` too, and every pooled Line
-- and the crosshair re-size on a pixel-scale change without a render. The area fill's columns are a
-- spacing in UI units (`FILL_STEP`), so they stay in UI units. Red under minor 6: every line reads 1
-- (1.5, 3) whatever the scale.

local AXIS_C = "0.450,0.450,0.500,0.800"

--- The chart's shown pooled Lines, keyed by their color, each a list of thicknesses.
local function chartLines(c)
  local by = {}
  for _, l in ipairs(c.__linePool) do
    if l:IsShown() then
      local k = rgba(l.__color)
      by[k] = by[k] or {}
      by[k][#by[k] + 1] = l:GetThickness()
    end
  end
  return by
end

--- Every Line of color `key` is `th` thick (at least one drawn).
local function assertThick(by, key, th, what)
  local list = by[key]
  assertTrue(list ~= nil and #list > 0, what .. ": drawn")
  for i, v in ipairs(list) do assertEqual(v, th, what .. " #" .. i) end
end

local SERIES_A, SERIES_B, MARK, FILL = { 0.1, 0.2, 0.3, 1 }, { 0.3, 0.2, 0.1, 1 }, { 0.5, 0.5, 0.5, 1 },
  { 0.9, 0.8, 0.7, 0.25 }

local function chartData()
  local a, b = {}, {}
  for i = 1, 4 do a[i] = { x = i * 100, y = i * 10 }; b[i] = { x = i * 100, y = 50 - i * 5 } end
  return { xMin = 100, xMax = 400,
           markers = { { x = 200, color = MARK }, { x = 300, color = MARK, dashed = false } },
           series = { { points = a, color = SERIES_A, fill = FILL },
                      { points = b, color = SERIES_B, thickness = 3 } } }
end

--- The chart drawn at physical pixel `px` (UI units): axis, grid, markers and crosshair one pixel,
--- the default series 1.5 pixels, the host's 3 pixels, the fill columns FILL_STEP UI units.
local function assertChartAt(W, c, px, what, gridKey)
  local by = chartLines(c)
  assertThick(by, AXIS_C, px, what .. ": the axis")
  assertThick(by, gridKey, px, what .. ": the grid")
  assertThick(by, rgba(MARK), px, what .. ": the markers, dashed and solid")
  assertThick(by, rgba(SERIES_A), 1.5 * px, what .. ": a series at its default thickness")
  assertThick(by, rgba(SERIES_B), 3 * px, what .. ": a host's thickness, read as physical pixels")
  assertThick(by, rgba(FILL), W.LINE_CHART.FILL_STEP, what .. ": the fill columns stay in UI units")
  assertEqual(c.__cross:GetThickness(), px, what .. ": the crosshair")
end

test("pixel lines: the line chart's axis, grid, markers, crosshair and series are physical pixels, re-sized", function()
  local m, _, W, scale = env(true)
  local win = m.CreateFrame("Frame", nil, m.UIParent)
  local c = W.LineChart(win, {})
  c:SetData(chartData())
  c:Render(400, 200)
  local grid = rgba(W.LINE_CHART.GRID)
  assertChartAt(W, c, 0.5, "drawn", grid)
  scale.v = 3
  m.UIParent:__fire("OnSizeChanged", 1280, 720)
  assertChartAt(W, c, 0.25, "after the UI scale moved, with no render", grid)
  scale.v = 0.75
  win:SetScale(0.5)
  assertChartAt(W, c, 1, "after its window's SetScale", grid)
  c:Render(400, 200)
  assertChartAt(W, c, 1, "a render at the new scale", grid)
  assertEqual(#m.__registrations(), 0, "hooks, never an event registration")
end)

test("pixel lines: an owned line chart keeps physical pixels through a skin switch", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  local c = W.LineChart(m.UIParent, { owner = OWNER })
  c:SetData(chartData())
  c:Render(400, 200)
  local by = chartLines(c)
  assertThick(by, rgba(SERIES_B), 1.5, "an owned chart's host thickness")
  assertEqual(c.__cross:GetThickness(), 0.5, "an owned chart's crosshair")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  by = chartLines(c)
  assertThick(by, rgba(SERIES_A), 0.75, "a default series after a skin switch")
  assertThick(by, rgba(MARK), 0.5, "the markers after a skin switch")
end)
