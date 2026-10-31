-- tests/test_options_banner_acts.lua -- O.PageBanner's `acts` (LibKa0s#59, ruling U-08d;
-- OptionsTabs minor 13, Options minor 35): up to three buttons or checkboxes beside the picker on
-- the one band row, so a host need not drop to PageHeader to add an enable box.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertNil
local widgets_bench = dofile("tests/fixture_widgets.lua")("ActsBench").bench

--- The bench with chrome `width` wide, and every AceGUI widget backed by a frame recording its anchors:
--- the mock's own are frameless, the state PageBanner's guards exist for.
local function bench(width)
  local O, rec, ctx = widgets_bench()
  ctx.chrome.GetWidth = function() return width or 800 end
  local create = O.AceGUI.Create
  O.__framedCreate = create
  O.AceGUI.Create = function(self, kind)
    local w = create(self, kind)
    if kind ~= "Dropdown" then
      local f = { __points = {} }
      function f.SetPoint(fr, ...) fr.__points[#fr.__points + 1] = { ... } end
      function f.ClearAllPoints(fr) fr.__points = {} end
      function f.SetParent() end
      function f.SetHeight() end
      function f.Show() end
      function f.Hide() end
      w.frame = f
    end
    return w
  end
  return O, rec, ctx
end

--- Put the shared mock's Create back. Every case that draws ends here.
local function done(O) O.AceGUI.Create = O.__framedCreate end

local function spec(acts)
  return { label = "Unit", list = { a = "A", b = "B" }, order = { "a", "b" }, value = "a",
           onSelect = function() end, acts = acts }
end

--- The x offset of `w`'s frame against the chrome's TOPLEFT.
local function offsetOf(w)
  for _, p in ipairs(w.frame.__points or {}) do
    if p[1] == "TOPLEFT" then return p[4], p[5] end
  end
end

test("acts: a Button and a CheckBox draw beside the picker, third return in act order", function()
  -- red under: ignoring spec.acts.
  local O, _, ctx = bench()
  local clicks, state = 0, true
  local dd, btn, widgets = O.PageBanner(ctx, spec({
    { label = "Enable this unit", tooltip = "t", get = function() return state end,
      set = function(v) state = v end },
    { text = "Copy from Target", onClick = function() clicks = clicks + 1 end },
  }))
  assertEqual(dd.type, "Dropdown")
  assertNil(btn, "the second return stays `action`'s")
  assertEqual(#widgets, 2)
  assertEqual(widgets[1].type, "CheckBox")
  assertEqual(widgets[1].labelText, "Enable this unit")
  assertEqual(widgets[1].value, true, "seeded from get")
  assertEqual(widgets[2].type, "Button")
  widgets[2]:__fire("OnClick")
  assertEqual(clicks, 1)
  widgets[1]:__fire("OnValueChanged", false)
  assertEqual(state, false)
  done(O)
end)

test("acts: the band splits into equal cells, re-placed when the chrome learns its width", function()
  local O, _, ctx = bench(800)
  local _, _, widgets = O.PageBanner(ctx, spec({ { text = "A" }, { text = "B" }, { text = "C" } }))
  done(O)
  assertEqual((offsetOf(widgets[1])), 200 + 4)
  assertEqual((offsetOf(widgets[3])), 600 + 4)
  ctx.chrome:__fire("OnSizeChanged", 1200)
  assertEqual((offsetOf(widgets[3])), 900 + 4)
end)

test("acts: one act takes the right half, level with a labeled picker's control", function()
  local O, _, ctx = bench(800)
  local _, _, widgets = O.PageBanner(ctx, spec({ { text = "A" } }))
  done(O)
  local x, y = offsetOf(widgets[1])
  assertEqual(x, 404)
  assertEqual(y, -14)
end)

test("acts: past three, the extra are not drawn and the host is told", function()
  local O, rec, ctx = bench()
  rec.chat = {}
  local _, _, widgets = O.PageBanner(ctx,
    spec({ { text = "1" }, { text = "2" }, { text = "3" }, { text = "4" } }))
  assertEqual(#widgets, 3)
  assertTrue(table.concat(rec.chat, "\n"):find("acts", 1, true) ~= nil, "reported")
  done(O)
end)

test("acts: `acts` wins over `action`, and a banner with neither is unchanged", function()
  local O, _, ctx = bench()
  local s = spec({ { text = "A" } })
  s.action = { text = "Old" }
  local _, btn, widgets = O.PageBanner(ctx, s)
  assertNil(btn)
  assertEqual(widgets[1].text, "A")
  local _, none, nothing = O.PageBanner(ctx, spec(nil))
  assertNil(none)
  assertNil(nothing)
  done(O)
end)

test("acts: a re-render releases the old widgets once the new ones exist, never early", function()
  -- The act's own click may be what re-renders, so its widget must outlive the call.
  -- red under: dropping the Release of the old acts, or releasing them before the new ones exist.
  local O, _, ctx = bench()
  local s
  local during
  s = spec({ { text = "A", onClick = function()
    local _, _, again = O.PageBanner(ctx, s)
    during = again[1]
  end } })
  local before = T.mocks.__aceguiLive("Button")
  local _, _, first = O.PageBanner(ctx, s)
  local outAtRelease
  first[1].OnRelease = function() outAtRelease = T.mocks.__aceguiLive("Button") - before end
  first[1]:__fire("OnClick")
  done(O)   -- first: a failed assert below must not leave the framed Create on the shared mock
  assertTrue(during ~= first[1], "the render inside the click was handed a different button")
  assertEqual(ctx.__bannerActs[1], during)
  assertNil(ctx.__staleBannerActs)
  assertTrue(first[1].__released, "the old act went back to AceGUI")
  assertEqual(outAtRelease, 2, "the old act was released before its replacement existed")
  assertEqual(T.mocks.__aceguiLive("Button") - before, 1, "one act button out after two renders")
end)

test("acts: a click and a toggle are refused in combat", function()
  local O, _, ctx = bench()
  local state, clicks = true, 0
  local _, _, widgets = O.PageBanner(ctx, spec({
    { label = "On", get = function() return state end, set = function(v) state = v end },
    { text = "Go", onClick = function() clicks = clicks + 1 end },
  }))
  local saved = T.mocks.InCombatLockdown
  T.mocks.InCombatLockdown = function() return true end
  local ok, err = pcall(function()
    widgets[2]:__fire("OnClick")
    widgets[1]:__fire("OnValueChanged", false)
  end)
  T.mocks.InCombatLockdown = saved
  if not ok then error(err) end
  assertEqual(clicks, 0)
  assertEqual(state, true)
  assertEqual(widgets[1].value, true, "the box goes back to the stored value")
  done(O)
end)

test("acts: a raising act is reported and costs nothing else", function()
  local O, rec, ctx = bench()
  rec.chat = {}
  local _, _, widgets = O.PageBanner(ctx, spec({ { text = "Go", onClick = function() error("no") end } }))
  widgets[1]:__fire("OnClick")
  assertTrue(#rec.chat > 0)
  done(O)
end)

test("acts: a checkbox follows a write after a tab click cleared the scroll", function()
  -- The trap KickCD's Panel_Render.lua records: a strip-only redraw reassigns ctx.refreshers, and a
  -- band tick registered through it never hears a `/<slash> set` again.
  local O, _, ctx = bench()
  local state = true
  local _, _, widgets = O.PageBanner(ctx, spec({
    { label = "On", get = function() return state end, set = function(v) state = v end } }))
  O.ClearScroll(ctx)
  state = false
  for _, fn in ipairs(ctx.refreshers) do fn() end
  assertEqual(widgets[1].value, false, "the band's refresher survived ClearScroll")
  assertEqual(#ctx.refreshers, 1)
  O.ClearScroll(ctx)
  O.PageBanner(ctx, spec({ { label = "On", get = function() return state end, set = function() end } }))
  assertEqual(#ctx.refreshers, 1, "one per ctx, however many renders")
  done(O)
end)

test("acts: a band redrawn without acts leaves no live refresher behind", function()
  local O, _, ctx = bench()
  local reads = 0
  O.PageBanner(ctx, spec({ { label = "On", get = function() reads = reads + 1 end, set = function() end } }))
  O.PageBanner(ctx, spec(nil))
  reads = 0
  for _, fn in ipairs(ctx.refreshers) do fn() end
  assertEqual(reads, 0, "a released box is never written to again")
  done(O)
end)
