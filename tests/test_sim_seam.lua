-- tests/test_sim_seam.lua — LibKa0s-Sim-1.0's Compat answer seam, `Sim:NewSeam(compat, opts)`.
--
-- Every case runs on a fresh environment with Core and Sim loaded and a fresh host Compat table,
-- the way a host's setup file wraps its own NS.Compat straight after the Compat files load.
--
-- Only the IDLE seam is pinned here: no session binds a seam until `Sim:New` lands (the next
-- commit of this release), and the plan's review ruled out a test-only hook that would flip the
-- active flag by hand. Every active-path case (providers handed the fallback, a guarded member
-- never reaching live, `Live` answering live under an active session, bypass restored after a
-- raise) is written against a real session in tests/test_sim_session.lua's seam cases.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local Loader = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local MAJOR = "LibKa0s-Sim-1.0"

--- A fresh environment with Core and Sim loaded.
local function env()
  local m = buildMocks()
  Loader.load("LibKa0s/Core.lua", nil, m)
  Loader.load("LibKa0s/Sim.lua", nil, m)
  return m, m.LibStub(MAJOR)
end

--- A host Compat table: four client readers, two pure helpers, one guarded sender and a constant.
--- `calls` records each live member's name as it runs.
local function compatFixture()
  local calls = {}
  local function rec(name, fn)
    return function(...) calls[#calls + 1] = name; return fn(...) end
  end
  local C = {
    UnitName = rec("UnitName", function(unit) return "live-" .. tostring(unit) end),
    ZoneText = rec("ZoneText", function() return "Dornogal" end),
    Pair = rec("Pair", function(a, b) return a, b end),
    Holes = rec("Holes", function() return nil, 2, nil end),
    ChatSender = rec("ChatSender", function() return "real-sender" end),
    IsSecret = function() return false end,
    FormatToPattern = function(s) return s end,
    VERSION = 3,
  }
  return C, calls
end

local PURE = { IsSecret = true, FormatToPattern = true }

--- A seam over a fresh fixture. `extra` is merged into the opts.
local function seamOver(extra)
  local _, Sim = env()
  local C, calls = compatFixture()
  local opts = { name = "Host", pure = PURE, guarded = { ChatSender = function() return "guarded" end } }
  for k, v in pairs(extra or {}) do opts[k] = v end
  return Sim:NewSeam(C, opts), C, calls, Sim
end

--- The error a call raised, or nil when it did not raise.
local function raised(fn, ...)
  local ok, err = pcall(fn, ...)
  if ok then return nil end
  return err
end

local function joined(list) return table.concat(list, ",") end

-- ── the major ────────────────────────────────────────────────────────────────────────────

test("sim seam: the major registers with Core, and reports its file minor", function()
  local _, Sim = env()
  assertTrue(Sim ~= nil, MAJOR .. " registered")
  assertEqual(Sim.MAJOR, MAJOR)
  assertEqual(Sim.MODULES.Sim, Sim.MINOR, "the file reports its own live version")
  assertEqual(type(Sim.NewSeam), "function")
end)

test("sim seam: the module is absent without Core", function()
  local m = buildMocks()
  Loader.load("LibKa0s/Sim.lua", nil, m)
  assertNil(m.LibStub(MAJOR, true), "no NewLibrary without LibKa0s-Core-1.0")
end)

test("sim seam: the seam carries exactly SetProvider, Live, Keys and Unwrapped", function()
  local seam = seamOver()
  local names = {}
  for k, v in pairs(seam) do
    assertEqual(type(v), "function", "seam member " .. tostring(k))
    names[#names + 1] = k
  end
  table.sort(names)
  assertEqual(joined(names), "Keys,Live,SetProvider,Unwrapped",
    "no active-state query, no guarded-key query (OWNER_SCOPE C.7)")
  assertNil(getmetatable(seam), "the seam carries no metatable")
end)

-- ── NewSeam ──────────────────────────────────────────────────────────────────────────────

test("sim seam: every non-pure function is wrapped, and Keys() is sorted", function()
  local seam, C = seamOver()
  assertEqual(joined(seam:Keys()), "ChatSender,Holes,Pair,UnitName,ZoneText")
  assertEqual(C.VERSION, 3, "a non-function member is left alone")
  assertEqual(C.IsSecret(), false)
  assertNil(getmetatable(C), "the host table gets no metatable (no auto-wrap)")
end)

test("sim seam: pure members are the host's own functions, untouched", function()
  local _, Sim = env()
  local C = compatFixture()
  local isSecret, fmt = C.IsSecret, C.FormatToPattern
  Sim:NewSeam(C, { name = "Host", pure = PURE })
  assertTrue(rawequal(C.IsSecret, isSecret), "IsSecret not wrapped")
  assertTrue(rawequal(C.FormatToPattern, fmt), "FormatToPattern not wrapped")
end)

test("sim seam: Keys() answers a fresh copy each call", function()
  local seam = seamOver()
  local a = seam:Keys()
  a[1] = "Tampered"
  assertEqual(seam:Keys()[1], "ChatSender")
end)

test("sim seam: NewSeam refuses a bad compat, a missing name and bad opts", function()
  local _, Sim = env()
  assertTrue(raised(function() Sim:NewSeam(nil, { name = "Host" }) end) ~= nil, "nil compat")
  assertTrue(raised(function() Sim:NewSeam({}, nil) end) ~= nil, "nil opts")
  assertTrue(raised(function() Sim:NewSeam({}, {}) end) ~= nil, "no name")
  assertTrue(raised(function() Sim:NewSeam({}, { name = "" }) end) ~= nil, "empty name")
  assertTrue(raised(function() Sim:NewSeam({}, { name = "H", debug = "print" }) end) ~= nil,
    "a debug sink that is not a function")
end)

test("sim seam: a guarded key must be a wrapped member, and its answer a function", function()
  local _, Sim = env()
  local err = raised(function()
    Sim:NewSeam(compatFixture(), { name = "Host", pure = PURE, guarded = { ChatSendr = function() end } })
  end)
  assertTrue(err ~= nil and tostring(err):find("ChatSendr", 1, true) ~= nil, "a typo is named")
  assertTrue(raised(function()
    Sim:NewSeam(compatFixture(), { name = "Host", pure = PURE, guarded = { IsSecret = function() end } })
  end) ~= nil, "a pure key cannot be guarded")
  assertTrue(raised(function()
    Sim:NewSeam(compatFixture(), { name = "Host", pure = PURE, guarded = { ChatSender = true } })
  end) ~= nil, "a guarded answer that is not a function")
end)

test("sim seam: one compat table is wrapped once", function()
  local _, Sim = env()
  local C = compatFixture()
  Sim:NewSeam(C, { name = "Host", pure = PURE })
  local err = raised(function() Sim:NewSeam(C, { name = "Host", pure = PURE }) end)
  assertTrue(err ~= nil and tostring(err):find("Host", 1, true) ~= nil, "a second wrap raises, named")
end)

test("sim seam: a dropped compat table and its seam are collected", function()
  local _, Sim = env()
  local probe = setmetatable({}, { __mode = "k" })
  local C = compatFixture()
  local seam = Sim:NewSeam(C, { name = "Host", pure = PURE })
  probe[C], probe[seam] = true, true
  C, seam = nil, nil   -- luacheck: ignore 311
  collectgarbage("collect")
  collectgarbage("collect")
  assertNil(next(probe), "nothing the library holds keeps a dropped host table alive")
end)

-- ── the idle path ────────────────────────────────────────────────────────────────────────

test("sim seam: an idle call goes straight to live, arguments and nil holes intact", function()
  local _, C, calls = seamOver()
  assertEqual(C.UnitName("party1"), "live-party1")
  local a, b = C.Pair(nil, "b")
  assertNil(a)
  assertEqual(b, "b")
  assertEqual(select("#", C.Holes()), 3, "trailing nil survives")
  assertEqual(joined(calls), "UnitName,Pair,Holes")
end)

test("sim seam: idle, a guarded member calls live", function()
  local _, C, calls = seamOver()
  assertEqual(C.ChatSender(), "real-sender")
  assertEqual(joined(calls), "ChatSender")
end)

test("sim seam: idle, a registered provider is never consulted", function()
  local seam, C = seamOver()
  local asked = 0
  seam:SetProvider("ZoneText", function() asked = asked + 1; return "Simulated" end)
  assertEqual(C.ZoneText(), "Dornogal")
  assertEqual(asked, 0)
end)

test("sim seam: the idle wrapper allocates nothing", function()
  local _, Sim = env()
  local C = { Pair = function(a, b) return a, b end }
  Sim:NewSeam(C, { name = "Host" })
  local pair = C.Pair
  pair(1, 2)
  collectgarbage("collect")
  collectgarbage("stop")
  local before = collectgarbage("count")
  for i = 1, 2000 do pair(i, i) end
  local after = collectgarbage("count")
  collectgarbage("restart")
  assertEqual(after - before, 0, "KB allocated by 2000 idle calls")
end)

-- ── SetProvider ──────────────────────────────────────────────────────────────────────────

test("sim seam: SetProvider raises on a pure key and on an unknown key", function()
  local seam = seamOver()
  local err = raised(function() seam:SetProvider("IsSecret", function() end) end)
  assertTrue(err ~= nil and tostring(err):find("IsSecret", 1, true) ~= nil, "pure key named")
  err = raised(function() seam:SetProvider("UnitNmae", function() end) end)
  assertTrue(err ~= nil and tostring(err):find("UnitNmae", 1, true) ~= nil, "typo named")
  assertTrue(raised(function() seam:SetProvider("VERSION", function() end) end) ~= nil,
    "a non-function member is not wrapped")
  assertTrue(raised(function() seam:SetProvider("IsSecret", nil) end) ~= nil,
    "even a release names a key that must be wrapped")
end)

test("sim seam: a second owner raises; nil releases, and then a new owner is taken", function()
  local seam = seamOver()
  local first, second = function() end, function() end
  seam:SetProvider("UnitName", first)
  local err = raised(function() seam:SetProvider("UnitName", second) end)
  assertTrue(err ~= nil and tostring(err):find("UnitName", 1, true) ~= nil, "second owner named")
  assertTrue(raised(function() seam:SetProvider("UnitName", first) end) ~= nil,
    "the same function twice is still two registrations")
  seam:SetProvider("UnitName", nil)
  assertNil(raised(function() seam:SetProvider("UnitName", second) end), "released, re-owned")
  assertNil(raised(function() seam:SetProvider("ZoneText", nil) end), "releasing an unowned key is fine")
end)

test("sim seam: SetProvider raises on a provider that is not a function", function()
  local seam = seamOver()
  assertTrue(raised(function() seam:SetProvider("UnitName", "fn") end) ~= nil)
end)

-- ── Live ─────────────────────────────────────────────────────────────────────────────────

test("sim seam: Live runs fn with its arguments and keeps nil holes in both", function()
  local seam, C = seamOver()
  local n = select("#", seam:Live(function(...) return ... end, nil, 2, nil))
  assertEqual(n, 3, "returns keep their nil holes")
  local a, b, c = seam:Live(function(x, y) return x, C.UnitName(y), nil end, nil, "target")
  assertNil(a)
  assertEqual(b, "live-target")
  assertNil(c)
end)

test("sim seam: Live nests, and the seam works again after a raise", function()
  local seam, C = seamOver()
  local out = seam:Live(function()
    return seam:Live(function() return C.ZoneText() end)
  end)
  assertEqual(out, "Dornogal")
  pcall(seam.Live, seam, function() error("boom") end)
  assertEqual(C.ZoneText(), "Dornogal", "the wrapper still answers after Live raised")
  assertEqual(seam:Live(function() return 7 end), 7)
end)

test("sim seam: Live re-raises a table error value unchanged", function()
  local seam = seamOver()
  local value = { code = "E_SIM" }
  local ok, err = pcall(seam.Live, seam, function() error(value) end)
  assertFalse(ok)
  assertTrue(rawequal(err, value), "the very table, not a string")
end)

test("sim seam: Live re-raises a string error with no second position prefix", function()
  local seam = seamOver()
  local ok, err = pcall(seam.Live, seam, function() error("plain", 0) end)
  assertFalse(ok)
  assertEqual(err, "plain")
end)

test("sim seam: Live writes the traceback to opts.debug before re-raising", function()
  local lines = {}
  local seam = seamOver({ debug = function(tag, fmt, ...) lines[#lines + 1] = { tag = tag, text = fmt:format(...) } end })
  local ok = pcall(seam.Live, seam, function() error("kaboom", 0) end)
  assertFalse(ok)
  assertEqual(#lines, 1, "one debug line")
  assertEqual(lines[1].tag, "Sim")
  assertTrue(lines[1].text:find("Host", 1, true) ~= nil, "the seam's name")
  assertTrue(lines[1].text:find("kaboom", 1, true) ~= nil, "the error")
  assertTrue(lines[1].text:find("\n", 1, true) ~= nil, "a stack follows the message")
end)

test("sim seam: a raising debug sink never masks the original error", function()
  local seam = seamOver({ debug = function() error("sink broke") end })
  local value = {}
  local ok, err = pcall(seam.Live, seam, function() error(value) end)
  assertFalse(ok)
  assertTrue(rawequal(err, value))
end)

test("sim seam: Live with no debug sink still re-raises", function()
  local seam = seamOver()
  local ok, err = pcall(seam.Live, seam, function() error("quiet", 0) end)
  assertFalse(ok)
  assertEqual(err, "quiet")
  assertTrue(raised(function() seam:Live("not a function") end) ~= nil, "fn must be a function")
end)

-- ── Unwrapped ────────────────────────────────────────────────────────────────────────────

test("sim seam: Unwrapped() is empty straight after NewSeam", function()
  local seam = seamOver()
  assertEqual(#seam:Unwrapped(), 0)
end)

test("sim seam: Unwrapped() lists a late-added and a replaced member, sorted", function()
  local seam, C = seamOver()
  C.LateReader = function() return 1 end
  C.UnitName = function() return "replaced" end
  C.LATE_CONSTANT = 4
  C.IsSecret = function() return true end
  assertEqual(joined(seam:Unwrapped()), "LateReader,UnitName",
    "a constant and a replaced pure member are not escapes")
  C.LateReader = nil
  assertEqual(joined(seam:Unwrapped()), "UnitName")
end)

-- ── the source ───────────────────────────────────────────────────────────────────────────

test("sim seam: Sim.lua carries no auto-wrap metatable and no guarded-key query", function()
  local f = assert(io.open("LibKa0s/Sim.lua", "rb"))
  local src = f:read("*a")
  f:close()
  for _, word in ipairs({ "__newindex", "IsGuarded", "setmetatable(compat" }) do
    assertNil(src:find(word, 1, true), word .. " in LibKa0s/Sim.lua (OWNER_SCOPE C.7/C.8)")
  end
end)
