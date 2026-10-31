-- tests/test_skin_width_parity.lua — LibKa0s-Skin-1.0's width parity: every skin's text is as wide as
-- Ka0s Default's (SkinDefs minor 17; LK-05 of Ka0sAddonsCommonTasks docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK,
-- the owner's item 5 and ruling D-08), its HUD text too (LK-06, ruling D-09), S.HudFontSize, which
-- scales a HUD element's stored size by its skin's factor (SkinPaintExtras minor 7), and the sizes a
-- font override of a shipped face draws at (SkinDefs minor 18, Skin minor 10; LK-F02 of
-- docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES, its D-03 and D-07).
--
-- What it pins: each skin's body, title and HUD sizes, and that each one, times its face's measured
-- average advance per em, lands within the band below of Ka0s Default's Prototype at 12 / 14. The
-- WIDTH table is the measurement of the 2026-10-31 bundle's plan-data/font_metrics_shipped.py, run on
-- the shipped bytes (LibKa0s/media/fonts) with OUTLINE on (its section 10: HarfBuzz-shaped advances,
-- kerning on, over the body, title and HUD corpora). The sizes themselves were picked under six
-- pixel-snapping layout models with and without an outline's extra pixel (its sections 7, 8 and 10);
-- this suite checks the linear model, which is enough to catch a face or a size changed without a
-- re-measure.
--
-- red under: a size changed so a skin runs more than 2% wider than Ka0s Default (wide truncates
-- first) or more than 5% narrower; a skin given a face this table has no measurement for (re-run the
-- script and add its row); a skin's size that is not its face's row in the library's table; a shipped
-- face with no row there; High Contrast's description promising larger type again.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local F = dofile("tests/fixture_skin_paint.lua")

local MAJOR = "LibKa0s-Skin-1.0"
local function skinLib() return T.mocks.LibStub(MAJOR) end

-- Average advance per em, by role corpus, of every shipped face (lib.FONTS): the 2026-10-31 bundle's
-- font_metrics_shipped.txt, its section 10.
local WIDTH = {
  ["JetBrains Mono"]           = { body = 0.6000, title = 0.6000, hud = 0.6000 },
  ["Ka0s Atkinson"]            = { body = 0.4698, title = 0.4806, hud = 0.4944 },
  ["Ka0s Atkinson Bold"]       = { body = 0.5061, title = 0.5158, hud = 0.5277 },
  ["Ka0s Avant Garde"]         = { body = 0.5070, title = 0.5156, hud = 0.5219 },
  ["Ka0s Bitter"]              = { body = 0.4923, title = 0.5061, hud = 0.5156 },
  ["Ka0s Bitter Bold"]         = { body = 0.5032, title = 0.5169, hud = 0.5282 },
  ["Ka0s Doris PP"]            = { body = 0.5248, title = 0.5330, hud = 0.5500 },
  ["Ka0s Emblem"]              = { body = 0.5066, title = 0.5183, hud = 0.5290 },
  ["Ka0s Expressway"]          = { body = 0.4447, title = 0.4527, hud = 0.4590 },
  ["Ka0s Fira Sans Medium"]    = { body = 0.4765, title = 0.4868, hud = 0.4952 },
  ["Ka0s Fira Sans SemiBold"]  = { body = 0.4779, title = 0.4883, hud = 0.4975 },
  ["Ka0s Friz Quadrata TT"]    = { body = 0.5046, title = 0.5067, hud = 0.5333 },
  ["Ka0s Nunito"]              = { body = 0.4850, title = 0.4882, hud = 0.5161 },
  ["Ka0s Nunito SemiBold"]     = { body = 0.4926, title = 0.4967, hud = 0.5231 },
  ["Ka0s Open Sans"]           = { body = 0.4929, title = 0.5004, hud = 0.5196 },
  ["Ka0s Open Sans Bold"]      = { body = 0.5253, title = 0.5359, hud = 0.5483 },
  ["Ka0s Open Sans Condensed"] = { body = 0.4135, title = 0.4182, hud = 0.4323 },
  ["Ka0s Open Sans Light"]     = { body = 0.4756, title = 0.4819, hud = 0.5025 },
  ["Ka0s Open Sans Semibold"]  = { body = 0.5088, title = 0.5180, hud = 0.5337 },
  ["Ka0s Philosopher"]         = { body = 0.4543, title = 0.4673, hud = 0.4753 },
  ["Ka0s Philosopher Bold"]    = { body = 0.4720, title = 0.4864, hud = 0.4942 },
  ["Ka0s Prototype"]           = { body = 0.4735, title = 0.4804, hud = 0.4911 },
  ["Ka0s Segoe UI"]            = { body = 0.4682, title = 0.4719, hud = 0.4919 },
  ["Ka0s Segoe UI Bold"]       = { body = 0.5015, title = 0.5065, hud = 0.5289 },
  ["Ka0s Segoe UI Light"]      = { body = 0.4537, title = 0.4579, hud = 0.4754 },
  ["Ka0s Segoe UI Semibold"]   = { body = 0.4815, title = 0.4872, hud = 0.5047 },
  ["Ka0s Vollkorn"]            = { body = 0.4671, title = 0.4804, hud = 0.4923 },
  ["Ka0s Vollkorn Bold"]       = { body = 0.4989, title = 0.5165, hud = 0.5238 },
}

