-- tests/test_options_keybinds_sync.lua -- LibKa0s-Options-1.0's Keybindings tab following Options ->
-- Keybindings (OptionsKeybinds.lua minor 3, options-ui-§20; KEYBINDINGS_RESEARCH §3.1, §3.4 and
-- §5.1 "Syncing" of Ka0sAddonsCommonTasks docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/).
--
-- What it pins: one library frame (lib.__keybindEventFrame) that hears UPDATE_BINDINGS only while a
-- keybind row is on screen, registered through Core's SafeRegisterEvent and never raw; a key set
-- outside the tab, or a binding set switched, repainting the slots and the set line on the next
-- frame; three events in one frame giving one repaint; the page's OnShow re-reading what changed
-- while it was hidden, with or without the event; an event that reaches the frame with no row on
-- screen drawing nothing; and a capture in progress keeping its "Press a key..." through a repaint.
--
-- Every case runs on tests/fixture_keybinds.lua's bench, which fails it on any touch of Blizzard's
-- settings window and puts the sync state back after it.

local T = _G.LK_TEST
local assertEqual, assertTrue, assertFalse, assertNil =
  T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local mocks = T.mocks
local lib = T.options
local core = T.core
local Bench = dofile("tests/fixture_keybinds.lua")
local case = Bench.case
local S = lib.KEYBIND_STRINGS

local EVENT = "UPDATE_BINDINGS"

local function frame()
  local f = lib.__keybindEventFrame
  assertTrue(f ~= nil, "the library owns one UPDATE_BINDINGS frame")
  return f
end

local function registered() return frame():IsEventRegistered(EVENT) end

local function hide(ctx)
  ctx.panel:Hide()
  ctx.panel:__fire("OnHide")
end

local function show(ctx)
  ctx.panel:Show()
  ctx.panel:__fire("OnShow")
end

-- Run whatever a page's draw queued, so a case starts counting from an empty queue.
local function drain()
  while mocks.__fireTimers() > 0 do end
end

-- ── the version ──────────────────────────────────────────────────────────────────────────────

case("keybinds sync: OptionsKeybinds is at minor 3 or later", function()
  assertTrue(lib.MODULES.OptionsKeybinds >= 3, "minor " .. tostring(lib.MODULES.OptionsKeybinds))
  assertEqual(lib.__keybindsMinor, lib.MODULES.OptionsKeybinds)
  assertEqual(type(lib.__syncKeybindEvents), "function")
  assertEqual(type(lib.__OnKeybindEvent), "function")
end)

-- ── the registration ─────────────────────────────────────────────────────────────────────────

case("keybinds sync: UPDATE_BINDINGS is heard only while a keybind row is on screen", function()
  assertFalse(registered(), "no row on screen: not registered")
  local _, _, ctx1 = Bench.rowsPage()
  assertTrue(registered(), "a page with rows on screen registers it")
  local _, _, ctx2 = Bench.rowsPage()
  hide(ctx1)
  assertTrue(registered(), "the second page still shows rows")
  hide(ctx2)
  assertFalse(registered(), "hiding the last page with rows lets go")
  show(ctx1)
  assertTrue(registered(), "showing one again registers again")
end)

case("keybinds sync: a page with no keybind rows registers nothing", function()
  Bench.page(function(O, c) O.TextRow(c, "no rows here") end)
  assertFalse(registered())
end)

case("keybinds sync: releasing the rows lets go", function()
  local _, _, _, rows = Bench.rowsPage()
  assertTrue(registered())
  local aceGUI = mocks.__libs["AceGUI-3.0"]
  for _, row in ipairs(rows()) do aceGUI:Release(row.group) end
  assertFalse(registered(), "a released row is no longer live")
  for row in pairs(lib.__keybindLive) do
    assertFalse(row == rows()[1] or row == rows()[2], "released rows leave the live set")
  end
end)

