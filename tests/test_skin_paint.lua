-- tests/test_skin_paint.lua — LibKa0s-Skin-1.0's paint primitives, part one: the shared rules
-- (attachment, the holder, idempotence, live repaint, per-owner isolation, Ka0s Default keeping
-- stock art, owner moves and re-tracking) and the window family, the text primitives and the getters
-- (SkinPaint.lua, SkinPaintExtras.lua). The controls are tests/test_skin_paint_controls.lua's.
--
-- Every case runs on a fresh environment with the kit's paint recorder installed
-- (tests/fixture_skin_paint.lua), so regions are real objects whose paint can be read back. The
-- Ka0s Default cases pin a primitive's trace against the library code it stands for: Core's own
-- ApplySkin, run on an identical frame, or the call site's literal paint calls, cited by file.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local F = dofile("tests/fixture_skin_paint.lua")

local OWNER = "LootHistory"

local function survey(m, obj) return m.__paint(obj) end

--- Run `paint(target)` on a fresh window with the tracer on; answers the trace text.
local function traceOn(m, names, build, paint)
  local tr = F.tracer(m, names)
  local target, extra = build(m)
  tr.watch(target)
  for _, o in ipairs(extra or {}) do tr.watch(o) end
  tr.start(); paint(target); tr.stop(); tr.restore()
  return tr.text(), target
end

local function windowBuild(m)
  local f = F.window(m)
  return f, { f.title, f.divider }
end

-- ── attachment ───────────────────────────────────────────────────────────────────────────────

test("skin paint: the three files attach to the shell and fill every vocabulary entry", function()
  local _, Skin = F.env()
  assertEqual(Skin.MODULES.SkinPaint, Skin.__paintMinor, "SkinPaint reports its own minor")
  assertEqual(Skin.MODULES.SkinPaintExtras, Skin.__extrasMinor)
  assertEqual(Skin.MODULES.SkinPaintControls, Skin.__controlsMinor)
  for _, probe in ipairs({ "__paintShellMinor", "__extrasShellMinor", "__controlsShellMinor" }) do
    assertEqual(Skin[probe], Skin.MINOR, probe .. " names the live shell")
  end
  for _, name in ipairs(Skin.VOCAB) do
    assertEqual(type(Skin.prim[name]), "function", "lib.prim." .. name)
  end
  assertNil(Skin.Release, "no Release member: a pooled target is given back when it moves owner")
end)

test("skin paint: the extras and controls attach to nothing without SkinPaint's helpers", function()
  local _, Skin = F.env({ files = { "Core", "Skin", "SkinDefs", "SkinPaintExtras", "SkinPaintControls" } })
  assertNil(Skin.prim.Card, "no extras")
  assertNil(Skin.prim.Button, "no controls")
  assertNil(Skin.MODULES.SkinPaintControls)
  assertNil(Skin:For(OWNER).Button({}), "the trampoline answers nil and touches nothing")
end)

test("skin paint: with no skin registered a primitive paints nothing it has no token for", function()
  local m, Skin = F.env({ files = { "Core", "Skin", "SkinPaint", "SkinPaintExtras", "SkinPaintControls" } })
  local S = F.owner(Skin, OWNER)
  local f = F.window(m)
  S.Card(f)
  assertNil(survey(m, f).backdrop, "no card token, no backdrop")
  S.Shell(f)
  assertTrue(survey(m, f).backdrop == m.LibStub("LibKa0s-Core-1.0").SKIN, "Shell is still today's window")
end)

-- ── Shell ────────────────────────────────────────────────────────────────────────────────────

test("skin paint: Shell on Ka0s Default is Core.ApplySkin, call for call", function()
  local m, Skin = F.env()
  F.owner(Skin, OWNER)
  local core = m.LibStub("LibKa0s-Core-1.0")
  local names = { [core.SKIN] = "SKIN" }
  local want = traceOn(m, names, windowBuild, function(f) core.ApplySkin(f) end)
  local got = traceOn(m, names, windowBuild, function(f) Skin:For(OWNER).Shell(f) end)
  assertTrue(want:find("#1:SetBackdrop(SKIN)", 1, true) ~= nil, "Core hands the frame its own SKIN")
  assertEqual(got, want, "the registered owner's trace")
  local unregistered = traceOn(m, names, windowBuild, function(f) Skin:For("Nobody").Shell(f) end)
  assertEqual(unregistered, want, "an unregistered name's trace")
end)

