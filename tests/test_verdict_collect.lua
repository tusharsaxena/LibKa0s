-- tests/test_verdict_collect.lua -- LibKa0s-Verdict-1.0's category and collection verdict
-- (VerdictCollect.lua): CategoryOf for each category, its precedence and the classes it does not
-- watch; Verdict's new, collected, unknown, pet partial, recipe without the profession, kind word
-- and whitelisted answers; Read, the edge that asks an instance's reads for the probes and the
-- collection state; and the instance's coalesced re-read on a collection event. Ka0s Drop
-- Watcher's tests/test_collectibles.lua, ported to lib.Collect and the instance.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local FC = dofile("tests/fixture_verdict_client.lua")

local c = T.mocks.LibStub("LibKa0s-Verdict-1.0").Collect

local ARMOR, WEAPON, RECIPE, MISC, CONSUMABLE, REAGENT_CLASS, CONTAINER, QUIVER = 4, 2, 9, 15, 0, 7, 1, 11
local COSMETIC_SUB, MOUNT_SUB, PET_SUB, JUNK_SUB = 5, 5, 2, 0
local TAILORING_SUB, BOOK_SUB = 2, 0

local function keys(eval)
  local out = {}
  for i, r in ipairs(eval.reasons) do out[i] = r.key end
  return table.concat(out, ",")
end

-- ---------------------------------------------------------------------------------------------
-- CategoryOf
-- ---------------------------------------------------------------------------------------------

test("verdict collect: CategoryOf names each category", function()
  assertEqual(c.CategoryOf({ classID = ARMOR, subClassID = 4 }), "equipment")
  assertEqual(c.CategoryOf({ classID = WEAPON, subClassID = 7 }), "equipment")
  assertEqual(c.CategoryOf({ classID = MISC, subClassID = JUNK_SUB, isTierToken = true }), "tierToken")
  assertEqual(c.CategoryOf({ classID = MISC, subClassID = 4 }, { mountID = 9 }), "mount", "the journal")
  assertEqual(c.CategoryOf({ classID = MISC, subClassID = MOUNT_SUB }), "mount", "the class rung")
  assertEqual(c.CategoryOf({ classID = MISC, subClassID = 4 }, { speciesID = 3 }), "pet")
  assertEqual(c.CategoryOf({ classID = MISC, subClassID = PET_SUB }), "pet")
  assertEqual(c.CategoryOf({ classID = MISC, subClassID = 4 }, { toy = true }), "toy")
  assertEqual(c.CategoryOf({ classID = RECIPE, subClassID = TAILORING_SUB }), "recipe")
  assertEqual(c.CategoryOf({ classID = ARMOR, subClassID = COSMETIC_SUB }), "cosmetic")
end)

test("verdict collect: CategoryOf's precedence", function()
  assertEqual(c.CategoryOf({ classID = ARMOR, subClassID = 4, isTierToken = true }), "tierToken")
  assertEqual(c.CategoryOf({ classID = WEAPON, subClassID = 7 }, { cosmetic = true }), "cosmetic")
  assertEqual(c.CategoryOf({ classID = ARMOR, subClassID = COSMETIC_SUB }, { toy = true }), "toy")
  assertEqual(c.CategoryOf({ classID = WEAPON, subClassID = 7 }, { cosmetic = true, mountID = 4 }), "mount")
  assertEqual(c.CategoryOf({ classID = MISC, subClassID = MOUNT_SUB }, { speciesID = 3 }), "mount")
  assertEqual(c.CategoryOf({ classID = RECIPE, subClassID = 1 }, { toy = true }), "toy")
  assertNil(c.CategoryOf({ classID = MISC, subClassID = 4 }, { cosmetic = true }), "the flag counts on gear only")
end)

