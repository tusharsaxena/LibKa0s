-- tests/test_options_skin.lua — the settings chrome follows the page's skin owner (Options minor 31,
-- OptionsTabs 10, OptionsNav 3, OptionsDrawer 2, OptionsCombat 3, OptionsIds 4, OptionsIdList 6,
-- OptionsKeybinds 5, OptionsScroll 5; LK-07 of Ka0sAddonsCommonTasks docs/2026-10-25-SKINNING).
--
-- Three promises, pinned on the kit's paint recorder (tests/fixture_skin_paint.lua):
--
--   * WITHOUT AN OWNER NOTHING MOVES. The descriptor's `addonName` counts as the page's skin owner
--     only once that addon called Skin:RegisterOwner, so a page whose host names an unregistered
--     addon, a page whose host names none and a page in a client with no Skin major make the same
--     paint calls, call for call (the tracer, hook installs aside).
--   * AN OWNED PAGE paints its chrome from the owner's skin -- header, backdrop, tab strip, content
--     box, nav rail, drawer, combat cover, scrollbar thumb, the id list's help mark, the keybind
--     rows and the id-suggestion popup -- and a skin switch repaints it with no reload.
--   * KA0S DEFAULT ON AN OWNED PAGE draws what an owner-less page draws: no backdrop, the client's
--     tab art at full alpha.

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil =
  K.test, K.assertEqual, K.assertTrue, K.assertNil
local F = dofile("tests/fixture_skin_paint.lua")
local installBindings = dofile("tests/_kit/mock_bindings.lua")

local OWNER, OTHER = "LootHistory", "BankLedger"
local OPTIONS = { "Options", "OptionsRegistry", "OptionsWidgets", "OptionsIds", "OptionsIdList", "OptionsTabs",
                  "OptionsCombat", "OptionsCompose", "OptionsScroll", "OptionsNav", "OptionsDrawer",
                  "OptionsKeybinds" }

local function survey(m, obj) return m.__paint(obj) end
local function tok(Skin, skin, name) return F.tok(Skin, skin, name) end
local function rgb(c)
  if type(c) ~= "table" then return tostring(c) end
  return F.rgba({ c[1], c[2], c[3], 1 })
end

