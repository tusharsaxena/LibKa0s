-- tests/test_feed_style.lua -- LibKa0s-Feed-1.0's rows over the owner's skin (FeedRow.lua).
--
-- The skinned path runs on the real Skin major (tests/fixture_feed.lua's `skinned` bench): the fill
-- through S.Shell and its keepEdge override, the border's style and color order, every string
-- through S.HudFont, the text color order, the icon's crop and edge, the glow's color and blend,
-- and a skin switch repainting live rows. The degraded path (no Skin, an unregistered owner, no
-- Core facade) draws the plain look without a raise. The container's layering is here too.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local F = dofile("tests/fixture_feed.lua")

local OWNER = "FeedHost"

--- Content that copies the payload into the spec: plain fields as given, `lines` into the spec's own
--- three line tables.
local function copyContent(spec, payload)
  for k, v in pairs(payload) do
    if k == "lines" then
      for i, part in ipairs(v) do
        for pk, pv in pairs(part) do spec.lines[i][pk] = pv end
      end
    else
      spec[k] = v
    end
  end
end

--- A feed on the skinned bench, its owner registered (unless `unregistered`). Answers the feed,
--- the environment, the Skin major and the owner's facade.
local function skinned(d, unregistered)
  d = d or {}
  d.owner = d.owner or OWNER
  d.content = d.content or copyContent
  d.motion = d.motion or { smooth = false }
  local feed, m = F.feed(d, { skinned = true })
  local Skin = m.LibStub("LibKa0s-Skin-1.0")
  local S = nil
  if not unregistered then S = Skin:RegisterOwner(d.owner) or Skin:For(d.owner) end
  return feed, m, Skin, S
end

--- The row frame on screen nearest the anchor.
local function row(feed) return F.rows(feed)[1] end

--- The row's regions of `kind` in `layer` (and `sublevel` when given).
local function regions(frame, kind, layer, sublevel)
  local out = {}
  for _, r in ipairs({ frame:GetRegions() }) do
    if r:GetObjectType() == kind and (layer == nil or select(1, r:GetDrawLayer()) == layer)
      and (sublevel == nil or select(2, r:GetDrawLayer()) == sublevel) then
      out[#out + 1] = r
    end
  end
  return out
end

local function rgba(c) return ("%.2f,%.2f,%.2f,%.2f"):format(c[1], c[2], c[3], c[4] or 1) end

--- The row's own fill (BACKGROUND, sublevel -6).
local function fill(frame) return regions(frame, "Texture", "BACKGROUND", -6)[1] end

--- The row's edges (BORDER).
local function edgeColor(frame)
  local e = regions(frame, "Texture", "BORDER")[1]
  return e.__color and rgba(e.__color), e
end

--- The row's title string: the one whose text is `title`.
local function stringTitled(frame, title)
  for _, fs in ipairs(regions(frame, "FontString")) do
    if fs:GetText() == title then return fs end
  end
  return nil
end

--- Wrap facade member `name` with a recorder; answers the call list.
local function spy(S, name)
  local calls, fn = {}, S[name]
  S[name] = function(...)
    local call = { n = select("#", ...), ... }
    for i = 1, call.n do   -- a shallow copy of each table argument: a caller may reuse its opts
      if type(call[i]) == "table" and not call[i].GetObjectType then
        local copy = {}
        for k, v in pairs(call[i]) do copy[k] = v end
        call[i] = copy
      end
    end
    calls[#calls + 1] = call
    return fn(...)
  end
  return calls
end

-- == the container's layering =================================================================

test("feed style: the container is HIGH, not toplevel, clamped and mouse-off; rows sit above it", function()
  local feed = F.feed()
  feed:Push("a", { title = "A" })
  local c = feed:Frame()
  assertEqual(c.__strata, "HIGH")
  assertFalse(c.__toplevel, "never raised over a window the player clicks")
  assertTrue(c.__clamped)
  assertFalse(c.__mouse, "the container takes no mouse itself")
  local r = row(feed)
  assertTrue(r.__parent == c, "a row is the container's child")
  assertEqual(r:GetFrameLevel(), c:GetFrameLevel() + 1, "the first row's band starts one over the container")
  assertTrue(r.__mouse, "rows take the mouse unless click-through")
  local glow
  for _, child in ipairs({ r:GetChildren() }) do
    for _, t in ipairs({ child:GetRegions() }) do
      if t.GetBlendMode and t:GetBlendMode() == "ADD" then glow = child end
    end
  end
  assertTrue(glow ~= nil, "the glow holder is a child of the row")
  assertEqual(glow:GetFrameLevel(), r:GetFrameLevel() + 5, "at the top of the row's band")
end)

--- Every level a row's band holds: the row's own and each descendant frame's.
local function bandOf(r)
  local out = { r:GetFrameLevel() }
  local function walk(f)
    for _, child in ipairs({ f:GetChildren() }) do
      out[#out + 1] = child:GetFrameLevel()
      walk(child)
    end
  end
  walk(r)
  table.sort(out)
  return out
end

test("feed style: overlapping rows and peer feeds sit in distinct level bands (frame-layering-§3)", function()
  local feed, m, _, Feed = F.feed({ content = copyContent, motion = { smooth = false } })
  feed:Push("a", { title = "A", icon = 1 })
  feed:Push("b", { title = "B", icon = 1, highlight = true })
  local ra, rb = F.row(feed, "A"), F.row(feed, "B")
  local A, B = bandOf(ra), bandOf(rb)
  assertTrue(A[#A] < B[1] or B[#B] < A[1], "the two rows' bands do not overlap")
  for _, band in ipairs({ A, B }) do
    for i = 2, #band do assertTrue(band[i] > band[i - 1], "each frame of a row has a level of its own") end
  end
  -- A row dropped by Dismiss fades where it stood while the other slides into its place: its band
  -- is still its own.
  assertTrue(feed:Dismiss("b"))
  assertEqual(bandOf(rb)[1], B[1], "a dropping row keeps its band")
  local second = Feed:New({ content = copyContent })
  second:Push("x", { title = "X" })
  local c1, c2 = feed:Frame():GetFrameLevel(), second:Frame():GetFrameLevel()
  assertTrue(c2 - c1 >= 121, "the next feed's base clears the first feed's whole band")
  assertEqual(#m.__errors, 0)
end)

-- == the fill =================================================================================

test("feed style: from the skin the fill is S.Shell with noTopBar and noBands, recorded", function()
  local feed, _, Skin = skinned()
  feed:Push("a", { title = "A" })
  local r = row(feed)
  local rec = Skin.painted[r]
  assertTrue(rec ~= nil and rec.calls.Shell ~= nil, "the row is a Shell, recorded for a skin switch")
  local opts = rec.calls.Shell[1]
  assertTrue(opts.noTopBar, "no title band on a row")
  assertTrue(opts.noBands)
  assertNil(opts.keepEdge, "the skin's own fill")
  assertFalse(fill(r):IsShown(), "the row's own fill stays hidden")
  assertTrue(rec.regions.fill ~= nil and rec.regions.fill:IsShown(), "the skin's fill shows")
end)

test("feed style: each bgType override draws the row's own fill over a keepEdge Shell record", function()
  local lsm = { ["background:Marble"] = "path\\marble" }
  local cases = {
    { style = { bgColorFromSkin = false, bgType = "solid", bgColor = { 0.1, 0.2, 0.3, 0.4 } },
      check = function(t) assertEqual(rgba(t.__color), "0.10,0.20,0.30,0.40", "solid") end },
    { style = { bgColorFromSkin = false, bgType = "none" },
      check = function(t) assertFalse(t:IsShown(), "none") end },
    { style = { bgColorFromSkin = false, bgType = "gradient", bgColor = { 1, 0, 0, 1 }, bgColor2 = { 0, 0, 1, 1 } },
      check = function(t)
        assertEqual(t.__gradient.orientation, "HORIZONTAL", "gradient")
        assertEqual(t.__gradient.min.r, 1); assertEqual(t.__gradient.max.b, 1)
      end },
    { style = { bgColorFromSkin = false, bgType = "texture", bgTexture = "Marble", bgColor = { 1, 1, 1, 0.5 } },
      check = function(t) assertEqual(t.__texture, "path\\marble", "texture through LSM") end },
    { style = { bgColorFromSkin = false, bgType = "texture", bgTexture = "Absent", bgColor = { 0.5, 0.5, 0.5, 1 } },
      check = function(t) assertEqual(rgba(t.__color), "0.50,0.50,0.50,1.00", "an absent name is solid") end },
  }
  for i, c in ipairs(cases) do
    local feed, m, Skin = skinned({ style = c.style })
    local LSM = m.LibStub:NewLibrary("LibSharedMedia-3.0", 1)
    LSM.Fetch = function(_, kind, key) return lsm[kind .. ":" .. tostring(key)] end
    feed:Push("a", { title = "A" })
    local r = row(feed)
    c.check(fill(r))
    local opts = Skin.painted[r].calls.Shell[1]
    assertTrue(opts.keepEdge, "case " .. i .. ": a skin repaint leaves the host's fill alone")
    assertTrue(opts.noTopBar and opts.noBands, "case " .. i)
  end
end)

test("feed style: a Refresh from the skin's fill to an override hides the skin's fill", function()
  local style = {}
  local feed, _, Skin = skinned({ style = function() return style end })
  feed:Push("a", { title = "A" })
  local r = row(feed)
  assertTrue(Skin.painted[r].regions.fill:IsShown())
  style = { bgColorFromSkin = false, bgType = "none" }
  feed:Refresh()
  assertFalse(Skin.painted[r].regions.fill:IsShown(), "the skin's fill no longer draws under the host's")
  assertFalse(fill(r):IsShown())
end)

-- == the border ===============================================================================

test("feed style: BarBorder is called with the style's triple and its companion", function()
  local feed, _, _, S = skinned({ style = { borderStyle = "Solid", borderSize = 2, borderStyleFromSkin = false } })
  local calls = spy(S, "BarBorder")
  feed:Push("a", { title = "A" })
  assertTrue(#calls >= 1, "S.BarBorder asked")
  local a = calls[1]
  assertEqual(a[1], "Solid"); assertEqual(a[2], true); assertEqual(a[3], 2); assertEqual(a[4], false)
  local _, edge = edgeColor(row(feed))
  assertEqual(edge.__h, 2, "the edge drawn at the answered size")
end)

test("feed style: the border color is tint, then class, then the skin's, then the custom color", function()
  local tint = { 0.9, 0.1, 0.1, 1 }
  local function colorFor(style, payloadTint, classOn)
    local feed, m, Skin = skinned({ style = style })
    if classOn then m.LibStub("LibKa0s-Core-1.0").ClassColor = function() return 0.2, 0.4, 0.6 end end
    feed:Push("a", { title = "A", tint = payloadTint })
    return (edgeColor(row(feed))), Skin
  end
  assertEqual(colorFor({ borderTint = true, borderClass = true }, tint, true), "0.90,0.10,0.10,1.00",
    "the tint wins")
  assertEqual(colorFor({ borderTint = true, borderClass = true }, nil, true), "0.20,0.40,0.60,1.00",
    "no tint: the class color")
  local got, Skin = colorFor({}, tint, true)
  local want = Skin:Token(OWNER, "bar.border")
  assertEqual(got, rgba(want), "neither on: the skin's bar.border")
  assertEqual(colorFor({ borderColorFromSkin = false, borderColor = { 0.3, 0.6, 0.9, 1 } }, tint, true),
    "0.30,0.60,0.90,1.00", "off the skin: the custom color")
end)

-- == fonts and text colors ====================================================================

test("feed style: every string goes through S.HudFont and none through a bare SetFont", function()
  local feed, _, _, S = skinned()
  local calls = spy(S, "HudFont")
  feed:Push("a", { title = "A", prefix = "P", count = "x2", badge = "9", sub = "s",
    lines = { { left = "l1", right = "r1" } } })
  assertEqual(#calls, 11, "the title, prefix, count, sub, badge and three lines of two")
  local r = row(feed)
  local strings = regions(r, "FontString")
  for _, child in ipairs({ r:GetChildren() }) do
    for _, g in ipairs({ child:GetChildren() }) do
      for _, fs in ipairs({ g:GetRegions() }) do
        if fs:GetObjectType() == "FontString" then strings[#strings + 1] = fs end
      end
    end
  end
  assertEqual(#strings, 11)
  for _, fs in ipairs(strings) do
    assertNil(fs.__font, "no string has a SetFont of its own")
    assertTrue(fs.__fontObject ~= nil, "each wears a font object")
  end
  assertEqual(calls[1][1], stringTitled(r, "A"), "the title first")
  assertEqual(calls[1][2].size, S.HudFontSize(12, true), "the title at fontSize, through HudFontSize")
  assertEqual(calls[2][2].size, S.HudFontSize(10, true), "the rest at fontSize2")
end)

test("feed style: the text color is the spec's, then the class's, then the skin's, then the custom", function()
  local function titleColor(style, own, classOn)
    local feed, m, _, S = skinned({ style = style })
    if classOn then m.LibStub("LibKa0s-Core-1.0").ClassColor = function() return 0.2, 0.4, 0.6 end end
    feed:Push("a", { title = "A", titleColor = own, sub = "s" })
    local r = row(feed)
    return rgba({ stringTitled(r, "A"):GetTextColor() }), S, r
  end
  assertEqual(titleColor({ fontClass = true }, { 1, 0, 0, 1 }, true), "1.00,0.00,0.00,1.00", "the spec's own")
  assertEqual(titleColor({ fontClass = true }, nil, true), "0.20,0.40,0.60,1.00", "the class's")
  local got, S, r = titleColor({}, nil, true)
  assertEqual(got, rgba({ S.HudTextColor() }), "the skin's HUD text color for the title")
  assertEqual(rgba({ stringTitled(r, "s"):GetTextColor() }), rgba({ S.HudLabelColor() }),
    "the skin's HUD label color for the rest")
  assertEqual(titleColor({ fontColorFromSkin = false, fontColor = { 0.5, 0.5, 0.1, 1 } }, nil, false),
    "0.50,0.50,0.10,1.00", "off the skin: the custom color")
end)

-- == the icon and the glow ====================================================================

test("feed style: the icon is cropped at 0.07 through S.IconBorder with hud on", function()
  local feed, _, _, S = skinned()
  local calls = spy(S, "IconBorder")
  feed:Push("a", { title = "A", icon = 134400 })
  assertEqual(#calls, 1)
  assertTrue(calls[1][2].hud == true and calls[1][2].fromSkin == true, "the HUD's icon edge, from the skin")
  local icon = calls[1][2].icon
  assertEqual(icon.__texture, 134400)
  local c = { icon:GetTexCoord() }
  assertTrue(math.abs(c[1] - 0.07) < 1e-9 and math.abs(c[7] - 0.93) < 1e-9, "cropped at 0.07")
end)

test("feed style: the glow is the highlight's color, then the skin's glow, then the custom, in ADD", function()
  local function glowOf(style, highlight)
    local feed, _, _, S = skinned({ style = style })
    feed:Push("a", { title = "A", highlight = highlight })
    local r = row(feed)
    for _, child in ipairs({ r:GetChildren() }) do
      local t = ({ child:GetRegions() })[1]
      if t and t.GetBlendMode and t:GetBlendMode() == "ADD" then
        return rgba(t.__vertex or { 1, 1, 1, 1 }), child, S, feed, t
      end
    end
  end
  local got, holder, _, feed, strip = glowOf({}, { 0.1, 0.9, 0.2, 1 })
  assertEqual(got, "0.10,0.90,0.20,1.00", "a highlight color wins")
  assertTrue(holder:IsShown())
  assertEqual(strip.__texture, "Interface\\Buttons\\WHITE8X8")
  assertTrue(F.clock(feed) ~= nil, "a highlighted row keeps the clock for its breath")
  local skinGot, _, S = glowOf({}, true)
  assertEqual(skinGot, rgba({ S.GlowColor() }), "true: the skin's glow color")
  assertEqual((glowOf({ glowColorFromSkin = false, glowColor = { 0.3, 0.3, 0.9, 1 } }, true)),
    "0.30,0.30,0.90,1.00", "off the skin: the custom color")
  local _, off = glowOf({}, nil)
  assertFalse(off:IsShown(), "no highlight, no glow")
end)

-- == the skin switch ==========================================================================

test("feed style: a skin switch repaints the live rows through content", function()
  local n = 0
  local feed, _, Skin = skinned({ content = function(spec) n = n + 1; spec.title = "A" end })
  feed:Push("a", {}); feed:Push("b", {})
  local before = n
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(n, before + 2, "every live row's content re-ran")
end)

-- == the degraded look ========================================================================

local function assertDegraded(feed, m, why)
  assertEqual(feed:Push("a", { title = "A", icon = 1, tint = { 1, 0, 0, 1 }, sub = "s", highlight = true }), "new",
    why)
  local r = row(feed)
  assertEqual(rgba(fill(r).__color), "0.00,0.00,0.00,0.70", why .. ": the plain fill")
  assertEqual((edgeColor(r)), "0.30,0.30,0.30,1.00", why .. ": the plain edge")
  assertEqual(stringTitled(r, "A").__fontObject, "GameFontHighlight", why .. ": the client's title font")
  assertEqual(stringTitled(r, "s").__fontObject, "GameFontHighlightSmall", why .. ": and its small one")
  assertEqual(rgba({ stringTitled(r, "A"):GetTextColor() }), "1.00,1.00,1.00,1.00", why .. ": white text")
  assertEqual(#m.__errors, 0, why .. ": nothing raised")
  F.step(feed, 0.1)
end

test("feed style: the degraded look draws without Skin, an unregistered owner or a Core facade", function()
  local feed, m = F.feed({ owner = OWNER, content = copyContent, motion = { timerBar = true } })
  assertDegraded(feed, m, "no Skin major")
  local feed2, m2 = skinned({ motion = { timerBar = true } }, true)
  assertDegraded(feed2, m2, "an unregistered owner")
  local feed3, m3 = skinned({ motion = { timerBar = true } })
  m3.LibStub("LibKa0s-Core-1.0").__SkinFacade = nil
  assertDegraded(feed3, m3, "no Core facade")
  local icon = nil
  for _, child in ipairs({ row(feed):GetChildren() }) do
    for _, t in ipairs({ child:GetRegions() }) do
      if t:GetObjectType() == "Texture" and t.__texture == 1 then icon = t end
    end
  end
  assertTrue(icon ~= nil, "the icon drawn")
  local c = { icon:GetTexCoord() }
  assertTrue(math.abs(c[1] - 0.07) < 1e-9, "cropped at 0.07 without the skin too")
end)

test("feed style: the countdown bar follows the hold, flat white without a skin", function()
  local feed, _, _, Feed = F.feed({ content = copyContent, motion = { timerBar = true, smooth = false } })
  feed:Push("a", { title = "A" })
  for _ = 1, 10 do F.step(feed, Feed.ENTER_TIME / 10) end
  local bar
  for _, t in ipairs(regions(row(feed), "Texture", "ARTWORK")) do bar = bar or t end
  for _ = 1, 25 do F.step(feed, Feed.HOLD / 50) end
  assertTrue(bar:IsShown(), "the bar shows while holding")
  assertEqual(rgba(bar.__color), "1.00,1.00,1.00,1.00", "flat white")
  local full = Feed.WIDTH - 2
  assertTrue(math.abs(bar.__w - math.floor(full * 0.5 + 0.5)) <= 1, "half the hold left, half the width")
end)

test("feed style: a Refresh that turns timerBar off hides every live row's bar, a merge after included", function()
  local motion = { timerBar = true, smooth = false }
  local feed, _, _, Feed = F.feed({ content = copyContent, motion = function() return motion end })
  feed:Push("a", { title = "A" })
  F.settle(feed, Feed.ENTER_TIME + 1)
  local bar
  for _, t in ipairs(regions(row(feed), "Texture", "ARTWORK")) do bar = bar or t end
  assertTrue(bar:IsShown(), "on: the bar shows while holding")
  motion = { timerBar = false, smooth = false }
  feed:Refresh()
  F.step(feed, 0.05)
  assertFalse(bar:IsShown(), "off: the next tick hides it")
  assertEqual(feed:Push("a", { title = "A" }), "merged")
  F.step(feed, 0.05)
  assertFalse(bar:IsShown(), "and a merge's restarted hold draws none")
end)

test("feed style: a row's height and line steps count the size the skin draws, not the stored one", function()
  local feed, m, Skin, S = skinned({ style = { fontSize = 30, fontSize2 = 20 } })
  local Feed = m.LibStub(F.MAJOR)
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  feed:Push("a", { title = "A", sub = "s" })
  local r = row(feed)
  local big, small = S.HudFontSize(30, true), S.HudFontSize(20, true)
  assertTrue(big ~= 30, "the skin draws the stored 30 at another size")
  local pad = Feed.PADDING
  assertEqual(r.__h, math.max(Feed.ROW_HEIGHT, pad * 2 + big + 2 + small + 2), "the height as drawn")
  assertEqual(select(5, stringTitled(r, "s"):GetPoint()), -pad - (big + 2), "the sub steps under the title as drawn")
end)

test("feed style: the plain look draws the stored fill and edge and measures the client's fonts", function()
  local before = rawget(_G, "GameFontHighlight")
  _G.GameFontHighlight = { GetFont = function() return "Fonts\\x.ttf", 20, "" end }
  local ok, err = pcall(function()
    local feed, m, _, Feed = F.feed({ content = copyContent,
      style = { bgColor = { 0.2, 0.1, 0, 0.5 }, borderColor = { 0, 1, 0, 1 }, fontSize = 40 } })
    feed:Push("a", { title = "A", sub = "s" })
    local r = row(feed)
    assertEqual(rgba(fill(r).__color), "0.20,0.10,0.00,0.50", "the stored fill, the companion on")
    assertEqual((edgeColor(r)), "0.00,1.00,0.00,1.00", "the stored edge")
    local pad = Feed.PADDING
    assertEqual(select(5, stringTitled(r, "s"):GetPoint()), -pad - (20 + 2), "the template's size, not fontSize 40")
    assertEqual(#m.__errors, 0)
  end)
  _G.GameFontHighlight = before
  assertTrue(ok, tostring(err))
end)

test("feed style: the bar's texture and color follow the skin each on its own companion", function()
  local function barOf(style)
    local feed, m, _, S = skinned({ style = style, motion = { timerBar = true, smooth = false } })
    local LSM = m.LibStub:NewLibrary("LibSharedMedia-3.0", 1)
    LSM.Fetch = function(_, kind, key) if kind == "statusbar" and key == "Mine" then return "path\\mine" end end
    local calls = spy(S, "BarTexture")
    feed:Push("a", { title = "A" })
    local bar
    for _, t in ipairs(regions(row(feed), "Texture", "ARTWORK")) do bar = bar or t end
    return bar, calls, S
  end
  local bar, calls, S = barOf({ barTextureFromSkin = false, barTexture = "Mine" })
  assertEqual(#calls, 0, "the texture off the skin")
  assertEqual(bar.__texture, "path\\mine")
  assertEqual(rgba(bar.__vertex), rgba({ S.BarFillColor() }), "while the color still follows it")
  local _, calls2 = barOf({ barColorFromSkin = false, barColor = { 0.1, 0.2, 0.3, 1 } })
  assertEqual(#calls2, 1, "the texture from the skin")
  assertEqual(rgba({ calls2[1][2], calls2[1][3], calls2[1][4], calls2[1][5] }), "0.10,0.20,0.30,1.00",
    "in the stored color")
end)

test("feed style: a gradient fill and an LSM border reuse their objects across repaints", function()
  local feed, m = F.feed({ content = copyContent,
    style = { bgType = "gradient", borderStyle = "Glow", borderSize = 3 } })
  local LSM = m.LibStub:NewLibrary("LibSharedMedia-3.0", 1)
  LSM.Fetch = function(_, kind, key) if kind == "border" and key == "Glow" then return "path\\glow" end end
  local made, create = 0, m.CreateColor
  m.CreateColor = function(...) made = made + 1; return create(...) end
  feed:Push("a", { title = "A" })
  local r = row(feed)
  local edge
  for _, child in ipairs({ r:GetChildren() }) do
    if tostring(rawget(child, "__template") or ""):find("BackdropTemplate", 1, true) then edge = child end
  end
  local sets, setBackdrop = 0, edge.SetBackdrop
  rawset(edge, "SetBackdrop", function(self, t) sets = sets + 1; return setBackdrop(self, t) end)
  local first, backdrop = made, edge:GetBackdrop()
  assertEqual(backdrop.edgeFile, "path\\glow")
  for _ = 1, 5 do
    assertTrue(feed:Repaint("a"))
    assertEqual(feed:Push("a", { title = "A" }), "merged")
  end
  assertEqual(made, first, "no color object made after the first paint")
  assertEqual(sets, 0, "the backdrop is set again only when its edge changes")
  assertTrue(edge:GetBackdrop() == backdrop, "one backdrop table per row")
end)
