-- tests/test_widgets_skin.lua — Core and Widgets take a skin owner (Core minor 13, Widgets minor 16,
-- WidgetsReorder 2, WidgetsDragHandle 6, WidgetsLineChart 4, WidgetsAutocomplete 4,
-- WidgetsCopyWindow 1; LK-06 of Ka0sAddonsCommonTasks docs/2026-10-25-SKINNING).
--
-- Three promises, each pinned here on the kit's paint recorder (tests/fixture_skin_paint.lua):
--
--   * WITHOUT AN OWNER NOTHING MOVES. A name counts as an owner only once that addon called
--     Skin:RegisterOwner, so a call naming an unregistered addon, a call naming none and a call in a
--     client with no Skin major at all make the same paint calls, call for call (the tracer).
--   * WITH ONE, the control paints from that owner's skin and follows its switches, and two owners
--     side by side never reach each other's controls.
--   * THE SHARED SINGLETONS follow whoever opens them: the popup menu every dropdown drops and the
--     ghost every reorder list drags are repainted on each open, to the opener's skin, or back to
--     Ka0s Default when the opener has no owner.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertNil
local F = dofile("tests/fixture_skin_paint.lua")

local OWNER, OTHER = "LootHistory", "BankLedger"
local WFILES = { "Widgets", "WidgetsReorder", "WidgetsDragHandle", "WidgetsLineChart", "WidgetsAutocomplete",
                 "WidgetsCopyWindow" }

local function survey(m, obj) return m.__paint(obj) end

