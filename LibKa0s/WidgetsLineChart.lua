-- LibKa0s-Widgets-1.0 -- the line chart: one or more series of points drawn as Line regions over
-- a time axis, with auto-scaled y ticks, a dashed vertical marker, a dashed-range style for a part
-- of a series the host wants read as provisional, and a hover crosshair that reports the nearest x.
--
-- -- WHY IT IS A FILE OF ITS OWN AND NOT MORE OF Widgets.lua ------------------------------------
--
-- For the reason WidgetsDragHandle.lua gives: one file per widget keeps each under layout-1's
-- 1500-line cap, and a secondary file paired on the SHELL's minor cannot attach to a shell from
-- another vendored copy without saying so. It is not a major of its own: a new major would cost a
-- setup seam in every consumer, and only one draws a chart today.
--
-- -- WHY THE MATH IS PUBLISHED ------------------------------------------------------------------
--
-- Everything decided without a frame -- the tick ladder, the thinning, the time labels, the
-- nearest x, the dash cutting -- is on `lib.ChartMath`, so a library suite pins it with no geometry
-- stub and a host can line its own decorations (a bar strip under the plot) up with the same
-- numbers rather than restating them.
--
-- -- WHAT THE HOST STILL OWNS -------------------------------------------------------------------
--
-- Every string and color it passes, where the chart sits, when it is shown, what a hover means
-- (the widget reports an index; the host draws its own tooltip) and every unit conversion: the
-- widget plots the numbers it is handed.
--
-- Depends on LibStub and on the Widgets shell, and on no addon framework. Reads the client's
-- `date` and `time` for the time axis.

local lib = LibStub and LibStub("LibKa0s-Widgets-1.0", true)
if not lib then return end

local CHART_MINOR = 1
-- Paired on the SHELL's minor as well as this file's own, as WidgetsDragHandle.lua is: a chart that
-- attached to an older shell would publish `lib.LineChart` beside a `lib.MODULES` the shell owns,
-- and nothing would say the two came from different vendored copies.
if lib.__chartMinor and lib.__chartMinor >= CHART_MINOR
  and lib.__chartShellMinor == lib.MINOR then return end
lib.__chartMinor      = CHART_MINOR
lib.__chartShellMinor = lib.MINOR

lib.MODULES = lib.MODULES or {}
lib.MODULES.WidgetsLineChart = CHART_MINOR

local floor, ceil, max, min, abs, sqrt = math.floor, math.ceil, math.max, math.min, math.abs, math.sqrt
local log10 = math.log10
local DAY = 86400

--- The chart's published chrome. READ, never restated: a host that lines anything up with the plot
--- reads the paddings here (or asks `chart:GetPlotRect()`), so a later minor that moves them moves
--- the host too.
lib.LINE_CHART = {
  PAD_LEFT = 52, PAD_RIGHT = 8, PAD_TOP = 8, PAD_BOTTOM = 18,
  PX_PER_POINT = 2, DASH = 4, GAP = 3, Y_TICKS = 5, X_TICKS = 6, LABEL_GAP = 4,
  AXIS = { 0.45, 0.45, 0.5, 0.8 }, GRID = { 1, 1, 1, 0.07 }, CROSSHAIR = { 1, 1, 1, 0.35 },
  MARKER = { 0.8, 0.8, 0.8, 0.6 }, LINE = { 0.4, 0.6, 0.95, 1 },
}
local LC = lib.LINE_CHART

local Math = {}
lib.ChartMath = Math

-- -- y ticks: the 1 / 2 / 2.5 / 5 ladder -------------------------------------------------------

local function niceStep(span, maxTicks)
  local raw = span / max(1, maxTicks)
  local mag = 10 ^ floor(log10(raw))
  local norm = raw / mag
  if norm <= 1 then return mag end
  if norm <= 2 then return 2 * mag end
  if norm <= 2.5 then return 2.5 * mag end
  if norm <= 5 then return 5 * mag end
  return 10 * mag
end

-- A flat series still needs a span to divide by. A positive flat line is drawn from zero, a
-- negative one up to zero, and an all-zero one over 0..1, so the line sits on a real axis rather
-- than on a degenerate one.
local function widenFlat(lo, hi)
  if hi ~= lo then return lo, hi end
  if lo > 0 then return 0, hi end
  if lo < 0 then return lo, 0 end
  return 0, 1
end

function Math.NiceTicks(lo, hi, maxTicks, integer)
  lo, hi = lo or 0, hi or 0
  if hi < lo then lo, hi = hi, lo end
  lo, hi = widenFlat(lo, hi)
  local step = niceStep(hi - lo, maxTicks or LC.Y_TICKS)
  if integer and step < 1 then step = 1 end
  local niceLo, niceHi = floor(lo / step) * step, ceil(hi / step) * step
  local ticks, n = {}, floor((niceHi - niceLo) / step + 0.5)
  for k = 0, n do ticks[k + 1] = niceLo + k * step end
  return ticks, niceLo, niceHi, step