-- The sizes the measurement picked (its section 8): { font.bodySize, font.titleSize, hud.fontSize }.
local SIZES = {
  ka0s = { 12, 14, 12 }, obsidian = { 12.5, 14.5, 13 }, azeroth = { 11, 12, 11 }, glass = { 11, 13, 11 },
  contrast = { 10.5, 12.5, 10.5 }, ember = { 11, 12.5, 11 }, wow = { 11, 13, 11 }, midnight = { 11.5, 13, 11.5 },
  forever = { 12, 13.5, 11.5 },
}
local KEYS = { "ka0s", "obsidian", "azeroth", "glass", "contrast", "ember", "wow", "midnight", "forever" }

local ROLES = {
  { "font.body", "font.bodySize", "body" },
  { "font.title", "font.titleSize", "title" },
  { "hud.font", "hud.fontSize", "hud" },
}
local WIDER, NARROWER = 0.02, 0.05

--- A skin's width error for one role against Ka0s Default's: size * advance over the reference's - 1.
local function widthError(t, ref, role)
  local face, sizeTok, col = role[1], role[2], role[3]
  local w, base = WIDTH[t[face]], WIDTH[ref[face]]
  assertTrue(w ~= nil, tostring(t[face]) .. " has a measured width (re-run font_metrics_shipped.py)")
  return t[sizeTok] * w[col] / (ref[sizeTok] * base[col]) - 1
end

test("skin width parity: every skin's body, title and HUD sizes are the measured ones", function()
  local Skin = skinLib()
  for _, key in ipairs(KEYS) do
    local t = Skin:ResolveSkin(key)
    assertEqual(t["font.bodySize"], SIZES[key][1], key .. "'s body size")
    assertEqual(t["font.titleSize"], SIZES[key][2], key .. "'s title size")
    assertEqual(t["hud.fontSize"], SIZES[key][3], key .. "'s HUD size")
  end
end)

test("skin width parity: every skin's text is as wide as Ka0s Default's, never more than 2% wider", function()
  local Skin = skinLib()
  local ref = Skin:ResolveSkin("ka0s")
  assertEqual(ref["font.body"], "Ka0s Prototype", "the baseline is Prototype")
  for _, key in ipairs(KEYS) do
    local t = Skin:ResolveSkin(key)
    for _, role in ipairs(ROLES) do
      local e = widthError(t, ref, role)
      assertTrue(e <= WIDER and e >= -NARROWER, ("%s %s: %+.1f%% against Ka0s Default"):format(
        key, role[3], e * 100))
    end
  end
end)

test("skin width parity: every shipped face has a size for each role, as wide as Ka0s Default's", function()
  -- D-07. red under: a face added to lib.FONTS with no row (an override of it draws at the skin's
  -- size), a row off the measurement, or the reference moving.
  local Skin = skinLib()
  local Media = T.mocks.LibStub("LibKa0s-Media-1.0")
  local ref = Skin.__FACE_SIZES["Ka0s Prototype"]
  assertEqual(table.concat(ref, " "), "12 14 12", "Prototype is the reference")
  local count = 0
  for key in pairs(Media.FONTS) do
    local row, w = Skin.__FACE_SIZES[key], WIDTH[key]
    assertTrue(row ~= nil, key .. " has a size row")
    assertTrue(w ~= nil, key .. " has a measured width")
    for i, col in ipairs({ "body", "title", "hud" }) do
      local e = row[i] * w[col] / (ref[i] * WIDTH["Ka0s Prototype"][col]) - 1
      assertTrue(e <= WIDER and e >= -NARROWER, ("%s %s: %+.1f%%"):format(key, col, e * 100))
    end
    count = count + 1
  end
  assertEqual(count, 28, "the shipped faces")
  for key in pairs(Skin.__FACE_SIZES) do
    assertTrue(Media.FONTS[key] ~= nil, key .. "'s row names a shipped face")
  end
end)

