-- tests/test_header_buttons.lua — LibKa0s-Widgets-1.0's HeaderButtons (WidgetsHeader minor 1) and
-- LibKa0s-Core-1.0's settings-opener registry (Core minor 18), LibKa0s#86 (LK-86 of
-- Ka0sAddonsCommonTasks docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS, design section 3.7, research notes R4
-- and R9 C2, C8): one strip of header marks on every window the library draws, right-aligned, left to
-- right extras · settings · close (the owner's ruling Q3), settings opening the owning addon's
-- settings through the opener its launcher registered.
--
-- The acceptance cases at the bottom build each library window and assert the strip's order and the
-- presence of settings and close: the console, the copy window and the perf panel here; the sim
-- panel, the skin picker and the icon browser (its recorded opt-out) in their own window suites
-- (tests/test_sim_panel_render.lua, tests/test_options_skin_picker.lua, tests/test_icon_browser.lua),
-- whose benches they share: built here too, the three extra benches tipped the run's leak gate.
--
-- Smoke round 1, ruling 3 (SR-L2 of the same bundle): every title-bar control carries a tooltip, the
-- console's included, so each acceptance case also runs tests/fixture_title_tips.lua's check, every
-- control showing a non-empty tooltip on enter and hiding it on leave.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil
local mocks = T.mocks
local W, core = T.widgets, T.core
local TitleTips = dofile("tests/fixture_title_tips.lua")

local seq = 0
local function nextName(stem)
  seq = seq + 1
  return (stem or "HBHost") .. seq
end

--- A bar to build marks on, its parent a frame `Hide` reaches.
local function bar()
  local frame = mocks.CreateFrame("Frame", nil, mocks.UIParent)
  return mocks.CreateFrame("Frame", nil, frame), frame
end

local function joined(list) return table.concat(list, ",") end

--- Run `fn(calls)` with Tooltip's PlaceAttached recorded in `calls` (each { tip, el, third, n }).
local function spyAttached(fn)
  local Tip = T.tooltip
  local real = Tip.PlaceAttached
  local calls = {}
  Tip.PlaceAttached = function(tip, el, ...)
    calls[#calls + 1] = { tip = tip, el = el, third = (...), n = select("#", ...) }
    return true
  end
  local ok, err = pcall(fn, calls)
  Tip.PlaceAttached = real
  if not ok then error(err, 0) end
end

-- ── the registry (Core minor 18) ─────────────────────────────────────────────────────────────

test("header buttons: Core's registry records an opener, answers HasSettings, and OpenSettings calls it", function()
  -- red under: Core minor 17, which has no registry
  local name, seen = nextName(), {}
  assertTrue(core.RegisterSettingsOpener(name, function(...) seen[#seen + 1] = select("#", ...) end))
  assertTrue(core.HasSettings(name))
  assertTrue(core.OpenSettings(name), "an opener that ran clean answers true")
  assertEqual(#seen, 1)
  assertTrue(not core.HasSettings(nextName()), "an unknown owner has none")
  assertEqual(core.OpenSettings(nextName()), false, "and opening it answers false")
  assertEqual(core.RegisterSettingsOpener("", function() end), false, "an empty owner is refused")
  assertEqual(core.RegisterSettingsOpener(nextName(), "nope"), false, "a non-function is refused")
end)

test("header buttons: a raising opener is caught and answers false", function()
  local name = nextName()
  core.RegisterSettingsOpener(name, function() error("boom") end)
  local handled
  local saved = mocks.geterrorhandler
  mocks.geterrorhandler = function() return function(e) handled = e end end
  local ok, answer = pcall(core.OpenSettings, name)
  mocks.geterrorhandler = saved
  assertTrue(ok, "the raise never reaches the caller")
  assertEqual(answer, false)
  assertTrue(type(handled) == "string" and handled:find("boom", 1, true) ~= nil, "it reached the error handler")
end)

test("header buttons: Launcher:New registers openSettings by the addon's folder name (addonName)", function()
  -- red under: a Launcher that never calls RegisterSettingsOpener (R9 C8: the key is `name`)
  local name, buttons = nextName("HBLauncher"), {}
  T.launcher:New{ name = name, icon = "Interface\\Icons\\INV_Misc_QuestionMark", minimap = {},
    openSettings = function(button) buttons[#buttons + 1] = button end }
  assertTrue(core.HasSettings(name), "keyed by the launcher's name, which is every window's addonName")
  core.OpenSettings(name)
  assertEqual(joined(buttons), "LeftButton", "it opens what the left click opens")
end)

test("header buttons: a launcher with a different skin owner registers under both", function()
  local name, owner, n = nextName("HBLauncher"), nextName("HBSkinOwner"), 0
  T.launcher:New{ name = name, owner = owner, icon = "Interface\\Icons\\INV_Misc_QuestionMark", minimap = {},
    openSettings = function() n = n + 1 end }
  core.OpenSettings(name)
  core.OpenSettings(owner)
  assertEqual(n, 2)
end)

test("header buttons: the launcher instance gains no member", function()
  -- Nine addons parity-check the instance by name (R9 M7).
  local L = T.launcher:New{ name = nextName("HBLauncher"), icon = "x", minimap = {}, openSettings = function() end }
  local names = {}
  for k in pairs(L) do names[#names + 1] = k end
  table.sort(names)
  assertEqual(joined(names), "IsRegistered,IsShown,Object,Register,SetShown")
end)

-- ── the strip (WidgetsHeader minor 1) ────────────────────────────────────────────────────────

test("header buttons: left to right extras in their order, settings, close; offsets from the corner", function()
  local b, frame = bar()
  local hb = W.HeaderButtons(b, { owner = nextName(), frame = frame, extras = {
    { key = "a", label = "A", width = 30, onClick = function() end },
    { key = "b", label = "B", width = 40, onClick = function() end },
  } })
  assertEqual(joined(hb.order), "a,b,settings,close")
  assertTrue(hb.close ~= nil and hb.settings ~= nil and hb.extras.a ~= nil and hb.extras.b ~= nil)
  assertEqual(hb.offsets.close, -6, "PAD from the corner")
  assertEqual(hb.offsets.settings, -30, "past the 18 px close and a 6 px gap")
  assertEqual(hb.offsets.b, -54)
  assertEqual(hb.offsets.a, -100, "past B's 40 px word")
  assertEqual(hb.right[1].frame, hb.close, "S.Header's list, outermost first")
  assertEqual(hb.right[1].x, 6)
  assertTrue(frame.headerButtons == hb, "recorded on the window")
  assertEqual(W.HEADER.SIZE, 18)
  assertEqual(W.HEADER.GAP, 6)
end)

test("header buttons: close defaults to hiding the window, and close = false builds none", function()
  local b, frame = bar()
  frame:Show()
  local hb = W.HeaderButtons(b, { owner = nextName(), frame = frame })
  hb.close:__fire("OnClick")
  assertTrue(not frame:IsShown(), "the default close hides the window")
  local b2 = bar()
  local hb2 = W.HeaderButtons(b2, { owner = nextName(), close = false })
  assertNil(hb2.close)
  assertEqual(joined(hb2.order), "settings", "settings takes the corner")
  assertEqual(hb2.offsets.settings, -6)
end)

test("header buttons: the close is the host's factory, called with the owner, or one the window has", function()
  local seen
  local owner = nextName()
  local b = bar()
  local made = mocks.CreateFrame("Button", nil, b)
  local hb = W.HeaderButtons(b, { owner = owner, makeClose = function(_, onClick, name)
    seen = { onClick = onClick, name = name }
    return made
  end, close = function() end })
  assertTrue(hb.close == made)
  assertEqual(seen.name, owner, "three arguments, standalone-windows' close rule")
  local own = mocks.CreateFrame("Button", nil, b)
  local hb2 = W.HeaderButtons(bar(), { owner = owner, closeButton = own })
  assertTrue(hb2.close == own, "adopted")
end)

test("header buttons: settings opens the owner's registered opener", function()
  -- red under: a settings mark wired to nothing (the registry never read)
  local owner, n = nextName(), 0
  core.RegisterSettingsOpener(owner, function() n = n + 1 end)
  local hb = W.HeaderButtons(bar(), { owner = owner })
  hb.settings:__fire("OnClick")
  assertEqual(n, 1)
end)

test("header buttons: a window's own settings function overrides the registry", function()
  local owner, reg, own = nextName(), 0, 0
  core.RegisterSettingsOpener(owner, function() reg = reg + 1 end)
  local hb = W.HeaderButtons(bar(), { owner = owner, settings = function() own = own + 1 end })
  hb.settings:__fire("OnClick")
  assertEqual(own, 1)
  assertEqual(reg, 0)
end)

test("header buttons: hideOnSettings hides the window before settings opens", function()
  local owner, order = nextName(), {}
  local b, frame = bar()
  frame:Show()
  rawset(frame, "Hide", function() order[#order + 1] = "hide" end)
  core.RegisterSettingsOpener(owner, function() order[#order + 1] = "open" end)
  W.HeaderButtons(b, { owner = owner, frame = frame, hideOnSettings = frame }).settings:__fire("OnClick")
  assertEqual(joined(order), "hide,open")
end)

test("header buttons: a raising settings override is caught", function()
  local saved = mocks.geterrorhandler
  local handled
  mocks.geterrorhandler = function() return function(e) handled = e end end
  local hb = W.HeaderButtons(bar(), { owner = nextName(), settings = function() error("nope") end })
  local ok = pcall(hb.settings.__fire, hb.settings, "OnClick")
  mocks.geterrorhandler = saved
  assertTrue(ok, "the click does not raise")
  assertTrue(handled ~= nil, "the error handler heard it")
end)

test("header buttons: settings = false needs a reason, and records it", function()
  local ok, err = pcall(W.HeaderButtons, bar(), { owner = nextName(), settings = false })
  assertTrue(not ok and tostring(err):find("settingsOptOut", 1, true) ~= nil, tostring(err))
  local hb = W.HeaderButtons(bar(), { owner = nextName(), settings = false, settingsOptOut = "a reason" })
  assertNil(hb.settings)
  assertEqual(hb.optOut, "a reason")
  assertEqual(joined(hb.order), "close")
end)

test("header buttons: the art comes from the owner's copy, else the word, else the glyph", function()
  local hb = W.HeaderButtons(bar(), { owner = "HBArtHost", extras = {
    { key = "copy", icon = "copy", label = "Copy", width = 40 } } })
  assertTrue(hb.settings.icon ~= nil, "settings draws its art")
  assertTrue(hb.extras.copy.icon ~= nil)
  local plain = W.HeaderButtons(bar(), { extras = { { key = "copy", icon = "copy", label = "Copy", width = 40 } } })
  assertNil(plain.settings.icon, "no owner, no art")
  assertTrue(plain.settings.label ~= nil and plain.extras.copy.label ~= nil, "the glyph and the word")
  assertEqual(plain.offsets.copy, -54, "the word's own width")
end)

test("header buttons: a mark's tooltip is attached above it, and tips = false is retired", function()
  -- red under: a mark showing its tooltip at an anchor, or passing the retired "top" zone (SR-L1);
  -- and under WidgetsHeader's first cut, where `tips = false` drew none (smoke round 1, ruling 3)
  spyAttached(function(calls)
    local hb = W.HeaderButtons(bar(), { owner = nextName() })
    hb.settings:__fire("OnEnter")
    assertEqual(#calls, 1)
    assertTrue(calls[1].el == hb.settings, "placed against the mark")
    assertEqual(calls[1].n, 0, "the one rule, above the mark: no zone, no opts")
    assertEqual(hb.settings.__tip, W.HEADER_STRINGS.SETTINGS_TIP)
    hb.settings:__fire("OnLeave")
    local quiet = W.HeaderButtons(bar(), { owner = nextName(), tips = false })
    quiet.settings:__fire("OnEnter")
    assertEqual(#calls, 2, "a retired `tips = false` silences nothing")
    quiet.settings:__fire("OnLeave")
  end)
end)

-- ── the close mark's tooltip (Core minor 18 and Tooltip minor 1, SR-L2) ──────────────────────────────────────────

test("header buttons: Core's close mark says Close above itself, and an owner's words replace it", function()
  -- red under: Core.MakeCloseButton's close with no tooltip ("as it has always been")
  local owner = nextName("HBClose")
  local close = core.MakeCloseButton(bar(), function() end, owner)
  local said = TitleTips.check({ { "close", close } }, "Core's close")
  assertEqual(said.close, "Close")
  assertEqual(T.tooltip.CLOSE_STRINGS.CLOSE_TIP, "Close")
  spyAttached(function(calls)
    close:__fire("OnEnter")
    assertEqual(#calls, 1, "placed by the chrome rule")
    assertTrue(calls[1].el == close, "against the close")
    close:__fire("OnLeave")
  end)
  assertTrue(T.tooltip.SetCloseTip(owner, "Fermer"))
  assertEqual(T.tooltip.CloseTip(owner), "Fermer")
  assertEqual(TitleTips.check({ { "close", close } }, "Core's close").close, "Fermer", "read at hover time")
  local plain = core.MakeCloseButton(bar(), function() end)
  assertEqual(TitleTips.check({ { "close", plain } }, "an unnamed close").close, "Close")
  assertTrue(T.tooltip.SetCloseTip(owner, nil), "nil clears the owner's words")
  assertEqual(T.tooltip.CloseTip(owner), "Close")
  assertEqual(T.tooltip.SetCloseTip("", "x"), false, "an empty owner is refused")
end)

test("header buttons: a title-bar tooltip is drawn in the owner's gtip.title", function()
  -- red under: the close's tooltip in the tooltip's own default color
  local Skin = T.skin
  local owner = nextName("HBTipColor")
  Skin:RegisterOwner(owner)
  local want = Skin:Token(owner, "gtip.title")
  assertTrue(type(want) == "table", "the owner answers gtip.title")
  local close = core.MakeCloseButton(bar(), function() end, owner)
  TitleTips.record(function(rec)
    close:__fire("OnEnter")
    assertEqual(rec.text, "Close")
    assertTrue(rec.color and rec.color[1] == want[1] and rec.color[2] == want[2] and rec.color[3] == want[3],
      "the owner's gtip.title")
    close:__fire("OnLeave")
  end)
end)

test("header buttons: an adopted or host-made close carries the Close tooltip too", function()
  -- red under: HeaderButtons recording a close it did not build with no tooltip on it
  local adopted = mocks.CreateFrame("Button", nil, mocks.UIParent)
  local hb = W.HeaderButtons(bar(), { owner = nextName(), closeButton = adopted, settings = false,
    settingsOptOut = "a test", place = false })
  local made = W.HeaderButtons(bar(), { owner = nextName(),
    makeClose = function(parent) return mocks.CreateFrame("Button", nil, parent) end })
  local said = TitleTips.check({ { "adopted close", hb.close }, { "made close", made.close },
    { "made settings", made.settings } }, "HeaderButtons")
  assertEqual(said["adopted close"], "Close")
  assertEqual(said["made close"], "Close")
end)

-- ── the drag handle (WidgetsDragHandle minor 14; standard from minor 15) ─────────────────────

local DH = dofile("tests/fixture_draghandle.lua")

DH.test("header buttons: a drag strip carries the settings mark unless it opts out", function()
  -- Minor 15 (AF-LK-01): standard on every strip, `settings = false` the opt-out (DH.baseSpec's
  -- default). red under: minor 14, where the mark was opt-in (R4 Q4).
  local plain = W.DragHandle(mocks.UIParent, DH.baseSpec({ onClose = function() end }))
  assertNil(plain.settings, "settings = false opts out")
  local bare = DH.baseSpec({ onClose = function() end })
  bare.settings = nil
  local default = W.DragHandle(mocks.UIParent, bare)
  assertTrue(default.settings ~= nil, "no settings field at all builds it")
  local D = W.DRAG_HANDLE
  local owner, n = nextName(), 0
  core.RegisterSettingsOpener(owner, function() n = n + 1 end)
  local h = W.DragHandle(mocks.UIParent, DH.baseSpec({ onClose = function() end, settings = true, owner = owner }))
  assertTrue(h.settings ~= nil, "spec.settings = true builds it")
  assertEqual(h:Reserve(), plain:Reserve() + D.HELP_HIT + D.CLOSE_GAP, "each side keeps its frame clear")
  local p = h.settings.__points and h.settings.__points[1]
  assertTrue(p ~= nil and p.relativeTo == h.close and p.relativePoint == "LEFT", "left of the X")
  local hp = h.help.__points and h.help.__points[1]
  assertTrue(hp ~= nil and hp.relativeTo == h.settings and hp.relativePoint == "LEFT", "the '?' left of it")
  h.settings:__fire("OnClick", "LeftButton")
  assertEqual(n, 1, "the owner's registered opener")
  local own = 0
  local h2 = W.DragHandle(mocks.UIParent, DH.baseSpec({ settings = function() own = own + 1 end }))
  h2.settings:__fire("OnClick", "LeftButton")
  assertEqual(own, 1, "a function is the override")
end)

DH.test("header buttons: a drag strip's marks each carry a tooltip, the library's words without the host's", function()
  -- red under: WidgetsDragHandle minor 14's first cut, where a strip with no descriptor showed nothing
  -- on its "?", its X or its settings mark (smoke round 1, ruling 3)
  local h = W.DragHandle(mocks.UIParent, DH.baseSpec({ onClose = function() end, settings = true }))
  local said = TitleTips.check({ { "help", h.help }, { "close", h.close }, { "settings", h.settings } }, "drag strip")
  assertEqual(said.help, W.DRAG_HANDLE_STRINGS.HELP_TIP)
  assertEqual(said.close, "Close")
  assertEqual(said.settings, W.HEADER_STRINGS.SETTINGS_TIP)
  local own = W.DragHandle(mocks.UIParent, DH.baseSpec({ onClose = function() end, settings = true,
    tooltip = { title = "Buffs" }, closeTooltip = { title = "Hide the bar" },
    L = { SETTINGS_TIP = "Configure" } }))
  local mine = TitleTips.check({ { "help", own.help }, { "close", own.close }, { "settings", own.settings } }, "a host's strip")
  assertEqual(mine.help, "Buffs", "the strip's descriptor still wins on the mark")
  assertEqual(mine.close, "Hide the bar")
  assertEqual(mine.settings, "Buffs", "a host descriptor wins over the library's words")
  local worded = W.DragHandle(mocks.UIParent, DH.baseSpec({ onClose = function() end, settings = true,
    L = { SETTINGS_TIP = "Configure", CLOSE_TIP = "Hide", HELP_TIP = "Move me" } }))
  local w = TitleTips.check({ { "help", worded.help }, { "close", worded.close }, { "settings", worded.settings } }, "worded")
  assertEqual(w.help .. "," .. w.close .. "," .. w.settings, "Move me,Hide,Configure", "spec.L, rawget-keyed")
end)

-- ── acceptance: every library window ─────────────────────────────────────────────────────────

--- Assert `hb` reads ... settings, close at its right end, both present.
local function assertSettingsThenClose(hb, label)
  assertTrue(type(hb) == "table", label .. ": the window records its header marks")
  assertTrue(hb.settings ~= nil, label .. ": a settings mark")
  assertTrue(hb.close ~= nil, label .. ": a close mark")
  local n = #hb.order
  assertEqual(hb.order[n], "close", label .. ": close in the corner")
  assertEqual(hb.order[n - 1], "settings", label .. ": settings beside it")
end

test("header buttons: the debug console reads Copy, Clear, settings, close, every control with a tooltip", function()
  -- red under: DebugLogWindow minor 5's first cut, `tips = false` (research note R9 C2), superseded
  -- by smoke round 1's ruling 3: the toggle, the Diagnostics link and every mark carry one
  local owner, n = nextName("HBConsole"), 0
  core.RegisterSettingsOpener(owner, function() n = n + 1 end)
  local D = T.debuglog:New{ name = owner, addonName = owner, title = "Host", font = "Interface\\Fonts\\ARIALN.TTF",
    isEnabled = function() return false end, setEnabled = function() end, print = function() end }
  D:Show()
  local f = D._frameForTest
  assertSettingsThenClose(f.headerButtons, "console")
  assertEqual(joined(f.headerButtons.order), "copy,clear,settings,close")
  assertTrue(f.settingsButton == f.headerButtons.settings)
  local said = TitleTips.check({ { "Debug toggle", f.debugToggleBtn }, { "Diagnostics", f.diagnosticsButton },
    { "Copy", f.copyButton }, { "Clear", f.clearButton }, { "settings", f.settingsButton },
    { "close", f.closeButton } }, "console")
  local S = T.debuglog.STRINGS
  assertEqual(said["Debug toggle"], S.TOGGLE_TIP)
  assertEqual(said.Diagnostics, S.DIAGNOSTICS_TIP)
  assertEqual(said.Copy, S.COPY_TIP)
  assertEqual(said.Clear, S.CLEAR_TIP)
  assertEqual(said.settings, S.SETTINGS_TIP)
  assertEqual(said.close, "Close")
  spyAttached(function(calls)
    f.copyButton:__fire("OnEnter")
    f.debugToggleBtn:__fire("OnEnter")
    assertEqual(#calls, 2, "each placed by the chrome rule, above the control, never on the log")
    assertTrue(calls[1].el == f.copyButton and calls[2].el == f.debugToggleBtn)
    f.copyButton:__fire("OnLeave")
    f.debugToggleBtn:__fire("OnLeave")
  end)
  f.settingsButton:__fire("OnClick")
  assertEqual(n, 1, "the addon's settings, by addonName")
end)

test("header buttons: the console's tooltips are module strings a host's L overrides, rawget-keyed", function()
  -- red under: tooltips read with a plain index, or not through D:Text at all
  local L = setmetatable({ COPY_TIP = "Kopieren", TOGGLE_TIP = "Umschalten" }, { __index = function(_, k) return k end })
  local name = nextName("HBConsoleL")
  local D = T.debuglog:New{ name = name, addonName = name, title = "Host", font = "Interface\\Fonts\\ARIALN.TTF",
    isEnabled = function() return false end, setEnabled = function() end, print = function() end, L = L }
  D:Show()
  local f = D._frameForTest
  local said = TitleTips.check({ { "Copy", f.copyButton }, { "toggle", f.debugToggleBtn }, { "Clear", f.clearButton } }, "console L")
  assertEqual(said.Copy, "Kopieren")
  assertEqual(said.toggle, "Umschalten")
  assertEqual(said.Clear, T.debuglog.STRINGS.CLEAR_TIP, "an AceLocale-style __index answers no key")
end)

test("header buttons: the console's onSettings overrides the registry, on both its windows", function()
  local n = 0
  local D = T.debuglog:New{ name = nextName("HBConsole"), addonName = "HBConsoleOwn", title = "Host",
    font = "Interface\\Fonts\\ARIALN.TTF", isEnabled = function() return false end, setEnabled = function() end,
    print = function() end, onSettings = function() n = n + 1 end }
  D:Show()
  D._frameForTest.settingsButton:__fire("OnClick")
  D:ShowCopy()
  local copy = D._copyWindowForTest:GetFrame()
  copy.settingsButton:__fire("OnClick")
  assertEqual(n, 2)
end)

test("header buttons: the copy window reads settings, close, and hides itself before settings opens", function()
  local owner, order = nextName("HBCopy"), {}
  core.RegisterSettingsOpener(owner, function() order[#order + 1] = "open" end)
  local win = W.CopyWindow{ addonName = owner }
  local f = win:Show("text")
  assertSettingsThenClose(f.headerButtons, "copy window")
  assertEqual(joined(f.headerButtons.order), "settings,close")
  TitleTips.check({ { "settings", f.settingsButton }, { "close", f.closeButton } }, "copy window")
  local hide = f.Hide
  rawset(f, "Hide", function(self) order[#order + 1] = "hide"; return hide(self) end)
  f.settingsButton:__fire("OnClick")
  assertEqual(joined(order), "hide,open", "FULLSCREEN, so it hides first")
end)

test("header buttons: the perf panel reads settings, close", function()
  local owner, n = nextName("HBPerf"), 0
  core.RegisterSettingsOpener(owner, function() n = n + 1 end)
  local lc = T.lifecycle:New{ name = owner, standDown = function() end, standUp = function() end }
  local P = T.lib:New{ name = owner, addonName = owner, title = "Host", slash = "/host", sv = "HBPerfDB",
    lifecycle = lc, log = function() end, print = function() end }
  P.ShowPanel()
  local f = P.__panel()
  assertSettingsThenClose(f.headerButtons, "perf panel")
  TitleTips.check({ { "settings", f.settingsButton }, { "close", f.closeButton } }, "perf panel")
  f.settingsButton:__fire("OnClick")
  assertEqual(n, 1)
end)
