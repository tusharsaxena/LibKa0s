-- tests/test_sim_autoplay.lua — LibKa0s-Sim-1.0's auto-run (SimTimeline minor 3): a simulation
-- started from the verb layer plays on its own, and a manual act holds it.
--
-- The verb layer arms a run: a typed `start` (and so the picker's Start) and a typed `restart` (and
-- so the controls' Restart). Armed means `playing` at once, building included; the first tick is
-- scheduled through the session's After(0) once the session's ready() has fired, and every later
-- tick waits stepDelay as Run's do. The members `sim:Start{}` and `sim:Restart()` arm nothing: they
-- are the scripting layer host suites drive.
--
-- A manual act holds a playing run before it acts: a `step` (typed, or a click on the next row) and
-- the click-ahead cancel the pending tick or poll and leave the run paused, and the run stays paused
-- after the act while steps remain, so Resume (or `run`) is always what continues it.
--
-- The bench is tests/test_sim_timeline.lua's shape: a three-step scenario and a sized one, a
-- recording play, the kit's manual clock (`m.__timers()` the live set, `m.__fireTimers()` runs what
-- is pending), and the panel side of the attach handshake stood in for, so ctx.runTo is reachable.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse
local Loader = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local MAJOR = "LibKa0s-Sim-1.0"

--- A fresh environment with Core, Sim and SimTimeline loaded.
local function env()
  local m = buildMocks()
  Loader.load("LibKa0s/Core.lua", nil, m)
  Loader.load("LibKa0s/Sim.lua", nil, m)
  Loader.load("LibKa0s/SimTimeline.lua", nil, m)
  return m, m.LibStub(MAJOR)
end

