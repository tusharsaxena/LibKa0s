-- tests/test_toast_stack.lua — LibKa0s-Toast-1.0's stack (Toast minor 4): several toasts on screen at
-- once, each with its own countdown, grown from the saved point, dragged by any of them.
--
-- Peeled out of tests/test_toast.lua unchanged (FU-L2 of Ka0sAddonsCommonTasks
-- docs/2026-11-06-FOLLOWUPS_V1_91, layout-§1); the bench is tests/fixture_toast.lua, and the time,
-- timer and frame conventions are that suite's header.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local F = dofile("tests/fixture_toast.lua")
local newToast, lastTimer, live = F.newToast, F.lastTimer, F.live


-- ── the stack (minor 4) ──────────────────────────────────────────────────────────────────────

--- Show each key in `keys` as its own payload, under that key.
local function showKeys(t, keys, opts)
  for _, k in ipairs(keys) do
    local o = { key = k }
    for name, v in pairs(opts or {}) do o[name] = v end
    t:Show(k, o)
  end
end

--- The toast frames the shell built (the only frames that register a drag), not their close marks.
local function toastFrames(m)
  local out = {}
  for _, f in ipairs(m.__made) do
    if f.__dragButton == "LeftButton" then out[#out + 1] = f end
  end
  return out
end

local function joined(list)
  local out = {}
  for i, v in ipairs(list) do out[i] = tostring(v) end
  return table.concat(out, ",")
end

test("toast stack: with stack = 3, three of five show at once and two wait", function()
  local t, m, built = newToast({ stack = 3 })
  showKeys(t, { "a", "b", "c", "d", "e" })
  assertEqual(#built, 3, "three are drawn")
  assertEqual(#toastFrames(m), 3, "on three frames")
  assertEqual(joined(t:Visible()), "a,b,c", "head first")
  local s = t:Stats()
  assertEqual(s.visible, 3)
  assertEqual(s.waiting, 2)
  assertEqual(joined(s.keys), "d,e")
  for _, k in ipairs({ "a", "b", "c" }) do assertTrue(t:FrameFor(k):IsShown(), k .. " is up") end
  assertTrue(t:FrameFor("a") ~= t:FrameFor("b"), "each toast has its own frame")
  assertNil(t:FrameFor("d"), "a waiting toast has no frame")
  assertNil(t:FrameFor(nil))
  local payload, key = t:Current()
  assertEqual(payload, "a", "Current answers the head")
  assertEqual(key, "a")
  assertEqual(t:Frame(), t:FrameFor("a"), "Frame answers the head's frame")
end)

test("toast stack: each visible toast has its own countdown", function()
  local t, m = newToast({ stack = 3, duration = 6 })
  showKeys(t, { "a", "b", "c" })
  assertEqual(live(m), 3)
  for _, h in ipairs(m.__timers()) do assertEqual(h.delay, 6) end
end)

test("toast stack: closing one re-flows the rest and pulls the next from the queue", function()
  local t, m, _, Toast = newToast({ stack = 3 })
  showKeys(t, { "a", "b", "c", "d" })
  local fb, fc = t:FrameFor("b"), t:FrameFor("c")
  fb:__fire("OnMouseUp", "RightButton")
  assertEqual(joined(t:Visible()), "a,c,d", "b went and d came up at the tail")
  assertEqual(t:Stats().waiting, 0)
  assertEqual(fc.__point[2], t:FrameFor("a"), "c now hangs off a")
  local fd = t:FrameFor("d")
  assertEqual(fd.__point[2], fc, "d hangs off c")
  assertEqual(fd.__point[5], -Toast.STACK_GAP)
  t:FrameFor("a").close:__fire("OnClick")
  assertEqual(joined(t:Visible()), "c,d")
  assertEqual(fc.__point[2], m.UIParent, "c is the head now, at the saved point")
end)

test("toast stack: the head sits at the saved point and the rest grow DOWN by default", function()
  local t, m, _, Toast = newToast({ stack = 3, scale = 2,
    getPosition = function() return { "TOP", "TOP", 0, -100 } end })
  showKeys(t, { "a", "b", "c" })
  local fa, fb, fc = t:FrameFor("a"), t:FrameFor("b"), t:FrameFor("c")
  assertEqual(fa.__point[1], "TOP")
  assertEqual(fa.__point[2], m.UIParent)
  assertEqual(fa.__point[5], -50, "the head's point is divided by the scale")
  assertEqual(joined({ fb.__point[1], fb.__point[3], fb.__point[4], fb.__point[5] }),
    "TOP,BOTTOM,0," .. -Toast.STACK_GAP)
  assertEqual(fb.__point[2], fa)
  assertEqual(fc.__point[2], fb)
  assertEqual(fb.__scale, 2, "every toast in the stack takes the scale")
  assertEqual(t:Stats().grow, "DOWN")
end)

test("toast stack: stackGrow = UP stacks above the head, with the host's gap", function()
  local t, _, _, Toast = newToast({ stack = 2, stackGrow = "UP", stackGap = 10 })
  showKeys(t, { "a", "b" })
  local fa, fb = t:FrameFor("a"), t:FrameFor("b")
  assertEqual(fa.__point[1], Toast.POINT[1], "the head is where a v1 toast is")
  assertEqual(joined({ fb.__point[1], fb.__point[3], fb.__point[4], fb.__point[5] }), "BOTTOM,TOP,0,10")
  assertEqual(fb.__point[2], fa)
  assertEqual(t:Stats().grow, "UP")
end)

test("toast stack: a saved point on a side keeps the stack aligned to that side", function()
  local t = newToast({ stack = 2, getPosition = function() return { "TOPLEFT", "TOPLEFT", 20, -20 } end })
  showKeys(t, { "a", "b" })
  local fb = t:FrameFor("b")
  assertEqual(fb.__point[1], "TOPLEFT")
  assertEqual(fb.__point[3], "BOTTOMLEFT")
  local t2 = newToast({ stack = 2, stackGrow = "UP",
    getPosition = function() return { "BOTTOMRIGHT", "BOTTOMRIGHT", -20, 20 } end })
  showKeys(t2, { "a", "b" })
  assertEqual(t2:FrameFor("b").__point[1], "BOTTOMRIGHT")
  assertEqual(t2:FrameFor("b").__point[3], "TOPRIGHT")
end)

test("toast stack: a gap that is not a number of pixels is STACK_GAP", function()
  for _, bad in ipairs({ -1, "6", true }) do
    local t, _, _, Toast = newToast({ stack = 2, stackGap = bad })
    showKeys(t, { "a", "b" })
    assertEqual(t:FrameFor("b").__point[5], -Toast.STACK_GAP, "gap " .. tostring(bad))
  end
  local t = newToast({ stack = 2, stackGap = 0 })
  showKeys(t, { "a", "b" })
  assertEqual(t:FrameFor("b").__point[5], 0, "zero is a gap")
end)

test("toast stack: hovering one pauses only that one, and its leave resumes only it", function()
  local t, m = newToast({ stack = 2, duration = 8 })
  m.__now = 0
  showKeys(t, { "a", "b" })
  m.__now = 3
  local fb = t:FrameFor("b")
  fb:__fire("OnEnter")
  assertEqual(live(m), 1, "a keeps counting")
  assertFalse(t:Stats().paused, "Stats' paused is the head's")
  m.__fireTimers()
  assertEqual(joined(t:Visible()), "b", "a expired; b is paused and stays")
  assertTrue(t:Stats().paused, "b is the head now")
  fb:__fire("OnLeave")
  assertEqual(lastTimer(m).delay, 5)
end)

test("toast stack: Pause and Resume hold and free every visible countdown", function()
  local t, m = newToast({ stack = 3 })
  showKeys(t, { "a", "b", "c" })
  t:Pause()
  assertEqual(live(m), 0)
  t:Resume()
  assertEqual(live(m), 3)
end)

test("toast stack: Hold puts every visible toast back at the head of the queue, in order", function()
  local t, m = newToast({ stack = 3 })
  showKeys(t, { "a", "b", "c", "d" })
  t:Hold()
  assertEqual(t:Stats().visible, 0)
  assertEqual(live(m), 0)
  assertEqual(joined(t:Stats().keys), "a,b,c,d")
  for _, f in ipairs(toastFrames(m)) do assertFalse(f:IsShown()) end
  t:Release()
  assertEqual(joined(t:Visible()), "a,b,c")
  assertEqual(joined(t:Stats().keys), "d")
end)

test("toast stack: Hold(true) keeps the stack up and holds what follows", function()
  local t = newToast({ stack = 2 })
  showKeys(t, { "a", "b", "c" })
  t:Hold(true)
  assertEqual(joined(t:Visible()), "a,b")
  t:Dismiss()
  assertEqual(joined(t:Visible()), "b", "Dismiss closes the head, and nothing follows while held")
  t:Release()
  assertEqual(joined(t:Visible()), "b,c")
end)

test("toast stack: Remove closes a visible toast and drops a waiting one", function()
  local t = newToast({ stack = 2 })
  showKeys(t, { "a", "b", "c", "d" })
  assertEqual(t:Remove("d"), 1, "a waiting one")
  assertEqual(joined(t:Stats().keys), "c")
  assertEqual(t:Remove("a"), 1, "a visible one")
  assertEqual(joined(t:Visible()), "b,c", "the rest re-flow and the next comes up")
  assertEqual(t:Remove("zz"), 0)
  assertEqual(t:Remove(nil), 0)
end)

test("toast stack: Remove counts a key both visible and waiting", function()
  local t = newToast({ stack = 2 })
  showKeys(t, { "a", "k", "k", "b" })
  assertEqual(t:Remove("k"), 2)
  assertEqual(joined(t:Visible()), "a,b")
end)

test("toast stack: maxQueue still bounds only what waits", function()
  local t = newToast({ stack = 2, maxQueue = 2 })
  showKeys(t, { "a", "b", "c", "d", "e" })
  assertEqual(joined(t:Visible()), "a,b")
  assertEqual(joined(t:Stats().keys), "d,e", "c was the oldest waiting and went")
end)

test("toast stack: Hold with a full queue sends the stack back without dropping a payload", function()
  local t = newToast({ stack = 3, maxQueue = 5 })
  showKeys(t, { "a", "b", "c", "d", "e", "f", "g", "h" })
  assertEqual(joined(t:Stats().keys), "d,e,f,g,h", "the queue is full")
  t:Hold()
  assertEqual(joined(t:Stats().keys), "a,b,c,d,e,f,g,h", "every toast on screen waits, and so does every newest one")
  t:Release()
  assertEqual(joined(t:Visible()), "a,b,c")
  assertEqual(joined(t:Stats().keys), "d,e,f,g,h")
end)

test("toast stack: a cap under the stack's size still keeps every toast sent back to wait", function()
  local t = newToast({ stack = 3, maxQueue = 1 })
  showKeys(t, { "a", "b", "c", "d" })
  t:Hold()
  assertEqual(joined(t:Stats().keys), "a,b,c,d")
  t:Show("e", { key = "e" })
  assertEqual(joined(t:Stats().keys), "e", "the next Show trims the oldest down to the cap")
end)

test("toast stack: a shrinking stack sends its tail back past a full queue, dropping nothing", function()
  local t = newToast({ stack = 3, maxQueue = 2 })
  showKeys(t, { "a", "b", "c", "d", "e" })
  t:SetStack(1)
  assertEqual(joined(t:Visible()), "a")
  assertEqual(joined(t:Stats().keys), "b,c,d,e")
end)

test("toast stack: Stats keeps every v1 field and adds the stack's", function()
  local t = newToast({ stack = 3 })
  showKeys(t, { "a", "b" })
  t:Show("c")
  local s = t:Stats()
  assertTrue(s.built); assertTrue(s.shown); assertEqual(s.waiting, 0); assertFalse(s.held)
  assertFalse(s.paused); assertFalse(s.sticky); assertEqual(s.key, "a"); assertEqual(#s.keys, 0)
  assertEqual(s.visible, 3)
  assertEqual(joined(s.visibleKeys), "a,b,false", "false for a toast shown without a key")
  assertEqual(s.stack, 3)
  assertEqual(s.grow, "DOWN")
  s.visibleKeys[1] = "changed"
  assertEqual(t:Visible()[1], "a", "a fresh list each call")
end)

test("toast stack: SetStack shrinks the stack, sending the tail back to the head of the queue", function()
  local t = newToast({ stack = 3 })
  showKeys(t, { "a", "b", "c", "d" })
  t:SetStack(1)
  assertEqual(joined(t:Visible()), "a")
  assertEqual(joined(t:Stats().keys), "b,c,d", "in the order they came")
  t:SetStack(2, "UP")
  assertEqual(joined(t:Visible()), "a,b", "growing pulls the next up")
  assertEqual(t:FrameFor("b").__point[1], "BOTTOM", "and the direction moves")
  assertEqual(t:Stats().stack, 2)
  t:SetStack(nil, "DOWN")
  assertEqual(t:Stats().stack, 2, "a nil half is left as it was")
  assertEqual(t:FrameFor("b").__point[1], "TOP")
end)

test("toast stack: stack and stackGrow may be getters, read again on Refresh", function()
  local n, grow = 1, "DOWN"
  local t = newToast({ stack = function() return n end, stackGrow = function() return grow end })
  showKeys(t, { "a", "b", "c" })
  assertEqual(joined(t:Visible()), "a")
  n, grow = 3, "UP"
  t:Refresh()
  assertEqual(joined(t:Visible()), "a,b,c")
  assertEqual(t:FrameFor("c").__point[1], "BOTTOM")
end)

test("toast stack: Refresh hands the stack back to the descriptor after a SetStack", function()
  local n, grow = 2, "DOWN"
  local t = newToast({ stack = function() return n end, stackGrow = function() return grow end })
  showKeys(t, { "a", "b", "c" })
  t:SetStack(3, "UP")
  assertEqual(t:Stats().stack, 3)
  n, grow = 1, "DOWN"   -- a profile switch: the getters answer the new profile
  assertEqual(t:Stats().stack, 3, "SetStack holds until the next Refresh")
  t:Refresh()
  local s = t:Stats()
  assertEqual(s.stack, 1, "the getter answers again")
  assertEqual(s.grow, "DOWN")
  assertEqual(joined(t:Visible()), "a")
  assertEqual(joined(s.keys), "b,c")
end)

test("toast stack: a stack that is not a count of at least one is one", function()
  for _, bad in ipairs({ 0, -2, "3", true }) do
    local t = newToast({ stack = bad })
    showKeys(t, { "a", "b" })
    assertEqual(t:Stats().visible, 1, "stack " .. tostring(bad))
  end
  local t = newToast({ stack = 2.7 })
  showKeys(t, { "a", "b", "c" })
  assertEqual(t:Stats().visible, 2, "a fraction rounds down")
end)

test("toast stack: dragging any toast moves the head, and the saved point is the head's", function()
  local stored
  local t, m = newToast({ stack = 2, draggable = true,
    getPosition = function() return stored end, setPosition = function(pt) stored = pt end })
  showKeys(t, { "a", "b" })
  local fa, fb = t:FrameFor("a"), t:FrameFor("b")
  fb:__fire("OnDragStart")
  assertTrue(fa.__moving, "the head moves")
  assertFalse(fb.__moving == true, "the follower does not move on its own")
  fa.__point = { "CENTER", m.UIParent, "CENTER", 10, 20 }
  fb:__fire("OnDragStop")
  assertFalse(fa.__moving)
  assertEqual(joined(stored), "CENTER,CENTER,10,20")
  assertEqual(fb.__point[2], fa, "the follower still hangs off the head")
end)

test("toast stack: a head closed mid-drag stops moving and the next head takes the saved point", function()
  local t, m = newToast({ stack = 2, draggable = true })
  showKeys(t, { "a", "b" })
  local fa, fb = t:FrameFor("a"), t:FrameFor("b")
  fa:__fire("OnDragStart")
  fa:__fire("OnMouseUp", "RightButton")
  assertFalse(fa.__moving)
  assertEqual(fb.__point[2], m.UIParent)
end)

test("toast stack: a drag from a follower holds every countdown, so the head it moves cannot expire", function()
  local t, m = newToast({ stack = 2, draggable = true, duration = 8 })
  m.__now = 0
  showKeys(t, { "a", "b" })
  local fa, fb = t:FrameFor("a"), t:FrameFor("b")
  fb:__fire("OnEnter")
  fb.__over = true
  fb:__fire("OnDragStart")
  assertEqual(live(m), 0, "the head's countdown is held too, not only the hovered follower's")
  m.__fireTimers()
  assertEqual(joined(t:Visible()), "a,b", "nothing expired under the drag")
  fa.__point = { "CENTER", m.UIParent, "CENTER", 10, 20 }
  fb:__fire("OnDragStop")
  assertFalse(fa.__moving)
  assertEqual(live(m), 1, "the head resumes; the follower under the pointer stays paused")
  assertEqual(lastTimer(m).delay, 8, "with the time it had left")
  fb.__over = false
  fb:__fire("OnLeave")
  assertEqual(live(m), 2, "the follower resumes once the pointer leaves it")
end)

test("toast stack: a leave mid-drag does not restart a countdown; the drag's end does", function()
  local t, m = newToast({ stack = 2, draggable = true })
  showKeys(t, { "a", "b" })
  local fb = t:FrameFor("b")
  fb:__fire("OnEnter")
  fb:__fire("OnDragStart")
  fb:__fire("OnLeave")
  assertEqual(live(m), 0, "the drag still holds both")
  fb:__fire("OnDragStop")
  assertEqual(live(m), 2)
end)

test("toast stack: a toast pumped in mid-drag does not yank the moving head, and waits to count", function()
  local stored
  local t, m = newToast({ stack = 3, draggable = true,
    getPosition = function() return stored end, setPosition = function(pt) stored = pt end })
  showKeys(t, { "a", "b" })
  local fa, fb = t:FrameFor("a"), t:FrameFor("b")
  fb:__fire("OnDragStart")
  fa.__point = { "CENTER", m.UIParent, "CENTER", 10, 20 }
  t:Show("c", { key = "c" })
  assertEqual(joined(fa.__point), joined({ "CENTER", m.UIParent, "CENTER", 10, 20 }),
    "the head is left where the drag has it")
  assertTrue(fa.__moving)
  assertEqual(t:FrameFor("c").__point[2], fb, "the new toast hangs off the tail")
  assertEqual(live(m), 0, "its countdown waits for the drag to end")
  fb:__fire("OnDragStop")
  assertEqual(joined(stored), "CENTER,CENTER,10,20")
  assertEqual(live(m), 3)
end)

test("toast stack: a head taken down mid-drag saves the drag's point, and the next head takes it", function()
  local stored
  local t, m = newToast({ stack = 2, draggable = true,
    getPosition = function() return stored end, setPosition = function(pt) stored = pt end })
  showKeys(t, { "a", "b" })
  local fa, fb = t:FrameFor("a"), t:FrameFor("b")
  fb:__fire("OnDragStart")
  fa.__point = { "CENTER", m.UIParent, "CENTER", 10, 20 }
  t:Remove("a")
  assertFalse(fa.__moving, "the drag ended with its toast")
  assertEqual(joined(stored), "CENTER,CENTER,10,20", "the player's placement is kept")
  assertEqual(joined({ fb.__point[1], fb.__point[3], fb.__point[4], fb.__point[5] }), "CENTER,CENTER,10,20")
  assertEqual(fb.__point[2], m.UIParent, "the new head sits at the saved point")
  assertEqual(live(m), 1, "its countdown runs again")
  fb:__fire("OnDragStop")   -- the button's release, after the drag already ended: nothing more
  assertEqual(joined(stored), "CENTER,CENTER,10,20")
end)

test("toast stack: a preview put at the head mid-drag ends the drag where the player left it", function()
  local stored
  local t, m = newToast({ stack = 2, draggable = true,
    getPosition = function() return stored end, setPosition = function(pt) stored = pt end })
  showKeys(t, { "a", "b" })
  local fa = t:FrameFor("a")
  fa:__fire("OnDragStart")
  fa.__point = { "CENTER", m.UIParent, "CENTER", 10, 20 }
  t:Preview("sample")
  assertFalse(fa.__moving)
  assertEqual(joined(stored), "CENTER,CENTER,10,20")
  local head = t:Frame()
  assertEqual(head.__point[2], m.UIParent)
  assertEqual(head.__point[4], 10, "the preview sits where the drag left the stack")
  assertEqual(fa.__point[2], head, "the old head hangs off it")
end)

test("toast stack: a host's Pause before a drag is not undone when the drag ends", function()
  local t, m = newToast({ stack = 2, draggable = true })
  showKeys(t, { "a", "b" })
  t:Pause()
  t:FrameFor("a"):__fire("OnDragStart")
  t:FrameFor("a"):__fire("OnDragStop")
  assertEqual(live(m), 0)
end)

test("toast stack: frames are pooled: a closed toast's frame carries the next one", function()
  local t, m = newToast({ stack = 2, name = "HostToast" })
  showKeys(t, { "a", "b" })
  t:Remove("a")
  t:Show("c", { key = "c" })
  assertEqual(#toastFrames(m), 2, "no third frame")
  assertEqual(toastFrames(m)[1].__name, "HostToast")
  assertEqual(toastFrames(m)[2].__name, "HostToast2", "a pooled frame's name carries its place")
  assertEqual(joined(t:Visible()), "b,c")
end)

test("toast stack: each frame has its own close mark, closing only its toast", function()
  local t = newToast({ stack = 2 })
  showKeys(t, { "a", "b" })
  t:FrameFor("b").close:__fire("OnClick")
  assertEqual(joined(t:Visible()), "a")
end)

test("toast stack: Attach from the builder wires the control to the toast it was drawn on", function()
  local t, m
  local buttons = {}
  t, m = newToast({ stack = 2, build = function(frame, p)
    if not frame.btn then
      frame.btn = m.CreateFrame("Button", nil, frame)
      t:Attach(frame.btn)
    end
    buttons[p] = frame.btn
  end })
  showKeys(t, { "a", "b" })
  buttons.b:__fire("OnMouseUp", "RightButton")
  assertEqual(joined(t:Visible()), "a", "the right-click closed b, not the head")
end)

test("toast stack: Preview shows at the head, and a full stack sends its tail back to wait", function()
  local t, _, _, Toast = newToast({ stack = 2 })
  showKeys(t, { "a", "b", "c" })
  t:Preview("sample")
  assertEqual(joined(t:Visible()), Toast.PREVIEW .. ",a")
  assertEqual(joined(t:Stats().keys), "b,c")
  t:Preview("sample 2")
  assertEqual(joined(t:Visible()), Toast.PREVIEW .. ",a", "a second preview replaces the first")
  assertEqual(t:Remove(Toast.PREVIEW), 1)
  assertEqual(joined(t:Visible()), "a,b")
end)

test("toast stack: Clear takes the whole stack down", function()
  local t, m = newToast({ stack = 3 })
  showKeys(t, { "a", "b", "c", "d" })
  t:Clear()
  assertEqual(t:Stats().visible, 0)
  assertEqual(t:Stats().waiting, 0)
  assertEqual(live(m), 0)
  for _, f in ipairs(toastFrames(m)) do assertFalse(f:IsShown()) end
end)

test("toast stack: without the stack field (or with 1) it is the v1 toast: one frame, one at a time", function()
  for _, d in ipairs({ {}, { stack = 1 } }) do
    local t, m = newToast(d)
    showKeys(t, { "a", "b", "c" })
    assertEqual(#toastFrames(m), 1)
    assertEqual(joined(t:Visible()), "a")
    assertEqual(t:Stats().visible, 1)
    assertEqual(t:Stats().stack, 1)
    assertEqual(t:FrameFor("a"), t:Frame())
    t:Dismiss()
    assertEqual(t:Current(), "b")
    assertEqual(#toastFrames(m), 1, "the one frame carries every toast")
  end
end)
