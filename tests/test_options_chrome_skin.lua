-- tests/test_options_chrome_skin.lua — the settings chrome's last unskinned pieces wear the page
-- owner's skin and stand down with it (OptionsDrawer 3, OptionsNav 4, OptionsIdList 7, OptionsIds 5,
-- OptionsScroll 9's O.__hoverArt, SkinPaintControls 10's Drawer and NavItem, SkinDefs 16's
-- `list.hoverArt`; LK-06c of Ka0sAddonsCommonTasks docs/2026-10-30-SKIN_LIBRARY_FOLLOWUPS, ruling
-- R-5, decisions D-01, D-07, D-13 and D-14).
--
-- What the earlier minors left as the client drew it, on an owned page:
--
--   * the drawer head's label and summary were tinted only, so they kept their template face and
--     Ignore fonts had nothing to act on; they now take the skin's body face (D-13: Prototype under Ka0s
--     Default, where the template drew Friz Quadrata);
--   * the drawer's chevron, the client's yellow arrow art, now desaturated and colored `icon.arrow`
--     as every other arrow the library draws;
--   * the hover art (drawer head, nav entry, id list entry, suggestion row), now colored by the new
--     `list.hoverArt`, which is `false` (the art as the client draws it) in Ka0s Default and WoW
--     Default and the skin's accent in the seven others;
--   * the id-suggestion popup's rows (`menu.text`, the dropdown menu's row color), its "+N more" line
--     (`text.disabled`) and the gray every id is drawn in (`text.disabled`, `|cff808080` exactly in
--     Ka0s Default).
--
-- All of it is the settings panel (D-01): an owner that ignores its settings panel, and an owner-less
-- page, get the client's look back.

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil =
  K.test, K.assertEqual, K.assertTrue, K.assertNil
local F = dofile("tests/fixture_skin_paint.lua")

local OWNER, OTHER = "LootHistory", "BankLedger"
local OPTIONS = { "Options", "OptionsRegistry", "OptionsWidgets", "OptionsIds", "OptionsIdList", "OptionsTabs",
                  "OptionsCombat", "OptionsCompose", "OptionsScroll", "OptionsNav", "OptionsDrawer",
                  "OptionsKeybinds" }
local KA0S_FACE = "Fonts\\Ka0s Prototype"

-- A font for every skin face, and FontStrings built from a template that answer it by name.
local LSM = setmetatable({}, { __index = function(_, k)
  local key = type(k) == "string" and k:match("^font:(.+)$")
  return key and ("Fonts\\" .. key) or nil
end })

local function templateObject(name)
  return { name = name, GetName = function(self) return self.name end,
           GetFont = function() return "Fonts\\FRIZQT__.TTF", 10, "" end }
end

