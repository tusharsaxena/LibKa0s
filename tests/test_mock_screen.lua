-- tests/test_mock_screen.lua — the kit's opt-in fake screen and tooltip recorder (revision 57,
-- testkit/mock_screen.lua).
--
-- Through revision 56 every geometry read on a base frame answered from the metatable, the frame
-- itself, so a placer that guards its reads placed nothing and no suite could assert where a
-- tooltip opened. The screen answers them, opt-in. Every case builds a fresh mock, for the reason
-- `tests/test_mock_record.lua` gives.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil
local assertErrorMatches = T.assertErrorMatches

local buildMocks = dofile("tests/wow_mock.lua")
local install = dofile("tests/_kit/mock_screen.lua")

test("screen mock: UIParent answers the screen's size and scale, and restore puts them back", function()
  local M = buildMocks()
  local scaleBefore = M.UIParent:GetEffectiveScale()
  local scr = install(M, { width = 1600, height = 900, scale = 0.75 })
  assertEqual(M.UIParent:GetWidth(), 1600); assertEqual(M.UIParent:GetHeight(), 900)
  assertEqual(M.UIParent:GetEffectiveScale(), 0.75)
  assertEqual(M.UIParent:GetLeft(), 0); assertEqual(M.UIParent:GetTop(), 900)
  scr.resize(1920, 1080, 1)
  assertEqual(M.UIParent:GetWidth(), 1920, "resize moves it")
  scr.restore()
  assertEqual(M.UIParent:GetWidth(), 0, "the base's unarmed answer again")
  assertTrue(M.UIParent:GetEffectiveScale() == scaleBefore, "and the base's answer for the rest")
end)

test("screen mock: a frame answers its edges, center, scale, parent and shown state", function()
  local M = buildMocks(); local scr = install(M)
  local win = scr.frame{ left = 100, bottom = 200, width = 300, height = 400, scale = 0.8 }
  assertEqual(win:GetLeft(), 100); assertEqual(win:GetBottom(), 200)
  assertEqual(win:GetRight(), 400); assertEqual(win:GetTop(), 600)
  local cx, cy = win:GetCenter()
  assertEqual(cx, 250); assertEqual(cy, 400)
  assertEqual(win:GetEffectiveScale(), 0.8)
  assertTrue(win:GetParent() == M.UIParent, "UIParent by default")
  local row = scr.frame{ parent = win }
  assertTrue(row:GetParent() == win)
  assertNil(row:GetLeft(), "an unplaced frame answers nil"); assertNil(row:GetTop())
  assertTrue(win:IsShown())
  assertTrue(not scr.frame{ shown = false }:IsShown(), "spec.shown = false")
  row:__place(10, 20, 30, 40)
  assertEqual(row:GetRight(), 40, "__place moves it")
end)

test("screen mock: a tooltip records owner, points and anchor type in one ordered log", function()
  local M = buildMocks(); local scr = install(M)
  local owner = scr.frame{ left = 0, bottom = 0, width = 10, height = 10 }
  local tip = scr.tooltip{ width = 200, height = 80 }
  tip:SetOwner(owner, "ANCHOR_NONE")
  tip:SetAnchorType("ANCHOR_RIGHT", 0, 0)
  tip:ClearAllPoints()
  tip:SetPoint("TOPLEFT", M.UIParent, "BOTTOMLEFT", 702, 600)
  assertEqual(scr.ops(tip), "SetOwner SetAnchorType ClearAllPoints SetPoint")
  assertTrue(tip:GetOwner() == owner); assertEqual(tip:GetAnchorType(), "ANCHOR_RIGHT")
  assertEqual(#tip.__points, 1); assertEqual(tip.__point.x, 702)
  local l, b, r, t = scr.rectOf(tip)
  assertEqual(l, 702); assertEqual(b, 520); assertEqual(r, 902); assertEqual(t, 600)
  tip:__size(300, 80)
  assertEqual(select(3, scr.rectOf(tip)), 1002, "late growth moves the right edge")
end)

test("screen mock: rectOf reads a point relative to a frame the screen built, at the tooltip's scale", function()
  local M = buildMocks(); local scr = install(M)
  local btn = scr.frame{ left = 1000, bottom = 1000, width = 32, height = 32, scale = 0.5 }
  local tip = scr.tooltip{ width = 200, height = 80, scale = 0.5 }
  tip:SetPoint("TOPRIGHT", btn, "BOTTOMRIGHT", 0, -4)
  local l, b, r, t = scr.rectOf(tip)
  assertEqual(r, 516, "the button's right (1032 x 0.5)")
  assertEqual(t, 498, "its bottom (500) less 4 own units at 0.5")
  assertEqual(r - l, 100); assertEqual(t - b, 40)
  tip:SetPoint("TOP", {}, "BOTTOM", 0, 0)
  assertNil(scr.rectOf(tip), "a frame the screen did not build")
  tip:SetPoint("MIDDLE", M.UIParent, "BOTTOMLEFT", 0, 0)
  assertErrorMatches(function() scr.rectOf(tip) end, "unknown point MIDDLE")
end)
