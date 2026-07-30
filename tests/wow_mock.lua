-- LibKa0s's WoW-API mock: the shared base (testkit/mock_base.lua, vendored to tests/_kit/) plus the
-- one API the library itself reads that the base deliberately leaves alone.
--
-- Returns a builder so each run gets a fresh, isolated environment. Everything universal — frames,
-- timers, the stopwatch, the Settings canvas API, LibStub, the Ace fakes — lives in the kit and is
-- documented there, including its fidelity rules.
--
-- Note this repo consumes its own kit through tests/_kit/ rather than reaching into testkit/
-- directly. That is deliberate: it makes LibKa0s a consumer on exactly the same terms as every
-- addon, so `diff -r testkit tests/_kit` is the same gate here as it is downstream, and a kit change
-- that breaks a consumer breaks this repo first.

local base = dofile("tests/_kit/mock_base.lua")

return function()
  local M = base()

  -- Addon metadata, for the `interface` field a perf record stamps. Left out of the base on
  -- purpose: it is the target of every addon's Compat shim, and those shims are tested by swapping
  -- `_G.C_AddOns` to nil to reach the deprecated-global fallback. A base-level stub resolves ahead
  -- of _G and makes that branch unreachable.
  M.C_AddOns = { GetAddOnMetadata = function() return "120007" end }

  -- This repo's suites assert that a capture's context records the character's LOCALISED class
  -- name rather than the token, so the fixture character is a Death Knight — the pair where the two
  -- strings differ most obviously. The base defaults to a Mage, where they differ only by case and
  -- a swapped return would go unnoticed.
  M.__context.class      = "Death Knight"
  M.__context.classToken = "DEATHKNIGHT"

  return M
end