--- A fresh client: the paint recorder, Core, the Skin major (unless `noSkin`) and every Widgets
--- file. Answers m, Skin (nil without it), W, core.
local function env(noSkin)
  local files = {}
  for _, f in ipairs(noSkin and { "Core" } or F.FILES) do files[#files + 1] = f end
  for _, f in ipairs(WFILES) do files[#files + 1] = f end
  local m, Skin = F.env({ files = files })
  m.__cursorX, m.__cursorY = 100, 100
  return m, Skin, m.LibStub("LibKa0s-Widgets-1.0"), m.LibStub("LibKa0s-Core-1.0")
end

--- The tracer's lines for whatever `build(m, W, core)` paints, in a fresh client.
local function traceOf(noSkin, build)
  local m, _, W, core = env(noSkin)
  local tr = F.tracer(m)
  tr.start()
  local ok, err = pcall(build, m, W, core)
  tr.stop(); tr.restore()
  if not ok then error(err, 0) end
  return tr.text()
end

--- The three owner-less spellings of one call must trace identically: an unregistered name with
--- the Skin major loaded, no name, and no Skin major at all.
local function assertUnchanged(build, what)
  local named = traceOf(false, function(m, W, core) return build(m, W, core, OTHER) end)
  local bare = traceOf(false, function(m, W, core) return build(m, W, core, nil) end)
  local noSkin = traceOf(true, function(m, W, core) return build(m, W, core, OTHER) end)
  assertTrue(bare ~= "", what .. " paints something")
  assertEqual(named, bare, what .. ": an unregistered owner is today's paint, call for call")
  assertEqual(noSkin, bare, what .. ": a client with no Skin major is today's paint, call for call")
end

local function tok(Skin, skin, name) return F.tok(Skin, skin, name) end
local function rgba(c) return F.rgba(c) end

-- ── Core ─────────────────────────────────────────────────────────────────────────────────────

test("skin owner: Core.ApplySkin and MakeCloseButton without a registered owner are minor 12's", function()
  assertUnchanged(function(m, _, core, owner)
    local f = F.window(m)
    core.ApplySkin(f, nil, owner)
  end, "ApplySkin")
  assertUnchanged(function(m, _, core, owner)
    core.MakeCloseButton(m.UIParent, function() end, owner)
  end, "MakeCloseButton")
end)

test("skin owner: Core.ApplySkin paints a registered owner's window from its skin and repaints it", function()
  local m, Skin, _, core = env()
  F.owner(Skin, OWNER, "obsidian")
  local f = F.window(m)
  core.ApplySkin(f, nil, OWNER)
  assertEqual(rgba(survey(m, f).backdropColor), tok(Skin, "obsidian", "win.bg"))
  assertEqual(rgba(survey(m, f.title).textColor), tok(Skin, "obsidian", "title.text"))
  Skin:SetChoice(OWNER, "ka0s", "azeroth")
  assertEqual(rgba(survey(m, f).backdropColor), tok(Skin, "azeroth", "win.bg"), "a switch repaints it")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertEqual(rgba(survey(m, f).backdropColor), "0.060,0.060,0.080,0.920", "Ka0s Default is Core.SKIN")
end)

test("skin owner: a host's own skin table wins over the owner, and is never repainted", function()
  local m, Skin, _, core = env()
  F.owner(Skin, OWNER, "obsidian")
  local f = F.window(m)
  core.ApplySkin(f, { bgFile = "x", bg = { 0.2, 0.3, 0.4, 1 } }, OWNER)
  assertEqual(rgba(survey(m, f).backdropColor), "0.200,0.300,0.400,1")
  assertNil(Skin.painted[f], "not handed to the owner's facade")
end)

test("skin owner: Core works with no Skin major, and resolves it at call time", function()
  local m, Skin, _, core = env(true)
  assertNil(Skin)
  local f = F.window(m)
  core.ApplySkin(f, nil, OWNER)
  assertTrue(survey(m, f).backdrop == core.SKIN, "Core.SKIN, as before")
  assertTrue(core.MakeCloseButton(m.UIParent, function() end, OWNER) ~= nil)
end)

test("skin owner: MakeCloseButton takes a registered owner's close colors and follows a switch", function()
  local m, Skin, _, core = env()
  F.owner(Skin, OWNER, "contrast")
  local b = core.MakeCloseButton(m.UIParent, function() end, OWNER)
  assertEqual(rgba(survey(m, b.glyph).textColor), tok(Skin, "contrast", "close.rest"))
  b:__fire("OnEnter")
  assertEqual(rgba(survey(m, b.glyph).textColor), tok(Skin, "contrast", "close.hot"))
  b:__fire("OnLeave")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertEqual(rgba(survey(m, b.glyph).textColor), "0.700,0.700,0.720,1", "Ka0s Default's gray")
end)

-- ── the dropdown and its menu ────────────────────────────────────────────────────────────────

local function options(dd)
  dd:SetOptions({ { value = "a", label = "A" }, { value = "b", label = "B" } })
  dd:SelectValue("a")
  return dd
end

--- Open `dd`, answering the shared menu (captured the first time it is built).
local function open(m, dd, state)
  local saved = m.CreateFrame
  m.CreateFrame = function(...)
    local f = saved(...)
    state.menu = state.menu or f
    return f
  end
  dd:__fire("OnClick")
  m.CreateFrame = saved
  return state.menu
end

test("skin owner: Dropdown without a registered owner is minor 15's, button and menu", function()
  assertUnchanged(function(m, W, _, owner)
    local dd = options(W.Dropdown(m.UIParent, 120, { owner = owner }))
    dd:__fire("OnClick")
    dd:__fire("OnClick")
    dd:__fire("OnClick")
  end, "Dropdown")
end)

test("skin owner: an owned Dropdown wears its owner's skin, and two owners stay apart", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  F.owner(Skin, OTHER, "azeroth")
  local a = W.Dropdown(m.UIParent, 120, { owner = OWNER })
  local b = W.Dropdown(m.UIParent, 120, { owner = OTHER })
  assertEqual(rgba(survey(m, a).backdropColor), tok(Skin, "obsidian", "input.bg"))
  assertEqual(rgba(survey(m, a.arrow).vertex), tok(Skin, "obsidian", "icon.arrow"))
  assertEqual(rgba(survey(m, b).backdropColor), tok(Skin, "azeroth", "input.bg"))
  Skin:SetChoice(OWNER, "ka0s", "glass")
  assertEqual(rgba(survey(m, a).backdropColor), tok(Skin, "glass", "input.bg"), "the owner's switch repaints it")
  assertEqual(rgba(survey(m, b).backdropColor), tok(Skin, "azeroth", "input.bg"), "and never the other owner's")
end)

test("skin owner: the shared menu follows its opener, and an owner-less open puts Ka0s Default back", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  F.owner(Skin, OTHER, "azeroth")
  local state = {}
  local owned = options(W.Dropdown(m.UIParent, 120, { owner = OWNER }))
  local menu = open(m, owned, state)
  assertEqual(rgba(survey(m, menu).backdropColor), tok(Skin, "obsidian", "menu.bg"))
  local sel, plain = menu.buttons[1], menu.buttons[2]
  assertEqual(rgba(survey(m, sel.fs).textColor), tok(Skin, "obsidian", "menu.textSel"))
  assertEqual(rgba(survey(m, plain.fs).textColor), tok(Skin, "obsidian", "menu.text"))
  assertEqual(rgba(survey(m, sel.__hl).color), tok(Skin, "obsidian", "menu.hover"))

  local bare = options(W.Dropdown(m.UIParent, 120))
  open(m, bare, state)
  assertEqual(rgba(survey(m, menu).backdropColor), "0.060,0.060,0.080,0.980", "Ka0s Default's menu again")
  assertEqual(rgba(survey(m, menu).backdropBorderColor), "0,0,0,1")
  assertEqual(rgba(survey(m, menu.buttons[2].fs).textColor), "0.900,0.900,0.900,1")
  assertEqual(rgba(survey(m, menu.buttons[1].__hl).color), "1,0.820,0,0.150")

  local other = options(W.Dropdown(m.UIParent, 120, { owner = OTHER }))
  open(m, other, state)
  assertEqual(rgba(survey(m, menu).backdropColor), tok(Skin, "azeroth", "menu.bg"), "the next owner's skin")
  assertEqual(rgba(survey(m, menu.buttons[2].fs).textColor), tok(Skin, "azeroth", "menu.text"))
end)

test("skin owner: a LootHistory open under Obsidian, then an owner-less open, shows Ka0s Default", function()
  -- the plan review's pin, on the menu frame's backdrop calls alone
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  local state = {}
  open(m, options(W.Dropdown(m.UIParent, 120, { owner = OWNER })), state)
  local bare = options(W.Dropdown(m.UIParent, 120))
  local tr = F.tracer(m)
  tr.watch(state.menu)
  tr.start(); bare:__fire("OnClick"); tr.stop(); tr.restore()
  local text = F.only(tr, { SetBackdrop = true, SetBackdropColor = true, SetBackdropBorderColor = true })
  assertTrue(text:find("SetBackdropColor(0.060,0.060,0.080,0.980)", 1, true) ~= nil, text)
  assertTrue(text:find("SetBackdropBorderColor(0,0,0,1)", 1, true) ~= nil, text)
end)

-- ── the search box, the strip and the copy window ────────────────────────────────────────────

test("skin owner: SearchBox and TestStrip without a registered owner are minor 15's", function()
  assertUnchanged(function(m, W, _, owner)
    local box = W.SearchBox(m.UIParent, 100, { hint = "Search", icon = "icon", owner = owner })
    box:__fire("OnEditFocusGained")
    box:__fire("OnEditFocusLost")
  end, "SearchBox")
  assertUnchanged(function(m, W, _, owner)
    W.TestStrip(m.UIParent, { text = "Test", kind = "sim", owner = owner })
  end, "TestStrip")
end)

test("skin owner: an owned SearchBox paints its box, focus line and icon from the skin", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "azeroth")
  local box = W.SearchBox(m.UIParent, 100, { hint = "Search", icon = "icon", owner = OWNER })
  assertEqual(rgba(survey(m, box).backdropColor), tok(Skin, "azeroth", "input.bg"))
  assertEqual(rgba(survey(m, box.hint).textColor), tok(Skin, "azeroth", "input.placeholder"))
  box:__fire("OnEditFocusGained")
  assertEqual(rgba(survey(m, box).backdropBorderColor), tok(Skin, "azeroth", "input.focus"))
  box:__fire("OnEditFocusLost")
  assertEqual(F.rgba({ survey(m, box.icon).vertex[1], survey(m, box.icon).vertex[2], survey(m, box.icon).vertex[3] }),
    F.rgba({ Skin:Color(OWNER, "icon.tint") }))
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(rgba(survey(m, box).backdropColor), tok(Skin, "obsidian", "input.bg"), "repainted")
  local v = survey(m, box.icon).vertex
  assertEqual(F.rgba({ v[1], v[2], v[3] }), F.rgba({ Skin:Color(OWNER, "icon.tint") }), "the icon too")
end)

test("skin owner: an owned TestStrip takes its wash from the owner's skin", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER)
  Skin:RegisterSkin({ key = "loud", tokens = { ["strip.sim"] = { 0, 1, 0, 0.5 } } })
  local s = W.TestStrip(m.UIParent, { kind = "sim", owner = OWNER })
  assertEqual(rgba(survey(m, s.__fill).color), "0.350,0.800,1,0.120", "Ka0s Default's cyan")
  Skin:SetChoice(OWNER, "ka0s", "loud")
  assertEqual(rgba(survey(m, s.__fill).color), "0,1,0,0.500", "the skin's strip.sim")
end)

