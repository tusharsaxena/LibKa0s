-- tests/test_skin_follow_callout.lua -- LibKa0s#97's batch C (SD-LK-97C of Ka0sAddonsCommonTasks
-- docs/2026-11-20-LIBKA0S_94_97_99_100; the audit is docs/2026-11-20-SKIN_DEFAULTS_AUDIT): under any
-- skin the call-out and the waypoint arrow's text take the skin's value by default (ruling R-2).
--
--   97.10  the call-out's look follows the skin (the owner's U-1): Skin font, an "@skin" outline,
--          the glow in the skin's glow color, a shadow companion; `FollowKeys` names what a host's
--          one-time step moves (only values still at the minor-4 defaults) and `MoveToSkin` moves
--          it, storing the Skin font as itself; the font row shows a stored @skin as the Skin font
--          through the Options engine (its skinValue)
--   97.11  the "number" kind reads `hud.text` through `numberColorFromSkin` (default true)
--   U-2    info, go, stop, warn and error are meaning colors: `sem.*` by default, a picked swatch wins
--   97.12  with an owner the text and its halo go through the facade's HudFont and HudFontSize
--   97.13  the arrow's text color reads `HudTextColor` through `fontColorFromSkin` (default true)
--   97.14  the arrow's text shadow follows `fontShadowFromSkin` (default true), no hard false
--
-- Every case is red under the old files (Callout.lua minor 5 as SD-LK-100 left it, CalloutSettings.lua
-- minor 5, WaypointArrow.lua and WaypointArrowSettings.lua minor 2) but two characterizations, the
-- swatch reader's and the arrow's skin with no HUD text color, and the bench release. One real-Skin
-- bench for the call-out cases (the run's leak gate counts each load of the Skin major), released by
-- the last case.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertNil
local FS = dofile("tests/fixture_skin_paint.lua")
local FC = dofile("tests/fixture_callout.lua")
local FA = dofile("tests/fixture_waypoint_arrow.lua")
local FO = dofile("tests/fixture_options.lua")
local Loader = T.loader

local LSM = {
  ["font:Ka0s Prototype"] = "path\\prototype.ttf", ["font:Ka0s Doris PP"] = "path\\doris.ttf",
  ["font:Ka0s Oxanium SemiBold"] = "path\\oxanium.ttf", ["font:Ka0s Open Sans Semibold"] = "path\\opensans.ttf",
}

local function bench()
  local m, Skin = FS.env({ lsm = LSM })
  m.STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
  Loader.load("LibKa0s/Callout.lua", nil, m)
  Loader.load("LibKa0s/CalloutSettings.lua", nil, m)
  return m, Skin, m.LibStub("LibKa0s-Callout-1.0")
end

local M, SKIN, CALLOUT = bench()

local function rgb3(r, g, b) return ("%.3f,%.3f,%.3f"):format(r, g, b) end
local function tok3(skin, name)
  local c = SKIN:ResolveSkin(skin)[name]
  return rgb3(c[1], c[2], c[3])
end

--- A call-out for owner `owner` on skin `skin` (nil: owner-less), its settings in `db`.
local function callout(owner, skin, db)
  if owner and not SKIN:IsOwner(owner) then FS.owner(SKIN, owner, skin) end
  db = db or {}
  local c = CALLOUT:New({ db = db, addon = "TestAddon", skin = owner })
  return c, db
end

local function textOf(c)
  local _, text, halo = FC.parts(c)
  return text, halo
end

-- ── 97.10: the look's defaults ───────────────────────────────────────────────────────────────

test("callout follow: the look's defaults are the skin's (97.10, U-1)", function()
  -- red under Callout minor 5 (v1.107.0's): Oxanium SemiBold, THICKOUTLINE, the skin's glow color off.
  local D = CALLOUT.DEFAULTS
  assertEqual(D.font, CALLOUT.FONT_SKIN, "the Skin font")
  assertEqual(D.outline, "@skin", "the skin's outline")
  assertTrue(D.glowColorFromSkin, "the glow in the skin's glow color")
  assertTrue(D.fontShadowFromSkin, "the skin's shadow")
  assertTrue(D.numberColorFromSkin, "numbers in the skin's HUD text color")
  assertEqual(CALLOUT.OUTLINES[1], "@skin", "From skin leads the outline choices")
  for _, key in ipairs({ "fontShadowFromSkin", "numberColorFromSkin" }) do
    local listed = false
    for _, k in ipairs(CALLOUT.SETTINGS) do if k == key then listed = true end end
    assertTrue(listed, key .. " is a setting Get and Set take")
  end
end)

test("callout follow: with an owner the text wears the skin's HUD face, outline and shadow (97.10, 97.12)", function()
  -- red under Callout minor 5: SetFont on the string (no font object, no shadow a 12.0.7 client draws).
  local c = callout("CO_Look", "contrast")
  c:Show("GO")
  local text = textOf(c)
  local obj = text:GetFontObject()
  assertTrue(obj ~= nil, "a HudFont font object")
  local face, size, flags = obj:GetFont()
  assertEqual(face, "path\\doris.ttf", "High Contrast's hud.font")
  local T0 = SKIN:ResolveSkin("contrast")
  assertEqual(size, 96 * T0["hud.fontSize"] / 12, "the size through HudFontSize")
  assertEqual(flags, "OUTLINE", "@skin through the skin's outline")
  assertEqual(table.concat(obj.shadow, ","), T0["hud.shadowX"] .. "," .. T0["hud.shadowY"], "the skin's shadow")
  local look = c:Look()
  assertEqual(look.font, "path\\doris.ttf")
  assertEqual(look.flags, "OUTLINE", "Look answers the resolved flags")
end)

test("callout follow: Use the skin's shadow off draws the stored shadow; Shadow off draws none (97.10)", function()
  -- red under Callout minor 5: no fontShadowFromSkin, and the stored shadow never reached a font object.
  local c = callout("CO_Shadow", "contrast")
  assertTrue(c:Set("fontShadowFromSkin", false))
  c:Show("GO")
  local obj = textOf(c):GetFontObject()
  assertEqual(table.concat(obj.shadow, ","), "1,1", "the stored 1, 1")
  assertEqual(table.concat(obj.shadowColor, ","), "0,0,0,1", "in black")
  assertTrue(c:Set("shadow", false))
  obj = textOf(c):GetFontObject()
  assertEqual(table.concat(obj.shadow, ","), "0,0", "none")
end)

test("callout follow: the halo goes through HudFont too, thick and shadowless (97.12)", function()
  local c = callout("CO_Halo", "contrast")
  c:Show("GO")
  local _, halo = textOf(c)
  local obj = halo:GetFontObject()
  assertTrue(obj ~= nil, "the halo's font object")
  local face, size, flags = obj:GetFont()
  local scaled = 96 * SKIN:ResolveSkin("contrast")["hud.fontSize"] / 12
  assertEqual(face, "path\\doris.ttf")
  assertEqual(size, scaled + 2, "the text's drawn size plus the thickness on each side")
  assertEqual(flags, "THICKOUTLINE")
  assertEqual(table.concat(obj.shadow, ","), "0,0", "no shadow behind the halo")
end)

test("callout follow: a picked face keeps its stored size; a picked outline wins (97.10, 97.12)", function()
  local c = callout("CO_Picked", "contrast")
  assertTrue(c:Set("font", "Ka0s Oxanium SemiBold"))
  assertTrue(c:Set("outline", "THICKOUTLINE"))
  c:Show("GO")
  local face, size, flags = textOf(c):GetFontObject():GetFont()
  assertEqual(face, "path\\oxanium.ttf")
  assertEqual(size, 96, "its own face: the size as stored")
  assertEqual(flags, "THICKOUTLINE")
  assertTrue(c:Set("outline", "NONE"))
  assertEqual(select(3, textOf(c):GetFontObject():GetFont()), "", "None is no flags")
end)

test("callout follow: the glow takes the skin's glow color by default (97.10)", function()
  -- red under Callout minor 5: glowColorFromSkin false, the black swatch drew in every skin.
  local c = callout("CO_Glow", "azeroth")
  c:Show("GO")
  local _, halo = textOf(c)
  local r, g, b = halo:GetTextColor()
  assertEqual(rgb3(r, g, b), tok3("azeroth", "glow.color"))
  assertTrue(c:Set("glowColorFromSkin", false))
  r, g, b = halo:GetTextColor()
  assertEqual(rgb3(r, g, b), "0.000,0.000,0.000", "off: the black swatch")
end)

test("callout follow: a skin switch repaints the face and the shadow (97.12)", function()
  local c = callout("CO_Switch", "contrast")
  c:Show("GO")
  assertEqual((textOf(c):GetFontObject():GetFont()), "path\\doris.ttf")
  SKIN:SetChoice("CO_Switch", "ka0s", "azeroth")
  assertEqual((textOf(c):GetFontObject():GetFont()), "path\\opensans.ttf", "Azeroth's hud.font, no Apply")
end)

-- ── 97.11 and U-2: the kind colors ───────────────────────────────────────────────────────────

test("callout follow: numbers draw the skin's HUD text color; off, the swatch (97.11)", function()
  -- red under Callout minor 5: the white literal in every skin.
  local c = callout("CO_Number", "azeroth")
  assertEqual(rgb3(c:GetColor("number")), tok3("azeroth", "hud.text"))
  assertTrue(c:Set("numberColorFromSkin", false))
  assertEqual(rgb3(c:GetColor("number")), "1.000,1.000,1.000", "the swatch, white by default")
  assertTrue(c:SetColor("number", 0.2, 0.4, 0.6))
  assertEqual(rgb3(c:GetColor("number")), "0.200,0.400,0.600")
end)

test("callout follow: info, go, stop, warn and error draw the skin's meaning colors (U-2)", function()
  -- red under Callout minor 5: the literal defaults, read by no semantic token.
  local c = callout("CO_Meaning", "azeroth")
  local want = { info = "sem.info", go = "sem.good", stop = "sem.bad", warn = "sem.warn", error = "sem.bad" }
  for kind, token in pairs(want) do
    assertEqual(rgb3(c:GetColor(kind)), tok3("azeroth", token), kind .. " reads " .. token)
    assertEqual(CALLOUT.MEANING[kind], token)
  end
end)

test("callout follow: a meaning color the player picks wins; one at a default still follows (U-2)", function()
  local c, db = callout("CO_Pick", "azeroth")
  assertTrue(c:SetColor("warn", 0.1, 0.2, 0.3))
  assertEqual(rgb3(c:GetColor("warn")), "0.100,0.200,0.300", "the player's pick")
  db.colors.go = { 0.3, 1, 0.45 }   -- v1.107.0's default, copied into a host's table
  assertEqual(rgb3(c:GetColor("go")), tok3("azeroth", "sem.good"), "a stored old default follows")
  local d = CALLOUT.DEFAULTS.colors.stop
  db.colors.stop = { d[1], d[2], d[3] }
  assertEqual(rgb3(c:GetColor("stop")), tok3("azeroth", "sem.bad"), "a stored default follows")
end)

test("callout follow: the swatch's reader is the stored color, never the drawn one (U-2)", function()
  local c = callout("CO_Swatch", "azeroth")
  local sw = CALLOUT.__colorFor(c, "go")
  local d = CALLOUT.DEFAULTS.colors.go
  assertEqual(rgb3(sw.r, sw.g, sw.b), rgb3(d[1], d[2], d[3]), "the default, as a reset count compares it")
end)

-- ── the owner-less path ──────────────────────────────────────────────────────────────────────

test("callout follow: owner-less, the text is set directly, @skin an outline, the defaults' colors (97.12)", function()
  local c = callout(nil)
  c:Show("GO")
  local text = textOf(c)
  assertNil(text:GetFontObject(), "no HudFont")
  local _, size, flags = text:GetFont()
  assertEqual(size, 96)
  assertEqual(flags, "OUTLINE", "@skin with no skin reads OUTLINE")
  local x, y = text:GetShadowOffset()
  assertEqual(x .. "," .. y, "1,1", "the stored shadow, directly")
  local d = CALLOUT.DEFAULTS.colors.go
  assertEqual(rgb3(c:GetColor("go")), rgb3(d[1], d[2], d[3]))
  assertEqual(rgb3(c:GetColor("number")), "1.000,1.000,1.000")
end)

-- ── 97.10: the one-time move ─────────────────────────────────────────────────────────────────

test("callout follow: FollowKeys names only the look settings still at their minor-4 defaults (97.10)", function()
  -- red under Callout minor 5: no FollowKeys.
  local t = { font = "Ka0s Oxanium SemiBold", outline = "THICKOUTLINE", glowColorFromSkin = false, size = 96 }
  assertEqual(table.concat(CALLOUT:FollowKeys(t, "callout."), ","),
    "callout.font,callout.outline,callout.glowColorFromSkin")
  assertEqual(table.concat(CALLOUT:FollowKeys(t), ","), "font,outline,glowColorFromSkin", "no prefix")
  local picked = { font = "Ka0s Bebas Neue", outline = "OUTLINE", glowColorFromSkin = false }
  assertEqual(table.concat(CALLOUT:FollowKeys(picked, "callout"), ","), "callout.glowColorFromSkin",
    "a picked face and outline stay")
  assertEqual(#CALLOUT:FollowKeys({}, "callout."), 0, "nothing stored: nothing to move")
  assertEqual(#CALLOUT:FollowKeys(nil), 0)
  assertEqual(CALLOUT.FOLLOW_FROM.font, "Ka0s Oxanium SemiBold")
end)

test("callout follow: MoveToSkin writes the Skin font, @skin and true for the keys FollowKeys names (97.10)", function()
  -- red before the review fix: no MoveToSkin, and the documented route (ResetToSkin over FollowKeys)
  -- stored "@skin" for the face, which a path row's picker reads as no value of its own.
  local t = { font = "Ka0s Oxanium SemiBold", outline = "THICKOUTLINE", glowColorFromSkin = false }
  assertEqual(CALLOUT:MoveToSkin(t), 3, "three keys moved")
  assertEqual(t.font, CALLOUT.FONT_SKIN, "the face is stored as the Skin font, never @skin")
  assertEqual(t.outline, "@skin")
  assertEqual(t.glowColorFromSkin, true)
  assertEqual(CALLOUT:MoveToSkin(t), 0, "nothing left at an old default")
  local picked = { font = "Ka0s Bebas Neue", outline = "OUTLINE", glowColorFromSkin = false }
  assertEqual(CALLOUT:MoveToSkin(picked), 1)
  assertEqual(picked.font, "Ka0s Bebas Neue", "a picked face stays")
  assertEqual(picked.outline, "OUTLINE", "a picked outline stays")
  assertEqual(CALLOUT:MoveToSkin(nil), 0)
  local c = callout("CO_Move", "contrast", t)
  assertEqual(c:Get("font"), CALLOUT.FONT_SKIN)
  c:Show("GO")
  assertEqual((textOf(c):GetFontObject():GetFont()), "path\\doris.ttf", "the skin's face")
end)

test("callout follow: a stored @skin face (ResetToSkin over FollowKeys) still draws the skin's face (97.10)", function()
  local profile = { callout = { font = "Ka0s Oxanium SemiBold", outline = "THICKOUTLINE", glowColorFromSkin = false } }
  SKIN.ResetToSkin(profile, CALLOUT:FollowKeys(profile.callout, "callout."))
  local c = callout("CO_Reset", "contrast", profile.callout)
  assertEqual(c:Get("font"), CALLOUT.FONT_SKIN, "the sentinel reads as the Skin font")
  c:Show("GO")
  assertEqual((textOf(c):GetFontObject():GetFont()), "path\\doris.ttf", "the skin's face")
end)

-- ── the settings rows ────────────────────────────────────────────────────────────────────────

test("callout follow: the rows carry the outline's From skin, the shadow and number companions (CalloutSettings 6)", function()
  -- red under CalloutSettings minor 5: no From skin outline, no fontShadowFromSkin or numberColorFromSkin row.
  local c = callout("CO_Rows", "ka0s")
  local rows = c:SchemaRows("callout.", { texts = false })
  local by = {}
  for _, r in ipairs(rows) do by[r.path] = r end
  assertEqual(by["callout.outline"].values[1].value, "@skin")
  assertEqual(by["callout.outline"].values[1].text, "From skin")
  assertEqual(by["callout.outline"].default, "@skin")
  assertEqual(by["callout.font"].default, CALLOUT.FONT_SKIN)
  local shadow = by["callout.fontShadowFromSkin"]
  assertTrue(shadow ~= nil and shadow.type == "bool" and shadow.default == true, "Use the skin's shadow")
  assertEqual(shadow.label, "Use the skin's shadow")
  assertTrue(by["callout.shadow"].disabledIf(), "Shadow is not read while it is on")
  local num = by["callout.numberColorFromSkin"]
  assertTrue(num ~= nil and num.type == "bool" and num.default == true, "Use the skin's color for numbers")
  assertNil(by["callout.colors.number"].disabledIf, "the swatch stays live (options-ui-§17)")
  assertEqual(by["callout.glowColorFromSkin"].default, true)
  local order = {}
  for _, r in ipairs(rows) do order[#order + 1] = r.path end
  local joined = table.concat(order, ",")
  assertTrue(joined:find("callout.colors.number,callout.numberColorFromSkin,callout.colors.info", 1, true) ~= nil,
    "the companion sits beside the Numbers swatch")
end)

test("callout follow: through the Options engine a stored @skin font row shows the Skin font (97.10)", function()
  -- red before the review fix: a path row is read through the descriptor's get, so the font row's
  -- own `get` never ran and the picker showed "@skin"; the row's skinValue is the seam it honors.
  local profile = { callout = { font = "@skin" } }   -- the host's settings: one table, two readers
  local c = callout("CO_FontRow", "ka0s", profile.callout)
  local leaf = function(path) return (path:match("^callout%.(.+)$")) end
  local O = FO.new({ addonName = "CO_FontRowHost", get = function(path) return profile.callout[leaf(path)] end,
    set = function(path, v) profile.callout[leaf(path)] = v end })
  local rows = {}
  for _, r in ipairs((c:SchemaRows("callout.", { texts = false }))) do
    if r.path == "callout.font" then r.page, r.group = "general", "Look"; rows[1] = r end
  end
  local ctx = O.CreatePanel("CalloutFollowFontRow", "Call-out font row", {})
  O.RenderRows(ctx, rows)
  local picker
  for _, w in ipairs(FO.flatten(ctx.scroll)) do
    if w.labelText == "Font" then picker = w end
  end
  assertTrue(picker ~= nil, "the font row is drawn")
  assertEqual(picker.value, CALLOUT.FONT_SKIN, "the picker shows Skin font, not @skin")
  profile.callout.font = "Ka0s Bebas Neue"
  assertNil(rows[1].skinValue(rows[1]), "a picked face is shown as stored")
  -- The page outlives the case (the fixture's Options keeps its panels), and its widgets hold the
  -- row, whose closures hold this bench: empty the row so the bench release below can free it.
  for k in pairs(rows[1]) do rows[1][k] = nil end
end)

-- ── 97.13 and 97.14: the waypoint arrow's text ───────────────────────────────────────────────

local function skinnedArrow(record, hudText)
  return FA.newArrow({ skin = "TestAddon" }, function(m)
    m.STANDARD_TEXT_FONT = "Fonts\\GAME.TTF"
    local Skin = m.LibStub:NewLibrary("LibKa0s-Skin-1.0", 1)
    function Skin:Color() return nil end
    function Skin:For()
      return {
        HudFontSize = function(size) return size end,
        HudTextColor = function() if hudText then return hudText[1], hudText[2], hudText[3], 1 end end,
        HudFont = function(fs, opts)
          record[#record + 1] = opts
          fs:SetFont(opts.face or "Skin\\HUD.TTF", opts.size, opts.flags)
        end,
      }
    end
  end)
end

local function arrowText(a)
  local _, _, _, _, _, text = FA.parts(a)
  return text
end

test("arrow follow: the text color is the skin's HUD text color by default; class color first (97.13)", function()
  -- red under WaypointArrow minor 2: no fontColorFromSkin, the white swatch in every skin.
  local a, m = skinnedArrow({}, { 0.9, 0.8, 0.7 })
  assertEqual(a:Get("fontColorFromSkin"), true)
  a:SetProvider(function() return 100, 0 end, "Trainer")
  assertEqual(rgb3(arrowText(a):GetTextColor()), "0.900,0.800,0.700")
  a:Configure({ useClassColorFont = true })
  local cc = m.RAID_CLASS_COLORS[select(2, m.UnitClass("player"))]
  assertEqual(rgb3(arrowText(a):GetTextColor()), rgb3(cc.r, cc.g, cc.b), "Use class color comes first")
  a:Configure({ useClassColorFont = false, fontColorFromSkin = false, fontColor = { 0.1, 0.2, 0.3, 1 } })
  assertEqual(rgb3(arrowText(a):GetTextColor()), "0.100,0.200,0.300", "off: the swatch")
end)

test("arrow follow: a skin that answers no HUD text color leaves the swatch (97.13)", function()
  local a = skinnedArrow({}, nil)
  a:Configure({ fontColor = { 0.1, 0.2, 0.3, 1 } })
  a:SetProvider(function() return 100, 0 end, "Trainer")
  assertEqual(rgb3(arrowText(a):GetTextColor()), "0.100,0.200,0.300")
end)

test("arrow follow: the text shadow follows the skin unless Use the skin's shadow is off (97.14)", function()
  -- red under WaypointArrow minor 2: shadowFromSkin was the literal false.
  local record = {}
  local a = skinnedArrow(record)
  assertEqual(a:Get("fontShadowFromSkin"), true)
  a:SetProvider(function() return 100, 0 end, "Trainer")
  assertEqual(record[#record].shadowFromSkin, true)
  a:Configure({ fontShadowFromSkin = false })
  assertEqual(record[#record].shadowFromSkin, false, "off: the Font shadow row is the player's")
end)

test("arrow follow: the Text block carries the color and shadow companions at their rows' paths plus FromSkin", function()
  -- red under WaypointArrowSettings minor 2: neither companion had a row.
  local _, Arrow = FA.env()
  local paths = { font = "w.font", fontColor = "w.fontColor", fontShadow = "w.fontShadow" }
  local rows = Arrow.SettingsRows({ paths = paths })
  local by = {}
  for _, r in ipairs(rows) do by[r.key] = r end
  assertEqual(by.fontColorFromSkin.path, "w.fontColorFromSkin")
  assertEqual(by.fontShadowFromSkin.path, "w.fontShadowFromSkin")
  assertEqual(by.fontColorFromSkin.default, true)
  assertEqual(by.fontShadowFromSkin.default, true)
  assertNil(by.fontColor.disabledIf, "the swatch stays live")
  assertEqual(by.fontShadow.disabledIf, "w.fontShadowFromSkin", "Font shadow is not read while it is on")
  local O = dofile("tests/fixture_options.lua").new()
  local composed = Arrow.SettingsRows({ paths = paths, options = O })
  local cby = {}
  for _, r in ipairs(composed) do cby[r.key] = r end
  assertEqual(cby.fontColorFromSkin.path, "w.fontColorFromSkin", "the composer's row, kept")
  assertEqual(cby.fontShadowFromSkin.path, "w.fontShadowFromSkin")
  local a = Arrow:New({ addon = "TestAddon" })
  local store = { ["w.fontColorFromSkin"] = false, ["w.fontShadowFromSkin"] = false }
  a:ConfigureFrom(function(p) return store[p] end, paths)
  assertEqual(a:Get("fontColorFromSkin"), false, "ConfigureFrom reads them at the derived paths")
  assertEqual(a:Get("fontShadowFromSkin"), false)
end)

-- Last: let the bench go (the run's leak gate counts it until the end otherwise).
test("callout follow: the suite releases its bench", function()
  M, SKIN, CALLOUT = nil, nil, nil
  collectgarbage("collect")
  assertNil(M)
end)
