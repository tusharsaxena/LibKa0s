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

-- The first ask waits for login to settle (nil, "queued"); the timer's pass is the real one.
local function settle(m) m.__now = (m.__now or 0) + 10; m.__fireTimers() end

test("skin notice: the first addon claims it and shows the picker, the next records and stays quiet", function()
  -- red under: a claim per addon, which shows the picker once for every addon on the account.
  local m, Skin, lib = env()
  local a, b = register(Skin, OWNER), register(Skin, OTHER)
  local Oa, Ob = instance(lib, OWNER), instance(lib, OTHER)
  local ca, cb = cell(nil), cell(nil)
  local f, why = Oa.SkinNotice(specFor(a), ca.store)
  assertNil(f)
  assertEqual(why, "queued", "the show waits for login to settle")
  assertEqual(ca.writes, 0)
  local g, why2 = Ob.SkinNotice(specFor(b), cb.store)
  assertNil(g)
  assertEqual(why2, "queued")
  settle(m)
  assertEqual(ca.v, lib.SKIN_NOTICE_VERSION)
  assertTrue(Oa.__noticePending == nil and Ob.__noticePending == nil, "no timer left pending")
  assertEqual(cb.v, lib.SKIN_NOTICE_VERSION, "recorded in its own store, not shown a second time")
  assertEqual(lib.__noticeClaimed, lib.SKIN_NOTICE_VERSION)
end)

test("skin notice: an addon that has seen it silences one that loaded before it (SG-L3)", function()
  -- red under: 'seen' claimed nothing, so the first addon to load showed it again.
  local m, Skin, lib = env()
  local a, b = register(Skin, OWNER), register(Skin, OTHER)
  local Oa, Ob = instance(lib, OWNER), instance(lib, OTHER)
  local ca, cb = cell(nil), cell(lib.SKIN_NOTICE_VERSION)
  local shown, real = 0, Oa.SkinPicker
  Oa.SkinPicker = function(...) shown = shown + 1; return real(...) end
  local _, why = Oa.SkinNotice(specFor(a), ca.store)
  assertEqual(why, "queued")
  local _, why2 = Ob.SkinNotice(specFor(b), cb.store)
  assertEqual(why2, "seen")
  settle(m)
  assertEqual(ca.v, lib.SKIN_NOTICE_VERSION, "recorded, never shown")
  assertEqual(shown, 0, "no window")
end)

test("skin notice: a stood-down host records what it can and shows nothing", function()
  local _, Skin, lib = env()
  local a = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local c = cell(nil)
  local f, why = O.SkinNotice(specFor(a), c.store, true)
  assertNil(f)
  assertEqual(why, "standdown")
  assertEqual(c.writes, 0)
  local seen = cell(lib.SKIN_NOTICE_VERSION)
  local _, why2 = O.SkinNotice(specFor(a), seen.store, true)
  assertEqual(why2, "seen")
  assertEqual(lib.__noticeClaimed, lib.SKIN_NOTICE_VERSION, "a seen stood-down addon still silences the rest")
  local _, why3 = O.SkinNotice(specFor(a), c.store, true)
  assertEqual(why3, "claimed")
  assertEqual(c.v, lib.SKIN_NOTICE_VERSION)
end)

test("skin notice: a recorded version passes it by, and a higher notice version shows it again", function()
  -- red under: a boolean flag, which a later release could not re-announce with.
  local m, Skin, lib = env()
  local a = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local c = cell(lib.SKIN_NOTICE_VERSION)
  local f, why = O.SkinNotice(specFor(a), c.store)
  assertNil(f)
  assertEqual(why, "seen")
  assertEqual(c.writes, 0)
  lib.__noticeClaimed = nil
  c.v = lib.SKIN_NOTICE_VERSION - 1
  local _, why2 = O.SkinNotice(specFor(a), c.store)
  assertEqual(why2, "queued", "an older record shows it, once login settles")
  settle(m)
  assertEqual(c.v, lib.SKIN_NOTICE_VERSION)
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
  local _, why2 = O.SkinNotice(specFor(a), c.store)
  assertEqual(why2, "queued")
  -- Combat starts inside the settle: the timer asks again, nothing is lost.
  m.InCombatLockdown = function() return true end
  settle(m)
  assertEqual(c.writes, 0)
  assertTrue(O.__noticePending, "still pending, retrying")
  m.InCombatLockdown = function() return false end
  settle(m)
  assertEqual(c.v, lib.SKIN_NOTICE_VERSION)
end)

test("skin notice: a store without both halves is refused", function()
  local _, Skin, lib = env()
  local a = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f, why = O.SkinNotice(specFor(a), { get = function() end })
  assertNil(f)
  assertEqual(why, "unavailable")
end)
