-- tests/test_options_appearance.lua -- LibKa0s-Options-1.0's Appearance tab (OptionsAppearance.lua
-- minor 1, skinning-§3; LK-10 of Ka0sAddonsCommonTasks docs/2026-10-25-SKINNING): O.AppearanceTab,
-- O.AppearanceRows and lib.APPEARANCE_STRINGS, with the Skin major's two members the tab writes
-- through (Skin minor 4: OwnerLabel and WriteChoice).
--
-- What it pins: the tab entry (key, label, tooltip, its default place immediately before the
-- Keybindings tab, and the overrides); the rows (the two source choices, the EllesmereUI gate's four
-- conditions with a check or a cross and their fixes, one choice per registered skin with its four
-- swatches, name and description, the copy button and the fixed note); a skin pick moving the Skin
-- major first and then writing through the owner's seam, and repainting the owner's frames live;
-- copy to every Ka0s addon, disabled with its hint while no other owner is loaded, and otherwise a
-- confirmation naming the other owners that writes each one through its own registered setter; the
-- EllesmereUI choice disabled while the gate is closed; the one reload popup on leaving an
-- EllesmereUI that painted; spec.strings translating every string, the skins' names included; a
-- page drawn disabled; a page whose owner never registered.
--
-- Every case runs on a fresh client (the paint recorder, Core, Pool, the whole Skin major and every
-- Options file), so the owners one case registers never reach another.

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  K.test, K.assertEqual, K.assertTrue, K.assertFalse, K.assertNil
local F = dofile("tests/fixture_skin_paint.lua")
local E = dofile("tests/fixture_skin_eui.lua")
local Loader = dofile("tests/_kit/loader.lua")

local OWNER, OTHER, THIRD = "LootHistory", "BankLedger", "KickCD"
local SKIN_FILES = { "Skin", "SkinDefs", "SkinPaint", "SkinPaintExtras", "SkinPaintControls", "SkinEUI" }
local OPTIONS = { "Options", "OptionsRegistry", "OptionsWidgets", "OptionsIds", "OptionsIdList", "OptionsTabs",
                  "OptionsCombat", "OptionsCompose", "OptionsScroll", "OptionsNav", "OptionsDrawer",
                  "OptionsKeybinds", "OptionsAppearance" }
local ELLIPSIS = "\226\128\166"

