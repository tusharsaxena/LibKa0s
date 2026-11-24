-- tests/test_widgets_menu_selected.lua — WidgetsDropdown minor 4 (FB2-LK-02 of
-- Ka0sAddonsCommonTasks docs/2026-11-24-FEEDBACK_BATCH, decision D3): a selected row's label always
-- stands visibly off a plain row's.
--
-- The owner, 2026-11-24, on Loot History's character dropdown: "current character is not
-- highlighted in gold. It uses the skin color. - in this specific case, make the current selected
-- always be a different color than the other texts - e.g. gold in ka0s default". A selected row
-- paints `menu.textSel`, which every skin but Ka0s Default maps to its accent; where that accent sits
-- near the skin's `menu.text`, the selection read like every other row.
--
-- THE RULE. The selected color is `menu.textSel` when it stands at least SEL_DE00_MIN (20, the
-- library's hover floor, the lowest pair the owner accepted; tests/fixture_de00.lua) CIEDE2000 off
-- `menu.text`; otherwise Ka0s Default's gold (1, 0.82, 0). The selected color replaces any value color
-- (`opt.color`: class, quality) the row would otherwise wear. A preset row (`isActive`,
-- "Character: Current") paints selected the same way. Every shipped skin is walked: the skins'
-- definitions (SkinDefs.lua, SkinDefsOthers.lua) resolved through Skin:ResolveSkin.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local F = dofile("tests/fixture_skin_paint.lua")
local D = dofile("tests/fixture_de00.lua")

local OWNER = "LootHistory"
local WFILES = { "Widgets", "WidgetsDropdown", "WidgetsReorder", "WidgetsDragHandle", "WidgetsDragHandleTip",
                 "WidgetsLineChart", "WidgetsAutocomplete", "WidgetsCopyWindow", "WidgetsHeader" }
local GOLD = { 1, 0.82, 0 }
local SEL_DE00_MIN = 20
-- The skins whose own `menu.textSel` stands too near their `menu.text`, so their selection is the
-- fallback gold. Azeroth's gold accent on its parchment text stands 16.3 off. Pinned, so a skin
-- edit that moves a pair across the floor is seen and named.
local FALLBACK_SKINS = "azeroth"

local function env()
  local files = {}
  for _, f in ipairs(F.FILES) do files[#files + 1] = f end
  for _, f in ipairs(WFILES) do files[#files + 1] = f end
  local m, Skin = F.env({ files = files })
  m.__cursorX, m.__cursorY = 100, 100
  return m, Skin, m.LibStub("LibKa0s-Widgets-1.0")
end

local function rgb(c) return ("%.3f,%.3f,%.3f"):format(c[1], c[2], c[3]) end

--- Open `dd`, answering the shared menu (captured the first time it is built).
local function open(m, dd, state)
  local saved = m.CreateFrame
  m.CreateFrame = function(...)
    local f = saved(...)
    state.menu = state.menu or f
    return f
  end
  dd:__fire("OnClick")
  m.CreateFrame = saved
  return state.menu
end

local function painted(m, row) return m.__paint(row.fs).textColor end

--- The color the rule answers for a skin's resolved tokens.
local function expectedSel(t)
  local sel, text = t["menu.textSel"], t["menu.text"]
  if D.de00(sel, text) >= SEL_DE00_MIN then return sel end
  return GOLD
end

local function skinKeys(Skin)
  local out = {}
  for _, def in ipairs(Skin:Skins()) do out[#out + 1] = def.key end
  return out
end

test("menu selected: every shipped skin's selected row stands off its plain row", function()
  -- red under: a skin whose menu.textSel sits within 20 ΔE00 of its menu.text (Azeroth, 16.3).
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "ka0s")
  local state = {}
  local keys = skinKeys(Skin)
  assertTrue(#keys >= 9, "every shipped skin walked, got " .. #keys)
  for _, key in ipairs(keys) do
    Skin:SetChoice(OWNER, "ka0s", key)
    local dd = W.Dropdown(m.UIParent, 120, { owner = OWNER })
    dd:SetOptions({ { value = "a", label = "A" }, { value = "b", label = "B" } })
    dd:SelectValue("a")
    local menu = open(m, dd, state)
    local sel, plain = painted(m, menu.buttons[1]), painted(m, menu.buttons[2])
    local t = Skin:ResolveSkin(key)
    assertEqual(rgb(plain), rgb(t["menu.text"]), key .. ": a plain row is menu.text")
    assertEqual(rgb(sel), rgb(expectedSel(t)), key .. ": the selected row is the rule's color")
    local d = D.de00(sel, plain)
    assertTrue(d >= SEL_DE00_MIN, ("%s: the selected row stands %.1f ΔE00 off a plain one, want >= %d")
      :format(key, d, SEL_DE00_MIN))
    W.CloseMenu()
  end
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
end)

test("menu selected: the skins that need the gold fallback are the pinned list", function()
  -- red under: a skin edit moving a selection pair across the floor without anyone seeing it.
  local _, Skin = env()
  local need = {}
  for _, key in ipairs(skinKeys(Skin)) do
    local t = Skin:ResolveSkin(key)
    if D.de00(t["menu.textSel"], t["menu.text"]) < SEL_DE00_MIN then need[#need + 1] = key end
  end
  table.sort(need)
  assertEqual(table.concat(need, ","), FALLBACK_SKINS)
end)

test("menu selected: Ka0s Default keeps its own gold, and Azeroth takes the gold fallback", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "azeroth")
  local state = {}
  local dd = W.Dropdown(m.UIParent, 120, { owner = OWNER })
  dd:SetOptions({ { value = "a", label = "A" }, { value = "b", label = "B" } })
  dd:SelectValue("b")
  local menu = open(m, dd, state)
  assertEqual(rgb(painted(m, menu.buttons[2])), rgb(GOLD), "Azeroth's selection is the fallback gold")
  W.CloseMenu()
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  menu = open(m, dd, state)
  assertEqual(rgb(painted(m, menu.buttons[2])), rgb(Skin:ResolveSkin("ka0s")["menu.textSel"]), "Ka0s Default's own")
  W.CloseMenu()
end)

test("menu selected: the selected color replaces a row's value color (class, quality)", function()
  -- red under: opt.color winning over the selection, so a class-colored current character reads
  -- like every other class-colored row.
  local m, Skin, W = env()
  local HUNTER = { 0.67, 0.83, 0.45 }
  local state = {}
  F.owner(Skin, OWNER, "ka0s")
  for _, key in ipairs({ "ka0s", "obsidian", "azeroth" }) do
    Skin:SetChoice(OWNER, "ka0s", key)
    local dd = W.Dropdown(m.UIParent, 120, { owner = OWNER })
    dd:SetOptions({ { value = "me", label = "Samplehunter", color = HUNTER },
                    { value = "alt", label = "Mockflame", color = { 0.25, 0.78, 0.92 } } })
    dd:SelectValue("me")
    local menu = open(m, dd, state)
    local t = Skin:ResolveSkin(key)
    assertEqual(rgb(painted(m, menu.buttons[1])), rgb(expectedSel(t)), key .. ": the selection, not the class")
    assertEqual(rgb(painted(m, menu.buttons[2])), rgb({ 0.25, 0.78, 0.92 }), key .. ": a plain row keeps its value color")
    W.CloseMenu()
  end
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
end)

test("menu selected: a preset row (isActive, Character: Current) paints selected the same way", function()
  -- red under: a preset row that lights in another color than a selected value row, or not at all.
  local m, Skin, W = env()
  local state = {}
  F.owner(Skin, OWNER, "ka0s")
  for _, key in ipairs(skinKeys(Skin)) do
    Skin:SetChoice(OWNER, "ka0s", key)
    local dd = W.Dropdown(m.UIParent, 120, { owner = OWNER })
    dd:SetOptions({
      { value = "current", label = "Character: Current", isActive = function() return true end },
      { value = "all", label = "Character: All", isActive = function() return false end },
      { value = "x", label = "Samplehunter", color = { 0.67, 0.83, 0.45 } },
    })
    dd:SelectValue("x")
    local menu = open(m, dd, state)
    local t = Skin:ResolveSkin(key)
    assertEqual(rgb(painted(m, menu.buttons[1])), rgb(expectedSel(t)), key .. ": the preset row is selected")
    assertEqual(rgb(painted(m, menu.buttons[2])), rgb(t["menu.text"]), key .. ": an inactive preset is plain")
    W.CloseMenu()
  end
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
end)

test("menu selected: a multi-select dropdown's selected rows follow the same rule", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "azeroth")
  local state = {}
  local dd = W.Dropdown(m.UIParent, 120, { owner = OWNER })
  dd:SetMulti(true)
  dd:SetOptions({ { value = "all", label = "Store: All" }, { value = "a", label = "A" }, { value = "b", label = "B" } })
  dd:SetSelected({ a = true })
  local menu = open(m, dd, state)
  assertEqual(rgb(painted(m, menu.buttons[2])), rgb(GOLD), "a selected value in Azeroth")
  assertEqual(rgb(painted(m, menu.buttons[3])), rgb(Skin:ResolveSkin("azeroth")["menu.text"]), "an unselected one")
  W.CloseMenu()
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
end)

test("menu selected: the rule's ΔE00 is the shared fixture's, and it answers textSel or the gold", function()
  -- red under: a payload ΔE00 that drifts from the suites' own (a wrong constant, a lost term).
  local _, _, W = env()
  local rule, de = W.__menuSelColor, W.__menuDE00
  assertEqual(type(rule), "function", "the internal test seam")
  local pairsOf = { { { 1, 0.82, 0 }, { 0.9, 0.9, 0.9 } }, { { 0.89, 0.71, 0.35 }, { 0.91, 0.87, 0.74 } },
                    { { 0.3, 0.72, 1 }, { 0.91, 0.91, 0.93 } }, { { 0, 0, 0 }, { 1, 1, 1 } }, { { 0.5, 0.5, 0.5 }, { 0.5, 0.5, 0.5 } } }
  for i, p in ipairs(pairsOf) do
    assertTrue(math.abs(de(p[1], p[2]) - D.de00(p[1], p[2])) < 0.01, "pair " .. i)
  end
  local blue = { 0.3, 0.72, 1, 1 }
  assertTrue(rule(blue, { 0.91, 0.91, 0.93, 1 }) == blue, "a distinct textSel is kept, the same table")
  assertEqual(rgb(rule({ 0.9, 0.9, 0.9, 1 }, { 0.9, 0.9, 0.9, 1 })), rgb(GOLD), "a textSel equal to text")
  assertEqual(rgb(rule({ 0.89, 0.71, 0.35, 1 }, { 0.91, 0.87, 0.74, 1 })), rgb(GOLD), "Azeroth's pair")
end)

test("menu selected: a ticked W.ContextMenu row (radio, selected) paints selected, not a tick beside plain text", function()
  -- red under: a tick or radio beside unchanged text, which the standard's skinning-§4 (v2.120.0,
  -- "a mark alone is not enough") rules out.
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "ka0s")
  local on = "two"
  local rows = { { label = "One", radio = true, selected = function() return on == "one" end },
                 { label = "Two", radio = true, selected = function() return on == "two" end },
                 { label = "Flag", selected = true }, { label = "Plain" } }
  for _, key in ipairs(skinKeys(Skin)) do
    Skin:SetChoice(OWNER, "ka0s", key)
    local menu = W.ContextMenu(m.CreateFrame("Frame", nil, m.UIParent), rows, { owner = OWNER })
    local t = Skin:ResolveSkin(key)
    local want = rgb(expectedSel(t))
    assertEqual(rgb(painted(m, menu.buttons[1])), rgb(t["menu.text"]), key .. ": an unticked radio is plain")
    assertEqual(rgb(painted(m, menu.buttons[2])), want, key .. ": the ticked radio is selected")
    assertEqual(rgb(painted(m, menu.buttons[3])), want, key .. ": a selected = true row is selected")
    assertEqual(rgb(painted(m, menu.buttons[4])), rgb(t["menu.text"]), key .. ": a plain row is plain")
    W.CloseMenu()
  end
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  local menu = W.ContextMenu(m.CreateFrame("Frame", nil, m.UIParent), rows)
  assertEqual(rgb(painted(m, menu.buttons[2])), rgb(GOLD), "an owner-less menu's ticked row is the gold")
  W.CloseMenu()
end)
