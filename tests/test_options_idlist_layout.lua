-- tests/test_options_idlist_layout.lua — LibKa0s-Options-1.0's OptionsIdList.lua: how an id list's
-- entries lay out. `columns` and the floors a canvas has to pay for them, the gutter, the help mark
-- (its width, art and severity), and the no-wrap, lit label a multi-column entry is drawn with.
--
-- Peeled out of tests/test_options_widgets.lua (issue #33) in the commit that peeled the module
-- out of LibKa0s/OptionsWidgets.lua (issue #32). The cases are moved unchanged; the benches are in
-- tests/fixture_ids.lua.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil, assertNear =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil, T.assertNear
local Ids = dofile("tests/fixture_ids.lua")("IdLayoutBench")
local bench, seedIds = Ids.bench, Ids.seedIds
local LIST_BENCH_WIDTH = Ids.LIST_BENCH_WIDTH
local listBench, listRows = Ids.listBench, Ids.listRows
local mocks = T.mocks

-- ── columns (minor 24) ──────────────────────────────────────────────────────────────────────
--
-- The default is one entry per line, and it has to stay what minor 23 drew to the width: every
-- consumer's list is a default-1 list until it asks otherwise.

test("IdList: with no columns option each entry has its line to itself, at minor 23's widths", function()
  local O, _, ctx, lines = listBench({ { id = 21562 }, { id = 774, toggle = true } })
  -- red under: the column divisor reaching a list that never asked for columns
  assertEqual(#lines, 2, "one line per entry")
  assertTrue(lines[1] ~= lines[2], "and no two entries share one")
  assertEqual(#listRows(O, ctx), 2, "two rows in the scroll, one per entry")
  assertEqual(#lines[1].children, 2, "name and action, and no gutter after them")
  assertNear(lines[1].children[1].relativeWidth, 0.78, 1e-9, "the name")
  assertNear(lines[1].children[2].relativeWidth, 0.20, 1e-9, "the action beside it")
  local O2, _, ctx2, icons = listBench({ { id = 21562 } }, { removeStyle = "icon" })
  assertEqual(icons[1].children[1].width, 26, "the X, in a frame wider than its 16px art")
  assertEqual(icons[1].children[1].imageSize[1], 16, "which is still the art it carries")
  assertNear(icons[1].children[2].relativeWidth, 0.90, 1e-9, "and the name taking the rest")
  assertEqual(#listRows(O2, ctx2), 1)
end)

test("IdList: columns = 2 packs entries two to a line, row-major, at half the widths", function()
  local O, _, ctx, lines = listBench({
    { id = 21562 }, { id = 774 }, { id = 99999 }, { id = 6948 },
  }, { columns = 2 })
  -- red under: a column count that is read but not packed (four rows), or packed column-major
  assertEqual(#lines, 4, "one returned line per entry drawn, still in entry order")
  assertTrue(lines[1] == lines[2], "entries 1 and 2 share the first row")
  assertTrue(lines[3] == lines[4], "entries 3 and 4 share the second")
  assertTrue(lines[1] ~= lines[3], "and the two pairs are different rows")
  local rows = listRows(O, ctx)
  assertEqual(#rows, 2, "each shared row is added to the scroll once, not once per entry")
  assertEqual(#rows[1].children, 6, "name, action, gutter -- twice, left to right, then wrap")
  assertEqual(rows[1].children[1].text, "Power Word: Fortitude |cff808080(21562)|r")
  assertEqual(rows[1].children[4].text, "Rejuvenation |cff808080(774)|r", "the SECOND entry, not the third")
  assertEqual(rows[2].children[1].text, "Unknown spell 99999")
  -- Each entry is 0.49 of the row -- name, action and the gutter that separates it from the next --
  -- so the pair still sums to the 0.98 one entry used to hold on its own.
  assertNear(rows[1].children[1].relativeWidth, 0.37, 1e-9)
  assertNear(rows[1].children[2].relativeWidth, 0.10, 1e-9)
  assertNear(rows[1].children[3].relativeWidth, 0.02, 1e-9)
  assertNear(rows[1].children[4].relativeWidth, 0.37, 1e-9)
  assertNear(rows[1].children[5].relativeWidth, 0.10, 1e-9)
  assertNear(rows[1].children[6].relativeWidth, 0.02, 1e-9)
end)

test("IdList: columns = 2 in the icon style halves the name and leaves the X alone", function()
  local O, _, ctx = listBench({ { id = 21562 }, { id = 774 } }, { columns = 2, removeStyle = "icon" })
  local row = listRows(O, ctx)[1]
  -- red under: an X scaled by the column count (its frame would fall under its own art)
  assertEqual(#row.children, 6, "X, name, gutter -- twice")
  assertEqual(row.children[1].width, 26, "the X keeps its absolute frame; only the name is halved")
  assertNear(row.children[2].relativeWidth, 0.43, 1e-9)
  assertNear(row.children[3].relativeWidth, 0.02, 1e-9)
  assertEqual(row.children[1].__removeAtlas, "transmog-icon-remove", "still the delete art")
  assertEqual(row.children[4].width, 26)
  assertNear(row.children[5].relativeWidth, 0.43, 1e-9)
end)

test("IdList: an odd entry count leaves the last line half filled, not stretched", function()
  local O, _, ctx, lines = listBench({ { id = 21562 }, { id = 774 }, { id = 99999 } }, { columns = 2 })
  local rows = listRows(O, ctx)
  -- red under: a trailing entry dropped with the row that never filled, or widened to fill it
  assertEqual(#rows, 2, "the half-filled last row is still added")
  assertEqual(#rows[2].children, 3, "the odd one out is alone in the left half of its own row")
  assertNear(rows[2].children[1].relativeWidth, 0.37, 1e-9, "at a column's width")
  assertTrue(lines[3] == rows[2], "and it is the line returned for entry 3")
end)

test("IdList: inside a two-column list a noted entry takes a full-width line of its own", function()
  local O, _, ctx, lines = listBench({
    { id = 21562 }, { id = 774, note = "hidden by rule 3" }, { id = 99999 }, { id = 6948 },
  }, { columns = 2 })
  local rows = listRows(O, ctx)
  -- red under: a note line packed into a column (its second line would push the pair apart)
  assertEqual(#rows, 3, "the half-packed row goes out ahead of the noted entry")
  assertEqual(#rows[1].children, 3, "entry 1 alone: the entry that would have paired with it is noted")
  assertEqual(#rows[2].children, 3, "name, note, action -- and no gutter, it is a one-column row")
  assertEqual(rows[2].children[2].text, "|cff808080hidden by rule 3|r")
  assertNear(rows[2].children[1].relativeWidth, 0.78, 1e-9, "drawn as a one-column entry")
  assertNear(rows[2].children[2].relativeWidth, 0.78, 1e-9, "and the note under it with it")
  assertNil(rows[2].children[1].__wordWrap, "which means it wraps, exactly as minor 23 drew it")
  assertEqual(#rows[3].children, 6, "the entries after it pair up again")
  assertTrue(lines[2] == rows[2])
end)

test("IdList: a columns value that is not a usable count is floored, clamped, or read as 1", function()
  for _, bad in ipairs({ 0, -3, 1.8, "two", true }) do
    local O, _, ctx = listBench({ { id = 21562 }, { id = 774 } }, { columns = bad })
    -- red under: a zero or negative divisor (a width of inf, or a row that never fills)
    assertEqual(#listRows(O, ctx), 2, "one entry per row, as columns = 1: " .. tostring(bad))
  end
  local O, _, ctx, lines = listBench({
    { id = 21562 }, { id = 774 }, { id = 99999 }, { id = 6948 }, { id = 2589 },
  }, { columns = 40 })
  local rows = listRows(O, ctx)
  assertEqual(#rows, 3, "clamped to two a line, so five entries take three rows")
  assertEqual(#rows[1].children, 6, "two entries, not three")
  assertTrue(lines[4] == rows[2] and lines[5] == rows[3])
  assertNear(rows[1].children[1].relativeWidth, 0.37, 1e-9, "half the name's width")
end)

test("IdList: at two columns a failing entry costs itself, not the entry beside it", function()
  local O, rec, ctx = bench()
  seedIds()
  rec.chat = {}
  -- A canvas that pays for two columns, as listBench gives every other case here: this test is
  -- about the guard, not about the width, and the fake ScrollFrame publishes a content too narrow.
  O.EnsureScroll(ctx).content.width = LIST_BENCH_WIDTH
  -- Raise while the SECOND entry is drawing, AFTER it has put its name into the shared row: the
  -- row has to be rolled back to the entry already in it, or half an entry is drawn beside a whole
  -- one. A host kind, so the raise is the host's and the kinds the library ships are untouched.
  local drawn, failing = 0, false
  local realCreate = O.AceGUI.Create
  O.AceGUI.Create = function(self, wtype)
    if failing and wtype == "Button" then error("action exploded") end
    return realCreate(self, wtype)
  end
  local kind = { noun = "spell", resolve = function(text) return tonumber(text) end,
                 info = function(id) drawn = drawn + 1; failing = drawn == 2; return "Spell " .. id end }
  local ok, lines = pcall(O.IdList, ctx, { kind = kind, columns = 2,
    entries = function() return { { id = 11 }, { id = 22 }, { id = 33 } } end })
  O.AceGUI.Create = realCreate
  assertTrue(ok, "the raise never leaves the list: " .. tostring(lines))
  -- red under: an unguarded entry (the list stops at entry 2), or a guard that drops the whole row
  assertEqual(#lines, 2, "the two entries that drew, and no line for the one that did not")
  local rows = listRows(O, ctx)
  assertEqual(#rows, 1, "the survivors share the one row")
  assertEqual(#rows[1].children, 6, "half of entry 2 was trimmed back out of it")
  assertEqual(rows[1].children[1].text, "Spell 11 |cff808080(11)|r")
  assertEqual(rows[1].children[4].text, "Spell 33 |cff808080(33)|r", "entry 3 takes the free column")
  local chat = table.concat(rec.chat, "\n")
  assertTrue(chat:find("action exploded", 1, true) ~= nil, "and the failure is printed")
  assertTrue(chat:find("22", 1, true) ~= nil, "against the entry's own id")
end)

test("IdList: at two columns the FIRST entry of a row fails without stranding the row", function()
  local O, rec, ctx = bench()
  seedIds()
  rec.chat = {}
  O.EnsureScroll(ctx).content.width = LIST_BENCH_WIDTH   -- two columns, as above
  -- The other half of the guard: raise while the entry that OPENS a row is drawing. Nothing else
  -- is in that row and nothing ever will be, so it is never added to the scroll -- and a row the
  -- scroll never took is a row no ReleaseChildren will ever reach.
  local drawn, failing = 0, false
  local realCreate = O.AceGUI.Create
  O.AceGUI.Create = function(self, wtype)
    if failing and wtype == "Button" then error("first exploded") end
    return realCreate(self, wtype)
  end
  local kind = { noun = "spell", resolve = function(text) return tonumber(text) end,
                 info = function(id) drawn = drawn + 1; failing = drawn == 1; return "Spell " .. id end }
  local before = #O.AceGUI.__released
  local ok, lines = pcall(O.IdList, ctx, { kind = kind, columns = 2,
    entries = function() return { { id = 11 }, { id = 22 }, { id = 33 } } end })
  O.AceGUI.Create = realCreate
  assertTrue(ok, "the raise never leaves the list: " .. tostring(lines))
  assertEqual(#lines, 2, "the two entries after it draw")
  local rows = listRows(O, ctx)
  assertEqual(#rows, 1, "and they pair up in one row of their own")
  assertEqual(rows[1].children[1].text, "Spell 22 |cff808080(22)|r", "entry 2 opens it")
  assertEqual(rows[1].children[4].text, "Spell 33 |cff808080(33)|r")
  -- red under: the abandoned row dropped with `pending = nil` and never handed back -- it leaks
  -- out of AceGUI's pool, one SimpleGroup per failing entry that happened to open a row
  local freed = false
  for i = before + 1, #O.AceGUI.__released do
    if O.AceGUI.__released[i].type == "SimpleGroup" then freed = true end
  end
  assertTrue(freed, "the row the first entry abandoned goes back to the pool")
  assertTrue(table.concat(rec.chat, "\n"):find("first exploded", 1, true) ~= nil)
end)

-- The cap is arithmetic rather than taste, so the case carries the arithmetic. Two floors bind it.
--
-- The LABEL floor is AceGUI's. A Label that has been given an image moves the image ON TOP,
-- centered, with the name wrapped underneath, whenever the frame leaves it under 200px beside that
-- image -- `if (width - imagewidth) < 200`, AceGUI-3.0's UpdateImageAnchor
-- (widgets/AceGUIWidget-Label.lua), which the InteractiveLabel an entry is drawn with hijacks
-- whole. A count the width cannot pay for is not a narrower list, it is a column of icons over
-- wrapped names, and nothing anywhere reports it.
--
-- The X floor is this library's. The delete control's frame is ABSOLUTE (26px), so the names have
-- to leave `cols * 26` behind after taking their 0.90 of the row.
--
-- Both are measured against the CONTENT width, which is what the library does know about itself:
-- L.CONTENT_LEFT + L.CONTENT_RIGHT (12 + 28, LibKa0s/Options.lua:187-188) off the panel, and then
-- OptionsScroll.lua's GUTTER of 20 (LibKa0s/OptionsScroll.lua:34) off that. Panel less 60.
local ACEGUI_LABEL_MIN = 200    -- UpdateImageAnchor's threshold
local ENTRY_ICON_PX    = 16     -- ID_ICON_SIZE, the entry's own icon
local REMOVE_HIT_PX    = 26     -- ID_REMOVE_HIT, the X's absolute frame
local SCROLL_INSET_PX  = 60     -- panel -> content: 12 + 28 + the scrollbar gutter's 20

--- The fraction of a line one entry's NAME holds, per style, at `cols` columns: 0.98 less what the
--- delete control takes and less the gutter, over the count. The gutter is drawn only where there
--- is a neighbor to separate the entry from.
local function nameRel(iconStyle, cols)
  local base = iconStyle and 0.90 or 0.78
  if cols > 1 then base = base - 0.04 end
  return base / cols
end

--- The narrowest CONTENT width at which `cols` columns still draw the layout they promise, in the
--- style `iconStyle` asks for: the wider of the label floor and (in the icon style) the X floor.
local function minContent(iconStyle, cols)
  local floor = (ACEGUI_LABEL_MIN + ENTRY_ICON_PX) / nameRel(iconStyle, cols)
  if iconStyle then floor = math.max(floor, cols * REMOVE_HIT_PX / 0.10) end
  return floor
end

test("IdList: columns is capped at two, and the cap's arithmetic is the label's and the X's", function()
  -- red under: a cap raised past what a settings canvas can pay for. Three columns in the default
  -- style want 876px of CONTENT -- 936px of panel -- and a panel that wide is not a thing this
  -- library has ever been handed.
  assertNear(minContent(false, 1), 276.92, 0.01, "one column wants ~277px of content")
  assertNear(minContent(false, 2), 583.78, 0.01, "two want ~584px")
  assertNear(minContent(false, 3), 875.68, 0.01, "three want ~876px")
  assertNear(minContent(false, 4), 1167.57, 0.01, "and four ~1168px")
  assertEqual(minContent(true, 1), 260, "the icon style's floor at one column is the X's, not the label's")
  assertEqual(minContent(true, 2), 520, "and at two it still is -- 26px of frame per column, over 0.10")
  -- Read the other way round: the panel a count needs is its content plus the scroll's own inset.
  assertNear(minContent(false, 2) + SCROLL_INSET_PX, 643.78, 0.01, "two columns want a ~644px panel")
  assertNear(minContent(false, 3) + SCROLL_INSET_PX, 935.68, 0.01, "three want a ~936px panel")
  -- And the constant agrees with the arithmetic: three is clamped back to two.
  local O, _, ctx = listBench({ { id = 21562 }, { id = 774 }, { id = 99999 } }, { columns = 3 })
  local rows = listRows(O, ctx)
  assertEqual(#rows, 2, "three entries at columns = 3 still take two rows")
  assertEqual(#rows[1].children, 6, "two entries in the first, not three")
  assertNear(rows[1].children[1].relativeWidth, 0.37, 1e-9, "at the two-column width")
end)

-- ── the floors, measured rather than assumed ────────────────────────────────────────────────
--
-- The cap is a guess about the canvas; these are a reading of it. `content.width` is the number
-- AceGUI's Flow lays a row out against (`local width = content.width or content:GetWidth() or 0`,
-- AceGUI-3.0.lua's Flow layout), so a test that writes it is asking the library the same question
-- a real panel of that width asks.

test("IdList: a content width two columns cannot pay for draws one, not a broken grid", function()
  -- red under: a column count taken from the spec alone. One pixel under the icon style's floor the
  -- two X frames (26px each, absolute) no longer fit in what the names left them, and Flow starts a
  -- new row rather than shrinking anything -- the trailing gutter, then an X, land on a line of
  -- their own and nothing anywhere says so.
  local O, _, ctx, lines = listBench({ { id = 21562 }, { id = 774 } },
    { columns = 2, removeStyle = "icon" }, minContent(true, 2) - 1)
  local rows = listRows(O, ctx)
  assertEqual(#rows, 2, "one entry per row: the count fell back to what the width pays for")
  assertEqual(#rows[1].children, 2, "X and name, and no gutter -- it is a one-column row")
  assertEqual(rows[1].children[1].width, REMOVE_HIT_PX, "the X keeps its absolute frame")
  assertNear(rows[1].children[2].relativeWidth, 0.90, 1e-9, "at the one-column name width")
  assertNil(rows[1].children[2].__wordWrap, "and the name wraps again, as a one-column entry does")
  assertTrue(lines[1] ~= lines[2], "and no two entries share a row")
end)

test("IdList: a content width that covers the floor keeps the columns the host asked for", function()
  -- red under: a fallback that fires on a width which DOES pay for the layout. A two-column list
  -- collapsed for nothing is the same silent failure seen from the other side.
  local O, _, ctx = listBench({ { id = 21562 }, { id = 774 } },
    { columns = 2, removeStyle = "icon" }, minContent(true, 2) + 1)
  local rows = listRows(O, ctx)
  assertEqual(#rows, 1, "both entries still share one row")
  assertEqual(#rows[1].children, 6, "X, name, gutter -- twice")
  assertNear(rows[1].children[2].relativeWidth, 0.43, 1e-9, "at the two-column name width")
  assertEqual(rows[1].children[2].__wordWrap, false, "still a one-line entry, so still no wrap")
end)

test("IdList: the default style falls back on the LABEL's floor, which is its only one", function()
  -- The default style has no absolute frame to pay for, so its floor is the label's alone: the
  -- entry's 16px icon plus AceGUI's 200px threshold, over the 0.37 a two-column name holds.
  local narrow, wide = minContent(false, 2) - 1, minContent(false, 2) + 1
  local O, _, ctx = listBench({ { id = 21562 }, { id = 774 } }, { columns = 2 }, narrow)
  -- red under: the icon style's X floor applied to a list that draws no X (it would collapse this
  -- list at 519px, where the label still has its 200px and the layout is honest)
  assertEqual(#listRows(O, ctx), 2, "one entry per row below the label floor")
  local O2, _, ctx2 = listBench({ { id = 21562 }, { id = 774 } }, { columns = 2 }, wide)
  assertEqual(#listRows(O2, ctx2), 1, "and both on one row above it")
  assertTrue(narrow > minContent(true, 2),
    "and this width is above the icon style's floor -- the two styles are measured apart")
end)

test("IdList: a width that cannot be measured leaves the column count exactly as it was", function()
  -- red under: an unmeasured scroll read as a zero-width one. `false` clears `content.width` and
  -- the fake's frame answers 0 until a test arms it -- the shape a page drawn before its panel was
  -- ever given a size has. Collapsing a working two-column list there would be a worse bug than
  -- the one the measurement exists to catch.
  local O, _, ctx = listBench({ { id = 21562 }, { id = 774 } }, { columns = 2 }, false)
  assertEqual(#listRows(O, ctx), 1, "unmeasured is unchanged: both entries still share a row")
  local O2, _, ctx2 = listBench({ { id = 21562 }, { id = 774 } }, { columns = 2 }, 0)
  assertEqual(#listRows(O2, ctx2), 1, "and a width that reads as zero is unmeasured too")
  local O3, _, ctx3 = listBench({ { id = 21562 }, { id = 774 } }, { columns = 2 }, -40)
  assertEqual(#listRows(O3, ctx3), 1, "as is a negative one")
end)

test("IdList: the X's frame is wider than its art, absolute, at every column count", function()
  for _, cols in ipairs({ 1, 2 }) do
    local O, _, ctx = listBench({ { id = 21562 }, { id = 774 } },
      { removeStyle = "icon", columns = cols })
    local x = listRows(O, ctx)[1].children[1]
    -- red under: a relative width on the X (0.08 / cols falls under the art on a narrow canvas, and
    -- an Icon anchors its texture TOP-centered rather than clipping it, so the art spills sideways),
    -- or a frame the size of the art (16px of click target, flush against the 16px spell icon).
    assertEqual(x.width, REMOVE_HIT_PX, "an absolute 26px frame at " .. cols .. " column(s)")
    assertNil(x.relativeWidth, "and no relative one to be multiplied down")
    assertEqual(x.imageSize[1], ENTRY_ICON_PX, "around 16px of art -- 5px of padding on every side")
    assertEqual(x.imageSize[2], ENTRY_ICON_PX)
  end
end)

test("IdList: a gutter separates each entry from the next, and only at more than one column", function()
  -- AceGUI's Flow butts its children edge to edge (`frame:SetPoint("TOPLEFT",
  -- children[i-1].frame, "TOPRIGHT", 0, ...)`), so without a widget in between, entry one's Remove
  -- button sits flush against entry two's NAME -- the name it does not belong to.
  local O, _, ctx = listBench({ { id = 21562 }, { id = 774 } }, { columns = 2 })
  local row = listRows(O, ctx)[1]
  -- red under: no gutter at all, or a gutter that is not a real widget in the row
  assertEqual(row.children[3].type, "SimpleGroup", "a gutter after entry one's action")
  assertEqual(row.children[3].height, 1, "one pixel tall, so it adds nothing to the row")
  assertNil(row.children[3].fullWidth, "and relative, not a full-width spacer that takes its own row")
  assertNear(row.children[3].relativeWidth, 0.02, 1e-9)
  assertNear(row.children[1].relativeWidth + row.children[2].relativeWidth
    + row.children[3].relativeWidth, 0.49, 1e-9, "the entry's whole share of the row is still 0.49")
  local O2, _, ctx2 = listBench({ { id = 21562 }, { id = 774 } })
  for _, r in ipairs(listRows(O2, ctx2)) do
    assertEqual(#r.children, 2, "nothing is drawn at one column, where there is no neighbor")
  end
end)

--- An AceGUI whose InteractiveLabel carries the two things the real widget has and the kit's
--- inert recorder does not: the `label` FontString behind the text, and SetHighlight. Registered
--- through the fake's own RegisterWidgetType, run, then taken back off again.
local function withRealLabels(fn)
  local made = {}
  T.mocks.__libs["AceGUI-3.0"]:RegisterWidgetType("InteractiveLabel", function()
    local w = T.mocks.__makeAceGUIWidget("InteractiveLabel")
    local fs = { wordWrap = true }
    function fs:SetWordWrap(v) self.wordWrap = v and true or false end
    w.label = fs
    function w:SetHighlight(tex) self.highlightTexture = tex end
    made[#made + 1] = w
    return w
  end, 21)
  local ok, err = pcall(fn, made)
  T.mocks.__libs["AceGUI-3.0"].WidgetRegistry["InteractiveLabel"] = nil
  assertTrue(ok, tostring(err))
end

test("IdList: at more than one column an entry name is one line tall, never wrapped", function()
  withRealLabels(function()
    local O, _, ctx = listBench({ { id = 21562 }, { id = 774 } }, { columns = 2 })
    local row = listRows(O, ctx)[1]
    -- red under: word wrap left on. AceGUI's Flow centers a row's widgets on each other by
    -- alignoffset (`frameoffset = child.alignoffset or (frameheight / 2)`, and the next child is
    -- anchored `frameoffset - lastframeoffset` off its neighbor's TOPRIGHT), so a name that wraps
    -- to two lines in column one moves the name AND the action in column two down with it. The
    -- grid stops being a grid.
    assertFalse(row.children[1].label.wordWrap, "column one's name does not wrap")
    assertFalse(row.children[4].label.wordWrap, "nor column two's")
    assertFalse(row.children[1].__wordWrap, "and it is recorded for a fake that has no FontString")
  end)
end)

-- ── the per-entry help mark (minor 28) ──────────────────────────────────────────────────────
--
-- The alternative already here is `note`, a full-width second line -- and a second line cannot
-- share a Flow row, so a noted entry takes a row of its own and punches a hole in a multi-column
-- grid. A host with something to say about MANY entries had to choose between saying it and
-- keeping its columns. The mark says it in a tooltip for a fixed 18px and leaves every entry the
-- same shape.

--- The help Icons of a rendered list, in row order.
local function helpMarks(O, ctx)
  local out = {}
  for _, row in ipairs(listRows(O, ctx)) do
    for _, kid in ipairs(row.children or {}) do
      if kid.type == "Icon" and kid.__helpLines ~= nil or (kid.type == "Icon" and kid.__helpTint) then
        out[#out + 1] = kid
      end
    end
  end
  return out
end

test("IdList: a list where nothing carries help draws no marks at all", function()
  local O, _, ctx = listBench({ { id = 21562 }, { id = 774 } })
  -- red under a mark drawn per entry rather than per list: a host that never heard of `help` must
  -- pay nothing for it, in width or in widgets.
  assertEqual(#helpMarks(O, ctx), 0, "no help, no marks")
end)

test("IdList: every entry gets a mark once ANY entry carries help", function()
  local O, _, ctx = listBench({ { id = 21562, help = { "Never matches." } }, { id = 774 } })
  local marks = helpMarks(O, ctx)
  -- red under a mark only on the entries that have lines, which would make the column appear and
  -- disappear down the list and stop the names lining up.
  assertEqual(#marks, 2, "one mark per entry, not one per helped entry")
  assertEqual(marks[1].__helpLines[1], "Never matches.", "the first carries the host's line")
  assertNil(marks[2].__helpLines, "the second has nothing to say")
end)

test("IdList: a mark with nothing to say is dimmed and answers no tooltip", function()
  local O, _, ctx = listBench({ { id = 21562, help = { "x" } }, { id = 774 } })
  local marks = helpMarks(O, ctx)
  -- red under a mark that looked the same either way, which would invite a hover that does nothing
  assertTrue(marks[1].__helpTint[1] > marks[2].__helpTint[1], "the helped mark is brighter")
  assertNil(marks[2].callbacks and marks[2].callbacks.OnEnter,
    "and the empty one registers no hover at all, so it cannot answer a blank tooltip")
end)

test("IdList: a string help reads as one line", function()
  local O, _, ctx = listBench({ { id = 21562, help = "Just the one." } })
  assertEqual(helpMarks(O, ctx)[1].__helpLines[1], "Just the one.",
    "a host with one thing to say need not wrap it in a table")
end)

--- The relative width of the first row's name label.
local function firstNameRel(entries)
  local O, _, ctx = listBench(entries)
  for _, kid in ipairs(listRows(O, ctx)[1].children or {}) do
    if kid.type == "InteractiveLabel" then return kid.relativeWidth end
  end
  return nil
end

test("IdList: the help mark's width comes out of the NAME", function()
  local withHelp = firstNameRel({ { id = 21562, help = { "x" } } })
  local without  = firstNameRel({ { id = 21562 } })
  assertTrue(withHelp ~= nil and without ~= nil, "both rows drew a name")
  -- red under a mark that claimed no width, which would push the row past its clip budget and
  -- wrap the last control onto a line of its own -- the failure nothing reports.
  assertTrue(withHelp < without, "the name gives up its share for the mark")
end)

-- ── the mark's size, its art and its severity (minor 29) ─────────────────────────────────────
--
-- Three owner findings against minor 28, and the first is one this suite could not see from the
-- inside: listBench draws into LIST_BENCH_WIDTH, 1000px, which pays for minor 28's 720px helped
-- two-column floor. A settings canvas does not. So every helped list in game was fitted down to one
-- column while every case above stayed green. These read the widths a panel actually hands a page.

local HELP_HIT_PX   = 24      -- ID_HELP_HIT: the mark's absolute frame, its 14px art plus 10
local HELP_REL_FRAC = 0.09    -- ID_HELP_REL: what the name gives up for that frame

--- The narrowest CONTENT width at which a HELPED two-column icon-style list is still two columns:
--- AceGUI's label floor over what one name holds once the X (0.08), the gutter (0.04) and the mark
--- (ID_HELP_REL) are out of the line. Written from the numbers rather than read off the library,
--- for the same reason minContent above is -- a floor that asks its own implementation cannot fail.
local function helpedIconFloor()
  return (ACEGUI_LABEL_MIN + ENTRY_ICON_PX) / ((0.90 - 0.04 - HELP_REL_FRAC) / 2)
end

test("IdList: a helped list still gets two columns on a canvas that pays for them", function()
  -- red under minor 28's ID_HELP_REL of 0.05: entryMinContent's mark floor is
  -- `cols * ID_HELP_HIT / ID_HELP_REL` = 2 * 18 / 0.05 = 720px of content, against the ~584 the
  -- ID_COLUMNS_MAX block calls comfortable and the ~876 it calls past a canvas. Setting `help` on
  -- ONE entry therefore collapsed the whole list to one column -- which is what the owner reported
  -- against a two-column spell list, and what nothing in this file could see at a 1000px bench.
  local helped = { { id = 21562, help = { "Never matches." } }, { id = 774 } }
  local O, _, ctx = listBench(helped, { columns = 2, removeStyle = "icon" }, helpedIconFloor() + 1)
  assertEqual(#listRows(O, ctx), 1, "both entries share one row just above the floor")
  -- and the floor is still a floor: a pixel under it the list is narrow rather than broken.
  local O2, _, ctx2 = listBench(helped, { columns = 2, removeStyle = "icon" }, helpedIconFloor() - 1)
  assertEqual(#listRows(O2, ctx2), 2, "one entry per row just below it")
end)

test("IdList: the mark is drawn big enough to read, in a frame with the X's 5px ring", function()
  local O, _, ctx = listBench({ { id = 21562, help = { "x" } } }, { removeStyle = "icon" })
  local mark = helpMarks(O, ctx)[1]
  -- red under minor 28's 8px art in an 18px frame. 8px between the X's 16px atlas and the entry's
  -- own 16px icon reads as half-drawn rather than as small, which is the owner's report. The frame
  -- is the art plus 10 for the reason ID_REMOVE_HIT is: AceGUI centers an Icon's texture and hangs
  -- it 5px below the frame's top, so art + 10 is 5px of clear space on all four sides.
  assertEqual(mark.imageSize[1], 14, "the art is 14px, under the 16 beside it and over the 8")
  assertEqual(mark.width, HELP_HIT_PX, "and the frame is the art plus 10")
end)

test("IdList: the mark draws this library's own info art when the host names itself", function()
  -- red under minor 28, which had no default beyond the client's glyph: the collection ships
  -- `media/icons/info.tga` and ConsumableMaster already draws it for this job, so one addon's info
  -- mark being the library's and another's the client's was the inconsistency it looks like.
  local O, _, ctx = listBench({ { id = 21562, help = { "x" } } }, nil, nil,
    { addonName = "TestHost" })
  assertEqual(helpMarks(O, ctx)[1].__helpIcon,
    "Interface\\AddOns\\TestHost\\libs\\LibKa0s\\media\\icons\\info",
    "the vendored path Media.Icon builds from the descriptor's addonName, extensionless")
end)

test("IdList: the art ladder falls back, and a host that names its own art keeps it", function()
  -- red under a default that assumed Media, or that ignored spec.helpIcon once it had one. A
  -- payload may ship Options without Media, and a host may name no addon -- both draw the client's
  -- glyph rather than a blank square, which is exactly what minor 28 drew.
  local O, _, ctx = listBench({ { id = 21562, help = { "x" } } })
  assertEqual(helpMarks(O, ctx)[1].__helpIcon, "Interface\\FriendsFrame\\InformationIcon",
    "no addonName, no library art")
  local O2, _, ctx2 = listBench({ { id = 21562, help = { "x" } } },
    { helpIcon = "Interface\\Custom\\Mark" }, nil, { addonName = "TestHost" })
  assertEqual(helpMarks(O2, ctx2)[1].__helpIcon, "Interface\\Custom\\Mark",
    "the host's own art still wins over the library's default")
end)

test("IdList: a help level tints the mark, and an entry that names none keeps its gold", function()
  local O, _, ctx = listBench({
    { id = 21562, help = { level = "blocked", "This aura can never match." } },
    { id = 774,   help = { level = "info", "Also in 2 other categories." } },
    { id = 99999, help = { "Something to know." } },
    { id = 12345 },
  })
  local marks = helpMarks(O, ctx)
  -- red under minor 28, where every helped mark was one gold: "can never match" and "also in 2"
  -- are the same type to the library and two different answers to a player, so the host says which.
  assertEqual(marks[1].__helpLevel, "blocked", "the level is recorded, for a fake with no texture")
  assertTrue(marks[1].__helpTint[2] < marks[2].__helpTint[2],
    "red is red because it drops the green gold keeps, not because it adds red")
  assertEqual(marks[2].__helpTint, marks[3].__helpTint,
    "`info` is the same gold a plain list of strings already wore -- one color, not two")
  assertNil(marks[3].__helpLevel, "and a plain list names no level")
  assertTrue(marks[3].__helpTint[1] > marks[4].__helpTint[1],
    "while an entry with nothing to say is still the flat gray")
end)

test("IdList: an unknown level draws the default, and a hover leaves a mark its own color", function()
  local O, _, ctx = listBench({
    { id = 21562, help = { level = "blocked", "Never matches." } },
    { id = 774,   help = { level = "whatever-the-host-invented", "A line." } },
  })
  local marks = helpMarks(O, ctx)
  -- red under a lookup that raised or blanked on a name it did not know. A host newer than its
  -- vendored copy is the ordinary case, and the honest answer is the mark minor 28 drew.
  -- red under an unknown level resolving to nil rather than falling back: `x == (x and x)` is
  -- true for every value INCLUDING nil, which is what this assertion said before.
  assertTrue(type(marks[2].__helpTint) == "table", "an unknown level still resolves to a tint")
  assertEqual(marks[2].__helpLevel, "whatever-the-host-invented", "recorded, so a typo is visible")
  assertTrue(marks[2].__helpTint[2] > marks[1].__helpTint[2], "and drawn as the default gold")
  -- red under minor 28's OnLeave, which restored ID_HELP_TINT by name: with levels that turns a red
  -- mark gold the first time the cursor crosses it, and leaves it gold.
  marks[1]:__fire("OnEnter")
  assertEqual(marks[1].__helpTintNow[1], 1, "the hover brightens it to white")
  marks[1]:__fire("OnLeave")
  assertEqual(marks[1].__helpTintNow, marks[1].__helpTint, "and it goes back to ITS color, not gold")
end)

test("IdList: a one-column list still wraps, and now lights too (minor 28)", function()
  withRealLabels(function()
    local O, _, ctx = listBench({ { id = 21562 }, { id = 774 } })
    for _, r in ipairs(listRows(O, ctx)) do
      -- red under: the no-wrap rule leaking into the default. One entry has its whole row, a
      -- wrapped name pushes nothing sideways, and truncating it would lose the gray id for no gain.
      assertTrue(r.children[1].label.wordWrap, "the FontString still wraps")
      assertNil(r.children[1].__wordWrap, "and nothing asked it not to")
      -- LIT FROM MINOR 28, where this used to assert the opposite. The reasoning it replaces was
      -- that a one-column tooltip already hangs off the name and needs no second owner -- but the
      -- lit name is not only a tooltip's owner, it is the feedback that says which row the cursor
      -- is on, and one column wants that as much as two. It also left a NOTED entry, drawn at one
      -- column inside a two-column list, as the only unlit row on the page.
      assertEqual(r.children[1].__highlight, "Interface\\QuestFrame\\UI-QuestTitleHighlight",
        "the entry lights under the cursor at one column too")
    end
  end)
end)

test("IdList: the no-wrap FontString is put back when AceGUI takes the widget back", function()
  withRealLabels(function()
    local O, _, ctx = listBench({ { id = 21562 }, { id = 774 } }, { columns = 2 })
    local lbl = listRows(O, ctx)[1].children[1]
    assertFalse(lbl.label.wordWrap)
    -- red under: word wrap left off on a released widget. AceGUI pools widgets across every addon
    -- in the session and Label's OnAcquire does not reset it, so the next consumer of this pooled
    -- label -- in this addon or another -- would get a label that silently stopped wrapping.
    local fs = lbl.label
    O.AceGUI:Release(lbl)
    assertTrue(fs.wordWrap, "release puts the FontString back the way it was found")
  end)
end)

test("IdList: release clears the markers, so a pooled label cannot answer for the next list", function()
  withRealLabels(function()
    local O, _, ctx = listBench({ { id = 21562 }, { id = 774 } }, { columns = 2 })
    local lbl = listRows(O, ctx)[1].children[1]
    assertFalse(lbl.__wordWrap)
    assertEqual(lbl.__highlight, "Interface\\QuestFrame\\UI-QuestTitleHighlight")
    -- red under: the markers left on the widget. AceGUI:Release wipes userdata, events and a fixed
    -- field list, and keys an addon invented are not on it, so both markers ride the widget into a
    -- pool shared with every other consumer of AceGUI. The one-column cases above assert the
    -- default contract as "no marker", which a stale marker turns into a case that passes or fails
    -- on pool order rather than on what the render asked for.
    local fs = lbl.label
    O.AceGUI:Release(lbl)
    assertNil(lbl.__wordWrap, "the no-wrap marker does not ride the widget into the pool")
    assertNil(lbl.__highlight, "and neither does the highlight marker")
    assertTrue(fs.wordWrap, "and the same one callback still hands the FontString back")
  end)
end)

test("IdList: a label with no FontString still has its markers cleared", function()
  -- The kit's InteractiveLabel fake has no `label` FontString, which is exactly the case
  -- entryNoWrap returns early on -- before it used to install anything. The marker is set before
  -- that return, so the callback that clears it has to be installed independently of whether there
  -- was a FontString to restore.
  -- red under: the clear hidden behind the FontString check.
  local O, _, ctx = listBench({ { id = 21562 }, { id = 774 } }, { columns = 2 })
  local lbl = listRows(O, ctx)[1].children[1]
  assertNil(lbl.label, "the plain fake has no FontString, which is the point of this case")
  assertFalse(lbl.__wordWrap)
  assertEqual(lbl.__highlight, "Interface\\QuestFrame\\UI-QuestTitleHighlight")
  O.AceGUI:Release(lbl)
  assertNil(lbl.__wordWrap)
  assertNil(lbl.__highlight)
end)

test("IdList: at more than one column the hovered entry is lit, so the tooltip has an owner", function()
  withRealLabels(function()
    local O, _, ctx = listBench({ { id = 21562 }, { id = 774 } }, { columns = 2 })
    local row = listRows(O, ctx)[1]
    -- red under: no highlight. The tooltip hangs off the whole ROW at two columns so that it
    -- cannot cover the sibling column, which means it can open a long way from the name the cursor
    -- is on with nothing saying which of the two entries it describes.
    assertEqual(row.children[1].highlightTexture, "Interface\\QuestFrame\\UI-QuestTitleHighlight")
    assertEqual(row.children[4].highlightTexture, "Interface\\QuestFrame\\UI-QuestTitleHighlight")
    assertEqual(row.children[1].__highlight, "Interface\\QuestFrame\\UI-QuestTitleHighlight",
      "recorded too, for a fake with no SetHighlight to call")
  end)
end)

--- Hover `label` with GameTooltip:SetOwner spied; answers what it was anchored to, and how.
local function hoverOwner(label)
  local tip, seen = mocks.GameTooltip, {}
  local saved = rawget(tip, "SetOwner")
  tip.SetOwner = function(_, owner, anchor) seen.owner, seen.anchor = owner, anchor end
  local ok, err = pcall(label.__fire, label, "OnEnter")
  tip.SetOwner = saved
  assertTrue(ok, tostring(err))
  return seen
end

test("IdList: a multi-column tooltip hangs off the row, not over the column beside it", function()
  local _, _, _, one = listBench({ { id = 21562 } })
  local single = hoverOwner(one[1].children[1])
  assertEqual(single.anchor, "ANCHOR_RIGHT")
  assertTrue(single.owner == one[1].children[1].frame,
    "one column: the label, whose right edge IS the list's right edge")
  local O, _, ctx, pair = listBench({ { id = 21562 }, { id = 774 } }, { columns = 2 })
  local row = listRows(O, ctx)[1]
  -- red under: ANCHOR_RIGHT off a column-one label at two columns -- the tooltip lands squarely
  -- over column two, hiding the entries the reader is on their way to
  local left = hoverOwner(pair[1].children[1])
  assertEqual(left.anchor, "ANCHOR_RIGHT", "the same anchor, on a wider owner")
  assertTrue(left.owner == row.frame, "two columns: the row, which still reaches the list's edge")
  local right = hoverOwner(pair[2].children[4])
  assertTrue(right.owner == row.frame, "and the column-two entry hangs off the same row")
end)
