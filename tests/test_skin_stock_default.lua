-- tests/test_skin_stock_default.lua — LibKa0s-Skin-1.0's `opts.stockDefault` (LK-05 of
-- Ka0sAddonsCommonTasks docs/2026-10-29-SKINNING_ROLLOUT, gap QC-G4): a window that deliberately
-- matches Blizzard's settings window (Quick Comms' callout popup and icon browser, built on
-- SettingsFrameTemplate: its NineSlice with the title on it, its Bg, its ClosePanelButton) keeps the
-- client's art under Ka0s Default and is skinned under every other skin and under EllesmereUI.
--
-- What it pins: under Ka0s Default a primitive given `opts.stockDefault` paints nothing and gives
-- back anything it painted before, so a live switch back to Ka0s Default is the stock window again;
-- under another skin it paints as it always did; its hover and enable hooks do nothing while the
-- target is stock; without the option Ka0s Default paints exactly as before; under the eui source a
-- call goes to EllesmereUI as before, the live fallback before EllesmereUI paints is Ka0s Default's
-- stock, and a refused EllesmereUI (fail closed) is the library's paint from the derived tokens.
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

--- Paint the window the way QC-G4 asks: every part with `stockDefault`.
local function paint(S, f)
  local opts = { stockDefault = true, stock = { f.Bg } }
  S.Shell(f, opts)
  S.FadeNineSlice(f, { stockDefault = true })
  S.TitleBar(f.NineSlice, { stockDefault = true, text = f.NineSlice.Text, noBg = true })
  S.CloseButton(f.ClosePanelButton, { stockDefault = true })
end

--- True when the window shows exactly the client's art and nothing of the library's.
local function isStock(m, Skin, f)
  for _, k in ipairs(m.__nineSliceKeys) do
    if survey(m, f.NineSlice[k]).alpha ~= 1 then return false, "NineSlice." .. k .. " faded" end
  end
  if survey(m, f.Bg).alpha ~= 1 then return false, "Bg faded" end
  if survey(m, f.closeArt).alpha ~= 1 then return false, "the close art faded" end
  if F.rgba(survey(m, f.NineSlice.Text).textColor) ~= "1,0.820,0,1" then return false, "the title recolored" end
  for _, target in ipairs({ f, f.NineSlice, f.ClosePanelButton }) do
    local rec = Skin.painted[target]
    for key, r in pairs(rec and rec.regions or {}) do
      if Skin.__ours[r] and type(r.IsShown) == "function" and r:IsShown() then
        return false, "a library region shown: " .. tostring(key)
      end
    end
  end
  return true
end

-- ── Ka0s Default and the other skins ─────────────────────────────────────────────────────────

test("skin stock default: under Ka0s Default a SettingsFrameTemplate window stays the client's", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local f = settingsWindow(m)
  paint(S, f)
  local ok, why = isStock(m, Skin, f)
  assertTrue(ok, why)
  assertTrue(Skin.painted[f] ~= nil, "still recorded, so a skin switch repaints it")
end)

test("skin stock default: another skin paints it, and a switch back gives the stock window back", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "obsidian")
  local f = settingsWindow(m)
  paint(S, f)
  assertEqual(survey(m, f.NineSlice.TopEdge).alpha, 0, "Obsidian fades the NineSlice")
  assertEqual(survey(m, f.Bg).alpha, 0, "and the Bg")
  assertEqual(survey(m, f.closeArt).alpha, 0, "and the close art")
  assertEqual(survey(m, F.region(Skin, f.ClosePanelButton, "glyph")).text, "x", "the close glyph drawn")
  assertEqual(F.rgba(survey(m, f.NineSlice.Text).textColor), F.tok(Skin, "obsidian", "title.text"))
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  local ok, why = isStock(m, Skin, f)
  assertTrue(ok, "back on Ka0s Default: " .. tostring(why))
  Skin:SetChoice(OWNER, "ka0s", "ember")
  assertEqual(survey(m, f.NineSlice.TopEdge).alpha, 0, "Ember paints it again")
  assertEqual(F.rgba(survey(m, f.NineSlice.Text).textColor), F.tok(Skin, "ember", "title.text"))
