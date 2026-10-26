-- tests/test_skin_paint_controls.lua — LibKa0s-Skin-1.0's paint primitives, part three: the
-- controls (SkinPaintControls.lua). The shared rules and the window family are
-- tests/test_skin_paint.lua's; the bench is tests/fixture_skin_paint.lua.
--
-- The Ka0s Default cases pin a control's trace against the library code it stands for: Widgets'
-- dropdown and search box (run for real on an identical frame and filtered to the paint calls),
-- Core's close button, OptionsNav's entry, OptionsDrawer's header, OptionsScroll's thumb and
-- DebugLog's console bar, each cited by file.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local F = dofile("tests/fixture_skin_paint.lua")
local Loader = dofile("tests/_kit/loader.lua")

local OWNER = "LootHistory"

local function survey(m, obj) return m.__paint(obj) end

local PAINT = { SetBackdrop = true, SetBackdropColor = true, SetBackdropBorderColor = true,
                SetVertexColor = true, SetTextColor = true, SetColorTexture = true }

local function backdropButton(m)
  local b = m.CreateFrame("Button", nil, m.UIParent, "BackdropTemplate")
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  return b
end

--- A stock template button: its normal texture answers GetNormalTexture.
local function stockButton(m)
  local b = m.CreateFrame("Button", nil, m.UIParent)
  rawset(b, "SetBackdrop", nil)   -- the client's panel button wears no BackdropTemplate
  local normal = b:CreateTexture()
  rawset(b, "GetNormalTexture", function() return normal end)
  return b, normal
end

local function withWidgets(m)
  Loader.load("LibKa0s/Widgets.lua", nil, m)
  return m.LibStub("LibKa0s-Widgets-1.0")
end

-- ── buttons ──────────────────────────────────────────────────────────────────────────────────

test("skin controls: Button on Ka0s Default is LootHistory's flat button's paint", function()
  -- modules/BrowserFilterBar.lua makeBarButton: the WHITE8X8 table with insets, .1/.1/.12/.9, .24/.24/.27/.9
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local tr = F.tracer(m)
  local b = backdropButton(m)
  tr.watch(b); tr.watch(b.text)
  tr.start(); S.Button(b); tr.stop(); tr.restore()
  assertEqual(F.only(tr, { SetBackdrop = true, SetBackdropColor = true, SetBackdropBorderColor = true }),
    table.concat({
      '#1:SetBackdrop({bgFile="Interface\\\\Buttons\\\\WHITE8X8",edgeFile="Interface\\\\Buttons\\\\WHITE8X8",'
        .. 'edgeSize=1,insets={bottom=1,left=1,right=1,top=1}})',
      "#1:SetBackdropColor(0.100,0.100,0.120,0.900)",
      "#1:SetBackdropBorderColor(0.240,0.240,0.270,0.900)",
    }, "\n"))
  assertEqual(F.rgba(survey(m, b.text).textColor), "1,1,1,1", "the label in btn.text")
  b:__fire("OnEnter")
  assertEqual(F.rgba(survey(m, b.text).textColor), "1,0.820,0,1", "gold under the pointer, as today")
  b:__fire("OnLeave")
  assertEqual(F.rgba(survey(m, b.text).textColor), "1,1,1,1")
end)

test("skin controls: Button repaints live, primary reads btnPrimary, and the icon is tinted", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local b = backdropButton(m)
  b.icon = b:CreateTexture()
  S.Button(b)
  assertEqual(F.rgba(survey(m, b.icon).vertex), "0.850,0.850,0.850,1", "btn.icon")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(F.rgba(survey(m, b).backdropColor), F.tok(Skin, "obsidian", "btn.bg"), "repainted")
  b:__fire("OnEnter")
  assertEqual(F.rgba(survey(m, b.text).textColor), F.tok(Skin, "obsidian", "btn.hover"), "the hook reads the new skin")
  local p = backdropButton(m)
  S.Button(p, { primary = true })
  assertEqual(F.rgba(survey(m, p).backdropColor), F.tok(Skin, "obsidian", "btnPrimary.bg"))
  local hooks = 0
  local q = backdropButton(m)
  local prev = q.HookScript
  rawset(q, "HookScript", function(self, ...) hooks = hooks + 1; return prev(self, ...) end)
  S.Button(q); S.Button(q)
  assertEqual(hooks, 4, "OnEnter, OnLeave, OnEnable and OnDisable are hooked once each, however often it is painted")
end)

test("skin controls: a stock button is faded and boxed under every skin, Ka0s Default too", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local b, normal = stockButton(m)
  S.Button(b)
  assertEqual(normal:GetAlpha(), 0, "Ka0s Default fades the client's art (SkinPaint minor 6)")
  assertEqual(F.rgba(survey(m, F.region(Skin, b, "fill")).color), F.tok(Skin, "ka0s", "btn.bg"), "and boxes it")
  Skin:SetChoice(OWNER, "ka0s", "ember")
  assertEqual(normal:GetAlpha(), 0, "faded")
  local g = survey(m, F.region(Skin, b, "fill")).gradient
  assertEqual(F.rgba({ g.max.r, g.max.g, g.max.b, g.max.a }), F.tok(Skin, "ember", "btn.bgTop"),
    "a fill region, Ember's gradient")
  assertEqual(F.region(Skin, b, "edgeTop"):GetParent(), F.region(Skin, b, "holder"), "its edge on the holder")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertEqual(normal:GetAlpha(), 0, "still faded")
  assertEqual(F.rgba(survey(m, F.region(Skin, b, "fill")).color), F.tok(Skin, "ka0s", "btn.bg"), "in Ka0s Default's fill")
end)

