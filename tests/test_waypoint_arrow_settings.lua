-- tests/test_waypoint_arrow_settings.lua — WaypointArrowSettings.lua: the rows a host drops into its schema.
--
-- The rows carry the HOST's paths, so the cases hold them to the shape a LibKa0s-Schema-1.0
-- instance takes (its own shape check, and a write through it reaching the arrow).

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil

local F = dofile("tests/fixture_waypoint_arrow.lua")

local PATHS = {
  style = "waypoints.arrowStyle", useSkinColors = "waypoints.arrowSkinColors",
  farColor = "waypoints.arrowFar", nearColor = "waypoints.arrowNear", scale = "waypoints.arrowScale",
}

local function byKey(rows)
  local out = {}
  for _, r in ipairs(rows) do out[r.key] = r end
  return out
end

test("arrow settings: five rows in order, each on the host's path, page and group", function()
  local _, Arrow = F.env()
  local rows = Arrow.SettingsRows({ paths = PATHS, page = "trainers", group = "Waypoints", subgroup = "Arrow" })
  local keys, types = {}, {}
  for i, r in ipairs(rows) do
    keys[i], types[i] = r.key, r.type
    assertEqual(r.path, PATHS[r.key], r.key .. "'s path")
    assertEqual(r.page, "trainers")
    assertEqual(r.group, "Waypoints")
    assertEqual(r.subgroup, "Arrow")
    assertTrue(type(r.label) == "string" and type(r.desc) == "string", r.key .. " has words")
    assertTrue(type(r.onChange) == "function", r.key .. " has an onChange")
  end
  assertEqual(table.concat(keys, ","), "style,useSkinColors,farColor,nearColor,scale")
  assertEqual(table.concat(types, ","), "string,bool,color,color,number")
end)

test("arrow settings: the defaults are the arrow's: Raised, the skin's colors on, scale 1", function()
  local _, Arrow = F.env()
  local r = byKey(Arrow.SettingsRows({ paths = PATHS }))
  assertEqual(r.style.default, "raised")
  assertEqual(r.useSkinColors.default, true)
  assertEqual(r.scale.default, 1)
  assertEqual(table.concat(r.farColor.default, ","), "1,0.82,0,1", "{ r, g, b, a } by default")
  assertEqual(r.scale.min, 0.5)
  assertEqual(r.scale.max, 2)
  assertEqual(r.scale.step, 0.05)
end)

test("arrow settings: the style row offers the five looks by name", function()
  local _, Arrow = F.env()
  local r = byKey(Arrow.SettingsRows({ paths = PATHS }))
  local values, texts = {}, {}
  for i, v in ipairs(r.style.values) do values[i], texts[i] = v.value, v.text end
  assertEqual(table.concat(values, ","), "flat,ridge,raised,faceted,ground")
  assertEqual(table.concat(texts, ","), "Flat,Ridge,Raised,Faceted,On the ground")
end)

test("arrow settings: the color rows gray out while the skin's colors are drawn", function()
  local _, Arrow = F.env()
  local r = byKey(Arrow.SettingsRows({ paths = PATHS }))
  assertEqual(r.farColor.disabledIf, PATHS.useSkinColors)
  assertEqual(r.nearColor.disabledIf, PATHS.useSkinColors)
  assertNil(r.style.disabledIf)
  local noToggle = { farColor = "a.far", nearColor = "a.near" }
  assertNil(byKey(Arrow.SettingsRows({ paths = noToggle })).farColor.disabledIf, "no toggle row: nothing to gray on")
end)

