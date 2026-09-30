-- tests/test_options_combat_debug.lua — LibKa0s-Options-1.0's combat lock reaching the host's debug
-- sink (Options minor 27, gap G3 of the 2026-09-30 LibKa0s debug-gaps run).
--
-- The Options descriptor already took `debug(tag, message)` for the open refusal and the park
-- (OptionsRegistry minor 1). From this minor every refusal the combat lock decides writes ONE `Cfg`
-- line through it, naming what was refused -- a write, a page's Defaults, a library button (Reset
-- all settings among them), a session toggle, a tab or rail switch, a banner's selection or action,
-- an id list's change, a page shown under the lock -- and a registration parked in combat writes a
-- flush line when the end of combat replays it. Absent `debug`, the module stays silent, and the chat
-- (one gray notice per combat) is what it was at minor 26 either way.
--
-- Its own suite rather than more cases in tests/test_options_combat.lua, which pins the lock's
-- behavior; this one pins only what the lock tells the log.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse
local mocks = T.mocks
local Fixture = dofile("tests/fixture_options.lua")
local Ids = dofile("tests/fixture_ids.lua")("CombatDebugIds")

local lib = T.options

-- ── harness ──────────────────────────────────────────────────────────────────────────────────

local function fire(event)
  lib.__combatFrame:__fire("OnEvent", event)
end

local function enterCombat()
  fire("PLAYER_REGEN_DISABLED")
  mocks.InCombatLockdown = function() return true end
end

local function leaveCombat()
  mocks.InCombatLockdown = function() return false end
  fire("PLAYER_REGEN_ENABLED")
end

--- A case with the library's process-lived combat and park state put back however it ends.
local function lockCase(name, fn)
  test(name, function()
    local savedCombat, savedReg = mocks.InCombatLockdown, mocks.Settings.RegisterAddOnCategory
    local ok, err = pcall(fn)
    mocks.InCombatLockdown = function() return false end
    lib.__combatLocked = false
    lib.__parkedPanels = {}
    if lib.__parkFrame then lib.__parkFrame:UnregisterEvent("PLAYER_REGEN_ENABLED") end
    mocks.InCombatLockdown, mocks.Settings.RegisterAddOnCategory = savedCombat, savedReg
    if not ok then error(err, 0) end
  end)
end

