-- tests/test_options_compose_follow.lua -- the group composers start on the skin unless the host opts
-- out (OptionsCompose minor 20; SD-LK-97.6 to SD-LK-97.9 of Ka0sAddonsCommonTasks
-- docs/2026-11-20-SKIN_DEFAULTS_AUDIT, LibKa0s#97, the owner's ruling R-2).
--
-- What is pinned:
--
--   * WITH NO `fromSkin`, FontGroup, BorderGroup and BarGroup emit their picker's `<key>FromSkin`
--     companion, default true and governing the picker, as `fromSkin = true` did (97.6, 97.9).
--   * WITH NO `flagsFromSkin`, Font flags leads with From skin and defaults to it (97.7).
--   * EVERY SWATCH gets a `<color key>FromSkin` companion and Font shadow a `fontShadowFromSkin`, bool
--     rows defaulting true (97.8). A swatch stays live (options-ui-§17); Font shadow is not read while
--     its companion is on, so it is disabled meanwhile.
--   * THE OPT-OUT: `fromSkin = false` is minor 19's block, byte for byte; `flagsFromSkin = false`,
--     `colorFromSkin = false` and `shadowFromSkin = false` each take one part back.
--   * A HOST THAT ALREADY WRITES a companion in `extra` keeps its own row and gets no second one.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local Fixture = dofile("tests/fixture_options.lua")
local Skin = T.skin

local OWNER = "ComposeFollowHost"

local function rowAt(rows, path)
  for _, r in ipairs(rows) do if (r.path or r.field) == path then return r end end
  return nil
end

local function paths(rows)
  local out = {}
  for i, r in ipairs(rows) do out[i] = r.path or r.field end
  return table.concat(out, ",")
end

local function count(rows, path)
  local n = 0
  for _, r in ipairs(rows) do if (r.path or r.field) == path then n = n + 1 end end
  return n
end

local function host()
  local O, rec = Fixture.new({ addonName = OWNER })
  return O, rec
end

test("compose follow: OptionsCompose is at minor 20", function()
  -- red under: the change landing without its bump: a minor-19 copy loaded first would keep every
  -- group off the skin for a host that never asked.
  assertEqual(T.options.MODULES.OptionsCompose, 20)
end)

-- ── SD-LK-97.6: the font picker follows the skin by default ─────────────────────────────────

test("compose follow: FontGroup with no fromSkin emits Use the skin's font, on and governing the picker", function()
  -- red under minor 19: no fontFromSkin row without an opt-in.
  local O = host()
  local rows = O.FontGroup({ prefix = "t." })
  local c = rowAt(rows, "t.fontFromSkin")
  assertTrue(c ~= nil, "the companion is emitted")
  assertEqual(c.type, "bool")
  assertEqual(c.label, "Use the skin's font")
  assertEqual(c.default, true)
  assertTrue(c.startsLine, "the first companion opens its own line")
  assertEqual(rowAt(rows, "t.font").disabledIf, "t.fontFromSkin", "the picker follows it")
  assertEqual(type(rowAt(rows, "t.font").skinValue), "function", "and shows the skin's face meanwhile")
end)

-- ── SD-LK-97.7: Font flags From skin by default ─────────────────────────────────────────────

test("compose follow: FontGroup with no flagsFromSkin leads Font flags with From skin and defaults to it", function()
  -- red under minor 19: the row defaulted to OUTLINE and offered no From skin.
  local O = host()
  local row = rowAt(O.FontGroup({ prefix = "t." }), "t.fontFlags")
  assertEqual(row.default, Skin.FROM_SKIN)
  assertEqual(row.values[Skin.FROM_SKIN], "From skin")
  assertEqual(row.sorting[1], Skin.FROM_SKIN)
  assertTrue(row.tooltip:find("Font outline", 1, true) ~= nil, "the tooltip says what it follows")
  row = rowAt(O.FontGroup({ prefix = "t.", fromSkin = true }), "t.fontFlags")
  assertEqual(row.default, Skin.FROM_SKIN, "fromSkin = true alone now carries it too")
end)

test("compose follow: flagsFromSkin = false is minor 19's typed Font flags row", function()
  local O = host()
  local row = rowAt(O.FontGroup({ prefix = "t.", flagsFromSkin = false }), "t.fontFlags")
  assertEqual(row.default, "OUTLINE")
  assertNil(row.values[Skin.FROM_SKIN])
  assertTrue(row.values == O.FONT_FLAGS and row.sorting == O.FONT_FLAGS_SORT, "the published lists")
  assertEqual(row.tooltip, "Outline and monochrome rendering.")
  assertTrue(rowAt(O.FontGroup({ prefix = "t.", flagsFromSkin = false }), "t.fontFromSkin") ~= nil,
    "and the face still follows")
end)

-- ── SD-LK-97.8: a companion for every swatch and for Font shadow ────────────────────────────

test("compose follow: FontGroup emits Use the skin's color and Use the skin's shadow, both on", function()
  -- red under minor 19: neither row existed; every host hand-wrote them in `extra`.
  local O = host()
  local rows = O.FontGroup({ prefix = "t." })
  assertEqual(paths(rows), "t.font,t.fontSize,t.fontColor,t.useClassColorFont,t.fontFlags,t.fontShadow,"
    .. "t.fontFromSkin,t.fontColorFromSkin,t.fontShadowFromSkin", "after the canonical six")
  local color, shadow = rowAt(rows, "t.fontColorFromSkin"), rowAt(rows, "t.fontShadowFromSkin")
  assertEqual(color.type, "bool"); assertEqual(color.default, true)
  assertEqual(color.label, "Use the skin's color")
  assertTrue(color.tooltip:find("Use class color comes first", 1, true) ~= nil, "class color leads")
  assertEqual(shadow.type, "bool"); assertEqual(shadow.default, true)
  assertEqual(shadow.label, "Use the skin's shadow")
  assertNil(color.startsLine, "the color companion pairs beside the font's")
  assertTrue(shadow.startsLine, "and the shadow's opens the next line")
end)

test("compose follow: the swatch stays live and Font shadow is disabled while its companion is on", function()
  local O, rec = host()
  local rows = O.FontGroup({ prefix = "t." })
  local swatch, shadow = rowAt(rows, "t.fontColor"), rowAt(rows, "t.fontShadow")
  assertNil(swatch.disabledIf, "options-ui-§17: a companion puts no disabledIf on a swatch")
  assertNil(swatch.skinValue)
  assertEqual(shadow.disabledIf, "t.fontShadowFromSkin", "Font shadow is not read while it is on")
  rec.store["t.fontShadow"] = false
  assertNil(shadow.skinValue(shadow), "companion unset: the stored toggle shows")
end)

test("compose follow: BarGroup, BorderGroup and ColorPair carry a color companion after their picker's", function()
  -- red under minor 19 (97.8 and 97.9): no companion at all without fromSkin.
  local O = host()
  local bar = O.BarGroup({ prefix = "r." })
  assertEqual(paths(bar), "r.barTexture,r.barAlpha,r.barColor,r.useClassColorBar,r.barTextureFromSkin,r.barColorFromSkin")
  assertEqual(rowAt(bar, "r.barTexture").disabledIf, "r.barTextureFromSkin", "97.9: the texture follows")
  assertEqual(rowAt(bar, "r.barColorFromSkin").default, true)
  local border = O.BorderGroup({ prefix = "b." })
  assertEqual(paths(border),
    "b.borderStyle,b.borderSize,b.borderColor,b.useClassColorBorder,b.borderStyleFromSkin,b.borderColorFromSkin")
  assertEqual(rowAt(border, "b.borderStyleFromSkin").default, true, "97.9: the border style follows")
  assertNil(rowAt(border, "b.borderSize").disabledIf, "the plain family leaves the thickness the player's")
  local pair = O.ColorPair({ prefix = "c.", key = "bgColor", label = "Background color" })
  assertEqual(paths(pair), "c.bgColor,c.useClassColorBgColor,c.bgColorFromSkin")
  local c = rowAt(pair, "c.bgColorFromSkin")
  assertEqual(c.default, true); assertEqual(c.label, "Use the skin's color"); assertTrue(c.startsLine)
  assertTrue(c.tooltip:find("Background color", 1, true) ~= nil, "it names the swatch it governs")
end)

-- ── the opt-out ─────────────────────────────────────────────────────────────────────────────

test("compose follow: fromSkin = false is minor 19's block for all four composers", function()
  local O = host()
  assertEqual(paths(O.FontGroup({ prefix = "t.", fromSkin = false })),
    "t.font,t.fontSize,t.fontColor,t.useClassColorFont,t.fontFlags,t.fontShadow")
  assertEqual(rowAt(O.FontGroup({ prefix = "t.", fromSkin = false }), "t.fontFlags").default, "OUTLINE",
    "the flags are typed too")
  assertEqual(paths(O.BorderGroup({ prefix = "b.", fromSkin = false })),
    "b.borderStyle,b.borderSize,b.borderColor,b.useClassColorBorder")
  assertEqual(paths(O.BarGroup({ prefix = "r.", fromSkin = false })), "r.barTexture,r.barAlpha,r.barColor,r.useClassColorBar")
  assertEqual(paths(O.ColorPair({ prefix = "c.", fromSkin = false })), "c.color,c.useClassColorColor")
  for _, r in ipairs(O.FontGroup({ prefix = "t.", fromSkin = false })) do
    assertNil(r.disabledIf, (r.path or "?") .. " carries no disabledIf")
    assertNil(r.skinValue, (r.path or "?") .. " carries no skinValue")
  end
  local typed = rowAt(O.FontGroup({ prefix = "t.", fromSkin = false, flagsFromSkin = true }), "t.fontFlags")
  assertEqual(typed.default, Skin.FROM_SKIN, "an explicit flagsFromSkin = true still wins")
end)

test("compose follow: colorFromSkin = false and shadowFromSkin = false each take one part back", function()
  local O = host()
  assertEqual(paths(O.FontGroup({ prefix = "t.", colorFromSkin = false })),
    "t.font,t.fontSize,t.fontColor,t.useClassColorFont,t.fontFlags,t.fontShadow,t.fontFromSkin,t.fontShadowFromSkin")
  local rows = O.FontGroup({ prefix = "t.", shadowFromSkin = false })
  assertEqual(paths(rows),
    "t.font,t.fontSize,t.fontColor,t.useClassColorFont,t.fontFlags,t.fontShadow,t.fontFromSkin,t.fontColorFromSkin")
  assertNil(rowAt(rows, "t.fontShadow").disabledIf, "an opted-out shadow is the player's")
  assertEqual(paths(O.BarGroup({ prefix = "r.", colorFromSkin = false })),
    "r.barTexture,r.barAlpha,r.barColor,r.useClassColorBar,r.barTextureFromSkin")
  assertEqual(paths(O.ColorPair({ prefix = "c.", colorFromSkin = false })), "c.color,c.useClassColorColor",
    "a class or meaning color takes no companion")
end)

test("compose follow: omit, defaults, labels and keys reach every companion", function()
  local O = host()
  local rows = O.FontGroup({ prefix = "t.", omit = { fontColorFromSkin = true, fontShadow = true },
    defaults = { fontFromSkin = false }, labels = { fontFromSkin = "Skin face" } })
  assertNil(rowAt(rows, "t.fontColorFromSkin"), "omitted")
  assertNil(rowAt(rows, "t.fontShadowFromSkin"), "no Font shadow row, no companion for it")
  assertEqual(rowAt(rows, "t.fontFromSkin").default, false, "a host default wins")
  assertEqual(rowAt(rows, "t.fontFromSkin").label, "Skin face")
  local renamed = O.FontGroup({ prefix = "t.", keys = { fontColor = "textColor", fontShadow = "shadow" } })
  assertTrue(rowAt(renamed, "t.textColorFromSkin") ~= nil, "the companion sits beside the swatch's stored key")
  assertTrue(rowAt(renamed, "t.shadowFromSkin") ~= nil, "and beside the shadow's")
  local own = O.FontGroup({ prefix = "t.", keys = { fontColor = "textColor", fontColorFromSkin = "fontColorFromSkin" } })
  assertTrue(rowAt(own, "t.fontColorFromSkin") ~= nil, "keys names the companion's own stored key")
  assertNil(rowAt(own, "t.textColorFromSkin"))
end)

-- ── a host that already writes the companions ───────────────────────────────────────────────

test("compose follow: a companion the host writes in extra is kept and not emitted twice", function()
  -- The Combat Trail and Absorb Tracker shape at v1.107.0: fromSkin, flagsFromSkin and two
  -- hand-written companions in `extra`.
  local O = host()
  local mine = { path = "t.fontColorFromSkin", type = "bool", label = "Mine", default = true, startsLine = true }
  local rows = O.FontGroup({ prefix = "t.", fromSkin = true, flagsFromSkin = true, extra = {
    mine, { path = "t.fontShadowFromSkin", type = "bool", label = "Mine too", default = true } } })
  assertEqual(count(rows, "t.fontColorFromSkin"), 1, "one color companion")
  assertEqual(count(rows, "t.fontShadowFromSkin"), 1, "one shadow companion")
  assertEqual(rowAt(rows, "t.fontColorFromSkin").label, "Mine", "the host's own row")
  assertEqual(rowAt(rows, "t.fontShadow").disabledIf, "t.fontShadowFromSkin", "governed by the host's row")
  assertEqual(paths(rows), "t.font,t.fontSize,t.fontColor,t.useClassColorFont,t.fontFlags,t.fontShadow,"
    .. "t.fontFromSkin,t.fontColorFromSkin,t.fontShadowFromSkin")
  local bound = O.BarGroup({ extra = { { field = "barColorFromSkin", type = "bool", label = "Mine" } },
    bind = { record = function() return {} end, set = function() end } })
  assertEqual(count(bound, "barColorFromSkin"), 1, "a bound extra's field counts as declared")
end)

test("compose follow: a record-backed group binds its companions to the record", function()
  local rec = { fontShadow = true }
  local O = host()
  local rows = O.FontGroup({ bind = { record = function() return rec end,
    set = function(field, value) rec[field] = value end } })
  local color, shadow = rowAt(rows, "fontColorFromSkin"), rowAt(rows, "fontShadowFromSkin")
  assertTrue(color ~= nil and color.path == nil, "the color companion is a record field")
  assertTrue(shadow ~= nil and shadow.path == nil, "and the shadow's")
  shadow.set(false)
  assertEqual(rec.fontShadowFromSkin, false)
  local shadowRow = rowAt(rows, "fontShadow")
  assertEqual(shadowRow.disabledIf, "fontShadowFromSkin")
end)

test("compose follow: a rendered block draws the companions and Font shadow follows its own", function()
  if not Skin:IsOwner(OWNER) then Skin:RegisterOwner(OWNER) end
  local O, rec = host()
  local rows = O.FontGroup({ prefix = "f.", page = "general", group = "Text" })
  local ctx = O.CreatePanel("ComposeFollow1", "Compose follow", {})
  O.RenderRows(ctx, rows)
  local function widget(w, label)
    if type(w) ~= "table" then return nil end
    if w.labelText == label then return w end
    for _, c in ipairs(w.children or {}) do
      local found = widget(c, label)
      if found then return found end
    end
    return nil
  end
  local shadow, companion = widget(ctx.scroll, "Font shadow"), widget(ctx.scroll, "Use the skin's shadow")
  assertTrue(shadow ~= nil and companion ~= nil, "both rendered")
  assertTrue(widget(ctx.scroll, "Use the skin's color") ~= nil, "and the color companion")
  companion:__fire("OnValueChanged", true)
  assertEqual(rec.store["f.fontShadowFromSkin"], true, "the companion writes through the host's seam")
  assertTrue(shadow.disabled, "Font shadow is disabled meanwhile")
  companion:__fire("OnValueChanged", false)
  assertFalse(shadow.disabled == true, "and live again when it is off")
end)
