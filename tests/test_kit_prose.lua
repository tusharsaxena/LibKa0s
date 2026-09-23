-- tests/test_kit_prose.lua — which files the kit's prose gate reads, driven over fixture trees.
--
-- WHAT IT PROVES. That `testkit/test_prose.lua` reads the store-root files `documentation-§3` says
-- are rewritten in place (`docs/automated-tests/README.md`, `docs/automated-tests/RESULTS.md`,
-- `docs/perf-analysis/README.md`) although they sit under folders it otherwise skips, that it still
-- skips the dated bundles beside them and the two frozen stores `docs/superpowers/` and
-- `docs/investigations/`, and that it carries `localization-§5`'s lists whole, `synchronis`
-- included. This repository does not wire the kit's copy of the gate (CLAUDE.md, register row 3),
-- so without this file the scan-back would be proved nowhere before a consumer re-vendored it.
--
-- DRIVEN THROUGH THE GATE, NOT AROUND IT, the way `tests/test_kit_eol.lua` drives the eol gate.
-- The walker is a local of a vendored suite and reads the tracked set from `git ls-files` in the
-- working directory, which Lua cannot change. So each case builds a real git index in a temporary
-- directory, starts a child interpreter there, loads the vendored suite with a small stand-in for
-- the kit, and runs the gate's scan case. Its failure text names every hit as `path:line - words`,
-- which is what is read back.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

--- This process's working directory, or nil when nothing here can ask for it.
local function cwd()
  local p = io.popen("pwd 2>/dev/null")
  local here = p and p:read("*l")
  if p then p:close() end
  here = here and here:match("^%s*(.-)%s*$")
  if here == "" then return nil end
  return here
end

--- A fresh temporary directory, or a skip.
local function tempRoot()
  local p = io.popen("mktemp -d 2>/dev/null")
  local made = p and p:read("*l")
  if p then p:close() end
  made = made and made:match("^%s*(.-)%s*$")
  if not made or made == "" then
    T.skip("no `mktemp -d` on this host, so the prose fixtures cannot be built")
  end
  return made .. "/"
end

--- A git index at `root` tracking exactly `files`, a map of path to body.
local function gitFixture(root, files)
  for path, body in pairs(files) do
    local parent = path:match("^(.*)/[^/]+$")
    if parent then os.execute(('mkdir -p "%s%s"'):format(root, parent)) end
    local f = assert(io.open(root .. path, "wb"))
    f:write(body)
    f:close()
  end
  return os.execute(('cd "%s" && git init -q . >/dev/null 2>&1 && git add -A >/dev/null 2>&1')
    :format(root))
end

-- The kit stand-in the child hands the suite: enough to register every case and run the scan.
local STAND_IN = 'local cases = {} '
  .. 'local function no() error("unused", 0) end '
  .. 'local K = { prose = {}, test = function(n, f) cases[#cases + 1] = { n = n, f = f } end, '
  .. 'fail = function(m) error(m, 0) end, skip = function(m) error("SKIP " .. m, 0) end, '
  .. 'assertEqual = function(a, b, m) if a ~= b then error(m, 0) end end, '
  .. 'assertTrue = no, assertFalse = no } '

