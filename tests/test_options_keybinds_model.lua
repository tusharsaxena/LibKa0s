-- tests/test_options_keybinds_model.lua -- LibKa0s-Options-1.0's OptionsKeybinds.lua (minor 1): the
-- key binding model under the Keybindings tab, headless. lib.__keybindSet / lib.__keybindClear write
-- through the client's binding API with Blizzard's slot semantics (RebindKeysInOrder), refuse in
-- combat before calling any of it, and save once with GetCurrentBindingSet(); lib.__keyChord turns
-- a key press into the client's chord string; lib.__keybindSetName names the set in force.
--
-- Every case installs the kit's binding mock (testkit/mock_bindings.lua, revision 42) on the shared
-- mock and takes every name it filled back off afterwards, so no later suite sees a binding API it
-- did not ask for.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local mocks = T.mocks
local lib = T.options

local install = dofile("tests/_kit/mock_bindings.lua")

local FILLED = {
  "GetBindingKey", "GetBindingAction", "SetBinding", "SaveBindings", "GetCurrentBindingSet",
  "LoadBindings", "GetBindingText", "GetBindingName", "NOT_BOUND", "KEY_BOUND",
  "KEY_UNBOUND_ERROR", "ACCOUNT_BINDINGS", "CHARACTER_BINDINGS", "IsAltKeyDown",
  "IsControlKeyDown", "IsShiftKeyDown", "IsMetaKeyDown", "setModifiers", "bindKey",
  "clearBindings", "GetConvertedKeyOrButton", "IsKeyPressIgnoredForBinding",
  "CreateKeyChordStringUsingMetaKeyState", "__modifiers",
}

--- Run `fn` with the binding mock installed on the shared mock, then take it back off.
local function withBindings(opts, fn)
  if fn == nil then fn, opts = opts, nil end
  local before = {}
  for _, name in ipairs(FILLED) do before[name] = mocks[name] end
  local hadEnum, hadSet = mocks.Enum, type(mocks.Enum) == "table" and mocks.Enum.BindingSet
  local savedCombat, savedLock = mocks.InCombatLockdown, lib.__combatLocked
  install(mocks, opts)
  mocks.clearBindings()
  local ok, err = pcall(fn)
  for _, name in ipairs(FILLED) do mocks[name] = before[name] end
  if hadEnum == nil then mocks.Enum = nil
  elseif not hadSet then mocks.Enum.BindingSet = nil end
  mocks.InCombatLockdown, lib.__combatLocked = savedCombat, savedLock
  if not ok then error(err, 0) end
end

local function keys(command)
  return table.concat({ mocks.GetBindingKey(command) }, ",")
end

local function count(t) return #t end

-- ── the version ──────────────────────────────────────────────────────────────────────────────

test("keybinds: OptionsKeybinds is at minor 4 or later, paired on an Options shell at 30 or later", function()
  assertTrue(lib.MODULES.OptionsKeybinds >= 4, "OptionsKeybinds minor " .. tostring(lib.MODULES.OptionsKeybinds))
  assertEqual(lib.__keybindsMinor, lib.MODULES.OptionsKeybinds)
  assertTrue(lib.MINOR >= 30, "Options.lua minor " .. tostring(lib.MINOR))
  assertEqual(lib.__keybindsShellMinor, lib.MINOR)
  assertEqual(type(lib.__AttachKeybinds), "function")
end)

