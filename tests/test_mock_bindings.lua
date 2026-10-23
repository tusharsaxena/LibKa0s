-- tests/test_mock_bindings.lua — the kit's opt-in binding mock (revision 42, testkit/mock_bindings.lua).
--
-- Through revision 41 the base answered every binding call from its metatable, which hands back THE
-- FRAME (or nothing at all for a bare global): GetBindingKey was truthy for every command, SetBinding
-- stored nothing, and no suite could tell a bound key from a free one (fidelity rules 1 and 3). The
-- binding model QuickComms carried in its own harness is ported here, opt-in, so a Keybindings tab
-- and an addon's Bindings.xml can be pinned in every consumer from one copy.
--
-- Every case builds a fresh mock, for the reason `tests/test_mock_record.lua` gives.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse
local assertNil = T.assertNil

local buildMocks = dofile("tests/wow_mock.lua")
local install = dofile("tests/_kit/mock_bindings.lua")

local function fresh(opts)
  return install(buildMocks(), opts)
end

local function keys(M, command) return table.concat({ M.GetBindingKey(command) }, ",") end

test("binding mock: GetBindingKey answers every key in bind order, and nil for an unbound command", function()
  -- red under: revision 41, where GetBindingKey was not installed at all
  local M = fresh()
  assertNil(M.GetBindingKey("CMD_A"), "an unbound command has no key")
  assertTrue(M.SetBinding("F", "CMD_A"))
  assertTrue(M.SetBinding("ALT-F", "CMD_A"))
  assertEqual(keys(M, "CMD_A"), "F,ALT-F", "slot order is bind order")
  assertEqual(M.GetBindingAction("ALT-F"), "CMD_A")
end)

