-- tests/test_feed_motion.lua -- LibKa0s-Feed-1.0 (Loot History #38): the clock and the motion.
--
-- The bench is tests/fixture_feed.lua. These cases drive the shell's one clock through the kit's
-- settable time: when it arms and sleeps, the MAX_DT cap, merge in place, the slide to a new Y and
-- the settle re-read. The phase machine's own arithmetic is tests/test_feed_model.lua's.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local F = dofile("tests/fixture_feed.lua")
local push, settle = F.push, F.settle

local function near(a, b, msg) assertTrue(math.abs(a - b) < 1e-6, (msg or "") .. ": " .. tostring(a) .. " ~= " .. tostring(b)) end

--- Record every pulse value the shell hands the rows' Animate, so a case can see a merge pulse.
local function watchPulse(Feed)
  local seen = { max = 0 }
  local orig = Feed.__row.Animate
  Feed.__row.Animate = function(R, pulse, clock)
    if (pulse or 0) > seen.max then seen.max = pulse end
    seen.last = pulse
    return orig(R, pulse, clock)
  end
  return seen
end

-- == the clock ================================================================================

test("feed motion: the clock arms on the first push and is nil once every row has gone", function()
  local feed, _, _, Feed = F.feed()
  assertNil(F.clock(feed), "no clock before a push")
  assertEqual(push(feed, "a"), "new")
  assertTrue(F.clock(feed) ~= nil, "a push arms the clock")
  assertTrue(feed:Stats().awake)
  settle(feed, Feed.ENTER_TIME + Feed.HOLD + Feed.FADE_TIME + Feed.DROP_FADE + 0.2)
  assertEqual(feed:Stats().live, 0, "the row ran its life")
  assertNil(F.clock(feed), "idle: the OnUpdate is cleared, not left running")
  assertFalse(feed:Stats().awake)
  push(feed, "b")
  assertTrue(F.clock(feed) ~= nil, "the next push wakes it again")
end)

test("feed motion: a feed showing only sticky rows sleeps once their enter is done", function()
  local feed, _, _, Feed = F.feed()
  push(feed, "a", nil, { sticky = true })
  push(feed, "b", nil, { sticky = true })
  assertTrue(feed:Stats().awake, "entering rows need the clock")
  settle(feed, Feed.ENTER_TIME + Feed.SLIDE_TIME + 0.1)
  assertNil(F.clock(feed), "sticky rows with no countdown need no tick")
  settle(feed, Feed.HOLD * 3)
  assertEqual(feed:Stats().live, 2, "and they never run out")
end)

test("feed motion: a frozen feed sleeps with no pulse, and a merge's pulse wakes it until it ends", function()
  local feed, _, _, Feed = F.feed({ motion = { pin = true } })
  push(feed, "a"); push(feed, "b")
  settle(feed, Feed.ENTER_TIME + Feed.SLIDE_TIME + 0.1)
  F.row(feed, "b"):__fire("OnEnter")
  assertTrue(feed:Stats().frozen)
  F.step(feed, 0.05)
  assertNil(F.clock(feed), "frozen and nothing pulsing: asleep")
  local seen = watchPulse(Feed)
  assertEqual(push(feed, "a"), "merged")
  assertTrue(F.clock(feed) ~= nil, "the merge wakes it")
  F.step(feed, 0.05)
  assertTrue(seen.max > 0, "the merge pulses under the pin")
  settle(feed, Feed.PULSE_TIME + 0.1)
  assertEqual(seen.last, 0, "the pulse ran out")
  assertNil(F.clock(feed), "and the frozen feed sleeps again")
  assertEqual(feed:Stats().live, 2, "nothing ran out while frozen")
end)

test("feed motion: one tick advances at most MAX_DT, so a hitch never skips a row's life", function()
  local feed, m, _, Feed = F.feed({ motion = { enter = "fade" } })
  push(feed, "a")
  local f = F.row(feed, "a")
  m.__now = m.__now + 5   -- a five-second loading screen
  F.clock(feed):__fire("OnUpdate", 5)
  local k = Feed.MAX_DT / Feed.ENTER_TIME
  near(f:GetAlpha(), 1 - (1 - k) ^ 2, "the enter took one MAX_DT, eased")
  assertEqual(feed:Stats().live, 1, "the row is still there")
end)

-- == merge in place ===========================================================================

test("feed motion: a merge inside the window calls d.merge, restarts the hold, pulses and moves to index 1", function()
  local calls = {}
  local feed, _, content, Feed = F.feed({ motion = { mergeWindow = 10 }, merge = function(old, new, key)
    calls[#calls + 1] = { old = old, new = new, key = key }
    return { title = old.title .. "+" .. new.title }
  end })
  local seen = watchPulse(Feed)
  push(feed, "a", "A"); push(feed, "b", "B")
  assertEqual(table.concat(feed:Visible(), ","), "b,a")
  settle(feed, Feed.ENTER_TIME + Feed.HOLD + Feed.FADE_TIME / 2)
  local f = F.row(feed, "A")
  assertTrue(f:GetAlpha() < 1, "the row is fading before the merge")
  local before = #content
  assertEqual(feed:Push("a", { title = "A2" }), "merged")
  assertEqual(#calls, 1)
  assertEqual(calls[1].old.title, "A"); assertEqual(calls[1].new.title, "A2"); assertEqual(calls[1].key, "a")
  assertEqual(feed:Get("a").title, "A+A2", "the reducer's payload is the row's")
  assertEqual(#content, before + 1, "content repainted the merged row once")
  assertEqual(f:GetAlpha(), 1, "back to full alpha at once: the enter is not replayed")
  assertEqual(table.concat(feed:Visible(), ","), "a,b", "the merged row moved to the anchor")
  F.step(feed, 0.05)
  assertTrue(seen.max > 0, "the merge pulses")
  settle(feed, Feed.HOLD - 0.2)
  assertEqual(F.row(feed, "A+A2"):GetAlpha(), 1, "a whole new hold at full alpha")
  assertEqual(table.concat(feed:Visible(), ","), "a", "while the unmerged row ran its own life out")
end)

test("feed motion: without d.merge the newer payload replaces the older one", function()
  local feed = F.feed()
  push(feed, "a", "old")
  assertEqual(push(feed, "a", "new"), "merged")
  assertEqual(feed:Get("a").title, "new")
end)

test("feed motion: a merge while the row is entering keeps the enter running", function()
  local feed, _, _, Feed = F.feed({ motion = { enter = "fade" } })
  push(feed, "a")
  F.step(feed, 0.1)
  local f = F.row(feed, "a")
  local mid = f:GetAlpha()
  assertTrue(mid < 1, "mid-enter")
  assertEqual(push(feed, "a"), "merged")
  assertTrue(f:GetAlpha() < 1, "the enter is neither cut short nor restarted")
  near(f:GetAlpha(), mid, "the same alpha")
  settle(feed, Feed.ENTER_TIME - 0.1 + 0.05)
  assertEqual(f:GetAlpha(), 1, "the enter finishes on its own time")
end)

test("feed motion: past the merge window, or with mergeWindow 0, the same key is a new row", function()
  local feed, _, _, Feed = F.feed()
  push(feed, "a")
  settle(feed, Feed.MERGE_WINDOW + 0.1)
  assertEqual(push(feed, "a"), "new", "past the window")
  assertEqual(table.concat(feed:Visible(), ","), "a,a", "the older row keeps running beside it")
  local feed0 = F.feed({ motion = { mergeWindow = 0 } })
  push(feed0, "a")
  assertEqual(push(feed0, "a"), "new", "mergeWindow 0 never merges")
  assertEqual(feed0:Stats().live, 2)
end)

test("feed motion: a dropping row is never merged into; the push is a new row", function()
  local feed = F.feed({ layout = { shown = 1 } })
  push(feed, "a"); push(feed, "b")
  assertEqual(feed:Stats().dropping, 1, "a was dropped by the shown cap")
  assertEqual(push(feed, "a"), "new", "the dropping row takes no merge")
  local feed2 = F.feed()
  push(feed2, "x")
  assertTrue(feed2:Dismiss("x"))
  assertEqual(push(feed2, "x"), "new", "a dismissed row takes no merge either")
  assertEqual(feed2:Stats().dropping, 1)
  assertEqual(feed2:Stats().live, 1)
end)

-- == the slide ================================================================================

test("feed motion: smooth reposition reaches targetY over SLIDE_TIME, calling SetPoint only while it moves", function()
  local feed, _, _, Feed = F.feed({ motion = { smooth = true } })
  push(feed, "a")
  settle(feed, Feed.ENTER_TIME + 0.05)
  local f = F.row(feed, "a")
  assertEqual(f.__point[5], 0, "alone at the anchor")
  push(feed, "b")
  local target = Feed.ROW_HEIGHT + Feed.GAP
  assertEqual(f.__point[5], 0, "a push does not jump the older row")
  F.step(feed, Feed.SLIDE_TIME / 3)
  local y = f.__point[5]
  assertTrue(y > 0 and y < target, "part way after a third of SLIDE_TIME: " .. tostring(y))
  F.step(feed, Feed.SLIDE_TIME / 3)
  F.step(feed, Feed.SLIDE_TIME / 3 + 0.001)
  near(f.__point[5], target, "at its target after SLIDE_TIME")
  local calls = f.__setPoints
  settle(feed, 1)
  assertEqual(f.__setPoints, calls, "no SetPoint once it has stopped")
  assertEqual(f.__point[5], target)
end)

test("feed motion: with smooth off a row snaps to its new Y", function()
  local feed, _, _, Feed = F.feed({ motion = { smooth = false } })
  push(feed, "a")
  local f = F.row(feed, "a")
  push(feed, "b")
  assertEqual(f.__point[5], Feed.ROW_HEIGHT + Feed.GAP, "at once, with no tick")
  local calls = f.__setPoints
  settle(feed, 0.5)
  assertEqual(f.__setPoints, calls, "and no further SetPoint")
end)

-- == the settle re-read =======================================================================

test("feed motion: settle calls content once at paintedAt + settle and never again", function()
  local feed, _, content = F.feed({ motion = { settle = 1 } })
  push(feed, "a")
  assertEqual(#content, 1, "the present")
  settle(feed, 0.9)
  assertEqual(#content, 1, "not before the settle time")
  settle(feed, 0.2)
  assertEqual(#content, 2, "one re-read at paintedAt + settle")
  assertEqual(content[2].key, "a")
  settle(feed, 3)
  assertEqual(#content, 2, "never again")
  local feed0, _, content0 = F.feed()
  push(feed0, "a")
  settle(feed0, 3)
  assertEqual(#content0, 1, "settle 0 is off")
end)
