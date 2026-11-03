-- tests/test_options_skin_picker_preview.lua -- the skin picker's preview contract, spec.preview
-- (OptionsSkinPicker.lua minor 11; R6-L1 of Ka0sAddonsCommonTasks docs/2026-11-03-SMOKE_ROUND6, the
-- owner's feedback on images 62, 63 and 66, and the lead's call 1).
--
-- The owner's rule: when the picker shows and the addon's main surface is hidden, the addon enters its
-- preview mode (test mode, else unlock mode); the eye toggles that mode; when the picker closes, by
-- any route, the addon goes back to the state it had when the picker opened.
--
-- spec.preview = { mode, enter(why), exit(why), isActive(), isShown() }. A fresh show records
-- { active, shown } on the owner's picker record and, when the surface is hidden and the mode off,
-- calls enter("picker") and raises the window. The eye calls exit("eye") or enter("eye") and shows a
-- lit or dimmed state with a tooltip worded per mode. closed(p), which every close route passes
-- through, undoes what the picker and its eye changed, before onClose and before the queue
-- advances. A refused enter changes nothing, so nothing is undone. Alt-Z is not a close. A spec with
-- only spec.onPreview keeps the one-shot eye: no enter at show, no restore.

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  K.test, K.assertEqual, K.assertTrue, K.assertFalse, K.assertNil

local Bench = dofile("tests/fixture_skin_picker.lua")
local OWNER, OTHER = Bench.OWNER, Bench.OTHER
local env, register, instance, specFor = Bench.env, Bench.register, Bench.instance, Bench.specFor

