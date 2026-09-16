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
local test, assertEqual, assertTrue, assertFalse, assertNil, assertError =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil, T.assertError
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
--- that one field is enough and nothing has to be unloaded. `silent` is honoured exactly as the
--- mock's own LibStub honours it: a non-silent lookup of a blocked major still raises, so a case
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
  assertError(function() lib:New{ icon = "x", openSettings = function() end } end,
    "descriptor.name")
  assertError(function() lib:New{ name = "X", openSettings = function() end } end,
    "descriptor.icon")
  assertError(function() lib:New{ name = "X", icon = "x" } end, "descriptor.openSettings")
  assertError(function() lib:New{ name = "", icon = "x", openSettings = function() end } end,
    "descriptor.name", "an empty string is not a folder name")
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
  -- red under: labelling one registration and naming the other, which is the drift §1 names.
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

test("launcher: OnTooltipShow is passed through, and only when it is a function", function()
  -- launcher-§1 leaves the contents to the addon and binds nothing about them; what it does bind
  -- is that there is one object to hang them on.
  -- red under: dropping the hook, or handing LDB a non-function a display would then call.
  local shown = 0
  local rec = fixture{ onTooltipShow = function() shown = shown + 1 end }
  local L = lib:New(rec.d)
  L:Register()
  L:Object().OnTooltipShow({})
  assertEqual(shown, 1)

  local plain = fixture{ onTooltipShow = "not a function" }
  local P = lib:New(plain.d)
  P:Register()
  assertNil(P:Object().OnTooltipShow)
end)

-- ── click behaviour (launcher-§2) ────────────────────────────────────────────────────────────

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
