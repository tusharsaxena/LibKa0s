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

test("sim sample: the shell's minor is 3", function()
  local _, Sim = env()
  assertEqual(Sim.MINOR, 3)
  assertEqual(Sim.MODULES.Sim, 3)
end)
