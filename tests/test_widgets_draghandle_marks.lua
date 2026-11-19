-- tests/test_widgets_draghandle_marks.lua — LibKa0s-Widgets-1.0: the drag strip's three marks at
-- WidgetsDragHandle minor 15 (AF-LK-01 of Ka0sAddonsCommonTasks docs/2026-11-19-ADOPTION_FEEDBACK, the
-- owner's feedback on the adoption smoke, images 6-9).
--
-- Four claims, each the owner's words made a number:
--
--   * THE ORDER is [?][settings][close] left to right, the window header's (WidgetsHeader.lua's
--     extras, settings, close): the X in the corner, the gear against it, the "?" leftmost.
--   * THE GAP is reduced: the arts sit 6px of air apart (10 through minor 14), inside the 4-6 the
--     run asked for, and the corner art keeps the window header's 9px from the edge.
--   * THE TINT at rest and under the pointer is the window header's, read back off a real header
--     mark and a real Core close button rather than off a typed literal.
--   * THE SETTINGS MARK IS STANDARD: built unless `settings = false`; the X still needs `onClose`
--     and a strip without one shows no X.
--
-- A suite of its own for `layout-§1`: tests/test_widgets_draghandle.lua is at some 850 lines. It
-- shares tests/fixture_draghandle.lua's bench, but builds its specs WITHOUT the bench's
-- `settings = false` default (spec() below), because the default is what is under test here.

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
  local s = { label = "Buffs", moveFrame = geomFrame() }
  for k, v in pairs(over or {}) do s[k] = v end
  return s
end

local function rgb(c) return table.concat({ c[1], c[2], c[3] }, ",") end

--- The x offset of `f`'s first point and the frame it is anchored to.
local function anchor(f)
  local point, rel, relPoint, x = f:GetPoint(1)
  return point .. "," .. relPoint .. "," .. x, rel
end

-- ── the order ────────────────────────────────────────────────────────────────────────────────

test("draghandle marks: the order is [?][settings][close], the X in the corner", function()
  -- red under: minor 14's [settings][close][?], the owner's image 6.
  local h = W.DragHandle(mocks.UIParent, spec({ onClose = function() end }))
  local D = W.DRAG_HANDLE
  assertTrue(h.close and h.settings and h.help, "three marks")
  local a, rel = anchor(h.close)
  assertEqual(a, "RIGHT,RIGHT," .. -D.HELP_INSET, "the X in the corner")
  assertTrue(rel == h)
  a, rel = anchor(h.settings)
  assertEqual(a, "RIGHT,LEFT," .. -D.CLOSE_GAP, "the gear against the X")
  assertTrue(rel == h.close)
  a, rel = anchor(h.help)
  assertEqual(a, "RIGHT,LEFT," .. -D.CLOSE_GAP, "the '?' against the gear")
  assertTrue(rel == h.settings)
end)

test("draghandle marks: a strip without an X puts the gear in the corner and the '?' against it", function()
  local h = W.DragHandle(mocks.UIParent, spec())
  assertNil(h.close)
  local a, rel = anchor(h.settings)
  assertEqual(a, "RIGHT,RIGHT," .. -W.DRAG_HANDLE.HELP_INSET)
  assertTrue(rel == h)
  local _, hrel = anchor(h.help)
  assertTrue(hrel == h.settings)
end)

-- ── the gap ──────────────────────────────────────────────────────────────────────────────────

test("draghandle marks: the arts sit 6px of air apart, and the corner art 9px from the edge", function()
  -- red under: minor 14's 18px frames, 10px of air between two arts (the owner: "reduce the gap").
  local D = W.DRAG_HANDLE
  local h = W.DragHandle(mocks.UIParent, spec({ onClose = function() end }))
  for _, k in ipairs({ "help", "settings", "close" }) do
    assertEqual(h[k].__w .. "x" .. h[k].__h, D.HELP_HIT .. "x" .. D.HEIGHT, k .. ": the frame, as tall as the strip")
    assertEqual(h[k].icon.__w, D.HELP, k .. ": the art")
  end
  local air = D.HELP_HIT + D.CLOSE_GAP - D.HELP
  assertEqual(air, 6, "art to art")
  assertTrue(air >= 4 and air <= 6, "inside the run's 4-6")
  local H = W.HEADER
  assertEqual(D.HELP_INSET + D.HELP_GUTTER, H.PAD + (H.SIZE - H.ART) / 2,
    "the corner art sits where a window header's does, 9px in")
  assertTrue(D.HELP_HIT >= 12, "and each mark keeps a usable click target")
end)

