-- tests/test_options_tabs.lua — LibKa0s-Options-1.0's OptionsTabs.lua: the page's chrome.
--
-- The tab strip, the page banner, the host's own header block, the secondary strip, and the
-- geometry all four are laid out by. One suite per module (`testing-§1`), so this file peeled out
-- of tests/test_options_widgets.lua in the same commit as the module it mirrors and on the same
-- seam — which is the whole reason issue #8 waited for issue #16 rather than splitting by widget
-- family first: a suite that partitioned itself before the module did would have ended up paired
-- with nothing.
--
-- WHAT IS HERE. Every case whose subject is chrome. The cases under *the tabbed page* on the
-- four-argument `O.RenderTabbedSchema` stayed in tests/test_options_widgets.lua when it lived there;
-- it moved to OptionsTabs.lua at minor 4, and those cases are the move's characterization. Its
-- `opts` fields and the banner's `action` are pinned at the foot of this file.
--
-- WHAT MAKES THESE CASES POSSIBLE AT ALL is `instrument` below: the kit's frame stub no-ops
-- SetPoint and answers no atlas height, and a chrome whose corners nobody can read is a chrome
-- that shipped drawn on top of its own banner with every test passing. That happened. So the
-- frames are instrumented per case rather than widened for every suite in the repo.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local Fixture = dofile("tests/fixture_options.lua")
-- The INTERNAL LAYOUT keys (CHROME_DIVIDER_*, PANEL_*, CONTENT_*) have no O.* seam of their own --
-- by design, per the published/internal split at the top of Options.lua -- so a test that needs
-- their raw numbers reads them off the lib table directly, same as tests/test_options.lua does.
local lib = T.options

--- A host, a throwaway panel and a parent container. The same bench tests/test_options_widgets.lua
--- keeps, under its own panel name: two suites handing `CreatePanel` the same key would be two
--- suites sharing one registration.
local panelSeq = 0
local function bench(overrides)
  local O, rec = Fixture.new(overrides)
  panelSeq = panelSeq + 1
  local ctx = O.CreatePanel("TabBench" .. panelSeq, "Bench " .. panelSeq, {})
  return O, rec, ctx
end

--- Run `fn` with AceGUI absent, restoring it afterwards.
---
--- The instance resolves AceGUI ONCE, at New() time (`LibKa0s/Options.lua:217`), so the library
--- has to be built INSIDE this: flipping the mock after Fixture.new leaves the instance holding
--- the handle it already resolved, and the degraded path never runs.
local function withoutAceGUI(fn)
  local saved = T.mocks.__libs["AceGUI-3.0"]
  T.mocks.__libs["AceGUI-3.0"] = nil
  local ok, err = pcall(fn)
  T.mocks.__libs["AceGUI-3.0"] = saved
  if not ok then error(err) end
end

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
  -- red under: `y = -((r - 1) * rowPitch)`, which answers 0 for row 1 regardless of top.
  local O = Fixture.new()
  local placement, rowCount = O.__tabPlacement({ 60, 60, 60 }, 150, 4, 44, 28)
  assertEqual(rowCount, 2, "60+4+60 fits in 150; the third tab wraps, same as __layoutTabs")
  assertEqual(#placement, 3, "every tab placed")
  assertEqual(placement[1].y, -44, "row 1 sits at the bottom of the reserved band, not at 0")
  assertEqual(placement[2].y, -44, "row 1's second tab shares row 1's y")
  -- ONE PITCH, not a tab height plus a gap. The pitch is the tab ART's height, which is shorter
  -- than the button; packing by the button left the empty strip along each button's top standing
  -- between the two rows as a visible gap.
  assertEqual(placement[3].y, -(44 + 28), "row 2 sits exactly one pitch below row 1, flush to it")
end)

test("widgets: __tabPlacement accumulates x across a row", function()
  -- red under: resetting x to 0 for every tab instead of advancing past the previous one.
  local O = Fixture.new()
  local placement = O.__tabPlacement({ 60, 80 }, 1000, 4, 0, 24)
  assertEqual(placement[1].x, 0, "the first tab in a row starts at the row's left edge")
  assertEqual(placement[2].x, 64, "the second tab starts after the first tab's width plus the gap")
end)

test("widgets: __tabPlacement places every index exactly once", function()
  -- Mirrors the guarantee __layoutTabs already carries: losing an index here would lose a tab
  -- from the strip with nothing said about it.
  -- red under: dropping an over-wide tab, or emitting an index twice across two rows.
  local O = Fixture.new()
  local placement = O.__tabPlacement({ 60, 500, 60, 60, 60 }, 130, 4, 0, 24)
  local seen = {}
  for _, p in ipairs(placement) do
    assertEqual(seen[p.index], nil, "index " .. p.index .. " placed only once")
    seen[p.index] = true
  end
  for i = 1, 5 do assertTrue(seen[i], "index " .. i .. " was placed") end
end)

test("widgets: __bannerBand widens a real height by the gap/rule/gap, and a zero one not at all",
function()
  -- Pure arithmetic, deliberately: the widening is what feeds __tabPlacement's `top` (via
  -- ctx.__bannerHeight), so it has to be checkable without a live dropdown frame.
  -- red under: adding the gap/rule/gap unconditionally, which would push a tabs-only page's
  -- first row down for a banner that was never drawn.
  local O = Fixture.new()
  local L = lib.LAYOUT
  assertEqual(O.__bannerBand(44), 44 + L.CHROME_DIVIDER_GAP_TOP + L.CHROME_DIVIDER_H
    + L.CHROME_DIVIDER_GAP_BOTTOM)
  assertEqual(O.__bannerBand(0), 0, "no banner drawn, nothing to separate it from")
  assertEqual(O.__bannerBand(nil), 0)
