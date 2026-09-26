-- tests/test_options_widgets.lua — LibKa0s-Options-1.0's OptionsWidgets.lua: the five schema-row
-- widget makers, the session checkbox, disabledIf on every maker, and RenderField's dispatch.
--
-- Widgets here are the kit's inert recorders: they remember what was set on them and expose
-- __fire(event, ...) so a callback can be driven exactly as AceGUI would drive it on a click or a
-- slider release. That is what makes the real read -> set -> refresh loop observable rather than
-- assumed, and it is why every case below asserts on the STORE as well as on the widget.
--
-- THE PAGE'S CHROME IS NOT HERE. The tab strip, the page banner, the header block and the secondary
-- strip moved to tests/test_options_tabs.lua at v1.39.0 (issue #8), in the same commit as the
-- module they mirror and on that module's seam -- which is exactly why #8 waited for #16 rather
-- than splitting by widget family: a suite partitioned before its module was would have paired
-- with nothing, and one-suite-per-module is what makes a red legible.
--
-- THE ID SURFACE'S CASES ARE NOT HERE EITHER. The ResolveId / IdInput / IdList cases moved with
-- their module (issue #33, in the commit that peeled OptionsIds.lua and OptionsIdList.lua out of
-- OptionsWidgets.lua for #32): to tests/test_options_ids.lua, tests/test_options_idlist.lua and
-- tests/test_options_idlist_layout.lua, with the benches they share in tests/fixture_ids.lua.
--
-- NOR ARE THE REST OF OptionsWidgets.lua's CASES. What was left of this suite after that peel was
-- still over layout-§1's cap, and the module has no further seam of its own, so #33's second part
-- split the suite on its case seams, each block moved unchanged: O.ChoiceGrid to
-- tests/test_options_choicegrid.lua; the two-column flow engine (RenderRows, RenderGrid, Section,
-- ClearScroll, InlineButtonPair, `wide` / `startsLine`, subsection headings) and the tabbed page
-- to tests/test_options_flow.lua; O.TextRow and O.BuildLandingPage to
-- tests/test_options_landing.lua. The benches the four share are in tests/fixture_widgets.lua.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil, assertNear =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil, T.assertNear
local Fixture = dofile("tests/fixture_options.lua")
local bench = dofile("tests/fixture_widgets.lua")("WidgetBench").bench

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

test("widgets: a bool row renders a CheckBox labeled and seeded from the schema", function()
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
    "every key in " .. row.path .. "'s values list is offered, alphabetized")
end)

test("widgets: a row with explicit `sorting` keeps that order instead of alphabetizing",
  function()
  -- Outline styles read in a deliberate order (None, Outline, Thick); alphabetizing scrambles it.
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

test("widgets: a color row opts OUT of alpha by declaring it, and cannot before", function()
  -- The flipped default. `row.hasAlpha and true or false` made an absent field and a declared
  -- false the same thing, so "no alpha" was inexpressible while the codec stored an alpha the
  -- user could never reach.
  local withAlpha = render("barColor")
  assertTrue(withAlpha.hasAlpha, "absent means yes")
  local without = render("borderColor")
  assertFalse(without.hasAlpha, "and a declared false is honored")
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

-- ── color picker ──────────────────────────────────────────────────────────────────────────

test("widgets: a color row renders a ColorPicker seeded through the descriptor's codec", function()
  local O, rec, ctx = bench()
  rec.store.barColor = { r = 0.1, g = 0.2, b = 0.3, a = 0.4 }
  local cp = O.RenderField(ctx, rec.byPath.barColor, O.AceGUI:Create("SimpleGroup"), 0.5)
  assertEqual(cp.type, "ColorPicker")
  assertTrue(cp.hasAlpha, "alpha is on by default — the row declares nothing")
  assertNear(cp.color.r, 0.1, 1e-6)
  assertNear(cp.color.a, 0.4, 1e-6)
end)

test("widgets: a color picker substitutes 1s for a missing or corrupt stored color", function()
  local O, rec, ctx = bench()
  rec.store.barColor = "not a table"
  local cp = O.RenderField(ctx, rec.byPath.barColor, O.AceGUI:Create("SimpleGroup"), 0.5)
  assertEqual(cp.color.r, 1)
  assertEqual(cp.color.a, 1)
end)

test("widgets: the color codec is the descriptor's, so an array-storing host is not translated",
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

test("widgets: disabledIf grays the swatch out while its sibling toggle is on", function()
  local O, rec, ctx = bench()
  rec.store.useClassColor = true
  local cp = O.RenderField(ctx, rec.byPath.barColor, O.AceGUI:Create("SimpleGroup"), 0.5)
  assertTrue(cp.disabled, "class color on -> swatch disabled")

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
local function widgetLabeled(O, ctx, label)
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
  local first = widgetLabeled(O, ctx, "Lock Position")
  local second = widgetLabeled(O, ctx, "Show tooltips")
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
  assertTrue(widgetLabeled(O, ctx, "Profile label").disabled,
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

test("widgets: a color drag does NOT refresh every panel", function()
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
  -- matching swatch grays out on the same frame.
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

test("widgets: RenderField returns nil for an unrecognized type instead of erroring", function()
  local O, _, ctx = bench()
  assertNil(O.RenderField(ctx, { path = "x", type = "mystery", label = "X" },
    O.AceGUI:Create("SimpleGroup"), 0.5))
end)

test("widgets: RenderField adds the widget to the parent it was given", function()
  local w, _, _, _, _, parent = render("barWidth", 0.5)
  assertEqual(#parent.children, 1)
  assertEqual(parent.children[1], w)
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
-- makeSlider, which is exactly the old behavior.

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