test("skin paint: Shell paints a skin's window from its tokens", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "obsidian")
  local f = F.window(m)
  S.Shell(f)
  local s = survey(m, f)
  assertEqual(F.rgba(s.backdropColor), F.tok(Skin, "obsidian", "win.bg"), "win.bg")
  assertEqual(F.rgba(s.backdropBorderColor), F.tok(Skin, "obsidian", "win.border"), "win.border")
  assertEqual(F.rgba(survey(m, f.title).textColor), F.tok(Skin, "obsidian", "title.text"), "title.text")
  assertEqual(F.rgba(survey(m, f.divider).color), F.tok(Skin, "obsidian", "divider"), "divider")
  assertNil(rawget(f, "innerBorder"), "Obsidian has no inner rule: Core makes none")
  local top = F.region(Skin, f, "top")
  assertEqual(F.rgba(survey(m, top).color), F.tok(Skin, "obsidian", "title.bg"), "the title band")
end)

test("skin paint: a second Shell call makes no new region and paints the same", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, "A", "midnight")
  local f = F.window(m)
  S.Shell(f)
  local regions, kids = f:GetNumRegions(), f:GetNumChildren()
  local before = F.rgba(survey(m, f).backdropColor)
  S.Shell(f)
  assertEqual(f:GetNumRegions(), regions, "no new region")
  assertEqual(f:GetNumChildren(), kids, "no new child frame")
  assertEqual(F.rgba(survey(m, f).backdropColor), before)
  assertEqual(#Skin.painted[f].order, 1, "one primitive recorded once")
end)

test("skin paint: a skin switch repaints a Shell live, and back to Ka0s Default exactly", function()
  local m, Skin = F.env()
  local core = m.LibStub("LibKa0s-Core-1.0")
  local S = F.owner(Skin, OWNER)
  local f = F.window(m)
  S.Shell(f)
  Skin:SetChoice(OWNER, "ka0s", "midnight")
  local grad = F.region(Skin, f, "grad")
  assertTrue(grad ~= nil and grad:IsShown(), "WoW Midnight's window gradient")
  local g = survey(m, grad).gradient
  assertEqual(g.orientation, "VERTICAL")
  assertEqual(F.rgba({ g.max.r, g.max.g, g.max.b, g.max.a }), F.tok(Skin, "midnight", "win.bgTop"), "top")
  assertEqual(F.rgba(survey(m, f.title).textColor), F.tok(Skin, "midnight", "title.text"))
  assertEqual(F.rgba(survey(m, f.innerBorder).backdropBorderColor), F.tok(Skin, "midnight", "win.inner"))
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(F.rgba(survey(m, f.innerBorder).backdropBorderColor), "0,0,0,0",
    "a skin with no inner rule clears the one Core left tinted")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertTrue(survey(m, f).backdrop == core.SKIN, "Ka0s Default hands Core its SKIN again")
  assertFalse(grad:IsShown(), "the gradient is hidden")
  assertFalse(F.region(Skin, f, "top"):IsShown(), "the title band is hidden")
  assertEqual(F.rgba(survey(m, f.innerBorder).backdropBorderColor), F.rgba(core.SKIN.innerBorder))
end)

test("skin paint: WoW Default's window is the dialog edge on the holder over the tiled art", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "wow")
  local tr = F.tracer(m)
  local f = F.window(m)
  tr.watch(f)
  tr.start(); S.Shell(f); tr.stop(); tr.restore()
  local h = F.region(Skin, f, "holder")
  local bd = survey(m, h).backdrop
  assertEqual(bd.edgeFile, "Interface\\DialogFrame\\UI-DialogBox-Border",
    "Blizzard Dialog, from the client's path when LibSharedMedia lacks it")
  assertEqual(bd.edgeSize, 32)
  assertTrue(tr.text():find('SetPoint("TOPLEFT",#1,"TOPLEFT",-8,8)', 1, true) ~= nil,
    "drawn outset by a quarter of its size")
  assertEqual(F.rgba(survey(m, f).backdropBorderColor), "0,0,0,0", "the backdrop's own edge is clear")
  local art = F.region(Skin, f, "art")
  assertEqual(survey(m, art).texture, Skin:ResolveSkin("wow")["win.bgTexture"], "the tiled art")
  assertTrue(art:GetHorizTile() and art:GetVertTile(), "tiled both ways")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertNil(survey(m, h).backdrop, "back on Ka0s Default the nine-slice is gone")
  assertFalse(art:IsShown())