--- What the vendored prose gate's case whose name carries `needle` says about a repository tracking
--- `files`: `NAME ` and the case name, then `RESULT OK`, or `RESULT FAIL ` and the failure with its
--- whitespace collapsed. The name is printed because the disclosure case carries its figure there.
local function caseVerdict(files, needle)
  local interpreter, here = (rawget(_G, "arg") or {})[-1], cwd()
  if type(interpreter) ~= "string" or not here then
    T.skip("no interpreter path (arg[-1]) or no `pwd`, so the gate cannot be driven in a fixture")
  end
  local root = tempRoot()
  local ok, outText = pcall(function()
    gitFixture(root, files)
    local chunk = (STAND_IN
      .. 'assert(loadfile([[%s/tests/_kit/test_prose.lua]]))(K) '
      .. 'for _, c in ipairs(cases) do if c.n:find([[%s]], 1, true) then '
      .. 'print("NAME " .. c.n) local ok, err = pcall(c.f) '
      .. 'print(ok and "RESULT OK" or ("RESULT FAIL " .. tostring(err):gsub("%%s+", " "))) end end')
      :format(here, needle)
    local p = io.popen(("cd '%s' && '%s' -e '%s' 2>&1"):format(root, interpreter, chunk))
    local text = p and p:read("*a") or ""
    if p then p:close() end
    return text
  end)
  os.execute(('rm -rf "%s"'):format(root))
  if not ok then error(outText, 0) end
  if not outText:find("RESULT ", 1, true) then
    T.skip("the child produced no verdict, so this host cannot drive the gate: "
      .. outText:gsub("%s+", " "):sub(1, 160))
  end
  return outText
end

--- What the vendored prose gate's scan case says about a repository tracking `files`.
local function scanVerdict(files) return caseVerdict(files, "no authored file carries") end

--- A fixture: a clean root README, so the scan always has something to read, plus `extra`.
local function tree(extra)
  local files = { ["README.md"] = "A clean line.\n" }
  for path, body in pairs(extra) do files[path] = body end
  return files
end

-- Built from parts so this file's own prose carries no forbidden spelling.
local ANALYSED = "analy" .. "sed"
local SYNC = "synchroni" .. "sation"

local RED = {
  { "a store-root perf-analysis README is read though its folder is skipped",
    "docs/perf-analysis/README.md", "analys" },
  { "a store-root automated-tests README is read",
    "docs/automated-tests/README.md", "analys" },
  { "a store-root automated-tests RESULTS.md is read",
    "docs/automated-tests/RESULTS.md", "analys" },
}

for _, c in ipairs(RED) do
  local label, path, word = c[1], c[2], c[3]
  test("prose scan-back: " .. label, function()
    local out = scanVerdict(tree{ [path] = "Numbers " .. ANALYSED .. " here.\n" })
    assertTrue(out:find("RESULT FAIL", 1, true) ~= nil, "the gate reddens: " .. out)
    assertTrue(out:find(path .. ":1 - " .. word, 1, true) ~= nil,
      "and names the store-root file, its line and its word: " .. out)
  end)
end

local GREEN = {
  { "a dated perf-analysis bundle stays skipped", "docs/perf-analysis/20260101-000000/ANALYSIS.md" },
  { "a dated automated-tests bundle stays skipped", "docs/automated-tests/20260101-000000/ANALYSIS.md" },
  { "a store-root name one folder down is a bundle file", "docs/perf-analysis/20260101-000000/README.md" },
  { "docs/superpowers/ is a frozen store and skipped", "docs/superpowers/specs/x.md" },
  { "docs/investigations/ is a frozen store and skipped", "docs/investigations/x.md" },
}

for _, c in ipairs(GREEN) do
  local label, path = c[1], c[2]
  test("prose scan-back: " .. label, function()
    local out = scanVerdict(tree{ [path] = "Numbers " .. ANALYSED .. " here.\n" })
    assertEqual(out:match("RESULT %a+"), "RESULT OK", path .. " is not read: " .. out)
  end)
end

test("prose lists: synchronis is published, and a root README carrying it is red", function()
  local out = scanVerdict{ ["README.md"] = "Settings " .. SYNC .. " across profiles.\n" }
  assertTrue(out:find("README.md:1 - synchronis", 1, true) ~= nil, "the root README reddens: " .. out)
end)

test("prose lists: synchronism, synchronisms and synchronistic are allowed", function()
  local out = scanVerdict{ ["README.md"] = "A synchronism, two synchronisms, synchronistic.\n" }
  assertEqual(out:match("RESULT %a+"), "RESULT OK", "the three US words pass: " .. out)
end)

