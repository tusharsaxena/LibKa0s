-- testkit/framework.lua — the test registry, the assertions, the runner and the `--list` renderer.
--
-- COLLECT-THEN-RUN, deliberately. Some runners in the collection execute each case body at
-- registration time and short-circuit it in list mode, which makes `--list` a second code path
-- through the same file — so the inventory can disagree with the run. Here `test()` only records,
-- and nothing executes until run(). `--list` is then a pure filter over the registry and cannot
-- drift from what actually runs.

local Kit = {}

--- The kit revision. A plain integer, bumped on every released change to ANY file in `testkit/`,
--- because the three files vendor as one folder and are never adopted separately.
---
--- This is NOT a LibStub minor and does NOT make the kit a library: nothing registers it, no load
--- order depends on it, and two copies never negotiate — the vendoring gate is byte-identity, not
--- version comparison (`tests/test_kitsync.lua`). What it buys is the one question byte-identity
--- cannot answer on its own: *which* kit is a given consumer holding? Before this, "AbsorbTracker's
--- kit is stale" was only reachable by diffing against this repo at the right commit. Now the
--- consumer can say so itself, and its API document has a name.
Kit.VERSION = 8

local tests = {}
local currentSuite  -- basename (no extension) of the suite file currently being dofile'd

--- Register a case.
---
--- `skipReason`, when given, registers the case as a DECLARED skip: `fn` is never called, the run
--- reports it as SKIP, and `--list` discloses the reason. That is the only kind of skip `--list` can
--- see, because `--list` never executes a case body (see the header) — a skip decided inside a body
--- is reported by the run, not by the inventory.
function Kit.test(name, fn, skipReason)
  tests[#tests + 1] = { name = name, fn = fn, suite = currentSuite, skip = skipReason }
end

-- ── skip ───────────────────────────────────────────────────────────────────────────────────
--
-- A third status, and the reason it exists: a case that CANNOT LOOK — no sibling checkout, no
-- git, a fixture the platform cannot produce — used to be written as a bare `return`, which
-- registers as PASS. Six repos in this collection did exactly that, so six green gates were
-- reporting "checked and fine" for a check that never ran.
--
-- Implemented as a sentinel error so it works from inside a case body, at any depth, without
-- restructuring the case into a predicate plus a body. Two properties are NON-NEGOTIABLE and are
-- asserted by the consumers that depend on them:
--
--   * a skip is NEVER folded into `passed` — the README [tests] badge and docs/test-cases.md
--     count passes, and a skip counted as one is the original lie in a new place;
--   * a skip NEVER changes the exit code — the same script is the commit gate, and the release
--     gate reads `suites.tests.failed` from the run manifest. A skip is "not evaluated", which the
--     release flow judges for itself; it is not a failure to be re-litigated here.

local SKIP = {}

--- Abandon the current case with a reason, reported as SKIP rather than as PASS or FAIL.
--- Never returns.
function Kit.skip(reason)
  error(setmetatable({ reason = tostring(reason or "no reason given") }, SKIP), 0)
end

--- The reason, if `err` is a skip sentinel; nil for any other error value.
local function skipReasonOf(err)
  if type(err) == "table" and getmetatable(err) == SKIP then return err.reason end
  return nil
end

-- ── assertions ─────────────────────────────────────────────────────────────────────────────
--
-- `level + 1` on every failure so the reported line is the CALLER's, not this file's.

local function fail(msg, level) error(msg, (level or 1) + 1) end
Kit.fail = fail

local function fmt(v)
  if type(v) == "table" then return "<table>" end
  return tostring(v)
end

function Kit.assertEqual(got, want, msg)
  if got ~= want then
    fail((msg or "assertEqual") ..
      string.format(" (expected %s, got %s)", fmt(want), fmt(got)), 1)
  end
end

function Kit.assertTrue(c, msg) if not c then fail(msg or "assertTrue failed", 1) end end
function Kit.assertFalse(c, msg) if c then fail(msg or "assertFalse failed", 1) end end

function Kit.assertNil(v, msg)
  if v ~= nil then fail((msg or "assertNil") .. " (got " .. fmt(v) .. ")", 1) end
end

--- Float comparison with an explicit tolerance. Never compare computed geometry with `==`.
function Kit.assertNear(got, want, tolerance, msg)
  tolerance = tolerance or 1e-6
  if type(got) ~= "number" or math.abs(got - want) > tolerance then
    fail((msg or "assertNear") ..
      string.format(" (expected %s +/- %s, got %s)", fmt(want), fmt(tolerance), fmt(got)), 1)
  end
end

--- Assert that calling fn raises. Returns the error message so a caller can assert on its text —
--- an assertion that something raised, without checking WHAT, passes just as happily on a typo in
--- the test itself.
function Kit.assertError(fn, msg)
  local ok, err = pcall(fn)
  if ok then fail(msg or "assertError: expected an error, got none", 1) end
  return tostring(err)
end

--- Merge the registry and assertions into the host's `_G.<X>_TEST` table and return it, so a repo
--- keeps its existing global name and key set and no suite file has to change.
function Kit.expose(t)
  t = t or {}
  t.KIT_VERSION = Kit.VERSION
  t.test        = Kit.test
  t.fail        = Kit.fail
  t.skip        = Kit.skip
  t.assertEqual = Kit.assertEqual
  t.assertTrue  = Kit.assertTrue
  t.assertFalse = Kit.assertFalse
  t.assertNil   = Kit.assertNil
  t.assertNear  = Kit.assertNear
  t.assertError = Kit.assertError
  return t
end

-- ── suite loading ──────────────────────────────────────────────────────────────────────────

local function fileExists(path)
  local f = io.open(path, "r")
  if f then f:close(); return true end
  return false
end

--- Load every suite, stamping each registered case with the file it came from.
---
--- A SUITES entry naming a file that does not exist yet is skipped rather than fatal, so a suite
--- can be listed while it is being written without taking the whole run down with it.
local function loadSuites(dir, suites)
  for _, suite in ipairs(suites) do
    local path = dir .. suite .. ".lua"
    if fileExists(path) then
      currentSuite = suite
      dofile(path)
    end
  end
  currentSuite = nil
end

-- ── `--list` ───────────────────────────────────────────────────────────────────────────────
--
-- Emits the whole body of docs/test-cases.md, CRLF-terminated, and exits 0 without running a
-- single case. CRLF is written HERE rather than left to a `| sed 's/$/\r/'` in the shell: the
-- repos pin `*.md text eol=crlf`, a plain redirect writes LF, and a regeneration command with a
-- pipeline in it is one someone eventually runs without the pipeline.

local function wantsList()
  for _, a in ipairs(arg or {}) do
    if a == "--list" then return true end
  end
  return false
end

local function out(line) io.write((line or ""), "\r\n") end

local function countIn(suite)
  local n = 0
  for _, t in ipairs(tests) do
    if t.suite == suite then n = n + 1 end
  end
  return n
end

local function renderInventory(suites)
  out("# Test Cases")
  out()
  out("The full inventory of every headless test case in this repo, grouped by the suite file it")
  out("lives in. The `## Totals` table below is the **authoritative pass count** — the README test")
  out("badge and any count quoted in the docs must agree with it.")
  out()
  out("**Generated — do not hand-edit.** Regenerate with `lua tests/run.lua --list > docs/test-cases.md`.")

  -- Declared-suite order, not first-seen and not sorted: the suite list is load-order-sensitive and
  -- the inventory should read the way the run reads.
  for _, suite in ipairs(suites) do
    local names = {}
    for _, t in ipairs(tests) do
      if t.suite == suite then
        -- A declared skip is disclosed in the inventory, so a reader of docs/test-cases.md sees
        -- that the case exists AND that it is not currently being evaluated.
        names[#names + 1] = t.skip and (t.name .. " (skipped: " .. t.skip .. ")") or t.name
      end
    end
    if #names > 0 then
      out()
      out(string.format("### %s.lua (%d)", suite, #names))
      out()
      for _, name in ipairs(names) do out("- " .. name) end
    end
  end

  out()
  out("## Totals")
  out()
  out("| Suite | Cases |")
  out("|-------|------:|")
  for _, suite in ipairs(suites) do
    local n = countIn(suite)
    if n > 0 then out(string.format("| %s.lua | %d |", suite, n)) end
  end
  out(string.format("| **Total** | **%d** |", #tests))
end

-- ── run ────────────────────────────────────────────────────────────────────────────────────

--- Load the suites, then either render the inventory or run everything.
--- opts = { dir = "tests/", suites = { ... } }
--- Exits the process: 0 on success, 1 on any failure, so the green gate is a plain shell check.
function Kit.run(opts)
  local dir    = opts.dir or "tests/"
  local suites = opts.suites or {}

  loadSuites(dir, suites)

  if wantsList() then
    renderInventory(suites)
    os.exit(0)
  end

  local passed, failed, skipped = 0, 0, 0
  for _, t in ipairs(tests) do
    if t.skip then
      skipped = skipped + 1
      print("  SKIP  " .. t.name .. " — " .. t.skip)
    else
      local ok, err = pcall(t.fn)
      local reason = (not ok) and skipReasonOf(err) or nil
      if reason then
        skipped = skipped + 1
        print("  SKIP  " .. t.name .. " — " .. reason)
      elseif ok then
        passed = passed + 1
        print("  PASS  " .. t.name)
      else
        failed = failed + 1
        print("  FAIL  " .. t.name .. "\n          " .. tostring(err))
      end
    end
  end
  -- Skips are their own column and are NOT added to `passed`; the exit code is still `failed == 0`.
  print(string.format("\n%d passed, %d failed, %d skipped, %d total",
    passed, failed, skipped, passed + failed + skipped))
  os.exit(failed == 0 and 0 or 1)
end

--- The live registry, for the kit's own self-tests.
function Kit.__tests() return tests end

return Kit
