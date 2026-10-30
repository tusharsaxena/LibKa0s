-- tests/test_skin_stock_default.lua — LibKa0s-Skin-1.0's retired `opts.stockDefault` (LK-02 of
-- Ka0sAddonsCommonTasks docs/2026-10-30-SKIN_LIBRARY_FOLLOWUPS, ruling R-2, decisions D-04 and D-08).
-- The option once kept a template-built window (Quick Comms' callout popup, built on
-- SettingsFrameTemplate: its NineSlice with the title on it, its Bg, its ClosePanelButton) as the
-- client drew it while its owner drew Ka0s Default. R-2 retires that: Ka0s Default looks like Ka0s
-- Default everywhere, and a player who wants the client's look picks WoW Default.
--
-- What it pins: a stale `stockDefault = true` is ignored without error by every primitive that once
-- read it, so the target paints exactly as one painted without it; its hover and enable hooks run
-- under Ka0s Default; `opts.stock` stays the fade list it is under every skin (D-04); PageButton
-- forwards its opts (`stock`, `noBorder`, `noBg`) and a repaint replays them; P.unpaint gives a
-- TitleBar's text alignment back (D-08); the eui route is unchanged, its fallback now painted.
--
-- Every case runs on a fresh environment (tests/fixture_skin_paint.lua, tests/fixture_skin_eui.lua).

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil
local F = dofile("tests/fixture_skin_paint.lua")
local E = dofile("tests/fixture_skin_eui.lua")

local OWNER = "QuickComms"

local function survey(m, obj) return m.__paint(obj) end

--- A window as SettingsFrameTemplate builds one: a NineSlice with the title on it, a Bg texture
--- and a stock close button (its art in GetNormalTexture), no backdrop.
local function settingsWindow(m)
  local f = m.CreateFrame("Frame", nil, m.UIParent)
  rawset(f, "SetBackdrop", nil)
  m.__paintNineSlice(f)
  f.Bg = f:CreateTexture(nil, "BACKGROUND")
  f.NineSlice.Text = f.NineSlice:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.NineSlice.Text:SetTextColor(1, 0.82, 0, 1)
  local close = m.CreateFrame("Button", nil, f)
  rawset(close, "SetBackdrop", nil)
  local normal = close:CreateTexture()
  rawset(close, "GetNormalTexture", function() return normal end)
  f.ClosePanelButton, f.closeArt = close, normal
  return f
end

--- Paint the window the way Quick Comms' popup did, `stockDefault` on every part (`stale`), or
--- the same calls without it.
local function paint(S, f, stale)
  local function o(t) if stale then t.stockDefault = true end return t end
  S.Shell(f, o({ stock = { f.Bg } }))
  S.FadeNineSlice(f, o({}))
  S.TitleBar(f.NineSlice, o({ text = f.NineSlice.Text, noBg = true }))
  S.CloseButton(f.ClosePanelButton, o({}))
end

--- Assert the window wears `skin`'s look: the template art faded, the "x" drawn, the title recolored.
local function assertPainted(m, Skin, f, skin, label)
  for _, k in ipairs(m.__nineSliceKeys) do
    assertEqual(survey(m, f.NineSlice[k]).alpha, 0, label .. ": NineSlice." .. k .. " faded")
  end
  assertEqual(survey(m, f.Bg).alpha, 0, label .. ": the Bg faded (opts.stock, the fade list)")
  assertEqual(survey(m, f.closeArt).alpha, 0, label .. ": the close art faded")
  local glyph = F.region(Skin, f.ClosePanelButton, "glyph")
  assertEqual(glyph and survey(m, glyph).text, "x", label .. ": the close glyph drawn")
  assertEqual(F.rgba(survey(m, f.NineSlice.Text).textColor), F.tok(Skin, skin, "title.text"),
    label .. ": the title recolored")
end

--- A stock control of `kind` (template Left/Middle/Right pieces, no backdrop).
local function stockControl(m, kind)
  local f = m.CreateFrame(kind, nil, m.UIParent)
  rawset(f, "SetBackdrop", nil)
  f.Left, f.Middle, f.Right = f:CreateTexture(), f:CreateTexture(), f:CreateTexture()
  return f
end

-- ── Ka0s Default paints the Ka0s look ────────────────────────────────────────────────────────

test("skin stock retired: under Ka0s Default a stale stockDefault window is painted the Ka0s look", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local f = settingsWindow(m)
  paint(S, f, true)
  assertPainted(m, Skin, f, "ka0s", "Ka0s Default")
  assertNil(Skin.__regions[f.ClosePanelButton].stockKept, "no stock-kept mark")
  Skin:SetChoice(OWNER, "ka0s", "ember")
  assertPainted(m, Skin, f, "ember", "Ember")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertPainted(m, Skin, f, "ka0s", "a switch back to Ka0s Default")
end)

