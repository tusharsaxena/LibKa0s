-- tests/test_skin_hud_tokens.lua -- LibKa0s-Skin-1.0's HUD text, fill and shadow tokens and their
-- getters (SkinDefs minor 24, SkinDefsOthers minor 6, SkinPaintExtras minor 12, Skin minor 13; FS-T1
-- of Ka0sAddonsCommonTasks docs/2026-11-01-FULL_SKINNING, causes D2, D3 and D6).
--
-- What it pins: Ka0s Default's values are what the HUD draws today; every other skin states its own,
-- and they read; the getters answer the owner's skin; Ignore fonts leaves the shadow to the host and the colors to the skin; and an addon whose stored
-- default differs keeps its pixels under Ka0s Default through an owner token that follows these.
--
-- Every case runs on a fresh environment (tests/fixture_skin_paint.lua).

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil
local F = dofile("tests/fixture_skin_paint.lua")

local OWNER = "AuraMaster"
local KEYS = { "ka0s", "obsidian", "azeroth", "glass", "contrast", "ember", "wow", "midnight", "forever" }

local function channel(c)
  if c <= 0.03928 then return c / 12.92 end
  return ((c + 0.055) / 1.055) ^ 2.4
end
local function luminance(c)
  return 0.2126 * channel(c[1]) + 0.7152 * channel(c[2]) + 0.0722 * channel(c[3])
end
local function contrast(a, b)
  local la, lb = luminance(a), luminance(b)
  if la < lb then la, lb = lb, la end
  return (la + 0.05) / (lb + 0.05)
end

test("skin hud tokens: the schema carries them, in the HUD group", function()
  local _, Skin = F.env()
  local want = { ["hud.text"] = "color", ["hud.label"] = "color", ["bar.fill"] = "color",
                 ["hud.shadow"] = "color", ["hud.shadowX"] = "number", ["hud.shadowY"] = "number" }
  for name, kind in pairs(want) do
    local entry = Skin.__schemaIndex[name]
    assertTrue(entry ~= nil, name .. " is in the schema")
    assertEqual(entry.kind, kind, name)
    assertEqual(entry.group, "HUD", name)
  end
  assertTrue(Skin.__schemaIndex["hud.shadow"].nilable, "`false` is how a skin says no shadow")
end)

