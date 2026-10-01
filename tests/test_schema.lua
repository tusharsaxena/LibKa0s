-- tests/test_schema.lua — the settings schema runtime's contract, one case per invariant.
--
-- Every case builds its state from a fixture CONSTRUCTOR (newFlat, newInstance, newClosure) and
-- never from shared mutable state, because the thing under test is mostly ORDER and ABSENCE: that
-- a refused write called nothing, that the log line came before the reaction, that a bracket spoke
-- once. A fixture shared between cases would carry one case's writes into the next one's "nothing
-- happened", and the absence would be somebody else's.
--
-- One recorder per fixture appends every host callback to a single ordered log, so the order is
-- asserted rather than inferred from counters that cannot see it.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil, assertError =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil, T.assertError
local assertErrorMatches = T.assertErrorMatches

local Schema = T.schema

-- ── fixtures ────────────────────────────────────────────────────────────────────────────────
--
-- The constructors are tests/fixture_schema.lua, shared with tests/test_schema_write.lua, which
-- holds the write stage onward (the write seam, defaults, the bulk bracket, the profile reset's
-- count) since issue #38 split this suite by pipeline stage.

local F = dofile("tests/fixture_schema.lua")
local newRecorder, spies, newFlat, rowAt, sortedKeys =
  F.newRecorder, F.spies, F.newFlat, F.rowAt, F.sortedKeys

-- ── the reference degradation stub ──────────────────────────────────────────────────────────

