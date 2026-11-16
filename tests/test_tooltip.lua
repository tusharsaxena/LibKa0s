-- tests/test_tooltip.lua — LibKa0s-Tooltip-1.0's pure solvers (LibKa0s#92, LK-92A): the body rule
-- (`__solveBeside`), the chrome rule (`__solveAttached`) and the launcher rule (`__solveLauncher`),
-- each as a table of screen layouts and the side and point WowAddonStandards standalone-windows,
-- *Tooltip placement*, puts the tooltip at. Numbers in, numbers out: no frame is touched here. The
-- placers that read frames and apply these answers are tests/test_tooltip_place.lua's.
--
-- Every figure is in screen units on a 1920 x 1080 screen, with the gap the major publishes.

local T = _G.LK_TEST
local test, assertEqual, assertNil, assertTrue = T.test, T.assertEqual, T.assertNil, T.assertTrue
local mocks = T.mocks

local Tip = mocks.LibStub("LibKa0s-Tooltip-1.0")
local SW, SH, GAP = 1920, 1080, 2

test("tooltip: the major registers minor 1 and publishes TIP_GAP = 2", function()
  assertEqual(Tip.MINOR, 1)
  assertEqual(Tip.MODULES.Tooltip, 1)
  assertEqual(Tip.TIP_GAP, 2, "standalone-windows' *Terms*: the gap is 2 px under every skin")
end)

-- ── the body rule ────────────────────────────────────────────────────────────────────────────

-- { name, gl, gr, elemTop, tipW, tipH, prefer, side, point, x, y }
local BESIDE = {
  { "right fits",                         400, 800, 700, 300, 100, nil,    "right", "TOPLEFT",  802, 700 },
  { "right fits exactly",                 400, 1618, 700, 300, 100, nil,   "right", "TOPLEFT",  1620, 700 },
  { "right misses by one, left fits",     400, 1619, 700, 300, 100, nil,   "left",  "TOPRIGHT", 398, 700 },
  { "left preferred and fits",            400, 800, 700, 300, 100, "left", "left",  "TOPRIGHT", 398, 700 },
  { "left preferred, misses: right",      200, 800, 700, 300, 100, "left", "right", "TOPLEFT",  802, 700 },
  { "left fits exactly",                  302, 1800, 700, 300, 100, nil,   "left",  "TOPRIGHT", 300, 700 },
  { "bottom clamp: slides up to fit",     400, 800, 60, 300, 100, nil,     "right", "TOPLEFT",  802, 100 },
  { "top clamp: slides down to the top",  400, 800, 1200, 300, 100, nil,   "right", "TOPLEFT",  802, 1080 },
  { "taller than the screen: top kept",   400, 800, 500, 300, 1500, nil,   "right", "TOPLEFT",  802, 1080 },
}

for _, c in ipairs(BESIDE) do
  test("tooltip beside: " .. c[1], function()
    local side, point, x, y = Tip.__solveBeside(c[2], c[3], c[4], c[5], c[6], SW, SH, GAP, c[7])
    assertEqual(side, c[8], "side")
    assertEqual(point, c[9], "point")
    assertEqual(x, c[10], "x: the group's outer edge, the gap outside it")
    assertEqual(y, c[11], "y: level with the element's top, clamped")
  end)
end

test("tooltip beside: neither side fits answers nil, the fallback's cue", function()
  -- red under: a solver that put the tooltip on the right regardless and covered the group
  assertNil(Tip.__solveBeside(100, 1800, 700, 300, 100, SW, SH, GAP, nil))
  assertNil(Tip.__solveBeside(100, 1800, 700, 300, 100, SW, SH, GAP, "left"))
end)

test("tooltip beside: the tooltip never covers the group on either side", function()
  for _, c in ipairs(BESIDE) do
    local side, _, x = Tip.__solveBeside(c[2], c[3], c[4], c[5], c[6], SW, SH, GAP, c[7])
    if side == "right" then
      assertTrue(x >= c[3] + GAP, c[1] .. ": left edge outside the group's right")
      assertTrue(x + c[5] <= SW, c[1] .. ": and on screen")
    else
      assertTrue(x <= c[2] - GAP, c[1] .. ": right edge outside the group's left")
      assertTrue(x - c[5] >= 0, c[1] .. ": and on screen")
    end
  end
end)

-- ── the chrome rule ──────────────────────────────────────────────────────────────────────────

