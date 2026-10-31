-- tests/fixture_skin_picker.lua -- the bench the skin picker suites share:
-- tests/test_options_skin_picker.lua (the window, the picks),
-- tests/test_options_skin_picker_shared.lua (one window across addons, the queue) and
-- tests/test_options_skin_verb.lua (O.SkinVerb, the `/xx skin` act; LK-11 of Ka0sAddonsCommonTasks
-- docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK). Moved out of the first, unchanged, when the second was
-- written, so the two cannot drift: one copy rather than two, for the reason
-- tests/fixture_widgets.lua gives.
--
-- Loaded as `dofile("tests/fixture_skin_picker.lua")`. Every env() is a fresh client.

local F = dofile("tests/fixture_skin_paint.lua")
local Loader = dofile("tests/_kit/loader.lua")

local OWNER, OTHER, THIRD = "LootHistory", "BankLedger", "KickCD"
local SKIN_FILES = { "Skin", "SkinOwnerTokens", "SkinDefs", "SkinDefsOthers", "SkinPaint", "SkinPaintExtras", "SkinPaintControls", "SkinEUI" }
local OPTIONS = { "Options", "OptionsRegistry", "OptionsWidgets", "OptionsIds", "OptionsIdList", "OptionsTabs",
                  "OptionsCombat", "OptionsCompose", "OptionsScroll", "OptionsNav", "OptionsDrawer",
                  "OptionsKeybinds", "OptionsAppearance", "OptionsSkinPicker", "OptionsSkinPickerRows", "OptionsSwitch", "OptionsMedia" }
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
--- An Options instance for a host named `owner`; `extra` descriptor fields (a `print` that records,
--- a `debug`) are laid over the bench's.
local function instance(lib, owner, extra)
  seq = seq + 1
  local d = {
    parentTitle = "Picker Host", mainPanelName = "PickerMain" .. seq, addonName = owner,
    print = function() end,
    get = function() end, set = function() end, applyDefault = function() end,
    rowsForPage = function() return {} end, allRows = function() return {} end,
  }
  for k, v in pairs(extra or {}) do d[k] = v end
  return lib:New(d)
end

--- The picker's spec over `store`: its read, and a write seam that records each call.
local function specFor(store, extra)
  local spec = {
    get = function() return { source = store.source, skin = store.skin } end,
    set = function(src, sk, ig, media)
      store.calls = store.calls or {}
      store.calls[#store.calls + 1] = { src, sk, ig, media }
      if src ~= nil then store.source = src end
      if sk ~= nil then store.skin = sk end
      if media ~= nil then store.media = media end
    end,
    onClose = function() store.closed = (store.closed or 0) + 1 end,
  }
  for k, v in pairs(extra or {}) do spec[k] = v end
  return spec
end

--- Open the window's list and click the row for skin `key`.
local function pickRow(f, key)
  f.dd:__fire("OnClick")
  for _, r in ipairs({ f.list:GetChildren() }) do
    if r.key == key then r:__fire("OnClick") end
  end
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

local function applied(Skin, owner)
  return select(2, Skin:GetChoice(owner))
end

return {
  OWNER = OWNER, OTHER = OTHER, THIRD = THIRD, OPTIONS = OPTIONS, LSM = LSM,
  armGeometry = armGeometry, env = env, register = register, instance = instance, specFor = specFor,
  pickRow = pickRow, armClientHide = armClientHide, applied = applied,
}
