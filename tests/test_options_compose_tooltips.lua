-- tests/test_options_compose_tooltips.lua — OptionsCompose minor 10: `tooltips` beside `labels` on
-- the group composers.
--
-- options-ui-§16 (standard v2.88.0, WS-35): where a composed group's canonical tooltip misdescribes
-- the host's wiring -- AbsorbTracker's *Bar opacity*, applied to the whole frame rather than the
-- bar's fill (U-02, ABS-L12) -- the host passes `tooltips = { <leaf> = "..." }` to FontGroup,
-- BorderGroup, BarGroup or ColorPair. That replaces exactly that row's tooltip; a color swatch keeps
-- the class-color sentence after it (options-ui-§17); the label stays canonical. MasterControls
-- takes `notes`, never `tooltips` (options-ui-§15). A NO MOCK suite like test_options_compose.lua.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertNil
local Fixture = dofile("tests/fixture_options.lua")
local Golden  = dofile("tests/fixture_compose_golden.lua")

local O = Fixture.new()

-- The four composers, each with its canonical leaves and the spec that emits all of them.
-- BorderGroup appears twice, with and without its Show border toggle.
local GROUPS = {
  { name = "ColorPair", make = function(s) return O.ColorPair(s) end, spec = {},
    leaves = { "color", "useClassColorColor" } },
  { name = "FontGroup", make = function(s) return O.FontGroup(s) end, spec = {},
    leaves = { "font", "fontSize", "fontColor", "useClassColorFont", "fontFlags", "fontShadow" } },
  { name = "BorderGroup", make = function(s) return O.BorderGroup(s) end, spec = {},
    leaves = { "borderStyle", "borderSize", "borderColor", "useClassColorBorder" } },
  { name = "BorderGroup/show", make = function(s) return O.BorderGroup(s) end, spec = { show = true },
    leaves = { "borderShow", "borderStyle", "borderSize", "borderColor", "useClassColorBorder" } },
  { name = "BarGroup", make = function(s) return O.BarGroup(s) end, spec = {},
    leaves = { "barTexture", "barAlpha", "barColor", "useClassColorBar" } },
}

--- A copy of `base` with `extra`'s fields laid over it; neither is written.
local function with(base, extra)
  local out = { page = "p", group = "g" }
  for k, v in pairs(base) do out[k] = v end
  for k, v in pairs(extra or {}) do out[k] = v end
  return out
end

--- The row carrying `path`, or nil.
local function rowAt(rows, path)
  for _, row in ipairs(rows) do
    if row.path == path then return row end
  end
end

-- ── the replacement ──────────────────────────────────────────────────────────────────────────