-- One rule for every attached tooltip (smoke round 1, ruling 2, SR-L1): ABOVE the element, centered,
-- the gap off it, because the pointer hangs down from its hotspot and above is the side it never
-- covers; BELOW only when there is no room above. The tenth argument, the zone that once chose the
-- side ("top" below, "bottom" above), is retired: a caller still passing one moves nothing.
-- { name, el, eb, er, et, tipW, tipH, retired zone, side, point, x, y }
local ATTACHED = {
  { "fits above: above, centered",          900, 500, 1000, 520, 200, 80, nil,      "above", "BOTTOM", 950, 522 },
  { "a retired \"top\" chooses nothing",     900, 500, 1000, 520, 200, 80, "top",    "above", "BOTTOM", 950, 522 },
  { "a retired \"bottom\" chooses nothing",  900, 500, 1000, 520, 200, 80, "bottom", "above", "BOTTOM", 950, 522 },
  { "at the screen's bottom: still above",  900, 40, 1000, 60, 200, 80, nil,        "above", "BOTTOM", 950, 62 },
  { "fits above exactly",                   900, 980, 1000, 998, 200, 80, nil,      "above", "BOTTOM", 950, 1000 },
  { "no room above: flips below",           900, 1020, 1000, 1040, 200, 80, nil,    "below", "TOP",    950, 1018 },
  { "misses above by one: flips below",     900, 980, 1000, 999, 200, 80, "top",    "below", "TOP",    950, 978 },
  { "x clamp at the left edge",             0, 500, 40, 520, 200, 80, nil,          "above", "BOTTOM", 100, 522 },
  { "x clamp at the right edge",            1880, 500, 1920, 520, 200, 80, nil,     "above", "BOTTOM", 1820, 522 },
  { "x clamp after the flip",               1880, 1020, 1920, 1040, 200, 80, nil,   "below", "TOP",    1820, 1018 },
  { "no room either side: above",           900, 40, 1000, 1060, 200, 80, nil,      "above", "BOTTOM", 950, 1062 },
  { "no room either side, retired zone",    900, 40, 1000, 1060, 200, 80, "top",    "above", "BOTTOM", 950, 1062 },
}

for _, c in ipairs(ATTACHED) do
  test("tooltip attached: " .. c[1], function()
    -- red under: the zone rule (a "top" or absent zone below the element, a "bottom" one above)
    local side, point, x, y = Tip.__solveAttached(c[2], c[3], c[4], c[5], c[6], c[7], SW, SH, GAP, c[8])
    assertEqual(side, c[9], "side")
    assertEqual(point, c[10], "point")
    assertEqual(x, c[11], "x: the tooltip's center on the element's, clamped on screen")
    assertEqual(y, c[12], "y: the gap off the element")
  end)
end

test("tooltip attached: a tooltip wider than the screen keeps its left edge on screen", function()
  local _, _, x = Tip.__solveAttached(900, 500, 1000, 520, 2000, 80, SW, SH, GAP)
  assertEqual(x - 1000, 0, "its left edge at 0")
end)

-- ── the launcher rule ────────────────────────────────────────────────────────────────────────

-- A 32 unit button centered at (cx, cy): { name, cx, cy, point, relPoint, dy }
local LAUNCHER = {
  { "upper right",  1800, 1000, "TOPRIGHT",    "BOTTOMRIGHT", -2 },
  { "upper middle", 960,  1000, "TOP",         "BOTTOM",      -2 },
  { "upper left",   100,  1000, "TOPLEFT",     "BOTTOMLEFT",  -2 },
  { "lower right",  1800, 80,   "BOTTOMRIGHT", "TOPRIGHT",    2 },
  { "lower middle", 960,  80,   "BOTTOM",      "TOP",         2 },
  { "lower left",   100,  80,   "BOTTOMLEFT",  "TOPLEFT",     2 },
}

for _, c in ipairs(LAUNCHER) do
  test("tooltip launcher: " .. c[1] .. " opens toward the center", function()
    local point, rel, dx, dy = Tip.__solveLauncher(c[2] - 16, c[3] - 16, c[2] + 16, c[3] + 16, SW, SH, GAP)
    assertEqual(point, c[4], "point")
    assertEqual(rel, c[5], "relative point")
    assertEqual(dx, 0, "no sideways offset")
    assertEqual(dy, c[6], "the gap, away from the button")
  end)
end

test("tooltip launcher: the thirds and the half are read from the button's center", function()
  -- just inside each boundary: the left third ends at 640, the right third starts past 1280
  assertEqual((Tip.__solveLauncher(623, 600, 639, 616, SW, SH, GAP)), "TOPLEFT")
  assertEqual((Tip.__solveLauncher(633, 600, 649, 616, SW, SH, GAP)), "TOP")
  assertEqual((Tip.__solveLauncher(1273, 600, 1289, 616, SW, SH, GAP)), "TOPRIGHT")
  assertEqual((Tip.__solveLauncher(900, 525, 916, 541, SW, SH, GAP)), "BOTTOM", "center 533: lower half")
  assertEqual((Tip.__solveLauncher(900, 540, 916, 556, SW, SH, GAP)), "TOP", "center 548: upper half")
end)
