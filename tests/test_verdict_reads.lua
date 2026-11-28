-- tests/test_verdict_reads.lua -- LibKa0s-Verdict-1.0's default client reads (VerdictReads.lua):
-- each member answers its documented absent value on a client without the API and never raises, a
-- secret answer is no answer, and the readers the facts and the collections lean on (the tooltip
-- line reader, the class line, the opens line, the recipe line, the talent tree, Pawn's readiness)
-- read the client the way Ka0s Drop Watcher's compat members did. The members' end-to-end reads
-- are the facts, gear, score and collect suites'; this one pins the edges those leave out.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local FC = dofile("tests/fixture_verdict_client.lua")

local LINK = FC.link(4001)

-- A world whose client has none of the APIs the reads call.
local function bare()
  local W = FC.new{}
  local m = W.m
  for _, name in ipairs({ "C_Item", "C_TooltipInfo", "C_Container", "C_MountJournal", "C_PetJournal",
    "C_ToyBox", "C_Spell", "C_TransmogCollection", "GetInventoryItemLink", "PlayerHasToy",
    "GetProfessions", "GetProfessionInfo", "ItemLocation", "UnitLevel", "UnitClass" }) do
    m[name] = nil
  end
  return W
end

test("verdict reads: every member answers its absent value on a client without the API", function()
  local R = bare().V.Reads
  assertNil(R.InventoryItemLink("player", 1)); assertEqual(R.BagSlotCount(0), 0); assertNil(R.BagItemLink(0, 1))
  assertNil(R.InventoryItemLevel("player", 1)); assertNil(R.GetItemInfo(LINK)); assertNil(R.GetDetailedItemLevel(LINK))
  assertEqual(next(R.GetItemStats(LINK)), nil, "an empty table"); assertNil(R.GetItemSpecs(LINK))
  local cat, max = R.GetItemUniqueness(LINK)
  assertNil(cat); assertNil(max)
  assertNil(R.GetItemUpgradeInfo(LINK)); assertNil(R.PlayerHasTransmog(LINK)); assertNil(R.ItemClassRestriction(LINK))
  assertNil(R.ItemPrimaryStats(LINK)); assertFalse(R.IsItemBindToAccount(LINK)); assertFalse(R.IsItemBindToAccountUntilEquip(LINK))
  assertNil(R.ItemEquipLoc(LINK)); assertFalse(R.CanRequestItemLoad())
  local level, quality = R.BagItemLevelQuality(0, 1)
  assertNil(level); assertNil(quality)
  assertNil(R.MountFromItem(1)); assertNil(R.MountCollected(1)); assertNil(R.PetSpeciesFromItem(1))
  assertNil(R.PetCollected(1)); assertFalse(R.IsToy(1)); assertNil(R.ToyCollected(1)); assertFalse(R.IsCosmeticItem(LINK))
  assertNil(R.RecipeKnown(LINK)); assertNil(R.ProfessionSkillLines()); assertNil(R.TierTokenSlot(LINK))
  assertNil(R.ItemOpens(LINK)); assertNil(R.ItemUseText(LINK)); assertFalse(R.CanRequestSpellLoad())
  assertFalse(R.RequestSpellLoad(7)); assertNil(R.UnitLevel("player")); assertNil(R.UnitClass("player"))
  assertFalse(R.PawnIsReady()); assertNil(R.PawnItemData(LINK)); assertNil(R.PawnUpgradeInfo(LINK))
  assertNil(R.PawnScaleForSpec(8, 62)); assertNil(R.PawnVisibleScale(8, 62)); assertNil(R.PawnCustomScale(8))
  assertEqual(#R.PawnClassScales(8), 0); assertNil(R.PawnItemValue(LINK, "x"))
end)

test("verdict reads: a secret answer is no answer", function()
  local W = FC.new{ seed = function(m)
    m.addItem(LINK, FC.def("INVTYPE_HEAD", 600, 4, 2))
    m.inventory.player[1] = LINK
  end }
  local R, m = W.V.Reads, W.m
  local secret = {}
  m.issecretvalue = function(v) return v == secret end
  m.GetInventoryItemLink = function() return secret end
  assertNil(R.InventoryItemLink("player", 1))
  m.UnitLevel = function() return secret end
  assertNil(R.UnitLevel("player"))
  m.C_Item.GetDetailedItemLevelInfo = function() return secret end
  assertNil(R.GetDetailedItemLevel(LINK))
  assertNil(R.GetItemInfo(secret), "a secret link is never read")
end)

test("verdict reads: the tooltip line reader prefers the typed line, then any line", function()
  local R = FC.new{}.V.Reads
  local data = { lines = { { type = 0, leftText = "Item Level 300" }, { type = 41, leftText = "Item Level 311" } } }
  local parse = function(text) return tonumber(text:match("(%d+)$")) end
  assertEqual(R.ReadTooltipLine(data, "ItemLevel", parse), 311, "the ItemLevel line first")
  assertEqual(R.ReadTooltipLine(data, "NoSuchType", parse), 300, "no such type: every line")
  assertNil(R.ReadTooltipLine(nil, "ItemLevel", parse)); assertNil(R.ReadTooltipLine({}, "ItemLevel", parse))
end)

test("verdict reads: the class line, the opens line and the recipe line read their GlobalStrings", function()
  local W = FC.new{}
  local R, m = W.V.Reads, W.m
  m.tooltips.hyperlink[LINK] = { lines = { { type = 21, leftText = "Classes: Warrior, Death Knight" },
    { type = 0, leftText = "Locked" } } }
  local set = R.ItemClassRestriction(LINK)
  assertTrue(set.WARRIOR); assertTrue(set.DEATHKNIGHT); assertNil(set.MAGE)
  assertEqual(R.ItemOpens(LINK), "locked")
  assertFalse(R.RecipeKnown(LINK), "read, with no Already known line")
  m.tooltips.hyperlink[LINK].lines[3] = { type = 0, leftText = "Already known" }
  assertTrue(R.RecipeKnown(LINK))
  local secret = {}
  m.issecretvalue = function(v) return v == secret end
  m.tooltips.hyperlink[LINK].lines[4] = { type = 0, leftText = secret }
  assertNil(R.RecipeKnown(LINK), "a secret line: no claim either way")
  assertNil(R.ItemOpens(LINK))
end)

test("verdict reads: the talent tree is the group with the most points, none on a tie", function()
  local W = FC.new{ client = "forever", seed = function(m)
    m.__context.class, m.__context.classToken = "Hunter", "HUNTER"
    m.seedTalents(1485, { { name = "Beast Mastery", spent = 3 }, { name = "Marksmanship", spent = 31 } })
  end }
  local R = W.V.Reads
  local tree = R.PlayerTalentTree()
  assertEqual(tree.index, 2); assertEqual(tree.name, "Marksmanship")
  W.m.talents[1].spent = 31
  assertNil(R.PlayerTalentTree(), "a tie")
  assertNil(FC.new{}.V.Reads.PlayerTalentTree(), "Retail has no talent groups")
end)

test("verdict reads: Pawn is ready by PawnIsReady, else PawnIsInitialized; its error is never the host's", function()
  local W = FC.new{}
  local R, m = W.V.Reads, W.m
  m.PawnIsInitialized = true
  assertTrue(R.PawnIsReady(), "the flag")
  m.PawnIsReady = function() error("Pawn's bug") end
  assertFalse(R.PawnIsReady(), "a raise is not ready")
  m.PawnIsReady = function() return true end
  m.PawnGetItemData = function() error("Pawn's bug") end
  assertNil(R.PawnItemData(LINK), "a raise is no data")
  m.PawnGetItemData = function(l) return { link = l } end
  m.PawnGetSingleValueFromItem = function() return 50, 40 end
  assertEqual(R.PawnItemValue(LINK, "x"), 40, "the unenchanted value")
  m.PawnFindScaleForSpec = function(classID, index) return classID .. ":" .. index end
  assertEqual(R.PawnScaleForSpec(8, 62), "8:1", "Retail's spec index")
  assertEqual(R.PawnScaleForSpec(11, 1447, 2, "TANK", "forever"), "11:3", "Forever's Feral tank")
end)
