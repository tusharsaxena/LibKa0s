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
  assertEqual(W.MODULES.WidgetsLineChart, 1)
  assertEqual(W.__chartMinor, 1)
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