end)

test("skin paint: the holder is a child frame one level up, and edges live on it", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "contrast")
  local tr = F.tracer(m)
  local f = m.CreateFrame("Frame", nil, m.UIParent)
  rawset(f, "SetBackdrop", nil)   -- no BackdropTemplate: the fill a region, every edge on the holder
  rawset(f, "GetFrameLevel", function() return 5 end)
  tr.start(); S.Shell(f); tr.stop(); tr.restore()
  local h = F.region(Skin, f, "holder")
  assertTrue(h ~= nil and h.__parent == f, "the holder is the frame's child")
  assertTrue(tr.text():find("SetFrameLevel(6)", 1, true) ~= nil, "at the frame's level + 1")
  local edge = F.region(Skin, f, "edgeTop")
  assertTrue(edge:GetParent() == h, "an edge is a region of the holder")
  for _, r in ipairs({ f:GetRegions() }) do
    assertFalse(r == edge, "and never a direct region of the frame")
  end
  assertEqual(F.rgba(survey(m, edge).color), F.tok(Skin, "contrast", "win.border"))
end)

test("skin paint: Ka0s Default leaves a stock frame stock, and a skin fades its art", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local f = m.CreateFrame("Frame", nil, m.UIParent, "PortraitFrameTemplate")
  rawset(f, "SetBackdrop", nil)   -- the client's portrait frame wears no BackdropTemplate
  local piece = f.NineSlice.TopEdge
  piece:SetAlpha(0.8)
  S.Shell(f)
  assertEqual(piece:GetAlpha(), 0.8, "Ka0s Default: the client's art as drawn")
  assertNil(survey(m, f).backdrop, "and nothing painted over it")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(piece:GetAlpha(), 0, "a skin fades the template art")
  assertTrue(F.region(Skin, f, "holder") ~= nil, "and draws its own window")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertEqual(piece:GetAlpha(), 0.8, "back on Ka0s Default the recorded alpha returns")
  assertFalse(F.region(Skin, f, "holder"):IsShown(), "and every Ka0s region is hidden")
  assertNil(survey(m, f).backdrop, "the backdrop it set is taken off")
end)

-- ── per owner ────────────────────────────────────────────────────────────────────────────────

test("skin paint: two owners on one loaded copy paint and repaint only their own frames", function()
  local m, Skin = F.env()
  local A, B = F.owner(Skin, "AddonA", "obsidian"), F.owner(Skin, "AddonB", "ember")
  local fa, fb = F.window(m), F.window(m)
  A.Shell(fa); B.Shell(fb)
  assertEqual(F.rgba(survey(m, fa).backdropColor), F.tok(Skin, "obsidian", "win.bg"))
  assertEqual(F.rgba(survey(m, fb).backdropColor), F.tok(Skin, "ember", "win.bg"))
  local bBefore = survey(m, fb).backdrop
  Skin:SetChoice("AddonA", "ka0s", "azeroth")
  assertEqual(F.rgba(survey(m, fa).backdropColor), F.tok(Skin, "azeroth", "win.bg"), "A repainted")
  assertTrue(survey(m, fb).backdrop == bBefore, "B's frame was not touched")
  assertEqual(F.rgba(survey(m, fb).backdropColor), F.tok(Skin, "ember", "win.bg"))
end)

test("skin paint: a target painted for a second owner is given back first", function()
  local m, Skin = F.env()
  local A, B = F.owner(Skin, "AddonA", "obsidian"), F.owner(Skin, "AddonB")
  local b = m.CreateFrame("Button", nil, m.UIParent)
  rawset(b, "SetBackdrop", nil)
  local normal = b:CreateTexture()
  rawset(b, "GetNormalTexture", function() return normal end)
  A.Button(b)
  assertEqual(normal:GetAlpha(), 0, "A's skin fades the stock art")
  B.Button(b)
  assertEqual(normal:GetAlpha(), 1, "B on Ka0s Default sees the stock art again")
  assertEqual(Skin.painted[b].owner, "AddonB")

  local C = F.owner(Skin, "AddonC", "contrast")
  local row = m.CreateFrame("Button", nil, m.UIParent)
  C.ListRow(row, "selected")
  local sel, edge = F.region(Skin, row, "sel"), F.region(Skin, row, "edgeTop")
  A.ListRow(row, "normal")
  assertFalse(sel:IsShown(), "C's selection wash is gone")
  assertFalse(edge:IsShown(), "and its outline")
  Skin:SetChoice("AddonC", "ka0s", "glass")
  assertFalse(sel:IsShown(), "C's repaint no longer reaches the row")
end)

