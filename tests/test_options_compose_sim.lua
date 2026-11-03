-- tests/test_options_compose_sim.lua — OptionsCompose minor 19: the Master controls tab's Sim mode
-- checkbox (R6-SIM-L of Ka0sAddonsCommonTasks docs/2026-11-03-SMOKE_ROUND6, the owner's "Add a sim
-- checkbox in settings (next to test) for all Ka0s addons that support it").
--
-- The host hands MasterControls the SAME pair its launcher descriptor carries, `isSimMode` and
-- `toggleSim` (Launcher minor 7). With both, the composer emits one session-only "Sim mode" row
-- beside Test mode, or beside Lock frame where the host has no Test mode row, whose get answers
-- isSimMode() and whose set(v) calls toggleSim() only when v differs from it. Without them nothing
-- changes. A NO MOCK suite for the rows, plus flow-engine renders for the line placement and the
-- checkbox's round trip.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertNil
local Fixture = dofile("tests/fixture_options.lua")
local Golden  = dofile("tests/fixture_compose_golden.lua")

local O = Fixture.new()

local SIM_PATH = "state.sim"
local SIM_TIP = "Run the addon's simulation, the same as its sim slash command, so the display " ..
  "plays scripted data. Untick it to stop the simulation. Session state: a reload ends it."

--- Every row's path, joined.
local function paths(rows)
  local out = {}
  for i, row in ipairs(rows) do out[i] = tostring(row.path) end
  return table.concat(out, "|")
end

--- The row carrying `path`, or nil.
local function rowAt(rows, path)
  for _, row in ipairs(rows) do
    if row.path == path then return row end
  end
end

--- A host's sim: the two launcher hooks over one flag. `refuse` makes a start do nothing, the way a
--- sim refused in combat or by its own prepare step leaves the flag off.
local function newSim()
  local sim = { active = false, refuse = false, toggles = 0 }
  sim.isSimMode = function() return sim.active end
  sim.toggleSim = function()
    sim.toggles = sim.toggles + 1
    if sim.active then sim.active = false elseif not sim.refuse then sim.active = true end
  end
  return sim
end

--- A framed spec with every canonical row, plus whatever the case adds.
local function full(extra)
  local s = { page = "general", addonName = "X", minimapPath = "global.minimap.hide",
    testModePath = "state.test", onResetAll = function() end, onResetPosition = function() end }
  for k, v in pairs(extra or {}) do s[k] = v end
  return s
end

--- `spec` with the sim's two hooks on it.
local function withSim(spec, sim)
  spec.isSimMode, spec.toggleSim = sim.isSimMode, sim.toggleSim
  return spec
end

--- A host that routes a row's own get/set at its descriptor, as LibKa0s-Schema's S.Get / S.Set do
--- for every row carrying them, and renders `rows` on a fresh panel.
local function render(name, rows)
  local own = {}
  for _, row in ipairs(rows) do
    if row.path and type(row.get) == "function" then own[row.path] = row end
  end
  local store = {}
  local Oi = Fixture.new{
    get = function(path)
      local r = own[path]
      if r then return r.get() end
      return store[path]
    end,
    set = function(path, value)
      local r = own[path]
      if r then return r.set(value) end
      store[path] = value
    end,
  }
  local ctx = Oi.CreatePanel(name, name, {})
  ctx.panel:Show()
  Oi.RenderRows(ctx, rows)
  return Oi, ctx
end

--- The CheckBox widget labeled `label` under `scroll`, or nil.
local function checkbox(scroll, label)
  for _, w in ipairs(Fixture.flatten(scroll)) do
    if w.type == "CheckBox" and w.labelText == label then return w end
  end
end

-- ── shown only with the hooks ────────────────────────────────────────────────────────────────

test("compose sim: without isSimMode and toggleSim the tab is byte for byte what it was", function()
  -- red under: a Sim mode row appearing, or any row moving, for a host that passed no hooks.
  local want = Golden.serialize(O.MasterControls(full()))
  local sim = newSim()
  assertEqual(Golden.serialize(O.MasterControls(full())), want)
  assertEqual(Golden.serialize(O.MasterControls(full{ isSimMode = sim.isSimMode })), want,
    "one hook alone draws nothing")
  assertEqual(Golden.serialize(O.MasterControls(full{ toggleSim = sim.toggleSim })), want,
    "one hook alone draws nothing")
  assertEqual(Golden.serialize(O.MasterControls(full{ isSimMode = true, toggleSim = "x" })), want,
    "non-functions draw nothing")
  local lockOnly = { page = "general", addonName = "X", lockIsPreview = true,
    minimapPath = "global.minimap.hide" }
  for _, row in ipairs(O.MasterControls(lockOnly)) do
    assertTrue(row.label ~= "Sim mode", "no Sim mode row without hooks")
  end
end)

test("compose sim: with both hooks the tab gains one session-only Sim mode row", function()
  -- red under: no row, a stored row, a row with no default for the reset walk, or other words.
  local rows = O.MasterControls(withSim(full(), newSim()))
  local row = rowAt(rows, SIM_PATH)
  assertTrue(row ~= nil, "a Sim mode row at state.sim")
  assertEqual(row.type, "bool")
  assertEqual(row.label, "Sim mode")
  assertEqual(row.tooltip, SIM_TIP)
  assertEqual(row.sessionOnly, true, "never persisted")
  assertEqual(row.default, false, "Reset all settings ends the sim")
  assertEqual(row.page, "general")
  assertEqual(row.group, "Master controls")
  assertEqual(type(row.get), "function")
  assertEqual(type(row.set), "function")
  local n = 0
  for _, r in ipairs(rows) do if r.label == "Sim mode" then n = n + 1 end end
  assertEqual(n, 1)
end)

test("compose sim: simPath moves the row, notes.simMode follows the tooltip", function()
  -- red under: ignoring simPath, or the note keyed by anything but the canonical leaf.
  local rows = O.MasterControls(withSim(full{ simPath = "session.sim",
    notes = { simMode = "Leaves the test mode alone." } }, newSim()))
  assertNil(rowAt(rows, SIM_PATH))
  local row = rowAt(rows, "session.sim")
  assertTrue(row ~= nil, "the row sits at the host's path, verbatim")
  assertEqual(row.tooltip, SIM_TIP .. " Leaves the test mode alone.")
  -- omit.simMode drops it, like any canonical leaf.
  assertNil(rowAt(O.MasterControls(withSim(full{ omit = { simMode = true } }, newSim())), SIM_PATH))
end)

-- ── placement ────────────────────────────────────────────────────────────────────────────────

test("compose sim: it follows Test mode and opens its own line when Test pairs beside Minimap", function()
  -- red under: Sim mode anywhere but straight after Test mode, or pairing a full line.
  local rows = O.MasterControls(withSim(full(), newSim()))
  assertEqual(paths(rows), "enabled|visibility|scale|alpha|locked|state.debugConsole|" ..
    "global.minimap.hide|state.test|" .. SIM_PATH)
  assertNil(rowAt(rows, "state.test").startsLine, "Test mode still pairs beside Minimap button")
  assertEqual(rowAt(rows, SIM_PATH).startsLine, true)
end)

test("compose sim: it pairs beside Test mode when Test opens its own line", function()
  -- red under: Sim mode opening a line under a Test mode that sits alone.
  local rows = O.MasterControls(withSim(full{ omit = { locked = true } }, newSim()))
  assertEqual(rowAt(rows, "state.test").startsLine, true)
  assertNil(rowAt(rows, SIM_PATH).startsLine)
  rows = O.MasterControls(withSim(full{ minimapPath = false }, newSim()))
  assertEqual(rowAt(rows, "state.test").startsLine, true, "no minimap row: Test opens its line")
  assertNil(rowAt(rows, SIM_PATH).startsLine)
end)

test("compose sim: with no Test mode row it pairs beside Lock frame", function()
  -- red under: Sim mode going anywhere but beside Lock frame for a host without a Test mode, or
  -- the console and minimap rows left with the shape they had before it took their place.
  local spec = withSim({ page = "general", addonName = "X", lockIsPreview = true,
    minimapPath = "global.minimap.hide", onResetAll = function() end }, newSim())
  local rows = O.MasterControls(spec)
  assertEqual(paths(rows), "enabled|visibility|scale|alpha|locked|" .. SIM_PATH ..
    "|state.debugConsole|global.minimap.hide")
  assertEqual(rowAt(rows, "locked").startsLine, true)
  assertNil(rowAt(rows, SIM_PATH).startsLine, "beside Lock frame")
  assertEqual(rowAt(rows, "state.debugConsole").startsLine, true, "the console opens the next line")
  assertNil(rowAt(rows, "global.minimap.hide").startsLine, "Minimap button beside the console")
end)

test("compose sim: with neither Test mode nor Lock frame it takes Test mode's slot", function()
  -- red under: pairing beside a Lock frame that was never emitted.
  local rows = O.MasterControls(withSim({ page = "general", addonName = "X", frameless = true,
    minimapPath = "global.minimap.hide", onResetAll = function() end }, newSim()))
  assertEqual(paths(rows), "enabled|visibility|state.debugConsole|global.minimap.hide|" .. SIM_PATH)
  assertEqual(rowAt(rows, SIM_PATH).startsLine, true, "the minimap sits beside the console")
end)

test("compose sim: the flow engine draws it beside Test mode and beside Lock frame", function()
  -- red under: the placement living in the rows but not reaching the two-column engine.
  local _, ctx = render("ComposeSimBesideTest",
    O.MasterControls(withSim(full{ omit = { locked = true } }, newSim())))
  local line = Fixture.rowWithLabel(ctx.scroll, "Sim mode")
  assertTrue(line ~= nil, "Sim mode was drawn")
  assertEqual(line, Fixture.rowWithLabel(ctx.scroll, "Test mode"), "Sim mode shares Test mode's line")

  _, ctx = render("ComposeSimBesideLock", O.MasterControls(withSim({ page = "general",
    addonName = "X", lockIsPreview = true, minimapPath = "global.minimap.hide" }, newSim())))
  line = Fixture.rowWithLabel(ctx.scroll, "Sim mode")
  assertEqual(line, Fixture.rowWithLabel(ctx.scroll, "Lock frame"), "Sim mode shares Lock frame's line")
  assertEqual(Fixture.rowWithLabel(ctx.scroll, "Debug console"),
    Fixture.rowWithLabel(ctx.scroll, "Minimap button"), "the console and the minimap share a line")
end)

-- ── the act ──────────────────────────────────────────────────────────────────────────────────

test("compose sim: the row reads the live sim and toggles only on a change", function()
  -- red under: a set that toggles unconditionally, which would start a sim on Reset all settings.
  local sim = newSim()
  local row = rowAt(O.MasterControls(withSim(full(), sim)), SIM_PATH)
  assertEqual(row.get(), false)
  row.set(false)
  assertEqual(sim.toggles, 0, "set(false) on an idle sim does nothing")
  row.set(true)
  assertEqual(sim.toggles, 1)
  assertEqual(row.get(), true)
  row.set(true)
  assertEqual(sim.toggles, 1, "set(true) on a running sim does nothing")
  row.set(false)
  assertEqual(sim.toggles, 2)
  assertEqual(row.get(), false)
  sim.active = true
  assertEqual(row.get(), true, "a sim started elsewhere reads as on")
end)

test("compose sim: ticking starts the sim, unticking stops it", function()
  -- red under: the checkbox writing a stored value instead of calling the host's toggle.
  local sim = newSim()
  local _, ctx = render("ComposeSimToggle", O.MasterControls(withSim(full(), sim)))
  local cb = checkbox(ctx.scroll, "Sim mode")
  assertTrue(cb ~= nil, "the checkbox was drawn")
  assertEqual(cb:GetValue(), false)
  cb:__fire("OnValueChanged", true)
  assertEqual(sim.active, true, "ticking starts the sim")
  assertEqual(sim.toggles, 1)
  assertEqual(cb:GetValue(), true)
  cb:__fire("OnValueChanged", false)
  assertEqual(sim.active, false, "unticking stops it")
  assertEqual(sim.toggles, 2)
  assertEqual(cb:GetValue(), false)
end)

test("compose sim: a refused start leaves the box unticked", function()
  -- red under: the box echoing the click instead of re-reading the sim after the call.
  local sim = newSim()
  sim.refuse = true
  local _, ctx = render("ComposeSimRefused", O.MasterControls(withSim(full(), sim)))
  local cb = checkbox(ctx.scroll, "Sim mode")
  cb:SetValue(true)   -- what AceGUI's own click leaves on the widget
  cb:__fire("OnValueChanged", true)
  assertEqual(sim.toggles, 1, "the host was asked")
  assertEqual(sim.active, false)
  assertEqual(cb:GetValue(), false, "the box reads the sim again, and it is still off")
end)

test("compose sim: the combat lock's refusal reaches no toggle and leaves the box as it was", function()
  -- red under: the row bypassing the flow engine's write seam.
  local sim = newSim()
  local Oi, ctx = render("ComposeSimCombat", O.MasterControls(withSim(full(), sim)))
  local cb = checkbox(ctx.scroll, "Sim mode")
  local saved = Oi.__combatRefused
  Oi.__combatRefused = function() return true end
  cb:SetValue(true)
  cb:__fire("OnValueChanged", true)
  Oi.__combatRefused = saved
  assertEqual(sim.toggles, 0, "no toggle in combat")
  assertEqual(cb:GetValue(), false)
end)

test("compose sim: a sim started elsewhere shows on the next refresh and on the panel's show", function()
  -- red under: the box staying stale until the page is rebuilt.
  local sim = newSim()
  local rows, tail = O.MasterControls(withSim(full(), sim))
  local Oi, ctx = render("ComposeSimLive", rows)
  local cb = checkbox(ctx.scroll, "Sim mode")
  sim.active = true                       -- `/xx sim`, the sim panel, the launcher
  Oi.RefreshScalars()                     -- the host's signal, off its sim's listener
  assertEqual(cb:GetValue(), true)

  -- The tail arms a refresh on the panel's show, once however often the page renders.
  local saved = Oi.InlineButtonPair
  Oi.InlineButtonPair = function() end
  tail(ctx)
  tail(ctx)
  Oi.InlineButtonPair = saved
  sim.active = false                      -- the sim ended on its own while the page was hidden
  ctx.panel:Hide()
  ctx.panel:Show()
  ctx.panel:__fire("OnShow")
  assertEqual(cb:GetValue(), false, "the show re-read the sim")
end)

test("compose sim: Reset all settings stops a running sim and starts none", function()
  -- red under: the reset walk toggling, or skipping the session row.
  local sim = newSim()
  local row = rowAt(O.MasterControls(withSim(full(), sim)), SIM_PATH)
  row.set(row.default)
  assertEqual(sim.toggles, 0, "an idle sim stays idle")
  sim.active = true
  row.set(row.default)
  assertEqual(sim.active, false, "a running sim is stopped")
end)

test("compose sim: the spec is never written and two calls agree", function()
  -- red under: the composer stashing its closures or its row on the host's spec.
  local spec = withSim(full(), newSim())
  local first = Golden.serialize(O.MasterControls(spec))
  assertEqual(Golden.serialize(O.MasterControls(spec)), first)
  assertNil(spec.simPath)
  assertNil(spec.omit)
end)

-- ── the minor ────────────────────────────────────────────────────────────────────────────────

test("compose sim: OptionsCompose is at minor 19", function()
  -- red under: the change landing without its bump: every host vendors minor 18, and a minor-18
  -- copy loaded first would keep a tab with no Sim mode row.
  assertEqual(T.options.MODULES.OptionsCompose, 19)
end)
