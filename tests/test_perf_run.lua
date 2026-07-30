-- tests/test_perf_run.lua — the sampler, the combat-gated measurement windows, suspend/resume,
-- and the announcements that come out of them.

local T = _G.LK_TEST
local mocks = T.mocks
local test, assertEqual, assertTrue, assertFalse =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse
local Fixture = dofile("tests/fixture.lua")

-- Drive one sampler frame by hand. The real client calls OnUpdate every frame with the elapsed
-- seconds; a test says exactly how much time passed and whether the player was in combat, so every
-- assertion below is exact rather than wall-clock flaky.
local function tick(p, seconds, combat)
  mocks.__inCombat = combat and true or false
  local f = p.__sampler()
  assertTrue(f ~= nil, "sampler frame exists")
  f:__fire("OnUpdate", seconds)
end

local function startExperiment(p)
  p.Start("test")
end

-- End an experiment AND put the host fully back. Stop() deliberately leaves the suspend state
-- alone, so a test that armed window B would otherwise leak p.suspended = true into later tests.
local function finish(p)
  p.Stop()
  if p.suspended then p.Resume() end
end

-- ── suspend / resume ────────────────────────────────────────────────────────────────────────

test("lib: suspend returns false when already suspended", function()
  local p = Fixture.new()
  assertTrue(p.Suspend(), "first call suspends")
  assertFalse(p.Suspend(), "second is a no-op")
  p.Resume()
end)

test("lib: resume returns false when not suspended", function()
  local p = Fixture.new()
  assertFalse(p.Resume(), "nothing to resume")
end)

test("lib: the suspended state is session-only, never persisted", function()
  local p = Fixture.new()
  p.Suspend()
  assertEqual(_G.TestHostPerfDB, nil, "suspending writes nothing to the SavedVariables ring")
  p.Resume()
end)

-- ── lifecycle logging ───────────────────────────────────────────────────────────────────────
--
-- The capture's phase boundaries belong in the console timeline next to the player's own combat
-- log entries. Matching a suspend against the combat it happened in is exactly how the first
-- capture's unequal-combat confound was spotted; reconstructing it from memory afterwards is
-- guesswork.

test("lib: starting an experiment logs it", function()
  local p, rec = Fixture.new()
  p.Start("solo")
  local lines = table.concat(rec.log, "\n")
  assertTrue(lines:find("run started", 1, true) ~= nil, "says what happened")
  assertTrue(lines:find("solo", 1, true) ~= nil, "and which capture: " .. lines)
end)

test("lib: stopping an experiment logs both arm durations", function()
  local p, rec = Fixture.new()
  local arms = p.__fpsArms()
  arms.active.seconds, arms.active.frames = 60, 7000
  arms.suspended.seconds, arms.suspended.frames = 30, 3500
  p.Stop()
  local lines = table.concat(rec.log, "\n")
  assertTrue(lines:find("run finished", 1, true) ~= nil, "logged: " .. lines)
  assertTrue(lines:find("60.0s", 1, true) ~= nil, "active arm duration")
  assertTrue(lines:find("30.0s", 1, true) ~= nil, "suspended arm duration")
end)

test("lib: suspend and resume are logged", function()
  local p, rec = Fixture.new()
  p.Suspend()
  local lines = table.concat(rec.log, "\n")
  assertTrue(lines:find("SUSPENDED", 1, true) ~= nil, "suspend logged: " .. lines)
  p.Resume()
  lines = table.concat(rec.log, "\n")
  assertTrue(lines:find("RESUMED", 1, true) ~= nil, "resume logged: " .. lines)
end)