test("skin paint: a target untracked and painted again reuses its regions and hooks", function()
  local m, Skin = F.env()
  local A, B = F.owner(Skin, "AddonA", "contrast"), F.owner(Skin, "AddonB", "obsidian")
  local row = m.CreateFrame("Button", nil, m.UIParent)
  A.ListRow(row, "selected")
  local holder, under = F.region(Skin, row, "holder"), F.region(Skin, row, "under")
  for _ = 1, 3 do
    Skin:Untrack(row)
    A.ListRow(row, "selected")
  end
  B.ListRow(row, "selected")
  assertTrue(F.region(Skin, row, "holder") == holder, "the same holder")
  assertTrue(F.region(Skin, row, "under") == under, "the same fill holder")
  assertEqual(row:GetNumChildren(), 2, "two holders on the row, ever")

  local secure, scripts = 0, 0
  m.hooksecurefunc = function() secure = secure + 1 end
  local cb = m.CreateFrame("CheckButton", nil, m.UIParent)
  local hook = cb.HookScript
  rawset(cb, "HookScript", function(self, ...) scripts = scripts + 1; return hook(self, ...) end)
  A.Checkbox(cb)
  local first = scripts .. "/" .. secure
  Skin:Untrack(cb); A.Checkbox(cb); B.Checkbox(cb)
  assertEqual(scripts .. "/" .. secure, first, "no hook is added twice")
end)

test("skin paint: fills and washes sit under the target's text, edges over it", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "contrast")
  local tr = F.tracer(m)
  local row = m.CreateFrame("Button", nil, m.UIParent)
  rawset(row, "GetFrameLevel", function() return 5 end)
  tr.start(); S.ListRow(row, { stripe = true, selected = true }); tr.stop(); tr.restore()
  local under, holder = F.region(Skin, row, "under"), F.region(Skin, row, "holder")
  assertTrue(under ~= nil and under.__parent == row, "the fill holder is the row's child")
  assertTrue(tr.text():find("SetFrameLevel(4)", 1, true) ~= nil, "one level below the row")
  assertEqual(F.region(Skin, row, "stripe"):GetParent(), under, "the stripe under the row's text")
  assertEqual(F.region(Skin, row, "sel"):GetParent(), under, "the selection wash too")
  assertEqual(F.region(Skin, row, "edgeTop"):GetParent(), holder, "the outline over it")

  local lv0 = m.CreateFrame("Frame", nil, m.UIParent)
  rawset(lv0, "SetBackdrop", nil)
  rawset(lv0, "GetFrameLevel", function() return 0 end)
  local tr0 = F.tracer(m)
  tr0.start(); S.Strip(lv0); tr0.stop(); tr0.restore()
  assertTrue(tr0.text():find("SetFrameLevel(0)", 1, true) ~= nil, "never below level 0")
  assertEqual(F.region(Skin, lv0, "wash"):GetParent(), F.region(Skin, lv0, "under"))
end)

-- ── Panel, Inset, the faders ─────────────────────────────────────────────────────────────────

local function backdropFrame(m) return m.CreateFrame("Frame", nil, m.UIParent, "BackdropTemplate") end

test("skin paint: Panel on Ka0s Default is LootHistory's list panel, call for call", function()
  -- modules/AnalyticsCharts.lua listPanel: the WHITE8X8 table with 1px insets, then fill, then edge
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local got = traceOn(m, nil, backdropFrame, function(f) S.Panel(f) end)
  local want = table.concat({
    '#1:SetBackdrop({bgFile="Interface\\\\Buttons\\\\WHITE8X8",edgeFile="Interface\\\\Buttons\\\\WHITE8X8",'
      .. 'edgeSize=1,insets={bottom=1,left=1,right=1,top=1}})',
    "#1:SetBackdropColor(0.080,0.080,0.100,0.600)",
    "#1:SetBackdropBorderColor(0.240,0.240,0.270,0.700)",
  }, "\n")
  assertEqual(got, want)
end)

