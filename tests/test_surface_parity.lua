-- tests/test_surface_parity.lua — the degradation-stub gate, asserted here first.
--
-- Nine addons in this collection hand-write a `settings/OptionsSetup.lua` degradation arm that
-- mirrors the `LibKa0s-Options-1.0` surface — MultiMeters 384 lines, AbsorbTracker 369, KickCD 351,
-- and six more. A stub is a second implementation of somebody else's surface, so it drifts the
-- moment the library grows a member the host starts calling, and it drifts SILENTLY: the live path
-- stays green and the degraded path raises in exactly the install the stub exists for.
-- AbsorbTracker's stub omits `SetRenderer` outright today with every suite in that repo green.
--
-- `Kit.assertSurfaceParity(stub, majorName)` is what closes that, and this file is the reference
-- implementation of the case the nine are asked to write. The library cannot publish a no-op
-- surface to stand in for itself — a published stand-in would have to live in the payload that is
-- BY DEFINITION absent on the path the stub exists for — so the check is kit-side and reads the
-- live major instead.
--
-- LibKa0s ships no degradation stub of its own, so the stubs here are BUILT from the live surface
-- and then damaged one member at a time. That is the honest thing to assert in this repo: what is
-- under test is the gate, not a stub, and a gate that cannot tell a whole surface from a surface
-- with a hole in it is what nine repos would then be trusting.

local T = _G.LK_TEST
local test, assertTrue, assertEqual, assertError = T.test, T.assertTrue, T.assertEqual, T.assertError

local MAJOR = "LibKa0s-Slash-1.0"

--- A stub of `MAJOR`'s public surface, with the named members left out.
---
--- Built through `T.publicMembers` rather than by walking the live table here, because that is the
--- rule the assertion itself applies — bookkeeping (`MINOR`, `MODULES`) and `__`-prefixed internals
--- are not surface. Writing the walk a second time in this file would let the two definitions
--- disagree and would test the copy.
local function stubOf(drop)
  local omit = {}
  for _, name in ipairs(drop or {}) do omit[name] = true end
  local live = T.mocks.LibStub(MAJOR)
  local stub = {}
  for _, member in ipairs(T.publicMembers(live)) do
    if not omit[member.name] then stub[member.name] = live[member.name] end
  end
  return stub, live
end

test("parity: a stub carrying every public member of a live major passes", function()
  local stub, live = stubOf()
  -- The load-bearing half of this case is what the stub does NOT carry. It has no MINOR, no
  -- MODULES and none of the pairing dunders, exactly like every degradation arm in the collection,
  -- and an assertion that walked the live table raw would report every one of them as a hole. Six
  -- false divergences per major is a gate nobody adopts.
  assertTrue(live.MINOR ~= nil, "the live major carries MINOR (otherwise this case proves nothing)")
  assertEqual(stub.MINOR, nil, "the stub carries no MINOR")
  assertEqual(stub.MODULES, nil, "the stub carries no MODULES")
  T.assertSurfaceParity(stub, MAJOR)
end)

test("parity: a stub missing one member fails and names it", function()
  local stub = stubOf{ "FormatKV" }
  local err = assertError(function() T.assertSurfaceParity(stub, MAJOR) end)
  assertTrue(err:find("FormatKV", 1, true) ~= nil,
    "the failure must name the missing member; got: " .. err)
end)

test("parity: every divergence lands in one message", function()
  -- A stub written from a stale surface is typically wrong in several places, and one-at-a-time is
  -- one test run per missing member.
  local stub = stubOf{ "FormatKV", "FormatRow" }
  local err = assertError(function() T.assertSurfaceParity(stub, MAJOR) end)
  assertTrue(err:find("FormatKV", 1, true) ~= nil, "names the first: " .. err)
  assertTrue(err:find("FormatRow", 1, true) ~= nil, "names the second: " .. err)
  assertTrue(err:find("2 place(s)", 1, true) ~= nil, "counts both: " .. err)
end)

test("parity: a member that is a function live and something else degraded is reported", function()
  -- `Helpers.Refresh = UI and UI.Refresh` is the shape. When UI is present but the member is not,
  -- the key IS set — to false — and a check that only asks "is the key set?" waves it through
  -- while the call site raises anyway.
  local stub = stubOf()
  stub.FormatKV = false
  local err = assertError(function() T.assertSurfaceParity(stub, MAJOR) end)
  assertTrue(err:find("FormatKV is a function live but boolean degraded", 1, true) ~= nil,
    "the failure must say what the member became; got: " .. err)
end)

test("parity: a member left out on purpose is named as data, not omitted in silence", function()
  -- An intentional omission and a bug are otherwise indistinguishable, and the usual resolution
  -- for that is to delete the case. Both documented shapes of `ignore` reach the by-name form.
  local stub = stubOf{ "FormatKV" }
  T.assertSurfaceParity(stub, MAJOR, { FormatKV = true })
  T.assertSurfaceParity(stub, MAJOR, { "FormatKV" })
end)

test("parity: a major the surface source cannot resolve fails rather than passes", function()
  local err = assertError(function()
    T.assertSurfaceParity(stubOf(), "LibKa0s-NotAMajor-1.0")
  end)
  assertTrue(err:find("LibKa0s-NotAMajor-1.0", 1, true) ~= nil, "names the major: " .. err)
end)

test("parity: with no surface source registered the gate fails rather than passes", function()
  -- The bargain tests/test_kitsync.lua, tests/test_prose.lua and testkit/test_eol.lua all strike: a
  -- gate that goes quiet when it cannot look reports success, which is worse than not existing.
  -- A consumer whose harness does not hand the kit a LibStub must be told so, once, loudly.
  local restore = T.setSurfaceSource(nil)
  local ok, err = pcall(function() T.assertSurfaceParity(stubOf(), MAJOR) end)
  T.setSurfaceSource(restore)
  assertTrue(not ok, "the assertion must raise when there is no source to resolve the major with")
  assertTrue(tostring(err):find("setSurfaceSource", 1, true) ~= nil,
    "the failure must name the fix; got: " .. tostring(err))
end)
