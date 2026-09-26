-- tests/test_options_ids.lua — LibKa0s-Options-1.0's OptionsIds.lua: O.ResolveId,
-- O.UnnamedCandidates, O.ID_NAME_HINT and O.IdInput, including the lookup a typed name waits on.
-- The suggestion dropdown's cases are in tests/test_options_idsuggest.lua.
--
-- Peeled out of tests/test_options_widgets.lua (issue #33) in the commit that peeled the module
-- out of LibKa0s/OptionsWidgets.lua (issue #32), on the module's seam: one suite per module, so a
-- red names the file it is about. The cases are moved unchanged; the benches they share with the
-- id list's suites are in tests/fixture_ids.lua.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil, assertNear =
  T.test, T.assertEqual, T.assertTrue, T.assertNil, T.assertNear
local Fixture = dofile("tests/fixture_options.lua")
local Ids = dofile("tests/fixture_ids.lua")("IdsBench")
local bench, withoutAceGUI = Ids.bench, Ids.withoutAceGUI
local seedIds, inputBench, typeEnter = Ids.seedIds, Ids.inputBench, Ids.typeEnter
local countingLoads = Ids.countingLoads
local mocks = T.mocks

-- ── ResolveId / IdInput / IdList (minor 16) ────────────────────────────────────────────────
--
-- An id list a player edits by typing a number, pasting a link or typing a name. Before this each
-- host drew its own edit box and Add button and accepted a bare number only (BankLedger,
-- LootHistory, ConsumableMaster), so a player had to look an id up outside the game. The records
-- below go through the kit's opt-in id lookups, which this repo's tests/wow_mock.lua installs.

test("ResolveId: a number is an id, and a known one carries its name and icon", function()
  local O = Fixture.new()
  seedIds()
  local id, name, icon = O.ResolveId("spell", " 21562 ")
  assertEqual(id, 21562); assertEqual(name, "Power Word: Fortitude"); assertEqual(icon, 135987)
  -- red under: refusing an id the client cannot name (id-only input is the degraded mode)
  local unknown, noName = O.ResolveId("spell", "99999")
  assertEqual(unknown, 99999)
  assertNil(noName, "an unknown id resolves with no name")
end)

test("ResolveId: every link form resolves, for its own kind only", function()
  local O = Fixture.new()
  seedIds()
  assertEqual(O.ResolveId("spell", "|cff71d5ff|Hspell:21562:0|h[Power Word: Fortitude]|h|r"), 21562)
  assertEqual(O.ResolveId("item", "|cffffffff|Hitem:6948::::::::80:::::|h[Hearthstone]|h|r"), 6948)
  assertEqual(O.ResolveId("currency", "|cffffffff|Hcurrency:3008:0|h[Valorstones]|h|r"), 3008)
  assertEqual(O.ResolveId("spell", "spell:21562"), 21562)
  assertEqual(O.ResolveId("item", "item:6948"), 6948)
  assertEqual(O.ResolveId("currency", "currency:3008"), 3008)
  -- red under: one link pattern for every kind (an item link would add item 6948 as a spell)
  local id, reason = O.ResolveId("spell", "|cffffffff|Hitem:6948|h[Hearthstone]|h|r")
  assertNil(id); assertEqual(reason, "notFound")
end)

test("ResolveId: a spell name the client knows resolves to its id", function()
  local O = Fixture.new()
  seedIds()
  local id, name, icon = O.ResolveId("spell", "power word: fortitude")
  -- red under: a case-sensitive lookup (players type names in lower case)
  assertEqual(id, 21562); assertEqual(name, "Power Word: Fortitude"); assertEqual(icon, 135987)
  local item, itemName = O.ResolveId("item", "HEARTHSTONE")
  assertEqual(item, 6948); assertEqual(itemName, "Hearthstone")
end)

test("ResolveId: a name the client cannot look up is found among the host's candidates", function()
  local O = Fixture.new()
  seedIds()
  local candidates = function() return { 2914, 3008 } end
  local id, name, icon = O.ResolveId("currency", "valorstones", candidates)
  -- red under: no candidates step (a currency has no client name lookup at all)
  assertEqual(id, 3008); assertEqual(name, "Valorstones"); assertEqual(icon, 5872049)
  local none, reason = O.ResolveId("currency", "valorstones")
  assertNil(none); assertEqual(reason, "notFound", "with no candidates there is nothing to search")
end)

test("ResolveId: two candidates with the name are ambiguous, one listed twice is not", function()
  local O = Fixture.new()
  seedIds()
  local id, reason = O.ResolveId("currency", "crest", function() return { 2914, 2915 } end)
  -- red under: taking the first match (the player would get a currency they did not mean)
  assertNil(id); assertEqual(reason, "ambiguous")
  -- red under: counting matches rather than distinct ids
  assertEqual(O.ResolveId("currency", "crest", function() return { 2914, 2914 } end), 2914)
end)

test("ResolveId: nothing typed is empty, and an unknown name is not found", function()
  local O = Fixture.new()
  seedIds()
  local id, reason = O.ResolveId("spell", "   ")
  assertNil(id); assertEqual(reason, "empty")
  assertEqual(select(2, O.ResolveId("spell", nil)), "empty")
  id, reason = O.ResolveId("spell", "Shadow Word: Pain")
  assertNil(id); assertEqual(reason, "notFound")
  -- A raising candidates() is a host bug, and costs the name step rather than the player's click.
  id, reason = O.ResolveId("spell", "Shadow Word: Pain", function() error("boom") end)
  assertNil(id); assertEqual(reason, "notFound")
end)

test("ResolveId: a custom kind's resolver is handed everything typed", function()
  local O = Fixture.new()
  local seen
  local kind = { noun = "thing", resolve = function(text)
    seen = text
    if text == "42" then return -42, "Forty-two", 7 end
    if text == "twin" then return nil, "ambiguous" end
    if text == "boom" then error("resolver exploded") end
    return nil
  end }
  local id, name, icon = O.ResolveId(kind, " 42 ")
  -- red under: parsing a number before the resolver (a host that stores spells as -id could not)
  assertEqual(id, -42); assertEqual(name, "Forty-two"); assertEqual(icon, 7)
  assertEqual(seen, "42", "trimmed, and otherwise untouched")
  assertEqual(select(2, O.ResolveId(kind, "twin")), "ambiguous", "a resolver can say why")
  assertEqual(select(2, O.ResolveId(kind, "nope")), "notFound")
  assertEqual(select(2, O.ResolveId(kind, "boom")), "notFound", "a raising resolver finds nothing")
  assertEqual(select(2, O.ResolveId(kind, "")), "empty", "empty is decided before the resolver")
end)

test("ResolveId: with no client APIs a number still resolves and a name finds nothing", function()
  local O = Fixture.new()
  local savedSpell, savedItem = mocks.C_Spell, mocks.C_Item
  mocks.C_Spell, mocks.C_Item = nil, nil
  local ok, err = pcall(function()
    assertEqual(O.ResolveId("spell", "21562"), 21562)
    -- red under: an unguarded C_Spell (the whole input raises on a client without it)
    assertEqual(select(2, O.ResolveId("spell", "Power Word: Fortitude")), "notFound")
    assertEqual(select(2, O.ResolveId("item", "Hearthstone")), "notFound")
  end)
  mocks.C_Spell, mocks.C_Item = savedSpell, savedItem
  assertTrue(ok, tostring(err))
end)

test("IdInput: an edit box and an Add button share a line, with a status line under them", function()
  local b = inputBench({ label = "Add spell", tooltip = "An id, a link or a name." })
  -- red under: O.IdInput absent (every host keeps its own id-only edit box)
  assertEqual(b.eb.type, "EditBox"); assertEqual(b.add.type, "Button")
  assertEqual(b.eb.labelText, "Add spell")
  assertNear(b.eb.relativeWidth, 0.78, 1e-6)
  assertNear(b.add.relativeWidth, 0.20, 1e-6)
  assertEqual(b.add.text, "Add")
  assertTrue(b.eb.buttonDisabled, "the edit box's own Okay button is hidden: Add is the button")
  assertEqual(b.status.type, "Label"); assertEqual(b.status.text, "")
  assertTrue(b.group.children[1] == b.eb and b.group.children[2] == b.add
    and b.group.children[3] == b.status, "all three in one group, in that order")
  local scroll = b.O.EnsureScroll(b.ctx)
  assertTrue(scroll.children[#scroll.children] == b.group, "added to the page's scroll")
  assertTrue(b.eb.callbacks.OnEnter ~= nil, "the tooltip is attached")
end)

test("IdInput: the Add button is the height of the box it sits beside, not AceGUI's default",
  function()
    -- THE OWNER'S REPORT, 2026-09-22: "the add button is slightly higher than the add a spell
    -- textbox". It was not higher. The two were already centered on each other and always had
    -- been -- AceGUI's labeled EditBox publishes `self.alignoffset = 30` (SetLabel in
    -- widgets/AceGUIWidget-EditBox.lua) and Flow anchors the next widget by
    -- `frameoffset - lastframeoffset`, which puts their middles on one line. The button was
    -- TALLER: InputBoxTemplate draws its border art 20 tall and AceGUI's Button is a flat
    -- SetHeight(24), so it overhung 2px at each end -- and the two overhangs do not read alike,
    -- because the top one sits against the row's gold caption and the bottom against empty dark.
    --
    -- red under the SetHeight going away, which puts AceGUI's 24 back.
    local b = inputBench({ label = "Add spell" })
    assertEqual(b.add.height, 20,
      "the Add button matches InputBoxTemplate's border art, which is 20 tall")
  end)

test("IdInput: Enter with a valid name adds it once and clears the box", function()
  local b = inputBench()
  typeEnter(b.eb, "power word: fortitude")
  -- red under: Enter not wired (only the button would submit)
  assertEqual(#b.added, 1, "onAdd ran once")
  assertEqual(b.added[1], 21562, "with the resolved id")
  assertEqual(b.eb.text, "", "the box is cleared for the next one")
  assertEqual(b.status.text, "")
end)

test("IdInput: the Add button submits what was typed", function()
  local b = inputBench()
  b.eb:SetText("|Hspell:774|h[Rejuvenation]|h")
  b.add:__fire("OnClick")
  -- red under: the button resolving nothing (it would need Enter to be pressed first)
  assertEqual(b.added[1], 774)
end)

test("IdInput: a name that resolves to nothing says so inline and adds nothing", function()
  local b = inputBench()
  typeEnter(b.eb, "Shadow Word: Pain")
  -- red under: adding on a failed resolve, or failing silently
  assertEqual(#b.added, 0, "nothing added")
  -- red under: "that the game knows" (C_Spell.GetSpellInfo(name) answers only the spellbook)
  assertEqual(b.status.text, "No spell named 'Shadow Word: Pain' in your spellbook. " ..
    "Names work for spells in your spellbook and ones this list knows; otherwise use the id or " ..
    "shift-click a link.")
  assertTrue(b.status.color ~= nil and b.status.color.r == 1 and b.status.color.b == 0,
    "in orange")
  assertEqual(b.eb.text, "Shadow Word: Pain", "the text stays, so the player can correct it")
  typeEnter(b.eb, "21562")
  assertEqual(b.status.text, "", "a success clears the message")
end)

test("IdInput: an ambiguous name asks for the id, in the kind's own plural", function()
  local b = inputBench({ kind = "currency", candidates = function() return { 2914, 2915 } end })
  typeEnter(b.eb, "Crest")
  assertEqual(#b.added, 0)
  -- red under: pluralizing by adding "s" ("currencys")
  assertEqual(b.status.text,
    "Several currencies are named 'Crest' \226\128\148 pick one from the list, or use the id.")
end)

test("IdInput: the host can reword the button and the messages", function()
  local b = inputBench({ strings = { add = "Include", notFound = "Nope: {text}" } })
  assertEqual(b.add.text, "Include")
  typeEnter(b.eb, "zzz")
  -- red under: ignoring spec.strings (a localized host would show English)
  assertEqual(b.status.text, "Nope: zzz")
end)

test("IdInput: a raising onAdd is reported, and the box keeps its text", function()
  local b = inputBench({ onAdd = function() error("store exploded") end })
  b.rec.chat = {}
  typeEnter(b.eb, "zzz")
  typeEnter(b.eb, "21562")
  -- red under: an unguarded onAdd (a raise inside AceGUI's dispatch takes the frame's clicks down)
  assertTrue(table.concat(b.rec.chat, "\n"):find("store exploded", 1, true) ~= nil)
  assertEqual(b.eb.text, "21562", "the add did not happen, so the input is not cleared")
  assertEqual(b.status.text, "No spell named 'zzz' in your spellbook. " .. b.O.ID_NAME_HINT.spell,
    "and the status line is as it was")
end)

test("IdInput: the box and status line are cleared before onAdd, so onAdd may redraw the page", function()
  local b
  local seen = {}
  b = inputBench({ onAdd = function()
    seen.text, seen.status = b.eb.text, b.status.text
    -- What a synchronous redraw does: both widgets go back to AceGUI's pool, and the next render
    -- may take them. Anything written to them from here on lands on someone else's widget.
    b.eb.SetText = function() seen.touched = true end
    b.status.SetText = function() seen.touched = true end
    b.status.SetColor = function() seen.touched = true end
  end })
  typeEnter(b.eb, "zzz")
  typeEnter(b.eb, "21562")
  -- red under: clearing after onAdd returns (a host that redraws inside onAdd has its new page's
  -- widgets blanked -- ConsumableMaster and LootHistory each coded around it)
  assertEqual(seen.text, "", "the box was cleared before onAdd ran")
  assertEqual(seen.status, "", "and so was the status line")
  assertNil(seen.touched, "nothing touches either widget after onAdd returns")
end)

test("IdInput: drawn inside a disabled render, or with spec.disabled, it is disabled", function()
  local O, rec, ctx = bench()
  local eb, add
  local after = { Master = function(c)
    local _
    _, eb, add = O.IdInput(c, nil, { kind = "spell", onAdd = function() end })
  end }
  O.RenderRows(ctx, { rec.byPath.locked }, after, nil, { disabled = true })
  -- red under: the input ignoring the render's flag (a disabled page would still take ids)
  assertTrue(eb.disabled); assertTrue(add.disabled)
  local b = inputBench({ disabled = true })
  assertTrue(b.eb.disabled); assertTrue(b.add.disabled)
  assertNil(b.ctx.__renderDisabled, "the flag lives for the call only")
  local live = inputBench()
  assertNil(live.eb.disabled, "an input drawn normally is never touched")
end)

test("IdInput: with no AceGUI it draws nothing", function()
  withoutAceGUI(function()
    local O, _, ctx = bench()
    assertNil(O.IdInput(ctx, nil, { kind = "spell", onAdd = function() end }))
  end)
end)

-- ── a name among uncached candidates, the name hint, and a shared name ──────────────────────
--
-- The client's item-name lookup answers only for an item the player carries, or carried this
-- session. ConsumableMaster's owner typed "Potion of the Hushed Zephyr" (three crafted-quality ranks
-- share the name, none in the bags) into Add-by-ID and read "No item matches". There is no client
-- item-name search: a name reaches an item through that lookup or through the host's candidates,
-- and a candidate the client has not cached has no name to match until it is loaded.

local ZEPHYR = "Potion of the Hushed Zephyr"
local ELLIPSIS = "..."  -- G-1: plain ASCII, the owner's font draws U+2026 as an empty box
local ITEM_HINT = "Names work for items you carry (or carried this session) and ones this list " ..
  "knows; otherwise use the id or shift-click a link."

--- The three ranks sharing one name: uncached, unless `cached` names them.
local function seedZephyr(cached)
  cached = cached or {}
  for _, id in ipairs({ 191395, 191396, 191397 }) do
    mocks.addIdRecord("item", id, ZEPHYR, 4638, not cached[id], 1)
  end
end
local function zephyrs() return { 191395, 191396, 191397 } end

--- Fire the timer queue until it is empty, or `limit` rounds. Answers how many rounds ran.
local function drainTimers(limit)
  local rounds = 0
  while #mocks.__timers > 0 and rounds < limit do
    mocks.__fireTimers()
    rounds = rounds + 1
  end
  return rounds
end

test("ResolveId: a client name hit another candidate shares its name with is ambiguous", function()
  local O = Fixture.new()
  seedIds()
  seedZephyr({ [191395] = true, [191396] = true })
  assertEqual(O.ResolveId("item", ZEPHYR), 191395, "with no candidates the client's answer stands")
  local id, reason = O.ResolveId("item", ZEPHYR, zephyrs)
  -- red under: returning the client's hit before reading the candidates (one rank added silently)
  assertNil(id); assertEqual(reason, "ambiguous")
  assertEqual(O.ResolveId("item", ZEPHYR, function() return { 191395, 191397 } end), 191395,
    "a candidate the client cannot name yet is not a second match")
  assertEqual(O.ResolveId("item", "hearthstone", function() return { 6948, 191396 } end), 6948,
    "the client's own id among the candidates is one match, not two")
  mocks.addIdRecord("spell", 900001, "Twin Strike", 1)
  mocks.addIdRecord("spell", 900002, "Twin Strike", 2)
  assertEqual(select(2, O.ResolveId("spell", "twin strike", function() return { 900002 } end)),
    "ambiguous", "a spell the client names and a different candidate spell")
end)

test("UnnamedCandidates: the item candidates the client cannot name yet, each once, capped", function()
  local O = Fixture.new()
  seedIds()
  seedZephyr({ [191396] = true })
  -- red under: O.UnnamedCandidates absent (the widget has nothing to ask the client for)
  local ids = O.UnnamedCandidates("item", function() return { 6948, 191395, 191396, 191397, 191395 } end)
  assertEqual(table.concat(ids, ","), "191395,191397", "in the host's order, each once")
  local many = {}
  for i = 1, 300 do many[i] = 800000 + i end
  assertEqual(#O.UnnamedCandidates("item", function() return many end), 200, "capped at 200")
  assertEqual(#O.UnnamedCandidates("spell", function() return { 99999 } end), 0, "only items load")
  assertEqual(#O.UnnamedCandidates("currency", function() return { 99999 } end), 0)
  assertEqual(#O.UnnamedCandidates("item", function() error("boom") end), 0)
  assertEqual(#O.UnnamedCandidates("item"), 0)
  local real = mocks.C_Item.RequestLoadItemDataByID
  mocks.C_Item.RequestLoadItemDataByID = nil
  local ok, n = pcall(function() return #O.UnnamedCandidates("item", zephyrs) end)
  mocks.C_Item.RequestLoadItemDataByID = real
  assertTrue(ok, tostring(n))
  assertEqual(n, 0, "a client that cannot load an item has none to wait for")
end)

test("IdInput: a name among uncached candidates is looked up, and added once it lands", function()
  countingLoads(function(requests)
    local b = inputBench({ kind = "item", candidates = function() return { 6948, 191396 } end })
    seedZephyr()
    local before = requests.total
    typeEnter(b.eb, ZEPHYR)
    -- red under: no lookup (a candidate the client has not cached can never match a name)
    assertEqual(#b.added, 0, "nothing added yet")
    assertEqual(b.status.text, "Looking up items" .. ELLIPSIS)
    assertTrue(b.status.color.r == 1 and b.status.color.g == 1 and b.status.color.b == 1,
      "in a neutral color, not the failure orange")
    assertEqual(requests.total - before, 1, "the one unnamed candidate is asked for")
    assertEqual(#mocks.__timers, 1, "one check for the whole lookup")
    assertEqual(b.eb.text, ZEPHYR, "the text stays while it looks")
    mocks.addIdRecord("item", 191396, ZEPHYR, 4638, nil, 1)
    mocks.__fireTimers()
    assertEqual(#b.added, 1, "the retry adds it, once")
    assertEqual(b.added[1], 191396)
    assertEqual(b.eb.text, ""); assertEqual(b.status.text, "")
  end)
end)

test("IdInput: a lookup waits for every candidate it asked for, then refuses a shared name", function()
  countingLoads(function(requests)
    local b = inputBench({ kind = "item", candidates = zephyrs })
    seedZephyr()
    typeEnter(b.eb, ZEPHYR)
    local asked395, asked396 = requests[191395], requests[191396]
    seedZephyr({ [191395] = true })
    mocks.__fireTimers()
    -- red under: retrying as soon as one lands (rank 1 alone would be added, though two more ranks
    -- share its name)
    assertEqual(#b.added, 0)
    assertEqual(b.status.text, "Looking up items" .. ELLIPSIS, "still waiting on two")
    assertEqual(requests[191396], asked396 + 1, "the ones still unnamed are asked for again")
    assertEqual(requests[191395], asked395, "a landed one is not")
    seedZephyr({ [191395] = true, [191396] = true, [191397] = true })
    mocks.__fireTimers()
    -- red under: adding one rank of a shared name (the owner's decision: never silently one rank)
    assertEqual(#b.added, 0, "neither one rank nor all of them")
    assertEqual(b.status.text, "Several items are named '" .. ZEPHYR ..
      "' \226\128\148 pick one from the list, or use the id.")
    assertTrue(b.status.color.r == 1 and b.status.color.b == 0, "in orange")
    assertEqual(b.eb.text, ZEPHYR, "the text stays")
    assertEqual(#mocks.__timers, 0)
  end)
end)

test("IdInput: a lookup that never lands gives up after a bounded wait, with the honest reason", function()
  countingLoads(function(requests)
    local b = inputBench({ kind = "item", candidates = function() return { 999001 } end })
    typeEnter(b.eb, ZEPHYR)
    local asked = requests[999001]
    local rounds = drainTimers(50)
    -- red under: re-asking for ever (an id the client does not have never loads)
    assertTrue(rounds < 50, "the wait ends on its own")
    assertEqual(requests[999001] - asked, 4, "five asks in all, the submit's included")
    assertEqual(#b.added, 0)
    assertEqual(b.status.text, "No item named '" .. ZEPHYR .. "' that the game can find. " .. ITEM_HINT)
    assertTrue(b.status.color.r == 1 and b.status.color.b == 0, "in orange")
  end)
end)

test("IdInput: a second submit, a changed box or a released box drops a pending lookup", function()
  countingLoads(function()
    local b = inputBench({ kind = "item", candidates = function() return { 191396 } end })
    seedZephyr()
    typeEnter(b.eb, ZEPHYR)
    typeEnter(b.eb, "6948")
    assertEqual(b.added[1], 6948)
    seedZephyr({ [191396] = true })
    drainTimers(10)
    -- red under: a stale lookup landing after a newer submit (the old name added behind its back)
    assertEqual(#b.added, 1, "the replaced lookup adds nothing")
    assertEqual(b.status.text, "", "and leaves the status line alone")

    local c = inputBench({ kind = "item", candidates = function() return { 191396 } end })
    seedZephyr()
    typeEnter(c.eb, ZEPHYR)
    c.eb:SetText("Hearth")
    seedZephyr({ [191396] = true })
    drainTimers(10)
    assertEqual(#c.added, 0, "a box the player typed over is not submitted for them")
    assertEqual(c.status.text, "", "the looking line goes")
    assertEqual(c.eb.text, "Hearth")

    local d = inputBench({ kind = "item", candidates = function() return { 191396 } end })
    seedZephyr()
    typeEnter(d.eb, ZEPHYR)
    local touched
    d.eb:Release()
    d.status.SetText = function() touched = true end
    d.eb.SetText = function() touched = true end
    seedZephyr({ [191396] = true })
    drainTimers(10)
    -- red under: a lookup writing to widgets AceGUI's pool may have handed to another page
    assertEqual(#d.added, 0)
    assertNil(touched, "nothing touches a released box or its status line")
  end)
end)

test("IdInput and IdList: built with item candidates, they ask for the unnamed ones up front", function()
  countingLoads(function(requests)
    local O, _, ctx = bench()
    seedIds()
    seedZephyr({ [191396] = true })
    O.IdInput(ctx, nil, { kind = "item", candidates = zephyrs, onAdd = function() end })
    -- red under: no pre-warm (a name among the host's candidates misses on the first try)
    assertEqual(requests[191395], 1); assertEqual(requests[191397], 1)
    assertNil(requests[191396], "a named candidate is not asked for")
    assertEqual(#mocks.__timers, 0, "a pre-warm waits for nothing")
    O.IdList(ctx, { kind = "item", candidates = zephyrs, entries = function() return {} end })
    assertEqual(requests.total, 2, "once per id per instance, however many renders")
    O.IdInput(ctx, nil, { kind = "spell", candidates = function() return { 99999 } end,
                          onAdd = function() end })
    assertEqual(requests.total, 2, "spells are not loaded")
    local many = {}
    for i = 1, 300 do many[i] = 800000 + i end
    O.IdInput(ctx, nil, { kind = "item", candidates = function() return many end, onAdd = function() end })
    assertEqual(requests.total, 202, "at most 200 a build")
    local saved = mocks.C_Item
    mocks.C_Item = nil
    local ok, err = pcall(O.IdInput, ctx, nil, { kind = "item", candidates = zephyrs, onAdd = function() end })
    mocks.C_Item = saved
    assertTrue(ok, tostring(err))
  end)
end)

test("IdInput: a name that finds nothing says where names work, per kind; the hint is exported", function()
  local O = Fixture.new()
  -- red under: no exported hint (a host's tooltip would restate the rule, and drift from it)
  assertEqual(O.ID_NAME_HINT.item, ITEM_HINT)
  assertEqual(O.ID_NAME_HINT.spell,
    "Names work for spells in your spellbook and ones this list knows; otherwise use the id or " ..
    "shift-click a link.")
  assertEqual(O.ID_NAME_HINT.currency,
    "Currency names work only for the currencies this list knows; otherwise use the id or " ..
    "shift-click a link.")
  O.ID_NAME_HINT.item = "changed"
  local other = Fixture.new()
  assertEqual(other.ID_NAME_HINT.item, ITEM_HINT, "each instance has its own copy")
  -- red under: one table shared by every instance (the new one rewrote the first one's change)
  assertEqual(O.ID_NAME_HINT.item, "changed", "a later instance leaves the first one's alone")
  assertTrue(not rawequal(O.ID_NAME_HINT, other.ID_NAME_HINT), "two tables, not one")

  local item = inputBench({ kind = "item" })
  typeEnter(item.eb, "Nope")
  -- red under: the old bare "No item named" (it reads as if the item does not exist)
  assertEqual(item.status.text, "No item named 'Nope' that the game can find. " .. ITEM_HINT)
  local currency = inputBench({ kind = "currency" })
  typeEnter(currency.eb, "Nope")
  assertEqual(currency.status.text, "No currency named 'Nope' that this list knows. " ..
    currency.O.ID_NAME_HINT.currency)
  local thing = inputBench({ kind = { noun = "thing" } })
  typeEnter(thing.eb, "Nope")
  assertEqual(thing.status.text, "No thing named 'Nope'.", "a host kind keeps the plain words")
  local custom = inputBench({ kind = "item", strings = { nameHint = "Custom hint." } })
  typeEnter(custom.eb, "Nope")
  assertEqual(custom.status.text, "No item named 'Nope' that the game can find. Custom hint.")
end)

test("IdInput: the looking line can be reworded", function()
  countingLoads(function()
    local b = inputBench({ kind = "item", candidates = function() return { 191396 } end,
                           strings = { looking = "Searching {plural} for '{text}'" } })
    seedZephyr()
    typeEnter(b.eb, ZEPHYR)
    -- red under: a hard-coded looking line (a localized host would show English)
    assertEqual(b.status.text, "Searching items for '" .. ZEPHYR .. "'")
  end)
end)

local AMBIGUOUS_ZEPHYR = "Several items are named '" .. ZEPHYR ..
  "' \226\128\148 pick one from the list, or use the id."

test("IdInput: a client hit on one rank waits for the uncached ranks, then refuses the name", function()
  countingLoads(function(requests)
    -- Rank 1 is in the bags (the client's name lookup answers it); ranks 2 and 3 are candidates the
    -- client has not cached, so nothing can tell yet that they share its name.
    local b = inputBench({ kind = "item", candidates = zephyrs })
    seedZephyr({ [191395] = true })
    typeEnter(b.eb, ZEPHYR)
    -- red under: adding the client's hit at once (one rank of a shared name, added silently)
    assertEqual(#b.added, 0, "nothing added while two candidates are unnamed")
    assertEqual(b.status.text, "Looking up items" .. ELLIPSIS)
    assertTrue(requests[191396] ~= nil and requests[191397] ~= nil, "the unnamed ranks are asked for")
    seedZephyr({ [191395] = true, [191396] = true, [191397] = true })
    drainTimers(10)
    assertEqual(#b.added, 0, "neither one rank nor all of them")
    assertEqual(b.status.text, AMBIGUOUS_ZEPHYR)
    assertEqual(b.eb.text, ZEPHYR, "the text stays")

    -- The rank in the bags need not be a candidate: the other two still share its name.
    local c = inputBench({ kind = "item", candidates = function() return { 191396, 191397 } end })
    seedZephyr({ [191395] = true })
    typeEnter(c.eb, ZEPHYR)
    assertEqual(#c.added, 0)
    seedZephyr({ [191395] = true, [191396] = true, [191397] = true })
    drainTimers(10)
    assertEqual(#c.added, 0)
    assertEqual(c.status.text, AMBIGUOUS_ZEPHYR)
  end)
end)

test("IdInput: a name hit waits on unnamed candidates, then adds; a number or a link never waits", function()
  countingLoads(function(requests)
    local b = inputBench({ kind = "item", candidates = function() return { 6948, 2589 } end })
    typeEnter(b.eb, "Hearthstone")
    -- red under: no wait (the uncached candidate could have carried the same name)
    assertEqual(#b.added, 0, "waits while a candidate is unnamed")
    assertEqual(b.status.text, "Looking up items" .. ELLIPSIS)
    mocks.addIdRecord("item", 2589, "Linen Cloth", 132889, nil, 1)
    drainTimers(10)
    assertEqual(#b.added, 1, "a name no other candidate carries is added once they land")
    assertEqual(b.added[1], 6948)

    local c = inputBench({ kind = "item", candidates = function() return { 6948, 2589 } end })
    local before = requests.total
    typeEnter(c.eb, "6948")
    assertEqual(c.added[1], 6948, "a number is added at once")
    typeEnter(c.eb, "|cffffffff|Hitem:19019::::::::|h[Thunderfury]|h|r")
    assertEqual(c.added[2], 19019, "a link is added at once")
    assertEqual(#mocks.__timers, 0, "neither waits")
    assertTrue(requests.total - before <= 1, "at most the pre-warm's one ask")
  end)
end)

--- ConsumableMaster's shape: a host kind whose `resolve` takes digits and links itself and hands a
--- name to O.ResolveId("item", text, candidates), with the item kind's words forwarded through
--- `__index`. `loads` and `info` are what opt it into the pre-warm and the lookup.
local function hostItemKind(O)
  local base = { lookup = "item", noun = "item", plural = "items", loads = true,
                 info = function(id) return mocks.C_Item.GetItemNameByID(id) end }
  return setmetatable({
    resolve = function(text, candidates)
      local id = tonumber(text:match("^%d+$")) or tonumber(text:match("item:(%d+)"))
      if id then return id end
      return O.ResolveId(base.lookup, text, candidates)
    end,
  }, { __index = function(_, key) return base[key] end })
end

test("IdInput: a host kind with resolve, loads and info is looked up, and refuses a shared name", function()
  countingLoads(function(requests)
    local O, _, ctx = bench()
    seedIds()
    seedZephyr()
    local added = {}
    local function onAdd(id) added[#added + 1] = id end
    local strings = { notFound = "No {noun} named '{text}'. {hint}", nameHint = "Host hint." }
    local kind = hostItemKind(O)
    assertEqual(table.concat(O.UnnamedCandidates(kind, zephyrs), ","), "191395,191396,191397")
    local _, eb, _, status = O.IdInput(ctx, nil, { kind = kind, candidates = zephyrs,
                                                   strings = strings, onAdd = onAdd })
    assertEqual(requests[191395], 1, "pre-warmed through the host kind")
    typeEnter(eb, ZEPHYR)
    assertEqual(status.text, "Looking up items" .. ELLIPSIS)
    seedZephyr({ [191395] = true, [191396] = true, [191397] = true })
    drainTimers(10)
    assertEqual(#added, 0, "no rank added")
    assertEqual(status.text, AMBIGUOUS_ZEPHYR)

    -- One rank in the bags, the others unnamed: the host's own resolver answers the client's hit,
    -- and the widget still waits.
    local O2, _, ctx2 = bench()
    seedIds()
    seedZephyr({ [191395] = true })
    local _, eb2, _, status2 = O2.IdInput(ctx2, nil, { kind = hostItemKind(O2), candidates = zephyrs,
                                                       strings = strings, onAdd = onAdd })
    typeEnter(eb2, ZEPHYR)
    -- red under: a host resolver's hit added before the unnamed ranks land
    assertEqual(#added, 0)
    seedZephyr({ [191395] = true, [191396] = true, [191397] = true })
    drainTimers(10)
    assertEqual(#added, 0)
    assertEqual(status2.text, AMBIGUOUS_ZEPHYR)

    local plain = setmetatable({ resolve = hostItemKind(O).resolve },
      { __index = { noun = "item", plural = "items" } })
    assertEqual(#O.UnnamedCandidates(plain, zephyrs), 0, "a host kind without loads is not looked up")
  end)
end)

test("IdInput: a second submit of the same text replaces the pending lookup", function()
  countingLoads(function()
    local calls = 0
    local b = inputBench({ kind = "item",
                           candidates = function() calls = calls + 1; return zephyrs() end })
    seedZephyr()
    typeEnter(b.eb, ZEPHYR)
    seedZephyr({ [191395] = true, [191396] = true, [191397] = true })
    typeEnter(b.eb, ZEPHYR)
    assertEqual(b.status.text, AMBIGUOUS_ZEPHYR, "the second submit answers on its own")
    local before = calls
    drainTimers(10)
    -- red under: a submit that leaves the older lookup in place (its check resolves the text again)
    assertEqual(calls, before, "the first lookup's check does nothing")
    assertEqual(b.status.text, AMBIGUOUS_ZEPHYR)

    local c = inputBench({ kind = "item", candidates = zephyrs })
    seedZephyr()
    typeEnter(c.eb, ZEPHYR)
    typeEnter(c.eb, "")
    drainTimers(10)
    assertEqual(c.status.text, "Type an id, a link or a name.",
      "an empty submit's message is not wiped by the lookup it replaced")
  end)
end)

test("IdInput: ids a lookup could not load are skipped, so later candidates get their turn", function()
  countingLoads(function(requests)
    local list = {}
    for i = 1, 200 do list[i] = 900000 + i end -- never load: retired or invalid ids
    list[201] = 191396
    local b = inputBench({ kind = "item", candidates = function() return list end })
    mocks.addIdRecord("item", 191396, "Rare Draught", 4638, true, 1)
    typeEnter(b.eb, "Rare Draught")
    assertNil(requests[191396], "past the cap: neither the pre-warm nor the first window asks")
    drainTimers(5)
    -- red under: a lookup that stops at the first 200 (a name among later candidates never resolves)
    assertEqual(requests[191396], 1, "the first window exhausted, the next one asks for it")
    assertEqual(b.status.text, "Looking up items" .. ELLIPSIS, "still looking")
    assertEqual(#b.added, 0)
    mocks.addIdRecord("item", 191396, "Rare Draught", 4638, nil, 1)
    drainTimers(10)
    assertEqual(b.added[1], 191396, "added once the later candidate lands")
    assertEqual(requests[900001], 6, "a dead id: the pre-warm's ask and the lookup's five")
    local asked = requests.total
    typeEnter(b.eb, "Nope")
    -- red under: re-asking the same dead ids on every Enter for the full wait
    assertEqual(requests.total, asked, "a later Enter does not ask for the dead ids again")
    assertEqual(b.status.text, "No item named 'Nope' that the game can find. " .. ITEM_HINT)
  end)
end)

test("IdInput: a lookup runs at most five windows of 200; the next Enter carries on past them", function()
  countingLoads(function(requests)
    local list = {}
    for i = 1, 1200 do list[i] = 900000 + i end -- none ever loads
    local b = inputBench({ kind = "item", candidates = function() return list end })
    typeEnter(b.eb, "Rare Draught")
    local rounds = drainTimers(100)
    assertTrue(rounds < 100, "the lookup ends on its own")
    assertEqual(requests[901000], 5, "the fifth window's last id was asked for")
    -- red under: windows without a bound (one typed name asking for every candidate there is)
    assertNil(requests[901001], "a sixth window is never asked for")
    assertEqual(b.status.text, "No item named 'Rare Draught' that the game can find. " .. ITEM_HINT)
    typeEnter(b.eb, "Rare Draught")
    assertEqual(requests[901001], 1, "the next Enter moves on to the ids after them")
    assertEqual(requests[900001], 6, "and never back to a dead one: the pre-warm's ask and five")
  end)
end)

test("IdInput and IdList: pre-warm moves past the ids it has asked for, and reads each id once", function()
  countingLoads(function(requests)
    local O, _, ctx = bench()
    seedIds()
    local many = {}
    for i = 1, 300 do many[i] = 800000 + i end
    local function draw()
      O.IdInput(ctx, nil, { kind = "item", candidates = function() return many end,
                            onAdd = function() end })
    end
    draw()
    assertEqual(requests.total, 200)
    draw()
    -- red under: a window that restarts at the first 200 (the last 100 are never warmed)
    assertEqual(requests.total, 300, "the second build warms the next ones")

    local reads = 0
    local realName = mocks.C_Item.GetItemNameByID
    mocks.C_Item.GetItemNameByID = function(id) reads = reads + 1; return realName(id) end
    local named = function() return { 6948, 19019 } end
    O.IdInput(ctx, nil, { kind = "item", candidates = named, onAdd = function() end })
    local first = reads
    O.IdList(ctx, { kind = "item", candidates = named, entries = function() return {} end })
    mocks.C_Item.GetItemNameByID = realName
    assertTrue(first > 0)
    -- red under: every draw rescanning every candidate's name
    assertEqual(reads, first, "a redraw does not read the candidates' names again")
  end)
end)
