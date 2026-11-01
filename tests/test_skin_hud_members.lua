-- tests/test_skin_hud_members.lua -- the three members the AbsorbTracker pilot of
-- Ka0sAddonsCommonTasks docs/2026-11-01-FULL_SKINNING showed the hosts were each about to write:
-- S.BarGloss, S.HudFont (SkinPaintExtras minor 14) and Skin.FollowOnce (Skin minor 14).
--
-- What it pins: one gloss look for every host, drawn on the fill so it never shines past it, shown
-- only under `bar.gloss` and following a skin change with no host call; a HUD string's face, flags
-- and shadow on one named font object, with S.HudShadow's three answers and a client with no
-- CreateFont; and the per-profile record gate of the step onto the skin.
--
-- Every case runs on a fresh environment (tests/fixture_skin_paint.lua).

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local F = dofile("tests/fixture_skin_paint.lua")

local OWNER = "AuraMaster"
local FACE = "Fonts\\Host.ttf"

local function statusBar(m)
  local bar = m.CreateFrame("StatusBar")
  bar:SetStatusBarTexture("Interface\\Bar")
  return bar
end

local function regionsOf(bar)
  local out = {}
  for _, r in ipairs({ bar:GetRegions() }) do
    if r ~= bar:GetStatusBarTexture() then out[#out + 1] = r end
  end
  return out
end

local function fontString(m) return m.CreateFrame("Frame"):CreateFontString() end

-- ── S.BarGloss ───────────────────────────────────────────────────────────────────────────────

test("skin hud members: BarGloss and HudFont are in the facade", function()
  local _, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  assertEqual(type(S.BarGloss), "function")
  assertEqual(type(S.HudFont), "function")
end)

test("skin hud members: BarGloss draws one look over the fill's top half, on the fill", function()
  -- red under: a gloss anchored to the bar, which shines past a part-full fill, or a host's look.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "glass")
  local bar = statusBar(m)
  S.BarGloss(bar)
  local fill = bar:GetStatusBarTexture()
  local gloss = F.region(Skin, bar, "gloss")
  assertTrue(gloss ~= nil, "the skin's bar.gloss draws it")
  local p = m.__paint(gloss)
  assertTrue(p.shown, "shown")
  assertEqual(p.layer, "OVERLAY")
  assertEqual(p.sublevel, -8, "over the fill, under a host's own OVERLAY text")
  assertEqual(gloss.__owner, bar, "a region of the status bar")
  assertEqual(p.gradient.orientation, "VERTICAL")
  assertEqual(F.rgba({ p.gradient.min.r, p.gradient.min.g, p.gradient.min.b, p.gradient.min.a }),
    F.rgba({ 1, 1, 1, 0 }), "clear at the middle")
  assertEqual(F.rgba({ p.gradient.max.r, p.gradient.max.g, p.gradient.max.b, p.gradient.max.a }),
    F.rgba({ 1, 1, 1, 0.25 }), "0.25 white at the top")
  assertEqual(gloss:GetNumPoints(), 2)
  local a, relA, b = gloss:GetPoint(1)
  assertEqual(a, "TOPLEFT")
  assertTrue(relA == fill, "anchored to the fill")
  assertEqual(b, "TOPLEFT")
  local c, relC, d = gloss:GetPoint(2)
  assertEqual(c, "BOTTOMRIGHT")
  assertTrue(relC == fill, "anchored to the fill")
  assertEqual(d, "RIGHT", "the top half")
end)

test("skin hud members: BarGloss builds nothing where the skin sets no gloss", function()
  -- red under: Ka0s Default growing a layer, which is a look change on every bar.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local bar = statusBar(m)
  S.BarGloss(bar)
  assertNil(F.region(Skin, bar, "gloss"), "no region under Ka0s Default")
  assertEqual(#regionsOf(bar), 0)
end)

test("skin hud members: BarGloss follows a skin change with no host call, and reuses its layer", function()
  -- red under: the primitive not recorded, a second layer on a repaint, or a stale shown state.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local bar = statusBar(m)
  S.BarGloss(bar)
  Skin:SetChoice(OWNER, "ka0s", "glass")
  local gloss = F.region(Skin, bar, "gloss")
  assertTrue(gloss ~= nil and gloss:IsShown(), "on with the skin")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertFalse(gloss:IsShown(), "off with the skin")
  Skin:SetChoice(OWNER, "ka0s", "glass")
  assertTrue(gloss:IsShown(), "on again")
  S.BarGloss(bar)
  assertEqual(#regionsOf(bar), 1, "one layer, however often it paints")
end)

test("skin hud members: a BarGloss repaint moves to the fill the bar wears now", function()
  -- red under: anchors set once, left on a fill a host replaced.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "glass")
  local bar = statusBar(m)
  S.BarGloss(bar)
  local swapped = bar:CreateTexture()
  bar:SetStatusBarTexture(swapped)
  S.BarGloss(bar)
  local gloss = F.region(Skin, bar, "gloss")
  assertEqual(gloss:GetNumPoints(), 2, "the old anchors cleared")
  local _, rel = gloss:GetPoint(1)
  assertTrue(rel == swapped)
end)

test("skin hud members: BarGloss leaves anything but a status bar alone, and keeps the bar's color", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "glass")
  local plain = m.CreateFrame("Frame")
  S.BarGloss(plain)
  S.BarGloss(nil)
  assertNil(Skin.painted[plain], "a plain frame is no target")
  local bar = statusBar(m)
  bar:SetStatusBarColor(0.1, 0.2, 0.3, 1)
  S.BarGloss(bar)
  assertEqual(F.rgba({ bar:GetStatusBarColor() }), F.rgba({ 0.1, 0.2, 0.3, 1 }))
end)

test("skin hud members: a bar given back hides the gloss", function()
  -- red under: the region not marked as ours, so another owner's skin keeps this one's shine.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "glass")
  local other = F.owner(Skin, "Other")
  local bar = statusBar(m)
  S.BarGloss(bar)
  local gloss = F.region(Skin, bar, "gloss")
  other.BarGloss(bar)
  assertFalse(gloss:IsShown())
end)

