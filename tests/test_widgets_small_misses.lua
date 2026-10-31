-- tests/test_widgets_small_misses.lua -- cause L8 of Ka0sAddonsCommonTasks docs/2026-11-01-FULL_SKINNING,
-- the library's rows: the strings and fills a skin never reached. A stock close button's "x" (row 16),
-- a host's backdrop on the copy window (697), the carried copy of a reorder list (704), the menu's
-- glyph column (705), the autocomplete's list (707) and the glow's color (718). Row 711, a host's
-- face on an owned control, is in tests/test_widgets_skin_scope.lua.

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = K.test, K.assertEqual, K.assertTrue, K.assertNil

local F = dofile("tests/fixture_skin_paint.lua")

local OWNER = "LootHistory"
local WFILES = { "Widgets", "WidgetsReorder", "WidgetsDragHandle", "WidgetsLineChart", "WidgetsAutocomplete",
                 "WidgetsCopyWindow", "Glow" }

local LSM = setmetatable({}, { __index = function(_, k)
  local key = type(k) == "string" and k:match("^font:(.+)$")
  return key and ("Fonts\\" .. key) or nil
end })

--- A FontString built from a template answers it as its font object, as the client's does, so a
--- face given back is observable.
local function templates(m)
  local objects = {}
  local create = m.CreateFrame
  m.CreateFrame = function(...)
    local f = create(...)
    local cfs = rawget(f, "CreateFontString")
    if type(cfs) == "function" then
      rawset(f, "CreateFontString", function(self, name, layer, template)
        local fs = cfs(self, name, layer, template)
        if type(template) == "string" then
          objects[template] = objects[template] or { name = template, GetName = function(o) return o.name end,
            GetFont = function() return "Fonts\\FRIZQT__.TTF", 10, "" end }
          fs:SetFontObject(objects[template])
        end
        return fs
      end)
    end
    return f
  end
end

