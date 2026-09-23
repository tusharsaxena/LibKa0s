-- tests/test_mock_events.lua — the kit's event surfaces beyond AceEvent (revision 26).
--
-- Three client surfaces the kit did not model, each of which let a consumer suite pass over a case
-- the client would have failed:
--
--   * `EventRegistry`, whose callbacks never reached `M.__registrations()`, so a stand-down suite
--     could not see a surviving `EditMode.Exit` callback (review finding `PartyFrameEnhanced-R-10`);
--   * a raw `frame:RegisterEvent` / `frame:RegisterUnitEvent`, which recorded any name at all where
--     the client raises on an unknown one -- only the AceEvent path honored `M.__badEvents`;
--   * `C_EventUtils.IsEventValid`, the client's own answer to "would that raise?".
--
-- Every case builds a fresh mock, for the reason `tests/test_mock_record.lua` gives: a count is only
-- legible over a build nobody else has touched.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse
local assertNil, assertErrorMatches = T.assertNil, T.assertErrorMatches

local buildMocks = dofile("tests/wow_mock.lua")

--- The live `kind = "callback"` rows, in the survey's order.
local function callbacks(M)
  local out = {}
  for _, reg in ipairs(M.__registrations()) do
    if reg.kind == "callback" then out[#out + 1] = reg end
  end
  return out
end

--- Every live registration rendered `kind:event`, so a case can assert on the whole set.
local function names(M)
  local out = {}
  for _, reg in ipairs(M.__registrations()) do out[#out + 1] = reg.kind .. ":" .. reg.event end
  return table.concat(out, ",")
end

-- ── EventRegistry ──────────────────────────────────────────────────────────────────────────

test("events: an EventRegistry callback appears in __registrations as kind 'callback'", function()
  -- red under: no EventRegistry in the kit (the survey never sees the callback)
  local M = buildMocks()
  local owner = {}
  local returned = M.EventRegistry:RegisterCallback("EditMode.Exit", function() end, owner)
  assertEqual(returned, owner, "RegisterCallback answers the owner, as CallbackRegistry does")
  local rows = callbacks(M)
  assertEqual(#rows, 1)
  assertEqual(rows[1].event, "EditMode.Exit")
  assertEqual(rows[1].owner, owner)
  assertNil(rows[1].target, "a callback row carries its owner, not a target")
end)

test("events: UnregisterCallback removes the callback from __registrations", function()
  -- red under: make UnregisterCallback a no-op in testkit/mock_events.lua
  local M = buildMocks()
  local a, b = {}, {}
  M.EventRegistry:RegisterCallback("EditMode.Exit", function() end, a)
  M.EventRegistry:RegisterCallback("EditMode.Exit", function() end, b)
  M.EventRegistry:UnregisterCallback("EditMode.Exit", a)
  local rows = callbacks(M)
  assertEqual(#rows, 1, "only the owner that unregistered is gone")
  assertEqual(rows[1].owner, b)
  M.EventRegistry:UnregisterCallback("EditMode.Exit", b)
  assertEqual(#callbacks(M), 0, "and the survey is empty once both have")
end)

test("events: one callback per (event, owner) -- a second registration replaces the first", function()
  -- red under: append instead of replace in RegisterCallback
  local M = buildMocks()
  local owner, hits = {}, {}
  M.EventRegistry:RegisterCallback("EditMode.Exit", function() hits[#hits + 1] = "first" end, owner)
  M.EventRegistry:RegisterCallback("EditMode.Exit", function() hits[#hits + 1] = "second" end, owner)
  assertEqual(#callbacks(M), 1)
  M.EventRegistry:TriggerEvent("EditMode.Exit")
  assertEqual(table.concat(hits, ","), "second")
end)

test("events: TriggerEvent reaches a live callback as func(owner, ...) and skips a removed one", function()
  -- red under: make TriggerEvent a no-op in testkit/mock_events.lua
  local M = buildMocks()
  local owner, gone = {}, {}
  local seen, goneRan = nil, false
  M.EventRegistry:RegisterCallback("SetItemRef", function(self, link, text)
    seen = { self = self, link = link, text = text }
  end, owner)
  M.EventRegistry:RegisterCallback("SetItemRef", function() goneRan = true end, gone)
  M.EventRegistry:UnregisterCallback("SetItemRef", gone)
  M.EventRegistry:TriggerEvent("SetItemRef", "addon:x", "[x]")
  assertTrue(seen ~= nil, "the live callback ran")
  assertEqual(seen.self, owner)
  assertEqual(seen.link, "addon:x")
  assertEqual(seen.text, "[x]")
  assertFalse(goneRan, "an unregistered owner is not reached")
end)

test("events: RegisterCallback refuses what CallbackRegistry refuses", function()
  -- red under: drop the argument checks from RegisterCallback
  local M = buildMocks()
  local ER = M.EventRegistry
  assertErrorMatches(function() ER:RegisterCallback(1, function() end, {}) end,
    "RegisterCallback 'event' requires string type.")
  assertErrorMatches(function() ER:RegisterCallback("E", "notAFunction", {}) end,
    "RegisterCallback 'func' requires function type.")
  assertErrorMatches(function() ER:RegisterCallback("E", function() end, 7) end,
    "RegisterCallback 'owner' as number is reserved internally.")
  assertErrorMatches(function() ER:RegisterCallback("E", function() end, {}, "bound") end,
    "the closure form of RegisterCallback is not modeled")
  assertErrorMatches(function() ER:UnregisterCallback("E", nil) end,
    "UnregisterCallback 'owner' is required.")
  assertEqual(#callbacks(M), 0, "and nothing refused was stored")
end)

test("events: a callback registered with no owner gets a generated numeric owner", function()
  -- red under: store an ownerless callback under nil
  local M = buildMocks()
  local id = M.EventRegistry:RegisterCallback("EditMode.Enter", function() end)
  assertEqual(type(id), "number")
  assertEqual(callbacks(M)[1].owner, id)
  M.EventRegistry:UnregisterCallback("EditMode.Enter", id)
  assertEqual(#callbacks(M), 0)
end)

test("events: callback rows follow the other kinds, ordered by event then registration", function()
  -- red under: return callback rows in pairs() order
  local M = buildMocks()
  local f = M.CreateFrame("Frame")
  f:RegisterEvent("PLAYER_LOGIN")
  M.EventRegistry:RegisterCallback("b.Event", function() end, {})
  M.EventRegistry:RegisterCallback("a.Event", function() end, {})
  assertEqual(names(M), "frame:PLAYER_LOGIN,callback:a.Event,callback:b.Event")
end)

test("events: each build has its own EventRegistry", function()
  -- red under: hold the callback table at module scope in testkit/mock_events.lua
  local first, second = buildMocks(), buildMocks()
  first.EventRegistry:RegisterCallback("EditMode.Exit", function() end, {})
  assertEqual(#callbacks(second), 0)
end)

-- ── frame registration honors __badEvents ──────────────────────────────────────────────────

test("events: frame:RegisterEvent raises on a name in __badEvents, and records nothing", function()
  -- red under: the frame stub's RegisterEvent without the __badEvents check
  local M = buildMocks()
  M.__badEvents = { BAD = true }
  local f = M.CreateFrame("Frame")
  assertErrorMatches(function() f:RegisterEvent("BAD") end,
    'Attempt to register unknown event "BAD"')
  assertFalse(f:IsEventRegistered("BAD"), "the client registers nothing when it raises")
  f:RegisterEvent("PLAYER_LOGIN")
  assertEqual(names(M), "frame:PLAYER_LOGIN", "a known name still registers")
end)

test("events: frame:RegisterUnitEvent raises on a name in __badEvents, and records nothing", function()
  -- red under: the frame stub's RegisterUnitEvent without the __badEvents check
  local M = buildMocks()
  M.__badEvents = { BAD_UNIT = true }
  local f = M.CreateFrame("Frame")
  assertErrorMatches(function() f:RegisterUnitEvent("BAD_UNIT", "player") end,
    'Attempt to register unknown event "BAD_UNIT"')
  f:RegisterUnitEvent("UNIT_AURA", "player")
  assertEqual(names(M), "unit:UNIT_AURA", "only the known name is recorded")
end)

test("events: the frame path reads __badEvents at call time", function()
  -- red under: capture M.__badEvents when the frame is built
  local M = buildMocks()
  local f = M.CreateFrame("Frame")
  f:RegisterEvent("LATER_BAD")
  M.__badEvents = { LATER_BAD = true }
  assertErrorMatches(function() f:RegisterEvent("LATER_BAD") end,
    'Attempt to register unknown event "LATER_BAD"')
  M.__badEvents = {}
  f:RegisterEvent("LATER_BAD")
  assertTrue(f:IsEventRegistered("LATER_BAD"))
end)

test("events: the frame raise names the caller, not the kit", function()
  -- red under: raise at level 1 inside the frame stub's wrapper
  local M = buildMocks()
  M.__badEvents = { BAD = true }
  local f = M.CreateFrame("Frame")
  local err = assertErrorMatches(function() f:RegisterEvent("BAD") end, "BAD")
  assertTrue(err:find("test_mock_events.lua", 1, true) ~= nil,
    "the position is this suite's line, as the client names the addon's: " .. err)
end)

-- ── C_EventUtils.IsEventValid ──────────────────────────────────────────────────────────────

test("events: C_EventUtils.IsEventValid answers false for a bad name and true otherwise", function()
  -- red under: no C_EventUtils in the kit
  local M = buildMocks()
  M.__badEvents = { BAD = true }
  assertFalse(M.C_EventUtils.IsEventValid("BAD"))
  assertTrue(M.C_EventUtils.IsEventValid("PLAYER_LOGIN"))
  M.__badEvents = {}
  assertTrue(M.C_EventUtils.IsEventValid("BAD"), "read at call time, like the frame path")
end)

test("events: a suite may remove C_EventUtils to model an older client", function()
  -- red under: make the frame path consult M.C_EventUtils instead of M.__badEvents
  local M = buildMocks()
  M.C_EventUtils = nil
  M.__badEvents = { BAD = true }
  local f = M.CreateFrame("Frame")
  assertErrorMatches(function() f:RegisterEvent("BAD") end,
    'Attempt to register unknown event "BAD"')
  f:RegisterEvent("PLAYER_LOGIN")
  assertTrue(f:IsEventRegistered("PLAYER_LOGIN"))
end)
