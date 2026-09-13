-- tests/test_options_idsuggest.lua — LibKa0s-Options-1.0's IdInput suggestions (OptionsWidgets
-- minor 16, issue #31): the dropdown under the edit box that lists matching names while the player
-- types.
--
-- Adding by name used to work only for a player who already knew the exact name, and it gave no way
-- to pick between items or spells that share one across ranks. The owner typed "Potion of the Hushed
-- Zephyr" (three crafted-quality ranks, none in the bags) into ConsumableMaster's Add-by-ID and read
-- "No item matches". The dropdown lists every rank as its own row; Enter on a shared name WITHOUT a
-- pick still refuses it, so one rank is never added silently.
--
-- A suite of its own rather than more cases in tests/test_options_widgets.lua, which is over
-- layout-§1's cap with issue #8 open on it.
--
-- The dropdown is a frame of the library's, not an AceGUI widget, so a case finds it among the
-- frames CreateFrame handed out: the one carrying `rows`. What each row shows is read off the
-- library's own record on it (`row.entry`, `row.labelText`), because the kit's frame stub answers a
-- FontString with the frame itself and keeps no text.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local Fixture = dofile("tests/fixture_options.lua")
local mocks = T.mocks

local ZEPHYR = "Potion of the Hushed Zephyr"
local GRAY = "|cff808080"
local WHITE = "|cffffffff"
local function atlas(tier) return ("|A:Professions-Icon-Quality-Tier%d-Small:14:14|a"):format(tier) end

