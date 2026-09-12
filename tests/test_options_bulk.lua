-- tests/test_options_bulk.lua — LibKa0s-Options-1.0's bulk bracket (Options minor 16): the optional
-- bulkBegin / bulkEnd pair that RestoreDefaults and RestoreAllDefaults call around their reset walks,
-- and the info argument bulkEnd reads to learn that an act included a whole-profile reset.
--
-- Its own suite rather than a section of tests/test_options.lua, which it would have pushed past
-- layout-§1's 1500-line cap. It peels on that file's own seam: one feature, one fixture, its own
-- helpers, and nothing in tests/test_options.lua reads anything defined here.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse
local Fixture = dofile("tests/fixture_options.lua")

-- ── the bulk bracket (Options minor 16) ────────────────────────────────────────────────────
--
-- debug-logging-§10 (standard v2.44.0): a bulk copy or reset through the settings helper is ONE
-- flow line naming the act, its scope and the row count, never one `[Set]` per row. The host's
-- write seam cannot tell a Defaults press from N single writes, so the library brackets its own
-- reset walks and the host mutes its per-row line inside the bracket.

--- A descriptor whose every call lands in one ordered trace, so a case can assert the bracket's
--- position relative to the rows, the profile reset, the after-hook and the refresh. `extra` is
--- either a table of descriptor overrides or a function of `push` returning one, so an override
--- can write into the same trace.
local function traced(extra)
  local trace = {}
  local function push(s) trace[#trace + 1] = s end
  if type(extra) == "function" then extra = extra(push) end
  local over = {
    bulkBegin = function(act, scope) push("begin:" .. act .. ":" .. tostring(scope)) end,
    bulkEnd   = function(act, scope, count, err)
      push("end:" .. act .. ":" .. tostring(scope) .. ":" .. count .. ":" .. tostring(err))
    end,
  }
  for k, v in pairs(extra or {}) do over[k] = v end
  local O, rec = Fixture.new(over)
  local plainApply = rec.d.applyDefault
  rec.d.applyDefault = function(row) push("row:" .. row.path); return plainApply(row) end
  return O, rec, trace, push
end

local function joinRows(prefix, rows, pred)
  local out = {}
  for _, row in ipairs(rows) do
    if not pred or pred(row) then out[#out + 1] = prefix .. row.path end
  end
  return out
end

test("options: RestoreDefaults brackets its page walk — begin, every row, end with the count, "
  .. "then the refresh", function()
  -- red under: RestoreDefaults not reading bulkBegin/bulkEnd at all (Options minor 15).
  local O, rec, trace, push = traced()
  local ctx = O.CreatePanel("TestPanelBK1", "Test BK1", { pageKey = "bar" })
  ctx.refreshers[1] = function() push("refresh") end
  O.RestoreDefaults("bar", ctx)

  local rows = rec.d.rowsForPage("bar")
  assertTrue(#rows > 1, "the fixture's bar page must have several rows for this to mean anything")
  local want = { "begin:reset:bar" }
  for _, s in ipairs(joinRows("row:", rows)) do want[#want + 1] = s end
  want[#want + 1] = "end:reset:bar:" .. #rows .. ":nil"
  want[#want + 1] = "refresh"
  assertEqual(table.concat(trace, ","), table.concat(want, ","))
end)

test("options: RestoreAllDefaults brackets the whole act — rows, afterRestoreAll — and refreshes "
  .. "after the end", function()
  -- The after-hook is part of the reset, so a host write it makes is inside the mute; the refresh
  -- is not a write, so it is outside. Vetoed rows are not counted: `count` is rows WRITTEN.
  -- red under: bracketing only the row loop, or counting the rows walked rather than written.
  local O, rec, trace, push = traced(function(p) return {
    skipRestoreAll  = function(row) return row.page == "bar" end,
    afterRestoreAll = function() p("hook") end,
  } end)
  local ctx = O.CreatePanel("TestPanelBK2", "Test BK2", {})
  ctx.refreshers[1] = function() push("refresh") end
  O.RestoreAllDefaults()

  local written = joinRows("row:", rec.rows, function(r) return r.page ~= "bar" end)
  local want = { "begin:reset:all" }
  for _, s in ipairs(written) do want[#want + 1] = s end
  want[#want + 1] = "hook"
  want[#want + 1] = "end:reset:all:" .. #written .. ":nil"
  want[#want + 1] = "refresh"
  assertEqual(table.concat(trace, ","), table.concat(want, ","))
end)

test("options: with resetProfile the bracket spans the session rows, the profile reset and the hook",
  function()
  -- A profile reset writes no row through the helper, so `count` is the session rows alone — the
  -- host knows it supplied resetProfile and phrases its one line accordingly.
  -- red under: resetProfile or afterRestoreAll running outside the bracket.
  local O, rec, trace = traced(function(push) return {
    resetProfile    = function() push("profile") end,
    afterRestoreAll = function() push("hook") end,
  } end)
  O.RestoreAllDefaults()
  local session = joinRows("row:", rec.rows, function(r) return r.sessionOnly end)
  assertTrue(#session >= 1, "the fixture carries a sessionOnly row")
  local want = { "begin:reset:all" }
  for _, s in ipairs(session) do want[#want + 1] = s end
  want[#want + 1] = "profile"
  want[#want + 1] = "hook"
  want[#want + 1] = "end:reset:all:" .. #session .. ":nil"
  assertEqual(table.concat(trace, ","), table.concat(want, ","))
end)

test("options: a row that raises mid-walk still closes the bracket, then the error propagates",
  function()
  -- The bracket is a host MUTE. If bulkEnd could be skipped, one corrupt row would leave the host's
  -- write seam silent for the rest of the session. So: the walk stops at the raising row (exactly
  -- as it does unbracketed), bulkEnd runs once with the rows written before it and the raised
  -- value, and then the SAME value is re-raised. The refresh does not run, as it never has after a
  -- raising row.
  -- red under: no pcall around the walk (bulkEnd skipped), or swallowing the error.
  local BOOM = setmetatable({}, { __tostring = function() return "BOOM" end })
  local O, rec, trace, push = traced()
  local rows = rec.d.rowsForPage("bar")
  local inner = rec.d.applyDefault
  rec.d.applyDefault = function(row)
    if row.path == rows[2].path then error(BOOM) end
    return inner(row)
  end
  local ctx = O.CreatePanel("TestPanelBK3", "Test BK3", { pageKey = "bar" })
  ctx.refreshers[1] = function() push("refresh") end

  local ok, err = pcall(O.RestoreDefaults, "bar", ctx)
  assertFalse(ok, "the error must still propagate")
  assertTrue(rawequal(err, BOOM), "and it is the very value the row raised, not a re-wrapped one")
  assertEqual(table.concat(trace, ","),
    "begin:reset:bar,row:" .. rows[1].path .. ",end:reset:bar:1:BOOM",
    "one row written, the walk stopped, the bracket closed with that count, no refresh")
end)

test("options: the bracket closes when afterRestoreAll or bulkBegin itself raises", function()
  -- Every raise inside the act is covered, not only a row's: the hook and the profile reset run
  -- inside the bracket, and so does bulkBegin — a host that set its mute flag and then raised must
  -- still get its bulkEnd.
  -- red under: calling bulkBegin outside the protected region.
  local O, _, trace = traced{ afterRestoreAll = function() error("hook down", 0) end }
  local ok, err = pcall(O.RestoreAllDefaults)
  assertFalse(ok)
  assertEqual(err, "hook down")
  assertTrue(trace[#trace]:find("^end:reset:all:%d+:hook down$") ~= nil, trace[#trace])

  local ended
  local O2 = Fixture.new{
    bulkBegin = function() error("begin down", 0) end,
    bulkEnd   = function(_, _, count, e) ended = count .. ":" .. tostring(e) end,
  }
  local ok2, err2 = pcall(O2.RestoreDefaults, "bar")
  assertFalse(ok2)
  assertEqual(err2, "begin down")
  assertEqual(ended, "0:begin down", "no row was written, and bulkEnd still ran")
end)

test("options: either half of the bracket works alone", function()
  local counted
  local O, rec = Fixture.new{ bulkEnd = function(_, _, n) counted = n end }
  O.RestoreDefaults("bar")
  assertEqual(counted, #rec.d.rowsForPage("bar"), "bulkEnd alone still gets the count")

  local begun = 0
  local O2, rec2 = Fixture.new{ bulkBegin = function() begun = begun + 1 end }
  rec2.store.barWidth = 333
  O2.RestoreDefaults("bar")
  assertEqual(begun, 1)
  assertEqual(rec2.store.barWidth, 200, "and the rows are still reset")
end)

--- The documented host (docs/api/Options/version-16.15.4.3-docs.md, "Worked example"), built for
--- real: a single write seam that logs one `[Set]` per write, muted by a bulk depth, and a bulkEnd
--- that emits `[Set] <act> <scope>: N rows` — unless `info.profileReset` says the act included a
--- whole-profile reset, whose one line is the profile-event handler's (debug-logging-§10, standard
--- v2.44.0, 7883278). `extra(h)` returns descriptor overrides that can write into the same log.
local function seamHost(extra)
  local h = { log = {}, depth = 0, store = {} }
  function h.Set(path, value)                    -- the host's single write seam
    h.store[path] = value
    if h.depth == 0 then h.log[#h.log + 1] = ("[Set] %s = %s"):format(path, tostring(value)) end
  end
  local over = {
    set       = function(path, v) h.Set(path, v) end,
    bulkBegin = function() h.depth = h.depth + 1 end,
    bulkEnd   = function(act, scope, count, err, info)
      h.depth, h.count, h.err, h.info = h.depth - 1, count, err, info
      if info.profileReset then return end     -- the profile handler already logged the reset
      h.log[#h.log + 1] = ("[Set] %s %s: %d rows"):format(act, tostring(scope), count)
    end,
  }
  for k, v in pairs(extra and extra(h) or {}) do over[k] = v end
  local O, rec = Fixture.new(over)
  rec.d.applyDefault = function(row) h.Set(row.path, row.default) end
  return O, rec, h
end

test("options: a host mutes its seam's [Set] inside the bracket and logs ONE line — the documented "
  .. "worked example, a page reset", function()
  -- red under: bulkEnd called without its info argument (the host reads info.profileReset).
  local O, rec, h = seamHost()
  O.RestoreDefaults("bar")
  local n = #rec.d.rowsForPage("bar")
  assertEqual(table.concat(h.log, " | "), ("[Set] reset bar: %d rows"):format(n),
    "one line for the whole reset")
  assertEqual(h.depth, 0, "the mute is released")
  assertEqual(h.store.barWidth, 200, "and every row still went through the seam")
  assertFalse(h.info.profileReset, "a page reset is never a profile reset")

  rec.d.set("barWidth", 250)                     -- a plain write after the reset
  assertEqual(h.log[2], "[Set] barWidth = 250", "and the seam logs per write again")
end)

test("options: a profile-reset RestoreAllDefaults is ONE line, the profile handler's — bulkEnd's "
  .. "info says so and the host adds nothing", function()
  -- debug-logging-§10's final ruling: a profile-wide reset is logged once, by the host's
  -- profile-event handler, and no bulk bracket adds a second line. The session rows the library
  -- walks one by one are still muted, so the reset reads as exactly one line.
  -- red under: bulkEnd without info, or info.profileReset false after resetProfile returned.
  local O, rec, h = seamHost(function(h)
    return { resetProfile = function()          -- stands in for db:ResetProfile() → OnProfileReset
      h.log[#h.log + 1] = "[Set] reset profile 'Default' to defaults (12 rows)"
    end }
  end)
  O.RestoreAllDefaults()
  local session = 0
  for _, row in ipairs(rec.rows) do if row.sessionOnly then session = session + 1 end end
  assertEqual(table.concat(h.log, " | "), "[Set] reset profile 'Default' to defaults (12 rows)")
  assertTrue(h.info.profileReset, "bulkEnd was told the act included a whole-profile reset")
  assertEqual(h.count, session, "and the count is still the session rows actually written")
  assertEqual(h.depth, 0)
end)

test("options: without resetProfile, RestoreAllDefaults' info.profileReset is false and the host "
  .. "logs [Set] reset all: N rows, N the rows actually written", function()
  -- red under: bulkEnd without info, or counting rows in scope rather than rows written.
  local O, rec, h = seamHost(function()
    return { skipRestoreAll = function(row) return row.page == "bar" end }
  end)
  O.RestoreAllDefaults()
  local written = 0
  for _, row in ipairs(rec.rows) do if row.page ~= "bar" then written = written + 1 end end
  assertTrue(written < #rec.rows, "the veto must take rows out of the count for this to mean anything")
  assertEqual(table.concat(h.log, " | "), ("[Set] reset all: %d rows"):format(written))
  assertFalse(h.info.profileReset)
end)

test("options: a resetProfile that raises leaves info.profileReset false and hands bulkEnd the "
  .. "error", function()
  -- profileReset means the profile reset COMPLETED, so the host may rely on its handler's line. A
  -- reset that raised may never have reached the handler, so the host must still be told to log.
  -- red under: setting the flag before calling resetProfile.
  local O, _, h = seamHost(function()
    return { resetProfile = function() error("db down", 0) end }
  end)
  local ok, err = pcall(O.RestoreAllDefaults)
  assertFalse(ok)
  assertEqual(err, "db down")
  assertEqual(h.err, "db down")
  assertFalse(h.info.profileReset, "the reset did not complete, so the host still logs")
  assertEqual(h.depth, 0)
end)

test("options: with NO bracket the walk is exactly minor 15's — same calls, same order, and an "
  .. "error escapes with its own stack", function()
  -- The compatibility half. A host that supplies neither field must see the identical call
  -- sequence, and a raising row must not pass through a pcall: the traceback taken at the raise
  -- point still runs through the row's own frame, which a caught-and-re-raised error loses.
  -- red under: routing the unbracketed walk through the pcall too.
  local seen = {}
  local O, rec = Fixture.new()
  local inner = rec.d.applyDefault
  rec.d.applyDefault = function(row) seen[#seen + 1] = row.path; return inner(row) end
  O.RestoreDefaults("bar")
  assertEqual(table.concat(seen, ","), table.concat(joinRows("", rec.d.rowsForPage("bar")), ","))
  seen = {}
  O.RestoreAllDefaults()
  assertEqual(table.concat(seen, ","), table.concat(joinRows("", rec.rows), ","))

  local raiseLine
  rec.d.applyDefault = function()
    raiseLine = debug.getinfo(1, "l").currentline; error("row down")
  end
  local ok, tb = xpcall(function() O.RestoreDefaults("bar") end, debug.traceback)
  assertFalse(ok)
  assertTrue(tb:find("test_options_bulk.lua:" .. raiseLine .. ": row down", 1, true) ~= nil,
    "the message is the row's own: " .. tb)
  assertTrue(select(2, tb:gsub("test_options_bulk.lua:" .. raiseLine .. ":", "")) >= 2,
    "and the stack still holds the row's frame, not a re-raise site: " .. tb)
end)

