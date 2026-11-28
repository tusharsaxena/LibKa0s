-- tests/test_sim_sample.lua -- LibKa0s-Sim-1.0's sample characters (Sim minor 3, LibKa0s#87).
--
-- `Sim.SAMPLE.retail` and `Sim.SAMPLE.forever` are the collection's one set of named sample
-- characters, the protagonists a test mode, a sim or a showcase draws, and `Sim.Sample(client)`
-- answers a copy of the active client's set. The cases below hold the data to the naming
-- convention written into docs/api/Sim (and mirrored by WowAddonStandards preview-mode):
--
--   * every name is obviously fictional: one capitalized word of letters (a name the client could
--     hold, 2 to 12 letters) that starts "Sample" or "Mock", surnames and pets the same;
--   * realms come from the fixed fictional pair, and no real realm name appears anywhere;
--   * a Retail character is `Name-Realm` with a specID of its own class; a WoW Forever character
--     is "First Surname" with no realm in its identity, a class the client has, and a classic
--     talent tree 1-3 whose role is the one LibKa0s-Role-1.0 seeds for that tree;
--   * a pet only on a class that has one.
--
-- `Sim.SampleCrowd(client, n, seed)` (Sim minor 5, LibKa0s#104, FB2-LK-03) answers the crowd beyond
-- those five, held to the same convention, with rule 6 retired: every named sample person in every
-- addon comes from the library, so the crowd must be big enough for a 40-player raid roster, cover
-- every class the client has, balance its roles and replay for a seed.
--
-- Profile-independent: every case states its client through the kit's MockClient on a mock set of
-- its own, so `KA0S_KIT_CLIENT=forever` runs the same cases to the same answers.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local Loader = (_G.LK_TEST and _G.LK_TEST.loader) or dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")
local MockClient = dofile("tests/_kit/mock_client.lua")

local MAJOR = "LibKa0s-Sim-1.0"

--- A fresh mock set on `profile` with Core, (unless noCompat) Compat, Role and Sim loaded.
local function env(profile, opts)
  opts = opts or {}
  local m = buildMocks()
  Loader.load("LibKa0s/Core.lua", nil, m)
  if not opts.noCompat then Loader.load("LibKa0s/Compat.lua", nil, m) end
  Loader.load("LibKa0s/Role.lua", nil, m)
  Loader.load("LibKa0s/Sim.lua", nil, m)
  -- After the loads: the Loader stamps the run's own profile on a mock set at its first load.
  MockClient.apply(m, profile or "retail")
  return m, m.LibStub(MAJOR)
end

-- The fixed fictional realms, and the real realm names fixtures across the collection have used
-- (research note R6 of Ka0sAddonsCommonTasks docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS/), which the
-- shared data must never carry.
local REALMS = { Samplerealm = true, Mockrealm = true }
local REAL_REALMS = { "Frostmourne", "Silvermoon", "Ravencrest", "Draenor", "Sargeras", "Thrall",
  "Stormrage", "Area 52", "Illidan", "Tichondrius", "Kazzak", "Argent Dawn" }

-- Retail's specIDs by class file (the client's ChrSpecialization ids), roles beside them.
local RETAIL_SPECS = {
  WARRIOR = { [71] = "DAMAGER", [72] = "DAMAGER", [73] = "TANK" },
  PALADIN = { [65] = "HEALER", [66] = "TANK", [70] = "DAMAGER" },
  HUNTER = { [253] = "DAMAGER", [254] = "DAMAGER", [255] = "DAMAGER" },
  ROGUE = { [259] = "DAMAGER", [260] = "DAMAGER", [261] = "DAMAGER" },
  PRIEST = { [256] = "HEALER", [257] = "HEALER", [258] = "DAMAGER" },
  DEATHKNIGHT = { [250] = "TANK", [251] = "DAMAGER", [252] = "DAMAGER" },
  SHAMAN = { [262] = "DAMAGER", [263] = "DAMAGER", [264] = "HEALER" },
  MAGE = { [62] = "DAMAGER", [63] = "DAMAGER", [64] = "DAMAGER" },
  WARLOCK = { [265] = "DAMAGER", [266] = "DAMAGER", [267] = "DAMAGER" },
  MONK = { [268] = "TANK", [269] = "DAMAGER", [270] = "HEALER" },
  DRUID = { [102] = "DAMAGER", [103] = "DAMAGER", [104] = "TANK", [105] = "HEALER" },
  DEMONHUNTER = { [577] = "DAMAGER", [581] = "TANK" },
  EVOKER = { [1467] = "DAMAGER", [1468] = "HEALER", [1473] = "DAMAGER" },
}

