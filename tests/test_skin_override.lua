-- tests/test_skin_override.lua — LibKa0s-Skin-1.0's per-owner font and texture overrides (Skin
-- minor 6, LibKa0s#63; SO-01 of Ka0sAddonsCommonTasks docs/2026-10-28-SKIN_OVERRIDES_AND_PICKER):
-- GetOverride, SetOverride, the overrides laid over the owner's tokens in `__Tokens`, and
-- WriteChoice's fourth setter argument `media`; and S.BarTexture (SkinPaintExtras minor 4, SO-02), the
-- owner's bar texture on a Texture or a StatusBar, which a texture override reaches live.
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
-- Ka0s Default's bar texture (SkinDefs minor 14), where Media.RegisterLSM would put it for OWNER.
local KA0S_BAR = "Interface\\AddOns\\LootHistory\\libs\\LibKa0s\\media\\textures\\ka0s-default"
local LSM = { ["font:Ka0s Expressway"] = "Fonts\\Expressway.ttf", ["font:Ka0s Nunito"] = "Fonts\\Nunito.ttf",
              ["statusbar:Blizzard"] = "Interface\\TargetingFrame\\UI-StatusBar",
              ["statusbar:Ka0s Default"] = KA0S_BAR,
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
  assertFalse(Skin:SetOverride("Nobody", "Ka0s Expressway", nil), "no owner, no change")
  assertNil((Skin:GetOverride("Nobody")))
end)

test("skin override: a font and a texture reach every token read, and nothing else moves", function()
  local _, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local S = Skin:For(OWNER)
  local base = Skin:ResolveSkin("ka0s")
  assertTrue(Skin:__Tokens(OWNER) == base, "with no override the owner reads the resolved table itself")
  assertTrue(Skin:SetOverride(OWNER, "Ka0s Expressway", "Ka0s Flat"), "a change")
  local font, texture = Skin:GetOverride(OWNER)
  assertEqual(font, "Ka0s Expressway"); assertEqual(texture, "Ka0s Flat")
  for _, name in ipairs({ "font.body", "font.title", "hud.font" }) do
    assertEqual(Skin:Token(OWNER, name), "Ka0s Expressway", name .. " is the override")
  end
  assertEqual(S.Token("bar.texture"), "Ka0s Flat", "the facade reads the texture override")
  assertEqual(Skin:Token(OWNER, "font.mono"), base["font.mono"], "the mono face stays the skin's")
  assertEqual(Skin:Token(OWNER, "font.bodySize"), base["font.bodySize"], "sizes stay the skin's")
  assertEqual(F.rgba({ Skin:Color(OWNER, "win.bg") }), F.rgba(base["win.bg"]), "colors stay the skin's")
  assertEqual(base["font.body"], "Ka0s Prototype", "ResolveSkin is override-free")
  assertEqual(Skin:ResolveSkin("ka0s")["bar.texture"], "Ka0s Default", "and keeps the skin's texture")
  assertTrue(Skin:__Tokens(OWNER) == Skin:__Tokens(OWNER), "the derived table is cached")
  local bar = S.BarStyle()
  assertEqual(bar.textureKey, "Ka0s Flat"); assertEqual(bar.texture, "Interface\\Ka0s\\Flat")
  assertEqual(bar.fontKey, "Ka0s Expressway"); assertEqual(bar.font, "Fonts\\Expressway.ttf")
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
  assertTrue(Skin:SetOverride(OWNER, "Ka0s Expressway", "Ka0s Flat"))
  assertEqual(fired, 1, "the listeners fired once")
  assertFalse(Skin:SetOverride(OWNER, "Ka0s Expressway", "Ka0s Flat"), "the same pair is no change")
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
  Skin:SetOverride(OWNER, "Ka0s Expressway", nil)
  assertEqual(fs:GetFontObject().font[1], "Fonts\\Expressway.ttf", "the override's face, through the repaint")
  Skin:SetOverride(OWNER, false, nil)
  assertEqual((fs:GetFont()), "Fonts\\FRIZQT__.TTF", "cleared, the string's own face is back")
end)

