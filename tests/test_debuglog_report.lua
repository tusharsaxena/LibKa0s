-- tests/test_debuglog_report.lua — LibKa0s-DebugLog-1.0's report seam (DebugLogDiagnostics.lua,
-- minor 11; LibKa0s#79, LK-79 of Ka0sAddonsCommonTasks docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS):
-- `D:Report(tag, title, fn)` and the table serializer, `D:Serialize(value, opts)` and
-- `lib.Serialize(value, opts)`.
--
-- The owner's ruling of 2026-11-08 is what is pinned: a report (a dump or list a player asks for)
-- goes to the debug console whether or not trace logging is on, the console opens if it is hidden,
-- chat gets exactly one pointer line, and a refusal (a body that writes nothing) writes no report.
-- The library's own calls on top of the ruling (design §3.5): a raising body costs one line and
-- still points (D2), a report never turns logging on (D7), and the pointer counts the header (D8).
--
-- The plain-text Copy buffer the report's colored lines rely on is tests/test_debuglog_plain.lua's.

local T = _G.LK_TEST
local debuglog, mocks = T.debuglog, T.mocks
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse

-- The same stand-in for a combat secret tests/test_debuglog.lua uses: `..` succeeds on it and
-- table.concat raises, which is the pair of behaviors Core's SafeToString probes for.
local secretMock = setmetatable({}, { __concat = function() return "secret-propagated" end })

local POINTER = "%s: %d lines written to the debug console. Use Copy to share it."

