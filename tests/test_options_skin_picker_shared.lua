-- tests/test_options_skin_picker_shared.lua -- the skin picker's one window across addons: two
-- Options instances sharing one library table, the queue, combat, and onClose once per showing.
-- Moved unchanged out of tests/test_options_skin_picker.lua on the seam the watch list named
-- (FX-LK-SIZE of Ka0sAddonsCommonTasks docs/2026-10-31-FINDINGS_REMEDIATION); the bench is shared
-- through tests/fixture_skin_picker.lua.

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  K.test, K.assertEqual, K.assertTrue, K.assertFalse, K.assertNil

local Bench = dofile("tests/fixture_skin_picker.lua")
local OWNER, OTHER, THIRD = Bench.OWNER, Bench.OTHER, Bench.THIRD
local env, register, instance, specFor = Bench.env, Bench.register, Bench.instance, Bench.specFor
local pickRow, applied, armClientHide = Bench.pickRow, Bench.applied, Bench.armClientHide

-- ── one window across addons ─────────────────────────────────────────────────────────────────

test("skin picker: two instances on one library: the second owner queues, and shows when the first closes",
function()
  -- red under: one window per instance (each addon showed its own picker at once).
  local _, Skin, lib = env()
  local storeA = register(Skin, OWNER)
  local storeB = register(Skin, OTHER)
  local A, B = instance(lib, OWNER), instance(lib, OTHER)
  local a = A.SkinPicker(specFor(storeA))
  local b, why = B.SkinPicker(specFor(storeB))
  assertNil(b, "no frame for a queued picker")
  assertEqual(why, "queued")
  assertTrue(a:IsShown(), "the first stays up")
  assertEqual(#lib.__pickerQueue.waiting, 1)
  local refreshed = specFor(storeB, { strings = { TITLE = "Second" } })
  assertNil(B.SkinPicker(refreshed), "a repeat call")
  assertEqual(#lib.__pickerQueue.waiting, 1, "one entry per owner")
  assertNil(storeB.closed, "a queued picker is not closed")
  a.close:__fire("OnClick")
  assertEqual(storeA.closed, 1)
  local q = lib.__pickerQueue
  assertTrue(q.current ~= nil and q.current.owner == OTHER, "the second owner's picker is up")
  b = q.current.frame
  assertTrue(b:IsShown() and b ~= a, "its own window")
  assertEqual(b.title:GetText(), "Second", "with the spec the repeat call gave")
  assertEqual(b.ownerLabel:GetText(), OTHER .. " Label")
  b.apply:__fire("OnClick")
  assertEqual(storeB.closed, 1)
  assertNil(q.current, "nothing left to show")
end)

test("skin picker: a queued owner waits out combat and shows when it ends", function()
  -- red under: advance() showing the next owner at once, mid-combat (PK-03).
  local m, Skin, lib = env()
  local storeA = register(Skin, OWNER)
  local storeB = register(Skin, OTHER)
  local storeC = register(Skin, THIRD)
  local A, B, C = instance(lib, OWNER), instance(lib, OTHER), instance(lib, THIRD)
  local a = A.SkinPicker(specFor(storeA))
  assertNil(B.SkinPicker(specFor(storeB)), "queued")
  m.InCombatLockdown = function() return true end
  a.close:__fire("OnClick")
  assertEqual(storeA.closed, 1, "the close still closes in combat")
  local q = lib.__pickerQueue
  assertNil(q.current, "nothing shown mid-combat")
  assertEqual(#q.waiting, 1, "the next owner stays queued")
  assertEqual(q.waiting[1].owner, OTHER)
  assertNil(storeB.closed)
  local c, why = C.SkinPicker(specFor(storeC))
  assertNil(c, "a call while the queue waits out combat queues behind it")
  assertEqual(why, "queued")
  assertEqual(#q.waiting, 2)
  m.InCombatLockdown = function() return false end
  assertTrue(lib.__parkFrame ~= nil, "parked on the library's end-of-combat park")
  lib.__parkFrame:__fire("OnEvent", "PLAYER_REGEN_ENABLED")
  assertTrue(q.current ~= nil and q.current.owner == OTHER, "the first queued shows when combat ends")
  assertTrue(q.current.frame:IsShown())
  assertEqual(#q.waiting, 1, "the other still waits behind it")
  q.current.frame.apply:__fire("OnClick")
  assertEqual(q.current.owner, THIRD, "out of combat the queue advances at once")
end)

test("skin picker: a queue dismissed while waiting out combat shows nothing when combat ends", function()
  local m, Skin, lib = env()
  local storeA = register(Skin, OWNER)
  local storeB = register(Skin, OTHER)
  local A, B = instance(lib, OWNER), instance(lib, OTHER)
  local a = A.SkinPicker(specFor(storeA))
  B.SkinPicker(specFor(storeB))
  m.InCombatLockdown = function() return true end
  a.close:__fire("OnClick")
  B.HideSkinPicker()
  m.InCombatLockdown = function() return false end
  lib.__parkFrame:__fire("OnEvent", "PLAYER_REGEN_ENABLED")
  assertNil(lib.__pickerQueue.current, "nothing to show")
  assertNil(storeB.closed, "never seen")
  assertTrue(A.SkinPicker(specFor(storeA)) ~= nil, "a later call shows at once: the park let go")
end)

test("skin picker: a queued owner is shown after Apply and after the gear, too", function()
  local _, Skin, lib = env()
  local storeA = register(Skin, OWNER)
  local storeB = register(Skin, OTHER)
  local storeC = register(Skin, THIRD)
  local A, B, C = instance(lib, OWNER), instance(lib, OTHER), instance(lib, THIRD)
  local a = A.SkinPicker(specFor(storeA))
  B.SkinPicker(specFor(storeB))
  C.SkinPicker(specFor(storeC, { onSettings = function() end }))
  a.apply:__fire("OnClick")
  local q = lib.__pickerQueue
  assertEqual(q.current.owner, OTHER, "queue order: the first queued")
  q.current.frame.settings:__fire("OnClick")
  assertEqual(storeB.closed, 1, "the gear closed it")
  assertEqual(q.current.owner, THIRD, "then the next")
end)

test("skin picker: HideSkinPicker takes a queued owner out unseen, and a shown one down with onClose", function()
  local _, Skin, lib = env()
  local storeA = register(Skin, OWNER)
  local storeB = register(Skin, OTHER)
  local A, B = instance(lib, OWNER), instance(lib, OTHER)
  local a = A.SkinPicker(specFor(storeA))
  B.SkinPicker(specFor(storeB))
  B.HideSkinPicker()
  assertEqual(#lib.__pickerQueue.waiting, 0, "out of the queue")
  assertNil(storeB.closed, "no onClose: it was never seen")
  assertTrue(a:IsShown(), "the shown one is not B's to hide")
  B.SkinPicker(specFor(storeB))
  A.HideSkinPicker()
  assertEqual(storeA.closed, 1, "the shown one closes, onClose as for any close")
  assertEqual(lib.__pickerQueue.current.owner, OTHER, "and the next shows")
end)

test("skin picker: one instance's second owner queues behind its first, each refreshed only by its own",
function()
  -- red under: minor 1, which hid the first owner's window (running its onClose) to show the second.
  local _, Skin, lib = env()
  local storeA = register(Skin, OWNER)
  local storeB = register(Skin, "Other")
  local O = instance(lib, OWNER)
  local a = O.SkinPicker(specFor(storeA))
  assertNil(O.SkinPicker(specFor(storeB, { owner = "Other" })), "queued")
  assertTrue(a:IsShown(), "the first stays up")
  assertNil(storeA.closed)
  O.SkinPicker(specFor(storeA))   -- the first owner again: still its window, nothing queued for it
  a.close:__fire("OnClick")
  local b = lib.__pickerQueue.current.frame
  assertTrue(a ~= b and b:IsShown(), "the other owner's own window")
  assertEqual(storeA.closed, 1, "closed once")
  a:__fire("OnHide")
  assertTrue(b:IsShown(), "a late OnHide of the first window does not close the second")
  assertNil(storeB.closed)
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(b.dd.text:GetText(), Skin:GetSkin("ka0s").label, "the first owner's switch leaves the second alone")
  storeB.skin = "ember"
  Skin:SetChoice("Other", "ka0s", "ember")
  assertEqual(b.dd.text:GetText(), Skin:GetSkin("ember").label, "its own owner's switch refreshes it")
  storeA.skin = "obsidian"
  assertNil(O.SkinPicker(specFor(storeA)), "the first owner queued behind the second")
  b.close:__fire("OnClick")
  assertTrue(lib.__pickerQueue.current.frame == a, "the first owner's window again, reused")
  assertEqual(a.dd.text:GetText(), Skin:GetSkin("obsidian").label, "refreshed on show")
end)

test("skin picker: with the client's own OnHide, one instance's first owner closing leaves the second up",
function()
  -- red under: hide()'s close read the instance's current picker after the synchronous OnHide had
  -- already closed the first and shown the second, so it closed the second too (its onClose run, its
  -- window left on screen as a picker nobody owned, the queue emptied).
  local m, Skin, lib = env()
  armClientHide(m)
  local storeA = register(Skin, OWNER)
  local storeB = register(Skin, "Other")
  local O = instance(lib, OWNER)
  local a = O.SkinPicker(specFor(storeA))
  assertNil(O.SkinPicker(specFor(storeB, { owner = "Other" })), "queued")
  a.close:__fire("OnClick")
  assertEqual(storeA.closed, 1, "the first closed once")
  local q = lib.__pickerQueue
  assertTrue(q.current ~= nil and q.current.owner == "Other", "the second is the picker up")
  local b = q.current.frame
  assertTrue(b ~= a and b:IsShown(), "its own window, shown")
  assertNil(storeB.closed, "the second's onClose has not run")
  pickRow(b, "ember")
  assertEqual(applied(Skin, "Other"), "ember", "the second still previews")
  assertNil(O.SkinPicker(specFor(storeA)), "the first queued behind it")
  b.apply:__fire("OnClick")
  assertEqual(storeB.calls[1][2], "ember", "Apply saved the second's pick")
  assertEqual(storeB.closed, 1, "the second closed once")
  assertTrue(q.current ~= nil and q.current.frame == a and a:IsShown(), "the first shows again")
  assertNil(storeA.calls, "the first's write seam untouched")
  assertEqual(storeA.closed, 1, "and its onClose not run by the second's Apply")
  O.HideSkinPicker()
  assertEqual(storeA.closed, 2, "HideSkinPicker closes it once")
  assertNil(q.current, "nothing left up")
end)

test("skin picker: with the client's own OnHide, onClose still runs once per showing, by every route",
function()
  local m, Skin, lib = env()
  armClientHide(m)
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  f.close:__fire("OnClick")
  assertEqual(store.closed, 1, "the close control")
  O.SkinPicker(specFor(store))
  f.apply:__fire("OnClick")
  assertEqual(store.closed, 2, "Apply")
  O.SkinPicker(specFor(store, { onSettings = function() end }))
  f.settings:__fire("OnClick")
  assertEqual(store.closed, 3, "the gear")
  O.SkinPicker(specFor(store))
  O.HideSkinPicker()
  assertEqual(store.closed, 4, "HideSkinPicker")
  O.SkinPicker(specFor(store))
  f:Hide()
  assertEqual(store.closed, 5, "Escape")
  assertNil(lib.__pickerQueue.current)
end)

test("skin picker: a skin registered after the first show gains its row on the next", function()
  -- red under: the rows built once per window.
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  local before = #{ f.list:GetChildren() }
  Skin:RegisterSkin({ key = "late", label = "Late Skin", swatches = { "#112233", "#445566", "#778899" },
                      tokens = {} })
  O.HideSkinPicker()
  O.SkinPicker(specFor(store))
  local rows = { f.list:GetChildren() }
  assertEqual(#rows, before + 1, "one row added")
  assertEqual(rows[#rows].key, "late", "at the end")
  assertEqual(rows[#rows].text:GetText(), "Late Skin")
end)

test("skin picker: onClose runs once per showing, by every route", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local f = O.SkinPicker(specFor(store))
  f.close:__fire("OnClick")
  assertFalse(f:IsShown(), "the close control closes")
  f:__fire("OnHide")
  O.HideSkinPicker()
  assertEqual(store.closed, 1, "once, though the client's OnHide follows")
  O.SkinPicker(specFor(store))
  O.HideSkinPicker()
  assertEqual(store.closed, 2, "HideSkinPicker is a route too")
  O.SkinPicker(specFor(store))
  f:__fire("OnHide")
  assertEqual(store.closed, 2, "an OnHide while still shown (UIParent hidden) is not a close")
  f:Hide(); f:__fire("OnHide")
  assertEqual(store.closed, 3, "Escape (the client's hide) is")
  O.SkinPicker(specFor(store))
  f.apply:__fire("OnClick")
  assertEqual(store.closed, 4, "and Apply")
end)
