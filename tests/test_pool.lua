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

-- ── KEYED POOLS (minor 2) ────────────────────────────────────────────────────────────────────
--
-- A keyed pool exists because two consumers independently needed an O(1) index INTO the active
-- set and could not express it: KickCD keys its icon-grid buttons by spellID so a cooldown-state
-- message reaches one widget without a scan. Before minor 2 they had to hand-roll the pool, and a
-- host that ported to `ReleaseAll` anyway got the module's own headline bug back — the array loop
-- walks nothing over a keyed table, so nothing is ever recycled and nothing goes red.

test("pool: NewKeyed hands back an empty keyed pool", function()
  local p = pool.NewKeyed()
  local free, active = pool.CountsKeyed(p)
  assertEqual(free, 0)
  assertEqual(active, 0)
end)

test("pool: AcquireKeyed files the object under its key, and shows it", function()
  local p = pool.NewKeyed()
  local factory, made = counting()
  local o = pool.AcquireKeyed(p, 47, factory)
  assertEqual(made(), 1)
  assertTrue(o.__shown, "an acquired object is shown")
  assertEqual(p.active[47], o, "and is reachable by its key — the whole point of the variant")
end)

test("pool: AcquireKeyed reuses a released object rather than rebuilding", function()
  local p = pool.NewKeyed()
  local factory, made = counting()
  pool.AcquireKeyed(p, "a", factory)
  pool.AcquireKeyed(p, "b", factory)
  assertEqual(made(), 2)

  pool.ReleaseAllKeyed(p)
  pool.AcquireKeyed(p, "c", factory)
  pool.AcquireKeyed(p, "d", factory)
  assertEqual(made(), 2, "the second pass must build NOTHING")
end)

test("pool: ReleaseAllKeyed hides every active object and returns it to free", function()
  -- The case the whole variant exists for. `ReleaseAll`'s `for i = 1, #active` walks zero
  -- iterations here, which is a silent leak; this must actually recycle.
  local p = pool.NewKeyed()
  local factory = counting()
  local a = pool.AcquireKeyed(p, 101, factory)
  pool.AcquireKeyed(p, 202, factory)

  pool.ReleaseAllKeyed(p)
  local free, active = pool.CountsKeyed(p)
  assertEqual(active, 0, "the active map is emptied")
  assertEqual(free, 2, "and BOTH objects are back on the free list")
  assertFalse(a.__shown, "released objects are hidden")
  assertEqual(next(p.active), nil, "no key survives the release")
end)

test("pool: ReleaseAllKeyed hands the key to the before hook", function()
  local p = pool.NewKeyed()
  local factory = counting()
  pool.AcquireKeyed(p, "x", factory)
  pool.AcquireKeyed(p, "y", factory)

  local seen, shownAtHookTime = {}, 0
  pool.ReleaseAllKeyed(p, function(o, key)
    seen[key] = true
    if o.__shown then shownAtHookTime = shownAtHookTime + 1 end
  end)
  assertTrue(seen.x and seen.y, "the hook saw every key")
  assertEqual(shownAtHookTime, 2, "and saw each object BEFORE it was hidden")
end)

test("pool: ReleaseAllKeyed on an empty pool is a no-op", function()
  local p = pool.NewKeyed()
  pool.ReleaseAllKeyed(p)
  local free, active = pool.CountsKeyed(p)
  assertEqual(free, 0); assertEqual(active, 0)
end)

test("pool: AcquireKeyed twice on one key replaces nothing and leaks nothing", function()
  -- A host re-acquiring a live key would otherwise orphan the first object: it would leave the
  -- active map holding only the second, and the first would never reach the free list again.
  local p = pool.NewKeyed()
  local factory, made = counting()
  local first = pool.AcquireKeyed(p, 5, factory)
  local again = pool.AcquireKeyed(p, 5, factory)
  assertEqual(again, first, "the live object under that key comes back")
  assertEqual(made(), 1, "and nothing new was built")

  pool.ReleaseAllKeyed(p)
  assertEqual(select(1, pool.CountsKeyed(p)), 1, "exactly one object reached the free list")
end)

test("pool: keyed acquire-release-acquire preserves object identity", function()
  local p = pool.NewKeyed()
  local factory = counting()
  local first = pool.AcquireKeyed(p, "k", factory)
  pool.ReleaseAllKeyed(p)
  local again = pool.AcquireKeyed(p, "other", factory)
  assertEqual(again.__id, first.__id, "the same object came back, under a different key")
end)

test("pool: ReleaseAll RAISES on a keyed pool rather than silently recycling nothing", function()
  -- The trap this variant was filed for. Before minor 2 this combination was reachable through
  -- the documented API and produced a leak with no symptom: every object hidden, none freed,
  -- every suite still green. It must be loud instead.
  local p = pool.NewKeyed()
  pool.AcquireKeyed(p, 172345, counting())

  local ok, err = pcall(pool.ReleaseAll, p)
  assertFalse(ok, "ReleaseAll must refuse a keyed pool")
  assertTrue(tostring(err):find("keyed", 1, true) ~= nil,
    "and must say why, naming the keyed pool: " .. tostring(err))
end)

test("pool: ReleaseAll still accepts an ordinary array pool untouched", function()
  -- The guard must not cost the common path anything.
  local p = pool.New()
  local factory = counting()
  pool.Acquire(p, factory); pool.Acquire(p, factory)
  local ok = pcall(pool.ReleaseAll, p)
  assertTrue(ok, "an array pool releases as it always did")
  assertEqual(select(1, pool.Counts(p)), 2)
end)

test("pool: CountsKeyed counts a keyed active map that Counts cannot see", function()
  -- `Counts` answers #active, which is 0 for a keyed map however full it is. That is exactly the
  -- reading that made the leak unobservable, so the variant ships its own counter.
  local p = pool.NewKeyed()
  pool.AcquireKeyed(p, "a", counting())
  pool.AcquireKeyed(p, "b", counting())
  assertEqual(select(2, pool.CountsKeyed(p)), 2, "CountsKeyed sees both")
  assertEqual(select(2, pool.Counts(p)), 0, "and Counts, by construction, sees neither")
end)

test("pool: the ReleaseAll guard cannot catch keys that are themselves 1..n", function()
  -- Recorded as a LIMIT, not a wish. A keyed pool whose keys happen to be a dense integer
  -- sequence is indistinguishable from an array pool — `#active` answers 2 for both — so the
  -- array loop consumes it and the guard never fires. It recycles correctly here by accident,
  -- and the accident stops the moment a key is missing from the sequence.
  --
  -- This is why the guard is a safety net and NOT the contract: the contract is that a keyed pool
  -- is released by ReleaseAllKeyed. Real keyed hosts key by domain identity — spellIDs, frame
  -- names — which never form 1..n, so the net catches the case that actually occurs.
  local p = pool.NewKeyed()
  local factory = counting()
  pool.AcquireKeyed(p, 1, factory)
  pool.AcquireKeyed(p, 2, factory)

  local ok = pcall(pool.ReleaseAll, p)
  assertTrue(ok, "1..n keys pass the guard, because nothing can tell them from an array")
  assertEqual(select(1, pool.Counts(p)), 2, "and they happen to recycle correctly")
end)