test("draghandle marks: each mark beyond the '?' widens the reserve by its frame, on both sides", function()
  Bench.stubMeasurer()
  local D = W.DRAG_HANDLE
  local h = W.DragHandle(mocks.UIParent, spec({ onClose = function() end }))
  assertEqual(D.RESERVE, 29, "a lone '?' keeps minor 2's reserve")
  assertEqual(h:Reserve(), D.RESERVE + 2 * (D.HELP_HIT + D.CLOSE_GAP))
  assertEqual(h:Reserve(), 57, "65 through minor 14")
  local width = h:ApplyWidth()
  assertEqual(width, 5 * 6 + D.FIT_SLACK + 57 * 2)
  local leftArt = width - D.HELP_INSET - 3 * D.HELP_HIT - 2 * D.CLOSE_GAP + D.HELP_GUTTER
  assertEqual(leftArt - (width - h:Reserve()), D.HELP_CLEAR, "the '?' keeps HELP_CLEAR in front of its ink")
end)

-- ── the tint ─────────────────────────────────────────────────────────────────────────────────

test("draghandle marks: an owner-less strip's marks rest and light in a window header's colors", function()
  -- red under: minor 14, whose marks went full white under the pointer and whose '?' stayed dim
  -- without a click (the owner's images 7-9: the strip should look like a HUD header).
  local h = W.DragHandle(mocks.UIParent, spec({ onClose = function() end }))
  local mark = W.HeaderButton(geomFrame(), { glyph = "*" })
  local close = core.MakeCloseButton(geomFrame(), function() end)
  local markRest = rgb(mark.label.__textColor)
  mark:__fire("OnEnter")
  local markHot = rgb(mark.label.__textColor)
  local closeRest = rgb(close.glyph.__textColor)
  close:__fire("OnEnter")
  local closeHot = rgb(close.glyph.__textColor)
  for _, k in ipairs({ "help", "settings" }) do
    assertEqual(rgb(h[k].icon.__vertex), markRest, k .. " at rest is the header mark's rest")
    h[k]:__fire("OnEnter")
    assertEqual(rgb(h[k].icon.__vertex), markHot, k .. " under the pointer is the header mark's hover")
    h[k]:__fire("OnLeave")
    assertEqual(rgb(h[k].icon.__vertex), markRest, k .. " back at rest")
  end
  assertEqual(rgb(h.close.icon.__vertex), closeRest, "the X at rest is Core's close")
  h.close:__fire("OnEnter")
  assertEqual(rgb(h.close.icon.__vertex), closeHot, "the X under the pointer is Core's red")
  h.close:__fire("OnLeave")
  assertEqual(rgb(h.close.icon.__vertex), closeRest)
  assertEqual(markHot, "1,0.5,0", "Ka0s Default's text.link")
  assertEqual(closeHot, "1,0.3,0.3", "Ka0s Default's close.hot")
end)

-- ── the settings mark is standard; the X needs onClose ───────────────────────────────────────

test("draghandle marks: the settings mark is built unless the host passes settings = false", function()
  -- red under: minor 14's opt-in, where a strip with no `settings` field had no gear.
  local owner = "DHMarksHost"
  local opened = 0
  core.RegisterSettingsOpener(owner, function() opened = opened + 1 end)
  local h = W.DragHandle(mocks.UIParent, spec({ owner = owner }))
  assertTrue(h.settings ~= nil, "on by default")
  h.settings:__fire("OnClick", "LeftButton")
  assertEqual(opened, 1, "and it opens the owner's registered settings")
  local off = W.DragHandle(mocks.UIParent, spec({ owner = owner, settings = false }))
  assertNil(off.settings, "settings = false opts out")
  assertEqual(off:Reserve(), W.DRAG_HANDLE.RESERVE, "and keeps no room for it")
end)

test("draghandle marks: a strip with no onClose shows no X, never a mark that does nothing", function()
  local h = W.DragHandle(mocks.UIParent, spec())
  assertNil(h.close)
  assertEqual(h:Reserve(), W.DRAG_HANDLE.RESERVE + W.DRAG_HANDLE.HELP_HIT + W.DRAG_HANDLE.CLOSE_GAP,
    "room for the '?' and the gear only")
  local closed = 0
  local x = W.DragHandle(mocks.UIParent, spec({ onClose = function() closed = closed + 1 end }))
  x.close:__fire("OnClick", "LeftButton")
  assertEqual(closed, 1, "with onClose the X is built and calls it")
end)