test("skin stock retired: a stale stockDefault paints exactly as the same calls without it", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local function traced(stale)
    local f = settingsWindow(m)
    local tr = F.tracer(m)
    for _, o in ipairs({ f, f.NineSlice, f.Bg, f.NineSlice.Text, f.ClosePanelButton, f.closeArt }) do
      tr.watch(o)
    end
    for _, k in ipairs(m.__nineSliceKeys) do tr.watch(f.NineSlice[k]) end
    tr.start()
    paint(S, f, stale)
    tr.stop(); tr.restore()
    return tr.text()
  end
  local plain, stale = traced(false), traced(true)
  assertTrue(#plain > 0, "the window was painted")
  assertEqual(stale, plain, "stockDefault = true is no option any more")
end)

test("skin stock retired: every primitive that once read stockDefault ignores it without error", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local build = {
    Shell = function() return settingsWindow(m) end,
    Panel = function() return m.CreateFrame("Frame", nil, m.UIParent, "BackdropTemplate") end,
    Inset = function() return m.CreateFrame("Frame", nil, m.UIParent, "BackdropTemplate") end,
    TitleBar = function()
      local f = m.CreateFrame("Frame", nil, m.UIParent)
      f.title = f:CreateFontString(); return f
    end,
    FadeNineSlice = function() return settingsWindow(m) end,
    Button = function() local b = stockControl(m, "Button"); b.text = b:CreateFontString(); return b end,
    EditBox = function() return stockControl(m, "EditBox") end,
    Dropdown = function() return stockControl(m, "Button") end,
    Slider = function() return stockControl(m, "Slider") end,
    Tab = function() local b = stockControl(m, "Button"); b.text = b:CreateFontString(); return b end,
    CloseButton = function() return settingsWindow(m).ClosePanelButton end,
  }
  local names = {}
  for name in pairs(build) do names[#names + 1] = name end
  table.sort(names)
  for _, name in ipairs(names) do
    local a, b = build[name](), build[name]()
    local ok, err = pcall(S[name], a, { stockDefault = true })
    assertTrue(ok, name .. " raised: " .. tostring(err))
    S[name](b, {})
    assertNil(Skin.__regions[a].stockKept, name .. ": no stock-kept mark")
    local ra, rb = Skin.painted[a].regions, Skin.painted[b].regions
    for key, r in pairs(rb) do
      if Skin.__ours[r] and type(r.IsShown) == "function" then
        local mine = ra[key]
        assertEqual(mine ~= nil and mine:IsShown(), r:IsShown(), name .. ": region " .. tostring(key))
      end
    end
    if rawget(a, "Left") then
      assertEqual(survey(m, a.Left).alpha, survey(m, b.Left).alpha, name .. ": the template piece")
    end
  end
end)

test("skin stock retired: a stale stockDefault target's hover and enable hooks run under Ka0s Default", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local b = m.CreateFrame("Button", nil, m.UIParent)
  rawset(b, "SetBackdrop", nil)
  local normal = b:CreateTexture()
  rawset(b, "GetNormalTexture", function() return normal end)
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  b.text:SetTextColor(1, 0.82, 0, 1)
  S.Button(b, { stockDefault = true })
  assertEqual(survey(m, normal).alpha, 0, "the stock art faded under Ka0s Default")
  assertEqual(F.rgba(survey(m, b.text).textColor), F.tok(Skin, "ka0s", "btn.text"), "the label painted")
  b:__fire("OnEnter")
  assertEqual(F.rgba(survey(m, b.text).textColor), F.tok(Skin, "ka0s", "btn.hover"), "the hover hook runs")
  b:__fire("OnLeave")
  assertEqual(F.rgba(survey(m, b.text).textColor), F.tok(Skin, "ka0s", "btn.text"), "and gives the rest back")
  local c = settingsWindow(m).ClosePanelButton
  S.CloseButton(c, { stockDefault = true })
  local glyph = F.region(Skin, c, "glyph")
  assertTrue(glyph ~= nil and survey(m, glyph).shown, "the close glyph shown under Ka0s Default")
  c:__fire("OnEnter")
  assertEqual(F.rgba(survey(m, glyph).textColor), F.tok(Skin, "ka0s", "close.hot"), "the close hover runs")
end)

test("skin stock retired: opts.stock stays the fade list under Ka0s Default", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local tab = m.CreateFrame("Button", nil, m.UIParent)
  rawset(tab, "SetBackdrop", nil)
  local art = tab:CreateTexture()
  S.Tab(tab, { stock = { art }, stockDefault = true })
  assertEqual(survey(m, art).alpha, 0, "the caller's art faded under Ka0s Default")
end)

-- ── PageButton forwards its opts ─────────────────────────────────────────────────────────────

test("skin stock retired: PageButton forwards stock, noBorder and noBg, and a repaint replays them", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local pb = m.CreateFrame("Button", nil, m.UIParent)
  rawset(pb, "SetBackdrop", nil)
  local art = pb:CreateTexture()
  S.PageButton(pb, "up", { stock = { art }, noBorder = true })
  assertEqual(survey(m, art).alpha, 0, "opts.stock faded")
  local top = F.region(Skin, pb, "edgeTop")
  assertTrue(top == nil or not survey(m, top).shown, "noBorder: no edge")
  assertEqual(F.region(Skin, pb, "arrow"):GetRotation(), math.pi / 2, "the arrow still turned to dir")
  local plain = m.CreateFrame("Button", nil, m.UIParent)
  rawset(plain, "SetBackdrop", nil)
  S.PageButton(plain, "up")
  assertTrue(survey(m, F.region(Skin, plain, "edgeTop")).shown, "without opts the edge is drawn")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  top = F.region(Skin, pb, "edgeTop")
  assertTrue(top == nil or not survey(m, top).shown, "the repaint replays noBorder")
  assertEqual(survey(m, art).alpha, 0, "and the fade list")
  local hb = m.CreateFrame("Button", nil, m.UIParent, "BackdropTemplate")
  S.PageButton(hb, "next", { noBg = true })
  assertEqual(F.rgba(survey(m, hb).backdropColor), "0,0,0,0", "noBg: a clear fill")
end)

-- ── P.unpaint gives a TitleBar's alignment back (D-08) ───────────────────────────────────────

test("skin stock retired: P.unpaint gives a TitleBar's text alignment back", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "forever")
  local bar = m.CreateFrame("Frame", nil, m.UIParent)
  bar.title = bar:CreateFontString()
  bar.title:SetJustifyH("LEFT")
  S.TitleBar(bar)
  assertEqual(bar.title:GetJustifyH(), Skin:ResolveSkin("forever")["title.align"], "WoW Forever aligns it")
  Skin.__P.unpaint(Skin.painted[bar], bar)
  assertEqual(bar.title:GetJustifyH(), "LEFT", "the title's own alignment back")
  S.TitleBar(bar)
  F.owner(Skin, "PrettyChat").FadeRegions(bar)
  assertEqual(bar.title:GetJustifyH(), "LEFT", "another owner's paint gives it back too")
end)

-- ── EllesmereUI ──────────────────────────────────────────────────────────────────────────────

test("skin stock retired: under eui the window goes to EllesmereUI; its fallback is painted", function()
  local m, Skin, eui = E.env()
  local S = Skin:RegisterOwner(OWNER, { get = function() return "eui", "ka0s" end })
  local f = settingsWindow(m)
  paint(S, f, true)
  assertEqual(survey(m, f.NineSlice.TopEdge).alpha, 0, "before EllesmereUI paints, Ka0s Default's look")
  eui.login()
  assertTrue(Skin.euiPainted[OWNER], "EllesmereUI paints the owner")
  assertEqual(#eui.callsFor("Shell", f), 1, "the window goes to EllesmereUI")
  assertEqual(#eui.callsFor("CloseButton", f.ClosePanelButton), 1, "and its close button")
  local call = eui.callsFor("Shell", f)[1]
  local opts = call and call.args[1]
  assertTrue(opts == nil or opts.stockDefault == nil, "stockDefault is never handed on: stripped")
  assertNil(Skin.euiRefused[OWNER], "nothing refused")
end)

test("skin stock retired: a refused EllesmereUI (fail closed) is the library's paint", function()
  local m, Skin, eui = E.env()
  local S = Skin:RegisterOwner(OWNER, { get = function() return "eui", "ka0s" end })
  local f = settingsWindow(m)
  eui.login()
  assertTrue(Skin.euiPainted[OWNER])
  Skin.euiRefused[OWNER] = "test: refused"
  paint(S, f, true)
  assertEqual(#eui.callsFor("Shell", f), 0, "never handed to a refused EllesmereUI")
  assertEqual(survey(m, f.NineSlice.TopEdge).alpha, 0, "the library paints it from the derived tokens")
  assertEqual(Skin:DrawsKey(OWNER), "eui", "the owner draws EllesmereUI's tokens")
end)
