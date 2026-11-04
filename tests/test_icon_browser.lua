-- tests/test_icon_browser.lua — LibKa0s-IconBrowser-1.0's browser (IconBrowser.lua) and its window
-- (IconBrowserWindow.lua): `IB:New(spec)`, the window in the host's layers and its owner tokens, the
-- tabs (the host's first, the hidden built-ins gone), selecting and choosing, the virtualized grid
-- and the glyph color. Ported from Ka0s Quick Comms' tests/test_icon_browser.lua and re-pointed at
-- the library; the search, the icon sets, what closes it and two browsers side by side are in
-- tests/test_icon_browser_search.lua. That suite's cases on the sources alone (the marker list, the
-- macro readers, ColorFrom, Search's memo, a set's labels) live in tests/test_icon_browser_sources.lua,
-- and its cases on Quick Comms' own opener (the callout popup, the chooser's swatch) stay in Quick
-- Comms. The bench is tests/fixture_icon_browser.lua.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local F = dofile("tests/fixture_icon_browser.lua")
local OWNER, SKULL = F.OWNER, F.SKULL
local env, browserOf, boot, openOn = F.env, F.browserOf, F.boot, F.openOn
local cellFor, shownCells, glyph, vertex = F.cellFor, F.shownCells, F.glyph, F.vertex
local spells, range, tabButton = F.spells, F.range, F.tabButton

-- ── the major ───────────────────────────────────────────────────────────────────────────────

