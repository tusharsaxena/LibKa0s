-- tests/test_sim_start_panel.lua — Sim minor 5 (FB2-LK-01 of Ka0sAddonsCommonTasks
-- docs/2026-11-24-FEEDBACK_BATCH, decision D2): every start of a session shows the step panel.
--
-- The owner's words, 2026-11-24: "sim mode whether started from a command like /xx sim start
-- <scenario> or from just plain /xx sim should always show the sim stepper window". Until minor 5
-- only the bare `/xx sim` opened it; `start` and every other start path left it closed. The rule now
-- lives at the one choke point every start goes through, the session's own Start: the typed
-- `start`, the panel's Start row and picker, a Restart, the Master controls Sim box (the host's
-- toggleSim) and a host's own `sim:Start(opts)`. A headless session (no panel file, or its floor
-- unmet: the shell's ShowPanel fallback answers false) stays headless, and a refused start (stood
-- down, unknown scenario, already running) shows nothing.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse
local F = dofile("tests/fixture_sim_panel.lua")
local Fixture = dofile("tests/fixture_options.lua")

local bench, buttons = F.bench, F.buttons

test("sim start panel: a host's own sim:Start shows the panel", function()
  -- red under: the member start leaving the panel closed (minor 4).
  local b = bench()
  assertFalse(b.sim:IsPanelShown(), "closed before the start")
  local ok = b.sim:Start({ scenario = "three" })
  assertTrue(ok, "the start succeeds")
  assertTrue(b.sim:IsPanelShown(), "the start opened the step panel")
end)

test("sim start panel: a typed start shows the panel", function()
  -- red under: verbStart starting the session without the panel (the owner's /lh sim start loot).
  local b = bench()
  assertTrue(b.sim:RunVerb("start three"))
  assertTrue(b.sim:IsPanelShown(), "/host sim start three opened the step panel")
end)

test("sim start panel: a typed start reopens a panel the player closed", function()
  -- red under: the panel shown only on the first start of a game session.
  local b = bench()
  b.sim:RunVerb("start three")
  b.sim:RunVerb("stop")
  b.sim:HidePanel()
  assertFalse(b.sim:IsPanelShown())
  b.sim:RunVerb("start sized 5")
  assertTrue(b.sim:IsPanelShown(), "the second start shows it again")
end)

test("sim start panel: the bare verb still shows the panel and starts nothing", function()
  -- red under: the bare line's own ShowPanel lost in the move.
  local b = bench()
  assertTrue(b.sim:RunVerb(""))
  assertTrue(b.sim:IsPanelShown())
  assertFalse(b.sim:IsActive(), "the bare verb shows status and the panel, never starts")
end)

test("sim start panel: a Restart shows the panel again", function()
  -- red under: Restart's own Start skipping the panel after the player closed it mid-run.
  local b = bench()
  b.sim:Start({ scenario = "three" })
  b.sim:HidePanel()
  assertTrue(b.sim:Restart())
  assertTrue(b.sim:IsPanelShown(), "the restarted session shows its panel")
end)

test("sim start panel: the panel's Start row and picker start with the panel shown", function()
  -- red under: a click start hiding or failing to repaint the panel it came from.
  local b = bench()
  F.recording(b.m, function()
    local f = F.shown(b)
    buttons(f)[1]:__fire("OnClick")
    assertTrue(b.sim:IsActive(), "the Start row started a session")
    assertTrue(b.sim:IsPanelShown())
    b.sim:RunVerb("stop")
    f.picker.start:__fire("OnClick")
    assertTrue(b.sim:IsActive(), "the picker's Start started one")
    assertTrue(b.sim:IsPanelShown())
  end)
end)

test("sim start panel: the Master controls Sim box (the host's toggleSim) shows the panel", function()
  -- red under: a box tick that starts the session through the member and leaves the panel closed.
  local b = bench()
  local O = Fixture.new()
  local spec = { page = "general", addonName = "X", minimapPath = "global.minimap.hide",
    testModePath = "state.test", onResetAll = function() end, onResetPosition = function() end,
    isSimMode = function() return b.sim:IsActive() end,
    toggleSim = function()
      if b.sim:IsActive() then b.sim:Stop("stop") else b.sim:Start({ scenario = "three" }) end
    end }
  local box
  for _, row in ipairs(O.MasterControls(spec)) do
    if row.label == "Sim mode" then box = row end
  end
  assertTrue(box ~= nil, "the Sim mode row")
  box.set(true)
  assertTrue(b.sim:IsActive(), "the box started the session")
  assertTrue(b.sim:IsPanelShown(), "and the step panel opened")
end)

test("sim start panel: a refused start shows nothing", function()
  -- red under: the panel shown before the refusal checks, or on an unknown scenario.
  local b = bench()
  local ok = b.sim:Start({ scenario = "nope" })
  assertFalse(ok)
  assertFalse(b.sim:IsPanelShown(), "an unknown scenario opens no panel")
  b.stoodDown = true
  assertFalse(b.sim:Start({ scenario = "three" }))
  assertFalse(b.sim:RunVerb("start three"))
  assertFalse(b.sim:IsPanelShown(), "a stood-down library shows nothing")
end)

test("sim start panel: a headless session (no Widgets, no panel) starts and stays headless", function()
  -- red under: Start raising, or answering false, where ShowPanel is the shell's fallback.
  local b = bench(nil, nil, nil, { noWidgets = true })
  local ok = b.sim:Start({ scenario = "three" })
  assertTrue(ok, "a headless start succeeds")
  assertFalse(b.sim:IsPanelShown(), "and has no panel to show")
  assertEqual(#b.sim:Steps(), 3)
end)

test("sim start panel: a session that ended inside prepare shows nothing", function()
  -- red under: the panel shown for a session prepare already stopped.
  local b = bench({ prepare = function() error("boom") end })
  assertFalse(b.sim:Start({ scenario = "three" }))
  assertFalse(b.sim:IsPanelShown())
end)

test("sim start panel: a ShowPanel that raises never fails the start", function()
  -- red under: an unguarded ShowPanel call inside Start.
  local b = bench()
  b.sim.ShowPanel = function() error("panel broke") end
  local ok = b.sim:Start({ scenario = "three" })
  assertTrue(ok, "the session started regardless")
  assertTrue(b.sim:IsActive())
end)
