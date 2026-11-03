-- tests/test_options_skin_picker_close.lua -- the skin picker's list closes on a press outside it
-- (OptionsSkinPicker.lua minor 10; R5-L4 of Ka0sAddonsCommonTasks docs/2026-11-03-SMOKE_ROUND5,
-- the owner's item 6, images 46 and 47, and the lead's call 7).
--
-- The list is the one Ka0s pullout that is neither an AceGUI pullout (OptionsCombat's watcher, R4-L1)
-- nor the shared Widgets menu, so neither of their seams reached it, and an outside press did
-- nothing. It now LISTENS for GLOBAL_MOUSE_DOWN itself, on its own frame, while it is open, as the
-- Widgets menu (Widgets.lua's __OutsideClick) and LootHistory's BrowserTable row menu do. A press
-- over neither the list (a row, or the gutter between rows) nor its dropdown button closes it,
-- including a press on the picker's own body, title, eye or gear, whose own click still runs.
-- Nothing is caught. Each picker's list listens on its own frame, so two close independently.
-- Escape is unchanged: it closes the window.
--
-- The kit's frames answer IsMouseOver with the frame (truthy, never `true`), so the bench pins it
-- per frame through `over`.

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse =
  K.test, K.assertEqual, K.assertTrue, K.assertFalse

local Bench = dofile("tests/fixture_skin_picker.lua")
local OWNER, OTHER = Bench.OWNER, Bench.OTHER
local env, register, instance, specFor = Bench.env, Bench.register, Bench.instance, Bench.specFor

local MOUSE_DOWN = "GLOBAL_MOUSE_DOWN"

--- `frame` answers IsMouseOver from `frame.__over`, false until a case sets it.
local function hoverable(frame)
  frame.__over = false
  rawset(frame, "IsMouseOver", function(self) return self.__over == true end)
  return frame
end

--- Every frame a press can land on in `f`'s window made hoverable: the window, the list, the
--- dropdown, the eye, the gear, the close control and the list's rows.
local function armHover(f)
  for _, fr in ipairs({ f, f.list, f.dd, f.preview, f.settings, f.close }) do
    if fr then hoverable(fr) end
  end
  for _, row in ipairs({ f.list:GetChildren() }) do hoverable(row) end
end

--- The mouse over exactly `frames` in `f`'s window (nothing else), then a press, as the client
--- sends GLOBAL_MOUSE_DOWN to every frame registered for it.
local function press(f, frames)
  for _, fr in ipairs({ f, f.list, f.dd, f.preview, f.settings, f.close }) do
    if fr then fr.__over = false end
  end
  for _, row in ipairs({ f.list:GetChildren() }) do row.__over = false end
  for _, fr in ipairs(frames or {}) do fr.__over = true end
  if f.list:IsEventRegistered(MOUSE_DOWN) then f.list:__fire("OnEvent", MOUSE_DOWN, "LeftButton") end
end

local function listening(f) return f.list:IsEventRegistered(MOUSE_DOWN) == true end

--- A shown picker with its list open, every frame hoverable.
local function openPicker(extra)
  local m, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store, extra))
  armHover(f)
  f.dd:__fire("OnClick")
  assertTrue(f.list:IsShown(), "the dropdown's click opens the list")
  return f, store, O, m, Skin
end

local function firstRow(f)
  for _, row in ipairs({ f.list:GetChildren() }) do if row.key then return row end end
end

-- ── listening ────────────────────────────────────────────────────────────────────────────────

test("skin picker close: the list listens for GLOBAL_MOUSE_DOWN only while it is open", function()
  -- red under: minor 10 before R5-L4, where nothing registered and an outside press did nothing.
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  assertFalse(listening(f), "a closed list listens to nothing")
  f.dd:__fire("OnClick")
  assertTrue(listening(f), "an open list listens")
  f.dd:__fire("OnClick")
  assertFalse(f.list:IsShown(), "the toggle still closes it")
  assertFalse(listening(f), "and lets go")
end)

test("skin picker close: a press outside the window closes the list, the window stays up", function()
  -- red under: before R5-L4 (images 46 and 47), the list stayed open.
  local f = openPicker()
  press(f, {})
  assertFalse(f.list:IsShown(), "closed")
  assertTrue(f:IsShown(), "the window stays")
  assertFalse(listening(f), "and lets go")
end)

-- ── presses that are not outside ─────────────────────────────────────────────────────────────

test("skin picker close: a press on a row or the gutter between rows does not close before the pick", function()
  local f, _, _, _, Skin = openPicker()
  local row = firstRow(f)
  press(f, { f.list })   -- the gutter: over the list, no row
  assertTrue(f.list:IsShown(), "the gutter keeps it open")
  press(f, { f.list, row })
  assertTrue(f.list:IsShown(), "so a row's release still finds it open")
  assertTrue(listening(f), "still listening")
  row:__fire("OnClick")
  assertFalse(f.list:IsShown(), "the pick closes it")
  assertEqual(select(2, Skin:GetChoice(OWNER)), row.key, "and previews the row's skin")
  assertFalse(listening(f), "a pick lets go")
end)

test("skin picker close: a press on the dropdown button leaves it to the button's own toggle", function()
  local f = openPicker()
  press(f, { f, f.dd })
  assertTrue(f.list:IsShown(), "not closed on the press")
  f.dd:__fire("OnClick")
  assertFalse(f.list:IsShown(), "the release toggles it closed, once")
  assertFalse(listening(f))
end)

-- ── presses inside the window that are outside the list ──────────────────────────────────────

