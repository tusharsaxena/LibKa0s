-- tests/test_kit_eol.lua — which `.gitattributes` body the kit's eol gate asks each repo kind for.
--
-- WHAT IT PROVES. That `testkit/test_eol.lua` sorts a repository into the client-bound (crlf) or
-- the non-client (lf) body by line-endings-2's three arms in order -- a tracked `.toc`, a tracked
-- `libs/`, a library payload folder -- and quotes the evidence it used. That classification is the
-- first thing every eol failure prints, and the live run only ever exercises one arm of it: this
-- library's own, the payload folder. Every other arm is taken only in a consumer, so it is pinned
-- here against fixture repositories rather than left to whichever consumer re-vendors first.
--
-- DRIVEN THROUGH THE GATE, NOT AROUND IT. The classifier is a local of a vendored suite file and
-- is not exported; the gate reads the tracked set from `git ls-files` in the working directory, and
-- Lua cannot change its own. So each case builds a real git index in a temporary directory, starts
-- a child interpreter there, loads the suite with a two-function stand-in for the kit, and runs the
-- body case against a tree with no `.gitattributes`. That failure (a) quotes the kind and the
-- evidence verbatim, which is exactly what is read back.

local T = _G.LK_TEST
local test, assertEqual = T.test, T.assertEqual

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
    T.skip("no `mktemp -d` on this host, so the eol fixtures cannot be built")
  end
  return made .. "/"
end

--- A git index at `root` tracking `files` and nothing else. Each entry is a path, written as a
--- one-line file, or a `{ path, bytes }` pair written exactly as given.
local function gitFixture(root, files)
  for _, entry in ipairs(files) do
    local path, bytes = entry, "x\n"
    if type(entry) == "table" then path, bytes = entry[1], entry[2] end
    local parent = path:match("^(.*)/[^/]+$")
    if parent then os.execute(('mkdir -p "%s%s"'):format(root, parent)) end
    local f = assert(io.open(root .. path, "wb"))
    f:write(bytes)
    f:close()
  end
  return os.execute(('cd "%s" && git init -q . >/dev/null 2>&1 && git add -A >/dev/null 2>&1')
    :format(root))
end

--- What the vendored eol gate's case whose name contains `needle` says about a repo tracking
--- `files`: `RESULT OK`, or `RESULT FAIL ` and the failure with its whitespace collapsed.
local function gateVerdict(files, needle)
  local interpreter, here = (rawget(_G, "arg") or {})[-1], cwd()
  if type(interpreter) ~= "string" or not here then
    T.skip("no interpreter path (arg[-1]) or no `pwd`, so the gate cannot be driven in a fixture")
  end
  local root = tempRoot()
  local ok, outText = pcall(function()
    gitFixture(root, files)
    local chunk = ('local cases = {} '
      .. 'local K = { test = function(n, f) cases[#cases + 1] = { n = n, f = f } end, '
      .. 'fail = function(m) error(m, 0) end } '
      .. 'assert(loadfile([[%s/tests/_kit/test_eol.lua]]))(K) '
      .. 'for _, c in ipairs(cases) do if c.n:find([[%s]], 1, true) then '
      .. 'local ok, err = pcall(c.f) '
      .. 'print(ok and "RESULT OK" or ("RESULT FAIL " .. tostring(err):gsub("%%s+", " "))) end end')
      :format(here, needle)
    local p = io.popen(("cd '%s' && '%s' -e '%s' 2>&1"):format(root, interpreter, chunk))
    local text = p and p:read("*a") or ""
    if p then p:close() end
    return text
  end)
  os.execute(('rm -rf "%s"'):format(root))
  if not ok then error(outText, 0) end
  return outText
end

--- The (kind, evidence) the vendored eol gate reports for a repo tracking `paths`.
local function kindOf(paths)
  local outText = gateVerdict(paths, "canonical body")
  local kind, why = outText:match("repo kind %((%a+), because (.-)%), then renormalize")
  if not kind then
    T.skip("the child produced no classification, so this host cannot drive the gate: "
      .. outText:gsub("%s+", " "):sub(1, 160))
  end
  return kind, why
end

