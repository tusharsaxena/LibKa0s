-- tests/test_skin_primary_disabled.lua -- a disabled primary button looks like a disabled button
-- (SkinPaintControls minor 21, FB-LK-02 of Ka0sAddonsCommonTasks docs/2026-11-24-FEEDBACK_BATCH, the
-- owner's O2 finding, images 37-41 against Skin Tester's image 38).
--
-- THE DEFECT. Through minor 20 a disabled primary kept the primary box (`btnPrimary.bg`) and took
-- the disabled label (`text.disabled`): the skin's dim text on its bright primary fill, tan on tan in
-- Slate, lavender on lavender in Glass. Outfitter Reborn's New Outfit "Done" is disabled while the name
-- is empty, so every skin showed it. No skin defines a disabled-primary fill.
--
-- THE RULE. While disabled, a primary paints the plain `btn.*` box with `text.disabled`, exactly as
-- a disabled normal button does, unless the host remapped its own `bg` (Combat Trail's
-- ct.primary.off* look). Enabled again, it is a primary: `btnPrimary.bg` and `btnPrimary.text`.

local T = _G.LK_TEST
local test, assertEqual = T.test, T.assertEqual
local F = dofile("tests/fixture_skin_paint.lua")

local KEYS = { "ka0s", "obsidian", "azeroth", "glass", "contrast", "ember", "wow", "midnight", "forever" }

local function button(m, enabled)
  local b = m.CreateFrame("Button", nil, m.UIParent, "BackdropTemplate")
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  local on = { v = enabled }
  rawset(b, "IsEnabled", function() return on.v end)
  return b, on
end

local function fill(m, b) return F.rgba(m.__paint(b).backdropColor) end
local function label(m, b) return F.rgba(m.__paint(b.text).textColor) end

for _, key in ipairs(KEYS) do
  test("skin primary disabled: a disabled primary paints the plain button box and the disabled label (" .. key .. ")", function()
    -- red under: SkinPaintControls minor 20, which kept btnPrimary.bg under text.disabled.
    local m, Skin = F.env()
    local S = F.owner(Skin, "OutfitterReborn", key)
    local b = button(m, false)
    S.Button(b, { primary = true })
    assertEqual(fill(m, b), F.tok(Skin, key, "btn.bg"), "disabled at its first paint: btn.bg")
    assertEqual(label(m, b), F.tok(Skin, key, "text.disabled"), "and text.disabled")
    local plain = button(m, false)
    S.Button(plain)
    assertEqual(fill(m, b), fill(m, plain), "the same box as a disabled normal button")
  end)

  test("skin primary disabled: enabling restores the primary, disabling takes it back (" .. key .. ")", function()
    local m, Skin = F.env()
    local S = F.owner(Skin, "OutfitterReborn", key)
    local b, on = button(m, false)
    S.Button(b, { primary = true })
    on.v = true; b:__fire("OnEnable")
    assertEqual(fill(m, b), F.tok(Skin, key, "btnPrimary.bg"), "enabled: btnPrimary.bg")
    assertEqual(label(m, b), F.tok(Skin, key, "btnPrimary.text"), "and btnPrimary.text")
    on.v = false; b:__fire("OnDisable")
    assertEqual(fill(m, b), F.tok(Skin, key, "btn.bg"), "disabled again: btn.bg")
    assertEqual(label(m, b), F.tok(Skin, key, "text.disabled"))
    b:__fire("OnEnter")
    assertEqual(fill(m, b), F.tok(Skin, key, "btn.bg"), "no hover fill while disabled")
  end)
end

test("skin primary disabled: a host's own bg remap still wins while disabled", function()
  -- Combat Trail paints a disabled primary from ct.primary.off*; the library must not override it.
  local m, Skin = F.env()
  local S = F.owner(Skin, "LootHistory", "obsidian")
  local b = button(m, false)
  S.Button(b, { primary = true, tokens = { bg = "sem.bad" } })
  assertEqual(fill(m, b), F.tok(Skin, "obsidian", "sem.bad"), "the remapped bg")
end)
