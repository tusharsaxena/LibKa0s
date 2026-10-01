-- tests/test_core_resize.lua — Core.MakeResizable, the grip every Ka0s diagnostic window resizes
-- from (Core minor 9; minor 10 adds the canResize gate, the onResizeStop callback and gripParent).
-- The windows that use it are pinned in tests/test_resize_windows.lua; this suite pins the helper's
-- own contract: the grip, the bounds, the two mouse edges, the relayout, the user-placed flag that
-- keeps a resize out of the client's layout cache, and minor 10's three optional fields.

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
  local function note(what)
    order[#order + 1] = what
  end
  f:SetScript("OnSizeChanged", function() note("host") end)
  core.MakeResizable(f, {
    minWidth = 200, minHeight = 100,
    onResize = function(w, h) note("relayout " .. w .. "x" .. h) end,
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

-- ── Core minor 10: canResize, onResizeStop, gripParent (LibKa0s#41) ─────────────────────────

-- Run `fn` with every frame built while it runs recording its SetPoint arguments as `__points`
-- and its SetFrameLevel argument as `__level` (both still applied), so a case can read where the
-- library anchored the grip and at what level.
local function recordGrip(fn)
  local realCreate = mocks.CreateFrame
  mocks.CreateFrame = function(...)
    local f = realCreate(...)
    f.__points = {}
    local setPoint, setLevel = f.SetPoint, f.SetFrameLevel
    rawset(f, "SetPoint", function(self, ...)
      table.insert(self.__points, { ... })
      if type(setPoint) == "function" then return setPoint(self, ...) end
    end)
    rawset(f, "SetFrameLevel", function(self, level)
      self.__level = level
      if type(setLevel) == "function" then return setLevel(self, level) end
    end)
    return f
  end
  local ok, err = pcall(fn)
  mocks.CreateFrame = realCreate
  if not ok then error(err, 0) end
end

test("resize: canResize answering false refuses the mouse-down, and the mouse-up after it is inert", function()
  -- red under: drop the canResize check from wireGrip in LibKa0s/Core.lua
  local f = newWindow()
  local resized, stopped = 0, 0
  local grip = core.MakeResizable(f, {
    minWidth = 200, minHeight = 100,
    canResize = function() return false end,
    onResize = function() resized = resized + 1 end,
    onResizeStop = function() stopped = stopped + 1 end,
  })
  grip:__fire("OnMouseDown", "LeftButton")
  grip:__fire("OnMouseUp", "LeftButton")
  assertEqual(f.__sizingCount, 0, "no sizing started")
  assertEqual(f.__stopCount, 0, "and nothing was stopped")
  assertEqual(resized, 0, "onResize did not run")
  assertEqual(stopped, 0, "onResizeStop did not run")
  assertFalse(f:IsUserPlaced(), "the user-placed flag is untouched")
end)

test("resize: canResize is read at every mouse-down, not once at build", function()
  -- red under: cache canResize()'s answer at MakeResizable time
  local f = newWindow()
  local locked = true
  local grip = core.MakeResizable(f, {
    minWidth = 200, minHeight = 100, canResize = function() return not locked end,
  })
  grip:__fire("OnMouseDown", "LeftButton")
  grip:__fire("OnMouseUp", "LeftButton")
  assertEqual(f.__sizingCount, 0, "locked: refused")
  locked = false
  grip:__fire("OnMouseDown", "LeftButton")
  grip:__fire("OnMouseUp", "LeftButton")
  assertEqual(f.__sizingCount, 1, "unlocked: the next mouse-down sizes")
  assertEqual(f.__stopCount, 1)
end)

test("resize: canResize is handed the frame being sized", function()
  -- red under: hand canResize the grip, or the grip's parent
  local f = newWindow()
  local seen
  local grip = core.MakeResizable(f, { canResize = function(frame) seen = frame; return true end })
  grip:__fire("OnMouseDown", "LeftButton")
  assertEqual(seen, f, "the sized frame")

  local anchor = newWindow()
  local art = mocks.CreateFrame("Frame", nil, mocks.UIParent)
  seen = nil
  grip = core.MakeResizable(anchor, {
    gripParent = art, canResize = function(frame) seen = frame; return true end,
  })
  grip:__fire("OnMouseDown", "LeftButton")
  assertEqual(seen, anchor, "the sized frame, not the grip's parent")
end)

test("resize: a sizing already started finishes even if canResize turns false mid-drag", function()
  -- red under: re-check canResize in OnMouseUp
  local f = newWindow()
  local allow, stopped = true, 0
  local grip = core.MakeResizable(f, {
    canResize = function() return allow end,
    onResizeStop = function() stopped = stopped + 1 end,
  })
  grip:__fire("OnMouseDown", "LeftButton")
  allow = false
  grip:__fire("OnMouseUp", "LeftButton")
  assertEqual(f.__stopCount, 1, "the drag was stopped")
  assertEqual(stopped, 1, "and onResizeStop ran once")
end)

test("resize: canResize never changes the grip's visibility", function()
  -- red under: hide or show the grip from the canResize gate
  local f = newWindow()
  local allow = false
  local grip = core.MakeResizable(f, { canResize = function() return allow end })
  grip:__fire("OnMouseDown", "LeftButton")
  grip:__fire("OnMouseUp", "LeftButton")
  assertTrue(grip:IsShown(), "shown after a refused mouse-down")
  allow = true
  grip:__fire("OnMouseDown", "LeftButton")
  grip:__fire("OnMouseUp", "LeftButton")
  assertTrue(grip:IsShown(), "and after an allowed one")
end)

test("resize: a canResize that is not a function is ignored", function()
  -- red under: treat any non-nil canResize as a gate
  for _, value in ipairs({ false, "no" }) do
    local f = newWindow()
    local grip = core.MakeResizable(f, { canResize = value })
    grip:__fire("OnMouseDown", "LeftButton")
    assertEqual(f.__sizingCount, 1, "sizes with canResize = " .. tostring(value))
  end
end)

test("resize: onResizeStop runs once per completed sizing, after onResize, and never from OnSizeChanged", function()
  -- red under: call onStop from the OnSizeChanged hook
  local f = newWindow()
  local order, stops = {}, 0
  local grip = core.MakeResizable(f, {
    minWidth = 200, minHeight = 100,
    onResize = function(w, h) order[#order + 1] = "resize " .. w .. "x" .. h end,
    onResizeStop = function(w, h)
      stops = stops + 1
      order[#order + 1] = "stop " .. w .. "x" .. h
    end,
  })
  for _ = 1, 3 do f:__fire("OnSizeChanged", 500, 250) end
  grip:__fire("OnMouseDown", "LeftButton")
  f:__setGeom(820, 410)
  grip:__fire("OnMouseUp", "LeftButton")
  assertEqual(table.concat(order, ","),
    "resize 500x250,resize 500x250,resize 500x250,resize 820x410,stop 820x410")
  assertEqual(stops, 1)
end)

test("resize: onResizeStop does not run for a right-click or a stray mouse-up", function()
  -- red under: run onStop on every mouse-up rather than only one that ends a sizing
  local f = newWindow()
  local stops = 0
  local grip = core.MakeResizable(f, { onResizeStop = function() stops = stops + 1 end })
  grip:__fire("OnMouseDown", "RightButton")
  grip:__fire("OnMouseUp", "RightButton")
  grip:__fire("OnMouseUp", "LeftButton")
  assertEqual(stops, 0)
end)

test("resize: gripParent builds the grip on another frame while sizing stays on frame", function()
  -- red under: buildGrip ignoring its parent argument
  recordGrip(function()
    local anchor = newWindow()
    local art = mocks.CreateFrame("Frame", nil, mocks.UIParent)
    rawset(art, "GetFrameLevel", function() return 7 end)
    local grip = core.MakeResizable(anchor, { minWidth = 200, minHeight = 100, gripParent = art })
    assertEqual(grip.__parent, art, "the grip is the art frame's child")
    local pt = grip.__points[1]
    assertEqual(pt[1], "BOTTOMRIGHT"); assertEqual(pt[2], art, "anchored to the art frame")
    assertEqual(pt[3], "BOTTOMRIGHT"); assertEqual(pt[4], -1); assertEqual(pt[5], 1)
    assertEqual(grip.__level, 17, "leveled from the art frame")
    assertEqual(anchor.resizeGrip, grip, "and still kept on the sized frame")
    assertNil(rawget(art, "resizeGrip"), "not on the art frame")
    grip:__fire("OnMouseDown", "LeftButton")
    assertEqual(anchor.__sizing, "BOTTOMRIGHT", "the sized frame sizes from its corner")
    grip:__fire("OnMouseUp", "LeftButton")
    assertEqual(anchor.__stopCount, 1, "the sized frame was sized")
    assertEqual(art.__sizingCount or 0, 0, "the art frame was not")
  end)
end)

test("resize: gripParent that is not a table falls back to the frame", function()
  -- red under: use opts.gripParent unchecked
  local f = newWindow()
  local grip = core.MakeResizable(f, { gripParent = "art" })
  assertEqual(grip.__parent, f)
end)