test("skin override: Ignore fonts wins over a font override", function()
  local m, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local fs = m.CreateFrame("Frame"):CreateFontString()
  fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
  Skin:For(OWNER).Font(fs)
  Skin:SetOverride(OWNER, "Ka0s Expressway", nil)
  Skin:SetIgnore(OWNER, nil, true)
  assertEqual((fs:GetFont()), "Fonts\\FRIZQT__.TTF", "ignored fonts keep the string's own face")
  assertEqual((Skin:GetOverride(OWNER)), "Ka0s Expressway", "and the override is kept")
  Skin:SetIgnore(OWNER, nil, false)
  assertEqual(fs:GetFontObject().font[1], "Fonts\\Expressway.ttf", "the override applies again")
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
  Skin:SetOverride(OWNER, "Ka0s Expressway", "Ka0s Flat")
  assertEqual(Skin:Token(OTHER, "font.body"), "Ka0s Prototype", "the other owner reads its skin's face")
  assertEqual(Skin:Token(OTHER, "bar.texture"), "Ka0s Default")
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
  assertTrue(Skin:SetOverride(OWNER, "Ka0s Expressway", nil), "stored")
  assertEqual(calls, 1, "nothing repainted")
  assertEqual(fired, 0, "no listener fired")
  assertEqual((Skin:GetOverride(OWNER)), "Ka0s Expressway")
end)

