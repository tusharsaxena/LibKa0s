-- tests/test_mock_resize.lua — the kit's frame resize surface (revision 33, testkit/mock_resize.lua).
--
-- Through revision 32 every resize call answered from mock_base.lua's metatable, which hands back
-- the frame: `IsResizable()` and `IsUserPlaced()` were truthy whatever the frame had been told, and
-- `GetResizeBounds()` answered a table where the client answers four numbers. Each case below is
-- red on revision 32's mock for the reason its comment names.
--
-- Every case builds a fresh mock, for the reason `tests/test_mock_record.lua` gives.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse

local buildMocks = dofile("tests/wow_mock.lua")

test("resize mock: a new frame is neither resizable nor user-placed", function()
  -- red under: revision 32, where both answered the frame itself (truthy)
  local f = buildMocks().CreateFrame("Frame")
  assertFalse(f:IsResizable(), "not resizable until told")
  assertFalse(f:IsUserPlaced(), "not user-placed until moved, sized or told")
end)

test("resize mock: SetResizable is answered back by IsResizable", function()
  local f = buildMocks().CreateFrame("Frame")
  f:SetResizable(true)
  assertTrue(f:IsResizable())
  f:SetResizable(false)
  assertFalse(f:IsResizable())
end)

test("resize mock: GetResizeBounds answers the four numbers SetResizeBounds was given", function()
  -- red under: revision 32, where GetResizeBounds answered the frame, not numbers
  local f = buildMocks().CreateFrame("Frame")
  assertEqual(select("#", f:GetResizeBounds()), 4, "four values before any bounds are set")
  assertEqual(f:GetResizeBounds(), 0, "and they are zeros")
  f:SetResizeBounds(100, 50, 800, 600)
  local a, b, c, d = f:GetResizeBounds()
  assertEqual(a, 100); assertEqual(b, 50); assertEqual(c, 800); assertEqual(d, 600)
end)

test("resize mock: StartSizing records the point and marks the frame user-placed", function()
  -- red under: drop the __userPlaced write from StartSizing in testkit/mock_resize.lua
  local f = buildMocks().CreateFrame("Frame")
  f:StartSizing("BOTTOMRIGHT")
  assertEqual(f.__sizing, "BOTTOMRIGHT", "the point is recorded while sizing")
  assertEqual(f.__sizingCount, 1)
  assertTrue(f:IsUserPlaced(), "sizing flags the frame for the client's layout cache")
  f:StopMovingOrSizing()
  assertEqual(f.__sizing, nil, "and cleared on the stop")
  assertEqual(f.__stopCount, 1)
  assertTrue(f:IsUserPlaced(), "the stop does not clear the flag: the caller has to")
end)

test("resize mock: StartMoving marks the frame user-placed, and SetUserPlaced clears it", function()
  local f = buildMocks().CreateFrame("Frame")
  f:StartMoving()
  assertTrue(f:IsUserPlaced(), "a drag flags the frame, as in the client")
  f:SetUserPlaced(false)
  assertFalse(f:IsUserPlaced())
end)

test("resize mock: a frame's own stub (M.__stubFrame) carries the surface too", function()
  local M = buildMocks()
  local f = M.__stubFrame()
  assertFalse(f:IsResizable())
  assertFalse(f:IsUserPlaced())
end)
