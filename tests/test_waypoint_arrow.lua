-- tests/test_waypoint_arrow.lua — LibKa0s-WaypointArrow-1.0, the waypoint arrow (Skill Master round 8, L1).
--
-- The bench is tests/fixture_waypoint_arrow.lua: a fresh environment per case, the kit's paint
-- recorder (so the three textures are distinct), and a faked world: the player's place and facing
-- and a map's place are fields the case sets.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil, assertError =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil, T.assertError
local Loader = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local F = dofile("tests/fixture_waypoint_arrow.lua")
local MAJOR, MEDIA = F.MAJOR, F.MEDIA
local newArrow, parts, tick = F.newArrow, F.parts, F.tick

local PI = math.pi

local function near(a, b, eps) return type(a) == "number" and math.abs(a - b) <= (eps or 1e-9) end

local function assertNear(a, b, msg, eps)
  assertTrue(near(a, b, eps), (msg or "") .. ": expected " .. tostring(b) .. ", got " .. tostring(a))
end

local function vertex(tex)
  local r, g, b = tex:GetVertexColor()
  return { r, g, b }
end

-- ── load and construction ────────────────────────────────────────────────────────────────────

test("arrow: the major loads at minor 2 and reports its two files", function()
  local _, Arrow = F.env()
  assertEqual(Arrow.MAJOR, MAJOR)
  assertEqual(Arrow.MINOR, 2)
  assertEqual(Arrow.MODULES.WaypointArrow, 2)
  assertEqual(Arrow.MODULES.WaypointArrowSettings, 2)
  assertEqual(T.arrow, T.mocks.LibStub(MAJOR), "the runner's whole-payload load carries it too")
end)

test("arrow: without Core the major is absent (no NewLibrary)", function()
  local m = buildMocks()
  Loader.load("LibKa0s/WaypointArrow.lua", nil, m)
  assertNil(m.LibStub(MAJOR, true))
end)

test("arrow: New refuses a descriptor that does not say where the art sits", function()
  local _, Arrow = F.env()
  local err = assertError(function() Arrow:New({}) end)
  assertTrue(err:find("d.addon", 1, true) ~= nil, "names d.addon; got: " .. err)
  assertError(function() Arrow:New(nil) end)
  Arrow:New({ mediaBase = "Interface\\AddOns\\X\\art" })   -- a base is enough
end)

test("arrow: a method called on something that is not an instance raises", function()
  local a = newArrow()
  local err = assertError(function() a.Clear({}) end)
  assertTrue(err:find("WaypointArrow:New", 1, true) ~= nil, "says where an instance comes from; got: " .. err)
end)

test("arrow: nothing is built or armed before a target", function()
  local a = newArrow()
  local s = a:Stats()
  assertFalse(s.built)
  assertFalse(s.shown)
  assertEqual(s.style, "raised", "Raised is the default look")
end)

-- ── the rotation math ────────────────────────────────────────────────────────────────────────

test("arrow: Rotation is the bearing (x north, y west) less the facing, counter-clockwise", function()
  local _, Arrow = F.env()
  local R = Arrow.Rotation
  assertNear(R(0, 0, 100, 0, 0), 0, "due north, facing north: straight ahead")
  assertNear(R(0, 0, 0, 100, 0), PI / 2, "due west, facing north: a quarter turn left")
  assertNear(R(0, 0, 0, -100, 0), -PI / 2, "due east: a quarter turn right")
  assertNear(R(0, 0, 100, 0, PI / 2), -PI / 2, "facing west, the target north is to the right")
  assertNear(R(0, 0, -100, 0, 0), PI, "behind folds to +pi, never -pi")
  assertNear(R(10, 20, 110, 20, 0), 0, "only the difference counts")
end)

test("arrow: Rotation folds every answer into -pi .. pi", function()
  local _, Arrow = F.env()
  for _, f in ipairs({ -7, -3.5, 0.3, 4, 9.9, 2 * PI }) do
    local r = Arrow.Rotation(0, 0, 50, 70, f)
    assertTrue(r > -PI - 1e-12 and r <= PI + 1e-12, "facing " .. f .. " gave " .. tostring(r))
    local want = math.atan2(70, 50) - f
    assertNear(math.cos(r), math.cos(want), "same direction (cos)")
    assertNear(math.sin(r), math.sin(want), "same direction (sin)")
  end
end)

