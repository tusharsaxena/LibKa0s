-- tests/test_callout.lua — LibKa0s-Callout-1.0, the center-screen call-out (LibKa0s#85).
--
-- The bench is tests/fixture_callout.lua: a fresh environment per case, the kit's paint recorder
-- (so the text and the halo are distinct FontStrings), recording AnimationGroups, recorded sound,
-- and `frameAt(m, t)`, which sets the kit's clock and runs the call-out's OnUpdate once, the way one
-- client frame does.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil, assertError =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil, T.assertError
local Loader = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local F = dofile("tests/fixture_callout.lua")
local MAJOR = F.MAJOR
local env, newCallout, parts, frameAt, tts = F.env, F.newCallout, F.parts, F.frameAt, F.tts

local PACK_DIR = "Interface\\AddOns\\TestAddon\\libs\\LibKa0s\\media\\sounds\\callout\\"

local function shown(c)
  local f, text = parts(c)
  if not f:IsShown() then return nil end
  return text:GetText()
end

local function live(m) return #m.__timers() end

-- ── load and construction ────────────────────────────────────────────────────────────────────

test("callout: the major loads at minor 3 and reports its one file", function()
  local _, Callout = env()
  assertEqual(Callout.MAJOR, MAJOR)
  assertEqual(Callout.MINOR, 3)
  assertEqual(Callout.MODULES.Callout, 3)
  assertEqual(T.callout, T.mocks.LibStub(MAJOR), "the runner's whole-payload load carries it too")
end)

test("callout: without Core the major is absent (no NewLibrary)", function()
  local m = buildMocks()
  Loader.load("LibKa0s/Callout.lua", nil, m)
  assertNil(m.LibStub(MAJOR, true))
end)

test("callout: New refuses a descriptor without a db, naming it", function()
  local _, Callout = env()
  local err = assertError(function() Callout:New({}) end)
  assertTrue(err:find("d.db", 1, true) ~= nil, "names d.db; got: " .. err)
  assertError(function() Callout:New(nil) end)
  Callout:New({ db = function() return {} end })   -- a getter is a db
end)

test("callout: a method called on something that is not an instance raises", function()
  local c = newCallout()
  local err = assertError(function() c.Show({}, "GO") end)
  assertTrue(err:find("Callout:New", 1, true) ~= nil, "says where an instance comes from; got: " .. err)
end)

test("callout: nothing is built before first use, and nothing wakes", function()
  local c, m = newCallout()
  assertFalse(c:Stats().built)
  assertEqual(#m.__made, 0)
  assertEqual(live(m), 0)
end)

test("callout: the frame is the screen alert tier, clamped, and never takes the mouse while locked", function()
  local c = newCallout()
  local f = parts(c)
  assertEqual(rawget(f, "__strata"), "FULLSCREEN", "frame-layering-§1 T5, the non-interactive screen alert")
  assertTrue(rawget(f, "__clamped"))
  assertFalse(rawget(f, "__mouse"))
  assertTrue(c:Locked())
end)

test("callout: the stock texts, the packs and the lines are data", function()
  local _, Callout = env()
  assertEqual(#Callout.STOCK_ORDER, 23)
  for _, key in ipairs(Callout.STOCK_ORDER) do
    assertTrue(Callout.STOCK[key] ~= nil, key .. " has a row")
  end
  assertEqual(#Callout.LINES, 43, "23 stock lines and the numbers 1 to 20")
  assertEqual(Callout.LINES[1], "ready")
  assertEqual(Callout.LINES[43], "20")
  assertEqual(Callout.PACKS[1].key, "female")
  assertEqual(Callout.PACKS[2].folder, "male-joe")
  assertEqual(Callout.DEFAULTS.voice, "female", "the default voice is the first pack")
end)

test("texts: every pack folder ships exactly LINES as .ogg, beside its credits", function()
  -- red under: a pack row whose folder is missing a line, or carries a clip no LINES entry names
  local _, Callout = env()
  for _, pack in ipairs(Callout.PACKS) do
    local dir = "LibKa0s/media/sounds/callout/" .. pack.folder .. "/"
    local p = io.popen("git ls-files -co --exclude-standard -- '" .. dir .. "' 2>/dev/null")
    local onDisk, clips = {}, 0
    for path in p:read("*a"):gmatch("[^\n]+") do
      local name = path:match("[^/]+$")
      onDisk[name] = true
      if name:match("%.ogg$") then clips = clips + 1 end
    end
    p:close()
    for _, line in ipairs(Callout.LINES) do
      assertTrue(onDisk[line .. Callout.SOUND_EXT], pack.folder .. " has " .. line .. Callout.SOUND_EXT)
    end
    assertEqual(clips, #Callout.LINES, pack.folder .. " carries no clip LINES does not name")
    assertTrue(onDisk["CREDITS.md"], pack.folder .. " carries its CREDITS.md")
  end
end)

-- ── the countdown ────────────────────────────────────────────────────────────────────────────

test("countdown: the first number shows at the call, and onTick hears it", function()
  local c, m = newCallout()
  local ticks = {}
  assertTrue(c:Countdown{ endsAt = 5, onTick = function(n) ticks[#ticks + 1] = n end })
  assertEqual(shown(c), "5")
  assertEqual(table.concat(ticks, ","), "5")
  local running, n = c:Running()
  assertTrue(running)
  assertEqual(n, 5)
  assertEqual(live(m), 1, "the OnUpdate is armed while the countdown runs")
end)

test("countdown: the number flips exactly when ceil(endsAt - now) changes", function()
  local c, m = newCallout()
  local ticks = {}
  m.__now = 100
  c:Countdown{ endsAt = 103, onTick = function(n) ticks[#ticks + 1] = n end }
  frameAt(m, 100.999)
  assertEqual(shown(c), "3", "0.001 s before the integer it is still 3")
  frameAt(m, 101.0)
  assertEqual(shown(c), "2", "on the integer it is 2")
  frameAt(m, 101.0001)
  frameAt(m, 101.5)
  assertEqual(table.concat(ticks, ","), "3,2", "each number is shown once, not once per frame")
  frameAt(m, 102.25)
  assertEqual(shown(c), "1")
  assertEqual(table.concat(ticks, ","), "3,2,1")
end)

test("countdown: a frame that skips past several integers shows the number now, once", function()
  local c, m = newCallout()
  local ticks = {}
  c:Countdown{ endsAt = 10, onTick = function(n) ticks[#ticks + 1] = n end }
  frameAt(m, 6.5)
  assertEqual(shown(c), "4")
  assertEqual(table.concat(ticks, ","), "10,4")
end)

test("countdown: nothing shows while the remainder is above `from`", function()
  local c, m = newCallout()
  c:Countdown{ endsAt = 10, from = 3 }
  assertNil(shown(c))
  assertNil(c:Stats().number)
  frameAt(m, 6.99)
  assertNil(shown(c), "4 is above from")
  frameAt(m, 7)
  assertEqual(shown(c), "3")
end)

test("countdown: from is clamped to 20, and a non-number endsAt is refused", function()
  local c = newCallout()
  assertFalse(c:Countdown{ endsAt = "soon" })
  assertFalse(c:Countdown{ endsAt = 0 / 0 })
  assertFalse(c:Countdown())
  c:Countdown{ endsAt = 30, from = 99 }
  assertNil(shown(c), "30 is above the clamped 20")
  c:Countdown{ endsAt = 20.5, from = 0 }
  assertEqual(c:Running(), true)
  assertNil(shown(c), "from 0 is clamped to 1")
end)

test("countdown: at zero the finish shows, onDone is called once, and the clock sleeps after the hold", function()
  local c, m = newCallout()
  local done = 0
  c:Countdown{ endsAt = 2, onDone = function() done = done + 1 end }
  frameAt(m, 2)
  assertEqual(shown(c), "GO!", "the default finish is GO")
  assertEqual(c:Stats().kind, "go")
  assertEqual(done, 1)
  assertFalse(c:Running())
  frameAt(m, 2.5)
  assertEqual(done, 1, "onDone is called once")
  local f = parts(c)
  local fade = rawget(f, "__groups")[1]
  assertEqual(fade.__plays, 0, "the finish holds")
  frameAt(m, 2 + c:Get("hold"))
  assertEqual(fade.__plays, 1, "then fades")
  assertEqual(live(m), 0, "nothing is armed once the countdown and the hold are over")
  fade:__finish()
  assertFalse(f:IsShown())
end)

test("countdown: a Show during the count is replaced by the next number, and its hold fades nothing", function()
  local c, m = newCallout()
  m.__now = 100
  c:Countdown{ endsAt = 110, from = 10 }
  frameAt(m, 101.2)
  assertEqual(shown(c), "9")
  c:Show("MOVE")
  assertEqual(shown(c), "MOVE", "it shows over the count")
  frameAt(m, 102.1)
  assertEqual(shown(c), "8", "the next number replaces it")
  frameAt(m, 102.8)                                -- past the Show's 1.5 s hold
  local fade = rawget(parts(c), "__groups")[1]
  assertEqual(fade.__plays, 0, "the Show's hold went with it: the number is not faded mid-count")
  assertEqual(shown(c), "8")
  assertEqual(c:Stats().text, "8")
  frameAt(m, 103.05)
  assertEqual(shown(c), "7")
end)

test("countdown: a held call-out fades on its own hold through a lead-in; the first number still shows", function()
  local c, m = newCallout()
  m.__now = 200
  c:Show("MOVE")
  assertTrue(c:Countdown{ endsAt = 230, from = 5 })
  assertEqual(shown(c), "MOVE", "nothing to count yet: the call-out stays for its hold")
  local fade = rawget(parts(c), "__groups")[1]
  frameAt(m, 200 + c:Get("hold") + 0.05)
  assertEqual(fade.__plays, 1, "its hold runs out and it fades")
  fade:__finish()
  frameAt(m, 215)
  assertNil(shown(c), "nothing stays up through the lead-in")
  assertTrue(c:Running())
  frameAt(m, 225.5)
  assertEqual(shown(c), "5", "the count starts at from")
end)

test("countdown: a finish's GO fades on its hold when onDone starts the next countdown's lead-in", function()
  local c, m = newCallout()
  c:Countdown{ endsAt = 1, onDone = function() c:Countdown{ endsAt = 60, from = 3 } end }
  frameAt(m, 1)
  assertEqual(shown(c), "GO!")
  assertTrue(c:Running(), "the next countdown runs")
  frameAt(m, 1 + c:Get("hold") + 0.05)
  assertEqual(rawget(parts(c), "__groups")[1].__plays, 1, "GO! does not wait for the next count")
end)

test("countdown: finish may be a stock key, a custom spec, or false for none", function()
  local c, m = newCallout()
  c:Countdown{ endsAt = 1, finish = "FINISH" }
  frameAt(m, 1)
  assertEqual(shown(c), "FINISH")
  c:Countdown{ endsAt = 2, finish = { text = "Pull now", kind = "warn" } }
  frameAt(m, 2)
  assertEqual(shown(c), "Pull now")
  assertEqual(c:Stats().kind, "warn")
  local done = false
  c:Countdown{ endsAt = 3, finish = false, onDone = function() done = true end }
  frameAt(m, 3)
  assertTrue(done)
  assertEqual(c:Stats().text, "1", "no finish: the last number fades out")
  assertEqual(live(m), 0)
end)

test("countdown: an endsAt already past finishes at the call", function()
  local c, m = newCallout()
  m.__now = 50
  local done = false
  c:Countdown{ endsAt = 49, onDone = function() done = true end }
  assertTrue(done)
  assertEqual(shown(c), "GO!")
end)

test("countdown: Cancel takes it down with no finish and no onDone, and disarms the clock", function()
  local c, m = newCallout()
  local done = false
  c:Countdown{ endsAt = 5, onDone = function() done = true end }
  assertTrue(c:Cancel())
  assertFalse(c:Running())
  assertNil(shown(c))
  assertEqual(live(m), 0)
  frameAt(m, 10)
  assertFalse(done)
  assertFalse(c:Cancel(), "nothing left to cancel")
end)

test("countdown: a new countdown replaces the running one", function()
  local c, m = newCallout()
  local firstDone = false
  c:Countdown{ endsAt = 3, onDone = function() firstDone = true end }
  c:Countdown{ endsAt = 9 }
  assertEqual(shown(c), "9")
  frameAt(m, 3)
  assertFalse(firstDone)
  assertEqual(shown(c), "6")
end)

test("countdown: a raising callback reaches the error handler and the countdown runs on", function()
  local c, m = newCallout()
  c:Countdown{ endsAt = 2, onTick = function() error("tick boom") end }
  assertEqual(#m.__errors, 1)
  assertTrue(tostring(m.__errors[1]):find("tick boom", 1, true) ~= nil)
  frameAt(m, 1)
  assertEqual(shown(c), "1")
end)

-- ── Show ─────────────────────────────────────────────────────────────────────────────────────

test("show: a stock key shows its text in its kind's color, and fades after the hold", function()
  local c, m = newCallout()
  assertTrue(c:Show("MOVE"))
  local _, text, halo = parts(c)
  assertEqual(text:GetText(), "MOVE")
  assertEqual(halo:GetText(), "MOVE", "the halo carries the same text")
  local r, g, b = c:GetColor("warn")
  local tr, tg, tb = text:GetTextColor()
  assertEqual(("%.2f %.2f %.2f"):format(tr, tg, tb), ("%.2f %.2f %.2f"):format(r, g, b))
  assertEqual(live(m), 1, "armed for the hold")
  frameAt(m, 1.49)
  assertEqual(rawget(parts(c), "__groups")[1].__plays, 0)
  frameAt(m, 1.5)
  assertEqual(rawget(parts(c), "__groups")[1].__plays, 1, "the fade starts at the hold")
  assertEqual(live(m), 0)
end)

test("show: a number, its string, and a custom text with its kind", function()
  local c = newCallout()
  assertTrue(c:Show(7))
  assertEqual(c:Stats().kind, "number")
  assertTrue(c:Show("12"))
  assertEqual(shown(c), "12")
  assertTrue(c:Show({ text = "Burn!", kind = "error" }))
  assertEqual(shown(c), "Burn!")
  assertEqual(c:Stats().kind, "error")
  assertTrue(c:Show({ text = "plain" }))
  assertEqual(c:Stats().kind, "info", "an unknown or missing kind is info")
end)

test("show: nothing to show is refused, and logged", function()
  local c, _, _, logs = newCallout()
  assertFalse(c:Show("NOPE"))
  assertFalse(c:Show(21))
  assertFalse(c:Show({ kind = "go" }))
  assertFalse(c:Show(nil))
  assertTrue(#logs >= 1)
  assertEqual(logs[1].tag, "CALLOUT")
end)

test("show: opts.hold and a spec's hold replace the setting's", function()
  local c, m = newCallout()
  c:Show("GO", { hold = 3 })
  frameAt(m, 2.9)
  assertEqual(live(m), 1)
  frameAt(m, 3)
  assertEqual(live(m), 0)
  c:Show({ text = "x", hold = 0.5 })
  frameAt(m, 3.5)
  assertEqual(live(m), 0)
end)

test("show: the player's own text for a stock key is shown in its place", function()
  local c = newCallout()
  assertTrue(c:Set("texts", { GO = "Allez!" }))
  c:Show("GO")
  assertEqual(shown(c), "Allez!")
  assertFalse(c:Set("texts", { NOT_A_KEY = "x" }), "only stock keys")
end)

test("show: the setting's animation plays, opts.anim overrides it, and none plays nothing", function()
  local c = newCallout()
  c:Show("GO")
  local f, _, halo, cf = parts(c)
  assertEqual(#rawget(f, "__groups"), 1, "the frame carries the fade alone")
  local groups = rawget(cf, "__groups")
  assertEqual(#groups, 1, "the slam plays on the content frame")
  local slam = groups[1]
  assertEqual(slam.__plays, 1)
  assertEqual(slam.__anims[1].__kind, "Scale")
  c:Show("GO", { anim = "pulse" })
  assertEqual(#rawget(cf, "__groups"), 2)
  assertEqual(rawget(cf, "__groups")[2].__plays, 1)
  c:Show("GO", { anim = "glow" })
  assertEqual(#rawget(halo, "__groups"), 1, "glow animates the halo")
  assertTrue(rawget(halo, "__groups")[1].__finalAlpha)
  c:Set("anim", "none")
  local before = #rawget(cf, "__groups")
  c:Show("GO")
  assertEqual(#rawget(cf, "__groups"), before, "none builds nothing")
  assertEqual(#rawget(f, "__groups"), 1, "and the frame still only fades")
end)

test("show: Hide takes it down now and disarms the clock", function()
  local c, m = newCallout()
  c:Show("GO")
  c:Hide()
  assertNil(shown(c))
  assertEqual(live(m), 0)
end)

-- ── the settings ─────────────────────────────────────────────────────────────────────────────

test("settings: Set writes into the host's table and Get reads it back", function()
  local c, _, db = newCallout()
  assertEqual(c:Get("size"), 96, "the default before any write")
  assertTrue(c:Set("size", 140))
  assertEqual(db.size, 140)
  assertEqual(c:Get("size"), 140)
  assertTrue(c:Set("voice", "male"))
  assertEqual(db.voice, "male")
  assertTrue(c:Set("size", nil))
  assertNil(db.size)
  assertEqual(c:Get("size"), 96)
end)

test("settings: an invalid value or an unknown key is refused and nothing is written", function()
  local c, _, db = newCallout()
  assertFalse(c:Set("size", 20))
  assertFalse(c:Set("size", 201))
  assertFalse(c:Set("outline", "THIN"))
  assertFalse(c:Set("voice", "robot"))
  assertFalse(c:Set("speakFrom", 2.5))
  assertFalse(c:Set("nope", 1))
  assertNil(next(db))
  assertNil(c:Get("nope"))
end)

test("settings: a stored value that is not valid reads as the default and is left alone", function()
  local c, _, db = newCallout()
  db.anim, db.size = "spin", "big"
  assertEqual(c:Get("anim"), "slam")
  assertEqual(c:Get("size"), 96)
  assertEqual(db.anim, "spin", "never rewritten")
end)

test("settings: a db getter is followed at every read (a profile switch)", function()
  local a, b = { size = 50 }, { size = 150 }
  local cur = a
  local c = newCallout({ db = function() return cur end })
  assertEqual(c:Get("size"), 50)
  cur = b
  assertEqual(c:Get("size"), 150)
  c:Set("glowThickness", 5)
  assertEqual(b.glowThickness, 5)
  assertNil(a.glowThickness)
end)

test("settings: Get hands out a copy, so the caller cannot change a table it holds", function()
  local c, _, db = newCallout()
  local pt = c:Get("point")
  pt[1] = "TOPLEFT"
  assertEqual(c:Get("point")[1], "CENTER")
  assertNil(db.point)
end)

test("settings: DEFAULTS seeds a profile with every key the instance reads", function()
  local _, Callout = env()
  for _, key in ipairs(Callout.SETTINGS) do
    assertTrue(Callout.DEFAULTS[key] ~= nil, key .. " has a default")
  end
  for _, kind in ipairs(Callout.KINDS) do
    assertTrue(Callout.DEFAULTS.colors[kind] ~= nil, kind .. " has a color")
  end
end)

test("settings: a kind's color is written as r, g, b and painted on the text", function()
  local c, _, db = newCallout()
  assertTrue(c:SetColor("go", 0.1, 0.2, 0.3))
  assertEqual(db.colors.go[3], 0.3)
  local r, g, b = c:GetColor("go")
  assertEqual(("%.1f %.1f %.1f"):format(r, g, b), "0.1 0.2 0.3")
  c:Show("GO")
  local _, text = parts(c)
  local tr = text:GetTextColor()
  assertEqual(tr, 0.1)
  assertFalse(c:SetColor("pink", 1, 1, 1))
  assertFalse(c:SetColor("go", "red"))
  assertTrue(c:SetColor("go"))
  assertNil(db.colors.go)
end)

test("settings: the look reaches the text: face, size, outline and shadow", function()
  local c = newCallout()
  c:Set("font", "Game default")
  c:Set("size", 120)
  c:Set("outline", "NONE")
  c:Set("shadowX", 3)
  local f, text, halo = parts(c)
  local path, size, flags = text:GetFont()
  assertEqual(path, "Fonts\\FRIZQT__.TTF")
  assertEqual(size, 120)
  assertEqual(flags, "")
  assertEqual(select(1, text:GetShadowOffset()), 3)
  assertEqual(select(3, halo:GetFont()), "THICKOUTLINE", "the halo is always thick")
  assertEqual(rawget(f, "__h"), 180, "the frame is 1.5 x the size high")
  c:Set("shadow", false)
  assertEqual(select(1, text:GetShadowOffset()), 0)
  c:Set("glow", false)
  assertEqual(halo:GetAlpha(), 0)
end)

test("settings: a face name nothing resolves falls back to the game's", function()
  local c = newCallout({ addon = false })
  c:Set("font", "No Such Face")
  local _, text = parts(c)
  assertEqual((text:GetFont()), "Fonts\\FRIZQT__.TTF")
end)

-- ── the position ─────────────────────────────────────────────────────────────────────────────

test("position: the frame sits at the saved point, a drag writes it, and Reset forgets it", function()
  local c, m, db = newCallout()
  local f = parts(c)
  local p = rawget(f, "__point")
  assertEqual(p[1], "CENTER")
  assertEqual(p[2], m.UIParent)
  assertEqual(p[5], 180)
  c:SetLocked(false)
  assertTrue(rawget(f, "__mouse"), "unlocked, it takes the mouse")
  assertEqual(shown(c), "READY", "and shows a sample to place")
  f:__fire("OnDragStart")
  assertTrue(rawget(f, "__moving"))
  f:SetPoint("TOPLEFT", m.UIParent, "TOPLEFT", 40, -60)
  f:__fire("OnDragStop")
  assertEqual(db.point[1], "TOPLEFT")
  assertEqual(db.point[4], -60)
  c:SetLocked(true)
  assertFalse(rawget(f, "__mouse"))
  assertNil(shown(c), "the sample goes when it locks")
  c:ResetPosition()
  assertNil(db.point)
  assertEqual(rawget(f, "__point")[1], "CENTER")
end)

test("position: a locked frame does not move on a drag", function()
  local c = newCallout()
  local f = parts(c)
  f:__fire("OnDragStart")
  assertFalse(rawget(f, "__moving") == true)
end)

-- ── the sound ────────────────────────────────────────────────────────────────────────────────

test("sound: a stock key plays its pack line on the chosen channel", function()
  local c, m = newCallout()
  c:Show("NEW_BEST")
  assertEqual(#m.__files, 1)
  assertEqual(m.__files[1].file, PACK_DIR .. "female-kathleen\\new_best.ogg")
  assertEqual(m.__files[1].channel, "Master")
  c:Set("voice", "male")
  c:Set("channel", "Dialog")
  c:Show("GO")
  assertEqual(m.__files[2].file, PACK_DIR .. "male-joe\\go.ogg")
  assertEqual(m.__files[2].channel, "Dialog")
end)

test("sound: soundsBase and vendorPath move where the packs are found", function()
  local c, m = newCallout({ vendorPath = "lib\\Ka0s" })
  c:Show("GO")
  assertEqual(m.__files[1].file, "Interface\\AddOns\\TestAddon\\lib\\Ka0s\\media\\sounds\\callout\\female-kathleen\\go.ogg")
  local c2, m2 = newCallout({ soundsBase = "Interface\\AddOns\\Mine\\voices" })
  c2:Show("GO")
  assertEqual(m2.__files[1].file, "Interface\\AddOns\\Mine\\voices\\female-kathleen\\go.ogg")
end)

test("sound: a countdown speaks only from speakFrom down", function()
  local c, m = newCallout()
  c:Countdown{ endsAt = 7 }
  frameAt(m, 1)
  assertEqual(#m.__files, 0, "7 and 6 are shown, not spoken")
  frameAt(m, 2)
  assertEqual(#m.__files, 1)
  assertEqual(m.__files[1].file, PACK_DIR .. "female-kathleen\\5.ogg")
  frameAt(m, 7)
  assertEqual(m.__files[#m.__files].file, PACK_DIR .. "female-kathleen\\go.ogg")
end)

test("sound: a missing file falls back to silence, logged once", function()
  local c, m, _, logs = newCallout()
  m.__missing[PACK_DIR .. "female-kathleen\\go.ogg"] = true
  assertTrue(c:Show("GO"), "the call-out still shows")
  assertTrue(c:Show("GO"))
  local n = 0
  for _, l in ipairs(logs) do
    if l.msg:find("go.ogg", 1, true) then n = n + 1 end
  end
  assertEqual(n, 1, "logged once")
  assertEqual(#m.__errors, 0)
  assertEqual(shown(c), "GO!")
end)

test("sound: no addon and no soundsBase is silence, logged once", function()
  local c, m, _, logs = newCallout({ addon = false })
  c:Show("GO")
  c:Show("STOP")
  assertEqual(#m.__files, 0)
  assertEqual(#logs, 1)
end)

test("sound: voice off, a spec's voice = false and opts.voice = false are silent", function()
  local c, m = newCallout()
  c:Show("GO", { voice = false })
  c:Show({ text = "x", sound = "Interface\\x.ogg", voice = false })
  c:Set("voice", "off")
  c:Show("GO")
  c:Show({ text = "y", sound = "Interface\\y.ogg" })
  assertEqual(#m.__files, 0)
end)

test("sound: a custom text plays its own file; with none it is silent on a pack", function()
  local c, m = newCallout()
  c:Show({ text = "Hi", sound = "Interface\\AddOns\\Host\\hi.ogg" })
  assertEqual(m.__files[1].file, "Interface\\AddOns\\Host\\hi.ogg")
  c:Show({ text = "Quiet" })
  assertEqual(#m.__files, 1)
end)

test("sound: text to speech speaks with the chosen voice, else the client's first", function()
  local c, m = newCallout(nil, function(mm)
    tts(mm, { { voiceID = 3, name = "Zira" }, { voiceID = 7, name = "David" } })
  end)
  c:Set("voice", "tts")
  c:Show("NEW_BEST")
  assertEqual(m.__spoken[1].text, "New best")
  assertEqual(m.__spoken[1].id, 3, "no choice: the first voice")
  assertEqual(m.__spoken[1].volume, 100)
  assertTrue(m.__spoken[1].overlap)
  c:Set("ttsVoice", 7)
  c:Show({ text = "Custom words" })
  assertEqual(m.__spoken[2].id, 7)
  assertEqual(m.__spoken[2].text, "Custom words", "a custom text with no sound is spoken")
  c:Set("ttsVoice", 99)
  c:Show("GO")
  assertEqual(m.__spoken[3].id, 3, "a voice the client no longer has: the first")
  assertEqual(#m.__files, 0)
  local voices = c:TtsVoices()
  assertEqual(#voices, 2)
  assertEqual(voices[2].name, "David")
end)

test("sound: text to speech without C_VoiceChat or without a voice is silent, logged once", function()
  local c, m, _, logs = newCallout()
  c:Set("voice", "tts")
  c:Show("GO")
  c:Show("GO")
  assertEqual(#logs, 1)
  assertEqual(#c:TtsVoices(), 0)
  local c2, m2, _, logs2 = newCallout(nil, function(mm) tts(mm, {}) end)
  c2:Set("voice", "tts")
  c2:Show("GO")
  assertEqual(#m2.__spoken, 0)
  assertEqual(#logs2, 1)
  assertEqual(#m.__errors + #m2.__errors, 0)
end)

test("sound: Voices lists the packs, then text to speech and off", function()
  local c = newCallout()
  local keys = {}
  for i, v in ipairs(c:Voices()) do keys[i] = v.key end
  assertEqual(table.concat(keys, ","), "female,male,tts,off")
end)

-- ── the stand-down ───────────────────────────────────────────────────────────────────────────

test("suspend: the countdown stops with no onDone, everything goes, and Show is refused until Resume", function()
  local c, m = newCallout()
  local done = false
  c:Countdown{ endsAt = 3, onDone = function() done = true end }
  c:SetLocked(false)
  c:Suspend()
  assertTrue(c:Suspended())
  assertTrue(c:Locked())
  assertFalse(c:Running())
  assertNil(shown(c))
  assertEqual(live(m), 0, "nothing is armed after the stand-down")
  frameAt(m, 5)
  assertFalse(done)
  assertFalse(c:Show("GO"))
  assertFalse(c:Countdown{ endsAt = 9 })
  c:Resume()
  assertFalse(c:Suspended())
  assertTrue(c:Show("GO"))
end)

test("suspend: Stats reports the state a host's diagnostics prints", function()
  local c = newCallout()
  c:Countdown{ endsAt = 4 }
  local s = c:Stats()
  assertTrue(s.built)
  assertTrue(s.shown)
  assertTrue(s.running)
  assertEqual(s.number, 4)
  assertEqual(s.endsAt, 4)
  assertTrue(s.awake)
  assertFalse(s.suspended)
end)
