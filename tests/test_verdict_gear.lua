-- tests/test_verdict_gear.lua -- LibKa0s-Verdict-1.0's gear snapshot (VerdictGear.lua), per
-- instance: each worn slot at its current level, the best owned item per slot with the bags
-- included, the candidate the kernel takes for you, off-spec gear, the throttled rebuild on the
-- gear events, onChange("gear"), items still loading, the host's bag defer and the lifecycle. Ka0s
-- Drop Watcher's tests/test_gear.lua, ported to the instance (its Qualities case stays there with
-- Qualities), plus the review focus of its Item Search split plan, test 5: a stand-down while gear
-- events fire cancels the pending refresh, and no onChange fires until the stand-up.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local FC = dofile("tests/fixture_verdict_client.lua")

local SLOT = { HEAD = 1, NECK = 2, CHEST = 5, FINGER1 = 11, FINGER2 = 12, MAINHAND = 16, OFFHAND = 17 }
local RANGED = 18
local link, def = FC.link, FC.def

local function leather(equipLoc, ilvl, extra) return def(equipLoc, ilvl, 4, 2, extra) end
local function plate(equipLoc, ilvl) return def(equipLoc, ilvl, 4, 4) end
local function ring(ilvl, extra) return def("INVTYPE_FINGER", ilvl, 4, 0, extra) end
local function dagger(ilvl) return def("INVTYPE_WEAPON", ilvl, 2, 15) end

-- An Outlaw rogue (a dual wielder in leather) unless the seed says otherwise; Retail unless named.
local function world(seed, client)
  return FC.new{ client = client, seed = seed }
end

local function hunterTrees(bm, mm, sv)
  return { { name = "Beast Mastery", spent = bm }, { name = "Marksmanship", spent = mm },
    { name = "Survival", spent = sv } }
end

-- ---------------------------------------------------------------------------------------------
-- The snapshot
-- ---------------------------------------------------------------------------------------------

test("verdict gear: each worn slot is a copy of its facts at the current level; an empty slot is false", function()
  local W = world(function(m)
    m.addItem(link(3001), leather("INVTYPE_HEAD", 600, { effectiveIlvl = 610 }))
    m.inventory.player[SLOT.HEAD] = link(3001)
    m.addItem(link(3002), leather("INVTYPE_CHEST", 620))
    m.inventory.player[SLOT.CHEST] = link(3002)
    m.tooltips.inventory["player:" .. SLOT.CHEST] = { lines = { { type = 41, leftText = "Item Level 590" } } }
  end)
  local s = W.v:Snapshot()
  assertEqual(s.equipped[SLOT.HEAD].ilvl, 610, "the link's effective level with no tooltip line")
  assertEqual(s.equipped[SLOT.HEAD].slot, SLOT.HEAD)
  assertEqual(s.equipped[SLOT.CHEST].ilvl, 590, "the tooltip's current level wins")
  assertEqual(W.v:Facts(link(3002)).ilvl, 620, "the cached facts are not written")
  assertEqual(s.equipped[SLOT.NECK], false, "an empty slot")
  assertEqual(s.loading, 0)
end)

test("verdict gear: Retail's candidate carries its spec and no tree; the hand flags are the spec's", function()
  local W = world()
  local c = W.v:Candidate()
  assertNil(c.tree); assertEqual(c.level, 80)
  assertEqual(c.classFile, "ROGUE"); assertEqual(c.specID, 260)
  assertTrue(c.dualWield); assertFalse(c.titanGrip); assertTrue(c.isPlayer)
  assertTrue(c.gear == W.v:Snapshot().equipped); assertTrue(c.owned == W.v:Snapshot().owned)
  assertNil(c.prefs, "the judge adds the preferences")
  assertEqual(type(c.offSpecGear), "function", "Retail's off-spec gear")
  W.m.__context.class, W.m.__context.classToken = "Warrior", "WARRIOR"
  W.m.specID = 72
  W.v:RefreshGear("test")
  c = W.v:Candidate()
  assertTrue(c.dualWield); assertTrue(c.titanGrip, "Fury")
end)

