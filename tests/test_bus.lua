-- tests/test_bus.lua — the stand-down record and the strict message catalog, one invariant per case.
--
-- Most cases here assert on the kit's LIVE registration set (`T.mocks.__registrations()`) and on
-- delivery through the kit's CallbackHandler, never on the bus's internals. That is the point of the
-- major: a stood-down addon that still holds a message registration looks exactly like one that
-- does not until something is sent, so the suite sends.
--
-- The fixtures live at the top of this file rather than in a `tests/fixture_bus.lua`, so the suite
-- is one file an integrator wires with one line.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertError, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertError, T.assertNil

local Loader = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local MAJOR = "LibKa0s-Bus-1.0"
local Bus = T.bus or T.mocks.LibStub(MAJOR, true)
local LC = T.lifecycle
local mocks = T.mocks

-- ── fixtures ───────────────────────────────────────────────────────────────────────────────

local F = {}

--- A fresh bus (overrides merged into the descriptor) and a recorder of handler calls, in order.
--- `rec.calls` is an array of strings; `rec.hit(label)` answers a handler that appends
--- `label` plus every argument it was called with.
function F.newBus(overrides)
  local d = { name = "TestHost" }
  for k, v in pairs(overrides or {}) do d[k] = v end
  local rec = { calls = {} }
  function rec.hit(label)
    return function(...)
      local parts = { label }
      for i = 1, select("#", ...) do parts[#parts + 1] = tostring((select(i, ...))) end
      rec.calls[#rec.calls + 1] = table.concat(parts, " ")
    end
  end
  function rec.joined() return table.concat(rec.calls, "|") end
  function rec.reset() rec.calls = {} end
  return Bus:New(d), rec
end

--- The live registrations held by the given targets, as a sorted array of `"<i>:<kind>:<name>"`,
--- where `i` is the target's position in the argument list. Filtered because the mock is shared
--- by the whole run and other suites' registrations are in it too.
function F.live(...)
  local index = {}
  for i = 1, select("#", ...) do index[(select(i, ...))] = i end
  local out = {}
  for _, reg in ipairs(mocks.__registrations()) do
    local i = index[reg.target]
    if i then out[#out + 1] = ("%d:%s:%s"):format(i, reg.kind, reg.event) end
  end
  table.sort(out)
  return table.concat(out, ",")
end

-- One UNTRACKED publisher for the whole suite: a raw AceEvent embed, so delivery is proven through
-- the kit's CallbackHandler rather than by calling a handler directly (architecture-§4).
local publisher = mocks.LibStub("AceEvent-3.0"):Embed({})

function F.send(message, ...) publisher:SendMessage(message, ...) end

--- Fire a game event at the live registration set. Answers how many handlers ran.
function F.fire(event, ...) return mocks.__fire(event, ...) end

--- Run `fn` with AceEvent-3.0 invisible to LibStub and everything else delegated, restoring the
--- registry even when `fn` raises. A non-silent lookup of the hidden library still raises, so a
--- case cannot pass because the module forgot its `, true`.
function F.withoutAceEvent(fn)
  local original = mocks.LibStub
  mocks.LibStub = setmetatable({
    GetLibrary = function(_, major, silent)
      if major == "AceEvent-3.0" then
        if not silent then error("Cannot find a library instance of " .. tostring(major)) end
        return nil
      end
      return original:GetLibrary(major, silent)
    end,
    NewLibrary = function(_, major, minor) return original:NewLibrary(major, minor) end,
  }, { __call = function(self, major, silent) return self:GetLibrary(major, silent) end })
  local ok, err = pcall(fn)
  mocks.LibStub = original
  if not ok then error(err, 0) end
end

--- Run `fn` with `set` as the fake client's unknown-event list, restoring the old list afterwards.
function F.withBadEvents(set, fn)
  local original = mocks.__badEvents
  mocks.__badEvents = set
  local ok, err = pcall(fn)
  mocks.__badEvents = original
  if not ok then error(err, 0) end
end

--- Take a target out of AceEvent-3.0's own `embeds` set. AceEvent holds every embedded table
--- strongly, in the client as in the kit, so a GC case that left it there would pass whatever the
--- bus did. Removing it isolates the one reference the case is about: the bus's own.
function F.releaseFromAce(t) mocks.LibStub("AceEvent-3.0").embeds[t] = nil end

--- A unique name per call, because the kit's registries are shared by the whole run and the
--- client raises on an unknown event only for its FIRST registrant.
local nameSeq = 0
function F.name(stem)
  nameSeq = nameSeq + 1
  return ("%s_%d"):format(stem, nameSeq)
end

--- The rows `Catalog` must refuse: `{ label, addonName, messages, needle }`. `needle` is text the
--- raised message must contain, which is how each row proves it hit its own check.
F.CATALOG_CASES = {
  { "addonName not a string", 42, { A = "Ka0s_X_Thing" }, "addonName" },
  { "addonName empty", "", { A = "Ka0s__Thing" }, "addonName" },
  { "messages empty", "X", {}, "non-empty table" },
  { "messages not a table", "X", "Ka0s_X_Thing", "non-empty table" },
  { "non-string key", "X", { "Ka0s_X_Thing" }, "key 1 is not a string" },
  { "lowercase key", "X", { changed = "Ka0s_X_Changed" }, "key changed is not SCREAMING_SNAKE" },
  { "key starting with a digit", "X", { ["1CHANGED"] = "Ka0s_X_Changed" }, "key 1CHANGED" },
  { "wrong prefix", "X", { CHANGED = "Kaos_X_Changed" }, "does not start with Ka0s_X_" },
  { "another addon's prefix", "AuraMaster", { CHANGED = "Ka0s_KickCD_Changed" },
    "does not start with Ka0s_AuraMaster_" },
  { "a prefix that only starts like the addon", "Aura", { CHANGED = "Ka0s_AuraMaster_Changed" },
    "key CHANGED" },
  { "non-string value", "X", { CHANGED = 7 }, "key CHANGED = 7" },
  { "SCREAMING_SNAKE event", "X", { METER_UPDATED = "Ka0s_X_METER_UPDATED" }, "not PascalCase" },
  { "camelCase event", "X", { CHANGED = "Ka0s_X_containersChanged" }, "not PascalCase" },
  { "all-caps event with no lowercase", "X", { CHANGED = "Ka0s_X_CHANGED" }, "not PascalCase" },
  { "empty event", "X", { CHANGED = "Ka0s_X_" }, "not PascalCase" },
  { "event with an underscore", "X", { CHANGED = "Ka0s_X_Containers_Changed" }, "not PascalCase" },
  { "duplicate value", "X", { A_ONE = "Ka0s_X_Changed", B_TWO = "Ka0s_X_Changed" },
    "keys A_ONE and B_TWO declare one wire name" },
}

--- A Lifecycle latch whose callbacks drive the bus, with the latch as the bus's `isDown`. The
--- shape every record-half host wires.
function F.latchedHost()
  local lc
  local bus, rec = F.newBus{ isDown = function() return lc:IsDown() end }
  lc = LC:New{
    name = "TestHost",
    standDown = function() bus:StandDown() end,
    standUp = function() bus:StandUp() end,
  }
  return lc, bus, rec
end

--- `fn` raises, and the raised text names `needle`.
local function assertRaises(fn, needle)
  local err = assertError(fn, "expected a raise naming '" .. needle .. "'")
  assertTrue(err:find(needle, 1, true) ~= nil, "raised: " .. err .. " (wanted '" .. needle .. "')")
end

local function count(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n
end

-- ── the major ──────────────────────────────────────────────────────────────────────────────

test("bus: the major is registered and reports its file minor", function()
  assertTrue(Bus ~= nil, MAJOR .. " registered")
  assertEqual(Bus.MAJOR, MAJOR)
  assertEqual(Bus.MODULES.Bus, Bus.MINOR, "the file reports its own live version")
end)

test("bus: the major is absent without Core, and with a Core below its floor", function()
  -- red under: drop the NEEDS_CORE return before NewLibrary
  local bare = buildMocks()
  Loader.load("LibKa0s/Bus.lua", nil, bare)
  assertNil(bare.LibStub(MAJOR, true), "no Core, no Bus")

  local old = buildMocks()
  Loader.loadSource(
    'local c = LibStub:NewLibrary("LibKa0s-Core-1.0", 1) c.MAJOR, c.MINOR = "LibKa0s-Core-1.0", 0',
    "core-below-floor", nil, old)
  Loader.load("LibKa0s/Bus.lua", nil, old)
  assertNil(old.LibStub(MAJOR, true), "a Core below the declared floor is refused")

  local good = buildMocks()
  Loader.load("LibKa0s/Core.lua", nil, good)
  Loader.load("LibKa0s/Bus.lua", nil, good)
  assertTrue(good.LibStub(MAJOR, true) ~= nil, "and with Core present it registers")
end)

test("bus: New refuses a descriptor without name, and a non-function isDown", function()
  -- red under: drop either guard in lib:New
  assertRaises(function() Bus:New(nil) end, "descriptor.name")
  assertRaises(function() Bus:New{ name = "" } end, "descriptor.name")
  assertRaises(function() Bus:New{ name = "X", isDown = true } end, "descriptor.isDown")
  local bus = Bus:New{ name = "X" }
  assertEqual(bus.name, "X", "the name is published as a diagnostic field")
end)

test("bus: the documented degradation stub matches the live surface", function()
  -- The stub docs/api/Bus/version-1-docs.md prints for a host's degraded arm. If the library grows a
  -- member, this is where the stub is found wanting before a host's copy is.
  local stub = {
    New = function(_, d)
      return {
        name = d and d.name,
        NewTarget = function() return nil end,
        StandDown = function() return 0 end,
        StandUp = function() return 0, {} end,
      }
    end,
    Catalog = function(_, messages) return messages end,
  }
  T.assertSurfaceParity(stub, MAJOR)
end)

-- ── targets ────────────────────────────────────────────────────────────────────────────────

test("bus: NewTarget answers a fresh target per call, and two receivers both hear one message", function()
  -- red under: return a cached target from NewTarget
  local bus, rec = F.newBus()
  local a, b = bus:NewTarget(), bus:NewTarget()
  assertTrue(a ~= nil and b ~= nil and a ~= b, "two calls, two targets")
  local msg = F.name("Ka0s_Test_Fresh")
  a:RegisterMessage(msg, rec.hit("a"))
  b:RegisterMessage(msg, rec.hit("b"))
  F.send(msg, 1)
  table.sort(rec.calls)
  assertEqual(rec.joined(), "a " .. msg .. " 1|b " .. msg .. " 1", "both receivers heard it")
  a:UnregisterAllMessages(); b:UnregisterAllMessages()
end)

test("bus: SendMessage on a tracked target is left raw, and reaches others while its own are down", function()
  -- red under: wrap SendMessage, or stand it down with the registrations
  local bus, rec = F.newBus()
  local t = bus:NewTarget()
  local msg = F.name("Ka0s_Test_Publish")
  t:RegisterMessage(msg, rec.hit("self"))
  local untracked = mocks.LibStub("AceEvent-3.0"):Embed({})
  untracked:RegisterMessage(msg, rec.hit("other"))
  assertEqual(t.SendMessage, publisher.SendMessage, "the raw AceEvent member, unwrapped")
  bus:StandDown()
  t:SendMessage(msg)
  assertEqual(rec.joined(), "other " .. msg, "the untracked receiver heard it; the stood-down one did not")
  untracked:UnregisterAllMessages()
end)

-- ── the record ─────────────────────────────────────────────────────────────────────────────

test("bus: the record follows every wrapper, and UnregisterAllEvents leaves messages alone", function()
  -- red under: make UnregisterAllEvents forget both kinds
  local bus = F.newBus()
  local t = bus:NewTarget()
  local e1, e2, m1, m2 = F.name("EV_A"), F.name("EV_B"), F.name("Ka0s_Test_A"), F.name("Ka0s_Test_B")
  t:RegisterEvent(e1, function() end)
  t:RegisterEvent(e2, function() end)
  t:RegisterMessage(m1, function() end)
  t:RegisterMessage(m2, function() end)
  t:UnregisterMessage(m2)
  t:UnregisterAllEvents()
  assertEqual(F.live(t), "1:message:" .. m1, "live before the round trip")
  assertEqual(bus:StandDown(), 1, "one entry recorded")
  local replayed, rejected = bus:StandUp()
  assertEqual(replayed, 1)
  assertEqual(#rejected, 0)
  assertEqual(F.live(t), "1:message:" .. m1, "and exactly that entry came back")
  t:UnregisterAllMessages()
end)

test("bus: StandDown takes events AND messages down and answers the entry count", function()
  -- red under: skip the raw UnregisterAllEvents in StandDown (the messages-only variants)
  local bus, rec = F.newBus()
  local a, b = bus:NewTarget(), bus:NewTarget()
  local ev, msg = F.name("EV_DOWN"), F.name("Ka0s_Test_Down")
  -- The method named for the event, so the falsification below can still reach it.
  a[ev] = function(_, event) rec.hit("a-event")(event) end
  a:RegisterEvent(ev)
  a:RegisterMessage(msg, rec.hit("a-msg"))
  b:RegisterMessage(msg, rec.hit("b-msg"))
  assertEqual(bus:StandDown(), 3)
  assertEqual(F.live(a, b), "", "nothing live on either target")
  assertEqual(F.fire(ev), 0, "the game event reaches no handler")
  F.send(msg)
  assertEqual(rec.joined(), "", "the message reaches nobody")
  -- Falsification: the handler is still there, the client simply cannot reach it.
  assertEqual(mocks.__fireUnconditional(a, ev), 1, "a survivor would have been caught")
  bus:StandUp()
  a:UnregisterAllEvents(); a:UnregisterAllMessages(); b:UnregisterAllMessages()
end)

test("bus: StandDown keeps the record and StandUp replays it", function()
  -- red under: clear the record in StandDown
  local bus, rec = F.newBus()
  local t = bus:NewTarget()
  local ev, msg = F.name("EV_REPLAY"), F.name("Ka0s_Test_Replay")
  t:RegisterEvent(ev, rec.hit("event"))
  t:RegisterMessage(msg, rec.hit("msg"))
  bus:StandDown()
  local replayed, rejected = bus:StandUp()
  assertEqual(replayed, 2, "both entries replayed")
  assertEqual(#rejected, 0)
  assertEqual(F.fire(ev, "x"), 1)
  F.send(msg, "y")
  assertEqual(rec.joined(), "event " .. ev .. " x|msg " .. msg .. " y")
  t:UnregisterAllEvents(); t:UnregisterAllMessages()
end)

test("bus: StandUp replays the record as it is NOW, not a snapshot taken at StandDown", function()
  -- red under: snapshot the record in StandDown and replay the snapshot
  local bus = F.newBus()
  local t = bus:NewTarget()
  local a, b = F.name("Ka0s_Test_NowA"), F.name("Ka0s_Test_NowB")
  t:RegisterMessage(a, function() end)
  bus:StandDown()
  t:UnregisterMessage(a)
  t:RegisterMessage(b, function() end)
  bus:StandUp()
  assertEqual(F.live(t), "1:message:" .. b, "only the registration wanted now is live")
  t:UnregisterAllMessages()
end)

test("bus: a registration made while down is recorded and NOT live until StandUp", function()
  -- red under: call the raw register in the down branch
  local bus, rec = F.newBus()
  local t = bus:NewTarget()
  bus:StandDown()
  local ev, msg = F.name("EV_LATE"), F.name("Ka0s_Test_Late")
  t:RegisterEvent(ev, rec.hit("event"))
  t:RegisterMessage(msg, rec.hit("msg"))
  assertEqual(F.live(t), "", "a stood-down addon registers nothing")
  F.send(msg)
  assertEqual(rec.joined(), "")
  local replayed = bus:StandUp()
  assertEqual(replayed, 2)
  assertEqual(F.live(t), "1:event:" .. ev .. ",1:message:" .. msg)
  t:UnregisterAllEvents(); t:UnregisterAllMessages()
end)

test("bus: StandDown and StandUp are idempotent", function()
  -- red under: drop the `down` check at the top of either member
  local bus, rec = F.newBus()
  local t = bus:NewTarget()
  local msg = F.name("Ka0s_Test_Idem")
  t:RegisterMessage(msg, rec.hit("m"))
  local replayed, rejected = bus:StandUp()
  assertEqual(replayed, 0, "StandUp while up replays nothing")
  assertEqual(#rejected, 0)
  assertEqual(bus:StandDown(), 1)
  assertEqual(bus:StandDown(), 0, "a second StandDown answers 0")
  assertEqual(F.live(t), "")
  assertEqual(bus:StandUp(), 1)
  assertEqual(bus:StandUp(), 0, "a second StandUp answers 0")
  F.send(msg)
  assertEqual(rec.joined(), "m " .. msg, "delivered once, not twice")
  t:UnregisterAllMessages()
end)

test("bus: re-registering a key replaces the entry in place and never duplicates it", function()
  -- red under: append a second entry on re-register (the order-list leak)
  local bus, rec = F.newBus()
  local t = bus:NewTarget()
  local msg = F.name("Ka0s_Test_Again")
  t:RegisterMessage(msg, rec.hit("f1"))
  t:RegisterMessage(msg, rec.hit("f2"))
  t:UnregisterMessage(msg)
  t:RegisterMessage(msg, rec.hit("f3"))
  t:RegisterMessage(msg, rec.hit("f4"))
  assertEqual(bus:StandDown(), 1, "one key, one entry")
  assertEqual(bus:StandUp(), 1, "and one replay")
  F.send(msg)
  assertEqual(rec.joined(), "f4 " .. msg, "only the last handler, once")
  t:UnregisterAllMessages()
end)

test("bus: every handler form survives the round trip with CallbackHandler's arguments", function()
  -- red under: drop the optional arg, or its count, from the record. (Recording `handler or false`
  -- is NOT a red: CallbackHandler reads a false method as "the method named for the event", exactly
  -- as it reads nil.)
  local bus, rec = F.newBus()
  local t = bus:NewTarget()
  local names = {}
  for i = 1, 6 do names[i] = F.name("Ka0s_Test_Form") end
  local evName = F.name("EV_FORM")
  -- A method named for the event, and a method named by string.
  t[names[2]] = function(self, ...) assertTrue(self == t); rec.hit("named")(...) end
  t.OnThing = function(self, ...) assertTrue(self == t); rec.hit("method")(...) end
  t[evName] = function(self, ...) assertTrue(self == t); rec.hit("evnamed")(...) end
  t:RegisterMessage(names[1], rec.hit("fn"))
  t:RegisterMessage(names[2])                              -- nil: the method named for the message
  t:RegisterMessage(names[3], "OnThing")
  t:RegisterMessage(names[4], rec.hit("fnarg"), "A")       -- arg form
  t:RegisterMessage(names[5], rec.hit("fnnil"), nil)       -- explicit nil arg: counted, passed
  t:RegisterMessage(names[6], "OnThing", "B")              -- method with an arg
  t:RegisterEvent(evName)                                  -- nil, on the event half
  bus:StandDown()
  local replayed, rejected = bus:StandUp()
  assertEqual(replayed, 7)
  assertEqual(#rejected, 0)
  for i = 1, 6 do F.send(names[i], "p") end
  F.fire(evName, "q")
  assertEqual(rec.joined(), table.concat({
    "fn " .. names[1] .. " p",
    "named " .. names[2] .. " p",
    "method " .. names[3] .. " p",
    "fnarg A " .. names[4] .. " p",
    "fnnil nil " .. names[5] .. " p",
    "method B " .. names[6] .. " p",
    "evnamed " .. evName .. " q",
  }, "|"))
  t:UnregisterAllEvents(); t:UnregisterAllMessages()
end)

test("bus: a raw register that raises while up reaches the caller and is not recorded", function()
  -- red under: record before the raw call
  local bus = F.newBus()
  local t = bus:NewTarget()
  local good, bad = F.name("EV_GOOD"), F.name("EV_BAD")
  t:RegisterEvent(good, function() end)
  F.withBadEvents({ [bad] = true }, function()
    assertRaises(function() t:RegisterEvent(bad, function() end) end, "unknown event")
    assertEqual(bus:StandDown(), 1, "only the good entry was recorded")
    local replayed, rejected = bus:StandUp()
    assertEqual(replayed, 1)
    assertEqual(#rejected, 0, "the bad event was never recorded, so it is never rejected")
  end)
  assertEqual(F.live(t), "1:event:" .. good)
  -- A non-string name is CallbackHandler's own usage error, in either state.
  assertRaises(function() t:RegisterMessage(nil, function() end) end, "string expected")
  bus:StandDown()
  assertRaises(function() t:RegisterMessage(42, function() end) end, "string expected")
  bus:StandUp()
  assertEqual(F.live(t), "1:event:" .. good, "and neither was recorded")
  t:UnregisterAllEvents()
end)

test("bus: one entry that raises on replay does not stop the others, and StandUp never raises", function()
  -- red under: drop the per-entry pcall in StandUp
  local bus, rec = F.newBus()
  local t = bus:NewTarget()
  local before, bad, after = F.name("EV_BEFORE"), F.name("EV_BAD"), F.name("Ka0s_Test_After")
  local missing = F.name("Ka0s_Test_Missing")
  bus:StandDown()
  t:RegisterEvent(before, rec.hit("before"))
  t:RegisterEvent(bad, function() end)                  -- recorded while down, never validated
  t:RegisterMessage(missing, "NoSuchMethod")            -- also invalid, rejected by CallbackHandler
  t:RegisterMessage(after, rec.hit("after"))
  F.withBadEvents({ [bad] = true }, function()
    local ok, replayed, rejected = pcall(bus.StandUp, bus)
    assertTrue(ok, "StandUp did not raise")
    assertEqual(replayed, 2, "the good entries on either side of the bad ones")
    assertEqual(table.concat(rejected, ","), "event:" .. bad .. ",message:" .. missing,
      "the rejected entries, sorted")
  end)
  assertEqual(F.live(t), "1:event:" .. before .. ",1:message:" .. after,
    "the bus is up, and a rejected entry leaves nothing behind in the registry")
  F.fire(before); F.send(after)
  assertEqual(rec.joined(), "before " .. before .. "|after " .. after)
  t:UnregisterAllEvents(); t:UnregisterAllMessages()
end)

test("bus: a rejected entry is dropped from the record", function()
  -- red under: keep a failing entry in the record after rejecting it
  local bus = F.newBus()
  local t = bus:NewTarget()
  local good, bad = F.name("EV_KEEP"), F.name("EV_DROP")
  bus:StandDown()
  t:RegisterEvent(good, function() end)
  t:RegisterEvent(bad, function() end)
  F.withBadEvents({ [bad] = true }, function()
    local _, first = bus:StandUp()
    assertEqual(#first, 1)
    assertEqual(bus:StandDown(), 1, "one entry left in the record")
    local replayed, second = bus:StandUp()
    assertEqual(replayed, 1)
    assertEqual(#second, 0, "a second round trip rejects nothing")
  end)
  t:UnregisterAllEvents()
end)

-- ── the seam with the latch ────────────────────────────────────────────────────────────────

test("bus: StandUp is refused while isDown answers true, and the bus stays down", function()
  -- red under: drop the isDown check in StandUp
  local latched = true
  local bus, rec = F.newBus{ isDown = function() return latched end }
  local t = bus:NewTarget()
  local msg = F.name("Ka0s_Test_Latched")
  t:RegisterMessage(msg, rec.hit("m"))
  bus:StandDown()
  local replayed, rejected = bus:StandUp()
  assertEqual(replayed, 0, "a bare stand-up under a held latch replays nothing")
  assertEqual(#rejected, 0)
  assertEqual(F.live(t), "")
  local msg2 = F.name("Ka0s_Test_StillDown")
  t:RegisterMessage(msg2, rec.hit("m2"))
  assertEqual(F.live(t), "", "still down: a new registration is deferred, not made live")
  latched = false
  assertEqual(bus:StandUp(), 2, "a permitted StandUp replays everything")
  F.send(msg); F.send(msg2)
  assertEqual(rec.joined(), "m " .. msg .. "|m2 " .. msg2)
  t:UnregisterAllMessages()
end)

test("bus: composed with Lifecycle, releasing one hold under another leaves the bus down", function()
  -- The seam end to end: the latch decides WHEN, the bus does WHAT. Hold(disabled); Hold(perf);
  -- Release(perf) must not resurrect the registrations of an addon the player switched off.
  local lc, bus, rec = F.latchedHost()
  local t = bus:NewTarget()
  local msg = F.name("Ka0s_Test_Seam")
  t:RegisterMessage(msg, rec.hit("m"))
  assertEqual(F.live(t), "1:message:" .. msg, "up")
  lc:Hold(LC.HOLD_DISABLED)
  assertEqual(F.live(t), "", "the first hold takes the bus down")
  lc:Hold(LC.HOLD_PERF)
  lc:Release(LC.HOLD_PERF)
  assertEqual(F.live(t), "", "releasing perf under disabled leaves it down")
  -- A host calling the bus bare, outside the latch, is refused too.
  assertEqual(bus:StandUp(), 0, "the latch is still held")
  assertEqual(F.live(t), "")
  lc:Release(LC.HOLD_DISABLED)
  assertEqual(F.live(t), "1:message:" .. msg, "the last release brings it up, from inside standUp")
  F.send(msg)
  assertEqual(rec.joined(), "m " .. msg)
  t:UnregisterAllMessages()
end)

-- ── retention ──────────────────────────────────────────────────────────────────────────────

test("bus: a target only CallbackHandler holds survives StandDown and a full GC", function()
  -- red under: make the held set weak-valued (`__mode = "kv"`). A weak-KEYED set alone stays green
  -- here, and that is Lua 5.1 rather than luck: with no ephemerons, a weak key whose value refers
  -- back to it (the record names its target) is never released. In the client AceEvent-3.0's
  -- `embeds` set holds the target anyway; F.releaseFromAce takes that holder out of the picture.
  local bus, rec = F.newBus()
  local msg = F.name("Ka0s_Test_Orphan")
  -- Built inside a call rather than a `do` block: Lua 5.1 can leave a dead block local in its stack
  -- slot, and the collector treats that slot as a live reference.
  local function build()
    local t = bus:NewTarget()
    t:RegisterMessage(msg, rec.hit("orphan"))
    F.releaseFromAce(t)
  end
  build()
  bus:StandDown()   -- CallbackHandler lets go here; the bus is now the only holder
  collectgarbage("collect"); collectgarbage("collect")
  assertEqual(bus:StandUp(), 1, "the orphaned target was still there to replay")
  F.send(msg)
  assertEqual(rec.joined(), "orphan " .. msg)
  -- Retire it the way an owner does, so the registry is left as the case found it.
  for _, reg in ipairs(mocks.__registrations()) do
    if reg.event == msg then reg.target:UnregisterAllMessages() end
  end
end)

test("bus: a target emptied by its owner leaves the bus, which then holds nothing of it", function()
  -- red under: never release a target from the held set
  local bus = F.newBus()
  local probe = setmetatable({}, { __mode = "k" })
  local function buildAndRetire()
    local t = bus:NewTarget()
    t:RegisterEvent(F.name("EV_RETIRE"), function() end)
    t:RegisterMessage(F.name("Ka0s_Test_Retire"), function() end)
    t:UnregisterAllEvents()
    t:UnregisterAllMessages()
    F.releaseFromAce(t)
    probe[t] = true
  end
  buildAndRetire()
  collectgarbage("collect"); collectgarbage("collect")
  assertEqual(count(probe), 0, "nothing in the bus kept the retired target alive")
  assertEqual(bus:StandDown(), 0, "and the record has nothing left to take down")
end)

test("bus: two buses share nothing", function()
  -- red under: move the held set or the down flag to module scope
  local a, recA = F.newBus()
  local b, recB = F.newBus()
  local ta, tb = a:NewTarget(), b:NewTarget()
  local msg = F.name("Ka0s_Test_Two")
  ta:RegisterMessage(msg, recA.hit("a"))
  tb:RegisterMessage(msg, recB.hit("b"))
  assertEqual(a:StandDown(), 1)
  assertEqual(F.live(ta, tb), "2:message:" .. msg, "b's target is still live")
  F.send(msg)
  assertEqual(recA.joined(), "")
  assertEqual(recB.joined(), "b " .. msg)
  assertEqual(b:StandUp(), 0, "b was never down")
  a:StandUp()
  ta:UnregisterAllMessages(); tb:UnregisterAllMessages()
end)

test("bus: the bus prints nothing across a full cycle", function()
  local before = #mocks.__printed()
  local lc, bus = F.latchedHost()
  local t = bus:NewTarget()
  t:RegisterMessage(F.name("Ka0s_Test_Quiet"), function() end)
  lc:Hold("disabled"); lc:Release("disabled")
  bus:StandDown(); bus:StandUp()
  assertEqual(#mocks.__printed(), before, "no line reached the player")
  t:UnregisterAllMessages()
end)

-- ── without AceEvent ───────────────────────────────────────────────────────────────────────

test("bus: without AceEvent-3.0, NewTarget answers nil and the rest answer zero", function()
  -- red under: resolve AceEvent at file load, or look it up without `, true`
  F.withoutAceEvent(function()
    local bus = Bus:New{ name = "NoAce" }
    assertNil(bus:NewTarget(), "no AceEvent, no target")
    assertEqual(bus:StandDown(), 0, "nothing was ever tracked")
    local replayed, rejected = bus:StandUp()
    assertEqual(replayed, 0)
    assertEqual(#rejected, 0)
    local MSG = Bus.Catalog("NoAce", { CHANGED = "Ka0s_NoAce_Changed" })
    assertEqual(MSG.CHANGED, "Ka0s_NoAce_Changed", "Catalog is pure and needs no Ace library")
  end)
  -- And the lookup is at call time: the same bus finds AceEvent once it is back.
  local bus = Bus:New{ name = "Later" }
  local t
  F.withoutAceEvent(function() assertNil(bus:NewTarget()) end)
  t = bus:NewTarget()
  assertTrue(t ~= nil, "resolved at call time, not cached as absent")
end)

-- ── the catalog ────────────────────────────────────────────────────────────────────────────

test("bus: Catalog accepts a conforming table and answers a fresh copy of it", function()
  -- red under: return the input table
  local input = {
    CONTAINERS_CHANGED = "Ka0s_AuraMaster_ContainersChanged",
    SPELL_STATE_2      = "Ka0s_AuraMaster_SpellState2",
  }
  local MSG = Bus.Catalog("AuraMaster", input)
  assertTrue(MSG ~= input, "a fresh table")
  assertEqual(MSG.CONTAINERS_CHANGED, "Ka0s_AuraMaster_ContainersChanged")
  assertEqual(MSG.SPELL_STATE_2, "Ka0s_AuraMaster_SpellState2")
  local seen = {}
  for k, v in pairs(MSG) do seen[#seen + 1] = k .. "=" .. v end
  table.sort(seen)
  assertEqual(table.concat(seen, ","),
    "CONTAINERS_CHANGED=Ka0s_AuraMaster_ContainersChanged,SPELL_STATE_2=Ka0s_AuraMaster_SpellState2",
    "pairs enumerates exactly the declared keys")
  assertNil(getmetatable(input), "the input is not made strict")
  assertEqual(count(input), 2, "and not mutated")
end)

test("bus: Catalog refuses each malformed declaration, naming what is wrong", function()
  -- red under: drop the matching check in lib.Catalog (each row names its own)
  for _, row in ipairs(F.CATALOG_CASES) do
    local label, addonName, messages, needle = row[1], row[2], row[3], row[4]
    local ok, err = pcall(Bus.Catalog, addonName, messages)
    assertFalse(ok, label .. ": expected a refusal")
    assertTrue(tostring(err):find(needle, 1, true) ~= nil,
      label .. ": raised '" .. tostring(err) .. "', wanted '" .. needle .. "'")
  end
  -- A colon call is the one mistake a dot-called member invites; it is named as such.
  assertRaises(function() Bus:Catalog({ A = "Ka0s_X_Thing" }) end, "dot-called")
end)

test("bus: the catalog is strict on read and on write", function()
  -- red under: drop the metatable Catalog sets on its answer
  local MSG = Bus.Catalog("PartyFrameEnhanced", { VISIBILITY = "Ka0s_PartyFrameEnhanced_VisibilityChanged" })
  assertEqual(MSG.VISIBILITY, "Ka0s_PartyFrameEnhanced_VisibilityChanged", "a declared key reads")
  assertRaises(function() return MSG.VISIBILTY end, "no bus message named VISIBILTY")
  assertRaises(function() MSG.NEW_ONE = "Ka0s_PartyFrameEnhanced_NewOne" end,
    "NEW_ONE is not declared")
  -- The publisher half the constant rule alone does not close: a mistyped key used to send would
  -- otherwise be SendMessage(nil), which CallbackHandler drops without a word.
  assertRaises(function() publisher:SendMessage(MSG.VISIBILITY_CHANGED) end,
    "no bus message named VISIBILITY_CHANGED")
end)