--- A fresh client: the paint recorder, Core, Pool, the Skin major (unless `noSkin`) and every Options
--- file. Answers m, Skin (nil without it), the Options major.
local function env(noSkin)
  local files = {}
  for _, f in ipairs(noSkin and { "Core" } or F.FILES) do files[#files + 1] = f end
  files[#files + 1] = "Pool"
  for _, f in ipairs(OPTIONS) do files[#files + 1] = f end
  local m, Skin = F.env({ files = files })
  return m, Skin, m.LibStub("LibKa0s-Options-1.0")
end

local seq = 0
--- An Options instance for a host named `owner` (nil: a host passing no addonName).
local function instance(lib, owner)
  seq = seq + 1
  local store = {}
  local O = lib:New({
    parentTitle = "Skin Host", mainPanelName = "SkinHostMain" .. seq, addonName = owner,
    print = function() end,
    get = function(path) return store[path] end,
    set = function(path, value) store[path] = value end,
    applyDefault = function() end,
    rowsForPage = function() return {} end,
    allRows = function() return {} end,
  })
  return O, store
end

--- One page with every piece of chrome: header, nav rail, tab strip and content box, a header block
--- and its hairline, an open drawer, and the combat cover put up.
local function page(O)
  seq = seq + 1
  local ctx = O.CreatePanel("SkinPage" .. seq, "Skin page", {})
  O.PageHeader(ctx, { height = 24, build = function() end })
  O.NavRail(ctx, { entries = { { key = "a", label = "Alpha" }, { key = "b", label = "Beta" } }, value = "a" })
  O.TabStrip(ctx, { tabs = { { key = "x", label = "Ex" }, { key = "y", label = "Why" } }, value = "x" })
  O.Drawer(ctx, { label = "Content", summary = "Any", open = true, set = true, body = function() end })
  ctx.__combatCover:Show()
  return ctx
end

--- The tracer's paint lines (hook installs dropped) for a page built by a host named `owner`.
local function traceOf(noSkin, owner)
  local m, _, lib = env(noSkin)
  local tr = F.tracer(m)
  tr.start()
  local ok, err = pcall(function() page((instance(lib, owner))) end)
  tr.stop(); tr.restore()
  if not ok then error(err, 0) end
  local out = {}
  for _, line in ipairs(tr.lines) do
    if not line:find(":HookScript(", 1, true) then out[#out + 1] = line end
  end
  return table.concat(out, "\n")
end

--- The tab buttons a strip drew, in order, and the content box.
local function tabsOf(ctx)
  local buttons, box = {}, nil
  for _, k in ipairs(ctx.__tabKids) do
    if k.__ka0sTabArt then buttons[#buttons + 1] = k else box = k end
  end
  return buttons, box
end

local function drawerHead(ctx)
  local scroll = ctx.scroll
  local group = scroll.children[#scroll.children]
  return group.children[1].frame.__ka0sDrawerHead
end

-- ── without an owner ─────────────────────────────────────────────────────────────────────────

test("options skin: a page with no registered owner is today's paint, call for call", function()
  local named = traceOf(false, OTHER)
  local bare = traceOf(false, nil)
  local noSkin = traceOf(true, OTHER)
  assertTrue(bare ~= "", "the page paints something")
  assertEqual(named, bare, "an unregistered owner is the previous minors' paint")
  assertEqual(noSkin, bare, "a client with no Skin major is the previous minors' paint")
end)

test("options skin: an owner-less page records nothing in the Skin major", function()
  local m, Skin, lib = env()
  local ctx = page((instance(lib, OTHER)))
  local buttons = tabsOf(ctx)
  assertNil(Skin.painted[buttons[1]], "no tab is tracked")
  assertNil(Skin.painted[ctx.__railFrame], "nor the rail")
  assertNil(ctx.panel.__ka0sSkinBg, "and no backdrop exists")
  assertEqual(survey(m, buttons[1].__ka0sTabArt.left).alpha, 1, "the client's tab art is untouched")
end)

-- ── an owned page ────────────────────────────────────────────────────────────────────────────

test("options skin: an owned page paints its header and an opaque backdrop from the skin", function()
  local m, Skin, lib = env()
  F.owner(Skin, OWNER, "azeroth")
  local ctx = page((instance(lib, OWNER)))
  assertEqual(F.rgba(survey(m, ctx.panel.title).textColor), rgb(Skin:ResolveSkin("azeroth")["title.text"]))
  assertEqual(F.rgba(survey(m, ctx.panel.divider).vertex), rgb(Skin:ResolveSkin("azeroth")["title.text"]),
    "the divider atlas is tinted the title color")
  local bg = ctx.panel.__ka0sSkinBg
  assertTrue(bg ~= nil, "a backdrop away from Ka0s Default")
  local p = survey(m, bg)
  assertTrue(p.shown, "shown")
  assertEqual(F.rgba(p.color), rgb(Skin:ResolveSkin("azeroth")["win.bg"]), "win.bg at full alpha")
end)

test("options skin: an owned page's tab strip fades the client's art and wears the tab roles", function()
  local m, Skin, lib = env()
  F.owner(Skin, OWNER, "obsidian")
  local ctx = page((instance(lib, OWNER)))
  local buttons, box = tabsOf(ctx)
  local on, off = buttons[1], buttons[2]
  for _, k in ipairs({ "left", "mid", "right" }) do
    assertEqual(survey(m, on.__ka0sTabArt[k]).alpha, 0, "slice " .. k .. " faded")
  end
  assertEqual(F.rgba(survey(m, on.__ka0sTabLabel).textColor), rgb(Skin:ResolveSkin("obsidian")["tab.onText"]))
  assertEqual(F.rgba(survey(m, off.__ka0sTabLabel).textColor), rgb(Skin:ResolveSkin("obsidian")["tab.text"]))
  assertTrue(Skin.painted[box] ~= nil, "the content box is painted")
  assertEqual(survey(m, box.__ka0sHalves[1]).alpha, 0, "its inner-frame art faded")
  assertEqual(F.rgba(survey(m, ctx.__ruleTex).color), tok(Skin, "obsidian", "tab.rule"), "the hairline")
end)

test("options skin: an owned page's rail, drawer and cover paint from the skin", function()
  local m, Skin, lib = env()
  F.owner(Skin, OWNER, "ember")
  local ctx = page((instance(lib, OWNER)))
  local T = Skin:ResolveSkin("ember")
  assertEqual(F.rgba(survey(m, ctx.__railFrame).backdropColor), F.rgba(T["nav.bg"]), "the rail's pane")
  local sel, other = ctx.__railKids[1], ctx.__railKids[2]
  assertEqual(F.rgba(survey(m, sel.__ka0sNavLabel).textColor), rgb(T["nav.selText"]))
  assertEqual(F.rgba(survey(m, other.__ka0sNavLabel).textColor), rgb(T["nav.text"]))
  local head = drawerHead(ctx)
  assertEqual(F.rgba(survey(m, head.__ka0sDrawerLabelFS).textColor), rgb(T["drawer.textSet"]))
  assertEqual(F.rgba(survey(m, head.__ka0sDrawerEdges.fill).vertex), F.rgba(T["drawer.bgOpen"]))
  local cover = ctx.__combatCover
  assertEqual(F.rgba(survey(m, cover.__dim).color), F.rgba(T["cover.dim"]))
  assertEqual(F.rgba(survey(m, cover.__line).textColor), rgb(T["cover.text"]))
end)

test("options skin: a skin switch repaints the owned page with no reload, Ka0s Default included",
  function()
  local m, Skin, lib = env()
  F.owner(Skin, OWNER, "obsidian")
  local ctx = page((instance(lib, OWNER)))
  local buttons = tabsOf(ctx)
  Skin:SetChoice(OWNER, "ka0s", "contrast")
  local T = Skin:ResolveSkin("contrast")
  assertEqual(F.rgba(survey(m, ctx.panel.__ka0sSkinBg).color), rgb(T["win.bg"]), "the backdrop follows")
  assertEqual(F.rgba(survey(m, ctx.panel.title).textColor), rgb(T["title.text"]), "and the title")
  assertEqual(F.rgba(survey(m, ctx.__railFrame).backdropColor), F.rgba(T["nav.bg"]), "and the rail")
  assertEqual(F.rgba(survey(m, buttons[1].__ka0sTabLabel).textColor), rgb(T["tab.onText"]), "and the tabs")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  local D = Skin:ResolveSkin("ka0s")
  assertEqual(F.rgba(survey(m, ctx.panel.__ka0sSkinBg).color), rgb(D["win.bg"]), "Ka0s Default's backdrop (minor 6)")
  assertEqual(survey(m, buttons[1].__ka0sTabArt.left).alpha, 0, "the client's tab art stays faded")
  assertEqual(F.rgba(survey(m, ctx.panel.divider).vertex), "1,0.820,0,1", "the divider is gold again")
end)

test("options skin: Ka0s Default dresses an owned page like every skin", function()
  -- SkinPaint minor 6: Ka0s Default draws the page's backdrop and fades the client's art too.
  local m, Skin, lib = env()
  F.owner(Skin, OWNER)
  local ctx = page((instance(lib, OWNER)))
  local buttons, box = tabsOf(ctx)
  local D = Skin:ResolveSkin("ka0s")
  assertEqual(F.rgba(survey(m, ctx.panel.__ka0sSkinBg).color), rgb(D["win.bg"]), "Ka0s Default's backdrop")
  assertEqual(survey(m, buttons[1].__ka0sTabArt.left).alpha, 0, "tab art faded")
  assertEqual(survey(m, box.__ka0sHalves[1]).alpha, 0, "inner-frame art faded")
  assertEqual(F.rgba(survey(m, ctx.__railFrame).backdropColor), "0.100,0.100,0.100,0.500", "PANE_FILL")
  assertEqual(F.rgba(survey(m, ctx.__combatCover.__dim).color), "0,0,0,0.600", "the cover's dim")
end)

test("options skin: an owner that registers after the page was built gets its skin on the next show",
  function()
  local m, Skin, lib = env()
  local O = instance(lib, OWNER)
  seq = seq + 1
  local ctx = O.CreatePanel("SkinLate" .. seq, "Late", {})
  assertNil(ctx.panel.__ka0sSkinBg, "built before the owner registered: nothing")
  F.owner(Skin, OWNER, "glass")
  ctx.panel:Hide()
  ctx.panel:Show()
  ctx.panel:__fire("OnShow")
  assertTrue(ctx.panel.__ka0sSkinBg ~= nil, "the show paints it")
  assertEqual(F.rgba(survey(m, ctx.panel.title).textColor), rgb(Skin:ResolveSkin("glass")["title.text"]))
end)

test("options skin: two owners' pages stay apart", function()
  local m, Skin, lib = env()
  F.owner(Skin, OWNER, "obsidian")
  F.owner(Skin, OTHER, "azeroth")
  local mine = page((instance(lib, OWNER)))
  local theirs = page((instance(lib, OTHER)))
  Skin:SetChoice(OTHER, "ka0s", "ember")
  assertEqual(F.rgba(survey(m, mine.panel.title).textColor), rgb(Skin:ResolveSkin("obsidian")["title.text"]),
    "the other owner's switch never reaches this page")
  assertEqual(F.rgba(survey(m, theirs.panel.title).textColor), rgb(Skin:ResolveSkin("ember")["title.text"]))
end)

-- ── the pooled pieces ────────────────────────────────────────────────────────────────────────

test("options skin: the always-shown thumb takes the owner's tints, and is given back on release", function()
  local m, Skin, lib = env()
  F.owner(Skin, OWNER, "obsidian")
  local bar = m.CreateFrame("Slider", nil, m.UIParent)
  local thumb = bar:CreateTexture(nil, "OVERLAY")
  bar.GetThumbTexture = function() return thumb end
  bar.SetValue, bar.Enable, bar.Disable = function() end, function() end, function() end
  local scroll = { scrollbar = bar, scrollframe = m.CreateFrame("Frame"), content = m.CreateFrame("Frame"),
                   localstatus = { offset = 0 } }
  scroll.scrollframe.GetHeight = function() return 100 end
  scroll.content.GetHeight = function() return 400 end
  scroll.SetScroll = function() end
  lib.PatchAlwaysShowScrollbar(scroll, OWNER)
  scroll:FixScroll()
  local T = Skin:ResolveSkin("obsidian")
  assertEqual(F.rgba(survey(m, thumb).vertex), rgb(T["scroll.thumbOn"]), "a live bar: thumbOn")
  scroll.content.GetHeight = function() return 50 end
  scroll:FixScroll()
  assertEqual(F.rgba(survey(m, thumb).vertex), rgb(T["scroll.thumbOff"]), "an inert bar: thumbOff")
  scroll:OnRelease()
  assertNil(Skin.painted[bar], "released: the pooled bar is given back")
  assertEqual(F.rgba(survey(m, thumb).vertex), "1,1,1,1", "with the patch's own white")
end)

test("options skin: a pooled drawer head drawn for no owner leaves the owner's repaint", function()
  local _, Skin, lib = env()
  F.owner(Skin, OWNER, "obsidian")
  local O = instance(lib, OWNER)
  local ctx = page(O)
  local head = drawerHead(ctx)
  assertTrue(Skin.painted[head] ~= nil, "tracked for its owner")
  local bare = instance(lib, nil)
  seq = seq + 1
  local other = bare.CreatePanel("SkinBare" .. seq, "Bare", {})
  -- The head lives on a pooled SimpleGroup frame; draw an owner-less drawer on that same frame.
  local group = ctx.scroll.children[#ctx.scroll.children]
  local header = group.children[1]
  local saved = bare.AceGUI.Create
  bare.AceGUI.Create = function(self, wtype)
    local w = saved(self, wtype)
    if wtype == "SimpleGroup" then
      other.__groups = (other.__groups or 0) + 1
      -- The drawer's second SimpleGroup is its header (its first is the drawer's own group).
      if other.__groups == 2 then w.frame = header.frame end
    end
    return w
  end
  bare.Drawer(other, { label = "Bare", open = false })
  bare.AceGUI.Create = saved
  assertNil(Skin.painted[head], "drawn for no owner: given back")
end)

test("options skin: the id list's help mark takes the skin's tints away from Ka0s Default", function()
  local _, Skin, lib = env()
  F.owner(Skin, OWNER, "azeroth")
  local O = instance(lib, OWNER)
  seq = seq + 1
  local ctx = O.CreatePanel("SkinIds" .. seq, "Ids", {})
  local entries = { { id = 17, help = { "A note." } } }
  O.EnsureScroll(ctx).content.width = 1000
  O.IdList(ctx, { kind = "spell", entries = function() return entries end })
  local mark
  local function walk(w)
    if type(w) ~= "table" then return end
    if w.__helpTint then mark = w end
    for _, c in ipairs(w.children or {}) do walk(c) end
  end
  walk(ctx.scroll)
  assertTrue(mark ~= nil, "a help mark is drawn")
  local T = Skin:ResolveSkin("azeroth")
  assertEqual(rgb(mark.__helpTint), rgb(T["text.accent"]), "its tint is the skin's accent")
  mark:__fire("OnEnter")
  assertEqual(rgb(mark.__helpTintNow), rgb(T["icon.hot"]), "its hover is the skin's hot icon color")
end)

test("options skin: the keybind rows take the skin's text roles away from Ka0s Default", function()
  local m, Skin, lib = env()
  installBindings(m)
  m.BINDING_NAME_LKSKIN_TOGGLE = "Toggle the skin bench"
  F.owner(Skin, OWNER, "obsidian")
  local O = instance(lib, OWNER)
  seq = seq + 1
  local ctx = O.CreatePanel("SkinKeys" .. seq, "Keys", {})
  local rows = O.KeybindRows(ctx, { bindings = { { command = "LKSKIN_TOGGLE" } } })
  assertTrue(rows and rows[1] ~= nil, "a row is drawn")
  local T = Skin:ResolveSkin("obsidian")
  local c = rows[1].label.color
  assertEqual(rgb({ c.r, c.g, c.b }), rgb(T["text.body"]), "the action's name in the body role")
  local s = rows[1].status.color
  assertEqual(rgb({ s.r, s.g, s.b }), rgb(T["text.muted"]), "the outcome line muted")
end)

test("options skin: Ka0s Default colors the keybind rows in its own text roles", function()
  local m, Skin, lib = env()
  installBindings(m)
  F.owner(Skin, OWNER)
  local O = instance(lib, OWNER)
  seq = seq + 1
  local ctx = O.CreatePanel("SkinKeysDefault" .. seq, "Keys", {})
  local rows = O.KeybindRows(ctx, { bindings = { { command = "LKSKIN_TOGGLE" } } })
  local D = Skin:ResolveSkin("ka0s")
  local c, st = rows[1].label.color, rows[1].status.color
  assertEqual(rgb({ c.r, c.g, c.b }), rgb(D["text.body"]), "the action's name in the body role")
  assertEqual(rgb({ st.r, st.g, st.b }), rgb(D["text.muted"]), "the outcome line muted")
end)

--- The id-suggestion popup a page's IdInput opens, typed into under the page's owner: answers the
--- popup (the one frame carrying `rows`).
local function openSuggest(m, O)
  for tier, id in ipairs({ 191395, 191396, 191397 }) do
    m.addIdRecord("item", id, "Potion of the Hushed Zephyr", 4638, nil, 1)
    m.setCraftedQuality(id, tier)
  end
  seq = seq + 1
  local ctx = O.CreatePanel("SkinSuggest" .. seq, "Suggest", {})
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
    if type(f.rows) == "table" then return f, eb end
  end
end

test("options skin: the id-suggestion popup takes the skin, Ka0s Default's edge included", function()
  local m, Skin, lib = env()
  F.owner(Skin, OWNER, "obsidian")
  local popup, eb = openSuggest(m, (instance(lib, OWNER)))
  assertTrue(popup ~= nil and popup:IsShown(), "the suggestion popup is open")
  local T = Skin:ResolveSkin("obsidian")
  assertEqual(F.rgba(survey(m, popup).backdropColor), F.rgba(T["popup.bg"]), "its fill is the skin's")
  assertEqual(rgb(survey(m, popup).backdropBorderColor), rgb(T["popup.border"]), "and its edge")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  local D = Skin:ResolveSkin("ka0s")
  assertEqual(F.rgba(survey(m, popup).backdropColor), F.rgba(D["popup.bg"]), "Ka0s Default's fill")
  assertEqual(F.rgba({ popup:GetBackdropBorderColor() }), F.rgba(D["popup.border"]), "and Ka0s Default's edge (minor 8)")
  -- a reopen under Ka0s Default keeps it there
  eb:SetText("zeph")
  eb:__fire("OnTextChanged", "zeph")
  m.__fireTimers()
  assertEqual(F.rgba({ popup:GetBackdropBorderColor() }), F.rgba(D["popup.border"]), "a reopen keeps it")
end)