-- ── S.HudFont ────────────────────────────────────────────────────────────────────────────────

test("skin hud members: HudFont puts face, size, flags and a skin's shadow on a named font object", function()
  -- red under: a runtime SetShadow* on the string, which a 12.0.7 client no longer renders.
  local m, Skin = F.env()
  local S = F.owner(Skin, "My Addon", "contrast")
  local fs = fontString(m)
  local obj = S.HudFont(fs, { face = FACE, size = 14, flags = "OUTLINE" })
  assertTrue(obj ~= nil, "answers the object")
  assertTrue(type(obj.name) == "string" and obj.name:find("My Addon", 1, true) ~= nil, "a named one")
  assertTrue(m.__paint(fs).fontObject == obj, "the string wears it")
  assertEqual(obj.font[1], FACE)
  assertEqual(obj.font[2], 14)
  assertEqual(obj.font[3], "OUTLINE")
  local x, y, r, g, b, a = S.HudShadow()
  assertEqual(obj.shadow[1], x)
  assertEqual(obj.shadow[2], y)
  assertEqual(F.rgba(obj.shadowColor), F.rgba({ r, g, b, a }))
  assertNil(m.__paint(fs).shadowOffset, "nothing on the string")
end)

test("skin hud members: HudFont gives a string one object, and each string its own", function()
  -- red under: a second object per call, which the client never frees, or a shared one, where
  -- the last caller's face lands on every string.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local one, two = fontString(m), fontString(m)
  local a = S.HudFont(one, { face = FACE, size = 12 })
  local b = S.HudFont(two, { face = "Fonts\\B.ttf", size = 20 })
  assertTrue(a ~= b, "one each")
  assertTrue(a.name ~= b.name, "each its own name")
  assertTrue(S.HudFont(one, { face = FACE, size = 13 }) == a, "the same one again")
  assertEqual(a.font[2], 13)
  assertEqual(#m.__fontsMade, 2)
end)

test("skin hud members: HudFont's false draws no shadow, and clears the last one", function()
  -- red under: an off arm that skips the call and leaves what the last pass set.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "contrast")
  local fs = fontString(m)
  local obj = S.HudFont(fs, { face = FACE, size = 12, shadow = true })
  assertEqual(obj.shadow[1], 2, "High Contrast's")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertEqual(S.HudShadow(), false)
  S.HudFont(fs, { face = FACE, size = 12, shadow = true })
  assertEqual(obj.shadow[1], 0)
  assertEqual(obj.shadow[2], 0)
  assertEqual(obj.shadowColor[4], 0, "and clear")
end)

