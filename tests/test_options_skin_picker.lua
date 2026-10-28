-- tests/test_options_skin_picker.lua -- LibKa0s-Options-1.0's skin picker (OptionsSkinPicker.lua
-- minor 1, Options minor 34; LibKa0s#64, PK-01 of Ka0sAddonsCommonTasks
-- docs/2026-10-28-SKIN_OVERRIDES_AND_PICKER): O.SkinPicker, O.HideSkinPicker and
-- lib.SKIN_PICKER_STRINGS.
--
-- What it pins: the attach and the file's pairing; the window (shown, one per instance, about 280
-- wide, HIGH, toplevel, clamped, titled "Choose a skin"); the dropdown button naming the skin worn
-- now with its three swatches; the list of every skin, each row three swatches and the skin's name
-- in that skin's own body face and size; a pick moving the Skin major first and then the owner's
-- write seam, closing the list and not the window, the dropdown following; combat refusing a pick;
-- the eye (absent without onPreview) and the gear (onSettings, or the panel opened at the Skin tab,
-- then the window closed); onClose once per showing, by every route; the icons through
-- LibKa0s-Media-1.0 and their glyphs without it; spec.strings; and the degraded paths.
--
-- Every case runs on a fresh client (the paint and layer recorders, Core, the whole Skin major,
-- Pool and every Options file), so the owners one case registers never reach another.

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  K.test, K.assertEqual, K.assertTrue, K.assertFalse, K.assertNil
local F = dofile("tests/fixture_skin_paint.lua")
local Loader = dofile("tests/_kit/loader.lua")

local OWNER = "LootHistory"
local SKIN_FILES = { "Skin", "SkinDefs", "SkinPaint", "SkinPaintExtras", "SkinPaintControls", "SkinEUI" }
local OPTIONS = { "Options", "OptionsRegistry", "OptionsWidgets", "OptionsIds", "OptionsIdList", "OptionsTabs",
                  "OptionsCombat", "OptionsCompose", "OptionsScroll", "OptionsNav", "OptionsDrawer",
                  "OptionsKeybinds", "OptionsAppearance", "OptionsSkinPicker" }
local LSM = { ["font:Ka0s Inter"] = "Fonts\\Inter.ttf", ["font:Ka0s Nunito"] = "Fonts\\Nunito.ttf" }

--- Arm every frame's geometry (the kit answers 0 until a test asks): its size setters record
--- what they are told, so the window's width and its growth read back.
local function armGeometry(m)
  local create = m.CreateFrame
  m.CreateFrame = function(...)
    local f = create(...)
    rawset(f, "SetSize", function(self, w, h) self:__setGeom(w, h) end)
    rawset(f, "SetWidth", function(self, w) self:__setGeom(w, rawget(self, "__geomH") or 0) end)
    rawset(f, "SetHeight", function(self, h) self:__setGeom(rawget(self, "__geomW") or 0, h) end)
    return f
  end
end

