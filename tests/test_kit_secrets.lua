-- tests/test_kit_secrets.lua — Kit.secret, the shared secret-value simulator (kit revision 38).
--
-- WHAT IT PROVES. That a wrapper minted by `Kit.secret` raises an error carrying `Kit.SECRET_ERROR`
-- from every operation Lua 5.1 lets a metatable trap, with the secret on either side of an
-- arithmetic operator; that `Kit.isSecret` and `Kit.reveal` see through it and through nothing else;
-- that `Kit.installSecretValue` sets the global and its restore puts back exactly what was there,
-- absence included; and that the registry is process-wide, so a secret minted before a second load
-- of the kit or a second mock build is still one after it.
--
-- WHAT IT DOES NOT PROVE, because the VM decides those cases before any metamethod runs: a boolean
-- test, `==` against a non-table, `#` on a table, and a comparison between a secret and a plain
-- value (which raises, but with Lua's own "attempt to compare" text). The last is pinned below as a
-- raise; the rest are pinned as the documented non-traps they are, so the header's claims cannot
-- drift from the behavior.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse
local assertError, assertErrorMatches = T.assertError, T.assertErrorMatches

local Kit = dofile("tests/_kit/framework.lua")

-- Every trapped operation, each as a function that performs it on the secret `s`.
local OPS = {
  { "+ (secret on the left)",   function(s) return s + 1 end },
  { "+ (secret on the right)",  function(s) return 1 + s end },
  { "- (secret on the left)",   function(s) return s - 1 end },
  { "- (secret on the right)",  function(s) return 1 - s end },
  { "* (secret on the left)",   function(s) return s * 2 end },
  { "* (secret on the right)",  function(s) return 2 * s end },
  { "/ (secret on the left)",   function(s) return s / 2 end },
  { "/ (secret on the right)",  function(s) return 2 / s end },
  { "% (secret on the left)",   function(s) return s % 2 end },
  { "% (secret on the right)",  function(s) return 2 % s end },
  { "^ (secret on the left)",   function(s) return s ^ 2 end },
  { "^ (secret on the right)",  function(s) return 2 ^ s end },
  { "unary -",                  function(s) return -s end },
  { ".. (secret on the left)",  function(s) return s .. "x" end },
  { ".. (secret on the right)", function(s) return "x" .. s end },
  { "indexing",                 function(s) return s.field end },
  { "field assignment",         function(s) s.field = 1 end },
  { "call",                     function(s) return s() end },
  { "< between two secrets",    function(s) return s < Kit.secret(6) end },
  { "<= between two secrets",   function(s) return s <= Kit.secret(6) end },
  { "== between two secrets",   function(s) return s == Kit.secret(5) end },
}

test("kit: Kit.SECRET_ERROR is the fixed marker `secret value`", function()
  -- red under: the member not existing (kit revision 37 has no secrets.lua).
  assertEqual(Kit.SECRET_ERROR, "secret value")
end)

for _, op in ipairs(OPS) do
  test("kit: Kit.secret raises Kit.SECRET_ERROR on " .. op[1], function()
    -- red under: a wrapper whose metatable leaves this operation untrapped (the VM's own
    -- "attempt to perform arithmetic on a table value" carries no marker), or no Kit.secret at all.
    local s = Kit.secret(5)
    assertErrorMatches(function() return op[2](s) end, "secret value", op[1])
  end)
end

test("kit: a secret compared against a plain value still raises (the VM's own text)", function()
  -- red under: a wrapper that answered the comparison (the VM rejects table-vs-number before any
  -- metamethod, so this pins that the comparison cannot silently succeed).
  local s = Kit.secret(5)
  assertError(function() return s < 6 end, "secret < number must raise")
  assertError(function() return 6 <= s end, "number <= secret must raise")
end)

test("kit: what Lua 5.1 cannot trap is documented, not pretended", function()
  -- red under: a header whose claims drifted from the VM; if a later interpreter starts trapping
  -- one of these, this case says so and the header is updated with it.
  local s = Kit.secret(5)
  local truthy = false
  if s then truthy = true end
  assertTrue(truthy, "a boolean test on a secret succeeds (a table is truthy)")
  assertFalse(s == 5, "== against a number is answered false by the VM")
  assertFalse(s == nil, "== against nil is answered false by the VM")
  assertEqual(type(tostring(s)), "string", "tostring is not trapped")
end)

test("kit: Kit.reveal returns the plain value, and is the identity on a non-secret", function()
  -- red under: a reveal that answered the wrapper, or one that raised on a plain value.
  assertEqual(Kit.reveal(Kit.secret(5)), 5)
  assertEqual(Kit.reveal(Kit.secret("name")), "name")
  assertEqual(Kit.reveal(7), 7)
  assertEqual(Kit.reveal(nil), nil)
  local t = {}
  assertTrue(Kit.reveal(t) == t, "a plain table comes back as itself")
end)

test("kit: Kit.isSecret is true for a wrapper and false for 5, nil and a plain table", function()
  -- red under: an isSecret keyed on the metatable alone (a plain table with a borrowed metatable
  -- would pass), or one that answered truthiness.
  assertTrue(Kit.isSecret(Kit.secret(5)), "a wrapper is a secret")
  assertTrue(Kit.isSecret(Kit.secret(false)), "a wrapped false is a secret")
  assertFalse(Kit.isSecret(5), "5 is not")
  assertFalse(Kit.isSecret(nil), "nil is not")
  assertFalse(Kit.isSecret({}), "a plain table is not")
  assertFalse(Kit.isSecret(setmetatable({}, getmetatable(Kit.secret(1)))),
    "a table that borrowed the metatable is not")
end)

test("kit: installSecretValue sets issecretvalue, and restore puts back an absent global", function()
  -- red under: a restore that left the installed function behind, or set the global to false.
  local before = rawget(_G, "issecretvalue")
  rawset(_G, "issecretvalue", nil)
  local restore = Kit.installSecretValue()
  local ok, err = pcall(function()
    local isv = rawget(_G, "issecretvalue")
    assertEqual(type(isv), "function", "the global is installed")
    assertTrue(isv(Kit.secret(5)), "it answers true for a secret")
    assertFalse(isv(5), "and false for a plain value")
    restore()
    assertEqual(rawget(_G, "issecretvalue"), nil, "restore puts back the absence")
  end)
  rawset(_G, "issecretvalue", before)
  if not ok then error(err, 0) end
end)

test("kit: installSecretValue's restore puts back a present global", function()
  -- red under: a restore that cleared the global rather than restoring what was there.
  local before = rawget(_G, "issecretvalue")
  local mine = function() return "host's own" end
  rawset(_G, "issecretvalue", mine)
  local restore = Kit.installSecretValue()
  local ok, err = pcall(function()
    assertTrue(rawget(_G, "issecretvalue") ~= mine, "the global is replaced while installed")
    restore()
    assertTrue(rawget(_G, "issecretvalue") == mine, "restore puts back the host's function")
  end)
  rawset(_G, "issecretvalue", before)
  if not ok then error(err, 0) end
end)

test("kit: a secret minted before a second kit load and mock build is still a secret after", function()
  -- red under: a registry local to one load of secrets.lua (a second framework load, as a suite
  -- that dofiles the kit makes, would mint a second registry and answer false here).
  local s = Kit.secret(9)
  local Kit2 = dofile("tests/_kit/framework.lua")
  dofile("tests/wow_mock.lua")()
  assertTrue(Kit2 ~= Kit, "the second load is a distinct kit table")
  assertTrue(Kit2.isSecret(s), "the second kit recognizes the first kit's secret")
  assertEqual(Kit2.reveal(s), 9, "and reveals it")
  assertTrue(Kit.isSecret(Kit2.secret(1)), "and the other way round")
  assertErrorMatches(function() return s == Kit2.secret(9) end, "secret value",
    "== across the two loads still reaches the shared metatable")
end)

test("kit: nothing installs issecretvalue by default", function()
  -- red under: a kit or mock build that set the global on load (fidelity: a client without the
  -- global must stay modeled).
  local before = rawget(_G, "issecretvalue")
  rawset(_G, "issecretvalue", nil)
  dofile("tests/_kit/framework.lua")
  dofile("tests/wow_mock.lua")()
  local after = rawget(_G, "issecretvalue")
  rawset(_G, "issecretvalue", before)
  assertEqual(after, nil, "neither a kit load nor a mock build installs the global")
end)