--- The stub the API document's "The degradation stub" section describes, as a host would write it
--- for `LibStub("LibKa0s-Schema-1.0", true) or stub`. It is WRITE-COMPLETING and LOG-SILENT:
--- reads, writes, reactions, announce and the sweep veto work, because a player can observe
--- them through the host verbs and Reset All that never needed Options or Slash
--- (slash-commands-§1, options-ui-§1). The [Set] line, the bracket's tally and the reset count are
--- not reproduced, because every adopter's degraded DebugLog stub discards the line they feed.
---
--- It closes over NOTHING and runs in an environment of plain Lua, so it cannot reach the library
--- it stands in for; a case below pins both. Everything a host needs from the library when the
--- library is absent is here, lib level included, so a host keeps one seam and no call site moves.
local function referenceStub(brand)
  local stubLib = {}
  local function copy(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, x in pairs(v) do out[k] = copy(x) end
    return out
  end
  function stubLib.SplitPath(path)
    local parts = {}
    if path ~= nil then
      for seg in tostring(path):gmatch("[^%.]+") do parts[#parts + 1] = seg end
    end
    return parts
  end
  local function partsOf(p) return type(p) == "table" and p or stubLib.SplitPath(p) end
  function stubLib.Read(root, p, first)
    local parts, node = partsOf(p), root
    first = first or 1
    if type(root) ~= "table" or #parts < first then return nil end
    for i = first, #parts do
      if type(node) ~= "table" then return nil end
      node = node[parts[i]]
    end
    return node
  end
  function stubLib.Write(root, p, value, first)
    local parts, node = partsOf(p), root
    first = first or 1
    if type(root) ~= "table" or #parts < first then return end
    for i = first, #parts - 1 do
      if type(node[parts[i]]) ~= "table" then node[parts[i]] = {} end
      node = node[parts[i]]
    end
    node[parts[#parts]] = value
  end
  function stubLib.SameValue(a, b)
    if a == b then return true end
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    for k, v in pairs(a) do if not stubLib.SameValue(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
  end

  function stubLib:New(d)
    local S, depth = {}, 0
    local rows = d.rows
    -- writeThrough: one synthetic row per listed path, built once. It has no validate, normalize,
    -- set or onChange, so `prepare` below stores it raw (a copy) and announces it, as the library
    -- does; every other row-less path is still refused.
    local through = {}
    for _, p in ipairs(type(d.writeThrough) == "table" and d.writeThrough or {}) do
      if type(p) == "string" and p ~= "" then through[p] = { path = p, writeThrough = true } end
    end
    local function resolve(parts, id)
      if type(d.resolveRoot) ~= "function" then return nil end
      return d.resolveRoot(parts, id)
    end
    function S.AllRows() return rows end
    function S.FindRow(path)
      if type(path) ~= "string" then return nil end
      for _, row in ipairs(rows) do
        if type(row) == "table" and row.path == path then return row end
      end
    end
    function S.AddRows(list, at)
      if type(list) ~= "table" then return 0 end
      at = type(at) == "number" and math.floor(at) or #rows + 1
      if at > #rows + 1 then at = #rows + 1 elseif at < 1 then at = 1 end
      for i, row in ipairs(list) do table.insert(rows, at + i - 1, row) end
      return #list
    end
    function S.Reindex() end
    function S.Get(path, id)
      local row = S.FindRow(path)
      if row and type(row.get) == "function" then return row.get(id) end
      if type(path) ~= "string" or (row and row.sessionOnly) then return nil end
      local parts = stubLib.SplitPath(path)
      local root, first = resolve(parts, id)
      if type(root) ~= "table" then return nil end
      return stubLib.Read(root, parts, first)
    end
    -- The write seam's order without its log and tally: refuse (a listed writeThrough path is not
    -- refused), validate, normalize, store, react, announce. `prepare` answers a plan, or nil and the refusal; Set and SetMany share it.
    local function prepare(path, value, id)
      local row = S.FindRow(path) or through[path]
      if not row then return nil, brand .. ": no setting " .. tostring(path) end
      local w = { row = row, path = path, value = value, rid = id }
      w.stored = type(row.set) ~= "function" and not row.sessionOnly
      if w.stored then
        w.parts = stubLib.SplitPath(path)
        local r, f, got = resolve(w.parts, id)
        if type(r) == "table" then w.root, w.first = r, f end
        if got ~= nil then w.rid = got end
      end
      if type(row.validate) == "function" then
        local ok, why = row.validate(value, w.rid)
        if not ok then return nil, brand .. ": invalid value for " .. path, why end
      end
      if type(row.normalize) == "function" then
        local out, why = row.normalize(value, w.rid)
        if out == nil then return nil, brand .. ": invalid value for " .. path, why end
        w.value = out
      end
      if w.stored and not w.root then return nil, brand .. ": nowhere to store " .. path end
      return w
    end
    local function store(w)
      if type(w.row.set) == "function" then
        w.row.set(w.value)
      elseif w.stored then
        stubLib.Write(w.root, w.parts, copy(w.value), w.first)
      end
    end
    local function react(w)
      if type(w.row.onChange) == "function" then w.row.onChange(w.value, w.rid) end
    end
    function S.Set(path, value, id)
      local w, err, why = prepare(path, value, id)
      if not w then return false, err, why end
      store(w)
      react(w)
      if type(d.announce) == "function" then d.announce(w.row, path, w.value, w.rid) end
      return true
    end
    -- All or nothing, as the library's: every entry prepared, then every store, every onChange,
    -- and one announceBatch (or announce per write). Log-silent, so `act` is not read at all.
    local function prepareAll(entries, id)
      local ws = {}
      for i, e in ipairs(type(entries) == "table" and entries or {}) do
        if type(e) ~= "table" then e = {} end
        local w, err, why = prepare(e.path, e.value, id)
        if not w then return nil, err, why, i end
        ws[i] = w
      end
      return ws
    end
    local function announceAll(ws)
      if #ws == 0 then return end
      if type(d.announceBatch) == "function" then return d.announceBatch(ws, ws[1].rid) end
      if type(d.announce) ~= "function" then return end
      for _, w in ipairs(ws) do d.announce(w.row, w.path, w.value, w.rid) end
    end
    function S.SetMany(entries, opts)
      local ws, err, why, at = prepareAll(entries, type(opts) == "table" and opts.instanceId or nil)
      if not ws then return false, err, why, at end
      for _, w in ipairs(ws) do store(w) end
      for _, w in ipairs(ws) do react(w) end
      announceAll(ws)
      return true
    end
    function S.Default(path)
      local row = S.FindRow(path)
      return row and copy(row.default)
    end
    function S.ApplyDefault(row, id)
      if type(row) ~= "table" or type(row.path) ~= "string" or row.default == nil then return false end
      local exempt = d.resetExempt
      if depth > 0 and type(exempt) == "table" and exempt[row.path] then return false end
      return S.Set(row.path, copy(row.default), id)
    end
    -- The bracket keeps its depth, because the sweep veto above reads it; it counts nothing.
    function S.BulkBegin() depth = depth + 1 end
    function S.BulkEnd() if depth > 0 then depth = depth - 1 end end
    function S.BulkRun(act, scope, fn)
      S.BulkBegin(act, scope)
      local ok, err = pcall(fn, { profileReset = false })
      S.BulkEnd(act, scope)
      if not ok then error(err, 0) end
    end
    function S.BulkAdd() end
    function S.InBulk() return depth > 0 end
    function S.CountOffDefault() return 0 end
    function S.ResetCounted(fn) fn() end
    function S.ConsumeResetCount() return nil end
    function S.Validate()
      if type(d.print) == "function" then
        d.print(brand .. ": LibKa0s-Schema-1.0 is missing, so the schema was not checked")
      end
      return 0, 0, 0
    end
    return S
  end
  return stubLib
end

--- The environment the reference stub runs in: plain Lua and nothing of this suite, so a global
--- reach for LibStub, the library or the kit is a nil call rather than a silent pass.
setfenv(referenceStub, {
  type = type, pairs = pairs, ipairs = ipairs, tostring = tostring, pcall = pcall, error = error,
  table = { insert = table.insert }, math = { floor = math.floor },
})

-- ── the major ───────────────────────────────────────────────────────────────────────────────

test("schema: the major is registered and reports its own live version", function()
  assertTrue(Schema ~= nil, "LibKa0s-Schema-1.0 registered")
  assertEqual(Schema.MAJOR, "LibKa0s-Schema-1.0")
  assertEqual(Schema.MODULES.Schema, Schema.MINOR)
end)

test("schema: the module refuses to register without Core, and registers with it", function()
  -- red under: drop the NEEDS_CORE return above NewLibrary
  local Loader = dofile("tests/_kit/loader.lua")
  local buildMocks = dofile("tests/wow_mock.lua")
  local bare = buildMocks()
  Loader.load("LibKa0s/Schema.lua", nil, bare)
  assertNil(bare.LibStub("LibKa0s-Schema-1.0", true), "no Core, no schema runtime")

  local whole = buildMocks()
  Loader.load("LibKa0s/Core.lua", nil, whole)
  Loader.load("LibKa0s/Schema.lua", nil, whole)
  assertTrue(whole.LibStub("LibKa0s-Schema-1.0", true) ~= nil, "Core present, schema present")
end)

test("schema: the lib-level surface is exactly the six pure members", function()
  local names = {}
  for _, m in ipairs(T.publicMembers(Schema)) do names[#names + 1] = m.name end
  assertEqual(table.concat(names, ","), "New,Read,STRINGS,SameValue,SplitPath,Write")
end)

test("schema: the instance surface is exactly the documented member list", function()
  -- Hosts mirror this list in their degradation stub; a member added here without a document row
  -- is a member every stub is missing.
  local S = newFlat()
  assertEqual(sortedKeys(S), table.concat({
    "AddRows", "AllRows", "ApplyDefault", "BulkAdd", "BulkBegin", "BulkEnd", "BulkRun",
    "ConsumeResetCount", "CountOffDefault", "Default", "FindRow", "Get", "InBulk", "Reindex",
    "ResetCounted", "Set", "SetMany", "Validate",
  }, ","))
end)

test("schema: the reference stub carries the whole surface, lib level and instance", function()
  -- The instance surface is not in members-1.json, so it is pinned with the kit's two-table form;
  -- the lib level is pinned by name. STRINGS is the one lib member a stub does not carry: its
  -- refusals are in the host's own words, not a copy of the library's constants.
  local stubLib = referenceStub("Host")
  local S, fx = newFlat()
  T.assertSurfaceParity(S, stubLib:New(fx.d), "schema instance vs host stub")
  T.assertSurfaceParity(stubLib, "LibKa0s-Schema-1.0", { "STRINGS" })
end)

test("schema: the reference stub reaches neither the library nor the suite", function()
  -- red under: the stub builder capturing `Schema` (an upvalue) or calling LibStub (a global)
  assertNil(debug.getupvalue(referenceStub, 1), "the builder closes over nothing")
  local env = getfenv(referenceStub)
  assertNil(env.LibStub, "no LibStub in the stub's environment")
  assertNil(env.LK_TEST, "no suite in the stub's environment")
end)

test("schema: the stub completes writes, in the live seam's order and to the same store", function()
  -- The degraded path a host verb, Reset All and a combat re-lock take. Each write is driven into a
  -- live instance and into the stub, from two identical fixtures, and the stores and the reaction
  -- order must agree once the live seam's debug entries are set aside.
  -- red under: the stub's Set refusing (the read-only contract this replaced)
  local _, live = newFlat()
  local _, degraded = newFlat()
  local stub = referenceStub("Host"):New(degraded.d)
  local tint = { r = 0, g = 0.5, b = 1, a = 1 }
  for _, fx in ipairs({ { S = live.S, fx = live }, { S = stub, fx = degraded } }) do
    local S = fx.S
    assertTrue(S.Set("scale", 1.5), "a validated stored row")
    assertTrue(S.Set("units.player.width", 250), "a nested stored row")
    assertTrue(S.Set("color", tint), "a table value")
    assertTrue(S.Set("debugConsole", true), "a sessionOnly closure row")
    assertTrue(S.Set("minimap", false), "an inverted closure row")
    assertFalse(S.Set("scale", 9), "validate still refuses")
    assertFalse(S.Set("nope", 1), "an unknown path is still refused, never stored")
  end
  tint.r = 1
  assertEqual(degraded.db.profile.color.r, 0, "the stub stores a copy, as the seam does")
  assertTrue(Schema.SameValue(live.db, degraded.db), "the same store after the same writes")
  assertEqual(degraded.console, true)
  local liveOrder = {}
  for _, e in ipairs(live.rec.log) do
    if e ~= "debug" then liveOrder[#liveOrder + 1] = e end
  end
  assertEqual(degraded.rec.joined(), table.concat(liveOrder, ","), "onChange then announce, per write")
  assertEqual(#degraded.rec.debugLines, 0, "log-silent: the degraded sink would discard the line")
end)

test("schema: the stub's SetMany is all or nothing, and lands what the live batch lands", function()
  -- red under: a stub SetMany that stores entries as they validate, or one that logs
  local _, live = newFlat()
  local _, degraded = newFlat()
  local stub = referenceStub("Host"):New(degraded.d)
  local good = { { path = "scale", value = 1.5 }, { path = "units.player.width", value = 250 },
                 { path = "minimap", value = false } }
  local bad = { { path = "enabled", value = false }, { path = "scale", value = 9 } }
  for _, S in ipairs({ live.S, stub }) do
    local ok, _, why, at = S.SetMany(bad)
    assertFalse(ok, "one refused entry refuses the batch")
    assertEqual(why, "out of range")
    assertEqual(at, 2)
    assertTrue(S.SetMany(good, { act = "copy", scope = "all" }))
  end
  assertTrue(Schema.SameValue(live.db, degraded.db), "the same store after the same batches")
  assertEqual(degraded.db.profile.enabled, true, "the refused batch's first entry never landed")
  assertEqual(#degraded.rec.debugLines, 0, "log-silent")
  assertEqual(live.rec.debugLines[1], "[Set] copy all: 3 rows", "the live batch is one line")
end)

test("schema: the stub writes a writeThrough path through, as the live seam does", function()
  -- The degraded route (a) a host verb takes for a composed row whose composer is absent: `locked`
  -- is listed and has no row, `scale` is listed and has one, `general.__nope` is neither.
  -- red under: a stub that refuses every row-less path (the pre-writeThrough reference)
  local list = { "locked", "scale" }
  local _, live = newFlat({ writeThrough = list })
  local _, degraded = newFlat({ writeThrough = list })
  local stub = referenceStub("Host"):New(degraded.d)
  for _, S in ipairs({ live.S, stub }) do
    assertTrue(S.Set("locked", true), "a listed row-less path is written")
    assertTrue(S.Set("units.player.width", 250), "a row write between the two")
    assertTrue(S.Set("locked", false), "and written again, false included")
    local ok, _, why = S.Set("scale", 9)
    assertFalse(ok, "a listed path WITH a row still goes through its validate")
    assertEqual(why, "out of range")
    assertFalse(S.Set("general.__nope", 1), "an unlisted row-less path is still refused")
  end
  assertEqual(degraded.db.profile.locked, false, "false is stored, not skipped")
  assertNil(degraded.db.profile.general, "the refused path created nothing")
  assertTrue(Schema.SameValue(live.db, degraded.db), "the same store after the same writes")
  local liveOrder = {}
  for _, e in ipairs(live.rec.log) do
    if e ~= "debug" then liveOrder[#liveOrder + 1] = e end
  end
  assertEqual(degraded.rec.joined(), table.concat(liveOrder, ","), "the same announce order")
  assertEqual(degraded.rec.count("onChange:"), 1, "only the row write reacted")
  assertTrue(degraded.rec.lastAnnounce.row.writeThrough == true, "a synthetic row, marked")
  assertEqual(degraded.rec.lastAnnounce.path, "locked")
end)

test("schema: the stub's Reset All sweep resets rows and keeps the sweep veto", function()
  -- red under: a no-op bracket (the minimap row is swept), or ApplyDefault refusing
  local _, fx = newFlat({ resetExempt = { minimap = true } })
  local stub = referenceStub("Host"):New(fx.d)
  stub.Set("scale", 1.5)
  stub.Set("minimap", false)
  stub.Set("debugConsole", true)
  stub.BulkRun("reset", "all", function()
    for _, row in ipairs(stub.AllRows()) do stub.ApplyDefault(row) end
  end)
  assertEqual(fx.db.profile.scale, 1, "a stored row is back at its default")
  assertEqual(fx.console, false, "a sessionOnly row is swept too")
  assertEqual(fx.db.global.minimap.hide, true, "the exempt row is not swept")
  assertFalse(stub.InBulk(), "the bracket closed")
  assertTrue(stub.ApplyDefault(rowAt(fx, "minimap")), "a named reset outside a sweep still applies")
  assertEqual(fx.db.global.minimap.hide, false)
  local boom = {}
  local ok, err = pcall(stub.BulkRun, "reset", "all", function() error(boom) end)
  assertFalse(ok)
  assertTrue(err == boom, "the error comes back by identity")
  assertFalse(stub.InBulk(), "a raising act still closes the bracket")
end)

test("schema: the stub's lib level answers as the library's does on the same inputs", function()
  -- A host whose own code calls the primitives (a data layer's path walk) keeps working degraded.
  local stubLib = referenceStub("Host")
  for _, path in ipairs({ "a.b.c", "a..b", "single", "" }) do
    assertEqual(table.concat(stubLib.SplitPath(path), "|"), table.concat(Schema.SplitPath(path), "|"))
  end
  assertEqual(#stubLib.SplitPath(nil), 0, "nil is the empty path")
  local a, b = { x = { y = 1 } }, { x = 5 }
  stubLib.Write(a, "x.z", 2)
  Schema.Write(b, "x.z", 2)
  assertEqual(stubLib.Read(a, "x.z"), 2)
  assertTrue(Schema.SameValue(b, { x = { z = 2 } }), "the library replaces a non-table intermediate")
  local c = { x = 5 }
  stubLib.Write(c, "x.z", 2)
  assertTrue(Schema.SameValue(c, b), "and so does the stub")
  assertNil(stubLib.Read(a, ""), "the root itself is never an answer")
  assertEqual(stubLib.Read({ k = { v = 3 } }, { "skip", "k", "v" }, 2), 3, "parts and first")
  assertTrue(stubLib.SameValue({ 1, { 2 } }, { 1, { 2 } }))
  assertFalse(stubLib.SameValue({ a = false }, {}), "false and absent differ")
end)

test("schema: L overrides a STRINGS key, and a synthesizing L does not mask the rest", function()
  -- red under: resolving the override with a plain index instead of rawget
  local L = setmetatable({ NOT_FOUND = "Unknown: %s" }, { __index = function(_, k) return k end })
  local S = newFlat({ L = L })
  local _, err = S.Set("nope", 1)
  assertEqual(err, "Unknown: nope", "a real entry wins")
  local _, err2 = S.Set("scale", "x")
  assertEqual(err2, "Invalid value for scale", "a synthesized key falls through to STRINGS")
end)

-- ── path primitives ─────────────────────────────────────────────────────────────────────────

test("schema: SplitPath memoizes by identity, drops empty segments, tostrings a number", function()
  local a = Schema.SplitPath("units.player.width")
  assertTrue(a == Schema.SplitPath("units.player.width"), "the same table for the same path")
  assertEqual(table.concat(a, "|"), "units|player|width")
  assertEqual(table.concat(Schema.SplitPath("a..b."), "|"), "a|b", "empty segments dropped")
  assertEqual(#Schema.SplitPath("..."), 0, "all-dots is the empty path")
  assertEqual(#Schema.SplitPath(""), 0)
  assertEqual(table.concat(Schema.SplitPath(42), "|"), "42", "a number is tostring'd")
  assertEqual(#Schema.SplitPath(nil), 0, "nil is the empty path, not the segment 'nil'")
end)

test("schema: Read walks a nested path and answers nil at every absence", function()
  local root = { a = { b = { c = 3 } }, s = "leaf" }
  assertEqual(Schema.Read(root, "a.b.c"), 3)
  assertNil(Schema.Read(root, "a.b.x"), "missing leaf")
  assertNil(Schema.Read(root, "s.x"), "a non-table intermediate")
  assertNil(Schema.Read(nil, "a"), "nil root")
  assertNil(Schema.Read("str", "a"), "non-table root")
  assertNil(Schema.Read(root, ""), "the empty path is not the root")
  assertEqual(Schema.Read(root, "kind.b.c", 2), nil, "first = 2 skips the leading segment")
  assertEqual(Schema.Read(root.a, "kind.b.c", 2), 3, "first = 2 reads from the second segment")
  assertEqual(Schema.Read(root, { "a", "b", "c" }), 3, "a parts array is taken as already split")
  assertNil(Schema.Read(root, { "a" }, 2), "first past the end is the empty path")
end)

test("schema: Write creates intermediates and repairs a non-table one", function()
  local root = { s = "leaf" }
  Schema.Write(root, "a.b.c", 1)
  assertEqual(root.a.b.c, 1, "intermediates created")
  Schema.Write(root, "s.x", 2)
  assertEqual(type(root.s), "table", "a scalar where a section belongs is replaced")
  assertEqual(root.s.x, 2)
  Schema.Write(nil, "a", 1)                               -- no raise
  Schema.Write(root, "", 9)
  assertNil(root[""], "the empty path writes nothing")
  local m = {}
  Schema.Write(m, "kind.width", 7, 2)
  assertEqual(m.width, 7, "first = 2 writes from the second segment")
  local t = {}
  Schema.Write(root, "keep", t)
  assertTrue(root.keep == t, "Write stores the value itself; copying is the seam's decision")
end)

test("schema: SameValue compares scalars, -0, nested tables, both directions", function()
  local same = Schema.SameValue
  assertTrue(same(1, 1)); assertTrue(same(nil, nil)); assertTrue(same(-0, 0))
  assertFalse(same(1, "1")); assertFalse(same(1, nil)); assertFalse(same({}, 1))
  assertTrue(same({ a = { b = 1 } }, { a = { b = 1 } }), "nested, by content")
  assertFalse(same({ a = 1 }, { a = 1, b = 2 }), "extra key on the right")
  assertFalse(same({ a = 1, b = 2 }, { a = 1 }), "extra key on the left")
  assertFalse(same({ a = false }, {}), "false is not absence")
  assertFalse(same({ a = { b = 1 } }, { a = { b = 2 } }))
end)

test("schema: a warm Read allocates nothing", function()
  -- The AbsorbTracker / PartyFrameEnhanced perf ceilings, pinned upstream so a re-vendor cannot
  -- regress them silently: the split is memoized and the walk is an integer loop.
  local root = { units = { player = { width = 200 } } }
  local S = newFlat()
  Schema.Read(root, "units.player.width")
  S.Get("units.player.width")
  collectgarbage("collect")
  collectgarbage("stop")
  local before = collectgarbage("count")
  for _ = 1, 1000 do
    Schema.Read(root, "units.player.width")
    S.Get("units.player.width")
  end
  local grew = collectgarbage("count") - before
  collectgarbage("restart")
  assertTrue(grew < 1, ("1000 warm reads grew the heap by %.3f KB"):format(grew))
end)

-- ── the registry ────────────────────────────────────────────────────────────────────────────

test("schema: New refuses a descriptor without rows and holds rows by reference", function()
  local err = assertError(function() Schema:New(nil) end)
  assertTrue(err:find("descriptor.rows", 1, true) ~= nil, err)
  assertErrorMatches(function() Schema:New{ rows = "x" } end, "descriptor.rows must be a table")
  local S, fx = newFlat()
  assertTrue(S.AllRows() == fx.rows, "AllRows is the host's own table")
  assertTrue(S.FindRow("scale") == fx.rows[2], "rows present at New are indexed")
end)

test("schema: FindRow is first-wins, skips path-less rows, and refuses a non-string", function()
  local first = { path = "a", type = "bool", group = "g" }
  local second = { path = "a", type = "bool", group = "g" }
  local bound = { type = "bool", group = "g", get = function() end, set = function() end }
  local S = Schema:New{ rows = { first, second, bound } }
  assertTrue(S.FindRow("a") == first, "the first registered row wins")
  assertNil(S.FindRow(nil)); assertNil(S.FindRow(1))
  assertNil(S.FindRow(""), "a path-less row is not indexed under anything")
end)

test("schema: AddRows appends, inserts at the head in order, and clamps past the end", function()
  local S = Schema:New{ rows = { { path = "x" } } }
  assertEqual(S.AddRows({ { path = "y" } }), 1)
  assertEqual(S.AddRows({ { path = "h1" }, { path = "h2" } }, 1), 2)
  assertEqual(S.AddRows({ { path = "z" } }, 99), 1, "past the end appends")
  assertEqual(S.AddRows({ { path = "h0" } }, 0), 1, "below 1 is the head")
  local order = {}
  for _, row in ipairs(S.AllRows()) do order[#order + 1] = row.path end
  assertEqual(table.concat(order, ","), "h0,h1,h2,x,y,z")
  assertTrue(S.FindRow("h2") ~= nil and S.FindRow("z") ~= nil, "every added row is indexed")
  assertEqual(S.AddRows("nope"), 0, "a non-table adds nothing")
end)

test("schema: a head insert re-indexes, so a new duplicate becomes the first", function()
  local old = { path = "a" }
  local new = { path = "a" }
  local S = Schema:New{ rows = { old } }
  S.AddRows({ new }, 1)
  assertTrue(S.FindRow("a") == new, "first-wins follows the array, not insertion time")
end)

test("schema: a host's in-place removal is seen after Reindex and not before", function()
  local S, fx = newFlat()
  table.remove(fx.rows, 2)                                   -- "scale"
  assertTrue(S.FindRow("scale") ~= nil, "the index is stale until the host says so")
  S.Reindex()
  assertNil(S.FindRow("scale"))
end)

-- ── the shape check ─────────────────────────────────────────────────────────────────────────

local function flatDefaultsRoot(fx)
  return function(_, row)
    if row.path == "minimap" then return fx.defaults.global, 1 end
    return fx.defaults.profile, 1
  end
end

test("schema: a healthy schema validates to zero errors and resolves every stored row", function()
  local S, fx = newFlat()
  fx.defaults.global.minimap = true      -- the inverted row resolves against the global store
  local e, r, m = S.Validate{
    pages = { general = true, units = true },
    defaultsRoot = flatDefaultsRoot(fx),
  }
  assertEqual(e, 0); assertEqual(m, 0)
  -- enabled, scale, color, units.player.width, minimap; the sessionOnly console is skipped.
  assertEqual(r, 5)
  assertEqual(#fx.rec.chat, 0, "nothing printed")
end)

test("schema: each shape error is counted and printed once", function()
  local rec = newRecorder()
  local rows = {
    "not a row",
    { type = "bool", group = "g", page = "p" },                    -- no path
    { path = "a", type = "slider", group = "g", page = "p" },      -- bad type
    { path = "b", type = "bool", group = "g", page = "nowhere" },  -- bad page
    { path = "c", type = "bool", page = "p" },                     -- no group
    { path = "a", type = "bool", group = "g", page = "p" },        -- duplicate of row 3
  }
  local S = Schema:New(spies(rec, { rows = rows }))
  local e, r, m = S.Validate{ pages = { p = true } }
  assertEqual(e, 6)
  assertEqual(r, 0); assertEqual(m, 0, "no defaultsRoot, no resolution check")
  assertEqual(#rec.chat, 6)
  assertEqual(rec.chat[1], "|cffff0000schema error|r: row #1 (<no path>): row is not a table")
  assertTrue(rec.chat[2]:find("missing or empty `path`", 1, true) ~= nil)
  assertTrue(rec.chat[3]:find("invalid `type` = slider", 1, true) ~= nil)
  assertTrue(rec.chat[4]:find("invalid `page` = nowhere", 1, true) ~= nil)
  assertTrue(rec.chat[5]:find("missing or empty `group`", 1, true) ~= nil)
  assertEqual(rec.chat[6], "|cffff0000schema error|r: row #6 (a): duplicate `path` (first used by row #3)")
end)

test("schema: an unresolvable path is missing; sessionOnly, nil roots and bound rows are exempt", function()
  local rec = newRecorder()
  local defaults = { a = 1 }
  local rows = {
    { path = "a", type = "bool", group = "g" },
    { path = "typo", type = "bool", group = "g" },
    { path = "sess", type = "bool", group = "g", sessionOnly = true },
    { path = "elsewhere", type = "bool", group = "g" },
    { type = "bool", group = "g", get = function() end, set = function() end },
  }
  local S = Schema:New(spies(rec, { rows = rows }))
  local e, r, m = S.Validate{
    defaultsRoot = function(_, row) if row.path == "elsewhere" then return nil end return defaults, 1 end,
  }
  assertEqual(e, 0, "a path-less get/set row is not an error")
  assertEqual(r, 1); assertEqual(m, 1)
  assertEqual(#rec.chat, 1)
  assertEqual(rec.chat[1], "|cffff0000schema error|r: row #2 (typo): `path` does not resolve against the defaults")
end)

test("schema: types defaults to the four widget types and a host set replaces it", function()
  local rows = { { path = "a", type = "table", group = "g" } }
  local S = Schema:New{ rows = rows }
  assertEqual((S.Validate()), 1, "table is not a default type")
  assertEqual((S.Validate{ types = { table = true } }), 0)
end)

test("schema: Validate with no print still counts, silently", function()
  local S = Schema:New{ rows = { "x", { path = "a", type = "bool", group = "g" } } }
  local e, r, m = S.Validate{ defaultsRoot = function() return {}, 1 end }
  assertEqual(e, 1); assertEqual(r, 0); assertEqual(m, 1)
end)

test("schema: one row's errors print in field order, and its missing line prints after them", function()
  -- Characterization for the v1.55.0 CCN split of Validate: path, type, page, group, then the
  -- resolution line, which is printed but never counted as an error.
  local rec = newRecorder()
  local rows = {
    { get = function() end, type = "x", page = "q", group = "" },     -- get without set: unreachable
    { path = "z", type = "x", page = "q" },
  }
  local S = Schema:New(spies(rec, { rows = rows }))
  local e, r, m = S.Validate{ pages = { p = true }, defaultsRoot = function() return {}, 1 end }
  assertEqual(e, 7); assertEqual(r, 0); assertEqual(m, 1)
  assertEqual(table.concat(rec.chat, "\n"), table.concat({
    "|cffff0000schema error|r: row #1 (<no path>): missing or empty `path`",
    "|cffff0000schema error|r: row #1 (<no path>): invalid `type` = x",
    "|cffff0000schema error|r: row #1 (<no path>): invalid `page` = q",
    "|cffff0000schema error|r: row #1 (<no path>): missing or empty `group`",
    "|cffff0000schema error|r: row #2 (z): invalid `type` = x",
    "|cffff0000schema error|r: row #2 (z): invalid `page` = q",
    "|cffff0000schema error|r: row #2 (z): missing or empty `group`",
    "|cffff0000schema error|r: row #2 (z): `path` does not resolve against the defaults",
  }, "\n"))
end)

test("schema: a non-string or empty path is labeled as given and is never a stored path", function()
  local rec = newRecorder()
  local calls = 0
  local rows = {
    { path = 5, type = "bool", group = "g" },
    { path = false, type = "bool", group = "g" },
    { path = "", type = "bool", group = "g", get = function() end, set = function() end },
    { path = "", type = "bool", group = "g", get = function() end, set = function() end },
  }
  local S = Schema:New(spies(rec, { rows = rows }))
  local e, r, m = S.Validate{ defaultsRoot = function() calls = calls + 1; return {}, 1 end }
  assertEqual(e, 2, "5 and false are missing paths; a bound \"\" row is not, and is no duplicate")
  assertEqual(r, 0); assertEqual(m, 0)
  assertEqual(calls, 0, "defaultsRoot is asked about no row without a string path")
  assertEqual(rec.chat[1], "|cffff0000schema error|r: row #1 (5): missing or empty `path`")
  assertEqual(rec.chat[2], "|cffff0000schema error|r: row #2 (<no path>): missing or empty `path`", "a false path reads as none")
end)

test("schema: defaultsRoot gets the split parts and the row, and its first may be a string", function()
  local rows = { { path = "x.a", type = "bool", group = "g" }, { path = "x.b", type = "bool", group = "g" } }
  local S = Schema:New{ rows = rows }
  local got = {}
  local e, r, m = S.Validate{ defaultsRoot = function(parts, row)
    got[#got + 1] = { parts = parts, row = row }
    if row.path == "x.a" then return { a = 1 }, "2" end
    return { x = { b = 1 } }, nil
  end }
  assertEqual(e, 0); assertEqual(r, 2); assertEqual(m, 0)
  assertTrue(got[1].parts == Schema.SplitPath("x.a"), "the memoized parts, by identity")
  assertTrue(got[1].row == rows[1])
  assertTrue(got[2].row == rows[2])
end)

test("schema: a malformed spec falls back field by field", function()
  local rows = { { path = "a", type = "bool", group = "g", page = "nowhere" } }
  local S = Schema:New{ rows = rows }
  assertEqual((S.Validate("junk")), 0, "a non-table spec is the empty spec")
  assertEqual((S.Validate{ types = "junk", pages = "junk", defaultsRoot = "junk" }), 0,
    "types falls back to the four widget types; no page or resolution check")
  local e, r, m = S.Validate{ types = { table = true }, defaultsRoot = {} }
  assertEqual(e, 1, "bool is not in a host's own types set"); assertEqual(r, 0); assertEqual(m, 0)
end)

test("schema: two instances share nothing", function()
  local a, fxa = newFlat()
  local b, fxb = newFlat()
  a.BulkBegin("reset", "all")
  assertFalse(b.InBulk())
  b.Set("scale", 1.5)
  assertEqual(fxb.rec.debugLines[1], "[Set] scale = 1.5", "b is not muted by a's bracket")
  a.BulkEnd("reset", "all")
  assertEqual(fxa.rec.debugLines[1], "[Set] reset all: 0 rows")
end)
