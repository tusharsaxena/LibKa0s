-- tests/fixture_appearance.lua -- the bench the two Appearance tab suites share:
-- tests/test_options_appearance.lua and tests/test_options_appearance_overrides.lua. Moved out of the
-- first, unchanged, when the second was split off (FX-LK-SIZE of Ka0sAddonsCommonTasks
-- docs/2026-10-31-FINDINGS_REMEDIATION).
--
-- Loaded as `dofile("tests/fixture_appearance.lua")`. Every env() is a fresh client.

local F = dofile("tests/fixture_skin_paint.lua")
local E = dofile("tests/fixture_skin_eui.lua")
local Loader = dofile("tests/_kit/loader.lua")

local OWNER, OTHER, THIRD = "LootHistory", "BankLedger", "KickCD"
local SKIN_FILES = { "Skin", "SkinOwnerTokens", "SkinDefs", "SkinDefsOthers", "SkinPaint", "SkinPaintExtras", "SkinPaintControls", "SkinEUI" }
local OPTIONS = { "Options", "OptionsRegistry", "OptionsWidgets", "OptionsFlow", "OptionsIds", "OptionsIdSuggest", "OptionsIdList", "OptionsTabs", "OptionsTabbed",
                  "OptionsCombat", "OptionsCompose", "OptionsScroll", "OptionsNav", "OptionsDrawer",
                  "OptionsKeybinds", "OptionsAppearance" }
local ELLIPSIS = "\226\128\166"

--- A fresh client. `spec.eui` installs the EllesmereUI fake first (its fields are
--- tests/fixture_skin_eui.lua's); `spec.noSkin` loads no Skin major. Every AceGUI CheckBox answers
--- SetDescription, as AceGUI's does, and every StaticPopup_Show is recorded in `m.popups`.
--- Answers m, Skin, the Options major, eui.
local function env(spec)
  spec = spec or {}
  local m = F.env({ files = { "Core" }, lsm = spec.lsm })
  local eui = spec.eui and E.install(m, spec.eui) or nil
  local files = {}
  if not spec.noSkin then
    for _, f in ipairs(SKIN_FILES) do files[#files + 1] = f end
  end
  files[#files + 1] = "Pool"
  for _, f in ipairs(OPTIONS) do files[#files + 1] = f end
  for _, f in ipairs(files) do Loader.load("LibKa0s/" .. f .. ".lua", nil, m) end
  local ace = m.__libs["AceGUI-3.0"]
  local create = ace.Create
  ace.Create = function(self, wtype)
    local w = create(self, wtype)
    if wtype == "CheckBox" then
      function w:SetDescription(v) self.desc = v; return self end
    end
    return w
  end
  m.popups = {}
  m.StaticPopup_Show = function(which, a1, a2, data)
    m.popups[#m.popups + 1] = { which = which, a1 = a1, a2 = a2, data = data,
                                dialog = m.StaticPopupDialogs[which] }
  end
  return m, m.LibStub("LibKa0s-Skin-1.0", true), m.LibStub("LibKa0s-Options-1.0"), eui
end

--- Register `owner` with a profile store; answers the store ({ source, skin, writes }).
local function register(Skin, owner, source, skin)
  local store = { source = source or "ka0s", skin = skin or "ka0s", writes = 0 }
  Skin:RegisterOwner(owner, {
    label = owner .. " Label",
    get = function() return { source = store.source, skin = store.skin } end,
    set = function(src, sk, ig, media)
      store.source, store.skin, store.writes, store.ignore, store.media = src, sk, store.writes + 1, ig, media
    end,
  })
  return store
end

local seq = 0
--- An Options instance for a host named `owner`, and a page of it.
local function page(lib, owner)
  seq = seq + 1
  local O = lib:New({
    parentTitle = "Appearance Host", mainPanelName = "AppearanceMain" .. seq, addonName = owner,
    print = function() end,
    get = function() end, set = function() end, applyDefault = function() end,
    rowsForPage = function()
      return { { path = "alpha", page = "general", group = "Alpha", order = 10, type = "bool", label = "A" } }
    end,
    allRows = function() return {} end,
  })
  local ctx = O.CreatePanel("AppearancePage" .. seq, "Appearance page", { pageKey = "general" })
  return O, ctx
end

--- The tab's spec over `store`: the owner's read, and its write seam counting each call.
local function specFor(store, extra)
  local spec = {
    get = function() return { source = store.source, skin = store.skin } end,
    set = function(src, sk, ig, media)
      store.seamCalls = (store.seamCalls or 0) + 1
      if src ~= nil then store.source = src end
      if sk ~= nil then store.skin = sk end
      if ig ~= nil then store.ignore = ig end
      if media ~= nil then store.media = media end
    end,
  }
  for k, v in pairs(extra or {}) do spec[k] = v end
  return spec
end

--- Every widget under `w`, depth first.
local function flatten(w, out)
  out = out or {}
  for _, c in ipairs(w.children or {}) do
    out[#out + 1] = c
    flatten(c, out)
  end
  return out
end

--- The texts of every widget the page drew.
local function texts(ctx)
  local out = {}
  for _, w in ipairs(flatten(ctx.scroll)) do
    if type(w.text) == "string" then out[#out + 1] = w.text end
    if type(w.labelText) == "string" then out[#out + 1] = w.labelText end
  end
  return out
end

local function hasText(ctx, needle)
  for _, t in ipairs(texts(ctx)) do
    if t:find(needle, 1, true) then return true end
  end
  return false
end

local MEDIA_LSM = { ["font:Ka0s Expressway"] = "Fonts\\Expressway.ttf", ["font:Arial Narrow"] = "Fonts\\ARIALN.ttf",
                    ["statusbar:Ka0s Flat"] = "Interface\\Ka0s\\Flat", ["statusbar:Blizzard"] = "Interface\\Bar" }

--- A client whose LibSharedMedia also lists its keys (the fixture's fake fetches only).
local function mediaEnv()
  local m, Skin, lib = env({ lsm = MEDIA_LSM })
  local LSM = m.LibStub("LibSharedMedia-3.0")
  LSM.List = function(_, kind)
    local out = {}
    for k in pairs(MEDIA_LSM) do
      local kk, key = k:match("^(%w+):(.+)$")
      if kk == kind then out[#out + 1] = key end
    end
    return out
  end
  return m, Skin, lib
end

local function indexOf(list, w)
  for i, x in ipairs(list) do if x == w then return i end end
  return nil
end

return {
  OWNER = OWNER, OTHER = OTHER, THIRD = THIRD, ELLIPSIS = ELLIPSIS,
  env = env, register = register, page = page, specFor = specFor,
  flatten = flatten, texts = texts, hasText = hasText, mediaEnv = mediaEnv, indexOf = indexOf,
}
