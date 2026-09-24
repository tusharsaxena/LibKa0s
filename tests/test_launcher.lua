-- tests/test_launcher.lua — LibKa0s-Launcher-1.0: one broker object, registered twice.
--
-- What these cases pin is `launcher-§1`/`§2`/`§3`, which are rules about a SHAPE rather than about
-- pixels: exactly one LibDataBroker object of `type = "launcher"`; one OnClick that both surfaces
-- dispatch into, so the click rule cannot be satisfied on the minimap and missed in a broker
-- display; and LibDBIcon's OWN `minimap` table handed straight in, never copied. Every one of those
-- is checkable with no client at all, which is the whole reason the wiring lives here rather than
-- eleven times over in eleven addons.
--
-- NEITHER BROKER LIBRARY IS MOCKED IN `tests/wow_mock.lua`, and that is deliberate. They are
-- optional to this module (`LibStub(..., true)` at Register time), the degraded paths are the ones
-- an addon actually ships into, and a base-level fake would make all three of them unreachable.
-- The fakes below are registered into the mock's own LibStub registry, and `withoutLibs` takes them
-- away again for the cases that need them gone.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil, assertErrorMatches =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil, T.assertErrorMatches
local mocks = T.mocks
local lib = T.launcher

-- ── the two fakes ────────────────────────────────────────────────────────────────────────────
--
-- FIDELITY, not convenience. `NewDataObject` answers nil for a name already taken, exactly as the
-- real one does — that is the whole subject of one case below — and `Register` records the table it
-- was handed rather than a copy of it, because "the same table" is the assertion `launcher-§3`
-- turns on.

local LDB = mocks.LibStub:NewLibrary("LibDataBroker-1.1", 1)
LDB.__objects = {}
function LDB:NewDataObject(name, tbl)
  if self.__objects[name] then return nil end
  self.__objects[name] = tbl
  return tbl
end
function LDB:GetDataObjectByName(name) return self.__objects[name] end

local ICON = mocks.LibStub:NewLibrary("LibDBIcon-1.0", 1)
ICON.__buttons = {}
function ICON:Register(name, object, db)
  self.__buttons[name] = { object = object, db = db, shown = not (db and db.hide), calls = 1 }
end
function ICON:Show(name)
  local b = self.__buttons[name]
  if b then b.shown = true end
end
function ICON:Hide(name)
  local b = self.__buttons[name]
  if b then b.shown = false end
end

--- Run `fn` with the named LibStub majors invisible, then put the registry back.
---
--- The module resolves both libraries at CALL time through the environment's `LibStub`, so swapping
--- that one field is enough and nothing has to be unloaded. `silent` is honored exactly as the
--- mock's own LibStub honors it: a non-silent lookup of a blocked major still raises, so a case
--- cannot pass because the module forgot its `, true`.
local function withoutLibs(blockedNames, fn)
  local blocked = {}
  for _, n in ipairs(blockedNames) do blocked[n] = true end
  local original = mocks.LibStub
  mocks.LibStub = setmetatable({
    GetLibrary = function(_, major, silent)
      if blocked[major] then
        if not silent then error("Cannot find a library instance of " .. tostring(major)) end
        return nil
      end
      return original:GetLibrary(major, silent)
    end,
    NewLibrary = function(_, major, minor) return original:NewLibrary(major, minor) end,
  }, { __call = function(self, major, silent) return self:GetLibrary(major, silent) end })
  local ok, err = pcall(fn)
  mocks.LibStub = original
  if not ok then error(err, 0) end
end

-- Each case takes its own addon name, because LibDataBroker's registry is process-wide in the
-- client too and a suite that shared one name would be testing the fake's reset rather than the
-- module.
local seq = 0
local function nextName()
  seq = seq + 1
  return "TestHost" .. seq
end

