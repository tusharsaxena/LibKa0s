-- tests/test_kit_asserts.lua — Kit.assertErrorMatches and Kit.assertLibraryConstant (kit
-- revision 26).
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

-- ── Kit.assertLibraryConstant ────────────────────────────────────────────────────────────────
--
-- A library-absent Slash stub may carry exactly one library string verbatim, `LibKa0s-Slash-1.0`'s
-- `DISABLED_LINE_FORMAT` (`slash-commands-§1`), and must pin it against the live library so the copy
-- cannot drift. `assertLibraryConstant` is that pin: it resolves the major through the registered
-- surface source, falls back to the harness's LibStub when the source maps the name to an INSTANCE
-- that does not carry the member, and compares byte for byte.

local SLASH = "LibKa0s-Slash-1.0"

test("kit: assertLibraryConstant passes on the live bytes, and on a dotted member path", function()
  -- red under: the member not existing, or not being exposed by Kit.expose.
  T.assertLibraryConstant(T.slash.DISABLED_LINE_FORMAT, SLASH, "DISABLED_LINE_FORMAT")
  T.assertLibraryConstant("%s is disabled \226\128\148 enable it with |cFFFFFF00%s|r", SLASH,
    "DISABLED_LINE_FORMAT", "the stub's hand-carried copy")
  T.assertLibraryConstant(T.slash.STRINGS.NO_DEFAULT, SLASH, "STRINGS.NO_DEFAULT")
end)

test("kit: assertLibraryConstant fails on a one-byte difference, naming both strings", function()
  -- red under: a comparison that ignores case or the multibyte dash, or a failure that names only
  -- one side (the reader then has to go and find the other).
  -- Both copies keep the live length, so a length-only comparator stays green on them: the em
  -- dash's last byte turned into an en dash's (\148 -> \147), and one letter's case flipped.
  local live = T.slash.DISABLED_LINE_FORMAT
  local copies = { (live:gsub("\148", "\147")), (live:gsub("disabled", "Disabled", 1)) }
  for _, copy in ipairs(copies) do
    assertEqual(#live, #copy, "the fixture keeps the live length")
    assertTrue(copy ~= live, "the fixture differs from the live bytes")
    local ok, err = pcall(T.assertLibraryConstant, copy, SLASH, "DISABLED_LINE_FORMAT", "stub line")
    assertFalse(ok, "a copy that differs by one byte must fail: " .. ("%q"):format(copy))
    assertTrue(has(err, "stub line"), "the failure carries the caller's message: " .. tostring(err))
    assertTrue(has(err, ("%q"):format(copy)), "the failure names the copy: " .. tostring(err))
    assertTrue(has(err, ("%q"):format(live)), "the failure names the live bytes: " .. tostring(err))
    assertTrue(has(err, "DISABLED_LINE_FORMAT"), "the failure names the member: " .. tostring(err))
  end
end)

test("kit: assertLibraryConstant fails clearly on an unknown major or member", function()
  -- red under: a member that answers nil for an unresolved name and then compares nil to nil, or
  -- that raises an index error on the way instead of saying what did not resolve.
  local ok, err = pcall(T.assertLibraryConstant, "x", "LibKa0s-Nope-1.0", "DISABLED_LINE_FORMAT")
  assertFalse(ok, "an unknown major must fail")
  assertTrue(has(err, "LibKa0s-Nope-1.0"), "the failure names the major: " .. tostring(err))
  assertTrue(has(err, "did not resolve"), "the failure says it did not resolve: " .. tostring(err))

  ok, err = pcall(T.assertLibraryConstant, nil, SLASH, "NO_SUCH_FORMAT")
  assertFalse(ok, "a member the library does not carry must fail, even against a nil copy")
  assertTrue(has(err, "NO_SUCH_FORMAT"), "the failure names the member: " .. tostring(err))
end)

test("kit: assertLibraryConstant falls back to LibStub when the source maps the name to an "
  .. "instance", function()
  -- red under: reading the member off the registered source only. AbsorbTracker's and WhatGroup's
  -- runners map "LibKa0s-Slash-1.0" to the Slash INSTANCE (`NS.Slash.__cli`) for the parity gate,
  -- and `DISABLED_LINE_FORMAT` is lib-level, so without the fallback neither could pin its stub.
  local instance = { OnSlash = function() end, DisabledLine = function() end }
  local restore = T.setSurfaceSource{ [SLASH] = instance }
  local ok, err = pcall(T.assertLibraryConstant, T.slash.DISABLED_LINE_FORMAT, SLASH,
    "DISABLED_LINE_FORMAT")
  local okOther, errOther = pcall(T.assertLibraryConstant, "x", SLASH, "DISABLED_LINE_FORMAT")
  T.setSurfaceSource(restore)
  assertTrue(ok, "the live bytes resolve through the LibStub fallback: " .. tostring(err))
  assertFalse(okOther, "the fallback still compares")
  assertTrue(has(errOther, ("%q"):format(T.slash.DISABLED_LINE_FORMAT)),
    "and names the library's bytes: " .. tostring(errOther))
end)
