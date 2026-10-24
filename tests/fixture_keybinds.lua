-- tests/fixture_keybinds.lua -- the bench tests/test_options_keybinds.lua drives the Keybindings tab
-- with (OptionsKeybinds.lua minor 2, options-ui-§20).
--
-- WHAT IT BUILDS. An Options instance from tests/fixture_options.lua with one page drawn by a
-- renderer the case hands in, the kit's binding mock (testkit/mock_bindings.lua, revision 42)
-- installed on the shared mock, and two recorders:
--
--   * A WINDOW RECORDER, modeled on tests/test_options_combat.lua's (which is not edited), that
--     notes ANY touch of SettingsPanel or KeybindListener -- a read, a call, a write -- and any call
--     of HideUIPanel, ToggleGameMenu, Settings.OpenToCategory, Settings.SelectCharacterBindings or
--     Settings.SelectAccountBindings, in or out of combat, and fails the case on the first one.
--     The tab never drives Blizzard's settings window (options-ui-§20); combat's recorder only
--     asks that of combat, this one asks it of every moment.
--   * A CLICK RECORDER on every AceGUI Button created during the case: the frame's last
--     RegisterForClicks, so a case can see that a released slot leaves with nothing of ours
--     (options-ui-§19). The kit's frames answer RegisterForClicks with the frame and remember
--     nothing, so it is rawset per frame here.
--
-- The listener (lib.__keybindListener) is library-level and lives for the process, so its switches
-- are instrumented once, in place, the first time a bench asks for it.
--
-- Every name the mock filled is taken back off after the case, as the model suite does, so no later
-- suite sees a binding API it did not ask for.

local T = _G.LK_TEST
local mocks = T.mocks
local lib = T.options
local Fixture = dofile("tests/fixture_options.lua")
local install = dofile("tests/_kit/mock_bindings.lua")

local Bench = {}

Bench.TOGGLE = "LKTEST_TOGGLE"
Bench.SECOND = "LKTEST_SECOND"
Bench.TOGGLE_NAME = "Toggle test window"
Bench.BINDINGS = {
  { command = Bench.TOGGLE, tooltip = "Shows or hides the test window." },
  { command = Bench.SECOND, tooltip = "Does the second thing." },
}

local FILLED = {
  "GetBindingKey", "GetBindingAction", "SetBinding", "SaveBindings", "GetCurrentBindingSet",
  "LoadBindings", "GetBindingText", "GetBindingName", "NOT_BOUND", "KEY_BOUND",
  "KEY_UNBOUND_ERROR", "ACCOUNT_BINDINGS", "CHARACTER_BINDINGS", "IsAltKeyDown",
  "IsControlKeyDown", "IsShiftKeyDown", "IsMetaKeyDown", "setModifiers", "bindKey",
  "clearBindings", "GetConvertedKeyOrButton", "IsKeyPressIgnoredForBinding",
  "CreateKeyChordStringUsingMetaKeyState", "__modifiers",
  "BINDING_NAME_" .. Bench.TOGGLE, "BINDING_NAME_LKTEST_OTHER",
  "SettingsPanel", "KeybindListener", "HideUIPanel", "ToggleGameMenu",
}
local SETTINGS_FNS = { "OpenToCategory", "SelectCharacterBindings", "SelectAccountBindings" }