test("arrow: Rotation answers nil for anything that is not a plain number, a secret included", function()
  local _, Arrow = F.env(function(m)
    m.issecretvalue = function(v) return v == 42 end
  end)
  assertNil(Arrow.Rotation(nil, 0, 1, 1, 0))
  assertNil(Arrow.Rotation(0, 0, 1, 1, nil))
  assertNil(Arrow.Rotation(0, 0, 1, 1, 0 / 0), "NaN")
  assertNil(Arrow.Rotation(0, 0, 1, 1, 42), "a secret facing")
  assertNil(Arrow.Rotation("0", 0, 1, 1, 0))
end)

test("arrow: Distance, Fade and Mix", function()
  local _, Arrow = F.env()
  assertNear(Arrow.Distance(0, 0, 30, 40), 50, "a 3-4-5 triangle")
  assertNil(Arrow.Distance(0, nil, 1, 1))
  assertEqual(Arrow.Fade(10), 0, "near or closer: the near color")
  assertEqual(Arrow.Fade(30), 0)
  assertEqual(Arrow.Fade(300), 1, "far or more: the far color")
  assertEqual(Arrow.Fade(5000), 1)
  assertNear(Arrow.Fade(165), 0.5, "halfway")
  assertEqual(Arrow.Fade(nil), 1, "no distance draws the far color")
  assertNear(Arrow.Fade(15, 10, 20), 0.5, "custom edges")
  local r, g, b = Arrow.Mix({ 1, 0, 0 }, { r = 0, g = 1, b = 0 }, 0.25)
  assertNear(r, 0.25, "r")
  assertNear(g, 0.75, "g")
  assertNear(b, 0, "b")
end)

-- ── the ground sheet ─────────────────────────────────────────────────────────────────────────

test("arrow: GroundFrame picks the nearest 5 degrees, counter-clockwise, wrapping at 72", function()
  local _, Arrow = F.env()
  local G = Arrow.GroundFrame
  assertEqual(G(0), 0)
  assertEqual(G(math.rad(2.4)), 0)
  assertEqual(G(math.rad(2.6)), 1)
  assertEqual(G(math.rad(35)), 7)
  assertEqual(G(PI / 2), 18, "a quarter turn left")
  assertEqual(G(PI), 36)
  assertEqual(G(-PI / 2), 54, "a quarter turn right")
  assertEqual(G(math.rad(-5)), 71)
  assertEqual(G(2 * PI), 0)
  assertNil(G(nil))
end)

test("arrow: GroundTexCoord lays the frames 8 to a row of 64x44 cells on a 512 sheet", function()
  local _, Arrow = F.env()
  local l, r, t, b = Arrow.GroundTexCoord(0)
  assertNear(l, 0, "frame 0 left")
  assertNear(r, 64 / 512, "frame 0 right")
  assertNear(t, 0, "frame 0 top")
  assertNear(b, 44 / 512, "frame 0 bottom")
  l, _, t = Arrow.GroundTexCoord(9)
  assertNear(l, 64 / 512, "frame 9 is column 1")
  assertNear(t, 44 / 512, "frame 9 is row 1")
  _, r, _, b = Arrow.GroundTexCoord(71)
  assertNear(r, 1, "frame 71 ends the row")
  assertNear(b, 9 * 44 / 512, "frame 71 is the ninth row")
end)

-- ── the looks ────────────────────────────────────────────────────────────────────────────────

local function pointAhead(a, yards, rotation)
  a:SetProvider(function() return yards, rotation end, "Trainer")
end

test("arrow: Raised, the default, draws the fill, its overlay and a shadow offset down and right", function()
  local a = newArrow()
  pointAhead(a, 100, 0.5)
  local _, box, shadow, body, overlay = parts(a)
  assertEqual(body:GetTexture(), MEDIA .. "arrow-fill")
  assertEqual(overlay:GetTexture(), MEDIA .. "raised-overlay")
  assertEqual(shadow:GetTexture(), MEDIA .. "raised-shadow")
  assertTrue(shadow:IsShown(), "the shadow shows")
  local p = { shadow:GetPoint(1) }
  assertEqual(p[1], "CENTER")
  assertEqual(p[2], box)
  assertTrue(p[4] > 0 and p[5] < 0, "down and right of the arrow")
  assertNear(shadow:GetRotation(), 0.5, "the shadow turns with the arrow")
  assertNear(body:GetRotation(), 0.5, "the body turns")
  assertNear(overlay:GetRotation(), 0.5, "the overlay turns")
end)

