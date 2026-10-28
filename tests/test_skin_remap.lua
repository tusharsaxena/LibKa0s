-- tests/test_skin_remap.lua — LibKa0s-Skin-1.0's token remap on the box and button primitives
-- (LK-02 of Ka0sAddonsCommonTasks docs/2026-10-29-SKINNING_ROLLOUT): `opts.tokens` on `Shell`,
-- `Panel`, `Inset`, `Card` and `Button` names, per slot, the library or owner token a slot paints
-- from instead of the primitive's own (a danger button, a caution callout, an opaque modal, an
-- alternate card fill). Token NAMES, never values.
--
-- What it pins: no `opts.tokens` (or an empty one) paints exactly what the primitive painted before;
-- each slot paints its named token, a fill slot carrying that token's gradient (or none); the remap is
-- recorded, so a skin switch replays it and a button's hover and enable hooks keep it; an owner token
-- resolves in a slot; a name no token carries, or a value where a name belongs, is ignored for that
-- slot and logged once; under the eui source a remapped call is painted by the library from
-- EllesmereUI's colors, never handed to EllesmereUI, while a plain call still is.
--
-- Every case runs on a fresh environment (tests/fixture_skin_paint.lua, tests/fixture_skin_eui.lua).

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertNil
local F = dofile("tests/fixture_skin_paint.lua")
local E = dofile("tests/fixture_skin_eui.lua")

local OWNER = "DpsRace"

local DANGER_BG, DANGER_EDGE = { 0.35, 0.08, 0.08, 0.9 }, { 0.8, 0.2, 0.2, 0.9 }
local DANGER_TEXT, DANGER_HOT = { 1, 0.6, 0.6, 1 }, { 1, 0.32, 0.32, 1 }
local MODAL = { 0.05, 0.05, 0.06, 1 }
local CALLOUT_BG, CALLOUT_EDGE = { 1, 0.72, 0.29, 0.07 }, { 1, 0.72, 0.29, 0.35 }

local function tokens()
  return {
    ["dr.dangerBg"] = { default = DANGER_BG, follow = "btn.bg" },
    ["dr.dangerEdge"] = { default = DANGER_EDGE, follow = "sem.statusBad" },
    ["dr.dangerText"] = { default = DANGER_TEXT, follow = "sem.statusBad" },
    ["dr.dangerHot"] = { default = DANGER_HOT, follow = "sem.bad" },
    ["dr.modal"] = { default = MODAL, follow = "win.bg", skins = { midnight = { 0.1, 0.05, 0.15, 1 } } },
    ["dr.calloutBg"] = { default = CALLOUT_BG, follow = "card.bg" },
    ["dr.calloutEdge"] = { default = CALLOUT_EDGE, follow = "sem.warn" },
  }
end

