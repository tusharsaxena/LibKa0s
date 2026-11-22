-- tests/test_compat_containers.lua -- LibKa0s-Compat-1.0 minor 6: the container groups and the
-- bank-readiness reads (LibKa0s#101).
--
-- The cases carry over what the three copies' suites pinned: BankLedger's tests/test_keyring_client.lua,
-- tests/test_bank_readiness.lua and the bag-group cases of tests/test_constants.lua; LootHistory's
-- bag-group and Keyring cases in tests/test_compat.lua and the readiness cases of
-- tests/test_reconciler_rows.lua. What those suites pinned about a consumer's own deadline, memory
-- store or event cues stays with them; what is pinned here is the answer the library gives.
--
-- NO CASE TRUSTS WHAT THE BASE MOCK HAPPENS TO CARRY. Every case installs the Enum, C_Bank and project
-- constants it reads through `with`, so the two kit profiles (default and KA0S_KIT_CLIENT=forever)
-- run the same assertions; the profile case at the end plants each client's own enum and pins that
-- the active profile is the row the library picks.

local T = _G.LK_TEST
local compat, mocks = T.compat, T.mocks
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil

-- -- fixtures ---------------------------------------------------------------------------------

--- Installs nil for a key in `with`: "this client does not have that API".
local ABSENT = setmetatable({}, { __tostring = function() return "ABSENT" end })

--- Run `fn` with each key of `fixture` installed in the mock environment (ABSENT removes it), then
--- restore every key and re-raise. A removed key is also cleared from the real global table for the
--- duration, because the loader falls back there.
local function with(fixture, fn)
  local saved, savedG = {}, {}
  for key, value in pairs(fixture) do
    saved[key], savedG[key] = mocks[key], rawget(_G, key)
    if rawequal(value, ABSENT) then
      mocks[key] = nil
      rawset(_G, key, nil)
    else
      mocks[key] = value
    end
  end
  local ok, err = pcall(fn)
  for key in pairs(fixture) do
    mocks[key] = saved[key]
    rawset(_G, key, savedG[key])
  end
  if not ok then error(err, 0) end
end

local function merge(...)
  local out = {}
  for i = 1, select("#", ...) do
    for k, v in pairs((select(i, ...))) do out[k] = v end
  end
  return out
end

local function list(t) return table.concat(t, ",") end

local function range(first, last)
  local out = {}
  for i = first, last do out[#out + 1] = i end
  return out
end

local RETAIL  = { WOW_PROJECT_ID = 1,  WOW_PROJECT_MAINLINE = 1, WOW_PROJECT_CAMELOT = ABSENT }
local FOREVER = { WOW_PROJECT_ID = 18, WOW_PROJECT_MAINLINE = 1, WOW_PROJECT_CAMELOT = 18 }
local NEITHER = { WOW_PROJECT_ID = ABSENT, WOW_PROJECT_MAINLINE = ABSENT, WOW_PROJECT_CAMELOT = ABSENT }

--- Enum.BagIndex as each client ships it (BagIndexConstantsDocumentation.lua), with the two type
--- constants (-2, -3) the patterns must not scoop up and the Keyring (-1), which both enums carry.
--- Retail 12.1.5: six character tabs 6..11 and five account tabs 12..16 (20 members). WoW Forever
--- 1.60.1: nine of each, 6..14 and 15..23 (27 members).
local function bagIndex(forever)
  local e = {
    Keyring = -1, Backpack = 0, Bag_1 = 1, Bag_2 = 2, Bag_3 = 3, Bag_4 = 4, ReagentBag = 5,
    Characterbanktab = -2, Accountbanktab = -3,
  }
  local charTabs, accountTabs = forever and 9 or 6, forever and 9 or 5
  for i = 1, charTabs do e["CharacterBankTab_" .. i] = 5 + i end
  for i = 1, accountTabs do e["AccountBankTab_" .. i] = 5 + charTabs + i end
  return e
end

local function enum(members) return { Enum = merge({ BankType = { Character = 0, Guild = 1, Account = 2 } }, members) } end

local function count(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n
end

-- -- the pattern table (2) ----------------------------------------------------------------------

test("compat containers: the pattern table is published, one row per client, anchored", function()
  local p = compat.CONTAINER_PATTERNS_BY_CLIENT
  assertEqual(count(p), 2, "two rows")
  assertEqual(list(p.retail.bags), "^Backpack$,^Bag_%d+$,^ReagentBag$", "retail bags")
  assertEqual(list(p.forever.bags), "^Backpack$,^Bag_%d+$,^ReagentBag$,^Keyring$", "forever bags: the keyring")
  for _, key in ipairs({ "retail", "forever" }) do
    assertEqual(list(p[key].bank), "^Bank$,^BankBag_%d+$,^CharacterBankTab_%d+$", key .. " bank")
    for group, patterns in pairs(p[key]) do
      for _, pattern in ipairs(patterns) do
        assertTrue(pattern:sub(1, 1) == "^" and pattern:sub(-1) == "$", key .. "." .. group .. " anchored: " .. pattern)
      end
    end
  end
  assertEqual(list(p.retail.accountBank), "^AccountBankTab_%d+$", "retail declares the account bank")
  assertEqual(#p.forever.accountBank, 0, "forever declares none")
end)

test("compat containers: writing to the published table changes no answer", function()
  local p = compat.CONTAINER_PATTERNS_BY_CLIENT
  local saved = p.retail.bags[1]
  p.retail.bags[1] = "^Nothing$"
  local ok, err = pcall(with, merge(RETAIL, enum({ BagIndex = bagIndex(false) })), function()
    assertEqual(list(compat.ContainerGroups().bags), "0,1,2,3,4,5", "the library reads its own copy")
  end)
  p.retail.bags[1] = saved
  if not ok then error(err, 0) end
end)

-- -- ContainerGroups (9) ------------------------------------------------------------------------

test("compat containers: Retail's groups come by name, the type constants and the keyring excluded", function()
  with(merge(RETAIL, enum({ BagIndex = bagIndex(false) })), function()
    local g = compat.ContainerGroups()
    assertEqual(list(g.bags), "0,1,2,3,4,5", "bags: backpack, four bags, the reagent bag")
    assertEqual(list(g.bank), list(range(6, 11)), "bank: the six character tabs")
    assertEqual(list(g.accountBank), list(range(12, 16)), "accountBank: the five warband tabs")
  end)
end)

test("compat containers: WoW Forever's bags hold the keyring, and it declares no account bank", function()
  with(merge(FOREVER, enum({ BagIndex = bagIndex(true) })), function()
    local g = compat.ContainerGroups()
    assertEqual(list(g.bags), "-1,0,1,2,3,4,5", "bags: the keyring first")
    assertEqual(list(g.bank), list(range(6, 14)), "bank: the nine character tabs")
    assertEqual(#g.accountBank, 0, "AccountBankTab_1..9 (15..23) are in the enum, but the bank is not there")
  end)
end)

test("compat containers: a client that is neither reads Retail's bags and bank and no account bank", function()
  with(merge(NEITHER, enum({ BagIndex = bagIndex(false) })), function()
    local g = compat.ContainerGroups()
    assertEqual(list(g.bags), "0,1,2,3,4,5", "bags")
    assertEqual(list(g.bank), list(range(6, 11)), "bank")
    assertEqual(#g.accountBank, 0, "the account bank is declared, never assumed")
  end)
end)

test("compat containers: no id belongs to two groups and no group lists an id twice", function()
  for _, case in ipairs({ { RETAIL, false }, { FOREVER, true } }) do
    with(merge(case[1], enum({ BagIndex = bagIndex(case[2]) })), function()
      local seen = {}
      for group, ids in pairs(compat.ContainerGroups()) do
        for i, id in ipairs(ids) do
          assertNil(seen[id], ("id %d in %s and %s"):format(id, tostring(seen[id]), group))
          seen[id] = group
          if i > 1 then assertTrue(ids[i - 1] < id, group .. " sorted ascending") end
        end
      end
    end)
  end
end)

test("compat containers: the patterns are case-sensitive and anchored at both ends", function()
  local members = {
    Backpack = 0, backpack = 40, XBackpack = 41, Bag_1 = 1, Bag_1x = 42, bag_2 = 43,
    CharacterBankTab_1 = 6, characterBankTab_2 = 44, Characterbanktab = -2,
    AccountBankTab_1 = 12, AccountBankTab_ = 45, Accountbanktab = -3, ReagentBagX = 46,
  }
  with(merge(RETAIL, enum({ BagIndex = members })), function()
    local g = compat.ContainerGroups()
    assertEqual(list(g.bags), "0,1", "bags")
    assertEqual(list(g.bank), "6", "bank")
    assertEqual(list(g.accountBank), "12", "accountBank")
  end)
end)

test("compat containers: the pre-tab bank series is matched, and two names for one id count once", function()
  local members = { Backpack = 0, Bag_1 = 1, Bank = -1, BankBag_1 = 6, BankBag_2 = 7, BankBag_3 = 7 }
  with(merge(RETAIL, enum({ BagIndex = members })), function()
    local g = compat.ContainerGroups()
    assertEqual(list(g.bank), "-1,6,7", "Bank and BankBag_N, de-duplicated")
    assertEqual(list(g.bags), "0,1", "Retail never takes -1 into the bags")
  end)
end)

test("compat containers: with no Enum.BagIndex the bags are 0..5 and the bank groups empty", function()
  for _, fixture in ipairs({ { Enum = ABSENT }, enum({}) }) do
    with(merge(RETAIL, fixture), function()
      local g = compat.ContainerGroups()
      assertEqual(list(g.bags), "0,1,2,3,4,5", "the documented fallback")
      assertEqual(#g.bank, 0, "bank")
      assertEqual(#g.accountBank, 0, "accountBank")
    end)
  end
  with(merge(RETAIL, enum({ BagIndex = { CharacterBankTab_1 = 6 } })), function()
    local g = compat.ContainerGroups()
    assertEqual(list(g.bags), "0,1,2,3,4,5", "an enum that names no bag falls back too")
    assertEqual(list(g.bank), "6", "and the bank is still what matched")
  end)
end)

test("compat containers: every call answers fresh tables", function()
  with(merge(RETAIL, enum({ BagIndex = bagIndex(false) })), function()
    local a = compat.ContainerGroups()
    a.bags[1], a.bank[#a.bank + 1] = 99, 99
    local b = compat.ContainerGroups()
    assertEqual(list(b.bags), "0,1,2,3,4,5", "bags")
    assertEqual(list(b.bank), list(range(6, 11)), "bank")
  end)
  with(merge(RETAIL, { Enum = ABSENT }), function()
    compat.ContainerGroups().bags[1] = 99
    assertEqual(compat.ContainerGroups().bags[1], 0, "the fallback is copied, not shared")
  end)
end)

test("compat containers: the client and the enum are read at call time", function()
  with(merge(RETAIL, enum({ BagIndex = bagIndex(false) })), function()
    assertEqual(#compat.ContainerGroups().accountBank, 5, "Retail")
    mocks.WOW_PROJECT_ID, mocks.WOW_PROJECT_CAMELOT = 18, 18
    mocks.Enum.BagIndex = bagIndex(true)
    local g = compat.ContainerGroups()
    assertEqual(g.bags[1], -1, "Forever: the keyring")
    assertEqual(#g.accountBank, 0, "Forever: no account bank")
  end)
end)

-- -- CanViewCharacterBank (4) -------------------------------------------------------------------

test("compat containers: CanViewCharacterBank asks C_Bank.CanViewBank for Enum.BankType.Character by name", function()
  local asked
  local function canView(answer)
    return { CanViewBank = function(t) asked = t; return answer end }
  end
  with(merge(enum({ BankType = { Character = 7 } }), { C_Bank = canView(true) }), function()
    assertEqual(compat.CanViewCharacterBank(), true, "viewable")
    assertEqual(asked, 7, "the member's value, whatever the number")
  end)
  with(merge(enum({}), { C_Bank = canView(false) }), function()
    assertEqual(compat.CanViewCharacterBank(), false, "a warband-only banker")
  end)
end)

test("compat containers: CanViewCharacterBank normalizes the answer to a boolean", function()
  with(merge(enum({}), { C_Bank = { CanViewBank = function() return 1 end } }), function()
    assertEqual(compat.CanViewCharacterBank(), true, "1")
  end)
  with(merge(enum({}), { C_Bank = { CanViewBank = function() return nil end } }), function()
    assertEqual(compat.CanViewCharacterBank(), false, "a nil answer from a present API is false")
  end)
end)

test("compat containers: CanViewCharacterBank is nil when the build cannot tell", function()
  local api = { CanViewBank = function() return true end }
  local cases = {
    { "no C_Bank", merge(enum({}), { C_Bank = ABSENT }) },
    { "no CanViewBank", merge(enum({}), { C_Bank = {} }) },
    { "no Enum", { Enum = ABSENT, C_Bank = api } },
    { "no BankType", { Enum = {}, C_Bank = api } },
    { "no Character member", merge(enum({ BankType = { Account = 2 } }), { C_Bank = api }) },
  }
  for _, case in ipairs(cases) do
    with(case[2], function()
      local n = select("#", compat.CanViewCharacterBank())
      assertEqual(n, 1, case[1] .. ": arity")
      assertNil(compat.CanViewCharacterBank(), case[1])
    end)
  end
end)

test("compat containers: a secret CanViewBank answer reads as cannot tell, never tested", function()
  local secret = setmetatable({}, { __eq = function() error("SECRET compared") end })
  with(merge(enum({}), {
    issecretvalue = function(v) return rawequal(v, secret) end,
    C_Bank = { CanViewBank = function() return secret end },
  }), function()
    assertNil(compat.CanViewCharacterBank())
  end)
end)

-- -- NumPurchasedBankTabs (3) -------------------------------------------------------------------

test("compat containers: NumPurchasedBankTabs reads the bank type by name", function()
  local asked = {}
  with(merge(enum({}), { C_Bank = { FetchNumPurchasedBankTabs = function(t)
    asked[#asked + 1] = t
    return t == 0 and 3 or 2
  end } }), function()
    assertEqual(compat.NumPurchasedBankTabs("Character"), 3, "Character")
    assertEqual(compat.NumPurchasedBankTabs("Account"), 2, "Account")
    assertEqual(list(asked), "0,2", "Enum.BankType.Character, then .Account")
  end)
end)

test("compat containers: NumPurchasedBankTabs is nil without the API, the member or a plain number", function()
  local function fetch(answer) return { FetchNumPurchasedBankTabs = function() return answer end } end
  local secret = {}
  local cases = {
    { "no C_Bank", merge(enum({}), { C_Bank = ABSENT }), "Character" },
    { "no FetchNumPurchasedBankTabs", merge(enum({}), { C_Bank = {} }), "Character" },
    { "no Enum", { Enum = ABSENT, C_Bank = fetch(3) }, "Character" },
    { "an unknown name", merge(enum({}), { C_Bank = fetch(3) }), "Reagent" },
    { "a non-number answer", merge(enum({}), { C_Bank = fetch("3") }), "Character" },
    { "a nil answer", merge(enum({}), { C_Bank = fetch(nil) }), "Character" },
    { "a secret answer", merge(enum({}), { C_Bank = fetch(secret),
      issecretvalue = function(v) return rawequal(v, secret) end }), "Character" },
  }
  for _, case in ipairs(cases) do
    with(case[2], function() assertNil(compat.NumPurchasedBankTabs(case[3]), case[1]) end)
  end
end)

test("compat containers: NumPurchasedBankTabs with a name that is not a string calls nothing", function()
  local calls = 0
  with(merge(enum({}), { C_Bank = { FetchNumPurchasedBankTabs = function() calls = calls + 1; return 3 end } }),
    function()
      assertNil(compat.NumPurchasedBankTabs(nil), "nil")
      assertNil(compat.NumPurchasedBankTabs(0), "a number")
    end)
  assertEqual(calls, 0)
end)

-- -- BankerKind (3) -----------------------------------------------------------------------------

local INTERACTION = { Banker = 8, CharacterBanker = 67, AccountBanker = 68, MailInfo = 17, GuildBanker = 10 }

test("compat containers: BankerKind names the bank each banker type opens", function()
  with(enum({ PlayerInteractionType = INTERACTION }), function()
    assertEqual(compat.BankerKind(8), "character", "Banker")
    assertEqual(compat.BankerKind(67), "character", "CharacterBanker")
    assertEqual(compat.BankerKind(68), "account", "AccountBanker")
    assertNil(compat.BankerKind(17), "MailInfo")
    assertNil(compat.BankerKind(10), "GuildBanker is not a container bank")
    assertNil(compat.BankerKind(nil), "nil")
    assertNil(compat.BankerKind("8"), "a string")
  end)
end)

test("compat containers: BankerKind reads the enum by name, so a renumbered or older build follows", function()
  with(enum({ PlayerInteractionType = { Banker = 30, CharacterBanker = 31, AccountBanker = 32 } }), function()
    assertEqual(compat.BankerKind(30), "character", "renumbered Banker")
    assertEqual(compat.BankerKind(32), "account", "renumbered AccountBanker")
    assertNil(compat.BankerKind(8), "the old number is nothing now")
  end)
  with(enum({ PlayerInteractionType = { Banker = 8 } }), function()
    assertEqual(compat.BankerKind(8), "character", "a build with Banker alone")
    assertNil(compat.BankerKind(67), "no CharacterBanker member: 67 is nothing")
  end)
end)

test("compat containers: BankerKind is nil without the enum, and never compares a secret", function()
  for _, fixture in ipairs({ { Enum = ABSENT }, { Enum = {} } }) do
    with(fixture, function() assertNil(compat.BankerKind(8)) end)
  end
  local secret = setmetatable({}, { __eq = function() error("SECRET compared") end })
  with(merge(enum({ PlayerInteractionType = INTERACTION }),
    { issecretvalue = function(v) return rawequal(v, secret) end }), function()
    assertNil(compat.BankerKind(secret))
  end)
end)

-- -- UnreadyBankContainers (7) ------------------------------------------------------------------

test("compat containers: a bank whose remembered containers all answer is ready", function()
  local memory = { [6] = 98, [7] = 98, [8] = 98 }
  assertNil(compat.UnreadyBankContainers({ [6] = 98, [7] = 98, [8] = 98 }, memory, 3), "every tab back")
  assertNil(compat.UnreadyBankContainers({ [6] = 98, [7] = 40, [8] = 98 }, memory, 3),
    "a tab answering fewer slots is loaded, not loading")
end)

test("compat containers: visit 2 with a partly loaded bank names the containers still at 0, sorted", function()
  local memory = { [6] = 98, [7] = 98, [8] = 98, [9] = 98 }
  local shape = { [9] = 0, [6] = 98, [8] = 0, [7] = 0 }
  local missing = compat.UnreadyBankContainers(shape, memory, 4)
  assertEqual(list(missing), "7,8,9")
  assertNil(missing.short, "an id list, not the marker")
end)

test("compat containers: a tab that never had slots, or that the shape does not carry, never blocks", function()
  local memory = { [6] = 98, [7] = 0 }
  assertNil(compat.UnreadyBankContainers({ [6] = 98, [7] = 0, [8] = 0 }, memory), "unbought tabs at 0")
  assertNil(compat.UnreadyBankContainers({ [7] = 0 }, { [6] = 98 }), "6 was not read, so it is not judged")
end)

test("compat containers: with no memory and no purchase count the first read is taken as found", function()
  for _, memory in ipairs({ false, {}, { [6] = 0, [7] = 0 } }) do
    assertNil(compat.UnreadyBankContainers({ [6] = 0, [7] = 0 }, memory or nil, nil),
      "memory " .. (memory and count(memory) or "nil"))
  end
end)

test("compat containers: a first visit with fewer containers answering than bought tabs is the marker", function()
  local marker = compat.UnreadyBankContainers({ [6] = 98, [7] = 0, [8] = 0 }, nil, 3)
  assertTrue(type(marker) == "table", "a table, so `if missing then` waits")
  assertEqual(marker.short, true, "short")
  assertEqual(marker.answering, 1, "answering")
  assertEqual(marker.purchased, 3, "purchased")
  assertEqual(#marker, 0, "no array part: an id loop prints nothing")
  local iterated = 0
  for _ in ipairs(marker) do iterated = iterated + 1 end
  assertEqual(iterated, 0, "ipairs")
  assertNil(compat.UnreadyBankContainers({ [6] = 98, [7] = 98, [8] = 98 }, {}, 3), "all bought tabs answer")
  assertNil(compat.UnreadyBankContainers({ [6] = 98, [7] = 98, [8] = 98, [9] = 0 }, nil, 3),
    "an unbought fourth tab at 0 changes nothing")
end)

test("compat containers: with a memory the purchase count is not consulted", function()
  assertNil(compat.UnreadyBankContainers({ [6] = 98, [7] = 0 }, { [6] = 98 }, 5),
    "the memory judges; tab 7 never had slots")
end)

test("compat containers: UnreadyBankContainers is pure: it reads no client and changes no input", function()
  local shape, memory = { [6] = 0, [7] = 98 }, { [6] = 98, [7] = 98 }
  with({ C_Bank = ABSENT, C_Container = ABSENT, Enum = ABSENT }, function()
    assertEqual(list(compat.UnreadyBankContainers(shape, memory, 2)), "6")
  end)
  assertEqual(shape[6], 0, "shape kept")
  assertEqual(memory[6], 98, "memory kept")
  assertEqual(count(shape) + count(memory), 4, "no key added")
  assertNil(compat.UnreadyBankContainers(nil, memory, 2), "no shape: nothing read 0")
  local marker = compat.UnreadyBankContainers(nil, nil, 1)
  assertEqual(marker and marker.answering, 0, "no shape on a first visit: none answering")
end)

-- -- the active profile (1) ---------------------------------------------------------------------

test("compat containers: on the active kit profile the library picks that client's row", function()
  local client = T.loader.MockClient.current()
  local forever = client == "forever"
  with(enum({ BagIndex = bagIndex(forever) }), function()
    local g = compat.ContainerGroups()
    assertEqual(compat.ClientKey(), client, "KA0S_KIT_CLIENT reaches Compat")
    assertEqual(g.bags[1], forever and -1 or 0, client .. ": the keyring only on Forever")
    assertEqual(#g.bank, forever and 9 or 6, client .. ": character tabs")
    assertEqual(#g.accountBank, forever and 0 or 5, client .. ": the account bank only on Retail")
  end)
end)