test("arrow settings: a setting with no path has no row", function()
  local _, Arrow = F.env()
  local rows = Arrow.SettingsRows({ paths = { style = "x.style", scale = "x.scale" } })
  assertEqual(#rows, 2)
  assertEqual(#Arrow.SettingsRows({}), 0)
  assertEqual(#Arrow.SettingsRows(nil), 0)
end)

test("arrow settings: encodeColor shapes the color defaults the host's way", function()
  local _, Arrow = F.env()
  local r = byKey(Arrow.SettingsRows({ paths = PATHS,
    encodeColor = function(cr, cg, cb, ca) return { r = cr, g = cg, b = cb, a = ca } end }))
  assertEqual(r.nearColor.default.g, 0.80)
  assertNil(r.nearColor.default[1])
end)

test("arrow settings: opts.L overrides a word, read raw so a locale fallback never answers the key", function()
  local _, Arrow = F.env()
  local L = setmetatable({ FAR = "Lointain" }, { __index = function(_, k) return k end })
  local r = byKey(Arrow.SettingsRows({ paths = PATHS, L = L }))
  assertEqual(r.farColor.label, "Lointain")
  assertEqual(r.nearColor.label, "Near color", "an untranslated word stays English")
end)

test("arrow settings: a change configures the arrow, then tells the host", function()
  local a, _, Arrow = F.newArrow()
  local heard = {}
  local rows = a:SettingsRows({ paths = PATHS, onChange = function(k, v) heard[#heard + 1] = k .. "=" .. tostring(v) end })
  byKey(rows).style.onChange("ground")
  assertEqual(a:Get("style"), "ground", "the instance's rows configure it")
  assertEqual(heard[1], "style=ground")
  local plain = Arrow.SettingsRows({ paths = PATHS })
  byKey(plain).scale.onChange(1.25)   -- no arrow, no onChange: nothing raises
end)

test("arrow settings: the rows pass a Schema instance's shape check, and a write reaches the arrow", function()
  local a, m = F.newArrow()
  m.LibStub("LibKa0s-Core-1.0")
  local Schema = T.schema
  local db = { waypoints = {} }
  local rows = a:SettingsRows({ paths = PATHS, page = "p", group = "g" })
  for _, r in ipairs(rows) do db.waypoints[r.path:match("%.(.+)$")] = r.default end
  local printed = {}
  local S = Schema:New({ rows = rows, resolveRoot = function() return db, 1 end,
    print = function(line) printed[#printed + 1] = line end })
  assertEqual((S.Validate()), 0, "no shape problems: " .. table.concat(printed, " | "))
  S.Set(PATHS.style, "faceted")
  assertEqual(db.waypoints.arrowStyle, "faceted")
  assertEqual(a:Get("style"), "faceted", "the row's onChange configured the arrow")
  S.Set(PATHS.useSkinColors, false)
  S.Set(PATHS.farColor, { 0, 0, 1, 1 })
  local far = a:Colors()
  assertEqual(table.concat(far, ","), "0,0,1")
end)

test("arrow settings: ConfigureFrom reads the host's paths", function()
  local a = F.newArrow()
  local store = { ["waypoints.arrowStyle"] = "ridge", ["waypoints.arrowScale"] = 0.75 }
  a:ConfigureFrom(function(path) return store[path] end, PATHS)
  assertEqual(a:Get("style"), "ridge")
  assertEqual(a:Get("scale"), 0.75)
  assertEqual(a:Get("useSkinColors"), true, "an unset path reads the default")
end)

-- ── the Text block (minor 2, round 9 L2) ─────────────────────────────────────────────────────

local TEXT_PATHS = {
  font = "w.font", fontSize = "w.fontSize", fontColor = "w.fontColor", useClassColorFont = "w.fontClass",
  fontFlags = "w.fontFlags", fontShadow = "w.fontShadow", textPosition = "w.textPos",
  showLabel = "w.showLabel", distanceUnits = "w.units",
}

local TEXT_ORDER = "font,fontSize,fontColor,useClassColorFont,fontFlags,fontShadow,fontFromSkin,"
  .. "textPosition,showLabel,distanceUnits"

local function keysOf(rows)
  local out = {}
  for i, r in ipairs(rows) do out[i] = r.key end
  return table.concat(out, ",")
end

test("arrow settings: the Text block is the Font block's six rows, the companion, then three extras", function()
  local _, Arrow = F.env()
  local rows = Arrow.SettingsRows({ paths = TEXT_PATHS, page = "p", group = "g", subgroup = "Arrow" })
  assertEqual(keysOf(rows), TEXT_ORDER)
  local r = byKey(rows)
  assertEqual(r.fontFromSkin.path, "w.fontFromSkin", "the companion lives at the font path plus FromSkin")
  assertEqual(r.font.disabledIf, "w.fontFromSkin", "the picker grays while the skin's font is used")
  assertEqual(r.font.dialogControl, "Ka0sMedia_Font")
  assertEqual(r.font.default, "Ka0s Prototype")
  assertEqual(r.fontFromSkin.default, true)
  assertEqual(r.fontFlags.default, "@skin")
  assertEqual(r.fontFlags.values["@skin"], "From skin")
  assertEqual(r.fontShadow.default, true)
  assertEqual(r.fontSize.default, 12)
  assertEqual(r.textPosition.default, "BELOW")
  assertEqual(r.distanceUnits.default, "yards")
  assertEqual(r.showLabel.default, false)
  for _, k in ipairs({ "font", "fontColor", "fontFromSkin", "textPosition" }) do
    assertTrue(r[k].startsLine == true, k .. " starts its line")
  end
  assertEqual(r.useClassColorFont.label, "Use class color")
  assertEqual(r.textPosition.subgroup, "Arrow", "the host's subgroup")
  local values = {}
  for i, v in ipairs(r.textPosition.values) do values[i] = v.text end
  assertEqual(table.concat(values, ","), "Below,Above,Left,Right,Hidden")
end)

test("arrow settings: given an Options instance the Font rows are O.FontGroup's own", function()
  local O = dofile("tests/fixture_options.lua").new()
  local Arrow = T.arrow
  local L = { FONT_SHADOW = "Ombre" }
  local rows = Arrow.SettingsRows({ paths = TEXT_PATHS, options = O, page = "p", group = "g",
    textSubgroup = "Text", L = L })
  assertEqual(keysOf(rows), TEXT_ORDER, "the same keys in the same order")
  local own = Arrow.SettingsRows({ paths = TEXT_PATHS, page = "p", group = "g", textSubgroup = "Text" })
  for i, r in ipairs(rows) do
    assertEqual(r.path, own[i].path, r.key .. ": the same path either way")
    assertEqual(r.type, own[i].type, r.key .. ": the same type")
    assertEqual(r.subgroup, "Text", r.key .. ": on the Text subgroup")
    assertTrue(type(r.onChange) == "function", r.key .. ": the arrow's change route")
  end
  local r = byKey(rows)
  assertEqual(r.fontShadow.label, "Ombre", "opts.L overrides a composed word")
  assertEqual(r.fontSize.label, "Font size", "the composer's words for the rest")
  assertEqual(r.fontFlags.default, "@skin", "flagsFromSkin")
  assertEqual(r.fontShadow.default, true, "the arrow's default, not the composer's")
  assertTrue(type(r.font.skinValue) == "function", "the composer's skin-governed picker")
end)

test("arrow settings: a Text row's change configures the arrow", function()
  local a = F.newArrow()
  local r = byKey(a:SettingsRows({ paths = TEXT_PATHS }))
  r.textPosition.onChange("LEFT")
  r.fontFromSkin.onChange(false)
  assertEqual(a:Get("textPosition"), "LEFT")
  assertEqual(a:Get("fontFromSkin"), false)
end)

test("arrow settings: every row, the Text block's too, passes a Schema instance's shape check", function()
  local a = F.newArrow()
  local all = {}
  for k, v in pairs(PATHS) do all[k] = v end
  for k, v in pairs(TEXT_PATHS) do all[k] = v:gsub("^w%.", "waypoints.") end
  local rows = a:SettingsRows({ paths = all, page = "p", group = "g" })
  local db = { waypoints = {} }
  for _, r in ipairs(rows) do db.waypoints[r.path:match("%.(.+)$")] = r.default end
  local printed = {}
  local S = T.schema:New({ rows = rows, resolveRoot = function() return db, 1 end,
    print = function(line) printed[#printed + 1] = line end })
  assertEqual((S.Validate()), 0, "no shape problems: " .. table.concat(printed, " | "))
  S.Set("waypoints.units", "compact")
  assertEqual(a:Get("distanceUnits"), "compact")
end)

test("arrow settings: opts.L reaches the composed flags choices and the swatch's class-color sentence", function()
  local O = dofile("tests/fixture_options.lua").new()
  local L = { FLAGS_SKIN = "Du skin", FLAGS_NONE = "Aucun", CLASS_COLOR_NOTE = "Non lu en couleur de classe." }
  local r = byKey(T.arrow.SettingsRows({ paths = TEXT_PATHS, options = O, page = "p", group = "g", L = L }))
  assertEqual(r.fontFlags.values["@skin"], "Du skin", "a localized flags choice")
  assertEqual(r.fontFlags.values[""], "Aucun")
  assertEqual(r.fontFlags.values.OUTLINE, "Outline", "the rest in the US-English words")
  assertEqual(r.fontColor.tooltip, "The color the text is drawn in. Non lu en couleur de classe.",
    "the composer's English sentence replaced")
  local again = byKey(T.arrow.SettingsRows({ paths = TEXT_PATHS, options = O, page = "p", group = "g" }))
  assertEqual(again.fontFlags.values["@skin"], "From skin", "the composer's shared table untouched")
end)