test("prose scan-back: restating the kit's own folder in skipDirs does not un-scan the root README",
function()
  local out = scanVerdict(tree{
    ["docs/perf-analysis/README.md"] = "Numbers " .. ANALYSED .. " here.\n",
    ["tests/prose_waivers.lua"] = 'return { skipDirs = { "docs/perf-analysis/" } }\n',
  })
  assertTrue(out:find("docs/perf-analysis/README.md:1", 1, true) ~= nil,
    "a repository that wants the file unread names it in skipFiles, where the refusals see it: "
    .. out)
end)

-- The restated kit folder, seen by the disclosure and the packaging refusal. The entry suppresses
-- nothing -- the kit already skips the folder, and the scan reads its store-root file back past it
-- -- so both must say so, rather than naming as narrowed a file the scan reads or sending the
-- consumer to .pkgmeta for it.
local function restated(pkgmeta)
  return tree{
    ["docs/perf-analysis/README.md"] = "A clean store root.\n",
    ["tests/prose_waivers.lua"] = 'return { skipDirs = { "docs/perf-analysis/" } }\n',
    ["Fixture.toc"] = "## Interface: 110200\nCore.lua\n",
    [".pkgmeta"] = pkgmeta,
  }
end

test("prose scan-back: a restated kit folder in skipDirs is disclosed as suppressing nothing",
function()
  local out = caseVerdict(restated("ignore:\n  - docs\n"), "this repository declared suppressed")
  assertTrue(out:find("suppressed 0 of ", 1, true) ~= nil, "no file is suppressed: " .. out)
  assertTrue(out:find("docs/perf-analysis/ [skipDirs", 1, true) ~= nil
    and out:find("(0): nothing", 1, true) ~= nil,
    "and the entry is disclosed as covering nothing: " .. out)
  assertTrue(out:find("(1): docs/perf-analysis/README.md", 1, true) == nil,
    "never as covering the store-root file the scan reads: " .. out)
end)

test("prose scan-back: a restated kit folder in skipDirs, not ignored, is refused as matching nothing",
function()
  local out = caseVerdict(restated("ignore:\n  - tests\n"), "is one .pkgmeta keeps out of the zip")
  assertTrue(out:find("RESULT FAIL", 1, true) ~= nil, "the dead entry is refused: " .. out)
  assertTrue(out:find("match nothing", 1, true) ~= nil
    and out:find("docs/perf-analysis/", 1, true) ~= nil,
    "as matching nothing, with its name: " .. out)
  assertTrue(out:find("not ones .pkgmeta", 1, true) == nil,
    "and never sent to .pkgmeta for a file the scan reads: " .. out)
end)

-- An entry .pkgmeta ignores is not refused for matching nothing, which is the refusal's standing
-- contract rather than anything the scan-back changed; the disclosure above is what names it dead.
test("prose scan-back: a restated kit folder in skipDirs that .pkgmeta ignores passes the refusal",
function()
  local out = caseVerdict(restated("ignore:\n  - docs\n"), "is one .pkgmeta keeps out of the zip")
  assertEqual(out:match("RESULT %a+"), "RESULT OK", "nothing it suppresses ships: " .. out)
end)

test("prose lists: PUBLISHED_BRITISH == #BRITISH == 92 and PUBLISHED_ALLOWED == #ALLOWED == 33",
function()
  local lists = dofile("testkit/prose_lists.lua")
  assertEqual(#lists.BRITISH, 92, "BRITISH carries localization-§5's 92 entries")
  assertEqual(lists.PUBLISHED_BRITISH, 92, "and says so")
  assertEqual(#lists.ALLOWED, 33, "ALLOWED carries localization-§5's 33 entries")
  assertEqual(lists.PUBLISHED_ALLOWED, 33, "and says so")
  local set = {}
  for _, d in ipairs(lists.SCAN_BACK or {}) do set[d] = true end
  assertTrue(set["docs/automated-tests/README.md"] and set["docs/automated-tests/RESULTS.md"]
    and set["docs/perf-analysis/README.md"] and #lists.SCAN_BACK == 3,
    "SCAN_BACK names the three store-root files and nothing else")
end)