--- A fresh client. `spec.eui` installs the EllesmereUI fake first (its fields are
--- tests/fixture_skin_eui.lua's); `spec.noSkin` loads no Skin major. Every AceGUI CheckBox answers
--- SetDescription, as AceGUI's does, and every StaticPopup_Show is recorded in `m.popups`.
--- Answers m, Skin, the Options major, eui.
local function env(spec)
  spec = spec or {}
  local m = F.env({ files = { "Core" } })
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
    set = function(src, sk) store.source, store.skin, store.writes = src, sk, store.writes + 1 end,
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
    set = function(src, sk)
      store.seamCalls = (store.seamCalls or 0) + 1
      store.source, store.skin = src, sk
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

-- ── the members ──────────────────────────────────────────────────────────────────────────────

test("appearance: OptionsAppearance is at minor 1 or later and attaches the two members", function()
  local _, _, lib = env()
  assertTrue((lib.MODULES.OptionsAppearance or 0) >= 1, "OptionsAppearance minor")
  assertEqual(lib.__appearanceMinor, lib.MODULES.OptionsAppearance)
  assertEqual(lib.__appearanceShellMinor, lib.MINOR, "paired on the shell's minor")
  assertEqual(type(lib.APPEARANCE_STRINGS), "table")
  local O = page(lib, OWNER)
  assertEqual(type(O.AppearanceTab), "function")
  assertEqual(type(O.AppearanceRows), "function")
end)

test("appearance: the Skin major answers an owner's label and writes through its setter", function()
  local _, Skin = env()
  local store = register(Skin, OWNER)
  assertEqual(Skin:OwnerLabel(OWNER), OWNER .. " Label")
  assertNil(Skin:OwnerLabel("NotAnOwner"), "an unregistered owner has no label")
  assertTrue(Skin:WriteChoice(OWNER, "ka0s", "ember"), "the setter ran")
  assertEqual(store.skin, "ember")
  assertEqual(store.writes, 1)
  assertEqual(select(2, Skin:GetChoice(OWNER)), "ka0s", "WriteChoice never moves the applied choice")
  assertFalse(Skin:WriteChoice("NotAnOwner", "ka0s", "ember"), "no owner, no write")
  Skin:RegisterOwner(THIRD, { set = function() error("seam raised") end })
  assertFalse(Skin:WriteChoice(THIRD, "ka0s", "glass"), "a raising setter answers false, and raises nothing")
  Skin:RegisterOwner("NoSetter", {})
  assertFalse(Skin:WriteChoice("NoSetter", "ka0s", "glass"), "an owner with no setter answers false")
end)

-- ── the tab entry ────────────────────────────────────────────────────────────────────────────

test("appearance: AppearanceTab's defaults", function()
  local _, _, lib = env()
  local O = page(lib, OWNER)
  local tab = O.AppearanceTab({})
  assertEqual(tab.key, "Appearance")
  assertEqual(tab.label, "Appearance")
  assertEqual(tab.tooltip, lib.APPEARANCE_STRINGS.TAB_TIP)
  assertEqual(tab.before, "Keybindings", "immediately before the Keybindings tab (skinning-§3)")
  assertEqual(type(tab.render), "function")
end)

test("appearance: spec.key, spec.before and spec.strings override", function()
  local _, _, lib = env()
  local O = page(lib, OWNER)
  local tab = O.AppearanceTab({ key = "Look", before = "Keys", strings = { TAB_LABEL = "Aussehen", TAB_TIP = "T" } })
  assertEqual(tab.key, "Look")
  assertEqual(tab.label, "Aussehen")
  assertEqual(tab.tooltip, "T")
  assertEqual(tab.before, "Keys")
  assertNil(O.AppearanceTab({ before = false }).before, "before = false puts it last")
  assertEqual(lib.APPEARANCE_STRINGS.TAB_LABEL, "Appearance", "the library's words are not written through")
end)

test("appearance: RenderTabbedSchema puts it immediately before Keybindings, and its render draws rows",
function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  local opts = { tabs = { O.KeybindingsTab({ bindings = {} }), O.AppearanceTab(specFor(store)) } }
  local _, keys = O.RenderTabbedSchema(ctx, "general", nil, nil, opts)
  assertEqual(table.concat(keys, "|"), "Alpha|Appearance|Keybindings")
  O.ClearScroll(ctx)
  ctx.activeTab = "Appearance"
  O.RenderTabbedSchema(ctx, "general", nil, nil, opts)
  assertTrue(hasText(ctx, "Ka0s skins"), "the tab's render drew the source choice")
end)

-- ── the rows ─────────────────────────────────────────────────────────────────────────────────

test("appearance: the rows draw both sources, one choice per skin with swatches, the copy button and the note",
function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  assertTrue(view ~= nil, "a view")
  assertEqual(view.source.ka0s.checkType, "radio")
  assertEqual(view.source.ka0s.value, true, "Ka0s skins is the stored source")
  assertEqual(view.source.eui.value, false)
  local skins = Skin:Skins()
  assertEqual(#view.order, #skins, "one choice per registered skin")
  assertEqual(#skins, 9)
  for i, def in ipairs(skins) do
    local cb = view.skins[def.key]
    assertEqual(view.order[i], def.key, "in registration order")
    assertTrue(cb.labelText:find(def.label, 1, true) ~= nil, def.key .. "'s name")
    local _, n = cb.labelText:gsub("|TInterface\\Buttons\\WHITE8X8:", "")
    assertEqual(n, 4, def.key .. "'s four swatches")
    assertEqual(cb.desc, def.desc, def.key .. "'s description")
    assertEqual(cb.value, def.key == "ka0s", def.key .. " checked only when stored")
  end
  assertEqual(view.copy.text, "Copy to every Ka0s addon" .. ELLIPSIS, "options-ui-§21's ellipsis")
  assertTrue(hasText(ctx, lib.APPEARANCE_STRINGS.NOTE), "the fixed note")
  assertTrue(hasText(ctx, "Skin source"), "the source heading")
end)

test("appearance: a skin pick moves the Skin major, then writes through the seam, and repaints live", function()
  local m, Skin, lib = env()
  local store = register(Skin, OWNER)
  local frame = F.window(m)
  local S = Skin:For(OWNER)
  S.Shell(frame)
  local O, ctx = page(lib, OWNER)
  local order = {}
  local spec = specFor(store)
  local seam = spec.set
  spec.set = function(src, sk)
    order[#order + 1] = "set:" .. select(2, Skin:GetChoice(OWNER))
    seam(src, sk)
  end
  local view = O.AppearanceRows(ctx, spec)
  view.skins.obsidian:__fire("OnValueChanged", true)
  assertEqual(order[1], "set:obsidian", "SetChoice ran before the owner's write seam")
  assertEqual(store.seamCalls, 1, "one write through spec.set")
  assertEqual(store.source, "ka0s")
  assertEqual(store.skin, "obsidian")
  assertEqual(F.rgba(m.__paint(frame.title).textColor), F.tok(Skin, "obsidian", "title.text"),
    "the owner's window repainted with no reload")
  assertEqual(view.skins.obsidian.value, true, "the pick is checked")
  assertEqual(view.skins.ka0s.value, false, "and the old one cleared")
  assertEqual(#m.popups, 0, "no popup for a Ka0s skin switch")
end)

test("appearance: a pick never reaches another owner, and clicking the checked skin keeps it", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local other = register(Skin, OTHER, "ka0s", "glass")
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  view.skins.ember:__fire("OnValueChanged", true)
  assertEqual(select(2, Skin:GetChoice(OTHER)), "glass", "the other owner keeps its skin")
  assertEqual(other.writes, 0, "and its profile is not written")
  view.skins.ember:__fire("OnValueChanged", false)
  assertEqual(view.skins.ember.value, true, "a radio clicked off snaps back on")
  assertEqual(select(2, Skin:GetChoice(OWNER)), "ember")
end)

-- ── copy to every Ka0s addon ─────────────────────────────────────────────────────────────────

test("appearance: copy is disabled with its hint while no other owner is loaded", function()
  local m, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  assertTrue(view.copy.disabled, "disabled")
  assertTrue(hasText(ctx, "No other loaded Ka0s addon uses skins yet."), "the hint")
  view.copy:__fire("OnClick")
  assertEqual(#m.popups, 0, "a disabled copy asks nothing")
end)

test("appearance: copy confirms with the other owners' names and writes each through its own setter", function()
  local m, Skin, lib = env()
  local store = register(Skin, OWNER, "ka0s", "midnight")
  local other = register(Skin, OTHER, "ka0s", "glass")
  local third = register(Skin, THIRD)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  assertFalse(view.copy.disabled, "enabled with two other owners")
  assertFalse(hasText(ctx, "No other loaded Ka0s addon uses skins yet."), "no hint")
  view.copy:__fire("OnClick")
  assertEqual(#m.popups, 1, "one confirmation")
  local p = m.popups[1]
  assertTrue(p.a2:find(OTHER .. " Label", 1, true) ~= nil, "names " .. OTHER)
  assertTrue(p.a2:find(THIRD .. " Label", 1, true) ~= nil, "names " .. THIRD)
  assertFalse(p.a2:find(OWNER .. " Label", 1, true) ~= nil, "not the addon copying")
  assertTrue(p.dialog.text:find("not loaded are unchanged", 1, true) ~= nil, "says what is not changed")
  assertEqual(other.writes, 0, "nothing written before the confirmation")
  p.dialog.OnAccept(nil, p.data)
  assertEqual(other.skin, "midnight", OTHER .. "'s profile written")
  assertEqual(third.skin, "midnight", THIRD .. "'s profile written")
  assertEqual(other.writes, 1)
  assertEqual(select(2, Skin:GetChoice(OTHER)), "midnight", "and its applied choice moved (repainted)")
  assertEqual(select(2, Skin:GetChoice(THIRD)), "midnight")
  assertEqual(store.seamCalls, nil, "the copying addon's own seam is not written")
end)

-- ── the EllesmereUI source ───────────────────────────────────────────────────────────────────

test("appearance: the EllesmereUI choice is disabled while the gate is closed, each condition listed", function()
  local _, Skin, lib = env({ eui = { masterOff = true } })
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  assertTrue(view.source.eui.disabled, "disabled")
  assertFalse(view.source.ka0s.disabled and true or false, "Ka0s skins stays choosable")
  assertEqual(#view.conditions, 4, "the gate's four conditions")
  local status = Skin:GetEUIStatus(OWNER)
  for i, c in ipairs(status.conditions) do
    local line = view.conditions[i].text
    local mark = c.ok and "ReadyCheck-Ready" or "ReadyCheck-NotReady"
    assertTrue(line:find(mark, 1, true) ~= nil, c.key .. " carries its " .. (c.ok and "check" or "cross"))
    assertTrue(line:find(c.label, 1, true) ~= nil, c.key .. "'s label")
    if not c.ok then assertTrue(line:find(c.hint, 1, true) ~= nil, c.key .. "'s fix") end
  end
  view.source.eui:__fire("OnValueChanged", true)
  assertEqual(Skin:GetChoice(OWNER), "ka0s", "a disabled choice moves nothing")
end)

test("appearance: with no Skin EllesmereUI provider the choice is disabled with one line", function()
  local _, Skin, lib = env()
  Skin.GetEUIStatus = nil
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  assertTrue(view.source.eui.disabled, "disabled")
  assertTrue(hasText(ctx, lib.APPEARANCE_STRINGS.EUI_MISSING), "says why")
end)

test("appearance: the open gate lets EllesmereUI in, and leaving it raises one reload popup", function()
  local m, Skin, lib, eui = env({ eui = {} })
  local store = register(Skin, OWNER)
  eui.login()
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  assertFalse(view.source.eui.disabled and true or false, "choosable")
  view.source.eui:__fire("OnValueChanged", true)
  assertEqual(Skin:GetChoice(OWNER), "eui")
  assertEqual(store.source, "eui", "written through the seam")
  assertEqual(#m.popups, 0, "onto EllesmereUI is live")
  view.source.ka0s:__fire("OnValueChanged", true)
  assertEqual(store.source, "ka0s")
  assertEqual(#m.popups, 1, "one reload popup")
  assertEqual(m.popups[1].which, "LIBKA0S_SKIN_RELOAD")
  assertEqual(m.popups[1].a1, OWNER .. " Label")
  local reloaded = 0
  m.ReloadUI = function() reloaded = reloaded + 1 end
  m.popups[1].dialog.OnAccept()
  assertEqual(reloaded, 1, "its accept reloads")
  view.source.eui:__fire("OnValueChanged", true)
  view.source.ka0s:__fire("OnValueChanged", true)
  assertEqual(#m.popups, 1, "never a second time")
end)

-- ── strings, disable, degradation ────────────────────────────────────────────────────────────

test("appearance: spec.strings translates every string, the skins' names and descriptions included", function()
  local m, Skin, lib = env()
  local store = register(Skin, OWNER)
  register(Skin, OTHER)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store, { strings = {
    SOURCE_KA0S = "Ka0s-Skins", SOURCE_HEADING = "Quelle", NOTE = "Hinweis", COPY = "Kopieren...",
    SKIN_obsidian = "Obsidian (de)", SKIN_obsidian_DESC = "Dunkel", COPY_CONFIRM = "%s -> %s",
  } }))
  assertEqual(view.source.ka0s.labelText, "Ka0s-Skins")
  assertTrue(hasText(ctx, "Quelle") and hasText(ctx, "Hinweis"), "heading and note")
  assertEqual(view.copy.text, "Kopieren...")
  assertTrue(view.skins.obsidian.labelText:find("Obsidian (de)", 1, true) ~= nil, "a skin's name")
  assertEqual(view.skins.obsidian.desc, "Dunkel", "and its description")
  view.copy:__fire("OnClick")
  assertEqual(m.popups[1].dialog.text, "%s -> %s", "the confirmation")
  assertEqual(lib.APPEARANCE_STRINGS.SOURCE_KA0S, "Ka0s skins", "the library's words are not written through")
end)

test("appearance: a page drawn disabled draws every control disabled", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  register(Skin, OTHER)
  local O, ctx = page(lib, OWNER)
  ctx.__renderDisabled = true
  local view = O.AppearanceRows(ctx, specFor(store))
  ctx.__renderDisabled = nil
  assertTrue(view.source.ka0s.disabled and view.copy.disabled and view.skins.glass.disabled, "all disabled")
end)

test("appearance: the refresher re-reads the owner's store", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  ctx.refreshers = {}
  local view = O.AppearanceRows(ctx, specFor(store))
  store.skin = "azeroth"
  for _, fn in ipairs(ctx.refreshers) do fn() end
  assertEqual(view.skins.azeroth.value, true)
  assertEqual(view.skins.ka0s.value, false)
end)

test("appearance: an owner that never registered, or no Skin major, draws one line and no controls", function()
  local _, _, lib = env()
  local O, ctx = page(lib, OWNER)
  assertNil(O.AppearanceRows(ctx, { get = function() end, set = function() end }))
  assertTrue(hasText(ctx, lib.APPEARANCE_STRINGS.UNAVAILABLE), "the line")
  local _, none, lib2 = env({ noSkin = true })
  assertNil(none, "no Skin major")
  local O2, ctx2 = page(lib2, OWNER)
  assertNil(O2.AppearanceRows(ctx2, {}))
  assertTrue(hasText(ctx2, lib2.APPEARANCE_STRINGS.UNAVAILABLE))
end)
