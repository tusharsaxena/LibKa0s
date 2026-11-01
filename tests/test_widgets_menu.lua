-- tests/test_widgets_menu.lua -- LibKa0s-Widgets-1.0's shared popup menu, opened by a host: the row
-- options (title, disabled, divider, tooltip, keepOpen) and W.ContextMenu, for the hosts that wrote a
-- context menu of their own (FS-FIX of Ka0sAddonsCommonTasks docs/2026-11-01-FULL_SKINNING, Widgets
-- minor 21).
--
-- It installs tests/fixture_geom.lua's frames per case for the reason tests/test_widgets.lua's header
-- gives: the base stub has no geometry, and the menu measures itself.

local T = _G.LK_TEST
local assertEqual, assertTrue, assertFalse, assertNil = T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local mocks = T.mocks
local W = T.widgets

local Geom = dofile("tests/fixture_geom.lua")
local test = Geom.test

local function anchor() return mocks.CreateFrame("Frame", nil, mocks.UIParent) end

local function rowsOf(menu, n)
  local out = {}
  for i = 1, n do out[i] = menu.buttons[i] end
  return out
end

local function textRGB(row)
  local c = row.fs.__textColor
  return c[1], c[2], c[3]
end

local function click(row)
  assertTrue(row:GetScript("OnClick") ~= nil, "a live row")
  row:GetScript("OnClick")()
end

test("menu: ContextMenu opens the shared menu on rows a host passes", function()
  local a = anchor()
  local menu = W.ContextMenu(a, { { label = "One" }, { label = "Two" } })
  assertTrue(menu ~= nil, "answers the menu")
  assertTrue(menu:IsShown())
  assertTrue(menu._owner == a, "the anchor is its owner, so a press on it is no outside press")
  local rows = rowsOf(menu, 2)
  assertEqual(rows[1].fs:GetText(), "One")
  assertEqual(rows[2].fs:GetText(), "Two")
  W.CloseMenu()
  assertFalse(menu:IsShown())
end)

test("menu: ContextMenu refuses no anchor and no rows", function()
  assertNil(W.ContextMenu(nil, { { label = "x" } }))
  assertNil(W.ContextMenu(anchor(), nil))
  assertNil(W.ContextMenu(anchor(), {}), "an empty list opens nothing, as the doc says")
  assertFalse(W.ContextMenu(anchor(), { { label = "x" } }) == nil, "a row still opens")
  W.CloseMenu()
end)

test("menu: a ContextMenu row's onClick runs after the menu has hidden", function()
  -- red under: a callback opening another menu, then hidden by the row that opened it.
  local a = anchor()
  local shown, got
  local row = { label = "Go", value = 7, onClick = function(v, r) shown, got = nil, { v, r } end }
  row.onClick = function(v, r)
    shown, got = W.ContextMenu(a, { { label = "Next" } }):IsShown(), { v, r }
  end
  local menu = W.ContextMenu(a, { row })
  click(menu.buttons[1])
  assertTrue(shown, "the second menu stood")
  assertTrue(menu:IsShown(), "the callback's menu stays open")
  assertEqual(got[1], 7)
  assertTrue(got[2] == row, "the row reaches its callback")
  W.CloseMenu()
end)

test("menu: a second ContextMenu on one anchor closes, as a dropdown's second click does", function()
  local a = anchor()
  local menu = W.ContextMenu(a, { { label = "x" } })
  W.ContextMenu(a, { { label = "x" } })
  assertFalse(menu:IsShown())
end)

test("menu: opts.cursor opens at the pointer, and moves rather than closes", function()
  local a = anchor()
  local realCursor = mocks.GetCursorPosition
  mocks.GetCursorPosition = function() return 300, 200 end
  local menu = W.ContextMenu(a, { { label = "x" } }, { cursor = true })
  local p, rel, rp, x, y = menu:GetPoint(1)
  assertEqual(p, "TOPLEFT")
  assertTrue(rel == mocks.UIParent)
  assertEqual(rp, "BOTTOMLEFT")
  assertEqual(x, 300)
  assertEqual(y, 200)
  mocks.GetCursorPosition = function() return 10, 20 end
  W.ContextMenu(a, { { label = "x" } }, { cursor = true })
  assertTrue(menu:IsShown(), "open at the new spot")
  x = select(4, menu:GetPoint(1))
  assertEqual(x, 10)
  mocks.GetCursorPosition = realCursor
  W.CloseMenu()
end)

