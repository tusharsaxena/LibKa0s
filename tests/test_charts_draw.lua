-- tests/test_charts_draw.lua — LibKa0s-Charts-1.0: what each renderer draws, and that a second pass
-- builds no frame.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil = T.test, T.assertEqual, T.assertTrue,
  T.assertFalse, T.assertNil
local F = dofile("tests/fixture_charts.lua")

local RED, BLUE = { 1, 0, 0 }, { 0, 0, 1 }

local function bench(host)
  local m, C = F.env()
  local content = F.content(m)
  local ctx = C:New(content, host or {})
  return ctx, m, C, ctx:sectionHeader(nil, "Heading")
end

test("draw: a bar section scales to its longest row, leaves the rows alone, and moves the cursor", function()
  local ctx, _, C, header = bench()
  local K = C.K
  local rows = { { label = "One", frac = 0.5, color = RED, value = "10" },
                 { label = "Two", frac = 0.25, color = BLUE, value = "5" } }
  local pool = ctx:Pool("bars")
  local y = ctx:renderBarSection(pool, header, rows, -10, 500, 8)
  assertEqual(y, -10 - K.HEADER_H - 2 * (K.BAR_H + K.BAR_GAP) - K.SECTION_GAP)
  assertEqual(rows[1].frac, 0.5, "the caller's table is not written")
  local a, b = pool.active[1], pool.active[2]
  local trackW = 500 - 16 - K.LABELW - K.VALW - 12
  assertEqual(a.fill.__w, trackW, "the longest fills the track")
  assertEqual(b.fill.__w, trackW / 2)
  assertEqual(a.label.__text, "One")
  assertEqual(a.value.__text, "10")
  assertEqual(a.label.__color[1], 1, "a label takes its bar's color")
  assertEqual(a._tip, "One:  10", "the hover states the value")
end)

test("draw: an empty section hides its heading and leaves the cursor", function()
  local ctx, _, _, header = bench()
  assertEqual(ctx:renderBarSection(ctx:Pool("b"), header, {}, -10, 500, 8), -10)
  assertFalse(header:IsShown())
  assertEqual(ctx:renderStackedBarSection(ctx:Pool("s"), header, {}, -11, 500, 8), -11)
  assertEqual(ctx:renderRangeSection(ctx:Pool("r"), header, {}, -12, 500, 8), -12)
  assertEqual(ctx:renderLegend(ctx:Pool("l"), {}, -13, 500, 8), -13)
end)

test("draw: all-zero rows draw a one-pixel fill, and a row with no color takes the bar color", function()
  local ctx, _, _, header = bench()
  local pool = ctx:Pool("bars")
  ctx:renderBarSection(pool, header, { { label = "None", value = "0" } }, 0, 500, 8)
  assertEqual(pool.active[1].fill.__w, 1)
  assertEqual(pool.active[1].fill.__color[1], ctx.colors.bar[1])
end)

test("draw: a sublabel grows every row and hides again on a row without one", function()
  local ctx, _, C, header = bench()
  local K = C.K
  local pool = ctx:Pool("bars")
  local rows = { { label = "A", sublabel = "under", frac = 1, color = RED, value = "1" },
                 { label = "B", frac = 1, color = RED, value = "1" } }
  ctx:renderBarSection(pool, header, rows, 0, 500, 8)
  assertEqual(pool.active[1].__h, K.BAR_H2)
  assertEqual(pool.active[2].__h, K.BAR_H2, "the section's rows stay even")
  assertEqual(pool.active[1].sub.__text, "under")
  assertFalse(pool.active[2].sub:IsShown())
  ctx:ReleaseAll()
  ctx:renderBarSection(pool, header, { { label = "C", frac = 1, color = RED, value = "1" } }, 0, 500, 8)
  assertEqual(pool.active[1].__h, K.BAR_H, "a reused row shrinks back")
  assertFalse(pool.active[1].sub:IsShown())
end)

