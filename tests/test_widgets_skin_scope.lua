-- tests/test_widgets_skin_scope.lua — the Widgets controls under the Scope switches (Widgets minor 17,
-- WidgetsAutocomplete 5, WidgetsLineChart 5, WidgetsDragHandle 7, SkinPaintControls 10,
-- SkinPaintExtras 6, SkinPaint 12; LK-06a of Ka0sAddonsCommonTasks
-- docs/2026-10-30-SKIN_LIBRARY_FOLLOWUPS, ruling R-5, decisions D-01, D-02 and D-13).
--
-- Two promises, each pinned here on the kit's paint recorder (tests/fixture_skin_paint.lua):
--
--   * IGNORE FONTS REACHES EVERY STRING A CONTROL DRAWS. The dropdown's menu rows (and the string the
--     menu is measured on), the mode strip's line, the autocomplete's rows, the chart's tick labels
--     and the drag handle's label drew their template's face in every skin, so the switch had
--     nothing to act on. An owned control now draws them in its skin's body face through the
--     facade (Prototype under Ka0s Default, D-13), and Ignore fonts gives each its template back. A
--     face the host named (`opts.font`, `spec.labelFont`) is the host's and is never touched.
--   * `panel = true` PUTS A CONTROL ON A SETTINGS PAGE (D-02): while its owner ignores its settings
--     panel the control is drawn as an owner-less one, live both ways; without it a control is a
--     window's and wears the skin whatever that switch says (D-01).
--
-- A FontString built from a template answers that template as its font object here, as the client's
-- does, so "given back" is observable: the kit's base answers none.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil
local F = dofile("tests/fixture_skin_paint.lua")

local OWNER = "LootHistory"
local WFILES = { "Widgets", "WidgetsReorder", "WidgetsDragHandle", "WidgetsLineChart", "WidgetsAutocomplete",
                 "WidgetsCopyWindow" }

-- Every font key resolves, so each skin's body face has a path: "Fonts\<key>".
local LSM = setmetatable({}, { __index = function(_, k)
  local key = type(k) == "string" and k:match("^font:(.+)$")
  return key and ("Fonts\\" .. key) or nil
end })

local function templateObject(name)
  return { name = name, GetName = function(self) return self.name end,
           GetFont = function() return "Fonts\\FRIZQT__.TTF", 10, "" end }
end

