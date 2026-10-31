-- tests/test_options_media.lua -- LibKa0s-Options-1.0's OptionsMedia.lua (minor 1): the Ka0sMedia_*
-- picker types, their rows, and the two callers that reach for them (the Skin tab, and a row naming
-- an LSM30_* type or a Ka0sMedia_* one).
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

local Fixture = dofile("tests/fixture_media.lua")
local env, stockDropdown, FACE, BASE_FONT = Fixture.env, Fixture.stockDropdown, Fixture.FACE, Fixture.BASE_FONT

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

-- ── the closed row ───────────────────────────────────────────────────────────────────────────

test("media: a picker never closes on its first entry: no value is blank, a value is its key", function()
  -- The owner's Skin Tester sample read "2002", the first font key. Red under: any default to the
  -- list's first row. A picker shows list[value] and nothing else.
  local _, _, lib, ace = env()
  local dd = picker(lib, ace, "font")
  dd:SetList()
  dd:SetValue(nil)
  assertEqual(dd.text:GetText(), "", "nothing selected reads blank")
  assertNil(dd.value)
  dd:SetValue("Ka0s Prototype")
  assertEqual(dd.text:GetText(), "Ka0s Prototype")
  assertEqual(rows(dd)[1], "Ka0s Expressway", "and that was not the first row")
end)

test("media: border and sound rows sit on the stock bar, level with the page's other controls", function()
  -- LSM30_Border's patch existed because that widget pinned a 42px tile left of its bar. A picker
  -- has none: the frame is the stock Dropdown's; the swatch or play button is made on the bar, and
  -- the text moves over inside it (closedExtra).
  local _, _, lib, ace = env()
  for _, kind in ipairs({ "statusbar", "border", "background", "sound" }) do
    local dd = picker(lib, ace, kind)
    assertNil(rawget(dd.frame, "displayButton"), kind .. ": no preview tile beside the bar")
    local m = dd.__media
    local extra = kind == "sound" and m.play or m.swatch
    local tpoint, tanchor = dd.text:GetPoint(#dd.text.__points)
    assertEqual(tpoint, "LEFT", kind)
    assertEqual(tanchor, extra, kind .. ": the text starts after it")
  end
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

test("media: with no SharedMediaWidgets an LSM30_* row of every kind draws the matching picker", function()
  local _, _, lib = env()
  local O = A.instance(lib, nil)
  for asked, want in pairs({
    LSM30_Font = "Ka0sMedia_Font", LSM30_Statusbar = "Ka0sMedia_Statusbar", LSM30_Border = "Ka0sMedia_Border",
    LSM30_Background = "Ka0sMedia_Background", LSM30_Sound = "Ka0sMedia_Sound",
  }) do
    local ctx, rec = ctxOn(O)
    rec.dialogControl = asked
    assertEqual(O.RenderField(ctx, rec, O.AceGUI:Create("SimpleGroup"), 0.5).type, want, asked)
  end
end)

test("media: a registered LSM30_* type does not win: the row is still our picker", function()
  -- red under: asking GetWidgetVersion first, which is what let a host's SharedMediaWidgets decide
  -- what the row drew (the owner's ruling of 2026-11-01: Ka0sMedia_* is the only media picker).
  local m, _, lib, ace = env()
  ace:RegisterWidgetType("LSM30_Font", function()
    local w = stockDropdown(m, ace)
    w.type = "LSM30_Font"
    return w
  end, 13)
  local O = A.instance(lib, nil)
  local ctx, rec = ctxOn(O)
  local dd = O.RenderField(ctx, rec, O.AceGUI:Create("SimpleGroup"), 0.5)
  assertEqual(dd.type, "Ka0sMedia_Font")
end)

test("media: a row naming Ka0sMedia_* draws it, a host's own registered type is left alone", function()
  local m, _, lib, ace = env()
  ace:RegisterWidgetType("HostDropdown", function()
    local w = stockDropdown(m, ace)
    w.type = "HostDropdown"
    return w
  end, 1)
  local O = A.instance(lib, nil)
  local ctx, rec = ctxOn(O)
  rec.dialogControl = "Ka0sMedia_Font"
  assertEqual(O.RenderField(ctx, rec, O.AceGUI:Create("SimpleGroup"), 0.5).type, "Ka0sMedia_Font")
  rec.dialogControl = "HostDropdown"
  assertEqual(O.RenderField(ctx, rec, O.AceGUI:Create("SimpleGroup"), 0.5).type, "HostDropdown")
end)

test("media: with no picker to draw, a registered LSM30_* row keeps its type", function()
  local m, _, lib, ace = env({ noBase = true })
  ace:RegisterWidgetType("LSM30_Font", function()
    local w = m.__makeAceGUIWidget("LSM30_Font")
    w.SetList, w.SetValue = function() end, function() end
    return w
  end, 13)
  local O = A.instance(lib, nil)
  local ctx, rec = ctxOn(O)
  assertEqual(O.RenderField(ctx, rec, O.AceGUI:Create("SimpleGroup"), 0.5).type, "LSM30_Font")
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