--- A case with every frame CreateFrame hands out recorded (`made`), on empty id records and an
--- empty timer queue, both emptied again however it ends.
local function suggestCase(name, fn)
  test(name, function()
    local real = mocks.CreateFrame
    local made = {}
    mocks.CreateFrame = function(...)
      local f = real(...)
      made[#made + 1] = f
      return f
    end
    mocks.clearIdRecords()
    mocks.__timers = {}
    local ok, err = pcall(fn, made)
    mocks.CreateFrame = real
    mocks.clearIdRecords()
    mocks.__timers = {}
    if not ok then error(err, 0) end
  end)
end

local seq = 0
--- One IdInput on a fresh instance and page, recording every onAdd.
local function input(made, spec, O)
  O = O or Fixture.new()
  seq = seq + 1
  local ctx = O.CreatePanel("SuggestBench" .. seq, "Suggest " .. seq, {})
  local added = {}
  spec.onAdd = spec.onAdd or function(id) added[#added + 1] = id end
  local _, eb, add, status = O.IdInput(ctx, nil, spec)
  return { O = O, ctx = ctx, eb = eb, add = add, status = status, added = added, made = made }
end

--- The dropdown: the one frame carrying `rows`.
local function dropdown(made)
  for _, f in ipairs(made) do
    if type(f.rows) == "table" then return f end
  end
end

local function shown(b)
  local dd = dropdown(b.made)
  return dd ~= nil and dd:IsShown()
end

--- Type into the box as AceGUI's EditBox reports it, then let the debounce run.
local function typeText(b, text)
  b.eb:SetText(text)
  b.eb:__fire("OnTextChanged", text)
  mocks.__fireTimers()
end

--- The ids the dropdown's visible rows carry, in order; "" while it is hidden.
local function shownIds(b)
  if not shown(b) then return "" end
  local ids = {}
  for _, row in ipairs(dropdown(b.made).rows) do
    if row:IsShown() and row.entry then ids[#ids + 1] = row.entry.id end
  end
  return table.concat(ids, ",")
end

local function press(b, key) b.eb.editbox:__fire("OnArrowPressed", key) end

--- The three ranks, cached, with their crafted-quality tiers.
local function seedZephyr()
  for tier, id in ipairs({ 191395, 191396, 191397 }) do
    mocks.addIdRecord("item", id, ZEPHYR, 4638, nil, 1)
    mocks.setCraftedQuality(id, tier)
  end
end
local function zephyrs() return { 191397, 191395, 191396 } end

-- ── ordering ─────────────────────────────────────────────────────────────────────────────────

suggestCase("IdInput suggestions: exact, then prefix, then a word, then anywhere; shorter first", function(made)
  local names = {
    [1001] = "Mana Potion", [1002] = "Potion", [1003] = "Potion of Speed",
    [1004] = "Greater Potion", [1005] = "Superpotion", [1006] = "Potion of Power",
    [1007] = "Potions", [1008] = "Minor Potion", [1009] = "Elixir",
  }
  local ids = {}
  for id, name in pairs(names) do
    mocks.addIdRecord("item", id, name, 1)
    ids[#ids + 1] = id
  end
  local b = input(made, { kind = "item", candidates = function() return ids end })
  typeText(b, "potion")
  -- red under: no suggestions at all (a player had to know the exact name)
  assertEqual(shownIds(b), "1002,1007,1006,1003,1001,1008,1004,1005",
    "exact; prefix by length then name; word by length; anywhere")
  typeText(b, "POTION")
  assertEqual(shownIds(b), "1002,1007,1006,1003,1001,1008,1004,1005", "case does not matter")
end)

suggestCase("IdInput suggestions: one name's rows sort by rank, then by id", function(made)
  mocks.addIdRecord("item", 3001, "Elixir of Wit", 1)
  mocks.addIdRecord("item", 3002, "Elixir of Wit", 1)
  mocks.addIdRecord("item", 3003, "Elixir of Wit", 1)
  mocks.setCraftedQuality(3001, 2); mocks.setCraftedQuality(3002, 2); mocks.setCraftedQuality(3003, 1)
  mocks.addIdRecord("item", 4002, "Elixir of Wisdom", 1)
  mocks.addIdRecord("item", 4001, "Elixir of Wisdom", 1)
  local b = input(made, { kind = "item", candidates = function() return { 4002, 3002, 4001, 3001, 3003 } end })
  typeText(b, "elixir of wi")
  -- red under: a sort with no rank or id step (a shared name's rows would come out in host order)
  assertEqual(shownIds(b), "3003,3001,3002,4001,4002")
end)

suggestCase("IdInput suggestions: at most ten rows, then a line saying how many were left out", function(made)
  local ids = {}
  for i = 1, 13 do
    mocks.addIdRecord("item", 5000 + i, ("Arrow %02d"):format(i), 1)
    ids[i] = 5000 + i
  end
  local b = input(made, { kind = "item", candidates = function() return ids end })
  typeText(b, "arrow")
  local dd = dropdown(made)
  -- red under: no cap (thirteen rows under a box)
  assertEqual(shownIds(b), "5001,5002,5003,5004,5005,5006,5007,5008,5009,5010")
  assertTrue(dd.more:IsShown()); assertEqual(dd.more.labelText, "+3 more")
  for _ = 1, 11 do press(b, "DOWN") end
  -- red under: the "+N more" line taking the highlight
  assertTrue(dd.rows[1].selected, "the eleventh Down wraps to the first row, not the more line")
  dd.more:__fire("OnClick")
  assertEqual(#b.added, 0, "the more line adds nothing")

  local c = input(made, { kind = "item", candidates = function() return ids end,
                          strings = { more = "{count} de plus" } }, b.O)
  typeText(c, "arrow")
  assertEqual(dd.more.labelText, "3 de plus", "the host can reword it")
  typeText(c, "arrow 1")
  assertEqual(shownIds(c), "5010,5011,5012,5013")
  assertFalse(dd.more:IsShown(), "no more line when nothing is left out")
end)

suggestCase("IdInput suggestions: digits match ids by prefix; a name needs two letters", function(made)
  mocks.addIdRecord("item", 19019, "Thunderfury", 1, nil, 5)
  mocks.addIdRecord("item", 6948, "Hearthstone", 1, nil, 1)
  seedZephyr()
  local b = input(made, { kind = "item", candidates = function() return { 6948, 191396, 19019, 191395 } end })
  typeText(b, "19")
  -- red under: digits matched against names (an id prefix would find nothing)
  assertEqual(shownIds(b), "19019,191395,191396", "ascending")
  typeText(b, "191")
  assertEqual(shownIds(b), "191395,191396")
  typeText(b, "6")
  assertEqual(shownIds(b), "6948", "one digit is enough")
  typeText(b, "z")
  assertEqual(shownIds(b), "", "one letter is not")
  typeText(b, "ze")
  assertEqual(shownIds(b), "191395,191396")
end)

-- ── ranks ────────────────────────────────────────────────────────────────────────────────────

suggestCase("IdInput suggestions: every rank is its own row, labeled, beside the others", function(made)
  seedZephyr()
  mocks.addIdRecord("item", 100, "Zephyr Draught", 1, nil, 1)
  mocks.addIdRecord("item", 102, "Zephyr Dust", 1, nil, 1)
  mocks.setReagentQuality(102, 2)
  local b = input(made, { kind = "item", candidates = function()
    local ids = zephyrs(); ids[#ids + 1] = 100; ids[#ids + 1] = 102; return ids end })
  typeText(b, "zephyr")
  -- red under: one row per name (the player could not pick a rank)
  assertEqual(shownIds(b), "102,100,191395,191396,191397")
  local rows = dropdown(made).rows
  assertEqual(rows[1].labelText, WHITE .. "Zephyr Dust|r " .. atlas(2) .. " " .. GRAY .. "(102)|r",
    "a reagent tier is a rank too")
  assertEqual(rows[2].labelText, WHITE .. "Zephyr Draught|r " .. GRAY .. "(100)|r",
    "no tier: the id alone tells it apart")
  for i, tier in ipairs({ 1, 2, 3 }) do
    assertEqual(rows[i + 2].labelText, WHITE .. ZEPHYR .. "|r " .. atlas(tier) .. " " .. GRAY ..
      "(" .. (191394 + tier) .. ")|r")
  end
  assertEqual(rows[3].entry.icon, 4638, "each row carries its icon")
end)

suggestCase("IdInput suggestions: a spell's rank is the client's subtext", function(made)
  mocks.addIdRecord("spell", 900001, "Twin Strike", 11)
  mocks.addIdRecord("spell", 900002, "Twin Strike", 12)
  mocks.setSpellSubtext(900001, "Rank 2")
  mocks.setSpellSubtext(900002, "Rank 1")
  local b = input(made, { kind = "spell", candidates = function() return { 900001, 900002 } end })
  typeText(b, "twin")
  assertEqual(shownIds(b), "900002,900001")
  assertEqual(dropdown(made).rows[1].labelText, "Twin Strike Rank 1 " .. GRAY .. "(900002)|r",
    "spell names are drawn plain, as IdList draws them")
end)

-- ── picking ──────────────────────────────────────────────────────────────────────────────────

suggestCase("IdInput suggestions: a click adds that row's id once, through onAdd, and closes", function(made)
  seedZephyr()
  local b = input(made, { kind = "item", candidates = zephyrs })
  typeText(b, "zephyr")
  local dd = dropdown(made)
  dd.rows[2]:__fire("OnClick")
  -- red under: a row that is not clickable (the player could see the rank and not take it)
  assertEqual(table.concat(b.added, ","), "191396")
  assertEqual(b.eb.text, "", "the box is cleared, as a typed add clears it")
  assertEqual(b.status.text, "")
  assertFalse(dd:IsShown())
  assertEqual(#mocks.__timers, 0, "no lookup: a picked row names one id")
end)

suggestCase("IdInput suggestions: Up and Down move the highlight, and Enter adds it", function(made)
  seedZephyr()
  local b = input(made, { kind = "item", candidates = zephyrs })
  typeText(b, "zephyr")
  local rows = dropdown(made).rows
  press(b, "DOWN"); press(b, "DOWN")
  assertTrue(rows[2].selected); assertFalse(rows[1].selected)
  press(b, "UP"); press(b, "UP")
  assertTrue(rows[3].selected, "Up from the first row wraps to the last")
  b.eb:__fire("OnEnterPressed", b.eb.text)
  -- red under: Enter resolving the typed name (a shared name would be refused, not the pick taken)
  assertEqual(table.concat(b.added, ","), "191397")
  assertEqual(b.status.text, "")
  typeText(b, "zephyr")
  press(b, "UP")
  assertTrue(rows[3].selected, "Up with nothing highlighted takes the last row")
  press(b, "LEFT")
  assertTrue(rows[3].selected, "Left and Right stay the cursor's")
end)

suggestCase("IdInput suggestions: Enter with no row highlighted still refuses a shared name", function(made)
  seedZephyr()
  local b = input(made, { kind = "item", candidates = zephyrs })
  typeText(b, ZEPHYR)
  assertEqual(shownIds(b), "191395,191396,191397")
  b.eb:__fire("OnEnterPressed", ZEPHYR)
  -- red under: Enter taking the first row (one rank added silently, which the owner ruled out)
  assertEqual(#b.added, 0, "neither one rank nor all of them")
  assertEqual(b.status.text, "Several items are named '" .. ZEPHYR ..
    "' \226\128\148 pick one from the list, or use the id.")
  -- red under: the dropdown closed by the submit (the refusal pointed at a list that was not there)
  assertEqual(shownIds(b), "191395,191396,191397", "the ranks the refusal points at stay listed")
  b.eb:__fire("OnEnterPressed", ZEPHYR)
  assertEqual(#b.added, 0, "a second Enter with nothing highlighted still adds nothing")
  assertEqual(shownIds(b), "191395,191396,191397")
  press(b, "DOWN"); press(b, "DOWN")
  b.eb:__fire("OnEnterPressed", ZEPHYR)
  assertEqual(table.concat(b.added, ","), "191396", "Down, Down, Enter takes the second rank")
  typeText(b, "zephyr")
  b.eb:__fire("OnEnterPressed", "zephyr")
  assertFalse(shown(b), "a submit the list cannot help closes it")
  typeText(b, "zephyr")
  b.add:__fire("OnClick")
  assertFalse(shown(b), "and so does Add")
end)

suggestCase("IdInput suggestions: a shared name refused by Add, or before the pause, lists its ranks", function(made)
  seedZephyr()
  local b = input(made, { kind = "item", candidates = zephyrs })
  b.eb:SetText(ZEPHYR); b.eb:__fire("OnTextChanged", ZEPHYR)
  b.eb:__fire("OnEnterPressed", ZEPHYR)
  -- red under: only the debounce showing the list (a paste then Enter never showed it at all)
  assertEqual(shownIds(b), "191395,191396,191397", "Enter inside the 0.1 s pause")
  mocks.__fireTimers()
  assertEqual(shownIds(b), "191395,191396,191397", "and the dropped update does not close it")

  local c = input(made, { kind = "item", candidates = zephyrs }, b.O)
  local focused = 0
  c.eb.SetFocus = function() focused = focused + 1 end
  typeText(c, ZEPHYR)
  c.add:__fire("OnClick")
  assertEqual(#c.added, 0)
  assertEqual(shownIds(c), "191395,191396,191397", "Add refuses and lists them too")
  assertEqual(focused, 1, "and hands the box the keys, so Up, Down and Enter pick")
end)

suggestCase("IdInput suggestions: a shared name refused after a lookup lists its ranks", function(made)
  for _, id in ipairs(zephyrs()) do mocks.addIdRecord("item", id, ZEPHYR, 4638, true, 1) end
  local b = input(made, { kind = "item", candidates = zephyrs })
  typeText(b, ZEPHYR)
  b.eb:__fire("OnEnterPressed", ZEPHYR)
  assertEqual(b.status.text, "Looking up items\226\128\166")
  seedZephyr()
  mocks.__fireTimers()
  assertEqual(#b.added, 0)
  -- red under: the lookup's refusal leaving the list closed
  assertEqual(shownIds(b), "191395,191396,191397")

  local c = input(made, { kind = "item", candidates = zephyrs }, b.O)
  for _, id in ipairs(zephyrs()) do mocks.addIdRecord("item", id, ZEPHYR, 4638, true, 1) end
  typeText(c, ZEPHYR)
  c.eb:__fire("OnEnterPressed", ZEPHYR)
  c.eb.editbox.HasFocus = function() return false end
  c.eb.editbox:__fire("OnEditFocusLost")
  seedZephyr()
  mocks.__fireTimers()
  assertEqual(shownIds(c), "", "a player who left the box is not handed a list")
  c.eb.editbox.HasFocus = nil
  c.eb.editbox:__fire("OnEditFocusGained")
  assertEqual(shownIds(c), "191395,191396,191397", "coming back to the box brings it")
end)

suggestCase("IdList suggestions: a pick reaches onAdd and rebuilds the list", function(made)
  seedZephyr()
  local O = Fixture.new()
  local ctx = O.CreatePanel("SuggestList", "Suggest list", {})
  local added, rebuilt = {}, 0
  ctx.rebuild = function() rebuilt = rebuilt + 1 end
  O.IdList(ctx, { kind = "item", candidates = zephyrs, entries = function() return {} end,
                  onAdd = function(id) added[#added + 1] = id end })
  local created = mocks.__libs["AceGUI-3.0"].__created
  local eb
  for i = #created, 1, -1 do
    if created[i].type == "EditBox" then eb = created[i]; break end
  end
  local b = { eb = eb, made = made }
  typeText(b, "zephyr")
  dropdown(made).rows[1]:__fire("OnClick")
  assertEqual(table.concat(added, ","), "191395")
  assertEqual(rebuilt, 1, "the list is drawn again with its new entry")
end)

-- ── closing ──────────────────────────────────────────────────────────────────────────────────

suggestCase("IdInput suggestions: Escape, focus loss, a hidden panel and a release close it", function(made)
  seedZephyr()
  local b = input(made, { kind = "item", candidates = zephyrs })
  typeText(b, "zephyr")
  local dd = dropdown(made)
  assertTrue(dd:IsShown())
  b.eb.editbox:__fire("OnEscapePressed")
  -- red under: a dropdown nothing closes (it would sit over the panel after the player moved on)
  assertFalse(dd:IsShown(), "Escape")
  typeText(b, "zephyr")
  dd.IsMouseOver = function() return true end
  b.eb.editbox:__fire("OnEditFocusLost")
  assertTrue(dd:IsShown(), "focus lost to a click on the dropdown keeps it for the click")
  dd.IsMouseOver = nil
  b.eb.editbox:__fire("OnEditFocusLost")
  assertFalse(dd:IsShown(), "focus lost anywhere else")
  typeText(b, "zephyr")
  b.eb.frame:__fire("OnHide")
  assertFalse(dd:IsShown(), "the box hidden with its panel")
  b.eb.frame:Show()
  typeText(b, "zephyr")
  assertTrue(dd:IsShown(), "the panel shown again suggests again")
  b.eb:Release()
  assertFalse(dd:IsShown(), "the box released by a re-render")
  press(b, "DOWN")
  b.eb.editbox:__fire("OnEscapePressed")
  assertEqual(#b.added, 0, "a released box's keys reach nothing")
end)

suggestCase("IdInput suggestions: typing is debounced, and a released box's pending update is dropped", function(made)
  seedZephyr()
  local b = input(made, { kind = "item", candidates = zephyrs })
  b.eb:SetText("ze"); b.eb:__fire("OnTextChanged", "ze")
  -- red under: computed on every keystroke rather than once the typing pauses
  assertNil(dropdown(made), "nothing until the pause")
  mocks.__fireTimers()
  local dd = dropdown(made)
  local shows = 0
  local realShow = dd.Show
  dd.Show = function(self) shows = shows + 1; return realShow(self) end
  for _, text in ipairs({ "zep", "zeph", "zephy" }) do b.eb:SetText(text); b.eb:__fire("OnTextChanged", text) end
  mocks.__fireTimers()
  assertEqual(shows, 1, "three keystrokes, one update")
  b.eb:SetText("zephyr"); b.eb:__fire("OnTextChanged", "zephyr")
  b.eb:Release()
  mocks.__fireTimers()
  assertEqual(shows, 1, "a released box is not updated")
  assertFalse(dd:IsShown())
end)

-- ── sources ──────────────────────────────────────────────────────────────────────────────────

suggestCase("IdInput suggestions: items in the bags and spells in the spellbook need no candidates", function(made)
  mocks.addIdRecord("item", 6948, "Hearthstone", 134414, nil, 1)
  mocks.addIdRecord("item", 19019, "Thunderfury", 135349, nil, 5)
  mocks.setBagItems(0, { 6948 })
  mocks.setBagItems(4, { false, 19019, 6948 })
  local b = input(made, { kind = "item" })
  typeText(b, "hearth")
  -- red under: the host's candidates as the only source (an item in the bags would not be offered)
  assertEqual(shownIds(b), "6948", "a stack in two bags is one row")
  typeText(b, "thunder")
  dropdown(made).rows[1]:__fire("OnClick")
  assertEqual(table.concat(b.added, ","), "19019")

  mocks.addIdRecord("spell", 21562, "Power Word: Fortitude", 135987)
  mocks.addIdRecord("spell", 774, "Rejuvenation", 136081)
  mocks.setSpellBook({ 21562, 774 })
  local s = input(made, { kind = "spell" }, b.O)
  typeText(s, "fort")
  assertEqual(shownIds(s), "21562")

  mocks.addIdRecord("currency", 3008, "Valorstones", 5872049)
  local c = input(made, { kind = "currency", candidates = function() return { 3008 } end }, b.O)
  typeText(c, "valor")
  assertEqual(shownIds(c), "3008", "a currency has the host's candidates alone")
end)

suggestCase("IdInput suggestions: a missing source, a raising candidates() or no info costs nothing", function(made)
  mocks.addIdRecord("item", 6948, "Hearthstone", 134414, nil, 1)
  mocks.setBagItems(0, { 6948 })
  local O = Fixture.new()
  local savedBags, savedBook, savedTrade = mocks.C_Container, mocks.C_SpellBook, mocks.C_TradeSkillUI
  mocks.C_Container, mocks.C_SpellBook, mocks.C_TradeSkillUI = nil, nil, nil
  local ok, err = pcall(function()
    local b = input(made, { kind = "item", candidates = function() return { 6948 } end }, O)
    typeText(b, "hearth")
    -- red under: an unguarded C_Container or C_TradeSkillUI (the input raises on such a client)
    assertEqual(shownIds(b), "6948")
    local s = input(made, { kind = "spell" }, O)
    typeText(s, "fort")
    assertEqual(shownIds(s), "", "a spell kind with no spellbook and no candidates lists nothing")
  end)
  mocks.C_Container, mocks.C_SpellBook, mocks.C_TradeSkillUI = savedBags, savedBook, savedTrade
  assertTrue(ok, tostring(err))

  local r = input(made, { kind = "item", candidates = function() error("boom") end }, O)
  typeText(r, "hearth")
  assertEqual(shownIds(r), "6948", "a raising candidates() costs the candidates, not the bags")
  local h = input(made, { kind = { noun = "thing", resolve = function() return nil end },
                          candidates = function() return { 6948 } end }, O)
  typeText(h, "hearth")
  assertEqual(shownIds(h), "", "a host kind with no info has nothing to name a row with")
end)

suggestCase("IdInput suggestions: an uncached candidate joins the list once it is named", function(made)
  for _, id in ipairs(zephyrs()) do mocks.addIdRecord("item", id, ZEPHYR, 4638, true, 1) end
  mocks.__loadRequests = {}
  local b = input(made, { kind = "item", candidates = zephyrs })
  assertTrue(mocks.__loadRequests[191395] and mocks.__loadRequests[191397], "drawing asked for them")
  typeText(b, "zephyr")
  assertEqual(shownIds(b), "", "no name to match yet")
  seedZephyr()
  typeText(b, "zephyr")
  -- red under: names cached once per render and never re-read (a load would never reach the list)
  assertEqual(shownIds(b), "191395,191396,191397")
end)

-- ── frames ───────────────────────────────────────────────────────────────────────────────────

suggestCase("IdInput suggestions: one dropdown per instance, whatever the renders", function(made)
  seedZephyr()
  local b = input(made, { kind = "item", candidates = zephyrs })
  typeText(b, "zephyr")
  local dd = dropdown(made)
  assertEqual(#dd.rows, 10, "ten pooled rows, built once")
  b.eb:Release()
  local c = input(made, { kind = "item", candidates = zephyrs }, b.O)
  local before = #made   -- after the second page's own frames
  typeText(c, "zephyr")
  -- red under: a dropdown built per render (every redraw would leak eleven frames)
  assertEqual(#made, before, "the second render builds no frame")
  assertTrue(dd:IsShown())
  local count = 0
  for _, f in ipairs(made) do if type(f.rows) == "table" then count = count + 1 end end
  assertEqual(count, 1)
  b.eb.editbox:__fire("OnEscapePressed")
  assertTrue(dd:IsShown(), "the first render's box no longer owns it")
  typeText(c, "zephyr")
  assertEqual(shownIds(c), "191395,191396,191397")
end)

suggestCase("IdInput suggestions: a box pooled into a second render is hooked once", function(made)
  seedZephyr()
  local b = input(made, { kind = "item", candidates = zephyrs })
  local eb = b.eb
  eb:Release()
  -- AceGUI's pool hands the released box to the next render; the kit's factory never reuses one.
  eb.__released = nil
  local gui = mocks.__libs["AceGUI-3.0"]
  local saved = gui.WidgetRegistry.EditBox
  gui.WidgetRegistry.EditBox = function() return eb end
  local ok, c = pcall(input, made, { kind = "item", candidates = zephyrs }, b.O)
  gui.WidgetRegistry.EditBox = saved
  assertTrue(ok, tostring(c))
  assertTrue(c.eb == eb, "the second render drew the pooled box")
  typeText(c, "zephyr")
  press(c, "DOWN")
  -- red under: hooks installed on every render (one Down would move the highlight twice)
  local rows = dropdown(made).rows
  assertTrue(rows[1].selected, "one Down, one row"); assertFalse(rows[2].selected)
end)

suggestCase("IdInput suggestions: Enter in a box that no longer owns the dropdown submits its text", function(made)
  seedZephyr()
  local b = input(made, { kind = "item", candidates = zephyrs })
  local c = input(made, { kind = "item", candidates = zephyrs }, b.O)
  typeText(b, "zephyr")
  press(b, "DOWN")
  typeText(c, "zephyr")
  b.eb:__fire("OnEnterPressed", "zephyr")
  -- red under: Enter taking a highlight another box's list replaced (a row the player cannot see)
  assertEqual(#b.added, 0, "the first box's old highlight is not picked")
  assertEqual(shownIds(c), "191395,191396,191397", "the other box keeps its list")
end)

suggestCase("IdInput suggestions: a box that left before the pause shows nothing", function(made)
  seedZephyr()
  local b = input(made, { kind = "item", candidates = zephyrs })
  local function typeThen(away, why)
    b.eb:SetText("zephyr"); b.eb:__fire("OnTextChanged", "zephyr")
    away()
    mocks.__fireTimers()
    -- red under: hooks that act only once their box owns the dropdown (the timer shows it anyway)
    assertFalse(shown(b), why)
  end
  typeThen(function() b.eb.editbox:__fire("OnEditFocusLost") end, "focus lost")
  typeThen(function() b.eb.editbox:__fire("OnEscapePressed") end, "Escape")
  typeThen(function()
    b.eb.editbox:__fire("OnEditFocusLost")
    b.eb.frame:__fire("OnHide")
  end, "focus lost, then the panel hidden (Escape twice)")
  typeText(b, "zephyr")
  assertFalse(shown(b), "a hidden box stays quiet")
  b.eb.frame:Show()
  typeText(b, "zephyr")
  assertEqual(shownIds(b), "191395,191396,191397", "until its panel is shown again")
end)

suggestCase("IdInput suggestions: focus lost to the dropdown itself goes back to the box", function(made)
  seedZephyr()
  local b = input(made, { kind = "item", candidates = zephyrs })
  typeText(b, "zephyr")
  local dd = dropdown(made)
  local focused = 0
  b.eb.editbox.SetFocus = function() focused = focused + 1 end
  dd.IsMouseOver = function() return true end
  b.eb.editbox:__fire("OnEditFocusLost")
  mocks.__fireTimers()
  dd.IsMouseOver = nil
  -- red under: a click on the backdrop or the "+N more" line leaving the box without the keys
  assertEqual(focused, 1, "the box takes the keys back, so Escape still reaches it")
  assertTrue(dd:IsShown())
  b.eb.editbox:__fire("OnEscapePressed")
  assertFalse(dd:IsShown())

  typeText(b, "zephyr")
  dd.IsMouseOver = function() return true end
  b.eb.editbox:__fire("OnEditFocusLost")
  dd.rows[1]:__fire("OnClick")
  mocks.__fireTimers()
  assertEqual(table.concat(b.added, ","), "191395", "a click on a row still picks it")
  assertEqual(focused, 1, "and nothing is focused for a closed list")
end)

suggestCase("IdInput suggestions: one render names at most 2000 ids", function(made)
  local ids = {}
  for i = 1, 2001 do
    ids[i] = 700000 + i
    mocks.addIdRecord("item", ids[i], i == 2000 and "Edge Draught" or i == 2001 and "Past Draught"
      or ("Filler %d"):format(i), 1)
  end
  local b = input(made, { kind = "item", candidates = function() return ids end })
  typeText(b, "draught")
  -- red under: no cap on the index (a host's long list named whole on the first keystroke)
  assertEqual(shownIds(b), "702000", "the 2000th id is in, the 2001st is not")
end)

suggestCase("IdInput suggestions: a raising info costs that id's row, not the list", function(made)
  local kind = { noun = "widget", plural = "widgets", resolve = function() return nil, "notFound" end,
                 info = function(id)
                   if id == 2 then error("boom") end
                   return "Widget " .. id, 100 + id
                 end }
  local b = input(made, { kind = kind, candidates = function() return { 1, 2, 3 } end })
  -- red under: an unguarded info (the debounced update raises, and the list never shows)
  local ok, err = pcall(typeText, b, "widget")
  assertTrue(ok, tostring(err))
  assertEqual(shownIds(b), "1,3")
end)

suggestCase("IdInput suggestions: the dropdown is as wide as the box looks", function(made)
  seedZephyr()
  local b = input(made, { kind = "item", candidates = zephyrs })
  typeText(b, "zephyr")
  local dd = dropdown(made)
  local width
  dd.SetWidth = function(_, w) width = w end
  dd.GetEffectiveScale = function() return 1 end
  b.eb.editbox.GetWidth = function() return 300 end
  b.eb.editbox.GetEffectiveScale = function() return 1.5 end
  typeText(b, "zephy")
  -- red under: the box's width taken at its own scale (a scaled panel's list too narrow or wide)
  assertEqual(width, 450)
  b.eb.editbox.GetEffectiveScale = nil
  typeText(b, "zephyr")
  assertEqual(width, 300, "a scale the client does not answer is taken as the same")
end)