test("binding mock: slot order is kept across a rebind of the first slot", function()
  -- red under: a model that keeps one key per command (QuickComms' bindingKeys), where slot 2 is lost
  local M = fresh()
  M.SetBinding("F", "CMD_A"); M.SetBinding("G", "CMD_A")
  M.SetBinding("F", nil)
  assertEqual(keys(M, "CMD_A"), "G", "unbinding slot 1 leaves slot 2")
  M.SetBinding("H", "CMD_A")
  assertEqual(keys(M, "CMD_A"), "G,H", "a new key joins after the survivor")
  assertEqual(M.GetBindingAction("F"), "", "the unbound key is free again")
end)

test("binding mock: GetBindingAction answers the empty string for a free key", function()
  local M = fresh()
  assertEqual(M.GetBindingAction("NUMPAD7"), "")
end)

test("binding mock: a key taken from another action leaves that action keyless", function()
  local M = fresh()
  M.SetBinding("F", "CMD_A")
  M.SetBinding("F", "CMD_B")
  assertNil(M.GetBindingKey("CMD_A"), "the old action lost its only key")
  assertEqual(keys(M, "CMD_B"), "F")
  assertEqual(M.GetBindingAction("F"), "CMD_B")
end)

test("binding mock: SetBinding and SaveBindings are refused in combat, recorded, and change nothing", function()
  local M = fresh()
  M.bindKey("F", "CMD_A")
  M.InCombatLockdown = function() return true end
  assertFalse(M.SetBinding("G", "CMD_A"), "SetBinding answers false in combat")
  M.SaveBindings(2)
  assertEqual(#M.__bindingRefusals, 2, "both refusals are recorded")
  assertEqual(M.__bindingRefusals[1][1], "G"); assertEqual(M.__bindingRefusals[1][2], "CMD_A")
  assertEqual(M.__bindingRefusals[2].save, 2)
  assertEqual(keys(M, "CMD_A"), "F", "no binding moved")
  assertEqual(#M.__bindingWrites, 0, "no write was recorded")
  assertEqual(#M.__savedBindingSets, 0, "no save was recorded")
  assertEqual(M.__bindingFires, 0, "no UPDATE_BINDINGS fired")
end)

test("binding mock: __bindingFailNext refuses one SetBinding for that key, then clears", function()
  local M = fresh()
  M.__bindingFailNext = "F"
  assertFalse(M.SetBinding("F", "CMD_A"), "the armed key fails once")
  assertNil(M.__bindingFailNext, "the seam clears itself")
  assertNil(M.GetBindingKey("CMD_A"))
  assertTrue(M.SetBinding("F", "CMD_A"), "and the next call lands")
  assertEqual(keys(M, "CMD_A"), "F")
end)

test("binding mock: SaveBindings(2) then LoadBindings round-trips both sets", function()
  local M = fresh()
  M.SetBinding("F", "CMD_A")
  M.SaveBindings(2)
  assertEqual(M.__savedBindingSets[1], 2)
  assertEqual(M.GetCurrentBindingSet(), 2, "saving a set makes it current, as the client does")
  M.LoadBindings(1)
  assertEqual(M.GetCurrentBindingSet(), 1)
  assertNil(M.GetBindingKey("CMD_A"), "set 1 never had the key saved into it")
  M.LoadBindings(2)
  assertEqual(M.GetCurrentBindingSet(), 2)
  assertEqual(keys(M, "CMD_A"), "F", "set 2 kept what was saved")
  M.SetBinding("G", "CMD_A")
  M.LoadBindings(2)
  assertEqual(keys(M, "CMD_A"), "F", "loading discards an unsaved change")
end)

test("binding mock: UPDATE_BINDINGS reaches a registered frame and not an unregistered one", function()
  local M = fresh()
  local heard, other = 0, 0
  local f = M.CreateFrame("Frame")
  f:RegisterEvent("UPDATE_BINDINGS")
  f:SetScript("OnEvent", function(_, e) if e == "UPDATE_BINDINGS" then heard = heard + 1 end end)
  local g = M.CreateFrame("Frame")
  g:SetScript("OnEvent", function() other = other + 1 end)
  M.SetBinding("F", "CMD_A")
  M.SaveBindings(1)
  M.LoadBindings(1)
  assertEqual(heard, 3, "set, save and load each fire")
  assertEqual(other, 0, "a frame that never registered hears nothing")
  assertEqual(M.__bindingFires, 3)
  f:UnregisterEvent("UPDATE_BINDINGS")
  M.SetBinding("G", "CMD_A")
  assertEqual(heard, 3, "and an unregistered frame stops hearing it")
end)

test("binding mock: __bindingsFireOnSet = false suppresses only SetBinding's fire", function()
  local M = fresh()
  M.__bindingsFireOnSet = false
  M.SetBinding("F", "CMD_A")
  assertEqual(M.__bindingFires, 0, "SetBinding is silent")
  assertEqual(#M.__bindingWrites, 1, "but still recorded")
  M.SaveBindings(1)
  assertEqual(M.__bindingFires, 1, "SaveBindings still fires")
end)

test("binding mock: GetBindingName reads BINDING_NAME_ on the mock, then _G, then answers the command", function()
  local M = fresh()
  M.BINDING_NAME_CMD_A = "Do A"
  rawset(_G, "BINDING_NAME_CMD_LK10_G", "From G")
  assertEqual(M.GetBindingName("CMD_A"), "Do A")
  assertEqual(M.GetBindingName("CMD_LK10_G"), "From G")
  assertEqual(M.GetBindingName("CMD_NONE"), "CMD_NONE")
  rawset(_G, "BINDING_NAME_CMD_LK10_G", nil)
  assertEqual(M.GetBindingText("ALT-F"), "ALT-F", "GetBindingText is the identity")
end)

test("binding mock: a consumer's own GetBindingKey is kept, and the seams are installed regardless", function()
  local M = buildMocks()
  local mine = function() return "MINE" end
  M.GetBindingKey = mine
  M.NOT_BOUND = "Unbound!"
  install(M)
  assertTrue(M.GetBindingKey == mine, "the consumer's fixture wins")
  assertEqual(M.NOT_BOUND, "Unbound!")
  assertEqual(type(M.SetBinding), "function", "what was missing is filled")
  assertEqual(type(M.__bindingSets[1]), "table", "the seams are always installed")
  assertEqual(M.__bindingSet, 1)
end)

test("binding mock: the constants are the client's", function()
  local M = fresh()
  assertEqual(M.NOT_BOUND, "Not Bound")
  assertEqual(M.KEY_BOUND, "Key Bound Successfully")
  assertEqual(M.KEY_UNBOUND_ERROR, "|cffff0000%s Function is Now Unbound!|r")
  assertEqual(M.ACCOUNT_BINDINGS, 1); assertEqual(M.CHARACTER_BINDINGS, 2)
  assertEqual(M.Enum.BindingSet.Default, 0)
  assertEqual(M.Enum.BindingSet.Account, 1)
  assertEqual(M.Enum.BindingSet.Character, 2)
end)

test("binding mock: the Enum merge keeps existing members", function()
  local M = buildMocks()
  M.Enum = { ItemQuality = { Epic = 4 }, BindingSet = { Account = 99 } }
  install(M)
  assertEqual(M.Enum.ItemQuality.Epic, 4, "another enum survives")
  assertEqual(M.Enum.BindingSet.Account, 99, "an existing BindingSet member is not replaced")
  assertEqual(M.Enum.BindingSet.Character, 2, "a missing one is added")
end)

test("binding mock: modifiers are false by default and set by M.setModifiers", function()
  local M = fresh()
  assertFalse(M.IsAltKeyDown()); assertFalse(M.IsControlKeyDown())
  assertFalse(M.IsShiftKeyDown()); assertFalse(M.IsMetaKeyDown())
  M.setModifiers{ alt = true, shift = true }
  assertTrue(M.IsAltKeyDown()); assertTrue(M.IsShiftKeyDown())
  assertFalse(M.IsControlKeyDown()); assertFalse(M.IsMetaKeyDown())
  M.setModifiers{}
  assertFalse(M.IsAltKeyDown(), "an empty table clears every modifier")
end)

test("binding mock: bindKey seeds silently and clearBindings empties both sets and every log", function()
  local M = fresh()
  M.bindKey("F", "CMD_A")
  assertEqual(keys(M, "CMD_A"), "F")
  assertEqual(M.__bindingFires, 0, "seeding fires nothing")
  assertEqual(#M.__bindingWrites, 0, "and records nothing")
  M.SetBinding("G", "CMD_B"); M.SaveBindings(2)
  M.clearBindings()
  assertNil(M.GetBindingKey("CMD_A")); assertNil(M.GetBindingKey("CMD_B"))
  M.LoadBindings(2)
  assertNil(M.GetBindingKey("CMD_B"), "set 2 is empty too")
  assertEqual(#M.__bindingWrites, 0); assertEqual(#M.__savedBindingSets, 0)
  assertEqual(#M.__bindingRefusals, 0)
end)

test("binding mock: the client chord helpers are absent by default", function()
  -- so a suite exercises the library's bundled fallback unless it asks for the client's
  local M = fresh()
  assertNil(rawget(M, "GetConvertedKeyOrButton"))
  assertNil(rawget(M, "IsKeyPressIgnoredForBinding"))
  assertNil(rawget(M, "CreateKeyChordStringUsingMetaKeyState"))
end)

test("binding mock: clientChordHelpers installs the client's chord helpers, faithfully", function()
  local M = fresh{ clientChordHelpers = true }
  assertEqual(M.GetConvertedKeyOrButton("LeftButton"), "BUTTON1")
  assertEqual(M.GetConvertedKeyOrButton("RightButton"), "BUTTON2")
  assertEqual(M.GetConvertedKeyOrButton("MiddleButton"), "BUTTON3")
  assertEqual(M.GetConvertedKeyOrButton("Button4"), "BUTTON4")
  assertEqual(M.GetConvertedKeyOrButton("X"), "X")
  for _, k in ipairs({ "LSHIFT", "RSHIFT", "LCTRL", "RCTRL", "LALT", "RALT", "LMETA", "RMETA",
                       "UNKNOWN", "BUTTON1", "BUTTON2" }) do
    assertTrue(M.IsKeyPressIgnoredForBinding(k), k .. " is ignored")
  end
  assertFalse(M.IsKeyPressIgnoredForBinding("BUTTON3"))
  assertFalse(M.IsKeyPressIgnoredForBinding("X"))
  M.setModifiers{ alt = true, ctrl = true, shift = true, meta = true }
  assertEqual(M.CreateKeyChordStringUsingMetaKeyState("X"), "ALT-CTRL-SHIFT-META-X")
  M.setModifiers{ shift = true }
  assertEqual(M.CreateKeyChordStringUsingMetaKeyState("X"), "SHIFT-X")
  assertEqual(M.CreateKeyChordStringUsingMetaKeyState("LSHIFT"), "SHIFT", "a meta key alone adds no key")
end)
