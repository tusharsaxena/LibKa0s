-- tests/test_mock_foreverdb.lua -- the kit's opt-in fake of the ForeverDB data addon (revision 61,
-- testkit/mock_foreverdb.lua).
--
-- What a consumer's suite leans on: each preset's C_AddOns answers, the global handed over AT the
-- load and never before it, the load count, the consumer's own C_AddOns members kept, the client
-- constants, and a restore that puts everything back. Every case builds a fresh mock, for the
-- reason `tests/test_mock_record.lua` gives.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil = T.test, T.assertEqual, T.assertTrue,
  T.assertFalse, T.assertNil
local assertErrorMatches = T.assertErrorMatches

local buildMocks = dofile("tests/wow_mock.lua")
local FDB = dofile("tests/_kit/mock_foreverdb.lua")
local I = FDB.IDS

test("foreverdb mock: present hands the database over at the load, and counts it", function()
  local M = buildMocks()
  local fake = FDB.install(M)
  assertEqual(fake.preset, "present")
  assertTrue(M.C_AddOns.DoesAddOnExist("ForeverDB"))
  assertFalse((M.C_AddOns.IsAddOnLoaded("ForeverDB")))
  assertNil(M.ForeverDB, "a LoadOnDemand global does not exist before its load")
  assertEqual(M.C_AddOns.GetAddOnMetadata("ForeverDB", "Version"), FDB.VERSION, "readable unloaded")
  local ok, reason = M.C_AddOns.LoadAddOn("ForeverDB")
  assertTrue(ok); assertNil(reason)
  assertEqual(fake.loads, 1)
  assertTrue(M.ForeverDB == fake.data, "the database is the global now")
  assertTrue((M.C_AddOns.IsAddOnLoaded("ForeverDB")))
  fake.restore()
end)

test("foreverdb mock: missing, loadfails and reshaped answer as the client does", function()
  local M = buildMocks()
  local fake = FDB.install(M, { preset = "missing" })
  assertFalse(M.C_AddOns.DoesAddOnExist("ForeverDB"))
  assertEqual(select(5, M.C_AddOns.GetAddOnInfo("ForeverDB")), "MISSING")
  assertEqual(select(2, M.C_AddOns.LoadAddOn("ForeverDB")), "MISSING")
  assertNil(M.ForeverDB); assertNil(fake.data)
  fake.restore()

  fake = FDB.install(M, { preset = "loadfails" })
  assertTrue(M.C_AddOns.DoesAddOnExist("ForeverDB"))
  assertEqual(select(5, M.C_AddOns.GetAddOnInfo("ForeverDB")), "DISABLED")
  local ok, reason = M.C_AddOns.LoadAddOn("ForeverDB")
  assertFalse(ok); assertEqual(reason, "DISABLED"); assertEqual(fake.loads, 1)
  assertNil(M.ForeverDB)
  fake.restore()

  fake = FDB.install(M, { preset = "reshaped" })
  assertTrue((M.C_AddOns.LoadAddOn("ForeverDB")))
  assertEqual(M.ForeverDB, "ForeverDB", "loaded, and not a table")
  fake.restore()
  assertErrorMatches(function() FDB.install(M, { preset = "absent" }) end, "unknown preset")
end)

test("foreverdb mock: the consumer's own C_AddOns members survive, and restore puts them back", function()
  local M = buildMocks()
  local before = M.C_AddOns
  local fake = FDB.install(M, { preset = "present" })
  assertEqual(M.C_AddOns.GetAddOnMetadata("Host", "Version"), "1.2.3", "the mock's own answer")
  assertFalse(M.C_AddOns.DoesAddOnExist("SomethingElse"))
  assertEqual(select(2, M.C_AddOns.LoadAddOn("SomethingElse")), "MISSING")
  assertEqual(fake.loads, 0, "only ForeverDB's loads count")
  fake.restore()
  assertTrue(M.C_AddOns == before, "the mock's table again")
  assertNil(M.ForeverDB)
end)

test("foreverdb mock: loaded and loadNow model another addon's load", function()
  local M = buildMocks()
  local fake = FDB.install(M, { loaded = true })
  assertTrue((M.C_AddOns.IsAddOnLoaded("ForeverDB")))
  assertTrue(M.ForeverDB == fake.data); assertEqual(fake.loads, 0)
  fake.restore()
  fake = FDB.install(M)
  fake.loadNow()
  assertTrue(M.ForeverDB == fake.data); assertEqual(fake.loads, 0, "not this addon's load")
  fake.restore()
end)

test("foreverdb mock: client sets the project constants and restore puts them back", function()
  local M = buildMocks()
  M.WOW_PROJECT_ID, M.WOW_PROJECT_CAMELOT = 7, 8
  local fake = FDB.install(M, { client = "forever" })
  assertEqual(M.WOW_PROJECT_ID, 18); assertEqual(M.WOW_PROJECT_CAMELOT, 18)
  fake.restore()
  assertEqual(M.WOW_PROJECT_ID, 7); assertEqual(M.WOW_PROJECT_CAMELOT, 8)
  fake = FDB.install(M, { client = "retail" })
  assertEqual(M.WOW_PROJECT_ID, 1); assertNil(M.WOW_PROJECT_CAMELOT)
  fake.restore()
  assertErrorMatches(function() FDB.install(M, { client = "classic" }) end, "unknown client")
end)

test("foreverdb mock: the fixture is fresh per call, invented, and in ForeverDB's shape", function()
  local a, b = FDB.fixture(), FDB.fixture()
  assertTrue(a ~= b and a.npc ~= b.npc, "a fresh copy each time")
  for role, n in pairs(I) do
    if role:sub(1, 3) ~= "map" then
      assertTrue(n >= 990000 and n <= 990999, role .. " is in the invented id range")
    end
  end
  assertEqual(type(a.npc[I.gnoll][1]), "string", "rows are positional")
  assertEqual(#a.drop[I.blade] % 2, 0, "drop lists are flat pairs")
  assertTrue(a.spm["c" .. I.gnoll] ~= nil and a.spm["o" .. I.crate] ~= nil, "c<id> and o<id> keys")
  assertEqual(a.qg[I.errand][1], "c" .. I.gnoll)
end)
