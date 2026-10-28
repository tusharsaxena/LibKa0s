-- tests/test_options_appearance.lua -- LibKa0s-Options-1.0's Appearance tab (OptionsAppearance.lua
-- minor 1, skinning-§3; LK-10 of Ka0sAddonsCommonTasks docs/2026-10-25-SKINNING): O.AppearanceTab,
-- O.AppearanceRows and lib.APPEARANCE_STRINGS, with the Skin major's two members the tab writes
-- through (Skin minor 4: OwnerLabel and WriteChoice). Since OptionsAppearance minor 3 (LibKa0s#63)
-- the tab is labeled "Skin" and draws a "Font and texture" section (Skin minor 6's SetOverride),
-- pinned at the end of this file.
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
-- page drawn disabled; a page whose owner never registered; and combat, which refuses a pick, a
-- copy click and a copy confirmation accepted after combat starts, writing nothing.
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
  assertEqual(tab.key, "Appearance", "the key stays Appearance (hosts name it in before and a stored tab)")
  assertEqual(tab.label, "Skin", "labeled Skin since OptionsAppearance minor 3")
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
  assertEqual(lib.APPEARANCE_STRINGS.TAB_LABEL, "Skin", "the library's words are not written through")
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

-- ── combat (options-ui-§2: every write through the settings surface waits for REGEN_ENABLED) ──

test("appearance: in combat a skin or source pick writes nothing", function()
  local m, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  lib.__combatLocked = true
  view.skins.obsidian:__fire("OnValueChanged", true)
  view.source.ka0s:__fire("OnValueChanged", true)
  assertEqual(select(2, Skin:GetChoice(OWNER)), "ka0s", "the applied skin did not move")
  assertNil(store.seamCalls, "the owner's seam was not called")
  assertEqual(store.writes, 0, "and its profile was not written")
  assertEqual(view.skins.obsidian.value, false, "the refused pick snaps back")
  assertEqual(view.skins.ka0s.value, true, "the stored skin stays checked")
  assertEqual(#m.popups, 0, "no popup")
  lib.__combatLocked = false
  view.skins.obsidian:__fire("OnValueChanged", true)
  assertEqual(select(2, Skin:GetChoice(OWNER)), "obsidian", "out of combat the pick lands")
end)

test("appearance: a copy clicked in combat asks nothing", function()
  local m, Skin, lib = env()
  local store = register(Skin, OWNER, "ka0s", "midnight")
  register(Skin, OTHER, "ka0s", "glass")
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  lib.__combatLocked = true
  view.copy:__fire("OnClick")
  assertEqual(#m.popups, 0, "no confirmation in combat")
end)

test("appearance: a copy confirmation accepted after combat starts writes no other owner", function()
  local m, Skin, lib = env()
  local store = register(Skin, OWNER, "ka0s", "midnight")
  local other = register(Skin, OTHER, "ka0s", "glass")
  local third = register(Skin, THIRD)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  view.copy:__fire("OnClick")
  assertEqual(#m.popups, 1, "the confirmation is up before combat")
  local p = m.popups[1]
  lib.__combatLocked = true
  p.dialog.OnAccept(nil, p.data)
  assertEqual(select(2, Skin:GetChoice(OTHER)), "glass", OTHER .. "'s applied skin did not move")
  assertEqual(select(2, Skin:GetChoice(THIRD)), "ka0s", THIRD .. "'s applied skin did not move")
  assertEqual(other.writes, 0, OTHER .. "'s profile not written")
  assertEqual(third.writes, 0, THIRD .. "'s profile not written")
  assertEqual(#m.popups, 1, "no reload popup")
  lib.__combatLocked = false
  p.dialog.OnAccept(nil, p.data)
  assertEqual(other.skin, "midnight", "accepted again out of combat, the copy lands")
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

-- ── the Scope section: Ignore settings panel, Ignore fonts (Skin minor 5, OptionsAppearance minor 2) ──

local function indexOf(list, w)
  for i, x in ipairs(list) do if x == w then return i end end
  return nil
end

test("appearance: the Scope section draws its two exceptions between the skins and the copy button", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  local S = lib.APPEARANCE_STRINGS
  assertEqual(view.ignore.panel.labelText, S.IGNORE_PANEL)
  assertEqual(view.ignore.fonts.labelText, S.IGNORE_FONTS)
  assertEqual(view.ignore.panel.value, false, "off by default")
  assertEqual(view.ignore.fonts.value, false)
  assertTrue(view.ignore.panel.checkType ~= "radio", "a check box, not a radio")
  assertTrue(hasText(ctx, S.SCOPE_HEADING), "its own heading")
  local all = flatten(ctx.scroll)
  local lastSkin = indexOf(all, view.skins[view.order[#view.order]])
  local panel, fonts, copy = indexOf(all, view.ignore.panel), indexOf(all, view.ignore.fonts), indexOf(all, view.copy)
  assertTrue(lastSkin < panel and panel < fonts and fonts < copy, "below the skins, side by side, above the copy")
end)

test("appearance: Ignore fonts moves the Skin major, writes the seam's third argument, and fonts go back live", function()
  -- red under: P.font without its __FontsIgnored gate (the string keeps the skin's face).
  local m, Skin, lib = env({ lsm = { ["font:Ka0s Fira Sans"] = "Fonts\\FiraSans.ttf",
    ["font:Ka0s Fira Sans SemiBold"] = "Fonts\\FiraSansSB.ttf" } })
  local store = register(Skin, OWNER, "ka0s", "forever")
  local frame = F.window(m)
  -- The kit's template font strings report no prior face (the client's GameFontNormal does): give
  -- the title one, so there is a face to hand back.
  frame.title:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
  Skin:For(OWNER).Shell(frame)
  local function face() return (frame.title:GetFont()) end
  assertEqual(face(), "Fonts\\FiraSansSB.ttf", "the skin's face on the title")
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  view.ignore.fonts:__fire("OnValueChanged", true)
  assertEqual(select(2, Skin:GetIgnore(OWNER)), true, "the Skin major moved")
  assertEqual(store.ignore and store.ignore.fonts, true, "written through spec.set's third argument")
  assertEqual(store.ignore.panel, false, "with the other half as it was")
  assertEqual(store.skin, "forever", "the skin untouched")
  assertEqual(face(), "Fonts\\FRIZQT__.TTF", "the title's own face is back, no reload")
  assertEqual(F.rgba(m.__paint(frame.title).textColor), F.tok(Skin, "forever", "title.text"), "still colored")
  view.ignore.fonts:__fire("OnValueChanged", false)
  assertEqual(face(), "Fonts\\FiraSansSB.ttf", "and the skin's face comes back")
  assertEqual(view.ignore.fonts.value, false)
end)

test("appearance: Ignore settings panel applies live both ways, with no reload", function()
  -- red under: a reload popup on turning it on (OptionsScroll minor 7 hands the chrome back).
  local m, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  view.ignore.panel:__fire("OnValueChanged", true)
  assertEqual(Skin:GetIgnore(OWNER), true)
  assertEqual(store.ignore and store.ignore.panel, true, "written")
  assertEqual(#m.popups, 0, "no reload popup")
  assertNil(lib.__chromeSkin(OWNER), "the chrome paints nothing now")
  view.ignore.panel:__fire("OnValueChanged", false)
  assertEqual(#m.popups, 0, "nor turning it off")
  assertTrue(lib.__chromeSkin(OWNER) ~= nil, "and the chrome paints again")
end)

test("appearance: SetIgnore keeps a nil half, never asks for a reload, and WriteChoice passes it on", function()
  local _, Skin = env()
  assertEqual(table.concat({ tostring(Skin:GetIgnore("Nobody")) }), "false", "an unregistered owner ignores nothing")
  local store = register(Skin, OWNER)
  local changed, reload = Skin:SetIgnore(OWNER, true, nil)
  assertTrue(changed, "changed")
  assertFalse(reload, "never a reload (OptionsScroll minor 7)")
  local panel, fonts = Skin:GetIgnore(OWNER)
  assertEqual(panel, true); assertEqual(fonts, false, "the nil half kept")
  assertFalse(Skin:__PanelSkinned(OWNER), "the paint paths are told to leave the panel")
  assertFalse((Skin:SetIgnore(OWNER, true, false)), "the same pair is no change")
  assertTrue(Skin:WriteChoice(OWNER, "ka0s", "glass", { panel = 1, fonts = true }))
  assertEqual(store.ignore.panel, false, "only true is true")
  assertEqual(store.ignore.fonts, true)
  Skin:WriteChoice(OWNER, "ka0s", "glass")
  assertNil(store.ignore, "no third argument without one")
end)

test("appearance: copy gives every other owner this owner's scope as well as its skin", function()
  local m, Skin, lib = env()
  local store = register(Skin, OWNER, "ka0s", "ember")
  local other = register(Skin, OTHER)
  Skin:SetIgnore(OWNER, false, true)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  view.copy:__fire("OnClick")
  assertTrue(m.popups[1].dialog.text:find("skin source, skin, scope, font and texture", 1, true) ~= nil,
    "says scope, font and texture")
  m.popups[1].dialog.OnAccept(nil, m.popups[1].data)
  local panel, fonts = Skin:GetIgnore(OTHER)
  assertEqual(panel, false); assertEqual(fonts, true, "the other owner ignores fonts now")
  assertEqual(other.ignore and other.ignore.fonts, true, "and its profile says so")
  assertEqual(other.skin, "ember")
end)

test("appearance: an instance whose owner ignores its panel still hears a skin switch", function()
  -- red under: O.__chromeSkin installing its listener only from the gated facade (turning the
  -- exception off would never re-render the open pages).
  local _, Skin, lib = env()
  register(Skin, OWNER)
  Skin:SetIgnore(OWNER, true, nil)
  local O = page(lib, OWNER)
  assertNil(O.__chromeSkin(), "nothing to paint with")
  assertTrue(#Skin.owners[OWNER].listeners > 0, "the listener is installed all the same")
end)

-- ── Font and texture (OptionsAppearance minor 3, LibKa0s-Skin-1.0 minor 6) ───────────────────

local MEDIA_LSM = { ["font:Ka0s Inter"] = "Fonts\\Inter.ttf", ["font:Arial Narrow"] = "Fonts\\ARIALN.ttf",
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

test("appearance: the Font and texture section draws two dropdowns between the skins and the scope", function()
  local _, Skin, lib = mediaEnv()
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  local S = lib.APPEARANCE_STRINGS
  assertTrue(hasText(ctx, S.MEDIA_HEADING), "its own heading")
  local font, texture = view.media.font, view.media.texture
  assertEqual(font.labelText, "Font"); assertEqual(texture.labelText, "Texture")
  assertEqual(font.order[1], "@skin", "the skin's own entry first")
  assertEqual(font.list["@skin"], "Skin's own (Ka0s Oxanium SemiBold)", "naming Ka0s Default's face")
  assertEqual(texture.list["@skin"], "Skin's own (Ka0s Default)", "and its bar texture")
  assertEqual(table.concat(font.order, "|"), "@skin|Arial Narrow|Ka0s Inter", "then LSM's font keys, sorted")
  assertEqual(table.concat(texture.order, "|"), "@skin|Blizzard|Ka0s Flat", "and its statusbar keys")
  assertEqual(font.value, "@skin", "no override: the skin's own")
  assertEqual(texture.value, "@skin")
  local all = flatten(ctx.scroll)
  local lastSkin = indexOf(all, view.skins[view.order[#view.order]])
  assertTrue(lastSkin < indexOf(all, font) and indexOf(all, font) < indexOf(all, texture)
    and indexOf(all, texture) < indexOf(all, view.ignore.panel), "after the skins, side by side, before the scope")
end)

test("appearance: a font pick moves the Skin major first, then writes the seam's fourth argument", function()
  local m, Skin, lib = mediaEnv()
  local store = register(Skin, OWNER)
  local frame = F.window(m)
  frame.title:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
  Skin:For(OWNER).Shell(frame)
  local O, ctx = page(lib, OWNER)
  local spec = specFor(store)
  local seam, seen = spec.set, nil
  spec.set = function(...)
    seen = { override = (Skin:GetOverride(OWNER)), n = select("#", ...), ... }
    seam(...)
  end
  local view = O.AppearanceRows(ctx, spec)
  view.media.font:__fire("OnValueChanged", "Ka0s Inter")
  assertEqual(seen.override, "Ka0s Inter", "SetOverride ran before the owner's write seam")
  assertNil(seen[1]); assertNil(seen[2]); assertNil(seen[3], "no source, skin or scope")
  assertEqual(store.media.font, "Ka0s Inter")
  assertEqual(store.media.texture, false, "the other half as it was: the skin's own")
  assertEqual(store.seamCalls, 1)
  assertEqual((frame.title:GetFont()), "Fonts\\Inter.ttf", "the title repainted with the override, live")
  assertEqual(view.media.font.value, "Ka0s Inter")
  view.media.texture:__fire("OnValueChanged", "Ka0s Flat")
  assertEqual(select(2, Skin:GetOverride(OWNER)), "Ka0s Flat")
  assertEqual(store.media.font, "Ka0s Inter", "both halves on every write")
  view.media.font:__fire("OnValueChanged", "@skin")
  assertNil((Skin:GetOverride(OWNER)), "the skin's own entry clears it")
  assertEqual(store.media.font, false)
  assertEqual(view.media.font.value, "@skin")
  assertEqual(select(2, Skin:GetChoice(OWNER)), "ka0s", "the skin untouched")
end)

test("appearance: in combat a font or texture pick writes nothing and snaps back", function()
  local _, Skin, lib = mediaEnv()
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  lib.__combatLocked = true
  view.media.font:__fire("OnValueChanged", "Ka0s Inter")
  view.media.texture:__fire("OnValueChanged", "Ka0s Flat")
  local font, texture = Skin:GetOverride(OWNER)
  assertNil(font); assertNil(texture, "the Skin major did not move")
  assertNil(store.seamCalls, "the seam was not called")
  assertEqual(view.media.font.value, "@skin", "the refused pick snaps back")
  lib.__combatLocked = false
  view.media.font:__fire("OnValueChanged", "Ka0s Inter")
  assertEqual((Skin:GetOverride(OWNER)), "Ka0s Inter", "out of combat it lands")
end)

test("appearance: sync re-reads the overrides, and the skin's own entry follows a skin switch", function()
  local _, Skin, lib = mediaEnv()
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  ctx.refreshers = {}
  local view = O.AppearanceRows(ctx, specFor(store))
  Skin:SetOverride(OWNER, nil, "Ka0s Flat")
  view.skins.obsidian:__fire("OnValueChanged", true)
  assertEqual(view.media.texture.value, "Ka0s Flat", "the override set elsewhere is read back")
  assertEqual(view.media.font.list["@skin"], "Skin's own (" .. Skin:ResolveSkin("obsidian")["font.body"] .. ")",
    "the first entry names the skin worn now")
  Skin:SetOverride(OWNER, nil, false)
  for _, fn in ipairs(ctx.refreshers) do fn() end
  assertEqual(view.media.texture.value, "@skin", "the refresher re-reads it too")
end)

test("appearance: copy gives every other owner this owner's font and texture", function()
  local m, Skin, lib = mediaEnv()
  local store = register(Skin, OWNER, "ka0s", "ember")
  local other = register(Skin, OTHER)
  Skin:SetOverride(OWNER, "Ka0s Inter", nil)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  view.copy:__fire("OnClick")
  m.popups[1].dialog.OnAccept(nil, m.popups[1].data)
  local font, texture = Skin:GetOverride(OTHER)
  assertEqual(font, "Ka0s Inter", "the other owner wears the font now")
  assertNil(texture, "and the skin's own texture")
  assertEqual(other.media.font, "Ka0s Inter", "its profile is written through WriteChoice's media")
  assertEqual(other.media.texture, false)
  assertEqual(other.skin, "ember")
end)

test("appearance: without LibSharedMedia each dropdown offers only the skin's own", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  assertEqual(table.concat(view.media.font.order, "|"), "@skin")
  assertEqual(table.concat(view.media.texture.order, "|"), "@skin")
end)

test("appearance: with a Skin copy before minor 6 the section is absent", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  Skin.SetOverride, Skin.GetOverride = nil, nil
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  assertNil(view.media.font, "no dropdowns")
  assertFalse(hasText(ctx, lib.APPEARANCE_STRINGS.MEDIA_HEADING), "no heading")
end)

test("appearance: a stored key LibSharedMedia lacks stays listed, and the skin's own names the worn face", function()
  -- red under: mediaList without the stored key (the field showed blank) and ResolveSkin's label.
  local _, Skin, lib = mediaEnv()
  local store = register(Skin, OWNER)
  Skin:SetOverride(OWNER, "Gone Font", nil)
  Skin.__euiTokens = function(owner) if owner == OWNER then return { ["font.body"] = "Expressway" } end end
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  Skin.__euiTokens = nil
  local font = view.media.font
  assertEqual(font.list["@skin"], "Skin's own (Expressway)", "the face worn without overrides")
  assertEqual(font.list["Gone Font"], "Gone Font (not loaded)", "the stored key, marked")
  assertEqual(font.order[#font.order], "Gone Font", "after LSM's keys")
  assertEqual(font.value, "Gone Font", "so the field shows it")
end)
