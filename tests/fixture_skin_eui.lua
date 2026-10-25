-- tests/fixture_skin_eui.lua — the bench tests/test_skin_eui.lua runs on: the Skin major loaded
-- whole (SkinEUI.lua included) on tests/fixture_skin_paint.lua's paint-recorder environment, and a
-- headless EllesmereUI fake.
--
-- THE FAKE models EllesmereUI's skinning API as its SKINNING_API.md describes it (API version 3) and
-- as PremadeGroupsFilterExtension's test fake models it: written here from that description, never
-- from EllesmereUI's code. `RegisterSkin(name, fn)` queues (first registration of a name wins); the
-- dispatcher, which lives in the EllesmereUIBlizzardSkin child, fires each queued entry ONCE, and
-- only while the master switch (`EllesmereUIDB.thirdPartySkinsOff`) and that entry
-- (`thirdPartySkinAddons[name]`, nil = on) are on; after the login dispatch a new registration
-- fires at once. The facade RECORDS every primitive call, so a case asks what EllesmereUI painted.
--
--   spec.child = false   EllesmereUIBlizzardSkin not loaded (RegisterSkin only queues)
--   spec.masterOff       EllesmereUIDB.thirdPartySkinsOff = true
--   spec.entries         EllesmereUIDB.thirdPartySkinAddons
--   spec.omit            facade members left out (an EllesmereUI whose facade changed shape)
--   spec.raise           one primitive that records its call, then raises
--
-- Handle: { registry, order, fired, calls, looks, accent, panel, font, dispatch(name),
-- dispatchAll(), login(), callsFor(fn, target), count(fn) }.

local F = dofile("tests/fixture_skin_paint.lua")

local E = {}

E.OWNER = "LootHistory"
E.FILES = { "Core", "Skin", "SkinDefs", "SkinPaint", "SkinPaintExtras", "SkinPaintControls", "SkinEUI" }

local PRIMITIVES = { "Shell", "Panel", "Inset", "FadeRegions", "FadeNineSlice", "Button",
  "WhiteButtonLabel", "StateButtonLabel", "EditBox", "Checkbox", "Dropdown", "ScrollBar", "Tab",
  "SetTabSelection", "CloseButton", "PageButton", "SquareIcon", "SortHeaderBar", "Font", "White",
  "ApplyBarFill" }

local function makeFacade(m, eui, name, spec)
  local S = { apiVersion = 3 }
  for _, fname in ipairs(PRIMITIVES) do
    S[fname] = function(target, ...)
      eui.calls[#eui.calls + 1] = { fn = fname, target = target, n = select("#", ...), args = { ... },
                                    skin = name }
    end
  end
  S.GetAccentColor = function() local a = eui.accent; return a[1], a[2], a[3] end
  S.GetPanelColor = function() local p = eui.panel; return p[1], p[2], p[3], p[4] end
  S.GetFont = function() return eui.font, "" end
  S.GetStyle = function() return "eui" end
  S.OnLooksChanged = function(fn) eui.looks[#eui.looks + 1] = fn end
  S.IsEnabled = function() return eui.on(name) end
  if spec.raise then
    local record = S[spec.raise]
    S[spec.raise] = function(...)
      record(...)
      error("EllesmereUI fake: " .. spec.raise .. " raised")
    end
  end
  for _, fname in ipairs(spec.omit or {}) do S[fname] = nil end
  m.__euiFacades = m.__euiFacades or {}
  m.__euiFacades[name] = S
  return S
end

--- Install the fake on `m` (before or after the payload loads). Answers its handle, also `m.eui`.
function E.install(m, spec)
  spec = spec or {}
  local eui = { registry = {}, order = {}, fired = {}, calls = {}, looks = {},
                accent = { 0.05, 0.8, 0.6 }, panel = { 0.1, 0.1, 0.1, 0.95 }, font = "Fonts\\EUI.ttf" }
  m.eui = eui
  m.loadedAddons = { EllesmereUI = true, EllesmereUIBlizzardSkin = spec.child ~= false }
  m.C_AddOns = m.C_AddOns or {}
  m.C_AddOns.IsAddOnLoaded = function(name)
    local on = m.loadedAddons[name] == true
    return on, on
  end
  m.EllesmereUIDB = { thirdPartySkinsOff = spec.masterOff and true or nil,
                      thirdPartySkinAddons = spec.entries or {} }
  function eui.on(name)
    local d = m.EllesmereUIDB
    local t = d and d.thirdPartySkinAddons
    return not (d and d.thirdPartySkinsOff) and not (t and t[name] == false)
  end
  function eui.dispatch(name)
    local fn = eui.registry[name]
    if not fn or eui.fired[name] or not eui.on(name) then return false end
    if m.loadedAddons.EllesmereUIBlizzardSkin ~= true then return false end
    eui.fired[name] = true
    fn(makeFacade(m, eui, name, spec))
    return true
  end
  function eui.dispatchAll()
    local any = false
    for _, name in ipairs(eui.order) do any = eui.dispatch(name) or any end
    return any
  end
  --- PLAYER_LOGIN on EllesmereUI's side: dispatch the queue; later registrations fire at once.
  function eui.login()
    eui.loggedIn = true
    return eui.dispatchAll()
  end
  function eui.callsFor(fname, target)
    local out = {}
    for _, c in ipairs(eui.calls) do
      if (fname == nil or c.fn == fname) and (target == nil or c.target == target) then out[#out + 1] = c end
    end
    return out
  end
  function eui.count(fname) return #eui.callsFor(fname) end
  m.EllesmereUI = {
    RegisterSkin = function(name, fn)
      if type(name) ~= "string" or type(fn) ~= "function" or eui.registry[name] then return end
      eui.registry[name] = fn
      eui.order[#eui.order + 1] = name
      if eui.loggedIn then eui.dispatch(name) end
    end,
  }
  return eui
end

--- A fresh environment: the paint recorder, the whole Skin major, and (unless `spec.noEUI`) the
--- EllesmereUI fake installed first. Answers m, Skin, eui.
function E.env(spec)
  spec = spec or {}
  local m = F.env({ files = { "Core" } })
  local eui = not spec.noEUI and E.install(m, spec) or nil
  local Loader = dofile("tests/_kit/loader.lua")
  for i = 2, #E.FILES do Loader.load("LibKa0s/" .. E.FILES[i] .. ".lua", nil, m) end
  return m, m.LibStub(F.MAJOR, true), eui
end

--- Register `owner` on (source, skin), logging into `log` (an array) when given. Answers its facade.
function E.owner(Skin, owner, source, skin, log)
  return Skin:RegisterOwner(owner, {
    get = function() return source or "ka0s", skin or "ka0s" end,
    label = owner,
    log = log and function(line) log[#log + 1] = line end or nil,
  })
end

--- A window (tests/fixture_skin_paint.lua's) with a button on it.
function E.window(m)
  local f = F.window(m)
  f.btn = m.CreateFrame("Button", nil, f, "BackdropTemplate")
  return f
end

E.F = F
return E