--- A fresh client with every Widgets file and the Skin major, a font for every skin face, and
--- template-built FontStrings that answer their template. Answers m, Skin, W.
local function env()
  local files = {}
  for _, f in ipairs(F.FILES) do files[#files + 1] = f end
  for _, f in ipairs(WFILES) do files[#files + 1] = f end
  local m, Skin = F.env({ files = files, lsm = LSM })
  m.__cursorX, m.__cursorY = 100, 100
  local objects = {}
  local create = m.CreateFrame
  m.CreateFrame = function(...)
    local f = create(...)
    local cfs = rawget(f, "CreateFontString")
    if type(cfs) == "function" then
      rawset(f, "CreateFontString", function(self, name, layer, template)
        local fs = cfs(self, name, layer, template)
        if type(template) == "string" then
          objects[template] = objects[template] or templateObject(template)
          fs:SetFontObject(objects[template])
        end
        return fs
      end)
    end
    return f
  end
  return m, Skin, m.LibStub("LibKa0s-Widgets-1.0")
end

--- The face `fs` draws in: the skin font object's path, or the template's name.
local function face(fs)
  local obj = fs:GetFontObject()
  if type(obj) == "string" then return obj end
  if type(obj) == "table" and obj.font then return obj.font[1] end
  if type(obj) == "table" then return obj.name end
  return nil
end

local KA0S_FACE = "Fonts\\Ka0s Prototype"

local function bodyFace(Skin, skin)
  return "Fonts\\" .. Skin:ResolveSkin(skin)["font.body"]
end

local function rgba(c) return F.rgba(c) end
local function survey(m, obj) return m.__paint(obj) end

-- ── the dropdown and its menu ────────────────────────────────────────────────────────────────

local function options(dd)
  dd:SetOptions({ { value = "a", label = "A" }, { value = "b", label = "B" } })
  dd:SelectValue("a")
  return dd
end

local function open(m, dd, state)
  local saved = m.CreateFrame
  m.CreateFrame = function(...)
    local f = saved(...)
    state.menu = state.menu or f
    return f
  end
  dd:__fire("OnClick")
  m.CreateFrame = saved
  if state.menu:IsShown() then dd:__fire("OnClick") end   -- closed again; the paint stays
  return state.menu
end

test("skin scope: an owned dropdown's menu rows and measure take the skin's body face", function()
  -- red under: the rows and the measuring string left on GameFontHighlightSmall in every skin, so
  -- Ignore fonts had nothing to give back and a long label in a wider face would truncate.
  local m, Skin, W = env()
  F.owner(Skin, OWNER)
  local state = {}
  local menu = open(m, options(W.Dropdown(m.UIParent, 120, { owner = OWNER })), state)
  assertEqual(face(menu.buttons[1].fs), KA0S_FACE, "Ka0s Default's face (D-13)")
  assertEqual(face(menu.buttons[2].fs), KA0S_FACE)
  assertEqual(face(menu.measure), KA0S_FACE, "measured in the face the rows wear")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(face(menu.buttons[1].fs), bodyFace(Skin, "obsidian"), "a switch repaints an open row")
  Skin:SetIgnore(OWNER, nil, true)
  assertEqual(face(menu.buttons[1].fs), "GameFontHighlightSmall", "Ignore fonts gives the template back")
  assertEqual(face(menu.measure), "GameFontHighlightSmall")
end)

test("skin scope: an owner-less open after an owned one gives the rows their template back", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  local state = {}
  local menu = open(m, options(W.Dropdown(m.UIParent, 120, { owner = OWNER })), state)
  assertEqual(face(menu.buttons[2].fs), bodyFace(Skin, "obsidian"))
  open(m, options(W.Dropdown(m.UIParent, 120)), state)
  assertEqual(face(menu.buttons[1].fs), "GameFontHighlightSmall")
  assertEqual(face(menu.buttons[2].fs), "GameFontHighlightSmall")
  assertEqual(face(menu.measure), "GameFontHighlightSmall")
  Skin:SetChoice(OWNER, "ka0s", "azeroth")
  assertEqual(face(menu.buttons[1].fs), "GameFontHighlightSmall", "no longer the owner's to repaint")
end)

test("skin scope: a panel-scoped dropdown is owner-less while its owner ignores the panel, live", function()
  -- red under: a dropdown with no panel scope, which keeps the skin on a settings page whose owner
  -- asked for the client's look there.
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  local dd = options(W.Dropdown(m.UIParent, 120, { owner = OWNER, panel = true }))
  assertEqual(rgba(survey(m, dd).backdropColor), F.tok(Skin, "obsidian", "input.bg"))
  Skin:SetIgnore(OWNER, true, nil)
  assertEqual(rgba(survey(m, dd).backdropColor), "0.100,0.100,0.120,0.900", "minor 15's flat fill, live")
  assertEqual(rgba(survey(m, dd.arrow).vertex), "0.700,0.700,0.720,1", "and its arrow")
  local state = {}
  local menu = open(m, dd, state)
  assertEqual(rgba(survey(m, menu.buttons[2].fs).textColor), "0.900,0.900,0.900,1", "the menu is owner-less")
  assertEqual(face(menu.buttons[2].fs), "GameFontHighlightSmall")
  Skin:SetIgnore(OWNER, false, nil)
  assertEqual(rgba(survey(m, dd).backdropColor), F.tok(Skin, "obsidian", "input.bg"), "skinned again, live")
  open(m, dd, state)
  assertEqual(rgba(survey(m, menu.buttons[2].fs).textColor), F.tok(Skin, "obsidian", "menu.text"))
end)

test("skin scope: a dropdown with no panel scope keeps the skin while the panel is ignored", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  Skin:SetIgnore(OWNER, true, nil)
  local state = {}
  for _, opts in ipairs({ { owner = OWNER }, { owner = OWNER, panel = false } }) do
    local dd = options(W.Dropdown(m.UIParent, 120, opts))
    assertEqual(rgba(survey(m, dd).backdropColor), F.tok(Skin, "obsidian", "input.bg"), "a window's control")
    local menu = open(m, dd, state)
    assertEqual(rgba(survey(m, menu.buttons[2].fs).textColor), F.tok(Skin, "obsidian", "menu.text"))
  end
end)

-- ── the search box ───────────────────────────────────────────────────────────────────────────

test("skin scope: a panel-scoped search box is owner-less while the panel is ignored, focus included", function()
  -- red under: the focus hook painting the skin's input.focus over a given-back box, or a box that
  -- keeps the skin.
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "azeroth")
  local box = W.SearchBox(m.UIParent, 100, { hint = "Search", icon = "icon", owner = OWNER, panel = true })
  assertEqual(rgba(survey(m, box).backdropColor), F.tok(Skin, "azeroth", "input.bg"))
  Skin:SetIgnore(OWNER, true, nil)
  assertEqual(rgba(survey(m, box).backdropColor), "0.100,0.100,0.120,0.900", "given back, live")
  assertEqual(face(box.hint), "GameFontDisableSmall", "the hint's own face")
  local v = survey(m, box.icon).vertex
  assertEqual(F.rgba({ v[1], v[2], v[3] }), "0.700,0.700,0.720,1", "the icon's own gray")
  box:__fire("OnEditFocusGained")
  assertEqual(rgba(survey(m, box).backdropBorderColor), "1,0.820,0,0.900", "minor 15's gold focus line")
  box:__fire("OnEditFocusLost")
  assertEqual(rgba(survey(m, box).backdropBorderColor), "0.240,0.240,0.270,0.900")
  Skin:SetIgnore(OWNER, false, nil)
  assertEqual(rgba(survey(m, box).backdropColor), F.tok(Skin, "azeroth", "input.bg"), "skinned again")
  box:__fire("OnEditFocusGained")
  assertEqual(rgba(survey(m, box).backdropBorderColor), F.tok(Skin, "azeroth", "input.focus"))
  v = survey(m, box.icon).vertex
  assertEqual(F.rgba({ v[1], v[2], v[3] }), F.rgba({ Skin:Color(OWNER, "icon.tint") }))
end)

-- ── the mode strip ───────────────────────────────────────────────────────────────────────────

test("skin scope: an owned strip's line is text.accent in the body face, and Ignore fonts gives it back", function()
  -- red under: the line left on GameFontNormalSmall's gold and face in every skin.
  local m, Skin, W = env()
  F.owner(Skin, OWNER)
  local s = W.TestStrip(m.UIParent, { text = "Test", owner = OWNER })
  assertEqual(rgba(survey(m, s.text).textColor), "1,0.820,0,1", "Ka0s Default's accent is the template's gold")
  assertEqual(face(s.text), KA0S_FACE)
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(rgba(survey(m, s.text).textColor), F.tok(Skin, "obsidian", "text.accent"))
  assertEqual(face(s.text), bodyFace(Skin, "obsidian"))
  Skin:SetIgnore(OWNER, nil, true)
  assertEqual(face(s.text), "GameFontNormalSmall", "its own face")
  assertEqual(rgba(survey(m, s.text).textColor), F.tok(Skin, "obsidian", "text.accent"), "the color stays")
end)

test("skin scope: a panel-scoped strip is owner-less while the panel is ignored, live", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER)
  Skin:RegisterSkin({ key = "loud", tokens = { ["strip.sim"] = { 0, 1, 0, 0.5 }, ["text.accent"] = { 0, 0, 1, 1 } } })
  Skin:SetChoice(OWNER, "ka0s", "loud")
  local s = W.TestStrip(m.UIParent, { text = "Sim", kind = "sim", owner = OWNER, panel = true })
  assertEqual(rgba(survey(m, s.__fill).color), "0,1,0,0.500")
  Skin:SetIgnore(OWNER, true, nil)
  assertEqual(rgba(survey(m, s.__fill).color), "0.350,0.800,1,0.120", "minor 15's cyan, live")
  assertEqual(face(s.text), "GameFontNormalSmall")
  assertTrue(rgba(survey(m, s.text).textColor) ~= "0,0,1,1", "not the skin's accent")
  Skin:SetIgnore(OWNER, false, nil)
  assertEqual(rgba(survey(m, s.__fill).color), "0,1,0,0.500", "skinned again, live")
  assertEqual(rgba(survey(m, s.text).textColor), "0,0,1,1")
  local w = W.TestStrip(m.UIParent, { text = "Sim", kind = "sim", owner = OWNER })
  Skin:SetIgnore(OWNER, true, nil)
  assertEqual(rgba(survey(m, w.__fill).color), "0,1,0,0.500", "a window's strip keeps the skin")
end)

