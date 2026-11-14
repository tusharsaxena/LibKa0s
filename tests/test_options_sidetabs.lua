-- tests/test_options_sidetabs.lua -- LibKa0s-Options-1.0's OptionsNav.lua minor 7: O.SideTabs, the
-- nav rail's look drawn INSIDE a page's content (plan row L13 of docs/superpowers/plans/
-- 2026-11-13-callout.md). A list of tabs on the left, the selected one's body on the right, under
-- whatever the page drew first; the Callout's one settings tab draws its Look and Sound with it.
--
-- The kit's AceGUI records children and layout names but lays nothing out, so the group's layout
-- function is driven directly (`O.__sideLayout`) on a recording content frame, the way the client's
-- AceGUI calls it.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local Fixture = dofile("tests/fixture_options.lua")
local lib = T.options

local panelSeq = 0
local function bench()
  local O, rec = Fixture.new()
  panelSeq = panelSeq + 1
  local ctx = O.CreatePanel("SideTabsBench" .. panelSeq, "Side " .. panelSeq, {})
  return O, ctx, O.EnsureScroll(ctx), rec
end

local ENTRIES = {
  { key = "general", label = "General", tooltip = "The instance itself." },
  { key = "filters", label = "Filters" },
  { key = "layout",  label = "Layout" },
}