local function env()
  local files = {}
  for _, f in ipairs(F.FILES) do files[#files + 1] = f end
  for _, f in ipairs(WFILES) do files[#files + 1] = f end
  local m, Skin = F.env({ files = files, lsm = LSM })
  m.__cursorX, m.__cursorY = 100, 100
  templates(m)
  return m, Skin, m.LibStub("LibKa0s-Widgets-1.0")
end

local function survey(m, obj) return m.__paint(obj) end
local function face(fs)
  local obj = fs:GetFontObject()
  return type(obj) == "table" and obj.font and obj.font[1] or nil
end
local function body(Skin, skin) return "Fonts\\" .. Skin:ResolveSkin(skin)["font.body"] end

-- ── the tokens ───────────────────────────────────────────────────────────────────────────────

test("small misses: Ka0s Default's new tokens draw what it drew, every other skin's its own role", function()
  local _, Skin = env()
  local T = Skin:ResolveSkin("ka0s")
  assertEqual(F.rgba(T["menu.suggestBg"]), "0.100,0.100,0.120,0.950", "the box's fill at the alpha floor")
  assertEqual(F.rgba(T["menu.suggestBorder"]), F.rgba(T["input.border"]), "the box's edge")
  assertEqual(F.rgba(T["list.ghostIcon"]), "1,1,1,1", "the white it drew")
  for _, skin in ipairs({ "obsidian", "glass", "contrast" }) do
    local O = Skin:ResolveSkin(skin)
    assertEqual(F.rgba(O["menu.suggestBg"]), F.rgba(O["menu.bg"]), skin)
    assertEqual(F.rgba(O["menu.suggestBorder"]), F.rgba(O["menu.border"]), skin)
    assertEqual(F.rgba(O["list.ghostIcon"]), F.rgba(O["icon.tint"]), skin)
  end
end)

-- ── row 16: the close button's glyph ─────────────────────────────────────────────────────────

local function stockClose(m)
  local b = m.CreateFrame("Button", nil, m.UIParent)
  local t = b:CreateTexture()
  rawset(b, "GetNormalTexture", function() return t end)
  return b
end

test("small misses: a stock close button's x wears the skin's body face, and Ignore fonts gives it back", function()
  -- red under: the glyph stayed on GameFontNormalLarge's face in every skin and escaped Ignore fonts.
  local m, Skin = env()
  local S = F.owner(Skin, OWNER, "obsidian")
  local b = stockClose(m)
  S.CloseButton(b, { stock = { b:GetNormalTexture() } })
  local glyph = Skin.painted[b].regions.glyph
  assertTrue(glyph ~= nil, "the glyph drew")
  assertEqual(face(glyph), body(Skin, "obsidian"))
  Skin:SetChoice(OWNER, "ka0s", "contrast")
  assertEqual(face(glyph), body(Skin, "contrast"), "a switch")
  Skin:SetIgnore(OWNER, nil, true)
  assertNil(face(glyph), "Ignore fonts: no skin font object")
end)

-- ── row 697: the copy window ─────────────────────────────────────────────────────────────────

test("small misses: a skinned copy window wears win.bgDense over a host's backdrop", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "contrast")
  local g = W.CopyWindow({ addonName = OWNER, name = "Dense", backdrop = { 0.2, 0.2, 0.2, 0.5 } }):Show("x")
  assertEqual(F.rgba(survey(m, g).backdropColor), F.tok(Skin, "contrast", "win.bgDense"))
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(F.rgba(survey(m, g).backdropColor), F.tok(Skin, "obsidian", "win.bgDense"), "a switch")
  local plain = W.CopyWindow({ addonName = "NoSkin", name = "Plain", backdrop = { 0.2, 0.2, 0.2, 0.5 } }):Show("x")
  assertEqual(F.rgba(survey(m, plain).backdropColor), "0.200,0.200,0.200,0.500", "an owner-less window's stays")
end)

-- ── row 704: the carried copy ────────────────────────────────────────────────────────────────

local function grab(m, W, opts, row)
  opts.stride, opts.onMove = 30, function() end
  local list = W.ReorderList(opts)
  local f = m.CreateFrame("Frame", nil, m.UIParent)
  f:SetSize(200, 30)
  row = row or {}
  row.ghostText = "Row"
  local h = list:AddRow(f, row)
  list:Finish(m.CreateFrame("Frame", nil, m.UIParent))
  h:__fire("OnMouseDown", "LeftButton")
  m.__cursorY = m.__cursorY - 40
  h:__fire("OnUpdate", 0.1)
  local g = W.__DragGhost
  g:__fire("OnUpdate", 0.1)
  return g
end

test("small misses: the carried copy takes the body face and the mark's tint, and a host's color wins", function()
  -- red under: GameFontNormal always, and a typed white icon.
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  local g = grab(m, W, { owner = OWNER })
  assertTrue(g:IsShown(), "the drag started")
  assertEqual(face(g.text), body(Skin, "obsidian"))
  assertEqual(F.rgba(survey(m, g.icon).vertex), F.tok(Skin, "obsidian", "list.ghostIcon"))
  W.__DragGhost:Hide()
  local hosted = grab(m, W, { owner = OWNER }, { ghostIconColor = { 0.2, 0.4, 0.6 } })
  assertEqual(F.rgba(survey(m, hosted.icon).vertex), "0.200,0.400,0.600,1", "the host's color")
end)

test("small misses: an owner-less list after a skinned one gets the ghost's template back", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  grab(m, W, { owner = OWNER })
  W.__DragGhost:Hide()
  local g = grab(m, W, {})
  assertNil(face(g.text), "the skin's font left with the skin")
  assertEqual(F.rgba(survey(m, g.icon).vertex), "1,1,1,1", "white, as minor 1")
end)

-- ── row 705: the menu's glyph column ─────────────────────────────────────────────────────────

local function menuRows(m, W, opts)
  local dd = W.Dropdown(m.UIParent, 110, opts)
  dd:SetOptions({ { value = "a", label = "A", glyph = ">" } })
  local saved, first = m.CreateFrame, nil
  m.CreateFrame = function(...)
    local f = saved(...)
    first = first or f
    return f
  end
  dd:__fire("OnClick")
  m.CreateFrame = saved
  return (first or W.__menu or {}).buttons, dd
end

test("small misses: an owned menu's glyph column reads font.mono at the host's size", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  local rows = menuRows(m, W, { owner = OWNER, glyphFont = "HostMono" })
  assertEqual(rows[1].glyph.__font[1], "Fonts\\" .. Skin:ResolveSkin("obsidian")["font.mono"])
  assertEqual(rows[1].glyph.__font[2], 11, "the size is the layout's")
end)

test("small misses: Ignore fonts and an owner-less menu keep the host's glyph face", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  Skin:SetIgnore(OWNER, nil, true)
  local rows = menuRows(m, W, { owner = OWNER, glyphFont = "HostMono" })
  assertEqual(rows[1].glyph.__font[1], "HostMono", "ignored")
  local m2, _, W2 = env()
  assertEqual(menuRows(m2, W2, { glyphFont = "HostMono" })[1].glyph.__font[1], "HostMono", "owner-less")
end)

test("small misses: S.GetFont('mono') answers font.mono, or nil rather than a proportional face", function()
  local _, Skin = env()
  local S = F.owner(Skin, OWNER, "obsidian")
  assertEqual(S.GetFont("mono"), "Fonts\\" .. Skin:ResolveSkin("obsidian")["font.mono"])
  assertEqual(S.GetFont(), body(Skin, "obsidian"), "the body face without a role")
  local m2, Skin2 = F.env({ files = F.FILES })
  m2.STANDARD_TEXT_FONT = "Fonts\\STD"
  local S2 = F.owner(Skin2, OWNER, "obsidian")
  assertNil(S2.GetFont("mono"), "no media: no face")
end)

-- ── row 707: the autocomplete's list ─────────────────────────────────────────────────────────

local function suggest(m, W, opts)
  local box = m.CreateFrame("EditBox", nil, m.UIParent, "BackdropTemplate")
  box:SetBackdropColor(0.3, 0.3, 0.3, 0.5)
  box:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
  rawset(box, "GetBackdropColor", function() return 0.3, 0.3, 0.3, 0.5 end)
  rawset(box, "GetBackdropBorderColor", function() return 0.4, 0.4, 0.4, 1 end)
  rawset(box, "GetText", function() return "ab" end)
  opts.provider = function() return { { text = "One" } } end
  local h = W.Autocomplete(box, opts)
  h:Refresh()
  return h
end

test("small misses: an owned list's fill and edge are the skin's, read on every show", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  local h = suggest(m, W, { owner = OWNER })
  assertEqual(F.rgba(survey(m, h.__list).backdropColor), F.tok(Skin, "obsidian", "menu.bg"))
  assertEqual(F.rgba(survey(m, h.__list).backdropBorderColor), F.tok(Skin, "obsidian", "menu.border"))
  Skin:SetChoice(OWNER, "ka0s", "contrast")
  h:Refresh()
  assertEqual(F.rgba(survey(m, h.__list).backdropColor), F.tok(Skin, "contrast", "menu.bg"), "a switch")
end)

test("small misses: an owner-less list, and a panel list on an ignored panel, follow the box", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  local plain = suggest(m, W, {})
  assertEqual(F.rgba(survey(m, plain.__list).backdropColor), "0.300,0.300,0.300,0.950", "the floor holds")
  assertEqual(F.rgba(survey(m, plain.__list).backdropBorderColor), "0.400,0.400,0.400,1")
  Skin:SetIgnore(OWNER, true, nil)
  local paneled = suggest(m, W, { owner = OWNER, panel = true })
  assertEqual(F.rgba(survey(m, paneled.__list).backdropColor), "0.300,0.300,0.300,0.950", "ignored")
end)

-- ── row 718: the glow ────────────────────────────────────────────────────────────────────────

local function glowEnv()
  local m, Skin = env()
  local calls = {}
  local L = m.LibStub:NewLibrary("LibCustomGlow-1.0", 24)
  L.PixelGlow_Start = function(_, color) calls[#calls + 1] = color or false end
  return m, Skin, m.LibStub("LibKa0s-Glow-1.0"), calls
end

test("small misses: a glow naming an owner and no color draws the skin's glow.color", function()
  local _, Skin, G, calls = glowEnv()
  F.owner(Skin, OWNER, "obsidian")
  local knobs = { owner = OWNER }
  assertTrue(G.Start({}, "pixel", knobs))
  assertEqual(F.rgba(calls[1]), F.tok(Skin, "obsidian", "glow.color"))
  assertNil(knobs.color, "the host's table is left alone")
  G.Start({}, "pixel", knobs)
  assertTrue(calls[1] ~= calls[2], "a fresh color per call: the button style keeps it by reference")
end)

test("small misses: a host's glow color wins, and an unregistered owner or none stays LCG's", function()
  local _, Skin, G, calls = glowEnv()
  F.owner(Skin, OWNER, "obsidian")
  local mine = { 1, 0, 0, 1 }
  G.Start({}, "pixel", { owner = OWNER, color = mine })
  assertTrue(calls[1] == mine, "the host's knob, by reference")
  G.Start({}, "pixel", { owner = "Nobody" })
  G.Start({}, "pixel", {})
  assertEqual(#calls, 3)
  assertEqual(calls[2], false, "unregistered")
  assertEqual(calls[3], false, "no owner")
end)