--- A fresh client. `spec.media` loads LibKa0s-Media-1.0 too; `spec.noSkin` loads no Skin major.
--- Every StaticPopup_Show is recorded in `m.popups`. Answers m, Skin, the Options major.
local function env(spec)
  spec = spec or {}
  local m = F.env({ files = { "Core" }, lsm = LSM })
  dofile("tests/_kit/mock_layers.lua")(m)
  armGeometry(m)
  local files = {}
  if spec.media then files[#files + 1] = "Media"; files[#files + 1] = "MediaIcons" end
  if not spec.noSkin then
    for _, f in ipairs(SKIN_FILES) do files[#files + 1] = f end
  end
  files[#files + 1] = "Pool"
  for _, f in ipairs(OPTIONS) do files[#files + 1] = f end
  for _, f in ipairs(files) do Loader.load("LibKa0s/" .. f .. ".lua", nil, m) end
  m.popups = {}
  m.StaticPopup_Show = function(which, a1) m.popups[#m.popups + 1] = { which = which, a1 = a1 } end
  return m, m.LibStub("LibKa0s-Skin-1.0", true), m.LibStub("LibKa0s-Options-1.0")
end

--- Register `owner` with a profile store; answers the store.
local function register(Skin, owner, skin)
  local store = { source = "ka0s", skin = skin or "ka0s" }
  Skin:RegisterOwner(owner, {
    label = owner .. " Label",
    get = function() return { source = store.source, skin = store.skin } end,
    set = function(src, sk) store.source, store.skin = src, sk end,
  })
  if skin then Skin:SetChoice(owner, "ka0s", skin) end
  return store
end

local seq = 0
--- An Options instance for a host named `owner`.
local function instance(lib, owner)
  seq = seq + 1
  return lib:New({
    parentTitle = "Picker Host", mainPanelName = "PickerMain" .. seq, addonName = owner,
    print = function() end,
    get = function() end, set = function() end, applyDefault = function() end,
    rowsForPage = function() return {} end, allRows = function() return {} end,
  })
end

--- The picker's spec over `store`: its read, and a write seam that records each call.
local function specFor(store, extra)
  local spec = {
    get = function() return { source = store.source, skin = store.skin } end,
    set = function(src, sk)
      store.calls = store.calls or {}
      store.calls[#store.calls + 1] = { src, sk }
      store.source, store.skin = src, sk
    end,
    onClose = function() store.closed = (store.closed or 0) + 1 end,
  }
  for k, v in pairs(extra or {}) do spec[k] = v end
  return spec
end

local function hex3(def, i)
  local r, g, b = tostring(def.swatches[i]):match("^#?(%x%x)(%x%x)(%x%x)")
  return F.rgba({ tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255, 1 })
end

local function swatchesOf(m, list)
  local out = {}
  for i, t in ipairs(list) do out[i] = F.rgba(m.__paint(t).color) end
  return out
end

-- ── the attach ───────────────────────────────────────────────────────────────────────────────

test("skin picker: OptionsSkinPicker is minor 1, paired on the shell, and attaches two members", function()
  local _, _, lib = env()
  assertEqual(lib.MODULES.OptionsSkinPicker, 1)
  assertEqual(lib.__pickerMinor, 1)
  assertEqual(lib.__pickerShellMinor, lib.MINOR, "paired on the shell's minor")
  assertTrue(lib.MINOR >= 34, "Options minor 34 attaches it")
  assertEqual(type(lib.SKIN_PICKER_STRINGS), "table")
  assertEqual(lib.SKIN_PICKER_STRINGS.TITLE, "Choose a skin")
  local O = instance(lib, OWNER)
  assertEqual(type(O.SkinPicker), "function")
  assertEqual(type(O.HideSkinPicker), "function")
end)

-- ── the window ───────────────────────────────────────────────────────────────────────────────

test("skin picker: shows one small HIGH, toplevel, clamped window naming the skin worn now", function()
  local m, Skin, lib = env()
  local store = register(Skin, OWNER, "obsidian")
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  assertTrue(f ~= nil and f:IsShown(), "shown")
  local layers = m.__layers(f)
  assertEqual(layers.strata, "HIGH", "frame-layering T4: an on-demand window")
  assertTrue(layers.toplevel, "toplevel (frame-layering §4)")
  assertTrue(layers.clamped, "clamped")
  assertEqual(f:GetWidth(), 280)
  assertEqual(f.title:GetText(), "Choose a skin")
  local def = Skin:GetSkin("obsidian")
  assertEqual(f.dd.text:GetText(), def.label, "the dropdown names the skin worn now")
  local sw = swatchesOf(m, f.dd.swatches)
  assertEqual(#sw, 3, "three swatches")
  for i = 1, 3 do assertEqual(sw[i], hex3(def, i), "swatch " .. i) end
  assertTrue(O.SkinPicker(specFor(store)) == f, "one window per instance")
  assertTrue(Skin.painted[f] ~= nil and Skin.painted[f].owner == OWNER, "painted for the owner")
end)

test("skin picker: the list holds every skin, three swatches each and its name in its own face", function()
  local m, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  assertFalse(f.list:IsShown(), "the list starts closed")
  local closedH = f:GetHeight()
  f.dd:__fire("OnClick")
  assertTrue(f.list:IsShown(), "a click opens it")
  assertTrue(f:GetHeight() > closedH, "the window grows to hold it")
  local skins = Skin:Skins()
  local rows = {}
  for _, row in ipairs({ f.list:GetChildren() }) do if row.key then rows[#rows + 1] = row end end
  assertEqual(#rows, #skins, "a row per skin")
  for i, def in ipairs(skins) do
    local row = rows[i]
    assertEqual(row.key, def.key, "in Skin:Skins() order")
    assertEqual(row.text:GetText(), def.label)
    local sw = swatchesOf(m, row.swatches)
    assertEqual(#sw, 3, def.key .. ": three swatches")
    for j = 1, 3 do assertEqual(sw[j], hex3(def, j), def.key .. " swatch " .. j) end
    local T = Skin:ResolveSkin(def.key)
    local face = LSM["font:" .. tostring(T["font.body"])]
    local path, size = row.text:GetFont()
    if face then
      assertEqual(path, face, def.key .. ": its own body face")
      assertEqual(size, T["font.bodySize"], def.key .. ": its own body size")
    else
      assertNil(path, def.key .. ": a face LSM lacks leaves the row's normal font")
    end
  end
  f.dd:__fire("OnClick")
  assertFalse(f.list:IsShown(), "a second click closes it")
end)

test("skin picker: a pick moves the Skin major, then the seam, closes the list and keeps the window", function()
  local m, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local spec = specFor(store)
  local seam, order = spec.set, {}
  spec.set = function(src, sk)
    order[#order + 1] = "set:" .. select(2, Skin:GetChoice(OWNER))
    seam(src, sk)
  end
  local f = O.SkinPicker(spec)
  f.dd:__fire("OnClick")
  local row
  for _, r in ipairs({ f.list:GetChildren() }) do if r.key == "ember" then row = r end end
  row:__fire("OnClick")
  assertEqual(order[1], "set:ember", "SetChoice ran before the owner's write seam")
  assertEqual(store.calls[1][1], "ka0s", "the stored source kept")
  assertEqual(store.calls[1][2], "ember")
  assertFalse(f.list:IsShown(), "the list closes")
  assertTrue(f:IsShown(), "the window stays")
  assertEqual(f.dd.text:GetText(), Skin:GetSkin("ember").label, "the dropdown follows")
  assertEqual(F.rgba(m.__paint(f.title).textColor), F.tok(Skin, "ember", "title.text"), "the window repainted live")
  assertEqual(#m.popups, 0, "no reload popup for a Ka0s skin switch")
  assertNil(store.closed, "a pick does not close the window")
end)

test("skin picker: the dropdown follows a switch made elsewhere", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  store.skin = "glass"
  Skin:SetChoice(OWNER, "ka0s", "glass")
  assertEqual(f.dd.text:GetText(), Skin:GetSkin("glass").label, "OnLooksChanged refreshed it")
end)

test("skin picker: a pick that needs a reload raises the one reload popup", function()
  local m, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  Skin.SetChoice = function() return true, true end
  f.dd:__fire("OnClick")
  for _, r in ipairs({ f.list:GetChildren() }) do if r.key == "glass" then r:__fire("OnClick") end end
  assertEqual(#m.popups, 1)
  assertEqual(m.popups[1].which, "LIBKA0S_SKIN_RELOAD")
  assertEqual(m.popups[1].a1, OWNER .. " Label")
end)

test("skin picker: in combat a pick writes nothing", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  lib.__combatLocked = true
  f.dd:__fire("OnClick")
  for _, r in ipairs({ f.list:GetChildren() }) do if r.key == "ember" then r:__fire("OnClick") end end
  lib.__combatLocked = false
  assertEqual(select(2, Skin:GetChoice(OWNER)), "ka0s", "the applied skin did not move")
  assertNil(store.calls, "the seam was not called")
  assertTrue(f:IsShown(), "the window stays")
end)

-- ── the eye, the gear, closing ───────────────────────────────────────────────────────────────

test("skin picker: the eye shows only with onPreview, and calls it", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  assertFalse(f.preview:IsShown(), "no onPreview, no eye")
  local previews = 0
  O.SkinPicker(specFor(store, { onPreview = function() previews = previews + 1 end }))
  assertTrue(f.preview:IsShown(), "the eye")
  assertEqual(f.preview.__tip, "Preview: open test mode")
  f.preview:__fire("OnClick")
  assertEqual(previews, 1)
  assertTrue(f:IsShown(), "the eye does not close the window")
  assertNil(store.closed)
end)

test("skin picker: the gear opens the panel at the Skin tab by default, then closes", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local calls = {}
  O.OpenOptionsPanel = function() calls[#calls + 1] = "open" end
  O.SelectTab = function(page, tab) calls[#calls + 1] = "tab:" .. tostring(page) .. "/" .. tostring(tab) end
  local f = O.SkinPicker(specFor(store, { page = "general" }))
  assertEqual(f.settings.__tip, "Open the Skin settings")
  f.settings:__fire("OnClick")
  assertEqual(table.concat(calls, ","), "open,tab:general/Appearance", "the panel, then the Skin tab")
  assertFalse(f:IsShown(), "and the window closes")
  assertEqual(store.closed, 1, "onClose once")
  calls = {}
  O.SkinPicker(specFor(store, { page = "general", tab = "Look" }))
  f.settings:__fire("OnClick")
  assertEqual(calls[2], "tab:general/Look", "spec.tab names another key")
  local own = 0
  O.SkinPicker(specFor(store, { onSettings = function() own = own + 1 end }))
  calls = {}
  f.settings:__fire("OnClick")
  assertEqual(own, 1, "spec.onSettings replaces the default")
  assertEqual(#calls, 0)
end)

test("skin picker: in combat the gear opens nothing and the window stays up, not marked seen", function()
  -- red under: hide() after a refused OpenOptionsPanel (onClose set pickerSeen with nothing opened).
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local own = 0
  local f = O.SkinPicker(specFor(store, { onSettings = function() own = own + 1 end }))
  lib.__combatLocked = true
  f.settings:__fire("OnClick")
  lib.__combatLocked = false
  assertEqual(own, 0, "spec.onSettings not called in combat")
  assertTrue(f:IsShown(), "the window stays")
  assertNil(store.closed, "onClose did not run")
  O.SkinPicker(specFor(store))
  O.OpenOptionsPanel = function() return false end
  f.settings:__fire("OnClick")
  assertTrue(f:IsShown(), "a panel that refused to open leaves the window up")
  assertNil(store.closed)
end)

test("skin picker: a window per owner, each refreshed only by its own owner", function()
  -- red under: one P for the instance (the first window orphaned, its listener refreshing the second).
  local _, Skin, lib = env()
  local storeA = register(Skin, OWNER)
  local storeB = register(Skin, "Other")
  local O = instance(lib, OWNER)
  local a = O.SkinPicker(specFor(storeA))
  local b = O.SkinPicker(specFor(storeB, { owner = "Other" }))
  assertTrue(a ~= b, "the other owner's own window")
  assertFalse(a:IsShown(), "the first hidden")
  assertEqual(storeA.closed, 1, "and closed once")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(b.dd.text:GetText(), Skin:GetSkin("ka0s").label, "the first owner's switch leaves the second alone")
  storeB.skin = "ember"
  Skin:SetChoice("Other", "ka0s", "ember")
  assertEqual(b.dd.text:GetText(), Skin:GetSkin("ember").label, "its own owner's switch refreshes it")
  storeA.skin = "obsidian"
  assertTrue(O.SkinPicker(specFor(storeA)) == a, "the first owner's window again, reused")
  assertFalse(b:IsShown())
  assertEqual(a.dd.text:GetText(), Skin:GetSkin("obsidian").label, "refreshed on show")
end)

test("skin picker: a skin registered after the first show gains its row on the next", function()
  -- red under: the rows built once per window.
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  local before = #{ f.list:GetChildren() }
  Skin:RegisterSkin({ key = "late", label = "Late Skin", swatches = { "#112233", "#445566", "#778899" },
                      tokens = {} })
  O.HideSkinPicker()
  O.SkinPicker(specFor(store))
  local rows = { f.list:GetChildren() }
  assertEqual(#rows, before + 1, "one row added")
  assertEqual(rows[#rows].key, "late", "at the end")
  assertEqual(rows[#rows].text:GetText(), "Late Skin")
end)

test("skin picker: onClose runs once per showing, by every route", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  f.close:__fire("OnClick")
  assertFalse(f:IsShown(), "the close control closes")
  f:__fire("OnHide")
  O.HideSkinPicker()
  assertEqual(store.closed, 1, "once, though the client's OnHide follows")
  O.SkinPicker(specFor(store))
  O.HideSkinPicker()
  assertEqual(store.closed, 2, "HideSkinPicker is a route too")
  O.SkinPicker(specFor(store))
  f:__fire("OnHide")
  assertEqual(store.closed, 2, "an OnHide while still shown (UIParent hidden) is not a close")
  f:Hide(); f:__fire("OnHide")
  assertEqual(store.closed, 3, "Escape (the client's hide) is")
end)

-- ── icons, strings, degradation ──────────────────────────────────────────────────────────────

test("skin picker: the icons come from LibKa0s-Media-1.0, and are glyphs without it", function()
  local m, Skin, lib = env({ media = true })
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store, { onPreview = function() end }))
  local Media = m.LibStub("LibKa0s-Media-1.0")
  assertTrue(Media.Icon(OWNER, "eye") ~= nil and Media.Icon(OWNER, "settings") ~= nil, "both names are Media's")
  assertEqual(m.__paint(f.preview.icon).texture, Media.Icon(OWNER, "eye"))
  assertEqual(m.__paint(f.settings.icon).texture, Media.Icon(OWNER, "settings"))
  local _, Skin2, lib2 = env()
  local store2 = register(Skin2, OWNER)
  local f2 = instance(lib2, OWNER).SkinPicker(specFor(store2, { onPreview = function() end }))
  assertNil(f2.preview.icon, "no Media, no icon")
  assertEqual(f2.preview.text:GetText(), lib2.SKIN_PICKER_STRINGS.PREVIEW_GLYPH)
  assertEqual(f2.settings.text:GetText(), lib2.SKIN_PICKER_STRINGS.SETTINGS_GLYPH)
end)

test("skin picker: spec.strings translates the title, the tips and a skin's name", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store, { strings = { TITLE = "Skin waehlen", SETTINGS_TIP = "Einstellungen",
                                                      SKIN_ka0s = "Ka0s (de)" } }))
  assertEqual(f.title:GetText(), "Skin waehlen")
  assertEqual(f.settings.__tip, "Einstellungen")
  assertEqual(f.dd.text:GetText(), "Ka0s (de)")
  assertEqual(lib.SKIN_PICKER_STRINGS.TITLE, "Choose a skin", "the library's words are not written through")
end)

test("skin picker: nil with no Skin major, or for an owner that never registered", function()
  local _, _, lib = env({ noSkin = true })
  assertNil(instance(lib, OWNER).SkinPicker({}), "no Skin major")
  local _, Skin2, lib2 = env()
  assertNil(instance(lib2, OWNER).SkinPicker({}), "not registered")
  register(Skin2, "Other")
  assertTrue(instance(lib2, OWNER).SkinPicker({ owner = "Other" }) ~= nil, "spec.owner names the owner")
  instance(lib2, OWNER).HideSkinPicker()   -- nothing shown: a no-op
end)
