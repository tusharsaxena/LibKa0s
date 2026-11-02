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

test("skin icon border: Ka0s Default's is Solid 1px black", function()
  -- Drop Watcher's Window › Icons border was Solid 2px until R3-FIX of Ka0sAddonsCommonTasks
  -- docs/2026-11-02-SMOKE_ROUND3: the owner's "exactly 1 px in every skin" reaches the hosts that
  -- draw their own icon border from these tokens (KickCD, ConsumableMaster, DropWatcher).
  local _, Skin = F.env()
  local t = Skin:ResolveSkin("ka0s")
  assertEqual(t["icon.borderStyle"], "Solid")
  assertEqual(t["icon.borderSize"], 1)
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
  assertEqual(F.rgba(survey(m, F.region(Skin, f, "edgeTop")).color), F.rgba(S.Token("icon.border")),
    "SkinEUI minor 4's, half EllesmereUI's panel color")
  assertNil(Skin.euiRefused[OWNER], "nothing refused")
end)
