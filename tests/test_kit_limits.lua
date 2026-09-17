-- tests/test_kit_limits.lua — the kit's resource bounds (kit revision 23).
--
-- A headless run in this collection once took its whole machine down: a stray probe made a runner
-- start itself through `--list`, forever, and a consumer's harness held every addon instance it had
-- ever built until the run ended. Both were silent until the kernel's OOM killer spoke. The cases
-- below pin the bounds that turn each of those into a named failure instead: the process guard that
-- runs when the kit loads, and the heap, leak, CPU and host-path gates inside the runner.
--
-- The guard cases start a real child through tests/fixture_guard.lua, because what they assert --
-- a re-launch, an exported depth, an exit code, a stopped process -- only exists across a process
-- boundary. Each child is given KA0S_KIT_DEPTH=0 and no cgroup, so the case does not depend on how
-- deep this run itself is, or on the host's systemd.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil

local Kit = dofile("tests/_kit/framework.lua")

local function interpreter()
  local a = rawget(_G, "arg")
  return (a and a[-1]) or "lua"
end

--- Run the fixture with `env` prefixed and `args` after it; answer its output and exit code.
local function runFixture(env, args)
  if not io.popen then T.skip("io.popen is unavailable, so no child process can be started") end
  local cmd = ("KA0S_KIT_DEPTH=0 KA0S_KIT_CGROUP=off %s %s tests/fixture_guard.lua %s 2>&1; echo \"rc=$?\"")
    :format(env or "", interpreter(), args)
  local p = io.popen(cmd)
  local out = p:read("*a") or ""
  p:close()
  local rc = tonumber(out:match("rc=(%d+)%s*$"))
  return out, rc
end

-- ── the process guard ──────────────────────────────────────────────────────────────────────

test("kit guard: a guarded process sees its depth one deeper and its own arguments unchanged", function()
  local out, rc = runFixture("", "report a 'b c'")
  assertEqual(rc, 0, "the fixture exits cleanly: " .. out)
  assertTrue(out:find("depth=1 args=report,a,b c", 1, true) ~= nil,
    "depth 1, the arguments intact, and no marker left in `arg`: " .. out)
end)

