-- tests/test_kit_asserts.lua — Kit.assertErrorMatches (kit revision 26).
--
-- `Kit.assertError(fn, msg)` proves that fn raised and nothing more: `msg` is only the text of its
-- own failure, and the raised error it returns is discarded by any caller that uses it as a
-- statement. `testing-§12` says "it raised" is not sufficient, because a case like that passes just
-- as happily on a typo in the test itself, or on a raise from a line the case never meant to reach.
-- `assertErrorMatches` is the statement-position form that checks WHAT was raised, so a case that
-- wants that check does not have to hand-roll `local err = assertError(...); assertTrue(err:find(...))`.

local T = _G.LK_TEST
local test, assertEqual, assertFalse, assertTrue = T.test, T.assertEqual, T.assertFalse, T.assertTrue

--- True when `s` contains `needle` as plain text.
local function has(s, needle)
  return tostring(s):find(needle, 1, true) ~= nil
end

test("kit: assertErrorMatches passes on a raise that carries the needle, and returns the error", function()
  -- red under: the member not existing (T.assertErrorMatches is nil, and calling it raises), or not
  -- being exposed by Kit.expose.
  local err = T.assertErrorMatches(function() error("descriptor.rows must be a table", 0) end,
    "descriptor.rows")
  assertEqual(err, "descriptor.rows must be a table", "the raised text comes back whole")
  -- The needle is plain text, not a pattern: `.` and `(` match themselves only.
  T.assertErrorMatches(function() error("bad arg (x.y)", 0) end, "(x.y)")
end)

test("kit: assertErrorMatches fails when fn raises something else, naming both strings", function()
  -- red under: a member that checks only that fn raised, which is exactly what assertError does.
  local ok, err = pcall(T.assertErrorMatches,
    function() error("an unrelated failure", 0) end, "descriptor.name", "the name is required")
  assertFalse(ok, "a raise without the needle must fail the assertion")
  assertTrue(has(err, "descriptor.name"), "the failure names the needle: " .. tostring(err))
  assertTrue(has(err, "an unrelated failure"), "the failure names what was raised: " .. tostring(err))
  assertTrue(has(err, "the name is required"), "the failure carries the caller's message: "
    .. tostring(err))
end)

test("kit: assertErrorMatches fails when fn does not raise", function()
  -- red under: a member that treats a clean return as a match (an empty error string contains no
  -- needle, but a member that skipped the pcall result would never look).
  local ok, err = pcall(T.assertErrorMatches, function() return 1 end, "anything")
  assertFalse(ok, "a function that returns normally must fail the assertion")
  assertTrue(has(err, "anything"), "the failure names the needle it was waiting for: "
    .. tostring(err))
  assertTrue(has(err, "no error"), "the failure says nothing was raised: " .. tostring(err))
end)