test("draw: a second pass reuses every frame", function()
  local ctx, m, _, header = bench()
  local pool, legend = ctx:Pool("bars"), ctx:Pool("legend")
  local rows = { { label = "A", frac = 1, color = RED, value = "1" } }
  ctx:renderBarSection(pool, header, rows, 0, 500, 8, legend)
  local made = #m.__frames
  ctx:ReleaseAll()
  ctx:renderBarSection(pool, header, rows, 0, 500, 8, legend)
  assertEqual(#m.__frames, made)
end)

test("draw: stacked bars lay their segments end to end and hide the unused ones", function()
  local ctx, _, C, header = bench()
  local K = C.K
  local pool = ctx:Pool("stack")
  local rows = { { label = "S", value = "9", segments = {
    { frac = 0.5, color = RED, tip = "red" }, { frac = 0.25, color = BLUE, tip = "blue" }, { frac = 0 } } } }
  ctx:renderStackedBarSection(pool, header, rows, 0, 500, 8)
  local bar = pool.active[1]
  local trackW = 500 - 16 - K.LABELW - K.VALW - 12
  assertEqual(bar.segs[1].__w, trackW / 2)
  assertEqual(F.xy(bar.segs[2]), trackW / 2, "the second starts where the first ends")
  assertEqual(bar.segs[2]._tip, "blue")
  assertFalse(bar.segs[3]:IsShown(), "a zero segment")
  assertFalse(bar.segs[K.MAX_STACK_SEGS]:IsShown())
  assertEqual(bar.label.__color[1], ctx.colors.body[1], "no labelColor reads body")
end)

test("draw: a range bar spans lo to hi on the rows' scale, with its mark and scale line", function()
  local ctx, _, C, header = bench()
  local K = C.K
  local pool, scale = ctx:Pool("range"), ctx:Pool("scale")
  local rows = { { label = "A", lo = 100, hi = 200, mark = 150, color = RED, value = "x" },
                 { label = "B", lo = 150, hi = 150, color = BLUE, value = "y" } }
  local y = ctx:renderRangeSection(pool, header, rows, 0, 500, 8, scale, function(v) return "v" .. v end)
  local trackW = 500 - 16 - K.LABELW - K.VALW - 12
  local a, b = pool.active[1], pool.active[2]
  assertEqual(a.fill.__w, trackW)
  assertEqual(F.xy(a.fill), 0)
  assertEqual(F.xy(a.mark), trackW / 2)
  assertTrue(a.mark:IsShown())
  assertEqual(b.fill.__w, K.RANGE_MIN_W, "alike runs still draw")
  assertFalse(b.mark:IsShown(), "no mark")
  assertEqual(scale.active[1].lo.__text, "v100")
  assertEqual(scale.active[1].hi.__text, "v200")
  assertEqual(y, -K.HEADER_H - 2 * (K.BAR_H + K.BAR_GAP) - K.RANGE_SCALE_H - K.SECTION_GAP)
end)

test("draw: a legend wraps, and the first chip on a narrow line stays on it", function()
  local ctx, _, C = bench()
  local K = C.K
  local pool = ctx:Pool("legend")
  local rows = { { label = "A", color = RED }, { label = "B", color = BLUE }, { label = "C long enough to cut", color = RED, value = "7" } }
  local y = ctx:renderLegend(pool, rows, 0, 2 * K.CHIP_W + 40, 8, 8)
  assertEqual(select(2, F.xy(pool.active[1])), 0)
  assertEqual(select(2, F.xy(pool.active[3])), -K.LEGEND_ROW_H, "the third wraps")
  assertEqual(y, -2 * K.LEGEND_ROW_H - K.SECTION_GAP)
  assertEqual(pool.active[3]._tip, "C long enough to cut:  7", "the hover keeps it whole")
  ctx:ReleaseAll()
  local narrow = ctx:renderLegend(pool, { { label = "A", color = RED } }, 0, 50, 8)
  assertEqual(select(2, F.xy(pool.active[1])), 0, "no empty line above a chip that cannot fit")
  assertEqual(narrow, -K.LEGEND_ROW_H - K.SECTION_GAP)
end)

test("draw: a strip's columns scale to the tallest, a zero column is a faint stub", function()
  local ctx, _, C, header = bench()
  local K = C.K
  local pool, strip = ctx:Pool("strip"), ctx:strip()
  local buckets = { { count = 4, label = "1/1", info = "four" }, { count = 0, info = "none" }, { count = 2, color = RED } }
  local y = ctx:renderStrip(pool, header, strip, buckets, 0, 400, 8)
  assertEqual(y, -K.HEADER_H - K.DAYSTRIP_H - K.STRIP_LABEL_H - K.SECTION_GAP)
  local a, b, c = pool.active[1], pool.active[2], pool.active[3]
  assertEqual(a.fill.__h, K.DAYSTRIP_H - 2)
  assertEqual(b.fill.__h, 1)
  assertEqual(b.fill.__set.SetAlpha[1], 0.12)
  assertEqual(c.fill.__h, (K.DAYSTRIP_H - 2) / 2)
  assertEqual(c.fill.__color[1], 1, "a bucket's own color")
  assertEqual(a.axis.__text, "1/1")
  assertFalse(b.axis:IsShown(), "no label")
  assertEqual(a._tip, "four")
  assertEqual(strip.axisLine.__w, K.STRIP_SLOT_MAX * 3)
end)

test("draw: a strip takes a fixed top, and a top of nothing falls back to the tallest", function()
  local ctx, _, C, header = bench()
  local K = C.K
  local pool, strip = ctx:Pool("strip"), ctx:strip()
  ctx:renderStrip(pool, header, strip, { { count = 5 } }, 0, 400, 8, 10)
  assertEqual(pool.active[1].fill.__h, (K.DAYSTRIP_H - 2) / 2)
  ctx:ReleaseAll()
  ctx:renderStrip(pool, header, strip, { { count = 5 } }, 0, 400, 8, 0)
  assertEqual(pool.active[1].fill.__h, K.DAYSTRIP_H - 2, "never a division by zero")
end)

test("draw: an empty strip hides itself and its heading", function()
  local ctx, _, _, header = bench()
  local strip = ctx:strip()
  assertEqual(ctx:renderStrip(ctx:Pool("strip"), header, strip, {}, -4, 400, 8), -4)
  assertFalse(strip:IsShown())
  assertFalse(header:IsShown())
end)

test("draw: a list panel caps its rows, sizes itself, and a reused row forgets its click", function()
  local ctx, _, C = bench()
  local K = C.K
  local pool, panel = ctx:Pool("list"), ctx:listPanel(nil, "Top")
  local rows, clicked = {}, 0
  for i = 1, K.LIST_MAX + 2 do rows[i] = { name = "n" .. i, right = "r" .. i } end
  rows[1].onClick = function() clicked = clicked + 1 end
  local h = ctx:renderListPanel(pool, panel, rows, 0, 300, 8)
  assertEqual(h, K.LIST_TITLE_H + K.LIST_MAX * K.LIST_ROW_H + 4)
  assertEqual(#pool.active, K.LIST_MAX)
  local first = pool.active[1]
  first:GetScript("OnMouseUp")(first, "LeftButton")
  assertEqual(clicked, 1)
  assertEqual(first._tip, "n1:  r1")
  ctx:ReleaseAll()
  ctx:renderListPanel(pool, panel, { { name = "x", right = "y" } }, 0, 300, 8)
  local reused = pool.active[1]
  reused:GetScript("OnMouseUp")(reused, "LeftButton")
  assertEqual(clicked, 1, "the last row's click is gone")
end)

test("draw: an empty list panel still holds one row's height", function()
  local ctx, _, C = bench()
  local K = C.K
  assertEqual(ctx:renderListPanel(ctx:Pool("list"), ctx:listPanel(nil, "Top"), {}, 0, 300, 8),
    K.LIST_TITLE_H + K.LIST_ROW_H + 4)
end)

test("draw: a card states its figure and hover, and a later bind undoes a shrink", function()
  local ctx = bench()
  local card = ctx:card(nil, "Total")
  ctx:setCard(card, "12,345")
  assertEqual(card.value.__text, "12,345")
  assertEqual(card.frame._tip, "Total:  12,345")
  assertEqual(card.value.__color[1], ctx.colors.heading[1])
  card.value.__stringWidth = 400
  ctx:setCard(card, "a long figure", "tip", 200, RED)
  assertEqual(card.value.__fontSize, 12, "half the width, half the size")
  assertEqual(card.value.__color[2], 0, "the caller's color")
  assertEqual(card.frame._tip, "tip")
  card.value.__stringWidth = 10
  ctx:setCard(card, "1", nil, 200)
  assertNil(card.value.__fontSize, "back on the font object")
end)

test("draw: a divider's rules flank its title", function()
  local ctx = bench()
  local d = ctx:sectionDivider(nil, "Section")
  assertEqual(d.fs.__text, "Section")
  assertEqual(#d.rules, 2)
  assertEqual(d.rules[1].__color[4], ctx.colors.rule[4])
end)
