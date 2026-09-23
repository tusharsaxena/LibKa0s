-- tests/test_kit_inventory.lua — the suite inventory, and the three ways a gate stops running.
--
-- WHAT IT PROVES. That a declaration is the pair (basename, directory), and that a suite the
-- vendored kit ships which no declaration names is reported — as a collision when the repo wires
-- its own file of that name, as a decline when the repo wrote the decline down, and as a plain hole
-- otherwise. Two of the three are failures. None of the three is a pass.
--
-- WHY IT IS PINNED HERE RATHER THAN LEFT TO THE RUN. Every defect in this area is invisible by
-- construction: a shadowed kit gate leaves the runner's suite list, docs/test-cases.md and the pass
-- count all asserting coverage the run never produced, and six repositories in this collection sat
-- in exactly that state while the key was the bare basename. A gate whose own failure mode is
-- silence cannot be checked by observing that the suite is green, which is testing-12's point, so
-- each shape is driven against a fixture tree and the message is read back.
--
-- THE FIXTURES ARE REAL DIRECTORIES, not a stubbed filesystem. The inventory shells out to `ls -A`
-- and opens files with `io.open`, and a fake for either would be a fake of the exact surface the
-- defect lives on: the revision-25 change is which directory a name is looked up in.
--
-- The decline reader gets the most cases, because it is the one path that can turn a failure into a
-- skip. It is deliberately hard to satisfy — the register row names the rule AND the suite — and
-- this library is why: its own register carries two `localization-5` rows about third-party API
-- identifiers, and a reader keyed on the rule alone would have let either one switch the prose gate
-- off without ever mentioning it.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local assertError = T.assertError

local Kit = dofile("tests/_kit/framework.lua")

-- ── fixtures ───────────────────────────────────────────────────────────────────────────────

local function write(path, body)
  local f = assert(io.open(path, "w"))
  f:write(body or "-- fixture\n")
  f:close()
end

--- A fresh temporary directory, or a skip. `mktemp` is present on every shell the suites run under;
--- a host without one cannot build the fixture, and a case that cannot look says so rather than
--- passing.
local function tempRoot()
  local p = io.popen("mktemp -d 2>/dev/null")
  local made = p and p:read("*l")
  if p then p:close() end
  made = made and made:match("^%s*(.-)%s*$")
  if not made or made == "" then
    T.skip("no `mktemp -d` on this host, so the inventory fixtures cannot be built")
  end
  return made .. "/"
end

--- A repository-shaped fixture — `tests/`, a vendored `tests/_kit/` with a `framework.lua` in it so
--- the kit pass is armed, and `docs/` for a register — carrying the named suite files.
--- Returns the root prefix, the suite directory and the kit directory.
local function fixture(ownSuites, kitSuites)
  local root = tempRoot()
  os.execute(('mkdir -p "%stests/_kit" "%sdocs"'):format(root, root))
  write(root .. "tests/_kit/framework.lua")
  for _, name in ipairs(ownSuites or {}) do write(root .. "tests/" .. name .. ".lua") end
  for _, name in ipairs(kitSuites or {}) do write(root .. "tests/_kit/" .. name .. ".lua") end
  return root, root .. "tests/", root .. "tests/_kit/"
end

--- Run `body` against a fixture and delete the tree afterwards, however the body ended. A skip is
--- re-raised unchanged so it stays a skip.
local function withFixture(ownSuites, kitSuites, body)
  local root, dir, kitDir = fixture(ownSuites, kitSuites)
  local ok, err = pcall(body, root, dir, kitDir)
  os.execute(('rm -rf "%s"'):format(root))
  if not ok then error(err, 0) end
end

