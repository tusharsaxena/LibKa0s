-- tests/test_perf_panel.lua — the clickable step panel (LibKa0s/PerfPanel.lua).
--
-- Progress() is the whole state model — asserted directly against the probe belongs in
-- test_perf_run.lua. This suite covers what the panel itself adds: the frame, the buttons, their
-- state-driven colour and clickability, and show/hide/toggle.
--
-- What a click actually DISPATCHES lives in test_perf_command.lua, next to the typed form of the
-- same command: the two must produce identical output, and asserting that in one place is what
-- keeps them from drifting.

local T = _G.LK_TEST
local mocks = T.mocks
local test, assertEqual, assertTrue, assertFalse =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse
local Fixture = dofile("tests/fixture.lua")
local Loader = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

-- Drive one sampler frame by hand, same idiom as test_perf_run.lua.
local function tick(p, seconds, combat)
  mocks.__inCombat = combat and true or false
  local f = p.__sampler()
  f:__fire("OnUpdate", seconds)
end

-- End an experiment AND put the host fully back. Stop() deliberately leaves the suspend state
-- alone, so a test that armed window B would otherwise leak p.suspended = true into a later test.
local function finish(p)
  p.Stop()
  if p.suspended then p.Resume() end
end

-- ── the step panel ──────────────────────────────────────────────────────────────────────────

test("lib: before a run Start is the one offered step", function()
  -- The panel is the entry point, not a mid-run companion: someone who remembers only the host's
  -- slash prefix has to be able to get a run going from it.
  local p = Fixture.new()
  local s = p.Progress()
  assertEqual(s.start, "ready", "start is clickable")
  assertEqual(s.measureA, "locked", "A")
  assertEqual(s.measureB, "locked", "B")
  assertEqual(s.finish, "locked", "finish")
  assertEqual(s.report, "locked", "report")
  assertEqual(s.cancel, "locked", "and nothing to cancel")
end)

test("lib: Start reads done while a run is in flight", function()
  local p = Fixture.new()
  p.Start("s")
  assertEqual(p.Progress().start, "done", "already started")
  p.Stop()
end)

test("lib: Start is offered again once a run has finished", function()
  -- Running another is the obvious next thing, and it resets everything on the way in.
  local p = Fixture.new()
  p.Start("s")
  p.Measure("a"); tick(p, 0.5, true); tick(p, 0.5, false)
  p.Stop()
  assertEqual(p.Progress().start, "ready", "ready for the next run")
  assertTrue(p.PanelIsActionable("start"), "and clickable")
end)

test("lib: starting a run makes exactly Measure A ready", function()
  local p = Fixture.new()
  p.Start("panel")
  local s = p.Progress()
  assertEqual(s.measureA, "ready", "A is next")
  assertEqual(s.measureB, "locked", "B waits its turn")
  assertEqual(s.finish, "locked", "finish waits")
  p.Stop()
end)

test("lib: an armed or recording experiment reads busy, not ready", function()
  local p = Fixture.new()
  p.Start("panel")
  p.Measure("a")
  assertEqual(p.Progress().measureA, "busy", "armed is busy")
  tick(p, 0.5, true)
  assertEqual(p.Progress().measureA, "busy", "recording is busy too")
  assertEqual(p.Progress().measureB, "locked", "and B stays locked meanwhile")
  p.Stop()
end)

test("lib: completing A unlocks B and nothing else", function()
  local p = Fixture.new()
  p.Start("panel")
  p.Measure("a")
  tick(p, 0.5, true)
  tick(p, 0.5, false)
  local s = p.Progress()
  assertEqual(s.measureA, "done", "A done")
  assertEqual(s.measureB, "ready", "B is next")
  assertEqual(s.finish, "locked", "finish still locked")
  p.Stop()
end)

test("lib: completing B unlocks Finish", function()
  local p = Fixture.new()
  p.Start("panel")
  p.Measure("a"); tick(p, 0.5, true); tick(p, 0.5, false)
  p.Measure("b"); tick(p, 0.5, true); tick(p, 0.5, false)
  local s = p.Progress()
  assertEqual(s.measureB, "done", "B done")
  assertEqual(s.finish, "ready", "finish is next")
  assertEqual(s.report, "locked", "review waits for the run to end")
  finish(p)
end)

