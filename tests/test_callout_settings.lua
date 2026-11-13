-- tests/test_callout_settings.lua — LibKa0s-Callout-1.0's CalloutSettings.lua (minor 1): the settings
-- section a consumer drops into its own panel (plan row L4).
--
-- Two benches. The call-out is tests/fixture_callout.lua's (its own environment, CalloutSettings.lua
-- loaded after Callout.lua). The Options build draws into a page of tests/fixture_options.lua's
-- host, an Options instance in the runner's environment: the section only calls that instance's
-- members, so the two environments meet exactly where a host's page and the library meet. A row
-- is driven the way a player drives it, by firing its AceGUI widget's callback, and read back out
-- of the host's db.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local F = dofile("tests/fixture_callout.lua")
local Fixture = dofile("tests/fixture_options.lua")
local newCallout, parts, tts = F.newCallout, F.parts, F.tts

local panelSeq = 0
local function page()
  local O = Fixture.new()
  panelSeq = panelSeq + 1
  local ctx = O.CreatePanel("CalloutSettingsBench" .. panelSeq, "Call-out " .. panelSeq, {})
  return O, ctx, O.EnsureScroll(ctx)
end

local function widgets(scroll) return Fixture.flatten(scroll) end

local function widgetLabeled(scroll, label)
  for _, w in ipairs(widgets(scroll)) do
    if w.labelText == label then return w end
  end
end

local function widgetTexted(scroll, wtype, text)
  for _, w in ipairs(widgets(scroll)) do
    if w.type == wtype and w.text == text then return w end
  end
end

local function rowsByKey(rows)
  local out = {}
  for _, r in ipairs(rows) do out[r.key] = r end
  return out
end

local function shown(c)
  local f, text = parts(c)
  if not f:IsShown() then return nil end
  return text:GetText()
end

-- ── the version ──────────────────────────────────────────────────────────────────────────────

test("callout settings: CalloutSettings is at minor 1, paired on the Callout shell's minor", function()
  local c, _, _, _, Callout = newCallout()
  assertEqual(Callout.MODULES.CalloutSettings, 1)
  assertEqual(Callout.__settingsMinor, 1)
  assertEqual(Callout.__settingsShellMinor, Callout.MINOR)
  for _, name in ipairs({ "BuildSettings", "SettingsRows", "SettingsTabs", "Preview", "TestCountdown", "Look" }) do
    assertEqual(type(c[name]), "function", "an instance has " .. name)
  end
end)

-- ── the rows ─────────────────────────────────────────────────────────────────────────────────

