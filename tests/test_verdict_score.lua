-- tests/test_verdict_score.lua -- LibKa0s-Verdict-1.0's scorers (VerdictScore.lua): the Pawn scale
-- import, the weights score and its unknown keys, which adapter is in use for each config, the
-- Pawn adapter for you and for a looter (its scales, "pending" while Pawn is not ready) on both
-- clients, and the sidegrade the kernel reaches when item level and score disagree. Ka0s Drop
-- Watcher's tests/test_scoring.lua, ported to lib.Score and the instance, plus the review focus of
-- its Item Search split plan, test 2: Pawn absent or not ready never errors, a pending score marks
-- the judgment pending, and it is judged again once Pawn answers.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local FC = dofile("tests/fixture_verdict_client.lua")

local V = T.mocks.LibStub("LibKa0s-Verdict-1.0")
local S = V.Score

local STR, INT, AGI = "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_AGILITY_SHORT"
local CRIT, HASTE = "ITEM_MOD_CRIT_RATING_SHORT", "ITEM_MOD_HASTE_RATING_SHORT"

local PAWN = '( Pawn: v1: "Arms": Class=1, Spec=1, Strength=1.50, CritRating=0.8, HasteRating=0.60,'
  .. ' Versatility=0, Dps=3.2, IsPlate=1, Leech=0.1 )'

