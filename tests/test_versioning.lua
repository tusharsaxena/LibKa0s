-- tests/test_versioning.lua — the versioning contract.
--
-- LibStub picks a winner between vendored copies by comparing MINOR integers, so a released change
-- that does not bump its file's minor is invisible: every host that already carries the old copy
-- keeps running it, and the fix silently does not ship. Nothing in Lua can notice that on its own,
-- which is why the discipline is pinned here — the one part of it a test CAN enforce is that code and
-- changelog agree about what version each file is at.
--
-- See docs/releasing.md for the order of operations these tests exist to protect.

local T = _G.LK_TEST
local lib = T.lib
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

local function readFile(path)
  local f = io.open(path, "r")
  assertTrue(f ~= nil, "cannot open " .. path .. " (tests run from the repo root)")
  local body = f:read("*a")
  f:close()
  return body
end

test("versioning: every file in the major registers its live version", function()
  assertTrue(type(lib.MODULES) == "table", "lib.MODULES exists")
  -- Both files of LibKa0s-Perf-1.0. A new file added to this major without a MODULES entry makes
  -- version skew unanswerable from in-game, so the list is asserted explicitly rather than counted.
  assertTrue(lib.MODULES.Perf ~= nil, "Perf registers")
  assertTrue(lib.MODULES.PerfPanel ~= nil, "PerfPanel registers")
  assertEqual(lib.MODULES.Perf, lib.MINOR, "the probe's entry is the major's own minor")
end)

test("versioning: every registered version is a positive integer", function()
  for name, minor in pairs(lib.MODULES) do
    assertTrue(type(minor) == "number", name .. " minor is a number")
    assertEqual(minor, math.floor(minor), name .. " minor is an integer — LibStub compares integers")
    assertTrue(minor >= 1, name .. " minor is at least 1")
  end
end)

test("versioning: the changelog accounts for the version every file is at", function()
  local changelog = readFile("CHANGELOG.md")
  -- Every miss is collected before failing. Asserting inside the loop would abort on the first
  -- missing entry and leave the rest unchecked — which is exactly how this test's own first run
  -- reported one gap while hiding a second.
  local missing = {}
  for name, minor in pairs(lib.MODULES) do
    -- Loose about wording, strict about the pair: any line may carry it, but the file's name and its
    -- current number must both appear. This is what fails when someone bumps a minor and forgets the
    -- entry, or writes an entry for a bump they did not make.
    local needle = ("%s minor %d"):format(name, minor)
    if not changelog:find(needle, 1, true) then missing[#missing + 1] = needle end
  end
  table.sort(missing)
  assertEqual(table.concat(missing, ", "), "",
    "CHANGELOG.md is missing these — a bump and its changelog entry must move together")
end)

test("versioning: the panel records which probe it attached to", function()
  -- The pairing guard's own state. Asserted because a panel silently attached to a probe from a
  -- different vendored copy is the failure the single-major layout is supposed to make impossible,
  -- and tests/test_perf_isolation.lua's two-copy simulation depends on this field being maintained.
  assertEqual(lib.__panelProbeMinor, lib.MINOR,
    "the attached panel was built against the live probe")
  assertEqual(lib.__panelMinor, lib.MODULES.PerfPanel, "and reports its own version consistently")
end)
