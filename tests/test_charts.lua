-- tests/test_charts.lua — LibKa0s-Charts-1.0: the load, the context's plumbing and the pure helpers.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil, assertError =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil, T.assertError
local F = dofile("tests/fixture_charts.lua")
local Loader = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local Charts = T.charts

test("charts: the major loads and reports its two files", function()
  assertEqual(Charts.MAJOR, "LibKa0s-Charts-1.0")
  assertEqual(Charts.MODULES.Charts, Charts.MINOR)
  assertEqual(Charts.MODULES.ChartsRender, Charts.__renderMinor)
  assertEqual(Charts.__renderShellMinor, Charts.MINOR, "paired on the live shell")
end)

test("charts: no Core means no major, and ChartsRender loads to nothing without the shell", function()
  local m = buildMocks()
  Loader.load("LibKa0s/Charts.lua", nil, m)
  Loader.load("LibKa0s/ChartsRender.lua", nil, m)
  assertNil(m.LibStub("LibKa0s-Charts-1.0", true))
end)

test("charts: New needs a pool, and takes LibKa0s-Pool-1.0's when the host names none", function()
  local m, C = F.env({ noPool = true })
  assertError(function() C:New(F.content(m), {}) end, "host.pool")
  local m2, C2 = F.env()
  local ctx = C2:New(F.content(m2))
  assertEqual(ctx.poolApi, m2.LibStub("LibKa0s-Pool-1.0"))
end)

test("charts: a host's own pool API is the one used", function()
  local m, C = F.env()
  local calls = { new = 0, rel = 0 }
  local api = {
    New = function() calls.new = calls.new + 1; return {} end,
    Acquire = function(_, factory) return factory() end,
    ReleaseAll = function() calls.rel = calls.rel + 1 end,
  }
  local ctx = C:New(F.content(m), { pool = api })
  local a = ctx:Pool("bars")
  assertEqual(ctx:Pool("bars"), a, "one pool per name")
  ctx:Pool("other")
  ctx:ReleaseAll()
  assertEqual(calls.new, 2)
  assertEqual(calls.rel, 2, "every pool made here")
end)

test("charts: truncate counts glyphs, stays inside the cap, and reports the cut", function()
  assertEqual(Charts.truncate("short", 16), "short")
  assertFalse(select(2, Charts.truncate("short", 16)))
  local s, cut = Charts.truncate("abcdefgh", 5)
  assertEqual(s, "ab...")
  assertTrue(cut)
  -- Five two-byte glyphs: a byte-based cut would land inside the second.
  local five = string.rep("\195\162", 5)
  assertEqual(Charts.truncate(five, 4), "\195\162...")
  assertEqual(Charts.truncate(five, 5), five, "fits by glyphs")
  assertEqual(Charts.truncate(nil, 4), "")
  assertEqual(Charts.truncate(1234567, 5), "12...", "a number reads as its string")
  assertEqual(Charts.truncate("abc", 0), "...", "a cap of nothing raises nothing")
end)

test("charts: tipText states the value beside the full label", function()
  assertEqual(Charts.tipText("Name", "12"), "Name:  12")
  assertEqual(Charts.tipText("Name", 12), "Name:  12", "a numeric value")
  assertEqual(Charts.tipText("Name", ""), "Name")
  assertEqual(Charts.tipText("Name"), "Name")
  assertEqual(Charts.tipText(nil, "12"), "12")
end)

test("charts: fitFontSize shrinks only an overflow, and never under the floor", function()
  assertEqual(Charts.fitFontSize(50, 100, 24, 11), 24)
  assertEqual(Charts.fitFontSize(200, 100, 24, 11), 12)
  assertEqual(Charts.fitFontSize(2000, 100, 24, 11), 11)
  assertEqual(Charts.fitFontSize(nil, 100, 24, 11), 24)
  assertEqual(Charts.fitFontSize(0, 100, 24, 11), 24)
end)