test("kit guard: a runner that starts itself stops at the depth limit instead of forking forever", function()
  local out = runFixture("KA0S_KIT_MAX_DEPTH=3", "recurse")
  local depths = {}
  for d in out:gmatch("depth=(%d+)") do depths[#depths + 1] = tonumber(d) end
  assertEqual(table.concat(depths, ","), "1,2,3", "one process per level up to the limit: " .. out)
  assertTrue(out:find("refusing to start", 1, true) ~= nil,
    "and the fourth is refused, with a message that says why: " .. out)
end)

test("kit guard: the guarded child's exit code is the run's exit code", function()
  local _, rc = runFixture("", "exit 7")
  assertEqual(rc, 7, "a gate is a plain shell check, so the code must survive the re-launch")
end)

test("kit guard: a run past its wall-clock limit is stopped with 124 and says so", function()
  local out, rc = runFixture("KA0S_KIT_TIMEOUT_S=1", "loop")
  assertEqual(rc, 124, "timeout's own code: " .. out)
  assertTrue(out:find("wall-clock limit", 1, true) ~= nil, "and the reason is printed: " .. out)
end)

test("kit guard: KA0S_KIT_GUARD=off runs the process as it was started", function()
  local out = runFixture("KA0S_KIT_GUARD=off", "report")
  assertTrue(out:find("depth=0 args=report", 1, true) ~= nil,
    "no re-launch, so the depth is the one the caller exported: " .. out)
end)

test("kit guard: exit statuses normalize across Lua 5.1 and 5.2+", function()
  local code = Kit.__exitCodeOf
  assertEqual(code(0), 0, "5.1, a clean exit")
  assertEqual(code(7 * 256), 7, "5.1, exit 7 as a wait status")
  assertEqual(code(9), 137, "5.1, killed by SIGKILL")
  assertEqual(code(true, "exit", 0), 0, "5.2+, a clean exit")
  assertEqual(code(nil, "exit", 3), 3, "5.2+, exit 3")
  assertEqual(code(nil, "signal", 9), 137, "5.2+, killed by SIGKILL")
end)

-- ── the gates inside the runner ────────────────────────────────────────────────────────────

test("kit limits: a case's CPU ceiling stops a loop, even one that swallows the first error", function()
  local ok, err = Kit.__pcallBounded(1, function()
    while true do pcall(function() while true do end end) end
  end)
  assertEqual(ok, false, "the bounded call fails")
  assertTrue(tostring(err):find("CPU ceiling", 1, true) ~= nil, "and names the ceiling: " .. tostring(err))
end)

test("kit limits: a bounded call hands back every result, nils included", function()
  local ok, a, b, c = Kit.__pcallBounded(5, function() return 1, nil, 3 end)
  assertTrue(ok, "the call succeeded")
  assertEqual(a, 1, "first result")
  assertNil(b, "a nil in the middle survives")
  assertEqual(c, 3, "and so does what follows it")
end)

test("kit limits: --jobs is capped by memory, never below one, and unchanged when memory is unknown", function()
  local cap = Kit.__memoryCappedJobs
  assertEqual(cap(16, 4096, 512), 6, "three quarters of 4096 MB holds six 512 MB workers")
  assertEqual(cap(4, 64000, 512), 4, "plenty of memory leaves the request alone")
  assertEqual(cap(16, 100, 512), 1, "never fewer than one worker")
  assertEqual(cap(16, nil, 512), 16, "no /proc/meminfo, no cap")
  assertEqual(cap(1, 100, 512), 1, "a serial run is never touched")
end)

test("kit limits: a host path in a suite is caught, and a WoW path is not", function()
  local find = Kit.__hostPathIn
  -- Assembled rather than written out, so this file does not trip the gate it tests.
  local slash = "/"
  assertTrue(find("dofile(\"" .. slash .. "mnt/d/GIT/Other/x.lua\")") ~= nil, "a WSL drive mount")
  assertTrue(find("local p = '" .. slash .. "home/someone/GIT/x'") ~= nil, "a Linux home")
  assertTrue(find("local p = '" .. slash .. "Users/someone/GIT/x'") ~= nil, "a macOS home")
  assertTrue(find("local p = [[C:\\" .. "Users\\someone\\x]]") ~= nil, "a Windows profile")
  assertNil(find("Interface\\AddOns\\MultiMeters\\media\\bar.tga"), "a client texture path")
  assertNil(find("local root = arg[0]:match('^(.*)/tests/run%.lua$')"), "the runner's own root")
end)

test("kit limits: the heap budget names the case that crossed it", function()
  local limits = Kit.__limits
  local saved = limits.heapMB
  limits.heapMB = 1
  local held = {}
  for i = 1, 60000 do held[i] = { i } end
  local failure = Kit.__heapFailure({ name = "an allocating case" })
  limits.heapMB = saved
  assertTrue(held[1] ~= nil and failure ~= nil, "a live heap over the budget fails")
  assertTrue(failure:find("an allocating case", 1, true) ~= nil, "and names the case: " .. failure)
end)

test("kit limits: the leak gate counts what is still held, not garbage waiting to be swept", function()
  local limits = Kit.__limits
  local saved = limits.leakMB
  limits.leakMB = 2
  collectgarbage("collect")
  local base = collectgarbage("count") / 1024
  local holder = { items = {} }
  for i = 1, 60000 do holder.items[i] = { i } end
  local leaked = Kit.__leakFailure(base, "test_holding")
  holder.items = nil
  assertNil(holder.items, "the fixture let go of what it held")
  collectgarbage("collect")
  for i = 1, 60000 do local _ = { i } end
  local swept = Kit.__leakFailure(base, "test_garbage")
  limits.leakMB = saved
  assertTrue(leaked ~= nil and leaked:find("test_holding.lua", 1, true) ~= nil,
    "held memory over the budget fails, naming the suite: " .. tostring(leaked))
  assertNil(swept, "garbage alone never fails the gate")
end)
