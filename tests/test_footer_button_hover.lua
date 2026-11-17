-- tests/test_footer_button_hover.lua — a library window's footer button lights clearly on hover in every
-- skin (SR2-L3 of Ka0sAddonsCommonTasks docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS, the owner's answer 3
-- of SR2_SMOKE_ROUND2.md: footer buttons follow ruling 4).
--
-- THE DEFECT. The boxed text buttons along the bottom of a library window (the skin picker's Apply
-- and Apply to all, the icon browser's Choose and Cancel, an AceConfig confirm's two, the sim panel's
-- Start and its controls) paint their label in a rest color and repaint it under the pointer. In some
-- skins the two were one color in two shades, or the same color: Azeroth's `btn.hover` (white) stood
-- 15.1 ΔE00 off its cream `btn.text`; four skins' `btnPrimary.hover` was their `btnPrimary.text` or
-- a tint of it (WoW Midnight 0.0, Ember 0.0, Obsidian 10.8, Glass 11.1, WoW Forever 11.9); and the
-- sim panel's controls hovered `text.accent`, 16.3 off Azeroth's `sem.stepReady`.
--
-- THE RULE. A footer button keeps its hover glow, and its hovered label stands at least
-- HOVER_DE00_MIN (20, the title bar's floor, tests/fixture_de00.lua) off its rest label in every
-- skin, legible on the button's own fill (its contrast at least the rest label's, or 4.5:1). The
-- route is the smallest per skin: a hover token that already clears the floor keeps its value (Ka0s
-- Default's gold is LootHistory's flat button, pinned in tests/test_skin.lua); where it does not, the
-- skin's `text.link` when that clears it, else the nearest color of the link's own family that does.
-- So Azeroth's `btn.hover` is #FFF800, its link #FFEB33's saturated twin (the link itself stands
-- 19.1 off the cream); and the sim panel's controls hover `text.link` (SimPanelRender's TOKENS
-- `hot`), which clears every skin.
--
-- A PRIMARY BUTTON HOVERS BY ITS FILL (SR2-L5, the owner's option C of the SR2-L3 review call). On a
-- bright primary fill (Obsidian's blue, Glass's lavender, Ember's orange, WoW Forever's tan) the only
-- label both legible and 20 off the rest was near-black, so SR2-L3 had exempted four skins. Now the
-- label keeps `btnPrimary.text` under the pointer, the glow stays, and the button's fill repaints in
-- `btnPrimary.hoverBg` (a gradient pair `btnPrimary.hoverBgTop` / `btnPrimary.hoverBgBottom` exactly
-- where `btnPrimary.bg` is one), back to `btnPrimary.bg` on leave. Every skin: the hover fill stands
-- at least HOVER_DE00_MIN off the rest fill, both composited over the window and a gradient read as
-- the mean of its two stops, and the label reads on it at least as well as at rest, or 4.5:1. No
-- exemption. `btnPrimary.hover` stays in the schema for a host that reads it; no painter does.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local F = dofile("tests/fixture_skin_paint.lua")
local DE = dofile("tests/fixture_de00.lua")
local PK = dofile("tests/fixture_skin_picker.lua")
local A = dofile("tests/fixture_skin_ace.lua")

local KEYS = { "ka0s", "obsidian", "azeroth", "glass", "contrast", "ember", "wow", "midnight",
  "forever" }
local FLOOR, LEGIBLE = DE.HOVER_DE00_MIN, 4.5
local de00 = DE.de00

local function skinLib() return T.mocks.LibStub("LibKa0s-Skin-1.0") end

local function linear(v)
  if v <= 0.03928 then return v / 12.92 end
  return ((v + 0.055) / 1.055) ^ 2.4
end
local function luminance(c) return 0.2126 * linear(c[1]) + 0.7152 * linear(c[2]) + 0.0722 * linear(c[3]) end
local function over(c, under)
  local a = c[4] or 1
  return { c[1] * a + under[1] * (1 - a), c[2] * a + under[2] * (1 - a), c[3] * a + under[3] * (1 - a), 1 }
end
local function ratio(x, y)
  local a, b = luminance(x), luminance(y)
  if a < b then a, b = b, a end
  return (a + 0.05) / (b + 0.05)
end
local function hex(c) return ("#%02X%02X%02X"):format(
  math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5)) end

