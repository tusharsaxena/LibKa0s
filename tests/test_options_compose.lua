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
local test, assertEqual, assertTrue, assertFalse, assertNil, assertError =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil, T.assertError
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

--- How many keys `t` holds. A media list is a key map keyed on the media name, so `#t` answers 0
--- for a perfectly full one and says nothing at all about whether the dropdown has options.
local function size(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n
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

-- ── the media rows are deferred readers (LIBKA0S-A-01d) ──────────────────────────

-- Nothing in this suite ever CALLED a media row's `values` before these four, and that is how the
-- collection's only Critical shipped past 764 green cases: the sole `values` assertion here
-- (MasterControls' visibility list, below) compares a table by identity and never invokes anything.
-- `enumList` (OptionsWidgets.lua:78-79) unwraps a row's `values` exactly ONCE, so what the composer
-- assigns must be the deferred reader itself and not a wrapper around it. These cases call the row
-- the way the flow engine does and look at what comes back.

test("compose: FontGroup's font row answers a populated list, not a second closure", function()
  -- The list is read AFTER the row is declared, which is the whole point of the deferral
  -- (Options.lua:759-763): the addons that register fonts have not run at file load. So the fixture
  -- gets its media only once the row exists, and the row still has to see it.
  -- red under: wrapping O.LSMValues in an outer `function() ... end`, which hands enumList a
  -- function where it has already unwrapped and gets `{}` -- a dropdown with no options, silently,
  -- because the empty-list report at OptionsWidgets.lua:1442 is gated on `values == nil`.
  local opts, rec = Fixture.new()
  local row = rowAt(opts.FontGroup(spec()), "font")
  assertEqual(type(row.values), "function", "the row must stay a deferred reader")

  rec.lsm = { HashTable = function(_, kind)
    assertEqual(kind, "font", "the media type is carried through to the call")
    return { ["Friz Quadrata TT"] = "path/a", Arial = "path/b" }
  end }
  local list = row.values()
  assertEqual(type(list), "table", "enumList unwraps once; a second closure reaches it as a function")
  assertEqual(size(list), 2, "the live font list, not an empty dropdown")
  assertEqual(list.Arial, "Arial", "keyed on the name, valued with the name (an AceGUI list)")
end)

test("compose: BorderGroup's border-style row answers a populated list", function()
  -- Its own case rather than a loop over the three, because a loop that broke on the first group
  -- would leave the other two unproven and the failure would name neither.
  -- red under: the same double wrap, in the border composer alone.
  local opts, rec = Fixture.new()
  local row = rowAt(opts.BorderGroup(spec()), "borderStyle")
  assertEqual(type(row.values), "function", "the row must stay a deferred reader")

  rec.lsm = { HashTable = function(_, kind)
    assertEqual(kind, "border", "the media type is carried through to the call")
    return { Blizzard = "path/a", Chat = "path/b" }
  end }
  local list = row.values()
  assertEqual(type(list), "table", "enumList unwraps once; a second closure reaches it as a function")
  assertEqual(size(list), 2, "the live border list, not an empty dropdown")
  assertEqual(list.Chat, "Chat")
end)

test("compose: BarGroup's bar-texture row answers a populated list", function()
  -- red under: the same double wrap, in the bar composer alone. This is the row KickCD's
  -- settings/Castbar.lua reaches through the composer eight times over.
  local opts, rec = Fixture.new()
  local row = rowAt(opts.BarGroup(spec()), "barTexture")
  assertEqual(type(row.values), "function", "the row must stay a deferred reader")

  rec.lsm = { HashTable = function(_, kind)
    assertEqual(kind, "statusbar", "the media type is carried through to the call")
    return { Blizzard = "path/a", Smooth = "path/b" }
  end }
  local list = row.values()
  assertEqual(type(list), "table", "enumList unwraps once; a second closure reaches it as a function")
  assertEqual(size(list), 2, "the live statusbar list, not an empty dropdown")
  assertEqual(list.Smooth, "Smooth")
end)

test("compose: a host whose own LSMValues returns a TABLE lands a frozen list, which is the breach",
function()
  -- __AttachCompose lets a host supply its own O.LSMValues, and the composer reads that member
  -- once, at row-declaration time. A host handing back a TABLE therefore freezes its media list at
  -- whatever happened to be registered when the file loaded -- exactly the failure the deferral
  -- exists to prevent. MultiMeters ships that shape today (settings/Schema.lua:670 reads
  -- `C.LSMValues = function(t) return lsmValues(t)() end`) and must hand back the closure instead.
  --
  -- This case is the only thing that makes the breach visible: with the outer wrapper in place a
  -- table-returner works by accident, late-evaluated, and nothing anywhere says the host is wrong.
  -- red under: restoring the outer closure, which demotes this assertion back to "a function".
  local opts = Fixture.new()
  opts.LSMValues = function(_) return { Blizzard = "Blizzard" } end
  local row = rowAt(opts.BarGroup(spec()), "barTexture")

  assertEqual(type(row.values), "table",
    "a table-returning host LSMValues must land as the frozen literal it is, where a case can see it")
  assertEqual(row.values.Blizzard, "Blizzard", "and it is the host's list, frozen at declaration")
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

-- A HOST VERB IN THE PAIR (`leadButton`). §15 fixes the reset buttons' wording, so an addon that
-- wants its own act beside them cannot draw the pair itself without keeping a second copy of
-- "Reset all settings" -- which is the drift this composer exists to end. The seam hands the verb
-- IN instead, and the composer stays the only writer of the reset's text.
--
-- FRAMELESS ONLY takes it into the pair, because the frameless pair's right half is the one empty
-- cell §15 leaves. A framed addon's pair is already full and §15 forbids splitting or reordering
-- it, so there the verb takes its own row above.
--
-- red under: putting the lead button on the right (the reset must close the tab), or letting it
-- displace a reset on a framed addon.
test("compose: a frameless addon's lead button shares the pair with Reset all settings", function()
  local fired = {}
  local _, tail = O.MasterControls{
    page = "general", addonName = "PrettyChat", frameless = true,
    leadButton = {
      text    = "Test",
      tooltip = "Print a sample of every active format string.",
      onClick = function() fired[#fired + 1] = "test" end,
    },
    onResetAll = function() fired[#fired + 1] = "all" end,
  }

  local ctx = O.CreatePanel("ComposeLead", "Compose lead", {})
  tail(ctx)
  local rows = Fixture.flowRows(ctx.scroll)
  assertEqual(#rows[1].children, 2, "the verb and the reset share ONE row")
  assertEqual(rows[1].children[1].text, "Test", "the host's verb leads")
  assertEqual(rows[1].children[2].text, "Reset all settings", "and the reset still closes the tab")

  rows[1].children[1]:__fire("OnClick")
  rows[1].children[2]:__fire("OnClick")
  assertEqual(table.concat(fired, "|"), "test|all", "the handlers were wired the wrong way up")
end)

test("compose: a FRAMED addon's lead button takes its own row above the full pair", function()
  -- The pair is [Reset position][Reset all settings] and §15 forbids splitting or reordering it,
  -- so there is no cell to give away. The verb goes above rather than displacing a reset.
  -- red under: dropping either reset to make room, or drawing three buttons on one line.
  local _, tail = O.MasterControls{
    page = "general", addonName = "KickCD",
    leadButton      = { text = "Test", onClick = function() end },
    onResetPosition = function() end,
    onResetAll      = function() end,
  }

  local ctx = O.CreatePanel("ComposeLeadFramed", "Compose lead framed", {})
  tail(ctx)
  local rows = Fixture.flowRows(ctx.scroll)
  assertEqual(#rows[1].children, 1, "the verb is alone on the first row")
  assertEqual(rows[1].children[1].text, "Test")
  assertEqual(#rows[2].children, 2, "and the canonical pair is intact below it")
  assertEqual(rows[2].children[1].text, "Reset position")
  assertEqual(rows[2].children[2].text, "Reset all settings")
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

-- ── compose minor 4: the record-backed arm (PanelMaster#48, PANELMASTER-A-03) ─────────────────
--
-- `spec.bind` binds a composed block to a REGISTRY RECORD instead of to settings paths, for a page
-- that edits records -- PanelMaster's panel editor, whose three option-ui-§16 groups could not
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
  assertError(function() opts.BorderGroup{ bind = { get = function() end } } end, "no set raised")
  assertError(function() opts.BorderGroup{ bind = { set = function() end } } end,
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

-- ── the Reset all settings tooltip follows what the reset IS (compose minor 5) ──────────────────
--
-- options-ui-§12: with `resetProfile` supplied the global reset is a PROFILE reset, and the control's
-- tooltip SHOULD name the equivalence with Profiles -> Reset Profile. Through compose minor 4 it was
-- one literal, "Restore every setting in this addon to its default", whatever the reset did, and a
-- host could not change it without keeping a second copy of the button. The Options descriptor
-- picks the wording now: `resetProfile`, and `profilesPage` for a host that ships that page.

local tipPanels = 0

--- The tooltip body the Reset all settings button shows, for a host built from `overrides`.
--- Frameless, so the button is alone on its row; the tooltip is read by firing the button's
--- OnEnter with GameTooltip:AddLine spied, which is the only place AttachTooltip puts it.
local function resetAllTip(overrides, attach)
  local Oi = Fixture.new(overrides)
  if attach then attach(Oi) end
  local _, tail = Oi.MasterControls{
    page = "general", addonName = "X", frameless = true, onResetAll = function() end,
  }
  tipPanels = tipPanels + 1
  local ctx = Oi.CreatePanel("ComposeTip" .. tipPanels, "Compose tip", {})
  tail(ctx)
  local btn = Fixture.flowRows(ctx.scroll)[1].children[1]
  assertEqual(btn.text, "Reset all settings")
  local lines, tip = {}, T.mocks.GameTooltip   -- the chunk env reads mocks first
  local saved = rawget(tip, "AddLine")
  rawset(tip, "AddLine", function(_, text) lines[#lines + 1] = text end)
  local ok, err = pcall(btn.callbacks.OnEnter)
  rawset(tip, "AddLine", saved)
  assertTrue(ok, tostring(err))
  assertEqual(#lines, 1, "one tooltip line")
  return lines[1]
end

local function resetProfile() end
local S = T.options.STRINGS

test("compose: with no resetProfile the Reset all tooltip keeps its minor-4 wording, byte for byte", function()
  -- red under: dropping the old literal, or letting `profilesPage` alone change it.
  assertEqual(resetAllTip(), "Restore every setting in this addon to its default.")
  assertEqual(S.RESET_ALL_TIP, "Restore every setting in this addon to its default.")
  assertEqual(resetAllTip{ profilesPage = true }, S.RESET_ALL_TIP,
    "profilesPage is ignored without resetProfile: there the reset really walks every setting")
end)

test("compose: with resetProfile the Reset all tooltip says it resets the current profile only", function()
  -- red under: the minor-4 literal, which overstates a profile reset -- other profiles survive it.
  local tip = resetAllTip{ resetProfile = resetProfile }
  assertEqual(tip, "Reset the current profile to its defaults. Your other profiles are not affected.")
  assertEqual(tip, S.RESET_ALL_TIP_PROFILE)
  assertTrue(tip:find("Reset Profile", 1, true) == nil,
    "no Profiles page declared, so the tooltip must not point at one")
end)

test("compose: with resetProfile and profilesPage the tooltip names Profiles -> Reset Profile", function()
  -- options-ui-§12: "the same thing Profiles → Reset Profile does".
  local tip = resetAllTip{ resetProfile = resetProfile, profilesPage = true }
  assertEqual(tip, "Reset the current profile to its defaults \226\128\148 the same thing Profiles " ..
    "\226\134\146 Reset Profile does. Your other profiles are not affected.")
  assertEqual(tip, S.RESET_ALL_TIP_PROFILES_PAGE)
end)

test("compose: the descriptor moves the Reset all tooltip and nothing else Master controls draws", function()
  -- A descriptor without profilesPage behaves exactly as before apart from resetProfile's wording:
  -- the same rows, the same buttons, the same order, the same handlers.
  -- red under: the descriptor reaching any row or button field other than that one tooltip.
  local function shape(overrides)
    local Oi = Fixture.new(overrides)
    local rows, tail = Oi.MasterControls{
      page = "general", addonName = "KickCD", onResetPosition = function() end,
      onResetAll = function() end,
    }
    tipPanels = tipPanels + 1
    local ctx = Oi.CreatePanel("ComposeShape" .. tipPanels, "Compose shape", {})
    tail(ctx)
    local out = { paths(rows) }
    for _, row in ipairs(Fixture.flowRows(ctx.scroll)) do
      for _, child in ipairs(row.children) do out[#out + 1] = child.text end
    end
    return table.concat(out, "|")
  end
  local before = shape()
  assertEqual(before, "enabled|visibility|scale|alpha|locked|state.debugConsole|" ..
    "Reset position|Reset all settings")
  assertEqual(shape{ resetProfile = resetProfile }, before)
  assertEqual(shape{ resetProfile = resetProfile, profilesPage = true }, before)
end)

test("compose: a shell that hands __AttachCompose no descriptor keeps the minor-4 tooltip", function()
  -- Options.lua before minor 18 called __AttachCompose(O). Whole-folder vendoring keeps that pair
  -- out of the wild, but a missing descriptor must read as "no resetProfile", never raise.
  -- red under: indexing a nil descriptor.
  local tip = resetAllTip({ resetProfile = resetProfile, profilesPage = true },
    function(Oi) T.options.__AttachCompose(Oi) end)
  assertEqual(tip, S.RESET_ALL_TIP)
end)
