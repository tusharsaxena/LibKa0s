-- tests/test_callout_voice.lua — LibKa0s-Callout-1.0's sound and timing edges, in depth (plan row
-- L6): text to speech with C_VoiceChat absent and present, numbers spoken only from speakFrom, a
-- custom sound file played verbatim, a countdown with finish = false, `from` clamped to 20, and the
-- stand-down canceling and hiding whatever is up.
--
-- The bench is tests/fixture_callout.lua's: `m.__files` records every PlaySoundFile call,
-- `F.tts(m, voices)` installs a recording C_VoiceChat, `frameAt(m, t)` is one client frame at t.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local F = dofile("tests/fixture_callout.lua")
local newCallout, parts, frameAt, tts = F.newCallout, F.parts, F.frameAt, F.tts

local VOICES = { { voiceID = 3, name = "Zira" }, { voiceID = 7, name = "David" } }

local function shown(c)
  local f, text = parts(c)
  if not f:IsShown() then return nil end
  return text:GetText()
end

local function live(m) return #m.__timers() end

local function files(m)
  local out = {}
  for i, f in ipairs(m.__files) do out[i] = f.file:match("[^\\]+$") end
  return table.concat(out, ",")
end

local function said(m)
  local out = {}
  for i, s in ipairs(m.__spoken or {}) do out[i] = s.text end
  return table.concat(out, ",")
end

local function withVoices(m) tts(m, VOICES) end

-- ── numbers spoken only from speakFrom ───────────────────────────────────────────────────────

