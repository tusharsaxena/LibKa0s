-- tests/test_feed_input.lua -- LibKa0s-Feed-1.0 (Loot History #38): the pointer, the drag, the strip.
--
-- The bench is tests/fixture_feed.lua. A row's scripts are driven by firing them on its frame
-- (`OnEnter`, `OnLeave`, `OnMouseUp` with a button); the unlock cases load the real drag handle
-- (`{ widgets = true }`) and drive its OnDragStart / OnDragStop.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local F = dofile("tests/fixture_feed.lua")
local push, settle = F.push, F.settle

local function hover(feed, title) F.row(feed, title):__fire("OnEnter") end
local function leave(feed, title) F.row(feed, title):__fire("OnLeave") end
local function click(feed, title, button) F.row(feed, title):__fire("OnMouseUp", button) end

--- The drag handle: the container's child carrying the handle's own ApplyWidth method.
local function handleOf(feed)
  for _, f in ipairs({ feed:Frame():GetChildren() }) do
    if type(rawget(f, "ApplyWidth")) == "function" then return f end
  end
  return nil
end

local function stripsOf(feed)
  local out = {}
  for _, f in ipairs({ feed:Frame():GetChildren() }) do
    if rawget(f, "kind") == "test" or rawget(f, "kind") == "sim" then out[rawget(f, "kind")] = f end
  end
  return out
end

-- == hover and the freeze =====================================================================

test("feed input: with pin, hovering any row freezes the feed: time, Y, queued pushes, merge in place", function()
  local feed, _, _, Feed = F.feed({ motion = { pin = true } })
  push(feed, "a"); push(feed, "b")
  settle(feed, Feed.ENTER_TIME + Feed.SLIDE_TIME + 0.1)
  local fa = F.row(feed, "a")
  local ya = fa.__point[5]
  hover(feed, "b")
  assertTrue(feed:Stats().frozen, "frozen while a row is hovered")
  assertEqual(push(feed, "a"), "merged", "a repeat inside the window still merges")
  assertEqual(table.concat(feed:Visible(), ","), "b,a", "in place, without moving")
  settle(feed, Feed.HOLD + Feed.FADE_TIME + 1)
  assertEqual(table.concat(feed:Visible(), ","), "b,a", "no row ran out")
  assertEqual(fa:GetAlpha(), 1, "and none faded: every row's time stopped")
  assertEqual(fa.__point[5], ya, "the merged row holds its Y")
  assertEqual(push(feed, "c"), "queued", "a new push waits")
  leave(feed, "b")
  assertFalse(feed:Stats().frozen, "leaving ends the freeze")
  assertEqual(feed:Stats().waiting, 0, "and drains the waiting list")
  assertEqual(table.concat(feed:Visible(), ","), "c,b,a", "the waiting row presents at the anchor")
  assertTrue(F.clock(feed) ~= nil, "the clock runs again")
end)

test("feed input: the freeze is derived, so dismissing the hovered row ends it", function()
  local feed, _, _, Feed = F.feed({ motion = { pin = true } })
  push(feed, "a"); push(feed, "b")
  settle(feed, Feed.ENTER_TIME + 0.05)
  hover(feed, "a")
  assertTrue(feed:Stats().frozen)
  push(feed, "c")
  assertTrue(feed:Dismiss("a"))
  assertFalse(feed:Stats().frozen, "no live row is hovered any more")
  assertEqual(feed:Stats().waiting, 0, "the end of the freeze drained")
  assertEqual(table.concat(feed:Visible(), ","), "c,b")
end)

test("feed input: onEnter and onLeave reach the host once each, a dropped hovered row included", function()
  local log = {}
  local feed, _, _, Feed = F.feed({ motion = { pin = false },
    onEnter = function(row, payload, key) log[#log + 1] = "enter:" .. key .. ":" .. payload.title .. ":" .. type(row) end,
    onLeave = function(_, _, key) log[#log + 1] = "leave:" .. key end })
  push(feed, "a")
  hover(feed, "a")
  hover(feed, "a")   -- a second enter without a leave is not a second hover
  leave(feed, "a")
  leave(feed, "a")
  assertEqual(table.concat(log, ","), "enter:a:a:table,leave:a")
  hover(feed, "a")
  feed:Dismiss("a")
  assertEqual(log[#log], "leave:a", "a hovered row that drops tells the host it left")
  settle(feed, Feed.DROP_FADE + 0.1)
  assertEqual(#log, 4)
end)

test("feed input: without pin only the hovered row pauses; the rest run on", function()
  local feed, _, _, Feed = F.feed({ motion = { pin = false } })
  push(feed, "a"); push(feed, "b")
  settle(feed, Feed.ENTER_TIME + 0.05)
  hover(feed, "a")
  assertFalse(feed:Stats().frozen, "pin off: the feed never freezes")
  assertEqual(push(feed, "c"), "new", "pushes still present")
  settle(feed, Feed.HOLD + Feed.FADE_TIME + Feed.DROP_FADE + 0.5)
  assertEqual(table.concat(feed:Visible(), ","), "a", "only the hovered row is still there")
  assertEqual(F.row(feed, "a"):GetAlpha(), 1)
  leave(feed, "a")
  assertTrue(F.clock(feed) ~= nil, "leaving wakes the clock for the paused row")
  settle(feed, Feed.HOLD + Feed.FADE_TIME + Feed.DROP_FADE + 0.5)
  assertEqual(feed:Stats().live, 0, "and it runs out after")
end)

-- == clicks ===================================================================================

test("feed input: a right-click dismisses with rightDismiss on and reaches onClick with it off", function()
  local clicks = {}
  local onClick = function(payload, button, key) clicks[#clicks + 1] = { payload, button, key } end
  local feed = F.feed({ onClick = onClick })
  push(feed, "a")
  click(feed, "a", "RightButton")
  assertEqual(#clicks, 0, "the dismiss is the library's")
  assertEqual(feed:Stats().live, 0)
  assertEqual(feed:Stats().dropping, 1, "the row drops")
  local feed2 = F.feed({ onClick = onClick, motion = { rightDismiss = false } })
  push(feed2, "b")
  click(feed2, "b", "RightButton")
  assertEqual(#clicks, 1)
  assertEqual(clicks[1][2], "RightButton")
  assertEqual(feed2:Stats().live, 1, "nothing dropped")
end)

test("feed input: onClick receives (payload, button, key) for every other click while locked", function()
  local clicks = {}
  local feed = F.feed({ onClick = function(payload, button, key) clicks[#clicks + 1] = { payload, button, key } end })
  push(feed, "a", "Alpha")
  click(feed, "Alpha", "LeftButton")
  click(feed, "Alpha", "MiddleButton")
  assertEqual(#clicks, 2)
  assertEqual(clicks[1][1].title, "Alpha", "the host's payload, untouched")
  assertEqual(clicks[1][2], "LeftButton")
  assertEqual(clicks[1][3], "a")
  assertEqual(clicks[2][2], "MiddleButton")
  local raising = F.feed({ onClick = function() error("host boom") end })
  local m = F.mocks(raising)
  push(raising, "x")
  click(raising, "x", "LeftButton")
  assertEqual(#m.__errors, 1, "a raising onClick reaches geterrorhandler and the feed runs on")
end)

test("feed input: a left click while unlocked is a drag's and never reaches onClick", function()
  local clicks = 0
  local feed = F.feed({ onClick = function() clicks = clicks + 1 end, strings = { HANDLE = "Move" } }, { widgets = true })
  push(feed, "a")
  assertFalse(feed:SetLocked(false))
  click(feed, "a", "LeftButton")
  assertEqual(clicks, 0, "unlocked: the left button is the drag's")
  click(feed, "a", "MiddleButton")
  assertEqual(clicks, 1, "another button still reaches the host")
  feed:SetLocked(true)
  click(feed, "a", "LeftButton")
  assertEqual(clicks, 2, "locked again: the left click is the host's")
end)

-- == click-through ============================================================================

test("feed input: SetClickThrough turns the mouse off on live and later rows, ends hover and freeze, drains", function()
  local left = 0
  local feed, _, _, Feed = F.feed({ motion = { pin = true }, onLeave = function() left = left + 1 end })
  push(feed, "a"); push(feed, "b")
  settle(feed, Feed.ENTER_TIME + 0.05)
  assertTrue(F.row(feed, "a"):IsMouseEnabled(), "rows take the mouse by default")
  hover(feed, "a")
  assertEqual(push(feed, "c"), "queued")
  feed:SetClickThrough(true)
  assertTrue(feed:Stats().clickThrough)
  assertFalse(feed:Stats().frozen, "the freeze ends: the client sends no OnLeave now")
  assertEqual(left, 1, "the host hears the hover end")
  assertEqual(feed:Stats().waiting, 0, "the waiting list drained")
  for _, title in ipairs({ "a", "b", "c" }) do
    assertFalse(F.row(feed, title):IsMouseEnabled(), title .. ": mouse off")
  end
  push(feed, "d")
  assertFalse(F.row(feed, "d"):IsMouseEnabled(), "a row acquired while on takes no mouse")
  feed:SetClickThrough(false)
  assertFalse(feed:Stats().clickThrough)
  assertTrue(F.row(feed, "d"):IsMouseEnabled(), "off again: the mouse comes back")
  local early = F.feed()
  early:SetClickThrough(true)
  push(early, "x")
  assertFalse(F.row(early, "x"):IsMouseEnabled(), "set before the build, it holds for the first row")
end)

-- == the drag handle ==========================================================================

test("feed input: SetLocked(false) docks a DragHandle with the host's label on the far edge", function()
  local feed = F.feed({ strings = { HANDLE = "Move toasts", HANDLE_TIP = "Drag to move." }, layout = { grow = "UP" } },
    { widgets = true })
  assertFalse(feed:SetLocked(false), "unlocked")
  assertFalse(feed:IsLocked())
  assertFalse(feed:Stats().locked)
  assertTrue(feed:Stats().built, "an unlock builds the feed")
  local c = feed:Frame()
  assertTrue(c.__movable, "the container is movable")
  local h = handleOf(feed)
  assertTrue(h ~= nil, "a drag handle is a child of the container")
  assertTrue(h:IsShown())
  assertEqual(h.label:GetText(), "Move toasts", "the host's label")
  local p = h.__point
  assertEqual(p[1], "BOTTOM"); assertTrue(p[2] == c); assertEqual(p[3], "TOP", "over the stack growing up")
  assertTrue(feed:SetLocked(true))
  assertFalse(h:IsShown(), "locked: the handle hides")
  assertFalse(c.__movable)
  local down = F.feed({ strings = { HANDLE = "Move" }, layout = { grow = "DOWN" } }, { widgets = true })
  down:SetLocked(false)
  local hp = handleOf(down).__point
  assertEqual(hp[1], "TOP"); assertEqual(hp[3], "BOTTOM", "under the stack growing down")
end)

test("feed input: an unlock is refused in combat and answers true without Widgets", function()
  local feed, m = F.feed({ strings = { HANDLE = "Move" } }, { widgets = true })
  m.InCombatLockdown = function() return true end
  assertTrue(feed:SetLocked(false), "refused in combat")
  assertTrue(feed:IsLocked())
  m.InCombatLockdown = function() return false end
  assertFalse(feed:SetLocked(false))
  m.InCombatLockdown = function() return true end
  assertTrue(feed:SetLocked(true), "a lock is never refused")
  local bare = F.feed()
  assertTrue(bare:SetLocked(false), "no Widgets: stays locked")
  assertTrue(bare:IsLocked())
  assertTrue(bare:Stats().locked)
end)

--- Answer `rect` (container units) from the container and `scale` as its effective scale, over a
--- 1920 x 1080 UIParent at effective scale 1.
local function geometry(m, c, rect, scale)
  rawset(c, "GetLeft", function() return rect[1] end)
  rawset(c, "GetBottom", function() return rect[2] end)
  rawset(c, "GetRight", function() return rect[3] end)
  rawset(c, "GetTop", function() return rect[4] end)
  rawset(c, "GetEffectiveScale", function() return scale end)
  rawset(m.UIParent, "GetEffectiveScale", function() return 1 end)
  m.UIParent:__setGeom(1920, 1080)
end

test("feed input: a drag stop calls onMoved(x, y) with the nudge for the slot and re-anchors", function()
  local moves = {}
  local feed, m, _, Feed = F.feed({ strings = { HANDLE = "Move" },
    layout = { slot = "BOTTOMRIGHT", grow = "UP", scale = 2 },
    onMoved = function(x, y) moves[#moves + 1] = { x, y } end }, { widgets = true })
  push(feed, "a")
  feed:SetLocked(false)
  local c, h = feed:Frame(), handleOf(feed)
  -- In UIParent units the stack sits 1500..1820 across and 100..300 up: the rect, over the scale.
  geometry(m, c, { 750, 50, 910, 150 }, 2)
  h:__fire("OnDragStart")
  assertTrue(c.__moving, "the handle moves the container")
  h:__fire("OnDragStop")
  assertFalse(c.__moving)
  assertEqual(#moves, 1)
  local I = Feed.SLOT_INSET
  local x, y = 1820 - 1920 + I, 100 - 0 - I
  assertEqual(moves[1][1], x); assertEqual(moves[1][2], y)
  local p = c.__point
  assertEqual(p[1], "BOTTOMRIGHT"); assertTrue(p[2] == m.UIParent); assertEqual(p[3], "BOTTOMRIGHT")
  assertEqual(p[4], (x - I) / 2, "re-anchored from the slot, the nudge over the scale")
  assertEqual(p[5], (y + I) / 2)
  -- The round trip: the slot offset of the nudge is the rect's own corner.
  local _, ox, oy = Feed.__model.SlotOffset("BOTTOMRIGHT", x, y)
  assertEqual(ox, 1820 - 1920); assertEqual(oy, 100)
  -- Locking while a drag is under way ends it and still saves it.
  h:__fire("OnDragStart")
  feed:SetLocked(true)
  assertFalse(c.__moving, "the lock stopped the move")
  assertEqual(#moves, 2, "and saved it")
  h:__fire("OnDragStart")
  assertFalse(c.__moving, "locked: the handle no longer drags")
end)

-- == the strip ================================================================================

test("feed input: SetStrip docks the host's strip on the far edge and hides it under the handle", function()
  local feed = F.feed({ strings = { HANDLE = "Move" } }, { widgets = true })
  feed:SetStrip("test", "Test mode")
  assertNil(feed:Frame(), "a strip set before the build waits for it")
  push(feed, "a")
  local s = stripsOf(feed)
  local tstrip = s.test
  assertTrue(tstrip ~= nil, "built with the feed")
  assertTrue(tstrip:IsShown())
  assertEqual(tstrip.text:GetText(), "Test mode", "the host's text")
  assertFalse(tstrip:IsMouseEnabled(), "the strip takes no mouse")
  local c = feed:Frame()
  assertEqual(tstrip.__point[1], "BOTTOMRIGHT"); assertTrue(tstrip.__point[2] == c); assertEqual(tstrip.__point[3], "TOPRIGHT")
  feed:SetLocked(false)
  assertFalse(tstrip:IsShown(), "hidden while the drag handle shows")
  feed:SetLocked(true)
  assertTrue(tstrip:IsShown(), "back once locked")
  feed:SetStrip("sim", "Simulation")
  s = stripsOf(feed)
  assertTrue(s.sim ~= nil and s.sim:IsShown(), "the sim strip")
  assertFalse(tstrip:IsShown(), "one strip at a time")
  feed:SetStrip(nil)
  assertFalse(s.sim:IsShown(), "nil hides it")
  feed:SetStrip("test", "Again")
  assertEqual(tstrip.text:GetText(), "Again", "a kind's strip is reused with the new text")
  feed:Clear()
  assertFalse(tstrip:IsShown(), "Clear hides the strip")
  push(feed, "b")
  assertFalse(tstrip:IsShown(), "and forgets it")
  local bare = F.feed()
  bare:SetStrip("test", "x")
  push(bare, "a")
  assertEqual(next(stripsOf(bare)), nil, "no Widgets: no strip, and no error")
end)
