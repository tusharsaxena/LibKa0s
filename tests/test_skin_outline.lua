-- tests/test_skin_outline.lua -- LibKa0s-Skin-1.0's per-owner font outline (Skin minor 9, SkinDefs
-- minor 17, SkinPaint minor 13; LK-03 of Ka0sAddonsCommonTasks docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK,
-- the owner's ruling D-06): OUTLINE_MODES, GetOutline, SetOutline, the mode applied in `__Tokens`,
-- WriteChoice's `media.outline`, and P.font never outlining the mono role.
--
-- What it pins: every skin states OUTLINE for window and HUD text; "all" (the default) reads them as
-- stated and leaves the owner's table the resolved one; "hud" answers "" for `font.outline`; "off"
-- for both; the mode reaches a painted string's flags on the repaint SetOutline triggers, and
-- BarStyle; the mono role is never outlined; Ignore fonts wins; ResolveSkin is untouched; one
-- owner's mode never reaches another; a font override and the mode compose; and WriteChoice hands
-- the mode on normalized.
--
-- Every case runs on a fresh environment (tests/fixture_skin_paint.lua), so the owners one case
-- registers never reach another.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local F = dofile("tests/fixture_skin_paint.lua")

local OWNER, OTHER = "LootHistory", "BankLedger"
local LSM = { ["font:Ka0s Prototype"] = "Fonts\\Prototype.ttf", ["font:JetBrains Mono"] = "Fonts\\Mono.ttf",
              ["font:Ka0s Nunito"] = "Fonts\\Nunito.ttf" }

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

--- A font string painted for `owner` in the body role: answers it and a reader of its flags.
local function bodyString(m, Skin, owner)
  local fs = m.CreateFrame("Frame"):CreateFontString()
  fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
  Skin:For(owner).Font(fs)
  return fs, function()
    local obj = fs:GetFontObject()
    return obj and obj.font and obj.font[3]
  end
end

test("skin outline: the three modes, in the tab's order, and all is the default", function()
  local _, Skin = F.env()
  assertEqual(table.concat(Skin.OUTLINE_MODES, "|"), "all|hud|off")
  assertEqual(Skin.OUTLINE_DEFAULT, "all")
  assertEqual(Skin:GetOutline("Nobody"), "all", "an unregistered owner reads the default")
  register(Skin, OWNER)
  assertEqual(Skin:GetOutline(OWNER), "all", "an owner that never set one too")
  assertFalse(Skin:SetOutline("Nobody", "off"), "no owner, no change")
end)

test("skin outline: every skin states OUTLINE for window and HUD text", function()
  -- red under: Ka0s Default's font.outline left at "" (SkinDefs before LK-03): All text outlines nothing.
  local _, Skin = F.env()
  local n = 0
  for _, def in ipairs(Skin:Skins()) do
    n = n + 1
    local t = Skin:ResolveSkin(def.key)
    assertEqual(t["font.outline"], "OUTLINE", def.key .. ": font.outline")
    assertEqual(t["hud.outline"], "OUTLINE", def.key .. ": hud.outline")
  end
  assertTrue(n >= 8, "every registered skin was read")
end)

test("skin outline: all reads the skin, hud drops window text, off drops both", function()
  -- red under: __Tokens without its withOutline layer (every mode reads the skin as stated).
  local _, Skin = F.env()
  register(Skin, OWNER)
  local S = Skin:For(OWNER)
  local base = Skin:ResolveSkin("ka0s")
  assertTrue(Skin:__Tokens(OWNER) == base, "all: the owner reads the resolved table itself")
  assertEqual(S.Token("font.outline"), "OUTLINE"); assertEqual(S.Token("hud.outline"), "OUTLINE")
  assertTrue(Skin:SetOutline(OWNER, "hud"), "a change")
  assertEqual(Skin:GetOutline(OWNER), "hud")
  assertEqual(S.Token("font.outline"), "", "hud: window text has no outline")
  assertEqual(S.Token("hud.outline"), "OUTLINE", "and the HUD keeps it")
  assertTrue(Skin:__Tokens(OWNER) == Skin:__Tokens(OWNER), "the derived table is cached")
  assertEqual(S.Token("font.body"), base["font.body"], "nothing else moves")
  assertEqual(S.Resolve("hud.outline", Skin.FROM_SKIN), "OUTLINE", "Resolve follows the mode")
  Skin:SetOutline(OWNER, "off")
  assertEqual(S.Token("font.outline"), "", "off: no window outline")
  assertEqual(S.Token("hud.outline"), "", "and no HUD outline")
  assertEqual(S.Resolve("hud.outline", "THICKOUTLINE", true), "", "a HUD value following the skin follows the mode")
  assertEqual(S.Resolve("hud.outline", "THICKOUTLINE"), "THICKOUTLINE", "a stored pick stands")
  assertEqual(S.BarStyle().outline, "", "BarStyle reads it")
  Skin:SetOutline(OWNER, "all")
  assertTrue(Skin:__Tokens(OWNER) == base, "back to all: the resolved table again")
  assertEqual(Skin:ResolveSkin("ka0s")["font.outline"], "OUTLINE", "ResolveSkin never moved")
end)