end)

test("skin stock default: TitleBar gives back the title's justification with its color", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "forever")
  local f = settingsWindow(m)
  f.NineSlice.Text:SetJustifyH("LEFT")
  paint(S, f)
  assertEqual(f.NineSlice.Text:GetJustifyH(), Skin:ResolveSkin("forever")["title.align"], "WoW Forever centers it")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertEqual(f.NineSlice.Text:GetJustifyH(), "LEFT", "the template's own alignment")
end)

test("skin stock default: a stock target's hover and enable hooks do nothing under Ka0s Default", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "obsidian")
  local b = m.CreateFrame("Button", nil, m.UIParent)
  rawset(b, "SetBackdrop", nil)
  local normal = b:CreateTexture()
  rawset(b, "GetNormalTexture", function() return normal end)
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  b.text:SetTextColor(1, 0.82, 0, 1)
  S.Button(b, { stockDefault = true })
  b:__fire("OnEnter")
  assertEqual(F.rgba(survey(m, b.text).textColor), F.tok(Skin, "obsidian", "btn.hover"), "hooked under Obsidian")
  b:__fire("OnLeave")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertEqual(F.rgba(survey(m, b.text).textColor), "1,0.820,0,1", "the stock label color back")
  assertEqual(survey(m, normal).alpha, 1, "the stock art back")
  b:__fire("OnEnter")
  assertEqual(F.rgba(survey(m, b.text).textColor), "1,0.820,0,1", "the hover hook is inert while stock")
  b:__fire("OnDisable")
  assertEqual(F.rgba(survey(m, b.text).textColor), "1,0.820,0,1", "and so is the enable hook")
  local c = settingsWindow(m).ClosePanelButton
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  S.CloseButton(c, { stockDefault = true })
  local glyph = F.region(Skin, c, "glyph")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  local before = F.rgba(survey(m, glyph).textColor)
  c:__fire("OnEnter")
  assertEqual(F.rgba(survey(m, glyph).textColor), before, "the close button's hover too")
  assertTrue(not survey(m, glyph).shown, "and its glyph hidden")
end)

test("skin stock default: the stock mark leaves with the record: an Untrack or another owner clears it", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local b = m.CreateFrame("Button", nil, m.UIParent)
  rawset(b, "SetBackdrop", nil)
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  S.Button(b, { stockDefault = true })
  assertTrue(Skin.__regions[b].stockKept == true, "kept stock under Ka0s Default")
  Skin:Untrack(b)
  S.WhiteButtonLabel(b)
  assertNil(Skin.__regions[b].stockKept, "a primitive that never asks for stock, after an Untrack: no mark")
  assertEqual(F.rgba(survey(m, b.text).textColor), F.tok(Skin, "ka0s", "btn.text"), "and it paints")
  S.Button(b, { stockDefault = true })
  assertTrue(Skin.__regions[b].stockKept == true, "kept stock again")
  F.owner(Skin, "PrettyChat").WhiteButtonLabel(b)
  assertNil(Skin.__regions[b].stockKept, "another owner's paint clears it")
end)

