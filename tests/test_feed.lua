-- tests/test_feed.lua -- LibKa0s-Feed-1.0, the toast feed (Loot History #38): the shell.
--
-- The bench is tests/fixture_feed.lua: a fresh environment per case with Core and the feed's three
-- files loaded. The pure half's cases are tests/test_feed_model.lua.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil, assertError =
  T.test, T.assertEqual, T.assertTrue, T.assertNil, T.assertError
local Loader = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local F = dofile("tests/fixture_feed.lua")
local MAJOR = F.MAJOR

-- == load and construction ====================================================================

test("feed: the major loads at minor 1 and reports its three files", function()
  local _, Feed = F.env()
  assertEqual(Feed.MAJOR, MAJOR)
  assertEqual(Feed.MINOR, 1)
  assertEqual(Feed.MODULES.Feed, 1)
  assertEqual(Feed.MODULES.FeedModel, 1)
  assertEqual(Feed.MODULES.FeedRow, 1)
  assertEqual(T.feed, T.mocks.LibStub(MAJOR), "the runner's whole-payload load carries it too")
end)

test("feed: the published defaults are the design's numbers", function()
  local _, Feed = F.env()
  assertEqual(Feed.STRATA, "HIGH")
  assertEqual(table.concat(Feed.SLOTS, ","),
    "TOPLEFT,TOP,TOPRIGHT,LEFT,CENTER,RIGHT,BOTTOMLEFT,BOTTOM,BOTTOMRIGHT")
  local want = {
    MAX_QUEUE = 10, SHOWN = 5, SHOWN_MAX = 10, WIDTH = 320, ROW_HEIGHT = 48, ICON_SIZE = 36,
    PADDING = 6, GAP = 5, SLOT_INSET = 20, NUDGE_MAX = 600, ENTER_TIME = 0.25, HOLD = 5,
    FADE_TIME = 1, MERGE_WINDOW = 3, PULSE_TIME = 0.6, SLIDE_TIME = 0.15, DROP_FADE = 0.2, MAX_DT = 0.1,
  }
  for k, v in pairs(want) do assertEqual(Feed[k], v, k) end
end)

test("feed: without Core, or with a Core under minor 20, the major is absent", function()
  local m = buildMocks()
  for _, file in ipairs(F.FILES) do Loader.load(file, nil, m) end
  assertNil(m.LibStub(MAJOR, true), "no Core")
  local m2 = buildMocks()
  local old = m2.LibStub:NewLibrary("LibKa0s-Core-1.0", 19)
  old.MINOR = 19
  for _, file in ipairs(F.FILES) do Loader.load(file, nil, m2) end
  assertNil(m2.LibStub(MAJOR, true), "Core 19")
end)

test("feed: the two secondaries are paired on the shell's minor", function()
  local m, Feed = F.env()
  assertEqual(Feed.__modelMinor, 1)
  assertEqual(Feed.__modelShellMinor, Feed.MINOR, "the model attached to the live shell")
  assertEqual(Feed.__rowMinor, 1)
  assertEqual(Feed.__rowShellMinor, Feed.MINOR, "the rows attached to the live shell")
  assertEqual(type(Feed.__model), "table")
  assertEqual(type(Feed.__row), "table")
  for _, name in ipairs({ "Snapshot", "SlotOffset", "NudgeFromRect", "RowHeight", "Layout", "Advance",
    "Merge", "Drain" }) do
    assertEqual(type(Feed.__model[name]), "function", "__model." .. name)
  end
  for _, name in ipairs({ "Build", "Paint", "Place", "Restyle" }) do
    assertEqual(type(Feed.__row[name]), "function", "__row." .. name)
  end
  -- A second load of the same minors is a no-op: the tables already published stay.
  local model, row = Feed.__model, Feed.__row
  Loader.load("LibKa0s/FeedModel.lua", nil, m)
  Loader.load("LibKa0s/FeedRow.lua", nil, m)
  assertTrue(Feed.__model == model, "the model is not rebuilt")
  assertTrue(Feed.__row == row, "the rows are not rebuilt")
  -- A shell at another minor makes the same secondaries attach again.
  Feed.MINOR = 2
  Loader.load("LibKa0s/FeedModel.lua", nil, m)
  Loader.load("LibKa0s/FeedRow.lua", nil, m)
  assertTrue(Feed.__model ~= model, "the model re-attaches to a newer shell")
  assertTrue(Feed.__row ~= row, "the rows re-attach to a newer shell")
  assertEqual(Feed.__modelShellMinor, 2)
  assertEqual(Feed.__rowShellMinor, 2)
end)

test("feed: the secondaries load to nothing without the shell", function()
  local m = buildMocks()
  Loader.load("LibKa0s/Core.lua", nil, m)
  Loader.load("LibKa0s/FeedModel.lua", nil, m)
  Loader.load("LibKa0s/FeedRow.lua", nil, m)
  assertNil(m.LibStub(MAJOR, true))
end)

test("feed: New raises without d.content, naming it", function()
  local _, Feed = F.env()
  local err = assertError(function() Feed:New({}) end)
  assertTrue(err:find("d.content", 1, true) ~= nil, "names d.content; got: " .. err)
  assertError(function() Feed:New(nil) end)
  assertError(function() Feed:New({ content = "not a function" }) end)
  assertEqual(type(Feed:New({ content = function() end })), "table", "a content function is enough")
end)

test("feed: a method called on something that is not an instance raises", function()
  local feed = F.feed()
  local err = assertError(function() feed.Stats({}) end)
  assertTrue(err:find("Feed:New", 1, true) ~= nil, "says where an instance comes from; got: " .. err)
end)

test("feed: every instance member is on a new feed, copied from the shell's method table", function()
  local feed, _, _, Feed = F.feed()
  local names = { "Push", "Get", "Update", "Repaint", "RepaintAll", "Dismiss", "Clear", "Hold", "Release",
    "Refresh", "Preview", "ClearPreview", "SetLocked", "IsLocked", "SetClickThrough", "SetStrip", "Visible",
    "Stats", "Frame", "__Step" }
  for _, name in ipairs(names) do
    assertEqual(type(feed[name]), "function", name)
    assertTrue(feed[name] == Feed.__methods[name], name .. " is the shell's")
  end
end)

test("feed: Stats answers its full shape on a new feed", function()
  local feed = F.feed()
  local s = feed:Stats()
  local want = { live = 0, waiting = 0, dropping = 0, frozen = false, held = false, locked = true,
    clickThrough = false, awake = false, shown = 0, built = false }
  for k, v in pairs(want) do assertEqual(s[k], v, "Stats()." .. k) end
  local n = 0
  for _ in pairs(s) do n = n + 1 end
  assertEqual(n, 10, "no other field")
  assertNil(feed:Frame(), "nothing is built before the first push")
  assertTrue(feed:IsLocked(), "a new feed is locked")
  assertNil(F.clock(feed), "and its clock is not armed")
end)