test("skin owner: CopyWindow without a registered owner is minor 15's", function()
  assertUnchanged(function(_, W, _, owner)
    W.CopyWindow({ addonName = owner or "Plain" }):Show("text")
  end, "CopyWindow")
end)

test("skin owner: a registered addon's CopyWindow wears its skin, dense fill and close button", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  local f = W.CopyWindow({ addonName = OWNER }):Show("text")
  assertEqual(rgba(survey(m, f).backdropColor), tok(Skin, "obsidian", "win.bgDense"))
  Skin:SetChoice(OWNER, "ka0s", "glass")
  assertEqual(rgba(survey(m, f).backdropColor), tok(Skin, "glass", "win.bgDense"), "dense again after the repaint")
  local closes = 0
  for frame in pairs(Skin.byOwner[OWNER] or {}) do
    local rec = Skin.painted[frame]
    if rec and rec.calls.CloseButton then closes = closes + 1 end
  end
  assertEqual(closes, 1, "its close button is the owner's")
  local g = W.CopyWindow({ addonName = OWNER, name = "HostBackdrop", backdrop = { 0.2, 0.2, 0.2, 0.5 } }):Show("x")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(rgba(survey(m, g).backdropColor), "0.200,0.200,0.200,0.500", "a host's own backdrop stays")
end)

