-- A throwaway host for the library under test. Each Fixture.new() is a fresh instance with its own
-- state, which is the point: the lib's central promise is that hosts share nothing.

local T = _G.LK_TEST
local Fixture = {}

-- `rec` captures everything the instance sends outward, so a test can assert on the host contract
-- (what got logged, what got printed, whether suspend actually fired) rather than on internals.
function Fixture.new(overrides)
  local rec = { log = {}, chat = {}, calls = {}, decorated = nil }
  local d = {
    name    = "TestHost",
    title   = "Test Host",
    slash   = "/th",
    version = "1.2.3",
    sv      = "TestHostPerfDB",
    buckets = {
      { key = "outer" },
      { key = "inner", within = "outer" },
    },
    suspend = function() rec.calls[#rec.calls + 1] = "suspend" end,
    resume  = function() rec.calls[#rec.calls + 1] = "resume"  end,
    log     = function(line) rec.log[#rec.log + 1] = line end,
    print   = function(line) rec.chat[#rec.chat + 1] = line end,
  }
  for k, v in pairs(overrides or {}) do d[k] = v end
  _G[d.sv] = nil                       -- every fixture starts with an empty ring
  T.mocks.__profileMs = 0
  T.mocks.__inCombat  = false
  T.mocks.__stopwatch = {}
  return T.lib:New(d), rec
end

return Fixture