test("lib: finishing unlocks Report and Dump", function()
  local p = Fixture.new()
  p.Start("panel")
  p.Measure("a"); tick(p, 0.5, true); tick(p, 0.5, false)
  p.Measure("b"); tick(p, 0.5, true); tick(p, 0.5, false)
  p.Stop()
  if p.suspended then p.Resume() end
  local s = p.Progress()
  assertEqual(s.finish, "done", "finish done")
  assertEqual(s.report, "ready", "report available")
  assertEqual(s.dump, "ready", "dump available")
end)

test("lib: exactly one step is ready at any point in a run", function()
  -- The panel's entire purpose: a run cannot be done out of order.
  local p = Fixture.new()
  local function readyCount()
    local n = 0
    for _, state in pairs(p.Progress()) do if state == "ready" then n = n + 1 end end
    return n
  end
  p.Start("panel")
  assertEqual(readyCount(), 1, "after start")
  p.Measure("a")
  assertEqual(readyCount(), 0, "while A is armed, nothing else is offered")
  tick(p, 0.5, true); tick(p, 0.5, false)
  assertEqual(readyCount(), 1, "after A")
  p.Measure("b")
  assertEqual(readyCount(), 0, "while B is armed")
  tick(p, 0.5, true); tick(p, 0.5, false)
  assertEqual(readyCount(), 1, "after B")
  finish(p)
end)

test("lib: re-arming a completed experiment sends it back to busy", function()
  local p = Fixture.new()
  p.Start("panel")
  p.Measure("a"); tick(p, 0.5, true); tick(p, 0.5, false)
  assertEqual(p.Progress().measureA, "done", "done after the first attempt")
  p.Measure("a")
  assertEqual(p.Progress().measureA, "busy", "redoing it is in progress again")
  assertEqual(p.Progress().measureB, "locked", "and B relocks until A completes")
  p.Stop()
end)

test("lib: a window that caught no frames still counts as completed", function()
  -- Completion is tracked explicitly rather than inferred from frame counts: the step happened,
  -- whatever it caught.
  local p = Fixture.new()
  p.Start("panel")
  p.Measure("a")
  tick(p, 0.0, true)     -- opens, accumulates a zero-length frame
  tick(p, 0.0, false)    -- closes immediately
  assertEqual(p.Progress().measureA, "done", "still done")
  p.Stop()
end)

test("lib: Reset clears completion, so a fresh run starts from step one", function()
  local p = Fixture.new()
  p.Start("panel")
  p.Measure("a"); tick(p, 0.5, true); tick(p, 0.5, false)
  p.Stop()
  p.Start("second")
  assertEqual(p.Progress().measureA, "ready", "A is offered again")
  assertEqual(p.Progress().measureB, "locked", "and B is not")
  p.Stop()
end)

test("lib: the panel renders every step and tracks their states", function()
  local p = Fixture.new()
  p.Start("panel")
  p.Measure("a"); tick(p, 0.5, true); tick(p, 0.5, false)
  p.ShowPanel()
  local f = p.__panel()
  assertTrue(f ~= nil, "panel built")
  assertTrue(f:IsShown(), "and shown")
  for _, step in ipairs(p.STEPS) do
    assertTrue(f.buttons[step.key] ~= nil, "button for " .. step.key)
  end
  assertEqual(f.buttons.measureA.__label, "Measure A (with the addon)", "label is plain text")
  assertEqual(f.buttons.measureA.__state, "done", "a completed step carries its state")
  assertEqual(f.buttons.measureB.__state, "ready", "as does the next one")
  assertEqual(f.buttons.finish.__state, "locked", "and the ones beyond it")
  p.Stop()
  p.HidePanel()
end)

test("lib: a locked panel button refuses to act when clicked", function()
  -- Belt and braces over Disable(): a step that runs out of order corrupts the run the panel exists
  -- to protect, and a script can be fired directly.
  local p = Fixture.new()
  p.Start("panel")
  p.ShowPanel()
  local f = p.__panel()
  assertEqual(p.PanelStateOf("finish"), "locked", "finish is locked")
  f.buttons.finish:__fire("OnClick")
  assertTrue(p.run, "the run is still going \226\128\148 the click did nothing")
  p.Stop()
  p.HidePanel()
end)

