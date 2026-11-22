-- tests/test_mock_client.lua -- the kit's client profiles (testkit/mock_client.lua).
--
-- Two profiles and no more: `retail` (the default, live Retail shape, WOW_PROJECT_CAMELOT nil) and
-- `forever`. Every case applies a profile by name to a FRESH mock set, so none depends on which
-- profile the run was started under (KA0S_KIT_CLIENT).
--
-- Kit revision 60 (LibKa0s#101) adds each client's Enum.BagIndex, Enum.BankType and
-- C_Bank.CanViewBank, filled only where the consumer's own mock set left them out.

local T = _G.LK_TEST
local test, assertEqual, assertNil, assertTrue = T.test, T.assertEqual, T.assertNil, T.assertTrue

local MockClient = dofile("tests/_kit/mock_client.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local function fresh(name)
  local m = buildMocks()
  MockClient.apply(m, name)
  return m
end

test("mock client: retail is the live Retail shape, with no Camelot constant", function()
  local m = fresh("retail")
  assertEqual(m.WOW_PROJECT_ID, 1, "WOW_PROJECT_ID")
  assertEqual(m.WOW_PROJECT_MAINLINE, 1, "WOW_PROJECT_MAINLINE")
  assertNil(m.WOW_PROJECT_CAMELOT, "the constant does not exist on Retail")
  local version, build, _, interface = m.GetBuildInfo()
  assertEqual(version, "12.1.5", "version")
  assertEqual(build, "70783", "build")
  assertEqual(interface, 120105, "interface")
  assertNil(m.SetDesaturation, "SetDesaturation is absent under retail too")
  assertEqual(MockClient.current(), "retail", "current")
end)

test("mock client: forever is Camelot, with the spec globals gone", function()
  local m = fresh("forever")
  assertEqual(m.WOW_PROJECT_ID, 18, "WOW_PROJECT_ID")
  assertEqual(m.WOW_PROJECT_CAMELOT, 18, "WOW_PROJECT_CAMELOT")
  assertEqual(m.WOW_PROJECT_MAINLINE, 1, "WOW_PROJECT_MAINLINE")
  local version, build, date, interface = m.GetBuildInfo()
  assertEqual(version, "1.60.1", "version")
  assertEqual(build, "70790", "build")
  assertEqual(date, "Nov  3 2026", "date")
  assertEqual(interface, 16001, "the 4th return is the interface")
  for _, name in ipairs({ "GetSpecialization", "GetSpecializationInfo", "GetActiveSpecGroup",
    "GetTalentInfo", "SetDesaturation" }) do
    assertNil(m[name], name .. " is absent on Forever")
  end
  assertEqual(MockClient.current(), "forever", "current")
end)

test("mock client: an unknown profile name raises", function()
  local err = T.assertError(function() MockClient.apply(buildMocks(), "classic") end,
    "no third profile")
  assertTrue(tostring(err):find('unknown client profile "classic"', 1, true) ~= nil, "names it")
end)

test("mock client: applying retail after forever restores the Camelot-free shape", function()
  local m = fresh("forever")
  MockClient.apply(m, "retail")
  assertNil(m.WOW_PROJECT_CAMELOT, "cleared again")
  assertEqual(m.WOW_PROJECT_ID, 1, "id")
end)

-- -- the container and bank shape (kit revision 60) ---------------------------------------------

local function count(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n
end

--- The BagIndex members every client carries, then the bank tab series for `charTabs`/`accountTabs`.
local function assertBagIndex(e, charTabs, accountTabs, label)
  assertEqual(count(e), 9 + charTabs + accountTabs, label .. ": member count")
  local fixed = { Accountbanktab = -3, Characterbanktab = -2, Keyring = -1, Backpack = 0,
    Bag_1 = 1, Bag_2 = 2, Bag_3 = 3, Bag_4 = 4, ReagentBag = 5 }
  for k, v in pairs(fixed) do assertEqual(e[k], v, label .. ": " .. k) end
  for i = 1, charTabs do assertEqual(e["CharacterBankTab_" .. i], 5 + i, label .. ": CharacterBankTab_" .. i) end
  for i = 1, accountTabs do
    assertEqual(e["AccountBankTab_" .. i], 5 + charTabs + i, label .. ": AccountBankTab_" .. i)
  end
  assertNil(e["CharacterBankTab_" .. (charTabs + 1)], label .. ": no extra character tab")
  assertNil(e["AccountBankTab_" .. (accountTabs + 1)], label .. ": no extra account tab")
end

test("mock client: retail carries 12.1.5's 20-member Enum.BagIndex, six character and five account tabs", function()
  local m = fresh("retail")
  assertBagIndex(m.Enum.BagIndex, 6, 5, "retail")
  assertEqual(m.Enum.BankType.Character, 0, "BankType.Character")
  assertEqual(m.Enum.BankType.Guild, 1, "BankType.Guild")
  assertEqual(m.Enum.BankType.Account, 2, "BankType.Account")
end)

test("mock client: forever carries 1.60.1's 27-member Enum.BagIndex, nine tabs of each kind", function()
  local m = fresh("forever")
  assertBagIndex(m.Enum.BagIndex, 9, 9, "forever")
  assertEqual(m.Enum.BagIndex.AccountBankTab_9, 23, "the last member")
  assertEqual(count(m.Enum.BankType), 3, "BankType: Character, Guild, Account")
end)

test("mock client: C_Bank.CanViewBank is character-and-account on retail, character only on forever", function()
  local r, f = fresh("retail"), fresh("forever")
  local BT = r.Enum.BankType
  assertEqual(r.C_Bank.CanViewBank(BT.Character), true, "retail character")
  assertEqual(r.C_Bank.CanViewBank(BT.Account), true, "retail account")
  assertEqual(f.C_Bank.CanViewBank(BT.Character), true, "forever character")
  assertEqual(f.C_Bank.CanViewBank(BT.Account), false, "forever: no warband bank")
  assertEqual(r.C_Bank.CanViewBank(BT.Guild), false, "guild: not away from a guild vault")
  assertEqual(f.C_Bank.CanViewBank(99), false, "an unknown type is false, a value a branch can tell")
  local err = T.assertError(function() r.C_Bank.CanViewBank(nil) end, "bankType is not nilable")
  assertTrue(tostring(err):find("C_Bank.CanViewBank(bankType)", 1, true) ~= nil, "the client's usage line")
end)

test("mock client: a consumer's own Enum.BagIndex, Enum.BankType and C_Bank win over the profile", function()
  local m = buildMocks()
  local mine, types, bank = { Backpack = 0 }, { Character = 5 }, { FetchNumPurchasedBankTabs = function() return 2 end }
  m.Enum = { BagIndex = mine, BankType = types, GameRule = { HardcoreRuleset = 1 } }
  m.C_Bank = bank
  for _, name in ipairs({ "forever", "retail" }) do
    MockClient.apply(m, name)
    assertTrue(rawequal(m.Enum.BagIndex, mine), name .. ": the consumer's BagIndex kept")
    assertTrue(rawequal(m.Enum.BankType, types), name .. ": the consumer's BankType kept")
    assertEqual(m.Enum.GameRule.HardcoreRuleset, 1, name .. ": the rest of the consumer's Enum kept")
    assertTrue(rawequal(m.C_Bank, bank), name .. ": the consumer's C_Bank kept")
    assertNil(m.C_Bank.CanViewBank, name .. ": and not given a CanViewBank it left out")
  end
end)

test("mock client: a consumer's Enum without BagIndex is left without it, the absence it may be testing", function()
  local m = buildMocks()
  m.Enum = { GameRule = { HardcoreRuleset = 1 } }
  MockClient.apply(m, "forever")
  assertEqual(m.Enum.GameRule.HardcoreRuleset, 1, "kept")
  assertNil(m.Enum.BagIndex, "no BagIndex added")
  assertNil(m.Enum.BankType, "no BankType added")
end)

test("mock client: inside the profile's own Enum a re-apply keeps a member another fake merged in", function()
  local m = fresh("forever")
  m.Enum.BindingSet = { Default = 0, Account = 1, Character = 2 }
  MockClient.apply(m, "retail")
  assertEqual(m.Enum.BindingSet.Character, 2, "BindingSet kept")
  assertNil(m.Enum.BagIndex.CharacterBankTab_7, "BagIndex is retail's")
end)

test("mock client: a C_Bank or Enum on the real global table wins over the profile", function()
  local savedBank, savedEnum = rawget(_G, "C_Bank"), rawget(_G, "Enum")
  local bank, enum = {}, {}
  rawset(_G, "C_Bank", bank)
  rawset(_G, "Enum", enum)
  local ok, err = pcall(function()
    local m = buildMocks()
    m.Enum, m.C_Bank = nil, nil
    MockClient.apply(m, "forever")
    assertNil(m.C_Bank, "the mock set is not given a C_Bank to shadow the global")
    assertNil(m.Enum, "nor an Enum")
    assertNil(enum.BagIndex, "and the global's Enum is not written to")
  end)
  rawset(_G, "C_Bank", savedBank)
  rawset(_G, "Enum", savedEnum)
  if not ok then error(err, 0) end
end)

test("mock client: applying retail after forever replaces the profile's own tables", function()
  local m = fresh("forever")
  MockClient.apply(m, "retail")
  assertBagIndex(m.Enum.BagIndex, 6, 5, "retail again")
  assertEqual(m.C_Bank.CanViewBank(m.Enum.BankType.Account), true, "retail's account bank again")
end)

test("mock client: every apply builds fresh tables, so a case's edit reaches no other mock set", function()
  local a, b = fresh("forever"), fresh("forever")
  assertTrue(not rawequal(a.Enum.BagIndex, b.Enum.BagIndex), "two BagIndex tables")
  assertTrue(not rawequal(a.C_Bank, b.C_Bank), "two C_Bank tables")
  a.Enum.BagIndex.Keyring = nil
  a.C_Bank.CanViewBank = nil
  assertEqual(b.Enum.BagIndex.Keyring, -1, "b's Keyring untouched")
  assertEqual(b.C_Bank.CanViewBank(0), true, "b's CanViewBank untouched")
end)
