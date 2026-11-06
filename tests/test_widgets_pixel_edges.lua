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
local WFILES = { "Widgets", "WidgetsReorder", "WidgetsDragHandle", "WidgetsLineChart", "WidgetsAutocomplete",
                 "WidgetsCopyWindow" }
local PIECES = { "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
                 "TopEdge", "BottomEdge", "LeftEdge", "RightEdge", "Center" }

--- A client whose frames answer `scale.v` as their effective scale (1.5 to start), PixelUtil's
--- factor 0.75, and a hooksecurefunc that post-hooks for real. A frame answers its parent and its
--- last SetScale. `noSkin` loads Core and Widgets alone. Answers m, Skin (nil without it), W, scale.
local function env(noSkin)
  local files = {}
  for _, f in ipairs(noSkin and { "Core" } or F.FILES) do files[#files + 1] = f end
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
    rawset(f, "GetParent", function() return parent end)
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