test("menu: a title row is gold, takes no click and shows no highlight", function()
  local menu = W.ContextMenu(anchor(), { { label = "Heading", title = true }, { label = "Row" } })
  local row = menu.buttons[1]
  assertNil(row:GetScript("OnClick"), "no click")
  assertFalse(row.__hl:IsShown(), "no hover")
  local r, g = textRGB(row)
  assertEqual(r, 1)
  assertEqual(g, 0.82)
  assertTrue(menu.buttons[2].__hl:IsShown(), "the next row is live")
  W.CloseMenu()
end)

test("menu: a disabled row is gray and takes no click, a predicate read each open", function()
  local off = true
  local rows = { { label = "A", disabled = true }, { label = "B", disabled = function() return off end } }
  local a = anchor()
  local menu = W.ContextMenu(a, rows)
  assertNil(menu.buttons[1]:GetScript("OnClick"))
  assertNil(menu.buttons[2]:GetScript("OnClick"))
  local r = textRGB(menu.buttons[2])
  assertEqual(r, 0.5)
  W.CloseMenu()
  off = false
  menu = W.ContextMenu(a, rows)
  assertTrue(menu.buttons[2]:GetScript("OnClick") ~= nil, "live again")
  W.CloseMenu()
end)

test("menu: a divider row is short, drawn as a rule, and the height counts it", function()
  local menu = W.ContextMenu(anchor(), { { label = "A" }, { divider = true }, { label = "B" } })
  local rule = menu.buttons[2]
  assertEqual(rule:GetHeight(), 8)
  assertNil(rule:GetScript("OnClick"))
  assertTrue(rule.__rule:IsShown(), "the rule")
  assertEqual(table.concat(rule.__rule.__colorTexture, ","), "0.24,0.24,0.27,0.85", "in the divider's color")
  assertEqual(rule.fs:GetText(), "")
  assertFalse(menu.buttons[1].__rule:IsShown(), "and on no other row")
  assertEqual(menu:GetHeight(), 16 + 8 + 16 + 8)
  local _, _, _, _, y = menu.buttons[3]:GetPoint(1)
  assertEqual(y, -(4 + 16 + 8), "the row after it starts below it")
  W.CloseMenu()
end)

test("menu: a pooled row leaves its divider and its title behind", function()
  -- red under: a field left alone, the previous menu's rule or dead click on this row.
  local a = anchor()
  W.ContextMenu(a, { { divider = true }, { label = "T", title = true }, { label = "X", disabled = true } })
  W.CloseMenu()
  local menu = W.ContextMenu(a, { { label = "A" }, { label = "B" }, { label = "C" } })
  for i = 1, 3 do
    local row = menu.buttons[i]
    assertEqual(row:GetHeight(), 16, "row height " .. i)
    assertFalse(row.__rule:IsShown(), "no rule " .. i)
    assertTrue(row.__hl:IsShown(), "a highlight " .. i)
    assertTrue(row:GetScript("OnClick") ~= nil, "a click " .. i)
    local r = textRGB(row)
    assertEqual(r, 0.9, "plain text " .. i)
  end
  W.CloseMenu()
end)

test("menu: a row's tooltip shows on enter and leaves with the row or the menu", function()
  local tip = mocks.GameTooltip
  local owner, text, hidden = nil, nil, 0
  rawset(tip, "SetOwner", function(_, o) owner = o end)
  rawset(tip, "SetText", function(_, s) text = s end)
  rawset(tip, "Hide", function() hidden = hidden + 1 end)
  rawset(tip, "Show", function() end)
  local menu = W.ContextMenu(anchor(), { { label = "A", tooltip = "Why" }, { label = "B" } })
  local row = menu.buttons[1]
  row:GetScript("OnEnter")(row)
  assertTrue(owner == row)
  assertEqual(text, "Why")
  row:GetScript("OnLeave")(row)
  assertEqual(hidden, 1)
  row:GetScript("OnEnter")(row)
  W.CloseMenu()
  menu:__fire("OnHide")
  assertEqual(hidden, 2, "a menu closing under the pointer takes its tooltip with it")
  assertNil(menu.buttons[2]:GetScript("OnEnter"), "a row with none has no script")
  rawset(tip, "SetOwner", nil); rawset(tip, "SetText", nil); rawset(tip, "Hide", nil); rawset(tip, "Show", nil)
end)

