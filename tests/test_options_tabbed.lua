-- tests/test_options_tabbed.lua — LibKa0s-Options-1.0's OptionsTabs.lua: the tabbed page's `opts`
-- (host tabs, the disabled notice, the chrome hook) and the page banner's action button.
--
-- Split out of tests/test_options_tabs.lua, which was 1218 lines and in `layout-§1`'s 1000-1500
-- band, in the 2026-09-26 automated-tests sweep. The tabbed page is the seam the watch list names
-- inside OptionsTabs.lua, so these cases moved unchanged, in their original order, and run right
-- after that suite. The chrome itself (the strip, the banner, the header block, the secondary
-- strip and their geometry) stays there.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local Fixture = dofile("tests/fixture_options.lua")
-- The INTERNAL LAYOUT keys have no O.* seam of their own, so the cases read them off the lib table,
-- as tests/test_options_tabs.lua does.
local lib = T.options

--- A host, a throwaway panel and a parent container: tests/fixture_widgets.lua's bench, under a
--- panel name of this suite's own.
local bench = dofile("tests/fixture_widgets.lua")("TabbedBench").bench

--- The banner spec tests/test_options_tabs.lua renders, for the case that draws a banner with no action.
local BANNER = { label = "W", list = { [1] = "One", [2] = "Two" }, order = { 1, 2 }, value = 1,
                 onSelect = function() end }

-- ── the tabbed page: host tabs, the disabled notice and the chrome hook (T4) ─────────────────
--
-- `O.RenderTabbedSchema` moved here from OptionsWidgets.lua at T4 and took an optional fifth
-- argument, so a host with bespoke (non-row) tabs, a page drawn disabled or a line above every tab
-- stops forking the whole render (AuraMaster-R-04: AuraMaster's seven pages, and the same strip
-- hand-built in four more hosts). The cases on the signature every host already calls are in
-- tests/test_options_flow.lua and pass unchanged; these pin the new fields.