test("verdict collect: the out-of-scope classes are not watched; kinds and IsCollectible", function()
  for _, f in ipairs({ { classID = CONSUMABLE, subClassID = 0 }, { classID = MISC, subClassID = JUNK_SUB },
    { classID = MISC, subClassID = 6 }, { classID = 13, subClassID = 0 }, {} }) do
    assertNil(c.CategoryOf(f), "class " .. tostring(f.classID))
  end
  assertNil(c.CategoryOf(nil)); assertNil(c.CategoryOf("x"))
  local junk = { classID = MISC, subClassID = JUNK_SUB, quality = 2 }
  assertEqual(c.CategoryOf(junk, { opens = "locked" }), "lockbox")
  assertEqual(c.CategoryOf(junk, { opens = "opens" }), "lockbox")
  assertEqual(c.CategoryOf({ classID = CONTAINER, subClassID = 0 }), "container")
  assertEqual(c.CategoryOf({ classID = QUIVER, subClassID = 2 }), "container")
  assertEqual(c.CategoryOf({ classID = REAGENT_CLASS, subClassID = 11 }), "reagent")
  for _, key in ipairs({ "mount", "pet", "toy", "recipe", "cosmetic" }) do assertTrue(c.IsCollectible({ category = key }), key) end
  for _, key in ipairs({ "equipment", "tierToken", "lockbox", "container", "reagent", "other" }) do
    assertFalse(c.IsCollectible({ category = key }), key)
  end
  assertFalse(c.IsCollectible(nil))
end)

-- ---------------------------------------------------------------------------------------------
-- Verdict
-- ---------------------------------------------------------------------------------------------

test("verdict collect: Verdict reads new, collected and no answer; a pet's partial count", function()
  local v = c.Verdict({ category = "mount", collect = { kind = "mount", known = false } })
  assertEqual(v.verdict, "newCollect"); assertEqual(keys(v), "collectNew")
  assertEqual(v.equip, "collect"); assertTrue(v.collect); assertEqual(v.category, "mount")
  assertEqual(c.Verdict({ category = "toy", collect = { known = true } }).verdict, "collected")
  assertEqual(c.Verdict({ category = "mount", collect = {} }).verdict, "collectUnknown")
  assertEqual(c.Verdict({ category = "recipe" }).verdict, "collectUnknown", "no collect table at all")
  v = c.Verdict({ category = "pet", collect = { known = true, count = 1, limit = 3 } })
  assertEqual(keys(v), "collectKnown,petPartial"); assertEqual(v.reasons[2].detail, "1/3")
  assertEqual(keys(c.Verdict({ category = "pet", collect = { known = true, count = 3, limit = 3 } })), "collectKnown")
end)

test("verdict collect: a recipe for a profession you lack is cantUse; a cosmetic reads transmogKnown", function()
  assertEqual(c.Verdict({ category = "recipe", collect = { known = false, hasProfession = false } }).verdict, "cantUse")
  assertEqual(c.Verdict({ category = "recipe", collect = { known = false, hasProfession = true } }).verdict, "newCollect")
  local f = { category = "cosmetic", collect = { kind = "cosmetic", known = false }, transmogKnown = true }
  assertEqual(c.Verdict(f).verdict, "collected", "the live flag, not the copy")
  f.transmogKnown = nil
  assertEqual(c.Verdict(f).verdict, "collectUnknown")
end)

test("verdict collect: a kind's word, no gain; whitelisted; gear and a token answer nil", function()
  local v = c.Verdict({ category = "lockbox", classID = MISC, subClassID = JUNK_SUB })
  assertEqual(v.verdict, "lockbox"); assertNil(v.ilvlDelta)
  assertEqual(c.Verdict({ category = "container", classID = QUIVER }).verdict, "container")
  assertEqual(c.Verdict({ category = "reagent", classID = REAGENT_CLASS }).verdict, "reagent")
  v = c.Verdict({ classID = REAGENT_CLASS, subClassID = 1 })
  assertEqual(v.verdict, "item"); assertEqual(v.category, "other")
  v = c.Verdict({ category = "toy", collect = { known = false } }, true)
  assertEqual(keys(v), "collectNew,whitelisted")
  assertEqual(c.Verdict({ classID = REAGENT_CLASS, subClassID = 1 }, true).verdict, "item", "never Unknown")
  assertEqual(c.Verdict({ itemID = 7 }, true).verdict, "unknown", "its class not read yet")
  assertNil(c.Verdict({ category = "equipment" })); assertNil(c.Verdict({ category = "tierToken" }, false))
  assertNil(c.Verdict(nil))
end)

