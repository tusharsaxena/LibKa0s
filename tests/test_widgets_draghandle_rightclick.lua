-- tests/test_widgets_draghandle_rightclick.lua — LibKa0s-Widgets-1.0: the drag strip's right-click at
-- WidgetsDragHandle minor 17 (SRC-LK-01 of Ka0sAddonsCommonTasks docs/2026-11-23-STRIP_RIGHT_CLICK).
--
-- The owner's words, 2026-11-23: "Right clicking on any unlock strip should open the relevant settings
-- page - same way as clicking the gear icon." Through minor 16 a strip answered a right-click only when
-- its host passed `spec.onRightClick`, so Ka0s Absorb Tracker's strip, whose gear opens the bar's own
-- Appearance page, did nothing on a right-click while Ka0s Aura Master's, which wires both, worked.
--
-- Four claims:
--
--   * THE DEFAULT: a strip with a settings mark and no `onRightClick` answers a right-click, on the
--     strip and on each of its marks, with the settings mark's own action: `spec.settings` when it is
--     a function, else `spec.onSettings`, else the owner's registered opener. The same function the
--     gear's left click runs, so the two cannot open different pages.
--   * THE HOST WINS: an explicit `onRightClick` is called instead, as through minor 16.
--   * NO GEAR, NO CLICK: a strip built with `settings = false` and no `onRightClick` still registers
--     no click on any frame (dhSetClick's rule: a registered click nothing handles is swallowed).
--   * A LEFT CLICK ON THE STRIP IS STILL THE DRAG'S, never the settings'.
--
-- A suite of its own for `layout-§1`: tests/test_widgets_draghandle.lua is at some 850 lines. Like
-- tests/test_widgets_draghandle_marks.lua it builds its specs without the bench's `settings = false`.

local T = _G.LK_TEST
local assertEqual = T.assertEqual
local assertTrue  = T.assertTrue
local assertNil   = T.assertNil
local mocks       = T.mocks

local W, core = T.widgets, T.core

local Bench     = dofile("tests/fixture_draghandle.lua")
local test      = Bench.test
local geomFrame = Bench.geomFrame

--- The two required fields and whatever `over` adds; no `settings` default, unlike Bench.baseSpec.
local function spec(over)
  local s = { label = "Bar", moveFrame = geomFrame() }
  for k, v in pairs(over or {}) do s[k] = v end
  return s
end

local function regs(f) return table.concat(f.__clicks, ",") end

-- ── the default ──────────────────────────────────────────────────────────────────────────────

test("draghandle right-click: a strip whose gear is onSettings opens it on a right-click", function()
  -- red under: minor 16, where the strip registered no click at all (Ka0s Absorb Tracker's strip).
  local opened = 0
  local h = W.DragHandle(mocks.UIParent, spec({ onSettings = function() opened = opened + 1 end }))
  assertEqual(regs(h), "RightButtonUp", "the strip registers the right button")
  h:__fire("OnClick", "RightButton")
  assertEqual(opened, 1, "and a right-click runs the gear's action")
  h.settings:__fire("OnClick", "LeftButton")
  assertEqual(opened, 2, "the gear's own left click is the same function")
end)

test("draghandle right-click: a function `settings` is what the right-click runs", function()
  local seen = {}
  local h = W.DragHandle(mocks.UIParent, spec({
    settings = function() seen[#seen + 1] = "settings" end,
    onSettings = function() seen[#seen + 1] = "onSettings" end,
  }))
  h:__fire("OnClick", "RightButton")
  assertEqual(table.concat(seen, ","), "settings", "the gear's precedence: the function over onSettings")
end)

test("draghandle right-click: with no opener of its own the right-click reaches the owner's", function()
  local owner = "DHRightClickHost"
  local opened = 0
  core.RegisterSettingsOpener(owner, function() opened = opened + 1 end)
  local h = W.DragHandle(mocks.UIParent, spec({ owner = owner }))
  h:__fire("OnClick", "RightButton")
  assertEqual(opened, 1, "Core's OpenSettings(owner), the gear's last rung")
end)

test("draghandle right-click: every mark passes the right-click to the gear's action", function()
  -- The marks pass a right-click through (minor 15), so none is a dead zone for the default either.
  local opened, closed = 0, 0
  local h = W.DragHandle(mocks.UIParent, spec({
    onSettings = function() opened = opened + 1 end,
    onClose = function() closed = closed + 1 end,
  }))
  assertEqual(regs(h.help), "RightButtonUp")
  assertEqual(regs(h.settings), "LeftButtonUp,RightButtonUp")
  assertEqual(regs(h.close), "LeftButtonUp,RightButtonUp")
  h.help:__fire("OnClick", "RightButton")
  h.settings:__fire("OnClick", "RightButton")
  h.close:__fire("OnClick", "RightButton")
  assertEqual(opened, 3, "the '?', the gear and the X each open settings on a right-click")
  assertEqual(closed, 0, "a right-click on the X never closes")
end)

test("draghandle right-click: a left click on the strip is still the drag's", function()
  local opened = 0
  local h = W.DragHandle(mocks.UIParent, spec({ onSettings = function() opened = opened + 1 end }))
  h:__fire("OnClick", "LeftButton")
  assertEqual(opened, 0)
end)

test("draghandle right-click: an opener that raises is reported, never thrown at the click", function()
  local reported
  local saved = rawget(_G, "geterrorhandler")
  rawset(_G, "geterrorhandler", function() return function(e) reported = e end end)
  local h = W.DragHandle(mocks.UIParent, spec({ onSettings = function() error("boom", 0) end }))
  local ok = pcall(h.__fire, h, "OnClick", "RightButton")
  rawset(_G, "geterrorhandler", saved)
  assertTrue(ok, "the click itself does not raise")
  assertEqual(reported, "boom", "the error reaches the error handler, as the gear's does")
end)

-- ── the host wins ────────────────────────────────────────────────────────────────────────────

test("draghandle right-click: a host's own onRightClick is called instead of the gear's", function()
  local opened, menus = 0, 0
  local h = W.DragHandle(mocks.UIParent, spec({
    onSettings = function() opened = opened + 1 end,
    onRightClick = function() menus = menus + 1 end,
    onClose = function() end,
  }))
  h:__fire("OnClick", "RightButton")
  h.help:__fire("OnClick", "RightButton")
  h.settings:__fire("OnClick", "RightButton")
  h.close:__fire("OnClick", "RightButton")
  assertEqual(menus, 4, "the host's right-click on the strip and on every mark")
  assertEqual(opened, 0, "and the gear's action only on the gear's left click")
  h.settings:__fire("OnClick", "LeftButton")
  assertEqual(opened, 1)
end)

-- ── no gear, no click ────────────────────────────────────────────────────────────────────────

test("draghandle right-click: a strip with settings = false and no onRightClick registers nothing", function()
  local closed = 0
  local h = W.DragHandle(mocks.UIParent, spec({ settings = false, onClose = function() closed = closed + 1 end }))
  assertNil(h.settings)
  assertEqual(#h.__clicks, 0, "the strip")
  assertEqual(#h.help.__clicks, 0, "the '?'")
  assertNil(h:GetScript("OnClick"))
  assertEqual(regs(h.close), "LeftButtonUp", "the X keeps its left click alone")
end)

test("draghandle right-click: the minor and its module row moved", function()
  assertTrue(W.__dragMinor >= 17, "WidgetsDragHandle is at minor 17 or later")
  assertEqual(W.MODULES.WidgetsDragHandle, W.__dragMinor)
end)
