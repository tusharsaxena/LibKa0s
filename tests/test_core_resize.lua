-- tests/test_core_resize.lua — Core.MakeResizable, the grip every Ka0s diagnostic window resizes
-- from (Core minor 9). The windows that use it are pinned in tests/test_resize_windows.lua; this
-- suite pins the helper's own contract: the grip, the bounds, the two mouse edges, the relayout and
-- the user-placed flag that keeps a resize out of the client's layout cache.

local T = _G.LK_TEST
local core, mocks = T.core, T.mocks
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local function newWindow()
  return mocks.CreateFrame("Frame", "ResizeCase", mocks.UIParent, "BackdropTemplate")
end

-- Run `fn` with UIParent answering a screen size, then put it back to the unarmed stub.
local function withScreen(w, h, fn)
  local ui = mocks.UIParent
  ui:__setGeom(w, h)
  local ok, err = pcall(fn)
  rawset(ui, "__geomLive", nil)
  rawset(ui, "__geomW", nil)
  rawset(ui, "__geomH", nil)
  if not ok then error(err, 0) end
end

test("resize: MakeResizable makes the frame resizable and answers the grip it built", function()
  -- red under: drop the SetResizable call from lib.MakeResizable in LibKa0s/Core.lua
  local f = newWindow()
  local grip = core.MakeResizable(f, { minWidth = 200, minHeight = 100 })
  assertTrue(f:IsResizable(), "the frame is resizable")
  assertTrue(type(grip) == "table", "a grip is answered")
  assertEqual(f.resizeGrip, grip, "and kept on the frame")
  assertEqual(grip.__frameType, "Button")
  assertEqual(grip.__parent, f, "the grip is the window's child")
  assertTrue(grip:IsShown(), "and always shown")
end)

test("resize: the bounds are the options' minimum and the screen's size", function()
  -- red under: default the maximum to anything but UIParent's size
  withScreen(1920, 1080, function()
    local f = newWindow()
    core.MakeResizable(f, { minWidth = 300, minHeight = 120 })
    local minW, minH, maxW, maxH = f:GetResizeBounds()
    assertEqual(minW, 300); assertEqual(minH, 120)
    assertEqual(maxW, 1920, "max width defaults to the UI's width")
    assertEqual(maxH, 1080, "max height defaults to the UI's height")
  end)
end)

test("resize: explicit maxima win over the screen", function()
  local f = newWindow()
  core.MakeResizable(f, { minWidth = 300, minHeight = 120, maxWidth = 900, maxHeight = 500 })
  local _, _, maxW, maxH = f:GetResizeBounds()
  assertEqual(maxW, 900); assertEqual(maxH, 500)
end)

test("resize: with no minimum the frame's current size is the minimum", function()
  local f = newWindow()
  f:__setGeom(640, 420)
  core.MakeResizable(f)
  local minW, minH = f:GetResizeBounds()
  assertEqual(minW, 640); assertEqual(minH, 420)
end)

test("resize: widthOnly pins the height at the minimum", function()
  -- red under: drop the `if opts.widthOnly then maxH = minH end` line
  withScreen(1920, 1080, function()
    local f = newWindow()
    core.MakeResizable(f, { minWidth = 376, minHeight = 196, widthOnly = true })
    local minW, minH, maxW, maxH = f:GetResizeBounds()
    assertEqual(minW, 376); assertEqual(maxW, 1920, "width still ranges to the screen")
    assertEqual(minH, 196); assertEqual(maxH, 196, "height cannot move")
  end)
end)

test("resize: a client without SetResizeBounds gets SetMinResize and SetMaxResize", function()
  -- red under: call SetResizeBounds unguarded (a pre-10.0 frame has no such method)
  local f = newWindow()
  local seen = {}
  rawset(f, "SetResizeBounds", false)
  rawset(f, "SetMinResize", function(_, w, h) seen.min = { w, h } end)
  rawset(f, "SetMaxResize", function(_, w, h) seen.max = { w, h } end)
  core.MakeResizable(f, { minWidth = 200, minHeight = 100, maxWidth = 800, maxHeight = 600 })
  assertEqual(seen.min[1], 200); assertEqual(seen.min[2], 100)
  assertEqual(seen.max[1], 800); assertEqual(seen.max[2], 600)
end)

