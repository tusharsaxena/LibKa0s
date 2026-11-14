-- tests/test_callout_glow.lua — LibKa0s-Callout-1.0's glow behind the text (plan row L15): Callout
-- minor 3's settings, which are AuraMaster's text glow (an on/off toggle, Glow color with its swatch,
-- Use class color, Use the skin's color, Intensity, Thickness, X and Y offset) drawn on the halo the
-- call-out has always drawn; the old Off / Soft / Strong choice read and migrated as the same look;
-- and CalloutSettings minor 4's Glow rows in SchemaRows and in the one tab's Look side tab.
--
-- The benches are tests/fixture_callout.lua's call-out, tests/fixture_options.lua's page, and a
-- stand-in LibKa0s-Skin-1.0 whose owner "tester" answers a glow color.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local F = dofile("tests/fixture_callout.lua")
local Fixture = dofile("tests/fixture_options.lua")
local newCallout, parts = F.newCallout, F.parts

local function rgb(r, g, b) return ("%.2f %.2f %.2f"):format(r, g, b) end

local SKIN_GLOW = { 1, 0.8, 0 }

--- A stand-in skin library: owner "tester" answers SKIN_GLOW as its glow color; `none` answers nil.
local function withSkin(m, none)
  local Skin = m.LibStub:NewLibrary("LibKa0s-Skin-1.0", 999)
  Skin.IsOwner = function(_, owner) return owner == "tester" end
  Skin.For = function()
    return { GetFont = function() return nil end,
      GlowColor = function()
        if none then return nil end
        return SKIN_GLOW[1], SKIN_GLOW[2], SKIN_GLOW[3], 1
      end }
  end
end

local function halo(c)
  local _, _, h = parts(c)
  return h
end

-- ── the defaults ─────────────────────────────────────────────────────────────────────────────

test("callout glow: on by default at the old soft look; the color companions all off", function()
  local c, _, _, _, Callout = newCallout()
  local D = Callout.DEFAULTS
  assertEqual(D.glow, true)
  assertEqual(D.glowIntensity, 0.35)
  assertEqual(D.glowThickness, 2)
  assertEqual(D.glowX .. "," .. D.glowY, "0,0")
  -- red under: any of the three color choices defaulting on
  assertFalse(D.glowCustom, "Glow color is off: the glow takes the kind color")
  assertFalse(D.useClassColorGlow, "Use class color is off")
  assertFalse(D.glowColorFromSkin, "Use the skin's color is off")
  for _, key in ipairs({ "glow", "glowIntensity", "glowThickness", "glowX", "glowY", "glowCustom", "glowColor",
    "useClassColorGlow", "glowColorFromSkin" }) do
    local listed = false
    for _, k in ipairs(Callout.SETTINGS) do if k == key then listed = true end end
    assertTrue(listed, key .. " is a setting Get and Set take")
  end
  c:Show("GO")
  local h = halo(c)
  assertEqual(rgb(h:GetTextColor()), rgb(unpack(D.colors.go)), "the halo is in the kind's color")
  assertEqual(h:GetAlpha(), 0.35)
end)

test("callout glow: the setting rules refuse what is out of range", function()
  local c = newCallout()
  assertFalse(c:Set("glow", "bright"), "the toggle is a boolean or an old choice")
  assertFalse(c:Set("glowIntensity", 0.01))
  assertFalse(c:Set("glowIntensity", 1.5))
  assertFalse(c:Set("glowThickness", 0))
  assertFalse(c:Set("glowThickness", 7))
  assertFalse(c:Set("glowX", 21))
  assertFalse(c:Set("glowY", -21))
  assertFalse(c:Set("glowColor", { 1, 2 }))
  assertFalse(c:Set("useClassColorGlow", "yes"))
  assertTrue(c:Set("glowIntensity", 0.05))
  assertTrue(c:Set("glowThickness", 6))
end)

-- ── the drawing ──────────────────────────────────────────────────────────────────────────────

test("callout glow: intensity is the halo's alpha, thickness its size over the text, the offsets its point", function()
  local c = newCallout()
  c:Show("STOP")
  local h = halo(c)
  c:Set("glowIntensity", 0.8)
  c:Set("glowThickness", 4)
  c:Set("glowX", 3)
  c:Set("glowY", -6)
  assertEqual(h:GetAlpha(), 0.8)
  assertEqual(select(2, h:GetFont()), 96 + 8, "4 px out on every side")
  assertEqual(select(3, h:GetFont()), "THICKOUTLINE")
  local point, rel, relPoint, x, y = h:GetPoint(1)
  assertEqual(point .. "," .. relPoint .. "," .. x .. "," .. y, "CENTER,CENTER,3,-6")
  assertTrue(rel ~= nil, "anchored to the content frame")
  assertEqual(h:GetNumPoints(), 1, "a re-apply moves the one point, it does not add one")
  c:Set("glow", false)
  assertEqual(h:GetAlpha(), 0, "off: nothing shows")
  assertEqual(c:Look().glow, false)
  assertEqual(c:Look().glowThickness, 4)
end)

test("callout glow: no OnUpdate is armed for the glow; it is painted with the call-out", function()
  local c, m = newCallout()
  c:Set("glowThickness", 3)
  assertNil(F.clock(m), "a write arms nothing")
end)

-- ── the color ────────────────────────────────────────────────────────────────────────────────

test("callout glow: Glow color draws the swatch; off, the kind's color", function()
  local c = newCallout()
  c:Show("WARNING")
  local h = halo(c)
  assertTrue(c:Set("glowColor", { 0.1, 0.2, 0.3 }))
  assertEqual(rgb(h:GetTextColor()), rgb(1, 0.78, 0.2), "the swatch alone does nothing")
  assertTrue(c:Set("glowCustom", true))
  assertEqual(rgb(h:GetTextColor()), rgb(0.1, 0.2, 0.3), "Glow color on: the swatch")
  assertEqual(rgb(c:GetGlowColor("warn")), rgb(0.1, 0.2, 0.3))
  local _, text = parts(c)
  assertEqual(rgb(text:GetTextColor()), rgb(1, 0.78, 0.2), "the text keeps its kind's color")
end)

test("callout glow: class over skin over the swatch over the kind, each falling through when it answers nothing", function()
  local c, m, db = newCallout({ skin = "tester" }, withSkin)
  c:Show("GO")
  local h = halo(c)
  local mage = m.RAID_CLASS_COLORS[m.__context.classToken]
  db.glowCustom, db.glowColor = true, { 0.1, 0.2, 0.3 }
  db.glowColorFromSkin, db.useClassColorGlow = true, true
  c:Apply()
  assertEqual(rgb(h:GetTextColor()), rgb(mage.r, mage.g, mage.b), "class wins")
  db.useClassColorGlow = false
  c:Apply()
  assertEqual(rgb(h:GetTextColor()), rgb(unpack(SKIN_GLOW)), "then the skin's glow color")
  db.glowColorFromSkin = false
  c:Apply()
  assertEqual(rgb(h:GetTextColor()), rgb(0.1, 0.2, 0.3), "then the swatch")
  db.glowCustom = false
  c:Apply()
  assertEqual(rgb(h:GetTextColor()), rgb(0.3, 1, 0.45), "then the kind's color")
  -- A class the client does not answer for falls to the next: the skin.
  local c2, _, db2 = newCallout({ skin = "tester" }, function(mm) withSkin(mm); mm.__context.classToken = "BROKEN" end)
  db2.useClassColorGlow, db2.glowColorFromSkin = true, true
  c2:Show("GO")
  assertEqual(rgb(halo(c2):GetTextColor()), rgb(unpack(SKIN_GLOW)), "no class color: the skin's")
end)

test("callout glow: the skin's color needs a registered owner answering one, else it falls through", function()
  local c, _, db = newCallout(nil, withSkin)           -- no d.skin
  db.glowColorFromSkin = true
  c:Show("GO")
  assertEqual(rgb(halo(c):GetTextColor()), rgb(0.3, 1, 0.45), "no owner: the kind's color")
  local c2, _, db2 = newCallout({ skin = "tester" }, function(m) withSkin(m, true) end)
  db2.glowColorFromSkin, db2.glowCustom, db2.glowColor = true, true, { r = 0.5, g = 0.5, b = 0.5 }
  c2:Show("GO")
  assertEqual(rgb(halo(c2):GetTextColor()), rgb(0.5, 0.5, 0.5), "a skin with no glow color: the swatch")
end)

test("callout glow: a glow color in either shape is stored in the instance's", function()
  local c, _, db = newCallout()
  assertTrue(c:Set("glowColor", { r = 0.2, g = 0.4, b = 0.6, a = 1 }))
  assertEqual(table.concat(db.glowColor, ","), "0.2,0.4,0.6", "off the route: the array")
  local host = {}
  local c2 = newCallout({ path = "co.", set = function(path, v) host[path] = v; return true end })
  assertTrue(c2:Set("glowColor", { 0.2, 0.4, 0.6 }))
  local v = host["co.glowColor"]
  assertEqual(v.r .. "," .. v.g .. "," .. v.b, "0.2,0.4,0.6", "on the route: the named shape")
end)

-- ── the old choice ───────────────────────────────────────────────────────────────────────────

test("callout glow: a stored off / soft / strong reads as the same look it drew", function()
  for name, want in pairs({ off = { false, 0 }, soft = { true, 0.35, 100 }, strong = { true, 0.7, 106 } }) do
    local c, _, db = newCallout()
    db.glow = name
    c:Show("GO")
    local h = halo(c)
    assertEqual(c:Get("glow"), want[1], name .. ": the toggle")
    assertEqual(h:GetAlpha(), want[2], name .. ": the alpha")
    if want[3] then assertEqual(select(2, h:GetFont()), want[3], name .. ": the size at 96") end
    assertEqual(db.glow, name, name .. ": never rewritten by a read")
  end
  local c, _, db = newCallout()
  db.glow, db.glowIntensity = "strong", 0.5
  c:Show("GO")
  assertEqual(halo(c):GetAlpha(), 0.5, "a setting stored on its own wins over the old choice")
end)

test("callout glow: Set takes an old choice and writes it as the new keys; Get answers the boolean", function()
  -- red under: Set refusing "soft" (v1.98.0 callers break), or storing the string itself
  local c, _, db = newCallout()
  db.glowIntensity = 0.9
  assertTrue(c:Set("glow", "strong"), "a v1.98.0 caller's write lands")
  assertEqual(db.glow, true)
  assertEqual(db.glowIntensity, 0.7, "the choice is the player's, so it overwrites")
  assertEqual(db.glowThickness, 5)
  assertEqual(c:Get("glow"), true, "Get answers the boolean")
  assertEqual(c:Look().glow, true)
  assertTrue(c:Set("glow", "off"))
  assertEqual(db.glow, false)
  assertEqual(db.glowThickness, 5, "off names no thickness")
  local host = {}
  local c2 = newCallout({ path = "co.", set = function(path, v) host[path] = v; return true end })
  assertTrue(c2:Set("glow", "soft"))
  assertEqual(host["co.glow"], true, "on the host's route too")
  assertEqual(host["co.glowIntensity"], 0.35)
  assertEqual(host["co.glowThickness"], 2)
  local c3 = newCallout({ path = "co.", set = function() return false end })
  assertFalse(c3:Set("glow", "soft"), "a refused write answers false")
end)

test("callout glow: MigrateGlow rewrites the old choice as the new keys, once", function()
  local _, _, _, _, Callout = newCallout()
  local strong = { glow = "strong" }
  assertTrue(Callout:MigrateGlow(strong))
  assertEqual(strong.glow, true)
  assertEqual(strong.glowIntensity, 0.7)
  assertEqual(strong.glowThickness, 5)
  assertFalse(Callout:MigrateGlow(strong), "a migrated table is left alone")
  local off = { glow = "off", glowThickness = 3 }
  assertTrue(Callout:MigrateGlow(off))
  assertEqual(off.glow, false)
  assertEqual(off.glowThickness, 3, "a valid stored setting is kept")
  assertNil(off.glowIntensity, "off implies no intensity")
  local kept = { glow = "soft", glowIntensity = 0.9 }
  Callout:MigrateGlow(kept)
  assertEqual(kept.glowIntensity, 0.9)
  assertFalse(Callout:MigrateGlow(nil))
  assertFalse(Callout:MigrateGlow({}))
end)

-- ── the rows ─────────────────────────────────────────────────────────────────────────────────

local GLOW_ROWS = { "glow", "glowCustom", "glowColor", "useClassColorGlow", "glowColorFromSkin", "glowIntensity",
  "glowThickness", "glowX", "glowY" }

test("callout glow: SchemaRows carries every glow row with its path, default, bounds, validate and onChange", function()
  local c, _, _, _, Callout = newCallout()
  local by = {}
  for _, r in ipairs(c:SchemaRows("callout.", { texts = false })) do by[r.path] = r end
  local applied = 0
  local apply = c.Apply
  c.Apply = function(self) applied = applied + 1; return apply(self) end
  for _, key in ipairs(GLOW_ROWS) do
    local r = by["callout." .. key]
    assertTrue(r ~= nil, key .. " has a row")
    assertEqual(r.key, key)
    assertEqual(r.tab, "look", key .. " is on Look")
    assertEqual(r.subgroup, "Glow", key .. " is under Glow")
    assertTrue(r.validate(r.default), key .. "'s default passes its validate")
    r.onChange()
  end
  assertEqual(applied, #GLOW_ROWS, "every row's onChange is the instance's Apply")
  for key, w in pairs({ glowIntensity = { 0.05, 1, 0.05 }, glowThickness = { 1, 6, 1 }, glowX = { -20, 20, 1 },
    glowY = { -20, 20, 1 } }) do
    local r = by["callout." .. key]
    assertEqual(r.min .. "," .. r.max .. "," .. r.step, table.concat(w, ","), key .. "'s bounds")
  end
  assertTrue(by["callout.glowIntensity"].isPercent, "Intensity reads as a percent")
  assertEqual(by["callout.glow"].default, true)
  for _, key in ipairs({ "glowCustom", "useClassColorGlow", "glowColorFromSkin" }) do
    assertEqual(by["callout." .. key].default, false, key .. " defaults off")
  end
  local color = by["callout.glowColor"]
  assertEqual(color.type, "color")
  assertEqual(color.default.r .. "," .. color.default.g .. "," .. color.default.b, table.concat(Callout.DEFAULTS.glowColor, ","))
  assertEqual(type(color.get), "function", "the swatch reads either stored shape")
  assertFalse(by["callout.glowIntensity"].validate(2))
  assertNil(by["callout.glow"].values, "the toggle is no list")
end)

test("callout glow: AuraMaster's two columns; the swatch and its class companion never dim", function()
  local c, _, db = newCallout()
  local rows = {}
  for _, r in ipairs(c:SettingsRows({ texts = false, tab = "look" })) do
    if r.subgroup == "Glow" then rows[#rows + 1] = r end
  end
  local order, starts = {}, {}
  for i, r in ipairs(rows) do order[i] = r.key; starts[i] = r.startsLine and "|" or "" end
  assertEqual(table.concat(order, ","), table.concat(GLOW_ROWS, ","))
  -- [Glow behind the text][Glow color] / [Color][Use class color] / [Use the skin's color] /
  -- [Intensity][Thickness (px)] / [X offset][Y offset]
  assertEqual(table.concat(starts, ","), "|,,|,,|,|,,|,")
  assertEqual(rows[3].label .. "/" .. rows[4].label, "Color/Use class color", "options-ui-§17's adjacent pair")
  db.glow = false
  for _, r in ipairs(rows) do
    local dims = r.key ~= "glow" and r.key ~= "glowColor" and r.key ~= "useClassColorGlow"
    if dims then
      assertTrue(r.disabledIf(), r.key .. " dims while the glow is off")
    else
      assertNil(r.disabledIf, r.key .. " never dims")
    end
  end
  db.glow = true
  assertFalse(rows[2].disabledIf())
end)

test("callout glow: the one tab's Look draws the Glow rows beside Colors, and a write reaches the halo", function()
  local c, _, db = newCallout()
  local O = Fixture.new()
  local ctx = O.CreatePanel("CalloutGlowBench", "Callout glow", {})
  local scroll = O.EnsureScroll(ctx)
  c:BuildSettings(ctx, { options = O, layout = "side" })
  local heads, labels = {}, {}
  for _, w in ipairs(Fixture.flatten(scroll)) do
    if w.type == "Heading" then heads[#heads + 1] = w.text end
    if w.labelText then labels[w.labelText] = w end
  end
  assertEqual(table.concat(heads, ","), "Preview,Glow,Colors", "Glow sits right before Colors in Look")
  for _, label in ipairs({ "Glow behind the text", "Glow color", "Color", "Use class color", "Use the skin's color",
    "Intensity", "Thickness (px)", "X offset", "Y offset" }) do
    assertTrue(labels[label] ~= nil, label .. " is drawn in Look")
  end
  assertNil(labels.Glow, "no Off / Soft / Strong dropdown")
  labels["Thickness (px)"]:__fire("OnMouseUp", 5)
  assertEqual(db.glowThickness, 5)
  assertEqual(select(2, halo(c):GetFont()), 106)
end)

test("callout glow: the plain build draws the intensity as a percent", function()
  local c, m = newCallout()
  local parent = m.CreateFrame("Frame", nil, m.UIParent)
  local view = c:BuildSettings(parent, { layout = "side" })
  for _, ctl in ipairs(view.controls) do
    if ctl.row.key == "glowIntensity" then
      assertEqual(ctl.control.text:GetText(), "35%")
    end
  end
end)
