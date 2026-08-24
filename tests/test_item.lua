-- tests/test_item.lua — the item-identity primitives, and nothing that decides policy.
--
-- WHAT IS DELIBERATELY ABSENT HERE IS THE POINT. There is no merged "resolve an item" function,
-- because the two consumers disagree — on purpose, in writing — about what an UNCACHED item means:
-- LootHistory guesses from the link's colour and brackets, BankLedger refuses and records the skip
-- so a quality gate never admits a row it cannot classify. Both are right for their addon, and a
-- shared resolver would have quietly overturned one of them. So this module carries the four
-- primitives they compose and no opinion about how.

local T = _G.LK_TEST
local item, mocks = T.item, T.mocks
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

local EPIC_LINK =
  "|cffa335ee|Hitem:258586::::::::80:250::5:3:10356:10355:1540:1:28:2462:::|h[Bloodfeather Chestguard]|h|r"
local RARE_LINK = "|cff0070dd|Hitem:19019::::::::80:250:::::|h[Thunderfury]|h|r"

-- ── ItemIDFromLink ───────────────────────────────────────────────────────────────────────

test("item: ItemIDFromLink pulls the id out of a full link", function()
  assertEqual(item.ItemIDFromLink(EPIC_LINK), 258586)
end)

test("item: ItemIDFromLink accepts a bare itemString", function()
  assertEqual(item.ItemIDFromLink("item:19019::::::::::"), 19019)
end)

test("item: ItemIDFromLink answers nil for anything that is not a link", function()
  assertEqual(item.ItemIDFromLink("Linen Cloth"), nil)
  assertEqual(item.ItemIDFromLink(nil), nil)
  assertEqual(item.ItemIDFromLink(2589), nil)
end)

-- ── QualityFromLink ──────────────────────────────────────────────────────────────────────

test("item: QualityFromLink reads the quality out of the colour prefix", function()
  -- THE CASE THE COLLECTION LEARNED THE HARD WAY. C_Item.GetItemInfo(itemID) can only ever answer
  -- with the BASE item, so an upgrade-track drop reads back at the quality it started as. The link
  -- carries the real one in its colour, and that is the only thing available before the client has
  -- cached the item.
  assertEqual(item.QualityFromLink(EPIC_LINK), 4)
  assertEqual(item.QualityFromLink(RARE_LINK), 3)
end)

test("item: QualityFromLink answers nil for an uncoloured or absent link", function()
  assertEqual(item.QualityFromLink("|Hitem:19019::::::::::|h[Thunderfury]|h"), nil)
  assertEqual(item.QualityFromLink(nil), nil)
  assertEqual(item.QualityFromLink("Linen Cloth"), nil)
end)

test("item: QualityFromLink answers nil for a colour no quality uses", function()
  assertEqual(item.QualityFromLink("|cff123456|Hitem:1::|h[x]|h|r"), nil)
end)

-- ── QualityLabel ─────────────────────────────────────────────────────────────────────────

test("item: QualityLabel prefers the client's localized label", function()
  assertEqual(item.QualityLabel(4), "Epic")
end)

test("item: QualityLabel falls back to the static English map", function()
  -- Reached headlessly and on a client that has not populated the global. Matching on the ID and
  -- never on a localized string is localization-§4.
  local saved = mocks.ITEM_QUALITY4_DESC
  mocks.ITEM_QUALITY4_DESC = nil
  assertEqual(item.QualityLabel(4), "Epic")
  mocks.ITEM_QUALITY4_DESC = saved
end)

test("item: QualityLabel defaults to Poor when given nothing", function()
  assertEqual(item.QualityLabel(nil), "Poor")
end)

test("item: QualityLabel stringifies a quality it does not know", function()
  assertEqual(item.QualityLabel(99), "99")
end)

-- ── LoadItem ─────────────────────────────────────────────────────────────────────────────

test("item: LoadItem asks the client to cache the id", function()
  assertEqual(mocks.__loadRequests[2589], nil)
  item.LoadItem(2589)
  assertTrue(mocks.__loadRequests[2589] == true, "the request reached C_Item")
end)

test("item: LoadItem fires the callback once the item is loaded", function()
  local fired = false
  item.LoadItem(2589, function() fired = true end)
  mocks.__fireTimers()
  assertTrue(fired, "the callback ran")
end)

test("item: LoadItem is inert without an id or without the API", function()
  item.LoadItem(nil, function() error("must not fire") end)
  local saved = mocks.C_Item
  mocks.C_Item = nil
  item.LoadItem(2589, function() error("must not fire") end)
  mocks.C_Item = saved
end)
