-- tests/test_options_skin_verb.lua -- LibKa0s-Options-1.0's O.SkinVerb(spec), the act behind every
-- addon's `/<slash> skin` verb (OptionsSkinPicker.lua minor 3; LK-11 of Ka0sAddonsCommonTasks
-- docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK, the owner's item 12 and ruling D-16).
--
-- What it pins: the verb shows the same picker a new profile shows, whatever the profile's "seen"
-- flag says (the host hands it its first-run spec); in combat it shows nothing and prints the gray
-- VERB_COMBAT line on EVERY call, with one Cfg line through the descriptor's debug; while another
-- owner's picker is up it queues and says so; a repeat while its own is up refreshes the one window;
-- without the Skin major, or for an owner that never registered, it says skins are unavailable; and
-- the four words in lib.SKIN_PICKER_STRINGS, ASCII, spec.strings over them.
--
-- Its own suite rather than more cases in tests/test_options_skin_picker.lua, which is in layout-§1's
-- band; the bench is shared through tests/fixture_skin_picker.lua.

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = K.test, K.assertEqual, K.assertTrue, K.assertNil
local Bench = dofile("tests/fixture_skin_picker.lua")
local OWNER, OTHER = Bench.OWNER, Bench.OTHER
local env, register, instance, specFor = Bench.env, Bench.register, Bench.instance, Bench.specFor

--- An instance for `owner` whose printed lines and debug lines are recorded.
local function recorded(lib, owner)
  local out = { lines = {}, debug = {} }
  out.O = instance(lib, owner, {
    print = function(msg) out.lines[#out.lines + 1] = msg end,
    debug = function(channel, msg) out.debug[#out.debug + 1] = channel .. ": " .. tostring(msg) end,
  })
  return out
end

local function count(list, want)
  local n = 0
  for _, v in ipairs(list) do if v == want then n = n + 1 end end
  return n
end

test("skin verb: SkinVerb is a member, and its four words are ASCII", function()
  local _, _, lib = env()
  local O = instance(lib, OWNER)
  assertEqual(type(O.SkinVerb), "function")
  local S = lib.SKIN_PICKER_STRINGS
  assertEqual(S.VERB_HELP, "Choose a skin: open the skin picker")
  for _, key in ipairs({ "VERB_HELP", "VERB_COMBAT", "VERB_QUEUED", "VERB_UNAVAILABLE" }) do
    assertEqual(type(S[key]), "string", key)
    assertNil(S[key]:find("[\128-\255]"), key .. " is ASCII")
  end
  assertTrue(S.VERB_COMBAT:find("^|cffaaaaaa") ~= nil, "gray, like the combat notice")
end)

test("skin verb: shows the picker on a profile that has already seen it, with the same spec", function()
  -- red under: a verb that gates on pickerSeen as the first-run start does (it would show nothing)
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  store.pickerSeen = true
  local r = recorded(lib, OWNER)
  local spec = specFor(store)
  local f = r.O.SkinVerb(spec)
  assertTrue(f ~= nil and f:IsShown(), "the window is up")
  assertEqual(#r.lines, 0, "and nothing is printed")
  f.close:__fire("OnClick")
  assertEqual(store.closed, 1, "its onClose runs once, where the host marks the profile seen")
end)

test("skin verb: in combat it shows nothing and prints the gray line on every call", function()
  -- red under: routing through O.__combatRefused, which prints once per combat (the second
  -- /xx skin in one fight would answer nothing)
  local m, Skin, lib = env()
  local store = register(Skin, OWNER)
  local r = recorded(lib, OWNER)
  m.InCombatLockdown = function() return true end
  local f, why = r.O.SkinVerb(specFor(store))
  assertNil(f)
  assertEqual(why, "combat")
  local _, again = r.O.SkinVerb(specFor(store))
  assertEqual(again, "combat")
  m.InCombatLockdown = function() return false end
  assertEqual(count(r.lines, lib.SKIN_PICKER_STRINGS.VERB_COMBAT), 2, "one line per call")
  assertNil(lib.__pickerQueue.current, "no window")
  assertEqual(count(r.debug, "Cfg: skin picker " .. OWNER .. " refused (in combat)"), 2,
    "one Cfg line per call, through the descriptor's debug")
end)

test("skin verb: with another owner's picker up it queues, says so, and shows when that one closes", function()
  local _, Skin, lib = env()
  local storeA, storeB = register(Skin, OTHER), register(Skin, OWNER)
  local other = instance(lib, OTHER)
  local fa = other.SkinPicker(specFor(storeA))
  local r = recorded(lib, OWNER)
  local f, why = r.O.SkinVerb(specFor(storeB))
  assertNil(f)
  assertEqual(why, "queued")
  assertEqual(count(r.lines, lib.SKIN_PICKER_STRINGS.VERB_QUEUED), 1)
  fa.close:__fire("OnClick")
  local cur = lib.__pickerQueue.current
  assertTrue(cur ~= nil and cur.owner == OWNER, "this owner's picker shows next")
end)

test("skin verb: a repeat while its own picker is up refreshes the one window", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local r = recorded(lib, OWNER)
  local f1 = r.O.SkinVerb(specFor(store))
  local f2 = r.O.SkinVerb(specFor(store))
  assertTrue(f1 ~= nil and f1 == f2, "one window")
  assertEqual(#r.lines, 0)
end)

test("skin verb: without the Skin major, or for an unregistered owner, skins are unavailable", function()
  local _, _, lib = env({ noSkin = true })
  local r = recorded(lib, OWNER)
  local f, why = r.O.SkinVerb(specFor({}))
  assertNil(f)
  assertEqual(why, "unavailable")
  assertEqual(count(r.lines, lib.SKIN_PICKER_STRINGS.VERB_UNAVAILABLE), 1)
  local _, _, lib2 = env()
  local r2 = recorded(lib2, "NeverRegistered")
  local _, why2 = r2.O.SkinVerb(specFor({}))
  assertEqual(why2, "unavailable")
  assertEqual(#r2.lines, 1)
end)

test("skin verb: spec.strings translate the verb's words", function()
  local m, Skin, lib = env()
  local store = register(Skin, OWNER)
  local r = recorded(lib, OWNER)
  m.InCombatLockdown = function() return true end
  r.O.SkinVerb(specFor(store, { strings = { VERB_COMBAT = "pas en combat" } }))
  m.InCombatLockdown = function() return false end
  assertEqual(r.lines[1], "pas en combat")
end)
