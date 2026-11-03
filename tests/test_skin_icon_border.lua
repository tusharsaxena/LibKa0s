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
-- EllesmereUI-derived tokens, never handed to EllesmereUI. Since the owner's fourth smoke round
-- (R4-L3 of Ka0sAddonsCommonTasks docs/2026-11-03-SMOKE_ROUND4, option 2) the outline is
-- `icon.outline`, else `icon.border`: a window's icon outline that shows in every skin, while
-- `icon.border`, the HUD hosts' edge, keeps its value (Ka0s Default's black).
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

test("skin icon border: Ka0s Default's is Solid 1px, its HUD edge black and its outline #4D4D57", function()
  -- Drop Watcher's Window › Icons border was Solid 2px until R3-FIX of Ka0sAddonsCommonTasks
  -- docs/2026-11-02-SMOKE_ROUND3: the owner's "exactly 1 px in every skin" reaches the hosts that
  -- draw their own icon border from these tokens (KickCD, ConsumableMaster, DropWatcher). R4-L3: the
  -- HUD edge stays black (the owner's scope answer), and the window outline is a gray that shows.
  local _, Skin = F.env()
  local t = Skin:ResolveSkin("ka0s")
  assertEqual(t["icon.borderStyle"], "Solid")
  assertEqual(t["icon.borderSize"], 1)
  assertEqual(F.rgba(t["icon.border"]), "0,0,0,1")
  assertEqual(F.rgba(t["icon.outline"]), F.rgba({ 0x4d / 255, 0x4d / 255, 0x57 / 255, 1 }))
end)

test("skin icon border: icon.outline is a nilable HUD color in the schema", function()
  -- R4-L3. red under: the token missing from the schema, which RegisterSkin's validation and the
  -- override editors read, so a skin stating it would name an unknown token.
  local _, Skin = F.env()
  local e = Skin.__schemaIndex["icon.outline"]
  assertTrue(e ~= nil, "in the schema")
  assertEqual(e.kind, "color")
  assertEqual(e.group, "HUD")
  assertTrue(e.nilable, "nilable, as icon.border is")
end)

-- WCAG 2 relative luminance and contrast ratio, alpha ignored (a composited color).
local function channel(c)
  if c <= 0.03928 then return c / 12.92 end
  return ((c + 0.055) / 1.055) ^ 2.4
end
local function luminance(c) return 0.2126 * channel(c[1]) + 0.7152 * channel(c[2]) + 0.0722 * channel(c[3]) end
local function contrast(a, b)
  local la, lb = luminance(a), luminance(b)
  if la < lb then la, lb = lb, la end
  return (la + 0.05) / (lb + 0.05)
end
local function over(top, under)
  local a = top[4] or 1
  return { top[1] * a + under[1] * (1 - a), top[2] * a + under[2] * (1 - a), top[3] * a + under[3] * (1 - a), 1 }
end
local BLACK = { 0, 0, 0, 1 }

test("skin icon border: every skin's icon outline shows against its window and the icon's dark art", function()
  -- R4-L3, images 19 to 21: the outline sits between the window (outside) and the icon's art, whose
  -- own field is near-black after the zoom, so it shows only if it stands off both. Obsidian's
  -- measures 1.60, the owner's reference for visible. red under: Ka0s Default's black (1.09 / 1.00),
  -- Glass's white at 0.18, WoW Forever's #3a3530 or Ember's #6a2e17, the outlines that did not show.
  local _, Skin = F.env()
  for _, key in ipairs(KEYS) do
    local t = Skin:ResolveSkin(key)
    local win = over(t["win.bg"], BLACK)
    local edge = over(t["icon.outline"], win)
    local onWin, onArt = contrast(edge, win), contrast(edge, BLACK)
    assertTrue(onWin >= 1.6, ("%s: the outline %.2f against the window, want >= 1.6"):format(key, onWin))
    assertTrue(onArt >= 1.6, ("%s: the outline %.2f against black art, want >= 1.6"):format(key, onArt))
  end
end)

test("skin icon border: icon.outline is the owner's value in every skin, and icon.border kept its own", function()
  -- R4-L3, the owner's scope answer (R4_SIGNOFF.md, mockup option 2). red under: a lift landed on
  -- icon.border, which moves every HUD host's icon edge (AuraMaster, KickCD, DropWatcher, QuickComms,
  -- DpsRace, ConsumableMaster's button border), or an outline left on the edge that did not show.
  local _, Skin = F.env()
  local function hx(s, a)
    return F.rgba({ tonumber(s:sub(2, 3), 16) / 255, tonumber(s:sub(4, 5), 16) / 255, tonumber(s:sub(6, 7), 16) / 255, a or 1 })
  end
  local BORDER = {
    ka0s = "0,0,0,1", obsidian = hx("#34343b"), azeroth = hx("#8a6a36"), glass = hx("#ffffff", 0.18),
    contrast = hx("#E0E0E0"), ember = hx("#6a2e17"), wow = hx("#9a9a9a"), midnight = hx("#5a4a26"),
    forever = hx("#3a3530"),
  }
  local OUTLINE = {
    ka0s = hx("#4d4d57"), obsidian = BORDER.obsidian, azeroth = BORDER.azeroth, glass = hx("#ffffff", 0.35),
    contrast = BORDER.contrast, ember = hx("#8a3c1c"), wow = BORDER.wow, midnight = hx("#7a6532"),
    forever = hx("#5a5048"),
  }
  for _, key in ipairs(KEYS) do
    assertEqual(F.tok(Skin, key, "icon.border"), BORDER[key], key .. ": icon.border is unchanged")
    assertEqual(F.tok(Skin, key, "icon.outline"), OUTLINE[key], key .. ": icon.outline")
  end
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
    -- red under: 2 in Azeroth, Ember, WoW Midnight and a Blizzard Tooltip nine-slice in WoW Default,
    -- beside the 1 px S.IconBorder draws (R3-FIX: "exactly 1 px in every skin").
    assertEqual(style, "Solid", key .. ": a flat edge")
    assertEqual(size, 1, key .. ": 1 px")
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
  assertEqual(F.rgba(survey(m, F.region(Skin, one, "edgeTop")).color), F.tok(Skin, "ka0s", "icon.outline"))
  assertNil(F.region(Skin, one, "nine"), "never a nine-slice")
  Skin:SetChoice(OWNER, "ka0s", "wow")
  assertNil(F.region(Skin, two, "nine"), "WoW Default's Blizzard Tooltip is not read without fromSkin")
  assertTrue(survey(m, F.region(Skin, two, "edgeTop")).shown, "still the flat edge")
end)

test("skin icon border: fromSkin draws a 1 px outline in icon.outline in every skin, never the skin's size", function()
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
      assertEqual(F.rgba(r.color), F.tok(Skin, key, "icon.outline"), key .. ": " .. side .. " in icon.outline")
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
  Skin:RegisterSkin({ key = "plain", tokens = { ["icon.outline"] = false, ["icon.border"] = { 1, 0, 0, 1 } } })
  Skin:RegisterSkin({ key = "barer", tokens = { ["icon.outline"] = false, ["icon.border"] = false,
    divider = { 0.5, 0.5, 0.5, 1 } } })
  local S = F.owner(Skin, OWNER, "bare")
  local f = m.CreateFrame("Frame", nil, m.UIParent)
  S.IconBorder(f, { fromSkin = true })
  local e = survey(m, F.region(Skin, f, "edgeTop"))
  assertTrue(e.shown, "None draws it")
  assertEqual(F.rgba(e.color), F.tok(Skin, "bare", "icon.outline"))
  -- R4-L3: a skin with no outline draws its icon.border. red under: the outline read alone.
  Skin:SetChoice(OWNER, "ka0s", "plain")
  e = survey(m, F.region(Skin, f, "edgeTop"))
  assertTrue(e.shown, "a skin with no icon.outline draws one")
  assertEqual(F.rgba(e.color), "1,0,0,1", "in its icon.border")
  Skin:SetChoice(OWNER, "ka0s", "barer")
  e = survey(m, F.region(Skin, f, "edgeTop"))
  assertTrue(e.shown, "a skin with neither token too")
  assertEqual(F.rgba(e.color), "0.500,0.500,0.500,1", "in its divider")
end)

test("skin icon border: SquareIcon's edge is icon.outline, else icon.border", function()
  -- R4-L3: S.SquareIcon draws its own edge, under IconBorder's in the Skin Tester's pairing, so it
  -- reads the same token. red under: icon.border alone, a black edge beneath the gray outline.
  local m, Skin = F.env()
  Skin:RegisterSkin({ key = "plain", tokens = { ["icon.outline"] = false, ["icon.border"] = { 1, 0, 0, 1 } } })
  local S = F.owner(Skin, OWNER)
  local b = m.CreateFrame("Button", nil, m.UIParent)
  b.icon = b:CreateTexture()
  S.SquareIcon(b, { crop = true })
  assertEqual(F.rgba(survey(m, F.region(Skin, b, "edgeTop")).color), F.tok(Skin, "ka0s", "icon.outline"))
  Skin:SetChoice(OWNER, "ka0s", "glass")
  assertEqual(F.rgba(survey(m, F.region(Skin, b, "edgeTop")).color), F.tok(Skin, "glass", "icon.outline"))
  Skin:SetChoice(OWNER, "ka0s", "plain")
  assertEqual(F.rgba(survey(m, F.region(Skin, b, "edgeTop")).color), "1,0,0,1", "a skin with no outline: icon.border")
end)

-- ── opts.hud (R4-L4 of Ka0sAddonsCommonTasks docs/2026-11-03-SMOKE_ROUND4, R4_ADDENDUM_HUD_ICON_EDGE.md) ──
-- The owner's scope answer ("I prefer the HUD icons to keep black edges", R4_SIGNOFF.md): an icon a
-- HUD edges through S.IconBorder draws `icon.border`, the HUD token R4-L3 left alone, and never
-- `icon.outline`, the window outline.

--- The four edges' colors of `f`, each checked against `want`.
local function edgesAre(m, Skin, f, want, label)
  for _, side in ipairs({ "Top", "Bottom", "Left", "Right" }) do
    local r = survey(m, F.region(Skin, f, "edge" .. side))
    assertEqual(F.rgba(r.color), want, label .. ": " .. side)
    assertTrue(r.shown, label .. ": " .. side .. " shown")
  end
end

test("skin icon border: opts.hud draws icon.border in every skin, black under Ka0s Default, never icon.outline", function()
  -- red under: drawIconEdge reading icon.outline first for every caller, which turned DpsRace's race
  -- HUD rows, MultiMeters' row icons and PartyFrameEnhanced's cast icon #4D4D57 under Ka0s Default.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local f, g = m.CreateFrame("Frame", nil, m.UIParent), m.CreateFrame("Frame", nil, m.UIParent)
  S.IconBorder(f, { hud = true })
  S.IconBorder(g, { hud = true, fromSkin = true })
  for _, key in ipairs(KEYS) do
    Skin:SetChoice(OWNER, "ka0s", key)
    local want = F.tok(Skin, key, "icon.border")
    assertTrue(want ~= "nil", key .. ": the skin states its HUD edge")
    edgesAre(m, Skin, f, want, key .. " hud")
    edgesAre(m, Skin, g, want, key .. " hud fromSkin")
  end
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  local top = F.rgba(survey(m, F.region(Skin, f, "edgeTop")).color)
  assertEqual(top, "0,0,0,1", "Ka0s Default's HUD edge is black")
  assertTrue(top ~= F.tok(Skin, "ka0s", "icon.outline"), "not the window outline")
  assertEqual(edgeSizes(m, Skin, S, g, { hud = true, fromSkin = true }),
    "#2:SetHeight(1)\n#3:SetHeight(1)\n#4:SetWidth(1)\n#5:SetWidth(1)", "still the 1 px outline")
end)

test("skin icon border: without opts.hud, or hud false, the edge is still icon.outline", function()
  -- red under: hud read as a truthy default, or the window outline moved with the HUD's.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local f, g = m.CreateFrame("Frame", nil, m.UIParent), m.CreateFrame("Frame", nil, m.UIParent)
  S.IconBorder(f, { fromSkin = true })
  S.IconBorder(g, { hud = false })
  for _, key in ipairs(KEYS) do
    Skin:SetChoice(OWNER, "ka0s", key)
    edgesAre(m, Skin, f, F.tok(Skin, key, "icon.outline"), key .. " window")
    edgesAre(m, Skin, g, F.tok(Skin, key, "icon.outline"), key .. " hud false")
  end
end)

test("skin icon border: opts.hud survives a replay and skin flips, and a skin with no icon.border falls past the outline", function()
  -- red under: the flag dropped from the recorded call, so a repaint or a skin switch drew the
  -- outline; or a hud edge with no icon.border reading icon.outline before divider.
  local m, Skin = F.env()
  Skin:RegisterSkin({ key = "nohud", tokens = { ["icon.outline"] = { 1, 0, 0, 1 }, ["icon.border"] = false,
    divider = { 0.5, 0.5, 0.5, 1 } } })
  local S = F.owner(Skin, OWNER)
  local f = m.CreateFrame("Frame", nil, m.UIParent)
  local tex = f:CreateTexture()
  S.IconBorder(f, { hud = true, fromSkin = true })
  S.IconBorder(tex, { hud = true })
  Skin:Repaint(OWNER)
  edgesAre(m, Skin, f, "0,0,0,1", "after a replay")
  edgesAre(m, Skin, tex, "0,0,0,1", "a Texture after a replay")
  for _, key in ipairs({ "glass", "ember", "ka0s", "midnight", "forever", "ka0s" }) do
    Skin:SetChoice(OWNER, "ka0s", key)
    edgesAre(m, Skin, f, F.tok(Skin, key, "icon.border"), key .. " after a flip")
    edgesAre(m, Skin, tex, F.tok(Skin, key, "icon.border"), key .. " a Texture after a flip")
  end
  Skin:SetChoice(OWNER, "ka0s", "nohud")
  edgesAre(m, Skin, f, "0.500,0.500,0.500,1", "no icon.border: divider, never the outline")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  Skin:Repaint(OWNER)
  edgesAre(m, Skin, f, "0,0,0,1", "back to black")
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
  f.icon:SetTexCoord(0.02, 0.98, 0.02, 0.98)
  S.IconBorder(f, { fromSkin = true })
  S.IconBorder(f, { fromSkin = true })
  assertEqual(texCoord(m, f.icon), inset(0.07))
  Skin.__P.unpaint(Skin.painted[f], f)
  assertEqual(texCoord(m, f.icon), inset(0.02), "the host's crop, not the first zoom's")
  assertTrue(not survey(m, F.region(Skin, f, "edgeTop")).shown, "and the outline hidden")
end)

test("skin icon border: the zoom only tightens, a host's tighter crop stands (SquareIcon crop, then IconBorder)", function()
  -- red under: the zoom writing 0.07 over SquareIcon's 0.08, which loosened the host's crop and
  -- showed the art's own edge (R3-FIX of Ka0sAddonsCommonTasks docs/2026-11-02-SMOKE_ROUND3; the
  -- Skin Tester's ShowroomControls pairs the two).
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local sq = m.CreateFrame("Button", nil, m.UIParent)
  sq.icon = sq:CreateTexture()
  S.SquareIcon(sq, { crop = true })
  S.IconBorder(sq, { fromSkin = true })
  assertEqual(texCoord(m, sq.icon), inset(0.08), "SquareIcon's 0.08 stands")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(texCoord(m, sq.icon), inset(0.08), "and on every replay")
  local loose = m.CreateFrame("Frame", nil, m.UIParent)
  loose.icon = loose:CreateTexture()
  loose.icon:SetTexCoord(0.02, 0.98, 0.1, 0.9)
  S.IconBorder(loose, { fromSkin = true })
  assertEqual(texCoord(m, loose.icon), table.concat({ 0.07, 0.1, 0.07, 0.9, 0.93, 0.1, 0.93, 0.9 }, ","),
    "each axis takes the larger inset: 0.07 over 0.02, the host's 0.1 kept")
  local stub = m.CreateFrame("Frame", nil, m.UIParent)
  stub.icon = stub:CreateTexture()
  rawset(stub.icon, "GetTexCoord", function(self) return self end)   -- a host's bare stub (WhatGroup's mock)
  S.IconBorder(stub, { fromSkin = true })
  assertEqual(texCoord(m, stub.icon), inset(0.07), "coords that are not numbers read as the full texture")
end)