-- ── the autocomplete ─────────────────────────────────────────────────────────────────────────

local function suggest(m, W, owner)
  local box = m.CreateFrame("EditBox", nil, m.UIParent, "BackdropTemplate")
  rawset(box, "GetText", function() return "ab" end)
  local h = W.Autocomplete(box, { owner = owner, provider = function()
    return { { text = "One" }, { text = "Two", color = { 0.1, 0.2, 0.3 } } }
  end })
  h:Refresh()
  return h
end

test("skin owner: Autocomplete without a registered owner is minor 3's", function()
  assertUnchanged(function(m, W, _, owner) suggest(m, W, owner) end, "Autocomplete")
end)

test("skin owner: an owned Autocomplete colors its rows from the skin on every show", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER)
  Skin:RegisterSkin({ key = "rows", tokens = { ["menu.text"] = { 0.2, 0.4, 0.6, 1 },
                                               ["menu.hover"] = { 0, 0, 1, 0.3 } } })
  Skin:SetChoice(OWNER, "ka0s", "rows")
  local h = suggest(m, W, OWNER)
  local one, two = h.__rows[1], h.__rows[2]
  assertEqual(rgba(survey(m, one.label).textColor), "0.200,0.400,0.600,1", "plain rows in menu.text")
  assertEqual(rgba(survey(m, two.label).textColor), "0.100,0.200,0.300,1", "an item's own color wins")
  assertEqual(rgba(survey(m, one.__hl).color), "0,0,1,0.300", "the highlight in menu.hover")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  h:Refresh()
  assertEqual(rgba(survey(m, one.label).textColor), "0.900,0.900,0.900,1", "the next show reads Ka0s Default")
  assertEqual(rgba(survey(m, one.__hl).color), "1,0.820,0,0.150")
end)

-- ── the drag handle ──────────────────────────────────────────────────────────────────────────

local function handle(m, W, owner)
  return W.DragHandle(m.UIParent, { label = "Move", moveFrame = m.CreateFrame("Frame"), owner = owner,
                                    onClose = function() end, onRightClick = function() end })
end

test("skin owner: DragHandle without a registered owner is minor 5's", function()
  assertUnchanged(function(m, W, _, owner)
    local h = handle(m, W, owner)
    h.help:__fire("OnEnter"); h.help:__fire("OnLeave")
    h.close:__fire("OnEnter"); h.close:__fire("OnLeave")
  end, "DragHandle")
end)