--- A `debug` that records `tag|message`.
local function sink()
  local logs = {}
  return logs, function(tag, message) logs[#logs + 1] = tostring(tag) .. "|" .. tostring(message) end
end

local seq = 0

--- A host with a recording `debug` (or `debugValue` in its place, when the case passes one), and one
--- page on it.
local function host(pageKey, tabbed, noDebug, debugValue)
  local logs, debug = sink()
  local overrides = {}
  if not noDebug then overrides.debug = debugValue == nil and debug or debugValue end
  local O, rec = Fixture.new(overrides)
  seq = seq + 1
  local ctx = O.CreatePanel("CombatDebugPage" .. seq, "Combat Debug " .. seq,
    { pageKey = pageKey, defaultsButton = true })
  O.SetRenderer(ctx, function(c)
    O.ClearScroll(c)
    if tabbed then O.RenderTabbedSchema(c, pageKey) else O.RenderSchema(c, pageKey) end
  end)
  rec.logs = logs
  return O, rec, ctx
end

local function show(ctx)
  ctx.panel:Show()
  ctx.panel:__fire("OnShow")
end

local function widget(ctx, label)
  for _, w in ipairs(Fixture.flatten(ctx.scroll)) do
    if w.labelText == label then return w end
  end
end

local function assertLines(rec, want, label)
  assertEqual(#rec.logs, #want, label .. ": " .. table.concat(rec.logs, " || "))
  for i, line in ipairs(want) do assertEqual(rec.logs[i], line, label .. " (line " .. i .. ")") end
end

-- ── the version ────────────────────────────────────────────────────────────────────────────

test("opt combat debug: Options is at 27, with the six files the lines touch bumped", function()
  assertEqual(lib.MINOR, 27)
  assertEqual(lib.MODULES.Options, 27)
  assertEqual(lib.MODULES.OptionsRegistry, 2)
  assertEqual(lib.MODULES.OptionsWidgets, 33)
  assertEqual(lib.MODULES.OptionsIds, 2)
  assertEqual(lib.MODULES.OptionsIdList, 2)
  assertEqual(lib.MODULES.OptionsTabs, 7)
  assertEqual(lib.MODULES.OptionsNav, 2)
end)

-- ── refused writes ───────────────────────────────────────────────────────────────────────────

lockCase("opt combat debug: every refused write is one line naming the row; the notice stays once",
  function()
  local _, rec, ctx = host("general")
  show(ctx)
  assertLines(rec, {}, "nothing out of combat")
  enterCombat()
  widget(ctx, "Lock Position"):__fire("OnValueChanged", true)
  widget(ctx, "Show tooltips"):__fire("OnValueChanged", false)
  assertLines(rec, { "Cfg|write locked refused (in combat)", "Cfg|write showTooltips refused (in combat)" },
    "two writes, two lines")
  assertEqual(#rec.chat, 1, "and still one gray notice in chat")
  leaveCombat()
  widget(ctx, "Lock Position"):__fire("OnValueChanged", true)
  assertEqual(#rec.logs, 2, "a write out of combat writes no line")
end)

lockCase("opt combat debug: a color commit refused names its row", function()
  local _, rec, ctx = host("bar")
  show(ctx)
  enterCombat()
  widget(ctx, "Bar Color"):__fire("OnValueConfirmed", 0.1, 0.2, 0.3, 1)
  assertLines(rec, { "Cfg|write barColor refused (in combat)" }, "color")
end)

lockCase("opt combat debug: the page's Defaults, header button, footer control and RestoreDefaults",
  function()
  local O, rec, ctx = host("general")
  ctx.panel.defaultsOnClick = function() O.RestoreDefaults("general", ctx) end
  show(ctx)
  enterCombat()
  ctx.panel.defaultsBtn:__fire("OnClick")
  ctx.panel.OnDefault()
  O.RestoreDefaults("general", ctx)
  local title = ctx.panel.name
  assertLines(rec, {
    "Cfg|defaults " .. title .. " refused (in combat)",
    "Cfg|defaults " .. title .. " refused (in combat)",
    "Cfg|defaults general refused (in combat)",
  }, "three refusals, three lines")
end)

lockCase("opt combat debug: a library button (Reset all settings) names its text", function()
  local O, rec, ctx = host("general")
  show(ctx)
  O.InlineButtonPair(ctx, { text = "Reset all settings", onClick = function() end })
  local btn
  for _, w in ipairs(Fixture.flatten(ctx.scroll)) do
    if w.type == "Button" and w.text == "Reset all settings" then btn = w end
  end
  enterCombat()
  btn:__fire("OnClick")
  assertLines(rec, { "Cfg|button Reset all settings refused (in combat)" }, "button")
end)

lockCase("opt combat debug: a session checkbox names its label", function()
  local O, rec, ctx = host("general")
  show(ctx)
  local cb = O.SessionCheckbox(ctx, nil, 0.5, {
    label = "Debug console", get = function() return false end, set = function() end,
  })
  enterCombat()
  cb:__fire("OnValueChanged", true)
  assertLines(rec, { "Cfg|toggle Debug console refused (in combat)" }, "session toggle")
end)

-- ── refused switches ─────────────────────────────────────────────────────────────────────────

lockCase("opt combat debug: a tab click and SelectTab name the tab", function()
  local O, rec, ctx = host("tabbed", true)
  show(ctx)
  local beta
  for _, b in ipairs(ctx.__tabKids or {}) do
    if b.__ka0sTabTipLabel == "Beta" then beta = b end
  end
  assertTrue(beta ~= nil, "the strip was drawn")
  enterCombat()
  beta:__fire("OnClick")
  assertFalse(O.SelectTab("tabbed", "Beta"))
  assertLines(rec, { "Cfg|tab Beta refused (in combat)", "Cfg|tab tabbed/Beta refused (in combat)" },
    "the strip and the member")
end)

lockCase("opt combat debug: a nav rail click names the entry", function()
  local O, rec, ctx = host("tabbed", true)
  O.SetRenderer(ctx, function(c)
    O.ClearScroll(c)
    O.NavRail(c, { value = "a", onSelect = function() end,
      entries = { { key = "a", label = "A" }, { key = "b", label = "B" } } })
  end)
  show(ctx)
  enterCombat()
  ctx.__railKids[2]:__fire("OnClick")
  assertLines(rec, { "Cfg|rail b refused (in combat)" }, "rail")
end)

lockCase("opt combat debug: a page banner's selection and action name themselves", function()
  local O, rec, ctx = host("general")
  show(ctx)
  local dd, btn = O.PageBanner(ctx, { label = "Unit", list = { a = "A", b = "B" }, value = "a",
    onSelect = function() end, action = { text = "New container", onClick = function() end } })
  enterCombat()
  dd:__fire("OnValueChanged", "b")
  btn:__fire("OnClick")
  assertLines(rec, {
    "Cfg|banner select b refused (in combat)",
    "Cfg|banner action New container refused (in combat)",
  }, "banner")
end)

lockCase("opt combat debug: a page shown under the lock writes one line naming it", function()
  local _, rec, ctx = host("general")
  enterCombat()
  show(ctx)
  assertLines(rec, { "Cfg|show general refused (in combat)" }, "covered show")
end)

-- ── the id list ──────────────────────────────────────────────────────────────────────────────

lockCase("opt combat debug: an id list toggle and remove are one line each", function()
  local logs, debug = sink()
  local _, _, _, lines, log = Ids.listBench({ { id = 21562 }, { id = 774, toggle = true, on = true } },
    nil, nil, { debug = debug })
  enterCombat()
  lines[2].children[2]:__fire("OnValueChanged", false)
  lines[1].children[2]:__fire("OnClick")
  assertEqual(#log.toggled + #log.removed, 0, "nothing reached the host")
  assertEqual(#logs, 2, "one line per refusal, not two for the toggle: " .. table.concat(logs, " || "))
  assertEqual(logs[1], "Cfg|id list toggle 774 refused (in combat)")
  assertEqual(logs[2], "Cfg|id list change refused (in combat)")
end)

-- ── the registration park ────────────────────────────────────────────────────────────────────

lockCase("opt combat debug: a parked registration writes the parked line, then the flush line",
  function()
  local logs, debug = sink()
  mocks.Settings.RegisterAddOnCategory = function() end
  local O = Fixture.new({ debug = debug })
  mocks.InCombatLockdown = function() return true end
  O.CreateOptionsPanel()
  O.CreateOptionsPanel()
  assertEqual(table.concat(logs, " || "), "Cfg|register parked (in combat)", "parked once")
  mocks.InCombatLockdown = function() return false end
  lib.__parkFrame:__fire("OnEvent", "PLAYER_REGEN_ENABLED")
  assertEqual(#logs, 2)
  assertEqual(logs[2], "Cfg|register flushed (combat ended)", "the flush line when the replay runs")
end)

-- ── the silent default ───────────────────────────────────────────────────────────────────────

lockCase("opt combat debug: no debug on the descriptor is silent, and the chat is unchanged", function()
  local O, rec, ctx = host("general", false, true)
  assertTrue(rec.d.debug == nil)
  show(ctx)
  enterCombat()
  widget(ctx, "Lock Position"):__fire("OnValueChanged", true)
  ctx.panel.OnDefault()
  assertFalse(O.SelectTab("general", "x"))
  assertEqual(#rec.chat, 1, "one gray notice, as at minor 26")
  assertEqual(rec.store.locked, false)
  local P = Fixture.new()
  mocks.Settings.RegisterAddOnCategory = function() end
  P.CreateOptionsPanel()
  leaveCombat()
  lib.__parkFrame:__fire("OnEvent", "PLAYER_REGEN_ENABLED")
  assertEqual(#rec.logs, 0)
end)

lockCase("opt combat debug: a debug that is not a function is ignored", function()
  local _, rec, ctx = host("general", false, false, true)
  show(ctx)
  enterCombat()
  widget(ctx, "Lock Position"):__fire("OnValueChanged", true)
  assertEqual(#rec.chat, 1)
  assertEqual(#rec.logs, 0)
end)
