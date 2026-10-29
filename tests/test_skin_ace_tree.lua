-- tests/test_skin_ace_tree.lua — SkinAce coverage (SkinAce.lua minor 4; LK-03 of Ka0sAddonsCommonTasks
-- docs/2026-10-29-SKINNING_ROLLOUT): a host's own AceGUI widget type painted as the stock type it is
-- built from, and a painter for AceGUI's TreeGroup.
--
-- The promises, on tests/fixture_skin_ace.lua's pooled AceGUI fake:
--
--   * Skin:AliasAceType(hostType, baseType) makes a host type (AuraMaster's AuraMasterDropdown, the
--     stock Dropdown under a second pool name) painted by its base type's painter, kept by that
--     painter's durability hooks and given back stock on release, its host's own dressing (LEFT
--     justification) untouched. A bad alias is refused, logged once, and changes nothing.
--   * A TreeGroup is painted whole: both panes in `nav.bg` / `nav.border`, its row buttons' labels
--     in `nav.text` (a first-level row) or `nav.selText` (a deeper, selected or hovered one), their
--     highlight in `nav.selBg`, the tree scroll bar's track in `scroll.track`. Rows AceGUI makes or
--     re-dresses later (RefreshTree) are painted too, and the whole widget is stock again for the
--     next acquirer, including a row whose level changed while it was owned (options-ui-§19).
--   * Ka0s Default reproduces the TreeGroup's stock colors exactly; an eui owner's TreeGroup and
--     aliased rows are painted by the library, never handed to EllesmereUI.

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  K.test, K.assertEqual, K.assertTrue, K.assertFalse, K.assertNil
local A = dofile("tests/fixture_skin_ace.lua")
local F = A.F

local OWNER, OTHER, HOST = A.OWNER, A.OTHER, A.HOST_DROPDOWN

local function rgb(c)
  if type(c) ~= "table" then return tostring(c) end
  return F.rgba({ c[1], c[2], c[3], 1 })
end
local function textColor(fs) return F.rgba({ fs:GetTextColor() }) end
local function vertex(t) return F.rgba({ t:GetVertexColor() }) end
local GOLD, WHITE = rgb({ 1, 0.82, 0 }), rgb({ 1, 1, 1 })
local function ours(Skin, w, part, key)
  local st = Skin.__ace[w]
  local rec = st and st.parts[part or "frame"]
  return rec and rec.regions[key]
end

local function owned(skin, opts)
  local m, Skin, lib, ace = A.env(opts)
  F.owner(Skin, OWNER, skin)
  local O = A.instance(lib, OWNER)
  return m, Skin, O, ace, lib
end

-- A first-level row, a deeper one, another first-level one.
local TREE = {
  { value = "chat", text = "Chat", level = 1 },
  { value = "chat.say", text = "Say", level = 2 },
  { value = "loot", text = "Loot", level = 1 },
}
-- The same rows, the second one moved up a level and a fourth added.
local TREE2 = {
  { value = "chat", text = "Chat", level = 1 },
  { value = "combat", text = "Combat", level = 1 },
  { value = "loot", text = "Loot", level = 1 },
  { value = "loot.roll", text = "Roll", level = 2 },
}

-- ── AliasAceType ─────────────────────────────────────────────────────────────────────────────

test("skin ace tree: a host widget type has no painter until it is aliased", function()
  local _, Skin, O = owned("obsidian")
  local dd = O.AceGUI:Create(HOST)
  assertNil(Skin.__ace[dd] and Skin.__ace[dd].owner, "stock: the library knows no such type")
  assertFalse(Skin:PaintAce(OWNER, dd), "and PaintAce refuses it")
end)

