-- tests/test_options_landing.lua — LibKa0s-Options-1.0's OptionsWidgets.lua: O.TextRow and
-- O.BuildLandingPage, the three-host BuildMainContent promotion.
--
-- Peeled out of tests/test_options_widgets.lua (issue #33) when what was left of that suite after
-- the id peel was split on its own case seams. The cases are moved unchanged; the bench is in
-- tests/fixture_widgets.lua.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local bench = dofile("tests/fixture_widgets.lua")("LandingBench").bench

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

test("widgets: TextRow left-justifies by default and honors an explicit justify", function()
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

test("widgets: BuildLandingPage honors an explicit logoSize", function()
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
