-- tests/test_skin_override.lua — LibKa0s-Skin-1.0's per-owner font and texture overrides (Skin
-- minor 6, LibKa0s#63; SO-01 of Ka0sAddonsCommonTasks docs/2026-10-28-SKIN_OVERRIDES_AND_PICKER):
-- GetOverride, SetOverride, the overrides laid over the owner's tokens in `__Tokens`, and
-- WriteChoice's fourth setter argument `media`.
--
-- What it pins: an override reaches every token read (`Token`, `Color`, the facade) and a painted
-- string's face on the repaint it triggers; clearing it gives the skin's own back; a repeat is no
-- change; one owner's override never reaches another owner; `ResolveSkin` stays override-free (the
-- picker and the Appearance tab read other skins' real tokens through it); an owner with no override
-- reads the resolved table itself; WriteChoice hands `media` on normalized; and an override set
-- while a reload is pending is stored without a repaint.
--
-- Every case runs on a fresh environment (tests/fixture_skin_paint.lua), so the owners one case
-- registers never reach another.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local F = dofile("tests/fixture_skin_paint.lua")

local OWNER, OTHER = "LootHistory", "BankLedger"
local LSM = { ["font:Ka0s Inter"] = "Fonts\\Inter.ttf", ["font:Ka0s Nunito"] = "Fonts\\Nunito.ttf",
              ["statusbar:Blizzard"] = "Interface\\TargetingFrame\\UI-StatusBar",
              ["statusbar:Ka0s Flat"] = "Interface\\Ka0s\\Flat" }

--- Register `owner` with a store its setter writes; answers the store.
local function register(Skin, owner)
  local store = { calls = 0 }
  Skin:RegisterOwner(owner, {
    set = function(source, skin, ignore, media)
      store.calls = store.calls + 1
      store.source, store.skin, store.ignore, store.media = source, skin, ignore, media
    end,
  })
  return store
end

test("skin override: an unregistered owner has none and cannot set one", function()
  local _, Skin = F.env()
  local font, texture = Skin:GetOverride("Nobody")
  assertNil(font); assertNil(texture)
  assertFalse(Skin:SetOverride("Nobody", "Ka0s Inter", nil), "no owner, no change")
  assertNil((Skin:GetOverride("Nobody")))
end)

test("skin override: a font and a texture reach every token read, and nothing else moves", function()
  local _, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local S = Skin:For(OWNER)
  local base = Skin:ResolveSkin("ka0s")
  assertTrue(Skin:__Tokens(OWNER) == base, "with no override the owner reads the resolved table itself")
  assertTrue(Skin:SetOverride(OWNER, "Ka0s Inter", "Ka0s Flat"), "a change")
  local font, texture = Skin:GetOverride(OWNER)
  assertEqual(font, "Ka0s Inter"); assertEqual(texture, "Ka0s Flat")
  for _, name in ipairs({ "font.body", "font.title", "hud.font" }) do
    assertEqual(Skin:Token(OWNER, name), "Ka0s Inter", name .. " is the override")
  end
  assertEqual(S.Token("bar.texture"), "Ka0s Flat", "the facade reads the texture override")
  assertEqual(Skin:Token(OWNER, "font.mono"), base["font.mono"], "the mono face stays the skin's")
  assertEqual(Skin:Token(OWNER, "font.bodySize"), base["font.bodySize"], "sizes stay the skin's")
  assertEqual(F.rgba({ Skin:Color(OWNER, "win.bg") }), F.rgba(base["win.bg"]), "colors stay the skin's")
  assertEqual(base["font.body"], "Friz Quadrata TT", "ResolveSkin is override-free")
  assertEqual(Skin:ResolveSkin("ka0s")["bar.texture"], "Blizzard", "and keeps the skin's texture")
  assertTrue(Skin:__Tokens(OWNER) == Skin:__Tokens(OWNER), "the derived table is cached")
  local bar = S.BarStyle()
  assertEqual(bar.textureKey, "Ka0s Flat"); assertEqual(bar.texture, "Interface\\Ka0s\\Flat")
  assertEqual(bar.fontKey, "Ka0s Inter"); assertEqual(bar.font, "Fonts\\Inter.ttf")
end)

test("skin override: the override follows a skin switch, over the new skin's table", function()
  local _, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  Skin:SetOverride(OWNER, nil, "Ka0s Flat")
  local before = Skin:__Tokens(OWNER)
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  local after = Skin:__Tokens(OWNER)
  assertTrue(before ~= after, "a new base, a new derived table")
  assertEqual(after["bar.texture"], "Ka0s Flat", "the override holds")
  assertEqual(after["font.body"], Skin:ResolveSkin("obsidian")["font.body"], "the nil half is the new skin's")
end)

