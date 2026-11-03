-- tests/test_skin_step_arrows.lua -- cause L7 of Ka0sAddonsCommonTasks docs/2026-11-01-FULL_SKINNING: a
-- scroll bar's step buttons are the Ka0s chevrons in `icon.arrow`, in every skin, wherever the bar is
-- painted: S.ScrollBar (the copy window, every addon's own bars, a settings page's always-shown bar)
-- and SkinAce's ScrollFrame, TreeGroup and MultiLineEditBox. Stock art comes back whole on release,
-- and one button painted through both paths is one mark.

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  K.test, K.assertEqual, K.assertTrue, K.assertFalse, K.assertNil

local F = dofile("tests/fixture_skin_paint.lua")
local A = dofile("tests/fixture_skin_ace.lua")

local OWNER = "LootHistory"

local function env()
  local files = {}
  for _, f in ipairs(F.FILES) do files[#files + 1] = f end
  files[#files + 1] = "Media"
  return F.env({ files = files })
end

local function rgba(c) return F.rgba({ c[1], c[2], c[3], c[4] or 1 }) end
local function vertex(t) return rgba({ t:GetVertexColor() }) end

--- A stock step button: the four state textures the template gives it.
local function stepButton(m)
  local b = m.CreateFrame("Button", nil, m.UIParent)
  local art = {}
  for _, g in ipairs({ "Normal", "Pushed", "Disabled", "Highlight" }) do
    local t = b:CreateTexture()
    art[#art + 1] = t
    rawset(b, "Get" .. g .. "Texture", function() return t end)
  end
  return b, art
end

--- A template bar with both step buttons as keys, the way a retail template hangs them.
local function bar(m)
  local sb = m.CreateFrame("Slider", nil, m.UIParent)
  local up, upArt = stepButton(m)
  local down, downArt = stepButton(m)
  sb.ScrollUpButton, sb.ScrollDownButton = up, down
  return sb, up, down, upArt, downArt
end

local function mark(Skin, btn)
  local rec = Skin.__steps[btn]
  return rec and rec.regions.art
end

test("step arrows: S.ScrollBar draws the Ka0s chevrons in icon.arrow, stock art faded, Ka0s Default too", function()
  local m, Skin = env()
  local S = F.owner(Skin, OWNER)
  local sb, up, down, upArt, downArt = bar(m)
  S.ScrollBar(sb)
  local Media = m.LibStub("LibKa0s-Media-1.0")
  assertEqual(m.__paint(mark(Skin, up)).texture, Media.Icon(OWNER, "chevron-up"))
  assertEqual(m.__paint(mark(Skin, down)).texture, Media.Icon(OWNER, "chevron-down"))
  assertEqual(vertex(mark(Skin, up)), rgba(Skin:ResolveSkin("ka0s")["icon.arrow"]))
  assertTrue(mark(Skin, down):IsShown(), "the mark is drawn")
  for _, t in ipairs(upArt) do assertEqual(t:GetAlpha(), 0, "the stock art is faded") end
  for _, t in ipairs(downArt) do assertEqual(t:GetAlpha(), 0, "on both buttons") end
end)

test("step arrows: a skin switch repaints them", function()
  local m, Skin = env()
  local S = F.owner(Skin, OWNER)
  local sb, up = bar(m)
  S.ScrollBar(sb)
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(vertex(mark(Skin, up)), rgba(Skin:ResolveSkin("obsidian")["icon.arrow"]))
end)

test("step arrows: a NAMED bar's buttons are found by name when the keys are absent", function()
  local m, Skin = env()
  local S = F.owner(Skin, OWNER)
  local sb = m.CreateFrame("Slider", nil, m.UIParent)
  rawset(sb, "GetName", function() return "LK_StepBar" end)
  local up = stepButton(m)
  _G.LK_StepBarScrollUpButton = up
  S.ScrollBar(sb)
  _G.LK_StepBarScrollUpButton = nil
  assertTrue(mark(Skin, up) ~= nil, "found by its template name")
end)

test("step arrows: hover takes icon.hot, a disabled button scroll.thumbOff, both live", function()
  local m, Skin = env()
  local S = F.owner(Skin, OWNER)
  local sb, up = bar(m)
  up:Disable()
  S.ScrollBar(sb)
  local T = Skin:ResolveSkin("ka0s")
  assertEqual(vertex(mark(Skin, up)), rgba(T["scroll.thumbOff"]), "a button that starts disabled reads inert")
  up:__fire("OnEnter")
  assertEqual(vertex(mark(Skin, up)), rgba(T["scroll.thumbOff"]), "hover does not wake it")
  up:Enable()
  up:__fire("OnEnable")
  assertEqual(vertex(mark(Skin, up)), rgba(T["icon.hot"]), "enabled under the pointer")
  up:__fire("OnLeave")
  assertEqual(vertex(mark(Skin, up)), rgba(T["icon.arrow"]), "at rest")
  up:Disable()
  up:__fire("OnDisable")
  assertEqual(vertex(mark(Skin, up)), rgba(T["scroll.thumbOff"]), "the client disables it at the top of the range")
end)

test("step arrows: unpainted, the stock art is back, the mark gone and its hooks inert", function()
  local m, Skin = env()
  local S = F.owner(Skin, OWNER)
  local sb, up, _, upArt = bar(m)
  S.ScrollBar(sb)
  local t = mark(Skin, up)
  Skin.__P.unpaint(Skin.painted[sb], sb)
  for _, a in ipairs(upArt) do assertEqual(a:GetAlpha(), 1, "the stock art's alpha is back") end
  assertFalse(t:IsShown(), "the mark is hidden")
  local before = vertex(t)
  up:__fire("OnEnter")
  assertEqual(vertex(t), before, "a released button's hover paints nothing")
end)

test("step arrows: without an owner's art the stock buttons stay", function()
  local m, Skin = F.env()   -- no Media in this copy
  local S = F.owner(Skin, OWNER)
  local sb, up, _, upArt = bar(m)
  S.ScrollBar(sb)
  assertNil(mark(Skin, up), "no mark")
  assertEqual(upArt[1]:GetAlpha(), 1, "and the stock art is not faded to nothing")
end)

test("step arrows: a bar with no step buttons, the console's, paints as before", function()
  local m, Skin = env()
  local S = F.owner(Skin, OWNER)
  local sb = m.CreateFrame("Slider", nil, m.UIParent)
  S.ScrollBar(sb)
  assertTrue(F.region(Skin, sb, "track") ~= nil, "its corridor is drawn")
end)

-- ── AceGUI ───────────────────────────────────────────────────────────────────────────────────

local function aceEnv(skin)
  local files = {}
  for _, f in ipairs(A.FILES) do files[#files + 1] = f end
  files[#files + 1] = "Media"
  local m, Skin, lib, ace = A.env({ files = files })
  F.owner(Skin, A.OWNER, skin)
  return m, Skin, lib, ace
end

test("step arrows: an AceGUI ScrollFrame's bar wears them, and a release gives the pool stock art", function()
  local m, Skin, _, ace = aceEnv("obsidian")
  local w = ace:Create("ScrollFrame")
  local up, upArt = stepButton(m)
  w.scrollbar.ScrollUpButton = up
  assertTrue(Skin:PaintAce(A.OWNER, w), "painted")
  local t = mark(Skin, up)
  assertEqual(vertex(t), rgba(Skin:ResolveSkin("obsidian")["icon.arrow"]))
  assertEqual(upArt[1]:GetAlpha(), 0, "the stock art is faded")
  ace:Release(w)
  assertEqual(upArt[1]:GetAlpha(), 1, "and back for the next acquirer")
  assertFalse(t:IsShown(), "the mark is gone")
end)

test("step arrows: a page's bar painted by both SkinAce and S.ScrollBar is one mark, and comes back whole", function()
  local m, Skin, _, ace = aceEnv("obsidian")
  local S = Skin:For(A.OWNER)
  local w = ace:Create("ScrollFrame")
  local up, upArt = stepButton(m)
  w.scrollbar.ScrollUpButton = up
  Skin:PaintAce(A.OWNER, w)
  local t = mark(Skin, up)
  S.ScrollBar(w.scrollbar, { state = "on" })
  assertTrue(mark(Skin, up) == t, "the same mark")
  Skin.__P.unpaint(Skin.painted[w.scrollbar], w.scrollbar)
  ace:Release(w)
  assertEqual(upArt[1]:GetAlpha(), 1, "the stock art's alpha is its own, not the faded one a second record saved")
end)

test("step arrows: an ignored settings panel keeps the client's buttons, live both ways", function()
  local m, Skin, lib = aceEnv("obsidian")
  local sb, up, _, upArt = bar(m)
  Skin:SetIgnore(A.OWNER, false)
  lib.__chromePaint(A.OWNER, "ScrollBar", sb, { state = "on" })
  assertEqual(upArt[1]:GetAlpha(), 0, "Scope cleared: the stock art is faded")
  local t = mark(Skin, up)
  Skin:SetIgnore(A.OWNER, true)
  lib.__chromePaint(A.OWNER, "ScrollBar", sb, { state = "on" })
  assertEqual(upArt[1]:GetAlpha(), 1, "ignored: the client's art")
  assertFalse(t:IsShown(), "and no mark")
  Skin:SetIgnore(A.OWNER, false)
  lib.__chromePaint(A.OWNER, "ScrollBar", sb, { state = "on" })
  assertTrue(t:IsShown(), "and back")
  assertEqual(upArt[1]:GetAlpha(), 0, "faded again")
end)

test("step arrows: a MultiLineEditBox's bar wears them", function()
  local m, Skin, _, ace = aceEnv("obsidian")
  local w = ace:Create("MultiLineEditBox")
  local sb = m.CreateFrame("Slider", nil, m.UIParent)
  local up = stepButton(m)
  sb.ScrollUpButton = up
  w.scrollBar = sb
  Skin:PaintAce(A.OWNER, w)
  assertTrue(mark(Skin, up) ~= nil, "painted")
end)
