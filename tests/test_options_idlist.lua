-- tests/test_options_idlist.lua — LibKa0s-Options-1.0's OptionsIdList.lua: O.IdList's entry lines,
-- notes and suffixes, its host callbacks, its uncached-item batches and based kinds. How the
-- entries lay out -- columns, the floors, the help mark and the lit label -- is in
-- tests/test_options_idlist_layout.lua, and the icon-style X in tests/test_options_idlist_remove.lua.
--
-- Peeled out of tests/test_options_widgets.lua (issue #33) in the commit that peeled the module
-- out of LibKa0s/OptionsWidgets.lua (issue #32). The cases are moved unchanged; the benches are in
-- tests/fixture_ids.lua.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil, assertNear =
  T.test, T.assertEqual, T.assertTrue, T.assertNil, T.assertNear
local Fixture = dofile("tests/fixture_options.lua")
local Ids = dofile("tests/fixture_ids.lua")("IdListBench")
local bench, withoutAceGUI = Ids.bench, Ids.withoutAceGUI
local seedIds, typeEnter = Ids.seedIds, Ids.typeEnter
local listBench, listRows, listInput = Ids.listBench, Ids.listRows, Ids.listInput
local countingLoads = Ids.countingLoads
local mocks = T.mocks

test("IdList: one line per entry -- icon, name and gray id, then Remove or a checkbox", function()
  local O, _, ctx, lines = listBench({
    { id = 21562 }, { id = 99999 }, { id = 774, toggle = true, on = true },
  }, { heading = "Spells" })
  -- red under: O.IdList absent
  assertEqual(#lines, 3, "one line per entry, returned in order")
  local flat = Fixture.flatten(O.EnsureScroll(ctx))
  assertEqual(flat[1].type, "Heading"); assertEqual(flat[1].text, "Spells")
  assertTrue(listInput(O, ctx) ~= nil, "the input is drawn above the entries")

  local label, action = lines[1].children[1], lines[1].children[2]
  assertEqual(label.type, "InteractiveLabel")
  assertEqual(label.text, "Power Word: Fortitude |cff808080(21562)|r")
  assertEqual(label.image[1], 135987, "with its icon")
  assertEqual(action.type, "Button"); assertEqual(action.text, "Remove")
  -- red under: formatting a nil name (the line would raise, or read "nil")
  assertEqual(lines[2].children[1].text, "Unknown spell 99999")
  local toggle = lines[3].children[2]
  assertEqual(toggle.type, "CheckBox", "a toggle entry gets a checkbox instead of Remove")
  assertTrue(toggle.value, "seeded from the entry")
end)

test("IdList: an entry's note is drawn under its name, and only when it has one", function()
  local _, _, _, lines = listBench({
    { id = 21562, note = "also in Defensives (Hide) - hidden by rule 3" }, { id = 774, toggle = true },
  })
  -- red under: `note` ignored, or drawn for an entry that carries none
  local noted = lines[1].children[2]
  assertEqual(noted.type, "Label")
  assertEqual(noted.text, "|cff808080also in Defensives (Hide) - hidden by rule 3|r")
  -- with a note present the note line sits between the name and the action widget
  assertEqual(lines[1].children[3].type, "Button")
  -- an entry with no note draws only the name and the action widget, unchanged
  assertEqual(#lines[2].children, 2, "no note line inserted for an entry without one")
  assertEqual(lines[2].children[2].type, "CheckBox")
end)

test("IdList: an empty-string or non-string note draws nothing", function()
  local _, _, _, lines = listBench({
    { id = 21562, note = "" }, { id = 774, toggle = true, note = 42 },
  })
  -- red under: an empty or non-string note drawing a blank/garbage line anyway
  assertEqual(#lines[1].children, 2, "an empty note draws no line")
  assertEqual(#lines[2].children, 2, "a non-string note draws no line")
end)

-- ── entry `suffix` (minor 25) ──────────────────────────────────────────
--
-- The lighter option beside `note`: a few host-composed words INSIDE the entry's own label, after
-- the gray id and in the same gray. It adds no widget, so it costs a shared row nothing -- which
-- is the entire reason it exists rather than being a second note.

test("IdList: an entry's suffix is drawn inside the label, after the gray id and in the same gray",
function()
  local _, _, _, lines = listBench({
    { id = 21562, suffix = "(also in 1)" }, { id = 99999, suffix = "(also in 2)" },
  })
  -- red under: `suffix` ignored, drawn as its own widget, or drawn before the id
  assertEqual(lines[1].children[1].text,
    "Power Word: Fortitude |cff808080(21562)|r |cff808080(also in 1)|r")
  assertEqual(#lines[1].children, 2, "name and action -- the suffix is bytes, not a widget")
  assertEqual(lines[1].children[2].type, "Button")
  -- an unnamed entry has no gray (id) to sit after; the suffix still rides its label
  assertEqual(lines[2].children[1].text, "Unknown spell 99999 |cff808080(also in 2)|r")
end)

test("IdList: an entry with no suffix renders exactly as it did at minor 24", function()
  local _, _, _, lines = listBench({
    { id = 21562 }, { id = 774, suffix = "" }, { id = 99999, suffix = 42 },
  })
  -- red under: a nil, empty or non-string suffix appending a stray " |cff808080|r"
  assertEqual(lines[1].children[1].text, "Power Word: Fortitude |cff808080(21562)|r")
  assertEqual(lines[2].children[1].text, "Rejuvenation |cff808080(774)|r", "an empty suffix adds nothing")
  assertEqual(lines[3].children[1].text, "Unknown spell 99999", "nor does a non-string one")
  for i = 1, 3 do assertEqual(#lines[i].children, 2, "and no widget is added either") end
end)

test("IdList: a suffixed entry still pairs up at two columns -- it is not a full-width row",
function()
  local O, _, ctx, lines = listBench({
    { id = 21562, suffix = "(also in 1)" }, { id = 774, suffix = "(also in 3)" },
    { id = 99999 }, { id = 6948 },
  }, { columns = 2 })
  local rows = listRows(O, ctx)
  -- red under: a suffix taken for a note, which would give entry 1 a row of its own (3 rows, not 2)
  assertEqual(#rows, 2, "two rows for four entries -- the suffixes cost no row")
  assertTrue(lines[1] == lines[2], "the two suffixed entries share the first row")
  assertEqual(#rows[1].children, 6, "name, action, gutter -- twice, exactly as an unsuffixed pair")
  assertNear(rows[1].children[1].relativeWidth, 0.37, 1e-9, "at a column's width, not full width")
  assertEqual(rows[1].children[1].text,
    "Power Word: Fortitude |cff808080(21562)|r |cff808080(also in 1)|r")
  assertEqual(rows[1].children[1].__wordWrap, false, "and word wrap is still off, as at minor 24")
end)

test("IdList: a suffix and a note on one entry -- the note wins its line, the suffix stays inline",
function()
  local O, _, ctx, lines = listBench({
    { id = 21562 }, { id = 774, note = "hidden by rule 3", suffix = "(also in 2)" },
    { id = 99999 }, { id = 6948 },
  }, { columns = 2 })
  local rows = listRows(O, ctx)
  -- red under: a suffix canceling the note's full-width row, or the note swallowing the suffix
  assertEqual(#rows, 3, "the noted entry still takes a row of its own")
  assertEqual(#rows[2].children, 3, "name, note, action -- the suffix adds no fourth child")
  assertEqual(rows[2].children[1].text, "Rejuvenation |cff808080(774)|r |cff808080(also in 2)|r")
  assertEqual(rows[2].children[2].text, "|cff808080hidden by rule 3|r", "the note is untouched")
  assertNear(rows[2].children[1].relativeWidth, 0.78, 1e-9, "drawn as a one-column entry")
  assertTrue(lines[2] == rows[2])
end)

test("IdList: a suffix is concatenated, so a % or a |c in it reaches the client as written",
function()
  local _, _, _, lines = listBench({
    { id = 21562, suffix = "(100%% of 2)" }, { id = 774, suffix = "|cffff0000(3)|r" },
    { id = 99999, suffix = "50% off" },
  })
  -- red under: the suffix passed through string.format or used as a gsub replacement, where %% and
  -- %( are the escapes of those functions rather than bytes the player typed
  assertEqual(lines[1].children[1].text,
    "Power Word: Fortitude |cff808080(21562)|r |cff808080(100%% of 2)|r")
  assertEqual(lines[2].children[1].text,
    "Rejuvenation |cff808080(774)|r |cff808080|cffff0000(3)|r|r", "a host color escape is not stripped")
  assertEqual(lines[3].children[1].text, "Unknown spell 99999 |cff80808050% off|r")
end)

test("IdList: Remove and a toggle call the host back, and Remove asks for a rebuild", function()
  local _, _, _, lines, log = listBench({ { id = 21562 }, { id = 774, toggle = true, on = true } })
  lines[1].children[2]:__fire("OnClick")
  -- red under: Remove not wired to onRemove
  assertEqual(log.removed[1], 21562)
  -- red under: no rebuild after a remove (the removed line would stay on screen)
  assertEqual(log.rebuilt, 1, "the list's shape changed, so the page is rebuilt")
  lines[2].children[2]:__fire("OnValueChanged", false)
  assertEqual(log.toggled[1][1], 774)
  assertEqual(log.toggled[1][2], false)
end)

test("IdList: an add through its input reaches onAdd and rebuilds the list", function()
  local O, _, ctx, _, log = listBench({})
  local eb = listInput(O, ctx)
  typeEnter(eb, "rejuvenation")
  assertEqual(log.added[1], 774)
  -- red under: IdList not rebuilding after an add (the new entry would not appear)
  assertEqual(log.rebuilt, 1)
end)

test("IdList: with no ctx.rebuild the library's structural refresh redraws it", function()
  local O, _, ctx = bench()
  seedIds()
  local refreshed = 0
  local real = O.RefreshAllPanels
  O.RefreshAllPanels = function() refreshed = refreshed + 1 end
  local lines = O.IdList(ctx, { kind = "spell", entries = function() return { { id = 21562 } } end,
                                onRemove = function() end })
  lines[1].children[2]:__fire("OnClick")
  O.RefreshAllPanels = real
  -- red under: no fallback when the host sets no ctx.rebuild
  assertEqual(refreshed, 1)
end)

test("IdList: an empty list shows the host's empty text", function()
  local O, _, ctx, lines = listBench({}, { emptyText = "No spells added." })
  assertEqual(#lines, 0)
  -- red under: drawing nothing for an empty list (the page reads as broken)
  local found = false
  for _, w in ipairs(Fixture.flatten(O.EnsureScroll(ctx))) do
    if w.type == "Label" and w.text == "No spells added." then found = true end
  end
  assertTrue(found, "the empty text is on the page")
end)


test("IdList: an uncached item asks to load, and the list redraws once its name lands", function()
  countingLoads(function(requests)
    local O, _, ctx, lines, log = listBench({ { id = 2589 }, { id = 6948 } }, { kind = "item" })
    assertEqual(lines[1].children[1].text, "Unknown item 2589", "no name until it is cached")
    -- red under: never asking the client for the item (its name would never arrive)
    assertEqual(requests.total, 1, "one request, for the uncached item only")
    mocks.addIdRecord("item", 2589, "Linen Cloth", 132889)
    mocks.__fireTimers()
    -- red under: a load callback that redraws nothing
    assertEqual(log.rebuilt, 1, "the load rebuilt the list")
    assertEqual(#mocks.__timers, 0, "a landed item is not asked for again")
    O.IdList(ctx, { kind = "item", entries = function() return { { id = 2589 } } end })
    assertEqual(requests.total, 1, "a named item needs no request")
  end)
end)

test("IdList: an item's name is colored by its quality; a spell's and a currency's are not", function()
  local O, _, ctx, lines = listBench({ { id = 6948 }, { id = 19019 } }, { kind = "item" })
  -- red under: an item name drawn plain (BankLedger and LootHistory colored theirs by quality)
  assertEqual(lines[1].children[1].text, "|cffffffffHearthstone|r |cff808080(6948)|r")
  assertEqual(lines[2].children[1].text, "|cffff8000Thunderfury|r |cff808080(19019)|r")
  local spell = O.IdList(ctx, { kind = "spell", entries = function() return { { id = 21562 } } end })
  assertEqual(spell[1].children[1].text, "Power Word: Fortitude |cff808080(21562)|r")
  local currency = O.IdList(ctx, { kind = "currency", entries = function() return { { id = 3008 } } end })
  assertEqual(currency[1].children[1].text, "Valorstones |cff808080(3008)|r")
end)

test("IdList: an item with no quality yet, or no palette for it, is drawn uncolored", function()
  local O, _, ctx, lines = listBench({ { id = 2589 }, { id = 777001 } }, { kind = "item" })
  mocks.__timers = {}
  assertEqual(lines[1].children[1].text, "Unknown item 2589", "an uncached item is not colored")
  assertEqual(lines[2].children[1].text, "Nameless Quality |cff808080(777001)|r",
    "a named item the client answers no quality for is drawn plain")
  mocks.addIdRecord("item", 2589, "Linen Cloth", 132889, nil, 1)
  local landed = O.IdList(ctx, { kind = "item", entries = function() return { { id = 2589 } } end })
  assertEqual(landed[1].children[1].text, "|cffffffffLinen Cloth|r |cff808080(2589)|r",
    "the redraw after the load colors it")
  local palette = mocks.ITEM_QUALITY_COLORS
  mocks.ITEM_QUALITY_COLORS = nil
  local ok, bare = pcall(O.IdList, ctx, { kind = "item", entries = function() return { { id = 6948 } } end })
  mocks.ITEM_QUALITY_COLORS = palette
  assertTrue(ok, tostring(bare))
  -- red under: indexing a missing palette (the line would be lost to its guard)
  assertEqual(bare[1].children[1].text, "Hearthstone |cff808080(6948)|r")
end)

test("IdList: uncached items load as one batch -- one timer and one rebuild, however many", function()
  countingLoads(function(requests)
    local entries = {}
    for i = 1, 20 do entries[i] = { id = 900000 + i } end
    local _, _, _, _, log = listBench(entries, { kind = "item" })
    assertEqual(requests.total, 20, "every uncached item is asked for")
    -- red under: one timer per id (twenty full page renders landing in the same frame)
    assertEqual(#mocks.__timers, 1, "one check for the whole batch")
    for i = 1, 20 do mocks.addIdRecord("item", 900000 + i, "Item " .. i, 1) end
    mocks.__fireTimers()
    assertEqual(log.rebuilt, 1, "one rebuild draws every name that landed")
  end)
end)

test("IdList: an item not cached by the check is asked for again, a bounded number of times", function()
  countingLoads(function(requests)
    local _, _, _, _, log = listBench({ { id = 2589 } }, { kind = "item" })
    mocks.__fireTimers()
    -- red under: giving up after one fixed delay (a slow load reads "Unknown item" until some
    -- unrelated redraw)
    assertEqual(requests[2589], 2, "asked again once the first check found no name")
    assertEqual(log.rebuilt, 0, "nothing landed, so nothing is redrawn")
    mocks.addIdRecord("item", 2589, "Linen Cloth", 132889)
    mocks.__fireTimers()
    assertEqual(log.rebuilt, 1, "the retry's check redraws the name that landed")
    assertEqual(#mocks.__timers, 0)

    -- An id the client does not have never loads: the asks stop.
    local _, _, _, _, never = listBench({ { id = 999001 } }, { kind = "item" })
    local rounds = 0
    while #mocks.__timers > 0 and rounds < 50 do
      mocks.__fireTimers()
      rounds = rounds + 1
    end
    -- red under: re-requesting for ever (an id the client never loads would loop forever)
    assertTrue(rounds < 50, "the asks stop on their own")
    assertEqual(requests[999001], 5, "five asks, then the entry stays unnamed")
    assertEqual(never.rebuilt, 0)
  end)
end)

test("IdList: an entry's label shows the client's own tooltip for it", function()
  local _, _, _, lines = listBench({ { id = 21562 } })
  local tip, seen = mocks.GameTooltip, {}
  local saved = rawget(tip, "SetSpellByID")
  tip.SetSpellByID = function(_, id) seen.id = id end
  local label = lines[1].children[1]
  local ok, err = pcall(label.__fire, label, "OnEnter")
  tip.SetSpellByID = saved
  assertTrue(ok, tostring(err))
  -- red under: no tooltip on the entry label
  assertEqual(seen.id, 21562)
end)

--- Hover an entry's label with GameTooltip's `method` spied; answers the id it was handed.
local function hoverWith(label, method)
  local tip, seen = mocks.GameTooltip, {}
  local saved = rawget(tip, method)
  tip[method] = function(_, id) seen.id = id end
  local ok, err = pcall(label.__fire, label, "OnEnter")
  tip[method] = saved
  assertTrue(ok, tostring(err))
  return seen.id
end

test("IdList: a host kind with base = \"item\" wears the item kind's color, tooltip and loads", function()
  -- ConsumableMaster's shape: its own resolve (existence checks the library does not know), and
  -- ids that are items. Without `base` it gets none of the item kind's decorations.
  local kind = { noun = "potion", plural = "potions", base = "item",
                 resolve = function(text) return tonumber(text) end }
  local O, _, ctx, lines = listBench({ { id = 6948 }, { id = 19019 }, { id = 2589 } }, { kind = kind })
  mocks.__timers = {}
  -- red under: NAME_COLOR keyed by the library's kind table alone (a host kind's names drawn plain)
  assertEqual(lines[1].children[1].text, "|cffffffffHearthstone|r |cff808080(6948)|r",
    "the item kind's quality color, and its info names the entry")
  assertEqual(lines[2].children[1].text, "|cffff8000Thunderfury|r |cff808080(19019)|r")
  assertEqual(lines[3].children[1].text, "Unknown potion 2589", "the host's own noun wins")
  assertEqual(hoverWith(lines[1].children[1], "SetItemByID"), 6948, "the item kind's tooltip")
  assertEqual(table.concat(O.UnnamedCandidates(kind, function() return { 2589, 6948 } end), ","),
    "2589", "the item kind's loads and info: its unnamed candidates are pre-warmed and looked up")

  -- A field the host sets itself wins over the base's.
  local own
  own = { noun = "potion", base = "item", resolve = kind.resolve,
          tooltip = function(_, id) own.shown = id end }
  local mine = O.IdList(ctx, { kind = own, entries = function() return { { id = 6948 } } end })
  assertEqual(hoverWith(mine[1].children[1], "SetItemByID"), nil, "not the base's tooltip")
  assertEqual(own.shown, 6948, "the host's own")
end)

test("IdList: a host kind without base, or with a base no library kind has, is drawn as before", function()
  local itemName = function(id) return mocks.C_Item.GetItemNameByID(id) end
  for _, base in ipairs({ false, "widget" }) do
    local kind = { noun = "potion", base = base or nil, info = itemName, loads = true,
                   resolve = function(text) return tonumber(text) end }
    local O, _, _, lines = listBench({ { id = 6948 } }, { kind = kind })
    -- red under: a decoration read off every host kind (a host's own ids need not be items)
    assertEqual(lines[1].children[1].text, "Hearthstone |cff808080(6948)|r", "plain, as today")
    assertNil(hoverWith(lines[1].children[1], "SetItemByID"), "no tooltip it did not declare")
    assertEqual(table.concat(O.UnnamedCandidates(kind, function() return { 2589 } end), ","), "2589",
      "its own loads and info still count")
  end
end)

test("IdList: a based spell kind draws as a spell and keeps its own tooltip", function()
  -- AuraMaster's shape: a kind of its own for nothing but the entry tooltip, over ids that are the
  -- library's spells. `base = "spell"` hands it the spell kind's info and words; the tooltip it
  -- declares is still the one a hover reaches.
  local own
  own = { base = "spell", tooltip = function(_, id) own.shown = id end }
  local _, _, _, lines = listBench({ { id = 21562 } }, { kind = own })
  assertEqual(lines[1].children[1].text, "Power Word: Fortitude |cff808080(21562)|r",
    "the base's info names it, drawn plain as a spell is")
  assertNil(hoverWith(lines[1].children[1], "SetSpellByID"), "not the base's tooltip")
  -- red under: a host tooltip filled in from the base (the host's own never called)
  assertEqual(own.shown, 21562, "the host's own")
end)

test("IdList: a raising entries() is reported and still draws the input", function()
  local O, rec, ctx = bench()
  rec.chat = {}
  local lines = O.IdList(ctx, { kind = "spell", entries = function() error("list exploded") end })
  -- red under: an unguarded entries() (the whole page stops at the list)
  assertEqual(#lines, 0)
  assertTrue(listInput(O, ctx) ~= nil, "the input is still there to add with")
  assertTrue(table.concat(rec.chat, "\n"):find("list exploded", 1, true) ~= nil)
end)

test("IdList: drawn disabled, every Remove and checkbox is disabled", function()
  local _, _, _, lines = listBench({ { id = 21562 }, { id = 774, toggle = true } }, { disabled = true })
  -- red under: entries ignoring the disable (a disabled page would still remove ids)
  assertTrue(lines[1].children[2].disabled)
  assertTrue(lines[2].children[2].disabled)
end)

test("IdList: with no AceGUI it draws nothing", function()
  withoutAceGUI(function()
    local O, _, ctx = bench()
    assertNil(O.IdList(ctx, { kind = "spell", entries = function() return {} end }))
  end)
end)
