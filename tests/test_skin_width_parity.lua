-- tests/test_skin_width_parity.lua — LibKa0s-Skin-1.0's width parity: every skin's text is as wide as
-- Ka0s Default's (SkinDefs minor 17; LK-05 of Ka0sAddonsCommonTasks docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK,
-- the owner's item 5 and ruling D-08).
--
-- What it pins: each skin's body and title sizes, and that each one, times its face's measured
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

-- The sizes the measurement picked (its section 8): { font.bodySize, font.titleSize }.
local SIZES = {
  ka0s = { 12, 14 }, obsidian = { 12.5, 14.5 }, azeroth = { 12, 12.5 }, glass = { 11.5, 13 },
  contrast = { 12, 13 }, ember = { 11.5, 12.5 }, wow = { 12, 14 }, midnight = { 12.5, 13.5 },
  forever = { 12, 13.5 },
}
local KEYS = { "ka0s", "obsidian", "azeroth", "glass", "contrast", "ember", "wow", "midnight", "forever" }

-- role: the face token, the size token, the WIDTH column.
local ROLES = {
  { "font.body", "font.bodySize", "body" },
  { "font.title", "font.titleSize", "title" },
}
local WIDER, NARROWER = 0.02, 0.05

--- A skin's width error for one role against Ka0s Default's: size * advance over the reference's - 1.
local function widthError(t, ref, role)
  local face, sizeTok, col = role[1], role[2], role[3]
  local w, base = WIDTH[t[face]], WIDTH[ref[face]]
  assertTrue(w ~= nil, tostring(t[face]) .. " has a measured width (re-run font_metrics_shipped.py)")
  return t[sizeTok] * w[col] / (ref[sizeTok] * base[col]) - 1
end

test("skin width parity: every skin's body and title sizes are the measured ones", function()
  local Skin = skinLib()
  for _, key in ipairs(KEYS) do
    local t = Skin:ResolveSkin(key)
    assertEqual(t["font.bodySize"], SIZES[key][1], key .. "'s body size")
    assertEqual(t["font.titleSize"], SIZES[key][2], key .. "'s title size")
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