--- Every heading, row label and text line in a ctx's scroll, in order.
local function drawn(ctx)
  local out = {}
  if not ctx.scroll then return out end
  for _, w in ipairs(Fixture.flatten(ctx.scroll)) do
    if w.type == "Heading" then
      out[#out + 1] = "HEADING:" .. tostring(w.text)
    elseif w.type == "Label" then
      out[#out + 1] = "TEXT:" .. tostring(w.text)
    elseif w.labelText then
      out[#out + 1] = w.labelText
    end
  end
  return out
end

--- The keys of the strip a render drew, in order, read off the buttons' labels.
local function stripKeys(ctx)
  local out = {}
  for _, b in ipairs(ctx.__tabKids or {}) do
    if b.__ka0sTabTipLabel then out[#out + 1] = b.__ka0sTabTipLabel end
  end
  return table.concat(out, "|")
end

test("widgets: a host tab sits before the group it names and renders through its callback",
function()
  -- red under: the four-argument RenderTabbedSchema, which ignores opts.tabs entirely.
  local O, _, ctx = bench()
  local calls = {}
  local custom = { key = "Custom", label = "Custom", before = "Gamma",
                   render = function(c, rows) calls[#calls + 1] = { c = c, rows = rows }
                     O.TextRow(c, "bespoke body") end }
  local late = { key = "Late", label = "Late", before = "NoSuchGroup", render = function() end }
  local groups, keys = O.RenderTabbedSchema(ctx, "tabbed", nil, nil, { tabs = { custom, late } })

  assertEqual(table.concat(groups, "|"), "Alpha|Beta|Gamma|Delta", "the groups are still the groups")
  assertEqual(table.concat(keys, "|"), "Alpha|Beta|Custom|Gamma|Delta|Late",
    "ahead of the group `before` names; last when that group is not drawn")
  assertEqual(stripKeys(ctx), "Alpha|Beta|Custom|Gamma|Delta|Late", "the strip draws the same order")
  assertEqual(#calls, 0, "a host tab that is not active is not rendered")

  ctx.__tabKids[3]:__fire("OnClick")
  assertEqual(ctx.activeTab, "Custom")
  assertEqual(#calls, 1, "the active host tab rendered exactly once")
  assertTrue(calls[1].c == ctx, "handed the page's ctx")
  assertNil(calls[1].rows, "a tab standing for no group is handed no rows")
  local labels = table.concat(drawn(ctx), "|")
  assertTrue(labels:find("bespoke body", 1, true) ~= nil, "the callback drew the page")
  assertNil(labels:find("Alpha one", 1, true), "no group's rows under a host tab")
end)

test("widgets: a host tab keyed by a group takes that group's place and is handed its rows",
function()
  -- red under: adding a second tab for the key, or drawing the group's rows as well.
  local O, _, ctx = bench()
  local got
  local alpha = { key = "Alpha", label = "Alpha", render = function(_, rows) got = rows end }
  local _, keys = O.RenderTabbedSchema(ctx, "tabbed", nil, nil, { tabs = { alpha } })

  assertEqual(table.concat(keys, "|"), "Alpha|Beta|Gamma|Delta", "no second Alpha tab")
  assertEqual(ctx.activeTab, "Alpha")
  assertEqual(#(got or {}), 2, "the group's two rows reached the callback")
  assertEqual(got[1].label, "Alpha one")
  assertNil(table.concat(drawn(ctx), "|"):find("Alpha one", 1, true),
    "the flow engine did not also draw the rows the host tab stands in for")
end)

test("widgets: a stale active tab heals to the first tab when only host tabs remain", function()
  -- red under: healing against the schema groups alone, which a group-less page has none of.
  local O, rec, ctx = bench({ rowsForPage = function() return {} end })
  ctx.activeTab = "Gone"
  local seen = 0
  local only = { key = "Only", label = "Only", render = function() seen = seen + 1 end }
  O.RenderTabbedSchema(ctx, "empty", nil, nil, { tabs = { only } })
  assertEqual(ctx.activeTab, "Only")
  assertEqual(seen, 1)
  assertEqual(stripKeys(ctx), "Only", "a page of host tabs alone still draws its strip")
  for _, line in ipairs(rec.chat) do
    assertNil(line:find("no grouped rows", 1, true), "a page with a strip is not reported: " .. line)
  end
end)

test("widgets: disabledFor draws the notice ABOVE the rows, and the rows disabled", function()
  -- red under: ignoring disabledFor, drawing the notice in place of the rows, or below them.
  local O, _, ctx = bench()
  local asked
  local cfg = { kind = "icons" }
  O.RenderTabbedSchema(ctx, "tabbed", nil, nil, {
    cfg = cfg,
    disabledFor = function(c) asked = c; return true end,
    disabledNotice = function(c) return "not for " .. c.kind end,
  })
  assertTrue(asked == cfg, "disabledFor is handed opts.cfg")
  local labels = drawn(ctx)
  assertEqual(labels[1], "TEXT:not for icons", "the notice is the first thing on the page")
  local rows = 0
  for _, w in ipairs(Fixture.flatten(ctx.scroll)) do
    if w.type == "CheckBox" then
      rows = rows + 1
      assertTrue(w.disabled, tostring(w.labelText) .. " is drawn disabled")
    end
  end
  assertEqual(rows, 2, "both of Alpha's rows are still drawn")
  assertNil(ctx.__renderDisabled, "the flag lives for the render only")
end)

test("widgets: disabledFor false draws no notice and live rows; a raising one reads as enabled",
function()
  -- red under: drawing the notice unconditionally, or calling the predicate unguarded.
  -- Hoisted out of the `for` header: lizard 1.24.0 lists no function literal written there, and the
  -- sighted complexity suite's parity check reads that as a blind file (kit revision 35).
  local predicates = { function() return false end, function() error("predicate bug") end }
  for _, pred in ipairs(predicates) do
    local O, _, ctx = bench()
    O.RenderTabbedSchema(ctx, "tabbed", nil, nil,
      { disabledFor = pred, disabledNotice = "never shown" })
    assertNil(table.concat(drawn(ctx), "|"):find("never shown", 1, true))
    for _, w in ipairs(Fixture.flatten(ctx.scroll)) do
      if w.type == "CheckBox" then assertFalse(w.disabled == true, "a live row drew disabled") end
    end
  end
end)

test("widgets: a host tab renders under the page's disable, and the flag never outlives it",
function()
  -- red under: calling render without ctx.__renderDisabled, or not restoring it after a raise.
  local O, _, ctx = bench()
  local during
  local custom = { key = "Custom", label = "Custom", render = function(c)
    during = c.__renderDisabled
    error("host render bug")
  end }
  ctx.activeTab = "Custom"
  local ok = pcall(O.RenderTabbedSchema, ctx, "tabbed", nil, nil, {
    tabs = { custom }, disabledFor = function() return true end, disabledNotice = "off",
  })
  assertFalse(ok, "a raising host tab still raises, as a raising afterGroup hook does")
  assertTrue(during == true, "the host tab drew under the disable")
  assertNil(ctx.__renderDisabled, "restored on the way out, the raise included")
end)

test("widgets: chrome is called once per render, after the strip and before the rows", function()
  -- red under: ignoring opts.chrome, calling it before TabStrip, or after RenderRows.
  local O, _, ctx = bench()
  local calls = {}
  local function chrome(c)
    calls[#calls + 1] = { strip = stripKeys(c), drawnBefore = #drawn(c) }
    O.TextRow(c, "above every tab")
  end
  O.RenderTabbedSchema(ctx, "tabbed", nil, nil, { chrome = chrome })
  assertEqual(#calls, 1)
  assertEqual(calls[1].strip, "Alpha|Beta|Gamma|Delta", "the strip was already drawn")
  assertEqual(calls[1].drawnBefore, 0, "no row was drawn yet")
  assertEqual(drawn(ctx)[1], "TEXT:above every tab", "and what it drew sits above the rows")

  ctx.__tabKids[2]:__fire("OnClick")
  assertEqual(#calls, 2, "a tab click is a render, and it calls chrome once more")
  assertEqual(drawn(ctx)[1], "TEXT:above every tab")
end)

-- ── minor 8: untabbedSkipRender, disabledReplaces, rerender (AbsorbTracker#32) ──────────────
--
-- All three are off by default, and the default cases below pin today's behavior for the ten
-- consumers that pass none of them: BankLedger's Filters group is all skipRender and drawn by an
-- afterGroup hook, and LootHistory's skipRender row keeps its subgroup heading.

--- A page with an all-skipRender group ("Link") between two drawable ones; Beta mixes a drawn row
--- with a skipRender one.
local function linkPage()
  local rows = {
    { path = "tabAlpha", page = "linked", group = "Alpha", type = "bool", label = "Alpha one" },
    { path = "mirror",   page = "linked", group = "Link",  type = "bool", label = "Mirror",
      skipRender = true },
    { path = "tabBeta",  page = "linked", group = "Beta",  type = "bool", label = "Beta one" },
    { path = "betaOwn",  page = "linked", group = "Beta",  type = "bool", label = "Beta own",
      skipRender = true },
  }
  return bench({ rowsForPage = function() return rows end })
end

test("widgets: without untabbedSkipRender an all-skipRender group is still a tab (default)", function()
  local O, _, ctx = linkPage()
  local groups, keys = O.RenderTabbedSchema(ctx, "linked")
  assertEqual(table.concat(groups, "|"), "Alpha|Link|Beta")
  assertEqual(table.concat(keys, "|"), "Alpha|Link|Beta", "today's strip, unchanged")
end)

test("widgets: untabbedSkipRender drops an all-skipRender group's tab and keeps a mixed one",
function()
  -- red under: minor 7, which ignores the flag and draws a Link tab.
  local O, _, ctx = linkPage()
  local opts = { untabbedSkipRender = true }
  local groups, keys = O.RenderTabbedSchema(ctx, "linked", nil, nil, opts)
  assertEqual(table.concat(keys, "|"), "Alpha|Beta", "no Link tab")
  assertEqual(table.concat(groups, "|"), "Alpha|Link|Beta", "the groups are still the groups")
  ctx.__tabKids[2]:__fire("OnClick")
  assertEqual(ctx.activeTab, "Beta")
  local labels = table.concat(drawn(ctx), "|")
  assertTrue(labels:find("Beta one", 1, true) ~= nil, "the mixed group's drawable row is drawn")
  assertNil(labels:find("Beta own", 1, true), "and its skipRender row still is not")
end)

test("widgets: untabbedSkipRender keeps an all-skipRender group a hook or host tab claims", function()
  -- red under: dropping every all-skipRender group, which would cost BankLedger its Filters tab.
  local O, _, ctx = linkPage()
  local hook = { Link = function(c) O.TextRow(c, "link hook") end }
  local _, keys = O.RenderTabbedSchema(ctx, "linked", hook, nil, { untabbedSkipRender = true })
  assertEqual(table.concat(keys, "|"), "Alpha|Link|Beta", "an afterGroup hook keeps it, in place")

  local O2, _, ctx2 = linkPage()
  local host = { key = "Link", label = "Linked", render = function() end }
  local _, keys2 = O2.RenderTabbedSchema(ctx2, "linked", nil, nil,
    { untabbedSkipRender = true, tabs = { host } })
  assertEqual(table.concat(keys2, "|"), "Alpha|Link|Beta", "a host tab keyed by it keeps it, in place")
end)

--- O.TextRow spied, so a case can read the font each line was asked for.
local function spyTextRow(O)
  local fonts, real = {}, O.TextRow
  O.TextRow = function(c, text, o)
    fonts[#fonts + 1] = { text = text, font = o and o.fontObject }
    return real(c, text, o)
  end
  return fonts
end

test("widgets: disabledReplaces draws the notice instead of the rows and host tab", function()
  -- red under: minor 7, which draws the notice above rows that are still drawn.
  local O, _, ctx = bench()
  local fonts = spyTextRow(O)
  O.RenderTabbedSchema(ctx, "tabbed", nil, nil, {
    disabledFor = function() return true end, disabledNotice = "linked",
    disabledReplaces = true, disabledNoticeFont = "GameFontNormal",
  })
  assertEqual(table.concat(drawn(ctx), "|"), "TEXT:linked", "the notice and nothing else")
  assertEqual(fonts[1].font, "GameFontNormal", "in the font the host asked for")

  local O2, _, ctx2 = bench()
  local rendered = 0
  ctx2.activeTab = "Custom"
  O2.RenderTabbedSchema(ctx2, "tabbed", nil, nil, {
    tabs = { { key = "Custom", label = "Custom", render = function() rendered = rendered + 1 end } },
    disabledFor = function() return true end, disabledNotice = "linked", disabledReplaces = true,
  })
  assertEqual(rendered, 0, "the active host tab is not rendered either")
end)

test("widgets: without disabledReplaces the notice is small and the rows still draw (default)",
function()
  local O, _, ctx = bench()
  local fonts = spyTextRow(O)
  O.RenderTabbedSchema(ctx, "tabbed", nil, nil,
    { disabledFor = function() return true end, disabledNotice = "linked" })
  assertEqual(fonts[1].font, "GameFontHighlightSmall", "the notice's font is unchanged")
  local labels = table.concat(drawn(ctx), "|")
  assertTrue(labels:find("Alpha one", 1, true) ~= nil, "the rows are still drawn under it")
end)

test("widgets: rerender takes over a tab click: activeTab set, no ClearScroll, refreshers kept",
function()
  -- red under: minor 7, which clears the scroll (and with it ctx.refreshers) and re-renders itself.
  local O, _, ctx = bench()
  local calls = {}
  O.RenderTabbedSchema(ctx, "tabbed", nil, nil,
    { rerender = function(c) calls[#calls + 1] = { c = c, tab = c.activeTab } end })
  local mine = function() end
  ctx.refreshers[#ctx.refreshers + 1] = mine
  local cleared = 0
  local realClear = O.ClearScroll
  O.ClearScroll = function(...) cleared = cleared + 1; return realClear(...) end
  ctx.__tabKids[2]:__fire("OnClick")
  O.ClearScroll = realClear
  assertEqual(#calls, 1, "the host redraws, once")
  assertTrue(calls[1].c == ctx, "handed the page's ctx")
  assertEqual(calls[1].tab, "Beta", "with activeTab already set to the clicked tab")
  assertEqual(cleared, 0, "the library did not clear the scroll itself")
  assertTrue(ctx.refreshers[#ctx.refreshers] == mine, "a refresher the host appended survives")
end)

test("widgets: a raising rerender is reported and the strip stays usable", function()
  -- red under: calling rerender unguarded, which raises out of the tab button's OnClick.
  local O, rec, ctx = bench()
  local calls = 0
  O.RenderTabbedSchema(ctx, "tabbed", nil, nil,
    { rerender = function() calls = calls + 1; error("host redraw bug") end })
  rec.chat = {}
  local ok, err = pcall(ctx.__tabKids[2].__fire, ctx.__tabKids[2], "OnClick")
  assertTrue(ok, "the click did not raise: " .. tostring(err))
  assertTrue(table.concat(rec.chat, "\n"):find("host redraw bug", 1, true) ~= nil, "reported")
  ctx.__tabKids[3]:__fire("OnClick")
  assertEqual(ctx.activeTab, "Gamma", "a later click still switches")
  assertEqual(calls, 2)
end)

test("widgets: with OptionsTabs.lua absent RenderTabbedSchema takes opts and renders untabbed",
function()
  -- The widget half's fallback, which the chrome half's attach overrides. A host passing the new
  -- fifth argument to a partial copy must still get a usable page and no raise.
  -- red under: the fallback raising on opts, or drawing nothing.
  local savedTabs = lib.__AttachTabs
  lib.__AttachTabs = nil
  local O, _, ctx = bench()
  lib.__AttachTabs = savedTabs
  assertNil(O.TabStrip, "the tab half really is absent")
  local ok, groups = pcall(O.RenderTabbedSchema, ctx, "tabbed", nil, nil, {
    tabs = { { key = "Custom", label = "Custom", render = function() end } },
    disabledFor = function() return true end, disabledNotice = "off",
    chrome = function() end,
  })
  assertTrue(ok, "the fallback must not raise: " .. tostring(groups))
  assertEqual(table.concat(groups, "|"), "Alpha|Beta|Gamma|Delta")
  local labels = table.concat(drawn(ctx), "|")
  assertTrue(labels:find("Alpha one", 1, true) ~= nil and labels:find("Delta", 1, true) ~= nil,
    "every group drawn, with its heading")
end)

test("widgets: the tab half alone does not define RenderTabbedSchema over no flow engine", function()
  -- red under: defining it unconditionally, which raises on O.RenderRows the first time it runs.
  local savedWidgets = lib.__AttachWidgets
  lib.__AttachWidgets = nil
  local O = bench()
  lib.__AttachWidgets = savedWidgets
  assertNil(O.RenderTabbedSchema, "no flow engine, no tabbed render")
end)

-- ── the page banner's action button (T4, options-ui-§14's picker+create band) ──────────────

test("widgets: PageBanner's action draws a Button whose click calls onClick", function()
  -- red under: ignoring spec.action.
  local O, _, ctx = bench()
  local clicks = 0
  local spec = { label = "Container", list = { [1] = "One" }, order = { 1 }, value = 1,
                 onSelect = function() end,
                 action = { text = "New container", tooltip = "Make one", onClick = function()
                   clicks = clicks + 1 end } }
  local dd, btn = O.PageBanner(ctx, spec)
  assertEqual(dd.type, "Dropdown", "the picker is still the first return")
  assertEqual(btn and btn.type, "Button", "the action is a Button")
  assertEqual(btn.text, "New container")
  btn:__fire("OnClick")
  assertEqual(clicks, 1)

  local _, none = O.PageBanner(ctx, BANNER)
  assertNil(none, "no action, no button")
end)

test("widgets: PageBanner's action button is Released like its picker, never leaked", function()
  -- red under: creating the Button per render and never Releasing it.
  local O, _, ctx = bench()
  local spec = { label = "W", list = { [1] = "One" }, order = { 1 }, value = 1,
                 action = { text = "New", onClick = function() end } }
  local before = T.mocks.__aceguiLive("Button")
  local _, first = O.PageBanner(ctx, spec)
  O.PageBanner(ctx, spec)
  assertEqual(T.mocks.__aceguiLive("Button") - before, 1, "one action button out after two renders")
  assertTrue(first.__released, "the first render's button went back to AceGUI")
  O.PageHeader(ctx, { height = 60, build = function() end })
  assertEqual(T.mocks.__aceguiLive("Button") - before, 0, "a header took the band and the button")
end)

test("widgets: PageBanner's action re-rendering from its own click never hands itself back",
function()
  -- The create act re-renders the page from inside the button's own OnClick, exactly as a
  -- selection does from inside the picker's callback.
  -- red under: releasing the old button before the replacement Button is created.
  local O, _, ctx = bench()
  local spec = { label = "W", list = { [1] = "One" }, order = { 1 }, value = 1 }
  local second
  spec.action = { text = "New", onClick = function() local _, b = O.PageBanner(ctx, spec); second = b end }
  local before = T.mocks.__aceguiLive("Button")
  local _, first = O.PageBanner(ctx, spec)
  local outAtRelease
  function first.OnRelease() outAtRelease = T.mocks.__aceguiLive("Button") - before end
  first:__fire("OnClick")
  assertTrue(second ~= nil and second ~= first, "the re-render drew a fresh button")
  assertTrue(first.__released, "the old button went back to AceGUI")
  assertEqual(outAtRelease, 2, "the old button was released before its replacement existed")
  assertEqual(T.mocks.__aceguiLive("Button") - before, 1)
end)

test("widgets: PageBanner's action is refused in combat, like its picker", function()
  -- red under: calling onClick unguarded while the page is locked.
  local O, _, ctx = bench()
  local clicks = 0
  local _, btn = O.PageBanner(ctx, { label = "W", list = { [1] = "One" }, order = { 1 }, value = 1,
    action = { text = "New", onClick = function() clicks = clicks + 1 end } })
  assertTrue(btn ~= nil, "the action drew a button")
  local saved = T.mocks.InCombatLockdown
  T.mocks.InCombatLockdown = function() return true end
  local ok, err = pcall(btn.__fire, btn, "OnClick")
  T.mocks.InCombatLockdown = saved
  if not ok then error(err) end
  assertEqual(clicks, 0, "a create act ran in combat")
end)
