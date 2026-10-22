-- tests/test_widgets_step_panel.lua — LibKa0s-Widgets-1.0: `lib.StepPanel`, the render-only
-- clickable step panel (`LibKa0s/WidgetsStepPanel.lua`, minor 1, #53).
--
-- The widget draws rows a host composes and dispatches clicks a host decides on; it owns no state
-- semantics. So this suite drives it with a plain `rows()` over a table the case mutates, and asks
-- what was drawn.
--
-- The kit's frame answers `CreateTexture` and `CreateFontString` with the frame itself (its
-- header's known divergence), so a row's label, its dot and its command would be one table and a
-- color painted on one would read back from all three. `recording` swaps CreateFrame for one whose
-- frames hand out DISTINCT regions that record their color, text, texture, size, points and shown
-- state, and whose own SetSize / SetWidth / SetHeight / SetPoint are recorded too. The resize
-- surface (`SetResizeBounds` / `GetResizeBounds`) is the kit's own, from testkit/mock_resize.lua.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local mocks = T.mocks
local W     = T.widgets
local core  = T.core

local HOST_CHECK = "Interface\\AddOns\\Host\\media\\icons\\confirm"

-- Perf's geometry and palette (LibKa0s/PerfPanel.lua), restated here on purpose: the widget copies
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

local function recordPoints(f)
  f.__pts = {}
  rawset(f, "SetPoint", function(self, p, rel, relPoint, x, y)
    -- The short form, SetPoint(point, x, y), carries the offsets in the second and third places.
    if type(rel) == "number" then rel, relPoint, x, y = nil, nil, rel, relPoint end
    self.__pts[#self.__pts + 1] = { point = p, rel = rel, relPoint = relPoint, x = x, y = y }
    return self
  end)
  rawset(f, "ClearAllPoints", function(self) self.__pts = {}; return self end)
end

local function recordSize(f)
  rawset(f, "SetSize", function(self, w, h) self:__setGeom(w, h); return self end)
  rawset(f, "SetWidth", function(self, w) self:__setGeom(w, self.__geomH or 0); return self end)
  rawset(f, "SetHeight", function(self, h) self:__setGeom(self.__geomW or 0, h); return self end)
end

--- One distinct region (texture or font string), recording what the widget paints on it.
local function region(parent, kind, layer, template)
  local r = { __shown = true, __kind = kind, __layer = layer, __template = template, __parent = parent }
  function r:Show() self.__shown = true; return self end
  function r:Hide() self.__shown = false; return self end
  function r:SetShown(v) self.__shown = not not v; return self end
  function r:IsShown() return self.__shown end
  function r:SetSize(w, h) self.__w, self.__h = w, h; return self end
  function r:SetPoint(p, rel, relPoint, x, y)
    self.__pts = self.__pts or {}
    self.__pts[#self.__pts + 1] = { point = p, rel = rel, relPoint = relPoint, x = x, y = y }
    return self
  end
  function r:SetText(t) self.__text = t; return self end
  function r:GetText() return self.__text end
  function r:SetTextColor(cr, cg, cb, ca) self.__textColor = { cr, cg, cb, ca }; return self end
  function r:SetColorTexture(cr, cg, cb, ca) self.__colorTexture = { cr, cg, cb, ca }; return self end
  function r:SetVertexColor(cr, cg, cb, ca) self.__vertexColor = { cr, cg, cb, ca }; return self end
  function r:SetTexture(p) self.__texture = p; return self end
  function r:GetTexture() return self.__texture end
  function r:SetJustifyH(v) self.__justifyH = v; return self end
  return r
end

local function record(f)
  recordPoints(f)
  recordSize(f)
  rawset(f, "CreateTexture", function(self, _, layer) return region(self, "Texture", layer) end)
  rawset(f, "CreateFontString", function(self, _, layer, template)
    return region(self, "FontString", layer, template)
  end)
  return f
end

--- Run `fn()` with every frame CreateFrame builds carrying the recorders above.
local function recording(fn)
  local saved = mocks.CreateFrame
  mocks.CreateFrame = function(...) return record(saved(...)) end
  local ok, err = pcall(fn)
  mocks.CreateFrame = saved
  if not ok then error(err, 0) end
end

local seq = 0
--- A panel over `list` (mutable by the case), with the descriptor's other fields overridable.
local function newPanel(list, over)
  seq = seq + 1
  local clicks = {}
  local d = {
    name = "LKStepPanelTest" .. seq,
    addonName = "TestHost",
    title = "Steps",
    rows = function() return list end,
    onClick = function(row, index) clicks[#clicks + 1] = { row = row, index = index } end,
  }
  for k, v in pairs(over or {}) do d[k] = v end
  return W.StepPanel(d), clicks, d
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

local function sameColor(got, want, msg)
  assertTrue(got ~= nil, msg .. ": no color painted")
  for i = 1, 3 do assertEqual(got[i], want[i], msg .. " [" .. i .. "]") end
end

-- ── the surface ──────────────────────────────────────────────────────────────────────────────

test("StepPanel: the file attaches at minor 1, paired on the shell's minor", function()
  assertEqual(W.MODULES.WidgetsStepPanel, 1)
  assertEqual(W.__stepPanelMinor, 1)
  assertEqual(W.__stepPanelShellMinor, W.MINOR)
  assertEqual(type(W.StepPanel), "function")
end)

test("StepPanel: the descriptor's required fields raise when missing", function()
  for _, field in ipairs({ "name", "addonName", "rows", "onClick" }) do
    local d = { name = "LKStepPanelReq", addonName = "TestHost", rows = function() return {} end,
      onClick = function() end }
    d[field] = nil
    local ok, err = pcall(W.StepPanel, d)
    assertFalse(ok, field .. " is required")
    assertTrue(tostring(err):find(field, 1, true) ~= nil, "the error names " .. field)
  end
  assertFalse((pcall(W.StepPanel, nil)), "no descriptor at all raises")
end)

test("StepPanel: the handle answers the seven members, and no frame until asked", function()
  local p = newPanel({})
  for _, k in ipairs({ "Frame", "Show", "Hide", "Toggle", "IsShown", "Refresh", "Buttons" }) do
    assertEqual(type(p[k]), "function", k)
  end
  assertFalse(p.IsShown(), "nothing is shown before the first Show")
  assertEqual(#p.Buttons(), 0, "and there are no buttons")
end)

test("StepPanel: headless, Frame() answers nil and nothing raises", function()
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

test("StepPanel: the frame's chrome is Perf's", function()
  recording(function()
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

test("StepPanel: the close mark gets the descriptor's addonName", function()
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

test("StepPanel: close=false draws no close mark", function()
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

test("StepPanel: Show, Hide, Toggle and IsShown", function()
  recording(function()
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

test("StepPanel: row geometry and the test record", function()
  recording(function()
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
      sameColor(btn.cmd.__textColor, CMD_COLOR, "command column")
      assertEqual(btn.__index, i)
      assertEqual(btn.__label, list[i].label)
      assertEqual(btn.__state, list[i].state)
      assertEqual(btn.__command, list[i].command)
      assertEqual(btn.text.__text, list[i].label)
      assertEqual(btn.cmd.__text, list[i].command)
    end
  end)
end)

test("StepPanel: every state paints Perf's palette on the label and the dot", function()
  recording(function()
    local list = {}
    for _, s in ipairs({ "done", "used", "ready", "busy", "locked", "cancel" }) do
      list[#list + 1] = row(s, s, false)
    end
    local p = newPanel(list)
    p.Show()
    for _, b in ipairs(p.Buttons()) do
      local want = COLORS[b.__state]
      sameColor(b.text.__textColor, want, b.__state .. " label")
      sameColor(b.dot.__colorTexture, want, b.__state .. " dot")
      assertEqual(b.dot.__colorTexture[4], b.__state == "locked" and 0.35 or 1, b.__state .. " dot alpha")
    end
  end)
end)

test("StepPanel: an unknown state paints as locked", function()
  recording(function()
    local p = newPanel({ row("x", "mystery", false) })
    p.Show()
    sameColor(p.Buttons()[1].text.__textColor, COLORS.locked, "fallback")
  end)
end)

test("StepPanel: actionable is explicit row data and nil means false", function()
  recording(function()
    local p = newPanel({ row("a", "ready", true), row("b", "ready", nil), row("c", "ready", false) })
    p.Show()
    local b = p.Buttons()
    assertTrue(b[1]:IsEnabled(), "actionable true")
    assertFalse(b[2]:IsEnabled(), "actionable nil")
    assertFalse(b[3]:IsEnabled(), "actionable false")
  end)
end)

test("StepPanel: command text is repainted on every Refresh", function()
  recording(function()
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

test("StepPanel: an actionable row hovers gold and leaves to its palette color", function()
  recording(function()
    local p = newPanel({ row("Next", "ready", true), row("Again", "used", true) })
    p.Show()
    for _, b in ipairs(p.Buttons()) do
      b:__fire("OnEnter")
      sameColor(b.text.__textColor, { 1, 0.82, 0 }, b.__state .. " hover")
      b:__fire("OnLeave")
      sameColor(b.text.__textColor, COLORS[b.__state], b.__state .. " leave")
    end
  end)
end)

test("StepPanel: an actionable cancel row hovers red", function()
  recording(function()
    local p = newPanel({ row("Stop", "cancel", true) })
    p.Show()
    local b = p.Buttons()[1]
    b:__fire("OnEnter")
    sameColor(b.text.__textColor, { 1, 0.45, 0.45 }, "cancel hover")
    b:__fire("OnLeave")
    sameColor(b.text.__textColor, COLORS.cancel, "cancel leave")
  end)
end)

test("StepPanel: a non-actionable row does not hover", function()
  recording(function()
    local p = newPanel({ row("Ahead", "locked", false), row("Now", "busy", false), row("Stop", "cancel", false) })
    p.Show()
    for _, b in ipairs(p.Buttons()) do
      b:__fire("OnEnter")
      sameColor(b.text.__textColor, COLORS[b.__state], b.__state .. " stays")
    end
  end)
end)

test("StepPanel: the tooltip is called on enter only for a row with a tip", function()
  recording(function()
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
    b[3]:__fire("OnEnter")
    assertEqual(#calls, 2, "a row that is not actionable still shows its tip")
    sameColor(b[3].text.__textColor, COLORS.done, "but does not hover")
  end)
end)

test("StepPanel: a row with a tip and no tooltip fn shows nothing", function()
  recording(function()
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

test("StepPanel: a click re-reads rows() and hands onClick the fresh row and its index", function()
  recording(function()
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

test("StepPanel: a row that stopped being actionable after paint is not dispatched", function()
  recording(function()
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

test("StepPanel: a click on a row index the list no longer has is not dispatched", function()
  recording(function()
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

test("StepPanel: a dispatched click repaints", function()
  recording(function()
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

test("StepPanel: height follows the row count, and a shrink hides the extra rows", function()
  recording(function()
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

test("StepPanel: a footer adds its height plus PAD, is built once and painted every Refresh", function()
  recording(function()
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

test("StepPanel: the title is re-read on every Refresh", function()
  recording(function()
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

test("StepPanel: red under: bounds fixed at MakeResizable time are re-pinned when the count moves", function()
  -- Core.MakeResizable is call-once and fixes the widthOnly height bounds at the height the frame
  -- had then. A row count that grows or shrinks afterwards would leave the grip clamping to the
  -- old height; the panel re-pins the bounds itself.
  recording(function()
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

test("StepPanel: the old SetMinResize / SetMaxResize pair is used where SetResizeBounds is absent", function()
  recording(function()
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

test("StepPanel: a width resize stretches every row, and new rows come at the stretched width", function()
  recording(function()
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

test("StepPanel: with a check, a done row shows the tinted check over a hidden dot", function()
  recording(function()
    local list = { row("Done", "done", false), row("Next", "ready", true) }
    local p = newPanel(list, { check = HOST_CHECK })
    p.Show()
    local done, ready = p.Buttons()[1], p.Buttons()[2]
    assertEqual(done.check.__texture, HOST_CHECK, "the host's art")
    assertTrue(done.check:IsShown(), "check shown")
    assertFalse(done.dot:IsShown(), "dot hidden under it")
    sameColor(done.check.__vertexColor, COLORS.done, "tinted with the state color")
    assertEqual(done.check.__pts[1].point, "CENTER"); assertTrue(done.check.__pts[1].rel == done.dot, "over the dot")
    assertFalse(ready.check:IsShown(), "not done: no check")
    assertTrue(ready.dot:IsShown(), "not done: the dot")
    list[1] = row("Done", "ready", true)
    p.Refresh()
    assertFalse(done.check:IsShown(), "a row that stops being done loses the check")
    assertTrue(done.dot:IsShown(), "and gets its dot back")
  end)
end)

test("StepPanel: with no check, a done row keeps its dot and no check is built", function()
  recording(function()
    local p = newPanel({ row("Done", "done", false) })
    p.Show()
    local b = p.Buttons()[1]
    assertNil(b.check, "no check texture")
    assertTrue(b.dot:IsShown())
  end)
end)
