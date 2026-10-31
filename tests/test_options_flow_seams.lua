-- tests/test_options_flow_seams.lua -- LibKa0s#59 on the flow engine: `opts.beforeGroup`,
-- `opts.afterSubgroup`, the schema `note` row and the O.PositionBlock composer (OptionsFlow minor 2,
-- OptionsWidgets minor 40, OptionsTabbed minor 2, OptionsCompose minor 15, Options minor 35).

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil, assertFalse =
  T.test, T.assertEqual, T.assertTrue, T.assertNil, T.assertFalse
local Fixture = dofile("tests/fixture_options.lua")
local bench = dofile("tests/fixture_widgets.lua")("SeamBench").bench

--- A plain bool row.
local function bool(path, group, subgroup)
  return { path = path, type = "bool", label = path, group = group, subgroup = subgroup }
end

--- A hook that records `name`, with how many top-level children the page held when it ran.
local function mark(log, ctx, name)
  return function(_, arg)
    log[#log + 1] = { name = name, at = ctx.scroll and #ctx.scroll.children or 0, arg = arg }
  end
end

--- The children of the page's scroll that are of `kind`, as their text.
local function textsOf(ctx, kind)
  local out = {}
  for _, w in ipairs(Fixture.flatten(ctx.scroll)) do
    if w.type == kind then out[#out + 1] = w.text end
  end
  return out
end

-- ── opts.beforeGroup ───────────────────────────────────────────────────────────────────────

test("seams: beforeGroup runs ahead of its group's heading, with the last group flushed", function()
  -- red under: no beforeGroup seam, or the hook running after O.Section.
  local O, _, ctx = bench()
  local sawTail, headingsThen
  local rows = { bool("a", "One"), bool("b", "Two") }
  O.RenderRows(ctx, rows, nil, nil, { beforeGroup = { Two = function()
    sawTail = Fixture.rowWithLabel(ctx.scroll, "a") ~= nil
    headingsThen = #textsOf(ctx, "Heading")
  end } })
  assertTrue(sawTail == true, "the previous group's tail row is on the page")
  assertEqual(headingsThen, 1, "only group One's heading is down: Two's comes after the hook")
  assertEqual(#textsOf(ctx, "Heading"), 2)
end)

test("seams: beforeGroup fires under noHeadings, and once per render when a group recurs", function()
  local O, _, ctx = bench()
  local log = {}
  local hooks = { One = mark(log, ctx, "one") }
  local rows = { bool("a", "One"), bool("b", "Two"), bool("c", "One") }
  O.RenderRows(ctx, rows, nil, nil, { noHeadings = true, beforeGroup = hooks })
  assertEqual(#log, 1, "the group's first run only, as afterGroup")
  O.ClearScroll(ctx)
  O.RenderRows(ctx, rows, nil, nil, { noHeadings = true, beforeGroup = hooks })
  assertEqual(#log, 2, "the host's table is never consumed: a second render fires again")
end)

test("seams: a beforeGroup hook is disabled with the page it draws on", function()
  local O, _, ctx = bench()
  local flag
  O.RenderRows(ctx, { bool("a", "One") }, nil, nil,
    { disabled = true, beforeGroup = { One = function() flag = ctx.__renderDisabled end } })
  assertTrue(flag == true)
  assertNil(ctx.__renderDisabled, "and the flag is restored")
end)

-- ── opts.afterSubgroup ─────────────────────────────────────────────────────────────────────

test("seams: afterSubgroup runs after its block's tail row, before the next heading", function()
  -- red under: no seam, or the hook running before the pending line is flushed. "c" is alone on its
  -- line, so it is exactly the row a late flush would strand.
  local O, _, ctx = bench()
  local sawTail, headingsThen
  local rows = { bool("a", "G", "Size"), bool("b", "G", "Size"), bool("c", "G", "Size"),
                 bool("d", "G", "Layer") }
  O.RenderRows(ctx, rows, nil, nil, { afterSubgroup = { Size = function()
    sawTail = Fixture.rowWithLabel(ctx.scroll, "c") ~= nil
    headingsThen = #textsOf(ctx, "Heading")
  end } })
  assertTrue(sawTail == true, "the block's last line is on the page")
  assertEqual(headingsThen, 2, "G and Size are down, Layer is not")
end)

test("seams: afterSubgroup closes on the page's last row and comes before afterGroup", function()
  local O, _, ctx = bench()
  local log = {}
  O.RenderRows(ctx, { bool("a", "G", "Size") }, { G = mark(log, ctx, "group") }, nil,
    { afterSubgroup = { Size = mark(log, ctx, "sub") } })
  assertEqual(#log, 2)
  assertEqual(log[1].name, "sub")
  assertEqual(log[2].name, "group")
end)

test("seams: a subgroup name shared by two groups closes in each, naming the group", function()
  -- "Border" under Bars and under Tooltip is the shape startGroup's note describes: a name-keyed
  -- ledger would have fired for the first and lost the second in silence.
  local O, _, ctx = bench()
  local log = {}
  local rows = { bool("a", "Bars", "Border"), bool("b", "Tooltip", "Border") }
  O.RenderRows(ctx, rows, nil, nil, { afterSubgroup = { Border = mark(log, ctx, "b") } })
  assertEqual(#log, 2)
  assertEqual(log[1].arg, "Bars")
  assertEqual(log[2].arg, "Tooltip")
end)

test("seams: a block that recurs in one group closes once, and no hook means no flush", function()
  local O, _, ctx = bench()
  local log = {}
  local rows = { bool("a", "G", "A"), bool("b", "G", "B"), bool("c", "G", "A") }
  local hooks = { A = mark(log, ctx, "a") }
  O.RenderRows(ctx, rows, nil, nil, { afterSubgroup = hooks })
  assertEqual(#log, 1)
  O.ClearScroll(ctx)
  O.RenderRows(ctx, rows, nil, nil, { afterSubgroup = hooks })
  assertEqual(#log, 2, "a hoisted table renders again")
  -- A subgroup with no hook leaves the pair on one line: the seam changes nothing it is not asked to.
  O.ClearScroll(ctx)
  O.RenderRows(ctx, { bool("a", "G"), bool("b", "G") }, nil, nil, { afterSubgroup = {} })
  assertEqual(#Fixture.flowRows(ctx.scroll), 1)
end)

test("seams: RenderSchema takes the same opts", function()
  local O, _, ctx = bench()
  local fired
  O.RenderSchema(ctx, "general", nil, nil, { beforeGroup = { Master = function() fired = true end } })
  assertTrue(fired == true)
end)

test("seams: RenderTabbedSchema hands both seams to the flow, on a tab click too", function()
  local O, _, ctx = bench({
    rowsForPage = function()
      return { bool("a", "One", "Sub"), bool("b", "Two", "Sub") }
    end,
  })
  local log = {}
  local opts = { beforeGroup = { One = mark(log, ctx, "before1"), Two = mark(log, ctx, "before2") },
                 afterSubgroup = { Sub = mark(log, ctx, "sub") } }
  O.RenderTabbedSchema(ctx, "p", nil, nil, opts)
  assertEqual(#log, 2)
  assertEqual(log[1].name, "before1")
  assertEqual(log[2].name, "sub")
  ctx.__tabKids[2]:__fire("OnClick")
  assertEqual(#log, 4)
  assertEqual(log[3].name, "before2")
  assertEqual(log[4].arg, "Two")
end)

-- ── the note row ───────────────────────────────────────────────────────────────────────────

local NOTE = { type = "note", group = "G", text = "Read by the game at login." }

test("seams: a note row draws dim, at full width, on a line of its own", function()
  -- red under: RenderField's dispatch not knowing the type (it would draw nothing and hold no row).
  local O, _, ctx = bench()
  -- The mock's Label has no FontString of its own: the case gives it one, and the face a client has.
  local create, savedFont = O.AceGUI.Create, _G.GameFontDisableSmall
  local face = {}
  _G.GameFontDisableSmall = face
  O.AceGUI.Create = function(self, kind)
    local w = create(self, kind)
    if kind == "Label" then
      w.label = { SetFontObject = function(fs, obj) fs.fontObject = obj end }
    end
    return w
  end
  local ok, err = pcall(O.RenderRows, ctx, { bool("a", "G"), NOTE, bool("b", "G") })
  O.AceGUI.Create, _G.GameFontDisableSmall = create, savedFont
  if not ok then error(err) end
  local lines = Fixture.flowRows(ctx.scroll)
  assertEqual(#lines, 3, "the note breaks the pair: a, note, b")
  local label = lines[2].children[1]
  assertEqual(label.type, "Label")
  assertEqual(label.text, NOTE.text)
  assertTrue(label.fullWidth == true, "full width")
  assertEqual(label.label.fontObject, face, "the dim face")
end)

test("seams: a note in RenderGrid and in RenderField draws too, and adds no refresher", function()
  local O, _, ctx = bench()
  O.RenderGrid(ctx, { bool("a", "G"), NOTE, bool("b", "G") })
  assertEqual(#Fixture.flowRows(ctx.scroll), 3, "a note is wide in the grid as well")
  assertEqual(#ctx.refreshers, 2, "text reads nothing")
  local parent = O.AceGUI:Create("SimpleGroup")
  local w = O.RenderField(ctx, NOTE, parent, nil)
  assertEqual(w and w.type, "Label", "a host's own band can draw one")
end)

test("seams: a note counts for no pairWith and no line parity after it", function()
  local O, _, ctx = bench()
  O.RenderRows(ctx, { NOTE, bool("a", "G"), bool("b", "G") })
  assertEqual(#Fixture.flowRows(ctx.scroll), 2, "the note, then the pair")
end)

test("seams: the two reset walks never hand a note to the host's applyDefault", function()
  -- red under: the walk calling d.applyDefault(note), which a host's seam indexes by a nil path. The
  -- fixture's own applyDefault does: `store[row.path] = ...` raises.
  local rows = { bool("a", "G"), NOTE }
  rows[1].page, rows[2].page, rows[1].default = "p", "p", true
  local seen = {}
  local O, _, ctx = bench({
    rowsForPage = function() return rows end,
    allRows = function() return rows end,
    applyDefault = function(row) seen[#seen + 1] = row end,
  })
  O.RestoreDefaults("p", ctx)
  assertEqual(#seen, 1)
  O.RestoreAllDefaults(ctx)
  assertEqual(#seen, 2)
end)

-- ── the Position block ─────────────────────────────────────────────────────────────────────

test("seams: PositionBlock emits X | Y under the Position subgroup, on a fresh line", function()
  local O = bench()
  local rows = O.PositionBlock({ prefix = "hud.", page = "p", group = "Layout" })
  assertEqual(#rows, 2)
  assertEqual(rows[1].path, "hud.x")
  assertEqual(rows[2].path, "hud.y")
  assertEqual(rows[1].label, "X offset")
  assertEqual(rows[2].label, "Y offset")
  assertEqual(rows[1].subgroup, "Position")
  assertEqual(rows[2].subgroup, "Position")
  assertEqual(rows[1].page, "p")
  assertTrue(rows[1].startsLine == true, "parity-proof, as every composed block")
  assertEqual(rows[1].type, "number")
  assertEqual(rows[1].default, 0)
end)

test("seams: PositionBlock's hook draws the Reset button under the block", function()
  local O, _, ctx = bench()
  local resets = 0
  local spec = { prefix = "hud.", group = "G", subgroup = "Anchor", min = -50, max = 50,
    labels = { x = "Across" }, defaults = { y = 7 },
    onReset = function() resets = resets + 1 end }
  local rows, after = O.PositionBlock(spec)
  assertEqual(rows[1].subgroup, "Anchor", "the heading is the row's own subgroup")
  assertEqual(rows[1].min, -50)
  assertEqual(rows[2].max, 50)
  assertEqual(rows[1].label, "Across")
  assertEqual(rows[2].default, 7)
  assertEqual(type(after), "function")
  O.RenderRows(ctx, rows, nil, nil, { afterSubgroup = { Anchor = after } })
  assertEqual(textsOf(ctx, "Heading")[2], "Anchor")
  local btn = Fixture.flatten(ctx.scroll)
  local found
  for _, w in ipairs(btn) do if w.type == "Button" then found = w end end
  assertEqual(found and found.text, "Reset position")
  found:__fire("OnClick")
  assertEqual(resets, 1)
end)

test("seams: PositionBlock with no onReset has no hook, and never writes to its spec", function()
  local O = bench()
  local spec = { prefix = "p." }
  local _, after = O.PositionBlock(spec)
  assertNil(after)
  assertNil(spec.subgroup, "the default is not written back")
  assertFalse(pcall(O.PositionBlock, { onReset = true }), "a Reset with nothing to run is refused")
end)

test("seams: PositionBlock takes the record-backed arm", function()
  local O = bench()
  local rec = { x = 4, y = 9 }
  local rows = O.PositionBlock({ bind = { record = function() return rec end,
    set = function(field, value) rec[field] = value end } })
  assertNil(rows[1].path)
  assertEqual(rows[1].field, "x")
  assertEqual(rows[2].get(), 9)
end)