test("verdict collect: an item of no category reads as gear by the client's slot plans", function()
  local relic = { classID = 15, subClassID = 4, equipLoc = "INVTYPE_RELIC" }
  -- red under: one slot plan for every caller, so a Forever relic read as an item of no kind
  assertNil(c.Verdict(relic, false, "forever"), "a relic is gear on WoW Forever")
  assertEqual(c.Verdict(relic, false, "retail").verdict, "item", "Retail has no relic slot")
  assertEqual(c.Verdict(relic, true, "forever").verdict, "unknown", "forced gear with no category")
  assertNil(c.Verdict(relic, false), "no client: either client's plans")
end)

-- ---------------------------------------------------------------------------------------------
-- Read, through an instance's facts
-- ---------------------------------------------------------------------------------------------

local MOUNT  = "|cnIQ4:|Hitem:6001::::::::90:::::|h[Reins]|h|r"
local PET    = "|cnIQ3:|Hitem:6002::::::::90:::::|h[Cage]|h|r"
local TOY    = "|cnIQ3:|Hitem:6003::::::::90:::::|h[Toy]|h|r"
local PATTERN = "|cnIQ3:|Hitem:6004::::::::90:::::|h[Pattern]|h|r"
local LOOK   = "|cnIQ4:|Hitem:6005::::::::90:::::|h[Fancy Hat]|h|r"
local HELM   = "|cnIQ4:|Hitem:6006::::::::90:::::|h[Helm]|h|r"
local POTION = "|cnIQ1:|Hitem:6007::::::::90:::::|h[Potion]|h|r"

local function item(classID, subClassID, extra)
  local def = { name = "x", quality = 3, ilvl = 100, equipLoc = "", classID = classID, subClassID = subClassID,
    bindType = 1 }
  for k, v in pairs(extra or {}) do def[k] = v end
  return def
end

test("verdict collect: Read fills a mount's, a pet's and a toy's collection state", function()
  local W = FC.new{ seed = function(m)
    m.addItem(MOUNT, item(MISC, MOUNT_SUB)); m.mounts.byItem[6001] = 77; m.mounts.collected[77] = false
    m.addItem(PET, item(MISC, PET_SUB)); m.pets.byItem[6002] = 12; m.pets.counts[12] = { 1, 3 }
    m.addItem(TOY, item(CONSUMABLE, 8)); m.toys[6003] = true; m.toysOwned[6003] = true
  end }
  local f = W.v:Facts(MOUNT)
  assertEqual(f.category, "mount"); assertEqual(f.collect.mountID, 77); assertFalse(f.collect.known)
  f = W.v:Facts(PET)
  assertEqual(f.collect.speciesID, 12); assertEqual(f.collect.count, 1); assertTrue(f.collect.known)
  assertTrue(W.v:Facts(TOY).collect.known)
  assertEqual(W.v:JudgeFacts(W.v:Facts(MOUNT)).verdict, "newCollect", "the judge takes the collection path")
end)

test("verdict collect: Read fills a recipe's profession and known line", function()
  local W = FC.new{ seed = function(m)
    m.addItem(PATTERN, item(RECIPE, TAILORING_SUB))
    m.tooltips.hyperlink[PATTERN] = { lines = { { type = 0, leftText = "Already known" } } }
    m.professions = { 165, 171 }
  end }
  local f = W.v:Facts(PATTERN)
  assertEqual(f.collect.skillLine, 197); assertFalse(f.collect.hasProfession); assertTrue(f.collect.known)
  assertEqual(c.Verdict(f).verdict, "cantUse")
  W.m.professions = {}
  assertFalse(W.v:ReadFacts(PATTERN).collect.hasProfession, "no profession at all: not yours")
  W.m.GetProfessions = nil
  assertNil(W.v:ReadFacts(PATTERN).collect.hasProfession, "no answer: not claimed")
  W.m.items[PATTERN].subClassID = BOOK_SUB
  assertNil(W.v:ReadFacts(PATTERN).collect.skillLine, "a book needs no profession")
end)

