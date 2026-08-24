-- tests/test_pool.lua — the free/active widget pool.
--
-- THE CASE THAT MATTERS IS THE RECYCLING ONE, and it is why this module exists at all. Four
-- hand-rolled copies of this pool shipped across two addons; three were correct and the fourth
-- hid its active objects without returning them to the free list, so `Acquire` fell through to
-- `factory()` every single time. Nothing about a leaking pool is visible from the outside: the
-- charts render correctly, the suite stays green, and hidden frames accumulate for the session
-- because frames are never destroyed in WoW. Counting factory calls is the only way to see it.

local T = _G.LK_TEST
local pool = T.pool
local test, assertEqual, assertTrue, assertFalse =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse

--- A factory that counts how many objects it was actually asked to build, and objects that record
--- their own shown state. Deliberately not frames: this module never touches a frame API beyond
--- Show/Hide, and a plain table proves that.
local function counting()
  local made = 0
  return function()
    made = made + 1
    local o = { __shown = false, __id = made }
    function o:Show() self.__shown = true end
    function o:Hide() self.__shown = false end
    return o
  end, function() return made end
end

test("pool: New hands back an empty pool", function()
  local p = pool.New()
  local free, active = pool.Counts(p)
  assertEqual(free, 0)
  assertEqual(active, 0)
end)

test("pool: New hands back a DISTINCT pool each call", function()
  -- A shared table returned twice would make two charts fight over one free list, which is the
  -- kind of bug that only shows up under the second consumer.
  local a, b = pool.New(), pool.New()
  pool.Acquire(a, counting())
  assertEqual(select(2, pool.Counts(b)), 0, "acquiring from one pool must not touch the other")
end)

test("pool: Acquire builds when the free list is empty, and shows what it hands back", function()
  local p, factory, made = pool.New(), counting()
  factory, made = counting()
  local o = pool.Acquire(p, factory)
  assertEqual(made(), 1)
  assertTrue(o.__shown, "an acquired object is shown")
  assertEqual(select(2, pool.Counts(p)), 1, "and is on the active list")
end)

test("pool: a released object is REUSED rather than rebuilt", function()
  local p = pool.New()
  local factory, made = counting()
  for _ = 1, 3 do pool.Acquire(p, factory) end
  assertEqual(made(), 3)

  pool.ReleaseAll(p)
  for _ = 1, 3 do pool.Acquire(p, factory) end
  assertEqual(made(), 3, "the second pass must build NOTHING")
end)

test("pool: ReleaseAll hides every active object and returns it to free", function()
  local p = pool.New()
  local factory = counting()
  local a = pool.Acquire(p, factory)
  pool.Acquire(p, factory)

  pool.ReleaseAll(p)
  local free, active = pool.Counts(p)
  assertEqual(active, 0)
  assertEqual(free, 2)
  assertFalse(a.__shown, "released objects are hidden")
end)

test("pool: ReleaseAll on an empty pool is a no-op", function()
  local p = pool.New()
  pool.ReleaseAll(p)
  local free, active = pool.Counts(p)
  assertEqual(free, 0); assertEqual(active, 0)
end)

test("pool: the `before` hook runs on each object, before it is hidden", function()
  -- This hook is what lets one function cover a NESTED pool: a host releasing a pool of panels
  -- releases each panel's own row pool first. Without it that host needs a second library member
  -- and the two drift.
  local p = pool.New()
  local factory = counting()
  pool.Acquire(p, factory); pool.Acquire(p, factory)

  local seen = 0
  local shownAtHookTime = 0
  pool.ReleaseAll(p, function(o)
    seen = seen + 1
    if o.__shown then shownAtHookTime = shownAtHookTime + 1 end
  end)
  assertEqual(seen, 2, "the hook saw every active object")
  assertEqual(shownAtHookTime, 2, "and saw each one BEFORE it was hidden")
end)

test("pool: a nested release through the hook empties both levels", function()
  local panels = pool.New()
  local factory = counting()
  local panel = pool.Acquire(panels, factory)
  panel._rows = pool.New()
  pool.Acquire(panel._rows, factory)
  pool.Acquire(panel._rows, factory)

  pool.ReleaseAll(panels, function(p) pool.ReleaseAll(p._rows) end)
  assertEqual(select(2, pool.Counts(panels)), 0, "the outer pool released")
  assertEqual(select(2, pool.Counts(panel._rows)), 0, "and so did the inner one")
  assertEqual(select(1, pool.Counts(panel._rows)), 2, "the rows are back on their own free list")
end)

test("pool: acquire-release-acquire preserves object identity", function()
  -- Not decoration: a host stashes per-object state (a full label for a tooltip) on the widget,
  -- and a pool that quietly swapped identities would make that state follow the wrong row.
  local p = pool.New()
  local factory = counting()
  local first = pool.Acquire(p, factory)
  pool.ReleaseAll(p)
  local again = pool.Acquire(p, factory)
  assertEqual(again.__id, first.__id, "the same object came back")
end)
