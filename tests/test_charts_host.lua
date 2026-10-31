-- tests/test_charts_host.lua — LibKa0s-Charts-1.0: the host seams, the tooltip, the real skin engine
-- and Reskin.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil = T.test, T.assertEqual, T.assertTrue,
  T.assertFalse, T.assertNil
local F = dofile("tests/fixture_charts.lua")

local RED = { 1, 0, 0 }

-- The whole payload once: it is the slow part, and each case takes an owner of its own.
local M, C, Skin
local serial = 0
local function skinned(extra)
  if not M then
    M, C = F.env({ full = true })
    Skin = M.LibStub("LibKa0s-Skin-1.0")
  end
  serial = serial + 1
  local owner = "ChartsHost" .. serial
  Skin:RegisterOwner(owner)
  local host = { owner = owner }
  for k, v in pairs(extra or {}) do host[k] = v end
  return C:New(F.content(M), host), owner, M
end

test("host: a context with no owner draws Ka0s Default's colors and the font object's face", function()
  local m, Charts = F.env()
  local ctx = Charts:New(F.content(m), {})
  assertEqual(ctx.colors.heading[1], 1)
  assertEqual(ctx.colors.rule[4], 0.35)
  local fs = ctx:sectionHeader(nil, "H")
  assertEqual(fs.__fontObject, "GameFontNormal")
  assertEqual(fs.__color[2], 0.82)
end)

test("host: a host's colors and fonts win, field by field, and a function is read", function()
  local m, Charts = F.env()
  local ctx = Charts:New(F.content(m), {
    colors = { heading = RED, body = function() return { 0, 1, 0 } end },
    fonts = { heading = "HostFont" },
  })
  assertEqual(ctx.colors.heading, RED)
  assertEqual(ctx.colors.body[2], 1)
  assertEqual(ctx.colors.value[1], 0.8, "the rest default")
  assertEqual(ctx:sectionHeader(nil, "H").__fontObject, "HostFont")
  assertEqual(ctx.fonts.label, "GameFontHighlightSmall")
end)

test("host: the text, paint, fill, barFill and panel seams each carry their draws", function()
  local m, Charts = F.env()
  local seen = { text = 0, paint = 0, fill = 0, bar = 0, panel = 0 }
  local ctx = Charts:New(F.content(m), {
    text = function(parent) seen.text = seen.text + 1; return parent:CreateFontString() end,
    paint = function() seen.paint = seen.paint + 1 end,
    fill = function() seen.fill = seen.fill + 1 end,
    barFill = function() seen.bar = seen.bar + 1 end,
    panel = function(parent) seen.panel = seen.panel + 1; return m.CreateFrame("Frame", nil, parent) end,
  })
  ctx:listPanel(nil, "T")
  ctx:renderBarSection(ctx:Pool("b"), ctx:sectionHeader(nil, "H"),
    { { label = "A", frac = 1, color = RED, value = "1" } }, 0, 500, 8)
  assertEqual(seen.panel, 1)
  assertTrue(seen.text >= 4)
  assertTrue(seen.paint >= 4)
  assertEqual(seen.fill, 1, "the track")
  assertEqual(seen.bar, 1, "the data")
end)

test("host: two contexts keep their own seams, so one addon never paints another's chart", function()
  local m, Charts = F.env()
  local a, b = 0, 0
  local one = Charts:New(F.content(m), { paint = function() a = a + 1 end })
  Charts:New(F.content(m), { paint = function() b = b + 1 end })
  one:sectionHeader(nil, "H")
  assertEqual(a, 1)
  assertEqual(b, 0)
end)

test("host: a host fill stands in for the bar fill when it names no barFill", function()
  local m, Charts = F.env()
  local n = 0
  local ctx = Charts:New(F.content(m), { fill = function() n = n + 1 end })
  ctx:renderBarSection(ctx:Pool("b"), ctx:sectionHeader(nil, "H"),
    { { label = "A", frac = 1, color = RED, value = "1" } }, 0, 500, 8)
  assertEqual(n, 2, "the track and the fill")
end)

test("host: the default tooltip shows a title and its lines, and an empty one shows nothing", function()
  local m, Charts = F.env()
  local ctx = Charts:New(F.content(m), {})
  local pool = ctx:Pool("list")
  ctx:renderListPanel(pool, ctx:listPanel(nil, "T"),
    { { name = "A", right = "1", tip = { "Title", "line", 3 } }, { name = "B", right = "2" } }, 0, 300, 8)
  local row = pool.active[1]
  row:GetScript("OnEnter")(row)
  assertEqual(m.GameTooltip.__owner, row)
  assertEqual(m.GameTooltip.__anchor, "ANCHOR_CURSOR_RIGHT")
  assertEqual(m.GameTooltip.__text, "Title")
  assertEqual(m.GameTooltip.__lines[2], "3")
  row:GetScript("OnLeave")(row)
  assertTrue(m.GameTooltip.__shown == false)
  m.GameTooltip.__owner = nil
  row._tip = {}
  row:GetScript("OnEnter")(row)
  assertNil(m.GameTooltip.__owner, "no lines, no tooltip")
end)

