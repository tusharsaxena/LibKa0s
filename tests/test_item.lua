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
local Loader = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

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

test("item: QualityFromLink reads the quality out of a legacy |cff hex prefix", function()
  -- THE CASE THE COLLECTION LEARNED THE HARD WAY. C_Item.GetItemInfo(itemID) can only ever answer
  -- with the BASE item, so an upgrade-track drop reads back at the quality it started as. The link
  -- carries the real one in its colour, and that is the only thing available before the client has
  -- cached the item. These two are the pre-11.1.5 hex shape, which stored links still carry.
  assertEqual(item.QualityFromLink(EPIC_LINK), 4)
  assertEqual(item.QualityFromLink(RARE_LINK), 3)
end)

test("item: QualityFromLink reads the 11.1.5+ |cnIQ<n> link color", function()
  -- Since patch 11.1.5 the client colors an item link by quality NUMBER, not by hex: every live
  -- link on 12.x starts |cnIQ<n>:, and the hex rung alone answered nil for all of them, so an
  -- uncached drop was recorded with no quality at all (review finding LibKa0s-R-01).
  -- red under: dropping the |cnIQ rung.
  assertEqual(item.QualityFromLink("|cnIQ4:|Hitem:19019::::::::60:::::|h[Thunderfury]|h|r"), 4)
  assertEqual(item.QualityFromLink("|cnIQ0:|Hitem:2589::::::::60:::::|h[Linen Cloth]|h|r"), 0,
    "quality 0 is an answer, not a miss")
  assertEqual(item.QualityFromLink("|cnIQ3|Hitem:19019::::::::60:::::|h[x]|h|r"), 3,
    "anchored on the digits, with no trailing ':' required")
end)

test("item: QualityFromLink retries a quality map that was built empty", function()
  -- A fresh env rather than the shared one: the shared copy's map was built by the cases above,
  -- and nilling the palette on T.mocks would leak into every later case in the run.
  -- red under: caching the empty map, which pins nil for the session on the legacy rung.
  local m = buildMocks()
  local palette = m.ITEM_QUALITY_COLORS
  m.ITEM_QUALITY_COLORS = {}
  Loader.load("LibKa0s/Core.lua", nil, m)
  Loader.load("LibKa0s/Item.lua", nil, m)
  local isolated = m.LibStub("LibKa0s-Item-1.0")
  T.assertNil(isolated.QualityFromLink(EPIC_LINK), "nothing to map against yet")
  m.ITEM_QUALITY_COLORS = palette
  assertEqual(isolated.QualityFromLink(EPIC_LINK), 4,
    "the empty map was not kept, so the populated palette is read on the next call")
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
