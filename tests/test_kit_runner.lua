-- tests/test_kit_runner.lua — what the kit's automated-test runner records, driven over fixture repos.
--
-- WHAT IT PROVES. Two things `testkit/run-automated-tests.sh` writes into every consumer's record
-- (kit revision 26). First, which of `automated-tests-§3`'s two sanctioned perf skip reasons a repo
-- with no `tests/perf.lua` gets: reason (1), *nothing to run*, or reason (2), a ratified
-- `performance-§12` no-combat-path exemption read out of the repo's `## Documented deviations`
-- register. Second, that an empty watch-list table prints its header row and then `None.` under a
-- blank line (`automated-tests-§4`, kit revision 30): revision 25 printed `None.` in place of the
-- header, and revisions 26 to 29 printed the header alone.
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
