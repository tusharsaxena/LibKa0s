-- tests/test_foreverdb.lua -- LibKa0s-ForeverDB-1.0, the reader of WoW Forever's ForeverDB data
-- addon (LibKa0s#105).
--
-- Every case installs the kit's fake (tests/_kit/mock_foreverdb.lua, kit revision 61; its `obj`
-- rows for minor 3's Object since revision 64; minor 4's spots, vendx and Full fake since revision
-- 65, exercised in tests/test_foreverdb_spots.lua) with the
-- client it means, so a case reads the same under both kit profiles (`lua tests/run.lua` and
-- `KA0S_KIT_CLIENT=forever lua tests/run.lua`), and puts everything back after. The database the
-- fake hands over is INVENTED in ForeverDB's real shape: ForeverDB is GPL-3.0 and this repo is MIT,
-- so no real row appears here (the fake's header says what was copied: the shape alone).
--
-- The adapter keeps its Available() answer for the session, so every case starts and ends with
-- `__reset()`, the seam that exists for exactly this.

local T = _G.LK_TEST
local fdbLib, mocks, debuglog = T.foreverdb, T.mocks, T.debuglog
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local Loader     = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")
local FDB        = dofile("tests/_kit/mock_foreverdb.lua")
local I          = FDB.IDS

--- Run `fn(fake)` with the fake installed on the shared mock (`opts` as FDB.install takes them,
--- client "forever" unless given), then restore and reset, re-raising a failure.
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

local function pack(...) return { n = select("#", ...), ... } end

--- Every lookup, called once with a known id, each answer collected.
local function everyLookup()
  local p = pack(fdbLib.VendorPrice(I.blade))
  return {
    Meta = fdbLib.Meta(), NPC = fdbLib.NPC(I.gnoll), Item = fdbLib.Item(I.blade),
    Object = fdbLib.Object(I.crate),
    Quest = fdbLib.Quest(I.errand), ItemSources = fdbLib.ItemSources(I.blade),
    VendorPrice = p[1], Spots = fdbLib.Spots("npc", I.gnoll),
    TrainerSpells = fdbLib.TrainerSpells(I.trainer),
    VendorPriceAt = (fdbLib.VendorPriceAt(I.vendor, I.blade)),
    WorldToMap = (fdbLib.WorldToMap(I.continent, 600, -250)),
    SpotsFromWorld = fdbLib.Spots("npc", I.wanderer),
  }
end

local function assertNoAnswers(label)
  for name, v in pairs(everyLookup()) do assertNil(v, label .. ": " .. name) end
end

--- A fresh environment with the fake installed BEFORE the library's files load, and the files.
--- The kit profile is applied first (`Loader.makeEnv`), so the fake's client constants are the
--- ones the files read rather than being overwritten by the profile at the first load.
local function freshEnv(opts, files)
  local M = buildMocks()
  Loader.makeEnv(M)
  local fake = FDB.install(M, opts)
  for _, file in ipairs(files) do
    Loader.loadSource(Loader.readFile("LibKa0s/" .. file .. ".lua"), "@LibKa0s/" .. file .. ".lua", nil, M)
  end
  return M, fake
end

-- -- registration and shape -------------------------------------------------------------------

test("foreverdb: registers minor 4 with exactly its public members", function()
  assertEqual(fdbLib.MAJOR, "LibKa0s-ForeverDB-1.0")
  assertEqual(fdbLib.MINOR, 4)
  assertEqual(fdbLib.MODULES.ForeverDB, 4)
  local names = {}
  for _, member in ipairs(T.publicMembers(fdbLib)) do
    names[#names + 1] = member.name .. ":" .. member.kind
  end
  assertEqual(table.concat(names, ","), "Available:function,FullCost:function,FullStatus:function,"
    .. "IsLoaded:function,Item:function,ItemSources:function,LoadFull:function,Meta:function,NPC:function,"
    .. "Object:function,Quest:function,QuestsForItem:function,"
    .. "RewardFrom:function,SearchItems:function,SkinnedFrom:function,Spots:function,"
    .. "StartsQuest:function,Status:function,TrainerSpells:function,VendorPrice:function,"
    .. "VendorPriceAt:function,WorldToMap:function")
end)

test("foreverdb: the Core floor keeps the major absent from a payload without Core", function()
  local src = Loader.readFile("LibKa0s/ForeverDB.lua")
  local bare = buildMocks()
  Loader.loadSource(src, "@LibKa0s/ForeverDB.lua", nil, bare)
  assertNil(bare.LibStub("LibKa0s-ForeverDB-1.0", true), "no Core: no NewLibrary")
  Loader.loadSource(Loader.readFile("LibKa0s/Core.lua"), "@LibKa0s/Core.lua", nil, bare)
  Loader.loadSource(src, "@LibKa0s/ForeverDB.lua", nil, bare)
  assertTrue(bare.LibStub("LibKa0s-ForeverDB-1.0", true) ~= nil, "with Core: registered")
end)

test("foreverdb: the source reads every global bare, and calls LoadAddOn once per addon", function()
  local src = Loader.readFile("LibKa0s/ForeverDB.lua")
  assertFalse(src:find("_G.", 1, true), "ForeverDB.lua reads a global through `_G.`")
  assertFalse(src:find("_G[", 1, true), "ForeverDB.lua reads a global through `_G[`")
  local calls = 0
  for _ in src:gmatch("A%.LoadAddOn%(") do calls = calls + 1 end
  assertEqual(calls, 2, "two LoadAddOn call sites")
  local base, full = 0, 0
  for _ in src:gmatch("A%.LoadAddOn%(ADDON%)") do base = base + 1 end
  for _ in src:gmatch("A%.LoadAddOn%(FULL%)") do full = full + 1 end
  assertEqual(base, 1, "Available()'s, for ForeverDB")
  assertEqual(full, 1, "LoadFull()'s, for ForeverDB_Full")
  assertFalse(src:find("pcall(", 1, true), "no pcall: defensive type checks instead")
end)

-- -- nothing loads at file load -----------------------------------------------------------------

test("foreverdb: loading the library loads nothing; the first lookup is the load", function()
  local M, fake = freshEnv({ preset = "present", client = "forever" }, { "Core", "Compat", "ForeverDB" })
  local lib = M.LibStub("LibKa0s-ForeverDB-1.0")
  assertEqual(fake.loads, 0, "no LoadAddOn at file load")
  assertNil(M.ForeverDB, "and no global yet")
  assertFalse(lib.IsLoaded(), "IsLoaded reads, never loads")
  local st = lib.Status()
  assertEqual(fake.loads, 0, "neither does Status")
  assertTrue(st.present); assertFalse(st.loaded)
  local npc = lib.NPC(I.gnoll)
  assertEqual(fake.loads, 1, "the first lookup loads")
  assertEqual(npc.name, "Fixture Gnoll")
  lib.Item(I.blade); lib.Available(); lib.ItemSources(I.blade)
  assertEqual(fake.loads, 1, "and nothing loads again")
  fake.restore()
end)

-- -- the client gate and the failure answers ----------------------------------------------------

test("foreverdb: on Retail Available answers false, client, and nothing loads", function()
  with({ preset = "present", client = "retail" }, function(fake)
    local got = pack(fdbLib.Available())
    assertEqual(got.n, 2, "arity")
    assertFalse(got[1]); assertEqual(got[2], "client")
    assertNoAnswers("retail")
    assertEqual(fake.loads, 0, "Retail never loads it")
  end)
end)

test("foreverdb: without Compat the client is taken as not Forever", function()
  local M, fake = freshEnv({ preset = "present", client = "forever" }, { "Core", "ForeverDB" })
  local lib = M.LibStub("LibKa0s-ForeverDB-1.0")
  local ok, reason = lib.Available()
  assertFalse(ok); assertEqual(reason, "client")
  assertEqual(fake.loads, 0)
  fake.restore()
end)

test("foreverdb: a missing addon answers false, missing, without a load attempt", function()
  with({ preset = "missing" }, function(fake)
    local ok, reason = fdbLib.Available()
    assertFalse(ok); assertEqual(reason, "missing")
    assertEqual(fake.loads, 0, "DoesAddOnExist said no, so LoadAddOn is never asked")
    assertNoAnswers("missing")
  end)
end)

test("foreverdb: a failed load answers the client's reason, once a session", function()
  with({ preset = "loadfails" }, function(fake)
    local ok, reason = fdbLib.Available()
    assertFalse(ok); assertEqual(reason, "DISABLED")
    assertEqual(fake.loads, 1)
    assertNoAnswers("loadfails")
    fdbLib.Available()
    assertEqual(fake.loads, 1, "the answer is kept; no second attempt")
  end)
  with({ preset = "loadfails", reason = "DEP_MISSING" }, function()
    assertEqual(select(2, fdbLib.Available()), "DEP_MISSING")
  end)
end)

test("foreverdb: a global that is not a table answers false, reshaped", function()
  with({ preset = "reshaped" }, function(fake)
    local ok, reason = fdbLib.Available()
    assertFalse(ok); assertEqual(reason, "reshaped")
    assertEqual(fake.loads, 1)
    assertNoAnswers("reshaped")
  end)
end)

test("foreverdb: no C_AddOns at all answers missing", function()
  with({ preset = "present" }, function()
    local saved = mocks.C_AddOns
    mocks.C_AddOns = nil
    local ok, reason = fdbLib.Available()
    mocks.C_AddOns = saved
    assertFalse(ok); assertEqual(reason, "missing")
  end)
end)

test("foreverdb: without DoesAddOnExist, GetAddOnInfo's MISSING reason decides", function()
  with({ preset = "missing" }, function()
    mocks.C_AddOns.DoesAddOnExist = nil
    assertEqual(select(2, fdbLib.Available()), "missing")
  end)
  with({ preset = "present" }, function()
    mocks.C_AddOns.DoesAddOnExist = nil
    assertTrue(fdbLib.Available(), "known through GetAddOnInfo")
  end)
end)

test("foreverdb: already loaded by another addon, nothing loads it again", function()
  with({ preset = "present", loaded = true }, function(fake)
    assertTrue(fdbLib.IsLoaded())
    local ok, reason = fdbLib.Available()
    assertTrue(ok); assertNil(reason)
    assertEqual(fake.loads, 0, "IsAddOnLoaded said yes")
    assertEqual(fdbLib.NPC(I.vendor).name, "Fixture Vendor")
  end)
end)

test("foreverdb: the answer is kept for the session, and __reset asks again", function()
  with({ preset = "present" }, function(fake)
    assertTrue(fdbLib.Available())
    assertTrue(fdbLib.Available())
    assertEqual(fake.loads, 1)
    fdbLib.__reset()
    assertTrue(fdbLib.Available(), "asked again")
    assertEqual(fake.loads, 1, "already loaded, so the second ask loads nothing")
  end)
end)

-- -- the field mapping --------------------------------------------------------------------------

test("foreverdb: NPC maps the row's positions and the faction", function()
  with({}, function()
    local n = fdbLib.NPC(I.gnoll)
    assertEqual(n.id, I.gnoll); assertEqual(n.name, "Fixture Gnoll")
    assertEqual(n.subname, "Invented Pack"); assertEqual(n.minLevel, 10)
    assertEqual(n.maxLevel, 12); assertEqual(n.rank, 1); assertEqual(n.faction, "H")
    local k = fdbLib.NPC(I.kobold)
    assertNil(k.subname, "a nil position"); assertNil(k.faction, "no nfac row")
    assertEqual(fdbLib.NPC(I.vendor).faction, "AH")
    assertNil(fdbLib.NPC(990999), "an unknown id")
    assertNil(fdbLib.NPC("990001"), "a string id is no answer")
    assertNil(fdbLib.NPC(nil)); assertNil(fdbLib.NPC(-1))
  end)
end)

test("foreverdb: Item maps the row's first eight positions", function()
  with({}, function()
    local it = fdbLib.Item(I.blade)
    assertEqual(it.id, I.blade); assertEqual(it.name, "Fixture Blade"); assertEqual(it.quality, 2)
    assertEqual(it.requiredLevel, 10); assertEqual(it.itemLevel, 15); assertEqual(it.classID, 2)
    assertEqual(it.subclassID, 7); assertEqual(it.inventoryType, 13); assertEqual(it.icon, 9990001)
    assertNil(fdbLib.Item(I.pebble).itemLevel, "a nil position reads nil")
    assertNil(fdbLib.Item(990999))
  end)
end)

test("foreverdb: Object answers the row's name, and no answer without one (minor 3)", function()
  with({}, function()
    local o = fdbLib.Object(I.crate)
    assertEqual(o.id, I.crate); assertEqual(o.name, "Fixture Crate")
    local keys = {}
    for k in pairs(o) do keys[#keys + 1] = k end
    table.sort(keys)
    assertEqual(table.concat(keys, ","), "id,name", "the name is the one fact read")
    assertEqual(fdbLib.Object(I.boxA).name, "Fixture Strongbox")
    assertEqual(fdbLib.Object(I.boxB).name, "Fixture Strongbox", "two objects may share a name")
    assertNil(fdbLib.Object(I.husk), "a row with no name is no answer")
    assertNil(fdbLib.Object(I.scrap), "a row that is not a table is no answer")
    assertNil(fdbLib.Object(990999), "an unknown id")
    assertNil(fdbLib.Object(tostring(I.crate)), "a string id is no answer")
    assertNil(fdbLib.Object(nil)); assertNil(fdbLib.Object(-1)); assertNil(fdbLib.Object(0 / 0))
  end)
end)

test("foreverdb: Object reads a non-string or empty name as no answer, and a missing obj table", function()
  local D = FDB.fixture()
  D.obj[I.boxA] = { 42 }
  D.obj[I.boxB] = { "" }
  with({ data = D }, function()
    assertNil(fdbLib.Object(I.boxA), "a number for a name")
    assertNil(fdbLib.Object(I.boxB), "an empty name")
    assertEqual(fdbLib.Object(I.crate).name, "Fixture Crate", "the other rows still answer")
  end)
  D = FDB.fixture()
  D.obj = "not a table"
  with({ data = D }, function()
    assertNil(fdbLib.Object(I.crate), "an obj that is not a table")
  end)
  D = FDB.fixture()
  D.obj = nil
  with({ data = D }, function()
    assertNil(fdbLib.Object(I.crate), "no obj table at all")
  end)
end)

test("foreverdb: Quest maps the row and resolves givers and enders by kind", function()
  with({}, function()
    local q = fdbLib.Quest(I.errand)
    assertEqual(q.id, I.errand); assertEqual(q.title, "Fixture Errand")
    assertEqual(q.level, 12); assertEqual(q.minLevel, 8)
    assertEqual(#q.givers, 2)
    assertEqual(q.givers[1].kind, "npc"); assertEqual(q.givers[1].id, I.gnoll)
    assertEqual(q.givers[2].kind, "object"); assertEqual(q.givers[2].id, I.crate)
    assertEqual(#q.enders, 1)
    assertEqual(q.enders[1].kind, "npc"); assertEqual(q.enders[1].id, I.vendor)
    assertNil(fdbLib.Quest(990999))
  end)
end)

test("foreverdb: ItemSources scales chances to 0..1, unknown rates nil and last", function()
  with({}, function()
    local s = fdbLib.ItemSources(I.blade)
    assertEqual(#s.creatures, 2)
    assertEqual(s.creatures[1].id, I.gnoll); assertEqual(s.creatures[1].chance, 0.25)
    assertEqual(s.creatures[2].id, I.kobold); assertNil(s.creatures[2].chance, "0 = rate unknown")
    assertEqual(#s.objects, 1); assertEqual(s.objects[1].id, I.crate); assertEqual(s.objects[1].chance, 1)
    assertEqual(#s.items, 1); assertEqual(s.items[1].id, I.coffer); assertEqual(s.items[1].chance, 0.05)
    assertEqual(table.concat(s.vendors, ","), I.vendor .. "," .. I.trainer)
    assertEqual(s.worldMinLevel, 8)
    assertNil(fdbLib.ItemSources(I.pebble), "nothing at all is nil")
  end)
end)

test("foreverdb: ItemSources sorts the most likely source first", function()
  local D = FDB.fixture()
  D.drop[I.blade] = { I.kobold, 0, I.vendor, 100, I.gnoll, 9000, I.trainer, 100 }
  with({ data = D }, function()
    local ids = {}
    for _, c in ipairs(fdbLib.ItemSources(I.blade).creatures) do ids[#ids + 1] = c.id end
    assertEqual(table.concat(ids, ","),
      table.concat({ I.gnoll, I.vendor, I.trainer, I.kobold }, ","), "chance, then id, unknown last")
  end)
end)

test("foreverdb: VendorPrice answers the lowest price seen and its vendor", function()
  with({}, function()
    local got = pack(fdbLib.VendorPrice(I.blade))
    assertEqual(got.n, 2)
    assertEqual(got[1], 1200); assertEqual(got[2], I.trainer)
    local none = pack(fdbLib.VendorPrice(I.pebble))
    assertNil(none[1]); assertNil(none[2])
  end)
end)

test("foreverdb: Spots scales coordinates to 0..1 per map", function()
  with({}, function()
    local s = fdbLib.Spots("npc", I.gnoll)
    local pts = s[I.mapA]
    assertEqual(#pts, 2)
    assertEqual(pts[1].x, 0.5); assertEqual(pts[1].y, 0.25)
    assertEqual(pts[2].x, 0.123); assertEqual(pts[2].y, 0.877)
    local o = fdbLib.Spots("object", I.crate)[I.mapB]
    assertEqual(o[1].x, 1); assertEqual(o[1].y, 0)
    assertNil(fdbLib.Spots("creature", I.gnoll), "only npc and object")
    assertNil(fdbLib.Spots("npc", I.kobold), "no spot")
  end)
end)

test("foreverdb: TrainerSpells answers cost and level by spell name", function()
  with({}, function()
    local t = fdbLib.TrainerSpells(I.trainer)
    assertEqual(t["Fixture Strike"].cost, 100); assertEqual(t["Fixture Strike"].level, 10)
    assertEqual(t["Fixture Ward"].cost, 1000); assertEqual(t["Fixture Ward"].level, 20)
    assertNil(fdbLib.TrainerSpells(I.gnoll))
  end)
end)

test("foreverdb: Meta answers the TOC version, build, hash and a copy of the counts", function()
  with({ version = "2099.02.03.4" }, function(fake)
    local m = fdbLib.Meta()
    assertEqual(m.version, "2099.02.03.4"); assertEqual(m.build, "2099-01-01")
    assertEqual(m.hash, "0123456789abcdef"); assertEqual(m.counts.npc, 5)
    assertTrue(m.counts ~= fake.data.meta.counts, "a copy")
  end)
end)

-- -- fresh tables and a reshaped database -------------------------------------------------------

test("foreverdb: every answer is a fresh table, never ForeverDB's own row", function()
  with({}, function(fake)
    local n = fdbLib.NPC(I.gnoll)
    assertTrue(n ~= fake.data.npc[I.gnoll])
    n.name = "Edited"
    assertEqual(fdbLib.NPC(I.gnoll).name, "Fixture Gnoll", "an edit reaches nothing")
    assertEqual(fake.data.npc[I.gnoll][1], "Fixture Gnoll", "and the database is untouched")
    local s = fdbLib.ItemSources(I.blade)
    s.creatures[1] = nil; s.vendors[1] = nil
    assertEqual(fdbLib.ItemSources(I.blade).creatures[1].id, I.gnoll)
    assertEqual(fake.data.vend[I.blade][1], I.vendor)
    local q = fdbLib.Quest(I.errand); q.givers[1] = nil
    assertEqual(fdbLib.Quest(I.errand).givers[1].id, I.gnoll)
    local sp = fdbLib.Spots("npc", I.gnoll); sp[I.mapA][1].x = 9
    assertEqual(fdbLib.Spots("npc", I.gnoll)[I.mapA][1].x, 0.5)
    assertEqual(fake.data.spm["c" .. I.gnoll][I.mapA][1], 500)
    local t = fdbLib.TrainerSpells(I.trainer)
    assertTrue(t["Fixture Strike"] ~= fake.data.trn[I.trainer]["Fixture Strike"])
    local o = fdbLib.Object(I.crate)
    assertTrue(o ~= fake.data.obj[I.crate]); o.name = "Edited"
    assertEqual(fdbLib.Object(I.crate).name, "Fixture Crate", "an edit reaches nothing")
    assertEqual(fake.data.obj[I.crate][1], "Fixture Crate")
  end)
end)

test("foreverdb: a reshaped row or field reads nil and never raises", function()
  local D = FDB.fixture()
  D.npc[I.gnoll] = "not a row"
  D.npc[I.kobold] = { 42, {}, "ten", nil, true }
  D.nfac[I.kobold] = "X"
  D.item = 7
  D.qg[I.errand] = { "c", "z123", 5, "c" .. I.gnoll, "oabc" }
  D.drop[I.blade] = { I.gnoll, "high", "x", 100, I.kobold }
  D.vp[I.trainer][I.blade] = "free"
  D.vendx[I.vendor] = { [I.blade] = { p = "dear" } }   -- minor 4: a reshaped vendx price falls to vp
  D.spm["c" .. I.gnoll] = { [I.mapA] = { 500, "y", 100 }, bad = { 1, 2 } }
  D.spw["c" .. I.gnoll] = nil   -- minor 4 would answer the gnoll's world point instead
  D.trn[I.trainer] = { [1] = { 5, 5 }, ["Fixture Strike"] = "x" }
  with({ data = D }, function()
    assertNil(fdbLib.NPC(I.gnoll), "a row that is not a table")
    local k = fdbLib.NPC(I.kobold)
    assertNil(k.name); assertNil(k.subname); assertNil(k.minLevel); assertNil(k.rank)
    assertNil(k.faction, "an unknown faction token")
    assertNil(fdbLib.Item(I.blade), "a table that is not a table")
    local g = fdbLib.Quest(I.errand).givers
    assertEqual(#g, 1, "only the well-formed giver"); assertEqual(g[1].id, I.gnoll)
    local s = fdbLib.ItemSources(I.blade)
    assertEqual(#s.creatures, 1, "the pair with a bad id is skipped")
    assertEqual(s.creatures[1].id, I.gnoll); assertNil(s.creatures[1].chance, "a chance that is no number")
    local price, npc = fdbLib.VendorPrice(I.blade)
    assertEqual(price, 1500); assertEqual(npc, I.vendor, "the reshaped price is skipped")
    assertNil(fdbLib.Spots("npc", I.gnoll), "no well-formed point")
    assertNil(fdbLib.TrainerSpells(I.trainer), "no well-formed spell")
  end)
end)

test("foreverdb: an out-of-range chance or coordinate reads as no value", function()
  local D = FDB.fixture()
  D.drop[I.blade] = { I.gnoll, 15000, I.kobold, -3, I.vendor, 10000 }
  D.spm["c" .. I.gnoll] = { [I.mapA] = { 1200, 500, -5, 100, 250, 750 }, [I.mapB] = { 1001, 0 } }
  with({ data = D }, function()
    local s = fdbLib.ItemSources(I.blade)
    assertEqual(#s.creatures, 3)
    assertEqual(s.creatures[1].id, I.vendor); assertEqual(s.creatures[1].chance, 1, "10000 is the top")
    assertNil(s.creatures[2].chance, "15000 is out of range")
    assertNil(s.creatures[3].chance, "a negative chance is out of range")
    local sp = fdbLib.Spots("npc", I.gnoll)
    assertEqual(#sp[I.mapA], 1, "only the in-range pair")
    assertEqual(sp[I.mapA][1].x, 0.25); assertEqual(sp[I.mapA][1].y, 0.75)
    assertNil(sp[I.mapB], "a map with no in-range pair")
  end)
end)

test("foreverdb: a database with no meta answers Meta with the version alone", function()
  local D = FDB.fixture()
  D.meta = nil
  with({ data = D }, function()
    local m = fdbLib.Meta()
    assertEqual(m.version, FDB.VERSION); assertNil(m.build); assertNil(m.hash); assertNil(m.counts)
  end)
end)

-- -- Status and the diagnostics line ------------------------------------------------------------

test("foreverdb: Status reports present, loaded and the version, and build and hash once loaded", function()
  with({}, function(fake)
    local st = fdbLib.Status()
    assertTrue(st.present); assertFalse(st.loaded); assertEqual(st.version, FDB.VERSION)
    assertNil(st.build); assertNil(st.hash)
    assertEqual(fake.loads, 0, "Status never loads")
    fdbLib.Available()
    st = fdbLib.Status()
    assertTrue(st.loaded); assertEqual(st.build, "2099-01-01"); assertEqual(st.hash, "0123456789abcdef")
  end)
  with({ preset = "missing", client = "retail" }, function()
    local st = fdbLib.Status()
    assertFalse(st.present); assertFalse(st.loaded); assertNil(st.version)
  end)
end)

local function reportLines()
  local D = debuglog:New{
    name = "FdbDiag", title = "Fdb Diag", font = "Interface\\Fonts\\FRIZQT__.TTF",
    isEnabled = function() return true end, setEnabled = function() end, print = function() end,
  }
  local out = {}
  for _, line in ipairs(D:BuildDiagnostics().lines) do out[#out + 1] = line[2] end
  return out
end

local function lineWith(lines, needle)
  for _, s in ipairs(lines) do
    if s:find(needle, 1, true) then return s end
  end
  return nil
end

test("foreverdb: the diagnostics report prints the ForeverDB line and never loads it", function()
  with({}, function(fake)
    local line = lineWith(reportLines(), "ForeverDB: ")
    assertEqual(line, "ForeverDB: present=yes loaded=no version=" .. FDB.VERSION, "not loaded")
    assertEqual(fake.loads, 0, "the report loads nothing")
    assertTrue(lineWith(reportLines(), "ForeverDB 4") ~= nil, "the major among the running minors")
  end)
  with({ loaded = true }, function(fake)
    local line = lineWith(reportLines(), "ForeverDB: ")
    assertEqual(line, "ForeverDB: present=yes loaded=yes version=" .. FDB.VERSION
      .. " build=2099-01-01 hash=0123456789abcdef", "loaded")
    assertEqual(fake.loads, 0)
  end)
  with({ preset = "missing", client = "retail" }, function()
    assertEqual(lineWith(reportLines(), "ForeverDB: "), "ForeverDB: present=no loaded=no", "absent")
  end)
end)

test("foreverdb: a client read that raises costs the report only the ForeverDB line", function()
  with({ preset = "missing", client = "retail" }, function()
    local saved = mocks.C_AddOns.IsAddOnLoaded
    mocks.C_AddOns.IsAddOnLoaded = function() error("boom") end
    local ok, lines = pcall(reportLines)
    mocks.C_AddOns.IsAddOnLoaded = saved
    assertTrue(ok, "the report still builds")
    assertEqual(lineWith(lines, "ForeverDB: "), "ForeverDB: unreadable")
  end)
end)

test("foreverdb: Status reads no Version for an addon the client does not know", function()
  with({ preset = "missing", client = "retail" }, function()
    local saved, asked = mocks.C_AddOns.GetAddOnMetadata, false
    mocks.C_AddOns.GetAddOnMetadata = function(...) asked = true; return saved(...) end
    local s = fdbLib.Status()
    mocks.C_AddOns.GetAddOnMetadata = saved
    assertFalse(s.present); assertNil(s.version); assertFalse(asked, "no metadata read")
  end)
end)