local function newLog(overrides)
  local rec = { chat = {}, enabled = false, sets = 0 }
  local d = {
    name       = "ReportTest",
    title      = "Report Test",
    font       = "Interface\\Fonts\\FRIZQT__.TTF",
    slash      = "/th",
    isEnabled  = function() return rec.enabled end,
    setEnabled = function(v) rec.enabled = v; rec.sets = rec.sets + 1 end,
    print      = function(line) rec.chat[#rec.chat + 1] = line end,
  }
  for k, v in pairs(overrides or {}) do d[k] = v end
  return debuglog:New(d), rec
end

--- The message of each buffered line from `first` on: "<ts> | [<tag>] <msg>" -> "[<tag>] <msg>".
local function tail(D, first)
  local out = {}
  for i = first or 1, #D.buffer do out[#out + 1] = (D.buffer[i]:match("^.- | (.*)$")) end
  return out
end

--- A body that writes each of `lines` through `out`.
local function body(lines)
  return function(out) for _, l in ipairs(lines) do out(l) end end
end

--- Run `fn` with the client's `issecretvalue` answering `probe`, then put back what was there.
local function withSecretProbe(probe, fn)
  local before = rawget(mocks, "issecretvalue")
  mocks.issecretvalue = probe
  local ok, err = pcall(fn)
  mocks.issecretvalue = before
  if not ok then error(err, 0) end
end

-- ── the string and the file ────────────────────────────────────────────────────────────────

test("report: the pointer string is pinned, and Report and Serialize are on every instance", function()
  assertEqual(debuglog.STRINGS.REPORT_WRITTEN, POINTER)
  assertEqual(debuglog.MODULES.DebugLogDiagnostics, 12)
  local D = newLog()
  assertEqual(type(D.Report), "function", "D:Report")
  assertEqual(type(D.Serialize), "function", "D:Serialize")
  assertEqual(type(debuglog.Serialize), "function", "lib.Serialize")
end)

-- ── what a report writes ───────────────────────────────────────────────────────────────────

test("report: lands with logging off, under its tag, after a /<slash> <title> header", function()
  local D, rec = newLog()
  local n = D:Report("Dump", "dump bags", body{ "a", "b" })
  assertEqual(n, 3, "the header and two body lines")
  assertEqual(table.concat(tail(D), "\n"), "[Dump] /th dump bags\n[Dump] a\n[Dump] b")
  assertFalse(rec.enabled, "logging stays off")
  assertEqual(rec.sets, 0, "and the flag was never written")
end)

test("report: never turns logging off either, and never clears the console", function()
  local D, rec = newLog()
  rec.enabled = true
  D:Add("Trace", "before the report")
  D:Report("Dump", "dump bags", body{ "a" })
  assertTrue(rec.enabled, "logging stays on")
  assertEqual(rec.sets, 0)
  assertEqual(tail(D)[1], "[Trace] before the report", "the trace above it is kept")
end)

test("report: with no slash the header is the title alone", function()
  local D = newLog{ slash = "" }
  D:Report("Dump", "dump bags", body{ "a" })
  assertEqual(tail(D)[1], "[Dump] dump bags")
end)

test("report: a tag that is not a string reports as [Report]", function()
  local D = newLog()
  D:Report(nil, "dump bags", body{ "a" })
  assertEqual(tail(D)[1], "[Report] /th dump bags")
end)

test("report: reveals a hidden console and leaves a shown one shown", function()
  local D = newLog()
  assertFalse(D:IsShown())
  D:Report("Dump", "dump bags", body{ "a" })
  assertTrue(D:IsShown(), "revealed")
  D:Report("Dump", "dump bags", body{ "a" })
  assertTrue(D:IsShown(), "and not toggled shut by a second report")
end)

test("report: prints exactly one pointer line, naming the title and counting the header", function()
  local D, rec = newLog()
  D:Report("Dump", "dump bags", body{ "a", "b" })
  assertEqual(#rec.chat, 1, "one chat line")
  assertEqual(rec.chat[1], POINTER:format("dump bags", 3))
end)

test("report: the pointer is the host's through d.L", function()
  local D, rec = newLog{ L = { REPORT_WRITTEN = "%s -> %d" } }
  D:Report("Dump", "dump bags", body{ "a" })
  assertEqual(rec.chat[1], "dump bags -> 2")
end)

test("report: repaints once, not once per line", function()
  local D = newLog()
  D:Show()
  local paints = 0
  local update = D.UpdateStatus
  D.UpdateStatus = function(self) paints = paints + 1; return update(self) end
  D:Report("Dump", "dump bags", body{ "a", "b", "c", "d" })
  D.UpdateStatus = update
  assertEqual(paints, 1)
end)

-- ── refusals and raises ────────────────────────────────────────────────────────────────────

test("report: a body that writes nothing writes no report, prints nothing and opens nothing", function()
  local D, rec = newLog()
  D:Add("Trace", "x")
  local before = D:BufferSize()
  local n = D:Report("Dump", "dump item", function() end)
  assertEqual(n, 0)
  assertEqual(D:BufferSize(), before, "no header either")
  assertEqual(#rec.chat, 0, "no pointer")
  assertFalse(D:IsShown(), "the console stays hidden")
end)

test("report: a body that is not a function writes nothing", function()
  local D, rec = newLog()
  assertEqual(D:Report("Dump", "dump item", nil), 0)
  assertEqual(D:BufferSize(), 0)
  assertEqual(#rec.chat, 0)
end)

test("report: a raising body writes what it collected and one failure line, and still points", function()
  local D, rec = newLog()
  local n = D:Report("Dump", "dump bags", function(out) out("one"); error("boom", 0) end)
  assertEqual(n, 3, "header, the collected line, the failure line")
  local t = tail(D)
  assertEqual(t[2], "[Dump] one")
  assertEqual(t[3], "[Dump] dump bags failed: boom")
  assertEqual(#rec.chat, 1)
  assertEqual(rec.chat[1], POINTER:format("dump bags", 3))
  assertTrue(D:IsShown())
end)

test("report: a body that raises before writing still reports the failure", function()
  local D, rec = newLog()
  local n = D:Report("Dump", "dump bags", function() error("early", 0) end)
  assertEqual(n, 2)
  assertEqual(tail(D)[2], "[Dump] dump bags failed: early")
  assertEqual(#rec.chat, 1)
end)

test("report: a secret body line renders the sentinel and raises nothing", function()
  local D = newLog()
  local ok = pcall(function() D:Report("Dump", "dump bags", body{ secretMock }) end)
  assertTrue(ok, "no raise")
  assertEqual(tail(D)[2], "[Dump] <secret>")
end)

test("report: capped at the diagnostics cap, with one truncated line", function()
  local D, rec = newLog()
  local many = {}
  for i = 1, 2000 do many[i] = "line " .. i end
  local n = D:Report("Dump", "dump all", body(many))
  local cap = math.min(debuglog.DIAG_MAX_LINES, debuglog.MAX_BUFFER - 100)
  assertEqual(n, cap, "the cap, header and truncated line included")
  local t = tail(D)
  assertEqual(#t, cap)
  assertEqual(t[#t], ("[Dump] dump all truncated: %d line(s) omitted"):format(2000 - (cap - 2)))
  assertEqual(rec.chat[1], POINTER:format("dump all", cap))
end)

test("report: a capped raising body keeps its failure line", function()
  local D = newLog()
  local n = D:Report("Dump", "dump all", function(out)
    for i = 1, 2000 do out("line " .. i) end
    error("late", 0)
  end)
  local cap = math.min(debuglog.DIAG_MAX_LINES, debuglog.MAX_BUFFER - 100)
  assertEqual(n, cap)
  local t = tail(D)
  assertTrue(t[#t - 1]:find("truncated", 1, true) ~= nil, "the truncated line: " .. t[#t - 1])
  assertEqual(t[#t], "[Dump] dump all failed: late")
end)

-- ── the serializer ─────────────────────────────────────────────────────────────────────────

test("serialize: sorts keys, indents nested tables and marks a cycle (ConsumableMaster's case)", function()
  local D = newLog()
  local cyc = { name = "loop" }
  cyc.self = cyc
  local lines, truncated = D:Serialize({
    b = "two\nlines", a = 1, [2] = true, [1] = { z = {}, y = 3 }, c = cyc, f = print,
  })
  assertFalse(truncated)
  assertEqual(table.concat(lines, "\n"), table.concat({
    "  [1] = {",
    "    y = 3",
    "    z = {}",
    "  }",
    "  [2] = true",
    "  a = 1",
    '  b = "two\\nlines"',
    "  c = {",
    '    name = "loop"',
    "    self = <cycle>",
    "  }",
    "  f = <function>",
  }, "\n"))
end)

test("serialize: writes nothing to the console or to chat", function()
  local D, rec = newLog()
  D:Serialize({ a = 1 })
  assertEqual(D:BufferSize(), 0)
  assertEqual(#rec.chat, 0)
end)

test("serialize: a table shared by two branches renders under both", function()
  local shared = { x = 1 }
  local lines = debuglog.Serialize({ p = shared, q = shared })
  assertEqual(table.concat(lines, "\n"), "  p = {\n    x = 1\n  }\n  q = {\n    x = 1\n  }")
end)

test("serialize: numbers first, then strings, then every other key; odd strings bracketed", function()
  local lines = debuglog.Serialize({ [true] = 1, [1] = 2, x = 3, ["two words"] = 4 })
  assertEqual(table.concat(lines, "\n"), '  [1] = 2\n  ["two words"] = 4\n  x = 3\n  [true] = 1')
end)

test("serialize: a scalar, an empty table and an indent of the caller's", function()
  assertEqual(debuglog.Serialize(42)[1], "  42")
  assertEqual(debuglog.Serialize("hi")[1], '  "hi"')
  assertEqual(debuglog.Serialize({})[1], "  {}")
  assertEqual(#debuglog.Serialize({}), 1)
  assertEqual(table.concat(debuglog.Serialize({ a = { b = 1 } }, { indent = "" }), "\n"),
    "a = {\n  b = 1\n}")
end)

test("serialize: a huge table stops at the line cap and says so", function()
  local big = {}
  for i = 1, 1000 do big[i] = i end
  local lines, truncated = debuglog.Serialize(big)
  assertTrue(truncated)
  assertEqual(#lines, 401, "400 lines and the truncated line")
  assertEqual(lines[#lines], "  ... truncated at 400 lines")
  local few = debuglog.Serialize(big, { maxLines = 5 })
  assertEqual(#few, 6)
  assertEqual(few[6], "  ... truncated at 5 lines")
end)

test("serialize: nesting past the depth cap reads {...}", function()
  local deep = {}
  local at = deep
  for _ = 1, 8 do at.a = {}; at = at.a end
  at.leaf = 1
  local lines = debuglog.Serialize(deep)
  local opens, capped = 0, 0
  for _, l in ipairs(lines) do
    if l:match("= {$") then opens = opens + 1 end
    if l:match("= {%.%.%.}$") then capped = capped + 1 end
  end
  assertEqual(opens, 5, "five levels open below the top")
  assertEqual(capped, 1, "and the sixth is elided")
  assertEqual(#debuglog.Serialize(deep, { maxDepth = 2 }), 3, "a {, a {...} and a }")
end)

test("serialize: sort = false walks the table in its own order", function()
  local t = { a = 1, b = 2, c = 3 }
  local want = {}
  for k, v in next, t do want[#want + 1] = ("  %s = %d"):format(k, v) end
  assertEqual(table.concat(debuglog.Serialize(t, { sort = false }), "\n"), table.concat(want, "\n"))
end)

test("serialize: a secret value or table renders the sentinel and is never inspected", function()
  local hiddenTable = setmetatable({}, { __index = function() error("indexed a secret table") end })
  rawset(hiddenTable, 1, "never shown")
  withSecretProbe(function(v) return v == "hidden" or v == hiddenTable end, function()
    local lines = debuglog.Serialize({ name = "hidden", t = hiddenTable })
    assertEqual(table.concat(lines, "\n"), "  name = <secret>\n  t = <secret>")
    assertEqual(debuglog.Serialize(hiddenTable)[1], "  <secret>", "a secret table at the top")
  end)
end)

test("serialize: a secret key renders the sentinel, sorted after every readable key", function()
  withSecretProbe(function(v) return v == 7 or v == "hidden" end, function()
    assertEqual(table.concat(debuglog.Serialize({ [7] = "n", a = 1 }), "\n"),
      '  a = 1\n  [<secret>] = "n"')
    assertEqual(debuglog.Serialize({ hidden = 1 })[1], "  [<secret>] = 1")
  end)
end)

test("serialize: a probe that raises counts as a secret", function()
  withSecretProbe(function(v) if v == "odd" then error("probe") end return false end, function()
    assertEqual(debuglog.Serialize({ k = "odd" })[1], "  k = <secret>")
  end)
end)

test("serialize: a concat-hostile table is walked rawly and raises nothing", function()
  local ok, lines = pcall(debuglog.Serialize, { n = secretMock })
  assertTrue(ok)
  assertEqual(lines[1], "  n = {}")
end)

test("serialize: a raise inside the walk keeps the lines so far and says it failed", function()
  local D = newLog{ safeToString = function(v)
    if v == 13 then error("bad value", 0) end
    return tostring(v)
  end }
  local lines = D:Serialize({ a = 1, b = 13 })
  assertEqual(lines[1], "  a = 1")
  assertEqual(lines[2], "  <serialize failed: bad value>")
  assertEqual(#lines, 2)
end)

test("serialize: the instance's stringifier renders the values, the library's renders them bare",
  function()
    local D = newLog{ safeToString = function(v) return "<" .. tostring(v) .. ">" end }
    assertEqual(D:Serialize({ a = 1 })[1], "  a = <1>")
    assertEqual(debuglog.Serialize({ a = 1 })[1], "  a = 1")
  end)

test("serialize: composes with a report's out", function()
  local D = newLog()
  local n = D:Report("Dump", "dump t", function(out)
    for _, l in ipairs(D:Serialize({ a = 1, b = { c = true } })) do out(l) end
  end)
  assertEqual(n, 5)
  assertEqual(table.concat(tail(D), "\n"),
    "[Dump] /th dump t\n[Dump]   a = 1\n[Dump]   b = {\n[Dump]     c = true\n[Dump]   }")
end)