case("keybinds sync: the registration goes through Core's SafeRegisterEvent", function()
  local original = core.SafeRegisterEvent
  local calls = {}
  core.SafeRegisterEvent = function(target, event, ...)
    calls[#calls + 1] = { target = target, event = event }
    return original(target, event, ...)
  end
  local ok, err = pcall(Bench.rowsPage)
  core.SafeRegisterEvent = original
  if not ok then error(err, 0) end
  assertTrue(#calls >= 1, "SafeRegisterEvent was asked")
  assertTrue(calls[1].target == frame(), "for the library's frame")
  assertEqual(calls[1].event, EVENT)
  assertTrue(registered())
end)

case("keybinds sync: without SafeRegisterEvent nothing registers, and OnShow still re-reads", function()
  local original = core.SafeRegisterEvent
  core.SafeRegisterEvent = nil
  local ok, err = pcall(function()
    local _, _, ctx, rows = Bench.rowsPage()
    assertFalse(registered(), "no helper: no registration at all")
    hide(ctx)
    mocks.bindKey("F9", Bench.TOGGLE)
    show(ctx)
    assertEqual(rows()[1].slots[1].text, "F9", "the OnShow re-read repaints")
    for _, fn in ipairs(ctx.refreshers) do fn() end
    assertEqual(rows()[1].slots[1].text, "F9", "the refreshers still work")
  end)
  core.SafeRegisterEvent = original
  if not ok then error(err, 0) end
end)

-- ── the repaint ──────────────────────────────────────────────────────────────────────────────

case("keybinds sync: a key set in Options -> Keybindings shows on the next frame", function()
  local _, _, _, rows = Bench.rowsPage()
  drain()
  local fires = mocks.__bindingFires
  mocks.SetBinding("F6", Bench.TOGGLE)
  assertEqual(mocks.__bindingFires, fires + 1, "SetBinding fired UPDATE_BINDINGS")
  assertEqual(rows()[1].slots[1].text, mocks.NOT_BOUND, "not before the frame ends")
  assertEqual(mocks.__fireTimers(), 1, "one repaint queued")
  assertEqual(rows()[1].slots[1].text, "F6", "the slot shows the key")
end)

case("keybinds sync: three UPDATE_BINDINGS in one frame give exactly one repaint", function()
  local _, _, _, rows = Bench.rowsPage()
  drain()
  local reads = 0
  local getKey = mocks.GetBindingKey
  mocks.GetBindingKey = function(...) reads = reads + 1; return getKey(...) end
  mocks.bindKey("F2", Bench.SECOND)
  mocks.__fire(EVENT)
  mocks.__fire(EVENT)
  mocks.__fire(EVENT)
  assertEqual(reads, 0, "nothing is drawn while the events arrive")
  assertEqual(mocks.__fireTimers(), 1, "one repaint, not three")
  assertEqual(reads, #rows(), "one GetBindingKey per row")
  assertEqual(rows()[2].slots[1].text, "F2")
  assertEqual(mocks.__fireTimers(), 0, "and nothing left queued")
  mocks.__fire(EVENT)
  assertEqual(mocks.__fireTimers(), 1, "the next frame's event queues again")
end)

case("keybinds sync: LoadBindings to the other set repaints the slots and the set line", function()
  mocks.bindKey("F5", Bench.TOGGLE)
  mocks.SaveBindings(1)
  mocks.LoadBindings(2)
  mocks.bindKey("F8", Bench.TOGGLE)
  mocks.SaveBindings(2)
  mocks.LoadBindings(1)
  local _, _, ctx, rows = Bench.rowsPage()
  drain()
  assertEqual(rows()[1].slots[1].text, "F5")
  assertTrue(Bench.setLine(ctx):find("all characters", 1, true) ~= nil)
  mocks.LoadBindings(2)
  mocks.__fireTimers()
  assertEqual(rows()[1].slots[1].text, "F8", "the slots follow the set now in force")
  assertTrue(Bench.setLine(ctx):find("this character only", 1, true) ~= nil, "and the set line")
end)

case("keybinds sync: a key changed while the page was hidden shows on the next OnShow, no event",
function()
  local _, _, ctx, rows = Bench.rowsPage()
  drain()
  hide(ctx)
  assertFalse(registered())
  mocks.SetBinding("F7", Bench.TOGGLE)
  assertEqual(mocks.__fireTimers(), 0, "nobody heard it")
  assertEqual(rows()[1].slots[1].text, mocks.NOT_BOUND)
  show(ctx)
  assertEqual(rows()[1].slots[1].text, "F7", "the OnShow re-read, with no timer run")
end)

case("keybinds sync: an event delivered with no row on screen draws and prints nothing", function()
  local _, rec, ctx, rows = Bench.rowsPage()
  drain()
  hide(ctx)
  mocks.bindKey("F3", Bench.TOGGLE)
  local chat = #rec.chat
  assertEqual(mocks.__fireUnconditional(frame(), EVENT), 1, "the handler was reached")
  assertEqual(mocks.__fireTimers(), 0, "no repaint queued")
  assertNil(lib.__keybindRepaintPending)
  assertEqual(rows()[1].slots[1].text, mocks.NOT_BOUND, "nothing drawn")
  assertEqual(#rec.chat, chat, "nothing printed")
  assertFalse(registered(), "and still not registered")
end)

case("keybinds sync: a capture in progress keeps LISTENING through a repaint", function()
  local _, _, _, rows = Bench.rowsPage()
  drain()
  local r = rows()
  Bench.click(r[1].slots[1])
  assertEqual(r[1].slots[1].text, S.LISTENING)
  mocks.SetBinding("F4", Bench.SECOND)
  mocks.__fireTimers()
  assertEqual(r[1].slots[1].text, S.LISTENING, "the listening slot still says so")
  assertTrue(lib.__keybindCapture ~= nil, "and still listens")
  assertEqual(r[2].slots[1].text, "F4", "the other rows repaint")
  Bench.key("J")
  assertEqual(Bench.keys(Bench.TOGGLE), "J")
end)

case("keybinds sync: a repaint runs in combat, since it only reads", function()
  local _, _, _, rows = Bench.rowsPage()
  drain()
  Bench.enterCombat()
  mocks.bindKey("F1", Bench.TOGGLE)
  mocks.__fire(EVENT)
  mocks.__fireTimers()
  assertEqual(rows()[1].slots[1].text, "F1")
  Bench.leaveCombat()
end)

case("keybinds sync: without C_Timer the repaint runs at once", function()
  local _, _, _, rows = Bench.rowsPage()
  drain()
  local timer = mocks.C_Timer
  mocks.C_Timer = nil
  local ok, err = pcall(function()
    mocks.bindKey("F10", Bench.TOGGLE)
    mocks.__fire(EVENT)
    assertEqual(rows()[1].slots[1].text, "F10")
    assertNil(lib.__keybindRepaintPending)
  end)
  mocks.C_Timer = timer
  if not ok then error(err, 0) end
end)
