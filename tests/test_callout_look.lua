-- tests/test_callout_look.lua — LibKa0s-Callout-1.0's look, in depth (plan row L6): each animation as
-- the setting picks it, the outline, shadow and glow reaching both FontStrings, every kind's color,
-- and the saved position with unlock-to-move over a stand-in drag strip.
--
-- The bench is tests/fixture_callout.lua's (recording AnimationGroups, the kit's paint recorder, the
-- settable clock). test_callout.lua holds the contract's first pass; this file holds the depth.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local F = dofile("tests/fixture_callout.lua")
local newCallout, parts, frameAt = F.newCallout, F.parts, F.frameAt

local function groups(region) return rawget(region, "__groups") or {} end

local function rgb(r, g, b) return ("%.2f %.2f %.2f"):format(r, g, b) end

local function shown(c)
  local f, text = parts(c)
  if not f:IsShown() then return nil end
  return text:GetText()
end

-- A stand-in LibKa0s-Widgets-1.0 whose DragHandle builds a real (mock) frame and records its spec.
local function withHandle(m)
  local W = m.LibStub:NewLibrary("LibKa0s-Widgets-1.0", 999)
  m.__handles = {}
  W.DragHandle = function(frame, spec)
    local h = m.CreateFrame("Frame", nil, frame)
    rawset(h, "__spec", spec)
    rawset(h, "ApplyWidth", function(self) rawset(self, "__widthApplied", true) end)
    m.__handles[#m.__handles + 1] = h
    return h
  end
end

-- ── the animations ───────────────────────────────────────────────────────────────────────────

test("look: each animation is the setting's, built once from its own steps", function()
  local c = newCallout()
  local _, _, halo, cf = parts(c)
  local want = {
    slam  = { "Scale", "Alpha" },
    pulse = { "Scale", "Scale" },
    blink = { "Alpha", "Alpha", "Alpha", "Alpha" },
    shake = { "Translation", "Translation", "Translation", "Translation" },
  }
  local seen = 0                                   -- the content frame carries only the animations
  for _, name in ipairs({ "slam", "pulse", "blink", "shake" }) do
    assertTrue(c:Set("anim", name))
    c:Show("GO")
    seen = seen + 1
    local list = groups(cf)
    assertEqual(#list, seen, name .. " builds one group on the content frame")
    local ag = list[seen]
    assertEqual(ag.__plays, 1, name .. " plays")
    local kinds = {}
    for i, a in ipairs(ag.__anims) do kinds[i] = a.__kind end
    assertEqual(table.concat(kinds, ","), table.concat(want[name], ","), name .. "'s steps")
    c:Show("GO")
    assertEqual(#groups(cf), seen, name .. " is built once and reused")
    assertEqual(ag.__plays, 2, name .. " plays again on the next call-out")
  end
  assertEqual(#groups(halo), 0, "no frame animation is built on the halo")
end)

test("look: slam lands from 2.2x and fades in; pulse swells and settles; shake runs out and back", function()
  local c = newCallout()
  local _, _, _, cf = parts(c)
  c:Show("GO")
  local slam = groups(cf)[1].__anims
  assertEqual(slam[1].__scaleFrom[1], 2.2)
  assertEqual(slam[1].__scaleTo[1], 1)
  assertEqual(slam[1].__smoothing, "OUT")
  assertEqual(slam[2].__fromAlpha, 0)
  assertEqual(slam[2].__toAlpha, 1)
  assertEqual(slam[1].__order, slam[2].__order, "the scale and the fade-in run together")
  c:Show("GO", { anim = "pulse" })
  local pulse = groups(cf)[2].__anims
  assertEqual(pulse[1].__scaleTo[1], pulse[2].__scaleFrom[1], "the swell's peak is where it settles from")
  assertEqual(pulse[2].__scaleTo[1], 1)
  assertTrue(pulse[2].__order > pulse[1].__order, "one after the other")
  c:Show("GO", { anim = "shake" })
  local sum, orders = 0, {}
  for i, a in ipairs(groups(cf)[3].__anims) do
    sum = sum + a.__offset[1]
    orders[i] = a.__order
  end
  assertEqual(sum, 0, "the shake ends where it began")
  assertEqual(table.concat(orders, ","), "1,2,3,4")
end)

test("look: blink dims twice; glow flashes the halo and leaves it at its final alpha", function()
  local c = newCallout()
  local _, _, halo, cf = parts(c)
  c:Show("GO", { anim = "blink" })
  local blink = groups(cf)[1].__anims
  assertEqual(#blink, 4)
  assertEqual(blink[1].__toAlpha, blink[3].__toAlpha)
  assertEqual(blink[4].__toAlpha, 1, "the text ends fully drawn")
  c:Show("GO", { anim = "glow" })
  local glow = groups(halo)[1]
  assertEqual(glow.__plays, 1)
  assertTrue(glow.__finalAlpha, "SetToFinalAlpha, so the halo does not snap back")
  assertEqual(glow.__anims[1].__fromAlpha, 1)
  assertEqual(glow.__anims[1].__toAlpha, 0)
  assertEqual(#groups(cf), 1, "glow adds nothing to the content frame")
end)

test("look: a new call-out stops the last one's animation; an unknown opts.anim is the setting's", function()
  local c = newCallout()
  local _, _, _, cf = parts(c)
  c:Show("GO")
  local slam = groups(cf)[1]
  local stops = slam.__stops
  c:Show("STOP")
  assertTrue(slam.__stops > stops, "the running group is stopped before the next plays")
  assertEqual(slam.__plays, 2)
  c:Show("GO", { anim = "spin" })
  assertEqual(#groups(cf), 1, "no group for an unknown name")
  assertEqual(slam.__plays, 3, "the setting's slam plays")
  c:Set("anim", "none")
  c:Show("GO", { anim = "pulse" })
  assertEqual(#groups(cf), 2, "opts.anim wins over none")
end)

test("look: a countdown's every number animates, and the fade waits for the finish's hold", function()
  local c, m = newCallout()
  local f, _, _, cf = parts(c)
  c:Countdown{ endsAt = 3 }
  local slam = groups(cf)[1]
  assertEqual(slam.__plays, 1)
  frameAt(m, 1)
  frameAt(m, 2)
  assertEqual(slam.__plays, 3, "3, 2 and 1 each slam")
  frameAt(m, 3)
  assertEqual(slam.__plays, 4, "and so does GO!")
  assertEqual(groups(f)[1].__plays, 0, "no fade while it holds")
end)

-- ── outline, shadow and glow ─────────────────────────────────────────────────────────────────

test("look: every outline reaches the text as its flags; the halo is always thick", function()
  local c, _, _, _, Callout = newCallout()
  local _, text, halo = parts(c)
  for _, o in ipairs(Callout.OUTLINES) do
    assertTrue(c:Set("outline", o))
    assertEqual(select(3, text:GetFont()), o == "NONE" and "" or o, o .. " on the text")
    assertEqual(select(3, halo:GetFont()), "THICKOUTLINE", o .. ": the halo")
    assertEqual(c:Look().flags, o == "NONE" and "" or o, o .. " in Look")
  end
end)

test("look: the shadow is on by default at (1, 1), follows its offsets, and off is no shadow at all", function()
  local c = newCallout()
  local _, text = parts(c)
  local x, y = text:GetShadowOffset()
  assertEqual(x .. "," .. y, "1,1", "the owner's 1 px (Callout minor 4)")
  assertEqual(select(4, text:GetShadowColor()), 1, "an opaque black shadow")
  c:Set("shadowX", -5)
  c:Set("shadowY", 7)
  x, y = text:GetShadowOffset()
  assertEqual(x .. "," .. y, "-5,7", "a write applies at once")
  c:Set("shadow", false)
  x, y = text:GetShadowOffset()
  assertEqual(x .. "," .. y, "0,0")
  assertEqual(select(4, text:GetShadowColor()), 0, "and transparent")
  assertFalse(c:Set("shadowX", 21), "offsets are -20 to 20")
end)

test("look: the glow is the halo's alpha (its intensity) and its size over the text (its thickness)", function()
  local c = newCallout()
  local _, text, halo = parts(c)
  assertEqual(halo:GetAlpha(), 1, "on by default, at full intensity (Callout minor 4)")
  assertEqual(select(2, halo:GetFont()), 98, "and 1 px out on every side: 96 + 2")
  c:Set("glowIntensity", 0.7)
  c:Set("glowThickness", 5)
  assertEqual(halo:GetAlpha(), 0.7)
  assertEqual(select(2, halo:GetFont()), 106, "the old strong look's size at 96")
  assertEqual(select(2, text:GetFont()), 96, "the text keeps its size")
  c:Set("glow", false)
  assertEqual(halo:GetAlpha(), 0, "off is no glow")
  c:Set("glow", true)
  c:Set("size", 50)
  assertEqual(select(2, halo:GetFont()), 60, "the halo follows the size, thickness px out")
end)

test("look: the size sets the frame's height, its width is WIDTH", function()
  local c, _, _, _, Callout = newCallout()
  local f = parts(c)
  for _, size in ipairs({ 32, 75, 200 }) do
    c:Set("size", size)
    assertEqual(rawget(f, "__w"), Callout.WIDTH)
    assertEqual(rawget(f, "__h"), math.floor(size * 1.5 + 0.5), size .. ": 1.5 x the size")
  end
end)

-- A stand-in LibSharedMedia-3.0 holding one face.
local function withLSM(m)
  local LSM = m.LibStub:NewLibrary("LibSharedMedia-3.0", 1)
  LSM.Fetch = function(_, kind, name)
    if kind == "font" and name == "Big Face" then return "Interface\\AddOns\\Faces\\big.ttf" end
    return nil
  end
  LSM.List = function() return { "Big Face" } end
end

test("look: a LibSharedMedia face is drawn by its path; the skin and game choices are the game's here", function()
  local c = newCallout(nil, withLSM)
  local _, text = parts(c)
  assertTrue(c:Set("font", "Big Face"))
  assertEqual((text:GetFont()), "Interface\\AddOns\\Faces\\big.ttf")
  assertEqual(c:Look().font, "Interface\\AddOns\\Faces\\big.ttf")
  c:Set("font", "Skin font")
  assertEqual((text:GetFont()), "Fonts\\FRIZQT__.TTF", "no skin registered: the game's face")
  c:Set("font", "Game default")
  assertEqual((text:GetFont()), "Fonts\\FRIZQT__.TTF")
  assertFalse(c:Set("font", ""), "a face is a non-empty name")
end)

test("look: a face the client cannot load is replaced by the game's at the same size and flags", function()
  local c = newCallout(nil, withLSM)
  local _, text = parts(c)
  local setFont = text.SetFont
  rawset(text, "SetFont", function(self, path, size, flags)
    if path ~= "Fonts\\FRIZQT__.TTF" then return false end
    return setFont(self, path, size, flags)
  end)
  c:Set("font", "Big Face")
  c:Set("size", 80)
  local path, size, flags = text:GetFont()
  assertEqual(path, "Fonts\\FRIZQT__.TTF")
  assertEqual(size, 80)
  assertEqual(flags, "THICKOUTLINE")
end)

-- ── the colors ───────────────────────────────────────────────────────────────────────────────

test("colors: every stock key paints its kind's default on the text and the halo", function()
  local c, _, db, _, Callout = newCallout()
  local _, text, halo = parts(c)
  db.glowCustom = false   -- the default glow is the swatch's black (minor 4); off, the kind's color
  for _, key in ipairs(Callout.STOCK_ORDER) do
    c:Show(key)
    local d = Callout.DEFAULTS.colors[Callout.STOCK[key].kind]
    assertEqual(rgb(text:GetTextColor()), rgb(d[1], d[2], d[3]), key .. "'s text")
    assertEqual(rgb(halo:GetTextColor()), rgb(d[1], d[2], d[3]), key .. "'s halo")
  end
  c:Show(3)
  assertEqual(rgb(text:GetTextColor()), "1.00 1.00 1.00", "a number is white")
end)

test("colors: each kind is the player's own, set alone, and a custom text takes its kind's", function()
  local c, _, db, _, Callout = newCallout()
  local _, text = parts(c)
  for i, kind in ipairs(Callout.KINDS) do
    assertTrue(c:SetColor(kind, i / 10, 0, 1))
  end
  for i, kind in ipairs(Callout.KINDS) do
    assertEqual(rgb(c:GetColor(kind)), rgb(i / 10, 0, 1), kind .. " keeps its own")
  end
  c:Show({ text = "Burn", kind = "error" })
  assertEqual(rgb(text:GetTextColor()), rgb(0.6, 0, 1))
  c:SetColor("error")
  assertNil(db.colors.error)
  assertEqual(rgb(c:GetColor("warn")), rgb(0.5, 0, 1), "clearing one leaves the rest")
end)

test("colors: a write repaints the call-out on screen; a broken stored color reads as the default", function()
  local c, _, db, _, Callout = newCallout()
  local _, text = parts(c)
  c:Show("STOP")
  c:SetColor("stop", 0, 0, 0)
  assertEqual(rgb(text:GetTextColor()), "0.00 0.00 0.00", "the shown call-out takes it at once")
  db.colors.stop = { "red" }
  local d = Callout.DEFAULTS.colors.stop
  assertEqual(rgb(c:GetColor("stop")), rgb(d[1], d[2], d[3]))
  db.colors = "nope"
  assertEqual(rgb(c:GetColor("go")), rgb(Callout.DEFAULTS.colors.go[1], Callout.DEFAULTS.colors.go[2], Callout.DEFAULTS.colors.go[3]))
  assertTrue(c:SetColor("go", 1, 1, 0), "a non-table colors is replaced on write")
  assertEqual(type(db.colors), "table")
  assertEqual(rgb(c:GetColor("pink")), rgb(c:GetColor("info")), "an unknown kind reads as info")
end)

-- ── the position ─────────────────────────────────────────────────────────────────────────────

test("position: a point stored before the frame is built is where it first appears", function()
  local c, m, db = newCallout()
  db.point = { "TOP", "TOP", 10, -40 }
  local p = rawget(parts(c), "__point")
  assertEqual(p[1], "TOP")
  assertEqual(p[2], m.UIParent)
  assertEqual(p[3], "TOP")
  assertEqual(p[4] .. "," .. p[5], "10,-40")
end)

test("position: Set moves the frame now; a broken point is refused, and a stored one reads as the default", function()
  local c, _, db = newCallout()
  local f = parts(c)
  assertTrue(c:Set("point", { "BOTTOMLEFT", "BOTTOMLEFT", 5, 6 }))
  assertEqual(rawget(f, "__point")[1], "BOTTOMLEFT")
  assertFalse(c:Set("point", { 1, 2 }))
  assertFalse(c:Set("point", { "TOP", "TOP", 0 / 0, 0 }))
  db.point = "middle"
  c:Apply()
  assertEqual(rawget(f, "__point")[1], "CENTER", "the default")
  assertEqual(rawget(f, "__point")[5], 180)
  db.point = { "LEFT" }
  c:Apply()
  local p = rawget(f, "__point")
  assertEqual(p[3] .. "," .. p[4] .. "," .. p[5], "LEFT,0,0", "a bare point is its own relative point at 0, 0")
end)

test("position: a drag that ends without a relative point saves the point twice and finite offsets", function()
  local c, _, db = newCallout()
  local f = parts(c)
  c:SetLocked(false)
  f:__fire("OnDragStart")
  rawset(f, "GetPoint", function() return "RIGHT", nil, nil, 0 / 0, 12 end)
  f:__fire("OnDragStop")
  assertFalse(rawget(f, "__moving"))
  assertEqual(table.concat({ db.point[1], db.point[2], db.point[3], db.point[4] }, ","), "RIGHT,RIGHT,0,12")
end)

test("unlock: the drag strip is built over the frame, hidden while locked, shown unlocked", function()
  local c, m = newCallout({ skin = "TestSkin" }, withHandle)
  local f = parts(c)
  assertEqual(#m.__handles, 1, "one strip, built with the frame")
  local h = m.__handles[1]
  local spec = rawget(h, "__spec")
  assertEqual(spec.label, "Call-out", "the default label")
  assertEqual(spec.moveFrame, f)
  assertTrue(spec.ignoreParentAlpha, "the strip does not take the frame's alpha (frame-layering-§2)")
  assertEqual(spec.level, 10, "and sits over the frame's level")
  assertEqual(spec.owner, "TestSkin", "the strip is in the host's skin")
  assertTrue(rawget(h, "__widthApplied"))
  local p = rawget(h, "__point")
  assertEqual(p[1] .. "," .. p[3], "BOTTOM,TOP", "it sits on top of the frame")
  assertFalse(h:IsShown())
  assertFalse(spec.canDrag(), "a locked frame does not drag")
  c:SetLocked(false)
  assertTrue(h:IsShown())
  assertTrue(spec.canDrag())
  c:SetLocked(true)
  assertFalse(h:IsShown())
end)

test("unlock: the strip's own drag saves the point; d.label names it", function()
  local c, m, db = newCallout({ label = "Race countdown" }, withHandle)
  local f = parts(c)
  local spec = rawget(m.__handles[1], "__spec")
  assertEqual(spec.label, "Race countdown")
  c:SetLocked(false)
  f:SetPoint("TOP", m.UIParent, "TOP", 0, -100)
  spec.onDragStop()
  assertEqual(db.point[1], "TOP")
  assertEqual(db.point[4], -100)
end)

test("unlock: locking mid-drag ends the move and saves the point", function()
  local c, m, db = newCallout()
  local f = parts(c)
  c:SetLocked(false)
  f:__fire("OnDragStart")
  assertTrue(rawget(f, "__moving"))
  f:SetPoint("TOPLEFT", m.UIParent, "TOPLEFT", 40, -60)
  c:SetLocked(true)
  assertFalse(rawget(f, "__moving"), "the mouse-up never comes once the frame stops taking the mouse")
  assertEqual(table.concat({ db.point[1], db.point[2], db.point[3], db.point[4] }, ","), "TOPLEFT,TOPLEFT,40,-60")
end)

test("unlock: a Suspend mid-drag on the strip ends the move and saves the point", function()
  local c, m, db = newCallout(nil, withHandle)
  local f = parts(c)
  c:SetLocked(false)
  local spec = rawget(m.__handles[1], "__spec")
  f:StartMoving()                                  -- what the strip's own OnDragStart does
  spec.onDragStart()
  f:SetPoint("BOTTOM", m.UIParent, "BOTTOM", 0, 80)
  c:Suspend()
  assertFalse(rawget(f, "__moving"))
  assertEqual(db.point[1], "BOTTOM")
  assertEqual(db.point[4], 80)
end)

test("unlock: a lock with no drag running leaves the point alone", function()
  local c, _, db = newCallout()
  c:SetLocked(false)
  c:SetLocked(true)
  assertNil(db.point)
end)

test("position: a stored anchor that is not a region point reads as the default", function()
  local c, _, db = newCallout()
  db.point = { "MIDDLE", "CENTER", 5, 5 }
  local f = parts(c)
  local p = rawget(f, "__point")
  assertEqual(p[1] .. "," .. p[3] .. "," .. p[5], "CENTER,CENTER,180", "built at the default")
  db.point = { "TOP", "UPPER", 0, 0 }
  c:Apply()
  assertEqual(rawget(f, "__point")[1], "CENTER", "a bad relative point is the default too")
  assertEqual(c:Get("point")[1], "CENTER")
  assertFalse(c:Set("point", { "MIDDLE" }), "never written")
  assertTrue(c:Set("point", { "BOTTOMRIGHT", "BOTTOMRIGHT", -10, 10 }))
  assertEqual(rawget(f, "__point")[1], "BOTTOMRIGHT")
end)

test("unlock: without Widgets there is no strip, and the frame drags itself", function()
  local c, m, db = newCallout()
  local f = parts(c)
  c:SetLocked(false)
  f:__fire("OnDragStart")
  assertTrue(rawget(f, "__moving"))
  f:SetPoint("LEFT", m.UIParent, "LEFT", 30, 0)
  f:__fire("OnDragStop")
  assertEqual(db.point[1], "LEFT")
end)

test("unlock: unlocking builds the frame; the sample is silent and stays past any hold", function()
  local c, m = newCallout()
  assertFalse(c:Stats().built)
  c:SetLocked(false)
  assertTrue(c:Stats().built)
  assertEqual(shown(c), "READY")
  assertEqual(#m.__files, 0, "the sample says nothing")
  frameAt(m, 60)
  assertEqual(shown(c), "READY", "it waits to be placed")
  c:Show("GO")
  frameAt(m, 120)
  assertEqual(groups(parts(c))[1].__plays, 0, "unlocked, a call-out does not fade")
  assertEqual(shown(c), "GO!")
  c:SetLocked(true)
  assertNil(shown(c))
end)

test("unlock: the lock is never written into the host's db, and SetLocked twice is one change", function()
  local c, _, db = newCallout()
  c:SetLocked(false)
  c:SetLocked(false)
  assertFalse(c:Locked())
  assertNil(next(db))
  c:SetLocked()
  assertTrue(c:Locked(), "no argument locks")
end)

test("unlock: locking during a countdown leaves the countdown on screen", function()
  local c, m = newCallout()
  c:SetLocked(false)
  c:Countdown{ endsAt = 5 }
  c:SetLocked(true)
  assertEqual(shown(c), "5")
  frameAt(m, 1)
  assertEqual(shown(c), "4")
end)
