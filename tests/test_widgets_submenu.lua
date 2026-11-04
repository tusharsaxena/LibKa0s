-- tests/test_widgets_submenu.lua -- LibKa0s-Widgets-1.0's cascading menus (Widgets minor 23): a
-- W.ContextMenu row with `submenu = rows` opens a child menu beside itself, one pooled frame per
-- depth, while the parent stays drawn; the optional `radio` / `selected` tick column. For Outfitter
-- Reborn's outfit menu (its docs/superpowers/specs/2026-11-05-smoke-round-2-design.md, G4), whose
-- nested levels lost their parent when a submenu reopened the one shared frame in its place.
--
-- It installs tests/fixture_geom.lua's frames per case, as tests/test_widgets_menu.lua does. That
-- stub's Hide does not fire OnHide, so a case that means the client's cascade fires it by hand.

local T = _G.LK_TEST
local assertEqual, assertTrue, assertFalse, assertNil = T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local mocks = T.mocks
local W = T.widgets

local Geom = dofile("tests/fixture_geom.lua")
local test = Geom.test

local function anchor() return mocks.CreateFrame("Frame", nil, mocks.UIParent) end

local function textRGB(row)
  local c = row.fs.__textColor
  return c[1], c[2], c[3]
end

local function click(row)
  assertTrue(row:GetScript("OnClick") ~= nil, "a live row")
  row:GetScript("OnClick")(row)
end

local function hover(row)
  assertTrue(row:GetScript("OnEnter") ~= nil, "a row that answers the pointer")
  row:GetScript("OnEnter")(row)
end

