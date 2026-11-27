-- tests/fixture_verdict.lua -- the bench the LibKa0s-Verdict-1.0 suites share: the live major, and
-- each client's kernel in the shape Ka0s Drop Watcher's own kernel suites call it, so the cases
-- ported from them (test_evaluate, test_offspec, test_tier_token) read as they did there.
--
-- Drop Watcher's suites loaded a namespace with one class list installed and called
-- NS.Evaluate.Evaluate(facts, candidate, opts). Here the client is the caller's, so `F.kernel(client)`
-- answers E, C and CD for that client: E.Evaluate names it in `opts.client` (the caller's opts table
-- is copied, never written), E.Equippability passes it, C is lib.C with that client's SLOT and
-- SLOT_PLAN, and CD is its class list.

local T = _G.LK_TEST
local V = T.mocks.LibStub("LibKa0s-Verdict-1.0")

local F = { V = V }

local function withClient(opts, client)
  if opts ~= nil and type(opts) ~= "table" then return opts end   -- junk input passes through
  local out = {}
  for k, v in pairs(opts or {}) do out[k] = v end
  if out.client == nil then out.client = client end
  return out
end

local cache = {}

--- The kernel of `client` ("retail" | "forever") in Drop Watcher's shape: E, C, CD.
function F.kernel(client)
  if cache[client] then return cache[client].E, cache[client].C, cache[client].CD end
  local E = {
    Evaluate = function(facts, candidate, opts) return V.Evaluate(facts, candidate, withClient(opts, client)) end,
    Equippability = function(facts, candidate) return V.Equippability(facts, candidate, client) end,
    ItemVerdict = V.ItemVerdict, TrackDelta = V.TrackDelta, SubClassKey = V.SubClassKey,
  }
  local C = setmetatable({ SLOT = V.C.SlotsFor(client), SLOT_PLAN = V.C.SlotPlanFor(client) }, { __index = V.C })
  cache[client] = { E = E, C = C, CD = V.ClassData.ForClient(client) }
  return E, C, cache[client].CD
end

return F
