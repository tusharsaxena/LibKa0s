-- tests/test_options_media.lua -- LibKa0s-Options-1.0's OptionsMedia.lua (minor 1): the Ka0sMedia_*
-- picker types, their rows, and the two callers that reach for them (the Skin tab, and an
-- unregistered LSM30_* row).
--
-- THE BENCH. tests/fixture_skin_ace.lua's pooled AceGUI, because "a font never rides a pooled object
-- into the next acquirer" is the promise, plus what that fixture's Dropdown leaves out and the
-- pickers lean on, written from AceGUIWidget-DropDown.lua: the stock Dropdown and
-- Dropdown-Item-Toggle REGISTERED (the kit's fake registers neither, which is the case the
-- OptionsMedia header calls a client without the picker), SetList / SetValue / AddItem, and a
-- pull-out that fires OnOpen and releases its items on Clear.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local A = dofile("tests/fixture_skin_ace.lua")
local Loader = dofile("tests/_kit/loader.lua")

local FACE = { ["Ka0s Expressway"] = "Fonts\\Expressway.ttf", ["Ka0s Fira Sans"] = "Fonts\\FiraSans.ttf",
               ["Ka0s Prototype"] = "Fonts\\Prototype.ttf" }
local LSM = {
  ["font:Ka0s Expressway"] = FACE["Ka0s Expressway"], ["font:Ka0s Fira Sans"] = FACE["Ka0s Fira Sans"],
  ["font:Ka0s Prototype"] = FACE["Ka0s Prototype"],
  ["statusbar:Smooth"] = "Tex\\Smooth", ["statusbar:Flat"] = "Tex\\Flat",
  ["border:Glass"] = "Tex\\GlassEdge", ["background:Solid"] = "Tex\\Solid",
  ["sound:Ding"] = "Sound\\Ding.ogg",
}
local BASE_FONT = "Fonts\\BASE.TTF"

--- Give the fixture's pull-out what AceGUI's has: callbacks, OnOpen, an item walk, a releasing Clear.
local function fullPullout(ace, po)
  if po.__full then return end
  po.__full = true
  po.events = {}
  po.SetCallback = function(self, name, fn) self.events[name] = fn end
  po.IterateItems = function(self) return ipairs(self.items) end
  po.Open = function(self)
    self.frame:Show()
    if self.events.OnOpen then self.events.OnOpen(self, "OnOpen") end
  end
  po.Clear = function(self)
    for i = #self.items, 1, -1 do
      ace:Release(self.items[i])
      self.items[i] = nil
    end
  end
end

--- AceGUIWidget-DropDown.lua's methods, on the fixture's anatomy.
local function stockDropdown(m, ace)
  local w = m.__makeAceGUIWidget("Dropdown")
  A.dress(m, w, "Dropdown")
  w.text:SetFont(BASE_FONT, 10, "")
  local acquire, release = w.OnAcquire, w.OnRelease
  w.OnRelease = function(self)
    release(self)
    self.value, self.list, self.open = nil, nil, nil
    self:SetText("")
  end
  w.OnAcquire = function(self)
    acquire(self)
    fullPullout(ace, self.pullout)
    self.pullout.events.OnOpen = function(this) this.userdata.obj.open = true end
    self.list = {}
  end
  w.SetText = function(self, text) self.text:SetText(text or "") end
  w.SetValue = function(self, value)
    self:SetText(self.list[value] or "")
    self.value = value
  end
  w.GetValue = function(self) return self.value end
  local function addRow(self, value, text, itemType)
    local item = ace:Create(itemType or "Dropdown-Item-Toggle")
    item.userdata = item.userdata or {}
    item.userdata.value = value
    item:SetText(text)
    self.pullout:AddItem(item)
  end
  w.SetList = function(self, list, order, itemType)
    self.list = list or {}
    self.pullout:Clear()
    for _, key in ipairs(order or {}) do addRow(self, key, list[key], itemType) end
  end
  w.AddItem = function(self, value, text, itemType)
    self.list[value] = text
    addRow(self, value, text, itemType)
  end
  return w
end