test("lib: a no-op suspend or resume logs nothing", function()
  -- The line marks a real state transition; logging a rejected call would put phantom boundaries
  -- in the timeline that never happened.
  local p, rec = Fixture.new()
  p.Suspend()
  local before = #rec.log
  p.Suspend()
  assertEqual(#rec.log, before, "second suspend is silent")
  p.Resume()
  assertTrue(#rec.log > before, "the real resume still logs")
  local afterResume = #rec.log
  p.Resume()
  assertEqual(#rec.log, afterResume, "second resume is silent")
end)

test("lib: nothing is logged when no run is happening", function()
  -- Ungated does not mean chatty: the lines only exist inside a run.
  local p, rec = Fixture.new()
  assertEqual(#rec.log, 0, "an idle instance writes nothing")
end)

-- ── combat-gated measurement windows ────────────────────────────────────────────────────────
--
-- The A/B is a pair of explicitly-armed windows that open when PLAYER combat starts and close when
-- it ends, rather than continuous sampling split by suspend state. Continuous sampling folded every
-- environmental difference into the result: two real captures were lost that way, one with the
-- active arm at ~78% combat against a suspended arm at ~100%, one with arms of 72.3s and 59.2s.

test("lib: an armed window samples nothing until combat begins", function()
  local p = Fixture.new()
  startExperiment(p)
  p.Measure("a")
  tick(p, 1.0, false)
  tick(p, 1.0, false)
  assertEqual(p.__fpsArms().active.frames, 0, "out of combat is not measured")
  assertTrue(p.armed ~= nil, "still waiting")
  assertFalse(p.on, "and the brackets stay closed")
  finish(p)
end)

test("lib: a window opens on combat and accumulates", function()
  local p = Fixture.new()
  startExperiment(p)
  p.Measure("a")
  tick(p, 0.5, true)
  tick(p, 0.5, true)
  assertEqual(p.recording, "active", "window open")
  assertEqual(p.__fpsArms().active.frames, 2, "two frames")
  assertEqual(p.__fpsArms().active.seconds, 1, "one second")
  assertTrue(p.on, "brackets record inside a window")
  finish(p)
end)

test("lib: a window closes when combat ends and stops accumulating", function()
  local p = Fixture.new()
  startExperiment(p)
  p.Measure("a")
  tick(p, 0.5, true)
  tick(p, 0.5, false)            -- combat ended: closes the window
  tick(p, 9.0, false)            -- and nothing lands afterwards
  tick(p, 9.0, true)             -- not even a later, unrelated fight
  assertEqual(p.recording, nil, "window closed")
  assertEqual(p.__fpsArms().active.frames, 1, "only the in-combat frame counted")
  assertFalse(p.on, "brackets closed with the window")
  finish(p)
end)

test("lib: the walk between windows is never measured", function()
  -- The whole point: reset a dungeon, run back, wait for respawns - none of it contaminates a run.
  local p = Fixture.new()
  startExperiment(p)
  p.Measure("a")
  tick(p, 1.0, true)
  tick(p, 1.0, false)
  for _ = 1, 20 do tick(p, 5.0, false) end   -- a long walk back
  p.Measure("b")
  tick(p, 1.0, true)
  local arms = p.__fpsArms()
  assertEqual(arms.active.seconds, 1, "arm A holds only its own combat")
  assertEqual(arms.suspended.seconds, 1, "arm B likewise")
  finish(p)
end)

test("lib: measure b suspends the addon and measure a resumes it", function()
  -- The suspend state is the independent variable, so arming sets it - it cannot be forgotten.
  local p = Fixture.new()
  startExperiment(p)
  p.Measure("b")
  assertTrue(p.suspended, "B suspends")
  p.Measure("a")
  assertFalse(p.suspended, "A resumes")
  finish(p)
end)

test("lib: window B still samples while the addon is suspended", function()
  -- Suspend unregisters the host's event frames, so a combat-EVENT-driven window would never open
  -- for arm B. The sampler polls UnitAffectingCombat on its own frame precisely to avoid that.
  local p = Fixture.new()
  startExperiment(p)
  p.Measure("b")
  assertTrue(p.suspended, "suspended")
  tick(p, 0.5, true)
  tick(p, 0.5, true)
  assertEqual(p.__fpsArms().suspended.frames, 2, "arm B sampled anyway")
  finish(p)
end)

test("lib: re-arming a window zeroes it rather than averaging in", function()
  -- A botched pull should be redoable with the same command.
  local p = Fixture.new()
  startExperiment(p)
  p.Measure("a")
  tick(p, 1.0, true)
  tick(p, 1.0, false)
  assertEqual(p.__fpsArms().active.seconds, 1, "first attempt recorded")
  p.Measure("a")
  tick(p, 2.0, true)
  assertEqual(p.__fpsArms().active.seconds, 2, "second attempt replaced it")
  finish(p)
end)

test("lib: arming a window mid-combat closes the one already open", function()
  local p = Fixture.new()
  startExperiment(p)
  p.Measure("a")
  tick(p, 1.0, true)
  p.Measure("b")
  assertEqual(p.recording, nil, "A was closed, B not yet open")
  assertEqual(p.__fpsArms().active.seconds, 1, "A kept what it had")
  finish(p)
end)

test("lib: Measure is rejected outside an experiment", function()
  local p = Fixture.new()
  local arm, err = p.Measure("a")
  assertEqual(arm, nil, "refused")
  assertEqual(err, "no experiment", "with a reason the caller can branch on")
end)

test("lib: Measure rejects an unknown window token", function()
  local p = Fixture.new()
  startExperiment(p)
  local arm, err = p.Measure("c")
  assertEqual(arm, nil, "refused")
  assertEqual(err, "unknown window", "and says why")
  finish(p)
end)

test("lib: Measure accepts either case", function()
  local p = Fixture.new()
  startExperiment(p)
  assertEqual(p.Measure("A"), "active", "uppercase A")
  assertEqual(p.Measure("B"), "suspended", "uppercase B")
  finish(p)
end)

test("lib: Stop closes an open window rather than discarding it", function()
  local p = Fixture.new()
  startExperiment(p)
  p.Measure("a")
  tick(p, 1.5, true)
  local record = p.Stop()
  assertEqual(p.recording, nil, "closed")
  assertEqual(record.fps.active.seconds, 1.5, "and its data survived into the record")
end)

test("lib: Stop detaches the sampler so an idle client pays nothing", function()
  local p = Fixture.new()
  startExperiment(p)
  p.Stop()
  assertEqual(p.__sampler():GetScript("OnUpdate"), nil, "OnUpdate removed")
  assertFalse(p.run, "experiment over")
end)

test("lib: the sampler ignores ticks once the experiment is over", function()
  local p = Fixture.new()
  startExperiment(p)
  p.Measure("a")
  p.Stop()
  tick(p, 5.0, true)
  assertEqual(p.__fpsArms().active.frames, 0, "nothing accumulated after Stop")
end)

test("lib: two completed windows produce a delta", function()
  local p = Fixture.new()
  startExperiment(p)
  p.Measure("a")
  for _ = 1, 8 do tick(p, 0.0125, true) end     -- 0.1s, 8 frames -> 80 fps, 12.5 ms/frame
  tick(p, 0.1, false)
  p.Measure("b")
  for _ = 1, 10 do tick(p, 0.01, true) end      -- 0.1s, 10 frames -> 100 fps, 10 ms/frame
  local record = p.Stop()
  if p.suspended then p.Resume() end
  assertEqual(record.fps.deltaMsPerFrame, 2.5, "A costs 2.5 ms/frame more than B")
end)

-- ── experiment announcements ────────────────────────────────────────────────────────────────

test("lib: recording start and end are announced to chat AND the debug log", function()
  -- These fire mid-combat: chat is what the user actually sees, the console line is what survives
  -- into the copied log for later analysis. Both, deliberately.
  local p, rec = Fixture.new()
  p.Start("announce")
  p.Measure("a")
  tick(p, 0.5, true)          -- opens
  tick(p, 0.5, false)         -- closes
  p.Stop()

  local chatText = table.concat(rec.chat, "\n")
  local logText = table.concat(rec.log, "\n")

  assertTrue(chatText:find("RECORDING", 1, true) ~= nil, "chat announced the start: " .. chatText)
  assertTrue(chatText:find("ENDED", 1, true) ~= nil, "and the end")
  assertTrue(logText:find("RECORDING", 1, true) ~= nil, "console too: " .. logText)
  assertTrue(logText:find("ENDED", 1, true) ~= nil, "and the end")
end)

test("lib: the end announcement carries the duration and frame rate", function()
  local p, rec = Fixture.new()
  p.Start("dur")
  p.Measure("a")
  for _ = 1, 60 do tick(p, 0.05, true) end   -- 3.0s, 60 frames -> 20 fps
  tick(p, 0.1, false)
  p.Stop()
  local logText = table.concat(rec.log, "\n")
  assertTrue(logText:find("3.0s", 1, true) ~= nil, "duration: " .. logText)
  assertTrue(logText:find("60 frames", 1, true) ~= nil, "frames")
  assertTrue(logText:find("20.0 fps", 1, true) ~= nil, "and the rate")
end)

test("lib: the console log is plain text, free of colour escapes", function()
  -- The Copy window mirrors this buffer verbatim; colour codes in a log you are about to paste
  -- somewhere for analysis are noise.
  local p, rec = Fixture.new()
  p.Start("plain")
  p.Measure("a")
  tick(p, 0.5, true)
  p.Stop()
  local logText = table.concat(rec.log, "\n")
  assertEqual(logText:find("|c", 1, true), nil, "no colour escapes: " .. logText)
  assertTrue(logText:find("Experiment A", 1, true) ~= nil, "and it reads cleanly")
end)

test("lib: experiments are named A and B, never active/suspended", function()
  local p, rec = Fixture.new()
  p.Start("naming")
  p.Measure("b")
  tick(p, 0.5, true)
  p.Stop()
  if p.suspended then p.Resume() end
  local logText = table.concat(rec.log, "\n")
  assertTrue(logText:find("Experiment B", 1, true) ~= nil, "user-facing name: " .. logText)
end)

test("lib: the run start is logged with its context", function()
  local p, rec = Fixture.new()
  p.Start("logged run")
  p.Stop()
  local logText = table.concat(rec.log, "\n")
  assertTrue(logText:find("run started", 1, true) ~= nil, "start line: " .. logText)
  assertTrue(logText:find("logged run", 1, true) ~= nil, "with the label")
  assertTrue(logText:find("Testchar", 1, true) ~= nil, "and the context")
  assertTrue(logText:find("run finished", 1, true) ~= nil, "and the finish line")
end)

test("lib: arming logs which experiment and whether the addon is suspended", function()
  local p, rec = Fixture.new()
  p.Start("arm log")
  p.Measure("b")
  p.Stop()
  if p.suspended then p.Resume() end
  local logText = table.concat(rec.log, "\n")
  assertTrue(logText:find("armed", 1, true) ~= nil, "armed line: " .. logText)
  assertTrue(logText:find("SUSPENDED", 1, true) ~= nil, "and the addon state that defines the arm")
end)

-- ── the host contract ───────────────────────────────────────────────────────────────────────

test("lib: measure b calls the host's suspend, measure a its resume", function()
  local p, rec = Fixture.new()
  p.Start("cap")
  p.Measure("b")
  assertEqual(rec.calls[#rec.calls], "suspend", "arming B suspends the host")
  p.Measure("a")
  assertEqual(rec.calls[#rec.calls], "resume", "arming A resumes it")
end)

test("lib: cancelling a suspended run restores the host", function()
  local p, rec = Fixture.new()
  p.Start("cap")
  p.Measure("b")
  p.Cancel()
  assertEqual(rec.calls[#rec.calls], "resume", "cancel must never strand a host inert")
  assertFalse(p.suspended, "suspended cleared")
end)

test("lib: the stopwatch is driven per window", function()
  local p = Fixture.new()
  p.Start("cap")
  mocks.__stopwatch = {}
  p.Measure("a")
  assertEqual(mocks.__stopwatch[1], "clear", "arming resets the stopwatch")
  tick(p, 0.1, true)
  assertEqual(mocks.__stopwatch[2], "play", "recording starts it")
  tick(p, 0.1, false)
  assertEqual(mocks.__stopwatch[3], "pause", "the window closing pauses it")
end)
