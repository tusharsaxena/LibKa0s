-- tests/test_perf_toplevel.lua — Perf minor 15: `Note(key, ms, false)` records an observation at
-- top level, and the record and the report keep it apart from "not stated" (nil).
--
-- From DropWatcher's 2026-10-14 review (F20). A bucket that runs inside a parent on one path and
-- outside every bucket on another could not be recorded truthfully through minor 14: `false` was
-- stored, but the report read it as falsy ("declares itself within P — not observed", "first:
-- false"). Red under: the minor-14 `nestingSentence` and `addNestingNote`'s `or nil`.

local T = _G.LK_TEST
local lib = T.lib
local test, assertEqual = T.test, T.assertEqual
local Fixture = dofile("tests/fixture.lua")

test("perf top: Note takes false as an observation at top level, not as no observation", function()
  -- Perf minor 15 (DropWatcher's 2026-10-14 review, F20). nil means "not stated"; false means the
  -- call site ran outside every bucket. A sometimes-nested bucket needs the second to be truthful.
  local p = Fixture.new()
  p.Note("inner", 1, false)
  assertEqual(p.__buckets().inner.observedWithin, false, "observed at top level, and kept as false")
  T.assertTrue(p.__buckets().inner.observedMixed == nil, "one observation is not a mix")
  p.Note("inner", 1, false)
  T.assertTrue(p.__buckets().inner.observedMixed == nil, "top level twice is not a mix either")
  p.Note("inner", 1)
  T.assertTrue(p.__buckets().inner.observedMixed == nil, "and nil still states nothing")
end)

test("perf top: top level and a parent, in either order, are a mix that keeps both observations",
function()
  local a = Fixture.new()
  a.Note("inner", 1, false)
  a.Note("inner", 1, "outer")
  T.assertTrue(a.__buckets().inner.observedMixed == true, "top level then a parent is a mix")
  assertEqual(a.__buckets().inner.observedWithin, false, "the first observation stands")
  assertEqual(a.__buckets().inner.observedSecond, "outer", "and the second is kept beside it")
  local b = Fixture.new()
  b.Note("inner", 1, "outer")
  b.Note("inner", 1, false)
  T.assertTrue(b.__buckets().inner.observedMixed == true, "a parent then top level is a mix")
  assertEqual(b.__buckets().inner.observedWithin, "outer", "the first observation stands")
  assertEqual(b.__buckets().inner.observedSecond, false, "and the second is kept beside it")
end)

test("perf top: a bucket observed only at top level is reported as top level, not as unobserved",
function()
  local p = Fixture.new()
  p.Note("outer", 4)
  p.Note("inner", 1, false)
  local lines = table.concat(p.FormatReport(p.BuildRecord("cap")), "\n")
  T.assertTrue(lines:find("inner declares itself within outer but was observed at top level", 1, true)
    ~= nil, "the declaration is contradicted by a top-level call site: " .. lines)
  assertEqual(lines:find("not observed", 1, true), nil, "it was observed, at top level")
  assertEqual(lines:find("false", 1, true), nil, "and the sentinel never reaches the reader")
end)

test("perf top: an undeclared bucket seen at top level and inside a parent names both", function()
  local p = Fixture.new({ buckets = { { key = "outer" }, { key = "eval" } } })
  p.Note("outer", 4)
  p.Note("eval", 1, "outer")
  p.Note("eval", 1, false)
  local lines = table.concat(p.FormatReport(p.BuildRecord("cap")), "\n")
  T.assertTrue(lines:find("eval observed inside outer and at top level", 1, true) ~= nil,
    "a mixed bucket says where it ran: " .. lines)
  T.assertTrue(lines:find("do not sum", 1, true) ~= nil, "and part of it nests, so do not sum")
  assertEqual(lines:find("first: false", 1, true), nil, "never the raw sentinel")
end)

test("perf top: two different parents name both in the mixed sentence", function()
  local p = Fixture.new()
  p.Note("outer", 4)
  p.Note("inner", 1, "outer")
  p.Note("inner", 1, "elsewhere")
  local lines = table.concat(p.FormatReport(p.BuildRecord("cap")), "\n")
  T.assertTrue(lines:find("inner observed inside more than one parent (first: outer, then: elsewhere)",
    1, true) ~= nil, "both parents named: " .. lines)
end)

test("perf top: an undeclared bucket seen only at top level adds no nesting footer of its own", function()
  local p = Fixture.new({ buckets = { { key = "solo" } } })
  p.Note("solo", 1, false)
  local lines = table.concat(p.FormatReport(p.BuildRecord("cap")), "\n")
  T.assertTrue(lines:find("do not sum", 1, true) == nil, "top level is not nesting, so say nothing")
end)

test("perf top: a top-level observation travels into the record and its JSON as false", function()
  local p = Fixture.new()
  p.Note("inner", 1, "outer")
  p.Note("inner", 1, false)
  local r = p.BuildRecord("cap")
  assertEqual(r.buckets.inner.observedWithin, "outer", "first observation")
  assertEqual(r.buckets.inner.observedSecond, false, "second observation, kept as false")
  T.assertTrue(r.buckets.inner.observedMixed == true, "mixed")
  local json = lib.EncodeJSON(r)
  T.assertTrue(json:find('"observedSecond":false', 1, true) ~= nil, "the dump writes the boolean")
  local q = Fixture.new()
  q.Note("inner", 1, false)
  T.assertTrue(lib.EncodeJSON(q.BuildRecord("cap")):find('"observedWithin":false', 1, true) ~= nil,
    "a top-level-only bucket dumps observedWithin false rather than dropping the field")
end)