--- A host's preview mode: its state, the calls it got in `log` (prefixed with `tag`), and the
--- spec.preview table. `opts.active`, `opts.shown`: the state at the start; `opts.noShown`: no
--- isShown; `opts.refuse`: enter and exit answer false and change nothing.
local function host(opts, tag, shared)
  opts = opts or {}
  local h = { active = opts.active or false, shown = opts.shown or false, refuse = opts.refuse,
              log = shared or {} }
  local function note(what) h.log[#h.log + 1] = (tag and (tag .. " ") or "") .. what end
  h.preview = {
    mode = opts.mode or "test",
    isActive = function() return h.active end,
    enter = function(why)
      note("enter:" .. tostring(why))
      if h.refuse then return false end
      h.active = true
    end,
    exit = function(why)
      note("exit:" .. tostring(why))
      if h.refuse then return false end
      h.active = false
    end,
  }
  if not opts.noShown then h.preview.isShown = function() return h.shown end end
  return h
end

--- A shown picker for OWNER whose spec carries `h.preview` (and `extra`); onClose notes "close" in
--- the host's log and the mode it saw then.
local function open(h, extra, envSpec)
  local m, Skin, lib = env(envSpec)
  local store = register(Skin, OWNER)
  local O = instance(lib, OWNER)
  local spec = specFor(store, extra)
  spec.preview = h.preview
  spec.onClose = function()
    store.closed = (store.closed or 0) + 1
    h.log[#h.log + 1] = "close"
    h.activeAtClose = h.active
  end
  local f = O.SkinPicker(spec)
  return f, O, store, m, lib, spec
end

local function joined(log) return table.concat(log, ",") end

-- ── the attach ───────────────────────────────────────────────────────────────────────────────

test("skin picker preview: OptionsSkinPicker is minor 11, with the eye's per-mode words", function()
  local _, _, lib = env()
  assertEqual(lib.MODULES.OptionsSkinPicker, 11)
  assertEqual(lib.__pickerMinor, 11)
  local S = lib.SKIN_PICKER_STRINGS
  for _, mode in ipairs({ "TEST", "UNLOCK", "WINDOW", "CONSOLE" }) do
    assertEqual(type(S["PREVIEW_" .. mode .. "_ON"]), "string", mode .. " on")
    assertEqual(type(S["PREVIEW_" .. mode .. "_OFF"]), "string", mode .. " off")
  end
  assertEqual(S.PREVIEW_TIP, "Preview: open test mode", "onPreview's one-shot words stay")
end)

-- ── a fresh show ─────────────────────────────────────────────────────────────────────────────

test("skin picker preview: a fresh show with the surface hidden and the mode off enters it, then raises", function()
  -- red under: minor 10, where nothing called the host at show time.
  local h = host()
  local raisedAtEnter
  local enter = h.preview.enter
  local libRef
  h.preview.enter = function(why)
    local cur = libRef and libRef.__pickerQueue.current
    raisedAtEnter = cur and cur.frame and (rawget(cur.frame, "__raised") or 0)
    return enter(why)
  end
  local m, Skin, lib = env()
  libRef = lib
  local store = register(Skin, OWNER)
  local f = instance(lib, OWNER).SkinPicker(specFor(store, { preview = h.preview }))
  assertEqual(joined(h.log), "enter:picker", "entered once, as the picker")
  assertTrue(h.active, "the mode is on")
  assertTrue(f:IsShown())
  assertTrue(raisedAtEnter ~= nil, "the window was up when the mode was entered")
  assertTrue(m.__layers(f).raised > raisedAtEnter, "and is raised after it")
end)

test("skin picker preview: a host with no isShown counts as hidden", function()
  local h = host({ noShown = true })
  open(h)
  assertEqual(joined(h.log), "enter:picker")
end)

test("skin picker preview: a shown surface, or a mode already on, is not entered and not undone", function()
  for _, start in ipairs({ { shown = true }, { active = true }, { shown = true, active = true } }) do
    local h = host(start)
    local f = open(h)
    assertEqual(joined(h.log), "", "nothing entered")
    f.close:__fire("OnClick")
    assertEqual(joined(h.log), "close", "nothing undone at the close")
    assertEqual(h.active, start.active or false, "the mode as it was")
  end
end)

test("skin picker preview: a repeat call while up neither records again nor enters again", function()
  local h = host()
  local f, O, _, _, _, spec = open(h)
  f.preview:__fire("OnClick")                  -- the eye turns it off
  assertFalse(h.active)
  O.SkinPicker(spec)                           -- a repeat while up
  assertEqual(joined(h.log), "enter:picker,exit:eye", "no second enter")
  f.close:__fire("OnClick")
  assertEqual(joined(h.log), "enter:picker,exit:eye,close", "back where it opened: off, nothing to do")
end)

-- ── the eye ──────────────────────────────────────────────────────────────────────────────────

test("skin picker preview: the eye toggles the mode, lit while on, with an on and an off tooltip", function()
  -- red under: minor 10's one-shot eye (no exit, no state, one tooltip).
  local h = host()
  local f, _, _, _, lib = open(h, nil, { media = true })
  local S = lib.SKIN_PICKER_STRINGS
  assertTrue(f.preview:IsShown(), "the eye shows with spec.preview alone")
  assertTrue(f.preview.lit, "lit: the picker entered the mode")
  assertEqual(f.preview.__tip, S.PREVIEW_TEST_ON)
  assertEqual(f.preview.icon:GetAlpha(), 1)
  f.preview:__fire("OnClick")
  assertEqual(joined(h.log), "enter:picker,exit:eye")
  assertFalse(h.active)
  assertFalse(f.preview.lit, "dimmed")
  assertEqual(f.preview.__tip, S.PREVIEW_TEST_OFF)
  assertTrue(f.preview.icon:GetAlpha() < 1, "the icon dims")
  assertTrue(f.preview.icon.__desaturated == true, "and grays")
  f.preview:__fire("OnClick")
  assertEqual(joined(h.log), "enter:picker,exit:eye,enter:eye")
  assertTrue(h.active)
  assertTrue(f.preview.lit)
  assertEqual(f.preview.icon:GetAlpha(), 1)
  assertTrue(f:IsShown(), "the eye never closes the window")
  assertNil(rawget(h, "activeAtClose"))
end)

test("skin picker preview: the tooltip is worded per mode, and the glyph dims without Media", function()
  local _, _, lib0 = env()
  local S = lib0.SKIN_PICKER_STRINGS
  for _, mode in ipairs({ "test", "unlock", "window", "console" }) do
    local h = host({ mode = mode })
    local f = open(h)
    local up = mode:upper()
    assertEqual(f.preview.__tip, S["PREVIEW_" .. up .. "_ON"], mode .. " on")
    f.preview:__fire("OnClick")
    assertEqual(f.preview.__tip, S["PREVIEW_" .. up .. "_OFF"], mode .. " off")
    assertTrue(f.preview.text:GetAlpha() < 1, "the glyph dims")
  end
  local h = host({ mode = "nonsense" })
  local f = open(h)
  assertEqual(f.preview.__tip, S.PREVIEW_TEST_ON, "an unknown mode reads as test mode")
  local words = { PREVIEW_UNLOCK_ON = "Frames free" }
  local h2 = host({ mode = "unlock" })
  local f2 = open(h2, { strings = words })
  assertEqual(f2.preview.__tip, "Frames free", "spec.strings translates them")
end)

test("skin picker preview: the eye refreshes the window's raise and survives a raising hook", function()
  local h = host()
  local f, _, _, m = open(h)
  local raised = m.__layers(f).raised
  h.preview.exit = function() error("host failed") end
  local errs = 0
  m.geterrorhandler = function() return function() errs = errs + 1 end end
  f.preview:__fire("OnClick")
  assertEqual(errs, 1, "reported")
  assertEqual(m.__layers(f).raised, raised + 1, "still raised")
  assertTrue(f.preview.lit, "the mode is still on, so still lit")
end)

-- ── every close route restores ───────────────────────────────────────────────────────────────

local ROUTES = {
  { "Apply", function(f) f.apply:__fire("OnClick") end },
  { "the gear", function(f) f.settings:__fire("OnClick") end },
  { "the close control", function(f) f.close:__fire("OnClick") end },
  { "Escape", function(f) f:Hide(); f:__fire("OnHide") end },
  { "HideSkinPicker", function(_, O) O.HideSkinPicker() end },
}

test("skin picker preview: every close route turns off what the picker turned on, before onClose", function()
  -- red under: minor 10, where closed() put the skin back and left the mode on.
  for _, route in ipairs(ROUTES) do
    local h = host()
    local f, O = open(h, { onSettings = function() end })
    route[2](f, O)
    assertEqual(joined(h.log), "enter:picker,exit:picker,close", route[1])
    assertFalse(h.active, route[1] .. ": off again")
    assertFalse(h.activeAtClose, route[1] .. ": off before onClose ran")
  end
end)

test("skin picker preview: Apply to all restores this owner's mode too", function()
  local _, Skin, lib = env()
  local h = host()
  local storeA = register(Skin, OWNER)
  register(Skin, OTHER)
  local f = instance(lib, OWNER).SkinPicker(specFor(storeA, { preview = h.preview }))
  assertTrue(f.applyAll:IsShown())
  f.applyAll:__fire("OnClick")
  assertEqual(joined(h.log), "enter:picker,exit:picker")
  assertFalse(h.active)
end)

test("skin picker preview: an eye that turned off a mode on at open turns it back on at the close", function()
  for _, route in ipairs(ROUTES) do
    local h = host({ active = true })
    local f, O = open(h, { onSettings = function() end })
    f.preview:__fire("OnClick")
    assertFalse(h.active)
    route[2](f, O)
    assertEqual(joined(h.log), "exit:eye,enter:picker,close", route[1])
    assertTrue(h.active, route[1] .. ": back on")
    assertTrue(h.activeAtClose, route[1] .. ": on before onClose ran")
  end
end)

test("skin picker preview: the eye turned back to the opening state leaves nothing to undo", function()
  local h = host()
  local f = open(h)
  f.preview:__fire("OnClick")
  f.preview:__fire("OnClick")
  f.close:__fire("OnClick")
  assertEqual(joined(h.log), "enter:picker,exit:eye,enter:eye,exit:picker,close", "on at the close: off")
  local h2 = host({ active = true })
  local f2 = open(h2)
  f2.preview:__fire("OnClick")
  f2.preview:__fire("OnClick")
  f2.close:__fire("OnClick")
  assertEqual(joined(h2.log), "exit:eye,enter:eye,close", "on at open, on at close: nothing")
end)

test("skin picker preview: a refused enter changes nothing, so the close undoes nothing", function()
  local h = host({ refuse = true })
  local f = open(h)
  assertEqual(joined(h.log), "enter:picker", "asked once")
  assertFalse(h.active, "refused (combat)")
  assertFalse(f.preview.lit, "the eye is dim: the mode is off")
  h.refuse = false
  h.active = true                              -- the player's own /xx test, not the picker's
  f.close:__fire("OnClick")
  assertEqual(joined(h.log), "enter:picker,close", "the picker undoes only what it changed")
  assertTrue(h.active, "the player's mode stays on")
end)

test("skin picker preview: a hide of UIParent (Alt-Z) is not a close", function()
  local h = host()
  local f = open(h)
  f:__fire("OnHide")                           -- UIParent hidden: the window still reads shown
  assertEqual(joined(h.log), "enter:picker", "no restore")
  assertTrue(h.active)
  f.close:__fire("OnClick")
  assertEqual(joined(h.log), "enter:picker,exit:picker,close", "the real close restores once")
  f:__fire("OnHide")
  assertEqual(joined(h.log), "enter:picker,exit:picker,close", "a late OnHide restores nothing more")
end)

test("skin picker preview: a restore refused in combat runs when combat ends", function()
  local h = host()
  local f, _, _, m, lib = open(h)
  m.InCombatLockdown = function() return true end
  h.refuse = true                              -- the host refuses its secure frames in combat
  f.close:__fire("OnClick")
  assertEqual(joined(h.log), "enter:picker,exit:picker,close", "asked, and refused")
  assertTrue(h.active, "still on in combat")
  m.InCombatLockdown = function() return false end
  h.refuse = false
  assertTrue(lib.__parkFrame ~= nil, "parked on the end-of-combat park")
  lib.__parkFrame:__fire("OnEvent", "PLAYER_REGEN_ENABLED")
  assertEqual(joined(h.log), "enter:picker,exit:picker,close,exit:picker", "asked again after combat")
  assertFalse(h.active, "off after combat")
end)

-- ── the queue ────────────────────────────────────────────────────────────────────────────────

test("skin picker preview: two owners: each records its own, and A restores before B enters", function()
  local _, Skin, lib = env()
  local log = {}
  local hA, hB = host(nil, "A", log), host(nil, "B", log)
  local storeA, storeB = register(Skin, OWNER), register(Skin, OTHER)
  local A, B = instance(lib, OWNER), instance(lib, OTHER)
  local specA = specFor(storeA, { preview = hA.preview })
  specA.onClose = function() log[#log + 1] = "A close" end
  local specB = specFor(storeB, { preview = hB.preview })
  specB.onClose = function() log[#log + 1] = "B close" end
  local a = A.SkinPicker(specA)
  hB.active = true                             -- B's mode is on when B's picker is queued
  assertNil(B.SkinPicker(specB), "queued")
  hB.active = false                            -- and off by the time it shows
  assertEqual(joined(log), "A enter:picker", "a queued owner records and enters nothing")
  a.close:__fire("OnClick")
  assertEqual(joined(log), "A enter:picker,A exit:picker,A close,B enter:picker",
    "A restored before onClose and before B showed; B recorded its own state when it showed")
  local b = lib.__pickerQueue.current.frame
  b.preview:__fire("OnClick")
  b.preview:__fire("OnClick")
  b.apply:__fire("OnClick")
  assertEqual(joined(log), "A enter:picker,A exit:picker,A close,B enter:picker,B exit:eye,B enter:eye,B exit:picker,B close")
  assertFalse(hA.active); assertFalse(hB.active)
end)

test("skin picker preview: Apply to all dismisses a queued owner without entering or restoring it", function()
  local _, Skin, lib = env()
  local log = {}
  local hA, hB = host(nil, "A", log), host({ active = true }, "B", log)
  local storeA, storeB = register(Skin, OWNER), register(Skin, OTHER)
  local A, B = instance(lib, OWNER), instance(lib, OTHER)
  local a = A.SkinPicker(specFor(storeA, { preview = hA.preview }))
  assertNil(B.SkinPicker(specFor(storeB, { preview = hB.preview })))
  a.applyAll:__fire("OnClick")
  assertEqual(joined(log), "A enter:picker,A exit:picker", "B is never touched")
  assertEqual(storeB.closed, 1, "B's onClose ran (dismissed)")
  assertTrue(hB.active, "B's own mode stays as it was")
  assertNil(lib.__pickerQueue.current)
end)

test("skin picker preview: HideSkinPicker on a queued owner's instance touches nothing of it", function()
  local _, Skin, lib = env()
  local log = {}
  local hA, hB = host(nil, "A", log), host(nil, "B", log)
  local storeA, storeB = register(Skin, OWNER), register(Skin, OTHER)
  local A, B = instance(lib, OWNER), instance(lib, OTHER)
  A.SkinPicker(specFor(storeA, { preview = hA.preview }))
  B.SkinPicker(specFor(storeB, { preview = hB.preview }))
  B.HideSkinPicker()
  assertEqual(joined(log), "A enter:picker", "B dropped, never entered")
  A.HideSkinPicker()
  assertEqual(joined(log), "A enter:picker,A exit:picker", "A restored by its own stand-down")
  assertNil(lib.__pickerQueue.current)
end)

-- ── back-compat ──────────────────────────────────────────────────────────────────────────────

test("skin picker preview: a spec with only onPreview keeps the one-shot eye: no enter, no restore", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local calls = 0
  local f = instance(lib, OWNER).SkinPicker(specFor(store, { onPreview = function() calls = calls + 1 end }))
  assertEqual(calls, 0, "not called at show")
  assertEqual(f.preview.__tip, lib.SKIN_PICKER_STRINGS.PREVIEW_TIP)
  f.preview:__fire("OnClick")
  f.preview:__fire("OnClick")
  assertEqual(calls, 2, "every click calls it")
  assertEqual(f.preview.__tip, lib.SKIN_PICKER_STRINGS.PREVIEW_TIP, "one tooltip")
  f.close:__fire("OnClick")
  assertEqual(calls, 2, "nothing at the close")
end)

test("skin picker preview: with both, spec.preview wins and onPreview is never called", function()
  local h = host()
  local calls = 0
  local f = open(h, { onPreview = function() calls = calls + 1 end })
  f.preview:__fire("OnClick")
  f.close:__fire("OnClick")
  assertEqual(calls, 0)
  assertEqual(joined(h.log), "enter:picker,exit:eye,close")
end)

test("skin picker preview: an incomplete spec.preview is ignored, and the eye hides without onPreview", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local f = instance(lib, OWNER).SkinPicker(specFor(store, { preview = { mode = "test", enter = function() end } }))
  assertFalse(f.preview:IsShown(), "no isActive and exit: not a preview hook")
  f.close:__fire("OnClick")
  assertEqual(store.closed, 1)
end)

test("skin picker preview: an eye dimmed under spec.preview is lit again for a later onPreview-only show", function()
  local h = host()
  local f, O, store, _, lib = open(h)
  f.preview:__fire("OnClick")
  assertTrue(f.preview.text:GetAlpha() < 1, "dimmed: the eye turned it off")
  f.close:__fire("OnClick")
  O.SkinPicker(specFor(store, { onPreview = function() end }))
  assertEqual(f.preview.text:GetAlpha(), 1, "the one-shot eye is drawn lit")
  assertNil(f.preview.lit)
  assertEqual(f.preview.__tip, lib.SKIN_PICKER_STRINGS.PREVIEW_TIP)
end)