-- ── one physical pixel after a scale change (R3-FIX: the size was taken once, at paint time) ──

--- An environment whose frames answer `scale.v` as their effective scale and whose hooksecurefunc
--- post-hooks for real, with PixelUtil's factor 1. A frame answers its parent and its last SetScale
--- (the kit's base frame answers neither).
local function scaledEnv()
  local m, Skin = F.env()
  local scale = { v = 1 }
  m.PixelUtil = { GetPixelToUIUnitFactor = function() return 1 end }
  m.hooksecurefunc = function(t, name, fn)
    local orig = t[name]
    rawset(t, name, function(...) local r = orig(...); fn(...); return r end)
  end
  local make = m.CreateFrame
  m.CreateFrame = function(kind, name, parent, ...)
    local f = make(kind, name, parent, ...)
    rawset(f, "GetEffectiveScale", function() return scale.v end)
    rawset(f, "GetParent", function() return parent end)
    rawset(f, "GetScale", function(self) return rawget(self, "__s") or 1 end)
    rawset(f, "SetScale", function(self, s) rawset(self, "__s", s) end)
    return f
  end
  return m, Skin, scale
end

test("skin icon border: the outline and FadeNineSlice's ring re-size when UIParent's size moves, no event registered", function()
  -- red under: P.px read once at paint time, so the edge drew 2 px after the player raised the UI scale.
  -- Hooked, never an event: a library frame registered for UI_SCALE_CHANGED outlived every host's
  -- stand-down (the hosts' slash-commands-§7 conformance suites).
  local m, Skin, scale = scaledEnv()
  local S = F.owner(Skin, OWNER, "midnight")
  local f = m.CreateFrame("Frame", nil, m.UIParent)
  local ns = m.CreateFrame("Frame", nil, m.UIParent)
  ns.NineSlice = m.CreateFrame("Frame", nil, ns)
  S.IconBorder(f, { fromSkin = true })
  S.FadeNineSlice(ns)
  assertEqual(F.region(Skin, f, "edgeTop"):GetHeight(), 1)
  assertEqual(F.region(Skin, ns, "ringLeft"):GetWidth(), 1)
  assertEqual(#m.__registrations(), 0, "no registration: a host's stand-down leaves none behind")
  scale.v = 2
  m.UIParent:__fire("OnSizeChanged", 1280, 720)   -- a UI scale change resizes UIParent
  assertEqual(F.region(Skin, f, "edgeTop"):GetHeight(), 0.5, "the icon outline: one pixel at scale 2")
  assertEqual(F.region(Skin, f, "edgeRight"):GetWidth(), 0.5)
  assertEqual(F.region(Skin, ns, "ringLeft"):GetWidth(), 0.5, "the ring too")
  scale.v = 4
  m.UIParent:__fire("OnSizeChanged", 640, 360)
  assertEqual(F.region(Skin, ns, "ringTop"):GetHeight(), 0.25, "and on a display size change")
end)

test("skin icon border: a host's SetScale on an ancestor re-sizes the outline, an unchanged scale costs nothing", function()
  -- red under: DpsRace's HUD (ui.frame:SetScale on every Refresh) keeping the edge sized for the old scale.
  local m, Skin, scale = scaledEnv()
  local S = F.owner(Skin, OWNER)
  local win = m.CreateFrame("Frame", nil, m.UIParent)
  local row = m.CreateFrame("Frame", nil, win)
  local tex = row:CreateTexture()
  S.IconBorder(tex, { fromSkin = true })
  assertEqual(F.region(Skin, tex, "edgeTop"):GetHeight(), 1)
  scale.v = 2
  win:SetScale(2)
  assertEqual(F.region(Skin, tex, "edgeTop"):GetHeight(), 0.5, "re-sized after the ancestor's SetScale")
  local top = F.region(Skin, tex, "edgeTop")
  local calls = 0
  local set = top.SetHeight
  rawset(top, "SetHeight", function(...) calls = calls + 1; return set(...) end)
  win:SetScale(2)
  assertEqual(calls, 0, "the same scale again re-sizes nothing")
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
  assertEqual(Skin:Token(OWNER, "icon.borderSize"), 1)
  assertTrue(survey(m, F.region(Skin, f, "edgeTop")).shown, "drawn")
  assertEqual(F.rgba(survey(m, F.region(Skin, f, "edgeTop")).color), F.rgba(S.Token("icon.outline")),
    "SkinEUI minor 4's, half EllesmereUI's panel color (icon.outline since R4-L3)")
  assertNil(Skin.euiRefused[OWNER], "nothing refused")
end)
