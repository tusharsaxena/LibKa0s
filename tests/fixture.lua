-- A throwaway host for the library under test. Each Fixture.new() is a fresh instance with its own
-- state, which is the point: the lib's central promise is that hosts share nothing.

local T = _G.LK_TEST
local Fixture = {}

-- `rec` captures everything the instance sends outward, so a test can assert on the host contract
-- (what got logged, what got printed, whether suspend actually fired) rather than on internals.
--- A host plus its recorder. `rec.calls` is the edge log, and it records what the LATCH fired
--- rather than what the probe called: since Perf minor 12 the probe takes and releases a named hold
--- and the host's teardown is reached through LibKa0s-Lifecycle-1.0, so "suspend" here means
--- standDown actually ran — which is the only thing a case about suspension should be asserting on.
function Fixture.new(overrides)
  local rec = { log = {}, chat = {}, calls = {}, decorated = nil }
  local lc = T.lifecycle:New{
    name      = "TestHost",
    standDown = function() rec.calls[#rec.calls + 1] = "suspend" end,
    standUp   = function() rec.calls[#rec.calls + 1] = "resume"  end,
  }
  local d = {
    lifecycle = lc,
    name    = "TestHost",
    title   = "Test Host",
    slash   = "/th",
    version = "1.2.3",
    sv      = "TestHostPerfDB",
    buckets = {
      { key = "outer" },
      { key = "inner", within = "outer" },
    },
    log     = function(line) rec.log[#rec.log + 1] = line end,
    print   = function(line) rec.chat[#rec.chat + 1] = line end,
  }
  for k, v in pairs(overrides or {}) do d[k] = v end
  _G[d.sv] = nil                       -- every fixture starts with an empty ring
  T.mocks.__profileMs = 0
  T.mocks.__inCombat  = false
  T.mocks.__stopwatch = {}
  rec.lifecycle = lc
  return T.lib:New(d), rec
end

return Fixture
