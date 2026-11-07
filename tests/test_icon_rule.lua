-- tests/test_icon_rule.lua — the icon rule on every Blizzard icon art the library draws (R5-L5 of
-- Ka0sAddonsCommonTasks docs/2026-11-03-SMOKE_ROUND5, feedback item 7, the lead's call 9):
-- OptionsIdList 9, OptionsIdSuggest 2, Widgets 22 and WidgetsAutocomplete 7.
--
-- The rule (docs/api/README.md, *Icon art*): an item, spell, spec, class or currency icon is cropped
-- at least 0.07 a side, and in a window or on a settings page edged 1 physical px in `icon.outline`
-- (S.IconBorder with no `hud`). What the library draws of that art, and what this pins:
--
--   * the id list's entry icon (`lbl:SetImage`): AceGUI's own texcoords carry the crop, so a pooled
--     label's OnAcquire `SetImage(nil)` puts them back; the edge is a frame the list owns, laid over
--     the image and handed back on the label's release, never a record on AceGUI's pooled texture
--     (the skeptic's correction: a record there outlives the label and reaches the next addon);
--   * the id input's suggestion rows and the Widgets autocomplete's rows: cropped on every fill,
--     edged on an owned page or list, and no edge without an owner;
--   * W.IconText, the inline `|T` markup a host writes into a tooltip or chat line, which cannot
--     take an edge, so it is cropped only: 5..59 of 64.
--
-- Every case runs on a fresh environment (tests/fixture_skin_paint.lua).

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = K.test, K.assertEqual, K.assertTrue, K.assertNil
local F = dofile("tests/fixture_skin_paint.lua")

local OWNER, OTHER = "LootHistory", "BankLedger"
local OPTIONS = { "Options", "OptionsRegistry", "OptionsWidgets", "OptionsFlow", "OptionsIds", "OptionsIdSuggest",
                  "OptionsIdList", "OptionsTabs", "OptionsTabbed", "OptionsHeader", "OptionsCombat", "OptionsCompose",
                  "OptionsScroll", "OptionsNav", "OptionsDrawer", "OptionsKeybinds" }
local WFILES = { "Widgets", "WidgetsDropdown", "WidgetsReorder", "WidgetsDragHandle", "WidgetsLineChart", "WidgetsAutocomplete",
                 "WidgetsCopyWindow" }
local SPELL, SPELL_ICON = 21562, 135987

local function survey(m, obj) return m.__paint(obj) end
local function texCoord(m, t) return table.concat(survey(m, t).texCoord or {}, ",") end
--- A square inset's coords as the client answers them, the corners UL, LL, UR, LR (mock_paint.lua).
local function inset(z) return table.concat({ z, z, z, 1 - z, 1 - z, z, 1 - z, 1 - z }, ",") end

local function env(widgets)
  local files = {}
  for _, f in ipairs(F.FILES) do files[#files + 1] = f end
  files[#files + 1] = "Pool"
  for _, f in ipairs(widgets and WFILES or OPTIONS) do files[#files + 1] = f end
  local m, Skin = F.env({ files = files })
  m.addIdRecord("spell", SPELL, "Power Word: Fortitude", SPELL_ICON)
  return m, Skin, m.LibStub(widgets and "LibKa0s-Widgets-1.0" or "LibKa0s-Options-1.0")
end

local seq = 0
local function instance(lib, owner)
  seq = seq + 1
  local store = {}
  return lib:New({
    parentTitle = "Icon Host", mainPanelName = "IconHostMain" .. seq, addonName = owner,
    print = function() end,
    get = function(path) return store[path] end,
    set = function(path, value) store[path] = value end,
    applyDefault = function() end,
    rowsForPage = function() return {} end,
    allRows = function() return {} end,
  })
end

--- The edge's four sides on `target`'s record: shown, each in one color. Answers that color, or nil
--- when no side is shown.
local function edgeColor(m, Skin, target)
  local rec = Skin.painted[target]
  if not rec then return nil end
  local color
  for _, side in ipairs({ "Top", "Bottom", "Left", "Right" }) do
    local t = rec.regions["edge" .. side]
    if not (t and survey(m, t).shown) then return nil end
    local c = F.rgba(survey(m, t).color)
    assertTrue(color == nil or color == c, "every side in one color")
    color = c
  end
  return color
end

-- ── the id list ──────────────────────────────────────────────────────────────────────────────

--- Draw an id list of one spell on `O`'s page; with `faithful`, the InteractiveLabel gets AceGUI's
--- own image Texture and SetImage (texture, then the texcoords passed or 0..1), where the kit's
--- label records the call's arguments. Answers the entry label and ctx.
local function idList(m, O, faithful)
  seq = seq + 1
  local ctx = O.CreatePanel("IconIds" .. seq, "Ids", {})
  O.EnsureScroll(ctx).content.width = 1000
  local saved = O.AceGUI.Create
  O.AceGUI.Create = function(self, wtype)
    local w = saved(self, wtype)
    if wtype == "InteractiveLabel" and faithful then
      w.image = m.CreateFrame("Frame"):CreateTexture(nil, "BACKGROUND")   -- a recorded Texture
      rawset(w, "SetImage", function(lbl, path, ...)
        lbl.image:SetTexture(path)
        if select("#", ...) == 4 then lbl.image:SetTexCoord(...) else lbl.image:SetTexCoord(0, 1, 0, 1) end
        return lbl
      end)
    end
    return w
  end
  -- The kit's frames take SetAllPoints and SetParent silently; the ones made here record both.
  local make = m.CreateFrame
  m.CreateFrame = function(...)
    local f = make(...)
    rawset(f, "SetAllPoints", function(self, rel) rawset(self, "__laidOn", rel) end)
    rawset(f, "SetParent", function(self, p) rawset(self, "__parentWas", p) end)
    return f
  end
  O.IdList(ctx, { kind = "spell", entries = function() return { { id = SPELL } } end })
  m.CreateFrame = make
  O.AceGUI.Create = saved
  local lbl
  local function walk(w)
    if type(w) ~= "table" then return end
    if w.type == "InteractiveLabel" and not lbl then lbl = w end
    for _, c in ipairs(w.children or {}) do walk(c) end
  end
  walk(ctx.scroll)
  assertTrue(lbl ~= nil, "an entry label is drawn")
  return lbl, ctx
end

test("icon rule: the minors move with the icon rule", function()
  local _, _, O = env()
  assertTrue(O.MODULES.OptionsIdList >= 9, "OptionsIdList minor 9")
  assertTrue(O.MODULES.OptionsIdSuggest >= 2, "OptionsIdSuggest minor 2")
  local _, _, W = env(true)
  assertTrue(W.MODULES.Widgets >= 22, "Widgets minor 22")
  assertTrue(W.MODULES.WidgetsAutocomplete >= 7, "WidgetsAutocomplete minor 7")
end)

test("icon rule: an id list entry's icon is cropped 0.07 a side through SetImage's own texcoords", function()
  -- red under: lbl:SetImage(icon), which AceGUI draws at 0..1, the art's own bevel showing (image 52's kind).
  local m, _, lib = env()
  local lbl = idList(m, instance(lib, OTHER))
  assertEqual(table.concat(lbl.image, ","), table.concat({ SPELL_ICON, 0.07, 0.93, 0.07, 0.93 }, ","),
    "the icon and four texcoords, an owner-less page included")
end)

test("icon rule: an owned id list entry's icon is edged 1 px in icon.outline, over the image", function()
  -- red under: no edge at all on the entry icon (the investigator's site 5).
  local m, Skin, lib = env()
  F.owner(Skin, OWNER, "ember")
  local lbl = idList(m, instance(lib, OWNER), true)
  assertEqual(texCoord(m, lbl.image), inset(0.07), "AceGUI drew the crop")
  local edge = lbl.__ka0sIconEdge
  assertTrue(edge ~= nil, "an edge frame the list owns")
  assertTrue(Skin.painted[lbl.image] == nil, "no record on AceGUI's pooled image")
  assertEqual(edgeColor(m, Skin, edge), F.tok(Skin, "ember", "icon.outline"), "the window outline, not icon.border")
  assertEqual(F.region(Skin, edge, "edgeTop"):GetHeight(), 1, "one pixel")
  assertTrue(rawget(edge, "__laidOn") == lbl.image, "on the image's own rect")
  assertTrue(rawget(edge, "__parentWas") == lbl.frame, "a child of the entry's frame while it is drawn")
  assertEqual(texCoord(m, lbl.image), inset(0.07), "and the edge leaves the coords alone")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(edgeColor(m, Skin, edge), F.tok(Skin, "obsidian", "icon.outline"), "a switch reaches it")
end)

test("icon rule: a released id list label hands its edge back, so a pooled label shows none", function()
  -- red under: the edge left standing on the AceGUI label another list, or another addon, acquires next.
  local m, Skin, lib = env()
  F.owner(Skin, OWNER)
  local lbl = idList(m, instance(lib, OWNER), true)
  local edge = lbl.__ka0sIconEdge
  assertTrue(survey(m, edge).shown, "shown while the entry is")
  lbl:__fire("OnRelease")
  assertTrue(not survey(m, edge).shown, "hidden on release")
  assertNil(lbl.__ka0sIconEdge, "and the label forgets it")
end)

test("icon rule: an owner-less id list entry is cropped and draws no edge", function()
  local m, _, lib = env()
  local lbl = idList(m, instance(lib, OTHER), true)
  assertEqual(texCoord(m, lbl.image), inset(0.07))
  assertNil(lbl.__ka0sIconEdge, "no owner, no skin, no edge")
end)

-- ── the id input's suggestions ───────────────────────────────────────────────────────────────

local function openSuggest(m, O)
  for tier, id in ipairs({ 191395, 191396, 191397 }) do
    m.addIdRecord("item", id, "Potion of the Hushed Zephyr", 4638, nil, 1)
    m.setCraftedQuality(id, tier)
  end
  seq = seq + 1
  local ctx = O.CreatePanel("IconSuggest" .. seq, "Suggest", {})
  local real, made = m.CreateFrame, {}
  m.CreateFrame = function(...)
    local f = real(...)
    made[#made + 1] = f
    return f
  end
  local _, eb = O.IdInput(ctx, nil, { kind = "item", candidates = function() return { 191395, 191396, 191397 } end,
                                       onAdd = function() end })
  eb:SetText("zephyr")
  eb:__fire("OnTextChanged", "zephyr")
  m.__fireTimers()
  m.CreateFrame = real
  for _, f in ipairs(made) do
    if type(f.rows) == "table" then return f end
  end
  return nil
end

test("icon rule: an id suggestion row's icon is cropped 0.07 a side, owned or not", function()
  -- red under: the row's texture at 0..1.
  local m, _, lib = env()
  local popup = openSuggest(m, instance(lib, OTHER))
  assertTrue(popup ~= nil and popup:IsShown(), "the popup is open")
  assertEqual(texCoord(m, popup.rows[1].icon), inset(0.07))
end)

test("icon rule: an owned id suggestion row's icon is edged in icon.outline, an owner-less one is not", function()
  -- red under: no edge on the row icon (the investigator's site 6).
  local m, Skin, lib = env()
  F.owner(Skin, OWNER, "azeroth")
  local popup = openSuggest(m, instance(lib, OWNER))
  local icon = popup.rows[1].icon
  assertEqual(edgeColor(m, Skin, icon), F.tok(Skin, "azeroth", "icon.outline"))
  assertEqual(F.region(Skin, icon, "edgeTop"):GetHeight(), 1, "one pixel")
  assertEqual(texCoord(m, icon), inset(0.07), "the crop and the zoom agree")
  local m2, Skin2, lib2 = env()
  local bare = openSuggest(m2, instance(lib2, OTHER))
  assertNil(edgeColor(m2, Skin2, bare.rows[1].icon), "owner-less: cropped only")
end)

-- ── the Widgets autocomplete ─────────────────────────────────────────────────────────────────

local function suggest(m, W, owner, icon)
  local box = m.CreateFrame("EditBox", nil, m.UIParent, "BackdropTemplate")
  rawset(box, "GetText", function() return "ab" end)
  local h = W.Autocomplete(box, { owner = owner, provider = function()
    return { { text = "One", icon = icon or 4638 }, { text = "Two" } }
  end })
  h:Refresh()
  return h
end

test("icon rule: an autocomplete row's icon is cropped 0.07 a side, owned or not", function()
  -- red under: the row's texture at 0..1.
  local m, _, W = env(true)
  local h = suggest(m, W, nil)
  assertEqual(texCoord(m, h.__rows[1].icon), inset(0.07))
  assertTrue(not survey(m, h.__rows[2].icon).shown, "a row with no icon shows none")
end)

test("icon rule: an owned autocomplete row's icon is edged in icon.outline, live, and hidden with its icon", function()
  -- red under: no edge on the row icon (the investigator's site 7).
  local m, Skin, W = env(true)
  F.owner(Skin, OWNER, "glass")
  local h = suggest(m, W, OWNER)
  local icon = h.__rows[1].icon
  assertEqual(edgeColor(m, Skin, icon), F.tok(Skin, "glass", "icon.outline"))
  assertEqual(texCoord(m, icon), inset(0.07))
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  h:Refresh()
  assertEqual(edgeColor(m, Skin, icon), F.tok(Skin, "ka0s", "icon.outline"), "the next show reads the switch")
  local bare = suggest(m, W, OTHER)
  assertNil(edgeColor(m, Skin, bare.__rows[1].icon), "an unregistered owner: cropped only")
end)

test("icon rule: an autocomplete row reused for an item with no icon keeps no visible edge", function()
  local m, Skin, W = env(true)
  F.owner(Skin, OWNER)
  local box = m.CreateFrame("EditBox", nil, m.UIParent, "BackdropTemplate")
  rawset(box, "GetText", function() return "ab" end)
  local answer = { { text = "One", icon = 4638 } }
  local h = W.Autocomplete(box, { owner = OWNER, provider = function() return answer end })
  h:Refresh()
  local icon = h.__rows[1].icon
  local holder = Skin.painted[icon].regions.holder
  assertTrue(survey(m, holder).shown, "the edge shows around the icon")
  answer = { { text = "Bare" } }
  h:Refresh()
  assertTrue(not survey(m, icon).shown, "the icon hidden")
  assertTrue(not survey(m, holder).shown, "and its edge with it")
end)

-- ── inline markup ────────────────────────────────────────────────────────────────────────────

test("icon rule: W.IconText is inline markup cropped 5..59 of 64, at a size or the line's height", function()
  -- red under: no such member (hosts wrote `|T<icon>:<s>:<s>:0:0|t`, uncropped).
  local _, _, W = env(true)
  assertEqual(type(W.IconText), "function")
  assertEqual(W.IconText(SPELL_ICON, 14), "|T135987:14:14:0:0:64:64:5:59:5:59|t")
  assertEqual(W.IconText("Interface\\ICONS\\Ability_Hunter_FocusedAim", 16, 12),
    "|TInterface\\ICONS\\Ability_Hunter_FocusedAim:16:12:0:0:64:64:5:59:5:59|t", "height then width, as |T is")
  assertEqual(W.IconText(SPELL_ICON), "|T135987:0:0:0:0:64:64:5:59:5:59|t", "no size: the line's height")
  assertEqual(W.IconText(nil, 14), "", "no icon: nothing")
  assertTrue(5 / 64 >= 0.07, "5 of 64 is at least the rule's 0.07")
end)

test("icon rule: the inline crop is what MarkText's full-art markup is not", function()
  -- The Ka0s catalog marks are exempt (the rule's last line): S.MarkText keeps 0..64.
  local _, Skin = env(true)
  local S = F.owner(Skin, OWNER)
  local mark = S.MarkText("Interface\\x", 12, "icon.tint")
  assertTrue(mark:find(":0:64:0:64:", 1, true) ~= nil, "a mark is drawn whole: " .. mark)
end)