test("skin override: nil keeps a half, false and the empty string clear it, a repeat changes nothing", function()
  local _, Skin = F.env()
  register(Skin, OWNER)
  local fired = 0
  Skin:OnLooksChanged(OWNER, function() fired = fired + 1 end)
  assertTrue(Skin:SetOverride(OWNER, "Ka0s Inter", "Ka0s Flat"))
  assertEqual(fired, 1, "the listeners fired once")
  assertFalse(Skin:SetOverride(OWNER, "Ka0s Inter", "Ka0s Flat"), "the same pair is no change")
  assertFalse(Skin:SetOverride(OWNER, nil, nil), "nil keeps both")
  assertEqual(fired, 1, "no listener for no change")
  assertTrue(Skin:SetOverride(OWNER, false, nil))
  local font, texture = Skin:GetOverride(OWNER)
  assertNil(font, "false clears the font"); assertEqual(texture, "Ka0s Flat", "the nil half kept")
  assertTrue(Skin:SetOverride(OWNER, nil, ""))
  assertNil(select(2, Skin:GetOverride(OWNER)), "the empty string clears the texture")
  assertTrue(Skin:__Tokens(OWNER) == Skin:ResolveSkin("ka0s"), "cleared, the owner reads the skin's table again")
  assertEqual(fired, 3)
end)

test("skin override: a painted string takes the override's face on the repaint, and the skin's back on a clear",
function()
  -- red under: __Tokens answering the skin's table alone (the string keeps its stock font).
  local m, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local S = Skin:For(OWNER)
  local fs = m.CreateFrame("Frame"):CreateFontString()
  fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
  S.Font(fs)
  assertEqual((fs:GetFont()), "Fonts\\FRIZQT__.TTF", "Ka0s Default's face is not in this LSM: the stock face")
  Skin:SetOverride(OWNER, "Ka0s Inter", nil)
  assertEqual(fs:GetFontObject().font[1], "Fonts\\Inter.ttf", "the override's face, through the repaint")
  Skin:SetOverride(OWNER, false, nil)
  assertEqual((fs:GetFont()), "Fonts\\FRIZQT__.TTF", "cleared, the string's own face is back")
end)

test("skin override: Ignore fonts wins over a font override", function()
  local m, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local fs = m.CreateFrame("Frame"):CreateFontString()
  fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
  Skin:For(OWNER).Font(fs)
  Skin:SetOverride(OWNER, "Ka0s Inter", nil)
  Skin:SetIgnore(OWNER, nil, true)
  assertEqual((fs:GetFont()), "Fonts\\FRIZQT__.TTF", "ignored fonts keep the string's own face")
  assertEqual((Skin:GetOverride(OWNER)), "Ka0s Inter", "and the override is kept")
  Skin:SetIgnore(OWNER, nil, false)
  assertEqual(fs:GetFontObject().font[1], "Fonts\\Inter.ttf", "the override applies again")
end)

test("skin override: one owner's override never reaches another owner", function()
  local m, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  register(Skin, OTHER)
  local fs = m.CreateFrame("Frame"):CreateFontString()
  fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
  Skin:For(OTHER).Font(fs)
  local fired = 0
  Skin:OnLooksChanged(OTHER, function() fired = fired + 1 end)
  Skin:SetOverride(OWNER, "Ka0s Inter", "Ka0s Flat")
  assertEqual(Skin:Token(OTHER, "font.body"), "Friz Quadrata TT", "the other owner reads its skin's face")
  assertEqual(Skin:Token(OTHER, "bar.texture"), "Blizzard")
  assertNil((Skin:GetOverride(OTHER)))
  assertEqual((fs:GetFont()), "Fonts\\FRIZQT__.TTF", "its string was not repainted")
  assertEqual(fired, 0, "its listener did not fire")
end)

test("skin override: SetOverride while a reload is pending stores the pair and repaints nothing", function()
  local _, Skin = F.env()
  register(Skin, OWNER)
  local calls = 0
  Skin.prim.Probe = function(owner, f) calls = calls + 1; Skin:Track(owner, f, "Probe") end
  Skin.prim.Probe(OWNER, {})
  local fired = 0
  Skin:OnLooksChanged(OWNER, function() fired = fired + 1 end)
  Skin:__RequestReload(OWNER)
  assertTrue(Skin:SetOverride(OWNER, "Ka0s Inter", nil), "stored")
  assertEqual(calls, 1, "nothing repainted")
  assertEqual(fired, 0, "no listener fired")
  assertEqual((Skin:GetOverride(OWNER)), "Ka0s Inter")
end)

test("skin override: WriteChoice hands media to the setter as its fourth argument, normalized", function()
  local _, Skin = F.env()
  local store = register(Skin, OWNER)
  assertTrue(Skin:WriteChoice(OWNER, "ka0s", "glass", nil, { font = "Ka0s Inter", texture = "" }))
  assertEqual(store.media.font, "Ka0s Inter")
  assertEqual(store.media.texture, false, "the empty string is the skin's own: false")
  assertNil(store.ignore, "no ignore, no third argument")
  Skin:WriteChoice(OWNER, "ka0s", "glass", { fonts = true }, { texture = 7 })
  assertEqual(store.media.font, false, "a missing half is false")
  assertEqual(store.media.texture, false, "a non-string is false")
  assertEqual(store.ignore.fonts, true)
  Skin:WriteChoice(OWNER, "ka0s", "glass")
  assertNil(store.media, "no media, no fourth argument")
  assertNil((Skin:GetOverride(OWNER)), "WriteChoice never moves the applied overrides")
end)
