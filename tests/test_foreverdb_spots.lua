-- tests/test_foreverdb_spots.lua -- LibKa0s-ForeverDB-1.0 minor 4: Spots from ForeverDB_Full's
-- `spz`, the base `spm` and the base `spw` world coordinates (WorldToMap over `umaa` and `zbord`),
-- VendorPriceAt and `vendx` in VendorPrice, and ForeverDB_Full on a host's demand (FullStatus,
-- LoadFull, FullCost). ISR3-LK-01 of Ka0sAddonsCommonTasks docs/2026-11-25-ITEM_SEARCH_ROUND3/.
--
-- Every case installs the kit's fake (tests/_kit/mock_foreverdb.lua, kit revision 65: its invented
-- continent, zones, world coordinates, vendx row and ForeverDB_Full fake) with the client it means,
-- so a case reads the same under both kit profiles, and puts everything back after. The data is
-- INVENTED in ForeverDB's shape: ForeverDB is GPL-3.0 and this repo is MIT, so no real row appears
-- here. The expected map positions are worked by hand from the fixture's numbers (each one is in
-- the case's comment), on values a double holds exactly or rounds the same way both sides.

local T = _G.LK_TEST
local fdbLib, mocks = T.foreverdb, T.mocks
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local FDB = dofile("tests/_kit/mock_foreverdb.lua")
local I   = FDB.IDS

--- Run `fn(fake)` with the fake installed (client "forever" unless given), then restore and reset.
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

