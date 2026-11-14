-- tests/test_callout_settings.lua — LibKa0s-Callout-1.0's CalloutSettings.lua (minor 4): the settings
-- section a consumer drops into its own panel (plan row L4), its font row led by the call-out's
-- display faces from minor 2 (plan row L2).
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

test("callout settings: CalloutSettings is at minor 4, paired on the Callout shell's minor", function()
  local c, _, _, _, Callout = newCallout()
  assertEqual(Callout.MODULES.CalloutSettings, 4)
  assertEqual(Callout.__settingsMinor, 4)
  assertEqual(Callout.__settingsShellMinor, Callout.MINOR)
  for _, name in ipairs({ "BuildSettings", "SettingsRows", "SchemaRows", "SettingsTabs", "SettingsTab", "Preview", "TestCountdown", "Look" }) do
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

test("callout settings: an Options instance missing a member it calls builds nothing, and raises nothing", function()
  for _, member in ipairs({ "EnsureScroll", "TextRow", "InlineButtonPair", "RenderRows" }) do
    local c = newCallout()
    local O, ctx = page()
    local lacking = setmetatable({ [member] = false }, { __index = O })
    assertNil(c:BuildSettings(ctx, { options = lacking }), "no " .. member)
  end
  local c = newCallout()
  local O, ctx = page()
  local noScroll = setmetatable({ EnsureScroll = function() return nil end }, { __index = O })
  assertNil(c:BuildSettings(ctx, { options = noScroll }), "an EnsureScroll that answers no scroll")
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

-- ── the rows, in depth (plan row L6) ─────────────────────────────────────────────────────────

test("callout settings: each slider carries the setting's own bounds and step", function()
  local c, _, _, _, Callout = newCallout(nil, function(m) tts(m, { { voiceID = 3, name = "Zira" } }) end)
  local by = rowsByKey(c:SettingsRows())
  local want = {
    size = { Callout.SIZE_MIN, Callout.SIZE_MAX, 1 }, shadowX = { -20, 20, 1 }, shadowY = { -20, 20, 1 },
    hold = { 0.2, 10, 0.1 }, speakFrom = { 1, Callout.MAX_FROM, 1 }, ttsRate = { -10, 10, 1 },
    ttsVolume = { 0, 100, 1 },
  }
  for key, w in pairs(want) do
    local r = by[key]
    assertEqual(r.type, "number", key .. " is a slider")
    assertEqual(r.min .. "," .. r.max .. "," .. r.step, w[1] .. "," .. w[2] .. "," .. w[3], key .. "'s bounds")
    assertNil(r.values, key .. " is no list")
  end
end)

test("callout settings: each list offers exactly the major's choices, in its order", function()
  local c, _, _, _, Callout = newCallout()
  local by = rowsByKey(c:SettingsRows())
  local function keys(r)
    local out = {}
    for i, v in ipairs(r.values) do out[i] = v.value end
    return table.concat(out, ",")
  end
  assertEqual(keys(by.outline), table.concat(Callout.OUTLINES, ","))
  assertEqual(keys(by.glow), table.concat(Callout.GLOWS, ","))
  assertEqual(keys(by.anim), table.concat(Callout.ANIMS, ","))
  assertEqual(keys(by.channel), table.concat(Callout.CHANNELS, ","))
  assertEqual(keys(by.voice), "female,male,tts,off")
  for _, key in ipairs({ "outline", "glow", "anim", "channel", "voice" }) do
    for _, v in ipairs(by[key].values) do
      assertTrue(type(v.text) == "string" and v.text ~= "", key .. " " .. tostring(v.value) .. " has a word")
    end
  end
end)

test("callout settings: the shadow offsets are drawn disabled with no shadow", function()
  local c, _, db = newCallout()
  local by = rowsByKey(c:SettingsRows({ tab = "look" }))
  assertFalse(by.shadowX.disabledIf())
  assertFalse(by.shadowY.disabledIf())
  db.shadow = false
  assertTrue(by.shadowX.disabledIf())
  assertTrue(by.shadowY.disabledIf())
  assertNil(by.size.disabledIf, "the other rows are never disabled")
end)

test("callout settings: a row's write the call-out refuses leaves the db as it was", function()
  local c, _, db = newCallout()
  local by = rowsByKey(c:SettingsRows())
  by.size.set(500)
  by.outline.set("THIN")
  by.voice.set("robot")
  by.speakFrom.set(2.5)
  assertNil(next(db), "nothing was written")
  assertEqual(by.size.get(), 96, "the row still reads the default")
  by["colors.go"].set({})
  assertNil(db.colors, "a color with no channels is no write")
end)

test("callout settings: the font list leads with the skin's and the game's faces, then every LSM face", function()
  local c = newCallout(nil, function(m)
    local LSM = m.LibStub:NewLibrary("LibSharedMedia-3.0", 1)
    LSM.List = function() return { "Big Face", "Alpha Face" } end
    LSM.Fetch = function() return nil end
  end)
  local values = {}
  for i, v in ipairs(rowsByKey(c:SettingsRows({ tab = "look" })).font.values()) do values[i] = v.value end
  local list = table.concat(values, ",")
  assertEqual(values[1] .. "," .. values[2], "Skin font,Game default")
  assertTrue(list:find("Big Face", 1, true) ~= nil)
  assertTrue(list:find("Alpha Face", 1, true) ~= nil)
end)

test("callout settings: the call-out's display faces lead the font row, each when it can be drawn", function()
  -- Plan row L2 (minor 2). red under: the faces sorted in among the rest, a face offered that neither
  -- LibSharedMedia lists nor the Media copy ships (an older copy, before Media minor 13), a face
  -- listed twice, or Oxanium, the default, missing with neither present.
  local function values(before)
    local c = newCallout(nil, before)
    local out = {}
    for i, v in ipairs(rowsByKey(c:SettingsRows({ tab = "look" })).font.values()) do out[i] = v.value end
    return out
  end
  local listed = values(function(m)
    local LSM = m.LibStub:NewLibrary("LibSharedMedia-3.0", 1)
    LSM.List = function()
      return { "Alpha Face", "Ka0s Russo One", "Ka0s Oxanium Bold", "Ka0s Bebas Neue", "Zulu Face" }
    end
    LSM.Fetch = function() return nil end
  end)
  assertEqual(table.concat(listed, ","),
    "Skin font,Game default,Ka0s Oxanium Bold,Ka0s Bebas Neue,Ka0s Russo One,Alpha Face,Zulu Face",
    "the skin's, the game's, then the three faces in their order, then the rest sorted, each once")

  local old = values(function(m)
    local Media = m.LibStub:NewLibrary("LibKa0s-Media-1.0", 12)
    Media.FONTS = { ["Ka0s Oxanium Bold"] = {}, ["Ka0s Prototype"] = {} }
  end)
  assertEqual(table.concat(old, ","), "Skin font,Game default,Ka0s Oxanium Bold,Ka0s Prototype",
    "a Media copy without the two faces offers neither")

  local shipped = values(function(m)
    local Media = m.LibStub:NewLibrary("LibKa0s-Media-1.0", 13)
    Media.FONTS = { ["Ka0s Russo One"] = {}, ["Ka0s Bebas Neue"] = {}, ["Ka0s Prototype"] = {} }
  end)
  assertEqual(table.concat(shipped, ","),
    "Skin font,Game default,Ka0s Oxanium Bold,Ka0s Bebas Neue,Ka0s Russo One,Ka0s Prototype",
    "with no LibSharedMedia the Media copy's faces stand in, the default offered regardless")

  local bare = values()
  assertEqual(table.concat(bare, ","), "Skin font,Game default,Ka0s Oxanium Bold", "nothing installed: the default alone")

  -- red under: a face offered because the Media copy ships it while LibSharedMedia, present, does
  -- not list it. LSM holds no face Media's RegisterLSM refused for the client's locale (its
  -- langmask, Media.lua), and namedFont would then draw that face's raw file, boxes and all.
  local refused = values(function(m)
    local LSM = m.LibStub:NewLibrary("LibSharedMedia-3.0", 1)
    LSM.List = function() return { "Ka0s Oxanium Bold", "Alpha Face" } end
    LSM.Fetch = function() return nil end
    local Media = m.LibStub:NewLibrary("LibKa0s-Media-1.0", 13)
    Media.FONTS = { ["Ka0s Oxanium Bold"] = {}, ["Ka0s Russo One"] = {}, ["Ka0s Bebas Neue"] = {} }
  end)
  assertEqual(table.concat(refused, ","), "Skin font,Game default,Ka0s Oxanium Bold,Alpha Face",
    "a face LibSharedMedia does not list is not offered, though the Media copy ships it")
end)

test("callout settings: FONT_FACES names the default first and the two Media minor 13 faces", function()
  local _, _, _, _, Callout = newCallout()
  assertEqual(table.concat(Callout.FONT_FACES, ","), "Ka0s Oxanium Bold,Ka0s Bebas Neue,Ka0s Russo One")
  assertEqual(Callout.FONT_FACES[1], Callout.FONT_DEFAULT)
end)

-- ── the preview, in depth ────────────────────────────────────────────────────────────────────

test("callout settings: Preview shows the look on the real call-out without a sound", function()
  local c, m = newCallout()
  assertTrue(c:Preview())
  assertEqual(shown(c), "READY", "READY by default")
  assertTrue(c:Preview("STOP"))
  assertEqual(shown(c), "STOP")
  assertTrue(c:Preview({ text = "Mine", sound = "Interface\\x.ogg" }))
  assertEqual(#m.__files, 0, "silent, a custom sound included")
end)

test("callout settings: TestCountdown counts from its argument, 5 by default", function()
  local c, m = newCallout()
  m.__now = 10
  assertTrue(c:TestCountdown(3))
  assertEqual(shown(c), "3")
  local _, n = c:Running()
  assertEqual(n, 3)
  assertEqual(c:Stats().endsAt, 13, "endsAt is now + from")
  assertTrue(c:TestCountdown())
  assertEqual(shown(c), "5")
end)

test("callout settings: the plain preview is drawn in the chosen look, capped at 64", function()
  local c, m = newCallout()
  local parent = m.CreateFrame("Frame", nil, m.UIParent)
  local view = c:BuildSettings(parent, {})
  local _, size, flags = view.preview:GetFont()
  assertEqual(size, 64, "the default 96 is capped")
  assertEqual(flags, "THICKOUTLINE")
  local x, y = view.preview:GetShadowOffset()
  assertEqual(x .. "," .. y, "2,-2")
  c:Set("size", 40)
  c:Set("outline", "NONE")
  c:Set("shadow", false)
  view.refresh()
  _, size, flags = view.preview:GetFont()
  assertEqual(size, 40, "below the cap, the size itself")
  assertEqual(flags, "")
  x, y = view.preview:GetShadowOffset()
  assertEqual(x .. "," .. y, "0,0")
end)

test("callout settings: the preview's words carry each kind's color, so a color write shows", function()
  local c, m = newCallout()
  local parent = m.CreateFrame("Frame", nil, m.UIParent)
  local view = c:BuildSettings(parent, {})
  local text = view.preview:GetText()
  assertTrue(text:find("|cffffffff5|r", 1, true) ~= nil, "5 in the number color")
  c:SetColor("stop", 1, 0, 0)
  view.refresh()
  assertTrue(view.preview:GetText():find("|cffff0000STOP|r", 1, true) ~= nil, "STOP in the new stop color")
end)

-- ── the plain build, in depth ────────────────────────────────────────────────────────────────

local function plainView(before)
  local c, m, db = newCallout(nil, before)
  local parent = m.CreateFrame("Frame", nil, m.UIParent)
  local view = c:BuildSettings(parent, {})
  local by = {}
  for _, ctl in ipairs(view.controls) do by[ctl.row.key] = ctl end
  return c, m, db, view, by
end

test("callout settings: a plain number stops at its bounds and steps by its own step", function()
  local _, _, db, _, by = plainView()
  db.size = 200
  by.size.control.plus:__fire("OnClick")
  assertEqual(db.size, 200, "+ at the top stays at the top")
  db.speakFrom = 1
  by.speakFrom.control.minus:__fire("OnClick")
  assertEqual(db.speakFrom, 1, "- at the bottom stays at the bottom")
  by.hold.control.plus:__fire("OnClick")
  assertEqual(("%.1f"):format(db.hold), "1.6", "hold steps by 0.1")
  assertEqual(by.hold.control.text:GetText(), "1.6", "and shows one decimal")
end)

test("callout settings: a plain list wraps from its last choice to its first", function()
  local _, _, db, _, by = plainView()
  db.channel = "Dialog"
  by.channel.control:__fire("OnClick")
  assertEqual(db.channel, "Master")
end)

test("callout settings: a plain swatch opens the client's color picker; cancel puts the color back", function()
  local picked
  local _, m, db, _, by = plainView(function(mm)
    mm.ColorPickerFrame = {
      SetupColorPickerAndShow = function(_, info) picked = info end,
      GetColorRGB = function() return 0.2, 0.4, 0.6 end,
    }
  end)
  assertTrue(m.ColorPickerFrame ~= nil)
  by["colors.warn"].control:__fire("OnClick")
  assertEqual(("%.2f %.2f %.2f"):format(picked.r, picked.g, picked.b), "1.00 0.78 0.20", "opened on the current color")
  assertFalse(picked.hasOpacity)
  picked.swatchFunc()
  assertEqual(table.concat(db.colors.warn, ","), "0.2,0.4,0.6")
  picked.cancelFunc()
  assertEqual(table.concat(db.colors.warn, ","), "1,0.78,0.2", "cancel writes the color it opened on")
end)

test("callout settings: a plain swatch with no color picker does nothing", function()
  local _, _, db, _, by = plainView()
  by["colors.go"].control:__fire("OnClick")
  assertNil(db.colors)
end)

test("callout settings: a plain refresh syncs every control to an outside write", function()
  local c, _, _, view, by = plainView()
  c:Set("size", 150)
  view.refresh()
  assertEqual(by.size.control.text:GetText(), "150")
end)

test("callout settings: one plain tab builds that tab's rows alone, with no heading of its own", function()
  local c, m = newCallout()
  local parent = m.CreateFrame("Frame", nil, m.UIParent)
  local view = c:BuildSettings(parent, { tab = "sound" })
  for _, r in ipairs(view.rows) do assertEqual(r.tab, "sound") end
  for _, r in ipairs({ parent:GetRegions() }) do
    assertFalse(r.GetText and r:GetText() == "Sound", "the host's tab names it, as in the Options build")
  end
  assertTrue(#view.rows >= 3, "voice, channel and speak from")
  assertTrue(view.testButton ~= nil and view.playButton ~= nil and view.resetButton ~= nil)
  view.resetButton:__fire("OnClick")
end)
