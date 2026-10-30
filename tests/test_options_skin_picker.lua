-- tests/test_options_skin_picker.lua -- LibKa0s-Options-1.0's skin picker (OptionsSkinPicker.lua
-- minor 2, Options minor 34; LibKa0s#64, PK-01, PK-02 and PK-03 of Ka0sAddonsCommonTasks
-- docs/2026-10-28-SKIN_OVERRIDES_AND_PICKER, and LK-11 of docs/2026-10-30-SKIN_LIBRARY_FOLLOWUPS):
-- O.SkinPicker, O.HideSkinPicker,
-- lib.SKIN_PICKER_STRINGS and the library-level queue, lib.__pickerQueue.
--
-- What it pins: the attach and the file's pairing; the window (shown, one per owner, about 280
-- wide, DIALOG, toplevel, clamped, movable, its center 75% of the way up UIParent on every show,
-- titled "Choose a skin", the addon's label on its own line above the dropdown, never cut off: the
-- window widens to it, on every show and skin change); the dropdown button naming the skin worn now
-- with its three swatches; the list of every skin, each row three swatches and the skin's name in
-- that skin's own body face and size; a pick previewing (the Skin major moves, the window repaints,
-- no write and no popup), closing the list and not the window; Apply saving through the owner's
-- write seam, the one reload popup a pick asked for, then the close; the close control and Escape
-- putting the preview back with no write; "Apply to all Ka0s addons" (hidden alone; the skin half
-- of the Skin tab's copy; one popup; every queued picker dismissed); combat refusing a pick, Apply,
-- Apply to all and the gear; the eye (absent without onPreview, working while a preview is pending,
-- the picker raised after it over the HIGH window it opens) and the gear (saves, then onSettings,
-- or the panel opened at spec.page and its Skin tab, then the close); onClose once per showing, by
-- every route; one window across two Options instances sharing one library table (a second owner
-- queued, answered nil, "queued", shown when the first closes, taken out by its own HideSkinPicker;
-- waiting out combat); a dismissal putting back the owner's stored choice as it reads at the close;
-- a shown StaticPopup re-raised on show; the icons through LibKa0s-Media-1.0 and their glyphs
-- without it; spec.strings; and the degraded paths. Cases whose behavior PK-02 or PK-03 changed
-- carry a "red under" line naming the behavior they replaced.
--
-- Every case runs on a fresh client (the paint and layer recorders, Core, the whole Skin major,
-- Pool and every Options file), so the owners one case registers never reach another, and neither
-- does the library's queue.

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  K.test, K.assertEqual, K.assertTrue, K.assertFalse, K.assertNil
local F = dofile("tests/fixture_skin_paint.lua")
local Loader = dofile("tests/_kit/loader.lua")

local OWNER, OTHER, THIRD = "LootHistory", "BankLedger", "KickCD"
local SKIN_FILES = { "Skin", "SkinDefs", "SkinPaint", "SkinPaintExtras", "SkinPaintControls", "SkinEUI" }
local OPTIONS = { "Options", "OptionsRegistry", "OptionsWidgets", "OptionsIds", "OptionsIdList", "OptionsTabs",
                  "OptionsCombat", "OptionsCompose", "OptionsScroll", "OptionsNav", "OptionsDrawer",
                  "OptionsKeybinds", "OptionsAppearance", "OptionsSkinPicker" }
local LSM = { ["font:Ka0s Expressway"] = "Fonts\\Expressway.ttf", ["font:Ka0s Nunito"] = "Fonts\\Nunito.ttf" }

--- Arm every frame's geometry (the kit answers 0 until a test asks): its size setters record
--- what they are told, so the window's width and its growth read back, and its anchors are
--- recorded in `__pts` (ClearAllPoints empties them), and SetMovable in `__movable`.
local function armGeometry(m)
  local create = m.CreateFrame
  m.CreateFrame = function(...)
    local f = create(...)
    rawset(f, "SetSize", function(self, w, h) self:__setGeom(w, h) end)
    rawset(f, "SetWidth", function(self, w) self:__setGeom(w, rawget(self, "__geomH") or 0) end)
    rawset(f, "SetHeight", function(self, h) self:__setGeom(rawget(self, "__geomW") or 0, h) end)
    rawset(f, "SetPoint", function(self, ...)
      local pts = rawget(self, "__pts") or {}
      pts[#pts + 1] = { ... }
      rawset(self, "__pts", pts)
    end)
    rawset(f, "ClearAllPoints", function(self) rawset(self, "__pts", {}) end)
    rawset(f, "SetMovable", function(self, v) rawset(self, "__movable", v) end)
    return f
  end
end

--- A fresh client. `spec.media` loads LibKa0s-Media-1.0 too; `spec.noSkin` loads no Skin major.
--- UIParent answers `m.uiHeight` (768) for its height. Every StaticPopup_Show is recorded in
--- `m.popups`. Answers m, Skin, the Options major.
local function env(spec)
  spec = spec or {}
  local m = F.env({ files = { "Core" }, lsm = LSM })
  dofile("tests/_kit/mock_layers.lua")(m)
  armGeometry(m)
  m.uiHeight = 768
  rawset(m.UIParent, "GetHeight", function() return m.uiHeight end)
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

--- Register `owner` with a profile store; answers the store. Its registered setter (what
--- Skin:WriteChoice reaches) records every call in `store.writes`.
local function register(Skin, owner, skin)
  local store = { source = "ka0s", skin = skin or "ka0s" }
  Skin:RegisterOwner(owner, {
    label = owner .. " Label",
    get = function() return { source = store.source, skin = store.skin } end,
    set = function(src, sk, ig, media)
      store.writes = store.writes or {}
      store.writes[#store.writes + 1] = { src, sk, ig, media }
      store.source, store.skin = src, sk
    end,
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

--- Open the window's list and click the row for skin `key`.
local function pickRow(f, key)
  f.dd:__fire("OnClick")
  for _, r in ipairs({ f.list:GetChildren() }) do
    if r.key == key then r:__fire("OnClick") end
  end
end

local function applied(Skin, owner)
  return select(2, Skin:GetChoice(owner))
end

--- Make every frame's Hide fire its OnHide at once when the frame was shown, as the client does
--- (the kit's Hide only clears the flag). Arm it before the window is built.
local function armClientHide(m)
  local create = m.CreateFrame
  m.CreateFrame = function(...)
    local f = create(...)
    local hide = f.Hide
    rawset(f, "Hide", function(self)
      local was = self:IsShown()
      hide(self)
      if was then self:__fire("OnHide") end
      return self
    end)
    return f
  end
end

-- ── the attach ───────────────────────────────────────────────────────────────────────────────

test("skin picker: OptionsSkinPicker is minor 2, paired on the shell, and attaches two members", function()
  local _, _, lib = env()
  assertEqual(lib.MODULES.OptionsSkinPicker, 2)
  assertEqual(lib.__pickerMinor, 2)
  assertEqual(lib.__pickerShellMinor, lib.MINOR, "paired on the shell's minor")
  assertTrue(lib.MINOR >= 34, "Options minor 34 attaches it")
  assertEqual(type(lib.SKIN_PICKER_STRINGS), "table")
  assertEqual(lib.SKIN_PICKER_STRINGS.TITLE, "Choose a skin")
  assertNil(lib.SKIN_PICKER_STRINGS.TITLE_FOR, "retired: the addon's name has its own line (R-11)")
  assertEqual(lib.SKIN_PICKER_STRINGS.APPLY, "Apply")
  assertEqual(lib.SKIN_PICKER_STRINGS.APPLY_ALL, "Apply to all Ka0s addons")
  assertEqual(type(lib.__pickerQueue), "table", "the library-level queue")
  assertEqual(type(lib.__pickerQueue.waiting), "table")
  local O = instance(lib, OWNER)
  assertEqual(type(O.SkinPicker), "function")
  assertEqual(type(O.HideSkinPicker), "function")
end)

test("skin picker: a newer attach of the file adopts the queue already on the library table", function()
  -- red under: a queue created per file load (a second copy's picker would not see the first's).
  local m, _, lib = env()
  local q = lib.__pickerQueue
  q.waiting[1] = { owner = "Kept" }
  lib.__pickerMinor = nil   -- as a newer minor would find it: the guard lets the file run again
  Loader.load("LibKa0s/OptionsSkinPicker.lua", nil, m)
  assertTrue(lib.__pickerQueue == q, "the same table")
  assertEqual(q.waiting[1].owner, "Kept", "with what it held")
  lib.__pickerQueue = { current = false }
  lib.__pickerMinor = nil
  Loader.load("LibKa0s/OptionsSkinPicker.lua", nil, m)
  assertEqual(type(lib.__pickerQueue.waiting), "table", "a queue missing its list gains one")
end)

-- ── the window ───────────────────────────────────────────────────────────────────────────────

test("skin picker: shows one small DIALOG, toplevel, clamped window naming the addon and the skin worn now",
function()
  -- red under: TITLE_FOR, which put the addon in the title, where a long label was cut off (R-11);
  -- and HIGH (PK-03).
  local m, Skin, lib = env()
  local store = register(Skin, OWNER, "obsidian")
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  assertTrue(f ~= nil and f:IsShown(), "shown")
  local layers = m.__layers(f)
  assertEqual(layers.strata, "DIALOG", "frame-layering T6: a dialog the player answers")
  assertTrue(layers.toplevel, "toplevel (frame-layering §4)")
  assertTrue(layers.clamped, "clamped")
  assertEqual(f:GetWidth(), 280)
  assertEqual(f.title:GetText(), "Choose a skin", "the title")
  assertEqual(f.ownerLabel:GetText(), OWNER .. " Label", "the addon's label on its own line")
  local def = Skin:GetSkin("obsidian")
  assertEqual(f.dd.text:GetText(), def.label, "the dropdown names the skin worn now")
  local sw = swatchesOf(m, f.dd.swatches)
  assertEqual(#sw, 3, "three swatches")
  for i = 1, 3 do assertEqual(sw[i], hex3(def, i), "swatch " .. i) end
  assertTrue(O.SkinPicker(specFor(store)) == f, "one window per owner")
  assertTrue(Skin.painted[f] ~= nil and Skin.painted[f].owner == OWNER, "painted for the owner")
end)

test("skin picker: the window's center sits 75% of the way up UIParent, re-anchored on every show", function()
  -- red under: SetPoint("CENTER") once at build (the window over the main window the eye opens).
  local m, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  local pts = rawget(f, "__pts")
  assertEqual(#pts, 1, "one anchor")
  assertEqual(pts[1][1], "CENTER")
  assertTrue(pts[1][2] == m.UIParent, "on UIParent")
  assertEqual(pts[1][3], "BOTTOM")
  assertEqual(pts[1][4], 0)
  assertEqual(pts[1][5], 768 * 0.75, "75% of UIParent's height")
  assertEqual(rawget(f, "__movable"), true, "movable")
  O.HideSkinPicker()
  m.uiHeight = 1080
  O.SkinPicker(specFor(store))
  pts = rawget(f, "__pts")
  assertEqual(#pts, 1, "the old anchor cleared")
  assertEqual(pts[1][5], 1080 * 0.75, "read again on the next show")
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

test("skin picker: the addon's label sits on its own line above the dropdown, as a heading", function()
  -- red under: TITLE_FOR, "Choose a skin for <label>" in the title, cut off past 224 px (R-11).
  local m, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  local fs = f.ownerLabel
  assertTrue(fs ~= nil, "frame.ownerLabel")
  assertEqual(fs:GetText(), OWNER .. " Label", "Skin:OwnerLabel(owner)")
  assertEqual(rawget(fs, "__wordWrap"), false, "one line")
  assertEqual(rawget(fs, "__justifyH"), "LEFT")
  local function topY(frame)
    for _, pt in ipairs(rawget(frame, "__pts") or rawget(frame, "__points") or {}) do
      if pt[1] == "TOPLEFT" then return pt[5] end
    end
  end
  local labelY, ddY = topY(fs), topY(f.dd)
  assertTrue(labelY ~= nil and ddY ~= nil, "both anchored by their top left")
  assertTrue(labelY > ddY, "the label above the dropdown")
  assertTrue(labelY < -8, "and below the title")
  assertEqual(Skin.painted[fs] and Skin.painted[fs].owner, OWNER, "painted for the owner")
  assertEqual(F.rgba(m.__paint(fs).textColor), F.tok(Skin, "ka0s", "text.heading"), "the heading role")
  register(Skin, OTHER)
  local B = instance(lib, OTHER)
  O.HideSkinPicker()
  local g = B.SkinPicker(specFor(store))
  assertEqual(g.ownerLabel:GetText(), OTHER .. " Label", "each owner's own label")
end)

test("skin picker: a long label widens the window to its unbounded width, never cutting it off", function()
  -- red under: a fixed 280 wide window whose one-line title truncated the longest roster label.
  local m, Skin, lib = env()
  local long = "Ka0s Premade Groups Filter Extension"
  local store = { source = "ka0s", skin = "ka0s" }
  Skin:RegisterOwner("PremadeGroupsFilterExtension", {
    label = long,
    get = function() return { source = store.source, skin = store.skin } end,
    set = function(src, sk) store.source, store.skin = src, sk end,
  })
  local width = 300
  local create = m.CreateFrame
  m.CreateFrame = function(...)
    local fr = create(...)
    local mk = fr.CreateFontString
    rawset(fr, "CreateFontString", function(self, ...)
      local fs = mk(self, ...)
      rawset(fs, "GetUnboundedStringWidth", function(s2)
        return s2:GetText() == long and width or 0
      end)
      return fs
    end)
    return fr
  end
  local O = instance(lib, "PremadeGroupsFilterExtension")
  local f = O.SkinPicker(specFor(store, { owner = "PremadeGroupsFilterExtension" }))
  assertEqual(f.ownerLabel:GetText(), long)
  assertEqual(f:GetWidth(), 300 + 2 * 12, "the label's width plus the side padding")
  assertEqual(f.title:GetText(), "Choose a skin", "the title is unchanged")
  width = 250.4
  O.HideSkinPicker()
  O.SkinPicker(specFor(store, { owner = "PremadeGroupsFilterExtension" }))
  assertEqual(f:GetWidth(), 280, "never narrower than 280: refit on every show")
end)

test("skin picker: a skin change that moves the label's width refits the window", function()
  -- red under: a width set once at build.
  local m, Skin, lib = env()
  local store = register(Skin, OWNER)
  local width = 0
  local create = m.CreateFrame
  m.CreateFrame = function(...)
    local fr = create(...)
    local mk = fr.CreateFontString
    rawset(fr, "CreateFontString", function(self, ...)
      local fs = mk(self, ...)
      rawset(fs, "GetUnboundedStringWidth", function() return width end)
      return fs
    end)
    return fr
  end
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  assertEqual(f:GetWidth(), 280)
  width = 290.2
  pickRow(f, "ember")
  assertEqual(f:GetWidth(), 291 + 2 * 12, "refit on the owner's looks changing, rounded up")
  width = 10
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertEqual(f:GetWidth(), 280, "and back")
end)

-- ── preview, Apply, dismiss ──────────────────────────────────────────────────────────────────

test("skin picker: a pick previews: the Skin major moves live, nothing is written, the window stays", function()
  -- red under: minor 1's pick, which called spec.set(source, key) at once.
  local m, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  pickRow(f, "ember")
  assertEqual(applied(Skin, OWNER), "ember", "the Skin major moved")
  assertNil(store.calls, "the owner's write seam was not called")
  assertEqual(store.skin, "ka0s", "the profile still holds the skin it had")
  assertFalse(f.list:IsShown(), "the list closes")
  assertTrue(f:IsShown(), "the window stays")
  assertEqual(f.dd.text:GetText(), Skin:GetSkin("ember").label, "the dropdown names the pending pick")
  assertEqual(F.rgba(m.__paint(f.title).textColor), F.tok(Skin, "ember", "title.text"), "the window repainted live")
  assertEqual(#m.popups, 0, "no popup")
  assertNil(store.closed, "a pick does not close the window")
end)

test("skin picker: Apply saves the pending pick through the owner's seam, then closes", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  assertTrue(f.apply:IsShown(), "the Apply button")
  assertEqual(f.apply.text:GetText(), "Apply")
  assertTrue(Skin.painted[f.apply] ~= nil and Skin.painted[f.apply].regions.primary == true,
    "painted through the owner's facade as a primary button")
  pickRow(f, "glass")
  pickRow(f, "ember")
  f.apply:__fire("OnClick")
  assertEqual(#store.calls, 1, "one write, the last pick")
  assertEqual(store.calls[1][1], "ka0s", "the stored source kept")
  assertEqual(store.calls[1][2], "ember")
  assertEqual(applied(Skin, OWNER), "ember", "the Skin major stays on it")
  assertFalse(f:IsShown(), "the window closes")
  assertEqual(store.closed, 1, "onClose once: the host marks the picker seen")
  local g = O.SkinPicker(specFor(store))
  g.apply:__fire("OnClick")
  assertEqual(#store.calls, 1, "Apply with nothing picked writes nothing")
  assertEqual(store.closed, 2, "and closes")
end)

test("skin picker: a pick that asks for a reload raises the one popup at Apply, not at the pick", function()
  -- red under: minor 1, which raised the popup on the pick itself.
  local m, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  local setChoice = Skin.SetChoice
  Skin.SetChoice = function(self, owner, src, key)
    setChoice(self, owner, src, key)
    return true, key == "glass"
  end
  pickRow(f, "glass")
  pickRow(f, "ember")
  assertEqual(#m.popups, 0, "no popup while previewing")
  f.apply:__fire("OnClick")
  assertEqual(#m.popups, 1, "one popup: a pick in this showing asked for it")
  assertEqual(m.popups[1].which, "LIBKA0S_SKIN_RELOAD")
  assertEqual(m.popups[1].a1, OWNER .. " Label")
  assertEqual(store.calls[1][2], "ember")
end)

test("skin picker: the close control and Escape put the preview back and write nothing", function()
  -- red under: minor 1, where a pick had already written and a close kept it.
  local m, Skin, lib = env()
  local store = register(Skin, OWNER, "obsidian")
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  pickRow(f, "ember")
  f.close:__fire("OnClick")
  assertEqual(applied(Skin, OWNER), "obsidian", "back to the choice the window opened with")
  assertNil(store.calls, "no write")
  assertEqual(store.closed, 1, "onClose ran: the dismissal still counts as seen")
  assertEqual(F.rgba(m.__paint(f.title).textColor), F.tok(Skin, "obsidian", "title.text"), "repainted back")
  O.SkinPicker(specFor(store))
  pickRow(f, "glass")
  f:Hide(); f:__fire("OnHide")   -- Escape: UISpecialFrames hides it
  assertEqual(applied(Skin, OWNER), "obsidian", "Escape puts it back too")
  assertNil(store.calls)
  assertEqual(store.closed, 2)
  assertEqual(#m.popups, 0)
end)

test("skin picker: a close puts back the owner's stored choice now, not the one the window opened with",
function()
  -- red under: revert() to the choice the window opened with, which clobbered a skin the Skin tab
  -- or a profile change stored while the picker was up (PK-03).
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  pickRow(f, "ember")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")    -- the owner's seam (the Skin tab) wrote obsidian
  store.source, store.skin = "ka0s", "obsidian"
  f.close:__fire("OnClick")
  assertEqual(applied(Skin, OWNER), "obsidian", "the stored choice is worn")
  assertNil(store.calls, "the picker wrote nothing")
  assertNil(store.writes, "nor did the Skin major's setter run")
  assertEqual(store.skin, "obsidian")
  O.SkinPicker(specFor(store))
  pickRow(f, "glass")
  store.skin = "ember"                         -- a profile change: the store moved alone
  O.HideSkinPicker()
  assertEqual(applied(Skin, OWNER), "ember", "the profile's choice, read through spec.get")
  assertNil(store.calls)
end)

test("skin picker: a close with no usable spec.get puts back the choice the window opened with",
function()
  -- red under: revert() falling back to Skin:GetChoice, which by then answers the preview, so a
  -- host with no get, a get that raises or a get naming an unknown skin kept the unsaved preview
  -- worn after the close (PK-03).
  local m, Skin, lib = env()
  local errs = 0
  m.geterrorhandler = function() return function() errs = errs + 1 end end
  local store = register(Skin, OWNER, "obsidian")
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store, { get = false }))
  pickRow(f, "ember")
  assertEqual(applied(Skin, OWNER), "ember", "the preview is worn")
  f.close:__fire("OnClick")
  assertEqual(applied(Skin, OWNER), "obsidian", "no spec.get: the opened choice is back")
  assertNil(store.calls, "no write")
  O.SkinPicker(specFor(store, { get = function() error("get broke") end }))
  pickRow(f, "glass")
  local before = errs
  O.HideSkinPicker()
  assertEqual(applied(Skin, OWNER), "obsidian", "a raising spec.get: the opened choice is back")
  assertTrue(errs > before, "the error is reported")
  O.SkinPicker(specFor(store, { get = function() return { source = "ka0s", skin = "no-such-skin" } end }))
  pickRow(f, "ember")
  f:Hide(); f:__fire("OnHide")
  assertEqual(applied(Skin, OWNER), "obsidian", "an unknown skin key: the opened choice is back")
  assertNil(store.calls)
end)

test("skin picker: the eye keeps working while a preview is pending, and keeps the preview", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local previews = 0
  local f = O.SkinPicker(specFor(store, { onPreview = function() previews = previews + 1 end }))
  pickRow(f, "ember")
  f.preview:__fire("OnClick")
  assertEqual(previews, 1)
  assertTrue(f:IsShown(), "the eye does not close the window")
  assertEqual(applied(Skin, OWNER), "ember", "the preview stays on")
  f.apply:__fire("OnClick")
  assertEqual(store.calls[1][2], "ember", "and Apply still saves it")
end)

test("skin picker: the window the eye opens, HIGH and toplevel, does not cover the picker", function()
  -- red under: the picker at HIGH, the strata of the addon's own window, and no raise after
  -- onPreview, so the toplevel main window the eye showed came up over it (PK-03).
  local m, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local main
  local f = O.SkinPicker(specFor(store, { onPreview = function()
    main = main or m.CreateFrame("Frame", "PickerHostMain", m.UIParent)
    main:SetFrameStrata("HIGH")
    main:SetToplevel(true)
    main:Show()
  end }))
  local order = {}
  local raise = rawget(f, "Raise")
  rawset(f, "Raise", function(self)
    order[#order + 1] = main and main:IsShown() and "after" or "before"
    return raise(self)
  end)
  f.preview:__fire("OnClick")
  assertTrue(main ~= nil and main:IsShown(), "the eye opened the addon's window")
  local strata = { HIGH = 4, DIALOG = 5 }
  assertTrue((strata[m.__layers(f).strata] or 0) > strata[m.__layers(main).strata],
    "the picker's strata is above the HIGH window's")
  assertEqual(order[#order], "after", "and it is raised after onPreview returns")
  local raised = m.__layers(f).raised
  O.SkinPicker(specFor(store, { onPreview = function() error("host failed") end }))
  local errs = 0
  m.geterrorhandler = function() return function() errs = errs + 1 end end
  f.preview:__fire("OnClick")
  assertEqual(errs, 1, "a raising onPreview is reported")
  assertEqual(m.__layers(f).raised, raised + 1, "and the picker is still raised")
end)

test("skin picker: showing re-raises a shown StaticPopup, so a reload popup stays above the next picker",
function()
  -- red under: a picker that did not re-raise (frame-layering-§4, a DIALOG window; PK-03).
  local m, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local popup = m.CreateFrame("Frame", "StaticPopup1", m.UIParent)
  popup:Show()
  local saved = rawget(_G, "StaticPopup1")
  _G.StaticPopup1 = popup
  local ok, err = pcall(function()
    O.SkinPicker(specFor(store))
    assertEqual(m.__layers(popup).raised, 1, "the shown popup raised once")
  end)
  _G.StaticPopup1 = saved
  if not ok then error(err, 0) end
end)

test("skin picker: in combat a pick, Apply and Apply to all write nothing and leave the window up", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local other = register(Skin, OTHER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  pickRow(f, "glass")
  lib.__combatLocked = true
  pickRow(f, "ember")
  assertEqual(applied(Skin, OWNER), "glass", "the pick in combat moved nothing")
  f.apply:__fire("OnClick")
  f.applyAll:__fire("OnClick")
  lib.__combatLocked = false
  assertNil(store.calls, "the seam was not called")
  assertNil(other.writes, "no other owner written")
  assertEqual(applied(Skin, OTHER), "ka0s")
  assertTrue(f:IsShown(), "the window stays")
  assertNil(store.closed, "not marked seen")
  f.apply:__fire("OnClick")
  assertEqual(store.calls[1][2], "glass", "out of combat Apply saves the preview made before")
end)

test("skin picker: in combat the close control still closes, putting a pending preview back unwritten",
function()
  -- Pinned as intended: the put-back is no write, so combat does not refuse it (the header's rule).
  local _, Skin, lib = env()
  local store = register(Skin, OWNER, "obsidian")
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  pickRow(f, "ember")
  lib.__combatLocked = true
  f.close:__fire("OnClick")
  lib.__combatLocked = false
  assertFalse(f:IsShown(), "the window closes")
  assertEqual(applied(Skin, OWNER), "obsidian", "back to the choice the window opened with")
  assertNil(store.calls, "no write")
  assertEqual(store.closed, 1, "onClose once")
end)

-- ── Apply to all Ka0s addons ─────────────────────────────────────────────────────────────────

test("skin picker: Apply to all is hidden while no other skin owner is registered", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  assertFalse(f.applyAll:IsShown(), "alone, no button")
  O.HideSkinPicker()
  register(Skin, OTHER)
  O.SkinPicker(specFor(store))
  assertTrue(f.applyAll:IsShown(), "another owner registered: shown on the next show")
  assertEqual(f.applyAll.text:GetText(), "Apply to all Ka0s addons")
end)

test("skin picker: Apply to all saves here and gives every other owner the source and skin alone", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local other = register(Skin, OTHER)
  local third = register(Skin, THIRD, "glass")
  Skin:SetIgnore(OTHER, true, false)
  Skin:SetOverride(OTHER, "Ka0s Expressway", nil)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  pickRow(f, "ember")
  f.applyAll:__fire("OnClick")
  assertEqual(store.calls[1][2], "ember", "this owner saved, as Apply does")
  for _, row in ipairs({ { OTHER, other }, { THIRD, third } }) do
    local name, st = row[1], row[2]
    assertEqual(applied(Skin, name), "ember", name .. ": the Skin major moved")
    local w = st.writes[#st.writes]
    assertEqual(w[1], "ka0s", name .. ": the source")
    assertEqual(w[2], "ember", name .. ": the skin, through its own registered setter")
    assertNil(w[3], name .. ": no scope half")
    assertNil(w[4], name .. ": no font or texture half")
  end
  assertEqual(select(1, Skin:GetIgnore(OTHER)), true, "the other owner's scope left alone")
  assertEqual(select(1, Skin:GetOverride(OTHER)), "Ka0s Expressway", "and its font")
  assertFalse(f:IsShown(), "the window closes")
  assertEqual(store.closed, 1)
end)

test("skin picker: Apply to all raises one reload popup naming every addon that needs it", function()
  local m, Skin, lib = env()
  local store = register(Skin, OWNER)
  register(Skin, OTHER)
  register(Skin, THIRD)
  local setChoice = Skin.SetChoice
  Skin.SetChoice = function(self, owner, src, key)
    setChoice(self, owner, src, key)
    return true, owner ~= OTHER
  end
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  pickRow(f, "ember")
  f.applyAll:__fire("OnClick")
  assertEqual(#m.popups, 1, "one popup")
  assertEqual(m.popups[1].a1, OWNER .. " Label, " .. THIRD .. " Label", "this addon, then the others that need it")
end)

test("skin picker: Apply to all dismisses every queued picker, each onClose run, none shown", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local other = register(Skin, OTHER)
  local third = register(Skin, THIRD)
  local A, B, C = instance(lib, OWNER), instance(lib, OTHER), instance(lib, THIRD)
  local f = A.SkinPicker(specFor(store))
  assertNil(B.SkinPicker(specFor(other)), "queued")
  assertNil(C.SkinPicker(specFor(third)), "queued")
  f.applyAll:__fire("OnClick")
  assertEqual(other.closed, 1, "the queued picker counts as seen")
  assertEqual(third.closed, 1)
  assertEqual(#lib.__pickerQueue.waiting, 0, "the queue is empty")
  assertNil(lib.__pickerQueue.current, "and nothing is up")
  assertEqual(applied(Skin, OTHER), "ka0s", "they got the skin this window wore: no pick, Ka0s Default")
end)

-- ── the gear ─────────────────────────────────────────────────────────────────────────────────

test("skin picker: the gear saves, opens the page itself, then the Skin tab, then closes", function()
  -- red under: O.OpenOptionsPanel() with no page (the landing page), and a gear that saved nothing.
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local calls = {}
  O.OpenOptionsPanel = function(page) calls[#calls + 1] = "open:" .. tostring(page) end
  O.SelectTab = function(page, tab) calls[#calls + 1] = "tab:" .. tostring(page) .. "/" .. tostring(tab) end
  local f = O.SkinPicker(specFor(store, { page = "general" }))
  assertEqual(f.settings.__tip, "Keep this skin and open the Skin settings")
  pickRow(f, "ember")
  f.settings:__fire("OnClick")
  assertEqual(store.calls[1][2], "ember", "the pending pick saved first")
  assertEqual(table.concat(calls, ","), "open:general,tab:general/Appearance", "the page, then the Skin tab")
  assertFalse(f:IsShown(), "and the window closes")
  assertEqual(store.closed, 1, "onClose once")
  assertEqual(applied(Skin, OWNER), "ember", "the saved pick is not put back")
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
  pickRow(f, "ember")
  lib.__combatLocked = true
  f.settings:__fire("OnClick")
  lib.__combatLocked = false
  assertEqual(own, 0, "spec.onSettings not called in combat")
  assertNil(store.calls, "nothing saved")
  assertTrue(f:IsShown(), "the window stays")
  assertNil(store.closed, "onClose did not run")
  O.SkinPicker(specFor(store))
  O.OpenOptionsPanel = function() return false end
  f.settings:__fire("OnClick")
  assertTrue(f:IsShown(), "a panel that refused to open leaves the window up")
  assertNil(store.closed)
end)

-- ── one window across addons ─────────────────────────────────────────────────────────────────

test("skin picker: two instances on one library: the second owner queues, and shows when the first closes",
function()
  -- red under: one window per instance (each addon showed its own picker at once).
  local _, Skin, lib = env()
  local storeA = register(Skin, OWNER)
  local storeB = register(Skin, OTHER)
  local A, B = instance(lib, OWNER), instance(lib, OTHER)
  local a = A.SkinPicker(specFor(storeA))
  local b, why = B.SkinPicker(specFor(storeB))
  assertNil(b, "no frame for a queued picker")
  assertEqual(why, "queued")
  assertTrue(a:IsShown(), "the first stays up")
  assertEqual(#lib.__pickerQueue.waiting, 1)
  local refreshed = specFor(storeB, { strings = { TITLE = "Second" } })
  assertNil(B.SkinPicker(refreshed), "a repeat call")
  assertEqual(#lib.__pickerQueue.waiting, 1, "one entry per owner")
  assertNil(storeB.closed, "a queued picker is not closed")
  a.close:__fire("OnClick")
  assertEqual(storeA.closed, 1)
  local q = lib.__pickerQueue
  assertTrue(q.current ~= nil and q.current.owner == OTHER, "the second owner's picker is up")
  b = q.current.frame
  assertTrue(b:IsShown() and b ~= a, "its own window")
  assertEqual(b.title:GetText(), "Second", "with the spec the repeat call gave")
  assertEqual(b.ownerLabel:GetText(), OTHER .. " Label")
  b.apply:__fire("OnClick")
  assertEqual(storeB.closed, 1)
  assertNil(q.current, "nothing left to show")
end)

test("skin picker: a queued owner waits out combat and shows when it ends", function()
  -- red under: advance() showing the next owner at once, mid-combat (PK-03).
  local m, Skin, lib = env()
  local storeA = register(Skin, OWNER)
  local storeB = register(Skin, OTHER)
  local storeC = register(Skin, THIRD)
  local A, B, C = instance(lib, OWNER), instance(lib, OTHER), instance(lib, THIRD)
  local a = A.SkinPicker(specFor(storeA))
  assertNil(B.SkinPicker(specFor(storeB)), "queued")
  m.InCombatLockdown = function() return true end
  a.close:__fire("OnClick")
  assertEqual(storeA.closed, 1, "the close still closes in combat")
  local q = lib.__pickerQueue
  assertNil(q.current, "nothing shown mid-combat")
  assertEqual(#q.waiting, 1, "the next owner stays queued")
  assertEqual(q.waiting[1].owner, OTHER)
  assertNil(storeB.closed)
  local c, why = C.SkinPicker(specFor(storeC))
  assertNil(c, "a call while the queue waits out combat queues behind it")
  assertEqual(why, "queued")
  assertEqual(#q.waiting, 2)
  m.InCombatLockdown = function() return false end
  assertTrue(lib.__parkFrame ~= nil, "parked on the library's end-of-combat park")
  lib.__parkFrame:__fire("OnEvent", "PLAYER_REGEN_ENABLED")
  assertTrue(q.current ~= nil and q.current.owner == OTHER, "the first queued shows when combat ends")
  assertTrue(q.current.frame:IsShown())
  assertEqual(#q.waiting, 1, "the other still waits behind it")
  q.current.frame.apply:__fire("OnClick")
  assertEqual(q.current.owner, THIRD, "out of combat the queue advances at once")
end)

test("skin picker: a queue dismissed while waiting out combat shows nothing when combat ends", function()
  local m, Skin, lib = env()
  local storeA = register(Skin, OWNER)
  local storeB = register(Skin, OTHER)
  local A, B = instance(lib, OWNER), instance(lib, OTHER)
  local a = A.SkinPicker(specFor(storeA))
  B.SkinPicker(specFor(storeB))
  m.InCombatLockdown = function() return true end
  a.close:__fire("OnClick")
  B.HideSkinPicker()
  m.InCombatLockdown = function() return false end
  lib.__parkFrame:__fire("OnEvent", "PLAYER_REGEN_ENABLED")
  assertNil(lib.__pickerQueue.current, "nothing to show")
  assertNil(storeB.closed, "never seen")
  assertTrue(A.SkinPicker(specFor(storeA)) ~= nil, "a later call shows at once: the park let go")
end)

test("skin picker: a queued owner is shown after Apply and after the gear, too", function()
  local _, Skin, lib = env()
  local storeA = register(Skin, OWNER)
  local storeB = register(Skin, OTHER)
  local storeC = register(Skin, THIRD)
  local A, B, C = instance(lib, OWNER), instance(lib, OTHER), instance(lib, THIRD)
  local a = A.SkinPicker(specFor(storeA))
  B.SkinPicker(specFor(storeB))
  C.SkinPicker(specFor(storeC, { onSettings = function() end }))
  a.apply:__fire("OnClick")
  local q = lib.__pickerQueue
  assertEqual(q.current.owner, OTHER, "queue order: the first queued")
  q.current.frame.settings:__fire("OnClick")
  assertEqual(storeB.closed, 1, "the gear closed it")
  assertEqual(q.current.owner, THIRD, "then the next")
end)

test("skin picker: HideSkinPicker takes a queued owner out unseen, and a shown one down with onClose", function()
  local _, Skin, lib = env()
  local storeA = register(Skin, OWNER)
  local storeB = register(Skin, OTHER)
  local A, B = instance(lib, OWNER), instance(lib, OTHER)
  local a = A.SkinPicker(specFor(storeA))
  B.SkinPicker(specFor(storeB))
  B.HideSkinPicker()
  assertEqual(#lib.__pickerQueue.waiting, 0, "out of the queue")
  assertNil(storeB.closed, "no onClose: it was never seen")
  assertTrue(a:IsShown(), "the shown one is not B's to hide")
  B.SkinPicker(specFor(storeB))
  A.HideSkinPicker()
  assertEqual(storeA.closed, 1, "the shown one closes, onClose as for any close")
  assertEqual(lib.__pickerQueue.current.owner, OTHER, "and the next shows")
end)

test("skin picker: one instance's second owner queues behind its first, each refreshed only by its own",
function()
  -- red under: minor 1, which hid the first owner's window (running its onClose) to show the second.
  local _, Skin, lib = env()
  local storeA = register(Skin, OWNER)
  local storeB = register(Skin, "Other")
  local O = instance(lib, OWNER)
  local a = O.SkinPicker(specFor(storeA))
  assertNil(O.SkinPicker(specFor(storeB, { owner = "Other" })), "queued")
  assertTrue(a:IsShown(), "the first stays up")
  assertNil(storeA.closed)
  O.SkinPicker(specFor(storeA))   -- the first owner again: still its window, nothing queued for it
  a.close:__fire("OnClick")
  local b = lib.__pickerQueue.current.frame
  assertTrue(a ~= b and b:IsShown(), "the other owner's own window")
  assertEqual(storeA.closed, 1, "closed once")
  a:__fire("OnHide")
  assertTrue(b:IsShown(), "a late OnHide of the first window does not close the second")
  assertNil(storeB.closed)
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(b.dd.text:GetText(), Skin:GetSkin("ka0s").label, "the first owner's switch leaves the second alone")
  storeB.skin = "ember"
  Skin:SetChoice("Other", "ka0s", "ember")
  assertEqual(b.dd.text:GetText(), Skin:GetSkin("ember").label, "its own owner's switch refreshes it")
  storeA.skin = "obsidian"
  assertNil(O.SkinPicker(specFor(storeA)), "the first owner queued behind the second")
  b.close:__fire("OnClick")
  assertTrue(lib.__pickerQueue.current.frame == a, "the first owner's window again, reused")
  assertEqual(a.dd.text:GetText(), Skin:GetSkin("obsidian").label, "refreshed on show")
end)

test("skin picker: with the client's own OnHide, one instance's first owner closing leaves the second up",
function()
  -- red under: hide()'s close read the instance's current picker after the synchronous OnHide had
  -- already closed the first and shown the second, so it closed the second too (its onClose run, its
  -- window left on screen as a picker nobody owned, the queue emptied).
  local m, Skin, lib = env()
  armClientHide(m)
  local storeA = register(Skin, OWNER)
  local storeB = register(Skin, "Other")
  local O = instance(lib, OWNER)
  local a = O.SkinPicker(specFor(storeA))
  assertNil(O.SkinPicker(specFor(storeB, { owner = "Other" })), "queued")
  a.close:__fire("OnClick")
  assertEqual(storeA.closed, 1, "the first closed once")
  local q = lib.__pickerQueue
  assertTrue(q.current ~= nil and q.current.owner == "Other", "the second is the picker up")
  local b = q.current.frame
  assertTrue(b ~= a and b:IsShown(), "its own window, shown")
  assertNil(storeB.closed, "the second's onClose has not run")
  pickRow(b, "ember")
  assertEqual(applied(Skin, "Other"), "ember", "the second still previews")
  assertNil(O.SkinPicker(specFor(storeA)), "the first queued behind it")
  b.apply:__fire("OnClick")
  assertEqual(storeB.calls[1][2], "ember", "Apply saved the second's pick")
  assertEqual(storeB.closed, 1, "the second closed once")
  assertTrue(q.current ~= nil and q.current.frame == a and a:IsShown(), "the first shows again")
  assertNil(storeA.calls, "the first's write seam untouched")
  assertEqual(storeA.closed, 1, "and its onClose not run by the second's Apply")
  O.HideSkinPicker()
  assertEqual(storeA.closed, 2, "HideSkinPicker closes it once")
  assertNil(q.current, "nothing left up")
end)

test("skin picker: with the client's own OnHide, onClose still runs once per showing, by every route",
function()
  local m, Skin, lib = env()
  armClientHide(m)
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  f.close:__fire("OnClick")
  assertEqual(store.closed, 1, "the close control")
  O.SkinPicker(specFor(store))
  f.apply:__fire("OnClick")
  assertEqual(store.closed, 2, "Apply")
  O.SkinPicker(specFor(store, { onSettings = function() end }))
  f.settings:__fire("OnClick")
  assertEqual(store.closed, 3, "the gear")
  O.SkinPicker(specFor(store))
  O.HideSkinPicker()
  assertEqual(store.closed, 4, "HideSkinPicker")
  O.SkinPicker(specFor(store))
  f:Hide()
  assertEqual(store.closed, 5, "Escape")
  assertNil(lib.__pickerQueue.current)
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
  O.SkinPicker(specFor(store))
  f.apply:__fire("OnClick")
  assertEqual(store.closed, 4, "and Apply")
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

test("skin picker: spec.strings translates the title, the buttons, the tips and a skin's name", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  register(Skin, OTHER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store, { strings = {
    TITLE = "Skin waehlen", SETTINGS_TIP = "Einstellungen", SKIN_ka0s = "Ka0s (de)",
    APPLY = "Anwenden", APPLY_ALL = "Allen geben", APPLY_TIP = "Behalten" } }))
  assertEqual(f.title:GetText(), "Skin waehlen")
  assertEqual(f.ownerLabel:GetText(), OWNER .. " Label", "the label is the owner's, not a word")
  assertEqual(f.settings.__tip, "Einstellungen")
  assertEqual(f.dd.text:GetText(), "Ka0s (de)")
  assertEqual(f.apply.text:GetText(), "Anwenden")
  assertEqual(f.apply.__tip, "Behalten")
  assertEqual(f.applyAll.text:GetText(), "Allen geben")
  assertEqual(lib.SKIN_PICKER_STRINGS.TITLE, "Choose a skin", "the library's words are not written through")
  O.HideSkinPicker()
  O.SkinPicker(specFor(store, { strings = { TITLE = "100% %d" } }))
  assertEqual(f.title:GetText(), "100% %d", "a title is shown verbatim, never formatted")
end)

test("skin picker: nil with no Skin major, or for an owner that never registered", function()
  local _, _, lib = env({ noSkin = true })
  assertNil(instance(lib, OWNER).SkinPicker({}), "no Skin major")
  local _, Skin2, lib2 = env()
  assertNil(instance(lib2, OWNER).SkinPicker({}), "not registered")
  register(Skin2, "Other")
  assertTrue(instance(lib2, OWNER).SkinPicker({ owner = "Other" }) ~= nil, "spec.owner names the owner")
  instance(lib2, OWNER).HideSkinPicker()   -- nothing shown on this instance: a no-op
  assertEqual(lib2.__pickerQueue.current.owner, "Other", "the other instance's window stays up")
end)
