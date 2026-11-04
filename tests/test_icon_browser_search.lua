-- tests/test_icon_browser_search.lua — LibKa0s-IconBrowser-1.0's browser, continued from
-- tests/test_icon_browser.lua: the search box, the Wowhead hint, the icon sets, what closes the
-- browser (Escape over an opener, Cancel(owner), Revalidate, combat, the stand-down) and two browsers
-- side by side. Ported from Ka0s Quick Comms' tests/test_icon_browser.lua; the bench is
-- tests/fixture_icon_browser.lua.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local F = dofile("tests/fixture_icon_browser.lua")
local OWNER, SKULL, OPENER = F.OWNER, F.SKULL, F.OPENER
local env, browserOf, boot, flush, openOn = F.env, F.browserOf, F.boot, F.flush, F.openOn
local cellFor, shownCells, listed, glyph = F.cellFor, F.shownCells, F.listed, F.glyph
local spells = F.spells

-- ── search ──────────────────────────────────────────────────────────────────────────────────

test("browser: the search box filters the tab as you type; the count says N of M", function()
  local m, B = boot()
  local list = { 132092, 99, 51320, 136116 }
  for i = 1, 2000 do
    if not tostring(700000 + i):find("132", 1, true) then list[#list + 1] = 700000 + i end
  end
  spells(m, list)
  openOn(B, nil)
  B:SetTab("game")
  local w = B:Widgets()
  -- red under: no search box on the toolbar
  assertTrue(w.search ~= nil and w.search.frame:IsShown(), "the search box")
  assertTrue(w.search.buttonDisabled, "no Okay button: it filters as you type")
  assertEqual(w.count:GetText(), #list .. " icons", "unfiltered, the count is the tab's")
  assertFalse(w.clear:IsShown(), "no clear mark while empty")
  B:ScrollTo(10)
  w.search:__fire("OnTextChanged", "132")
  assertEqual(B:State().search, "132")
  assertEqual(B:State().count, 2)
  assertEqual(B:State().total, #list)
  -- red under: keep "%d icons" while a search narrows the tab
  assertEqual(w.count:GetText(), "2 of " .. #list .. " icons")
  assertEqual(B:State().offset, 0, "the results from the top")
  assertTrue(cellFor(B, 51320) ~= nil)
  assertNil(cellFor(B, 99))
  assertTrue(w.clear:IsShown())
  w.clear:__fire("OnClick")
  assertEqual(B:State().search, "")
  assertEqual(w.search.text, "", "the box is emptied")
  assertFalse(w.clear:IsShown())
  assertEqual(B:State().count, #list)
  B:SetSearch("zzz")
  assertEqual(shownCells(B), 0)
  assertTrue(w.status:IsShown())
  assertEqual(w.status:GetText(), "No icon matches your search.")
end)

test("browser: the search box keeps its text inset clear of the magnifier after AceGUI resets it", function()
  local _, B = boot()
  openOn(B, nil)
  B:SetTab("glyphs")
  local w = B:Widgets()
  local input = w.search.editbox or w.search.frame
  local left
  rawset(input, "SetTextInsets", function(_, l) left = l end)
  -- AceGUI's EditBox runs HideButton (insets 0, 0, 3, 3) from SetText, Enter and a drop
  local setText = w.search.SetText
  w.search.SetText = function(self, ...)
    setText(self, ...)
    input:SetTextInsets(0, 0, 3, 3)
  end
  B:SetSearch("x")
  B:SetSearch("")
  -- red under: set the insets once in buildSearch
  assertEqual(left, 14 + 4, "after the clear mark's SetText")
  for _, script in ipairs({ "OnEnterPressed", "OnReceiveDrag" }) do
    input:SetTextInsets(0, 0, 3, 3)
    input:__fire(script)
    assertEqual(left, 14 + 4, "after " .. script)
  end
end)

test("browser: the search is kept across tabs and the session's opens, and re-filters each tab", function()
  local m, B, IB = boot()
  openOn(B, nil)
  B:SetSearch("star")
  assertEqual(B:State().count, 1, "Markers: the Star")
  assertTrue(cellFor(B, IB.Sources.MarkerPath(1)) ~= nil)
  B:SetTab("glyphs")
  -- red under: clear the search on a tab switch
  assertEqual(B:State().search, "star")
  assertTrue(cellFor(B, glyph(m, "star")) ~= nil)
  B:Cancel()
  openOn(B, nil)
  -- red under: reset the search in Open
  assertEqual(B:State().search, "star", "kept for the session")
  assertEqual(B:Widgets().search.text, "star", "and shown in the box")
  assertEqual(B:State().count, 1)
end)

test("browser: Game icons carries the Wowhead hint; its button shows the address in a copy window", function()
  local m, B = boot()
  openOn(B, nil)
  local w = B:Widgets()
  -- red under: no hint row
  assertTrue(w.hint ~= nil)
  assertFalse(w.hint:IsShown(), "not on Markers")
  B:SetTab("game")
  assertTrue(w.hint:IsShown(), "on Game icons")
  local said = w.hintText:GetText()
  assertTrue(said:find("Search by texture id.", 1, true) ~= nil)
  assertTrue(said:find("ability_cheapshot", 1, true) ~= nil)
  assertTrue(said:find("Wowhead", 1, true) ~= nil)
  local point, rel, relPoint = w.hint:GetPoint(1)
  assertEqual(point, "TOPLEFT")
  assertEqual(rel, w.grid)
  assertEqual(relPoint, "BOTTOMLEFT")
  B:SetTab("glyphs")
  assertFalse(w.hint:IsShown())
  B:SetTab("game")
  local win = B:LinkWindow()
  assertTrue(win ~= nil, "the library's copy window")
  local shown
  local show = win.Show
  win.Show = function(self, value)
    shown = value
    return show(self, value)
  end
  w.link:__fire("OnClick")
  -- red under: a link button that shows nothing
  assertEqual(shown, "https://www.wowhead.com/icons")
  local f = m.__named.TestHostIconBrowserLinkWindow
  assertTrue(f ~= nil and f:IsShown())
  -- red under: leave the copy window in the browser's strata, under its catcher
  assertEqual(m.__layers(f).strata, "FULLSCREEN_DIALOG", "above the browser")
  B:Cancel()
  assertFalse(f:IsShown(), "it goes with the browser")
end)

test("browser: a host's copy window is used when it passes one", function()
  local made
  local _, B = boot(nil, { copyWindow = function(d)
    made = d
    return { Show = function() end, Hide = function() end }
  end })
  openOn(B, nil)
  assertTrue(B:LinkWindow() ~= nil)
  assertEqual(made.title, "Ka0s Test Host: Wowhead icons")
  assertEqual(made.addonName, OWNER)
end)

-- ── the icon sets ───────────────────────────────────────────────────────────────────────────

test("browser: [sets] the glyph tab reads the session's list on every keystroke", function()
  local _, B, IB = boot({ catalog = true })
  local Src = IB.Sources
  local seen = {}
  local list = Src.List
  Src.List = function(...)
    local out, loaded = list(...)
    seen[#seen + 1] = out
    return out, loaded
  end
  openOn(B, nil)
  B:SetTab("glyphs")
  B:SetSearch("a")
  B:SetSearch("ar")
  B:SetSearch("arr")
  Src.List = list
  table.remove(seen, 1)   -- the Markers tab the browser opened on
  assertTrue(#seen >= 4)
  -- red under: rebuild the glyph list per read (Search's memos would miss)
  for i = 1, #seen do assertTrue(seen[i] == Src.Glyphs(OWNER), "read " .. i .. " is the session's list") end
end)

test("browser: [sets] the Glyphs filter lists the library's sets and narrows to one", function()
  local m, B, IB = boot({ catalog = true })
  local Src = IB.Sources
  local all, ph = #Src.Glyphs(OWNER), #Src.Glyphs(OWNER, "phosphor")
  openOn(B, nil)
  B:SetTab("glyphs")
  local w = B:Widgets()
  assertTrue(w.sets ~= nil and w.sets.frame:IsShown(), "the set filter shows on Glyphs")
  assertEqual(table.concat(w.sets.order, ","), "all,open-iconic,phosphor,game-icons")
  assertFalse(w.filter.frame:IsShown(), "the game filter does not")
  assertTrue(w.swatch.frame:IsShown(), "the swatch still does")
  assertEqual(B:State().glyphSet, "all")
  assertEqual(B:State().count, all)
  w.sets:__fire("OnValueChanged", "phosphor")
  assertEqual(B:State().glyphSet, "phosphor")
  assertEqual(B:State().count, ph)
  assertEqual(w.count:GetText(), ph .. " icons")
  B:SetSearch("arrow-up")
  assertTrue(B:State().count > 0 and B:State().count < ph)
  assertEqual(w.count:GetText(), B:State().count .. " of " .. ph .. " icons")
  B:SetSearch("")
  B:SetTab("game")
  assertFalse(w.sets.frame:IsShown())
  assertEqual(B:State().filter, "all")
  B:SetTab("glyphs")
  assertEqual(B:State().glyphSet, "phosphor", "kept across a tab switch")
  B:SetGlyphSet("nope")
  assertEqual(B:State().glyphSet, "phosphor", "an unknown set is refused")
  -- a stored glyph from another set opens on All, so it can be shown selected
  B:Cancel()
  openOn(B, glyph(m, "gi:sword-wound"))
  assertEqual(B:State().tab, "glyphs")
  assertEqual(B:State().glyphSet, "all")
  assertTrue(cellFor(B, glyph(m, "gi:sword-wound")) ~= nil, "scrolled to it")
end)

test("browser: [sets] a glyph's tooltip names its set, and a Game-icons mark its author", function()
  local m, B = boot({ catalog = true })
  local lines = {}
  rawset(m.GameTooltip, "SetText", function(_, value) lines = { value } end)
  rawset(m.GameTooltip, "AddLine", function(_, value) lines[#lines + 1] = value end)
  local who = m.LibStub("LibKa0s-Media-1.0").IconAuthor("gi:sword-wound")
  assertTrue(type(who) == "string" and who ~= "", "the library names the author")
  openOn(B, glyph(m, "gi:sword-wound"))
  cellFor(B, glyph(m, "gi:sword-wound")):__fire("OnEnter")
  assertEqual(lines[1], "Sword wound")
  -- red under: no author line on a Game-icons tooltip (CC BY 3.0 asks for the credit)
  assertTrue(listed(lines, "Game-icons, by " .. who), "names the set and the author")
  B:SetGlyphSet("phosphor")
  B:SetSearch("ph:arrow-up")
  cellFor(B, glyph(m, "ph:arrow-up")):__fire("OnEnter")
  assertEqual(lines[1], "Arrow up")
  assertTrue(listed(lines, "Phosphor"), "names the set")
  B:SetSearch("")
  B:SetTab("markers")
  cellFor(B, SKULL):__fire("OnEnter")
  assertEqual(#lines, 2, "a marker: its name and the click line, no set")
end)

-- ── what closes it ──────────────────────────────────────────────────────────────────────────

test("browser: Escape over an opener closes the browser only; the opener's Escape comes back after", function()
  local m, B = boot()
  local opener = m.CreateFrame("Frame", OPENER)
  m.UISpecialFrames[#m.UISpecialFrames + 1] = OPENER
  openOn(B, nil, nil, { lift = { OPENER } })
  -- red under: leave the opener's special frame listed (Escape hides every shown one)
  assertFalse(listed(m.UISpecialFrames, OPENER), "the opener is out of Escape's list")
  assertTrue(listed(m.UISpecialFrames, "TestHostIconBrowser"))
  -- Escape, as the client does it: every listed special frame that is shown is hidden
  for _, name in ipairs(m.UISpecialFrames) do
    local f = m.__named[name]
    if f and f:IsShown() then
      f:Hide()
      f:__fire("OnHide")
    end
  end
  assertFalse(B:IsOpen(), "the browser closed")
  assertTrue(opener:IsShown(), "the opener did not")
  -- red under: put the name back at once (inside the client's walk of the list)
  assertFalse(listed(m.UISpecialFrames, OPENER), "back on the next frame, not now")
  flush(m)
  assertTrue(listed(m.UISpecialFrames, OPENER), "the opener's Escape is back")
  -- opened and closed again before the next frame: listed once
  openOn(B, nil, nil, { lift = { OPENER } })
  B:Cancel()
  openOn(B, nil, nil, { lift = { OPENER } })
  assertFalse(listed(m.UISpecialFrames, OPENER), "still out while open")
  B:Cancel()
  flush(m)
  local n = 0
  for _, name in ipairs(m.UISpecialFrames) do if name == OPENER then n = n + 1 end end
  assertEqual(n, 1)
end)

test("browser: Cancel(owner) closes only that owner's browser; Revalidate closes a gone opener's", function()
  local _, B = boot()
  openOn(B, nil)
  B:Cancel("popup")
  -- red under: ignore Cancel's owner
  assertTrue(B:IsOpen(), "Cancel(owner) closes only that owner's browser")
  B:Cancel("test")
  assertFalse(B:IsOpen())
  local alive = true
  openOn(B, nil, nil, { valid = function() return alive end })
  B:Revalidate()
  assertTrue(B:IsOpen(), "a valid opener keeps it")
  alive = false
  B:Revalidate()
  assertFalse(B:IsOpen(), "a gone opener closes it")
  -- and Choose refuses to hand a gone opener anything
  local chosen = openOn(B, SKULL, nil, { valid = function() return alive end })
  local ok, why = B:Choose()
  assertFalse(ok)
  assertEqual(why, "notOpen")
  assertEqual(#chosen, 0)
  assertFalse(B:IsOpen())
end)

test("browser: Choose in combat answers false, \"combat\" and calls nothing", function()
  local m, B = boot()
  local chosen = openOn(B, nil)
  B:Select(SKULL)
  m.__combat = true
  local ok, why = B:Choose()
  -- red under: drop the combat refusal in Choose
  assertFalse(ok)
  assertEqual(why, "combat")
  assertEqual(#chosen, 0)
  assertTrue(B:IsOpen(), "the browser stays open")
  assertTrue(table.concat(m.prints, "\n"):find("cannot choose an icon during combat", 1, true) ~= nil)
  m.__combat = false
  assertTrue(B:Choose())
  assertEqual(chosen[1][1], SKULL)
end)

test("browser: without inCombat the client's combat lockdown refuses Choose", function()
  local m, IB, helpers = env()
  local B = IB:New({ owner = OWNER, helpers = helpers })
  local chosen = openOn(B, SKULL)
  m.InCombatLockdown = function() return true end
  local ok, why = B:Choose()
  assertFalse(ok)
  assertEqual(why, "combat")
  assertEqual(#chosen, 0)
end)

test("browser: a stand-down closes it and refuses an open until the stand-up", function()
  local _, B = boot()
  openOn(B, nil)
  B:StandDown()
  -- red under: no StandDown on the browser
  assertFalse(B:IsOpen())
  assertFalse(B:Open({ owner = "test", onChoose = function() end }), "stood down, it cannot open")
  B:StandUp()
  assertTrue(B:Open({ owner = "test", onChoose = function() end }), "it opens again after a stand-up")
end)

-- ── two browsers ────────────────────────────────────────────────────────────────────────────

test("browser: two instances do not share selection or search", function()
  local m, IB, helpers = env()
  local A = browserOf(m, IB, helpers)
  local B = browserOf(m, IB, helpers, { hide = { markers = true } })
  openOn(A, SKULL)
  openOn(B, glyph(m, "star"))
  A:SetSearch("sk")
  -- red under: keep the browser's state in file locals
  assertEqual(A:State().selected, SKULL)
  assertEqual(B:State().selected, glyph(m, "star"))
  assertEqual(B:State().search, "", "B's search is its own")
  assertEqual(A:State().tab, "markers")
  assertEqual(B:State().tab, "glyphs")
  assertTrue(A.frame ~= B.frame, "a window each")
  assertEqual(m.__named.TestHostIconBrowser2, B.frame, "the second numbered")
  A:Cancel()
  assertTrue(B:IsOpen(), "closing one leaves the other")
end)
