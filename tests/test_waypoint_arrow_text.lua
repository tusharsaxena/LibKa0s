-- tests/test_waypoint_arrow_text.lua — LibKa0s-WaypointArrow-1.0 minor 2: the distance text (Skill
-- Master round 9, L2). Its font (the canonical Font block's six leaves and "Use the skin's font"),
-- where it sits, the label line and the distance's units, on the shared bench
-- (tests/fixture_waypoint_arrow.lua).

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local F = dofile("tests/fixture_waypoint_arrow.lua")
local newArrow, parts, tick = F.newArrow, F.parts, F.tick

local GAME_FACE = "Fonts\\GAME.TTF"

local function near(a, b) return type(a) == "number" and math.abs(a - b) <= 1e-9 end

local function pointAhead(a, yards, label)
  a:SetProvider(function() return yards, 0 end, label or "Trainer")
end

local function textOf(a)
  local _, _, _, _, _, text = parts(a)
  return text
end

--- An arrow with the client's standard face set, so the font paths are distinct.
local function arrowWithFace(d, before)
  return newArrow(d, function(m)
    m.STANDARD_TEXT_FONT = GAME_FACE
    if before then before(m) end
  end)
end

-- ── the settings ─────────────────────────────────────────────────────────────────────────────

test("arrow text: the defaults follow the skin, below the arrow, in yards, with no label line", function()
  local a, _, Arrow = newArrow()
  assertEqual(a:Get("font"), "Ka0s Prototype")
  assertEqual(a:Get("fontFromSkin"), true)
  assertEqual(a:Get("fontSize"), 12)
  assertEqual(table.concat(a:Get("fontColor"), ","), "1,1,1,1")
  assertEqual(a:Get("useClassColorFont"), false)
  assertEqual(a:Get("fontFlags"), "@skin")
  assertEqual(a:Get("fontShadow"), true)
  assertEqual(a:Get("textPosition"), "BELOW")
  assertEqual(a:Get("showLabel"), false)
  assertEqual(a:Get("distanceUnits"), "yards")
  assertEqual(table.concat(Arrow.TEXT_POSITIONS, ","), "BELOW,ABOVE,LEFT,RIGHT,HIDDEN")
  assertEqual(table.concat(Arrow.DISTANCE_UNITS, ","), "yards,compact")
end)

test("arrow text: a value that is not valid reads as the default", function()
  local a = newArrow()
  a:Configure({ textPosition = "INSIDE", distanceUnits = "miles", fontSize = 99, fontFlags = "BOLD",
    fontColor = "red", showLabel = "yes", font = "" })
  assertEqual(a:Get("textPosition"), "BELOW")
  assertEqual(a:Get("distanceUnits"), "yards")
  assertEqual(a:Get("fontSize"), 12)
  assertEqual(a:Get("fontFlags"), "@skin")
  assertEqual(a:Get("fontColor")[1], 1)
  assertEqual(a:Get("showLabel"), false)
  assertEqual(a:Get("font"), "Ka0s Prototype")
end)

-- ── the distance ─────────────────────────────────────────────────────────────────────────────

test("arrow text: FormatDistance in yards and compact, with the host's strings", function()
  local _, Arrow = F.env()
  local fmt = Arrow.FormatDistance
  assertEqual(fmt(123.4, "yards"), "123 yd")
  assertEqual(fmt(4210, "yards"), "4210 yd", "yards never shortens")
  assertEqual(fmt(4210, "compact"), "4.2k yd", "compact from 1000 yd")
  assertEqual(fmt(999.4, "compact"), "999 yd", "under 1000, yards")
  assertEqual(fmt(999.6, "compact"), "1.0k yd", "rounded first")
  assertEqual(fmt(50), "50 yd", "no units is yards")
  assertNil(fmt(nil, "yards"))
  local L = setmetatable({ DISTANCE = "%d m", DISTANCE_COMPACT = "%.1f km" },
    { __index = function(_, k) return k end })
  assertEqual(fmt(12, "yards", L), "12 m")
  assertEqual(fmt(4210, "compact", L), "4.2 km")
  assertEqual(fmt(12, "yards", setmetatable({}, { __index = function(_, k) return k end })), "12 yd",
    "read raw, so a locale that answers the key is no override")
end)

test("arrow text: compact units reach the text, and d.strings words it", function()
  local a = newArrow({ strings = { DISTANCE_COMPACT = "%.1f mil" } })
  a:Configure({ distanceUnits = "compact" })
  pointAhead(a, 4260)
  assertEqual(textOf(a):GetText(), "4.3 mil")
end)

test("arrow text: d.format gets the yards and the units, and its string wins", function()
  local seen = {}
  local a = newArrow({ format = function(y, units)
    seen[#seen + 1] = units
    if units == "compact" then return ("%.0f m"):format(y * 0.9144) end
  end })
  pointAhead(a, 100)
  assertEqual(textOf(a):GetText(), "100 yd", "a nil answer falls back to the library's words")
  a:Configure({ distanceUnits = "compact" })
  tick(nil, a)
  assertEqual(textOf(a):GetText(), "91 m")
  assertEqual(seen[1], "yards")
  assertEqual(seen[#seen], "compact")
end)

-- ── the label line ───────────────────────────────────────────────────────────────────────────

test("arrow text: Show the label adds the target's label on a second line", function()
  local a = newArrow()
  pointAhead(a, 100, "Master Smith")
  assertEqual(textOf(a):GetText(), "100 yd", "off by default")
  a:Configure({ showLabel = true })
  assertEqual(textOf(a):GetText(), "100 yd\nMaster Smith")
  a:SetProvider(function() return 100, 0 end)
  assertEqual(textOf(a):GetText(), "100 yd", "no label, no second line")
end)

test("arrow text: with no distance the label shows alone and dim, the label line or not", function()
  local a = newArrow()
  a:Configure({ showLabel = true })
  a:SetProvider(function() return nil, 0 end, "Far away")
  local text = textOf(a)
  assertEqual(text:GetText(), "Far away")
  assertTrue(near(text:GetAlpha(), 0.6), "dim")
end)

test("arrow text: the sample previews the label line with its own label", function()
  local a = newArrow({ strings = { SAMPLE = "Beispiel" } })
  a:Configure({ showLabel = true })
  a:ShowSample()
  assertEqual(textOf(a):GetText(), "240 yd\nBeispiel")
end)

-- ── where it sits ────────────────────────────────────────────────────────────────────────────

test("arrow text: each position anchors the text to its side of the art box", function()
  local a = newArrow()
  pointAhead(a, 100)
  local want = {
    BELOW = { "TOP", "BOTTOM", 0, -2.5, "CENTER" },
    ABOVE = { "BOTTOM", "TOP", 0, 2.5, "CENTER" },
    LEFT = { "RIGHT", "LEFT", -2.5, 0, "RIGHT" },
    RIGHT = { "LEFT", "RIGHT", 2.5, 0, "LEFT" },
  }
  for pos, w in pairs(want) do
    a:Configure({ textPosition = pos })
    local _, box, _, _, _, text = parts(a)
    local p = { text:GetPoint(1) }
    assertEqual(p[1], w[1], pos .. ": the text's point")
    assertEqual(p[2], box, pos .. ": on the art box")
    assertEqual(p[3], w[2], pos .. ": the box's point")
    assertTrue(near(p[4], w[3]) and near(p[5], w[4]), pos .. ": the gap's 2 units")
    assertEqual(text:GetJustifyH(), w[5], pos .. ": justified toward the arrow")
    assertTrue(text:IsShown(), pos .. ": shown")
    assertEqual(({ box:GetPoint(1) })[1], "CENTER", pos .. ": the arrow stays where it was")
  end
end)

test("arrow text: the hit rect grows toward the text's side", function()
  local a = newArrow()
  pointAhead(a, 100)
  local f = a:Frame()
  a:Configure({ textPosition = "ABOVE" })
  local ins = rawget(f, "__insets")
  assertTrue(ins[3] < 0 and ins[4] == 0, "above: the top grows")
  local text = textOf(a)
  rawset(text, "GetStringWidth", function() return 50 end)
  a:Configure({ textPosition = "RIGHT" })
  ins = rawget(f, "__insets")
  assertTrue(near(ins[2], -(2.5 + 50 - 10)), "right: by the measured width, past the pad")
  assertEqual(ins[1], 0)
  a:Configure({ textPosition = "HIDDEN" })
  assertEqual(table.concat(rawget(f, "__insets"), ","), "0,0,0,0", "hidden: the frame alone")
end)

test("arrow text: Hidden hides the text and the art still points", function()
  local a = newArrow()
  a:Configure({ textPosition = "HIDDEN" })
  pointAhead(a, 100)
  local _, _, _, body, _, text = parts(a)
  assertFalse(text:IsShown())
  assertTrue(body:IsShown())
  a:Configure({ textPosition = "BELOW" })
  assertTrue(text:IsShown(), "back")
  assertEqual(text:GetText(), "100 yd")
end)

-- ── the font, without a skin ─────────────────────────────────────────────────────────────────

test("arrow text: without a skin, Use the skin's font draws the game's face, outlined, shadowed", function()
  local a = arrowWithFace()
  pointAhead(a, 100)
  local face, size, flags = textOf(a):GetFont()
  assertEqual(face, GAME_FACE)
  assertEqual(size, 12)
  assertEqual(flags, "OUTLINE", "From skin, with no skin, is an outline")
  local x, y = textOf(a):GetShadowOffset()
  assertEqual(x .. "," .. y, "1,-1", "the shadow")
end)

test("arrow text: the player's font, size, flags and shadow", function()
  local a = arrowWithFace(nil, function(m)
    local LSM = m.LibStub:NewLibrary("LibSharedMedia-3.0", 1)
    function LSM:Fetch(kind, name) if kind == "font" and name == "Mono" then return "Fonts\\MONO.TTF" end end
  end)
  a:Configure({ fontFromSkin = false, font = "Mono", fontSize = 20, fontFlags = "THICKOUTLINE",
    fontShadow = false })
  pointAhead(a, 100)
  local face, size, flags = textOf(a):GetFont()
  assertEqual(face, "Fonts\\MONO.TTF")
  assertEqual(size, 20)
  assertEqual(flags, "THICKOUTLINE")
  local _, _, _, alpha = textOf(a):GetShadowColor()
  assertEqual(alpha, 0, "no shadow")
  a:Configure({ font = "Nowhere" })
  assertEqual((textOf(a):GetFont()), GAME_FACE, "a face nobody knows is the game's")
end)

test("arrow text: the color is the swatch's, or the player's class color", function()
  local a, m = newArrow()
  a:Configure({ fontColor = { r = 0.2, g = 0.4, b = 0.6, a = 0.8 } })
  pointAhead(a, 100)
  local r, g, b, al = textOf(a):GetTextColor()
  assertEqual(table.concat({ r, g, b, al }, ","), "0.2,0.4,0.6,0.8", "a keyed swatch, its alpha too")
  a:Configure({ useClassColorFont = true })
  r, g, b = textOf(a):GetTextColor()
  local c = m.RAID_CLASS_COLORS[select(2, m.UnitClass("player"))]
  assertEqual(table.concat({ r, g, b }, ","), table.concat({ c.r, c.g, c.b }, ","), "the player's class color")
end)

-- ── the font, with a skin ────────────────────────────────────────────────────────────────────

local function skinned(record)
  return arrowWithFace({ skin = "TestAddon" }, function(m)
    local Skin = m.LibStub:NewLibrary("LibKa0s-Skin-1.0", 1)
    function Skin:Color() return nil end
    function Skin:For()
      return {
        HudFontSize = function(size, fromSkin) return fromSkin and size * 2 or size end,
        HudFont = function(fs, opts)
          record[#record + 1] = opts
          fs:SetFont(opts.face or "Skin\\HUD.TTF", opts.size, opts.flags)
        end,
      }
    end
    local LSM = m.LibStub:NewLibrary("LibSharedMedia-3.0", 1)
    function LSM:Fetch(_, name) if name == "Mono" then return "Fonts\\MONO.TTF" end end
  end)
end

test("arrow text: with a skin the font goes through its HudFont, the skin's face while it follows", function()
  local record = {}
  local a = skinned(record)
  pointAhead(a, 100)
  local opts = record[#record]
  assertNil(opts.face, "Use the skin's font: no face, the skin's HUD face")
  assertEqual(opts.size, 24, "the size scaled by the skin's HudFontSize")
  assertEqual(opts.flags, "@skin", "From skin flags go to the skin as they are")
  assertEqual(opts.shadow, true)
  assertEqual(opts.shadowFromSkin, false, "the Font shadow row is the player's")
  a:Configure({ fontFromSkin = false, font = "Mono", fontSize = 14 })
  opts = record[#record]
  assertEqual(opts.face, "Fonts\\MONO.TTF")
  assertEqual(opts.size, 14, "its own face: the size as stored")
end)

test("arrow text: the text never takes the skin's Text role, so a skin switch cannot overwrite the font", function()
  local calls = 0
  local a = arrowWithFace({ skin = "TestAddon" }, function(m)
    local Skin = m.LibStub:NewLibrary("LibKa0s-Skin-1.0", 1)
    function Skin:Color() return nil end
    function Skin:For() return { Text = function() calls = calls + 1 end } end
  end)
  pointAhead(a, 100)
  a:SetProvider(function() return nil, 0 end, "x")
  assertEqual(calls, 0)
end)

-- ── the host's paths ─────────────────────────────────────────────────────────────────────────

test("arrow text: ConfigureFrom reads the companion at the font path plus FromSkin", function()
  local a = newArrow()
  local store = { ["w.font"] = "Mono", ["w.fontFromSkin"] = false, ["w.pos"] = "LEFT" }
  a:ConfigureFrom(function(p) return store[p] end, { font = "w.font", textPosition = "w.pos" })
  assertEqual(a:Get("fontFromSkin"), false)
  assertEqual(a:Get("font"), "Mono")
  assertEqual(a:Get("textPosition"), "LEFT")
end)