test("callout settings: the rows are Look, Sound then Texts, each path-less and bound to the instance", function()
  local c = newCallout()
  local rows = c:SettingsRows()
  local order, seen = {}, {}
  for _, r in ipairs(rows) do
    assertNil(r.path, r.label .. " has no path")
    assertEqual(type(r.get), "function", r.label .. " reads through its get")
    assertEqual(type(r.set), "function", r.label .. " writes through its set")
    assertTrue(type(r.tooltip) == "string" and r.tooltip ~= "", r.label .. " has a tooltip")
    if not seen[r.group] then seen[r.group] = true; order[#order + 1] = r.group end
  end
  assertEqual(table.concat(order, ","), "Look,Sound,Texts")
  local by = rowsByKey(rows)
  assertEqual(by.font.dialogControl, "Ka0sMedia_Font", "the font row is the one media picker (options-ui-§23)")
  local fonts = {}
  for i, v in ipairs(by.font.values()) do fonts[i] = v.value end
  assertEqual(fonts[1] .. "," .. fonts[2], "Skin font,Game default", "the skin's and the game's face lead")
  assertTrue(table.concat(fonts, ","):find("Ka0s Oxanium Bold", 1, true) ~= nil, "the default face is offered")
end)

test("callout settings: the Texts tab has a color per kind, and a text box and a mute per stock key", function()
  local c, _, _, _, Callout = newCallout()
  local colors, texts, mutes = 0, 0, 0
  for _, r in ipairs(c:SettingsRows({ tab = "texts" })) do
    assertEqual(r.tab, "texts")
    if r.type == "color" then colors = colors + 1; assertFalse(r.hasAlpha) end
    if r.dialogControl == "EditBox" then texts = texts + 1 end
    if r.type == "bool" then mutes = mutes + 1 end
  end
  assertEqual(colors, #Callout.KINDS)
  assertEqual(texts, #Callout.STOCK_ORDER)
  assertEqual(mutes, #Callout.STOCK_ORDER)
  local plain = c:SettingsRows({ tab = "texts", plain = true })
  assertEqual(#plain, #Callout.KINDS + #Callout.STOCK_ORDER, "the plain build has no text boxes")
end)

test("callout settings: text to speech rows are there only while the client lists a voice", function()
  local c = newCallout()
  assertNil(rowsByKey(c:SettingsRows({ tab = "sound" })).ttsVoice, "no C_VoiceChat: no voice row")
  local c2 = newCallout(nil, function(m) tts(m, {}) end)
  assertNil(rowsByKey(c2:SettingsRows({ tab = "sound" })).ttsVoice, "no voice installed: no voice row")
  local c3, _, db = newCallout(nil, function(m) tts(m, { { voiceID = 3, name = "Zira" }, { voiceID = 7, name = "David" } }) end)
  local by = rowsByKey(c3:SettingsRows({ tab = "sound" }))
  assertEqual(#by.ttsVoice.values, 2)
  assertEqual(by.ttsVoice.values[2].text, "David")
  assertEqual(by.ttsVoice.get(), 3, "nothing chosen reads as the client's first voice")
  assertTrue(by.ttsVoice.disabledIf(), "drawn disabled while the voice is not text to speech")
  db.voice = "tts"
  assertFalse(by.ttsVoice.disabledIf())
  assertFalse(by.ttsRate.disabledIf())
end)

test("callout settings: every row writes the host db", function()
  local c, _, db = newCallout(nil, function(m) tts(m, { { voiceID = 3, name = "Zira" }, { voiceID = 7, name = "David" } }) end)
  local by = rowsByKey(c:SettingsRows())
  local writes = {
    font = "Game default", size = 120, outline = "OUTLINE", glow = "strong", shadow = false,
    shadowX = 4, shadowY = -4, anim = "pulse", hold = 2.5, voice = "male", channel = "SFX",
    speakFrom = 3, ttsVoice = 7, ttsRate = 2, ttsVolume = 50,
  }
  for key, v in pairs(writes) do
    by[key].set(v)
    assertEqual(db[key], v, key .. " is written into the db")
    assertEqual(by[key].get(), v, key .. " reads it back")
  end
  by["colors.go"].set({ r = 0.1, g = 0.2, b = 0.3, a = 1 })
  assertEqual(table.concat(db.colors.go, ","), "0.1,0.2,0.3", "a named-key color is stored as the call-out's array")
  by["colors.stop"].set({ 0.4, 0.5, 0.6, 1 })
  assertEqual(table.concat(db.colors.stop, ","), "0.4,0.5,0.6", "an array color too")
  local read = by["colors.go"].get()
  assertEqual(read.r .. "," .. read[1], "0.1,0.1", "a swatch reads both shapes, for either host codec")
  by["texts.GO"].set("  Charge  ")
  assertEqual(db.texts.GO, "Charge", "a stock key's own text, trimmed")
  by["texts.GO"].set("")
  assertNil(db.texts.GO, "empty clears it back to the stock text")
  by["muted.STOP"].set(true)
  assertTrue(db.muted.STOP)
  assertTrue(by["muted.STOP"].get())
  by["muted.STOP"].set(false)
  assertNil(db.muted.STOP, "unmuted leaves no key behind")
end)

test("callout settings: a muted stock key shows without its voice; the rest still speak", function()
  local c, m, db = newCallout()
  db.muted = { GO = true }
  assertTrue(c:Show("GO"))
  assertEqual(shown(c), "GO!", "it still shows")
  assertEqual(#m.__files, 0, "and says nothing")
  assertTrue(c:Show("STOP"))
  assertEqual(#m.__files, 1, "another key speaks")
  db.muted = { GO = "yes" }
  assertEqual(next(c:Get("muted")), nil, "an invalid mute table reads as the default")
end)

test("callout settings: Look answers the look the frame draws", function()
  local c, _, db = newCallout()
  db.size, db.outline, db.shadow, db.font = 64, "NONE", false, "Game default"
  local look = c:Look()
  assertEqual(look.size, 64)
  assertEqual(look.flags, "", "no outline is no flags")
  assertFalse(look.shadow)
  assertEqual(look.font, "Fonts\\FRIZQT__.TTF")
end)

-- ── the Options build ────────────────────────────────────────────────────────────────────────

test("callout settings: one tab builds with the Options instance's own widgets", function()
  local c = newCallout()
  local O, ctx, scroll = page()
  local view = c:BuildSettings(ctx, { options = O, tab = "look" })
  assertEqual(view.kind, "options")
  assertTrue(view.preview ~= nil and view.preview.type == "Label", "the preview is a Label on the page")
  assertTrue(tostring(view.preview.text):find("GO!", 1, true) ~= nil, "it shows the sample line")
  assertEqual(widgetLabeled(scroll, "Size").type, "Slider")
  assertEqual(widgetLabeled(scroll, "Shadow").type, "CheckBox")
  assertEqual(widgetLabeled(scroll, "Outline").type, "Dropdown")
  assertEqual(widgetLabeled(scroll, "Unlock to move").type, "CheckBox")
  assertEqual(widgetLabeled(scroll, "Text to play").type, "Dropdown")
  assertNil(widgetLabeled(scroll, "Voice"), "one tab: the Sound rows are not drawn")
  for _, w in ipairs(widgets(scroll)) do
    assertFalse(w.type == "Heading" and w.text == "Look", "one tab draws no heading of its own")
  end
end)

test("callout settings: a widget's change writes the host db and repaints the preview", function()
  local c, _, db = newCallout()
  local O, ctx, scroll = page()
  local view = c:BuildSettings(ctx, { options = O, tab = "look" })
  widgetLabeled(scroll, "Outline"):__fire("OnValueChanged", "MONOCHROME")
  assertEqual(db.outline, "MONOCHROME")
  widgetLabeled(scroll, "Shadow"):__fire("OnValueChanged", false)
  assertFalse(db.shadow)
  local before = view.preview.text
  c:SetColor("go", 0, 0, 1)
  O.RefreshScalars()
  assertFalse(view.preview.text == before, "a refresh repaints the sample in the new color")
  assertTrue(view.preview.text:find("0000ff", 1, true) ~= nil)
end)

test("callout settings: Test countdown counts the real call-out from 5; Play shows the picked text", function()
  local c, m = newCallout()
  local O, ctx, scroll = page()
  c:BuildSettings(ctx, { options = O, tab = "sound" })
  m.__now = 100
  widgetTexted(scroll, "Button", "Test countdown"):__fire("OnClick")
  local running, n = c:Running()
  assertTrue(running)
  assertEqual(n, 5)
  assertEqual(shown(c), "5")
  c:Cancel()
  local spoken = #m.__files
  widgetLabeled(scroll, "Text to play"):__fire("OnValueChanged", "MOVE")
  widgetTexted(scroll, "Button", "Play"):__fire("OnClick")
  assertEqual(shown(c), "MOVE")
  assertEqual(#m.__files, spoken + 1, "Play speaks")
  widgetTexted(scroll, "Button", "Reset position"):__fire("OnClick")
end)

test("callout settings: the unlock toggle is the instance's lock, never saved", function()
  local c, _, db = newCallout()
  local O, ctx, scroll = page()
  c:BuildSettings(ctx, { options = O, tab = "look" })
  widgetLabeled(scroll, "Unlock to move"):__fire("OnValueChanged", true)
  assertFalse(c:Locked())
  assertEqual(shown(c), "READY", "unlocked, the call-out shows its sample")
  widgetLabeled(scroll, "Unlock to move"):__fire("OnValueChanged", false)
  assertTrue(c:Locked())
  for k in pairs(db) do assertFalse(k == "locked" or k == "unlocked", "the lock is not in the db") end
end)

test("callout settings: with no tab the three sections draw one under another, each under its heading", function()
  local c, _, db = newCallout()
  local O, ctx, scroll = page()
  c:BuildSettings(ctx, { options = O })
  local headings = {}
  for _, w in ipairs(widgets(scroll)) do
    if w.type == "Heading" then headings[#headings + 1] = w.text end
  end
  assertEqual(table.concat(headings, ","), "Look,Sound,Texts,Colors,Stock texts",
    "a heading per tab, then the Texts tab's two subgroups")
  widgetLabeled(scroll, "Voice"):__fire("OnValueChanged", "off")
  assertEqual(db.voice, "off")
  widgetLabeled(scroll, "Mute STOP"):__fire("OnValueChanged", true)
  assertTrue(db.muted.STOP)
  widgetLabeled(scroll, "READY"):__fire("OnEnterPressed", "Set")
  assertEqual(db.texts.READY, "Set")
  widgetLabeled(scroll, "Numbers"):__fire("OnValueConfirmed", 0.5, 0.5, 0.5, 1)
  assertEqual(table.concat(db.colors.number, ","), "0.5,0.5,0.5")
end)

test("callout settings: SettingsTabs answers three host tabs that draw their tab", function()
  local c = newCallout()
  local O, ctx, scroll = page()
  local tabs = c:SettingsTabs({ options = O, before = "window" })
  assertEqual(#tabs, 3)
  assertEqual(tabs[1].key .. "," .. tabs[2].key .. "," .. tabs[3].key, "callout.look,callout.sound,callout.texts")
  assertEqual(tabs[2].label, "Sound")
  assertEqual(tabs[3].before, "window")
  assertTrue(type(tabs[1].tooltip) == "string" and tabs[1].tooltip ~= "")
  tabs[2].render(ctx)
  assertEqual(widgetLabeled(scroll, "Voice").type, "Dropdown")
  assertEqual(c:SettingsTabs({ keyPrefix = "co_" })[1].key, "co_look")
end)

test("callout settings: words come from opts.L, read with rawget, else US English", function()
  local c = newCallout()
  local L = setmetatable({ TAB_LOOK = "Aspect", PLAY = "Jouer" }, { __index = function(_, k) return k end })
  local rows = c:SettingsRows({ L = L })
  assertEqual(rows[1].group, "Aspect")
  assertEqual(rowsByKey(rows).voice.group, "Sound", "a key the table lacks is the library's word, not the key")
  local O, ctx, scroll = page()
  c:BuildSettings(ctx, { options = O, tab = "look", L = L })
  assertTrue(widgetTexted(scroll, "Button", "Jouer") ~= nil)
end)

test("callout settings: nothing to build into, or an unknown tab, answers nil", function()
  local c = newCallout()
  local O = page()
  assertNil(c:BuildSettings(nil, { options = O }))
  assertNil(c:BuildSettings({}, {}), "a plain build needs a frame")
  assertNil(c:BuildSettings({}, { options = O, tab = "colors" }))
end)

-- ── the plain build ──────────────────────────────────────────────────────────────────────────

test("callout settings: without Options, plain frames: a control per row and the preview", function()
  local c, m, db = newCallout()
  local parent = m.CreateFrame("Frame", nil, m.UIParent)
  local view = c:BuildSettings(parent, {})
  assertEqual(view.kind, "plain")
  assertEqual(#view.controls, #view.rows + 2, "every row, the text to play and the unlock toggle")
  assertTrue(view.height > 0)
  assertTrue(view.preview:GetText():find("GO!", 1, true) ~= nil, "the preview shows the sample")
  local by = {}
  for _, ctl in ipairs(view.controls) do by[ctl.row.key] = ctl end
  rawset(by.outline.control, "SetText", function(self, t) rawset(self, "__label", t) end)
  by.outline.control:__fire("OnClick")
  assertEqual(db.outline, "MONOCHROME", "a list steps to its next choice")
  assertEqual(rawget(by.outline.control, "__label"), "Monochrome", "and shows it")
  by.size.control.plus:__fire("OnClick")
  assertEqual(db.size, 97, "+ steps a number up")
  by.size.control.minus:__fire("OnClick")
  by.size.control.minus:__fire("OnClick")
  assertEqual(db.size, 95)
  rawset(by.shadow.control, "GetChecked", function() return false end)
  by.shadow.control:__fire("OnClick")
  assertFalse(db.shadow, "a check button writes its state")
  m.__now = 50
  view.testButton:__fire("OnClick")
  assertTrue((c:Running()))
  c:Cancel()
  view.playButton:__fire("OnClick")
  assertEqual(shown(c), "GO!", "Play shows the picked text, GO! until another is picked")
end)