test("resize: a left mouse-down on the grip starts sizing from the bottom-right", function()
  local f = newWindow()
  local grip = core.MakeResizable(f, { minWidth = 200, minHeight = 100 })
  grip:__fire("OnMouseDown", "LeftButton")
  assertEqual(f.__sizing, "BOTTOMRIGHT")
  assertEqual(f.__sizingCount, 1)
end)

test("resize: any other button does not start sizing", function()
  local f = newWindow()
  local grip = core.MakeResizable(f, { minWidth = 200, minHeight = 100 })
  grip:__fire("OnMouseDown", "RightButton")
  assertEqual(f.__sizingCount, 0)
  grip:__fire("OnMouseUp", "RightButton")
  assertEqual(f.__stopCount, 0, "and a mouse-up with no sizing in progress stops nothing")
end)

test("resize: mouse-up stops sizing and hands the new size to onResize", function()
  local f = newWindow()
  local got
  local grip = core.MakeResizable(f, {
    minWidth = 200, minHeight = 100, onResize = function(w, h) got = { w, h } end,
  })
  grip:__fire("OnMouseDown", "LeftButton")
  f:__setGeom(820, 410)   -- what the client's sizing left the frame at
  grip:__fire("OnMouseUp", "LeftButton")
  assertEqual(f.__stopCount, 1, "StopMovingOrSizing ran")
  assertEqual(got[1], 820); assertEqual(got[2], 410)
end)

test("resize: a resize alone leaves the frame out of the client's layout cache", function()
  -- red under: drop the SetUserPlaced(wasPlaced) after StopMovingOrSizing; StartSizing marks the
  -- frame user-placed, and a user-placed named frame has its size written to layout-local.txt
  local f = newWindow()
  local grip = core.MakeResizable(f, { minWidth = 200, minHeight = 100 })
  assertFalse(f:IsUserPlaced(), "an undragged window starts out of the cache")
  grip:__fire("OnMouseDown", "LeftButton")
  assertTrue(f:IsUserPlaced(), "sizing flagged it, as the client does")
  grip:__fire("OnMouseUp", "LeftButton")
  assertFalse(f:IsUserPlaced(), "and the grip put the flag back")
end)

test("resize: a window dragged before the resize stays user-placed, exactly as a drag leaves it", function()
  -- red under: SetUserPlaced(false) unconditionally after sizing, which would change how a dragged
  -- window's POSITION behaves across a /reload
  local f = newWindow()
  local grip = core.MakeResizable(f, { minWidth = 200, minHeight = 100 })
  f:StartMoving(); f:StopMovingOrSizing()
  assertTrue(f:IsUserPlaced(), "the drag flagged it")
  grip:__fire("OnMouseDown", "LeftButton")
  grip:__fire("OnMouseUp", "LeftButton")
  assertTrue(f:IsUserPlaced(), "the resize did not change what the drag did")
end)

test("resize: OnSizeChanged runs the relayout, after any script the frame already had", function()
  -- red under: SetScript rather than HookScript, which would drop the host's own handler
  local f = newWindow()
  local order = {}
  f:SetScript("OnSizeChanged", function() order[#order + 1] = "host" end)
  core.MakeResizable(f, {
    minWidth = 200, minHeight = 100,
    onResize = function(w, h) order[#order + 1] = "relayout " .. w .. "x" .. h end,
  })
  f:__fire("OnSizeChanged", 500, 250)
  assertEqual(table.concat(order, ","), "host,relayout 500x250")
end)

test("resize: no onResize is fine", function()
  local f = newWindow()
  local grip = core.MakeResizable(f, { minWidth = 200, minHeight = 100 })
  grip:__fire("OnMouseDown", "LeftButton")
  grip:__fire("OnMouseUp", "LeftButton")
  f:__fire("OnSizeChanged", 300, 200)
  assertEqual(f.__stopCount, 1)
end)

test("resize: without CreateFrame, or on a frame with no sizing API, nothing changes", function()
  local f = newWindow()
  local realCreate = mocks.CreateFrame
  mocks.CreateFrame = nil
  local ok, grip = pcall(core.MakeResizable, f, { minWidth = 200 })
  mocks.CreateFrame = realCreate
  assertTrue(ok, tostring(grip))
  assertNil(grip, "no client, no grip")
  assertFalse(f:IsResizable(), "and the frame is untouched")
  assertNil(core.MakeResizable({}, { minWidth = 200 }), "a table with no sizing API is refused")
  assertNil(core.MakeResizable(nil), "and so is nil")
end)
