-- tests/test_skin_marks.lua -- cause L6 of Ka0sAddonsCommonTasks docs/2026-11-01-FULL_SKINNING: small
-- marks are the Ka0s icons, tinted. S.Mark and S.MarkText; the Options marks while the chrome is
-- skinned (Scope cleared), client art while the owner ignores its panel; the owned Widgets rungs.
-- The picker's reset and arrow are in tests/test_options_skin_picker.lua, the media rows' speaker in
-- tests/test_options_media.lua, the gate in tests/test_options_appearance.lua.

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = K.test, K.assertEqual, K.assertTrue, K.assertNil

local F = dofile("tests/fixture_skin_paint.lua")

local OWNER = "LootHistory"
local OPTIONS = { "Options", "OptionsRegistry", "OptionsWidgets", "OptionsFlow", "OptionsIds", "OptionsIdSuggest",
                  "OptionsIdList", "OptionsTabs", "OptionsTabbed", "OptionsCombat", "OptionsScroll", "OptionsNav",
                  "OptionsDrawer", "OptionsCompose" }
local WIDGETS = { "Widgets", "WidgetsDropdown", "WidgetsReorder", "WidgetsDragHandle", "WidgetsLineChart", "WidgetsAutocomplete",
                  "WidgetsCopyWindow" }

