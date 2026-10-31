-- tests/test_sim_host.lua -- a DropWatcher-shaped mini host on LibKa0s-Sim-1.0, driven end to end.
--
-- The other test_sim_* suites pin one member at a time. This one wires a whole host the way a real
-- one is wired (OWNER_SCOPE C.10: DropWatcher's migration is the contract proof, and this is its
-- library-side half): a Compat table with pure, guarded and plain members wrapped at load; a
-- deliver over an ordered handler table that skips an event the host rejects; a refusal; a prepare
-- that builds the world asynchronously; three steps behind a gate; an OnStopGuarded and an OnStop
-- registration; and a stood-down latch. It drives start -> RunVerb("run") -> stop, and a stand-down
-- mid-run, and asserts what every host suite owes:
--
--   * seam:Unwrapped() is empty after load (C.8: no auto-wrap metatable, so the host checks);
--   * no guarded member reaches the client while a session is active;
--   * the host's own table carries the host fields and the instance gains none (C.4);
--   * the stop runs guarded -> seam off -> cleanup, and a stand-down suppresses DeliverForCleanup;
--   * no timer outlives its session, and nothing is written to a SavedVariables-shaped global.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local F = dofile("tests/fixture_sim_panel.lua")

-- The instance surface the library publishes (docs/api/Sim, "Instance members", and the three
-- files' members). The C.4 case asserts a driven instance's key set is exactly this.
local PUBLISHED = {
  "AddListener", "After", "DeliverForCleanup", "Fire", "HidePanel", "IsActive", "IsDelivering",
  "IsPanelShown", "OnStop", "OnStopGuarded", "PanelRows", "Pause", "RefreshPanel", "ResetPanelPosition",
  "Restart", "Resume", "Run", "RunVerb", "Session", "ShowPanel", "Start", "Status", "Step", "Steps",
  "Stop", "TogglePanel",
}

local SV_NAME = "MiniHostDB"

--- A deep, ordered serialization: the before/after comparison of a SavedVariables-shaped table.
local function dump(v)
  if type(v) ~= "table" then return type(v) .. ":" .. tostring(v) end
  local keys = {}
  for k in pairs(v) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  local parts = {}
  for _, k in ipairs(keys) do parts[#parts + 1] = tostring(k) .. "=" .. dump(v[k]) end
  return "{" .. table.concat(parts, ",") .. "}"
end

--- Build the mini host on a fresh, fully loaded environment. Answers NS: NS.Compat (wrapped),
--- NS.SimSeam, NS.Sim (the library instance), NS.SimHost (the host's own table), NS.live (what
--- reached the client) and NS.order (the stop's steps as they ran).
local function miniHost()
  local m, Sim = F.env()
  m[SV_NAME] = { profile = { enabled = true, sent = 0 }, global = { seen = { 1, 2 } } }
  local NS = { m = m, printed = {}, live = { ChatSender = 0, UnitName = 0 }, order = {} }

  -- A host's core/Compat.lua: a pure helper, a plain client reader and a guarded outward action.
  NS.Compat = {
    FoldName = function(s) return (tostring(s):gsub("%-.*$", "")) end,
    UnitName = function(unit) NS.live.UnitName = NS.live.UnitName + 1; return "Live-" .. tostring(unit) end,
    ChatSender = function(msg) NS.live.ChatSender = NS.live.ChatSender + 1; return "sent " .. tostring(msg) end,
  }

  -- The host's own table (C.4). Every host field lives here, never on NS.Sim.
  NS.SimHost = { world = nil, counts = { sent = 0, cleanup = 0 }, log = {}, testMode = false, stoodDown = false,
    settle = 0 }
  local H = NS.SimHost

  -- A host's core/SimSetup.lua, straight after the Compat files: wrap at load.
  NS.SimSeam = Sim:NewSeam(NS.Compat, {
    name = "MiniHost",
    pure = { FoldName = true },
    guarded = { ChatSender = function(msg) H.counts.sent = H.counts.sent + 1; return "sim " .. tostring(msg) end },
  })
  NS.SimSeam:SetProvider("UnitName", function(fallback, unit)
    local world = H.world
    if world and world.names[unit] then return world.names[unit] end
    return fallback(unit)
  end)

  -- The client's handler set, in order; REJECTED_EVENT is one the host refuses to reproduce.
  local handlers = {
    LOOT_READY = { function(n) H.log[#H.log + 1] = "loot:" .. tostring(n) end },
    CHAT_MSG_LOOT = {
      function(msg) H.log[#H.log + 1] = "chat:" .. tostring(msg) end,
      function() H.log[#H.log + 1] = "chat:second" end,
    },
    SIM_CLEANUP = { function() H.counts.cleanup = H.counts.cleanup + 1; H.log[#H.log + 1] = "cleanup" end },
  }
  local rejected = { REJECTED_EVENT = true }
  local function deliver(event, ...)
    if rejected[event] then return 0 end
    local n = 0
    for _, fn in ipairs(handlers[event] or {}) do fn(...); n = n + 1 end
    return n
  end

  local plays = {
    loot = function() NS.Sim:Fire("LOOT_READY", 3); H.settle = 1 end,
    chat = function()
      NS.Compat.ChatSender("hi")
      NS.Sim:Fire("CHAT_MSG_LOOT", "Ka0s receives loot")
      H.rejectedAnswer = NS.Sim:Fire("REJECTED_EVENT")
    end,
    trade = function() H.tradeWith = NS.Compat.UnitName("target") end,
  }

  NS.Sim = Sim:New({
    name = "MiniHost", seam = NS.SimSeam, slash = "/mini sim",
    deliver = deliver,
    isStoodDown = function() return H.stoodDown end,
    refusal = function() if H.testMode then return "Leave test mode first." end end,
    gate = function()
      if H.settle > 0 then H.settle = H.settle - 1; return false, "Waiting for the loot window." end
      return true
    end,
    stepDelay = 1,
    scenarios = { names = { "loot" }, defs = { loot = { label = "Loot", timeline = function()
      return { { kind = "loot", label = "Loot" }, { kind = "chat", label = "Chat" }, { kind = "trade", label = "Trade" } }
    end } } },
    prepare = function(_, _, _, ready)
      NS.Sim:After(0.1, function()
        H.world = { names = { target = "Simmed-Target" } }
        ready()
      end)
    end,
    play = function(step) plays[step.kind]() end,
    stopText = { standDown = "Simulation stopped: MiniHost is disabled." },
    print = function(line) NS.printed[#NS.printed + 1] = line end,
    panel = { title = "Mini simulator" },
  })

  NS.Sim:OnStopGuarded(function()
    NS.order[#NS.order + 1] = "guarded"
    NS.guardedActive = NS.Sim:IsActive()
    NS.guardedSend = NS.Compat.ChatSender("bye")      -- still guarded: the seam answers
  end)
  NS.Sim:OnStop(function(_, reason)
    NS.order[#NS.order + 1] = "onStop"
    NS.onStopActive = NS.Sim:IsActive()
    NS.onStopReason = reason
    NS.cleanupAnswer = NS.Sim:DeliverForCleanup("SIM_CLEANUP")
    H.world = nil
  end)
  NS.Sim:AddListener(function()
    if NS.Sim:Session() == nil and not NS.listenedIdle then
      NS.listenedIdle = true
      NS.order[#NS.order + 1] = "listener"
    end
  end)

  -- The host's stand-down: the latch, then Stop("standDown") as the first stand-down step (H6).
  function NS.StandDown()
    H.stoodDown = true
    NS.Sim:Stop("standDown")
  end
  return NS
end

--- Fire pending timers until none is left, bounded so a self-rearming timer fails the case.
local function drain(m)
  for _ = 1, 20 do
    if m.__fireTimers() == 0 then return end
  end
  error("timers kept rearming after 20 passes")
end

local function sortedKeys(t)
  local out = {}
  for k in pairs(t) do out[#out + 1] = tostring(k) end
  table.sort(out)
  return table.concat(out, ",")
end

--- The globals of env `m` that are not `__` kit bookkeeping.
local function globalKeys(m)
  local out = {}
  for k in pairs(m) do
    if type(k) == "string" and k:sub(1, 2) ~= "__" then out[k] = true end
  end
  return out
end

--- Start the scenario and let prepare's async world build land.
local function started(NS)
  assertTrue(NS.Sim:Start({ scenario = "loot" }))
  local s, code = NS.Sim:Step()
  assertNil(s); assertEqual(code, "building", "not ready before the world")
  NS.m.__fireTimers()
  assertTrue(NS.Sim:Status().ready, "the world built, ready() called")
end

-- -- load ------------------------------------------------------------------------------------------

test("sim host: after load every non-pure Compat member is wrapped, and Unwrapped() is empty", function()
  local NS = miniHost()
  assertEqual(#NS.SimSeam:Unwrapped(), 0, "the assertion every host suite owes (C.8)")
  assertEqual(table.concat(NS.SimSeam:Keys(), ","), "ChatSender,UnitName", "FoldName is pure")
  -- And the assertion has teeth: a member added after NewSeam shows up.
  NS.Compat.Late = function() end
  assertEqual(table.concat(NS.SimSeam:Unwrapped(), ","), "Late")
end)

test("sim host: idle, every wrapped member reaches the client", function()
  local NS = miniHost()
  assertEqual(NS.Compat.UnitName("target"), "Live-target")
  assertEqual(NS.Compat.ChatSender("x"), "sent x")
  assertEqual(NS.live.UnitName, 1); assertEqual(NS.live.ChatSender, 1)
end)

-- -- refusal ---------------------------------------------------------------------------------------

test("sim host: the host's refusal stops a start before anything is built", function()
  local NS = miniHost()
  NS.SimHost.testMode = true
  local ok, line = NS.Sim:Start({ scenario = "loot" })
  assertFalse(ok); assertEqual(line, "Leave test mode first.")
  assertFalse(NS.Sim:IsActive())
  assertEqual(NS.m.__fireTimers(), 0, "prepare never ran, so no world timer")
  assertNil(NS.SimHost.world)
end)

-- -- start -> run -> stop --------------------------------------------------------------------------

test("sim host: start, RunVerb('run') and stop, end to end", function()
  local NS = miniHost()
  local H = NS.SimHost
  local svBefore = dump(NS.m[SV_NAME])
  local globalsBefore = globalKeys(NS.m)

  started(NS)
  assertTrue(NS.Sim:RunVerb("run"), "run accepted")
  drain(NS.m)

  -- The three steps played, through the gate, with the rejected event skipped.
  local st = NS.Sim:Status()
  assertEqual(st.pos, 3); assertEqual(st.total, 3); assertFalse(st.playing)
  assertEqual(table.concat(H.log, "|"), "loot:3|chat:Ka0s receives loot|chat:second")
  assertEqual(H.rejectedAnswer, 0, "deliver skipped the rejected event")
  local waited = false
  for _, line in ipairs(NS.printed) do
    if line == "Waiting for the loot window." then waited = true end
  end
  assertTrue(waited, "the closed gate printed its line once")
  assertEqual(H.tradeWith, "Simmed-Target", "the provider answered from the host's world")

  -- No guarded member reached the client while active.
  assertEqual(NS.live.ChatSender, 0)
  assertEqual(NS.live.UnitName, 0, "the provider answered without falling back to live")
  assertEqual(H.counts.sent, 1)

  -- The stop: guarded -> seam off -> cleanup.
  assertTrue(NS.Sim:RunVerb("stop"))
  assertEqual(table.concat(NS.order, ","), "guarded,onStop,listener")
  assertTrue(NS.guardedActive, "OnStopGuarded runs while the seam still answers")
  assertEqual(NS.guardedSend, "sim bye", "and a guarded member is still guarded there")
  assertEqual(NS.live.ChatSender, 0, "never live, inside the stop included")
  assertFalse(NS.onStopActive, "OnStop runs with the seam off")
  assertEqual(NS.onStopReason, "stop")
  assertEqual(NS.cleanupAnswer, 1, "DeliverForCleanup is legal in OnStop")
  assertEqual(H.counts.cleanup, 1)
  assertEqual(NS.printed[#NS.printed], "Simulation stopped.", "the stop line is printed last")

  -- Timers dead, SavedVariables untouched, no global written.
  assertEqual(#NS.m.__timers(), 0, "no live timer outlives the session")
  assertEqual(NS.m.__fireTimers(), 0)
  assertEqual(dump(NS.m[SV_NAME]), svBefore, "the SavedVariables-shaped global is byte-identical")
  for k in pairs(globalKeys(NS.m)) do
    assertTrue(globalsBefore[k], "nothing wrote a new global: " .. k)
  end

  -- Idle again: the seam calls live.
  assertEqual(NS.Compat.ChatSender("after"), "sent after")
  assertEqual(NS.live.ChatSender, 1)
end)

test("sim host: the host's fields are on its own table, and the instance gained none (C.4)", function()
  local NS = miniHost()
  started(NS)
  NS.Sim:RunVerb("run")
  drain(NS.m)
  local H = NS.SimHost
  assertTrue(H.world ~= nil and H.counts.sent == 1 and #H.log == 3, "the host's table carries the run")
  assertEqual(sortedKeys(NS.Sim), table.concat(PUBLISHED, ","),
    "the instance's key set is the published surface after a run")
  NS.Sim:Stop()
  assertEqual(sortedKeys(NS.Sim), table.concat(PUBLISHED, ","), "and after its stop")
  for _, field in ipairs({ "world", "counts", "log", "testMode", "stoodDown", "SimHost" }) do
    assertNil(rawget(NS.Sim, field), "no host field on the instance: " .. field)
  end
end)

-- -- stand-down mid-run ------------------------------------------------------------------------------

test("sim host: a stand-down mid-run stops first, suppresses cleanup delivery and hides the panel", function()
  local NS = miniHost()
  local H = NS.SimHost
  started(NS)
  F.recording(NS.m, function() assertTrue(NS.Sim:ShowPanel()) end)
  assertTrue(NS.Sim:RunVerb("run"))
  assertEqual(#H.log, 1, "the first step played at once; the rest are pending")

  NS.StandDown()
  assertFalse(NS.Sim:IsActive())
  assertEqual(table.concat(NS.order, ","), "guarded,onStop,listener")
  assertEqual(NS.onStopReason, "standDown")
  assertEqual(NS.cleanupAnswer, 0, "DeliverForCleanup is suppressed by the stand-down")
  assertEqual(H.counts.cleanup, 0)
  assertFalse(NS.Sim:IsPanelShown(), "a stand-down stop hides the panel")
  assertEqual(NS.printed[#NS.printed], "Simulation stopped: MiniHost is disabled.", "the host's stopText")

  drain(NS.m)
  assertEqual(#H.log, 1, "the pending tick died with the session")
  assertEqual(NS.live.ChatSender, 0)

  local ok, line = NS.Sim:Start({ scenario = "loot" })
  assertFalse(ok); assertEqual(line, "A simulation cannot start while the addon is disabled.")
  assertFalse(NS.Sim:ShowPanel(), "the panel refuses to show while stood down")
end)

test("sim host: a latch set without a stop is caught by Fire's self-stop backstop", function()
  local NS = miniHost()
  local H = NS.SimHost
  started(NS)
  assertTrue(NS.Sim:Step(), "the loot step")
  H.stoodDown = true                       -- the latch, with no Stop call (a host that forgot H6)
  assertEqual(NS.Sim:Fire("LOOT_READY", 9), 0, "Fire answers 0 and stops the session")
  assertFalse(NS.Sim:IsActive())
  assertEqual(NS.onStopReason, "standDown")
  assertEqual(NS.cleanupAnswer, 0)
  assertEqual(table.concat(H.log, "|"), "loot:3", "the stood-down event was never delivered")
end)
