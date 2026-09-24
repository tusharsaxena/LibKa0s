-- tests/test_launcher.lua — LibKa0s-Launcher-1.0: one broker object, registered twice.
--
-- What these cases pin is `launcher-§1`/`§2`/`§3`, which are rules about a SHAPE rather than about
-- pixels: exactly one LibDataBroker object of `type = "launcher"`; one OnClick that both surfaces
-- dispatch into, so the rung rule cannot be satisfied on the minimap and missed in a broker
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

-- ── the status tooltip (minor 3, launcher-§1 as of standard v2.66.0) ─────────────────────────
--
-- The library draws it, always, in one shape for all eleven addons:
--
--   <label>  v<version>          (version optional)
--   Enabled: Yes|No              (always)
--   Locked: Yes|No               (only with isLocked)
--   Test mode: On|Off            (only with isTestMode)
--   <the host's own lines>       (onTooltipShow, appended once)
--   Left-click: <what it does>
--   Right-click: Open settings

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

local DISABLED_LINE = "TestHost is disabled \226\128\148 enable it with |cFFFFFF00/th enable|r"

test("launcher: the library ALWAYS draws the tooltip, and a rung (c) host need pass nothing", function()
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
    "Left-click: Open settings",
    "Right-click: Open settings",
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
  local rec = fixture{
    onClick = function() end,
    isEnabled = function() return enabled end,
    disabledLine = function() return DISABLED_LINE end,
  }
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

test("launcher: a disabled rung (a)/(b) hint names the enable command, read from disabledLine", function()
  -- launcher-§2 (v2.66.0): the tooltip says before the click what the refusal will print after it.
  -- The host passes nothing new: the command is read out of the dispatcher's own disabled line.
  -- red under: the enabled label while disabled, which promises a click that will be refused.
  local rec = fixture{
    onClick = function() end,
    leftClickLabel = "Toggle window",
    isEnabled = function() return false end,
    disabledLine = function() return DISABLED_LINE end,
  }
  local L = lib:New(rec.d)
  L:Register()
  local lines = hover(L)
  assertEqual(lines[#lines - 1], "Left-click: disabled \226\128\148 /th enable")
  assertEqual(lines[#lines], "Right-click: Open settings", "the right button does not change")
  assertEqual(#rec.lines, 0, "hovering prints nothing to chat")
end)

test("launcher: an explicit slash wins, and a line naming no command still says disabled", function()
  -- red under: a hint that loses the command when the host's line is worded differently.
  local rec = fixture{
    onClick = function() end,
    slash = "th2",
    isEnabled = function() return false end,
    disabledLine = function() return DISABLED_LINE end,
  }
  local L = lib:New(rec.d)
  L:Register()
  local lines = hover(L)
  assertEqual(lines[#lines - 1], "Left-click: disabled \226\128\148 /th2 enable",
    "descriptor.slash, given its slash")

  local rec2 = fixture{
    onClick = function() end,
    isEnabled = function() return false end,
    disabledLine = function() return "off" end,
  }
  local L2 = lib:New(rec2.d)
  L2:Register()
  local lines2 = hover(L2)
  assertEqual(lines2[#lines2 - 1], "Left-click: disabled")
end)

test("launcher: a rung (c) tooltip reads Open settings whether enabled or not", function()
  -- launcher-§2: rung (c)'s left click opens the panel in either state, and so says the hint.
  -- red under: a disabled pointer on a button whose left click still works.
  local rec = fixture{
    isEnabled = function() return false end,
    disabledLine = function() return DISABLED_LINE end,
  }
  local L = lib:New(rec.d)
  L:Register()
  local lines = hover(L)
  assertEqual(lines[2], "Enabled: No")
  assertEqual(lines[#lines - 1], "Left-click: Open settings")
end)

test("launcher: leftClickLabel may be a function, and rung (a)/(b) without one reads Toggle", function()
  -- A lock toggle's label follows the lock, so a function is asked on every show.
  -- red under: a label captured once, which reads Unlock frame on an unlocked frame.
  local locked = true
  local rec = fixture{
    onClick = function() end,
    leftClickLabel = function() return locked and "Unlock frame" or "Lock frame" end,
  }
  local L = lib:New(rec.d)
  L:Register()
  local lines = hover(L)
  assertEqual(lines[#lines - 1], "Left-click: Unlock frame")
  locked = false
  lines = hover(L)
  assertEqual(lines[#lines - 1], "Left-click: Lock frame")

  local rec2 = fixture{ onClick = function() end }
  local L2 = lib:New(rec2.d)
  L2:Register()
  local lines2 = hover(L2)
  assertEqual(lines2[#lines2 - 1], "Left-click: Toggle")
end)

--- The descriptor fields one matrix cell passes, and the lines it must draw.
local function matrixCell(enabled, rungAB, lockMode, testMode)
  local over = {
    label = "Ka0s Test Host",
    version = "9.9.9",
    isEnabled = function() return enabled end,
    disabledLine = function() return DISABLED_LINE end,
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
  local left = "Open settings"
  if rungAB then
    over.onClick = function() end
    over.leftClickLabel = "Toggle window"
    left = enabled and "Toggle window" or "disabled \226\128\148 /th enable"
  end
  want[#want + 1] = "Left-click: " .. left
  want[#want + 1] = "Right-click: Open settings"
  return over, want
end

test("launcher: every combination of state, rung and status lines draws the fixed shape", function()
  -- The matrix the shape is written for: enabled or disabled, rung (a)/(b) or (c), with or without
  -- a lock, with or without a test mode, each value both ways. Status lines appear only for the
  -- states the addon has (never a permanent No), and the order never moves.
  -- red under: any line out of order, a status line drawn for a state not passed, or a hint wrong
  -- for its rung and state.
  local cases = 0
  for _, enabled in ipairs{ true, false } do
    for _, rungAB in ipairs{ true, false } do
      for _, lockMode in ipairs{ "absent", true, false } do
        for _, testMode in ipairs{ "absent", true, false } do
          local over, want = matrixCell(enabled, rungAB, lockMode, testMode)
          local rec = fixture(over)
          local L = lib:New(rec.d)
          L:Register()
          local label = ("enabled=%s rungAB=%s lock=%s test=%s"):format(
            tostring(enabled), tostring(rungAB), tostring(lockMode), tostring(testMode))
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
    rec.name, "Enabled: Yes", "Locked: No", "Entries: 42", "Session: 3",
    "Left-click: Open settings", "Right-click: Open settings",
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
    onClick = function() end,
    leftClickLabel = "Toggle test mode",
    isEnabled = function() asked = asked + 1; return enabled end,
    disabledLine = function() return DISABLED_LINE end,
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
  assertEqual(second[5], "Left-click: disabled \226\128\148 /th enable")
  assertEqual(asked, 2, "isEnabled was asked once per show")
end)

test("launcher: a raising tooltip accessor or host hook costs its own line, not the tooltip", function()
  -- The tooltip runs inside the client's hover dispatch, where a raise is a red error box.
  -- red under: an unguarded accessor, which draws half a tooltip and an error.
  local rec = fixture{
    onClick = function() end,
    leftClickLabel = function() error("label boom") end,
    isLocked = function() error("lock boom") end,
    onTooltipShow = function() error("host boom") end,
  }
  local L = lib:New(rec.d)
  L:Register()
  local ok, lines = pcall(hover, L)
  assertTrue(ok, tostring(lines))
  assertEqual(lines[3], "Locked: No", "a raising isLocked reads as No")
  assertEqual(lines[#lines - 1], "Left-click: Toggle", "a raising label falls back")
  assertEqual(lines[#lines], "Right-click: Open settings", "and the hints still draw")
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
  local L1 = setmetatable({ TOOLTIP_ENABLED = "Aktiv: %s", TOOLTIP_YES = "Ja" },
    { __index = function(_, k) return k end })
  local rec = fixture{ L = L1 }
  local L = lib:New(rec.d)
  L:Register()
  local lines = hover(L)
  assertEqual(lines[2], "Aktiv: Ja")
  assertEqual(lines[#lines], "Right-click: Open settings", "an unset key falls through")
  for _, key in ipairs{ "TOOLTIP_TITLE_VERSION", "TOOLTIP_ENABLED", "TOOLTIP_LOCKED",
    "TOOLTIP_TEST_MODE", "TOOLTIP_YES", "TOOLTIP_NO", "TOOLTIP_ON", "TOOLTIP_OFF", "TOOLTIP_LEFT",
    "TOOLTIP_RIGHT", "TOOLTIP_OPEN_SETTINGS", "TOOLTIP_LEFT_DEFAULT", "TOOLTIP_DISABLED_HINT",
    "TOOLTIP_DISABLED_BARE" } do
    assertEqual(type(lib.STRINGS[key]), "string", key .. " is in lib.STRINGS")
  end
end)

test("launcher: minor 3 is live", function()
  -- red under: a tooltip change that forgot its bump, which reaches no host holding minor 2.
  assertEqual(lib.MINOR, 3)
  assertEqual(lib.MODULES.Launcher, 3)
end)

-- ── click behavior (launcher-§2) ────────────────────────────────────────────────────────────

test("launcher: right-click ALWAYS opens the settings panel, on every rung", function()
  -- The rule that lets rungs (a) and (b) spend the left button on something better: the panel is
  -- never more than one click away, on every addon in the collection.
  -- red under: a host action reachable from the right button, which is anti-pattern #81.
  local rungAB = fixture{ onClick = function() end }
  local A = lib:New(rungAB.d)
  A:Register()
  A:Object().OnClick(nil, "RightButton")
  assertEqual(rungAB.opened, 1, "rung (a)/(b): right-click still opens the panel")

  local rungC = fixture()
  local C = lib:New(rungC.d)
  C:Register()
  C:Object().OnClick(nil, "RightButton")
  assertEqual(rungC.opened, 1, "rung (c): the same")
end)

test("launcher: left-click runs the host's action on rungs (a) and (b)", function()
  -- The rung is a property of the addon, expressed as the PRESENCE of onClick rather than as a
  -- flag, so a host cannot declare a rung it did not implement.
  -- red under: opening the panel anyway, which is a rung skipped rather than a design chosen.
  local rec = fixture{}
  rec.d.onClick = function(button)
    rec.left = rec.left + 1
    rec.leftButton = button
  end
  local L = lib:New(rec.d)
  L:Register()
  L:Object().OnClick(nil, "LeftButton")
  assertEqual(rec.left, 1)
  assertEqual(rec.opened, 0, "the panel is the RIGHT button's job here")
  assertEqual(rec.leftButton, "LeftButton", "the handler is told which button it was")
end)

test("launcher: with no onClick, left-click opens the panel too — that is rung (c)", function()
  -- red under: a silent left button, which is what an addon with no primary window and no preview
  -- would get from a handler that only knew about the other two rungs.
  local rec = fixture()
  local L = lib:New(rec.d)
  L:Register()
  L:Object().OnClick(nil, "LeftButton")
  assertEqual(rec.opened, 1)
end)

-- ── the disabled gate (minor 2, launcher-§2) ─────────────────────────────────────────────────

test("launcher: with isEnabled false, a left click prints disabledLine and never calls onClick", function()
  -- launcher-§2: a disabled rung (a)/(b) addon refuses the left click with the dispatcher's own
  -- line. Hosts hand-wrote that gate inside onClick in three spellings; this is the one owner.
  -- red under: no gate, which runs the host's action (and writes SavedVariables) while disabled.
  local enabled = false
  local rec = fixture{
    isEnabled = function() return enabled end,
    disabledLine = function() return "TestHost is disabled — enable it with /th enable" end,
  }
  rec.d.onClick = function() rec.left = rec.left + 1 end
  local L = lib:New(rec.d)
  L:Register()
  L:Object().OnClick(nil, "LeftButton")
  assertEqual(rec.left, 0, "the host's action never ran")
  assertEqual(rec.opened, 0, "and nothing else opened in its place")
  assertEqual(#rec.lines, 1, "exactly one line")
  assertEqual(rec.lines[1], "TestHost is disabled — enable it with /th enable",
    "and it is the host's disabledLine, verbatim")

  enabled = true
  L:Object().OnClick(nil, "LeftButton")
  assertEqual(rec.left, 1, "enabled again, the action runs")
  assertEqual(#rec.lines, 1, "and nothing more is said")
end)

test("launcher: the gate leaves right-click and rung (c) exactly as they were", function()
  -- Right-click ALWAYS opens settings, and a disabled addon's settings panel is where it is
  -- re-enabled. Rung (c) is still expressed by omitting onClick, and its left click opens the panel.
  -- red under: gating every click, which locks the player out of the one surface that re-enables.
  local rungAB = fixture{
    onClick = function() end,
    isEnabled = function() return false end,
    disabledLine = function() return "disabled" end,
  }
  local A = lib:New(rungAB.d)
  A:Register()
  A:Object().OnClick(nil, "RightButton")
  assertEqual(rungAB.opened, 1, "right-click still opens settings while disabled")
  assertEqual(#rungAB.lines, 0, "and refuses nothing")

  local rungC = fixture{
    isEnabled = function() return false end,
    disabledLine = function() return "disabled" end,
  }
  local C = lib:New(rungC.d)
  C:Register()
  C:Object().OnClick(nil, "LeftButton")
  assertEqual(rungC.opened, 1, "rung (c): left-click still opens settings")
  assertEqual(#rungC.lines, 0)
end)

test("launcher: New refuses an isEnabled with no disabledLine", function()
  -- A refusal that says nothing is the silent left button launcher-§2 exists to forbid.
  -- red under: accepting the pair half-filled, which ships a button that does nothing when clicked.
  assertErrorMatches(function()
    lib:New{ name = "X", icon = "x", openSettings = function() end,
      onClick = function() end, isEnabled = function() return true end }
  end, "requires descriptor.disabledLine")
end)

test("launcher: a raising click is reported and never escapes into the client", function()
  -- This runs inside the client's click dispatch, where a raise is a red error box over the
  -- player's minimap with nothing naming the addon that caused it.
  -- red under: an unguarded call, which is the shape every hand-written copy of this handler had.
  local rec = fixture{ onClick = function() error("boom") end }
  local L = lib:New(rec.d)
  L:Register()
  L:Object().OnClick(nil, "LeftButton")
  assertTrue(said(rec):find(rec.name, 1, true) ~= nil, "the report names the addon")
  assertTrue(said(rec):find("left", 1, true) ~= nil, "and which button")
  assertTrue(said(rec):find("boom", 1, true) ~= nil, "and what raised")
  -- And the launcher is still usable afterwards.
  L:Object().OnClick(nil, "RightButton")
  assertEqual(rec.opened, 1)
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
