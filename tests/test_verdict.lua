-- tests/test_verdict.lua -- LibKa0s-Verdict-1.0's shell (Verdict.lua): the load, the Core floor, the
-- secondary files paired on the shell's minor, the constants' per-client slots, and New(host).

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil, assertError =
  T.test, T.assertEqual, T.assertTrue, T.assertNil, T.assertError
local Loader = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local V = T.mocks.LibStub("LibKa0s-Verdict-1.0")
local FILES = { "VerdictConstants", "VerdictClassData", "VerdictTierTokens", "VerdictEvaluate" }

test("verdict: the major loads and reports its five files, each paired on the shell", function()
  assertEqual(V.MAJOR, "LibKa0s-Verdict-1.0")
  assertEqual(V.MODULES.Verdict, V.MINOR)
  assertEqual(V.MODULES.VerdictConstants, V.__constantsMinor)
  assertEqual(V.MODULES.VerdictClassData, V.__classDataMinor)
  assertEqual(V.MODULES.VerdictTierTokens, V.__tierTokensMinor)
  assertEqual(V.MODULES.VerdictEvaluate, V.__evaluateMinor)
  for _, field in ipairs({ "__constantsShellMinor", "__classDataShellMinor", "__tierTokensShellMinor",
      "__evaluateShellMinor" }) do
    assertEqual(V[field], V.MINOR, field .. ": paired on the live shell")
  end
end)

test("verdict: the kernel's public members are the major's own", function()
  for _, name in ipairs({ "Evaluate", "Equippability", "ItemVerdict", "TrackDelta", "SubClassKey", "New" }) do
    assertEqual(type(V[name]), "function", name)
  end
  for _, name in ipairs({ "C", "ClassData", "TierTokens", "OffSpec" }) do
    assertEqual(type(V[name]), "table", name)
  end
end)

test("verdict: no Core means no major, and every secondary loads to nothing without the shell", function()
  local m = buildMocks()
  Loader.load("LibKa0s/Verdict.lua", nil, m)
  for _, file in ipairs(FILES) do Loader.load("LibKa0s/" .. file .. ".lua", nil, m) end
  assertNil(m.LibStub("LibKa0s-Verdict-1.0", true))
end)

test("verdict: a secondary loaded again on the same shell is a no-op; a newer shell re-runs it", function()
  local before = V.Evaluate
  Loader.load("LibKa0s/VerdictEvaluate.lua", nil, T.mocks)
  assertTrue(V.Evaluate == before, "the same minor on the same shell: the file returns early")
end)

test("verdict: New(host) binds a client and raises on a host that names none", function()
  local v = V:New({ client = "forever" })
  assertEqual(v:Client(), "forever")
  assertEqual(V:New({ client = "retail" }).client, "retail")
  assertError(function() V:New() end, "host table")
  assertError(function() V:New({}) end, "host.client")
  assertError(function() V:New({ client = "classic" }) end, "host.client")
end)

test("verdict: two instances keep their own hosts, and share the method table", function()
  local a, b = V:New({ client = "retail" }), V:New({ client = "forever" })
  assertTrue(a.host ~= b.host)
  assertEqual(a:Client(), "retail"); assertEqual(b:Client(), "forever")
  assertTrue(getmetatable(a).__index == V.__methods and getmetatable(b).__index == V.__methods)
end)

test("verdict: the constants keep both clients' slots and slot plans", function()
  local C = V.C
  assertNil(C.SlotsFor("retail").RANGED, "Retail has no ranged slot")
  assertEqual(C.SlotsFor("forever").RANGED, 18)
  assertTrue(C.SlotsFor(nil) == C.SlotsFor("retail"), "no client: Retail's")
  assertTrue(C.SLOT == C.SlotsFor("retail"), "the shared slots")
  assertEqual(C.SlotPlanFor("retail").INVTYPE_RANGED.kind, "ranged")
  assertEqual(C.SlotPlanFor("forever").INVTYPE_RANGED.slots[1], 18)
  assertNil(C.SlotPlanFor("retail").INVTYPE_RELIC, "no relics on Retail")
  assertEqual(C.SlotPlanFor("forever").INVTYPE_RELIC.kind, "single")
  assertTrue(C.SlotPlanFor("classic") == C.SlotPlanFor("retail"), "an unknown client: Retail's")
  -- The values Drop Watcher's core/Constants.lua carried, verbatim.
  assertEqual(C.ITEM_CLASS.ARMOR, 4); assertEqual(C.ITEM_CLASS.WEAPON, 2)
  assertEqual(C.ARMOR_SUBCLASS.PLATE, 4); assertEqual(C.ARMOR_SUBCLASS.TOTEM, 9)
  assertEqual(C.WEAPON_SUBCLASS.WAND, 19); assertEqual(C.QUALITY.HEIRLOOM, 7)
  assertEqual(C.TRACK_TIER.Myth, 6); assertEqual(#C.TIER_SLOTS, 5)
  assertEqual(table.concat(C.FEATURE_CLIENTS.offSpec, ","), "retail")
end)

test("verdict: an evaluation's client picks its class list and its slot plans", function()
  local C = V.C
  local A, W = C.ARMOR_SUBCLASS, C.WEAPON_SUBCLASS
  local mail = { itemID = 1, ilvl = 610, equipLoc = "INVTYPE_CHEST", classID = C.ITEM_CLASS.ARMOR, subClassID = A.MAIL }
  local warrior = { classFile = "WARRIOR", level = 60, gear = { [5] = false } }
  -- red under: one class list for every caller (Drop Watcher's file-load install)
  assertEqual(V.Evaluate(mail, warrior, { client = "retail" }).verdict, "cantUse", "Retail's exact armor type")
  assertEqual(V.Evaluate(mail, warrior, { client = "forever" }).verdict, "upgrade", "Forever's lighter type")
  assertEqual(V.Evaluate(mail, warrior).verdict, "cantUse", "no client: Retail's list")
  local bow = { itemID = 2, ilvl = 650, equipLoc = "INVTYPE_RANGED", classID = C.ITEM_CLASS.WEAPON, subClassID = W.BOWS }
  local hunter = { classFile = "HUNTER", tree = 1, level = 60, gear = { [16] = false, [17] = false, [18] = false } }
  assertEqual(V.Evaluate(bow, hunter, { client = "forever" }).baselineSlot, 18, "Forever's ranged slot")
  assertEqual(V.Evaluate(bow, hunter, { client = "retail" }).baselineSlot, 16, "Retail's main hand")
end)