--- A `## Documented deviations` register at `host`, carrying `rows` and nothing else.
local function register(root, host, rows, extra)
  local lines = {
    "# Fixture", "", "## Documented deviations", "",
    "| Rule | What differs | Why | Decided | Re-check trigger |",
    "|---|---|---|---|---|",
  }
  for _, row in ipairs(rows) do lines[#lines + 1] = row end
  for _, line in ipairs(extra or {}) do lines[#lines + 1] = line end
  write(root .. host, table.concat(lines, "\n") .. "\n")
end

local function row(rule, differs)
  return ("| `%s` | %s | Because the repo says so | 2026-09-23 | The kit's copy grows a case |")
    :format(rule, differs)
end

local DECLINE = "`tests/_kit/test_prose.lua` is unwired; this repo runs its own test_prose gate"

-- ── the pair key ───────────────────────────────────────────────────────────────────────────

test("a kit suite declared with its directory is covered", function()
  withFixture({ "test_own" }, { "test_prose" }, function(_, dir, kitDir)
    local ok, err = pcall(Kit.assertSuiteInventory, dir,
      { "test_own", { name = "test_prose", dir = kitDir } })
    assertTrue(ok, "a pair-keyed declaration covers the kit's file: " .. tostring(err))
  end)
end)

test("a bare declaration does not cover the kit's file of the same name", function()
  withFixture({ "test_prose" }, { "test_prose" }, function(_, dir, kitDir)
    local err = assertError(function() Kit.assertSuiteInventory(dir, { "test_prose" }) end,
      "a bare name must not answer for the kit's copy")
    assertTrue(err:find(kitDir .. "test_prose.lua", 1, true) ~= nil, "names the kit's path")
    assertTrue(err:find(dir .. "test_prose.lua", 1, true) ~= nil, "names the repo's own path")
    assertTrue(err:find("is what runs", 1, true) ~= nil, "says which of the two is running")
    assertTrue(err:find("never both", 1, true) ~= nil, "says to wire one or the other")
  end)
end)

test("an unreferenced kit suite with no local twin is the same hole", function()
  withFixture({ "test_own" }, { "test_prose" }, function(_, dir, kitDir)
    local err = assertError(function() Kit.assertSuiteInventory(dir, { "test_own" }) end,
      "an unreferenced kit suite is a failure")
    assertTrue(err:find(kitDir .. "test_prose.lua", 1, true) ~= nil, "names the kit's path")
    assertTrue(err:find('dir = "tests/_kit/"', 1, true) ~= nil,
      "names the entry to add, in a spelling a suites list can carry")
    assertTrue(err:find("running zero cases today", 1, true) ~= nil, "says what it costs")
  end)
end)

test("a bare entry whose file ships only in the kit is told which directory it wants", function()
  withFixture({ "test_own" }, { "test_prose" }, function(_, dir, kitDir)
    local err = assertError(function()
      Kit.assertSuiteInventory(dir, { "test_own", "test_prose", { name = "test_prose", dir = kitDir } })
    end, "a declaration pointing at the wrong directory is a missing file")
    assertTrue(err:find("DOES exist", 1, true) ~= nil, "says the kit has the file")
    assertTrue(err:find('dir = "tests/_kit/"', 1, true) ~= nil, "names the directory it wants")
  end)
end)

-- ── the decline, and everything that is not one ────────────────────────────────────────────

test("a recorded decline in docs/ARCHITECTURE.md is a skip, not a hole", function()
  withFixture({ "test_own" }, { "test_prose" }, function(root, dir)
    register(root, "docs/ARCHITECTURE.md", { row("localization-§5", DECLINE) })
    local before = #Kit.__tests()
    local ok, err = pcall(Kit.assertSuiteInventory, dir, { "test_own" })
    assertTrue(ok, "a recorded decline does not fail the run: " .. tostring(err))
    assertEqual(#Kit.__tests(), before + 1, "exactly one case registered")
    local added = Kit.__tests()[#Kit.__tests()]
    assertTrue(added.skip ~= nil, "registered as a declared skip rather than as a live case")
    assertEqual(added.fn, nil, "a declared skip has no body to run")
    assertTrue(added.skip:find("localization", 1, true) ~= nil, "the reason quotes the row's key")
  end)
end)

test("a recorded decline in the root CLAUDE.md is read too", function()
  withFixture({ "test_own" }, { "test_prose" }, function(root, dir)
    register(root, "CLAUDE.md", { row("localization-§5", DECLINE) })
    local ok, err = pcall(Kit.assertSuiteInventory, dir, { "test_own" })
    assertTrue(ok, "a library repo keeps its register in CLAUDE.md: " .. tostring(err))
  end)
end)

test("a decline is reported once however often the inventory is asserted", function()
  withFixture({ "test_own" }, { "test_prose" }, function(root, dir)
    register(root, "docs/ARCHITECTURE.md", { row("localization-§5", DECLINE) })
    local before = #Kit.__tests()
    Kit.assertSuiteInventory(dir, { "test_own" })
    Kit.assertSuiteInventory(dir, { "test_own" })
    assertEqual(#Kit.__tests(), before + 1, "the second assertion adds nothing")
  end)
end)

test("a row keyed to the rule but silent about the suite grants nothing", function()
  withFixture({ "test_own" }, { "test_prose" }, function(root, dir)
    register(root, "docs/ARCHITECTURE.md",
      { row("localization-§5", "`mock_base.lua` reproduces AceTimer's own handle field verbatim") })
    assertError(function() Kit.assertSuiteInventory(dir, { "test_own" }) end,
      "an unrelated row under the same rule must not switch a gate off")
  end)
end)

test("a row that only mentions the repo's own copy grants nothing", function()
  withFixture({ "test_own" }, { "test_prose" }, function(root, dir)
    register(root, "docs/ARCHITECTURE.md", { row("localization-§5",
      "`mock_base.lua` keeps AceTimer's own field name; `tests/test_prose.lua` reddens if it stops matching") })
    assertError(function() Kit.assertSuiteInventory(dir, { "test_own" }) end,
      "this is the row this library actually carries, and it decides nothing about the kit's copy")
  end)
end)

test("a row naming the suite but keyed to another rule grants nothing", function()
  withFixture({ "test_own" }, { "test_prose" }, function(root, dir)
    register(root, "docs/ARCHITECTURE.md", { row("testing-§1", DECLINE) })
    assertError(function() Kit.assertSuiteInventory(dir, { "test_own" }) end,
      "a row filed under the wrong rule is not a decline of this gate")
  end)
end)

test("a row in a subsection of the register is not a deviation row", function()
  withFixture({ "test_own" }, { "test_prose" }, function(root, dir)
    register(root, "docs/ARCHITECTURE.md", {}, {
      "", "### Files over the 1500-line cap", "",
      "| File | Lines | Disposition |", "|---|---|---|",
      "| `localization-§5` | 1600 | " .. DECLINE .. " |",
    })
    assertError(function() Kit.assertSuiteInventory(dir, { "test_own" }) end,
      "the census nested under the register is not the register")
  end)
end)

-- The kit spells the rule `localization-5` in its own table, because a section sign in a shipped
-- string is a byte the ASCII gate stops; a register cell spells it `localization-§5`, because that
-- is how a document writes it. `normRule` is what makes those one key, and it has to hold in both
-- directions -- a row is as free to drop the sign as the table is.
test("`localization-5` and `localization-§5` are the same key", function()
  for _, spelling in ipairs({ "localization-5", "localization-§5", "`localization-§5`" }) do
    withFixture({ "test_own" }, { "test_prose" }, function(root, dir)
      register(root, "docs/ARCHITECTURE.md", { row(spelling, DECLINE) })
      local ok, err = pcall(Kit.assertSuiteInventory, dir, { "test_own" })
      assertTrue(ok, "the section-mark is not what makes a key (" .. spelling .. "): "
        .. tostring(err))
    end)
  end
end)

test("the rule each kit gate serves is written down", function()
  assertEqual(Kit.__kitGateRule.test_prose, "localization-5")
  assertEqual(Kit.__kitGateRule.test_eol, "line-endings-7")
  assertEqual(Kit.__kitGateRule.test_layout_cap, "layout-1")
end)

test("a repository with no register at all is not accidentally declined", function()
  withFixture({ "test_own" }, { "test_prose" }, function(_, dir)
    assertError(function() Kit.assertSuiteInventory(dir, { "test_own" }) end,
      "no register means no decline")
  end)
end)

-- ── loadSuites, which is where the absence is caught rather than buried ────────────────────

test("a listed suite that is not on disk raises, naming the path and the position", function()
  withFixture({ "test_own" }, {}, function(_, dir)
    local err = assertError(function() Kit.__loadSuites(dir, { "test_own", "test_gone" }) end,
      "a listed-but-absent suite is an error, never a skip")
    assertTrue(err:find(dir .. "test_gone.lua", 1, true) ~= nil, "names the path")
    assertTrue(err:find("position 2", 1, true) ~= nil, "names the declaration's position")
  end)
end)

test("a listed suite that is absent here but ships in the kit is told so", function()
  withFixture({ "test_own" }, { "test_prose" }, function(_, dir, kitDir)
    local err = assertError(function() Kit.__loadSuites(dir, { "test_own", "test_prose" }) end,
      "the bare entry points at a file that is not there")
    assertTrue(err:find("DOES exist", 1, true) ~= nil, "says the kit has it")
    assertTrue(err:find('dir = "tests/_kit/"', 1, true) ~= nil, "names the directory it wants")
    assertTrue(err:find('dir = "' .. kitDir .. '"', 1, true) == nil,
      "and never this checkout's own absolute path, which no suites list could carry")
  end)
end)

test("a `pending` entry with no file registers a skip carrying its reason", function()
  withFixture({ "test_own" }, {}, function(_, dir)
    local before = #Kit.__tests()
    Kit.__loadSuites(dir, { { name = "test_ghost", pending = "half written, landing next week" } })
    assertEqual(#Kit.__tests(), before + 1, "one case registered")
    local added = Kit.__tests()[#Kit.__tests()]
    assertEqual(added.skip, "half written, landing next week", "the reason is carried, not dropped")
    assertEqual(added.fn, nil, "nothing to run")
  end)
end)

test("a `pending` entry whose file exists raises", function()
  withFixture({ "test_own" }, {}, function(_, dir)
    local err = assertError(function()
      Kit.__loadSuites(dir, { { name = "test_own", pending = "half written" } })
    end, "a pending marker left on a written suite is a lie about the tree")
    assertTrue(err:find("drop the `pending` field", 1, true) ~= nil, "says what to do about it")
    assertTrue(err:find(dir .. "test_own.lua", 1, true) ~= nil, "names the path")
  end)
end)

-- ── the revision ───────────────────────────────────────────────────────────────────────────

test("the kit is revision 25", function()
  assertEqual(Kit.VERSION, 25, "testing-9, localization-5 and layout-1 cite revision 25 by name")
  assertEqual(T.KIT_VERSION, 25, "and `Kit.expose` publishes it to every consumer")
end)

-- ── path spellings ──────────────────────────────────────────────────────────────────────────
--
-- WHY THIS SECTION EXISTS. The pair key compares directories, and two of the eleven consumers
-- resolve their root out of `arg[0]` and fall back to `"."`, so their runner reaches the kit with
-- `dir = "./tests/"` while their declaration says `dir = "tests/_kit/"` -- the literal form
-- `testing-9` prescribes. Compared as raw strings those are two directories, and the gate reported
-- a collision against a compliant repo, told it to delete a vendored file, and took the whole
-- suite and `--list` down with it from `Kit.run`. The cases below pin the normalizer that closes
-- it, in both directions: the false collision must not be reported, and a real one still must be.

--- This process's working directory, or nil when nothing here can ask for it.
local function cwd()
  local p = io.popen("pwd 2>/dev/null")
  local here = p and p:read("*l")
  if p then p:close() end
  here = here and here:match("^%s*(.-)%s*$")
  if here == "" then return nil end
  return here
end

--- Assert the inventory the way a consumer actually reaches it: a child `lua` started FROM the
--- fixture root, so `dir` and the declaration are the relative spellings the runners really use.
--- Returns the child's one result line.
---
--- A child rather than a direct call, because the defect is about relative paths and Lua cannot
--- change its own working directory -- an in-process case could only ever approximate the spelling
--- with an absolute prefix in front of it (the case below this one does exactly that, so a host
--- with no shell still catches a revert).
local function inventoryFrom(root, dirSpelling, suitesLiteral)
  local interpreter, here = (rawget(_G, "arg") or {})[-1], cwd()
  if type(interpreter) ~= "string" or not here then
    T.skip("no interpreter path (arg[-1]) or no `pwd`, so the consumer's own spelling cannot be driven")
  end
  local chunk = ('local K = dofile([[%s/tests/_kit/framework.lua]]) '
    .. 'local ok, err = pcall(K.assertSuiteInventory, [[%s]], %s) '
    .. 'print(ok and "RESULT OK" or ("RESULT FAIL " .. tostring(err):gsub("%%s+", " ")))')
    :format(here, dirSpelling, suitesLiteral)
  local cmd = ("cd '%s' && KA0S_KIT_GUARD=off '%s' -e '%s' 2>&1")
    :format(root, interpreter, chunk)
  local p = io.popen(cmd)
  local outText = p and p:read("*a") or ""
  if p then p:close() end
  local line = outText:match("RESULT [^\n]*")
  if not line then
    T.skip("the child runner produced no result line, so this host cannot drive the spelling: "
      .. outText:gsub("%s+", " "):sub(1, 160))
  end
  return line
end

test("a `tests/_kit/` declaration covers the kit against a runner dir of `./tests/`", function()
  withFixture({}, { "test_prose" }, function(root)
    local line = inventoryFrom(root, "./tests/", '{ { name = "test_prose", dir = "tests/_kit/" } }')
    assertEqual(line, "RESULT OK",
      "the two spellings name one directory; a collision here is the gate failing a compliant repo")
  end)
end)

test("a real shadow is still reported when the runner dir is spelled `./tests/`", function()
  withFixture({ "test_prose" }, { "test_prose" }, function(root)
    local line = inventoryFrom(root, "./tests/", '{ "test_prose" }')
    assertTrue(line:find("RESULT FAIL", 1, true) == 1, "a genuine shadow is still a failure")
    assertTrue(line:find("never both", 1, true) ~= nil, "and still says to wire one or the other")
  end)
end)

test("a `./` segment inside the runner dir does not fork the pair key", function()
  withFixture({}, { "test_prose" }, function(root, _, kitDir)
    local ok, err = pcall(Kit.assertSuiteInventory, root .. "./tests/",
      { { name = "test_prose", dir = kitDir } })
    assertTrue(ok, "one directory reached by two spellings is one directory: " .. tostring(err))
  end)
end)

test("a doubled slash and a missing trailing slash are the same directory", function()
  withFixture({}, { "test_prose" }, function(root)
    local ok, err = pcall(Kit.assertSuiteInventory, root .. "tests//",
      { { name = "test_prose", dir = root .. "tests/_kit" } })
    assertTrue(ok, "`tests//` and `tests/_kit` are not new directories: " .. tostring(err))
  end)
end)

test("the directory normalizer folds only the spellings it claims to", function()
  local norm = Kit.__normDir
  assertEqual(norm("./tests/"), "tests/", "a leading `./` is not part of the name")
  assertEqual(norm("././tests/"), "tests/", "however many times it was written")
  assertEqual(norm("tests//_kit//"), "tests/_kit/", "a doubled slash is one slash")
  assertEqual(norm("tests/./_kit"), "tests/_kit/", "an interior `/./` goes, and the tail gains its slash")
  assertEqual(norm("/abs/tests/"), "/abs/tests/", "an absolute path keeps its leading slash")
  assertEqual(norm("."), "./", "the working directory keeps a spelling `ls -A` can take")
  assertEqual(norm(""), "", "but nothing at all stays nothing: that is no directory, not `here`")
  assertEqual(norm("tests/../tests/"), "tests/../tests/",
    "`..` is left alone: collapsing it lexically is wrong the moment the first segment is a symlink")
end)

-- ── two spellings of one directory, mixed in ONE suites list ───────────────────────
--
-- Not hypothetical: KickCD and MultiMeters each take `root` from `arg[0]` with a `"."` fallback,
-- hand `Kit.run` `root .. "/tests/"`, then declare one kit suite as `root .. "/tests/_kit/"` and
-- the next as a bare `"tests/_kit/"`. Run from the repo root the fallback makes `root` `"."` and
-- the two spellings fold together, which is why this was green in all eleven repos. Invoked BY
-- PATH -- a wrapper script, an editor's runner, a CI step -- `root` is absolute and the bare entry
-- keys against a different string from the very directory it names, so the gate reported a
-- correctly wired suite as both missing and undeclared and aborted before a case ran.

test("a relative declaration is not a collision under an absolute runner dir", function()
  withFixture({}, { "test_prose" }, function(root)
    local ok, err = pcall(Kit.assertSuiteInventory, root .. "tests/",
      { { name = "test_prose", dir = "tests/_kit/" } })
    assertTrue(ok, "the entry is read against the runner's root, which is what it was written "
      .. "relative to: " .. tostring(err))
  end)
end)

test("an absolute declaration is not a collision under a relative runner dir", function()
  withFixture({}, { "test_prose" }, function(root)
    local line = inventoryFrom(root, "tests/",
      ('{ { name = "test_prose", dir = [[%stests/_kit/]] } }'):format(root))
    assertEqual(line, "RESULT OK", "the mirror spelling names the same one directory")
  end)
end)

test("a mixed suites list survives being invoked from another working directory", function()
  withFixture({}, { "test_eol", "test_prose" }, function(root)
    local line = inventoryFrom(root .. "tests/_kit/", root .. "tests/",
      ('{ { name = "test_prose", dir = "tests/_kit/" }, '
        .. '{ name = "test_eol", dir = [[%stests/_kit/]] } }'):format(root))
    assertEqual(line, "RESULT OK",
      "this is KickCD's and MultiMeters' list verbatim, run the way a wrapper runs it")
  end)
end)

test("the remedy names a `dir` a suites list can actually carry", function()
  withFixture({}, { "test_prose" }, function(root, _, kitDir)
    local err = assertError(function() Kit.assertSuiteInventory(root .. "tests/", {}) end,
      "an unwired kit gate is a failure whatever the runner dir is spelled like")
    assertTrue(err:find('dir = "tests/_kit/"', 1, true) ~= nil,
      "the entry to paste is repo-relative")
    assertTrue(err:find('dir = "' .. kitDir .. '"', 1, true) == nil,
      "this checkout's absolute path is never offered as something to paste")
    assertTrue(err:find("same root expression", 1, true) ~= nil,
      "it says where the prefix comes from instead of inventing one")
  end)
end)

test("the two sides are resolved against each other, and only where they differ", function()
  local resolve = Kit.__resolveDir
  assertEqual(resolve("tests/_kit/", "/abs/repo/tests/"), "/abs/repo/tests/_kit/",
    "a relative entry takes the absolute runner's root")
  assertEqual(resolve("/abs/repo/tests/_kit/", "tests/"), "tests/_kit/",
    "and the mirror is cut back at the runner's own directory")
  assertEqual(resolve("tests/_kit/", "tests/"), "tests/_kit/", "two relatives are left alone")
  assertEqual(resolve("/a/tests/_kit/", "/a/tests/"), "/a/tests/_kit/", "so are two absolutes")
  assertEqual(resolve(nil, "tests/"), "tests/", "no `dir` still means the runner's own")
  assertEqual(resolve("/elsewhere/kit/", "tests/"), "/elsewhere/kit/",
    "an absolute entry sharing no anchor with the runner is not given an invented one")
  assertEqual(resolve("/a/tests/b/tests/_kit/", "tests/"), "tests/_kit/",
    "the LAST occurrence, so a checkout that itself lives under a `tests/` cuts in the right place")
end)

test("a remedy under a relative runner dir is printed exactly as it resolved", function()
  local advice, note = Kit.__adviceDir("tests/_kit/", "")
  assertEqual(advice, "tests/_kit/", "a relative runner already spells it the way its list does")
  assertEqual(note, "", "and needs no note about where the prefix came from")
end)

-- ── the kit-hole report, word for word ──────────────────────────────────────────────────────
--
-- Characterization of `collectKitHoles`, pinned before it was split into named units to bring it
-- under the complexity ceiling (CCN 15). The cases above assert what each report MEANS; these
-- assert what it SAYS, byte for byte, on every arm: the collision, the plain hole, the decline with
-- and without a shadow, a rule cell left empty, a kit suite the rule table does not know, the
-- 200-byte clip on a decline's reason, and which of several shadows a collision names. A refactor
-- that moves a word, or picks a different shadow, goes red here.

-- Built from bytes so this file's literals stay ASCII.
local EM = string.char(226, 128, 148)
local LOC5 = "localization-" .. string.char(194, 167) .. "5"

--- The one problem line `collectKitHoles` writes for an unwired kit suite with no shadow.
local function holeLine(kitDir, root, name, rule, gate)
  local advice, note = Kit.__adviceDir(kitDir, root)
  return ("%s%s.lua arrived with the vendored kit but is not declared in the suites list " .. EM
    .. " add { name = %q, dir = %q }%s to the runner, or record the decline as a `## Documented "
    .. "deviations` row keyed %s that names %s.lua; it is running zero cases today")
    :format(kitDir, name, name, advice, note, rule, gate)
end

--- The one problem line `collectKitHoles` writes for a kit suite a bare declaration shadows.
local function collisionLine(kitDir, root, name, index, shadowPath, rule, gate)
  local advice, note = Kit.__adviceDir(kitDir, root)
  return ("%s%s.lua ships in the vendored kit, and the suites list declares a bare %q (position %d) "
    .. "instead " .. EM .. " that entry wires %s, %s is what runs, and the kit's copy is loading zero "
    .. "cases. Wire one or the other, never both: change the entry to { name = %q, dir = %q }%s and "
    .. "delete %s, or record the decline as a `## Documented deviations` row keyed %s that names %s.lua")
    :format(kitDir, name, name, index, shadowPath, shadowPath, name, advice, note, shadowPath, rule, gate)
end

--- The whole failure `assertSuiteInventory` raises for `lines`, in order.
local function inventoryFailure(dir, lines)
  return "suite inventory (" .. dir .. "):\n          - " .. table.concat(lines, "\n          - ")
end

--- `err` without the `file:line: ` position `error` prefixes to it.
local function bare(err) return (err:gsub("^[^\n]-:%d+: ", "", 1)) end

test("characterization: a plain kit hole is reported word for word", function()
  withFixture({ "test_own" }, { "test_prose" }, function(root, dir, kitDir)
    local err = assertError(function() Kit.assertSuiteInventory(dir, { "test_own" }) end, "a hole")
    assertEqual(bare(err), inventoryFailure(dir,
      { holeLine(kitDir, root, "test_prose", "localization-5", "tests/_kit/test_prose") }))
  end)
end)

test("characterization: a kit suite with no rule row names the fallback rule", function()
  withFixture({ "test_own" }, { "test_custom" }, function(root, dir, kitDir)
    local err = assertError(function() Kit.assertSuiteInventory(dir, { "test_own" }) end, "a hole")
    assertEqual(bare(err), inventoryFailure(dir,
      { holeLine(kitDir, root, "test_custom", "the rule this gate serves", "tests/_kit/test_custom") }))
  end)
end)

test("characterization: a collision is reported word for word", function()
  withFixture({ "test_prose" }, { "test_prose" }, function(root, dir, kitDir)
    local err = assertError(function() Kit.assertSuiteInventory(dir, { "test_prose" }) end, "a collision")
    assertEqual(bare(err), inventoryFailure(dir, { collisionLine(kitDir, root, "test_prose", 1,
      dir .. "test_prose.lua", "localization-5", "tests/_kit/test_prose") }))
  end)
end)

test("characterization: of several shadows, the last declared is the one named", function()
  withFixture({ "test_prose" }, { "test_prose" }, function(root, dir, kitDir)
    os.execute(('mkdir -p "%salt"'):format(root))
    write(root .. "alt/test_prose.lua")
    local alt = { name = "test_prose", dir = root .. "alt/" }
    for _, order in ipairs({ { "test_prose", alt }, { alt, "test_prose" } }) do
      local last = order[2] == alt and (root .. "alt/test_prose.lua") or (dir .. "test_prose.lua")
      local err = assertError(function() Kit.assertSuiteInventory(dir, order) end, "a collision")
      assertEqual(bare(err), inventoryFailure(dir, { collisionLine(kitDir, root, "test_prose", 2, last,
        "localization-5", "tests/_kit/test_prose") }))
    end
  end)
end)

--- The declared skip the last `assertSuiteInventory` call registered, asserted to be exactly one.
local function onlyDecline(dir, suites)
  local before = #Kit.__tests()
  local ok, err = pcall(Kit.assertSuiteInventory, dir, suites)
  assertTrue(ok, "a recorded decline does not fail the run: " .. tostring(err))
  assertEqual(#Kit.__tests(), before + 1, "exactly one case registered")
  return Kit.__tests()[#Kit.__tests()]
end

test("characterization: a decline's name and reason, word for word", function()
  withFixture({ "test_own" }, { "test_prose" }, function(root, dir)
    register(root, "docs/ARCHITECTURE.md", { row(LOC5, DECLINE) })
    local added = onlyDecline(dir, { "test_own" })
    assertEqual(added.name, "suite inventory: tests/_kit/test_prose.lua is declined, and the decline is recorded")
    assertEqual(added.skip, root .. "docs/ARCHITECTURE.md carries a `## Documented deviations` row "
      .. "keyed `" .. LOC5 .. "`: " .. DECLINE)
  end)
end)

test("characterization: a decline over a collision names the file that runs instead", function()
  withFixture({ "test_prose" }, { "test_prose" }, function(root, dir)
    register(root, "docs/ARCHITECTURE.md", { row(LOC5, DECLINE) })
    local added = onlyDecline(dir, { "test_prose" })
    assertEqual(added.skip, root .. "docs/ARCHITECTURE.md carries a `## Documented deviations` row "
      .. "keyed `" .. LOC5 .. "`: " .. DECLINE .. " " .. EM .. " " .. dir .. "test_prose.lua runs in its place")
  end)
end)

test("characterization: a decline with an empty rule cell, and a reason clipped at 200 bytes", function()
  withFixture({ "test_own" }, { "test_custom" }, function(root, dir)
    local long = "`tests/_kit/test_custom` is unwired   because " .. ("x"):rep(240)
    register(root, "CLAUDE.md", { "|  | " .. long .. " | Why | 2026-09-23 | Never |" })
    local added = onlyDecline(dir, { "test_own" })
    local folded = long:gsub("%s+", " ")
    assertEqual(added.skip, root .. "CLAUDE.md carries a `## Documented deviations` row keyed "
      .. "(no rule cell): " .. folded:sub(1, 200) .. " ...")
  end)
end)
