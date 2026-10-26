-- tests/test_options_drawer.lua -- LibKa0s-Options-1.0's OptionsDrawer.lua (minor 1): the drawer, a
-- header bar that opens a bordered box the host fills with ordinary AceGUI rows, and Options minor
-- 29's two reads of it (the attach, and RefreshPanel taking a drawer's ctx back to its page).
--
-- The kit's AceGUI widgets are inert recorders and its frames answer no geometry, so the header's
-- dress is read off the fields the file records on the header button (`__ka0sDrawer*`), the way
-- tests/test_options_nav.lua reads a rail entry's, and the body's padding off the patched methods
-- called directly.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local Fixture = dofile("tests/fixture_options.lua")
local lib = T.options

local panelSeq = 0
local function bench(overrides)
  local O, rec = Fixture.new(overrides)
  panelSeq = panelSeq + 1
  local ctx = O.CreatePanel("DrawerBench" .. panelSeq, "Drawer " .. panelSeq, {})
  return O, rec, ctx
end

--- The drawer's header button: the one frame the file hangs on the header group's frame.
local function headOf(drawer)
  return drawer.header.frame.__ka0sDrawerHead
end

local function hasText(chat, needle)
  for _, line in ipairs(chat) do
    if tostring(line):find(needle, 1, true) then return true end
  end
  return false
end

-- ── the version ──────────────────────────────────────────────────────────────────────────────

test("drawer: OptionsDrawer is at minor 1 or later, attached to an Options shell at 29 or later", function()
  assertTrue(lib.MODULES.OptionsDrawer >= 1, "OptionsDrawer minor " .. tostring(lib.MODULES.OptionsDrawer))
  assertTrue(lib.MINOR >= 29, "Options.lua minor " .. tostring(lib.MINOR))
  assertEqual(lib.__drawerShellMinor, lib.MINOR)
end)

-- ── the closed drawer ────────────────────────────────────────────────────────────────────────