test("skin paint: Inset, noBg, noBorder and the nav rail's recolor", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "obsidian")
  local f = backdropFrame(m)
  S.Inset(f)
  assertEqual(F.rgba(survey(m, f).backdropColor), F.tok(Skin, "obsidian", "input.bg"), "Inset is input.*")
  local g = backdropFrame(m)
  S.Panel(g, { noBg = true })
  assertEqual(F.rgba(survey(m, g).backdropColor), "0,0,0,0", "noBg: a clear fill")
  assertEqual(F.rgba(survey(m, g).backdropBorderColor), F.tok(Skin, "obsidian", "panel.border"))
  local h = backdropFrame(m)
  S.Panel(h, { noBorder = true })
  assertEqual(F.rgba(survey(m, h).backdropBorderColor), "0,0,0,0", "noBorder: a clear edge")
  -- OptionsNav.lua railFrame: SetBackdropColor(PANE_FILL 4), SetBackdropBorderColor(PANE_BORDER 3)
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  local text = traceOn(m, nil, backdropFrame, function(r) S.Panel(r, { nav = true }) end)
  assertEqual(text, "#1:SetBackdropColor(0.100,0.100,0.100,0.500)\n#1:SetBackdropBorderColor(0.400,0.400,0.400)",
    "the rail's art is kept and recolored, as OptionsNav paints it")
end)

test("skin paint: FadeRegions fades the stock textures, records their alpha, and spares its own", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local f = m.CreateFrame("Frame", nil, m.UIParent)
  local a, b = f:CreateTexture(), f:CreateTexture()
  b:SetAlpha(0.5)
  local fs = f:CreateFontString()
  S.FadeRegions(f)
  assertEqual(a:GetAlpha(), 1, "Ka0s Default fades nothing")
  Skin:SetChoice(OWNER, "ka0s", "glass")
  assertEqual(a:GetAlpha(), 0); assertEqual(b:GetAlpha(), 0)
  assertEqual(fs:GetAlpha(), 1, "a font string is not art")
  S.Divider(f)
  S.FadeRegions(f)
  assertEqual(F.region(Skin, f, "holder"):GetAlpha(), 1, "the holder is never faded")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertEqual(b:GetAlpha(), 0.5, "the recorded alpha comes back")
  assertEqual(a:GetAlpha(), 1)
end)

test("skin paint: FadeNineSlice fades the nine pieces away from Ka0s Default", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "ember")
  local f = m.CreateFrame("Frame", nil, m.UIParent, "NineSlicePanelTemplate")
  S.FadeNineSlice(f)
  for _, k in ipairs(m.__nineSliceKeys) do assertEqual(f.NineSlice[k]:GetAlpha(), 0, k) end
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  for _, k in ipairs(m.__nineSliceKeys) do assertEqual(f.NineSlice[k]:GetAlpha(), 1, k) end
end)

-- ── the Ka0s extras ──────────────────────────────────────────────────────────────────────────

test("skin paint: TitleBar paints only the title color on Ka0s Default", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local text = traceOn(m, nil, function(mm)
    local bar = mm.CreateFrame("Frame", nil, mm.UIParent)
    bar.title = bar:CreateFontString()
    return bar, { bar.title }
  end, function(bar) S.TitleBar(bar) end)
  assertEqual(text, "#2:SetTextColor(1,0.820,0)", "title.text, three components, and nothing else")
end)

test("skin paint: TitleBar fills under its text, centers its title, and gives the alignment back", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "forever")
  local bar = m.CreateFrame("Frame", nil, m.UIParent)
  rawset(bar, "SetBackdrop", nil)   -- a bare bar: the fill goes on the fill holder
  local fs = bar:CreateFontString()
  fs:SetJustifyH("LEFT")
  S.TitleBar(bar, { text = fs })
  local fill = F.region(Skin, bar, "fill")
  assertTrue(fill:GetParent() == F.region(Skin, bar, "under"), "the fill is under the bar's text")
  assertEqual(F.rgba(survey(m, fill).color), F.tok(Skin, "forever", "title.bg"))
  assertEqual(fs:GetJustifyH(), "CENTER", "WoW Forever centers its titles")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertEqual(fs:GetJustifyH(), "LEFT", "the alignment it had comes back")
  assertFalse(fill:IsShown(), "and the fill is hidden")
end)

