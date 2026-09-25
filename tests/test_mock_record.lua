-- tests/test_mock_record.lua — the kit's recording surveys (revision 22).
--
-- Every case here is really one case asked five ways: CAN A SUITE SEE THE DIFFERENCE between an
-- addon that stopped watching and an addon that merely stopped reacting? The kit's answer is the
-- registration set, and the answer is only worth anything if entries come OUT of it on unregister.
-- A registry that only ever grows reports a perfectly torn-down addon as still watching everything,
-- and the suite written against it gets tuned until it passes — which is to say, until it no longer
-- asks the question. So the negative half of every survey is what is actually pinned below.
--
-- The surveys are asserted against a mock built fresh in each case rather than against the shared
-- `T.mocks`, because the shared one has a whole library's worth of frames and registrations in it
-- by the time this file runs, and a count is only legible over a build nobody else has touched.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse
local assertErrorMatches = T.assertErrorMatches

local buildMocks = dofile("tests/wow_mock.lua")

--- One registration rendered as a comparable string: `kind:event` or `kind:event@unit`.
local function render(reg)
  return reg.kind .. ":" .. reg.event .. (reg.unit and ("@" .. reg.unit) or "")
end

local function names(M)
  local out = {}
  for _, reg in ipairs(M.__registrations()) do out[#out + 1] = render(reg) end
  return table.concat(out, ",")
end

--- An AceEvent target, which is the shape a module's bus target takes in every addon here.
local function busTarget(M)
  local t = { PLAYER_LOGIN = function() end }
  M.__libs["AceEvent-3.0"]:Embed(t)
  return t
end

-- ── the registration set ───────────────────────────────────────────────────────────────────

test("record: a fresh build has registered nothing", function()
  local M = buildMocks()
  assertEqual(#M.__registrations(), 0, "or every later assertion passes trivially")
end)

test("record: a raw frame:RegisterEvent is recorded, by frame and by name", function()
  -- Through revision 21 this was answered by the frame stub's metatable and remembered nothing, so
  -- an addon whose events sit on a plain CreateFrame — which is most of them — had a registration
  -- set no suite could see.
  local M = buildMocks()
  local f = M.CreateFrame("Frame")
  f:RegisterEvent("PLAYER_REGEN_DISABLED")
  f:RegisterEvent("PLAYER_REGEN_ENABLED")
  assertEqual(names(M), "frame:PLAYER_REGEN_DISABLED,frame:PLAYER_REGEN_ENABLED")
  assertTrue(f:IsEventRegistered("PLAYER_REGEN_DISABLED"))
  assertFalse(f:IsEventRegistered("UNIT_AURA"), "and not every event, as the metatable answered")
end)

test("record: entries are REMOVED on unregister and on UnregisterAllEvents", function()
  -- red under: make UnregisterEvent and UnregisterAllEvents no-ops in the frame stub
  --
  -- The half that makes the whole survey falsifiable in the useful direction.
  local M = buildMocks()
  local f = M.CreateFrame("Frame")
  f:RegisterEvent("UNIT_AURA")
  f:RegisterUnitEvent("UNIT_HEALTH", "player", "target")
  assertEqual(names(M), "frame:UNIT_AURA,unit:UNIT_HEALTH@player,unit:UNIT_HEALTH@target")
  f:UnregisterEvent("UNIT_AURA")
  assertEqual(names(M), "unit:UNIT_HEALTH@player,unit:UNIT_HEALTH@target")
  f:UnregisterAllEvents()
  assertEqual(names(M), "", "nothing survives UnregisterAllEvents, raw or per-unit")
end)

test("record: a per-unit registration is one row PER UNIT TOKEN", function()
  -- The per-unit filter is what a stand-down widens by accident: an addon that rebuilds UNIT_AURA
  -- for every unit instead of the enabled ones has the same event count and a different set.
  local M = buildMocks()
  local f = M.CreateFrame("Frame")
  f:RegisterUnitEvent("UNIT_AURA", "player")
  assertEqual(names(M), "unit:UNIT_AURA@player")
  f:RegisterUnitEvent("UNIT_AURA", "player", "party1", "party2")
  assertEqual(names(M), "unit:UNIT_AURA@party1,unit:UNIT_AURA@party2,unit:UNIT_AURA@player",
    "three rows, and the widening is visible")
end)

test("record: AceEvent events and messages are recorded under their own kinds", function()
  local M = buildMocks()
  local t = busTarget(M)
  t:RegisterEvent("PLAYER_LOGIN")
  t:RegisterMessage("Ka0s_ConfigChanged", function() end)
  assertEqual(names(M), "event:PLAYER_LOGIN,message:Ka0s_ConfigChanged")
  t:UnregisterAllEvents()
  assertEqual(names(M), "message:Ka0s_ConfigChanged", "events go, messages stay — as in the client")
  t:UnregisterAllMessages()
  assertEqual(names(M), "")
end)

test("record: an embedded FRAME loses its raw and per-unit rows to UnregisterAllEvents too", function()
  -- Embedding replaces the frame's own UnregisterAllEvents, so without the kit clearing both
  -- tables an embedded frame's raw registrations would survive the one call whose whole meaning is
  -- that nothing is registered any more.
  local M = buildMocks()
  local f = M.CreateFrame("Frame")
  f.PLAYER_LOGIN = function() end
  f:RegisterUnitEvent("UNIT_AURA", "player")
  M.__libs["AceEvent-3.0"]:Embed(f)
  f:RegisterEvent("PLAYER_LOGIN")
  assertEqual(names(M), "event:PLAYER_LOGIN,unit:UNIT_AURA@player")
  f:UnregisterAllEvents()
  assertEqual(names(M), "")
end)

test("record: the survey comes back in the same order twice", function()
  local M = buildMocks()
  local f = M.CreateFrame("Frame")
  f:RegisterEvent("B_EVENT")
  f:RegisterEvent("A_EVENT")
  f:RegisterUnitEvent("C_EVENT", "target", "player")
  assertEqual(names(M), names(M), "a suite asserting on this is not asserting on the hash seed")
end)

-- ── buckets ────────────────────────────────────────────────────────────────────────────────

test("record: a bucket registration is a registration, and it is removable", function()
  -- red under: drop the AceBucket fake and let RegisterBucketEvent fall through
  --
  -- Until revision 22 the kit had no model of a bucket at all, so an addon that coalesced its
  -- UNIT_AURA traffic through AceBucket had a registration set no suite could see, and a
  -- stand-down that forgot UnregisterAllBuckets passed every test in its repo.
  local M = buildMocks()
  local t = {}
  M.__libs["AceBucket-3.0"]:Embed(t)
  local handle = t:RegisterBucketEvent({ "UNIT_AURA", "UNIT_HEALTH" }, 0.2, function() end)
  assertEqual(names(M), "bucket:UNIT_AURA,bucket:UNIT_HEALTH")
  t:UnregisterBucket(handle)
  assertEqual(names(M), "")
end)

test("record: a bucket fires on its interval, through the one timer queue", function()
  local M = buildMocks()
  local t = {}
  M.__libs["AceBucket-3.0"]:Embed(t)
  local fired = 0
  t:RegisterBucketEvent("UNIT_AURA", 0.2, function() fired = fired + 1 end)
  M.__fire("UNIT_AURA", "player")
  M.__fire("UNIT_AURA", "target")
  assertEqual(fired, 0, "a bucket does not call back on the event; that is what a bucket is for")
  M.__fireTimers()
  assertEqual(fired, 1, "two events, one callback")
end)

test("record: a bucket unregistered before its tick does NOT call back", function()
  local M = buildMocks()
  local t = {}
  M.__libs["AceBucket-3.0"]:Embed(t)
  local fired = 0
  t:RegisterBucketEvent("UNIT_AURA", 0.2, function() fired = fired + 1 end)
  M.__fire("UNIT_AURA", "player")
  t:UnregisterAllBuckets()
  M.__fireTimers()
  assertEqual(fired, 0, "the real library cancels its timer; the fake's guard is what agrees with it")
end)

-- ── firing ─────────────────────────────────────────────────────────────────────────────────

test("record: __fire reaches the LIVE set only", function()
  -- red under: make __fire dispatch to every frame rather than to the registered ones
  local M = buildMocks()
  local f = M.CreateFrame("Frame")
  local hits = 0
  f:SetScript("OnEvent", function() hits = hits + 1 end)
  f:RegisterEvent("UNIT_AURA")
  assertEqual(M.__fire("UNIT_AURA"), 1)
  assertEqual(hits, 1)
  f:UnregisterAllEvents()
  assertEqual(M.__fire("UNIT_AURA"), 0, "the client fires at whoever is registered, and nobody is")
  assertEqual(hits, 1)
end)

test("record: __fireUnconditional reaches a target whose registration is gone", function()
  -- THE FALSIFICATION HALF. Without it, "no handler ran" is a claim about the harness: an empty
  -- registry dispatches nothing whether the addon stood down or the mock lost the ability to
  -- dispatch at all. This is what proves a survivor would have been caught.
  local M = buildMocks()
  local f = M.CreateFrame("Frame")
  local hits = 0
  f:SetScript("OnEvent", function() hits = hits + 1 end)
  f:RegisterEvent("UNIT_AURA")
  f:UnregisterAllEvents()
  assertEqual(M.__fire("UNIT_AURA"), 0, "unreachable from the client")
  assertEqual(M.__fireUnconditional(f, "UNIT_AURA"), 1, "and still very much there")
  assertEqual(hits, 1)
end)

test("record: __fireUnconditional drives an AceEvent handler too", function()
  local M = buildMocks()
  local seen = {}
  local t = { PLAYER_LOGIN = function(_, event) seen[#seen + 1] = event end }
  M.__libs["AceEvent-3.0"]:Embed(t)
  t:RegisterEvent("PLAYER_LOGIN")
  t:UnregisterAllEvents()
  assertEqual(M.__fire("PLAYER_LOGIN"), 0)
  assertEqual(M.__fireUnconditional(t, "PLAYER_LOGIN"), 1)
  assertEqual(table.concat(seen, ","), "PLAYER_LOGIN")
end)

-- ── timers ─────────────────────────────────────────────────────────────────────────────────

test("record: the timer queue is both the pending array and the live set", function()
  local M = buildMocks()
  assertEqual(#M.__timers, 0, "indexed: what is pending")
  assertEqual(#M.__timers(), 0, "called: what is still going to wake up")
  M.C_Timer.After(0.1, function() end)
  assertEqual(#M.__timers, 1)
  assertEqual(#M.__timers(), 1)
  M.__fireTimers()
  assertEqual(#M.__timers, 0, "a one-shot that has run is neither pending")
  assertEqual(#M.__timers(), 0, "nor live")
end)

test("record: a canceled ticker leaves the live set", function()
  -- red under: make C_Timer handle Cancel a no-op again
  local M = buildMocks()
  local ticker = M.C_Timer.NewTimer(0.5, function() end)
  assertEqual(#M.__timers(), 1)
  ticker.Cancel()
  assertEqual(#M.__timers(), 0)
end)

test("record: a repeating AceTimer stays live across a tick, and leaves on cancel", function()
  -- The case a pending-queue read cannot answer: a repeating ticker that has just fired is absent
  -- from the queue for a moment and is still very much alive.
  local M = buildMocks()
  local t = {}
  M.__libs["AceTimer-3.0"]:Embed(t)
  local handle = t:ScheduleRepeatingTimer(function() end, 0.3)
  assertEqual(#M.__timers(), 1)
  M.__fireTimers()
  assertEqual(#M.__timers(), 1, "still armed, and a stood-down addon must not leave it so")
  t:CancelTimer(handle)
  assertEqual(#M.__timers(), 0)
end)

test("record: a frame carrying an OnUpdate is live until the script is cleared", function()
  -- red under: stop surveying OnUpdate scripts
  --
  -- An OnUpdate left armed on a stood-down addon is a per-frame cost that no visible surface
  -- reports, which is exactly why it has a step of its own in the conformance suite.
  local M = buildMocks()
  local f = M.CreateFrame("Frame")
  f:SetScript("OnUpdate", function() end)
  assertEqual(#M.__timers(), 1)
  f:SetScript("OnUpdate", nil)
  assertEqual(#M.__timers(), 0)
end)

-- ── shown frames ───────────────────────────────────────────────────────────────────────────

test("record: __shownFrames answers what is on screen, in creation order", function()
  local M = buildMocks()
  local before = #M.__shownFrames()
  local a, b = M.CreateFrame("Frame"), M.CreateFrame("Frame")
  a:Show(); b:Show()
  local shown = M.__shownFrames()
  assertEqual(#shown - before, 2)
  assertTrue(shown[#shown - 1].__seq < shown[#shown].__seq, "creation order, so two lists diff")
  b:Hide()
  assertEqual(#M.__shownFrames() - before, 1)
  a:SetShown(false)
  assertEqual(#M.__shownFrames() - before, 0)
end)

test("record: a frame an addon's own mock built with __stubFrame is surveyed too", function()
  -- Otherwise the one frame a consumer had to make for itself is the one frame its stand-down
  -- suite cannot see.
  local M = buildMocks()
  local before = #M.__shownFrames()
  local f = M.__stubFrame()
  f:Show()
  assertEqual(#M.__shownFrames() - before, 1)
end)

-- ── printed lines ──────────────────────────────────────────────────────────────────────────

test("record: every line that reached the chat frame is recorded, and resettable", function()
  local M = buildMocks()
  M.__resetPrinted()
  M.DEFAULT_CHAT_FRAME:AddMessage("first")
  M.DEFAULT_CHAT_FRAME:AddMessage("second")
  assertEqual(table.concat(M.__printed(), "|"), "first|second")
  M.__resetPrinted()
  assertEqual(#M.__printed(), 0)
end)

test("record: __printed hands back a copy, not the live log", function()
  local M = buildMocks()
  M.__resetPrinted()
  M.DEFAULT_CHAT_FRAME:AddMessage("one")
  local snapshot = M.__printed()
  snapshot[#snapshot + 1] = "injected"
  assertEqual(#M.__printed(), 1, "mutating the report did not mutate the record")
end)

test("record: a host printer that bypasses the chat frame can still be recorded", function()
  local M = buildMocks()
  M.__resetPrinted()
  local hostPrint = function(line) M.__recordPrint("[TH] " .. line) end
  hostPrint("hello")
  assertEqual(M.__printed()[1], "[TH] hello")
end)

-- ── SavedVariables writes ──────────────────────────────────────────────────────────────────

local function newDb(M, name)
  _G[name] = nil
  return M.__libs["AceDB-3.0"]:New(name, { profile = { barWidth = 200, locked = false } })
end

test("record: a write to the profile is reported by path and value", function()
  local M = buildMocks()
  local db = newDb(M, "RecordTestDB")
  M.__resetSvWrites()
  db.profile.barWidth = 240
  local writes = M.__svWrites()
  assertEqual(#writes, 1)
  assertEqual(writes[1].path, "RecordTestDB.profiles.Default.barWidth")
  assertEqual(writes[1].value, 240)
end)

test("record: an addon that writes nothing reports zero writes", function()
  -- red under: seed the baseline from an empty table rather than from the live tree
  --
  -- The assertion step 6 of the conformance suite is built on: fire every event the addon used to
  -- be registered for, and assert that nothing reached disk.
  local M = buildMocks()
  local db = newDb(M, "RecordQuietDB")
  M.__resetSvWrites()
  local _ = db.profile.barWidth        -- a READ is not a write
  assertEqual(#M.__svWrites(), 0)
end)

test("record: clearing a key counts as a write", function()
  local M = buildMocks()
  local db = newDb(M, "RecordClearDB")
  db.profile.barWidth = 240
  M.__resetSvWrites()
  db.profile.barWidth = nil
  local writes = M.__svWrites()
  assertEqual(#writes, 1, "a setting being cleared is how a setting is cleared")
  assertEqual(writes[1].path, "RecordClearDB.profiles.Default.barWidth")
  assertEqual(writes[1].value, nil)
end)

test("record: a global SavedVariables table can be watched explicitly", function()
  -- LibKa0s-Perf-1.0's record ring is the collection's example: `_G[descriptor.sv]`, never through
  -- AceDB, and invisible to the survey until it is named.
  local M = buildMocks()
  _G.RecordRingDB = { records = {} }
  M.__watchSv("RecordRingDB")
  assertEqual(#M.__svWrites(), 0)
  _G.RecordRingDB.records[1] = "a record"
  local writes = M.__svWrites()
  assertEqual(#writes, 1)
  assertEqual(writes[1].path, "RecordRingDB.records.1")
  _G.RecordRingDB = nil
end)

test("record: two databases are told apart in the report", function()
  local M = buildMocks()
  local one = newDb(M, "RecordOneDB")
  local two = newDb(M, "RecordTwoDB")
  M.__resetSvWrites()
  one.profile.locked = true
  two.profile.locked = true
  local writes = M.__svWrites()
  assertEqual(#writes, 2)
  assertEqual(writes[1].path, "RecordOneDB.profiles.Default.locked")
  assertEqual(writes[2].path, "RecordTwoDB.profiles.Default.locked")
end)

-- ── AceDB's profile verbs raise where AceDB-3.0 raises (revision 26) ──────────────────────
--
-- Through revision 25 the fake returned silently from every bad profile name, so a consumer's
-- "copy a profile" slash command passed a headless suite on a name that raises a raw Lua error in
-- the client. The messages are asserted byte for byte: they are AceDB-3.0.lua's own, :531-537 and
-- :581-587 in every consumer's vendored copy.

local function profileDb(M, name)
  _G[name] = nil
  local db = M.__libs["AceDB-3.0"]:New(name, { profile = { barWidth = 200, pos = { x = 1 } } })
  db:SetProfile("B")
  db:SetProfile("Default")
  return db
end

test("record: CopyProfile onto the active profile raises AceDB's own message", function()
  -- red under: `if not src or name == current then return end`, the silent return
  local db = profileDb(buildMocks(), "RecordCopySelfDB")
  local err = assertErrorMatches(function() db:CopyProfile("Default") end,
    'Cannot have the same source and destination profiles ("Default").')
  assertTrue(err:find("test_mock_record.lua:", 1, true) ~= nil,
    "raised at level 2, so the position names the caller, not the kit: " .. err)
end)

test("record: CopyProfile from a missing profile raises unless silent", function()
  -- red under: `if not src or name == current then return end`, the silent return
  local db = profileDb(buildMocks(), "RecordCopyMissingDB")
  assertErrorMatches(function() db:CopyProfile("Missing") end,
    'Cannot copy profile "Missing" as it does not exist.')
end)

test("record: CopyProfile(missing, true) is silent, and resets the active profile as AceDB does", function()
  -- red under: the silent return, which left the active profile untouched
  local db = profileDb(buildMocks(), "RecordCopySilentDB")
  db.profile.barWidth = 240
  local heard
  db.RegisterCallback({}, "OnProfileCopied", function(_, _, key) heard = key end)
  db:CopyProfile("Missing", true)
  assertEqual(db.profile.barWidth, 200, "AceDB resets before it copies, and there was nothing to copy")
  assertEqual(heard, "Missing", "OnProfileCopied still fires, with the source's name")
end)

test("record: DeleteProfile on the active profile raises AceDB's own message", function()
  -- red under: `if name == current then return end`, the silent return
  local db = profileDb(buildMocks(), "RecordDeleteSelfDB")
  assertErrorMatches(function() db:DeleteProfile("Default") end,
    'Cannot delete the active profile ("Default") in an AceDBObject.')
  assertTrue(db.sv.profiles.Default ~= nil, "and the profile is still there")
end)

test("record: DeleteProfile on a missing profile raises unless silent", function()
  -- red under: `sv.profiles[name] = nil` run unconditionally, a silent no-op on a missing name
  local db = profileDb(buildMocks(), "RecordDeleteMissingDB")
  assertErrorMatches(function() db:DeleteProfile("Missing") end,
    'Cannot delete profile "Missing" as it does not exist.')
end)

test("record: DeleteProfile(missing, true) is silent, and a real delete still deletes", function()
  -- red under: a DeleteProfile that ignores `silent` and raises on every missing name. Green under
  -- the old silent return too: it is the pair to the raise above, so that raise cannot be won by
  -- raising on every call.
  local db = profileDb(buildMocks(), "RecordDeleteSilentDB")
  db:DeleteProfile("Missing", true)
  db:DeleteProfile("B")
  assertEqual(db.sv.profiles.B, nil, "a profile that exists is deleted")
end)

test("record: SetProfile strips values equal to their defaults from the OUTGOING profile", function()
  -- red under: a SetProfile that only swaps `current` and fires, with no removeDefaults
  --
  -- AceDB-3.0.lua:460-463 runs removeDefaults over the old profile before it switches, so what the
  -- SavedVariables file holds for a profile nobody is using is only what differs from the defaults.
  local db = profileDb(buildMocks(), "RecordStripDB")
  local a = db.profile
  a.barWidth = 200            -- equal to its default: the scalar arm strips it
  a.pos.x = 1                 -- equal to its default, inside a default table: the table arm
  a.extra = "kept"            -- no default at all: never touched
  db:SetProfile("B")
  assertEqual(a.barWidth, nil, "a scalar equal to its default is stripped")
  assertEqual(a.pos, nil, "a default table left empty by the strip is removed")
  assertEqual(a.extra, "kept", "a key with no default survives")
  assertTrue(db.sv.profiles.Default == a, "stripped in place, as AceDB does")
  db:SetProfile("Default")
  assertEqual(db.profile.barWidth, 200, "and switching back reads the default again")
end)

test("record: SetProfile keeps a value that differs from its default", function()
  -- red under: a strip that compares by key presence rather than by value
  local db = profileDb(buildMocks(), "RecordKeepDB")
  local a = db.profile
  a.barWidth = 240
  a.pos.x = 5
  db:SetProfile("B")
  assertEqual(a.barWidth, 240)
  assertEqual(a.pos.x, 5)
end)

-- ── what AceGUI still holds (revision 26) ──────────────────────────────────────────────────

test("record: __aceguiLive counts a Create per type and gives it back on Release", function()
  -- red under: no survey, or a Create or Release that does not report to it
  --
  -- The kit's AceGUI fake never reuses a widget, so a render that Creates and never Releases
  -- passes every other assertion: only a count of what is still out can see the leak
  -- (review finding LibKa0s-R-02).
  local M = buildMocks()
  local AceGUI = M.__libs["AceGUI-3.0"]
  assertEqual(M.__aceguiLive("Dropdown"), 0, "a fresh build holds nothing")
  local a = AceGUI:Create("Dropdown")
  local b = AceGUI:Create("Dropdown")
  AceGUI:Create("Button")
  assertEqual(M.__aceguiLive("Dropdown"), 2)
  assertEqual(M.__aceguiLive("Button"), 1, "counted per type, not in one pile")
  AceGUI:Release(a)
  assertEqual(M.__aceguiLive("Dropdown"), 1, "a Release gives one back")
  b:Release()
  assertEqual(M.__aceguiLive("Dropdown"), 0, "the method form counts too")
  local all = M.__aceguiLive()
  assertEqual(all.Button, 1, "with no type, every type still out")
  assertEqual(all.Dropdown, nil, "and a type with nothing out is not listed")
end)

test("record: __aceguiLive ignores a Release it never saw created, and a registered type counts",
function()
  -- red under: decrementing on every Release, which drives a count below zero, or counting only
  -- the factory's own widgets and not a constructor a suite registered
  local M = buildMocks()
  local AceGUI = M.__libs["AceGUI-3.0"]
  local stray = M.__makeAceGUIWidget("Dropdown")
  AceGUI:Release(stray)
  assertEqual(M.__aceguiLive("Dropdown"), 0, "a widget the factory never handed out is not owed")
  AceGUI:RegisterWidgetType("Custom", function() return M.__makeAceGUIWidget("Custom") end, 1)
  local c = AceGUI:Create("Custom")
  assertEqual(M.__aceguiLive("Custom"), 1)
  AceGUI:Release(c)
  assertEqual(M.__aceguiLive("Custom"), 0)
end)
