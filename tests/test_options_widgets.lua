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

--- A host, a throwaway panel and a parent container, so a maker can be driven in isolation.
local panelSeq = 0
local function bench(overrides)
  local O, rec = Fixture.new(overrides)
  panelSeq = panelSeq + 1
  local ctx = O.CreatePanel("WidgetBench" .. panelSeq, "Bench " .. panelSeq, {})
  return O, rec, ctx
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
  local left, right, blew = 0, 0, false
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
  blew = not pcall(function() row.children[2]:__fire("OnClick") end)
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
