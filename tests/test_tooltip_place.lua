-- tests/test_tooltip_place.lua — LibKa0s-Tooltip-1.0's placers on the kit's fake screen
-- (tests/_kit/mock_screen.lua, kit revision 57): what each one reads, the point it writes, the
-- order it writes it in, the window group it measures and what it does when the geometry cannot be
-- read (LibKa0s#92, LK-92A). The solvers' tables are tests/test_tooltip.lua's.
--
-- Every case installs the screen on the suite's shared mock and restores it, so UIParent answers
-- the base's geometry again for every other suite.

local T = _G.LK_TEST
local rawTest, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil
local mocks = T.mocks

local Tip = mocks.LibStub("LibKa0s-Tooltip-1.0")
local installScreen = dofile("tests/_kit/mock_screen.lua")

--- A case with a fresh 1920 x 1080 screen (`scr`) installed on the shared mock, restored after.
local function test(name, fn)
  rawTest("tooltip place: " .. name, function()
    local scr = installScreen(mocks, { width = 1920, height = 1080, scale = 1 })
    local before = {}
    for k in pairs(Tip.__groups) do before[k] = true end
    local ok, err = pcall(fn, scr)
    for k in pairs(Tip.__groups) do if not before[k] then Tip.__groups[k] = nil end end
    scr.restore()
    if not ok then error(err, 0) end
  end)
end

--- A window at (left, bottom) of `w` x `h`, with one row `rowTop` from its bottom.
local function window(scr, left, bottom, w, h, rowTop, scale)
  local win = scr.frame{ left = left, bottom = bottom, width = w, height = h, scale = scale }
  local row = scr.frame{ left = left, bottom = bottom + rowTop - 20, width = w, height = 20,
                         parent = win, scale = scale }
  return win, row
end

test("Own: ANCHOR_NONE on the element, or on opts.owner", function(scr)
  local _, row = window(scr, 400, 300, 300, 400, 300)
  local tip = scr.tooltip()
  assertTrue(Tip.Own(tip, row) == tip, "answers the tooltip")
  assertTrue(tip.__owner == row); assertEqual(tip.__anchor, "ANCHOR_NONE")
  Tip.Own(tip, row, { owner = mocks.UIParent })
  assertTrue(tip.__owner == mocks.UIParent, "a restricted tree's element is not the owner")
end)

test("beside: right fits, TOPLEFT on UIParent at the group's right + 2, top level with the row", function(scr)
  local win, row = window(scr, 400, 300, 300, 400, 300)
  local tip = scr.tooltip{ width = 250, height = 90 }
  assertEqual(Tip.PlaceBeside(tip, row, win), "right")
  local p = tip.__point
  assertEqual(p.point, "TOPLEFT"); assertTrue(p.rel == mocks.UIParent); assertEqual(p.relPoint, "BOTTOMLEFT")
  local l, _, _, t = scr.rectOf(tip)
  assertEqual(l, 702, "the window's right edge (700) plus TIP_GAP")
  assertEqual(t, 600, "level with the row's top")
end)

test("beside: right does not fit, TOPRIGHT at the group's left - 2", function(scr)
  local win, row = window(scr, 1500, 300, 300, 400, 300)
  local tip = scr.tooltip{ width = 250, height = 90 }
  assertEqual(Tip.PlaceBeside(tip, row, win), "left")
  assertEqual(tip.__point.point, "TOPRIGHT")
  local _, _, r, t = scr.rectOf(tip)
  assertEqual(r, 1498); assertEqual(t, 600)
end)

test("beside: the comparison side is set before the point, ANCHOR_NONE-owned", function(scr)
  local win, row = window(scr, 1500, 300, 300, 400, 300)
  local tip = scr.tooltip()
  Tip.Own(tip, row)
  Tip.PlaceBeside(tip, row, win)
  assertEqual(scr.ops(tip), "SetOwner SetAnchorType ClearAllPoints SetPoint",
    "the client's bag order: the anchor type first, so the point is the last word")
  assertEqual(tip.__anchorType, "ANCHOR_LEFT", "comparisons open further out, on the same side")
  local tip2 = scr.tooltip()
  Tip.PlaceBeside(tip2, row, win, { comparisons = false })
  assertEqual(scr.ops(tip2), "ClearAllPoints SetPoint", "opts.comparisons = false skips it")
end)

test("beside: neither side fits, centered 2 above the row; at the top, below it", function(scr)
  -- red under: the fallback's old side, under the row (SR-L1: every attached tooltip opens above)
  local win, row = window(scr, 100, 300, 1700, 400, 300)
  local tip = scr.tooltip{ width = 250, height = 90 }
  assertEqual(Tip.PlaceBeside(tip, row, win), "above")
  local l, b, r = scr.rectOf(tip)
  assertEqual(b, 602, "2 over the row's top (600)")
  assertEqual((l + r) / 2, 950, "centered on the row")
  assertEqual(scr.ops(tip), "ClearAllPoints SetPoint", "no comparison side on the fallback")
  local high, highRow = window(scr, 100, 700, 1700, 380, 370)
  assertEqual(Tip.PlaceBeside(tip, highRow, high), "below", "flipped at the screen's top")
  local _, _, _, t = scr.rectOf(tip)
  assertEqual(t, 1048, "2 under the row's bottom (1050)")
end)

test("beside: clamped vertically, sliding only as far as needed", function(scr)
  local win, row = window(scr, 400, 0, 300, 400, 50)
  local tip = scr.tooltip{ width = 250, height = 90 }
  Tip.PlaceBeside(tip, row, win)
  local _, b, _, t = scr.rectOf(tip)
  assertEqual(b, 0, "its bottom on the screen's"); assertEqual(t, 90)
end)

test("beside: scale, a 0.8 window and a 1.0 tooltip measure in one space", function(scr)
  -- the window's own units 500..875 are 400..700 on screen
  local win = scr.frame{ left = 500, bottom = 375, width = 375, height = 500, scale = 0.8 }
  local row = scr.frame{ left = 500, bottom = 725, width = 375, height = 25, parent = win, scale = 0.8 }
  local tip = scr.tooltip{ width = 250, height = 90 }
  assertEqual(Tip.PlaceBeside(tip, row, win), "right")
  local l, _, _, t = scr.rectOf(tip)
  assertEqual(l, 702); assertEqual(t, 600)
end)

test("beside: a 0.5 tooltip's point is written in its own units", function(scr)
  local win, row = window(scr, 400, 300, 300, 400, 300)
  local tip = scr.tooltip{ width = 500, height = 180, scale = 0.5 }
  Tip.PlaceBeside(tip, row, win)
  assertEqual(tip.__point.x, 1404, "702 screen units at 0.5"); assertEqual(tip.__point.y, 1200)
  local l = scr.rectOf(tip)
  assertEqual(l, 702, "and the gap is still 2 on screen")
end)

test("beside: a companion docked right of the main window opens its tips on its right", function(scr)
  local main = scr.frame{ left = 400, bottom = 300, width = 300, height = 400 }
  local panel = scr.frame{ left = 700, bottom = 300, width = 200, height = 400, parent = main }
  local prow = scr.frame{ left = 700, bottom = 580, width = 200, height = 20, parent = panel }
  local mrow = scr.frame{ left = 400, bottom = 580, width = 300, height = 20, parent = main }
  Tip.SetGroup(main, { panel })
  local tip = scr.tooltip{ width = 250, height = 90 }
  assertEqual(Tip.PlaceBeside(tip, prow), "right", "the panel's side away from the main window")
  assertEqual((scr.rectOf(tip)), 902, "beside the whole group")
  assertEqual(Tip.PlaceBeside(tip, mrow), "right", "main's own tips are measured from the panel's edge")
  assertEqual((scr.rectOf(tip)), 902)
end)

test("beside: a companion docked left prefers the left; the far side when that misses", function(scr)
  local main = scr.frame{ left = 400, bottom = 300, width = 300, height = 400 }
  local panel = scr.frame{ left = 200, bottom = 300, width = 200, height = 400, parent = main }
  local prow = scr.frame{ left = 200, bottom = 580, width = 200, height = 20, parent = panel }
  Tip.SetGroup(main, { panel })
  local tip = scr.tooltip{ width = 150, height = 90 }
  assertEqual(Tip.PlaceBeside(tip, prow), "left")
  local _, _, r = scr.rectOf(tip)
  assertEqual(r, 198, "outside the panel's left edge")
  local wide = scr.tooltip{ width = 250, height = 90 }
  assertEqual(Tip.PlaceBeside(wide, prow), "right", "no room on the left: beyond the main window")
  assertEqual((scr.rectOf(wide)), 702)
end)

test("beside: a hidden companion drops out of the group", function(scr)
  local main = scr.frame{ left = 400, bottom = 300, width = 300, height = 400 }
  local panel = scr.frame{ left = 700, bottom = 300, width = 200, height = 400, parent = main, shown = false }
  local mrow = scr.frame{ left = 400, bottom = 580, width = 300, height = 20, parent = main }
  Tip.SetGroup(main, function() return { panel } end)
  local tip = scr.tooltip()
  Tip.PlaceBeside(tip, mrow)
  assertEqual((scr.rectOf(tip)), 702, "measured from main's edge while the panel is hidden")
  panel:Show()
  Tip.PlaceBeside(tip, mrow)
  assertEqual((scr.rectOf(tip)), 902, "and from the panel's once it shows (re-read each hover)")
end)

test("beside: the group may be a frame, a list, a { main, panels } table or a function", function(scr)
  local main = scr.frame{ left = 400, bottom = 300, width = 300, height = 400 }
  local panel = scr.frame{ left = 700, bottom = 300, width = 200, height = 400 }
  local row = scr.frame{ left = 400, bottom = 580, width = 300, height = 20, parent = main }
  local tip = scr.tooltip()
  Tip.PlaceBeside(tip, row, main); assertEqual((scr.rectOf(tip)), 702, "a frame")
  Tip.PlaceBeside(tip, row, { main, panel }); assertEqual((scr.rectOf(tip)), 902, "a list")
  Tip.PlaceBeside(tip, row, { main = main, panels = { panel } }); assertEqual((scr.rectOf(tip)), 902, "main + panels")
  Tip.PlaceBeside(tip, row, function() return { main, panel } end); assertEqual((scr.rectOf(tip)), 902, "a function")
end)

test("GroupOf: a registered ancestor decides; else the outermost frame under UIParent", function(scr)
  local outer = scr.frame{ left = 400, bottom = 300, width = 300, height = 400 }
  local mid = scr.frame{ left = 400, bottom = 300, width = 300, height = 200, parent = outer }
  local leaf = scr.frame{ left = 400, bottom = 300, width = 30, height = 20, parent = mid }
  local frames, main, host = Tip.GroupOf(leaf)
  assertEqual(#frames, 1); assertTrue(main == outer and host == outer, "the outermost ancestor")
  local panel = scr.frame{ left = 700, bottom = 300, width = 200, height = 400 }
  local prow = scr.frame{ left = 700, bottom = 300, width = 20, height = 20, parent = panel }
  Tip.SetGroup(outer, { panel })
  frames, main, host = Tip.GroupOf(prow)
  assertEqual(#frames, 2); assertTrue(main == outer, "the companion's window")
  assertTrue(host == panel, "and the member the element sits in")
  Tip.SetGroup(outer, false)
  frames, main = Tip.GroupOf(prow)
  assertTrue(main == panel and #frames == 1, "SetGroup(window, false) removes the registration")
end)

test("unreadable geometry places nothing and answers nil", function(scr)
  local win, row = window(scr, 400, 300, 300, 400, 300)
  local unplaced = scr.frame{ parent = win }
  local tip = scr.tooltip()
  assertNil(Tip.PlaceBeside(tip, unplaced, win), "an unplaced element")
  assertNil(Tip.PlaceAttached(tip, unplaced, "top"))
  assertNil(Tip.PlaceLauncher(tip, unplaced))
  assertEqual(scr.ops(tip), "", "nothing written")
  local secret = setmetatable({}, { __index = function() return nil end })
  assertNil(Tip.PlaceBeside(tip, row, win, { rect = function() return secret, 1, 2, 3 end }),
    "a rect hook that answers a non-number")
  rawset(mocks.UIParent, "GetWidth", function() return mocks.UIParent end)
  assertNil(Tip.PlaceBeside(tip, row, win), "a screen it cannot read")
  assertEqual(scr.ops(tip), "")
end)

test("a secret geometry read counts as unreadable", function(scr)
  local win, row = window(scr, 400, 300, 300, 400, 300)
  local tip = scr.tooltip()
  local saved = rawget(mocks, "issecretvalue")
  mocks.issecretvalue = function(v) return v == 600 end
  local ok, side = pcall(Tip.PlaceBeside, tip, row, win)
  mocks.issecretvalue = saved
  assertTrue(ok, tostring(side))
  assertNil(side, "the row's top (600) is secret: no arithmetic on it")
  assertEqual(scr.ops(tip), "")
end)

test("attached: above the element, centered; below only when there is no room above", function(scr)
  -- red under: the zone rule, which put a "top" (or absent) zone's tooltip under the element
  local bar = scr.frame{ left = 900, bottom = 500, width = 100, height = 20 }
  local tip = scr.tooltip{ width = 200, height = 80 }
  assertEqual(Tip.PlaceAttached(tip, bar), "above")
  assertEqual(tip.__point.point, "BOTTOM"); assertTrue(tip.__point.rel == mocks.UIParent)
  local l, b, r = scr.rectOf(tip)
  assertEqual(b, 522); assertEqual((l + r) / 2, 950)
  assertEqual(Tip.PlaceAttached(tip, bar, "top"), "above", "a retired zone chooses nothing")
  assertEqual(Tip.PlaceAttached(tip, bar, "bottom"), "above")
  local high = scr.frame{ left = 900, bottom = 1020, width = 100, height = 20 }
  assertEqual(Tip.PlaceAttached(tip, high), "below", "no room above: flipped")
  local _, _, _, t = scr.rectOf(tip)
  assertEqual(t, 1018)
end)

test("attached: opts is the third argument (the zone slot is retired)", function(scr)
  -- red under: PlaceAttached(tip, element, zone, opts), which read a third-argument opts as a zone
  local bar = scr.frame{ left = 900, bottom = 500, width = 100, height = 20 }
  local tip = scr.tooltip{ width = 200, height = 80 }
  local hooked = 0
  local rect = function() hooked = hooked + 1; return 100, 300, 200, 320 end
  assertEqual(Tip.PlaceAttached(tip, bar, { rect = rect }), "above")
  assertTrue(hooked > 0, "opts.rect read")
  local l, b, r = scr.rectOf(tip)
  assertEqual(b, 322, "placed by the hook's rect"); assertEqual((l + r) / 2, 150)
  tip:__size(200, 80)
  assertEqual(Tip.Replace(tip), "above", "Replace re-runs it with the same opts")
  local _, b2 = scr.rectOf(tip)
  assertEqual(b2, 322)
end)

test("launcher: relative to the button, 2 off it, toward the screen's center", function(scr)
  local btn = scr.frame{ left = 1850, bottom = 1000, width = 32, height = 32 }
  local tip = scr.tooltip()
  assertEqual(Tip.PlaceLauncher(tip, btn), "TOPRIGHT")
  local p = tip.__point
  assertTrue(p.rel == btn, "relative to the button")
  assertEqual(p.relPoint, "BOTTOMRIGHT"); assertEqual(p.x, 0); assertEqual(p.y, -2)
end)

test("launcher: the button's own scale (the minimap's) is applied before the third is read", function(scr)
  -- own center x 1200 at 0.5 is 600 on screen: the left third, not the middle
  local btn = scr.frame{ left = 1184, bottom = 1500, width = 32, height = 32, scale = 0.5 }
  local tip = scr.tooltip{ scale = 0.5 }
  assertEqual(Tip.PlaceLauncher(tip, btn), "TOPLEFT")
  assertEqual(tip.__point.y, -4, "2 screen units in a 0.5 tooltip's own")
end)

test("Replace re-runs the last placement after the tooltip grew", function(scr)
  local win, row = window(scr, 1300, 300, 300, 400, 300)
  local tip = scr.tooltip{ width = 200, height = 90 }
  assertEqual(Tip.PlaceBeside(tip, row, win), "right")
  tip:__size(400, 90)
  assertEqual(Tip.Replace(tip), "left", "the wider tooltip no longer fits on the right")
  local _, _, r = scr.rectOf(tip)
  assertEqual(r, 1298)
  assertNil(Tip.Replace(scr.tooltip()), "nothing placed yet")
  local btn = scr.frame{ left = 100, bottom = 100, width = 32, height = 32 }
  Tip.PlaceLauncher(tip, btn)
  assertEqual(Tip.Replace(tip), "BOTTOMLEFT", "the launcher placer too")
end)