-- The classes with a pet a sample may name.
local PET_CLASSES = { HUNTER = true, WARLOCK = true }

--- A name the convention admits: one capitalized word of 2-12 letters starting Sample or Mock.
local function fictional(s)
  if type(s) ~= "string" or #s < 2 or #s > 12 or not s:match("^[A-Z][a-z]+$") then return false end
  return s:sub(1, 6) == "Sample" or s:sub(1, 4) == "Mock"
end

local function noRealRealm(s, where)
  for _, real in ipairs(REAL_REALMS) do
    assertTrue(not tostring(s):find(real, 1, true), where .. " carries the real realm " .. real)
  end
end

local function eachCharacter(set, fn)
  for i, c in ipairs(set) do fn(c, ("#%d %s"):format(i, tostring(c.name))) end
end

local function sortedKeys(t)
  local out = {}
  for k in pairs(t) do out[#out + 1] = tostring(k) end
  table.sort(out)
  return table.concat(out, ",")
end

-- -- the data -----------------------------------------------------------------------------------

test("sim sample: SAMPLE holds a retail and a forever set of five characters, and nothing else", function()
  local _, Sim = env()
  assertEqual(type(Sim.SAMPLE), "table")
  assertEqual(sortedKeys(Sim.SAMPLE), "forever,retail")
  assertEqual(#Sim.SAMPLE.retail, 5, "retail")
  assertEqual(#Sim.SAMPLE.forever, 5, "forever")
end)

test("sim sample: every name, surname and pet is fictional by the convention", function()
  local _, Sim = env()
  for client, set in pairs(Sim.SAMPLE) do
    eachCharacter(set, function(c, where)
      where = client .. " " .. where
      assertTrue(fictional(c.name), where .. ": name " .. tostring(c.name))
      if c.surname ~= nil then assertTrue(fictional(c.surname), where .. ": surname " .. tostring(c.surname)) end
      if c.pet ~= nil then assertTrue(fictional(c.pet), where .. ": pet " .. tostring(c.pet)) end
      assertTrue(REALMS[c.realm] == true, where .. ": realm " .. tostring(c.realm) .. " is not a sample realm")
      for _, field in ipairs({ "name", "surname", "realm", "fullName", "pet", "spec" }) do
        if c[field] ~= nil then noRealRealm(c[field], where .. "." .. field) end
      end
    end)
  end
end)

test("sim sample: names and full names are unique within a set", function()
  local _, Sim = env()
  for client, set in pairs(Sim.SAMPLE) do
    local names, full = {}, {}
    eachCharacter(set, function(c, where)
      assertNil(names[c.name], client .. " " .. where .. ": name repeated")
      assertNil(full[c.fullName], client .. " " .. where .. ": fullName repeated")
      names[c.name], full[c.fullName] = true, true
    end)
  end
end)

test("sim sample: a retail character is Name-Realm, with a specID and role of its own class", function()
  local _, Sim = env()
  eachCharacter(Sim.SAMPLE.retail, function(c, where)
    assertNil(c.surname, where .. ": retail has no surname")
    assertNil(c.tree, where .. ": retail has no talent tree index")
    assertEqual(c.fullName, c.name .. "-" .. c.realm, where .. ": fullName")
    local specs = RETAIL_SPECS[c.classFile]
    assertTrue(specs ~= nil, where .. ": unknown class " .. tostring(c.classFile))
    assertTrue(specs[c.specID] ~= nil, where .. ": specID " .. tostring(c.specID) .. " is not a " .. c.classFile .. " spec")
    assertEqual(c.role, specs[c.specID], where .. ": role")
    assertEqual(type(c.spec), "string", where .. ": spec label")
  end)
end)

test("sim sample: a forever character is First Surname on a forever class and a classic talent tree", function()
  local m, Sim = env()
  local Role = m.LibStub("LibKa0s-Role-1.0")
  eachCharacter(Sim.SAMPLE.forever, function(c, where)
    assertEqual(type(c.surname), "string", where .. ": surname")
    assertEqual(c.fullName, c.name .. " " .. c.surname, where .. ": fullName has no realm")
    assertNil(c.specID, where .. ": a forever spec ID is class-wide and the client's alone")
    local trees = Role.TALENT_GROUP_ROLE[c.classFile]
    assertTrue(trees ~= nil, where .. ": " .. tostring(c.classFile) .. " is not a forever class")
    assertTrue(c.tree == 1 or c.tree == 2 or c.tree == 3, where .. ": tree " .. tostring(c.tree))
    assertEqual(c.role, trees[c.tree], where .. ": role")
    assertEqual(type(c.spec), "string", where .. ": spec label")
  end)
end)

test("sim sample: a pet only on a class that has one, and each set shows one", function()
  local _, Sim = env()
  for client, set in pairs(Sim.SAMPLE) do
    local pets = 0
    eachCharacter(set, function(c, where)
      if c.pet ~= nil then
        pets = pets + 1
        assertTrue(PET_CLASSES[c.classFile] == true, client .. " " .. where .. ": a pet on " .. c.classFile)
      end
    end)
    assertTrue(pets >= 1, client .. " has no pet")
  end
end)

test("sim sample: each set covers a tank, a healer and damage", function()
  local _, Sim = env()
  for client, set in pairs(Sim.SAMPLE) do
    local roles = {}
    eachCharacter(set, function(c) roles[c.role] = true end)
    assertEqual(sortedKeys(roles), "DAMAGER,HEALER,TANK", client)
  end
end)

-- -- Sample(client) -------------------------------------------------------------------------------

test("sim sample: Sample names its client, and answers a copy the caller owns", function()
  local _, Sim = env()
  for _, client in ipairs({ "retail", "forever" }) do
    local got = Sim.Sample(client)
    assertEqual(#got, #Sim.SAMPLE[client], client)
    assertFalse(rawequal(got, Sim.SAMPLE[client]), client .. ": the shared set itself")
    for i, c in ipairs(got) do
      assertFalse(rawequal(c, Sim.SAMPLE[client][i]), client .. " #" .. i .. ": a shared row")
      assertEqual(sortedKeys(c), sortedKeys(Sim.SAMPLE[client][i]), client .. " #" .. i)
      for k, v in pairs(c) do assertEqual(v, Sim.SAMPLE[client][i][k], client .. " #" .. i .. "." .. k) end
    end
    got[1].name = "Changed"
    got[2] = nil
    assertTrue(Sim.SAMPLE[client][1].name ~= "Changed", client .. ": a write reached SAMPLE")
    assertTrue(Sim.SAMPLE[client][2] ~= nil, client .. ": a removal reached SAMPLE")
  end
end)

test("sim sample: Sample() answers the active client's set through LibKa0s-Compat-1.0", function()
  local _, retail = env("retail")
  assertEqual(retail.Sample()[1].fullName, retail.SAMPLE.retail[1].fullName, "on retail")
  local _, forever = env("forever")
  assertEqual(forever.Sample()[1].fullName, forever.SAMPLE.forever[1].fullName, "on forever")
end)

test("sim sample: Sample() reads the client at call time, not at load", function()
  local m, Sim = env("retail")
  MockClient.apply(m, "forever")
  assertEqual(Sim.Sample()[1].fullName, Sim.SAMPLE.forever[1].fullName)
end)

test("sim sample: with no Compat, or a client that is neither, Sample() answers retail", function()
  local _, Sim = env("forever", { noCompat = true })
  assertEqual(Sim.Sample()[1].fullName, Sim.SAMPLE.retail[1].fullName, "no Compat")
  local m, Sim2 = env("retail")
  m.WOW_PROJECT_ID, m.WOW_PROJECT_MAINLINE, m.WOW_PROJECT_CAMELOT = nil, nil, nil
  assertEqual(Sim2.Sample()[1].fullName, Sim2.SAMPLE.retail[1].fullName, "neither client")
end)

test("sim sample: an unknown client raises at the caller's line", function()
  local _, Sim = env()
  for _, bad in ipairs({ "classic", "both", 1, true }) do
    local ok, err = pcall(Sim.Sample, bad)
    assertFalse(ok, tostring(bad))
    assertTrue(tostring(err):find('Sample: unknown client "' .. tostring(bad) .. '"', 1, true) ~= nil, tostring(err))
  end
end)

-- -- SampleCrowd(client, n, seed) (minor 5, LibKa0s#104) ---------------------------------------

-- The classes each client has, and the roles a role-balanced crowd draws in turn.
local CLASSES = {
  retail = { "DEATHKNIGHT", "DEMONHUNTER", "DRUID", "EVOKER", "HUNTER", "MAGE", "MONK", "PALADIN", "PRIEST",
    "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR" },
  forever = { "DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR" },
}
local SEEDS = { 1, 2, 7, 42, 20261124, 2147483646 }

--- Hold one crowd row to the convention, by its client's shape (the protagonists' cases, row by row).
local function conventional(m, client, c, where)
  assertTrue(fictional(c.name), where .. ": name " .. tostring(c.name))
  if c.surname ~= nil then assertTrue(fictional(c.surname), where .. ": surname " .. tostring(c.surname)) end
  if c.pet ~= nil then
    assertTrue(fictional(c.pet), where .. ": pet " .. tostring(c.pet))
    assertTrue(PET_CLASSES[c.classFile] == true, where .. ": a pet on " .. tostring(c.classFile))
  else
    assertNil(PET_CLASSES[c.classFile], where .. ": a " .. tostring(c.classFile) .. " with no pet")
  end
  assertTrue(REALMS[c.realm] == true, where .. ": realm " .. tostring(c.realm))
  for _, field in ipairs({ "name", "surname", "realm", "fullName", "pet", "spec" }) do
    if c[field] ~= nil then noRealRealm(c[field], where .. "." .. field) end
  end
  assertEqual(type(c.spec), "string", where .. ": spec label")
  if client == "retail" then
    assertNil(c.surname, where .. ": retail has no surname")
    assertNil(c.tree, where .. ": retail has no tree")
    assertEqual(c.fullName, c.name .. "-" .. c.realm, where .. ": fullName")
    local specs = RETAIL_SPECS[c.classFile]
    assertTrue(specs ~= nil and specs[c.specID] ~= nil, where .. ": specID " .. tostring(c.specID))
    assertEqual(c.role, specs[c.specID], where .. ": role")
  else
    assertEqual(c.fullName, c.name .. " " .. tostring(c.surname), where .. ": fullName has no realm")
    assertNil(c.specID, where .. ": no forever spec ID")
    local trees = m.LibStub("LibKa0s-Role-1.0").TALENT_GROUP_ROLE[c.classFile]
    assertTrue(trees ~= nil, where .. ": " .. tostring(c.classFile) .. " is not a forever class")
    assertTrue(c.tree == 1 or c.tree == 2 or c.tree == 3, where .. ": tree " .. tostring(c.tree))
    assertEqual(c.role, trees[c.tree], where .. ": role")
  end
end

local function rowKey(c)
  local keys, out = {}, {}
  for k in pairs(c) do keys[#keys + 1] = k end
  table.sort(keys)
  for _, k in ipairs(keys) do out[#out + 1] = k .. "=" .. tostring(c[k]) end
  return table.concat(out, ";")
end

local function crowdKey(rows)
  local out = {}
  for i, c in ipairs(rows) do out[i] = rowKey(c) end
  return table.concat(out, "|")
end

test("sim sample: SampleCrowd holds enough people for a 40-player raid roster, on both clients", function()
  local _, Sim = env()
  assertEqual(type(Sim.SampleCrowd), "function")
  assertTrue(type(Sim.CROWD_MAX) == "number" and Sim.CROWD_MAX >= 39, "CROWD_MAX covers 39 raiders besides you")
  for _, client in ipairs({ "retail", "forever" }) do
    for _, n in ipairs({ 0, 1, 4, 5, 19, 35, 39, Sim.CROWD_MAX }) do
      assertEqual(#Sim.SampleCrowd(client, n), n, client .. " n=" .. n)
    end
    -- The raid DropWatcher simulates: you, the five protagonists and 34 of the crowd, all apart.
    local seen = {}
    local raid = Sim.Sample(client)
    for _, c in ipairs(Sim.SampleCrowd(client, 35, 9)) do raid[#raid + 1] = c end
    assertEqual(#raid, 40, client)
    for _, c in ipairs(raid) do
      assertNil(seen[c.fullName], client .. ": " .. c.fullName .. " twice in the raid")
      seen[c.fullName] = true
    end
  end
end)

test("sim sample: every crowd row follows the convention, rules 1 to 5, on both clients and many seeds", function()
  local m, Sim = env()
  for _, client in ipairs({ "retail", "forever" }) do
    for _, seed in ipairs(SEEDS) do
      for i, c in ipairs(Sim.SampleCrowd(client, Sim.CROWD_MAX, seed)) do
        conventional(m, client, c, ("%s seed %d #%d %s"):format(client, seed, i, tostring(c.name)))
      end
    end
  end
end)

test("sim sample: crowd names are unique and never a protagonist's name, surname or pet", function()
  local _, Sim = env()
  for _, client in ipairs({ "retail", "forever" }) do
    local taken = {}
    for _, row in ipairs(Sim.SAMPLE[client]) do
      for _, field in ipairs({ "name", "surname", "pet" }) do
        if row[field] then taken[row[field]] = row.name .. "." .. field end
      end
    end
    for _, seed in ipairs(SEEDS) do
      local names, full = {}, {}
      for i, c in ipairs(Sim.SampleCrowd(client, Sim.CROWD_MAX, seed)) do
        local where = ("%s seed %d #%d"):format(client, seed, i)
        assertNil(taken[c.name], where .. ": " .. c.name .. " is the protagonist " .. tostring(taken[c.name]))
        if c.surname then assertNil(taken[c.surname], where .. ": surname " .. c.surname .. " is a protagonist's") end
        if c.pet then assertNil(taken[c.pet], where .. ": pet " .. c.pet .. " is a protagonist's") end
        assertNil(names[c.name], where .. ": name repeated")
        assertNil(full[c.fullName], where .. ": fullName repeated")
        names[c.name], full[c.fullName] = true, true
      end
    end
  end
end)

test("sim sample: a crowd covers every class the client has once it is that large", function()
  local _, Sim = env()
  for _, client in ipairs({ "retail", "forever" }) do
    for _, seed in ipairs(SEEDS) do
      for _, n in ipairs({ #CLASSES[client], 20, 40, Sim.CROWD_MAX }) do
        local have = {}
        for _, c in ipairs(Sim.SampleCrowd(client, n, seed)) do have[c.classFile] = true end
        assertEqual(sortedKeys(have), table.concat(CLASSES[client], ","), ("%s seed %d n=%d"):format(client, seed, n))
      end
    end
  end
end)

test("sim sample: a crowd's roles are balanced, a tank and a healer for every three damage", function()
  local _, Sim = env()
  for _, client in ipairs({ "retail", "forever" }) do
    for n = 1, Sim.CROWD_MAX do
      local count = { TANK = 0, HEALER = 0, DAMAGER = 0 }
      for _, c in ipairs(Sim.SampleCrowd(client, n, n)) do count[c.role] = count[c.role] + 1 end
      local where = ("%s n=%d"):format(client, n)
      assertEqual(count.TANK, math.floor((n + 4) / 5), where .. " tanks")
      assertEqual(count.HEALER, math.floor((n + 3) / 5), where .. " healers")
      assertEqual(count.DAMAGER, n - count.TANK - count.HEALER, where .. " damage")
    end
  end
end)

test("sim sample: a seed replays its crowd, and a crowd is a copy the caller owns", function()
  local _, Sim = env()
  for _, client in ipairs({ "retail", "forever" }) do
    for _, seed in ipairs(SEEDS) do
      local a, b = Sim.SampleCrowd(client, 40, seed), Sim.SampleCrowd(client, 40, seed)
      assertEqual(crowdKey(a), crowdKey(b), client .. " seed " .. seed)
      a[1].name = "Changed"
      assertTrue(Sim.SampleCrowd(client, 40, seed)[1].name ~= "Changed", client .. ": a write reached the next call")
    end
    assertEqual(crowdKey(Sim.SampleCrowd(client, 12)), crowdKey(Sim.SampleCrowd(client, 12, 1)), client .. ": nil is seed 1")
    assertTrue(crowdKey(Sim.SampleCrowd(client, 12, 2)) ~= crowdKey(Sim.SampleCrowd(client, 12, 3)), client .. ": seeds differ")
    -- A smaller crowd is the larger one's head, so a host that asks for more keeps its first people.
    local big, small = Sim.SampleCrowd(client, Sim.CROWD_MAX, 5), Sim.SampleCrowd(client, 10, 5)
    for i = 1, 10 do assertEqual(rowKey(small[i]), rowKey(big[i]), client .. " head #" .. i) end
  end
end)

test("sim sample: the same seed names the same people on both clients, in the same order", function()
  local _, Sim = env()
  for _, seed in ipairs(SEEDS) do
    local r, f = Sim.SampleCrowd("retail", 30, seed), Sim.SampleCrowd("forever", 30, seed)
    for i = 1, 30 do assertEqual(r[i].name, f[i].name, "seed " .. seed .. " #" .. i) end
  end
end)

test("sim sample: SampleCrowd() reads the client through Compat at call time", function()
  local m, Sim = env("retail")
  assertEqual(Sim.SampleCrowd(nil, 3, 4)[1].fullName, Sim.SampleCrowd("retail", 3, 4)[1].fullName, "on retail")
  MockClient.apply(m, "forever")
  assertEqual(Sim.SampleCrowd(nil, 3, 4)[1].fullName, Sim.SampleCrowd("forever", 3, 4)[1].fullName, "on forever")
  local _, bare = env("forever", { noCompat = true })
  assertEqual(bare.SampleCrowd(nil, 3, 4)[1].fullName, bare.SampleCrowd("retail", 3, 4)[1].fullName, "no Compat")
end)

test("sim sample: SampleCrowd refuses an unknown client, a bad size and a bad seed at the caller's line", function()
  local _, Sim = env()
  local function raises(needle, ...)
    local ok, err = pcall(Sim.SampleCrowd, ...)
    assertFalse(ok, needle)
    assertTrue(tostring(err):find(needle, 1, true) ~= nil, tostring(err))
  end
  raises('SampleCrowd: unknown client "classic"', "classic", 3)
  for _, bad in ipairs({ -1, 1.5, Sim.CROWD_MAX + 1, "x" }) do raises("SampleCrowd: n must be", "retail", bad) end
  raises("SampleCrowd: n must be", "retail", nil)
  raises("SampleCrowd: seed must be", "retail", 3, "x")
end)

test("sim sample: the shell's minor is 6", function()
  local _, Sim = env()
  assertEqual(Sim.MINOR, 6)
  assertEqual(Sim.MODULES.Sim, 6)
end)