-- Twelve components when OptionsKeybinds arrived; OptionsAppearance.lua (Options minor 33) made a
-- thirteenth, so the case pins OptionsKeybinds' place and one component per file.
test("keybinds: the Options version key has a component per file, OptionsKeybinds the twelfth", function()
  local files
  for _, row in ipairs(T.majors) do
    if row.major == "LibKa0s-Options-1.0" then files = row.files end
  end
  assertTrue(#files >= 12, "tests/majors.lua's Options row")
  assertEqual(files[12], "OptionsKeybinds", "the twelfth file")
  local parts = {}
  for i, f in ipairs(files) do parts[i] = tostring(lib.MODULES[f]) end
  local key = table.concat(parts, ".")
  local n = select(2, key:gsub("%.", "")) + 1
  assertEqual(n, #files, "key " .. key)
end)

-- ── the strings ──────────────────────────────────────────────────────────────────────────────

test("keybinds: KEYBIND_STRINGS carries the exact default words, all ASCII", function()
  local S = lib.KEYBIND_STRINGS
  assertEqual(S.TAB_LABEL, "Keybindings")
  assertEqual(S.TAB_TIP, "The same key bindings as Options -> Keybindings. A key set here shows there, and the other way round.")
  assertEqual(S.INTRO, "Key bindings are saved by the game, not in your profile. Defaults and Reset all settings leave them alone.")
  assertEqual(S.UNCHANGED, "Key bindings are not changed.")
  assertEqual(S.KEY, "Key binding")
  assertNil(S.KEY1, "minor 4: one key button, no slot words")
  assertNil(S.KEY2)
  assertEqual(S.KEY_MORE, "%s +%d")
  assertEqual(S.KEYS_ALL, "Keys: %s")
  assertEqual(S.KEYS_OTHER, "The others were set on the game's Key Bindings page (Options -> Keybindings).")
  assertEqual(S.CLEAR, "Clear")
  assertEqual(S.CLEAR_TIP, "Remove every key from this action.")
  assertEqual(S.SLOT_TIP, "Click, then press a key or a mouse button to bind it. Esc cancels. Right-click removes this key.")
  assertEqual(S.LISTENING, "Press a key...")
  assertEqual(S.SET_ACCOUNT, "Saved for: all characters")
  assertEqual(S.SET_CHARACTER, "Saved for: this character only")
  assertEqual(S.SET_HOW, "(Options -> Keybindings -> Character Specific Keybindings)")
  assertEqual(S.COMBAT, "Key bindings can be changed after combat.")
  assertEqual(S.FAILED, "That key could not be bound.")
  assertEqual(S.CLEARED, "Key removed.")
  assertEqual(S.UNAVAILABLE, "Key bindings cannot be set here on this client. Use Options -> Keybindings.")
  for k, v in pairs(S) do
    assertFalse(v:find("[\128-\255]") ~= nil, k .. " is ASCII")
  end
end)

test("keybinds: the client's own strings win where they exist, with the library's fallbacks", function()
  local saved = { mocks.NOT_BOUND, mocks.KEY_BOUND, mocks.KEY_UNBOUND_ERROR }
  mocks.NOT_BOUND, mocks.KEY_BOUND, mocks.KEY_UNBOUND_ERROR = nil, nil, nil
  assertEqual(lib.__keybindClientString("NOT_BOUND"), "Not bound")
  assertEqual(lib.__keybindClientString("KEY_BOUND"), "Key bound.")
  assertEqual(lib.__keybindClientString("KEY_UNBOUND_ERROR"), "%s is now unbound.")
  mocks.NOT_BOUND = "Client Not Bound"
  assertEqual(lib.__keybindClientString("NOT_BOUND"), "Client Not Bound")
  mocks.NOT_BOUND, mocks.KEY_BOUND, mocks.KEY_UNBOUND_ERROR = saved[1], saved[2], saved[3]
end)

-- ── __keybindAvailable ───────────────────────────────────────────────────────────────────────

test("keybinds: the API is available only when all five binding functions exist", function()
  withBindings(function()
    assertTrue(lib.__keybindAvailable())
    mocks.SaveBindings = nil
    assertFalse(lib.__keybindAvailable())
  end)
  withBindings(function()
    mocks.SetBinding = nil
    assertFalse(lib.__keybindAvailable())
    local ok, _, _, reason = lib.__keybindSet("CMD_A", 1, "F")
    assertFalse(ok)
    assertEqual(reason, "unavailable")
    local cok, creason = lib.__keybindClear("CMD_A")
    assertFalse(cok)
    assertEqual(creason, "unavailable")
  end)
end)

-- ── __keybindSet: slots ──────────────────────────────────────────────────────────────────────

test("keybinds: slot 1 on a keyless command binds the key and saves once", function()
  withBindings(function()
    local ok, displaced, unbound, reason = lib.__keybindSet("CMD_A", 1, "F")
    assertTrue(ok)
    assertNil(displaced); assertNil(reason)
    assertFalse(unbound == true, "nothing was displaced")
    assertEqual(keys("CMD_A"), "F")
    assertEqual(count(mocks.__savedBindingSets), 1)
  end)
end)

test("keybinds: slot 2 on a keyless command becomes slot 1", function()
  withBindings(function()
    assertTrue((lib.__keybindSet("CMD_A", 2, "G")))
    assertEqual(keys("CMD_A"), "G")
  end)
end)

test("keybinds: slot 1 on a one-key command replaces that key, which is left free", function()
  withBindings(function()
    mocks.bindKey("F", "CMD_A")
    assertTrue((lib.__keybindSet("CMD_A", 1, "G")))
    assertEqual(keys("CMD_A"), "G")
    assertEqual(mocks.GetBindingAction("F"), "", "slot 1's old key is unbound")
  end)
end)

test("keybinds: slot 2 on a one-key command keeps the old key first", function()
  withBindings(function()
    mocks.bindKey("F", "CMD_A")
    assertTrue((lib.__keybindSet("CMD_A", 2, "G")))
    assertEqual(keys("CMD_A"), "F,G")
  end)
end)

test("keybinds: on a two-key command the slot's old key is unbound and the order kept", function()
  withBindings(function()
    mocks.bindKey("F", "CMD_A"); mocks.bindKey("G", "CMD_A")
    assertTrue((lib.__keybindSet("CMD_A", 1, "H")))
    assertEqual(keys("CMD_A"), "H,G")
    assertEqual(mocks.GetBindingAction("F"), "", "slot 1's old key is free")
  end)
  withBindings(function()
    mocks.bindKey("F", "CMD_A"); mocks.bindKey("G", "CMD_A")
    assertTrue((lib.__keybindSet("CMD_A", 2, "H")))
    assertEqual(keys("CMD_A"), "F,H")
    assertEqual(mocks.GetBindingAction("G"), "", "slot 2's old key is free")
  end)
end)

test("keybinds: the same key in the same slot is a no-op that writes and saves nothing", function()
  withBindings(function()
    mocks.bindKey("F", "CMD_A"); mocks.bindKey("G", "CMD_A")
    local ok, displaced = lib.__keybindSet("CMD_A", 2, "G")
    assertTrue(ok); assertNil(displaced)
    assertEqual(count(mocks.__bindingWrites), 0)
    assertEqual(count(mocks.__savedBindingSets), 0)
    assertEqual(keys("CMD_A"), "F,G")
  end)
end)

test("keybinds: moving a key from slot 2 to slot 1 of the same command swaps the two", function()
  withBindings(function()
    mocks.bindKey("F", "CMD_A"); mocks.bindKey("G", "CMD_A")
    local ok, displaced = lib.__keybindSet("CMD_A", 1, "G")
    assertTrue(ok)
    assertNil(displaced, "a command's own key is never displaced from it")
    assertEqual(keys("CMD_A"), "G,F")
  end)
end)

-- ── __keybindSet: conflicts ──────────────────────────────────────────────────────────────────

test("keybinds: taking another action's only key names it, left keyless", function()
  withBindings(function()
    mocks.bindKey("F", "CMD_B")
    local ok, displaced, unbound = lib.__keybindSet("CMD_A", 1, "F")
    assertTrue(ok)
    assertEqual(displaced, "CMD_B")
    assertTrue(unbound, "CMD_B has no key left")
    assertEqual(keys("CMD_A"), "F")
    assertNil(mocks.GetBindingKey("CMD_B"))
  end)
end)

test("keybinds: taking one of another action's two keys names it, not left keyless", function()
  withBindings(function()
    mocks.bindKey("F", "CMD_B"); mocks.bindKey("G", "CMD_B")
    local ok, displaced, unbound = lib.__keybindSet("CMD_A", 1, "F")
    assertTrue(ok)
    assertEqual(displaced, "CMD_B")
    assertFalse(unbound, "CMD_B keeps G")
    assertEqual(keys("CMD_B"), "G")
  end)
end)

-- ── __keybindSet: a failed write ─────────────────────────────────────────────────────────────

test("keybinds: a failed SetBinding restores every old binding, the displaced action's too", function()
  withBindings(function()
    mocks.bindKey("F", "CMD_A"); mocks.bindKey("G", "CMD_A"); mocks.bindKey("H", "CMD_B")
    -- Fail the rebind of slot 2's key (G), after the new key (H) has already been bound.
    local realSet, failed = mocks.SetBinding, false
    mocks.SetBinding = function(key, cmd)
      if not failed and key == "G" and cmd == "CMD_A" then failed = true; return false end
      return realSet(key, cmd)
    end
    local ok, displaced, unbound, reason = lib.__keybindSet("CMD_A", 1, "H")
    mocks.SetBinding = realSet
    assertTrue(failed, "the seam fired")
    assertFalse(ok)
    assertNil(displaced); assertNil(unbound)
    assertEqual(reason, "failed")
    assertEqual(keys("CMD_A"), "F,G", "the command's keys are back in order")
    assertEqual(keys("CMD_B"), "H", "the displaced action has its key back")
    assertEqual(count(mocks.__savedBindingSets), 0, "nothing is saved")
  end)
end)

test("keybinds: a failed SetBinding on a keyless command leaves it keyless and saves nothing", function()
  withBindings(function()
    mocks.__bindingFailNext = "F"
    local ok, _, _, reason = lib.__keybindSet("CMD_A", 1, "F")
    assertFalse(ok)
    assertEqual(reason, "failed")
    assertNil(mocks.GetBindingKey("CMD_A"))
    assertEqual(mocks.GetBindingAction("F"), "")
    assertEqual(count(mocks.__savedBindingSets), 0)
  end)
end)

-- ── the save ─────────────────────────────────────────────────────────────────────────────────

test("keybinds: SaveBindings runs exactly once, with GetCurrentBindingSet(), for sets 1 and 2", function()
  for _, set in ipairs({ 1, 2 }) do
    withBindings(function()
      mocks.__bindingSet = set
      mocks.bindKey("F", "CMD_A")
      assertTrue((lib.__keybindSet("CMD_A", 2, "G")))
      assertEqual(count(mocks.__savedBindingSets), 1)
      assertEqual(mocks.__savedBindingSets[1], set)
      assertTrue((lib.__keybindClear("CMD_A")))
      assertEqual(count(mocks.__savedBindingSets), 2)
      assertEqual(mocks.__savedBindingSets[2], set)
    end)
  end
end)

-- ── combat ───────────────────────────────────────────────────────────────────────────────────

local function assertNothingCalled()
  assertEqual(count(mocks.__bindingWrites), 0, "no SetBinding")
  assertEqual(count(mocks.__bindingRefusals), 0, "not even a refused one")
  assertEqual(count(mocks.__savedBindingSets), 0, "no SaveBindings")
end

test("keybinds: under the combat lock set and clear refuse 'combat' and call no binding API", function()
  withBindings(function()
    mocks.bindKey("F", "CMD_A")
    lib.__combatLocked = true
    local ok, displaced, unbound, reason = lib.__keybindSet("CMD_A", 1, "G")
    assertFalse(ok); assertNil(displaced); assertNil(unbound)
    assertEqual(reason, "combat")
    local cok, creason = lib.__keybindClear("CMD_A")
    assertFalse(cok)
    assertEqual(creason, "combat")
    assertNothingCalled()
    assertEqual(keys("CMD_A"), "F")
  end)
end)

test("keybinds: under InCombatLockdown alone set and clear refuse 'combat' too", function()
  withBindings(function()
    mocks.bindKey("F", "CMD_A")
    lib.__combatLocked = false
    mocks.InCombatLockdown = function() return true end
    local ok, _, _, reason = lib.__keybindSet("CMD_A", 1, "G")
    assertFalse(ok); assertEqual(reason, "combat")
    local cok, creason = lib.__keybindClear("CMD_A", 1)
    assertFalse(cok); assertEqual(creason, "combat")
    assertNothingCalled()
  end)
end)

-- ── __keybindClear ───────────────────────────────────────────────────────────────────────────

test("keybinds: clear slot 1 leaves slot 2, clear slot 2 leaves slot 1, nil clears both", function()
  withBindings(function()
    mocks.bindKey("F", "CMD_A"); mocks.bindKey("G", "CMD_A")
    assertTrue((lib.__keybindClear("CMD_A", 1)))
    assertEqual(keys("CMD_A"), "G")
    assertEqual(count(mocks.__savedBindingSets), 1)
  end)
  withBindings(function()
    mocks.bindKey("F", "CMD_A"); mocks.bindKey("G", "CMD_A")
    assertTrue((lib.__keybindClear("CMD_A", 2)))
    assertEqual(keys("CMD_A"), "F")
  end)
  withBindings(function()
    mocks.bindKey("F", "CMD_A"); mocks.bindKey("G", "CMD_A")
    assertTrue((lib.__keybindClear("CMD_A")))
    assertNil(mocks.GetBindingKey("CMD_A"))
    assertEqual(mocks.GetBindingAction("F"), "")
    assertEqual(mocks.GetBindingAction("G"), "")
    assertEqual(count(mocks.__savedBindingSets), 1, "one save for both")
  end)
end)

test("keybinds: clearing with nothing bound succeeds and saves nothing", function()
  withBindings(function()
    local ok, reason = lib.__keybindClear("CMD_A")
    assertTrue(ok); assertNil(reason)
    assertTrue((lib.__keybindClear("CMD_A", 2)))
    mocks.bindKey("F", "CMD_A")
    assertTrue((lib.__keybindClear("CMD_A", 2)), "an empty slot 2 is nothing to clear")
    assertEqual(count(mocks.__bindingWrites), 0)
    assertEqual(count(mocks.__savedBindingSets), 0)
  end)
end)

-- ── __keybindSetName ─────────────────────────────────────────────────────────────────────────

test("keybinds: the set in force is 'account' for 1 and 'character' for 2", function()
  withBindings(function()
    mocks.__bindingSet = 1
    assertEqual(lib.__keybindSetName(), "account")
    mocks.__bindingSet = 2
    assertEqual(lib.__keybindSetName(), "character")
  end)
end)

-- ── __keyChord ───────────────────────────────────────────────────────────────────────────────

local function chordCases(chord)
  assertEqual(chord("F", { alt = true, ctrl = true, shift = true, meta = true }),
    "ALT-CTRL-SHIFT-META-F")
  assertEqual(chord("F", { shift = true, alt = true }), "ALT-SHIFT-F")
  assertEqual(chord("F", {}), "F")
  for _, ignored in ipairs({ "LSHIFT", "RSHIFT", "LCTRL", "RCTRL", "LALT", "RALT", "LMETA",
                             "RMETA", "UNKNOWN", "LeftButton", "RightButton", "BUTTON1",
                             "BUTTON2", "ESCAPE" }) do
    assertNil(chord(ignored, { shift = true }), ignored .. " is ignored")
  end
  assertEqual(chord("MiddleButton", {}), "BUTTON3")
  assertEqual(chord("Button4", {}), "BUTTON4")
  assertEqual(chord("Button31", { ctrl = true }), "CTRL-BUTTON31")
  assertEqual(chord("MOUSEWHEELUP", {}), "MOUSEWHEELUP")
  assertEqual(chord("MOUSEWHEELDOWN", { alt = true }), "ALT-MOUSEWHEELDOWN")
end

test("keybinds: the bundled chord builder orders ALT-CTRL-SHIFT-META and converts mouse names", function()
  withBindings(function()
    assertNil(mocks.GetConvertedKeyOrButton, "the bundled route")
    chordCases(function(key, mods) return lib.__keyChord(key, mods) end)
  end)
end)

test("keybinds: the bundled chord builder reads the modifier keys when no mods are passed", function()
  withBindings(function()
    mocks.setModifiers{ ctrl = true, meta = true }
    assertEqual(lib.__keyChord("F"), "CTRL-META-F")
  end)
end)

test("keybinds: with the client's chord helpers the client route agrees", function()
  withBindings({ clientChordHelpers = true }, function()
    assertEqual(type(mocks.CreateKeyChordStringUsingMetaKeyState), "function")
    local used = 0
    local real = mocks.CreateKeyChordStringUsingMetaKeyState
    mocks.CreateKeyChordStringUsingMetaKeyState = function(key) used = used + 1; return real(key) end
    chordCases(function(key, mods)
      mocks.setModifiers(mods)
      return lib.__keyChord(key)
    end)
    assertTrue(used > 0, "the client's chord string was asked for")
  end)
end)

test("keybinds: the client route refuses the left and right buttons its ignore check lets through", function()
  -- The client's IsKeyPressIgnoredForBinding covers the modifier keys and UNKNOWN only
  -- (BindingUtil.lua:21-25); BUTTON1 / BUTTON2 are refused elsewhere (:90-92), so the library
  -- applies its own list as well.
  withBindings({ clientChordHelpers = true }, function()
    mocks.IsKeyPressIgnoredForBinding = function() return false end
    for _, button in ipairs({ "LeftButton", "RightButton", "BUTTON1", "BUTTON2" }) do
      mocks.setModifiers{}
      assertNil(lib.__keyChord(button), button .. " binds nothing")
      mocks.setModifiers{ shift = true }
      assertNil(lib.__keyChord(button), "SHIFT-" .. button .. " binds nothing")
    end
    assertEqual(lib.__keyChord("MiddleButton"), "SHIFT-BUTTON3")
  end)
end)