test("skin width parity: a skin's sizes are its faces' rows in the library's table", function()
  -- One measurement, so a skin and an override of the same face cannot disagree.
  local Skin = skinLib()
  for _, key in ipairs(KEYS) do
    local t = Skin:ResolveSkin(key)
    for i, role in ipairs(ROLES) do
      assertEqual(t[role[2]], Skin.__FACE_SIZES[t[role[1]]][i], key .. "'s " .. role[2])
    end
  end
end)

test("skin width parity: High Contrast no longer promises larger type", function()
  local Skin = skinLib()
  local desc = Skin:GetSkin("contrast").desc
  assertTrue(not desc:lower():find("larger"), "High Contrast's description: " .. desc)
  assertEqual(desc, "Black and white with yellow focus, crisp 1px edges.", "High Contrast's description")
end)

-- ── S.HudFontSize (SkinPaintExtras minor 7, LK-06, D-09) ─────────────────────────────────────

local OWNER = "LootHistory"

local function hudOwner(skin)
  local _, Skin = F.env()
  Skin:RegisterOwner(OWNER, { set = function() end })
  if skin then Skin:SetChoice(OWNER, "ka0s", skin) end
  return Skin, Skin:For(OWNER)
end

test("skin hud size: HudFontSize is in the vocabulary and the facade", function()
  local _, Skin = F.env()
  local found = false
  for _, name in ipairs(Skin.VOCAB) do if name == "HudFontSize" then found = true end end
  assertTrue(found, "VOCAB names it")
  assertEqual(type(Skin:For(OWNER).HudFontSize), "function", "the facade carries it")
end)

test("skin hud size: a stored size scales by the skin's HUD size over Ka0s Default's", function()
  -- red under: HudFontSize answering the stored size under every skin (the HUD keeps its width in
  -- none), or the skin's absolute hud.fontSize (a 36pt element drawn at 13).
  local _, S = hudOwner("obsidian")
  assertEqual(S.HudFontSize(12), 13, "Obsidian: 12 draws at 13")
  assertEqual(S.HudFontSize(36), 39, "and 36 at 39")
  assertEqual(S.HudFontSize(12, true), 13, "fromSkin true is the same")
  local _, G = hudOwner("glass")
  assertEqual(G.HudFontSize(24), 22, "Glass: 24 draws at 22")
  local _, K = hudOwner()
  assertEqual(K.HudFontSize(14), 14, "Ka0s Default: the stored size")
end)

