-- tests/test_options_compose.lua — LibKa0s-Options-1.0's OptionsCompose.lua: the schema composers.
--
-- NO MOCK, and that is the point of the module rather than an accident of the suite. A composer is a
-- pure function returning an array of ordinary schema rows: it creates no widget, touches no AceGUI
-- and reads no state, so every case below is a call and a table comparison. The one exception is the
-- Master controls tail, which is a button-drawing hook and therefore needs a real ctx.
--
-- What these cases pin is the CANONICAL SHAPE (options-ui-§15, §16, §17) -- the exact leaves, in the
-- exact order, with the color companion adjacent to its swatch and no `disabledIf` anywhere. Nine
-- addons are about to be laid out from these lists, and a composer that quietly reordered one block
-- would reorder it in all nine at once.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local Fixture = dofile("tests/fixture_options.lua")

local O = Fixture.new()

--- Every row's path, joined -- which is the leaf list whenever the spec carried no prefix.
local function paths(rows)
  local out = {}
  for i, row in ipairs(rows) do out[i] = row.path end
  return table.concat(out, "|")
end

--- The row carrying `path`, or nil.
local function rowAt(rows, path)
  for i, row in ipairs(rows) do
    if row.path == path then return row, i end
  end
end

local BLOCK = { page = "general", group = "Appearance", subgroup = "Bar" }

--- The common spec every case starts from, plus whatever it is adding.
local function spec(extra)
  local s = {}
  for k, v in pairs(BLOCK) do s[k] = v end
  for k, v in pairs(extra or {}) do s[k] = v end
  return s
end

-- ── the instance exposes them ──────────────────────────────────────────────────────────────

test("compose: the instance carries every composer and every published constant", function()
  -- Attached through lib:New like the widget makers and the scroll patch, so a host that vendored
  -- a folder without this file degrades to no composers rather than erroring at :New.
  -- red under: dropping the __AttachCompose call from Options.lua's tail.
  assertEqual(type(O.ColorPair), "function")
  assertEqual(type(O.FontGroup), "function")
  assertEqual(type(O.BorderGroup), "function")
  assertEqual(type(O.BarGroup), "function")
  assertEqual(type(O.MasterControls), "function")
  assertEqual(O.MASTER_GROUP, "Master controls",
    "the literal is the group name AND the tab label AND the afterGroup key")
  assertEqual(table.concat(O.FONT_FLAGS_SORT, "|"),
    "|OUTLINE|THICKOUTLINE|MONOCHROME|OUTLINE, MONOCHROME")
  assertEqual(table.concat(O.VISIBILITY_SORT, "|"), "always|inCombat|outOfCombat|never")
  assertEqual(O.VISIBILITY_VALUES.inCombat, "Only in combat")
  assertEqual(O.FONT_FLAGS[""], "None", "the empty string is a real stored value and needs a label")
end)

-- ── the canonical row lists ────────────────────────────────────────────────────────────────

test("compose: FontGroup emits the six canonical leaves in the canonical order", function()
  -- The order IS the rule (options-ui-§16): font, size, color, companion, flags, shadow, landing as
  -- three lines. Five addons were about to type this out slightly differently each.
  -- red under: any reordering at all, or dropping the shadow row because one addon has no use for
  -- it -- a control the addon cannot honour is a control it should not have needed a group for.
  assertEqual(paths(O.FontGroup(spec())),
    "font|fontSize|fontColor|useClassColorFont|fontFlags|fontShadow")
end)

test("compose: BorderGroup emits the four mandated leaves, and the toggle only when asked",
function()
  -- red under: emitting borderShow unconditionally, which gives every addon a toggle it never had.
  assertEqual(paths(O.BorderGroup(spec())),
    "borderStyle|borderSize|borderColor|useClassColorBorder")
  assertEqual(paths(O.BorderGroup(spec{ show = true })),
    "borderShow|borderStyle|borderSize|borderColor|useClassColorBorder")
end)

test("compose: BarGroup emits texture, opacity, color, companion -- in that layout", function()
  -- R1f's whole content, and AbsorbTracker's bar tab is being re-laid-out from texture, color,
  -- class, opacity to exactly this.
  -- red under: keeping the shipped order, which reads down the page instead of across it.
  assertEqual(paths(O.BarGroup(spec())), "barTexture|barAlpha|barColor|useClassColorBar")
end)