test("skin paint: Divider colors a texture in place, as Core's divider is colored", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local text = traceOn(m, nil, function(mm)
    local t = mm.CreateFrame("Frame"):CreateTexture()
    return t
  end, function(t) S.Divider(t) end)
  assertEqual(text, "#1:SetColorTexture(0.240,0.240,0.270,0.850)")
  local f = m.CreateFrame("Frame", nil, m.UIParent)
  S.Divider(f, { token = "section.rule" })
  local line = F.region(Skin, f, "line")
  assertEqual(F.rgba(survey(m, line).color), F.tok(Skin, "ka0s", "section.rule"), "a frame: a line on the holder")
end)

test("skin paint: Card on Ka0s Default is LootHistory's KPI card, call for call", function()
  -- modules/Analytics.lua: the WHITE8X8 table with 1px insets, fill .1/.1/.12/.85, edge .24/.24/.27/.9
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local text = traceOn(m, nil, backdropFrame, function(f) S.Card(f) end)
  assertEqual(text, table.concat({
    '#1:SetBackdrop({bgFile="Interface\\\\Buttons\\\\WHITE8X8",edgeFile="Interface\\\\Buttons\\\\WHITE8X8",'
      .. 'edgeSize=1,insets={bottom=1,left=1,right=1,top=1}})',
    "#1:SetBackdropColor(0.100,0.100,0.120,0.850)",
    "#1:SetBackdropBorderColor(0.240,0.240,0.270,0.900)",
  }, "\n"))
end)

test("skin paint: Footer draws nothing on Ka0s Default and a band in a skin that sets foot.bg", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local text = traceOn(m, nil, backdropFrame, function(f) S.Footer(f) end)
  assertEqual(text, "", "foot.bg is nil in Ka0s Default")
  Skin:SetChoice(OWNER, "ka0s", "azeroth")
  local f = backdropFrame(m)
  S.Footer(f)
  assertEqual(F.rgba(survey(m, f).backdropColor), F.tok(Skin, "azeroth", "foot.bg"))
end)

test("skin paint: Strip and Cover color their textures as TestStrip and the combat cover do", function()
  -- Widgets.lua STRIP_FILL; OptionsCombat.lua the dim and its line
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local tex = function(mm) return mm.CreateFrame("Frame"):CreateTexture() end
  assertEqual((traceOn(m, nil, tex, function(t) S.Strip(t) end)), "#1:SetColorTexture(1,0.650,0.150,0.120)")
  assertEqual((traceOn(m, nil, tex, function(t) S.Strip(t, { kind = "sim" }) end)),
    "#1:SetColorTexture(0.350,0.800,1,0.120)")
  local text = traceOn(m, nil, function(mm)
    local f = mm.CreateFrame("Frame")
    local dim, line = f:CreateTexture(), f:CreateFontString()
    return dim, { line }
  end, function(dim) S.Cover(dim, { text = select(2, dim:GetParent():GetRegions()) }) end)
  assertEqual(text, "#1:SetColorTexture(0,0,0,0.600)\n#2:SetTextColor(0.667,0.667,0.667)")
end)

test("skin paint: MenuFrame on Ka0s Default is the shared popup menu, call for call", function()
  -- Widgets.lua EnsureMenu: a WHITE8X8 table with NO insets, then .06/.06/.08/.98 and 0/0/0/1
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local text = traceOn(m, nil, backdropFrame, function(f) S.MenuFrame(f) end)
  assertEqual(text, table.concat({
    '#1:SetBackdrop({bgFile="Interface\\\\Buttons\\\\WHITE8X8",edgeFile="Interface\\\\Buttons\\\\WHITE8X8",edgeSize=1})',
    "#1:SetBackdropColor(0.060,0.060,0.080,0.980)",
    "#1:SetBackdropBorderColor(0,0,0,1)",
  }, "\n"))
  local alt = backdropFrame(m)
  S.MenuFrame(alt, { alt = true })
  assertEqual(F.rgba(survey(m, alt).backdropBorderColor), F.tok(Skin, "ka0s", "menu.borderAlt"), "the row menu's edge")
  local pop = backdropFrame(m)
  pop:SetBackdrop({ bgFile = "art" })
  S.MenuFrame(pop, { popup = true })
  assertEqual(survey(m, pop).backdrop.bgFile, "art", "popup keeps its art")
  assertEqual(F.rgba(survey(m, pop).backdropColor), F.tok(Skin, "ka0s", "popup.bg"))
end)

