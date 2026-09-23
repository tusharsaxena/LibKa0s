-- tests/test_schema_batch.lua — LibKa0s-Schema-1.0 minor 2: the all-or-nothing batch `SetMany`,
-- the row's `normalize`, the instance id reaching a row's `get` and `ApplyDefault`'s write, and the
-- descriptor's `writeThrough` paths, stored without a row.
--
-- ── WHY A SUITE OF ITS OWN ────────────────────────────────────────────────────────────────────
--
-- `layout-§1`. tests/test_schema.lua was 1233 lines when these cases were written, so minor 2's
-- cases start a file of their own rather than taking that one toward the 1500-line cap. The
-- reference degradation stub stays there, because it is pinned against the live instance by the
-- cases around it; its SetMany is pinned there too.
--
-- ── WHAT THESE CASES PIN ──────────────────────────────────────────────────────────────────────
--
-- ALL OR NOTHING: a batch with one refused entry (unknown path, validate, normalize) stores
-- nothing, calls nothing, and names the entry's index. A batch that passes stores every entry,
-- runs every onChange, and announces ONCE through `announceBatch` when the host gave one. With an
-- `act`, the batch is one bracket and therefore one `[Set] <act> <scope>: N rows` line.
--
-- Every case builds its own fixture; the claims are mostly about absence, and a shared fixture
-- would carry one case's writes into the next one's "nothing happened".

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local Schema = T.schema

-- ── fixture ─────────────────────────────────────────────────────────────────────────────────

