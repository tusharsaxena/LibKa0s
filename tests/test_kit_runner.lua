-- tests/test_kit_runner.lua — what the kit's automated-test runner records, driven over fixture repos.
--
-- WHAT IT PROVES. Two things `testkit/run-automated-tests.sh` writes into every consumer's record
-- (kit revision 26). First, which of `automated-tests-§3`'s two sanctioned perf skip reasons a repo
-- with no `tests/perf.lua` gets: reason (1), *nothing to run*, or reason (2), a ratified
-- `performance-§12` no-combat-path exemption read out of the repo's `## Documented deviations`
-- register. Second, that an empty watch-list table prints its header row and then `None.` under a
-- blank line (`automated-tests-§4`, kit revision 30): revision 25 printed `None.` in place of the
-- header, and revisions 26 to 29 printed the header alone. Third, that the band table leaves out
-- what `layout-§1`'s generated-data carve-out exempts, read from the same `Kit.layoutCap.exempt`
-- the cap gate reads, through `lua tests/run.lua --layout-cap-exempt` (kit revision 31, ATS-21).
--
-- DRIVEN THROUGH THE SCRIPT, NOT AROUND IT. The runner is a shell script and reads the repo it is
-- started in, so each case builds a throwaway repo in a temporary directory and runs the library's
-- own `testkit/run-automated-tests.sh` there by absolute path, under bash (the script uses bash
-- arrays, so `sh` is not enough where `sh` is dash). The fixture carries a `.toc`, so it is read as
-- an addon and needs no git, except in the case that pins the library host.

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
    T.skip("no `mktemp -d` on this host, so the runner fixtures cannot be built")
  end
  return made .. "/"
end

--- Write `files` (path -> bytes) under `root`.
local function writeTree(root, files)
  for path, bytes in pairs(files) do
    local parent = path:match("^(.*)/[^/]+$")
    if parent then os.execute(('mkdir -p "%s%s"'):format(root, parent)) end
    local f = assert(io.open(root .. path, "wb"))
    f:write(bytes)
    f:close()
  end
end

