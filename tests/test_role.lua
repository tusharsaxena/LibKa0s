-- tests/test_role.lua -- LibKa0s-Role-1.0: the player's spec and the role it plays.
--
-- Every case installs the WHOLE client it needs through `with` (the project constants included), so
-- a case means the same thing under both kit profiles: `lua tests/run.lua` and
-- `KA0S_KIT_CLIENT=forever lua tests/run.lua` run every branch of Resolve, the Retail ones and the
-- Forever ones, because the client a case reads is the one it installed. Nothing under test is
-- stubbed (testing-§8); LibKa0s-Compat-1.0 is the real one the library loaded, and its IsForever
-- reads the constants installed here.
--
-- The talent fixture is a warrior's Forever tree: three groups (Arms, Fury, Protection) handed back
-- by GetGroupDisplayInfoByTreeID OUT of display order, so the sort by orderIndex is exercised by
-- every talent case, and the points spent in each set per case.

local T = _G.LK_TEST
local role, mocks = T.role, T.mocks
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local Loader     = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

-- -- fixtures ---------------------------------------------------------------------------------

local ABSENT = setmetatable({}, { __tostring = function() return "ABSENT" end })

--- Run `fn` with each key of `fixture` installed in the mock environment (ABSENT removes it), then
--- restore every key and re-raise (the shape tests/test_compat.lua uses).
local function with(fixture, fn)
  local saved, savedG = {}, {}
  for key, value in pairs(fixture) do
    saved[key], savedG[key] = mocks[key], rawget(_G, key)
    if rawequal(value, ABSENT) then
      mocks[key] = nil
      rawset(_G, key, nil)
    else
      mocks[key] = value
    end
  end
  local ok, err = pcall(fn)
  for key in pairs(fixture) do
    mocks[key] = saved[key]
    rawset(_G, key, savedG[key])
  end
  if not ok then error(err, 0) end
end

local function raiser(what)
  return function() error("SECRET: attempted " .. what, 2) end
end

local SECRET = setmetatable({}, {
  __eq = raiser("=="), __lt = raiser("<"), __le = raiser("<="), __concat = raiser(".."),
  __len = raiser("#"), __index = raiser("index"), __newindex = raiser("assign"),
  __call = raiser("call"),
})

local function secretSystem(v) return rawequal(v, SECRET) end

local function merge(base, extra)
  for k, v in pairs(extra or {}) do base[k] = v end
  return base
end

local CONFIG, TREE = 77, 500
local ARMS, FURY, PROT = 101, 102, 103

