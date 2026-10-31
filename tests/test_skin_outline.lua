-- tests/test_skin_outline.lua -- LibKa0s-Skin-1.0's per-owner font outline (Skin minor 9, SkinDefs
-- minor 17, SkinPaint minor 13; LK-03 of Ka0sAddonsCommonTasks docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK,
-- the owner's ruling D-06): OUTLINE_MODES, GetOutline, SetOutline, the mode applied in `__Tokens`,
-- WriteChoice's `media.outline`, and P.font never outlining the mono role.
--
-- What it pins: every skin states OUTLINE for window and HUD text; "hud", the default since LK-F05 of
-- docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES, answers "" for `font.outline`, for an owner that never
-- set one too; "all" reads them as stated and leaves the owner's table the resolved one; "off" for both; the mode reaches a painted string's flags on the repaint SetOutline triggers, and
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

test("skin outline: the three modes, in the tab's order, and hud is the default", function()
  local _, Skin = F.env()
  assertEqual(table.concat(Skin.OUTLINE_MODES, "|"), "all|hud|off")
  assertEqual(Skin.OUTLINE_DEFAULT, "hud")
  assertEqual(Skin:GetOutline("Nobody"), "hud", "an unregistered owner reads the default")
  register(Skin, OWNER)
  assertEqual(Skin:GetOutline(OWNER), "hud", "an owner that never set one too")
  assertFalse(Skin:SetOutline("Nobody", "off"), "no owner, no change")
end)

test("skin outline: an owner that never set one draws HUD text only, and the skin's table is untouched", function()
  -- red under: withOutline reading `o.outline` alone (nil skips the mode, so the default outlines
  -- window text however OUTLINE_DEFAULT reads). LK-F05 of docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES.
  local m, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local S = Skin:For(OWNER)
  assertEqual(S.Token("font.outline"), "", "window text has no outline")
  assertEqual(S.Token("hud.outline"), "OUTLINE", "the HUD keeps it")
  assertEqual(S.FontFlags(Skin.FROM_SKIN), "OUTLINE", "a HUD element following the skin is outlined")
  assertEqual(S.FontFlags(Skin.FROM_SKIN, "window"), "", "window text following the skin is not")
  assertEqual(S.BarStyle().outline, "OUTLINE", "BarStyle reads it")
  local _, flags = bodyString(m, Skin, OWNER)
  assertEqual(flags(), "", "a painted string draws unoutlined")
  assertEqual(Skin:ResolveSkin("ka0s")["font.outline"], "OUTLINE", "ResolveSkin never moved")
  assertEqual(Skin:Token("Nobody", "font.outline"), "", "an unregistered owner wears what GetOutline says")
  assertEqual(Skin:Token("Nobody", "hud.outline"), "OUTLINE", "the HUD half too")
end)