--- The whole of `path`, or nil.
local function slurp(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local text = f:read("*a")
  f:close()
  return text
end

--- The first line `cmd` prints, or nil.
local function firstLine(cmd)
  local p = io.popen(cmd)
  local line = p and p:read("*l")
  if p then p:close() end
  return line
end

--- What `wants` names in the fixture at `root`: "manifest" (the newest bundle's manifest.json),
--- "bundles" (how many bundle directories exist), or a repo-relative path read whole.
local function readBack(root, wants)
  local read = {}
  for _, want in ipairs(wants or {}) do
    if want == "manifest" then
      local dir = firstLine(("ls -1d '%s'docs/automated-tests/[0-9]*/ 2>/dev/null"):format(root))
      read.manifest = dir and slurp(dir .. "manifest.json")
    elseif want == "bundles" then
      read.bundles = tonumber(firstLine(("ls -1d '%s'docs/automated-tests/[0-9]*/ 2>/dev/null | wc -l")
        :format(root)) or "0")
    else
      read[want] = slurp(root .. want)
    end
  end
  return read
end

--- Run the runner with `args` in a fixture holding `files`. Returns its combined output, its exit
--- code, and what `opts.read` asked `readBack` for (read before the fixture is removed).
--- `opts.setup` is an optional shell step run inside the fixture first; `opts.env` prefixes the command.
local function runIn(files, args, opts)
  opts = opts or {}
  local here = cwd()
  if not here then T.skip("no `pwd`, so the runner cannot be found by absolute path") end
  local root = tempRoot()
  local ok, a, b, c = pcall(function()
    writeTree(root, files)
    local cmd = ("cd '%s' && %s%s bash '%s/testkit/run-automated-tests.sh' %s 2>&1; echo \"EXIT=$?\"")
      :format(root, opts.setup and (opts.setup .. " && ") or "", opts.env or "", here, args)
    local p = io.popen(cmd)
    local text = p and p:read("*a") or ""
    if p then p:close() end
    local code = tonumber(text:match("EXIT=(%d+)%s*$"))
    if not code then T.skip("the runner produced no exit code on this host: " .. text:sub(1, 160)) end
    return text, code, readBack(root, opts.read)
  end)
  os.execute(('rm -rf "%s"'):format(root))
  if not ok then error(a, 0) end
  return a, b, c
end

local TOC = { ["Fix.toc"] = "## Interface: 120000\n## Version: 1.0.0\n" }

--- A fixture addon: the `.toc`, plus `extra` merged over it.
local function addon(extra)
  local files = {}
  for k, v in pairs(TOC) do files[k] = v end
  for k, v in pairs(extra or {}) do files[k] = v end
  return files
end

local HEADER = "| Rule | What differs | Why | Decided | Re-check trigger |\n|---|---|---|---|---|\n"

--- A `## Documented deviations` register holding `rows`, between two other sections.
local function register(rows)
  return "# Architecture\n\nIntro.\n\n## Documented deviations\n\n" .. HEADER .. table.concat(rows, "\n")
    .. "\n\n## Next section\n\n| Rule | not | a | deviation | row |\n|---|---|---|---|---|\n"
    .. "| `performance-§12` | under another heading | x | y | z |\n"
end

local EXEMPT_ROW = "| `performance-§12` | No perf harness is wired | No combat path | 2026-09-01 | A combat path |"
local OTHER_ROW = "| `localization-§5` | a key keeps a British spelling, `a \\| b` | c | d | e |"
local REASON_ONE = "no tests/perf.lua — this addon ships no offline scenarios"
local REASON_TWO_ADDON =
  "performance-§12 no-combat-path exemption (ratified; docs/ARCHITECTURE.md -> Documented deviations)"

test("runner perf: a performance-§12 register row records skip reason (2), in the manifest and RESULTS.md", function()
  -- red under: revision 25's perf block, which knows reason (1) only
  local out, code, read = runIn(addon{ ["docs/ARCHITECTURE.md"] = register{ OTHER_ROW, EXEMPT_ROW } },
    "--suite perf", { read = { "manifest", "docs/automated-tests/RESULTS.md" } })
  assertEqual(code, 0, "a perf skip never fails the run: " .. out)
  assertTrue(out:find("skip  — " .. REASON_TWO_ADDON, 1, true) ~= nil,
    "the console names reason (2) and the register it came from: " .. out)
  assertTrue((read.manifest or ""):find('"skipReason": "' .. REASON_TWO_ADDON .. '"', 1, true) ~= nil,
    "the manifest's skipReason carries reason (2): " .. tostring(read.manifest))
  local results = read["docs/automated-tests/RESULTS.md"] or ""
  assertTrue(results:find("second of", 1, true) ~= nil and results:find("docs/performance.md", 1, true) ~= nil,
    "RESULTS.md's Perf section states reason (2) and points at docs/performance.md: " .. results:sub(-1500))
  assertTrue(results:find("nothing to run", 1, true) == nil, "and never reason (1)'s wording")
end)

test("runner perf: a library's root CLAUDE.md register is read when there is no docs/ARCHITECTURE.md", function()
  -- red under: read docs/ARCHITECTURE.md only
  local out, code = runIn({ ["CLAUDE.md"] = register{ EXEMPT_ROW } }, "--no-bundle --suite perf",
    { setup = "git init -q . >/dev/null 2>&1" })
  assertEqual(code, 0, out)
  assertTrue(out:find("(ratified; CLAUDE.md -> Documented deviations)", 1, true) ~= nil,
    "the reason names the root CLAUDE.md register: " .. out)
end)

test("runner perf: with no performance-§12 row the skip stays reason (1)", function()
  -- red under: match the rule anywhere in the file rather than in the register's own rows
  local out, code = runIn(addon{ ["docs/ARCHITECTURE.md"] = register{ OTHER_ROW } }, "--no-bundle --suite perf")
  assertEqual(code, 0, out)
  assertTrue(out:find("skip  — " .. REASON_ONE, 1, true) ~= nil, "reason (1), unchanged: " .. out)
end)

test("runner perf: a row that disclaims the exemption is not the exemption", function()
  -- red under: match `performance-§12` as a substring of the rule cell
  local disclaim = "| `performance-§12` (the exemption is not claimed) | x | y | z | w |"
  local out, code = runIn(addon{ ["docs/ARCHITECTURE.md"] = register{ disclaim } }, "--no-bundle --suite perf")
  assertEqual(code, 0, out)
  assertTrue(out:find("skip  — " .. REASON_ONE, 1, true) ~= nil, "reason (1): " .. out)
end)

test("runner perf: an unparseable register exits 2 before any bundle is written", function()
  -- red under: skip the register rows the parser cannot read, and fall back to reason (1)
  local broken = "# A\n\n## Documented deviations\n\n| Rule | What differs |\n"
    .. "| `performance-§12` | no separator above |\n"
  local out, code, read = runIn(addon{ ["docs/ARCHITECTURE.md"] = broken }, "--suite perf",
    { read = { "bundles" } })
  assertEqual(code, 2, "exit 2: " .. out)
  assertTrue(out:find("Documented deviations", 1, true) ~= nil and out:find("docs/ARCHITECTURE.md", 1, true) ~= nil,
    "the message names the register and its file: " .. out)
  assertEqual(read.bundles, 0, "no bundle directory is left behind")
end)

test("runner perf: KA0S_PERF_EXEMPT=1 counts only where no register exists", function()
  -- red under: honor KA0S_PERF_EXEMPT=1 over a present register
  local out = runIn(addon(), "--no-bundle --suite perf", { env = "KA0S_PERF_EXEMPT=1" })
  assertTrue(out:find("skip  — performance-§12 no-combat-path exemption (ratified; KA0S_PERF_EXEMPT=1)", 1, true) ~= nil,
    "no register: the flag records reason (2): " .. out)
  local withReg = runIn(addon{ ["docs/ARCHITECTURE.md"] = register{ OTHER_ROW } }, "--no-bundle --suite perf",
    { env = "KA0S_PERF_EXEMPT=1" })
  assertTrue(withReg:find("skip  — " .. REASON_ONE, 1, true) ~= nil,
    "a register without the row outranks the flag: " .. withReg)
end)

test("runner complexity: empty watch-list tables print their header rows, then 'None.'", function()
  -- red under: revision 25's fn_table/band_table early `printf 'None.'` exits (no header), and
  -- revisions 26 to 29's header with nothing under it (ATS-20)
  local lizard = firstLine("command -v lizard 2>/dev/null")
  if not lizard or lizard == "" then T.skip("lizard is not on PATH, so the complexity suite cannot run") end
  local out, code, read = runIn(addon{ ["one.lua"] = "local function one()\n  return 1\nend\nreturn one\n" },
    "--suite complexity", { read = { "docs/automated-tests/RESULTS.md" } })
  assertEqual(code, 0, out)
  local results = read["docs/automated-tests/RESULTS.md"] or ""
  assertTrue(results:find("| Function | CCN | Location | Disposition |\n|---|---|---|---|\n\nNone.\n", 1, true) ~= nil,
    "the functions table keeps its header and separator, then says None.: " .. results:sub(-1200))
  assertTrue(results:find("| Band | File | LOC | Disposition |\n|---|---|---|---|\n\nNone.\n", 1, true) ~= nil,
    "the band table keeps its header and separator, then says None.")
  local _, count = results:gsub("\nNone%.\n", "")
  assertEqual(count, 2, "exactly one None. per empty table")
end)

test("runner complexity: a table with rows does not also say 'None.'", function()
  -- red under: none_if_empty printing whatever the rows, which would put `None.` under a listed entry
  local lizard = firstLine("command -v lizard 2>/dev/null")
  if not lizard or lizard == "" then T.skip("lizard is not on PATH, so the complexity suite cannot run") end
  local src = { "local function busy(x)" }
  for i = 1, 20 do src[#src + 1] = ("  if x == %d then return %d end"):format(i, i) end
  src[#src + 1] = "  return 0\nend\nreturn busy\n"
  local out, _, read = runIn(addon{ ["busy.lua"] = table.concat(src, "\n") },
    "--suite complexity", { read = { "docs/automated-tests/RESULTS.md" } })
  local results = read["docs/automated-tests/RESULTS.md"] or ""
  local fnSection = results:match("### Functions `lizard` warned on\n\n(.-)\n### ") or ""
  assertTrue(fnSection:find("| `busy` |", 1, true) ~= nil,
    "the warned function is listed: " .. fnSection .. "\n" .. out:sub(-600))
  assertTrue(fnSection:find("None.", 1, true) == nil, "and its table does not also say None.")
  local bandSection = results:match("### Files by `layout%-§1` band\n\n(.-)\n\n`lizard`") or ""
  assertTrue(bandSection:find("\n\nNone.", 1, true) ~= nil, "the empty band table still does: " .. bandSection)
end)

--- `n` lines of Lua, so a fixture file lands in whichever `layout-§1` band a case needs.
local function linesOf(n)
  local out = {}
  for i = 1, n do out[i] = ("local _ = %d"):format(i) end
  return table.concat(out, "\n") .. "\n"
end

--- A fixture `tests/run.lua` that loads this checkout's kit, runs `body`, and hands `Kit.run` no suites.
local function fixtureRunner(here, body)
  return ('local Kit = dofile("%s/testkit/framework.lua")\n'):format(here)
    .. (body or "") .. "Kit.run{ suites = {} }\n"
end

--- The band section of a fixture run's RESULTS.md, or a skip where the complexity suite cannot run.
local function bandSection(files)
  local lizard = firstLine("command -v lizard 2>/dev/null")
  if not lizard or lizard == "" then T.skip("lizard is not on PATH, so the complexity suite cannot run") end
  local out, code, read = runIn(addon(files), "--suite complexity",
    { read = { "docs/automated-tests/RESULTS.md", "manifest" } })
  assertEqual(code, 0, out)
  local results = read["docs/automated-tests/RESULTS.md"] or ""
  return results:match("### Files by `layout%-§1` band\n\n(.-)\n\n`lizard`") or "", read.manifest or ""
end

test("runner complexity: the band table leaves out what Kit.layoutCap.exempt names, and says so", function()
  -- red under: revisions 30 and earlier, whose band table listed every file of 1000 lines or more
  -- outside the vendored pair, generated dumps included (ATS-21)
  local here = cwd()
  if not here then T.skip("no `pwd`, so the fixture runner cannot find the kit by absolute path") end
  local band, manifest = bandSection{
    ["Big.lua"] = linesOf(1100),
    ["Gen/Dump.lua"] = linesOf(1600),
    ["Gen/Other.lua"] = linesOf(1200),
    ["Solo.lua"] = linesOf(1050),
    ["General.lua"] = linesOf(1300),
    -- The print is setup noise that happens to name a band path; it must not read as an answer.
    ["tests/run.lua"] = fixtureRunner(here,
      'print("Big.lua")\nKit.layoutCap = { exempt = { "Gen/", ["Solo.lua"] = true } }\n'),
  }
  assertTrue(band:find("| `Big.lua` |", 1, true) ~= nil, "an authored band file is listed: " .. band)
  assertTrue(band:find("| `General.lua` |", 1, true) ~= nil,
    "a `Gen/` entry covers the folder, not every path that starts with its letters")
  for _, gone in ipairs({ "Gen/Dump.lua", "Gen/Other.lua", "Solo.lua" }) do
    assertTrue(band:find("| `" .. gone .. "` |", 1, true) == nil, gone .. " is exempt and has no row: " .. band)
  end
  assertTrue(band:find("Left out as generated non-shipping data", 1, true) ~= nil,
    "the table says what the carve-out left out: " .. band)
  assertTrue(band:find("`Gen/Dump.lua`, `Gen/Other.lua`, `Solo.lua`", 1, true) ~= nil,
    "and names each file, in path order: " .. band)
  assertTrue(manifest:find('"bandFiles": 2', 1, true) ~= nil, "two authored files are in the band: " .. manifest)
  assertTrue(manifest:find('"overCapFiles": 0', 1, true) ~= nil, "and the exempt dump is not counted over the cap")
end)

test("runner complexity: with no exempt set a generated dump is listed like any other file", function()
  -- red under: a runner that guessed at generated files by path or size instead of asking the repo
  local here = cwd()
  if not here then T.skip("no `pwd`, so the fixture runner cannot find the kit by absolute path") end
  local band, manifest = bandSection{
    ["Gen/Dump.lua"] = linesOf(1600),
    ["tests/run.lua"] = fixtureRunner(here),
  }
  assertTrue(band:find("| > 1500 (over cap) | `Gen/Dump.lua` |", 1, true) ~= nil,
    "an undeclared dump is a breach like any other file: " .. band)
  assertTrue(band:find("Left out", 1, true) == nil, "and nothing claims to have been left out")
  assertTrue(manifest:find('"overCapFiles": 1', 1, true) ~= nil, "and the manifest counts it: " .. manifest)
end)

--- A function of `n` decisions after a first line carrying `hazard`, over which raw lizard loses
--- the whole function (kit revision 35).
local function busyWith(head, hazard, n)
  local src = { head, "  " .. hazard }
  for i = 1, n do src[#src + 1] = ("  if x == %d then return %d end"):format(i, i) end
  src[#src + 1] = "  return 0\nend"
  return table.concat(src, "\n")
end

test("runner complexity: functions lizard's reader drops are measured, methods under their own name", function()
  -- red under: revision 34's raw `lizard` over the tree, which drops a function over `#` or a bare
  -- `class` and names `function M:go()` as `M`
  local lizard = firstLine("command -v lizard 2>/dev/null")
  if not lizard or lizard == "" then T.skip("lizard is not on PATH, so the complexity suite cannot run") end
  local src = "local M = {}\n" .. busyWith("local function hashed(x, t)", "if #t > 99 then return -1 end", 20) .. "\n"
    .. busyWith("function M:go(x)", "local c = { class = x }", 18) .. "\nreturn M, hashed\n"
  local out, code, read = runIn(addon{ ["busy.lua"] = src }, "--suite complexity",
    { read = { "docs/automated-tests/RESULTS.md", "manifest" } })
  assertEqual(code, 0, out)
  local results = read["docs/automated-tests/RESULTS.md"] or ""
  local fnSection = results:match("### Functions `lizard` warned on\n\n(.-)\n### ") or ""
  assertTrue(fnSection:find("| `hashed` | 22 | `busy.lua` |", 1, true) ~= nil,
    "the function whose `#` shares a line with `end` is measured: " .. fnSection .. "\n" .. out:sub(-600))
  assertTrue(fnSection:find("| `M.go` | 19 | `busy.lua` |", 1, true) ~= nil,
    "the method is measured, under its own name: " .. fnSection)
  local manifest = read.manifest or ""
  assertTrue(manifest:find('"complexity": { "status": "pass"', 1, true) ~= nil, "parity holds: " .. manifest)
  assertTrue(manifest:find('"blindFiles": 0', 1, true) ~= nil, "and the manifest says so: " .. manifest)
end)

test("runner complexity: a file lizard stays blind in fails complexity, names the file, never fails the run", function()
  -- red under: revision 34, which recorded `pass` over a function lizard never listed
  local lizard = firstLine("command -v lizard 2>/dev/null")
  if not lizard or lizard == "" then T.skip("lizard is not on PATH, so the complexity suite cannot run") end
  -- A function literal in a `for ... in` header at file scope: lizard 1.24.0 lists nothing for it,
  -- and the sanitizer does not rewrite it, so only parity can see it.
  local out, code, read = runIn(addon{
    ["blind.lua"] = "for _, p in ipairs({ function() return 1 end }) do p() end\n",
    ["fine.lua"] = "local function one() return 1 end\nreturn one\n",
  }, "--suite complexity", { read = { "docs/automated-tests/RESULTS.md", "manifest" } })
  assertEqual(code, 0, "a blind file never fails the run: " .. out)
  assertTrue(out:find("complexity  fail", 1, true) ~= nil, "the console records the suite as failed: " .. out)
  assertTrue(out:find("lizard blind in 1 file(s): `blind.lua` (0 of 1 functions listed)", 1, true) ~= nil,
    "and names the file with both counts: " .. out)
  assertTrue(out:find("verdict: amber", 1, true) ~= nil, "the verdict is amber, not red: " .. out)
  local manifest = read.manifest or ""
  assertTrue(manifest:find('"complexity": { "status": "fail"', 1, true) ~= nil, "the manifest: " .. manifest)
  assertTrue(manifest:find('"blindFiles": 1', 1, true) ~= nil, "counts the blind file: " .. manifest)
  local results = read["docs/automated-tests/RESULTS.md"] or ""
  assertTrue(results:find("**Not sighted — complexity did not pass**", 1, true) ~= nil,
    "the watch list says it was not sighted: " .. results:sub(-2000))
end)

test("runner complexity: a function longer than lizard's default 1000 lines is not a warning (-L 1500)", function()
  -- red under: kit 35 before GI-LK-10R, whose lizard ran at its default length threshold (1000), so a
  -- CCN-1 closure wrapping a 1100-line file was a complexity warning; length is layout-§1's to govern
  local lizard = firstLine("command -v lizard 2>/dev/null")
  if not lizard or lizard == "" then T.skip("lizard is not on PATH, so the complexity suite cannot run") end
  local src = { "local function attach(lib)" }
  for i = 1, 1100 do src[#src + 1] = ("  lib.v%d = %d"):format(i, i) end
  src[#src + 1] = "end\nreturn attach\n"
  local out, code, read = runIn(addon{ ["long.lua"] = table.concat(src, "\n") }, "--suite complexity",
    { read = { "manifest" } })
  assertEqual(code, 0, out)
  local manifest = read.manifest or ""
  assertTrue(manifest:find('"complexity": { "status": "pass"', 1, true) ~= nil, "the suite passes: " .. manifest)
  assertTrue(manifest:find('"warnings": 0, "maxCcn": 1,', 1, true) ~= nil,
    "an 1100-line CCN-1 function is no complexity warning: " .. manifest .. "\n" .. out:sub(-600))
end)
