-- tests/test_widgets_linechart.lua — LibKa0s-Widgets-1.0: `lib.LineChart`, the drawn half.
--
-- Built on kit revision 37's Line regions: every segment, grid rule and crosshair the chart makes is
-- a distinct recording Line on the chart frame (`__madeLines`), so these cases can count what a
-- render drew and prove a second render drew nothing new. Labels are FontStrings, which the base
-- kit still aliases to the frame (testkit/mock_base.lua's "Known divergence"); no case here reads a
-- label's text for that reason -- the text comes from formatY/formatX, and those are the host's.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse
local mocks = T.mocks
local W = T.widgets

local function newChart(opts)
  return W.LineChart(mocks.CreateFrame("Frame"), opts or {})
end

local function ramp(n, y0, step)
  local pts = {}
  for i = 1, n do pts[i] = { x = i * 100, y = y0 + (i - 1) * step } end
  return pts
end

local function shownLines(c)
  local n = 0
  for _, l in ipairs(c.__madeLines) do if l:IsShown() then n = n + 1 end end
  return n
end

local function yTicks(lo, hi)
  return (W.ChartMath.NiceTicks(lo, hi, W.LINE_CHART.Y_TICKS))
end

test("line chart: Render draws the axis, one grid rule per y tick and one line per segment", function()
  local c = newChart()
  c:SetData({ xMin = 100, xMax = 300, series = { { points = ramp(3, 0, 50) } } })
  c:Render(400, 200)
  -- axis 1 + grid #ticks(0..100) + 2 segments; the crosshair exists but is hidden
  assertEqual(shownLines(c), 1 + #yTicks(0, 100) + 2)
end)

test("line chart: a second Render of the same data creates no new Line objects", function()
  -- Review Focus 5
  local c = newChart()
  c:SetData({ xMin = 100, xMax = 2000, series = { { points = ramp(20, 0, 3) }, { points = ramp(20, 5, 1) } } })
  c:Render(400, 200)
  local made, shown = #c.__madeLines, shownLines(c)
  c:Render(400, 200)
  assertEqual(#c.__madeLines, made, "the pool hands the same Lines back")
  assertEqual(shownLines(c), shown)
end)

test("line chart: a smaller render hides the leftovers instead of leaving them drawn", function()
  local c = newChart()
  c:SetData({ xMin = 100, xMax = 2000, series = { { points = ramp(20, 0, 3) } } })
  c:Render(400, 200)
  local before = shownLines(c)
  c:SetData({ xMin = 100, xMax = 300, series = { { points = ramp(3, 0, 3) } } })
  c:Render(400, 200)
  assertTrue(shownLines(c) < before, "segments the new data does not need are hidden")
end)

test("line chart: the plot never gets more than one point per 2px", function()
  -- Review Focus 1, through the widget
  local c = newChart()
  c:SetData({ xMin = 100, xMax = 100000, series = { { points = ramp(1000, 0, 1) } } })
  c:Render(208, 120)
  local _, _, pw = c:GetPlotRect()
  local budget = W.ChartMath.Budget(pw)
  assertEqual(shownLines(c), 1 + #yTicks(0, 999) + (budget - 1))
end)

test("line chart: opts.pxPerPoint sets the point budget per chart; the default is unchanged", function()
  local function draw(opts)
    local c = newChart(opts)
    c:SetData({ xMin = 100, xMax = 100000, series = { { points = ramp(1000, 0, 1) } } })
    c:Render(208, 120)
    local _, _, pw = c:GetPlotRect()
    return shownLines(c), pw
  end
  local base, pw = draw(nil)
  local explicit = draw({ pxPerPoint = 2 })
  local wide = draw({ pxPerPoint = 4 })
  assertEqual(explicit, base, "an explicit 2 is the default")
  assertEqual(wide - base, W.ChartMath.Budget(pw, 4) - W.ChartMath.Budget(pw), "segments follow the budget")
  assertTrue(wide < base, "a larger spacing draws fewer segments")
end)

test("line chart: a series maps its first point onto the plot's bottom-left corner", function()
  local c = newChart()
  c:SetData({ xMin = 100, xMax = 300, series = { { points = ramp(3, 0, 50), thickness = 3 } } })
  c:Render(400, 200)
  local left, bottom = c:GetPlotRect()
  local first = c.__madeLines[1 + 1 + #yTicks(0, 100) + 1]  -- crosshair, axis, grid, then the series
  local _, rel, x, y = first:GetStartPoint()
  assertTrue(rel == c, "anchored to the chart frame")
  assertEqual(x, left); assertEqual(y, bottom)
  assertEqual(first:GetThickness(), 3)
  assertEqual(c:XToPixel(300), left + select(3, c:GetPlotRect()))
end)

test("line chart: a dashed range draws dashes, an undashed series one line per segment", function()
  local solid, dashed = newChart(), newChart()
  local pts = { { x = 0, y = 0 }, { x = 100, y = 0 } }
  solid:SetData({ xMin = 0, xMax = 100, yMin = 0, yMax = 1, series = { { points = pts } } })
  dashed:SetData({ xMin = 0, xMax = 100, yMin = 0, yMax = 1, series = { { points = pts, dashFrom = 0, dashTo = 100 } } })
  solid:Render(400, 200); dashed:Render(400, 200)
  assertTrue(shownLines(dashed) > shownLines(solid) + 10, "a 340px dashed segment is many dashes")
end)

test("line chart: a marker inside the domain draws a dashed rule; outside it draws nothing", function()
  local inside, outside = newChart(), newChart()
  local base = { xMin = 0, xMax = 100, yMin = 0, yMax = 1, series = {} }
  inside:SetData({ xMin = 0, xMax = 100, yMin = 0, yMax = 1, series = {}, markers = { { x = 50 } } })
  outside:SetData({ xMin = 0, xMax = 100, yMin = 0, yMax = 1, series = {}, markers = { { x = 500 } } })
  local plain = newChart(); plain:SetData(base)
  inside:Render(400, 200); outside:Render(400, 200); plain:Render(400, 200)
  assertTrue(shownLines(inside) > shownLines(plain), "the marker drew")
  assertEqual(shownLines(outside), shownLines(plain), "an out-of-range marker draws nothing")
end)

test("line chart: HoverAtPixel snaps to the nearest x and calls onHover once per change", function()
  local calls = {}
  local c = newChart({ onHover = function(_, i, x) calls[#calls + 1] = { i, x } end })
  c:SetData({ xMin = 100, xMax = 300, series = { { points = ramp(3, 0, 1) } }, hoverXs = { 100, 200, 300 } })
  c:Render(400, 200)
  assertEqual(c:HoverAtPixel(c:XToPixel(190)), 2)
  c:HoverAtPixel(c:XToPixel(205))
  assertEqual(#calls, 1, "the same index again is not a new hover")
  assertEqual(calls[1][1], 2); assertEqual(calls[1][2], 200)
  assertTrue(c.__madeLines[1]:IsShown(), "the crosshair is up")
  c:ClearHover()
  assertEqual(#calls, 2); assertEqual(calls[2][1], nil)
  assertFalse(c.__madeLines[1]:IsShown(), "and down again")
  assertEqual(c:HoverIndex(), nil)
end)

test("line chart: OnLeave clears the hover the way ClearHover does", function()
  local last = "unset"
  local c = newChart({ onHover = function(_, i) last = i end })
  c:SetData({ xMin = 0, xMax = 10, series = {}, hoverXs = { 0, 10 } })
  c:Render(400, 200)
  c:HoverAtPixel(c:XToPixel(9))
  c:__fire("OnLeave")
  assertEqual(last, nil)
end)

test("line chart: Clear hides every line", function()
  local c = newChart()
  c:SetData({ xMin = 100, xMax = 300, series = { { points = ramp(3, 0, 50) } } })
  c:Render(400, 200)
  c:Clear()
  assertEqual(shownLines(c), 0)
end)

test("line chart: Render before SetData or at zero size draws nothing and does not raise", function()
  local c = newChart()
  c:Render(400, 200)
  assertEqual(shownLines(c), 0)
  c:SetData({ xMin = 100, xMax = 300, series = { { points = ramp(3, 0, 50) } } })
  c:Render(0, 0)
  assertEqual(shownLines(c), 0)
  assertEqual(c:GetPlotRect(), nil)
end)

test("line chart: a one-point series still draws a visible mark", function()
  local c = newChart()
  c:SetData({ xMin = 0, xMax = 100, series = { { points = { { x = 50, y = 5 } } } } })
  c:Render(400, 200)
  assertEqual(shownLines(c), 1 + #yTicks(0, 5) + 1)
end)
