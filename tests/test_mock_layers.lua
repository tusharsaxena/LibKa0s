-- tests/test_mock_layers.lua — the kit's opt-in frame-layer recorder (revision 42,
-- testkit/mock_layers.lua).
--
-- Through revision 41 every layer call answered from the base's metatable: GetFrameLevel and
-- GetParent handed back THE FRAME, and SetFrameStrata, SetToplevel, SetClampedToScreen and the rest
-- stored nothing, so a suite could not assert that a window sat in the strata it was given or that a
-- child inherited its parent's level (fidelity rules 1 and 2). The recorder answers them, opt-in.
--
-- Every case builds a fresh mock, for the reason `tests/test_mock_record.lua` gives.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse
local assertErrorMatches = T.assertErrorMatches

local buildMocks = dofile("tests/wow_mock.lua")
local install = dofile("tests/_kit/mock_layers.lua")

test("layer mock: strata and level are inherited through the parent chain", function()
  -- red under: revision 41, where GetFrameLevel answered the frame and GetFrameStrata nothing real
  local M = buildMocks(); install(M)
  local root = M.CreateFrame("Frame")
  local mid = M.CreateFrame("Frame", nil, root)
  local leaf = M.CreateFrame("Frame", nil, mid)
  assertEqual(root:GetFrameStrata(), "MEDIUM", "a root defaults to MEDIUM")
  assertEqual(root:GetFrameLevel(), 0, "a root sits at level 0")
  assertEqual(mid:GetFrameLevel(), 1); assertEqual(leaf:GetFrameLevel(), 2)
  root:SetFrameStrata("DIALOG")
  assertEqual(leaf:GetFrameStrata(), "DIALOG", "a child takes its ancestor's strata")
  mid:SetFrameLevel(10)
  assertEqual(leaf:GetFrameLevel(), 11, "and its parent's level plus one")
  assertTrue(leaf:GetParent() == mid, "GetParent answers the parent, not the frame")
end)

test("layer mock: an explicit level survives until SetParent, which re-derives it", function()
  local M = buildMocks(); install(M)
  local a, b = M.CreateFrame("Frame"), M.CreateFrame("Frame")
  b:SetFrameLevel(20)
  local f = M.CreateFrame("Frame", nil, a)
  f:SetFrameLevel(7)
  assertEqual(f:GetFrameLevel(), 7, "explicit wins over the parent's")
  f:SetParent(b)
  assertTrue(f:GetParent() == b)
  assertEqual(f:GetFrameLevel(), 21, "SetParent drops the explicit level (XS-18)")
end)

test("layer mock: toplevel, clamp, parent alpha and fixed strata/level round-trip", function()
  local M = buildMocks(); install(M)
  local f = M.CreateFrame("Frame")
  assertFalse(f:IsToplevel()); assertFalse(f:IsClampedToScreen())
  assertFalse(f:IsIgnoringParentAlpha()); assertFalse(f:HasFixedFrameStrata())
  assertFalse(f:HasFixedFrameLevel())
  f:SetToplevel(true); f:SetClampedToScreen(true); f:SetIgnoreParentAlpha(true)
  f:SetFixedFrameStrata(true); f:SetFixedFrameLevel(true)
  assertTrue(f:IsToplevel()); assertTrue(f:IsClampedToScreen())
  assertTrue(f:IsIgnoringParentAlpha()); assertTrue(f:HasFixedFrameStrata())
  assertTrue(f:HasFixedFrameLevel())
  f:SetFrameStrata("HIGH"); f:SetFrameLevel(5)
  local s = M.__layers(f)
  assertEqual(s.strata, "HIGH"); assertEqual(s.level, 5)
  assertTrue(s.toplevel); assertTrue(s.clamped); assertTrue(s.fixedStrata)
  assertTrue(s.ignoreParentAlpha)
  f:SetToplevel(false)
  assertFalse(f:IsToplevel())
end)

test("layer mock: Raise and Lower are counted", function()
  local M = buildMocks(); install(M)
  local f = M.CreateFrame("Frame")
  assertEqual(M.__layers(f).raised, 0)
  f:Raise(); f:Raise(); f:Lower()
  assertEqual(M.__layers(f).raised, 2)
  assertEqual(f.__lowered, 1)
end)

test("layer mock: an unknown strata raises, naming itself", function()
  local M = buildMocks(); install(M)
  local f = M.CreateFrame("Frame")
  assertErrorMatches(function() f:SetFrameStrata("SKY") end, "SKY")
  for _, s in ipairs({ "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN",
                       "FULLSCREEN_DIALOG", "TOOLTIP" }) do
    f:SetFrameStrata(s)
    assertEqual(f:GetFrameStrata(), s)
  end
end)

test("layer mock: UIParent carries the recorder too", function()
  local M = buildMocks(); install(M)
  M.UIParent:SetFrameStrata("LOW")
  local f = M.CreateFrame("Frame", nil, M.UIParent)
  assertEqual(f:GetFrameStrata(), "LOW")
  assertEqual(f:GetFrameLevel(), 1)
end)

test("layer mock: restore() puts CreateFrame back, and later frames are plain", function()
  local M = buildMocks()
  local before = M.CreateFrame
  local restore = install(M)
  assertTrue(M.CreateFrame ~= before, "installed")
  restore()
  assertTrue(M.CreateFrame == before, "restored")
  local f = M.CreateFrame("Frame")
  assertEqual(rawget(f, "SetFrameStrata"), nil, "a frame built after restore has no recorder")
  assertTrue(f:GetFrameLevel() == f, "and answers from the base metatable again")
end)
