-- tests/test_skin_ace.lua — AceGUI rows wear their page owner's skin and go back to AceGUI's shared
-- pool stock (SkinAce.lua minor 1, Options minor 32, OptionsRegistry minor 3, OptionsScroll minor 6;
-- LK-08 of Ka0sAddonsCommonTasks docs/2026-10-25-SKINNING).
--
-- The promises, on tests/fixture_skin_ace.lua's pooled AceGUI fake with AceGUI's anatomy:
--
--   * A REGISTERED OWNER AWAY FROM KA0S DEFAULT gets every widget its Options instance acquires
--     painted from its skin, through the one proxy on `O.AceGUI`.
--   * THE POOL STAYS CLEAN. A released widget is stock again before the next acquirer sees it:
--     another owner wears its own skin on it, and an acquirer outside Ka0s sees exactly what a
--     never-painted widget shows (every stock region, color, font object and backdrop).
--   * KA0S DEFAULT IS STOCK ACEGUI: nothing painted, nothing wrapped; an unregistered owner's
--     instance holds AceGUI itself.
--   * DURABLE: AceGUI's own recolors (SetDisabled, SetValue, the Slider edit box's hover, a
--     Label's SetFontObject) do not wash the skin out while the widget is owned.
--   * A failing restore never keeps a widget out of the pool; a host's OnRelease and the skin's
--     coexist; a skin switch with a page open repaints its rows one frame later; an `eui` owner's
--     rows never reach EllesmereUI; a widget another skinning addon skinned is left to it.

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  K.test, K.assertEqual, K.assertTrue, K.assertFalse, K.assertNil
local A = dofile("tests/fixture_skin_ace.lua")
local F = A.F

local OWNER, OTHER = A.OWNER, A.OTHER

local function rgb(c)
  if type(c) ~= "table" then return tostring(c) end
  return F.rgba({ c[1], c[2], c[3], 1 })
end
local function textColor(fs) return F.rgba({ fs:GetTextColor() }) end
local function ours(Skin, w, part, key)
  local st = Skin.__ace[w]
  local rec = st and st.parts[part or "frame"]
  return rec and rec.regions[key]
end

--- An env with `owner` registered on `skin` and an Options instance for it.
local function owned(skin, opts)
  local m, Skin, lib, ace = A.env(opts)
  F.owner(Skin, OWNER, skin)
  local O = A.instance(lib, OWNER)
  return m, Skin, O, ace, lib
end

-- ── painted for its owner ────────────────────────────────────────────────────────────────────