test("compose: ColorPair emits exactly two rows, and names the companion after the swatch",
function()
  -- red under: a fixed companion leaf, which collides the moment a page has two swatches.
  assertEqual(paths(O.ColorPair(spec{ key = "bgColor", label = "Background color" })),
    "bgColor|useClassColorBgColor")
  assertEqual(paths(O.ColorPair(spec{ key = "accent", companionKey = "accentClassColor" })),
    "accent|accentClassColor")
  assertEqual(paths(O.ColorPair(spec())), "color|useClassColorColor")
end)

-- ── the color companion (options-ui-§17) ───────────────────────────────────────────────────

test("compose: every color row is immediately followed by its companion, and starts a line",
function()
  -- "Immediately to its right" is a property of the two-column engine, and without `startsLine` it
  -- is a property of how many rows happen to precede the swatch instead.
  -- red under: dropping startsLine, which lets a pair declared after an odd row split across two
  -- lines -- the swatch on the right of one and its companion on the left of the next.
  local blocks = {
    O.FontGroup(spec()), O.BorderGroup(spec()), O.BarGroup(spec()),
    O.BorderGroup(spec{ show = true }), O.ColorPair(spec{ key = "bgColor" }),
  }
  local seen = 0
  for _, rows in ipairs(blocks) do
    for i, row in ipairs(rows) do
      if row.type == "color" then
        seen = seen + 1
        assertTrue(row.startsLine, row.path .. " may be split across two lines")
        local companion = rows[i + 1]
        assertTrue(companion ~= nil, row.path .. " has no companion at all")
        assertEqual(companion.type, "bool")
        assertEqual(companion.label, "Use class color")
      end
    end
  end
  assertEqual(seen, 5, "every block must have contributed exactly one swatch")
end)