-- ── the autocomplete ─────────────────────────────────────────────────────────────────────────

local function suggest(m, W, opts)
  local box = m.CreateFrame("EditBox", nil, m.UIParent, "BackdropTemplate")
  rawset(box, "GetText", function() return "ab" end)
  opts.provider = function() return { { text = "One" }, { text = "Two" } } end
  local h = W.Autocomplete(box, opts)
  h:Refresh()
  return h
end

test("skin scope: an owned autocomplete's rows take the body face unless the host named one", function()
  -- red under: the rows left on GameFontHighlightSmall in every skin.
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  local h = suggest(m, W, { owner = OWNER })
  assertEqual(face(h.__rows[1].label), bodyFace(Skin, "obsidian"))
  Skin:SetIgnore(OWNER, nil, true)
  h:Refresh()
  assertEqual(face(h.__rows[1].label), "GameFontHighlightSmall", "Ignore fonts")
  local hosted = suggest(m, W, { owner = OWNER, font = "HostFont" })
  Skin:SetIgnore(OWNER, nil, false)
  hosted:Refresh()
  assertEqual(face(hosted.__rows[1].label), "HostFont", "the host's face is the host's")
end)

test("skin scope: a panel-scoped autocomplete is owner-less while the panel is ignored", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  local h = suggest(m, W, { owner = OWNER, panel = true })
  assertEqual(rgba(survey(m, h.__rows[1].label).textColor), F.tok(Skin, "obsidian", "menu.text"))
  Skin:SetIgnore(OWNER, true, nil)
  h:Refresh()
  assertEqual(rgba(survey(m, h.__rows[1].label).textColor), "0.900,0.900,0.900,1", "AUTOCOMPLETE.TEXT")
  assertEqual(rgba(survey(m, h.__rows[1].__hl).color), "1,0.820,0,0.150")
  assertEqual(face(h.__rows[1].label), "GameFontHighlightSmall")
  Skin:SetIgnore(OWNER, false, nil)
  h:Refresh()
  assertEqual(face(h.__rows[1].label), bodyFace(Skin, "obsidian"), "skinned on the next show")
end)