test("skin hud tokens: Ka0s Default is what the HUD draws today", function()
  -- red under: Ka0s Default moving off a stored default most of the HUD draws: white text
  -- (AuraMaster, Absorb Tracker, KickCD, Party Frame Enhanced), gold labels (ConsumableMaster,
  -- MultiMeters, AuraMaster's container name), AuraMaster's blue fill, and no shadow.
  local _, Skin = F.env()
  assertEqual(F.tok(Skin, "ka0s", "hud.text"), F.rgba({ 1, 1, 1, 1 }), "white text")
  assertEqual(F.tok(Skin, "ka0s", "hud.label"), F.rgba({ 1, 0.82, 0, 1 }), "gold labels")
  assertEqual(F.tok(Skin, "ka0s", "bar.fill"), F.rgba({ 0.20, 0.55, 0.95, 1 }), "AuraMaster's blue")
  assertEqual(Skin:GetSkin("ka0s").tokens["hud.shadow"], false, "no shadow")
  local k = Skin:ResolveSkin("ka0s")
  assertEqual(k["hud.shadowX"], 1, "and the client's offset for a host that draws one")
  assertEqual(k["hud.shadowY"], -1)
end)

test("skin hud tokens: every other skin states its own, and they read", function()
  -- red under: a skin left on Ka0s Default's blue fill or white text while it has its own, or a
  -- HUD color that does not read on the bar's own backing.
  local _, Skin = F.env()
  for _, key in ipairs(KEYS) do
    local t = Skin:ResolveSkin(key)
    if key ~= "ka0s" then
      assertEqual(F.rgba(t["hud.text"]), F.rgba(t["text.body"]), key .. ": HUD text is its body")
      assertEqual(F.rgba(t["hud.label"]), F.rgba(t["text.accent"]), key .. ": a label is its accent")
      assertEqual(F.rgba(t["bar.fill"]), F.rgba(t["slider.fill"]), key .. ": a fill is its slider's")
      assertTrue(type(t["hud.shadow"]) == "table", key .. " draws a shadow")
      local ratio = contrast(t["hud.text"], t["hud.shadow"])
      assertTrue(ratio >= 4.5, ("%s: shadow contrast %.2f, want >= 4.5"):format(key, ratio))
    end
    for _, name in ipairs({ "hud.text", "hud.label" }) do
      local ratio = contrast(t[name], { 0, 0, 0 })
      assertTrue(ratio >= 4.5, ("%s: %s contrast %.2f, want >= 4.5"):format(key, name, ratio))
    end
  end
  local hc = Skin:ResolveSkin("contrast")
  assertEqual(hc["hud.shadowX"], 2, "High Contrast's heavier shadow")
  assertEqual(hc["hud.shadowY"], -2)
end)

test("skin hud tokens: the getters answer the owner's skin and are in the facade", function()
  -- red under: a getter reading Ka0s Default's table, or a name missing from VOCAB (a cached S
  -- would answer nothing after a minor upgrade).
  local _, Skin = F.env()
  for _, name in ipairs({ "HudTextColor", "HudLabelColor", "BarFillColor", "HudShadow" }) do
    local found = false
    for _, v in ipairs(Skin.VOCAB) do found = found or v == name end
    assertTrue(found, name .. " is in the vocabulary")
  end
  local S, t = F.owner(Skin, OWNER, "ember"), Skin:ResolveSkin("ember")
  assertEqual(F.rgba({ S.HudTextColor() }), F.rgba(t["hud.text"]))
  assertEqual(F.rgba({ S.HudLabelColor() }), F.rgba(t["hud.label"]))
  assertEqual(F.rgba({ S.BarFillColor() }), F.rgba(t["bar.fill"]))
  local x, y, r, g, b, a = S.HudShadow()
  assertEqual(x, 1); assertEqual(y, -1)
  assertEqual(F.rgba({ r, g, b, a }), F.rgba(t["hud.shadow"]))
  local bar = S.BarStyle()
  assertTrue(bar.text == t["hud.text"], "BarStyle carries the text color")
  assertTrue(bar.label == t["hud.label"], "the label color")
  assertTrue(bar.fill == t["bar.fill"], "and the fill")
  assertNil(Skin.painted[S], "a getter records nothing")
end)

test("skin hud tokens: HudShadow tells no shadow from the host's own", function()
  -- red under: Ka0s Default's `false` answering nil, which would hand the host its stored shadow
  -- under a skin that says none, or Ignore fonts answering the skin's.
  local _, Skin = F.env()
  local S = F.owner(Skin, OWNER, "ka0s")
  assertEqual(S.HudShadow(), false, "Ka0s Default: none")
  local G = F.owner(Skin, "Sleek", "glass")
  assertEqual(select("#", G.HudShadow()), 6, "a skin's: offset and color")
  Skin:SetIgnore("Sleek", nil, true)
  assertNil(G.HudShadow(), "Ignore fonts: the host's own stands")
  assertNil(G.Token("hud.shadow"), "as hud.outline does")
  assertEqual(G.Resolve("hud.shadow", "stored", true), "stored", "the stored value wins")
  assertEqual(F.rgba({ G.HudTextColor() }), F.tok(Skin, "glass", "hud.text"), "a color is not a font")
  assertEqual(F.rgba({ G.BarFillColor() }), F.tok(Skin, "glass", "bar.fill"))
  Skin:SetIgnore("Sleek", nil, false)
  assertEqual(select("#", G.HudShadow()), 6, "off again")
end)

test("skin hud tokens: an owner token keeps the addon's pixels under Ka0s Default and follows otherwise", function()
  -- The seam the default flips use: Absorb Tracker's fill and ConsumableMaster's own defaults differ
  -- from the skin's. red under: a follow on these tokens refused, or Ka0s Default answering them.
  local _, Skin = F.env()
  local mine = { 0.4, 0.7, 1, 0.8 }
  Skin:RegisterOwner(OWNER, { tokens = { ["at.fill"] = { default = mine, follow = "bar.fill" } } })
  local S = Skin:For(OWNER)
  assertEqual(F.rgba({ S.Color("at.fill") }), F.rgba(mine), "Ka0s Default: the addon's own")
  Skin:SetChoice(OWNER, "ka0s", "ember")
  assertEqual(F.rgba({ S.Color("at.fill") }), F.tok(Skin, "ember", "bar.fill"), "a skin: its fill")
end)
