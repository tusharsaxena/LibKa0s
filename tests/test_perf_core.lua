-- tests/test_perf_core.lua — buckets, JSON encoding, record assembly, persistence, reporting.

local T = _G.LK_TEST
local lib = T.lib
local test, assertEqual = T.test, T.assertEqual

test("lib: registers under its major with a schema and a default ring", function()
  assertEqual(lib.MAJOR, "LibKa0s-Perf-1.0", "major")
  assertEqual(lib.SCHEMA, 2, "schema")
  assertEqual(lib.DEFAULT_RING, 10, "default ring")
end)

local Fixture = dofile("tests/fixture.lua")

test("lib: New requires a name, an sv global and a suspend/resume pair", function()
  local ok = pcall(function() lib:New({ sv = "X", suspend = function() end, resume = function() end }) end)
  T.assertFalse(ok, "missing name must error")
  ok = pcall(function() lib:New({ name = "X", suspend = function() end, resume = function() end }) end)
  T.assertFalse(ok, "missing sv must error")
  ok = pcall(function() lib:New({ name = "X", sv = "XDB", resume = function() end }) end)
  T.assertFalse(ok, "missing suspend must error")
end)

test("lib: two instances share no state", function()
  local a = Fixture.new({ name = "HostA", sv = "HostAPerfDB" })
  local b = Fixture.new({ name = "HostB", sv = "HostBPerfDB" })
  a.Note("outer", 5)
  assertEqual(a.__buckets().outer.calls, 1, "A recorded")
  assertEqual(b.__buckets().outer, nil, "B untouched")
end)

test("lib: bucket order and nesting come from the descriptor", function()
  local p = Fixture.new()
  assertEqual(p.BUCKET_ORDER[1], "outer", "first bucket")
  assertEqual(p.BUCKET_ORDER[2], "inner", "second bucket")
  assertEqual(p.BUCKET_WITHIN.inner, "outer", "declared nesting")
  assertEqual(p.BUCKET_WITHIN.outer, nil, "top-level bucket has no parent")
end)

test("lib: the capture gate starts off", function()
  local p = Fixture.new()
  T.assertFalse(p.on, "on")
  T.assertFalse(p.run, "run")
  T.assertFalse(p.suspended, "suspended")
end)

-- ── bucket accounting ───────────────────────────────────────────────────────────────────────

test("lib: Note accumulates calls, total and max", function()
  local p = Fixture.new()
  p.Note("outer", 2)
  p.Note("outer", 5)
  p.Note("outer", 1)
  local b = p.__buckets().outer
  assertEqual(b.calls, 3, "calls")
  assertEqual(b.totalMs, 8, "totalMs")
  assertEqual(b.maxMs, 5, "maxMs is the peak, not the last")
end)

test("lib: Note tracks unrelated buckets independently", function()
  local p = Fixture.new()
  p.Note("outer", 2)
  p.Note("inner", 7)
  assertEqual(p.__buckets().outer.calls, 1, "outer")
  assertEqual(p.__buckets().inner.totalMs, 7, "inner")
end)

test("lib: Reset clears every bucket and both fps arms", function()
  local p = Fixture.new()
  p.Note("outer", 2)
  p.__fpsArms().active.frames = 99
  p.Reset()
  assertEqual(next(p.__buckets()), nil, "buckets emptied")
  assertEqual(p.__fpsArms().active.frames, 0, "active arm zeroed")
  assertEqual(p.__fpsArms().suspended.frames, 0, "suspended arm zeroed")
end)

-- ── JSON encoding ───────────────────────────────────────────────────────────────────────────

test("lib: EncodeJSON emits object keys in sorted order", function()
  -- Sorted output is what makes two captures diffable; pairs() order is unspecified.
  assertEqual(lib.EncodeJSON({ b = 1, a = 2, c = 3 }), '{"a":2,"b":1,"c":3}')
end)

test("lib: EncodeJSON renders integral numbers without a decimal point", function()
  assertEqual(lib.EncodeJSON({ n = 42 }), '{"n":42}')
end)

test("lib: EncodeJSON renders fractional numbers to four places", function()
  assertEqual(lib.EncodeJSON({ n = 1.5 }), '{"n":1.5000}')
end)

test("lib: EncodeJSON escapes quotes, backslashes and control characters", function()
  assertEqual(lib.EncodeJSON('a"b\\c\nd'), '"a\\"b\\\\c\\nd"')
end)

test("lib: EncodeJSON emits arrays for sequence tables", function()
  assertEqual(lib.EncodeJSON({ 1, 2, 3 }), "[1,2,3]")
end)

test("lib: EncodeJSON emits an empty table as an object", function()
  assertEqual(lib.EncodeJSON({}), "{}")
end)

test("lib: EncodeJSON coerces non-finite numbers rather than emitting invalid JSON", function()
  -- inf/NaN have no JSON representation; emitting them raw would produce a file no parser reads.
  assertEqual(lib.EncodeJSON({ n = math.huge }), '{"n":0}')
end)

test("lib: EncodeJSON round-trips a full record without error", function()
  local p = Fixture.new()
  p.Note("outer", 1.25)
  local json = lib.EncodeJSON(p.__buckets())
  T.assertTrue(json:find('"outer"', 1, true) ~= nil, "carries the bucket")
end)
