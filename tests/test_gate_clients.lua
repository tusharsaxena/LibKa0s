-- tests/test_gate_clients.lua -- the `clients` gate of the slash, launcher and keybinds surfaces
-- (WFP-LK-04). Slash.lua minor 22, Launcher.lua minor 8 and OptionsKeybinds.lua minor 8.
--
-- An entry declared `clients = { "retail" }` does not exist on a Forever client: the verb is not
-- dispatched, listed or counted and typing it gets the unknown-verb line, the menu has no row for the
-- launcher entry, and the keybind row is never drawn. Each case sets the project constants itself,
-- so it holds under either KA0S_KIT_CLIENT profile.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse
local mocks = T.mocks

local ABSENT = {}
local RETAIL  = { WOW_PROJECT_ID = 1,  WOW_PROJECT_MAINLINE = 1, WOW_PROJECT_CAMELOT = ABSENT }
local FOREVER = { WOW_PROJECT_ID = 18, WOW_PROJECT_MAINLINE = 1, WOW_PROJECT_CAMELOT = 18 }

--- Run `fn` with the project constants of `client`, restoring them afterwards.
local function on(client, fn)
  local saved = {}
  for k, v in pairs(client) do
    saved[k] = mocks[k]
    if rawequal(v, ABSENT) then mocks[k] = nil else mocks[k] = v end
  end
  local ok, err = pcall(fn)
  for k in pairs(client) do mocks[k] = saved[k] end
  if not ok then error(err, 0) end
end

-- ── slash ─────────────────────────────────────────────────────────────────────────────────────

local F = dofile("tests/fixture_slash.lua")

--- A dispatcher whose verb table carries one retail-only verb, `scan`, and one for every client.
local function slashHost(clients)
  local Sl, rec = F.new()
  rec.ran = 0
  rec.commands[#rec.commands + 1] = { "scan", "Scan the group", function() rec.ran = rec.ran + 1 end,
    clients = clients }
  return Sl, rec
end