test("lib: the panel repaints itself on every state transition", function()
  local p = Fixture.new()
  p.ShowPanel()
  p.Start("cap")
  assertEqual(p.__panel().buttons.measureA.__state, "ready",
    "no bus hop: the panel owns the state it renders and repaints directly")
end)

test("lib: every step row carries a status dot, drawn not glyphed", function()
  -- A text tick rendered as tofu in the default font, and any Interface\\... path is an unverifiable
  -- guess. The dot is a SetColorTexture, which has no font or art dependency.
  local p = Fixture.new()
  p.Start("dots")
  p.ShowPanel()
  local f = p.__panel()
  for _, step in ipairs(p.STEPS) do
    assertTrue(f.buttons[step.key].dot ~= nil, "dot for " .. step.key)
  end
  p.Stop()
  p.HidePanel()
end)

test("lib: labels are plain text with no decoration baked in", function()
  local p = Fixture.new()
  p.Start("labels")
  p.ShowPanel()
  local f = p.__panel()
  for _, step in ipairs(p.STEPS) do
    assertEqual(f.buttons[step.key].__label, step.label,
      step.key .. " renders its label verbatim")
  end
  p.Stop()
  p.HidePanel()
end)

-- ── the cancel step ─────────────────────────────────────────────────────────────────────────

test("lib: cancel is offered throughout a run and nowhere else", function()
  -- A live-looking button that would discard nothing is just a way to worry someone: after `finish`
  -- the run is already saved, and before `start` there is nothing to abandon.
  local p = Fixture.new()
  assertEqual(p.Progress().cancel, "locked", "before a run")
  p.Start("c")
  assertEqual(p.Progress().cancel, "cancel", "during one")
  p.Measure("a")
  assertEqual(p.Progress().cancel, "cancel", "mid-experiment")
  tick(p, 0.5, true); tick(p, 0.5, false)
  assertEqual(p.Progress().cancel, "cancel", "between experiments")
  p.Stop()
  assertEqual(p.Progress().cancel, "locked", "and greyed out once finished")
end)

test("lib: cancel has its own state, so it never reads as the next step", function()
  local p = Fixture.new()
  p.Start("c")
  local ready = 0
  for _, state in pairs(p.Progress()) do if state == "ready" then ready = ready + 1 end end
  assertEqual(ready, 1, "cancel does not inflate the ready count")
end)

test("lib: cancelling discards the run without saving it", function()
  local p = Fixture.new()
  p.Start("thrown away")
  p.Measure("a"); tick(p, 0.5, true); tick(p, 0.5, false)
  assertTrue(p.Cancel(), "cancelled")
  assertEqual(_G.TestHostPerfDB, nil, "nothing was written to the ring")
  assertFalse(p.run, "run over")
  assertEqual(p.__fpsArms().active.frames, 0, "counters zeroed")
  assertEqual(p.Progress().measureA, "locked", "and the progression is back to the start")
end)