test("skin outline: a stored choice stays, all included", function()
  -- red under: a stored "all" read as never set (D-10: the default is for an owner that never set one).
  local m, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local _, flags = bodyString(m, Skin, OWNER)
  assertTrue(Skin:SetOutline(OWNER, "all"), "all is a change from the default now")
  assertEqual(Skin:GetOutline(OWNER), "all")
  assertEqual(flags(), "OUTLINE", "and the repaint outlines window text")
  assertEqual(Skin:Token(OWNER, "font.outline"), "OUTLINE")
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
  assertTrue(Skin:SetOutline(OWNER, "all"), "a change from the default")
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

test("skin outline: an unknown mode is the default, a repeat changes nothing, listeners fire per change", function()
  local _, Skin = F.env()
  register(Skin, OWNER)
  local fired = 0
  Skin:OnLooksChanged(OWNER, function() fired = fired + 1 end)
  assertFalse(Skin:SetOutline(OWNER, "hud"), "the default again is no change")
  assertTrue(Skin:SetOutline(OWNER, "off"))
  assertFalse(Skin:SetOutline(OWNER, "off"), "a repeat is no change")
  assertEqual(fired, 1, "one listener call for one change")
  assertTrue(Skin:SetOutline(OWNER, "THICK"), "an unknown value")
  assertEqual(Skin:GetOutline(OWNER), "hud", "is the default")
  assertTrue(Skin:SetOutline(OWNER, "all"))
  assertTrue(Skin:SetOutline(OWNER, nil), "nil")
  assertEqual(Skin:GetOutline(OWNER), "hud", "is the default too")
  assertEqual(fired, 4)
end)

test("skin outline: a painted string takes the mode's flags on the repaint", function()
  -- red under: P.font reading flags from the skin's table without the owner's mode.
  local m, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local fs, flags = bodyString(m, Skin, OWNER)
  assertEqual(fs:GetFontObject().font[1], "Fonts\\Prototype.ttf", "the skin's face")
  assertEqual(flags(), "", "the default: unoutlined")
  Skin:SetOutline(OWNER, "all")
  assertEqual(flags(), "OUTLINE", "all: the repaint outlines it")
  Skin:SetOutline(OWNER, "hud")
  assertEqual(flags(), "", "hud: the repaint takes the outline off")
  Skin:SetOutline(OWNER, "all")
  assertEqual(flags(), "OUTLINE", "and puts it back")
end)

test("skin outline: the mono role is never outlined", function()
  -- red under: FONT_ROLE.mono without `outline = false` (the console's digits take OUTLINE under all).
  local m, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  Skin:SetOutline(OWNER, "all")
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
  assertNil(S.Token("hud.outline"), "the HUD outline is left alone under the default")
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
  assertEqual(Skin:Token(OTHER, "hud.outline"), "OUTLINE", "the other owner keeps its own mode")
  assertEqual(Skin:GetOutline(OTHER), "hud")
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
  assertTrue(Skin:SetOutline(OWNER, "off"), "stored")
  assertEqual(calls, 1, "nothing repainted")
  assertEqual(fired, 0, "no listener fired")
  assertEqual(Skin:GetOutline(OWNER), "off")
end)

test("skin outline: WriteChoice hands media.outline to the setter, normalized", function()
  local _, Skin = F.env()
  local store = register(Skin, OWNER)
  assertTrue(Skin:WriteChoice(OWNER, nil, nil, nil, { font = false, texture = false, outline = "off" }))
  assertEqual(store.media.outline, "off")
  assertEqual(store.media.font, false, "the halves as before")
  Skin:WriteChoice(OWNER, nil, nil, nil, { outline = "THICK" })
  assertNil(store.media.outline, "an unknown mode is left alone: nil")
  Skin:WriteChoice(OWNER, nil, nil, nil, { font = "Ka0s Nunito" })
  assertNil(store.media.outline, "no mode given: nil")
  assertEqual(Skin:GetOutline(OWNER), "hud", "WriteChoice never moves the applied mode")
end)

-- ── S.FontFlags (SkinPaintExtras minor 7, LK-04 of the same bundle, D-07) ─────────────────────

test("skin font flags: FontFlags is in the vocabulary and the facade", function()
  local _, Skin = F.env()
  local found = false
  for _, name in ipairs(Skin.VOCAB) do if name == "FontFlags" then found = true end end
  assertTrue(found, "VOCAB names it")
  assertEqual(type(Skin:For(OWNER).FontFlags), "function", "the facade carries it")
  assertTrue((Skin.MODULES.SkinPaintExtras or 0) >= 7, "SkinPaintExtras minor 7")
end)

test("skin font flags: a picked flag wins, From skin follows the Font outline", function()
  -- red under: FontFlags answering the skin's outline for a picked flag (the player's pick is lost).
  local _, Skin = F.env()
  register(Skin, OWNER)
  local S = Skin:For(OWNER)
  for _, v in ipairs({ "", "OUTLINE", "THICKOUTLINE", "MONOCHROME", "OUTLINE, MONOCHROME" }) do
    assertEqual(S.FontFlags(v), v, "picked: " .. v)
  end
  Skin:SetOutline(OWNER, "all")
  assertEqual(S.FontFlags(Skin.FROM_SKIN), "OUTLINE", "all: From skin is OUTLINE")
  assertEqual(S.FontFlags(nil), "OUTLINE", "nothing stored is From skin")
  assertEqual(S.FontFlags(Skin.FROM_SKIN, "window"), "OUTLINE", "window text too")
  Skin:SetOutline(OWNER, "hud")
  assertEqual(S.FontFlags(Skin.FROM_SKIN), "OUTLINE", "hud: a HUD element keeps it")
  assertEqual(S.FontFlags(Skin.FROM_SKIN, "window"), "", "and window text loses it")
  Skin:SetOutline(OWNER, "off")
  assertEqual(S.FontFlags(Skin.FROM_SKIN), "", "off: none")
  assertEqual(S.FontFlags("THICKOUTLINE"), "THICKOUTLINE", "a pick still wins under off")
end)

test("skin font flags: under Ignore fonts From skin answers OUTLINE for the HUD whatever the mode", function()
  local _, Skin = F.env()
  register(Skin, OWNER)
  local S = Skin:For(OWNER)
  Skin:SetOutline(OWNER, "off")
  Skin:SetIgnore(OWNER, nil, true)
  assertEqual(S.FontFlags(Skin.FROM_SKIN), "OUTLINE", "the Font outline is not read")
  assertEqual(S.FontFlags(""), "", "a pick still wins")
  assertEqual(Skin:For("Nobody").FontFlags(Skin.FROM_SKIN), "OUTLINE", "an unregistered owner reads Ka0s Default")
end)

test("skin font flags: under Ignore fonts From skin window text answers none, as its stock text", function()
  -- red under: FontFlags answering "OUTLINE" for where == "window" while the owner ignores fonts (P.font
  -- gives window strings their stock flags then, so an element resolving through FontFlags would not match).
  local _, Skin = F.env()
  register(Skin, OWNER)
  local S = Skin:For(OWNER)
  Skin:SetIgnore(OWNER, nil, true)
  assertEqual(S.FontFlags(Skin.FROM_SKIN, "window"), "", "window text: no skin outline")
  assertEqual(S.FontFlags(nil, "window"), "", "nothing stored is From skin")
  assertEqual(S.FontFlags("THICKOUTLINE", "window"), "THICKOUTLINE", "a pick still wins")
  Skin:SetOutline(OWNER, "hud")
  assertEqual(S.FontFlags(Skin.FROM_SKIN, "window"), "", "whatever the mode")
  assertEqual(S.FontFlags(Skin.FROM_SKIN), "OUTLINE", "and the HUD's answer stands")
end)

-- ── the review of LK-03 and LK-04: the eui source, the cache, owner tokens ───────────────────

test("skin outline: an owner on the eui source takes the mode over EllesmereUI's derived table", function()
  -- red under: withOutline applied to the ResolveSkin branch only (an eui owner ignores its mode).
  local _, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local eui = { ["font.body"] = "Ka0s Nunito", ["font.outline"] = "OUTLINE", ["hud.outline"] = "OUTLINE" }
  Skin.__euiTokens = function(owner) if owner == OWNER then return eui end end
  local ok, err = pcall(function()
    assertEqual(Skin:DrawsKey(OWNER), "eui", "the owner draws by eui")
    assertEqual(Skin:Token(OWNER, "font.outline"), "", "the default: no window outline")
    Skin:SetOutline(OWNER, "all")
    assertTrue(Skin:__Tokens(OWNER) == eui, "all: EllesmereUI's table itself")
    Skin:SetOutline(OWNER, "off")
    assertEqual(Skin:Token(OWNER, "font.outline"), "", "off: no window outline")
    assertEqual(Skin:Token(OWNER, "hud.outline"), "", "and no HUD outline")
    assertEqual(Skin:Token(OWNER, "font.body"), "Ka0s Nunito", "EllesmereUI's face stands")
    assertEqual(eui["font.outline"], "OUTLINE", "the derived table is never written")
  end)
  Skin.__euiTokens = nil
  assertTrue(ok, tostring(err))
end)

test("skin outline: hud survives a later font override and a skin change, and the new face applies", function()
  -- red under: withOutline's cache keyed on the owner alone (a new base table reads the old one).
  local m, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local fs, flags = bodyString(m, Skin, OWNER)
  Skin:SetOutline(OWNER, "hud")
  local before = Skin:__Tokens(OWNER)
  Skin:SetOverride(OWNER, "Ka0s Nunito", nil)
  assertTrue(Skin:__Tokens(OWNER) ~= before, "a new derived table for the new base")
  assertEqual(Skin:Token(OWNER, "font.outline"), "", "hud: window text still has no outline")
  assertEqual(Skin:Token(OWNER, "hud.outline"), "OUTLINE", "and the HUD keeps it")
  assertEqual(fs:GetFontObject().font[1], "Fonts\\Nunito.ttf", "the override's face, painted")
  assertEqual(flags(), "", "with the mode's flags")
  Skin:SetOverride(OWNER, false, nil)
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(Skin:Token(OWNER, "font.outline"), "", "after a skin change too")
  assertEqual(Skin:Token(OWNER, "font.body"), Skin:ResolveSkin("obsidian")["font.body"], "the new skin's face")
  assertEqual(flags(), "", "and the repaint keeps the mode's flags")
end)

test("skin outline: an owner token that follows font.outline follows the mode", function()
  -- red under: the owner tokens laid under withOutline (the token would read the skin's OUTLINE under hud).
  local _, Skin = F.env()
  Skin:RegisterOwner(OWNER, {
    set = function() end,
    tokens = { ["lh.rowOutline"] = { default = "OUTLINE", follow = "font.outline" } },
  })
  assertEqual(Skin:Token(OWNER, "lh.rowOutline"), "", "the default: the mode moved the follow token")
  Skin:SetOutline(OWNER, "all")
  assertEqual(Skin:Token(OWNER, "lh.rowOutline"), "OUTLINE", "all: Ka0s Default's default")
  Skin:SetOutline(OWNER, "hud")
  assertEqual(Skin:Token(OWNER, "lh.rowOutline"), "", "hud: the mode moved the follow token")
  Skin:SetOutline(OWNER, "all")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(Skin:Token(OWNER, "lh.rowOutline"), "OUTLINE", "a skin under all: the follow token")
  Skin:SetOutline(OWNER, "off")
  assertEqual(Skin:Token(OWNER, "lh.rowOutline"), "", "off: the follow token, dropped")
end)
