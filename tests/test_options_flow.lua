-- tests/test_options_flow.lua — LibKa0s-Options-1.0's two-column flow engine: RenderRows' row
-- guard, RenderGrid, RenderSchema's pairing, `solo` / `skipRender` / afterGroup / pairWith,
-- Section, ClearScroll, InlineButtonPair, `wide` and `startsLine`, subsection headings, and the
-- tabbed page.
--
-- Peeled out of tests/test_options_widgets.lua (issue #33) when what was left of that suite after
-- the id peel was split on its own case seams. The cases are moved unchanged; the benches are in
-- tests/fixture_widgets.lua.
--
-- The cases under *the tabbed page* came with them, and that is the one place the cut differs from
-- the banner list #8 wrote down. `O.RenderTabbedSchema` was the flow engine's tabbed entry point; it
-- moved to OptionsTabs.lua at OptionsTabs minor 4, and these cases stayed unchanged as the
-- characterization of that move. Its new `opts` fields are pinned in tests/test_options_tabs.lua.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil, assertNear =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil, T.assertNear
local Fixture = dofile("tests/fixture_options.lua")
-- The INTERNAL LAYOUT keys (CHROME_DIVIDER_*, PANEL_*, CONTENT_*) have no O.* seam of
-- their own -- by design, per the published/internal split at the top of Options.lua -- so a
-- test that needs their raw numbers reads them off the lib table directly, same as
-- tests/test_options.lua does.
local lib = T.options
local Widgets = dofile("tests/fixture_widgets.lua")("FlowBench")
local bench, withoutAceGUI = Widgets.bench, Widgets.withoutAceGUI

-- ── the row guard and RenderGrid ──────────────────────────────────────────────────────────

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
  -- the pending line is flushed BEFORE the hook is called, not after. The neighboring case counts
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

-- ── the half-vendored pair (layout-§1's peel, #16) ───────────────────────────────
--
-- OptionsWidgets.lua and OptionsTabs.lua are two files of ONE major, paired on the shell's minor
-- rather than on each other's, so a consumer whose vendored copy carries one and not the other is
-- a state LibStub cannot detect. The whole argument for cutting the file in two is that this state
-- degrades instead of raising -- and until these two cases existed, that argument was asserted and
-- never exercised. Eleven addons vendor this payload byte-for-byte.
--
-- The shape is tests/test_options.lua's 'survives a vendored copy whose widget makers never
-- attached': nil the attach hook BEFORE Fixture.new, because lib:New reaches for it once at build
-- time, so flipping it afterwards leaves the instance holding what it already resolved.

test("widgets: a tabbed page falls back to the untabbed render when OptionsTabs.lua is absent",
  function()
  -- red under: dropping the `if not O.TabStrip` guard at the head of RenderTabbedSchema. The page
  -- would raise on the first OnShow, from inside the library, on a consumer that had done nothing
  -- wrong except vendor a partial folder.
  local savedTabs = lib.__AttachTabs
  lib.__AttachTabs = nil
  local O, _, ctx = bench()
  lib.__AttachTabs = savedTabs

  assertNil(O.TabStrip, "the tab half really is absent from this instance")

  local ok, groups = pcall(O.RenderTabbedSchema, ctx, "tabbed")
  assertTrue(ok, "a half-vendored copy must not raise while drawing: " .. tostring(groups))
  assertEqual(table.concat(groups or {}, "|"), "Alpha|Beta|Gamma|Delta",
    "the groups are still reported, so a caller reading them is unaffected")

  -- The fallback is the UNTABBED render: every row, with its section headings -- the page a player
  -- can still use. Not the tabbed partition, which would show one group and no way to reach the
  -- others.
  local labels = table.concat(scrollLabels(ctx), "|")
  assertTrue(labels:find("Alpha one", 1, true) ~= nil, "the first group is drawn")
  assertTrue(labels:find("Beta one", 1, true) ~= nil,
    "and so is a group that would have been behind a tab -- otherwise it is unreachable")
  assertTrue(labels:find("Gamma one", 1, true) ~= nil)
end)

test("widgets: the tab half draws its banner without the widget half's tooltip attacher",
  function()
  -- The mirror of the case above, and the one line of moved module code the peel changed:
  -- OptionsTabs.lua's banner reaches O.AttachTooltip, which lives in the widget half. Bare, it
  -- raises; guarded, the banner simply carries no tooltip.
  --
  -- O.PageBanner is the entry point, NOT RenderTabbedSchema: the flow engine lives in the widget
  -- half, so with that half absent there is no RenderTabbedSchema to call and this case would be
  -- testing its own setup. The tab half's own exported surface is what survives, and it is what a
  -- host on a half-vendored copy still reaches.
  -- red under: making that reach bare again.
  local savedWidgets = lib.__AttachWidgets
  lib.__AttachWidgets = nil
  local O, _, ctx = bench()
  lib.__AttachWidgets = savedWidgets

  assertNil(O.AttachTooltip, "the widget makers really are absent from this instance")
  assertTrue(O.PageBanner ~= nil, "but the tab half is present -- that is the state under test")

  local ok, dd = pcall(O.PageBanner, ctx, {
    label = "Window", list = { [1] = "One" }, order = { 1 }, value = 1,
    tooltip = "a tooltip nothing can attach", onSelect = function() end,
  })
  assertTrue(ok, "the tab half must not raise reaching across the seam: " .. tostring(dd))
  assertEqual(dd.type, "Dropdown", "and the banner is still drawn, just without its tooltip")
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