test("speak from: a countdown from 10 speaks 5 to 1 and GO, and shows every number", function()
  local c, m = newCallout()
  local ticks = {}
  c:Countdown{ endsAt = 10, onTick = function(n) ticks[#ticks + 1] = n end }
  for t = 1, 10 do frameAt(m, t) end
  assertEqual(table.concat(ticks, ","), "10,9,8,7,6,5,4,3,2,1", "every number shows")
  assertEqual(files(m), "5.ogg,4.ogg,3.ogg,2.ogg,1.ogg,go.ogg", "only 5 and below are spoken")
end)

test("speak from: the setting moves the line, from 1 to 20", function()
  local c, m = newCallout()
  assertTrue(c:Set("speakFrom", 2))
  c:Countdown{ endsAt = 4, finish = false }
  for t = 1, 4 do frameAt(m, t) end
  assertEqual(files(m), "2.ogg,1.ogg")
  assertTrue(c:Set("speakFrom", 20))
  m.__files = {}
  m.__now = 100
  c:Countdown{ endsAt = 120, finish = false }
  assertEqual(files(m), "20.ogg", "20 is spoken from 20")
  assertFalse(c:Set("speakFrom", 0))
  assertFalse(c:Set("speakFrom", 21))
end)

test("speak from: a number shown on its own follows the same line, a stock key never does", function()
  local c, m = newCallout()
  c:Set("speakFrom", 3)
  c:Show(10)
  c:Show("4")
  assertEqual(#m.__files, 0, "10 and 4 are above 3")
  c:Show(3)
  c:Show("LAST_TEN")
  assertEqual(files(m), "3.ogg,last_ten.ogg", "a stock key is not a number")
end)

test("speak from: text to speech speaks the numbers from the line too", function()
  local c, m = newCallout(nil, withVoices)
  c:Set("voice", "tts")
  c:Set("speakFrom", 3)
  c:Countdown{ endsAt = 6 }
  for t = 1, 6 do frameAt(m, t) end
  assertEqual(said(m), "3,2,1,Go", "4 to 6 are shown, not spoken; a stock key says its words")
  assertEqual(#m.__files, 0, "text to speech plays no file")
end)

-- ── text to speech ───────────────────────────────────────────────────────────────────────────

test("tts: absent C_VoiceChat, the call-out still shows, says nothing, raises nothing", function()
  local c, m, _, logs = newCallout()
  assertTrue(c:Set("voice", "tts"))
  assertTrue(c:Show("GO"))
  assertEqual(shown(c), "GO!")
  c:Countdown{ endsAt = 2 }
  frameAt(m, 1)
  frameAt(m, 2)
  assertEqual(shown(c), "GO!")
  assertEqual(#m.__files, 0, "no pack line stands in for text to speech")
  assertEqual(#m.__errors, 0)
  assertEqual(#logs, 1, "logged once for the session")
  assertTrue(logs[1].msg:find("SpeakText", 1, true) ~= nil, "naming what is missing")
  assertEqual(#c:TtsVoices(), 0)
end)

test("tts: a C_VoiceChat without SpeakText is absent too; one without GetTtsVoices has no voice", function()
  local c, m, _, logs = newCallout(nil, function(mm) mm.C_VoiceChat = { GetTtsVoices = function() return VOICES end } end)
  c:Set("voice", "tts")
  c:Show("GO")
  assertEqual(#m.__errors, 0)
  assertEqual(#logs, 1)
  assertEqual(#c:TtsVoices(), 2, "the voices are still listed")
  local spoken = {}
  local c2, m2, _, logs2 = newCallout(nil, function(mm)
    mm.C_VoiceChat = { SpeakText = function(...) spoken[#spoken + 1] = { ... } end }
  end)
  c2:Set("voice", "tts")
  c2:Show("GO")
  assertEqual(#spoken, 0, "no voice to speak with")
  assertEqual(#logs2, 1)
  assertEqual(#m2.__errors, 0)
end)

test("tts: present, the line's words are spoken at the player's rate and volume, overlapping", function()
  local c, m = newCallout(nil, withVoices)
  c:Set("voice", "tts")
  c:Set("ttsRate", -4)
  c:Set("ttsVolume", 35)
  c:Show("LAST_TEN")
  local s = m.__spoken[1]
  assertEqual(s.text, "Last ten seconds", "the stock key's say, not its shown text")
  assertEqual(s.id, 3)
  assertEqual(s.rate, -4)
  assertEqual(s.volume, 35)
  assertTrue(s.overlap, "a call-out never waits for the last one")
  c:Set("texts", { GO = "Allez" })
  c:Show("GO")
  assertEqual(m.__spoken[2].text, "Go", "the player's own shown text does not change what is said")
  assertEqual(shown(c), "Allez")
end)

test("tts: the voice list is the client's, malformed rows dropped, names defaulted", function()
  local c = newCallout(nil, function(mm)
    tts(mm, { { voiceID = 4, name = "Hazel" }, "junk", { name = "no id" }, { voiceID = 9 } })
  end)
  local v = c:TtsVoices()
  assertEqual(#v, 2)
  assertEqual(v[1].name, "Hazel")
  assertEqual(v[2].name, "9", "a voice with no name is named by its id")
  v[1].name = "changed"
  assertEqual(c:TtsVoices()[1].name, "Hazel", "a fresh list each call")
end)

test("tts: a custom text with its own sound plays the file, not the voice; muted and voice=false are silent", function()
  local c, m = newCallout(nil, withVoices)
  c:Set("voice", "tts")
  c:Show({ text = "Bloodlust", sound = "Interface\\AddOns\\Host\\lust.ogg" })
  assertEqual(#m.__spoken, 0)
  assertEqual(files(m), "lust.ogg")
  c:Show({ text = "Quiet", voice = false })
  c:Set("muted", { STOP = true })
  c:Show("STOP")
  assertEqual(#m.__spoken, 0)
  c:Show({ text = "Heroism" })
  assertEqual(said(m), "Heroism", "a custom text with no sound is spoken by its text")
end)

-- ── a custom sound file ──────────────────────────────────────────────────────────────────────

test("custom sound: the path is played exactly as given, on the player's channel", function()
  local c, m = newCallout()
  c:Set("channel", "SFX")
  local paths = {
    "Interface\\AddOns\\Host\\Sounds\\Air Horn.OGG",
    "Interface/AddOns/Host/sounds/beep.mp3",
    "Sound\\Interface\\RaidWarning.ogg",
  }
  for _, p in ipairs(paths) do c:Show({ text = "x", sound = p }) end
  for i, p in ipairs(paths) do
    assertEqual(m.__files[i].file, p, "verbatim: " .. p)
    assertEqual(m.__files[i].channel, "SFX")
  end
end)

test("custom sound: a FileDataID number is played as that number", function()
  local c, m = newCallout()
  c:Show({ text = "x", sound = 567890 })
  assertEqual(m.__files[1].file, 567890)
end)

test("custom sound: it needs no addon or soundsBase, and is not under the pack folder", function()
  local c, m, _, logs = newCallout({ addon = false })
  c:Show({ text = "Mine", sound = "Interface\\AddOns\\Host\\mine.ogg" })
  assertEqual(m.__files[1].file, "Interface\\AddOns\\Host\\mine.ogg")
  assertEqual(#logs, 0, "nothing about the packs is logged")
  c:Set("voice", "male")
  c:Show({ text = "Mine", sound = "Interface\\AddOns\\Host\\mine.ogg" })
  assertEqual(m.__files[2].file, "Interface\\AddOns\\Host\\mine.ogg", "whatever the pack")
end)

test("custom sound: a missing file is silence, logged once by its path; an empty path is no sound", function()
  local c, m, _, logs = newCallout()
  m.__missing["Interface\\gone.ogg"] = true
  c:Show({ text = "a", sound = "Interface\\gone.ogg" })
  c:Show({ text = "b", sound = "Interface\\gone.ogg" })
  assertEqual(#logs, 1)
  assertTrue(logs[1].msg:find("Interface\\gone.ogg", 1, true) ~= nil)
  assertEqual(shown(c), "b")
  m.__files = {}
  c:Show({ text = "c", sound = "" })
  assertEqual(#m.__files, 0, "an empty path is not a file, and a pack has no line for a custom text")
end)

test("custom sound: no PlaySoundFile in the client is silence, logged once", function()
  local c, m, _, logs = newCallout()
  m.PlaySoundFile = nil
  c:Show({ text = "x", sound = "Interface\\x.ogg" })
  c:Show("GO")
  assertEqual(#logs, 1)
  assertTrue(logs[1].msg:find("PlaySoundFile", 1, true) ~= nil)
  assertEqual(#m.__errors, 0)
end)

-- ── finish = false ───────────────────────────────────────────────────────────────────────────

test("finish false: at zero nothing new shows or plays, the 1 fades, onDone runs once", function()
  local c, m = newCallout()
  c:Set("speakFrom", 1)
  local done, ticks = 0, {}
  c:Countdown{ endsAt = 2, finish = false, onDone = function() done = done + 1 end,
    onTick = function(n) ticks[#ticks + 1] = n end }
  frameAt(m, 1)
  local fade = rawget(parts(c), "__groups")[1]
  assertEqual(fade.__plays, 0)
  frameAt(m, 2)
  assertEqual(done, 1)
  assertEqual(table.concat(ticks, ","), "2,1", "no tick for zero")
  assertEqual(files(m), "1.ogg", "no finish line is played")
  assertEqual(fade.__plays, 1, "the last number fades at zero")
  assertEqual(c:Stats().key, "1")
  assertFalse(c:Running())
  assertEqual(live(m), 0, "the clock sleeps at once: no hold to wait out")
  fade:__finish()
  assertNil(shown(c))
  assertNil(c:Stats().key)
  frameAt(m, 5)
  assertEqual(done, 1)
end)

test("finish false: an endsAt already past is onDone at the call, with nothing on screen", function()
  local c, m = newCallout()
  m.__now = 30
  local done = false
  assertTrue(c:Countdown{ endsAt = 29, finish = false, onDone = function() done = true end })
  assertTrue(done)
  assertNil(shown(c))
  assertEqual(#m.__files, 0)
  assertEqual(live(m), 0)
end)

test("finish: a number finish shows that number; nil is GO; an unknown key is no finish", function()
  local c, m = newCallout()
  c:Countdown{ endsAt = 1, finish = 20 }
  frameAt(m, 1)
  assertEqual(shown(c), "20")
  local done = false
  c:Countdown{ endsAt = 2, finish = "NOT_A_KEY", onDone = function() done = true end }
  frameAt(m, 2)
  assertTrue(done, "onDone runs whatever the finish")
  assertEqual(c:Stats().text, "1")
  c:Countdown{ endsAt = 3 }
  frameAt(m, 3)
  assertEqual(shown(c), "GO!")
end)

-- ── from clamped to 20 ───────────────────────────────────────────────────────────────────────

test("from: above 20 is 20; nothing shows until the remainder reaches it", function()
  local c, m = newCallout()
  local ticks = {}
  c:Countdown{ endsAt = 25, from = 25, onTick = function(n) ticks[#ticks + 1] = n end }
  assertNil(shown(c))
  frameAt(m, 4.5)
  assertNil(shown(c), "21 is above 20")
  frameAt(m, 5)
  assertEqual(shown(c), "20")
  assertEqual(table.concat(ticks, ","), "20")
  assertTrue(c:Running(), "the countdown ran all along")
end)

test("from: nil is 20, a fraction is floored, a numeric string is read, a nonsense one is 20", function()
  local c, m = newCallout()
  c:Countdown{ endsAt = 22 }
  frameAt(m, 1.5)
  assertNil(shown(c), "nil is 20: 21 does not show")
  frameAt(m, 2)
  assertEqual(shown(c), "20")
  c:Cancel()
  m.__now = 100
  c:Countdown{ endsAt = 110, from = 9.9 }
  assertNil(shown(c), "9.9 is 9: 10 does not show")
  frameAt(m, 101)
  assertEqual(shown(c), "9")
  c:Cancel()
  m.__now = 200
  c:Countdown{ endsAt = 207, from = "7" }
  assertEqual(shown(c), "7")
  c:Cancel()
  m.__now = 300
  c:Countdown{ endsAt = 320, from = "soon" }
  assertEqual(shown(c), "20")
end)

test("from: negative and zero are 1, so only the 1 shows before the finish", function()
  local c, m = newCallout()
  local ticks = {}
  c:Countdown{ endsAt = 3, from = -5, onTick = function(n) ticks[#ticks + 1] = n end }
  frameAt(m, 1)
  assertNil(shown(c))
  frameAt(m, 2)
  assertEqual(shown(c), "1")
  frameAt(m, 3)
  assertEqual(shown(c), "GO!")
  assertEqual(table.concat(ticks, ","), "1")
end)

test("from: MAX_FROM is 20, the last number a pack has a line for", function()
  local _, _, _, _, Callout = newCallout()
  assertEqual(Callout.MAX_FROM, 20)
  assertEqual(Callout.LINES[#Callout.LINES], tostring(Callout.MAX_FROM))
end)

-- ── the stand-down ───────────────────────────────────────────────────────────────────────────

test("suspend: a call-out holding on screen goes at once, with no fade and nothing armed", function()
  local c, m = newCallout()
  c:Show("MOVE", { hold = 5 })
  local fade = rawget(parts(c), "__groups")[1]
  c:Suspend()
  assertNil(shown(c))
  assertEqual(fade.__plays, 0, "taken down, not faded")
  assertEqual(live(m), 0)
  assertNil(c:Stats().key)
  frameAt(m, 10)
  assertNil(shown(c))
end)

test("suspend: an unlocked frame is locked and its sample goes; Resume does not unlock or re-show", function()
  local c = newCallout()
  c:SetLocked(false)
  assertEqual(shown(c), "READY")
  c:Suspend()
  assertTrue(c:Locked())
  assertNil(shown(c))
  assertFalse(rawget(parts(c), "__mouse"), "mouse-transparent again")
  c:Resume()
  assertTrue(c:Locked())
  assertNil(shown(c))
end)

test("suspend: a running animation is stopped, and the countdown's onTick and onDone never run again", function()
  local c, m = newCallout()
  local ticks, done = 0, false
  c:Countdown{ endsAt = 3, onTick = function() ticks = ticks + 1 end, onDone = function() done = true end }
  local slam = rawget(parts(c), "__groups")[2]
  local stops = slam.__stops
  c:Suspend()
  assertTrue(slam.__stops > stops)
  for t = 1, 5 do frameAt(m, t) end
  assertEqual(ticks, 1, "only the first number, before the stand-down")
  assertFalse(done)
  assertEqual(#m.__files, 1)
end)

test("suspend: before first use it builds nothing; twice is once; Resume twice is harmless", function()
  local c, m = newCallout()
  c:Suspend()
  c:Suspend()
  assertFalse(c:Stats().built)
  assertEqual(#m.__made, 0)
  assertTrue(c:Suspended())
  assertFalse(c:Preview(), "a preview is a Show, refused while suspended")
  assertFalse(c:TestCountdown())
  c:Resume()
  c:Resume()
  assertFalse(c:Suspended())
end)

test("suspend: after Resume a countdown runs to its finish as new", function()
  local c, m = newCallout()
  c:Countdown{ endsAt = 9 }
  c:Suspend()
  c:Resume()
  m.__now = 20
  local done = false
  assertTrue(c:Countdown{ endsAt = 22, onDone = function() done = true end })
  assertEqual(shown(c), "2")
  frameAt(m, 22)
  assertTrue(done)
  assertEqual(shown(c), "GO!")
end)

test("suspend: settings still read and write while suspended", function()
  local c, _, db = newCallout()
  c:Suspend()
  assertTrue(c:Set("size", 150))
  assertEqual(db.size, 150)
  assertTrue(c:SetColor("go", 0, 1, 0))
  assertEqual(c:Get("size"), 150)
end)