local CASES = {
  { "a root .toc is the evidence even when a nested one sorts first",
    { "Aa/Nested.toc", "Z.toc", "core.lua" }, "crlf", "it ships an addon to the client (Z.toc)" },
  { "with no root .toc, the first nested one in tracked order",
    { "Bb/Other.toc", "Aa/Nested.toc" }, "crlf", "it ships an addon to the client (Aa/Nested.toc)" },
  { "a .toc outranks a libs/ tree",
    { "Z.toc", "libs/Foo/Foo.lua" }, "crlf", "it ships an addon to the client (Z.toc)" },
  { "a libs/ tree with no .toc, first path in tracked order",
    { "libs/B/b.lua", "libs/A/a.lua", "core.lua" }, "crlf",
    "it ships a client-bound libs/ tree (libs/A/a.lua)" },
  { "a libs/ tree outranks a library payload folder",
    { "Lib/Lib.xml", "Lib/a.lua", "libs/x.lua" }, "crlf",
    "it ships a client-bound libs/ tree (libs/x.lua)" },
  { "only a top-level libs/ counts",
    { "sub/libs/x.lua", "libsx/y.lua" }, "lf",
    "it ships nothing into the WoW client: no .toc, no tracked libs/, no library payload folder" },
  { "a payload folder: its own aggregate XML with Lua beside it",
    { "Lib/Lib.xml", "Lib/Core.lua" }, "crlf",
    "it is a Ka0s-owned library repo whose ship payload is Lib/ (Lib/Lib.xml)" },
  { "Lua anywhere under the payload folder counts",
    { "Lib/Lib.xml", "Lib/sub/deep.lua" }, "crlf",
    "it is a Ka0s-owned library repo whose ship payload is Lib/ (Lib/Lib.xml)" },
  { "of two payload folders, the first in tracked order",
    { "Bb/Bb.xml", "Bb/b.lua", "Aa/Aa.xml", "Aa/a.lua" }, "crlf",
    "it is a Ka0s-owned library repo whose ship payload is Aa/ (Aa/Aa.xml)" },
  { "an aggregate XML with no Lua in its folder is not a payload",
    { "Lib/Lib.xml", "Other/x.lua", "Lib.lua" }, "lf",
    "it ships nothing into the WoW client: no .toc, no tracked libs/, no library payload folder" },
  { "an XML not named after its folder is not a payload",
    { "Lib/Other.xml", "Lib/a.lua" }, "lf",
    "it ships nothing into the WoW client: no .toc, no tracked libs/, no library payload folder" },
  { "an aggregate XML below the folder's top is not a payload",
    { "Lib/sub/Lib.xml", "Lib/a.lua" }, "lf",
    "it ships nothing into the WoW client: no .toc, no tracked libs/, no library payload folder" },
}

for _, c in ipairs(CASES) do
  local label, paths, kind, why = c[1], c[2], c[3], c[4]
  test("eol repo kind: " .. label, function()
    local gotKind, gotWhy = kindOf(paths)
    assertEqual(gotKind, kind, "the body the gate asks for")
    assertEqual(gotWhy, why, "the evidence it quotes")
  end)
end

-- ── case one's lone-CR check (kit revision 26) ──────────────────────────────────────────────
--
-- A CR that no LF follows is a terminator the old count could not see: it counted LFs and asked how
-- many had a CR before them, so `a\r\r\n` read as one clean CRLF. git's `text=auto` classifies such
-- a file as binary and stores it unnormalized, so nothing downstream sees it either (the
-- 2026-09-23 audit's `AuraMaster-A-18`, whose `tests/page_helpers.lua:80` was the live case). Each
-- fixture is a real git index with a CRLF or LF pin, driven through the vendored gate's case one.

local CASE_ONE = "every tracked file carries the terminator"
local CRLF_PIN = { ".gitattributes", "* text=auto eol=crlf\r\n" }
local LF_PIN = { ".gitattributes", "* text=auto eol=lf\n" }

--- The gate's case-one verdict for `files`, or a skip when this host cannot drive a child.
local function caseOne(files)
  local out = gateVerdict(files, CASE_ONE)
  if not out:find("RESULT ", 1, true) then
    T.skip("the child produced no verdict, so this host cannot drive the gate: "
      .. out:gsub("%s+", " "):sub(1, 160))
  end
  return out
end

test("eol lone CR: a line ending \\r\\r\\n fails, naming path:line", function()
  -- red under: count only LFs and the CRs before them (revision 25's terminators())
  local out = caseOne({ CRLF_PIN, { "bad.lua", "a\r\nb\r\r\nc\r\n" } })
  T.assertTrue(out:find("RESULT FAIL", 1, true) ~= nil,
    "a lone CR in a CRLF-pinned file fails case one: " .. out:sub(1, 200))
  T.assertTrue(out:find("bad.lua:2", 1, true) ~= nil,
    "the failure names the path and the line the lone CR sits on: " .. out:sub(1, 300))
end)

test("eol lone CR: every lone CR is named, including one at end of file", function()
  -- red under: report only the first lone CR in a file
  local out = caseOne({ LF_PIN, { "two.lua", "a\rb\nc\nd\r" } })
  T.assertTrue(out:find("two.lua:1", 1, true) ~= nil, "the first lone CR, on line 1: " .. out:sub(1, 300))
  T.assertTrue(out:find("two.lua:3", 1, true) ~= nil,
    "the second, a CR the file ends on, on line 3: " .. out:sub(1, 300))
end)

test("eol lone CR: a file with a NUL byte is skipped", function()
  -- red under: drop the NUL guard in case one
  local out = caseOne({ CRLF_PIN, { "blob.dat", "a\0\r\rb\n" } })
  assertEqual(out:match("RESULT %u+"), "RESULT OK", "a NUL byte marks a binary nobody declared")
end)

test("eol lone CR: clean CRLF and clean LF files pass", function()
  -- red under: count the CR of a CRLF as a lone CR
  local crlf = caseOne({ CRLF_PIN, { "ok.lua", "a\r\nb\r\n" } })
  assertEqual(crlf:match("RESULT %u+"), "RESULT OK", "a clean CRLF file under a CRLF pin")
  local lf = caseOne({ LF_PIN, { "ok.lua", "a\nb\n" } })
  assertEqual(lf:match("RESULT %u+"), "RESULT OK", "a clean LF file under an LF pin")
end)