local function count(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n
end

-- ---------------------------------------------------------------------------------------------
-- The pure halves
-- ---------------------------------------------------------------------------------------------

test("verdict score: a Pawn v1 string imports its stats under GetItemStats' keys", function()
  local warned = {}
  local r = S.ParseImport(PAWN, function(key) warned[#warned + 1] = key end)
  assertEqual(r.name, "Arms")
  assertEqual(r.weights[STR], 1.5); assertEqual(r.weights[CRIT], 0.8); assertEqual(r.weights[HASTE], 0.6)
  assertEqual(r.weights.ITEM_MOD_CR_LIFESTEAL_SHORT, 0.1)
  assertNil(r.weights.ITEM_MOD_VERSATILITY, "a 0 weight is left out")
  assertEqual(count(r.weights), 4)
  assertEqual(table.concat(r.skipped, ","), "Dps,IsPlate")
  assertEqual(#warned, 2, "each skipped stat is told")
end)

test("verdict score: an import that is empty, not a Pawn string, or has no stat is refused", function()
  local r, why = S.ParseImport("   ")
  assertNil(r); assertEqual(why, "empty")
  r, why = S.ParseImport(nil)
  assertNil(r); assertEqual(why, "empty")
  r, why = S.ParseImport("Strength=1, Agility=2")
  assertNil(r); assertEqual(why, "format")
  r, why = S.ParseImport('( Pawn: v2: "X": Strength=1 )')
  assertNil(r); assertEqual(why, "format")
  r, why = S.ParseImport('( Pawn: v1: "Tank": Class=1, Armor=2, Dps=1 )')
  assertNil(r); assertEqual(why, "noStats")
  r = S.ParseImport('(Pawn:v1:"Tight":Intellect=2,Stamina=garbage)')
  assertEqual(r.weights[INT], 2, "spacing is free; a pair without a number is ignored")
end)

test("verdict score: ImportInto replaces one spec's weights in a fresh map and keeps the others", function()
  local stored = { [71] = { [STR] = 9, [CRIT] = 9 }, [72] = { [HASTE] = 1 } }
  local out, r = S.ImportInto(stored, 71, PAWN)
  assertEqual(r.name, "Arms")
  assertEqual(out[71][STR], 1.5); assertNil(out[71].ITEM_MOD_VERSATILITY)
  assertEqual(out[72][HASTE], 1)
  assertTrue(out ~= stored and out[72] ~= stored[72], "a fresh table")
  assertEqual(stored[71][STR], 9, "the stored map is untouched")
  local none, why = S.ImportInto(stored, nil, PAWN)
  assertNil(none); assertEqual(why, "noSpec")
  none, why = S.ImportInto(stored, 71, "nope")
  assertNil(none); assertEqual(why, "format")
  assertEqual(S.ImportInto(nil, 73, PAWN)[73][STR], 1.5, "from no map")
  assertEqual(S.ImportInto({}, "HUNTER:3", '( Pawn: v1: "BM": Agility=2 )')["HUNTER:3"][AGI], 2, "into a tree")
end)

test("verdict score: a weights score is the sum of stat times weight; an unknown key counts 0, told", function()
  assertEqual(S.WeightsScore({ [STR] = 100, [CRIT] = 50, [HASTE] = 10 }, { [STR] = 2, [CRIT] = 0.5 }), 225)
  assertEqual(S.WeightsScore({}, { [STR] = 2 }), 0)
  assertNil(S.WeightsScore(nil, { [STR] = 2 })); assertNil(S.WeightsScore({ [STR] = 1 }, nil))
  assertNil(S.WeightsScore({ [STR] = 1 }, {}), "no weights is no score")
  local told = {}
  assertEqual(S.WeightsScore({ [STR] = 10, ITEM_MOD_MADE_UP = 99 }, { [STR] = 1, ITEM_MOD_MADE_UP = 5 },
    function(key) told[#told + 1] = key end), 10)
  assertEqual(told[1], "weight:ITEM_MOD_MADE_UP")
end)

test("verdict score: HasWeights, and Resolve picks the adapter for every config", function()
  assertFalse(S.HasWeights(nil)); assertFalse(S.HasWeights({})); assertFalse(S.HasWeights({ [62] = {} }))
  assertTrue(S.HasWeights({ [62] = { [INT] = 1 } }))
  local rows = {
    { "auto", true, true, "pawn" }, { "auto", false, true, "weights" }, { "auto", false, false, "none" },
    { "pawn", true, false, "pawn" }, { "pawn", false, true, "none" }, { "weights", true, true, "weights" },
    { "weights", true, false, "none" }, { "none", true, true, "none" }, { "bogus", false, true, "weights" },
    { nil, true, false, "pawn" },
  }
  for _, r in ipairs(rows) do
    assertEqual(S.Resolve(r[1], r[2], r[3]), r[4], tostring(r[1]) .. "/" .. tostring(r[2]) .. "/" .. tostring(r[3]))
  end
end)

test("verdict score: the weights are keyed by spec on Retail and by class and talent tree on Forever", function()
  local map = { ["HUNTER:1"] = { [AGI] = 1 }, ["HUNTER:2"] = { [AGI] = 3 }, [1485] = { [AGI] = 100 } }
  local forever = S.WeightsScorer(map, "forever")
  local drop = { stats = { [AGI] = 10 } }
  -- red under: a weights scorer that reads map[specID], the class-wide spec every tree shares
  assertEqual(forever(drop, { classFile = "HUNTER", specID = 1485, tree = 1 }, drop), 10)
  assertEqual(forever(drop, { classFile = "HUNTER", specID = 1485 }, drop), 30, "no tree: the best of the class's trees")
  assertNil(forever(drop, { classFile = "HUNTER", specID = 1485, tree = 3 }, drop), "a tree with no weights")
  local retail = S.WeightsScorer(map, "retail")
  assertEqual(retail(drop, { classFile = "HUNTER", specID = 1485 }, drop), 1000, "Retail reads map[specID]")
  assertEqual(S.WeightsScorer(map)(drop, { classFile = "HUNTER", specID = 1485 }, drop), 1000, "no client: Retail's")
end)

local function ring(ilvl, stats)
  return { itemID = 1, ilvl = ilvl, equipLoc = "INVTYPE_FINGER", classID = 4, subClassID = 0, stats = stats }
end

local function wearer(a, b) return { classFile = "MAGE", specID = 62, gear = { [11] = a, [12] = b } } end

test("verdict score: with weights, a higher item level that scores lower is a sidegrade", function()
  local scorer = S.WeightsScorer({ [62] = { [CRIT] = 1, [HASTE] = 0.5 } }, "retail")
  local who = wearer(ring(600, { [CRIT] = 100 }), ring(600, { [CRIT] = 100 }))
  local out = V.Evaluate(ring(610, { [HASTE] = 100 }), who, { scorer = scorer, client = "retail" })
  assertEqual(out.verdict, "sidegrade"); assertEqual(out.scoreDelta, -50)
  assertEqual(out.reasons[1].key, "scoreDisagrees")
  out = V.Evaluate(ring(610, { [CRIT] = 120 }), who, { scorer = scorer, client = "retail" })
  assertEqual(out.verdict, "upgrade", "both agree")
  out = V.Evaluate(ring(610, { [CRIT] = 120 }), wearer(ring(600, {}), ring(600, {})),
    { scorer = S.WeightsScorer({ [63] = { [CRIT] = 1 } }), client = "retail" })
  assertNil(out.scoreDelta, "another spec's weights do not score this one")
end)

-- ---------------------------------------------------------------------------------------------
-- The adapter in use, on an instance
-- ---------------------------------------------------------------------------------------------

test("verdict score: ScorerInUse and Scorer follow the host's config and whether Pawn is initialized", function()
  local W = FC.new{}
  local v = W.v
  assertEqual(v:ScorerInUse(), "none")
  assertNil(v:Scorer(), "no Pawn and no weights: item level alone")
  W.config = { weights = { [250] = { [INT] = 1 } } }
  assertEqual(v:ScorerInUse(), "weights")
  assertEqual(v:Scorer()({ stats = { [INT] = 7 } }, { specID = 250 }), 7)
  W.config = { scorer = "pawn", weights = W.config.weights }
  assertEqual(v:ScorerInUse(), "none", "pawn asked for, not initialized: item level alone")
  W.m.PawnIsReady = function() return true end
  assertEqual(v:ScorerInUse(), "pawn")
  W.config.scorer = "none"
  assertNil(v:Scorer())
  assertEqual(v:ScorerInUse({ scorer = "weights", weights = { [1] = { [INT] = 1 } } }), "weights", "a cfg handed in wins")
end)

-- ---------------------------------------------------------------------------------------------
-- The Pawn adapter (Retail)
-- ---------------------------------------------------------------------------------------------

local function retailPawn(values, upgrades)
  local W = FC.new{}
  local calls = {}
  FC.installPawn(W.m, { values = values, upgrades = upgrades })
  local real = W.m.PawnIsItemAnUpgrade
  W.m.PawnIsItemAnUpgrade = function(data)
    calls[#calls + 1] = "upgrade:" .. data.link
    return real(data)
  end
  return W, calls
end

test("verdict score: for you, Pawn values the drop and the baseline on the drop's best visible scale", function()
  local W, calls = retailPawn({ Tank = { drop = 50, worn = 40 }, Dps = { drop = 80, worn = 60 } },
    { drop = { { ScaleName = "Tank", PercentUpgrade = 0.05 }, { ScaleName = "Dps", PercentUpgrade = 0.2 } } })
  local score = W.v:PawnScorer()
  local drop, me = { link = "drop" }, { isPlayer = true, classFile = "MAGE", specID = 62 }
  assertEqual(score(drop, me, drop), 80)
  assertEqual(score({ link = "worn" }, me, drop), 60)
  assertEqual(#calls, 1, "the scale is read once per drop")
end)

test("verdict score: for you, a drop that upgrades no scale is valued on your spec's (or your shown) scale", function()
  local W = retailPawn({ ["S8:1"] = { drop = 10, worn = 12 }, Mine = { drop = 30, worn = 31 } }, { drop = {} })
  local drop, me = { link = "drop" }, { isPlayer = true, classFile = "MAGE", specID = 62 }
  assertEqual(W.v:PawnScorer()(drop, me, drop), 10)
  W.m.PawnCommon = { Scales = { ["S8:1"] = { ClassID = 8, SpecID = 1, Provider = "P", ProviderActive = true },
    Mine = {} } }
  W.m.PawnIsScaleVisible = function(name) return name == "Mine" end
  assertEqual(W.v:PawnScorer()(drop, me, drop), 30, "the scale you show in Pawn")
end)

test("verdict score: for a looter, Pawn uses their class and spec's scale; pending while not read", function()
  local W = retailPawn({ ["S1:1"] = { drop = 30, theirs = 25 } }, {})
  local score = W.v:PawnScorer()
  local drop = { link = "drop" }
  local brakk = { isPlayer = false, classFile = "WARRIOR", specID = 71 }
  assertEqual(score(drop, brakk, drop), 30)
  assertEqual(score({ link = "theirs" }, brakk, drop), 25)
  assertNil(score(drop, { classFile = "WARRIOR", specID = 999 }, drop), "a spec Pawn cannot be asked for")
  assertNil(score({}, brakk, drop), "no link: no score")
  assertEqual(score({ link = "uncached" }, brakk, drop), "pending", "a nil value is not ready")
  assertEqual(score(drop, { isPlayer = true, classFile = "MAGE", specID = 62 }, drop), "pending",
    "your drop's upgrade list not read yet")
  W.m.PawnIsReady = function() return nil end
  assertEqual(score(drop, brakk, drop), "pending")
end)

-- ---------------------------------------------------------------------------------------------
-- The Pawn adapter (WoW Forever: one scale per talent tree)
-- ---------------------------------------------------------------------------------------------

local function classicPawn(W, classes, values, upgrades, visible)
  local m, scales = W.m, {}
  for _, c in ipairs(classes) do
    for i = 1, c[3] do scales[c[1] .. i] = { ClassID = c[2], SpecID = i, Provider = "Classic", ProviderActive = true } end
  end
  m.PawnIsReady = function() return true end
  m.PawnCommon = { Scales = scales }
  m.PawnIsScaleVisible = function(name) return scales[name] ~= nil and (visible == nil or visible[name] == true) end
  m.PawnGetItemData = function(link) return { link = link } end
  m.PawnIsItemAnUpgrade = function(data) return (upgrades or {})[data.link] end
  m.PawnFindScaleForSpec = function(classID, specID)
    for name, s in pairs(scales) do
      if s.ClassID == classID and s.SpecID == specID and s.Provider then return name end
    end
  end
  m.PawnGetSingleValueFromItem = function(data, scale) return values[scale] and values[scale][data.link] end
  return scales
end

local HUNTER = { { "HUNTER", 3, 3 } }

test("verdict score: on Forever your score uses the scale of your top talent tree, else your custom one", function()
  local W = FC.new{ client = "forever" }
  local scales = classicPawn(W, HUNTER, {
    HUNTER1 = { drop = 10, worn = 8 }, HUNTER2 = { drop = 20, worn = 25 }, HUNTER3 = { drop = 90, worn = 10 },
  }, { drop = { { ScaleName = "HUNTER3", PercentUpgrade = 0.8 } } })
  W.config = { scorer = "pawn" }
  local drop, me = { link = "drop" }, { isPlayer = true, classFile = "HUNTER", specID = 1485, tree = 2 }
  local score = W.v:PawnScorer()
  -- red under: a scorer that takes the drop's best visible scale (the tree that gains most)
  assertEqual(score(drop, me, drop), 20)
  assertEqual(score({ link = "worn" }, me, drop), 25)
  local val, how = W.v:ScoreFor("drop", me)
  assertEqual(val, 20); assertEqual(how, "tree")
  scales.Mine = {}
  W.m.PawnGetSingleValueFromItem = function(data, scale) return scale == "Mine" and #data.link or nil end
  val, how = W.v:ScoreFor("drop", me)
  assertEqual(val, 4); assertEqual(how, "custom")
end)

test("verdict score: on Forever with no tree, and for another player, the best of the class's scales", function()
  local W = FC.new{ client = "forever" }
  classicPawn(W, HUNTER, {
    HUNTER1 = { drop = 10, worn = 8 }, HUNTER2 = { drop = 30, worn = 25 }, HUNTER3 = { drop = 20, worn = 1 },
  }, nil, {})
  W.config = { scorer = "pawn" }
  local drop = { link = "drop" }
  local me = { isPlayer = true, classFile = "HUNTER", specID = 1485 }
  assertEqual(W.v:PawnScorer()(drop, me, drop), 30)
  assertEqual(W.v:PawnScorer()({ link = "worn" }, me, drop), 25, "the baseline on the drop's scale")
  local them = { isPlayer = false, classFile = "HUNTER", specID = 1485 }
  local val, how = W.v:ScoreFor("drop", them)
  assertEqual(val, 30); assertEqual(how, "bestOfClass")
  assertNil(W.v:PawnScorer()(drop, { classFile = "ROGUE", specID = 1484 }, drop), "a class Pawn has no scale for")
  W.m.PawnGetItemData = function(link) if link ~= "drop" then return { link = link } end end
  assertEqual(W.v:PawnScorer()(drop, me, drop), "pending", "the drop not read by Pawn yet")
end)

test("verdict score: a Feral Druid tank uses Pawn 3, damage Pawn 2, by the host's role read", function()
  local role = "TANK"
  local W = FC.new{ client = "forever", host = { reads = { PlayerRole = function() return role end } } }
  classicPawn(W, { { "DRUID", 11, 4 } }, {
    DRUID1 = { drop = 1 }, DRUID2 = { drop = 2 }, DRUID3 = { drop = 3 }, DRUID4 = { drop = 4 },
  })
  local drop = { link = "drop" }
  local feral = { isPlayer = true, classFile = "DRUID", specID = 1447, tree = 2 }
  assertEqual(W.v:PawnScorer()(drop, feral, drop), 3)
  role = "DAMAGER"
  assertEqual(W.v:PawnScorer()(drop, feral, drop), 2)
  assertEqual(W.v:PawnScorer()(drop, { isPlayer = true, classFile = "DRUID", specID = 1447, tree = 3 }, drop), 4)
end)

test("verdict score: ScoreFor with your weights is how = custom, and none without a scorer", function()
  local W = FC.new{}
  local val, how = W.v:ScoreFor("x", { classFile = "MAGE", specID = 62 })
  assertNil(val); assertEqual(how, "none")
  local link = W.item(100, FC.def("INVTYPE_FINGER", 600, 4, 0, { stats = { [CRIT] = 10 } }))
  W.config = { weights = { [62] = { [CRIT] = 2 } } }
  val, how = W.v:ScoreFor(link, { classFile = "MAGE", specID = 62 })
  assertEqual(val, 20); assertEqual(how, "custom")
end)

-- ---------------------------------------------------------------------------------------------
-- Review focus 2: Pawn absent or not ready
-- ---------------------------------------------------------------------------------------------

local HEAD = 1
local function rogue(m)
  m.addItem(FC.link(3000), FC.def("INVTYPE_HEAD", 600, 4, 2, { stats = { [AGI] = 80 } }))
  m.inventory.player[HEAD] = FC.link(3000)
  m.addItem(FC.link(3001), FC.def("INVTYPE_HEAD", 610, 4, 2, { stats = { [AGI] = 50 } }))
end

test("verdict score: pawn not ready then ready -- pending, retried, judged again once Pawn answers", function()
  local pawn = { data = { [FC.link(3001)] = false }, values = {}, upgrades = {} }
  local W = FC.new{ seed = function(m)
    rogue(m)
    FC.installPawn(m, pawn)
  end }
  W.config = { scorer = "pawn" }
  local me, pending = W.v:Judge(FC.link(3001))
  assertEqual(me.verdict, "upgrade", "item level answers meanwhile")
  assertEqual(me.reasons[1].key, "scorePending")
  assertTrue(pending, "the judgment says it waits on its score")
  assertTrue(V.Gear.ScorePending(me))
  W.timers()
  assertEqual(W.count("score"), 0, "still not read: nothing to tell")
  -- Pawn reads the drop: its best scale values it below the worn helm.
  pawn.data[FC.link(3001)] = nil
  pawn.upgrades[FC.link(3001)] = { { ScaleName = "Dps", PercentUpgrade = 0.1 } }
  pawn.values.Dps = { [FC.link(3001)] = 90, [FC.link(3000)] = 100 }
  W.timers()
  -- red under: a judge that answered pending once and was never asked again
  assertEqual(W.count("score"), 1, "the retry found the answer and told the host")
  assertEqual(W.changes[#W.changes], "score:" .. FC.link(3001))
  me, pending = W.v:Judge(FC.link(3001))
  assertEqual(me.verdict, "sidegrade"); assertEqual(me.scoreDelta, -10); assertFalse(pending)
  assertEqual(W.timers(), 0, "nothing left to retry")
end)

test("verdict score: a score that never answers is retried SCORE_TRIES times, then given up", function()
  local W = FC.new{ seed = function(m)
    rogue(m)
    FC.installPawn(m, { data = { [FC.link(3001)] = false } })
  end }
  W.config = { scorer = "pawn" }
  local _, pending = W.v:Judge(FC.link(3001))
  assertTrue(pending)
  local passes = 0
  while W.timers() > 0 do passes = passes + 1 end
  assertEqual(passes, V.Gear.SCORE_TRIES)
  assertEqual(W.count("score"), 0)
end)

test("verdict score: Pawn absent, or loaded but not initialized, never errors and never waits", function()
  local W = FC.new{ seed = rogue }
  W.config = { scorer = "pawn" }
  local me, pending = W.v:Judge(FC.link(3001))
  assertEqual(me.verdict, "upgrade"); assertFalse(pending)
  assertEqual(#me.reasons, 0, "no Pawn: item level alone")
  W.m.PawnIsReady = function() return false end
  W.m.PawnGetItemData = function() error("Pawn's own bug") end
  me, pending = W.v:Judge(FC.link(3001))
  assertEqual(me.verdict, "upgrade"); assertFalse(pending)
  W.m.PawnIsReady = function() return true end
  me = W.v:Judge(FC.link(3001))
  assertEqual(me.verdict, "upgrade", "a Pawn that raises is no score, never an error")
end)

test("verdict score: a stand-down drops the score retry; no onChange until the stand-up", function()
  local pawn = { data = { [FC.link(3001)] = false } }
  local W = FC.new{ seed = function(m)
    rogue(m)
    FC.installPawn(m, pawn)
  end }
  W.config = { scorer = "pawn" }
  W.v:Judge(FC.link(3001))
  W.v:StandDown()
  pawn.data[FC.link(3001)] = nil
  assertEqual(W.timers(), 0, "the retry was canceled")
  assertEqual(W.count("score"), 0)
end)
