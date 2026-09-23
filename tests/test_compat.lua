-- tests/test_compat.lua -- LibKa0s-Compat-1.0: the version-variant readers and the secret seam.
--
-- THE CASES THAT MATTER ARE THE DEGRADED ONES. Every reader is a ladder over an API Blizzard has
-- already moved once, and the rung a live client exercises is the top one -- so every lower rung,
-- and the all-rungs-absent answer each host's degradation stub is checked against, ships untested
-- unless a case REMOVES the API. Every case here is therefore fixture-driven through `with`, which
-- installs or removes globals in the mock environment the library was loaded into; nothing under
-- test is ever stubbed (testing-§8).
--
-- NO CASE TRUSTS WHAT THE BASE MOCK HAPPENS TO CARRY. `tests/wow_mock.lua` installs the kit's
-- `mock_ids`, which fills `C_Spell.GetSpellInfo`, and `mock_base` installs the legacy spec globals.
-- So every spell and spec case installs its WHOLE `C_Spell` / `C_SpecializationInfo` table and
-- states each legacy global explicitly, present or ABSENT.
--
-- SECRET is a table whose metatable raises on every operation a real secret refuses. Lua 5.1 raises
-- on ordering a table against a number without consulting metamethods, so any `<` on it raises
-- anyway; equality ACROSS types is silent in Lua 5.1, so "never compared with a string" cannot be
-- pinned by the metatable and is pinned instead by call-order spies (the GetSpellName cases).

local T = _G.LK_TEST
local compat, core, mocks = T.compat, T.core, T.mocks
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local Loader     = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local unpack = unpack

-- -- fixtures ---------------------------------------------------------------------------------

--- Installs nil for a key in `with`: "this client does not have that API".
local ABSENT = setmetatable({}, { __tostring = function() return "ABSENT" end })

--- Run `fn` with each key of `fixture` installed in the mock environment (ABSENT removes it), then
--- restore every key and re-raise. A removed key is also cleared from the real global table for the
--- duration, because the loader falls back there: a global some other suite leaked would otherwise
--- answer in place of the absence the case asked for.
local function with(fixture, fn)
  local saved, savedG = {}, {}
  for key, value in pairs(fixture) do
    saved[key], savedG[key] = mocks[key], rawget(_G, key)
    if rawequal(value, ABSENT) then
      mocks[key] = nil
      rawset(_G, key, nil)
    else
      mocks[key] = value
    end
  end
  local ok, err = pcall(fn)
  for key in pairs(fixture) do
    mocks[key] = saved[key]
    rawset(_G, key, savedG[key])
  end
  if not ok then error(err, 0) end
end

local function raiser(what)
  return function() error("SECRET: attempted " .. what, 2) end
end

local SECRET = setmetatable({}, {
  __eq = raiser("=="), __lt = raiser("<"), __le = raiser("<="), __concat = raiser(".."),
  __len = raiser("#"), __index = raiser("index"), __newindex = raiser("assign"),
  __call = raiser("call"),
})

--- The client's own test, answering for SECRET only.
local function secretSystem(v) return rawequal(v, SECRET) end

local function pack(...) return { n = select("#", ...), ... } end

--- Every call made by a tracked function, across all of them, in order. Reset per case.
local order = {}
local function resetOrder() for i = #order, 1, -1 do order[i] = nil end end

