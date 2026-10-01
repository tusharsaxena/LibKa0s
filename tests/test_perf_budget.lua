-- tests/test_perf_budget.lua — report-only per-bucket budgets (issue #1).
--
-- A host declares `budget = { msPerSec = <n>, maxMs = <n> }` on a bucket in its descriptor. The
-- library validates it, copies it onto that bucket in the record, and reports each budgeted bucket
-- as `ok`, `OVER` or `not exercised`. Nothing gates: no refusal, no error, no exit code. A host
-- that declares no budget gets the report it always got, byte for byte.

local T = _G.LK_TEST
local lib = T.lib
local test, assertEqual, assertTrue, assertFalse =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse
local Fixture = dofile("tests/fixture.lua")

local function latch()
  return T.lifecycle:New{ name = "X", standDown = function() end, standUp = function() end }
end

local function newWith(buckets)
  return function()
    return lib:New({ name = "X", sv = "XDB", buckets = buckets, lifecycle = latch() })
  end
end

-- Outer is budgeted on both axes, inner on ms/s only, idle on max ms only; flat has no budget.
local function budgetedHost()
  return Fixture.new({ buckets = {
    { key = "outer", budget = { msPerSec = 1, maxMs = 5 } },
    { key = "inner", within = "outer", budget = { msPerSec = 0.5 } },
    { key = "idle",  budget = { maxMs = 2 } },
    { key = "flat" },
  } })
end

-- Ten active seconds, so ms/s is totalMs / 10.
local function tenSeconds(p)
  local arms = p.__fpsArms()
  arms.active.seconds, arms.active.frames = 10, 600
end

local function reportOf(p)
  return table.concat(p.FormatReport(p.BuildRecord("cap")), "\n")
end

-- The budget section is the report's last; the bucket table above it indents a nested bucket by
-- the same two spaces, so a row is looked for after the section's header and nowhere else.
local function section(lines)
  return lines:match("budget %(report%-only%)[^\n]*(.*)$")
end

local function budgetRow(lines, key)
  local body = section(lines)
  return body and body:match("\n  " .. key .. " [^\n]*")
end

-- ── the descriptor ────────────────────────────────────────────────────────────────────────────

test("budget: a malformed budget is refused in the library's own words", function()
  -- red under: a descriptor whose `budget` is never read
  local ok, err = pcall(newWith({ { key = "a", budget = "fast" } }))
  assertFalse(ok, "a budget that is not a table")
  assertTrue(tostring(err):find("descriptor.buckets[1].budget must be a table", 1, true) ~= nil,
    "framed like every other descriptor error, got: " .. tostring(err))
  ok, err = pcall(newWith({ { key = "a" }, { key = "b", budget = { msPerSec = "1" } } }))
  assertFalse(ok, "a ceiling that is not a number")
  assertTrue(tostring(err):find("descriptor.buckets[2].budget.msPerSec must be a positive number",
    1, true) ~= nil, "naming the entry and the field, got: " .. tostring(err))
  assertFalse(pcall(newWith({ { key = "a", budget = { maxMs = 0 } } })), "nor a zero ceiling")
  assertFalse(pcall(newWith({ { key = "a", budget = { maxMs = -1 } } })), "nor a negative one")
  assertFalse(pcall(newWith({ { key = "a", budget = {} } })), "nor a budget with no ceiling")
end)

test("budget: a well-formed budget is accepted, and a bucket may declare one axis", function()
  local ok = pcall(newWith({ { key = "a", budget = { msPerSec = 1.5, maxMs = 4 } },
    { key = "b", budget = { maxMs = 2 } }, { key = "c" } }))
  assertTrue(ok, "both axes, one axis, or none")
end)

-- ── the record ────────────────────────────────────────────────────────────────────────────────

test("budget: the declared budget travels onto its bucket in the record and the JSON", function()
  -- red under: BuildRecord leaving the budget behind
  local p = budgetedHost()
  p.Note("outer", 3)
  p.Note("flat", 1)
  local r = p.BuildRecord("cap")
  assertEqual(r.buckets.outer.budget.msPerSec, 1, "ms/s ceiling")
  assertEqual(r.buckets.outer.budget.maxMs, 5, "max ms ceiling")
  assertEqual(r.buckets.flat.budget, nil, "an unbudgeted bucket carries no budget key")
  assertTrue(lib.EncodeJSON(r):find('"budget":{"maxMs":5,"msPerSec":1}', 1, true) ~= nil,
    "and the encoded record carries it")
end)

test("budget: the record's budget is a copy, not the descriptor's table", function()
  local p = budgetedHost()
  p.Note("outer", 3)
  local r = p.BuildRecord("cap")
  r.buckets.outer.budget.msPerSec = 99
  assertEqual(p.BuildRecord("again").buckets.outer.budget.msPerSec, 1,
    "editing a saved record cannot move the host's ceiling")
end)

-- ── the report ────────────────────────────────────────────────────────────────────────────────

test("budget: a bucket over its ms/s ceiling and over its max ms reports OVER on both", function()
  -- red under: a report with no budget section
  local p = budgetedHost()
  tenSeconds(p)
  p.Note("outer", 6)          -- max 6 > 5
  p.Note("outer", 6)          -- 12 ms over 10 s = 1.2 ms/s > 1
  local lines = reportOf(p)
  assertTrue(lines:find("budget (report-only)", 1, true) ~= nil, "the section is there")
  local row = budgetRow(lines, "outer")
  assertTrue(row ~= nil, "outer has a budget row")
  assertTrue(row:find("OVER  ms/s 1.200 / 1.000 OVER", 1, true) ~= nil, "ms/s over, got: " .. row)
  assertTrue(row:find("max ms 6.000 / 5.000 OVER", 1, true) ~= nil, "max ms over, got: " .. row)
end)

test("budget: a bucket inside both ceilings reports ok, and one axis over reports OVER", function()
  local p = budgetedHost()
  tenSeconds(p)
  p.Note("outer", 4)          -- 0.4 ms/s, max 4: both inside
  p.Note("inner", 6)          -- 0.6 ms/s > 0.5
  local lines = reportOf(p)
  local outer = budgetRow(lines, "outer")
  assertTrue(outer:find("ok    ms/s 0.400 / 1.000 ok", 1, true) ~= nil, "got: " .. outer)
  assertTrue(outer:find("max ms 4.000 / 5.000 ok", 1, true) ~= nil, "got: " .. outer)
  local inner = budgetRow(lines, "inner")
  assertTrue(inner:find("OVER  ms/s 0.600 / 0.500 OVER", 1, true) ~= nil, "got: " .. inner)
  assertEqual(inner:find("max ms", 1, true), nil, "an axis with no ceiling is not printed")
end)

test("budget: a budgeted bucket that recorded no calls reports not exercised", function()
  local p = budgetedHost()
  tenSeconds(p)
  p.Note("inner", 1)          -- outer is emitted as inner's zero-count ancestor
  local lines = reportOf(p)
  assertTrue(budgetRow(lines, "outer"):find("not exercised", 1, true) ~= nil, "a zero-count ancestor")
  assertTrue(budgetRow(lines, "idle"):find("not exercised", 1, true) ~= nil,
    "and a bucket absent from the record")
  assertEqual(budgetRow(lines, "flat"), nil, "an unbudgeted bucket has no budget row")
end)

test("budget: a host with no budgets gets a byte-identical report", function()
  -- red under: the budget section printed whenever any bucket is declared
  local p = Fixture.new()
  tenSeconds(p)
  p.Note("outer", 4)
  p.Note("inner", 1)
  local lines = p.FormatReport(p.BuildRecord("cap"))
  for _, line in ipairs(lines) do
    assertEqual(line:find("budget", 1, true), nil, "no budget line: " .. line)
  end
  assertTrue(lines[#lines]:find("do not sum", 1, true) ~= nil, "the nesting note still ends it")
end)

test("budget: a record read back off the ring reports the budget it was built with", function()
  local p = budgetedHost()
  tenSeconds(p)
  p.Note("outer", 12)
  local r = p.BuildRecord("cap")
  r.buckets.outer.budget = { msPerSec = 2 }      -- as though the descriptor had since changed
  local lines = table.concat(p.FormatReport(r), "\n")
  local row = budgetRow(lines, "outer")
  assertTrue(row:find("ms/s 1.200 / 2.000 ok", 1, true) ~= nil, "the record's own ceiling, got: " .. row)
end)

-- ── the finish ack ────────────────────────────────────────────────────────────────────────────

test("budget: finish says how many buckets went over budget, and nothing gates", function()
  -- red under: a finish ack with no budget line
  local p, rec = budgetedHost()
  p.OnCommand("start")
  tenSeconds(p)
  p.Note("outer", 12)         -- 1.2 ms/s > 1, max 12 > 5
  p.Note("inner", 6)          -- 0.6 ms/s > 0.5
  local out = table.concat(p.OnCommand("finish"), "\n")
  assertTrue(out:find("2 bucket(s) over budget", 1, true) ~= nil, "got: " .. out)
  assertEqual(#_G.TestHostPerfDB.runs, 1, "the run was saved regardless")
  assertFalse(p.run, "and the run finished")
  assertTrue(#rec.chat > 0, "the usual acknowledgment still went out")
end)

test("budget: finish with budgets all inside says zero, and with none declared says nothing", function()
  local p = budgetedHost()
  p.OnCommand("start")
  tenSeconds(p)
  p.Note("outer", 1)
  local out = table.concat(p.OnCommand("finish"), "\n")
  assertTrue(out:find("0 bucket(s) over budget", 1, true) ~= nil, "got: " .. out)

  local plain = Fixture.new()
  plain.OnCommand("start")
  plain.Note("outer", 1)
  local quiet = table.concat(plain.OnCommand("finish"), "\n")
  assertEqual(quiet:find("budget", 1, true), nil, "an un-adopted host sees no change")
end)