local function bodyText(body)
  local out = {}
  for _, w in ipairs(Fixture.flatten(body)) do
    if w.type == "Label" then out[#out + 1] = w.text end
  end
  return table.concat(out, ",")
end

local function groupOf(scroll)
  for _, w in ipairs(scroll.children or {}) do
    if w.layout == "Ka0sSideTabs" then return w end
  end
end

-- ── the version ──────────────────────────────────────────────────────────────────────────────

test("side tabs: OptionsNav is at minor 7 and every instance carries SideTabs", function()
  assertEqual(lib.MODULES.OptionsNav, 7)
  local O = bench()
  assertEqual(type(O.SideTabs), "function")
end)

-- ── the group ────────────────────────────────────────────────────────────────────────────────

test("side tabs: the group lands where the page has got to, a rail entry per tab, the body drawn by render", function()
  local O, ctx, scroll = bench()
  O.TextRow(ctx, "above")
  local handed
  local buttons, body, key = O.SideTabs(ctx, { entries = ENTRIES, value = "filters",
    render = function(c, k)
      handed = k
      assertTrue(c == ctx, "render is handed the page's own ctx")
      O.TextRow(c, "body " .. k)
    end })
  -- red under: the group drawn as chrome (pinned to the body, not in the scroll), or above the
  -- page's earlier rows
  assertEqual(scroll.children[1].text, "above", "what the page drew first stays above")
  local group = scroll.children[2]
  assertEqual(group.layout, "Ka0sSideTabs", "the group is laid out by the side-tab layout")
  assertTrue(group.fullWidth, "and is as wide as the page")
  assertTrue(group.children[1] == body, "its one child is the body")
  assertEqual(body.layout, "List")
  -- red under: render drawing into the page's scroll rather than the body
  assertEqual(bodyText(body), "body filters", "the selected tab's body is in the body")
  assertEqual(#scroll.children, 2, "nothing render drew landed in the page's scroll")
  assertTrue(ctx.scroll == scroll, "the page's scroll comes back after render")
  assertEqual(handed, "filters")
  assertEqual(key, "filters")
  assertEqual(#buttons, 3)
  assertEqual(buttons[1].__ka0sNavText, "General")
  assertFalse(buttons[2]:IsEnabled(), "the selected entry is disabled, as the rail's is")
  assertTrue(buttons[1]:IsEnabled() and buttons[3]:IsEnabled())
  assertEqual(group.__ka0sSideRailW, 120, "the rail is 120 wide by default")
  assertEqual(group.__ka0sSideMinH, 2 * 8 + 3 * 20, "the group is at least as tall as its entries")
end)

test("side tabs: a value no drawn entry has selects the first, and clients gates an entry", function()
  local O, ctx = bench()
  local _, _, key = O.SideTabs(ctx, { entries = ENTRIES, value = "gone", render = function() end })
  assertEqual(key, "general", "a stale pointer heals to the first entry")
  -- The other client's name, whichever profile the suite runs under.
  local other = lib.__ClientOk({ "retail" }) and "forever" or "retail"
  local gated = { { key = "a", label = "A", clients = { other } }, { key = "b", label = "B" } }
  local buttons, _, k2 = O.SideTabs(ctx, { entries = gated, value = "a", render = function() end })
  assertEqual(#buttons, 1, "an entry for another client gets no button")
  assertEqual(k2, "b")
end)

test("side tabs: section headings inside the body start fresh, and the page's trackers come back", function()
  local O, ctx, scroll = bench()
  O.Section(ctx, "Preview")
  local _, body = O.SideTabs(ctx, { entries = ENTRIES, value = "general",
    render = function(c) O.Section(c, "Colors") end })
  local inBody = Fixture.flatten(body)
  -- red under: the page's tracker leaking in (no top spacer above the body's first heading means
  -- the body started fresh)
  assertEqual(inBody[1].type, "Heading", "the body's first heading has no spacer over it")
  assertEqual(inBody[1].text, "Colors")
  assertEqual(ctx.lastGroup, nil, "the page's group tracker is as it was")
  assertTrue(ctx.scroll == scroll)
end)

test("side tabs: a raising render is reported, and the page's scroll still comes back", function()
  local O, ctx, scroll, rec = bench()
  local printed = #rec.chat
  assertTrue(pcall(O.SideTabs, ctx, { entries = ENTRIES, render = function() error("boom") end }),
    "the raise stays inside SideTabs")
  assertTrue(ctx.scroll == scroll, "the page's scroll is restored after the raise")
  assertEqual(#rec.chat, printed + 1, "and the failure is printed")
  assertTrue(tostring(rec.chat[#rec.chat]):find("side tab general", 1, true) ~= nil)
end)

test("side tabs: nothing to draw answers nil and draws nothing", function()
  local O, ctx, scroll = bench()
  assertNil(O.SideTabs(nil, { entries = ENTRIES, render = function() end }), "no ctx")
  assertNil(O.SideTabs(ctx, { entries = ENTRIES }), "no render")
  assertNil(O.SideTabs(ctx, { entries = {}, render = function() end }), "no entry")
  assertNil(O.SideTabs(ctx, nil), "no spec")
  assertEqual(#(scroll.children or {}), 0)
end)

-- ── the click ────────────────────────────────────────────────────────────────────────────────

--- A page whose renderer draws the side tabs off `state.side`, shown and rendered once.
local function rendered()
  local O, ctx = bench()
  local state, picked, renders = { side = "general" }, {}, 0
  O.SetRenderer(ctx, function(c)
    renders = renders + 1
    O.ClearScroll(c)
    state.buttons, state.body = O.SideTabs(c, { entries = ENTRIES, value = state.side,
      onSelect = function(key) picked[#picked + 1] = key; state.side = key end,
      render = function(cc, key) O.TextRow(cc, "body " .. key) end })
  end)
  ctx.panel:Show()
  ctx.panel:__fire("OnShow")
  return O, ctx, state, picked, function() return renders end
end

test("side tabs: a click hands its key to onSelect, then the page re-renders on the new tab", function()
  local _, _, state, picked, renders = rendered()
  assertEqual(renders(), 1)
  local first = state.body
  state.buttons[3]:__fire("OnClick")
  assertEqual(table.concat(picked, ","), "layout")
  -- red under: onSelect called with no re-render (the list moves, the body stays on General)
  assertEqual(renders(), 2, "the page re-renders through its renderer")
  assertEqual(bodyText(state.body), "body layout")
  assertFalse(state.body == first, "on a new body (the old group's release is the case below)")
  state.buttons[3]:__fire("OnClick")
  assertEqual(#picked, 1, "the selected entry does nothing")
end)

test("side tabs: a click in combat is refused, and nothing changes", function()
  local _, _, state, picked, renders = rendered()
  lib.__combatLocked = true
  local ok, err = pcall(function() state.buttons[2]:__fire("OnClick") end)
  lib.__combatLocked = false
  if not ok then error(err, 0) end
  assertEqual(#picked, 0, "onSelect never ran")
  assertEqual(renders(), 1, "the page did not re-render")
end)

test("side tabs: a released group hands its rail back, and the next group takes it rather than building one", function()
  local O, ctx = bench()
  O.SideTabs(ctx, { entries = ENTRIES, render = function() end })
  local group = groupOf(ctx.scroll)
  local free = O.__sideFreeRails()
  -- red under: no OnRelease (the rail rides the pooled frame into another page), or a release that
  -- hides the rail and never frees it (a new rail per re-render)
  O.AceGUI:Release(group)
  assertEqual(O.__sideFreeRails(), free + 1, "the released group's rail is free")
  assertEqual(group.layout, "List", "the pooled group's layout is back to AceGUI's default")
  assertNil(group.__ka0sSideRailW)
  O.SideTabs(ctx, { entries = ENTRIES, render = function() end })
  assertEqual(O.__sideFreeRails(), free, "the next group took it")
end)

test("side tabs: a released rail goes back to client art before another instance can take it", function()
  -- red under: a release that only parks the rail, so a host with no skin that reuses it keeps the
  -- previous owner's skin backdrop (FREE_RAILS is shared by every instance)
  local O, ctx = bench()
  O.SideTabs(ctx, { entries = ENTRIES, render = function() end })
  local group = groupOf(ctx.scroll)
  local given = {}
  local real = lib.__chromeUnpaint
  lib.__chromeUnpaint = function(target) given[#given + 1] = target end
  local ok, err = pcall(function() O.AceGUI:Release(group) end)
  lib.__chromeUnpaint = real
  if not ok then error(err, 0) end
  assertEqual(#given, 1, "the rail is handed back once")
  assertTrue(type(given[1]) == "table" and given[1].__ka0sSidePool ~= nil, "and it is the rail")
end)

test("side tabs: a registered skin owner's rail and entries paint through its facade", function()
  local O, ctx = bench()
  local painted = {}
  local real = O.__chromePaint
  O.__chromePaint = function(prim, _, opts)
    painted[#painted + 1] = prim .. (opts and opts.nav and ":nav" or "")
  end
  local ok, err = pcall(O.SideTabs, ctx, { entries = ENTRIES, render = function() end })
  O.__chromePaint = real
  if not ok then error(err, 0) end
  local list = table.concat(painted, ",")
  assertEqual(select(2, list:gsub("NavItem", "")), 3, "each entry paints as a nav item")
  assertTrue(list:find("Panel:nav", 1, true) ~= nil, "the rail paints as the rail's pane")
end)

-- ── the layout ───────────────────────────────────────────────────────────────────────────────

--- A content frame as AceGUI hands a layout one: its width, and the widget it belongs to.
local function content(width, railW, minH)
  local finished = {}
  local obj = { __ka0sSideRailW = railW, __ka0sSideMinH = minH,
    LayoutFinished = function(_, w, h) finished[#finished + 1] = { w = w, h = h } end }
  return { width = width, obj = obj }, finished
end

local function body(height)
  local rec = { points = {}, laid = 0 }
  local frame = { height = height }
  function frame:ClearAllPoints() rec.points = {} end
  function frame:SetPoint(p, rel, relP, x, y) rec.points[p] = { rel = rel, relP = relP, x = x, y = y } end
  function frame:Show() rec.shown = true end
  local b = { frame = frame }
  function b:SetWidth(w) rec.width = w end
  function b:DoLayout() rec.laid = rec.laid + 1 end
  return b, rec
end

test("side tabs: the layout puts the body right of the rail, takes the rest of the width, and sizes the group", function()
  local O = bench()
  local c, finished = content(600, 120, 76)
  local b, rec = body(300)
  O.__sideLayout(c, { b })
  assertEqual(rec.points.TOPLEFT.x, 132, "the body starts 12 right of the rail")
  assertEqual(rec.points.TOPLEFT.y, 0)
  assertTrue(rec.points.TOPLEFT.rel == c)
  assertEqual(rec.width, 600 - 132, "and takes the rest of the width")
  assertEqual(rec.laid, 1, "the body is laid out at its width")
  assertTrue(rec.shown)
  assertEqual(finished[1].h, 300, "the group is as tall as the body")
  local c2, finished2 = content(600, 160, 76)
  local b2, rec2 = body(20)
  O.__sideLayout(c2, { b2 })
  assertEqual(rec2.points.TOPLEFT.x, 172, "a wider rail moves the body")
  assertEqual(finished2[1].h, 76, "a short body still leaves room for every entry")
  local c3, finished3 = content(600, 120, 76)
  O.__sideLayout(c3, {})
  assertEqual(finished3[1].h, 76, "no body: the entries' height")
end)