test("arrow: Flat, Ridge and Faceted swap the overlay and drop the shadow", function()
  local a = newArrow()
  pointAhead(a, 100, -1)
  for _, style in ipairs({ "flat", "ridge", "faceted" }) do
    a:Configure({ style = style })
    local _, _, shadow, body, overlay = parts(a)
    assertEqual(body:GetTexture(), MEDIA .. "arrow-fill", style .. ": the shared fill")
    assertEqual(overlay:GetTexture(), MEDIA .. style .. "-overlay", style .. ": its overlay")
    assertFalse(shadow:IsShown(), style .. ": no shadow")
    assertEqual(a:Stats().style, style)
  end
end)

test("arrow: the ground look picks a sheet frame instead of turning", function()
  local a = newArrow()
  a:Configure({ style = "ground" })
  pointAhead(a, 100, PI / 2)
  local _, _, shadow, body, overlay = parts(a)
  assertEqual(body:GetTexture(), MEDIA .. "ground-body")
  assertEqual(overlay:GetTexture(), MEDIA .. "ground-overlay")
  assertFalse(shadow:IsShown())
  assertEqual(body:GetRotation(), 0, "never turned")
  assertEqual(a:Stats().frameIndex, 18)
  local ul_x, ul_y = body:GetTexCoord()
  assertNear(ul_x, (18 % 8) * 64 / 512, "frame 18's column")
  assertNear(ul_y, math.floor(18 / 8) * 44 / 512, "frame 18's row")
  local w, h = body:GetSize()
  assertNear(w, 50 * 1.25, "a cell is 50 units wide, at 1.25 px a unit")
  assertNear(h, 34.375 * 1.25, "and 34.375 tall")
end)

-- ── the size (minor 2, round 9 L1) ───────────────────────────────────────────────────────────

test("arrow: scale 1 draws the 48-unit art box at 60 px, 1.25x minor 1's 48", function()
  local a, _, Arrow = newArrow()
  pointAhead(a, 100, 0)
  local f, box, shadow, body, overlay = parts(a)
  assertEqual(Arrow.ART, 60)
  assertEqual(Arrow.UNITS, 48)
  local bw, bh = box:GetSize()
  assertEqual(bw, 60, "the box")
  assertEqual(bh, 60)
  assertEqual(select(1, body:GetSize()), 60, "the body fills it")
  assertEqual(select(1, overlay:GetSize()), 60, "and the overlay")
  assertNear(select(1, shadow:GetSize()), 80, "the 64-unit shadow canvas")
  local p = { shadow:GetPoint(1) }
  assertNear(p[4], 1.875, "the shadow's offset right, 1.5 units")
  assertNear(p[5], -3.75, "and down, 3 units")
  local fw, fh = f:GetSize()
  assertNear(fw, 60 + 2 * 8 * 1.25, "the frame: the box and 8 units each side")
  assertNear(fh, 60 + 2 * 8 * 1.25, "a square, centered on the art")
  local ins = rawget(f, "__insets")
  assertEqual(table.concat({ ins[1], ins[2], ins[3] }, ","), "0,0,0", "the hit rect grows only under")
  assertNear(ins[4], -(2.5 + 20 * 1.25 - 10), "by the text's 22 units, past the pad")
  local p2 = { box:GetPoint(1) }
  assertEqual(p2[1], "CENTER", "the art box sits at the frame's center")
  assertEqual(f:GetScale(), 1, "scale 1 is the new 1.0")
end)

test("arrow: the text sits the gap's 2 units under the art box", function()
  local a = newArrow()
  pointAhead(a, 100, 0)
  local _, box, _, _, _, text = parts(a)
  local p = { text:GetPoint(1) }
  assertEqual(p[1], "TOP")
  assertEqual(p[2], box)
  assertEqual(p[3], "BOTTOM")
  assertNear(p[5], -2.5, "2 units at 1.25 px")
end)

