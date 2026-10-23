-- tests/test_sim_timeline.lua — LibKa0s-Sim-1.0's step machine, `SimTimeline.lua`.
--
-- Every case runs on a fresh environment with Core, Sim and SimTimeline loaded, and a descriptor
-- whose callbacks record what they were asked. Timers are the kit's: `m.__timers` is the queue of
-- pending entries, each carrying the `delay` it was set with, `m.__timers()` the live set, and
-- `m.__fireTimers()` runs every pending one and answers how many ran.
--
-- RunTo is Sim-internal (OWNER_SCOPE C.7): never an instance member. It reaches the panel through
-- the attach handshake's internal table, so this suite reaches it the same way, by standing in for
-- SimPanel.lua's `__AttachPanel` and keeping the ctx it is handed.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
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

--- A bench: a three-step scenario, a sized one, a recording play, and the panel side of the attach
--- handshake captured as b.ctx. `over` is merged into the descriptor before New. `prepare` calls
--- ready() at once unless b.holdReady is set, when it keeps the ready in b.readies.
local function bench(over, holdReady)
  local m, Sim = env()
  local seam = Sim:NewSeam({ Probe = function() return "live" end }, { name = "Host" })
  local b = { m = m, Sim = Sim, printed = {}, debugs = {}, played = {}, readies = {}, prepares = 0,
    seeds = {}, notified = 0, gateOpen = true, gateLine = nil, gateCalls = 0 }
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
        sized = { label = "Sized", sizes = { 5 }, timeline = function(_, opts)
          local out = {}
          for i = 1, 2 do out[i] = { kind = "s" .. i, size = opts.size } end
          return out
        end },
      },
    },
    prepare = function(session, _, opts, ready)
      b.prepares = b.prepares + 1
      b.seeds[#b.seeds + 1] = opts.seed
      b.readies[#b.readies + 1] = ready
      b.session = session
      if not holdReady then ready() end
    end,
    play = function(step, session)
      b.played[#b.played + 1] = step.kind
      if b.onPlay then return b.onPlay(step, session) end
      return "did " .. step.kind
    end,
    print = function(line) b.printed[#b.printed + 1] = line end,
    debug = function(tag, fmt, ...) b.debugs[#b.debugs + 1] = { tag = tag, text = fmt:format(...) } end,
  }
  for k, v in pairs(over or {}) do d[k] = v end
  b.d = d
  Sim.__AttachPanel = function(_, ctx) b.ctx = ctx end
  b.sim = Sim:New(d)
  b.sim:AddListener(function() b.notified = b.notified + 1 end)
  return b
end

--- The bench's descriptor gate: open or closed by b.gateOpen, with b.gateLine as its line.
local function gated()
  local b
  b = bench({ gate = function(session)
    b.gateCalls = b.gateCalls + 1
    b.gateSession = session
    return b.gateOpen, b.gateLine
  end })
  return b
end

local function lastPrinted(b) return b.printed[#b.printed] end
local function joined(list) return table.concat(list, ",") end

local function printedHas(b, needle)
  for _, line in ipairs(b.printed) do
    if line:find(needle, 1, true) then return true end
  end
  return false
end

--- The delay of every live timer (the kit's live set: armed, not canceled).
local function pendingDelays(m)
  local out = {}
  for _, t in ipairs(m.__timers()) do out[#out + 1] = t.delay end
  return out
end

-- ── the file and its attach ──────────────────────────────────────────────────────────────

test("sim timeline: the file registers on the shell's minor and in MODULES", function()
  local _, Sim = env()
  assertEqual(Sim.MODULES.SimTimeline, 3)
  assertEqual(Sim.__timelineMinor, 3)
  assertEqual(Sim.__timelineShellMinor, Sim.MINOR)
  assertEqual(type(Sim.__AttachTimeline), "function")
end)

test("sim timeline: the STRINGS keys the step machine prints are added to Sim.STRINGS", function()
  local _, Sim = env()
  for _, key in ipairs({ "BUILDING", "PLAYING", "NOT_PLAYING", "NOT_PAUSED", "DONE", "SETTLING",
    "STEP_LINE", "STEP_FAILED", "FINISHED", "ERROR" }) do
    assertEqual(type(Sim.STRINGS[key]), "string", key)
  end
  assertEqual(Sim.STRINGS.STEP_LINE, "Simulation step %d of %d: %s.")
  assertEqual(Sim.STRINGS.FINISHED, "Simulation finished: %s stop ends it.")
  assertEqual(Sim.STRINGS.NO_TIMELINE ~= nil, true, "the shell's own keys stay")
end)

test("sim timeline: the members overwrite the shell's fallbacks, and RunTo is not one of them", function()
  local b = bench()
  assertEqual(joined(b.sim:Steps()), "")
  local step, code = b.sim:Step()
  assertNil(step)
  assertEqual(code, "notRunning", "not the fallback's 'absent'")
  assertNil(b.sim.RunTo, "RunTo is Sim-internal (OWNER_SCOPE C.7)")
  assertEqual(type(b.ctx.runTo), "function", "handed to the panel through the handshake")
end)

-- ── Steps, Step and building ─────────────────────────────────────────────────────────────

test("sim timeline: Steps is the live list while running and {} idle", function()
  local b = bench()
  b.sim:Start({ scenario = "three" })
  local steps = b.sim:Steps()
  assertEqual(#steps, 3)
  assertEqual(steps[1].kind, "a")
  assertTrue(rawequal(b.sim:Steps(), steps), "the same live list each call")
  b.sim:Stop()
  assertEqual(#b.sim:Steps(), 0)
end)

test("sim timeline: the timeline is handed the def and the session's opts", function()
  local b = bench()
  b.sim:Start({ scenario = "sized", size = 5 })
  assertEqual(b.sim:Steps()[1].size, 5)
end)

test("sim timeline: Step answers building until ready(), then plays; a second ready is ignored", function()
  local b = bench(nil, true)
  b.sim:Start({ scenario = "three" })
  local step, code = b.sim:Step()
  assertNil(step)
  assertEqual(code, "building")
  assertEqual(#b.played, 0)
  b.readies[1]()
  local n = b.notified
  b.readies[1]()
  assertEqual(b.notified, n, "a second ready() tells nobody")
  step = b.sim:Step()
  assertEqual(step.kind, "a")
  assertEqual(joined(b.played), "a")
end)

test("sim timeline: Step stamps ranAt, detail and index, prints STEP_LINE and nothing else", function()
  local b = bench()
  b.sim:Start({ scenario = "three" })
  local step = b.sim:Step()
  assertEqual(step.detail, "did a")
  assertEqual(step.index, 1)
  assertEqual(type(step.ranAt), "number")
  local keys = {}
  for k in pairs(step) do keys[#keys + 1] = k end
  table.sort(keys)
  assertEqual(joined(keys), "detail,index,kind,label,ranAt", "the library writes nothing else")
  assertEqual(lastPrinted(b), "Simulation step 1 of 3: Alpha.")
  assertEqual(b.sim:Status().pos, 1)
end)

test("sim timeline: Step labels a step through panel.stepLabel when the host gives one", function()
  local b = bench({ panel = { stepLabel = function(step, i) return "Row " .. i .. " " .. step.kind end } })
  b.sim:Start({ scenario = "three" })
  b.sim:Step()
  assertEqual(lastPrinted(b), "Simulation step 1 of 3: Row 1 a.")
end)

test("sim timeline: Step answers done after the last step, and the last step prints FINISHED", function()
  local b = bench()
  b.sim:Start({ scenario = "three" })
  b.sim:Step(); b.sim:Step(); b.sim:Step()
  assertEqual(lastPrinted(b), "Simulation finished: /host sim stop ends it.")
  local step, code = b.sim:Step()
  assertNil(step)
  assertEqual(code, "done")
  assertEqual(#b.played, 3)
end)

test("sim timeline: Step answers notRunning while idle", function()
  local b = bench()
  local step, code = b.sim:Step()
  assertNil(step)
  assertEqual(code, "notRunning")
end)

-- ── the gate ─────────────────────────────────────────────────────────────────────────────

test("sim timeline: a closed gate answers settling, prints its line and does not advance", function()
  local b = gated()
  b.sim:Start({ scenario = "three" })
  b.gateOpen, b.gateLine = false, "Waiting for the loot window."
  local step, code = b.sim:Step()
  assertNil(step)
  assertEqual(code, "settling")
  assertEqual(lastPrinted(b), "Waiting for the loot window.")
  assertEqual(b.sim:Status().pos, 0)
  assertTrue(b.sim:Status().settling)
  assertEqual(#b.played, 0)
  assertTrue(rawequal(b.gateSession, b.sim:Session()), "the gate is handed the session")
end)

test("sim timeline: a closed gate with no line prints SETTLING", function()
  local b = gated()
  b.sim:Start({ scenario = "three" })
  b.gateOpen = false
  b.sim:Step()
  assertEqual(lastPrinted(b), b.Sim.STRINGS.SETTLING)
end)

test("sim timeline: once the gate opens, Step plays and settling clears", function()
  local b = gated()
  b.sim:Start({ scenario = "three" })
  b.gateOpen = false
  b.sim:Step()
  b.gateOpen = true
  assertEqual(b.sim:Step().kind, "a")
  assertFalse(b.sim:Status().settling)
end)

test("sim timeline: with no gate the gate is always open", function()
  local b = bench()
  b.sim:Start({ scenario = "three" })
  assertEqual(b.sim:Step().kind, "a")
end)

-- ── Run and stepDelay ────────────────────────────────────────────────────────────────────

test("sim timeline: Run plays the first step at once and the next after the default 2 s", function()
  local b = bench()
  b.sim:Start({ scenario = "three" })
  assertTrue(b.sim:Run())
  assertEqual(joined(b.played), "a")
  assertTrue(b.sim:Status().playing)
  assertEqual(joined(pendingDelays(b.m)), "2")
  b.m.__fireTimers()
  assertEqual(joined(b.played), "a,b")
  b.m.__fireTimers()
  assertEqual(joined(b.played), "a,b,c")
  assertFalse(b.sim:Status().playing, "finished")
  assertEqual(lastPrinted(b), "Simulation finished: /host sim stop ends it.")
  assertEqual(#pendingDelays(b.m), 0, "no tick after the end")
end)

test("sim timeline: Run reads a constant stepDelay", function()
  local b = bench({ stepDelay = 0.5 })
  b.sim:Start({ scenario = "three" })
  b.sim:Run()
  assertEqual(joined(pendingDelays(b.m)), "0.5")
end)

test("sim timeline: Run reads stepDelay(step) for the step just played, when each timer is set", function()
  local asked = {}
  local b = bench({ stepDelay = function(step)
    asked[#asked + 1] = step.kind
    return step.kind == "a" and 1.5 or 3
  end })
  b.sim:Start({ scenario = "three" })
  b.sim:Run()
  assertEqual(joined(pendingDelays(b.m)), "1.5")
  b.m.__fireTimers()
  assertEqual(joined(pendingDelays(b.m)), "3")
  assertEqual(joined(asked), "a,b")
end)

test("sim timeline: Run answers notRunning, building, playing and done", function()
  local b = bench(nil, true)
  local ok, code = b.sim:Run()
  assertFalse(ok); assertEqual(code, "notRunning")
  b.sim:Start({ scenario = "three" })
  ok, code = b.sim:Run()
  assertFalse(ok); assertEqual(code, "building")
  b.readies[1]()
  assertTrue(b.sim:Run())
  ok, code = b.sim:Run()
  assertFalse(ok); assertEqual(code, "playing")
  b.m.__fireTimers(); b.m.__fireTimers()
  ok, code = b.sim:Run()
  assertFalse(ok); assertEqual(code, "done")
end)

test("sim timeline: a Run tick on a closed gate re-polls after 0.25 s without advancing", function()
  local b = gated()
  b.sim:Start({ scenario = "three" })
  b.gateOpen = false
  assertTrue(b.sim:Run())
  assertEqual(#b.played, 0)
  assertEqual(joined(pendingDelays(b.m)), "0.25")
  assertTrue(b.sim:Status().settling)
  assertTrue(b.sim:Status().playing)
  b.m.__fireTimers()
  assertEqual(#b.played, 0, "still closed")
  assertEqual(joined(pendingDelays(b.m)), "0.25")
  b.gateOpen = true
  b.m.__fireTimers()
  assertEqual(joined(b.played), "a")
  assertFalse(b.sim:Status().settling)
  assertEqual(joined(pendingDelays(b.m)), "2")
end)

test("sim timeline: the gate is checked before every step of a Run", function()
  local b = gated()
  b.sim:Start({ scenario = "three" })
  b.sim:Run()
  local before = b.gateCalls
  b.m.__fireTimers()
  assertTrue(b.gateCalls > before)
end)

-- ── Pause, Resume and Restart ────────────────────────────────────────────────────────────

test("sim timeline: Pause cancels the pending tick and leaves no orphan timer", function()
  local b = bench()
  b.sim:Start({ scenario = "three" })
  b.sim:Run()
  assertEqual(#b.m.__timers(), 1)
  assertTrue(b.sim:Pause())
  assertEqual(#b.m.__timers(), 0, "no live timer")
  assertEqual(b.m.__fireTimers(), 0)
  assertEqual(joined(b.played), "a")
  local s = b.sim:Status()
  assertFalse(s.playing)
  assertTrue(s.paused)
end)

test("sim timeline: Pause answers notPlaying when nothing plays", function()
  local b = bench()
  b.sim:Start({ scenario = "three" })
  local ok, code = b.sim:Pause()
  assertFalse(ok)
  assertEqual(code, "notPlaying")
end)

test("sim timeline: Resume continues a paused run; it answers notPaused otherwise", function()
  local b = bench()
  b.sim:Start({ scenario = "three" })
  local ok, code = b.sim:Resume()
  assertFalse(ok); assertEqual(code, "notPaused")
  b.sim:Run()
  b.sim:Pause()
  assertTrue(b.sim:Resume())
  assertEqual(joined(b.played), "a,b", "Resume is Run: the next step plays at once")
  assertFalse(b.sim:Status().paused)
  assertTrue(b.sim:Status().playing)
end)

test("sim timeline: Restart stops with 'restart' and starts the same scenario with a fresh seed", function()
  local b = bench()
  b.sim:Start({ scenario = "sized", size = 5, seed = 42 })
  b.sim:Step()
  assertTrue(b.sim:Restart())
  assertTrue(printedHas(b, b.Sim.STRINGS.STOPPED_RESTART))
  assertEqual(b.prepares, 2, "prepare ran again")
  assertEqual(b.seeds[1], 42)
  assertTrue(b.seeds[2] ~= 42, "a fresh seed")
  assertEqual(b.sim:Session().scenario, "sized")
  assertEqual(b.sim:Session().size, 5)
  assertEqual(b.sim:Status().pos, 0, "the new session starts at the top")
end)

test("sim timeline: Restart carries the caller's extra start options, all but seed (minor 2)", function()
  local got = {}
  local b = bench({ prepare = function(_, _, opts, ready) got[#got + 1] = opts; ready() end })
  local band = { low = 25, high = 35 }
  b.sim:Start({ scenario = "sized", size = 5, seed = 42, band = band, classFilter = "any" })
  assertTrue(b.sim:Restart())
  assertEqual(#got, 2, "prepare ran again")
  assertTrue(rawequal(got[2].band, band), "band carried")
  assertEqual(got[2].classFilter, "any", "classFilter carried")
  assertEqual(got[2].scenario, "sized")
  assertEqual(got[2].size, 5)
  assertTrue(got[2].seed ~= 42, "a fresh seed, never the carried one")
end)

test("sim timeline: Restart answers notRunning while idle", function()
  local b = bench()
  local ok, code = b.sim:Restart()
  assertFalse(ok)
  assertEqual(code, "notRunning")
end)

test("sim timeline: a refused Restart prints the refusal and answers false, refused", function()
  local refuse = false
  local b = bench({ refusal = function() if refuse then return "Not in combat." end end })
  b.sim:Start({ scenario = "three" })
  refuse = true
  local ok, code = b.sim:Restart()
  assertFalse(ok)
  assertEqual(code, "refused")
  assertEqual(lastPrinted(b), "Not in combat.")
  assertFalse(b.sim:IsActive())
end)

test("sim timeline: a Restart during an async prepare ignores the old ready() (C.1)", function()
  local b = bench(nil, true)
  b.sim:Start({ scenario = "three" })
  local oldReady = b.readies[1]
  b.sim:Restart()
  oldReady()
  local _, code = b.sim:Step()
  assertEqual(code, "building", "the stale ready() did not ready the new session")
  b.readies[2]()
  assertEqual(b.sim:Step().kind, "a")
end)

-- ── RunTo (Sim-internal) ─────────────────────────────────────────────────────────────────

test("sim timeline: RunTo plays up to and including index back to back, synchronous on an open gate", function()
  local b = bench()
  b.sim:Start({ scenario = "three" })
  assertTrue(b.ctx.runTo(2))
  assertEqual(joined(b.played), "a,b")
  assertEqual(#pendingDelays(b.m), 0, "no stepDelay timer")
  assertFalse(b.sim:Status().playing, "done, so the playing slot is free")
  assertTrue(printedHas(b, "Simulation step 2 of 3: Beta."), "the same per-step lines")
end)

test("sim timeline: RunTo waits on a closed gate by polling, then continues", function()
  local b = gated()
  b.sim:Start({ scenario = "three" })
  b.gateOpen = false
  assertTrue(b.ctx.runTo(2))
  assertEqual(#b.played, 0)
  assertEqual(joined(pendingDelays(b.m)), "0.25")
  b.gateOpen = true
  b.m.__fireTimers()
  assertEqual(joined(b.played), "a,b")
  assertEqual(#pendingDelays(b.m), 0)
end)

test("sim timeline: RunTo answers notRunning, building and done", function()
  local b = bench(nil, true)
  local ok, code = b.ctx.runTo(1)
  assertFalse(ok); assertEqual(code, "notRunning")
  b.sim:Start({ scenario = "three" })
  ok, code = b.ctx.runTo(1)
  assertFalse(ok); assertEqual(code, "building")
  b.readies[1]()
  b.ctx.runTo(3)
  ok, code = b.ctx.runTo(3)
  assertFalse(ok); assertEqual(code, "done")
end)

test("sim timeline: Run during a pending RunTo poll answers playing; a second RunTo retargets (C.2)", function()
  local b = gated()
  b.sim:Start({ scenario = "three" })
  b.gateOpen = false
  b.ctx.runTo(3)
  local ok, code = b.sim:Run()
  assertFalse(ok)
  assertEqual(code, "playing")
  -- minor 3: a click-ahead holds whatever plays and retargets, where it used to answer playing
  assertTrue(b.ctx.runTo(2), "a second click-ahead holds the first and retargets")
  assertEqual(#b.m.__timers(), 1, "one poll: the first one's was canceled")
  b.gateOpen = true
  b.m.__fireTimers()
  assertEqual(joined(b.played), "a,b")
  assertTrue(b.sim:Status().paused, "short of the last step: held")
end)

test("sim timeline: Pause cancels a pending RunTo poll (C.2)", function()
  local b = gated()
  b.sim:Start({ scenario = "three" })
  b.gateOpen = false
  b.ctx.runTo(3)
  assertTrue(b.sim:Pause())
  assertEqual(#b.m.__timers(), 0)
  b.gateOpen = true
  b.m.__fireTimers()
  assertEqual(#b.played, 0)
end)

test("sim timeline: Stop cancels a pending RunTo poll (C.2)", function()
  local b = gated()
  b.sim:Start({ scenario = "three" })
  b.gateOpen = false
  b.ctx.runTo(3)
  b.sim:Stop()
  assertEqual(#b.m.__timers(), 0)
  b.gateOpen = true
  b.m.__fireTimers()
  assertEqual(#b.played, 0)
  assertFalse(b.sim:Status().playing)
end)

test("sim timeline: a step failure ends a RunTo", function()
  local b = bench()
  b.onPlay = function(step) if step.kind == "a" then error("bad step") end end
  b.sim:Start({ scenario = "three" })
  b.ctx.runTo(3)
  assertEqual(joined(b.played), "a")
  assertTrue(b.sim:Status().paused)
end)

-- ── a play error, and the session token ──────────────────────────────────────────────────

test("sim timeline: a play error counts the step as run, pauses the run and prints STEP_FAILED", function()
  local b = bench()
  b.onPlay = function(step) if step.kind == "a" then error("bad step") end end
  b.sim:Start({ scenario = "three" })
  b.sim:Run()
  local step = b.sim:Steps()[1]
  assertEqual(step.detail, b.Sim.STRINGS.ERROR)
  assertEqual(step.index, 1)
  assertTrue(step.ranAt ~= nil)
  assertEqual(b.sim:Status().pos, 1)
  assertTrue(b.sim:Status().paused)
  assertFalse(b.sim:Status().playing)
  assertEqual(lastPrinted(b), b.Sim.STRINGS.STEP_FAILED:format(1, 3, "Alpha"))
  assertEqual(#b.m.__timers(), 0, "no next tick")
  local logged = false
  for _, line in ipairs(b.debugs) do
    if line.text:find("bad step", 1, true) then logged = true end
  end
  assertTrue(logged, "the error goes to the debug sink")
end)

test("sim timeline: a Stop inside play leaves no stamp, no STEP_LINE and no next tick (token)", function()
  local b = bench()
  b.onPlay = function() b.sim:Stop() end
  b.sim:Start({ scenario = "three" })
  local stepTable = b.sim:Steps()[1]
  b.sim:Run()
  assertNil(stepTable.ranAt)
  assertNil(stepTable.detail)
  assertNil(stepTable.index)
  assertFalse(printedHas(b, "Simulation step"))
  assertEqual(#b.m.__timers(), 0)
  assertEqual(b.m.__fireTimers(), 0)
end)

test("sim timeline: a Restart inside play leaves the new session untouched (token)", function()
  local b = bench()
  local restarted = false
  b.onPlay = function()
    if not restarted then restarted = true; b.sim:Restart() end
  end
  b.sim:Start({ scenario = "three" })
  local step, code = b.sim:Step()
  assertNil(step)
  assertEqual(code, "notRunning")
  assertEqual(b.sim:Status().pos, 0, "the new session is at the top")
  assertNil(b.sim:Steps()[1].ranAt)
end)

-- ── listeners and Status ─────────────────────────────────────────────────────────────────

test("sim timeline: listeners fire on start, ready, step, run, pause and stop", function()
  local b = bench(nil, true)
  local n = b.notified
  b.sim:Start({ scenario = "three" })
  assertTrue(b.notified > n, "start"); n = b.notified
  b.readies[1]()
  assertTrue(b.notified > n, "ready"); n = b.notified
  b.sim:Step()
  assertTrue(b.notified > n, "step"); n = b.notified
  b.sim:Run()
  assertTrue(b.notified > n, "run"); n = b.notified
  b.sim:Pause()
  assertTrue(b.notified > n, "pause"); n = b.notified
  b.sim:Stop()
  assertTrue(b.notified > n, "stop")
end)

test("sim timeline: Status carries pos, total, playing, paused, settling and ready", function()
  local b = bench(nil, true)
  local s = b.sim:Status()
  assertEqual(s.pos, 0); assertEqual(s.total, 0)
  assertFalse(s.playing); assertFalse(s.paused); assertFalse(s.settling); assertFalse(s.ready)
  b.sim:Start({ scenario = "three" })
  s = b.sim:Status()
  assertEqual(s.total, 3); assertFalse(s.ready)
  b.readies[1]()
  b.sim:Run()
  s = b.sim:Status()
  assertEqual(s.pos, 1); assertEqual(s.total, 3); assertTrue(s.playing); assertTrue(s.ready)
  b.sim:Stop()
  s = b.sim:Status()
  assertEqual(s.pos, 0); assertEqual(s.total, 0); assertFalse(s.playing); assertFalse(s.paused)
end)

test("sim timeline: every timer is a session After, so Stop leaves none", function()
  local b = bench()
  b.sim:Start({ scenario = "three" })
  b.sim:Run()
  b.sim:Stop()
  assertEqual(#b.m.__timers(), 0)
end)
