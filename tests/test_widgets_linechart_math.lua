-- tests/test_widgets_linechart_math.lua — LibKa0s-Widgets-1.0: the line chart's pure math.
--
-- Everything the chart decides without a frame -- where the y ticks go, how a long series is
-- thinned to the pixels it has, where the time labels land, which x a cursor is nearest, how a
-- dashed segment is cut -- lives in `lib.ChartMath` so it is pinned here headless, with no geometry
-- stub at all. tests/test_widgets_linechart.lua pins what the widget DRAWS from it.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local mocks = T.mocks
local W = T.widgets
local function M() return W.ChartMath end

test("chart math: the file attaches to the Widgets shell and records its minor", function()
  assertEqual(W.MODULES.WidgetsLineChart, 3)
  assertEqual(W.__chartMinor, 3)
  assertEqual(W.__chartShellMinor, W.MINOR, "paired on the shell's minor, as WidgetsDragHandle is")
end)

test("chart math: NiceTicks picks a 1-2-2.5-5 step and covers the data", function()
  local ticks, lo, hi, step = M().NiceTicks(0, 97, 5)
  assertEqual(step, 20); assertEqual(lo, 0); assertEqual(hi, 100)
  assertEqual(#ticks, 6); assertEqual(ticks[1], 0); assertEqual(ticks[6], 100)
  ticks, lo, hi, step = M().NiceTicks(13, 47, 5)
  assertEqual(step, 10); assertEqual(lo, 10); assertEqual(hi, 50); assertEqual(#ticks, 5)
end)

test("chart math: NiceTicks widens a flat or empty range instead of dividing by zero", function()
  local ticks, lo, hi = M().NiceTicks(5, 5, 5)
  assertEqual(lo, 0); assertEqual(hi, 5); assertEqual(#ticks, 6)
  ticks, lo, hi = M().NiceTicks(0, 0, 5, true)
  assertEqual(lo, 0); assertEqual(hi, 1); assertEqual(#ticks, 2)
  ticks, lo, hi = M().NiceTicks(nil, nil, 5)
  assertEqual(lo, 0); assertTrue(hi > 0 and #ticks >= 2)
end)

test("chart math: NiceTicks with integer=true never steps below 1", function()
  local _, _, _, step = M().NiceTicks(0, 2, 5)
  assertEqual(step, 0.5)
  _, _, _, step = M().NiceTicks(0, 2, 5, true)
  assertEqual(step, 1)
end)

test("chart math: NiceTicks handles a range that crosses zero", function()
  local _, lo, hi, step = M().NiceTicks(-30, 70, 5)
  assertEqual(step, 20); assertEqual(lo, -40); assertEqual(hi, 80)
end)

test("chart math: Downsample keeps at most one point per 2px and both endpoints", function()
  -- Review Focus 1
  local pts = {}
  for i = 1, 1000 do pts[i] = { x = i, y = (i % 7) * 10 } end
  local n = M().Budget(200)
  assertEqual(n, 100, "200px holds 100 points at 2px each")
  local out = M().Downsample(pts, n)
  assertEqual(#out, 100)
  assertTrue(out[1] == pts[1] and out[#out] == pts[1000], "first and last points survive")
  for i = 2, #out do assertTrue(out[i].x > out[i - 1].x, "x stays strictly increasing") end
end)

test("chart math: Downsample hands a series that already fits back untouched", function()
  local pts = { { x = 1, y = 1 }, { x = 2, y = 5 } }
  assertTrue(M().Downsample(pts, 100) == pts, "same table, no copy")
end)

test("chart math: Downsample keeps a one-point spike", function()
  local pts = {}
  for i = 1, 500 do pts[i] = { x = i, y = 0 } end
  pts[250].y = 1000
  local peak = 0
  for _, p in ipairs(M().Downsample(pts, 50)) do if p.y > peak then peak = p.y end end
  assertEqual(peak, 1000, "a balance spike must not be averaged away")
end)

test("chart math: Budget never answers fewer than three points", function()
  assertEqual(M().Budget(0), 3); assertEqual(M().Budget(3), 3)
end)

test("chart math: Budget takes a per-chart spacing and falls to the default for a bad one", function()
  assertEqual(M().Budget(200, 4), 50)
  assertEqual(M().Budget(200, 2), 100)
  assertEqual(M().Budget(200), 100)
  assertEqual(M().Budget(200, 0), 100, "zero spacing falls to the default")
  assertEqual(M().Budget(200, -3), 100)
  assertEqual(M().Budget(200, "x"), 100)
  assertEqual(M().Budget(8, 4), 3, "still never fewer than three")
end)

test("chart math: a larger spacing draws fewer points yet keeps the series' global min and max", function()
  local pts = {}
  for i = 1, 2000 do pts[i] = { x = i, y = 500 + ((i * 37) % 41) } end  -- bounded noise 500..540
  pts[613].y = 9000   -- the global max, mid-bucket
  pts[1402].y = -7000 -- the global min
  local wide = M().Downsample(pts, M().Budget(400, 2))
  local wider = M().Downsample(pts, M().Budget(400, 5))
  assertTrue(#wider < #wide, "a larger spacing keeps fewer points")
  for _, out in ipairs({ wide, wider }) do
    local lo, hi = math.huge, -math.huge
    for _, p in ipairs(out) do
      if p.y < lo then lo = p.y end
      if p.y > hi then hi = p.y end
    end
    assertEqual(hi, 9000, "the global max survives thinning")
    assertEqual(lo, -7000, "the global min survives thinning")
    assertTrue(out[1] == pts[1] and out[#out] == pts[2000], "both endpoints survive")
  end
end)

test("chart math: TimeTicks lands day steps on local midnight", function()
  local x0 = mocks.time({ year = 2026, month = 10, day = 1, hour = 0 })
  local ticks, step = M().TimeTicks(x0, x0 + 30 * 86400, 6)
  assertEqual(step, 7 * 86400)
  assertEqual(#ticks, 5)
  for _, t in ipairs(ticks) do assertEqual(mocks.date("*t", t).hour, 0) end
end)

test("chart math: TimeTicks uses hour steps inside one day", function()
  local x0 = mocks.time({ year = 2026, month = 10, day = 1, hour = 0 })
  local ticks, step = M().TimeTicks(x0, x0 + 86400, 6)
  assertEqual(step, 6 * 3600)
  assertEqual(#ticks, 5)
  assertEqual(mocks.date("*t", ticks[2]).hour, 6)
end)

test("chart math: TimeTicks answers nothing for an empty span", function()
  local ticks, step = M().TimeTicks(100, 100, 6)
  assertEqual(#ticks, 0); assertEqual(step, nil)
end)

test("chart math: NearestIndex snaps to the closest x and clamps at the ends", function()
  local xs = { 0, 10, 20, 30 }
  assertEqual(M().NearestIndex(xs, -5), 1)
  assertEqual(M().NearestIndex(xs, 14), 2)
  assertEqual(M().NearestIndex(xs, 16), 3)
  assertEqual(M().NearestIndex(xs, 99), 4)
  assertEqual(M().NearestIndex({}, 3), nil)
end)

test("chart math: Dashes cuts a segment into dash-gap pieces along its length", function()
  local d = M().Dashes(0, 0, 20, 0, 4, 3)
  assertEqual(#d, 3)
  assertEqual(d[1][1], 0); assertEqual(d[1][3], 4)
  assertEqual(d[3][1], 14); assertEqual(d[3][3], 18)
  local v = M().Dashes(0, 0, 0, 10, 4, 3)
  assertEqual(#v, 2)
  assertEqual(v[2][4], 10, "the last dash is clipped at the segment's end")
  assertEqual(#M().Dashes(5, 5, 5, 5, 4, 3), 0, "a zero-length segment has no dashes")
end)

-- -- ClipSegment (minor 3): Liang-Barsky against the plot rectangle ------------------------------

local function clip(...) return { M().ClipSegment(...) } end
-- To within float noise: a cut point is computed (x1 + t * dx), so it can land 1e-14 off the edge.
local function sameSeg(got, want, msg)
  assertEqual(#got, 4, msg)
  for k = 1, 4 do
    assertTrue(math.abs(got[k] - want[k]) < 1e-9, msg .. ": component " .. k .. " is " .. tostring(got[k])
      .. ", expected " .. tostring(want[k]))
  end
end

test("chart math: ClipSegment answers a segment inside the rectangle unchanged", function()
  -- red under: ClipSegment missing (minor 2 has no such member)
  local x1, y1, x2, y2 = M().ClipSegment(0.1, 0.2, 9.7, 9.3, 0, 0, 10, 10)
  assertTrue(x1 == 0.1 and y1 == 0.2 and x2 == 9.7 and y2 == 9.3, "inside comes back bit-for-bit")
  sameSeg(clip(0, 0, 10, 10, 0, 0, 10, 10), { 0, 0, 10, 10 }, "corner to corner, on the edges")
end)

test("chart math: ClipSegment answers nil for a segment wholly outside", function()
  -- red under: return the segment unclipped when it misses the rectangle
  assertEqual(M().ClipSegment(11, 0, 20, 5, 0, 0, 10, 10), nil, "right of it")
  assertEqual(M().ClipSegment(-5, 12, 15, 30, 0, 0, 10, 10), nil, "above it")
  assertEqual(M().ClipSegment(-5, 4, 4, -5, 0, 0, 10, 10), nil, "past the bottom-left corner")
end)

test("chart math: ClipSegment cuts a segment at each edge it crosses, keeping its direction", function()
  -- red under: skip any edge in the Liang-Barsky loop, or swap t0 and t1 on the way out
  sameSeg(clip(-5, 5, 5, 5, 0, 0, 10, 10), { 0, 5, 5, 5 }, "left edge")
  sameSeg(clip(5, 5, 15, 5, 0, 0, 10, 10), { 5, 5, 10, 5 }, "right edge")
  sameSeg(clip(5, -5, 5, 5, 0, 0, 10, 10), { 5, 0, 5, 5 }, "bottom edge")
  sameSeg(clip(5, 5, 5, 15, 0, 0, 10, 10), { 5, 5, 5, 10 }, "top edge")
  sameSeg(clip(15, 5, 5, 5, 0, 0, 10, 10), { 10, 5, 5, 5 }, "right to left keeps its direction")
  sameSeg(clip(-10, -10, 20, 20, 0, 0, 10, 10), { 0, 0, 10, 10 }, "through two corners")
end)

test("chart math: ClipSegment handles vertical and horizontal segments on either side", function()
  -- red under: divide by a zero dx or dy instead of testing the parallel edge
  assertEqual(M().ClipSegment(-1, 0, -1, 10, 0, 0, 10, 10), nil, "vertical, left of it")
  assertEqual(M().ClipSegment(0, 11, 10, 11, 0, 0, 10, 10), nil, "horizontal, above it")
  sameSeg(clip(3, -100, 3, 1e6, 0, 0, 10, 10), { 3, 0, 3, 10 }, "vertical through it")
  sameSeg(clip(-100, 7, 100, 7, 0, 0, 10, 10), { 0, 7, 10, 7 }, "horizontal through it")
end)

test("chart math: ClipSegment keeps a degenerate point inside and drops one outside", function()
  -- red under: treat a zero-length segment as always outside, or always inside
  sameSeg(clip(3, 3, 3, 3, 0, 0, 10, 10), { 3, 3, 3, 3 }, "a point inside")
  assertEqual(M().ClipSegment(12, 3, 12, 3, 0, 0, 10, 10), nil, "a point outside")
end)
