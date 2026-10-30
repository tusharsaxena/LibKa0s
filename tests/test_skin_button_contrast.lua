-- tests/test_skin_button_contrast.lua — a button's label reads as enabled in every skin (LK-14 of
-- Ka0sAddonsCommonTasks docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK, the owner's item 16 and ruling D-25).
--
-- THE DEFECT. DpsRace's Arm Race button (a primary button) read muted, as if disabled, under Ka0s
-- Default, Obsidian and Glass (image-55..57). Measured off the screenshots, its label was exactly the
-- skin's `btnPrimary.text` at 0.40 alpha over the button's enabled fill: #FFFFFF at 0.4 over
-- Obsidian's #1E80D0 is (121, 179, 227), Glass's #1A1033 at 0.4 over #B69CFF is (119, 100, 173), and
-- Ka0s Default's gold at 0.4 over its fill is (127, 103, 5). The 0.4 is DpsRace's disabled-label alpha
-- (its `dr.*.offText` tokens). The library painted every text color through `P.rgb`, which handed an
-- OPAQUE color over as three numbers, and the client keeps a FontString's alpha when SetTextColor is
-- given no fourth: once a label had been painted disabled, every enabled paint after it kept 0.4.
-- SkinPaint minor 13 (still) hands every text and vertex color over with its alpha; kit revision 45
-- models the client's keep-the-alpha rule in mock_paint.lua, so the first case below is red on the
-- old `P.rgb`.
--
-- THE GUARD. Every skin's button label against the fill it is drawn on, for both bases (`btn` and
-- `btnPrimary`): WCAG's contrast ratio, the fill composited over the skin's window and a gradient
-- read at its midpoint. An enabled label holds at least MIN_ENABLED (3:1, WCAG's floor for large
-- text and for user-interface components), and its contrast is at least SEPARATION times the
-- disabled label's (`text.disabled` on the same fill), so the two states never read alike.
--
-- red under: P.rgb dropping an opaque color's alpha again; a skin whose button or primary-button
-- label falls under 3:1 on its own fill; a skin whose disabled label is nearly as strong as its
-- enabled one.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local F = dofile("tests/fixture_skin_paint.lua")

local OWNER = "DpsRace"
local MIN_ENABLED, SEPARATION = 3.0, 1.5

-- ── the regression: a label painted disabled, then enabled ─────────────────────────────────────

--- An owner registered with a 0.4-alpha disabled-label token, as DpsRace registers its own.
local function ownerWithFadedOff(Skin, skin)
  return Skin:RegisterOwner(OWNER, {
    get = function() return "ka0s", skin end,
    tokens = { ["dr.primary.offText"] = { default = { 1, 0.82, 0, 0.4 }, follow = "text.disabled",
                                          skins = { obsidian = { 1, 1, 1, 0.4 }, glass = { 0.1, 0.06, 0.2, 0.4 } } } },
  })
end

local function primaryButton(m)
  local b = m.CreateFrame("Button", nil, m.UIParent, "BackdropTemplate")
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  return b
end

for _, skin in ipairs({ "ka0s", "obsidian", "glass" }) do
  test("skin button contrast: a primary button enabled after a faded disabled paint draws its label opaque (" .. skin .. ")", function()
    -- red under: SkinPaint's P.rgb handing an opaque color over as three numbers (image-55..57)
    local m, Skin = F.env()
    local S = ownerWithFadedOff(Skin, skin)
    local b = primaryButton(m)
    local on = false
    rawset(b, "IsEnabled", function() return on end)
    S.Button(b, { primary = true, tokens = { disabled = "dr.primary.offText" } })
    local _, _, _, a = b.text:GetTextColor()
    assertTrue(a < 1, "the disabled label is the owner's faded color (alpha " .. tostring(a) .. ")")
    on = true; b:__fire("OnEnable")
    S.Button(b, { primary = true })
    local want = Skin:ResolveSkin(skin)["btnPrimary.text"]
    assertEqual(F.rgba({ b.text:GetTextColor() }), F.rgba(want), skin .. ": btnPrimary.text, opaque")
    b:__fire("OnEnter"); b:__fire("OnLeave")
    assertEqual(F.rgba({ b.text:GetTextColor() }), F.rgba(want), skin .. ": still opaque after a hover")
  end)
end

test("skin button contrast: a plain button's label is opaque again after a faded disabled paint", function()
  local m, Skin = F.env()
  local S = ownerWithFadedOff(Skin, "obsidian")
  local b = primaryButton(m)
  local on = false
  rawset(b, "IsEnabled", function() return on end)
  S.Button(b, { tokens = { disabled = "dr.primary.offText" } })
  on = true; b:__fire("OnEnable")
  assertEqual(F.rgba({ b.text:GetTextColor() }), F.tok(Skin, "obsidian", "btn.text"), "btn.text, opaque")
end)

-- ── the guard: label against fill, every skin ─────────────────────────────────────────────────

local function linear(v)
  if v <= 0.03928 then return v / 12.92 end
  return ((v + 0.055) / 1.055) ^ 2.4
end

local function luminance(c) return 0.2126 * linear(c[1]) + 0.7152 * linear(c[2]) + 0.0722 * linear(c[3]) end

--- `c` composited over the opaque `under`.
local function over(c, under)
  local a = c[4] or 1
  return { c[1] * a + under[1] * (1 - a), c[2] * a + under[2] * (1 - a), c[3] * a + under[3] * (1 - a), 1 }
end

local function ratio(x, y)
  local a, b = luminance(x), luminance(y)
  if a < b then a, b = b, a end
  return (a + 0.05) / (b + 0.05)
end

--- The fill a `base` button draws on, opaque: its gradient's midpoint when it has one, over the window.
local function fillOf(t, base)
  local win = over(t["win.bg"], { 0, 0, 0, 1 })
  local top, bottom = t[base .. ".bgTop"], t[base .. ".bgBottom"]
  if type(top) == "table" and type(bottom) == "table" then
    local a, b = over(top, win), over(bottom, win)
    return { (a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2, 1 }
  end
  return over(t[base .. ".bg"], win)
end

test("skin button contrast: every skin's enabled button label holds 3:1 on its fill, well clear of disabled", function()
  local _, Skin = F.env()
  local skins = Skin:Skins()
  assertTrue(#skins >= 9, "every shipped skin is registered")
  for _, def in ipairs(skins) do
    local t = Skin:ResolveSkin(def.key)
    for _, base in ipairs({ "btn", "btnPrimary" }) do
      local fill = fillOf(t, base)
      local on = ratio(over(t[base .. ".text"], fill), fill)
      local off = ratio(over(t["text.disabled"], fill), fill)
      local where = def.key .. "'s " .. base
      assertTrue(on >= MIN_ENABLED, string.format("%s label is %.2f:1 on its fill, under %.1f:1", where, on,
        MIN_ENABLED))
      assertTrue(on >= SEPARATION * off, string.format("%s enabled %.2f:1 against disabled %.2f:1: they read alike",
        where, on, off))
    end
  end
end)