test("verdict collect: Read tells a lockbox from Junk that does not open; a reagent's tooltip is never read", function()
  local BOX, ALTAR = "|cnIQ2:|Hitem:4632::::::::20:::::|h[Lockbox]|h|r", "|cnIQ4:|Hitem:6011::::::::90:::::|h[Altar]|h|r"
  local CLOTH = "|cnIQ2:|Hitem:6012::::::::20:::::|h[Cloth]|h|r"
  local W = FC.new{ seed = function(m)
    m.addItem(BOX, item(MISC, JUNK_SUB, { quality = 2 }))
    m.addItem(ALTAR, item(MISC, JUNK_SUB, { quality = 4 }))
    m.addItem(CLOTH, item(REAGENT_CLASS, 5, { quality = 2 }))
    m.tooltips.hyperlink[BOX] = { lines = { { type = 0, leftText = "Locked" } } }
    m.tooltips.hyperlink[ALTAR] = { lines = { { type = 0, leftText = "Altar" } } }
    m.tooltips.hyperlink[CLOTH] = { lines = { { type = 0, leftText = "Locked" } } }
  end }
  assertEqual(W.v:Facts(BOX).category, "lockbox")
  assertNil(W.v:Facts(ALTAR).category)
  assertEqual(W.v:Facts(CLOTH).category, "reagent")
  W.m.LOCKED, W.m.ITEM_OPENABLE = nil, nil
  assertNil(W.v:ReadFacts(BOX).category, "no GlobalString: not read, no kind claimed")
end)

test("verdict collect: Read spends the probes only where they decide; a tier token probes nothing", function()
  local calls, asked = {}, 0
  local W = FC.new{ seed = function(m)
    m.addItem(LOOK, item(ARMOR, 1, { equipLoc = "INVTYPE_HEAD", transmog = false })); m.cosmetic[LOOK] = true
    m.addItem(HELM, item(ARMOR, 4, { equipLoc = "INVTYPE_HEAD" }))
    m.addItem(POTION, item(CONSUMABLE, 1))
    local mj = m.C_MountJournal.GetMountFromItem
    m.C_MountJournal.GetMountFromItem = function(id) calls[#calls + 1] = id; return mj(id) end
  end }
  local f = W.v:Facts(LOOK)
  assertEqual(f.category, "cosmetic"); assertFalse(f.transmogKnown); assertNil(f.collect.known)
  assertEqual(W.v:Facts(HELM).category, "equipment"); assertNil(W.v:Facts(POTION).category)
  assertEqual(table.concat(calls, ","), "6005,6007", "the cosmetic and the potion; never the helm")
  local TOKEN = "|cnIQ4:|Hitem:6008::::::::90:::::|h[Token]|h|r"
  W.m.addItem(TOKEN, item(MISC, JUNK_SUB))
  W.m.tooltips.hyperlink[TOKEN] = { lines = { { type = 21, leftText = "Classes: Warrior, Paladin" } } }
  W.m.C_ToyBox.GetToyInfo = function() asked = asked + 1 end
  local t = W.v:Facts(TOKEN)
  assertTrue(t.isTierToken); assertEqual(t.category, "tierToken"); assertNil(t.collect)
  assertEqual(asked, 0)
end)

test("verdict collect: Read answers its argument, survives no facts, and defaults to lib.Reads", function()
  assertNil(c.Read(nil))
  local f = { classID = ARMOR, subClassID = 4, link = HELM, itemID = 6006 }
  assertTrue(c.Read(f) == f)
  assertEqual(f.category, "equipment")
end)

-- ---------------------------------------------------------------------------------------------
-- The instance's re-read
-- ---------------------------------------------------------------------------------------------

test("verdict collect: a burst of collection events reads once, then tells the host", function()
  local W = FC.new{ seed = function(m)
    m.addItem(MOUNT, item(MISC, MOUNT_SUB)); m.mounts.byItem[6001] = 77; m.mounts.collected[77] = false
  end }
  W.v:StandUp()
  W.changes = {}
  assertFalse(W.v:Facts(MOUNT).collect.known)
  W.m.mounts.collected[77] = true
  W.fire("NEW_MOUNT_ADDED", 77)
  W.fire("NEW_TOY_ADDED", 1)
  W.fire("SKILL_LINES_CHANGED")
  assertEqual(W.count("collection"), 0, "nothing before the delay")
  assertEqual(W.timers(), 1, "one re-read for the burst")
  assertEqual(W.count("collection"), 1)
  assertTrue(W.v:Facts(MOUNT).collect.known, "the cached facts read again")
  assertEqual(W.v:JudgeFacts(W.v:Facts(MOUNT)).verdict, "collected")
  W.fire("NEW_PET_ADDED", 3)
  W.v:StandDown()
  assertEqual(W.timers(), 0, "a stand-down cancels the pending re-read")
  assertEqual(W.count("collection"), 1, "and nothing is told")
end)