test("skin controls: Button with keepKeys paints only the label", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "contrast")
  local b = backdropButton(m)
  S.Button(b, true)
  assertNil(survey(m, b).backdrop, "no box")
  assertEqual(F.rgba(survey(m, b.text).textColor), F.tok(Skin, "contrast", "btn.text"))
end)

test("skin controls: WhiteButtonLabel and StateButtonLabel", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "azeroth")
  local b = backdropButton(m)
  S.WhiteButtonLabel(b)
  assertEqual(F.rgba(survey(m, b.text).textColor), F.tok(Skin, "azeroth", "btn.text"))
  S.StateButtonLabel(b, true)
  assertEqual(F.rgba(survey(m, b.text).textColor), F.tok(Skin, "azeroth", "text.accent"))
  S.StateButtonLabel(b, false)
  assertEqual(F.rgba(survey(m, b.text).textColor), F.tok(Skin, "azeroth", "text.muted"))
end)

-- ── inputs ───────────────────────────────────────────────────────────────────────────────────

test("skin controls: EditBox on Ka0s Default paints the search box's backdrop, call for call", function()
  local m, Skin = F.env()
  local W = withWidgets(m)
  local S = F.owner(Skin, OWNER)
  local function run(make)
    local tr = F.tracer(m)
    tr.start()
    local box = make()
    tr.stop(); tr.restore()
    local lines = {}
    for _, line in ipairs(tr.lines) do
      local id, method = line:match("^#(%d+):([%w]+)%(")
      if id == "1" and (method == "SetBackdrop" or method == "SetBackdropColor"
        or method == "SetBackdropBorderColor") then lines[#lines + 1] = line end
    end
    return table.concat(lines, "\n"), box
  end
  local want = run(function() return W.SearchBox(m.UIParent, 100) end)
  local got, box = run(function()
    local eb = m.CreateFrame("EditBox", nil, m.UIParent, "BackdropTemplate")
    S.EditBox(eb)
    return eb
  end)
  assertTrue(want ~= "", "the search box paints a backdrop")
  assertEqual(got, want)
  box:__fire("OnEditFocusGained")
  assertEqual(F.rgba(survey(m, box).backdropBorderColor), "1,0.820,0,0.900", "input.focus while it has the keys")
  box:__fire("OnEditFocusLost")
  assertEqual(F.rgba(survey(m, box).backdropBorderColor), "0.240,0.240,0.270,0.900")
end)

test("skin controls: EditBox fades a template's pieces and colors its text and hint in a skin", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "contrast")
  Skin:RegisterSkin({ key = "ink", tokens = { ["input.text"] = { 0.1, 0.1, 0.1, 1 },
                                              ["input.placeholder"] = { 0.4, 0.4, 0.4, 1 } } })
  local eb = m.CreateFrame("EditBox", nil, m.UIParent)
  eb.Left = eb:CreateTexture()
  eb.hint = eb:CreateFontString()
  local colors = {}
  rawset(eb, "SetTextColor", function(_, r, g, b) colors[#colors + 1] = F.rgba({ r, g, b }) end)
  rawset(eb, "GetTextColor", function() return 1, 1, 1 end)
  S.EditBox(eb)
  assertEqual(eb.Left:GetAlpha(), 0, "Contrast fades the template's piece")
  Skin:SetChoice(OWNER, "ka0s", "ink")
  assertEqual(colors[#colors], "0.100,0.100,0.100,1", "input.text")
  assertEqual(F.rgba(survey(m, eb.hint).textColor), "0.400,0.400,0.400,1", "input.placeholder")
  Skin:SetChoice(OWNER, "ka0s", "contrast")
  assertEqual(colors[#colors], "1,1,1,1", "a nil input.text puts the prior color back")
end)

test("skin controls: leaving a skin font puts an EditBox's face back by path, never its anonymous font object", function()
  -- The client's EditBox answers GetFontObject with an anonymous font object, not the named one it
  -- was given (owner probe, 2026-10-26: `e:SetFontObject(GameFontHighlightSmall)` then
  -- `e:GetFontObject()` is an unnamed Font, `~= GameFontHighlightSmall`). Handing that object back
  -- through SetFontObject overflowed the client's stack: Forever -> Midnight crashed the game.
  -- Every shipped skin sets a body face since SkinDefs minor 8, so the way back by path is reached
  -- here through a skin registered with none (`false`), as a face the client cannot resolve would.
  local m, Skin = F.env({ lsm = { ["font:Ka0s Atkinson"] = "Fonts\\Atkinson.ttf" } })
  Skin:RegisterSkin({ key = "bare", tokens = { ["font.body"] = false } })
  local S = F.owner(Skin, OWNER)
  local eb = m.CreateFrame("EditBox", nil, m.UIParent)
  local anon = { GetName = function() return nil end }
  local objects, faces, current = {}, {}, anon
  rawset(eb, "SetFontObject", function(_, obj) objects[#objects + 1] = obj; current = obj end)
  rawset(eb, "GetFontObject", function() return current end)
  rawset(eb, "SetFont", function(_, path, size, flags) faces[#faces + 1] = { path, size, flags } end)
  rawset(eb, "GetFont", function() return "Fonts\\FRIZQT__.TTF", 10, "" end)
  local shadows = {}
  rawset(eb, "GetShadowOffset", function() return 0, 0 end)
  rawset(eb, "GetShadowColor", function() return 0, 0, 0, 0 end)
  rawset(eb, "SetShadowOffset", function(_, x, y) shadows[#shadows + 1] = x .. "," .. y end)
  rawset(eb, "SetShadowColor", function(_, r, g, b, a) shadows[#shadows + 1] = r .. "," .. g .. "," .. b .. "," .. a end)
  S.EditBox(eb)
  Skin:SetChoice(OWNER, "ka0s", "forever")
  assertEqual(#objects, 1, "Forever gives the box the owner's body font object")
  Skin:SetChoice(OWNER, "ka0s", "bare")
  for _, obj in ipairs(objects) do assertFalse(obj == anon, "the anonymous font object is never handed back") end
  assertEqual(#faces, 1, "a skin with no body face: the stock face goes back by path")
  assertEqual(table.concat(faces[1], "|"), "Fonts\\FRIZQT__.TTF|10|")
  assertEqual(table.concat(shadows, " "), "0,0 0,0,0,0", "and its own shadow, which SetFont leaves as the skin's")
  -- A record an older copy of the file wrote (an anonymous object saved) is checked again on restore.
  Skin:SetChoice(OWNER, "ka0s", "forever")
  local rec = Skin.painted[eb]
  rec.regions.saved.font[eb].obj = anon
  local before = #objects
  Skin:SetChoice(OWNER, "ka0s", "bare")
  assertEqual(#objects, before, "an anonymous object recorded by an older copy is never handed back")
end)

test("skin controls: Dropdown on Ka0s Default is Widgets' dropdown, call for call", function()
  local m, Skin = F.env()
  local W = withWidgets(m)
  local S = F.owner(Skin, OWNER)
  local function paintLines(tr, dd)
    local keep = { [tr.ids[dd]] = true, [tr.ids[dd.arrow]] = true }
    local out = {}
    for _, line in ipairs(tr.lines) do
      local id, method = line:match("^#(%d+):([%w]+)%(")
      if id and keep[tonumber(id)] and PAINT[method] then out[#out + 1] = (line:gsub("^#%d+", "")) end
    end
    return table.concat(out, "\n")
  end
  local tr1 = F.tracer(m); tr1.start()
  local real = W.Dropdown(m.UIParent, 120)
  tr1.stop(); tr1.restore()
  local tr2 = F.tracer(m)
  local dd = m.CreateFrame("Button", nil, m.UIParent, "BackdropTemplate")
  dd.text = dd:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  dd.arrow = dd:CreateTexture(nil, "OVERLAY")
  tr2.watch(dd); tr2.watch(dd.text); tr2.watch(dd.arrow)
  tr2.start(); S.Dropdown(dd); tr2.stop(); tr2.restore()
  local want = paintLines(tr1, real)
  assertTrue(want:find("SetVertexColor(0.700,0.700,0.720)", 1, true) ~= nil, "the arrow's gray")
  assertEqual(paintLines(tr2, dd), want)
  Skin:SetChoice(OWNER, "ka0s", "glass")
  assertEqual(F.rgba(survey(m, dd.arrow).vertex), F.tok(Skin, "glass", "icon.tint"), "repainted")
end)

-- ── checkboxes ───────────────────────────────────────────────────────────────────────────────

local function checkButton(m)
  local cb = m.CreateFrame("CheckButton", nil, m.UIParent)
  local on = false
  rawset(cb, "GetChecked", function() return on end)
  rawset(cb, "SetChecked", function(_, v) on = v and true or false end)
  local normal, check = cb:CreateTexture(), cb:CreateTexture()
  rawset(cb, "GetNormalTexture", function() return normal end)
  rawset(cb, "GetCheckedTexture", function() return check end)
  return cb, normal, check
end

test("skin controls: Checkbox draws a box and a mark that follows the check", function()
  local m, Skin = F.env()
  m.hooksecurefunc = function(t, name, fn)
    local orig = t[name]
    rawset(t, name, function(...) local a = orig(...); fn(...); return a end)
  end
  local S = F.owner(Skin, OWNER, "obsidian")
  local cb, normal, check = checkButton(m)
  S.Checkbox(cb, { hover = true })
  assertEqual(normal:GetAlpha(), 0, "the stock box faded")
  assertEqual(check:GetAlpha(), 0, "the stock check faded")
  local box, mark = F.region(Skin, cb, "box"), F.region(Skin, cb, "mark")
  assertEqual(F.rgba(survey(m, box).vertex), F.tok(Skin, "obsidian", "check.bg"))
  assertEqual(F.rgba(survey(m, mark).vertex), F.tok(Skin, "obsidian", "check.mark"))
  assertFalse(mark:IsShown(), "unchecked: no mark")
  cb:SetChecked(true)
  assertTrue(mark:IsShown(), "SetChecked shows it")
  cb:SetChecked(false); cb:__fire("OnClick")
  assertFalse(mark:IsShown())
  assertEqual(F.rgba(survey(m, F.region(Skin, cb, "hover")).color), F.tok(Skin, "obsidian", "menu.hover"))
end)

test("skin controls: WoW Default's checkbox is the client's art; Ka0s Default draws a square box", function()
  -- SkinPaintControls minor 2 (the owner's note): Ka0s Default no longer leaves the client's round
  -- check button; it draws a square box in its control colors, the stock art faded.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "wow")
  local cb, normal = checkButton(m)
  S.Checkbox(cb, { stockCheck = true })
  local box = F.region(Skin, cb, "box")
  assertEqual(survey(m, box).texture, Skin:ResolveSkin("wow")["check.texture"])
  assertFalse(F.region(Skin, cb, "mark"):IsShown(), "stockCheck keeps the client's check")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertEqual(normal:GetAlpha(), 0, "the round stock art is faded")
  assertTrue(box:IsShown(), "a square box is drawn")
  local sv = survey(m, box)
  assertEqual(F.rgba(sv.vertex or sv.color), F.tok(Skin, "ka0s", "check.bg"), "in Ka0s Default's control fill")
end)

test("skin controls: a disabled Button's label reads text.disabled, and comes back when enabled", function()
  -- red under: a disabled button painted exactly like an enabled one (the owner's screenshots).
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "obsidian")
  local b = backdropButton(m)
  local on = true
  rawset(b, "IsEnabled", function() return on end)
  S.Button(b)
  assertEqual(F.rgba(survey(m, b.text).textColor), F.tok(Skin, "obsidian", "btn.text"))
  on = false; b:__fire("OnDisable")
  assertEqual(F.rgba(survey(m, b.text).textColor), F.tok(Skin, "obsidian", "text.disabled"), "dimmed")
  b:__fire("OnEnter")
  assertEqual(F.rgba(survey(m, b.text).textColor), F.tok(Skin, "obsidian", "text.disabled"), "no hover while disabled")
  on = true; b:__fire("OnEnable")
  assertEqual(F.rgba(survey(m, b.text).textColor), F.tok(Skin, "obsidian", "btn.text"), "back to rest")
end)

-- ── scroll bars and sliders ──────────────────────────────────────────────────────────────────

test("skin controls: ScrollBar's thumb states and the console's own bar match today's tints", function()
  -- OptionsScroll.lua THUMB_ON / THUMB_OFF; DebugLog.lua the console's track and thumb
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local tr = F.tracer(m)
  local sb = m.CreateFrame("Slider", nil, m.UIParent)
  local thumb = sb:CreateTexture()
  rawset(sb, "GetThumbTexture", function() return thumb end)
  tr.watch(sb); tr.watch(thumb)
  tr.start(); S.ScrollBar(sb, { state = "on" }); S.ScrollBar(sb, { state = "off" }); tr.stop()
  assertEqual(F.only(tr, PAINT), "#2:SetVertexColor(1,1,1,1)\n#2:SetVertexColor(0.500,0.500,0.500,0.600)")
  local bar = m.CreateFrame("Frame")
  local track, own = bar:CreateTexture(), bar:CreateTexture()
  tr.watch(bar); tr.watch(track); tr.watch(own)
  tr.start(); S.ScrollBar(bar, { track = track, thumb = own }); tr.stop(); tr.restore()
  assertEqual(F.only(tr, PAINT), "#4:SetColorTexture(0.240,0.240,0.270,0.300)\n#5:SetColorTexture(0.500,0.500,0.550,0.850)")
end)

test("skin controls: a bar's own thumb is tinted and its track drawn under every skin", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local sb = m.CreateFrame("Slider", nil, m.UIParent)
  local thumb = sb:CreateTexture()
  rawset(sb, "GetThumbTexture", function() return thumb end)
  S.ScrollBar(sb)
  assertEqual(F.rgba(survey(m, thumb).vertex), F.tok(Skin, "ka0s", "scroll.thumb"), "Ka0s Default tints it (minor 6)")
  Skin:SetChoice(OWNER, "ka0s", "ember")
  assertEqual(F.rgba(survey(m, thumb).vertex), F.tok(Skin, "ember", "scroll.thumb"))
  assertEqual(F.rgba(survey(m, F.region(Skin, sb, "track")).color), F.tok(Skin, "ember", "scroll.track"))
  Skin:SetChoice(OWNER, "ka0s", "wow")
  assertEqual(survey(m, thumb).texture, Skin:ResolveSkin("wow")["scroll.thumbTexture"], "WoW Default's knob")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertEqual(F.rgba(survey(m, F.region(Skin, sb, "track")).color), F.tok(Skin, "ka0s", "scroll.track"), "its own track")
end)

test("skin controls: Slider is painted under every skin, Ka0s Default's thin bar included", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local sl = m.CreateFrame("Slider", nil, m.UIParent)
  local thumb = sl:CreateTexture()
  rawset(sl, "GetThumbTexture", function() return thumb end)
  S.Slider(sl)
  assertEqual(F.rgba(survey(m, thumb).vertex), F.tok(Skin, "ka0s", "slider.thumb"), "Ka0s Default's thumb (minor 8)")
  assertEqual(F.rgba(survey(m, F.region(Skin, sl, "track")).color), F.tok(Skin, "ka0s", "slider.track"), "and bar")
  Skin:RegisterSkin({ key = "sl", tokens = { ["slider.track"] = { 0.2, 0.2, 0.2, 1 },
                                             ["slider.thumb"] = { 1, 0, 0, 1 } } })
  Skin:SetChoice(OWNER, "ka0s", "sl")
  assertEqual(F.rgba(survey(m, thumb).vertex), "1,0,0,1")
  assertEqual(F.rgba(survey(m, F.region(Skin, sl, "track")).color), "0.200,0.200,0.200,1")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertEqual(F.rgba(survey(m, F.region(Skin, sl, "track")).color), F.tok(Skin, "ka0s", "slider.track"))
end)

-- ── tabs ─────────────────────────────────────────────────────────────────────────────────────

test("skin controls: Tab paints its state, SetTabSelection moves it, and a repaint keeps it", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "obsidian")
  local tab = m.CreateFrame("Button", nil, m.UIParent)
  tab.text = tab:CreateFontString()
  S.Tab(tab, { selected = false })
  assertEqual(F.rgba(survey(m, tab.text).textColor), F.tok(Skin, "obsidian", "tab.text"))
  assertNil(F.region(Skin, tab, "line"), "no underline while idle")
  S.SetTabSelection(tab, true)
  assertEqual(F.rgba(survey(m, tab.text).textColor), F.tok(Skin, "obsidian", "tab.onText"))
  assertEqual(F.rgba(survey(m, F.region(Skin, tab, "line")).color), F.tok(Skin, "obsidian", "tab.onLine"))
  Skin:SetChoice(OWNER, "ka0s", "ember")
  assertEqual(F.rgba(survey(m, tab.text).textColor), F.tok(Skin, "ember", "tab.onText"), "still selected")
  S.SetTabSelection(tab, false)
  assertFalse(F.region(Skin, tab, "line"):IsShown())
end)

test("skin controls: WoW Default's tabs are the client's tab art; a stock tab is faded under every skin", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "wow")
  local tab = m.CreateFrame("Button", nil, m.UIParent)
  S.Tab(tab, { selected = true })
  assertEqual(survey(m, F.region(Skin, tab, "fill")).texture, Skin:ResolveSkin("wow")["tab.onTexture"])
  S.SetTabSelection(tab, false)
  assertEqual(survey(m, F.region(Skin, tab, "fill")).texture, Skin:ResolveSkin("wow")["tab.texture"])
  local K = F.owner(Skin, "Other")
  local stock = m.CreateFrame("Button", nil, m.UIParent)
  local art = stock:CreateTexture()
  K.Tab(stock, { stock = { art } })
  assertEqual(art:GetAlpha(), 0, "Ka0s Default fades the art the caller named (minor 6)")
  assertTrue(F.region(Skin, stock, "fill") ~= nil, "and draws its own backing")
  Skin:SetChoice("Other", "ka0s", "glass")
  assertEqual(art:GetAlpha(), 0, "a skin fades the art the caller named")
end)

-- ── small buttons ────────────────────────────────────────────────────────────────────────────

test("skin controls: CloseButton on Ka0s Default is Core's close button, call for call", function()
  local m, Skin = F.env()
  local core = m.LibStub("LibKa0s-Core-1.0")
  local S = F.owner(Skin, OWNER)
  local function lines(tr)
    local out = {}
    for _, line in ipairs(tr.lines) do
      local method, args = line:match("^#%d+:([%w]+)%((.-)%)$")
      if method == "SetTextColor" or (method == "SetScript" and not args:find("OnClick", 1, true)) then
        out[#out + 1] = line:gsub("^#%d+", "")
      end
    end
    return table.concat(out, "\n")
  end
  local tr1 = F.tracer(m); tr1.start()
  core.MakeCloseButton(m.UIParent, function() end)
  tr1.stop(); tr1.restore()
  local tr2 = F.tracer(m)
  local b = m.CreateFrame("Button", nil, m.UIParent)
  b.glyph = b:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  tr2.watch(b); tr2.watch(b.glyph)
  tr2.start(); S.CloseButton(b, { own = true }); tr2.stop(); tr2.restore()
  local want = lines(tr1)
  assertTrue(want:find("SetTextColor(0.700,0.700,0.720)", 1, true) ~= nil)
  assertEqual(lines(tr2), want)
  b:__fire("OnEnter")
  assertEqual(F.rgba(survey(m, b.glyph).textColor), "1,0.300,0.300,1", "close.hot")
end)

test("skin controls: a stock close button gets a glyph under every skin, Ka0s Default too", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local b, normal = stockButton(m)
  S.CloseButton(b)
  assertEqual(F.rgba(survey(m, F.region(Skin, b, "glyph")).textColor), F.tok(Skin, "ka0s", "close.rest"),
    "Ka0s Default's glyph (minor 6)")
  Skin:SetChoice(OWNER, "ka0s", "contrast")
  assertEqual(normal:GetAlpha(), 0)
  local glyph = F.region(Skin, b, "glyph")
  assertEqual(survey(m, glyph).text, "x")
  assertEqual(F.rgba(survey(m, glyph).textColor), F.tok(Skin, "contrast", "close.rest"))
  b:__fire("OnEnter")
  assertEqual(F.rgba(survey(m, glyph).textColor), F.tok(Skin, "contrast", "close.hot"), "hooked hover")
end)

test("skin controls: PageButton, SquareIcon, IconBorder, SortHeaderBar and ApplyBarFill", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "contrast")
  local pb = m.CreateFrame("Button", nil, m.UIParent)
  rawset(pb, "SetBackdrop", nil)
  S.PageButton(pb, "prev")
  local arrow = F.region(Skin, pb, "arrow")
  assertEqual(survey(m, arrow).texture, "Interface\\ChatFrame\\ChatFrameExpandArrow", "in-client art")
  assertEqual(arrow:GetRotation(), math.pi)
  local icon = m.CreateFrame("Button", nil, m.UIParent)
  icon.icon = icon:CreateTexture()
  S.SquareIcon(icon, { crop = true })
  assertEqual(select(1, icon.icon:GetTexCoord()), 0.08, "cropped")
  Skin:RegisterSkin({ key = "framed", tokens = { ["icon.border"] = { 1, 1, 0, 1 },
                                                 ["list.header.bg"] = { 0, 0, 0.2, 1 } } })
  local ib = m.CreateFrame("Frame", nil, m.UIParent)
  S.IconBorder(ib, { size = 2 })
  assertEqual(F.rgba(survey(m, F.region(Skin, ib, "edgeTop")).color), F.tok(Skin, "contrast", "icon.border"),
    "Contrast inherits Ka0s Default's black icon border (SkinDefs minor 8)")
  Skin:SetChoice(OWNER, "ka0s", "framed")
  assertEqual(F.rgba(survey(m, F.region(Skin, ib, "edgeTop")).color), "1,1,0,1", "repainted with one")
  local bar = m.CreateFrame("Frame", nil, m.UIParent)
  rawset(bar, "SetBackdrop", nil)
  local h1, a1 = bar:CreateFontString(), bar:CreateTexture()
  S.SortHeaderBar(bar, { texts = { h1 }, arrows = { a1 } })
  assertEqual(F.rgba(survey(m, h1).textColor), F.tok(Skin, "framed", "list.header.text"))
  assertEqual(F.rgba(survey(m, a1).vertex), F.tok(Skin, "framed", "icon.tint"))
  assertEqual(F.rgba(survey(m, F.region(Skin, bar, "fill")).color), "0,0,0.200,1", "the header fill")
  local fill = m.CreateFrame("Frame"):CreateTexture()
  S.ApplyBarFill(fill)
  assertEqual(F.rgba(survey(m, fill).vertex), F.tok(Skin, "framed", "text.accent"))
end)

-- ── navigation, drawers, list rows ───────────────────────────────────────────────────────────

test("skin controls: NavItem on Ka0s Default is OptionsNav's entry paint", function()
  -- OptionsNav.lua newEntry / dressEntry: sel SELECT_RGB, label LABEL_WHITE / LABEL_GOLD, three each
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local tr = F.tracer(m)
  local b = m.CreateFrame("Button", nil, m.UIParent)
  local label, sel = b:CreateFontString(), b:CreateTexture()
  tr.watch(b); tr.watch(label); tr.watch(sel)
  tr.start()
  S.NavItem(b, { label = label, sel = sel, selected = true })
  S.NavItem(b, { label = label, sel = sel, selected = false })
  tr.stop(); tr.restore()
  assertEqual(F.only(tr, PAINT), table.concat({
    "#2:SetTextColor(1,1,1)", "#3:SetVertexColor(0.300,0.500,1)",
    "#2:SetTextColor(1,0.820,0)", "#3:SetVertexColor(0.300,0.500,1)",
  }, "\n"))
end)

test("skin controls: Drawer on Ka0s Default is OptionsDrawer's header paint", function()
  -- OptionsDrawer.lua dressHead: label, summary (three each), then paintEdges: fill, left, right,
  -- bottom, top, SetVertexColor with four components
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local tr = F.tracer(m)
  local head = m.CreateFrame("Button", nil, m.UIParent)
  local label, summary = head:CreateFontString(), head:CreateFontString()
  local e = { fill = head:CreateTexture(), left = head:CreateTexture(), right = head:CreateTexture(),
              bottom = head:CreateTexture(), top = head:CreateTexture() }
  for _, o in ipairs({ head, label, summary, e.fill, e.left, e.right, e.bottom, e.top }) do tr.watch(o) end
  tr.start(); S.Drawer(head, { label = label, summary = summary, edges = e, open = true, set = true }); tr.stop()
  tr.restore()
  assertEqual(F.only(tr, PAINT), table.concat({
    "#2:SetTextColor(1,0.820,0)", "#3:SetTextColor(0.910,0.850,0.660)",
    "#4:SetVertexColor(0.130,0.110,0.080,0.950)",
    "#5:SetVertexColor(0.420,0.330,0.130,1)", "#6:SetVertexColor(0.420,0.330,0.130,1)",
    "#7:SetVertexColor(0.420,0.330,0.130,1)", "#8:SetVertexColor(0.420,0.330,0.130,1)",
  }, "\n"))
end)

test("skin controls: ListRow washes live under the row and follow the latest state", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local row = m.CreateFrame("Button", nil, m.UIParent)
  S.ListRow(row, "stripe")
  local stripe = F.region(Skin, row, "stripe")
  assertEqual(stripe:GetParent(), row, "a region of the row (SkinPaintControls minor 5)")
  assertEqual(survey(m, stripe).sublevel, -8, "at the bottom of BACKGROUND, under the row's text")
  assertEqual(F.rgba(survey(m, stripe).color), F.tok(Skin, "ka0s", "list.stripe"))
  S.ListRow(row, { stripe = true, hover = true })
  assertEqual(F.rgba(survey(m, F.region(Skin, row, "hover")).color), F.tok(Skin, "ka0s", "list.hover"))
  S.ListRow(row, "normal")
  assertFalse(stripe:IsShown()); assertFalse(F.region(Skin, row, "hover"):IsShown())
  S.ListRow(row, "selected")
  Skin:SetChoice(OWNER, "ka0s", "contrast")
  assertEqual(F.rgba(survey(m, F.region(Skin, row, "sel")).color), F.tok(Skin, "contrast", "list.sel"),
    "the repaint replays the latest state")
  assertEqual(F.rgba(survey(m, F.region(Skin, row, "edgeTop")).color), F.tok(Skin, "contrast", "list.selOutline"))
  local regions = row:GetNumRegions()
  S.ListRow(row, "selected")
  assertEqual(row:GetNumRegions(), regions, "no new region on the row itself")
end)

-- ── idempotence, repaint, owner moves (every primitive) ──────────────────────────────────────

--- Frames and regions under `obj` (a frame, or a region: then its parent), counted recursively.
local function census(obj)
  local frames, regions = 0, 0
  local function walk(f)
    frames = frames + 1
    regions = regions + f:GetNumRegions()
    for _, c in ipairs({ f:GetChildren() }) do walk(c) end
  end
  local kind = obj.GetObjectType and obj:GetObjectType()
  if kind == "Texture" or kind == "FontString" then obj = obj:GetParent() end
  walk(obj)
  return frames .. " frames, " .. regions .. " regions"
end

--- Count every HookScript on `frame` and every hooksecurefunc in `m`; answers a reader.
local function hookCounter(m, frame)
  local n = { script = 0, secure = 0 }
  local kind = type(frame) == "table" and frame:GetObjectType()
  if kind and kind ~= "Texture" and kind ~= "FontString" then
    local orig = frame.HookScript
    rawset(frame, "HookScript", function(self, ...) n.script = n.script + 1; return orig(self, ...) end)
  end
  m.hooksecurefunc = function() n.secure = n.secure + 1 end
  return function() return n.script .. " script hooks, " .. n.secure .. " secure hooks" end
end

--- Watch every argument, every region and child of a frame argument, and every region an options
--- table names.
local function watchAll(tr, args)
  local function walk(o)
    if type(o) ~= "table" or tr.ids[o] then return end
    local kind = type(o.GetObjectType) == "function" and o:GetObjectType()
    if not kind then
      for _, v in pairs(o) do if type(v) == "table" and type(v.GetObjectType) == "function" then walk(v) end end
      return
    end
    tr.watch(o)
    if kind == "Texture" or kind == "FontString" then return end
    for _, r in ipairs({ o:GetRegions() }) do walk(r) end
    for _, c in ipairs({ o:GetChildren() }) do walk(c) end
  end
  for _, a in ipairs(args) do walk(a) end
end

local function bare(m, kind)
  local f = m.CreateFrame(kind or "Frame", nil, m.UIParent)
  rawset(f, "SetBackdrop", nil)
  return f
end

local function withFS(f, key) f[key] = f:CreateFontString(); return f end

-- name -> function(m) answering the target and the primitive's further arguments
local BUILD = {
  Shell = function(m) return F.window(m) end,
  Panel = function(m) return bare(m) end,
  Inset = function(m) return m.CreateFrame("Frame", nil, m.UIParent, "BackdropTemplate") end,
  FadeRegions = function(m) local f = bare(m); f:CreateTexture(); return f end,
  FadeNineSlice = function(m) return m.CreateFrame("Frame", nil, m.UIParent, "PortraitFrameTemplate") end,
  Button = function(m) return backdropButton(m) end,
  WhiteButtonLabel = function(m) return backdropButton(m) end,
  StateButtonLabel = function(m) return backdropButton(m), true end,
  EditBox = function(m) return withFS(m.CreateFrame("EditBox", nil, m.UIParent, "BackdropTemplate"), "hint") end,
  Checkbox = function(m) local cb = bare(m, "CheckButton"); rawset(cb, "GetChecked", function() return true end); return cb end,
  Dropdown = function(m)
    local dd = withFS(m.CreateFrame("Button", nil, m.UIParent, "BackdropTemplate"), "text")
    dd.arrow = dd:CreateTexture(); return dd
  end,
  ScrollBar = function(m) return bare(m, "Slider") end,
  Slider = function(m) return bare(m, "Slider") end,
  Tab = function(m) return withFS(bare(m, "Button"), "text"), { selected = true } end,
  CloseButton = function(m) local b = bare(m, "Button"); b.icon = b:CreateTexture(); return b end,
  PageButton = function(m) return backdropButton(m), "next" end,
  SquareIcon = function(m) local f = bare(m); f.icon = f:CreateTexture(); return f, { crop = true } end,
  IconBorder = function(m) return bare(m) end,
  SortHeaderBar = function(m) local f = bare(m); return f, { texts = { f:CreateFontString() } } end,
  ApplyBarFill = function(m) return bare(m, "StatusBar") end,
  NavItem = function(m)
    local f = bare(m); return f, { label = f:CreateFontString(), sel = f:CreateTexture(), selected = true }
  end,
  Drawer = function(m) local f = bare(m, "Button"); return f, { label = f:CreateFontString(), open = true } end,
  ListRow = function(m) return bare(m, "Button"), "selected" end,
  TitleBar = function(m) return withFS(bare(m), "title") end,
  Divider = function(m) return bare(m) end,
  Footer = function(m) return withFS(bare(m), "text") end,
  Card = function(m) local f = bare(m); return f, { title = f:CreateFontString() } end,
  Strip = function(m) return bare(m) end,
  Cover = function(m) local f = bare(m); return f, { text = f:CreateFontString() } end,
  Tooltip = function(m) return m.CreateFrame("Frame", nil, m.UIParent, "BackdropTemplate") end,
  MenuFrame = function(m) return m.CreateFrame("Frame", nil, m.UIParent, "BackdropTemplate") end,
  Text = function(m) return bare(m):CreateFontString(), "heading" end,
  Font = function(m) return bare(m):CreateFontString(), 1, 1, 1 end,
  White = function(m) return bare(m):CreateFontString() end,
}

-- Primitives whose every token is nil in both skins of the repaint case: nothing to repaint.
local NO_TOKEN = { IconBorder = true }   -- icon.border is nil in every shipped skin

local function eachPrimitive(fn)
  local names = {}
  for name in pairs(BUILD) do names[#names + 1] = name end
  table.sort(names)
  for _, name in ipairs(names) do fn(name, BUILD[name]) end
end

test("skin controls: every primitive's second call makes no new frame, region or hook", function()
  eachPrimitive(function(name, build)
    for _, skin in ipairs({ "ka0s", "obsidian", "contrast", "wow" }) do
      local m, Skin = F.env()
      local S = F.owner(Skin, OWNER, skin)
      local args = { build(m) }
      local hooks = hookCounter(m, args[1])
      S[name](unpack(args))
      local first, firstHooks = census(args[1]), hooks()
      S[name](unpack(args))
      assertEqual(census(args[1]), first, name .. " on " .. skin .. ": no new frame or region")
      assertEqual(hooks(), firstHooks, name .. " on " .. skin .. ": no new hook")
    end
  end)
end)

test("skin controls: every primitive's repaint reuses its regions and paints the new skin", function()
  eachPrimitive(function(name, build)
    local m, Skin = F.env()
    local S = F.owner(Skin, OWNER, "obsidian")
    local args = { build(m) }
    local hooks = hookCounter(m, args[1])
    S[name](unpack(args))
    Skin:SetChoice(OWNER, "ka0s", "contrast")
    local regions = Skin.painted[args[1]].regions
    local after, afterHooks = census(args[1]), hooks()
    local tr = F.tracer(m)
    watchAll(tr, args)
    tr.start(); Skin:SetChoice(OWNER, "ka0s", "obsidian"); Skin:SetChoice(OWNER, "ka0s", "contrast"); tr.stop()
    tr.restore()
    assertTrue(Skin.painted[args[1]].regions == regions, name .. ": the same regions table")
    assertEqual(census(args[1]), after, name .. ": a repaint makes no new frame or region")
    assertEqual(hooks(), afterHooks, name .. ": and no new hook")
    assertTrue(#tr.lines > 0 or NO_TOKEN[name], name .. ": the repaint painted")
  end)
end)

-- ── the owner's notes, round 2 (SkinPaint minor 5, SkinPaintControls minor 3) ────────────────

test("skin controls: a dark label is shadowless, a light one keeps its shadow", function()
  -- red under: one shadowed font object for every label, which smears dark text on a bright fill.
  local m, Skin = F.env({ lsm = { ["font:Ka0s Barlow"] = "Fonts\\Barlow.ttf" } })
  local S = F.owner(Skin, OWNER, "glass")   -- lilac primary with dark text, a light normal label
  local p, b = backdropButton(m), backdropButton(m)
  S.Button(p, { primary = true }); S.Button(b)
  assertEqual(p.text:GetFontObject().shadow[1], 0, "dark text on the primary: no shadow")
  assertEqual(b.text:GetFontObject().shadow[1], 1, "light text on a normal button: the shadow")
end)

test("skin controls: an EditBox hint and a sort header's texts take the skin's face", function()
  -- red under: strings a primitive only tints, left on the client's font and its shadow.
  local m, Skin = F.env({ lsm = { ["font:Ka0s Barlow"] = "Fonts\\Barlow.ttf" } })
  local S = F.owner(Skin, OWNER, "obsidian")
  local eb = m.CreateFrame("EditBox", nil, m.UIParent, "BackdropTemplate")
  eb.hint = eb:CreateFontString()
  S.EditBox(eb)
  assertEqual(eb.hint:GetFontObject().font[1], "Fonts\\Barlow.ttf", "the hint")
  local bar = m.CreateFrame("Frame", nil, m.UIParent)
  local name = bar:CreateFontString()
  S.SortHeaderBar(bar, { texts = { name } })
  assertEqual(name:GetFontObject().font[1], "Fonts\\Barlow.ttf", "the header text")
end)

test("skin controls: a slider's track is a thin bar centered in it", function()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "obsidian")
  local sl = m.CreateFrame("Slider", nil, m.UIParent)
  sl:SetSize(180, 18)
  S.Slider(sl)
  local t = F.region(Skin, sl, "track")
  assertEqual(t:GetHeight(), 4, "a 4px bar, Ka0s Default's shape")
end)