test("arrow: leaving the ground look gives the textures back their full coords", function()
  local a = newArrow()
  a:Configure({ style = "ground" })
  pointAhead(a, 100, 1)
  a:Configure({ style = "flat" })
  local _, _, _, body = parts(a)
  local c = { body:GetTexCoord() }
  assertEqual(table.concat(c, ","), "0,0,0,1,1,0,1,1")
  assertNear(body:GetRotation(), 1, "and turns it again")
end)

test("arrow: a style that is not one reads as Raised, and STYLES lists all five", function()
  local a, _, Arrow = newArrow()
  a:Configure({ style = "sparkly" })
  assertEqual(a:Get("style"), "raised")
  assertEqual(table.concat(Arrow.STYLES, ","), "flat,ridge,raised,faceted,ground")
  assertTrue(Arrow.IsStyle("ground"))
  assertFalse(Arrow.IsStyle("sparkly"))
end)

test("arrow: every look's art ships, uncompressed or RLE 32-bit TGA, power-of-two", function()
  local want = {
    ["arrow-fill"] = 128, ["flat-overlay"] = 128, ["ridge-overlay"] = 128, ["raised-overlay"] = 128,
    ["raised-shadow"] = 128, ["faceted-overlay"] = 128, ["ground-body"] = 512, ["ground-overlay"] = 512,
  }
  for name, size in pairs(want) do
    local fh = io.open("LibKa0s/media/waypoint/" .. name .. ".tga", "rb")
    assertTrue(fh ~= nil, name .. ".tga ships")
    local h = fh:read(18)
    fh:close()
    local kind, w, hh, bpp = h:byte(3), h:byte(13) + 256 * h:byte(14), h:byte(15) + 256 * h:byte(16), h:byte(17)
    assertTrue(kind == 2 or kind == 10, name .. ": true-color, raw or RLE")
    assertEqual(bpp, 32, name .. ": with alpha")
    assertEqual(w, size, name .. " width")
    assertEqual(hh, size, name .. " height")
  end
end)

-- ── the color ────────────────────────────────────────────────────────────────────────────────

test("arrow: the body fades from the far color to the near color by distance", function()
  local a = newArrow()
  a:Configure({ useSkinColors = false, farColor = { 1, 0, 0, 1 }, nearColor = { 0, 0, 1, 1 } })
  local yards = 300
  a:SetProvider(function() return yards, 0 end)
  local _, _, _, body, overlay = parts(a)
  assertEqual(table.concat(vertex(body), ","), "1,0,0", "300 yd: far")
  yards = 30
  tick(nil, a)
  assertEqual(table.concat(vertex(body), ","), "0,0,1", "30 yd: near")
  yards = 165
  tick(nil, a)
  local c = vertex(body)
  assertNear(c[1], 0.5, "halfway r")
  assertNear(c[3], 0.5, "halfway b")
  assertEqual(table.concat(vertex(overlay), ","), "1,1,1", "the overlay is never tinted")
end)

test("arrow: Use the skin's colors draws the skin's accent far and its good color near", function()
  local a = newArrow({ skin = "TestAddon" }, function(m)
    local Skin = m.LibStub:NewLibrary("LibKa0s-Skin-1.0", 1)   -- a stand-in answering two tokens
    function Skin:Color(owner, token)
      if owner ~= "TestAddon" then return nil end
      if token == "text.accent" then return 0.9, 0.1, 0.2, 1 end
      if token == "sem.good" then return 0.1, 0.8, 0.3, 1 end
    end
  end)
  local far, nearC = a:Colors()
  assertEqual(table.concat(far, ","), "0.9,0.1,0.2", "far is the skin's accent")
  assertEqual(table.concat(nearC, ","), "0.1,0.8,0.3", "near is sem.good")
  a:Configure({ useSkinColors = false, farColor = { r = 1, g = 1, b = 0 }, nearColor = { 0, 1, 1, 1 } })
  far, nearC = a:Colors()
  assertEqual(table.concat(far, ","), "1,1,0", "off: the custom far (a keyed color reads)")
  assertEqual(table.concat(nearC, ","), "0,1,1", "off: the custom near")
end)

test("arrow: with no skin, Use the skin's colors falls back to the custom pair", function()
  local a = newArrow()
  local far = a:Colors()
  assertEqual(table.concat(far, ","), "1,0.82,0", "the default far color")
end)