test("compose tooltips: an entry replaces exactly its leaf's tooltip, every other row byte-identical",
function()
  -- red under: tooltips ignored, keyed by path rather than leaf, or reaching more than one row.
  for _, g in ipairs(GROUPS) do
    local base = g.make(with(g.spec))
    for _, leaf in ipairs(g.leaves) do
      local rows = g.make(with(g.spec, { tooltips = { [leaf] = "Host words." } }))
      assertEqual(#rows, #base, g.name .. "/" .. leaf .. ": the same rows")
      for i, row in ipairs(rows) do
        if row.path == leaf then
          local want = "Host words."
          if row.type == "color" then want = want .. " " .. O.CLASS_COLOR_NOTE end
          assertEqual(row.tooltip, want, g.name .. "/" .. leaf)
          assertEqual(row.label, base[i].label, g.name .. "/" .. leaf .. ": the label stays canonical")
          local copy = {}
          for k, v in pairs(row) do copy[k] = v end
          copy.tooltip = base[i].tooltip
          assertEqual(Golden.serialize(copy), Golden.serialize(base[i]),
            g.name .. "/" .. leaf .. ": nothing but the tooltip moved")
        else
          assertEqual(Golden.serialize(row), Golden.serialize(base[i]),
            g.name .. "/" .. leaf .. " reached " .. tostring(row.path))
        end
      end
    end
  end
end)

test("compose tooltips: a swatch's override ends with the class-color sentence", function()
  -- red under: the override replacing the options-ui-§17 sentence along with the canonical words.
  local swatches = { ColorPair = "color", FontGroup = "fontColor", BorderGroup = "borderColor",
    BarGroup = "barColor" }
  for _, g in ipairs(GROUPS) do
    local leaf = swatches[g.name]
    if leaf then
      local row = rowAt(g.make(with(g.spec, { tooltips = { [leaf] = "Tints the frame." } })), leaf)
      assertEqual(row.type, "color")
      assertEqual(row.tooltip, "Tints the frame. " .. O.CLASS_COLOR_NOTE, g.name)
      local tail = " " .. O.CLASS_COLOR_NOTE
      assertEqual(row.tooltip:sub(-#tail), tail, g.name .. ": ends with the note")
    end
  end
end)

test("compose tooltips: a companion's override has no class-color sentence appended", function()
  -- red under: appending the note by leaf name or by the class-color stamp rather than by type.
  local companions = { ColorPair = "useClassColorColor", FontGroup = "useClassColorFont",
    BorderGroup = "useClassColorBorder", BarGroup = "useClassColorBar" }
  for _, g in ipairs(GROUPS) do
    local leaf = companions[g.name]
    if leaf then
      local row = rowAt(g.make(with(g.spec, { tooltips = { [leaf] = "Use the class." } })), leaf)
      assertEqual(row.type, "bool")
      assertEqual(row.tooltip, "Use the class.", g.name)
    end
  end
end)

test("compose tooltips: an empty, non-string or omitted-leaf entry changes nothing", function()
  -- red under: a bare tooltip of "", a tostring'd value, or reaching a row the host omitted.
  for _, g in ipairs(GROUPS) do
    local want = Golden.serialize(g.make(with(g.spec)))
    local first = g.leaves[1]
    assertEqual(Golden.serialize(g.make(with(g.spec, { tooltips = { [first] = "" } }))), want,
      g.name .. ": empty string")
    assertEqual(Golden.serialize(g.make(with(g.spec, { tooltips = { [first] = 5 } }))), want,
      g.name .. ": a number")
    assertEqual(Golden.serialize(g.make(with(g.spec, { tooltips = { [first] = true } }))), want,
      g.name .. ": a boolean")
    assertEqual(Golden.serialize(g.make(with(g.spec, { tooltips = { unknownLeaf = "x" } }))), want,
      g.name .. ": a leaf the composer has no row for")
    local omitted = g.make(with(g.spec, { omit = { [first] = true } }))
    local noted = g.make(with(g.spec, { omit = { [first] = true }, tooltips = { [first] = "x" } }))
    assertEqual(Golden.serialize(noted), Golden.serialize(omitted), g.name .. ": an omitted leaf")
  end
end)

test("compose tooltips: a keys rename keeps the override", function()
  -- red under: looking the override up by the renamed key.
  local rows = O.BarGroup(with({}, { keys = { barAlpha = "frameAlpha" },
    tooltips = { barAlpha = "Opacity of the whole frame." } }))
  assertEqual(rowAt(rows, "frameAlpha").tooltip, "Opacity of the whole frame.")
  rows = O.BarGroup(with({}, { keys = { barAlpha = "frameAlpha" },
    tooltips = { frameAlpha = "Keyed by the rename." } }))
  assertEqual(rowAt(rows, "frameAlpha").tooltip, "How opaque the bar's fill is.",
    "the rename is not a tooltips key")
  rows = O.ColorPair(with({}, { key = "tint", tooltips = { tint = "The tint." } }))
  assertEqual(rowAt(rows, "tint").tooltip, "The tint. " .. O.CLASS_COLOR_NOTE,
    "ColorPair's own key is its canonical leaf")
end)

test("compose tooltips: labels and tooltips together both apply", function()
  -- red under: one override arm shadowing the other.
  local rows = O.BarGroup(with({}, { labels = { barAlpha = "Frame opacity" },
    tooltips = { barAlpha = "Opacity of the whole frame." } }))
  local row = rowAt(rows, "barAlpha")
  assertEqual(row.label, "Frame opacity")
  assertEqual(row.tooltip, "Opacity of the whole frame.")
end)

test("compose tooltips: a prefixed block keys the override by the leaf, not the path", function()
  local rows = O.FontGroup(with({}, { prefix = "bars.text.", tooltips = { fontSize = "Points." } }))
  assertEqual(rowAt(rows, "bars.text.fontSize").tooltip, "Points.")
end)

test("compose tooltips: the bind arm applies the override", function()
  -- red under: the override living only on the path branch.
  local bind = { get = function() return nil end, set = function() end }
  local rows = O.BarGroup(with({}, { bind = bind,
    tooltips = { barAlpha = "Opacity of the whole frame.", barColor = "Tints the frame." } }))
  local alpha, color
  for _, row in ipairs(rows) do
    assertNil(row.path, "a bound row carries no path")
    if row.field == "barAlpha" then alpha = row end
    if row.field == "barColor" then color = row end
  end
  assertEqual(alpha.tooltip, "Opacity of the whole frame.")
  assertEqual(color.tooltip, "Tints the frame. " .. O.CLASS_COLOR_NOTE)
end)

test("compose tooltips: the spec and its tooltips table are never written, and two calls agree",
function()
  -- red under: writing the composed tooltip (with its note) back into the caller's table.
  local tooltips = { barAlpha = "Opacity of the whole frame.", barColor = "Tints the frame." }
  local spec = with({}, { tooltips = tooltips })
  local first = Golden.serialize(O.BarGroup(spec))
  local second = Golden.serialize(O.BarGroup(spec))
  assertEqual(first, second)
  assertEqual(tooltips.barAlpha, "Opacity of the whole frame.")
  assertEqual(tooltips.barColor, "Tints the frame.")
  local n = 0
  for _ in pairs(tooltips) do n = n + 1 end
  assertEqual(n, 2, "nothing added to tooltips")
  assertEqual(spec.tooltips, tooltips, "the spec still holds the caller's table")
end)

-- ── MasterControls ignores it ────────────────────────────────────────────────────────────────

test("compose tooltips: MasterControls ignores tooltips (notes is its only route)", function()
  -- red under: the group override reaching the Master controls tab (options-ui-§15).
  local spec = { page = "general", addonName = "X", minimapPath = "global.minimap.hide",
    onResetAll = function() end }
  local want = Golden.serialize(O.MasterControls(spec))
  spec.tooltips = { alpha = "x", locked = "y" }
  assertEqual(Golden.serialize(O.MasterControls(spec)), want)
  spec.labels = { alpha = "Opacity" }
  local labeled = O.MasterControls(spec)
  assertEqual(rowAt(labeled, "alpha").label, "Opacity", "labels keeps its behavior there")
  assertEqual(rowAt(labeled, "alpha").tooltip, "Opacity of the whole addon's display.")
end)

-- ── the goldens and the minor ────────────────────────────────────────────────────────────────

test("compose tooltips: every golden is unchanged", function()
  -- The case test_options_compose.lua runs, re-run here: a spec with no tooltips emits what it did.
  local opts = Fixture.new()
  for _, call in ipairs(Golden.calls(opts)) do
    local name, make = call[1], call[2]
    assertTrue(Golden.GOLDEN[name] ~= nil, "a golden exists for " .. name)
    assertEqual(Golden.serialize(make()), Golden.GOLDEN[name], name .. " moved")
  end
end)

test("compose tooltips: OptionsCompose is at minor 10 or later", function()
  -- red under: the change landing without its bump, which no vendored copy would pick up.
  assertTrue(T.options.MODULES.OptionsCompose >= 10)
end)