local function env(extra)
  local files = {}
  for _, f in ipairs(F.FILES) do files[#files + 1] = f end
  files[#files + 1] = "Pool"
  files[#files + 1] = "Media"
  for _, f in ipairs(extra or {}) do files[#files + 1] = f end
  local m, Skin = F.env({ files = files })
  m.__cursorX, m.__cursorY = 100, 100
  return m, Skin
end

local function rgb(c) return ("%.2f,%.2f,%.2f"):format(c[1], c[2], c[3]) end

local function tintOf(m, tex)
  local c = m.__paint(tex).vertex
  return rgb(c)
end

-- ── S.Mark and S.MarkText ────────────────────────────────────────────────────────────────────

test("skin marks: S.Mark draws the art in icon.tint, and a skin switch repaints it", function()
  local m, Skin = env()
  local S = F.owner(Skin, OWNER, "azeroth")
  local f = m.CreateFrame("Frame", nil, m.UIParent)
  local tex = f:CreateTexture()
  S.Mark(tex, { art = "Ka0s\\tick" })
  assertEqual(m.__paint(tex).texture, "Ka0s\\tick")
  assertEqual(tintOf(m, tex), rgb(Skin:ResolveSkin("azeroth")["icon.tint"]))
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(tintOf(m, tex), rgb(Skin:ResolveSkin("obsidian")["icon.tint"]), "the switch reaches it")
end)

test("skin marks: S.Mark takes a meaning token", function()
  local m, Skin = env()
  local S = F.owner(Skin, OWNER, "azeroth")
  local tex = m.CreateFrame("Frame", nil, m.UIParent):CreateTexture()
  S.Mark(tex, { token = "sem.good" })
  assertEqual(tintOf(m, tex), rgb(Skin:ResolveSkin("azeroth")["sem.good"]))
end)

test("skin marks: a panel-scoped S.Mark keeps the client art on an ignored panel, live both ways", function()
  local m, Skin = env()
  local S = F.owner(Skin, OWNER, "azeroth")
  local tex = m.CreateFrame("Frame", nil, m.UIParent):CreateTexture()
  tex:SetTexture("Client\\Tick")
  local spec = { art = "Ka0s\\tick", panel = true, stock = function(t) t:SetTexture("Client\\Tick") end }
  S.Mark(tex, spec)
  assertEqual(m.__paint(tex).texture, "Ka0s\\tick", "Scope cleared: the Ka0s icon")
  Skin:SetIgnore(OWNER, true)
  assertEqual(m.__paint(tex).texture, "Client\\Tick", "ignored: the client art")
  Skin:SetIgnore(OWNER, false)
  assertEqual(m.__paint(tex).texture, "Ka0s\\tick", "and back")
end)

test("skin marks: S.Mark ignores a target that is not a texture", function()
  local _, Skin = env()
  local S = F.owner(Skin, OWNER, "azeroth")
  S.Mark(nil)
  S.Mark({})
end)

test("skin marks: S.MarkText writes the mark at its size in the token's bytes", function()
  local _, Skin = env()
  local S = F.owner(Skin, OWNER, "azeroth")
  local c = Skin:ResolveSkin("azeroth")["sem.bad"]
  local line = S.MarkText("Ka0s\\x", 12, "sem.bad")
  local r = math.floor(c[1] * 255 + 0.5)
  assertTrue(line:find("|TKa0s\\x:12:12:0:0:64:64:0:64:0:64:" .. r .. ":", 1, true) == 1, line)
  assertTrue(S.MarkText("Ka0s\\x"):find("|TKa0s\\x:14:14:", 1, true) == 1, "default size")
  assertEqual(S.MarkText("Ka0s\\x", 12, "no.such.token"), "|TKa0s\\x:12:12|t", "no token, no tint")
end)

-- ── Options ──────────────────────────────────────────────────────────────────────────────────

local seq = 0

local function page(lib)
  seq = seq + 1
  local O = lib:New({
    parentTitle = "Marks Host", mainPanelName = "MarksHost" .. seq, addonName = OWNER,
    print = function() end, get = function() end, set = function() end,
    applyDefault = function() end, rowsForPage = function() return {} end,
    allRows = function() return {} end,
  })
  return O, O.CreatePanel("Marks" .. seq, "Marks", {})
end

local function removeMark(ctx)
  local x
  local function walk(w)
    if type(w) ~= "table" then return end
    if w.__removeAtlas or w.__removeIcon then x = w end
    for _, c in ipairs(w.children or {}) do walk(c) end
  end
  walk(ctx.scroll)
  return x
end

local function idList(O, ctx)
  local entries = { { id = 17 } }
  O.EnsureScroll(ctx).content.width = 1000
  O.IdList(ctx, { kind = "spell", removeStyle = "icon", onRemove = function() end,
                  entries = function() return entries end })
end

test("skin marks: with the Scope cleared the id list's X is the Ka0s close icon", function()
  local m, Skin = env(OPTIONS)
  F.owner(Skin, OWNER, "azeroth")
  local O, ctx = page(m.LibStub("LibKa0s-Options-1.0"))
  idList(O, ctx)
  local x = removeMark(ctx)
  assertEqual(x.__removeIcon, m.LibStub("LibKa0s-Media-1.0").Icon(OWNER, "close"))
  assertNil(x.__removeAtlas, "no client atlas")
end)

test("skin marks: the id list's Ka0s X wears icon.tint", function()
  local m, Skin = env(OPTIONS)
  F.owner(Skin, OWNER, "azeroth")
  local gui = m.__libs["AceGUI-3.0"]
  gui:RegisterWidgetType("Icon", function()
    local w = m.__makeAceGUIWidget("Icon")
    local holder = m.CreateFrame("Frame", nil, m.UIParent)
    local img, hl = holder:CreateTexture(), holder:CreateTexture()
    w.image = img
    w.frame.GetRegions = function() return img, hl end
    return w
  end, 21)
  local O, ctx = page(m.LibStub("LibKa0s-Options-1.0"))
  idList(O, ctx)
  local x = removeMark(ctx)
  assertEqual(m.__paint(x.image).texture, m.LibStub("LibKa0s-Media-1.0").Icon(OWNER, "close"))
  assertEqual(tintOf(m, x.image), rgb(Skin:ResolveSkin("azeroth")["icon.tint"]))
end)

test("skin marks: on an ignored panel the id list's X stays the client atlas", function()
  local m, Skin = env(OPTIONS)
  F.owner(Skin, OWNER, "azeroth")
  Skin:SetIgnore(OWNER, true)
  local O, ctx = page(m.LibStub("LibKa0s-Options-1.0"))
  idList(O, ctx)
  local x = removeMark(ctx)
  assertEqual(x.__removeAtlas, "transmog-icon-remove")
  assertNil(x.__removeIcon)
end)

test("skin marks: lib.__chromeMark answers nil without a registered owner or a known name", function()
  local m, Skin = env(OPTIONS)
  local lib = m.LibStub("LibKa0s-Options-1.0")
  assertNil(lib.__chromeMark(OWNER, "close"), "not registered")
  F.owner(Skin, OWNER, "azeroth")
  assertNil(lib.__chromeMark(OWNER, "no-such-icon"), "not a Media name")
  assertTrue(lib.__chromeMark(OWNER, "close") ~= nil)
end)

-- ── Widgets ──────────────────────────────────────────────────────────────────────────────────

test("skin marks: an owned dropdown with no art draws the Ka0s chevron and a tinted check", function()
  local m, Skin = env(WIDGETS)
  F.owner(Skin, OWNER, "azeroth")
  local W = m.LibStub("LibKa0s-Widgets-1.0")
  local Media = m.LibStub("LibKa0s-Media-1.0")
  local dd = W.Dropdown(m.UIParent, 100, { owner = OWNER })
  assertEqual(m.__paint(dd.arrow).texture, Media.Icon(OWNER, "chevron-down"))
  assertTrue(dd.__check:find(Media.Icon(OWNER, "confirm"), 1, true) ~= nil, dd.__check)
  assertTrue(dd.__check:find(":0:0:0:0:64:64:", 1, true) ~= nil, "at the line's height, tinted")
end)

test("skin marks: a host's art wins, and an ignored panel's dropdown keeps its client rung", function()
  local m, Skin = env(WIDGETS)
  F.owner(Skin, OWNER, "azeroth")
  local W = m.LibStub("LibKa0s-Widgets-1.0")
  local host = W.Dropdown(m.UIParent, 100, { owner = OWNER, chevron = "Host\\Arrow", check = "Host\\Tick" })
  assertEqual(m.__paint(host.arrow).texture, "Host\\Arrow")
  assertEqual(host.__check, "|THost\\Tick:0|t ")
  Skin:SetIgnore(OWNER, true)
  local dd = W.Dropdown(m.UIParent, 100, { owner = OWNER, panel = true })
  assertEqual(m.__paint(dd.arrow).texture, "Interface\\Buttons\\Arrow-Down-Up")
  assertEqual(dd.__check, "|TInterface\\Buttons\\UI-CheckBox-Check:0|t ")
end)

test("skin marks: an owned dropdown's marks follow a skin switch and the Scope, live", function()
  local m, Skin = env(WIDGETS)
  local S = F.owner(Skin, OWNER, "azeroth")
  local W = m.LibStub("LibKa0s-Widgets-1.0")
  local Media = m.LibStub("LibKa0s-Media-1.0")
  local tick, chevron = Media.Icon(OWNER, "confirm"), Media.Icon(OWNER, "chevron-down")
  local dd = W.Dropdown(m.UIParent, 100, { owner = OWNER, panel = true })
  local before = dd.__check

  Skin:SetChoice(OWNER, "ka0s", "contrast")
  assertTrue(dd.__check ~= before, "the tick's color moved with the skin")
  assertEqual(dd.__check, S.MarkText(tick, 0, "icon.hot") .. " ", "the tick is the live skin's")
  assertEqual(m.__paint(dd.arrow).texture, chevron)

  Skin:SetIgnore(OWNER, true)
  assertEqual(m.__paint(dd.arrow).texture, "Interface\\Buttons\\Arrow-Down-Up", "an ignored panel is stock")
  assertEqual(dd.__check, "|TInterface\\Buttons\\UI-CheckBox-Check:0|t ", "with no rebuild")

  Skin:SetIgnore(OWNER, false)
  assertEqual(m.__paint(dd.arrow).texture, chevron, "and clearing the Scope brings the marks back")
  assertEqual(dd.__check, S.MarkText(tick, 0, "icon.hot") .. " ")
end)

test("skin marks: a skin switch leaves a host's own dropdown art alone", function()
  local m, Skin = env(WIDGETS)
  F.owner(Skin, OWNER, "azeroth")
  local W = m.LibStub("LibKa0s-Widgets-1.0")
  local dd = W.Dropdown(m.UIParent, 100, { owner = OWNER, panel = true, chevron = "Host\\Arrow", check = "Host\\Tick" })
  Skin:SetChoice(OWNER, "ka0s", "contrast")
  Skin:SetIgnore(OWNER, true)
  assertEqual(m.__paint(dd.arrow).texture, "Host\\Arrow")
  assertEqual(dd.__check, "|THost\\Tick:0|t ")
end)

test("skin marks: an unowned dropdown is what it was", function()
  local m = env(WIDGETS)
  local dd = m.LibStub("LibKa0s-Widgets-1.0").Dropdown(m.UIParent, 100, {})
  assertEqual(m.__paint(dd.arrow).texture, "Interface\\Buttons\\Arrow-Down-Up")
end)

test("skin marks: an owned strip's icon wears icon.tint, a skin switch repaints it", function()
  local m, Skin = env(WIDGETS)
  F.owner(Skin, OWNER, "azeroth")
  local s = m.LibStub("LibKa0s-Widgets-1.0").TestStrip(m.UIParent, { owner = OWNER, icon = "Host\\Info" })
  assertEqual(tintOf(m, s.__icon), rgb(Skin:ResolveSkin("azeroth")["icon.tint"]))
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(tintOf(m, s.__icon), rgb(Skin:ResolveSkin("obsidian")["icon.tint"]))
end)

test("skin marks: an owned drag handle with no art draws the Ka0s info and close icons", function()
  local m, Skin = env(WIDGETS)
  F.owner(Skin, OWNER, "azeroth")
  local Media = m.LibStub("LibKa0s-Media-1.0")
  local h = m.LibStub("LibKa0s-Widgets-1.0").DragHandle(m.CreateFrame("Frame", nil, m.UIParent), {
    owner = OWNER, label = "L", onClose = function() end, tooltip = "t", showClose = true })
  assertEqual(m.__paint(h.help.icon).texture, Media.Icon(OWNER, "info"))
  if h.close then assertEqual(m.__paint(h.close.icon).texture, Media.Icon(OWNER, "close")) end
end)

test("skin marks: a panel drag handle's marks follow the Scope live, and a host's art stays", function()
  local m, Skin = env(WIDGETS)
  F.owner(Skin, OWNER, "azeroth")
  local Media = m.LibStub("LibKa0s-Media-1.0")
  local W = m.LibStub("LibKa0s-Widgets-1.0")
  local h = W.DragHandle(m.CreateFrame("Frame", nil, m.UIParent), { owner = OWNER, label = "L", panel = true })
  assertEqual(m.__paint(h.help.icon).texture, Media.Icon(OWNER, "info"))
  Skin:SetIgnore(OWNER, true)
  assertEqual(m.__paint(h.help.icon).texture, "Interface\\FriendsFrame\\InformationIcon")
  Skin:SetIgnore(OWNER, false)
  assertEqual(m.__paint(h.help.icon).texture, Media.Icon(OWNER, "info"))
  local host = W.DragHandle(m.CreateFrame("Frame", nil, m.UIParent),
    { owner = OWNER, label = "L", panel = true, helpIcon = "Host\\Help" })
  assertEqual(m.__paint(host.help.icon).texture, "Host\\Help")
end)

test("skin marks: lib.__ownedMark answers for an owner, and not for a panel control it ignores", function()
  local m, Skin = env(WIDGETS)
  F.owner(Skin, OWNER, "azeroth")
  local W = m.LibStub("LibKa0s-Widgets-1.0")
  local Media = m.LibStub("LibKa0s-Media-1.0")
  assertEqual(W.__ownedMark(OWNER, "move"), Media.Icon(OWNER, "move"))
  assertNil(W.__ownedMark("NotAnOwner", "move"), "no owner, no mark")
  Skin:SetIgnore(OWNER, true)
  assertNil(W.__ownedMark(OWNER, "move", true), "ignored and panel-scoped")
  assertEqual(W.__ownedMark(OWNER, "move"), Media.Icon(OWNER, "move"), "a window's is not reached")
end)