test("drawer: a closed drawer is one full-width group on the page, a header and no body", function()
  local O, _, ctx = bench()
  local called = false
  local d = O.Drawer(ctx, { label = "Content", summary = "Any", open = false,
    body = function() called = true end })
  local scroll = O.EnsureScroll(ctx)
  assertEqual(scroll.children[#scroll.children], d.group, "the drawer is one child of the page")
  assertTrue(d.group.fullWidth)
  assertEqual(d.group.children[1], d.header, "the header leads the group")
  assertNil(d.body, "closed: no body")
  assertNil(d.ctx, "and no body ctx")
  assertFalse(called, "a closed drawer never asks the host for its body")
  assertFalse(d.open)
end)

test("drawer: the header carries the label and the summary; set is gold, unset white and gray", function()
  local O, _, ctx = bench()
  local unset = headOf(O.Drawer(ctx, { label = "Role", summary = "Any" }))
  assertEqual(unset.__ka0sDrawerLabel, "Role")
  assertEqual(unset.__ka0sDrawerSummary, "Any")
  assertFalse(unset.__ka0sDrawerSet)
  assertEqual(table.concat(unset.__ka0sDrawerLabelRGB, ","), "1,1,1", "an unset condition reads white")
  local set = headOf(O.Drawer(ctx, { label = "Content", summary = "Dungeon, M+", set = true }))
  assertTrue(set.__ka0sDrawerSet)
  assertEqual(table.concat(set.__ka0sDrawerLabelRGB, ","), "1,0.82,0", "a set condition reads gold")
  assertFalse(table.concat(set.__ka0sDrawerSummaryRGB, ",") == table.concat(unset.__ka0sDrawerSummaryRGB, ","),
    "the summary of a set condition is not the gray of Any")
end)

test("drawer: summary and set may be functions, read when the drawer is drawn", function()
  local O, _, ctx = bench()
  local head = headOf(O.Drawer(ctx, { label = "Key level",
    summary = function() return "10 or higher" end, set = function() return true end }))
  assertEqual(head.__ka0sDrawerSummary, "10 or higher")
  assertTrue(head.__ka0sDrawerSet)
end)

test("drawer: a summary function that raises reads as no summary and is reported", function()
  local O, rec, ctx = bench()
  local head = headOf(O.Drawer(ctx, { label = "Class", summary = function() error("boom") end }))
  assertEqual(head.__ka0sDrawerSummary, "")
  assertTrue(hasText(rec.chat, "boom"), "the raise is reported, not swallowed")
end)

test("drawer: the chevron points right while closed and down while open", function()
  local O, _, ctx = bench()
  assertFalse(headOf(O.Drawer(ctx, { label = "A", open = false })).__ka0sDrawerOpen)
  assertTrue(headOf(O.Drawer(ctx, { label = "B", open = true })).__ka0sDrawerOpen)
end)

-- ── opening and closing ──────────────────────────────────────────────────────────────────────

test("drawer: a header click hands the host the other state, then re-renders the page once", function()
  local O, _, ctx = bench()
  local told, refreshed = {}, {}
  O.RefreshPanel = function(c, structural) refreshed[#refreshed + 1] = { c, structural } end
  local d = O.Drawer(ctx, { label = "Group", open = false, onToggle = function(v) told[#told + 1] = v end })
  headOf(d):__fire("OnClick")
  assertEqual(#told, 1)
  assertEqual(told[1], true, "closed -> open")
  assertEqual(#refreshed, 1)
  assertEqual(refreshed[1][1], ctx, "the page is refreshed, not a body ctx")
  assertEqual(refreshed[1][2], true, "structurally: a drawer that opens changes the page's shape")
  local open = O.Drawer(ctx, { label = "Group", open = true, onToggle = function(v) told[#told + 1] = v end })
  headOf(open):__fire("OnClick")
  assertEqual(told[2], false, "open -> closed")
end)

test("drawer: a header click keeps the page's scroll offset across the re-render", function()
  -- red under: a toggle that re-renders the page without carrying the scroll offset across it.
  -- The kit's ScrollFrame has no geometry, so the real loss (ClearScroll, then the first AddChild's
  -- FixScroll taking the "content fits" branch) is stood in for by a renderer that zeroes it. The
  -- offset is kept by RefreshPanel itself (Options.lua's keepScroll), so the real one runs here.
  local O, _, ctx = bench()
  local scroll = O.EnsureScroll(ctx)
  O.SetRenderer(ctx, function() scroll.localstatus.offset = 0 end)
  ctx.panel:Show(); ctx.panel:__fire("OnShow")
  scroll.localstatus.offset = 120
  local fixed = 0
  scroll.FixScroll = function() fixed = fixed + 1 end
  local d = O.Drawer(ctx, { label = "Battleground", open = false, onToggle = function() end })
  headOf(d):__fire("OnClick")
  assertEqual(scroll.localstatus.offset, 120, "the offset the player scrolled to survives the toggle")
  assertEqual(fixed, 1, "and the scroll is re-fixed to it, clamped to the new end")
end)

test("drawer: a header click is refused in combat, and the host is not told", function()
  -- red under: a click that calls onToggle without asking the shell's combat refusal.
  local O, _, ctx = bench()
  local told, asked = 0, nil
  O.__combatRefused = function(kind, subject) asked = { kind, subject }; return true end
  local refreshed = 0
  O.RefreshPanel = function() refreshed = refreshed + 1 end
  local d = O.Drawer(ctx, { label = "Role", onToggle = function() told = told + 1 end })
  headOf(d):__fire("OnClick")
  assertEqual(told, 0)
  assertEqual(refreshed, 0)
  assertEqual(asked[1], "drawer")
  assertEqual(asked[2], "Role", "the refusal names the drawer, for the shell's Cfg line")
end)

test("drawer: an onToggle that raises is reported and the click goes no further", function()
  local O, rec, ctx = bench()
  local refreshed = 0
  O.RefreshPanel = function() refreshed = refreshed + 1 end
  local d = O.Drawer(ctx, { label = "Role", onToggle = function() error("toggle broke") end })
  headOf(d):__fire("OnClick")
  assertTrue(hasText(rec.chat, "toggle broke"))
  assertEqual(refreshed, 0, "a failed toggle stored nothing, so there is nothing to redraw")
end)

-- ── the body ─────────────────────────────────────────────────────────────────────────────────

test("drawer: an open drawer asks the host for its body, with a ctx whose scroll is the body", function()
  local O, _, ctx = bench()
  local got
  local d = O.Drawer(ctx, { label = "Content", open = true, body = function(c, body) got = { c, body } end })
  assertTrue(d.body ~= nil, "open: a body")
  assertEqual(d.group.children[2], d.body, "under the header, in the same group")
  assertEqual(got[1], d.ctx)
  assertEqual(got[2], d.body)
  assertEqual(O.EnsureScroll(d.ctx), d.body, "every helper that draws into EnsureScroll draws into the box")
  assertTrue(d.open)
end)

test("drawer: the ordinary helpers draw into the box, not onto the page", function()
  local O, _, ctx = bench()
  local scroll = O.EnsureScroll(ctx)
  local before = #scroll.children
  local d = O.Drawer(ctx, { label = "Key level", open = true, body = function(c)
    O.TextRow(c, "a line in the box")
    O.RenderGrid(c, { { make = function(_, parent) local w = O.AceGUI:Create("CheckBox"); parent:AddChild(w); return w end } })
  end })
  assertEqual(#scroll.children, before + 1, "the page gained the drawer and nothing else")
  assertEqual(d.body.children[1].text, "a line in the box")
  assertEqual(d.body.children[2].type, "SimpleGroup", "and the grid's row went into the box")
end)

test("drawer: the body ctx reads the page's fields and writes through to the page", function()
  -- red under: a ctx built with __index alone, where a host's per-page list started from the body
  -- ctx lands on a table nothing keeps.
  local O, _, ctx = bench()
  ctx.hostField = "page"
  local d = O.Drawer(ctx, { label = "Class", open = true, body = function(c)
    assertEqual(c.hostField, "page", "a read reaches the page")
    c.hostList = { "written in the body" }
    c.refreshers[#c.refreshers + 1] = function() end
  end })
  assertEqual(ctx.hostList[1], "written in the body", "a write lands on the page")
  assertNil(rawget(d.ctx, "hostList"), "and not on the view")
  assertTrue(#ctx.refreshers >= 1, "a refresher registered in the box is the page's")
end)

test("drawer: RefreshPanel on a body ctx refreshes the page it is drawn on", function()
  -- red under: Options.lua's RefreshPanel without the page redirect, which renders the page's
  -- renderer into the body ctx's scroll -- the whole page inside one drawer.
  local O, _, ctx = bench()
  local renderedWith = {}
  O.SetRenderer(ctx, function(c) renderedWith[#renderedWith + 1] = c end)
  ctx.panel:Show()
  ctx._rendered = true
  local d = O.Drawer(ctx, { label = "Role", open = true, body = function() end })
  O.RefreshPanel(d.ctx, true)
  assertEqual(renderedWith[#renderedWith], ctx)
end)

test("drawer: a body that raises is reported against the drawer and the page goes on", function()
  local O, rec, ctx = bench()
  local d = O.Drawer(ctx, { label = "Specialization", open = true, body = function() error("no specs") end })
  assertTrue(d ~= nil and d.body ~= nil, "the drawer is still drawn")
  assertTrue(hasText(rec.chat, "Specialization"), "the line names the drawer")
  assertTrue(hasText(rec.chat, "no specs"))
  assertTrue(O.TextRow(ctx, "after") ~= nil, "and the page goes on")
end)

test("drawer: a disabled drawer draws its body under the render-disabled flag, and lifts it after", function()
  local O, _, ctx = bench()
  local seen
  O.Drawer(ctx, { label = "Content", open = true, disabled = true, body = function(c)
    seen = c.__renderDisabled
    O.InlineButtonPair(c, { text = "In the box", onClick = function() end })
  end })
  assertTrue(seen, "the body is drawn disabled")
  assertNil(ctx.__renderDisabled, "and the page's flag is put back")
  local ok = pcall(O.Drawer, ctx, { label = "X", open = true, disabled = true, body = function() error("x") end })
  assertTrue(ok)
  assertNil(ctx.__renderDisabled, "put back after a raise too")
end)

test("drawer: a drawer inside a drawer writes to the page and refreshes the page", function()
  local O, _, ctx = bench()
  local refreshed = {}
  O.RefreshPanel = function(c) refreshed[#refreshed + 1] = c end
  local inner
  O.Drawer(ctx, { label = "Outer", open = true, body = function(c)
    inner = O.Drawer(c, { label = "Inner", open = true, onToggle = function() end, body = function(ic)
      ic.deep = true
    end })
  end })
  assertTrue(ctx.deep, "the inner box's write reached the page")
  headOf(inner):__fire("OnClick")
  assertEqual(refreshed[1], ctx, "the inner toggle refreshes the page")
end)

-- ── the actions ──────────────────────────────────────────────────────────────────────────────

local function buttonsIn(row)
  local out = {}
  for _, w in ipairs(row.children) do
    if w.type == "Button" then out[#out + 1] = w end
  end
  return out
end

test("drawer: actions sit right-aligned on the box's last line, in the order given", function()
  local O, _, ctx = bench()
  local d = O.Drawer(ctx, { label = "Role", open = true, body = function(c) O.TextRow(c, "x") end,
    actions = { { text = "Select all" }, { text = "Clear (Any)" } } })
  local row = d.body.children[#d.body.children]
  assertEqual(row, d.actions, "the action line is the box's last child")
  assertEqual(row.children[1].type, "Label", "a filler first, so the buttons end at the right edge")
  local b = buttonsIn(row)
  assertEqual(#b, 2)
  assertEqual(b[1].text, "Select all")
  assertEqual(b[2].text, "Clear (Any)")
  local total = 0
  for _, w in ipairs(row.children) do total = total + (w.relativeWidth or 0) end
  assertTrue(total < 1, "the line fits one Flow row, clear of the scroll's clip")
end)

test("drawer: a closed drawer draws no actions; a drawer with none draws no action line", function()
  local O, _, ctx = bench()
  local closed = O.Drawer(ctx, { label = "Role", actions = { { text = "Clear (Any)" } } })
  assertNil(closed.actions)
  local bare = O.Drawer(ctx, { label = "Role", open = true, body = function() end })
  assertNil(bare.actions)
end)

test("drawer: an action click runs the host's onClick; refused in combat; a raise is reported", function()
  local O, rec, ctx = bench()
  local ran = 0
  local d = O.Drawer(ctx, { label = "Role", open = true,
    actions = { { text = "Clear (Any)", onClick = function() ran = ran + 1 end },
                { text = "Broken", onClick = function() error("action broke") end } } })
  local b = buttonsIn(d.actions)
  b[1]:__fire("OnClick")
  assertEqual(ran, 1)
  b[2]:__fire("OnClick")
  assertTrue(hasText(rec.chat, "action broke"))
  O.__combatRefused = function() return true end
  b[1]:__fire("OnClick")
  assertEqual(ran, 1, "refused in combat")
end)

test("drawer: a disabled drawer's actions are drawn disabled", function()
  local O, _, ctx = bench()
  local d = O.Drawer(ctx, { label = "Role", open = true, disabled = true, actions = { { text = "Clear (Any)" } } })
  assertTrue(buttonsIn(d.actions)[1].disabled)
end)

test("drawer: a drawer drawn while the page is render-disabled draws its actions disabled", function()
  -- red under: drawActions reading spec.disabled alone, so a drawer on a disabled tab (RenderRows'
  -- opts.disabled, a host tab rendered disabled) keeps live Select all / Clear buttons.
  local O, _, ctx = bench()
  ctx.__renderDisabled = true
  local d = O.Drawer(ctx, { label = "Role", open = true, actions = { { text = "Clear (Any)" } } })
  ctx.__renderDisabled = nil
  assertTrue(buttonsIn(d.actions)[1].disabled, "the action honors the page's flag")
  local live = O.Drawer(ctx, { label = "Role", open = true, actions = { { text = "Clear (Any)" } } })
  assertFalse(buttonsIn(live.actions)[1].disabled == true, "and is live on an enabled page")
end)

-- ── the box's padding, and what goes back to the pool ────────────────────────────────────────

test("drawer: the box pads its content and grows by the padding when it lays out", function()
  local O, _, ctx = bench()
  local d = O.Drawer(ctx, { label = "Role", open = true })
  local pad = lib.__drawerPad
  d.body:LayoutFinished(300, 40)
  assertEqual(d.body.height, 40 + pad.top + pad.bottom)
  d.body.content = { SetWidth = function(self, w) self.w = w end }
  d.body:OnWidthSet(300)
  assertEqual(d.body.content.width, 300 - pad.left - pad.right, "the Flow inside lays out to the inner width")
end)

test("drawer: released, the box's methods and the header's button are handed back clean", function()
  -- red under: methods patched on a widget AceGUI pools, left in place for the next SimpleGroup
  -- any addon in the session asks for.
  local O, _, ctx = bench()
  local d = O.Drawer(ctx, { label = "Role", open = true, onToggle = function() end })
  local body, head = d.body, headOf(d)
  local patched = body.LayoutFinished
  assertTrue(patched ~= nil)
  O.AceGUI:Release(body)
  assertFalse(body.LayoutFinished == patched, "the patch is taken off")
  O.AceGUI:Release(d.header)
  assertFalse(head:IsShown(), "the header's button is hidden with its pooled frame")
  assertNil(head:GetScript("OnClick"), "and it can fire no stale toggle")
end)

-- ── degraded ─────────────────────────────────────────────────────────────────────────────────

test("drawer: with OptionsDrawer.lua absent there is no Drawer, and the page is untouched", function()
  local saved = lib.__AttachDrawer
  lib.__AttachDrawer = nil
  local ok, err = pcall(function()
    local O = Fixture.new()
    assertNil(O.Drawer)
  end)
  lib.__AttachDrawer = saved
  if not ok then error(err, 0) end
end)

test("drawer: with no AceGUI it draws nothing and answers nil", function()
  local saved = T.mocks.__libs["AceGUI-3.0"]
  T.mocks.__libs["AceGUI-3.0"] = nil
  local ok, err = pcall(function()
    local O, _, ctx = bench()
    assertNil(O.Drawer(ctx, { label = "Role", open = true }))
  end)
  T.mocks.__libs["AceGUI-3.0"] = saved
  if not ok then error(err, 0) end
end)
