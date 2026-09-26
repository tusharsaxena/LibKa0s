-- tests/test_kitsync.lua - the vendoring gate for the test kit itself.
--
-- This repo consumes its own kit through tests/_kit/ so that LibKa0s is a consumer on exactly the
-- same terms as every addon (see the header of tests/run.lua). docs/releasing.md then asks for a
-- MANUAL `diff -r testkit tests/_kit` at release time, and a manual step is one that gets skipped:
-- the documentation milestone before this suite existed improved testkit/README.md, did not
-- re-vendor it, and shipped the divergence with three documents asserting the copies matched. Both
-- copies keep working when they drift, so nothing else in the suite goes red. This file is that
-- diff, mechanised.
--
-- Two properties, both required:
--   * the same SET of filenames in both directories, so a kit file added to one and not the other
--     is caught even though every existing file still matches;
--   * byte-identical CONTENT for every one of them, README.md included. The file that actually
--     diverged was a README, so a check restricted to *.lua would have caught nothing.
--
-- The comparison is over raw bytes read in binary mode. It deliberately does not normalize line
-- endings: every file here is pinned CRLF by .gitattributes, and a copy that arrived through an
-- LF-normalizing path is exactly one of the regressions this repo has had.

local T = _G.LK_TEST
local test, fail = T.test, T.fail

local SRC = "testkit"
local DST = "tests/_kit"

