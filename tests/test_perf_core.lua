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

-- ── record assembly ─────────────────────────────────────────────────────────────────────────

test("lib: BuildRecord carries schema, source and label", function()
  local p = Fixture.new()
  local r = p.BuildRecord("dummy run")
  assertEqual(r.schema, p.SCHEMA, "schema")
  assertEqual(r.source, "ingame", "source")
  assertEqual(r.label, "dummy run", "label")
end)

test("lib: BuildRecord derives avgFps and msPerFrame from the arms", function()
  local p = Fixture.new()
  local a = p.__fpsArms().active
  a.seconds, a.frames = 10, 800
  local r = p.BuildRecord()
  assertEqual(r.fps.active.avgFps, 80, "800 frames over 10s is 80 fps")
  assertEqual(r.fps.active.msPerFrame, 12.5, "and 12.5 ms per frame")
end)

test("lib: BuildRecord reports zero delta when only one arm was sampled", function()
  -- With no B arm, suspended.msPerFrame is 0 and a naive subtraction would report the ENTIRE
  -- frame time as the addon's cost — a number that reads as a catastrophic finding.
  local p = Fixture.new()
  local a = p.__fpsArms().active
  a.seconds, a.frames = 10, 800
  assertEqual(p.BuildRecord().fps.deltaMsPerFrame, 0, "no delta without both arms")
end)

test("lib: BuildRecord computes the delta when both arms were sampled", function()
  local p = Fixture.new()
  local arms = p.__fpsArms()
  arms.active.seconds, arms.active.frames = 10, 800        -- 12.5 ms/frame
  arms.suspended.seconds, arms.suspended.frames = 10, 1000 -- 10.0 ms/frame
  assertEqual(p.BuildRecord().fps.deltaMsPerFrame, 2.5, "active costs 2.5 ms/frame more")
end)

test("lib: BuildRecord snapshots buckets rather than aliasing them", function()
  local p = Fixture.new()
  p.Note("outer", 3)
  local r = p.BuildRecord()
  p.Note("outer", 3)
  assertEqual(r.buckets.outer.calls, 1, "the record is a snapshot, not a live view")
end)

test("lib: a record names the addon that produced it", function()
  local p = Fixture.new()
  local r = p.BuildRecord("cap")
  assertEqual(r.addon, "TestHost", "addon")
  assertEqual(r.schema, 2, "schema")
  assertEqual(r.version, "1.2.3", "host version")
end)

test("lib: a nested bucket carries its parent into the record", function()
  local p = Fixture.new()
  p.Note("outer", 4)
  p.Note("inner", 1)
  local r = p.BuildRecord("cap")
  assertEqual(r.buckets.inner.within, "outer", "declared nesting travels with the record")
  assertEqual(r.buckets.outer.within, nil, "a top-level bucket carries none")
end)

-- ── the SavedVariables ring ─────────────────────────────────────────────────────────────────

