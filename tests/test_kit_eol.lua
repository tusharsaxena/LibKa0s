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

--- A git index at `root` tracking `paths` (each written as a one-line file) and nothing else.
local function gitFixture(root, paths)
  for _, path in ipairs(paths) do
    local parent = path:match("^(.*)/[^/]+$")
    if parent then os.execute(('mkdir -p "%s%s"'):format(root, parent)) end
    local f = assert(io.open(root .. path, "wb"))
    f:write("x\n")
    f:close()
  end
  return os.execute(('cd "%s" && git init -q . >/dev/null 2>&1 && git add -A >/dev/null 2>&1')
    :format(root))
end

--- The (kind, evidence) the vendored eol gate reports for a repo tracking `paths`.
local function kindOf(paths)
  local interpreter, here = (rawget(_G, "arg") or {})[-1], cwd()
  if type(interpreter) ~= "string" or not here then
    T.skip("no interpreter path (arg[-1]) or no `pwd`, so the gate cannot be driven in a fixture")
  end
  local root = tempRoot()
  local ok, outText = pcall(function()
    gitFixture(root, paths)
    local chunk = ('local cases = {} '
      .. 'local K = { test = function(n, f) cases[#cases + 1] = { n = n, f = f } end, '
      .. 'fail = function(m) error(m, 0) end } '
      .. 'assert(loadfile([[%s/tests/_kit/test_eol.lua]]))(K) '
      .. 'for _, c in ipairs(cases) do if c.n:find("canonical body", 1, true) then '
      .. 'local ok, err = pcall(c.f) '
      .. 'print(ok and "RESULT OK" or ("RESULT FAIL " .. tostring(err):gsub("%%s+", " "))) end end')
      :format(here)
    local p = io.popen(("cd '%s' && '%s' -e '%s' 2>&1"):format(root, interpreter, chunk))
    local text = p and p:read("*a") or ""
    if p then p:close() end
    return text
  end)
  os.execute(('rm -rf "%s"'):format(root))
  if not ok then error(outText, 0) end
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