test("skin paint: Tooltip leaves a library tooltip alone unless the skin colors tooltips", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local f = backdropFrame(m)
  f:SetBackdrop({ bgFile = "tip" })
  local text = traceOn(m, nil, function() return f end, function(t) S.Tooltip(t) end)
  assertEqual(text, "", "tooltip.* are nil in Ka0s Default")
  Skin:RegisterSkin({ key = "tips", tokens = { ["tooltip.bg"] = { 0.2, 0.1, 0, 0.9 } } })
  Skin:SetChoice(OWNER, "ka0s", "tips")
  assertEqual(F.rgba(survey(m, f).backdropColor), "0.200,0.100,0,0.900", "repainted live")
  assertEqual(survey(m, f).backdrop.bgFile, "tip", "its art kept")
end)

-- ── text, fonts, getters ─────────────────────────────────────────────────────────────────────

local LSM = { ["font:Ka0s Barlow"] = "Fonts\\Barlow.ttf", ["font:Ka0s Barlow SemiBold"] = "Fonts\\BarlowSB.ttf",
              ["statusbar:Blizzard"] = "Interface\\TargetingFrame\\UI-StatusBar" }

test("skin paint: Text colors a role, and a skin's font reaches it through the owner's font object", function()
  local m, Skin = F.env({ lsm = LSM })
  local S = F.owner(Skin, OWNER)
  local fs = m.CreateFrame("Frame"):CreateFontString(nil, "OVERLAY", "GameFontNormal")
  local stock = { name = "GameFontNormal", GetName = function(self) return self.name end }
  fs:SetFontObject(stock)
  S.Text(fs, "heading")
  assertEqual(F.rgba(survey(m, fs).textColor), F.tok(Skin, "ka0s", "text.heading"))
  assertTrue(fs:GetFontObject() == stock, "Ka0s Default sets no font")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  local obj = fs:GetFontObject()
  assertEqual(obj.name, "LibKa0sSkin_LootHistory_title", "the owner's title font object")
  assertEqual(obj.font[1], "Fonts\\BarlowSB.ttf"); assertEqual(obj.font[2], 14)
  assertEqual(obj.shadow[1], 1, "the shadow is the font object's (the 12.0.7 rule)")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertTrue(fs:GetFontObject() == stock, "the stock font object comes back")
end)

test("skin paint: Font and White put the body font and color on a string", function()
  local m, Skin = F.env({ lsm = LSM })
  local S = F.owner(Skin, OWNER, "glass")
  local fs = m.CreateFrame("Frame"):CreateFontString()
  S.Font(fs, 0.1, 0.2, 0.3)
  assertEqual(fs:GetFontObject().font[1], "Fonts\\Barlow.ttf")
  assertEqual(F.rgba(survey(m, fs).textColor), "0.100,0.200,0.300,1")
  local w = m.CreateFrame("Frame"):CreateFontString()
  S.White(w)
  assertEqual(F.rgba(survey(m, w).textColor), F.tok(Skin, "glass", "text.body"))
end)

test("skin paint: the getters answer the owner's skin", function()
  local _, Skin = F.env({ lsm = LSM })
  local S = F.owner(Skin, OWNER, "ember")
  local tokens = Skin:ResolveSkin("ember")
  assertEqual(F.rgba({ S.GetAccentColor() }), F.rgba(tokens["text.accent"]))
  assertEqual(F.rgba({ S.GetPanelColor() }), F.rgba(tokens["win.bg"]))
  assertEqual(F.owner(Skin, "Sleek", "obsidian").GetFont(), "Fonts\\Barlow.ttf", "the body face's path")
  local K = F.owner(Skin, "Plain")
  assertNil(K.GlowColor(), "no glow color in Ka0s Default: the host's stands")
  local chart = K.ChartStyle()
  assertTrue(chart.axis == Skin:ResolveSkin("ka0s")["chart.axis"], "ChartStyle reads chart.*")
  assertEqual(#chart.series, 21, "the series palette")
  local bar = K.BarStyle()
  assertEqual(bar.textureKey, "Blizzard"); assertEqual(bar.texture, "Interface\\TargetingFrame\\UI-StatusBar")
  assertFalse(bar.gloss)
  assertEqual(bar.fontKey, "Friz Quadrata TT")
  assertNil(Skin.painted[S], "a getter records nothing")
end)