test("skin hud members: HudFont's nil lets the host's stored shadow stand", function()
  -- red under: Ignore fonts drawing the skin's shadow, or dropping the player's.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "contrast")
  Skin:SetIgnore(OWNER, nil, true)
  assertNil(S.HudShadow(), "the owner ignores fonts")
  local fs = fontString(m)
  local obj = S.HudFont(fs, { face = FACE, size = 12, shadow = true })
  assertEqual(obj.shadow[1], 1, "true is the client's offset")
  assertEqual(obj.shadow[2], -1)
  assertEqual(F.rgba(obj.shadowColor), F.rgba({ 0, 0, 0, 1 }))
  S.HudFont(fs, { face = FACE, size = 12, shadow = { 3, -2, 0.1, 0.2, 0.3, 0.5 } })
  assertEqual(obj.shadow[1], 3, "a table is x, y, r, g, b, a")
  assertEqual(obj.shadow[2], -2)
  assertEqual(F.rgba(obj.shadowColor), F.rgba({ 0.1, 0.2, 0.3, 0.5 }))
  S.HudFont(fs, { face = FACE, size = 12, shadow = false })
  assertEqual(obj.shadow[1], 0, "stored off")
  assertEqual(obj.shadowColor[4], 0)
  S.HudFont(fs, { face = FACE, size = 12 })
  assertEqual(obj.shadow[1], 0, "none stored")
end)

test("skin hud members: a host's companion off draws its stored shadow under any skin", function()
  -- red under: the skin's answer winning over a player who turned the companion off.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "contrast")
  local fs = fontString(m)
  local obj = S.HudFont(fs, { face = FACE, size = 12, shadow = true, shadowFromSkin = false })
  assertEqual(obj.shadow[1], 1, "stored, not High Contrast's 2")
  S.HudFont(fs, { face = FACE, size = 12, shadow = false, shadowFromSkin = false })
  assertEqual(obj.shadow[1], 0, "stored off")
end)

test("skin hud members: HudFont tolerates a client with no CreateFont", function()
  -- red under: a font object assumed, which raises where the client has none.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "contrast")
  m.CreateFont = nil
  rawset(_G, "CreateFont", nil)
  local fs = fontString(m)
  assertNil(S.HudFont(fs, { face = FACE, size = 15, flags = "" }), "no object")
  local p = m.__paint(fs)
  assertEqual(p.font[1], FACE)
  assertEqual(p.font[2], 15)
  local x, y = S.HudShadow()
  assertEqual(p.shadowOffset[1], x, "on the string, the best that client has")
  assertEqual(p.shadowOffset[2], y)
end)