--- Wrap `impl` so its calls are counted and its arguments recorded. Returns the function and the
--- record; every call also lands in `order`.
local function track(impl)
  local rec = { calls = 0, args = {} }
  local function fn(...)
    rec.calls = rec.calls + 1
    rec.args[rec.calls] = pack(...)
    order[#order + 1] = rec
    return impl(...)
  end
  return fn, rec
end

--- A tracked function returning exactly `...`, every time.
local function spy(...)
  local ret = pack(...)
  return track(function() return unpack(ret, 1, ret.n) end)
end

--- Assert a packed result is exactly `want` (arity and every position).
local function assertTuple(got, want, label)
  assertEqual(got.n, want.n, label .. ": arity")
  for i = 1, want.n do
    assertTrue(rawequal(got[i], want[i]),
      ("%s: position %d (expected %s, got %s)"):format(label, i, tostring(want[i]), tostring(got[i])))
  end
end

local INERT = pack(0, 0, false, 1, false)

-- -- registration and shape (3) -----------------------------------------------------------------

test("compat: registers minor 1 with exactly the nine public members", function()
  assertEqual(compat.MAJOR, "LibKa0s-Compat-1.0")
  assertEqual(compat.MINOR, 1)
  assertEqual(compat.MODULES.Compat, 1)
  local names = {}
  for _, member in ipairs(T.publicMembers(compat)) do
    assertEqual(member.kind, "function", member.name .. " kind")
    names[#names + 1] = member.name
  end
  assertEqual(table.concat(names, ","), "CanAccess,GetSpecialization,GetSpecializationInfo,"
    .. "GetSpellCooldown,GetSpellInfo,GetSpellName,GetSpellTexture,IsSafeKey,IsSecret")
end)

test("compat: the Core floor keeps the major absent from a payload without Core", function()
  local src = Loader.readFile("LibKa0s/Compat.lua")
  local bare = buildMocks()
  Loader.loadSource(src, "@LibKa0s/Compat.lua", nil, bare)
  assertNil(bare.LibStub("LibKa0s-Compat-1.0", true), "no Core: no NewLibrary")
  -- The same bytes register the moment Core is there, so the absence above is the floor and not a
  -- file that never registers at all.
  Loader.loadSource(Loader.readFile("LibKa0s/Core.lua"), "@LibKa0s/Core.lua", nil, bare)
  Loader.loadSource(src, "@LibKa0s/Compat.lua", nil, bare)
  local lib = bare.LibStub("LibKa0s-Compat-1.0", true)
  assertTrue(lib ~= nil, "with Core: registered")
  assertEqual(lib.MINOR, 1)
end)

test("compat: the source reads every global bare, never through the global table", function()
  -- An explicit global-table read steps around the kit's mock, so a ladder reached that way tests
  -- a client nobody runs and every degraded case below would pass against the real process globals.
  local src = Loader.readFile("LibKa0s/Compat.lua")
  assertFalse(src:find("_G.", 1, true), "Compat.lua reads a global through `_G.`")
  assertFalse(src:find("_G[", 1, true), "Compat.lua reads a global through `_G[`")
end)

-- -- the secret seam (10) -----------------------------------------------------------------------

test("compat: IsSecret is false for every value when the client has no secrets system", function()
  with({ issecretvalue = ABSENT }, function()
    for _, v in ipairs({ 0, "x", {}, true }) do
      assertTuple(pack(compat.IsSecret(v)), pack(false), "IsSecret(" .. type(v) .. ")")
    end
    assertTuple(pack(compat.IsSecret(nil)), pack(false), "IsSecret(nil)")
  end)
end)

test("compat: IsSecret asks the client's own test", function()
  with({ issecretvalue = secretSystem }, function()
    assertEqual(compat.IsSecret(SECRET), true)
    assertEqual(compat.IsSecret(300), false)
  end)
end)

test("compat: IsSecret normalizes a truthy non-boolean answer to true", function()
  with({ issecretvalue = function() return 1 end }, function()
    assertTuple(pack(compat.IsSecret(300)), pack(true), "issecretvalue answering 1")
  end)
  with({ issecretvalue = function() return nil end }, function()
    assertTuple(pack(compat.IsSecret(300)), pack(false), "issecretvalue answering nil")
  end)
end)

test("compat: CanAccess asks canaccessvalue where it exists", function()
  with({
    issecretvalue = secretSystem,
    canaccessvalue = function(v) return not rawequal(v, SECRET) end,
  }, function()
    assertTuple(pack(compat.CanAccess(SECRET)), pack(false), "CanAccess(SECRET)")
    assertTuple(pack(compat.CanAccess(300)), pack(true), "CanAccess(300)")
  end)
end)

test("compat: CanAccess without canaccessvalue is 'accessible unless secret'", function()
  with({ issecretvalue = secretSystem, canaccessvalue = ABSENT }, function()
    assertEqual(compat.CanAccess(SECRET), false)
    assertEqual(compat.CanAccess(300), true)
  end)
end)

test("compat: CanAccess with neither global answers true, nil included", function()
  with({ issecretvalue = ABSENT, canaccessvalue = ABSENT }, function()
    assertEqual(compat.CanAccess(300), true)
    assertEqual(compat.CanAccess(nil), true)
  end)
end)

test("compat: a secret that is accessible is still not a safe key", function()
  -- IsSafeKey is IsSecret and NOT CanAccess: the key restriction is about the value being secret at
  -- all. Built on CanAccess, this value would be keyed on and raise on the indexed assignment.
  with({ issecretvalue = secretSystem, canaccessvalue = function() return true end }, function()
    assertEqual(compat.CanAccess(SECRET), true)
    assertEqual(compat.IsSecret(SECRET), true)
    assertEqual(compat.IsSafeKey(SECRET), false)
  end)
end)

test("compat: IsSafeKey(nil) is false with and without the secrets system", function()
  with({ issecretvalue = ABSENT }, function()
    assertTuple(pack(compat.IsSafeKey(nil)), pack(false), "no system")
  end)
  with({ issecretvalue = secretSystem }, function()
    assertTuple(pack(compat.IsSafeKey(nil)), pack(false), "with the system")
  end)
end)

test("compat: IsSafeKey is true for plain values, and v ~= nil with no system", function()
  with({ issecretvalue = secretSystem }, function()
    for _, v in ipairs({ 0, 774, "Player-1-0A", false }) do
      assertTuple(pack(compat.IsSafeKey(v)), pack(true), "IsSafeKey(" .. tostring(v) .. ")")
    end
  end)
  with({ issecretvalue = ABSENT }, function()
    assertEqual(compat.IsSafeKey(SECRET), true, "no system: nothing is secret")
    assertEqual(compat.IsSafeKey(false), true)
    assertEqual(compat.IsSafeKey(nil), false)
  end)
end)

test("compat: Core's concat probe answers a different question and is not duplicated", function()
  -- Pinned so nobody later "deduplicates" the two: concat rejects a boolean that is not secret, and
  -- Core's probe never asks the client's secrets test.
  local fn, rec = track(secretSystem)
  with({ issecretvalue = fn }, function()
    assertEqual(core.IsConcatSafe(true), false)
    assertEqual(compat.IsSecret(true), false)
    local calls = rec.calls
    assertEqual(core.IsConcatSafe(SECRET), false)
    assertEqual(rec.calls, calls, "IsConcatSafe consulted issecretvalue")
    assertEqual(compat.IsSecret(SECRET), true)
  end)
end)

-- -- GetSpellInfo (7) ---------------------------------------------------------------------------

local function rejuv()
  return { name = "Rejuvenation", iconID = 136081, castTime = 0, minRange = 0, maxRange = 40,
    spellID = 774, originalIconID = 136081 }
end

test("compat: GetSpellInfo flattens C_Spell's table into exactly six values", function()
  local legacy, legacyRec = spy("Legacy", "Rank 1", 1)
  with({ C_Spell = { GetSpellInfo = rejuv }, GetSpellInfo = legacy }, function()
    assertTuple(pack(compat.GetSpellInfo(774)), pack("Rejuvenation", 136081, 0, 0, 40, 774), "modern")
  end)
  assertEqual(legacyRec.calls, 0)
end)

test("compat: GetSpellInfo's modern rung is authoritative when it answers nil", function()
  local legacy, legacyRec = spy("Legacy", "Rank 1", 999, 1.5, 0, 30, 774)
  with({ C_Spell = { GetSpellInfo = function() return nil end }, GetSpellInfo = legacy }, function()
    assertTuple(pack(compat.GetSpellInfo(774)), pack(nil), "modern nil")
  end)
  assertEqual(legacyRec.calls, 0, "the legacy global was consulted after an authoritative nil")
end)

test("compat: GetSpellInfo remaps the legacy global's real shape, dropping the rank", function()
  -- Red under reading the second return (the rank) as the icon, which two of the copies shipped.
  local legacy = spy("Legacy", "Rank 1", 999, 1.5, 0, 30, 774, 998)
  with({ C_Spell = ABSENT, GetSpellInfo = legacy }, function()
    assertTuple(pack(compat.GetSpellInfo(774)), pack("Legacy", 999, 1.5, 0, 30, 774), "legacy")
  end)
end)

test("compat: GetSpellInfo answers a single nil when neither rung exists", function()
  with({ C_Spell = ABSENT, GetSpellInfo = ABSENT }, function()
    assertTuple(pack(compat.GetSpellInfo(774)), pack(nil), "all absent")
  end)
end)

test("compat: GetSpellInfo takes a number or a string and calls no rung for anything else", function()
  local modern, rec = spy(nil)
  with({ C_Spell = { GetSpellInfo = modern }, GetSpellInfo = ABSENT }, function()
    assertTuple(pack(compat.GetSpellInfo(nil)), pack(nil), "nil id")
    assertTuple(pack(compat.GetSpellInfo({})), pack(nil), "table id")
    assertTuple(pack(compat.GetSpellInfo(true)), pack(nil), "boolean id")
    assertEqual(rec.calls, 0, "a rung was called for an identifier outside the domain")
    compat.GetSpellInfo("Kick")
    assertEqual(rec.calls, 1)
    assertTuple(rec.args[1], pack("Kick"), "the string reaches the client verbatim")
  end)
end)

test("compat: GetSpellInfo passes a secret field through untouched", function()
  local info = rejuv()
  info.name = SECRET
  with({ issecretvalue = secretSystem, C_Spell = { GetSpellInfo = function() return info end } },
    function()
      local got = pack(compat.GetSpellInfo(774))
      assertEqual(got.n, 6)
      assertTrue(rawequal(got[1], SECRET), "the secret name was not returned as-is")
    end)
end)

test("compat: GetSpellInfo answers a single nil when the legacy global has no name", function()
  with({ C_Spell = ABSENT, GetSpellInfo = spy(nil, "Rank 1", 999) }, function()
    assertTuple(pack(compat.GetSpellInfo(774)), pack(nil), "legacy nil name")
  end)
end)

-- -- GetSpellName (8) ---------------------------------------------------------------------------

test("compat: GetSpellName answers from C_Spell.GetSpellName first", function()
  local mid, midRec = spy({ name = "Middle" })
  local legacy, legacyRec = spy("Legacy")
  with({ C_Spell = { GetSpellName = spy("Kick"), GetSpellInfo = mid }, GetSpellInfo = legacy },
    function()
      assertTuple(pack(compat.GetSpellName(1766)), pack("Kick"), "top rung")
    end)
  assertEqual(midRec.calls + legacyRec.calls, 0, "a later rung was consulted after an answer")
end)

test("compat: GetSpellName falls to C_Spell.GetSpellInfo's name when the top rung is nil", function()
  local legacy, legacyRec = spy("Legacy")
  with({
    C_Spell = { GetSpellName = spy(nil), GetSpellInfo = spy({ name = "Middle" }) },
    GetSpellInfo = legacy,
  }, function()
    assertEqual(compat.GetSpellName(1766), "Middle")
  end)
  assertEqual(legacyRec.calls, 0)
end)

test("compat: GetSpellName treats a plain empty string as no answer", function()
  with({
    C_Spell = { GetSpellName = spy(""), GetSpellInfo = spy({ name = "Middle" }) },
    GetSpellInfo = ABSENT,
  }, function()
    assertEqual(compat.GetSpellName(1766), "Middle")
  end)
  with({
    C_Spell = { GetSpellName = spy(""), GetSpellInfo = spy({ name = "" }) },
    GetSpellInfo = spy(""),
  }, function()
    assertTuple(pack(compat.GetSpellName(1766)), pack(nil), "every rung empty")
  end)
end)

test("compat: GetSpellName reads C_Spell.GetSpellInfo when C_Spell.GetSpellName is absent", function()
  with({ C_Spell = { GetSpellInfo = spy({ name = "Middle" }) }, GetSpellInfo = ABSENT }, function()
    assertEqual(compat.GetSpellName(1766), "Middle")
  end)
end)

test("compat: GetSpellName on the legacy global returns its first value only", function()
  with({ C_Spell = ABSENT, GetSpellInfo = spy("Legacy", "Rank 1", 999, 1.5) }, function()
    assertTuple(pack(compat.GetSpellName(1766)), pack("Legacy"), "legacy")
  end)
end)

test("compat: GetSpellName answers nil when no rung exists", function()
  with({ C_Spell = ABSENT, GetSpellInfo = ABSENT }, function()
    assertTuple(pack(compat.GetSpellName(1766)), pack(nil), "all absent")
  end)
end)

test("compat: GetSpellName returns a secret untouched and asks IsSecret before anything else", function()
  -- The ordering is the pin. Lua 5.1 compares a table with a string silently, so the metatable
  -- alone cannot prove the secret never met `""`; the call order can. On the client, a secret
  -- compared with "" raises in combat, which is the defect one copy shipped.
  local top, topRec = track(function() return SECRET end)
  local secretFn, secretRec = track(secretSystem)
  local mid, midRec = spy({ name = "Middle" })
  local legacy, legacyRec = spy("Legacy")
  resetOrder()
  with({
    issecretvalue = secretFn,
    C_Spell = { GetSpellName = top, GetSpellInfo = mid },
    GetSpellInfo = legacy,
  }, function()
    assertTrue(rawequal(compat.GetSpellName(1766), SECRET), "the secret was not returned as-is")
  end)
  assertEqual(#order, 2, "calls after the top rung answered a secret")
  assertTrue(order[1] == topRec and order[2] == secretRec, "IsSecret was not asked first")
  assertTrue(rawequal(secretRec.args[1][1], SECRET), "IsSecret was asked about another value")
  assertEqual(midRec.calls + legacyRec.calls, 0)
  -- A secret ENDS the ladder even when its plain spelling would be "" -- it is never compared.
  with({
    issecretvalue = function(v) return v == "" end,
    C_Spell = { GetSpellName = spy(""), GetSpellInfo = spy({ name = "Middle" }) },
  }, function()
    assertEqual(compat.GetSpellName(1766), "", "a secret empty string fell through")
  end)
end)

test("compat: GetSpellName(nil) answers nil and calls no rung", function()
  local top, rec = spy("Kick")
  with({ C_Spell = { GetSpellName = top }, GetSpellInfo = ABSENT }, function()
    assertTuple(pack(compat.GetSpellName(nil)), pack(nil), "nil id")
  end)
  assertEqual(rec.calls, 0)
end)

-- -- GetSpellTexture (4) ------------------------------------------------------------------------

test("compat: GetSpellTexture returns one value, dropping the client's original icon", function()
  with({ C_Spell = { GetSpellTexture = spy(111, 222) }, GetSpellTexture = ABSENT }, function()
    assertTuple(pack(compat.GetSpellTexture(774)), pack(111), "modern")
  end)
end)

test("compat: GetSpellTexture's modern rung is authoritative when it answers nil", function()
  local legacy, rec = spy(333)
  with({ C_Spell = { GetSpellTexture = spy(nil) }, GetSpellTexture = legacy }, function()
    assertTuple(pack(compat.GetSpellTexture(774)), pack(nil), "modern nil")
  end)
  assertEqual(rec.calls, 0)
end)

test("compat: GetSpellTexture falls back to the legacy global, one value", function()
  with({ C_Spell = ABSENT, GetSpellTexture = spy(333, 444) }, function()
    assertTuple(pack(compat.GetSpellTexture(774)), pack(333), "legacy")
  end)
end)

test("compat: GetSpellTexture answers nil with no rung, and for a nil id calls none", function()
  with({ C_Spell = ABSENT, GetSpellTexture = ABSENT }, function()
    assertTuple(pack(compat.GetSpellTexture(774)), pack(nil), "all absent")
  end)
  local modern, rec = spy(111)
  with({ C_Spell = { GetSpellTexture = modern }, GetSpellTexture = ABSENT }, function()
    assertTuple(pack(compat.GetSpellTexture(nil)), pack(nil), "nil id")
  end)
  assertEqual(rec.calls, 0)
end)

-- -- GetSpellCooldown (9) -----------------------------------------------------------------------

local function cooldown(info)
  return { C_Spell = { GetSpellCooldown = function() return info end }, GetSpellCooldown = ABSENT }
end

test("compat: GetSpellCooldown returns the modern table's five values in order", function()
  with(cooldown({ startTime = 100, duration = 8, isEnabled = true, modRate = 1.5, isActive = true }),
    function()
      assertTuple(pack(compat.GetSpellCooldown(1766)), pack(100, 8, true, 1.5, true), "modern")
    end)
end)

test("compat: GetSpellCooldown reads a missing isEnabled as true and only true as active", function()
  with(cooldown({ startTime = 1, duration = 2, modRate = 1 }), function()
    assertTuple(pack(compat.GetSpellCooldown(1766)), pack(1, 2, true, 1, false), "flags missing")
  end)
  with(cooldown({ startTime = 1, duration = 2, modRate = 1, isEnabled = true, isActive = 1 }),
    function()
      assertTuple(pack(compat.GetSpellCooldown(1766)), pack(1, 2, true, 1, false), "isActive = 1")
    end)
end)

test("compat: GetSpellCooldown answers the inert tuple for a nil info table", function()
  local legacy, rec = spy(5, 12, true, 1)
  with({ C_Spell = { GetSpellCooldown = spy(nil) }, GetSpellCooldown = legacy }, function()
    assertTuple(pack(compat.GetSpellCooldown(1766)), INERT, "nil info")
  end)
  assertEqual(rec.calls, 0, "the legacy global was consulted after an authoritative nil")
end)

test("compat: GetSpellCooldown passes secret timings through without touching them", function()
  local fixture = cooldown({ startTime = SECRET, duration = SECRET, isEnabled = true, modRate = 1,
    isActive = true })
  fixture.issecretvalue = secretSystem
  with(fixture, function()
    local got = pack(compat.GetSpellCooldown(1766))
    assertEqual(got.n, 5)
    assertTrue(rawequal(got[1], SECRET) and rawequal(got[2], SECRET), "timings not returned as-is")
    assertEqual(got[5], true)
  end)
end)

test("compat: GetSpellCooldown derives isActive on the legacy global", function()
  with({ C_Spell = {}, GetSpellCooldown = spy(5, 12, true, 1) }, function()
    assertTuple(pack(compat.GetSpellCooldown(1766)), pack(5, 12, true, 1, true), "legacy")
  end)
end)

test("compat: GetSpellCooldown reads a zero legacy duration as not active", function()
  with({ C_Spell = {}, GetSpellCooldown = spy(0, 0, true, 1) }, function()
    assertTuple(pack(compat.GetSpellCooldown(1766)), pack(0, 0, true, 1, false), "zero duration")
  end)
end)

test("compat: GetSpellCooldown reads a legacy isEnabled of 0 or false as disabled", function()
  -- The legacy global answered 1 / 0. One copy read 0 as enabled (`e ~= false`); 0 is disabled.
  local cases = { { 0, false }, { false, false }, { 1, true }, { true, true }, { nil, true } }
  for _, c in ipairs(cases) do
    with({ C_Spell = {}, GetSpellCooldown = spy(5, 12, c[1], 1) }, function()
      local _, _, enabled = compat.GetSpellCooldown(1766)
      assertEqual(enabled, c[2], "isEnabled for a legacy " .. tostring(c[1]))
    end)
  end
end)

test("compat: GetSpellCooldown never orders a secret legacy duration", function()
  -- Two shapes. SECRET raises on any ordering; a plain number the fixture calls secret is what
  -- proves the IsSecret gate is there at all -- without it `12 > 0` is simply true.
  with({ issecretvalue = secretSystem, C_Spell = {}, GetSpellCooldown = spy(5, SECRET, true, 1) },
    function()
      local got = pack(compat.GetSpellCooldown(1766))
      assertTrue(rawequal(got[2], SECRET), "the duration was not returned as-is")
      assertEqual(got[5], false)
    end)
  with({
    issecretvalue = function(v) return v == 12 end,
    C_Spell = {},
    GetSpellCooldown = spy(5, 12, true, 1),
  }, function()
    local _, d, _, _, active = compat.GetSpellCooldown(1766)
    assertEqual(d, 12)
    assertEqual(active, false, "a secret duration was compared with 0")
  end)
end)

test("compat: GetSpellCooldown is inert with no rung and calls none for a bad id", function()
  with({ C_Spell = ABSENT, GetSpellCooldown = ABSENT }, function()
    assertTuple(pack(compat.GetSpellCooldown(1766)), INERT, "all absent")
  end)
  local modern, rec = spy({ startTime = 1, duration = 2 })
  with({ C_Spell = { GetSpellCooldown = modern }, GetSpellCooldown = ABSENT }, function()
    assertTuple(pack(compat.GetSpellCooldown(nil)), INERT, "nil id")
    assertTuple(pack(compat.GetSpellCooldown({})), INERT, "table id")
  end)
  assertEqual(rec.calls, 0)
end)

-- -- specialization (6) -------------------------------------------------------------------------

test("compat: GetSpecialization prefers the namespaced reader, even its nil, one value", function()
  local legacy, rec = spy(1)
  with({
    C_SpecializationInfo = { GetSpecialization = spy(2, "extra") },
    GetSpecialization = legacy,
  }, function()
    assertTuple(pack(compat.GetSpecialization()), pack(2), "namespaced")
  end)
  -- And authoritative: a namespaced nil (no spec chosen yet) is the answer, not a cue to ask the
  -- deprecated global, which would answer for a client state the namespaced reader already denied.
  with({
    C_SpecializationInfo = { GetSpecialization = spy(nil) },
    GetSpecialization = legacy,
  }, function()
    assertTuple(pack(compat.GetSpecialization()), pack(nil), "namespaced nil")
  end)
  assertEqual(rec.calls, 0, "the global was consulted after an authoritative nil")
end)

test("compat: GetSpecialization falls back to the global, one value", function()
  with({ C_SpecializationInfo = ABSENT, GetSpecialization = spy(3, "extra") }, function()
    assertTuple(pack(compat.GetSpecialization()), pack(3), "global")
  end)
end)

test("compat: GetSpecialization answers nil when neither reader exists", function()
  with({ C_SpecializationInfo = ABSENT, GetSpecialization = ABSENT }, function()
    assertTuple(pack(compat.GetSpecialization()), pack(nil), "all absent")
  end)
end)

test("compat: GetSpecializationInfo passes the namespaced multi-return through exactly", function()
  local six = pack(250, "Blood", "A tank.", 135770, "TANK", 1)
  with({
    C_SpecializationInfo = { GetSpecializationInfo = spy(unpack(six, 1, six.n)) },
    GetSpecializationInfo = ABSENT,
  }, function()
    assertTuple(pack(compat.GetSpecializationInfo(1)), six, "namespaced")
  end)
end)

test("compat: GetSpecializationInfo uses the global only when the namespaced reader is absent", function()
  with({ C_SpecializationInfo = ABSENT, GetSpecializationInfo = spy(251, "Frost") }, function()
    assertTuple(pack(compat.GetSpecializationInfo(2)), pack(251, "Frost"), "global")
  end)
  local legacy, rec = spy(251, "Frost")
  with({
    C_SpecializationInfo = { GetSpecializationInfo = spy(nil) },
    GetSpecializationInfo = legacy,
  }, function()
    assertNil(compat.GetSpecializationInfo(2))
  end)
  assertEqual(rec.calls, 0, "the global was consulted after an authoritative nil")
end)

test("compat: GetSpecializationInfo(nil) calls no reader, and nil when none exists", function()
  local ns, nsRec = spy(250, "Blood")
  local legacy, legacyRec = spy(250, "Blood")
  with({ C_SpecializationInfo = { GetSpecializationInfo = ns }, GetSpecializationInfo = legacy },
    function()
      assertTuple(pack(compat.GetSpecializationInfo(nil)), pack(nil), "nil index")
    end)
  assertEqual(nsRec.calls + legacyRec.calls, 0)
  with({ C_SpecializationInfo = ABSENT, GetSpecializationInfo = ABSENT }, function()
    assertTuple(pack(compat.GetSpecializationInfo(1)), pack(nil), "all absent")
  end)
end)

-- -- the absent table (1) -----------------------------------------------------------------------

--- Every member's answer on a client with NO rung at all. Copied verbatim into
--- docs/api/Compat/version-1-docs.md's "absent" column: it is the reference a host's degradation
--- stub is checked against -- readers answer exactly this, guards re-implement their body.
local ABSENT_ANSWERS = {
  { member = "IsSecret",              args = pack(300),  answer = pack(false) },
  { member = "CanAccess",             args = pack(300),  answer = pack(true) },
  { member = "IsSafeKey",             args = pack(300),  answer = pack(true) },
  { member = "IsSafeKey",             args = pack(nil),  answer = pack(false) },
  { member = "GetSpellInfo",          args = pack(774),  answer = pack(nil) },
  { member = "GetSpellName",          args = pack(774),  answer = pack(nil) },
  { member = "GetSpellTexture",       args = pack(774),  answer = pack(nil) },
  { member = "GetSpellCooldown",      args = pack(774),  answer = pack(0, 0, false, 1, false) },
  { member = "GetSpecialization",     args = pack(),     answer = pack(nil) },
  { member = "GetSpecializationInfo", args = pack(1),    answer = pack(nil) },
}

test("compat: with every rung removed each member answers the documented absent value", function()
  with({
    C_Spell = ABSENT, C_SpecializationInfo = ABSENT,
    GetSpellInfo = ABSENT, GetSpellTexture = ABSENT, GetSpellCooldown = ABSENT,
    GetSpecialization = ABSENT, GetSpecializationInfo = ABSENT,
    issecretvalue = ABSENT, canaccessvalue = ABSENT,
  }, function()
    local covered = {}
    for _, row in ipairs(ABSENT_ANSWERS) do
      local got = pack(compat[row.member](unpack(row.args, 1, row.args.n)))
      assertTuple(got, row.answer, row.member)
      covered[row.member] = true
    end
    for _, member in ipairs(T.publicMembers(compat)) do
      assertTrue(covered[member.name], member.name .. " has no row in the absent table")
    end
  end)
end)

-- -- the shared table (1) -----------------------------------------------------------------------

test("compat: a host patching the shared table does not change another member's answer", function()
  -- Every addon that loaded this copy shares the LibStub table. Internal calls go through file
  -- locals, so one host replacing `IsSecret` on it cannot change what GetSpellName answers for the
  -- rest -- reached through the table, this would return "Middle" instead of the secret.
  local saved = compat.IsSecret
  compat.IsSecret = function() return false end
  local ok, err = pcall(with, {
    issecretvalue = function(v) return v == "" end,
    C_Spell = { GetSpellName = spy(""), GetSpellInfo = spy({ name = "Middle" }) },
  }, function()
    assertEqual(compat.GetSpellName(1766), "")
  end)
  compat.IsSecret = saved
  if not ok then error(err, 0) end
end)
