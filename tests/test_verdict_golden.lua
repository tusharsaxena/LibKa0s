-- tests/test_verdict_golden.lua -- LibKa0s-Verdict-1.0 against the golden verdict table: the same
-- plain-data table Ka0s Drop Watcher's own tests/test_verdict_golden.lua drives its engine over
-- (DropWatcher#19, its plan task A1), copied here unchanged as tests/fixtures/verdict_golden.lua
-- (its header holds the shape). A move that changes one verdict fails on one side or the other.
--
-- The kernel half (`cases`) runs lib.Evaluate with the case's client named in `opts.client`, so
-- every case runs on either kit profile (the client is the caller's here; a case's `profile` is
-- Drop Watcher's, where the off-spec module initializes on Retail alone). A `collect` case runs
-- lib.Collect.Verdict and a `weights` scorer is lib.Score.WeightsScorer for the case's client.
--
-- The read half (`me`) seeds a fresh client (tests/fixture_verdict_client.lua) from the case's
-- setup, makes an instance for the case's client whose config is Drop Watcher's comparison
-- defaults (defaults/Profile.lua) with the case's settings over them, reads the link through
-- v:Facts and judges it through v:JudgeFacts, your gear from v:Snapshot and the scorer from the
-- config, as Drop Watcher's NS.ItemFacts.Get and NS.LootFeed.JudgeMe do. The client is the
-- instance's, so every case runs on either kit profile.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

local V = T.mocks.LibStub("LibKa0s-Verdict-1.0")
local GOLDEN = dofile("tests/fixtures/verdict_golden.lua")
local FC = dofile("tests/fixture_verdict_client.lua")

-- -- the comparison ----------------------------------------------------------------------------

local function reasonKeys(res)
  local out = {}
  for i, r in ipairs(res.reasons or {}) do out[i] = r.key end
  return out
end

local function expectFields(got, want, label)
  for k, v in pairs(want or {}) do assertEqual(got[k], v, label .. "." .. k) end
end

local function check(res, expect, label)
  if expect.none then
    assertEqual(res, nil, label .. ": no verdict")
    return
  end
  assertTrue(type(res) == "table", label .. ": a verdict")
  assertEqual(res.verdict, expect.verdict, label .. ": verdict")
  assertEqual(table.concat(reasonKeys(res), ","), table.concat(expect.reasonKeys or {}, ","), label .. ": reasons")
  expectFields(res, expect.fields, label)
  for key, detail in pairs(expect.details or {}) do
    local found
    for _, r in ipairs(res.reasons) do if r.key == key then found = r.detail end end
    assertEqual(found, detail, label .. ": " .. key .. " detail")
  end
  if expect.offSpec then
    assertTrue(type(res.offSpec) == "table", label .. ": an off-spec part")
    expectFields(res.offSpec, expect.offSpec, label .. ".offSpec")
  end
end

-- -- the kernel half -----------------------------------------------------------------------------

local function scorerOf(spec, client)
  if spec == nil then return nil end
  if spec.kind == "table" then
    return function(f) return type(f) == "table" and spec.scores[f.itemID] or nil end
  end
  if spec.kind == "weights" then return V.Score.WeightsScorer(spec.weights, client) end
  error("unknown scorer kind " .. tostring(spec.kind))
end

local function optsOf(data, client)
  local out = {}
  for k, v in pairs(data or {}) do out[k] = v end
  out.scorer = scorerOf(data and data.scorer, client)
  out.client = client
  return out
end

local function candidateOf(data)
  if type(data) ~= "table" then return data end
  local out = {}
  for k, v in pairs(data) do out[k] = v end
  if type(data.offSpecGear) == "table" then
    local map = data.offSpecGear
    out.offSpecGear = function(specID) return map[specID] end
  end
  return out
end

test("verdict golden: the table is Drop Watcher's, every kernel case named once", function()
  local seen = {}
  for _, case in ipairs(GOLDEN.cases) do
    assertTrue(not seen[case.name], "a case named twice: " .. case.name)
    seen[case.name] = true
    assertTrue(case.client == "retail" or case.client == "forever", case.name .. ": a client")
  end
  assertEqual(#GOLDEN.cases, 48, "the kernel half's 48 cases (DropWatcher plan task A1)")
end)

for _, case in ipairs(GOLDEN.cases) do
  test("verdict golden kernel: " .. case.name, function()
    local res
    if case.via == "collect" then
      res = V.Collect.Verdict(case.facts, case.forced == true, case.client)
    else
      res = V.Evaluate(case.facts, candidateOf(case.candidate), optsOf(case.opts, case.client))
    end
    check(res, case.expect, case.name)
  end)
end

-- -- the read half -------------------------------------------------------------------------------

-- Drop Watcher's comparison defaults (its defaults/Profile.lua), the config a fresh install judges on.
local DEFAULTS = { scorer = "auto", weights = {}, sidegradeBand = 0, compareOwned = false,
  heirloomProtect = true, undesired = {} }

local function configOf(settings)
  local cfg = {}
  for k, v in pairs(DEFAULTS) do cfg[k] = v end
  for path, value in pairs(settings or {}) do
    local key = path:match("^comparison%.(.+)$")
    assertTrue(key ~= nil, "a comparison setting: " .. tostring(path))
    cfg[key] = value
  end
  return cfg
end

local function seed(m, s)
  m.__context.class, m.__context.classToken, m.__context.level = s.class, s.classFile, s.level
  if s.talents then m.seedTalents(s.specID, s.talents) else m.specID = s.specID end
  for l, d in pairs(s.items or {}) do
    local copy = {}
    for k, v in pairs(d) do copy[k] = v end
    m.addItem(l, copy)
  end
  for slot, l in pairs(s.worn or {}) do m.inventory.player[slot] = l end
  for bag, slots in pairs(s.bags or {}) do
    m.bags[bag] = { size = 16 }
    for slot, l in pairs(slots) do m.bags[bag][slot] = l end
  end
  for l, data in pairs(s.tooltips or {}) do m.tooltips.hyperlink[l] = data end
  if s.mounts then
    for id, mount in pairs(s.mounts.byItem or {}) do m.mounts.byItem[id] = mount end
    for mount, known in pairs(s.mounts.collected or {}) do m.mounts.collected[mount] = known end
  end
  if s.pawn then FC.installPawn(m, { values = s.pawn.values, upgrades = s.pawn.upgrades }) end
end

test("verdict golden: the read half is Drop Watcher's, every case named once", function()
  local seen = {}
  for _, case in ipairs(GOLDEN.me) do
    assertTrue(not seen[case.name], "a case named twice: " .. case.name)
    seen[case.name] = true
  end
  assertEqual(#GOLDEN.me, 16, "the read half's 16 cases (DropWatcher plan task A1)")
end)

for _, case in ipairs(GOLDEN.me) do
  test("verdict golden me: " .. case.name, function()
    local W = FC.new{ client = case.client, seed = function(m) seed(m, case.setup) end }
    W.config = configOf(case.setup.settings)
    W.v:RefreshGear("test", true)
    assertEqual(W.v:Snapshot().classFile, case.setup.classFile, case.name .. ": the snapshot's class")
    local facts = W.v:Facts(case.link)
    assertTrue(facts ~= nil, case.name .. ": the drop's facts read")
    check(W.v:JudgeFacts(facts, { forced = case.setup.forced }), case.expect, case.name)
  end)
end