local function env()
  local files = {}
  for _, f in ipairs(F.FILES) do files[#files + 1] = f end
  files[#files + 1] = "Pool"
  for _, f in ipairs(OPTIONS) do files[#files + 1] = f end
  local m, Skin = F.env({ files = files, lsm = LSM })
  local objects, create = {}, m.CreateFrame
  m.CreateFrame = function(...)
    local f = create(...)
    local cfs = rawget(f, "CreateFontString")
    if type(cfs) == "function" then
      rawset(f, "CreateFontString", function(self, name, layer, template)
        local fs = cfs(self, name, layer, template)
        if type(template) == "string" then
          objects[template] = objects[template] or templateObject(template)
          fs:SetFontObject(objects[template])
        end
        return fs
      end)
    end
    return f
  end
  return m, Skin, m.LibStub("LibKa0s-Options-1.0")
end

local seq = 0
local function instance(lib, owner)
  seq = seq + 1
  local store = {}
  return lib:New({
    parentTitle = "Chrome Host", mainPanelName = "ChromeHostMain" .. seq, addonName = owner,
    print = function() end,
    get = function(path) return store[path] end,
    set = function(path, value) store[path] = value end,
    applyDefault = function() end,
    rowsForPage = function() return {} end,
    allRows = function() return {} end,
  })
end

local function face(fs)
  local obj = fs:GetFontObject()
  if type(obj) == "string" then return obj end
  if type(obj) == "table" and obj.font then return obj.font[1] end
  if type(obj) == "table" then return obj.name end
  return nil
end

local function bodyFace(Skin, skin) return "Fonts\\" .. Skin:ResolveSkin(skin)["font.body"] end
local function rgb(c) return F.rgba({ c[1], c[2], c[3], 1 }) end
local function vertex(tex) return F.rgba({ tex:GetVertexColor() }) end
local function hex(c)
  local function b(x) return string.format("%02x", math.floor(x * 255 + 0.5)) end
  return "|cff" .. b(c[1]) .. b(c[2]) .. b(c[3])
end

--- A page with a nav rail and one drawer: answers ctx, the drawer head, the selected nav entry and
--- the idle one.
local function page(O, open)
  seq = seq + 1
  local ctx = O.CreatePanel("ChromePage" .. seq, "Chrome page", {})
  O.NavRail(ctx, { entries = { { key = "a", label = "Alpha" }, { key = "b", label = "Beta" } }, value = "a" })
  O.Drawer(ctx, { label = "Content", summary = "Any", open = open, set = true, body = function() end })
  local head
  for _, c in ipairs(ctx.scroll.children) do
    local h = c.children and c.children[1] and c.children[1].frame and c.children[1].frame.__ka0sDrawerHead
    if h then head = h end
  end
  assertTrue(head ~= nil, "a drawer head is drawn")
  return ctx, head, ctx.__railKids[1], ctx.__railKids[2]
end

--- The id-suggestion popup a page's IdInput opens: answers the popup (the frame carrying `rows`).
local function openSuggest(m, O, ctx, text)
  for tier, id in ipairs({ 191395, 191396, 191397 }) do
    m.addIdRecord("item", id, "Potion of the Hushed Zephyr", 4638, nil, 1)
    m.setCraftedQuality(id, tier)
  end
  if not ctx then
    seq = seq + 1
    ctx = O.CreatePanel("ChromeSuggest" .. seq, "Suggest", {})
  end
  local real, made = m.CreateFrame, {}
  m.CreateFrame = function(...)
    local f = real(...)
    made[#made + 1] = f
    return f
  end
  local _, eb = O.IdInput(ctx, nil, { kind = "item", candidates = function() return { 191395, 191396, 191397 } end,
                                       onAdd = function() end })
  eb:SetText(text or "zephyr")
  eb:__fire("OnTextChanged", text or "zephyr")
  m.__fireTimers()
  m.CreateFrame = real
  for _, f in ipairs(made) do
    if type(f.rows) == "table" then return f, eb, ctx end
  end
  return O.__suggestFrame and O.__suggestFrame(), eb, ctx
end

local function reopen(m, eb, text)
  eb:SetText(text)
  eb:__fire("OnTextChanged", text)
  m.__fireTimers()
end

-- ── the drawer head ──────────────────────────────────────────────────────────────────────────

test("chrome skin: an owned drawer's label and summary wear the skin's body face", function()
  -- red under: drawerText tinting only (P.tint), the template faces left in every skin.
  local _, Skin, lib = env()
  F.owner(Skin, OWNER)
  local _, head = page(instance(lib, OWNER), true)
  assertEqual(face(head.__ka0sDrawerLabelFS), KA0S_FACE, "Ka0s Default's face (D-13)")
  assertEqual(face(head.__ka0sDrawerSummaryFS), KA0S_FACE)
  Skin:SetChoice(OWNER, "ka0s", "azeroth")
  assertEqual(face(head.__ka0sDrawerLabelFS), bodyFace(Skin, "azeroth"), "a switch reaches it")
  assertEqual(face(head.__ka0sDrawerSummaryFS), bodyFace(Skin, "azeroth"))
end)

test("chrome skin: Ignore fonts gives the drawer's label and summary their template faces, live", function()
  local m, Skin, lib = env()
  F.owner(Skin, OWNER, "ember")
  local _, head = page(instance(lib, OWNER), true)
  Skin:SetIgnore(OWNER, nil, true)
  assertEqual(face(head.__ka0sDrawerLabelFS), "GameFontNormal", "the label's own face")
  assertEqual(face(head.__ka0sDrawerSummaryFS), "GameFontHighlightSmall", "the summary's")
  assertEqual(F.rgba(m.__paint(head.__ka0sDrawerLabelFS).textColor),
    rgb(Skin:ResolveSkin("ember")["drawer.textSet"]), "the skin's color stays")
  Skin:SetIgnore(OWNER, nil, false)
  assertEqual(face(head.__ka0sDrawerLabelFS), bodyFace(Skin, "ember"), "and the skin's face back")
end)

test("chrome skin: an owned drawer's chevron is desaturated and colored icon.arrow", function()
  -- red under: the client's yellow chevron art left untinted in every skin.
  local _, Skin, lib = env()
  F.owner(Skin, OWNER, "glass")
  local _, head = page(instance(lib, OWNER), false)
  local chev = head.__ka0sDrawerChevron
  assertTrue(chev:IsDesaturated(), "desaturated, so the token's hue shows")
  assertEqual(vertex(chev), rgb(Skin:ResolveSkin("glass")["icon.arrow"]))
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertEqual(vertex(chev), "1,0.820,0,1", "Ka0s Default's gold, as every arrow since SkinDefs minor 12")
end)

test("chrome skin: an owner-less drawer keeps the client's chevron, faces and hover art", function()
  local _, _, lib = env()
  local _, head, nav = page(instance(lib, OTHER), false)
  assertTrue(not head.__ka0sDrawerChevron:IsDesaturated(), "the chevron's own art")
  assertEqual(vertex(head.__ka0sDrawerChevron), "1,1,1,1")
  assertEqual(face(head.__ka0sDrawerLabelFS), "GameFontNormal")
  assertEqual(face(head.__ka0sDrawerSummaryFS), "GameFontHighlightSmall")
  assertTrue(not head.__ka0sDrawerHover:IsDesaturated())
  assertTrue(not nav.__ka0sNavHover:IsDesaturated())
end)

-- ── the hover art ────────────────────────────────────────────────────────────────────────────

test("chrome skin: the drawer's and the nav entry's hover art take list.hoverArt", function()
  -- red under: the client's ADD highlight art left as drawn in every skin.
  local _, Skin, lib = env()
  F.owner(Skin, OWNER, "obsidian")
  local _, head, sel, idle = page(instance(lib, OWNER), false)
  local want = rgb(Skin:ResolveSkin("obsidian")["text.accent"])
  for name, tex in pairs({ drawer = head.__ka0sDrawerHover, nav = idle.__ka0sNavHover, sel = sel.__ka0sNavHover }) do
    assertTrue(tex:IsDesaturated(), name .. " desaturated")
    assertEqual(vertex(tex), want, name .. " in the skin's accent")
  end
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  for name, tex in pairs({ drawer = head.__ka0sDrawerHover, nav = idle.__ka0sNavHover }) do
    assertTrue(not tex:IsDesaturated(), name .. ": Ka0s Default draws the client's art")
    assertEqual(vertex(tex), "1,1,1,1", name .. " untinted")
  end
  Skin:SetChoice(OWNER, "ka0s", "wow")
  assertTrue(not head.__ka0sDrawerHover:IsDesaturated(), "and WoW Default")
end)

test("chrome skin: Ignore settings panel gives the drawer and the rail their client look back, live", function()
  -- D-01. red under: a piece painted outside the chrome's record, left skinned until a reload.
  local m, Skin, lib = env()
  F.owner(Skin, OWNER, "azeroth")
  local _, head, _, idle = page(instance(lib, OWNER), false)
  Skin:SetIgnore(OWNER, true, nil)
  assertEqual(face(head.__ka0sDrawerLabelFS), "GameFontNormal", "the label's face")
  assertEqual(face(head.__ka0sDrawerSummaryFS), "GameFontHighlightSmall", "the summary's")
  assertTrue(not head.__ka0sDrawerChevron:IsDesaturated(), "the chevron's art")
  assertEqual(vertex(head.__ka0sDrawerChevron), "1,1,1,1")
  assertTrue(not head.__ka0sDrawerHover:IsDesaturated(), "the drawer's hover art")
  assertEqual(vertex(head.__ka0sDrawerHover), "1,1,1,1")
  assertTrue(not idle.__ka0sNavHover:IsDesaturated(), "the nav entry's hover art")
  Skin:SetIgnore(OWNER, false, nil)
  m.__fireTimers()
  local _, head2 = page(instance(lib, OWNER), false)
  assertTrue(head2.__ka0sDrawerChevron:IsDesaturated(), "off: painted again")
end)

test("chrome skin: a pooled drawer head drawn for no owner takes the client's look back", function()
  -- red under: a dress that leaves the owner's face, chevron tint or hover tint on the pooled head.
  local _, Skin, lib = env()
  F.owner(Skin, OWNER, "obsidian")
  local ctx, head = page(instance(lib, OWNER), false)
  assertTrue(head.__ka0sDrawerChevron:IsDesaturated(), "painted for its owner first")
  local bare = instance(lib, nil)
  seq = seq + 1
  local other = bare.CreatePanel("ChromeBare" .. seq, "Bare", {})
  local group = ctx.scroll.children[#ctx.scroll.children]
  local header = group.children[1]
  local saved = bare.AceGUI.Create
  local n = 0
  bare.AceGUI.Create = function(self, wtype)
    local w = saved(self, wtype)
    if wtype == "SimpleGroup" then
      n = n + 1
      if n == 2 then w.frame = header.frame end
    end
    return w
  end
  bare.Drawer(other, { label = "Bare", open = false })
  bare.AceGUI.Create = saved
  assertEqual(face(head.__ka0sDrawerLabelFS), "GameFontNormal", "the label's template face")
  assertEqual(face(head.__ka0sDrawerSummaryFS), "GameFontHighlightSmall")
  assertTrue(not head.__ka0sDrawerChevron:IsDesaturated(), "the chevron's art")
  assertEqual(vertex(head.__ka0sDrawerChevron), "1,1,1,1")
  assertTrue(not head.__ka0sDrawerHover:IsDesaturated(), "the hover art")
end)

-- ── the id list ──────────────────────────────────────────────────────────────────────────────

--- An id list whose InteractiveLabels carry a highlight texture, as AceGUI's do: answers the first
--- entry label and the ctx.
local function idList(m, O, entries)
  seq = seq + 1
  local ctx = O.CreatePanel("ChromeIds" .. seq, "Ids", {})
  O.EnsureScroll(ctx).content.width = 1000
  local saved = O.AceGUI.Create
  O.AceGUI.Create = function(self, wtype)
    local w = saved(self, wtype)
    if wtype == "InteractiveLabel" and not w.highlight then
      w.highlight = m.CreateFrame("Frame"):CreateTexture(nil, "HIGHLIGHT")
    end
    return w
  end
  O.IdList(ctx, { kind = "spell", entries = function() return entries end })
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

test("chrome skin: an id list entry's highlight takes list.hoverArt and its gray text.disabled", function()
  -- red under: the entry's quest-log highlight left as drawn, and |cff808080 in every skin.
  local m, Skin, lib = env()
  F.owner(Skin, OWNER, "ember")
  local lbl = idList(m, instance(lib, OWNER), { { id = 17, suffix = "tag" } })
  local T = Skin:ResolveSkin("ember")
  assertTrue(lbl.highlight:IsDesaturated(), "desaturated")
  assertEqual(vertex(lbl.highlight), rgb(T["text.accent"]))
  assertTrue(tostring(lbl.text):find(hex(T["text.disabled"]) .. "tag", 1, true) ~= nil,
    "the suffix in the skin's disabled gray: " .. tostring(lbl.text))
end)

test("chrome skin: Ka0s Default and an owner-less list keep the client's highlight and |cff808080", function()
  local m, Skin, lib = env()
  F.owner(Skin, OWNER)
  local mine = idList(m, instance(lib, OWNER), { { id = 17, suffix = "tag" } })
  local theirs = idList(m, instance(lib, OTHER), { { id = 17, suffix = "tag" } })
  for name, lbl in pairs({ ["Ka0s Default"] = mine, ["owner-less"] = theirs }) do
    assertTrue(not lbl.highlight:IsDesaturated(), name .. ": the art as drawn")
    assertEqual(vertex(lbl.highlight), "1,1,1,1", name)
    assertTrue(tostring(lbl.text):find("|cff808080tag", 1, true) ~= nil, name .. ": " .. tostring(lbl.text))
  end
end)

test("chrome skin: a released id list entry gives its highlight art back to the pool", function()
  -- red under: the owner's tint riding the pooled InteractiveLabel to its next consumer.
  local m, Skin, lib = env()
  F.owner(Skin, OWNER, "glass")
  local lbl = idList(m, instance(lib, OWNER), { { id = 17 } })
  local tex = lbl.highlight
  assertTrue(tex:IsDesaturated(), "painted first")
  lbl.callbacks.OnRelease(lbl, "OnRelease")
  assertTrue(not tex:IsDesaturated(), "released: the art's own")
  assertEqual(vertex(tex), "1,1,1,1")
end)

test("chrome skin: Ignore settings panel draws the id list's next render in the client's look", function()
  local m, Skin, lib = env()
  F.owner(Skin, OWNER, "azeroth")
  Skin:SetIgnore(OWNER, true, nil)
  local lbl = idList(m, instance(lib, OWNER), { { id = 17, suffix = "tag" } })
  assertTrue(not lbl.highlight:IsDesaturated())
  assertTrue(tostring(lbl.text):find("|cff808080tag", 1, true) ~= nil, tostring(lbl.text))
end)

-- ── the id-suggestion popup ──────────────────────────────────────────────────────────────────

test("chrome skin: an owned suggestion popup's rows, more line and id gray wear the skin", function()
  -- red under: rows left GameFontHighlightSmall white, the more line GameFontDisableSmall, the
  -- highlight art untinted and the id |cff808080 in every skin.
  local m, Skin, lib = env()
  F.owner(Skin, OWNER, "azeroth")
  local popup = openSuggest(m, instance(lib, OWNER))
  assertTrue(popup ~= nil and popup:IsShown(), "the popup is open")
  local T = Skin:ResolveSkin("azeroth")
  local row = popup.rows[1]
  assertEqual(F.rgba(m.__paint(row.label).textColor), rgb(T["menu.text"]), "the row in menu.text")
  assertEqual(face(row.label), bodyFace(Skin, "azeroth"), "in the body face")
  assertTrue(tostring(row.labelText):find(hex(T["text.disabled"]) .. "(191395)", 1, true) ~= nil,
    "the id in text.disabled: " .. tostring(row.labelText))
  assertTrue(row.__ka0sHover:IsDesaturated(), "the row's highlight desaturated")
  assertEqual(vertex(row.__ka0sHover), rgb(T["text.accent"]), "and in the accent")
  assertEqual(F.rgba(m.__paint(popup.more.label).textColor), rgb(T["text.disabled"]), "the more line")
  assertEqual(face(popup.more.label), bodyFace(Skin, "azeroth"))
end)

test("chrome skin: Ka0s Default's suggestion rows keep the client's gray and highlight art", function()
  -- D-14: the rows take menu.text (0.9 where the template drew white, the dropdown menu's rows'
  -- color); the id gray and the more line stay exact.
  local m, Skin, lib = env()
  F.owner(Skin, OWNER)
  local popup = openSuggest(m, instance(lib, OWNER))
  local D = Skin:ResolveSkin("ka0s")
  local row = popup.rows[1]
  assertEqual(F.rgba(m.__paint(row.label).textColor), rgb(D["menu.text"]))
  assertEqual(face(row.label), KA0S_FACE)
  assertTrue(tostring(row.labelText):find("|cff808080(191395)", 1, true) ~= nil, tostring(row.labelText))
  assertTrue(not row.__ka0sHover:IsDesaturated(), "the client's highlight art")
  assertEqual(F.rgba(m.__paint(popup.more.label).textColor), "0.500,0.500,0.500,1", "the template's gray")
end)

test("chrome skin: an owner-less popup and an ignored panel draw the client's suggestion rows", function()
  local m, Skin, lib = env()
  local bare = openSuggest(m, instance(lib, OTHER))
  local row = bare.rows[1]
  assertEqual(face(row.label), "GameFontHighlightSmall", "owner-less: the template")
  assertEqual(face(bare.more.label), "GameFontDisableSmall")
  assertTrue(not row.__ka0sHover:IsDesaturated())
  assertTrue(tostring(row.labelText):find("|cff808080(191395)", 1, true) ~= nil)

  F.owner(Skin, OWNER, "azeroth")
  local popup, eb = openSuggest(m, instance(lib, OWNER))
  assertEqual(face(popup.rows[1].label), bodyFace(Skin, "azeroth"), "skinned first")
  Skin:SetIgnore(OWNER, true, nil)
  reopen(m, eb, "zeph")
  row = popup.rows[1]
  assertEqual(face(row.label), "GameFontHighlightSmall", "the row's template face")
  assertEqual(F.rgba({ row.label:GetTextColor() }), "1,1,1,1", "and its own white")
  assertEqual(face(popup.more.label), "GameFontDisableSmall")
  assertTrue(not row.__ka0sHover:IsDesaturated(), "the client's highlight art")
  assertTrue(tostring(row.labelText):find("|cff808080(191395)", 1, true) ~= nil, tostring(row.labelText))
end)

-- ── the token ────────────────────────────────────────────────────────────────────────────────

test("chrome skin: list.hoverArt is the client's art in Ka0s Default and WoW Default, the accent elsewhere",
  function()
  -- `false` ("none": the art as drawn) resolves to nil, as every nilable color does.
  local _, Skin = env()
  for _, def in ipairs(Skin:Skins()) do
    local t = Skin:ResolveSkin(def.key)
    if def.key == "ka0s" or def.key == "wow" then
      assertNil(t["list.hoverArt"], def.key)
    else
      assertEqual(F.rgba(t["list.hoverArt"]), F.rgba(t["text.accent"]), def.key .. " follows text.accent")
    end
  end
end)
