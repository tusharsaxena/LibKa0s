-- tests/test_skin_ace_dropdown.lua -- R3-L1 of Ka0sAddonsCommonTasks docs/2026-11-02-SMOKE_ROUND3: an
-- AceGUI Dropdown and the library's media pickers (Ka0sMedia_Font, Ka0sMedia_Statusbar, aliased to the
-- Dropdown) wear the skinned WowStyle1 dropdown (S.Dropdown, SF-L7): a flat box in the skin's colors,
-- the label left-aligned, one Ka0s chevron in `icon.arrow`, AceGUI's gold button faded, and the
-- pull-out skinned down to its check marks (images 83, 84: the gold button and a right-aligned label
-- under every skin).
--
-- What it pins: the closed row's look under a skin; the chevron in `text.disabled` while disabled;
-- release giving every piece back stock; the media pickers painted the same with their preview's
-- anchors untouched; Ignore settings panel keeping the row stock; a copy with no Media keeping the
-- gold button rather than drawing no arrow at all; a pull-out item's check in `check.mark`.

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  K.test, K.assertEqual, K.assertTrue, K.assertFalse, K.assertNil
local A = dofile("tests/fixture_skin_ace.lua")
local F = A.F

local OWNER = A.OWNER

--- An env with Media loaded (the chevron's art), `owner` on `skin`, and an Options instance for it.
local function owned(skin, noMedia)
  local files = {}
  for _, f in ipairs(A.FILES) do files[#files + 1] = f end
  if not noMedia then files[#files + 1] = "Media" end
  local m, Skin, lib, ace = A.env({ files = files })
  F.owner(Skin, OWNER, skin)
  for _, t in ipairs(A.MEDIA_TYPES) do Skin:AliasAceType(t, "Dropdown") end
  return m, Skin, A.instance(lib, OWNER), ace
end

local function rgba(c) return F.rgba({ c[1], c[2], c[3], c[4] or 1 }) end

--- The widget's chevron, the one Ka0s mark on its frame's record.
local function chevron(Skin, w)
  local st = Skin.__ace[w]
  local rec = st and st.parts.frame
  return rec and rec.regions.chevron
end

local function buttonArt(w)
  local b = w.button
  return { b:GetNormalTexture(), b:GetPushedTexture(), b:GetDisabledTexture(), b:GetHighlightTexture() }
end

local function alphas(w)
  local out = {}
  for i, t in ipairs(buttonArt(w)) do out[i] = string.format("%g", t:GetAlpha()) end
  return table.concat(out, ",")
end

test("skin ace dropdown: a Dropdown is the skinned dropdown, label left, one chevron, no gold button", function()
  -- red under: SkinAce's Dropdown painter boxing the row and leaving the button and the alignment.
  local m, Skin, O = owned("obsidian")
  local T = Skin:ResolveSkin("obsidian")
  local dd = O.AceGUI:Create("Dropdown")
  assertEqual(dd.text:GetJustifyH(), "LEFT", "the label left-aligned")
  assertEqual(alphas(dd), "0,0,0,0", "AceGUI's gold button faded, every state")
  local c = chevron(Skin, dd)
  assertTrue(c ~= nil and c:IsShown(), "one chevron")
  local Media = m.LibStub("LibKa0s-Media-1.0")
  assertEqual(m.__paint(c).texture, Media.Icon(OWNER, "chevron-down"), "the Ka0s chevron, as S.Dropdown's")
  assertEqual(rgba({ c:GetVertexColor() }), rgba(T["icon.arrow"]), "in icon.arrow")
  assertTrue(m.__paint(c).desaturated == true, "desaturated, so the skin's color shows")
  local fill = Skin.__ace[dd].parts.frame.regions.aceFill
  assertTrue(fill ~= nil and fill:IsShown(), "the flat box")
end)

test("skin ace dropdown: a disabled Dropdown's chevron reads in text.disabled, and back", function()
  local _, Skin, O = owned("obsidian")
  local T = Skin:ResolveSkin("obsidian")
  local dd = O.AceGUI:Create("Dropdown")
  dd:SetDisabled(true)
  assertEqual(rgba({ chevron(Skin, dd):GetVertexColor() }), rgba(T["text.disabled"]))
  dd:SetDisabled(false)
  assertEqual(rgba({ chevron(Skin, dd):GetVertexColor() }), rgba(T["icon.arrow"]))
end)

test("skin ace dropdown: a released Dropdown is stock: right-aligned, the gold button back, no chevron", function()
  -- red under: the alignment or the button's alpha left on a widget AceGUI pools for every addon.
  local m, Skin, O, ace = owned("obsidian")
  local raw = ace:Create("Dropdown")
  local stock = A.snapshot(m, Skin, raw)
  ace:Release(raw)
  local dd = O.AceGUI:Create("Dropdown")
  assertTrue(dd == raw, "the pooled object")
  local c = chevron(Skin, dd)
  O.AceGUI:Release(dd)
  assertEqual(dd.text:GetJustifyH(), "RIGHT", "the template's alignment back")
  assertEqual(alphas(dd), "1,1,1,1", "the gold button back")
  assertFalse(c:IsShown(), "the chevron hidden")
  assertEqual(A.snapshot(m, Skin, ace:Create("Dropdown")), stock, "stock for the next acquirer")
end)

test("skin ace dropdown: the media pickers paint the same, their preview's anchors untouched", function()
  local m, Skin, O = owned("glass")
  for _, t in ipairs(A.MEDIA_TYPES) do
    local w = O.AceGUI:Create(t)
    assertEqual(Skin.__ace[w].owner, OWNER, t .. ": painted as a Dropdown")
    assertEqual(w.text:GetJustifyH(), "LEFT", t .. ": left-aligned")
    assertEqual(alphas(w), "0,0,0,0", t .. ": no gold button")
    assertTrue(chevron(Skin, w) ~= nil and chevron(Skin, w):IsShown(), t .. ": one chevron")
    -- OptionsMedia's closedExtra anchors the text after its swatch; a paint that moved it would
    -- push the preview out of the box.
    w.text:ClearAllPoints()
    w.text:SetPoint("LEFT", w.button_cover, "LEFT", 54, 0)
    Skin:PaintAce(OWNER, w)
    assertEqual(w.text:GetNumPoints(), 1, t .. ": the paint sets no anchor")
    assertEqual(select(4, w.text:GetPoint(1)), 54, t .. ": the preview's offset stands")
  end
  assertEqual(#m.__errors, 0)
end)

test("skin ace dropdown: Ignore settings panel keeps the stock row, gold button and all", function()
  -- red under: the new pieces painted ahead of SkinAce's __PanelSkinned question.
  local _, Skin, O = owned("obsidian")
  Skin:SetIgnore(OWNER, true, nil)
  local dd = O.AceGUI:Create("Dropdown")
  assertEqual(dd.text:GetJustifyH(), "RIGHT")
  assertEqual(alphas(dd), "1,1,1,1")
  assertNil(chevron(Skin, dd))
end)

test("skin ace dropdown: with no Media to draw a chevron, the gold button stays", function()
  -- red under: the button faded with nothing in its place, a dropdown with no arrow.
  local _, Skin, O = owned("obsidian", true)
  local dd = O.AceGUI:Create("Dropdown")
  assertNil(chevron(Skin, dd), "no chevron art")
  assertEqual(alphas(dd), "1,1,1,1", "so the button is its arrow")
  assertEqual(dd.text:GetJustifyH(), "LEFT", "still left-aligned")
end)

test("skin ace dropdown: an open pull-out's check marks take check.mark, and are stock on close", function()
  local m, Skin, O = owned("obsidian")
  local T = Skin:ResolveSkin("obsidian")
  local dd = O.AceGUI:Create("Dropdown")
  local item = A.item(m, "Epic")
  dd.pullout:AddItem(item)
  dd.pullout:Open()
  assertEqual(rgba({ item.check:GetVertexColor() }), rgba(T["check.mark"]), "the check in the skin's mark color")
  assertTrue(m.__paint(item.check).desaturated == true, "desaturated, so the gold goes")
  dd.pullout:Close()
  assertTrue(not m.__paint(item.check).desaturated, "closed: the client's gold back")
end)