test("skin override: WriteChoice hands media to the setter as its fourth argument, normalized", function()
  local _, Skin = F.env()
  local store = register(Skin, OWNER)
  assertTrue(Skin:WriteChoice(OWNER, "ka0s", "glass", nil, { font = "Ka0s Expressway", texture = "" }))
  assertEqual(store.media.font, "Ka0s Expressway")
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

test("skin override: FROM_SKIN stored as an override means the skin's own", function()
  -- red under: mediaKey storing "@skin" (Token answered "@skin", a face that resolves to nothing).
  local _, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  assertFalse(Skin:SetOverride(OWNER, Skin.FROM_SKIN, Skin.FROM_SKIN), "no override, so no change")
  assertNil((Skin:GetOverride(OWNER)))
  assertEqual(Skin:Token(OWNER, "font.body"), "Ka0s Prototype")
  Skin:SetOverride(OWNER, "Ka0s Expressway", "Ka0s Flat")
  assertTrue(Skin:SetOverride(OWNER, Skin.FROM_SKIN, nil), "FROM_SKIN clears a set override")
  assertNil((Skin:GetOverride(OWNER)))
  local store = register(Skin, OWNER)
  Skin:WriteChoice(OWNER, "ka0s", "ka0s", nil, { font = Skin.FROM_SKIN })
  assertEqual(store.media.font, false, "WriteChoice hands it on as the skin's own")
end)

--- An LSM fake that fetches from a table the case can grow, and fires LibSharedMedia_Registered.
local function lateLSM(m, media)
  local L = m.LibStub("LibSharedMedia-3.0")
  L.subs = {}
  L.Fetch = function(_, kind, key) return media[kind .. ":" .. tostring(key)] end
  L.RegisterCallback = function(target, event, fn)
    L.subs[event] = L.subs[event] or {}
    L.subs[event][target] = fn
  end
  L.Register = function(_, kind, key, path)
    media[kind .. ":" .. key] = path
    for _, fn in pairs(L.subs.LibSharedMedia_Registered or {}) do fn("LibSharedMedia_Registered", kind, key) end
  end
  return L
end

test("skin override: a key LibSharedMedia lacks leaves the skin's own, until a pack registers it", function()
  -- red under: withOverrides laying any string over the tokens (the stock font and the flat bar).
  local media = { ["font:Ka0s Prototype"] = "Fonts\\Prototype-Regular.ttf",
                  ["statusbar:Ka0s Default"] = KA0S_BAR }
  local m, Skin = F.env({ lsm = {} })
  local L = lateLSM(m, media)
  register(Skin, OWNER)
  local S = Skin:For(OWNER)
  local fs = m.CreateFrame("Frame"):CreateFontString()
  fs:SetFont("Fonts\\ARIALN.ttf", 12, "")
  S.Font(fs)
  local tex = m.CreateFrame("Frame"):CreateTexture()
  S.BarTexture(tex, 1, 0, 0)
  local fired = 0
  Skin:OnLooksChanged(OWNER, function() fired = fired + 1 end)
  assertTrue(Skin:SetOverride(OWNER, "Gone Font", "Gone Bar"), "stored")
  local font, texture = Skin:GetOverride(OWNER)
  assertEqual(font, "Gone Font"); assertEqual(texture, "Gone Bar", "GetOverride answers the stored keys")
  assertEqual(Skin:Token(OWNER, "font.body"), "Ka0s Prototype", "the skin's own face stands")
  assertEqual(Skin:Token(OWNER, "bar.texture"), "Ka0s Default", "and its own texture")
  assertEqual(fs:GetFontObject().font[1], "Fonts\\Prototype-Regular.ttf", "the string wears the skin's face, not stock")
  assertEqual(m.__paint(tex).texture, KA0S_BAR, "the bar is not flat")
  fired = 0
  L:Register("statusbar", "Unrelated", "Interface\\X")
  assertEqual(fired, 0, "a key no override names repaints nothing")
  L:Register("font", "Gone Font", "Fonts\\Gone.ttf")
  assertEqual(fired, 1, "the owner naming it repainted and notified")
  assertEqual(Skin:Token(OWNER, "font.body"), "Gone Font")
  assertEqual(fs:GetFontObject().font[1], "Fonts\\Gone.ttf", "the late face, live")
  L:Register("statusbar", "Gone Bar", "Interface\\Gone")
  assertEqual(m.__paint(tex).texture, "Interface\\Gone", "the late texture, live")
  assertEqual(F.rgba(m.__paint(tex).vertex), "1,0,0,1", "the same tint")
end)

test("skin override: __BaseTokens is the owner's table without its overrides, EllesmereUI's when it paints",
function()
  local _, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  Skin:SetOverride(OWNER, "Ka0s Expressway", "Ka0s Flat")
  assertTrue(Skin:__BaseTokens(OWNER) == Skin:ResolveSkin("ka0s"), "the skin's own table")
  local eui = { ["font.body"] = "Expressway", ["bar.texture"] = "EUI Bar" }
  Skin.__euiTokens = function(owner) if owner == OWNER then return eui end end
  assertTrue(Skin:__BaseTokens(OWNER) == eui, "the EllesmereUI table while it answers")
  assertEqual(Skin:Token(OWNER, "font.body"), "Ka0s Expressway", "the overrides still lie over it")
  Skin.__euiTokens = nil
end)

-- ── S.BarTexture (SkinPaintExtras minor 4) ───────────────────────────────────────────────────

test("skin override: BarTexture puts the owner's bar texture on a Texture, tinted", function()
  local m, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local S = Skin:For(OWNER)
  local tex = m.CreateFrame("Frame"):CreateTexture()
  S.BarTexture(tex, 0.2, 0.4, 0.6, 0.8)
  local s = m.__paint(tex)
  assertEqual(s.texture, KA0S_BAR, "Ka0s Default's own bar, through LSM")
  assertEqual(F.rgba(s.vertex), "0.200,0.400,0.600,0.800", "tinted")
  assertTrue(Skin.painted[tex] ~= nil, "recorded")
end)

test("skin override: BarTexture follows a texture override and its clearing, live", function()
  -- red under: BarTexture left unrecorded (the override reaches no bar until the host paints again).
  local m, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local tex = m.CreateFrame("Frame"):CreateTexture()
  Skin:For(OWNER).BarTexture(tex, 1, 0, 0)
  Skin:SetOverride(OWNER, nil, "Ka0s Flat")
  assertEqual(m.__paint(tex).texture, "Interface\\Ka0s\\Flat", "the override, on the repaint")
  assertEqual(F.rgba(m.__paint(tex).vertex), "1,0,0,1", "the same tint")
  Skin:SetOverride(OWNER, nil, false)
  assertEqual(m.__paint(tex).texture, KA0S_BAR, "the skin's own again")
end)

test("skin override: with no texture resolved BarTexture is the flat look", function()
  local m, Skin = F.env()   -- no LibSharedMedia: "Ka0s Default" resolves to nothing
  register(Skin, OWNER)
  local tex = m.CreateFrame("Frame"):CreateTexture()
  tex:SetVertexColor(0.5, 0.5, 0.5)
  Skin:For(OWNER).BarTexture(tex, 0.1, 0.2, 0.3, 1)
  local s = m.__paint(tex)
  assertEqual(F.rgba(s.color), "0.100,0.200,0.300,1", "SetColorTexture with the tint")
  assertNil(s.texture, "no file")
  assertEqual(F.rgba(s.vertex), "1,1,1,1", "and a white vertex color, so the tint is not multiplied")
end)

test("skin override: BarTexture on a StatusBar sets its bar texture and color", function()
  local m, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local S = Skin:For(OWNER)
  local bar = m.CreateFrame("StatusBar", nil, m.UIParent)
  S.BarTexture(bar, 0, 1, 0, 0.5)
  local s = m.__paint(bar)
  assertEqual(s.statusBarTexture, KA0S_BAR)
  assertEqual(F.rgba(s.statusBarColor), "0,1,0,0.500")
  Skin:SetOverride(OWNER, nil, "Ka0s Flat")
  assertEqual(m.__paint(bar).statusBarTexture, "Interface\\Ka0s\\Flat", "repainted with the override")
  local m2, Skin2 = F.env()
  register(Skin2, OWNER)
  local flat = m2.CreateFrame("StatusBar", nil, m2.UIParent)
  Skin2:For(OWNER).BarTexture(flat, 1, 1, 0)
  assertEqual(m2.__paint(flat).statusBarTexture, "Interface\\Buttons\\WHITE8X8", "flat with nothing resolved")
end)

test("skin override: a nil color keeps the target's current color across repaints", function()
  local m, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local bar = m.CreateFrame("StatusBar", nil, m.UIParent)
  bar:SetStatusBarColor(0.3, 0.6, 0.9)
  local tex = m.CreateFrame("Frame"):CreateTexture()
  tex:SetVertexColor(0.9, 0.1, 0.1)
  local S = Skin:For(OWNER)
  S.BarTexture(bar); S.BarTexture(tex)
  assertEqual(F.rgba({ bar:GetStatusBarColor() }), "0.300,0.600,0.900,1", "the bar keeps its color")
  assertEqual(F.rgba({ tex:GetVertexColor() }), "0.900,0.100,0.100,1", "the texture keeps its tint")
  Skin:SetOverride(OWNER, nil, "Ka0s Flat")
  assertEqual(F.rgba({ bar:GetStatusBarColor() }), "0.300,0.600,0.900,1", "and on the repaint")
  assertEqual(m.__paint(tex).texture, "Interface\\Ka0s\\Flat")
end)

test("skin override: a repaint keeps a host's recolor made between paints, nil color or not", function()
  -- red under: the first-paint snapshot (0.9,0.1,0.1 and 1,0,0 came back on the repaint).
  local m, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local S = Skin:For(OWNER)
  local tex = m.CreateFrame("Frame"):CreateTexture()
  tex:SetVertexColor(0.9, 0.1, 0.1)
  S.BarTexture(tex)
  tex:SetVertexColor(0, 1, 0)
  local named = m.CreateFrame("Frame"):CreateTexture()
  S.BarTexture(named, 1, 0, 0)
  named:SetVertexColor(0, 0, 1)
  local bar = m.CreateFrame("StatusBar", nil, m.UIParent)
  S.BarTexture(bar, 1, 1, 0)
  bar:SetStatusBarColor(0, 1, 1)
  Skin:SetOverride(OWNER, nil, "Ka0s Flat")
  assertEqual(m.__paint(tex).texture, "Interface\\Ka0s\\Flat", "repainted")
  assertEqual(F.rgba({ tex:GetVertexColor() }), "0,1,0,1", "a nil color: the host's recolor holds")
  assertEqual(F.rgba({ named:GetVertexColor() }), "0,0,1,1", "a named color: the host's recolor holds")
  assertEqual(F.rgba({ bar:GetStatusBarColor() }), "0,1,1,1", "a StatusBar's recolor holds")
  S.BarTexture(named, 1, 0.5, 0)
  assertEqual(F.rgba({ named:GetVertexColor() }), "1,0.500,0,1", "a host's call with a color paints it")
end)

test("skin override: a flat bar keeps its tint through a texture and back", function()
  local m, Skin = F.env({ lsm = { ["statusbar:Ka0s Flat"] = "Interface\\Ka0s\\Flat" } })
  register(Skin, OWNER)   -- Ka0s Default's "Ka0s Default" bar is not in this LSM: flat
  local S = Skin:For(OWNER)
  local tex = m.CreateFrame("Frame"):CreateTexture()
  S.BarTexture(tex, 0.2, 0.4, 0.6, 1)
  assertEqual(F.rgba(m.__paint(tex).color), "0.200,0.400,0.600,1", "flat, the tint in the color texture")
  Skin:SetOverride(OWNER, nil, "Ka0s Flat")
  assertEqual(m.__paint(tex).texture, "Interface\\Ka0s\\Flat")
  assertEqual(F.rgba({ tex:GetVertexColor() }), "0.200,0.400,0.600,1", "the remembered tint, not the white")
  Skin:SetOverride(OWNER, nil, false)
  assertEqual(F.rgba(m.__paint(tex).color), "0.200,0.400,0.600,1", "flat again, the same tint")
  tex:SetVertexColor(0, 1, 0)
  Skin:SetOverride(OWNER, nil, "Ka0s Flat")
  assertEqual(F.rgba({ tex:GetVertexColor() }), "0,1,0,1", "a host's recolor of a flat bar holds")
end)

test("skin override: a texture Untrack handed back starts from its own color", function()
  -- red under: the tint kept per target across Untrack (the previous user's 1,0,0 came back).
  local m, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local S = Skin:For(OWNER)
  local tex = m.CreateFrame("Frame"):CreateTexture()
  S.BarTexture(tex, 1, 0, 0)
  Skin:Untrack(tex)
  tex:SetVertexColor(0, 1, 0)
  S.BarTexture(tex)
  assertEqual(F.rgba({ tex:GetVertexColor() }), "0,1,0,1", "the pooled texture's current color")
end)

test("skin override: BarTexture leaves a frame that is neither a Texture nor a StatusBar alone", function()
  local m, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local f = m.CreateFrame("Frame", nil, m.UIParent)
  Skin:For(OWNER).BarTexture(f, 1, 0, 0)
  assertNil(Skin.painted[f], "nothing recorded")
  Skin:For(OWNER).BarTexture(nil, 1, 0, 0)
end)

-- ── Ignore fonts reaches the HUD (Skin minor 8, SkinPaintExtras minor 6; LK-01 of
-- Ka0sAddonsCommonTasks docs/2026-10-30-SKIN_LIBRARY_FOLLOWUPS, ruling R-1, decision D-09) ────────

test("skin ignore fonts: the stored HUD face and outline win over a set companion", function()
  local _, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local S = Skin:For(OWNER)
  assertEqual(S.Resolve("hud.font", "Ka0s Expressway", true), "Ka0s Prototype", "fonts drawn: the skin's")
  Skin:SetIgnore(OWNER, nil, true)
  assertEqual(S.Resolve("hud.font", "Ka0s Expressway", true), "Ka0s Expressway", "ignored: the stored face")
  assertEqual(S.Resolve("hud.outline", "THICKOUTLINE", true), "THICKOUTLINE", "and the stored outline")
  assertEqual(Skin:Resolve(OWNER, "hud.font", "Ka0s Expressway", true), "Ka0s Expressway", "lib-level too")
  assertNil(S.Resolve("hud.font", Skin.FROM_SKIN), "a stored sentinel names no face of its own")
  assertNil(S.Resolve("hud.outline", Skin.FROM_SKIN), "nor an outline")
  assertNil(S.Resolve("hud.font", nil, true), "nothing stored: nil, the host's own stands")
end)

test("skin ignore fonts: Token leaves the HUD face and outline alone, and nothing else", function()
  local _, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local S = Skin:For(OWNER)
  Skin:SetIgnore(OWNER, nil, true)
  assertNil(S.Token("hud.font"), "the HUD face is left alone")
  assertNil(S.Token("hud.outline"), "and the outline")
  assertNil(Skin:Token(OWNER, "hud.font"), "lib-level too")
  assertEqual(S.Token("font.body"), "Ka0s Prototype", "font.body is P.font's, unchanged")
  assertEqual(S.Token("hud.fontSize"), 12, "the HUD size is out of R-1's scope")
  assertEqual(S.Resolve("bar.texture", "Smooth", true), "Ka0s Default", "a texture still follows the skin")
  assertEqual(S.Resolve("hud.fontSize", 9, true), 12, "and so does the size")
end)

test("skin ignore fonts: the stored face wins over a font override, and switching back is live", function()
  local _, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local S = Skin:For(OWNER)
  Skin:SetOverride(OWNER, "Ka0s Nunito", nil)
  Skin:SetIgnore(OWNER, nil, true)
  assertEqual(S.Resolve("hud.font", "Ka0s Expressway", true), "Ka0s Expressway", "the stored face, not the override")
  Skin:SetIgnore(OWNER, nil, false)
  assertEqual(S.Resolve("hud.font", "Ka0s Expressway", true), "Ka0s Nunito", "off again: the override")
  assertEqual(S.Token("hud.outline"), "OUTLINE", "and the skin's outline")
  Skin:SetOverride(OWNER, false, nil)
  assertEqual(S.Token("hud.font"), "Ka0s Prototype", "and the skin's face, with no re-register")
end)

test("skin ignore fonts: BarStyle's font fields are nil, every other field unchanged", function()
  local _, Skin = F.env({ lsm = LSM })
  register(Skin, OWNER)
  local S = Skin:For(OWNER)
  local before = S.BarStyle()
  Skin:SetIgnore(OWNER, nil, true)
  local bar = S.BarStyle()
  assertNil(bar.font); assertNil(bar.fontKey); assertNil(bar.outline)
  assertEqual(bar.textureKey, before.textureKey, "the texture is unchanged")
  assertEqual(bar.texture, before.texture)
  assertEqual(bar.fontSize, before.fontSize, "and the size")
  Skin:SetIgnore(OWNER, nil, false)
  assertEqual(S.BarStyle().fontKey, "Ka0s Prototype", "off again: the skin's face")
end)

test("skin ignore fonts: an unregistered owner reads Ka0s Default's HUD face as before", function()
  local _, Skin = F.env({ lsm = LSM })
  local S = Skin:For("Nobody")
  assertFalse(Skin:__FontsIgnored("Nobody"))
  assertEqual(S.Resolve("hud.font", "Ka0s Expressway", true), "Ka0s Prototype")
  assertEqual(S.Token("hud.outline"), "OUTLINE")
  assertEqual(S.BarStyle().fontKey, "Ka0s Prototype")
end)
