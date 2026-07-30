-- tests/test_perf_core.lua — buckets, JSON encoding, record assembly, persistence, reporting.

local T = _G.LK_TEST
local lib = T.lib
local test, assertEqual = T.test, T.assertEqual

test("lib: registers under its major with a schema and a default ring", function()
  assertEqual(lib.MAJOR, "LibKa0s-Perf-1.0", "major")
  assertEqual(lib.SCHEMA, 2, "schema")
  assertEqual(lib.DEFAULT_RING, 10, "default ring")
end)