test("skin ace tree: an aliased host type is painted by its base type's painter", function()
  local m, Skin, O = owned("obsidian")
  assertTrue(Skin:AliasAceType(HOST, "Dropdown"), "aliased")
  local T = Skin:ResolveSkin("obsidian")
  local dd = O.AceGUI:Create(HOST)
  assertEqual(Skin.__ace[dd] and Skin.__ace[dd].owner, OWNER, "owned")
  assertEqual(dd.dropdown.Left:GetAlpha(), 0, "the template art faded, as a Dropdown's is")
  local fill = ours(Skin, dd, "frame", "aceFill")
  assertTrue(fill ~= nil and fill:IsShown(), "the input box drawn")
  assertEqual(F.rgba(m.__paint(fill).color), F.rgba(T["input.bg"]), "in input.bg")
  assertEqual(textColor(dd.text), rgb(T["input.text"] or T["text.body"]), "its text in the input role")
  assertEqual(dd.text:GetJustifyH(), "LEFT", "the host's LEFT justification untouched")
  assertEqual(#m.__errors, 0, "nothing raised")
end)

test("skin ace tree: an aliased widget keeps the skin through its base type's durability hooks", function()
  local _, Skin, O = owned("obsidian")
  Skin:AliasAceType(HOST, "Dropdown")
  local T = Skin:ResolveSkin("obsidian")
  local dd = O.AceGUI:Create(HOST)
  dd:SetDisabled(true)
  assertEqual(textColor(dd.text), rgb(T["text.disabled"]), "disabled: the skin's disabled text")
  dd:SetDisabled(false)
  assertEqual(textColor(dd.text), rgb(T["input.text"] or T["text.body"]), "enabled: the skin's, not AceGUI's white")
end)

test("skin ace tree: a released aliased widget is stock for the next acquirer, pull-out included", function()
  local m, Skin, O, ace = owned("obsidian")
  Skin:AliasAceType(HOST, "Dropdown")
  local raw = ace:Create(HOST)
  local own = rawget(raw, "OnRelease")
  local stock = A.snapshot(m, Skin, raw)
  ace:Release(raw)
  local dd = O.AceGUI:Create(HOST)
  assertTrue(dd == raw, "the pooled object")
  assertTrue(A.snapshot(m, Skin, dd) ~= stock, "painted while owned")
  local po = dd.pullout
  po:AddItem(A.item(m, "Player"))
  po:Open()
  assertEqual(Skin.__ace[po] and Skin.__ace[po].owner, OWNER, "its open pull-out painted for the owner")
  O.AceGUI:Release(dd)
  assertNil(Skin.__ace[po].owner, "the pull-out handed back")
  local again = ace:Create(HOST)
  assertTrue(again == raw)
  assertEqual(A.snapshot(m, Skin, again), stock, "every stock region, color and font")
  assertTrue(rawget(again, "OnRelease") == own, "the wrapper is gone, the widget's own OnRelease back")
  assertEqual(again.text:GetJustifyH(), "LEFT", "and the host's own dressing is still its own")
end)

test("skin ace tree: AliasAceType refuses a bad alias, logs it once and changes nothing", function()
  local m, Skin, O = owned("obsidian")
  assertFalse(Skin:AliasAceType(nil, "Dropdown"), "no host type")
  assertFalse(Skin:AliasAceType(HOST, "SimpleGroup"), "a base type with no painter")
  assertFalse(Skin:AliasAceType("Dropdown", "Button"), "a host type with a painter of its own")
  assertFalse(Skin:AliasAceType(HOST, HOST), "a type aliased to itself")
  local before = #m.__errors
  assertFalse(Skin:AliasAceType(HOST, "SimpleGroup"), "refused again")
  assertEqual(#m.__errors, before, "logged once per refusal")
  assertTrue(before >= 3, "each refusal logged")
  assertTrue(m.__errors[1]:find("AliasAceType", 1, true) ~= nil, "naming the member")
  local dd = O.AceGUI:Create(HOST)
  assertNil(Skin.__ace[dd] and Skin.__ace[dd].owner, "nothing aliased")
  local b = O.AceGUI:Create("Dropdown")
  assertEqual(Skin.__ace[b].owner, OWNER, "the stock Dropdown still paints as a Dropdown")
end)

test("skin ace tree: a second alias to another base is refused; the same alias again is fine", function()
  local m, Skin = owned("obsidian")
  assertTrue(Skin:AliasAceType(HOST, "Dropdown"))
  assertTrue(Skin:AliasAceType(HOST, "Dropdown"), "every copy of a host may say it again")
  assertEqual(#m.__errors, 0)
  assertFalse(Skin:AliasAceType(HOST, "EditBox"), "the first base stands")
  assertEqual(#m.__errors, 1, "logged")
  assertEqual(Skin.__aceAlias[HOST], "Dropdown")
end)

-- ── the TreeGroup ────────────────────────────────────────────────────────────────────────────

test("skin ace tree: a TreeGroup's panes, rows, selection and scroll bar wear the owner's skin", function()
  local m, Skin, O = owned("obsidian")
  local T = Skin:ResolveSkin("obsidian")
  local tg = O.AceGUI:Create("TreeGroup")
  tg:SetTree(TREE)
  tg:SelectByValue("loot")
  assertEqual(Skin.__ace[tg] and Skin.__ace[tg].owner, OWNER, "owned")
  for _, key in ipairs({ "treeframe", "border" }) do
    local f = tg[key]
    assertEqual(F.rgba({ f:GetBackdropColor() }), F.rgba(T["nav.bg"]), key .. ": nav.bg")
    assertEqual(rgb({ f:GetBackdropBorderColor() }), rgb(T["nav.border"]), key .. ": nav.border")
  end
  local b = tg.buttons
  assertEqual(textColor(b[1].text), rgb(T["nav.text"]), "a first-level row in nav.text")
  assertEqual(textColor(b[2].text), rgb(T["nav.selText"]), "a deeper row in nav.selText")
  assertEqual(textColor(b[3].text), rgb(T["nav.selText"]), "the selected row in nav.selText")
  assertEqual(vertex(b[3]:GetHighlightTexture()), F.rgba(T["nav.selBg"]), "its highlight in nav.selBg")
  assertEqual(tg.scrollbg:GetAlpha(), 0, "the stock track faded")
  local track = ours(Skin, tg, "scrollbar", "aceTrack")
  assertTrue(track ~= nil and track:IsShown(), "the skin's track drawn")
  assertEqual(F.rgba(m.__paint(track).color), F.rgba(T["scroll.track"]), "in scroll.track")
  assertEqual(#m.__errors, 0, "nothing raised: " .. table.concat(m.__errors, " | "))
end)

test("skin ace tree: Ka0s Default draws the TreeGroup's stock colors exactly", function()
  local _, Skin, O = owned("ka0s")
  local tg = O.AceGUI:Create("TreeGroup")
  tg:SetTree(TREE)
  tg:SelectByValue("loot")
  assertEqual(Skin.__ace[tg] and Skin.__ace[tg].owner, OWNER, "painted under Ka0s Default, like every skin")
  assertEqual(F.rgba({ tg.treeframe:GetBackdropColor() }), "0.100,0.100,0.100,0.500", "the pane's fill")
  assertEqual(rgb({ tg.border:GetBackdropBorderColor() }), "0.400,0.400,0.400,1", "the content pane's edge")
  assertEqual(textColor(tg.buttons[1].text), GOLD, "GameFontNormal's gold")
  assertEqual(textColor(tg.buttons[2].text), WHITE, "GameFontHighlightSmall's white")
  assertEqual(textColor(tg.buttons[3].text), WHITE, "the selected row's white")
  assertEqual(vertex(tg.buttons[3]:GetHighlightTexture()), F.rgba({ 0.3, 0.5, 1, 1 }), "OptionsNav's select tint")
end)

test("skin ace tree: RefreshTree, a later row and the pointer keep the skin", function()
  local _, Skin, O = owned("obsidian")
  local T = Skin:ResolveSkin("obsidian")
  local tg = O.AceGUI:Create("TreeGroup")
  tg:SetTree(TREE)
  tg:SetTree(TREE2)
  local b = tg.buttons
  assertEqual(#b, 4, "AceGUI made a fourth row")
  assertEqual(textColor(b[2].text), rgb(T["nav.text"]), "a row that moved up a level: nav.text")
  assertEqual(textColor(b[4].text), rgb(T["nav.selText"]), "the new deeper row painted")
  assertEqual(vertex(b[4]:GetHighlightTexture()), F.rgba(T["nav.selBg"]), "with its highlight")
  b[1]:__fire("OnEnter")
  assertEqual(textColor(b[1].text), rgb(T["nav.selText"]), "hovered: nav.selText")
  b[1]:__fire("OnLeave")
  assertEqual(textColor(b[1].text), rgb(T["nav.text"]), "left: nav.text again")
  tg:SelectByValue("chat")
  b[1]:__fire("OnLeave")
  assertEqual(textColor(b[1].text), rgb(T["nav.selText"]), "a selected row stays nav.selText off the pointer")
end)

test("skin ace tree: a released TreeGroup is stock for the next acquirer, a re-leveled row included", function()
  local m, Skin, O, ace = owned("obsidian", { lsm = true })
  local raw = ace:Create("TreeGroup")
  local own = rawget(raw, "OnRelease")
  raw:SetTree(TREE2)
  raw:SetTree(TREE)
  ace:Release(raw)
  local stock = A.snapshot(m, Skin, raw)
  local tg = O.AceGUI:Create("TreeGroup")
  assertTrue(tg == raw, "the pooled object")
  tg:SetTree(TREE2)
  tg:SelectByValue("combat")
  tg:SetTree(TREE)
  assertTrue(A.snapshot(m, Skin, tg) ~= stock, "painted while owned")
  O.AceGUI:Release(tg)
  assertEqual(A.snapshot(m, Skin, tg), stock, "every pane, row, font and color as AceGUI left them")
  assertTrue(tg.buttons[2].text:GetFontObject() == A.ROW_FONT.small, "the deeper row's own font back")
  assertTrue(tg.buttons[4]:IsShown() == false, "and the hidden row")
  assertTrue(rawget(tg, "OnRelease") == own, "the wrapper is gone, the widget's own OnRelease back")
  local again = ace:Create("TreeGroup")
  again:SetTree(TREE)
  assertEqual(textColor(again.buttons[1].text), GOLD, "an acquirer outside Ka0s: stock gold")
  assertEqual(F.rgba({ again.treeframe:GetBackdropColor() }), "0.100,0.100,0.100,0.500", "and the stock pane")
  assertEqual(#m.__errors, 0, "nothing raised: " .. table.concat(m.__errors, " | "))
end)

test("skin ace tree: a row hook that rides the pooled TreeGroup elsewhere is inert", function()
  local _, Skin, O, ace = owned("obsidian")
  local tg = O.AceGUI:Create("TreeGroup")
  tg:SetTree(TREE)
  O.AceGUI:Release(tg)
  local again = ace:Create("TreeGroup")
  again:SetTree(TREE)
  again.buttons[1]:__fire("OnEnter")
  assertEqual(textColor(again.buttons[1].text), GOLD, "AceGUI's own color, not the skin's")
  assertNil(Skin.__ace[again].owner)
end)

test("skin ace tree: another owner's TreeGroup wears its own skin", function()
  local _, Skin, O, _, lib = owned("obsidian")
  F.owner(Skin, OTHER, "azeroth")
  local B = A.instance(lib, OTHER)
  local tg = O.AceGUI:Create("TreeGroup")
  tg:SetTree(TREE)
  O.AceGUI:Release(tg)
  local theirs = B.AceGUI:Create("TreeGroup")
  theirs:SetTree(TREE)
  local T = Skin:ResolveSkin("azeroth")
  assertEqual(F.rgba({ theirs.treeframe:GetBackdropColor() }), F.rgba(T["nav.bg"]), "the second owner's pane")
  assertEqual(textColor(theirs.buttons[1].text), rgb(T["nav.text"]), "and rows")
end)

test("skin ace tree: PaintAceTree paints a host's TreeGroup and the widgets in it", function()
  local _, Skin, _, ace = owned("obsidian")
  local tg = ace:Create("TreeGroup")
  tg:SetTree(TREE)
  local cb = ace:Create("CheckBox")
  tg:AddChild(cb)
  assertEqual(Skin:PaintAceTree(OWNER, tg), 2, "the tree and its check box")
  assertEqual(Skin.__ace[tg].owner, OWNER)
  assertEqual(Skin.__ace[cb].owner, OWNER)
end)

-- ── EllesmereUI ──────────────────────────────────────────────────────────────────────────────

test("skin ace tree: an eui owner's TreeGroup and aliased rows never reach EllesmereUI", function()
  local E = dofile("tests/fixture_skin_eui.lua")
  local Loader = dofile("tests/_kit/loader.lua")
  local m, Skin, eui = E.env()
  Loader.load("LibKa0s/SkinAce.lua", nil, m)
  m.hooksecurefunc = function() end
  local ace = A.pool(m)
  E.owner(Skin, OWNER, "eui", "ka0s")
  eui.login()
  assertTrue(Skin:AliasAceType(HOST, "Dropdown"))
  local tg = ace:Create("TreeGroup")
  tg:SetTree(TREE)
  assertTrue(Skin:PaintAce(OWNER, tg), "the tree painted")
  local dd = ace:Create(HOST)
  assertTrue(Skin:PaintAce(OWNER, dd), "the aliased dropdown painted")
  assertEqual(eui.count(), 0, "zero EllesmereUI calls")
  assertEqual(F.rgba({ tg.treeframe:GetBackdropColor() }), F.rgba(Skin:Token(OWNER, "nav.bg")),
    "the pane in the provider's derived nav.bg")
end)
