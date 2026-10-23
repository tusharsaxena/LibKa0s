-- tests/test_sim_panel_render.lua — LibKa0s-Sim-1.0's private step-panel renderer, the file-local
-- section of `LibKa0s/SimPanel.lua`, reached through the internal test seam `lib.__StepPanel`.
--
-- LK-11's outcome B (LibKa0s#53): the step panel is NOT public. The renderer LK-10 wrote as
-- `W.StepPanel` lives inside SimPanel.lua with no public contract, so these are LK-10's cases,
-- ported unchanged in what they assert and driven through `lib.__StepPanel` instead of a Widgets
-- member. The seam is `__`-prefixed and documented as internal (library-stack-§7's `__` clause): no
-- host reads it, and the members manifest leaves it out.
--
-- The widget draws rows a host composes and dispatches clicks a host decides on; it owns no state
-- semantics. So this suite drives it with a plain `rows()` over a table the case mutates, and asks
-- what was drawn. The frame recorder is tests/fixture_sim_panel.lua's.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local F = dofile("tests/fixture_sim_panel.lua")

-- One environment for the whole file, as LK-10's suite had one (the shared harness).
local mocks, Sim = F.env()
local SP   = Sim.__StepPanel
local core = mocks.LibStub("LibKa0s-Core-1.0")
local recording = F.recording

local HOST_CHECK = F.HOST_CHECK

-- Perf's geometry and palette (LibKa0s/PerfPanel.lua), restated here on purpose: the renderer copies
-- them, and a drift between the two copies is what these numbers catch.
local ROW_W, ROW_H, GAP, DOT_X, DOT, LABEL_X, CMD_PAD, TITLE_H, PAD = 360, 22, 4, 8, 8, 26, 10, 24, 8
local COLORS = {
  done   = { 0.30, 0.85, 0.30 },
  used   = { 0.30, 0.85, 0.30 },
  ready  = { 0.90, 0.90, 0.92 },
  busy   = { 1.00, 0.82, 0.00 },
  locked = { 0.40, 0.40, 0.42 },
  cancel = { 0.80, 0.32, 0.32 },
}
local CMD_COLOR = { 0.45, 0.45, 0.48 }

local seq = 0
--- A panel over `list` (mutable by the case), with the descriptor's other fields overridable.
local function newPanel(list, over)
  seq = seq + 1
  local clicks = {}
  local d = {
    name = "LKSimStepPanelTest" .. seq,
    addonName = "TestHost",
    title = "Steps",
    rows = function() return list end,
    onClick = function(row, index) clicks[#clicks + 1] = { row = row, index = index } end,
  }
  for k, v in pairs(over or {}) do d[k] = v end
  return SP(d), clicks, d
end

local function row(label, state, actionable, extra)
  local r = { label = label, command = "/th " .. label:lower(), state = state, actionable = actionable }
  for k, v in pairs(extra or {}) do r[k] = v end
  return r
end

local function heightFor(n, footerH)
  local h = TITLE_H + PAD * 2 + n * (ROW_H + GAP)
  if footerH then h = h + footerH + PAD end
  return h
end

local sameColor = F.sameColor

-- ── the surface ──────────────────────────────────────────────────────────────────────────────

test("sim panel render: the renderer is the internal seam lib.__StepPanel, not a Widgets member", function()
  assertEqual(type(SP), "function")
  local W = mocks.LibStub("LibKa0s-Widgets-1.0")
  assertNil(rawget(W, "StepPanel"), "no public W.StepPanel (LK-11 outcome B)")
  assertNil(W.MODULES.WidgetsStepPanel, "and no WidgetsStepPanel file")
end)

test("sim panel render: the descriptor's required fields raise when missing", function()
  for _, field in ipairs({ "name", "addonName", "rows", "onClick" }) do
    local d = { name = "LKSimStepPanelReq", addonName = "TestHost", rows = function() return {} end,
      onClick = function() end }
    d[field] = nil
    local ok, err = pcall(SP, d)
    assertFalse(ok, field .. " is required")
    assertTrue(tostring(err):find(field, 1, true) ~= nil, "the error names " .. field)
  end
  assertFalse((pcall(SP, nil)), "no descriptor at all raises")
end)

test("sim panel render: the handle answers the seven members, and no frame until asked", function()
  local p = newPanel({})
  for _, k in ipairs({ "Frame", "Show", "Hide", "Toggle", "IsShown", "Refresh", "Buttons" }) do
    assertEqual(type(p[k]), "function", k)
  end
  assertFalse(p.IsShown(), "nothing is shown before the first Show")
  assertEqual(#p.Buttons(), 0, "and there are no buttons")
end)

test("sim panel render: headless, Frame() answers nil and nothing raises", function()
  local saved = mocks.CreateFrame
  mocks.CreateFrame = nil
  local ok, err = pcall(function()
    local p = newPanel({ row("Start", "ready", true) })
    assertNil(p.Frame(), "no CreateFrame, no frame")
    p.Show(); p.Refresh(); p.Toggle(); p.Hide()
    assertFalse(p.IsShown(), "and it never reads as shown")
    assertEqual(#p.Buttons(), 0, "nor has buttons")
  end)
  mocks.CreateFrame = saved
  if not ok then error(err, 0) end
end)

-- ── chrome ───────────────────────────────────────────────────────────────────────────────────

test("sim panel render: the frame's chrome is Perf's", function()
  recording(mocks, function()
    local p, _, d = newPanel({ row("Start", "ready", true), row("Stop", "locked", false) })
    local f = p.Frame()
    assertEqual(f.__frameType, "Frame")
    assertEqual(f.__name, d.name, "the frame global is the descriptor's name")
    assertEqual(f.__template, "BackdropTemplate")
    assertTrue(f.__parent == mocks.UIParent, "parented to UIParent")
    assertEqual(f:GetWidth(), ROW_W + PAD * 2)
    assertEqual(f:GetHeight(), heightFor(2))
    assertEqual(f.__pts[1].point, "CENTER"); assertEqual(f.__pts[1].x, -320)
    assertFalse(f:IsShown(), "built hidden")
    local found = false
    for _, n in ipairs(mocks.UISpecialFrames) do if n == d.name then found = true end end
    assertTrue(found, "Escape closes it (UISpecialFrames)")
    assertEqual(f.title.__text, "Steps")
    assertEqual(f.title.__pts[1].point, "TOP"); assertEqual(f.title.__pts[1].y, -6)
    assertTrue(f.closeButton ~= nil, "the close mark is drawn by default")
    local cp = f.closeButton.__pts[1]
    assertEqual(cp.point, "TOPRIGHT"); assertEqual(cp.x, -6); assertEqual(cp.y, -3)
    assertTrue(f.resizeGrip ~= nil, "resizable through Core.MakeResizable")
    assertTrue(p.Frame() == f, "built once")
  end)
end)

test("sim panel render: the close mark gets the descriptor's addonName", function()
  local real, seen = core.MakeCloseButton, nil
  core.MakeCloseButton = function(parent, onClick, addonName)
    seen = addonName
    return real(parent, onClick, addonName)
  end
  local ok, err = pcall(function()
    local p = newPanel({}, { addonName = "OtherFolder" })
    p.Frame()
  end)
  core.MakeCloseButton = real
  if not ok then error(err, 0) end
  assertEqual(seen, "OtherFolder", "the third MakeCloseButton argument")
end)

test("sim panel render: close=false draws no close mark", function()
  local real, made = core.MakeCloseButton, 0
  core.MakeCloseButton = function(...) made = made + 1; return real(...) end
  local f
  local ok, err = pcall(function()
    local p = newPanel({}, { close = false })
    f = p.Frame()
  end)
  core.MakeCloseButton = real
  if not ok then error(err, 0) end
  assertEqual(made, 0, "the corner is the caller's")
  assertNil(f.closeButton)
end)

test("sim panel render: Show, Hide, Toggle and IsShown", function()
  recording(mocks, function()
    local p = newPanel({ row("Start", "ready", true) })
    p.Show()
    assertTrue(p.IsShown())
    p.Toggle()
    assertFalse(p.IsShown())
    p.Toggle()
    assertTrue(p.IsShown())
    p.Frame().closeButton:__fire("OnClick")
    assertFalse(p.IsShown(), "the close mark hides it")
  end)
end)

-- ── rows: geometry, palette, the test record ─────────────────────────────────────────────────

test("sim panel render: row geometry and the test record", function()
  recording(mocks, function()
    local list = { row("Start", "done", false), row("Measure", "ready", true) }
    local p = newPanel(list)
    p.Show()
    local f, b = p.Frame(), p.Buttons()
    assertEqual(#b, 2)
    for i, btn in ipairs(b) do
      assertEqual(btn.__frameType, "Button")
      assertEqual(btn:GetWidth(), ROW_W); assertEqual(btn:GetHeight(), ROW_H)
      local pt = btn.__pts[1]
      assertEqual(pt.point, "TOPLEFT"); assertTrue(pt.rel == f, "anchored to the panel")
      assertEqual(pt.x, PAD); assertEqual(pt.y, -(TITLE_H + PAD + (i - 1) * (ROW_H + GAP)))
      assertEqual(btn.dot.__w, DOT); assertEqual(btn.dot.__h, DOT)
      assertEqual(btn.dot.__pts[1].point, "LEFT"); assertEqual(btn.dot.__pts[1].x, DOT_X)
      assertEqual(btn.text.__pts[1].point, "LEFT"); assertEqual(btn.text.__pts[1].x, LABEL_X)
      assertEqual(btn.cmd.__pts[1].point, "RIGHT"); assertEqual(btn.cmd.__pts[1].x, -CMD_PAD)
      sameColor(T, btn.cmd.__textColor, CMD_COLOR, "command column")
      assertEqual(btn.__index, i)
      assertEqual(btn.__label, list[i].label)
      assertEqual(btn.__state, list[i].state)
      assertEqual(btn.__command, list[i].command)
      assertEqual(btn.text.__text, list[i].label)
      assertEqual(btn.cmd.__text, list[i].command)
    end
  end)
end)

test("sim panel render: every state paints Perf's palette on the label and the dot", function()
  recording(mocks, function()
    local list = {}
    for _, s in ipairs({ "done", "used", "ready", "busy", "locked", "cancel" }) do
      list[#list + 1] = row(s, s, false)
    end
    local p = newPanel(list)
    p.Show()
    for _, b in ipairs(p.Buttons()) do
      local want = COLORS[b.__state]
      sameColor(T, b.text.__textColor, want, b.__state .. " label")
      sameColor(T, b.dot.__colorTexture, want, b.__state .. " dot")
      assertEqual(b.dot.__colorTexture[4], b.__state == "locked" and 0.35 or 1, b.__state .. " dot alpha")
    end
  end)
end)

test("sim panel render: an unknown state paints as locked", function()
  recording(mocks, function()
    local p = newPanel({ row("x", "mystery", false) })
    p.Show()
    sameColor(T, p.Buttons()[1].text.__textColor, COLORS.locked, "fallback")
  end)
end)

test("sim panel render: actionable is explicit row data and nil means false", function()
  recording(mocks, function()
    local p = newPanel({ row("a", "ready", true), row("b", "ready", nil), row("c", "ready", false) })
    p.Show()
    local b = p.Buttons()
    assertTrue(b[1]:IsEnabled(), "actionable true")
    assertFalse(b[2]:IsEnabled(), "actionable nil")
    assertFalse(b[3]:IsEnabled(), "actionable false")
  end)
end)

test("sim panel render: command text is repainted on every Refresh", function()
  recording(mocks, function()
    local list = { row("Start", "ready", true) }
    local p = newPanel(list)
    p.Show()
    list[1] = row("Start", "ready", true, { command = "/th start Raid 20" })
    p.Refresh()
    local b = p.Buttons()[1]
    assertEqual(b.__command, "/th start Raid 20")
    assertEqual(b.cmd.__text, "/th start Raid 20")
  end)
end)

-- ── hover ────────────────────────────────────────────────────────────────────────────────────

test("sim panel render: an actionable row hovers gold and leaves to its palette color", function()
  recording(mocks, function()
    local p = newPanel({ row("Next", "ready", true), row("Again", "used", true) })
    p.Show()
    for _, b in ipairs(p.Buttons()) do
      b:__fire("OnEnter")
      sameColor(T, b.text.__textColor, { 1, 0.82, 0 }, b.__state .. " hover")
      b:__fire("OnLeave")
      sameColor(T, b.text.__textColor, COLORS[b.__state], b.__state .. " leave")
    end
  end)
end)

test("sim panel render: an actionable cancel row hovers red", function()
  recording(mocks, function()
    local p = newPanel({ row("Stop", "cancel", true) })
    p.Show()
    local b = p.Buttons()[1]
    b:__fire("OnEnter")
    sameColor(T, b.text.__textColor, { 1, 0.45, 0.45 }, "cancel hover")
    b:__fire("OnLeave")
    sameColor(T, b.text.__textColor, COLORS.cancel, "cancel leave")
  end)
end)

test("sim panel render: a non-actionable row does not hover", function()
  recording(mocks, function()
    local p = newPanel({ row("Ahead", "locked", false), row("Now", "busy", false), row("Stop", "cancel", false) })
    p.Show()
    for _, b in ipairs(p.Buttons()) do
      b:__fire("OnEnter")
      sameColor(T, b.text.__textColor, COLORS[b.__state], b.__state .. " stays")
    end
  end)
end)

test("sim panel render: the tooltip is called on enter only for a row with a tip", function()
  recording(mocks, function()
    local calls = {}
    local list = { row("Tip", "ready", true, { tip = { "line" } }), row("NoTip", "ready", true),
      row("Done", "done", false, { tip = { "ran" } }) }
    local p = newPanel(list, { tooltip = function(owner, r) calls[#calls + 1] = { owner = owner, row = r } end })
    p.Show()
    local b = p.Buttons()
    b[1]:__fire("OnEnter")
    b[2]:__fire("OnEnter")
    assertEqual(#calls, 1, "the second row has no tip")
    assertTrue(calls[1].owner == b[1], "owned by the row button")
    assertTrue(calls[1].row == list[1], "and handed the row")
    F.hover(b[3])   -- the client's rule: a disabled row's OnEnter runs only with motion scripts on
    assertEqual(#calls, 2, "a row that is not actionable still shows its tip")
    sameColor(T, b[3].text.__textColor, COLORS.done, "but does not hover")
  end)
end)

test("sim panel render: a row with a tip and no tooltip fn shows nothing", function()
  recording(mocks, function()
    local p = newPanel({ row("Tip", "locked", false, { tip = { "x" } }) })
    p.Show()
    local b = p.Buttons()[1]
    local before = mocks.GameTooltip:IsShown()
    b:__fire("OnEnter")
    assertEqual(mocks.GameTooltip:IsShown(), before, "no default tooltip")
    b:__fire("OnLeave")
    assertEqual(mocks.GameTooltip:IsShown(), before, "and nothing to hide")
  end)
end)

-- ── clicks ───────────────────────────────────────────────────────────────────────────────────

test("sim panel render: a click re-reads rows() and hands onClick the fresh row and its index", function()
  recording(mocks, function()
    local list = { row("Start", "done", false), row("Next", "ready", true) }
    local p, clicks = newPanel(list)
    p.Show()
    local fresh = row("Next", "ready", true, { key = "next" })
    list[2] = fresh
    p.Buttons()[2]:__fire("OnClick")
    assertEqual(#clicks, 1)
    assertTrue(clicks[1].row == fresh, "the row as rows() answers it now")
    assertEqual(clicks[1].index, 2)
  end)
end)

test("sim panel render: a row that stopped being actionable after paint is not dispatched", function()
  recording(mocks, function()
    local list = { row("Next", "ready", true) }
    local p, clicks = newPanel(list)
    p.Show()
    assertTrue(p.Buttons()[1]:IsEnabled(), "painted actionable")
    list[1] = row("Next", "busy", false)
    p.Buttons()[1]:__fire("OnClick")
    assertEqual(#clicks, 0, "the stale click does nothing")
    assertEqual(p.Buttons()[1].__state, "busy", "and the row is repainted from the fresh list")
  end)
end)

test("sim panel render: a click on a row index the list no longer has is not dispatched", function()
  recording(mocks, function()
    local list = { row("A", "ready", true), row("B", "ready", true) }
    local p, clicks = newPanel(list)
    p.Show()
    local second = p.Buttons()[2]
    list[2] = nil
    second:__fire("OnClick")
    assertEqual(#clicks, 0)
    assertFalse(second:IsShown(), "the vanished row is hidden by the repaint")
  end)
end)

test("sim panel render: a dispatched click repaints", function()
  recording(mocks, function()
    local list = { row("Next", "ready", true) }
    local p = newPanel(list, {
      onClick = function() list[1] = row("Next", "done", false) end,
    })
    p.Show()
    p.Buttons()[1]:__fire("OnClick")
    assertEqual(p.Buttons()[1].__state, "done")
  end)
end)

-- ── height, rows on demand, bounds ───────────────────────────────────────────────────────────

test("sim panel render: height follows the row count, and a shrink hides the extra rows", function()
  recording(mocks, function()
    local list = { row("a", "ready", true), row("b", "locked", false), row("c", "locked", false) }
    local p = newPanel(list)
    p.Show()
    local f = p.Frame()
    assertEqual(f:GetHeight(), heightFor(3))
    local built = p.Buttons()
    list[3] = nil
    p.Refresh()
    assertEqual(f:GetHeight(), heightFor(2), "recomputed on Refresh")
    assertEqual(#p.Buttons(), 2, "Buttons() answers the current rows")
    assertTrue(built[1]:IsShown() and built[2]:IsShown(), "kept rows shown")
    assertFalse(built[3]:IsShown(), "the dropped row is hidden")
    list[3] = row("c2", "ready", true)
    list[4] = row("d", "locked", false)
    p.Refresh()
    assertEqual(f:GetHeight(), heightFor(4))
    assertTrue(p.Buttons()[3] == built[3], "a hidden row is reused")
    assertTrue(built[3]:IsShown(), "and shown again")
    assertEqual(built[3].__label, "c2")
  end)
end)

test("sim panel render: a footer adds its height plus PAD, is built once and painted every Refresh", function()
  recording(mocks, function()
    local builds, paints, api = 0, 0, nil
    local list = { row("a", "ready", true) }
    local p = newPanel(list, { footer = {
      height = 24,
      build = function(frame, a) builds = builds + 1; api = a; frame.__footerBuilt = true end,
      paint = function(frame) paints = paints + 1; assertTrue(frame.__footerBuilt, "built first") end,
    } })
    p.Show()
    local f = p.Frame()
    assertEqual(f:GetHeight(), heightFor(1, 24))
    p.Refresh(); p.Refresh()
    assertEqual(builds, 1, "built once")
    assertEqual(paints, 3, "painted on every Refresh")
    assertEqual(type(api.Hide), "function", "the build gets the panel's handle")
    assertEqual(api.PAD, PAD)
    list[2] = row("b", "locked", false)
    p.Refresh()
    assertEqual(f:GetHeight(), heightFor(2, 24))
  end)
end)

test("sim panel render: the title is re-read on every Refresh", function()
  recording(mocks, function()
    local n = 0
    local p = newPanel({}, { title = function() n = n + 1; return "Title " .. n end })
    p.Show()
    local f = p.Frame()
    local seen = f.title.__text
    p.Refresh()
    assertTrue(f.title.__text ~= seen, "re-read")
    assertEqual(f.title.__text, "Title " .. n)
  end)
end)

test("sim panel render: red under: bounds fixed at MakeResizable time are re-pinned when the count moves", function()
  -- Core.MakeResizable is call-once and fixes the widthOnly height bounds at the height the frame
  -- had then. A row count that grows or shrinks afterwards would leave the grip clamping to the
  -- old height; the panel re-pins the bounds itself.
  recording(mocks, function()
    local list = { row("a", "ready", true), row("b", "locked", false) }
    local p = newPanel(list)
    p.Show()
    local f = p.Frame()
    local minW, minH, maxW, maxH = f:GetResizeBounds()
    assertEqual(minW, ROW_W + PAD * 2, "today's width is the minimum")
    assertEqual(minH, heightFor(2)); assertEqual(maxH, heightFor(2))
    for i = 3, 5 do list[i] = row("r" .. i, "locked", false) end
    p.Refresh()
    local gW, gH, gMaxW, gMaxH = f:GetResizeBounds()
    assertEqual(gH, heightFor(5), "grown: min height re-pinned")
    assertEqual(gMaxH, heightFor(5), "grown: max height re-pinned")
    assertEqual(gW, minW, "width bounds untouched"); assertEqual(gMaxW, maxW, "width bounds untouched")
    for i = 5, 2, -1 do list[i] = nil end
    p.Refresh()
    local _, sH, _, sMaxH = f:GetResizeBounds()
    assertEqual(sH, heightFor(1), "shrunk: min height re-pinned")
    assertEqual(sMaxH, heightFor(1), "shrunk: max height re-pinned")
  end)
end)

test("sim panel render: the old SetMinResize / SetMaxResize pair is used where SetResizeBounds is absent", function()
  recording(mocks, function()
    local list = { row("a", "ready", true) }
    local p = newPanel(list)
    local f = p.Frame()
    -- False, not nil: the kit frame's metatable answers any capitalized name with a function.
    rawset(f, "SetResizeBounds", false)
    rawset(f, "GetResizeBounds", false)
    rawset(f, "SetMinResize", function(self, w, h) self.__minResize = { w, h } end)
    rawset(f, "SetMaxResize", function(self, w, h) self.__maxResize = { w, h } end)
    list[2] = row("b", "locked", false)
    p.Refresh()
    assertEqual(f.__minResize[2], heightFor(2)); assertEqual(f.__maxResize[2], heightFor(2))
    assertEqual(f.__minResize[1], ROW_W + PAD * 2, "minimum width is the built width")
  end)
end)

test("sim panel render: a width resize stretches every row, and new rows come at the stretched width", function()
  recording(mocks, function()
    local list = { row("a", "ready", true) }
    local p = newPanel(list)
    p.Show()
    local f = p.Frame()
    f:__setGeom(500, f:GetHeight())
    f:__fire("OnSizeChanged", 500, f:GetHeight())
    assertEqual(p.Buttons()[1]:GetWidth(), 500 - PAD * 2)
    list[2] = row("b", "locked", false)
    p.Refresh()
    assertEqual(p.Buttons()[2]:GetWidth(), 500 - PAD * 2)
  end)
end)

-- ── the done mark ────────────────────────────────────────────────────────────────────────────

test("sim panel render: with a check, a done row shows the tinted check over a hidden dot", function()
  recording(mocks, function()
    local list = { row("Done", "done", false), row("Next", "ready", true) }
    local p = newPanel(list, { check = HOST_CHECK })
    p.Show()
    local done, ready = p.Buttons()[1], p.Buttons()[2]
    assertEqual(done.check.__texture, HOST_CHECK, "the host's art")
    assertTrue(done.check:IsShown(), "check shown")
    assertFalse(done.dot:IsShown(), "dot hidden under it")
    sameColor(T, done.check.__vertexColor, COLORS.done, "tinted with the state color")
    assertEqual(done.check.__pts[1].point, "CENTER"); assertTrue(done.check.__pts[1].rel == done.dot, "over the dot")
    assertFalse(ready.check:IsShown(), "not done: no check")
    assertTrue(ready.dot:IsShown(), "not done: the dot")
    list[1] = row("Done", "ready", true)
    p.Refresh()
    assertFalse(done.check:IsShown(), "a row that stops being done loses the check")
    assertTrue(done.dot:IsShown(), "and gets its dot back")
  end)
end)

test("sim panel render: with no check, a done row keeps its dot and no check is built", function()
  recording(mocks, function()
    local p = newPanel({ row("Done", "done", false) })
    p.Show()
    local b = p.Buttons()[1]
    assertNil(b.check, "no check texture")
    assertTrue(b.dot:IsShown())
  end)
end)

-- ── the MakeResizable guard ──────────────────────────────────────────────────────────────────

test("sim panel render: with no MakeResizable in Core the panel builds fixed", function()
  -- LK-11's spike: the renderer called core.MakeResizable unguarded, and the no-MakeResizable
  -- fixture (tests/test_resize_windows.lua) caught it. Guarded here.
  local real = core.MakeResizable
  core.MakeResizable = nil
  local ok, err = pcall(function()
    local list = { row("a", "ready", true) }
    local p = newPanel(list)
    p.Show()
    local f = p.Frame()
    assertNil(f.resizeGrip, "no grip")
    assertTrue(p.IsShown(), "and the panel still works")
    list[2] = row("b", "locked", false)
    p.Refresh()
    assertEqual(#p.Buttons(), 2)
  end)
  core.MakeResizable = real
  if not ok then error(err, 0) end
end)