--- Read a whole file as bytes, or nil if it cannot be opened.
local function readBytes(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local data = f:read("*a")
  f:close()
  return data
end

--- List the plain files in a directory, as a sorted array of basenames.
---
--- Lua 5.1 has no directory API and this repo does not depend on LuaFileSystem, so the listing
--- shells out. `ls -A` covers every shell the suite is actually run under (Linux, WSL, macOS, Git
--- Bash); `dir /b` is the cmd.exe fallback. If neither yields anything the test FAILS rather than
--- passing on an empty set - a gate that goes quiet when it cannot look is worse than no gate.
local function listDir(dir)
  local names = {}
  local function collect(cmd)
    local p = io.popen(cmd)
    if not p then return end
    for line in p:lines() do
      local name = line:gsub("[\r\n]+$", "")
      if name ~= "" and name ~= "." and name ~= ".." then names[#names + 1] = name end
    end
    p:close()
  end
  collect('ls -A "' .. dir .. '" 2>/dev/null')
  if #names == 0 then collect('dir /b "' .. dir:gsub("/", "\\") .. '" 2>NUL') end
  if #names == 0 then
    fail("kit sync: could not list " .. dir .. "/ - no `ls -A` and no `dir /b`; this gate cannot "
      .. "run, and must not be reported as passing", 2)
  end
  table.sort(names)
  return names
end

--- The git INDEX mode of a tracked path ("100644", "100755", ...), or nil if git cannot answer.
---
--- `git ls-files -s` prints `<mode> <sha> <stage>\t<path>`. The mode is read from the INDEX and
--- never from the filesystem, which is the whole point: this tree is DrvFs, every file reports
--- `rwxrwxrwx` to `ls -l` and to Lua, and every repo in the collection sets `core.fileMode=false`
--- so git ignores the on-disk bit as well. The index is the only place the executable bit for a
--- vendored file actually lives, and therefore the only place a gate can look.
local function indexMode(path)
  local p = io.popen('git ls-files -s -- "' .. path .. '" 2>/dev/null')
  if not p then return nil end
  local line = p:read("*l")
  p:close()
  if not line then return nil end
  return line:match("^(%d+)%s")
end

--- Index of the first differing byte between two strings, or nil when they are equal.
local function firstDiff(a, b)
  local n = math.min(#a, #b)
  for i = 1, n do
    if a:byte(i) ~= b:byte(i) then return i end
  end
  if #a ~= #b then return n + 1 end
  return nil
end

test("kitsync: Kit.VERSION is a positive integer and reaches the exposed table", function()
  local v = T.KIT_VERSION
  if type(v) ~= "number" or v < 1 or v % 1 ~= 0 then
    fail("kit version: Kit.VERSION must be a positive integer, got " .. tostring(v)
      .. " - it is set at the top of testkit/framework.lua and merged in by Kit.expose", 2)
  end
end)

test("kitsync: the kit revision has an API document", function()
  -- The same bargain test_versioning.lua strikes for the library's minors: a bump that lands
  -- without its document leaves adopters with a version nothing describes. The kit is vendored to
  -- six repos and its own README tells a reader to go to docs/api/ for the surface, so a missing
  -- document is a dead pointer in six places at once.
  local path = "docs/api/testkit/version-" .. tostring(T.KIT_VERSION) .. "-docs.md"
  local f = io.open(path, "r")
  if not f then
    fail("kit version: Kit.VERSION is " .. tostring(T.KIT_VERSION) .. " but " .. path
      .. " does not exist - a kit revision is not released until its API document is written "
      .. "(see docs/api/README.md)", 2)
  end
  f:close()
end)

test("kitsync: the kit revision is indexed in docs/api/README.md as the one Current revision", function()
  -- docs/api/README.md's "Adding a version" ends with "Add the row to the table above". A revision
  -- whose document exists but whose row does not leaves the index naming the previous revision as
  -- Current, which is the question the index exists to answer.
  -- red under: writing version-N-docs.md and marking N-1 Superseded without touching the index
  local index = readBytes("docs/api/README.md")
  if not index then fail("kit index: docs/api/README.md cannot be read", 2) end
  local want, current = tostring(T.KIT_VERSION), {}
  for line in index:gmatch("[^\n]+") do
    local v = line:match("^| %[(%d+)%]%(%./testkit/version%-%d+%-docs%.md%)")
    if v and line:match("| %*%*Current%*%* |%s*$") then current[#current + 1] = v end
  end
  if #current ~= 1 or current[1] ~= want then
    fail("kit index: Kit.VERSION is " .. want .. " but docs/api/README.md's testkit table marks "
      .. (#current == 0 and "no revision" or table.concat(current, ", ")) .. " Current - add revision "
      .. want .. "'s row and mark the one before it Superseded", 2)
  end
end)

test("kitsync: the runner is mode 100755 in the git index, in BOTH copies", function()
  -- The runner shipped `100644` in all nine repos of the collection, source included. Nobody could
  -- see it: `core.fileMode=false` everywhere means git never complains, and DrvFs reports
  -- `rwxrwxrwx` for every file so `ls -l` says it is executable when the index says it is not. The
  -- manual `chmod +x` the playbook asked for was missed by four of four adopters, which is evidence
  -- about the step rather than about the adopters.
  --
  -- The exec bit does not travel with `cp` and it is not in the file's bytes, so the byte-identity
  -- case below cannot see this and never will. It needs its own gate, on the index, in both copies:
  -- `testkit/` is what every consumer vendors FROM, and `tests/_kit/` is this repo's own copy, which
  -- is the one that would silently drop the bit on the next re-vendor.
  for _, path in ipairs({ SRC .. "/run-automated-tests.sh", DST .. "/run-automated-tests.sh" }) do
    local mode = indexMode(path)
    if not mode then
      fail("kit sync: `git ls-files -s -- " .. path .. "` returned nothing - either the path is "
        .. "untracked or git is not available here; this gate cannot run, and must not be reported "
        .. "as passing", 2)
    end
    if mode ~= "100755" then
      fail("kit sync: " .. path .. " is mode " .. mode .. " in the git index, not 100755 - a "
        .. "consumer that vendors it gets a file they cannot execute. Fix with `git update-index "
        .. "--chmod=+x " .. path .. "`. NOTE: `ls -l` is not evidence here - this tree is DrvFs and "
        .. "reports rwxrwxrwx for everything", 2)
    end
  end
end)

test("kitsync: testkit/ and tests/_kit/ hold the same set of files", function()
  local src = table.concat(listDir(SRC), ", ")
  local dst = table.concat(listDir(DST), ", ")
  -- Raised directly rather than through assertEqual so the reported location is this file and not
  -- the kit's own assertion helper - the point of the message is the two file lists.
  if src ~= dst then
    fail("kit sync: " .. SRC .. "/ and " .. DST .. "/ disagree on which files exist - " .. SRC
      .. "/ has [" .. src .. "], " .. DST .. "/ has [" .. dst
      .. "]; re-vendor with `cp -r testkit/. tests/_kit/`", 2)
  end
end)

test("kitsync: testkit/asserts.lua, inventory.lua, prose_lists.lua, prose_coverage.lua and prose_selftests.lua exist in both testkit/ and tests/_kit/", function()
  -- Kit revision 26 peeled framework.lua's assertion and parity families into asserts.lua, and
  -- test_prose.lua's published lists into prose_lists.lua, to take both files under layout-§1's cap;
  -- revision 28 peeled framework.lua's suite inventory and path helpers into inventory.lua, and
  -- revision 29 test_prose.lua's narrowing machinery into prose_coverage.lua and its self-tests
  -- into prose_selftests.lua (issue #39).
  -- All five are loaded by path from beside their parent, so a copy that drops any one breaks the
  -- kit at load. The set-equality case above catches a file missing from ONE side; this one catches
  -- the peel being undone on both.
  -- red under: any of the five absent from testkit/ or tests/_kit/
  local PROSE = { ["prose_lists.lua"] = true, ["prose_coverage.lua"] = true, ["prose_selftests.lua"] = true }
  for _, name in ipairs({ "asserts.lua", "inventory.lua", "prose_lists.lua", "prose_coverage.lua",
                          "prose_selftests.lua" }) do
    for _, dir in ipairs({ SRC, DST }) do
      if readBytes(dir .. "/" .. name) == nil then
        fail("kit sync: " .. dir .. "/" .. name .. " is missing - the kit loads it from "
          .. "beside " .. (PROSE[name] and "test_prose.lua" or "framework.lua")
          .. "; re-vendor with `cp -r testkit/. tests/_kit/`", 2)
      end
    end
  end
end)

test("kitsync: every kit file is byte-identical in testkit/ and tests/_kit/, README included", function()
  for _, name in ipairs(listDir(SRC)) do
    local srcPath, dstPath = SRC .. "/" .. name, DST .. "/" .. name
    local a = readBytes(srcPath)
    local b = readBytes(dstPath)
    if a == nil then fail("kit sync: cannot read " .. srcPath, 2) end
    if b == nil then
      fail("kit sync: " .. dstPath .. " is missing - re-vendor with `cp -r testkit/. tests/_kit/`", 2)
    end
    local at = firstDiff(a, b)
    if at then
      -- Name the file, and say where and how it differs: "the kit is out of sync" on its own costs
      -- the next person the manual diff this test exists to remove.
      fail(string.format(
        "kit sync: %s and %s DIFFER - first difference at byte %d (%s is %d bytes, %s is %d bytes)"
        .. "; re-vendor with `cp -r testkit/. tests/_kit/`",
        srcPath, dstPath, at, srcPath, #a, dstPath, #b), 2)
    end
  end
end)

-- ── the consumer gate's runner-mode case (LibKa0s#28) ─────────────────────────────────────────
--
-- `automated-tests-§2` MUSTs that the vendored-payload gate assert `tests/_kit/run-automated-tests.sh`
-- is recorded 100755. The case above asserts it for THIS repo's two copies; the case below is the
-- one `vendor_sync.lua` registers in every consumer. LibKa0s cannot run that gate end to end (there
-- is no sibling to compare against), so its cases are driven here through a stand-in test table and
-- only the runner-mode case is executed. Its default path is right in this repo too: LibKa0s vendors
-- its own kit to `tests/_kit/` exactly as a consumer does.

local VendorSync = dofile("tests/_kit/vendor_sync.lua")
local RUNNER_CASE = "the automated-test runner is recorded executable (100755)"

--- Register VendorSync's cases on a stand-in test table and return the runner-mode case's body.
local function runnerCase(opts)
  local body
  local stand = {
    test = function(name, fn) if name == RUNNER_CASE then body = fn end end,
    skip = T.skip, fail = T.fail, assertTrue = T.assertTrue, assertEqual = T.assertEqual,
  }
  VendorSync.register(stand, opts)
  if not body then
    fail("kit sync: vendor_sync.lua registers no case named `" .. RUNNER_CASE .. "`", 2)
  end
  return body
end

--- Run a case body: "pass"; "skip" and its reason; or "fail" and its message.
local function outcome(body)
  local ok, err = pcall(body)
  if ok then return "pass" end
  if type(err) == "table" and err.reason then return "skip", err.reason end
  return "fail", tostring(err)
end

test("kitsync: vendor_sync checks the runner's recorded mode, and this repo's copy passes", function()
  local status, detail = outcome(runnerCase({}))
  T.assertEqual(status, "pass", "the runner-mode case on tests/_kit/run-automated-tests.sh: "
    .. tostring(detail))
end)

test("kitsync: the runner-mode case fails on a path the index records 100644", function()
  local status, detail = outcome(runnerCase({ runner = "tests/run.lua" }))
  T.assertEqual(status, "fail", "a 100644 runner failed")
  T.assertTrue(detail:find("100644", 1, true) ~= nil, "and the message names the mode: " .. detail)
end)

test("kitsync: the runner-mode case fails on a path the index does not track", function()
  local status, detail = outcome(runnerCase({ runner = "tests/_kit/no-such-runner.sh" }))
  T.assertEqual(status, "fail", "an untracked runner failed")
  T.assertTrue(detail:find("not tracked", 1, true) ~= nil, "and the message says so: " .. detail)
end)

test("kitsync: the runner-mode case skips, with a reason, where there is no work tree", function()
  local status, reason = outcome(runnerCase({ root = "/nonexistent/libka0s-runner-probe" }))
  T.assertEqual(status, "skip", "no work tree is a skip, never a pass")
  T.assertTrue(reason:find("NOT checked", 1, true) ~= nil, "and the reason says so: " .. reason)
end)

test("kitsync: the runner-mode case skips, with a reason, where io.popen is unavailable", function()
  local body = runnerCase({})
  -- rawset rather than assignment: `io` is a standard table luacheck rightly treats as read-only,
  -- and this is the one place a case has to take a piece of it away and put it back.
  local saved = io.popen
  rawset(io, "popen", nil)
  local status, reason = outcome(body)
  rawset(io, "popen", saved)
  T.assertEqual(status, "skip", "no io.popen is a skip, never a pass")
  T.assertTrue(reason:find("io.popen", 1, true) ~= nil, "and the reason names it: " .. reason)
end)
