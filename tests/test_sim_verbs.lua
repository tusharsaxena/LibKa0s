-- tests/test_sim_verbs.lua — LibKa0s-Sim-1.0's verbs: `sim:RunVerb(line)`, in `SimTimeline.lua`.
--
-- The generic grammar (the empty line, start, run, step, pause, resume, restart, stop, status,
-- panel), the host's verbs, the free-verb rule, the WHY lines, the status line and the usage.
-- There is NO `help` verb (OWNER_SCOPE C.7): `help` is an unknown word and prints the usage.
--
-- "The click path is the typed path": a typed control prints exactly what calling the control
-- prints, so the dispatch cases run the same control on two benches, one typed and one called,
-- and compare every printed line.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local Loader = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local MAJOR = "LibKa0s-Sim-1.0"

--- A fresh environment with Core, Sim and SimTimeline loaded.
local function env()
  local m = buildMocks()
  Loader.load("LibKa0s/Core.lua", nil, m)
  Loader.load("LibKa0s/Sim.lua", nil, m)
  Loader.load("LibKa0s/SimTimeline.lua", nil, m)
  return m, m.LibStub(MAJOR)
end

--- A bench: a three-step scenario and a sized one, a recording play, and the panel members stood
--- in for (SimPanel.lua is not loaded here) so the panel verbs can be counted. `over` is merged into
--- the descriptor before New. `prepare` calls ready() at once unless holdReady is set.
local function bench(over, holdReady)
  local m, Sim = env()
  local seam = Sim:NewSeam({ Probe = function() return "live" end }, { name = "Host" })
  local b = { m = m, Sim = Sim, printed = {}, debugs = {}, played = {}, readies = {}, shown = 0, toggled = 0 }
  local d = {
    name = "Host", seam = seam, slash = "/host sim",
    deliver = function() return 1 end,
    isStoodDown = function() return false end,
    scenarios = {
      names = { "three", "sized" },
      defs = {
        three = { label = "Three", timeline = function()
          return { { kind = "a", label = "Alpha" }, { kind = "b", label = "Beta" }, { kind = "c", label = "Gamma" } }
        end },
        sized = { label = "Sized", sizes = { 5, 10 }, timeline = function()
          return { { kind = "s1" }, { kind = "s2" } }
        end },
      },
    },
    prepare = function(_, _, opts, ready)
      b.opts = opts
      b.readies[#b.readies + 1] = ready
      if not holdReady then ready() end
    end,
    play = function(step)
      b.played[#b.played + 1] = step.kind
      return "did " .. step.kind
    end,
    print = function(line) b.printed[#b.printed + 1] = line end,
    debug = function(tag, fmt, ...) b.debugs[#b.debugs + 1] = { tag = tag, text = fmt:format(...) } end,
  }
  for k, v in pairs(over or {}) do d[k] = v end
  b.d = d
  b.sim = Sim:New(d)
  b.sim.ShowPanel = function() b.shown = b.shown + 1; return true end
  b.sim.TogglePanel = function() b.toggled = b.toggled + 1; return true end
  return b
end

local function joined(list, sep) return table.concat(list, sep or ",") end
local function lastPrinted(b) return b.printed[#b.printed] end

--- The lines printed by fn(b) alone.
local function linesOf(b, fn)
  local from = #b.printed
  fn(b)
  local out = {}
  for i = from + 1, #b.printed do out[#out + 1] = b.printed[i] end
  return out
end

--- The library's usage, formatted with the bench's slash.
local USAGE_KEYS = { "USAGE_BARE", "USAGE_START", "USAGE_RUN", "USAGE_STEP", "USAGE_PAUSE", "USAGE_RESUME",
  "USAGE_RESTART", "USAGE_STOP", "USAGE_STATUS", "USAGE_PANEL" }
local function usage(Sim)
  local out = {}
  for i, key in ipairs(USAGE_KEYS) do out[i] = Sim.STRINGS[key]:format("/host sim") end
  return out
end

-- ── the file ─────────────────────────────────────────────────────────────────────────────

test("sim verbs: RunVerb is SimTimeline's, not the shell's NO_TIMELINE fallback", function()
  local b = bench()
  b.sim:RunVerb("status")
  assertFalse(lastPrinted(b) == b.Sim.STRINGS.NO_TIMELINE)
end)

test("sim verbs: the status, usage and state keys are added to Sim.STRINGS", function()
  local _, Sim = env()
  local keys = { "STATUS_IDLE", "STATUS_RUNNING", "STATUS_SIZE", "STATUS_RANDOM", "STATE_BUILDING",
    "STATE_PLAYING", "STATE_PAUSED", "STATE_SETTLING", "STATE_WAITING", "STATE_DONE", "VERB_FAILED" }
  for _, key in ipairs(USAGE_KEYS) do keys[#keys + 1] = key end
  for _, key in ipairs(keys) do assertEqual(type(Sim.STRINGS[key]), "string", key) end
  assertNil(Sim.STRINGS.USAGE_HELP, "no help verb (OWNER_SCOPE C.7)")
end)

-- ── the empty line, status, panel, usage ─────────────────────────────────────────────────

test("sim verbs: the empty line prints the status line and the usage, and opens the panel", function()
  local b = bench()
  local out = linesOf(b, function() assertTrue(b.sim:RunVerb("")) end)
  local want = { b.Sim.STRINGS.STATUS_IDLE:format("three, sized") }
  for _, line in ipairs(usage(b.Sim)) do want[#want + 1] = line end
  assertEqual(joined(out, "|"), joined(want, "|"))
  assertEqual(b.shown, 1)
end)

test("sim verbs: a nil or blank line is the empty line", function()
  local b = bench()
  b.sim:RunVerb(nil)
  b.sim:RunVerb("   ")
  assertEqual(b.shown, 2)
end)

test("sim verbs: 'help' is not a verb (C.7): it prints the usage, as any unknown word does", function()
  local b = bench()
  for _, word in ipairs({ "help", "bogus", "HELP" }) do
    local ok, code
    local out = linesOf(b, function() ok, code = b.sim:RunVerb(word) end)
    assertFalse(ok, word)
    assertEqual(code, "usage", word)
    assertEqual(joined(out, "|"), joined(usage(b.Sim), "|"), word)
  end
  assertEqual(b.shown, 0, "the usage opens no panel")
end)

test("sim verbs: the usage is formatted with d.slash and appends d.usage", function()
  local b = bench({ slash = "/x sim", usage = { "/x sim pull: pull a boss.", "/x sim kill: kill it." } })
  local out = linesOf(b, function() b.sim:RunVerb("bogus") end)
  assertEqual(#out, #USAGE_KEYS + 2)
  assertEqual(out[2], b.Sim.STRINGS.USAGE_START:format("/x sim"))
  assertTrue(out[2]:find("/x sim start", 1, true) ~= nil)
  assertEqual(out[#out - 1], "/x sim pull: pull a boss.")
  assertEqual(out[#out], "/x sim kill: kill it.")
end)

test("sim verbs: a usage line is overridable through d.L", function()
  local b = bench({ L = { USAGE_STOP = "%s stop -- end it" } })
  local out = linesOf(b, function() b.sim:RunVerb("bogus") end)
  assertEqual(out[8], "/host sim stop -- end it")
end)

test("sim verbs: status idle prints STATUS_IDLE with the scenario names, and is free", function()
  local b = bench()
  local ok = b.sim:RunVerb("status")
  assertTrue(ok)
  assertEqual(joined(b.printed, "|"), b.Sim.STRINGS.STATUS_IDLE:format("three, sized"))
end)

test("sim verbs: status running names the scenario, size, seed, position and state", function()
  local b = bench()
  b.sim:Start({ scenario = "sized", size = 5, seed = 42 })
  b.sim:Step()
  local out = linesOf(b, function() b.sim:RunVerb("status") end)
  local S = b.Sim.STRINGS
  assertEqual(out[1], S.STATUS_RUNNING:format(S.STATUS_SIZE:format("sized", "5"), "42", 1, 2, S.STATE_WAITING))
  assertEqual(#out, 1)
end)

test("sim verbs: status reads random for size 0 and no size for an unsized scenario", function()
  local b = bench()
  local S = b.Sim.STRINGS
  b.sim:Start({ scenario = "sized", seed = 7 })
  local out = linesOf(b, function() b.sim:RunVerb("status") end)
  assertEqual(out[1], S.STATUS_RUNNING:format(S.STATUS_SIZE:format("sized", S.STATUS_RANDOM), "7", 0, 2, S.STATE_WAITING))
  b.sim:Stop()
  b.sim:Start({ scenario = "three", seed = 8 })
  out = linesOf(b, function() b.sim:RunVerb("status") end)
  assertEqual(out[1], S.STATUS_RUNNING:format("three", "8", 0, 3, S.STATE_WAITING))
end)

test("sim verbs: the status state reads building, playing, paused, settling and finished", function()
  local S
  local b = bench(nil, true)
  S = b.Sim.STRINGS
  local function state()
    local line = linesOf(b, function() b.sim:RunVerb("status") end)[1]
    return line
  end
  b.sim:Start({ scenario = "three", seed = 1 })
  assertTrue(state():find(S.STATE_BUILDING, 1, true) ~= nil, "building")
  b.readies[1]()
  b.sim:Run()
  assertTrue(state():find(S.STATE_PLAYING, 1, true) ~= nil, "playing")
  b.sim:Pause()
  assertTrue(state():find(S.STATE_PAUSED, 1, true) ~= nil, "paused")
  b.sim:Step(); b.sim:Step()
  assertTrue(state():find(S.STATE_DONE, 1, true) ~= nil, "finished")

  local open = true
  b = bench({ gate = function() return open end })
  b.sim:Start({ scenario = "three", seed = 1 })
  open = false
  b.sim:Step()
  assertTrue(state():find(S.STATE_SETTLING, 1, true) ~= nil, "settling")
end)

test("sim verbs: status appends d.statusLine, as a line or a list, handed the status and session", function()
  local seen
  local b = bench({ statusLine = function(status, session)
    seen = { status = status, session = session }
    return "World: 4 members."
  end })
  b.sim:Start({ scenario = "three" })
  local out = linesOf(b, function() b.sim:RunVerb("status") end)
  assertEqual(#out, 2)
  assertEqual(out[2], "World: 4 members.")
  assertTrue(seen.status.active)
  assertTrue(rawequal(seen.session, b.sim:Session()))

  b = bench({ statusLine = function() return { "One.", "Two." } end })
  out = linesOf(b, function() b.sim:RunVerb("status") end)
  assertEqual(joined(out, "|"), b.Sim.STRINGS.STATUS_IDLE:format("three, sized") .. "|One.|Two.")
end)

test("sim verbs: a statusLine that raises is a debug line, and the library's line still prints", function()
  local b = bench({ statusLine = function() error("boom") end })
  local out = linesOf(b, function() assertTrue(b.sim:RunVerb("status")) end)
  assertEqual(#out, 1)
  assertTrue(#b.debugs > 0)
end)

test("sim verbs: panel toggles the panel, idle or running (a free verb)", function()
  local b = bench()
  local ok = b.sim:RunVerb("panel")
  assertTrue(ok)
  assertEqual(b.toggled, 1)
  assertEqual(#b.printed, 0)
end)

-- ── start ────────────────────────────────────────────────────────────────────────────────

test("sim verbs: start <name> starts it with no size, and prints exactly Start's lines", function()
  local typed, called = bench(), bench()
  local ok = typed.sim:RunVerb("start three")
  assertTrue(ok)
  called.sim:Start({ scenario = "three" })
  assertEqual(joined(typed.printed, "|"), joined(called.printed, "|"))
  assertEqual(typed.opts.scenario, "three")
  assertNil(typed.opts.size)
end)

test("sim verbs: start <name> <size> hands the size to Start", function()
  local b = bench()
  assertTrue(b.sim:RunVerb("start sized 10"))
  assertEqual(b.opts.size, 10)
end)

test("sim verbs: the verb and the scenario name match regardless of case", function()
  local b = bench()
  assertTrue(b.sim:RunVerb("START Three"))
  assertEqual(b.opts.scenario, "three")
end)

test("sim verbs: start of an unknown scenario prints the UNKNOWN_SCENARIO line, silently refused", function()
  local b = bench()
  local ok, code
  local out = linesOf(b, function() ok, code = b.sim:RunVerb("start nope") end)
  assertFalse(ok)
  assertEqual(code, "refused")
  assertEqual(joined(out, "|"), b.Sim.STRINGS.UNKNOWN_SCENARIO:format("nope", "three, sized"))
end)

test("sim verbs: start with no name prints the usage", function()
  local b = bench()
  local ok, code
  local out = linesOf(b, function() ok, code = b.sim:RunVerb("start") end)
  assertFalse(ok)
  assertEqual(code, "usage")
  assertEqual(joined(out, "|"), joined(usage(b.Sim), "|"))
end)

test("sim verbs: start while running prints ALREADY_RUNNING once (refused is silent)", function()
  local b = bench()
  b.sim:RunVerb("start three")
  local out = linesOf(b, function() b.sim:RunVerb("start three") end)
  assertEqual(joined(out, "|"), b.Sim.STRINGS.ALREADY_RUNNING)
end)

test("sim verbs: a host refusal prints its own line once", function()
  local b = bench({ refusal = function() return "Not in combat." end })
  local ok, code
  local out = linesOf(b, function() ok, code = b.sim:RunVerb("start three") end)
  assertFalse(ok)
  assertEqual(code, "refused")
  assertEqual(joined(out, "|"), "Not in combat.")
end)

-- ── the controls ─────────────────────────────────────────────────────────────────────────

--- Run `verb` typed on one bench and `call` on a twin bench, both started on `three`, after
--- `setup` ran on each; assert the same answer and exactly the same lines.
local function sameAsCalled(verb, call, setup)
  local typed, called = bench(), bench()
  for _, b in ipairs({ typed, called }) do
    b.sim:Start({ scenario = "three", seed = 1 })
    if setup then setup(b) end
  end
  local tOk, cOk
  local tOut = linesOf(typed, function() tOk = typed.sim:RunVerb(verb) end)
  local cOut = linesOf(called, function() cOk = call(called.sim) end)
  assertEqual(joined(tOut, "|"), joined(cOut, "|"), verb)
  assertEqual(not not tOk, not not cOk, verb)
  assertEqual(joined(typed.played), joined(called.played), verb)
  return typed
end

test("sim verbs: step dispatches to Step and prints exactly its line", function()
  local b = sameAsCalled("step", function(sim) return sim:Step() end)
  assertEqual(joined(b.played), "a")
end)

test("sim verbs: run dispatches to Run", function()
  local b = sameAsCalled("run", function(sim) return sim:Run() end)
  assertTrue(b.sim:Status().playing)
end)

test("sim verbs: pause dispatches to Pause", function()
  local b = sameAsCalled("pause", function(sim) return sim:Pause() end, function(x) x.sim:Run() end)
  assertTrue(b.sim:Status().paused)
end)

test("sim verbs: resume dispatches to Resume", function()
  local b = sameAsCalled("resume", function(sim) return sim:Resume() end,
    function(x) x.sim:Run(); x.sim:Pause() end)
  assertTrue(b.sim:Status().playing)
end)

test("sim verbs: restart dispatches to Restart", function()
  local b = sameAsCalled("restart", function(sim) return sim:Restart() end)
  assertEqual(#b.readies, 2, "prepared again")
end)

test("sim verbs: stop dispatches to Stop with the reason stop", function()
  local b = sameAsCalled("stop", function(sim) return sim:Stop("stop") end)
  assertFalse(b.sim:IsActive())
  assertEqual(lastPrinted(b), b.Sim.STRINGS.STOPPED)
end)

test("sim verbs: every non-free generic verb prints NOT_RUNNING while idle", function()
  local b = bench()
  for _, verb in ipairs({ "run", "step", "pause", "resume", "restart", "stop" }) do
    local ok, code
    local out = linesOf(b, function() ok, code = b.sim:RunVerb(verb) end)
    assertFalse(ok, verb)
    assertEqual(code, "notRunning", verb)
    assertEqual(joined(out, "|"), b.Sim.STRINGS.NOT_RUNNING, verb)
  end
end)

test("sim verbs: a failure code prints its library WHY line", function()
  local b = bench(nil, true)
  b.sim:RunVerb("start three")
  local cases = {
    { "step", "building", "BUILDING" },
    { "run", "building", "BUILDING" },
    { "pause", "notPlaying", "NOT_PLAYING" },
    { "resume", "notPaused", "NOT_PAUSED" },
  }
  for _, c in ipairs(cases) do
    local ok, code
    local out = linesOf(b, function() ok, code = b.sim:RunVerb(c[1]) end)
    assertFalse(ok, c[1])
    assertEqual(code, c[2], c[1])
    assertEqual(joined(out, "|"), b.Sim.STRINGS[c[3]], c[1])
  end
  b.readies[1]()
  b.sim:RunVerb("run")
  local ok, code
  local out = linesOf(b, function() ok, code = b.sim:RunVerb("run") end)
  assertFalse(ok)
  assertEqual(code, "playing")
  assertEqual(joined(out, "|"), b.Sim.STRINGS.PLAYING)
  b.sim:Pause()
  b.sim:Step(); b.sim:Step()
  out = linesOf(b, function() ok, code = b.sim:RunVerb("step") end)
  assertFalse(ok)
  assertEqual(code, "done")
  assertEqual(joined(out, "|"), b.Sim.STRINGS.DONE)
end)

test("sim verbs: step on a closed gate prints the gate's line once, not a second WHY", function()
  local b = bench({ gate = function() return false, "Waiting for the bank." end })
  b.sim:Start({ scenario = "three" })
  local ok, code
  local out = linesOf(b, function() ok, code = b.sim:RunVerb("step") end)
  assertFalse(ok)
  assertEqual(code, "settling")
  assertEqual(joined(out, "|"), "Waiting for the bank.")
end)

test("sim verbs: a failing step prints STEP_FAILED once, and failed is silent", function()
  local b = bench({ play = function() error("bad step") end })
  b.sim:Start({ scenario = "three" })
  local ok, code
  local out = linesOf(b, function() ok, code = b.sim:RunVerb("step") end)
  assertFalse(ok)
  assertEqual(code, "failed")
  assertEqual(#out, 1)
  assertTrue(out[1]:find("failed", 1, true) ~= nil)
end)

test("sim verbs: a refused restart is silent past the refusal's own line", function()
  local refuse = false
  local b = bench({ refusal = function() return refuse and "Not now." or nil end })
  b.sim:Start({ scenario = "three" })
  refuse = true
  local ok, code
  local out = linesOf(b, function() ok, code = b.sim:RunVerb("restart") end)
  assertFalse(ok)
  assertEqual(code, "refused")
  assertEqual(out[#out], "Not now.", "the refusal line is the last one: no WHY after it")
end)

test("sim verbs: a library WHY line is overridable through d.L", function()
  local b = bench({ L = { NOT_RUNNING = "Start one first." } })
  b.sim:RunVerb("step")
  assertEqual(lastPrinted(b), "Start one first.")
end)

-- ── host verbs ───────────────────────────────────────────────────────────────────────────

--- A bench with a host verb `pull` (needs a session) and `info` (free), recording their calls.
local function hostBench(over)
  local calls = {}
  local d = {
    verbs = {
      pull = {
        parse = function(words) return { verb = words[1], who = words[2] } end,
        run = function(cmd, sim) calls[#calls + 1] = { cmd = cmd, sim = sim }; return true end,
      },
      info = { free = true,
        parse = function() return { verb = "info" } end,
        run = function() calls[#calls + 1] = { cmd = "info" }; return true end },
      loot = {
        parse = function(words) if words[2] then return { n = tonumber(words[2]) } end end,
        run = function(cmd) if cmd.n > 3 then return false, "noLooter" end; return false, "refused" end,
      },
    },
    why = { noLooter = "No one by that name is in the group." },
  }
  for k, v in pairs(over or {}) do d[k] = v end
  local b = bench(d)
  b.calls = calls
  return b
end

test("sim verbs: a host verb is parsed from the words and run with the command and the instance", function()
  local b = hostBench()
  b.sim:Start({ scenario = "three" })
  local ok = b.sim:RunVerb("pull Boss")
  assertTrue(ok)
  assertEqual(#b.calls, 1)
  assertEqual(b.calls[1].cmd.verb, "pull", "words[1] is the verb")
  assertEqual(b.calls[1].cmd.who, "Boss")
  assertTrue(rawequal(b.calls[1].sim, b.sim))
end)

test("sim verbs: a host verb needs a session: idle it prints NOT_RUNNING and is not run", function()
  local b = hostBench()
  local ok, code
  local out = linesOf(b, function() ok, code = b.sim:RunVerb("pull") end)
  assertFalse(ok)
  assertEqual(code, "notRunning")
  assertEqual(joined(out, "|"), b.Sim.STRINGS.NOT_RUNNING)
  assertEqual(#b.calls, 0)
end)

test("sim verbs: a free host verb runs idle", function()
  local b = hostBench()
  assertTrue(b.sim:RunVerb("info"))
  assertEqual(b.calls[1].cmd, "info")
end)

test("sim verbs: a host failure code prints d.why's line; refused stays silent", function()
  local b = hostBench()
  b.sim:Start({ scenario = "three" })
  local ok, code
  local out = linesOf(b, function() ok, code = b.sim:RunVerb("loot 5") end)
  assertFalse(ok)
  assertEqual(code, "noLooter")
  assertEqual(joined(out, "|"), "No one by that name is in the group.")
  out = linesOf(b, function() ok, code = b.sim:RunVerb("loot 1") end)
  assertFalse(ok)
  assertEqual(code, "refused")
  assertEqual(#out, 0)
end)

test("sim verbs: a host verb that answers a library code prints the library's line", function()
  local b = hostBench({ verbs = { poke = { parse = function() return {} end,
    run = function() return false, "building" end } } })
  b.sim:Start({ scenario = "three" })
  b.sim:RunVerb("poke")
  assertEqual(lastPrinted(b), b.Sim.STRINGS.BUILDING)
end)

test("sim verbs: a host verb whose parse answers nil prints the usage", function()
  local b = hostBench()
  b.sim:Start({ scenario = "three" })
  local ok, code
  local out = linesOf(b, function() ok, code = b.sim:RunVerb("loot") end)
  assertFalse(ok)
  assertEqual(code, "usage")
  assertEqual(joined(out, "|"), joined(usage(b.Sim), "|"))
end)

test("sim verbs: a host verb that raises prints VERB_FAILED and writes a debug line", function()
  local b = hostBench({ verbs = { boom = { free = true, parse = function() return {} end,
    run = function() error("kaput") end } } })
  local ok, code
  local out = linesOf(b, function() ok, code = b.sim:RunVerb("boom") end)
  assertFalse(ok)
  assertEqual(code, "error")
  assertEqual(joined(out, "|"), b.Sim.STRINGS.VERB_FAILED:format("boom"))
  assertTrue(#b.debugs > 0)
end)

test("sim verbs: the generic verbs win over a host verb of the same name", function()
  local ran = false
  local b = hostBench({ verbs = { step = { parse = function() return {} end,
    run = function() ran = true; return true end } } })
  b.sim:Start({ scenario = "three" })
  b.sim:RunVerb("step")
  assertFalse(ran)
  assertEqual(joined(b.played), "a")
end)

test("sim verbs: a host 'help' verb is the host's own; the library defines none", function()
  local b = hostBench({ verbs = { help = { free = true, parse = function() return {} end,
    run = function() return true end } } })
  local out = linesOf(b, function() assertTrue(b.sim:RunVerb("help")) end)
  assertEqual(#out, 0)
end)
