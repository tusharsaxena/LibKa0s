-- tests/test_foreverdb_lookups.lua -- LibKa0s-ForeverDB-1.0 minor 2, the lookups Drop Watcher's
-- Item Search makes: SearchItems, QuestsForItem, RewardFrom, StartsQuest and SkinnedFrom.
--
-- The same conventions as tests/test_foreverdb.lua: every case installs the kit's fake
-- (tests/_kit/mock_foreverdb.lua, kit revision 63) with the client it means, so a case reads the
-- same under both kit profiles, and resets the adapter's session state before and after. Every row
-- is INVENTED (ForeverDB is GPL-3.0 and this repo is MIT).

local T = _G.LK_TEST
local fdbLib, mocks = T.foreverdb, T.mocks
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil

local FDB = dofile("tests/_kit/mock_foreverdb.lua")
local I   = FDB.IDS

local function with(opts, fn)
  opts = opts or {}
  if opts.client == nil then opts.client = "forever" end
  local fake = FDB.install(mocks, opts)
  fdbLib.__reset()
  local ok, err = pcall(fn, fake)
  fake.restore()
  fdbLib.__reset()
  if not ok then error(err, 0) end
end

local function ids(rows)
  local out = {}
  for _, r in ipairs(rows) do out[#out + 1] = tostring(r.id) end
  return table.concat(out, ",")
end

local function list(...)
  local out = {}
  for _, n in ipairs({ ... }) do out[#out + 1] = tostring(n) end
  return table.concat(out, ",")
end

--- Every minor-2 lookup with a known id, each answer collected.
local function everyLookup()
  return {
    SearchItems = fdbLib.SearchItems("blade"), QuestsForItem = fdbLib.QuestsForItem(I.leather),
    RewardFrom = fdbLib.RewardFrom(I.cloak), StartsQuest = fdbLib.StartsQuest(I.letter),
    SkinnedFrom = fdbLib.SkinnedFrom(I.leather),
  }
end

--- The degraded answers: `{}` for the four list lookups, nil for StartsQuest.
local function assertDegraded(label)
  local got = everyLookup()
  for name, v in pairs(got) do
    if name == "StartsQuest" then
      assertNil(v, label .. ": StartsQuest")
    else
      assertEqual(type(v), "table", label .. ": " .. name .. " is a table")
      assertEqual(#v, 0, label .. ": " .. name .. " is empty")
      assertNil(next(v), label .. ": " .. name .. " has no keys")
    end
  end
end

-- -- registration -------------------------------------------------------------------------------

test("foreverdb lookups: minor 2 registers the five new members", function()
  assertEqual(fdbLib.MINOR, 2)
  assertEqual(fdbLib.MODULES.ForeverDB, 2)
  for _, name in ipairs({ "SearchItems", "QuestsForItem", "RewardFrom", "StartsQuest", "SkinnedFrom" }) do
    assertEqual(type(fdbLib[name]), "function", name)
  end
end)

-- -- degradation --------------------------------------------------------------------------------

test("foreverdb lookups: missing, loadfails, reshaped and Retail answer {} or nil", function()
  for _, opts in ipairs({
    { preset = "missing" }, { preset = "loadfails" }, { preset = "reshaped" },
    { preset = "present", client = "retail" },
  }) do
    with(opts, function(fake)
      local label = opts.preset .. "/" .. (opts.client or "forever")
      assertDegraded(label)
      if opts.client == "retail" then assertEqual(fake.loads, 0, "Retail never loads it") end
    end)
  end
end)

test("foreverdb lookups: a database without the tables answers {} or nil", function()
  local D = FDB.fixture()
  D.item, D.qx, D.rew, D.start, D.skin = nil, nil, nil, nil, nil
  with({ data = D }, function() assertDegraded("tables absent") end)
  D = FDB.fixture()
  D.item, D.qx, D.rew, D.start, D.skin = 1, "x", true, 2, "y"
  with({ data = D }, function() assertDegraded("tables reshaped") end)
end)

test("foreverdb lookups: a bad id is no answer, and nothing raises", function()
  with({}, function()
    for _, bad in ipairs({ "990104", -1, 0, {}, true }) do
      assertEqual(#fdbLib.QuestsForItem(bad), 0)
      assertEqual(#fdbLib.RewardFrom(bad), 0)
      assertNil(fdbLib.StartsQuest(bad))
      assertEqual(#fdbLib.SkinnedFrom(bad), 0)
    end
    assertEqual(#fdbLib.QuestsForItem(nil), 0); assertNil(fdbLib.StartsQuest(nil))
    assertEqual(#fdbLib.QuestsForItem(990999), 0, "an unknown item")
    assertEqual(#fdbLib.SkinnedFrom(I.blade), 0, "not skinned from anything")
    assertNil(fdbLib.StartsQuest(I.blade), "starts nothing")
  end)
end)

test("foreverdb lookups: the first lookup is the load, and there is only one", function()
  with({}, function(fake)
    assertEqual(fake.loads, 0)
    fdbLib.SearchItems("x")
    assertEqual(fake.loads, 0, "a query too short to search looks nothing up")
    fdbLib.SearchItems("fixture")
    assertEqual(fake.loads, 1, "the first search loads")
    fdbLib.QuestsForItem(I.leather); fdbLib.RewardFrom(I.blade)
    fdbLib.StartsQuest(I.letter); fdbLib.SkinnedFrom(I.leather)
    assertEqual(fake.loads, 1, "and nothing loads again")
  end)
end)

-- -- SearchItems ---------------------------------------------------------------------------------

test("foreverdb lookups: SearchItems orders prefix matches, then shorter names, then id", function()
  with({}, function()
    local got = fdbLib.SearchItems("blade")
    assertEqual(ids(got), list(I.shard, I.blade, I.cloak), "prefix, then 13 before 24 characters")
    local r = got[2]
    assertEqual(r.name, "Fixture Blade", "the name as the database spells it")
    assertEqual(r.quality, 2); assertEqual(r.icon, 9990001); assertEqual(r.requiredLevel, 10)
    assertEqual(ids(fdbLib.SearchItems("Fixture Hide")), list(I.hide))
    assertEqual(ids(fdbLib.SearchItems("FIXTURE")),
      list(I.hide, I.blade, I.pebble, I.coffer, I.letter, I.leather, I.cloak, I.shard),
      "case-insensitive; equal lengths (14) break on id; the one non-prefix match last")
  end)
end)

test("foreverdb lookups: SearchItems is plain, trimmed, limited, and silent under two characters", function()
  with({}, function()
    assertEqual(#fdbLib.SearchItems("b"), 0, "one character")
    assertEqual(#fdbLib.SearchItems("  b  "), 0, "one character once trimmed")
    assertEqual(#fdbLib.SearchItems(""), 0)
    assertEqual(#fdbLib.SearchItems(nil), 0); assertEqual(#fdbLib.SearchItems(42), 0)
    assertEqual(#fdbLib.SearchItems("%a+"), 0, "no pattern: nothing is literally named %a+")
    assertEqual(#fdbLib.SearchItems("fix.ure"), 0, "a dot is a dot")
    assertEqual(ids(fdbLib.SearchItems("  blade ")), list(I.shard, I.blade, I.cloak), "trimmed")
    assertEqual(#fdbLib.SearchItems("fixture"), 8, "every item, under the default limit")
    assertEqual(#fdbLib.SearchItems("fixture", 3), 3)
    assertEqual(#fdbLib.SearchItems("fixture", 2.7), 2, "a fractional limit is floored")
    assertEqual(#fdbLib.SearchItems("fixture", 0), 8, "a limit under 1 is the default")
    assertEqual(#fdbLib.SearchItems("fixture", "3"), 8, "a limit that is not a number is the default")
    assertEqual(#fdbLib.SearchItems("no such thing"), 0)
  end)
end)

test("foreverdb lookups: a query of digits matches that id first", function()
  with({}, function()
    local got = fdbLib.SearchItems(tostring(I.cloak))
    assertEqual(#got, 1); assertEqual(got[1].id, I.cloak)
    assertEqual(got[1].name, "Fixture Bladeweave Cloak")
    assertEqual(#fdbLib.SearchItems("990999"), 0, "no such item")
  end)
  local D = FDB.fixture()
  D.item[I.pebble] = { "Fixture " .. I.cloak, 0, 0, nil, 15, 0, 0, 9990002 }
  with({ data = D }, function()
    assertEqual(ids(fdbLib.SearchItems(tostring(I.cloak))), list(I.cloak, I.pebble),
      "the id first, then a name holding the digits, never the id twice")
    assertEqual(#fdbLib.SearchItems(tostring(I.cloak), 1), 1, "the id counts toward the limit")
  end)
end)

test("foreverdb lookups: SearchItems answers fresh rows and skips rows with no name", function()
  local D = FDB.fixture()
  D.item[990150] = { 42 }
  D.item[990151] = "not a row"
  D.item.key = { "Fixture Key" }
  with({ data = D }, function(fake)
    local got = fdbLib.SearchItems("fixture")
    assertEqual(#got, 8, "only well-formed rows with numeric ids")
    got[1].name = "Edited"
    assertEqual(fdbLib.SearchItems("bladed")[1].name, "Bladed Fixture Shard", "an edit reaches nothing")
    assertEqual(fake.data.item[I.shard][1], "Bladed Fixture Shard")
  end)
end)

test("foreverdb lookups: the name index is built once and follows a swapped item table", function()
  with({}, function(fake)
    assertEqual(#fdbLib.SearchItems("fixture"), 8)
    fake.data.item[990160] = { "Fixture Late Arrival", 1, 0, 1, 15, 0, 0, 9990010 }
    assertEqual(#fdbLib.SearchItems("late arrival"), 0, "the index is the session's, not rebuilt per call")
    local items = {}
    for k, v in pairs(fake.data.item) do items[k] = v end
    fake.data.item = items
    assertEqual(ids(fdbLib.SearchItems("late arrival")), list(990160), "a new item table is indexed afresh")
    fake.data.item = FDB.fixture().item
    fdbLib.__reset()
    assertEqual(#fdbLib.SearchItems("late arrival"), 0, "__reset forgets the index")
  end)
end)

-- -- QuestsForItem -------------------------------------------------------------------------------

test("foreverdb lookups: QuestsForItem maps qx and quest, by quest id", function()
  with({}, function()
    local got = fdbLib.QuestsForItem(I.leather)
    assertEqual(ids(got), list(I.errand, I.hunt))
    local e, h = got[1], got[2]
    assertEqual(e.title, "Fixture Errand"); assertEqual(e.level, 12); assertEqual(e.minLevel, 8)
    assertEqual(e.races, 5); assertNil(e.classes, "a nil mask is any")
    assertEqual(#e.preQuests, 0, "no prequests is an empty array")
    assertEqual(h.title, "Fixture Hunt"); assertEqual(h.level, 14); assertEqual(h.minLevel, 10)
    assertNil(h.races, "a 0 mask is any"); assertEqual(h.classes, 9)
    assertEqual(list(unpack(h.preQuests)), list(I.errand, I.summons), "fields 3 and 4 merged, no repeats")
    assertEqual(ids(fdbLib.QuestsForItem(I.hide)), list(I.errand))
  end)
end)

test("foreverdb lookups: QuestsForItem skips bad entries and keeps a quest with no quest row", function()
  local D = FDB.fixture()
  D.qx[990250] = { 0, 0, "x", { "y", I.hunt, -2 }, nil, nil, nil, nil, nil, { I.leather, I.leather, "z" } }
  D.qx[990251] = "not a row"
  D.qx[990252] = { 0, 0, nil, nil, nil, nil, nil, nil, nil, "not a list" }
  D.qx.bad = { 0, 0, nil, nil, nil, nil, nil, nil, nil, { I.leather } }
  with({ data = D }, function()
    local got = fdbLib.QuestsForItem(I.leather)
    assertEqual(ids(got), list(I.errand, I.hunt, 990250), "an item listed twice counts once")
    local q = got[3]
    assertNil(q.title); assertNil(q.level); assertNil(q.minLevel)
    assertEqual(list(unpack(q.preQuests)), list(I.hunt), "only the numeric prequest")
  end)
end)

test("foreverdb lookups: QuestsForItem answers fresh rows and builds its index once", function()
  with({}, function(fake)
    local got = fdbLib.QuestsForItem(I.leather)
    got[1].preQuests[1] = 1; got[2] = nil
    assertEqual(#fdbLib.QuestsForItem(I.leather), 2, "an edit reaches nothing")
    fake.data.qx[990260] = { 0, 0, nil, nil, nil, nil, nil, nil, nil, { I.leather } }
    assertEqual(#fdbLib.QuestsForItem(I.leather), 2, "the session's index")
    fdbLib.__reset()
    assertEqual(#fdbLib.QuestsForItem(I.leather), 3, "__reset forgets it")
  end)
end)

-- -- RewardFrom, StartsQuest, SkinnedFrom ---------------------------------------------------------

test("foreverdb lookups: RewardFrom answers rew's quests, in order, once each", function()
  local D = FDB.fixture()
  D.rew[I.cloak] = { I.hunt, I.errand, I.hunt, "x", 990299 }
  with({ data = D }, function()
    local got = fdbLib.RewardFrom(I.cloak)
    assertEqual(ids(got), list(I.hunt, I.errand, 990299))
    assertEqual(got[1].title, "Fixture Hunt"); assertEqual(got[1].level, 14)
    assertNil(got[1].minLevel, "{ id, title, level } only")
    assertNil(got[3].title, "a quest with no quest row keeps its id")
    assertEqual(ids(fdbLib.RewardFrom(I.blade)), list(I.errand))
    assertEqual(#fdbLib.RewardFrom(I.pebble), 0)
  end)
end)

test("foreverdb lookups: StartsQuest answers start's quest", function()
  local D = FDB.fixture()
  D.start[I.pebble] = "x"
  D.start[I.hide] = 990299
  with({ data = D }, function(fake)
    local q = fdbLib.StartsQuest(I.letter)
    assertEqual(q.id, I.summons); assertEqual(q.title, "Fixture Summons"); assertEqual(q.level, 15)
    assertTrue(q ~= fake.data.quest[I.summons], "a fresh table")
    assertNil(fdbLib.StartsQuest(I.pebble), "a value that is not an id")
    local orphan = fdbLib.StartsQuest(I.hide)
    assertEqual(orphan.id, 990299); assertNil(orphan.title)
  end)
end)

test("foreverdb lookups: SkinnedFrom names and sorts the creatures, chances on 0..1", function()
  with({}, function()
    local got = fdbLib.SkinnedFrom(I.leather)
    assertEqual(ids(got), list(I.kobold, I.gnoll), "most likely first")
    assertEqual(got[1].name, "Fixture Kobold"); assertEqual(got[1].chance, 0.75)
    assertEqual(got[2].name, "Fixture Gnoll"); assertEqual(got[2].chance, 0.25)
    local hide = fdbLib.SkinnedFrom(I.hide)
    assertEqual(#hide, 1); assertNil(hide[1].chance, "0 = the rate unknown")
  end)
  local D = FDB.fixture()
  D.skin[I.leather] = { I.gnoll, 20000, "x", 100, 990099, 0, I.kobold, 100 }
  with({ data = D }, function()
    local got = fdbLib.SkinnedFrom(I.leather)
    assertEqual(ids(got), list(I.kobold, I.gnoll, 990099), "known rates first, unknown by id")
    assertNil(got[2].chance, "out of range reads as unknown")
    assertNil(got[3].name, "a creature with no npc row")
  end)
end)
