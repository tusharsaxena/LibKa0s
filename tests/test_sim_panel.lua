-- tests/test_sim_panel.lua — LibKa0s-Sim-1.0's step panel, `SimPanel.lua`: the rows it composes from
-- the live session, the picker and the controls under them, the clicks, and where it sits.
--
-- Every case runs on a fresh environment with Core, Widgets, Sim, SimTimeline and SimPanel loaded
-- (tests/fixture_sim_panel.lua), and a descriptor whose callbacks record what they were asked. The
-- rows are read through `sim:PanelRows()`, the published pure list, so nothing here reaches a `__`
-- field to assert a row. The renderer's own cases (geometry, palette, hover) are
-- tests/test_sim_panel_render.lua's.
--
-- "The click path is the typed path": a click runs `RunVerb` (or the internal click-ahead, which
-- prints the same per-step lines), so the click cases run the same action on two benches, one
-- clicked and one typed, and compare every printed line.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local F = dofile("tests/fixture_sim_panel.lua")

local HOST_CHECK = F.HOST_CHECK
local ROW_H, GAP, TITLE_H, PAD, BAR_H = 22, 4, 24, 8, 22

--- A bench: a three-step scenario and a sized one, a recording play, an anchor frame the panel
--- docks to, and the panel members live. `over` is merged into the descriptor before New;
--- `panelOver` into d.panel. `prepare` calls ready() at once unless holdReady is set.
local function bench(over, holdReady, panelOver, envOpts)
  local m, Sim = F.env(envOpts)
  local b0 = { now = 1000 }
  m.time = function() return b0.now end            -- a fixed clock: RAN_AGO is deterministic
  local seam = Sim:NewSeam({ Probe = function() return "live" end }, { name = "Host" })
  local b = b0
  b.m, b.Sim, b.printed, b.played, b.readies, b.stoodDown = m, Sim, {}, {}, {}, false
  local panel = {
    anchorTo = function() return b.anchor end,
    check = HOST_CHECK,
    stepTip = function(step) return { { "Injects", step.kind } } end,
    startTip = { { "Builds", "the world" } },
    stopTip = { { "Ends", "the simulation" } },
  }
  for k, v in pairs(panelOver or {}) do panel[k] = v end
  local d = {
    name = "Host", seam = seam, slash = "/host sim",
    deliver = function() return 1 end,
    isStoodDown = function() return b.stoodDown end,
    scenarios = {
      names = { "three", "sized" },
      defs = {
        three = { label = "Three", timeline = function()
          return { { kind = "a", label = "Alpha" }, { kind = "b", label = "Beta" }, { kind = "c", label = "Gamma" } }
        end },
        sized = { label = "Sized", sizes = { 5, 10 }, timeline = function()
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
    panel = panel,
  }
  for k, v in pairs(over or {}) do d[k] = v end
  b.d = d
  b.sim = Sim:New(d)
  return b
end

local function joined(list, sep) return table.concat(list, sep or ",") end

--- The lines printed by fn(b) alone.
local function linesOf(b, fn)
  local from = #b.printed
  fn(b)
  local out = {}
  for i = from + 1, #b.printed do out[#out + 1] = b.printed[i] end
  return out
end

--- Each row's `state` joined, and each row's actionable flag as y/n joined.
local function states(rows)
  local out = {}
  for i, r in ipairs(rows) do out[i] = r.state end
  return joined(out)
end
local function actionable(rows)
  local out = {}
  for i, r in ipairs(rows) do out[i] = r.actionable and "y" or "n" end
  return joined(out, "")
end

--- True when any line of a row's tip carries `needle` in either column.
local function tipHas(row, needle)
  for _, line in ipairs(row.tip or {}) do
    local text = type(line) == "table" and (tostring(line[1]) .. " " .. tostring(line[2])) or tostring(line)
    if text:find(needle, 1, true) then return true end
  end
  return false
end

--- Show the panel under the recorder and answer its frame (the renderer's, through the seam's
--- handle; built on the first Show).
local function shown(b)
  assertTrue(b.sim:ShowPanel(), "ShowPanel")
  return b.m.__named[b.d.name .. "SimPanel"]
end

--- The row buttons of the shown panel, by composed position.
local function buttons(f)
  local out = {}
  for _, child in ipairs(f.__rowButtons or {}) do out[#out + 1] = child end
  return out
end

-- ── the file and its attach ──────────────────────────────────────────────────────────────

test("sim panel: the file registers on the shell's minor and in MODULES", function()
  local _, Sim = F.env()
  assertEqual(Sim.MODULES.SimPanel, 2)
  assertEqual(Sim.__panelMinor, 2)
  assertEqual(Sim.__panelShellMinor, Sim.MINOR)
  assertEqual(type(Sim.__AttachPanel), "function")
  assertEqual(type(Sim.__StepPanel), "function", "the renderer's internal test seam")
end)

test("sim panel: the STRINGS keys the panel draws are added to Sim.STRINGS", function()
  local _, Sim = F.env()
  for _, key in ipairs({ "PANEL_START", "START", "PANEL_STOP", "RUN_ALL", "PAUSE", "RESUME", "RESTART", "STOP",
    "RANDOM", "RAN_AGO" }) do
    assertEqual(type(Sim.STRINGS[key]), "string", key)
  end
  assertEqual(Sim.STRINGS.NO_TIMELINE ~= nil and Sim.STRINGS.STEP_LINE ~= nil, true, "the other files' keys stay")
end)

test("sim panel: the floor unmet (no Widgets): no attach, and the shell's fallbacks answer", function()
  local b = bench(nil, nil, nil, { noWidgets = true })
  assertNil(b.Sim.MODULES.SimPanel)
  assertNil(b.Sim.__AttachPanel)
  assertNil(b.Sim.__panelMinor)
  assertFalse(b.sim:ShowPanel())
  assertFalse(b.sim:IsPanelShown())
  assertEqual(#b.sim:PanelRows(), 0)
  b.sim:Start({ scenario = "three" })
  assertEqual(#b.sim:Steps(), 3, "a headless Sim (seam, session, timeline) is never lost to a missing panel")
  assertTrue(b.sim:Step() ~= nil)
end)

test("sim panel: the floor unmet (Core below 9): no attach", function()
  local b = bench(nil, nil, nil, { coreMinor = 8 })
  assertNil(b.Sim.MODULES.SimPanel)
  assertFalse(b.sim:ShowPanel())
  assertEqual(#b.sim:PanelRows(), 0)
end)

-- ── PanelRows ────────────────────────────────────────────────────────────────────────────

test("sim panel: idle, the rows preview the picked scenario at pos 0, every step locked", function()
  local b = bench()
  local rows = b.sim:PanelRows()
  assertEqual(#rows, 5, "Start, three steps, Stop")
  assertEqual(rows[1].key, "start"); assertEqual(rows[1].index, 0)
  assertEqual(rows[1].label, b.Sim.STRINGS.PANEL_START:format("Three"))
  assertEqual(rows[1].command, "/host sim start three")
  assertEqual(rows[2].key, "step"); assertEqual(rows[2].index, 1); assertEqual(rows[2].label, "Alpha")
  assertEqual(rows[4].index, 3); assertEqual(rows[4].command, "/host sim step")
  assertEqual(rows[5].key, "stop"); assertEqual(rows[5].index, 4); assertEqual(rows[5].command, "/host sim stop")
  assertEqual(rows[5].label, b.Sim.STRINGS.PANEL_STOP)
  assertEqual(states(rows), "ready,locked,locked,locked,locked")
  assertEqual(actionable(rows), "ynnnn", "only Start while idle")
  for _, r in ipairs(rows) do
    for _, k in ipairs({ "key", "index", "label", "command", "state", "actionable", "tip" }) do
      assertTrue(r[k] ~= nil, "every row carries " .. k)
    end
  end
end)

test("sim panel: PanelRows is a fresh list each call, and building it plays nothing", function()
  local b = bench()
  local a, c = b.sim:PanelRows(), b.sim:PanelRows()
  assertFalse(a == c)
  assertFalse(a[1] == c[1])
  assertEqual(#b.played, 0)
end)

test("sim panel: building: Start busy, every step locked and not actionable, Stop cancel", function()
  local b = bench(nil, true)
  b.sim:Start({ scenario = "three" })
  local rows = b.sim:PanelRows()
  assertEqual(states(rows), "busy,locked,locked,locked,cancel")
  assertEqual(actionable(rows), "nnnny", "only Stop before ready")
end)

test("sim panel: mid-run: done, ready, and ahead rows locked AND actionable", function()
  local b = bench()
  b.sim:Start({ scenario = "three" })
  assertEqual(states(b.sim:PanelRows()), "done,ready,locked,locked,cancel")
  assertEqual(actionable(b.sim:PanelRows()), "nyyyy", "ahead rows are click-ahead targets")
  b.sim:Step()
  local rows = b.sim:PanelRows()
  assertEqual(states(rows), "done,done,ready,locked,cancel")
  assertEqual(actionable(rows), "nnyyy")
  assertEqual(rows[2].tip[1][1], "Injects", "the host's stepTip")
  assertTrue(tipHas(rows[2], b.Sim.STRINGS.RAN_AGO:format("0s")), "a done row adds RAN_AGO")
  assertTrue(tipHas(rows[1], b.Sim.STRINGS.RAN_AGO:format("0s")), "so does a done Start row")
  assertFalse(tipHas(rows[3], "Ran "), "a row not run has no RAN_AGO")
  assertTrue(tipHas(rows[5], "Ends"), "the host's stopTip")
  b.now = 1000 + 125
  assertTrue(tipHas(b.sim:PanelRows()[2], b.Sim.STRINGS.RAN_AGO:format("2m")), "minutes")
  b.now = 1000 + 7300
  assertTrue(tipHas(b.sim:PanelRows()[2], b.Sim.STRINGS.RAN_AGO:format("2h")), "hours")
end)

test("sim panel: playing: the row at pos is busy", function()
  local b = bench()
  b.sim:Start({ scenario = "three" })
  b.sim:Run()                                     -- plays step 1 at once, the next on a timer
  assertEqual(states(b.sim:PanelRows()), "done,busy,ready,locked,cancel")
  b.sim:Pause()
  assertEqual(states(b.sim:PanelRows()), "done,done,ready,locked,cancel", "paused: the row is done")
end)

test("sim panel: settling: the row at pos is busy while the gate holds the next one", function()
  local open = true
  local b = bench({ gate = function() return open, "settling..." end })
  b.sim:Start({ scenario = "three" })
  b.sim:Step()
  open = false
  b.sim:Step()
  assertEqual(states(b.sim:PanelRows()), "done,busy,ready,locked,cancel")
end)

test("sim panel: done: every step done and none actionable; Stop still cancels", function()
  local b = bench()
  b.sim:Start({ scenario = "three" })
  for _ = 1, 3 do b.sim:Step() end
  local rows = b.sim:PanelRows()
  assertEqual(states(rows), "done,done,done,done,cancel")
  assertEqual(actionable(rows), "nnnny")
end)

test("sim panel: stopping: nothing is actionable, and the Stop row is locked", function()
  local b = bench()
  local seen
  b.sim:OnStopGuarded(function() seen = b.sim:PanelRows() end)
  b.sim:Start({ scenario = "three" })
  b.sim:Stop()
  assertTrue(seen ~= nil)
  assertEqual(actionable(seen), ("n"):rep(#seen))
  assertEqual(seen[1].state, "busy")
  assertEqual(seen[#seen].state, "locked")
end)

test("sim panel: after a stop the rows are the idle preview again", function()
  local b = bench()
  b.sim:Start({ scenario = "three" })
  b.sim:Step()
  b.sim:Stop()
  assertEqual(states(b.sim:PanelRows()), "ready,locked,locked,locked,locked")
end)

test("sim panel: d.panel.stepLabel names the rows (step, i, steps)", function()
  local b = bench(nil, nil, { stepLabel = function(step, i, steps) return step.kind .. i .. "/" .. #steps end })
  local rows = b.sim:PanelRows()
  assertEqual(rows[2].label, "a1/3"); assertEqual(rows[4].label, "c3/3")
end)

test("sim panel: startTip and stopTip may be functions answering a line list", function()
  local b = bench(nil, nil, { startTip = function() return { { "Fn", "start" } } end,
    stopTip = function() return { { "Fn", "stop" } } end })
  local rows = b.sim:PanelRows()
  assertTrue(tipHas(rows[1], "start")); assertTrue(tipHas(rows[#rows], "stop"))
end)

-- ── the frame, the picker and the controls ───────────────────────────────────────────────

test("sim panel: the title defaults to name .. ' - Simulation', and d.panel.title overrides it", function()
  local b = bench()
  F.recording(b.m, function()
    local f = shown(b)
    assertEqual(f.title.__text, "Host - Simulation")
  end)
  local b2 = bench(nil, nil, { title = function() return "Brand - Simulation" end })
  F.recording(b2.m, function()
    local f = shown(b2)
    assertEqual(f.title.__text, "Brand - Simulation")
  end)
end)

test("sim panel: headless, ShowPanel answers false and PanelRows still composes", function()
  local b = bench()
  b.m.CreateFrame = nil
  assertFalse(b.sim:ShowPanel())
  assertFalse(b.sim:IsPanelShown())
  assertEqual(#b.sim:PanelRows(), 5)
  b.sim:RefreshPanel(); b.sim:HidePanel(); b.sim:ResetPanelPosition()
end)

test("sim panel: Show, Hide, Toggle, IsPanelShown", function()
  local b = bench()
  F.recording(b.m, function()
    assertFalse(b.sim:IsPanelShown())
    assertTrue(b.sim:ShowPanel())
    assertTrue(b.sim:IsPanelShown())
    b.sim:TogglePanel()
    assertFalse(b.sim:IsPanelShown())
    assertTrue(b.sim:TogglePanel())
    assertTrue(b.sim:IsPanelShown())
    b.sim:HidePanel()
    assertFalse(b.sim:IsPanelShown())
  end)
end)

test("sim panel: the empty verb opens it and `panel` toggles it", function()
  local b = bench()
  F.recording(b.m, function()
    b.sim:RunVerb("")
    assertTrue(b.sim:IsPanelShown())
    b.sim:RunVerb("panel")
    assertFalse(b.sim:IsPanelShown())
  end)
end)

test("sim panel: ShowPanel answers false and does nothing while stood down", function()
  local b = bench()
  b.stoodDown = true
  F.recording(b.m, function()
    assertFalse(b.sim:ShowPanel())
    assertFalse(b.sim:IsPanelShown())
    assertNil(b.m.__named and b.m.__named.HostSimPanel, "nothing is even built")
  end)
end)

test("sim panel: a stand-down stop hides it; any other stop repaints it", function()
  local b = bench()
  F.recording(b.m, function()
    shown(b)
    b.sim:Start({ scenario = "three" })
    b.sim:Stop()
    assertTrue(b.sim:IsPanelShown(), "a plain stop leaves it up")
    b.sim:Start({ scenario = "three" })
    b.stoodDown = true
    b.sim:Fire("ANY")                               -- the self-stop backstop
    assertFalse(b.sim:IsActive())
    assertFalse(b.sim:IsPanelShown(), "hidden on a stand-down stop")
  end)
end)

test("sim panel: every listener notification repaints a shown panel", function()
  local b = bench()
  F.recording(b.m, function()
    local f = shown(b)
    b.sim:Start({ scenario = "three" })
    local bs = buttons(f)
    assertEqual(bs[2].__state, "ready")
    b.sim:RunVerb("step")                           -- typed, not clicked
    assertEqual(bs[2].__state, "done")
    assertEqual(bs[3].__state, "ready")
  end)
end)

test("sim panel: the check texture is the host's path, shown on a done row", function()
  local b = bench()
  F.recording(b.m, function()
    local f = shown(b)
    b.sim:Start({ scenario = "three" })
    local done = buttons(f)[1]
    assertEqual(done.check.__texture, HOST_CHECK)
    assertTrue(done.check:IsShown())
    assertFalse(done.dot:IsShown())
  end)
end)

test("sim panel: height bounds are re-pinned when the row count changes", function()
  local b = bench()
  F.recording(b.m, function()
    local f = shown(b)
    local function h(n) return TITLE_H + PAD * 2 + n * (ROW_H + GAP) + BAR_H + PAD end
    assertEqual(f:GetHeight(), h(5))
    f.picker.scenario.onSelect("sized")             -- two steps: four rows
    assertEqual(f:GetHeight(), h(4))
    local _, minH, _, maxH = f:GetResizeBounds()
    assertEqual(minH, h(4)); assertEqual(maxH, h(4))
  end)
end)

test("sim panel: the picker previews the chosen scenario and offers sizes only when it has them", function()
  local b = bench()
  F.recording(b.m, function()
    local f = shown(b)
    assertTrue(f.picker:IsShown()); assertFalse(f.controls:IsShown())
    assertFalse(f.picker.size:IsShown(), "'three' has no sizes")
    f.picker.scenario.onSelect("sized")
    assertTrue(f.picker.size:IsShown(), "'sized' has sizes")
    local opts = f.picker.size._options
    assertEqual(opts[1].value, 0); assertEqual(opts[1].label, b.Sim.STRINGS.RANDOM)
    assertEqual(opts[2].value, 5); assertEqual(opts[3].value, 10)
    local rows = b.sim:PanelRows()
    assertEqual(#rows, 4)
    assertEqual(rows[1].command, "/host sim start sized", "random: no size argument")
    f.picker.size.onSelect(10)
    assertEqual(b.sim:PanelRows()[1].command, "/host sim start sized 10")
    f.picker.scenario.onSelect("three")
    assertFalse(f.picker.size:IsShown())
    assertEqual(b.sim:PanelRows()[1].command, "/host sim start three", "a size is never sent to a def without sizes")
  end)
end)

test("sim panel: the picker's Start starts the chosen scenario through the typed verb", function()
  local typed, clicked = bench(), bench()
  local want = linesOf(typed, function() typed.sim:RunVerb("start sized 5") end)
  F.recording(clicked.m, function()
    local f = shown(clicked)
    f.picker.scenario.onSelect("sized")
    f.picker.size.onSelect(5)
    local got = linesOf(clicked, function() f.picker.start:__fire("OnClick") end)
    assertEqual(joined(got, "|"), joined(want, "|"))
    assertEqual(clicked.sim:Session().size, 5)
  end)
end)

test("sim panel: running, the controls replace the picker, and Pause swaps with Resume", function()
  local b = bench()
  F.recording(b.m, function()
    local f = shown(b)
    b.sim:Start({ scenario = "three" })
    assertFalse(f.picker:IsShown()); assertTrue(f.controls:IsShown())
    local c = f.controls
    assertEqual(c.run.__label, b.Sim.STRINGS.RUN_ALL)
    assertEqual(c.restart.__label, b.Sim.STRINGS.RESTART)
    assertEqual(c.stop.__label, b.Sim.STRINGS.STOP)
    assertEqual(c.pause.__label, b.Sim.STRINGS.PAUSE)
    assertFalse(c.pause:IsEnabled(), "nothing to pause yet")
    assertTrue(c.run:IsEnabled())
    c.run:__fire("OnClick")
    assertTrue(c.pause:IsEnabled()); assertFalse(c.run:IsEnabled(), "already playing")
    c.pause:__fire("OnClick")
    assertFalse(b.sim:Status().playing)
    assertEqual(c.pause.__label, b.Sim.STRINGS.RESUME, "Pause became Resume")
    c.pause:__fire("OnClick")
    assertTrue(b.sim:Status().playing, "Resume ran")
    assertEqual(c.pause.__label, b.Sim.STRINGS.PAUSE)
    c.stop:__fire("OnClick")
    assertFalse(b.sim:IsActive())
    assertTrue(f.picker:IsShown(), "idle again: the picker")
  end)
end)

test("sim panel: Restart through the controls prints what the typed verb prints", function()
  local typed, clicked = bench(), bench()
  typed.sim:Start({ scenario = "three" })
  local want = linesOf(typed, function() typed.sim:RunVerb("restart") end)
  F.recording(clicked.m, function()
    local f = shown(clicked)
    clicked.sim:Start({ scenario = "three" })
    local got = linesOf(clicked, function() f.controls.restart:__fire("OnClick") end)
    assertEqual(joined(got, "|"), joined(want, "|"))
  end)
end)

-- ── clicks ───────────────────────────────────────────────────────────────────────────────

test("sim panel: clicking Start, the ready row and Stop prints what typing them prints", function()
  local typed, clicked = bench(), bench()
  local want = {}
  for _, line in ipairs({ "start three", "step", "stop" }) do
    want[#want + 1] = joined(linesOf(typed, function() typed.sim:RunVerb(line) end), "|")
  end
  F.recording(clicked.m, function()
    local f = shown(clicked)
    local got = {}
    got[1] = joined(linesOf(clicked, function() buttons(f)[1]:__fire("OnClick") end), "|")
    got[2] = joined(linesOf(clicked, function() buttons(f)[2]:__fire("OnClick") end), "|")
    got[3] = joined(linesOf(clicked, function() buttons(f)[5]:__fire("OnClick") end), "|")
    assertEqual(joined(got, "#"), joined(want, "#"))
  end)
end)

test("sim panel: clicking an ahead row runs every step up to it, in order (the internal RunTo)", function()
  local b = bench()
  F.recording(b.m, function()
    local f = shown(b)
    b.sim:Start({ scenario = "three" })
    local out = linesOf(b, function() buttons(f)[4]:__fire("OnClick") end)
    assertEqual(joined(b.played), "a,b,c")
    assertEqual(out[1], b.Sim.STRINGS.STEP_LINE:format(1, 3, "Alpha"))
    assertEqual(out[3], b.Sim.STRINGS.STEP_LINE:format(3, 3, "Gamma"))
    assertEqual(out[4], b.Sim.STRINGS.FINISHED:format("/host sim"))
    assertNil(b.sim.RunTo, "RunTo stays Sim-internal")
    assertEqual(states(b.sim:PanelRows()), "done,done,done,done,cancel")
  end)
end)

test("sim panel: an ahead click while a run is playing prints the PLAYING line and plays nothing", function()
  local b = bench()
  F.recording(b.m, function()
    local f = shown(b)
    b.sim:Start({ scenario = "three" })
    b.sim:Run()
    local out = linesOf(b, function() buttons(f)[4]:__fire("OnClick") end)
    assertEqual(joined(b.played), "a")
    assertEqual(out[1], b.Sim.STRINGS.PLAYING)
  end)
end)

test("sim panel: a stale click re-composes from the live model and refuses", function()
  local b = bench()
  F.recording(b.m, function()
    local f = shown(b)
    local start = buttons(f)[1]
    b.sim:Start({ scenario = "three" })               -- Start is no longer actionable
    local out = linesOf(b, function() start:__fire("OnClick") end)
    assertEqual(#out, 0, "no second start, not even its refusal line")
    -- a row painted actionable whose state moved while the panel was hidden (no repaint)
    local ready = buttons(f)[2]
    assertTrue(ready:IsEnabled(), "painted actionable")
    b.sim:HidePanel()
    b.sim:Stop()
    assertTrue(ready:IsEnabled(), "still painted actionable: a hidden panel is not repainted")
    out = linesOf(b, function() ready:__fire("OnClick") end)
    assertEqual(#out, 0, "the stopped session's step row never acts")
    assertEqual(#b.played, 0)
  end)
end)

-- ── placement ────────────────────────────────────────────────────────────────────────────

--- An anchor frame at `left`..`right` on a UIParent `screen` wide.
local function anchorAt(b, left, right, screen)
  local a = b.m.CreateFrame("Frame")
  rawset(a, "GetLeft", function() return left end)
  rawset(a, "GetRight", function() return right end)
  b.m.UIParent:__setGeom(screen, 1080)
  b.anchor = a
  return a
end

test("sim panel: with no anchor and no dragged point it floats at CENTER +420", function()
  local b = bench()
  F.recording(b.m, function()
    local f = shown(b)
    local pt = f.__pts[1]
    assertEqual(pt.point, "CENTER"); assertEqual(pt.relPoint, "CENTER"); assertEqual(pt.x, 420)
    assertEqual(f.__dock, "float")
  end)
end)

test("sim panel: it docks right of anchorTo() with DOCK_GAP 8", function()
  local b = bench()
  F.recording(b.m, function()
    local a = anchorAt(b, 100, 700, 1920)
    local f = shown(b)
    local pt = f.__pts[1]
    assertEqual(pt.point, "TOPLEFT"); assertTrue(pt.rel == a); assertEqual(pt.relPoint, "TOPRIGHT")
    assertEqual(pt.x, 8); assertEqual(pt.y, 0)
    assertEqual(f.__dock, "right")
  end)
end)

test("sim panel: it docks left when there is no room on the right", function()
  local b = bench()
  F.recording(b.m, function()
    local a = anchorAt(b, 1000, 1800, 1920)
    local f = shown(b)
    local pt = f.__pts[1]
    assertEqual(pt.point, "TOPRIGHT"); assertTrue(pt.rel == a); assertEqual(pt.relPoint, "TOPLEFT")
    assertEqual(pt.x, -8)
    assertEqual(f.__dock, "left")
  end)
end)

test("sim panel: it floats when neither side has room", function()
  local b = bench()
  F.recording(b.m, function()
    anchorAt(b, 200, 1700, 1920)
    local f = shown(b)
    assertEqual(f.__dock, "float")
    assertEqual(f.__pts[1].x, 420)
  end)
end)

test("sim panel: a point dragged this session beats the dock, in memory only", function()
  local b = bench()
  _G.HostSimDB = { profile = { untouched = true } }   -- a SavedVariables-shaped global
  F.recording(b.m, function()
    anchorAt(b, 100, 700, 1920)
    local f = shown(b)
    local before = {}
    for k in pairs(_G) do before[k] = true end
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", b.m.UIParent, "BOTTOMLEFT", 55, 66)
    f:__fire("OnDragStop")
    b.sim:HidePanel()
    b.sim:ShowPanel()
    local pt = f.__pts[1]
    assertEqual(pt.point, "TOPLEFT"); assertEqual(pt.relPoint, "BOTTOMLEFT")
    assertEqual(pt.x, 55); assertEqual(pt.y, 66)
    assertEqual(f.__dock, "dragged")
    for k in pairs(_G) do assertTrue(before[k], "no global written: " .. tostring(k)) end
    assertEqual(joined((function() local o = {} for k in pairs(_G.HostSimDB.profile) do o[#o + 1] = k end return o end)()),
      "untouched", "the SavedVariables-shaped table is untouched")
  end)
  _G.HostSimDB = nil
end)

test("sim panel: ResetPanelPosition forgets the point and redocks", function()
  local b = bench()
  F.recording(b.m, function()
    anchorAt(b, 100, 700, 1920)
    local f = shown(b)
    f:ClearAllPoints()
    f:SetPoint("CENTER", b.m.UIParent, "CENTER", 1, 2)
    f:__fire("OnDragStop")
    b.sim:ResetPanelPosition()
    assertEqual(f.__dock, "right", "redocked at once while shown")
    b.sim:HidePanel(); b.sim:ShowPanel()
    assertEqual(f.__dock, "right", "and on the next Show")
  end)
end)

test("sim panel: with no dragged point it redocks on every Show", function()
  local b = bench()
  F.recording(b.m, function()
    local f = shown(b)
    assertEqual(f.__dock, "float")
    b.sim:HidePanel()
    anchorAt(b, 100, 700, 1920)
    b.sim:ShowPanel()
    assertEqual(f.__dock, "right")
  end)
end)

test("sim panel: the panel never names SavedVariables or a store", function()
  local fh = assert(io.open("LibKa0s/SimPanel.lua", "rb"))
  local src = fh:read("*a")
  fh:close()
  for line in src:gmatch("[^\n]+") do
    if not line:match("^%s*%-%-") then
      assertFalse(line:find("SavedVariables", 1, true) ~= nil, "code line names SavedVariables: " .. line)
      assertFalse(line:find("store()", 1, true) ~= nil, "code line calls store(): " .. line)
    end
  end
end)

-- ── the tooltip ──────────────────────────────────────────────────────────────────────────

test("sim panel: a row's tip goes to GameTooltip as double lines under the row's label", function()
  local b = bench()
  F.recording(b.m, function()
    local f = shown(b)
    local tip = b.m.GameTooltip
    local got = {}
    rawset(tip, "SetText", function(_, t) got[#got + 1] = "T:" .. tostring(t) end)
    rawset(tip, "AddDoubleLine", function(_, l, r) got[#got + 1] = "D:" .. tostring(l) .. "=" .. tostring(r) end)
    rawset(tip, "AddLine", function(_, l) got[#got + 1] = "L:" .. tostring(l) end)
    buttons(f)[2]:__fire("OnEnter")
    assertEqual(joined(got, "|"), "T:Alpha|D:Injects=a")
    assertTrue(tip:IsShown())
    buttons(f)[2]:__fire("OnLeave")
    assertFalse(tip:IsShown())
  end)
end)

-- ── the shared dropdown menu (W.CloseMenu) ───────────────────────────────────────────────
--
-- The picker's dropdowns share Widgets' process-wide popup menu, which no owner's Hide reaches
-- (Widgets.lua's CloseMenu contract): every non-click way the picker leaves the screen must close
-- it, or it floats on at FULLSCREEN_DIALOG with no owner. The kit's Hide() fires no OnHide, so the
-- Escape case fires it itself, the way the client does when CloseSpecialWindows hides the frame.

--- Count W.CloseMenu calls on bench `b`; answers a reader of the count.
local function spyCloseMenu(b)
  local W = b.m.LibStub("LibKa0s-Widgets-1.0")
  local n, orig = 0, W.CloseMenu
  W.CloseMenu = function(...) n = n + 1; return orig(...) end
  return function() return n end
end

test("sim panel: HidePanel closes the shared dropdown menu", function()
  local b = bench()
  F.recording(b.m, function()
    shown(b)
    local closes = spyCloseMenu(b)
    b.sim:HidePanel()
    assertTrue(closes() >= 1, "HidePanel closed the menu")
  end)
end)

test("sim panel: Escape (the frame's OnHide, not HidePanel) closes the shared dropdown menu", function()
  local b = bench()
  F.recording(b.m, function()
    local f = shown(b)
    local closes = spyCloseMenu(b)
    f:Hide()
    f:__fire("OnHide")                              -- what CloseSpecialWindows' Hide fires in the client
    assertTrue(closes() >= 1, "Escape closed the menu")
  end)
end)

test("sim panel: a typed start that swaps the picker out closes the shared dropdown menu", function()
  local b = bench()
  F.recording(b.m, function()
    local f = shown(b)
    assertTrue(f.picker:IsShown())
    local closes = spyCloseMenu(b)
    b.sim:RunVerb("start three")                    -- typed, not clicked: no mouse press reaches the menu
    assertFalse(f.picker:IsShown())
    assertEqual(closes(), 1, "the swap closed the menu once")
    b.sim:RefreshPanel()
    assertEqual(closes(), 1, "a repaint with the picker already hidden closes nothing")
  end)
end)

-- ── a descriptor filled in place after New (SimPanel minor 2) ───────────────────────────────
--
-- Sim minor 2 made `Start` read `d.scenarios` live, so a host may fill its scenarios after `New`
-- (DropWatcher builds them when its world module loads). SimPanel minor 1 still read the first
-- scenario name once, inside `New`, so such a host's panel offered `Start: nil` for good. These
-- cases pin the live read, and the last one pins every other documented field read at use.

--- Fill `sc` (the descriptor's own scenarios table) in place with the bench's two scenarios.
local function fillScenarios(sc)
  sc.names[#sc.names + 1] = "three"
  sc.names[#sc.names + 1] = "sized"
  sc.defs.three = { label = "Three", timeline = function()
    return { { kind = "a", label = "Alpha" }, { kind = "b", label = "Beta" }, { kind = "c", label = "Gamma" } }
  end }
  sc.defs.sized = { label = "Sized", sizes = { 5, 10 }, timeline = function()
    return { { kind = "s1" }, { kind = "s2" } }
  end }
end

local function lateBench() return bench({ scenarios = { names = {}, defs = {} } }) end

test("sim panel: scenarios filled after New: the idle rows read the first one live (minor 2)", function()
  local b = lateBench()
  fillScenarios(b.d.scenarios)
  local rows = b.sim:PanelRows()
  assertEqual(rows[1].label, b.Sim.STRINGS.PANEL_START:format("Three"))
  assertEqual(rows[1].command, "/host sim start three")
  assertEqual(#rows, 5, "Start, the three previewed steps, Stop")
  assertEqual(rows[2].label, "Alpha"); assertEqual(rows[4].label, "Gamma")
  assertEqual(states(rows), "ready,locked,locked,locked,locked")
  assertEqual(actionable(rows), "ynnnn")
end)

test("sim panel: scenarios filled after New: the picker's Start starts the first one (minor 2)", function()
  local b = lateBench()
  F.recording(b.m, function()
    local f = shown(b)                              -- shown while nothing is listed yet
    fillScenarios(b.d.scenarios)
    b.sim:RefreshPanel()
    assertEqual(f.picker.scenario._value, "three", "the picker selects the first scenario")
    f.picker.start:__fire("OnClick")
    assertTrue(b.sim:IsActive(), "the picker's Start started a session")
    assertEqual(b.sim:Session().scenario, "three")
  end)
end)

test("sim panel: scenarios filled after New: clicking the Start row starts the first one (minor 2)", function()
  local b = lateBench()
  F.recording(b.m, function()
    local f = shown(b)
    fillScenarios(b.d.scenarios)
    b.sim:RefreshPanel()
    buttons(f)[1]:__fire("OnClick")
    assertTrue(b.sim:IsActive(), "the Start row started a session")
    assertEqual(b.sim:Session().scenario, "three")
  end)
end)

test("sim panel: nothing listed yet: the Start row and the picker's Start are inert", function()
  local b = lateBench()
  local rows = b.sim:PanelRows()
  assertEqual(#rows, 2, "Start and Stop, no preview")
  assertEqual(rows[1].state, "locked")
  assertFalse(rows[1].actionable, "no scenario to start")
  assertEqual(rows[1].command, "/host sim start")
  assertEqual(rows[1].label, b.Sim.STRINGS.PANEL_START:format(""))
  F.recording(b.m, function()
    local f = shown(b)
    assertFalse(f.picker.start:IsEnabled(), "the picker's Start is disabled")
    local before = #b.printed
    f.picker.start:__fire("OnClick")
    assertEqual(#b.printed, before, "a disabled Start prints nothing")
    assertFalse(b.sim:IsActive())
  end)
end)

test("sim panel: a picked scenario the host drops falls back to the first listed one", function()
  local b = bench()
  F.recording(b.m, function()
    local f = shown(b)
    f.picker.scenario.onSelect("sized")
    assertEqual(b.sim:PanelRows()[1].command, "/host sim start sized")
    local sc = b.d.scenarios
    sc.defs.sized = nil
    table.remove(sc.names, 2)
    assertEqual(b.sim:PanelRows()[1].command, "/host sim start three")
    f.picker.start:__fire("OnClick")
    assertEqual(b.sim:Session().scenario, "three", "the picker's Start follows the fallback")
  end)
end)

test("sim panel: every documented optional field filled in place after New is read at use", function()
  local debugged = {}
  local b = bench({ panel = {}, verbs = {}, usage = {}, why = {} })
  local d = b.d
  -- Filled in place, or assigned for the first time, after New: nothing here was there at New.
  d.verbs.ping = { free = true, parse = function(words) return words end, run = function() return false, "nope" end }
  d.why.nope = "Nope line."
  d.usage[1] = "/host sim ping: pings."
  d.statusLine = function() return "Extra status." end
  d.L = { STARTED = "Go (%s)." }
  d.stopText = { stop = "Ended." }
  d.refusal = function(opts) if opts.scenario == "sized" then return "No sized." end end
  d.gate = function(session) return session.events > 0, "Gate shut." end
  d.stepDelay = function() return 0 end
  d.debug = function(_, fmt, ...) debugged[#debugged + 1] = fmt:format(...) end
  d.panel.title = "Late title"
  d.panel.stepLabel = function(step) return "L-" .. step.kind end
  d.panel.startTip = { { "Late", "start tip" } }
  d.panel.stopTip = function() return { { "Late", "stop tip" } } end
  d.panel.stepTip = function(step) return { { "Late", step.kind } } end
  d.panel.check = HOST_CHECK
  local printed = {}
  d.print = function(line) printed[#printed + 1] = line end

  assertEqual(joined(linesOf({ printed = printed }, function() b.sim:RunVerb("ping") end), "|"), "Nope line.")
  local usage = linesOf({ printed = printed }, function() b.sim:RunVerb("nonsense") end)
  assertEqual(usage[#usage], "/host sim ping: pings.", "the late usage line")
  local status = linesOf({ printed = printed }, function() b.sim:RunVerb("status") end)
  assertEqual(status[2], "Extra status.")
  assertEqual(joined(linesOf({ printed = printed }, function() b.sim:Start({ scenario = "sized" }) end)),
    "No sized.", "the late refusal")
  local rows = b.sim:PanelRows()
  assertEqual(rows[2].label, "L-a", "the late stepLabel")
  assertTrue(tipHas(rows[1], "start tip")); assertTrue(tipHas(rows[2], "Late a")); assertTrue(tipHas(rows[5], "stop tip"))
  F.recording(b.m, function()
    local f = shown(b)
    assertEqual(f.title:GetText(), "Late title")
    assertEqual(buttons(f)[1].check.__texture, HOST_CHECK, "check set before the first Show")
    assertEqual(joined(linesOf({ printed = printed }, function() b.sim:Start({ scenario = "three" }) end)),
      "Go (Three).", "the late L")
    assertEqual(joined(linesOf({ printed = printed }, function() b.sim:Step() end)), "Gate shut.", "the late gate")
    assertEqual(joined(linesOf({ printed = printed }, function() b.sim:Stop() end)), "Ended.", "the late stopText")
  end)
  assertTrue(#debugged > 0, "the late debug sink")
  assertEqual(#b.printed, 0, "nothing reached the print sink New saw")
end)

test("sim panel: anchorTo, stepDelay and the required callbacks and slash, reassigned after New, are read at use", function()
  local b = bench({ panel = {} })                  -- no anchorTo at New
  local d = b.d
  local late = { prepared = 0, played = {}, delivered = {}, stoodDown = false }
  d.slash = "/late sim"
  d.prepare = function(_, _, _, ready) late.prepared = late.prepared + 1; ready() end
  d.play = function(step) late.played[#late.played + 1] = step.kind; return "late " .. step.kind end
  d.deliver = function(event) late.delivered[#late.delivered + 1] = event; return 7 end
  d.isStoodDown = function() return late.stoodDown end
  d.stepDelay = 0.75
  assertEqual(b.sim:PanelRows()[1].command, "/late sim start three", "the late slash")
  F.recording(b.m, function()
    local a = anchorAt(b, 100, 700, 1920)
    d.panel.anchorTo = function() return a end   -- assigned for the first time after New
    local f = shown(b)
    local pt = f.__pts[1]
    assertTrue(pt.rel == a, "docked to the late anchorTo"); assertEqual(f.__dock, "right")
    b.sim:Start({ scenario = "three" })
    assertEqual(late.prepared, 1, "the late prepare")
    assertTrue(b.sim:Run())
    assertEqual(joined(late.played), "a", "the late play")
    local delays = {}
    for _, t in ipairs(b.m.__timers()) do delays[#delays + 1] = t.delay end
    assertEqual(joined(delays), "0.75", "Run's tick reads the late stepDelay")
    assertEqual(b.sim:Fire("LATE_EVENT"), 7, "the late deliver")
    assertEqual(joined(late.delivered), "LATE_EVENT")
    late.stoodDown = true
    assertEqual(b.sim:Fire("AFTER"), 0, "the late isStoodDown stops the session")
    assertNil(b.sim:Session())
    assertFalse(b.sim:ShowPanel(), "the panel refuses while the late isStoodDown answers true")
  end)
  assertEqual(#b.played + #b.readies, 0, "nothing reached the callbacks New saw")
end)