--- A bench: `over` is merged into the descriptor before New. `prepare` calls ready() at once
--- unless holdReady is set, when it keeps the ready in b.readies.
local function bench(over, holdReady)
  local m, Sim = env()
  local seam = Sim:NewSeam({ Probe = function() return "live" end }, { name = "Host" })
  local b = { m = m, Sim = Sim, printed = {}, played = {}, readies = {}, gateOpen = true }
  local d = {
    name = "Host", seam = seam, slash = "/host sim",
    deliver = function() return 1 end,
    isStoodDown = function() return false end,
    scenarios = {
      names = { "three", "sized" },
      defs = {
        three = { label = "Three", timeline = function()
          return { { kind = "a", label = "Alpha" }, { kind = "b", label = "Beta" }, { kind = "c", label = "Gamma" } }
        end },
        sized = { label = "Sized", sizes = { 5 }, timeline = function()
          return { { kind = "s1" }, { kind = "s2" } }
        end },
      },
    },
    prepare = function(_, _, _, ready)
      b.readies[#b.readies + 1] = ready
      if not holdReady then ready() end
    end,
    play = function(step)
      b.played[#b.played + 1] = step.kind
      return "did " .. step.kind
    end,
    print = function(line) b.printed[#b.printed + 1] = line end,
  }
  for k, v in pairs(over or {}) do d[k] = v end
  b.d = d
  Sim.__AttachPanel = function(_, ctx) b.ctx = ctx end
  b.sim = Sim:New(d)
  return b
end

--- A bench whose descriptor gate is open or closed by b.gateOpen.
local function gated()
  local b
  b = bench({ gate = function() return b.gateOpen end })
  return b
end

local function joined(list) return table.concat(list, ",") end

--- The delay of every live timer (the kit's live set: armed, not canceled).
local function pendingDelays(m)
  local out = {}
  for _, t in ipairs(m.__timers()) do out[#out + 1] = t.delay end
  return out
end

-- ── a verb start arms the run ────────────────────────────────────────────────────────────

test("sim autoplay: a typed start with a synchronous ready plays on the next frame, then at stepDelay", function()
  local b = bench()
  assertTrue(b.sim:RunVerb("start three"))
  local st = b.sim:Status()
  assertTrue(st.playing, "armed: playing at once")
  assertFalse(st.paused)
  assertEqual(#b.played, 0, "nothing plays inside the start")
  assertEqual(joined(pendingDelays(b.m)), "0", "one tick, After(0)")
  b.m.__fireTimers()
  assertEqual(joined(b.played), "a")
  assertEqual(joined(pendingDelays(b.m)), "2", "every later tick waits the step delay")
end)

test("sim autoplay: the first tick after a typed start reads d.stepDelay for the next one", function()
  local b = bench({ stepDelay = 0.5 })
  b.sim:RunVerb("start three")
  assertEqual(joined(pendingDelays(b.m)), "0")
  b.m.__fireTimers()
  assertEqual(joined(pendingDelays(b.m)), "0.5")
  b.m.__fireTimers(); b.m.__fireTimers()
  assertEqual(joined(b.played), "a,b,c")
  assertFalse(b.sim:Status().playing, "finished")
  assertEqual(#b.m.__timers(), 0)
end)

test("sim autoplay: a typed start with ready held is armed and building; ready() schedules the tick", function()
  local b = bench(nil, true)
  assertTrue(b.sim:RunVerb("start three"))
  assertTrue(b.sim:Status().playing, "armed while building")
  assertFalse(b.sim:Status().ready)
  b.sim:RunVerb("status")
  local line = b.printed[#b.printed]
  assertTrue(line:find("building", 1, true) ~= nil, "the state word is building: " .. line)
  assertEqual(#b.m.__timers(), 0, "no tick before ready")
  b.readies[1]()
  assertEqual(joined(pendingDelays(b.m)), "0")
  b.m.__fireTimers()
  assertEqual(joined(b.played), "a")
end)

test("sim autoplay: the members arm nothing: sim:Start{} and sim:Restart() leave the run waiting", function()
  local b = bench()
  assertTrue(b.sim:Start({ scenario = "three" }))
  assertFalse(b.sim:Status().playing)
  assertEqual(#b.m.__timers(), 0)
  assertTrue(b.sim:Restart())
  assertFalse(b.sim:Status().playing)
  assertEqual(#b.m.__timers(), 0)
  assertEqual(#b.played, 0)
end)

test("sim autoplay: a typed restart arms the new session, and no timer of the old one survives", function()
  local b = bench()
  b.sim:RunVerb("start three")
  b.m.__fireTimers()
  assertEqual(joined(b.played), "a")
  local old = b.sim:Session()
  assertTrue(b.sim:RunVerb("restart"))
  assertTrue(b.sim:Session() ~= old, "a new session")
  local st = b.sim:Status()
  assertEqual(st.pos, 0)
  assertTrue(st.playing)
  assertEqual(joined(pendingDelays(b.m)), "0", "only the new session's first tick")
  b.m.__fireTimers()
  assertEqual(joined(b.played), "a,a", "the new session's first step")
end)

test("sim autoplay: a refused typed start arms nothing", function()
  local b = bench()
  assertFalse(b.sim:RunVerb("start nosuch"))
  assertEqual(#b.m.__timers(), 0)
  assertTrue(b.sim:Start({ scenario = "three" }))
  assertFalse(b.sim:RunVerb("start three"), "already running")
  assertFalse(b.sim:Status().playing, "the member's run stays unarmed")
  assertEqual(#b.m.__timers(), 0)
end)

-- ── Pause, Resume and Stop while armed ───────────────────────────────────────────────────

test("sim autoplay: Pause while armed and building holds it, and a later ready() schedules nothing", function()
  local b = bench(nil, true)
  b.sim:RunVerb("start three")
  assertTrue(b.sim:Pause())
  assertTrue(b.sim:Status().paused)
  assertFalse(b.sim:Status().playing)
  local ok, code = b.sim:Resume()
  assertFalse(ok)
  assertEqual(code, "building", "Resume checks blocked() first (A11)")
  assertTrue(b.sim:Status().paused, "a refused Resume keeps paused")
  b.readies[1]()
  assertEqual(#b.m.__timers(), 0, "paused: ready() schedules no tick")
  assertTrue(b.sim:Resume())
  assertEqual(joined(b.played), "a", "Resume is Run: the next step plays at once")
end)

test("sim autoplay: Stop while armed and building leaves no timer, and a stale ready() schedules nothing", function()
  local b = bench(nil, true)
  b.sim:RunVerb("start three")
  assertTrue(b.sim:RunVerb("stop"))
  assertEqual(#b.m.__timers(), 0)
  b.readies[1]()
  assertEqual(#b.m.__timers(), 0)
  assertEqual(#b.played, 0)
end)

-- ── a manual act holds the run ───────────────────────────────────────────────────────────

test("sim autoplay: a typed step while a run plays holds it, plays the next step, and stays paused", function()
  local b = bench()
  b.sim:RunVerb("start three")
  b.m.__fireTimers()
  assertEqual(joined(pendingDelays(b.m)), "2")
  assertTrue(b.sim:RunVerb("step"))
  assertEqual(joined(b.played), "a,b", "the next step plays at once, and only it")
  assertEqual(#b.m.__timers(), 0, "the run's pending tick is canceled")
  local st = b.sim:Status()
  assertFalse(st.playing)
  assertTrue(st.paused, "held: Resume continues it")
  assertEqual(b.m.__fireTimers(), 0)
  assertEqual(joined(b.played), "a,b")
end)

test("sim autoplay: a typed step while armed and building answers building and leaves the run armed", function()
  local b = bench(nil, true)
  b.sim:RunVerb("start three")
  local ok, code = b.sim:RunVerb("step")
  assertFalse(ok)
  assertEqual(code, "building")
  assertTrue(b.sim:Status().playing, "still armed")
  assertFalse(b.sim:Status().paused)
  b.readies[1]()
  assertEqual(joined(pendingDelays(b.m)), "0", "ready() still schedules the tick")
end)

test("sim autoplay: a click-ahead while a run plays holds it and plays up to the row", function()
  local b = bench()
  b.sim:RunVerb("start three")
  b.m.__fireTimers()
  assertTrue(b.ctx.runTo(3))
  assertEqual(joined(b.played), "a,b,c", "back to back")
  local st = b.sim:Status()
  assertFalse(st.playing)
  assertFalse(st.paused, "finished: nothing left to resume")
  assertEqual(#b.m.__timers(), 0)
end)

test("sim autoplay: a click-ahead short of the last step leaves the run paused", function()
  local b = bench()
  b.sim:RunVerb("start three")
  assertTrue(b.ctx.runTo(2), "held while armed, before its first tick")
  assertEqual(joined(b.played), "a,b")
  local st = b.sim:Status()
  assertFalse(st.playing)
  assertTrue(st.paused, "steps left after the target")
  assertEqual(#b.m.__timers(), 0, "the armed first tick is canceled")
  assertEqual(b.m.__fireTimers(), 0)
end)

test("sim autoplay: a second click-ahead retargets a polling one; Run still answers playing (C.2)", function()
  local b = gated()
  b.sim:Start({ scenario = "three" })
  b.gateOpen = false
  assertTrue(b.ctx.runTo(3))
  local ok, code = b.sim:Run()
  assertFalse(ok)
  assertEqual(code, "playing")
  assertTrue(b.ctx.runTo(1), "a second click-ahead holds the first and retargets")
  assertEqual(joined(pendingDelays(b.m)), "0.25", "one poll, the new one")
  b.gateOpen = true
  b.m.__fireTimers()
  assertEqual(joined(b.played), "a", "up to the new target only")
  assertTrue(b.sim:Status().paused)
  assertFalse(b.sim:Status().playing)
end)

test("sim autoplay: a manual step from the waiting state leaves paused; finishing clears it", function()
  local b = bench()
  b.sim:Start({ scenario = "three" })
  assertFalse(b.sim:Status().paused, "waiting")
  b.sim:Step()
  assertTrue(b.sim:Status().paused, "steps remain")
  b.sim:Step()
  assertTrue(b.sim:Status().paused)
  b.sim:Step()
  local st = b.sim:Status()
  assertFalse(st.paused, "finished")
  assertFalse(st.playing)
end)

test("sim autoplay: a typed run after a manual step resumes and plays the next step at once", function()
  local b = bench()
  b.sim:Start({ scenario = "three" })
  b.sim:RunVerb("step")
  assertTrue(b.sim:RunVerb("run"))
  assertEqual(joined(b.played), "a,b")
  local st = b.sim:Status()
  assertTrue(st.playing)
  assertFalse(st.paused)
end)

-- ── the usage ────────────────────────────────────────────────────────────────────────────

test("sim autoplay: the start and run usage lines say a simulation plays at once", function()
  local _, Sim = env()
  assertEqual(Sim.STRINGS.USAGE_START,
    "%s start <scenario> [size]: start a simulation. It plays at once; pause it to step by hand.")
  assertEqual(Sim.STRINGS.USAGE_RUN, "%s run: play the remaining steps (the same as resume).")
end)