test("compose: no composed row anywhere carries disabledIf", function()
  -- The swatch is read under BOTH modes -- for its ALPHA -- so graying it tells the player
  -- something untrue (anti-patterns #74). The tooltip says it in words instead.
  -- red under: adding `disabledIf = <companion>` to the swatch, which is what two addons had
  -- shipped and then reversed.
  local blocks = {
    O.FontGroup(spec()), O.BorderGroup(spec{ show = true }), O.BarGroup(spec()),
    O.ColorPair(spec()), (O.MasterControls(spec{ addonName = "TestHost" })),
  }
  for _, rows in ipairs(blocks) do
    for _, row in ipairs(rows) do
      assertNil(row.disabledIf, row.path .. " disables a row a composer emitted")
    end
  end

  local swatch = rowAt(O.BarGroup(spec()), "barColor")
  assertTrue(swatch.tooltip:find("except for its opacity", 1, true) ~= nil,
    "the swatch must say in words what it is not allowed to say by graying itself")
end)

test("compose: the class-color SOURCE is stamped on both halves of every pair", function()
  -- A path prefix cannot be trusted to say whose class a control means: a row stored under
  -- `units.target.` that draws the player's own cooldowns is player-scoped. So the intent is
  -- declared, and the declaration is what an audit reads (options-ui-§17).
  -- red under: defaulting the source per composer, or stamping the swatch and not the companion.
  local rows = O.BarGroup(spec{
    prefix = "units.target.", classColor = { source = "unit", unit = "target", default = true },
  })
  local swatch    = rowAt(rows, "units.target.barColor")
  local companion = rowAt(rows, "units.target.useClassColorBar")
  assertEqual(swatch.classColorSource, "unit")
  assertEqual(swatch.classColorUnit, "target")
  assertEqual(companion.classColorSource, "unit")
  assertEqual(companion.classColorUnit, "target")
  assertTrue(companion.default, "an addon that already ships the companion ON keeps it ON")

  local player = O.BarGroup(spec())
  assertEqual(rowAt(player, "barColor").classColorSource, "player",
    "everything that is not about a particular unit is the player's")
  assertFalse(rowAt(player, "useClassColorBar").default, "and the companion is OFF by default")
end)

-- ── the common spec ────────────────────────────────────────────────────────────────────────

test("compose: prefix composes the path, and page/group/subgroup reach every row", function()
  -- Every row on every page carries a `group` (options-ui-§13) -- a composed row that did not
  -- would render untabbed and print, which is the failure the strip rule exists to prevent.
  -- red under: stamping the block's fields onto the first row only.
  local rows = O.FontGroup(spec{ prefix = "castbar.text." })
  assertEqual(paths(rows),
    "castbar.text.font|castbar.text.fontSize|castbar.text.fontColor|" ..
    "castbar.text.useClassColorFont|castbar.text.fontFlags|castbar.text.fontShadow")
  for _, row in ipairs(rows) do
    assertEqual(row.page, "general")
    assertEqual(row.group, "Appearance")
    assertEqual(row.subgroup, "Bar")
    assertEqual(type(row.order), "number")
    assertTrue(row.label ~= nil and row.label ~= "", row.path .. " has no label")
  end
end)

test("compose: order starts where the caller said and steps by ten", function()
  -- Ten, so a host can splice a row of its own between two canonical ones without renumbering
  -- either.
  -- red under: a step of one, or ignoring spec.order.
  local rows = O.BarGroup(spec{ order = 100 })
  assertEqual(rows[1].order, 100)
  assertEqual(rows[2].order, 110)
  assertEqual(rows[4].order, 130)
  assertEqual(O.BarGroup(spec())[1].order, 0, "an omitted order starts at zero")
end)

test("compose: keys, labels and defaults override without changing what the block IS", function()
  -- The composer MUST NOT change what is stored. Nine implementers are splicing these into addons
  -- with live SavedVariables, and a silently renamed path orphans a player's setting.
  -- red under: ignoring `keys`, which is the override that actually protects stored data.
  local rows = O.BarGroup(spec{
    prefix   = "bar.",
    keys     = { barAlpha = "opacity", barColor = "colour" },
    labels   = { barTexture = "Statusbar" },
    defaults = { barAlpha = 0.7 },
  })
  assertEqual(paths(rows), "bar.barTexture|bar.opacity|bar.colour|bar.useClassColorBar")
  assertEqual(rowAt(rows, "bar.barTexture").label, "Statusbar")
  assertEqual(rowAt(rows, "bar.opacity").default, 0.7)
  assertEqual(rowAt(rows, "bar.opacity").label, "Bar opacity", "an override is one field, not all")
end)

test("compose: omit removes a row and leaves the survivors in the same relative order", function()
  -- red under: emitting the row and hiding it, which leaves it in the CLI and in the reset sweep.
  local rows = O.FontGroup(spec{ omit = { fontShadow = true, fontFlags = true } })
  assertEqual(paths(rows), "font|fontSize|fontColor|useClassColorFont")
  assertEqual(rows[1].order, 0)
  assertEqual(rows[4].order, 30, "the survivors are contiguous, so an omission leaves no hole")
end)

test("compose: extra rows are appended AFTER the mandated block, never interleaved", function()
  -- A border offset is legitimate and a border group without a thickness is not (options-ui-§16),
  -- so the extras go at the end and the mandated four keep their order.
  -- red under: merging extras by their declared order, which lets one land inside the block.
  local rows = O.BorderGroup(spec{
    extra = { { path = "borderOffset", type = "number", label = "Border offset", min = 0, max = 8 } },
  })
  assertEqual(paths(rows),
    "borderStyle|borderSize|borderColor|useClassColorBorder|borderOffset")
  local offset = rowAt(rows, "borderOffset")
  assertEqual(offset.group, "Appearance", "an extra belongs to the block it was appended to")
  assertEqual(offset.subgroup, "Bar")
  assertEqual(offset.order, 40)
end)

test("compose: a composer never writes to the spec it was handed", function()
  -- A host hoists its spec and its extras to a file constant and re-renders freely, exactly as it
  -- does with afterGroup and pairWith. A composer that stamped the caller's own extra rows would
  -- work once and then carry the previous block's group into the next one.
  -- red under: stamping `row` rather than a copy in appendExtra, or writing spec.group in
  -- MasterControls.
  local extraRow = { path = "borderOffset", type = "number", label = "Border offset" }
  local s = spec{ extra = { extraRow } }
  O.BorderGroup(s)
  O.BorderGroup(s)
  assertNil(extraRow.group, "the caller's row was stamped in place")
  assertNil(extraRow.order)
  assertEqual(s.group, "Appearance", "the caller's spec was rewritten")

  local master = { page = "general", addonName = "TestHost", omit = { visibility = true } }
  O.MasterControls(master)
  assertNil(master.group, "MasterControls wrote its default group into the caller's spec")
  assertNil(master.omit.scale)
end)

-- ── the Master controls tab (options-ui-§15) ───────────────────────────────────────────────

test("compose: MasterControls emits the six canonical rows and defaults its own group", function()
  -- The group name IS the tab label AND the afterGroup key, so a host that renamed it would
  -- silently detach its own button pair.
  -- red under: reordering the set, or letting an addon drop a row it merely has no use for.
  local rows, tail = O.MasterControls{ page = "general", addonName = "AbsorbTracker" }
  assertEqual(paths(rows), "enabled|visibility|scale|alpha|locked|state.debugConsole")
  assertEqual(type(tail), "function")
  for _, row in ipairs(rows) do
    assertEqual(row.group, "Master controls")
    assertEqual(row.page, "general")
  end
  assertEqual(rows[1].label, "Enable AbsorbTracker")
  assertEqual(rows[2].values, O.VISIBILITY_VALUES, "visibility is a dropdown, not a boolean")
  assertEqual(rows[2].default, "always")
  assertTrue(rows[6].sessionOnly, "a console left open is not a setting the next character inherits")
end)

test("compose: the debug console's path is verbatim and outside the block's prefix", function()
  -- Session state lives outside the settings prefix, which is why this one row takes a whole path
  -- rather than a leaf.
  -- red under: prefixing it, which stores a session toggle under the profile.
  local rows = O.MasterControls{ page = "general", addonName = "X", prefix = "settings." }
  assertEqual(paths(rows),
    "settings.enabled|settings.visibility|settings.scale|settings.alpha|settings.locked|" ..
    "state.debugConsole")

  local custom = O.MasterControls{ page = "general", addonName = "X", debugConsolePath = "ui.console" }
  assertTrue(rowAt(custom, "ui.console") ~= nil)
end)

test("compose: frameless drops EXACTLY the four frame-only controls and nothing else", function()
  -- PrettyChat is the one genuinely frameless addon in the collection. General visibility STAYS
  -- even there: "Never" is a meaningful master off-switch distinct from Enable.
  -- red under: dropping visibility too, or inventing a movable frame to fill the tab out.
  local rows, tail = O.MasterControls{
    page = "general", addonName = "PrettyChat", frameless = true,
    onResetAll = function() end,
  }
  assertEqual(paths(rows), "enabled|visibility|state.debugConsole")

  local ctx = O.CreatePanel("ComposeFrameless", "Compose frameless", {})
  tail(ctx)
  local row = Fixture.flowRows(ctx.scroll)[1]
  assertEqual(#row.children, 1, "a frameless addon draws Reset all settings ALONE")
  assertEqual(row.children[1].text, "Reset all settings")
end)

test("compose: the tail draws the two resets as the tab's closing button pair", function()
  -- They are acts rather than settings, so they are a button pair and not schema rows -- and
  -- "Reset all settings" is options-ui-§12's global reset verbatim, in every addon.
  -- red under: swapping the two, or emitting them as rows, which would put them in the CLI.
  local fired = {}
  local _, tail = O.MasterControls{
    page = "general", addonName = "KickCD",
    onResetPosition = function() fired[#fired + 1] = "position" end,
    onResetAll      = function() fired[#fired + 1] = "all" end,
  }

  local ctx = O.CreatePanel("ComposeTail", "Compose tail", {})
  tail(ctx)
  local row = Fixture.flowRows(ctx.scroll)[1]
  assertEqual(#row.children, 2)
  assertEqual(row.children[1].text, "Reset position")
  assertEqual(row.children[2].text, "Reset all settings")

  row.children[1]:__fire("OnClick")
  row.children[2]:__fire("OnClick")
  assertEqual(table.concat(fired, "|"), "position|all", "the handlers were wired the wrong way up")
end)