-- ── the line chart ───────────────────────────────────────────────────────────────────────────

local function chart(m, W, opts)
  local c = W.LineChart(m.UIParent, opts)
  c:SetData({ xMin = 100, xMax = 300, series = { { points = { { x = 100, y = 0 }, { x = 300, y = 10 } } } } })
  c:Render(400, 200)
  return c
end

test("skin scope: an owned chart's labels take the body face unless the host named one", function()
  -- red under: the tick labels left on GameFontDisableSmall in every skin.
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  local c = chart(m, W, { owner = OWNER })
  assertTrue(#c.__labelPool > 0)
  assertEqual(face(c.__labelPool[1]), bodyFace(Skin, "obsidian"))
  Skin:SetIgnore(OWNER, nil, true)
  assertEqual(face(c.__labelPool[1]), "GameFontDisableSmall", "Ignore fonts")
  local hosted = chart(m, W, { owner = OWNER, font = "HostFont" })
  Skin:SetIgnore(OWNER, nil, false)
  assertEqual(face(hosted.__labelPool[1]), "HostFont", "the host's face is the host's")
end)

test("skin scope: a panel-scoped chart reads lib.LINE_CHART while the panel is ignored, live", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER)
  Skin:RegisterSkin({ key = "inky", tokens = { ["chart.crosshair"] = { 1, 0, 1, 1 } } })
  Skin:SetChoice(OWNER, "ka0s", "inky")
  local c = chart(m, W, { owner = OWNER, panel = true })
  assertEqual(F.rgba(c.__cross.__color), "1,0,1,1")
  Skin:SetIgnore(OWNER, true, nil)
  assertEqual(F.rgba(c.__cross.__color), F.rgba(W.LINE_CHART.CROSSHAIR), "owner-less, live")
  assertEqual(face(c.__labelPool[1]), "GameFontDisableSmall")
  Skin:SetIgnore(OWNER, false, nil)
  assertEqual(F.rgba(c.__cross.__color), "1,0,1,1", "skinned again, live")
end)

