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
  ok = pcall(function() lib:New({ name = "X", sv = "XDB", suspend = function() end }) end)
  T.assertFalse(ok, "missing resume must error \226\128\148 the way back is not optional")
end)

test("lib: New rejects a bucket entry with no key, in the library's own words", function()
  -- Without this the loop raised a raw "table index is nil" from inside Perf.lua, which names
  -- neither the descriptor nor the offending entry.
  local function withBuckets(buckets)
    return function()
      lib:New({ name = "X", sv = "XDB", buckets = buckets,
        suspend = function() end, resume = function() end })
    end
  end
  local ok, err = pcall(withBuckets({ { within = "outer" } }))
  T.assertFalse(ok, "a bucket with no key must error")
  T.assertTrue(tostring(err):find("descriptor.buckets[1].key must be a string", 1, true) ~= nil,
    "framed like every other descriptor error, got: " .. tostring(err))
  T.assertFalse(pcall(withBuckets({ {} })), "and a bare entry must not vanish silently")
  T.assertFalse(pcall(withBuckets({ "outer" })), "nor must a bare string")
end)

test("lib: a ring of zero is clamped to one, not left to empty itself", function()
  -- ring = 0 trimmed the record away on the very Save that wrote it, while `finish` still announced
  -- the capture as saved.
  local p = Fixture.new({ ring = 0 })
  assertEqual(p.ringMax, 1, "clamped")
  p.Save(p.BuildRecord("kept"))
  assertEqual(#_G.TestHostPerfDB.runs, 1, "the record survives its own Save")
  assertEqual(_G.TestHostPerfDB.runs[1].label, "kept", "and it is the one just written")
end)

test("lib: a negative ring is clamped too", function()
  assertEqual(Fixture.new({ ring = -5 }).ringMax, 1)
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

test("lib: EncodeJSON encodes a whole record, not just its buckets", function()
  -- `dump` encodes BuildRecord()'s output, so that is what has to survive the encoder — nested
  -- arms, a context table and all. Encoding the bucket table alone exercised none of it.
  local p = Fixture.new()
  p.Start("json run")
  p.Note("outer", 1.25)
  local arms = p.__fpsArms()
  arms.active.seconds, arms.active.frames = 10, 800
  arms.suspended.seconds, arms.suspended.frames = 10, 1000
  local json = lib.EncodeJSON(p.BuildRecord("json run"))
  for _, key in ipairs({ "schema", "addon", "source", "version", "interface", "timestamp",
                         "label", "buckets", "fps", "context" }) do
    T.assertTrue(json:find('"' .. key .. '":', 1, true) ~= nil, "record carries " .. key)
  end
  T.assertTrue(json:find('"outer":{"calls":1', 1, true) ~= nil, "with the bucket inside it")
  T.assertTrue(json:find('"deltaMsPerFrame":2.5000', 1, true) ~= nil, "and the computed delta")
  p.Stop()
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

test("lib: a record stamps the host's interface version and the capture time", function()
  -- Both are read off the client through existence-checked accessors, so both have a degraded path
  -- that nothing was pinning: an `interface` silently stuck at 0 makes every archived capture
  -- unattributable to a game build.
  local p = Fixture.new()
  local r = p.BuildRecord("cap")
  assertEqual(r.interface, 120007, "from the host's own TOC metadata")
  T.assertTrue(type(r.timestamp) == "number" and r.timestamp > 0, "epoch seconds")
end)

test("lib: the record's context names the character's class", function()
  local p = Fixture.new()
  p.Start("ctx")
  local r = p.BuildRecord("ctx")
  assertEqual(r.context.class, "Death Knight", "UnitClass's localised name, not the token")
  assertEqual(r.context.character, "Testchar", "and the rest of the snapshot travels with it")
  p.Stop()
end)

test("lib: a record built before Start has no context at all", function()
  -- `report` and `dump` are reachable on a fresh instance, and the context is only snapshotted by
  -- Start() — so the key is genuinely absent rather than an empty table. Documented as optional in
  -- docs/record-schema.md; pinned here so it cannot quietly become an error instead.
  local p = Fixture.new()
  local r = p.BuildRecord("no run yet")
  assertEqual(r.context, nil, "absent, not empty")
  T.assertTrue(lib.EncodeJSON(r):find('"context"', 1, true) == nil, "and absent from the JSON")
  local lines = table.concat(p.FormatReport(r), "\n")
  assertEqual(lines:find("who:", 1, true), nil, "the report simply prints no context lines")
  T.assertTrue(lines:find("capture:", 1, true) ~= nil, "and everything else still renders")
end)

test("lib: a Note key the descriptor never declared still lands in the record", function()
  -- Membership in descriptor.buckets controls PRESENTATION only. A bracket added in a hurry, or one
  -- in a code path the descriptor's author forgot, must never silently drop its measurement.
  local p = Fixture.new()
  p.Note("undeclared", 3)
  p.Note("outer", 1)
  local r = p.BuildRecord("cap")
  assertEqual(r.buckets.undeclared.calls, 1, "recorded")
  assertEqual(r.buckets.undeclared.totalMs, 3, "with its total")
  local lines = table.concat(p.FormatReport(r), "\n")
  assertEqual(lines:find("undeclared", 1, true), nil, "but it is not in the report")
  T.assertTrue(lines:find("outer", 1, true) ~= nil, "which still prints the declared ones")
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

-- ── the minimal descriptor ──────────────────────────────────────────────────────────────────
--
-- Everything except name/sv/suspend/resume is optional, and the README promises each omission
-- degrades rather than errors. Nothing pinned that: every other fixture passes a full descriptor,
-- so an accidental dereference of an optional field would have sailed through the whole suite.

test("lib: a host passing only the four required fields gets working defaults", function()
  local printed = {}
  local realPrint = _G.print
  _G.print = function(line) printed[#printed + 1] = line end
  _G.MinPerfDB = nil

  local ok, err = pcall(function()
    local p = lib:New({
      name = "Min", sv = "MinPerfDB",
      suspend = function() end, resume = function() end,
    })

    assertEqual(p.slash, "/min", "slash defaults to the lowercased name")
    assertEqual(p.title, "Min", "title defaults to the name")
    assertEqual(p.ringMax, lib.DEFAULT_RING, "ring defaults to the library's")
    assertEqual(#p.BUCKET_ORDER, 0, "no declared buckets")

    -- Both sinks fall back to print, so nothing below may raise for want of a host callback.
    p.OnCommand("start")
    p.Note("anything", 2)
    p.OnCommand("measure a")
    T.mocks.__inCombat = true
    p.__sampler():__fire("OnUpdate", 0.5)
    T.mocks.__inCombat = false
    p.__sampler():__fire("OnUpdate", 0.5)
    p.OnCommand("finish")
    p.OnCommand("report")
    p.OnCommand("dump")           -- showLog defaults to a no-op, so this must not reach for one
    p.ShowPanel()
    T.assertTrue(p.IsPanelShown(), "and it still gets a panel")
    p.HidePanel()

    assertEqual(#_G.MinPerfDB.runs, 1, "the run was saved under the host's own global")
    assertEqual(_G.MinPerfDB.runs[1].version, "?", "an unstated version records as unknown")
    assertEqual(_G.MinPerfDB.runs[1].buckets.anything.calls, 1, "undeclared bucket still captured")
  end)

  _G.print = realPrint
  T.assertTrue(ok, "a minimal host must degrade, not error: " .. tostring(err))
  T.assertTrue(#printed > 0, "both sinks fell back to print")
  T.assertTrue(table.concat(printed, "\n"):find("capture:", 1, true) ~= nil,
    "including the report, which has nowhere else to go")
end)

-- ── the `L` trap ────────────────────────────────────────────────────────────
--
-- This is the one that actually shipped broken: KickCD's perf panel rendered
-- "Ka0s KickCDPANEL_TITLE_SUFFIX" and seven STEP_* keys in place of its labels,
-- because it passed its addon-wide locale table as `L` and that table answers
-- every key with the key. PerfPanel receives `tr` from Perf.lua, so fixing the
-- resolver here fixes the panel too.

local function fallbackLocale()
  return setmetatable({}, { __index = function(_, k) return k end })
end

test("perf: an L whose metatable synthesises every key does NOT mask the module's strings", function()
  -- red under: reverting tr() to `L[key] or lib.STRINGS[key]`
  local P = Fixture.new({ L = fallbackLocale() })
  for _, step in ipairs(P.STEPS) do
    assertEqual(step.label, lib.STRINGS[step.string],
      "step '" .. step.key .. "' must resolve to the module's own string")
  end
end)

test("perf: a step label is never its own SCREAMING_SNAKE_CASE key", function()
  -- The shape a host can cheaply assert, stated here so the library owns it too.
  local P = Fixture.new({ L = fallbackLocale() })
  for _, step in ipairs(P.STEPS) do
    assertEqual(step.label:match("^[A-Z][A-Z0-9_]+$"), nil,
      "step '" .. step.key .. "' rendered its raw key: " .. step.label)
  end
end)

test("perf: a REAL entry in an L that also has a fallback still overrides", function()
  local L = fallbackLocale()
  rawset(L, "STEP_START", "Demarrer")
  local P = Fixture.new({ L = L })
  for _, step in ipairs(P.STEPS) do
    if step.string == "STEP_START" then
      assertEqual(step.label, "Demarrer", "a real entry must still win")
    else
      assertEqual(step.label, lib.STRINGS[step.string], "neighbours must fall through")
    end
  end
end)