--- A map's points as "x,y;x,y", in order.
local function pts(list)
  local out = {}
  for _, p in ipairs(list or {}) do out[#out + 1] = p.x .. "," .. p.y end
  return table.concat(out, ";")
end

--- The answer's map ids, ascending, as "a,b".
local function maps(spots)
  local out = {}
  for mapID in pairs(spots or {}) do out[#out + 1] = mapID end
  table.sort(out)
  return table.concat(out, ",")
end

--- `{ map, x, y }` from WorldToMap, as one string.
local function where(c, x, y)
  local got = pack(fdbLib.WorldToMap(c, x, y))
  if got[1] == nil then return "nil" end
  return got[1] .. "@" .. got[2] .. "," .. got[3]
end

-- -- WorldToMap ---------------------------------------------------------------------------------

test("foreverdb spots: WorldToMap converts by the region's max edges, per zone", function()
  with({}, function()
    -- north: u = (500 - -250) / 1000 = 0.75, v = (1000 - 600) / 1000 = 0.4
    assertEqual(where(I.continent, 600, -250), I.mapNorth .. "@0.75,0.4", "north zone alone")
    -- south: u = (500 - 250) / 1000 = 0.25, v = (200 - -300) / 800 = 0.625
    assertEqual(where(I.continent, -300, 250), I.mapSouth .. "@0.25,0.625", "south zone alone")
    -- continent: u = (1000 - 900) / 2000 = 0.05, v = (1000 - -900) / 2000 = 0.95
    assertEqual(where(I.continent, -900, 900), I.mapCont .. "@0.05,0.95", "the continent map alone")
    local got = pack(fdbLib.WorldToMap(I.continent, 600, -250))
    assertEqual(got.n, 3, "uiMapID, x, y")
  end)
end)

test("foreverdb spots: in the overlap, the zone whose polygon holds the point wins over the smaller one", function()
  with({}, function()
    -- the south zone is smaller (800 x 1000) and holds (150, 0) by rectangle, but there the point
    -- is at map y 62.5, outside its polygon (y 250..1000); the north's polygon holds y 850
    assertEqual(where(I.continent, 150, 0), I.mapNorth .. "@0.5,0.85")
    -- neither polygon holds (50, 0) (south y 187.5, north y 950): the continent map, which has no
    -- zbord entry, takes it: u = 0.5, v = 950 / 2000 = 0.475
    assertEqual(where(I.continent, 50, 0), I.mapCont .. "@0.5,0.475")
  end)
end)

test("foreverdb spots: WorldToMap answers nil off every region, on an unknown continent and for bad input", function()
  with({}, function()
    assertEqual(where(I.continent, 5000, 0), "nil", "off every region")
    assertEqual(where(7, 10, 10), "nil", "a continent no umaa row names")
    assertEqual(where("99", 600, -250), "nil", "a continent that is not a number")
    assertEqual(where(I.continent, "600", -250), "nil", "a coordinate that is not a number")
    assertEqual(where(I.continent, 0 / 0, -250), "nil", "NaN")
    assertEqual(where(1.5, 600, -250), "nil", "a continent that is not whole")
    assertEqual(where(nil, nil, nil), "nil")
  end)
  with({ client = "retail" }, function()
    assertEqual(where(I.continent, 600, -250), "nil", "off Forever")
  end)
  with({ preset = "missing" }, function()
    assertEqual(where(I.continent, 600, -250), "nil", "without ForeverDB")
  end)
end)

test("foreverdb spots: without zbord the smallest containing rectangle answers; without umaa nothing does", function()
  local D = FDB.fixture()
  D.zbord = nil
  with({ data = D }, function()
    -- the south rectangle is the smallest that holds (150, 0): v = (200 - 150) / 800 = 0.0625
    assertEqual(where(I.continent, 150, 0), I.mapSouth .. "@0.5,0.0625", "rectangles alone")
  end)
  D = FDB.fixture()
  D.umaa = nil
  with({ data = D }, function()
    assertEqual(where(I.continent, 600, -250), "nil", "no umaa")
    assertNil(fdbLib.Spots("npc", I.wanderer), "and no spw answer")
  end)
end)

test("foreverdb spots: a malformed umaa row is skipped and the rest still answer", function()
  local D = FDB.fixture()
  D.umaa[990404] = "not a row"
  D.umaa[990405] = { "9906", I.continent, 0, 0, 0, 1, 1, -5000, -5000, 0, 5000, 5000, 0 }
  D.umaa[990406] = { 9906, I.continent, 0, 0, 0, 1, 1, 100, -5000, 0, 100, 5000, 0 }   -- no width
  D.umaa[990407] = { 9906, I.continent, 0, 1, 0, 1, 1, -5000, -5000, 0, 5000, 5000, 0 }   -- no ui width
  D.umaa[990408] = { 9906, I.continent, 0, 0, 0, 1, 1, -5000, nil, 0, 5000, 5000, 0 }
  D.umaa[990409] = { 9906, -1, 0, 0, 0, 1, 1, -5000, -5000, 0, 5000, 5000, 0 }   -- no continent
  D.umaa[990402][2] = "99"   -- the north zone's continent is a string: the row is gone
  with({ data = D }, function()
    assertEqual(where(I.continent, 5000, 0), "nil", "no malformed row answers off the map")
    assertEqual(where(I.continent, -300, 250), I.mapSouth .. "@0.25,0.625", "the south still answers")
    -- with the north row gone, (600, -250) is the continent's: u = 0.625, v = 0.2
    assertEqual(where(I.continent, 600, -250), I.mapCont .. "@0.625,0.2", "the continent takes the north's point")
  end)
end)

test("foreverdb spots: a malformed zbord entry or polygon leaves its zone a rectangle", function()
  local D = FDB.fixture()
  D.zbord[I.areaNorth] = { c = I.continent, m = { { 0, 0, 1000, "x", 1000, 900 }, { 0, 0, 1 } } }
  D.zbord[I.areaSouth] = { c = 7, m = { { 0, 250, 1000, 250, 1000, 1000, 0, 1000 } } }
  with({ data = D }, function()
    -- both zones are rectangles now: the smaller south takes the overlap
    assertEqual(where(I.continent, 150, 0), I.mapSouth .. "@0.5,0.0625", "a zbord on another continent is not read")
    -- a rectangle zone (the north's) holds (600, -250) and is smaller than the continent
    assertEqual(where(I.continent, 600, -250), I.mapNorth .. "@0.75,0.4", "a polygon with a non-number is skipped")
  end)
  D = FDB.fixture()
  D.zbord[I.areaNorth] = "not a table"
  D.zbord[I.areaSouth] = { c = I.continent, m = "not a list" }
  with({ data = D }, function()
    assertEqual(where(I.continent, 150, 0), I.mapSouth .. "@0.5,0.0625")
  end)
end)

-- -- Spots: the three origins -------------------------------------------------------------------

test("foreverdb spots: Spots answers spw world points grouped by the map each lands on", function()
  with({}, function()
    local got = pack(fdbLib.Spots("npc", I.wanderer))
    assertEqual(got.n, 2, "spots, origin")
    assertEqual(got[2], "spw")
    local s = got[1]
    assertEqual(maps(s), table.concat({ I.mapCont, I.mapNorth, I.mapSouth }, ","), "the point off every map, and the run on no umaa continent, skipped")
    assertEqual(pts(s[I.mapNorth]), "0.75,0.4;0.5,0.85", "in run order")
    assertEqual(pts(s[I.mapSouth]), "0.25,0.625")
    assertEqual(pts(s[I.mapCont]), "0.5,0.475")
  end)
end)

test("foreverdb spots: spm wins over spw, and its origin says so", function()
  with({}, function(fake)
    local s, origin = fdbLib.Spots("npc", I.gnoll)
    assertEqual(origin, "spm")
    assertEqual(maps(s), tostring(I.mapA), "the gnoll's spw point is not read")
    assertEqual(pts(s[I.mapA]), "0.5,0.25;0.123,0.877")
    fake.data.spm["c" .. I.gnoll] = nil
    s, origin = fdbLib.Spots("npc", I.gnoll)
    assertEqual(origin, "spw", "with no spm row the world point answers")
    assertEqual(pts(s[I.mapCont]), "0.05,0.95")
  end)
end)

test("foreverdb spots: with ForeverDB_Full loaded, spz wins over spm and fills sources spm lacks", function()
  with({ full = "present" }, function()
    local _, before = fdbLib.Spots("npc", I.gnoll)
    assertEqual(before, "spm", "Full is not read before it loads")
    assertNil(fdbLib.Spots("npc", I.vendor), "the vendor has no spm or spw row")
    assertTrue(fdbLib.LoadFull())
    local s, origin = fdbLib.Spots("npc", I.gnoll)
    assertEqual(origin, "spz")
    assertEqual(maps(s), tostring(I.mapB), "spz's row, not spm's")
    assertEqual(pts(s[I.mapB]), "0.6,0.7")
    local v, vo = fdbLib.Spots("npc", I.vendor)
    assertEqual(vo, "spz"); assertEqual(pts(v[I.mapA]), "0.25,0.5;0.26,0.51")
    local _, wo = fdbLib.Spots("npc", I.wanderer)
    assertEqual(wo, "spw", "a source with no spz row still falls through")
  end)
end)

test("foreverdb spots: a malformed spz row falls through to spm; spz is never read off Forever", function()
  local full = FDB.fullFixture()
  full.spz["c" .. I.gnoll] = { [I.mapB] = { 1200, 5 }, bad = { 1, 2 } }
  with({ full = "present", fullData = full }, function()
    fdbLib.LoadFull()
    local _, origin = fdbLib.Spots("npc", I.gnoll)
    assertEqual(origin, "spm", "no usable spz point")
  end)
  with({ client = "retail", full = "present", fullLoaded = true }, function()
    assertNil(fdbLib.Spots("npc", I.gnoll), "Retail answers nil whatever is loaded")
  end)
end)

test("foreverdb spots: malformed spw entries and runs are skipped, and nothing usable is nil", function()
  local D = FDB.fixture()
  D.spw["c" .. I.wanderer] = { "not a run", { "99", 600, -250 }, { I.continent, "x", -250, 600 }, 5 }
  D.spw["c" .. I.kobold] = "not a list"
  with({ data = D }, function()
    assertNil(fdbLib.Spots("npc", I.wanderer), "no point converts")
    assertNil(fdbLib.Spots("npc", I.kobold), "an entry that is not a table")
  end)
  D = FDB.fixture()
  D.spw["c" .. I.wanderer][1] = { I.continent, "x", -250, -300, 250 }
  with({ data = D }, function()
    local s = fdbLib.Spots("npc", I.wanderer)
    assertEqual(maps(s), tostring(I.mapSouth), "a bad pair is skipped, the next pair kept")
  end)
  D = FDB.fixture()
  D.spw = "not a table"
  with({ data = D }, function()
    assertNil(fdbLib.Spots("npc", I.wanderer))
  end)
end)

test("foreverdb spots: the spw memo hands out fresh tables and follows a swapped spw table", function()
  with({}, function(fake)
    local a = fdbLib.Spots("npc", I.wanderer)
    local b = fdbLib.Spots("npc", I.wanderer)
    assertTrue(a ~= b, "a new table each call")
    assertTrue(a[I.mapNorth] ~= b[I.mapNorth] and a[I.mapNorth][1] ~= b[I.mapNorth][1], "all the way down")
    a[I.mapNorth][1].x = 9; a[I.mapSouth] = nil
    local c = fdbLib.Spots("npc", I.wanderer)
    assertEqual(pts(c[I.mapNorth]), "0.75,0.4;0.5,0.85", "an edit reaches nothing")
    assertTrue(c[I.mapSouth] ~= nil)
    assertEqual(fake.data.spw["c" .. I.wanderer][1][2], 600, "and the database is untouched")
    fake.data.spw = { ["c" .. I.wanderer] = { { I.continent, -300, 250 } } }
    assertEqual(maps(fdbLib.Spots("npc", I.wanderer)), tostring(I.mapSouth), "a new spw table is converted afresh")
  end)
end)

-- -- vendor prices -------------------------------------------------------------------------------

test("foreverdb spots: VendorPriceAt reads vendx, then vp, with the origin", function()
  with({}, function()
    local got = pack(fdbLib.VendorPriceAt(I.vendor, I.blade))
    assertEqual(got.n, 2)
    assertEqual(got[1], 1400); assertEqual(got[2], "vendx", "vendx wins over the vendor's vp row")
    got = pack(fdbLib.VendorPriceAt(I.trainer, I.blade))
    assertEqual(got[1], 1200); assertEqual(got[2], "vp")
    got = pack(fdbLib.VendorPriceAt(I.gnoll, I.blade))
    assertEqual(got.n, 2); assertNil(got[1]); assertNil(got[2])
    assertNil((fdbLib.VendorPriceAt(I.vendor, I.pebble)))
    assertNil((fdbLib.VendorPriceAt("990003", I.blade)), "a string id")
    assertNil((fdbLib.VendorPriceAt(I.vendor, nil)))
  end)
  local D = FDB.fixture()
  D.vendx[I.vendor][I.blade] = { p = -1 }
  D.vp[I.trainer][I.blade] = { "free" }
  with({ data = D }, function()
    local p, o = fdbLib.VendorPriceAt(I.vendor, I.blade)
    assertEqual(p, 1500); assertEqual(o, "vp", "a negative vendx price falls to vp")
    assertNil((fdbLib.VendorPriceAt(I.trainer, I.blade)), "a vp price that is no number")
  end)
  with({ client = "retail" }, function()
    assertNil((fdbLib.VendorPriceAt(I.vendor, I.blade)), "off Forever")
  end)
end)

test("foreverdb spots: VendorPrice takes the lowest across vendx and vp, the first vendor on a tie", function()
  local D = FDB.fixture()
  D.vendx[I.vendor][I.blade] = { p = 900, s = 1 }
  with({ data = D }, function()
    local p, npc = fdbLib.VendorPrice(I.blade)
    assertEqual(p, 900); assertEqual(npc, I.vendor, "the vendx price is now the lowest")
  end)
  D = FDB.fixture()
  D.vendx[I.vendor][I.blade] = { p = 1200 }
  with({ data = D }, function()
    local p, npc = fdbLib.VendorPrice(I.blade)
    assertEqual(p, 1200); assertEqual(npc, I.vendor, "a tie: vend's first vendor")
  end)
  D = FDB.fixture()
  D.vp = nil
  with({ data = D }, function()
    local p, npc = fdbLib.VendorPrice(I.blade)
    assertEqual(p, 1400); assertEqual(npc, I.vendor, "vendx alone still answers")
  end)
  with({}, function()
    local p, npc = fdbLib.VendorPrice(I.blade)
    assertEqual(p, 1200); assertEqual(npc, I.trainer, "the fixture's own answer is minor 3's")
  end)
end)

-- -- ForeverDB_Full --------------------------------------------------------------------------------

test("foreverdb spots: FullStatus reads the client's state and never loads anything", function()
  with({}, function(fake)
    assertEqual(fdbLib.FullStatus(), "missing", "no Full fake: the client does not know it")
    assertEqual(fake.loads, 0, "not even the base")
  end)
  with({ full = "present" }, function(fake)
    assertEqual(fdbLib.FullStatus(), "available")
    assertEqual(fake.loads, 0); assertEqual(fake.fullLoads, 0)
    assertNil(mocks.ForeverDBFull)
  end)
  with({ full = "missing" }, function() assertEqual(fdbLib.FullStatus(), "missing") end)
  with({ full = "disabled" }, function() assertEqual(fdbLib.FullStatus(), "disabled") end)
  with({ full = "present", fullLoaded = true }, function() assertEqual(fdbLib.FullStatus(), "loaded") end)
  with({ full = "present", client = "retail" }, function() assertEqual(fdbLib.FullStatus(), "client") end)
  with({ full = "present", preset = "missing" }, function() assertEqual(fdbLib.FullStatus(), "base") end)
  with({ full = "present", preset = "loadfails" }, function(fake)
    assertEqual(fdbLib.FullStatus(), "available", "the base has not been asked yet")
    fdbLib.Available()
    assertEqual(fdbLib.FullStatus(), "base", "after Available() said no")
    assertEqual(fake.fullLoads, 0)
  end)
end)

test("foreverdb spots: a dependency the client reports missing reads as base", function()
  with({ full = "present" }, function()
    local info = mocks.C_AddOns.GetAddOnInfo
    mocks.C_AddOns.GetAddOnInfo = function(name)
      if name == "ForeverDB_Full" then return name, "Full", nil, false, "DEP_DISABLED", "INSECURE" end
      return info(name)
    end
    assertEqual(fdbLib.FullStatus(), "base")
    local ok, reason = fdbLib.LoadFull()
    assertFalse(ok); assertEqual(reason, "base")
  end)
end)

--- Run `fn` with the mock's heap reading and clock under the case's control: `ctl.heap` (KB) is
--- what collectgarbage("count") answers, and `mocks.__profileMs` what debugprofilestop answers.
local function measured(fn)
  local savedGC, savedMs = mocks.collectgarbage, mocks.__profileMs
  local ctl = { heap = 5000 }
  mocks.collectgarbage = function(what)
    if what == "count" then return ctl.heap end
    return 0
  end
  mocks.__profileMs = 1000
  local ok, err = pcall(fn, ctl)
  mocks.collectgarbage, mocks.__profileMs = savedGC, savedMs
  if not ok then error(err, 0) end
end

test("foreverdb spots: LoadFull refuses in combat without caching, then loads once and measures it", function()
  measured(function(ctl)
    local opts = { full = "present", onFullLoad = function()
      ctl.heap = ctl.heap + 20070.5
      mocks.__profileMs = mocks.__profileMs + 840
    end }
    with(opts, function(fake)
      assertNil(fdbLib.FullCost(), "nothing before a load")
      local savedCombat = mocks.InCombatLockdown
      mocks.InCombatLockdown = function() return true end
      local got = pack(fdbLib.LoadFull())
      mocks.InCombatLockdown = savedCombat
      assertEqual(got.n, 2); assertFalse(got[1]); assertEqual(got[2], "combat")
      assertEqual(fake.fullLoads, 0, "nothing loads in combat"); assertEqual(fake.loads, 0, "not even the base")
      local ok, reason = fdbLib.LoadFull()
      assertTrue(ok, "the refusal was not kept"); assertNil(reason)
      assertEqual(fake.fullLoads, 1); assertEqual(fake.loads, 1, "the base loaded through Available()")
      assertTrue(mocks.ForeverDBFull == fake.fullData)
      assertEqual(fdbLib.FullStatus(), "loaded")
      assertTrue(fdbLib.LoadFull()); assertEqual(fake.fullLoads, 1, "once a session")
      local cost = fdbLib.FullCost()
      assertEqual(cost.kb, 20070.5); assertEqual(cost.ms, 840)
      cost.kb = 0
      assertEqual(fdbLib.FullCost().kb, 20070.5, "a fresh table each call")
    end)
  end)
end)

test("foreverdb spots: LoadFull without debugprofilestop keeps the KB alone", function()
  measured(function(ctl)
    local opts = { full = "present", onFullLoad = function() ctl.heap = ctl.heap + 10 end }
    with(opts, function()
      local saved = mocks.debugprofilestop
      mocks.debugprofilestop = false
      local ok = fdbLib.LoadFull()
      mocks.debugprofilestop = saved
      assertTrue(ok)
      local cost = fdbLib.FullCost()
      assertEqual(cost.kb, 10); assertNil(cost.ms)
    end)
  end)
end)

test("foreverdb spots: LoadFull's refusals and failures", function()
  with({ full = "present", client = "retail" }, function(fake)
    assertEqual(select(2, fdbLib.LoadFull()), "client"); assertEqual(fake.fullLoads, 0)
  end)
  with({ full = "present", preset = "missing" }, function(fake)
    assertEqual(select(2, fdbLib.LoadFull()), "base"); assertEqual(fake.fullLoads, 0)
  end)
  with({ full = "missing" }, function(fake)
    assertEqual(select(2, fdbLib.LoadFull()), "missing"); assertEqual(fake.fullLoads, 0)
  end)
  with({}, function(fake)
    assertEqual(select(2, fdbLib.LoadFull()), "missing", "no Full fake at all"); assertEqual(fake.fullLoads, 0)
  end)
  with({ full = "disabled" }, function(fake)
    assertEqual(select(2, fdbLib.LoadFull()), "disabled"); assertEqual(fake.fullLoads, 0)
  end)
  with({ full = "loadfails" }, function(fake)
    local ok, reason = fdbLib.LoadFull()
    assertFalse(ok); assertEqual(reason, "CORRUPT", "the client's reason")
    fdbLib.LoadFull()
    assertEqual(fake.fullLoads, 1, "a failed load is kept: no second attempt")
    assertNil(fdbLib.FullCost(), "a load that failed cost nothing to report")
  end)
  with({ full = "reshaped" }, function(fake)
    local ok, reason = fdbLib.LoadFull()
    assertFalse(ok); assertEqual(reason, "reshaped")
    assertEqual(fake.fullLoads, 1)
    assertTrue(fdbLib.FullCost() ~= nil, "it did load, so the cost is kept")
    assertEqual(select(2, fdbLib.LoadFull()), "reshaped"); assertEqual(fake.fullLoads, 1)
    assertEqual(select(2, fdbLib.Spots("npc", I.gnoll)), "spm", "a reshaped Full is not read")
  end)
end)

test("foreverdb spots: LoadFull with Full already loaded by another addon loads nothing", function()
  with({ full = "present", fullLoaded = true }, function(fake)
    local ok, reason = fdbLib.LoadFull()
    assertTrue(ok); assertNil(reason)
    assertEqual(fake.fullLoads, 0)
    assertNil(fdbLib.FullCost(), "this library did not load it")
    assertEqual(select(2, fdbLib.Spots("npc", I.gnoll)), "spz")
  end)
end)

test("foreverdb spots: Status carries the Full state and cost, and never loads", function()
  measured(function(ctl)
    local opts = { full = "present", onFullLoad = function()
      ctl.heap = ctl.heap + 2048; mocks.__profileMs = mocks.__profileMs + 12
    end }
    with(opts, function(fake)
      local st = fdbLib.Status()
      assertEqual(st.full, "available"); assertNil(st.fullCost)
      assertEqual(fake.loads, 0); assertEqual(fake.fullLoads, 0, "Status loads nothing")
      fdbLib.LoadFull()
      st = fdbLib.Status()
      assertEqual(st.full, "loaded"); assertEqual(st.fullCost.kb, 2048); assertEqual(st.fullCost.ms, 12)
    end)
  end)
  with({ client = "retail" }, function()
    assertEqual(fdbLib.Status().full, "client")
  end)
end)