-- ── the drag handle ──────────────────────────────────────────────────────────────────────────

local function handle(m, W, spec)
  spec.label, spec.moveFrame = spec.label or "Move", m.CreateFrame("Frame")
  return W.DragHandle(m.UIParent, spec)
end

test("skin scope: an owned drag handle's label takes the body face, and is measured in it", function()
  -- red under: the label left on GameFontNormalSmall, or measured in the template while drawn in the
  -- skin's face (ApplyWidth would size the strip for Friz and a wider face would truncate).
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  local h = handle(m, W, { owner = OWNER })
  assertEqual(face(h.label), bodyFace(Skin, "obsidian"))
  h:Measure()
  assertTrue(W.__DragHandleMeasurer():GetFontObject() == h.label:GetFontObject(), "the measurer wears it")
  Skin:SetIgnore(OWNER, nil, true)
  assertEqual(face(h.label), "GameFontNormalSmall", "Ignore fonts")
  h:Measure()
  assertEqual(face(W.__DragHandleMeasurer()), "GameFontNormalSmall", "and measures in it")
  local plain = handle(m, W, {})
  plain:Measure()
  assertEqual(face(plain.label), "GameFontNormalSmall", "an owner-less label is untouched")
  local hosted = handle(m, W, { owner = OWNER, labelFont = "HostFont" })
  Skin:SetIgnore(OWNER, nil, false)
  assertEqual(face(hosted.label), "HostFont", "the host's face is the host's")
end)

test("skin scope: a panel-scoped drag handle is owner-less while the panel is ignored, live", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  local h = handle(m, W, { owner = OWNER, panel = true })
  assertEqual(rgba(survey(m, h.bg).color), F.tok(Skin, "obsidian", "handle.bg"))
  Skin:SetIgnore(OWNER, true, nil)
  assertEqual(rgba(survey(m, h.bg).color), "0,0,0,0.750", "minor 5's strip, live")
  assertEqual(rgba(survey(m, h.label).textColor), "1,0.820,0,1")
  assertEqual(face(h.label), "GameFontNormalSmall")
  Skin:SetIgnore(OWNER, false, nil)
  assertEqual(rgba(survey(m, h.bg).color), F.tok(Skin, "obsidian", "handle.bg"), "skinned again, live")
  assertEqual(face(h.label), bodyFace(Skin, "obsidian"))
  local hud = handle(m, W, { owner = OWNER })
  Skin:SetIgnore(OWNER, true, nil)
  assertEqual(rgba(survey(m, hud.bg).color), F.tok(Skin, "obsidian", "handle.bg"), "a HUD strip keeps the skin")
end)

-- ── the drag handle's re-fit (WidgetsDragHandle minor 8, LK-09, decision D-12) ────────────────