test("skin hud size: its own face, Ignore fonts and a bad size leave the stored size alone", function()
  -- red under: a player's own face scaled by the skin's factor (it was measured for the skin's face),
  -- Ignore fonts scaled (the host's own setting stands), or an answer SetFont refuses.
  local Skin, S = hudOwner("obsidian")
  assertEqual(S.HudFontSize(12, false), 12, "fromSkin false: the stored size")
  assertEqual(S.HudFontSize(0), 13, "no stored size: the skin's HUD size")
  assertEqual(S.HudFontSize(nil), 13, "nothing stored either")
  assertEqual(S.HudFontSize("x", false), 12, "never a height SetFont refuses")
  Skin:SetIgnore(OWNER, nil, true)
  assertEqual(S.HudFontSize(12), 12, "Ignore fonts: unscaled")
  assertEqual(S.HudFontSize(nil), 12, "and never nil")
  assertEqual(Skin:For("Nobody").HudFontSize(20), 20, "an unregistered owner reads Ka0s Default")
end)

test("skin hud size: the stored value is never rewritten, and the scale follows a live skin change", function()
  local Skin, S = hudOwner("azeroth")
  local profile = { size = 24 }
  assertEqual(S.HudFontSize(profile.size), 22, "Azeroth: 24 draws at 22")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(S.HudFontSize(profile.size), 26, "Obsidian: 26, from the same stored 24")
  assertEqual(profile.size, 24, "the stored size stands")
end)

local function overrideOwner(skin, lsm)
  local _, Skin = F.env({ lsm = lsm })
  Skin:RegisterOwner(OWNER, { set = function() end })
  Skin:SetChoice(OWNER, "ka0s", skin)
  return Skin, Skin:For(OWNER)
end

test("skin hud size: an override of a shipped face draws at that face's sizes, HUD and body alike", function()
  -- D-07, which retires the pin of LK-05/06's review (an override kept the skin's sizes, so Ka0s
  -- Emblem under Obsidian drew at Expressway's 12.5). red under: an override keeping the skin's
  -- sizes, or moving one role and not the others.
  local Skin, S = overrideOwner("obsidian", { ["font:Ka0s Prototype"] = "Fonts\\Prototype.ttf",
    ["font:Ka0s Emblem"] = "Fonts\\Emblem.ttf" })
  Skin:SetOverride(OWNER, "Ka0s Prototype", nil)
  assertEqual(S.Token("hud.font"), "Ka0s Prototype", "the override draws")
  assertEqual(S.HudFontSize(12), 12, "Prototype on the HUD: Ka0s Default's 12, not Obsidian's 13")
  assertEqual(S.HudFontSize(24), 24, "a stored size unscaled by the skin")
  assertEqual(S.Token("font.bodySize"), 12, "the body")
  assertEqual(S.Token("font.titleSize"), 14, "the title")
  assertEqual(S.BarStyle().fontSize, 12, "BarStyle's size too")
  Skin:SetOverride(OWNER, "Ka0s Emblem", nil)
  assertEqual(S.Token("font.bodySize"), 11, "Emblem's body")
  assertEqual(S.Token("font.titleSize"), 12.5, "Emblem's title")
  assertEqual(S.HudFontSize(24), 22, "Emblem's HUD scale")
  Skin:SetOverride(OWNER, false, nil)
  assertEqual(S.Token("font.bodySize"), 12.5, "cleared: Obsidian's own")
  assertEqual(S.HudFontSize(12), 13, "and its HUD scale")
  assertEqual(Skin:__BaseTokens(OWNER)["font.bodySize"], 12.5, "the base table never moved")
end)

test("skin hud size: a face the library did not measure keeps the skin's sizes", function()
  -- D-07: unmeasurable in the client. red under: a pack's face scaled by a guess.
  local Skin, S = overrideOwner("obsidian", { ["font:Some Pack Face"] = "Fonts\\Pack.ttf" })
  Skin:SetOverride(OWNER, "Some Pack Face", nil)
  assertEqual(S.Token("hud.font"), "Some Pack Face", "the override draws")
  assertEqual(S.Token("font.bodySize"), 12.5, "Obsidian's body size")
  assertEqual(S.Token("font.titleSize"), 14.5, "and its title size")
  assertEqual(S.HudFontSize(12), 13, "and its HUD scale")
end)

test("skin hud size: an override's sizes wait for it to resolve, and stay out of its own-face HUD", function()
  -- red under: a Ka0s face no LSM carries moving the sizes of the skin's own face that stands, or an
  -- element on its own face scaled by an override it does not draw.
  local Skin, S = overrideOwner("obsidian", { ["font:Ka0s Emblem"] = "Fonts\\Emblem.ttf" })
  Skin:SetOverride(OWNER, "Ka0s Doris PP", nil)
  assertEqual(S.Token("hud.font"), "Ka0s Expressway", "unresolved: the skin's face stands")
  assertEqual(S.Token("font.bodySize"), 12.5, "at the skin's size")
  Skin:SetOverride(OWNER, "Ka0s Emblem", nil)
  assertEqual(S.HudFontSize(24, false), 24, "fromSkin false: as stored")
end)

test("skin hud size: BarStyle's fontSize is each skin's own, Ka0s Default's under Ignore fonts", function()
  -- red under: BarStyle answering 12 in every skin (the showroom's worn line loses its width), or a
  -- skin's measured size while fonts are ignored (the host's own face drawn at a size measured for
  -- the skin's).
  for key, want in pairs({ obsidian = 13, glass = 11, ka0s = 12, forever = 11.5 }) do
    local _, S = hudOwner(key ~= "ka0s" and key or nil)
    assertEqual(S.BarStyle().fontSize, want, key .. "'s BarStyle size")
  end
  local Skin, S = hudOwner("obsidian")
  Skin:SetIgnore(OWNER, nil, true)
  assertEqual(S.BarStyle().fontSize, 12, "Ignore fonts: Ka0s Default's 12, as HudFontSize answers")
  assertEqual(S.BarStyle().fontSize, S.HudFontSize(), "the two agree")
end)

test("skin hud size: an EllesmereUI owner reads Ka0s Default's HUD size, unscaled", function()
  local E = dofile("tests/fixture_skin_eui.lua")
  local _, Skin, eui = E.env()
  E.owner(Skin, OWNER, "eui", "obsidian")
  eui.login()
  local S = Skin:For(OWNER)
  assertEqual(S.HudFontSize(24), 24, "the eui source draws Ka0s Default's sizes")
  assertEqual(S.BarStyle().fontSize, 12)
end)
