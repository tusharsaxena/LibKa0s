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
-- The comparison is over raw bytes read in binary mode. It deliberately does not normalise line
-- endings: every file here is pinned CRLF by .gitattributes, and a copy that arrived through an
-- LF-normalising path is exactly one of the regressions this repo has had.

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

--- Index of the first differing byte between two strings, or nil when they are equal.
local function firstDiff(a, b)
  local n = math.min(#a, #b)
  for i = 1, n do
    if a:byte(i) ~= b:byte(i) then return i end
  end
  if #a ~= #b then return n + 1 end
  return nil
end

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
