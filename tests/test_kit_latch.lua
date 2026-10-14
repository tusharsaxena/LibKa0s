-- tests/test_kit_latch.lua — Kit.assertLatchHoldOrder, the slash-commands-§7 step-10 helper (kit
-- revision 39).
--
-- WHAT IT PROVES. That the helper passes a host whose enable path and perf hold both go through the
-- one latch, in both orders, and that it FAILS each host that breaks the latch in one order only: an
-- enable path that stands the addon up directly (caught by the perf-first-held order B), a disable
-- path that tears down without taking a hold (caught by order A), and a stand-up that rebuilds a
-- different registration set of the same size (caught by the by-key comparison). Each failure names
-- its order, and leaves no hold taken behind it.
--
-- The latch is the real `LibKa0s-Lifecycle-1.0` (`T.lifecycle`); the host is a recording fake whose
-- registration set is a plain list its standDown empties and its standUp rebuilds, which is all the
-- helper reads through `regSet`.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse
local assertErrorMatches = T.assertErrorMatches

local Kit = dofile("tests/_kit/framework.lua")
local LC = T.lifecycle

local OWNED = { "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "UNIT_AURA" }

--- A host with one latch and a registration set. `break_` names the defect the fake carries:
---   nil           conformant: enable and disable go through the `disabled` hold
---   "enableUp"    setEnabled(true) releases the hold AND calls standUp directly
---   "disableDown" setEnabled(false/true) tears down / rebuilds directly, taking no hold
---   "drift"       standUp rebuilds a set of the same size under different keys
local function newHost(break_)
  local h = { regs = {}, rebuilds = 0 }
  local function standUp()
    h.rebuilds = h.rebuilds + 1
    h.regs = {}
    for i, e in ipairs(OWNED) do
      h.regs[i] = (break_ == "drift" and h.rebuilds > 1) and (e .. "_X") or e
    end
  end
  local function standDown() h.regs = {} end
  h.lc = LC:New{ name = "LatchHost", standDown = standDown, standUp = standUp }
  standUp()
  function h.setEnabled(on)
    if break_ == "disableDown" then
      if on then standUp() else standDown() end
      return
    end
    h.lc:Set(LC.HOLD_DISABLED, not on)
    if on and break_ == "enableUp" then standUp() end
  end
  function h.regSet() return h.regs end
  return h
end

local function opts(h, extra)
  local o = { lifecycle = h.lc, perfHold = LC.HOLD_PERF, setEnabled = h.setEnabled, regSet = h.regSet,
              label = "LatchHost" }
  for k, v in pairs(extra or {}) do o[k] = v end
  return o
end

test("kit latch: Kit.assertLatchHoldOrder is on the kit table and published by Kit.expose", function()
  assertEqual(type(Kit.assertLatchHoldOrder), "function", "the kit installs the helper")
  assertEqual(type(T.assertLatchHoldOrder), "function", "and Kit.expose hands it to the suite")
end)

test("kit latch: a conformant host passes both orders and is left up with no hold taken", function()
  local h = newHost()
  Kit.assertLatchHoldOrder(opts(h))
  assertFalse(h.lc:IsDown(), "the host is stood up again")
  assertEqual(#h.lc:Holds(), 0, "no hold outlives the helper")
  assertEqual(table.concat(h.regs, ","), table.concat(OWNED, ","), "and its set is the one it started with")
end)

test("kit latch: an enable path that stands up directly fails order B (perf still held)", function()
  local h = newHost("enableUp")
  assertErrorMatches(function() Kit.assertLatchHoldOrder(opts(h)) end, "order B",
    "the bypass is caught in the order where perf is the hold left")
  assertEqual(#h.lc:Holds(), 0, "the helper released what it took, failing")
end)

test("kit latch: a disable path that takes no hold fails order A (releasing perf resurrects it)", function()
  local h = newHost("disableDown")
  assertErrorMatches(function() Kit.assertLatchHoldOrder(opts(h)) end, "order A",
    "the bypass is caught in the order where disabled is the hold left")
  assertEqual(#h.lc:Holds(), 0, "the helper released what it took, failing")
end)

test("kit latch: a rebuild of the same size under different keys fails (compared by key, not count)", function()
  local h = newHost("drift")
  assertErrorMatches(function() Kit.assertLatchHoldOrder(opts(h)) end, "registration set",
    "a count comparison would have passed this host")
end)

test("kit latch: an empty R_on fails before anything is held", function()
  local h = newHost()
  h.regs = {}
  assertErrorMatches(function() Kit.assertLatchHoldOrder(opts(h)) end, "non-empty",
    "an addon that registers nothing passes every later assertion trivially")
  assertEqual(#h.lc:Holds(), 0, "nothing was taken")
end)

test("kit latch: the label leads every failure message", function()
  local h = newHost("enableUp")
  assertErrorMatches(function() Kit.assertLatchHoldOrder(opts(h, { label = "MyAddon" })) end, "MyAddon",
    "the consumer's label names the addon in the failure")
end)

test("kit latch: table registrations are keyed by target, kind, event and unit, or by opts.key", function()
  local target = {}
  local h = newHost()
  local function asRows()
    local out = {}
    for i, e in ipairs(h.regs) do out[i] = { target = target, kind = "event", event = e } end
    return out
  end
  Kit.assertLatchHoldOrder(opts(h, { regSet = asRows }))
  local seen = 0
  Kit.assertLatchHoldOrder(opts(h, { regSet = asRows, key = function(r) seen = seen + 1; return r.event end }))
  assertTrue(seen > 0, "opts.key is used when given")
end)

test("kit latch: missing or wrong-typed opts raise naming the field", function()
  local h = newHost()
  for _, field in ipairs({ "lifecycle", "perfHold", "setEnabled", "regSet" }) do
    local o = opts(h); o[field] = nil
    assertErrorMatches(function() Kit.assertLatchHoldOrder(o) end, field, "opts." .. field .. " is required")
  end
end)
