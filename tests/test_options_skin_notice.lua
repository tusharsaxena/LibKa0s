-- tests/test_options_skin_notice.lua -- O.SkinNotice (OptionsSkinPicker.lua minor 9, SG-L3 of
-- Ka0sAddonsCommonTasks docs/2026-11-01-SMOKE_FEEDBACK): the one-time announcement of the skin
-- picker, once per account. The first addon to ask in a session claims it and shows the picker;
-- every other addon records the version and stays quiet; a recorded version passes it by.

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = K.test, K.assertEqual, K.assertTrue, K.assertNil
local Bench = dofile("tests/fixture_skin_picker.lua")
local OWNER, OTHER = Bench.OWNER, Bench.OTHER
local env, register, instance, specFor = Bench.env, Bench.register, Bench.instance, Bench.specFor

local function cell(v)
  local c = { v = v, writes = 0 }
  c.store = { get = function() return c.v end, set = function(x) c.v = x; c.writes = c.writes + 1 end }
  return c
end

test("skin notice: the first addon claims it and shows the picker, the next records and stays quiet", function()
  -- red under: a claim per addon, which shows the picker once for every addon on the account.
  local _, Skin, lib = env()
  local a, b = register(Skin, OWNER), register(Skin, OTHER)
  local Oa, Ob = instance(lib, OWNER), instance(lib, OTHER)
  local ca, cb = cell(nil), cell(nil)
  local f = Oa.SkinNotice(specFor(a), ca.store)
  assertTrue(f ~= nil and f:IsShown(), "the claimant shows it")
  assertEqual(ca.v, lib.SKIN_NOTICE_VERSION)
  local g, why = Ob.SkinNotice(specFor(b), cb.store)
  assertNil(g)
  assertEqual(why, "claimed")
  assertEqual(cb.v, lib.SKIN_NOTICE_VERSION, "recorded in its own store")
end)

test("skin notice: a recorded version passes it by, and a higher notice version shows it again", function()
  -- red under: a boolean flag, which a later release could not re-announce with.
  local _, Skin, lib = env()
  local a = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local c = cell(lib.SKIN_NOTICE_VERSION)
  local f, why = O.SkinNotice(specFor(a), c.store)
  assertNil(f)
  assertEqual(why, "seen")
  assertEqual(c.writes, 0)
  c.v = lib.SKIN_NOTICE_VERSION - 1
  local g = O.SkinNotice(specFor(a), c.store)
  assertTrue(g ~= nil, "an older record shows it")
end)

test("skin notice: in combat nothing is claimed or recorded, and the next ask after it shows", function()
  -- red under: claiming in combat, which loses the notice for the whole session.
  local m, Skin, lib = env()
  local a = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local c = cell(nil)
  m.InCombatLockdown = function() return true end
  local f, why = O.SkinNotice(specFor(a), c.store)
  assertNil(f)
  assertEqual(why, "combat")
  assertEqual(c.writes, 0)
  m.InCombatLockdown = function() return false end
  assertTrue(O.SkinNotice(specFor(a), c.store) ~= nil)
end)

test("skin notice: a store without both halves is refused", function()
  local _, Skin, lib = env()
  local a = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f, why = O.SkinNotice(specFor(a), { get = function() end })
  assertNil(f)
  assertEqual(why, "unavailable")
end)
