-- tests/test_mock_lines.lua — the kit's Line regions (revision 37, testkit/mock_lines.lua).
--
-- Through revision 36 `CreateLine` answered from mock_base.lua's metatable, which hands back THE
-- FRAME: every line a chart drew was the same object as its parent, and SetStartPoint / SetEndPoint
-- were silent no-ops, so no suite could tell a drawn segment from a missing one (fidelity rules 1
-- and 3). Each case below is red on revision 36 for the reason its comment names.
--
-- Every case builds a fresh mock, for the reason `tests/test_mock_record.lua` gives.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse

local buildMocks = dofile("tests/wow_mock.lua")

test("line mock: CreateLine answers a distinct object per call, recorded on its frame", function()
  -- red under: revision 36, where CreateLine answered the frame itself
  local f = buildMocks().CreateFrame("Frame")
  local a, b = f:CreateLine(nil, "ARTWORK"), f:CreateLine()
  assertTrue(a ~= f and b ~= f and a ~= b, "two calls, two lines, neither the frame")
  assertEqual(#f.__madeLines, 2)
  assertTrue(f.__madeLines[1] == a and f.__madeLines[2] == b, "recorded in creation order")
  assertEqual(a.__layer, "ARTWORK")
end)

test("line mock: start, end, thickness and color are answered back", function()
  -- red under: revision 36, where every setter was a no-op and every getter answered the frame
  local l = buildMocks().CreateFrame("Frame"):CreateLine()
  l:SetStartPoint("BOTTOMLEFT", nil, 3, 4)
  l:SetEndPoint("BOTTOMLEFT", nil, 10, 12)
  l:SetThickness(2)
  l:SetColorTexture(1, 0, 0, 0.5)
  local p, _, x, y = l:GetStartPoint()
  assertEqual(p, "BOTTOMLEFT"); assertEqual(x, 3); assertEqual(y, 4)
  local _, _, x2, y2 = l:GetEndPoint()
  assertEqual(x2, 10); assertEqual(y2, 12)
  assertEqual(l:GetThickness(), 2)
  assertEqual(l.__color[1], 1); assertEqual(l.__color[4], 0.5)
end)

test("line mock: a new line is shown, and Hide / Show / SetShown are tracked", function()
  local l = buildMocks().CreateFrame("Frame"):CreateLine()
  assertTrue(l:IsShown(), "a new region is shown, as in the client")
  l:Hide(); assertFalse(l:IsShown())
  l:SetShown(true); assertTrue(l:IsShown())
end)

test("line mock: ClearAllPoints forgets both ends", function()
  local l = buildMocks().CreateFrame("Frame"):CreateLine()
  l:SetStartPoint("CENTER", nil, 1, 1); l:SetEndPoint("CENTER", nil, 2, 2)
  l:ClearAllPoints()
  assertEqual(l:GetStartPoint(), nil); assertEqual(l:GetEndPoint(), nil)
end)

test("line mock: an unmodeled method raises instead of silently succeeding", function()
  -- Fidelity rule 1: a Line is not a Frame, and a call the client would not answer must not pass.
  local l = buildMocks().CreateFrame("Frame"):CreateLine()
  local ok, err = pcall(function() l:SetScript("OnUpdate", function() end) end)
  assertFalse(ok, "a Line has no SetScript in the client")
  assertTrue(tostring(err):find("SetScript", 1, true) ~= nil, "the error names the method")
end)