test("skin owner: an owned DragHandle paints from its owner's skin and follows a switch alone", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  F.owner(Skin, OTHER, "azeroth")
  local h, o = handle(m, W, OWNER), handle(m, W, OTHER)
  assertEqual(rgba(survey(m, h.bg).color), tok(Skin, "obsidian", "handle.bg"))
  assertEqual(rgba(survey(m, h.__edges[1]).color), tok(Skin, "obsidian", "handle.edge"))
  local accent = Skin:ResolveSkin("obsidian")["text.accent"]
  assertEqual(rgba(survey(m, h.label).textColor), F.rgba({ accent[1], accent[2], accent[3] }))
  h.help:__fire("OnEnter")
  local hot = Skin:ResolveSkin("obsidian")["icon.hot"]
  assertEqual(rgba(survey(m, h.help.icon).vertex), F.rgba({ hot[1], hot[2], hot[3] }), "the hover tint")
  h.help:__fire("OnLeave")
  Skin:SetChoice(OWNER, "ka0s", "glass")
  assertEqual(rgba(survey(m, h.__edges[1]).color), tok(Skin, "glass", "handle.edge"), "repainted")
  assertEqual(rgba(survey(m, o.__edges[1]).color), tok(Skin, "azeroth", "handle.edge"), "the other owner's stays")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertEqual(rgba(survey(m, h.__edges[1]).color), "1,0.820,0,0.600", "Ka0s Default is minor 5's gold edge")
  assertEqual(rgba(survey(m, h.bg).color), "0,0,0,0.750")
end)

-- ── the reorder list and its ghost ───────────────────────────────────────────────────────────

local function reorder(m, W, owner)
  local list = W.ReorderList({ stride = 20, owner = owner })
  local row = m.CreateFrame("Frame", nil, m.UIParent)
  local h = list:AddRow(row, { ghostText = "Row" })
  list:AddRow(m.CreateFrame("Frame", nil, m.UIParent), { dimmed = true, draggable = false })
  list:Finish(m.UIParent)
  return list, h
end

local function drag(W, h)
  h:__fire("OnMouseDown")
  local g = W.__DragGhost
  h:__fire("OnMouseUp")
  return g
end

test("skin owner: ReorderList without a registered owner is minor 1's, ghost included", function()
  assertUnchanged(function(m, W, _, owner)
    local _, h = reorder(m, W, owner)
    drag(W, h)
  end, "ReorderList")
end)

test("skin owner: an owned ReorderList draws boxes, handle, line and ghost from the skin", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER, "obsidian")
  local list, h = reorder(m, W, OWNER)
  assertEqual(rgba(survey(m, list.boxes[1].fill).color), tok(Skin, "obsidian", "list.box"))
  assertEqual(rgba(survey(m, list.boxes[2].fill).color), tok(Skin, "obsidian", "list.boxDim"))
  assertEqual(rgba(survey(m, list.boxes[1].edges[1]).color), tok(Skin, "obsidian", "list.boxEdge"))
  local rest = Skin:ResolveSkin("obsidian")["handle.rest"]
  assertEqual(rgba(survey(m, h.art).vertex), F.rgba({ rest[1], rest[2], rest[3] }))
  assertEqual(F.rgba(list.color), tok(Skin, "obsidian", "list.dropLine"))
  local g = drag(W, h)
  assertEqual(rgba(survey(m, g.bg).color), tok(Skin, "obsidian", "list.ghostBg"), "the ghost follows the list")
  local _, plain = reorder(m, W, nil)
  drag(W, plain)
  assertEqual(rgba(survey(m, g.bg).color), "0.120,0.120,0.120,0.950", "an owner-less drag puts it back")
end)

test("skin owner: Ka0s Default draws the reorder list exactly as minor 1 did", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER)
  local list, h = reorder(m, W, OWNER)
  assertEqual(rgba(survey(m, list.boxes[1].fill).color), "1,1,1,0.060")
  assertEqual(rgba(survey(m, list.boxes[2].edges[1]).color), "1,1,1,0.060")
  assertEqual(rgba(survey(m, h.art).vertex), "0.700,0.700,0.700,1")
  assertEqual(F.rgba(list.color), "1,0.820,0,0.900")
  local g = drag(W, h)
  assertEqual(rgba(survey(m, g.bg).color), "0.120,0.120,0.120,0.950")