test("skin hud members: HudFont never hands SetFont what it refuses", function()
  -- red under: the sentinel as a flag, a zero height, a missing face, or a font file the client
  -- has not loaded leaving a fresh object with no font, which raises at the string's SetText.
  local m, Skin = F.env({ lsm = { ["font:Ka0s Prototype"] = "Fonts\\Proto.ttf" } })
  local S = F.owner(Skin, OWNER)
  local fs = fontString(m)
  local obj = S.HudFont(fs, { size = 0, flags = "@skin" })
  assertEqual(obj.font[1], "Fonts\\Proto.ttf", "the skin's HUD face")
  assertEqual(obj.font[2], 12)
  assertEqual(obj.font[3], S.FontFlags("@skin"))
  rawset(_G, "STANDARD_TEXT_FONT", "Fonts\\Standard.ttf")
  m.STANDARD_TEXT_FONT = "Fonts\\Standard.ttf"
  local real = obj.SetFont
  function obj:SetFont(path, ...)
    if path == "Fonts\\Missing.ttf" then return false end
    real(self, path, ...)
    return true
  end
  S.HudFont(fs, { face = "Fonts\\Missing.ttf", size = 16 })
  assertEqual(obj.font[1], "Fonts\\Standard.ttf", "the client's face, not none")
  assertEqual(obj.font[2], 16)
  rawset(_G, "STANDARD_TEXT_FONT", nil)
end)

test("skin hud members: HudFont paints nothing it cannot and records nothing", function()
  local m, Skin = F.env({ lsm = { ["font:Ka0s Prototype"] = "Fonts\\Proto.ttf" } })
  local S = F.owner(Skin, OWNER)
  assertNil(S.HudFont(nil, { face = FACE }))
  local tex = m.CreateFrame("Frame"):CreateTexture()
  assertNil(S.HudFont(tex, { face = FACE }), "a texture is no string")
  local fs = fontString(m)
  assertTrue(S.HudFont(fs) ~= nil, "no opts: the skin's own")
  local bare, skin = F.env()
  local unset = fontString(bare)
  assertNil(F.owner(skin, OWNER).HudFont(unset), "no face anywhere: left alone")
  assertNil(bare.__paint(unset).fontObject)
  assertNil(Skin.painted[fs], "the host's appearance pass calls it; a replay would draw a stale face")
end)

-- ── Skin.FollowOnce ──────────────────────────────────────────────────────────────────────────

test("skin hud members: FollowOnce resets once and records it per profile", function()
  -- red under: no gate, which re-runs over a companion the player turned off.
  local _, Skin = F.env()
  local p = { units = { player = { fontFromSkin = false } } }
  local keys = { "units.player.fontFromSkin" }
  assertTrue(Skin.FollowOnce(p, keys), "it ran")
  assertTrue(p.units.player.fontFromSkin, "the companion moved")
  assertTrue(p.skin.fullSkinReset, "the record")
  p.units.player.fontFromSkin = false
  assertFalse(Skin.FollowOnce(p, keys), "not twice")
  assertFalse(p.units.player.fontFromSkin, "a companion turned off stays off")
end)

test("skin hud members: FollowOnce creates only the record's table", function()
  -- red under: a path through a missing table made on the way.
  local _, Skin = F.env()
  local p = {}
  assertTrue(Skin.FollowOnce(p, { "units.player.fontFromSkin", "barFromSkin" }))
  assertNil(p.units, "a missing table stays missing")
  assertTrue(p.barFromSkin, "a top-level companion is set")
  assertTrue(p.skin.fullSkinReset)
  local q = { skin = { skin = "ember", pickerSeen = true } }
  Skin.FollowOnce(q, {})
  assertEqual(q.skin.skin, "ember", "a stored choice stays")
  assertTrue(q.skin.pickerSeen)
  assertTrue(q.skin.fullSkinReset)
end)

test("skin hud members: FollowOnce answers false and writes nothing on bad input", function()
  local _, Skin = F.env()
  assertFalse(Skin.FollowOnce(nil, {}))
  assertFalse(Skin.FollowOnce("x", {}))
  local p = {}
  assertFalse(Skin.FollowOnce(p, nil), "no keys, no record: the step has not run")
  assertNil(p.skin)
end)

test("skin hud members: FollowOnce passes opts on, and the colon form works", function()
  local _, Skin = F.env()
  local p = { bar = {} }
  assertTrue(Skin:FollowOnce(p, { "bar.texture" }, { companions = true }))
  assertTrue(p.bar.textureFromSkin, "ResetToSkin's opts.companions")
  local q = { skin = { fullSkinReset = false } }
  assertTrue(Skin:FollowOnce(q, {}), "false is not run yet")
end)
