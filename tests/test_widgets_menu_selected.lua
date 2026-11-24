-- tests/test_widgets_menu_selected.lua — WidgetsDropdown minor 4 (FB2-LK-02 of
-- Ka0sAddonsCommonTasks docs/2026-11-24-FEEDBACK_BATCH, decision D3): a selected row's label always
-- stands visibly off a plain row's.
--
-- The owner, 2026-11-24, on Loot History's character dropdown: "current character is not
-- highlighted in gold. It uses the skin color. - in this specific case, make the current selected
-- always be a different color than the other texts - e.g. gold in ka0s default". A selected row
-- painted `menu.textSel`, which every skin but Ka0s Default maps to its accent; where that accent sits
-- near the skin's `menu.text`, the selection read like every other row. Round 2 kept the accent while
-- it stood 20 CIEDE2000 off; the owner then saw WoW Forever's tan accent on Loot History's Character
-- dropdown and ruled (2026-11-24) that the issue "has not been fixed", and of the gold: "leave it as
-- gold".
--
-- THE RULE (the owner's ruling). The selected color is Ka0s Default's gold (1, 0.82, 0) in EVERY
-- skin. Only where the gold itself stands under SEL_DE00_MIN (20, the library's hover floor, the
-- lowest pair the owner accepted; tests/fixture_de00.lua) CIEDE2000 off the skin's `menu.text` does
-- the skin's `menu.textSel` stand in, and when that is under the floor too, the gold. A title row
-- keeps the skin's raw `menu.textSel`. The selected color replaces any value color
-- (`opt.color`: class, quality) the row would otherwise wear. A preset row (`isActive`,
-- "Character: Current") paints selected the same way. Every shipped skin is walked: the skins'
-- definitions (SkinDefs.lua, SkinDefsOthers.lua) resolved through Skin:ResolveSkin. W.SelectedColor(owner)
-- (FB2-LK-REV) answers the same color for a menu a host draws itself.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local F = dofile("tests/fixture_skin_paint.lua")
local D = dofile("tests/fixture_de00.lua")

local OWNER = "LootHistory"
local WFILES = { "Widgets", "WidgetsDropdown", "WidgetsReorder", "WidgetsDragHandle", "WidgetsDragHandleTip",
                 "WidgetsLineChart", "WidgetsAutocomplete", "WidgetsCopyWindow", "WidgetsHeader" }
local GOLD = { 1, 0.82, 0 }
local SEL_DE00_MIN = 20
-- The skins whose `menu.text` stands too near the gold, so their selection falls back to their own
-- `menu.textSel`. None of the nine shipped skins today: the nearest is Azeroth's parchment text, 20.7
-- off the gold (Ember 26.5, Ka0s Default 29.5; the rest 30 and over). Pinned, so a skin edit that
-- moves a skin's text across the floor is seen and named.
local FALLBACK_SKINS = ""

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

--- The color the rule answers for a skin's resolved tokens: the gold, else the skin's own
--- `menu.textSel` where the gold sits under the floor off `menu.text` and the skin's own does not.
local function expectedSel(t)
  local sel, text = t["menu.textSel"], t["menu.text"]
  if D.de00(GOLD, text) >= SEL_DE00_MIN then return GOLD end
  if D.de00(sel, text) >= SEL_DE00_MIN then return sel end
  return GOLD
end

--- True for a skin pinned in FALLBACK_SKINS.
local function fallsBack(key)
  for k in FALLBACK_SKINS:gmatch("[^,]+") do if k == key then return true end end
  return false
end

local function skinKeys(Skin)
  local out = {}
  for _, def in ipairs(Skin:Skins()) do out[#out + 1] = def.key end
  return out
end

test("menu selected: every shipped skin's selected row is the gold, standing off its plain row", function()
  -- red under: a skin's own accent kept for the selection (WoW Forever's tan, the owner's 2026-11-24
  -- screenshot), or a skin whose selection sits within 20 ΔE00 of its menu.text.
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
    if not fallsBack(key) then assertEqual(rgb(sel), rgb(GOLD), key .. ": the selected row is the gold") end
    local d = D.de00(sel, plain)
    assertTrue(d >= SEL_DE00_MIN, ("%s: the selected row stands %.1f ΔE00 off a plain one, want >= %d")
      :format(key, d, SEL_DE00_MIN))
    W.CloseMenu()
  end
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
end)

test("menu selected: the skins whose text is too near the gold are the pinned list", function()
  -- red under: a skin edit moving a skin's menu.text across the gold's floor without anyone seeing it.
  local _, Skin = env()
  local need = {}
  for _, key in ipairs(skinKeys(Skin)) do
    local t = Skin:ResolveSkin(key)
    if D.de00(GOLD, t["menu.text"]) < SEL_DE00_MIN then need[#need + 1] = key end
  end
  table.sort(need)
  assertEqual(table.concat(need, ","), FALLBACK_SKINS)
end)

test("menu selected: WoW Forever paints the gold, not its tan accent, and a title keeps the accent", function()
  -- red under: the owner's 2026-11-24 screenshot, Loot History's Character dropdown on WoW Forever
  -- with its selected rows in the skin's tan `menu.textSel` (27 ΔE00 off white, kept by round 2).
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "forever")
  local state = {}
  local t = Skin:ResolveSkin("forever")
  assertTrue(rgb(t["menu.textSel"]) ~= rgb(GOLD), "WoW Forever's accent is not the gold")
  local dd = W.Dropdown(m.UIParent, 120, { owner = OWNER })
  dd:SetOptions({ { title = true, label = "Characters" }, { value = "a", label = "A" }, { value = "b", label = "B" } })
  dd:SelectValue("b")
  local menu = open(m, dd, state)
  assertEqual(rgb(painted(m, menu.buttons[3])), rgb(GOLD), "WoW Forever's selection is the gold")
  assertEqual(rgb(painted(m, menu.buttons[1])), rgb(t["menu.textSel"]), "a title row keeps the skin's raw menu.textSel")
  W.CloseMenu()
  for _, key in ipairs({ "azeroth", "ka0s" }) do
    Skin:SetChoice(OWNER, "ka0s", key)
    menu = open(m, dd, state)
    assertEqual(rgb(painted(m, menu.buttons[3])), rgb(GOLD), key .. "'s selection is the gold")
    W.CloseMenu()
  end
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
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

test("menu selected: the rule's ΔE00 is the shared fixture's, and it answers the gold or textSel", function()
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
  assertEqual(rgb(rule(blue, { 0.91, 0.91, 0.93, 1 })), rgb(GOLD), "a distinct textSel still yields to the gold")
  assertEqual(rgb(rule({ 0.79, 0.63, 0.48, 1 }, { 1, 1, 1, 1 })), rgb(GOLD), "WoW Forever's tan on white: the gold")
  assertEqual(rgb(rule({ 0.9, 0.9, 0.9, 1 }, { 0.9, 0.9, 0.9, 1 })), rgb(GOLD), "a textSel equal to text")
  assertEqual(rgb(rule({ 0.89, 0.71, 0.35, 1 }, { 0.91, 0.87, 0.74, 1 })), rgb(GOLD), "Azeroth's pair")
  local goldText = { 1, 0.85, 0.1, 1 }
  assertTrue(D.de00(GOLD, goldText) < SEL_DE00_MIN, "the probe text sits near the gold")
  assertTrue(rule(blue, goldText) == blue, "text near the gold: the skin's own textSel stands in, the same table")
  assertEqual(rgb(rule({ 1, 0.8, 0.05, 1 }, goldText)), rgb(GOLD), "both under the floor: the gold")
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

test("menu selected: W.SelectedColor(owner) answers the color the shared menu paints, for a host's own menu", function()
  -- red under: no public surface, so a host menu that reads the raw `menu.textSel` token (the
  -- standard's skinning-§4 before FB2-LK-REV) paints the skin's accent (WoW Forever's tan), not the gold.
  local m, Skin, W = env()
  assertEqual(type(W.SelectedColor), "function", "the public member")
  F.owner(Skin, OWNER, "ka0s")
  local state = {}
  for _, key in ipairs(skinKeys(Skin)) do
    Skin:SetChoice(OWNER, "ka0s", key)
    local dd = W.Dropdown(m.UIParent, 120, { owner = OWNER })
    dd:SetOptions({ { value = "a", label = "A" }, { value = "b", label = "B" } })
    dd:SelectValue("a")
    local menu = open(m, dd, state)
    local r, g, b = W.SelectedColor(OWNER)
    assertEqual(rgb({ r, g, b }), rgb(painted(m, menu.buttons[1])), key .. ": the shared menu's own selected color")
    assertEqual(rgb({ r, g, b }), rgb(expectedSel(Skin:ResolveSkin(key))), key .. ": the rule's color")
    W.CloseMenu()
  end
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  for _, owner in ipairs({ "NotAnOwner", "" }) do
    local r, g, b = W.SelectedColor(owner)
    assertEqual(rgb({ r, g, b }), rgb(GOLD), "an unregistered owner reads Ka0s Default's gold")
  end
  local r, g, b = W.SelectedColor()
  assertEqual(rgb({ r, g, b }), rgb(GOLD), "no owner reads Ka0s Default's gold")
end)
