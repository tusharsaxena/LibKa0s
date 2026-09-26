-- tests/test_options_nav.lua -- LibKa0s-Options-1.0's OptionsNav.lua (minor 1): the nav rail, the
-- first level of a page that edits one instance out of many (options-ui-§13), and the one inset the
-- strip, the content panel and the scroll all read so they start right of it.
--
-- The kit's frame stub no-ops SetPoint and answers no geometry, so every layout case here records
-- anchors itself (`recording`), and the alignment case answers atlas heights itself (`withArt`),
-- the same two devices tests/test_options_tabs.lua's `instrument` uses for the strip.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local Fixture = dofile("tests/fixture_options.lua")
local lib = T.options
local L = lib.LAYOUT

local panelSeq = 0
local function bench(overrides)
  local O, rec = Fixture.new(overrides)
  panelSeq = panelSeq + 1
  local ctx = O.CreatePanel("NavBench" .. panelSeq, "Nav " .. panelSeq, {})
  return O, rec, ctx
end

local ENTRIES = {
  { key = "general", label = "General", tooltip = "The instance itself." },
  { key = "filters", label = "Filters" },
  { key = "layout",  label = "Layout" },
}

local FOUR_TABS = {
  { key = "a", label = "A" }, { key = "b", label = "B" }, { key = "c", label = "C" }, { key = "d", label = "D" },
}

