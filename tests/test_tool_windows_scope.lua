-- tests/test_tool_windows_scope.lua — the tool windows and the resize grip under the Scope switches
-- (DebugLogWindow minor 2, PerfPanel minor 11, SimPanel minor 8, WidgetsCopyWindow minor 2, Core minor
-- 14, SkinDefs minor 16's `icon.grip`; LK-06b of Ka0sAddonsCommonTasks
-- docs/2026-10-30-SKIN_LIBRARY_FOLLOWUPS, ruling R-5, decisions D-01, D-13 and D-14).
--
-- Three promises, each pinned here on the kit's paint recorder (tests/fixture_skin_paint.lua):
--
--   * IGNORE FONTS REACHES EVERY STRING A TOOL WINDOW DRAWS. The console's toggle, Diagnostics link
--     and Copy / Clear labels, the perf panel's step and command columns, and the sim panel's rows
--     and button labels drew their template's face in every skin, so the switch had nothing to act
--     on. An owned window now draws them in its skin's body face through the facade (Prototype under
--     Ka0s Default, D-13), and Ignore fonts gives each its template back. The windows are windows,
--     not the settings panel (D-01): Ignore settings panel leaves them skinned.
--   * THE SIM PANEL'S DROPDOWNS HAVE AN OWNER (finding F-2): an owned panel's scenario and size
--     pickers wear its skin, and their menu opens in it. An owner-less panel builds them as before.
--   * THE RESIZE GRIP FOLLOWS THE SKIN. `Core.MakeResizable`'s `opts.owner` names a registered skin
--     owner; its grip art is desaturated and tinted with `icon.grip`, which is `false` (the client's
--     art as drawn) under Ka0s Default and WoW Default and follows `icon.tint` in the other seven.
--     Every library window passes its owner.
--
-- A FontString built from a template answers that template as its font object here, as the client's
-- does, so "given back" is observable: the kit's base answers none. A Button's normal, highlight and
-- pushed art answer as textures here, as the client's do.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil
local F = dofile("tests/fixture_skin_paint.lua")

local OWNER, OTHER = "LootHistory", "BankLedger"
local TOOL_FILES = { "Widgets", "WidgetsCopyWindow", "DebugLog", "DebugLogDiagnostics", "DebugLogGates",
  "DebugLogWindow", "Lifecycle", "Perf", "PerfSampler", "PerfCommands", "PerfPanel", "Sim", "SimTimeline",
  "SimPanel", "SimPanelRender" }

-- Every font key resolves, so each skin's body face has a path: "Fonts\<key>".
local LSM = setmetatable({}, { __index = function(_, k)
  local key = type(k) == "string" and k:match("^font:(.+)$")
  return key and ("Fonts\\" .. key) or nil
end })

local function templateObject(name)
  return { name = name, GetName = function(self) return self.name end,
           GetFont = function() return "Fonts\\FRIZQT__.TTF", 10, "" end }
end

--- A Button's art setter and getter pair, answering a real texture of the button as the client does.
local function buttonArt(f, set, get)
  local tex
  rawset(f, set, function(self, path)
    tex = tex or self:CreateTexture()
    tex:SetTexture(path)
  end)
  rawset(f, get, function() return tex end)
end

