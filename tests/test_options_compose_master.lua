-- tests/test_options_compose_master.lua — OptionsCompose minor 9: what a host may add to the Master
-- controls tab's composed words, and how the tab packs when Lock frame is omitted.
--
-- options-ui-§15 (standard v2.88.0) makes the composed rows' words the composer's: a host MUST NOT
-- write the label or tooltip of a row or button MasterControls emits. Where the canonical tooltip
-- misdescribes the addon, the host passes `notes` (one sentence appended after the canonical text),
-- `resetPositionTooltip` (the one canonical text that names the addon's own frames, replaced) or
-- `lockIsPreview` (the library's one sentence for an addon whose unlocked view is its test mode).
-- The same minor renames the alpha row's label to Master opacity (owner call CALL-02; the stored
-- leaf stays `alpha`) and packs Minimap button beside Debug console when Lock frame is omitted
-- (U-09c). A NO MOCK suite like test_options_compose.lua, apart from the button recorder and the
-- one flow-engine render.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil, assertErrorMatches =
  T.test, T.assertEqual, T.assertTrue, T.assertNil, T.assertErrorMatches
local Fixture = dofile("tests/fixture_options.lua")
local Golden  = dofile("tests/fixture_compose_golden.lua")

local O = Fixture.new()

-- The text options-ui-§15 quotes for `lockIsPreview`, byte for byte.
local LOCK_PREVIEW_TIP = "Stop the frame being dragged. While it is unlocked the display shows " ..
  "placeholder content, so it can be seen and placed; this is the addon's test mode."

--- Every row's path, joined.
local function paths(rows)
  local out = {}
  for i, row in ipairs(rows) do out[i] = row.path end
  return table.concat(out, "|")
end

--- The row carrying `path`, or nil.
local function rowAt(rows, path)
  for _, row in ipairs(rows) do
    if row.path == path then return row end
  end
end

--- A spec that emits all eight canonical rows, plus whatever the case adds.
local function full(extra)
  local s = { page = "general", addonName = "X", minimapPath = "global.minimap.hide",
    testModePath = "state.test", onResetAll = function() end, onResetPosition = function() end }
  for k, v in pairs(extra or {}) do s[k] = v end
  return s
end

-- The canonical leaf of each row `full` emits, keyed by the row's path.
local LEAF_PATHS = {
  enabled = "enabled", visibility = "visibility", scale = "scale", alpha = "alpha",
  locked = "locked", debugConsole = "state.debugConsole", minimap = "global.minimap.hide",
  testMode = "state.test",
}

--- The tail's buttons, by text: InlineButtonPair is replaced with a recorder for the call and put
--- back after it, so no ctx or widget is needed.
local function buttons(spec)
  local _, tail = O.MasterControls(spec)
  local seen, saved = {}, O.InlineButtonPair
  O.InlineButtonPair = function(_, left, right)
    seen[#seen + 1] = left
    if right then seen[#seen + 1] = right end
  end
  local ok, err = pcall(tail, {})
  O.InlineButtonPair = saved
  assertTrue(ok, tostring(err))
  local byText = {}
  for _, b in ipairs(seen) do byText[b.text] = b end
  return byText
end

-- ── Master opacity (CALL-02, U-09a) ──────────────────────────────────────────────────────────

test("compose master: the alpha row is labeled Master opacity, everything else unchanged", function()
  -- red under: the label staying "Master alpha", or the rename reaching the stored leaf.
  local rows = O.MasterControls(full())
  local row = rowAt(rows, "alpha")
  assertTrue(row ~= nil, "the stored leaf is still alpha")
  assertEqual(row.label, "Master opacity")
  assertEqual(row.tooltip, "Opacity of the whole addon's display.")
  assertEqual(row.min, 0)
  assertEqual(row.max, 1)
  assertEqual(row.step, 0.05)
  assertEqual(row.default, 1)
  for _, r in ipairs(rows) do
    assertTrue(r.label ~= "Master alpha", "no row is labeled Master alpha")
  end
end)

-- ── notes ────────────────────────────────────────────────────────────────────────────────────

test("compose master: each row's note appends one sentence to exactly that row", function()
  -- red under: a note keyed by path rather than leaf, or landing on more than one row.
  local base = O.MasterControls(full())
  for leaf, path in pairs(LEAF_PATHS) do
    local rows = O.MasterControls(full{ notes = { [leaf] = "Note " .. leaf .. "." } })
    for i, row in ipairs(rows) do
      local want = base[i].tooltip
      if row.path == path then want = want .. " Note " .. leaf .. "." end
      assertEqual(row.tooltip, want, leaf .. " note on " .. tostring(row.path))
    end
  end
end)

test("compose master: notes.resetAll and notes.resetPosition append to the button tooltips", function()
  -- red under: the buttons ignoring notes.
  local plain = buttons(full())
  local noted = buttons(full{ notes = { resetAll = "All note.", resetPosition = "Position note." } })
  assertEqual(noted["Reset all settings"].tooltip, plain["Reset all settings"].tooltip .. " All note.")
  assertEqual(noted["Reset position"].tooltip,
    "Move the frame back to where it started. Position note.")
end)

test("compose master: an empty, non-string or omitted-leaf note changes nothing", function()
  -- red under: appending a bare space, a tostring'd value, or reaching a row the host omitted.
  local want = Golden.serialize(O.MasterControls(full()))
  assertEqual(Golden.serialize(O.MasterControls(full{ notes = { enabled = "" } })), want)
  assertEqual(Golden.serialize(O.MasterControls(full{ notes = { enabled = 5, locked = true } })), want)
  local omitted = full{ omit = { scale = true } }
  local withNote = full{ omit = { scale = true }, notes = { scale = "Never shown." } }
  assertEqual(Golden.serialize(O.MasterControls(withNote)), Golden.serialize(O.MasterControls(omitted)))
  assertEqual(Golden.serialize(O.MasterControls(full{ notes = "not a table" })), want)
end)

test("compose master: a keys rename does not stop the note", function()
  -- red under: looking the note up by the renamed key.
  local rows = O.MasterControls(full{ keys = { alpha = "opacity" }, notes = { alpha = "Renamed." } })
  assertEqual(rowAt(rows, "opacity").tooltip, "Opacity of the whole addon's display. Renamed.")
end)

test("compose master: the spec and its notes are never written, and two calls agree", function()
  -- red under: writing the composed tooltip back into the spec or the notes table.
  local notes = { locked = "Covers both bars.", resetAll = "All." }
  local spec = full{ notes = notes, omit = { visibility = true } }
  local first = Golden.serialize(O.MasterControls(spec))
  local second = Golden.serialize(O.MasterControls(spec))
  assertEqual(first, second)
  assertEqual(notes.locked, "Covers both bars.")
  assertEqual(notes.resetAll, "All.")
  local n = 0
  for _ in pairs(notes) do n = n + 1 end
  assertEqual(n, 2, "nothing added to notes")
  assertNil(spec.omit.locked)
  assertNil(spec.group)
end)

-- ── resetPositionTooltip ─────────────────────────────────────────────────────────────────────

test("compose master: resetPositionTooltip replaces the Reset position tooltip", function()
  -- red under: ignoring the field, or appending it rather than replacing.
  local b = buttons(full{ resetPositionTooltip = "Move both bars back." })
  assertEqual(b["Reset position"].tooltip, "Move both bars back.")
  b = buttons(full{ resetPositionTooltip = "Move both bars back.",
    notes = { resetPosition = "Lock is kept." } })
  assertEqual(b["Reset position"].tooltip, "Move both bars back. Lock is kept.")
  b = buttons(full{ resetPositionTooltip = "" })
  assertEqual(b["Reset position"].tooltip, "Move the frame back to where it started.")
  -- Frameless: no Reset position button at all, so the field has nowhere to go.
  b = buttons{ page = "general", addonName = "X", frameless = true, onResetAll = function() end,
    resetPositionTooltip = "Ignored." }
  assertNil(b["Reset position"])
  assertTrue(b["Reset all settings"] ~= nil)
end)

-- ── lockIsPreview ────────────────────────────────────────────────────────────────────────────

test("compose master: lockIsPreview gives Lock frame the library's preview sentence", function()
  -- red under: any other wording, which the standard quotes and an audit compares.
  local spec = { page = "general", addonName = "X", lockIsPreview = true }
  assertEqual(rowAt(O.MasterControls(spec), "locked").tooltip, LOCK_PREVIEW_TIP)
  spec.notes = { locked = "It ends when combat starts." }
  assertEqual(rowAt(O.MasterControls(spec), "locked").tooltip,
    LOCK_PREVIEW_TIP .. " It ends when combat starts.")
  assertEqual(rowAt(O.MasterControls{ page = "general", addonName = "X" }, "locked").tooltip,
    "Stop the frame being dragged.")
end)

test("compose master: lockIsPreview with a testModePath is refused", function()
  -- red under: drawing two switches for one mode (options-ui-§15's Test mode bullet).
  local err = assertErrorMatches(function()
    O.MasterControls{ page = "general", addonName = "X", lockIsPreview = true,
      testModePath = "state.test" }
  end, "lockIsPreview")
  assertTrue(err:find("options-ui section 15", 1, true) ~= nil, err)
end)

test("compose master: frameless with lockIsPreview emits no Lock frame row and does not raise", function()
  -- red under: raising, or emitting a lock row for an addon with no frame.
  local rows = O.MasterControls{ page = "general", addonName = "X", frameless = true,
    lockIsPreview = true }
  assertNil(rowAt(rows, "locked"))
end)

-- ── the frameless packing (U-09c) ────────────────────────────────────────────────────────────

test("compose master: frameless puts Minimap button beside Debug console", function()
  -- red under: Minimap button keeping its first-column startsLine with Lock frame gone.
  local rows = O.MasterControls{ page = "general", addonName = "X", frameless = true,
    minimapPath = "global.minimap.hide", onResetAll = function() end }
  assertEqual(paths(rows), "enabled|visibility|state.debugConsole|global.minimap.hide")
  assertNil(rowAt(rows, "global.minimap.hide").startsLine)
end)

test("compose master: framed with Lock frame omitted packs minimap and gives Test mode its own line", function()
  -- red under: Test mode pairing beside a minimap that already sits in the second column.
  local rows = O.MasterControls(full{ omit = { locked = true } })
  assertNil(rowAt(rows, "global.minimap.hide").startsLine)
  assertEqual(rowAt(rows, "state.test").startsLine, true)
  -- Nothing omitted: unchanged from compose minor 7.
  rows = O.MasterControls(full())
  assertEqual(rowAt(rows, "global.minimap.hide").startsLine, true)
  assertNil(rowAt(rows, "state.test").startsLine)
end)

test("compose master: with the console omitted too, frameless Minimap button opens its line", function()
  -- red under: packing beside a console row that was never emitted.
  local rows = O.MasterControls{ page = "general", addonName = "X", frameless = true,
    minimapPath = "global.minimap.hide", omit = { debugConsole = true } }
  assertEqual(rowAt(rows, "global.minimap.hide").startsLine, true)
end)

test("compose master: the flow engine draws Debug console and Minimap button on one line", function()
  -- red under: the packing living in the rows but not reaching the two-column engine.
  local Oi = Fixture.new()
  local rows = Oi.MasterControls{ page = "general", addonName = "X", frameless = true,
    minimapPath = "global.minimap.hide", onResetAll = function() end }
  local ctx = Oi.CreatePanel("ComposeMasterPacking", "Compose master packing", {})
  Oi.RenderRows(ctx, rows)
  local line = Fixture.rowWithLabel(ctx.scroll, "Debug console")
  assertTrue(line ~= nil, "Debug console was drawn")
  assertEqual(line, Fixture.rowWithLabel(ctx.scroll, "Minimap button"), "the two share one line")
  assertTrue(Fixture.rowWithLabel(ctx.scroll, "Enable X") ~= line)
end)

-- ── the minor ────────────────────────────────────────────────────────────────────────────────

test("compose master: OptionsCompose is at minor 9 or later", function()
  -- red under: the change landing without its bump, which no vendored copy would pick up. The
  -- current minor is pinned by test_options_compose_tooltips.lua (minor 10).
  assertTrue(T.options.MODULES.OptionsCompose >= 9)
end)