test("verdict gear: WoW Forever's candidate carries the class-wide spec, your talent tree and your level", function()
  local W = world(function(m)
    m.__context.class, m.__context.classToken, m.__context.level = "Hunter", "HUNTER", 30
    m.seedTalents(1485, hunterTrees(10, 3, 0))
  end, "forever")
  local c = W.v:Candidate()
  assertEqual(c.classFile, "HUNTER"); assertEqual(c.specID, 1485, "the class-wide spec")
  assertEqual(c.tree, 1, "Beast Mastery, the most points"); assertEqual(c.level, 30)
  assertTrue(c.dualWield, "a Forever hunter dual wields"); assertFalse(c.titanGrip)
  assertNil(c.offSpecGear, "no off-spec on WoW Forever")
  W.m.talents[2].spent = 10
  W.v:RefreshGear("test")
  assertNil(W.v:Candidate().tree, "a tie names no tree")
end)

-- ---------------------------------------------------------------------------------------------
-- The best owned per slot
-- ---------------------------------------------------------------------------------------------

test("verdict gear: a better bag item you can wear is owned for its slot; one you cannot is not", function()
  local W = world()
  W.wear(SLOT.HEAD, 3001, leather("INVTYPE_HEAD", 600))
  W.carry(0, 1, 3010, leather("INVTYPE_HEAD", 630))
  W.carry(0, 2, 3011, plate("INVTYPE_CHEST", 700))
  W.carry(1, 4, 3012, def("", 700, 15, 0))
  local s = W.v:Snapshot()
  assertEqual(s.owned[SLOT.HEAD].ilvl, 630)
  assertEqual(s.owned[SLOT.HEAD].bag, 0); assertEqual(s.owned[SLOT.HEAD].bagSlot, 1)
  assertNil(s.owned[SLOT.CHEST], "plate is not a rogue's")
end)

test("verdict gear: a pair gets your best two rings; a dual wielder's one-handers fill both hands", function()
  local W = world()
  W.wear(SLOT.FINGER1, 3001, ring(610))
  W.wear(SLOT.FINGER2, 3002, ring(600))
  W.carry(0, 1, 3010, ring(620))
  W.wear(SLOT.MAINHAND, 3003, dagger(600))
  W.wear(SLOT.OFFHAND, 3004, dagger(590))
  W.carry(0, 2, 3011, dagger(630))
  local s = W.v:Snapshot()
  assertEqual(s.owned[SLOT.FINGER1].ilvl, 620)
  assertEqual(s.owned[SLOT.FINGER2].ilvl, 610, "the worn 610 moves to the second finger")
  assertEqual(s.owned[SLOT.MAINHAND].ilvl, 630)
  assertEqual(s.owned[SLOT.OFFHAND].ilvl, 600)
end)

test("verdict gear: Titan's Grip puts a second two-hander in the off hand on Retail alone", function()
  local seed = function(m)
    m.__context.class, m.__context.classToken = "Warrior", "WARRIOR"
    m.specID = 72
  end
  local W = world(seed)
  W.carry(0, 1, 3010, def("INVTYPE_2HWEAPON", 640, 2, 8))
  W.carry(0, 2, 3011, def("INVTYPE_2HWEAPON", 630, 2, 1))
  assertEqual(W.v:Snapshot().owned[SLOT.OFFHAND].ilvl, 630)
  local F = world(function(m)
    seed(m)
    m.__context.level = 60
    m.seedTalents(1491, { { name = "Arms", spent = 5 }, { name = "Fury", spent = 31 }, { name = "Protection", spent = 0 } })
  end, "forever")
  F.carry(0, 1, 3010, def("INVTYPE_2HWEAPON", 64, 2, 8))
  F.carry(0, 2, 3011, def("INVTYPE_2HWEAPON", 63, 2, 1))
  assertEqual(F.v:Snapshot().owned[SLOT.MAINHAND].ilvl, 64)
  assertNil(F.v:Snapshot().owned[SLOT.OFFHAND], "no Titan's Grip on Forever")
end)