test("menu: a tooltip function is the host's renderer", function()
  local seen
  local rowOpt = { label = "A", tooltip = function(frame, opt) seen = { frame, opt } end }
  local menu = W.ContextMenu(anchor(), { rowOpt })
  local row = menu.buttons[1]
  row:GetScript("OnEnter")(row)
  assertTrue(seen[1] == row)
  assertTrue(seen[2] == rowOpt)
  row:GetScript("OnLeave")(row)
  W.CloseMenu()
end)

test("menu: a disabled row keeps its tooltip, which says why", function()
  local menu = W.ContextMenu(anchor(), { { label = "A", disabled = true, tooltip = "Not now" } })
  assertTrue(menu.buttons[1]:GetScript("OnEnter") ~= nil)
  W.CloseMenu()
end)

test("menu: keepOpen holds the menu through the callback and repaints the row", function()
  local on = false
  local rows = { { label = "Toggle", value = "t", keepOpen = true, isActive = function() return on end,
                   onClick = function() on = not on end } }
  local menu = W.ContextMenu(anchor(), rows)
  local r = textRGB(menu.buttons[1])
  assertEqual(r, 0.9)
  click(menu.buttons[1])
  assertTrue(menu:IsShown(), "still open")
  local rr, gg = textRGB(menu.buttons[1])
  assertEqual(rr, 1)
  assertEqual(gg, 0.82, "the row reads its new state")
  W.CloseMenu()
end)

test("menu: a keepOpen row leaves a menu its callback opened alone", function()
  -- red under: the repaint after the callback, which wrote the first menu's rows over the second's.
  local there, second = anchor(), { { label = "Second", value = "s" } }
  local rows = { { label = "Keep", value = "k", keepOpen = true,
                   onClick = function() W.ContextMenu(there, second) end } }
  local menu = W.ContextMenu(anchor(), rows)
  click(menu.buttons[1])
  assertTrue(menu._owner == there, "the callback's menu is up")
  assertEqual(menu.buttons[1].fs:GetText(), "Second", "and wears its own rows")
  W.CloseMenu()
end)

test("menu: a keepOpen row leaves a cursor menu on its own anchor alone", function()
  -- red under: a repaint gated on the owner alone: the same anchor, a new menu.
  local same, second = anchor(), { { label = "Second", value = "s" } }
  local rows = { { label = "Keep", value = "k", keepOpen = true,
                   onClick = function() W.ContextMenu(same, second, { cursor = true }) end } }
  local menu = W.ContextMenu(same, rows)
  click(menu.buttons[1])
  assertEqual(menu.buttons[1].fs:GetText(), "Second")
  W.CloseMenu()
end)

test("menu: a keepOpen row whose callback closed the menu does not repaint it", function()
  local rows = { { label = "Keep", value = "k", keepOpen = true, onClick = function() W.CloseMenu() end } }
  local menu = W.ContextMenu(anchor(), rows)
  local pop, painted = menu.Populate, 0
  menu.Populate = function(...) painted = painted + 1; return pop(...) end
  click(menu.buttons[1])
  menu.Populate = pop
  assertEqual(painted, 0)
  assertFalse(menu:IsShown())
end)

test("menu: every row takes the mouse, so a press on a title stops at the menu", function()
  -- red under: EnableMouse false on a title or a divider: the outside-click check exempts the press
  -- by geometry, so the menu stayed open and the click landed on whatever was under it.
  local rows = { { label = "Heading", title = true }, { divider = true }, { label = "Off", disabled = true },
                 { label = "Tip", title = true, tooltip = "why" }, { label = "Row" } }
  local a = anchor()
  local menu = W.ContextMenu(a, rows)
  W.CloseMenu()
  local got = {}
  for i = 1, #rows do
    local row = menu.buttons[i]
    local real = row.EnableMouse
    row.EnableMouse = function(self, on) got[i] = on; return real(self, on) end
  end
  menu = W.ContextMenu(a, rows)
  for i = 1, #rows do assertEqual(got[i], true, "row " .. i) end
  assertNil(menu.buttons[1]:GetScript("OnClick"), "and it is still inert")
  assertFalse(menu.buttons[1].__hl:IsShown())
  W.CloseMenu()
end)