test("lib: cancelling restores a suspended addon", function()
  local p, rec = Fixture.new()
  p.Start("c")
  p.Measure("b")
  assertTrue(p.suspended, "B suspended it")
  p.Cancel()
  assertFalse(p.suspended, "cancel brought it back")
  assertEqual(rec.calls[#rec.calls], "resume", "and the host was resumed with it")
end)

test("lib: cancelling mid-recording does not announce the experiment as ended", function()
  -- It goes through neither closeWindow nor Stop: marking a thrown-away window "ENDED" would be a
  -- lie about a measurement that never counted.
  local p, rec = Fixture.new()
  p.Start("c")
  p.Measure("a")
  tick(p, 0.5, true)
  p.Cancel()
  local lines = table.concat(rec.log, "\n")
  assertEqual(lines:find("ENDED", 1, true), nil, "no end-of-experiment line: " .. lines)
  assertTrue(lines:find("CANCELLED", 1, true) ~= nil, "but it says it was cancelled")
end)

test("lib: cancelling detaches the sampler", function()
  local p = Fixture.new()
  p.Start("c")
  p.Cancel()
  assertEqual(p.__sampler():GetScript("OnUpdate"), nil, "no per-frame cost left behind")
end)

test("lib: cancel returns false when there is nothing to cancel", function()
  local p = Fixture.new()
  assertFalse(p.Cancel(), "no run in flight")
end)

test("lib: a cancelled run leaves the next one clean", function()
  local p = Fixture.new()
  p.Start("first")
  p.Measure("a"); tick(p, 0.5, true); tick(p, 0.5, false)
  p.Cancel()
  p.Start("second")
  assertEqual(p.Progress().measureA, "ready", "A is offered again")
  assertEqual(p.__fpsArms().active.frames, 0, "with nothing carried over")
  p.Stop()
end)

-- ── the three-column layout ─────────────────────────────────────────────────────────────────

test("lib: every row shows its slash command", function()
  local p = Fixture.new()
  p.Start("cols")
  p.ShowPanel()
  local f = p.__panel()
  assertEqual(f.buttons.measureA.__command, "/th perf measure a", "A")
  assertEqual(f.buttons.finish.__command, "/th perf finish", "finish")
  assertEqual(f.buttons.cancel.__command, "/th perf cancel", "cancel")
  p.Stop()
  p.HidePanel()
end)

test("lib: cancel stays clickable while a run is mid-experiment", function()
  local p = Fixture.new()
  p.Start("c")
  p.Measure("a")
  tick(p, 0.5, true)
  p.ShowPanel()
  assertFalse(p.PanelIsActionable("measureA"), "A is busy, not clickable")
  assertFalse(p.PanelIsActionable("finish"), "finish still locked")
  assertTrue(p.PanelIsActionable("cancel"), "but the way out is always there")
  p.Cancel()
  p.HidePanel()
end)

test("lib: cancel is not clickable once the run is finished", function()
  local p = Fixture.new()
  p.Start("c")
  p.Measure("a"); tick(p, 0.5, true); tick(p, 0.5, false)
  p.Stop()
  p.ShowPanel()
  assertEqual(p.PanelStateOf("cancel"), "locked", "greyed out")
  assertFalse(p.PanelIsActionable("cancel"), "and inert")
  p.HidePanel()
end)

-- ── showing and hiding the panel ────────────────────────────────────────────────────────────

test("lib: hiding the panel never touches the run", function()
  -- A hidden window is not an abandoned capture. Conflating the two would make dismissing a panel a
  -- destructive act.
  local p = Fixture.new()
  p.Start("vis")
  p.Measure("a")
  p.ShowPanel()
  p.HidePanel()
  assertFalse(p.IsPanelShown(), "hidden")
  assertTrue(p.run, "run still going")
  assertEqual(p.armed, "active", "and the armed experiment survived")
  p.Cancel()
end)

test("lib: Toggle flips visibility both ways", function()
  local p = Fixture.new()
  p.HidePanel()
  p.TogglePanel()
  assertTrue(p.IsPanelShown(), "shown")
  p.TogglePanel()
  assertFalse(p.IsPanelShown(), "and hidden again")
end)

test("lib: decorate is handed the frame and a way to close it", function()
  local seen
  local p = Fixture.new({
    decorate = function(frame, api)
      seen = { frame = frame, hide = api.Hide, titleH = api.TITLE_H }
    end,
  })
  p.ShowPanel()
  assertTrue(seen ~= nil and seen.frame ~= nil, "decorate ran once, with the frame")
  assertTrue(type(seen.hide) == "function", "and a Hide it can wire to a close button")
  assertTrue(type(seen.titleH) == "number", "and the metrics to position against")
  seen.hide()
  assertFalse(p.IsPanelShown(), "hiding through the api works")
  assertTrue(p.run == false, "and never touches the run")
end)

test("lib: a host that passes no decorate still gets a working panel", function()
  local p = Fixture.new()
  p.ShowPanel()
  assertTrue(p.IsPanelShown(), "degrades to a plain frame, not an error")
end)

test("lib: report and dump stay clickable after use, but read as done", function()
  -- Re-reading a summary or re-dumping the JSON costs nothing and is regularly wanted twice, so
  -- these are marked rather than disabled.
  local p = Fixture.new()
  p.Start("review")
  p.Measure("a"); tick(p, 0.5, true); tick(p, 0.5, false)
  p.Measure("b"); tick(p, 0.5, true); tick(p, 0.5, false)
  p.Stop()
  if p.suspended then p.Resume() end

  assertEqual(p.Progress().report, "ready", "offered once the run is finished")
  assertTrue(p.MarkReviewed("report"), "marking it takes")
  assertEqual(p.Progress().report, "used", "now reads as used")
  assertTrue(p.PanelIsActionable("report"), "and is still clickable")
  assertEqual(p.Progress().dump, "ready", "dump is independent")
end)

test("lib: marking a review action twice is a no-op", function()
  local p = Fixture.new()
  p.Start("review")
  p.MarkReviewed("dump")
  assertFalse(p.MarkReviewed("dump"), "second time changes nothing")
  p.Stop()
end)

test("lib: MarkReviewed ignores keys that are not review actions", function()
  local p = Fixture.new()
  assertFalse(p.MarkReviewed("finish"), "finish is not a review action")
  assertFalse(p.MarkReviewed("nonsense"), "nor is anything else")
end)

test("lib: a fresh run clears the review marks", function()
  local p = Fixture.new()
  p.Start("first")
  p.MarkReviewed("report")
  p.MarkReviewed("dump")
  p.Stop()
  p.Start("second")
  assertFalse(p.__reviewed().report, "report unmarked")
  assertFalse(p.__reviewed().dump, "dump unmarked")
  p.Stop()
end)

test("lib: the panel titles itself like the debug console", function()
  local p = Fixture.new()
  p.ShowPanel()
  assertTrue(p.__panel().title ~= nil, "it has a title")
  p.HidePanel()
end)

test("lib: a locale table filled in after New still reaches the rows", function()
  -- Hosts on the Ka0s standard build NS.L from a separate locale file, which is under no obligation
  -- to have loaded by the time :New() runs. Resolving every label once at :New() froze the panel to
  -- the built-in English for those hosts, silently and permanently.
  local L = {}
  local p = Fixture.new({ L = L })
  L.STEP_START = "Demarrer"
  L.STEP_CANCEL = "Annuler"
  p.ShowPanel()
  local f = p.__panel()
  assertEqual(f.buttons.start.__label, "Demarrer", "the override took")
  assertEqual(f.buttons.cancel.__label, "Annuler", "for every overridden row")
  assertEqual(f.buttons.finish.__label, "Finish perf run", "and the rest keep the built-in string")
  p.HidePanel()
end)

test("lib: every step label names what it acts on", function()
  -- The rows are read at a glance mid-run, out of the panel's context; "Finish" alone does not say
  -- finish what.
  local p = Fixture.new()
  p.Start("labels")
  p.ShowPanel()
  local f = p.__panel()
  assertEqual(f.buttons.start.__label, "Start perf run", "start")
  assertEqual(f.buttons.finish.__label, "Finish perf run", "finish")
  assertEqual(f.buttons.dump.__label, "JSON Dump", "dump")
  assertEqual(f.buttons.cancel.__label, "Cancel perf run", "cancel")
  p.Cancel()
  p.HidePanel()
end)

-- ── panel-less hosts ────────────────────────────────────────────────────────────────────────
--
-- Every fixture above loads Perf.lua and PerfPanel.lua together, so `p.STEPS` and friends are
-- always the real thing by the time a test sees them. A copy of the lib without PerfPanel.lua is
-- also a shipping shape (README documents ShowPanel/HidePanel/TogglePanel/RefreshPanel/IsPanelShown
-- as safe to call either way); this loads Perf.lua alone into a fresh env to prove STEPS,
-- PanelStateOf and PanelIsActionable degrade the same way rather than leaving P.STEPS nil and
-- P.PanelStateOf erroring.

test("lib: a panel-less instance answers STEPS, PanelStateOf and PanelIsActionable safely", function()
  local noPanelMocks = buildMocks()
  Loader.load("LibKa0s/Perf.lua", nil, noPanelMocks)
  local lib = noPanelMocks.LibStub("LibKa0s-Perf-1.0")
  local p = lib:New({
    name = "NoPanel", sv = "NoPanelPerfDB",
    suspend = function() end, resume = function() end,
  })
  assertEqual(#p.STEPS, 0, "no panel means no rows to draw")
  assertEqual(p.PanelStateOf("start"), "locked", "same nil-safe default the panel itself uses")
  assertFalse(p.PanelIsActionable("start"), "nothing is clickable without a panel to click")
end)