test("skin picker close: a press on the window's body or title closes the list", function()
  local f = openPicker()
  press(f, { f })
  assertFalse(f.list:IsShown(), "the body closes it")
  assertTrue(f:IsShown(), "the window stays")
  f.dd:__fire("OnClick")
  assertTrue(f.list:IsShown(), "opens again")
  press(f, { f })   -- the title is a FontString on the window: the press is the window's
  f:__fire("OnMouseDown", "LeftButton")
  assertFalse(f.list:IsShown(), "the title closes it")
end)

test("skin picker close: a press on the eye closes the list and the eye still runs", function()
  local previews = 0
  local f = openPicker({ onPreview = function() previews = previews + 1 end })
  assertTrue(f.preview:IsShown(), "the eye is shown")
  press(f, { f, f.preview })
  assertFalse(f.list:IsShown(), "the press closes the list")
  f.preview:__fire("OnClick")
  assertEqual(previews, 1, "the eye's own click runs")
  assertTrue(f:IsShown(), "the window stays")
end)

test("skin picker close: a press on the gear closes the list and the gear still runs", function()
  local opened = 0
  local f, store = openPicker({ onSettings = function() opened = opened + 1 end })
  press(f, { f, f.settings })
  assertFalse(f.list:IsShown(), "the press closes the list")
  f.settings:__fire("OnClick")
  assertEqual(opened, 1, "the gear's own click runs")
  assertEqual(store.closed, 1, "and closes the window, as it does")
end)

-- ── two pickers, Escape, every close route ───────────────────────────────────────────────────

test("skin picker close: two open pickers' lists close independently", function()
  -- One picker is up at a time through the library's queue; the queue is emptied here to stand two
  -- up at once, so what is pinned is that no state is shared between the lists.
  local _, Skin, lib = env()
  local storeA, storeB = register(Skin, OWNER), register(Skin, OTHER)
  local A, B = instance(lib, OWNER), instance(lib, OTHER)
  local a = A.SkinPicker(specFor(storeA))
  lib.__pickerQueue.current = nil
  local b = B.SkinPicker(specFor(storeB))
  assertTrue(a ~= nil and b ~= nil and a ~= b, "two windows")
  armHover(a)
  armHover(b)
  a.dd:__fire("OnClick")
  b.dd:__fire("OnClick")
  assertTrue(listening(a) and listening(b), "each listens on its own list")
  -- A press on b's list is outside a's: the client sends it to both lists.
  a.list.__over, b.list.__over = false, true
  a.list:__fire("OnEvent", MOUSE_DOWN, "LeftButton")
  b.list:__fire("OnEvent", MOUSE_DOWN, "LeftButton")
  assertFalse(a.list:IsShown(), "a's list closes")
  assertTrue(b.list:IsShown(), "b's stays open")
  assertFalse(listening(a), "a lets go")
  assertTrue(listening(b), "b still listens")
  press(b, {})
  assertFalse(b.list:IsShown(), "b's closes on its own outside press")
end)

test("skin picker close: Escape still closes the window, the open list and its listener with it", function()
  local m, Skin, lib = env()
  Bench.armClientHide(m)
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  armHover(f)
  f.dd:__fire("OnClick")
  assertTrue(listening(f))
  f:Hide()   -- what UISpecialFrames does on Escape
  assertEqual(store.closed, 1, "the window closed")
  assertFalse(f.list:IsShown(), "the list with it")
  assertFalse(listening(f), "and nothing listens")
end)

test("skin picker close: a list hidden by another route lets go and closes nothing on the next press", function()
  local f = openPicker()
  f.list:Hide()
  f.list:__fire("OnHide")
  assertFalse(listening(f), "its OnHide lets go")
  f.dd:__fire("OnClick")   -- the picker still reads the list as open: the toggle closes it
  f.dd:__fire("OnClick")
  assertTrue(f.list:IsShown() and listening(f), "the next open listens again")
  f.list:__fire("OnEvent", "SOME_OTHER_EVENT")
  assertTrue(f.list:IsShown(), "another event closes nothing")
end)

test("skin picker close: an open list hidden with its window's parent listens again when shown", function()
  -- Alt-Z hides UIParent: the open list fires OnHide and lets go, then OnShow when the UI returns.
  local f = openPicker()
  f.list:__fire("OnHide")
  assertFalse(listening(f), "lets go while hidden")
  f.list:__fire("OnShow")
  assertTrue(listening(f), "listens again, the list still open")
  press(f, {})
  assertFalse(f.list:IsShown(), "and an outside press closes it")
end)

test("skin picker close: a press arriving after the list closed calls nothing and lets go", function()
  local f = openPicker()
  local row = firstRow(f)
  row:__fire("OnClick")
  assertFalse(f.list:IsShown())
  -- A late press, as one already queued when the pick closed the list.
  f.list:__fire("OnEvent", MOUSE_DOWN, "LeftButton")
  assertFalse(f.list:IsShown(), "still closed")
  assertFalse(listening(f))
end)

test("skin picker close: without Core's SafeRegisterEvent the list registers nothing and still toggles", function()
  local m, Skin, lib = env()
  local core = m.LibStub("LibKa0s-Core-1.0")
  local safe = core.SafeRegisterEvent
  core.SafeRegisterEvent = nil
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  f.dd:__fire("OnClick")
  assertTrue(f.list:IsShown(), "opens")
  assertFalse(listening(f), "no raw registration (CLAUDE.md's events-frames-taint-§1 row)")
  f.dd:__fire("OnClick")
  assertFalse(f.list:IsShown(), "closes by its toggle")
  core.SafeRegisterEvent = safe
end)