-- ── measuring ────────────────────────────────────────────────────────────────────────────────

test("arrow: SetTarget measures the player against a map point, every tick", function()
  local a, m = newArrow()
  m.__player, m.__facing = { 7, 0, 0 }, 0
  m.__maps[1429] = { 7, 0, 0, 1000 }
  assertTrue(a:SetTarget({ mapID = 1429, x = 0.1, y = 0, label = "North" }))
  local s = a:Stats()
  assertTrue(s.shown and s.armed, "shown, its OnUpdate armed")
  assertNear(s.yards, 100, "100 yd")
  assertNear(s.rotation, 0, "straight ahead")
  m.__facing = PI / 2   -- the player turns to face west
  tick(m, a)
  assertNear(a:Stats().rotation, -PI / 2, "the target is now to the right")
  local _, _, _, _, _, text = parts(a)
  assertEqual(text:GetText(), "100 yd")
end)

test("arrow: world targets, another instance, and no facing", function()
  local a, m = newArrow()
  m.__player, m.__facing = { 7, 0, 0 }, 0
  a:SetTarget({ instance = 7, wx = 0, wy = 50, label = "West" })
  assertNear(a:Stats().rotation, PI / 2, "due west")
  m.__facing = nil
  tick(m, a)
  local _, _, _, body, _, text = parts(a)
  assertFalse(body:IsShown(), "no facing: the art hides")
  assertEqual(text:GetText(), "50 yd", "the distance stays")
  m.__player = { 8, 0, 0 }
  tick(m, a)
  assertNil(a:Stats().yards, "another instance: no distance")
  assertEqual(text:GetText(), "West", "the label alone")
  assertNear(text:GetAlpha(), 0.6, "dim, with no skin to say muted")
end)