--- A face-aware measurer: 6 px a character in any face, 8 in Obsidian's body face. Answers it and
--- the widths a strip was set to.
local function faceMeasurer(W, Skin, h)
  local fs = { text = "" }
  function fs:SetFontObject(obj) self.obj, self.path = obj, nil end
  function fs:SetFont(path) self.path, self.obj = path, nil end
  function fs:SetText(t) self.text = t end
  function fs:GetStringWidth()
    local path = self.path or (type(self.obj) == "table" and self.obj.font and self.obj.font[1])
    return #self.text * (path == bodyFace(Skin, "obsidian") and 8 or 6)
  end
  W.__DragHandleMeasurer = function() return fs end
  local widths = {}
  if h then
    local set = h.SetWidth
    rawset(h, "SetWidth", function(self, w) widths[#widths + 1] = w; return set(self, w) end)
  end
  return fs, widths
end

local REAL_MEASURER

test("skin scope: a fitted drag handle re-fits its title in the new face on a skin switch", function()
  -- red under: dhRepaint re-fonting the label and leaving the width the host measured in the old
  -- face, which truncated "Ka0s KickCD - Focus" under a wider skin (image-43..45).
  local m, Skin, W = env()
  REAL_MEASURER = REAL_MEASURER or W.__DragHandleMeasurer
  F.owner(Skin, OWNER)
  local h = handle(m, W, { owner = OWNER, label = "Focus" })
  local _, widths = faceMeasurer(W, Skin, h)
  local slack, reserve = W.DRAG_HANDLE.FIT_SLACK, h:Reserve()
  assertEqual(h:ApplyWidth(0), 5 * 6 + slack + reserve * 2, "fitted in Ka0s Default's face")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(widths[#widths], 5 * 8 + slack + reserve * 2, "re-fitted in Obsidian's")
  Skin:SetIgnore(OWNER, nil, true)
  assertEqual(widths[#widths], 5 * 6 + slack + reserve * 2, "and again under Ignore fonts")
  W.__DragHandleMeasurer = REAL_MEASURER
end)

test("skin scope: the re-fit keeps the host's last floor, and a strip never fitted is not sized", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER)
  local floored = handle(m, W, { owner = OWNER })
  local unfitted = handle(m, W, { owner = OWNER })
  local _, widths = faceMeasurer(W, Skin, floored)
  local seen = 0
  local set = unfitted.SetWidth
  rawset(unfitted, "SetWidth", function(self, w) seen = seen + 1; return set(self, w) end)
  floored:ApplyWidth(500)
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(widths[#widths], 500, "the bar's floor still wins")
  assertEqual(#widths, 2, "one host fit, one re-fit")
  assertEqual(seen, 0, "born with no width, and the widget does not give it one")
end)

test("skin scope: onRefit replaces the default re-fit, and a raise in it costs nothing else", function()
  -- AuraMaster caps its strip and shortens the name itself, so it re-places rather than re-fits.
  local m, Skin, W = env()
  F.owner(Skin, OWNER)
  local calls = {}
  local h = handle(m, W, { owner = OWNER, onRefit = function(self) calls[#calls + 1] = self end })
  local bad = handle(m, W, { owner = OWNER, onRefit = function() error("host bug") end })
  local _, widths = faceMeasurer(W, Skin, h)
  h:ApplyWidth(0)
  bad:ApplyWidth(0)
  local savedEH = m.geterrorhandler
  local errs = 0
  m.geterrorhandler = function() return function() errs = errs + 1 end end
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  m.geterrorhandler = savedEH
  assertEqual(#calls, 1, "called once for the one repaint")
  assertTrue(calls[1] == h, "with the handle")
  assertEqual(#widths, 1, "and the widget did not re-fit it as well")
  assertEqual(errs, 1, "the raise reaches the error handler")
  assertEqual(face(h.label), bodyFace(Skin, "obsidian"), "the strip is repainted all the same")
end)

test("skin scope: the measurer hangs off a shown host parked off screen, and wears the label's face", function()
  -- red under: minor 7's hidden host, on which the client may never load the face it measures.
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  local calls, create = {}, m.CreateFrame
  m.CreateFrame = function(...)
    local f = create(...)
    for _, k in ipairs({ "SetSize", "SetPoint", "SetAlpha", "Show", "Hide" }) do
      local orig = f[k]
      rawset(f, k, function(self, ...)
        local args = { k }
        for i = 1, select("#", ...) do
          local v = select(i, ...)
          args[#args + 1] = v == m.UIParent and "UIParent" or tostring(v)
        end
        calls[#calls + 1] = table.concat(args, " ")
        if type(orig) == "function" then return orig(self, ...) end
      end)
    end
    return f
  end
  local fs, host = W.__DragHandleMeasurer()
  m.CreateFrame = create
  assertTrue(fs ~= nil and host ~= nil, "a FontString and its host")
  assertEqual(table.concat(calls, "|"),
    "SetSize 1 1|SetPoint TOPRIGHT UIParent TOPLEFT -64 0|SetAlpha 1|Show", "shown, opaque, off screen")
  local _, again = W.__DragHandleMeasurer("GameFontHighlight")
  assertTrue(again == host, "one host for every face")
  -- A label the skin set by path (no font object) lends its path, size and flags.
  local h = handle(m, W, { owner = OWNER })
  local label = h.label
  rawset(label, "GetFontObject", function() return nil end)
  rawset(label, "GetFont", function() return "Fonts\\ByPath", 13, "OUTLINE" end)
  local lentFont
  rawset(fs, "SetFont", function(_, ...) lentFont = { ... } end)
  h:Measure()
  assertEqual(table.concat(lentFont or {}, ","), "Fonts\\ByPath,13,OUTLINE")
end)

-- ── review of LK-09 ──────────────────────────────────────────────────────────────────────────

test("skin scope: a host's own SetWidth after an ApplyWidth ends the default re-fit until its next fit", function()
  -- AuraMaster's placeHandle: SetWidth(cap) when capped, ApplyWidth(w) otherwise. A strip once
  -- placed uncapped and later capped must keep its cap on the next repaint.
  -- red under: dhRefit re-running ApplyWidth on __fitted alone (the repaint widens the capped strip)
  local m, Skin, W = env()
  F.owner(Skin, OWNER)
  local h = handle(m, W, { owner = OWNER, label = "A long anchor title" })
  local _, widths = faceMeasurer(W, Skin, h)
  h:ApplyWidth(0)
  h:SetWidth(40)
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(widths[#widths], 40, "the cap the host set is kept")
  assertEqual(#widths, 2, "and the repaint set no width")
  h:SetSize(41, W.DRAG_HANDLE.HEIGHT)
  h:ApplyWidth(0)
  local fitted = #widths
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertEqual(#widths, fitted + 1, "a later ApplyWidth fits again, and the repaint re-fits it")
  W.__DragHandleMeasurer = REAL_MEASURER
end)

test("skin scope: the outline setting re-fits a fitted strip as a skin switch does", function()
  -- D-12 names the outline setting as a re-fit trigger beside a switch and Ignore fonts.
  local m, Skin, W = env()
  F.owner(Skin, OWNER)
  local h = handle(m, W, { owner = OWNER, label = "Focus" })
  local _, widths = faceMeasurer(W, Skin, h)
  h:ApplyWidth(7)
  assertTrue(Skin:SetOutline(OWNER, "off"), "a change")
  assertEqual(#widths, 2, "one host fit, one re-fit")
  assertEqual(widths[2], 5 * 6 + W.DRAG_HANDLE.FIT_SLACK + h:Reserve() * 2)
  W.__DragHandleMeasurer = REAL_MEASURER
end)

test("skin scope: a label set by path that still answers its template object lends the path", function()
  -- In the client a template-built FontString keeps answering its template as its font object
  -- after SetFont(path), so lending the object first measured the skin's label in the template.
  -- red under: dhLendFont trying GetFontObject before comparing it with the label's GetFont
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  local h = handle(m, W, { owner = OWNER })
  local fs = W.__DragHandleMeasurer()
  local label = h.label
  rawset(label, "GetFontObject", function() return templateObject("GameFontNormalSmall") end)
  rawset(label, "GetFont", function() return "Fonts\\ByPath", 13, "OUTLINE" end)
  local lentFont, lentObj
  rawset(fs, "SetFont", function(_, ...) lentFont = { ... } end)
  rawset(fs, "SetFontObject", function(_, obj) lentObj = obj end)
  h:Measure()
  assertEqual(table.concat(lentFont or {}, ","), "Fonts\\ByPath,13,OUTLINE", "the path the label draws")
  assertNil(lentObj, "not the template object")
  -- An object that draws what the label draws is lent as the object.
  lentFont = nil
  rawset(label, "GetFont", function() return "Fonts\\FRIZQT__.TTF", 10, "" end)
  h:Measure()
  assertNil(lentFont)
  assertEqual(type(lentObj), "table", "the label's own object")
end)