test("menu: a title row first does not name a multi dropdown's All", function()
  -- red under: UpdateMultiLabel reading _options[1], which a title row now can be.
  local dd = W.Dropdown(mocks.UIParent, 110)
  dd:SetMulti(true)
  dd:SetOptions({ { label = "Filters", title = true }, { value = "all", label = "Everything" },
                  { value = "a", label = "A" }, { value = "b", label = "B" } })
  dd:UpdateMultiLabel()
  assertEqual(dd.text:GetText(), "Everything")
  dd:SetSelected({ a = true, b = true })
  dd:UpdateMultiLabel()
  assertEqual(dd.text:GetText(), "Everything: 2 selected")
  dd:SetOptions({ { value = "a", label = "A" }, { value = "all", label = "Everything" } })
  dd:SetSelected({})
  dd:UpdateMultiLabel()
  assertEqual(dd.text:GetText(), "Everything", "the sentinel's, wherever it stands")
end)

test("menu: a multi dropdown with no all row reads its first real row, as it always did", function()
  local dd = W.Dropdown(mocks.UIParent, 110)
  dd:SetMulti(true)
  dd:SetOptions({ { label = "Filters", title = true }, { divider = true }, { value = "a", label = "First" } })
  dd:UpdateMultiLabel()
  assertEqual(dd.text:GetText(), "First")
end)

test("menu: a multi dropdown with no options says All", function()
  local dd = W.Dropdown(mocks.UIParent, 110)
  dd:SetMulti(true)
  dd:SetOptions({})
  dd:UpdateMultiLabel()
  assertEqual(dd.text:GetText(), "All")
end)

test("menu: a dropdown takes the row options too, and onSelect its row", function()
  local dd = W.Dropdown(mocks.UIParent, 110)
  local got
  dd.onSelect = function(v, row) got = { v, row } end
  local keep = { value = "b", label = "B", keepOpen = true }
  dd:SetOptions({ { label = "Group", title = true }, { value = "a", label = "A", disabled = true }, { divider = true }, keep })
  local menu = W.ContextMenu(anchor(), { { label = "x" } })   -- the one shared menu
  W.CloseMenu()
  dd:GetScript("OnClick")(dd)
  assertNil(menu.buttons[1]:GetScript("OnClick"), "a title")
  assertNil(menu.buttons[2]:GetScript("OnClick"), "disabled")
  assertEqual(menu.buttons[3]:GetHeight(), 8, "a divider")
  click(menu.buttons[4])
  assertTrue(menu:IsShown(), "keepOpen")
  assertEqual(dd._value, "b")
  assertEqual(got[1], "b")
  assertTrue(got[2] == keep, "the row reaches onSelect")
  W.CloseMenu()
end)

test("menu: the dropdown's own label is one line", function()
  -- red under: a long pick wrapping onto a second line behind the button's edge.
  local wrap
  local realCreate = mocks.CreateFrame
  mocks.CreateFrame = function(...)
    local f = realCreate(...)
    local mk = f.CreateFontString
    function f.CreateFontString(self, ...)
      local fs = mk(self, ...)
      function fs.SetWordWrap(_, v) wrap = v end
      return fs
    end
    return f
  end
  W.Dropdown(mocks.UIParent, 110)
  mocks.CreateFrame = realCreate
  assertEqual(wrap, false)
end)

test("menu: an owned menu reads its title, disabled and rule colors from the skin", function()
  local Skin = T.skin
  local OWNER = "MenuSkinHost"
  if not Skin:IsOwner(OWNER) then Skin:RegisterOwner(OWNER) end
  Skin:SetChoice(OWNER, "ka0s", "contrast")
  local t = Skin:ResolveSkin("contrast")
  local menu = W.ContextMenu(anchor(), { { label = "H", title = true }, { label = "D", disabled = true },
                                         { divider = true } }, { owner = OWNER })
  local r, g, b = textRGB(menu.buttons[1])
  assertEqual(("%.2f,%.2f,%.2f"):format(r, g, b), ("%.2f,%.2f,%.2f"):format(unpack(t["menu.textSel"])))
  r, g, b = textRGB(menu.buttons[2])
  assertEqual(("%.2f,%.2f,%.2f"):format(r, g, b), ("%.2f,%.2f,%.2f"):format(unpack(t["text.disabled"])))
  W.CloseMenu()
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
end)