test("browser: the major gains New, its two files and the four owner tokens", function()
  local _, IB = env()
  -- red under: no LibKa0s/IconBrowser.lua or LibKa0s/IconBrowserWindow.lua
  assertEqual(type(IB.New), "function")
  assertEqual(IB.MODULES.IconBrowser, IB.__browserMinor)
  assertEqual(IB.MODULES.IconBrowserWindow, IB.__windowMinor)
  local names = {}
  for name in pairs(IB.SKIN_TOKENS) do names[#names + 1] = name end
  table.sort(names)
  assertEqual(table.concat(names, ","), "ib.markGray,ib.modalDim,ib.note,ib.selStrong")
  assertEqual(table.concat(IB.SKIN_TOKENS["ib.selStrong"].default, ","), "1,0.82,0,0.7", "Quick Comms' pixels")
  assertEqual(IB.WOWHEAD_ICONS, "https://www.wowhead.com/icons")
end)

test("browser: New needs the host's folder and its Options instance", function()
  local _, IB, helpers = env()
  local ok = pcall(IB.New, IB, { helpers = helpers })
  assertFalse(ok, "no owner")
  ok = pcall(IB.New, IB, { owner = OWNER })
  assertFalse(ok, "no helpers")
  assertTrue(IB:New({ owner = OWNER, helpers = helpers }) ~= nil)
end)

test("browser: without the window file the browser does not attach", function()
  local _, IB = env({ files = { "IconBrowserSources" } })
  -- the sources stand on their own; New is the browser's
  assertTrue(IB ~= nil)
  assertNil(IB.New)
end)

-- ── the window ──────────────────────────────────────────────────────────────────────────────

test("browser: the window is the template's chrome, titled by the host, above its own catcher", function()
  local m, B = boot()
  openOn(B, nil)
  -- red under: build the browser's window as a plain frame
  assertEqual(B.frame.__template, "SettingsFrameTemplate")
  assertEqual(B.frame.NineSlice.Text:GetText(), "Ka0s Test Host", "the window title is the host's")
  assertEqual(B.ctx.panel.title:GetText(), "Choose an icon", "the page header")
  assertEqual(B.frame.__parent, B.catcher, "above its own catcher")
  assertEqual(m.__named.TestHostIconBrowser, B.frame, "named for the host")
  assertTrue(B.catcher:IsShown())
  B.frame.ClosePanelButton:__fire("OnClick")
  assertFalse(B:IsOpen(), "the close X cancels")
  assertFalse(B.catcher:IsShown())
end)

test("browser: the window sits in the host's strata and band; its transients go one strata up", function()
  local m, B = boot()
  openOn(B, nil)
  local L = m.__layers
  assertEqual(L(B.catcher).strata, "FULLSCREEN")
  assertEqual(L(B.frame).strata, "FULLSCREEN")
  local base = m.UIParent:GetFrameLevel()
  -- red under: read `level` when `over` is given (a browser over the host's own modal)
  assertEqual(L(B.catcher).level, base + 1400, "the band's base is `over`")
  assertEqual(L(B.frame).level, base + 1402, "the window two over it")
  assertEqual(L(B.ctx.panel).level, base + 1403, "the page over the window")
  assertEqual(L(B.frame.ClosePanelButton).level, base + 1405, "the close X over the page")
  assertTrue(L(B.frame).clamped, "clamped to the screen")
  assertFalse(L(B.frame).toplevel == true, "not toplevel: a raise would lift an opener through the band")
  -- without `over` the band is `level`
  local m2, IB, helpers = env()
  local other = IB:New({ owner = OWNER, helpers = helpers, layers = { strata = "DIALOG", level = 100 } })
  assertTrue(other:Open({ onChoose = function() end }))
  assertEqual(m2.__layers(other.catcher).strata, "DIALOG")
  assertEqual(m2.__layers(other.catcher).level, m2.UIParent:GetFrameLevel() + 100)
  assertEqual(other.layers.popup, "FULLSCREEN", "its transients one strata up")
end)

test("browser: a client without the template gets the plain window, the host's title on its band", function()
  local m, IB, helpers = env()
  m.C_XMLUtil = { GetTemplateInfo = function() return nil end }
  local B = browserOf(m, IB, helpers)
  openOn(B, nil)
  -- red under: ask CreateFrame for the template a client says it lacks
  assertTrue(B.frame.__template ~= "SettingsFrameTemplate")
  assertEqual(B.chrome.template, false)
  assertEqual(B.chrome.title:GetText(), "Ka0s Test Host")
  assertTrue(B.chrome.close ~= nil, "the shared close mark")
  B.chrome.close:__fire("OnClick")
  assertFalse(B:IsOpen(), "the close mark cancels")
end)

test("browser: the catcher's dim and the selected cell are the owner tokens, at Quick Comms' pixels", function()
  local m, B = boot()
  openOn(B, nil)
  local dim
  for _, r in ipairs({ B.catcher:GetRegions() }) do dim = dim or r end
  -- red under: paint the dim black at cover.dim's 0.6 (the library token, not ib.modalDim)
  assertEqual(table.concat(m.__paint(dim).color, ","), "0,0,0,0.45")
  assertEqual(table.concat(m.__paint(B.cells[1].selected).color, ","), "1,0.82,0,0.7")
  assertTrue(B:Widgets().name:GetText():find("|cffaaaaaa", 1, true) ~= nil, "the empty footer line is ib.note")
end)

test("browser: a host with no skin owner still draws, in the tokens' Ka0s Default values", function()
  local m, IB, helpers = env({ noOwner = true })
  local B = browserOf(m, IB, helpers)
  -- red under: index the facade without a registered owner
  openOn(B, nil)
  assertEqual(table.concat(m.__paint(B.cells[1].selected).color, ","), "1,0.82,0,0.7")
  assertTrue(B:IsOpen())
end)

-- ── the tabs ────────────────────────────────────────────────────────────────────────────────

test("browser: tabs in order; the stored icon is preselected and its tab opened", function()
  local m, B = boot()
  spells(m, { 136116 })
  local keys = {}
  for i, t in ipairs(B.tabs) do keys[i] = t.key end
  assertEqual(table.concat(keys, ","), "markers,game,glyphs")
  local cases = { { nil, "markers" }, { SKULL, "markers" }, { glyph(m, "star"), "glyphs" }, { 136116, "game" } }
  for _, case in ipairs(cases) do
    openOn(B, case[1])
    -- red under: open every browser on the first tab
    assertEqual(B:State().tab, case[2], tostring(case[1]))
    assertEqual(B:State().selected, case[1])
    if case[1] then assertTrue(cellFor(B, case[1]).selected:IsShown(), "drawn selected") end
    B:Cancel()
  end
  -- an icon no tab owns: the first tab, nothing selected
  for _, icon in ipairs({ "Interface\\Icons\\Spell_Nature_Bloodlust", "Interface\\Icons\\Whatever" }) do
    openOn(B, icon)
    assertEqual(B:State().tab, "markers", icon)
    -- red under: keep req.icon as the selection when TabFor finds no tab for it
    assertNil(B:State().selected, icon)
    assertTrue(B:Widgets().choose.disabled, "Choose waits for a click")
    B:Cancel()
  end
  -- a key that is not a tab is refused
  openOn(B, nil)
  B:SetTab("suggested")
  assertEqual(B:State().tab, "markers")
  -- the strip is the library's: a tab click shows that tab
  local clicked = tabButton(B, "Glyphs")
  -- red under: draw no tab strip (TabStrip) in IconBrowser.lua
  assertTrue(clicked ~= nil, "a Glyphs tab")
  clicked:__fire("OnClick")
  assertEqual(B:State().tab, "glyphs")
  B:Cancel()
  -- a color is kept only for a glyph, and only a valid one
  openOn(B, glyph(m, "star"), "ff0000")
  assertEqual(B:State().color, "ff0000")
  B:Cancel()
  openOn(B, glyph(m, "star"), "FF0000")
  assertNil(B:State().color, "a malformed color is none")
  B:Cancel()
  openOn(B, SKULL, "ff0000")
  assertNil(B:State().color, "a marker takes no color")
end)

test("browser: a host tab is listed first and preselected for its icon", function()
  local m, IB, helpers = env()
  spells(m, { 135349, 135350 })
  local rec = { key = "rec", label = "Recommended", tooltip = "The outfit's own icons.",
    list = function() return { 135349, 132662 }, true end,
    name = function(icon) return icon == 135349 and "Mighty helm" or nil end,
    owns = function(icon) return icon == 135349 end }
  local B = browserOf(m, IB, helpers, { tabs = { rec } })
  -- red under: append the host's tabs after the built-ins
  assertEqual(B.tabs[1].key, "rec")
  assertTrue(tabButton((function() openOn(B, nil); return B end)(), "Recommended") ~= nil, "on the strip")
  B:Cancel()
  openOn(B, 135349)
  -- red under: ask the built-ins first (Game icons owns every texture id)
  assertEqual(B:State().tab, "rec", "the host tab owns its icon before Game icons does")
  assertEqual(B:State().selected, 135349)
  assertTrue(cellFor(B, 135349).selected:IsShown())
  assertTrue(B:Widgets().name:GetText():find("Mighty helm", 1, true) ~= nil, "named by the host tab")
  B:Cancel()
  openOn(B, 135350)
  assertEqual(B:State().tab, "game", "an id the host tab does not own opens on Game icons")
  B:Cancel()
  openOn(B, nil)
  assertEqual(B:State().tab, "rec", "nothing stored: the first tab, the host's")
  assertEqual(B:State().count, 2)
end)

test("browser: a hidden built-in tab has no strip button and SetTab refuses it", function()
  local _, B = boot(nil, { hide = { markers = true } })
  openOn(B, nil)
  -- red under: ignore spec.hide
  assertNil(tabButton(B, "Markers"), "no Markers button")
  assertTrue(tabButton(B, "Game icons") ~= nil)
  assertEqual(B:State().tab, "game", "the first tab left")
  B:SetTab("markers")
  assertEqual(B:State().tab, "game", "SetTab refuses a hidden tab")
  B:Cancel()
  openOn(B, SKULL)
  assertEqual(B:State().tab, "game", "a marker is owned by no tab offered")
  assertNil(B:State().selected)
end)

test("browser: a host's words replace the library's, and a locale that answers its key does not", function()
  local L = setmetatable({ HEADER = "Pick an outfit icon", CHOOSE = "Use" }, { __index = function(_, k) return k end })
  local _, B = boot(nil, { L = L })
  openOn(B, nil)
  assertEqual(B.ctx.panel.title:GetText(), "Pick an outfit icon")
  assertEqual(B:Widgets().choose.text, "Use")
  assertEqual(B:Widgets().cancel.text, "Cancel", "an unknown key reads the library's word")
end)

-- ── selecting and choosing ──────────────────────────────────────────────────────────────────

test("browser: a click selects, a double-click chooses; Choose hands the opener the icon", function()
  local _, B = boot()
  local chosen = openOn(B, nil)
  local cell = cellFor(B, SKULL)
  cell:__fire("OnClick")
  assertEqual(B:State().selected, SKULL)
  assertTrue(cell.selected:IsShown(), "highlighted")
  assertTrue(B:Widgets().name:GetText():find("Skull", 1, true) ~= nil, "named in the footer")
  assertFalse(B:Widgets().choose.disabled)
  assertEqual(#chosen, 0, "a click only selects")
  B:Widgets().choose:__fire("OnClick")
  assertEqual(#chosen, 1)
  assertEqual(chosen[1][1], SKULL)
  assertNil(chosen[1][2], "a marker carries no color")
  assertFalse(B:IsOpen())
  chosen = openOn(B, nil)
  cellFor(B, SKULL):__fire("OnDoubleClick")
  assertEqual(chosen[1][1], SKULL, "a double-click chooses")
  assertFalse(B:IsOpen())
  -- nothing selected: Choose is idle
  chosen = openOn(B, nil)
  assertTrue(B:Widgets().choose.disabled)
  local ok, why = B:Choose()
  assertFalse(ok)
  assertEqual(why, "noSelection")
  B:Widgets().cancel:__fire("OnClick")
  assertFalse(B:IsOpen())
  assertEqual(#chosen, 0, "Cancel hands nothing back")
  ok, why = B:Choose()
  assertFalse(ok)
  assertEqual(why, "notOpen")
end)

test("browser: hovering an icon names it, or gives a game icon's texture id", function()
  local m, B = boot()
  spells(m, { 136116 })
  local said = {}
  rawset(m.GameTooltip, "SetText", function(_, value) said[#said + 1] = value end)
  openOn(B, nil)
  cellFor(B, SKULL):__fire("OnEnter")
  assertEqual(said[#said], "Skull")
  B:SetTab("game")
  cellFor(B, 136116):__fire("OnEnter")
  assertEqual(said[#said], "Texture id 136116")
end)

test("browser: a long name in the footer stops at the Choose button, on one line", function()
  local _, B = boot()
  openOn(B, "Interface\\Icons\\Ability_Warrior_BattleShout")
  local w = B:Widgets()
  local right
  for _, p in ipairs(rawget(w.name, "__points") or {}) do if p[1] == "RIGHT" then right = p end end
  -- red under: anchor the name on its left side only
  assertTrue(right ~= nil, "the name has a right edge")
  assertEqual(right[2], w.choose.frame, "at the Choose button")
  assertFalse(w.name:CanWordWrap(), "a long name is cut, not wrapped")
end)

-- ── the grid ────────────────────────────────────────────────────────────────────────────────

test("browser: the grid sits a section gap under the toolbar's row", function()
  local _, B = boot()
  openOn(B, nil)
  local grid, area = B:Widgets().grid, B:Widgets().area
  local point, rel, relPoint, x, y = grid:GetPoint(1)
  assertEqual(point, "TOPLEFT")
  assertEqual(rel, area)
  assertEqual(relPoint, "TOPLEFT")
  assertEqual(x, 0)
  -- red under: put the grid straight under the 30px toolbar band (the swatch row touched it)
  assertTrue(-y >= 30 + 8, "at least 8px between the toolbar band and the grid, got " .. tostring(-y))
  assertEqual(-y, B.GRID_TOP)
end)

test("browser: Glyphs is every catalog icon at the host's folder", function()
  local m, B = boot()
  local Media = m.LibStub("LibKa0s-Media-1.0")
  openOn(B, nil)
  B:SetTab("glyphs")
  assertEqual(B:State().count, #Media.ICONS)
  assertEqual(B:Widgets().count:GetText(), #Media.ICONS .. " icons")
  assertEqual(B.cells[1].ibIcon, Media.Icon(OWNER, Media.ICONS[1]), "the owner's path")
end)

test("browser: Game icons is both macro lists, filtered All / Spells / Items", function()
  local m, B = boot()
  spells(m, { 1, 2, 3 }, { 3, 4, "Interface\\Icons\\X" })
  openOn(B, nil)
  B:SetTab("game")
  assertTrue(B:Widgets().filter.frame:IsShown(), "the filter shows on Game icons")
  assertFalse(B:Widgets().swatch.frame:IsShown(), "game icons take no color")
  assertEqual(B:State().count, 4)
  B:Widgets().filter:__fire("OnValueChanged", "items")
  assertEqual(B:State().filter, "items")
  assertEqual(B:State().count, 2)
  assertTrue(cellFor(B, 4) ~= nil)
  assertNil(cellFor(B, 1))
  B:SetFilter("nope")
  assertEqual(B:State().filter, "items", "an unknown filter is refused")
  B:SetTab("markers")
  assertFalse(B:Widgets().filter.frame:IsShown())
end)

test("browser: a filtered game list holds each icon once (the loose lists overlap the full ones)", function()
  local m, B = boot()
  spells(m, { 1, 2 }, { 4 })
  m.GetLooseMacroIcons = function(t) t[#t + 1] = 9; t[#t + 1] = 1 end
  openOn(B, nil)
  B:SetTab("game")
  B:SetFilter("spells")
  assertEqual(B:State().count, 3, "the count is of distinct icons")
end)

test("browser: the game list not loaded yet says so, and loads on a later visit", function()
  local m, B = boot()
  openOn(B, nil)
  B:SetTab("game")
  assertFalse(B:State().loaded)
  assertEqual(shownCells(B), 0)
  -- red under: say "Nothing to show here." for a list the client has not loaded
  assertTrue(B:Widgets().status:IsShown())
  assertTrue(B:Widgets().status:GetText():find("not loaded yet", 1, true) ~= nil)
  spells(m, { 10, 11 })
  B:SetTab("markers")
  B:SetTab("game")
  assertTrue(B:State().loaded)
  assertEqual(B:State().count, 2)
  assertFalse(B:Widgets().status:IsShown())
end)

test("browser: the grid is virtualized: a fixed set of cells re-dressed as it scrolls", function()
  local m, B = boot()
  spells(m, range(100000, 5000))
  openOn(B, nil)
  local cells = #B.cells
  B:SetTab("game")
  -- red under: build a cell per icon
  assertEqual(#B.cells, cells, "no cell is built for a longer list")
  assertEqual(#B.cells, B.COLS * B.ROWS)
  assertEqual(B.cells[1].ibIcon, 100001)
  local w = B:Widgets()
  w.grid:__fire("OnMouseWheel", -1)
  assertEqual(B:State().offset, 1, "the wheel scrolls a row")
  assertEqual(B.cells[1].ibIcon, 100001 + B.COLS)
  w.slider:__fire("OnValueChanged", 10)
  assertEqual(B:State().offset, 10, "so does the scrollbar")
  assertEqual(rawget(B.cells[1].icon, "__texture"), 100001 + 10 * B.COLS)
  w.slider:__fire("OnValueChanged", 99999)
  local last = math.ceil(5000 / B.COLS) - B.ROWS
  assertEqual(B:State().offset, last, "clamped to the last page")
  w.grid:__fire("OnMouseWheel", 5)
  assertEqual(B:State().offset, last - 5)
  B:ScrollTo(3)
  assertEqual(B:State().offset, 3, "ScrollTo")
  -- the stored icon deep in the list: its row is scrolled to
  B:Cancel()
  openOn(B, 100001 + 40 * B.COLS)
  assertEqual(B:State().offset, 40)
  assertTrue(cellFor(B, 100001 + 40 * B.COLS).selected:IsShown())
end)

test("browser: game icon art is cropped and edged; a glyph and a marker are drawn whole", function()
  local m, B = boot()
  spells(m, { 136116 })
  openOn(B, 136116)
  local cell = cellFor(B, 136116)
  -- red under: draw the art whole (its native rounded edge shows)
  assertEqual(table.concat({ cell.icon:GetTexCoord() }, ",", 1, 2), "0.07,0.07")
  assertTrue(cell.ibIconEdge ~= nil, "edged")
  assertTrue(B:Widgets().previewEdge ~= nil, "and the footer's too")
  B:SetTab("markers")
  local marker = cellFor(B, SKULL)
  assertEqual(table.concat({ marker.icon:GetTexCoord() }, ",", 1, 2), "0,0")
  assertNil(marker.ibIconEdge, "a marker takes no edge")
end)

test("browser: a scroll under the pointer re-says the hovered cell's tooltip, or hides it", function()
  local m, B = boot()
  spells(m, range(300000, 500))
  local tip, said, owner = m.GameTooltip, {}, nil
  rawset(tip, "SetOwner", function(_, o) owner = o end)
  rawset(tip, "GetOwner", function() return owner end)
  rawset(tip, "SetText", function(_, value) said[#said + 1] = value end)
  openOn(B, nil)
  B:SetTab("game")
  local cell = B.cells[#B.cells]
  cell:__fire("OnEnter")
  tip:Show()
  assertEqual(said[#said], "Texture id " .. cell.ibIcon)
  B:Widgets().grid:__fire("OnMouseWheel", -1)
  -- red under: leave the tooltip as OnEnter said it (draw() not refreshing the owner's tooltip)
  assertEqual(said[#said], "Texture id " .. cell.ibIcon, "the tooltip follows the cell's new icon")
  assertTrue(tip:IsShown())
  assertTrue(500 % B.COLS ~= 0, "the fixture leaves the last row short")
  B:Widgets().slider:__fire("OnValueChanged", 99999)
  assertFalse(cell:IsShown())
  assertFalse(tip:IsShown(), "an emptied cell keeps no tooltip")
end)

test("browser: the wheel over the scrollbar scrolls the grid too", function()
  local m, B = boot()
  spells(m, range(200000, 500))
  openOn(B, nil)
  B:SetTab("game")
  local slider = B:Widgets().slider
  -- red under: enable the wheel on the grid alone (the scrollbar is its sibling, not its child)
  assertTrue(slider.__scripts.OnMouseWheel ~= nil, "the scrollbar takes the wheel")
  slider:__fire("OnMouseWheel", -2)
  assertEqual(B:State().offset, 2)
  slider:__fire("OnMouseWheel", 1)
  assertEqual(B:State().offset, 1)
end)

test("browser: the area follows the tab band when the chrome learns its width (first open)", function()
  local _, B, _, helpers = boot()
  openOn(B, nil)
  local area = B:Widgets().area
  local before = area:GetPoint(1) and select(5, area:GetPoint(1))
  local gap = helpers.CHROME_GAP or 8
  B.ctx.chromeHeight = 28
  B.ctx.chrome:__fire("OnSizeChanged", 700, 28)
  -- red under: anchor the area once in drawTabs with no OnSizeChanged hook on the chrome
  assertEqual(select(5, area:GetPoint(1)), -(gap + B.ctx.chromeHeight), "the area sits under the new band")
  assertTrue(before ~= nil)
end)

-- ── the glyph color ─────────────────────────────────────────────────────────────────────────

test("browser: the swatch tints every glyph; Choose hands a glyph its color, white as none", function()
  local m, B = boot()
  local star = glyph(m, "star")
  local chosen = openOn(B, star)
  local w = B:Widgets()
  assertTrue(w.swatch.frame:IsShown(), "the swatch shows on Glyphs")
  w.swatch:__fire("OnValueChanged", 0, 1, 0, 1)
  assertEqual(B:State().color, "00ff00")
  -- red under: draw every cell white (no tint in dressCell)
  assertEqual(vertex(cellFor(B, star).icon), "0,1,0")
  assertEqual(vertex(w.preview), "0,1,0", "the selection is drawn in it")
  B:SetTab("markers")
  assertFalse(w.swatch.frame:IsShown(), "Markers holds no glyph")
  assertEqual(vertex(cellFor(B, SKULL).icon), "1,1,1", "a marker stays white")
  B:SetTab("glyphs")
  B:Choose()
  assertEqual(chosen[1][1], star)
  assertEqual(chosen[1][2], "00ff00")
  chosen = openOn(B, star, "ff0000")
  B:Widgets().swatch:__fire("OnValueConfirmed", 1, 1, 1, 1)
  assertNil(B:State().color, "white is none")
  B:Choose()
  assertNil(chosen[1][2])
  -- a non-glyph chosen carries no color, whatever the swatch says
  chosen = openOn(B, star, "ff0000")
  B:Select(SKULL)
  B:Choose()
  assertNil(chosen[1][2])
  -- a malformed color is refused
  openOn(B, star, "ff0000")
  B:SetColor("red")
  assertEqual(B:State().color, "ff0000")
end)

-- A stand-in for Blizzard's ColorPickerFrame (its OnHide runs when a shown frame hides), and a click
-- on `swatch` that opens it, as AceGUI's does.
local function picker(m)
  local f = m.CreateFrame("Frame")
  local hide = f.Hide
  rawset(f, "Hide", function(self)
    local was = self:IsShown()
    hide(self)
    if was then self:__fire("OnHide") end
    return self
  end)
  f:Hide()
  m.ColorPickerFrame = f
  return f
end

local function openPicker(f, swatch)
  f:Hide()
  f:Show()
  swatch.frame:__fire("OnClick")
end

test("browser: the color picker its swatch opened closes with the browser, and only that one", function()
  local m, B = boot()
  local f = picker(m)
  openOn(B, nil)
  B:SetTab("glyphs")
  openPicker(f, B:Widgets().swatch)
  B:Cancel()
  -- red under: leave ColorPickerFrame up in close()
  assertFalse(f:IsShown(), "the picker goes with the browser")
  -- a picker the swatch did not open (another addon's) is left alone
  openOn(B, nil)
  f:Show()
  B:Cancel()
  assertTrue(f:IsShown())
  f:Hide()
  -- the picker closed by its own OK/Cancel first: nothing is left to hide later
  openOn(B, nil)
  B:SetTab("glyphs")
  openPicker(f, B:Widgets().swatch)
  f:Hide()
  f:Show()
  B:Cancel()
  assertTrue(f:IsShown(), "the OnHide forgot the swatch")
end)

test("browser: a host's picker tracking is used in place of the browser's", function()
  local tracked, released = {}, {}
  local m, B = boot(nil, { trackPicker = function(s) tracked[#tracked + 1] = s end,
    releasePicker = function(s) released[#released + 1] = s end })
  local f = picker(m)
  openOn(B, nil)
  -- red under: track the swatch inside the library whatever the host passed
  assertEqual(#tracked, 1)
  assertEqual(tracked[1], B:Widgets().swatch)
  openPicker(f, B:Widgets().swatch)
  B:Cancel()
  assertEqual(released[1], B:Widgets().swatch, "the host releases its picker")
  assertTrue(f:IsShown(), "the browser leaves the picker to the host")
end)