test("lib: Save creates the perf global and appends the run", function()
  local p = Fixture.new()
  p.Save(p.BuildRecord("first"))
  local db = _G.TestHostPerfDB
  assertEqual(type(db), "table", "global created")
  assertEqual(#db.runs, 1, "one run stored")
  assertEqual(db.runs[1].label, "first", "the run we saved")
end)

test("lib: Save stamps the schema on the store", function()
  local p = Fixture.new()
  p.Save(p.BuildRecord())
  assertEqual(_G.TestHostPerfDB.schema, p.SCHEMA, "store is self-describing")
end)

test("lib: Save trims the ring to ringMax, dropping the oldest", function()
  local p = Fixture.new({ ring = 3 })
  for i = 1, 3 + 3 do p.Save(p.BuildRecord("run" .. i)) end
  local runs = _G.TestHostPerfDB.runs
  assertEqual(#runs, 3, "capped at ringMax")
  assertEqual(runs[1].label, "run4", "oldest three dropped")
  assertEqual(runs[#runs].label, "run" .. 6, "newest kept")
end)

test("lib: a ring written under another schema is discarded, not converted", function()
  local p = Fixture.new()
  _G.TestHostPerfDB = { schema = 1, runs = { { schema = 1 }, { schema = 1 } } }
  p.Save(p.BuildRecord("cap"))
  assertEqual(_G.TestHostPerfDB.schema, 2, "stamped with the current schema")
  assertEqual(#_G.TestHostPerfDB.runs, 1, "the v1 records are gone, not migrated")
end)

-- ── report formatting ───────────────────────────────────────────────────────────────────────

test("lib: FormatReport marks an unsampled arm rather than printing zeros", function()
  local p = Fixture.new()
  local lines = table.concat(p.FormatReport(p.BuildRecord()), "\n")
  T.assertTrue(lines:find("(not sampled)", 1, true) ~= nil, "says so explicitly")
end)

test("lib: FormatReport prints both arms and the delta when both ran", function()
  local p = Fixture.new()
  local arms = p.__fpsArms()
  arms.active.seconds, arms.active.frames = 10, 800
  arms.suspended.seconds, arms.suspended.frames = 10, 1000
  local lines = table.concat(p.FormatReport(p.BuildRecord()), "\n")
  T.assertTrue(lines:find("active:", 1, true) ~= nil, "active arm")
  T.assertTrue(lines:find("suspended:", 1, true) ~= nil, "suspended arm")
  T.assertTrue(lines:find("+2.50 ms/frame", 1, true) ~= nil, "signed delta")
end)

test("lib: FormatReport derives ms/s from the active seconds only", function()
  local p = Fixture.new()
  local arms = p.__fpsArms()
  arms.active.seconds, arms.active.frames = 10, 800
  arms.suspended.seconds, arms.suspended.frames = 90, 9000  -- must not dilute the rate
  p.Note("outer", 20)
  local lines = table.concat(p.FormatReport(p.BuildRecord()), "\n")
  T.assertTrue(lines:find("2.000", 1, true) ~= nil, "20ms over 10 active seconds is 2 ms/s")
end)

test("lib: FormatReport warns that buckets nest", function()
  local p = Fixture.new()
  p.Note("outer", 4)
  p.Note("inner", 1)
  local lines = table.concat(p.FormatReport(p.BuildRecord()), "\n")
  T.assertTrue(lines:find("do not sum", 1, true) ~= nil, "totals must not be added naively")
end)

test("lib: FormatReport omits buckets that never fired", function()
  local p = Fixture.new()
  p.Note("outer", 1)
  local lines = table.concat(p.FormatReport(p.BuildRecord()), "\n")
  T.assertTrue(lines:find("outer", 1, true) ~= nil, "fired bucket present")
  assertEqual(lines:find("inner", 1, true), nil, "unfired bucket absent")
end)

test("lib: FormatReport indents a nested bucket under its parent", function()
  local p = Fixture.new()
  p.Note("outer", 4)
  p.Note("inner", 1)
  local lines = table.concat(p.FormatReport(p.BuildRecord("cap")), "\n")
  T.assertTrue(lines:find("\n  inner", 1, true) ~= nil, "inner is indented two spaces")
  T.assertTrue(lines:find("outer contains inner", 1, true) ~= nil, "the nesting is spelled out")
end)

test("lib: a flat bucket set gets no nesting footer", function()
  local p = Fixture.new({ buckets = { { key = "solo" } } })
  p.Note("solo", 1)
  local lines = table.concat(p.FormatReport(p.BuildRecord("cap")), "\n")
  T.assertTrue(lines:find("do not sum", 1, true) == nil, "nothing nests, so say nothing")
end)

-- ── capture context ─────────────────────────────────────────────────────────────────────────
--
-- A saved record is read weeks later, and "119 fps" means nothing without knowing it was a Blood DK
-- soloing a dummy rather than a healer in a 20-man.

test("lib: Context captures character, spec, zone and group", function()
  local p = Fixture.new()
  local ctx = p.Context()
  assertEqual(ctx.character, "Testchar", "character")
  assertEqual(ctx.realm, "Testrealm", "realm")
  assertEqual(ctx.level, 80, "level")
  assertEqual(ctx.spec, "Blood", "spec")
  assertEqual(ctx.zone, "Silvermoon City", "zone")
  assertEqual(ctx.subZone, "Falconwing Square", "sub-zone")
end)

test("lib: Context reports solo when ungrouped", function()
  local p = Fixture.new()
  assertEqual(p.Context().group, "solo")
end)

test("lib: Context reports party size and instance type", function()
  local p = Fixture.new()
  local saved = T.mocks.__context
  T.mocks.__context = {
    name = "X", realm = "Y", level = 80, spec = "Blood", zone = "Nexus-Point Xenas", subZone = "",
    inInstance = true, instanceType = "party", inGroup = true, inRaid = false, groupSize = 5,
  }
  local g = p.Context().group
  T.mocks.__context = saved
  assertEqual(g, "party (5) / party", "names both the group and where it is")
end)

test("lib: Context reports raid size", function()
  local p = Fixture.new()
  local saved = T.mocks.__context
  T.mocks.__context = {
    name = "X", realm = "Y", level = 80, spec = "Blood", zone = "Z", subZone = "",
    inInstance = true, instanceType = "raid", inGroup = true, inRaid = true, groupSize = 20,
  }
  local g = p.Context().group
  T.mocks.__context = saved
  assertEqual(g, "raid (20) / raid")
end)

test("lib: ContextLines folds the sub-zone into the location", function()
  local p = Fixture.new()
  local lines = table.concat(p.ContextLines(p.Context()), "\n")
  T.assertTrue(lines:find("Silvermoon City", 1, true) ~= nil, "zone: " .. lines)
  T.assertTrue(lines:find("Falconwing Square", 1, true) ~= nil, "and sub-zone")
end)

test("lib: ContextLines omits an empty sub-zone cleanly", function()
  local p = Fixture.new()
  local lines = table.concat(p.ContextLines({
    character = "X", realm = "Y", level = 80, spec = "Blood", class = "Death Knight",
    zone = "Orgrimmar", subZone = "", group = "solo",
  }), "\n")
  T.assertTrue(lines:find("Orgrimmar", 1, true) ~= nil, "zone present")
  assertEqual(lines:find("\226\128\148 \n", 1, true), nil, "no dangling separator")
end)

test("lib: ContextLines tolerates a record with no context", function()
  local p = Fixture.new()
  assertEqual(#p.ContextLines(nil), 0, "returns nothing rather than erroring")
end)
