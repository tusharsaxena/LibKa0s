-- tests/test_options_widgets.lua — LibKa0s-Options-1.0's OptionsWidgets.lua: the five schema-row
-- widget makers, the session checkbox, and the two-column flow engine.
--
-- Widgets here are the kit's inert recorders: they remember what was set on them and expose
-- __fire(event, ...) so a callback can be driven exactly as AceGUI would drive it on a click or a
-- slider release. That is what makes the real read -> set -> refresh loop observable rather than
-- assumed, and it is why every case below asserts on the STORE as well as on the widget.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil, assertNear =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil, T.assertNear
local Fixture = dofile("tests/fixture_options.lua")
-- The INTERNAL LAYOUT keys (CHROME_DIVIDER_*, PANEL_*, CONTENT_*) have no O.* seam of
-- their own -- by design, per the published/internal split at the top of Options.lua -- so a
-- test that needs their raw numbers reads them off the lib table directly, same as
-- tests/test_options.lua does.
local lib = T.options

--- A host, a throwaway panel and a parent container, so a maker can be driven in isolation.
local panelSeq = 0
local function bench(overrides)
  local O, rec = Fixture.new(overrides)
  panelSeq = panelSeq + 1
  local ctx = O.CreatePanel("WidgetBench" .. panelSeq, "Bench " .. panelSeq, {})
  return O, rec, ctx
end

--- Run `fn` with AceGUI absent, restoring it afterwards.
---
--- The instance resolves AceGUI ONCE, at New() time (`LibKa0s/Options.lua:217`), so the library
--- has to be built INSIDE this: flipping the mock after Fixture.new leaves the instance holding
--- the handle it already resolved, and the degraded path never runs. Save-and-restore rather
--- than assign-and-hope, copied from `tests/test_options.lua`'s own missing-AceGUI case.
local function withoutAceGUI(fn)
  local saved = T.mocks.__libs["AceGUI-3.0"]
  T.mocks.__libs["AceGUI-3.0"] = nil
  local ok, err = pcall(fn)
  T.mocks.__libs["AceGUI-3.0"] = saved
  if not ok then error(err) end
end

--- Render one schema path into a throwaway container; hand back the widget, its row and the ctx.
local function render(path, relativeWidth, overrides)
  local O, rec, ctx = bench(overrides)
  local row = rec.byPath[path]
  assertTrue(row ~= nil, "fixture schema row exists: " .. path)
  local parent = O.AceGUI:Create("SimpleGroup")
  return O.RenderField(ctx, row, parent, relativeWidth), row, ctx, rec, O, parent
end

-- ── the layout constants ───────────────────────────────────────────────────────────────────

test("widgets: the cross-slice layout constants are published on the instance", function()
  -- Host page files read these off the instance rather than keeping private copies, so the panel
  -- spacing stays in lockstep. A nil here silently collapses every row to zero height.
  local O = Fixture.new()
  assertEqual(type(O.ROW_VSPACER), "number")
  assertEqual(type(O.SECTION_HEADING_H), "number")
  assertEqual(type(O.BUTTON_PAIR_REL), "number")
  assertTrue(O.BUTTON_PAIR_REL < 0.5,
    "the paired-button width is inset under 0.5 so the right button clears the scroll clip")
end)

-- ── checkbox ───────────────────────────────────────────────────────────────────────────────

test("widgets: a bool row renders a CheckBox labelled and seeded from the schema", function()
  local cb, row = render("locked")
  assertEqual(cb.type, "CheckBox")
  assertEqual(cb.labelText, row.label)
  assertFalse(cb.value, "seeded from the store")

  -- Seeded, not defaulted: a second host whose store already holds true must render ticked.
  local O, rec, ctx = bench()
  rec.store.locked = true
  local ticked = O.RenderField(ctx, rec.byPath.locked, O.AceGUI:Create("SimpleGroup"), 0.5)
  assertTrue(ticked.value)
end)

test("widgets: clicking a checkbox writes through the descriptor's set", function()
  local cb, _, _, rec = render("locked")
  cb:__fire("OnValueChanged", true)
  assertEqual(rec.store.locked, true, "the click reached the host's store")
  cb:__fire("OnValueChanged", false)
  assertEqual(rec.store.locked, false, "and a stored false is a real false, not a nil")
end)

test("widgets: a checkbox registers a refresher that re-reads after an external change", function()
  local cb, _, ctx, rec = render("locked")
  assertFalse(cb.value)
  rec.store.locked = true             -- changed behind the widget's back, e.g. by a slash command
  for _, fn in ipairs(ctx.refreshers) do fn() end
  assertTrue(cb.value, "the refresher pulled the new value in")
end)

test("widgets: every widget gets tooltip callbacks wired from the schema desc", function()
  local cb = render("locked")
  assertTrue(cb.callbacks.OnEnter ~= nil, "OnEnter shows the tooltip")
  assertTrue(cb.callbacks.OnLeave ~= nil, "OnLeave hides it")
end)

test("widgets: relativeWidth is applied when given, full width otherwise", function()
  assertEqual(render("locked", 0.5).relativeWidth, 0.5)
  local full = render("locked")
  assertNil(full.relativeWidth)
  assertTrue(full.fullWidth, "no relative width means the widget spans the row")
end)

-- ── session checkbox (non-schema) ──────────────────────────────────────────────────────────

test("widgets: SessionCheckbox reads and writes the caller's get/set, never the store", function()
  -- The debug-console toggle is session-only and must not become a saved setting, so it cannot go
  -- through the schema maker at all.
  local O, rec, ctx = bench()
  local state = false
  local cb = O.SessionCheckbox(ctx, O.AceGUI:Create("SimpleGroup"), 0.5, {
    label = "Debug console", tooltip = "Show the console",
    get = function() return state end,
    set = function(v) state = v end,
  })
  assertFalse(cb.value, "initial state comes from get()")
  cb:__fire("OnValueChanged", true)
  assertTrue(state, "the click reached set()")
  assertNil(rec.store.debugConsole, "and no stray key was written to the settings store")

  state = false
  for _, fn in ipairs(ctx.refreshers) do fn() end
  assertFalse(cb.value, "and its refresher re-reads live state")
end)

-- ── slider ─────────────────────────────────────────────────────────────────────────────────

test("widgets: a number row renders a Slider carrying the schema's range and step", function()
  local s, row = render("barWidth")
  assertEqual(s.type, "Slider")
  assertEqual(s.min, row.min)
  assertEqual(s.max, row.max)
  assertEqual(s.step, row.step)
  assertFalse(s.isPercent, "raw units, not a percentage")
  assertEqual(s.value, row.default, "seeded from the store")
end)

test("widgets: a slider falls back to the row default when the stored value is not a number",
  function()
  -- A corrupt SavedVariable would otherwise hand AceGUI a string and blow up the layout.
  local O, rec, ctx = bench()
  rec.store.barWidth = "not a number"
  local s = O.RenderField(ctx, rec.byPath.barWidth, O.AceGUI:Create("SimpleGroup"), 0.5)
  assertEqual(s.value, 200)
end)

test("widgets: releasing a slider snaps the value to the row's step", function()
  local s, row, _, rec = render("barWidth")
  s:__fire("OnMouseUp", 217.4)
  assertEqual(rec.store.barWidth % row.step, 0, "the committed value sits on a step boundary")
  assertEqual(rec.store.barWidth, 217)
end)

test("widgets: slider snapping is relative to the row's min, not to zero", function()
  -- snapToStep offsets by `min` before rounding. barHeight runs 15..105 in steps of 10, and 15 is
  -- deliberately not a multiple of 10 — with a min that divided evenly the two implementations
  -- would agree on every input and this case could not fail.
  local s, row, _, rec = render("barHeight")
  s:__fire("OnMouseUp", row.min + row.step * 2 + row.step * 0.4)   -- 39
  assertEqual((rec.store.barHeight - row.min) % row.step, 0, "lands on a reachable stop")
  assertEqual(rec.store.barHeight, 35, "35, not the 40 a zero-relative rounding would give")
end)

-- ── dropdown ───────────────────────────────────────────────────────────────────────────────

test("widgets: a string row with values renders a Dropdown, sorted alphabetically by default",
  function()
  local dd, row, _, rec = render("barTexture")
  assertEqual(dd.type, "Dropdown")
  assertEqual(dd.value, rec.store.barTexture)
  assertTrue(type(dd.list) == "table", "the values hash was applied")
  -- The exact sequence, not merely a monotonic one: `pairs` order is arbitrary in Lua, so an
  -- implementation that dropped the sort could satisfy a "non-decreasing" check by luck.
  assertEqual(table.concat(dd.order, ","), "Aluminium,Blizzard,Smooth",
    "every key in " .. row.path .. "'s values list is offered, alphabetised")
end)