test("verdict gear: a bag item with no slot plan is never asked of the item facts", function()
  local W = world()
  W.carry(0, 1, 3201, def("", 1, 7, 0, { name = "Reagent", loadsNeeded = 1 }))
  W.carry(0, 2, 3202, leather("INVTYPE_HEAD", 640))
  W.v:Snapshot()
  assertEqual((W.v:FactsCounts()), 1, "the helm alone")
  assertEqual(#W.m.loadRequests, 0, "no load asked for the reagent")
end)

test("verdict gear: on Forever a bow compares against slot 18, on Retail against the hands", function()
  local function seed(m)
    m.__context.class, m.__context.classToken, m.__context.level = "Hunter", "HUNTER", 60
    m.specID = 254
    m.addItem(link(3001), def("INVTYPE_2HWEAPON", 600, 2, 6))
    m.inventory.player[SLOT.MAINHAND] = link(3001)
    m.addItem(link(3002), def("INVTYPE_RANGED", 610, 2, 2))
    m.inventory.player[RANGED] = link(3002)
    m.addItem(link(3020), def("INVTYPE_RANGED", 620, 2, 2))
  end
  local W = world(seed)
  local r = W.V.Evaluate(W.v:Facts(link(3020)), W.v:Candidate(), { client = "retail" })
  assertNil(W.v:Snapshot().equipped[RANGED], "slot 18 is never read on Retail")
  assertEqual(r.baselineSlot, SLOT.MAINHAND); assertEqual(r.ilvlDelta, 20)
  local F = world(function(m)
    seed(m)
    m.seedTalents(1485, hunterTrees(0, 31, 5))
  end, "forever")
  r = F.V.Evaluate(F.v:Facts(link(3020)), F.v:Candidate(), { client = "forever" })
  assertEqual(F.v:Snapshot().equipped[RANGED].ilvl, 610, "the snapshot reads the ranged slot")
  assertEqual(r.baselineSlot, RANGED); assertEqual(r.ilvlDelta, 10)
end)

-- ---------------------------------------------------------------------------------------------
-- Off-spec gear (Retail)
-- ---------------------------------------------------------------------------------------------

local INT, STR = "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_STRENGTH_SHORT"
local function mace(ilvl) return def("INVTYPE_WEAPON", ilvl, 2, 4, { stats = { [INT] = 90 } }) end
local function sword(ilvl) return def("INVTYPE_WEAPON", ilvl, 2, 7, { stats = { [STR] = 90 } }) end

local function protPaladin(m)
  m.__context.class, m.__context.classToken = "Paladin", "PALADIN"
  m.specID = 66
  m.addItem(link(3001), sword(620)); m.inventory.player[SLOT.MAINHAND] = link(3001)
  m.addItem(link(3002), plate("INVTYPE_HEAD", 610)); m.inventory.player[SLOT.HEAD] = link(3002)
end

test("verdict gear: OffSpecGear is the best item per slot that spec could wear, memoized per snapshot", function()
  local W = world(protPaladin)
  W.carry(0, 1, 3010, mace(600))
  W.carry(0, 2, 3012, mace(590))
  local holy = W.v:OffSpecGear(65)
  assertEqual(holy[SLOT.MAINHAND].link, link(3010), "the bag mace, not the worn sword")
  assertEqual(holy[SLOT.HEAD].link, link(3002), "the worn helm suits Holy too")
  assertEqual(holy[SLOT.NECK], false); assertEqual(holy[SLOT.OFFHAND], false, "Holy does not dual wield")
  assertTrue(W.v:OffSpecGear(65) == holy, "memoized on the snapshot")
  W.v:RefreshGear("test")
  assertTrue(W.v:OffSpecGear(65) ~= holy, "a rebuild drops the memo")
  assertNil(W.v:OffSpecGear("x")); assertNil(W.v:OffSpecGear(71), "a spec of another class")
end)

test("verdict gear: the candidate's off-spec gear lets the kernel judge Holy against the bag mace", function()
  local W = world(protPaladin)
  W.carry(0, 1, 3010, mace(600))
  local drop = W.v:Facts(W.item(3020, def("INVTYPE_WEAPON", 650, 2, 0, { stats = { [INT] = 100 } })))
  local r = W.V.Evaluate(drop, W.v:Candidate(), { client = "retail" })
  assertEqual(r.verdict, "cantUse")
  assertEqual(r.offSpec.specID, 65); assertEqual(r.offSpec.verdict, "upgrade")
  assertEqual(r.offSpec.ilvlDelta, 50); assertEqual(r.offSpec.baseline.link, link(3010))
end)

test("verdict gear: a bag item still loading leaves no off-spec gear; its arrival re-announces", function()
  local W = world(protPaladin)
  W.carry(0, 1, 3010, mace(600))
  W.m.items[link(3010)].loadsNeeded = 1
  assertNil(W.v:OffSpecGear(65), "nil while an item loads")
  W.timers(); W.timers()
  assertEqual(W.count("gear"), 1, "its arrival re-judges")
  assertEqual(W.v:OffSpecGear(65)[SLOT.MAINHAND].link, link(3010))
end)

-- ---------------------------------------------------------------------------------------------
-- The events, the throttle and onChange("gear")
-- ---------------------------------------------------------------------------------------------

test("verdict gear: the gear events share one throttled rebuild, which announces a change once", function()
  local W = world()
  W.v:StandUp()
  W.changes = {}
  W.wear(SLOT.HEAD, 3001, leather("INVTYPE_HEAD", 600))
  W.fire("PLAYER_EQUIPMENT_CHANGED", SLOT.HEAD, true)
  W.fire("BAG_UPDATE_DELAYED")
  W.fire("PLAYER_EQUIPMENT_CHANGED", SLOT.HEAD, false)
  assertTrue(W.v:GearScheduled())
  assertEqual(W.count("gear"), 0, "nothing before the timer")
  assertEqual(W.v:Snapshot().equipped[SLOT.HEAD], false, "the stored snapshot until then")
  assertEqual(W.timers(), 1, "one rebuild")
  assertEqual(W.count("gear"), 1)
  assertEqual(W.v:Snapshot().equipped[SLOT.HEAD].ilvl, 600)
  W.fire("BAG_UPDATE_DELAYED")
  W.timers()
  assertEqual(W.count("gear"), 1, "a rebuild that changed nothing is silent")
end)

test("verdict gear: sorting your bags moves no gear, so it announces nothing", function()
  local W = world(protPaladin)
  W.carry(0, 1, 3010, mace(600))
  W.carry(0, 2, 3012, mace(590))
  W.v:StandUp()
  W.changes = {}
  W.m.bags[0][1], W.m.bags[0][2] = W.m.bags[0][2], W.m.bags[0][1]
  W.fire("BAG_UPDATE_DELAYED")
  W.timers()
  assertEqual(W.count("gear"), 0)
end)

test("verdict gear: the host's deferWhile holds a bag event until PLAYER_REGEN_ENABLED", function()
  local held = true
  local W = FC.new{ host = { deferWhile = function() return held end } }
  W.wear(SLOT.HEAD, 3001, leather("INVTYPE_HEAD", 600))
  W.v:StandUp()
  W.fire("BAG_UPDATE_DELAYED")
  assertFalse(W.v:GearScheduled(), "held while the host says so")
  W.carry(0, 1, 3101, leather("INVTYPE_HEAD", 640))
  held = false
  W.fire("PLAYER_REGEN_ENABLED")
  assertTrue(W.v:GearScheduled(), "the edge arms the rebuild")
  W.timers()
  assertEqual(W.v:Snapshot().owned[SLOT.HEAD].link, link(3101))
  W.fire("PLAYER_REGEN_ENABLED")
  assertFalse(W.v:GearScheduled(), "an edge with nothing held rebuilds nothing")
  held = true
  W.fire("PLAYER_EQUIPMENT_CHANGED", SLOT.MAINHAND, false)
  assertTrue(W.v:GearScheduled(), "an equipment change is never held")
  local bare = FC.new{}
  bare.v:StandUp()
  bare.fire("BAG_UPDATE_DELAYED")
  assertTrue(bare.v:GearScheduled(), "no predicate: nothing is held")
end)

test("verdict gear: a bag-only rebuild keeps the worn slots as read; an equipment change reads them again", function()
  local W = world()
  W.wear(SLOT.HEAD, 3001, leather("INVTYPE_HEAD", 600))
  W.wear(SLOT.CHEST, 3002, leather("INVTYPE_CHEST", 620))
  W.v:StandUp()
  local reads, real = 0, W.m.C_TooltipInfo.GetInventoryItem
  W.m.C_TooltipInfo.GetInventoryItem = function(...) reads = reads + 1; return real(...) end
  W.carry(0, 1, 3101, leather("INVTYPE_HEAD", 640))
  W.fire("BAG_UPDATE_DELAYED")
  W.timers()
  assertEqual(reads, 0, "no worn tooltip read for a bag change")
  assertEqual(W.v:Snapshot().owned[SLOT.HEAD].link, link(3101))
  W.wear(SLOT.HEAD, 3003, leather("INVTYPE_HEAD", 650))
  W.fire("BAG_UPDATE_DELAYED")
  W.fire("PLAYER_EQUIPMENT_CHANGED", SLOT.HEAD, true)
  W.timers()
  assertTrue(reads > 0, "an equipment change sharing the rebuild reads every slot")
  assertEqual(W.v:Snapshot().equipped[SLOT.HEAD].link, link(3003))
end)

test("verdict gear: Retail rebuilds on your spec change alone; Forever on talents and levels", function()
  local W = world()
  W.v:StandUp()
  W.changes = {}
  W.fire("PLAYER_SPECIALIZATION_CHANGED", "party1")
  assertFalse(W.v:GearScheduled(), "another unit's spec")
  W.m.specID = 261
  W.fire("PLAYER_SPECIALIZATION_CHANGED", "player")
  W.timers()
  assertEqual(W.count("gear"), 1)
  assertEqual(W.v:Candidate().specID, 261)
  local F = world(function(m)
    m.__context.class, m.__context.classToken, m.__context.level = "Hunter", "HUNTER", 39
    m.seedTalents(1485, hunterTrees(10, 3, 0))
  end, "forever")
  F.v:StandUp()
  F.changes = {}
  F.m.talents[2].spent = 31
  F.fire("TRAIT_CONFIG_UPDATED", 7001)
  F.timers()
  assertEqual(F.v:Candidate().tree, 2, "Marksmanship now")
  F.m.__context.level = 40
  F.fire("PLAYER_LEVEL_UP", 40)
  assertTrue(F.v:GearScheduled())
  F.timers()
  assertEqual(F.v:Candidate().level, 40)
  assertEqual(F.count("gear"), 2)
end)

test("verdict gear: the first lazy read announces nothing; an item still loading is unknown, then rebuilt", function()
  local W = world()
  W.wear(SLOT.HEAD, 3001, leather("INVTYPE_HEAD", 600, { loadsNeeded = 1 }))
  local s = W.v:Snapshot()
  assertEqual(#W.changes, 0, "the lazy read is quiet")
  assertNil(s.equipped[SLOT.HEAD], "unknown, not empty")
  assertEqual(s.loading, 1)
  W.timers()   -- the load answers, and arms the rebuild
  assertTrue(W.v:GearScheduled())
  W.timers()
  assertEqual(W.count("gear"), 1)
  assertEqual(W.v:Snapshot().equipped[SLOT.HEAD].ilvl, 600)
end)

-- ---------------------------------------------------------------------------------------------
-- The lifecycle (review focus 5)
-- ---------------------------------------------------------------------------------------------

test("verdict gear: stand-down drops pending refresh, and nothing fires until the stand-up", function()
  local W = world()
  W.wear(SLOT.HEAD, 3001, leather("INVTYPE_HEAD", 600))
  W.v:StandUp()
  W.changes = {}
  W.wear(SLOT.HEAD, 3002, leather("INVTYPE_HEAD", 620))
  W.fire("PLAYER_EQUIPMENT_CHANGED", SLOT.HEAD, true)
  assertTrue(W.v:GearScheduled())
  W.v:StandDown()
  -- red under: a stand-down that left the armed timer to run its rebuild and announce it
  assertFalse(W.v:GearScheduled(), "the pending refresh is canceled")
  assertEqual(W.timers(), 0, "the canceled rebuild never runs")
  assertNil(W.v.__gear, "the snapshot is dropped")
  W.v:ScheduleGear("late")
  W.fire("BAG_UPDATE_DELAYED")
  assertFalse(W.v:GearScheduled(), "nothing arms while stood down")
  W.v:Changed("gear")
  assertEqual(#W.changes, 0, "no onChange while stood down")
  W.v:StandUp()
  assertEqual(W.count("gear"), 1, "the stand-up rebuilds and announces")
  assertEqual(W.v:Snapshot().equipped[SLOT.HEAD].ilvl, 620)
end)
