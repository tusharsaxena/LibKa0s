-- tests/test_options_compose_arm.lua — OptionsCompose minor 4: the record-backed arm (`spec.bind`) and
-- PanelMaster's three hand-written groups expressed with it. Moved unchanged out of
-- tests/test_options_compose.lua on the seam the watch list named (FX-LK-SIZE of Ka0sAddonsCommonTasks
-- docs/2026-10-31-FINDINGS_REMEDIATION). A NO MOCK suite like that one, apart from the rendered rows.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil, assertErrorMatches =
  T.test, T.assertEqual, T.assertTrue, T.assertNil, T.assertErrorMatches
local Fixture = dofile("tests/fixture_options.lua")

-- ── compose minor 4: the record-backed arm (PanelMaster#48, PANELMASTER-A-03) ─────────────────
--
-- `spec.bind` binds a composed block to a REGISTRY RECORD instead of to settings paths, for a page
-- that edits records -- PanelMaster's panel editor, whose three options-ui-§16 groups could not
-- compose because every row the composers emitted was path-keyed. What the arm must NOT do is move
-- a single byte of what a path-keyed caller gets, and that is the first case below.

local Golden = dofile("tests/fixture_compose_golden.lua")

test("compose: a path-keyed call emits byte-for-byte what compose minor 3 emitted", function()
  -- Characterization against a record taken BEFORE the arm existed (see the fixture's header).
  -- red under: the arm leaking into the path branch -- a `field`, a `get`, a changed order.
  local opts = Fixture.new()
  for _, call in ipairs(Golden.calls(opts)) do
    local name, make = call[1], call[2]
    assertTrue(Golden.GOLDEN[name] ~= nil, "a golden exists for " .. name)
    assertEqual(Golden.serialize(make()), Golden.GOLDEN[name], name .. " moved")
  end
end)

--- A fake registry: `records[id]` holds the live record and `writes` logs every Set, in order.
local function registry(initial)
  local reg = { records = { p1 = initial or {} }, writes = {} }
  function reg.Get(id) return reg.records[id] end
  function reg.Set(id, field, value)
    reg.writes[#reg.writes + 1] = { id, field, value }
    reg.records[id][field] = value
  end
  return reg
end

--- The bind a record-editing page hands the composer: get off the live record, set through the
--- registry's write seam. `field` is the record key, `row` the composed row asking.
local function recordBind(reg, id)
  return {
    get = function(field) return reg.Get(id)[field] end,
    set = function(field, value) reg.Set(id, field, value) end,
  }
end

--- A row with the binding taken off and its record key put back as a path: what the row would
--- have been had the block been path-keyed. Everything else must already be equal.
local function asPathRow(row)
  local copy = {}
  for k, v in pairs(row) do copy[k] = v end
  copy.path, copy.field, copy.get, copy.set = row.field, nil, nil, nil
  return copy
end

test("compose: the bind arm emits the same rows as the path arm, with the binding in place of path",
function()
  -- The row order, the labels, the defaults, the mandated shapes and the class-color stamps are the
  -- composer's; the arm changes WHERE a value lives and nothing about which controls there are.
  -- red under: an arm that reorders, drops a companion or forgets an extra.
  local opts = Fixture.new()
  local reg = registry()
  local common = { page = "p", group = "g", keys = { borderStyle = "borderTexture" },
                   extra = { { field = "borderOffset", type = "number", label = "Border offset" } } }
  local withBind = {}
  for k, v in pairs(common) do withBind[k] = v end
  withBind.bind = recordBind(reg, "p1")
  local withPath = {}
  for k, v in pairs(common) do withPath[k] = v end
  withPath.extra = { { path = "borderOffset", type = "number", label = "Border offset" } }

  local bound, keyed = opts.BorderGroup(withBind), opts.BorderGroup(withPath)
  assertEqual(#bound, #keyed, "the same number of rows")
  for i, row in ipairs(bound) do
    assertNil(row.path, "a bound row carries no path: row " .. i)
    assertEqual(type(row.get), "function", "and reads through get: row " .. i)
    assertEqual(type(row.set), "function", "and writes through set: row " .. i)
    assertEqual(Golden.serialize(asPathRow(row)), Golden.serialize(keyed[i]), "row " .. i .. " differs")
  end
  assertEqual(bound[1].field, "borderTexture", "keys rename the record field exactly as they rename a leaf")
end)

test("compose: a bound row's get and set reach the bind with the record field and the row", function()
  local opts = Fixture.new()
  local seen = {}
  local rows = opts.BarGroup{ page = "p", group = "g", prefix = "accent.",
    bind = {
      get = function(field, row) seen[#seen + 1] = { "get", field, row.type }; return 0.5 end,
      set = function(field, value, row) seen[#seen + 1] = { "set", field, value, row.type } end,
    } }
  assertEqual(rows[2].get(), 0.5, "get answers what the bind answered")
  rows[2].set(0.25)
  assertEqual(seen[1][2], "accent.barAlpha", "the field is the prefixed leaf, as a path would be")
  assertEqual(seen[1][3], "number", "and the row is handed through, so a bind can convert by type")
  assertTrue(seen[2][1] == "set" and seen[2][2] == "accent.barAlpha" and seen[2][3] == 0.25, "set")
end)

test("compose: bind.record is enough to read, and an extra's own path is left alone", function()
  local opts = Fixture.new()
  local rec = { color = { r = 1, g = 0, b = 0, a = 1 }, inset = 4 }
  local wrote = {}
  local rows = opts.ColorPair{ page = "p", group = "g",
    bind = { record = function() return rec end, set = function(f, v) wrote[f] = v end },
    extra = { { field = "inset", type = "number", label = "Inset" },
              { path = "global.thing", type = "bool", label = "Global" } } }
  assertTrue(rows[1].get() == rec.color, "record() is read at call time, by field")
  assertEqual(rows[3].get(), 4, "an extra declaring `field` is bound like a canonical row")
  rows[3].set(6)
  assertEqual(wrote.inset, 6)
  assertEqual(rows[4].path, "global.thing", "an extra declaring its own path keeps it")
  assertNil(rows[4].get, "and is not bound")
end)

test("compose: a bind with no setter, or with nothing to read, is refused when the block is composed",
function()
  -- A bound control with nowhere to write is a dead control, and a dead control that renders is
  -- the failure InlineButtonPair's DEAD_BUTTON report exists for. Here it is refused outright.
  local opts = Fixture.new()
  assertErrorMatches(function() opts.BorderGroup{ bind = { get = function() end } } end,
    "spec.bind needs set(field, value, row)", "no set raised")
  assertErrorMatches(function() opts.BorderGroup{ bind = { set = function() end } } end,
    "spec.bind needs get(field, row) or record()",
    "neither get nor record raised")
end)

-- The flow engine's half: OptionsWidgets minor 15 reads and writes a row that has NO path through
-- the row's own get / set. A row that has a path is untouched, whatever else it carries.

--- Render `row` into a throwaway container on a fresh panel; answer the widget and the ctx.
local benchSeq = 0
local function renderBound(opts, row)
  benchSeq = benchSeq + 1
  local ctx = opts.CreatePanel("ComposeBind" .. benchSeq, "Compose bind " .. benchSeq, {})
  return opts.RenderField(ctx, row, opts.AceGUI:Create("SimpleGroup"), 0.5), ctx
end

local function runRefreshers(ctx) for _, fn in ipairs(ctx.refreshers) do fn() end end

test("compose: every maker reads a bound row through get and writes it through set, never the store",
function()
  -- red under: a maker still calling d.get(row.path) / d.set(row.path, ...) -- which, for a row
  -- whose path is nil, reads nil and writes a nil-keyed setting into the host's store.
  local opts, rec = Fixture.new()
  local reg = registry({ show = true, style = "Blizzard", size = 3, tint = { r = 0.1, g = 0.2, b = 0.3, a = 1 },
                         label = "hi" })
  local bind = recordBind(reg, "p1")
  local function bound(field, row) row.field = field
    row.get = function() return bind.get(field) end
    row.set = function(v) bind.set(field, v) end
    return row
  end
  local before = Golden.serialize(rec.store)

  local cb = renderBound(opts, bound("show", { type = "bool", label = "Show" }))
  assertEqual(cb.value, true, "checkbox read the record")
  cb:__fire("OnValueChanged", false)

  local dd = renderBound(opts, bound("style", { type = "string", label = "Style",
    values = { Blizzard = "Blizzard", Solid = "Solid" } }))
  assertEqual(dd.value, "Blizzard", "dropdown read the record")
  dd:__fire("OnValueChanged", "Solid")

  local s = renderBound(opts, bound("size", { type = "number", label = "Size", min = 0, max = 32, step = 1 }))
  assertEqual(s.value, 3, "slider read the record")
  s:__fire("OnMouseUp", 7)

  local eb = renderBound(opts, bound("label", { type = "string", label = "Label", dialogControl = "EditBox" }))
  assertEqual(eb.text, "hi", "edit box read the record")
  eb:__fire("OnEnterPressed", "yo")

  local cp = renderBound(opts, bound("tint", { type = "color", label = "Tint" }))
  assertEqual(cp.color.g, 0.2, "color picker read the record through the descriptor's codec")
  cp:__fire("OnValueConfirmed", 0.5, 0.5, 0.5, 1)

  local fields = {}
  for i, w in ipairs(reg.writes) do fields[i] = w[2] end
  assertEqual(table.concat(fields, "|"), "show|style|size|label|tint", "every write went through set")
  assertEqual(reg.records.p1.size, 7)
  assertEqual(reg.records.p1.tint.r, 0.5, "the color was encoded by the codec, then set")
  assertEqual(Golden.serialize(rec.store), before, "and the settings store was never touched")
end)

test("compose: a bound row's refresher re-reads the record, so a write elsewhere repaints it", function()
  local opts = Fixture.new()
  local reg = registry({ size = 3 })
  local rows = opts.BorderGroup{ page = "p", group = "g", bind = recordBind(reg, "p1"),
                                 keys = { borderSize = "size" } }
  local s, ctx = renderBound(opts, rows[2])
  reg.records.p1.size = 9                     -- a drag, a CLI command, a reset: anything but the widget
  runRefreshers(ctx)
  assertEqual(s.value, 9, "the refresher read the live record")
end)

test("compose: a row WITH a path is read through the descriptor even when it carries get and set", function()
  -- The byte-for-byte promise, seen from the flow engine: the record path opens only for a row
  -- with no path, so a host schema that happens to carry get/set fields of its own is untouched.
  local opts, rec = Fixture.new()
  local row = {}
  for k, v in pairs(rec.byPath.locked) do row[k] = v end
  row.get = function() error("a path row must not be read through get") end
  row.set = function() error("a path row must not be written through set") end
  local cb = renderBound(opts, row)
  cb:__fire("OnValueChanged", true)
  assertEqual(rec.store.locked, true, "the write landed in the store, through d.set")
end)

-- ── PanelMaster's three hand-written groups, expressed with the arm ────────────────────────────
--
-- settings/PanelEditor.lua (PanelMaster, at LibKa0s v1.30.0) types out three options-ui-§16 blocks
-- over a panel RECORD: the panel's border, the accent bar, and the accent bar's own border. Each is
-- canonical four in canonical order plus the addon's own rows after them. These cases are the
-- claim in PanelMaster#48 made executable: all three compose, field for field, in the order the
-- page draws them today. docs/api/Options/version-15.15.4.3-docs.md carries the same three as the
-- worked example.

local function fieldsOf(rows)
  local out = {}
  for i, row in ipairs(rows) do out[i] = row.field or row.path end
  return table.concat(out, "|")
end

local function panelBlocks(opts, bind)
  local border = opts.BorderGroup{ bind = bind,
    keys = { borderStyle = "borderTexture", borderSize = "borderSize",
             borderColor = "borderColor", useClassColorBorder = "borderClassColor" },
    extra = { { field = "borderOffset", type = "number", label = "Border offset", min = -32, max = 32, step = 1 } } }
  local bar = opts.BarGroup{ bind = bind,
    keys = { barTexture = "accentTexture", barAlpha = "accentAlpha",
             barColor = "accentColor", useClassColorBar = "accentClassColor" },
    extra = { { field = "accentThickness", type = "number", label = "Bar thickness", min = 1, max = 32, step = 1 },
              { field = "accentOffset", type = "number", label = "Bar offset", min = -32, max = 32, step = 1 } } }
  local barBorder = opts.BorderGroup{ bind = bind,
    keys = { borderStyle = "accentBorderTexture", borderSize = "accentBorderSize",
             borderColor = "accentBorderColor", useClassColorBorder = "accentBorderClassColor" },
    extra = { { field = "accentBorderOffset", type = "number", label = "Border offset", min = -32, max = 32, step = 1 } } }
  return border, bar, barBorder
end

test("compose: PanelMaster's three record-backed groups compose, in the order the editor draws them",
function()
  local opts = Fixture.new()
  local border, bar, barBorder = panelBlocks(opts, recordBind(registry(), "p1"))
  assertEqual(fieldsOf(border), "borderTexture|borderSize|borderColor|borderClassColor|borderOffset")
  assertEqual(fieldsOf(bar), "accentTexture|accentAlpha|accentColor|accentClassColor|accentThickness|accentOffset")
  assertEqual(fieldsOf(barBorder),
    "accentBorderTexture|accentBorderSize|accentBorderColor|accentBorderClassColor|accentBorderOffset")
  for _, block in ipairs({ border, bar, barBorder }) do
    for i, row in ipairs(block) do
      assertTrue(row.path == nil and type(row.get) == "function" and type(row.set) == "function",
        "every row is bound to the record, not to a settings path: " .. tostring(row.field or i))
    end
  end
  assertEqual(bar[2].label, "Bar opacity", "the mandated labels come with the block")
  assertEqual(border[4].label, "Use class color")
end)

test("compose: a PanelMaster block writes through the registry and repaints off the live record", function()
  local opts = Fixture.new()
  local reg = registry({ borderClassColor = false, accentAlpha = 1 })
  local border, bar = panelBlocks(opts, recordBind(reg, "p1"))
  local companion = renderBound(opts, border[4])
  companion:__fire("OnValueChanged", true)
  assertTrue(reg.writes[1][1] == "p1" and reg.writes[1][2] == "borderClassColor" and reg.writes[1][3] == true,
    "the companion wrote the record's class-color flag through the registry")
  local alpha, ctx = renderBound(opts, bar[2])
  reg.records.p1.accentAlpha = 0.4
  runRefreshers(ctx)
  assertEqual(alpha.value, 0.4, "and the opacity slider repainted from the live record")
end)

test("compose: a bound row takes its pairWith partner, keyed by its field", function()
  -- pairWith is keyed by path, and a bound row has none, so its partner never attached.
  local opts = Fixture.new()
  local reg = registry({ a = true })
  local rows = opts.ColorPair{ page = "p", group = "G", bind = recordBind(reg, "p1"),
    extra = { { field = "a", type = "bool", label = "Alone", solo = true } } }
  local ctx = opts.CreatePanel("ComposePairWith", "Compose pairWith", {})
  local fired = 0
  opts.RenderRows(ctx, { rows[3] }, nil, { a = function() fired = fired + 1 end })
  assertEqual(fired, 1, "the partner keyed by the bound row's field attached")
end)

test("compose: disabledIf on a bound row reads the record through the bind, not the settings store", function()
  local opts = Fixture.new()
  local reg = registry({ tint = { r = 1, g = 1, b = 1, a = 1 }, locked = true })
  local rows = opts.ColorPair{ page = "p", group = "G", bind = recordBind(reg, "p1"),
    extra = { { field = "tint", type = "color", label = "Tint", disabledIf = "locked" } } }
  local cp = renderBound(opts, rows[3])
  assertEqual(cp.disabled, true, "the record's own flag grayed the swatch")
  assertEqual(rows[3].get("locked"), true, "get(key) reads another field of the same record")
end)