test("skin stock default: Slider, EditBox and Tab take the option through the same mechanism", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local function stock(kind)
    local f = m.CreateFrame(kind, nil, m.UIParent)
    rawset(f, "SetBackdrop", nil)
    f.Left, f.Middle, f.Right = f:CreateTexture(), f:CreateTexture(), f:CreateTexture()
    return f
  end
  local slider, eb, tab = stock("Slider"), stock("EditBox"), stock("Button")
  tab.text = tab:CreateFontString()
  S.Slider(slider, { stockDefault = true })
  S.EditBox(eb, { stockDefault = true })
  S.Tab(tab, { stockDefault = true })
  for name, f in pairs({ Slider = slider, EditBox = eb, Tab = tab }) do
    assertEqual(survey(m, f.Left).alpha, 1, name .. ": stock under Ka0s Default")
  end
  Skin:SetChoice(OWNER, "ka0s", "glass")
  for name, f in pairs({ Slider = slider, EditBox = eb, Tab = tab }) do
    assertEqual(survey(m, f.Left).alpha, 0, name .. ": painted under Glass")
  end
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  for name, f in pairs({ Slider = slider, EditBox = eb, Tab = tab }) do
    assertEqual(survey(m, f.Left).alpha, 1, name .. ": stock again")
  end
end)

test("skin stock default: without the option Ka0s Default paints exactly as before", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local f, g = settingsWindow(m), settingsWindow(m)
  local tr = F.tracer(m)
  tr.watch(f); tr.watch(f.NineSlice); tr.watch(f.Bg); tr.watch(f.NineSlice.Text)
  tr.start()
  S.Shell(f, { stock = { f.Bg } }); S.FadeNineSlice(f); S.TitleBar(f.NineSlice, { text = f.NineSlice.Text, noBg = true })
  tr.stop(); tr.restore()
  local tr2 = F.tracer(m)
  tr2.watch(g); tr2.watch(g.NineSlice); tr2.watch(g.Bg); tr2.watch(g.NineSlice.Text)
  tr2.start()
  S.Shell(g, { stock = { g.Bg }, stockDefault = false })
  S.FadeNineSlice(g, { stockDefault = false })
  S.TitleBar(g.NineSlice, { text = g.NineSlice.Text, noBg = true, stockDefault = false })
  tr2.stop(); tr2.restore()
  assertEqual(tr2.text(), tr.text(), "stockDefault = false is no option")
  assertEqual(survey(m, f.NineSlice.TopEdge).alpha, 0, "Ka0s Default fades the template, as since SkinPaint minor 6")
  assertEqual(survey(m, f.Bg).alpha, 0)
end)

-- ── EllesmereUI ──────────────────────────────────────────────────────────────────────────────

test("skin stock default: under eui the window goes to EllesmereUI; its fallback is stock", function()
  local m, Skin, eui = E.env()
  local S = Skin:RegisterOwner(OWNER, { get = function() return "eui", "ka0s" end })
  local f = settingsWindow(m)
  paint(S, f)
  local ok, why = isStock(m, Skin, f)
  assertTrue(ok, "before EllesmereUI paints, the owner wears Ka0s Default: stock (" .. tostring(why) .. ")")
  eui.login()
  assertTrue(Skin.euiPainted[OWNER], "EllesmereUI paints the owner")
  assertEqual(#eui.callsFor("Shell", f), 1, "the window goes to EllesmereUI")
  assertEqual(#eui.callsFor("CloseButton", f.ClosePanelButton), 1, "and its close button")
  local call = eui.callsFor("Shell", f)[1]
  local opts = call and call.args[1]
  assertTrue(opts == nil or opts.stockDefault == nil, "stockDefault is the library's: stripped")
  assertNil(Skin.euiRefused[OWNER], "nothing refused")
end)

test("skin stock default: a refused EllesmereUI (fail closed) is the library's paint, never stock", function()
  local m, Skin, eui = E.env()
  local S = Skin:RegisterOwner(OWNER, { get = function() return "eui", "ka0s" end })
  local f = settingsWindow(m)
  eui.login()
  assertTrue(Skin.euiPainted[OWNER])
  Skin.euiRefused[OWNER] = "test: refused"
  paint(S, f)
  assertEqual(#eui.callsFor("Shell", f), 0, "never handed to a refused EllesmereUI")
  assertEqual(survey(m, f.NineSlice.TopEdge).alpha, 0, "the library paints it from the derived tokens")
  assertEqual(Skin:__DrawsKey(OWNER), "eui", "the owner draws EllesmereUI's tokens")
end)
