-- tests/test_debuglog_diagnostics.lua — LibKa0s-DebugLog-1.0's diagnostics report
-- (DebugLogDiagnostics.lua, minor 1): RunDiagnostics, BuildDiagnostics, the `out` writer a section
-- is handed, and DebugVerb.
--
-- The dispatcher-facing half of the contract (both slash forms, while disabled, `debug diag` not
-- running it) is the kit's shared case, testkit/test_diagnostics_contract.lua, which this repo
-- runs against the fixture host in tests/fixture_diagnostics.lua. What is here is the library's
-- own half: what one report writes, and what it never does.

local T = _G.LK_TEST
local debuglog, mocks = T.debuglog, T.mocks
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse

-- The same stand-in for a combat secret tests/test_debuglog.lua uses: `..` succeeds on it and
-- table.concat raises, which is the pair of behaviors Core's SafeToString probes for.
local secretMock = setmetatable({}, { __concat = function() return "secret-propagated" end })

local function newLog(overrides)
  local rec = { chat = {}, enabled = false, sets = 0, sections = nil }
  local d = {
    name       = "DiagTest",
    title      = "Diag Test",
    brandName  = "Ka0s Diag Test",
    font       = "Interface\\Fonts\\FRIZQT__.TTF",
    isEnabled  = function() return rec.enabled end,
    setEnabled = function(v) rec.enabled = v; rec.sets = rec.sets + 1 end,
    print      = function(line) rec.chat[#rec.chat + 1] = line end,
    initSummary = function() return "Diag Test v1.0.0, schema 3" end,
    diagnostics = function() return rec.sections or {} end,
  }
  for k, v in pairs(overrides or {}) do d[k] = v end
  return debuglog:New(d), rec
end

--- The report's message texts, in order.
local function texts(report)
  local out = {}
  for i, line in ipairs(report.lines) do out[i] = line[2] end
  return out
end

--- A section that writes `n` numbered lines.
local function many(n)
  return function(out)
    for i = 1, n do out:add("Many", "line %s", i) end
  end
end

local function has(list, needle)
  for _, s in ipairs(list) do
    if s:find(needle, 1, true) then return true end
  end
  return false
end

-- ── the constants ──────────────────────────────────────────────────────────────────────────

test("diag: the caps are pinned as literals, and the file registers under the major", function()
  -- Literals on purpose: these are the numbers the standard and every consumer's docs cite.
  assertEqual(debuglog.DIAG_MAX_LINES, 1200)
  assertEqual(debuglog.DIAG_MAX_PER_LIST, 40)
  assertEqual(debuglog.MODULES.DebugLogDiagnostics, 1)
  assertEqual(debuglog.__diagShellMinor, debuglog.MINOR, "paired on the live shell")
  assertEqual(debuglog.STRINGS.DIAG_WRITTEN,
    "Diagnostic report written to the debug console: %d lines. Use Copy to share it.")
end)

-- ── the markers and the header ─────────────────────────────────────────────────────────────

test("diag: both markers carry the brand, and the end marker counts every line", function()
  local D = newLog()
  local r = D:BuildDiagnostics()
  local t = texts(r)
  assertEqual(t[1], "==== Ka0s Diag Test diagnostics begin ====")
  assertEqual(t[#t], ("==== Ka0s Diag Test diagnostics end: %d line(s) ===="):format(#t))
  for _, line in ipairs(r.lines) do assertEqual(line[1], "Diag", "the header lines are [Diag]") end
end)

test("diag: with no brandName the markers name the title", function()
  local D = newLog{ brandName = "" }
  local t = texts(D:BuildDiagnostics())
  assertEqual(t[1], "==== Diag Test diagnostics begin ====")
end)

test("diag: the identity header names the host, the client, the flags and the running minors",
  function()
    local D = newLog()
    local t = texts(D:BuildDiagnostics())
    assertEqual(t[2], "Diag Test v1.0.0, schema 3", "the host's initSummary comes first")
    assertTrue(has(t, "client: version=12.0.7 build=60000"), "GetBuildInfo, read")
    assertTrue(has(t, "interface=120007"), "the interface number")
    assertTrue(has(t, "locale: enUS"), "GetLocale")
    assertTrue(has(t, "debug logging: off"), "the flag, printed")
    assertTrue(has(t, "combat: InCombatLockdown=false UnitAffectingCombat=false"), "both reads")
    assertTrue(has(t, "LibKa0s running: "), "the running minors")
    assertTrue(has(t, "DebugLogDiagnostics 1"), "this file among them")
    assertTrue(has(t, "DebugLog " .. debuglog.MINOR), "and its shell")
  end)

test("diag: a combat read that raises prints unreadable and costs nothing else", function()
  local saved = mocks.InCombatLockdown
  mocks.InCombatLockdown = function() error("protected") end
  local ok, err = pcall(function()
    local D = newLog()
    local t = texts(D:BuildDiagnostics())
    assertTrue(has(t, "combat: InCombatLockdown=unreadable UnitAffectingCombat=false"),
      "the one read is marked, the other still read")
    assertFalse(has(t, "section identity failed"), "the header did not fall over")
  end)
  mocks.InCombatLockdown = saved
  if not ok then error(err, 0) end
end)

-- ── what the report never does ─────────────────────────────────────────────────────────────

test("diag: BuildDiagnostics writes nothing", function()
  local D, rec = newLog()
  D:Add("Trace", "before")
  D:BuildDiagnostics()
  assertEqual(#D.buffer, 1, "the buffer is untouched")
  assertEqual(#rec.chat, 0, "and nothing reached chat")
end)

test("diag: the report appends, and the trace before it survives", function()
  local D = newLog()
  D:Add("Trace", "reproduced the bug")
  local n = D:RunDiagnostics()
  -- red under: a report that calls Clear() before it writes
  assertTrue(D.buffer[1]:find("[Trace] reproduced the bug", 1, true) ~= nil, "the trace is first")
  assertEqual(#D.buffer, n + 1, "and the report follows it")
  assertTrue(D.buffer[2]:find("[Diag] ==== Ka0s Diag Test diagnostics begin ====", 1, true) ~= nil)
end)

test("diag: the report never calls Clear", function()
  local D = newLog()
  local cleared = 0
  local real = D.Clear
  D.Clear = function(...) cleared = cleared + 1; return real(...) end
  D:RunDiagnostics()
  assertEqual(cleared, 0)
end)

test("diag: the report is ungated: it lands with logging off and leaves the flag alone", function()
  local D, rec = newLog()
  rec.enabled = false
  local n = D:RunDiagnostics()
  -- red under: a report written through the gated D.Debug sink
  assertTrue(n > 2, "lines landed")
  assertEqual(#D.buffer, n)
  assertFalse(rec.enabled, "the flag is still off")
  assertEqual(rec.sets, 0, "and setEnabled was never called")
end)

-- ── what the report does ───────────────────────────────────────────────────────────────────

test("diag: RunDiagnostics prints one chat line with the count and returns it", function()
  local D, rec = newLog()
  local n = D:RunDiagnostics()
  assertEqual(#rec.chat, 1)
  assertEqual(rec.chat[1], ("Diagnostic report written to the debug console: %d lines. "
    .. "Use Copy to share it."):format(n))
  assertEqual(type(n), "number")
end)

test("diag: the chat line is the host's when L overrides it", function()
  local D, rec = newLog{ L = { DIAG_WRITTEN = "report: %d" } }
  local n = D:RunDiagnostics()
  assertEqual(rec.chat[1], "report: " .. n)
end)

test("diag: RunDiagnostics shows a hidden console", function()
  local D = newLog()
  assertFalse(D:IsShown(), "hidden before")
  D:RunDiagnostics()
  assertTrue(D:IsShown(), "shown after")
end)

test("diag: the report repaints once, not once per line", function()
  local D, rec = newLog()
  rec.sections = { { "many", many(50) } }
  -- The console is built first: building it paints its status line once, and that paint belongs to
  -- the window, not to the report.
  D:Add("Trace", "console built")
  local statuses, bars = 0, 0
  local realStatus, realBar = D.UpdateStatus, D.UpdateScrollBar
  D.UpdateStatus = function(...) statuses = statuses + 1; return realStatus(...) end
  D.UpdateScrollBar = function(...) bars = bars + 1; return realBar(...) end
  local n = D:RunDiagnostics()
  assertTrue(n > 50, "more than fifty lines written")
  assertEqual(statuses, 1, "one status update")
  assertEqual(bars, 1, "one scrollbar update")
end)

test("diag: sections are asked for at run time, so one added after New still reports", function()
  local D, rec = newLog()
  rec.sections = { { "late", function(out) out:add("Late", "loaded after the console") end } }
  local t = texts(D:BuildDiagnostics())
  assertTrue(has(t, "loaded after the console"))
end)

test("diag: spec.sections replaces the host's list", function()
  local D, rec = newLog()
  rec.sections = { { "host", function(out) out:add("Host", "from the descriptor") end } }
  local t = texts(D:BuildDiagnostics{ sections = {
    { "spec", function(out) out:add("Spec", "from the spec") end } } })
  assertTrue(has(t, "from the spec"))
  assertFalse(has(t, "from the descriptor"))
end)

-- ── failure costs one line ─────────────────────────────────────────────────────────────────

test("diag: a raising section costs exactly one line, and the next section still runs", function()
  local D, rec = newLog()
  local clean = #D:BuildDiagnostics().lines
  rec.sections = {
    { "broken", function() error("boom", 0) end },
    { "after", function(out) out:add("After", "still here") end },
  }
  local r = D:BuildDiagnostics()
  local t = texts(r)
  assertTrue(has(t, "section broken failed: boom"), "the failure is one named line")
  assertTrue(has(t, "still here"), "and the next section ran")
  assertEqual(#r.lines, clean + 2, "one line for the failure, one for the section after it")
end)

test("diag: a raising section list costs one line", function()
  local D = newLog{ diagnostics = function() error("no list", 0) end }
  local t = texts(D:BuildDiagnostics())
  assertTrue(has(t, "section list failed: no list"))
  assertTrue(t[#t]:find("diagnostics end", 1, true) ~= nil, "and the report still ends")
end)

-- ── the cap ────────────────────────────────────────────────────────────────────────────────

test("diag: an over-cap report keeps two lines for the truncated line and the end marker",
  function()
    local D, rec = newLog()
    rec.sections = { { "many", many(100) } }
    local r = D:BuildDiagnostics{ maxLines = 20 }
    local t = texts(r)
    assertEqual(#t, 20, "exactly the cap")
    assertTrue(r.capped and r.dropped > 0)
    assertEqual(t[19], ("truncated: %d line(s) omitted, per-list caps hit=no"):format(r.dropped))
    assertEqual(t[20], "==== Ka0s Diag Test diagnostics end: 20 line(s) ====")
    assertEqual(#t - 2 + r.dropped, #D:BuildDiagnostics{ maxLines = 1000 }.lines - 1,
      "every line is either kept or counted")
  end)

test("diag: the cap is clamped a hundred lines below the buffer", function()
  local D, rec = newLog()
  rec.sections = { { "many", many(300) } }
  local saved = debuglog.MAX_BUFFER
  debuglog.MAX_BUFFER = 150
  local ok, err = pcall(function()
    assertEqual(#D:BuildDiagnostics().lines, 50, "min(DIAG_MAX_LINES, MAX_BUFFER - 100)")
    assertEqual(#D:BuildDiagnostics{ maxLines = 5000 }.lines, 50, "a spec cannot lift it")
  end)
  debuglog.MAX_BUFFER = saved
  if not ok then error(err, 0) end
end)

test("diag: an uncapped report writes no truncated line", function()
  local D = newLog()
  local r = D:BuildDiagnostics()
  assertFalse(r.capped)
  assertFalse(has(texts(r), "truncated:"))
end)

test("diag: a per-list cap sets the flag the truncated line reports", function()
  local D, rec = newLog()
  local items = {}
  for i = 1, 50 do items[i] = i end
  rec.sections = { { "ids", function(out) out:list("Ids", "ids:", items) end } }
  local r = D:BuildDiagnostics()
  local t = texts(r)
  assertTrue(r.capsHit and r.capped)
  assertTrue(has(t, "(+10 more)"), "the forty kept and the rest counted")
  assertTrue(has(t, "truncated: 0 line(s) omitted, per-list caps hit=yes"))
end)

test("diag: a list under its own cap is written whole and sets nothing", function()
  local D, rec = newLog()
  rec.sections = { { "ids", function(out) out:list("Ids", "ids:", { 1, 2, 3 }, 5) end } }
  local r = D:BuildDiagnostics()
  assertFalse(r.capsHit)
  assertTrue(has(texts(r), "ids: 1, 2, 3"))
end)

-- ── the writer ─────────────────────────────────────────────────────────────────────────────

--- Run `fn(out)` as the only section and answer the lines it wrote.
local function written(fn)
  local D = newLog()
  local r = D:BuildDiagnostics{ sections = { { "probe", fn } } }
  local body, inside = {}, false
  for _, line in ipairs(r.lines) do
    if line[1] == "Probe" then inside = true end
    if inside and line[1] ~= "Diag" then body[#body + 1] = line[2] end
  end
  return body, r
end

test("diag: out:add strips color, texture, atlas and hyperlink escapes", function()
  local body = written(function(out)
    out:add("Probe", "%s", "|cffff0000red|r |Tpath:0|t|A:atlas:0:0|a|Hitem:1|h[Item]|h")
  end)
  assertEqual(body[1], "red [Item]")
end)

test("diag: out:escape doubles the pipe, and the doubled pipe survives the strip", function()
  local body = written(function(out)
    out:add("Probe", "format = %s", out:escape("|cff00ff00%s|r"))
  end)
  assertEqual(body[1], "format = ||cff00ff00%s||r")
end)

test("diag: a secret value goes through safeToString and does not raise", function()
  local body, r = written(function(out)
    out:add("Probe", "value=%d", secretMock)
    out:add("Probe", "readable=%s %s", out:readable(secretMock), out:readable(7))
  end)
  -- The sentinel is a string, so `%d` cannot take it: the line lands through the fallback join.
  assertEqual(body[1], "value=%d <secret>")
  assertEqual(body[2], "readable=false true")
  assertFalse(has(texts(r), "failed"), "no section failed")
end)

test("diag: out:readable refuses what the client calls secret", function()
  local saved = mocks.issecretvalue
  mocks.issecretvalue = function(v) return v == 42 end
  local ok, err = pcall(function()
    local body = written(function(out)
      out:add("Probe", "%s %s", out:readable(42), out:readable(41))
    end)
    assertEqual(body[1], "false true")
  end)
  mocks.issecretvalue = saved
  if not ok then error(err, 0) end
end)

test("diag: out:joined wraps at 200 characters and writes `lead -` for nothing", function()
  local parts = {}
  for i = 1, 60 do parts[i] = ("item%02d"):format(i) end
  local body = written(function(out)
    out:joined("Probe", "items:", parts)
    out:joined("Probe", "none:", {})
  end)
  assertTrue(#body >= 3, "sixty items wrap")
  for i = 1, #body - 1 do assertTrue(#body[i] <= 200, "line " .. i .. " is within the width") end
  assertTrue(body[1]:find("^items: item01, item02") ~= nil)
  assertTrue(body[2]:find("^  item") ~= nil, "a continuation is indented")
  assertEqual(body[#body], "none: -")
end)

test("diag: out:section nests a pcall of its own", function()
  local body = written(function(out)
    out:section("inner", function() error("inner boom", 0) end)
    out:add("Probe", "outer goes on")
  end)
  assertEqual(body[1], "outer goes on")
end)

test("diag: out:nonDefaults prints what differs, skips session-only and hidden rows", function()
  local rows = {
    { path = "a", default = 1 },
    { path = "b", default = 2 },
    { path = "c", default = { r = 1, g = 1 } },
    { path = "d", default = true, sessionOnly = true },
    { path = "e", default = "x", hidden = true },
    { path = "f", default = "same" },
  }
  local store = { a = 1, b = 3, c = { r = 0, g = 1 }, d = false, e = "y", f = "same" }
  local count
  local body = written(function(out)
    count = out:nonDefaults(rows, function(row) return store[row.path] end, nil, nil,
      { always = { "f" }, tag = "Probe" })
  end)
  assertEqual(count, 3)
  assertEqual(body[1], "b = 3 (2)")
  assertEqual(body[2], "c = {g=1, r=0} ({g=1, r=1})")
  assertEqual(body[3], "f = same (same)", "an always path prints at its default")
end)

-- ── DebugVerb ──────────────────────────────────────────────────────────────────────────────

test("diag: DebugVerb runs the report for `diagnostics`, in any case", function()
  local D = newLog()
  assertTrue(D:DebugVerb("diagnostics"))
  local after = #D.buffer
  assertTrue(after > 0, "a report was written")
  assertTrue(D:DebugVerb("  DIAGNOSTICS  "))
  assertTrue(#D.buffer > after, "and again")
end)

test("diag: DebugVerb sets the flag for on and off", function()
  local D, rec = newLog()
  assertTrue(D:DebugVerb("on"))
  assertTrue(rec.enabled)
  assertTrue(D:DebugVerb("OFF"))
  assertFalse(rec.enabled)
end)

test("diag: DebugVerb answers false for anything else and writes no report", function()
  local D = newLog()
  for _, word in ipairs({ "", "diag", "dump", "dx", "diagnostic", "window" }) do
    assertFalse(D:DebugVerb(word), "'" .. word .. "' is the host's")
  end
  assertFalse(D:DebugVerb(nil), "nil is the host's too")
  assertEqual(#D.buffer, 0, "nothing was written")
end)

-- ── the degraded contract ──────────────────────────────────────────────────────────────────

test("diag: the three instance members a consumer's DebugLog stub must carry", function()
  -- A consumer's library-absent stub stands in for an instance, and its parity case compares it
  -- against one. These are the members this file adds to that surface; the stub's RunDiagnostics
  -- prints its one placeholder line, writes nothing and returns 0 (debug-logging-§14), which is why
  -- the live one returns a number too.
  local D = newLog()
  assertEqual(type(D.RunDiagnostics), "function")
  assertEqual(type(D.BuildDiagnostics), "function")
  assertEqual(type(D.DebugVerb), "function")
  assertEqual(type(D:RunDiagnostics()), "number")
end)

test("diag: without the secondary file an instance has no report methods", function()
  local saved = debuglog.__installDiagnostics
  debuglog.__installDiagnostics = nil
  local ok, err = pcall(function()
    local D = newLog()
    assertEqual(D.RunDiagnostics, nil)
    assertEqual(D.DebugVerb, nil)
    D:Add("Trace", "the console itself still works")
    assertEqual(#D.buffer, 1)
  end)
  debuglog.__installDiagnostics = saved
  if not ok then error(err, 0) end
end)