local function owner(Skin, skin)
  local log = {}
  local S = Skin:RegisterOwner(OWNER, {
    get = function() return "ka0s", skin or "ka0s" end,
    log = function(line) log[#log + 1] = line end,
    tokens = tokens(),
  })
  return S, log
end

local function survey(m, obj) return m.__paint(obj) end

local function button(m)
  local b = m.CreateFrame("Button", nil, m.UIParent, "BackdropTemplate")
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  return b
end

local function card(m)
  local f = m.CreateFrame("Frame", nil, m.UIParent, "BackdropTemplate")
  f.head = f:CreateFontString(nil, "OVERLAY")
  f.body = f:CreateFontString(nil, "OVERLAY")
  return f
end

--- The paint trace of `paint(S, frame)` on a fresh environment's frame from `make`.
local function trace(make, paint)
  local m, Skin = F.env()
  local S = owner(Skin)
  local tr = F.tracer(m)
  local f = make(m)
  tr.watch(f)
  tr.start(); paint(S, f); tr.stop(); tr.restore()
  return tr.text()
end

test("skin remap: no opts.tokens, or an empty one, paints exactly what the primitive painted", function()
  local cases = {
    { F.window, function(S, f) S.Shell(f) end, function(S, f) S.Shell(f, { tokens = {} }) end },
    { card, function(S, f) S.Panel(f) end, function(S, f) S.Panel(f, { tokens = {} }) end },
    { card, function(S, f) S.Inset(f) end, function(S, f) S.Inset(f, { tokens = {} }) end },
    { card, function(S, f) S.Card(f, { title = f.head }) end,
      function(S, f) S.Card(f, { title = f.head, tokens = {} }) end },
    { button, function(S, f) S.Button(f) end, function(S, f) S.Button(f, { tokens = {} }) end },
  }
  for i, c in ipairs(cases) do
    local plain, empty = trace(c[1], c[2]), trace(c[1], c[3])
    assertTrue(#plain > 0, "case " .. i .. " paints")
    assertEqual(empty, plain, "case " .. i .. ": an empty remap is no remap")
  end
end)

test("skin remap: a danger button paints its fill, edge, label and hover from owner tokens", function()
  local m, Skin = F.env()
  local S = owner(Skin)
  local b = button(m)
  S.Button(b, { tokens = { bg = "dr.dangerBg", border = "dr.dangerEdge", text = "dr.dangerText",
                           hover = "dr.dangerHot" } })
  local sv = survey(m, b)
  assertEqual(F.rgba(sv.backdropColor), F.rgba(DANGER_BG), "the danger fill")
  assertEqual(F.rgba(sv.backdropBorderColor), F.rgba(DANGER_EDGE), "the danger edge")
  assertEqual(F.rgba(survey(m, b.text).textColor), F.rgba(DANGER_TEXT), "the danger label")
  b:__fire("OnEnter")
  assertEqual(F.rgba(survey(m, b.text).textColor), F.rgba(DANGER_HOT), "the hover keeps the remap")
  b:__fire("OnLeave")
  assertEqual(F.rgba(survey(m, b.text).textColor), F.rgba(DANGER_TEXT), "and the rest color")
  local plain = button(m)
  S.Button(plain)
  assertEqual(F.rgba(survey(m, plain).backdropColor), F.tok(Skin, "ka0s", "btn.bg"), "another button is untouched")
end)

test("skin remap: a skin switch replays the remap, and a fill slot drops the gradient it replaces", function()
  local m, Skin = F.env()
  local S = owner(Skin)
  local b = button(m)
  S.Button(b, { tokens = { bg = "dr.dangerBg", hover = "dr.dangerHot" } })
  Skin:SetChoice(OWNER, "ka0s", "ember")
  local fill = survey(m, b)
  assertEqual(F.rgba(fill.backdropColor), F.tok(Skin, "ember", "btn.bg"),
    "ember: the owner token follows btn.bg's flat value")
  local grad = F.region(Skin, b, "grad")
  assertTrue(grad == nil or not grad:IsShown(), "ember's button gradient is not drawn over a remapped fill")
  b:__fire("OnEnter")
  assertEqual(F.rgba(survey(m, b.text).textColor), F.tok(Skin, "ember", "sem.bad"), "hover in ember's followed color")
  local plain = button(m)
  S.Button(plain)
  local g = F.region(Skin, plain, "grad")
  assertTrue(g ~= nil and g:IsShown(), "an unremapped button keeps ember's gradient")
end)

test("skin remap: a disabled remapped button reads its disabled slot, else text.disabled", function()
  local m, Skin = F.env()
  local S = owner(Skin)
  local b = button(m)
  local on = true
  rawset(b, "IsEnabled", function() return on end)
  S.Button(b, { tokens = { text = "dr.dangerText" } })
  on = false; b:__fire("OnDisable")
  assertEqual(F.rgba(survey(m, b.text).textColor), F.tok(Skin, "ka0s", "text.disabled"), "text.disabled")
  on = true; b:__fire("OnEnable")
  assertEqual(F.rgba(survey(m, b.text).textColor), F.rgba(DANGER_TEXT), "back to its remapped label")
  local c = button(m)
  local cOn = true
  rawset(c, "IsEnabled", function() return cOn end)
  S.Button(c, { tokens = { disabled = "dr.dangerEdge" } })
  cOn = false; c:__fire("OnDisable")
  assertEqual(F.rgba(survey(m, c.text).textColor), F.rgba(DANGER_EDGE), "a remapped disabled slot")
end)

test("skin remap: an opaque modal Shell paints its window fill flat from the named token", function()
  local m, Skin = F.env()
  local S = owner(Skin, "midnight")
  local f, plain = F.window(m), F.window(m)
  S.Shell(f, { tokens = { bg = "dr.modal" } })
  S.Shell(plain)
  assertEqual(F.rgba(survey(m, f).backdropColor), "0.100,0.050,0.150,1", "midnight's own entry for dr.modal")
  local grad = Skin.__regions[f].grad
  assertTrue(grad == nil or not grad:IsShown(), "no window gradient over the opaque fill")
  assertTrue(Skin.__regions[plain].grad:IsShown(), "the plain window keeps midnight's gradient")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertEqual(F.rgba(survey(m, f).backdropColor), F.rgba(MODAL), "Ka0s Default: the token's default, replayed")
  assertEqual(F.rgba(survey(m, plain).backdropColor), F.tok(Skin, "ka0s", "win.bg"), "the plain window, win.bg")
end)

test("skin remap: Shell's border, inner rule, top bar and title text slots", function()
  local m, Skin = F.env()
  local S = owner(Skin)
  local f = F.window(m)
  S.Shell(f, { tokens = { border = "dr.dangerEdge", inner = "dr.calloutEdge", top = "dr.calloutBg",
                          text = "dr.dangerText" } })
  local r = Skin.__regions[f]
  assertEqual(F.rgba(survey(m, r.edgeTop).color), F.rgba(DANGER_EDGE), "the edge")
  assertEqual(F.rgba(survey(m, r.innerTop).color), F.rgba(CALLOUT_EDGE), "the inner rule")
  assertEqual(F.rgba(survey(m, r.top).color), F.rgba(CALLOUT_BG), "the top bar")
  assertEqual(F.rgba(survey(m, f.title).textColor), F.rgba(DANGER_TEXT), "the title text")
end)

test("skin remap: a caution callout Panel and Card, an Inset and the nav rail's recolor", function()
  local m, Skin = F.env()
  local S = owner(Skin)
  local p = card(m)
  S.Panel(p, { tokens = { bg = "dr.calloutBg", border = "dr.calloutEdge" } })
  assertEqual(F.rgba(survey(m, p).backdropColor), F.rgba(CALLOUT_BG), "the panel's fill")
  assertEqual(F.rgba(survey(m, p).backdropBorderColor), F.rgba(CALLOUT_EDGE), "and its edge")
  local c = card(m)
  S.Card(c, { title = c.head, text = c.body,
              tokens = { bg = "dr.calloutBg", border = "dr.calloutEdge", title = "sem.warn", text = "dr.dangerText" } })
  assertEqual(F.rgba(survey(m, c).backdropColor), F.rgba(CALLOUT_BG), "the card's fill")
  assertEqual(F.rgba(survey(m, c).backdropBorderColor), F.rgba(CALLOUT_EDGE), "its edge")
  assertEqual(F.rgba(survey(m, c.head).textColor), F.tok(Skin, "ka0s", "sem.warn"), "its title, a library token")
  assertEqual(F.rgba(survey(m, c.body).textColor), F.rgba(DANGER_TEXT), "its text, an owner token")
  local i = card(m)
  S.Inset(i, { tokens = { bg = "panel.bg" } })
  assertEqual(F.rgba(survey(m, i).backdropColor), F.tok(Skin, "ka0s", "panel.bg"), "an inset's fill")
  assertEqual(F.rgba(survey(m, i).backdropBorderColor), F.tok(Skin, "ka0s", "input.border"), "its own edge")
  local n = card(m)
  n:SetBackdrop({ bgFile = "x" })
  S.Panel(n, { nav = true, tokens = { bg = "dr.modal" } })
  assertEqual(F.rgba(survey(m, n).backdropColor), F.rgba(MODAL), "the nav rail's recolor reads the slot")
end)

test("skin remap: a name no token carries, or a value, is ignored for its slot and logged once", function()
  local m, Skin = F.env()
  local S, log = owner(Skin)
  local b = button(m)
  local opts = { tokens = { bg = "dr.nope", border = DANGER_EDGE, text = "dr.dangerText" } }
  S.Button(b, opts)
  assertEqual(F.rgba(survey(m, b).backdropColor), F.tok(Skin, "ka0s", "btn.bg"), "the unknown name: btn.bg")
  assertEqual(F.rgba(survey(m, b).backdropBorderColor), F.tok(Skin, "ka0s", "btn.border"), "the value: btn.border")
  assertEqual(F.rgba(survey(m, b.text).textColor), F.rgba(DANGER_TEXT), "the good slot still lands")
  assertEqual(#log, 2, "one line per bad slot")
  S.Button(b, opts)
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(#log, 2, "a repeat and a repaint log nothing more")
end)

test("skin remap: the record keeps the caller's remap, so a repaint replays it", function()
  local m, Skin = F.env()
  local S = owner(Skin)
  local b = button(m)
  local opts = { tokens = { bg = "dr.dangerBg" } }
  S.Button(b, opts)
  assertTrue(Skin.painted[b].calls.Button[1] == opts, "recorded as given")
  assertEqual(Skin:Repaint(OWNER), 1, "one call replayed")
  assertEqual(F.rgba(survey(m, b).backdropColor), F.rgba(DANGER_BG), "still the danger fill")
end)

test("skin remap: under eui a remapped call is the library's, from EllesmereUI's colors", function()
  local m, Skin, eui = E.env()
  local S = Skin:RegisterOwner(OWNER, { get = function() return "eui", "ka0s" end, tokens = tokens() })
  local danger, plain, win = button(m), button(m), F.window(m)
  S.Button(danger, { tokens = { bg = "dr.dangerBg", border = "dr.dangerEdge" } })
  S.Button(plain)
  S.Shell(win, { tokens = { bg = "dr.modal" } })
  eui.login()
  assertTrue(Skin.euiPainted[OWNER], "EllesmereUI paints the owner")
  assertEqual(#eui.callsFor("Button", plain), 1, "a plain button goes to EllesmereUI")
  assertEqual(#eui.callsFor("Button", danger), 0, "a remapped button never does")
  assertEqual(#eui.callsFor("Shell", win), 0, "nor a remapped window")
  assertEqual(F.rgba(survey(m, danger).backdropColor), F.tok(Skin, "ka0s", "btn.bg"),
    "dr.dangerBg follows btn.bg, which EllesmereUI does not drive: Ka0s Default's btn.bg")
  assertEqual(F.rgba(survey(m, win).backdropColor), F.rgba(eui.panel), "dr.modal follows win.bg: EllesmereUI's panel color")
  S.Button(danger, { tokens = { bg = "dr.dangerBg" } })
  assertEqual(#eui.callsFor("Button", danger), 0, "a later remapped call stays the library's")
  assertNil(Skin.euiRefused[OWNER], "nothing refused")
end)