test("arrow: a secret facing or a secret position is no value", function()
  local a, m = newArrow(nil, function(mm)
    mm.issecretvalue = function(v) return v == "secret" end
  end)
  m.__player, m.__facing = { 7, 0, 0 }, "secret"
  a:SetTarget({ instance = 7, wx = 10, wy = 0 })
  local _, _, _, body = parts(a)
  assertFalse(body:IsShown(), "the art hides")
  m.C_Map.GetPlayerMapPosition = function() return "secret" end
  tick(m, a)
  assertNil(a:Stats().yards)
  assertEqual(#m.__errors, 0, "nothing raised")
end)

test("arrow: within arrive yards onArrive gets the spec and the arrow comes down", function()
  local a, m, _, rec = newArrow()
  m.__player, m.__facing = { 7, 0, 0 }, 0
  local spec = { instance = 7, wx = 20, wy = 0 }
  a:SetTarget(spec)
  assertTrue(a:IsShown())
  m.__player = { 7, 17, 0 }
  tick(m, a)
  assertEqual(rec.arrived[1], spec)
  assertFalse(a:IsShown())
  assertFalse(a:Stats().armed, "the OnUpdate is disarmed")
  assertNil(a:Target())
end)

test("arrow: arrive = false never arrives", function()
  local a, m, _, rec = newArrow({ arrive = false })
  m.__player, m.__facing = { 7, 0, 0 }, 0
  a:SetTarget({ instance = 7, wx = 0.5, wy = 0 })
  assertEqual(#rec.arrived, 0)
  assertTrue(a:IsShown())
end)

test("arrow: a provider that raises is no value, and the arrow runs on", function()
  local a = newArrow()
  a:SetProvider(function() error("boom") end, "Somewhere")
  local _, _, _, body, _, text = parts(a)
  assertFalse(body:IsShown())
  assertEqual(text:GetText(), "Somewhere")
end)

test("arrow: format(yards) writes the distance", function()
  local a = newArrow({ format = function(y) return ("%.0f m"):format(y * 0.9144) end })
  pointAhead(a, 100, 0)
  local _, _, _, _, _, text = parts(a)
  assertEqual(text:GetText(), "91 m")
end)

-- ── showing and hiding ───────────────────────────────────────────────────────────────────────

test("arrow: Clear hides and disarms; SetTarget refuses a spec without a place", function()
  local a = newArrow()
  assertFalse(a:SetTarget({ label = "nowhere" }))
  assertFalse(a:SetTarget(nil))
  pointAhead(a, 100, 0)
  a:Clear()
  local s = a:Stats()
  assertFalse(s.shown)
  assertFalse(s.armed)
  assertNil(a:Target())
end)

test("arrow: the sample shows at its fixed distance and angle, and a real target waits under it", function()
  local a, _, Arrow = newArrow()
  a:ShowSample("Sample trainer")
  local s = a:Stats()
  assertTrue(s.shown and s.sample)
  assertNear(s.rotation, Arrow.SAMPLE_ROTATION, "35 degrees left")
  assertNear(s.yards, Arrow.SAMPLE_YARDS, "240 yd")
  pointAhead(a, 50, 1)
  assertNear(a:Stats().rotation, Arrow.SAMPLE_ROTATION, "the sample stays over a new target")
  a:Clear()
  assertTrue(a:IsShown(), "Clear leaves the sample up")
  pointAhead(a, 50, 1)
  a:HideSample()
  assertTrue(a:IsShown(), "the real target is pointed at again")
  assertNear(a:Stats().rotation, 1)
  a:Clear()
  a:ShowSample()
  a:HideSample()
  assertFalse(a:IsShown(), "no target under it: the sample's end hides")
end)

test("arrow: Suspend takes everything down and refuses until Resume", function()
  local a = newArrow()
  pointAhead(a, 100, 0)
  a:Suspend()
  assertFalse(a:IsShown())
  assertTrue(a:Suspended())
  assertFalse(a:SetTarget({ instance = 1, wx = 1, wy = 1 }))
  assertFalse(a:ShowSample())
  a:Resume()
  assertTrue(a:SetTarget({ instance = 1, wx = 1, wy = 1 }))
end)

-- ── scale and position ───────────────────────────────────────────────────────────────────────

test("arrow: scale applies to the frame and is clamped to 0.5 .. 2", function()
  local a = newArrow()
  pointAhead(a, 100, 0)
  a:Configure({ scale = 1.5 })
  assertEqual(a:Frame():GetScale(), 1.5)
  a:Configure({ scale = 9 })
  assertEqual(a:Frame():GetScale(), 1, "out of range reads as the default")
end)

test("arrow: the saved point places the frame; a drag hands the new point back", function()
  local a, _, _, rec = newArrow({ point = { point = "TOPLEFT", relPoint = "TOPLEFT", x = 10, y = -20 } })
  pointAhead(a, 100, 0)
  local f = a:Frame()
  local p = { f:GetPoint() }
  assertEqual(p[1], "TOPLEFT")
  assertEqual(p[4], 10)
  f:__fire("OnDragStart")
  assertTrue(rawget(f, "__moving"), "moving")
  f:SetPoint("BOTTOM", nil, "BOTTOM", 4, 5)
  f:__fire("OnDragStop")
  local moved = rec.moved[1]
  assertEqual(moved.point, "BOTTOM")
  assertEqual(moved.x, 4)
  assertEqual(moved.y, 5)
  assertEqual(a:GetPosition().point, "BOTTOM")
end)

test("arrow: canDrag false holds the frame still", function()
  local a, _, _, rec = newArrow({ canDrag = function() return false end })
  pointAhead(a, 100, 0)
  local f = a:Frame()
  f:__fire("OnDragStart")
  assertFalse(rawget(f, "__moving") == true)
  f:__fire("OnDragStop")
  assertEqual(#rec.moved, 0)
end)

test("arrow: SetPosition takes either shape; ResetPosition tells the host to forget", function()
  local a, _, Arrow, rec = newArrow()
  a:SetPosition({ "LEFT", "LEFT", 3, 4 })
  assertEqual(a:GetPosition().point, "LEFT")
  a:SetPosition({ point = "NOWHERE" })
  assertEqual(a:GetPosition().point, Arrow.DEFAULT_POINT.point, "an anchor SetPoint would refuse reads as the default")
  a:ResetPosition()
  assertEqual(rec.moved[1], false, "onMoved(nil)")
end)

test("arrow: a right click reaches onClick", function()
  local a, _, _, rec = newArrow()
  pointAhead(a, 100, 0)
  a:Frame():__fire("OnMouseUp", "RightButton")
  assertEqual(rec.clicks[1], "RightButton")
end)