test("skin outline: an unknown mode is all, a repeat changes nothing, listeners fire per change", function()
  local _, Skin = F.env()
  register(Skin, OWNER)
  local fired = 0
  Skin:OnLooksChanged(OWNER, function() fired = fired + 1 end)
  assertFalse(Skin:SetOutline(OWNER, "all"), "the default again is no change")
  assertTrue(Skin:SetOutline(OWNER, "off"))
  assertFalse(Skin:SetOutline(OWNER, "off"), "a repeat is no change")
  assertEqual(fired, 1, "one listener call for one change")
  assertTrue(Skin:SetOutline(OWNER, "THICK"), "an unknown value")
  assertEqual(Skin:GetOutline(OWNER), "all", "is all")
  assertTrue(Skin:SetOutline(OWNER, "hud"))
  assertTrue(Skin:SetOutline(OWNER, nil), "nil")
  assertEqual(Skin:GetOutline(OWNER), "all", "is all too")
  assertEqual(fired, 4)
end)

test("skin outline: a painted string takes the mode's flags on the repaint", function()
  -- red under: P.font reading flags from the skin's table without the owner's mode.
  local m, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local fs, flags = bodyString(m, Skin, OWNER)
  assertEqual(fs:GetFontObject().font[1], "Fonts\\Prototype.ttf", "the skin's face")
  assertEqual(flags(), "OUTLINE", "all: outlined")
  Skin:SetOutline(OWNER, "hud")
  assertEqual(flags(), "", "hud: the repaint takes the outline off")
  Skin:SetOutline(OWNER, "all")
  assertEqual(flags(), "OUTLINE", "and puts it back")
end)

test("skin outline: the mono role is never outlined", function()
  -- red under: FONT_ROLE.mono without `outline = false` (the console's digits take OUTLINE under all).
  local m, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local P = Skin.__P
  local fs = m.CreateFrame("Frame"):CreateFontString()
  fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
  local rec = P.track(OWNER, fs, "Probe")
  P.font(OWNER, rec, fs, "mono")
  local obj = fs:GetFontObject()
  assertEqual(obj.font[1], "Fonts\\Mono.ttf", "the mono face")
  assertEqual(obj.font[3], "", "and no outline, under all")
  P.font(OWNER, rec, fs, "body")
  assertEqual(fs:GetFontObject().font[3], "OUTLINE", "the body role on the same owner is outlined")
end)

test("skin outline: Ignore fonts wins whatever the mode", function()
  local m, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local S = Skin:For(OWNER)
  local fs = bodyString(m, Skin, OWNER)
  Skin:SetIgnore(OWNER, nil, true)
  assertEqual((fs:GetFont()), "Fonts\\FRIZQT__.TTF", "the string's own font is back")
  assertNil(S.Token("hud.outline"), "the HUD outline is left alone under all")
  Skin:SetOutline(OWNER, "off")
  assertNil(S.Token("hud.outline"), "and under off")
  assertEqual((fs:GetFont()), "Fonts\\FRIZQT__.TTF", "a mode change paints no font back")
  assertEqual(S.Resolve("hud.outline", "THICKOUTLINE", true), "THICKOUTLINE", "the stored value stands")
end)

test("skin outline: one owner's mode never reaches another, and a font override composes", function()
  local _, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  register(Skin, OTHER)
  Skin:SetOutline(OWNER, "off")
  assertEqual(Skin:Token(OTHER, "font.outline"), "OUTLINE", "the other owner reads the skin")
  assertEqual(Skin:GetOutline(OTHER), "all")
  Skin:SetOverride(OWNER, "Ka0s Nunito", nil)
  assertEqual(Skin:Token(OWNER, "font.body"), "Ka0s Nunito", "the override")
  assertEqual(Skin:Token(OWNER, "font.outline"), "", "and the mode, together")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(Skin:Token(OWNER, "hud.outline"), "", "the mode follows a skin switch")
end)

test("skin outline: SetOutline while a reload is pending stores the mode and repaints nothing", function()
  local _, Skin = F.env()
  register(Skin, OWNER)
  local calls = 0
  Skin.prim.Probe = function(owner, f) calls = calls + 1; Skin:Track(owner, f, "Probe") end
  Skin.prim.Probe(OWNER, {})
  local fired = 0
  Skin:OnLooksChanged(OWNER, function() fired = fired + 1 end)
  Skin:__RequestReload(OWNER)
  assertTrue(Skin:SetOutline(OWNER, "hud"), "stored")
  assertEqual(calls, 1, "nothing repainted")
  assertEqual(fired, 0, "no listener fired")
  assertEqual(Skin:GetOutline(OWNER), "hud")
end)

test("skin outline: WriteChoice hands media.outline to the setter, normalized", function()
  local _, Skin = F.env()
  local store = register(Skin, OWNER)
  assertTrue(Skin:WriteChoice(OWNER, nil, nil, nil, { font = false, texture = false, outline = "hud" }))
  assertEqual(store.media.outline, "hud")
  assertEqual(store.media.font, false, "the halves as before")
  Skin:WriteChoice(OWNER, nil, nil, nil, { outline = "THICK" })
  assertNil(store.media.outline, "an unknown mode is left alone: nil")
  Skin:WriteChoice(OWNER, nil, nil, nil, { font = "Ka0s Nunito" })
  assertNil(store.media.outline, "no mode given: nil")
  assertEqual(Skin:GetOutline(OWNER), "all", "WriteChoice never moves the applied mode")
end)
