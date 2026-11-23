-- tests/test_core_follow_color.lua -- LibKa0s-Core-1.0 minor 20: the preview stand-in for a class
-- color and the one class -> skin -> swatch ladder (FB-LK-01 of Ka0sAddonsCommonTasks
-- docs/2026-11-24-FEEDBACK_BATCH, the owner's K and P findings).
--
-- THE DEFECT. A preview, unlock or sim frame that describes a unit that does not exist (target,
-- focus, party1) asked lib.ClassColor for that unit, got nil, and drew the stored swatch: on the
-- owner's hunter, KickCD's "Target" label with "Use class color" on drew the gold label color, and
-- PFE's preview cast bar its orange cast color. And with no shared ladder, about twelve private
-- copies disagreed on the unresolved case: some fell to the skin, some skipped it.
--
-- THE RULE. lib.ClassColor(unit, standIn) and lib.ResolveColor(stored, on, unit, standIn) resolve
-- `standIn` (a host passes "player" while previewing) when `unit` does not exist. lib.FollowColor is
-- the ladder: a class color that resolved first (it has no companion and keeps the stored alpha),
-- then the skin's color while "Use the skin's color" is on, then the stored swatch. A class toggle
-- with no class to show follows the skin like a toggle that is off.

local T = _G.LK_TEST
local core = T.core
local test, assertEqual, assertNil = T.test, T.assertEqual, T.assertNil

local function fresh()
  core.__ResetClassColor()
  T.mocks.__unitClass = {}
  T.mocks.__unitExists = { player = true, target = false, focus = false }
  -- No target and no focus: the client answers no class for either (the mock's unit-blind fallback
  -- would answer the fixture character).
  T.mocks.setUnitClass("target", nil, nil)
  T.mocks.setUnitClass("focus", nil, nil)
end

local STORED = { r = 0.1, g = 0.2, b = 0.3, a = 0.4 }
local function skin(r, g, b, a)
  local asked = {}
  return function(token) asked[#asked + 1] = token; return r, g, b, a end, asked
end

test("core follow color: a stand-in answers for a unit that does not exist", function()
  -- red under: Core minor 19, whose ClassColor took one argument and answered nil for "target".
  fresh()
  T.mocks.setUnitClass("player", "Hunter", "MAGE")
  assertNil(core.ClassColor("target"), "no stand-in: nil, as before")
  local r = core.ClassColor("target", "player")
  assertEqual(r, 0.25, "no target: the player's class")
end)

test("core follow color: a unit that exists is never replaced by the stand-in", function()
  -- red under: preferring the stand-in whenever one is passed.
  fresh()
  T.mocks.__unitExists.target = true
  T.mocks.setUnitClass("target", "Warlock", "WARLOCK")
  assertEqual(core.ClassColor("target", "player"), 0.53, "the real target's class")
  T.mocks.setUnitClass("boss1", "Boss", nil)
  T.mocks.__unitExists.boss1 = true
  assertNil(core.ClassColor("boss1", "player"), "an NPC that exists is still no class")
end)

test("core follow color: ResolveColor passes the stand-in through and keeps the stored alpha", function()
  fresh()
  local r, g, b, a = core.ResolveColor(STORED, true, "focus", "player")
  assertEqual(r, 0.77, "the fixture Death Knight stands in for the missing focus")
  assertEqual(g, 0.12)
  assertEqual(b, 0.23)
  assertEqual(a, 0.4)
  local sr = core.ResolveColor(STORED, true, "focus")
  assertEqual(sr, 0.1, "no stand-in: the stored swatch, as before")
end)

test("core follow color: a class that resolves comes first, whatever the skin companion says", function()
  -- red under: SkillMaster's and CombatTrail's order, the skin ahead of the class.
  fresh()
  local read = skin(0.9, 0.9, 0.9, 1)
  local r, g, b, a, from = core.FollowColor(STORED, true, "player", true, read, "hud.text")
  assertEqual(r, 0.77); assertEqual(g, 0.12); assertEqual(b, 0.23)
  assertEqual(a, 0.4, "the class keeps the stored alpha")
  assertEqual(from, "class")
end)

test("core follow color: an unresolved class falls to the skin while its companion is on", function()
  -- red under: KickCD's SkinHudColor and AbsorbTracker's skinColor, which skipped the skin whenever
  -- the class toggle was on, so an NPC or an absent target drew the stored swatch.
  fresh()
  local read, asked = skin(0.5, 0.6, 0.7, 0.8)
  local r, g, b, a, from = core.FollowColor(STORED, true, "target", true, read, "hud.label")
  assertEqual(r, 0.5); assertEqual(g, 0.6); assertEqual(b, 0.7); assertEqual(a, 0.8)
  assertEqual(from, "skin")
  assertEqual(asked[1], "hud.label", "the reader is handed the token")
end)

test("core follow color: the stand-in wins over the skin in a preview", function()
  fresh()
  local r, _, _, _, from = core.FollowColor(STORED, true, "target", true, skin(0.5, 0.6, 0.7, 0.8), nil, "player")
  assertEqual(r, 0.77)
  assertEqual(from, "class")
end)

test("core follow color: the skin's alpha is the stored one when the reader gives none", function()
  fresh()
  local _, _, _, a = core.FollowColor(STORED, false, nil, true, skin(0.5, 0.6, 0.7))
  assertEqual(a, 0.4)
end)

test("core follow color: the stored swatch when neither rung answers", function()
  fresh()
  local r, g, b, a, from = core.FollowColor(STORED, false, nil, false, skin(0.5, 0.6, 0.7, 1))
  assertEqual(r, 0.1); assertEqual(g, 0.2); assertEqual(b, 0.3); assertEqual(a, 0.4)
  assertEqual(from, "stored", "companion off: the skin is never asked")
  local r2, _, _, _, from2 = core.FollowColor(STORED, true, "target", true, skin(nil))
  assertEqual(r2, 0.1, "a skin that leaves the token alone")
  assertEqual(from2, "stored")
  local r3, _, _, _, from3 = core.FollowColor(STORED, true, "target", true, nil)
  assertEqual(r3, 0.1, "no reader: a host with no library")
  assertEqual(from3, "stored")
end)

test("core follow color: a reader may answer a color table", function()
  fresh()
  local r, g, b, a = core.FollowColor(STORED, false, nil, true, function() return { 0.5, 0.6, 0.7, 0.9 } end)
  assertEqual(r, 0.5); assertEqual(g, 0.6); assertEqual(b, 0.7); assertEqual(a, 0.9)
end)