local function stockItem(m)
  local w = m.__makeAceGUIWidget("Dropdown-Item-Toggle")
  A.dress(m, w, "Dropdown-Item-Toggle")
  local item = A.item(m, "")
  w.frame, w.text, w.highlight = item.frame, item.text, item.highlight
  w.text:SetFont(BASE_FONT, 10, "")
  w.SetText = function(self, text) self.text:SetText(text or "") end
  w.OnAcquire = function() end
  w.OnRelease = function(self) self.frame:Hide() end
  return w
end

--- A client whose AceGUI carries the stock Dropdown. `opts.noLsm` leaves LibSharedMedia out.
local function env(opts)
  opts = opts or {}
  local files = {}
  for i, f in ipairs(A.FILES) do files[i] = f end
  files[#files + 1] = "OptionsAppearance"
  local m, Skin, lib, ace = A.env({ files = files, lsm = not opts.noLsm and LSM or nil })
  Loader.load("LibKa0s/OptionsMedia.lua", nil, m)
  -- The kit's SetText overwrites `text`, the field the fixture's Button keeps its FontString in; the
  -- Skin tab's buttons set their words before anything reads it.
  local create = ace.Create
  ace.Create = function(self, wtype, ...)
    local w = create(self, wtype, ...)
    if wtype == "Button" then w.SetText = function() end end
    return w
  end
  if not opts.noBase then
    ace:RegisterWidgetType("Dropdown", function() return stockDropdown(m, ace) end, 41)
    ace:RegisterWidgetType("Dropdown-Item-Toggle", function() return stockItem(m) end, 1)
  end
  if not opts.noLsm then
    local L = m.LibStub("LibSharedMedia-3.0", true)
    L.HashTable = function(_, kind)
      local out = {}
      for k, v in pairs(LSM) do
        local name = k:match("^" .. kind .. ":(.+)$")
        if name then out[name] = v end
      end
      return out
    end
  end
  return m, Skin, lib, ace
end

local function font(fs) return (fs:GetFont()) end

local function picker(lib, ace, kind) return ace:Create(lib.__MediaWidgetType(kind)) end

--- Every value in the pull-out, in row order, and each row by its value.
local function rows(dd)
  local order, byValue = {}, {}
  for i, item in ipairs(dd.pullout.items) do
    order[i] = item.userdata.value
    byValue[item.userdata.value] = item
  end
  return order, byValue
end

-- ── the types ────────────────────────────────────────────────────────────────────────────────

test("media: lib.__MediaWidgetType maps a kind, its LSM30_* and its own type name to one type", function()
  local _, _, lib = env()
  for name, want in pairs({
    font = "Ka0sMedia_Font", LSM30_Font = "Ka0sMedia_Font", Ka0sMedia_Font = "Ka0sMedia_Font",
    statusbar = "Ka0sMedia_Statusbar", LSM30_Statusbar = "Ka0sMedia_Statusbar",
    border = "Ka0sMedia_Border", LSM30_Border = "Ka0sMedia_Border",
    background = "Ka0sMedia_Background", LSM30_Background = "Ka0sMedia_Background",
    sound = "Ka0sMedia_Sound", LSM30_Sound = "Ka0sMedia_Sound",
  }) do
    assertEqual(lib.__MediaWidgetType(name), want, name)
  end
  assertNil(lib.__MediaWidgetType("SomeHostDropdown"), "a type that is no media kind stays the caller's")
end)

test("media: no stock Dropdown registered, so no picker, and the caller draws a plain Dropdown", function()
  local _, _, lib, ace = env({ noBase = true })
  assertNil(lib.__MediaWidgetType("font"))
  assertNil(ace:GetWidgetVersion("Ka0sMedia_Font"), "nothing registered half-way")
end)

test("media: registering twice leaves the constructors alone and touches no other type", function()
  local _, _, lib, ace = env()
  lib.__MediaWidgetType("font")
  local ctor, dropdown = ace.WidgetRegistry.Ka0sMedia_Font, ace.WidgetRegistry.Dropdown
  local count = 0
  local register = ace.RegisterWidgetType
  ace.RegisterWidgetType = function(self, ...)
    count = count + 1
    return register(self, ...)
  end
  lib.__MediaWidgetType("font")
  ace.RegisterWidgetType = register
  assertEqual(count, 0, "the second ask registers nothing")
  assertEqual(ace.WidgetRegistry.Ka0sMedia_Font, ctor)
  assertEqual(ace.WidgetRegistry.Dropdown, dropdown, "the stock type is read, never replaced")
end)

test("media: the file is its own file of the major, paired on the shell's minor", function()
  local _, _, lib = env()
  assertEqual(lib.MODULES.OptionsMedia, lib.__mediaMinor)
  assertEqual(lib.__mediaShellMinor, lib.MINOR)
end)

-- ── the list ─────────────────────────────────────────────────────────────────────────────────

test("media: the order puts a leading row first and its text is the list's", function()
  local _, _, lib, ace = env()
  local dd = picker(lib, ace, "font")
  dd:SetList({ ["@skin"] = "Skin's default (Ka0s Expressway)", ["Ka0s Fira Sans"] = "Ka0s Fira Sans" },
    { "@skin", "Ka0s Fira Sans" })
  local order, byValue = rows(dd)
  assertEqual(order[1], "@skin")
  assertEqual(order[2], "Ka0s Fira Sans")
  assertEqual(byValue["@skin"].text:GetText(), "Skin's default (Ka0s Expressway)")
  assertEqual(byValue["@skin"].type, "Ka0sMedia_Item", "the rows are ours, not Dropdown-Item-Toggle")
end)

test("media: a list with no order sorts by its text, and no list means every key of the kind", function()
  local _, _, lib, ace = env()
  local dd = picker(lib, ace, "statusbar")
  dd:SetList({ b = "alpha", a = "Zulu" })
  local order = rows(dd)
  assertEqual(order[1], "b")
  assertEqual(order[2], "a")
  dd:SetList()
  order = rows(dd)
  assertEqual(#order, 2)
  assertEqual(order[1], "Flat")
  assertEqual(order[2], "Smooth")
end)

test("media: a stored key the list lacks still shows, and the host's table is not written", function()
  local _, _, lib, ace = env()
  local dd = picker(lib, ace, "font")
  local list = { ["Ka0s Fira Sans"] = "Ka0s Fira Sans" }
  dd:SetList(list, { "Ka0s Fira Sans" })
  dd:SetValue("Gone Face")
  assertEqual(dd.text:GetText(), "Gone Face")
  local order = rows(dd)
  assertEqual(order[2], "Gone Face", "and it has a row to come back to")
  assertNil(list["Gone Face"], "the host's list is the host's")
  dd:SetList(list, { "Ka0s Fira Sans" })
  dd:SetValue("Gone Face")
  assertEqual(#rows(dd), 2, "a rebuilt list gets it back from SetValue, the order every caller uses")
end)

test("media: a value leaving the list leaves no row behind", function()
  -- red under: SetList adding back the widget's old value, a row with nothing behind it that stays
  -- in the pull-out after SetValue moved on (a Reset font on an unloaded face).
  local _, _, lib, ace = env()
  local dd = picker(lib, ace, "font")
  dd:SetList({ Lead = "Skin's default", Gone = "Gone (not loaded)" }, { "Lead", "Gone" })
  dd:SetValue("Gone")
  dd:SetList({ Lead = "Skin's default" }, { "Lead" })
  dd:SetValue("Lead")
  local order = rows(dd)
  assertEqual(#order, 1, "only the new list's rows")
  assertEqual(order[1], "Lead")
  assertNil(dd.list["Gone"], "and nothing to pick")
end)

-- ── previews ─────────────────────────────────────────────────────────────────────────────────

test("media: the closed row and an opened row draw in the entry's own face", function()
  local _, _, lib, ace = env()
  local dd = picker(lib, ace, "font")
  dd:SetList({ ["Ka0s Fira Sans"] = "Ka0s Fira Sans", ["Ka0s Expressway"] = "Ka0s Expressway" },
    { "Ka0s Expressway", "Ka0s Fira Sans" })
  dd:SetValue("Ka0s Fira Sans")
  assertEqual(font(dd.text), FACE["Ka0s Fira Sans"])
  local _, byValue = rows(dd)
  assertEqual(font(byValue["Ka0s Expressway"].text), BASE_FONT, "rows wait for the open")
  dd.pullout:Open()
  assertEqual(font(byValue["Ka0s Expressway"].text), FACE["Ka0s Expressway"])
  assertEqual(font(byValue["Ka0s Fira Sans"].text), FACE["Ka0s Fira Sans"])
end)

test("media: a leading row previews the key it stands for, closed and open", function()
  local _, _, lib, ace = env()
  local dd = picker(lib, ace, "font")
  dd:SetPreviews({ ["@skin"] = "Ka0s Expressway" })
  dd:SetList({ ["@skin"] = "Skin's default (Ka0s Expressway)" }, { "@skin" })
  dd:SetValue("@skin")
  assertEqual(font(dd.text), FACE["Ka0s Expressway"])
  dd.pullout:Open()
  assertEqual(font(dd.pullout.items[1].text), FACE["Ka0s Expressway"])
end)

test("media: a key LSM cannot resolve keeps the plain face and raises nothing", function()
  local _, _, lib, ace = env()
  local dd = picker(lib, ace, "font")
  dd:SetList({ ["Ka0s Fira Sans"] = "Ka0s Fira Sans" }, { "Ka0s Fira Sans" })
  dd:SetValue("Ka0s Fira Sans")
  dd:SetValue("Gone Face")
  assertEqual(font(dd.text), BASE_FONT, "back off the last entry's face")
  dd.pullout:Open()
end)

test("media: statusbar, border and background entries draw a swatch of that art", function()
  local m, _, lib, ace = env()
  local dd = picker(lib, ace, "statusbar")
  dd:SetList({ Smooth = "Smooth" }, { "Smooth" })
  dd:SetValue("Smooth")
  local s = dd.__media.swatch
  assertTrue(s:IsShown())
  assertEqual(m.__paint(s.bar).texture, "Tex\\Smooth")
  dd.pullout:Open()
  local row = dd.pullout.items[1].__media.swatch
  assertEqual(m.__paint(row.bar).texture, "Tex\\Smooth", "the row's own swatch")

  local edge = picker(lib, ace, "border")
  edge:SetList({ Glass = "Glass" }, { "Glass" })
  edge:SetValue("Glass")
  assertEqual(edge.__media.swatch:GetBackdrop().edgeFile, "Tex\\GlassEdge")

  local fill = picker(lib, ace, "background")
  fill:SetList({ Solid = "Solid" }, { "Solid" })
  fill:SetValue("Solid")
  assertEqual(fill.__media.swatch:GetBackdrop().bgFile, "Tex\\Solid")
  fill:SetValue("Gone")
  assertFalse(fill.__media.swatch:IsShown(), "a missing key shows no stale art")
end)

test("media: a sound row's play button plays that sound, and a click on it is not a pick", function()
  local m, _, lib, ace = env()
  local played = {}
  m.PlaySoundFile = function(path, channel) played[#played + 1] = { path, channel } end
  local dd = picker(lib, ace, "sound")
  local chose = 0
  dd:SetCallback("OnValueChanged", function() chose = chose + 1 end)
  dd:SetList({ Ding = "Ding" }, { "Ding" })
  dd:SetValue("Ding")
  dd.pullout:Open()
  local btn = dd.pullout.items[1].__media.play
  assertTrue(btn:IsShown())
  btn:GetScript("OnClick")(btn)
  assertEqual(played[1][1], "Sound\\Ding.ogg")
  assertEqual(played[1][2], "Master")
  assertEqual(chose, 0)
end)

-- ── faces load first ─────────────────────────────────────────────────────────────────────────

test("media: faces are preloaded before the rows draw, and a load dresses them again next frame", function()
  local m, _, lib, ace = env()
  local calls, loaded = 0, 2
  lib.__PreloadFonts = function()
    calls = calls + 1
    local n = loaded
    loaded = 0
    return n
  end
  local dd = picker(lib, ace, "font")
  assertEqual(calls, 1, "on acquiring: the closed row draws a face too")
  dd:SetList({ ["Ka0s Fira Sans"] = "Ka0s Fira Sans" }, { "Ka0s Fira Sans" })
  m.__timers = m.__timers or {}
  loaded = 1
  dd.pullout:Open()
  assertEqual(calls, 2, "on opening")
  local item = dd.pullout.items[1]
  item.text:SetFont(BASE_FONT, 10, "")          -- what the client's blank first draw stands for
  for _, t in ipairs(m.__timers) do if t.fn then t.fn() end end
  assertEqual(font(item.text), FACE["Ka0s Fira Sans"], "dressed again on the next frame")
end)

test("media: a picker drawn in the tick that preloaded its face dresses again next frame", function()
  -- red under: the panel's OnShow preloading first, so this picker's call loads nothing and the closed
  -- row's first draw of that face is never repeated. The text is set again too, since that is what
  -- draws blank.
  local m, _, lib, ace = env()
  lib.__PreloadFonts = function() return 0 end
  m.__timers = {}
  local dd = picker(lib, ace, "font")
  dd:SetList({ ["Ka0s Fira Sans"] = "Ka0s Fira Sans" }, { "Ka0s Fira Sans" })
  dd:SetValue("Ka0s Fira Sans")
  local sets, set = 0, dd.text.SetText
  dd.text.SetText = function(fs, text)
    sets = sets + 1
    return set(fs, text)
  end
  dd.text:SetFont(BASE_FONT, 10, "")
  for _, t in ipairs(m.__timers) do if t.fn then t.fn() end end
  dd.text.SetText = set
  assertEqual(font(dd.text), FACE["Ka0s Fira Sans"], "the face again")
  assertTrue(sets > 0, "and the text")
  assertEqual(dd.text:GetText(), "Ka0s Fira Sans", "the same text")
end)

test("media: a swatch picker on an acquire asks for no next frame", function()
  local m, _, lib, ace = env()
  m.__timers = {}
  picker(lib, ace, "statusbar")
  assertEqual(#m.__timers, 0, "only a face can draw blank")
end)

test("media: a picker released before that next frame does nothing", function()
  local m, _, lib, ace = env()
  lib.__PreloadFonts = function() return 1 end
  local dd = picker(lib, ace, "font")
  dd:SetList({ ["Ka0s Fira Sans"] = "Ka0s Fira Sans" }, { "Ka0s Fira Sans" })
  dd:SetValue("Ka0s Fira Sans")
  ace:Release(dd)
  for _, t in ipairs(m.__timers or {}) do if t.fn then t.fn() end end
  assertEqual(font(dd.text), BASE_FONT)
end)

-- ── the pool ─────────────────────────────────────────────────────────────────────────────────

test("media: release puts the face, the previews and the rows back, into this type's own pool", function()
  local _, _, lib, ace = env()
  local dd = picker(lib, ace, "font")
  dd:SetPreviews({ ["@skin"] = "Ka0s Expressway" })
  dd:SetList({ ["@skin"] = "x", ["Ka0s Fira Sans"] = "Ka0s Fira Sans" }, { "@skin", "Ka0s Fira Sans" })
  dd:SetValue("@skin")
  dd.pullout:Open()
  local item = dd.pullout.items[1]
  local po = dd.pullout
  ace:Release(dd)
  assertEqual(font(dd.text), BASE_FONT, "the closed row")
  assertEqual(font(item.text), BASE_FONT, "the row")
  assertTrue(#ace.__pools.Ka0sMedia_Item >= 2, "rows into their own pool")
  assertEqual(ace.__pools.Ka0sMedia_Font[1], dd)
  assertNil(ace.__pools["Dropdown-Item-Toggle"], "never the stock one")
  assertEqual(po.events.OnOpen ~= nil, true, "the pull-out's callback is the release's to wipe")

  local again = ace:Create("Ka0sMedia_Font")
  assertEqual(again, dd, "the pool hands it back")
  assertNil(again.__media.previews)
  again:SetList({ ["@skin"] = "y" }, { "@skin" })
  again:SetValue("@skin")
  assertEqual(font(again.text), BASE_FONT, "a stale preview does not survive the pool")
end)

test("media: a pooled row that made room for a swatch gets its text width back", function()
  -- red under: the font picker reusing a row whose text still stops at a hidden swatch.
  local _, _, lib, ace = env()
  for _, kind in ipairs({ "statusbar", "sound" }) do
    local dd = picker(lib, ace, kind)
    local key = kind == "sound" and "Ding" or "Smooth"
    dd:SetList({ [key] = key }, { key })
    dd.pullout:Open()
    local item = dd.pullout.items[1]
    dd:SetList({}, {})
    local point, anchor, rel, x = item.text:GetPoint(#item.text.__points)
    assertEqual(point, "BOTTOMRIGHT", kind)
    assertEqual(anchor, item.frame, kind .. ": on the row again")
    assertEqual(rel, "BOTTOMRIGHT", kind)
    assertEqual(x, -8, kind .. ": Dropdown-Item-Toggle's inset")
  end
end)

test("media: a released swatch and play button hide, and a stock Dropdown stays stock", function()
  local _, _, lib, ace = env()
  local stock = ace:Create("Dropdown")
  local dd = picker(lib, ace, "statusbar")
  dd:SetList({ Smooth = "Smooth" }, { "Smooth" })
  dd:SetValue("Smooth")
  ace:Release(dd)
  assertFalse(dd.__media.swatch:IsShown())
  assertEqual(stock.type, "Dropdown")
  assertNil(rawget(stock, "__media"))
end)

test("media: disabling dims the swatch", function()
  local _, _, lib, ace = env()
  local dd = picker(lib, ace, "statusbar")
  dd:SetDisabled(true)
  assertTrue(dd.__media.swatch:GetAlpha() < 1)
  dd:SetDisabled(false)
  assertEqual(dd.__media.swatch:GetAlpha(), 1)
end)

-- ── the skin ─────────────────────────────────────────────────────────────────────────────────

test("media: the skin paints a picker as a Dropdown and the preview survives its font", function()
  local _, Skin, lib, ace = env()
  Skin:RegisterOwner(A.OWNER, { label = "Loot History" })
  local O = A.instance(lib, A.OWNER)
  local dd = O.AceGUI:Create(lib.__MediaWidgetType("font"))
  assertEqual(Skin.__aceAlias.Ka0sMedia_Font, "Dropdown")
  assertTrue(Skin.__ace[dd] ~= nil and Skin.__ace[dd].owner == A.OWNER, "painted for the owner")
  dd:SetList({ ["Ka0s Fira Sans"] = "Ka0s Fira Sans" }, { "Ka0s Fira Sans" })
  dd:SetValue("Ka0s Fira Sans")
  assertEqual(font(dd.text), FACE["Ka0s Fira Sans"])
  dd:SetDisabled(true)                        -- the durability hook repaints the row's font
  assertEqual(font(dd.text), FACE["Ka0s Fira Sans"], "the repaint does not take the preview off")
  dd:SetDisabled(false)
  ace:Release(dd)
  assertEqual(font(dd.text), BASE_FONT, "stock again on release")
end)

test("media: an open pull-out wears the menu tokens", function()
  local _, Skin, lib, ace = env()
  Skin:RegisterOwner(A.OWNER, { label = "Loot History" })
  local O = A.instance(lib, A.OWNER)
  local dd = O.AceGUI:Create(lib.__MediaWidgetType("statusbar"))
  dd:SetList({ Smooth = "Smooth" }, { "Smooth" })
  dd.pullout:Open()
  assertEqual(Skin.__ace[dd.pullout].owner, A.OWNER)
  ace:Release(dd)
end)

-- ── no LibSharedMedia ────────────────────────────────────────────────────────────────────────

test("media: with no LibSharedMedia the picker still lists, picks and shows its text", function()
  local _, _, lib, ace = env({ noLsm = true })
  local dd = picker(lib, ace, "font")
  dd:SetList({ ["@skin"] = "Skin's default (X)", Stored = "Stored" }, { "@skin", "Stored" })
  dd:SetPreviews({ ["@skin"] = "X" })
  dd:SetValue("@skin")
  assertEqual(dd.text:GetText(), "Skin's default (X)")
  assertEqual(font(dd.text), BASE_FONT)
  dd.pullout:Open()
  dd:SetList()
  dd:SetValue("@skin")
  assertEqual(#rows(dd), 1, "no list and no LSM offers nothing but the value it holds")
end)

-- ── the two callers ──────────────────────────────────────────────────────────────────────────

local function ctxOn(O)
  local rec = { path = "face", label = "Face", type = "string", dialogControl = "LSM30_Font",
                values = function() return { ["Ka0s Fira Sans"] = "Ka0s Fira Sans" } end }
  local ctx = { refreshers = {}, scroll = O.AceGUI:Create("ScrollFrame") }
  return ctx, rec
end

test("media: an unregistered LSM30_* row is drawn by the matching picker", function()
  local _, _, lib = env()
  local O = A.instance(lib, nil)
  local ctx, rec = ctxOn(O)
  local dd = O.RenderField(ctx, rec, O.AceGUI:Create("SimpleGroup"), 0.5)
  assertEqual(dd.type, "Ka0sMedia_Font")
end)

test("media: a registered LSM30_* row keeps it", function()
  local m, _, lib, ace = env()
  ace:RegisterWidgetType("LSM30_Font", function()
    local w = stockDropdown(m, ace)
    w.type = "LSM30_Font"
    return w
  end, 13)
  local O = A.instance(lib, nil)
  local ctx, rec = ctxOn(O)
  local dd = O.RenderField(ctx, rec, O.AceGUI:Create("SimpleGroup"), 0.5)
  assertEqual(dd.type, "LSM30_Font")
end)

test("media: with no picker to draw, an LSM30_* row is the stock Dropdown", function()
  local _, _, lib = env({ noBase = true })
  local O = A.instance(lib, nil)
  local ctx, rec = ctxOn(O)
  local dd = O.RenderField(ctx, rec, O.AceGUI:Create("SimpleGroup"), 0.5)
  assertEqual(dd.type, "Dropdown")
end)

--- A Skin tab for a registered owner: its view, the owner's store and the skin's own body face.
local function skinTab(Skin, lib)
  local store = { source = "ka0s", skin = "ka0s" }
  local read = function() return { source = store.source, skin = store.skin, media = store.media } end
  local write = function(_, _, _, media)
    if media ~= nil then store.media = media end
  end
  Skin:RegisterOwner(A.OWNER, { label = "Loot History", get = read, set = write })
  local O = A.instance(lib, A.OWNER)
  local ctx = O.CreatePanel("MediaTab", "Media tab", { pageKey = "general" })
  local view = O.AppearanceRows(ctx, { get = read, set = write })
  return view, store, Skin:ResolveSkin("ka0s")["font.body"]
end

test("media: the Skin tab's font and texture rows are pickers led by a previewing row", function()
  local _, Skin, lib = env()
  local view, _, own = skinTab(Skin, lib)
  local dd = view.media.font
  assertEqual(dd.type, "Ka0sMedia_Font")
  assertEqual(view.media.texture.type, "Ka0sMedia_Statusbar")
  assertEqual(dd.pullout.items[1].userdata.value, "@skin", "the skin's entry leads")
  assertEqual(dd.__media.previews["@skin"], own, "and previews the face it stands for")
  assertEqual(dd.value, "@skin")
  assertEqual(font(dd.text), FACE[own], "closed too")
end)

test("media: a Skin tab pick writes through the same seam and keeps the row a picker", function()
  local _, Skin, lib = env()
  local view, store = skinTab(Skin, lib)
  local dd = view.media.font
  dd:__fire("OnValueChanged", "Ka0s Fira Sans")
  assertEqual(store.media.font, "Ka0s Fira Sans")
  assertEqual(dd.value, "Ka0s Fira Sans")
  assertEqual(font(dd.text), FACE["Ka0s Fira Sans"])
end)

test("media: without a picker the Skin tab's rows are stock Dropdowns", function()
  local _, Skin, lib = env({ noBase = true })
  local view = skinTab(Skin, lib)
  assertEqual(view.media.font.type, "Dropdown")
  assertNil(view.media.font.SetPreviews)
end)
