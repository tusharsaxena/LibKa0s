-- tests/test_skin_ace_confirm.lua -- cause A4 of Ka0sAddonsCommonTasks docs/2026-11-01-FULL_SKINNING:
-- AceConfigDialog's one confirmation box wears the skin only when a Ka0s addon's profile page raised
-- it to delete a profile.
--
-- The fakes reproduce what the real files do. AceDBOptions-3.0 minor 15 hands every database the SAME
-- `args` table (`tbl.args = optionsTable`), so a write into `args` reaches every addon in the client.
-- ActivateControl reads `confirm` by walking `user.options` along `user.path`, calls a function
-- `confirm` with (info, value), and confirmPopup shows the box, sets its text and then measures it.

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  K.test, K.assertEqual, K.assertTrue, K.assertFalse, K.assertNil

local F = dofile("tests/fixture_skin_paint.lua")
local A = dofile("tests/fixture_skin_ace.lua")

local OWNER, OTHER = A.OWNER, A.OTHER

local function rgba(c) return F.rgba({ c[1], c[2], c[3], c[4] or 1 }) end
local function textColor(fs) return rgba({ fs:GetTextColor() }) end

--- AceConfigDialog's popup, as its file builds it.
local function stockPopup(m)
  local frame = m.CreateFrame("Frame", nil, m.UIParent)
  frame:Hide()
  rawset(frame, "SetBackdrop", false)   -- a plain Frame: no BackdropTemplate, the client's popup has none
  local border = m.CreateFrame("Frame", nil, frame, "DialogBorderOpaqueTemplate")
  local text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  text:SetTextColor(1, 1, 1)
  frame.text = text
  local function button()
    local b = m.CreateFrame("Button", nil, frame)
    local label = b:CreateFontString(nil, "OVERLAY")
    label:SetTextColor(1, 0.82, 0)
    rawset(b, "GetFontString", function() return label end)
    for _, g in ipairs({ "Normal", "Pushed", "Highlight" }) do
      local t = b:CreateTexture()
      rawset(b, "Get" .. g .. "Texture", function() return t end)
    end
    return b
  end
  frame.accept, frame.cancel = button(), button()
  return frame, border
end