test("skin ace: an owned page's CheckBox is painted from the owner's skin through O.AceGUI", function()
  local m, Skin, O, ace = owned("obsidian")
  assertTrue(O.AceGUI ~= ace, "the instance holds the proxy")
  local cb = O.AceGUI:Create("CheckBox")
  cb:SetLabel("Show minimap button")
  assertEqual(cb.checkbg:GetAlpha(), 0, "the stock box is faded")
  assertEqual(cb.highlight:GetAlpha(), 0, "and the stock highlight")
  assertEqual(textColor(cb.text), rgb(Skin:ResolveSkin("obsidian")["text.body"]), "the label in the body role")
  local fill = ours(Skin, cb, "frame", "aceFill")
  assertTrue(fill ~= nil and fill:IsShown(), "the skin's box is drawn")
  assertEqual(Skin.__ace[cb].owner, OWNER, "owned")
  assertTrue(type(rawget(cb, "OnRelease")) == "function", "its release is wrapped")
  assertEqual(#m.__errors, 0, "nothing raised")
end)

test("skin ace: Ka0s Default paints AceGUI rows like every skin", function()
  -- SkinAce minor 2 (SkinPaint minor 6): Ka0s Default was stock AceGUI, the client's look; it now
  -- paints its rows from its tokens. red under: a Ka0s Default branch that leaves the row alone.
  local _, Skin, O = owned("ka0s")
  local cb = O.AceGUI:Create("CheckBox")
  assertEqual(Skin.__ace[cb] and Skin.__ace[cb].owner, OWNER, "painted for the owner")
  assertTrue(rawget(cb, "OnRelease") ~= nil, "and wrapped, so its release gives it back stock")
  assertEqual(cb.checkbg:GetAlpha(), 0, "the stock box faded")
  assertEqual(textColor(cb.text), rgb(Skin:ResolveSkin("ka0s")["text.body"]), "in Ka0s Default's body text")
end)

test("skin ace: an unregistered owner's instance holds AceGUI itself", function()
  local m, Skin, lib, ace = A.env()
  local O = A.instance(lib, OTHER)
  assertTrue(O.AceGUI == ace, "no proxy for a name that never registered")
  local cb = O.AceGUI:Create("CheckBox")
  assertNil(Skin.__ace[cb], "and nothing painted")
  local bare = A.instance(lib, nil)
  assertTrue(bare.AceGUI == m.LibStub("AceGUI-3.0"), "nor for a host with no addonName")
end)

test("skin ace: the proxy is AceGUI for everything but Create", function()
  local _, _, O, ace = owned("obsidian")
  assertTrue(O.AceGUI.__created == ace.__created, "fields read through")
  O.AceGUI:RegisterLayout("SkinAceFlow", function() end)
  assertTrue(ace:GetLayout("SkinAceFlow") ~= nil, "a method called on the proxy runs on AceGUI")
  O.AceGUI.__skinAceMark = true
  assertTrue(ace.__skinAceMark, "a write lands on AceGUI")
end)

test("skin ace: an owner that registers after lib:New is proxied at CreateOptionsPanel", function()
  local _, Skin, lib, ace = A.env()
  local O = A.instance(lib, OWNER)
  assertTrue(O.AceGUI == ace, "not registered yet: AceGUI itself")
  F.owner(Skin, OWNER, "glass")
  O.CreateOptionsPanel()
  assertTrue(O.AceGUI ~= ace, "the re-resolved handle is proxied")
  local cb = O.AceGUI:Create("CheckBox")
  assertEqual(Skin.__ace[cb].owner, OWNER)
end)

-- ── the pool stays clean ─────────────────────────────────────────────────────────────────────

test("skin ace: a released CheckBox is stock for the next acquirer outside Ka0s", function()
  local m, Skin, O, ace = owned("obsidian")
  local raw = ace:Create("CheckBox")
  local stock = A.snapshot(m, Skin, raw)
  ace:Release(raw)
  local cb = O.AceGUI:Create("CheckBox")
  assertTrue(cb == raw, "the pool handed the same object to the owner")
  assertTrue(A.snapshot(m, Skin, cb) ~= stock, "painted while owned")
  cb:SetValue(true)
  O.AceGUI:Release(cb)
  local again = ace:Create("CheckBox")
  assertTrue(again == raw, "and back to the next acquirer")
  assertEqual(A.snapshot(m, Skin, again), stock, "every stock region, color and font as a fresh widget's")
  assertFalse(ours(Skin, again, "frame", "aceFill"):IsShown(), "the skin's box is hidden")
  assertFalse(ours(Skin, again, "frame", "aceMark"):IsShown(), "and its mark")
  assertNil(rawget(again, "OnRelease"), "the wrapper is gone")
  assertNil(Skin.__ace[again].owner, "and nobody owns it")
end)

test("skin ace: another owner acquiring the pooled object wears its own skin, not the first's", function()
  local m, Skin, O, _, lib = owned("obsidian")
  F.owner(Skin, OTHER, "azeroth")
  local B = A.instance(lib, OTHER)
  local cb = O.AceGUI:Create("CheckBox")
  O.AceGUI:Release(cb)
  local theirs = B.AceGUI:Create("CheckBox")
  assertTrue(theirs == cb, "the same pooled object")
  local T = Skin:ResolveSkin("azeroth")
  assertEqual(textColor(theirs.text), rgb(T["text.body"]), "the second owner's body text")
  local p = m.__paint(ours(Skin, theirs, "frame", "aceFill"))
  if T["check.texture"] then
    assertTrue(p.texture ~= nil, "the second owner's box art")
  else
    assertEqual(F.rgba(p.color), F.rgba(T["check.bg"]), "the second owner's box color")
  end
  assertEqual(Skin.__ace[theirs].owner, OTHER)
end)

-- Every painter, one table: painted while owned, stock again for the next acquirer.
local TYPES = { "Button", "CheckBox", "Slider", "Dropdown", "EditBox", "MultiLineEditBox", "Heading", "Label",
                "InteractiveLabel", "Icon", "ColorPicker", "InlineGroup", "ScrollFrame" }

test("skin ace: every painted type is painted while owned and stock on its next acquisition", function()
  local m, Skin, O, ace = owned("obsidian")
  for _, wtype in ipairs(TYPES) do
    local raw = ace:Create(wtype)
    local stock = A.snapshot(m, Skin, raw)
    ace:Release(raw)
    local w = O.AceGUI:Create(wtype)
    assertTrue(w == raw, wtype .. ": the pooled object")
    assertEqual(Skin.__ace[w] and Skin.__ace[w].owner, OWNER, wtype .. ": owned")
    assertTrue(A.snapshot(m, Skin, w) ~= stock, wtype .. ": painted")
    O.AceGUI:Release(w)
    local again = ace:Create(wtype)
    assertEqual(A.snapshot(m, Skin, again), stock, wtype .. ": stock again")
    ace:Release(again)
  end
  assertEqual(#m.__errors, 0, "nothing raised: " .. table.concat(m.__errors, " | "))
end)

test("skin ace: a SimpleGroup has no painter and is never wrapped", function()
  local _, Skin, O = owned("obsidian")
  local g = O.AceGUI:Create("SimpleGroup")
  assertNil(Skin.__ace[g], "nothing to paint")
  assertNil(rawget(g, "OnRelease"))
end)

-- ── durability ───────────────────────────────────────────────────────────────────────────────

test("skin ace: SetDisabled and SetValue keep the skin's colors and mark", function()
  local _, Skin, O = owned("obsidian")
  local T = Skin:ResolveSkin("obsidian")
  local cb = O.AceGUI:Create("CheckBox")
  cb:SetDisabled(true)
  assertEqual(textColor(cb.text), rgb(T["text.disabled"]), "disabled: the skin's disabled text")
  cb:SetDisabled(false)
  assertEqual(textColor(cb.text), rgb(T["text.body"]), "enabled again: the skin's body, not AceGUI's white")
  local mark = ours(Skin, cb, "frame", "aceMark")
  assertFalse(mark:IsShown(), "unchecked: no mark")
  cb:SetValue(true)
  assertTrue(mark:IsShown(), "checked: the skin's mark")
  cb:SetValue(false)
  assertFalse(mark:IsShown(), "and gone again")
  cb:SetType("radio")
  assertEqual(mark:GetNumPoints(), 2, "the mark follows the radio's smaller box")
end)

test("skin ace: the Slider's edit box keeps the skin's edge through AceGUI's hover recolor", function()
  local _, Skin, O = owned("obsidian")
  local T = Skin:ResolveSkin("obsidian")
  local s = O.AceGUI:Create("Slider")
  local eb = s.editbox
  assertEqual(F.rgba({ eb:GetBackdropColor() }), F.rgba(T["input.bg"]), "the skin's input fill")
  eb:__fire("OnEnter")
  assertEqual(F.rgba({ eb:GetBackdropBorderColor() }), F.rgba(T["input.focus"]), "hovered: the focus edge")
  eb:__fire("OnLeave")
  assertEqual(F.rgba({ eb:GetBackdropBorderColor() }), F.rgba(T["input.border"]), "left: the skin's edge")
  O.AceGUI:Release(s)
  eb:__fire("OnEnter")
  assertEqual(F.rgba({ eb:GetBackdropBorderColor() }), "0.500,0.500,0.500,1", "released: AceGUI's own hover")
end)

test("skin ace: a Label keeps the skin's font through its host's SetFontObject, and gives the host's back",
  function()
  local _, Skin, O = owned("obsidian", { lsm = true })
  local lbl = O.AceGUI:Create("Label")
  local skinFont = lbl.label:GetFontObject()
  assertTrue(type(skinFont) == "table" and tostring(skinFont.name):find("LibKa0sSkin_LootHistory_body", 1, true),
    "the owner's body font object")
  local hostFont = { name = "HostHeadingFont", GetName = function(self) return self.name end }
  lbl:SetFontObject(hostFont)
  assertTrue(lbl.label:GetFontObject() == skinFont, "the host's set is followed by the skin's font again")
  O.AceGUI:Release(lbl)
  assertTrue(lbl.label:GetFontObject() == hostFont, "released: the host's font, not the skin's")
  assertEqual(Skin.__ace[lbl].owner, nil)
end)

-- ── the release chain ────────────────────────────────────────────────────────────────────────

test("skin ace: a raising restore still returns the widget to the pool, logged once", function()
  local m, Skin, O, ace = owned("obsidian")
  local dd = O.AceGUI:Create("Dropdown")
  local P = Skin.__P
  local unpaint = P.unpaint
  local function boom() error("restore blew up") end
  P.unpaint = boom
  local ok = pcall(O.AceGUI.Release, O.AceGUI, dd)
  P.unpaint = unpaint
  assertTrue(ok, "the release itself did not raise")
  assertNil(dd.pullout, "AceGUI's own OnRelease still ran (the pull-out went back)")
  local pool = ace.__pools.Dropdown
  assertTrue(pool and pool[#pool] == dd, "and the widget is in the pool")
  assertTrue(type(rawget(dd, "OnRelease")) == "function" and rawget(dd, "OnRelease") ~= nil, "its own OnRelease is back")
  assertEqual(#m.__errors, 1, "one line")
  assertTrue(m.__errors[1]:find("restore blew up", 1, true) ~= nil, "naming the failure")
  local again = O.AceGUI:Create("Dropdown")
  O.AceGUI:Release(again)
  P.unpaint = boom
  local d2 = O.AceGUI:Create("Dropdown")
  pcall(O.AceGUI.Release, O.AceGUI, d2)
  P.unpaint = unpaint
  assertEqual(#m.__errors, 1, "the same failure is not written twice: " .. table.concat(m.__errors, " | "))
end)

test("skin ace: a host OnRelease and the skin's restore both run, and a re-acquire is stock", function()
  local m, Skin, O, ace = owned("obsidian")
  local raw = ace:Create("CheckBox")
  local stock = A.snapshot(m, Skin, raw)
  ace:Release(raw)
  local cb = O.AceGUI:Create("CheckBox")
  local chained, callback = 0, 0
  Skin:OnRelease(cb, function() chained = chained + 1 end)
  cb:SetCallback("OnRelease", function() callback = callback + 1 end)
  assertTrue(Skin:PaintAce(OWNER, cb), "painting again in place")
  O.AceGUI:Release(cb)
  assertEqual(chained, 1, "the host's chained OnRelease ran")
  assertEqual(callback, 1, "and its OnRelease callback")
  local again = ace:Create("CheckBox")
  assertEqual(A.snapshot(m, Skin, again), stock, "stock for the next acquirer")
  assertNil(rawget(again, "OnRelease"), "every wrapper unwound")
end)

test("skin ace: a widget whose wrapper a host replaced is put back when it is acquired again", function()
  local m, Skin, O, ace = owned("obsidian")
  local raw = ace:Create("Label")
  local stock = A.snapshot(m, Skin, raw)
  ace:Release(raw)
  local lbl = O.AceGUI:Create("Label")
  lbl.OnRelease = nil   -- a host assigning OnRelease outright drops the skin's wrapper
  ace:Release(lbl)
  local B = O.AceGUI:Create("Label")
  assertTrue(B == lbl, "the same object")
  assertEqual(Skin.__ace[B].owner, OWNER, "painted for the owner again")
  O.AceGUI:Release(B)
  assertEqual(A.snapshot(m, Skin, ace:Create("Label")), stock, "and stock after a proper release")
end)

-- ── the dropdown's pull-out ──────────────────────────────────────────────────────────────────

test("skin ace: the dropdown's pull-out wears the owner's skin while open and is stock on close", function()
  local m, Skin, O = owned("obsidian")
  local T = Skin:ResolveSkin("obsidian")
  local dd = O.AceGUI:Create("Dropdown")
  local po = dd.pullout
  local item = A.item(m, "Epic")
  po:AddItem(item)
  po:Open()
  assertEqual(F.rgba({ po.frame:GetBackdropColor() }), F.rgba(T["menu.bg"]), "the menu fill")
  assertEqual(textColor(item.text), rgb(T["menu.text"]), "the item's text")
  po:Close()
  assertEqual(F.rgba({ po.frame:GetBackdropColor() }), "0,0,0,1", "closed: the stock fill")
  assertEqual(textColor(item.text), "1,1,1,1", "and the item's own white")
  O.AceGUI:Release(dd)
  po:Open()
  assertEqual(F.rgba({ po.frame:GetBackdropColor() }), "0,0,0,1", "a released pull-out opens stock")
end)

-- ── a skin switch with a page open ───────────────────────────────────────────────────────────

test("skin ace: Ka0s Default to Obsidian with a page open repaints its rows after the deferred re-render",
  function()
  local m, Skin, O, ace = owned("ka0s")
  local ctx = O.CreatePanel("SkinAcePage", "Ace page", {})
  local made = {}
  O.SetRenderer(ctx, function(c)
    made[#made + 1] = O.SessionCheckbox(c, nil, nil, { label = "Toggle", get = function() return true end,
                                                        set = function() end })
  end)
  ctx.panel:Show()
  ctx.panel:__fire("OnShow")
  assertEqual(#made, 1, "drawn on show")
  assertEqual(Skin.__ace[made[1]] and Skin.__ace[made[1]].owner, OWNER, "Ka0s Default paints it too")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(#made, 1, "not re-rendered inside the switch")
  m.__fireTimers()
  assertEqual(#made, 2, "re-rendered one frame later")
  local cb = made[2]
  assertEqual(Skin.__ace[cb] and Skin.__ace[cb].owner, OWNER, "the new row is painted")
  assertEqual(textColor(cb.text), rgb(Skin:ResolveSkin("obsidian")["text.body"]), "in the new skin")
  Skin:SetChoice(OWNER, "ka0s", "contrast")
  Skin:SetChoice(OWNER, "ka0s", "ember")
  m.__fireTimers()
  assertEqual(#made, 3, "two switches in one frame re-render once")
  assertTrue(ace ~= nil)
end)

-- ── EllesmereUI, and other skinning addons ───────────────────────────────────────────────────

test("skin ace: an eui owner's rows are painted from EllesmereUI's colors with zero EllesmereUI calls", function()
  local E = dofile("tests/fixture_skin_eui.lua")
  local Loader = dofile("tests/_kit/loader.lua")
  local m, Skin, eui = E.env()
  Loader.load("LibKa0s/SkinAce.lua", nil, m)
  m.hooksecurefunc = function() end
  local ace = A.pool(m)
  E.owner(Skin, OWNER, "eui", "ka0s")
  eui.login()
  local cb = ace:Create("CheckBox")
  assertTrue(Skin:PaintAce(OWNER, cb), "painted")
  assertEqual(eui.count(), 0, "the pooled widget never reaches EllesmereUI")
  assertEqual(textColor(cb.text), rgb(Skin:Token(OWNER, "text.body")), "in the provider's derived text color")
end)

test("skin ace: a widget another skinning addon skinned is left to it", function()
  local _, Skin, _, ace = owned("obsidian")
  local cb = ace:Create("CheckBox")
  rawset(cb.frame, "isSkinned", true)
  assertFalse(Skin:PaintAce(OWNER, cb), "stepped aside")
  assertEqual(cb.checkbg:GetAlpha(), 1, "nothing faded")
  local s = ace:Create("Slider")
  rawset(s.slider, "backdrop", {})
  assertFalse(Skin:PaintAce(OWNER, s), "ElvUI's backdrop mark too")
end)

-- ── the members ──────────────────────────────────────────────────────────────────────────────

test("skin ace: PaintAceTree paints a host container's widgets", function()
  local _, Skin, _, ace = owned("obsidian")
  local g = ace:Create("SimpleGroup")
  local cb, lbl = ace:Create("CheckBox"), ace:Create("Label")
  g:AddChild(cb)
  g:AddChild(lbl)
  assertEqual(Skin:PaintAceTree(OWNER, g), 2, "two painted")
  assertEqual(Skin.__ace[lbl].owner, OWNER)
  assertEqual(Skin:PaintAceTree(OTHER, g), 0, "an unregistered owner paints nothing")
end)

test("skin ace: Skin:OnRelease chains once and answers its function", function()
  local _, Skin, _, ace = owned("obsidian")
  local w = ace:Create("Label")
  local order = {}
  local own = w.OnRelease
  w.OnRelease = function() order[#order + 1] = "own" end
  local fn = function() order[#order + 1] = "chained" end
  assertTrue(Skin:OnRelease(w, fn) == fn, "answers fn")
  ace:Release(w)
  assertEqual(table.concat(order, ","), "chained,own", "the chained one first, then the widget's own")
  w.OnRelease = own
  assertNil(Skin:OnRelease(w, nil), "no function: nothing")
end)