--- A flat profile store with a validated number, a clamping (normalizing) number, a nested path
--- and a closure row whose `get` records the id it was handed. One ordered log records every host
--- callback, so an order or an absence is asserted rather than inferred.
local function newBatch(overrides)
  local fx = { log = {}, debugLines = {}, gets = {}, batches = {} }
  local function add(e) fx.log[#fx.log + 1] = e end
  local function onChange(path)
    return function(value, rid) add("onChange:" .. path .. "=" .. tostring(value) .. "@" .. tostring(rid)) end
  end
  fx.db = { scale = 1, alpha = 0.5, frame = { width = 100 }, label = "a" }
  fx.store = { mode = "x" }
  fx.rows = {
    { path = "scale", type = "number", page = "p", group = "g", default = 1,
      validate = function(v) return type(v) == "number", "not a number" end,
      onChange = onChange("scale") },
    { path = "alpha", type = "number", page = "p", group = "g", default = 0.5,
      validate = function(v) return type(v) == "number", "not a number" end,
      normalize = function(v, rid)
        add("normalize:" .. tostring(v) .. "@" .. tostring(rid))
        if v < 0 then return nil, "below zero" end
        if v > 1 then return 1 end
        return v
      end,
      onChange = onChange("alpha") },
    { path = "frame.width", type = "number", page = "p", group = "g", default = 100,
      onChange = onChange("frame.width") },
    { path = "label", type = "string", page = "p", group = "g", default = "a",
      onChange = onChange("label") },
    { path = "mode", type = "string", page = "p", group = "g", default = "x",
      get = function(id) fx.gets[#fx.gets + 1] = id == nil and "nil" or tostring(id); return fx.store.mode end,
      set = function(v) fx.store.mode = v end,
      onChange = onChange("mode") },
  }
  local d = {
    rows = fx.rows,
    resolveRoot = function(_, id) return fx.db, 1, id end,
    debug = function(tag, fmt, ...)
      fx.debugLines[#fx.debugLines + 1] = ("[%s] " .. fmt):format(tag, ...)
      add("debug")
    end,
    announce = function(_, path, value, rid)
      add("announce:" .. path .. "=" .. tostring(value) .. "@" .. tostring(rid))
    end,
  }
  for k, v in pairs(overrides or {}) do d[k] = v end
  fx.d = d
  fx.S = Schema:New(d)
  return fx.S, fx
end

--- A host `announceBatch` recording each call's writes and id.
local function batchSpy(fx)
  return function(writes, rid)
    fx.log[#fx.log + 1] = "announceBatch:" .. #writes .. "@" .. tostring(rid)
    fx.batches[#fx.batches + 1] = { writes = writes, rid = rid }
  end
end

local function countPrefix(log, prefix)
  local n = 0
  for _, e in ipairs(log) do
    if e:sub(1, #prefix) == prefix then n = n + 1 end
  end
  return n
end

-- ── the minor ───────────────────────────────────────────────────────────────────────────────

test("schema batch: the instance carries SetMany at minor 2", function()
  -- red under: minor 1, which has no SetMany
  local S = newBatch()
  assertTrue(Schema.MINOR >= 2, "Schema minor 2 or newer")
  assertEqual(type(S.SetMany), "function", "SetMany is an instance member")
end)

-- ── all or nothing ──────────────────────────────────────────────────────────────────────────

test("schema batch: one invalid entry stores nothing, calls nothing, and names its index", function()
  -- red under: storing entries as they validate (the first entry would land)
  local S, fx = newBatch()
  local ok, err, why, at = S.SetMany({
    { path = "scale", value = 1.5 },
    { path = "frame.width", value = 250 },
    { path = "scale", value = "big" },
  })
  assertFalse(ok, "the batch is refused")
  assertEqual(err, "Invalid value for scale")
  assertEqual(why, "not a number")
  assertEqual(at, 3, "the refused entry's index")
  assertEqual(fx.db.scale, 1, "entry 1 did not land")
  assertEqual(fx.db.frame.width, 100, "entry 2 did not land")
  assertEqual(#fx.log, 0, "no debug, onChange or announce")
end)

test("schema batch: an unknown path refuses the whole batch", function()
  -- red under: skipping an unknown entry rather than refusing the batch
  local S, fx = newBatch()
  local ok, err, why, at = S.SetMany({
    { path = "scale", value = 1.5 },
    { path = "nope", value = 1 },
  })
  assertFalse(ok)
  assertEqual(err, "Setting not found: nope")
  assertNil(why)
  assertEqual(at, 2)
  assertEqual(fx.db.scale, 1, "nothing stored")
  assertNil(fx.db.nope, "the unknown path is never stored")
  assertEqual(#fx.log, 0)
end)

test("schema batch: a normalize refusal inside a batch refuses it whole", function()
  local S, fx = newBatch()
  local ok, err, why, at = S.SetMany({
    { path = "label", value = "b" },
    { path = "alpha", value = -1 },
  })
  assertFalse(ok)
  assertEqual(err, "Invalid value for alpha")
  assertEqual(why, "below zero")
  assertEqual(at, 2)
  assertEqual(fx.db.label, "a", "the entry ahead of it did not land")
end)

-- ── a batch that passes ─────────────────────────────────────────────────────────────────────

test("schema batch: a valid batch stores every entry, runs every onChange, announces once", function()
  -- red under: announcing per write when the host gave announceBatch
  local S, fx = newBatch()
  fx.d.announceBatch = batchSpy(fx)
  assertTrue(S.SetMany({
    { path = "scale", value = 1.5 },
    { path = "frame.width", value = 250 },
    { path = "mode", value = "y" },
  }, { instanceId = 7 }))
  assertEqual(fx.db.scale, 1.5)
  assertEqual(fx.db.frame.width, 250)
  assertEqual(fx.store.mode, "y", "a closure row's set ran")
  assertEqual(countPrefix(fx.log, "onChange:"), 3, "every onChange ran")
  assertEqual(countPrefix(fx.log, "announce:"), 0, "no per-write announce")
  assertEqual(#fx.batches, 1, "announceBatch ran once")
  local b = fx.batches[1]
  assertEqual(b.rid, 7, "the batch's resolved id")
  assertEqual(#b.writes, 3)
  assertEqual(b.writes[1].path, "scale")
  assertEqual(b.writes[1].value, 1.5)
  assertTrue(b.writes[1].row == S.FindRow("scale"), "the row itself, by identity")
  assertEqual(b.writes[3].path, "mode")
  assertEqual(fx.log[#fx.log], "announceBatch:3@7", "the announce comes last")
end)

test("schema batch: every store lands before the first onChange runs", function()
  -- A batch is one act: a reaction reading a sibling row sees the whole batch, and a raising
  -- onChange cannot leave the store half-written.
  local S, fx = newBatch()
  local seen
  S.FindRow("scale").onChange = function() seen = fx.db.frame.width end
  assertTrue(S.SetMany({
    { path = "scale", value = 1.5 },
    { path = "frame.width", value = 250 },
  }))
  assertEqual(seen, 250, "the first reaction already sees the second store")
end)

test("schema batch: without announceBatch, announce runs once per write, after the reactions", function()
  local S, fx = newBatch()
  assertTrue(S.SetMany({
    { path = "scale", value = 1.5 },
    { path = "label", value = "b" },
  }, { instanceId = 3 }))
  assertEqual(table.concat(fx.log, ","), table.concat({
    "debug", "debug",
    "onChange:scale=1.5@3", "onChange:label=b@3",
    "announce:scale=1.5@3", "announce:label=b@3",
  }, ","), "outside a bracket each write logs its own line")
end)

test("schema batch: with an act the batch is one bracket and one line counting the rows it moved", function()
  -- red under: logging each write, or counting the entry already at its value
  local S, fx = newBatch()
  fx.d.announceBatch = batchSpy(fx)
  assertTrue(S.SetMany({
    { path = "scale", value = 1.5 },
    { path = "frame.width", value = 250 },
    { path = "label", value = "a" },          -- already "a": written, not a change
  }, { act = "copy", scope = "target→focus" }))
  assertEqual(#fx.debugLines, 1, "exactly one line")
  assertEqual(fx.debugLines[1], "[Set] copy target→focus: 2 rows")
  assertFalse(S.InBulk(), "the bracket closed")
  assertEqual(fx.log[#fx.log], "announceBatch:3@nil", "announce after the bracket's line")
end)

test("schema batch: a raising onChange still closes the batch's bracket, and the stores stand", function()
  local S, fx = newBatch()
  S.FindRow("label").onChange = function() error("boom", 0) end
  local ok, err = pcall(S.SetMany, {
    { path = "scale", value = 1.5 },
    { path = "label", value = "b" },
  }, { act = "copy", scope = "all" })
  assertFalse(ok)
  assertEqual(err, "boom", "the error comes back unchanged")
  assertFalse(S.InBulk(), "the bracket closed")
  assertEqual(fx.debugLines[1], "[Set] copy all: 2 rows (stopped by an error)")
  assertEqual(fx.db.scale, 1.5)
  assertEqual(fx.db.label, "b")
end)

test("schema batch: an empty batch stores nothing and answers true", function()
  local S, fx = newBatch()
  fx.d.announceBatch = batchSpy(fx)
  assertTrue(S.SetMany({}))
  assertTrue(S.SetMany(nil), "a non-table batch is the empty batch")
  assertEqual(#fx.log, 0, "no announce for no writes")
end)

-- ── normalize ───────────────────────────────────────────────────────────────────────────────

test("schema batch: Set stores normalize's value and hands it to onChange and announce", function()
  -- red under: minor 1, which ignores row.normalize (2 would be stored)
  local S, fx = newBatch()
  assertTrue(S.Set("alpha", 2, 4))
  assertEqual(fx.db.alpha, 1, "the clamped value is stored")
  assertEqual(table.concat(fx.log, ","), table.concat({
    "normalize:2@4", "debug", "onChange:alpha=1@4", "announce:alpha=1@4",
  }, ","))
end)

test("schema batch: normalize answering nil, why refuses with INVALID and stores nothing", function()
  local S, fx = newBatch()
  local ok, err, why = S.Set("alpha", -1)
  assertFalse(ok)
  assertEqual(err, "Invalid value for alpha")
  assertEqual(why, "below zero")
  assertEqual(fx.db.alpha, 0.5, "nothing stored")
  assertEqual(table.concat(fx.log, ","), "normalize:-1@nil", "nothing called after normalize")
end)

test("schema batch: normalize runs only after validate accepts", function()
  local S, fx = newBatch()
  local ok = S.Set("alpha", "x")
  assertFalse(ok)
  assertEqual(#fx.log, 0, "a value validate refused never reaches normalize")
end)

test("schema batch: a normalize refusal comes before a missing root", function()
  local S, fx = newBatch()
  fx.d.resolveRoot = function() return nil end
  local _, err = S.Set("alpha", -1)
  assertEqual(err, "Invalid value for alpha", "the bad value is named first")
end)

-- ── the instance id ─────────────────────────────────────────────────────────────────────────

test("schema batch: Get hands the instance id to a row's own get", function()
  -- red under: minor 1's `get()` with no argument
  local S, fx = newBatch()
  assertEqual(S.Get("mode", 9), "x")
  S.Get("mode")
  assertEqual(table.concat(fx.gets, ","), "9,nil")
end)

test("schema batch: ApplyDefault(row, id) writes through Set with that id", function()
  -- red under: minor 1's ApplyDefault(row), which drops the id
  local seen = {}
  local S, fx = newBatch()
  fx.d.resolveRoot = function(_, id)
    seen[#seen + 1] = id == nil and "nil" or tostring(id)
    return fx.db, 1, id
  end
  fx.db.scale = 2
  assertTrue(S.ApplyDefault(S.FindRow("scale"), 5))
  assertEqual(fx.db.scale, 1)
  assertEqual(seen[1], "5", "the resolver saw the id")
  assertEqual(fx.log[#fx.log], "announce:scale=1@5", "and so did the announce")
end)

-- ── writeThrough ────────────────────────────────────────────────────────────────────────────
--
-- A declared list of paths the seam stores WITHOUT a row: the standard's route (a) for a host verb
-- that writes a composed Master-controls row (`enabled`, `locked`) on a load where the composer
-- that would have declared the row is absent. Stored raw (a copy), logged, announced with a
-- synthetic row; no validate, no normalize, no onChange. A path with a row always takes the row.

--- A batch fixture whose `announce` also keeps the row it was handed, per call.
local function newWriteThrough(list)
  local S, fx = newBatch({ writeThrough = list })
  fx.announced = {}
  fx.d.announce = function(row, path, value, rid)
    fx.log[#fx.log + 1] = "announce:" .. path .. "=" .. tostring(value) .. "@" .. tostring(rid)
    fx.announced[#fx.announced + 1] = row
  end
  return S, fx
end

test("schema batch: a writeThrough path with no row is stored raw, logged and announced", function()
  -- red under: the NOT_FOUND refusal every row-less path got before writeThrough
  local S, fx = newWriteThrough({ "enabled" })
  assertNil(S.FindRow("enabled"), "no row declares it")
  assertTrue(S.Set("enabled", false, 4), "a listed row-less path is written")
  assertEqual(fx.db.enabled, false, "false is stored, not skipped")
  assertEqual(table.concat(fx.log, ","), "debug,announce:enabled=false@4",
    "logged like any write, then announced; no onChange ran")
  assertEqual(fx.debugLines[1], "[Set] enabled = false")
  local row = fx.announced[1]
  assertTrue(row.writeThrough == true, "the announce carries a synthetic row marked writeThrough")
  assertEqual(row.path, "enabled")
  assertTrue(S.Set("enabled", true), "written again")
  assertTrue(fx.announced[2] == row, "one synthetic row per path, built once, never per write")
end)

test("schema batch: a row-less path NOT in writeThrough is still refused and never stored", function()
  local S, fx = newWriteThrough({ "enabled" })
  local ok, err = S.Set("locked", true)
  assertFalse(ok)
  assertEqual(err, "Setting not found: locked")
  assertNil(fx.db.locked, "nothing stored")
  assertEqual(#fx.log, 0, "nothing logged or announced")
end)

test("schema batch: a writeThrough path that HAS a row takes the row and its validate", function()
  -- red under: the list winning over the index (the bad value would be stored raw)
  local S, fx = newWriteThrough({ "scale" })
  local ok, err, why = S.Set("scale", "big")
  assertFalse(ok, "the row's validate still refuses")
  assertEqual(err, "Invalid value for scale")
  assertEqual(why, "not a number")
  assertEqual(fx.db.scale, 1, "nothing stored")
  assertTrue(S.Set("scale", 1.5))
  assertEqual(countPrefix(fx.log, "onChange:scale"), 1, "the row's onChange ran")
  assertTrue(fx.announced[1] == S.FindRow("scale"), "announced with the real row")
end)

test("schema batch: a writeThrough store is a copy, and a missing root still refuses", function()
  local S, fx = newWriteThrough({ "tint" })
  local tint = { r = 1 }
  assertTrue(S.Set("tint", tint))
  tint.r = 0
  assertEqual(fx.db.tint.r, 1, "the caller's table and the store do not alias")
  fx.d.resolveRoot = function() return nil end
  local ok, err = S.Set("tint", { r = 0.5 })
  assertFalse(ok)
  assertEqual(err, "Setting has nowhere to be stored yet: tint")
end)

test("schema batch: a writeThrough write inside a bracket joins its tally, and SetMany takes it", function()
  local S, fx = newWriteThrough({ "enabled", "locked" })
  S.BulkRun("reset", "all", function()
    S.Set("enabled", true)
    S.Set("locked", nil)                          -- already absent: written, not a change
  end)
  assertEqual(fx.debugLines[1], "[Set] reset all: 1 rows")
  assertTrue(S.SetMany({ { path = "locked", value = true }, { path = "scale", value = 2 } }))
  assertEqual(fx.db.locked, true, "a listed path is a batch entry like any row")
  assertEqual(fx.db.scale, 2)
end)

test("schema batch: a malformed writeThrough list keeps only its non-empty strings", function()
  local S, fx = newWriteThrough({ "enabled", "", 5, false })
  assertTrue(S.Set("enabled", true))
  assertFalse(S.Set("", 1), "an empty path is never written through")
  assertFalse(S.Set("5", 1), "a number is not a path")
  assertEqual(fx.db["5"], nil)
  local S2 = newBatch({ writeThrough = "enabled" })
  assertFalse(S2.Set("enabled", true), "a list that is not a table is no list")
end)