-- test_gate_slash_verb_absent_on_forever
test("gate clients: a retail verb is not dispatched, listed or counted on Forever", function()
  on(FOREVER, function()
    local Sl, rec = slashHost({ "retail" })
    local base = #Sl:HelpRows()
    Sl:OnSlash("scan")
    assertEqual(rec.ran, 0, "the handler never ran")
    assertTrue(F.plain(rec.chat[1]):find("unknown command 'scan'", 1, true) ~= nil,
      "the dispatcher's own unknown-verb line: " .. tostring(rec.chat[1]))
    for _, row in ipairs(Sl:HelpRows()) do
      assertTrue(F.plain(row):find("scan", 1, true) == nil, "not in the help: " .. row)
    end
    assertEqual(#Sl:LandingRows(), base, "not in the landing rows either")
    assertEqual(#rec.commands, base + 1, "the host's own table is untouched")
  end)
  on(RETAIL, function()
    local Sl, rec = slashHost({ "retail" })
    Sl:OnSlash("scan")
    assertEqual(rec.ran, 1, "Retail dispatches it")
    local listed = false
    for _, row in ipairs(Sl:HelpRows()) do
      if F.plain(row):find("scan", 1, true) then listed = true end
    end
    assertTrue(listed, "and lists it")
  end)
end)

test("gate clients: a forever-only verb is absent on Retail, and no clients means every client", function()
  on(RETAIL, function()
    local Sl, rec = slashHost({ "forever" })
    Sl:OnSlash("scan")
    assertEqual(rec.ran, 0)
    Sl:OnSlash("version")
    assertTrue(#rec.chat >= 2, "an ungated verb still answers")
  end)
  on(FOREVER, function()
    local Sl, rec = slashHost(nil)
    Sl:OnSlash("scan")
    assertEqual(rec.ran, 1, "ungated, Forever runs it")
  end)
end)

-- ── launcher ──────────────────────────────────────────────────────────────────────────────────

local launcher = T.launcher
-- Built inside the case, not at load: the mock installs itself on `mocks`, and test_launcher.lua's
-- own menu mock must be the one in place when that suite runs.
local MENU
local OWNER = { name = "LibDBIcon10_GateHost" }
if not mocks.LibStub("LibDataBroker-1.1", true) then
  local LDB = mocks.LibStub:NewLibrary("LibDataBroker-1.1", 1)
  LDB.__objects = {}
  function LDB:NewDataObject(name, tbl)
    if self.__objects[name] then return nil end
    self.__objects[name] = tbl
    return tbl
  end
  function LDB:GetDataObjectByName(name) return self.__objects[name] end
end
if not mocks.LibStub("LibDBIcon-1.0", true) then
  local ICON = mocks.LibStub:NewLibrary("LibDBIcon-1.0", 1)
  function ICON:Register() end
  function ICON:Show() end
  function ICON:Hide() end
end

local seq = 0
--- The texts of the menu a right click opens on a launcher whose Sim mode entry carries `clients`.
local function menuTexts(clients)
  seq = seq + 1
  local d = {
    name = "GateHost" .. seq, icon = "Interface\\AddOns\\GateHost\\logo.tga",
    minimap = function() return {} end, openSettings = function() end, print = function() end,
    isEnabled = function() return true end, setEnabled = function() end,
    isSimMode = function() return false end, toggleSim = function() end,
    entryClients = clients and { toggleSim = clients } or nil,
  }
  local L = launcher:New(d)
  L:Register()
  MENU.reset()
  L:Object().OnClick(OWNER, "RightButton")
  return table.concat(MENU.last:Texts(), "|")
end

-- test_gate_launcher_entry_absent_on_forever
test("gate clients: a retail launcher entry is not built on Forever", function()
  local savedUtil, savedResponse = mocks.MenuUtil, mocks.MenuResponse
  MENU = dofile("tests/mock_menu.lua")(mocks)
  local ok, err = pcall(function()
  on(FOREVER, function()
    assertEqual(menuTexts({ "retail" }), "Enabled|Open settings", "no Sim mode checkbox")
  end)
  on(RETAIL, function()
    assertEqual(menuTexts({ "retail" }), "Enabled|Sim mode|Open settings", "Retail builds it")
  end)
  on(FOREVER, function()
    assertEqual(menuTexts(nil), "Enabled|Sim mode|Open settings", "no declaration, every client")
    assertEqual(menuTexts({ "forever" }), "Enabled|Sim mode|Open settings", "a forever entry on Forever")
  end)
  on(RETAIL, function()
    assertEqual(menuTexts({ "forever" }), "Enabled|Open settings", "the mirror")
  end)
  end)
  mocks.MenuUtil, mocks.MenuResponse = savedUtil, savedResponse
  if not ok then error(err, 0) end
end)

-- ── keybinds ──────────────────────────────────────────────────────────────────────────────────

local Bench = dofile("tests/fixture_keybinds.lua")

-- test_gate_keybind_row_absent_on_forever
Bench.case("gate clients: a retail keybind row is never drawn on Forever", function()
  local bindings = {
    { command = Bench.TOGGLE, tooltip = "Shown everywhere." },
    { command = Bench.SECOND, tooltip = "Retail only.", clients = { "retail" } },
  }
  on(FOREVER, function()
    local _, _, _, rows = Bench.rowsPage({ bindings = bindings })
    assertEqual(#rows(), 1, "one row")
    assertEqual(rows()[1].command, Bench.TOGGLE)
  end)
  on(RETAIL, function()
    local _, _, _, rows = Bench.rowsPage({ bindings = bindings })
    assertEqual(#rows(), 2, "Retail draws both")
  end)
  on(FOREVER, function()
    local O = Bench.page(function() end)
    local tab = O.KeybindingsTab({ clients = { "retail" } })
    assertFalse(tab.clients == nil, "the tab carries its declaration to the tabbed page")
  end)
end)
