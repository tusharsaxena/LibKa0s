-- tests/test_loader.lua — the loader's chunk cache, and the isolation invariant it rests on.
--
-- The cache exists because `loadfile` was 91% of a consumer's test CPU: a suite that builds a fresh
-- instance per case re-reads and re-PARSES the whole source tree every time, and on a WSL2 `/mnt`
-- checkout each of those reads crosses a 9p mount. Caching the compiled chunk took one consumer's
-- suite from 2m10s to 11.9s.
--
-- THE CASE THAT MATTERS MOST IS THE FIRST ONE. The cache holds a FUNCTION, not a result, and the
-- whole claim that this is safe rests on a single Lua 5.1 property: `setfenv` sets the environment a
-- chunk sees when it NEXT RUNS, and a closure created during that run inherits its parent's
-- environment AT CREATION TIME. If that were not true, two "isolated" instances would quietly share
-- one global namespace — and they would share it INVISIBLY, because every existing case would still
-- pass while testing the wrong instance's state. That is precisely the shape testing-§12 calls a
-- test that cannot fail, so it is pinned here by construction rather than asserted in a comment.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

-- A private loader, dofile'd rather than taken off T: the cache is a file-local upvalue, and a
-- suite that shares the runner's loader would be testing a cache the runner has already filled.
local Loader = dofile("tests/_kit/loader.lua")

--- A mock set whose every global reads back as `marker`.
local function envOf(marker)
  return setmetatable({}, { __index = function() return marker end })
end

--- Write `src` to a scratch file and return its path. The caller removes it.
local function scratch(src)
  local path = os.tmpname()
  local f = assert(io.open(path, "wb"))
  f:write(src)
  f:close()
  return path
end

test("loader: a cached chunk gives each instance its own global namespace", function()
  -- The chunk returns a CLOSURE that reads a global. If the cache leaked environments, both
  -- closures would answer with whichever env was installed last.
  local path = scratch("local function peek() return MARKER end\nreturn peek\n")

  local peekA = Loader.load(path, nil, envOf("A"))
  local peekB = Loader.load(path, nil, envOf("B"))

  assertEqual(peekA(), "A", "the first instance's closure must still read the first instance's env")
  assertEqual(peekB(), "B", "the second instance's closure must read the second instance's env")
  assertTrue(peekA ~= peekB, "each load must produce a fresh closure, not the cached one again")

  os.remove(path)
end)

test("loader: a chunk read once is not re-read", function()
  -- Observable without hooking `loadfile`: rewrite the file between loads. A cached chunk still
  -- answers with the ORIGINAL source, which is exactly the behavior being bought.
  local path = scratch("return 'first'\n")
  assertEqual(Loader.load(path, nil, {}), "first")

  local f = assert(io.open(path, "wb"))
  f:write("return 'second'\n")
  f:close()

  assertEqual(Loader.load(path, nil, {}), "first",
    "the second load must come from the cache, not from the rewritten file")
  os.remove(path)
end)

test("loader: uncache(path) forces the next load to re-read", function()
  local path = scratch("return 'first'\n")
  assertEqual(Loader.load(path, nil, {}), "first")

  local f = assert(io.open(path, "wb"))
  f:write("return 'second'\n")
  f:close()

  Loader.uncache(path)
  assertEqual(Loader.load(path, nil, {}), "second",
    "uncache(path) must drop that path so the rewritten file is read")
  os.remove(path)
end)

test("loader: uncache() with no argument empties the whole cache", function()
  local one = scratch("return 'one-old'\n")
  local two = scratch("return 'two-old'\n")
  Loader.load(one, nil, {})
  Loader.load(two, nil, {})

  for _, pair in ipairs({ { one, "one-new" }, { two, "two-new" } }) do
    local f = assert(io.open(pair[1], "wb"))
    f:write(("return %q\n"):format(pair[2]))
    f:close()
  end

  Loader.uncache()
  assertEqual(Loader.load(one, nil, {}), "one-new", "uncache() must drop every path, not just one")
  assertEqual(Loader.load(two, nil, {}), "two-new", "uncache() must drop every path, not just one")

  os.remove(one)
  os.remove(two)
end)

test("loader: a missing file raises, and names the path", function()
  local missing = "tests/no_such_file_" .. tostring(os.time()) .. ".lua"
  local err = T.assertError(function() Loader.load(missing, nil, {}) end,
    "loading a file that is not there must raise")
  assertTrue(err:find(missing, 1, true) ~= nil,
    "the error must name the path it could not load; got: " .. tostring(err))
end)

test("loader: a file that fails to compile stays an error until it is fixed", function()
  -- The failure mode this guards is a cache that REMEMBERS the failure as a value: a stored `false`
  -- or an empty stub would turn the second attempt from a raise into a silent nil, and a source file
  -- that silently loads as nothing is the degradation every load-list gate in this repo exists to
  -- prevent. So both halves are asserted — it must keep raising while broken, and it must pick up
  -- the fix once the file is valid.
  local path = scratch("this is not lua(((\n")
  T.assertError(function() Loader.load(path, nil, {}) end, "a syntax error must raise")
  T.assertError(function() Loader.load(path, nil, {}) end,
    "a still-broken file must raise on EVERY attempt, never resolve to a cached nothing")

  local f = assert(io.open(path, "wb"))
  f:write("return 'now valid'\n")
  f:close()

  assertEqual(Loader.load(path, nil, {}), "now valid",
    "a failed compile must leave the cache empty, so the fixed file is read")
  os.remove(path)
end)
