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
-- A suite of its own rather than more cases in tests/test_options_widgets.lua, which was over
-- layout-§1's cap when this was written (since split under issue #33).
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

local GRAY = "|cff808080"
local WHITE = "|cffffffff"
local function atlas(tier) return ("|A:Professions-Icon-Quality-Tier%d-Small:14:14|a"):format(tier) end

-- The bench (suggestCase, input, the dropdown readers, the Zephyr ranks and hostKind) is
-- tests/fixture_idsuggest.lua, shared with tests/test_options_idsuggest_frames.lua.
local S = dofile("tests/fixture_idsuggest.lua")("SuggestBench")
local ZEPHYR, suggestCase, input, dropdown, shown = S.ZEPHYR, S.suggestCase, S.input, S.dropdown, S.shown
local typeText, shownIds, press, seedZephyr, zephyrs = S.typeText, S.shownIds, S.press, S.seedZephyr, S.zephyrs
local hostKind = S.hostKind

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

suggestCase("IdInput suggestions: two letters means two characters, not two bytes", function(made)
  mocks.addIdRecord("item", 800, "Caf\195\169 Draught", 1, nil, 1)
  local b = input(made, { kind = "item", candidates = function() return { 800 } end })
  typeText(b, "\195\169")
  -- red under: a byte count (one two-byte letter would pass the two-letter floor)
  assertEqual(shownIds(b), "", "one non-ASCII letter is one character")
  typeText(b, "f\195\169")
  assertEqual(shownIds(b), "800", "two characters, three bytes")
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

suggestCase("IdInput suggestions: a shared name the bags or the spellbook carry is refused, not one rank added", function(made)
  -- Two quality tiers of one potion in the bags and no candidates: the client's name lookup answers
  -- ONE of them, and the list shows both.
  seedZephyr()
  mocks.setBagItems(0, { 191396, 191395 })
  local b = input(made, { kind = "item" })
  typeText(b, ZEPHYR)
  assertEqual(shownIds(b), "191395,191396")
  b.eb:__fire("OnEnterPressed", ZEPHYR)
  -- red under: a shared-name check that reads the candidates alone (the client's rank added unpicked)
  assertEqual(#b.added, 0, "Enter with nothing picked adds no rank")
  assertEqual(b.status.text, "Several items are named '" .. ZEPHYR ..
    "' \226\128\148 pick one from the list, or use the id.")
  assertEqual(shownIds(b), "191395,191396", "the ranks the refusal points at stay listed")
  local id, reason = b.O.ResolveId("item", ZEPHYR, function() return { 191395 } end)
  assertNil(id); assertEqual(reason, "ambiguous", "candidates covering one rank, the other in the bags")
  mocks.setBagItems(0, { 191395 })
  assertEqual(b.O.ResolveId("item", ZEPHYR), 191395, "one rank carried is that rank")

  mocks.addIdRecord("spell", 900001, "Twin Strike", 11)
  mocks.addIdRecord("spell", 900002, "Twin Strike", 12)
  mocks.setSpellBook({ 900002, 900001 })
  local s = input(made, { kind = "spell" }, b.O)
  typeText(s, "Twin Strike")
  s.eb:__fire("OnEnterPressed", "Twin Strike")
  assertEqual(#s.added, 0, "two spellbook spells of one name: neither added unpicked")
  assertEqual(shownIds(s), "900001,900002")
end)

suggestCase("IdInput suggestions: typing drops the highlight, so Enter never takes a row the text left", function(made)
  seedZephyr()
  mocks.addIdRecord("item", 100, "Zephyr Draught", 1, nil, 1)
  local b = input(made, { kind = "item", candidates = function()
    local ids = zephyrs(); ids[#ids + 1] = 100; return ids end })
  typeText(b, "zephyr")
  assertEqual(shownIds(b), "100,191395,191396,191397")
  press(b, "DOWN"); press(b, "DOWN")
  local rows = dropdown(made).rows
  assertTrue(rows[2].selected)
  -- More typing, then Enter inside the 0.1 s pause: the list on screen is still the old one.
  b.eb:SetText("zephyr dr"); b.eb:__fire("OnTextChanged", "zephyr dr")
  -- red under: a keystroke that leaves the highlight (Enter would take 191395, which "zephyr dr" left)
  assertFalse(rows[2].selected, "the row is no longer drawn highlighted")
  b.eb:__fire("OnEnterPressed", "zephyr dr")
  assertEqual(#b.added, 0, "Enter submits the text, which names nothing")
  mocks.__fireTimers()
  typeText(b, "zephyr dr")
  assertEqual(shownIds(b), "100")
  press(b, "DOWN")
  b.eb:__fire("OnEnterPressed", "zephyr dr")
  assertEqual(table.concat(b.added, ","), "100", "a highlight made after the typing is taken")
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
  assertEqual(b.status.text, "Looking up items...")
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

-- ── a host kind based on a library kind ──────────────────────────────────────────────────────
--
-- ConsumableMaster's Add-by-ID is a host kind: its own resolve keeps its existence checks and its
-- no-active-spec refusal. Its ids are items, and `base = "item"` says so, so its rows wear the item
-- kind's tier icon and quality color. Without `base` a host kind's rows are drawn as they were.

-- hostKind, ConsumableMaster's shape, is in tests/fixture_idsuggest.lua.

local function rankLabel(tier, plain)
  local name = plain and ZEPHYR or (WHITE .. ZEPHYR .. "|r")
  return name .. " " .. (plain and "" or (atlas(tier) .. " ")) .. GRAY .. "(" .. (191394 + tier) .. ")|r"
end

suggestCase("IdInput suggestions: a host kind with base = \"item\" shows each rank's tier and color", function(made)
  seedZephyr()
  local O = Fixture.new()
  local ownInfo = function(id) return mocks.C_Item.GetItemNameByID(id), 4638 end
  for _, extra in ipairs({ { base = "item", info = ownInfo, loads = true }, { base = "item" } }) do
    local b = input(made, { kind = hostKind(O, extra), candidates = zephyrs }, O)
    typeText(b, "hushed")
    assertEqual(shownIds(b), "191395,191396,191397", "a shared name lists every rank")
    local rows = dropdown(made).rows
    for tier = 1, 3 do
      -- red under: SUGGEST_KIND and NAME_COLOR keyed by the library's kind alone (labeled by id only)
      assertEqual(rows[tier].labelText, rankLabel(tier), "tier icon and quality color")
    end
    b.eb:__fire("OnEnterPressed", "hushed")
    b.eb:__fire("OnEnterPressed", ZEPHYR)
    assertEqual(#b.added, 0, "Enter without a pick still refuses the shared name")
    assertEqual(b.status.text, "Several items are named '" .. ZEPHYR ..
      "' \226\128\148 pick one from the list, or use the id.")
  end

  -- red under: a decoration read off every host kind
  local plain = input(made, { kind = hostKind(O, { info = ownInfo }, { [191396] = true }),
                              candidates = zephyrs }, O)
  typeText(plain, "hushed")
  assertEqual(shownIds(plain), "191395,191396,191397")
  assertEqual(dropdown(made).rows[1].labelText, rankLabel(1, true), "no base: drawn as before")
  dropdown(made).rows[2]:__fire("OnClick")
  -- red under: every host kind's pick asked of its resolve (only a based kind's is)
  assertEqual(table.concat(plain.added, ","), "191396",
    "and a pick goes to onAdd as before, past a resolve that would refuse it")
end)

suggestCase("IdInput suggestions: a based host kind's own false wins over its base", function(made)
  -- ConsumableMaster with no active spec sets `info = false, loads = false` on its kind: no list,
  -- nothing pre-warmed. A base must not fill those back in.
  for _, id in ipairs(zephyrs()) do mocks.addIdRecord("item", id, ZEPHYR, 4638, true, 1) end
  local O = Fixture.new()
  assertEqual(table.concat(O.UnnamedCandidates(hostKind(O, { base = "item" }), zephyrs), ","),
    "191397,191395,191396", "the base's loads and info, where the host sets none")
  -- red under: a base field read wherever the host's is falsy (false filled in from the base)
  assertEqual(table.concat(O.UnnamedCandidates(hostKind(O, { base = "item", loads = false }), zephyrs), ","),
    "", "the host's loads = false: nothing to pre-warm")
  seedZephyr()
  local b = input(made, { kind = hostKind(O, { base = "item", info = false }), candidates = zephyrs }, O)
  typeText(b, "hushed")
  assertEqual(shownIds(b), "", "the host's info = false: nothing names a row, so no list")
end)

suggestCase("IdInput suggestions: the id a based kind's resolve answers for a pick is the one added", function(made)
  seedZephyr()
  local O = Fixture.new()
  local kind = hostKind(O, { base = "item" })
  local resolve = kind.resolve
  kind.resolve = function(text, candidates)
    if text == "191395" then return 191397, ZEPHYR end
    return resolve(text, candidates)
  end
  local b = input(made, { kind = kind, candidates = zephyrs }, O)
  typeText(b, "hushed")
  dropdown(made).rows[1]:__fire("OnClick")
  -- red under: the picked row's id added past the resolver's answer
  assertEqual(table.concat(b.added, ","), "191397", "the resolver's id, not the row's")
end)

test("IdInput suggestions: a based kind built per render is collected with its view", function()
  -- ConsumableMaster builds its kind afresh on every render of Add-by-ID. WoW's Lua 5.1 has no
  -- ephemerons, so a weak-keyed cache whose value (the view) reaches back to its key (the host)
  -- keeps both for the session.
  local O = Fixture.new()
  local probe = setmetatable({}, { __mode = "k" })
  for _ = 1, 50 do
    local host = { base = "item", resolve = function(text) return tonumber(text) end }
    probe[host] = true
    O.ResolveId(host, "6948")
    O.UnnamedCandidates(host, function() return { 6948 } end)
  end
  collectgarbage("collect")
  collectgarbage("collect")
  local left = 0
  for _ in pairs(probe) do left = left + 1 end
  -- red under: basedViews weak on its keys alone (every host and its view kept)
  assertEqual(left, 0, "no host kind outlives its render")
end)

suggestCase("IdInput suggestions: a based host kind's resolve still decides what a pick adds", function(made)
  seedZephyr()
  local O = Fixture.new()
  local calls = 0
  local kind = hostKind(O, { base = "item" }, { [191396] = true })
  local resolve = kind.resolve
  kind.resolve = function(...) calls = calls + 1; return resolve(...) end
  local b = input(made, { kind = kind, candidates = zephyrs }, O)
  typeText(b, "hushed")
  assertEqual(shownIds(b), "191395,191396,191397", "the refused rank is still suggested")
  dropdown(made).rows[2]:__fire("OnClick")
  -- red under: a pick handed straight to onAdd (an id the host refuses added anyway)
  assertEqual(#b.added, 0, "the host refused it")
  assertEqual(b.status.text, "No item named '191396'.", "and says so, as a typed id would")
  assertEqual(b.eb.text, "hushed", "the text stays for the player to correct")
  assertEqual(calls, 1, "asked once, about the id")
  typeText(b, "hushed")
  dropdown(made).rows[1]:__fire("OnClick")
  assertEqual(table.concat(b.added, ","), "191395", "a rank the host takes is added")
  assertEqual(b.eb.text, "")
  assertEqual(b.status.text, "")
end)

suggestCase("IdInput suggestions: any library kind can be a base; its ranks and fields come with it", function(made)
  mocks.addIdRecord("spell", 900001, "Twin Strike", 11)
  mocks.addIdRecord("spell", 900002, "Twin Strike", 12)
  mocks.setSpellSubtext(900001, "Rank 2")
  mocks.setSpellSubtext(900002, "Rank 1")
  local O = Fixture.new()
  local kind = { base = "spell", resolve = function(text) return tonumber(text) end }
  local b = input(made, { kind = kind, candidates = function() return { 900001, 900002 } end }, O)
  typeText(b, "twin")
  -- red under: only an item base honored
  assertEqual(dropdown(made).rows[1].labelText, "Twin Strike Rank 1 " .. GRAY .. "(900002)|r",
    "the spell kind's rank, and its plain name")

  -- With no resolve of its own, a based kind resolves with the base's link and info, over the
  -- candidates; the client's name lookup and its bags stay the library kind's.
  mocks.addIdRecord("item", 6948, "Hearthstone", 134414, nil, 1)
  mocks.setBagItems(0, { 6948 })
  local bare = { base = "item" }
  assertEqual(O.ResolveId(bare, "|cffffffff|Hitem:6948::::|h[Hearthstone]|h|r"), 6948, "the item link")
  local _, reason = O.ResolveId(bare, "Hearthstone")
  assertEqual(reason, "notFound", "a name reaches the host's candidates alone")
  local id, name = O.ResolveId(bare, "hearthstone", function() return { 6948 } end)
  assertEqual(id, 6948); assertEqual(name, "Hearthstone")
end)

-- ── a based host kind's suggestions ───────────────────────────────────────
--
-- AuraMaster passes a kind of its own for nothing but the entry tooltip O.IdList builds from the
-- kind, and says `base = "spell"` because its ids are spells. Until minor 26 that cost it the
-- spellbook: SUGGEST_KIND was keyed by the library's kind table alone, so the add box suggested
-- nothing as the player typed. A based kind reads its base's row now. A kind with NO base still
-- reads none -- that is how a host whose ids are not the client's opts out.

suggestCase("IdInput suggestions: a based host kind is offered its base's client ids, ranked as the base ranks them", function(made)
  mocks.addIdRecord("spell", 21562, "Power Word: Fortitude", 135987)
  mocks.addIdRecord("spell", 900001, "Twin Strike", 11)
  mocks.setSpellSubtext(900001, "Rank 2")
  mocks.setSpellBook({ 21562, 900001 })
  local O = Fixture.new()
  local own
  own = { base = "spell", tooltip = function(_, id) own.shown = id end }
  local b = input(made, { kind = own }, O)
  typeText(b, "fort")
  -- red under: SUGGEST_KIND keyed by the library's kind table alone (a based kind saw no spellbook)
  assertEqual(shownIds(b), "21562", "the spellbook, with no candidates of its own")
  typeText(b, "twin")
  assertEqual(dropdown(made).rows[1].labelText, "Twin Strike Rank 2 " .. GRAY .. "(900001)|r",
    "and the base's rank on the row")

  mocks.addIdRecord("item", 6948, "Hearthstone", 134414, nil, 1)
  mocks.setBagItems(0, { 6948 })
  local i = input(made, { kind = { base = "item", resolve = function(text) return tonumber(text) end } }, O)
  typeText(i, "hearth")
  assertEqual(shownIds(i), "6948", "an item base is offered the bags the same way")
end)

suggestCase("IdInput suggestions: a host kind with no base is offered nothing of the client's", function(made)
  mocks.addIdRecord("spell", 21562, "Power Word: Fortitude", 135987)
  mocks.setSpellBook({ 21562 })
  mocks.addIdRecord("item", 6948, "Hearthstone", 134414, nil, 1)
  mocks.setBagItems(0, { 6948 })
  local O = Fixture.new()
  local spellInfo = function(id)
    local info = mocks.C_Spell.GetSpellInfo(id)
    return info and info.name, info and info.iconID
  end
  -- A host list of its own ids -- currencies, tokens, anything -- must never be offered spells.
  local b = input(made, { kind = { noun = "token", info = spellInfo,
                                   resolve = function(text) return tonumber(text) end } }, O)
  typeText(b, "fort")
  -- red under: the client's rows inherited by every host kind (a token list offered the spellbook)
  assertEqual(shownIds(b), "", "no base, no client source")
  local c = input(made, { kind = { noun = "token", info = spellInfo,
                                   resolve = function(text) return tonumber(text) end },
                          candidates = function() return { 21562 } end }, O)
  typeText(c, "fort")
  assertEqual(shownIds(c), "21562", "its own candidates are all it lists, as before")
end)

suggestCase("IdInput suggestions: the shared-name check reads one source through a based kind and its base", function()
  -- The client answers ONE id for a name several spells share. Through the base that hit is
  -- refused when the spellbook holds another spell of the name; a based kind must refuse it too.
  mocks.addIdRecord("spell", 900001, "Twin Strike", 11)
  mocks.addIdRecord("spell", 900002, "Twin Strike", 12)
  mocks.setSpellBook({ 900001, 900002 })
  local O = Fixture.new()
  local byName = function(text)
    if text:lower() == "twin strike" then return 900001, "Twin Strike", 11 end
  end
  local based = { base = "spell", byName = byName }
  local _, viaBase = O.ResolveId("spell", "Twin Strike")
  assertEqual(viaBase, "ambiguous", "the base refuses a name two spellbook spells share")
  local id, reason = O.ResolveId(based, "Twin Strike")
  -- red under: kindSourceIds keyed by the kind table (a based kind saw no spellbook, so no clash)
  assertNil(id); assertEqual(reason, "ambiguous", "and so does a kind based on it")

  mocks.setSpellBook({ 900001 })
  assertEqual(O.ResolveId(based, "Twin Strike"), 900001, "one spell of the name: that spell")

  local loose = { noun = "token", byName = byName, info = function(spellId)
    local info = mocks.C_Spell.GetSpellInfo(spellId)
    return info and info.name, info and info.iconID
  end }
  mocks.setSpellBook({ 900001, 900002 })
  assertEqual(O.ResolveId(loose, "Twin Strike"), 900001,
    "a kind with no base reads no client source, so nothing shares the name")
end)

-- The dropdown's frames are in tests/test_options_idsuggest_frames.lua.