--- The window recorder: every touch of the names options-ui-§20 says the tab never touches.
local function installRecorder(violations)
  local function note(what) violations[#violations + 1] = what end
  local function proxy(name)
    return setmetatable({}, {
      __index = function(_, k)
        note("read " .. name .. "." .. tostring(k))
        return function() note("call " .. name .. ":" .. tostring(k) .. "()") end
      end,
      __newindex = function(_, k) note("write " .. name .. "." .. tostring(k)) end,
    })
  end
  local function guarded(name)
    return function() note(name .. "()"); error(name .. "() called by the Keybindings tab", 2) end
  end
  mocks.SettingsPanel = proxy("SettingsPanel")
  mocks.KeybindListener = proxy("KeybindListener")
  mocks.HideUIPanel = guarded("HideUIPanel")
  mocks.ToggleGameMenu = guarded("ToggleGameMenu")
  for _, k in ipairs(SETTINGS_FNS) do mocks.Settings[k] = guarded("Settings." .. k) end
end

--- The click recorder: each Button's frame remembers the last RegisterForClicks it was told.
local function wrapCreate(aceGUI)
  local original = aceGUI.Create
  aceGUI.Create = function(self, wtype)
    local w = original(self, wtype)
    if wtype == "Button" and type(w.frame) == "table" then
      rawset(w.frame, "RegisterForClicks", function(f, ...)
        f.__clicks = table.concat({ ... }, ",")
        return f
      end)
    end
    return w
  end
  return function() aceGUI.Create = original end
end

--- The listener, its switches recorded in place (once: it is library-level).
function Bench.listener()
  local f = lib.__keybindEnsureListener and lib.__keybindEnsureListener()
  T.assertTrue(f ~= nil, "the library owns one capture listener (options-ui-§20)")
  if not rawget(f, "__kbInstrumented") then
    rawset(f, "__kbInstrumented", true)
    rawset(f, "EnableKeyboard", function(s, v) s.__keyboard = v; return s end)
    rawset(f, "EnableMouse", function(s, v) s.__mouse = v; return s end)
    rawset(f, "EnableMouseWheel", function(s, v) s.__wheel = v; return s end)
    rawset(f, "SetParent", function(s, p) s.__kbParent = p; return s end)
    rawset(f, "SetAllPoints", function(s, p) s.__kbAll = p or true; return s end)
    rawset(f, "ClearAllPoints", function(s) s.__kbAll = nil; return s end)
    rawset(f, "SetPropagateKeyboardInput", function(s, v) s.__propagates = v; return s end)
  end
  return f
end

--- One case with the binding mock and both recorders installed, everything put back however the
--- case ends, and no window touch allowed.
function Bench.case(name, fn)
  T.test(name, function()
    local before = {}
    for _, k in ipairs(FILLED) do before[k] = mocks[k] end
    local beforeSettings = {}
    for _, k in ipairs(SETTINGS_FNS) do beforeSettings[k] = mocks.Settings[k] end
    local hadEnum, hadSet = mocks.Enum, type(mocks.Enum) == "table" and mocks.Enum.BindingSet
    local savedCombat, savedLock = mocks.InCombatLockdown, lib.__combatLocked
    local savedShot = mocks.Screenshot
    install(mocks)
    mocks.clearBindings()
    mocks["BINDING_NAME_" .. Bench.TOGGLE] = Bench.TOGGLE_NAME
    local violations = {}
    installRecorder(violations)
    local unwrap = wrapCreate(mocks.__libs["AceGUI-3.0"])
    Bench.listener()
    Bench.resetSync()
    local ok, err = pcall(fn)
    if lib.__keybindStop then lib.__keybindStop(false) end
    Bench.resetSync()
    unwrap()
    for _, k in ipairs(FILLED) do mocks[k] = before[k] end
    for _, k in ipairs(SETTINGS_FNS) do mocks.Settings[k] = beforeSettings[k] end
    if hadEnum == nil then mocks.Enum = nil
    elseif not hadSet then mocks.Enum.BindingSet = nil end
    mocks.InCombatLockdown, lib.__combatLocked, mocks.Screenshot = savedCombat, savedLock, savedShot
    if not ok then error(err, 0) end
    T.assertEqual(#violations, 0,
      "the Keybindings tab touched Blizzard's settings window: " .. table.concat(violations, "; "))
  end)
end

--- The sync state (OptionsKeybinds.lua minor 3) back to empty: no live row, no repaint pending,
--- and UPDATE_BINDINGS let go of. A row a case drew stays "on screen" in the harness (the kit's
--- ScrollFrame forgets its children rather than releasing them), so without this one case's rows
--- would keep the frame registered into the next case, and into every later suite.
function Bench.resetSync()
  if type(lib.__keybindLive) == "table" then
    for row in pairs(lib.__keybindLive) do lib.__keybindLive[row] = nil end
  end
  lib.__keybindRepaintPending = nil
  if lib.__syncKeybindEvents then lib.__syncKeybindEvents() end
end

local seq = 0

--- A host and one page whose renderer is `render(O, ctx)`, shown, so it is drawn and on screen.
--- Answers O, rec, ctx.
function Bench.page(render)
  local O, rec = Fixture.new()
  seq = seq + 1
  local ctx = O.CreatePanel("KeybindPage" .. seq, "Keybinds " .. seq, { pageKey = "general" })
  O.SetRenderer(ctx, function(c)
    O.ClearScroll(c)
    render(O, c)
  end)
  ctx.panel:Show()
  ctx.panel:__fire("OnShow")
  return O, rec, ctx
end

--- A page that draws O.KeybindRows(ctx, spec); answers O, rec, ctx and a getter for the rows.
function Bench.rowsPage(spec)
  local rows
  local O, rec, ctx = Bench.page(function(O, c)
    rows = O.KeybindRows(c, spec or { bindings = Bench.BINDINGS })
  end)
  return O, rec, ctx, function() return rows end
end

--- Every widget the page's scroll holds, depth first.
function Bench.widgets(ctx)
  return ctx.scroll and Fixture.flatten(ctx.scroll) or {}
end

--- The widgets directly in the scroll, in order.
function Bench.top(ctx)
  return ctx.scroll and ctx.scroll.children or {}
end

--- The set line: the one widget whose text begins "Saved for:".
function Bench.setLine(ctx)
  for _, w in ipairs(Bench.widgets(ctx)) do
    if type(w.text) == "string" and w.text:find("Saved for:", 1, true) == 1 then return w.text end
  end
end

--- The combat edges, through the library's one combat frame, as tests/test_options_combat.lua
--- drives them.
function Bench.enterCombat()
  local f = lib.__combatFrame
  T.assertTrue(f ~= nil, "the library owns one combat event frame")
  f:__fire("OnEvent", "PLAYER_REGEN_DISABLED")
  mocks.InCombatLockdown = function() return true end
end

function Bench.leaveCombat()
  mocks.InCombatLockdown = function() return false end
  lib.__combatFrame:__fire("OnEvent", "PLAYER_REGEN_ENABLED")
end

--- The listener's three scripts, as the client would run them.
function Bench.key(key) local f = Bench.listener(); return f:GetScript("OnKeyDown")(f, key) end
function Bench.mouse(button) local f = Bench.listener(); return f:GetScript("OnMouseDown")(f, button) end
function Bench.wheel(delta) local f = Bench.listener(); return f:GetScript("OnMouseWheel")(f, delta) end

--- A click on a slot or on Clear, through the AceGUI fake's callback.
function Bench.click(widget, button) return widget:__fire("OnClick", button or "LeftButton") end

function Bench.keys(command)
  return table.concat({ mocks.GetBindingKey(command) }, ",")
end

return Bench
