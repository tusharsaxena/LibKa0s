-- tests/test_options_compose_flags.lua -- FontGroup's "From skin" Font flags (OptionsCompose minor 14;
-- LK-04 of Ka0sAddonsCommonTasks docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK, the owner's ruling D-07).
--
-- A suite of its own: tests/test_options_compose.lua was in the band when these were written, and
-- has since peeled its record-backed arm to tests/test_options_compose_arm.lua.
--
-- What is pinned:
--
--   * WITHOUT `flagsFromSkin` FontGroup's Font flags row is minor 13's: the same values, order,
--     default and tooltip, and no "From skin".
--   * WITH IT the row leads with "From skin" (the Skin major's FROM_SKIN), defaults to it, keeps every
--     other flag in its order, and says what it follows; the shared lists are never written to.
--   * WITH `fromSkin = true` as well the block is the minimum font setting (D-07): face, size, color
--     and its class-color companion, flags with From skin, shadow, and "Use the skin's font".
--   * `omit`, `keys`, `defaults` and `labels` reach the row as they reach any leaf.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil
local Fixture = dofile("tests/fixture_options.lua")
local Skin = T.skin

local function rowAt(rows, path)
  for _, r in ipairs(rows) do if (r.path or r.field) == path then return r end end
  return nil
end

local function paths(rows)
  local out = {}
  for i, r in ipairs(rows) do out[i] = r.path or r.field end
  return table.concat(out, ",")
end

local function host()
  local O = Fixture.new({ addonName = "ComposeFlagsHost" })
  return O
end

test("compose flags: OptionsCompose is at minor 14 or later", function()
  assertTrue(T.options.MODULES.OptionsCompose >= 14)
end)

test("compose flags: without flagsFromSkin the Font flags row is minor 13's", function()
  local O = host()
  local row = rowAt(O.FontGroup({ prefix = "t." }), "t.fontFlags")
  assertEqual(row.default, "OUTLINE")
  assertEqual(table.concat(row.sorting, "|"), "|OUTLINE|THICKOUTLINE|MONOCHROME|OUTLINE, MONOCHROME")
  assertNil(row.values["@skin"], "no From skin in the plain list")
  assertEqual(row.tooltip, "Outline and monochrome rendering.")
  assertTrue(row.values == O.FONT_FLAGS and row.sorting == O.FONT_FLAGS_SORT, "the published lists, as before")
end)

test("compose flags: flagsFromSkin leads with From skin and defaults to it", function()
  -- red under: FontGroup ignoring spec.flagsFromSkin (the row keeps OUTLINE as its default).
  local O = host()
  local row = rowAt(O.FontGroup({ prefix = "t.", flagsFromSkin = true }), "t.fontFlags")
  assertEqual(Skin.FROM_SKIN, "@skin", "the value is the Skin major's sentinel")
  assertEqual(row.default, "@skin", "From skin is the default")
  assertEqual(row.values["@skin"], "From skin")
  assertEqual(table.concat(row.sorting, "|"), "@skin||OUTLINE|THICKOUTLINE|MONOCHROME|OUTLINE, MONOCHROME",
    "first, then every flag in its order")
  for k, v in pairs(O.FONT_FLAGS) do assertEqual(row.values[k], v, "the flag " .. k .. " is offered as before") end
  assertTrue(row.tooltip:find("Font outline", 1, true) ~= nil, "the tooltip names what From skin follows")
  assertNil(O.FONT_FLAGS["@skin"], "the published list is not written to")
  assertEqual(#O.FONT_FLAGS_SORT, 5, "nor its order")
end)

test("compose flags: fromSkin and flagsFromSkin together are the minimum font setting", function()
  local O = host()
  local rows = O.FontGroup({ prefix = "t.", fromSkin = true, flagsFromSkin = true })
  assertEqual(paths(rows), "t.font,t.fontSize,t.fontColor,t.useClassColorFont,t.fontFlags,t.fontShadow,t.fontFromSkin",
    "face, size, color, class color, flags, shadow, and Use the skin's font")
  assertEqual(rowAt(rows, "t.fontFlags").default, "@skin")
  assertEqual(rowAt(rows, "t.fontFromSkin").label, "Use the skin's font")
  assertEqual(rowAt(rows, "t.useClassColorFont").type, "bool")
end)

test("compose flags: omit, keys, defaults and labels reach the From skin row", function()
  local O = host()
  local rows = O.FontGroup({ prefix = "t.", flagsFromSkin = true, keys = { fontFlags = "outline" },
    labels = { fontFlags = "Outline" } })
  local row = rowAt(rows, "t.outline")
  assertEqual(row.label, "Outline"); assertEqual(row.default, "@skin")
  row = rowAt(O.FontGroup({ prefix = "t.", flagsFromSkin = true, defaults = { fontFlags = "" } }), "t.fontFlags")
  assertEqual(row.default, "", "a host default wins")
  assertNil(rowAt(O.FontGroup({ prefix = "t.", flagsFromSkin = true, omit = { fontFlags = true } }), "t.fontFlags"))
end)