--- The fill a `base` button draws on, opaque: its gradient's midpoint when it has one, over the
--- window (tests/test_skin_button_contrast.lua's reading).
--- `name` the fill token, `btnPrimary.hoverBg` for a primary's hover (its pair `<name>Top` /
--- `<name>Bottom`, read as the mean of the two stops).
local function fillOf(t, base, name)
  name = name or base .. ".bg"
  local win = over(t["win.bg"], { 0, 0, 0, 1 })
  local top, bottom = t[name .. "Top"], t[name .. "Bottom"]
  if type(top) == "table" and type(bottom) == "table" then
    local a, b = over(top, win), over(bottom, win)
    return { (a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2, 1 }
  end
  return over(t[name], win)
end

--- Hover against rest on `fill`: the floor, and the hover at least as legible as the rest or 4.5:1.
local function holds(where, rest, hover, fill)
  local d = de00(rest, hover)
  assertTrue(d >= FLOOR, ("%s: hover %s ΔE00 %.1f off rest %s, want >= %d"):format(
    where, hex(hover), d, hex(rest), FLOOR))
  local on, was = ratio(over(hover, fill), fill), ratio(over(rest, fill), fill)
  assertTrue(on >= was or on >= LEGIBLE, ("%s: hover %.2f:1 on its fill, under the rest's %.2f:1 and %.1f:1")
    :format(where, on, was, LEGIBLE))
end

-- ── the tokens, every skin ───────────────────────────────────────────────────────────────────

test("footer button hover: a push button's hovered label is clearly another color than its rest in every skin", function()
  -- red under: Azeroth's white `btn.hover`, 15.1 off its cream `btn.text`.
  for _, key in ipairs(KEYS) do
    local t = skinLib():ResolveSkin(key)
    holds(key .. "'s btn", t["btn.text"], t["btn.hover"], fillOf(t, "btn"))
  end
end)

test("footer button hover: a primary button's hovered fill is clearly another color than its rest in every skin", function()
  -- SR2-L5: no exemption. red under: no `btnPrimary.hoverBg` in any skin.
  for _, key in ipairs(KEYS) do
    local t = skinLib():ResolveSkin(key)
    assertTrue(type(t["btnPrimary.hoverBg"]) == "table", key .. ": btnPrimary.hoverBg is set")
    local rest, hot = fillOf(t, "btnPrimary"), fillOf(t, "btnPrimary", "btnPrimary.hoverBg")
    local d = de00(rest, hot)
    assertTrue(d >= FLOOR, ("%s: hover fill %s ΔE00 %.1f off rest fill %s, want >= %d"):format(
      key, hex(hot), d, hex(rest), FLOOR))
  end
end)

test("footer button hover: a primary's label reads on its hover fill at least as well as at rest, or 4.5:1", function()
  for _, key in ipairs(KEYS) do
    local t = skinLib():ResolveSkin(key)
    local label = t["btnPrimary.text"]
    local rest, hot = fillOf(t, "btnPrimary"), fillOf(t, "btnPrimary", "btnPrimary.hoverBg")
    local on, was = ratio(over(label, hot), hot), ratio(over(label, rest), rest)
    assertTrue(on >= math.min(was, LEGIBLE), ("%s: btnPrimary.text %.2f:1 on the hover fill, under the rest's %.2f:1 and %.1f:1")
      :format(key, on, was, LEGIBLE))
  end
end)

test("footer button hover: a primary's hover fill is a gradient exactly where its rest fill is one", function()
  -- Typed as `btnPrimary.bg` is: Azeroth, Ember, WoW Default and WoW Midnight draw a pair.
  for _, key in ipairs(KEYS) do
    local t = skinLib():ResolveSkin(key)
    local restGrad = type(t["btnPrimary.bgTop"]) == "table" and type(t["btnPrimary.bgBottom"]) == "table"
    local hotGrad = type(t["btnPrimary.hoverBgTop"]) == "table" and type(t["btnPrimary.hoverBgBottom"]) == "table"
    assertEqual(hotGrad, restGrad, key .. ": hoverBg's gradient pair follows bg's")
  end
end)

test("footer button hover: the retuned hovers are the link or its own family", function()
  -- SR2-L3's picks, pinned. `btn.text` and `btnPrimary.text` do not move.
  local az, mid = skinLib():ResolveSkin("azeroth"), skinLib():ResolveSkin("midnight")
  assertEqual(hex(az["btn.hover"]), "#FFF800", "Azeroth's btn.hover, its link's saturated twin")
  assertTrue(de00(az["btn.hover"], az["text.link"]) < 5, "within 5 ΔE00 of Azeroth's link")
  assertEqual(hex(az["btn.text"]), "#F2E3BD", "Azeroth's btn.text, unchanged")
  -- SR2-L3's value, kept: `btnPrimary.hover` is read by no painter since SR2-L5, only by a host.
  assertEqual(hex(mid["btnPrimary.hover"]), hex(mid["text.link"]), "WoW Midnight's btnPrimary.hover, its link")
  assertEqual(hex(mid["btnPrimary.text"]), "#FFFFFF", "WoW Midnight's btnPrimary.text, unchanged")
end)

test("footer button hover: the sim panel's controls hover in the link color, clear of their rest", function()
  -- red under: the controls' `text.accent`, 16.3 off Azeroth's `sem.stepReady`.
  for _, key in ipairs(KEYS) do
    local t = skinLib():ResolveSkin(key)
    holds(key .. "'s sim control", t["sem.stepReady"], t["text.link"], over(t["win.bg"], { 0, 0, 0, 1 }))
  end
end)

-- ── the acceptance cases: the label repaints on enter and back on leave ──────────────────────

local function textColor(m, fs) return F.rgba(m.__paint(fs).textColor) end
--- A token's color as "r,g,b,1": what a three-argument SetTextColor records.
local function tok3(Skin, skin, name)
  local c = Skin:ResolveSkin(skin)[name]
  return F.rgba({ c[1], c[2], c[3], 1 })
end

for _, key in ipairs(KEYS) do
  test("footer button hover: the skin picker's Apply to all lights its label on enter, rest on leave (" .. key .. ")", function()
    local m, Skin, lib = PK.env()
    local store = PK.register(Skin, PK.OWNER, key)
    local b = PK.instance(lib, PK.OWNER).SkinPicker(PK.specFor(store)).applyAll
    assertEqual(textColor(m, b.text), F.tok(Skin, key, "btn.text"), "at rest")
    b:__fire("OnEnter")
    assertEqual(textColor(m, b.text), F.tok(Skin, key, "btn.hover"), "under the pointer")
    b:__fire("OnLeave")
    assertEqual(textColor(m, b.text), F.tok(Skin, key, "btn.text"), "at rest again")
  end)

  test("footer button hover: the skin picker's Apply repaints its fill on enter and back on leave, its label kept (" .. key .. ")", function()
    -- SR2-L5. red under: the fill never moved and the label repainted to `btnPrimary.hover`.
    local m, Skin, lib = PK.env()
    local store = PK.register(Skin, PK.OWNER, key)
    local b = PK.instance(lib, PK.OWNER).SkinPicker(PK.specFor(store)).apply
    local t = Skin:ResolveSkin(key)
    local function fill() return F.rgba(m.__paint(b).backdropColor) end
    local function grad()
      local g = Skin.painted[b] and Skin.painted[b].regions.grad
      local gr = g and g:IsShown() and m.__paint(g).gradient
      return gr and F.rgba({ gr.max.r, gr.max.g, gr.max.b, gr.max.a }) or "none"
    end
    local function want(name)
      local top = t[name .. "Top"]
      return F.tok(Skin, key, name), type(top) == "table" and F.rgba(top) or "none"
    end
    local label = F.tok(Skin, key, "btnPrimary.text")
    local restFill, restGrad = want("btnPrimary.bg")
    local hotFill, hotGrad = want("btnPrimary.hoverBg")
    assertEqual(fill(), restFill, "at rest: btnPrimary.bg")
    assertEqual(grad(), restGrad, "at rest: its gradient's top")
    assertEqual(textColor(m, b.text), label, "at rest: btnPrimary.text")
    b:__fire("OnEnter")
    assertEqual(fill(), hotFill, "under the pointer: btnPrimary.hoverBg")
    assertEqual(grad(), hotGrad, "under the pointer: its gradient's top")
    assertEqual(textColor(m, b.text), label, "under the pointer: the label unchanged")
    b:__fire("OnLeave")
    assertEqual(fill(), restFill, "at rest again: btnPrimary.bg")
    assertEqual(grad(), restGrad, "at rest again: its gradient's top")
    assertEqual(textColor(m, b.text), label, "at rest again: btnPrimary.text")
  end)

  test("footer button hover: an AceGUI Button (the icon browser's Choose) lights on enter, rest on leave (" .. key .. ")", function()
    local m, Skin, lib = A.env()
    F.owner(Skin, A.OWNER, key)
    local w = A.instance(lib, A.OWNER).AceGUI:Create("Button")
    assertEqual(textColor(m, w.text), tok3(Skin, key, "btn.text"), "at rest")
    w.frame:__fire("OnEnter")
    assertEqual(textColor(m, w.text), tok3(Skin, key, "btn.hover"), "under the pointer")
    w.frame:__fire("OnLeave")
    assertEqual(textColor(m, w.text), tok3(Skin, key, "btn.text"), "at rest again")
  end)
end

local SIM_FILES = { "Widgets", "WidgetsDropdown", "WidgetsHeader", "Lifecycle", "Sim", "SimTimeline", "SimPanel",
  "SimPanelRender" }

--- A shown sim panel for `owner` on `skin`; answers m, Skin and the panel frame.
local function simPanel(owner, skin)
  local files = {}
  for _, f in ipairs(F.FILES) do files[#files + 1] = f end
  for _, f in ipairs(SIM_FILES) do files[#files + 1] = f end
  local m, Skin = F.env({ files = files })
  local named, create = {}, m.CreateFrame
  m.CreateFrame = function(kind, name, ...)
    local fr = create(kind, name, ...)
    if name then named[name] = fr end
    return fr
  end
  if skin then F.owner(Skin, owner, skin) end
  local Sim = m.LibStub("LibKa0s-Sim-1.0")
  local s = Sim:New{
    name = owner, seam = Sim:NewSeam({ Probe = function() return "live" end }, { name = owner }),
    slash = "/host sim", deliver = function() return 1 end, isStoodDown = function() return false end,
    scenarios = { names = { "one" }, defs = { one = { label = "One", timeline = function()
      return { { kind = "a", label = "Alpha" } }
    end } } },
    prepare = function(_, _, _, ready) ready() end, play = function() return "did" end,
    print = function() end, panel = {},
  }
  assertTrue(s:ShowPanel(), "ShowPanel")
  return m, Skin, named[owner .. "SimPanel"]
end

for _, key in ipairs(KEYS) do
  test("footer button hover: the sim panel's Start lights in the link color on enter, rest on leave (" .. key .. ")", function()
    local m, Skin, f = simPanel("LootHistory", key)
    local start = f.picker.start
    assertEqual(textColor(m, start.label), tok3(Skin, key, "sem.stepReady"), "at rest")
    start:__fire("OnEnter")
    assertEqual(textColor(m, start.label), tok3(Skin, key, "text.link"), "under the pointer")
    start:__fire("OnLeave")
    assertEqual(textColor(m, start.label), tok3(Skin, key, "sem.stepReady"), "at rest again")
  end)
end

test("footer button hover: an owner-less sim panel's Start hovers Ka0s Default's link orange", function()
  -- The constants are Ka0s Default's tokens (SimPanelRender's THE SKIN OWNER), so a panel no skin
  -- owns hovers what Ka0s Default does. red under: SimPanel's DEFAULT.hot left gold.
  local m, _, f = simPanel("BankLedger")
  local start = f.picker.start
  start:__fire("OnEnter")
  assertEqual(textColor(m, start.label), F.rgba({ 1, 0.5, 0, 1 }), "Ka0s Default's text.link")
  start:__fire("OnLeave")
  assertEqual(textColor(m, start.label), F.rgba({ 0.9, 0.9, 0.92, 1 }), "its rest")
end)

-- ── a primary's hover fill: disabled, remapped, a region-boxed button ────────────────────────

local function primaryButton(m)
  local b = m.CreateFrame("Button", nil, m.UIParent, "BackdropTemplate")
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  return b
end

test("footer button hover: a disabled primary keeps its rest fill under the pointer", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, "LootHistory", "obsidian")
  local b, on = primaryButton(m), true
  rawset(b, "IsEnabled", function() return on end)
  S.Button(b, { primary = true })
  on = false; b:__fire("OnDisable")
  b:__fire("OnEnter")
  assertEqual(F.rgba(m.__paint(b).backdropColor), F.tok(Skin, "obsidian", "btnPrimary.bg"), "no hover fill while disabled")
  on = true; b:__fire("OnEnable")
  b:__fire("OnEnter")
  assertEqual(F.rgba(m.__paint(b).backdropColor), F.tok(Skin, "obsidian", "btnPrimary.hoverBg"), "enabled, it hovers")
  on = false; b:__fire("OnDisable")
  assertEqual(F.rgba(m.__paint(b).backdropColor), F.tok(Skin, "obsidian", "btnPrimary.bg"), "disabled while hovered: rest")
end)

test("footer button hover: a primary whose fill is remapped hovers only by a remapped hoverBg", function()
  -- `opts.tokens.bg` alone (a danger button): the library's hover fill would flash another color,
  -- so the fill stays; `hoverBg` remapped too, the hover paints that token.
  local m, Skin = F.env()
  local S = F.owner(Skin, "LootHistory", "obsidian")
  local b = primaryButton(m)
  S.Button(b, { primary = true, tokens = { bg = "sem.bad" } })
  b:__fire("OnEnter")
  assertEqual(F.rgba(m.__paint(b).backdropColor), F.tok(Skin, "obsidian", "sem.bad"), "bg alone: no hover fill")
  b:__fire("OnLeave")
  local c = primaryButton(m)
  S.Button(c, { primary = true, tokens = { bg = "sem.bad", hoverBg = "sem.off" } })
  c:__fire("OnEnter")
  assertEqual(F.rgba(m.__paint(c).backdropColor), F.tok(Skin, "obsidian", "sem.off"), "hoverBg remapped: that token")
  c:__fire("OnLeave")
  assertEqual(F.rgba(m.__paint(c).backdropColor), F.tok(Skin, "obsidian", "sem.bad"), "and back")
end)

test("footer button hover: a primary with no backdrop repaints its fill region, the gradient included", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, "LootHistory", "ember")
  local b = m.CreateFrame("Button", nil, m.UIParent)
  rawset(b, "SetBackdrop", nil)
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  S.Button(b, { primary = true })
  local function top()
    local g = m.__paint(F.region(Skin, b, "fill")).gradient
    return F.rgba({ g.max.r, g.max.g, g.max.b, g.max.a })
  end
  assertEqual(top(), F.tok(Skin, "ember", "btnPrimary.bgTop"), "at rest")
  b:__fire("OnEnter")
  assertEqual(top(), F.tok(Skin, "ember", "btnPrimary.hoverBgTop"), "under the pointer")
  b:__fire("OnLeave")
  assertEqual(top(), F.tok(Skin, "ember", "btnPrimary.bgTop"), "at rest again")
end)
