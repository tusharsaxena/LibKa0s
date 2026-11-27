-- tests/test_verdict_tokens.lua -- LibKa0s-Verdict-1.0's tier tokens (VerdictTierTokens.lua):
-- the slot from the curated table, then the token's Use text or tooltip slot line, then its name,
-- else `any`; who may use a token; a concrete slot judged upgrade, sidegrade or downgrade against
-- what is worn there; the wrong class `cantUse`; an omni Curio with no class line folded to its best
-- slot; the scorer skipped and the caller's opts untouched; the looter's verdict on their own gear;
-- the words read from the host's locale table; and the text parsers behind them. Ported from Ka0s
-- Drop Watcher's tests/test_tier_token.lua and the tier token part of its tests/test_text_parse.lua
-- (DropWatcher#19), the cases unchanged. Drop Watcher's cases that read a token through its facts
-- reader (ItemFacts), its feed and its cells stay there, or land with the facts file (plan task B2).

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local Kit = dofile("tests/_kit/framework.lua")
local F = dofile("tests/fixture_verdict.lua")
local V = F.V
local TT = V.TierTokens

local MISC, JUNK_SUB, CLOTH, PLATE = 15, 0, 1, 4

local function hasReason(res, key)
  for _, r in ipairs(res.reasons or {}) do
    if r.key == key then return true end
  end
  return false
end

-- A row in the curated table, and the function that takes it out again: the table is lib.C's,
-- shared by every addon that loads the major.
local function listed(itemID, row)
  V.C.TIER_TOKENS[itemID] = row
  return function() V.C.TIER_TOKENS[itemID] = nil end
end

local secret = Kit.secret   -- the kit's secret-value simulator

-- ---------------------------------------------------------------------------------------------
-- The verdict (lib.Evaluate)
-- ---------------------------------------------------------------------------------------------

local function kernel() return F.kernel("retail") end

local function worn(C, ilvl, loc, sub)
  return { itemID = 1, ilvl = ilvl, equipLoc = loc, classID = C.ITEM_CLASS.ARMOR, subClassID = sub or CLOTH }
end

-- A mage wearing a head, shoulder, chest, hands and legs at the levels given.
local function mage(C, levels)
  local S, gear = C.SLOT, {}
  gear[S.HEAD], gear[S.SHOULDER] = worn(C, levels[1], "INVTYPE_HEAD"), worn(C, levels[2], "INVTYPE_SHOULDER")
  gear[S.CHEST], gear[S.HANDS] = worn(C, levels[3], "INVTYPE_CHEST"), worn(C, levels[4], "INVTYPE_HAND")
  gear[S.LEGS] = worn(C, levels[5], "INVTYPE_LEGS")
  return { classFile = "MAGE", specID = 64, gear = gear }
end

local function tokenFacts(ilvl, slot, classes)
  return { itemID = 707, ilvl = ilvl, equipLoc = slot ~= "any" and slot or "", rawEquipLoc = "", classID = MISC,
    subClassID = JUNK_SUB, isTierToken = true, tokenSlot = slot, classes = classes, category = "tierToken",
    stats = {} }
end

test("verdict tier token: a concrete slot is upgrade, sidegrade or downgrade against what is worn there", function()
  local E, C = kernel()
  local who = mage(C, { 610, 600, 600, 600, 600 })
  local mages = { MAGE = true, PRIEST = true, WARLOCK = true }
  local up = E.Evaluate(tokenFacts(620, "INVTYPE_HEAD", mages), who)
  assertEqual(up.equip, "ok"); assertEqual(up.verdict, "upgrade"); assertEqual(up.ilvlDelta, 10)
  assertEqual(up.baselineSlot, C.SLOT.HEAD)
  assertEqual(E.Evaluate(tokenFacts(610, "INVTYPE_HEAD", mages), who).verdict, "sidegrade")
  assertEqual(E.Evaluate(tokenFacts(605, "INVTYPE_HEAD", mages), who, { sidegradeBand = 2 }).verdict, "downgrade")
  assertEqual(E.Evaluate(tokenFacts(609, "INVTYPE_HEAD", mages), who, { sidegradeBand = 2 }).verdict, "sidegrade")
end)

test("verdict tier token: another class's token is cantUse; a slot not read is unknown, reason tierToken", function()
  local E, C = kernel()
  local who = mage(C, { 600, 600, 600, 600, 600 })
  local res = E.Evaluate(tokenFacts(620, "INVTYPE_HEAD", { WARRIOR = true, PALADIN = true }), who)
  assertEqual(res.verdict, "cantUse"); assertTrue(hasReason(res, "classRestricted"))
  -- red under: planFor answering notGear for a token with its classes but no slot read
  res = E.Evaluate(tokenFacts(620, nil, { MAGE = true }), who)
  assertEqual(res.verdict, "unknown"); assertTrue(hasReason(res, "tierToken"))
  assertFalse(hasReason(res, "notGear"))
end)

test("verdict tier token: a Curio with no class line folds to its best slot", function()
  local E, C = kernel()
  local who = mage(C, { 630, 625, 600, 640, 610 })
  -- red under: usable() answering unknown/tierToken for a token with no class list
  local res = E.Evaluate(tokenFacts(620, "any", nil), who)
  assertEqual(res.equip, "ok")
  assertEqual(res.verdict, "upgrade"); assertEqual(res.ilvlDelta, 20, "the chest, the largest gain")
  assertEqual(res.tokenSlot, "INVTYPE_CHEST"); assertEqual(res.baselineSlot, C.SLOT.CHEST)
  who.gear[C.SLOT.LEGS] = false
  res = E.Evaluate(tokenFacts(620, "any", nil), who)
  assertEqual(res.tokenSlot, "INVTYPE_LEGS", "an empty slot beats any gain")
  who = mage(C, { 640, 640, 630, 650, 640 })
  res = E.Evaluate(tokenFacts(620, "any", nil), who)
  assertEqual(res.verdict, "downgrade"); assertEqual(res.tokenSlot, "INVTYPE_CHEST", "the least loss")
end)

test("verdict tier token: a Curio of another class is cantUse, naming no slot", function()
  local E, C = kernel()
  local res = E.Evaluate(tokenFacts(620, "any", { WARRIOR = true }), mage(C, { 600, 600, 600, 600, 600 }))
  assertEqual(res.verdict, "cantUse"); assertNil(res.tokenSlot)
end)

test("verdict tier token: the scorer is skipped, and neither the opts nor the facts are written", function()
  local E, C = kernel()
  local scored = 0
  local opts = { scorer = function() scored = scored + 1 return 100 end, sidegradeBand = 0 }
  local facts = tokenFacts(620, "any", { MAGE = true })
  local before = {}
  for k, v in pairs(facts) do before[k] = v end
  local res = E.Evaluate(facts, mage(C, { 600, 600, 600, 600, 600 }), opts)
  -- red under: compare calling the scorer for a token (Pawn cannot value one)
  assertEqual(scored, 0); assertNil(res.scoreDelta)
  assertFalse(hasReason(res, "scorePending"))
  assertNil(opts.skipScore); assertEqual(type(opts.scorer), "function")
  -- red under: the fold setting equipLoc or tokenSlot on the cache's own facts
  for k, v in pairs(before) do assertEqual(facts[k], v, k) end
  for k in pairs(facts) do assertTrue(before[k] ~= nil, k .. " added") end
  local gear = E.Evaluate(worn(C, 620, "INVTYPE_HEAD"), mage(C, { 600, 600, 600, 600, 600 }), opts)
  assertEqual(gear.scoreDelta, 0, "gear is still scored")
end)

test("verdict tier token: the looter is judged on their own class and gear", function()
  local E, C = kernel()
  local facts = tokenFacts(620, "INVTYPE_HAND", { WARRIOR = true, PALADIN = true })
  local brakk = { classFile = "WARRIOR", specID = 71, gear = { [C.SLOT.HANDS] = worn(C, 630, "INVTYPE_HAND", PLATE) } }
  local res = E.Evaluate(facts, brakk)
  assertEqual(res.verdict, "downgrade"); assertEqual(res.ilvlDelta, -10)
  assertEqual(E.Evaluate(facts, mage(C, { 600, 600, 600, 600, 600 })).verdict, "cantUse")
end)

-- ---------------------------------------------------------------------------------------------
-- The token's own text (TT-1): the Use text, the name, the Curio
-- ---------------------------------------------------------------------------------------------

local MIDNIGHT_HAND = "Create a soulbound set hand item appropriate for your class."
local NULLCORE = "Synthesize a soulbound set shoulder item appropriate for your class."
local MANAFORGE = "Synthesize a soulbound Manaforge Omega set leg item appropriate for your class."
local TIER19 = "Create a soulbound Tier 19 item appropriate for your class."

test("verdict tier token: the Use text names the slot (Midnight's tokens), source use", function()
  local function slotOf(id, name, text) return TT.SlotOf({ itemID = id, name = name, useText = text }) end
  local slot, source = slotOf(270913, "Venomforged Idol", MIDNIGHT_HAND)
  assertEqual(slot, "INVTYPE_HAND"); assertEqual(source, "use")
  slot, source = slotOf(249366, "Voidforged Unraveled Nullcore", NULLCORE)
  assertEqual(slot, "INVTYPE_SHOULDER"); assertEqual(source, "use")
  assertEqual((slotOf(1, "Token", MANAFORGE)), "INVTYPE_LEGS", "a raid name of two words")
  assertEqual((slotOf(1, "Token", "Create a soulbound Sunset set head item appropriate for your class.")),
    "INVTYPE_HEAD", "a raid name ending in set")
  assertEqual((slotOf(1, "Token", "CREATE A SOULBOUND SET CHEST ITEM APPROPRIATE FOR YOUR CLASS.")),
    "INVTYPE_CHEST", "any case")
end)

test("verdict tier token: an older token's name names the slot, source name; else any", function()
  local function slotOf(name, text) return TT.SlotOf({ itemID = 1, name = name, useText = text }) end
  local slot, source = slotOf("Gauntlets of the Foreseen Conqueror", TIER19)
  -- red under: the name rung missing, so a Tier 19 token reads any
  assertEqual(slot, "INVTYPE_HAND"); assertEqual(source, "name")
  assertEqual((slotOf("Helm of the Forgotten Vanquisher")), "INVTYPE_HEAD")
  assertEqual((slotOf("Shoulders of the Foreseen Protector")), "INVTYPE_SHOULDER")
  assertEqual((slotOf("Chestguard of the Forgotten Protector")), "INVTYPE_CHEST")
  assertEqual((slotOf("leggings of the lost conqueror")), "INVTYPE_LEGS", "any case")
  slot, source = slotOf("Cloak of the Foreseen Conqueror", TIER19)
  assertEqual(slot, "any", "a cloak is not a tier slot"); assertEqual(source, "any")
  assertEqual((slotOf("Helmsman's Badge")), "any", "a slot noun only as a whole word")
  slot, source = slotOf("Venomforged Idol", "Teaches you a thing.")
  assertEqual(slot, "any", "neither"); assertEqual(source, "any")
end)

test("verdict tier token: the rungs run in order: table, then use, then name", function()
  local undo = listed(720, { slot = "INVTYPE_LEGS" })
  local asked = 0
  local function reader() asked = asked + 1 return "INVTYPE_CHEST" end
  local both = { name = "Gauntlets of the Foreseen Conqueror", useText = NULLCORE }
  local slot, source = TT.SlotOf({ itemID = 720, name = both.name, useText = both.useText }, reader)
  assertEqual(slot, "INVTYPE_LEGS"); assertEqual(source, "table")
  -- red under: the name read before the Use text
  slot, source = TT.SlotOf({ itemID = 721, name = both.name, useText = both.useText }, reader)
  assertEqual(slot, "INVTYPE_SHOULDER"); assertEqual(source, "use")
  assertEqual(asked, 0, "the tooltip slot line is not read when the Use text answers")
  slot, source = TT.SlotOf({ itemID = 721, name = both.name, useText = TIER19 }, reader)
  assertEqual(slot, "INVTYPE_CHEST", "the tooltip slot line, the use rung's second read"); assertEqual(source, "use")
  slot, source = TT.SlotOf({ itemID = 721, name = both.name, useText = TIER19 })
  assertEqual(slot, "INVTYPE_HAND"); assertEqual(source, "name")
  undo()
end)

test("verdict tier token: a secret, missing or non-string text reads no slot, never raises", function()
  for _, v in ipairs({ secret(MIDNIGHT_HAND), 42, "", {} }) do
    local ok, slot, source = pcall(TT.SlotOf, { itemID = 1, name = v, useText = v })
    assertTrue(ok, "raised"); assertEqual(slot, "any"); assertEqual(source, "any")
    assertFalse(TT.UseNamesClass(v)); assertFalse(TT.IsCurio({ quality = 4, classID = MISC, name = v }))
  end
  assertFalse(TT.UseNamesClass(nil)); assertNil(TT.UseSlot(nil)); assertNil(TT.NameSlot(nil))
end)

test("verdict tier token: every word is the host's locale table's, read by Drop Watcher's keys", function()
  local L = setmetatable({}, { __index = function(_, k) return k end })
  L["appropriate for your class"], L["set %s item"], L["hand hands"] = "fuer eure Klasse", "Setteil %s", "Haende"
  L["Gauntlets Gloves Handguards Grips Handwraps Grasps"], L["Curio"] = "Stulpen", "Kuriositaet"
  -- red under: any of the words written in the matcher itself
  assertEqual((TT.SlotOf({ itemID = 1, useText = "Erschafft ein Setteil Haende fuer eure Klasse." }, nil, L)), "INVTYPE_HAND")
  assertTrue(TT.UseNamesClass("... fuer eure Klasse.", L))
  assertEqual((TT.SlotOf({ itemID = 1, name = "Stulpen des Eroberers" }, nil, L)), "INVTYPE_HAND")
  assertTrue(TT.IsCurio({ quality = 4, classID = MISC, subClassID = JUNK_SUB, rawEquipLoc = "", name = "Leere Kuriositaet" }, L))
  local slot, source = TT.SlotOf({ itemID = 1, name = "Gauntlets of the Foreseen Conqueror", useText = MIDNIGHT_HAND }, nil, L)
  assertEqual(slot, "any", "the enUS words, no longer the table's, never match"); assertEqual(source, "any")
  -- red under: one cached vocabulary for every host, so the first host's words answer the second's
  slot, source = TT.SlotOf({ itemID = 1, name = "Gauntlets of the Foreseen Conqueror", useText = MIDNIGHT_HAND })
  assertEqual(slot, "INVTYPE_HAND", "no table: the enUS words"); assertEqual(source, "use")
end)

test("verdict tier token: the word keys are Drop Watcher's locale keys", function()
  local K = V.TierTokens.WORDS
  assertEqual(K.phrase, "appropriate for your class"); assertEqual(K.template, "set %s item")
  assertEqual(K.useSlots.INVTYPE_HAND, "hand hands"); assertEqual(K.useSlots.INVTYPE_SHOULDER, "shoulder shoulders")
  assertEqual(K.names.INVTYPE_HAND, "Gauntlets Gloves Handguards Grips Handwraps Grasps")
  assertEqual(K.names.INVTYPE_LEGS, "Leggings Legguards Legplates Pants Kilt Trousers Breeches Legwraps")
  assertEqual(K.curio, "Curio")
  local slots = 0
  for _ in pairs(K.useSlots) do slots = slots + 1 end
  assertEqual(slots, #V.C.TIER_SLOTS, "a Use word per tier slot")
end)

-- ---------------------------------------------------------------------------------------------
-- The slot rungs and the users
-- ---------------------------------------------------------------------------------------------

test("verdict tier token: a reader's slot that is not a tier slot, or any, reads any; no facts reads nil", function()
  local slot, source = TT.SlotOf({ itemID = 9 }, function() return "INVTYPE_FEET" end)
  assertEqual(slot, "any", "not a tier slot"); assertEqual(source, "any")
  slot, source = TT.SlotOf({ itemID = 9 }, function() return "any" end)
  assertEqual(slot, "any", "the tooltip never says any"); assertEqual(source, "any")
  assertNil(TT.SlotOf(nil), "no facts")
end)

test("verdict tier token: the tooltip is not read when the table answers", function()
  local undo = listed(705, { slot = "INVTYPE_CHEST" })
  local asked = 0
  local slot, source = TT.SlotOf({ itemID = 705 }, function() asked = asked + 1 return "INVTYPE_HEAD" end)
  assertEqual(slot, "INVTYPE_CHEST"); assertEqual(source, "table"); assertEqual(asked, 0)
  assertFalse(TT.Listed(706)); assertTrue(TT.Listed(705))
  undo()
  assertFalse(TT.Listed(705), "the table is shared: the case leaves it as it found it")
end)

test("verdict tier token: Users: every for a Curio or a listed any, yours for the class phrase, nil for a class list", function()
  local curio = { quality = 4, classID = MISC, subClassID = JUNK_SUB, rawEquipLoc = "", name = "Chiming Void Curio" }
  assertEqual(TT.Users(curio), "every")
  local undo = listed(708, { slot = "any" })
  assertEqual(TT.Users({ itemID = 708 }), "every", "a listed any")
  undo()
  assertEqual(TT.Users({ itemID = 709, useText = MIDNIGHT_HAND }), "yours")
  assertNil(TT.Users({ itemID = 709, useText = MIDNIGHT_HAND, classes = { MAGE = true } }), "a class list names its own")
  assertNil(TT.Users({ itemID = 709, useText = "Teaches you a thing." }), "not read")
  assertNil(TT.Users(nil))
  -- red under: a gear slot read as no slot plan, so a Curio-named piece of gear reads as a Curio
  assertFalse(TT.IsCurio({ quality = 4, classID = MISC, subClassID = JUNK_SUB, rawEquipLoc = "INVTYPE_HEAD",
    name = "Helm Curio" }), "gear is no Curio")
  assertFalse(TT.IsCurio({ quality = 3, classID = MISC, subClassID = JUNK_SUB, rawEquipLoc = "", name = "Curio" }),
    "a rare is no Curio")
  assertFalse(TT.IsCurio({ quality = 4, classID = MISC, subClassID = V.C.MISC_SUBCLASS.MOUNT, rawEquipLoc = "",
    name = "Curio" }), "a mount is no Curio")
end)


-- ---------------------------------------------------------------------------------------------
-- The text parsers (Drop Watcher's core/TextParse.lua, its tier token part)
-- ---------------------------------------------------------------------------------------------

test("verdict tier token text: EscapePattern escapes every magic character", function()
  local s = "a.b%c(d)[e]*f+g-h?i^j$k"
  assertTrue(("x" .. s .. "y"):find(TT.EscapePattern(s)) == 2, "a plain match of the whole text")
end)

-- The enUS words the tier token readers hand over (TT-1).
local function useVocab()
  return { phrase = "appropriate for your class", template = "set %s item",
    slots = TT.WordMap({ INVTYPE_HAND = "hand hands", INVTYPE_LEGS = "leg legs", INVTYPE_HEAD = "head" }) }
end

test("verdict tier token text: WordMap, FirstWord and EndsWithWord read whole words, any case (TT-1)", function()
  local map = TT.WordMap({ HAND = "Gauntlets Gloves", HEAD = "Helm" })
  assertEqual(map.gauntlets, "HAND"); assertEqual(map.helm, "HEAD"); assertNil(map.Helm, "keys are lowercase")
  assertEqual(TT.FirstWord("GAUNTLETS of the Foreseen Conqueror", map), "HAND")
  assertEqual(TT.FirstWord("Helm, then Gloves", map), "HEAD", "the first known word")
  assertNil(TT.FirstWord("Helmsman's Gloveshaft", map), "never part of a word")
  assertTrue(TT.EndsWithWord("Chiming Void curio  ", "Curio"))
  assertFalse(TT.EndsWithWord("Chiming Void Curio Box", "Curio"), "not the last word")
  assertFalse(TT.EndsWithWord("Chiming Voidcurio", "Curio"), "not a whole word")
  assertFalse(TT.EndsWithWord("Curio", ""), "no word")
end)

test("verdict tier token text: TokenUseSlot reads the class phrase and the set <slot> item, in the words it is handed (TT-1)", function()
  local v = useVocab()
  assertEqual(TT.TokenUseSlot("Create a soulbound set hand item appropriate for your class.", v), "INVTYPE_HAND")
  assertEqual(TT.TokenUseSlot("Synthesize a soulbound Manaforge Omega set leg item appropriate for your class.", v),
    "INVTYPE_LEGS", "a raid name of two words")
  assertEqual(TT.TokenUseSlot("Create a soulbound Sunset set head item appropriate for your class", v),
    "INVTYPE_HEAD", "a raid name ending in set, no full stop")
  assertEqual(TT.TokenUseSlot("CREATE A SOULBOUND SET HANDS ITEM APPROPRIATE FOR YOUR CLASS.", v), "INVTYPE_HAND")
  -- red under: a slot word matched without the class phrase, or inside a longer word
  assertNil(TT.TokenUseSlot("Create a soulbound set hand item.", v), "no class phrase")
  assertNil(TT.TokenUseSlot("Create a soulbound Tier 19 item appropriate for your class.", v), "no set <slot> item")
  assertNil(TT.TokenUseSlot("Create a soulbound set feet item appropriate for your class.", v), "not a tier slot")
  assertNil(TT.TokenUseSlot("Create a soulbound Voidset hand item appropriate for your class.", v), "set inside a word")
  assertNil(TT.TokenUseSlot("Create a soulbound set handy item appropriate for your class.", v), "a longer word")
  local de = { phrase = "passend fuer eure Klasse", template = "Setteil %s", slots = TT.WordMap({ HAND = "Haende" }) }
  assertEqual(TT.TokenUseSlot("Erschafft ein Setteil Haende, passend fuer eure Klasse.", de), "HAND",
    "another locale's words, handed over")
  assertNil(TT.TokenUseSlot("Create a soulbound set hand item appropriate for your class.", de), "the enUS line")
end)