--- A descriptor with everything required filled in, plus a recorder for what the module reports.
local function fixture(over)
  local rec = {
    name = nextName(),
    lines = {},
    logs = {},
    opened = 0,
    left = 0,
    leftButton = nil,
    minimap = {},
  }
  local d = {
    name = rec.name,
    icon = "Interface\\AddOns\\TestHost\\media\\logos\\testhost.logo.128.tga",
    minimap = function() return rec.minimap end,
    openSettings = function() rec.opened = rec.opened + 1 end,
    print = function(line) rec.lines[#rec.lines + 1] = line end,
    debug = function(tag, message) rec.logs[#rec.logs + 1] = tag .. ": " .. message end,
  }
  for k, v in pairs(over or {}) do d[k] = v end
  rec.d = d
  return rec
end

--- Every reported line, joined, so a case can ask what was said without indexing.
local function said(rec)
  return table.concat(rec.lines, "\n")
end

-- ── the descriptor ───────────────────────────────────────────────────────────────────────────

test("launcher: New refuses a descriptor missing name, icon or openSettings", function()
  -- All three are load-bearing and none has a defensible default. The FOLDER name keys LibDBIcon's
  -- saved position, the icon is the addon's face in three places (launcher-§4), and right-click
  -- ALWAYS opens the panel, so a launcher with no way to do that is one rule short on every addon.
  -- red under: defaulting any of them, which ships a button that draws nothing or loses the angle
  -- the player dragged it to.
  assertErrorMatches(function() lib:New{ icon = "x", openSettings = function() end } end,
    "requires descriptor.name")
  assertErrorMatches(function() lib:New{ name = "X", openSettings = function() end } end,
    "requires descriptor.icon")
  assertErrorMatches(function() lib:New{ name = "X", icon = "x" } end,
    "requires descriptor.openSettings")
  assertErrorMatches(function() lib:New{ name = "", icon = "x", openSettings = function() end } end,
    "requires descriptor.name", "an empty string is not a folder name")
end)

-- ── one object, registered twice ─────────────────────────────────────────────────────────────

test("launcher: ONE object, of type 'launcher', carrying the host's own icon", function()
  -- launcher-§1. `"launcher"` is the reason rather than a label: a broker display reads `type` to
  -- decide what to draw, and `"data source"` promises a `text` value this object does not have.
  -- red under: `type = "data source"`, which draws an empty value cell beside the icon forever.
  local rec = fixture()
  local L = lib:New(rec.d)
  assertNil(L:Object(), "nothing is registered until Register is called")
  assertTrue(L:Register())
  local obj = L:Object()
  assertEqual(obj.type, "launcher")
  assertEqual(obj.icon, rec.d.icon)
  assertEqual(obj.label, rec.name, "the label defaults to the folder name")
  assertEqual(type(obj.OnClick), "function")
  assertEqual(LDB.__objects[rec.name], obj, "the broker registry holds exactly this object")
  assertEqual(ICON.__buttons[rec.name].object, obj,
    "and LibDBIcon draws its button from the very same one")
end)

test("launcher: both registrations use the addon's folder name, and a host may relabel", function()
  -- The NAME is not cosmetic: LibDBIcon keys the button's saved position by it, so two spellings
  -- drop the angle the player dragged the button to. The LABEL is what a display prints and is the
  -- host's to choose.
  -- red under: labeling one registration and naming the other, which is the drift §1 names.
  local rec = fixture{ label = "Test Host" }
  local L = lib:New(rec.d)
  L:Register()
  assertEqual(L:Object().label, "Test Host")
  assertTrue(LDB.__objects[rec.name] ~= nil, "registered under the FOLDER name, not the label")
  assertTrue(ICON.__buttons[rec.name] ~= nil, "and so is the button")
end)

test("launcher: Register is idempotent, so a second call builds no second button", function()
  -- A host may call this from OnInitialize and again from a login handler. LibDBIcon's Register on
  -- a name it already holds would otherwise build a second button over the first.
  -- red under: re-registering, which is a button the player can see but not drag away from.
  local rec = fixture()
  local L = lib:New(rec.d)
  assertTrue(L:Register())
  local obj = L:Object()
  assertTrue(L:Register(), "the second call reports the launcher wired, as it is")
  assertEqual(L:Object(), obj, "and hands back the same object")
  assertEqual(ICON.__buttons[rec.name].calls, 1, "LibDBIcon was asked exactly once")
end)

test("launcher: IsRegistered is false until BOTH halves are wired", function()
  -- red under: reporting registered off the broker object alone, which tells a host the button is
  -- there when only the plugin is.
  local rec = fixture()
  local L = lib:New(rec.d)
  assertFalse(L:IsRegistered())
  L:Register()
  assertTrue(L:IsRegistered())
end)

-- ── the status tooltip (minor 3, launcher-§1; hints fixed at minor 4, standard v2.67.0) ───────
--
-- The library draws it, always, in one shape for all eleven addons:
--
--   <label>  v<version>          (version optional)
--   Enabled: Yes|No              (always)
--   Locked: Yes|No               (only with isLocked)
--   Test mode: On|Off            (only with isTestMode)
--   <the host's own lines>       (onTooltipShow, appended once)
--   Left-click: Open settings
--   Right-click: Options menu

--- A GameTooltip stand-in that records each line's text, and nothing it was not asked to hold.
local function fakeTooltip()
  local tt = { lines = {} }
  function tt:AddLine(line) self.lines[#self.lines + 1] = line end
  return tt
end

--- A line with its color escapes taken out, which is what the player reads.
local function plain(line)
  return (tostring(line):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

--- Show the tooltip once and answer the plain lines, then the raw ones.
local function hover(L)
  local tt = fakeTooltip()
  L:Object().OnTooltipShow(tt)
  local out = {}
  for i, line in ipairs(tt.lines) do out[i] = plain(line) end
  return out, tt.lines
end

local LEFT_HINT, RIGHT_HINT = "Left-click: Open settings", "Right-click: Options menu"

--- The fields minor 4 retired. Passed by a host that has not yet re-vendored its setup file.
local function retiredFields(rec)
  return {
    onClick = function() rec.left = rec.left + 1 end,
    leftClickLabel = "Toggle window",
    disabledLine = function() return "TestHost is disabled \226\128\148 enable it with /th enable" end,
    slash = "th",
  }
end

test("launcher: the library ALWAYS draws the tooltip, and a host need pass nothing", function()
  -- launcher-§1 (v2.66.0): the tooltip is a MUST, drawn by this module from the descriptor, so a
  -- host that passes no hook still answers a hover with its name, its state and its two clicks.
  -- red under: minor 2's pass-through, which left OnTooltipShow nil and the button silent.
  local rec = fixture()
  local L = lib:New(rec.d)
  L:Register()
  assertEqual(type(L:Object().OnTooltipShow), "function", "set with no host hook at all")
  local lines = hover(L)
  assertEqual(table.concat(lines, "\n"), table.concat({
    rec.name,
    "Enabled: Yes",
    LEFT_HINT,
    RIGHT_HINT,
  }, "\n"))
end)

test("launcher: the tooltip title is the label, and the version where one is passed", function()
  -- red under: a title read from the folder name when a label was given, or a doubled `vv`.
  local rec = fixture{ label = "Ka0s Test Host", version = "1.2.3" }
  local L = lib:New(rec.d)
  L:Register()
  assertEqual(hover(L)[1], "Ka0s Test Host  v1.2.3")

  local rec2 = fixture{ label = "Ka0s Test Host", version = "v2.0.0" }
  local L2 = lib:New(rec2.d)
  L2:Register()
  assertEqual(hover(L2)[1], "Ka0s Test Host  v2.0.0", "a leading v is not doubled")

  local v = "3.0.0"
  local rec3 = fixture{ label = "Ka0s Test Host", version = function() return v end }
  local L3 = lib:New(rec3.d)
  L3:Register()
  assertEqual(hover(L3)[1], "Ka0s Test Host  v3.0.0", "a function is asked")
  v = nil
  assertEqual(hover(L3)[1], "Ka0s Test Host", "and answering nothing drops the version")
end)

test("launcher: the tooltip's Enabled line is green Yes or red No, read from isEnabled", function()
  -- The one status line on every addon (slash-commands-§7), and the only color is the value's.
  -- red under: an uncolored value, or a disabled addon reading Yes.
  local enabled = true
  local rec = fixture{ isEnabled = function() return enabled end }
  local L = lib:New(rec.d)
  L:Register()
  local lines, raw = hover(L)
  assertEqual(lines[2], "Enabled: Yes")
  assertTrue(raw[2]:find("|cFF00FF00Yes|r", 1, true) ~= nil, "Yes is green")
  enabled = false
  lines, raw = hover(L)
  assertEqual(lines[2], "Enabled: No")
  assertTrue(raw[2]:find("|cFFFF0000No|r", 1, true) ~= nil, "No is red")
  assertTrue(raw[1]:find("|c", 1, true) == nil, "the title carries no color")
end)

test("launcher: the click hints are fixed, in either state, whatever retired fields are passed", function()
  -- launcher-§1/§2 (v2.67.0): left opens settings and right opens the menu on every addon, so
  -- neither hint varies by addon or changes while disabled. Minor 3's leftClickLabel and its
  -- `disabled — /<slash> enable` form described the retired rungs.
  -- red under: a hint read from leftClickLabel, or a disabled pointer on a button that still works.
  for _, enabled in ipairs{ true, false } do
    local rec = fixture()
    local over = retiredFields(rec)
    over.isEnabled = function() return enabled end
    for k, v in pairs(over) do rec.d[k] = v end
    local L = lib:New(rec.d)
    L:Register()
    local lines = hover(L)
    assertEqual(lines[#lines - 1], LEFT_HINT, "enabled=" .. tostring(enabled))
    assertEqual(lines[#lines], RIGHT_HINT, "enabled=" .. tostring(enabled))
    assertEqual(#rec.lines, 0, "hovering prints nothing to chat")
  end
end)

--- The descriptor fields one matrix cell passes, and the lines it must draw.
local function matrixCell(rec, enabled, retired, lockMode, testMode)
  local over = {
    label = "Ka0s Test Host",
    version = "9.9.9",
    isEnabled = function() return enabled end,
  }
  local want = { "Ka0s Test Host  v9.9.9", "Enabled: " .. (enabled and "Yes" or "No") }
  if lockMode ~= "absent" then
    over.isLocked = function() return lockMode end
    want[#want + 1] = "Locked: " .. (lockMode and "Yes" or "No")
  end
  if testMode ~= "absent" then
    over.isTestMode = function() return testMode end
    want[#want + 1] = "Test mode: " .. (testMode and "On" or "Off")
  end
  if retired then
    for k, v in pairs(retiredFields(rec)) do over[k] = v end
  end
  want[#want + 1] = LEFT_HINT
  want[#want + 1] = RIGHT_HINT
  return over, want
end

test("launcher: every combination of state and status lines draws the fixed shape", function()
  -- The matrix the shape is written for: enabled or disabled, retired fields passed or not, with
  -- or without a lock, with or without a test mode, each value both ways. Status lines appear only
  -- for the states the addon has (never a permanent No), and the order never moves.
  -- red under: any line out of order, a status line drawn for a state not passed, or a hint that
  -- moves with state or with a retired field.
  local cases = 0
  for _, enabled in ipairs{ true, false } do
    for _, retired in ipairs{ true, false } do
      for _, lockMode in ipairs{ "absent", true, false } do
        for _, testMode in ipairs{ "absent", true, false } do
          local rec = fixture()
          local over, want = matrixCell(rec, enabled, retired, lockMode, testMode)
          for k, v in pairs(over) do rec.d[k] = v end
          local L = lib:New(rec.d)
          L:Register()
          local label = ("enabled=%s retired=%s lock=%s test=%s"):format(
            tostring(enabled), tostring(retired), tostring(lockMode), tostring(testMode))
          assertEqual(table.concat(hover(L), "\n"), table.concat(want, "\n"), label)
          cases = cases + 1
        end
      end
    end
  end
  assertEqual(cases, 36)
end)

test("launcher: tooltip Locked and Test mode values are green for Yes/On, red for No/Off", function()
  -- red under: status values drawn plain, which the standard's one permitted color is for.
  local rec = fixture{ isLocked = function() return true end, isTestMode = function() return false end }
  local L = lib:New(rec.d)
  L:Register()
  local _, raw = hover(L)
  assertTrue(raw[3]:find("|cFF00FF00Yes|r", 1, true) ~= nil, "Locked: Yes is green")
  assertTrue(raw[4]:find("|cFFFF0000Off|r", 1, true) ~= nil, "Test mode: Off is red")
end)

test("launcher: the host's tooltip lines are appended ONCE, below the status, above the hints", function()
  -- launcher-§1: the host's onTooltipShow adds what is the addon's own, between the status block
  -- and the click hints, and nowhere else.
  -- red under: handing the host the object's OnTooltipShow (its lines alone, or twice), or drawing
  -- them after the hints.
  local calls = 0
  local rec = fixture{
    isLocked = function() return false end,
    onTooltipShow = function(tt)
      calls = calls + 1
      tt:AddLine("Entries: 42")
      tt:AddLine("Session: 3")
    end,
  }
  local L = lib:New(rec.d)
  L:Register()
  local lines = hover(L)
  assertEqual(calls, 1, "the host hook runs once per show")
  assertEqual(table.concat(lines, "\n"), table.concat({
    rec.name, "Enabled: Yes", "Locked: No", "Entries: 42", "Session: 3", LEFT_HINT, RIGHT_HINT,
  }, "\n"))
  hover(L)
  assertEqual(calls, 2, "and once again on the next show")

  local plainRec = fixture{ onTooltipShow = "not a function" }
  local P = lib:New(plainRec.d)
  P:Register()
  assertEqual(#hover(P), 4, "a non-function hook is dropped, and the library's block still draws")
end)

test("launcher: tooltip status is read on EVERY show, never cached", function()
  -- red under: a state captured at Register or at the first hover, which disagrees with the panel
  -- the moment the player changes it.
  local enabled, locked, testing = true, true, false
  local asked = 0
  local rec = fixture{
    isEnabled = function() asked = asked + 1; return enabled end,
    isLocked = function() return locked end,
    isTestMode = function() return testing end,
  }
  local L = lib:New(rec.d)
  L:Register()
  local first = hover(L)
  enabled, locked, testing = false, false, true
  local second = hover(L)
  assertEqual(first[2] .. "|" .. first[3] .. "|" .. first[4], "Enabled: Yes|Locked: Yes|Test mode: Off")
  assertEqual(second[2] .. "|" .. second[3] .. "|" .. second[4], "Enabled: No|Locked: No|Test mode: On")
  assertEqual(second[5], LEFT_HINT)
  assertEqual(asked, 2, "isEnabled was asked once per show")
end)

test("launcher: a raising tooltip accessor or host hook costs its own line, not the tooltip", function()
  -- The tooltip runs inside the client's hover dispatch, where a raise is a red error box.
  -- red under: an unguarded accessor, which draws half a tooltip and an error.
  local rec = fixture{
    version = function() error("version boom") end,
    isLocked = function() error("lock boom") end,
    onTooltipShow = function() error("host boom") end,
  }
  local L = lib:New(rec.d)
  L:Register()
  local ok, lines = pcall(hover, L)
  assertTrue(ok, tostring(lines))
  assertEqual(lines[1], rec.name, "a raising version drops the version")
  assertEqual(lines[3], "Locked: No", "a raising isLocked reads as No")
  assertEqual(lines[#lines - 1], LEFT_HINT, "and the hints still draw")
  assertEqual(lines[#lines], RIGHT_HINT)
  assertTrue(table.concat(rec.logs, "|"):find("host boom", 1, true) ~= nil, "the debug seam heard it")
  assertEqual(#rec.lines, 0, "and nothing went to chat on a hover")
end)

test("launcher: a tooltip argument with no AddLine is left alone", function()
  -- A display may hand OnTooltipShow something that is not a GameTooltip. Refuse it quietly.
  -- red under: calling a method the argument does not have.
  local rec = fixture()
  local L = lib:New(rec.d)
  L:Register()
  assertTrue(pcall(L:Object().OnTooltipShow, {}))
  assertTrue(pcall(L:Object().OnTooltipShow, nil))
end)

test("launcher: every tooltip string goes through the descriptor's L, rawget-guarded", function()
  -- localization: lib.STRINGS overridden by d.L. A key-echoing table falls through to English.
  -- red under: literals in the draw code, or a plain index that prints TOOLTIP_ENABLED.
  local L1 = setmetatable({ TOOLTIP_ENABLED = "Aktiv: %s", TOOLTIP_YES = "Ja",
    TOOLTIP_OPTIONS_MENU = "Optionen" }, { __index = function(_, k) return k end })
  local rec = fixture{ L = L1 }
  local L = lib:New(rec.d)
  L:Register()
  local lines = hover(L)
  assertEqual(lines[2], "Aktiv: Ja")
  assertEqual(lines[#lines - 1], LEFT_HINT, "an unset key falls through")
  assertEqual(lines[#lines], "Right-click: Optionen")
  for _, key in ipairs{ "TOOLTIP_TITLE_VERSION", "TOOLTIP_ENABLED", "TOOLTIP_LOCKED",
    "TOOLTIP_TEST_MODE", "TOOLTIP_YES", "TOOLTIP_NO", "TOOLTIP_ON", "TOOLTIP_OFF", "TOOLTIP_LEFT",
    "TOOLTIP_RIGHT", "TOOLTIP_OPEN_SETTINGS", "TOOLTIP_OPTIONS_MENU", "MENU_ENABLED", "MENU_LOCKED",
    "MENU_TEST_MODE", "MENU_SHOW_WINDOW", "MENU_NEEDS_ENABLE", "MENU_GRAYED", "MENU_FAILED" } do
    assertEqual(type(lib.STRINGS[key]), "string", key .. " is in lib.STRINGS")
  end
  for _, key in ipairs{ "TOOLTIP_LEFT_DEFAULT", "TOOLTIP_DISABLED_HINT", "TOOLTIP_DISABLED_BARE" } do
    assertNil(lib.STRINGS[key], key .. " retired with the rungs at minor 4")
  end
end)

test("launcher: minor 4 is live", function()
  -- red under: a click change that forgot its bump, which reaches no host holding minor 3.
  assertEqual(lib.MINOR, 4)
  assertEqual(lib.MODULES.Launcher, 4)
end)

-- ── click behavior (minor 4, launcher-§2 as of standard v2.67.0) ─────────────────────────────
--
-- Left-click opens the settings panel on every addon, in either state. Right-click opens the
-- client's context menu, titled with the label, with one checkbox per toggle the descriptor
-- supplies, in the one order: Enabled, Locked, Test mode, Show window.

local MENU = dofile("tests/mock_menu.lua")(mocks)
local OWNER = { name = "LibDBIcon10_TestHost" }   -- the frame the client hands OnClick

--- Right-click the launcher and answer the menu the mock recorded, or nil if none opened.
local function rightClick(L)
  MENU.reset()
  L:Object().OnClick(OWNER, "RightButton")
  return MENU.last
end

--- A descriptor carrying every accessor-and-toggle pair, each toggle counted, each state live.
local function fullHost(over)
  local rec = fixture()
  rec.state = { enabled = true, locked = false, testMode = false, window = false }
  rec.calls = { setEnabled = {}, toggleLock = 0, toggleTestMode = 0, toggleWindow = 0 }
  local d, st, calls = rec.d, rec.state, rec.calls
  d.label = "Ka0s Test Host"
  d.isEnabled = function() return st.enabled end
  d.setEnabled = function(v) calls.setEnabled[#calls.setEnabled + 1] = v; st.enabled = v end
  d.isLocked = function() return st.locked end
  d.toggleLock = function() calls.toggleLock = calls.toggleLock + 1; st.locked = not st.locked end
  d.isTestMode = function() return st.testMode end
  d.toggleTestMode = function() calls.toggleTestMode = calls.toggleTestMode + 1; st.testMode = not st.testMode end
  d.isWindowShown = function() return st.window end
  d.toggleWindow = function() calls.toggleWindow = calls.toggleWindow + 1; st.window = not st.window end
  for k, v in pairs(over or {}) do d[k] = v end
  local L = lib:New(d)
  L:Register()
  return rec, L
end

test("launcher: left-click opens the settings panel, enabled or disabled", function()
  -- launcher-§2 (v2.67.0): the panel is setup, not a feature, so the left button opens it in
  -- either state, on every addon. No refusal line, no host action.
  -- red under: minor 2's disabled refusal, or minor 3's rung (a)/(b) onClick.
  for _, enabled in ipairs{ true, false } do
    local rec, L = fullHost{ isEnabled = function() return enabled end }
    L:Object().OnClick(OWNER, "LeftButton")
    assertEqual(rec.opened, 1, "enabled=" .. tostring(enabled))
    assertEqual(#rec.lines, 0, "and nothing is said")
  end
end)

test("launcher: onClick, leftClickLabel, disabledLine and slash are retired and ignored", function()
  -- Minor 4 retires them with the rungs. A host that has not yet re-vendored its setup file still
  -- passes them: New accepts the descriptor, and none of them does anything.
  -- red under: an error on a retired field, or a left click that still runs onClick.
  local rec = fixture()
  for k, v in pairs(retiredFields(rec)) do rec.d[k] = v end
  rec.d.isEnabled = function() return false end
  local L = lib:New(rec.d)
  L:Register()
  L:Object().OnClick(OWNER, "LeftButton")
  assertEqual(rec.left, 0, "onClick never runs")
  assertEqual(rec.opened, 1, "the panel opens instead")
  assertEqual(#rec.lines, 0, "and the disabled line is not printed")
  -- Minor 2 raised on an isEnabled without a disabledLine; that rule served the refusal.
  local ok = pcall(function()
    lib:New{ name = nextName(), icon = "x", openSettings = function() end,
      isEnabled = function() return true end }
  end)
  assertTrue(ok, "isEnabled no longer needs a disabledLine")
end)

test("launcher: right-click opens the client's context menu, titled with the label", function()
  -- launcher-§2: `MenuUtil.CreateContextMenu`, anchored to the frame that was clicked, and the
  -- settings panel is NOT opened as well.
  -- red under: right-click still opening settings, or a menu built by the host.
  local rec, L = fullHost()
  local menu = rightClick(L)
  assertTrue(menu ~= nil, "a menu opened")
  assertEqual(menu.owner, OWNER, "anchored to the clicked frame")
  assertEqual(table.concat(menu.titles, "|"), "Ka0s Test Host")
  assertEqual(rec.opened, 0, "the panel stays shut")

  local bare = fixture{ isEnabled = function() return true end, setEnabled = function() end }
  local B = lib:New(bare.d)
  B:Register()
  assertEqual(table.concat(rightClick(B).titles, "|"), bare.name, "no label: the folder name")
end)

test("launcher: the menu carries one checkbox per supplied toggle, in the one order", function()
  -- Every combination of the four pairs present or absent (16), each entry drawn exactly when the
  -- descriptor passes its accessor AND its toggle, never out of order.
  -- red under: an entry for a state the addon does not have, a missing one, or a moved one.
  local PAIRS = {
    { "Enabled",     "isEnabled",     "setEnabled" },
    { "Locked",      "isLocked",      "toggleLock" },
    { "Test mode",   "isTestMode",    "toggleTestMode" },
    { "Show window", "isWindowShown", "toggleWindow" },
  }
  local cells = 0
  for mask = 0, 15 do
    local rec = fixture()
    local want = {}
    for i, p in ipairs(PAIRS) do
      if math.floor(mask / 2 ^ (i - 1)) % 2 == 1 then
        rec.d[p[2]] = function() return true end
        rec.d[p[3]] = function() end
        want[#want + 1] = p[1]
      end
    end
    local L = lib:New(rec.d)
    L:Register()
    local menu = rightClick(L)
    if #want == 0 then
      assertNil(menu, "mask " .. mask .. ": no toggle, no menu")
      assertEqual(rec.opened, 1, "mask " .. mask .. ": the panel opens instead")
    else
      assertEqual(table.concat(menu:Texts(), "|"), table.concat(want, "|"), "mask " .. mask)
    end
    cells = cells + 1
  end
  assertEqual(cells, 16)
end)

test("launcher: an accessor without its toggle, or a toggle without its accessor, draws nothing", function()
  -- Half a pair is not a state the menu can show AND change, so it is absent rather than a
  -- checkbox that lies or does nothing.
  -- red under: drawing an entry from the accessor alone (the tooltip's fields), which is every
  -- minor-3 host's isLocked / isTestMode.
  local rec = fixture{
    isEnabled = function() return true end, setEnabled = function() end,
    isLocked = function() return true end,                 -- no toggleLock
    toggleTestMode = function() end,                         -- no isTestMode
    isWindowShown = function() return true end, toggleWindow = "not a function",
  }
  local L = lib:New(rec.d)
  L:Register()
  assertEqual(table.concat(rightClick(L):Texts(), "|"), "Enabled")
end)

test("launcher: each checkbox shows the state its accessor answers when the menu opens", function()
  -- Read at open, never cached: a second open after a change shows the change.
  -- red under: states captured at Register or at the first open.
  local rec, L = fullHost()
  local st = rec.state
  st.locked, st.testMode, st.window = true, false, true
  local menu = rightClick(L)
  assertTrue(menu:Checked("Enabled"))
  assertTrue(menu:Checked("Locked"))
  assertFalse(menu:Checked("Test mode"))
  assertTrue(menu:Checked("Show window"))
  st.locked, st.testMode, st.window = false, true, false
  menu = rightClick(L)
  assertFalse(menu:Checked("Locked"))
  assertTrue(menu:Checked("Test mode"))
  assertFalse(menu:Checked("Show window"))
end)

test("launcher: each entry toggles through its host function exactly once", function()
  -- launcher-§2: the addon's OWN handler, so its refusals and messages are the addon's. Enabled
  -- is handed the state it is moving to; the others take no argument. The menu closes after.
  -- red under: a handler called twice (a toggle that undoes itself), none at all, or a library
  -- write of the state behind the host's back.
  local rec, L = fullHost()
  local calls = rec.calls
  assertEqual(rightClick(L):Click("Locked"), MENU.RESPONSE.Close, "the menu closes")
  assertEqual(calls.toggleLock, 1)
  rightClick(L):Click("Test mode")
  assertEqual(calls.toggleTestMode, 1)
  rightClick(L):Click("Show window")
  assertEqual(calls.toggleWindow, 1)
  assertEqual(#calls.setEnabled, 0, "nothing else ran")
  rightClick(L):Click("Enabled")
  assertEqual(#calls.setEnabled, 1)
  assertEqual(calls.setEnabled[1], false, "an enabled addon is disabled")
  rightClick(L):Click("Enabled")
  assertEqual(calls.setEnabled[2], true, "and a disabled one enabled")
  assertEqual(calls.toggleLock + calls.toggleTestMode + calls.toggleWindow, 3, "one call each")
  assertEqual(rec.opened, 0)
end)

test("launcher: while disabled, Enabled stays live and the rest are grayed with the note", function()
  -- launcher-§2: Enabled is the off switch and must work in the off state; Locked, Test mode and
  -- Show window drive features, which refuse while disabled, so they show grayed rather than hidden.
  -- red under: hiding them, leaving them clickable, or graying Enabled too.
  local rec, L = fullHost()
  rec.state.enabled = false
  local menu = rightClick(L)
  assertEqual(table.concat(menu:Texts(), "|"), table.concat({
    "Enabled",
    "Locked (enable the addon first)",
    "Test mode (enable the addon first)",
    "Show window (enable the addon first)",
  }, "|"))
  assertTrue(menu:Find("Enabled").enabled, "Enabled stays clickable")
  assertFalse(menu:Checked("Enabled"))
  for _, e in ipairs{ "Locked", "Test mode", "Show window" } do
    assertFalse(menu:Find(e).enabled, e .. " is grayed")
  end
  assertNil(menu:Click("Locked"), "a grayed entry cannot be clicked")
  menu:Click("Enabled")
  assertEqual(rec.calls.setEnabled[1], true, "Enabled turns the addon back on")
  menu = rightClick(L)
  assertEqual(table.concat(menu:Texts(), "|"), "Enabled|Locked|Test mode|Show window",
    "and the next open is ungrayed")
  for _, e in ipairs{ "Locked", "Test mode", "Show window" } do
    assertTrue(menu:Find(e).enabled, e .. " is live again")
  end
end)

test("launcher: a grayed entry clicked anyway calls no handler and writes nothing", function()
  -- A client that dispatched the click despite the gray still reaches the module's own gate.
  -- red under: relying on the client's gray alone.
  local rec, L = fullHost()
  rec.state.enabled = false
  local menu = rightClick(L)
  menu:ForceClick("Locked")
  menu:ForceClick("Test mode")
  menu:ForceClick("Show window")
  local c = rec.calls
  assertEqual(c.toggleLock + c.toggleTestMode + c.toggleWindow + #c.setEnabled, 0)
  assertFalse(rec.state.locked or rec.state.testMode or rec.state.window)
  assertEqual(#rec.lines, 0, "and says nothing in chat")
end)

test("launcher: a host with no isEnabled has nothing grayed and no Enabled entry", function()
  -- A host without the pair is always enabled, as its tooltip says.
  -- red under: treating a missing isEnabled as disabled, which grays every entry forever.
  local rec, L = fullHost{ isEnabled = false, setEnabled = false }
  local menu = rightClick(L)
  assertEqual(table.concat(menu:Texts(), "|"), "Locked|Test mode|Show window")
  menu:Click("Locked")
  assertEqual(rec.calls.toggleLock, 1)
end)

test("launcher: with no MenuUtil, right-click degrades to the settings panel", function()
  -- Every client call sits behind a nil-guard: a client without the 11.0 menu API gets the panel,
  -- where every toggle also lives, rather than a silent button or an error box.
  -- red under: an unguarded MenuUtil, which raises inside the client's click dispatch.
  local rec, L = fullHost()
  MENU.remove()
  local ok = pcall(L:Object().OnClick, OWNER, "RightButton")
  mocks.MenuUtil = { }   -- present, but without CreateContextMenu
  local ok2 = pcall(L:Object().OnClick, OWNER, "RightButton")
  MENU.install()
  assertTrue(ok and ok2)
  assertEqual(rec.opened, 2, "the panel opened both times")
  assertEqual(#rec.lines, 0, "and nothing was reported as a failure")
  assertTrue(table.concat(rec.logs, "|"):find("CreateContextMenu absent", 1, true) ~= nil)
end)

test("launcher: a raising toggle or menu API is reported and never escapes", function()
  -- Both run inside the client's dispatch. One line names the addon and what raised.
  -- red under: an unguarded handler, which is a red error box naming no addon.
  local rec, L = fullHost{ toggleLock = function() error("lock boom") end }
  local ok = pcall(function() rightClick(L):Click("Locked") end)
  assertTrue(ok)
  assertTrue(said(rec):find("Locked", 1, true) ~= nil, "the report names the entry")
  assertTrue(said(rec):find("lock boom", 1, true) ~= nil, "and what raised")

  local saved = MENU.MenuUtil.CreateContextMenu
  MENU.MenuUtil.CreateContextMenu = function() error("menu boom") end
  local ok2 = pcall(L:Object().OnClick, OWNER, "RightButton")
  MENU.MenuUtil.CreateContextMenu = saved
  assertTrue(ok2)
  assertTrue(said(rec):find("right", 1, true) ~= nil and said(rec):find("menu boom", 1, true) ~= nil)

  local left = fixture{ openSettings = function() error("panel boom") end }
  local P = lib:New(left.d)
  P:Register()
  assertTrue(pcall(P:Object().OnClick, OWNER, "LeftButton"))
  assertTrue(said(left):find("left", 1, true) ~= nil and said(left):find("panel boom", 1, true) ~= nil)
end)

test("launcher: a raising accessor costs its checkmark, not the menu", function()
  -- red under: an unguarded accessor in the generator, which opens no menu at all.
  local rec, L = fullHost{ isTestMode = function() error("test boom") end }
  local menu = rightClick(L)
  assertEqual(#menu.entries, 4, "every entry still drawn")
  assertFalse(menu:Checked("Test mode"), "the raising one reads unchecked")
  assertTrue(table.concat(rec.logs, "|"):find("test boom", 1, true) ~= nil, "the debug seam heard it")
  assertEqual(#rec.lines, 0)
end)

test("launcher: every menu string goes through the descriptor's L, rawget-guarded", function()
  -- red under: literal entry labels, or a key-echoing locale printing MENU_LOCKED.
  local L1 = setmetatable({ MENU_LOCKED = "Gesperrt", MENU_NEEDS_ENABLE = "erst aktivieren" },
    { __index = function(_, k) return k end })
  local rec, L = fullHost{ L = L1 }
  rec.state.enabled = false
  assertEqual(table.concat(rightClick(L):Texts(), "|"), table.concat({
    "Enabled", "Gesperrt (erst aktivieren)", "Test mode (erst aktivieren)",
    "Show window (erst aktivieren)" }, "|"))
end)

-- ── visibility (launcher-§3) ─────────────────────────────────────────────────────────────────

test("launcher: the host's OWN minimap table is handed to LibDBIcon, never a copy", function()
  -- LibDBIcon writes `minimapPos` into this table when the player drags the button and `hide` when
  -- they use its own menu. A copy here would be a second record of one state, and the two would
  -- disagree the first time either was used (anti-pattern #81).
  -- red under: passing a fresh table, after which the settings row and the button drift apart.
  local rec = fixture()
  local L = lib:New(rec.d)
  L:Register()
  assertEqual(ICON.__buttons[rec.name].db, rec.minimap, "the same table, by identity")
  rec.minimap.minimapPos = 217
  assertEqual(ICON.__buttons[rec.name].db.minimapPos, 217)
end)

test("launcher: the minimap table is resolved at REGISTER time, not at New", function()
  -- `db.global.minimap` does not exist when a host builds its descriptor at file load, and a table
  -- captured then is a table AceDB later replaces.
  -- red under: reading `d.minimap` once inside New, which hands LibDBIcon a table nothing writes to.
  local live = nil
  local rec = fixture{}
  rec.d.minimap = function() return live end
  local L = lib:New(rec.d)
  live = { hide = true }
  L:Register()
  assertEqual(ICON.__buttons[rec.name].db, live)
  assertFalse(L:IsShown(), "and the stored state it carried is read, not defaulted")
end)

test("launcher: IsShown reads LibDBIcon's own `hide` key and inverts it", function()
  -- §3's storage rule in one assertion: ONE boolean, the one the library also writes. The row's
  -- label says shown and the stored key says hidden, which is the whole cost of storing it.
  -- red under: a parallel `show` key, which is the second copy the section forbids.
  local rec = fixture()
  local L = lib:New(rec.d)
  L:Register()
  assertTrue(L:IsShown(), "an empty table means the button is shown")
  rec.minimap.hide = true
  assertFalse(L:IsShown())
  assertNil(rec.minimap.show, "no second key is invented beside LibDBIcon's")
end)

test("launcher: SetShown writes `hide` and drives LibDBIcon's Show / Hide", function()
  -- The row's `set` calls this from the host's single write seam, so the button follows the
  -- checkbox immediately rather than at the next reload.
  -- red under: writing the store and leaving the button where it was until a reload.
  local rec = fixture()
  local L = lib:New(rec.d)
  L:Register()
  assertTrue(L:SetShown(false))
  assertTrue(rec.minimap.hide, "stored as LibDBIcon spells it")
  assertFalse(ICON.__buttons[rec.name].shown, "and the button went with it")
  assertTrue(L:SetShown(true))
  assertFalse(rec.minimap.hide)
  assertTrue(ICON.__buttons[rec.name].shown)
end)

test("launcher: the debug seam reports under the Launcher tag", function()
  -- red under: a module that logs nowhere, which is the one shape a host cannot diagnose a
  -- missing button from.
  local rec = fixture()
  local L = lib:New(rec.d)
  L:Register()
  L:SetShown(false)
  assertTrue(table.concat(rec.logs, "|"):find("Launcher: registered", 1, true) ~= nil)
  assertTrue(table.concat(rec.logs, "|"):find("Launcher: hidden", 1, true) ~= nil)
end)

-- ── degrading (launcher-§5, library-stack) ───────────────────────────────────────────────────

test("launcher: with no LibDataBroker there is no object, and nothing raises", function()
  -- Both broker libraries are OPTIONAL: they are resolved with `LibStub(..., true)` at call time,
  -- and a host whose libs/ folder does not carry them must not lose its settings panel over it.
  -- red under: a hard dependency, which takes out the whole module — or the host — over a library
  -- that is genuinely optional to everything but the button.
  local rec = fixture()
  local L = lib:New(rec.d)
  withoutLibs({ "LibDataBroker-1.1", "LibDBIcon-1.0" }, function()
    assertFalse(L:Register())
  end)
  assertNil(L:Object())
  assertFalse(L:IsRegistered())
  assertTrue(said(rec):find("LibDataBroker", 1, true) ~= nil, "and it says which library is missing")
end)

test("launcher: with no LibDBIcon the broker plugin still registers; the button does not", function()
  -- The honest middle state, and worth having: a broker display shows the addon, the minimap does
  -- not, and Register says `false` because §1's headline surface is the one that is absent.
  -- red under: refusing the plugin as well, which throws away the half that did load.
  local rec = fixture()
  local L = lib:New(rec.d)
  withoutLibs({ "LibDBIcon-1.0" }, function()
    assertFalse(L:Register(), "not fully wired")
  end)
  assertTrue(L:Object() ~= nil, "but the one object exists and a display can draw it")
  assertNil(ICON.__buttons[rec.name], "and no button was registered")
  assertTrue(said(rec):find("LibDBIcon", 1, true) ~= nil)
end)

test("launcher: two Register calls with no LibDBIcon print NO_ICON once", function()
  -- Register is callable from OnInitialize and again from login, and a failing Register reaches the
  -- notice again each time. One missing library is one line, not one per call.
  -- red under: no once guard, which prints the same notice twice per session.
  local rec = fixture()
  local L = lib:New(rec.d)
  withoutLibs({ "LibDBIcon-1.0" }, function()
    L:Register()
    L:Register()
  end)
  assertEqual(#rec.lines, 1, "one notice across two calls")
  assertTrue(rec.lines[1]:find("LibDBIcon", 1, true) ~= nil)

  local rec2 = fixture()
  local L2 = lib:New(rec2.d)
  withoutLibs({ "LibDataBroker-1.1" }, function()
    L2:Register()
    L2:Register()
  end)
  assertEqual(#rec2.lines, 1, "NO_BROKER likewise")
end)

test("launcher: STRINGS carry no [LibKa0s] tag, because the host printer adds its own", function()
  -- makeEmit hands these to the host's tagged printer, so a library tag is a second tag.
  -- red under: the old prefix, which reads "[Host] [LibKa0s] Host: ..." in chat.
  for key, value in pairs(lib.STRINGS) do
    assertTrue(value:find("[LibKa0s]", 1, true) == nil, key .. " carries no library tag")
  end
end)

test("launcher: SetShown still records the player's choice where LibDBIcon is absent", function()
  -- The store is the truth and the button is a view of it, so a degraded install still remembers
  -- what the checkbox was set to — and the checkbox still reads back correctly.
  -- red under: writing `hide` only inside the LibDBIcon branch, which silently drops the setting.
  local rec = fixture()
  local L = lib:New(rec.d)
  withoutLibs({ "LibDBIcon-1.0" }, function() L:Register() end)
  assertFalse(L:SetShown(false), "the button could not be moved, and says so")
  assertTrue(rec.minimap.hide, "the choice was still recorded")
  assertFalse(L:IsShown(), "so the Master-controls checkbox reads what the player chose")
end)

test("launcher: a descriptor whose minimap answers no table refuses the button and says why", function()
  -- LibDBIcon has nowhere to keep the button's position without it, and registering with nil would
  -- give the player a button that jumps back to the default angle on every login.
  -- red under: passing nil straight through, which fails inside somebody else's library.
  local rec = fixture{}
  rec.d.minimap = function() return nil end
  local L = lib:New(rec.d)
  assertFalse(L:Register())
  assertNil(ICON.__buttons[rec.name])
  assertTrue(said(rec):find("minimap", 1, true) ~= nil)
  assertTrue(L:IsShown(), "with nothing stored, the button reads as shown")
end)

test("launcher: a name LibDataBroker already holds takes that object rather than none", function()
  -- NewDataObject answers nil for a taken name. A second launcher under one addon's name is not a
  -- state this module can improve on, and the object the displays already hold is the real one.
  -- red under: leaving `object` nil, after which every click seam in the host is dead.
  local rec = fixture()
  local first = lib:New(rec.d)
  first:Register()
  local second = lib:New(rec.d)
  assertTrue(second:Register())
  assertEqual(second:Object(), first:Object())
end)

test("launcher: a host locale overrides a report, and a key-echoing fallback does not", function()
  -- Every Ka0s host's locale table answers an unknown key WITH THE KEY (anti-patterns #2), so a
  -- plain index would accept that synthesized string for every key and the library's own English
  -- would become unreachable. The same guard DebugLog and Slash carry, for the same shipped defect.
  -- red under: a plain index, which prints "NO_BROKER" at the player.
  local echoing = setmetatable({ NO_BROKER = "no broker here: %s" },
    { __index = function(_, k) return k end })
  local rec = fixture{ L = echoing }
  local L = lib:New(rec.d)
  withoutLibs({ "LibDataBroker-1.1" }, function() L:Register() end)
  assertTrue(said(rec):find("no broker here", 1, true) ~= nil, "the host's own words won")

  local rec2 = fixture{ L = setmetatable({}, { __index = function(_, k) return k end }) }
  local L2 = lib:New(rec2.d)
  withoutLibs({ "LibDataBroker-1.1" }, function() L2:Register() end)
  assertTrue(said(rec2):find("LibDataBroker", 1, true) ~= nil,
    "a table that only echoes keys falls through to the library's string")
  assertFalse(said(rec2) == "NO_BROKER")
end)

test("launcher: with no descriptor print, a report reaches the chat frame", function()
  -- The default every other major carries. A module whose only diagnostic needs a descriptor field
  -- to be seen is a module that is silent in exactly the install that needed it.
  -- red under: dropping the line where `print` was not supplied.
  local seen = {}
  local frame = mocks.DEFAULT_CHAT_FRAME
  mocks.DEFAULT_CHAT_FRAME = { AddMessage = function(_, line) seen[#seen + 1] = line end }
  local rec = fixture()
  rec.d.print = nil
  local L = lib:New(rec.d)
  local ok, err = pcall(function()
    withoutLibs({ "LibDataBroker-1.1" }, function() L:Register() end)
  end)
  mocks.DEFAULT_CHAT_FRAME = frame
  assertTrue(ok, tostring(err))
  assertTrue(table.concat(seen, "|"):find("LibDataBroker", 1, true) ~= nil)
end)