--- Every frame of the cascade below `menu`, in depth order, and the pointer off each one.
local function chain(menu)
  local out, f = {}, menu
  while f do
    f.__mouseOver = false
    out[#out + 1] = f
    f = f.__child
  end
  return out
end

local function tree()
  local picked = {}
  local rows = {
    { label = "Plain", onClick = function() picked[#picked + 1] = "plain" end },
    { label = "Colors", onClick = function() picked[#picked + 1] = "never" end, submenu = {
      { label = "Red", onClick = function() picked[#picked + 1] = "red" end },
      { label = "Shades", submenu = {
        { label = "Dark", onClick = function() picked[#picked + 1] = "dark" end },
      } },
    } },
    { label = "Sizes", submenu = { { label = "Big" }, { label = "Small" } } },
    { label = "Off", disabled = true, submenu = { { label = "Hidden" } } },
  }
  return rows, picked
end

test("submenu: a click on a submenu row opens its rows beside the row, and the parent stays", function()
  local rows, picked = tree()
  local menu = W.ContextMenu(anchor(), rows)
  local row = menu.buttons[2]
  click(row)
  local child = menu.__child
  assertTrue(child ~= nil and child ~= menu, "a frame of its own")
  assertTrue(child:IsShown(), "the child is up")
  assertTrue(menu:IsShown(), "and the parent is still drawn")
  assertEqual(child.buttons[1].fs:GetText(), "Red")
  assertEqual(child.buttons[2].fs:GetText(), "Shades")
  local p, rel, rp = child:GetPoint(1)
  assertEqual(p, "TOPLEFT")
  assertTrue(rel == row, "anchored to the row that opened it")
  assertEqual(rp, "TOPRIGHT")
  assertEqual(#picked, 0, "a submenu row's own onClick never runs")
  W.CloseMenu()
end)

test("submenu: hovering a submenu row opens it, and hovering it again does not repaint", function()
  local rows = tree()
  local menu = W.ContextMenu(anchor(), rows)
  hover(menu.buttons[3])
  local child = menu.__child
  assertTrue(child:IsShown())
  assertEqual(child.buttons[1].fs:GetText(), "Big")
  local pop, painted = child.Populate, 0
  child.Populate = function(...) painted = painted + 1; return pop(...) end
  hover(menu.buttons[3])
  click(menu.buttons[3])
  child.Populate = pop
  assertEqual(painted, 0, "the open child is the one asked for")
  W.CloseMenu()
end)

test("submenu: a child that would leave the screen's right edge opens to the row's left, clamped", function()
  local rows = tree()
  local menu = W.ContextMenu(anchor(), rows)
  local row = menu.buttons[3]
  rawset(mocks.UIParent, "GetRight", function() return 1000 end)
  row.GetRight = function() return 990 end
  click(row)
  local child = menu.__child
  local p, rel, rp = child:GetPoint(1)
  rawset(mocks.UIParent, "GetRight", nil)
  assertEqual(p, "TOPRIGHT")
  assertTrue(rel == row)
  assertEqual(rp, "TOPLEFT")
  W.CloseMenu()
  local clamped
  child.SetClampedToScreen = function(_, on) clamped = on end
  row.GetRight = function() return 100 end
  rawset(mocks.UIParent, "GetRight", function() return 1000 end)
  menu = W.ContextMenu(anchor(), rows)
  click(menu.buttons[3])
  rawset(mocks.UIParent, "GetRight", nil)
  child.SetClampedToScreen = nil
  assertEqual((child:GetPoint(1)), "TOPLEFT", "room on the right: the right")
  assertEqual(clamped, true, "every open clamps the child to the screen")
  W.CloseMenu()
end)

test("submenu: opening a sibling submenu closes every deeper level", function()
  local rows = tree()
  local menu = W.ContextMenu(anchor(), rows)
  click(menu.buttons[2])
  local child = menu.__child
  click(child.buttons[2])
  local grand = child.__child
  assertTrue(grand:IsShown(), "two deep")
  assertEqual(grand.buttons[1].fs:GetText(), "Dark")
  hover(menu.buttons[3])
  assertTrue(child:IsShown(), "depth 2 now holds the sibling's rows")
  assertEqual(child.buttons[1].fs:GetText(), "Big")
  assertFalse(grand:IsShown(), "and depth 3 is gone")
  W.CloseMenu()
end)

test("submenu: hovering a plain row closes the levels below its own", function()
  local rows = tree()
  local menu = W.ContextMenu(anchor(), rows)
  click(menu.buttons[2])
  local child = menu.__child
  click(child.buttons[2])
  hover(child.buttons[1])
  assertTrue(child:IsShown(), "its own level stays")
  assertFalse(child.__child:IsShown(), "the level below it closes")
  hover(menu.buttons[1])
  assertFalse(child:IsShown())
  assertTrue(menu:IsShown())
  W.CloseMenu()
end)

test("submenu: a disabled submenu row opens nothing", function()
  local rows = tree()
  local menu = W.ContextMenu(anchor(), rows)
  assertNil(menu.buttons[4]:GetScript("OnClick"))
  if menu.__child then menu.__child:Hide() end
  hover(menu.buttons[4])
  assertFalse(menu.__child ~= nil and menu.__child:IsShown(), "no child for an inert row")
  W.CloseMenu()
end)

test("submenu: a press on none of the levels closes them all, a press on any of them closes none", function()
  local rows = tree()
  local a = anchor()
  local menu = W.ContextMenu(a, rows)
  click(menu.buttons[2])
  click(menu.__child.buttons[2])
  local frames = chain(menu)
  a.__mouseOver = false
  assertEqual(#frames, 3)
  for depth = 1, 3 do
    frames[depth].__mouseOver = true
    menu:__fire("OnEvent", "GLOBAL_MOUSE_DOWN", "LeftButton")
    for d = 1, 3 do assertTrue(frames[d]:IsShown(), "a press on depth " .. depth .. " keeps depth " .. d) end
    frames[depth].__mouseOver = false
  end
  menu:__fire("OnEvent", "GLOBAL_MOUSE_DOWN", "LeftButton")
  for d = 1, 3 do assertFalse(frames[d]:IsShown(), "an outside press closes depth " .. d) end
end)

test("submenu: CloseMenu closes every level", function()
  local rows = tree()
  local menu = W.ContextMenu(anchor(), rows)
  click(menu.buttons[2])
  click(menu.__child.buttons[2])
  local frames = chain(menu)
  W.CloseMenu()
  for d = 1, 3 do assertFalse(frames[d]:IsShown(), "depth " .. d) end
end)

test("submenu: the root menu's OnHide closes every level", function()
  local rows = tree()
  local menu = W.ContextMenu(anchor(), rows)
  click(menu.buttons[2])
  click(menu.__child.buttons[2])
  local frames = chain(menu)
  menu:Hide()
  menu:__fire("OnHide")
  for d = 2, 3 do assertFalse(frames[d]:IsShown(), "depth " .. d) end
end)

test("submenu: a new menu opened while a cascade is up closes the old levels", function()
  local rows = tree()
  local menu = W.ContextMenu(anchor(), rows)
  click(menu.buttons[2])
  local child = menu.__child
  W.ContextMenu(anchor(), { { label = "Other" } })
  assertTrue(menu:IsShown())
  assertFalse(child:IsShown(), "no child of a menu that is gone")
  W.CloseMenu()
end)

test("submenu: a plain pick in a child closes every level before its callback", function()
  local rows, picked = tree()
  local menu = W.ContextMenu(anchor(), rows)
  click(menu.buttons[2])
  local child = menu.__child
  click(child.buttons[2])
  local grand = child.__child
  local seen
  rows[2].submenu[2].submenu[1].onClick = function(_, r)
    seen = { menu:IsShown(), child:IsShown(), grand:IsShown(), r }
  end
  click(grand.buttons[1])
  assertEqual(#picked, 0)
  assertFalse(seen[1] or seen[2] or seen[3], "every level hid before the callback")
  assertTrue(seen[4] == rows[2].submenu[2].submenu[1], "the row reaches its callback")
end)

test("submenu: a keepOpen pick in a child repaints the child and every ancestor", function()
  local mode = "a"
  local rows = {
    { label = "Mode", isActive = function() return mode == "b" end, submenu = {
      { label = "Inner", isActive = function() return mode == "b" end, submenu = {
        { label = "B", keepOpen = true, radio = true, selected = function() return mode == "b" end,
          onClick = function() mode = "b" end },
      } },
    } },
  }
  local menu = W.ContextMenu(anchor(), rows)
  click(menu.buttons[1])
  local child = menu.__child
  click(child.buttons[1])
  local grand = child.__child
  assertEqual((textRGB(menu.buttons[1])), 0.9, "plain before the pick")
  assertEqual(grand.buttons[1].__tick:GetText(), "", "no tick before the pick")
  click(grand.buttons[1])
  assertTrue(menu:IsShown() and child:IsShown() and grand:IsShown(), "every level stays")
  local r, g = textRGB(menu.buttons[1])
  assertEqual(r, 1)
  assertEqual(g, 0.82, "the root row reads the new state")
  assertEqual((select(2, textRGB(child.buttons[1]))), 0.82, "so does the middle level's")
  assertTrue(grand.buttons[1].__tick:GetText() ~= "", "and the pick wears its tick")
  W.CloseMenu()
end)

test("submenu: a keepOpen pick whose callback closed the menu repaints no level", function()
  local rows = { { label = "Sub", submenu = { { label = "Close", keepOpen = true, onClick = function() W.CloseMenu() end } } } }
  local menu = W.ContextMenu(anchor(), rows)
  click(menu.buttons[1])
  local child = menu.__child
  local painted = 0
  local pops = { menu.Populate, child.Populate }
  menu.Populate = function(...) painted = painted + 1; return pops[1](...) end
  child.Populate = function(...) painted = painted + 1; return pops[2](...) end
  click(child.buttons[1])
  menu.Populate, child.Populate = pops[1], pops[2]
  assertEqual(painted, 0)
  assertFalse(menu:IsShown() or child:IsShown())
end)

test("submenu: radio and selected rows draw a tick column, a predicate read on every paint", function()
  local on = true
  local rows = { { label = "One", radio = true, selected = true }, { label = "Two", radio = true },
                 { label = "Three", selected = function(row) return on and row.label == "Three" end },
                 { label = "Plain" } }
  local a = anchor()
  local menu = W.ContextMenu(a, rows)
  local b = menu.buttons
  assertTrue(b[1].__tick:IsShown())
  assertTrue(b[1].__tick:GetText():find("|T", 1, true) ~= nil, "the tick is the menu's check markup")
  assertTrue(b[2].__tick:IsShown(), "an unpicked radio keeps the column")
  assertEqual(b[2].__tick:GetText(), "")
  assertTrue(b[3].__tick:GetText() ~= "", "the predicate said yes")
  assertFalse(b[4].__tick ~= nil and b[4].__tick:IsShown(), "a plain row has no column")
  assertEqual((select(4, b[2].fs:GetPoint(1))), 22, "a ticked row's label clears the column")
  assertEqual((select(4, b[4].fs:GetPoint(1))), 8, "a plain row's starts at the margin")
  W.CloseMenu()
  on = false
  menu = W.ContextMenu(a, rows)
  assertEqual(menu.buttons[3].__tick:GetText(), "", "read again on the next open")
  W.CloseMenu()
end)

test("submenu: a submenu row carries an arrow and its label stops short of it", function()
  local menu = W.ContextMenu(anchor(), { { label = "Sub", submenu = { { label = "x" } } }, { label = "Plain" } })
  assertTrue(menu.buttons[1].__sub:IsShown())
  assertFalse(menu.buttons[2].__sub ~= nil and menu.buttons[2].__sub:IsShown())
  assertEqual((select(4, menu.buttons[1].fs:GetPoint(2))), -18)
  assertEqual((select(4, menu.buttons[2].fs:GetPoint(2))), -8)
  W.CloseMenu()
end)

test("submenu: a pooled row leaves its arrow, its tick and its hover behind", function()
  local a = anchor()
  W.ContextMenu(a, { { label = "Sub", submenu = { { label = "x" } } }, { label = "R", radio = true, selected = true } })
  W.CloseMenu()
  local menu = W.ContextMenu(a, { { label = "A" }, { label = "B" } })
  for i = 1, 2 do
    local row = menu.buttons[i]
    assertFalse(row.__sub ~= nil and row.__sub:IsShown(), "no arrow " .. i)
    assertFalse(row.__tick ~= nil and row.__tick:IsShown(), "no tick " .. i)
    assertNil(row:GetScript("OnEnter"), "a flat menu's row has no hover script " .. i)
    assertEqual((select(4, row.fs:GetPoint(1))), 8)
  end
  W.CloseMenu()
end)

test("submenu: a dropdown's rows ignore submenu, radio and selected", function()
  local dd = W.Dropdown(mocks.UIParent, 110)
  local got
  dd.onSelect = function(v) got = v end
  dd:SetOptions({ { value = "a", label = "A", submenu = { { label = "x" } }, radio = true, selected = true } })
  local menu = W.ContextMenu(anchor(), { { label = "x" } })
  W.CloseMenu()
  dd:GetScript("OnClick")(dd)
  local row = menu.buttons[1]
  assertFalse(row.__sub ~= nil and row.__sub:IsShown(), "no arrow")
  assertFalse(row.__tick ~= nil and row.__tick:IsShown(), "no tick")
  click(row)
  assertEqual(got, "a", "the row is the value, as it always was")
  assertFalse(menu:IsShown())
end)

test("submenu: a child wears the opener's skin", function()
  local Skin = T.skin
  local OWNER = "SubmenuSkinHost"
  if not Skin:IsOwner(OWNER) then Skin:RegisterOwner(OWNER) end
  Skin:SetChoice(OWNER, "ka0s", "contrast")
  local t = Skin:ResolveSkin("contrast")
  local menu = W.ContextMenu(anchor(), { { label = "Sub", submenu = { { label = "H", title = true } } } },
    { owner = OWNER })
  click(menu.buttons[1])
  local r, g, b = textRGB(menu.__child.buttons[1])
  assertEqual(("%.2f,%.2f,%.2f"):format(r, g, b), ("%.2f,%.2f,%.2f"):format(unpack(t["menu.textSel"])))
  W.CloseMenu()
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
end)
