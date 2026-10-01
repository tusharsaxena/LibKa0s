-- tests/test_schema_write.lua — the settings schema runtime's write stage onward: the write seam
-- (Set and its refusals, the instance resolver, the log-react-announce order), defaults and
-- ApplyDefault, the bulk bracket, and the profile reset's count.
--
-- Peeled whole from tests/test_schema.lua (issue #38), every case moved unchanged, so that suite
-- leaves layout-§1's 1000-1500 band. The split follows the pipeline: that suite keeps the major,
-- the reference degradation stub, the path primitives, the registry and the shape check; the
-- fixture constructors both read are tests/fixture_schema.lua. Why every case builds its own
-- fixture, and why the recorder keeps one ordered log, is tests/test_schema.lua's header.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local Schema = T.schema

local F = dofile("tests/fixture_schema.lua")
local newRecorder, spies, onChangeSpy, newFlat, rowAt, newInstance, newClosure =
  F.newRecorder, F.spies, F.onChangeSpy, F.newFlat, F.rowAt, F.newInstance, F.newClosure

-- ── the write seam ──────────────────────────────────────────────────────────────────────────

test("schema: an unknown path is refused and nothing is stored or called", function()
  -- red under: storing a write to a path with no row (JC-2)
  local S, fx = newFlat()
  local ok, err = S.Set("nope.path", 5)
  assertFalse(ok)
  assertEqual(err, "Setting not found: nope.path")
  assertEqual(fx.rec.joined(), "", "no debug, no onChange, no announce")
  assertNil(fx.db.profile.nope, "nothing stored")
  local ok2, err2 = S.Set(nil, 1)
  assertFalse(ok2); assertEqual(err2, "Setting not found: nil")
end)

test("schema: a write logs, then reacts, then announces, once each, and copies a table", function()
  -- red under: calling onChange before the debug line (JC-4), or storing the caller's table (JC-6)
  local S, fx = newFlat()
  local c = { r = 0, g = 0.5, b = 1, a = 1 }
  assertTrue(S.Set("color", c))
  assertEqual(fx.rec.joined(), "debug,onChange:color,announce:color")
  assertTrue(fx.db.profile.color ~= c, "the store holds a copy")
  c.r = 0.9
  assertEqual(fx.db.profile.color.r, 0, "mutating the argument afterwards leaves the store alone")
  assertTrue(fx.rec.lastOnChange.value == c, "onChange gets the value as given")
  assertTrue(fx.rec.lastAnnounce.row == rowAt(fx, "color"), "announce gets the row")
end)

test("schema: a validate refusal names the path and carries why, and nothing happens", function()
  local S, fx = newFlat()
  local ok, err, why = S.Set("scale", 9)
  assertFalse(ok)
  assertEqual(err, "Invalid value for scale")
  assertEqual(why, "out of range")
  assertEqual(fx.db.profile.scale, 1, "nothing stored")
  assertEqual(fx.rec.joined(), "")
end)

test("schema: a bare-false validate is refused with why = nil", function()
  local rows = { { path = "a", validate = function() return false end } }
  local S = Schema:New{ rows = rows, resolveRoot = function() return {}, 1 end }
  local ok, err, why = S.Set("a", 1)
  assertFalse(ok); assertEqual(err, "Invalid value for a"); assertNil(why)
end)

test("schema: an instance-rooted write reaches the named instance, not the active one", function()
  local S, fx = newInstance()
  assertTrue(S.Set("member.width", 175, 2))
  assertEqual(fx.members[2].width, 175, "member 2 written")
  assertEqual(fx.members[1].width, 100, "the active member untouched")
  assertEqual(fx.rec.lastOnChange.rid, 2, "onChange receives the resolved id")
  assertEqual(fx.rec.lastAnnounce.rid, 2, "announce receives the resolved id")
  assertEqual(S.Get("member.width", 2), 175)
  assertEqual(S.Get("member.width"), 100, "no id is the resolver's default")
end)

test("schema: an absent instance is refused with the resolver's reason, after validate", function()
  -- red under: checking the root before validate (a bad value must be named first)
  local S, fx = newInstance()
  local ok, err = S.Set("member.width", 50, 9)
  assertFalse(ok); assertEqual(err, "no member")
  local ok2, err2 = S.Set("member.width", -1, 9)
  assertFalse(ok2); assertEqual(err2, "Invalid value for member.width", "INVALID wins over no root")
  assertEqual(fx.rec.count("onChange"), 0)
  assertNil(S.Get("member.width", 9), "root absent reads nil")
end)

test("schema: a resolver answering nil with no reason is refused as NO_ROOT", function()
  -- `function() return NS.db and NS.db.global, 1 end` before the db exists: the 1 is not a reason.
  local rows = { { path = "a" } }
  local S = Schema:New{ rows = rows, resolveRoot = function() return nil, 1 end }
  local ok, err = S.Set("a", 1)
  assertFalse(ok); assertEqual(err, "Setting has nowhere to be stored yet: a")
  assertNil(S.Get("a"))
  local S2 = Schema:New{ rows = { { path = "a" } } }
  local ok2, err2 = S2.Set("a", 1)
  assertFalse(ok2); assertEqual(err2, "Setting has nowhere to be stored yet: a", "no resolver at all")
end)

test("schema: a row with its own set stores through it and never resolves a root", function()
  local S, fx = newFlat()
  local v = { marker = true }
  local seen
  fx.rows[#fx.rows + 1] = { path = "own", set = function(x) seen = x end, get = function() return seen end }
  S.Reindex()
  local before = fx.rec.resolves
  assertTrue(S.Set("own", v))
  assertTrue(seen == v, "row.set gets the argument itself, not a copy")
  assertEqual(fx.rec.resolves, before, "resolveRoot never called for a closure row")
end)

test("schema: a sessionOnly row without set stores nothing and still reacts and announces", function()
  local rec = newRecorder()
  local rows = { { path = "s", sessionOnly = true, onChange = onChangeSpy(rec, "s") } }
  local S = Schema:New(spies(rec, { rows = rows, resolveRoot = function()
    rec.add("resolve"); return {}, 1 end }))
  assertTrue(S.Set("s", 1))
  assertEqual(rec.joined(), "debug,onChange:s,announce:s", "no resolve, no store, the tail runs")
  assertNil(S.Get("s"), "a sessionOnly row with no get reads nil")
end)

test("schema: the inverted minimap row stores the inverse and reads back the value", function()
  local S, fx = newFlat()
  assertTrue(S.Set("minimap", false))
  assertEqual(fx.db.global.minimap.hide, true)
  assertEqual(S.Get("minimap"), false)
  S.Set("minimap", true)
  assertEqual(fx.db.global.minimap.hide, false)
  assertEqual(S.Get("minimap"), true)
end)

test("schema: debugEnabled false means neither debug nor format runs", function()
  -- red under: formatting the value before asking whether anyone will read it (the color drag)
  local formats = 0
  local S, fx = newFlat({
    debugEnabled = function() return false end,
    format = function() formats = formats + 1; return "x" end,
  })
  S.Set("scale", 1.5)
  assertEqual(formats, 0)
  assertEqual(#fx.rec.debugLines, 0)
  assertEqual(fx.rec.joined(), "onChange:scale,announce:scale")
end)

test("schema: the Set line carries format(row, v) when given and the value otherwise", function()
  local S, fx = newFlat({ format = function(row, v) return row.path .. "<" .. tostring(v) .. ">" end })
  S.Set("scale", 1.5)
  assertEqual(fx.rec.debugLines[1], "[Set] scale = scale<1.5>")
  local S2, fx2 = newFlat()
  S2.Set("enabled", false)
  assertEqual(fx2.rec.debugLines[1], "[Set] enabled = false", "a boolean reaches %s as text")
end)

test("schema: with no debug, announce or format the seam still stores and reacts", function()
  local rec = newRecorder()
  local store = {}
  local S = Schema:New{ rows = { { path = "a", onChange = onChangeSpy(rec, "a") } },
    resolveRoot = function() return store, 1 end }
  assertTrue(S.Set("a", 3))
  assertEqual(store.a, 3)
  assertEqual(rec.joined(), "onChange:a")
end)

test("schema: a raising onChange propagates after the store and the line, before announce", function()
  -- red under: pcall around onChange (JC-3), or announce before onChange
  local S, fx = newFlat()
  rowAt(fx, "scale").onChange = function() fx.rec.add("boom"); error("host blew up") end
  local ok, err = pcall(S.Set, "scale", 1.5)
  assertFalse(ok)
  assertTrue(tostring(err):find("host blew up", 1, true) ~= nil)
  assertEqual(fx.db.profile.scale, 1.5, "the value landed")
  assertEqual(fx.rec.joined(), "debug,boom", "logged, reacted, never announced")
end)

test("schema: Set resolves before it validates, and validate and the tail see the resolved id", function()
  -- Characterization for the v1.55.0 CCN split of Set: the resolver runs first, with the caller's
  -- id, and the id it names is the one validate, onChange and announce are handed.
  local rec = newRecorder()
  local store = {}
  local rows = { { path = "k.v",
    validate = function(_, rid) rec.add("validate:" .. tostring(rid)); return true end,
    onChange = function(_, rid) rec.add("onChange:" .. tostring(rid)) end } }
  local S = Schema:New(spies(rec, { rows = rows, resolveRoot = function(_, id)
    rec.add("resolve:" .. tostring(id)); return store, 2, "R" end }))
  assertTrue(S.Set("k.v", 4, "given"))
  assertEqual(rec.joined(), "resolve:given,validate:R,debug,onChange:R,announce:k.v")
  assertEqual(store.v, 4, "stored from the resolver's first segment")
  assertEqual(rec.lastAnnounce.rid, "R")
end)

test("schema: a resolver naming no id leaves the caller's, and a false id is still an id", function()
  local rec = newRecorder()
  local id
  local rows = { { path = "a", onChange = function(_, rid) rec.add("onChange:" .. tostring(rid)) end } }
  local S = Schema:New{ rows = rows, resolveRoot = function() return {}, 1, id end }
  assertTrue(S.Set("a", 1, "given"))
  id = false
  assertTrue(S.Set("a", 1, "given"))
  assertEqual(rec.joined(), "onChange:given,onChange:false")
end)

test("schema: a closure or sessionOnly row hands validate and the tail the caller's id as given", function()
  local rec = newRecorder()
  local seen
  local function spy(tag) return function(_, rid) rec.add(tag .. ":" .. tostring(rid)); return true end end
  local rows = {
    { path = "own", set = function(v) seen = v end, validate = spy("v"), onChange = spy("c") },
    { path = "sess", sessionOnly = true, validate = spy("v"), onChange = spy("c") },
    { path = "both", sessionOnly = true, set = function(v) rec.add("set:" .. tostring(v)) end },
  }
  local S = Schema:New{ rows = rows, resolveRoot = function() rec.add("resolve"); return {}, 1, "R" end }
  assertTrue(S.Set("own", 3, 7))
  assertTrue(S.Set("sess", 4, 8))
  assertTrue(S.Set("both", 5))
  assertEqual(seen, 3)
  assertEqual(rec.joined(), "v:7,c:7,v:8,c:8,set:5", "no resolve; a sessionOnly row's own set still runs")
end)

test("schema: Set answers one value on success, two on a refusal, three on an invalid value", function()
  local rows = { { path = "a", validate = function(v) return v ~= 0, "zero" end },
    { path = "b", validate = function() return nil end } }
  local root
  local S = Schema:New{ rows = rows, resolveRoot = function() return root, 1 end }
  assertEqual(select("#", S.Set("zzz", 1)), 2, "NOT_FOUND")
  assertEqual(select("#", S.Set("a", 1)), 2, "NO_ROOT")
  assertEqual(select("#", S.Set("a", 0)), 3, "INVALID carries why")
  local ok, err, why = S.Set("b", 1)
  assertFalse(ok); assertEqual(err, "Invalid value for b"); assertNil(why)
  assertEqual(select("#", S.Set("b", 1)), 3, "INVALID with a nil why is still three")
  root = {}
  assertEqual(select("#", S.Set("a", 1)), 1, "success")
  assertEqual(root.a, 1)
end)

test("schema: a format answering nil falls back to the value's text on the Set line", function()
  local S, fx = newFlat({ format = function() return nil end })
  S.Set("scale", 1.5)
  assertEqual(fx.rec.debugLines[1], "[Set] scale = 1.5")
end)

test("schema: Get answers an interior node for a path with no row, and nil past a leaf", function()
  local S, fx = newFlat()
  assertTrue(S.Get("units.player") == fx.db.profile.units.player, "a debugging read of a node")
  assertNil(S.Get("enabled.x"))
  assertNil(S.Get(nil)); assertNil(S.Get(5))
end)

test("schema: every instance member works taken as a bare value, without self", function()
  -- The reason members are dot-called: the Options and Slash descriptors take seams as values.
  local S, fx = newFlat()
  local set, get, find, all = S.Set, S.Get, S.FindRow, S.AllRows
  assertTrue(set("scale", 1.25))
  assertEqual(get("scale"), 1.25)
  assertTrue(find("scale") == rowAt(fx, "scale"))
  assertTrue(all() == fx.rows)
  local begin, finish, apply = S.BulkBegin, S.BulkEnd, S.ApplyDefault
  begin("reset", "all"); apply(rowAt(fx, "scale")); finish("reset", "all", 0)
  assertEqual(fx.db.profile.scale, 1)
  local validate, count = S.Validate, S.CountOffDefault
  assertEqual(count(), 0)
  assertEqual((validate()), 0)
end)

-- ── defaults ────────────────────────────────────────────────────────────────────────────────

test("schema: Default is a deep copy and nil for an unknown path", function()
  local S, fx = newFlat()
  local d = S.Default("color")
  assertEqual(d.r, 1)
  d.r = 0
  assertEqual(rowAt(fx, "color").default.r, 1, "the schema's own default is untouched")
  assertTrue(S.Default("color") ~= rowAt(fx, "color").default)
  assertNil(S.Default("nope"))
  assertNil(S.Default(nil))
end)

test("schema: ApplyDefault writes through Set, and refuses a row with nothing to restore", function()
  local S, fx = newFlat()
  S.Set("scale", 1.5)
  fx.rec.log = {}
  assertTrue(S.ApplyDefault(rowAt(fx, "scale")))
  assertEqual(fx.db.profile.scale, 1)
  assertEqual(fx.rec.joined(), "debug,onChange:scale,announce:scale", "one line, one reaction")

  fx.rec.log = {}
  local nodefault = { path = "scale" }
  assertFalse(S.ApplyDefault(nodefault), "default == nil means no restore (JC-5)")
  assertFalse(S.ApplyDefault("scale"), "not a table")
  assertFalse(S.ApplyDefault({ default = 1 }), "no path")
  assertEqual(fx.rec.joined(), "", "nothing written for any of them")
  local ok, err = S.ApplyDefault({ path = "unknown", default = 1 })
  assertFalse(ok); assertEqual(err, "Setting not found: unknown", "Set's own answer")
end)

test("schema: ApplyDefault's table default is stored as a copy", function()
  local S, fx = newFlat()
  S.Set("color", { r = 0, g = 0, b = 0, a = 1 })
  S.ApplyDefault(rowAt(fx, "color"))
  assertTrue(fx.db.profile.color ~= rowAt(fx, "color").default, "no alias into the schema")
  assertTrue(Schema.SameValue(fx.db.profile.color, rowAt(fx, "color").default))
end)

test("schema: resetExempt vetoes a sweep inside a bracket and not a named reset outside one", function()
  -- red under: honoring resetExempt outside a bracket (a named /x reset minimap must work)
  local S, fx = newFlat({ resetExempt = { minimap = true } })
  S.Set("minimap", false)
  S.BulkBegin("reset", "all")
  assertFalse(S.ApplyDefault(rowAt(fx, "minimap")), "a sweep does not touch it")
  S.BulkEnd("reset", "all", 0)
  assertEqual(S.Get("minimap"), false)
  assertTrue(S.ApplyDefault(rowAt(fx, "minimap")), "a named reset does")
  assertEqual(S.Get("minimap"), true)
end)

-- ── the bulk bracket ────────────────────────────────────────────────────────────────────────

test("schema: a bracket mutes per-row lines and closes with one line counting changed rows", function()
  local S, fx = newFlat()
  S.Set("scale", 1.5)
  S.Set("enabled", false)
  fx.rec.debugLines = {}
  S.BulkBegin("reset", "all")
  assertTrue(S.InBulk())
  for _, row in ipairs(fx.rows) do S.ApplyDefault(row) end
  assertEqual(#fx.rec.debugLines, 0, "no per-row line while open")
  S.BulkEnd("reset", "all", 99)
  assertFalse(S.InBulk())
  -- scale and enabled moved; color, width, the console and the minimap were at their defaults. The
  -- library's count (99) is ignored. red under: `before = bulk and Get(...) or nil`, which reads the
  -- console's stored `false` as nil and counts it as a change.
  assertEqual(fx.rec.debugLines[1], "[Set] reset all: 2 rows")
  assertEqual(#fx.rec.debugLines, 1)
end)

test("schema: nested brackets are one act, one line, the outermost act and scope", function()
  local S, fx = newFlat()
  S.BulkBegin("copy", "profile")
  S.Set("scale", 1.5)
  S.BulkBegin("reset", "page")
  S.Set("enabled", false)
  S.BulkEnd("reset", "page", 0)
  assertEqual(#fx.rec.debugLines, 0, "the inner close is silent")
  S.BulkEnd("copy", "profile", 0)
  assertEqual(fx.rec.debugLines[1], "[Set] copy profile: 2 rows")
  assertEqual(#fx.rec.debugLines, 1)
end)

test("schema: a profile reset at any level silences the bracket", function()
  local S, fx = newFlat()
  S.BulkBegin("reset", "all")
  S.BulkBegin("reset", "profile")
  S.Set("scale", 1.5)
  S.BulkEnd("reset", "profile", 0, nil, { profileReset = true })
  S.BulkEnd("reset", "all", 0)
  assertEqual(#fx.rec.debugLines, 0)
end)

test("schema: an error at any level marks the line stopped", function()
  local S, fx = newFlat()
  S.BulkBegin("reset", "all")
  S.BulkBegin("reset", "page")
  S.Set("scale", 1.5)
  S.BulkEnd("reset", "page", 0, "boom")
  S.BulkEnd("reset", "all", 0)
  assertEqual(fx.rec.debugLines[1], "[Set] reset all: 1 rows (stopped by an error)")
end)

test("schema: an unpaired BulkEnd is a no-op and never drives the depth negative", function()
  local S, fx = newFlat()
  S.BulkEnd("reset", "all", 0)
  assertFalse(S.InBulk())
  assertEqual(#fx.rec.debugLines, 0, "no line")
  S.Set("scale", 1.5)
  assertEqual(fx.rec.debugLines[1], "[Set] scale = 1.5", "a later write is not muted")
  S.BulkBegin("a", "b"); S.BulkEnd("a", "b"); S.BulkEnd("a", "b")
  assertFalse(S.InBulk())
end)

test("schema: BulkRun re-raises the same error value, closes the bracket, marks the line", function()
  local S, fx = newFlat()
  local boom = { code = 7 }
  local ok, err = pcall(S.BulkRun, "reset", "all", function()
    S.Set("scale", 1.5)
    error(boom)
  end)
  assertFalse(ok)
  assertTrue(err == boom, "a table error comes back by identity")
  assertFalse(S.InBulk(), "the bracket closed")
  assertEqual(fx.rec.debugLines[1], "[Set] reset all: 1 rows (stopped by an error)")
end)

test("schema: BulkRun hands fn an info table whose profileReset silences the line", function()
  local S, fx = newFlat()
  local got
  S.BulkRun("reset", "profile", function(info)
    got = info
    S.Set("scale", 1.5)
    info.profileReset = true
  end)
  assertEqual(type(got), "table")
  assertEqual(#fx.rec.debugLines, 0)
  S.BulkRun("reset", "page", function() S.Set("scale", 1) end)
  assertEqual(fx.rec.debugLines[1], "[Set] reset page: 1 rows")
end)

test("schema: BulkAdd feeds the open bracket's tally and does nothing outside one", function()
  local S, fx = newFlat()
  S.BulkAdd(3)
  assertEqual(#fx.rec.debugLines, 0, "outside a bracket, no line")
  S.BulkBegin("import", "all")
  S.BulkAdd(3)
  S.BulkAdd("junk")
  S.Set("scale", 1.5)
  S.BulkEnd("import", "all")
  assertEqual(fx.rec.debugLines[1], "[Set] import all: 4 rows")
end)

test("schema: a closure row that stores what it already held counts 0 (read-back tally)", function()
  -- red under: tallying before-versus-argument instead of before-versus-after (JC-8)
  local S, fx = newClosure()
  fx.store.prefix = "abc"
  S.BulkBegin("reset", "all")
  S.Set("chat.color", "ff0000")                  -- clears to absence, reads back the same
  S.Set("chat.prefix", "ABC")                    -- normalizes to what it already held
  S.BulkEnd("reset", "all")
  assertEqual(fx.rec.debugLines[1], "[Set] reset all: 0 rows")
  S.BulkBegin("reset", "all")
  S.Set("chat.color", "00ff00")
  S.BulkEnd("reset", "all")
  assertEqual(fx.rec.debugLines[2], "[Set] reset all: 1 rows")
end)

test("schema: a raising onChange inside a bracket still counts the write that landed", function()
  local S, fx = newFlat()
  rowAt(fx, "scale").onChange = function() error("host blew up") end
  S.BulkBegin("reset", "all")
  pcall(S.Set, "scale", 1.5)
  S.BulkEnd("reset", "all")
  assertEqual(fx.rec.debugLines[1], "[Set] reset all: 1 rows")
end)

test("schema: the bulk line honors debugEnabled", function()
  local S, fx = newFlat({ debugEnabled = function() return false end })
  S.BulkRun("reset", "all", function() S.Set("scale", 1.5) end)
  assertEqual(#fx.rec.debugLines, 0)
end)

-- ── the profile reset's count ───────────────────────────────────────────────────────────────

test("schema: CountOffDefault counts stored rows off default and honors pred", function()
  local S, fx = newFlat()
  assertEqual(S.CountOffDefault(), 0, "a fresh store is at its defaults")
  S.Set("scale", 1.5)
  S.Set("debugConsole", true)                              -- sessionOnly: never counted
  S.Set("minimap", false)
  assertEqual(S.CountOffDefault(), 2, "scale and minimap")
  assertEqual(S.CountOffDefault(function(row) return row.path ~= "minimap" end), 1,
    "pred false excludes")
  assertEqual(S.CountOffDefault(function() return nil end), 2, "only an explicit false excludes")
  fx.rows[#fx.rows + 1] = { type = "bool", group = "g", get = function() end, set = function() end }
  fx.rows[#fx.rows + 1] = { path = "scale", default = 1 }  -- a later duplicate
  S.Reindex()
  assertEqual(S.CountOffDefault(), 2, "path-less and duplicate rows are not counted")
end)

test("schema: CountOffDefault with no root counts exactly the rows that have a default", function()
  local rows = { { path = "a", default = 1 }, { path = "b" } }
  local S = Schema:New{ rows = rows, resolveRoot = function() return nil end }
  assertEqual(S.CountOffDefault(), 1)
end)

test("schema: ResetCounted leaves the count pending for exactly one consumer", function()
  local S, fx = newFlat()
  S.Set("scale", 1.5)
  S.Set("enabled", false)
  local first, second
  S.ResetCounted(function()
    fx.db.profile = { enabled = true, scale = 1, color = { r = 1, g = 1, b = 1, a = 1 },
      units = { player = { width = 200 } } }
    first = S.ConsumeResetCount()
    second = S.ConsumeResetCount()
  end)
  assertEqual(first, 2)
  assertNil(second, "taken once")
  assertNil(S.ConsumeResetCount(), "nothing pending after the reset returns")
end)

test("schema: ResetCounted re-raises unchanged and clears the pending count", function()
  local S = newFlat()
  local boom = {}
  local ok, err = pcall(S.ResetCounted, function() error(boom) end)
  assertFalse(ok)
  assertTrue(err == boom)
  assertNil(S.ConsumeResetCount(), "a reset that never reached the handler hands nothing on")
end)

test("schema: ConsumeResetCount while a bracket is open closes it with no line", function()
  -- red under: dropping the silence in ConsumeResetCount (JC-12)
  local S, fx = newFlat()
  S.BulkBegin("reset", "all")
  S.Set("scale", 1.5)
  assertNil(S.ConsumeResetCount())
  S.BulkEnd("reset", "all")
  assertEqual(#fx.rec.debugLines, 0)
  S.BulkRun("reset", "all", function() S.Set("scale", 1) end)
  assertEqual(fx.rec.debugLines[1], "[Set] reset all: 1 rows", "the next bracket speaks again")
end)
