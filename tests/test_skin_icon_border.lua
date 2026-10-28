-- tests/test_skin_icon_border.lua — LibKa0s-Skin-1.0's icon border family (LK-04 of
-- Ka0sAddonsCommonTasks docs/2026-10-29-SKINNING_ROLLOUT, gap DW-G14): `icon.borderStyle` and
-- `icon.borderSize` beside `icon.border`, so an item icon's border can follow the skin the way a
-- bar's does (SkinDefs minor 15), and `S.IconBorder(frame, { fromSkin = true })` drawing them.
--
-- What it pins: the two tokens are in the schema's HUD group and every one of the nine skins sets
-- both itself; Ka0s Default's are Drop Watcher's Window › Icons border today (Solid, 2px, in
-- `icon.border`'s black); every style a skin names is one the library can draw; S.IconBorder WITHOUT
-- `fromSkin` paints exactly what it painted before (flat, `opts.size` or 1); WITH it, the skin's style
-- and size, repainted on a skin switch, "None" drawing nothing; and under the eui source it is
-- painted by the library from the EllesmereUI-derived tokens, never handed to EllesmereUI.
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

test("skin icon border: fromSkin draws Ka0s Default's Solid 2px in icon.border", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local f = m.CreateFrame("Frame", nil, m.UIParent)
  S.IconBorder(f, { fromSkin = true })
  assertEqual(edgeSizes(m, Skin, S, f, { fromSkin = true }),
    "#2:SetHeight(2)\n#3:SetHeight(2)\n#4:SetWidth(2)\n#5:SetWidth(2)", "2px")
  for _, side in ipairs({ "Top", "Bottom", "Left", "Right" }) do
    local r = survey(m, F.region(Skin, f, "edge" .. side))
    assertEqual(F.rgba(r.color), "0,0,0,1", side .. " black")
    assertTrue(r.shown, side .. " shown")
  end
  assertNil(F.region(Skin, f, "nine"), "Solid is the flat edge, no nine-slice")
end)

test("skin icon border: fromSkin wins over opts.size, and a skin switch repaints style and size", function()
  local m, Skin = F.env({ lsm = { ["border:Blizzard Tooltip"] = "Interface\\Tooltips\\UI-Tooltip-Border" } })
  local S = F.owner(Skin, OWNER)
  local f = m.CreateFrame("Frame", nil, m.UIParent)
  S.IconBorder(f, { fromSkin = true, size = 5 })
  assertEqual(edgeSizes(m, Skin, S, f, { fromSkin = true, size = 5 }),
    "#2:SetHeight(2)\n#3:SetHeight(2)\n#4:SetWidth(2)\n#5:SetWidth(2)", "the skin's size, not opts.size")
  Skin:SetChoice(OWNER, "ka0s", "wow")
  local t = Skin:ResolveSkin("wow")
  local nine = F.region(Skin, f, "nine")
  assertTrue(nine ~= nil, "WoW Default's " .. t["icon.borderStyle"] .. " is a nine-slice")
  local bd = survey(m, nine).backdrop
  assertEqual(bd.edgeFile, "Interface\\Tooltips\\UI-Tooltip-Border")
  assertEqual(bd.edgeSize, t["icon.borderSize"])
  assertEqual(F.rgba(survey(m, nine).backdropBorderColor), F.tok(Skin, "wow", "icon.border"))
  assertTrue(not survey(m, F.region(Skin, f, "edgeTop")).shown, "the flat edges hidden")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertNil(F.region(Skin, f, "nine"), "back to flat")
  assertEqual(edgeSizes(m, Skin, S, f, { fromSkin = true, size = 5 }),
    ("#2:SetHeight(%d)\n#3:SetHeight(%d)\n#4:SetWidth(%d)\n#5:SetWidth(%d)"):format(
      Skin:ResolveSkin("obsidian")["icon.borderSize"], Skin:ResolveSkin("obsidian")["icon.borderSize"],
      Skin:ResolveSkin("obsidian")["icon.borderSize"], Skin:ResolveSkin("obsidian")["icon.borderSize"]),
    "Obsidian's own size")
end)

test("skin icon border: a skin whose icon.borderStyle is None draws no border", function()
  local m, Skin = F.env()
  Skin:RegisterSkin({ key = "bare", tokens = { ["icon.borderStyle"] = "None", ["icon.borderSize"] = 1 } })
  local S = F.owner(Skin, OWNER)
  local f = m.CreateFrame("Frame", nil, m.UIParent)
  S.IconBorder(f, { fromSkin = true })
  assertTrue(survey(m, F.region(Skin, f, "edgeTop")).shown, "Ka0s Default draws it")
  Skin:SetChoice(OWNER, "ka0s", "bare")
  assertTrue(not survey(m, F.region(Skin, f, "edgeTop")).shown, "None hides it")
  assertNil(F.region(Skin, f, "nine"))
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
  assertEqual(F.rgba(survey(m, F.region(Skin, f, "edgeTop")).color), "0,0,0,1")
  assertNil(Skin.euiRefused[OWNER], "nothing refused")
end)
