-- tests/test_callout_layout.lua — LibKa0s-Callout-1.0's CalloutSettings.lua minor 4: the section as
-- ONE host tab (plan row L13, the owner's redesign of 2026-11-14). A "Preview" heading over the
-- preview block, then Look and Sound side tabs (Options' O.SideTabs, OptionsNav minor 7), the
-- colors in Look, no stock texts; `SchemaRows`' and `SettingsRows`' `texts = false`; and the Play
-- list's "Countdown 10 to 1". The three-tab shape stays, and is re-pinned here beside the new one.
--
-- The benches are tests/test_callout_settings.lua's: the call-out from tests/fixture_callout.lua,
-- the page from tests/fixture_options.lua's host, widgets driven through their AceGUI callbacks.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local F = dofile("tests/fixture_callout.lua")
local Fixture = dofile("tests/fixture_options.lua")
local newCallout, parts, frameAt = F.newCallout, F.parts, F.frameAt

local panelSeq = 0
local function page(overrides)
  local O = Fixture.new(overrides)
  panelSeq = panelSeq + 1
  local ctx = O.CreatePanel("CalloutLayoutBench" .. panelSeq, "Callout " .. panelSeq, {})
  return O, ctx, O.EnsureScroll(ctx)
end

local function labeled(root, label)
  for _, w in ipairs(Fixture.flatten(root)) do
    if w.labelText == label then return w end
  end
end

local function texted(root, wtype, text)
  for _, w in ipairs(Fixture.flatten(root)) do
    if w.type == wtype and w.text == text then return w end
  end
end

local function headings(root)
  local out = {}
  for _, w in ipairs(Fixture.flatten(root)) do
    if w.type == "Heading" then out[#out + 1] = w.text end
  end
  return table.concat(out, ",")
end

--- The index of `w` among the page scroll's own children, or nil when it is not one of them.
local function topIndex(scroll, w)
  for i, child in ipairs(scroll.children or {}) do
    if child == w then return i end
    for _, inner in ipairs(Fixture.flatten(child)) do
      if inner == w then return i end
    end
  end
end

local function shown(c)
  local f, text = parts(c)
  if not f:IsShown() then return nil end
  return text:GetText()
end

-- ── the version ──────────────────────────────────────────────────────────────────────────────

test("callout layout: CalloutSettings is at minor 4, and an instance carries SettingsTab", function()
  local c, _, _, _, Callout = newCallout()
  assertEqual(Callout.MODULES.CalloutSettings, 4)
  assertEqual(Callout.__settingsMinor, 4)
  assertEqual(type(c.SettingsTab), "function")
  assertEqual(table.concat(Callout.SETTINGS_SIDE_TABS, ","), "look,sound")
  assertEqual(Callout.PLAY_COUNTDOWN, "countdown10")
end)

-- ── the one tab ──────────────────────────────────────────────────────────────────────────────

test("callout layout: SettingsTab answers one host tab, Callout, that draws the side layout", function()
  local c = newCallout()
  local O, ctx, scroll = page()
  local tab = c:SettingsTab({ options = O, before = "window" })
  assertEqual(tab.key, "callout")
  assertEqual(tab.label, "Callout")
  assertEqual(tab.before, "window")
  assertTrue(type(tab.tooltip) == "string" and tab.tooltip ~= "")
  tab.render(ctx)
  assertTrue(texted(scroll, "Heading", "Preview") ~= nil, "the tab draws its Preview block")
  assertEqual(c:SettingsTab({ key = "co_callout" }).key, "co_callout")
  local L = { TAB_CALLOUT = "Annonce" }
  assertEqual(c:SettingsTab({ L = L }).label, "Annonce", "the label is the host's word when it has one")
end)

test("callout layout: a Preview heading over the preview block, then side tabs Look and Sound", function()
  local c = newCallout()
  local O, ctx, scroll = page()
  local view = c:BuildSettings(ctx, { options = O, layout = "side" })
  assertEqual(view.layout, "side")
  local heading = texted(scroll, "Heading", "Preview")
  assertTrue(scroll.children[1] == heading, "the section opens with the Preview heading")
  local buttons, body = view.sideTabs, nil
  for _, w in ipairs(scroll.children) do
    if w.layout == "Ka0sSideTabs" then body = w.children[1] end
  end
  assertTrue(body ~= nil, "the side tabs are drawn in the page")
  local sideAt = topIndex(scroll, body)
  -- red under: the preview controls drawn inside a side tab, or under the side tabs
  for _, w in ipairs({ view.preview, texted(scroll, "Button", "Test countdown"), texted(scroll, "Button", "Play"),
    labeled(scroll, "Text to play"), labeled(scroll, "Unlock to move"), texted(scroll, "Button", "Reset position") }) do
    assertTrue(w ~= nil, "a preview control is drawn")
    assertTrue(topIndex(scroll, w) < sideAt, "every preview control is above the side tabs")
  end
  assertEqual(#buttons, 2)
  assertEqual(buttons[1].__ka0sNavText .. "," .. buttons[2].__ka0sNavText, "Look,Sound")
  assertEqual(view.side, "look", "Look is selected first")
end)

test("callout layout: Look holds the face rows and the Colors section; no Sound rows, no stock texts", function()
  local c, _, _, _, Callout = newCallout()
  local O, ctx, scroll = page()
  local view = c:BuildSettings(ctx, { options = O, layout = "side" })
  local body
  for _, w in ipairs(scroll.children) do
    if w.layout == "Ka0sSideTabs" then body = w.children[1] end
  end
  for _, label in ipairs({ "Font", "Size", "Outline", "Glow", "Shadow", "Animation", "Hold (seconds)", "Numbers", "Errors" }) do
    assertTrue(labeled(body, label) ~= nil, label .. " is in Look")
  end
  -- red under: Colors left on a Texts tab, or drawn above the side tabs
  assertEqual(headings(body), "Colors", "Look's one heading is Colors")
  assertNil(labeled(scroll, "Voice"), "Sound is not drawn while Look is selected")
  assertNil(labeled(scroll, "Mute STOP"), "no mute per stock key")
  assertNil(labeled(scroll, "READY"), "no text box per stock key")
  assertFalse(headings(scroll):find("Stock texts", 1, true) ~= nil, "no Stock texts section")
  assertFalse(headings(scroll):find("Texts", 1, true) ~= nil, "no Texts section")
  local colors = 0
  for _, r in ipairs(view.rows) do
    assertEqual(r.tab, "look")
    if r.type == "color" then colors = colors + 1 end
  end
  assertEqual(colors, #Callout.KINDS)
end)

--- A page whose renderer draws the side layout, shown once.
local function renderedSide(c, overrides)
  local O, ctx = page(overrides)
  local out = {}
  O.SetRenderer(ctx, function(cc)
    O.ClearScroll(cc)
    out.view = c:BuildSettings(cc, { options = O, layout = "side" })
  end)
  ctx.panel:Show()
  ctx.panel:__fire("OnShow")
  return O, ctx, out
end

test("callout layout: the Sound side tab draws the voice rows, and the choice holds across a redraw", function()
  local c, _, db = newCallout()
  local _, ctx, out = renderedSide(c)
  out.view.sideTabs[2]:__fire("OnClick")
  assertEqual(out.view.side, "sound", "the page re-rendered on Sound")
  for _, label in ipairs({ "Voice", "Sound channel", "Speak numbers from" }) do
    assertTrue(labeled(ctx.scroll, label) ~= nil, label .. " is in Sound")
  end
  assertNil(labeled(ctx.scroll, "Size"), "Look's rows are gone")
  labeled(ctx.scroll, "Voice"):__fire("OnValueChanged", "off")
  assertEqual(db.voice, "off", "a Sound row writes the host db")
  -- A second section build (another page draw) opens where the player left it.
  local O2, ctx2 = page()
  assertEqual(c:BuildSettings(ctx2, { options = O2, layout = "side" }).side, "sound",
    "the side tab is the instance's session state")
end)

test("callout layout: a Look row writes the host db and repaints the preview", function()
  local c, _, db = newCallout()
  local O, ctx, scroll = page()
  local view = c:BuildSettings(ctx, { options = O, layout = "side" })
  labeled(scroll, "Outline"):__fire("OnValueChanged", "MONOCHROME")
  assertEqual(db.outline, "MONOCHROME")
  labeled(scroll, "Numbers"):__fire("OnValueConfirmed", 0, 0, 1, 1)
  assertEqual(table.concat(db.colors.number, ","), "0,0,1")
  O.RefreshScalars()
  assertTrue(view.preview.text:find("0000ff", 1, true) ~= nil, "the preview repaints in the new color")
end)

test("callout layout: an Options copy without SideTabs draws Look and Sound under their headings", function()
  local c = newCallout()
  local O, ctx, scroll = page()
  local older = setmetatable({ SideTabs = false }, { __index = O })
  local view = c:BuildSettings(ctx, { options = older, layout = "side" })
  assertTrue(view ~= nil)
  assertEqual(headings(scroll), "Preview,Look,Colors,Sound", "the older copy still has every row but the texts")
  assertNil(labeled(scroll, "Mute STOP"))
end)

test("callout layout: an unknown layout answers nil; the layout wins over a tab", function()
  local c = newCallout()
  local O, ctx, scroll = page()
  assertNil(c:BuildSettings(ctx, { options = O, layout = "grid" }))
  local view = c:BuildSettings(ctx, { options = O, layout = "side", tab = "texts" })
  assertEqual(view.layout, "side", "opts.tab is not read with a layout")
  assertNil(labeled(scroll, "Mute STOP"))
end)

test("callout layout: the plain build's side layout draws Look and Sound with no stock texts", function()
  local c, m, _, _, Callout = newCallout()
  local parent = m.CreateFrame("Frame", nil, m.UIParent)
  local view = c:BuildSettings(parent, { layout = "side" })
  assertEqual(view.kind, "plain")
  local groups, colors = {}, 0
  for _, r in ipairs(view.rows) do
    groups[r.group] = true
    assertFalse(r.key:find("^muted%.") ~= nil or r.key:find("^texts%.") ~= nil, r.key .. " is no stock text row")
    if r.type == "color" then colors = colors + 1; assertEqual(r.group, "Look") end
  end
  assertTrue(groups.Look and groups.Sound and not groups.Texts)
  assertEqual(colors, #Callout.KINDS)
end)

-- ── the rows ─────────────────────────────────────────────────────────────────────────────────

--- How many rows of `rows` have a key (or path) starting with one of the stock text prefixes.
local function stockRows(rows, field)
  local n = 0
  for _, r in ipairs(rows) do
    local k = r[field] or ""
    if k:find("texts.", 1, true) or k:find("muted.", 1, true) then n = n + 1 end
  end
  return n
end

test("callout layout: SchemaRows with texts = false leaves the stock texts' rows out, colors on Look", function()
  local c, _, _, _, Callout = newCallout()
  local all = c:SchemaRows("callout.")
  local lean = c:SchemaRows("callout.", { texts = false })
  assertEqual(stockRows(all, "path"), 2 * #Callout.STOCK_ORDER, "by default every stock key has a text and a mute row")
  -- red under: texts = false ignored, or the colors dropped with the texts
  assertEqual(stockRows(lean, "path"), 0, "texts = false: no texts.<KEY> and no muted.<KEY>")
  assertEqual(#lean, #all - 2 * #Callout.STOCK_ORDER, "and nothing else goes")
  for _, r in ipairs(lean) do
    if r.type == "color" then assertEqual(r.tab, "look", r.path .. " is on Look") end
  end
  for _, r in ipairs(all) do
    if r.type == "color" then assertEqual(r.tab, "texts", r.path .. " stays on Texts by default") end
  end
end)

test("callout layout: SettingsRows with texts = false is the one tab's rows", function()
  local c = newCallout()
  local rows = c:SettingsRows({ texts = false })
  assertEqual(stockRows(rows, "key"), 0)
  local look = c:SettingsRows({ texts = false, tab = "look" })
  local colors = 0
  for _, r in ipairs(look) do if r.type == "color" then colors = colors + 1 end end
  assertEqual(colors, 6, "Look carries the colors")
  assertEqual(#c:SettingsRows({ texts = false, tab = "texts" }), 0, "there is no Texts tab")
end)

-- ── Countdown 10 to 1 ────────────────────────────────────────────────────────────────────────

test("callout layout: Text to play leads with Countdown 10 to 1, then every stock text", function()
  local c, _, _, _, Callout = newCallout()
  local O, ctx, scroll = page()
  c:BuildSettings(ctx, { options = O, layout = "side" })
  local values
  for _, r in ipairs(c:SchemaRows("callout.")) do
    if r.key == "play" then values = r.values end
  end
  assertEqual(values[1].value, Callout.PLAY_COUNTDOWN)
  assertEqual(values[1].text, "Countdown 10 to 1")
  assertEqual(#values, 1 + #Callout.STOCK_ORDER)
  assertTrue(labeled(scroll, "Text to play") ~= nil)
end)

test("callout layout: Play with Countdown 10 to 1 counts the real call-out from 10 to 1, with no finish", function()
  local c, m = newCallout()
  local O, ctx, scroll = page()
  c:BuildSettings(ctx, { options = O, layout = "side" })
  frameAt(m, 100)
  labeled(scroll, "Text to play"):__fire("OnValueChanged", "countdown10")
  local spoken = #m.__files
  texted(scroll, "Button", "Play"):__fire("OnClick")
  local running, n = c:Running()
  assertTrue(running)
  assertEqual(n, 10, "it starts at 10")
  assertEqual(shown(c), "10")
  assertEqual(#m.__files, spoken, "10 is above Speak numbers from (5), so it is not spoken")
  frameAt(m, 105.5)
  assertEqual(shown(c), "5")
  assertEqual(#m.__files, spoken + 1, "5 is spoken")
  frameAt(m, 109.5)
  assertEqual(shown(c), "1")
  frameAt(m, 110.1)
  -- red under: the countdown left on its GO finish
  assertFalse((c:Running()), "the countdown is over")
  assertFalse(shown(c) == "GO!", "and no finish is shown")
end)

test("callout layout: the countdown pick is a session value the route's validate accepts", function()
  local c = newCallout()
  local play
  for _, r in ipairs(c:SchemaRows("callout.")) do
    if r.key == "play" then play = r end
  end
  assertTrue(play.validate("countdown10"))
  assertTrue(play.validate("GO"))
  assertFalse(play.validate("countdown5"))
  play.set("countdown10")
  assertEqual(play.get(), "countdown10")
  play.set("nonsense")
  assertEqual(play.get(), "countdown10", "an unknown pick is refused")
end)

-- ── the three-tab shape, unchanged ───────────────────────────────────────────────────────────

test("callout layout: SettingsTabs and the three-tab build are as they were", function()
  local c = newCallout()
  local O, ctx, scroll = page()
  local tabs = c:SettingsTabs({ options = O })
  assertEqual(#tabs, 3)
  assertEqual(tabs[3].key, "callout.texts")
  c:BuildSettings(ctx, { options = O })
  assertEqual(headings(scroll), "Look,Sound,Texts,Colors,Stock texts")
  assertTrue(labeled(scroll, "Mute STOP") ~= nil, "the three-tab build still draws the stock texts")
end)