--- The look of the box, as one string: what a give-back must return.
local function look(popup, border)
  local parts = { tostring(border:GetAlpha()), textColor(popup.text), tostring(popup.text:GetFontObject()) }
  for _, b in ipairs({ popup.accept, popup.cancel }) do
    parts[#parts + 1] = textColor(b:GetFontString())
    parts[#parts + 1] = tostring(b:GetNormalTexture():GetAlpha())
  end
  return table.concat(parts, "|")
end

local function env(skin)
  local m, Skin, _, ace = A.env()
  F.owner(Skin, OWNER, skin)
  F.owner(Skin, OTHER, skin)
  local popup, border = stockPopup(m)
  local shared = {
    current = { order = 10, type = "select" },
    delete = { order = 80, type = "select", name = "Delete", set = "DeleteProfile", values = "ListProfiles",
               disabled = "HasNoProfiles", arg = "nocurrent", confirm = true, confirmText = "Really?" },
  }
  local dbo = { optionTables = {} }
  m.__libs["AceConfigDialog-3.0"] = { popup = popup }
  m.__libs["AceDBOptions-3.0"] = dbo
  local function table_for(db)
    local tbl = { type = "group", handler = { db = db }, args = shared }
    dbo.optionTables[db] = tbl
    return tbl
  end
  return { m = m, Skin = Skin, ace = ace, popup = popup, border = border, shared = shared, dbo = dbo,
           tableFor = table_for }
end

--- AceConfigDialog:Open onto a fresh container: one widget per row, the path and the row's table in
--- its user data, then the host's PaintAceTree.
local function page(e, owner, options, path)
  local row = options
  for _, k in ipairs(path) do row = row.args[k] end
  local w = e.ace:Create("Dropdown")
  w.userdata.option, w.userdata.options, w.userdata.path = row, options, path
  local container = e.ace:Create("Dropdown")
  rawset(container, "children", { w })
  if owner then e.Skin:PaintAceTree(owner, container) end
  return w
end

local PATH = { "delete" }

--- frame:Hide(), and the OnHide the client would run.
local function hide(popup)
  popup:Hide()
  local fn = popup:GetScript("OnHide")
  if fn then fn(popup) end
end

--- ActivateControl: `confirm` found along the path, a function one called, and the box raised.
local function activate(e, w)
  local user = w.userdata
  local group, confirm = user.options, user.options.confirm
  for _, k in ipairs(user.path) do
    group = group.args[k]
    if group.confirm ~= nil then confirm = group.confirm end
  end
  if type(confirm) == "function" then confirm({}, "alt") end
  if confirm then
    e.popup:Show()
    e.popup.text:SetText(user.option.confirmText)
    return true
  end
  return false
end

test("confirm box: raised from a Ka0s profile page with the Scope cleared, it wears the skin", function()
  local e = env("midnight")
  local Skin, popup = e.Skin, e.popup
  Skin:SetIgnore(OWNER, false, false)
  activate(e, page(e, OWNER, e.tableFor("mine"), PATH))
  assertEqual(0, e.border:GetAlpha())
  assertEqual(0, popup.accept:GetNormalTexture():GetAlpha())
  local T = Skin:__Tokens(OWNER)
  assertEqual(rgba(T["text.body"]), textColor(popup.text))
  assertEqual(rgba(T["btn.text"]), textColor(popup.accept:GetFontString()))
  assertEqual(rgba(T["btn.text"]), textColor(popup.cancel:GetFontString()))
  assertTrue(F.region(Skin, popup, "fill"):IsShown())
end)

test("confirm box: the font is on before Ace measures the text", function()
  local e = env("midnight")
  e.Skin:SetIgnore(OWNER, false, false)
  activate(e, page(e, OWNER, e.tableFor("mine"), PATH))
  assertTrue(e.Skin.painted[e.popup.text] ~= nil)   -- activate stops at SetText, where Ace measures next
end)

test("confirm box: hiding gives every part back, and it is stock for whoever raises it next", function()
  local e = env("midnight")
  local Skin, popup = e.Skin, e.popup
  Skin:SetIgnore(OWNER, false, false)
  local stock = look(popup, e.border)
  activate(e, page(e, OWNER, e.tableFor("mine"), PATH))
  assertFalse(stock == look(popup, e.border))
  local fill = F.region(Skin, popup, "fill")
  hide(popup)
  assertEqual(stock, look(popup, e.border))
  assertFalse(fill:IsShown())
  for _, f in ipairs({ popup, popup.text, popup.accept, popup.cancel }) do assertNil(Skin.painted[f]) end
  popup:Show()   -- a box nobody owns stays as it is
  hide(popup)
  assertEqual(stock, look(popup, e.border))
end)

test("confirm box: it wears the skin every time, Open's redraw included", function()
  local e = env("midnight")
  e.Skin:SetIgnore(OWNER, false, false)
  local options = e.tableFor("mine")
  local args = page(e, OWNER, options, PATH) and options.args
  for _ = 1, 3 do
    -- Ace redraws the page on cancel and on accept with no PaintAceTree of the host's: a fresh row.
    activate(e, page(e, nil, options, PATH))
    assertEqual(0, e.border:GetAlpha())
    hide(e.popup)
    assertEqual(1, e.border:GetAlpha())
  end
  page(e, OWNER, options, PATH)
  assertTrue(args == options.args, "a second paint leaves the row as it is")
end)

test("confirm box: another addon's delete stays stock, before, after and while ours is open", function()
  local e = env("midnight")
  e.Skin:SetIgnore(OWNER, false, false)
  local popup = e.popup
  local stock = look(popup, e.border)
  local theirs = page(e, nil, e.tableFor("theirs"), PATH)
  assertTrue(activate(e, theirs))
  assertEqual(stock, look(popup, e.border))
  hide(popup)
  local mine = page(e, OWNER, e.tableFor("mine"), PATH)
  activate(e, mine)
  hide(popup)
  activate(e, theirs)
  assertEqual(stock, look(popup, e.border))
  hide(popup)
  activate(e, mine)
  assertFalse(stock == look(popup, e.border))
  activate(e, theirs)   -- the box is never modal: another addon's page can raise it over ours
  assertEqual(stock, look(popup, e.border))
end)

test("confirm box: the shared AceDBOptions tables are not written, nor another database's", function()
  local e = env("midnight")
  e.Skin:SetIgnore(OWNER, false, false)
  local delete = e.shared.delete
  local theirs = e.tableFor("theirs")
  local mine = e.tableFor("mine")
  page(e, OWNER, mine, PATH)
  assertTrue(e.shared.delete == delete)
  assertEqual(true, delete.confirm)
  assertTrue(theirs.args == e.shared)
  assertFalse(mine.args == e.shared)
end)

test("confirm box: the row keeps every field but its confirm, and every other row is the same table", function()
  local e = env("midnight")
  local mine = e.tableFor("mine")
  page(e, OWNER, mine, PATH)
  assertTrue(mine.args.current == e.shared.current)
  for k, v in pairs(e.shared.delete) do
    if k ~= "confirm" then assertEqual(v, mine.args.delete[k]) end
  end
  assertEqual(true, mine.args.delete.confirm({}, "alt"))
end)

test("confirm box: an owner ignoring its settings panel keeps the client's box, live both ways", function()
  local e = env("midnight")
  e.Skin:SetIgnore(OWNER, true, false)
  local stock = look(e.popup, e.border)
  local w = page(e, OWNER, e.tableFor("mine"), PATH)
  assertTrue(activate(e, w))
  assertEqual(stock, look(e.popup, e.border))
  hide(e.popup)
  e.Skin:SetIgnore(OWNER, false, false)
  activate(e, w)
  assertFalse(stock == look(e.popup, e.border))
end)

test("confirm box: a table AceDBOptions did not hand out, or another confirm row, is left alone", function()
  local e = env("midnight")
  e.Skin:SetIgnore(OWNER, false, false)
  local copied = { type = "group", handler = { db = "copied" }, args = e.shared }
  page(e, OWNER, copied, PATH)
  assertTrue(copied.args == e.shared)
  local mine = e.tableFor("mine")
  mine.args = { wipe = { type = "execute", set = "Wipe", confirm = true, confirmText = "Wipe?" } }
  local wipe = mine.args.wipe
  page(e, OWNER, mine, { "wipe" })
  assertTrue(mine.args.wipe == wipe)
end)

test("confirm box: nested under an addon's own group, the row is found by its path", function()
  local e = env("midnight")
  e.Skin:SetIgnore(OWNER, false, false)
  local root = { type = "group", args = { profiles = e.tableFor("mine") } }
  local w = page(e, OWNER, root, { "profiles", "delete" })
  activate(e, w)
  assertEqual(0, e.border:GetAlpha())
end)

test("confirm box: a box another skinning addon took is left to it", function()
  local e = env("midnight")
  e.Skin:SetIgnore(OWNER, false, false)
  rawset(e.popup, "template", "Transparent")
  local stock = look(e.popup, e.border)
  activate(e, page(e, OWNER, e.tableFor("mine"), PATH))
  assertEqual(stock, look(e.popup, e.border))
end)

test("confirm box: Ka0s Default paints it too", function()
  local e = env()
  e.Skin:SetIgnore(OWNER, false, false)
  activate(e, page(e, OWNER, e.tableFor("mine"), PATH))
  assertEqual(0, e.border:GetAlpha())
end)

test("confirm box: no AceConfigDialog on the client paints nothing and raises nothing", function()
  local e = env("midnight")
  e.Skin:SetIgnore(OWNER, false, false)
  e.m.__libs["AceConfigDialog-3.0"] = nil
  local w = page(e, OWNER, e.tableFor("mine"), PATH)
  assertEqual(true, w.userdata.options.args.delete.confirm({}, "alt"))
  assertEqual(0, #e.m.__errors)
end)
