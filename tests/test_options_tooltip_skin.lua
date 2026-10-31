-- tests/test_options_tooltip_skin.lua — the tooltip lines the settings chrome writes take the page
-- owner's tooltip tokens (OptionsScroll minor 9's O.__tipColor; OptionsWidgets 36, OptionsDrawer 3,
-- OptionsNav 4, OptionsTabs 11, OptionsKeybinds 6, OptionsIdList 7; LK-06d of Ka0sAddonsCommonTasks
-- docs/2026-10-30-SKIN_LIBRARY_FOLLOWUPS, ruling R-5, decision D-14).
--
-- Six sites wrote an explicit color into GameTooltip: the white title of O.AttachTooltip (every
-- settings row and control), the drawer head, the nav entry, the tab, the key button, and the id
-- list's help mark, whose lines were a 0.8 gray. Through one helper they read:
--
--   * the titles `gtip.value` (white in all nine skins, so Ka0s Default draws exactly what it drew);
--   * the help mark's lines `gtip.body` (Ka0s Default's 0.9: the recorded shift D-14 accepts in
--     exchange for one tooltip palette across the collection);
--   * lines that named no color stay the client's (nil), as D-14 rules.
--
-- Only while the chrome is skinned: an owner-less page and an owner that ignores its settings panel
-- draw the literals the previous minors drew.

local K = _G.LK_TEST
local test, assertEqual, assertTrue =
  K.test, K.assertEqual, K.assertTrue
local F = dofile("tests/fixture_skin_paint.lua")
local installBindings = dofile("tests/_kit/mock_bindings.lua")

local OWNER, OTHER = "LootHistory", "BankLedger"
local OPTIONS = { "Options", "OptionsRegistry", "OptionsWidgets", "OptionsFlow", "OptionsIds", "OptionsIdSuggest", "OptionsIdList", "OptionsTabs",
                  "OptionsCombat", "OptionsCompose", "OptionsScroll", "OptionsNav", "OptionsDrawer",
                  "OptionsKeybinds" }

local WHITE, GRAY = "1,1,1,1", "0.800,0.800,0.800,1"