test("charts: StackSegments keeps the top, folds the rest to OTHER, in the global order", function()
  local kept, total = Charts.StackSegments({ a = 1, b = 5, c = 3, d = 2, zero = 0 }, { "d", "c", "b", "a" }, 3)
  assertEqual(total, 11, "the total counts the folded ones")
  assertEqual(#kept, 3)
  assertEqual(kept[1].key, "c", "c comes before b in the order")
  assertEqual(kept[2].key, "b")
  assertEqual(kept[3].key, Charts.OTHER)
  assertEqual(kept[3].mag, 3, "a and d folded")
end)

test("charts: StackSegments with room folds nothing and sorts unlisted keys last, stably", function()
  local kept = Charts.StackSegments({ x = 1, y = 1, a = 1 }, { "a" })
  assertEqual(#kept, 3)
  assertEqual(kept[1].key, "a")
  assertEqual(kept[2].key, "x")
  assertEqual(kept[3].key, "y")
  assertEqual(#Charts.StackSegments({}, {}), 0)
end)

test("charts: RangeScale spans the rows, opens when they meet, and answers an empty set", function()
  local lo, hi = Charts.RangeScale({ { lo = 5, hi = 9 }, { lo = 2, hi = 7 } })
  assertEqual(lo, 2)
  assertEqual(hi, 9)
  lo, hi = Charts.RangeScale({ { lo = 100, hi = 100 } })
  assertEqual(lo, 95)
  assertEqual(hi, 105)
  lo, hi = Charts.RangeScale({ { lo = 0, hi = 0 } })
  assertEqual(lo, -1)
  assertEqual(hi, 1)
  lo, hi = Charts.RangeScale({})
  assertEqual(lo, 0)
  assertEqual(hi, 1)
end)

test("charts: StripSlots stops widening, and the column stays inside its slot", function()
  local slot, bar = Charts.StripSlots(1000, 2)
  assertEqual(slot, Charts.K.STRIP_SLOT_MAX)
  assertEqual(bar, Charts.K.STRIP_BAR_MAX)
  slot, bar = Charts.StripSlots(100, 100)
  assertEqual(slot, 1)
  assertEqual(bar, 2, "never under two pixels")
  slot = Charts.StripSlots(100, 0)
  assertEqual(slot, Charts.K.STRIP_SLOT_MAX, "no buckets divides by nothing")
end)

test("charts: StripLabels never lets two collide, and the larger block wins", function()
  -- Slots 10 wide: a one-column label at 1, then a ten-column block at 2. They sit 10 apart.
  local buckets = { { label = "a" } }
  buckets[2] = { label = "b" }
  for i = 3, 11 do buckets[i] = {} end
  local shown = Charts.StripLabels(buckets, 10, 500)
  assertNil(shown[1], "the one-column label drops")
  assertTrue(shown[2] ~= nil, "the block's stays")
end)

test("charts: StripLabels moves an edge label in, and ties go to the earlier one", function()
  local shown = Charts.StripLabels({ { label = "a" }, { label = "b" } }, 10, 500)
  assertTrue(shown[1] ~= nil, "the earlier label")
  assertEqual(shown[1], 20 - 5, "half the pitch from the edge, off a center of 5")
  assertNil(shown[2])
end)

test("charts: paletteColor cycles, paletteMap keeps a key's color by position", function()
  local m, C = F.env()
  local ctx = C:New(F.content(m), { palette = { { 1, 0, 0 }, { 0, 1, 0 } } })
  assertEqual(ctx:paletteColor(1)[1], 1)
  assertEqual(ctx:paletteColor(3)[1], 1, "wraps")
  local map = ctx:paletteMap({ "x", "y" })
  assertEqual(map.y[2], 1)
  assertEqual(next(ctx:paletteMap(nil)), nil)
end)

test("charts: a palette function is read at every draw, and a bad answer takes the default", function()
  local m, C = F.env()
  local list = { { 1, 0, 0 } }
  local ctx = C:New(F.content(m), { palette = function() return list end })
  assertEqual(ctx:paletteColor(1)[1], 1)
  list = { { 0, 0, 1 } }
  assertEqual(ctx:paletteColor(1)[3], 1, "the live list")
  list = {}
  assertEqual(ctx:paletteColor(1)[1], 0.90, "Ka0s Default's first hue")
  assertEqual(C:New(F.content(m), {}):paletteColor(22)[1], 0.90, "twenty-one, then round again")
end)