test("host: a host's tip and hideTip replace it", function()
  local m, Charts = F.env()
  local got, hid
  local ctx = Charts:New(F.content(m), {
    tip = function(_, lines, anchor) got = { lines[1], anchor } end,
    hideTip = function() hid = true end,
  })
  local card = ctx:card(nil, "Cap")
  ctx:setCard(card, "9")
  card.frame:GetScript("OnEnter")(card.frame)
  assertEqual(got[1], "Cap:  9", "a string becomes one line")
  assertEqual(got[2], "ANCHOR_CURSOR_RIGHT")
  card.frame:GetScript("OnLeave")(card.frame)
  assertTrue(hid)
end)

test("host: an owner nobody registered draws the plain way, with no skin", function()
  local m, Charts = F.env()
  local ctx = Charts:New(F.content(m), { owner = "NoSuchAddon" })
  assertNil(ctx.skin)
  skinned()
  local ctx2 = C:New(F.content(M), { owner = "NoSuchAddon" })
  assertNil(ctx2.skin, "with the engine loaded too")
  assertEqual(ctx2.colors.heading[1], 1)
end)

test("skin: an owner's context reads its colors and palette from the owner's skin", function()
  local ctx, owner = skinned()
  assertEqual(ctx.colors.track, Skin:Token(owner, "chart.track"))
  assertEqual(ctx.colors.caption, Skin:Token(owner, "text.disabled"))
  assertEqual(ctx:paletteColor(1), Skin:Token(owner, "chart.series")[1])
end)

test("skin: the host's color and palette still beat the owner's", function()
  local ctx = skinned({ colors = { track = RED }, palette = { RED } })
  assertEqual(ctx.colors.track, RED)
  assertEqual(ctx:paletteColor(1), RED)
end)

test("skin: a bar of data goes through the owner's bar texture, and a panel through its Panel", function()
  local ctx = skinned()
  local panel = ctx:listPanel(nil, "T")
  assertEqual(panel.__template, "BackdropTemplate")
  assertTrue(Skin.painted[panel] ~= nil, "recorded, so the engine repaints it")
  local pool = ctx:Pool("b")
  ctx:renderBarSection(pool, ctx:sectionHeader(nil, "H"),
    { { label = "A", frac = 1, color = RED, value = "1" } }, 0, 500, 8)
  local rec = Skin.painted[pool.active[1].fill]
  assertTrue(rec ~= nil and rec.calls.BarTexture ~= nil, "the fill is a recorded BarTexture")
  assertNil(Skin.painted[pool.active[1].track], "the track stays a flat color")
end)

test("skin: a label is on the owner's face, recorded for the repaint", function()
  local ctx = skinned()
  local fs = ctx:sectionHeader(nil, "H")
  local rec = Skin.painted[fs]
  assertTrue(rec ~= nil and rec.calls.Font ~= nil)
end)

test("skin: a switch moves the colors in place, repaints both pool lists, then calls onReskin", function()
  local redraws = 0
  local ctx, owner = skinned({ onReskin = function() redraws = redraws + 1 end })
  local colors = ctx.colors
  local header = ctx:sectionHeader(nil, "H")
  local active, free = ctx:Pool("active"), ctx:Pool("free")
  local row = { { label = "A", frac = 1, color = RED, value = "1" } }
  ctx:renderBarSection(free, header, row, 0, 500, 8)
  ctx:ReleaseAll()
  ctx:renderBarSection(active, header, row, 0, 500, 8)
  local parked, drawn = free.free[1], active.active[1]
  parked.track.__color, drawn.track.__color, header.__color = nil, nil, nil

  local target
  for _, key in ipairs({ "slate", "glass", "midnight" }) do
    if Skin:GetSkin(key) then target = key; break end
  end
  if not target then
    for key in pairs(Skin:Skins()) do
      if type(key) == "string" and key ~= Skin.DEFAULT then target = key; break end
    end
  end
  assertTrue(target ~= nil, "a second skin to switch to")
  Skin:SetChoice(owner, "ka0s", target)

  assertEqual(ctx.colors, colors, "the same table")
  assertEqual(ctx.colors.track, Skin:Token(owner, "chart.track"))
  assertTrue(parked.track.__color ~= nil, "the free list")
  assertTrue(drawn.track.__color ~= nil, "the active list")
  assertTrue(header.__color ~= nil, "the chrome")
  assertEqual(redraws, 1)
end)

test("skin: Reskin works for a host with no owner, and a card keeps its caller's color", function()
  local m, Charts = F.env()
  local live = RED
  local ctx = Charts:New(F.content(m), { colors = { heading = function() return live end } })
  local card = ctx:card(nil, "Cap")
  local tinted = ctx:card(nil, "Cap2")
  ctx:setCard(card, "1")
  ctx:setCard(tinted, "2", nil, nil, { 0, 1, 0 })
  live = { 0, 0, 1 }
  ctx:Reskin()
  assertEqual(card.value.__color[3], 1, "the new heading")
  assertEqual(tinted.value.__color[2], 1, "the caller's color stays")
  assertFalse(card.value.__color[1] == 1)
end)

test("skin: setCard puts the owner's face back on the figure", function()
  local ctx = skinned()
  local card = ctx:card(nil, "Cap")
  local faced
  local face = ctx.face
  ctx.face = function(fs) faced = fs; face(fs) end
  ctx:setCard(card, "1")
  assertEqual(faced, card.value, "after the figure's font object, so the skin's face stays")
  assertTrue(Skin.painted[card.value].calls.Font ~= nil)
end)