local function env()
  local files = {}
  for _, f in ipairs(F.FILES) do files[#files + 1] = f end
  files[#files + 1] = "Pool"
  for _, f in ipairs(OPTIONS) do files[#files + 1] = f end
  local m, Skin = F.env({ files = files })
  installBindings(m)
  m.BINDING_NAME_LKTIP_TOGGLE = "Toggle the tooltip bench"
  return m, Skin, m.LibStub("LibKa0s-Options-1.0")
end

local seq = 0
local function instance(lib, owner)
  seq = seq + 1
  local store = {}
  return lib:New({
    parentTitle = "Tip Host", mainPanelName = "TipHostMain" .. seq, addonName = owner,
    print = function() end,
    get = function(path) return store[path] end,
    set = function(path, value) store[path] = value end,
    applyDefault = function() end,
    rowsForPage = function() return {} end,
    allRows = function() return {} end,
  })
end

--- Every tooltip site on one page, by name: answers { name = function() fires its OnEnter end }.
local function sites(O)
  seq = seq + 1
  local ctx = O.CreatePanel("TipPage" .. seq, "Tip page", {})
  O.NavRail(ctx, { entries = { { key = "a", label = "Alpha", tooltip = "Nav tip." } }, value = "a" })
  O.TabStrip(ctx, { tabs = { { key = "x", label = "Ex", tooltip = "Tab tip." }, { key = "y", label = "Why" } },
                    value = "x" })
  O.Drawer(ctx, { label = "Content", summary = "Any", open = false, tooltip = "Drawer tip.", body = function() end })
  local plain = O.AceGUI:Create("Label")
  O.AttachTooltip(plain, "Row", "Row tip.")
  O.EnsureScroll(ctx).content.width = 1000
  O.IdList(ctx, { kind = "spell", entries = function() return { { id = 17, help = { "A note." } } } end })
  local rows = O.KeybindRows(ctx, { bindings = { { command = "LKTIP_TOGGLE" } } })
  local mark
  local function walk(w)
    if type(w) ~= "table" then return end
    if w.__helpTint then mark = w end
    for _, c in ipairs(w.children or {}) do walk(c) end
  end
  walk(ctx.scroll)
  local head
  for _, c in ipairs(ctx.scroll.children) do
    local h = c.children and c.children[1] and c.children[1].frame and c.children[1].frame.__ka0sDrawerHead
    if h then head = h end
  end
  local tab
  for _, k in ipairs(ctx.__tabKids) do
    if k.__ka0sTabArt and not tab then tab = k end
  end
  assertTrue(mark ~= nil and head ~= nil and tab ~= nil and rows and rows[1] ~= nil, "every site is drawn")
  local key = rows[1].slots[1]
  return {
    row = function() plain:__fire("OnEnter") end,
    drawer = function() head:__fire("OnEnter") end,
    nav = function() ctx.__railKids[1]:__fire("OnEnter") end,
    tab = function() tab:__fire("OnEnter") end,
    key = function() key.callbacks.OnEnter(key) end,
    help = function() mark:__fire("OnEnter") end,
  }
end

--- Fire `fire` with GameTooltip's SetText and AddLine recorded: each line's text and color, in order
--- (the color "nil" when the line named none).
local function hover(m, fire)
  local tip, seen = m.GameTooltip, {}
  local saved = { SetOwner = rawget(tip, "SetOwner"), SetText = rawget(tip, "SetText"),
                  AddLine = rawget(tip, "AddLine"), Show = rawget(tip, "Show") }
  local function rec(_, text, r, g, b)
    seen[#seen + 1] = { text = text, color = r == nil and "nil" or F.rgba({ r, g, b }) }
  end
  rawset(tip, "SetOwner", function() end)
  rawset(tip, "SetText", rec)
  rawset(tip, "AddLine", rec)
  rawset(tip, "Show", function() end)
  local ok, err = pcall(fire)
  for k, v in pairs(saved) do rawset(tip, k, v) end
  assertTrue(ok, tostring(err))
  return seen
end

local TITLED = { "row", "drawer", "nav", "tab", "key", "help" }

--- Every site's first line (the title) and, for the help mark, its note line.
local function colors(m, s)
  local out = {}
  for _, name in ipairs(TITLED) do
    local seen = hover(m, s[name])
    assertTrue(#seen >= 1, name .. " drew a tooltip")
    out[name] = seen[1].color
    if name == "help" then out.note = seen[2] and seen[2].color end
    if name ~= "help" then out[name .. "Body"] = seen[2] and seen[2].color end
  end
  return out
end

local function rgb(c) return F.rgba({ c[1], c[2], c[3] }) end

-- ── the literals, where the chrome is not skinned ─────────────────────────────────────────────

test("tooltip skin: an owner-less page writes the previous minors' tooltip literals", function()
  -- red under: a helper that reads Ka0s Default's tokens for a page with no registered owner.
  local m, _, lib = env()
  local c = colors(m, sites(instance(lib, OTHER)))
  for _, name in ipairs(TITLED) do assertEqual(c[name], WHITE, name .. "'s title") end
  assertEqual(c.note, GRAY, "the help mark's 0.8 lines")
end)

test("tooltip skin: an owner ignoring its settings panel gets the literals back", function()
  -- red under: tokens read with no regard to Ignore settings panel (the chrome stands down, its
  -- tooltips would not).
  local m, Skin, lib = env()
  F.owner(Skin, OWNER, "azeroth")
  Skin:ResolveSkin("azeroth")["gtip.value"] = { 0.2, 0.4, 0.6, 1 }
  local s = sites(instance(lib, OWNER))
  assertEqual(colors(m, s).row, "0.200,0.400,0.600,1", "skinned first")
  Skin:SetIgnore(OWNER, true, nil)
  local c = colors(m, s)
  for _, name in ipairs(TITLED) do assertEqual(c[name], WHITE, name .. "'s title") end
  assertEqual(c.note, GRAY, "the help mark's lines")
  Skin:SetIgnore(OWNER, false, nil)
  assertEqual(colors(m, s).help, "0.200,0.400,0.600,1", "and the skin back with the switch off")
end)

-- ── an owned page ────────────────────────────────────────────────────────────────────────────

test("tooltip skin: Ka0s Default's titles are white and the help mark's lines gtip.body", function()
  -- D-14: the titles exact; the note lines Ka0s Default's 0.9 (from 0.8), recorded.
  local m, Skin, lib = env()
  F.owner(Skin, OWNER)
  local c = colors(m, sites(instance(lib, OWNER)))
  for _, name in ipairs(TITLED) do assertEqual(c[name], WHITE, name .. "'s title") end
  assertEqual(c.note, rgb(Skin:ResolveSkin("ka0s")["gtip.body"]), "the help mark's lines")
  assertEqual(c.note, "0.900,0.900,0.900,1")
end)

test("tooltip skin: an owned page's titles take gtip.value and the help lines gtip.body", function()
  -- red under: any of the six sites keeping its literal. gtip.value is white in every shipped skin,
  -- so the case sets it to prove the read.
  local m, Skin, lib = env()
  F.owner(Skin, OWNER, "azeroth")
  local T = Skin:ResolveSkin("azeroth")
  T["gtip.value"] = { 0.2, 0.4, 0.6, 1 }
  local c = colors(m, sites(instance(lib, OWNER)))
  for _, name in ipairs(TITLED) do assertEqual(c[name], "0.200,0.400,0.600,1", name .. "'s title") end
  assertEqual(c.note, rgb(T["gtip.body"]), "Azeroth's tooltip body")
  assertTrue(c.note ~= GRAY, "not the literal")
end)

test("tooltip skin: lines that named no color stay the client's", function()
  -- D-14. red under: coloring a nil-colored line (the tooltip body of a row, drawer, nav entry, tab
  -- and key button).
  local m, Skin, lib = env()
  F.owner(Skin, OWNER, "ember")
  local c = colors(m, sites(instance(lib, OWNER)))
  for _, name in ipairs({ "row", "drawer", "nav", "tab", "key" }) do
    assertEqual(c[name .. "Body"], "nil", name .. "'s body line")
  end
end)

test("tooltip skin: a skin switch reaches the next hover with no rebuild", function()
  -- red under: a color captured at build or at dress.
  local m, Skin, lib = env()
  F.owner(Skin, OWNER, "obsidian")
  local s = sites(instance(lib, OWNER))
  Skin:ResolveSkin("contrast")["gtip.value"] = { 0.1, 0.3, 0.5, 1 }
  Skin:SetChoice(OWNER, "ka0s", "contrast")
  local c = colors(m, s)
  for _, name in ipairs(TITLED) do assertEqual(c[name], "0.100,0.300,0.500,1", name .. " after the switch") end
  assertEqual(c.note, rgb(Skin:ResolveSkin("contrast")["gtip.body"]))
end)
