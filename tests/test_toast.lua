-- tests/test_toast.lua — LibKa0s-Toast-1.0, the alert-toast shell (LibKa0s#60).
--
-- Every case runs on a fresh environment with Core and Toast loaded. CreateFrame is wrapped so each
-- frame it builds records what the shell tells it (strata, mouse, scale, the anchor, the size, the
-- drag) and answers GetPoint, GetScale and IsMouseOver from that record: the kit's universal frame
-- answers those with the frame itself, which would make every placement assertion vacuous. Time is
-- the kit's settable clock (`m.__now`) and the countdown is the kit's NewTimer queue, read through
-- `m.__timers()`, which lists only live handles.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil, assertError =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil, T.assertError
local Loader = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local MAJOR = "LibKa0s-Toast-1.0"

--- Record what the shell sets on `f`, and answer the getters from the record.
local function instrument(f)
  f.SetFrameStrata = function(self, s) self.__strata = s end
  f.SetToplevel = function(self, v) self.__toplevel = v end
  f.SetClampedToScreen = function(self, v) self.__clamped = v end
  f.EnableMouse = function(self, v) self.__mouse = v end
  f.RegisterForDrag = function(self, b) self.__dragButton = b end
  f.SetScale = function(self, s) self.__scale = s end
  f.GetScale = function(self) return self.__scale or 1 end
  f.ClearAllPoints = function(self) self.__point = nil end
  f.SetPoint = function(self, ...) self.__point = { ... } end
  f.GetPoint = function(self)
    local p = self.__point
    if not p then return nil end
    return p[1], p[2], p[3], p[4], p[5]
  end
  f.SetSize = function(self, w, h) self.__w, self.__h = w, h end
  f.SetWidth = function(self, w) self.__w = w end
  f.SetHeight = function(self, h) self.__h = h end
  f.StartMoving = function(self) self.__moving = true end
  f.StopMovingOrSizing = function(self) self.__moving = false end
  f.IsMouseOver = function(self) return self.__over == true end
  return f
end

--- A fresh environment: Core (unless `fakeCore` registers a stand-in first) and Toast, with every
--- frame instrumented and every PlaySound and error-handler call recorded.
local function env(fakeCore)
  local m = buildMocks()
  local create = m.CreateFrame
  m.__made = {}
  m.CreateFrame = function(...)
    local f = instrument(create(...))
    m.__made[#m.__made + 1] = f
    return f
  end
  m.__sounds = {}
  m.PlaySound = function(id, channel) m.__sounds[#m.__sounds + 1] = { id = id, channel = channel } end
  m.__files = {}
  m.PlaySoundFile = function(file, channel) m.__files[#m.__files + 1] = { file = file, channel = channel } end
  m.SOUNDKIT = { RAID_WARNING = 8959, UI_EPICLOOT_TOAST = 31578 }
  m.__errors = {}
  m.geterrorhandler = function() return function(e) m.__errors[#m.__errors + 1] = e end end
  if fakeCore then fakeCore(m) else Loader.load("LibKa0s/Core.lua", nil, m) end
  Loader.load("LibKa0s/Toast.lua", nil, m)
  return m, m.LibStub(MAJOR, true)
end

--- A toast whose builder records each call; `d` overrides the descriptor's fields.
local function newToast(d, fakeCore)
  local m, Toast = env(fakeCore)
  local built = {}
  local desc = { build = function(frame, payload)
    built[#built + 1] = { frame = frame, payload = payload }
    return 300, 50
  end }
  for k, v in pairs(d or {}) do desc[k] = v end
  return Toast:New(desc), m, built, Toast
end

local function lastTimer(m)
  local live = m.__timers()
  return live[#live]
end

local function live(m) return #m.__timers() end

-- ── load and construction ────────────────────────────────────────────────────────────────────

test("toast: the major loads at minor 4 and reports its one file", function()
  local _, Toast = env()
  assertEqual(Toast.MAJOR, MAJOR)
  assertEqual(Toast.MINOR, 4)
  assertEqual(Toast.MODULES.Toast, 4)
  assertEqual(T.toast, T.mocks.LibStub(MAJOR), "the runner's whole-payload load carries it too")
end)

test("toast: without Core the major is absent (no NewLibrary)", function()
  local m = buildMocks()
  Loader.load("LibKa0s/Toast.lua", nil, m)
  assertNil(m.LibStub(MAJOR, true))
end)

test("toast: New refuses a descriptor without a builder, naming it", function()
  local _, Toast = env()
  local err = assertError(function() Toast:New({}) end)
  assertTrue(err:find("d.build", 1, true) ~= nil, "names d.build; got: " .. err)
  assertError(function() Toast:New(nil) end)
end)

test("toast: a method called on something that is not an instance raises", function()
  local t = newToast()
  local err = assertError(function() t.Show({}, "x") end)
  assertTrue(err:find("Toast:New", 1, true) ~= nil, "says where an instance comes from; got: " .. err)
end)

test("toast: nothing is built before the first Show", function()
  local t, m = newToast()
  assertNil(t:Frame())
  assertEqual(#m.__made, 0)
  assertFalse(t:Stats().built)
end)

-- ── the builder ──────────────────────────────────────────────────────────────────────────────

test("toast: the builder is called with the toast's frame and the payload, and sizes it", function()
  local t, _, built = newToast()
  local payload = { best = 123 }
  assertTrue(t:Show(payload))
  assertEqual(#built, 1)
  assertEqual(built[1].frame, t:Frame())
  assertEqual(built[1].payload, payload, "the payload is handed over as given")
  assertEqual(t:Frame().__w, 300)
  assertEqual(t:Frame().__h, 50)
  assertTrue(t:Frame():IsShown())
  assertEqual(t:Current(), payload)
end)

test("toast: a builder answering no size keeps the descriptor's, else the library's", function()
  local t = newToast({ build = function() end, width = 280, height = 40 })
  t:Show("a")
  assertEqual(t:Frame().__w, 280)
  assertEqual(t:Frame().__h, 40)
  local t2, _, _, Toast = newToast({ build = function() end })
  t2:Show("a")
  assertEqual(t2:Frame().__w, Toast.WIDTH)
  assertEqual(t2:Frame().__h, Toast.HEIGHT)
end)

test("toast: a builder answering false skips the payload and the next one shows", function()
  local seen = {}
  local t = newToast({ build = function(_, p)
    seen[#seen + 1] = p
    if p == "skip" then return false end
  end })
  t:Show("first")
  t:Show("skip")
  t:Show("last")
  t:Dismiss()
  assertEqual(table.concat(seen, ","), "first,skip,last")
  assertEqual(t:Current(), "last")
end)

test("toast: a builder that raises costs its payload, reports through the error handler, and the next shows", function()
  local t, m = newToast({ build = function(_, p) if p == "bad" then error("boom") end end })
  t:Show("bad")
  assertNil(t:Current(), "nothing is on screen after a failed build")
  assertEqual(#m.__errors, 1)
  assertTrue(tostring(m.__errors[1]):find("boom", 1, true) ~= nil)
  t:Show("good")
  assertEqual(t:Current(), "good")
end)

-- ── the queue ────────────────────────────────────────────────────────────────────────────────

test("toast: one at a time; the rest wait and show in the order they came", function()
  local t, _, built = newToast()
  t:Show("a")
  t:Show("b")
  t:Show("c")
  assertEqual(#built, 1, "only the first is drawn while it is on screen")
  assertEqual(t:Stats().waiting, 2)
  t:Dismiss()
  assertEqual(t:Current(), "b")
  t:Dismiss()
  assertEqual(t:Current(), "c")
  t:Dismiss()
  assertNil(t:Current())
  assertFalse(t:Frame():IsShown(), "the frame hides when the queue runs dry")
  assertEqual(#built, 3)
end)

test("toast: past the cap the oldest waiting payload is dropped", function()
  local t = newToast({ maxQueue = 2 })
  for _, p in ipairs({ "a", "b", "c", "d" }) do t:Show(p) end
  assertEqual(t:Stats().waiting, 2)
  t:Dismiss()
  assertEqual(t:Current(), "c", "b was the oldest waiting and went")
  t:Dismiss()
  assertEqual(t:Current(), "d")
end)

test("toast: a toast closed mid-drag stops moving", function()
  local t = newToast({ draggable = true })
  t:Show("a")
  local f = t:Frame()
  f:__fire("OnDragStart")
  assertTrue(f.__moving)
  f:__fire("OnMouseUp", "RightButton")
  assertFalse(f.__moving)
end)

test("toast: a cap under one still keeps the payload just queued", function()
  local t = newToast({ maxQueue = 0.5 })
  t:Show("a")
  t:Show("b")
  t:Show("c")
  assertEqual(t:Stats().waiting, 1)
  t:Dismiss()
  assertEqual(t:Current(), "c")
end)

test("toast: Stats names the waiting payloads' keys, oldest first, false for none", function()
  local t = newToast()
  assertEqual(#t:Stats().keys, 0, "nothing waits")
  t:Show("a", { key = 1 })
  t:Show("b", { key = "x" })
  t:Show("c")
  t:Show("d", { key = 4 })
  local s = t:Stats()
  assertEqual(s.key, 1, "the one on screen is key, not in keys")
  assertEqual(#s.keys, 3)
  assertEqual(s.keys[1], "x"); assertEqual(s.keys[2], false); assertEqual(s.keys[3], 4)
  s.keys[1] = "changed"
  assertEqual(t:Stats().keys[1], "x", "a fresh list each call: the queue is not handed out")
  t:Hold()
  assertEqual(t:Stats().keys[1], 1, "a held toast goes back to the head of the queue")
end)

test("toast: the cap defaults to MAX_QUEUE", function()
  local t, _, _, Toast = newToast()
  for i = 1, Toast.MAX_QUEUE + 4 do t:Show(i) end
  assertEqual(t:Stats().waiting, Toast.MAX_QUEUE)
end)

test("toast: Remove drops queued payloads by key and closes the one on screen", function()
  local t = newToast()
  t:Show("a", { key = 1 })
  t:Show("b", { key = 2 })
  t:Show("c", { key = 2 })
  t:Show("d", { key = 3 })
  assertEqual(t:Remove(2), 2)
  assertEqual(t:Stats().waiting, 1)
  assertEqual(t:Remove(1), 1, "the one on screen counts")
  assertEqual(t:Current(), "d", "the next waiting one shows")
  assertEqual(t:Remove(99), 0)
  assertEqual(t:Remove(nil), 0)
end)

-- ── the lifetime ─────────────────────────────────────────────────────────────────────────────

test("toast: it closes after the host's duration and the next one shows with its own countdown", function()
  local t, m = newToast({ duration = function() return 6 end })
  t:Show("a")
  t:Show("b")
  assertEqual(live(m), 1)
  assertEqual(lastTimer(m).delay, 6)
  m.__fireTimers()
  assertEqual(t:Current(), "b")
  assertEqual(live(m), 1, "b has its own countdown")
  m.__fireTimers()
  assertNil(t:Current())
  assertEqual(live(m), 0)
end)

test("toast: a duration that is missing or not a positive number is DURATION", function()
  for _, bad in ipairs({ false, 0, -3, "8" }) do
    local t, m, _, Toast = newToast({ duration = bad })
    t:Show("a")
    assertEqual(lastTimer(m).delay, Toast.DURATION, "duration " .. tostring(bad))
  end
end)

test("toast: hovering pauses the countdown and leaving resumes it with the time it had left", function()
  local t, m = newToast({ duration = 8 })
  local f
  m.__now = 100
  t:Show("a")
  f = t:Frame()
  m.__now = 103
  f:__fire("OnEnter")
  assertEqual(live(m), 0, "no countdown while the pointer is over it")
  assertTrue(t:Stats().paused)
  m.__now = 500
  m.__fireTimers()
  assertEqual(t:Current(), "a", "a paused toast does not close")
  f:__fire("OnLeave")
  assertFalse(t:Stats().paused)
  assertEqual(lastTimer(m).delay, 5, "8 seconds less the 3 it was on screen before the hover")
end)

test("toast: leaving onto the toast itself (a child control) keeps it paused until the pointer goes", function()
  local t, m = newToast({ duration = 8 })
  m.__now = 0
  t:Show("a")
  local f = t:Frame()
  m.__now = 2
  f:__fire("OnEnter")
  f.__over = true
  f:__fire("OnLeave")
  assertTrue(t:Stats().paused)
  assertEqual(live(m), 1, "only the leave watch runs, no countdown")
  m.__fireTimers()
  assertTrue(t:Stats().paused, "still over the toast: still paused")
  f.__over = false
  m.__fireTimers()
  assertFalse(t:Stats().paused, "the pointer went: the countdown resumes")
  assertEqual(lastTimer(m).delay, 6)
end)

test("toast: the countdown resumes off the close mark even after its scripts were set again", function()
  local t, m = newToast({ duration = 8 })
  m.__now = 0
  t:Show("a")
  local f = t:Frame()
  local close = f.close
  -- What Core minor 13 does to a skin owner's close mark on every skin switch: SetScript, which
  -- drops the toast's hooks.
  close:SetScript("OnEnter", function() end)
  close:SetScript("OnLeave", function() end)
  m.__now = 3
  f:__fire("OnEnter")
  f.__over = true
  f:__fire("OnLeave")         -- frame -> close mark
  close:__fire("OnEnter")
  f.__over = false
  close:__fire("OnLeave")     -- close mark -> straight off the toast; no hook fires
  m.__fireTimers()
  assertFalse(t:Stats().paused)
  assertEqual(lastTimer(m).delay, 5, "the countdown resumes with the time it had left")
  m.__fireTimers()
  assertNil(t:Current(), "and the toast closes")
end)

test("toast: closing a toast while a leave watch runs cancels the watch", function()
  local t, m = newToast()
  t:Show("a")
  local f = t:Frame()
  f:__fire("OnEnter")
  f.__over = true
  f:__fire("OnLeave")
  assertEqual(live(m), 1)
  t:Dismiss()
  assertEqual(live(m), 0)
end)

test("toast: a resumed countdown never has less than a second", function()
  local t, m = newToast({ duration = 2 })
  m.__now = 0
  t:Show("a")
  m.__now = 1.9
  t:Pause()
  t:Resume()
  assertEqual(lastTimer(m).delay, 1)
end)

test("toast: a sticky toast has no countdown and pausing it does nothing", function()
  local t, m = newToast()
  t:Show("a", { sticky = true })
  assertEqual(live(m), 0)
  assertTrue(t:Stats().sticky)
  t:Pause()
  t:Resume()
  assertEqual(live(m), 0)
  assertFalse(t:Stats().paused)
end)

test("toast: the close mark closes it and the next one shows", function()
  local t = newToast()
  t:Show("a")
  t:Show("b")
  local close = t:Frame().close
  assertTrue(close ~= nil, "Core's close mark is on the frame")
  close:__fire("OnClick")
  assertEqual(t:Current(), "b")
end)

test("toast: a right-click anywhere closes it; a left-click does not", function()
  local t, m = newToast()
  t:Show("a")
  local f = t:Frame()
  f:__fire("OnMouseUp", "LeftButton")
  assertEqual(t:Current(), "a")
  f:__fire("OnMouseUp", "RightButton")
  assertNil(t:Current())
  assertEqual(live(m), 0, "its countdown goes with it")
end)

test("toast: hovering the close mark pauses, and a right-click on it closes", function()
  local t, m = newToast()
  t:Show("a")
  local close = t:Frame().close
  close:__fire("OnEnter")
  assertEqual(live(m), 0)
  close:__fire("OnMouseUp", "RightButton")
  assertNil(t:Current())
end)

test("toast: Attach wires a host control to the pause and the right-click, keeping its own script", function()
  local mine = 0
  local t, m = newToast()
  t:Show("a")
  local button = m.CreateFrame("Button", nil, t:Frame())
  button:SetScript("OnEnter", function() mine = mine + 1 end)
  t:Attach(button)
  button:__fire("OnEnter")
  assertEqual(mine, 1, "the control's own OnEnter still runs")
  assertEqual(live(m), 0, "hovering the control holds the countdown")
  button:__fire("OnMouseUp", "RightButton")
  assertNil(t:Current())
  t:Attach(nil)   -- not a widget: ignored
end)

-- ── chrome ───────────────────────────────────────────────────────────────────────────────────

test("toast: the frame is the T5 alert tier: HIGH, toplevel, mouse-enabled, clamped", function()
  local t, _, _, Toast = newToast({ name = "HostToast" })
  t:Show("a")
  local f = t:Frame()
  assertEqual(Toast.STRATA, "HIGH")
  assertEqual(f.__strata, "HIGH")
  assertTrue(f.__toplevel)
  assertTrue(f.__mouse)
  assertTrue(f.__clamped)
  assertEqual(f.__name, "HostToast", "the global name is the host's")
  assertEqual(f.__template, "BackdropTemplate")
  assertEqual(f.__dragButton, "LeftButton")
end)

test("toast: the alert sound plays when the host says so, on the host's kit or the default", function()
  local t, m = newToast({ sound = function() return true end })
  t:Show("a")
  assertEqual(#m.__sounds, 1)
  assertEqual(m.__sounds[1].id, m.SOUNDKIT.UI_EPICLOOT_TOAST)
  assertEqual(m.__sounds[1].channel, "Master")
  local t2, m2 = newToast({ sound = true, soundKit = 12345 })
  t2:Show("a")
  assertEqual(m2.__sounds[1].id, 12345)
  local t3, m3 = newToast({ sound = true })
  m3.SOUNDKIT = { RAID_WARNING = 8959 }
  t3:Show("a")
  assertEqual(m3.__sounds[1].id, 8959, "the raid warning when the loot toast's entry is absent")
end)

test("toast: soundFile plays the host's file on Master, and nothing else plays", function()
  -- red under: the kit path alone, which plays the default alert and ignores the file.
  local t, m = newToast({ sound = true, soundFile = "Interface\\Host\\Ding.ogg", soundKit = 12345 })
  t:Show("a")
  assertEqual(#m.__files, 1)
  assertEqual(m.__files[1].file, "Interface\\Host\\Ding.ogg")
  assertEqual(m.__files[1].channel, "Master")
  assertEqual(#m.__sounds, 0, "the file wins over the kit")
  local t2, m2 = newToast({ sound = true, soundFile = 567890 })
  t2:Show("a")
  assertEqual(m2.__files[1].file, 567890, "a file data id")
  assertEqual(#m2.__sounds, 0)
end)

test("toast: soundFile may be a getter, read as each toast shows", function()
  local file = "Interface\\Host\\One.ogg"
  local t, m = newToast({ sound = true, soundFile = function() return file end })
  t:Show("a")
  t:Dismiss()
  file = "Interface\\Host\\Two.ogg"
  t:Show("b")
  assertEqual(#m.__files, 2)
  assertEqual(m.__files[1].file, "Interface\\Host\\One.ogg")
  assertEqual(m.__files[2].file, "Interface\\Host\\Two.ogg")
  file = nil
  t:Dismiss()
  t:Show("c")
  assertEqual(#m.__files, 2, "a getter that answers nothing plays no file")
  assertEqual(m.__sounds[1].id, m.SOUNDKIT.UI_EPICLOOT_TOAST, "and the kit path plays")
end)

test("toast: a soundFile that is no file falls to the kit path as it always did", function()
  -- Hoisted out of the for header: lizard 1.24.0 does not see a function literal there.
  local blank = function() return "" end
  for _, bad in ipairs({ "", blank, true, {} }) do
    local t, m = newToast({ sound = true, soundFile = bad, soundKit = 12345 })
    t:Show("a")
    assertEqual(#m.__files, 0)
    assertEqual(#m.__sounds, 1)
    assertEqual(m.__sounds[1].id, 12345)
    assertEqual(m.__sounds[1].channel, "Master")
  end
end)

test("toast: soundFile stays behind d.sound, and a client without PlaySoundFile plays nothing", function()
  for _, off in ipairs({ false, "yes" }) do
    local t, m = newToast({ sound = off, soundFile = "Interface\\Host\\Ding.ogg" })
    t:Show("a")
    assertEqual(#m.__files, 0, "the host said no")
    assertEqual(#m.__sounds, 0)
  end
  local t, m = newToast({ sound = true, soundFile = "Interface\\Host\\Ding.ogg" })
  m.PlaySoundFile = nil
  t:Show("a")
  assertEqual(#m.__sounds, 0, "a named file never turns into the default alert")
end)

test("toast: no sound when the host says no", function()
  -- Hoisted out of the for header: lizard 1.24.0 does not see a function literal there.
  local never = function() return false end
  for _, off in ipairs({ false, never }) do
    local t, m = newToast({ sound = off })
    t:Show("a")
    assertEqual(#m.__sounds, 0)
  end
  local t, m = newToast()
  t:Show("a")
  assertEqual(#m.__sounds, 0, "sound is opt-in")
end)

test("toast: the frame takes the host's scale, read again on Refresh", function()
  local scale = 1.5
  local t = newToast({ scale = function() return scale end })
  t:Show("a")
  assertEqual(t:Frame().__scale, 1.5)
  scale = 0.75
  t:Refresh()
  assertEqual(t:Frame().__scale, 0.75)
  scale = -1
  t:Refresh()
  assertEqual(t:Frame().__scale, 1, "a scale the frame cannot take is 1")
end)

-- ── placement ────────────────────────────────────────────────────────────────────────────────

test("toast: the saved position is applied in UIParent's units, divided by the scale", function()
  local t, m = newToast({ scale = 2, getPosition = function() return { "CENTER", "BOTTOM", 100, 40 } end })
  t:Show("a")
  local p = t:Frame().__point
  assertEqual(p[1], "CENTER")
  assertEqual(p[2], m.UIParent)
  assertEqual(p[3], "BOTTOM")
  assertEqual(p[4], 50)
  assertEqual(p[5], 20)
end)

test("toast: with no saved position it sits at defaultPosition, else POINT", function()
  local t, _, _, Toast = newToast({ getPosition = function() return nil end })
  t:Show("a")
  local p = t:Frame().__point
  assertEqual(p[1], Toast.POINT[1])
  assertEqual(p[5], Toast.POINT[4])
  local t2 = newToast({ defaultPosition = { "BOTTOM", "BOTTOM", 0, 200 },
    getPosition = function() return { 42 } end })
  t2:Show("a")
  assertEqual(t2:Frame().__point[1], "BOTTOM")
  assertEqual(t2:Frame().__point[5], 200)
end)

test("toast: it drags only while the host says it may", function()
  local allowed, saved = false, {}
  local t = newToast({
    draggable = function() return allowed end,
    setPosition = function(pt) saved[#saved + 1] = pt end,
  })
  t:Show("a")
  local f = t:Frame()
  f:__fire("OnDragStart")
  assertFalse(f.__moving == true, "not draggable: no move")
  f:__fire("OnDragStop")
  assertEqual(#saved, 0, "and nothing saved")
  allowed = true
  f:__fire("OnDragStart")
  assertTrue(f.__moving)
  f:__fire("OnDragStop")
  assertFalse(f.__moving)
  assertEqual(#saved, 1)
end)

test("toast: a drag saves the point times the scale, so the anchor survives a scale change", function()
  local stored
  local scale = 2
  local t, m = newToast({
    draggable = true, scale = function() return scale end,
    getPosition = function() return stored end,
    setPosition = function(pt) stored = pt end,
  })
  t:Show("a")
  local f = t:Frame()
  f:__fire("OnDragStart")
  f.__point = { "TOPLEFT", m.UIParent, "TOPLEFT", 30, -15 }
  f:__fire("OnDragStop")
  assertEqual(stored[1], "TOPLEFT")
  assertEqual(stored[2], "TOPLEFT")
  assertEqual(stored[3], 60)
  assertEqual(stored[4], -30)
  scale = 3
  t:Refresh()
  assertEqual(f.__point[4], 20, "60 UIParent units at scale 3")
  assertEqual(f.__point[5], -10)
end)

test("toast: ResetPosition hands the host nil and goes back to the default", function()
  local stored = { "LEFT", "LEFT", 5, 5 }
  local calls = 0
  local t, _, _, Toast = newToast({
    getPosition = function() return stored end,
    setPosition = function(pt) calls = calls + 1; stored = pt end,
  })
  t:Show("a")
  t:ResetPosition()
  assertEqual(calls, 1)
  assertNil(stored)
  assertEqual(t:Frame().__point[1], Toast.POINT[1])
end)

-- ── hold, clear and preview ──────────────────────────────────────────────────────────────────

test("toast: Hold puts the toast on screen back at the head and shows nothing until Release", function()
  local t, m = newToast()
  t:Show("a")
  t:Show("b")
  t:Hold()
  assertNil(t:Current())
  assertEqual(live(m), 0)
  assertTrue(t:Stats().held)
  t:Show("c")
  assertNil(t:Current(), "a held toast queues and does not show")
  assertEqual(t:Stats().waiting, 3)
  t:Release()
  assertEqual(t:Current(), "a", "the held toast shows first")
  t:Dismiss()
  assertEqual(t:Current(), "b")
end)

test("toast: Hold(true) keeps the toast on screen and holds only what follows it", function()
  local t, m = newToast()
  t:Show("a")
  t:Show("b")
  t:Hold(true)
  assertEqual(t:Current(), "a", "the toast on screen stays up")
  assertEqual(live(m), 1, "and keeps its countdown")
  assertTrue(t:Stats().held)
  t:Dismiss()
  assertNil(t:Current(), "what waits behind the hold still waits")
  assertEqual(t:Stats().waiting, 1)
  t:Release()
  assertEqual(t:Current(), "b")
end)

test("toast: a held toast gets its full duration again when it returns", function()
  local t, m = newToast({ duration = 6 })
  m.__now = 0
  t:Show("a")
  m.__now = 4
  t:Hold()
  m.__now = 50
  t:Release()
  assertEqual(t:Current(), "a")
  assertEqual(lastTimer(m).delay, 6, "not the 2 it had left")
end)

test("toast: Preview shows past a Hold without releasing it", function()
  local t, _, _, Toast = newToast()
  t:Hold()
  t:Show("x")
  t:Preview("s")
  assertEqual(t:Current(), "s", "the preview shows while held")
  assertTrue(t:Stats().held, "the hold stands")
  t:Remove(Toast.PREVIEW)
  assertNil(t:Current(), "what waits behind the hold still waits")
  assertTrue(t:Stats().held)
  t:Release()
  assertEqual(t:Current(), "x")
end)

test("toast: Clear is the stand-down: nothing on screen, nothing waiting, no countdown, no hold", function()
  local t, m = newToast()
  t:Show("a")
  t:Show("b")
  t:Hold()
  t:Clear()
  assertNil(t:Current())
  assertEqual(t:Stats().waiting, 0)
  assertFalse(t:Stats().held)
  assertEqual(live(m), 0)
  assertFalse(t:Frame():IsShown())
  t:Show("c")
  assertEqual(t:Current(), "c", "it works again after a stand-down")
end)

test("toast: Clear before anything was shown builds nothing", function()
  local t, m = newToast()
  t:Clear()
  assertEqual(#m.__made, 0)
end)

test("toast: Preview shows now, sticky, and the toast it covered waits at the head", function()
  local t, m, _, Toast = newToast()
  t:Show("live")
  t:Show("next")
  t:Preview("sample")
  local payload, key = t:Current()
  assertEqual(payload, "sample")
  assertEqual(key, Toast.PREVIEW)
  assertTrue(t:Stats().sticky)
  assertEqual(live(m), 0, "a preview stays until it is closed")
  t:Preview("sample 2")
  assertEqual(t:Current(), "sample 2", "a second preview replaces the first")
  assertEqual(t:Stats().waiting, 2, "the first preview is not queued behind it")
  assertEqual(t:Remove(Toast.PREVIEW), 1)
  assertEqual(t:Current(), "live", "the covered toast shows again")
  t:Dismiss()
  assertEqual(t:Current(), "next")
end)

-- ── the host's view ──────────────────────────────────────────────────────────────────────────

test("toast: Stats and Current describe the toast", function()
  local t = newToast()
  t:Show("a", { key = "k" })
  t:Show("b")
  local s = t:Stats()
  assertTrue(s.built)
  assertTrue(s.shown)
  assertEqual(s.waiting, 1)
  assertEqual(s.key, "k")
  assertFalse(s.held)
  local payload, key = t:Current()
  assertEqual(payload, "a")
  assertEqual(key, "k")
end)

test("toast: the debug sink hears the shell, and a sink that raises costs nothing", function()
  local lines = {}
  local t = newToast({ debug = function(tag, fmt, ...) lines[#lines + 1] = tag .. " " .. fmt:format(...) end })
  t:Show("a")
  t:Show("b")
  assertTrue(#lines >= 2)
  assertTrue(lines[1]:find("^TOAST ") ~= nil)
  local t2 = newToast({ debug = function() error("sink") end })
  t2:Show("a")
  assertEqual(t2:Current(), "a")
end)

-- ── what the shell asks of Core ──────────────────────────────────────────────────────────────

test("toast: the skin and the close mark are Core's, called with the host's owner", function()
  local calls = {}
  local t = newToast({ owner = "HostAddon" }, function(m)
    local core = m.LibStub:NewLibrary("LibKa0s-Core-1.0", 12)
    core.MINOR = 12
    core.ApplySkin = function(...) calls.skin = { n = select("#", ...), ... } end
    core.MakeCloseButton = function(parent, onClick, addonName)
      calls.close = { parent = parent, addonName = addonName }
      local b = m.CreateFrame("Button", nil, parent)
      b:SetScript("OnClick", onClick)
      return b
    end
  end)
  t:Show("a")
  assertEqual(calls.skin[1], t:Frame())
  assertNil(calls.skin[2], "no skin table: Core's own, or the owner's")
  assertEqual(calls.skin[3], "HostAddon")
  assertEqual(calls.close.parent, t:Frame())
  assertEqual(calls.close.addonName, "HostAddon")
  t:Frame().close:__fire("OnClick")
  assertNil(t:Current())
end)

test("toast: on a Core with no ApplySkin or MakeCloseButton it still shows and closes", function()
  local t = newToast(nil, function(m)
    local core = m.LibStub:NewLibrary("LibKa0s-Core-1.0", 1)
    core.MINOR = 1
  end)
  t:Show("a")
  assertEqual(t:Current(), "a")
  assertNil(t:Frame().close, "no close mark")
  t:Frame():__fire("OnMouseUp", "RightButton")
  assertNil(t:Current(), "a right-click still closes it")
end)

test("toast: a close mark Core cannot build (no frame) leaves the toast without one", function()
  local t = newToast(nil, function(m)
    local core = m.LibStub:NewLibrary("LibKa0s-Core-1.0", 12)
    core.MINOR = 12
    core.MakeCloseButton = function() return nil end
  end)
  t:Show("a")
  assertNil(t:Frame().close)
end)

test("toast: two instances keep separate queues and frames", function()
  local m, Toast = env()
  local a = Toast:New({ build = function() end })
  local b = Toast:New({ build = function() end })
  a:Show(1)
  a:Show(2)
  b:Show(3)
  assertEqual(a:Current(), 1)
  assertEqual(b:Current(), 3)
  assertTrue(a:Frame() ~= b:Frame())
  b:Clear()
  assertEqual(a:Stats().waiting, 1)
  assertTrue(#m.__made >= 2)
end)

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