test("widgets: a row with explicit `sorting` keeps that order instead of alphabetising",
  function()
  -- Outline styles read in a deliberate order (None, Outline, Thick); alphabetising scrambles it.
  local dd, row = render("anchor")
  assertEqual(#dd.order, #row.sorting)
  for i, key in ipairs(row.sorting) do
    assertEqual(dd.order[i], key, "position " .. i .. " preserved")
  end
end)

test("widgets: a dropdown falls back to a plain Dropdown when its dialogControl is unregistered",
  function()
  -- AceGUI-3.0-SharedMediaWidgets is optional; without it the option must still render (no media
  -- swatch, but usable) rather than erroring on an unknown widget type.
  local dd, row = render("barTexture")
  assertEqual(row.dialogControl, "LSM30_Statusbar", "the row does ask for the LSM widget")
  assertEqual(dd.type, "Dropdown", "but falls back when it is not registered")
end)

test("widgets: a dropdown uses its dialogControl widget when that IS registered", function()
  local O, rec, ctx = bench()
  O.AceGUI:RegisterWidgetType("LSM30_Statusbar",
    function() return T.mocks.__makeAceGUIWidget("LSM30_Statusbar") end, 1)
  local ok, err = pcall(function()
    local dd = O.RenderField(ctx, rec.byPath.barTexture, O.AceGUI:Create("SimpleGroup"), 0.5)
    assertEqual(dd.type, "LSM30_Statusbar")
  end)
  O.AceGUI.WidgetRegistry["LSM30_Statusbar"]   = nil
  O.AceGUI.__widgetVersions["LSM30_Statusbar"] = nil
  if not ok then error(err) end
end)

test("widgets: a dropdown writes the chosen value, and its refresher re-applies the LIST",
  function()
  -- Re-applying the list, not just the value, is what makes a media list that grew after the page
  -- was built (another addon registering a texture) appear on the next refresh.
  local dd, _, ctx, rec = render("anchor")
  dd:__fire("OnValueChanged", "TOP")
  assertEqual(rec.store.anchor, "TOP")
  dd.list, dd.order = nil, nil
  for _, fn in ipairs(ctx.refreshers) do fn() end
  assertTrue(dd.list ~= nil, "the list was rebuilt, not just the value re-read")
  assertTrue(dd.order ~= nil)
end)

test("widgets: a dropdown built from an ordered array keeps declaration order", function()
  local dd, _, _, rec = render("growth")
  assertEqual(dd.order[1], "RIGHT", "declared position wins, not alphabetical order")
  assertEqual(dd.order[2], "LEFT")
  assertEqual(dd.list.RIGHT, "Right", "and the entry's text is its label")
  dd:__fire("OnValueChanged", "LEFT")
  assertEqual(rec.store.growth, "LEFT", "the VALUE is stored, never the array index")
end)

test("widgets: a key set labels its entries with its keys, not with 'true'", function()
  -- { Blizzard = true } is a degenerate key map. Rendering the value as the label is how such a
  -- row becomes a dropdown of entries all reading "true".
  local dd = render("barTexture")
  assertEqual(dd.list.Blizzard, "Blizzard")
end)

test("widgets: the dropdown's options and the CLI's allowed values agree, in both shapes",
  function()
  -- The cross-major parity case. enumList is duplicated verbatim in Slash.lua and
  -- OptionsWidgets.lua rather than hoisted into Core (hoisting would raise NEEDS_CORE in two
  -- majors, which docs/releasing.md calls a breaking change to the vendoring). This is the
  -- guarantee that buys instead: a CLI that accepts a value the dropdown cannot display, or a
  -- dropdown offering one the CLI refuses, fails here.
  local slash = T.slash
  for _, path in ipairs({ "growth", "anchor" }) do
    local dd, row = render(path)
    for _, value in ipairs(dd.order) do
      assertEqual(slash.ParseValue(row, tostring(value)), value,
        path .. ": the CLI accepts every value the dropdown offers")
    end
    assertNil((slash.ParseValue(row, "NOT_A_REAL_VALUE")),
      path .. ": and refuses one it does not")
  end
end)

test("widgets: a colour row opts OUT of alpha by declaring it, and cannot before", function()
  -- The flipped default. `row.hasAlpha and true or false` made an absent field and a declared
  -- false the same thing, so "no alpha" was inexpressible while the codec stored an alpha the
  -- user could never reach.
  local withAlpha = render("barColor")
  assertTrue(withAlpha.hasAlpha, "absent means yes")
  local without = render("borderColor")
  assertFalse(without.hasAlpha, "and a declared false is honoured")
end)

test("widgets: a tooltip body comes from `tooltip`, with `desc` still accepted", function()
  -- `tooltip` is the name every Ka0s host's schema declares; `desc` is this library's own. Reading
  -- only `desc` blanked the body on every widget of a host on the standard's shape — the label
  -- still renders, so it failed silently and only in game.
  local _, _, _, _, O = render("barColor")
  local seen = {}
  local fake = { frame = {}, SetCallback = function(self, e, fn) seen[e] = fn end }
  O.AttachTooltip(fake, "Label", "body")
  assertTrue(seen.OnEnter ~= nil, "the tooltip is wired through SetCallback")

  local cb = render("barWidth")      -- carries `desc`, not `tooltip`
  assertTrue(cb ~= nil, "a desc-carrying row still renders")
end)

test("widgets: a slider does not commit on drag by default", function()
  local s, _, _, rec = render("barWidth")
  local before = rec.store.barWidth
  s:__fire("OnValueChanged", 217.4)
  assertEqual(rec.store.barWidth, before, "a drag is not a commit unless the host asks")
end)

test("widgets: sliderCommit = 'change' commits on drag, throttled, last value wins", function()
  local s, _, _, rec = render("barWidth", nil, { sliderCommit = "change" })
  local before = rec.store.barWidth
  s:__fire("OnValueChanged", 210)
  s:__fire("OnValueChanged", 240)
  s:__fire("OnValueChanged", 217.4)
  assertEqual(#rec.timers, 1, "three drag frames arm ONE timer, not three")
  assertEqual(rec.store.barWidth, before, "and nothing is written until it fires")
  rec.fireTimers()
  assertEqual(rec.store.barWidth, 217, "the last value wins, snapped to the row's step")
end)

test("widgets: commitOn on a row overrides the descriptor default, both ways", function()
  -- Per-row, against ONE fixture: `render` builds a fresh host each call, so a row mutated
  -- through one of them is not the row the next one renders.
  local O, rec, ctx = bench()
  local parent = O.AceGUI:Create("SimpleGroup")

  rec.byPath.barWidth.commitOn = "change"
  local live = O.RenderField(ctx, rec.byPath.barWidth, parent, 0.5)
  live:__fire("OnValueChanged", 220)
  rec.fireTimers()
  assertEqual(rec.store.barWidth, 220, "a row asking for live commit gets it")
  rec.byPath.barWidth.commitOn = nil

  local O2, rec2, ctx2 = bench({ sliderCommit = "change" })
  rec2.byPath.barHeight.commitOn = "release"
  local held = O2.RenderField(ctx2, rec2.byPath.barHeight, O2.AceGUI:Create("SimpleGroup"), 0.5)
  local before = rec2.store.barHeight
  held:__fire("OnValueChanged", 95)
  rec2.fireTimers()
  assertEqual(rec2.store.barHeight, before, "and a row opting out overrides the descriptor")
end)

test("widgets: a raising row costs that row and no other", function()
  -- The page-level guard added in Options minor 3 catches a raising BUILDER. This is the more
  -- common failure: one corrupt saved value, or a `values` function that raises because the media
  -- library it queries is half-loaded. Unguarded it propagated out of AceGUI's layout pass and
  -- every row after it never drew.
  local O, rec, ctx = bench()
  local rows = {
    { path = "barWidth",  type = "number", label = "W", min = 1, max = 10, step = 1 },
    { path = "boom",      type = "string", label = "B", values = function() error("bad media") end },
    { path = "barHeight", type = "number", label = "H", min = 1, max = 10, step = 1 },
  }
  rec.chat = {}
  O.RenderRows(ctx, rows)
  local text = table.concat(rec.chat, "\n")
  assertTrue(text:find("boom", 1, true) ~= nil, "the failing row is named: " .. text)
  -- Two healthy rows still registered their refreshers; the broken one did not.
  assertEqual(#ctx.refreshers, 2, "the rows on either side of it still drew")
end)

test("widgets: RenderGrid lays arbitrary items out two per row", function()
  -- The caller-driven sibling of RenderRows, for a list whose LENGTH is not in the schema — one
  -- checkbox per macro, per unit, per spell. Every host had a hand-rolled copy of this loop.
  local O, rec, ctx = bench()
  local made = {}
  local function item(name)
    return { make = function(_, parent, relW)
      made[#made + 1] = { name = name, relW = relW }
      local cb = O.AceGUI:Create("CheckBox")
      parent:AddChild(cb)
    end }
  end
  O.RenderGrid(ctx, { item("a"), item("b"), item("c") })
  assertEqual(#made, 3, "every item rendered")
  assertNear(made[1].relW, 0.5, 1e-6, "paired items get half width")
  assertTrue(rec ~= nil)
end)

test("widgets: RenderGrid gives a wide item its own full-width row", function()
  local O, _, ctx = bench()
  -- Recorded as a STRING sentinel, not as the raw nil: `t[#t + 1] = nil` is a no-op in Lua, so a
  -- naive recorder drops the very item under test and silently shifts every index after it.
  local widths = {}
  local function item(wide)
    return { wide = wide, make = function(_, parent, relW)
      widths[#widths + 1] = relW or "full"
      parent:AddChild(O.AceGUI:Create("CheckBox"))
    end }
  end
  O.RenderGrid(ctx, { item(false), item(true), item(false) })
  assertNear(widths[1], 0.5, 1e-6)
  assertEqual(widths[2], "full", "a wide item takes no relative width")
  assertNear(widths[3], 0.5, 1e-6)
end)

test("widgets: RenderGrid guards each item the way RenderRows guards each row", function()
  local O, rec, ctx = bench()
  local drew = 0
  local function ok() return { make = function() drew = drew + 1 end } end
  rec.chat = {}
  O.RenderGrid(ctx, { ok(), { make = function() error("item exploded") end }, ok() })
  assertEqual(drew, 2, "the items on either side of the failure still drew")
  assertTrue(table.concat(rec.chat, "\n"):find("exploded", 1, true) ~= nil)
end)

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

--- A fake check texture: records what choiceFill paints on it, the same three calls a real
--- Texture answers (SetTexture / SetVertexColor / SetTexCoord), plus SetSize.
local function fakeCheckTexture()
  local tex = { calls = {} }
  function tex:SetTexture(path) self.texturePath = path end
  function tex:SetVertexColor(r, g, b) self.vertexColor = { r, g, b } end
  function tex:SetTexCoord(...) self.texCoord = { ... } end
  function tex:SetSize(w, h) self.size = { w, h } end
  return tex
end

test("widgets: ChoiceGrid cells are checkboxes, never radios, and the lit one carries the fill", function()
  local O, _, ctx = bench()
  local ace = O.AceGUI
  local realCreate = ace.Create
  local checkBoxes = {}
  ace.Create = function(self, wtype)
    local w = realCreate(self, wtype)
    if wtype == "CheckBox" then
      -- red under: choiceCell calling SetType("radio") again
      function w:SetType(t) self.checkType = t end
      w.check = fakeCheckTexture()
      checkBoxes[#checkBoxes + 1] = w
    end
    return w
  end
  local ok, lines = pcall(O.ChoiceGrid, ctx, { rows = gridRows(), columns = GRID_COLUMNS })
  ace.Create = realCreate
  assertTrue(ok, tostring(lines))

  for _, cb in ipairs(checkBoxes) do
    assertNil(cb.checkType, "SetType was never called: the cell stays an ordinary checkbox")
  end

  -- alpha holds "show" (Whitelist, column 2 of GRID_COLUMNS)
  local radios = radiosOf(lines[1])
  local lit, unlit = radios[2], radios[1]
  -- red under: the lit cell losing its fill texture
  assertEqual(lit.__checkTexture.texturePath, "Interface\\Buttons\\WHITE8X8",
    "the lit cell's check region is painted with the solid fill")
  assertTrue(lit.__checkTexture.vertexColor ~= nil, "and tinted")
  -- choiceFill runs unconditionally per cell, lit or not: it paints the check REGION, not the
  -- lit state, which SetValue still carries.
  assertTrue(unlit.__checkTexture ~= nil, "every cell's check region is painted the same way")
end)

test("widgets: choiceFill is guarded when a host's AceGUI fake carries no check texture", function()
  local O, _, ctx = bench()
  -- The stock fixture's CheckBox carries no .check and no .frame.check (see mock_base.lua), so
  -- this exercises the real, unmodified O.AceGUI:Create("CheckBox") fake.
  local lines = O.ChoiceGrid(ctx, { rows = gridRows(), columns = GRID_COLUMNS })
  -- red under: choiceFill raising instead of returning nil when no paintable texture exists
  for _, cb in ipairs(radiosOf(lines[1])) do assertNil(cb.__checkTexture) end
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

-- ── ResolveId / IdInput / IdList (minor 16) ────────────────────────────────────────────────
--
-- An id list a player edits by typing a number, pasting a link or typing a name. Before this each
-- host drew its own edit box and Add button and accepted a bare number only (BankLedger,
-- LootHistory, ConsumableMaster), so a player had to look an id up outside the game. The records
-- below go through the kit's opt-in id lookups, which this repo's tests/wow_mock.lua installs.

local mocks = T.mocks

--- Reset the kit's id records to a known set: two spells, four items (one uncached, one the client
--- answers no quality for, the others Common and Legendary), and three currencies, two of which
--- share a name.
local function seedIds()
  mocks.clearIdRecords()
  mocks.addIdRecord("spell", 21562, "Power Word: Fortitude", 135987)
  mocks.addIdRecord("spell", 774, "Rejuvenation", 136081)
  mocks.addIdRecord("item", 6948, "Hearthstone", 134414, nil, 1)
  mocks.addIdRecord("item", 2589, "Linen Cloth", 132889, true, 1)
  mocks.addIdRecord("item", 19019, "Thunderfury", 135349, nil, 5)
  mocks.addIdRecord("item", 777001, "Nameless Quality", 1)
  mocks.addIdRecord("currency", 3008, "Valorstones", 5872049)
  mocks.addIdRecord("currency", 2914, "Crest", 5872050)
  mocks.addIdRecord("currency", 2915, "Crest", 5872051)
end

test("ResolveId: a number is an id, and a known one carries its name and icon", function()
  local O = Fixture.new()
  seedIds()
  local id, name, icon = O.ResolveId("spell", " 21562 ")
  assertEqual(id, 21562); assertEqual(name, "Power Word: Fortitude"); assertEqual(icon, 135987)
  -- red under: refusing an id the client cannot name (id-only input is the degraded mode)
  local unknown, noName = O.ResolveId("spell", "99999")
  assertEqual(unknown, 99999)
  assertNil(noName, "an unknown id resolves with no name")
end)

test("ResolveId: every link form resolves, for its own kind only", function()
  local O = Fixture.new()
  seedIds()
  assertEqual(O.ResolveId("spell", "|cff71d5ff|Hspell:21562:0|h[Power Word: Fortitude]|h|r"), 21562)
  assertEqual(O.ResolveId("item", "|cffffffff|Hitem:6948::::::::80:::::|h[Hearthstone]|h|r"), 6948)
  assertEqual(O.ResolveId("currency", "|cffffffff|Hcurrency:3008:0|h[Valorstones]|h|r"), 3008)
  assertEqual(O.ResolveId("spell", "spell:21562"), 21562)
  assertEqual(O.ResolveId("item", "item:6948"), 6948)
  assertEqual(O.ResolveId("currency", "currency:3008"), 3008)
  -- red under: one link pattern for every kind (an item link would add item 6948 as a spell)
  local id, reason = O.ResolveId("spell", "|cffffffff|Hitem:6948|h[Hearthstone]|h|r")
  assertNil(id); assertEqual(reason, "notFound")
end)

test("ResolveId: a spell name the client knows resolves to its id", function()
  local O = Fixture.new()
  seedIds()
  local id, name, icon = O.ResolveId("spell", "power word: fortitude")
  -- red under: a case-sensitive lookup (players type names in lower case)
  assertEqual(id, 21562); assertEqual(name, "Power Word: Fortitude"); assertEqual(icon, 135987)
  local item, itemName = O.ResolveId("item", "HEARTHSTONE")
  assertEqual(item, 6948); assertEqual(itemName, "Hearthstone")
end)

test("ResolveId: a name the client cannot look up is found among the host's candidates", function()
  local O = Fixture.new()
  seedIds()
  local candidates = function() return { 2914, 3008 } end
  local id, name, icon = O.ResolveId("currency", "valorstones", candidates)
  -- red under: no candidates step (a currency has no client name lookup at all)
  assertEqual(id, 3008); assertEqual(name, "Valorstones"); assertEqual(icon, 5872049)
  local none, reason = O.ResolveId("currency", "valorstones")
  assertNil(none); assertEqual(reason, "notFound", "with no candidates there is nothing to search")
end)

test("ResolveId: two candidates with the name are ambiguous, one listed twice is not", function()
  local O = Fixture.new()
  seedIds()
  local id, reason = O.ResolveId("currency", "crest", function() return { 2914, 2915 } end)
  -- red under: taking the first match (the player would get a currency they did not mean)
  assertNil(id); assertEqual(reason, "ambiguous")
  -- red under: counting matches rather than distinct ids
  assertEqual(O.ResolveId("currency", "crest", function() return { 2914, 2914 } end), 2914)
end)

test("ResolveId: nothing typed is empty, and an unknown name is not found", function()
  local O = Fixture.new()
  seedIds()
  local id, reason = O.ResolveId("spell", "   ")
  assertNil(id); assertEqual(reason, "empty")
  assertEqual(select(2, O.ResolveId("spell", nil)), "empty")
  id, reason = O.ResolveId("spell", "Shadow Word: Pain")
  assertNil(id); assertEqual(reason, "notFound")
  -- A raising candidates() is a host bug, and costs the name step rather than the player's click.
  id, reason = O.ResolveId("spell", "Shadow Word: Pain", function() error("boom") end)
  assertNil(id); assertEqual(reason, "notFound")
end)

test("ResolveId: a custom kind's resolver is handed everything typed", function()
  local O = Fixture.new()
  local seen
  local kind = { noun = "thing", resolve = function(text)
    seen = text
    if text == "42" then return -42, "Forty-two", 7 end
    if text == "twin" then return nil, "ambiguous" end
    if text == "boom" then error("resolver exploded") end
    return nil
  end }
  local id, name, icon = O.ResolveId(kind, " 42 ")
  -- red under: parsing a number before the resolver (a host that stores spells as -id could not)
  assertEqual(id, -42); assertEqual(name, "Forty-two"); assertEqual(icon, 7)
  assertEqual(seen, "42", "trimmed, and otherwise untouched")
  assertEqual(select(2, O.ResolveId(kind, "twin")), "ambiguous", "a resolver can say why")
  assertEqual(select(2, O.ResolveId(kind, "nope")), "notFound")
  assertEqual(select(2, O.ResolveId(kind, "boom")), "notFound", "a raising resolver finds nothing")
  assertEqual(select(2, O.ResolveId(kind, "")), "empty", "empty is decided before the resolver")
end)

test("ResolveId: with no client APIs a number still resolves and a name finds nothing", function()
  local O = Fixture.new()
  local savedSpell, savedItem = mocks.C_Spell, mocks.C_Item
  mocks.C_Spell, mocks.C_Item = nil, nil
  local ok, err = pcall(function()
    assertEqual(O.ResolveId("spell", "21562"), 21562)
    -- red under: an unguarded C_Spell (the whole input raises on a client without it)
    assertEqual(select(2, O.ResolveId("spell", "Power Word: Fortitude")), "notFound")
    assertEqual(select(2, O.ResolveId("item", "Hearthstone")), "notFound")
  end)
  mocks.C_Spell, mocks.C_Item = savedSpell, savedItem
  assertTrue(ok, tostring(err))
end)

--- One IdInput on a throwaway page, recording every onAdd.
local function inputBench(spec)
  local O, rec, ctx = bench()
  seedIds()
  local added = {}
  spec = spec or {}
  spec.kind = spec.kind or "spell"
  spec.onAdd = spec.onAdd or function(id) added[#added + 1] = id end
  local group, eb, add, status = O.IdInput(ctx, nil, spec)
  return { O = O, rec = rec, ctx = ctx, group = group, eb = eb, add = add, status = status,
           added = added }
end

--- Type into an edit box the way AceGUI's does, then press Enter.
local function typeEnter(eb, text)
  eb:SetText(text)
  eb:__fire("OnEnterPressed", text)
end

test("IdInput: an edit box and an Add button share a line, with a status line under them", function()
  local b = inputBench({ label = "Add spell", tooltip = "An id, a link or a name." })
  -- red under: O.IdInput absent (every host keeps its own id-only edit box)
  assertEqual(b.eb.type, "EditBox"); assertEqual(b.add.type, "Button")
  assertEqual(b.eb.labelText, "Add spell")
  assertNear(b.eb.relativeWidth, 0.78, 1e-6)
  assertNear(b.add.relativeWidth, 0.20, 1e-6)
  assertEqual(b.add.text, "Add")
  assertTrue(b.eb.buttonDisabled, "the edit box's own Okay button is hidden: Add is the button")
  assertEqual(b.status.type, "Label"); assertEqual(b.status.text, "")
  assertTrue(b.group.children[1] == b.eb and b.group.children[2] == b.add
    and b.group.children[3] == b.status, "all three in one group, in that order")
  local scroll = b.O.EnsureScroll(b.ctx)
  assertTrue(scroll.children[#scroll.children] == b.group, "added to the page's scroll")
  assertTrue(b.eb.callbacks.OnEnter ~= nil, "the tooltip is attached")
end)

test("IdInput: Enter with a valid name adds it once and clears the box", function()
  local b = inputBench()
  typeEnter(b.eb, "power word: fortitude")
  -- red under: Enter not wired (only the button would submit)
  assertEqual(#b.added, 1, "onAdd ran once")
  assertEqual(b.added[1], 21562, "with the resolved id")
  assertEqual(b.eb.text, "", "the box is cleared for the next one")
  assertEqual(b.status.text, "")
end)

test("IdInput: the Add button submits what was typed", function()
  local b = inputBench()
  b.eb:SetText("|Hspell:774|h[Rejuvenation]|h")
  b.add:__fire("OnClick")
  -- red under: the button resolving nothing (it would need Enter to be pressed first)
  assertEqual(b.added[1], 774)
end)

test("IdInput: a name that resolves to nothing says so inline and adds nothing", function()
  local b = inputBench()
  typeEnter(b.eb, "Shadow Word: Pain")
  -- red under: adding on a failed resolve, or failing silently
  assertEqual(#b.added, 0, "nothing added")
  -- red under: "that the game knows" (C_Spell.GetSpellInfo(name) answers only the spellbook)
  assertEqual(b.status.text, "No spell named 'Shadow Word: Pain' in your spellbook. " ..
    "Names work for spells in your spellbook and ones this list knows; otherwise use the id or " ..
    "shift-click a link.")
  assertTrue(b.status.color ~= nil and b.status.color.r == 1 and b.status.color.b == 0,
    "in orange")
  assertEqual(b.eb.text, "Shadow Word: Pain", "the text stays, so the player can correct it")
  typeEnter(b.eb, "21562")
  assertEqual(b.status.text, "", "a success clears the message")
end)

test("IdInput: an ambiguous name asks for the id, in the kind's own plural", function()
  local b = inputBench({ kind = "currency", candidates = function() return { 2914, 2915 } end })
  typeEnter(b.eb, "Crest")
  assertEqual(#b.added, 0)
  -- red under: pluralizing by adding "s" ("currencys")
  assertEqual(b.status.text,
    "Several currencies are named 'Crest' \226\128\148 pick one from the list, or use the id.")
end)

test("IdInput: the host can reword the button and the messages", function()
  local b = inputBench({ strings = { add = "Include", notFound = "Nope: {text}" } })
  assertEqual(b.add.text, "Include")
  typeEnter(b.eb, "zzz")
  -- red under: ignoring spec.strings (a localized host would show English)
  assertEqual(b.status.text, "Nope: zzz")
end)

test("IdInput: a raising onAdd is reported, and the box keeps its text", function()
  local b = inputBench({ onAdd = function() error("store exploded") end })
  b.rec.chat = {}
  typeEnter(b.eb, "zzz")
  typeEnter(b.eb, "21562")
  -- red under: an unguarded onAdd (a raise inside AceGUI's dispatch takes the frame's clicks down)
  assertTrue(table.concat(b.rec.chat, "\n"):find("store exploded", 1, true) ~= nil)
  assertEqual(b.eb.text, "21562", "the add did not happen, so the input is not cleared")
  assertEqual(b.status.text, "No spell named 'zzz' in your spellbook. " .. b.O.ID_NAME_HINT.spell,
    "and the status line is as it was")
end)

test("IdInput: the box and status line are cleared before onAdd, so onAdd may redraw the page", function()
  local b
  local seen = {}
  b = inputBench({ onAdd = function()
    seen.text, seen.status = b.eb.text, b.status.text
    -- What a synchronous redraw does: both widgets go back to AceGUI's pool, and the next render
    -- may take them. Anything written to them from here on lands on someone else's widget.
    b.eb.SetText = function() seen.touched = true end
    b.status.SetText = function() seen.touched = true end
    b.status.SetColor = function() seen.touched = true end
  end })
  typeEnter(b.eb, "zzz")
  typeEnter(b.eb, "21562")
  -- red under: clearing after onAdd returns (a host that redraws inside onAdd has its new page's
  -- widgets blanked -- ConsumableMaster and LootHistory each coded around it)
  assertEqual(seen.text, "", "the box was cleared before onAdd ran")
  assertEqual(seen.status, "", "and so was the status line")
  assertNil(seen.touched, "nothing touches either widget after onAdd returns")
end)

test("IdInput: drawn inside a disabled render, or with spec.disabled, it is disabled", function()
  local O, rec, ctx = bench()
  local eb, add
  local after = { Master = function(c)
    local _
    _, eb, add = O.IdInput(c, nil, { kind = "spell", onAdd = function() end })
  end }
  O.RenderRows(ctx, { rec.byPath.locked }, after, nil, { disabled = true })
  -- red under: the input ignoring the render's flag (a disabled page would still take ids)
  assertTrue(eb.disabled); assertTrue(add.disabled)
  local b = inputBench({ disabled = true })
  assertTrue(b.eb.disabled); assertTrue(b.add.disabled)
  assertNil(b.ctx.__renderDisabled, "the flag lives for the call only")
  local live = inputBench()
  assertNil(live.eb.disabled, "an input drawn normally is never touched")
end)

test("IdInput: with no AceGUI it draws nothing", function()
  withoutAceGUI(function()
    local O, _, ctx = bench()
    assertNil(O.IdInput(ctx, nil, { kind = "spell", onAdd = function() end }))
  end)
end)

--- One IdList on a throwaway page. `entries` is the host's list; every callback is recorded.
local function listBench(entries, spec)
  local O, rec, ctx = bench()
  seedIds()
  local log = { added = {}, removed = {}, toggled = {}, rebuilt = 0 }
  ctx.rebuild = function() log.rebuilt = log.rebuilt + 1 end
  spec = spec or {}
  spec.kind = spec.kind or "spell"
  spec.entries = spec.entries or function() return entries end
  spec.onAdd = function(id) log.added[#log.added + 1] = id end
  spec.onRemove = function(id) log.removed[#log.removed + 1] = id end
  spec.onToggle = function(id, on) log.toggled[#log.toggled + 1] = { id, on } end
  local lines = O.IdList(ctx, spec)
  return O, rec, ctx, lines, log
end

--- The input group an IdList drew: the first SimpleGroup in the scroll holding an EditBox.
local function listInput(O, ctx)
  for _, w in ipairs(O.EnsureScroll(ctx).children) do
    if w.children and w.children[1] and w.children[1].type == "EditBox" then
      return w.children[1], w.children[2], w.children[3]
    end
  end
end

test("IdList: one line per entry -- icon, name and gray id, then Remove or a checkbox", function()
  local O, _, ctx, lines = listBench({
    { id = 21562 }, { id = 99999 }, { id = 774, toggle = true, on = true },
  }, { heading = "Spells" })
  -- red under: O.IdList absent
  assertEqual(#lines, 3, "one line per entry, returned in order")
  local flat = Fixture.flatten(O.EnsureScroll(ctx))
  assertEqual(flat[1].type, "Heading"); assertEqual(flat[1].text, "Spells")
  assertTrue(listInput(O, ctx) ~= nil, "the input is drawn above the entries")

  local label, action = lines[1].children[1], lines[1].children[2]
  assertEqual(label.type, "InteractiveLabel")
  assertEqual(label.text, "Power Word: Fortitude |cff808080(21562)|r")
  assertEqual(label.image[1], 135987, "with its icon")
  assertEqual(action.type, "Button"); assertEqual(action.text, "Remove")
  -- red under: formatting a nil name (the line would raise, or read "nil")
  assertEqual(lines[2].children[1].text, "Unknown spell 99999")
  local toggle = lines[3].children[2]
  assertEqual(toggle.type, "CheckBox", "a toggle entry gets a checkbox instead of Remove")
  assertTrue(toggle.value, "seeded from the entry")
end)

test("IdList: Remove and a toggle call the host back, and Remove asks for a rebuild", function()
  local _, _, _, lines, log = listBench({ { id = 21562 }, { id = 774, toggle = true, on = true } })
  lines[1].children[2]:__fire("OnClick")
  -- red under: Remove not wired to onRemove
  assertEqual(log.removed[1], 21562)
  -- red under: no rebuild after a remove (the removed line would stay on screen)
  assertEqual(log.rebuilt, 1, "the list's shape changed, so the page is rebuilt")
  lines[2].children[2]:__fire("OnValueChanged", false)
  assertEqual(log.toggled[1][1], 774)
  assertEqual(log.toggled[1][2], false)
end)

test("IdList: an add through its input reaches onAdd and rebuilds the list", function()
  local O, _, ctx, _, log = listBench({})
  local eb = listInput(O, ctx)
  typeEnter(eb, "rejuvenation")
  assertEqual(log.added[1], 774)
  -- red under: IdList not rebuilding after an add (the new entry would not appear)
  assertEqual(log.rebuilt, 1)
end)

test("IdList: with no ctx.rebuild the library's structural refresh redraws it", function()
  local O, _, ctx = bench()
  seedIds()
  local refreshed = 0
  local real = O.RefreshAllPanels
  O.RefreshAllPanels = function() refreshed = refreshed + 1 end
  local lines = O.IdList(ctx, { kind = "spell", entries = function() return { { id = 21562 } } end,
                                onRemove = function() end })
  lines[1].children[2]:__fire("OnClick")
  O.RefreshAllPanels = real
  -- red under: no fallback when the host sets no ctx.rebuild
  assertEqual(refreshed, 1)
end)

test("IdList: an empty list shows the host's empty text", function()
  local O, _, ctx, lines = listBench({}, { emptyText = "No spells added." })
  assertEqual(#lines, 0)
  -- red under: drawing nothing for an empty list (the page reads as broken)
  local found = false
  for _, w in ipairs(Fixture.flatten(O.EnsureScroll(ctx))) do
    if w.type == "Label" and w.text == "No spells added." then found = true end
  end
  assertTrue(found, "the empty text is on the page")
end)

--- Run `fn(requests)` with every C_Item.RequestLoadItemDataByID counted per id (and in total, as
--- `requests.total`), on an empty timer queue; the real request is put back however `fn` ends.
local function countingLoads(fn)
  local requests = { total = 0 }
  local realRequest = mocks.C_Item.RequestLoadItemDataByID
  mocks.C_Item.RequestLoadItemDataByID = function(id)
    requests.total = requests.total + 1
    requests[id] = (requests[id] or 0) + 1
    realRequest(id)
  end
  mocks.__timers = {}
  local ok, err = pcall(fn, requests)
  mocks.C_Item.RequestLoadItemDataByID = realRequest
  assertTrue(ok, tostring(err))
end

test("IdList: an uncached item asks to load, and the list redraws once its name lands", function()
  countingLoads(function(requests)
    local O, _, ctx, lines, log = listBench({ { id = 2589 }, { id = 6948 } }, { kind = "item" })
    assertEqual(lines[1].children[1].text, "Unknown item 2589", "no name until it is cached")
    -- red under: never asking the client for the item (its name would never arrive)
    assertEqual(requests.total, 1, "one request, for the uncached item only")
    mocks.addIdRecord("item", 2589, "Linen Cloth", 132889)
    mocks.__fireTimers()
    -- red under: a load callback that redraws nothing
    assertEqual(log.rebuilt, 1, "the load rebuilt the list")
    assertEqual(#mocks.__timers, 0, "a landed item is not asked for again")
    O.IdList(ctx, { kind = "item", entries = function() return { { id = 2589 } } end })
    assertEqual(requests.total, 1, "a named item needs no request")
  end)
end)

test("IdList: an item's name is colored by its quality; a spell's and a currency's are not", function()
  local O, _, ctx, lines = listBench({ { id = 6948 }, { id = 19019 } }, { kind = "item" })
  -- red under: an item name drawn plain (BankLedger and LootHistory colored theirs by quality)
  assertEqual(lines[1].children[1].text, "|cffffffffHearthstone|r |cff808080(6948)|r")
  assertEqual(lines[2].children[1].text, "|cffff8000Thunderfury|r |cff808080(19019)|r")
  local spell = O.IdList(ctx, { kind = "spell", entries = function() return { { id = 21562 } } end })
  assertEqual(spell[1].children[1].text, "Power Word: Fortitude |cff808080(21562)|r")
  local currency = O.IdList(ctx, { kind = "currency", entries = function() return { { id = 3008 } } end })
  assertEqual(currency[1].children[1].text, "Valorstones |cff808080(3008)|r")
end)

test("IdList: an item with no quality yet, or no palette for it, is drawn uncolored", function()
  local O, _, ctx, lines = listBench({ { id = 2589 }, { id = 777001 } }, { kind = "item" })
  mocks.__timers = {}
  assertEqual(lines[1].children[1].text, "Unknown item 2589", "an uncached item is not colored")
  assertEqual(lines[2].children[1].text, "Nameless Quality |cff808080(777001)|r",
    "a named item the client answers no quality for is drawn plain")
  mocks.addIdRecord("item", 2589, "Linen Cloth", 132889, nil, 1)
  local landed = O.IdList(ctx, { kind = "item", entries = function() return { { id = 2589 } } end })
  assertEqual(landed[1].children[1].text, "|cffffffffLinen Cloth|r |cff808080(2589)|r",
    "the redraw after the load colors it")
  local palette = mocks.ITEM_QUALITY_COLORS
  mocks.ITEM_QUALITY_COLORS = nil
  local ok, bare = pcall(O.IdList, ctx, { kind = "item", entries = function() return { { id = 6948 } } end })
  mocks.ITEM_QUALITY_COLORS = palette
  assertTrue(ok, tostring(bare))
  -- red under: indexing a missing palette (the line would be lost to its guard)
  assertEqual(bare[1].children[1].text, "Hearthstone |cff808080(6948)|r")
end)

test("IdList: uncached items load as one batch -- one timer and one rebuild, however many", function()
  countingLoads(function(requests)
    local entries = {}
    for i = 1, 20 do entries[i] = { id = 900000 + i } end
    local _, _, _, _, log = listBench(entries, { kind = "item" })
    assertEqual(requests.total, 20, "every uncached item is asked for")
    -- red under: one timer per id (twenty full page renders landing in the same frame)
    assertEqual(#mocks.__timers, 1, "one check for the whole batch")
    for i = 1, 20 do mocks.addIdRecord("item", 900000 + i, "Item " .. i, 1) end
    mocks.__fireTimers()
    assertEqual(log.rebuilt, 1, "one rebuild draws every name that landed")
  end)
end)

test("IdList: an item not cached by the check is asked for again, a bounded number of times", function()
  countingLoads(function(requests)
    local _, _, _, _, log = listBench({ { id = 2589 } }, { kind = "item" })
    mocks.__fireTimers()
    -- red under: giving up after one fixed delay (a slow load reads "Unknown item" until some
    -- unrelated redraw)
    assertEqual(requests[2589], 2, "asked again once the first check found no name")
    assertEqual(log.rebuilt, 0, "nothing landed, so nothing is redrawn")
    mocks.addIdRecord("item", 2589, "Linen Cloth", 132889)
    mocks.__fireTimers()
    assertEqual(log.rebuilt, 1, "the retry's check redraws the name that landed")
    assertEqual(#mocks.__timers, 0)

    -- An id the client does not have never loads: the asks stop.
    local _, _, _, _, never = listBench({ { id = 999001 } }, { kind = "item" })
    local rounds = 0
    while #mocks.__timers > 0 and rounds < 50 do
      mocks.__fireTimers()
      rounds = rounds + 1
    end
    -- red under: re-requesting for ever (an id the client never loads would loop forever)
    assertTrue(rounds < 50, "the asks stop on their own")
    assertEqual(requests[999001], 5, "five asks, then the entry stays unnamed")
    assertEqual(never.rebuilt, 0)
  end)
end)

test("IdList: an entry's label shows the client's own tooltip for it", function()
  local _, _, _, lines = listBench({ { id = 21562 } })
  local tip, seen = mocks.GameTooltip, {}
  local saved = rawget(tip, "SetSpellByID")
  tip.SetSpellByID = function(_, id) seen.id = id end
  local label = lines[1].children[1]
  local ok, err = pcall(label.__fire, label, "OnEnter")
  tip.SetSpellByID = saved
  assertTrue(ok, tostring(err))
  -- red under: no tooltip on the entry label
  assertEqual(seen.id, 21562)
end)

--- Hover an entry's label with GameTooltip's `method` spied; answers the id it was handed.
local function hoverWith(label, method)
  local tip, seen = mocks.GameTooltip, {}
  local saved = rawget(tip, method)
  tip[method] = function(_, id) seen.id = id end
  local ok, err = pcall(label.__fire, label, "OnEnter")
  tip[method] = saved
  assertTrue(ok, tostring(err))
  return seen.id
end

test("IdList: a host kind with base = \"item\" wears the item kind's color, tooltip and loads", function()
  -- ConsumableMaster's shape: its own resolve (existence checks the library does not know), and
  -- ids that are items. Without `base` it gets none of the item kind's decorations.
  local kind = { noun = "potion", plural = "potions", base = "item",
                 resolve = function(text) return tonumber(text) end }
  local O, _, ctx, lines = listBench({ { id = 6948 }, { id = 19019 }, { id = 2589 } }, { kind = kind })
  mocks.__timers = {}
  -- red under: NAME_COLOR keyed by the library's kind table alone (a host kind's names drawn plain)
  assertEqual(lines[1].children[1].text, "|cffffffffHearthstone|r |cff808080(6948)|r",
    "the item kind's quality color, and its info names the entry")
  assertEqual(lines[2].children[1].text, "|cffff8000Thunderfury|r |cff808080(19019)|r")
  assertEqual(lines[3].children[1].text, "Unknown potion 2589", "the host's own noun wins")
  assertEqual(hoverWith(lines[1].children[1], "SetItemByID"), 6948, "the item kind's tooltip")
  assertEqual(table.concat(O.UnnamedCandidates(kind, function() return { 2589, 6948 } end), ","),
    "2589", "the item kind's loads and info: its unnamed candidates are pre-warmed and looked up")

  -- A field the host sets itself wins over the base's.
  local own
  own = { noun = "potion", base = "item", resolve = kind.resolve,
          tooltip = function(_, id) own.shown = id end }
  local mine = O.IdList(ctx, { kind = own, entries = function() return { { id = 6948 } } end })
  assertEqual(hoverWith(mine[1].children[1], "SetItemByID"), nil, "not the base's tooltip")
  assertEqual(own.shown, 6948, "the host's own")
end)

test("IdList: a host kind without base, or with a base no library kind has, is drawn as before", function()
  local itemName = function(id) return mocks.C_Item.GetItemNameByID(id) end
  for _, base in ipairs({ false, "widget" }) do
    local kind = { noun = "potion", base = base or nil, info = itemName, loads = true,
                   resolve = function(text) return tonumber(text) end }
    local O, _, _, lines = listBench({ { id = 6948 } }, { kind = kind })
    -- red under: a decoration read off every host kind (a host's own ids need not be items)
    assertEqual(lines[1].children[1].text, "Hearthstone |cff808080(6948)|r", "plain, as today")
    assertNil(hoverWith(lines[1].children[1], "SetItemByID"), "no tooltip it did not declare")
    assertEqual(table.concat(O.UnnamedCandidates(kind, function() return { 2589 } end), ","), "2589",
      "its own loads and info still count")
  end
end)

test("IdList: a raising entries() is reported and still draws the input", function()
  local O, rec, ctx = bench()
  rec.chat = {}
  local lines = O.IdList(ctx, { kind = "spell", entries = function() error("list exploded") end })
  -- red under: an unguarded entries() (the whole page stops at the list)
  assertEqual(#lines, 0)
  assertTrue(listInput(O, ctx) ~= nil, "the input is still there to add with")
  assertTrue(table.concat(rec.chat, "\n"):find("list exploded", 1, true) ~= nil)
end)

test("IdList: drawn disabled, every Remove and checkbox is disabled", function()
  local _, _, _, lines = listBench({ { id = 21562 }, { id = 774, toggle = true } }, { disabled = true })
  -- red under: entries ignoring the disable (a disabled page would still remove ids)
  assertTrue(lines[1].children[2].disabled)
  assertTrue(lines[2].children[2].disabled)
end)

test("IdList: with no AceGUI it draws nothing", function()
  withoutAceGUI(function()
    local O, _, ctx = bench()
    assertNil(O.IdList(ctx, { kind = "spell", entries = function() return {} end }))
  end)
end)

-- ── a name among uncached candidates, the name hint, and a shared name ──────────────────────
--
-- The client's item-name lookup answers only for an item the player carries, or carried this
-- session. ConsumableMaster's owner typed "Potion of the Hushed Zephyr" (three crafted-quality ranks
-- share the name, none in the bags) into Add-by-ID and read "No item matches". There is no client
-- item-name search: a name reaches an item through that lookup or through the host's candidates,
-- and a candidate the client has not cached has no name to match until it is loaded.

local ZEPHYR = "Potion of the Hushed Zephyr"
local ELLIPSIS = "\226\128\166"
local ITEM_HINT = "Names work for items you carry (or carried this session) and ones this list " ..
  "knows; otherwise use the id or shift-click a link."

--- The three ranks sharing one name: uncached, unless `cached` names them.
local function seedZephyr(cached)
  cached = cached or {}
  for _, id in ipairs({ 191395, 191396, 191397 }) do
    mocks.addIdRecord("item", id, ZEPHYR, 4638, not cached[id], 1)
  end
end
local function zephyrs() return { 191395, 191396, 191397 } end

--- Fire the timer queue until it is empty, or `limit` rounds. Answers how many rounds ran.
local function drainTimers(limit)
  local rounds = 0
  while #mocks.__timers > 0 and rounds < limit do
    mocks.__fireTimers()
    rounds = rounds + 1
  end
  return rounds
end

test("ResolveId: a client name hit another candidate shares its name with is ambiguous", function()
  local O = Fixture.new()
  seedIds()
  seedZephyr({ [191395] = true, [191396] = true })
  assertEqual(O.ResolveId("item", ZEPHYR), 191395, "with no candidates the client's answer stands")
  local id, reason = O.ResolveId("item", ZEPHYR, zephyrs)
  -- red under: returning the client's hit before reading the candidates (one rank added silently)
  assertNil(id); assertEqual(reason, "ambiguous")
  assertEqual(O.ResolveId("item", ZEPHYR, function() return { 191395, 191397 } end), 191395,
    "a candidate the client cannot name yet is not a second match")
  assertEqual(O.ResolveId("item", "hearthstone", function() return { 6948, 191396 } end), 6948,
    "the client's own id among the candidates is one match, not two")
  mocks.addIdRecord("spell", 900001, "Twin Strike", 1)
  mocks.addIdRecord("spell", 900002, "Twin Strike", 2)
  assertEqual(select(2, O.ResolveId("spell", "twin strike", function() return { 900002 } end)),
    "ambiguous", "a spell the client names and a different candidate spell")
end)

test("UnnamedCandidates: the item candidates the client cannot name yet, each once, capped", function()
  local O = Fixture.new()
  seedIds()
  seedZephyr({ [191396] = true })
  -- red under: O.UnnamedCandidates absent (the widget has nothing to ask the client for)
  local ids = O.UnnamedCandidates("item", function() return { 6948, 191395, 191396, 191397, 191395 } end)
  assertEqual(table.concat(ids, ","), "191395,191397", "in the host's order, each once")
  local many = {}
  for i = 1, 300 do many[i] = 800000 + i end
  assertEqual(#O.UnnamedCandidates("item", function() return many end), 200, "capped at 200")
  assertEqual(#O.UnnamedCandidates("spell", function() return { 99999 } end), 0, "only items load")
  assertEqual(#O.UnnamedCandidates("currency", function() return { 99999 } end), 0)
  assertEqual(#O.UnnamedCandidates("item", function() error("boom") end), 0)
  assertEqual(#O.UnnamedCandidates("item"), 0)
  local real = mocks.C_Item.RequestLoadItemDataByID
  mocks.C_Item.RequestLoadItemDataByID = nil
  local ok, n = pcall(function() return #O.UnnamedCandidates("item", zephyrs) end)
  mocks.C_Item.RequestLoadItemDataByID = real
  assertTrue(ok, tostring(n))
  assertEqual(n, 0, "a client that cannot load an item has none to wait for")
end)

test("IdInput: a name among uncached candidates is looked up, and added once it lands", function()
  countingLoads(function(requests)
    local b = inputBench({ kind = "item", candidates = function() return { 6948, 191396 } end })
    seedZephyr()
    local before = requests.total
    typeEnter(b.eb, ZEPHYR)
    -- red under: no lookup (a candidate the client has not cached can never match a name)
    assertEqual(#b.added, 0, "nothing added yet")
    assertEqual(b.status.text, "Looking up items" .. ELLIPSIS)
    assertTrue(b.status.color.r == 1 and b.status.color.g == 1 and b.status.color.b == 1,
      "in a neutral color, not the failure orange")
    assertEqual(requests.total - before, 1, "the one unnamed candidate is asked for")
    assertEqual(#mocks.__timers, 1, "one check for the whole lookup")
    assertEqual(b.eb.text, ZEPHYR, "the text stays while it looks")
    mocks.addIdRecord("item", 191396, ZEPHYR, 4638, nil, 1)
    mocks.__fireTimers()
    assertEqual(#b.added, 1, "the retry adds it, once")
    assertEqual(b.added[1], 191396)
    assertEqual(b.eb.text, ""); assertEqual(b.status.text, "")
  end)
end)

test("IdInput: a lookup waits for every candidate it asked for, then refuses a shared name", function()
  countingLoads(function(requests)
    local b = inputBench({ kind = "item", candidates = zephyrs })
    seedZephyr()
    typeEnter(b.eb, ZEPHYR)
    local asked395, asked396 = requests[191395], requests[191396]
    seedZephyr({ [191395] = true })
    mocks.__fireTimers()
    -- red under: retrying as soon as one lands (rank 1 alone would be added, though two more ranks
    -- share its name)
    assertEqual(#b.added, 0)
    assertEqual(b.status.text, "Looking up items" .. ELLIPSIS, "still waiting on two")
    assertEqual(requests[191396], asked396 + 1, "the ones still unnamed are asked for again")
    assertEqual(requests[191395], asked395, "a landed one is not")
    seedZephyr({ [191395] = true, [191396] = true, [191397] = true })
    mocks.__fireTimers()
    -- red under: adding one rank of a shared name (the owner's decision: never silently one rank)
    assertEqual(#b.added, 0, "neither one rank nor all of them")
    assertEqual(b.status.text, "Several items are named '" .. ZEPHYR ..
      "' \226\128\148 pick one from the list, or use the id.")
    assertTrue(b.status.color.r == 1 and b.status.color.b == 0, "in orange")
    assertEqual(b.eb.text, ZEPHYR, "the text stays")
    assertEqual(#mocks.__timers, 0)
  end)
end)

test("IdInput: a lookup that never lands gives up after a bounded wait, with the honest reason", function()
  countingLoads(function(requests)
    local b = inputBench({ kind = "item", candidates = function() return { 999001 } end })
    typeEnter(b.eb, ZEPHYR)
    local asked = requests[999001]
    local rounds = drainTimers(50)
    -- red under: re-asking for ever (an id the client does not have never loads)
    assertTrue(rounds < 50, "the wait ends on its own")
    assertEqual(requests[999001] - asked, 4, "five asks in all, the submit's included")
    assertEqual(#b.added, 0)
    assertEqual(b.status.text, "No item named '" .. ZEPHYR .. "' that the game can find. " .. ITEM_HINT)
    assertTrue(b.status.color.r == 1 and b.status.color.b == 0, "in orange")
  end)
end)

test("IdInput: a second submit, a changed box or a released box drops a pending lookup", function()
  countingLoads(function()
    local b = inputBench({ kind = "item", candidates = function() return { 191396 } end })
    seedZephyr()
    typeEnter(b.eb, ZEPHYR)
    typeEnter(b.eb, "6948")
    assertEqual(b.added[1], 6948)
    seedZephyr({ [191396] = true })
    drainTimers(10)
    -- red under: a stale lookup landing after a newer submit (the old name added behind its back)
    assertEqual(#b.added, 1, "the replaced lookup adds nothing")
    assertEqual(b.status.text, "", "and leaves the status line alone")

    local c = inputBench({ kind = "item", candidates = function() return { 191396 } end })
    seedZephyr()
    typeEnter(c.eb, ZEPHYR)
    c.eb:SetText("Hearth")
    seedZephyr({ [191396] = true })
    drainTimers(10)
    assertEqual(#c.added, 0, "a box the player typed over is not submitted for them")
    assertEqual(c.status.text, "", "the looking line goes")
    assertEqual(c.eb.text, "Hearth")

    local d = inputBench({ kind = "item", candidates = function() return { 191396 } end })
    seedZephyr()
    typeEnter(d.eb, ZEPHYR)
    local touched
    d.eb:Release()
    d.status.SetText = function() touched = true end
    d.eb.SetText = function() touched = true end
    seedZephyr({ [191396] = true })
    drainTimers(10)
    -- red under: a lookup writing to widgets AceGUI's pool may have handed to another page
    assertEqual(#d.added, 0)
    assertNil(touched, "nothing touches a released box or its status line")
  end)
end)

test("IdInput and IdList: built with item candidates, they ask for the unnamed ones up front", function()
  countingLoads(function(requests)
    local O, _, ctx = bench()
    seedIds()
    seedZephyr({ [191396] = true })
    O.IdInput(ctx, nil, { kind = "item", candidates = zephyrs, onAdd = function() end })
    -- red under: no pre-warm (a name among the host's candidates misses on the first try)
    assertEqual(requests[191395], 1); assertEqual(requests[191397], 1)
    assertNil(requests[191396], "a named candidate is not asked for")
    assertEqual(#mocks.__timers, 0, "a pre-warm waits for nothing")
    O.IdList(ctx, { kind = "item", candidates = zephyrs, entries = function() return {} end })
    assertEqual(requests.total, 2, "once per id per instance, however many renders")
    O.IdInput(ctx, nil, { kind = "spell", candidates = function() return { 99999 } end,
                          onAdd = function() end })
    assertEqual(requests.total, 2, "spells are not loaded")
    local many = {}
    for i = 1, 300 do many[i] = 800000 + i end
    O.IdInput(ctx, nil, { kind = "item", candidates = function() return many end, onAdd = function() end })
    assertEqual(requests.total, 202, "at most 200 a build")
    local saved = mocks.C_Item
    mocks.C_Item = nil
    local ok, err = pcall(O.IdInput, ctx, nil, { kind = "item", candidates = zephyrs, onAdd = function() end })
    mocks.C_Item = saved
    assertTrue(ok, tostring(err))
  end)
end)

test("IdInput: a name that finds nothing says where names work, per kind; the hint is exported", function()
  local O = Fixture.new()
  -- red under: no exported hint (a host's tooltip would restate the rule, and drift from it)
  assertEqual(O.ID_NAME_HINT.item, ITEM_HINT)
  assertEqual(O.ID_NAME_HINT.spell,
    "Names work for spells in your spellbook and ones this list knows; otherwise use the id or " ..
    "shift-click a link.")
  assertEqual(O.ID_NAME_HINT.currency,
    "Currency names work only for the currencies this list knows; otherwise use the id or " ..
    "shift-click a link.")
  O.ID_NAME_HINT.item = "changed"
  local other = Fixture.new()
  assertEqual(other.ID_NAME_HINT.item, ITEM_HINT, "each instance has its own copy")
  -- red under: one table shared by every instance (the new one rewrote the first one's change)
  assertEqual(O.ID_NAME_HINT.item, "changed", "a later instance leaves the first one's alone")
  assertTrue(not rawequal(O.ID_NAME_HINT, other.ID_NAME_HINT), "two tables, not one")

  local item = inputBench({ kind = "item" })
  typeEnter(item.eb, "Nope")
  -- red under: the old bare "No item named" (it reads as if the item does not exist)
  assertEqual(item.status.text, "No item named 'Nope' that the game can find. " .. ITEM_HINT)
  local currency = inputBench({ kind = "currency" })
  typeEnter(currency.eb, "Nope")
  assertEqual(currency.status.text, "No currency named 'Nope' that this list knows. " ..
    currency.O.ID_NAME_HINT.currency)
  local thing = inputBench({ kind = { noun = "thing" } })
  typeEnter(thing.eb, "Nope")
  assertEqual(thing.status.text, "No thing named 'Nope'.", "a host kind keeps the plain words")
  local custom = inputBench({ kind = "item", strings = { nameHint = "Custom hint." } })
  typeEnter(custom.eb, "Nope")
  assertEqual(custom.status.text, "No item named 'Nope' that the game can find. Custom hint.")
end)

test("IdInput: the looking line can be reworded", function()
  countingLoads(function()
    local b = inputBench({ kind = "item", candidates = function() return { 191396 } end,
                           strings = { looking = "Searching {plural} for '{text}'" } })
    seedZephyr()
    typeEnter(b.eb, ZEPHYR)
    -- red under: a hard-coded looking line (a localized host would show English)
    assertEqual(b.status.text, "Searching items for '" .. ZEPHYR .. "'")
  end)
end)

local AMBIGUOUS_ZEPHYR = "Several items are named '" .. ZEPHYR ..
  "' \226\128\148 pick one from the list, or use the id."

test("IdInput: a client hit on one rank waits for the uncached ranks, then refuses the name", function()
  countingLoads(function(requests)
    -- Rank 1 is in the bags (the client's name lookup answers it); ranks 2 and 3 are candidates the
    -- client has not cached, so nothing can tell yet that they share its name.
    local b = inputBench({ kind = "item", candidates = zephyrs })
    seedZephyr({ [191395] = true })
    typeEnter(b.eb, ZEPHYR)
    -- red under: adding the client's hit at once (one rank of a shared name, added silently)
    assertEqual(#b.added, 0, "nothing added while two candidates are unnamed")
    assertEqual(b.status.text, "Looking up items" .. ELLIPSIS)
    assertTrue(requests[191396] ~= nil and requests[191397] ~= nil, "the unnamed ranks are asked for")
    seedZephyr({ [191395] = true, [191396] = true, [191397] = true })
    drainTimers(10)
    assertEqual(#b.added, 0, "neither one rank nor all of them")
    assertEqual(b.status.text, AMBIGUOUS_ZEPHYR)
    assertEqual(b.eb.text, ZEPHYR, "the text stays")

    -- The rank in the bags need not be a candidate: the other two still share its name.
    local c = inputBench({ kind = "item", candidates = function() return { 191396, 191397 } end })
    seedZephyr({ [191395] = true })
    typeEnter(c.eb, ZEPHYR)
    assertEqual(#c.added, 0)
    seedZephyr({ [191395] = true, [191396] = true, [191397] = true })
    drainTimers(10)
    assertEqual(#c.added, 0)
    assertEqual(c.status.text, AMBIGUOUS_ZEPHYR)
  end)
end)

test("IdInput: a name hit waits on unnamed candidates, then adds; a number or a link never waits", function()
  countingLoads(function(requests)
    local b = inputBench({ kind = "item", candidates = function() return { 6948, 2589 } end })
    typeEnter(b.eb, "Hearthstone")
    -- red under: no wait (the uncached candidate could have carried the same name)
    assertEqual(#b.added, 0, "waits while a candidate is unnamed")
    assertEqual(b.status.text, "Looking up items" .. ELLIPSIS)
    mocks.addIdRecord("item", 2589, "Linen Cloth", 132889, nil, 1)
    drainTimers(10)
    assertEqual(#b.added, 1, "a name no other candidate carries is added once they land")
    assertEqual(b.added[1], 6948)

    local c = inputBench({ kind = "item", candidates = function() return { 6948, 2589 } end })
    local before = requests.total
    typeEnter(c.eb, "6948")
    assertEqual(c.added[1], 6948, "a number is added at once")
    typeEnter(c.eb, "|cffffffff|Hitem:19019::::::::|h[Thunderfury]|h|r")
    assertEqual(c.added[2], 19019, "a link is added at once")
    assertEqual(#mocks.__timers, 0, "neither waits")
    assertTrue(requests.total - before <= 1, "at most the pre-warm's one ask")
  end)
end)

--- ConsumableMaster's shape: a host kind whose `resolve` takes digits and links itself and hands a
--- name to O.ResolveId("item", text, candidates), with the item kind's words forwarded through
--- `__index`. `loads` and `info` are what opt it into the pre-warm and the lookup.
local function hostItemKind(O)
  local base = { lookup = "item", noun = "item", plural = "items", loads = true,
                 info = function(id) return mocks.C_Item.GetItemNameByID(id) end }
  return setmetatable({
    resolve = function(text, candidates)
      local id = tonumber(text:match("^%d+$")) or tonumber(text:match("item:(%d+)"))
      if id then return id end
      return O.ResolveId(base.lookup, text, candidates)
    end,
  }, { __index = function(_, key) return base[key] end })
end

test("IdInput: a host kind with resolve, loads and info is looked up, and refuses a shared name", function()
  countingLoads(function(requests)
    local O, _, ctx = bench()
    seedIds()
    seedZephyr()
    local added = {}
    local function onAdd(id) added[#added + 1] = id end
    local strings = { notFound = "No {noun} named '{text}'. {hint}", nameHint = "Host hint." }
    local kind = hostItemKind(O)
    assertEqual(table.concat(O.UnnamedCandidates(kind, zephyrs), ","), "191395,191396,191397")
    local _, eb, _, status = O.IdInput(ctx, nil, { kind = kind, candidates = zephyrs,
                                                   strings = strings, onAdd = onAdd })
    assertEqual(requests[191395], 1, "pre-warmed through the host kind")
    typeEnter(eb, ZEPHYR)
    assertEqual(status.text, "Looking up items" .. ELLIPSIS)
    seedZephyr({ [191395] = true, [191396] = true, [191397] = true })
    drainTimers(10)
    assertEqual(#added, 0, "no rank added")
    assertEqual(status.text, AMBIGUOUS_ZEPHYR)

    -- One rank in the bags, the others unnamed: the host's own resolver answers the client's hit,
    -- and the widget still waits.
    local O2, _, ctx2 = bench()
    seedIds()
    seedZephyr({ [191395] = true })
    local _, eb2, _, status2 = O2.IdInput(ctx2, nil, { kind = hostItemKind(O2), candidates = zephyrs,
                                                       strings = strings, onAdd = onAdd })
    typeEnter(eb2, ZEPHYR)
    -- red under: a host resolver's hit added before the unnamed ranks land
    assertEqual(#added, 0)
    seedZephyr({ [191395] = true, [191396] = true, [191397] = true })
    drainTimers(10)
    assertEqual(#added, 0)
    assertEqual(status2.text, AMBIGUOUS_ZEPHYR)

    local plain = setmetatable({ resolve = hostItemKind(O).resolve },
      { __index = { noun = "item", plural = "items" } })
    assertEqual(#O.UnnamedCandidates(plain, zephyrs), 0, "a host kind without loads is not looked up")
  end)
end)

test("IdInput: a second submit of the same text replaces the pending lookup", function()
  countingLoads(function()
    local calls = 0
    local b = inputBench({ kind = "item",
                           candidates = function() calls = calls + 1; return zephyrs() end })
    seedZephyr()
    typeEnter(b.eb, ZEPHYR)
    seedZephyr({ [191395] = true, [191396] = true, [191397] = true })
    typeEnter(b.eb, ZEPHYR)
    assertEqual(b.status.text, AMBIGUOUS_ZEPHYR, "the second submit answers on its own")
    local before = calls
    drainTimers(10)
    -- red under: a submit that leaves the older lookup in place (its check resolves the text again)
    assertEqual(calls, before, "the first lookup's check does nothing")
    assertEqual(b.status.text, AMBIGUOUS_ZEPHYR)

    local c = inputBench({ kind = "item", candidates = zephyrs })
    seedZephyr()
    typeEnter(c.eb, ZEPHYR)
    typeEnter(c.eb, "")
    drainTimers(10)
    assertEqual(c.status.text, "Type an id, a link or a name.",
      "an empty submit's message is not wiped by the lookup it replaced")
  end)
end)

test("IdInput: ids a lookup could not load are skipped, so later candidates get their turn", function()
  countingLoads(function(requests)
    local list = {}
    for i = 1, 200 do list[i] = 900000 + i end -- never load: retired or invalid ids
    list[201] = 191396
    local b = inputBench({ kind = "item", candidates = function() return list end })
    mocks.addIdRecord("item", 191396, "Rare Draught", 4638, true, 1)
    typeEnter(b.eb, "Rare Draught")
    assertNil(requests[191396], "past the cap: neither the pre-warm nor the first window asks")
    drainTimers(5)
    -- red under: a lookup that stops at the first 200 (a name among later candidates never resolves)
    assertEqual(requests[191396], 1, "the first window exhausted, the next one asks for it")
    assertEqual(b.status.text, "Looking up items" .. ELLIPSIS, "still looking")
    assertEqual(#b.added, 0)
    mocks.addIdRecord("item", 191396, "Rare Draught", 4638, nil, 1)
    drainTimers(10)
    assertEqual(b.added[1], 191396, "added once the later candidate lands")
    assertEqual(requests[900001], 6, "a dead id: the pre-warm's ask and the lookup's five")
    local asked = requests.total
    typeEnter(b.eb, "Nope")
    -- red under: re-asking the same dead ids on every Enter for the full wait
    assertEqual(requests.total, asked, "a later Enter does not ask for the dead ids again")
    assertEqual(b.status.text, "No item named 'Nope' that the game can find. " .. ITEM_HINT)
  end)
end)

test("IdInput: a lookup runs at most five windows of 200; the next Enter carries on past them", function()
  countingLoads(function(requests)
    local list = {}
    for i = 1, 1200 do list[i] = 900000 + i end -- none ever loads
    local b = inputBench({ kind = "item", candidates = function() return list end })
    typeEnter(b.eb, "Rare Draught")
    local rounds = drainTimers(100)
    assertTrue(rounds < 100, "the lookup ends on its own")
    assertEqual(requests[901000], 5, "the fifth window's last id was asked for")
    -- red under: windows without a bound (one typed name asking for every candidate there is)
    assertNil(requests[901001], "a sixth window is never asked for")
    assertEqual(b.status.text, "No item named 'Rare Draught' that the game can find. " .. ITEM_HINT)
    typeEnter(b.eb, "Rare Draught")
    assertEqual(requests[901001], 1, "the next Enter moves on to the ids after them")
    assertEqual(requests[900001], 6, "and never back to a dead one: the pre-warm's ask and five")
  end)
end)

test("IdInput and IdList: pre-warm moves past the ids it has asked for, and reads each id once", function()
  countingLoads(function(requests)
    local O, _, ctx = bench()
    seedIds()
    local many = {}
    for i = 1, 300 do many[i] = 800000 + i end
    local function draw()
      O.IdInput(ctx, nil, { kind = "item", candidates = function() return many end,
                            onAdd = function() end })
    end
    draw()
    assertEqual(requests.total, 200)
    draw()
    -- red under: a window that restarts at the first 200 (the last 100 are never warmed)
    assertEqual(requests.total, 300, "the second build warms the next ones")

    local reads = 0
    local realName = mocks.C_Item.GetItemNameByID
    mocks.C_Item.GetItemNameByID = function(id) reads = reads + 1; return realName(id) end
    local named = function() return { 6948, 19019 } end
    O.IdInput(ctx, nil, { kind = "item", candidates = named, onAdd = function() end })
    local first = reads
    O.IdList(ctx, { kind = "item", candidates = named, entries = function() return {} end })
    mocks.C_Item.GetItemNameByID = realName
    assertTrue(first > 0)
    -- red under: every draw rescanning every candidate's name
    assertEqual(reads, first, "a redraw does not read the candidates' names again")
  end)
end)

-- ── edit box (the fifth widget type) ───────────────────────────────────────────────────────

test("widgets: a string row asking for an EditBox gets one, not a dropdown", function()
  -- Ships in -1.0 because adding a widget TYPE later is additive, but retrofitting one into a
  -- frozen dispatch table is not. No AbsorbTracker row uses it; KickCD's label rows do.
  local eb, row = render("profileName")
  assertEqual(eb.type, "EditBox")
  assertEqual(eb.labelText, row.label)
  assertEqual(eb.text, "", "seeded from the store")
end)

test("widgets: an edit box commits on OnEnterPressed and re-reads on refresh", function()
  local eb, _, ctx, rec = render("profileName")
  eb:__fire("OnEnterPressed", "raiding")
  assertEqual(rec.store.profileName, "raiding")
  rec.store.profileName = "elsewhere"
  for _, fn in ipairs(ctx.refreshers) do fn() end
  assertEqual(eb.text, "elsewhere")
end)

-- ── colour picker ──────────────────────────────────────────────────────────────────────────

test("widgets: a color row renders a ColorPicker seeded through the descriptor's codec", function()
  local O, rec, ctx = bench()
  rec.store.barColor = { r = 0.1, g = 0.2, b = 0.3, a = 0.4 }
  local cp = O.RenderField(ctx, rec.byPath.barColor, O.AceGUI:Create("SimpleGroup"), 0.5)
  assertEqual(cp.type, "ColorPicker")
  assertTrue(cp.hasAlpha, "alpha is on by default — the row declares nothing")
  assertNear(cp.color.r, 0.1, 1e-6)
  assertNear(cp.color.a, 0.4, 1e-6)
end)

test("widgets: a color picker substitutes 1s for a missing or corrupt stored colour", function()
  local O, rec, ctx = bench()
  rec.store.barColor = "not a table"
  local cp = O.RenderField(ctx, rec.byPath.barColor, O.AceGUI:Create("SimpleGroup"), 0.5)
  assertEqual(cp.color.r, 1)
  assertEqual(cp.color.a, 1)
end)

test("widgets: the colour codec is the descriptor's, so an array-storing host is not translated",
  function()
  -- AbsorbTracker stores {r=,g=,b=,a=}; KickCD stores {[1],[2],[3],[4]}. The library takes the
  -- codec rather than picking a winner, or one of the two would need a translation layer at every
  -- read site in the addon.
  local O, rec, ctx = bench{
    colorDecode = function(c) return c[1], c[2], c[3], c[4] end,
    colorEncode = function(r, g, b, a) return { r, g, b, a } end,
  }
  rec.store.barColor = { 0.2, 0.4, 0.6, 0.8 }
  local cp = O.RenderField(ctx, rec.byPath.barColor, O.AceGUI:Create("SimpleGroup"), 0.5)
  assertNear(cp.color.g, 0.4, 1e-6, "read back through the host's decoder")

  cp:__fire("OnValueConfirmed", 0.1, 0.2, 0.3, 0.4)
  local stored = rec.store.barColor
  assertNear(stored[1], 0.1, 1e-6, "and written back in the host's own shape")
  assertNil(stored.r, "never in the library's")
end)

test("widgets: disabledIf greys the swatch out while its sibling toggle is on", function()
  local O, rec, ctx = bench()
  rec.store.useClassColor = true
  local cp = O.RenderField(ctx, rec.byPath.barColor, O.AceGUI:Create("SimpleGroup"), 0.5)
  assertTrue(cp.disabled, "class colour on -> swatch disabled")

  rec.store.useClassColor = false
  for _, fn in ipairs(ctx.refreshers) do fn() end
  assertFalse(cp.disabled, "and the refresher re-evaluates it, so the pair tracks on one frame")
end)

-- ── disabledIf on every maker, and RenderRows' page-level disable ─────────────────────────
--
-- Until minor 16 only the color picker read `disabledIf`, and only as a settings path. A Layout
-- page that dims the rows of an anchor mode not in use needs it on checkboxes, sliders, dropdowns
-- and edit boxes too, and needs to say it as a predicate: "not in container mode" is not a stored
-- boolean. One fixture path per maker the dispatch reaches, the LSM media dropdown and the numeric
-- enum included, because both arrive at makeDropdown by a different branch of RenderField.

local function runRefreshers(ctx)
  for _, fn in ipairs(ctx.refreshers) do fn() end
end

local MAKER_PATHS = {
  { path = "locked",        widget = "CheckBox" },
  { path = "barWidth",      widget = "Slider" },
  { path = "anchor",        widget = "Dropdown" },
  { path = "retentionDays", widget = "Dropdown" },
  { path = "barTexture" },                       -- LSM30_Statusbar, or its Dropdown fallback
  { path = "profileName",   widget = "EditBox" },
  { path = "borderColor",   widget = "ColorPicker" },
}

--- The first widget under the ctx's scroll whose label reads `label`.
local function widgetLabelled(O, ctx, label)
  for _, w in ipairs(Fixture.flatten(O.EnsureScroll(ctx))) do
    if w.labelText == label or w.text == label then return w end
  end
end

test("widgets: a function disabledIf disables every maker and is re-evaluated on refresh", function()
  for _, m in ipairs(MAKER_PATHS) do
    local O, rec, ctx = bench()
    local mode, handed = "screen", nil
    local row = rec.byPath[m.path]
    row.disabledIf = function(r) handed = r; return mode == "screen" end
    local w = O.RenderField(ctx, row, O.AceGUI:Create("SimpleGroup"), 0.5)
    if m.widget then assertEqual(w.type, m.widget, m.path .. " reaches its maker") end
    -- red under: only makeColorPicker reading disabledIf (every other maker ignored it)
    assertTrue(w.disabled, m.path .. ": the predicate disabled it at build")
    assertTrue(handed == row, m.path .. ": the predicate is handed its own row")

    mode = "frame"
    runRefreshers(ctx)
    -- red under: evaluating disabledIf at build time only (the dimming would never lift)
    assertFalse(w.disabled, m.path .. ": the refresher re-evaluated the predicate")
    mode = "screen"
    runRefreshers(ctx)
    assertTrue(w.disabled, m.path .. ": and dims it again")
  end
end)

test("widgets: a path disabledIf disables every maker while that setting is on", function()
  for _, m in ipairs(MAKER_PATHS) do
    local O, rec, ctx = bench()
    local row = rec.byPath[m.path]
    row.disabledIf = "useClassColor"
    rec.store.useClassColor = true
    local w = O.RenderField(ctx, row, O.AceGUI:Create("SimpleGroup"), 0.5)
    -- red under: the path form still read by the color picker alone
    assertTrue(w.disabled, m.path .. ": the setting is on, so the row is disabled")
    rec.store.useClassColor = false
    runRefreshers(ctx)
    assertFalse(w.disabled, m.path .. ": and enabled again once it is off")
  end
end)

test("widgets: a row with no disabledIf never has its disabled state touched", function()
  for _, m in ipairs(MAKER_PATHS) do
    local O, rec, ctx = bench()
    local w = O.RenderField(ctx, rec.byPath[m.path], O.AceGUI:Create("SimpleGroup"), 0.5)
    -- red under: every maker calling SetDisabled(false) unconditionally, which re-enables on the
    -- next write anywhere a widget the host disabled itself
    assertNil(w.disabled, m.path .. ": SetDisabled never called")
    w:SetDisabled(true)
    runRefreshers(ctx)
    assertTrue(w.disabled, m.path .. ": a host's own SetDisabled survives a refresh")
  end
end)

test("widgets: a disabledIf predicate that raises leaves the row drawn and enabled", function()
  local O, rec, ctx = bench()
  local row = rec.byPath.locked
  row.disabledIf = function() error("predicate bug") end
  local w = O.RenderField(ctx, row, O.AceGUI:Create("SimpleGroup"), 0.5)
  -- red under: calling the predicate unguarded (the row fails to draw at all)
  assertTrue(w ~= nil, "the row still drew")
  assertFalse(w.disabled, "an unanswerable predicate reads as enabled")
end)

test("widgets: RenderRows opts.disabled disables every widget it draws, after-group ones included",
  function()
  local O, rec, ctx = bench()
  local after = {
    Size = function(c)
      O.InlineButtonPair(c, { text = "Left", onClick = function() end },
                            { text = "Right", onClick = function() end })
      O.SessionCheckbox(c, nil, 0.5, { label = "Session box",
        get = function() return false end, set = function() end })
    end,
  }
  O.RenderRows(ctx, rec.d.rowsForPage("bar"), after, nil, { disabled = true })

  local CONTROL = { CheckBox = true, Slider = true, Dropdown = true, EditBox = true,
                    ColorPicker = true, Button = true, LSM30_Statusbar = true }
  local drawn = 0
  for _, w in ipairs(Fixture.flatten(O.EnsureScroll(ctx))) do
    if CONTROL[w.type] then
      drawn = drawn + 1
      -- red under: RenderRows ignoring opts.disabled, or InlineButtonPair / SessionCheckbox not
      -- reading the render's flag
      assertTrue(w.disabled, tostring(w.labelText or w.text) .. " is disabled")
    end
  end
  -- The bar page's ten drawn rows (mirror is skipRender), two buttons and the session box.
  assertEqual(drawn, 13, "every control on the page was checked")
  -- red under: leaving the flag on the ctx after the call
  assertNil(ctx.__renderDisabled, "the flag lives for the call only")
end)

test("widgets: a disabled render's flag never leaks into a later render or into its refresh",
  function()
  local O, rec, ctx = bench()
  O.RenderRows(ctx, { rec.byPath.locked }, nil, nil, { disabled = true })
  O.RenderRows(ctx, { rec.byPath.showTooltips })
  local first = widgetLabelled(O, ctx, "Lock Position")
  local second = widgetLabelled(O, ctx, "Show tooltips")
  assertTrue(first.disabled)
  assertNil(second.disabled, "a later render without opts draws enabled, untouched widgets")

  runRefreshers(ctx)
  -- red under: the refresher reading ctx.__renderDisabled live instead of the build-time snapshot
  assertTrue(first.disabled, "the disabled page's widget stays disabled through a refresh")
  assertNil(second.disabled)
end)

test("widgets: a render nested inside a disabled render inherits the disable", function()
  local O, rec, ctx = bench()
  local after = { Master = function(c) O.RenderRows(c, { rec.byPath.profileName }) end }
  O.RenderRows(ctx, { rec.byPath.locked }, after, nil, { disabled = true })
  -- red under: a nested RenderRows resetting the flag to its own (absent) opts
  assertTrue(widgetLabelled(O, ctx, "Profile label").disabled,
    "a bespoke block drawn from an afterGroup hook is part of the disabled page")
  assertNil(ctx.__renderDisabled, "and the outer call still clears it")
end)

test("widgets: an afterGroup hook that raises still propagates, and the flag is cleared", function()
  local O, rec, ctx = bench()
  local after = { Master = function() error("hook bug") end }
  local ok = pcall(O.RenderRows, ctx, { rec.byPath.locked }, after, nil, { disabled = true })
  assertFalse(ok, "a raising hook propagates, as it always has")
  -- red under: clearing the flag only on the normal return path
  assertNil(ctx.__renderDisabled, "a raise does not strand the flag on the ctx")
end)

test("widgets: OnValueConfirmed commits immediately — cancel must not wait on the throttle",
  function()
  local cp, _, _, rec = render("barColor")
  cp:__fire("OnValueConfirmed", 0.5, 0.6, 0.7, 0.8)
  assertNear(rec.store.barColor.r, 0.5, 1e-6, "stored without a timer round trip")
  assertNear(rec.store.barColor.a, 0.8, 1e-6)
  assertEqual(#rec.timers, 0, "and no timer was armed")
end)

test("widgets: OnValueChanged throttles a drag to ONE timer and commits the LAST value", function()
  -- A live-preview drag fires at up to 60 Hz. Without the single re-armed timer that is 60
  -- repaints and 60 closures a second.
  local cp, _, _, rec = render("barColor")
  cp:__fire("OnValueChanged", 0.1, 0.1, 0.1, 1)
  cp:__fire("OnValueChanged", 0.2, 0.2, 0.2, 1)
  cp:__fire("OnValueChanged", 0.3, 0.3, 0.3, 1)
  assertEqual(#rec.timers, 1, "three drag frames arm exactly one timer")
  assertNear(rec.store.barColor.r, 1, 1e-6, "and nothing is committed until it fires")

  rec.fireTimers()
  assertNear(rec.store.barColor.r, 0.3, 1e-6, "the LAST drag value wins, not the first")

  cp:__fire("OnValueChanged", 0.5, 0.5, 0.5, 1)
  assertEqual(#rec.timers, 1, "the timer self-cleared, so the next frame re-arms")
  rec.fireTimers()
  assertNear(rec.store.barColor.r, 0.5, 1e-6)
end)

test("widgets: a colour drag does NOT refresh every panel", function()
  -- A sustained drag would re-traverse every widget on every panel at 20 Hz. The picker is the one
  -- maker that deliberately declines the refresh.
  local O, rec, ctx = bench()
  local other = O.CreatePanel("WidgetBenchColorOther", "Other", {})
  local refreshed = 0
  other.refreshers[1] = function() refreshed = refreshed + 1 end
  local cp = O.RenderField(ctx, rec.byPath.barColor, O.AceGUI:Create("SimpleGroup"), 0.5)
  cp:__fire("OnValueChanged", 0.1, 0.1, 0.1, 1)
  rec.fireTimers()
  cp:__fire("OnValueConfirmed", 0.2, 0.2, 0.2, 1)
  assertEqual(refreshed, 0)
end)

test("widgets: every other maker's write DOES refresh every panel", function()
  -- This is what makes paired controls just work: a "Use Class Color" toggle flips and the
  -- matching swatch greys out on the same frame.
  local O, rec, ctx = bench()
  local other = O.CreatePanel("WidgetBenchOther", "Other", {})
  local refreshed = 0
  other.refreshers[1] = function() refreshed = refreshed + 1 end
  local cb = O.RenderField(ctx, rec.byPath.useClassColor, O.AceGUI:Create("SimpleGroup"), 0.5)
  cb:__fire("OnValueChanged", true)
  assertTrue(refreshed > 0)
end)

-- ── RenderField dispatch ───────────────────────────────────────────────────────────────────

test("widgets: RenderField dispatches each schema type to its widget", function()
  assertEqual(render("locked").type, "CheckBox")
  assertEqual(render("barWidth").type, "Slider")
  assertEqual(render("anchor").type, "Dropdown")
  assertEqual(render("profileName").type, "EditBox")
  assertEqual(render("barColor").type, "ColorPicker")
end)

test("widgets: RenderField returns nil for an unrecognised type instead of erroring", function()
  local O, _, ctx = bench()
  assertNil(O.RenderField(ctx, { path = "x", type = "mystery", label = "X" },
    O.AceGUI:Create("SimpleGroup"), 0.5))
end)

test("widgets: RenderField adds the widget to the parent it was given", function()
  local w, _, _, _, _, parent = render("barWidth", 0.5)
  assertEqual(#parent.children, 1)
  assertEqual(parent.children[1], w)
end)

-- ── the two-column flow engine ─────────────────────────────────────────────────────────────

test("widgets: RenderSchema pairs widgets two-to-a-row inside full-width Flow groups", function()
  local O, _, ctx = bench()
  O.RenderSchema(ctx, "general")
  local rows = Fixture.flowRows(ctx.scroll)
  assertTrue(#rows > 0, "at least one flow row was laid out")
  for _, r in ipairs(rows) do
    assertTrue(r.fullWidth, "each row spans the panel so its two halves split it evenly")
    assertTrue(#r.children <= 2, "never more than two widgets per row")
  end
  for _, w in ipairs(Fixture.flatten(ctx.scroll)) do
    if w.relativeWidth then assertEqual(w.relativeWidth, 0.5, "paired widgets take half each") end
  end
end)

test("widgets: a `solo` row is rendered alone on its own line", function()
  local O, rec, ctx = bench()
  O.RenderSchema(ctx, "bar")
  local row = Fixture.rowWithLabel(ctx.scroll, rec.byPath.barTexture.label)
  assertTrue(row ~= nil, "the barTexture row was found")
  assertEqual(#row.children, 1, "a solo row holds exactly one widget")
end)

test("widgets: a `solo` row flushes the row in progress rather than joining it", function()
  -- throttleWindow is solo and sits SECOND in its group, so a maker that ignored `solo` would pair
  -- it with the row above and the case would still find one widget per row elsewhere.
  local O, rec, ctx = bench()
  O.RenderSchema(ctx, "general")
  local row = Fixture.rowWithLabel(ctx.scroll, rec.byPath.throttleWindow.label)
  assertEqual(#row.children, 1, "the solo pivot did not absorb the widget beside it")
end)

test("widgets: a `skipRender` row is left to the host and never drawn", function()
  local O, rec, ctx = bench()
  O.RenderSchema(ctx, "bar")
  for _, w in ipairs(Fixture.flatten(ctx.scroll)) do
    assertTrue(w.labelText ~= rec.byPath.mirror.label,
      "a skipRender row stays in the schema for resets, but the panel draws it bespoke")
  end
end)

test("widgets: RenderRows emits one Heading per group, in first-seen order", function()
  local O, _, ctx = bench()
  O.RenderSchema(ctx, "bar")
  local headings = {}
  for _, child in ipairs(ctx.scroll.children) do
    if child.type == "Heading" then headings[#headings + 1] = child.text end
  end
  assertEqual(table.concat(headings, ","), "Size,Fill")
end)

test("widgets: a group's heading lands BELOW the previous group's tail row, not above it",
  function()
  -- startGroup's half of the contract endGroup's tail-row case pins for afterGroup, and the only
  -- thing the heading's POSITION means. A group's last row is usually still PENDING when the next
  -- group opens — Master's third row, showTooltips, is the odd one left alone on its line — so the
  -- pending line is flushed BEFORE O.Section runs. Flush after instead and the "Performance"
  -- heading is added to the scroll first, so it renders above a widget that belongs above IT.
  --
  -- No afterGroup hook here on purpose: endGroup returns without flushing when the group has none,
  -- which leaves the ordering entirely to startGroup. Counting children at heading time would still
  -- pass a swapped pair; this names the widget that has to be down already.
  local O, rec, ctx = bench()
  O.RenderSchema(ctx, "general")

  local tailRowAt, headingAt
  for i, child in ipairs(ctx.scroll.children) do
    if child.type == "Heading" and child.text == "Performance" then
      headingAt = headingAt or i
    end
    for _, w in ipairs(child.children or {}) do
      if w.labelText == rec.byPath.showTooltips.label then tailRowAt = tailRowAt or i end
    end
  end
  assertTrue(tailRowAt ~= nil, "the Master group's tail row reached the page")
  assertTrue(headingAt ~= nil, "and the next group's heading did too")
  assertTrue(tailRowAt < headingAt,
    "the tail row was flushed before the heading was emitted, not after")
end)

test("widgets: an afterGroup callback fires exactly once, after its group's last row", function()
  local O, _, ctx = bench()
  local firedAfter = {}
  O.RenderSchema(ctx, "general", {
    Master = function() firedAfter[#firedAfter + 1] = #ctx.scroll.children end,
  })
  assertEqual(#firedAfter, 1, "one-shot")
  -- Everything the Master group drew is already in the scroll when the callback runs, and the
  -- Performance heading is not — which is what "after its group's last row" means structurally.
  local headingAt
  for i, child in ipairs(ctx.scroll.children) do
    if child.type == "Heading" and child.text == "Performance" then headingAt = i end
  end
  assertTrue(headingAt ~= nil and firedAfter[1] < headingAt,
    "the callback landed between the two groups")
end)

test("widgets: an afterGroup callback runs with its group's tail row already on the page",
  function()
  -- The one thing the callback's POSITION means. afterGroup draws buttons, and they belong on a
  -- fresh line under the group rather than packed into the empty right half of its last row — so
  -- the pending line is flushed BEFORE the hook is called, not after. The neighbouring case counts
  -- children at fire time, which still passes if the flush moves to after the call; this names the
  -- widget that has to be down already. Master's third row, showTooltips, is the odd one left alone
  -- on its line, so it is exactly the row a late flush would strand.
  local O, rec, ctx = bench()
  local sawTailRow
  O.RenderSchema(ctx, "general", {
    Master = function()
      sawTailRow = Fixture.rowWithLabel(ctx.scroll, rec.byPath.showTooltips.label) ~= nil
    end,
  })
  assertTrue(sawTailRow == true,
    "the group's last row was flushed to the page before its afterGroup hook ran")
end)

test("widgets: an afterGroup hook fires for a group's FIRST run only, when the group recurs",
  function()
  -- What the library's one-shot ledger actually buys, and the only case that needs it: a schema
  -- whose rows revisit a group name they already used. Every other guard is incidental — a hook
  -- fires on a group's last row, and a contiguous group has exactly one of those, so a ledger-less
  -- implementation passes every contiguous case in this file. Here "Fill" ends twice, and the host
  -- must still get one set of buttons rather than two.
  local O, rec, ctx = bench()
  local fired = 0
  local rows = {
    { path = "barWidth",     type = "number", group = "Fill", label = "W", min = 1, max = 9, step = 1 },
    { path = "barHeight",    type = "number", group = "Size", label = "H", min = 1, max = 9, step = 1 },
    { path = "useClassColor", type = "bool",  group = "Fill", label = "C" },
  }
  rec.chat = {}
  O.RenderRows(ctx, rows, { Fill = function() fired = fired + 1 end })
  assertEqual(fired, 1, "the hook is one-shot per render, not once per run of the group")
  assertEqual(table.concat(rec.chat, "\n"), "", "and no row failed on the way")
end)

test("widgets: a pairWith partner attaches to the named row, is one-shot, and stays 50/50",
  function()
  -- The production site is a session-only checkbox riding beside a schema bool. It only works when
  -- that path is the LONE widget on its row, so this doubles as a guard on the group's row count.
  local O, rec, ctx = bench()
  local made = 0
  local partner = {
    showTooltips = function(_ctxRef, rowGroup)
      made = made + 1
      rowGroup:AddChild(O.AceGUI:Create("CheckBox"))
    end,
  }
  O.RenderSchema(ctx, "general", nil, partner)
  assertEqual(made, 1, "the partner was built once")
  assertTrue(partner.showTooltips ~= nil,
    "the one-shot bookkeeping is the library's -- the caller's table is never written to")

  local row = Fixture.rowWithLabel(ctx.scroll, rec.byPath.showTooltips.label)
  assertTrue(row ~= nil, "the showTooltips row was found")
  assertEqual(#row.children, 2, "the pair stays 50/50 and never overflows to three-wide")
end)

test("widgets: a pairWith partner declines a row it would make three-wide", function()
  -- showOnlyInCombat renders as the RIGHT half of locked's row, so it is never the lone widget on
  -- its line. Attaching there would put three widgets in a 50/50 row and shove the layout sideways
  -- for the rest of the page.
  local O, rec, ctx = bench()
  local made = 0
  O.RenderSchema(ctx, "general", nil, { showOnlyInCombat = function() made = made + 1 end })
  assertEqual(made, 0)
  assertEqual(#Fixture.rowWithLabel(ctx.scroll, rec.byPath.showOnlyInCombat.label).children, 2)
end)

test("widgets: RenderRows leaves the caller's afterGroup / pairWith tables intact", function()
  -- The one-shot bookkeeping is the LIBRARY's, not the host's. A host that hoists its afterGroup /
  -- pairWith table to a file-level constant (the natural way to write it) and re-renders the page --
  -- ClearScroll + RenderSchema, which a per-unit page does on every unit switch -- must get the same
  -- panel the second time, not one silently missing every inline button and paired widget.
  local O, rec, ctx = bench()
  local afterFired, paired = 0, 0
  local afterGroup = { Master = function() afterFired = afterFired + 1 end }
  local pairWith = {
    showTooltips = function(_ctxRef, rowGroup)
      paired = paired + 1
      rowGroup:AddChild(O.AceGUI:Create("CheckBox"))
    end,
  }

  O.RenderSchema(ctx, "general", afterGroup, pairWith)
  assertEqual(afterFired, 1, "first pass: the afterGroup callback fired once")
  assertEqual(paired, 1, "first pass: the partner was built once")

  O.ClearScroll(ctx)
  O.RenderSchema(ctx, "general", afterGroup, pairWith)
  assertEqual(afterFired, 2, "second pass fires the afterGroup callback again")
  assertEqual(paired, 2, "second pass builds the paired widget again")
  assertTrue(afterGroup.Master ~= nil, "the caller's afterGroup entry was never nil'd out")
  assertTrue(pairWith.showTooltips ~= nil, "the caller's pairWith entry was never nil'd out")
  assertEqual(#Fixture.rowWithLabel(ctx.scroll, rec.byPath.showTooltips.label).children, 2,
    "and the second pass's pair is still 50/50")
end)

test("widgets: RenderRows runs a layout pass at the end", function()
  local O, _, ctx = bench()
  O.RenderSchema(ctx, "general")
  assertTrue((ctx.scroll.layoutCount or 0) > 0, "DoLayout is what positions the children")
end)

-- ── Section / AddSpacer / ClearScroll / InlineButtonPair ───────────────────────────────────

test("widgets: Section emits a full-width Heading and tracks the group", function()
  local O, _, ctx = bench()
  local h = O.Section(ctx, "Size")
  assertEqual(h.type, "Heading")
  assertEqual(h.text, "Size")
  assertTrue(h.fullWidth)
  assertEqual(h.height, O.SECTION_HEADING_H)
end)

test("widgets: ClearScroll releases the children AND resets ctx.refreshers", function()
  -- Every RenderField call appends a refresher closure over the widgets ReleaseChildren just tore
  -- down. Without this reset, every re-render grows ctx.refreshers forever and RefreshAllPanels
  -- pcalls an ever-larger pile of stale closures.
  local O, _, ctx = bench()
  O.RenderSchema(ctx, "general")
  local firstCount = #ctx.refreshers
  assertTrue(firstCount > 0, "the render registered refreshers")
  assertTrue(#ctx.scroll.children > 0)

  O.ClearScroll(ctx)
  assertEqual(#ctx.scroll.children, 0)
  assertEqual(#ctx.refreshers, 0)
  assertNil(ctx.lastGroup, "and the section tracker restarts, or the next heading is swallowed")

  O.RenderSchema(ctx, "general")
  assertEqual(#ctx.refreshers, firstCount, "so a re-render lands back at the same size")
end)

test("widgets: ClearScroll reassigns ctx.refreshers rather than wiping it in place", function()
  -- The panel registry holds the ctx table, not a separate reference to ctx.refreshers, so a fresh
  -- table is observed immediately. Asserting the identity change is what stops a `wipe()` that
  -- would leave a captured reference alive somewhere else.
  local O, _, ctx = bench()
  O.RenderSchema(ctx, "general")
  local before = ctx.refreshers
  O.ClearScroll(ctx)
  assertTrue(ctx.refreshers ~= before)
end)

test("widgets: InlineButtonPair lays two inset buttons into one Flow row and pcalls the click",
  function()
  local O, rec, ctx = bench()
  local left, right = 0, 0
  O.InlineButtonPair(ctx,
    { text = "Reset Position", tooltip = "Move it back", onClick = function() left = left + 1 end },
    { text = "Reset All",      onClick = function() right = right + 1; error("boom") end })

  local row = Fixture.flowRows(ctx.scroll)[1]
  assertEqual(#row.children, 2)
  assertEqual(row.children[1].text, "Reset Position")
  assertEqual(row.children[1].relativeWidth, O.BUTTON_PAIR_REL,
    "inset under 0.5 so the right button clears the ScrollFrame clip")
  assertTrue(row.children[1].callbacks.OnEnter ~= nil, "with its tooltip attached")

  row.children[1]:__fire("OnClick")
  assertEqual(left, 1)
  local blew = not pcall(function() row.children[2]:__fire("OnClick") end)
  assertFalse(blew, "a throwing onClick is reported, not propagated into AceGUI's dispatch")
  assertEqual(right, 1)
  assertTrue(table.concat(rec.chat, "\n"):find("boom", 1, true) ~= nil,
    "and the failure is printed rather than swallowed: " .. table.concat(rec.chat, "\n"))
end)

test("widgets: InlineButtonPair tolerates a missing second spec", function()
  local O, _, ctx = bench()
  assertTrue(pcall(O.InlineButtonPair, ctx, { text = "Only one" }, nil))
  assertEqual(#Fixture.flowRows(ctx.scroll)[1].children, 1)
end)

test("widgets: InlineButtonPair reports a handler-less button once, and draws it anyway",
  function()
  -- OptionsCompose builds `resetAll` and `resetPosition` UNCONDITIONALLY, whether or not the host
  -- spec supplied onResetAll/onResetPosition, so a spec that forgot one gets a live-looking button
  -- whose OnClick returns early. Nothing said so. The cure follows EMPTY_DROPDOWN rather than
  -- refusing to draw: an author who sees a gap in the pair fixes the spec, whereas a silently
  -- missing button reads as a deliberate layout and ships.
  local O, rec, ctx = bench()

  local row = O.InlineButtonPair(ctx, { text = "Reset all settings", tooltip = "Put it back" }, nil)

  local drawn = Fixture.flowRows(ctx.scroll)[1]
  assertEqual(#drawn.children, 1, "the button is still drawn -- report and render, never refuse")
  assertEqual(drawn.children[1].text, "Reset all settings")

  local expected = lib.STRINGS.DEAD_BUTTON:format("Reset all settings")
  local reports = 0
  for _, line in ipairs(rec.chat) do
    if line == expected then reports = reports + 1 end
  end
  assertEqual(reports, 1,
    "reported exactly once, at build time: " .. table.concat(rec.chat, "\n"))

  -- The report belongs to the BUILD, not to the press: a player leaning on a dead button must not
  -- be able to fill the chat frame with it.
  drawn.children[1]:__fire("OnClick")
  drawn.children[1]:__fire("OnClick")
  local after = 0
  for _, line in ipairs(rec.chat) do
    if line == expected then after = after + 1 end
  end
  assertEqual(after, 1, "and clicking it adds nothing")

  -- The counterpart: a button that HAS a handler is silent, or the line lands on all nine hosts.
  local O2, rec2, ctx2 = bench()
  O2.InlineButtonPair(ctx2, { text = "Reset all settings", onClick = function() end }, nil)
  assertEqual(table.concat(rec2.chat, "\n"):find("DEAD", 1, true), nil,
    "a handled button says nothing")
  assertTrue(row ~= nil)
end)

-- ── numeric enums render as dropdowns (WIDGETS_MINOR 5) ────────────────────────────────────
--
-- The two majors used to disagree about what one schema row IS. Slash.lua's parseNumber has always
-- treated `type = "number"` carrying a `values` list as a constrained ENUM — it refuses a value
-- outside the list rather than clamping, and its own comment calls the shape "a NUMERIC dropdown"
-- and warns that clamping "lands BETWEEN two entries, and the renderer then has no label for what
-- is stored". RenderField meanwhile sent every number row to makeSlider without ever consulting
-- `values`, so the renderer that comment describes did not exist.
--
-- Inferred from `values` rather than opted into with a `dialogControl`, because Slash infers too
-- and an opt-in would leave the two disagreeing for any row that declares `values` and nothing
-- else. Safe in the failure direction: a row whose values list comes back empty falls through to
-- makeSlider, which is exactly the old behaviour.

test("widgets: a number row carrying a values list renders as a Dropdown, not a Slider", function()
  local w = render("retentionDays")
  assertEqual(w.type, "Dropdown", "a numeric enum must not render as a slider")
end)

test("widgets: the numeric dropdown lists its entries with their own labels", function()
  local w = render("retentionDays")
  assertEqual(w.list[7], "7 days")
  assertEqual(w.list[30], "30 days")
  assertEqual(w.list[0], "Always", "the zero entry is a real value, not an absent one")
  assertEqual(#w.order, 3, "declaration order is preserved")
  assertEqual(w.order[1], 7)
end)

test("widgets: the numeric dropdown seeds the STORED number, not a stringified copy", function()
  local w, row, _, rec = render("retentionDays")
  assertEqual(w.value, rec.store[row.path], "seeded from the store")
  assertEqual(type(w.value), "number", "a numeric key must stay a number or SetValue cannot match")
end)

test("widgets: choosing an entry writes the number through the host's set", function()
  local w, row, _, rec = render("retentionDays")
  w:__fire("OnValueChanged", 7)
  assertEqual(rec.store[row.path], 7)
  assertEqual(type(rec.store[row.path]), "number", "the stored value is not stringified")
end)

test("widgets: a number row with NO values list still renders as a Slider", function()
  -- The existing-consumer path, and the reason the inference is safe: every number row in every
  -- shipped consumer is a range, and every one of them must be untouched by this.
  local w = render("barWidth")
  assertEqual(w.type, "Slider")
end)

test("widgets: a number row whose values function answers empty falls back to a Slider", function()
  -- The degenerate case the EditBox maker's comment worries about, resolved the other way round:
  -- there an empty list would silently become free text, which can write anything. Here it becomes
  -- a slider, which is what the row did before this change.
  local O, rec, ctx = bench()
  local row = { path = "barWidth", type = "number", label = "W", min = 1, max = 10,
                values = function() return {} end }
  local parent = O.AceGUI:Create("SimpleGroup")
  local w = O.RenderField(ctx, row, parent, nil)
  assertEqual(w.type, "Slider")
  assertTrue(rec ~= nil)
end)

-- ── TextRow and the landing page (the three-host BuildMainContent promotion) ────────────────
--
-- Three repos carried a function literally named Helpers.BuildMainContent rendering the same page
-- from the same four constants, and six carry the `if w.label and w.label.SetJustifyH` guard pair —
-- 28 copies of it. Both are library shapes now, and these cases are what pins them.

--- Run `fn` with a Label widget type that HAS a `.label` FontString.
---
--- The kit's widgets are inert recorders with no FontString at all, so the guard pair O.TextRow
--- owns is UNREACHABLE against the default: `w.label` is nil, both branches are skipped, and every
--- assertion about justification or font would pass vacuously. Registered and torn down around the
--- case because the AceGUI mock is shared by the whole run.
local function withFontStringLabels(O, fn)
  local made = {}
  O.AceGUI:RegisterWidgetType("Label", function()
    local w = T.mocks.__makeAceGUIWidget("Label")
    w.label = {
      SetFontObject = function(self, obj) self.fontObject = obj end,
      SetJustifyH   = function(self, j)   self.justify    = j   end,
    }
    made[#made + 1] = w
    return w
  end, 1)
  local ok, err = pcall(fn, made)
  O.AceGUI.WidgetRegistry.Label   = nil
  O.AceGUI.__widgetVersions.Label = nil
  if not ok then error(err, 0) end
end

test("widgets: TextRow adds a full-width Label carrying the text", function()
  local O, _, ctx = bench()
  local w = O.TextRow(ctx, "a line of prose")
  assertEqual(w.type, "Label")
  assertEqual(w.text, "a line of prose")
  assertTrue(w.fullWidth, "a landing row spans the page; a half-width one reads as a stray widget")
  assertEqual(ctx.scroll.children[#ctx.scroll.children], w, "and it went into the page's scroll")
end)

test("widgets: TextRow left-justifies by default and honours an explicit justify", function()
  local O, _, ctx = bench()
  withFontStringLabels(O, function()
    assertEqual(O.TextRow(ctx, "left").label.justify, "LEFT")
    assertEqual(O.TextRow(ctx, "right", { justify = "RIGHT" }).label.justify, "RIGHT")
  end)
end)

test("widgets: TextRow applies a font object by NAME, and only when the global exists", function()
  -- The NAME, not the object: a host declares its landing spec at file scope, where the font
  -- globals may not exist yet. Both halves of the guard matter — a client that does not ship the
  -- font must cost the line its styling, not the page.
  local O, _, ctx = bench()
  local sentinel = {}
  _G.LK_TestFontObject = sentinel
  withFontStringLabels(O, function()
    assertEqual(O.TextRow(ctx, "styled", { fontObject = "LK_TestFontObject" }).label.fontObject,
      sentinel)
    assertNil(O.TextRow(ctx, "plain", { fontObject = "LK_NoSuchFontObject" }).label.fontObject,
      "an absent font object is skipped, not passed through as nil")
  end)
  _G.LK_TestFontObject = nil
end)

test("widgets: TextRow draws nothing and returns nil when there is no scroll to draw into",
  function()
  -- AceGUI absent is a survivable state for this library, not an error one: the panel simply does
  -- not render. A TextRow that raised here would take the host's whole page builder with it.
  local O, _, ctx = bench()
  local aceGUI = O.AceGUI
  O.AceGUI = nil
  assertNil(O.TextRow(ctx, "nowhere to go"))
  O.AceGUI = aceGUI
end)

test("widgets: BuildLandingPage draws the logo block at its declared size, then a spacer", function()
  local O, _, ctx = bench()
  O.BuildLandingPage(ctx, { logo = "Interface\\AddOns\\Host\\logo.tga" })
  local kids = ctx.scroll.children
  assertEqual(kids[1].type, "SimpleGroup")
  assertEqual(kids[1].height, 300, "LANDING_LOGO, promoted from the three hosts that agreed on it")
  assertNil(kids[1].layout, "the layout is suppressed so the texture can be anchored by hand")
  assertEqual(kids[2].height, 8, "LANDING_GAP_LOGO")
end)

test("widgets: BuildLandingPage honours an explicit logoSize", function()
  local O, _, ctx = bench()
  O.BuildLandingPage(ctx, { logo = "x.tga", logoSize = 128 })
  assertEqual(ctx.scroll.children[1].height, 128)
end)

test("widgets: a logo whose widget has no backing frame costs the logo, not the page", function()
  -- The logo is the one block here that reaches THROUGH the AceGUI widget to a real frame handle
  -- and calls WoW texture methods on it. Every other widget touch in this file is guarded, and this
  -- one has more riding on it than any of them: BuildLandingPage runs under the renderer's pcall,
  -- so a raise on the logo is caught, printed as RENDER_FAILED, and the notes and every section
  -- never draw. A missing picture must not cost the page it decorates.
  --
  -- Driven by handing the factory a SimpleGroup with no `.frame` at all, which is the shape a
  -- widget mock takes and the shape a widget released mid-layout takes in game.
  local O, _, ctx = bench()
  local realCtor = O.AceGUI.WidgetRegistry.SimpleGroup
  O.AceGUI:RegisterWidgetType("SimpleGroup", function()
    local w = T.mocks.__makeAceGUIWidget("SimpleGroup")
    w.frame = nil
    return w
  end)

  local ok, err = pcall(O.BuildLandingPage, ctx, {
    logo     = "x.tga",
    notes    = "the one-liner",
    sections = { { heading = "Slash Commands", rows = function() return { "/x help" } end } },
  })
  O.AceGUI:RegisterWidgetType("SimpleGroup", realCtor)

  assertTrue(ok, "the logo block must not raise on a frameless widget: " .. tostring(err))
  local texts = {}
  for _, child in ipairs(ctx.scroll.children) do
    if child.type == "Label" or child.type == "Heading" then texts[#texts + 1] = tostring(child.text) end
  end
  local joined = table.concat(texts, "|")
  assertTrue(joined:find("the one-liner", 1, true) ~= nil, "the notes still drew: " .. joined)
  assertTrue(joined:find("/x help", 1, true) ~= nil, "and so did the sections: " .. joined)
end)

--- A texture stub that records what was done to it. The kit's base frame answers CreateTexture with
--- the FRAME ITSELF (a known divergence, documented in mock_base.lua), which makes "how many
--- textures were created" and "is the texture shown" both unanswerable — and those two questions
--- are the whole of the case below.
local function textureStub()
  local t = { shown = true, points = 0 }
  function t:SetTexture(v) self.texture = v end
  function t:SetSize(w, h) self.w, self.h = w, h end
  function t:ClearAllPoints() self.points = 0 end
  function t:SetPoint() self.points = self.points + 1 end
  function t:Show() self.shown = true end
  function t:Hide() self.shown = false end
  return t
end

test("widgets: a POOLED frame gains ONE logo texture, and hides it when released", function()
  -- THE BUG: AceGUI pools widget FRAMES. A texture created on one is not a widget, so nothing
  -- releases it and nothing hides it — it rides the frame into the pool and draws again the next
  -- time that frame is handed out, for whatever purpose. A host with a landing logo therefore grew
  -- a SECOND logo partway down its own page, intermittently, depending only on pool order.
  -- BuildLandingPage's ClearScroll cannot help: there is no widget there to clear.
  -- red under: an unconditional frame:CreateTexture(), which is what shipped through minor 7.
  local O, _, ctx = bench()

  local pooled  = T.mocks.__makeAceGUIWidget("SimpleGroup")
  local made    = 0
  local tex
  function pooled.frame:CreateTexture()
    made = made + 1
    tex = textureStub()
    return tex
  end

  -- The logo group is the first SimpleGroup BuildLandingPage creates; the spacer under it is the
  -- second, and must NOT be the same frame or the case proves nothing about pooling.
  local realCtor = O.AceGUI.WidgetRegistry.SimpleGroup
  local handOver = false
  O.AceGUI:RegisterWidgetType("SimpleGroup", function()
    if handOver then
      handOver = false
      return pooled
    end
    return T.mocks.__makeAceGUIWidget("SimpleGroup")
  end)

  handOver = true
  O.BuildLandingPage(ctx, { logo = "x.tga" })
  assertEqual(made, 1)
  assertEqual(tex.texture, "x.tga")
  assertTrue(tex.shown)

  -- AceGUI releasing the group back to its pool. It fires "OnRelease" BEFORE it clears a widget's
  -- callbacks, which is what makes SetCallback a safe place to hang this.
  pooled:__fire("OnRelease")
  assertFalse(tex.shown,
    "a texture left visible on a pooled frame IS the second logo, on whatever page reuses it")

  -- The same frame, handed back for another logo: it must reuse its own texture rather than stack
  -- a second one under the first.
  handOver = true
  O.BuildLandingPage(ctx, { logo = "x.tga" })
  O.AceGUI:RegisterWidgetType("SimpleGroup", realCtor)

  assertEqual(made, 1, "a re-rendered landing page must not create a second texture")
  assertTrue(tex.shown, "and the one it reuses has to be visible again")
  assertEqual(tex.points, 1, "anchored once — ClearAllPoints first, or the points accumulate")
end)

test("widgets: a spec with no logo draws no logo block", function()
  local O, _, ctx = bench()
  O.BuildLandingPage(ctx, { notes = "just the one-liner" })
  assertEqual(ctx.scroll.children[1].type, "Label", "the notes line is the first thing on the page")
end)

test("widgets: BuildLandingPage calls a notes FUNCTION at render time", function()
  -- The one-liner's usual source is the TOC's Notes field, which a host declaring its spec at file
  -- scope cannot read yet. Deferring it is the whole reason the field takes a function at all, so
  -- the case asserts WHEN it was called as well as what it returned.
  local O, _, ctx = bench()
  local calls = 0
  local spec = { notes = function() calls = calls + 1; return "resolved late" end }
  assertEqual(calls, 0, "declaring the spec resolves nothing")
  O.BuildLandingPage(ctx, spec)
  assertEqual(calls, 1)
  assertEqual(ctx.scroll.children[1].text, "resolved late")
end)

test("widgets: an empty one-liner skips the notes Label AND its spacer", function()
  -- Both, together. A skipped Label that left its spacer behind is a lone gap under the logo, which
  -- reads as a broken top margin rather than as a missing sentence.
  local O, _, ctx = bench()
  O.BuildLandingPage(ctx, {
    logo = "x.tga",
    notes = function() return "" end,
    sections = { { heading = "Slash Commands", rows = function() return { "/x help" } end } },
  })
  local kids = ctx.scroll.children
  assertEqual(kids[1].type, "SimpleGroup", "the logo")
  assertEqual(kids[2].height, 8, "its own spacer")
  assertEqual(kids[3].type, "Heading", "and then straight to the heading -- no gap of its own")
  for _, w in ipairs(kids) do
    assertTrue(w.height ~= 12, "the LANDING_GAP_DESC spacer was never emitted")
  end
end)

test("widgets: BuildLandingPage renders a heading and one row per section entry", function()
  local O, _, ctx = bench()
  O.BuildLandingPage(ctx, {
    sections = {
      { heading = "Slash Commands", rows = function() return { "/x help", "/x show" } end },
      { heading = "Credits",        rows = function() return { "you" } end },
    },
  })
  local seen = {}
  for _, w in ipairs(ctx.scroll.children) do
    if w.type == "Heading" or w.type == "Label" then seen[#seen + 1] = w.text end
  end
  assertEqual(table.concat(seen, "|"), "Slash Commands|/x help|/x show|Credits|you")
end)

test("widgets: a section's rows are re-evaluated on every render", function()
  -- `rows` is a FUNCTION, not an array, precisely so a command registered after the spec was
  -- declared still reaches the page. A snapshot taken at declaration would freeze the list at
  -- whatever had loaded first, and the panel would drift from `/x help` with nothing to notice it.
  local O, _, ctx = bench()
  local commands = { "/x help" }
  local spec = { sections = { { heading = "Slash Commands",
                                rows = function() return commands end } } }

  O.BuildLandingPage(ctx, spec)
  local function rowTexts()
    local out = {}
    for _, w in ipairs(ctx.scroll.children) do
      if w.type == "Label" then out[#out + 1] = w.text end
    end
    return table.concat(out, "|")
  end
  assertEqual(rowTexts(), "/x help")

  commands[#commands + 1] = "/x show"
  O.BuildLandingPage(ctx, spec)
  assertEqual(rowTexts(), "/x help|/x show", "the second render picked the new command up")
end)

test("widgets: a re-render clears the previous body instead of stacking a second copy", function()
  local O, _, ctx = bench()
  local spec = { logo = "x.tga", notes = "one line" }
  O.BuildLandingPage(ctx, spec)
  local first = #ctx.scroll.children
  O.BuildLandingPage(ctx, spec)
  assertEqual(#ctx.scroll.children, first, "the renderer owns the clear, so nothing accumulates")
end)

test("widgets: the second landing heading gets a top spacer and the first does not", function()
  -- O.Section only emits SECTION_TOP_SPACER when ctx.lastGroup is already set, so the tracker has
  -- to be advanced per section. Without that both headings butt straight up against the rows above
  -- them, which is the same broken-margin failure the notes skip avoids.
  local O, _, ctx = bench()
  O.BuildLandingPage(ctx, {
    sections = {
      { heading = "A", rows = function() return { "a" } end },
      { heading = "B", rows = function() return { "b" } end },
    },
  })
  local kids = ctx.scroll.children
  assertEqual(kids[1].type, "Heading", "nothing above the first heading")
  local secondAt
  for i, w in ipairs(kids) do
    if w.type == "Heading" and w.text == "B" then secondAt = i end
  end
  assertEqual(kids[secondAt - 1].height, 10, "SECTION_TOP_SPACER separates the two sections")
end)

test("widgets: the gap under a landing heading is emitted once, by Section", function()
  -- LANDING_GAP_HEAD and SECTION_BOTTOM_SPACER are the same 6. BuildLandingPage relies on Section
  -- for it rather than adding its own, and a second spacer would double the gap the three hosts
  -- render.
  local O, _, ctx = bench()
  O.BuildLandingPage(ctx, {
    sections = { { heading = "Slash Commands", rows = function() return { "/x help" } end } },
  })
  local kids = ctx.scroll.children
  assertEqual(kids[1].type, "Heading")
  assertEqual(kids[2].height, 6, "one gap under the heading")
  assertEqual(kids[3].type, "Label", "and then the first row")
end)

test("widgets: BuildLandingPage tolerates a nil spec and an empty one", function()
  local O, _, ctx = bench()
  assertTrue(pcall(O.BuildLandingPage, ctx))
  assertTrue(pcall(O.BuildLandingPage, ctx, {}))
  assertEqual(#ctx.scroll.children, 0)
end)

test("widgets: the landing page's text rows carry the same justify guard TextRow owns", function()
  local O, _, ctx = bench()
  withFontStringLabels(O, function(made)
    O.BuildLandingPage(ctx, {
      notes = "the one-liner",
      sections = { { heading = "Slash Commands", rows = function() return { "/x help" } end } },
    })
    assertEqual(#made, 2, "the one-liner and the one command row")
    for _, w in ipairs(made) do assertEqual(w.label.justify, "LEFT") end
  end)
end)

-- ── the tab strip ──────────────────────────────────────────────────────────────────────────

test("widgets: tab packing fills a row and wraps to the next", function()
  -- Pure arithmetic, deliberately: the wrap rule is the part that decides whether a page's
  -- strip is one row or two, and a rule that can only be checked against a measured font is a
  -- rule nothing checks.
  -- red under: counting the gap before the first tab of a row, or comparing with >=.
  local O = Fixture.new()
  local rows = O.__layoutTabs({ 60, 60, 60 }, 150, 4)
  assertEqual(#rows, 2, "60+4+60 = 124 fits in 150; a third would need 188, so it wraps")
  assertEqual(#rows[1], 2)
  assertEqual(rows[1][1], 1)
  assertEqual(rows[1][2], 2)
  assertEqual(#rows[2], 1)
  assertEqual(rows[2][1], 3)
end)

test("widgets: a tab wider than the strip gets its own row rather than vanishing", function()
  -- The split only happens when the row already holds something, so an over-wide tab is
  -- always placed. A rule that dropped it would lose a whole section with no error.
  -- red under: splitting unconditionally, which loops forever or drops the tab.
  local O = Fixture.new()
  local rows = O.__layoutTabs({ 500 }, 200, 4)
  assertEqual(#rows, 1)
  assertEqual(rows[1][1], 1)

  local mixed = O.__layoutTabs({ 60, 500, 60 }, 200, 4)
  assertEqual(#mixed, 3, "the over-wide tab neither joins a row nor absorbs the next")
end)

test("widgets: an empty tab list lays out as no rows at all", function()
  -- red under: seeding the loop with an empty first row and returning it.
  local O = Fixture.new()
  assertEqual(#O.__layoutTabs({}, 200, 4), 0)
end)

test("widgets: __tabPlacement puts the first row below the banner, and wraps below that",
function()
  -- The bug this seam exists to prevent: row 1 landing at ctx.chrome's TOPLEFT -- the same
  -- anchor the banner's dropdown uses -- because the offset was computed from the row index
  -- alone, with no `top` term for the band already spoken for above the strip.
  -- red under: `y = -((r - 1) * rowPitch)`, which answers 0 for row 1 regardless of top.
  local O = Fixture.new()
  local placement, rowCount = O.__tabPlacement({ 60, 60, 60 }, 150, 4, 44, 28)
  assertEqual(rowCount, 2, "60+4+60 fits in 150; the third tab wraps, same as __layoutTabs")
  assertEqual(#placement, 3, "every tab placed")
  assertEqual(placement[1].y, -44, "row 1 sits at the bottom of the reserved band, not at 0")
  assertEqual(placement[2].y, -44, "row 1's second tab shares row 1's y")
  -- ONE PITCH, not a tab height plus a gap. The pitch is the tab ART's height, which is shorter
  -- than the button; packing by the button left the empty strip along each button's top standing
  -- between the two rows as a visible gap.
  assertEqual(placement[3].y, -(44 + 28), "row 2 sits exactly one pitch below row 1, flush to it")
end)

test("widgets: __tabPlacement accumulates x across a row", function()
  -- red under: resetting x to 0 for every tab instead of advancing past the previous one.
  local O = Fixture.new()
  local placement = O.__tabPlacement({ 60, 80 }, 1000, 4, 0, 24)
  assertEqual(placement[1].x, 0, "the first tab in a row starts at the row's left edge")
  assertEqual(placement[2].x, 64, "the second tab starts after the first tab's width plus the gap")
end)

test("widgets: __tabPlacement places every index exactly once", function()
  -- Mirrors the guarantee __layoutTabs already carries: losing an index here would lose a tab
  -- from the strip with nothing said about it.
  -- red under: dropping an over-wide tab, or emitting an index twice across two rows.
  local O = Fixture.new()
  local placement = O.__tabPlacement({ 60, 500, 60, 60, 60 }, 130, 4, 0, 24)
  local seen = {}
  for _, p in ipairs(placement) do
    assertEqual(seen[p.index], nil, "index " .. p.index .. " placed only once")
    seen[p.index] = true
  end
  for i = 1, 5 do assertTrue(seen[i], "index " .. i .. " was placed") end
end)

test("widgets: __bannerBand widens a real height by the gap/rule/gap, and a zero one not at all",
function()
  -- Pure arithmetic, deliberately: the widening is what feeds __tabPlacement's `top` (via
  -- ctx.__bannerHeight), so it has to be checkable without a live dropdown frame.
  -- red under: adding the gap/rule/gap unconditionally, which would push a tabs-only page's
  -- first row down for a banner that was never drawn.
  local O = Fixture.new()
  local L = lib.LAYOUT
  assertEqual(O.__bannerBand(44), 44 + L.CHROME_DIVIDER_GAP_TOP + L.CHROME_DIVIDER_H
    + L.CHROME_DIVIDER_GAP_BOTTOM)
  assertEqual(O.__bannerBand(0), 0, "no banner drawn, nothing to separate it from")
  assertEqual(O.__bannerBand(nil), 0)
end)

test("widgets: __tabBand reserves the wrapped rows at their pitch, plus one full tab", function()
  -- The band is where the content panel's top edge lands, so an over-reservation opens a gap
  -- between the tabs and the page and an under-reservation buries the first row of settings.
  --
  -- The shape is (n-1) PITCHES plus one full TAB, not n tabs: every row but the last contributes
  -- only its pitch, because the next row's button overlaps its empty top. The LAST row is the one
  -- that has to fit whole, since its bottom is the edge the panel starts at.
  -- red under: n * pitch (the panel eats into the last row of tabs) or n * tabH (a gap opens
  -- under a wrapped strip, which is what the old height-plus-gap form did).
  local O = Fixture.new()
  assertEqual(O.__tabBand(44, 2, 37, 28), 44 + 28 + 37, "one pitch for row 1, a whole tab for row 2")
  assertEqual(O.__tabBand(0, 0, 37, 28), 37,
    "a wrapless call is still treated as one row, same as __tabPlacement")
  assertEqual(O.__tabBand(0, 1, 37, 28), 37, "one row reserves exactly one tab, no pitch at all")
  assertEqual(O.__tabBand(0, 3, 24, 24), 72, "pitch == tabH degenerates to n rows")
end)

--- Run `fn` with every frame's CreateTexture, SetPoint and SetHitRectInsets instrumented, and hand
--- back one record per frame: the atlases it asked for, in order, plus its own anchors.
---
--- The kit's base frame answers CreateTexture with the FRAME ITSELF, so "which atlas" is
--- unanswerable off a plain bench -- and it is the whole of several cases below. Wrapping the
--- MOCKS' CreateFrame is the only seam: makeTab, drawContentPanel and the pitch probe build raw
--- frames and nothing is handed in to intercept. It has to be `T.mocks` rather than `_G`, because
--- a loaded chunk reads its globals through the loader's env, whose __index resolves against the
--- mocks table first -- so a _G assignment here would never be seen.
---
--- THE TWO ATLAS FAMILIES ANSWER DIFFERENT HEIGHTS, and that is the point. The client does not draw
--- `Options_Tab_Active_*` at the same height as `Options_Tab_*`, and a harness that answered one
--- number for every atlas could not fail the selection-invariance case below -- which is precisely
--- how that defect shipped green (anti-patterns #70). `activeHeight` defaults to `artHeight + 5`,
--- so a caller that names only one still gets two.
---
--- The measurement is RESET on the way in and on the way out. It is memoized for the life of a
--- session on purpose, so a cached 28 from this harness would follow every later case that never
--- asked to be measured at all.
local INACTIVE_ART, ACTIVE_ART = 28, 33

local function instrument(O, artHeight, activeHeight, fn)
  activeHeight = activeHeight or (artHeight and artHeight + 5)
  O.__resetTabArtHeight()

  local realCreateFrame = T.mocks.CreateFrame
  local buttons, frames = {}, {}
  T.mocks.CreateFrame = function(kind, ...)
    local f = realCreateFrame(kind, ...)
    local rec = { kind = kind, atlases = {}, points = {} }
    if kind == "Button" then buttons[#buttons + 1] = rec else frames[#frames + 1] = rec end
    -- The frame's OWN anchors, which the kit's base stub no-ops. The content panel's whole
    -- correctness is where its four corners land, so they have to be observable -- and so is every
    -- tab's y offset, which is what the selection-invariance case reads.
    function f:SetPoint(point, rel, relPoint, x, y)
      rec.points[point] = { rel = rel, relPoint = relPoint, x = x, y = y }
    end
    function f:SetHitRectInsets(l, r, t, b) rec.hit = { l, r, t, b } end
    function f:CreateTexture()
      local t, atlas = {}, nil
      function t:SetAtlas(name) atlas = name; rec.atlases[#rec.atlases + 1] = name end
      function t:GetHeight()
        if not artHeight then return nil end
        if atlas and atlas:find("Active", 1, true) then return activeHeight end
        return artHeight
      end
      function t:SetPoint() end
      function t:SetTexCoord() end
      function t:SetColorTexture() end
      function t:SetGradient() end
      return t
    end
    return f
  end
  local ok, err = pcall(fn)
  local pitch = O.__tabArtHeight()
  T.mocks.CreateFrame = realCreateFrame
  O.__resetTabArtHeight()
  if not ok then error(err) end
  return buttons, frames, pitch
end

--- The primary strip, instrumented.
local function tabAtlases(O, ctx, spec, artHeight, activeHeight)
  return instrument(O, artHeight, activeHeight, function() O.TabStrip(ctx, spec) end)
end

local function threeTabs(active)
  return {
    tabs = { { key = "a", label = "A" }, { key = "b", label = "B" } },
    value = active,
    onSelect = function() end,
  }
end

test("widgets: a tab is cut from the client's own tab atlases, active art on the selected one",
function()
  -- The strip is meant to read as client chrome, not as a row of drawn rectangles: three atlas
  -- slices per tab off the same state family, and the SELECTED tab off the Active family. Two
  -- earlier attempts got this wrong in a way no assertion caught -- flat color fills, then the
  -- retired Interface/OptionsFrame textures -- so the atlas names are pinned here directly.
  -- red under: one texture instead of three, mixed families on one tab, or the selected tab
  -- drawn from the same art as the rest and distinguished by color alone.
  local O, _, ctx = bench()
  local buttons = tabAtlases(O, ctx, threeTabs("b"))

  assertEqual(#buttons, 2, "one button per tab")
  for i, rec in ipairs(buttons) do
    assertEqual(#rec.atlases, 3, "tab " .. i .. " is three slices: two caps and a middle")
    local family = rec.atlases[1]:match("^Options_Tab_A?c?t?i?v?e?_?") or ""
    for _, a in ipairs(rec.atlases) do
      assertTrue(a:sub(1, #family) == family, "every slice off one family, got " .. a)
    end
  end

  assertTrue(buttons[1].atlases[1]:find("Active", 1, true) == nil,
    "the unselected tab is inactive art: " .. buttons[1].atlases[1])
  assertTrue(buttons[2].atlases[1]:find("Active", 1, true) ~= nil,
    "the selected tab is active art: " .. buttons[2].atlases[1])
end)

test("widgets: a tabbed page gets the client's content panel, drawn as two mirrored halves",
function()
  -- The panel's TOP EDGE is the tab/content separator (options-ui-§13). There is no hairline any
  -- more: the selected tab's foot lands on this and merges into it, which is what makes the strip
  -- read as attached to the page. Two halves, because the atlas has one good corner and the left
  -- one is a mirrored copy of it.
  -- red under: drawing the panel once and stretching a corner across the width, or -- the real
  -- regression risk -- drawing it on an UNTABBED page, where eight of the nine consumers live.
  local O, _, ctx = bench()
  local _, frames = tabAtlases(O, ctx, threeTabs("a"))

  local halves = 0
  for _, rec in ipairs(frames) do
    for _, a in ipairs(rec.atlases) do
      if a == "Options_InnerFrame" then halves = halves + 1 end
    end
  end
  assertEqual(halves, 2, "the content panel is two mirrored halves of one atlas")
end)

test("widgets: the content box is drawn WIDER than the content column it encloses", function()
  -- THE BUG at 12.11.3: the box was anchored on the content column's own edges, so AceGUI's
  -- always-shown scrollbar -- which sits OUTBOARD of CONTENT_RIGHT -- was painted on top of the
  -- right border, and the left-hand row labels butted against the left one. A box has to be
  -- outside everything it contains.
  -- red under: anchoring the panel flush to ctx.chrome, which is the content column exactly.
  local O, _, ctx = bench()
  local _, frames = tabAtlases(O, ctx, threeTabs("a"))

  local panel
  for _, rec in ipairs(frames) do
    for _, a in ipairs(rec.atlases) do
      if a == "Options_InnerFrame" then panel = rec end
    end
  end
  assertTrue(panel ~= nil, "the content panel frame was found")

  local L = lib.LAYOUT
  -- Negative x pushes the top-left corner LEFT of the chrome, positive pushes the top-right
  -- corner RIGHT of it. Both must be non-zero, or the box is on the content column.
  assertEqual(panel.points.TOPLEFT.x, -(L.CONTENT_LEFT - L.PANEL_LEFT))
  assertEqual(panel.points.TOPRIGHT.x, L.CONTENT_RIGHT - L.PANEL_RIGHT)
  assertTrue(panel.points.TOPLEFT.x < 0, "the box starts left of the first widget")
  assertTrue(panel.points.TOPRIGHT.x > 0, "and ends right of the scrollbar")
  assertTrue(L.PANEL_BOTTOM < L.CONTENT_BOTTOM, "and below the last widget")
end)

test("widgets: wrapped rows are packed by the ART's height, so they sit flush", function()
  -- The tab BUTTON is taller than the atlas it carries -- the extra height is the foot that
  -- overlaps the content panel -- so packing rows by the button height leaves that empty strip
  -- standing between two rows as a visible gap. Reported from a client on a six-tab page.
  -- red under: a pitch of TAB_H, or of TAB_H plus any gap at all.
  local O, _, ctx = bench()
  local tabs = {}
  for i = 1, 4 do tabs[i] = { key = "k" .. i, label = "Tab " .. i } end
  -- The harness's chrome answers 0 from GetWidth, so all four tabs wrap onto their own rows.
  tabAtlases(O, ctx, { tabs = tabs, value = "k1", onSelect = function() end }, 28)

  -- Three rows contribute a pitch each; the LAST contributes a whole tab, because its bottom is
  -- the edge the content panel starts at.
  assertEqual(ctx.chromeHeight, (3 * 28) + O.TAB_H)
  assertTrue(ctx.chromeHeight < 4 * O.TAB_H, "flush rows are shorter than four stacked buttons")
end)

test("widgets: a strip laid out before the canvas has a width re-wraps when the width arrives",
function()
  -- THE BUG: ctx.chrome has zero width until the settings canvas lays itself out, and the FIRST
  -- page a player opens renders before that. placeTabs read 0, fell back to TAB_MIN_W, and every
  -- tab wrapped onto its own row -- a vertical stack that healed the moment you clicked any tab,
  -- because the second render measured a real width. Reported from a client against the General
  -- page; O.EnsureDefaultsButton already carries a note about ctx.body having zero width at
  -- enable time, which is the same client behavior reaching a second piece of chrome.
  -- red under: placing once and never again, which is what shipped.
  local O, _, ctx = bench()
  local tabs = {}
  for i = 1, 4 do tabs[i] = { key = "k" .. i, label = "Tab " .. i } end
  O.TabStrip(ctx, { tabs = tabs, value = "k1", onSelect = function() end })

  -- The harness's chrome answers 0 from GetWidth, so this is the broken first render exactly.
  local stacked = ctx.chromeHeight
  assertTrue(stacked >= 4 * O.TAB_H, "four tabs stacked onto four rows: " .. tostring(stacked))

  ctx.chrome:__fire("OnSizeChanged", 900)
  assertEqual(ctx.chromeHeight, O.TAB_H, "a real width collapsed them onto one row")

  -- Idempotent, and specifically immune to the height change SetChromeHeight itself causes --
  -- which fires this very script. Re-firing at the same width must not re-place anything.
  ctx.chrome:__fire("OnSizeChanged", 900)
  assertEqual(ctx.chromeHeight, O.TAB_H, "the same width again is a no-op, not a second pass")
end)

test("widgets: TabStrip draws one button per tab, marks the active one, and reserves the band",
function()
  -- red under: reserving TAB_H before knowing the row count, or forgetting to reserve at all.
  local O, rec, ctx = bench()
  local picked = {}
  local buttons = O.TabStrip(ctx, {
    tabs = {
      { key = "one",   label = "One" },
      { key = "two",   label = "Two" },
      { key = "three", label = "Three" },
    },
    value = "two",
    onSelect = function(key) picked[#picked + 1] = key end,
  })

  assertEqual(#buttons, 3)
  assertEqual(buttons[1].__template, nil, "tabs are raw Buttons, not a Blizzard template")
  assertFalse(buttons[2]:IsEnabled(), "the active tab is the disabled one, as Blizzard marks a tab")
  assertTrue(buttons[1]:IsEnabled())
  -- The band includes the strip's own baseline (options-ui-§13), not just the row(s) of tabs --
  -- floored rather than pinned exact, because the harness's zero-width chrome wraps these three
  -- tabs onto more than one row (exercised precisely by O.__tabBand's own tests above).
  assertTrue(ctx.chromeHeight >= O.TAB_H,
    "the strip reserved its own row(s)")

  buttons[3]:__fire("OnClick")
  assertEqual(#picked, 1)
  assertEqual(picked[1], "three")
  assertEqual(rec, rec, "no store write: a tab is not a setting")
end)

test("widgets: clicking the ACTIVE tab does not re-fire onSelect", function()
  -- A re-render on every click of the tab you are already on is a page that flickers for
  -- nothing, and on a host whose renderer refuses in combat it is a refusal message for
  -- nothing.
  -- red under: wiring OnClick before checking the active key.
  local O, _, ctx = bench()
  local fired = 0
  local buttons = O.TabStrip(ctx, {
    tabs = { { key = "a", label = "A" }, { key = "b", label = "B" } },
    value = "a",
    onSelect = function() fired = fired + 1 end,
  })
  buttons[1]:__fire("OnClick")
  assertEqual(fired, 0)
  buttons[2]:__fire("OnClick")
  assertEqual(fired, 1)
end)

test("widgets: a second TabStrip call replaces the first rather than stacking on it", function()
  -- A strip is redrawn whenever the page's subject changes. Leaving the old buttons parented to
  -- the chrome would stack two strips, with only the newer one wired up -- and the older one on
  -- top, swallowing the clicks.
  -- red under: creating buttons without releasing the previous set.
  local O, _, ctx = bench()
  O.TabStrip(ctx, { tabs = { { key = "a", label = "A" } }, value = "a", onSelect = function() end })
  local second = O.TabStrip(ctx, {
    tabs = { { key = "a", label = "A" }, { key = "b", label = "B" } },
    value = "b", onSelect = function() end,
  })
  assertEqual(#second, 2)
  -- The 2 buttons plus the strip's own baseline texture (options-ui-§13), which travels in the
  -- same ledger so a re-render cannot leave the old one floating over the new strip.
  assertEqual(#ctx.__tabKids, 3, "the first strip's furniture was released, not orphaned")
end)

test("widgets: re-selecting the same tabs builds no second set of frames", function()
  -- The strip is torn down and redrawn on EVERY tab click, and WoW never destroys a frame. A
  -- strip that CREATES its buttons and its content panel each time therefore leaks one full set
  -- per click for as long as the player leaves the panel open, and the release that was supposed
  -- to cover it only hid and unparented -- which is an allocator wearing a pool's name, the exact
  -- shape LibKa0s-Pool-1.0 was extracted to end. Nothing about it is visible from outside: the
  -- panel draws correctly, every case below this one stays green, and the only symptom is a
  -- client that gets heavier the longer settings is open.
  --
  -- Counted through the MOCKS' CreateFrame for the same reason `instrument` above wraps it there:
  -- a loaded chunk reads its globals through the loader's env, which resolves against the mocks
  -- table first, so a _G assignment would never be seen.
  -- red under: minor 13, where TabStrip calls makeTab and drawContentPanel per render.
  local O, _, ctx = bench()
  local tabs = {
    { key = "one",   label = "One" },
    { key = "two",   label = "Two" },
    { key = "three", label = "Three", tooltip = "The third one" },
  }
  local function select(key)
    O.TabStrip(ctx, { tabs = tabs, value = key, onSelect = function() end })
  end

  -- The first pass is deliberately UNCOUNTED. The claim is not that a strip never allocates --
  -- it has to, once -- but that the second click over the same three tabs allocates nothing.
  for _, key in ipairs({ "one", "two", "three" }) do select(key) end

  local created, realCreateFrame = 0, T.mocks.CreateFrame
  T.mocks.CreateFrame = function(...)
    created = created + 1
    return realCreateFrame(...)
  end
  local ok, err = pcall(function()
    for _, key in ipairs({ "one", "two", "three" }) do select(key) end
  end)
  T.mocks.CreateFrame = realCreateFrame
  if not ok then error(err) end

  assertEqual(created, 0, "a second pass over the same tabs built frames instead of reusing them")
  assertEqual(#ctx.__tabKids, 4, "three tabs and one content panel, not a growing pile")
end)

test("widgets: TabStrip refuses politely with no AceGUI and with no tabs", function()
  -- Every maker in this file answers nil having drawn nothing rather than raising, because the
  -- degraded path is a real one: a consumer vendored without AceGUI must show a plain page.
  -- red under: indexing spec.tabs before checking it.
  withoutAceGUI(function()
    local O, _, ctx = bench()
    assertNil(O.TabStrip(ctx, { tabs = { { key = "a", label = "A" } } }))
  end)

  local O2, _, ctx2 = bench()
  assertNil(O2.TabStrip(ctx2, { tabs = {} }))
  assertNil(O2.TabStrip(ctx2, nil))
end)

-- ── the page banner ────────────────────────────────────────────────────────────────────────────────

test("widgets: PageBanner draws a seeded picker and reserves the banner band", function()
  -- red under: reserving nothing, or seeding the dropdown from the list's first key.
  local O, _, ctx = bench()
  local chosen = {}
  local dd = O.PageBanner(ctx, {
    label = "Window",
    list  = { [1] = "Multi Meters #1", [2] = "Multi Meters #2" },
    order = { 1, 2 },
    value = 2,
    onSelect = function(key) chosen[#chosen + 1] = key end,
  })

  assertEqual(dd.type, "Dropdown")
  assertEqual(dd.value, 2, "seeded from the caller's pointer, not from the list")
  -- The recorded band is the WIDENED one -- the raw dropdown height plus the gap/rule/gap that
  -- separate the banner from whatever is drawn under it (options-ui-§14) -- not the raw height
  -- itself.
  assertEqual(ctx.__bannerHeight, O.__bannerBand(O.BANNER_H))
  assertTrue(ctx.chromeHeight >= O.BANNER_H)

  dd:__fire("OnValueChanged", 1)
  assertEqual(#chosen, 1)
  assertEqual(chosen[1], 1)
end)

test("widgets: banner then strip reserve ONE band between them, not two", function()
  -- The two are drawn in that order by every page that has both, and the band has to hold both --
  -- the banner's own row, the gap/rule/gap under it, the tab row, and the strip's own baseline.
  -- A strip that reserved only its own rows would slide up under the banner.
  -- red under: SetChromeHeight overwriting rather than accumulating the banner's share, or the
  -- gap/rule/gap/baseline block going missing from the total.
  local O, _, ctx = bench()
  O.PageBanner(ctx, { label = "W", list = { [1] = "One" }, order = { 1 }, value = 1,
                      onSelect = function() end })
  O.TabStrip(ctx, { tabs = { { key = "a", label = "A" } }, value = "a",
                    onSelect = function() end })
  local bannerBand = O.__bannerBand(O.BANNER_H)
  local reserved = O.__tabBand(bannerBand, 1, O.TAB_H, O.TAB_H)
  assertEqual(ctx.chromeHeight, reserved)
  assertTrue(ctx.chromeHeight > O.BANNER_H + O.TAB_H,
    "the gap and the rule widened the band beyond the bare banner + tab row")
end)

test("widgets: banner then strip leave no overlap in the reserved band", function()
  -- The regression itself: a strip drawn at ctx.chrome's TOPLEFT is drawn on top of the
  -- banner's dropdown, which anchors there too. Position is unobservable through the widget --
  -- the harness no-ops SetPoint -- so this recomputes __tabPlacement from the SAME
  -- ctx.__bannerHeight PageBanner just recorded, the only number placeTabs' `top` argument is
  -- built from.
  -- red under: placeTabs ignoring ctx.__bannerHeight when it builds `top`.
  local O, _, ctx = bench()
  O.PageBanner(ctx, { label = "W", list = { [1] = "One" }, order = { 1 }, value = 1,
                      onSelect = function() end })
  O.TabStrip(ctx, { tabs = { { key = "a", label = "A" } }, value = "a",
                    onSelect = function() end })
  assertTrue(ctx.__bannerHeight > 0, "PageBanner recorded a band")

  local placement = O.__tabPlacement({ 60 }, 200, 0, ctx.__bannerHeight, O.TAB_H)
  assertEqual(placement[1].y, -ctx.__bannerHeight,
    "the strip's first row starts exactly at the bottom of the banner's band, never above it")
end)

test("widgets: PageBanner refuses politely with no AceGUI and with no spec", function()
  -- red under: reading spec.list before checking spec.
  withoutAceGUI(function()
    local O, _, ctx = bench()
    assertNil(O.PageBanner(ctx, { label = "W", list = {}, order = {}, value = 1 }))
  end)

  local O2, _, ctx2 = bench()
  assertNil(O2.PageBanner(ctx2, nil))
end)

test("widgets: repeated strip renders do not grow the page-wide chrome ledger", function()
  -- A tab click redraws the strip and NOT the banner, so anything the strip files in the
  -- page-wide ledger is never cleared -- it accumulates for the life of the panel, holding
  -- buttons already hidden and unparented. On a page with no banner nothing clears it at all.
  -- red under: TabStrip appending its buttons to __chromeKids as well as __tabKids.
  local O, _, ctx = bench()
  local spec = {
    tabs = { { key = "a", label = "A" }, { key = "b", label = "B" } },
    value = "a", onSelect = function() end,
  }
  O.TabStrip(ctx, spec)
  local after1 = #(ctx.__chromeKids or {})
  for _ = 1, 5 do O.TabStrip(ctx, spec) end
  assertEqual(#(ctx.__chromeKids or {}), after1,
    "the page-wide ledger grew across strip re-renders")
  -- 2 buttons plus the strip's own baseline (options-ui-§13), and no more: the ledger is reset
  -- every render rather than appended to.
  assertEqual(#ctx.__tabKids, 3, "the strip still tracks its own furniture, not a growing pile")
end)


-- ── the tabbed page ────────────────────────────────────────────────────────────────────────

--- Every label and heading currently sitting in a ctx's scroll, in order.
---
--- Built on Fixture.flatten rather than on a second hand-rolled walk: the fixture already owns
--- "every widget below this one, depth first", and a private copy here would be the thing that
--- disagrees with it the next time the flow engine nests a row one level deeper.
local function scrollLabels(ctx)
  local out = {}
  if not ctx.scroll then return out end
  for _, w in ipairs(Fixture.flatten(ctx.scroll)) do
    if w.type == "Heading" then
      out[#out + 1] = "HEADING:" .. tostring(w.text)
    elseif w.labelText then
      out[#out + 1] = w.labelText
    end
  end
  return out
end

test("widgets: a tabbed page draws ONLY the active group's rows", function()
  -- The partition is the whole feature. A renderer that drew the strip and then every row would
  -- look right on the first tab and be a 35-control scroll under a strip on every other.
  -- red under: rendering d.rowsForPage whole, or filtering on order rather than on group.
  local O, _, ctx = bench()
  local groups = O.RenderTabbedSchema(ctx, "tabbed")

  assertEqual(table.concat(groups, "|"), "Alpha|Beta|Gamma|Delta",
    "the tabs are the groups, in DECLARATION order")

  local labels = table.concat(scrollLabels(ctx), "|")
  assertTrue(labels:find("Alpha one", 1, true) ~= nil)
  assertTrue(labels:find("Alpha two", 1, true) ~= nil)
  assertNil(labels:find("Beta one", 1, true), "a group that is not the active tab is not drawn")
  assertNil(labels:find("Gamma one", 1, true))
end)

test("widgets: a tabbed page draws no section heading -- the tab IS the heading", function()
  -- red under: passing the rows through the four-argument RenderRows.
  local O, _, ctx = bench()
  O.RenderTabbedSchema(ctx, "tabbed")
  for _, label in ipairs(scrollLabels(ctx)) do
    assertNil(label:find("^HEADING:"), "a tabbed page drew a heading: " .. label)
  end
end)

test("widgets: an UNtabbed page still draws its headings", function()
  -- The amendment to RenderRows is opt-in through a fifth argument, so every existing caller
  -- must behave exactly as it did. This is the case that pins that.
  -- red under: defaulting noHeadings to true, or dropping O.Section from the untabbed path.
  local O, _, ctx = bench()
  O.RenderSchema(ctx, "general")
  local sawHeading = false
  for _, label in ipairs(scrollLabels(ctx)) do
    if label:find("^HEADING:") then sawHeading = true end
  end
  assertTrue(sawHeading, "an untabbed page lost its section headings")
end)

test("widgets: clicking a tab clears the scroll and renders the new group", function()
  -- red under: rendering the new group without clearing, which appends it under the old one.
  local O, _, ctx = bench()
  O.RenderTabbedSchema(ctx, "tabbed")
  local buttons = ctx.__tabKids
  buttons[3]:__fire("OnClick")

  assertEqual(ctx.activeTab, "Gamma")
  local labels = table.concat(scrollLabels(ctx), "|")
  assertTrue(labels:find("Gamma one", 1, true) ~= nil)
  assertNil(labels:find("Alpha one", 1, true), "the previous tab's rows were left behind")
end)

test("widgets: the active tab survives a re-render, and heals when its group disappears",
function()
  -- A window switch re-renders the page and must land on the same tab (options-ui-§14).
  -- But a ctx.activeTab naming a group the page no longer has -- a filtered subset, a renamed
  -- section -- would render an empty page under a strip, so it falls back to the first.
  -- red under: seeding activeTab unconditionally, or trusting it without checking membership.
  local O, _, ctx = bench()
  O.RenderTabbedSchema(ctx, "tabbed")
  ctx.__tabKids[2]:__fire("OnClick")
  assertEqual(ctx.activeTab, "Beta")

  O.RenderTabbedSchema(ctx, "tabbed")
  assertEqual(ctx.activeTab, "Beta", "a re-render kept the tab")

  ctx.activeTab = "NoSuchGroup"
  O.RenderTabbedSchema(ctx, "tabbed")
  assertEqual(ctx.activeTab, "Alpha", "a stale tab healed to the first group")
end)

test("widgets: a one-group page draws a ONE-TAB strip", function()
  -- The reversal at minor 13 (options-ui-§13). "A strip over a single tab is chrome for its own
  -- sake" is a true sentence about one page and the wrong rule for a panel: a player moving
  -- between pages meets a strip on most of them, and the page that lost its strip is the one that
  -- looks broken. The tab is also the only thing naming the group once `noHeadings` has suppressed
  -- the heading, so the fallback took the section's name off the page as well.
  --
  -- Pointed at the "solo" fixture page, which exists for exactly this and holds ONE group.
  -- red under: restoring the `#groups < 2` fallback to O.RenderSchema.
  local O, _, ctx = bench()
  local groups = O.RenderTabbedSchema(ctx, "solo")
  assertEqual(#groups, 1, "the solo fixture page must hold exactly one group")
  assertEqual(ctx.chromeHeight, O.TAB_H, "a one-tab strip reserves exactly one row of tabs")
  -- One button plus the content panel, which travels in the same ledger.
  assertEqual(#(ctx.__tabKids or {}), 2, "the one-group page drew no strip")
  assertFalse(ctx.__tabKids[1]:IsEnabled(), "the tab that cannot be clicked IS the section label")

  -- And the group's own heading stays suppressed: the tab carries the name, exactly as it does on
  -- a page with four.
  for _, label in ipairs(scrollLabels(ctx)) do
    assertNil(label:find("^HEADING:"), "a one-tab page drew a heading as well as its tab: " .. label)
  end
end)

test("widgets: a page whose rows carry no group renders untabbed AND says so", function()
  -- Every row on every page carries a `group` (options-ui-§13). A page whose rows do not cannot
  -- draw a strip, and that is an authoring defect (anti-patterns #69) rather than a shape to
  -- absorb -- but it still renders, because a blank page under an empty strip is a worse failure
  -- than a strip-less one.
  -- red under: falling through to the strip with an empty tab list, or swallowing the report.
  local O, rec, ctx = bench({
    rowsForPage = function()
      return {
        { path = "orphanOne", type = "bool", label = "Orphan one", default = false },
        { path = "orphanTwo", type = "bool", label = "Orphan two", default = false },
      }
    end,
  })

  local groups = O.RenderTabbedSchema(ctx, "orphans")
  assertEqual(#groups, 0)
  assertEqual(#(ctx.__tabKids or {}), 0, "there is nothing to name a tab with, so no strip")

  local labels = table.concat(scrollLabels(ctx), "|")
  assertTrue(labels:find("Orphan one", 1, true) ~= nil, "the rows still rendered")
  assertTrue(labels:find("Orphan two", 1, true) ~= nil)

  local said = 0
  for _, line in ipairs(rec.chat) do
    if line:find("orphans", 1, true) and line:find("no grouped rows", 1, true) then said = said + 1 end
  end
  assertEqual(said, 1, "the page key was reported exactly once")
end)

test("widgets: a host that omits print still sees NO_GROUPS in the chat frame", function()
  -- The shell builds ONE sink at :New -- the descriptor's `print` when it is a function, and
  -- DEFAULT_CHAT_FRAME:AddMessage when it is not (`LibKa0s/Options.lua`) -- and this file used to
  -- build a second one, `d.print or function() end`, with neither the type guard nor the fallback.
  -- A host that passes no printer therefore had every widget-side diagnostic dropped on the floor:
  -- NO_GROUPS, EMPTY_DROPDOWN, DEAD_BUTTON and BUTTON_FAILED, which are the four lines that exist
  -- to name an authoring defect out loud. C01 shipped in exactly that silence.
  -- red under: __AttachWidgets building its own sink instead of reading the shell's O.__print.
  local _, rec = Fixture.new()
  local d = {}
  for k, v in pairs(rec.d) do d[k] = v end
  d.print = nil
  d.rowsForPage = function()
    return { { path = "orphanOne", type = "bool", label = "Orphan one", default = false } }
  end
  local O = lib:New(d)
  local ctx = O.CreatePanel("NoPrinterPanel", "No printer", {})

  local chat, got = T.mocks.DEFAULT_CHAT_FRAME, {}
  rawset(chat, "AddMessage", function(_, line) got[#got + 1] = line end)
  local ok, err = pcall(O.RenderTabbedSchema, ctx, "orphans")
  rawset(chat, "AddMessage", nil)
  if not ok then error(err) end

  assertTrue(table.concat(got, "\n"):find("no grouped rows", 1, true) ~= nil,
    "the report must reach the shell's sink, not a discard: " .. table.concat(got, "\n"))
end)

test("widgets: with no AceGUI a tabbed page reports no tabs and draws nothing", function()
  -- With no AceGUI there is nothing to draw AT ALL: EnsureScroll answers nil and every maker
  -- in the file refuses, so this reports an empty tab list -- exactly what RenderSchema would
  -- also have drawn, reached or not.
  -- red under: returning the computed group list instead of an empty one when AceGUI is absent.
  withoutAceGUI(function()
    local O, _, ctx = bench()
    local groups = O.RenderTabbedSchema(ctx, "tabbed")
    assertEqual(#groups, 0, "no AceGUI, no tabs to report")
  end)
end)

-- ── the strip's geometry is invariant under the selection (R4c) ────────────────────────────

test("widgets: a wrapped strip's geometry is IDENTICAL for every value of the selection",
function()
  -- THE BUG. The selected tab is cut from `Options_Tab_Active_*` and the rest from
  -- `Options_Tab_*`, and the client does not draw the two families at the same height. TabStrip
  -- recorded the pitch from the FIRST tab it built, whichever that happened to be -- so on a page
  -- whose strip WRAPS, selecting tab 1 packed the rows by the active art and selecting any other
  -- packed them by the inactive art. The band feeds SetChromeHeight, which re-anchors the scroll
  -- AND the content panel, so the whole page below the strip moved and resized when the player
  -- clicked one particular tab. Reported from a client against ConsumableMaster's Macros page
  -- (three wrapped rows, the gap on one tab alone) and again on its Macro Bar page.
  --
  -- It is invisible on an UNWRAPPED strip, because the pitch is multiplied by (rowCount - 1) = 0.
  -- This case therefore forces a wrap: the harness's chrome answers 0 from GetWidth, so every tab
  -- takes TAB_MIN_W and lands on its own row.
  --
  -- red under: restore `ctx.__tabArtH = ctx.__tabArtH or artH` and seed the pitch from whichever
  -- tab was drawn first.
  local tabs = {}
  for i = 1, 8 do tabs[i] = { key = "k" .. i, label = "Tab " .. i } end

  local function geometry(active)
    local O, _, ctx = bench()
    local buttons = tabAtlases(O, ctx,
      { tabs = tabs, value = active, onSelect = function() end }, INACTIVE_ART, ACTIVE_ART)
    local ys = {}
    for i, rec in ipairs(buttons) do ys[i] = rec.points.TOPLEFT.y end
    return ctx.chromeHeight, table.concat(ys, ",")
  end

  local firstBand, firstYs  = geometry("k1")
  local secondBand, secondYs = geometry("k2")

  assertEqual(firstBand, secondBand, "the reserved band moved with the selection")
  assertEqual(firstYs, secondYs, "a tab's row offset moved with the selection")

  -- And it is the INACTIVE art the rows are packed by, not the active one and not a mix: 8 rows
  -- means 7 pitches plus one whole tab.
  local O = Fixture.new()
  assertEqual(firstBand, O.__tabBand(0, 8, O.TAB_H, INACTIVE_ART),
    "the pitch was not the unselected tab art's own height")
end)

test("widgets: every tab's hit rect is inset by the same number the rows are packed by",
function()
  -- The empty strip along a button's top is not part of the tab and must not be clickable: row 2's
  -- button overlaps row 1's art by exactly the pitch, so without the inset it swallows clicks meant
  -- for row 1. Taken off each tab's OWN art the number was the inactive height on every unselected
  -- tab and the active height on the selected one -- so the invariant the code's own comment states
  -- held for all but one button per strip.
  -- red under: `if artH and ...` off drawTabSlices' return, which is where it was read from.
  local O, _, ctx = bench()
  local tabs = {}
  for i = 1, 3 do tabs[i] = { key = "k" .. i, label = "Tab " .. i } end
  local buttons = tabAtlases(O, ctx,
    { tabs = tabs, value = "k2", onSelect = function() end }, INACTIVE_ART, ACTIVE_ART)

  for i, rec in ipairs(buttons) do
    assertTrue(rec.hit ~= nil, "tab " .. i .. " never set a hit rect")
    assertEqual(rec.hit[3], O.TAB_H - INACTIVE_ART,
      "tab " .. i .. " was inset by its own art rather than by the strip's pitch")
  end
end)

test("widgets: the pitch is measured once, off the INACTIVE family, and cached on success only",
function()
  -- Cached on success only is what lets a client that has not resolved the atlas yet answer for
  -- real on the next read, instead of pinning the fallback for the session.
  -- red under: caching the fallback, or measuring off TAB_ATLAS[true].
  local O = Fixture.new()
  O.__resetTabArtHeight()
  assertEqual(O.__tabArtHeight(), O.TAB_H,
    "nothing measurable falls back to the button height, which is the pre-measurement behavior")
  assertEqual(O.__tabArtHeight(), O.TAB_H, "and the miss was not cached as the answer")

  local _, _, pitch = instrument(O, INACTIVE_ART, ACTIVE_ART, function()
    O.__tabArtHeight()
  end)
  assertEqual(pitch, INACTIVE_ART, "measured off the active family, or not measured at all")
end)

-- ── subsection headings (options-ui-§7) ────────────────────────────────────────────────────

--- Only the headings a render emitted, in order.
local function headings(ctx)
  local out = {}
  for _, label in ipairs(scrollLabels(ctx)) do
    local text = label:match("^HEADING:(.*)$")
    if text then out[#out + 1] = text end
  end
  return out
end

test("widgets: a subgroup draws a heading INSIDE a tab, where the group's own is suppressed",
function()
  -- A tab that mixes control types is three subjects under one label, and a player scanning it has
  -- no way to tell where one ends. `noHeadings` suppresses the GROUP heading only.
  -- red under: routing startSubgroup through the same noHeadings flag startGroup takes.
  local O, _, ctx = bench()
  O.RenderRows(ctx, {
    { path = "s1", group = "Appearance", subgroup = "Bar",    type = "bool", label = "Bar one" },
    { path = "s2", group = "Appearance", subgroup = "Bar",    type = "bool", label = "Bar two" },
    { path = "s3", group = "Appearance", subgroup = "Border", type = "bool", label = "Border one" },
  }, nil, nil, { noHeadings = true })

  assertEqual(table.concat(headings(ctx), "|"), "Bar|Border",
    "one heading per subgroup, once each, and never the tab's own name")
end)

test("widgets: a subgroup repeated under a SECOND group draws again", function()
  -- "Border" under Bars and "Border" under Tooltip is the shape the collection is about to be full
  -- of, and a tracker that survived the group boundary would swallow the second one.
  -- red under: dropping `ctx.lastSubgroup = nil` from startGroup.
  local O, _, ctx = bench()
  O.RenderRows(ctx, {
    { path = "b1", group = "Bars",    subgroup = "Border", type = "bool", label = "One" },
    { path = "b2", group = "Tooltip", subgroup = "Border", type = "bool", label = "Two" },
  }, nil, nil, { noHeadings = true })

  assertEqual(table.concat(headings(ctx), "|"), "Border|Border")
end)

test("widgets: the pending line is flushed before a subsection heading", function()
  -- A heading emitted without flushing lands packed into the empty half of the line above it, which
  -- is a heading beside a checkbox.
  -- red under: calling O.Section before flushRow in startSubgroup.
  local O, _, ctx = bench()
  O.RenderRows(ctx, {
    { path = "o1", group = "G", type = "bool", label = "Odd one" },
    { path = "o2", group = "G", subgroup = "Bar", type = "bool", label = "Bar one" },
  }, nil, nil, { noHeadings = true })

  local odd = Fixture.rowWithLabel(ctx.scroll, "Odd one")
  local bar = Fixture.rowWithLabel(ctx.scroll, "Bar one")
  assertTrue(odd ~= nil and bar ~= nil, "both rows rendered")
  assertFalse(odd == bar, "the heading was packed beside the row above it")
end)

test("widgets: an UNTABBED page draws its group heading AND its subgroup headings", function()
  -- The two levels are independent: `noHeadings` is about the group alone, so a page that draws
  -- both must show both, in that order.
  -- red under: making subgroup an alternative to group rather than a level inside it.
  local O, _, ctx = bench()
  O.RenderRows(ctx, {
    { path = "u1", group = "Appearance", subgroup = "Bar", type = "bool", label = "Bar one" },
  })
  assertEqual(table.concat(headings(ctx), "|"), "Appearance|Bar")
end)

-- ── `wide` and `startsLine` ────────────────────────────────────────────────────────────────

test("widgets: a `wide` row renders at FULL width, alone, with the lines around it flushed",
function()
  -- `solo` already renders a row alone -- in the LEFT HALF. `wide` is the other thing, and it is
  -- named to match RenderGrid's field of the same meaning rather than redefining `solo`, which
  -- would silently widen every solo row in nine shipped addons.
  -- red under: reusing `solo`, which leaves the row at HALF and the right half empty.
  local O, _, ctx = bench()
  O.RenderRows(ctx, {
    { path = "w1", group = "G", type = "bool", label = "Before" },
    { path = "w2", group = "G", type = "bool", label = "Spanning", wide = true },
    { path = "w3", group = "G", type = "bool", label = "After" },
  })

  local before   = Fixture.rowWithLabel(ctx.scroll, "Before")
  local spanning = Fixture.rowWithLabel(ctx.scroll, "Spanning")
  local after    = Fixture.rowWithLabel(ctx.scroll, "After")
  assertFalse(before == spanning, "the wide row joined the line above it")
  assertFalse(spanning == after, "the row below joined the wide row's line")
  assertEqual(#spanning.children, 1, "a wide row shares its line with nothing")

  local widget = spanning.children[1]
  assertTrue(widget.fullWidth, "the wide row was not given the full width")
  assertNil(widget.relativeWidth, "and it must not also carry a half-width")
end)

test("widgets: `startsLine` flushes a half-full line so a declared pair cannot be split",
function()
  -- The parity hazard this closes: a color swatch and its class-color companion (options-ui-§17)
  -- declared after an ODD number of rows land as the right half of one line and the left half of
  -- the next, which is a layout the schema cannot see and which breaks again the day a row is
  -- inserted above them.
  -- red under: omitting startsLine from opensLine, which leaves the pair split.
  local O, _, ctx = bench()
  O.RenderRows(ctx, {
    { path = "n1", group = "G", type = "bool", label = "Odd one" },
    { path = "n2", group = "G", type = "color", label = "Bar color", startsLine = true },
    { path = "n3", group = "G", type = "bool",  label = "Use class color" },
  })

  local odd       = Fixture.rowWithLabel(ctx.scroll, "Odd one")
  local swatch    = Fixture.rowWithLabel(ctx.scroll, "Bar color")
  local companion = Fixture.rowWithLabel(ctx.scroll, "Use class color")
  assertFalse(odd == swatch, "the swatch was left on the odd row's line")
  assertEqual(swatch, companion, "the pair was split across two lines")
  assertEqual(#swatch.children, 2, "and the line holds exactly the pair")
end)

test("widgets: `startsLine` on a line that is already empty costs nothing", function()
  -- The flush is conditional on there being something pending, or every startsLine row would emit
  -- an empty Flow row and a spacer above itself.
  -- red under: flushing unconditionally.
  local O, _, ctx = bench()
  O.RenderRows(ctx, {
    { path = "e1", group = "G", type = "color", label = "Bar color", startsLine = true },
    { path = "e2", group = "G", type = "bool",  label = "Use class color" },
  })
  assertEqual(#Fixture.flowRows(ctx.scroll), 1, "an empty line was flushed ahead of the pair")
end)

test("widgets: InlineButtonPair with no right-hand button draws one, at the pair's width",
function()
  -- A frameless addon's Master controls tab has a "Reset all settings" button and no "Reset
  -- position" to sit beside it (options-ui-§15), and that is the only shape that needs this.
  -- red under: indexing rightSpec before checking it.
  local O, _, ctx = bench()
  local row = O.InlineButtonPair(ctx, { text = "Reset all settings", onClick = function() end })
  assertEqual(#row.children, 1)
  assertEqual(row.children[1].text, "Reset all settings")
  assertEqual(row.children[1].relativeWidth, O.BUTTON_PAIR_REL,
    "a lone button still takes the pair's width, so it lines up with every other page's")
end)

-- ── the empty dropdown reports itself ──────────────────────────────────────────────────────

test("widgets: a string row with no values and no dialogControl prints once and still renders",
function()
  -- KickCD's `Label text` is the shipped instance: declared `type = "string"` with neither field,
  -- it reached the dropdown maker and opened on nothing. The opt-in stays -- inference would
  -- silently turn a row whose values function answers empty into a free-text field -- so this line
  -- is what makes forgetting it visible the first time the page is opened.
  -- red under: warning on any empty list, which fires on every LSM row before registration.
  local O, rec, ctx = bench()
  local parent = O.AceGUI:Create("SimpleGroup")
  local dd = O.RenderField(ctx,
    { path = "units.target.label.text", type = "string", label = "Label text" }, parent, 0.5)

  assertEqual(dd.type, "Dropdown", "it still renders -- one broken row must not cost the page")
  local said = 0
  for _, line in ipairs(rec.chat) do
    if line:find("units.target.label.text", 1, true) then said = said + 1 end
  end
  assertEqual(said, 1, "the row's path was reported exactly once")
end)

test("widgets: a values-backed row that is momentarily empty does NOT warn", function()
  -- The deferred-closure case the opt-in exists for: an LSM-backed row's `values` answers an empty
  -- table until the media library has registered anything, and warning about it would fire on
  -- every media dropdown in the collection on the first render.
  -- red under: keying the warning on the resolved list alone.
  local O, rec, ctx = bench()
  local parent = O.AceGUI:Create("SimpleGroup")
  O.RenderField(ctx, {
    path = "bar.texture", type = "string", label = "Bar texture",
    dialogControl = "LSM30_Statusbar", values = function() return {} end,
  }, parent, 0.5)

  for _, line in ipairs(rec.chat) do
    assertNil(line:find("bar.texture", 1, true), "a deferred media list was reported: " .. line)
  end
end)

-- ── the chrome block above the strip (options-ui-§14) ──────────────────────────────────────

test("widgets: PageHeader reserves the band, and the strip lands beneath it", function()
  -- Controls that apply to every tab sit ABOVE the strip: drawn under one tab they read as
  -- belonging to it, and they vanish the moment the player clicks another. O.PageBanner draws
  -- exactly one Dropdown, so what is generalised here is the BAND, not the banner.
  -- red under: reserving the raw height rather than O.__bannerBand's widened one, which lands the
  -- first tab on top of the block's own bottom edge.
  local O, _, ctx = bench()
  local built = {}
  local frame = O.PageHeader(ctx, {
    height = 60,
    build  = function(_, f) built[#built + 1] = f end,
  })

  assertTrue(frame ~= nil, "the block drew nothing")
  assertEqual(built[1], frame, "the host was handed the frame it is to draw into")
  assertEqual(ctx.__bannerHeight, O.__bannerBand(60))
  assertEqual(ctx.chromeHeight, O.__bannerBand(60))

  O.TabStrip(ctx, { tabs = { { key = "a", label = "A" } }, value = "a", onSelect = function() end })
  local placement = O.__tabPlacement({ 60 }, 200, 0, ctx.__bannerHeight, O.TAB_H)
  assertEqual(placement[1].y, -O.__bannerBand(60),
    "the strip's first row must start at the bottom of the block's band, never above it")
end)

test("widgets: a page draws at most ONE chrome block -- the second replaces the first", function()
  -- Two blocks are two bands, and the second pushes the page down for nothing. A page that needs a
  -- picker AND other page-wide controls puts the picker inside the block.
  -- red under: PageHeader appending to __chromeKids without releasing it first.
  local O, _, ctx = bench()
  local first = O.PageHeader(ctx, { height = 60, build = function() end })
  local afterHeader = #ctx.__chromeKids
  assertEqual(afterHeader, 2, "one block plus its hairline rule, and nothing else")

  -- Its own re-render first: a page redraws its header on every subject change, and a block left
  -- parented to the chrome would stack with the older one on top.
  O.PageHeader(ctx, { height = 60, build = function() end })
  assertEqual(#ctx.__chromeKids, afterHeader, "a second header stacked on the first")
  assertFalse(first:IsShown(), "the first block was left on the chrome")

  O.PageBanner(ctx, { label = "W", list = { [1] = "One" }, order = { 1 }, value = 1,
                      onSelect = function() end })
  assertEqual(#ctx.__chromeKids, afterHeader, "the two kinds of block stacked instead of replacing")
end)

test("widgets: PageHeader without a divider draws the block and no rule", function()
  -- red under: reading `spec.divider` truthily, which makes an omitted field mean OFF.
  local O, _, ctx = bench()
  O.PageHeader(ctx, { height = 60, divider = false, build = function() end })
  assertEqual(#ctx.__chromeKids, 1, "the rule was drawn anyway")
end)

test("widgets: a raising PageHeader builder costs the block, not the page", function()
  -- The builder reaches into live addon state, and a raise inside the render pass would take the
  -- strip and everything under it with it.
  -- red under: calling spec.build bare.
  local O, rec, ctx = bench()
  local frame = O.PageHeader(ctx, { height = 60, build = function() error("host blew up") end })
  assertTrue(frame ~= nil, "the block itself must survive its builder")
  local said = 0
  for _, line in ipairs(rec.chat) do
    if line:find("page header failed", 1, true) then said = said + 1 end
  end
  assertEqual(said, 1)
end)

test("widgets: PageHeader refuses politely with no spec and with no height", function()
  -- red under: reserving a zero band, which hides the chrome frame and moves the scroll for
  -- nothing.
  local O, _, ctx = bench()
  assertNil(O.PageHeader(ctx, nil))
  assertNil(O.PageHeader(ctx, { build = function() end }))
  assertNil(O.PageHeader(ctx, { height = 0, build = function() end }))
  assertNil(O.PageHeader(nil, { height = 60 }))
  assertEqual(ctx.chromeHeight, 0, "a refusal must reserve nothing")
end)

-- ── the secondary strip (options-ui-§13) ───────────────────────────────────────────────────

test("widgets: SubTabStrip draws inside the host's frame and reports the height it took",
function()
  -- The primary strip is pinned in the chrome band; a secondary one belongs to the content it
  -- divides and scrolls with it. Pinning a second band would double the chrome and push the page
  -- down twice.
  -- red under: parenting to ctx.chrome, or calling SetChromeHeight, either of which moves the page.
  local O, _, ctx = bench()
  local parent = T.mocks.CreateFrame("Frame", nil, T.mocks.UIParent)
  local tabs = {}
  for i = 1, 5 do tabs[i] = { key = "s" .. i, label = "String " .. i } end

  local picked = {}
  local buttons, height = O.SubTabStrip(ctx, parent, {
    tabs = tabs, value = "s2", onSelect = function(key) picked[#picked + 1] = key end,
  })

  assertEqual(#buttons, 5)
  assertEqual(ctx.chromeHeight, 0, "a secondary strip must not reserve a pinned band")
  assertEqual(#ctx.__subTabKids, 5, "its own ledger, so drawing the strip leaves the primary's alone")
  assertEqual(#(ctx.__tabKids or {}), 0, "and it must never leak into the primary strip's ledger")
  -- The harness's parent answers 0 from GetWidth, so all five wrap onto their own rows: four
  -- pitches plus one whole tab.
  assertEqual(height, O.__tabBand(0, 5, O.TAB_H, O.TAB_H))

  assertFalse(buttons[2]:IsEnabled(), "the active sub tab is the disabled one, same as the primary")
  buttons[4]:__fire("OnClick")
  assertEqual(#picked, 1)
  assertEqual(picked[1], "s4")
end)

test("widgets: a second SubTabStrip call releases the first rather than stacking on it", function()
  -- A secondary strip is redrawn whenever its category is. Buttons left parented to the host's
  -- frame would stack, with the older set on top swallowing the clicks -- the same failure the
  -- primary strip's ledger exists to prevent.
  -- red under: appending to __subTabKids without releasing it.
  local O, _, ctx = bench()
  local parent = T.mocks.CreateFrame("Frame", nil, T.mocks.UIParent)
  local spec = {
    tabs = { { key = "a", label = "A" }, { key = "b", label = "B" } },
    value = "a", onSelect = function() end,
  }
  local first = O.SubTabStrip(ctx, parent, spec)
  for _ = 1, 4 do O.SubTabStrip(ctx, parent, spec) end
  assertEqual(#ctx.__subTabKids, 2, "the ledger grew across re-renders")
  assertFalse(first[1]:IsShown(), "the first strip's buttons were left on the host's frame")
end)

test("widgets: ClearScroll drains the sub-tab ledger before AceGUI pools the parent", function()
  -- SubTabStrip drains its own ledger ON ENTRY, which covers redrawing a strip. It cannot cover the
  -- case where the page moves to a tab that draws NO secondary strip: SubTabStrip never runs, so
  -- nothing drains, and ClearScroll's ReleaseChildren hands the buttons' parent back to AceGUI's
  -- pool with them still shown on it. The next page to take that pooled frame inherits them.
  -- red under: dropping the `O.__releaseSubTabs(ctx)` call at the top of O.ClearScroll.
  local O, _, ctx = bench()
  local parent = T.mocks.CreateFrame("Frame", nil, T.mocks.UIParent)
  local buttons = O.SubTabStrip(ctx, parent, {
    tabs = { { key = "a", label = "A" }, { key = "b", label = "B" } },
    value = "a", onSelect = function() end,
  })
  assertEqual(#ctx.__subTabKids, 2)

  -- The page re-renders onto a tab with no secondary strip: ClearScroll, and no SubTabStrip call.
  O.ClearScroll(ctx)

  assertEqual(#ctx.__subTabKids, 0, "the ledger survived the render that released its parent")
  assertFalse(buttons[1]:IsShown(), "a sub tab button outlived the render that drew it")
  assertFalse(buttons[2]:IsShown(), "a sub tab button outlived the render that drew it")
end)

test("widgets: a wrapped SUB strip's geometry is invariant under the selected sub tab", function()
  -- The same rule as the primary strip, over the new function: it packs by the same measured pitch
  -- and must not read anything back off a tab that was drawn in whichever state it happened to be.
  -- red under: measuring the pitch inside SubTabStrip off its own first button.
  local tabs = {}
  for i = 1, 6 do tabs[i] = { key = "s" .. i, label = "String " .. i } end

  local function geometry(active)
    local O, _, ctx = bench()
    local parent = T.mocks.CreateFrame("Frame", nil, T.mocks.UIParent)
    local height
    local buttons = instrument(O, INACTIVE_ART, ACTIVE_ART, function()
      _, height = O.SubTabStrip(ctx, parent, {
        tabs = tabs, value = active, onSelect = function() end,
      })
    end)
    local ys = {}
    for i, rec in ipairs(buttons) do ys[i] = rec.points.TOPLEFT.y end
    return height, table.concat(ys, ",")
  end

  local firstHeight, firstYs   = geometry("s1")
  local secondHeight, secondYs = geometry("s3")
  assertEqual(firstHeight, secondHeight, "the reported height moved with the selection")
  assertEqual(firstYs, secondYs, "a sub tab's row offset moved with the selection")
end)

test("widgets: SubTabStrip refuses politely with no AceGUI, no parent and no tabs", function()
  -- red under: indexing spec.tabs before checking it.
  withoutAceGUI(function()
    local O, _, ctx = bench()
    local parent = T.mocks.CreateFrame("Frame", nil, T.mocks.UIParent)
    assertNil(O.SubTabStrip(ctx, parent, { tabs = { { key = "a", label = "A" } } }))
  end)

  local O2, _, ctx2 = bench()
  local parent2 = T.mocks.CreateFrame("Frame", nil, T.mocks.UIParent)
  assertNil(O2.SubTabStrip(ctx2, parent2, { tabs = {} }))
  assertNil(O2.SubTabStrip(ctx2, parent2, nil))
  assertNil(O2.SubTabStrip(ctx2, nil, { tabs = { { key = "a", label = "A" } } }))
end)