--- A warrior's Forever tree with `arms`, `fury`, `prot` points spent. `opts.noConfigInfo` drops
--- C_Traits.GetConfigInfo (the tree then comes from GetTraitTreeForSpec); `opts.noCurrency` gives a
--- group no currency entry.
local function traits(arms, fury, prot, opts)
  opts = opts or {}
  local spent = { [ARMS] = arms, [FURY] = fury, [PROT] = prot }
  local t = {
    GetGroupDisplayInfoByTreeID = function(treeID)
      if treeID ~= TREE then return {} end
      return {
        { groupID = PROT, treeID = TREE, orderIndex = 2, displayName = "Protection" },
        { groupID = ARMS, treeID = TREE, orderIndex = 0, displayName = "Arms" },
        { groupID = FURY, treeID = TREE, orderIndex = 1, displayName = "Fury" },
      }
    end,
    GetGroupCurrencyInfo = function(configID, ids)
      assertEqual(configID, CONFIG, "GetGroupCurrencyInfo's config")
      local out = {}
      for _, id in ipairs(ids) do
        if not (opts.noCurrency and id == FURY) then
          out[#out + 1] = { traitNodeGroupID = id, currencyInfos = { { spent = spent[id] } } }
        end
      end
      return out
    end,
  }
  if not opts.noConfigInfo then
    t.GetConfigInfo = function(id)
      if id == CONFIG then return { ID = CONFIG, treeIDs = { TREE } } end
      return nil
    end
  end
  return t
end

--- The specs a class has, by class id: warrior 1 (three on Retail), paladin 2.
local CLASS_SPECS = {
  [1] = { { 71, "Arms", "DAMAGER" }, { 72, "Fury", "DAMAGER" }, { 73, "Protection", "TANK" } },
  [2] = { { 65, "Holy", "HEALER" }, { 66, "Protection", "TANK" }, { 70, "Retribution", "DAMAGER" } },
}
local CLASSES = { { "Warrior", "WARRIOR", 1 }, { "Paladin", "PALADIN", 2 } }

--- A whole client. `kind` is "retail" or "forever"; `spec` is the active spec as
--- `{ index, id, name, role }`; `extra` overrides any key.
local function client(kind, spec, extra)
  spec = spec or { 1, 1001, "Warrior", "DAMAGER" }
  local f = {
    WOW_PROJECT_MAINLINE = 1,
    WOW_PROJECT_ID = kind == "forever" and 18 or 1,
    WOW_PROJECT_CAMELOT = kind == "forever" and 18 or ABSENT,
    issecretvalue = secretSystem,
    UnitClass = function() return "Warrior", "WARRIOR", 1 end,
    UnitGroupRolesAssigned = function() return "NONE" end,
    GetSpecialization = ABSENT, GetSpecializationInfo = ABSENT,
    GetNumSpecializationsForClassID = ABSENT, GetSpecializationInfoForClassID = ABSENT,
    GetClassInfo = ABSENT,
    GetNumClasses = function() return #CLASSES end,
    C_CreatureInfo = {
      GetClassInfo = function(i)
        local c = CLASSES[i]
        return c and { className = c[1], classFile = c[2], classID = c[3] } or nil
      end,
    },
    C_SpecializationInfo = {
      GetSpecialization = function() return spec[1] end,
      GetSpecializationInfo = function(i)
        if i ~= spec[1] then return nil end
        return spec[2], spec[3], "desc", 132355, spec[4]
      end,
      GetActiveSpecGroup = function() return 1 end,
      GetCombatConfigIDForSpecGroup = function(g) return g == 1 and CONFIG or nil end,
      GetNumSpecializationsForClassID = function(id) return CLASS_SPECS[id] and #CLASS_SPECS[id] or 0 end,
      GetSpecializationInfoForClassID = function(id, i)
        local s = CLASS_SPECS[id] and CLASS_SPECS[id][i]
        if not s then return nil end
        return s[1], s[2], "desc", 132355, s[3], false, true
      end,
    },
    C_ClassTalents = {
      GetActiveConfigID = function() return CONFIG end,
      GetTraitTreeForSpec = function(specID) return specID == spec[2] and TREE or nil end,
    },
    C_Traits = traits(0, 0, 0),
  }
  return merge(f, extra)
end

local function pack(...) return { n = select("#", ...), ... } end

local function assertResolve(store, wantRole, wantSource, wantDetail, label)
  local got = pack(role.Resolve(store))
  assertEqual(got.n, 3, label .. ": arity")
  assertEqual(got[1], wantRole, label .. ": role")
  assertEqual(got[2], wantSource, label .. ": source")
  assertEqual(got[3], wantDetail, label .. ": detail")
end

-- -- registration and shape -------------------------------------------------------------------

test("role: registers minor 1 with exactly its public members", function()
  assertEqual(role.MAJOR, "LibKa0s-Role-1.0")
  assertEqual(role.MINOR, 1)
  assertEqual(role.MODULES.Role, 1)
  local names = {}
  for _, member in ipairs(T.publicMembers(role)) do
    names[#names + 1] = member.name .. ":" .. member.kind
  end
  assertEqual(table.concat(names, ","), "Groups:function,Resolve:function,SetOverride:function,"
    .. "Spec:function,SpecsForClass:function,TALENT_GROUP_ROLE:table")
end)

test("role: the Core floor keeps the major absent from a payload without Core", function()
  local src = Loader.readFile("LibKa0s/Role.lua")
  local bare = buildMocks()
  Loader.loadSource(src, "@LibKa0s/Role.lua", nil, bare)
  assertNil(bare.LibStub("LibKa0s-Role-1.0", true), "no Core: no NewLibrary")
  Loader.loadSource(Loader.readFile("LibKa0s/Core.lua"), "@LibKa0s/Core.lua", nil, bare)
  Loader.loadSource(src, "@LibKa0s/Role.lua", nil, bare)
  assertTrue(bare.LibStub("LibKa0s-Role-1.0", true) ~= nil, "with Core: registered")
end)

test("role: the source reads every global bare, never through the global table", function()
  local src = Loader.readFile("LibKa0s/Role.lua")
  assertFalse(src:find("_G.", 1, true), "Role.lua reads a global through `_G.`")
  assertFalse(src:find("_G[", 1, true), "Role.lua reads a global through `_G[`")
end)

test("role: the talent seed names three valid roles for each of the nine classic classes", function()
  local classes = {}
  for file, roles in pairs(role.TALENT_GROUP_ROLE) do
    classes[#classes + 1] = file
    assertEqual(#roles, 3, file .. ": three groups")
    for i, r in ipairs(roles) do
      assertTrue(r == "TANK" or r == "HEALER" or r == "DAMAGER", file .. "[" .. i .. "]")
    end
  end
  table.sort(classes)
  assertEqual(table.concat(classes, ","), "DRUID,HUNTER,MAGE,PALADIN,PRIEST,ROGUE,SHAMAN,WARLOCK,WARRIOR")
  assertEqual(table.concat(role.TALENT_GROUP_ROLE.WARRIOR, ","), "DAMAGER,DAMAGER,TANK")
  assertEqual(table.concat(role.TALENT_GROUP_ROLE.PALADIN, ","), "HEALER,TANK,DAMAGER")
end)

-- -- Spec -------------------------------------------------------------------------------------

test("role: Spec answers the active spec's id and name through Compat, exactly two values", function()
  with(client("retail", { 3, 73, "Protection", "TANK" }), function()
    local got = pack(role.Spec())
    assertEqual(got.n, 2, "arity")
    assertEqual(got[1], 73)
    assertEqual(got[2], "Protection")
  end)
end)

test("role: Spec answers nil for no spec, a zero id and a secret id", function()
  with(client("forever", nil, {
    C_SpecializationInfo = { GetSpecialization = function() return nil end },
  }), function()
    local id, name = role.Spec()
    assertNil(id, "no index"); assertNil(name, "no index")
  end)
  with(client("retail", { 1, 0, "None", "DAMAGER" }), function()
    assertNil((role.Spec()), "zero id")
  end)
  with(client("retail", { 1, SECRET, SECRET, "DAMAGER" }), function()
    local id, name = role.Spec()
    assertNil(id, "secret id"); assertNil(name, "secret name")
  end)
end)

-- -- SpecsForClass ----------------------------------------------------------------------------

test("role: SpecsForClass lists a class's specs from the client, in index order", function()
  with(client("retail"), function()
    local specs = role.SpecsForClass("PALADIN")
    assertEqual(#specs, 3)
    assertEqual(specs[1].id, 65); assertEqual(specs[1].name, "Holy"); assertEqual(specs[1].role, "HEALER")
    assertEqual(specs[3].id, 70); assertEqual(specs[3].role, "DAMAGER")
  end)
end)

test("role: SpecsForClass with no class reads the player's own", function()
  with(client("forever", nil, { UnitClass = function() return "Paladin", "PALADIN", 2 end }), function()
    local specs = role.SpecsForClass()
    assertEqual(#specs, 3)
    assertEqual(specs[2].name, "Protection")
  end)
end)

test("role: SpecsForClass falls to the globals when the namespaced rungs are absent", function()
  with(client("retail", nil, {
    C_CreatureInfo = ABSENT,
    GetClassInfo = function(i) local c = CLASSES[i]; if c then return c[1], c[2], c[3] end end,
    C_SpecializationInfo = { GetSpecialization = function() return 1 end },
    GetNumSpecializationsForClassID = function(id) return id == 1 and 1 or 0 end,
    GetSpecializationInfoForClassID = function(id, i)
      if id == 1 and i == 1 then return 1446, "Warrior", "desc", 1, "DAMAGER" end
    end,
  }), function()
    local specs = role.SpecsForClass("WARRIOR")
    assertEqual(#specs, 1)
    assertEqual(specs[1].id, 1446)
    assertEqual(specs[1].role, "DAMAGER")
  end)
end)

test("role: SpecsForClass is an empty table for an unknown class, a missing API or a secret", function()
  with(client("retail"), function()
    assertEqual(#role.SpecsForClass("DEMONHUNTER"), 0, "unknown class")
    assertEqual(#role.SpecsForClass(SECRET), 0, "secret class")
  end)
  with(client("retail", nil, { GetNumClasses = ABSENT }), function()
    assertEqual(#role.SpecsForClass("WARRIOR"), 0, "no class list")
  end)
  with(client("retail", nil, {
    C_SpecializationInfo = { GetSpecialization = function() return 1 end },
  }), function()
    assertEqual(#role.SpecsForClass("WARRIOR"), 0, "no spec count")
  end)
  with(client("retail", nil, { UnitClass = ABSENT }), function()
    assertEqual(#role.SpecsForClass(), 0, "no player class")
  end)
end)

-- -- Groups -----------------------------------------------------------------------------------

test("role: Groups lists Forever's talent groups in display order with the points spent", function()
  with(client("forever", nil, { C_Traits = traits(5, 0, 31) }), function()
    local groups = role.Groups()
    assertEqual(#groups, 3)
    local seen = {}
    for i, g in ipairs(groups) do
      assertEqual(g.index, i, "index")
      seen[#seen + 1] = ("%s=%d"):format(g.name, g.spent)
    end
    assertEqual(table.concat(seen, ","), "Arms=5,Fury=0,Protection=31")
    assertEqual(groups[3].id, PROT)
    assertNil(groups[1].order, "the sort key is not part of the answer")
  end)
end)

test("role: Groups is empty on Retail even where C_Traits answers", function()
  with(client("retail", nil, { C_Traits = traits(5, 0, 31) }), function()
    assertEqual(#role.Groups(), 0)
  end)
end)

test("role: Groups takes the config from GetActiveConfigID and the tree from the spec when needed", function()
  with(client("forever", nil, {
    C_SpecializationInfo = {
      GetSpecialization = function() return 1 end,
      GetSpecializationInfo = function() return 1001, "Warrior", "desc", 1, "DAMAGER" end,
      GetActiveSpecGroup = function() return 1 end,
      GetCombatConfigIDForSpecGroup = function() return nil end,
    },
    C_Traits = traits(0, 12, 0, { noConfigInfo = true }),
  }), function()
    local groups = role.Groups()
    assertEqual(#groups, 3)
    assertEqual(groups[2].spent, 12)
  end)
end)

test("role: Groups reads a group with no currency entry as zero points", function()
  with(client("forever", nil, { C_Traits = traits(3, 9, 4, { noCurrency = true }) }), function()
    assertEqual(role.Groups()[2].spent, 0)
  end)
end)

test("role: Groups is empty when C_Traits, the config or the tree is missing", function()
  with(client("forever", nil, { C_Traits = ABSENT }), function()
    assertEqual(#role.Groups(), 0, "no C_Traits")
  end)
  with(client("forever", nil, {
    C_SpecializationInfo = { GetSpecialization = function() return 1 end },
    C_ClassTalents = ABSENT,
  }), function()
    assertEqual(#role.Groups(), 0, "no config")
  end)
  with(client("forever", nil, {
    C_Traits = traits(1, 1, 1, { noConfigInfo = true }), C_ClassTalents = {
      GetActiveConfigID = function() return CONFIG end,
    },
  }), function()
    assertEqual(#role.Groups(), 0, "no tree")
  end)
end)

-- -- Resolve: the order -----------------------------------------------------------------------

test("role: Resolve answers the player's override first, over every other rung, and never saves it", function()
  with(client("forever", nil, {
    UnitGroupRolesAssigned = function() return "HEALER" end, C_Traits = traits(0, 0, 31),
  }), function()
    local store = { override = "DAMAGER" }
    assertResolve(store, "DAMAGER", "override", nil, "override")
    assertEqual(store.last, nil, "an override is not saved")
    store.override = nil
    assertResolve(store, "HEALER", "assigned", nil, "cleared override")
    assertEqual(store.last.role, "HEALER")
    assertEqual(store.last.specID, 1001)
  end)
end)

test("role: Resolve ignores an override that is not a role", function()
  with(client("retail", { 3, 73, "Protection", "TANK" }), function()
    assertResolve({ override = "tank" }, "TANK", "spec", "Protection", "lowercase")
    assertResolve({ override = SECRET }, "TANK", "spec", "Protection", "secret")
  end)
end)

test("role: Resolve answers the group-assigned role next", function()
  with(client("forever", nil, {
    UnitGroupRolesAssigned = function() return "HEALER" end, C_Traits = traits(0, 0, 31),
  }), function()
    assertResolve({}, "HEALER", "assigned", nil, "assigned")
  end)
end)

test("role: Resolve passes over NONE, a secret and an absent UnitGroupRolesAssigned", function()
  with(client("retail", { 3, 73, "Protection", "TANK" }, {
    UnitGroupRolesAssigned = function() return SECRET end,
  }), function()
    assertResolve({}, "TANK", "spec", "Protection", "secret assigned")
  end)
  with(client("retail", { 3, 73, "Protection", "TANK" }, { UnitGroupRolesAssigned = ABSENT }), function()
    assertResolve({}, "TANK", "spec", "Protection", "absent")
  end)
end)

test("role: Resolve on Forever answers the talent group with the most points", function()
  with(client("forever", nil, { C_Traits = traits(5, 0, 31) }), function()
    local store = {}
    assertResolve(store, "TANK", "talents", "Protection", "protection warrior")
    assertEqual(store.last.role, "TANK")
  end)
  with(client("forever", nil, { C_Traits = traits(31, 5, 15) }), function()
    assertResolve({}, "DAMAGER", "talents", "Arms", "arms warrior")
  end)
  with(client("forever", { 1, 1002, "Paladin", "DAMAGER" }, {
    UnitClass = function() return "Paladin", "PALADIN", 2 end, C_Traits = traits(31, 0, 20),
  }), function()
    assertResolve({}, "HEALER", "talents", "Arms", "the first group of a paladin is Holy")
  end)
end)

test("role: Resolve on Forever falls through a tie, zero points and an unseeded class", function()
  with(client("forever", nil, { C_Traits = traits(10, 0, 10) }), function()
    assertResolve({}, "DAMAGER", "spec", "Warrior", "tie")
  end)
  with(client("forever", nil, { C_Traits = traits(0, 0, 0) }), function()
    assertResolve({}, "DAMAGER", "spec", "Warrior", "zero")
  end)
  with(client("forever", nil, {
    UnitClass = function() return "Death Knight", "DEATHKNIGHT", 6 end, C_Traits = traits(0, 0, 31),
  }), function()
    assertResolve({}, "DAMAGER", "spec", "Warrior", "no seed")
  end)
end)

test("role: Resolve on Retail never reads the talent groups", function()
  local called = 0
  local t = traits(0, 0, 31)
  local inner = t.GetGroupDisplayInfoByTreeID
  t.GetGroupDisplayInfoByTreeID = function(...) called = called + 1; return inner(...) end
  with(client("retail", { 1, 71, "Arms", "DAMAGER" }, { C_Traits = t }), function()
    assertResolve({}, "DAMAGER", "spec", "Arms", "retail arms")
  end)
  assertEqual(called, 0, "C_Traits read on Retail")
end)

test("role: Resolve answers the spec API's role, and saves it with the spec id", function()
  with(client("retail", { 3, 73, "Protection", "TANK" }), function()
    local store = {}
    assertResolve(store, "TANK", "spec", "Protection", "spec")
    assertEqual(store.last.role, "TANK")
    assertEqual(store.last.specID, 73)
  end)
end)

test("role: Resolve answers the saved role when the client cannot, and does not rewrite it", function()
  with(client("retail", nil, {
    C_SpecializationInfo = { GetSpecialization = function() return nil end },
  }), function()
    local last = { role = "HEALER", specID = 65 }
    local store = { last = last }
    assertResolve(store, "HEALER", "saved", nil, "saved")
    assertTrue(rawequal(store.last, last), "the saved table is the same table")
    assertEqual(last.specID, 65, "untouched")
    assertResolve({ last = { role = "nope" } }, nil, nil, nil, "an invalid saved role")
    assertResolve({}, nil, nil, nil, "nothing at all")
  end)
end)

test("role: Resolve accepts no store, and answers without writing", function()
  with(client("retail", { 3, 73, "Protection", "TANK" }), function()
    assertResolve(nil, "TANK", "spec", "Protection", "nil store")
    assertResolve("x", "TANK", "spec", "Protection", "a store that is not a table")
  end)
end)

test("role: a resolved answer updates store.last in place", function()
  with(client("retail", { 3, 73, "Protection", "TANK" }), function()
    local last = { role = "HEALER", specID = 65 }
    local store = { last = last }
    assertResolve(store, "TANK", "spec", "Protection", "update")
    assertTrue(rawequal(store.last, last), "the same table")
    assertEqual(last.role, "TANK"); assertEqual(last.specID, 73)
  end)
end)

test("role: without Compat, the override and the saved role still answer", function()
  local bare = buildMocks()
  Loader.loadSource(Loader.readFile("LibKa0s/Core.lua"), "@LibKa0s/Core.lua", nil, bare)
  Loader.loadSource(Loader.readFile("LibKa0s/Role.lua"), "@LibKa0s/Role.lua", nil, bare)
  local lone = bare.LibStub("LibKa0s-Role-1.0", true)
  bare.UnitGroupRolesAssigned = nil
  local id, name = lone.Spec()
  assertNil(id, "spec id"); assertNil(name, "spec name")
  assertEqual(#lone.Groups(), 0, "groups")
  assertEqual((lone.Resolve({ override = "TANK" })), "TANK", "override")
  local r, source = lone.Resolve({ last = { role = "HEALER" } })
  assertEqual(r, "HEALER"); assertEqual(source, "saved")
end)

-- -- SetOverride ------------------------------------------------------------------------------

test("role: SetOverride sets a valid role and clears with nil", function()
  local store = {}
  role.SetOverride(store, "HEALER")
  assertEqual(store.override, "HEALER")
  role.SetOverride(store, nil)
  assertNil(store.override)
end)

test("role: SetOverride raises on an unknown role and on a store that is not a table", function()
  local ok, err = pcall(role.SetOverride, {}, "Tank")
  assertFalse(ok); assertTrue(tostring(err):find('unknown role "Tank"', 1, true) ~= nil, tostring(err))
  ok, err = pcall(role.SetOverride, nil, "TANK")
  assertFalse(ok); assertTrue(tostring(err):find("store must be a table", 1, true) ~= nil, tostring(err))
end)
