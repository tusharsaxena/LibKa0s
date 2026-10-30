-- tests/test_skin_width_parity.lua — LibKa0s-Skin-1.0's width parity: every skin's text is as wide as
-- Ka0s Default's (SkinDefs minor 17; LK-05 of Ka0sAddonsCommonTasks docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK,
-- the owner's item 5 and ruling D-08), its HUD text too (LK-06, ruling D-09), and S.HudFontSize, which
-- scales a HUD element's stored size by its skin's factor (SkinPaintExtras minor 7).
--
-- What it pins: each skin's body, title and HUD sizes, and that each one, times its face's measured
-- average advance per em, lands within the band below of Ka0s Default's Prototype at 12 / 14. The
-- WIDTH table is the measurement of that bundle's plan-data/font_metrics_shipped.py, run on the
-- shipped bytes (LibKa0s/media/fonts) with OUTLINE on (its section 9: HarfBuzz-shaped advances,
-- kerning on, over the body, title and HUD corpora). The sizes themselves were picked under six
-- pixel-snapping layout models with and without an outline's extra pixel (its sections 7 and 8);
-- this suite checks the linear model, which is enough to catch a face or a size changed without a
-- re-measure.
--
-- red under: a size changed so a skin runs more than 2% wider than Ka0s Default (wide truncates
-- first) or more than 5% narrower; a skin given a face this table has no measurement for (re-run the
-- script and add its row); WoW Default's sizes moved before real Friz Quadrata is measured (D-05,
-- IS-07); High Contrast's description promising larger type again.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local F = dofile("tests/fixture_skin_paint.lua")

local MAJOR = "LibKa0s-Skin-1.0"
local function skinLib() return T.mocks.LibStub(MAJOR) end

-- Average advance per em, by role corpus (font_metrics_shipped.txt section 9).
local WIDTH = {
  ["Ka0s Prototype"]          = { body = 0.4735, title = 0.4804, hud = 0.4911 },
  ["Ka0s Expressway"]         = { body = 0.4447, title = 0.4527, hud = 0.4590 },
  ["Ka0s Vollkorn"]           = { body = 0.4671, title = 0.4804, hud = 0.4923 },
  ["Ka0s Vollkorn Bold"]      = { body = 0.4989, title = 0.5165, hud = 0.5238 },
  ["Ka0s Nunito"]             = { body = 0.4850, title = 0.4882, hud = 0.5161 },
  ["Ka0s Nunito SemiBold"]    = { body = 0.4926, title = 0.4967, hud = 0.5231 },
  ["Ka0s Atkinson"]           = { body = 0.4698, title = 0.4806, hud = 0.4944 },
  ["Ka0s Atkinson Bold"]      = { body = 0.5061, title = 0.5158, hud = 0.5277 },
  ["Ka0s Bitter"]             = { body = 0.4923, title = 0.5061, hud = 0.5156 },
  ["Ka0s Bitter Bold"]        = { body = 0.5032, title = 0.5169, hud = 0.5282 },
  ["Ka0s Philosopher"]        = { body = 0.4543, title = 0.4673, hud = 0.4753 },
  ["Ka0s Philosopher Bold"]   = { body = 0.4720, title = 0.4864, hud = 0.4942 },
  ["Ka0s Fira Sans Medium"]   = { body = 0.4765, title = 0.4868, hud = 0.4952 },
  ["Ka0s Fira Sans SemiBold"] = { body = 0.4779, title = 0.4883, hud = 0.4975 },
}

-- The sizes the measurement picked (its section 8): { font.bodySize, font.titleSize, hud.fontSize }.
local SIZES = {
  ka0s = { 12, 14, 12 }, obsidian = { 12.5, 14.5, 13 }, azeroth = { 12, 12.5, 11 }, glass = { 11.5, 13, 11 },
  contrast = { 12, 13, 11 }, ember = { 11.5, 12.5, 11 }, wow = { 12, 14, 12 }, midnight = { 12.5, 13.5, 12 },
  forever = { 12, 13.5, 11.5 },
}
local KEYS = { "ka0s", "obsidian", "azeroth", "glass", "contrast", "ember", "wow", "midnight", "forever" }

-- role: the face token, the size token, the WIDTH column.
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
    if key ~= "wow" then
      local t = Skin:ResolveSkin(key)
      for _, role in ipairs(ROLES) do
        local e = widthError(t, ref, role)
        assertTrue(e <= WIDER and e >= -NARROWER, ("%s %s: %+.1f%% against Ka0s Default"):format(
          key, role[3], e * 100))
      end
    end
  end
end)

test("skin width parity: WoW Default keeps Ka0s Default's sizes until real Friz Quadrata is measured", function()
  -- D-05: on the owner's client Fonts/FRIZQT__.TTF is byte-identical to Prototype, so the parity is
  -- exact there and unmeasured anywhere else (IS-07 asks for the real face).
  local Skin = skinLib()
  local ref, wow = Skin:ResolveSkin("ka0s"), Skin:ResolveSkin("wow")
  for _, role in ipairs(ROLES) do
    assertEqual(wow[role[2]], ref[role[2]], "WoW Default's " .. role[2])
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

test("skin hud size: a font override keeps the skin's sizes, HUD and body alike", function()
  -- Today's behavior, pinned until the owner rules otherwise (LK-05/06 review: an override draws a
  -- face at a size measured for the skin's own). red under: an override silently moving the sizes.
  local _, Skin = F.env({ lsm = { ["font:Ka0s Prototype"] = "Fonts\\Prototype.ttf" } })
  Skin:RegisterOwner(OWNER, { set = function() end })
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  local S = Skin:For(OWNER)
  Skin:SetOverride(OWNER, "Ka0s Prototype", nil)
  assertEqual(S.Token("hud.font"), "Ka0s Prototype", "the override draws")
  assertEqual(S.HudFontSize(12), 13, "Obsidian's HUD scale stands")
  assertEqual(S.Token("font.bodySize"), 12.5, "and its body size")
  assertEqual(S.BarStyle().fontSize, 13, "BarStyle's size too")
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
