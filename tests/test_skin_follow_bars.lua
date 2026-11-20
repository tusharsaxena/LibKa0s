-- tests/test_skin_follow_bars.lua -- LibKa0s#97's batch B (SD-LK-97B of Ka0sAddonsCommonTasks
-- docs/2026-11-20-LIBKA0S_94_97_99_100; the audit is docs/2026-11-20-SKIN_DEFAULTS_AUDIT): under any
-- skin a bar of data takes the skin's value by default (ruling R-2).
--
--   97.2   the Widgets Bar's border follows the skin's `bar.borderStyle` unless the host says false
--          (WidgetsBar minor 2); `borderShow = false` stays the no-border default under None
--   97.3   S.BarGloss takes a fill Texture (SkinPaintHud minor 2); the Bar's fill wears it under
--          Glass (`glossFromSkin`, default true), shown with the fill, following a switch; and the
--          window chart bars take the same gloss (the owner's U-4, Charts minor 3)
--   97.15  a Charts bar of data is drawn through `barFill` only: a host's `fill` no longer stands in
--          (Charts minor 3)
--   97.17  S.ApplyBarFill on a StatusBar with no texture lays the skin's `bar.texture`, recorded
--          (SkinPaintControls minor 19)
--
-- Each case names the minor it is red under. Two benches for the whole suite (the run's leak gate
-- counts each load of the Skin major), released by the last case.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local F = dofile("tests/fixture_skin_paint.lua")
local FC = dofile("tests/fixture_charts.lua")

local LSM = {
  ["statusbar:Ka0s Default"] = "path\\ka0s", ["statusbar:Ka0s Glass Bar"] = "path\\glass",
  ["statusbar:Ka0s Solid"] = "path\\solid", ["statusbar:Ka0s Matte"] = "path\\matte",
  ["statusbar:Own"] = "path\\own",
}

local function bench()
  local files = {}
  for _, f in ipairs(F.FILES) do files[#files + 1] = f end
  for _, f in ipairs({ "Pool", "Widgets", "WidgetsBar", "Charts", "ChartsRender" }) do files[#files + 1] = f end
  local m, Skin = F.env({ files = files, lsm = LSM })
  return m, Skin, m.LibStub("LibKa0s-Widgets-1.0")
end

-- One bench for the bars and the charts alike: a second full payload for the Charts cases tipped
-- the run's leak gate.
local M, SKIN, W = bench()

local function charts() return M, M.LibStub("LibKa0s-Charts-1.0"), SKIN end
local function content(m) return m.CreateFrame("Frame", nil, m.UIParent) end

local function edgesShown(bar)
  local n = 0
  for _, t in ipairs(bar.edges) do if t:IsShown() then n = n + 1 end end
  return n
end

local RED = { 1, 0, 0 }
local ROW = { { label = "A", frac = 1, color = RED, value = "1" } }

-- ── 97.2: the Bar's border ───────────────────────────────────────────────────────────────────

test("bar follow: a style with no borderFromSkin follows the skin's border (97.2)", function()
  -- red under WidgetsBar minor 1: DEFAULTS' borderFromSkin false, so the skin's Solid never drew.
  assertTrue(W.BarStyle("mini").borderFromSkin == true, "the default is to follow")
  F.owner(SKIN, "BF_Border", "contrast")
  local bar = W.Bar(M.UIParent, { owner = "BF_Border", style = W.BarStyle("mini") })
  assertEqual(edgesShown(bar), 4, "High Contrast's Solid border, with no borderShow")
  assertEqual(F.rgba(M.__paint(bar.edges[1]).color), F.tok(SKIN, "contrast", "bar.border"))
  SKIN:SetChoice("BF_Border", "ka0s", "obsidian")
  assertEqual(edgesShown(bar), 0, "a skin of None: the stored borderShow false draws none")
  SKIN:SetChoice("BF_Border", "ka0s", "azeroth")
  assertEqual(edgesShown(bar), 4, "and a switch back to a real style draws it again")
end)

test("bar follow: borderFromSkin false keeps the host's own border under every skin (97.2)", function()
  F.owner(SKIN, "BF_BorderOwn", "contrast")
  local bar = W.Bar(M.UIParent, { owner = "BF_BorderOwn", style = W.BarStyle("mini", { borderFromSkin = false }) })
  assertEqual(edgesShown(bar), 0, "the host resolved no border (Skill Master's BarStyle)")
  local shown = W.Bar(M.UIParent, { owner = "BF_BorderOwn",
    style = W.BarStyle("row", { borderFromSkin = false, borderShow = true, borderStyle = "Solid" }) })
  SKIN:SetChoice("BF_BorderOwn", "ka0s", "obsidian")
  assertEqual(edgesShown(shown), 4, "the host's Solid stays under a skin of None")
end)

test("bar follow: an owner-less bar still draws no border by default (97.2)", function()
  local bar = W.Bar(M.UIParent, { preset = "row" })
  assertEqual(edgesShown(bar), 0, "Ka0s Default's None")
end)

-- ── 97.3: the gloss ──────────────────────────────────────────────────────────────────────────

test("gloss: S.BarGloss on a Texture lays the look on its parent, anchored to it (97.3)", function()
  -- red under SkinPaintHud minor 1: anything but a StatusBar was left alone.
  local m, Skin = M, SKIN
  local S = F.owner(Skin, "BF_TexGloss", "glass")
  local frame = m.CreateFrame("Frame", nil, m.UIParent)
  local tex = frame:CreateTexture(nil, "ARTWORK")
  local answered = S.BarGloss(tex)
  local gloss = F.region(Skin, tex, "gloss")
  assertTrue(gloss ~= nil and gloss == answered, "built, and answered")
  local p = m.__paint(gloss)
  assertTrue(p.shown)
  assertEqual(p.layer, "OVERLAY"); assertEqual(p.sublevel, -8)
  assertEqual(gloss.__owner, frame, "a region of the Texture's parent")
  local a, rel, b = gloss:GetPoint(1)
  assertEqual(a, "TOPLEFT"); assertTrue(rel == tex); assertEqual(b, "TOPLEFT")
  local _, rel2, d = gloss:GetPoint(2)
  assertTrue(rel2 == tex); assertEqual(d, "RIGHT", "the top half")
  Skin:SetChoice("BF_TexGloss", "ka0s", "obsidian")
  assertFalse(gloss:IsShown(), "recorded: a switch to a skin with no gloss takes it off")
  Skin:SetChoice("BF_TexGloss", "ka0s", "glass")
  assertTrue(gloss:IsShown(), "and back on")
end)

test("gloss: a hidden Texture's gloss is hidden, fromSkin false and Ka0s Default build none (97.3)", function()
  local m, Skin = M, SKIN
  local S = F.owner(Skin, "BF_TexGloss2", "glass")
  local frame = m.CreateFrame("Frame", nil, m.UIParent)
  local hidden = frame:CreateTexture()
  hidden:Hide()
  local g = S.BarGloss(hidden)
  assertTrue(g ~= nil and not g:IsShown(), "built for the skin, hidden with its fill")
  local mine = frame:CreateTexture()
  assertNil(S.BarGloss(mine, false), "a player's own texture")
  assertNil(F.region(Skin, mine, "gloss"))
  local K = F.owner(Skin, "BF_TexGloss3")
  local plain = frame:CreateTexture()
  assertNil(K.BarGloss(plain), "Ka0s Default draws no gloss")
  assertNil(F.region(Skin, plain, "gloss"))
end)

test("bar follow: under Glass the Bar's fill wears the gloss, which follows a switch (97.3)", function()
  -- red under WidgetsBar minor 1: the fill is a Texture and no gloss was ever drawn on it.
  F.owner(SKIN, "BF_Gloss", "glass")
  local bar = W.Bar(M.UIParent, { owner = "BF_Gloss", preset = "row" })
  assertTrue(W.BarStyle("row").glossFromSkin == true, "the default is to follow")
  bar:__setGeom(102, 14)
  bar:SetValues{ value = 5, max = 10 }
  local gloss = F.region(SKIN, bar.fill, "gloss")
  assertTrue(gloss ~= nil and gloss:IsShown(), "Glass's gloss on the fill")
  assertEqual(gloss.__owner, bar, "a region of the bar")
  assertTrue(select(2, gloss:GetPoint(1)) == bar.fill, "anchored to the fill")
  SKIN:SetChoice("BF_Gloss", "ka0s", "obsidian")
  assertFalse(gloss:IsShown(), "off with a skin that draws none")
  SKIN:SetChoice("BF_Gloss", "ka0s", "glass")
  assertTrue(gloss:IsShown(), "on again")
end)

test("bar follow: the gloss shows only with its fill, a segment's included (97.3)", function()
  F.owner(SKIN, "BF_GlossShown", "glass")
  local bar = W.Bar(M.UIParent, { owner = "BF_GlossShown", style = W.BarStyle("row", { segmented = true }) })
  bar:__setGeom(302, 14)
  bar:SetValues{ value = 5, max = 10 }
  local gloss = F.region(SKIN, bar.fill, "gloss")
  assertTrue(gloss ~= nil and gloss:IsShown())
  bar:SetValues{ value = 0, max = 10 }
  assertFalse(bar.fill:IsShown()); assertFalse(gloss:IsShown(), "an empty fill shines nowhere")
  bar:SetValues{ value = 200, max = 300, segments = { 100, 200, 300 } }
  assertFalse(gloss:IsShown(), "segments take the fill's place, and its gloss goes with it")
  local seg = F.region(SKIN, bar.segmentTextures[1], "gloss")
  assertTrue(seg ~= nil and seg:IsShown(), "a segment wears its own")
  SKIN:SetChoice("BF_GlossShown", "ka0s", "obsidian")
  SKIN:SetChoice("BF_GlossShown", "ka0s", "glass")
  assertFalse(gloss:IsShown(), "a replay leaves the hidden fill's gloss hidden")
  assertTrue(seg:IsShown())
end)

test("bar follow: glossFromSkin false and the style's own texture draw no gloss (97.3)", function()
  F.owner(SKIN, "BF_GlossOff", "glass")
  local off = W.Bar(M.UIParent, { owner = "BF_GlossOff", style = W.BarStyle("row", { glossFromSkin = false }) })
  off:__setGeom(102, 14)
  off:SetValues{ value = 5, max = 10 }
  local g = F.region(SKIN, off.fill, "gloss")
  assertTrue(g == nil or not g:IsShown(), "the host opted out")
  local own = W.Bar(M.UIParent, { owner = "BF_GlossOff", style = W.BarStyle("row", { texture = "Own" }) })
  own:__setGeom(102, 14)
  own:SetValues{ value = 5, max = 10 }
  local g2 = F.region(SKIN, own.fill, "gloss")
  assertTrue(g2 == nil or not g2:IsShown(), "a player's own texture wears no skin gloss")
  local plain = W.Bar(M.UIParent, { preset = "row" })
  plain:SetValues{ value = 5, max = 10 }
  assertNil(F.region(SKIN, plain.fill, "gloss"), "an owner-less bar is Ka0s Default's: none")
end)

-- ── 97.17: ApplyBarFill on a texture-less StatusBar ──────────────────────────────────────────

test("bar fill: ApplyBarFill gives a StatusBar with no texture the skin's bar texture (97.17)", function()
  -- red under SkinPaintControls minor 18: only a color, so the bar drew nothing (Outfitter Reborn's
  -- progress bar).
  local m, Skin = M, SKIN
  local S = F.owner(Skin, "BF_Fill", "contrast")
  local sb = m.CreateFrame("StatusBar", nil, m.UIParent)
  S.ApplyBarFill(sb)
  assertEqual(sb:GetStatusBarTexture():GetTexture(), "path\\solid", "High Contrast's bar texture")
  assertEqual(F.rgba({ sb:GetStatusBarColor() }), F.tok(Skin, "contrast", "text.accent"), "in the accent")
  Skin:SetChoice("BF_Fill", "ka0s", "obsidian")
  assertEqual(sb:GetStatusBarTexture():GetTexture(), "path\\matte", "recorded: a switch moves it")
  assertEqual(F.rgba({ sb:GetStatusBarColor() }), F.tok(Skin, "obsidian", "text.accent"))
end)

test("bar fill: ApplyBarFill keeps a host's own texture, and a Texture takes the color only (97.17)", function()
  local m, Skin = M, SKIN
  local S = F.owner(Skin, "BF_FillOwn", "contrast")
  local sb = m.CreateFrame("StatusBar", nil, m.UIParent)
  sb:SetStatusBarTexture("Interface\\HostBar")
  S.ApplyBarFill(sb)
  assertEqual(sb:GetStatusBarTexture():GetTexture(), "Interface\\HostBar", "the host's")
  Skin:SetChoice("BF_FillOwn", "ka0s", "obsidian")
  assertEqual(sb:GetStatusBarTexture():GetTexture(), "Interface\\HostBar", "and after a switch")
  local tex = m.CreateFrame("Frame"):CreateTexture()
  S.ApplyBarFill(tex)
  assertNil(tex:GetTexture(), "a Texture is the host's art")
  assertEqual(F.rgba(m.__paint(tex).vertex), F.tok(Skin, "obsidian", "text.accent"))
end)

-- ── 97.15 and U-4: the Charts bars ───────────────────────────────────────────────────────────

test("charts follow: a host fill no longer stands in for a bar of data (97.15)", function()
  -- red under Charts minor 2: `host.barFill or host.fill or plainFill` drew the bars flat.
  local m, Charts = FC.env()
  local n = 0
  local ctx = Charts:New(FC.content(m), { fill = function() n = n + 1 end })
  local pool = ctx:Pool("b")
  ctx:renderBarSection(pool, ctx:sectionHeader(nil, "H"), ROW, 0, 500, 8)
  assertEqual(n, 1, "the track only")
  assertEqual(pool.active[1].fill.__color[1], 1, "no Skin major: the bar is a flat color")
end)

test("charts follow: an owner-less bar of data paints Ka0s Default's bar texture (97.15)", function()
  local m, C, Skin = charts()
  local n = 0
  local ctx = C:New(content(m), { fill = function() n = n + 1 end })
  local pool = ctx:Pool("b")
  ctx:renderBarSection(pool, ctx:sectionHeader(nil, "H"), ROW, 0, 500, 8)
  local rec = Skin.painted[pool.active[1].fill]
  assertTrue(rec ~= nil and rec.calls.BarTexture ~= nil, "through S.BarTexture")
  assertEqual(n, 1, "the host's fill drew the track")
end)

test("charts follow: an owner's chart bar wears the skin's gloss under Glass (U-4)", function()
  -- red under Charts minor 2: S.BarTexture alone, no gloss on a window chart bar.
  local m, C, Skin = charts()
  Skin:RegisterOwner("BF_ChartGloss")
  Skin:SetChoice("BF_ChartGloss", "ka0s", "glass")
  local ctx = C:New(content(m), { owner = "BF_ChartGloss" })
  local pool = ctx:Pool("b")
  ctx:renderBarSection(pool, ctx:sectionHeader(nil, "H"), ROW, 0, 500, 8)
  local bar = pool.active[1]
  local rec = Skin.painted[bar.fill]
  assertTrue(rec ~= nil and rec.calls.BarGloss ~= nil, "the fill's gloss is recorded")
  local gloss = rec.regions.gloss
  assertTrue(gloss ~= nil and gloss:IsShown(), "drawn")
  assertTrue(gloss.__owner == bar, "a region of the bar's frame")
  Skin:SetChoice("BF_ChartGloss", "ka0s", "obsidian")
  assertFalse(gloss:IsShown(), "a switch takes it off")
end)

-- Last: let the benches go (the run's leak gate counts them until the end otherwise).
test("bar follow: the suite releases its benches", function()
  M, SKIN, W = nil, nil, nil
  collectgarbage("collect")
  assertNil(W)
end)