end)

-- ── the line chart ───────────────────────────────────────────────────────────────────────────

local function chartColors(c)
  local out = {}
  for _, l in ipairs(c.__madeLines) do
    if l:IsShown() or l == c.__cross then out[#out + 1] = F.rgba(l.__color) end
  end
  return table.concat(out, " ")
end

local function chart(m, W, owner)
  local c = W.LineChart(m.UIParent, { owner = owner })
  c:SetData({ xMin = 100, xMax = 300, markers = { { x = 200 } }, series = {
    { points = { { x = 100, y = 0 }, { x = 300, y = 10 } } },
    { points = { { x = 100, y = 5 }, { x = 300, y = 2 } }, colorIndex = 2 },
  } })
  c:Render(400, 200)
  return c
end

test("skin owner: LineChart without a registered owner reads lib.LINE_CHART as minor 3 did", function()
  local function colorsIn(noSkin, owner)
    local m, _, W = env(noSkin)
    return chartColors(chart(m, W, owner))
  end
  local bare = colorsIn(false, nil)
  assertEqual(colorsIn(false, OTHER), bare)
  assertEqual(colorsIn(true, OTHER), bare)
  assertTrue(not bare:find("0.950,0.550,0.150", 1, true), "an owner-less colorIndex draws LINE")
end)

test("skin owner: an owned LineChart takes its chrome and series from ChartStyle and re-renders", function()
  local m, Skin, W = env()
  F.owner(Skin, OWNER)
  local c = chart(m, W, OWNER)
  assertEqual(F.rgba(c.__cross.__color), tok(Skin, "ka0s", "chart.crosshair"))
  assertEqual(F.rgba(c.__madeLines[2].__color), tok(Skin, "ka0s", "chart.axis"), "the x axis, first drawn")
  assertTrue(chartColors(c):find(F.rgba(Skin:ResolveSkin("ka0s")["chart.series"][2]), 1, true) ~= nil,
    "colorIndex 2 is the skin's second series color")
  Skin:RegisterSkin({ key = "inky", tokens = { ["chart.axis"] = { 0, 1, 0, 1 },
                                               ["chart.crosshair"] = { 1, 0, 1, 1 } } })
  Skin:SetChoice(OWNER, "ka0s", "inky")
  assertEqual(F.rgba(c.__madeLines[2].__color), "0,1,0,1", "the switch re-rendered the axis")
  assertEqual(F.rgba(c.__cross.__color), "1,0,1,1", "and recolored the crosshair")
end)

-- ── the eight Widgets tokens (SkinDefs minor 3) ──────────────────────────────────────────────

test("skin owner: Ka0s Default's eight Widgets tokens are the constants they replace", function()
  local _, Skin, W = env()
  local K = Skin:ResolveSkin("ka0s")
  assertEqual(F.rgba(K["list.box"]), F.rgba(W.ROW_BOX.FILL))
  assertEqual(F.rgba(K["list.boxDim"]), F.rgba(W.ROW_BOX.FILL_DIM))
  assertEqual(F.rgba(K["list.boxEdge"]), F.rgba(W.ROW_BOX.EDGE))
  assertEqual(F.rgba(K["list.boxEdgeDim"]), F.rgba(W.ROW_BOX.EDGE_DIM))
  assertEqual(F.rgba(K["handle.edge"]), "1,0.820,0,0.600", "WidgetsDragHandle's edge")
  assertEqual(F.rgba(K["handle.rest"]), "0.700,0.700,0.700,1", "WidgetsReorder's handle at rest")
  assertEqual(F.rgba(K["list.dropLine"]), "1,0.820,0,0.900", "WidgetsReorder's insertion line")
  assertEqual(F.rgba(K["list.ghostBg"]), "0.120,0.120,0.120,0.950", "WidgetsReorder's ghost")
  local O = Skin:ResolveSkin("obsidian")
  assertEqual(F.rgba(O["handle.edge"]), F.rgba({ O["text.accent"][1], O["text.accent"][2], O["text.accent"][3], 0.6 }),
    "another skin derives the edge from its accent")
  assertEqual(F.rgba(O["list.box"]), F.rgba({ O["text.body"][1], O["text.body"][2], O["text.body"][3], 0.06 }),
    "and the boxes from its body text")
end)
