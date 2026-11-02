-- tests/test_skin_icon_border.lua — LibKa0s-Skin-1.0's icon border family (LK-04 of
-- Ka0sAddonsCommonTasks docs/2026-10-29-SKINNING_ROLLOUT, gap DW-G14): `icon.borderStyle` and
-- `icon.borderSize` beside `icon.border`, so an item icon's border can follow the skin the way a
-- bar's does (SkinDefs minor 15), and `S.IconBorder(frame, { fromSkin = true })` drawing them.
--
-- What it pins: the two tokens are in the schema's HUD group and every one of the nine skins sets
-- both itself; Ka0s Default's are Drop Watcher's Window › Icons border today (Solid, 2px, in
-- `icon.border`'s black); every style a skin names is one the library can draw; S.IconBorder WITHOUT
-- `fromSkin` paints exactly what it painted before (flat, `opts.size` or 1); WITH it, since the
-- owner's third smoke round (R3-L3 of Ka0sAddonsCommonTasks docs/2026-11-02-SMOKE_ROUND3), a 1 px
-- outline in `icon.border` in every skin whatever its style and size, one physical pixel; the icon
-- zoomed 0.07 by default; and under the eui source it is painted by the library from the
-- EllesmereUI-derived tokens, never handed to EllesmereUI.
--
-- Every case runs on a fresh environment (tests/fixture_skin_paint.lua, tests/fixture_skin_eui.lua).

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil
local F = dofile("tests/fixture_skin_paint.lua")
local E = dofile("tests/fixture_skin_eui.lua")

local OWNER = "DropWatcher"
local KEYS = { "ka0s", "obsidian", "azeroth", "glass", "contrast", "ember", "wow", "midnight", "forever" }

local function survey(m, obj) return m.__paint(obj) end

--- The four flat edges' widths, "Top=2,Bottom=2,Left=2,Right=2", from a trace of one call.
local function edgeSizes(m, Skin, S, frame, opts)
  local tr = F.tracer(m)
  tr.watch(frame)
  local rec = Skin.painted[frame]
  for _, side in ipairs({ "Top", "Bottom", "Left", "Right" }) do
    local t = rec and rec.regions["edge" .. side]
    if t then tr.watch(t) end
  end
  tr.start(); S.IconBorder(frame, opts); tr.stop(); tr.restore()
  return F.only(tr, { SetWidth = true, SetHeight = true })
end

-- ── the tokens ───────────────────────────────────────────────────────────────────────────────

test("skin icon border: SkinDefs is at minor 15 and the schema's HUD group carries the family", function()
  local _, Skin = F.env()
  assertTrue(Skin.MODULES.SkinDefs >= 15, "SkinDefs minor 15")
  local style, size = Skin.__schemaIndex["icon.borderStyle"], Skin.__schemaIndex["icon.borderSize"]
  assertTrue(style ~= nil and size ~= nil, "both in the schema")
  assertEqual(style.kind, "string")
  assertEqual(size.kind, "number")
  assertEqual(style.group, "HUD")
  assertEqual(size.group, "HUD")
  assertTrue(not style.nilable and not size.nilable, "every skin resolves both")
end)

test("skin icon border: Ka0s Default's is Drop Watcher's Window › Icons border, Solid 2px black", function()
  -- DropWatcher defaults/Profile.lua icons.borderStyle "Solid" (WHITE8X8, modules/IconStyle.lua),
  -- icons.borderSize 2, icons.borderColor { 0, 0, 0, 1 }.
  local _, Skin = F.env()
  local t = Skin:ResolveSkin("ka0s")
  assertEqual(t["icon.borderStyle"], "Solid")
  assertEqual(t["icon.borderSize"], 2)
  assertEqual(F.rgba(t["icon.border"]), "0,0,0,1")
end)

test("skin icon border: every skin sets both tokens itself, each a style the library draws", function()
  local _, Skin = F.env()
  local known = { Solid = true, None = true, ["Blizzard Tooltip"] = true, ["Blizzard Dialog"] = true,
                  ["Ka0s Glass"] = true }
  for _, key in ipairs(KEYS) do
    local def = Skin:GetSkin(key)
    assertTrue(def ~= nil, key .. " registered")
    local style, size = def.tokens["icon.borderStyle"], def.tokens["icon.borderSize"]
    assertTrue(type(style) == "string" and known[style], key .. ": icon.borderStyle " .. tostring(style))
    assertTrue(type(size) == "number" and size >= 1 and size <= 4 and size == math.floor(size),
      key .. ": icon.borderSize " .. tostring(size) .. " is a whole 1-4px")
  end
end)

-- ── S.IconBorder ─────────────────────────────────────────────────────────────────────────────

test("skin icon border: without fromSkin IconBorder paints exactly what it did, flat at opts.size or 1", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local one, two = m.CreateFrame("Frame", nil, m.UIParent), m.CreateFrame("Frame", nil, m.UIParent)
  S.IconBorder(one)
  assertEqual(edgeSizes(m, Skin, S, one), "#2:SetHeight(1)\n#3:SetHeight(1)\n#4:SetWidth(1)\n#5:SetWidth(1)",
    "1px with no opts")
  S.IconBorder(two, { size = 2 })
  assertEqual(edgeSizes(m, Skin, S, two, { size = 3 }),
    "#2:SetHeight(3)\n#3:SetHeight(3)\n#4:SetWidth(3)\n#5:SetWidth(3)", "opts.size")
  assertEqual(F.rgba(survey(m, F.region(Skin, one, "edgeTop")).color), F.tok(Skin, "ka0s", "icon.border"))
  assertNil(F.region(Skin, one, "nine"), "never a nine-slice")
  Skin:SetChoice(OWNER, "ka0s", "wow")
  assertNil(F.region(Skin, two, "nine"), "WoW Default's Blizzard Tooltip is not read without fromSkin")
  assertTrue(survey(m, F.region(Skin, two, "edgeTop")).shown, "still the flat edge")
end)

test("skin icon border: fromSkin draws a 1 px outline in icon.border in every skin, never the skin's size", function()
  -- red under: icon.borderSize, which drew 2 px in Ka0s Default, Azeroth, Ember, WoW Midnight and a
  -- Blizzard Tooltip nine-slice in WoW Default (R3-L3 of Ka0sAddonsCommonTasks
  -- docs/2026-11-02-SMOKE_ROUND3, images 91 and 92: "make it consistently 1px").
  local m, Skin = F.env({ lsm = { ["border:Blizzard Tooltip"] = "Interface\\Tooltips\\UI-Tooltip-Border" } })
  local S = F.owner(Skin, OWNER)
  local f = m.CreateFrame("Frame", nil, m.UIParent)
  S.IconBorder(f, { fromSkin = true, size = 5 })
  for _, key in ipairs(KEYS) do
    Skin:SetChoice(OWNER, "ka0s", key)
    assertEqual(edgeSizes(m, Skin, S, f, { fromSkin = true, size = 5 }),
      "#2:SetHeight(1)\n#3:SetHeight(1)\n#4:SetWidth(1)\n#5:SetWidth(1)", key .. ": 1 px, not opts.size or the skin's")
    for _, side in ipairs({ "Top", "Bottom", "Left", "Right" }) do
      local r = survey(m, F.region(Skin, f, "edge" .. side))
      assertEqual(F.rgba(r.color), F.tok(Skin, key, "icon.border"), key .. ": " .. side .. " in icon.border")
      assertTrue(r.shown, key .. ": " .. side .. " shown")
    end
    assertNil(F.region(Skin, f, "nine"), key .. ": never a nine-slice")
  end
end)

test("skin icon border: the 1 px is one physical pixel at any UI scale, with or without fromSkin", function()
  -- red under: 1 UI unit, which draws 2 px where the UI scale is over one pixel per unit.
  local m, Skin = F.env()
  m.PixelUtil = { GetPixelToUIUnitFactor = function() return 0.75 end }
  local make = m.CreateFrame
  m.CreateFrame = function(...)
    local f = make(...)
    rawset(f, "GetEffectiveScale", function() return 1.5 end)
    return f
  end
  local S = F.owner(Skin, OWNER, "midnight")
  local f, g = m.CreateFrame("Frame", nil, m.UIParent), m.CreateFrame("Frame", nil, m.UIParent)
  S.IconBorder(f, { fromSkin = true })
  S.IconBorder(g, { size = 2 })
  assertEqual(F.region(Skin, f, "edgeTop"):GetHeight(), 0.5, "0.75 / 1.5: one physical pixel")
  assertEqual(F.region(Skin, g, "edgeLeft"):GetWidth(), 1, "opts.size in physical pixels too")
end)

test("skin icon border: a skin whose icon.borderStyle is None still draws the outline", function()
  -- red under: None drawing nothing, which leaves the icon's own edge as its only frame.
  local m, Skin = F.env()
  Skin:RegisterSkin({ key = "bare", tokens = { ["icon.borderStyle"] = "None", ["icon.borderSize"] = 1 } })
  Skin:RegisterSkin({ key = "barer", tokens = { ["icon.border"] = false, divider = { 0.5, 0.5, 0.5, 1 } } })
  local S = F.owner(Skin, OWNER, "bare")
  local f = m.CreateFrame("Frame", nil, m.UIParent)
  S.IconBorder(f, { fromSkin = true })
  local e = survey(m, F.region(Skin, f, "edgeTop"))
  assertTrue(e.shown, "None draws it")
  assertEqual(F.rgba(e.color), F.tok(Skin, "bare", "icon.border"))
  Skin:SetChoice(OWNER, "ka0s", "barer")
  e = survey(m, F.region(Skin, f, "edgeTop"))
  assertTrue(e.shown, "a skin with no icon.border too")
  assertEqual(F.rgba(e.color), "0.500,0.500,0.500,1", "in its divider")
end)

-- ── the zoom (R3-L3, images 88 to 90: the icon's own edge showed inside the border) ──────────

local function texCoord(m, t) return table.concat(survey(m, t).texCoord or {}, ",") end

--- A square inset's coords as the client answers them, the corners UL, LL, UR, LR (mock_paint.lua).
local function inset(z) return table.concat({ z, z, z, 1 - z, 1 - z, z, 1 - z, 1 - z }, ",") end

test("skin icon border: the icon is zoomed 0.07 by default, a frame's icon or a Texture itself", function()
  -- red under: no zoom, which leaves the art's built-in border inside the outline (img 90).
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local f = m.CreateFrame("Frame", nil, m.UIParent)
  f.icon = f:CreateTexture()
  S.IconBorder(f, { fromSkin = true })
  assertEqual(texCoord(m, f.icon), inset(0.07), "frame.icon")
  local g = m.CreateFrame("Frame", nil, m.UIParent)
  g.Icon = g:CreateTexture()
  S.IconBorder(g)
  assertEqual(texCoord(m, g.Icon), inset(0.07), "frame.Icon, without fromSkin too")
  local tex = m.CreateFrame("Frame", nil, m.UIParent):CreateTexture()
  S.IconBorder(tex, { fromSkin = true })
  assertEqual(texCoord(m, tex), inset(0.07), "a Texture handed in is the icon")
  local h = m.CreateFrame("Frame", nil, m.UIParent)
  local other = h:CreateTexture()
  S.IconBorder(h, { fromSkin = true, icon = other })
  assertEqual(texCoord(m, other), inset(0.07), "opts.icon")
end)

test("skin icon border: opts.zoom overrides the zoom, false leaves the coords alone, a frame with no icon is left", function()
  -- red under: a host's own crop overwritten, or a lone region of the frame guessed at.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local f = m.CreateFrame("Frame", nil, m.UIParent)
  f.icon = f:CreateTexture()
  S.IconBorder(f, { fromSkin = true, zoom = 0.1 })
  assertEqual(texCoord(m, f.icon), inset(0.1))
  local g = m.CreateFrame("Frame", nil, m.UIParent)
  g.icon = g:CreateTexture()
  g.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  S.IconBorder(g, { fromSkin = true, zoom = false })
  assertEqual(texCoord(m, g.icon), inset(0.08), "the host's crop stands")
  local bare = m.CreateFrame("Frame", nil, m.UIParent)
  local lone = bare:CreateTexture()
  S.IconBorder(bare, { fromSkin = true })
  assertEqual(texCoord(m, lone), "", "no icon named: no region guessed at")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(texCoord(m, f.icon), inset(0.1), "a replay keeps opts.zoom")
end)

test("skin icon border: P.unpaint gives the icon its own coords back", function()
  -- red under: a zoom left on an icon the skin no longer paints (Ignore, a scope off).
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local f = m.CreateFrame("Frame", nil, m.UIParent)
  f.icon = f:CreateTexture()
  f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  S.IconBorder(f, { fromSkin = true })
  S.IconBorder(f, { fromSkin = true })
  assertEqual(texCoord(m, f.icon), inset(0.07))
  Skin.__P.unpaint(Skin.painted[f], f)
  assertEqual(texCoord(m, f.icon), inset(0.08), "the host's crop, not the first zoom's")
  assertTrue(not survey(m, F.region(Skin, f, "edgeTop")).shown, "and the outline hidden")
end)

test("skin icon border: under eui fromSkin is the library's, from the EllesmereUI-derived tokens", function()
  local m, Skin, eui = E.env()
  local S = Skin:RegisterOwner(OWNER, { get = function() return "eui", "obsidian" end })
  local f = m.CreateFrame("Frame", nil, m.UIParent)
  S.IconBorder(f, { fromSkin = true })
  eui.login()
  assertTrue(Skin.euiPainted[OWNER], "EllesmereUI paints the owner")
  S.IconBorder(f, { fromSkin = true })
  assertEqual(eui.count("IconBorder"), 0, "IconBorder is a Ka0s extra: never handed to EllesmereUI")
  assertEqual(Skin:Token(OWNER, "icon.borderStyle"), "Solid", "EllesmereUI's look is Ka0s Default's here")
  assertEqual(Skin:Token(OWNER, "icon.borderSize"), 2)
  assertTrue(survey(m, F.region(Skin, f, "edgeTop")).shown, "drawn")
  assertEqual(F.rgba(survey(m, F.region(Skin, f, "edgeTop")).color), F.rgba(S.Token("icon.border")),
    "SkinEUI minor 4's, half EllesmereUI's panel color")
  assertNil(Skin.euiRefused[OWNER], "nothing refused")
end)