end

-- -- thinning: Largest-Triangle-Three-Buckets ----------------------------------------------------
--
-- A balance line is mostly flat with steps and spikes, and a spike is the thing a player is looking
-- for. Averaging or taking every Nth point erases it; LTTB keeps, per bucket, the point that spans
-- the largest triangle with its neighbors, so a one-point spike survives (pinned).

function Math.Budget(plotWidth)
  return max(3, floor((plotWidth or 0) / LC.PX_PER_POINT))
end

local function bucketAverage(points, from, to)
  local ax, ay, n = 0, 0, 0
  for j = from, to - 1 do
    ax, ay, n = ax + points[j].x, ay + points[j].y, n + 1
  end
  if n == 0 then
    local p = points[#points]
    return p.x, p.y
  end
  return ax / n, ay / n
end

local function largestTriangle(points, pa, from, to, ax, ay)
  local best, bestArea = from, -1
  for j = from, to - 1 do
    local p = points[j]
    local area = abs((pa.x - ax) * (p.y - pa.y) - (pa.x - p.x) * (ay - pa.y))
    if area > bestArea then best, bestArea = j, area end
  end
  return best
end

function Math.Downsample(points, maxPoints)
  local n = #points
  if maxPoints >= n or maxPoints < 3 then return points end
  local out, every, a = { points[1] }, (n - 2) / (maxPoints - 2), 1
  for i = 0, maxPoints - 3 do
    local ax, ay = bucketAverage(points, floor((i + 1) * every) + 2, min(floor((i + 2) * every) + 2, n + 1))
    local pick = largestTriangle(points, points[a], floor(i * every) + 2, floor((i + 1) * every) + 2, ax, ay)
    out[#out + 1] = points[pick]
    a = pick
  end
  out[#out + 1] = points[n]
  return out
end

-- -- x ticks: a time ladder that lands on the player's midnight ----------------------------------

local TIME_STEPS = { 3600, 10800, 21600, 43200, DAY, 2 * DAY, 7 * DAY, 14 * DAY, 30 * DAY,
  91 * DAY, 182 * DAY, 365 * DAY }

local function midnight(ts)
  local t = date("*t", ts)
  return time({ year = t.year, month = t.month, day = t.day, hour = 0, min = 0, sec = 0 })
end

local function pickStep(span, maxTicks)
  for _, s in ipairs(TIME_STEPS) do
    if span / s <= maxTicks then return s end
  end
  return TIME_STEPS[#TIME_STEPS]
end

-- Day steps re-anchor on midnight after every step, with a two-hour nudge, so a 23- or 25-hour
-- day (a daylight-saving change) cannot walk the labels off midnight.
local function nextTick(x, step)
  if step >= DAY then return midnight(x + step + 7200) end
  return x + step
end

local function firstTick(xMin, step)
  local m = midnight(xMin)
  if step >= DAY then
    if m < xMin then return midnight(m + DAY + 7200) end
    return m
  end
  return m + ceil((xMin - m) / step) * step
end

function Math.TimeTicks(xMin, xMax, maxTicks)
  maxTicks = maxTicks or LC.X_TICKS
  if not (xMin and xMax) or xMax <= xMin then return {}, nil end
  local step = pickStep(xMax - xMin, maxTicks)
  local ticks, x = {}, firstTick(xMin, step)
  while x <= xMax and #ticks <= maxTicks do
    ticks[#ticks + 1] = x
    x = nextTick(x, step)
  end
  return ticks, step
end

-- -- hover and dashes ----------------------------------------------------------------------------

function Math.NearestIndex(xs, x)
  local n = #xs
  if n == 0 then return nil end
  if x <= xs[1] then return 1 end
  if x >= xs[n] then return n end
  local lo, hi = 1, n
  while hi - lo > 1 do
    local mid = floor((lo + hi) / 2)
    if xs[mid] <= x then lo = mid else hi = mid end
  end
  if x - xs[lo] <= xs[hi] - x then return lo end
  return hi
end

function Math.Dashes(x1, y1, x2, y2, dash, gap)
  dash, gap = dash or LC.DASH, gap or LC.GAP
  local dx, dy = x2 - x1, y2 - y1
  local len = sqrt(dx * dx + dy * dy)
  local out = {}
  if len <= 0 then return out end
  local ux, uy, s = dx / len, dy / len, 0
  while s < len do
    local e = min(s + dash, len)
    out[#out + 1] = { x1 + ux * s, y1 + uy * s, x1 + ux * e, y1 + uy * e }
    s = s + dash + gap
  end
  return out
end
