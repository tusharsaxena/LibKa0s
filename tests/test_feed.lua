-- tests/test_feed.lua -- LibKa0s-Feed-1.0, the toast feed (Loot History #38): the shell.
--
-- The bench is tests/fixture_feed.lua: a fresh environment per case with Core and the feed's three
-- files loaded. The pure half's cases are tests/test_feed_model.lua.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil, assertError =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil, T.assertError
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

-- == the engine ===============================================================================

local function push(feed, key, title, opts) return feed:Push(key, { title = title or key }, opts) end

--- The lowest alpha among a row frame's BORDER-layer textures (its edges).
local function borderAlpha(frame)
  local lo = 1
  for _, r in ipairs({ frame:GetRegions() }) do
    if r.GetDrawLayer and r:GetDrawLayer() == "BORDER" then lo = math.min(lo, r:GetAlpha()) end
  end
  return lo
end

--- The row frame under `key`: the one whose title string reads `title`.
local function rowTitled(feed, title)
  for _, f in ipairs(F.rows(feed)) do
    for _, r in ipairs({ f:GetRegions() }) do
      if r.GetObjectType and r:GetObjectType() == "FontString" and r:GetText() == title then return f end
    end
  end
  return nil
end

local function settle(feed, seconds)
  local n = math.floor(seconds / 0.05 + 0.5)
  for _ = 1, n do F.step(feed, 0.05) end
end

test("feed: nothing is built until the first push, which builds the container and answers new", function()
  local feed, m = F.feed()
  local made = #m.__made
  feed:Hold(); feed:Release(); feed:RepaintAll(); feed:Refresh(); feed:ClearPreview(); feed:__Step(0.1)
  assertEqual(#m.__made, made, "no member but Push or Preview builds")
  assertNil(feed:Frame())
  assertFalse(feed:Stats().built)
  assertEqual(push(feed, "a"), "new")
  local c = feed:Frame()
  assertTrue(c ~= nil, "the container exists once a payload shows")
  assertTrue(feed:Stats().built)
  assertEqual(feed:Stats().live, 1)
  assertTrue(F.clock(feed) ~= nil, "the clock is armed for the enter")
end)

test("feed: the newest row sits at the anchor for both grows, the older ones stacked away from it", function()
  for _, grow in ipairs({ "UP", "DOWN" }) do
    local feed = F.feed({ layout = { grow = grow, gap = 4, rowHeight = 30 }, motion = { smooth = false } })
    push(feed, "a"); push(feed, "b"); push(feed, "c")
    local rows = F.rows(feed)
    assertEqual(#rows, 3, grow)
    local p1, p2, p3 = rows[1].__point, rows[2].__point, rows[3].__point
    local edge = grow == "UP" and "BOTTOM" or "TOP"
    assertEqual(p1[1], edge, grow .. ": rows hang from the grow-origin edge")
    assertEqual(p1[5], 0, grow .. ": the newest at the anchor")
    local sign = grow == "UP" and 1 or -1
    assertEqual(p2[5], sign * 34, grow .. ": the next one a row and a gap away")
    assertEqual(p3[5], sign * 68, grow)
    assertEqual(table.concat(feed:Visible(), ","), "c,b,a", grow .. ": Visible is newest first")
    assertEqual(feed:Frame().__h, 30 * 3 + 4 * 2, grow .. ": the container is the stack's height")
  end
end)

test("feed: past the shown cap the oldest row drops over DROP_FADE and is then released", function()
  local feed, _, _, Feed = F.feed({ layout = { shown = 2 } })
  push(feed, "a"); push(feed, "b")
  assertEqual(push(feed, "c"), "new")
  local s = feed:Stats()
  assertEqual(s.live, 2, "the stack keeps two")
  assertEqual(s.dropping, 1, "the oldest is leaving")
  assertEqual(table.concat(feed:Visible(), ","), "c,b")
  assertNil(feed:Get("a"), "a leaving row is no longer under its key")
  assertEqual(#F.rows(feed), 3, "the leaving row still shows while it fades")
  settle(feed, Feed.DROP_FADE + 0.05)
  assertEqual(feed:Stats().dropping, 0, "released once the fade is done")
  assertEqual(#F.rows(feed), 2)
end)

test("feed: Visible answers false for a key-less row, and a key-less push never merges", function()
  local feed = F.feed()
  push(feed, nil, "x"); push(feed, nil, "y"); push(feed, "k")
  local v = feed:Visible()
  assertEqual(#v, 3)
  assertEqual(v[1], "k"); assertEqual(v[2], false); assertEqual(v[3], false)
  assertTrue(feed:Visible() ~= v, "a new table per call")
end)

test("feed: content answering false skips the payload and answers false", function()
  local feed = F.feed({ content = function(spec, payload) if payload.skip then return false end
    spec.title = payload.title end })
  assertEqual(feed:Push("a", { skip = true }), false)
  assertEqual(feed:Stats().live, 0)
  assertNil(feed:Get("a"), "nothing is kept under the key")
  assertEqual(feed:Push("b", { title = "B" }), "new")
end)

test("feed: content raising reaches geterrorhandler, skips the payload and the feed runs on", function()
  local feed, m = F.feed({ content = function(_, payload) if payload.boom then error("boom") end end })
  assertEqual(feed:Push("a", { boom = true }), false)
  assertEqual(#m.__errors, 1, "the raise reached the error handler")
  assertTrue(tostring(m.__errors[1]):find("boom", 1, true) ~= nil)
  assertEqual(feed:Stats().live, 0)
  assertEqual(feed:Push("b", {}), "new", "the next payload shows")
end)

test("feed: Get answers the live payload; Update repaints in place without moving or pulsing", function()
  local feed, _, calls = F.feed({ motion = { smooth = false } })
  push(feed, "a", "A"); push(feed, "b", "B")
  assertEqual(feed:Get("a").title, "A")
  assertNil(feed:Get("zz"))
  settle(feed, 1)
  local before = #calls
  assertTrue(feed:Update("a", { title = "A2" }))
  assertEqual(#calls, before + 1, "content ran once")
  assertEqual(calls[#calls].payload.title, "A2")
  assertEqual(feed:Get("a").title, "A2")
  assertEqual(table.concat(feed:Visible(), ","), "b,a", "no move to the anchor")
  assertEqual(feed:Stats().awake, true, "the countdown still runs")
  assertFalse(feed:Update("zz", {}), "no entry, nothing taken")
  -- No pulse: the border alpha stays 1 a tick later, where a merge's pulse dims it.
  F.step(feed, 0.05)
  local row = rowTitled(feed, "A2")
  assertTrue(row ~= nil, "the row shows the new title")
  assertEqual(borderAlpha(row), 1, "no pulse")
  assertEqual(push(feed, "a", "A3"), "merged")
  F.step(feed, 0.05)
  assertTrue(borderAlpha(rowTitled(feed, "A3")) < 1, "a merge pulses, so the case above can fail")
end)

test("feed: Repaint re-runs content for one row; Dismiss drops it", function()
  local feed, _, calls, Feed = F.feed()
  push(feed, "a"); push(feed, "b")
  local before = #calls
  assertTrue(feed:Repaint("a"))
  assertEqual(#calls, before + 1)
  assertEqual(calls[#calls].key, "a")
  assertFalse(feed:Repaint("zz"))
  assertTrue(feed:Dismiss("b"))
  assertEqual(feed:Stats().dropping, 1)
  assertEqual(table.concat(feed:Visible(), ","), "a", "the stack closes up at once")
  assertFalse(feed:Dismiss("b"), "a leaving row is not dismissed twice")
  settle(feed, Feed.DROP_FADE + 0.05)
  assertEqual(feed:Stats().dropping, 0)
end)

test("feed: RepaintAll re-runs content for every live row", function()
  local feed, _, calls = F.feed()
  push(feed, "a"); push(feed, "b"); push(feed, "c")
  local before = #calls
  feed:RepaintAll()
  assertEqual(#calls, before + 3)
end)

test("feed: Clear stands the feed down and leaves it reusable", function()
  local feed = F.feed({ layout = { shown = 2 } })
  push(feed, "a"); push(feed, "b"); push(feed, "c")
  feed:Hold(); push(feed, "d")
  feed:Clear()
  local s = feed:Stats()
  assertEqual(s.live, 0); assertEqual(s.waiting, 0); assertEqual(s.dropping, 0)
  assertFalse(s.awake, "the clock is disarmed")
  assertNil(F.clock(feed))
  assertFalse(s.frozen)
  assertTrue(s.locked)
  assertEqual(#F.rows(feed), 0, "every row hidden")
  assertNil(feed:Get("a"))
  feed:Release()
  assertEqual(push(feed, "e"), "new", "reusable")
  assertEqual(#F.rows(feed), 1)
end)

test("feed: while held pushes queue, merge in the waiting list, cap at maxQueue and drain the newest shown", function()
  local merged = 0
  local feed = F.feed({ layout = { shown = 3 }, maxQueue = 4,
    merge = function(old, new) merged = merged + 1; return { title = old.title .. "+" .. new.title } end })
  feed:Hold()
  assertTrue(feed:Stats().held)
  assertEqual(push(feed, "a", "A"), "queued")
  assertEqual(push(feed, "a", "A2"), "merged", "a waiting entry takes a merge")
  assertEqual(merged, 1)
  assertEqual(feed:Get("a").title, "A+A2", "Get reads the waiting payload")
  for _, k in ipairs({ "b", "c", "d", "e" }) do assertEqual(push(feed, k), "queued") end
  assertEqual(feed:Stats().waiting, 4, "capped at maxQueue, the oldest dropped")
  assertNil(feed:Get("a"), "the dropped oldest is gone")
  assertEqual(feed:Stats().live, 0, "nothing shows while held")
  feed:Release()
  assertFalse(feed:Stats().held)
  assertEqual(feed:Stats().waiting, 0)
  assertEqual(table.concat(feed:Visible(), ","), "e,d,c", "only the newest shown present, the newest at the anchor")
  assertNil(feed:Get("b"), "the rest are freed")
end)

test("feed: Preview shows sticky preview rows; ClearPreview drops only those", function()
  local feed, _, _, Feed = F.feed()
  push(feed, "real")
  assertEqual(feed:Preview({ { "p1", { title = "P1" } }, { "p2", { title = "P2" } } }), 2)
  assertEqual(table.concat(feed:Visible(), ","), "p2,p1,real")
  assertNil(feed:Get("p1"), "a preview row takes no key")
  settle(feed, Feed.ENTER_TIME + Feed.HOLD + Feed.FADE_TIME + 0.5)
  assertEqual(table.concat(feed:Visible(), ","), "p2,p1", "the real row ran out; the previews are sticky")
  assertFalse(feed:Stats().awake, "only sticky rows: the clock sleeps")
  assertEqual(feed:Preview({ { "p3", {} } }), 1, "a new preview replaces the old")
  assertEqual(table.concat(feed:Visible(), ","), "p3")
  push(feed, "real2")
  feed:ClearPreview()
  assertEqual(table.concat(feed:Visible(), ","), "real2", "only the previews go")
  feed:Hold()
  assertEqual(feed:Preview({ { "p4", {} } }), 1, "a hold does not queue a preview")
  assertEqual(feed:Preview(nil), 0)
end)

test("feed: Stats answers its full shape at every stage", function()
  local feed = F.feed({ layout = { shown = 2 } })
  local keys = { "live", "waiting", "dropping", "frozen", "held", "locked", "clickThrough", "awake",
    "shown", "built" }
  local function check(stage)
    local s = feed:Stats()
    local n = 0
    for _ in pairs(s) do n = n + 1 end
    assertEqual(n, #keys, stage .. ": ten fields")
    for _, k in ipairs(keys) do assertTrue(s[k] ~= nil, stage .. ": " .. k) end
  end
  check("new")
  push(feed, "a"); push(feed, "b"); push(feed, "c")
  check("live")
  assertEqual(feed:Stats().shown, 2, "shown is the layout's cap")
  assertEqual(feed:Stats().dropping, 1)
  feed:Hold(); push(feed, "d")
  check("held")
  assertEqual(feed:Stats().waiting, 1)
  feed:Clear()
  check("cleared")
end)

test("feed: the frames made stay constant over 200 pushes once the pools are warm", function()
  local feed, m, _, Feed = F.feed({ layout = { shown = 3 } })
  for i = 1, 10 do
    push(feed, "k" .. i)
    settle(feed, Feed.DROP_FADE + 0.05)
  end
  local made = #m.__made
  for i = 11, 210 do
    push(feed, "k" .. i)
    settle(feed, Feed.DROP_FADE + 0.05)
  end
  assertEqual(#m.__made, made, "no frame built after warm-up: rows come from the pool")
  assertEqual(feed:Stats().live, 3)
end)

test("feed: Refresh re-reads the getters and re-anchors the container", function()
  local L = { slot = "BOTTOMRIGHT", x = 0, y = 0, shown = 3 }
  local reads = 0
  local feed, m, calls = F.feed({ layout = function() reads = reads + 1; return L end })
  push(feed, "a"); push(feed, "b")
  assertEqual(reads, 1, "read once, on the build")
  push(feed, "c")
  settle(feed, 0.5)
  assertEqual(reads, 1, "never by a push or the ticker")
  local c = feed:Frame()
  assertEqual(c.__point[1], "BOTTOMRIGHT", "anchored by the grow-origin edge")
  assertTrue(c.__point[2] == m.UIParent)
  assertEqual(c.__point[3], "BOTTOMRIGHT")
  assertEqual(c.__point[4], -20); assertEqual(c.__point[5], 20)
  L = { slot = "TOPLEFT", x = 10, y = -5, grow = "DOWN", shown = 2, scale = 2 }
  local before = #calls
  feed:Refresh()
  assertEqual(reads, 2)
  assertEqual(c.__point[1], "TOPLEFT", "the grow-down origin")
  assertEqual(c.__point[3], "TOPLEFT")
  assertEqual(c.__point[4], (10 + 20) / 2, "offsets in UIParent units over the scale")
  assertEqual(c.__point[5], (-5 - 20) / 2)
  assertEqual(c.__scale, 2)
  assertEqual(feed:Stats().live, 2, "the new cap applies")
  assertEqual(#calls, before + 2, "every live row repainted")
  assertEqual(F.rows(feed)[1].__point[1], "TOP", "rows re-placed for the new grow")
end)

test("feed: __Step ticks a built feed whether the clock is armed or not", function()
  local feed, _, _, Feed = F.feed({ motion = { hold = 0, fadeTime = 0 } })
  feed:__Step(0.1)   -- not built: nothing
  push(feed, "a")
  feed:__Step(Feed.ENTER_TIME + 0.01)
  assertEqual(feed:Stats().live, 0, "enter done, no hold, no fade: the row is gone")
  assertFalse(feed:Stats().awake)
end)