--- Every frame CreateFrame builds while `fn` runs, with the anchors later set on it. ClearAllPoints
--- empties them, as the client's does. The overrides stay on the frames after `fn` returns, so a
--- case can watch a later re-placement too.
local function recording(fn)
  local real = T.mocks.CreateFrame
  local made = {}
  T.mocks.CreateFrame = function(kind, name, parent, template)
    local f = real(kind, name, parent, template)
    local rec = { kind = kind, parent = parent, template = template, frame = f, points = {} }
    made[#made + 1] = rec
    rawset(f, "SetPoint", function(self, point, rel, relPoint, x, y)
      rec.points[point] = { rel = rel, relPoint = relPoint, x = x, y = y }
      return self
    end)
    rawset(f, "ClearAllPoints", function(self) rec.points = {}; return self end)
    return f
  end
  local ok, err = pcall(fn)
  T.mocks.CreateFrame = real
  if not ok then error(err, 0) end
  return made
end

local function byParent(made, parent, kind)
  local out = {}
  for _, r in ipairs(made) do
    if r.parent == parent and (kind == nil or r.kind == kind) then out[#out + 1] = r end
  end
  return out
end

--- Run `fn` with every texture answering `activeH` for an `*_Active_*` atlas and `inactiveH` for any
--- other, both measurements forgotten on the way in and out (they are cached for the session). Each
--- texture is its OWN object (the kit's CreateTexture answers the frame itself), and every other
--- method is a no-op, so a tab strip drawn inside `fn` dresses its art on these too.
local NOOP = function() end
local function withArt(O, inactiveH, activeH, fn)
  local real = T.mocks.CreateFrame
  T.mocks.CreateFrame = function(kind, ...)
    local f = real(kind, ...)
    rawset(f, "CreateTexture", function()
      local t, atlas = {}, nil
      function t:SetAtlas(name) atlas = name end
      function t:GetHeight()
        if atlas and atlas:find("Active", 1, true) then return activeH end
        return inactiveH
      end
      return setmetatable(t, { __index = function() return NOOP end })
    end)
    return f
  end
  O.__resetNavArtHeight()
  O.__resetTabArtHeight()
  local ok, err = pcall(fn)
  T.mocks.CreateFrame = real
  O.__resetNavArtHeight()
  O.__resetTabArtHeight()
  if not ok then error(err, 0) end
end

--- Draw a four-tab strip on `ctx` (after a rail when `rail`), with the chrome `chromeW` wide, and
--- answer the first tab's x, the content panel's anchors, the scroll's left x and the row count.
local function stripUnder(O, ctx, rail, chromeW)
  if rail then O.NavRail(ctx, { entries = ENTRIES, value = "general" }) end
  ctx.chrome:__setGeom(chromeW or 260, 0)
  local made = recording(function()
    O.TabStrip(ctx, { tabs = FOUR_TABS, value = "a" })
  end)
  local tabs, panels = byParent(made, ctx.chrome, "Button"), byParent(made, ctx.body, "Frame")
  local rows, rowCount = {}, 0
  for _, t in ipairs(tabs) do
    if not rows[t.points.TOPLEFT.y] then rowCount = rowCount + 1 end
    rows[t.points.TOPLEFT.y] = true
  end
  local scroll = O.EnsureScroll(ctx)
  local at = {}
  rawset(scroll.frame, "SetPoint", function(self, point, _, _, x) at[point] = x; return self end)
  O.SetChromeHeight(ctx, ctx.chromeHeight)
  return { tabX = tabs[1].points.TOPLEFT.x, panel = panels[#panels].points, scrollX = at.TOPLEFT,
           rows = rowCount }
end

-- ── the seams ────────────────────────────────────────────────────────────────────────────────

test("nav: the rail inset is zero with no rail and the rail's width plus its 12px gap with one", function()
  -- red under: an inset that answers the gap alone for a page with no rail (every page in the
  -- collection would move 12px right), or one that ignores a released rail's zero width.
  local O, _, ctx = bench()
  assertEqual(O.__railInset(ctx), 0, "a page that never drew a rail")
  ctx.railWidth = 0
  assertEqual(O.__railInset(ctx), 0, "a rail released to nothing")
  ctx.railWidth = 120
  assertEqual(O.__railInset(ctx), 132)
  ctx.railWidth = 90
  assertEqual(O.__railInset(ctx), 102)
  assertEqual(O.__railInset(nil), 0, "no ctx")
  assertEqual(O.__railInset, lib.__railInset, "one function, read by the shell, the strip and the panel")
end)

test("nav: the rail's top is measured off the ACTIVE tab art, under the banner's band", function()
  -- red under: the rail anchored to the tab BUTTON's top (a hard-coded 0), to the inactive art
  -- (a few pixels below the selected tab's top), or with the banner's band left out.
  local O, _, ctx = bench()
  withArt(O, 28, 33, function()
    assertEqual(O.__navArtHeight(), 33, "the active cap, measured")
    assertEqual(O.__railTop(ctx), -(L.TAB_H - 33), "no banner: level with the selected tab's art")
    ctx.__bannerHeight = 50
    assertEqual(O.__railTop(ctx), -(50 + L.TAB_H - 33), "under the band the banner reserved")
  end)
  ctx.__bannerHeight = nil
  withArt(O, 26, 30, function()
    -- another client scale answers another height, and the rail follows it: never hard-coded
    assertEqual(O.__railTop(ctx), -(L.TAB_H - 30))
  end)
  withArt(O, nil, nil, function()
    -- nothing measurable: the strip's own fallback, the button height, so the chrome's top
    assertEqual(O.__railTop(ctx), 0)
  end)
end)

test("nav: the probe's cap is the drawn selected tab's own art, so the rail's top is level with the strip beside it (spec §2, §4; A2)", function()
  -- red under: a probe measuring an atlas other than the one the selected tab is drawn from (the rail
  -- would sit a few pixels off the tab art beside it), or a rail top taken from the shorter,
  -- unselected art. The spec asks for the top "measured from the drawn tab's textures": this pins
  -- that the number the rail uses IS the drawn tab's, with a stub texture set.
  local O, _, ctx = bench()
  withArt(O, 28, 33, function()
    ctx.__bannerHeight = 50
    O.NavRail(ctx, { entries = ENTRIES, value = "general" })
    ctx.chrome:__setGeom(600, 0)                    -- one row: every tab on the rail's line
    O.TabStrip(ctx, { tabs = FOUR_TABS, value = "a" })
    local tallest = 0
    for _, b in ipairs(ctx.__tabKids) do             -- the ledger also holds the content panel
      local art = b.__ka0sTabArt
      if art and art.left then tallest = math.max(tallest, art.left:GetHeight() or 0) end
    end
    assertEqual(tallest, 33, "the selected tab is drawn from the active cap")
    assertEqual(O.__navArtHeight(), tallest, "the probe measured the atlas the drawn tab carries")
    assertEqual(O.__railTop(ctx), -(50 + L.TAB_H - tallest), "and the rail's top is that art's top")
  end)
  ctx.__bannerHeight = nil
end)

test("nav: entries stack 20px apart from 8px below the rail's top", function()
  local O = bench()
  assertEqual(O.__railEntryY(1), -8)
  assertEqual(O.__railEntryY(2), -28)
  assertEqual(O.__railEntryY(3), -48)
end)

-- ── drawing ──────────────────────────────────────────────────────────────────────────────────

test("nav: NavRail draws one entry per spec entry, records railWidth, and disables the selected one", function()
  -- red under: the selection read from anything but spec.value, or the width not recorded (the
  -- strip, the panel and the scroll would never move).
  local O, _, ctx = bench()
  local buttons = O.NavRail(ctx, { entries = ENTRIES, value = "filters", onSelect = function() end })
  assertEqual(#buttons, 3)
  assertEqual(ctx.railWidth, 120, "the default width is Test10's")
  for i, b in ipairs(buttons) do
    assertEqual(b.__ka0sNavKey, ENTRIES[i].key)
    assertEqual(b.__ka0sNavText, ENTRIES[i].label)
    assertTrue(b:IsShown(), ENTRIES[i].key .. " shown")
    assertEqual(ctx.__railKids[i], b, "the ledger a suite reads, in rail order")
  end
  assertFalse(buttons[2]:IsEnabled(), "the selected entry is disabled, as the active tab is")
  assertTrue(buttons[1]:IsEnabled() and buttons[3]:IsEnabled(), "the others are live")
  assertTrue(buttons[2].__ka0sNavSelected and not buttons[1].__ka0sNavSelected)
  assertEqual(buttons[1].__ka0sNavTip, "The instance itself.")
  local again = O.NavRail(ctx, { entries = { ENTRIES[2], ENTRIES[1] }, value = "general", width = 90 })
  assertEqual(ctx.railWidth, 90, "spec.width wins")
  -- red under: a dress that only ADDS fields (a pooled button keeps the last entry's tooltip)
  assertNil(again[1].__ka0sNavTip, "Filters carries no tooltip, whichever button it landed on")
  assertEqual(again[2].__ka0sNavTip, "The instance itself.")
end)

test("nav: the rail hangs in the body at the content column's left edge, from the art's top to the panel's foot", function()
  -- red under: the rail parented to the panel (outside the body, where the lab put it), anchored
  -- anywhere but CONTENT_LEFT, or its entries placed off the pure seam.
  local O, _, ctx = bench()
  local made = recording(function()
    O.NavRail(ctx, { entries = ENTRIES, value = "general" })
  end)
  local rails = byParent(made, ctx.body)
  assertEqual(#rails, 1, "one rail frame, a child of the body, so the cover's level walk finds it")
  local r = rails[1]
  assertEqual(r.template, "BackdropTemplate", "the tree pane's backdrop")
  assertEqual(r.points.TOPLEFT.rel, ctx.body)
  assertEqual(r.points.TOPLEFT.x, L.CONTENT_LEFT)
  assertEqual(r.points.TOPLEFT.y, O.__railTop(ctx))
  assertEqual(r.points.BOTTOMLEFT.rel, ctx.body)
  assertEqual(r.points.BOTTOMLEFT.x, L.CONTENT_LEFT)
  assertEqual(r.points.BOTTOMLEFT.y, L.PANEL_BOTTOM, "level with the content panel's foot")
  local entries = byParent(made, r.frame, "Button")
  assertEqual(#entries, 3)
  for i, e in ipairs(entries) do
    assertEqual(e.points.TOPLEFT.y, O.__railEntryY(i), "entry " .. i)
    assertEqual(e.points.TOPLEFT.x, 5)
    assertEqual(e.points.TOPRIGHT.x, -5)
  end
end)

-- ── the one inset ────────────────────────────────────────────────────────────────────────────

test("nav: with no rail the strip, the content panel and the scroll are anchored exactly as before", function()
  -- red under: an inset that is not zero for railWidth nil or 0 -- every page in the collection,
  -- including the ten hosts that never draw a rail, would move.
  for _, width in ipairs({ false, 0 }) do
    local O, _, ctx = bench()
    if width then ctx.railWidth = width end
    local got = stripUnder(O, ctx, false)
    assertEqual(got.tabX, 0, "the first tab at the chrome's left")
    assertEqual(got.panel.TOPLEFT.x, -(L.CONTENT_LEFT - L.PANEL_LEFT))
    assertEqual(got.panel.BOTTOMLEFT.x, L.PANEL_LEFT)
    assertEqual(got.scrollX, L.CONTENT_LEFT)
    assertEqual(got.rows, 1, "four 60px tabs fit 260px on one row")
  end
end)

test("nav: with a rail the strip, the content panel's left edge and the scroll all move by the one inset", function()
  -- red under: any of the three reading a number of its own (the panel's edge, the first tab and
  -- the first control stop lining up), or the strip wrapping against the chrome's full width (tabs
  -- drawn under the rail's right edge).
  local O, _, ctx = bench()
  local got = stripUnder(O, ctx, true)
  local inset = O.__railInset(ctx)
  assertEqual(inset, 132)
  assertEqual(got.tabX, inset)
  assertEqual(got.panel.TOPLEFT.x, -(L.CONTENT_LEFT - L.PANEL_LEFT) + inset)
  assertEqual(got.panel.BOTTOMLEFT.x, L.PANEL_LEFT + inset)
  assertEqual(got.scrollX, L.CONTENT_LEFT + inset)
  assertEqual(got.rows, 2, "260 - 132 = 128 holds two 60px tabs a row")
  -- Test10's geometry, in body coordinates: the content panel's left edge 4px right of the rail's.
  assertEqual(L.CONTENT_LEFT + got.panel.TOPLEFT.x, L.CONTENT_LEFT + 120 + 4)
end)

test("nav: the first render's zero-width chrome re-places the strip, inset included, when the width arrives", function()
  -- The first page a player opens is drawn before the canvas has a width (OptionsTabs.lua's
  -- replaceOnResize). red under: a usable width left negative (every tab on its own row for good),
  -- or the re-placement measured against the full width, or the inset applied twice.
  local O, _, ctx = bench()
  O.NavRail(ctx, { entries = ENTRIES, value = "general" })
  local made = recording(function()
    O.TabStrip(ctx, { tabs = { { key = "a", label = "A" }, { key = "b", label = "B" } }, value = "a" })
  end)
  local tabs = byParent(made, ctx.chrome, "Button")
  assertEqual(tabs[1].points.TOPLEFT.x, 132, "placed at the inset even at zero width")
  assertTrue(tabs[1].points.TOPLEFT.y ~= tabs[2].points.TOPLEFT.y, "a zero-width chrome stacks them")
  ctx.chrome:GetScript("OnSizeChanged")(ctx.chrome, 600)
  assertEqual(tabs[1].points.TOPLEFT.x, 132)
  assertEqual(tabs[2].points.TOPLEFT.x, 132 + L.TAB_MIN_W + L.TAB_GAP, "one row once 468px arrive")
  assertEqual(tabs[1].points.TOPLEFT.y, tabs[2].points.TOPLEFT.y)
end)

-- ── the pool, the click, the release ─────────────────────────────────────────────────────────

test("nav: a re-render reuses the pooled entries and builds no frame; a shorter one hides the surplus", function()
  -- red under: entries built per render (a frame leaked per click for the session), or a released
  -- entry left shown under the rail's next, shorter list.
  local O, _, ctx = bench()
  local first = O.NavRail(ctx, { entries = ENTRIES, value = "general" })
  local made = recording(function()
    O.NavRail(ctx, { entries = ENTRIES, value = "layout" })
  end)
  assertEqual(#made, 0, "no frame built on the second render")
  local second = O.NavRail(ctx, { entries = { ENTRIES[1], ENTRIES[2] }, value = "general" })
  assertEqual(#second, 2)
  local shown = 0
  for _, b in ipairs(first) do if b:IsShown() then shown = shown + 1 end end
  assertEqual(shown, 2, "the third entry went back to the pool, hidden")
  assertEqual(#ctx.__railKids, 2)
end)

test("nav: a click on another entry hands its key to onSelect; the selected entry and a raising handler do nothing", function()
  local O, _, ctx = bench()
  local picked = {}
  local buttons = O.NavRail(ctx, { entries = ENTRIES, value = "general",
    onSelect = function(key) picked[#picked + 1] = key end })
  buttons[3]:__fire("OnClick")
  assertEqual(table.concat(picked, ","), "layout")
  buttons[1]:__fire("OnClick")
  -- red under: the selected entry re-rendering the page it is already on
  assertEqual(#picked, 1, "the selected entry does nothing")
  buttons = O.NavRail(ctx, { entries = ENTRIES, value = "general", onSelect = function() error("boom") end })
  -- red under: onSelect called bare, so a host's raise escapes into the client's click dispatch
  assertTrue(pcall(function() buttons[2]:__fire("OnClick") end), "a raising host handler stays inside the click")
end)

test("nav: an empty entry list releases the rail and gives the page its full width back", function()
  local O, _, ctx = bench()
  local buttons = O.NavRail(ctx, { entries = ENTRIES, value = "general" })
  assertNil(O.NavRail(ctx, { entries = {} }))
  assertEqual(ctx.railWidth, 0)
  assertEqual(O.__railInset(ctx), 0)
  assertFalse(ctx.__railFrame:IsShown(), "the rail frame is hidden")
  for _, b in ipairs(buttons) do assertFalse(b:IsShown(), "entry " .. b.__ka0sNavKey .. " hidden") end
  assertNil(O.NavRail(nil, { entries = ENTRIES }), "no ctx draws nothing")
end)

test("nav: a live scroll moves right of the rail at once, and back when the rail is released, with or without a band", function()
  -- NavRail re-anchors a live scroll itself, because nothing after it has to: a page may draw the
  -- rail over an untabbed section, and a page with no banner reserves no band. red under: a
  -- re-anchor gated on a reserved band (a bannerless page's scroll stays under the rail, and a
  -- released rail never gives the width back), or no re-anchor at all (a banner's band was reserved
  -- BEFORE the rail recorded its width).
  for _, band in ipairs({ 0, 40 }) do
    local O, _, ctx = bench()
    local scroll = O.EnsureScroll(ctx)
    O.SetChromeHeight(ctx, band)
    local at = {}
    rawset(scroll.frame, "SetPoint", function(self, point, _, _, x) at[point] = x; return self end)
    O.NavRail(ctx, { entries = ENTRIES, value = "general" })
    assertEqual(at.TOPLEFT, L.CONTENT_LEFT + 132, "band " .. band .. ": right of the rail")
    O.NavRail(ctx, { entries = {} })
    assertEqual(at.TOPLEFT, L.CONTENT_LEFT, "band " .. band .. ": the full width back")
    assertEqual(ctx.chromeHeight, band, "band " .. band .. ": the reserved band untouched")
  end
end)

test("nav: with OptionsNav.lua absent there is no NavRail and nothing is inset", function()
  -- docs/releasing.md: a partly copied Options major degrades rather than raising at a call site.
  -- red under: an unguarded cross-file call in anchorScroll, placeTabs or drawContentPanel.
  local savedAttach, savedInset = lib.__AttachNav, lib.__railInset
  lib.__AttachNav, lib.__railInset = nil, nil
  local ok, err = pcall(function()
    local O, _, ctx = bench()
    assertNil(O.NavRail, "the rail half really is absent")
    ctx.railWidth = 120
    local got = stripUnder(O, ctx, false)
    assertEqual(got.tabX, 0)
    assertEqual(got.panel.BOTTOMLEFT.x, L.PANEL_LEFT)
    assertEqual(got.scrollX, L.CONTENT_LEFT)
  end)
  lib.__AttachNav, lib.__railInset = savedAttach, savedInset
  if not ok then error(err, 0) end
end)