--- A fresh client: the Skin major and the tool windows' majors, a font for every skin face,
--- template-built FontStrings that answer their template, Buttons whose art answers as textures, and
--- named frames kept in m.__named. Answers m, Skin.
local function env(noSkin)
  local files = {}
  for _, f in ipairs(noSkin and { "Core" } or F.FILES) do files[#files + 1] = f end
  for _, f in ipairs(TOOL_FILES) do files[#files + 1] = f end
  local m, Skin = F.env({ files = files, lsm = LSM })
  m.__named = {}
  local objects = {}
  local create = m.CreateFrame
  m.CreateFrame = function(kind, name, ...)
    local f = create(kind, name, ...)
    if name then m.__named[name] = f end
    local cfs = rawget(f, "CreateFontString")
    if type(cfs) == "function" then
      rawset(f, "CreateFontString", function(self, fname, layer, template)
        local fs = cfs(self, fname, layer, template)
        if type(template) == "string" then
          objects[template] = objects[template] or templateObject(template)
          fs:SetFontObject(objects[template])
        end
        return fs
      end)
    end
    if kind == "Button" then
      buttonArt(f, "SetNormalTexture", "GetNormalTexture")
      buttonArt(f, "SetHighlightTexture", "GetHighlightTexture")
      buttonArt(f, "SetPushedTexture", "GetPushedTexture")
    end
    return f
  end
  return m, Skin
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
local function bodyFace(Skin, skin) return "Fonts\\" .. Skin:ResolveSkin(skin)["font.body"] end
local function rgba(c) return F.rgba(c) end

-- ── the three windows (tests/test_tool_windows_skin.lua's builders) ──────────────────────────

local function console(m, owner)
  local enabled = false
  local D = m.LibStub("LibKa0s-DebugLog-1.0"):New{
    name = "Host" .. tostring(owner), addonName = owner, title = "Host", font = "Interface\\Fonts\\ARIALN.TTF",
    isEnabled = function() return enabled end, setEnabled = function(v) enabled = v end,
    print = function() end,
  }
  D:Show()
  return D, D._frameForTest
end

local function perf(m, owner)
  local lc = m.LibStub("LibKa0s-Lifecycle-1.0"):New{
    name = "Perf" .. tostring(owner), standDown = function() end, standUp = function() end,
  }
  local P = m.LibStub("LibKa0s-Perf-1.0"):New{
    name = "Perf" .. tostring(owner), addonName = owner, title = "Host", slash = "/host",
    sv = "ToolScopePerfDB", lifecycle = lc, log = function() end, print = function() end,
  }
  P.ShowPanel()
  return P, P.__panel()
end

local function sim(m, name)
  local Sim = m.LibStub("LibKa0s-Sim-1.0")
  local seam = Sim:NewSeam({ Probe = function() return "live" end }, { name = name })
  local s = Sim:New{
    name = name, seam = seam, slash = "/host sim",
    deliver = function() return 1 end,
    isStoodDown = function() return false end,
    scenarios = { names = { "one" }, defs = { one = { label = "One", timeline = function()
      return { { kind = "a", label = "Alpha" }, { kind = "b", label = "Beta" } }
    end } } },
    prepare = function(_, _, _, ready) ready() end,
    play = function() return "did" end,
    print = function() end,
    panel = {},
  }
  assertTrue(s:ShowPanel(), "ShowPanel")
  return s, m.__named[name .. "SimPanel"]
end

--- Every string a window's test names, as { label, fontstring, template }.
local function consoleStrings(f)
  return {
    { "the toggle", f.debugToggle, "GameFontNormalSmall" },
    { "the Diagnostics link", f.diagnosticsButton.label, "GameFontNormalSmall" },
    { "Copy", f.copyButton.label, "GameFontNormalSmall" },
    { "Clear", f.clearButton.label, "GameFontNormalSmall" },
  }
end
local function perfStrings(f)
  return {
    { "a step", f.buttons.start.text, "GameFontNormalSmall" },
    { "its command", f.buttons.start.cmd, "GameFontNormalSmall" },
  }
end
local function simStrings(f)
  return {
    { "a row", f.__rowButtons[1].text, "GameFontNormalSmall" },
    { "its command", f.__rowButtons[1].cmd, "GameFontNormalSmall" },
    { "the Start button", f.picker.start.label, "GameFontNormalSmall" },
    { "a control", f.controls.stop.label, "GameFontNormalSmall" },
  }
end

local function assertFaces(list, want, what)
  for _, s in ipairs(list) do
    assertEqual(face(s[2]), want == "template" and s[3] or want, what .. ": " .. s[1])
  end
end

--- An owned window's strings across Ka0s Default, a switch, Ignore fonts and Ignore settings panel.
local function fontCycle(build, strings, what)
  -- red under: the template's face in every skin, so Ignore fonts had nothing to give back.
  local m, Skin = env()
  F.owner(Skin, OWNER)
  local _, f = build(m, OWNER)
  local list = strings(f)
  assertFaces(list, KA0S_FACE, what .. " under Ka0s Default (D-13)")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertFaces(list, bodyFace(Skin, "obsidian"), what .. " after a switch")
  Skin:SetIgnore(OWNER, nil, true)
  assertFaces(list, "template", what .. " with Ignore fonts on")
  Skin:SetIgnore(OWNER, nil, false)
  assertFaces(list, bodyFace(Skin, "obsidian"), what .. " with Ignore fonts off again")
  Skin:SetIgnore(OWNER, true, nil)
  assertFaces(list, bodyFace(Skin, "obsidian"), what .. ": a window keeps its skin under Ignore settings panel")
end

--- An owner-less window's strings keep their template.
local function ownerless(build, strings, what)
  local m = env()
  local _, f = build(m, OTHER)
  assertFaces(strings(f), "template", what .. " without an owner")
end

-- ── Ignore fonts reaches every string ────────────────────────────────────────────────────────

test("tool windows scope: an owned console's labels take the skin's face and obey Ignore fonts", function()
  fontCycle(console, consoleStrings, "the console")
  ownerless(console, consoleStrings, "the console")
end)

test("tool windows scope: an owned perf panel's step and command columns take the skin's face", function()
  fontCycle(perf, perfStrings, "the perf panel")
  ownerless(perf, perfStrings, "the perf panel")
end)

test("tool windows scope: an owned sim panel's rows and button labels take the skin's face", function()
  fontCycle(sim, simStrings, "the sim panel")
  ownerless(sim, simStrings, "the sim panel")
end)

test("tool windows scope: the console's Diagnostics link is measured in the face it wears", function()
  -- red under: the link sized for the template's face, so a wider skin face ran past its button.
  local m, Skin = env()
  F.owner(Skin, OWNER)
  local _, f = console(m, OWNER)
  local fs, b = f.diagnosticsButton.label, f.diagnosticsButton
  local widths = { [KA0S_FACE] = 90, [bodyFace(Skin, "obsidian")] = 70, GameFontNormalSmall = 60 }
  rawset(fs, "GetStringWidth", function() return widths[face(fs)] end)
  local width
  rawset(b, "SetWidth", function(_, w) width = w end)   -- the kit records no width: spy on it
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(width, 70, "a switch re-measures the link")
  Skin:SetIgnore(OWNER, nil, true)
  assertEqual(width, 60, "and Ignore fonts too")
end)

-- ── the sim panel's dropdowns (F-2) ──────────────────────────────────────────────────────────

test("tool windows scope: an owned sim panel's dropdowns wear its skin", function()
  -- red under: W.Dropdown built with no owner, Widgets minor 15's literals in every skin.
  local m, Skin = env()
  F.owner(Skin, OWNER, "azeroth")
  local _, f = sim(m, OWNER)
  for _, key in ipairs({ "scenario", "size" }) do
    local dd = f.picker[key]
    assertEqual(dd.__owner, OWNER, key .. ": the panel's owner")
    assertTrue(Skin.painted[dd] ~= nil and Skin.painted[dd].owner == OWNER, key .. ": painted for it")
  end
  assertEqual(rgba(m.__paint(f.picker.scenario.text).textColor),
    F.rgba({ unpack(Skin:ResolveSkin("azeroth")["input.text"], 1, 3) }), "the label in input.text")
end)

test("tool windows scope: an owner-less sim panel's dropdowns are built as before", function()
  local m, Skin = env()
  local _, f = sim(m, OTHER)
  assertNil(f.picker.scenario.__owner, "no owner")
  assertNil(Skin.painted[f.picker.scenario], "nothing painted")
end)

-- ── the resize grip ──────────────────────────────────────────────────────────────────────────

local GRIP_ART = { "GetNormalTexture", "GetHighlightTexture", "GetPushedTexture" }

--- "desaturated r,g,b,a" or "art" for a grip's three textures, which must agree.
local function gripLook(m, grip)
  local looks = {}
  for _, get in ipairs(GRIP_ART) do
    local tex = grip[get](grip)
    assertTrue(type(tex) == "table", get)
    local p = m.__paint(tex)
    looks[#looks + 1] = tex:IsDesaturated() and ("desaturated " .. rgba(p.vertex)) or
      (p.vertex == nil and "art" or ("tinted " .. rgba(p.vertex)))
  end
  assertEqual(looks[2], looks[1], "the highlight matches the normal art")
  assertEqual(looks[3], looks[1], "the pushed art matches too")
  return looks[1]
end

local function tintOf(Skin, skin)
  local c = Skin:ResolveSkin(skin)["icon.tint"]
  return "desaturated " .. F.rgba({ c[1], c[2], c[3], 1 })
end

test("tool windows scope: MakeResizable's owner tints the grip with icon.grip, live", function()
  -- red under: the client's art untinted in every skin, and no opts.owner.
  local m, Skin = env()
  F.owner(Skin, OWNER)
  local core = m.LibStub("LibKa0s-Core-1.0")
  local frame = m.CreateFrame("Frame", nil, m.UIParent)
  frame:SetSize(200, 100)
  local grip = core.MakeResizable(frame, { owner = OWNER })
  assertEqual(gripLook(m, grip), "art", "Ka0s Default draws the client's art as drawn")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(gripLook(m, grip), tintOf(Skin, "obsidian"), "Obsidian tints it icon.tint")
  Skin:SetChoice(OWNER, "ka0s", "wow")
  local tex = grip:GetNormalTexture()
  assertEqual(tex:IsDesaturated(), false, "WoW Default gives the art its own color back")
  assertEqual(rgba(m.__paint(tex).vertex), "1,1,1,1", "untinted")
  Skin:SetChoice(OWNER, "ka0s", "ember")
  assertEqual(gripLook(m, grip), tintOf(Skin, "ember"), "Ember")
  Skin:SetIgnore(OWNER, true, true)
  assertEqual(gripLook(m, grip), tintOf(Skin, "ember"), "a window's grip: neither switch applies")
end)

test("tool windows scope: a grip without a registered owner is drawn as before", function()
  local m, Skin = env()
  F.owner(Skin, OWNER, "obsidian")
  local core = m.LibStub("LibKa0s-Core-1.0")
  for _, opts in ipairs({ {}, { owner = OTHER }, { owner = 42 } }) do
    local frame = m.CreateFrame("Frame", nil, m.UIParent)
    frame:SetSize(200, 100)
    assertEqual(gripLook(m, core.MakeResizable(frame, opts)), "art", tostring(opts.owner))
  end
  local m2 = env(true)
  local frame = m2.CreateFrame("Frame", nil, m2.UIParent)
  frame:SetSize(200, 100)
  assertEqual(gripLook(m2, m2.LibStub("LibKa0s-Core-1.0").MakeResizable(frame, { owner = OWNER })), "art",
    "a client with no Skin major")
end)

test("tool windows scope: every library window passes its owner to its grip", function()
  local m, Skin = env()
  F.owner(Skin, OWNER, "glass")
  local want = tintOf(Skin, "glass")
  local D, c = console(m, OWNER)
  assertEqual(gripLook(m, c.resizeGrip), want, "the console")
  D:ShowCopy()
  assertEqual(gripLook(m, D._copyFrameForTest.resizeGrip), want, "its copy window")
  local _, p = perf(m, OWNER)
  assertEqual(gripLook(m, p.resizeGrip), want, "the perf panel")
  local _, s = sim(m, OWNER)
  assertEqual(gripLook(m, s.resizeGrip), want, "the sim panel")
  local W = m.LibStub("LibKa0s-Widgets-1.0")
  local cw = W.CopyWindow({ name = "HostCopy", title = "Copy", addonName = OWNER })
  cw:Show("text")
  assertEqual(gripLook(m, m.__named.HostCopy.resizeGrip), want, "a host's copy window")
end)

-- ── the token ────────────────────────────────────────────────────────────────────────────────

test("tool windows scope: icon.grip is the client's art in Ka0s Default and WoW Default, icon.tint elsewhere",
  function()
  -- `false` ("none": the art as drawn) resolves to nil, as every nilable color does.
  local _, Skin = env()
  for _, def in ipairs(Skin:Skins()) do
    local t = Skin:ResolveSkin(def.key)
    if def.key == "ka0s" or def.key == "wow" then
      assertNil(t["icon.grip"], def.key)
    else
      assertEqual(rgba(t["icon.grip"]), rgba(t["icon.tint"]), def.key .. " follows icon.tint")
    end
  end
end)
