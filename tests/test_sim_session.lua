-- tests/test_sim_session.lua — LibKa0s-Sim-1.0's session, `Sim:New(d)`, and the seam's active path.
--
-- Every case runs on a fresh environment with Core and Sim loaded, a fresh host Compat table and
-- its seam, and a descriptor whose callbacks record what they were asked. Timers are the kit's:
-- `m.__fireTimers()` runs every pending one and answers how many ran.
--
-- The seam's active-path cases live here, not in tests/test_sim_seam.lua: only a bound session
-- turns a seam on, and the plan's review ruled out a test-only hook that would flip it by hand.

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

--- A host Compat table: two readers, one guarded sender, one pure helper. `calls` records each
--- live member's name as it runs.
local function compatFixture()
  local calls = {}
  local function rec(name, fn)
    return function(...) calls[#calls + 1] = name; return fn(...) end
  end
  local C = {
    UnitName = rec("UnitName", function(unit) return "live-" .. tostring(unit) end),
    ZoneText = rec("ZoneText", function() return "Dornogal" end),
    ChatSender = rec("ChatSender", function() return "real-sender" end),
    IsSecret = function() return false end,
  }
  return C, calls
end

local function joined(list) return table.concat(list, ",") end

--- The error a call raised, or nil when it did not raise.
local function raised(fn, ...)
  local ok, err = pcall(fn, ...)
  if ok then return nil end
  return tostring(err)
end

--- A bench: env, compat, seam, a descriptor that records everything, and the session built from it.
--- `over` is merged into the descriptor before New; `prepare` defaults to calling ready() at once.
local function bench(over)
  local m, Sim = env()
  local C, calls = compatFixture()
  local guardedCalls = 0
  local seam = Sim:NewSeam(C, { name = "Host", pure = { IsSecret = true },
    guarded = { ChatSender = function() guardedCalls = guardedCalls + 1; return "guarded" end } })
  local b = { m = m, Sim = Sim, C = C, calls = calls, seam = seam, printed = {}, debugs = {},
    delivered = {}, stoodDown = false, prepared = {} }
  b.guardedCalls = function() return guardedCalls end
  local d = {
    name = "Host", seam = seam, slash = "/host sim",
    deliver = function(event, ...)
      b.delivered[#b.delivered + 1] = { event = event, n = select("#", ...), ... }
      return 1
    end,
    isStoodDown = function() return b.stoodDown end,
    scenarios = {
      names = { "solo", "group" },
      defs = {
        solo = { label = "Solo", timeline = function() return { { kind = "a" } } end },
        group = { label = "Group", sizes = { 5, 10 }, timeline = function() return { { kind = "b" } } end },
      },
    },
    prepare = function(session, def, opts, ready)
      b.prepared[#b.prepared + 1] = { session = session, def = def, opts = opts, ready = ready }
      ready()
    end,
    play = function() end,
    print = function(line) b.printed[#b.printed + 1] = line end,
    debug = function(tag, fmt, ...) b.debugs[#b.debugs + 1] = { tag = tag, text = fmt:format(...) } end,
  }
  for k, v in pairs(over or {}) do d[k] = v end
  b.d = d
  b.sim = Sim:New(d)
  return b
end

local function lastPrinted(b) return b.printed[#b.printed] end

local function debugHas(b, needle)
  for _, line in ipairs(b.debugs) do
    if line.text:find(needle, 1, true) then return true end
  end
  return false
end

-- ── New ──────────────────────────────────────────────────────────────────────────────────

test("sim session: New is on the library, beside NewSeam", function()
  local _, Sim = env()
  assertEqual(type(Sim.New), "function")
  assertEqual(type(Sim.STRINGS), "table")
end)

test("sim session: every required descriptor field raises by name when missing", function()
  local base = bench().d
  for _, field in ipairs({ "name", "seam", "slash", "deliver", "isStoodDown", "scenarios", "prepare", "play" }) do
    local _, Sim = env()
    local C = compatFixture()
    local d = {}
    for k, v in pairs(base) do d[k] = v end
    d.seam = Sim:NewSeam(C, { name = "Host" })
    d[field] = nil
    local err = raised(function() Sim:New(d) end)
    assertTrue(err ~= nil, field .. " missing raises")
    assertTrue(err:find(field, 1, true) ~= nil, "the error names " .. field .. ": " .. tostring(err))
  end
end)

test("sim session: a seam that NewSeam did not make raises", function()
  local _, Sim = env()
  local d = bench().d
  d.seam = { SetProvider = function() end, Live = function() end }
  assertTrue(raised(function() Sim:New(d) end) ~= nil)
end)

test("sim session: a second New on one seam raises (one seam binds one session)", function()
  local b = bench()
  local err = raised(function() b.Sim:New(b.d) end)
  assertTrue(err ~= nil and err:find("seam", 1, true) ~= nil, "named: " .. tostring(err))
end)

test("sim session: a scenario name with no def, or a def with no timeline, raises", function()
  local _, Sim = env()
  local d = bench().d
  d.seam = Sim:NewSeam(compatFixture(), { name = "Host" })
  d.scenarios = { names = { "ghost" }, defs = {} }
  assertTrue((raised(function() Sim:New(d) end) or ""):find("ghost", 1, true) ~= nil)
  local _, Sim2 = env()
  d.seam = Sim2:NewSeam(compatFixture(), { name = "Host" })
  d.scenarios = { names = { "solo" }, defs = { solo = { label = "Solo" } } }
  assertTrue((raised(function() Sim2:New(d) end) or ""):find("timeline", 1, true) ~= nil)
end)

test("sim session: d.panel takes presentation fields only (no button, tooltip or store)", function()
  for _, key in ipairs({ "button", "tooltip", "store" }) do
    local _, Sim = env()
    local d = bench().d
    d.seam = Sim:NewSeam(compatFixture(), { name = "Host" })
    d.panel = { title = "T", [key] = function() end }
    local err = raised(function() Sim:New(d) end)
    assertTrue(err ~= nil and err:find(key, 1, true) ~= nil, "panel." .. key .. " refused: " .. tostring(err))
  end
  local _, Sim = env()
  local d = bench().d
  d.seam = Sim:NewSeam(compatFixture(), { name = "Host" })
  d.panel = { title = "T", stepLabel = function() end, stepTip = function() end, startTip = {}, stopTip = {},
    anchorTo = function() end, check = "path" }
  assertNil(raised(function() Sim:New(d) end), "every allowed field is accepted")
end)

test("sim session: the instance carries no Live and no public active or delivering field", function()
  local b = bench()
  assertNil(b.sim.Live, "one Live, on the seam (OWNER_SCOPE C.7)")
  assertNil(b.sim.active)
  assertNil(b.sim.delivering)
  b.sim:Start({ scenario = "solo" })
  assertNil(rawget(b.sim, "active"))
end)

test("sim session: the fallback members answer until their files attach", function()
  local b = bench()
  assertEqual(#b.sim:Steps(), 0)
  assertEqual(#b.sim:PanelRows(), 0)
  assertFalse(b.sim:IsPanelShown())
  local ok, code = b.sim:RunVerb("run")
  assertFalse(ok)
  assertEqual(code, "absent")
  assertEqual(lastPrinted(b), b.Sim.STRINGS.NO_TIMELINE)
  for _, name in ipairs({ "ShowPanel", "HidePanel", "TogglePanel", "RefreshPanel", "ResetPanelPosition",
    "Step", "Run", "Pause", "Resume", "Restart" }) do
    assertEqual(type(b.sim[name]), "function", name)
  end
end)

-- ── Start ────────────────────────────────────────────────────────────────────────────────

test("sim session: Start prints STARTED and creates the session", function()
  local b = bench()
  local ok = b.sim:Start({ scenario = "solo", seed = 42 })
  assertTrue(ok)
  assertTrue(b.sim:IsActive())
  local s = b.sim:Session()
  assertTrue(s.sim)
  assertEqual(s.scenario, "solo")
  assertEqual(s.seed, 42)
  assertEqual(s.events, 0)
  assertEqual(type(s.startedAt), "number")
  assertEqual(lastPrinted(b), b.Sim.STRINGS.STARTED:format("Solo"))
  assertNil(b.Sim.STRINGS.STARTED:lower():find("saved", 1, true), "STARTED makes no saved-data claim")
end)

test("sim session: the seed defaults to an integer, and two starts draw different seeds", function()
  local b = bench()
  b.sim:Start({ scenario = "solo" })
  local first = b.sim:Session().seed
  assertEqual(type(first), "number")
  assertEqual(first, math.floor(first))
  b.sim:Stop()
  b.sim:Start({ scenario = "solo" })
  assertTrue(b.sim:Session().seed ~= first, "a fresh seed")
end)

test("sim session: size reaches prepare only when the def has sizes; 0 is random", function()
  local b = bench()
  b.sim:Start({ scenario = "solo", size = 5 })
  assertNil(b.prepared[1].opts.size, "no sizes, no size")
  assertNil(b.sim:Session().size)
  b.sim:Stop()
  b.sim:Start({ scenario = "group", size = 10 })
  assertEqual(b.prepared[2].opts.size, 10)
  assertEqual(b.sim:Session().size, 10)
  b.sim:Stop()
  b.sim:Start({ scenario = "group" })
  assertEqual(b.prepared[3].opts.size, 0, "no size given is random")
  assertTrue(rawequal(b.prepared[3].def, b.d.scenarios.defs.group), "prepare gets the def")
  assertTrue(rawequal(b.prepared[3].session, b.sim:Session()), "prepare gets the session")
end)

test("sim session: an unknown scenario is refused first, naming the scenarios", function()
  local b = bench()
  local ok, line = b.sim:Start({ scenario = "nope" })
  assertFalse(ok)
  assertEqual(line, b.Sim.STRINGS.UNKNOWN_SCENARIO:format("nope", "solo, group"))
  assertEqual(lastPrinted(b), line, "printed too")
  assertFalse(b.sim:IsActive())
end)

test("sim session: Start reads the scenarios live: a def added after New starts (minor 2)", function()
  local b = bench({ scenarios = { names = {}, defs = {} } })
  local ok, line = b.sim:Start({ scenario = "dungeon" })
  assertFalse(ok, "not listed yet")
  assertEqual(line, b.Sim.STRINGS.UNKNOWN_SCENARIO:format("dungeon", ""))
  local sc = b.d.scenarios
  sc.names[1] = "dungeon"
  sc.defs.dungeon = { label = "Dungeon", sizes = { 5 }, timeline = function() return {} end }
  ok = b.sim:Start({ scenario = "dungeon", size = 5 })
  assertTrue(ok, "a scenario filled in place after New starts")
  assertEqual(b.sim:Session().scenario, "dungeon")
  assertTrue(rawequal(b.prepared[1].def, sc.defs.dungeon), "prepare gets the live def")
  b.sim:Stop()
  ok, line = b.sim:Start({ scenario = "nope" })
  assertFalse(ok)
  assertEqual(line, b.Sim.STRINGS.UNKNOWN_SCENARIO:format("nope", "dungeon"), "UNKNOWN lists the live names")
end)

test("sim session: a def listed after New is validated on Start, raising as New does", function()
  local b = bench({ scenarios = { names = {}, defs = {} } })
  local sc = b.d.scenarios
  sc.names[1] = "ghost"
  local err = raised(function() b.sim:Start({ scenario = "ghost" }) end)
  assertTrue(err ~= nil and err:find("defs.ghost is missing", 1, true) ~= nil, "missing def: " .. tostring(err))
  sc.defs.ghost = { label = "Ghost" }
  err = raised(function() b.sim:Start({ scenario = "ghost" }) end)
  assertTrue(err ~= nil and err:find("defs.ghost.timeline must be a function", 1, true) ~= nil,
    "missing timeline: " .. tostring(err))
  sc.defs.ghost = { label = "Ghost", sizes = 5, timeline = function() return {} end }
  err = raised(function() b.sim:Start({ scenario = "ghost" }) end)
  assertTrue(err ~= nil and err:find("defs.ghost.sizes must be a list", 1, true) ~= nil, "bad sizes: " .. tostring(err))
  assertFalse(b.sim:IsActive(), "a raising Start starts nothing")
  assertEqual(#b.prepared, 0)
end)

test("sim session: prepare receives the caller's extra start options (minor 2)", function()
  local refused
  local b = bench({ refusal = function(opts) refused = opts; return nil end })
  local band = { low = 25, high = 35 }
  local opts = { scenario = "group", size = 10, seed = 7, band = band, classFilter = "any" }
  assertTrue(b.sim:Start(opts))
  local got = b.prepared[1].opts
  assertTrue(rawequal(got.band, band), "band arrives")
  assertEqual(got.classFilter, "any", "classFilter arrives")
  assertEqual(got.scenario, "group")
  assertEqual(got.size, 10)
  assertEqual(got.seed, 7)
  assertFalse(rawequal(got, opts), "a shallow copy, not the caller's table")
  assertTrue(rawequal(refused, opts), "refusal still gets the caller's opts")
  b.sim:Stop()
  local bare = { scenario = "solo", size = 99, band = band }
  assertTrue(b.sim:Start(bare))
  got = b.prepared[2].opts
  assertNil(got.size, "the resolved size overwrites the caller's (no sizes, no size)")
  assertEqual(type(got.seed), "number", "the resolved seed")
  assertNil(bare.seed, "the caller's table is not written")
  assertEqual(bare.size, 99)
end)

test("sim session: refusal order is unknown, already running, refusal, stood down", function()
  local asked = 0
  local b = bench({ refusal = function() asked = asked + 1; return "host says no" end })
  -- (1) beats (3)
  b.sim:Start({ scenario = "nope" })
  assertEqual(asked, 0, "an unknown scenario never reaches refusal")
  -- (3) refuses
  local ok, line = b.sim:Start({ scenario = "solo" })
  assertFalse(ok)
  assertEqual(line, "host says no")
  assertEqual(lastPrinted(b), "host says no")
  assertEqual(asked, 1)
  -- (2) beats (3)
  b.d.refusal = nil
  assertTrue(b.sim:Start({ scenario = "solo" }))
  b.d.refusal = function() asked = asked + 1; return "x" end
  ok, line = b.sim:Start({ scenario = "solo" })
  assertFalse(ok)
  assertEqual(line, b.Sim.STRINGS.ALREADY_RUNNING)
  assertEqual(asked, 1, "already running never reaches refusal")
end)

test("sim session: the stood-down backstop refuses after refusal passes", function()
  local order = {}
  local b = bench({ refusal = function() order[#order + 1] = "refusal"; return nil end })
  b.stoodDown = true
  local ok, line = b.sim:Start({ scenario = "solo" })
  assertFalse(ok)
  assertEqual(line, b.Sim.STRINGS.STOOD_DOWN)
  assertEqual(joined(order), "refusal", "refusal ran first")
  assertFalse(b.sim:IsActive())
  assertEqual(#b.prepared, 0)
end)

test("sim session: refusal runs inside the seam's Live (it reads the real world)", function()
  local seen
  local b = bench()
  b.seam:SetProvider("ZoneText", function() return "Simulated" end)
  b.d.refusal = function() seen = b.C.ZoneText(); return nil end
  -- restart: the same descriptor, the refusal read right after a session ends
  b.sim:Start({ scenario = "solo" })
  assertEqual(b.C.ZoneText(), "Simulated", "the provider answers while active")
  b.sim:Stop("restart")
  b.sim:Start({ scenario = "solo" })
  assertEqual(seen, "Dornogal", "refusal read live")
  -- a raising refusal goes through Live: its traceback reaches the session's debug sink
  b.sim:Stop()
  b.d.refusal = function() error("refusal broke", 0) end
  local err = raised(function() b.sim:Start({ scenario = "solo" }) end)
  assertEqual(err, "refusal broke", "the original error, re-raised")
  assertTrue(debugHas(b, "refusal broke"), "Live wrote the traceback")
end)

test("sim session: a prepare error becomes Stop('error')", function()
  local b = bench({ prepare = function() error("world broke", 0) end })
  local ok = b.sim:Start({ scenario = "solo" })
  assertFalse(ok)
  assertFalse(b.sim:IsActive())
  assertEqual(lastPrinted(b), b.Sim.STRINGS.STOPPED_ERROR)
  assertTrue(debugHas(b, "world broke"))
end)

-- ── ready (OWNER_SCOPE C.1) ──────────────────────────────────────────────────────────────

test("sim session: ready() is bound to its session; a second call is ignored", function()
  local notes, readyFn = 0, nil
  local b = bench({ prepare = function(_, _, _, ready) readyFn = ready end })
  b.sim:AddListener(function() notes = notes + 1 end)
  b.sim:Start({ scenario = "solo" })
  assertFalse(b.sim:Status().ready, "not ready until ready()")
  local before = notes
  readyFn()
  assertTrue(b.sim:Status().ready)
  assertEqual(notes, before + 1, "ready notifies")
  readyFn()
  assertEqual(notes, before + 1, "a second ready() is ignored")
end)

test("sim session: a stale ready() is ignored after a restart and after stop then start", function()
  local readies = {}
  local b = bench({ prepare = function(_, _, _, ready) readies[#readies + 1] = ready end })
  b.sim:Start({ scenario = "solo" })
  b.sim:Stop("restart")
  b.sim:Start({ scenario = "solo" })
  readies[1]()
  assertFalse(b.sim:Status().ready, "the restarted session is not made ready by the old ready()")
  b.sim:Stop()
  b.sim:Start({ scenario = "solo" })
  readies[2]()
  assertFalse(b.sim:Status().ready, "stop then start: the old ready() is ignored")
  readies[3]()
  assertTrue(b.sim:Status().ready, "this session's own ready() works")
  b.sim:Stop()
  readies[3]()
  assertFalse(b.sim:Status().ready, "idle: a ready() changes nothing")
end)

-- ── Fire ─────────────────────────────────────────────────────────────────────────────────

test("sim session: Fire answers 0 when idle", function()
  local b = bench()
  assertEqual(b.sim:Fire("LOOT_READY"), 0)
  assertEqual(#b.delivered, 0)
end)

test("sim session: Fire delivers any event name with its payload, and counts it", function()
  local b = bench()
  b.sim:Start({ scenario = "solo" })
  assertEqual(b.sim:Fire("hook:Bag", nil, 2), 1)
  assertEqual(b.delivered[1].event, "hook:Bag")
  assertEqual(b.delivered[1].n, 2, "the nil hole survives")
  assertEqual(b.delivered[1][2], 2)
  assertEqual(b.sim:Session().events, 1)
  assertTrue(debugHas(b, "hook:Bag"))
end)

test("sim session: an observed stand-down stops the session first and answers 0", function()
  local b = bench()
  b.sim:Start({ scenario = "solo" })
  b.stoodDown = true
  assertEqual(b.sim:Fire("LOOT_READY"), 0)
  assertEqual(#b.delivered, 0)
  assertFalse(b.sim:IsActive(), "self-stopped")
  assertEqual(lastPrinted(b), b.Sim.STRINGS.STOPPED_REASON:format("standDown"))
end)

test("sim session: Fire answers 0 while stopping", function()
  local b = bench()
  local got
  b.sim:OnStopGuarded(function() got = b.sim:Fire("X") end)
  b.sim:Start({ scenario = "solo" })
  b.sim:Stop()
  assertEqual(got, 0)
  assertEqual(#b.delivered, 0)
end)

test("sim session: a deliver error is isolated to a debug line, and Fire answers 0", function()
  local b = bench({ deliver = function() error("handler broke", 0) end })
  b.sim:Start({ scenario = "solo" })
  assertEqual(b.sim:Fire("X"), 0)
  assertTrue(debugHas(b, "handler broke"))
  assertTrue(b.sim:IsActive(), "the session survives a bad handler")
  assertFalse(b.sim:IsDelivering())
end)

test("sim session: IsDelivering is true only inside Fire, and nesting restores it", function()
  local seen = {}
  local b
  b = bench({ deliver = function(event)
    seen[#seen + 1] = event .. ":" .. tostring(b.sim:IsDelivering())
    if event == "outer" then
      b.sim:Fire("inner")
      seen[#seen + 1] = "after-inner:" .. tostring(b.sim:IsDelivering())
    end
    return 1
  end })
  assertFalse(b.sim:IsDelivering())
  b.sim:Start({ scenario = "solo" })
  b.sim:Fire("outer")
  assertEqual(joined(seen), "outer:true,inner:true,after-inner:true")
  assertFalse(b.sim:IsDelivering())
end)

test("sim session: a Stop inside deliver leaves IsDelivering false afterwards", function()
  local b
  b = bench({ deliver = function(event)
    if event == "inner" then b.sim:Stop() end
    if event == "outer" then b.sim:Fire("inner") end
    return 1
  end })
  b.sim:Start({ scenario = "solo" })
  b.sim:Fire("outer")
  assertFalse(b.sim:IsActive())
  assertFalse(b.sim:IsDelivering(), "no stale delivering flag after the session ended")
end)

-- ── After ────────────────────────────────────────────────────────────────────────────────

test("sim session: After answers nil when idle", function()
  local b = bench()
  assertNil(b.sim:After(1, function() end))
end)

test("sim session: After fires within its session, under pcall", function()
  local b = bench()
  b.sim:Start({ scenario = "solo" })
  local ran = 0
  assertTrue(b.sim:After(1, function() ran = ran + 1 end) ~= nil)
  b.sim:After(1, function() error("timer broke", 0) end)
  b.m.__fireTimers()
  assertEqual(ran, 1)
  assertTrue(debugHas(b, "timer broke"), "a raising timer is a debug line")
  assertTrue(b.sim:IsActive())
end)

test("sim session: After never fires into a later session", function()
  local b = bench()
  b.sim:Start({ scenario = "solo" })
  local ran = 0
  b.sim:After(1, function() ran = ran + 1 end)
  b.sim:Stop()
  b.sim:Start({ scenario = "solo" })
  b.m.__fireTimers()
  assertEqual(ran, 0)
end)

test("sim session: Cancel cancels and forgets; Stop cancels every live handle", function()
  local b = bench()
  b.sim:Start({ scenario = "solo" })
  local ran = 0
  local h = b.sim:After(1, function() ran = ran + 1 end)
  b.sim:After(2, function() ran = ran + 1 end)
  h:Cancel()
  assertEqual(#b.m.__timers(), 1, "one live timer left")
  b.sim:Stop()
  assertEqual(#b.m.__timers(), 0, "the stop canceled the rest")
  b.m.__fireTimers()
  assertEqual(ran, 0)
  h:Cancel()   -- a second Cancel is harmless
end)

test("sim session: After refuses while stopping", function()
  local b = bench()
  local got = "unset"
  b.sim:OnStopGuarded(function() got = b.sim:After(1, function() end) end)
  b.sim:Start({ scenario = "solo" })
  b.sim:Stop()
  assertNil(got)
end)

-- ── Stop ─────────────────────────────────────────────────────────────────────────────────

test("sim session: Stop answers false when idle", function()
  local b = bench()
  assertFalse(b.sim:Stop())
end)

test("sim session: Stop runs guarded, then seam off, then cleanup, then notify, then prints", function()
  local order = {}
  local b = bench()
  b.seam:SetProvider("ZoneText", function() return "Simulated" end)
  b.sim:OnStopGuarded(function(session)
    order[#order + 1] = "guarded:" .. b.C.ZoneText() .. ":" .. tostring(b.sim:IsActive())
      .. ":" .. tostring(session.scenario)
  end)
  b.sim:OnStop(function(session, reason)
    order[#order + 1] = "stop:" .. b.C.ZoneText() .. ":" .. tostring(b.sim:IsActive())
      .. ":" .. tostring(session.scenario) .. ":" .. reason
  end)
  b.sim:AddListener(function(sim)
    if not sim:IsActive() then order[#order + 1] = "notify:" .. #b.printed end
  end)
  b.sim:Start({ scenario = "solo" })
  local printedBefore = #b.printed
  assertTrue(b.sim:Stop())
  assertEqual(joined(order), "guarded:Simulated:true:solo,stop:Dornogal:false:solo:stop,notify:" .. printedBefore)
  assertEqual(lastPrinted(b), b.Sim.STRINGS.STOPPED)
  assertNil(b.sim:Session())
  assertTrue(debugHas(b, "0 events"), "one debug line with the event count")
end)

test("sim session: each stop step is pcalled; a raising one does not skip the rest", function()
  local order = {}
  local b = bench()
  b.sim:OnStopGuarded(function() error("g1", 0) end)
  b.sim:OnStopGuarded(function() order[#order + 1] = "g2" end)
  b.sim:OnStop(function() error("s1", 0) end)
  b.sim:OnStop(function() order[#order + 1] = "s2" end)
  b.sim:AddListener(function() error("l1", 0) end)
  b.sim:Start({ scenario = "solo" })
  assertTrue(b.sim:Stop())
  assertEqual(joined(order), "g2,s2")
  assertFalse(b.sim:IsActive())
  assertEqual(lastPrinted(b), b.Sim.STRINGS.STOPPED)
  assertTrue(debugHas(b, "g1") and debugHas(b, "s1") and debugHas(b, "l1"))
end)

test("sim session: Stop re-entered from deliver, OnStop or a second call is a no-op false (C.1)", function()
  local answers = {}
  local b
  b = bench({ deliver = function()
    b.sim:Stop()
    return 1
  end })
  b.sim:OnStopGuarded(function() answers[#answers + 1] = b.sim:Stop("again") end)
  b.sim:OnStop(function() answers[#answers + 1] = b.sim:Stop("again") end)
  b.sim:AddListener(function(sim) if not sim:IsActive() then answers[#answers + 1] = sim:Stop() end end)
  b.sim:Start({ scenario = "solo" })
  local stopsPrinted = 0
  b.sim:Fire("X")   -- deliver stops the session
  for _, line in ipairs(b.printed) do
    if line == b.Sim.STRINGS.STOPPED then stopsPrinted = stopsPrinted + 1 end
  end
  assertEqual(stopsPrinted, 1, "one stop line")
  assertEqual(joined((function() local t = {} for i, v in ipairs(answers) do t[i] = tostring(v) end return t end)()),
    "false,false,false")
  assertFalse(b.sim:Stop(), "a second Stop in a row")
end)

test("sim session: stop reason lines, host stopText, and the generic reason line", function()
  local b = bench({ stopText = { group = "You joined a group." } })
  local S = b.Sim.STRINGS
  local cases = { { "stop", S.STOPPED }, { "restart", S.STOPPED_RESTART }, { "error", S.STOPPED_ERROR },
    { "group", "You joined a group." }, { "combat", S.STOPPED_REASON:format("combat") },
    { "standDown", S.STOPPED_REASON:format("standDown") } }
  for _, c in ipairs(cases) do
    b.sim:Start({ scenario = "solo" })
    b.sim:Stop(c[1])
    assertEqual(lastPrinted(b), c[2], c[1])
  end
  b.sim:Start({ scenario = "solo" })
  b.sim:Stop()
  assertEqual(lastPrinted(b), S.STOPPED, "no reason is 'stop'")
end)

test("sim session: stopText overrides a library reason too", function()
  local b = bench({ stopText = { stop = "Host stop line." } })
  b.sim:Start({ scenario = "solo" })
  b.sim:Stop()
  assertEqual(lastPrinted(b), "Host stop line.")
end)

test("sim session: the panel is hidden on a stood-down stop and repainted otherwise", function()
  local b = bench()
  local hidden, refreshed = 0, 0
  b.sim.HidePanel = function() hidden = hidden + 1 end
  b.sim.RefreshPanel = function() refreshed = refreshed + 1 end
  b.sim:Start({ scenario = "solo" })
  b.sim:Stop()
  assertEqual(hidden .. "/" .. refreshed, "0/1")
  b.sim:Start({ scenario = "solo" })
  b.stoodDown = true
  b.sim:Stop("standDown")
  assertEqual(hidden .. "/" .. refreshed, "1/1")
end)

-- ── DeliverForCleanup (OWNER_SCOPE C.3) ──────────────────────────────────────────────────

test("sim session: DeliverForCleanup delivers only in the OnStop phase, with the seam off", function()
  local b = bench()
  local inGuarded, inStop
  b.seam:SetProvider("ZoneText", function() return "Simulated" end)
  local zoneAtDelivery
  b.d.deliver = function(event)
    zoneAtDelivery = b.C.ZoneText()
    b.delivered[#b.delivered + 1] = { event = event }
    return 1
  end
  b.sim:OnStopGuarded(function() inGuarded = b.sim:DeliverForCleanup("UNDO") end)
  b.sim:OnStop(function() inStop = b.sim:DeliverForCleanup("UNDO") end)
  assertEqual(b.sim:DeliverForCleanup("UNDO"), 0, "idle")
  b.sim:Start({ scenario = "solo" })
  assertEqual(b.sim:DeliverForCleanup("UNDO"), 0, "active")
  b.sim:Stop()
  assertEqual(inGuarded, 0, "the guarded phase")
  assertEqual(inStop, 1, "the cleanup phase")
  assertEqual(zoneAtDelivery, "Dornogal", "the seam is off")
  assertEqual(b.sim:DeliverForCleanup("UNDO"), 0, "after the stop")
end)

test("sim session: DeliverForCleanup answers 0 while stood down", function()
  local b = bench()
  local got
  b.sim:OnStop(function() got = b.sim:DeliverForCleanup("UNDO") end)
  b.sim:Start({ scenario = "solo" })
  b.stoodDown = true
  b.sim:Stop("standDown")
  assertEqual(got, 0)
  assertEqual(#b.delivered, 0)
end)

-- ── Status, Session, listeners ───────────────────────────────────────────────────────────

test("sim session: Status answers every field, idle and running", function()
  local b = bench()
  local s = b.sim:Status()
  assertFalse(s.active)
  assertFalse(s.ready)
  assertEqual(s.pos, 0)
  assertEqual(s.total, 0)
  assertFalse(s.playing)
  assertFalse(s.paused)
  assertFalse(s.settling)
  b.sim:Start({ scenario = "group", size = 5, seed = 9 })
  b.sim:Fire("X")
  s = b.sim:Status()
  assertTrue(s.active)
  assertTrue(s.ready)
  assertEqual(s.scenario, "group")
  assertEqual(s.size, 5)
  assertEqual(s.seed, 9)
  assertEqual(s.events, 1)
  assertEqual(type(s.startedAt), "number")
end)

test("sim session: host fields go on the session table (the host bag)", function()
  local b = bench({ prepare = function(session, _, _, ready) session.world = { zone = "X" }; ready() end })
  b.sim:Start({ scenario = "solo" })
  assertEqual(b.sim:Session().world.zone, "X")
end)

test("sim session: listeners hear start, ready and stop, with the instance", function()
  local b = bench()
  local heard = {}
  b.sim:AddListener(function(sim) heard[#heard + 1] = rawequal(sim, b.sim) end)
  b.sim:Start({ scenario = "solo" })
  b.sim:Stop()
  assertEqual(#heard, 3, "ready, start, stop")
  for _, same in ipairs(heard) do assertTrue(same) end
end)

test("sim session: registrations must be functions", function()
  local b = bench()
  for _, name in ipairs({ "OnStopGuarded", "OnStop", "AddListener" }) do
    assertTrue(raised(function() b.sim[name](b.sim, "nope") end) ~= nil, name)
  end
end)

-- ── STRINGS ──────────────────────────────────────────────────────────────────────────────

test("sim session: STRINGS carry every session key", function()
  local _, Sim = env()
  for _, key in ipairs({ "STARTED", "STOPPED", "STOPPED_RESTART", "STOPPED_ERROR", "STOPPED_REASON",
    "ALREADY_RUNNING", "STOOD_DOWN", "UNKNOWN_SCENARIO", "NOT_RUNNING", "NO_TIMELINE" }) do
    assertEqual(type(Sim.STRINGS[key]), "string", key)
  end
end)

test("sim session: d.L overrides a string through rawget; a metatable fallback does not shadow", function()
  local L = setmetatable({ STOPPED = "Host stopped." }, { __index = function(_, k) return k end })
  local b = bench({ L = L })
  b.sim:Start({ scenario = "solo" })
  assertEqual(lastPrinted(b), b.Sim.STRINGS.STARTED:format("Solo"), "the fallback key is not used")
  b.sim:Stop()
  assertEqual(lastPrinted(b), "Host stopped.")
end)

test("sim session: print and debug are read at call time; the defaults need neither", function()
  local b = bench()
  local late = {}
  b.d.print = function(line) late[#late + 1] = line end
  b.sim:Start({ scenario = "solo" })
  assertEqual(#late, 1, "the replaced print is used")
  b.d.print, b.d.debug = nil, nil
  assertTrue(b.sim:Stop(), "the default sinks work")
end)

-- ── the seam's active path (deferred from tests/test_sim_seam.lua) ───────────────────────

test("sim session: active, a provider answers and is handed the live fallback", function()
  local b = bench()
  local fallbackAnswer
  b.seam:SetProvider("UnitName", function(fallback, unit)
    fallbackAnswer = fallback(unit)
    return "sim-" .. unit
  end)
  b.sim:Start({ scenario = "solo" })
  assertEqual(b.C.UnitName("party1"), "sim-party1")
  assertEqual(fallbackAnswer, "live-party1")
  b.sim:Stop()
  assertEqual(b.C.UnitName("party1"), "live-party1", "idle again")
end)

test("sim session: active, a member with no provider answers live", function()
  local b = bench()
  b.sim:Start({ scenario = "solo" })
  assertEqual(b.C.ZoneText(), "Dornogal")
end)

test("sim session: a guarded member never reaches live while active, inside Live included", function()
  local b = bench()
  b.sim:Start({ scenario = "solo" })
  assertEqual(b.C.ChatSender(), "guarded")
  assertEqual(b.seam:Live(function() return b.C.ChatSender() end), "guarded", "inside Live")
  local handed
  b.seam:SetProvider("ChatSender", function(fallback) handed = fallback(); return "provided" end)
  assertEqual(b.C.ChatSender(), "provided")
  assertEqual(handed, "guarded", "the provider's fallback is the guarded answer, never live")
  for _, name in ipairs(b.calls) do assertTrue(name ~= "ChatSender", "live ChatSender ran") end
  b.sim:Stop()
  assertEqual(b.C.ChatSender(), "real-sender", "idle, a guarded member calls live")
end)

test("sim session: active, Live answers live for ordinary members, nested and after a raise", function()
  local b = bench()
  b.seam:SetProvider("ZoneText", function() return "Simulated" end)
  b.sim:Start({ scenario = "solo" })
  assertEqual(b.seam:Live(function() return b.C.ZoneText() end), "Dornogal")
  assertEqual(b.seam:Live(function() return b.seam:Live(function() return b.C.ZoneText() end), b.C.ZoneText() end),
    "Dornogal")
  assertEqual(b.C.ZoneText(), "Simulated", "bypass restored after Live")
  pcall(b.seam.Live, b.seam, function() error("boom", 0) end)
  assertEqual(b.C.ZoneText(), "Simulated", "bypass restored after Live raised")
end)

test("sim session: once bound, Live's traceback goes to the session's debug sink", function()
  local b = bench()
  pcall(b.seam.Live, b.seam, function() error("bound-raise", 0) end)
  assertTrue(debugHas(b, "bound-raise"))
  assertEqual(b.debugs[#b.debugs].tag, "SIM")
end)

-- ── the source ───────────────────────────────────────────────────────────────────────────

test("sim session: Sim.lua defines one Live, on the seam, and no test hook on it", function()
  local f = assert(io.open("LibKa0s/Sim.lua", "rb"))
  local src = f:read("*a")
  f:close()
  assertNil(src:find("__setActive", 1, true), "no seam.__setActive hook")
  assertNil(src:find("function sim.Live", 1, true), "no sim:Live (OWNER_SCOPE C.7)")
  assertNil(src:find("function sim:Live", 1, true), "no sim:Live (OWNER_SCOPE C.7)")
end)
