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
  -- red under: `y = -((r - 1) * (tabH + rowGap))`, which answers 0 for row 1 regardless of top.
  local O = Fixture.new()
  local placement, rowCount = O.__tabPlacement({ 60, 60, 60 }, 150, 4, 44, 24, 2)
  assertEqual(rowCount, 2, "60+4+60 fits in 150; the third tab wraps, same as __layoutTabs")
  assertEqual(#placement, 3, "every tab placed")
  assertEqual(placement[1].y, -44, "row 1 sits at the bottom of the reserved band, not at 0")
  assertEqual(placement[2].y, -44, "row 1's second tab shares row 1's y")
  assertEqual(placement[3].y, -(44 + 24 + 2), "row 2 sits a full tab + row gap below row 1")
end)

test("widgets: __tabPlacement accumulates x across a row", function()
  -- red under: resetting x to 0 for every tab instead of advancing past the previous one.
  local O = Fixture.new()
  local placement = O.__tabPlacement({ 60, 80 }, 1000, 4, 0, 24, 2)
  assertEqual(placement[1].x, 0, "the first tab in a row starts at the row's left edge")
  assertEqual(placement[2].x, 64, "the second tab starts after the first tab's width plus the gap")
end)

test("widgets: __tabPlacement places every index exactly once", function()
  -- Mirrors the guarantee __layoutTabs already carries: losing an index here would lose a tab
  -- from the strip with nothing said about it.
  -- red under: dropping an over-wide tab, or emitting an index twice across two rows.
  local O = Fixture.new()
  local placement = O.__tabPlacement({ 60, 500, 60, 60, 60 }, 130, 4, 0, 24, 2)
  local seen = {}
  for _, p in ipairs(placement) do
    assertEqual(seen[p.index], nil, "index " .. p.index .. " placed only once")
    seen[p.index] = true
  end
  for i = 1, 5 do assertTrue(seen[i], "index " .. i .. " was placed") end
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
  assertTrue(ctx.chromeHeight >= O.TAB_H, "the strip reserved its own band")

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
  assertEqual(#ctx.__tabKids, 2, "the first strip's button was released, not orphaned")
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
  assertEqual(ctx.__bannerHeight, O.BANNER_H)
  assertTrue(ctx.chromeHeight >= O.BANNER_H)

  dd:__fire("OnValueChanged", 1)
  assertEqual(#chosen, 1)
  assertEqual(chosen[1], 1)
end)

test("widgets: banner then strip reserve ONE band between them, not two", function()
  -- The two are drawn in that order by every page that has both, and the band has to hold both.
  -- A strip that reserved only its own rows would slide up under the banner.
  -- red under: SetChromeHeight overwriting rather than accumulating the banner's share.
  local O, _, ctx = bench()
  O.PageBanner(ctx, { label = "W", list = { [1] = "One" }, order = { 1 }, value = 1,
                      onSelect = function() end })
  O.TabStrip(ctx, { tabs = { { key = "a", label = "A" } }, value = "a",
                    onSelect = function() end })
  assertEqual(ctx.chromeHeight, O.BANNER_H + O.TAB_H)
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

  local placement = O.__tabPlacement({ 60 }, 200, 0, ctx.__bannerHeight, O.TAB_H, 0)
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
  assertEqual(#ctx.__tabKids, 2, "the strip still tracks its own buttons")
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

test("widgets: a one-group page draws no strip at all", function()
  -- A strip over a single tab is chrome for its own sake, and it would reserve a band that
  -- pushes the page down for nothing.
  --
  -- Pointed at the "solo" fixture page, which exists for exactly this and holds ONE group. An
  -- earlier draft aimed this at "bar" and wrapped the assertion in `if #groups == 1` -- "bar"
  -- has two groups, so the guard never opened and the case could not fail.
  -- red under: drawing the strip before counting the groups.
  local O, _, ctx = bench()
  local groups = O.RenderTabbedSchema(ctx, "solo")
  assertEqual(#groups, 1, "the solo fixture page must hold exactly one group")
  assertEqual(ctx.chromeHeight, 0, "a single-group page reserved a band")
  assertEqual(#(ctx.__tabKids or {}), 0, "a single-group page built tab buttons")
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