end)

test("widgets: __tabBand reserves the wrapped rows at their pitch, plus one full tab", function()
  -- The band is where the content panel's top edge lands, so an over-reservation opens a gap
  -- between the tabs and the page and an under-reservation buries the first row of settings.
  --
  -- The shape is (n-1) PITCHES plus one full TAB, not n tabs: every row but the last contributes
  -- only its pitch, because the next row's button overlaps its empty top. The LAST row is the one
  -- that has to fit whole, since its bottom is the edge the panel starts at.
  -- red under: n * pitch (the panel eats into the last row of tabs) or n * tabH (a gap opens
  -- under a wrapped strip, which is what the old height-plus-gap form did).
  local O = Fixture.new()
  assertEqual(O.__tabBand(44, 2, 37, 28), 44 + 28 + 37, "one pitch for row 1, a whole tab for row 2")
  assertEqual(O.__tabBand(0, 0, 37, 28), 37,
    "a wrapless call is still treated as one row, same as __tabPlacement")
  assertEqual(O.__tabBand(0, 1, 37, 28), 37, "one row reserves exactly one tab, no pitch at all")
  assertEqual(O.__tabBand(0, 3, 24, 24), 72, "pitch == tabH degenerates to n rows")
end)

--- Run `fn` with every frame's CreateTexture, SetPoint and SetHitRectInsets instrumented, and hand
--- back one record per frame: the atlases it asked for, in order, plus its own anchors.
---
--- The kit's base frame answers CreateTexture with the FRAME ITSELF, so "which atlas" is
--- unanswerable off a plain bench -- and it is the whole of several cases below. Wrapping the
--- MOCKS' CreateFrame is the only seam: makeTab, drawContentPanel and the pitch probe build raw
--- frames and nothing is handed in to intercept. It has to be `T.mocks` rather than `_G`, because
--- a loaded chunk reads its globals through the loader's env, whose __index resolves against the
--- mocks table first -- so a _G assignment here would never be seen.
---
--- THE TWO ATLAS FAMILIES ANSWER DIFFERENT HEIGHTS, and that is the point. The client does not draw
--- `Options_Tab_Active_*` at the same height as `Options_Tab_*`, and a harness that answered one
--- number for every atlas could not fail the selection-invariance case below -- which is precisely
--- how that defect shipped green (anti-patterns #70). `activeHeight` defaults to `artHeight + 5`,
--- so a caller that names only one still gets two.
---
--- The measurement is RESET on the way in and on the way out. It is memoized for the life of a
--- session on purpose, so a cached 28 from this harness would follow every later case that never
--- asked to be measured at all.
local INACTIVE_ART, ACTIVE_ART = 28, 33

local function instrument(O, artHeight, activeHeight, fn)
  activeHeight = activeHeight or (artHeight and artHeight + 5)
  O.__resetTabArtHeight()

  local realCreateFrame = T.mocks.CreateFrame
  local buttons, frames = {}, {}
  T.mocks.CreateFrame = function(kind, ...)
    local f = realCreateFrame(kind, ...)
    local rec = { kind = kind, atlases = {}, points = {} }
    if kind == "Button" then buttons[#buttons + 1] = rec else frames[#frames + 1] = rec end
    -- The frame's OWN anchors, which the kit's base stub no-ops. The content panel's whole
    -- correctness is where its four corners land, so they have to be observable -- and so is every
    -- tab's y offset, which is what the selection-invariance case reads.
    function f:SetPoint(point, rel, relPoint, x, y)
      rec.points[point] = { rel = rel, relPoint = relPoint, x = x, y = y }
    end
    function f:SetHitRectInsets(l, r, t, b) rec.hit = { l, r, t, b } end
    function f:CreateTexture()
      local t, atlas = {}, nil
      function t:SetAtlas(name) atlas = name; rec.atlases[#rec.atlases + 1] = name end
      function t:GetHeight()
        if not artHeight then return nil end
        if atlas and atlas:find("Active", 1, true) then return activeHeight end
        return artHeight
      end
      function t:SetPoint() end
      function t:SetTexCoord() end
      function t:SetColorTexture() end
      function t:SetGradient() end
      return t
    end
    return f
  end
  local ok, err = pcall(fn)
  local pitch = O.__tabArtHeight()
  T.mocks.CreateFrame = realCreateFrame
  O.__resetTabArtHeight()
  if not ok then error(err) end
  return buttons, frames, pitch
end

--- The primary strip, instrumented.
local function tabAtlases(O, ctx, spec, artHeight, activeHeight)
  return instrument(O, artHeight, activeHeight, function() O.TabStrip(ctx, spec) end)
end

local function threeTabs(active)
  return {
    tabs = { { key = "a", label = "A" }, { key = "b", label = "B" } },
    value = active,
    onSelect = function() end,
  }
end

test("widgets: a tab is cut from the client's own tab atlases, active art on the selected one",
function()
  -- The strip is meant to read as client chrome, not as a row of drawn rectangles: three atlas
  -- slices per tab off the same state family, and the SELECTED tab off the Active family. Two
  -- earlier attempts got this wrong in a way no assertion caught -- flat color fills, then the
  -- retired Interface/OptionsFrame textures -- so the atlas names are pinned here directly.
  -- red under: one texture instead of three, mixed families on one tab, or the selected tab
  -- drawn from the same art as the rest and distinguished by color alone.
  local O, _, ctx = bench()
  local buttons = tabAtlases(O, ctx, threeTabs("b"))

  assertEqual(#buttons, 2, "one button per tab")
  for i, rec in ipairs(buttons) do
    assertEqual(#rec.atlases, 3, "tab " .. i .. " is three slices: two caps and a middle")
    local family = rec.atlases[1]:match("^Options_Tab_A?c?t?i?v?e?_?") or ""
    for _, a in ipairs(rec.atlases) do
      assertTrue(a:sub(1, #family) == family, "every slice off one family, got " .. a)
    end
  end

  assertTrue(buttons[1].atlases[1]:find("Active", 1, true) == nil,
    "the unselected tab is inactive art: " .. buttons[1].atlases[1])
  assertTrue(buttons[2].atlases[1]:find("Active", 1, true) ~= nil,
    "the selected tab is active art: " .. buttons[2].atlases[1])
end)

test("widgets: a tabbed page gets the client's content panel, drawn as two mirrored halves",
function()
  -- The panel's TOP EDGE is the tab/content separator (options-ui-§13). There is no hairline any
  -- more: the selected tab's foot lands on this and merges into it, which is what makes the strip
  -- read as attached to the page. Two halves, because the atlas has one good corner and the left
  -- one is a mirrored copy of it.
  -- red under: drawing the panel once and stretching a corner across the width, or -- the real
  -- regression risk -- drawing it on an UNTABBED page, which most consumers still have.
  local O, _, ctx = bench()
  local _, frames = tabAtlases(O, ctx, threeTabs("a"))

  local halves = 0
  for _, rec in ipairs(frames) do
    for _, a in ipairs(rec.atlases) do
      if a == "Options_InnerFrame" then halves = halves + 1 end
    end
  end
  assertEqual(halves, 2, "the content panel is two mirrored halves of one atlas")
end)

test("widgets: the content box is drawn WIDER than the content column it encloses", function()
  -- THE BUG at 12.11.3: the box was anchored on the content column's own edges, so AceGUI's
  -- always-shown scrollbar -- which sits OUTBOARD of CONTENT_RIGHT -- was painted on top of the
  -- right border, and the left-hand row labels butted against the left one. A box has to be
  -- outside everything it contains.
  -- red under: anchoring the panel flush to ctx.chrome, which is the content column exactly.
  local O, _, ctx = bench()
  local _, frames = tabAtlases(O, ctx, threeTabs("a"))

  local panel
  for _, rec in ipairs(frames) do
    for _, a in ipairs(rec.atlases) do
      if a == "Options_InnerFrame" then panel = rec end
    end
  end
  assertTrue(panel ~= nil, "the content panel frame was found")

  local L = lib.LAYOUT
  -- Negative x pushes the top-left corner LEFT of the chrome, positive pushes the top-right
  -- corner RIGHT of it. Both must be non-zero, or the box is on the content column.
  assertEqual(panel.points.TOPLEFT.x, -(L.CONTENT_LEFT - L.PANEL_LEFT))
  assertEqual(panel.points.TOPRIGHT.x, L.CONTENT_RIGHT - L.PANEL_RIGHT)
  assertTrue(panel.points.TOPLEFT.x < 0, "the box starts left of the first widget")
  assertTrue(panel.points.TOPRIGHT.x > 0, "and ends right of the scrollbar")
  assertTrue(L.PANEL_BOTTOM < L.CONTENT_BOTTOM, "and below the last widget")
end)

test("widgets: wrapped rows are packed by the ART's height, so they sit flush", function()
  -- The tab BUTTON is taller than the atlas it carries -- the extra height is the foot that
  -- overlaps the content panel -- so packing rows by the button height leaves that empty strip
  -- standing between two rows as a visible gap. Reported from a client on a six-tab page.
  -- red under: a pitch of TAB_H, or of TAB_H plus any gap at all.
  local O, _, ctx = bench()
  local tabs = {}
  for i = 1, 4 do tabs[i] = { key = "k" .. i, label = "Tab " .. i } end
  -- The harness's chrome answers 0 from GetWidth, so all four tabs wrap onto their own rows.
  tabAtlases(O, ctx, { tabs = tabs, value = "k1", onSelect = function() end }, 28)

  -- Three rows contribute a pitch each; the LAST contributes a whole tab, because its bottom is
  -- the edge the content panel starts at.
  assertEqual(ctx.chromeHeight, (3 * 28) + O.TAB_H)
  assertTrue(ctx.chromeHeight < 4 * O.TAB_H, "flush rows are shorter than four stacked buttons")
end)

test("widgets: a strip laid out before the canvas has a width re-wraps when the width arrives",
function()
  -- THE BUG: ctx.chrome has zero width until the settings canvas lays itself out, and the FIRST
  -- page a player opens renders before that. placeTabs read 0, fell back to TAB_MIN_W, and every
  -- tab wrapped onto its own row -- a vertical stack that healed the moment you clicked any tab,
  -- because the second render measured a real width. Reported from a client against the General
  -- page; O.EnsureDefaultsButton already carries a note about ctx.body having zero width at
  -- enable time, which is the same client behavior reaching a second piece of chrome.
  -- red under: placing once and never again, which is what shipped.
  local O, _, ctx = bench()
  local tabs = {}
  for i = 1, 4 do tabs[i] = { key = "k" .. i, label = "Tab " .. i } end
  O.TabStrip(ctx, { tabs = tabs, value = "k1", onSelect = function() end })

  -- The harness's chrome answers 0 from GetWidth, so this is the broken first render exactly.
  local stacked = ctx.chromeHeight
  assertTrue(stacked >= 4 * O.TAB_H, "four tabs stacked onto four rows: " .. tostring(stacked))

  ctx.chrome:__fire("OnSizeChanged", 900)
  assertEqual(ctx.chromeHeight, O.TAB_H, "a real width collapsed them onto one row")

  -- Idempotent, and specifically immune to the height change SetChromeHeight itself causes --
  -- which fires this very script. Re-firing at the same width must not re-place anything.
  ctx.chrome:__fire("OnSizeChanged", 900)
  assertEqual(ctx.chromeHeight, O.TAB_H, "the same width again is a no-op, not a second pass")
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
  -- The band includes the strip's own baseline (options-ui-§13), not just the row(s) of tabs --
  -- floored rather than pinned exact, because the harness's zero-width chrome wraps these three
  -- tabs onto more than one row (exercised precisely by O.__tabBand's own tests above).
  assertTrue(ctx.chromeHeight >= O.TAB_H,
    "the strip reserved its own row(s)")

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
  -- The 2 buttons plus the strip's own baseline texture (options-ui-§13), which travels in the
  -- same ledger so a re-render cannot leave the old one floating over the new strip.
  assertEqual(#ctx.__tabKids, 3, "the first strip's furniture was released, not orphaned")
end)

test("widgets: re-selecting the same tabs builds no second set of frames", function()
  -- The strip is torn down and redrawn on EVERY tab click, and WoW never destroys a frame. A
  -- strip that CREATES its buttons and its content panel each time therefore leaks one full set
  -- per click for as long as the player leaves the panel open, and the release that was supposed
  -- to cover it only hid and unparented -- which is an allocator wearing a pool's name, the exact
  -- shape LibKa0s-Pool-1.0 was extracted to end. Nothing about it is visible from outside: the
  -- panel draws correctly, every case below this one stays green, and the only symptom is a
  -- client that gets heavier the longer settings is open.
  --
  -- Counted through the MOCKS' CreateFrame for the same reason `instrument` above wraps it there:
  -- a loaded chunk reads its globals through the loader's env, which resolves against the mocks
  -- table first, so a _G assignment would never be seen.
  -- red under: minor 13, where TabStrip calls makeTab and drawContentPanel per render.
  local O, _, ctx = bench()
  local tabs = {
    { key = "one",   label = "One" },
    { key = "two",   label = "Two" },
    { key = "three", label = "Three", tooltip = "The third one" },
  }
  local function select(key)
    O.TabStrip(ctx, { tabs = tabs, value = key, onSelect = function() end })
  end

  -- The first pass is deliberately UNCOUNTED. The claim is not that a strip never allocates --
  -- it has to, once -- but that the second click over the same three tabs allocates nothing.
  for _, key in ipairs({ "one", "two", "three" }) do select(key) end

  local created, realCreateFrame = 0, T.mocks.CreateFrame
  T.mocks.CreateFrame = function(...)
    created = created + 1
    return realCreateFrame(...)
  end
  local ok, err = pcall(function()
    for _, key in ipairs({ "one", "two", "three" }) do select(key) end
  end)
  T.mocks.CreateFrame = realCreateFrame
  if not ok then error(err) end

  assertEqual(created, 0, "a second pass over the same tabs built frames instead of reusing them")
  assertEqual(#ctx.__tabKids, 4, "three tabs and one content panel, not a growing pile")
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
  -- The recorded band is the WIDENED one -- the raw dropdown height plus the gap/rule/gap that
  -- separate the banner from whatever is drawn under it (options-ui-§14) -- not the raw height
  -- itself.
  assertEqual(ctx.__bannerHeight, O.__bannerBand(O.BANNER_H))
  assertTrue(ctx.chromeHeight >= O.BANNER_H)

  dd:__fire("OnValueChanged", 1)
  assertEqual(#chosen, 1)
  assertEqual(chosen[1], 1)
end)

test("widgets: banner then strip reserve ONE band between them, not two", function()
  -- The two are drawn in that order by every page that has both, and the band has to hold both --
  -- the banner's own row, the gap/rule/gap under it, the tab row, and the strip's own baseline.
  -- A strip that reserved only its own rows would slide up under the banner.
  -- red under: SetChromeHeight overwriting rather than accumulating the banner's share, or the
  -- gap/rule/gap/baseline block going missing from the total.
  local O, _, ctx = bench()
  O.PageBanner(ctx, { label = "W", list = { [1] = "One" }, order = { 1 }, value = 1,
                      onSelect = function() end })
  O.TabStrip(ctx, { tabs = { { key = "a", label = "A" } }, value = "a",
                    onSelect = function() end })
  local bannerBand = O.__bannerBand(O.BANNER_H)
  local reserved = O.__tabBand(bannerBand, 1, O.TAB_H, O.TAB_H)
  assertEqual(ctx.chromeHeight, reserved)
  assertTrue(ctx.chromeHeight > O.BANNER_H + O.TAB_H,
    "the gap and the rule widened the band beyond the bare banner + tab row")
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

  local placement = O.__tabPlacement({ 60 }, 200, 0, ctx.__bannerHeight, O.TAB_H)
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
  -- 2 buttons plus the strip's own baseline (options-ui-§13), and no more: the ledger is reset
  -- every render rather than appended to.
  assertEqual(#ctx.__tabKids, 3, "the strip still tracks its own furniture, not a growing pile")
end)


-- ── the strip's geometry is invariant under the selection (R4c) ────────────────────────────

test("widgets: a wrapped strip's geometry is IDENTICAL for every value of the selection",
function()
  -- THE BUG. The selected tab is cut from `Options_Tab_Active_*` and the rest from
  -- `Options_Tab_*`, and the client does not draw the two families at the same height. TabStrip
  -- recorded the pitch from the FIRST tab it built, whichever that happened to be -- so on a page
  -- whose strip WRAPS, selecting tab 1 packed the rows by the active art and selecting any other
  -- packed them by the inactive art. The band feeds SetChromeHeight, which re-anchors the scroll
  -- AND the content panel, so the whole page below the strip moved and resized when the player
  -- clicked one particular tab. Reported from a client against ConsumableMaster's Macros page
  -- (three wrapped rows, the gap on one tab alone) and again on its Macro Bar page.
  --
  -- It is invisible on an UNWRAPPED strip, because the pitch is multiplied by (rowCount - 1) = 0.
  -- This case therefore forces a wrap: the harness's chrome answers 0 from GetWidth, so every tab
  -- takes TAB_MIN_W and lands on its own row.
  --
  -- red under: restore `ctx.__tabArtH = ctx.__tabArtH or artH` and seed the pitch from whichever
  -- tab was drawn first.
  local tabs = {}
  for i = 1, 8 do tabs[i] = { key = "k" .. i, label = "Tab " .. i } end

  local function geometry(active)
    local O, _, ctx = bench()
    local buttons = tabAtlases(O, ctx,
      { tabs = tabs, value = active, onSelect = function() end }, INACTIVE_ART, ACTIVE_ART)
    local ys = {}
    for i, rec in ipairs(buttons) do ys[i] = rec.points.TOPLEFT.y end
    return ctx.chromeHeight, table.concat(ys, ",")
  end

  local firstBand, firstYs  = geometry("k1")
  local secondBand, secondYs = geometry("k2")

  assertEqual(firstBand, secondBand, "the reserved band moved with the selection")
  assertEqual(firstYs, secondYs, "a tab's row offset moved with the selection")

  -- And it is the INACTIVE art the rows are packed by, not the active one and not a mix: 8 rows
  -- means 7 pitches plus one whole tab.
  local O = Fixture.new()
  assertEqual(firstBand, O.__tabBand(0, 8, O.TAB_H, INACTIVE_ART),
    "the pitch was not the unselected tab art's own height")
end)

test("widgets: every tab's hit rect is inset by the same number the rows are packed by",
function()
  -- The empty strip along a button's top is not part of the tab and must not be clickable: row 2's
  -- button overlaps row 1's art by exactly the pitch, so without the inset it swallows clicks meant
  -- for row 1. Taken off each tab's OWN art the number was the inactive height on every unselected
  -- tab and the active height on the selected one -- so the invariant the code's own comment states
  -- held for all but one button per strip.
  -- red under: `if artH and ...` off drawTabSlices' return, which is where it was read from.
  local O, _, ctx = bench()
  local tabs = {}
  for i = 1, 3 do tabs[i] = { key = "k" .. i, label = "Tab " .. i } end
  local buttons = tabAtlases(O, ctx,
    { tabs = tabs, value = "k2", onSelect = function() end }, INACTIVE_ART, ACTIVE_ART)

  for i, rec in ipairs(buttons) do
    assertTrue(rec.hit ~= nil, "tab " .. i .. " never set a hit rect")
    assertEqual(rec.hit[3], O.TAB_H - INACTIVE_ART,
      "tab " .. i .. " was inset by its own art rather than by the strip's pitch")
  end
end)

test("widgets: the pitch is measured once, off the INACTIVE family, and cached on success only",
function()
  -- Cached on success only is what lets a client that has not resolved the atlas yet answer for
  -- real on the next read, instead of pinning the fallback for the session.
  -- red under: caching the fallback, or measuring off TAB_ATLAS[true].
  local O = Fixture.new()
  O.__resetTabArtHeight()
  assertEqual(O.__tabArtHeight(), O.TAB_H,
    "nothing measurable falls back to the button height, which is the pre-measurement behavior")
  assertEqual(O.__tabArtHeight(), O.TAB_H, "and the miss was not cached as the answer")

  local _, _, pitch = instrument(O, INACTIVE_ART, ACTIVE_ART, function()
    O.__tabArtHeight()
  end)
  assertEqual(pitch, INACTIVE_ART, "measured off the active family, or not measured at all")
end)

-- ── the chrome block above the strip (options-ui-§14) ──────────────────────────────────────

test("widgets: PageHeader reserves the band, and the strip lands beneath it", function()
  -- Controls that apply to every tab sit ABOVE the strip: drawn under one tab they read as
  -- belonging to it, and they vanish the moment the player clicks another. O.PageBanner draws
  -- exactly one Dropdown, so what is generalised here is the BAND, not the banner.
  -- red under: reserving the raw height rather than O.__bannerBand's widened one, which lands the
  -- first tab on top of the block's own bottom edge.
  local O, _, ctx = bench()
  local built = {}
  local frame = O.PageHeader(ctx, {
    height = 60,
    build  = function(_, f) built[#built + 1] = f end,
  })

  assertTrue(frame ~= nil, "the block drew nothing")
  assertEqual(built[1], frame, "the host was handed the frame it is to draw into")
  assertEqual(ctx.__bannerHeight, O.__bannerBand(60))
  assertEqual(ctx.chromeHeight, O.__bannerBand(60))

  O.TabStrip(ctx, { tabs = { { key = "a", label = "A" } }, value = "a", onSelect = function() end })
  local placement = O.__tabPlacement({ 60 }, 200, 0, ctx.__bannerHeight, O.TAB_H)
  assertEqual(placement[1].y, -O.__bannerBand(60),
    "the strip's first row must start at the bottom of the block's band, never above it")
end)

test("widgets: a page draws at most ONE chrome block -- the second replaces the first", function()
  -- Two blocks are two bands, and the second pushes the page down for nothing. A page that needs a
  -- picker AND other page-wide controls puts the picker inside the block.
  -- red under: PageHeader appending to __chromeKids without releasing it first.
  local O, _, ctx = bench()
  local first = O.PageHeader(ctx, { height = 60, build = function() end })
  local afterHeader = #ctx.__chromeKids
  assertEqual(afterHeader, 2, "one block plus its hairline rule, and nothing else")

  -- Its own re-render first: a page redraws its header on every subject change, and a block left
  -- parented to the chrome would stack with the older one on top.
  -- Since minor 4 the second render is handed the SAME frame back (from the page's pool of one),
  -- so "replaces" means reused, not a second frame over the first.
  local second = O.PageHeader(ctx, { height = 60, build = function() end })
  assertEqual(#ctx.__chromeKids, afterHeader, "a second header stacked on the first")
  assertTrue(second == first, "a second block frame was drawn over the first")

  O.PageBanner(ctx, { label = "W", list = { [1] = "One" }, order = { 1 }, value = 1,
                      onSelect = function() end })
  assertEqual(#ctx.__chromeKids, afterHeader, "the two kinds of block stacked instead of replacing")
end)

test("widgets: PageHeader without a divider draws the block and no rule", function()
  -- red under: reading `spec.divider` truthily, which makes an omitted field mean OFF.
  local O, _, ctx = bench()
  O.PageHeader(ctx, { height = 60, divider = false, build = function() end })
  assertEqual(#ctx.__chromeKids, 1, "the rule was drawn anyway")
end)

test("widgets: a raising PageHeader builder costs the block, not the page", function()
  -- The builder reaches into live addon state, and a raise inside the render pass would take the
  -- strip and everything under it with it.
  -- red under: calling spec.build bare.
  local O, rec, ctx = bench()
  local frame = O.PageHeader(ctx, { height = 60, build = function() error("host blew up") end })
  assertTrue(frame ~= nil, "the block itself must survive its builder")
  local said = 0
  for _, line in ipairs(rec.chat) do
    if line:find("page header failed", 1, true) then said = said + 1 end
  end
  assertEqual(said, 1)
end)

test("widgets: PageHeader refuses politely with no spec and with no height", function()
  -- red under: reserving a zero band, which hides the chrome frame and moves the scroll for
  -- nothing.
  local O, _, ctx = bench()
  assertNil(O.PageHeader(ctx, nil))
  assertNil(O.PageHeader(ctx, { build = function() end }))
  assertNil(O.PageHeader(ctx, { height = 0, build = function() end }))
  assertNil(O.PageHeader(nil, { height = 60 }))
  assertEqual(ctx.chromeHeight, 0, "a refusal must reserve nothing")
end)

-- ── a full page render holds no more than it drew (minor 4) ─────────────────────────────────
--
-- Review finding LibKa0s-R-02. Until minor 4 every full render of a banner or header page minted a
-- fresh Dropdown or raw Frame plus a divider texture, and the release only hid them: the client
-- never destroys a frame, and AceGUI recycles a widget only when it is Released. The kit's AceGUI
-- fake never reuses a widget either, so no count below could be read until kit revision 26's
-- `M.__aceguiLive`.

--- A texture double for ctx.chrome's CreateTexture: the kit's answers the frame itself, which
--- cannot tell one texture from another or say whether one was unparented.
local function countTextures(ctx)
  local made = {}
  ctx.chrome.CreateTexture = function()
    local tex = { shown = true, parentCalls = 0 }
    function tex.SetColorTexture() end
    function tex.SetPoint() end
    function tex.ClearAllPoints() end
    function tex.SetHeight() end
    function tex.Show(t) t.shown = true end
    function tex.Hide(t) t.shown = false end
    function tex.IsShown(t) return t.shown end
    function tex.SetParent(t) t.parentCalls = t.parentCalls + 1 end
    made[#made + 1] = tex
    return tex
  end
  return made
end

local BANNER = { label = "W", list = { [1] = "One", [2] = "Two" }, order = { 1, 2 }, value = 1,
                 onSelect = function() end }

test("widgets: two full renders of a banner page leave ONE Dropdown out, not two", function()
  -- red under: PageBanner creating a Dropdown per render and releasing only its frame.
  local O, _, ctx = bench()
  local before = T.mocks.__aceguiLive("Dropdown")
  local first = O.PageBanner(ctx, BANNER)
  local second = O.PageBanner(ctx, BANNER)
  assertEqual(T.mocks.__aceguiLive("Dropdown") - before, 1, "the first render's picker was never Released")
  assertTrue(first ~= second, "the new picker is created before the old one is given back")
  assertTrue(first.__released, "the first render's picker went back to AceGUI")
  assertFalse(second.__released == true, "and the picker on screen did not")
end)

test("widgets: a header page after a banner page gives the banner's Dropdown back", function()
  -- The two blocks share one band, so moving from one to the other has to release the other's
  -- furniture too, not only its own.
  -- red under: releasing the banner widget only from PageBanner.
  local O, _, ctx = bench()
  local before = T.mocks.__aceguiLive("Dropdown")
  local dd = O.PageBanner(ctx, BANNER)
  O.PageHeader(ctx, { height = 60, build = function() end })
  assertEqual(T.mocks.__aceguiLive("Dropdown") - before, 0, "the banner's picker outlived its band")
  assertTrue(dd.__released, "released, not only hidden")
end)

test("widgets: PageBanner's re-render from inside its own onSelect never hands itself back", function()
  -- A banner's selection is a change of subject, and a host re-renders the page from inside the
  -- dropdown's own callback. Released before the new one is created, the old widget is the one
  -- AceGUI's pool hands straight back, re-initialized while its callback is still running.
  -- red under: releasing the old picker at the top of the render instead of after the Create.
  local O, _, ctx = bench()
  local seen
  local spec = { label = "W", list = { [1] = "One", [2] = "Two" }, order = { 1, 2 }, value = 1 }
  spec.onSelect = function() seen = O.PageBanner(ctx, spec) end
  local before = T.mocks.__aceguiLive("Dropdown")
  local first = O.PageBanner(ctx, spec)
  -- The kit's fake never reuses a widget, so the order is read at the moment of the Release: with
  -- the new picker already created there are two out, and with it not yet created only one.
  local outAtRelease
  function first.OnRelease() outAtRelease = T.mocks.__aceguiLive("Dropdown") - before end
  first:__fire("OnValueChanged", 2)
  assertTrue(seen ~= nil and seen ~= first, "the re-render drew a fresh picker")
  assertTrue(first.__released, "the old picker went back to AceGUI")
  assertEqual(outAtRelease, 2, "the old picker was released before its replacement existed")
  assertEqual(T.mocks.__aceguiLive("Dropdown") - before, 1)
end)

test("widgets: PageHeader hands the SAME frame back on every render of one page", function()
  -- red under: CreateFrame per call, which is one raw Frame per render for the life of the session.
  local O, _, ctx = bench()
  local first = O.PageHeader(ctx, { height = 60, build = function() end })
  local second = O.PageHeader(ctx, { height = 44, build = function() end })
  assertTrue(first == second, "a second frame was built for the same page")
  assertTrue(second:IsShown(), "and the reused frame is on screen")

  O.PageBanner(ctx, BANNER)
  assertFalse(first:IsShown(), "a banner took the band and left the header frame showing")
  local third = O.PageHeader(ctx, { height = 60, build = function() end })
  assertTrue(third == first, "back from a banner, the page's frame is still the one handed out")
end)

test("widgets: the divider texture is made once per page and hidden, never unparented", function()
  -- SetParent(nil) on a Region is not a call the client promises to honor, and a texture per
  -- render is a leak the release could only hide.
  -- red under: drawChromeDivider calling CreateTexture per render, or releaseChrome unparenting it.
  local O, _, ctx = bench()
  local made = countTextures(ctx)
  O.PageHeader(ctx, { height = 60, build = function() end })
  O.PageHeader(ctx, { height = 60, build = function() end })
  O.PageBanner(ctx, BANNER)
  assertEqual(#made, 1, "one rule per page, whatever draws above it")
  assertTrue(made[1].shown, "the rule is on screen under the block")

  O.PageHeader(ctx, { height = 60, divider = false, build = function() end })
  assertFalse(made[1].shown, "a block drawn without a divider left the last one showing")
  assertEqual(made[1].parentCalls, 0, "a Region was unparented")
end)

-- ── the secondary strip (options-ui-§13) ───────────────────────────────────────────────────

test("widgets: SubTabStrip draws inside the host's frame and reports the height it took",
function()
  -- The primary strip is pinned in the chrome band; a secondary one belongs to the content it
  -- divides and scrolls with it. Pinning a second band would double the chrome and push the page
  -- down twice.
  -- red under: parenting to ctx.chrome, or calling SetChromeHeight, either of which moves the page.
  local O, _, ctx = bench()
  local parent = T.mocks.CreateFrame("Frame", nil, T.mocks.UIParent)
  local tabs = {}
  for i = 1, 5 do tabs[i] = { key = "s" .. i, label = "String " .. i } end

  local picked = {}
  local buttons, height = O.SubTabStrip(ctx, parent, {
    tabs = tabs, value = "s2", onSelect = function(key) picked[#picked + 1] = key end,
  })

  assertEqual(#buttons, 5)
  assertEqual(ctx.chromeHeight, 0, "a secondary strip must not reserve a pinned band")
  assertEqual(#ctx.__subTabKids, 5, "its own ledger, so drawing the strip leaves the primary's alone")
  assertEqual(#(ctx.__tabKids or {}), 0, "and it must never leak into the primary strip's ledger")
  -- The harness's parent answers 0 from GetWidth, so all five wrap onto their own rows: four
  -- pitches plus one whole tab.
  assertEqual(height, O.__tabBand(0, 5, O.TAB_H, O.TAB_H))

  assertFalse(buttons[2]:IsEnabled(), "the active sub tab is the disabled one, same as the primary")
  buttons[4]:__fire("OnClick")
  assertEqual(#picked, 1)
  assertEqual(picked[1], "s4")
end)

test("widgets: a second SubTabStrip call releases the first rather than stacking on it", function()
  -- A secondary strip is redrawn whenever its category is. Buttons left parented to the host's
  -- frame would stack, with the older set on top swallowing the clicks -- the same failure the
  -- primary strip's ledger exists to prevent.
  -- red under: appending to __subTabKids without releasing it.
  local O, _, ctx = bench()
  local parent = T.mocks.CreateFrame("Frame", nil, T.mocks.UIParent)
  local spec = {
    tabs = { { key = "a", label = "A" }, { key = "b", label = "B" } },
    value = "a", onSelect = function() end,
  }
  local first = O.SubTabStrip(ctx, parent, spec)
  for _ = 1, 4 do O.SubTabStrip(ctx, parent, spec) end
  assertEqual(#ctx.__subTabKids, 2, "the ledger grew across re-renders")
  assertFalse(first[1]:IsShown(), "the first strip's buttons were left on the host's frame")
end)

test("widgets: ClearScroll drains the sub-tab ledger before AceGUI pools the parent", function()
  -- SubTabStrip drains its own ledger ON ENTRY, which covers redrawing a strip. It cannot cover the
  -- case where the page moves to a tab that draws NO secondary strip: SubTabStrip never runs, so
  -- nothing drains, and ClearScroll's ReleaseChildren hands the buttons' parent back to AceGUI's
  -- pool with them still shown on it. The next page to take that pooled frame inherits them.
  -- red under: dropping the `O.__releaseSubTabs(ctx)` call at the top of O.ClearScroll.
  local O, _, ctx = bench()
  local parent = T.mocks.CreateFrame("Frame", nil, T.mocks.UIParent)
  local buttons = O.SubTabStrip(ctx, parent, {
    tabs = { { key = "a", label = "A" }, { key = "b", label = "B" } },
    value = "a", onSelect = function() end,
  })
  assertEqual(#ctx.__subTabKids, 2)

  -- The page re-renders onto a tab with no secondary strip: ClearScroll, and no SubTabStrip call.
  O.ClearScroll(ctx)

  assertEqual(#ctx.__subTabKids, 0, "the ledger survived the render that released its parent")
  assertFalse(buttons[1]:IsShown(), "a sub tab button outlived the render that drew it")
  assertFalse(buttons[2]:IsShown(), "a sub tab button outlived the render that drew it")
end)

test("widgets: a wrapped SUB strip's geometry is invariant under the selected sub tab", function()
  -- The same rule as the primary strip, over the new function: it packs by the same measured pitch
  -- and must not read anything back off a tab that was drawn in whichever state it happened to be.
  -- red under: measuring the pitch inside SubTabStrip off its own first button.
  local tabs = {}
  for i = 1, 6 do tabs[i] = { key = "s" .. i, label = "String " .. i } end

  local function geometry(active)
    local O, _, ctx = bench()
    local parent = T.mocks.CreateFrame("Frame", nil, T.mocks.UIParent)
    local height
    local buttons = instrument(O, INACTIVE_ART, ACTIVE_ART, function()
      _, height = O.SubTabStrip(ctx, parent, {
        tabs = tabs, value = active, onSelect = function() end,
      })
    end)
    local ys = {}
    for i, rec in ipairs(buttons) do ys[i] = rec.points.TOPLEFT.y end
    return height, table.concat(ys, ",")
  end

  local firstHeight, firstYs   = geometry("s1")
  local secondHeight, secondYs = geometry("s3")
  assertEqual(firstHeight, secondHeight, "the reported height moved with the selection")
  assertEqual(firstYs, secondYs, "a sub tab's row offset moved with the selection")
end)

test("widgets: SubTabStrip refuses politely with no AceGUI, no parent and no tabs", function()
  -- red under: indexing spec.tabs before checking it.
  withoutAceGUI(function()
    local O, _, ctx = bench()
    local parent = T.mocks.CreateFrame("Frame", nil, T.mocks.UIParent)
    assertNil(O.SubTabStrip(ctx, parent, { tabs = { { key = "a", label = "A" } } }))
  end)

  local O2, _, ctx2 = bench()
  local parent2 = T.mocks.CreateFrame("Frame", nil, T.mocks.UIParent)
  assertNil(O2.SubTabStrip(ctx2, parent2, { tabs = {} }))
  assertNil(O2.SubTabStrip(ctx2, parent2, nil))
  assertNil(O2.SubTabStrip(ctx2, nil, { tabs = { { key = "a", label = "A" } } }))
end)

-- ── the tabbed page: host tabs, the disabled notice and the chrome hook (T4) ─────────────────
--
-- `O.RenderTabbedSchema` moved here from OptionsWidgets.lua at T4 and took an optional fifth
-- argument, so a host with bespoke (non-row) tabs, a page drawn disabled or a line above every tab
-- stops forking the whole render (AuraMaster-R-04: AuraMaster's seven pages, and the same strip
-- hand-built in four more hosts). The cases on the signature every host already calls are still in
-- tests/test_options_widgets.lua and pass unchanged; these pin the new fields.

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
  for _, pred in ipairs({ function() return false end, function() error("predicate bug") end }) do
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
