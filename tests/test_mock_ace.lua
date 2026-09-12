-- tests/test_mock_ace.lua — kit revision 17: the Ace fakes a consumer harness can build ON.
--
-- Six consumer harnesses replaced the kit's Ace fakes wholesale, so no kit revision reached their
-- suites (BankLedger#18/#19, ConsumableMaster#38, KickCD#21, PanelMaster#50, WhatGroup#19). The
-- owner's call was that they migrate onto the kit rather than keep their copies, which only works if
-- the kit models what those copies were written to model. Everything below is that surface, each
-- piece checked against the real Ace3 source rather than against any one consumer's fake:
--
--   AceAddon-3.0   NewAddon honoring its mixin list, GetAddon, NewModule and the whole module
--                  lifecycle, driven the way the client drives it: ADDON_LOADED and PLAYER_LOGIN
--                  on AceAddon's own frame.
--   AceEvent-3.0   the message half on CallbackHandler's terms: string methods, the optional arg,
--                  UnregisterAllMessages, and a registration made mid-dispatch waiting for the
--                  dispatch to end. Plus a way to fire a game event, and the client refusing an
--                  event name it does not know.
--   AceTimer-3.0   a real timer surface on the kit's one queue: cancellation is honored, a repeating
--                  timer repeats, and __fireTimers counts what actually ran.
--   AceConsole-3.0 RegisterChatCommand recorded and dispatchable.
--   AceGUI-3.0     the layout registry and the real name of the version table.
--
-- Every case builds a FRESH environment, for the reason tests/test_mock_base.lua gives: these
-- recorders accumulate, and a count read off a shared instance depends on which suite ran first.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil, assertError =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil, T.assertError
local buildMocks = dofile("tests/wow_mock.lua")

--- A fresh environment and its AceAddon fake.
local function fresh()
  local M = buildMocks()
  return M, M.LibStub("AceAddon-3.0")
end

--- Drive the client's own lifecycle event through AceAddon's frame, as the client does.
local function fire(AceAddon, event, arg1)
  AceAddon.frame:__fire("OnEvent", event, arg1)
end

--- Does `s` contain `needle`, plainly?
local function has(s, needle) return tostring(s):find(needle, 1, true) ~= nil end

-- ── AceAddon: NewAddon honors its mixin list ───────────────────────────────────────────────────

test("ace: NewAddon with a name embeds exactly the libraries it lists", function()
  -- AceAddon:EmbedLibraries embeds the named libraries and nothing else. A fake that stamped every
  -- mixin on every addon let an addon that forgot to list AceTimer-3.0 call ScheduleTimer headlessly
  -- and then hit a nil field in the client (fidelity rule 1).
  local _, AceAddon = fresh()
  local ev = AceAddon:NewAddon({}, "EventsOnly", "AceEvent-3.0")
  assertTrue(type(ev.RegisterEvent) == "function", "AceEvent's event half")
  assertTrue(type(ev.RegisterMessage) == "function" and type(ev.UnregisterAllMessages) == "function",
    "and its message half")
  assertNil(ev.Print, "no AceConsole mixin it did not ask for")
  assertNil(ev.ScheduleTimer, "no AceTimer mixin it did not ask for")

  local ct = AceAddon:NewAddon({}, "ConsoleAndTimer", "AceConsole-3.0", "AceTimer-3.0")
  for _, name in ipairs({ "Print", "Printf", "RegisterChatCommand", "UnregisterChatCommand",
                          "ScheduleTimer", "ScheduleRepeatingTimer", "CancelTimer",
                          "CancelAllTimers", "TimeLeft" }) do
    assertTrue(type(ct[name]) == "function", "it carries " .. name)
  end
  assertNil(ct.RegisterEvent, "and no AceEvent mixin")
end)

test("ace: NewAddon refuses what AceAddon refuses", function()
  local _, AceAddon = fresh()
  AceAddon:NewAddon({}, "Taken")
  assertTrue(has(assertError(function() AceAddon:NewAddon({}, "Taken") end), "already exists"),
    "a second addon under one name raised")
  assertTrue(has(assertError(function() AceAddon:NewAddon({}, 42) end), "string expected"),
    "a name that is not a string raised")
  assertTrue(has(assertError(function() AceAddon:NewAddon({}, "Lost", "NoSuchLib-1.0") end),
    "NoSuchLib-1.0"), "a library LibStub cannot find raised, naming it")
end)

test("ace: NewAddon(name) builds the object itself, named and printable as its name", function()
  local _, AceAddon = fresh()
  local a = AceAddon:NewAddon("Solo", "AceConsole-3.0")
  assertEqual(a.name, "Solo", "the name is recorded")
  assertEqual(tostring(a), "Solo", "and tostring answers it, as AceAddon's __tostring does")
  assertEqual(a:GetName(), "Solo")
  assertTrue(a:IsEnabled() == true and a:IsModule() == false, "enabled by default, and not a module")
  assertTrue(AceAddon:GetAddon("Solo") == a, "GetAddon finds it")
  assertNil(AceAddon:GetAddon("Nobody", true), "a silent lookup of a missing addon answers nil")
  assertTrue(has(assertError(function() AceAddon:GetAddon("Nobody") end), "Nobody"),
    "and a loud one raises, naming it")
end)

test("ace: a table with no name keeps revision 16's NewAddon, stamps and all", function()
  -- The one deliberate divergence. Real AceAddon raises on a missing name; two consumer harnesses
  -- still call the kit's NewAddon as NewAddon(target), and revision 17 does not break them.
  local _, AceAddon = fresh()
  local t = AceAddon:NewAddon({})
  for _, name in ipairs({ "RegisterEvent", "UnregisterEvent", "UnregisterAllEvents", "Print",
                          "Printf", "RegisterChatCommand", "ScheduleTimer", "CancelTimer" }) do
    assertTrue(type(t[name]) == "function", "the legacy target still carries " .. name)
  end
  assertNil(t.NewModule, "and none of the named path's module surface")
end)

-- ── AceAddon: modules ──────────────────────────────────────────────────────────────────────────

test("ace: NewModule makes a named child addon, in creation order", function()
  local _, AceAddon = fresh()
  local host = AceAddon:NewAddon({}, "Host")
  local a = host:NewModule("Alpha", "AceEvent-3.0")
  local b = host:NewModule("Beta")
  assertEqual(a.moduleName, "Alpha")
  assertEqual(a:GetName(), "Alpha", "GetName answers the module name, not the prefixed one")
  assertEqual(a.name, "Host_Alpha", "registered with AceAddon under the prefixed name")
  assertTrue(AceAddon:GetAddon("Host_Alpha") == a, "and reachable through it")
  assertTrue(a:IsModule(), "IsModule")
  assertTrue(type(a.RegisterMessage) == "function", "the module embedded what it listed")
  assertNil(b.RegisterMessage, "and a sibling did not")
  assertTrue(host:GetModule("Beta") == b, "GetModule")
  assertTrue(host.orderedModules[1] == a and host.orderedModules[2] == b, "orderedModules keeps order")
  assertNil(host:GetModule("Gamma", true), "a silent miss answers nil")
  assertError(function() host:GetModule("Gamma") end, "a loud miss raised")
  assertError(function() host:NewModule("Alpha") end, "a duplicate module name raised")
end)

test("ace: a module takes its prototype, default libraries and default state", function()
  local _, AceAddon = fresh()
  local host = AceAddon:NewAddon({}, "Host")
  local created = {}
  function host:OnModuleCreated(m) created[#created + 1] = m end
  host:SetDefaultModuleLibraries("AceTimer-3.0")
  host:SetDefaultModuleState(false)
  local proto = { Greet = function() return "hi" end }
  local m = host:NewModule("Proto", proto, "AceEvent-3.0")
  assertEqual(m:Greet(), "hi", "a table prototype is the module's __index")
  assertTrue(type(m.ScheduleTimer) == "function", "the default libraries were embedded")
  assertTrue(type(m.RegisterEvent) == "function", "and the listed ones")
  assertEqual(m.enabledState, false, "the default module state applies")
  assertTrue(created[1] == m, "OnModuleCreated heard it")
  assertError(function() host:SetDefaultModuleState(true) end,
    "module defaults cannot change once a module exists")
end)

-- ── AceAddon: the lifecycle, driven through AceAddon's frame ───────────────────────────────────

--- An addon with two modules, each logging its lifecycle callbacks into one shared list.
local function lifecycleHost(AceAddon, log)
  local host = AceAddon:NewAddon({}, "Life")
  local function hooks(obj, tag)
    function obj.OnInitialize() log[#log + 1] = tag .. ":init" end
    function obj.OnEnable() log[#log + 1] = tag .. ":enable" end
    function obj.OnDisable() log[#log + 1] = tag .. ":disable" end
  end
  hooks(host, "host")
  hooks(host:NewModule("A"), "A")
  hooks(host:NewModule("B"), "B")
  return host
end

test("ace: PLAYER_LOGIN initializes everything queued, then enables the addon before its modules",
function()
  -- AceAddon's order: every queued object is initialized (the addon first, its modules after, in
  -- creation order), then each is enabled, and EnableAddon on the host walks orderedModules AFTER
  -- the host's own OnEnable. KickCD's and MultiMeters' hand-written __enableAll disagree about
  -- which comes first; the client is the tie-break.
  local _, AceAddon = fresh()
  local log = {}
  lifecycleHost(AceAddon, log)
  fire(AceAddon, "PLAYER_LOGIN")
  assertEqual(table.concat(log, " "),
    "host:init A:init B:init host:enable A:enable B:enable")
  fire(AceAddon, "PLAYER_LOGIN")
  assertEqual(#log, 6, "a second PLAYER_LOGIN finds both queues empty")
end)

test("ace: ADDON_LOADED initializes; enabling waits for the login", function()
  local _, AceAddon = fresh()
  local log = {}
  local host = lifecycleHost(AceAddon, log)
  fire(AceAddon, "ADDON_LOADED", "Life")
  assertEqual(table.concat(log, " "), "host:init A:init B:init", "initialized, not yet enabled")
  assertEqual(host.baseName, "Life", "baseName is the ADDON_LOADED argument, as AceAddon records it")
  fire(AceAddon, "PLAYER_LOGIN")
  assertEqual(table.concat(log, " "), "host:init A:init B:init host:enable A:enable B:enable")
end)

test("ace: a module created disabled is skipped by the cascade and enabled on demand", function()
  local _, AceAddon = fresh()
  local log = {}
  local host = lifecycleHost(AceAddon, log)
  host:GetModule("B"):SetEnabledState(false)
  fire(AceAddon, "PLAYER_LOGIN")
  assertEqual(table.concat(log, " "), "host:init A:init B:init host:enable A:enable")
  host:EnableModule("B")
  assertEqual(log[#log], "B:enable", "EnableModule enables it")
  assertTrue(host:GetModule("B"):IsEnabled(), "and records the state")
end)

test("ace: Disable runs OnDisable, then disables every module, and Enable brings them back", function()
  local _, AceAddon = fresh()
  local log = {}
  local host = lifecycleHost(AceAddon, log)
  fire(AceAddon, "PLAYER_LOGIN")
  for i = #log, 1, -1 do log[i] = nil end
  assertTrue(host:Disable(), "Disable answers true once it has disabled")
  assertEqual(table.concat(log, " "), "host:disable A:disable B:disable")
  assertFalse(host:IsEnabled(), "and the state is recorded")
  assertFalse(host:Disable(), "a second Disable has nothing to do")
  for i = #log, 1, -1 do log[i] = nil end
  host:Enable()
  assertEqual(table.concat(log, " "), "host:enable A:enable B:enable")
end)

test("ace: Enable on an addon still queued for initialization only records the state", function()
  -- nevcairiel 2013-04-27, in AceAddon's own Enable: an object waiting for ADDON_LOADED is enabled
  -- by the init pass, not by an early Enable.
  local _, AceAddon = fresh()
  local log = {}
  local host = lifecycleHost(AceAddon, log)
  host:Enable()
  assertEqual(#log, 0, "nothing ran")
  fire(AceAddon, "PLAYER_LOGIN")
  assertEqual(log[4], "host:enable", "the login pass enabled it")
end)

test("ace: disabling an addon unregisters its events and messages and cancels its timers", function()
  -- AceAddon's DisableAddon calls OnEmbedDisable on every library the addon embedded, and AceEvent
  -- and AceTimer each tear down what they hold for it there.
  local M, AceAddon = fresh()
  local host = AceAddon:NewAddon({}, "Embeds", "AceEvent-3.0", "AceTimer-3.0")
  fire(AceAddon, "PLAYER_LOGIN")
  local heard = 0
  host:RegisterEvent("PLAYER_LOGOUT", function() end)
  host:RegisterMessage("EMBEDS_CHANGED", function() heard = heard + 1 end)
  local timer = host:ScheduleTimer(function() heard = heard + 100 end, 5)
  host:Disable()
  assertNil(next(host.__events), "the events went")
  host:SendMessage("EMBEDS_CHANGED")
  assertEqual(heard, 0, "the message registration went")
  assertTrue(timer.cancelled, "the timer was canceled")
  assertEqual(M.__fireTimers(), 0, "and a canceled timer does not run")
end)

test("ace: an OnEnable that raises costs only itself, and the cascade reports it afterwards", function()
  -- The client hands the error to geterrorhandler() and carries on with the next module. The kit
  -- carries on too, then raises the first error once the outermost call returns: a headless error
  -- handler that swallowed it would be a stub that silently succeeds.
  local _, AceAddon = fresh()
  local log = {}
  local host = lifecycleHost(AceAddon, log)
  host:GetModule("A").OnEnable = function() error("A exploded") end
  local err = assertError(function() fire(AceAddon, "PLAYER_LOGIN") end, "the login pass raised")
  assertTrue(has(err, "A exploded"), "with the module's own message")
  assertEqual(log[#log], "B:enable", "and the sibling after it was still enabled")
end)

-- ── AceEvent: the message half on CallbackHandler's terms ──────────────────────────────────────

test("ace: RegisterMessage dispatches a string method, a default method and the optional arg", function()
  local AceEvent = buildMocks().LibStub("AceEvent-3.0")
  local seen = {}
  local t = AceEvent:Embed({})
  function t:OnThing(...) seen[#seen + 1] = { self, ... } end
  function t:THING_NAMED(...) seen[#seen + 1] = { self, ... } end
  t:RegisterMessage("THING", "OnThing")
  t:RegisterMessage("THING_NAMED")
  local u = AceEvent:Embed({})
  u:RegisterMessage("THING", function(...) seen[#seen + 1] = { "fn", ... } end, "ARG")
  t:SendMessage("THING", 1)
  t:SendMessage("THING_NAMED", 2)
  assertEqual(#seen, 3, "three deliveries")
  local byTag = {}
  for _, s in ipairs(seen) do byTag[s[1] == t and (s[2] == "THING" and "m" or "n") or "fn"] = s end
  assertTrue(byTag.m[2] == "THING" and byTag.m[3] == 1, "a method gets (self, message, ...)")
  assertTrue(byTag.n[2] == "THING_NAMED" and byTag.n[3] == 2,
    "no method means the method named after the message")
  assertTrue(byTag.fn[2] == "ARG" and byTag.fn[3] == "THING" and byTag.fn[4] == 1,
    "a function with an arg gets (arg, message, ...)")
end)

test("ace: RegisterMessage refuses what CallbackHandler refuses", function()
  local t = buildMocks().LibStub("AceEvent-3.0"):Embed({ OnThing = function() end })
  assertFalse(pcall(t.RegisterMessage, t, 42, "OnThing"), "a message that is not a string raised")
  assertFalse(pcall(t.RegisterMessage, t, "THING"), "no method named after the message raised")
  assertFalse(pcall(t.RegisterMessage, t, "THING", "OnTypo"), "a missing method raised")
  assertFalse(pcall(t.RegisterMessage, t, "THING", 7), "a handler that is neither raised")
  assertFalse(pcall(t.UnregisterMessage, t, 42), "UnregisterMessage of a non-string raised")
end)

test("ace: UnregisterAllMessages drops this target's messages and nobody else's", function()
  local M = buildMocks()
  local AceEvent = M.LibStub("AceEvent-3.0")
  local a = AceEvent:Embed({ PLAYER_LOGIN = function() end })
  local b = AceEvent:Embed({})
  local heardA, heardB = 0, 0
  a:RegisterMessage("ONE", function() heardA = heardA + 1 end)
  a:RegisterMessage("TWO", function() heardA = heardA + 1 end)
  b:RegisterMessage("ONE", function() heardB = heardB + 1 end)
  a:RegisterEvent("PLAYER_LOGIN")
  a:UnregisterAllMessages()
  b:SendMessage("ONE"); b:SendMessage("TWO")
  assertEqual(heardA, 0, "the target's own registrations are gone")
  assertEqual(heardB, 1, "another target's registration for the same message survives")
  assertEqual(a.__events.PLAYER_LOGIN, true, "and its events are untouched")
  assertNil(M.__msgRegistry.ONE[a], "the published registry agrees")
end)

test("ace: the library's own SendMessage fans out, and the registry holds a function as given", function()
  local M = buildMocks()
  local AceEvent = M.LibStub("AceEvent-3.0")
  local t = AceEvent:Embed({})
  local got
  local fn = function(msg, v) got = { msg, v } end
  t:RegisterMessage("PING", fn)
  assertTrue(M.__msgRegistry.PING[t] == fn, "a function with no arg is stored as itself")
  AceEvent:SendMessage("PING", 9)
  assertTrue(got and got[1] == "PING" and got[2] == 9, "AceEvent:SendMessage delivered it")
end)

test("ace: a registration made while a message is being sent waits for the send to finish", function()
  -- CallbackHandler queues a NEW registration made mid-dispatch and applies it once the outermost
  -- Fire returns, so the newcomer never hears the message that was already in flight.
  local AceEvent = buildMocks().LibStub("AceEvent-3.0")
  local late = AceEvent:Embed({})
  local lateHeard = 0
  local early = AceEvent:Embed({})
  early:RegisterMessage("WAVE", function()
    late:RegisterMessage("WAVE", function() lateHeard = lateHeard + 1 end)
  end)
  early:SendMessage("WAVE")
  assertEqual(lateHeard, 0, "the newcomer did not hear the wave in flight")
  early:SendMessage("WAVE")
  assertEqual(lateHeard, 1, "and hears the next one")
end)

-- ── AceEvent: firing game events, and the events the client does not know ──────────────────────

test("ace: __fireEvent dispatches a game event the way CallbackHandler does", function()
  local M = buildMocks()
  local AceEvent = M.LibStub("AceEvent-3.0")
  local calls = {}
  local t = AceEvent:Embed({})
  function t:PLAYER_LOGIN(...) calls[#calls + 1] = { "named", self, ... } end
  function t:OnCombat(...) calls[#calls + 1] = { "method", self, ... } end
  t:RegisterEvent("PLAYER_LOGIN")
  t:RegisterEvent("PLAYER_REGEN_DISABLED", "OnCombat")
  t:RegisterEvent("PLAYER_REGEN_ENABLED", "OnCombat")
  local u = AceEvent:Embed({})
  u:RegisterEvent("PLAYER_LOGIN", function(...) calls[#calls + 1] = { "fn", ... } end)

  assertEqual(M.__fireEvent("PLAYER_REGEN_ENABLED", "x"), 1, "one handler ran")
  assertTrue(calls[1][1] == "method" and calls[1][2] == t and calls[1][3] == "PLAYER_REGEN_ENABLED"
    and calls[1][4] == "x", "a shared method hears WHICH event fired, as (self, event, ...)")
  assertEqual(M.__fireEvent("PLAYER_LOGIN"), 2, "both registrants of one event ran")
  assertEqual(M.__fireEvent("NOBODY_LISTENS"), 0, "an event nobody registered runs nothing")
  t:UnregisterEvent("PLAYER_LOGIN")
  assertEqual(M.__fireEvent("PLAYER_LOGIN"), 1, "an unregistered target no longer hears it")
end)

test("ace: an event the client does not know raises on its first registration", function()
  -- Modern retail's frame:RegisterEvent raises on an unknown name, and AceEvent calls it from
  -- CallbackHandler's OnUsed: after the callback is stored, and only for an event's FIRST
  -- registrant. Both halves are the client's; a harness that raised earlier or on every call would
  -- be kinder than the game.
  local M = buildMocks()
  M.__badEvents = { RETIRED_EVENT = true }
  local AceEvent = M.LibStub("AceEvent-3.0")
  local a = AceEvent:Embed({})
  local err = assertError(function() a:RegisterEvent("RETIRED_EVENT", function() end) end,
    "the first registration raised")
  assertTrue(has(err, "unknown event") and has(err, "RETIRED_EVENT"), "naming the event")
  assertTrue(a.__events.RETIRED_EVENT ~= nil, "the callback was stored before the frame refused it")
  local b = AceEvent:Embed({})
  b:RegisterEvent("RETIRED_EVENT", function() end)
  a:RegisterEvent("PLAYER_LOGOUT", function() end)
  assertEqual(b.__events.RETIRED_EVENT ~= nil and a.__events.PLAYER_LOGOUT ~= nil, true,
    "a later registrant of the same event, and any known event, register quietly")
end)

-- ── AceTimer, on the kit's one queue ───────────────────────────────────────────────────────────

--- A fresh environment and an object with AceTimer embedded.
local function timerHost()
  local M = buildMocks()
  M.__timers = {}
  return M, M.LibStub("AceTimer-3.0"):Embed({})
end

test("ace: ScheduleTimer queues a timer __fireTimers runs, with its arguments", function()
  local M, t = timerHost()
  local got = {}
  local handle = t:ScheduleTimer(function(...) got[#got + 1] = { ... } end, 2, "a", "b")
  function t:OnTick(...) got[#got + 1] = { self, ... } end
  t:ScheduleTimer("OnTick", 1, "c")
  assertEqual(#M.__timers, 2, "both are queued")
  assertEqual(handle.delay, 2, "the handle carries its delay")
  assertEqual(M.__fireTimers(), 2, "__fireTimers answers how many ran")
  assertTrue(got[1][1] == "a" and got[1][2] == "b", "a function gets its arguments")
  assertTrue(got[2][1] == t and got[2][2] == "c", "a method name is called on the object")
  assertEqual(#M.__timers, 0, "a one-shot does not come back")
end)

test("ace: ScheduleTimer refuses what AceTimer refuses", function()
  local _, t = timerHost()
  assertError(function() t:ScheduleTimer(nil, 1) end, "no callback raised")
  assertError(function() t:ScheduleTimer(function() end) end, "no delay raised")
  assertTrue(has(assertError(function() t:ScheduleTimer("Missing", 1) end), "Missing"),
    "a method the object does not carry raised, naming it")
end)

test("ace: CancelTimer is honored, answered, and not counted as a run", function()
  local M, t = timerHost()
  local ran = 0
  local keep = t:ScheduleTimer(function() ran = ran + 1 end, 1)
  local drop = t:ScheduleTimer(function() ran = ran + 10 end, 1)
  assertTrue(t:CancelTimer(drop), "the first cancel answers true")
  assertFalse(t:CancelTimer(drop), "a second answers false")
  assertTrue(drop.cancelled, "the handle says so, under AceTimer's own field name")
  assertEqual(M.__fireTimers(), 1, "only the live timer counted")
  assertEqual(ran, 1, "and only it ran")
  assertFalse(t:CancelTimer(keep), "a timer that has already fired cannot be canceled")
end)

test("ace: a repeating timer fires once per pass until it is canceled, even from inside itself", function()
  local M, t = timerHost()
  local runs, handle = 0, nil
  handle = t:ScheduleRepeatingTimer(function()
    runs = runs + 1
    if runs == 3 then t:CancelTimer(handle) end
  end, 1)
  M.__fireTimers(); M.__fireTimers()
  assertEqual(runs, 2, "one run per pass")
  assertEqual(#M.__timers, 1, "and it re-queued itself")
  M.__fireTimers()
  assertEqual(runs, 3, "the third pass ran it")
  assertEqual(#M.__timers, 0, "and its own cancel stopped it re-queuing")
  assertEqual(M.__fireTimers(), 0, "nothing left to run")
end)

test("ace: CancelAllTimers cancels this object's timers and nobody else's", function()
  local M, t = timerHost()
  local other = M.LibStub("AceTimer-3.0"):Embed({})
  local mine = t:ScheduleTimer(function() end, 1)
  local theirs = other:ScheduleTimer(function() end, 1)
  t:CancelAllTimers()
  assertTrue(mine.cancelled, "its own timer went")
  assertNil(theirs.cancelled, "the other object's did not")
end)

test("ace: TimeLeft reads the clock; a short delay is floored at AceTimer's 0.01", function()
  local M, t = timerHost()
  M.__now = 100
  local h = t:ScheduleTimer(function() end, 5)
  M.__now = 102
  assertEqual(t:TimeLeft(h), 3, "ends minus now")
  t:CancelTimer(h)
  assertEqual(t:TimeLeft(h), 0, "a canceled timer has none")
  assertEqual(t:ScheduleTimer(function() end, 0).delay, 0.01, "the C_Timer floor")
end)

test("ace: a C_Timer.NewTimer handle's Cancel is honored too", function()
  local M = buildMocks()
  M.__timers = {}
  local ran = 0
  local h = M.C_Timer.NewTimer(1, function() ran = ran + 1 end)
  assertFalse(h:IsCancelled(), "live until Cancel")
  h:Cancel()
  assertTrue(h:IsCancelled() and h.cancelled, "IsCancelled and the handle both record the cancel")
  assertEqual(M.__fireTimers(), 0, "the canceled timer did not run")
  assertEqual(ran, 0)
end)

-- ── AceConsole ─────────────────────────────────────────────────────────────────────────────────

test("ace: RegisterChatCommand records the command and dispatches it as the client would", function()
  local M = buildMocks()
  local AceConsole = M.LibStub("AceConsole-3.0")
  local t = AceConsole:Embed({})
  local got = {}
  function t:OnSlash(input) got[#got + 1] = { self, input } end
  assertTrue(t:RegisterChatCommand("kk", "OnSlash"), "RegisterChatCommand answers true")
  t:RegisterChatCommand("kf", function(input) got[#got + 1] = { "fn", input } end)
  assertEqual(AceConsole.commands.kk, "ACECONSOLE_KK", "commands maps the command to its list key")
  AceConsole:__slash("kk", "help me")
  AceConsole:__slash("kf", "x")
  assertTrue(got[1][1] == t and got[1][2] == "help me", "a method name gets (self, input)")
  assertTrue(got[2][1] == "fn" and got[2][2] == "x", "a function gets (input)")
  assertNil(M.SlashCmdList, "no SlashCmdList global is invented where the environment has none")
  t:UnregisterChatCommand("kk")
  assertNil(AceConsole.commands.kk, "UnregisterChatCommand forgets it")
  assertError(function() t:RegisterChatCommand(7, "OnSlash") end, "a command that is not a string raised")
end)

test("ace: where the environment models SlashCmdList, RegisterChatCommand writes the client's globals",
function()
  local M = buildMocks()
  M.SlashCmdList = {}
  local t = M.LibStub("AceConsole-3.0"):Embed({})
  local heard
  t:RegisterChatCommand("Kk", function(input) heard = input end)
  assertEqual(M.SLASH_ACECONSOLE_KK1, "/kk", "the slash alias, lower-cased")
  M.SlashCmdList.ACECONSOLE_KK("go")
  assertEqual(heard, "go", "SlashCmdList holds the handler")
end)

-- ── layering: a consumer wraps a fake and calls through with its own table ─────────────────────

test("ace: every Embed works when a consumer's wrapper calls it with its own table as self", function()
  -- The migration shape the six harnesses are moving to: replace libs["AceEvent-3.0"] with a table
  -- of your own whose Embed calls the kit's through, then layers on top. The receiver the kit's
  -- Embed sees is the WRAPPER, so a fake that read `self.embeds` raised on the first bus target
  -- (PanelMaster's harness, measured).
  local M = buildMocks()
  for _, major in ipairs({ "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0" }) do
    local kit = M.LibStub(major)
    local wrapper = { Embed = function(self, t) return kit.Embed(self, t) end }
    local t = wrapper:Embed({})
    assertTrue(t ~= nil and next(t) ~= nil, major .. "'s Embed stamped its mixins through a wrapper")
  end
  local AceConsole = M.LibStub("AceConsole-3.0")
  local t = AceConsole:Embed({})
  local heard
  t:RegisterChatCommand("wrapped", function(input) heard = input end)
  AceConsole.__slash({}, "wrapped", "ok")
  assertEqual(heard, "ok", "__slash reads the library, not its receiver")
end)

-- ── review fixes (2026-09-12) ──────────────────────────────────────────────────────────────────

test("ace: a repeating timer keeps its delay and its TimeLeft when the test never moves the clock", function()
  -- AceTimer compensates the next delay by how late this run was. Headlessly a pass runs with the
  -- clock wherever the test left it, usually BEFORE the timer's due time, and the compensation read
  -- that as the timer being early -- so the delay and TimeLeft grew by one period every pass.
  local M, t = timerHost()
  M.__now = 100
  local h = t:ScheduleRepeatingTimer(function() end, 1)
  for pass = 1, 4 do
    M.__fireTimers()
    assertEqual(M.__timers[1].delay, 1, "the re-queued delay on pass " .. pass)
    assertEqual(t:TimeLeft(h), 1, "TimeLeft on pass " .. pass)
  end
end)

test("ace: only a lone table argument takes the no-name path; everything else is validated", function()
  local _, AceAddon = fresh()
  assertTrue(has(assertError(function() AceAddon:NewAddon({}, nil, "AceEvent-3.0") end), "string expected"),
    "a table, a nil name and a library list raised as AceAddon raises")
  assertTrue(has(assertError(function() AceAddon:NewAddon() end), "string expected"),
    "a bare NewAddon() raised")
end)

test("ace: the no-name path's CancelTimer is honored by __fireTimers", function()
  local M, AceAddon = fresh()
  M.__timers = {}
  local t = AceAddon:NewAddon({})
  local ran = 0
  local h = t:ScheduleTimer(function() ran = ran + 1 end, 1)
  t:CancelTimer(h)
  assertEqual(M.__fireTimers(), 0, "the canceled timer did not run")
  assertEqual(ran, 0)
end)

test("ace: a message handler that raises costs only itself, and the send reports it afterwards", function()
  -- The same shape as the lifecycle cascade: the dispatch carries on, then the first error is raised.
  -- TWO raising handlers and one healthy one, and every call counted: whatever order the registry
  -- visits them in, a dispatch that stopped at the first error runs at most two of the three, so
  -- the counts fail deterministically on a kit that let the error end the dispatch.
  local M = buildMocks()
  local AceEvent = M.LibStub("AceEvent-3.0")
  local raised, heard = 0, 0
  AceEvent:Embed({}):RegisterMessage("BOOM", function() raised = raised + 1; error("boom one") end)
  AceEvent:Embed({}):RegisterMessage("BOOM", function() raised = raised + 1; error("boom two") end)
  local t = AceEvent:Embed({})
  t:RegisterMessage("BOOM", function() heard = heard + 1 end)
  local err = assertError(function() t:SendMessage("BOOM") end, "the send raised")
  assertTrue(has(err, "boom"), "with a handler's own message")
  assertEqual(raised, 2, "both raising handlers ran: the first error did not end the dispatch")
  assertEqual(heard, 1, "and the healthy handler still heard it, wherever it sat in the order")
  t:SendMessage("QUIET")

  -- The same through the events registry, fired the way AceEvent's frame fires one.
  local evRaised, evHeard = 0, 0
  AceEvent:Embed({}):RegisterEvent("PLAYER_LOGOUT", function() evRaised = evRaised + 1; error("event one") end)
  AceEvent:Embed({}):RegisterEvent("PLAYER_LOGOUT", function() evRaised = evRaised + 1; error("event two") end)
  AceEvent:Embed({}):RegisterEvent("PLAYER_LOGOUT", function() evHeard = evHeard + 1 end)
  assertTrue(has(assertError(function() M.__fireEvent("PLAYER_LOGOUT") end, "the fire raised"), "event"),
    "with a handler's own message")
  assertTrue(evRaised == 2 and evHeard == 1, "every event handler ran, raising or not")
end)

test("ace: ADDON_LOADED after the login enables a load-on-demand addon, reading IsLoggedIn at call time", function()
  local M, AceAddon = fresh()
  local log = {}
  local lod = AceAddon:NewAddon({}, "OnDemand")
  function lod.OnEnable() log[#log + 1] = "enable" end
  M.IsLoggedIn = function() return true end
  fire(AceAddon, "ADDON_LOADED", "OnDemand")
  assertEqual(log[1], "enable", "the client is logged in, so the load pass enabled it")
end)

test("ace: the AceEvent library carries the message registration API, as CallbackHandler publishes it", function()
  local AceEvent = buildMocks().LibStub("AceEvent-3.0")
  local got = 0
  AceEvent.RegisterMessage("SomeAddon", "PING", function() got = got + 1 end)
  AceEvent:SendMessage("PING")
  assertEqual(got, 1, "an addonId string may register a function")
  AceEvent.UnregisterMessage("SomeAddon", "PING")
  AceEvent:SendMessage("PING")
  assertEqual(got, 1, "and unregister it")
  assertTrue(has(assertError(function() AceEvent:RegisterMessage("PING", "Method") end), "use your own 'self'"),
    "a method name registered on the library itself raised")

  local a, b = AceEvent:Embed({}), AceEvent:Embed({})
  local heard = 0
  a:RegisterMessage("M", function() heard = heard + 1 end)
  b:RegisterMessage("M", function() heard = heard + 10 end)
  AceEvent.UnregisterAllMessages(a, b)
  AceEvent:SendMessage("M")
  assertEqual(heard, 0, "UnregisterAllMessages takes several targets at once")
  assertError(function() AceEvent:UnregisterAllMessages() end, "the library alone is not a meaningful target")
  assertError(function() AceEvent.UnregisterAllMessages() end, "and nothing at all raised too")
end)

-- ── AceGUI ─────────────────────────────────────────────────────────────────────────────────────

test("ace: AceGUI's layout registry and version table carry their real names", function()
  local AceGUI = buildMocks().LibStub("AceGUI-3.0")
  local flow = function() end
  AceGUI:RegisterLayout("MyFlow", flow)
  assertTrue(AceGUI:GetLayout("myflow") == flow, "names are case-folded, as AceGUI folds them")
  assertTrue(AceGUI.LayoutRegistry.MYFLOW == flow, "LayoutRegistry holds it")
  assertError(function() AceGUI:RegisterLayout("Bad", 5) end, "a layout that is not a function raised")
  AceGUI:RegisterWidgetType("MyWidget", function() end, 7)
  assertEqual(AceGUI.WidgetVersions.MyWidget, 7, "WidgetVersions is the real table name")
  assertTrue(AceGUI.WidgetVersions == AceGUI.__widgetVersions, "the same table the kit always kept")
end)

-- ── AceDB ──────────────────────────────────────────────────────────────────────────────────────

test("ace: AceDB's OnProfileCopied carries the SOURCE profile's key, as AceDB-3.0 fires it", function()
  -- Revision 18. AceDB-3.0's CopyProfile ends `self.callbacks:Fire("OnProfileCopied", self, name)`
  -- with `name` the profile copied FROM. Through revision 17 the fake fired every event with the
  -- active profile, so a copy of "Raid" into "Default" reached a handler as a copy of "Default",
  -- and a handler that logged `copied profile '<source>' → '<active>'` could not be tested through
  -- CopyProfile at all. The other two events keep the key they had.
  local AceDB = buildMocks().LibStub("AceDB-3.0")
  local db = AceDB:New({ profiles = { Raid = { width = 7 } } }, { profile = { width = 1 } })
  local heard = {}
  local function listen(event)
    db.RegisterCallback({}, event, function(ev, from, key)
      heard[#heard + 1] = { event = ev, db = from, key = key }
    end)
  end
  listen("OnProfileCopied"); listen("OnProfileChanged"); listen("OnProfileReset")

  db:CopyProfile("Raid")
  assertEqual(#heard, 1, "one callback for one copy")
  assertEqual(heard[1].event, "OnProfileCopied")
  assertTrue(heard[1].db == db, "the database is the second argument")
  assertEqual(heard[1].key, "Raid", "the SOURCE, not the active 'Default'")
  assertEqual(db:GetCurrentProfile(), "Default", "the copy lands in the active profile")
  assertEqual(db.profile.width, 7, "with the source's values")

  db:SetProfile("Raid")
  assertEqual(heard[2].event, "OnProfileChanged")
  assertEqual(heard[2].key, "Raid", "a switch still carries the profile switched TO")

  db:ResetProfile()
  assertEqual(heard[3].event, "OnProfileReset")
  assertEqual(heard[3].key, "Raid", "and a reset the active profile, as it always has here")
end)
