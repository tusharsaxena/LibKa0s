-- tests/test_options_switched.lua — LibKa0s-Options-1.0's switched sections (OptionsWidgets minor
-- 22): a row carrying `shownWhen = { path, equals }` is drawn only while its selector holds that
-- value (or one of a list), its subsection heading with it, and the page re-renders once, on the next
-- frame, when the selector changes; a row list with no `shownWhen` renders exactly as before. From
-- OptionsSwitch minor 1 (the switched sections peeled out of OptionsWidgets.lua at its minor 37, LK-10
-- of Ka0sAddonsCommonTasks docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK, decision D-17), the OR form:
-- `shownWhen = { any = { { path, equals }, ... } }`, drawn while any clause holds.
--
-- Its own suite rather than more cases in tests/test_options_widgets.lua, which was over layout-§1's
-- cap when this was written (issue #33, since split): new cases on a seam of their own go to a file
-- of their own, as v1.44.0's removeStyle cases did.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local Fixture = dofile("tests/fixture_options.lua")
local mocks = T.mocks

local panelSeq = 0

--- A selector and three switched subsections, the Layout -> Anchor shape: A for "a", B for "b",
--- C for "b" or "c". `extra` rows are appended as given.
local function anchorRows(extra)
  local rows = {
    { path = "mode", group = "Anchor", type = "string", label = "Attach to",
      values = { a = "A", b = "B", c = "C" }, sorting = { "a", "b", "c" } },
    { path = "a1", group = "Anchor", subgroup = "Section A", type = "bool", label = "A one",
      shownWhen = { path = "mode", equals = "a" } },
    { path = "a2", group = "Anchor", subgroup = "Section A", type = "bool", label = "A two",
      shownWhen = { path = "mode", equals = "a" } },
    { path = "b1", group = "Anchor", subgroup = "Section B", type = "bool", label = "B one",
      shownWhen = { path = "mode", equals = "b" } },
    { path = "c1", group = "Anchor", subgroup = "Section C", type = "bool", label = "C one",
      shownWhen = { path = "mode", equals = { "b", "c" } } },
  }
  for _, row in ipairs(extra or {}) do
    local n = #rows
    rows[n + 1] = row
  end
  return rows
end

--- A host and a throwaway page, its store holding `mode`.
local function bench(mode)
  local O, rec = Fixture.new()
  panelSeq = panelSeq + 1
  local ctx = O.CreatePanel("SwitchedBench" .. panelSeq, "Bench " .. panelSeq, {})
  rec.store.mode = mode
  return O, rec, ctx
end

--- The labels and heading texts one render drew, in order.
local function drawn(O, ctx)
  local out = {}
  for _, w in ipairs(Fixture.flatten(O.EnsureScroll(ctx))) do
    local t = w.labelText or (w.type == "Heading" and w.text) or nil
    if t then
      local n = #out
      out[n + 1] = t
    end
  end
  return table.concat(out, ",")
end

test("switched: only the subsection the selector names is drawn, its heading with it", function()
  local O, _, ctx = bench("a")
  O.RenderRows(ctx, anchorRows())
  -- red under: flowRows ignoring shownWhen (every section drawn), or skipping the rows but still
  -- emitting the hidden sections' headings (startSubgroup runs before the skip)
  assertEqual(drawn(O, ctx), "Anchor,Attach to,Section A,A one,A two")
end)

test("switched: equals may list several values; the row shows for any of them", function()
  local O, _, ctx = bench("c")
  O.RenderRows(ctx, anchorRows())
  assertEqual(drawn(O, ctx), "Anchor,Attach to,Section C,C one")
  O, _, ctx = bench("b")
  O.RenderRows(ctx, anchorRows())
  -- red under: a list compared as a whole (a table never equals the stored string)
  assertEqual(drawn(O, ctx), "Anchor,Attach to,Section B,B one,Section C,C one")
end)

test("switched: a group's afterGroup hook fires after its last DRAWN row, once", function()
  local O, _, ctx = bench("a")
  local fired = 0
  -- The group's last declared row (C one) is hidden under "a".
  O.RenderRows(ctx, anchorRows(), { Anchor = function() fired = fired + 1 end })
  -- red under: endGroup looking past the drawn rows (the hook waits for a row that never comes)
  assertEqual(fired, 1)
end)

test("switched: changing the selector re-renders the page once, on the next frame", function()
  local O, _, ctx = bench("a")
  local rows = anchorRows()
  local renders = 0
  O.SetRenderer(ctx, function(c)
    renders = renders + 1
    O.ClearScroll(c)
    O.RenderRows(c, rows)
  end)
  ctx.panel:Show(); ctx.panel:__fire("OnShow")
  assertEqual(renders, 1)
  local dd
  for _, w in ipairs(Fixture.flatten(O.EnsureScroll(ctx))) do
    if w.labelText == "Attach to" then dd = w end
  end
  dd:__fire("OnValueChanged", "b")
  -- red under: the re-render run inside the dropdown's own callback (it would release the dropdown)
  assertEqual(renders, 1, "not inside the callback")
  mocks.__fireTimers()
  -- red under: no refresher watching the selector (the page keeps drawing section A)
  assertEqual(renders, 2, "one re-render")
  assertEqual(drawn(O, ctx), "Anchor,Attach to,Section B,B one,Section C,C one")
  mocks.__fireTimers()
  assertEqual(renders, 2, "and only one")
end)

test("switched: a write from anywhere (a slash set, a reset) re-renders too, once per change", function()
  local O, rec, ctx = bench("a")
  local rows = anchorRows()
  local renders = 0
  O.SetRenderer(ctx, function(c)
    renders = renders + 1
    O.ClearScroll(c)
    O.RenderRows(c, rows)
  end)
  ctx.panel:Show(); ctx.panel:__fire("OnShow")
  rec.store.mode = "c"
  O.RefreshScalars()
  O.RefreshScalars()
  mocks.__fireTimers()
  assertEqual(renders, 2, "two scalar sweeps over one change: one re-render")
  assertEqual(drawn(O, ctx), "Anchor,Attach to,Section C,C one")
  O.RefreshScalars()
  mocks.__fireTimers()
  -- red under: the watcher re-rendering on every refresh rather than on a change
  assertEqual(renders, 2, "no change, no re-render")
end)

test("switched: a selector that cannot be read shows its rows rather than losing them", function()
  local O, rec, ctx = bench("a")
  local get = rec.d.get
  rec.d.get = function(path)
    if path == "mode" then error("selector unreadable") end
    return get(path)
  end
  local ok = pcall(O.RenderRows, ctx, anchorRows())
  rec.d.get = get
  assertTrue(ok, "the render survived")
  -- red under: shownNow calling the read unguarded (the whole render raises)
  assertTrue(drawn(O, ctx):find("B one", 1, true) ~= nil, "a raising read reads as shown")
end)

test("switched: rows without shownWhen render as before, and no selector watcher is added", function()
  local O, rec, ctx = bench("a")
  local rows = rec.d.rowsForPage("bar")
  O.RenderRows(ctx, rows)
  local widgets = 0
  for _, w in ipairs(Fixture.flatten(O.EnsureScroll(ctx))) do
    if w.labelText and w.type ~= "SimpleGroup" then widgets = widgets + 1 end
  end
  -- red under: a watcher added for every row when nothing opted in. (Whether the list is copied is
  -- not observable through the surface -- no hook receives the row list; a re-order is caught by the
  -- drawing cases' order assertions above.)
  assertEqual(#ctx.refreshers, widgets, "one refresher per drawn widget, as before minor 22")
  assertNil(ctx.__switchQueued)
  assertFalse(drawn(O, ctx) == "", "the page drew")
end)

test("switched: a bound (path-less) selector reads and is watched through its record", function()
  local O, _, ctx = bench("a")
  -- OptionsCompose's spec.bind shape: no path, a record field, get(key) reading that record.
  local record = { mode = "a", a1 = true, b1 = true }
  local function bound(field, extra)
    local row = { field = field, group = "Anchor", type = "bool",
      get = function(key) return record[key or field] end,
      set = function(v) record[field] = v end }
    for k, v in pairs(extra) do row[k] = v end
    return row
  end
  local rows = {
    bound("mode", { type = "string", label = "Attach to",
      values = { a = "A", b = "B" }, sorting = { "a", "b" } }),
    bound("a1", { subgroup = "Section A", label = "A one", shownWhen = { path = "mode", equals = "a" } }),
    bound("b1", { subgroup = "Section B", label = "B one", shownWhen = { path = "mode", equals = "b" } }),
  }
  local renders = 0
  O.SetRenderer(ctx, function(c)
    renders = renders + 1
    O.ClearScroll(c)
    O.RenderRows(c, rows)
  end)
  ctx.panel:Show(); ctx.panel:__fire("OnShow")
  assertEqual(drawn(O, ctx), "Anchor,Attach to,Section A,A one")
  record.mode = "b"
  O.RefreshScalars()
  mocks.__fireTimers()
  -- red under: the watcher keyed on row.path alone (a bound selector has none, so it is never watched)
  assertEqual(renders, 2, "one re-render")
  assertEqual(drawn(O, ctx), "Anchor,Attach to,Section B,B one")
end)

test("switched: two selectors changing in one frame cost one re-render", function()
  local O, rec, ctx = bench("a")
  rec.store.side = "l"
  local rows = anchorRows({
    { path = "side", group = "Anchor", type = "string", label = "Side",
      values = { l = "L", r = "R" }, sorting = { "l", "r" } },
    { path = "r1", group = "Anchor", subgroup = "Section R", type = "bool", label = "R one",
      shownWhen = { path = "side", equals = "r" } },
  })
  local renders = 0
  O.SetRenderer(ctx, function(c)
    renders = renders + 1
    O.ClearScroll(c)
    O.RenderRows(c, rows)
  end)
  ctx.panel:Show(); ctx.panel:__fire("OnShow")
  rec.store.mode = "b"
  rec.store.side = "r"
  O.RefreshScalars()
  mocks.__fireTimers()
  -- red under: requestSwitch not coalescing per ctx (each watcher queues its own re-render: 3)
  assertEqual(renders, 2, "both changes, one re-render")
  assertEqual(drawn(O, ctx), "Anchor,Attach to,Section B,B one,Section C,C one,Side,Section R,R one")
end)

-- ── the OR form: shownWhen = { any = { ... } } (OptionsSwitch minor 1) ─────────────────────────

--- DropWatcher's Upgrade glow shape: two style dropdowns (main, off-spec) and one section per style,
--- each row of a main | off-spec pair carrying the same OR across both selectors.
local function glowRows()
  local function either(style)
    return { any = { { path = "main", equals = style }, { path = "off", equals = { style } } } }
  end
  local styles = { values = { pixel = "Pixel", proc = "Proc", button = "Button" },
                   sorting = { "pixel", "proc", "button" } }
  return {
    { path = "main", group = "Glow", type = "string", label = "Main style",
      values = styles.values, sorting = styles.sorting },
    { path = "off", group = "Glow", type = "string", label = "Off-spec style",
      values = styles.values, sorting = styles.sorting },
    { path = "px.main", group = "Glow", subgroup = "Pixel border", type = "bool", label = "Pixel main",
      shownWhen = either("pixel") },
    { path = "px.off", group = "Glow", subgroup = "Pixel border", type = "bool", label = "Pixel off",
      shownWhen = either("pixel") },
    { path = "pr.main", group = "Glow", subgroup = "Proc", type = "bool", label = "Proc main",
      shownWhen = either("proc") },
    { path = "pr.off", group = "Glow", subgroup = "Proc", type = "bool", label = "Proc off",
      shownWhen = either("proc") },
  }
end

local function glowBench(main, off)
  local O, rec, ctx = bench("a")
  rec.store.main, rec.store.off = main, off
  return O, rec, ctx
end

local HEAD = "Glow,Main style,Off-spec style"

test("switched any: a section shows while either selector chooses it, both when both differ", function()
  -- red under: shownNow reading `path` alone (an `any` row has none, so it always shows) or only
  -- the first clause (Proc/Pixel would lose the Pixel section)
  local O, _, ctx = glowBench("proc", "proc")
  O.RenderRows(ctx, glowRows())
  assertEqual(drawn(O, ctx), HEAD .. ",Proc,Proc main,Proc off", "Proc/Proc: Pixel border dropped")
  O, _, ctx = glowBench("proc", "pixel")
  O.RenderRows(ctx, glowRows())
  assertEqual(drawn(O, ctx), HEAD .. ",Pixel border,Pixel main,Pixel off,Proc,Proc main,Proc off",
    "one style each: both sections, both columns")
  O, _, ctx = glowBench("button", "button")
  O.RenderRows(ctx, glowRows())
  assertEqual(drawn(O, ctx), HEAD, "neither chosen: neither section, nor its heading")
end)

test("switched any: a change to either selector re-renders once, on the next frame", function()
  -- red under: switchedRows registering no selector for an `any` row (no watcher, no re-render)
  local O, rec, ctx = glowBench("proc", "proc")
  local rows = glowRows()
  local renders = 0
  O.SetRenderer(ctx, function(c)
    renders = renders + 1
    O.ClearScroll(c)
    O.RenderRows(c, rows)
  end)
  ctx.panel:Show(); ctx.panel:__fire("OnShow")
  rec.store.off = "pixel"
  O.RefreshScalars()
  assertEqual(renders, 1, "not inside the sweep")
  mocks.__fireTimers()
  assertEqual(renders, 2, "the second clause's selector is watched")
  assertEqual(drawn(O, ctx), HEAD .. ",Pixel border,Pixel main,Pixel off,Proc,Proc main,Proc off")
  rec.store.main, rec.store.off = "pixel", "button"
  O.RefreshScalars()
  mocks.__fireTimers()
  assertEqual(renders, 3, "both selectors in one frame: one re-render")
  assertEqual(drawn(O, ctx), HEAD .. ",Pixel border,Pixel main,Pixel off")
end)

test("switched any: a clause whose read raises reads as shown; a malformed clause is skipped", function()
  local O, rec, ctx = glowBench("button", "button")
  local get = rec.d.get
  rec.d.get = function(path)
    if path == "off" then error("selector unreadable") end
    return get(path)
  end
  local ok = pcall(O.RenderRows, ctx, glowRows())
  rec.d.get = get
  assertTrue(ok, "the render survived")
  assertTrue(drawn(O, ctx):find("Pixel main", 1, true) ~= nil, "a raising clause reads as shown")
  -- A clause that is not a table, or names no path, holds for nothing and is never watched.
  local O2, _, ctx2 = glowBench("proc", "proc")
  O2.RenderRows(ctx2, {
    { path = "main", group = "Glow", type = "string", label = "Main style",
      values = { proc = "Proc" }, sorting = { "proc" } },
    { path = "x", group = "Glow", subgroup = "Odd", type = "bool", label = "Odd one",
      shownWhen = { any = { "main", { equals = "proc" }, { path = "main", equals = "pixel" } } } },
  })
  assertEqual(drawn(O2, ctx2), "Glow,Main style", "no clause holds: dropped")
end)

test("switched any: the single-path form is unchanged beside it", function()
  local O, _, ctx = bench("b")
  O.RenderRows(ctx, anchorRows({
    { path = "z1", group = "Anchor", subgroup = "Section Z", type = "bool", label = "Z one",
      shownWhen = { any = { { path = "mode", equals = "a" }, { path = "mode", equals = "c" } } } },
  }))
  assertEqual(drawn(O, ctx), "Anchor,Attach to,Section B,B one,Section C,C one", "b: Z is dropped")
end)

test("switched: OptionsSwitch.lua is its own file of the major, paired on the shell's minor", function()
  -- red under: the switched sections left in OptionsWidgets.lua (no OptionsSwitch minor), which
  -- took that file past its 1450-line re-check trigger (CLAUDE.md's band census)
  local lib = T.options
  assertEqual(lib.MODULES.OptionsSwitch, lib.__switchMinor)
  assertTrue(lib.__switchMinor >= 1)
  assertEqual(lib.__switchShellMinor, lib.MINOR, "attached to the shell that is live")
  assertEqual(type(lib.__AttachSwitch), "function")
end)
