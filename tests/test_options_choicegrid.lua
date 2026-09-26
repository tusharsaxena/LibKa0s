-- tests/test_options_choicegrid.lua — LibKa0s-Options-1.0's OptionsWidgets.lua: O.ChoiceGrid, the
-- one-choice-per-row matrix of checkbox cells (minor 16), and its extraColumn (minor 17).
--
-- Peeled out of tests/test_options_widgets.lua (issue #33) when what was left of that suite after
-- the id peel was split on its own case seams. The cases are moved unchanged; the benches are in
-- tests/fixture_widgets.lua.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil, assertNear =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil, T.assertNear
local Fixture = dofile("tests/fixture_options.lua")
local Widgets = dofile("tests/fixture_widgets.lua")("ChoiceGridBench")
local bench, withoutAceGUI = Widgets.bench, Widgets.withoutAceGUI

-- ── ChoiceGrid (minor 16) ─────────────────────────────────────────────────────────────────
--
-- A matrix of one-choice-per-row checkbox cells over rows that share one value list: a Filters
-- tab's categories, each one Default / Whitelist / Blacklist. Before this a host either drew
-- three dropdowns' worth of layout code itself (options-ui-§6 forbids it) or a dropdown per row,
-- which hides the choice behind a click. The rows are plain path rows in the fixture's store,
-- which takes any key.

local GRID_COLUMNS = {
  { value = "",     label = "Default" },
  { value = "show", label = "Whitelist" },
  { value = "hide", label = "Blacklist" },
}

local function gridRows()
  return {
    { path = "cat.alpha", label = "Alpha", tooltip = "The alpha category.", skipRender = true },
    { path = "cat.beta",  label = "Beta",  tooltip = "The beta category.",  skipRender = true },
  }
end

--- The choice cells of one grid line, in column order. Named `radiosOf` for the exclusive,
--- radio-like BEHAVIOR the cells hold, not their widget type -- they are plain CheckBoxes.
local function radiosOf(line)
  local out = {}
  for _, w in ipairs(line.children) do
    if w.type == "CheckBox" then out[#out + 1] = w end
  end
  return out
end

--- How many cells of a line are lit, and the index of the last lit one.
local function litOf(line)
  local n, at = 0, nil
  for i, cb in ipairs(radiosOf(line)) do
    if cb.value then n, at = n + 1, i end
  end
  return n, at
end

--- Run every refresher the ctx holds, as a RefreshScalars sweep would.
local function syncAll(ctx)
  for _, fn in ipairs(ctx.refreshers) do fn() end
end

local function drawGrid(overrides, spec)
  local O, rec, ctx = bench(overrides)
  rec.store["cat.alpha"], rec.store["cat.beta"] = "show", ""
  spec = spec or {}
  spec.rows = spec.rows or gridRows()
  spec.columns = spec.columns or GRID_COLUMNS
  local lines = O.ChoiceGrid(ctx, spec)
  return O, rec, ctx, lines, spec.rows
end

test("widgets: ChoiceGrid draws a heading, a header line and one line per row", function()
  local O, _, ctx, lines = drawGrid(nil, { heading = "Blizzard Categories" })
  -- red under: O.ChoiceGrid absent (a host has no grid to draw its categories with)
  assertEqual(#lines, 2, "one line per row, returned in row order")
  local flat = Fixture.flatten(O.EnsureScroll(ctx))
  assertEqual(flat[1].type, "Heading")
  assertEqual(flat[1].text, "Blizzard Categories", "the heading goes through O.Section")
  assertEqual(ctx.lastGroup, "Blizzard Categories",
    "and advances the tracker, so the next section gets its top spacer")

  local rows = Fixture.flowRows(O.EnsureScroll(ctx))
  assertEqual(#rows, 3, "the header line and the two row lines")
  local header = {}
  for i, w in ipairs(rows[1].children) do header[i] = w.text end
  assertEqual(table.concat(header, "|"), "Default|Whitelist|Blacklist|Category",
    "the column labels, then the default label header")
  assertTrue(rows[2] == lines[1] and rows[3] == lines[2], "the returned lines are the drawn ones")

  for _, line in ipairs(lines) do
    local radios = radiosOf(line)
    assertEqual(#radios, 3, "one radio cell per column")
    for _, cb in ipairs(radios) do assertNear(cb.relativeWidth, 0.12, 1e-6) end
    local label = line.children[#line.children]
    assertEqual(label.type, "InteractiveLabel", "the row label fills the rest of the line")
    assertTrue(label.relativeWidth > 0 and label.relativeWidth + 3 * 0.12 <= 1,
      "and the line fits one Flow row")
  end
  assertEqual(lines[1].children[4].text, "Alpha")
end)

test("widgets: ChoiceGrid draws skipRender rows, and a custom label header", function()
  local O, _, ctx, lines = drawGrid(nil, { labelHeader = "Spell list" })
  -- red under: the grid honoring skipRender (the flow engine's flag) and drawing nothing
  assertEqual(#lines, 2, "skipRender keeps the flow engine off the rows, not the grid")
  local header = Fixture.flowRows(O.EnsureScroll(ctx))[1]
  assertEqual(header.children[4].text, "Spell list")
  assertNil(ctx.lastGroup, "no heading asked for, so the tracker is left alone")
end)

test("widgets: ChoiceGrid lights the cell holding the stored value and only that one", function()
  local _, _, _, lines = drawGrid()
  local n, at = litOf(lines[1])
  assertEqual(n, 1); assertEqual(at, 2, "alpha holds show: Whitelist is lit")
  n, at = litOf(lines[2])
  -- red under: a truthiness test on the value (the empty string still lights, a nil too)
  assertEqual(n, 1); assertEqual(at, 1, "beta holds the empty string: Default is lit")
end)

test("widgets: a ChoiceGrid click writes the column value and re-syncs the whole line", function()
  local _, rec, _, lines = drawGrid()
  local radios = radiosOf(lines[1])
  radios[3]:__fire("OnValueChanged", true)
  -- red under: the click writing the checkbox's boolean instead of the column's value
  assertEqual(rec.store["cat.alpha"], "hide", "the column value reached the host's store")
  -- red under: no refresher per radio (the old cell would stay lit beside the new one)
  local n, at = litOf(lines[1])
  assertEqual(n, 1, "exactly one cell lit after the click")
  assertEqual(at, 3)
  assertEqual(litOf(lines[2]), 1, "the other line is untouched")
  assertEqual(rec.store["cat.beta"], "")
end)

test("widgets: clicking the lit ChoiceGrid cell keeps it lit and writes nothing", function()
  local _, rec, _, lines = drawGrid()
  local writes = 0
  local cb = radiosOf(lines[1])[2]
  local realSet = rec.d.set
  rec.d.set = function(path, value) writes = writes + 1; return realSet(path, value) end
  -- AceGUI toggles a CheckBox on every click, a radio-typed one included, so a click on the lit
  -- cell arrives as `false`. AceGUI's ToggleChecked unchecks the widget before it fires, and the
  -- kit's __fire only calls the callback, so mirror that toggle here.
  cb:SetValue(false)
  cb:__fire("OnValueChanged", false)
  -- red under: re-syncing only through a write (the lit cell would read unlit until the next one)
  assertTrue(cb.value, "a radio cannot be clicked off")
  -- red under: writing unconditionally (a no-op write and a refresh sweep on every stray click)
  assertEqual(writes, 0, "the value did not change, so nothing was written")
  assertEqual(rec.store["cat.alpha"], "show")
end)

test("widgets: a ChoiceGrid value outside the columns lights no cell", function()
  local O, rec, ctx = bench()
  rec.store["cat.alpha"], rec.store["cat.beta"] = "stale", nil
  local lines = O.ChoiceGrid(ctx, { rows = gridRows(), columns = GRID_COLUMNS })
  -- red under: a fallback to the first column (a stale value would read as Default and hide itself)
  assertEqual(litOf(lines[1]), 0, "a value no column carries lights none")
  assertEqual(litOf(lines[2]), 0, "and nil is not the empty string")
end)

test("widgets: ChoiceGrid radios re-read the store when the refreshers run", function()
  local _, rec, ctx, lines = drawGrid()
  rec.store["cat.beta"] = "hide"     -- written behind the grid's back, by a slash command say
  syncAll(ctx)
  local n, at = litOf(lines[2])
  -- red under: seeding the radios at build only
  assertEqual(n, 1); assertEqual(at, 3)
end)

test("widgets: ChoiceGrid reads and writes a path-less row through its own get/set", function()
  local O, _, ctx = bench()
  local held = "hide"
  local rows = { { label = "Record", get = function() return held end,
                   set = function(v) held = v end } }
  local lines = O.ChoiceGrid(ctx, { rows = rows, columns = GRID_COLUMNS })
  local _, at = litOf(lines[1])
  assertEqual(at, 3, "read through row.get")
  radiosOf(lines[1])[1]:__fire("OnValueChanged", true)
  -- red under: reading d.get(row.path) directly instead of the file's read/write seam
  assertEqual(held, "", "written through row.set")
end)

test("widgets: ChoiceGrid cells are ordinary checkboxes, never radios and never painted", function()
  local O, rec, ctx = bench()
  rec.store["cat.alpha"] = "show"
  local ace = O.AceGUI
  local realCreate = ace.Create
  local checkBoxes = {}
  ace.Create = function(self, wtype)
    local w = realCreate(self, wtype)
    if wtype == "CheckBox" then
      -- red under: choiceCell calling SetType("radio") again -- the owner wants a checkbox that
      -- BEHAVES like a radio (one choice per row), not the widget itself turned into one (G-1)
      function w:SetType(t) self.checkType = t end
      checkBoxes[#checkBoxes + 1] = w
    end
    return w
  end
  local ok, lines = pcall(O.ChoiceGrid, ctx, { rows = gridRows(), columns = GRID_COLUMNS })
  ace.Create = realCreate
  assertTrue(ok, tostring(lines))

  for _, cb in ipairs(checkBoxes) do
    assertNil(cb.checkType, "SetType was never called: the cell stays an ordinary checkbox")
    -- red under: choiceFill (or any successor) reintroduced without an owner decision -- the lit
    -- cell reads with AceGUI's own check glyph, never a painted texture (G-1)
    assertNil(cb.__checkTexture, "no cell carries a paint of its own; the check glyph is stock AceGUI")
  end

  -- alpha holds "show" (Whitelist, column 2 of GRID_COLUMNS); the exclusive one-choice-per-row
  -- behavior is choiceCell's callback, not the widget's appearance, and is unchanged by G-1
  local radios = radiosOf(lines[1])
  assertFalse(radios[1]:GetValue(), "the unchosen column reads false")
  assertTrue(radios[2]:GetValue(), "the chosen column reads true")
end)

test("widgets: a CheckBox recycled after a ChoiceGrid comes back with an untinted check (G-2)", function()
  -- Retained from v1.36.1 on purpose (G-2): this used to be the only thing that caught choiceFill
  -- painting the pooled check texture gold and never restoring it on Release, which leaked into
  -- every checkbox recycled afterward -- this addon's or another's sharing the same AceGUI
  -- instance. G-1 withdraws the fill and the OnRelease restore it required, so this test no longer
  -- exercises a live write; it is re-pointed at what still holds -- a checkbox recycled after a
  -- ChoiceGrid comes back with the same untinted check any other recycled CheckBox has. Keep this
  -- test alive: a future fill attempt (LibKa0s/OptionsWidgets.lua) MUST restore the pooled check
  -- texture's vertex color on OnRelease, or this regression returns silently.
  local O, _, ctx = bench()
  local lines = O.ChoiceGrid(ctx, { rows = gridRows(), columns = GRID_COLUMNS })
  for _, cb in ipairs(radiosOf(lines[1])) do cb:Release() end

  local recycled = O.AceGUI:Create("CheckBox")
  local r, g, b = recycled.check:GetVertexColor()
  assertEqual(r, 1, "a checkbox recycled after a grid is not tinted (red)")
  assertEqual(g, 1, "a checkbox recycled after a grid is not tinted (green)")
  assertEqual(b, 1, "a checkbox recycled after a grid is not tinted (blue)")
end)

test("widgets: ChoiceGrid disables a row's cells by its disabledIf", function()
  local O, rec, ctx = bench()
  local off = true
  local rows = gridRows()
  rows[1].disabledIf = function() return off end
  local lines = O.ChoiceGrid(ctx, { rows = rows, columns = GRID_COLUMNS })
  -- red under: the grid not binding disabledIf per radio
  for _, cb in ipairs(radiosOf(lines[1])) do assertTrue(cb.disabled, "alpha's cells are disabled") end
  assertTrue(lines[1].children[4].disabled, "and its label is dimmed with them")
  for _, cb in ipairs(radiosOf(lines[2])) do
    assertNil(cb.disabled, "a row with no disabledIf is never touched")
  end
  off = false
  syncAll(ctx)
  -- red under: evaluating disabledIf at build only
  for _, cb in ipairs(radiosOf(lines[1])) do assertFalse(cb.disabled, "re-evaluated on refresh") end
  -- red under: not registering the label's disable refresher (the label stays dimmed once its
  -- row re-enables)
  assertFalse(lines[1].children[4].disabled, "the label brightens with its cells")
  assertTrue(rec ~= nil)
end)

test("widgets: a ChoiceGrid drawn inside a disabled render is disabled with it", function()
  local O, rec, ctx = bench()
  local lines
  local after = { Master = function(c)
    lines = O.ChoiceGrid(c, { rows = gridRows(), columns = GRID_COLUMNS })
  end }
  O.RenderRows(ctx, { rec.byPath.locked }, after, nil, { disabled = true })
  -- red under: the radios ignoring the render's flag (a Filters tab on a disabled page stays live)
  for _, line in ipairs(lines) do
    for _, cb in ipairs(radiosOf(line)) do assertTrue(cb.disabled) end
  end
end)

test("widgets: ChoiceGrid spec.disabled disables every cell for the call only", function()
  local O, _, ctx = bench()
  local lines = O.ChoiceGrid(ctx, { rows = gridRows(), columns = GRID_COLUMNS, disabled = true })
  -- red under: ignoring spec.disabled (a host would have to set the ctx's private flag itself)
  for _, line in ipairs(lines) do
    for _, cb in ipairs(radiosOf(line)) do assertTrue(cb.disabled) end
  end
  -- red under: leaving the flag on the ctx after the call
  assertNil(ctx.__renderDisabled, "the flag lives for the call only")
  syncAll(ctx)
  assertTrue(radiosOf(lines[1])[1].disabled, "and stays through a refresh")
end)

test("widgets: a ChoiceGrid label carries the row's tooltip", function()
  local _, _, _, lines = drawGrid()
  local label = lines[1].children[4]
  -- Spied on the mock's own methods: the chunk env reads mocks first, so a _G stand-in is never
  -- the tooltip the library reaches.
  local tip, shown = T.mocks.GameTooltip, {}
  local savedText, savedLine = rawget(tip, "SetText"), rawget(tip, "AddLine")
  tip.SetText = function(_, text) shown.title = text end
  tip.AddLine = function(_, text) shown.body = text end
  local ok, err = pcall(label.__fire, label, "OnEnter")
  tip.SetText, tip.AddLine = savedText, savedLine
  assertTrue(ok, tostring(err))
  -- red under: no AttachTooltip on the label (the category's description is unreachable)
  assertEqual(shown.title, "Alpha")
  assertEqual(shown.body, "The alpha category.")
end)

test("widgets: a ChoiceGrid row that raises costs its own line, not the grid", function()
  local O, rec, ctx = bench()
  rec.chat = {}
  local rows = gridRows()
  table.insert(rows, 2, { label = "Broken", get = function() error("row exploded") end,
                          set = function() end })
  rec.store["cat.alpha"], rec.store["cat.beta"] = "show", "hide"
  local lines = O.ChoiceGrid(ctx, { rows = rows, columns = GRID_COLUMNS })
  -- red under: an unguarded line (every row after the broken one would never draw)
  assertEqual(#lines, 2, "the lines on either side still drew")
  assertEqual(lines[2].children[4].text, "Beta")
  assertTrue(table.concat(rec.chat, "\n"):find("row exploded", 1, true) ~= nil, "and it is reported")
end)

test("widgets: ChoiceGrid with no AceGUI draws nothing", function()
  withoutAceGUI(function()
    local O, _, ctx = bench()
    -- red under: reaching for the scroll without the EnsureScroll guard every maker has
    assertNil(O.ChoiceGrid(ctx, { rows = gridRows(), columns = GRID_COLUMNS }))
  end)
end)

-- ── ChoiceGrid extraColumn (minor 17) ──────────────────────────────────────────────────────
--
-- A per-row link after the label, so a host (Aura Master's Spell Categories tab) can send the
-- player from a category's grid line to that category's own spell list without drawing any
-- layout code of its own.

test("widgets: an extraColumn draws a header cell and a clickable per-row link, wired to onClick", function()
  -- red under: extraColumn absent from the header or the line (the host has nowhere to draw its link)
  local clicked
  local O, _, ctx, lines, rows = drawGrid(nil, {
    extraColumn = {
      header = "Spells",
      cell = function(row)
        if row.label ~= "Alpha" then return nil end
        return { text = "See spells", onClick = function() clicked = row.label end }
      end,
    },
  })
  local header = Fixture.flowRows(O.EnsureScroll(ctx))[1]
  assertEqual(header.children[5].text, "Spells", "the extra header lands after the label heading")

  local link = lines[1].children[5]
  assertEqual(link.type, "InteractiveLabel", "a live cell renders as a clickable label")
  assertEqual(link.text, "See spells")
  link:__fire("OnClick")
  assertEqual(clicked, rows[1].label, "the row's own onClick fired")
end)

test("widgets: an extraColumn's nil cell draws a blank of the same width, so rows stay aligned", function()
  local _, _, _, lines = drawGrid(nil, {
    extraColumn = {
      header = "Spells",
      cell = function(row)
        if row.label ~= "Alpha" then return nil end
        return { text = "See spells", onClick = function() end }
      end,
    },
  })
  local blank = lines[2].children[5]
  -- red under: a nil cell collapsing the line instead of drawing a same-width placeholder
  assertEqual(blank.type, "Label")
  assertEqual(blank.text, "")
  assertNear(blank.relativeWidth, lines[1].children[5].relativeWidth, 1e-6,
    "the blank matches the live cell's width")
end)

test("widgets: an extraColumn cell that raises costs only that cell, not the line or the grid", function()
  local _, _, _, lines = drawGrid(nil, {
    extraColumn = {
      header = "Spells",
      cell = function(row)
        if row.label == "Alpha" then error("host cell exploded") end
        return { text = "See spells", onClick = function() end }
      end,
    },
  })
  -- red under: extra.cell called unguarded (a raising host cell would take the whole line down)
  assertEqual(#lines, 2, "both lines still drew")
  assertEqual(lines[1].children[4].text, "Alpha", "the row's own label still drew")
  assertEqual(lines[1].children[5].type, "Label", "the raised cell fell back to a blank")
  assertEqual(lines[1].children[5].text, "")
  assertEqual(lines[2].children[5].text, "See spells", "the row after it drew normally")
end)

test("widgets: an extraColumn cell with a non-function onClick draws without wiring a handler", function()
  -- red under: `if cell.onClick then` treating a truthy non-function as callable, raising at
  -- click-time inside a settings page render (checked with `type(cell.onClick) == "function"`)
  local _, _, _, lines = drawGrid(nil, {
    extraColumn = {
      header = "Spells",
      cell = function(row)
        if row.label ~= "Alpha" then return nil end
        return { text = "See spells", onClick = "not-a-function" }
      end,
    },
  })
  local link = lines[1].children[5]
  assertEqual(link.type, "InteractiveLabel")
  assertEqual(link.text, "See spells")
  -- firing OnClick must not raise, and must not call the malformed value
  link:__fire("OnClick")
end)

test("widgets: an extraColumn narrows the label column, and the line still fits one Flow row", function()
  local _, _, _, lines = drawGrid(nil, {
    extraColumn = { header = "Spells", cell = function() return nil end },
  })
  for _, line in ipairs(lines) do
    local label = line.children[4]
    local extra = line.children[5]
    assertTrue(label.relativeWidth > 0 and label.relativeWidth + 3 * 0.12 + extra.relativeWidth <= 1,
      "the label gave back the extra column's width, and the line still fits")
  end
end)

test("widgets: with no extraColumn, ChoiceGrid's line shape is unchanged", function()
  -- red under: choiceLabelRel counting a nil extraColumn as present and shrinking the label anyway
  local _, _, _, lines = drawGrid()
  for _, line in ipairs(lines) do
    assertEqual(#line.children, 4, "three cells and the label, nothing more")
    local label = line.children[4]
    assertTrue(label.relativeWidth > 0 and label.relativeWidth + 3 * 0.12 <= 1)
  end
end)
